--[[
    ConsoleMode - Vanilla
    UI/KeybindingsList.lua - Lista de Mapeamentos e Paginas de Acao
]]

local CM = ConsoleMode
CM.config = CM.config or {}
CM.config.keybindingsList = CM.config.keybindingsList or {}
local KBList = CM.config.keybindingsList

KBList.frame = nil
KBList.currentPage = 1
KBList.buttons = {}
KBList.pageButtons = {}
KBList.parent = nil

local BUTTON_ORDER = { "A", "B", "X", "Y", "DUP", "DDOWN", "DLEFT", "DRIGHT" }

local BUTTON_INFO = {
    A      = { label = "A",              fallback = "[A]" },
    B      = { label = "B",              fallback = "[B]" },
    X      = { label = "X",              fallback = "[X]" },
    Y      = { label = "Y",              fallback = "[Y]" },
    DUP    = { label = "D-Pad Cima",     fallback = "[^]" },
    DDOWN  = { label = "D-Pad Baixo",    fallback = "[v]" },
    DLEFT  = { label = "D-Pad Esquerda", fallback = "[<]" },
    DRIGHT = { label = "D-Pad Direita",  fallback = "[>]" },
}

local PAGE_NAMES = {
    [1] = "Pagina 1 (Base)",
    [2] = "Pagina 2 (L2 / Shift)",
    [3] = "Pagina 3 (R1 / Ctrl)",
    [4] = "Pagina 4 (R2 / Alt)",
    [5] = "Pagina 5 (L2+R2)",
}

local PAGE_PREFIXES = {
    [1] = "",
    [2] = "L2 + ",
    [3] = "R1 + ",
    [4] = "R2 + ",
    [5] = "L2+R2 + ",
}

-- Mesma tabela de teclas que o Keybindings.lua usa como fonte da verdade
local KEY_DEFAULTS = {
    [1] = { A="SPACE",           X="1",           Y="2",           B="3",           DUP="7",           DDOWN="8",           DLEFT="9",           DRIGHT="0" },
    [2] = { A="SHIFT-SPACE",     X="SHIFT-1",     Y="SHIFT-2",     B="SHIFT-3",     DUP="SHIFT-7",     DDOWN="SHIFT-8",     DLEFT="SHIFT-9",     DRIGHT="SHIFT-0" },
    [3] = { A="CTRL-SPACE",      X="CTRL-1",      Y="CTRL-2",      B="CTRL-3",      DUP="CTRL-7",      DDOWN="CTRL-8",      DLEFT="CTRL-9",      DRIGHT="CTRL-0" },
    [4] = { A="ALT-SPACE",       X="ALT-1",       Y="ALT-2",       B="ALT-3",       DUP="ALT-7",       DDOWN="ALT-8",       DLEFT="ALT-9",       DRIGHT="ALT-0" },
    [5] = { A="ALT-SHIFT-SPACE", X="ALT-SHIFT-1", Y="ALT-SHIFT-2", B="ALT-SHIFT-3", DUP="ALT-SHIFT-7", DDOWN="ALT-SHIFT-8", DLEFT="ALT-SHIFT-9", DRIGHT="ALT-SHIFT-0" },
}

