--[[
    ConsoleMode - Vanilla
    UI/ContextMenu.lua

    Menu de Contexto Flutuante Estilo Console para a Bolsa (Bag):
    - Modo Menu: Usar / Equipar, Dividir (Split), Excluir / Destruir
    - Modo Split: Seletor nativo de divisão de pilhas com suporte total a D-Pad (◄ / ◅, Cima/Baixo)

    Compatível com Lua 5.0 / WoW 1.12
]]

local CM = ConsoleMode
CM.ui = CM.ui or {}
local Menu = CM.ui.contextMenu or {}
CM.ui.contextMenu = Menu

Menu.frame = nil
Menu.buttons = {}
Menu.currentBag = nil
Menu.currentSlot = nil
Menu.currentMax = 1
Menu.currentSplit = 1
Menu.currentMode = "MENU" -- "MENU", "SPLIT", ou "QUEST_MENU"
Menu.currentQuestIndex = nil
Menu.returnButton = nil

function Menu:Initialize()
    if self.frame then return end

    -- Frame Principal Flutuante
    local f = CreateFrame("Frame", "ConsoleModeContextMenu", UIParent)
    f:SetWidth(156)
    f:SetHeight(152)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(500)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    f:SetBackdropBorderColor(0.8, 0.65, 0.15, 0.9) -- Dourado sutil
    f:EnableMouse(true)
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("TOP", f, "TOP", 0, -6)
    title:SetWidth(140)
    title:SetJustifyH("CENTER")
    title:SetTextColor(1.0, 0.85, 0.2)
    f.title = title

    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -20)
    line:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -6, -21)
    line:SetTexture(0.5, 0.5, 0.5, 0.5)

    -- ====================================================================
    -- VIEW 1: MENU PRINCIPAL
    -- ====================================================================
    local menuView = CreateFrame("Frame", "ConsoleModeContextMenuMenuView", f)
    menuView:SetAllPoints(f)
    f.menuView = menuView

    local btnDefs = {
        { id = 1, label = "Usar / Equipar",     color = { r=0.2, g=0.9, b=0.3 }, action = "USE" },
        { id = 2, label = "Dividir (Split)",    color = { r=0.3, g=0.7, b=1.0 }, action = "SPLIT" },
        { id = 3, label = "Re-Stack (Agrupar)", color = { r=1.0, g=0.85, b=0.2 }, action = "RESTACK" },
        { id = 4, label = "Excluir / Destruir", color = { r=0.95, g=0.3, b=0.3 }, action = "DROP" },
    }

    self.buttons = {}
    for i, def in ipairs(btnDefs) do
        local btn = CreateFrame("Button", "ConsoleModeContextMenuBtn" .. i, menuView)
        btn:SetWidth(142)
        btn:SetHeight(24)
        btn:SetPoint("TOP", menuView, "TOP", 0, -24 - ((i - 1) * 27))

        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        btn:SetBackdropColor(0.12, 0.12, 0.15, 0.85)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER", btn, "CENTER", 0, 0)
        text:SetText(def.label)
        text:SetTextColor(def.color.r, def.color.g, def.color.b)
        btn.text = text
        btn.action = def.action

        btn:SetScript("OnClick", function()
            Menu:ExecuteAction(this.action)
        end)

        btn:SetScript("OnEnter", function()
            this:SetBackdropBorderColor(1.0, 0.85, 0.2, 1.0)
            this:SetBackdropColor(0.2, 0.2, 0.28, 0.95)
        end)

        btn:SetScript("OnLeave", function()
            this:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
            this:SetBackdropColor(0.12, 0.12, 0.15, 0.85)
        end)

        self.buttons[i] = btn
    end

    -- ====================================================================
    -- VIEW 2: SELETOR DE SPLIT (Dividir Pilha)
    -- ====================================================================
    local splitView = CreateFrame("Frame", "ConsoleModeContextMenuSplitView", f)
    splitView:SetAllPoints(f)
    splitView:Hide()
    f.splitView = splitView


    local countBox = CreateFrame("Frame", "ConsoleModeContextSplitCountBox", splitView)
    countBox:SetWidth(142)
    countBox:SetHeight(32)
    countBox:SetPoint("TOP", splitView, "TOP", 0, -26)
    countBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    countBox:SetBackdropColor(0.04, 0.04, 0.06, 0.9)
    countBox:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)

    local btnLeft = CreateFrame("Button", "ConsoleModeContextSplitLeftBtn", countBox, "UIPanelButtonTemplate")
    btnLeft:SetWidth(24)
    btnLeft:SetHeight(24)
    btnLeft:SetPoint("LEFT", countBox, "LEFT", 4, 0)
    btnLeft:SetText("<")
    btnLeft:SetScript("OnClick", function() Menu:AdjustSplit(-1) end)


    local btnRight = CreateFrame("Button", "ConsoleModeContextSplitRightBtn", countBox, "UIPanelButtonTemplate")
    btnRight:SetWidth(24)
    btnRight:SetHeight(24)
    btnRight:SetPoint("RIGHT", countBox, "RIGHT", -4, 0)
    btnRight:SetText(">")
    btnRight:SetScript("OnClick", function() Menu:AdjustSplit(1) end)


    local splitCountText = countBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    splitCountText:SetPoint("CENTER", countBox, "CENTER", 0, 0)
    splitCountText:SetTextColor(1.0, 1.0, 1.0)
    splitCountText:SetText("1 / 1")
    f.splitCountText = splitCountText


    local btnConfirm = CreateFrame("Button", "ConsoleModeContextSplitConfirmBtn", splitView, "UIPanelButtonTemplate")
    btnConfirm:SetWidth(142)
    btnConfirm:SetHeight(24)
    btnConfirm:SetPoint("TOP", countBox, "BOTTOM", 0, -6)
    btnConfirm:SetText("[A] Confirmar")
    btnConfirm:SetScript("OnClick", function() Menu:ConfirmSplit() end)
    f.btnConfirm = btnConfirm


    local splitHint = splitView:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    splitHint:SetPoint("BOTTOM", splitView, "BOTTOM", 0, 6)
    splitHint:SetTextColor(0.65, 0.65, 0.65)
    splitHint:SetText("[Pad] Quantidade  [B] Voltar")
    f.splitHint = splitHint

    self.frame = f
