--[[
    ConsoleMode - Vanilla
    UI/ActionBarPicker.lua - Seletor Visual Integrado de Slots de Action Bar
]]

local CM = ConsoleMode
CM.config = CM.config or {}
CM.config.picker = CM.config.picker or {}
local Picker = CM.config.picker

Picker.frame = nil
Picker.active = false
Picker.targetPage = 1
Picker.targetBtnKey = nil
Picker.targetCombo = nil
Picker.currentBar = 1
Picker.parentFrame = nil

-- Mapeamento fisico: pagina + botao -> tecla real do WoW
local KEY_MAPPINGS = {
    [1] = { A="SPACE",           X="1",           Y="2",           B="3",           DUP="7",           DDOWN="8",           DLEFT="9",           DRIGHT="0" },
    [2] = { A="SHIFT-SPACE",     X="SHIFT-1",     Y="SHIFT-2",     B="SHIFT-3",     DUP="SHIFT-7",     DDOWN="SHIFT-8",     DLEFT="SHIFT-9",     DRIGHT="SHIFT-0" },
    [3] = { A="CTRL-SPACE",      X="CTRL-1",      Y="CTRL-2",      B="CTRL-3",      DUP="CTRL-7",      DDOWN="CTRL-8",      DLEFT="CTRL-9",      DRIGHT="CTRL-0" },
    [4] = { A="ALT-SPACE",       X="ALT-1",       Y="ALT-2",       B="ALT-3",       DUP="ALT-7",       DDOWN="ALT-8",       DLEFT="ALT-9",       DRIGHT="ALT-0" },
    [5] = { A="ALT-SHIFT-SPACE", X="ALT-SHIFT-1", Y="ALT-SHIFT-2", B="ALT-SHIFT-3", DUP="ALT-SHIFT-7", DDOWN="ALT-SHIFT-8", DLEFT="ALT-SHIFT-9", DRIGHT="ALT-SHIFT-0" },
}

-- Definicoes das 5 barras de acao suportadas no WoW 1.12
local BAR_DEFINITIONS = {
    [1] = { name = "1: Principal",      startSlot = 1,  bindingPrefix = "ACTIONBUTTON" },
    [2] = { name = "2: Inferior Esq",   startSlot = 61, bindingPrefix = "MULTIACTIONBAR1BUTTON" },
    [3] = { name = "3: Inferior Dir",   startSlot = 49, bindingPrefix = "MULTIACTIONBAR2BUTTON" },
    [4] = { name = "4: Lateral Dir 1",  startSlot = 25, bindingPrefix = "MULTIACTIONBAR3BUTTON" },
    [5] = { name = "5: Lateral Dir 2",  startSlot = 37, bindingPrefix = "MULTIACTIONBAR4BUTTON" },
}