-- Tooltip Scanner para pegar o nome real das skills
local scanTip = CreateFrame("GameTooltip", "ConsoleModeKBListScanTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

function KBList:GetDisplayForButton(page, btnKey)
    -- Caso especial: A na pagina 1 e' sempre Pulo
    if page == 1 and btnKey == "A" then
        return nil, "Pulo / Jump", "Interface\\Icons\\Ability_Rogue_Sprint"
    end

    local physKey = KEY_DEFAULTS[page] and KEY_DEFAULTS[page][btnKey]
    if not physKey then
        return nil, "|cff888888(sem tecla)|r", nil
    end

    -- Pega qual acao esta vinculada a esta tecla fisica
    local boundAction = GetBindingAction(physKey)

    -- Se o modo de navegacao estiver ativo, as teclas da pagina 1 foram sobrescritas
    -- com CM_CURSOR_*. Usamos o snapshot KB.savedNavBindings guardado antes do nav mode.
    if boundAction and string.find(boundAction, "^CM_") then
        local KB = CM.keybindings
        if KB and KB.savedNavBindings and KB.savedNavBindings[physKey] then
            boundAction = KB.savedNavBindings[physKey]
        end
    end

    if not boundAction or boundAction == "" then
        return nil, "|cff888888(vazio)|r", nil
    end

    -- Resolve slot de action bar (string.find com captures = Lua 5.0 safe)
    local slot = nil
    local _, _, n

    _, _, n = string.find(boundAction, "^ACTIONBUTTON(%d+)$")
    if n then slot = tonumber(n) end

    if not slot then
        _, _, n = string.find(boundAction, "^MULTIACTIONBAR1BUTTON(%d+)$")
        if n then slot = tonumber(n) + 60 end
    end
    if not slot then
        _, _, n = string.find(boundAction, "^MULTIACTIONBAR2BUTTON(%d+)$")
        if n then slot = tonumber(n) + 48 end
    end
    if not slot then
        _, _, n = string.find(boundAction, "^MULTIACTIONBAR3BUTTON(%d+)$")
        if n then slot = tonumber(n) + 24 end
    end
    if not slot then
        _, _, n = string.find(boundAction, "^MULTIACTIONBAR4BUTTON(%d+)$")
        if n then slot = tonumber(n) + 36 end
    end

    if slot then
        local tex = nil
        local ok1, r1 = pcall(function() return GetActionTexture(slot) end)
        if ok1 and r1 then tex = r1 end
        
        local name = nil
        local ok2, r2 = pcall(function() return GetActionText(slot) end)
        if ok2 and r2 and r2 ~= "" then name = r2 end
        
        -- Se nao tem texto (ex: e' magia/feitiço), escaneia o tooltip real do WoW
        if not name or name == "" then
            local ok3, has = pcall(function() return HasAction(slot) end)
            if ok3 and has then
                scanTip:ClearLines()
                local ok4 = pcall(function() scanTip:SetAction(slot) end)
                if ok4 then
                    local tipText = ConsoleModeKBListScanTooltipTextLeft1:GetText()
                    if tipText and tipText ~= "" then
                        name = tipText
                    end
                end
                if not name or name == "" then
                    name = "Acao (Slot " .. slot .. ")"
                end
            else
                name = "|cff888888(Vazio - Slot " .. slot .. ")|r"
            end
        end
        return slot, name, tex
    end

    -- Nao e' action bar - mostra o nome do binding direto (ex: TARGETNEARESTENEMY, JUMP)
    return nil, boundAction, nil
end

function KBList:Show(parent)
    if parent then self.parent = parent end
    local p = self.parent
    if not p then return end

    -- Esconde o picker se estiver aberto no mesmo painel
    local picker = CM.config and CM.config.picker
    if picker and picker.frame then
        picker.frame:Hide()
        picker.active = false
    end
    
    if not self.frame then
        local f = CreateFrame("Frame", "ConsoleModeKeybindingsListFrame", p)
        f:SetAllPoints(p)
        
        -- Titulo da Secao
        local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -12)
        title:SetText("Mapeamento de Combinacoes")
        
        local desc = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        desc:SetText("Escolha a pagina e selecione um botao para vincular:")
        
        -- Barra de Abas das 5 Paginas (Base, L2, R1, R2, L2+R2)
        local pageBar = CreateFrame("Frame", "ConsoleModePageTabs", f)
        pageBar:SetWidth(414)
        pageBar:SetHeight(28)
        pageBar:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
        
        for idx = 1, 5 do
            local pageNum = idx
            local pBtn = CreateFrame("Button", "ConsoleModePageBtn" .. idx, pageBar, "UIPanelButtonTemplate")
            pBtn:SetWidth(78)
            pBtn:SetHeight(24)
            pBtn:SetPoint("LEFT", pageBar, "LEFT", (idx - 1) * 84, 0)
            
            local shortName = idx == 1 and "1: Base" or (idx == 2 and "2: L2" or (idx == 3 and "3: R1" or (idx == 4 and "4: R2" or "5: L2+R2")))
            pBtn:SetText(shortName)
            
            pBtn:SetScript("OnClick", function()
                KBList:SelectPage(pageNum)
            end)
            self.pageButtons[idx] = pBtn
        end
        
        -- Grid de 8 Botoes de Acao (2 colunas x 4 linhas)
        local gridFrame = CreateFrame("Frame", "ConsoleModeKeyGrid", f)
        gridFrame:SetWidth(414)
        gridFrame:SetHeight(300)
        gridFrame:SetPoint("TOPLEFT", pageBar, "BOTTOMLEFT", 0, -8)
        
        for i, btnKey in ipairs(BUTTON_ORDER) do
            local curBtnKey = btnKey
            local row = math.floor((i - 1) / 2)
            local col = math.mod(i - 1, 2)
            
            local rowBtn = CreateFrame("Button", "ConsoleModeKeyRow" .. i, gridFrame)
            rowBtn:SetWidth(202)
            rowBtn:SetHeight(64)
            rowBtn:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", col * 210, -(row * 70))
            
            rowBtn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            rowBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
            rowBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
            
            -- Icone da acao (36x36)
            local actIcon = rowBtn:CreateTexture(nil, "ARTWORK")
            actIcon:SetWidth(36)
            actIcon:SetHeight(36)
            actIcon:SetPoint("LEFT", rowBtn, "LEFT", 8, 0)
            actIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            
            -- Texto da combinacao de controle (ex: "L2 + X")
            local comboText = rowBtn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            comboText:SetPoint("TOPLEFT", actIcon, "TOPRIGHT", 8, 0)
            comboText:SetText(BUTTON_INFO[btnKey] and BUTTON_INFO[btnKey].label or btnKey)
            
            -- Nome da acao vinculada (ex: "Fireball", "Pulo")
            local actionText = rowBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            actionText:SetPoint("BOTTOMLEFT", actIcon, "BOTTOMRIGHT", 8, 2)
            actionText:SetPoint("RIGHT", rowBtn, "RIGHT", -8, 0)
            actionText:SetJustifyH("LEFT")
            actionText:SetText("Carregando...")
            
            rowBtn.btnKey = curBtnKey
            rowBtn.actIcon = actIcon
            rowBtn.comboText = comboText
            rowBtn.actionText = actionText
            
            rowBtn:EnableMouse(true)
            rowBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            
            rowBtn:SetScript("OnClick", function()
                KBList:OnKeySelected(curBtnKey)
            end)
            
            rowBtn:SetScript("OnEnter", function()
                this:SetBackdropBorderColor(1, 1, 0, 1)
            end)
            
            rowBtn:SetScript("OnLeave", function()
                this:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
            end)
            
            self.buttons[i] = rowBtn
        end
        
        pageBar:Show()
        gridFrame:Show()
        self.frame = f
    end
    
    self:SelectPage(self.currentPage or 1)
    self.frame:Show()
    
    -- Registra no cursor do ConsoleMode para navegacao por D-Pad
    local Cursor = CM.cursor
    if Cursor and Cursor.state and Cursor.state.enabled then
        Cursor.state.activeFrames[self.frame] = true
    end
end

function KBList:SelectPage(pageNum)
    self.currentPage = pageNum
    
    -- Destaca a aba ativa
    for p = 1, 5 do
        local pBtn = self.pageButtons[p]
        if pBtn then
            if p == pageNum then
                pBtn:LockHighlight()
            else
                pBtn:UnlockHighlight()
            end
        end
    end
    
    -- Atualiza os 8 botoes com as acoes reais da pagina
    for i, btnKey in ipairs(BUTTON_ORDER) do
        local rowBtn = self.buttons[i]
        if rowBtn then
            local prefix = PAGE_PREFIXES[pageNum] or ""
            local info = BUTTON_INFO[btnKey]
            local comboName = prefix .. (info and info.label or btnKey)
            
            rowBtn.comboText:SetText("|cffffcc00" .. comboName .. "|r")
            
            local slot, displayName, texture = self:GetDisplayForButton(pageNum, btnKey)
            rowBtn.actIcon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            rowBtn.actionText:SetText(displayName or "|cff888888(vazio)|r")
        end
    end
end

function KBList:OnKeySelected(btnKey)
    local prefix = PAGE_PREFIXES[self.currentPage] or ""
    local info = BUTTON_INFO[btnKey]
    local comboName = prefix .. (info and info.label or btnKey)
    
    -- Esconde a lista de binds e abre o Seletor de Action Bar diretamente no painel!
    if self.frame then
        self.frame:Hide()
    end
    
    local picker = CM.config and CM.config.picker
    if picker and picker.Show and self.parent then
        picker:Show(self.parent, self.currentPage, btnKey, comboName)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro ao abrir seletor de barras!")
    end
end

function KBList:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