end

function Menu:OpenForBagItem(bagID, slotID, anchorFrame)
    if not bagID or not slotID then return false end

    self:Initialize()

    local texture, count = GetContainerItemInfo(bagID, slotID)
    if not texture then return false end -- slot vazio

    count = count or 1

    local itemLink = GetContainerItemLink(bagID, slotID)
    local itemName = "Item"
    local itemID = nil
    local maxStack = 1

    if itemLink then
        local _, _, extractedID = string.find(itemLink, "item:(%d+)")
        if extractedID then
            itemID = tonumber(extractedID)
            local n, _, _, _, _, _, mStack = GetItemInfo(itemID)
            if n then itemName = n end
            if mStack then maxStack = tonumber(mStack) or 1 end
        end
        if itemName == "Item" then
            local _, _, extractedName = string.find(itemLink, "%[(.-)%]")
            if extractedName then itemName = extractedName end
        end
    end

    self.currentBag = bagID
    self.currentSlot = slotID
    self.currentInvSlot = nil
    self.currentMax = count
    self.currentSplit = math.floor(count / 2)
    if self.currentSplit < 1 then self.currentSplit = 1 end
    self.currentMode = "MENU"
    self.returnButton = anchorFrame
    self.itemName = itemName

    -- Título encurtado se for muito longo
    if string.len(itemName) > 18 then
        self.frame.title:SetText(string.sub(itemName, 1, 16) .. "..")
    else
        self.frame.title:SetText(itemName)
    end

    -- Configura View Inicial (Menu da Bolsa)
    self.frame.menuView:Show()
    self.frame.splitView:Hide()
    self.frame:SetHeight(152)

    local isUsable = false
    local BP = CM.config and CM.config.bagPicker
    if BP and BP.IsUsableItem then
        local _, _, _, _, readable = GetContainerItemInfo(bagID, slotID)
        isUsable = BP:IsUsableItem(itemLink, bagID, slotID, readable)
    else
        isUsable = true
    end


    local useBtn = self.buttons[1]
    if useBtn then
        useBtn:Show()
        useBtn.text:SetText("Usar / Equipar")
        useBtn.action = "USE"
        if isUsable then
            useBtn:Enable()
            useBtn.text:SetTextColor(0.2, 0.9, 0.3)
        else
            useBtn:Disable()
            useBtn.text:SetTextColor(0.45, 0.45, 0.45)
        end
    end


    local splitBtn = self.buttons[2]
    if splitBtn then
        splitBtn:Show()
        splitBtn.action = "SPLIT"
        if count and count > 1 then
            splitBtn:Enable()
            splitBtn.text:SetTextColor(0.3, 0.7, 1.0)
        else
            splitBtn:Disable()
            splitBtn.text:SetTextColor(0.45, 0.45, 0.45)
        end
    end

    local restackBtn = self.buttons[3]
    if restackBtn then
        restackBtn:Show()
        restackBtn.action = "RESTACK"
        -- Se a quantidade for maior que 1 ou o maxStack > 1, o item é comprovadamente empilhável
        if count > 1 or maxStack > 1 then
            restackBtn:Enable()
            restackBtn.text:SetTextColor(1.0, 0.85, 0.2)
        else
            restackBtn:Disable()
            restackBtn.text:SetTextColor(0.45, 0.45, 0.45)
        end
    end

    local dropBtn = self.buttons[4]
    if dropBtn then
        dropBtn:Show()
        dropBtn:Enable()
        dropBtn.text:SetText("Excluir / Destruir")
        dropBtn.text:SetTextColor(0.95, 0.3, 0.3)
        dropBtn.action = "DROP"
    end


    self.frame:ClearAllPoints()
    if anchorFrame then
        local left = anchorFrame:GetLeft() or 0
        local screenW = GetScreenWidth() or 1024
        if left > (screenW / 2) then
            self.frame:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -6, 10)
        else
            self.frame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 6, 10)
        end
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    self.frame:Show()
    PlaySound("igMainMenuOptionCheckBoxOn")


    if CM.cursor then
        CM.cursor.state.activeFrames[self.frame] = true
        local targetBtn = nil
        if self.buttons then
            for i = 1, table.getn(self.buttons) do
                local b = self.buttons[i]
                if b and b:IsVisible() and (b:IsEnabled() == 1 or b:IsEnabled() == true) then
                    targetBtn = b
                    break
                end
            end
        end
        if not targetBtn then targetBtn = self.buttons and self.buttons[1] end
        if targetBtn then
            CM.cursor:MoveTo(targetBtn)
            CM.cursor:UpdateState()
        end
    end

    return true
