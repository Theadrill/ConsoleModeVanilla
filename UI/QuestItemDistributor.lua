--[[
    ConsoleMode - Vanilla
    UI/QuestItemDistributor.lua

    Feature: Distribuicao de Itens de Missao Usaveis (Cluster L2+R2) + Deduplicador Global
    
    1. Distribuicao:
       - Escaneia as bolsas (0-4) por itens tipo Quest/Missao com efeito de uso (FIFO)
       - Distribui nos slots alvo do cluster L2+R2: {38, 39, 37, 41, 42, 43, 44}
       - NUNCA atribui itens ao slot 40 (L2+R2+A, reservado para Ring Menu)
       - Preserva slots ja preenchidos corretamente (evita recriar acoes desnecessariamente)
       - Limpa slots orfaos quando o item deixa de existir na bolsa

    2. Deduplicador:
       - Dispara APOS verificar/anexar os itens na barra de acao:
         a) Uma vez logo apos o login/reload (apos carregamento das bolsas)
         b) Sempre que um novo item for adicionado pelo sistema de distribuicao
         c) Manualmente via comando /cm dedup
       - Varre todas as barras de acao do personagem (slots 1 a 120, um por um)
       - Compara via Tooltip (e GetActionInfo se disponivel)
       - Remove quaisquer duplicatas encontradas fora do slot atribuido (preserva apenas keepSlot)

    Compativel com Lua 5.0 / WoW 1.12.1 (Turtle WoW)
]]

local CM = ConsoleMode
CM.questItemDistributor = CM.questItemDistributor or {}

local QID = CM.questItemDistributor

-- Slots-alvo no cluster L2+R2 (pagina 5 = MULTIACTIONBAR4BUTTON, startSlot=37):
--   X=BUTTON1->37, Y=BUTTON2->38, B=BUTTON3->39
--   A=BUTTON4->40 (ring menu — NUNCA tocar!)
--   DUP=BUTTON5->41, DDOWN=BUTTON6->42, DLEFT=BUTTON7->43, DRIGHT=BUTTON8->44
-- Ordem de distribuicao: Y -> B -> X -> DUP -> DDOWN -> DLEFT -> DRIGHT
QID.TARGET_SLOTS = {38, 39, 37, 41, 42, 43, 44}

-- Track de itens atualmente nos slots alvo: [slotID] = itemID
QID.slotMap = {}

-- Referencia ao frame de eventos
QID.eventFrame = nil

-- Timers de delay antes de rodar o scan e intervalo de polling (segundos)
QID.SCAN_INTERVAL = 4.0
QID.pollTimer     = 0
QID.scanDelay     = 0
QID.scanTimer     = 0

-- Flag para garantir que a deduplicacao inicial ocorra uma vez apos o login
QID.initialDedupDone = false
QID.initialized = false

-- Mapeamento amigavel de slots alvo para nomes de botoes do cluster
QID.SLOT_LABELS = {
    [37] = "X",
    [38] = "Y",
    [39] = "B",
    [41] = "D-UP",
    [42] = "D-DOWN",
    [43] = "D-LEFT",
    [44] = "D-RIGHT",
}

-- Set de itemIDs conhecidos na bolsa (evita spam de anunciar o mesmo item repetidamente)
QID.knownItemIDs = {}

