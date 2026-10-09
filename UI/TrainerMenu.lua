-- ============================================================================
-- ConsoleModeVanilla - UI/TrainerMenu.lua
-- Sistema Modular de Treinamento de Classe e Profissões para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE 2: Esqueleto Visual Responsivo Split-View com Moldura 9-Slice Esculpida
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_TrainerMenu = ConsoleMode_TrainerMenu or {}
local TrainerMenu = ConsoleMode_TrainerMenu
CM.trainerMenu = TrainerMenu

-- ----------------------------------------------------------------------------
-- 1. CONSTANTES VISUAIS, DESIGN SYSTEM & RECURSOS
-- ----------------------------------------------------------------------------
local FONTS = {
    titleBold = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    bodyBold  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    medium    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Medium.ttf",
    fallback  = "Fonts\\FRIZQT__.TTF",
}

local ICONS = {
    A      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\A.tga",
    B      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\B.tga",
    X      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\X.tga",
    Y      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\Y.tga",
    LB     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LB.tga",
    RB     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\RB.tga",
    LT     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LT.tga",
    RT     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\RT.tga",
    LS     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LS.tga",
    L3     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\L3.tga",
    DUP    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DUP.tga",
    DDOWN  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DDOWN.tga",
    DLEFT  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DLEFT.tga",
    DRIGHT = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DRIGHT.tga",
    DALL   = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\navigate_all_directions.tga",
    GOLD   = "Interface\\MoneyFrame\\UI-GoldIcon",
    SILVER = "Interface\\MoneyFrame\\UI-SilverIcon",
    COPPER = "Interface\\MoneyFrame\\UI-CopperIcon",
}

local NINESLICE = {
    texture    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Carved_9Slides.tga",
    cornerSize = 48,
    drawLayer  = "BACKGROUND",
    uv = {
        col = {
            { 0.0000, 0.2500 }, -- Esquerda (0 a 64px de 256px)
            { 0.2500, 0.5000 }, -- Centro (64 a 128px de 256px)
            { 0.5000, 0.7500 }, -- Direita (128 a 192px de 256px)
        },
        row = {
            { 0.0000, 0.2500 }, -- Topo (0 a 64px de 256px)
            { 0.2500, 0.5000 }, -- Centro (64 a 128px de 256px)
            { 0.5000, 0.7500 }, -- Fundo (128 a 192px de 256px)
        }
    }
}

-- ----------------------------------------------------------------------------
-- 2. ESTADO DO MÓDULO (FASE 2)
-- ----------------------------------------------------------------------------
TrainerMenu.isOpen      = false
TrainerMenu.initialized = false
TrainerMenu.trainerName = nil
TrainerMenu.trainerType = nil
TrainerMenu.numServices = 0

TrainerMenu.dimmer        = nil
TrainerMenu.frame         = nil
TrainerMenu.footerWidgets = nil

-- ----------------------------------------------------------------------------
-- 3. HELPERS TIPOGRÁFICOS E FORMATAÇÃO DE MOEDAS
-- ----------------------------------------------------------------------------
function TrainerMenu:ApplyFont(fontString, fontPath, size, outline, shadowOffset, shadowColor)
    if not fontString then return end
    fontPath = fontPath or FONTS.bodyBold
    size = size or 12
    outline = outline or ""

    local ok = fontString:SetFont(fontPath, size, outline)
    if not ok then
        fontString:SetFont(FONTS.fallback, size, outline)
    end

    local so = shadowOffset or { 1, -1 }
    local sc = shadowColor or { 0, 0, 0, 0.90 }
    fontString:SetShadowOffset(so[1], so[2])
    fontString:SetShadowColor(sc[1], sc[2], sc[3], sc[4])
end

function TrainerMenu:FormatMoneyText(totalCopper)
    totalCopper = totalCopper or 0
    if totalCopper < 0 then totalCopper = 0 end

    local gold   = math.floor(totalCopper / 10000)
    local silver = math.floor(math.mod(totalCopper, 10000) / 100)
    local copper = math.floor(math.mod(totalCopper, 100))

    local text = ""
    if gold > 0 then
        text = text .. "|cffffd700" .. gold .. "g|r "
    end
    if silver > 0 or gold > 0 then
        text = text .. "|cffc7c7cf" .. silver .. "s|r "
    end
    text = text .. "|cffeda55f" .. copper .. "c|r"
    return text