-- Tooltip Scanner para obter nomes reais de magias / itens
local scanTip = CreateFrame("GameTooltip", "ConsoleModePickerScanTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

function Picker:GetSlotInfo(slot)
    if not slot or slot <= 0 then return nil, "(Vazio)" end
    local tex = nil
    local ok1, r1 = pcall(function() return GetActionTexture(slot) end)
    if ok1 and r1 then tex = r1 end
    
    local name = nil
    local ok2, r2 = pcall(function() return GetActionText(slot) end)
    if ok2 and r2 and r2 ~= "" then
        name = r2
    end
    
    if not name or name == "" then
        local ok3, has = pcall(function() return HasAction(slot) end)
        if ok3 and has then
            scanTip:ClearLines()
            local ok4 = pcall(function() scanTip:SetAction(slot) end)
            if ok4 then
                local tipText = ConsoleModePickerScanTooltipTextLeft1:GetText()
                if tipText and tipText ~= "" then
                    name = tipText
                end
            end
            if not name or name == "" then
                name = "Acao (Slot " .. slot .. ")"
            end
        else
            name = "|cff888888(Vazio)|r"
        end
    end
    
    return tex, name
end

function Picker:CreateUI(parent)
    if self.frame then return end
    
    local f = CreateFrame("Frame", "ConsoleModeActionBarPickerFrame", parent)
    f:SetAllPoints(parent)
    
    -- Cabecalho do Picker
    local titleStr = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleStr:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -12)
    titleStr:SetText("Escolher Slot da Barra de Acao")
    f.titleStr = titleStr
    
    local subStr = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subStr:SetPoint("TOPLEFT", titleStr, "BOTTOMLEFT", 0, -4)
    subStr:SetText("Selecione a barra e o slot que deseja vincular a esta tecla.")
    f.subStr = subStr
    
    -- Botao Voltar / Cancelar
    local backBtn = CreateFrame("Button", "ConsoleModePickerBackBtn", f, "UIPanelButtonTemplate")
    backBtn:SetWidth(80)
    backBtn:SetHeight(24)
    backBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -12)
    backBtn:SetText("Voltar")
    backBtn:SetScript("OnClick", function()
        Picker:Cancel()
    end)
    
    -- Barra de Selecao de Barras (5 abas)
    local barTabsFrame = CreateFrame("Frame", "ConsoleModePickerBarTabs", f)
    barTabsFrame:SetWidth(414)
    barTabsFrame:SetHeight(26)
    barTabsFrame:SetPoint("TOPLEFT", subStr, "BOTTOMLEFT", 0, -8)
    
    self.barButtons = {}
    for b = 1, 5 do
        local barNum = b
        local bBtn = CreateFrame("Button", "ConsoleModePickerBarTab" .. b, barTabsFrame, "UIPanelButtonTemplate")
        bBtn:SetWidth(80)
        bBtn:SetHeight(22)
        bBtn:SetPoint("LEFT", barTabsFrame, "LEFT", (b - 1) * 83, 0)
        bBtn:SetText(BAR_DEFINITIONS[b].name)
        bBtn:SetScript("OnClick", function()
            Picker:SelectBar(barNum)
        end)
        self.barButtons[b] = bBtn
    end
    
    -- Grade de 12 Slots (4 colunas x 3 linhas)
    local gridFrame = CreateFrame("Frame", "ConsoleModePickerGrid", f)
    gridFrame:SetWidth(414)
    gridFrame:SetHeight(280)
    gridFrame:SetPoint("TOPLEFT", barTabsFrame, "BOTTOMLEFT", 0, -8)
    
    self.slotButtons = {}
    for i = 1, 12 do
        local slotIndex = i
        local row = math.floor((i - 1) / 4)
        local col = math.mod(i - 1, 4)
        
        local btn = CreateFrame("Button", "ConsoleModePickerSlotBtn" .. i, gridFrame)
        btn:SetWidth(100)
        btn:SetHeight(80)
        btn:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", col * 104, -(row * 86))
        
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
        
        -- Icone da acao
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(36)
        icon:SetHeight(36)
        icon:SetPoint("TOP", btn, "TOP", 0, -6)
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        btn.icon = icon
        
        -- Numero do Slot (#1..#12)
        local numText = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        numText:SetPoint("TOPLEFT", btn, "TOPLEFT", 6, -4)
        numText:SetText(tostring(i))
        btn.numText = numText
        
        -- Nome da Skill / Acao
        local nameText = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        nameText:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", -28, -2)
        nameText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 4, 4)
        nameText:SetJustifyH("CENTER")
        nameText:SetJustifyV("TOP")
        nameText:SetText("Vazio")
        btn.nameText = nameText
        
        btn:EnableMouse(true)
        btn:SetScript("OnClick", function()
            Picker:ConfirmSlotByIndex(slotIndex)
        end)
        
        btn:SetScript("OnEnter", function()
            this:SetBackdropBorderColor(1, 1, 0, 1)
            local currentBarDef = BAR_DEFINITIONS[Picker.currentBar]
            if currentBarDef then
                local realSlot = currentBarDef.startSlot + slotIndex - 1
                if HasAction(realSlot) then
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetAction(realSlot)
                    GameTooltip:Show()
                end
            end
        end)
        
        btn:SetScript("OnLeave", function()
            this:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
            GameTooltip:Hide()
        end)
        
        self.slotButtons[i] = btn
    end
    
    f:Hide()
    self.frame = f