-- Helper de log: imprime no chat com prefixo colorido
local function QLog(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[QID]|r " .. tostring(msg))
end

-- Helper de debug: silenciado para evitar flood no chat durante o polling periodico de itens
local function QDebug(msg)
    -- Silenciado intencionalmente para nao poluir o chat durante o polling periodico
end

-- ============================================================================
-- TOOLTIP SCANNER AUXILIAR
-- ============================================================================

local function GetScanTooltip()
    local tip = getglobal("ConsoleModeBagScanTooltip")
    if not tip then
        tip = CreateFrame("GameTooltip", "ConsoleModeBagScanTooltip", nil, "GameTooltipTemplate")
        tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return tip
end

-- ============================================================================
-- DETECCAO DE ITEM DE QUEST NAS BOLSAS
-- ============================================================================

-- Verifica via tooltip se o item e do tipo Quest/Missao e tem efeito de uso.
function QID:IsQuestItem(bagID, slotID, readable)
    local scanTooltip = GetScanTooltip()
    if not scanTooltip then return false end

    scanTooltip:ClearLines()
    local ok = pcall(function()
        scanTooltip:SetBagItem(bagID, slotID)
    end)
    if not ok then return false end

    local numLines = scanTooltip:NumLines()
    if not numLines or numLines <= 0 then return false end

    local isQuest  = false
    local isUsable = false

    for i = 1, numLines do
        local leftObj = getglobal("ConsoleModeBagScanTooltipTextLeft" .. i)
        local leftTxt = (leftObj and leftObj:GetText()) or ""
        local lLow    = string.lower(leftTxt)

        -- Tipo: "Quest Item" (EN) ou "Missao" (PT-BR) ou variantes
        if string.find(lLow, "quest") or string.find(lLow, "miss") then
            isQuest = true
        end

        -- Linha de uso: "Use: ...", "Uso: ...", etc.
        if string.find(lLow, "use:") or string.find(lLow, "uso:")
        or string.find(lLow, "utilizar:") or string.find(lLow, "direito para")
        or string.find(lLow, "right") or string.find(lLow, "bot") then
            isUsable = true
        end
    end

    return isQuest and (isUsable or readable)
end

-- Varre bags 0-4 e retorna lista FIFO de itens quest usaveis (sem duplicatas).
-- Retorna: { [1] = { bagID, slotID, itemLink, itemID, itemName, texture }, ... }
function QID:GetUsableQuestItems()
    local BP = CM.config and CM.config.bagPicker
    if not BP then return {} end

    local items = {}
    local seenItemIDs = {}  -- set para evitar itens duplicados

    for _, bagID in ipairs(BP.BAG_IDS) do
        local numSlots = GetContainerNumSlots(bagID)
        if numSlots and numSlots > 0 then
            for slotID = 1, numSlots do
                local texture, count, locked, quality, readable =
                    GetContainerItemInfo(bagID, slotID)

                if texture then
                    local itemLink = GetContainerItemLink(bagID, slotID)
                    if itemLink and QID:IsQuestItem(bagID, slotID, readable) then
                        local _, _, extracted = string.find(itemLink, "%[(.-)%]")
                        local itemName = extracted or "Item"

                        local _, _, itemIDStr = string.find(itemLink, "item:(%d+)")
                        local itemID = tonumber(itemIDStr)

                        -- So adiciona se este itemID ainda nao foi visto
                        if itemID and not seenItemIDs[itemID] then
                            seenItemIDs[itemID] = true
                            tinsert(items, {
                                bagID    = bagID,
                                slotID   = slotID,
                                itemLink = itemLink,
                                itemID   = itemID,
                                itemName = itemName,
                                texture  = texture,
                            })
                        end
                    end
                end
            end
        end
    end

    return items
end

-- Retorna true se o itemID ainda existe em alguma bag (0-4).
function QID:IsItemInBag(itemID)
    if not itemID then return false end

    local BP = CM.config and CM.config.bagPicker
    if not BP then return false end

    for _, bagID in ipairs(BP.BAG_IDS) do
        local numSlots = GetContainerNumSlots(bagID)
        if numSlots and numSlots > 0 then
            for slotID = 1, numSlots do
                local texture = GetContainerItemInfo(bagID, slotID)
                if texture then
                    local itemLink = GetContainerItemLink(bagID, slotID)
                    if itemLink then
                        local _, _, itemIDStr = string.find(itemLink, "item:(%d+)")
                        if tonumber(itemIDStr) == itemID then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

-- ============================================================================
-- MANIPULACAO DE SLOTS DE ACAO (WoW 1.12)
-- ============================================================================

-- Coloca um item da bag num slot da action bar.
function QID:PlaceItemInSlot(bagID, slotID, actionSlot)
    local ok = pcall(function()
        PickupContainerItem(bagID, slotID)
        PlaceAction(actionSlot)
        ClearCursor()
    end)
    return ok
end

-- Limpa um slot da action bar de forma segura no WoW 1.12.
-- ClearCursor() -> PickupAction(slot) -> ClearCursor()
function QID:ClearActionSlot(actionSlot)
    pcall(function()
        ClearCursor()
        PickupAction(actionSlot)
        ClearCursor()
    end)
end

-- Obtem o nome do item colocado em um determinado slot da action bar.
function QID:GetSlotItemName(slot)
    local has = false
    pcall(function() has = HasAction(slot) end)
    if not has then return nil end

    -- Se for macro nomeada, nao e um item arrastado diretamente
    local macroText = nil
    pcall(function() macroText = GetActionText(slot) end)
    if macroText and macroText ~= "" then
        return nil
    end

    local scanTooltip = GetScanTooltip()
    scanTooltip:ClearLines()
    local ok = pcall(function() scanTooltip:SetAction(slot) end)
    if ok then
        local left1Obj = getglobal("ConsoleModeBagScanTooltipTextLeft1")
        local name = left1Obj and left1Obj:GetText()
        if name and name ~= "" then
            return name
        end
    end

    return nil
end

-- Verifica se um slot de acao corresponde a um item de quest especifico
function QID:SlotMatchesQuestItem(slot, qItem)
    local has = false
    pcall(function() has = HasAction(slot) end)
    if not has then return false end

    local macroText = nil
    pcall(function() macroText = GetActionText(slot) end)
    if macroText and macroText ~= "" then
        return false
    end

    -- 1. Verificacao via GetActionInfo (caso o client de 1.12 implemente)
    if GetActionInfo then
        local actionType, currentID = nil, nil
        pcall(function() actionType, currentID = GetActionInfo(slot) end)
        if actionType == "item" and currentID and qItem.itemID and tonumber(currentID) == tonumber(qItem.itemID) then
            return true
        end
    end

    -- 2. Verificacao via Tooltip (leitura do nome real do item)
    local slotItemName = QID:GetSlotItemName(slot)
    if slotItemName and qItem.itemName then
        if string.lower(slotItemName) == string.lower(qItem.itemName) then
            return true
        end
    end

    return false
end

-- Procura qual questItem da lista esta presente em um slot alvo
function QID:FindQuestItemInSlot(slot, questItems)
    local has = false
    pcall(function() has = HasAction(slot) end)
    if not has then return nil end

    -- 1. Via GetActionInfo
    if GetActionInfo then
        local actionType, currentID = nil, nil
        pcall(function() actionType, currentID = GetActionInfo(slot) end)
        if actionType == "item" and currentID then
            local numID = tonumber(currentID)
            for _, item in ipairs(questItems) do
                if item.itemID and tonumber(item.itemID) == numID then
                    return item
                end
            end
        end
    end

    -- 2. Via Tooltip
    local slotItemName = QID:GetSlotItemName(slot)
    if slotItemName then
        local lowerName = string.lower(slotItemName)
        for _, item in ipairs(questItems) do
            if item.itemName and string.lower(item.itemName) == lowerName then
                return item
            end
        end
    end

    return nil
end

-- ============================================================================
-- DEDUPLICADOR GLOBAL DE ITENS DE QUEST
-- ============================================================================

-- Varre todos os 120 slots de barras de acao do personagem, um por um.
-- Remove quaisquer duplicatas dos itens de missao que estejam fora dos slots designados.
function QID:RunDeduplicator(assignedItems, isManual)
    if not assignedItems then
        assignedItems = {}
        local qItems = QID:GetUsableQuestItems()
        for _, slot in ipairs(QID.TARGET_SLOTS) do
            local matched = QID:FindQuestItemInSlot(slot, qItems)
            if matched then
                assignedItems[slot] = matched
            end
        end
    end

    local activeItems = {}
    for actionSlot, qItem in pairs(assignedItems) do
        tinsert(activeItems, {
            itemID   = qItem.itemID,
            itemName = qItem.itemName,
            keepSlot = actionSlot,
        })
    end

    local numActive = table.getn(activeItems)
    if numActive == 0 then
        if isManual then
            QLog("[Deduplicador] Nenhum item de quest ativo no cluster para deduplicar.")
        else
            QDebug("[Deduplicador] Nenhum item de quest ativo no cluster para deduplicar.")
        end
        return
    end

    QDebug("[Deduplicador] Varrendo todas as barras (slots 1..120) em busca de duplicatas...")
    local removedCount = 0

    for slot = 1, 120 do
        local has = false
        pcall(function() has = HasAction(slot) end)
        if has then
            for _, qInfo in ipairs(activeItems) do
                -- Se for o slot designado para este item, mantem intacto
                if slot ~= qInfo.keepSlot then
                    if QID:SlotMatchesQuestItem(slot, qInfo) then
                        local dupName = qInfo.itemName or "Item"
                        QLog("[Deduplicador] Duplicata de '" .. dupName .. "' encontrada no slot " .. slot .. ".")
                        QID:ClearActionSlot(slot)
                        QLog("[Deduplicador] Duplicata do slot " .. slot .. " removida com sucesso.")
                        if QID.slotMap[slot] then
                            QID.slotMap[slot] = nil
                        end
                        removedCount = removedCount + 1
                        break
                    end
                end
            end
        end
    end

    if removedCount > 0 then
        QLog("[Deduplicador] Concluido: " .. removedCount .. " duplicata(s) removida(s).")
    elseif isManual then
        QLog("[Deduplicador] Nenhuma duplicata encontrada nas barras.")
    end
end

-- ============================================================================
-- DISTRIBUICAO NOS SLOTS (CLUSTER L2+R2)
-- ============================================================================

function QID:DistributeQuestItems(forceDedup)
    local questItems = QID:GetUsableQuestItems()
    local numItems   = table.getn(questItems)

    QDebug("--- Distribuindo. Items encontrados: " .. numItems .. " ---")
    for i = 1, numItems do
        QDebug("  Item " .. i .. ": " .. (questItems[i].itemName or "?") .. " (ID=" .. tostring(questItems[i].itemID) .. " bag=" .. questItems[i].bagID .. " slot=" .. questItems[i].slotID .. ")")
    end

    -- 1. Detectar e anunciar novos itens de missao encontrados na bolsa
    local currentIDs = {}
    for i = 1, numItems do
        local item = questItems[i]
        currentIDs[item.itemID] = true
        if not QID.knownItemIDs[item.itemID] then
            QID.knownItemIDs[item.itemID] = true
            QLog("Novo item de missao encontrado: |cffffff00[" .. (item.itemName or "Item") .. "]|r")
        end
    end
    -- Remove do set de conhecidos os itens que nao estao mais na bolsa
    for oldID, _ in pairs(QID.knownItemIDs) do
        if not currentIDs[oldID] then
            QID.knownItemIDs[oldID] = nil
        end
    end

    local itemsAdded = 0
    local assignedItems = {}       -- [slot] = qItem
    local allocatedItemIDs = {}    -- [itemID] = slot

    -- PASSO 1: Identificar quais slots alvo ja contem o quest item correto
    for _, actionSlot in ipairs(QID.TARGET_SLOTS) do
        local matched = QID:FindQuestItemInSlot(actionSlot, questItems)
        if matched and not allocatedItemIDs[matched.itemID] then
            allocatedItemIDs[matched.itemID] = actionSlot
            assignedItems[actionSlot] = matched
            QID.slotMap[actionSlot] = matched.itemID
            QDebug("Slot " .. actionSlot .. ": ja contem " .. matched.itemName .. " (mantido)")
        end
    end

    -- PASSO 2: Preencher slots restantes ou limpar slots invalidos/sem item
    local nextItemIdx = 1
    for _, actionSlot in ipairs(QID.TARGET_SLOTS) do
        local btnLabel = QID.SLOT_LABELS[actionSlot] or tostring(actionSlot)
        if not assignedItems[actionSlot] then
            -- Busca o proximo quest item ainda nao alocado
            local itemToPlace = nil
            while nextItemIdx <= numItems do
                local candidate = questItems[nextItemIdx]
                nextItemIdx = nextItemIdx + 1
                if not allocatedItemIDs[candidate.itemID] then
                    itemToPlace = candidate
                    break
                end
            end

            if itemToPlace then
                -- Limpa slot se tiver acao antiga/invalida
                local has = false
                pcall(function() has = HasAction(actionSlot) end)
                if has then
                    local oldName = QID:GetSlotItemName(actionSlot)
                    if oldName and oldName ~= "" then
                        QLog("Item '" .. oldName .. "' nao esta mais na bolsa. Limpando slot " .. actionSlot .. " (" .. btnLabel .. ").")
                    end
                    QID:ClearActionSlot(actionSlot)
                end

                local placed = QID:PlaceItemInSlot(itemToPlace.bagID, itemToPlace.slotID, actionSlot)
                if placed then
                    allocatedItemIDs[itemToPlace.itemID] = actionSlot
                    assignedItems[actionSlot] = itemToPlace
                    QID.slotMap[actionSlot] = itemToPlace.itemID
                    itemsAdded = itemsAdded + 1
                    QLog("Posicionando |cffffff00[" .. itemToPlace.itemName .. "]|r no slot " .. actionSlot .. " (" .. btnLabel .. ")")
                end
            else
                -- Sem mais itens de quest: limpa o slot alvo se estiver ocupado
                local has = false
                pcall(function() has = HasAction(actionSlot) end)
                if has then
                    local oldName = QID:GetSlotItemName(actionSlot) or "Item"
                    QLog("Item '" .. oldName .. "' nao esta mais na bolsa. Limpando slot " .. actionSlot .. " (" .. btnLabel .. ").")
                    QID:ClearActionSlot(actionSlot)
                end
                QID.slotMap[actionSlot] = nil
            end
        end
    end

    QDebug("--- Distribuicao concluida. Novos itens adicionados: " .. itemsAdded .. " ---")

    -- PASSO 3: Deduplicacao
    -- Dispara APOS ver/anexar os itens na barra:
    -- 1) Uma vez so depois do login/reload (primeira distribuicao)
    -- 2) Sempre que mais um item for adicionado pelo sistema de distribuicao (itemsAdded > 0)
    -- 3) Manualmente se solicitado (forceDedup)
    local isFirstLogin = not QID.initialDedupDone
    local shouldDedup  = isFirstLogin or (itemsAdded > 0) or (forceDedup == true)

    if shouldDedup then
        QID.initialDedupDone = true
        QID:RunDeduplicator(assignedItems, forceDedup)
    end