end

-- ----------------------------------------------------------------------------
-- 4. CONSTRUTOR 9-SLICE ESCULPIDO OFICIAL
-- ----------------------------------------------------------------------------
function TrainerMenu:Create9Slice(parent, texturePath, cornerSize, uvMap, drawLayer)
    if not parent or not texturePath then return nil end

    cornerSize = cornerSize or NINESLICE.cornerSize
    uvMap = uvMap or NINESLICE.uv
    drawLayer = drawLayer or NINESLICE.drawLayer

    local slices = {}

    local function makeSlice(name, u1, u2, v1, v2)
        local tex = parent:CreateTexture(nil, drawLayer)
        tex:SetTexture(texturePath)
        tex:SetTexCoord(u1, u2, v1, v2)
        return tex
    end

    local c = uvMap.col
    local r = uvMap.row

    -- 1. Cantos fixos
    slices.topLeft = makeSlice("TopLeft", c[1][1], c[1][2], r[1][1], r[1][2])
    slices.topLeft:SetWidth(cornerSize)
    slices.topLeft:SetHeight(cornerSize)
    slices.topLeft:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    slices.topRight = makeSlice("TopRight", c[3][1], c[3][2], r[1][1], r[1][2])
    slices.topRight:SetWidth(cornerSize)
    slices.topRight:SetHeight(cornerSize)
    slices.topRight:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    slices.bottomLeft = makeSlice("BottomLeft", c[1][1], c[1][2], r[3][1], r[3][2])
    slices.bottomLeft:SetWidth(cornerSize)
    slices.bottomLeft:SetHeight(cornerSize)
    slices.bottomLeft:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)

    slices.bottomRight = makeSlice("BottomRight", c[3][1], c[3][2], r[3][1], r[3][2])
    slices.bottomRight:SetWidth(cornerSize)
    slices.bottomRight:SetHeight(cornerSize)
    slices.bottomRight:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- 2. Bordas Horizontais
    slices.top = makeSlice("Top", c[2][1], c[2][2], r[1][1], r[1][2])
    slices.top:SetHeight(cornerSize)
    slices.top:SetPoint("TOPLEFT", slices.topLeft, "TOPRIGHT", 0, 0)
    slices.top:SetPoint("TOPRIGHT", slices.topRight, "TOPLEFT", 0, 0)

    slices.bottom = makeSlice("Bottom", c[2][1], c[2][2], r[3][1], r[3][2])
    slices.bottom:SetHeight(cornerSize)
    slices.bottom:SetPoint("BOTTOMLEFT", slices.bottomLeft, "BOTTOMRIGHT", 0, 0)
    slices.bottom:SetPoint("BOTTOMRIGHT", slices.bottomRight, "BOTTOMLEFT", 0, 0)

    -- 3. Bordas Verticais
    slices.left = makeSlice("Left", c[1][1], c[1][2], r[2][1], r[2][2])
    slices.left:SetWidth(cornerSize)
    slices.left:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMLEFT", 0, 0)
    slices.left:SetPoint("BOTTOMLEFT", slices.bottomLeft, "TOPLEFT", 0, 0)

    slices.right = makeSlice("Right", c[3][1], c[3][2], r[2][1], r[2][2])
    slices.right:SetWidth(cornerSize)
    slices.right:SetPoint("TOPRIGHT", slices.topRight, "BOTTOMRIGHT", 0, 0)
    slices.right:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPRIGHT", 0, 0)

    -- 4. Centro
    slices.center = makeSlice("Center", c[2][1], c[2][2], r[2][1], r[2][2])
    slices.center:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMRIGHT", 0, 0)
    slices.center:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPLEFT", 0, 0)

    return slices
end

