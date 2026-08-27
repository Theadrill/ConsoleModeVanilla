--[[
    ConsoleMode - Vanilla
    UI/ConfigFrame.lua - Painel Principal de Configurações
]]

local CM = ConsoleMode
CM.config = CM.config or {}
local Config = CM.config

Config.frame = nil
Config.currentTab = "KEYBINDINGS"

function Config:Initialize()
    if self.frame then return end
    
    -- Criação da janela principal
    local f = CreateFrame("Frame", "ConsoleModeSettingsFrame", UIParent)
    f:SetWidth(640)
    f:SetHeight(480)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- Backdrop estilo clássico Blizzard
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    
    -- Header / Título no topo
    local headerTexture = f:CreateTexture(nil, "ARTWORK")
    headerTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    headerTexture:SetWidth(300)
    headerTexture:SetHeight(64)
    headerTexture:SetPoint("TOP", f, "TOP", 0, 12)
    
    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", headerTexture, "TOP", 0, -14)
    title:SetText("ConsoleMode - Settings")
    
    -- Botão de Fechar no canto superior direito
    local closeBtn = CreateFrame("Button", "ConsoleModeSettingsCloseButton", f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function()
        Config:Hide()
    end)
    
    -- Painel Lateral Esquerdo (Abas / Categorias)
    local leftNav = CreateFrame("Frame", "ConsoleModeSettingsNav", f)
    leftNav:SetWidth(150)
    leftNav:SetHeight(400)
    leftNav:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -40)
    leftNav:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    leftNav:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    leftNav:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    -- Botão de Categoria: Keybindings
    local tabKeybindings = CreateFrame("Button", "ConsoleModeTabKeybindings", leftNav, "UIPanelButtonTemplate")
    tabKeybindings:SetWidth(134)
    tabKeybindings:SetHeight(32)
    tabKeybindings:SetPoint("TOP", leftNav, "TOP", 0, -8)
    tabKeybindings:SetText("Atalhos / Binds")
    tabKeybindings:SetScript("OnClick", function()
        Config:SelectTab("KEYBINDINGS")
    end)
    
    -- Painel Central Direito (Conteúdo da Categoria)
    local contentFrame = CreateFrame("Frame", "ConsoleModeSettingsContent", f)
    contentFrame:SetWidth(446)
    contentFrame:SetHeight(400)
    contentFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -40)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    contentFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    contentFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    -- Rodapé informativo com prompts de controle
    local footerText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footerText:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
    footerText:SetText("|cff00ff00[A]|r Selecionar / Mapear   |   |cffff4444[B]|r Voltar / Fechar")
    
    f:Hide()
    self.frame = f
    self.contentFrame = contentFrame
    
    -- Registra suporte ao UIPanel do WoW
    tinsert(UISpecialFrames, "ConsoleModeSettingsFrame")
end

function Config:SelectTab(tabName)
    self.currentTab = tabName
    if tabName == "KEYBINDINGS" and self.keybindingsList and self.keybindingsList.Show then
        self.keybindingsList:Show(self.contentFrame)
    end
end

function Config:Show()
    if not self.frame then self:Initialize() end
    self.frame:Show()
    self:SelectTab(self.currentTab or "KEYBINDINGS")
end

function Config:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Config:Toggle()
    if not self.frame or not self.frame:IsVisible() then
        self:Show()
    else
        self:Hide()
    end
end