end

-- Permite acionamento manual do deduplicador para testes (/cm dedup)
function QID:ForceDeduplicate()
    QLog("Forcando redistribuicao e deduplicacao manual...")
    QID:DistributeQuestItems(true)
end

-- ============================================================================
-- INICIALIZACAO E EVENTOS
-- ============================================================================

function QID:Initialize()
    if QID.initialized then return end
    QID.initialized = true

    if not QID.eventFrame then
        QID.eventFrame = CreateFrame("Frame", "ConsoleModeQuestItemDistributorFrame")
    end

    local f = QID.eventFrame
    if not f then return end

    f:RegisterEvent("BAG_UPDATE")
    f:RegisterEvent("UNIT_INVENTORY_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("CHAT_MSG_LOOT")

    f:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            -- Delay no login: bolsas e itens ainda estao carregando
            QID.scanDelay = 4.0
            QID.scanTimer = 0
            QID.pollTimer = 0
            QID.initialDedupDone = false
        elseif event == "BAG_UPDATE" or event == "UNIT_INVENTORY_CHANGED" then
            -- Delay curto para updates de bolsa
            if QID.scanDelay <= 0 or QID.scanTimer < 0.5 then
                QID.scanDelay = 0.5
                QID.scanTimer = 0
            end
        elseif event == "CHAT_MSG_LOOT" then
            -- Delay medio para loot
            if QID.scanDelay <= 0 then
                QID.scanDelay = 1.0
                QID.scanTimer = 0
            end
        end
    end)

    f:SetScript("OnUpdate", function(elapsed)
        local dt = elapsed or arg1 or 0

        -- 1. Scan por evento com debounce
        if QID.scanDelay > 0 then
            QID.scanTimer = QID.scanTimer + dt
            if QID.scanTimer >= QID.scanDelay then
                QID.scanDelay = 0
                QID.scanTimer = 0
                QID.pollTimer = 0
                QID:DistributeQuestItems()
            end
        end

        -- 2. Polling periodico a cada 4 segundos (fallback para consistencia e economia de CPU)
        QID.pollTimer = QID.pollTimer + dt
        if QID.pollTimer >= QID.SCAN_INTERVAL then
            QID.pollTimer = 0
            QID:DistributeQuestItems()
        end
    end)
end