-- ----------------------------------------------------------------------------
-- 5. CONSTRUÇÃO DA INTERFACE VISUAL (CANVAS RESPONSIVO SPLIT-VIEW)
-- ----------------------------------------------------------------------------
function TrainerMenu:CreateDimmer()
    if self.dimmer then return end

    local dimmer = CreateFrame("Frame", "ConsoleMode_TrainerDimmer", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("HIGH")
    dimmer:SetFrameLevel(9)
    dimmer:EnableMouse(true)
    dimmer:Hide()

    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints(dimmer)
    dimTex:SetTexture(0.0, 0.0, 0.0, 0.65)
    dimmer.texture = dimTex

    self.dimmer = dimmer
end

function TrainerMenu:CreateFooterHints(parent)
    local hints = {
        { icons = { "A" },    label = "Marcar / Expandir" },
        { icons = { "RT" },   label = "Revisar Carrinho (0)" },
        { icons = { "Y" },    label = "Marcar Todas" },
        { icons = { "DALL" }, label = "Navegar" },
        { icons = { "L3" },   label = "Focar Busca" },
        { icons = { "X" },    label = "Limpar Busca" },
        { icons = { "B" },    label = "Fechar" },
    }

    local container = CreateFrame("Frame", "ConsoleMode_TrainerFooterContainer", parent)
    container:SetHeight(34)
    container:SetPoint("CENTER", parent, "BOTTOM", 0, 18)
    parent.footerContainer = container

    local widgets = {}
    local numHints = table.getn(hints)
    for i = 1, numHints do
        local hint = hints[i]
        local groupFrame = CreateFrame("Frame", nil, container)
        groupFrame:SetHeight(34)

        local currentX = 0
        local numIcons = table.getn(hint.icons)
        for k = 1, numIcons do
            local iconKey = hint.icons[k]
            local texPath = ICONS[iconKey]
            local iconTex = groupFrame:CreateTexture(nil, "OVERLAY")

            local curIconW = 27
            local curIconH = 27
            if iconKey == "A" or iconKey == "B" or iconKey == "X" or iconKey == "Y" or iconKey == "LB" or iconKey == "RB" or iconKey == "RT" or iconKey == "LT" then
                curIconW = 30
                curIconH = 30
            end

            iconTex:SetWidth(curIconW)
            iconTex:SetHeight(curIconH)
            iconTex:SetTexture(texPath)
            iconTex:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
            currentX = currentX + curIconW + 3
        end

        currentX = currentX + 5
        local iconsWidth = currentX

        local label = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
        self:ApplyFont(label, FONTS.bodyBold, 17)
        label:SetText(hint.label)
        label:SetTextColor(0.85, 0.85, 0.85, 0.95)

        local textW = math.floor(label:GetStringWidth() or 40)
        currentX = currentX + textW

        local sep = nil
        if i < numHints then
            sep = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            sep:SetPoint("LEFT", groupFrame, "LEFT", currentX + 8, 0)
            self:ApplyFont(sep, FONTS.medium, 14)
            sep:SetText("|cff666666•|r")
            currentX = currentX + 8 + 12
        end

        groupFrame:SetWidth(currentX)
        groupFrame.label = label
        groupFrame.sep = sep
        groupFrame.iconsWidth = iconsWidth

        table.insert(widgets, groupFrame)
    end

    self.footerWidgets = widgets
    self:UpdateFooterHints()
end

function TrainerMenu:UpdateFooterHints()
    if not self.frame or not self.footerWidgets then return end

    local numWidgets = table.getn(self.footerWidgets)
    local totalWidth = 0

    for i = 1, numWidgets do
        local widget = self.footerWidgets[i]
        local textW = math.floor(widget.label:GetStringWidth() or 40)
        local curX = widget.iconsWidth + textW

        if widget.sep then
            if i == numWidgets then
                widget.sep:Hide()
            else
                widget.sep:ClearAllPoints()
                widget.sep:SetPoint("LEFT", widget, "LEFT", curX + 8, 0)
                widget.sep:Show()
                curX = curX + 8 + 12
            end
        end

        widget:SetWidth(curX)
        totalWidth = totalWidth + curX
    end

    local container = self.frame.footerContainer
    if container then
        local startX = -math.floor(totalWidth / 2)
        local curX = startX
        for i = 1, numWidgets do
            local widget = self.footerWidgets[i]
            widget:ClearAllPoints()
            widget:SetPoint("LEFT", container, "CENTER", curX, 0)
            curX = curX + widget:GetWidth()
        end
        container:SetWidth(totalWidth)
    end
end

function TrainerMenu:CreateUI()
    if self.frame then return end

    self:CreateDimmer()

    -- Janela Principal (9-slice esculpido oficial)
    local frame = CreateFrame("Frame", "ConsoleMode_TrainerFrame", UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(10)
    frame:SetMovable(false)
    frame:EnableMouse(true)
    frame:Hide()

    self.slices = self:Create9Slice(
        frame,
        NINESLICE.texture,
        NINESLICE.cornerSize,
        NINESLICE.uv,
        NINESLICE.drawLayer
    )

    table.insert(UISpecialFrames, "ConsoleMode_TrainerFrame")
    frame:SetScript("OnHide", function()
        if TrainerMenu.isOpen then
            TrainerMenu:Close()
        end
    end)

    self.frame = frame

    -- Título Superior Central
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", frame, "TOP", 0, -18)
    self:ApplyFont(titleText, FONTS.titleBold, 22)
    titleText:SetText("TREINAMENTO DE CLASSE")
    frame.titleText = titleText

    -- Barra de Cabeçalho (Nome do NPC, Saldo de Moedas e Botão Fechar)
    local header = CreateFrame("Frame", "ConsoleMode_TrainerHeader", frame)
    header:SetHeight(32)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -18)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -18)
    frame.header = header

    -- Nome do NPC em Dourado
    local npcNameText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    npcNameText:SetPoint("LEFT", header, "LEFT", 0, 0)
    self:ApplyFont(npcNameText, FONTS.titleBold, 18)
    npcNameText:SetText("Treinador: |cffe09a15Desconhecido|r")
    header.npcNameText = npcNameText

    -- Saldo de Moedas
    local playerMoneyText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playerMoneyText:SetPoint("RIGHT", header, "RIGHT", -110, 0)
    self:ApplyFont(playerMoneyText, FONTS.titleBold, 18)
    playerMoneyText:SetText("0g 0s 0c")
    header.playerMoneyText = playerMoneyText

    -- Botão Fechar estilizado
    local closeBtn = CreateFrame("Button", "ConsoleMode_TrainerCloseBtn", header)
    closeBtn:SetWidth(96)
    closeBtn:SetHeight(28)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    closeBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    closeBtn:SetBackdropColor(0.12, 0.08, 0.05, 0.90)
    closeBtn:SetBackdropBorderColor(0.60, 0.48, 0.25, 0.80)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    self:ApplyFont(closeText, FONTS.bodyBold, 15)
    closeText:SetText("|cffffffff[B] Fechar|r")

    closeBtn:SetScript("OnClick", function()
        TrainerMenu:Close()
    end)
    closeBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
    end)
    closeBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.25, 0.80)
    end)
    header.closeBtn = closeBtn

    -- Barra de Rodapé com Atalhos do Controle
    self:CreateFooterHints(frame)

    -- Área Central de Conteúdo Split-View
    local contentArea = CreateFrame("Frame", "ConsoleMode_TrainerContentArea", frame)
    contentArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -54)
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 48)
    frame.contentArea = contentArea

    -- Divisória Central Vertical
    local divider = frame:CreateTexture("ConsoleMode_TrainerDivider", "ARTWORK")
    divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetWidth(2)
    divider:SetVertexColor(0.6, 0.5, 0.3, 0.4)
    divider:SetPoint("TOP", contentArea, "TOP", 0, 0)
    divider:SetPoint("BOTTOM", contentArea, "BOTTOM", 0, 0)
    divider:SetPoint("CENTER", contentArea, "CENTER", 0, 0)
    frame.divider = divider

    -- Helper para construir coluna com cabeçalho interno
    local function CreateColumnPanel(name, titleText, iconTag)
        local col = CreateFrame("Frame", name, contentArea)
        col:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 12,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        col:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
        col:SetBackdropBorderColor(0.50, 0.40, 0.28, 0.65)

        local colHeader = CreateFrame("Frame", nil, col)
        colHeader:SetHeight(34)
        colHeader:SetPoint("TOPLEFT", col, "TOPLEFT", 8, -6)
        colHeader:SetPoint("TOPRIGHT", col, "TOPRIGHT", -8, -6)
        col.header = colHeader

        local tagIcon = colHeader:CreateTexture(nil, "OVERLAY")
        tagIcon:SetWidth(28)
        tagIcon:SetHeight(28)
        tagIcon:SetPoint("LEFT", colHeader, "LEFT", 0, 0)
        tagIcon:SetTexture(iconTag)
        col.tagIcon = tagIcon

        local colTitle = colHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        colTitle:SetPoint("LEFT", tagIcon, "RIGHT", 8, 0)
        TrainerMenu:ApplyFont(colTitle, FONTS.titleBold, 18)
        colTitle:SetText(titleText)
        col.title = colTitle

        local placeholder = col:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        placeholder:SetPoint("CENTER", col, "CENTER", 0, 0)
        TrainerMenu:ApplyFont(placeholder, FONTS.medium, 16)
        col.placeholder = placeholder

        return col
    end

    -- Coluna Esquerda: Catálogo de Habilidades
    local leftCol = CreateColumnPanel("ConsoleMode_TrainerColLeft", "CATÁLOGO DE HABILIDADES", ICONS.LB)
    leftCol:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
    leftCol:SetPoint("BOTTOMLEFT", contentArea, "BOTTOMLEFT", 0, 0)
    leftCol:SetPoint("RIGHT", divider, "LEFT", -6, 0)
    leftCol.placeholder:SetText("|cffe09a15Carregando catálogo do treinador...|r\n|cffaaaaaa(Fase 3: Disponíveis, Futuras e Já Aprendidas)|r")
    frame.leftCol = leftCol

    -- Coluna Direita: Detalhes & Comparativo
    local rightCol = CreateColumnPanel("ConsoleMode_TrainerColRight", "DETALHES & EVOLUÇÃO DA HABILIDADE", ICONS.RB)
    rightCol:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", 0, 0)
    rightCol:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    rightCol:SetPoint("LEFT", divider, "RIGHT", 6, 0)
    rightCol.placeholder:SetText("|cffe09a15Selecione uma habilidade à esquerda para inspecionar.|r\n|cffaaaaaa(Fase 4: Comparativo Grimório vs Treinador)|r")
    frame.rightCol = rightCol
