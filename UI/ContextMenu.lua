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
Menu.currentMode = "MENU" -- "MENU" ou "SPLIT"
Menu.returnButton = nil

function Menu:Initialize()
    if self.frame then return end

    -- Frame Principal Flutuante
    local f = CreateFrame("Frame", "ConsoleModeContextMenu", UIParent)
    f:SetWidth(156)
    f:SetHeight(125)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
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
        { id = 3, label = "Excluir / Destruir", color = { r=0.95, g=0.3, b=0.3 }, action = "DROP" },
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

        local thisAction = def.action
        btn:SetScript("OnClick", function()
            Menu:ExecuteAction(thisAction)
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
    if itemLink then
        local ok, n = pcall(function() return GetItemInfo(itemLink) end)
        if ok and n then
            itemName = n
        else
            local _, _, extracted = string.find(itemLink, "%[(.-)%%]")
            if extracted then itemName = extracted end
        end
    end

    self.currentBag = bagID
    self.currentSlot = slotID
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

    -- Configura View Inicial (Menu)
    self.frame.menuView:Show()
    self.frame.splitView:Hide()


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
        if count and count > 1 then
            splitBtn:Enable()
            splitBtn.text:SetTextColor(0.3, 0.7, 1.0)
        else
            splitBtn:Disable()
            splitBtn.text:SetTextColor(0.45, 0.45, 0.45)
        end
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
        local targetBtn = self.buttons[1]
        if not isUsable then
            if count and count > 1 and self.buttons[2] and (self.buttons[2]:Enabled() == 1 or self.buttons[2]:IsEnabled() == true) then
                targetBtn = self.buttons[2]
            elseif self.buttons[3] then
                targetBtn = self.buttons[3]
            end
        end
        if targetBtn then
            CM.cursor:MoveTo(targetBtn)
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
    self.currentMode = "MENU"
    self.returnButton = nil
end

function Menu:ExecuteAction(action)
    local bagID  = self.currentBag
    local slotID = self.currentSlot
    local returnBtn = self.returnButton

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

    elseif action == "DROP" or action == "DELETE" then
        self:Close()
        PickupContainerItem(bagID, slotID)
        if CursorHasItem() then
            DeleteCursorItem()
        end
    end
end