end

function Picker:SelectBar(barNum)
    self.currentBar = barNum
    local barDef = BAR_DEFINITIONS[barNum]
    if not barDef then return end
    
    -- Atualiza aparencia das abas
    for b = 1, 5 do
        local btn = self.barButtons[b]
        if btn then
            if b == barNum then
                btn:LockHighlight()
            else
                btn:UnlockHighlight()
            end
        end
    end
    
    -- Atualiza os 12 slots da grade com as skills da barra selecionada
    for i = 1, 12 do
        local slotBtn = self.slotButtons[i]
        if slotBtn then
            local realSlot = barDef.startSlot + i - 1
            local tex, name = self:GetSlotInfo(realSlot)
            
            if tex then
                slotBtn.icon:SetTexture(tex)
            else
                slotBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            slotBtn.numText:SetText("#" .. i)
            slotBtn.nameText:SetText(name or "|cff888888(Vazio)|r")
        end
    end
end

function Picker:Show(parent, page, btnKey, comboName)
    self.parentFrame = parent
    self:CreateUI(parent)
    
    self.active = true
    self.targetPage = page or 1
    self.targetBtnKey = btnKey
    self.targetCombo = comboName or "?"
    
    self.frame.titleStr:SetText("Mapear: |cffffcc00" .. self.targetCombo .. "|r")
    self:SelectBar(self.currentBar or 1)
    
    self.frame:Show()
    
    -- Registra no cursor do ConsoleMode para permitir navegacao por D-Pad
    local Cursor = CM.cursor
    if Cursor and Cursor.state and Cursor.state.enabled then
        Cursor.state.activeFrames[self.frame] = true
        local firstSlot = self.slotButtons[1]
        if firstSlot then
            Cursor:MoveTo(firstSlot)
        end
    end
end

function Picker:ConfirmSlotByIndex(slotIndex)
    if not self.active then return end
    
    local barDef = BAR_DEFINITIONS[self.currentBar]
    if not barDef then return end
    
    local realSlot = barDef.startSlot + slotIndex - 1
    local bindingAction = barDef.bindingPrefix .. slotIndex
    local physKey = KEY_MAPPINGS[self.targetPage] and KEY_MAPPINGS[self.targetPage][self.targetBtnKey]
    
    if physKey and bindingAction then
        -- 1. Aplica o binding no WoW
        SetBinding(physKey, bindingAction)
        
        -- 2. Atualiza o snapshot de navegacao para nao sobrescrever ao fechar a janela
        local KB = CM.keybindings
        if KB and KB.savedNavBindings then
            KB.savedNavBindings[physKey] = bindingAction
        end
        
        -- 3. Persiste no arquivo de bindings do WoW de forma segura
        local set = GetCurrentBindingSet()
        if not set or set == 0 then set = 1 end
        pcall(function() SaveBindings(set) end)
        
        local _, actionName = self:GetSlotInfo(realSlot)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r |cffffcc00" .. self.targetCombo .. "|r vinculado a |cff88ccff" .. (actionName or ("Slot " .. slotIndex)) .. "|r (" .. barDef.name .. ")!")
        PlaySound("igMainMenuOptionCheckBoxOn")
        
        -- Atualiza imediatamente os icones do ActionHUD
        if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.Update then
            CM.ui.actionHUD:Update()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro ao vincular tecla!")
    end
    
    self:Cancel()
end

function Picker:Cancel()
    self.active = false
    if self.frame then
        self.frame:Hide()
    end
    
    -- Retorna para a lista de Keybindings
    local kbList = CM.config and CM.config.keybindingsList
    if kbList and self.parentFrame then
        kbList:Show(self.parentFrame)
        kbList:SelectPage(self.targetPage or 1)
    end
end