end

function TrainerMenu:UpdateLayout()
    if not self.frame then return end

    local screenW = (UIParent and UIParent:GetWidth()) or 1024
    local screenH = (UIParent and UIParent:GetHeight()) or 768

    local w = math.floor(screenW * 0.94)
    local h = math.floor(screenH * 0.85)

    if w < 840 then w = 840 end
    if h < 520 then h = 520 end
    if w > 1440 then w = 1440 end
    if h > 920 then h = 920 end

    self.frame:SetWidth(w)
    self.frame:SetHeight(h)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    if self.frame.footerContainer then
        self.frame.footerContainer:ClearAllPoints()
        self.frame.footerContainer:SetPoint("CENTER", self.frame, "BOTTOM", 0, 18)
    end
    self:UpdateFooterHints()
end

function TrainerMenu:RefreshHeader()
    if not self.frame then return end

    -- Título dinâmico
    local titleStr = "TREINAMENTO DE CLASSE"
    if self.trainerType == "tradeskill" then
        titleStr = "TREINAMENTO DE PROFISSÃO"
    end
    if self.frame.titleText then
        self.frame.titleText:SetText(titleStr)
    end

    -- Nome do NPC em Dourado
    local npcName = self.trainerName or UnitName("npc") or "Treinador"
    if self.frame.header and self.frame.header.npcNameText then
        self.frame.header.npcNameText:SetText("Treinador: |cffe09a15" .. npcName .. "|r")
    end

    -- Saldo do jogador
    local playerMoney = GetMoney() or 0
    if self.frame.header and self.frame.header.playerMoneyText then
        self.frame.header.playerMoneyText:SetText(self:FormatMoneyText(playerMoney))
    end
