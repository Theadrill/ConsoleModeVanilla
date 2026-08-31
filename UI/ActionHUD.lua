--[[
    ConsoleMode - Vanilla
    UI/ActionHUD.lua - HUD Visual de Barras de Acao estilo Console
    
    Recursos:
    - 2 Clusters em formato Diamond (D-Pad a esquerda, ABXY a direita)
    - Icones de acao elegantes com zoom/crop e cantos escuros
    - Prompts de botoes de controle ancorados nas pontas (A, B, X, Y, D-Pad)
    - Suporte a Cooldown Frame oficial do WoW Vanilla 1.12
    - Troca dinamica de pagina ao segurar modificadores (L2, R1, R2, L2+R2)
    - Posicionamento global (Shift+Left arrasta, Shift+Right reseta)
]]

local CM = ConsoleMode
CM.ui = CM.ui or {}
CM.ui.actionHUD = CM.ui.actionHUD or {}
local HUD = CM.ui.actionHUD

HUD.frame = nil
HUD.currentPage = 1
HUD.buttons = {}

-- Mesma tabela de teclas que o Keybindings.lua usa como fonte da verdade
local KEY_MAPPINGS = {
    [1] = { A="SPACE",           X="1",           Y="2",           B="3",           DUP="7",           DDOWN="8",           DLEFT="9",           DRIGHT="0" },
    [2] = { A="SHIFT-SPACE",     X="SHIFT-1",     Y="SHIFT-2",     B="SHIFT-3",     DUP="SHIFT-7",     DDOWN="SHIFT-8",     DLEFT="SHIFT-9",     DRIGHT="SHIFT-0" },
    [3] = { A="CTRL-SPACE",      X="CTRL-1",      Y="CTRL-2",      B="CTRL-3",      DUP="CTRL-7",      DDOWN="CTRL-8",      DLEFT="CTRL-9",      DRIGHT="CTRL-0" },
    [4] = { A="ALT-SPACE",       X="ALT-1",       Y="ALT-2",       B="ALT-3",       DUP="ALT-7",       DDOWN="ALT-8",       DLEFT="ALT-9",       DRIGHT="ALT-0" },
    [5] = { A="ALT-SHIFT-SPACE", X="ALT-SHIFT-1", Y="ALT-SHIFT-2", B="ALT-SHIFT-3", DUP="ALT-SHIFT-7", DDOWN="ALT-SHIFT-8", DLEFT="ALT-SHIFT-9", DRIGHT="ALT-SHIFT-0" },
}

-- Definicao dos botoes nos clusters (posicao e prompt)
local BUTTON_LAYOUT = {
    -- Cluster Esquerdo: D-Pad
    { key = "DUP",    cluster = "left",  relX = 0,   relY = 22,  promptAlign = "TOP",    promptX = 0,  promptY = 0,  icon = "DUP.tga" },
    { key = "DDOWN",  cluster = "left",  relX = 0,   relY = -22, promptAlign = "BOTTOM", promptX = 0,  promptY = 0, icon = "DDOWN.tga" },
    { key = "DLEFT",  cluster = "left",  relX = -44, relY = 0,   promptAlign = "LEFT",   promptX = 0, promptY = 0,  icon = "DLEFT.tga" },
    { key = "DRIGHT", cluster = "left",  relX = 44,  relY = 0,   promptAlign = "RIGHT",  promptX = 0,  promptY = 0,  icon = "DRIGHT.tga" },

    -- Cluster Direito: Botoes Faciais (Y = Cima, A = Baixo, X = Esquerda, B = Direita)
    { key = "Y",      cluster = "right", relX = 0,   relY = 22  ,  promptAlign = "TOP",    promptX = 0,  promptY = 0,  icon = "Y.tga" },
    { key = "A",      cluster = "right", relX = 0,   relY = -22, promptAlign = "BOTTOM", promptX = 0,  promptY = 0, icon = "A.tga" },
    { key = "X",      cluster = "right", relX = -44, relY = 0,   promptAlign = "LEFT",   promptX = 0, promptY = 0,  icon = "X.tga" },
    { key = "B",      cluster = "right", relX = 44,  relY = 0,   promptAlign = "RIGHT",  promptX = 0,  promptY = 0,  icon = "B.tga" },
}