end

function Menu:OpenForEquipItem(invSlotID, anchorFrame)
    if not invSlotID then return false end

    self:Initialize()

    local itemTexture = GetInventoryItemTexture("player", invSlotID)
    local itemLink = GetInventoryItemLink("player", invSlotID)
    if not itemTexture or not itemLink then
        -- Slot vazio, nada a desequipar
        return false
    end

    local itemName = "Item"
    local itemID = nil
    if itemLink then
        local _, _, extractedID = string.find(itemLink, "item:(%d+)")
        if extractedID then
            itemID = tonumber(extractedID)
            local n = GetItemInfo(itemID)
            if n then itemName = n end
        end
        if itemName == "Item" then
            local _, _, extractedName = string.find(itemLink, "%[(.-)%]")
            if extractedName then itemName = extractedName end
        end
    end

    self.currentMode = "EQUIP_MENU"
    self.currentInvSlot = invSlotID
    self.currentBag = nil
    self.currentSlot = nil
    self.returnButton = anchorFrame
    self.itemName = itemName

    -- Título encurtado se for muito longo
    if string.len(itemName) > 18 then
        self.frame.title:SetText(string.sub(itemName, 1, 16) .. "..")
    else
        self.frame.title:SetText(itemName)
    end

    -- Configura botões para o modo de Equipamento
    self.frame.menuView:Show()
    self.frame.splitView:Hide()
    self.frame:SetHeight(68)

    -- Botão 1: Desequipar
    local unequipBtn = self.buttons[1]
    if unequipBtn then
        unequipBtn:Show()
        unequipBtn:Enable()
        unequipBtn.text:SetText("Desequipar (Unequip)")
        unequipBtn.text:SetTextColor(0.3, 0.8, 1.0)
        unequipBtn.action = "UNEQUIP"
    end

    -- Esconde botões 2, 3 e 4 no modo Equip
    if self.buttons[2] then self.buttons[2]:Hide(); self.buttons[2]:Disable() end
    if self.buttons[3] then self.buttons[3]:Hide(); self.buttons[3]:Disable() end
    if self.buttons[4] then self.buttons[4]:Hide(); self.buttons[4]:Disable() end

    self.frame:ClearAllPoints()
    if anchorFrame then
        local left = anchorFrame:GetLeft() or 0
        local screenW = GetScreenWidth() or 1024
        if left > (screenW / 2) then
            self.frame:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -6, 10)
        else
            self.frame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 6, 10)
        end
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    self.frame:Show()
    PlaySound("igMainMenuOptionCheckBoxOn")

    if CM.cursor then
        CM.cursor.state.activeFrames[self.frame] = true
        if unequipBtn then
            CM.cursor:MoveTo(unequipBtn)
            CM.cursor:UpdateState()
        end
    end

    return true