end

-- ----------------------------------------------------------------------------
-- 6. CICLO DE VIDA, ABERTURA E FECHAMENTO
-- ----------------------------------------------------------------------------
function TrainerMenu:Open()
    self:CreateUI()
    self:UpdateLayout()
    self:RefreshHeader()

    if self.dimmer then
        self.dimmer:Show()
    end
    self.frame:Show()

    -- Ativa o Modo de Navegação no Gamepad
    if ConsoleMode and ConsoleMode.keybindings then
        if not ConsoleMode.keybindings.navigationMode then
            if ConsoleMode.keybindings.EnterNavigationMode then
                ConsoleMode.keybindings:EnterNavigationMode()
            end
        else
            if ConsoleMode.keybindings.ReapplyNavigationBindings then
                ConsoleMode.keybindings:ReapplyNavigationBindings()
            end
        end
    end

    PlaySound("igMainMenuOpen")
end

function TrainerMenu:Close()
    if not self.isOpen then return end

    self.isOpen      = false
    self.trainerName = nil
    self.trainerType = nil
    self.numServices = 0

    if self.dimmer and self.dimmer:IsVisible() then
        self.dimmer:Hide()
    end
    if self.frame and self.frame:IsVisible() then
        self.frame:Hide()
    end

    -- Desativa o Modo de Navegação no Gamepad de forma forçada
    if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.ExitNavigationMode then
        ConsoleMode.keybindings:ExitNavigationMode(true)
    end

    if CloseTrainer then
        CloseTrainer()
    end
    PlaySound("igMainMenuClose")
