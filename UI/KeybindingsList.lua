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

function KBList:GetActionSlotForButton(page, btnKey)
    local pageOffsets = {
        [1] = 0,
        [2] = 12,
        [3] = 24,
        [4] = 36,
        [5] = 48,
    }
    local btnOffsets = {
        A      = 0,
        X      = 1,
        Y      = 2,
        B      = 3,
        DUP    = 7,
        DDOWN  = 8,
        DLEFT  = 9,
        DRIGHT = 10,
    }
    
    if page == 1 and btnKey == "A" then
        return nil, "Pulo / Jump"
    end
    
    local offset = btnOffsets[btnKey] or 1
    local pOffset = pageOffsets[page] or 0
    local slot = pOffset + offset
    if slot <= 0 then slot = 1 end
    
    return slot, "Action Slot " .. slot
end

function KBList:GetActionInfoForSlot(slot)
    if not slot or slot <= 0 then 
        return "Interface\\Icons\\INV_Misc_QuestionMark", "Nenhum atalho", nil 
    end
    
    local texture = nil
    local ok, res = pcall(function() return GetActionTexture(slot) end)
    if ok and res then
        texture = res
    end
    
    local text = nil
    local ok2, res2 = pcall(function() return GetActionText(slot) end)
    if ok2 and res2 then
        text = res2
    end
    
    if not text or text == "" then
        local hasAct = false
        local ok3, res3 = pcall(function() return HasAction(slot) end)
        if ok3 and res3 then
            text = "Acao (Slot " .. slot .. ")"
        else
            text = "|cff888888(Vazio - Slot " .. slot .. ")|r"
        end
    end
    
    return texture or "Interface\\Icons\\INV_Misc_QuestionMark", text, slot
end

function KBList:Show(parent)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[LOG 3]|r KBList:Show chamado. Parent: " .. tostring(parent and parent:GetName()))
    if not self.frame then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[LOG 3.1]|r Criando ConsoleModeKeybindingsListFrame...")
        local f = CreateFrame("Frame", "ConsoleModeKeybindingsListFrame", parent)
        f:SetAllPoints(parent)
        
        -- Titulo da Secao
        local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -12)
        title:SetText("Mapeamento de Combinacoes")
        
        local desc = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        desc:SetText("Escolha a pagina e selecione um botao para vincular:")
        
        -- Barra de Navegacao de Paginas (1 a 5)
        local pageBar = CreateFrame("Frame", "ConsoleModePageBar", f)
        pageBar:SetWidth(414)
        pageBar:SetHeight(28)
        pageBar:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
        
        for p = 1, 5 do
            local pageNum = p  -- captura o valor atual, evita o closure bug do Lua 5.0
            local pBtn = CreateFrame("Button", "ConsoleModePageBtn" .. p, pageBar, "UIPanelButtonTemplate")
            pBtn:SetWidth(78)
            pBtn:SetHeight(24)
            pBtn:SetPoint("LEFT", pageBar, "LEFT", (p - 1) * 84, 0)
            
            local shortName = p == 1 and "1: Base" or (p == 2 and "2: L2" or (p == 3 and "3: R1" or (p == 4 and "4: R2" or "5: L2+R2")))
            pBtn:SetText(shortName)
            
            pBtn:SetScript("OnClick", function()
                DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[LOG PageBtn]|r Aba clicada: " .. tostring(pageNum))
                KBList:SelectPage(pageNum)
            end)
            self.pageButtons[p] = pBtn
        end
        
        -- Grid de 8 Botoes de Acao
        local gridFrame = CreateFrame("Frame", "ConsoleModeKeyGrid", f)
        gridFrame:SetWidth(414)
        gridFrame:SetHeight(300)
        gridFrame:SetPoint("TOPLEFT", pageBar, "BOTTOMLEFT", 0, -8)
        
        for i, btnKey in ipairs(BUTTON_ORDER) do
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
            
            -- Highlight ao passar o mouse / cursor
            local hl = rowBtn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            hl:SetBlendMode("ADD")
            hl:SetAllPoints(rowBtn)
            
            -- Icone da Acao
            local actIcon = rowBtn:CreateTexture(nil, "ARTWORK")
            actIcon:SetWidth(40)
            actIcon:SetHeight(40)
            actIcon:SetPoint("LEFT", rowBtn, "LEFT", 10, 0)
            actIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            
            -- Texto da Combinacao
            local comboText = rowBtn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            comboText:SetPoint("TOPLEFT", actIcon, "TOPRIGHT", 8, -2)
            comboText:SetText(btnKey)
            
            -- Nome da Habilidade / Acao
            local actionText = rowBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            actionText:SetPoint("BOTTOMLEFT", actIcon, "BOTTOMRIGHT", 8, 4)
            actionText:SetWidth(136)
            actionText:SetJustifyH("LEFT")
            actionText:SetText("Carregando...")
            
            rowBtn.btnKey = btnKey
            rowBtn.actIcon = actIcon
            rowBtn.comboText = comboText
            rowBtn.actionText = actionText
            
            rowBtn:EnableMouse(true)
            rowBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            
            rowBtn:SetScript("OnClick", function()
                KBList:OnKeySelected(this.btnKey)
            end)
            
            self.buttons[i] = rowBtn
        end
        
        pageBar:Show()
        gridFrame:Show()
        self.frame = f
    end
    
    self:SelectPage(self.currentPage or 1)
    self.frame:Show()
end

function KBList:SelectPage(pageNum)
    self.currentPage = pageNum
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[LOG 4]|r KBList:SelectPage selecionando pagina: " .. tostring(pageNum))
    
    -- Atualiza estado visual das abas de pagina
    for p, btn in ipairs(self.pageButtons) do
        if p == pageNum then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
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
            
            local slot, defaultDesc = self:GetActionSlotForButton(pageNum, btnKey)
            if slot then
                local texture, actName = self:GetActionInfoForSlot(slot)
                rowBtn.actIcon:SetTexture(texture)
                rowBtn.actionText:SetText(actName)
            else
                rowBtn.actIcon:SetTexture("Interface\\Icons\\Ability_Rogue_Sprint")
                rowBtn.actionText:SetText("|cff00ff00" .. (defaultDesc or "Pulo") .. "|r")
            end
        end
    end
end

function KBList:OnKeySelected(btnKey)
    local prefix = PAGE_PREFIXES[self.currentPage] or ""
    local info = BUTTON_INFO[btnKey]
    local comboName = prefix .. (info and info.label or btnKey)
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Selecionado para mapear: |cffffcc00" .. comboName .. "|r")
end

function KBList:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