function HUD:GetSlotForButton(page, btnKey)
    if page == 1 and btnKey == "A" then
        return nil, "Interface\\Icons\\Ability_Rogue_Sprint", "JUMP"
    end

    local physKey = KEY_MAPPINGS[page] and KEY_MAPPINGS[page][btnKey]
    if not physKey then return nil, nil, nil end

    local boundAction = GetBindingAction(physKey)
    if boundAction and string.find(boundAction, "^CM_") then
        local KB = CM.keybindings
        if KB and KB.savedNavBindings and KB.savedNavBindings[physKey] then
            boundAction = KB.savedNavBindings[physKey]
        end
    end

    if not boundAction or boundAction == "" then return nil, nil, nil end

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
        local ok, res = pcall(function() return GetActionTexture(slot) end)
        if ok and res then tex = res end
        return slot, tex, boundAction
    end

    return nil, nil, boundAction
end

function HUD:CreateButton(parent, def, id)
    local btn = CreateFrame("Button", "ConsoleModeActionButton" .. id, parent)
    btn:SetWidth(42)
    btn:SetHeight(42)
    btn:SetPoint("CENTER", parent, "CENTER", def.relX, def.relY)
    
    -- Backdrop escuro com borda fina
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    btn:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
    
    -- Textura do Icone de Habilidade
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Zoom/Crop moderno
    btn.icon = icon
    
    -- Cooldown Frame Oficial do WoW
    local cd = CreateFrame("Model", "ConsoleModeActionCD" .. id, btn, "CooldownFrameTemplate")
    cd:SetAllPoints(btn)
    cd:SetFrameLevel(btn:GetFrameLevel() + 1)
    btn.cooldown = cd
    
    -- Badge com o icone do botao de controle (A, B, X, Y, D-Pad)
    local prompt = btn:CreateTexture(nil, "OVERLAY")
    local isFront = (def.key == "A" or def.key == "B" or def.key == "X" or def.key == "Y")
    local pSize = isFront and 25 or 20
    prompt:SetWidth(pSize)
    prompt:SetHeight(pSize)
    prompt:SetPoint("CENTER", btn, def.promptAlign, def.promptX, def.promptY)
    prompt:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\" .. def.icon)
    btn.prompt = prompt
    
    -- Texto de Contagem/Stacks (ex: pocoes)
    local count = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
    count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4, 4)
    count:SetText("")
    btn.count = count
    
    btn.def = def
    btn.btnKey = def.key
    
    return btn
end

function HUD:Initialize()
    if self.frame then return end
    
    -- Container Principal (engloba os dois clusters)
    local f = CreateFrame("Frame", "ConsoleModeActionHUDFrame", UIParent)
    f:SetWidth(440)
    f:SetHeight(120)
    
    if CM.ui and CM.ui.MakeMovable then
        CM.ui:MakeMovable(f, "ActionHUD", "BOTTOM", "BOTTOM", 0, 45, "Barra de Acoes Console")
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 45)
    end
    
    f:SetFrameStrata("LOW")
    
    -- Cluster Esquerdo (D-Pad)
    local leftCluster = CreateFrame("Frame", "ConsoleModeHUDClusterLeft", f)
    leftCluster:SetWidth(110)
    leftCluster:SetHeight(110)
    leftCluster:SetPoint("LEFT", f, "LEFT", 10, 0)
    f.leftCluster = leftCluster
    
    -- Cluster Direito (Botoes ABXY)
    local rightCluster = CreateFrame("Frame", "ConsoleModeHUDClusterRight", f)
    rightCluster:SetWidth(110)
    rightCluster:SetHeight(110)
    rightCluster:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.rightCluster = rightCluster
    
    -- Criacao dos 8 Botoes
    self.buttons = {}
    for i, def in ipairs(BUTTON_LAYOUT) do
        local parent = (def.cluster == "left") and leftCluster or rightCluster
        self.buttons[i] = self:CreateButton(parent, def, i)
    end
    
    -- Polling de Modificadores para troca instantanea de pagina
    local lastPage = 1
    f:SetScript("OnUpdate", function()
        local page = 1
        if IsAltKeyDown() and IsShiftKeyDown() then
            page = 5 -- L2+R2
        elseif IsAltKeyDown() then
            page = 4 -- R2
        elseif IsControlKeyDown() then
            page = 3 -- R1
        elseif IsShiftKeyDown() then
            page = 2 -- L2
        else
            page = 1 -- Base
        end
        
        if page ~= lastPage then
            lastPage = page
            HUD.currentPage = page
            HUD:Update()
        end
    end)
    
    -- Eventos de Atualizacao do WoW
    f:RegisterEvent("UPDATE_BINDINGS")
    f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    f:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    f:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    f:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    f:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    f:RegisterEvent("ACTIONBAR_SHOWGRID")
    f:RegisterEvent("ACTIONBAR_HIDEGRID")
    f:RegisterEvent("SPELLS_CHANGED")
    f:RegisterEvent("LEARNED_SPELL_IN_TAB")
    f:RegisterEvent("BAG_UPDATE")
    f:RegisterEvent("BAG_UPDATE_COOLDOWN")
    f:RegisterEvent("PLAYER_AURAS_CHANGED")
    self.frame = f
    self:HideDefaultBars()
    self:Update()
    f:Show()