end

function TrainerMenu:OnCancel()
    self:Close()
end

-- ----------------------------------------------------------------------------
-- 7. SUPRESSÃO SEGURA DO FRAME NATIVO DA BLIZZARD (Zero Taint)
-- ----------------------------------------------------------------------------
function TrainerMenu:SuppressDefaultFrame()
    local f = ClassTrainerFrame or getglobal("ClassTrainerFrame")
    if f then
        f:SetAlpha(0)
        f:EnableMouse(false)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 5000)
    end
end

-- ----------------------------------------------------------------------------
-- 8. EVENTOS DO CICLO DE VIDA DO TREINADOR
-- ----------------------------------------------------------------------------
function TrainerMenu:OnTrainerShow()
    -- 1. Suprime o frame nativo off-screen
    self:SuppressDefaultFrame()

    -- 2. Lê os metadados oficiais da interação
    local npcName = UnitName("npc")
    if not npcName or npcName == "" then
        npcName = "Treinador"
    end

    local trainerType = "class"
    if GetTrainerType then
        trainerType = GetTrainerType() or "class"
    end

    local numServices = 0
    if GetNumTrainerServices then
        numServices = GetNumTrainerServices() or 0
    end

    self.isOpen      = true
    self.trainerName = npcName
    self.trainerType = trainerType
    self.numServices = numServices

    -- 3. Abre a interface nobre do ConsoleMode
    self:Open()

    -- 4. Delay de segurança (50ms) para re-suprimir caso a Blizzard tente renderizar tardiamente
    local delayedSafety = CreateFrame("Frame")
    delayedSafety:SetScript("OnUpdate", function()
        this.t = (this.t or 0) + (arg1 or 0)
        if this.t >= 0.05 then
            this:SetScript("OnUpdate", nil)
            TrainerMenu:SuppressDefaultFrame()
        end
    end)
end

function TrainerMenu:OnTrainerUpdate()
    if not self.isOpen then return end

    if GetNumTrainerServices then
        self.numServices = GetNumTrainerServices() or 0
    end
    self:RefreshHeader()
end

function TrainerMenu:OnTrainerClosed()
    if self.isOpen then
        self.isOpen      = false
        self.trainerName = nil
        self.trainerType = nil
        self.numServices = 0

        if self.dimmer and self.dimmer:IsVisible() then
            self.dimmer:Hide()
        end
        if self.frame and self.frame:IsVisible() then
            self.frame:Hide()
        end

        if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.ExitNavigationMode then
            ConsoleMode.keybindings:ExitNavigationMode(true)
        end
    end
end

function TrainerMenu:OnMoneyUpdate()
    if not self.isOpen then return end
    self:RefreshHeader()
end

-- ----------------------------------------------------------------------------
-- 9. INICIALIZAÇÃO E REGISTRO DE EVENTOS
-- ----------------------------------------------------------------------------
function TrainerMenu:Initialize()
    if self.initialized then return end
    self.initialized = true

    local ef = CreateFrame("Frame", "ConsoleMode_TrainerEventFrame")
    ef:RegisterEvent("TRAINER_SHOW")
    ef:RegisterEvent("TRAINER_UPDATE")
    ef:RegisterEvent("TRAINER_CLOSED")
    ef:RegisterEvent("PLAYER_MONEY")

    ef:SetScript("OnEvent", function()
        if event == "TRAINER_SHOW" then
            TrainerMenu:OnTrainerShow()
        elseif event == "TRAINER_UPDATE" then
            TrainerMenu:OnTrainerUpdate()
        elseif event == "TRAINER_CLOSED" then
            TrainerMenu:OnTrainerClosed()
        elseif event == "PLAYER_MONEY" then
            TrainerMenu:OnMoneyUpdate()
        end
    end)
end

-- Inicialização automática no carregamento das variáveis/login
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    TrainerMenu:Initialize()
end)
