-- ============================================================================
-- ConsoleModeVanilla - UI/AuctionScreen.lua
-- Tela de Leilão (Auction House) para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE 0: Fundação, Moldura 9-Slice, Abas e Hook de Abertura
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_AuctionScreen = ConsoleMode_AuctionScreen or {}
local AuctionScreen = ConsoleMode_AuctionScreen
CM.auctionScreen = AuctionScreen

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
-- 2. ESTADO DO MÓDULO
-- ----------------------------------------------------------------------------
AuctionScreen.isOpen           = false
AuctionScreen.initialized      = false
AuctionScreen.currentTab       = "BUY" -- "BUY", "SELL", "OWNER"
AuctionScreen.frame            = nil
AuctionScreen.dimmer           = nil
AuctionScreen.eventFrame       = nil
AuctionScreen.footerWidgets    = nil

local TABS = {
    { key = "BUY",   labelKey = "AH_TAB_BUY" },
    { key = "SELL",  labelKey = "AH_TAB_SELL" },
    { key = "OWNER", labelKey = "AH_TAB_MY_AUCTIONS" }
}

-- ----------------------------------------------------------------------------
-- 3. HELPERS DE TIPOGRAFIA E 9-SLICE
-- ----------------------------------------------------------------------------
function AuctionScreen:ApplyFont(fontString, fontPath, size, outline, shadowOffset, shadowColor)
    if not fontString then return end
    fontPath = fontPath or FONTS.bodyBold
    size = size or 12

    local success = fontString:SetFont(fontPath, size, outline or "")
    if not success and FONTS.fallback then
        fontString:SetFont(FONTS.fallback, size, outline or "")
    end

    if shadowOffset then
        fontString:SetShadowOffset(shadowOffset, -shadowOffset)
    else
        fontString:SetShadowOffset(1, -1)
    end

    if shadowColor then
        fontString:SetShadowColor(unpack(shadowColor))
    else
        fontString:SetShadowColor(0, 0, 0, 0.8)
    end
end

function AuctionScreen:Create9Slice(parent, texturePath, cornerSize, uvMap, drawLayer)
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
-- 4. CRIAÇÃO DE ELEMENTOS DA INTERFACE (DIMMER, ABAS, HEADER, FOOTER)
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateDimmer()
    if self.dimmer then return end

    local dimmer = CreateFrame("Frame", "ConsoleMode_AuctionDimmer", UIParent)
    dimmer:SetFrameStrata("HIGH")
    dimmer:SetFrameLevel(5)
    dimmer:SetAllPoints(UIParent)
    dimmer:EnableMouse(true)
    dimmer:Hide()

    local bg = dimmer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(dimmer)
    bg:SetTexture(0, 0, 0, 0.65)
    dimmer.bg = bg

    dimmer:SetScript("OnMouseDown", function()
        AuctionScreen:Close()
    end)

    self.dimmer = dimmer
end

function AuctionScreen:CreateTabIndicator(parent)
    local tabContainer = CreateFrame("Frame", "ConsoleMode_AuctionTabIndicator", parent)
    tabContainer:SetHeight(32)
    tabContainer:SetPoint("TOP", parent, "TOP", 0, -48)

    -- Ícone LB à esquerda
    local lbIcon = tabContainer:CreateTexture(nil, "ARTWORK")
    lbIcon:SetWidth(26)
    lbIcon:SetHeight(26)
    lbIcon:SetTexture(ICONS.LB)
    lbIcon:SetPoint("LEFT", tabContainer, "LEFT", 0, 0)

    -- Botões das Abas
    local tabButtons = {}
    local totalW = 26 + 10 -- offset inicial após LB

    for i = 1, table.getn(TABS) do
        local tabData = TABS[i]
        local btn = CreateFrame("Button", "ConsoleMode_AuctionTabBtn" .. i, tabContainer)
        btn:SetHeight(26)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self:ApplyFont(label, FONTS.titleBold, 15)
        label:SetText(CM:T(tabData.labelKey))
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.label = label

        local textW = math.floor(label:GetStringWidth() or 60)
        local btnW = textW + 28
        btn:SetWidth(btnW)
        btn:SetPoint("LEFT", tabContainer, "LEFT", totalW, 0)
        totalW = totalW + btnW + 6

        btn:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        btn.tabKey = tabData.key
        btn:SetScript("OnClick", function()
            AuctionScreen:SetTab(this.tabKey)
        end)

        table.insert(tabButtons, btn)
    end

    -- Ícone RB à direita
    local rbIcon = tabContainer:CreateTexture(nil, "ARTWORK")
    rbIcon:SetWidth(26)
    rbIcon:SetHeight(26)
    rbIcon:SetTexture(ICONS.RB)
    rbIcon:SetPoint("LEFT", tabContainer, "LEFT", totalW + 4, 0)
    totalW = totalW + 26 + 4

    tabContainer:SetWidth(totalW)
    tabContainer.buttons = tabButtons
    self.tabContainer = tabContainer
    self:UpdateTabStyles()