end

function Menu:SwitchToSplitView()
    self.currentMode = "SPLIT"
    self.frame.title:SetText("Dividir Pilha")
    self.frame.menuView:Hide()
    self.frame.splitView:Show()
    self:UpdateSplitDisplay()

    if CM.cursor and self.frame.btnConfirm then
        CM.cursor:MoveTo(self.frame.btnConfirm)
        CM.cursor:UpdateState()
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function Menu:SwitchToMenuView()
    self.currentMode = "MENU"
    if self.itemName then
        if string.len(self.itemName) > 18 then
            self.frame.title:SetText(string.sub(self.itemName, 1, 16) .. "..")
        else
            self.frame.title:SetText(self.itemName)
        end
    end
    self.frame.splitView:Hide()
    self.frame.menuView:Show()

    if CM.cursor and self.buttons[2] then
        CM.cursor:MoveTo(self.buttons[2])
        CM.cursor:UpdateState()
    end
    PlaySound("igMainMenuOptionCheckBoxOff")
end

function Menu:UpdateSplitDisplay()
    if not self.frame or not self.frame.splitCountText then return end
    self.frame.splitCountText:SetText(
        "|cffffd200" .. self.currentSplit .. "|r / " .. self.currentMax
    )
end

function Menu:AdjustSplit(delta)
    if self.currentMode ~= "SPLIT" then return end
    local maxCount = self.currentMax or 1
    local newSplit = self.currentSplit + delta
    if newSplit < 1 then newSplit = 1 end
    if newSplit >= maxCount then newSplit = maxCount - 1 end
    if newSplit < 1 then newSplit = 1 end

    self.currentSplit = newSplit
    self:UpdateSplitDisplay()
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function Menu:ConfirmSplit()
    local bagID = self.currentBag
    local slotID = self.currentSlot
    local count = self.currentSplit
    self:Close()

    if bagID and slotID and count and count >= 1 then
        SplitContainerItem(bagID, slotID, count)
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function Menu:Close()
    if not self.frame or not self.frame:IsVisible() then return end

    self.frame:Hide()
    PlaySound("igMainMenuOptionCheckBoxOff")

    if CM.cursor then
        CM.cursor.state.activeFrames[self.frame] = nil
        -- Retorna o foco do cursor para o botão da bolsa de onde partiu
        if self.returnButton and self.returnButton:IsVisible() then
            CM.cursor:MoveTo(self.returnButton)
            CM.cursor:UpdateState()
        end
    end

    self.currentBag = nil
    self.currentSlot = nil
    self.currentInvSlot = nil
    self.currentMode = "MENU"
    self.returnButton = nil
end

