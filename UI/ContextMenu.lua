--[[
    ConsoleMode - Vanilla
    UI/ContextMenu.lua

    Menu de Contexto Flutuante Estilo Console para a Bolsa (Bag):
    - Usar / Equipar
    - Dividir (Split)
    - Largar / Mover

    Compatível com Lua 5.0 / WoW 1.12
]]

local CM = ConsoleMode
CM.ui = CM.ui or {}
CM.ui.contextMenu = CM.ui.contextMenu or {}
local Menu = CM.ui.contextMenu

Menu.frame = nil
Menu.buttons = {}
Menu.currentBag = nil
Menu.currentSlot = nil
Menu.returnButton = nil

function Menu:Initialize()
    if self.frame then return end

    -- Frame Principal Flutuante
    local f = CreateFrame("Frame", "ConsoleModeContextMenu", UIParent)
    f:SetWidth(150)
    f:SetHeight(115)
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
    title:SetWidth(135)
    title:SetJustifyH("CENTER")
    title:SetTextColor(1.0, 0.85, 0.2)
    f.title = title

    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -20)
    line:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -6, -21)
    line:SetTexture(0.5, 0.5, 0.5, 0.5)

    local btnDefs = {
        { id = 1, label = "Usar / Equipar", color = { r=0.2, g=0.9, b=0.3 }, action = "USE" },
        { id = 2, label = "Dividir (Split)", color = { r=0.3, g=0.7, b=1.0 }, action = "SPLIT" },
        { id = 3, label = "Excluir / Destruir", color = { r=0.95, g=0.3, b=0.3 }, action = "DROP" },
    }


    self.buttons = {}
    for i, def in ipairs(btnDefs) do
        local btn = CreateFrame("Button", "ConsoleModeContextMenuBtn" .. i, f)
        btn:SetWidth(136)
        btn:SetHeight(24)
        btn:SetPoint("TOP", f, "TOP", 0, -24 - ((i - 1) * 27))

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

    self.frame = f
end

function Menu:OpenForBagItem(bagID, slotID, anchorFrame)
    if not bagID or not slotID then return false end

    self:Initialize()

    local texture, count = GetContainerItemInfo(bagID, slotID)
    if not texture then return false end -- slot vazio

    local itemLink = GetContainerItemLink(bagID, slotID)
    local itemName = "Item"
    if itemLink then
        local ok, n = pcall(function() return GetItemInfo(itemLink) end)
        if ok and n then
            itemName = n
        else
            local _, _, extracted = string.find(itemLink, "%[(.-)%]")
            if extracted then itemName = extracted end
        end
    end

    self.currentBag = bagID
    self.currentSlot = slotID
    self.returnButton = anchorFrame

    -- Título encurtado se for muito longo
    if string.len(itemName) > 18 then
        self.frame.title:SetText(string.sub(itemName, 1, 16) .. "..")
    else
        self.frame.title:SetText(itemName)
    end

    -- Habilita / Desabilita opção de Split
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

    -- Posiciona ao lado do botão da bolsa
    self.frame:ClearAllPoints()
    if anchorFrame then
        local left = anchorFrame:GetLeft() or 0
        local screenW = GetScreenWidth() or 1024
        if left > (screenW / 2) then
            -- Está na metade direita: abre à esquerda
            self.frame:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -6, 10)
        else
            -- Está na metade esquerda: abre à direita
            self.frame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 6, 10)
        end
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    self.frame:Show()
    PlaySound("igMainMenuOptionCheckBoxOn")

    -- Ativa a janela no Cursor e joga o foco DIRETO para a primeira opção (Usar)
    if CM.cursor then
        CM.cursor.state.activeFrames[self.frame] = true
        if self.buttons[1] then
            CM.cursor:MoveTo(self.buttons[1])
            CM.cursor:UpdateState()
        end
    end

    return true
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
        self:Close()
        UseContainerItem(bagID, slotID)
        if SpellIsTargeting and SpellIsTargeting() and UnitExists("target") then
            SpellTargetUnit("target")
        end

    elseif action == "SPLIT" then
        local texture, count = GetContainerItemInfo(bagID, slotID)
        self:Close()
        if count and count > 1 then
            -- Se o StackSplitFrame do WoW existir, abre ele
            if OpenStackSplitFrame and returnBtn then
                OpenStackSplitFrame(count, returnBtn, "BOTTOMLEFT", "TOPLEFT")
            else
                -- Fallback: divide metade na mão
                local half = math.floor(count / 2)
                if half < 1 then half = 1 end
                SplitContainerItem(bagID, slotID, half)
            end
        end

    elseif action == "DROP" or action == "DELETE" then
        self:Close()
        PickupContainerItem(bagID, slotID)
        if CursorHasItem() then
            DeleteCursorItem()
        end
    end
end