end

function AuctionScreen:UpdateTabStyles()
    if not self.tabContainer or not self.tabContainer.buttons then return end

    local numBtns = table.getn(self.tabContainer.buttons)
    for i = 1, numBtns do
        local btn = self.tabContainer.buttons[i]
        local isActive = (btn.tabKey == self.currentTab)

        if isActive then
            btn:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
            btn:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
            btn.label:SetTextColor(1.0, 0.90, 0.40, 1.0)
        else
            btn:SetBackdropColor(0.08, 0.06, 0.04, 0.70)
            btn:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.60)
            btn.label:SetTextColor(0.65, 0.65, 0.65, 0.90)
        end
    end
end

function AuctionScreen:CreateFooterHints(parent)
    local container = CreateFrame("Frame", "ConsoleMode_AuctionFooterContainer", parent)
    container:SetHeight(34)
    container:SetPoint("CENTER", parent, "BOTTOM", 0, 28)
    parent.footerContainer = container

    local hints = {
        { icons = { "A" },          label = CM:T("AH_HINT_SELECT") },
        { icons = { "LB", "RB" },   label = CM:T("AH_HINT_SWITCH_TAB") },
        { icons = { "B" },          label = CM:T("AH_HINT_CLOSE") }
    }

    local widgets = {}
    local numHints = table.getn(hints)
    local totalWidth = 0

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

            local curIconW = 28
            local curIconH = 28
            iconTex:SetWidth(curIconW)
            iconTex:SetHeight(curIconH)
            iconTex:SetTexture(texPath)
            iconTex:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
            currentX = currentX + curIconW + 3
        end

        currentX = currentX + 5
        local label = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
        self:ApplyFont(label, FONTS.bodyBold, 16)
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
        groupFrame.hintIndex = i

        table.insert(widgets, groupFrame)
        totalWidth = totalWidth + currentX
    end

    local startX = -math.floor(totalWidth / 2)
    local curX = startX
    for i = 1, numHints do
        local widget = widgets[i]
        widget:ClearAllPoints()
        widget:SetPoint("LEFT", container, "CENTER", curX, 0)
        curX = curX + widget:GetWidth()
    end

    container:SetWidth(totalWidth)
    self.footerWidgets = widgets
end

-- ----------------------------------------------------------------------------
-- 5. CRIAÇÃO DA INTERFACE PRINCIPAL
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateUI()
    if self.frame then return end

    self:CreateDimmer()

    local frame = CreateFrame("Frame", "ConsoleMode_AuctionFrame", UIParent)
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

    table.insert(UISpecialFrames, "ConsoleMode_AuctionFrame")
    frame:SetScript("OnHide", function()
        if AuctionScreen.isOpen then
            AuctionScreen:Close()
        end
    end)

    self.frame = frame

    -- Título Superior Central
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", frame, "TOP", 0, -18)
    self:ApplyFont(titleText, FONTS.titleBold, 26)
    titleText:SetText(CM:T("AH_TITLE"))
    frame.titleText = titleText

    -- Indicador de Abas (Comprar, Vender, Meus Leilões)
    self:CreateTabIndicator(frame)

    -- Barra de Cabeçalho (Subtítulo / NPC e Botão Sair)
    local header = CreateFrame("Frame", "ConsoleMode_AuctionHeader", frame)
    header:SetHeight(32)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -16)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -16)
    frame.header = header

    local npcText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    npcText:SetPoint("LEFT", header, "LEFT", 4, 0)
    self:ApplyFont(npcText, FONTS.titleBold, 17)
    npcText:SetText(string.format(CM:T("AH_HEADER_AUCTIONEER_FMT"), UnitName("npc") or CM:T("AH_UNKNOWN_AUCTIONEER")))
    frame.npcText = npcText

    -- Botão Sair (Canto Superior Direito)
    local closeBtn = CreateFrame("Button", "ConsoleMode_AuctionCloseBtn", header)
    closeBtn:SetWidth(96)
    closeBtn:SetHeight(28)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    closeBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    closeBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    closeBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local closeIcon = closeBtn:CreateTexture(nil, "OVERLAY")
    closeIcon:SetWidth(25)
    closeIcon:SetHeight(25)
    closeIcon:SetPoint("LEFT", closeBtn, "LEFT", 6, 0)
    closeIcon:SetTexture(ICONS.B)

    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeTxt:SetPoint("LEFT", closeIcon, "RIGHT", 6, 0)
    self:ApplyFont(closeTxt, FONTS.titleBold, 16)
    closeTxt:SetText(CM:T("AH_BUTTON_CLOSE"))

    closeBtn:SetScript("OnClick", function()
        AuctionScreen:Close()
    end)
    closeBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    closeBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    header.closeBtn = closeBtn

    -- Área de Conteúdo Central (Container para as fases seguintes)
    local contentArea = CreateFrame("Frame", "ConsoleMode_AuctionContentArea", frame)
    contentArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -86)
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 60)
    frame.contentArea = contentArea

    -- Footer Hints
    self:CreateFooterHints(frame)

    self.initialized = true