function Menu:ExecuteAction(action)
    local bagID  = self.currentBag
    local slotID = self.currentSlot
    local invSlot = self.currentInvSlot
    local returnBtn = self.returnButton

    if action == "QUEST_WATCH" then
        local qIdx = self.currentQuestIndex
        self:Close()
        if qIdx and CM.mainMenu and CM.mainMenu.ToggleQuestWatch then
            CM.mainMenu:ToggleQuestWatch(qIdx)
        end
        return
    elseif action == "QUEST_SHARE" then
        local qIdx = self.currentQuestIndex
        self:Close()
        if qIdx and CM.mainMenu and CM.mainMenu.ShareSelectedQuest then
            CM.mainMenu.selectedQuestIndex = qIdx
            CM.mainMenu:ShareSelectedQuest()
        end
        return
    elseif action == "QUEST_ABANDON" then
        local qIdx = self.currentQuestIndex
        self:Close()
        if qIdx and CM.mainMenu and CM.mainMenu.AbandonSelectedQuest then
            CM.mainMenu.selectedQuestIndex = qIdx
            CM.mainMenu:AbandonSelectedQuest()
        end
        return
    end

    if action == "UNEQUIP" then
        self:Close()
        if invSlot then
            PickupInventoryItem(invSlot)
            PutItemInBackpack()
            if CursorHasItem() then ClearCursor() end
            PlaySound("igMainMenuOptionCheckBoxOn")
            if CM.mainMenu and CM.mainMenu.UpdateEquipmentColumn then
                CM.mainMenu:UpdateEquipmentColumn()
                CM.mainMenu:UpdatePlayerModel()
            end
        end
        return
    end

    if not bagID or not slotID then
        self:Close()
        return
    end

    if action == "USE" then
        if self.buttons[1] and (self.buttons[1]:IsEnabled() == 0 or self.buttons[1]:IsEnabled() == false) then
            return
        end
        self:Close()
        UseContainerItem(bagID, slotID)
        if SpellIsTargeting and SpellIsTargeting() and UnitExists("target") then
            SpellTargetUnit("target")
        end

    elseif action == "SPLIT" then
        -- Abre o seletor nativo do ConsoleMode
        self:SwitchToSplitView()

    elseif action == "RESTACK" then
        if self.buttons[3] and (self.buttons[3]:IsEnabled() == 0 or self.buttons[3]:IsEnabled() == false) then
            return
        end
        self:Close()
        self:RestackItem(bagID, slotID)

    elseif action == "DROP" or action == "DELETE" then
        self:Close()
        PickupContainerItem(bagID, slotID)
        if CursorHasItem() then
            DeleteCursorItem()
        end
    end
end

-- ============================================================================
-- MOTOR DE RE-STACK (CONSOLIDAÇÃO MULTI-PASS ASSÍNCRONA)
-- ============================================================================

local restackTicker = CreateFrame("Frame", "ConsoleModeRestackTicker", UIParent)
restackTicker:Hide()

restackTicker:SetScript("OnUpdate", function()
    local elapsed = arg1 or 0.016
    this.timer = (this.timer or 0) - elapsed
    if this.timer > 0 then return end
    this.timer = this.stepDelay or 0.05

    -- Se o jogador tiver algo preso no cursor, devolve
    if CursorHasItem() then
        if this.lastSrcBag and this.lastSrcSlot then
            PickupContainerItem(this.lastSrcBag, this.lastSrcSlot)
        else
            ClearCursor()
        end
        return
    end

    this.maxSteps = (this.maxSteps or 30) - 1
    if this.maxSteps <= 0 then
        this:Hide()
        return
    end

    local matchPattern = this.matchPattern
    local maxStack = this.maxStack or 1

    -- Varre os slots atuais em tempo real
    local partialSlots = {}
    local fullSlots = {}

    for b = 0, 4 do
        local numSlots = GetContainerNumSlots(b)
        if numSlots and numSlots > 0 then
            for s = 1, numSlots do
                local slotLink = GetContainerItemLink(b, s)
                if slotLink and string.find(slotLink, matchPattern, 1, true) then
                    local _, count, locked = GetContainerItemInfo(b, s)
                    if locked then
                        -- Slot ainda travado pelo tick anterior, aguarda próximo tick
                        return
                    end
                    if count and count > 0 then
                        if count < maxStack then
                            table.insert(partialSlots, { bag = b, slot = s, count = count })
                        else
                            table.insert(fullSlots, { bag = b, slot = s, count = count })
                        end
                    end
                end
            end
        end
    end

    local numPartial = table.getn(partialSlots)
    if numPartial <= 1 then
        -- Todas as pilhas parciais foram unificadas!
        this:Hide()
        PlaySound("igMainMenuOptionCheckBoxOn")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Todas as pilhas de " .. (this.itemName or "Item") .. " foram consolidadas!")
        return
    end

    -- Pega o primeiro slot incompleto (destino) e o último slot incompleto (origem)
    local dest = partialSlots[1]
    local src = partialSlots[numPartial]

    if dest and src and (dest.bag ~= src.bag or dest.slot ~= src.slot) then
        this.lastSrcBag = src.bag
        this.lastSrcSlot = src.slot
        PickupContainerItem(src.bag, src.slot)
        PickupContainerItem(dest.bag, dest.slot)
        if CursorHasItem() then
            PickupContainerItem(src.bag, src.slot)
        end
    else
        this:Hide()
    end
end)