end

function HUD:HideDefaultBars()
    -- 1. Oculta a barra de acoes principal da Blizzard (Vanilla 1.12)
    if MainMenuBar then
        MainMenuBar:Hide()
        MainMenuBar:SetAlpha(0)
        MainMenuBar:EnableMouse(false)
        MainMenuBar.Show = function() end
    end
    
    if MainMenuBarArtFrame then
        MainMenuBarArtFrame:Hide()
        MainMenuBarArtFrame:SetAlpha(0)
        MainMenuBarArtFrame.Show = function() end
    end
    
    if MainMenuBarLeftEndCap then MainMenuBarLeftEndCap:Hide() end
    if MainMenuBarRightEndCap then MainMenuBarRightEndCap:Hide() end
    if MainMenuBarPageNumber then MainMenuBarPageNumber:Hide() end
    if ActionBarUpButton then ActionBarUpButton:Hide() end
    if ActionBarDownButton then ActionBarDownButton:Hide() end
    if MainMenuBarPerformanceBarFrame then MainMenuBarPerformanceBarFrame:Hide() end

    for i = 0, 3 do
        local tex = getglobal("MainMenuBarTexture" .. i)
        if tex then tex:Hide() end
    end

    -- 2. Oculta as MultiBars extras
    local multiBars = {
        "MultiBarBottomLeft",
        "MultiBarBottomRight",
        "MultiBarRight",
        "MultiBarLeft",
        "BonusActionBarFrame",
    }
    for _, barName in ipairs(multiBars) do
        local bar = getglobal(barName)
        if bar then
            bar:Hide()
            bar:SetAlpha(0)
            bar:EnableMouse(false)
            bar.Show = function() end
        end
    end
end

function HUD:Update()
    if not self.frame then return end
    
    local page = self.currentPage or 1
    
    for _, btn in ipairs(self.buttons) do
        local slot, tex, actionName = self:GetSlotForButton(page, btn.btnKey)
        
        if tex then
            btn.icon:SetTexture(tex)
            btn.icon:Show()
            btn.icon:SetVertexColor(1.0, 1.0, 1.0)
            
            -- Cooldown
            if slot and slot > 0 then
                local start, duration, enable = GetActionCooldown(slot)
                if btn.cooldown and start and duration then
                    CooldownFrame_SetTimer(btn.cooldown, start, duration, enable)
                end
                
                -- Usabilidade / Mana
                local isUsable, notEnoughMana = IsUsableAction(slot)
                if notEnoughMana then
                    btn.icon:SetVertexColor(0.5, 0.5, 1.0) -- Azul (sem mana)
                elseif not isUsable then
                    btn.icon:SetVertexColor(0.4, 0.4, 0.4) -- Escuro (inutilizavel)
                end
                
                -- Contagem / Stacks
                local count = GetActionCount(slot)
                if count and count > 1 then
                    btn.count:SetText(tostring(count))
                else
                    btn.count:SetText("")
                end
            else
                if btn.cooldown then btn.cooldown:Hide() end
                btn.count:SetText("")
            end
        else
            btn.icon:Hide()
            if btn.cooldown then btn.cooldown:Hide() end
            btn.count:SetText("")
        end
    end
end