end

function AuctionScreen:UpdateLayout()
    if not self.frame then return end

    local screenW = GetScreenWidth() or 1024
    local screenH = GetScreenHeight() or 768

    local w = math.floor(screenW * 0.94)
    local h = math.floor(screenH * 0.86)

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
        self.frame.footerContainer:SetPoint("CENTER", self.frame, "BOTTOM", 0, 28)
    end
end

-- ----------------------------------------------------------------------------
-- 6. NAVEGAÇÃO ENTRE ABAS
-- ----------------------------------------------------------------------------
function AuctionScreen:SetTab(tabKey)
    if self.currentTab == tabKey then return end
    self.currentTab = tabKey
    self:UpdateTabStyles()
end

function AuctionScreen:SwitchTab(delta)
    local currentIdx = 1
    local numTabs = table.getn(TABS)
    for i = 1, numTabs do
        if TABS[i].key == self.currentTab then
            currentIdx = i
            break
        end
    end

    local nextIdx = currentIdx + delta
    if nextIdx < 1 then
        nextIdx = numTabs
    elseif nextIdx > numTabs then
        nextIdx = 1
    end

    self:SetTab(TABS[nextIdx].key)
end

-- ----------------------------------------------------------------------------
-- 7. ABERTURA E FECHAMENTO
-- ----------------------------------------------------------------------------
function AuctionScreen:Open()
    if not self.initialized then
        self:CreateUI()
    end

    -- Carregamento do Data Lake autônomo (se disponível)
    if CM.LoadDataLake then
        pcall(function() CM:LoadDataLake("AuctionScreen") end)
    end

    -- Esconde frame nativo Blizzard para não conflitar
    if AuctionFrame and AuctionFrame:IsVisible() then
        AuctionFrame:Hide()
    end

    -- Bloqueia e esconde cursor legado para garantir navegação puramente programática
    local cursor = CM.cursor or (ConsoleMode and ConsoleMode.cursor)
    if cursor then
        if cursor.Hide then cursor:Hide() end
        if cursor.Disable then cursor:Disable() end
    end

    if CM.keybindings and CM.keybindings.EnterNavigationMode then
        CM.keybindings:EnterNavigationMode()
    end

    if self.frame.npcText then
        self.frame.npcText:SetText(string.format(CM:T("AH_HEADER_AUCTIONEER_FMT"), UnitName("npc") or CM:T("AH_UNKNOWN_AUCTIONEER")))
    end

    self:UpdateLayout()

    if self.dimmer then
        self.dimmer:Show()
    end
    if self.frame then
        self.frame:Show()
    end

    self.isOpen = true
end

function AuctionScreen:Close(fromServer)
    if not self.isOpen then return end

    if self.frame then
        self.frame:Hide()
    end
    if self.dimmer then
        self.dimmer:Hide()
    end

    self.isOpen = false

    if CM.keybindings and CM.keybindings.ExitNavigationMode then
        CM.keybindings:ExitNavigationMode()
    end

    if not fromServer then
        if CloseAuctionHouse then
            pcall(CloseAuctionHouse)
        end
    end
end

function AuctionScreen:OnCancel()
    self:Close()
end

-- ----------------------------------------------------------------------------
-- 8. GANCHOS DE EVENTO (AUCTION_HOUSE_SHOW / AUCTION_HOUSE_CLOSED)
-- ----------------------------------------------------------------------------
function AuctionScreen:InitEvents()
    if self.eventFrame then return end

    local ef = CreateFrame("Frame", "ConsoleMode_AuctionScreenEventFrame")
    ef:RegisterEvent("AUCTION_HOUSE_SHOW")
    ef:RegisterEvent("AUCTION_HOUSE_CLOSED")

    ef:SetScript("OnEvent", function()
        if event == "AUCTION_HOUSE_SHOW" then
            AuctionScreen:Open()
        elseif event == "AUCTION_HOUSE_CLOSED" then
            AuctionScreen:Close(true)
        end
    end)

    self.eventFrame = ef
end

AuctionScreen:InitEvents()