function Menu:RestackItem(bagID, slotID)
    if not bagID or not slotID then return end

    local link = GetContainerItemLink(bagID, slotID)
    if not link then return end

    local _, _, extractedID = string.find(link, "item:(%d+)")
    if not extractedID then return end

    local itemID = tonumber(extractedID)
    local itemName, _, _, _, _, _, mStack = GetItemInfo(itemID)
    local maxStack = tonumber(mStack) or 1
    if maxStack <= 1 then
        local _, curCount = GetContainerItemInfo(bagID, slotID)
        if curCount and curCount > 1 then
            maxStack = curCount
        else
            return
        end
    end

    -- Configura e inicia o motor de consolidação contínua
    restackTicker.targetID = itemID
    restackTicker.matchPattern = "item:" .. extractedID .. ":"
    restackTicker.maxStack = maxStack
    restackTicker.itemName = itemName or "Item"
    restackTicker.timer = 0
    restackTicker.stepDelay = 0.05
    restackTicker.maxSteps = 30
    restackTicker.lastSrcBag = nil
    restackTicker.lastSrcSlot = nil
    restackTicker:Show()
end

-- ============================================================================
-- CONTEXTO DE MISSÕES (Etapa 9.6 - Botão Y)
-- ============================================================================

function Menu:OpenForQuest(questLogIndex, questTitle)
    if not questLogIndex or questLogIndex <= 0 then return false end

    self:Initialize()

    self.currentMode = "QUEST_MENU"
    self.currentQuestIndex = questLogIndex
    self.currentBag = nil
    self.currentSlot = nil
    self.currentInvSlot = nil
    self.returnButton = nil

    local displayName = questTitle or "Missao"
    if string.len(displayName) > 18 then
        displayName = string.sub(displayName, 1, 16) .. ".."
    end
    self.frame.title:SetText(displayName)

    self.frame.menuView:Show()
    self.frame.splitView:Hide()
    self.frame:SetHeight(124)

    local isWatched = (IsQuestWatched and IsQuestWatched(questLogIndex)) or false
    local canShare = false
    if SelectQuestLogEntry then SelectQuestLogEntry(questLogIndex) end
    if GetQuestLogPushable then canShare = GetQuestLogPushable() end
    local numParty = (GetNumPartyMembers and GetNumPartyMembers()) or 0

    local btn1 = self.buttons[1]
    if btn1 then
        btn1:Show()
        btn1:Enable()
        if isWatched then
            btn1.text:SetText("Parar de Rastrear")
            btn1.text:SetTextColor(0.95, 0.6, 0.2)
        else
            btn1.text:SetText("Rastrear no HUD")
            btn1.text:SetTextColor(0.2, 0.9, 0.3)
        end
        btn1.action = "QUEST_WATCH"
    end

    local btn2 = self.buttons[2]
    if btn2 then
        btn2:Show()
        if canShare and numParty > 0 then
            btn2:Enable()
            btn2.text:SetText("Compartilhar")
            btn2.text:SetTextColor(0.3, 0.7, 1.0)
        else
            btn2:Disable()
            btn2.text:SetText("Compartilhar")
            btn2.text:SetTextColor(0.45, 0.45, 0.45)
        end
        btn2.action = "QUEST_SHARE"
    end

    local btn3 = self.buttons[3]
    if btn3 then
        btn3:Show()
        btn3:Enable()
        btn3.text:SetText("Abandonar")
        btn3.text:SetTextColor(0.95, 0.3, 0.3)
        btn3.action = "QUEST_ABANDON"
    end

    local btn4 = self.buttons[4]
    if btn4 then btn4:Hide(); btn4:Disable() end

    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.frame:Show()
    PlaySound("igMainMenuOptionCheckBoxOn")

    if CM.cursor then
        CM.cursor.state.activeFrames[self.frame] = true
        if btn1 then
            CM.cursor:MoveTo(btn1)
            CM.cursor:UpdateState()
        end
    end

    return true
end
