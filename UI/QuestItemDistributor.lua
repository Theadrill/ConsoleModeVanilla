--[[
    ConsoleMode - Vanilla
    UI/QuestItemDistributor.lua

    PASSO 1: Infraestrutura + Scan de Bags
    - Module skeleton com TARGET_SLOTS e SCAN_INTERVAL
    - Event frame registrado para BAG_UPDATE, UNIT_INVENTORY_CHANGED,
      PLAYER_ENTERING_WORLD, CHAT_MSG_LOOT
    - GetUsableQuestItems(): varre bags 0-4, reutiliza BP:IsUsableItem()
    - Debug print temporario listando itens encontrados
    - Compativel com Lua 5.0 / WoW 1.12

    Compativel com Lua 5.0 / WoW 1.12
]]

local CM = ConsoleMode
CM.questItemDistributor = CM.questItemDistributor or {}

local QID = CM.questItemDistributor

-- Slots-alvo no cluster L2+R2 (pagina 5), ordem de distribuicao
QID.TARGET_SLOTS = {39, 38, 37, 43, 44, 45, 46}  -- B, Y, X, D-UP, D-DOWN, D-LEFT, D-RIGHT

-- Intervalo entre scans (segundos)
QID.SCAN_INTERVAL = 3

-- Track de itens atualmente nos slots alvo: [slotID] = itemID
QID.slotMap = {}

-- Referencia ao frame de eventos
QID.eventFrame = nil

-- Flag suja para forcar re-scan no proximo OnUpdate
QID.dirty = false

-- Timer de delay antes de rodar o scan (evita rodar antes das bags carregarem)
QID.scanDelay  = 0
QID.scanTimer  = 0
-- Intervalo do timer periodico (segundos)
QID.TICK_INTERVAL = 0.1

-- ============================================================================
-- VARREDURA DE ITEMS DE QUEST USAVEIS
-- ============================================================================

-- Verifica via tooltip se o item e do tipo Quest/Missao.
-- O tipo aparece na ultima linha do tooltip (canto inferior direito).
-- Reutiliza o scanTooltip ja criado no BagPicker.
function QID:IsQuestItem(bagID, slotID, readable)
    local scanTooltip = getglobal("ConsoleModeBagScanTooltip")
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
        local leftObj  = getglobal("ConsoleModeBagScanTooltipTextLeft" .. i)
        local leftTxt  = (leftObj and leftObj:GetText()) or ""
        local lLow     = string.lower(leftTxt)

        -- Tipo: "Quest Item" ou "Missao" ou variantes
        if string.find(lLow, "quest") or string.find(lLow, "miss") then
            isQuest = true
        end

        -- Efeito de uso
        if string.find(lLow, "use:") or string.find(lLow, "uso:")
        or string.find(lLow, "utilizar:") or string.find(lLow, "direito para")
        or string.find(lLow, "right") or string.find(lLow, "bot") then
            isUsable = true
        end
    end

    return isQuest and (isUsable or readable)
end

-- Varre bags 0-4 e retorna lista FIFO de itens quest usaveis.
-- Retorna: { [1] = { bagID, slotID, itemLink, itemID, itemName }, ... }
function QID:GetUsableQuestItems()
    local BP = CM.config and CM.config.bagPicker
    if not BP then return {} end

    local items = {}

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

                        print("|cff00ff00[CM-Quest]|r Item de quest: " .. itemName)

                        tinsert(items, {
                            bagID    = bagID,
                            slotID   = slotID,
                            itemLink = itemLink,
                            itemID   = itemID,
                            itemName = itemName,
                        })
                    end
                end
            end
        end
    end

    if table.getn(items) == 0 then
        print("|cff888888[CM-Quest]|r Nenhum item de quest usavel encontrado.")
    end

    return items
end

-- ============================================================================
-- INICIALIZACAO
-- ============================================================================

-- Cria o event frame e registra eventos
function QID:Initialize()
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
            QID.scanDelay = 3.0
            QID.scanTimer = 0
        elseif event == "BAG_UPDATE" or event == "UNIT_INVENTORY_CHANGED" then
            QID.scanDelay = 0.5
            QID.scanTimer = 0
        elseif event == "CHAT_MSG_LOOT" then
            QID.scanDelay = 1.0
            QID.scanTimer = 0
        end
    end)

    f:SetScript("OnUpdate", function(elapsed)
        -- No WoW 1.12 o elapsed pode vir como arg1 em vez de parametro
        local dt = elapsed or arg1 or 0
        if QID.scanDelay > 0 then
            QID.scanTimer = QID.scanTimer + dt
            if QID.scanTimer >= QID.scanDelay then
                QID.scanDelay = 0
                QID.scanTimer = 0
                QID:GetUsableQuestItems()
            end
        end
    end)
end
