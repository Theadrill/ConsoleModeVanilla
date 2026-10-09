-- ============================================================================
-- ConsoleModeVanilla - UI/TrainerMenu.lua
-- Sistema Modular de Treinamento de Classe e Profissões para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE 3: Catálogo Estruturado, Seções com Collapse e Barra de Pesquisa
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
-- 2. ESTADO DO MÓDULO (FASE 3)
-- ----------------------------------------------------------------------------
TrainerMenu.isOpen      = false
TrainerMenu.initialized = false
TrainerMenu.trainerName = nil
TrainerMenu.trainerType = nil
TrainerMenu.numServices = 0
TrainerMenu.isScanning  = false
TrainerMenu.isConfiguringFilters = false
TrainerMenu.filtersConfigured    = false

-- Catálogo de serviços e listas filtradas
TrainerMenu.rawServices       = {}
TrainerMenu.availableServices = {}
TrainerMenu.futureServices    = {}
TrainerMenu.usedServices      = {}
TrainerMenu.treesOrder        = {}
TrainerMenu.flattenedList     = {}
TrainerMenu.spellbookCache    = {}

-- Navegação e exibição do catálogo
TrainerMenu.selectedIndex     = 1
TrainerMenu.scrollOffset      = 0
TrainerMenu.visibleRowCount   = 8
TrainerMenu.isFutureCollapsed = true
TrainerMenu.isUsedCollapsed   = true
TrainerMenu.collapsedTrees    = {}
TrainerMenu.searchText        = ""
TrainerMenu.catalogRows       = {}

-- Hold-to-repeat no D-Pad (UP/DOWN)
TrainerMenu.repeatState = {
    direction    = nil,
    timer        = 0,
    initialDelay = 0.35,
    interval     = 0.12,
}
TrainerMenu.repeatFrame  = nil
TrainerMenu.safetyFrame  = nil

-- Carrinho de Treinamento e Compra em Lote (Fase 5 & 6)
TrainerMenu.cartItems         = {}
TrainerMenu.cartKeys          = {}
TrainerMenu.cartSelectedIndex = 1
TrainerMenu.cartScrollOffset  = 0
TrainerMenu.cartModalFrame    = nil
TrainerMenu.cartRows          = {}
TrainerMenu.purchaseState     = nil
TrainerMenu.purchaseFrame     = nil

-- Elementos de Interface
TrainerMenu.dimmer           = nil
TrainerMenu.frame            = nil
TrainerMenu.footerWidgets    = nil
TrainerMenu.searchContainer  = nil
TrainerMenu.searchEditBox    = nil
TrainerMenu.searchPlaceholder= nil
TrainerMenu.searchClearBtn   = nil

-- Hidden tooltip para scanning preciso de feitiços do treinador e grimório (WoW 1.12)
local trainerScanTip = CreateFrame("GameTooltip", "ConsoleMode_TrainerScanTip", UIParent, "GameTooltipTemplate")
trainerScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

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
        groupFrame.hintIndex = i

        groupFrame:EnableMouse(true)
        groupFrame:SetScript("OnMouseDown", function()
            local idx = this.hintIndex
            if idx == 1 then TrainerMenu:OnConfirm()
            elseif idx == 2 then TrainerMenu:OnTriggerAction()
            elseif idx == 3 then TrainerMenu:OnContextAction()
            elseif idx == 5 then TrainerMenu:SelectSearchBar(); TrainerMenu:OpenSearchVK()
            elseif idx == 6 then TrainerMenu:OnSecondaryAction()
            elseif idx == 7 then TrainerMenu:OnCancel()
            end
        end)

        table.insert(widgets, groupFrame)
    end

    self.footerWidgets = widgets
    self:UpdateFooterHints()
end

function TrainerMenu:UpdateFooterHints()
    if not self.frame or not self.footerWidgets then return end

    local selEntry = self.flattenedList and self.flattenedList[self.selectedIndex]
    local isUsedHeader   = (selEntry and selEntry.id == "SECTION_USED")
    local isFutureHeader = (selEntry and selEntry.id == "SECTION_FUTURE")
    local isTreeHeader   = (selEntry and selEntry.type == "TREE_HEADER")

    -- Adapta dinamicamente a legenda do Botão A conforme foco
    if self.footerWidgets[1] and self.footerWidgets[1].label then
        if self.isSearchSelected then
            self.footerWidgets[1].label:SetText("Abrir Teclado")
        elseif isUsedHeader then
            if self.isUsedCollapsed then
                self.footerWidgets[1].label:SetText("Expandir Seção")
            else
                self.footerWidgets[1].label:SetText("Recolher Seção")
            end
        elseif isFutureHeader then
            if self.isFutureCollapsed then
                self.footerWidgets[1].label:SetText("Expandir Seção")
            else
                self.footerWidgets[1].label:SetText("Recolher Seção")
            end
        elseif isTreeHeader then
            if selEntry.isCollapsed then
                self.footerWidgets[1].label:SetText("Expandir Árvore")
            else
                self.footerWidgets[1].label:SetText("Recolher Árvore")
            end
        else
            self.footerWidgets[1].label:SetText("Marcar / Expandir")
        end
    end

    -- Adapta legenda do Botão RT (Carrinho) e Y (Marcar Todas)
    local cartCount = (self.GetCartCount and self:GetCartCount()) or 0
    if self.footerWidgets[2] and self.footerWidgets[2].label then
        self.footerWidgets[2].label:SetText("Revisar Carrinho (" .. cartCount .. ")")
    end
    if self.footerWidgets[3] and self.footerWidgets[3].label then
        local numAvail = table.getn(self.availableServices or {})
        local allSelected = (numAvail > 0 and cartCount >= numAvail)
        self.footerWidgets[3].label:SetText(allSelected and "Desmarcar Todas" or "Marcar Todas")
    end

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

-- ----------------------------------------------------------------------------
-- 5b. BARRA DE PESQUISA (EditBox + Atalho VirtualKeyboard [LS] + Limpar [X])
-- ----------------------------------------------------------------------------
-- 5b. BARRA DE BUSCA EM TEMPO REAL & ATALHO DO VIRTUALKEYBOARD (FASE 3)
-- ----------------------------------------------------------------------------
function TrainerMenu:CreateSearchBar(parent)
    local searchBar = CreateFrame("Button", "ConsoleMode_TrainerSearchBar", parent)
    searchBar:SetHeight(30)
    searchBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -42)
    searchBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -42)
    searchBar:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    searchBar:SetBackdropColor(0.06, 0.04, 0.03, 0.90)
    searchBar:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.70)

    -- Highlight de fundo quando selecionada pelo controle
    local hl = searchBar:CreateTexture(nil, "BACKGROUND")
    hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.25)
    hl:SetAllPoints(searchBar)
    hl:Hide()
    searchBar.highlight = hl

    -- Clique na barra de pesquisa abre o VirtualKeyboard
    searchBar:EnableMouse(true)
    searchBar:RegisterForClicks("LeftButtonUp")
    searchBar:SetScript("OnClick", function()
        TrainerMenu:SelectSearchBar()
        TrainerMenu:OpenSearchVK()
    end)

    -- Botão/Ícone [LS] no controle para abrir o VirtualKeyboard
    local lsBtn = CreateFrame("Button", nil, searchBar)
    lsBtn:SetWidth(24)
    lsBtn:SetHeight(24)
    lsBtn:SetPoint("LEFT", searchBar, "LEFT", 4, 0)

    local lsIcon = lsBtn:CreateTexture(nil, "OVERLAY")
    lsIcon:SetAllPoints(lsBtn)
    lsIcon:SetTexture(ICONS.L3)
    lsBtn.icon = lsIcon

    lsBtn:SetScript("OnClick", function()
        TrainerMenu:SelectSearchBar()
        TrainerMenu:OpenSearchVK()
    end)

    -- Botão Limpar [X]
    local clearBtn = CreateFrame("Button", nil, searchBar)
    clearBtn:SetWidth(26)
    clearBtn:SetHeight(26)
    clearBtn:SetPoint("RIGHT", searchBar, "RIGHT", -4, 0)

    local clearText = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clearText:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
    self:ApplyFont(clearText, FONTS.bodyBold, 15)
    clearText:SetText("|cffaaaaaa[X]|r")

    clearBtn:SetScript("OnClick", function()
        TrainerMenu:ClearSearch()
    end)
    clearBtn:Hide()

    -- Texto Placeholder ("🔍 Buscar habilidade...")
    local placeholder = searchBar:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    placeholder:SetPoint("LEFT", lsBtn, "RIGHT", 6, 0)
    self:ApplyFont(placeholder, FONTS.medium, 14)
    placeholder:SetText("|cff777777🔍 Buscar habilidade...|r")

    -- EditBox nativo com suporte a digitação física e clique de mouse
    local eb = CreateFrame("EditBox", "ConsoleMode_TrainerSearchEB", searchBar)
    eb:SetPoint("LEFT", lsBtn, "RIGHT", 6, 0)
    eb:SetPoint("RIGHT", clearBtn, "LEFT", -4, 0)
    eb:SetHeight(24)
    eb:SetFont(FONTS.bodyBold, 14, "")
    eb:SetTextColor(1.0, 1.0, 1.0, 1.0)
    eb:SetAutoFocus(false)
    eb:EnableMouse(true)
    eb:SetMaxLetters(32)
    eb:SetTextInsets(2, 2, 0, 0)

    eb:SetScript("OnMouseDown", function()
        TrainerMenu:SelectSearchBar()
        TrainerMenu:OpenSearchVK()
    end)

    eb:SetScript("OnTextChanged", function()
        local text = this:GetText() or ""
        TrainerMenu:SetSearchFilter(text)
    end)

    eb:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)

    eb:SetScript("OnEnterPressed", function()
        this:ClearFocus()
    end)

    searchBar.lsBtn       = lsBtn
    searchBar.clearBtn    = clearBtn
    searchBar.placeholder = placeholder
    searchBar.editBox     = eb

    self.searchContainer   = searchBar
    self.searchEditBox     = eb
    self.searchPlaceholder = placeholder
    self.searchClearBtn    = clearBtn

    return searchBar
end

-- ----------------------------------------------------------------------------
-- 5c. POOL FIXO DE LINHAS DO CATÁLOGO (Zero Garbage Collection)
-- ----------------------------------------------------------------------------
function TrainerMenu:CreateCatalogRow(parent, i, rows)
    local row = CreateFrame("Button", "ConsoleMode_TrainerRow" .. i, parent)
    row:SetHeight(42)
    if i == 1 then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    else
        row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -2)
        row:SetPoint("TOPRIGHT", rows[i - 1], "BOTTOMRIGHT", 0, -2)
    end

    row:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    row:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
    row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)

    -- Highlight de fundo quando selecionada
    local hl = row:CreateTexture(nil, "BACKGROUND")
    hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.30)
    hl:SetAllPoints(row)
    hl:Hide()
    row.highlight = hl

    -- Cursor indicador dourado
    local cur = row:CreateTexture(nil, "OVERLAY")
    cur:SetWidth(12)
    cur:SetHeight(12)
    cur:SetPoint("LEFT", row, "LEFT", 4, 0)
    cur:SetTexture("Interface\\QuestFrame\\UI-Quest-BulletPoint")
    cur:SetVertexColor(1.0, 0.85, 0.20)
    cur:Hide()
    row.cursor = cur

    -- Ícone da habilidade (32x32)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(32)
    icon:SetHeight(32)
    icon:SetPoint("LEFT", row, "LEFT", 20, 0)
    row.icon = icon

    local iconBorder = CreateFrame("Frame", nil, row)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    row.iconBorder = iconBorder

    -- Preço / Status à direita
    local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    priceText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    priceText:SetJustifyH("RIGHT")
    self:ApplyFont(priceText, FONTS.titleBold, 15)
    row.priceText = priceText

    -- Nome da habilidade (topo)
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1)
    nameText:SetPoint("RIGHT", priceText, "LEFT", -8, 0)
    nameText:SetJustifyH("LEFT")
    self:ApplyFont(nameText, FONTS.bodyBold, 15)
    row.nameText = nameText

    -- Subtítulo (nível requerido • especialização)
    local subText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
    subText:SetPoint("RIGHT", priceText, "LEFT", -8, 0)
    subText:SetJustifyH("LEFT")
    self:ApplyFont(subText, FONTS.medium, 13)
    row.subText = subText

    -- Texto para Cabeçalhos de Seção / Tree
    local headerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetPoint("LEFT", row, "LEFT", 12, 0)
    headerText:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    headerText:SetJustifyH("LEFT")
    self:ApplyFont(headerText, FONTS.titleBold, 15)
    row.headerText = headerText

    row.rowIndex = i
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function()
        TrainerMenu:OnRowClick(this.flatIndex)
    end)

    row:SetScript("OnEnter", function()
        if this.flatIndex and this.flatIndex ~= TrainerMenu.selectedIndex then
            this:SetBackdropBorderColor(0.70, 0.60, 0.40, 0.80)
        end
    end)

    row:SetScript("OnLeave", function()
        TrainerMenu:RestoreRowBorder(this)
    end)

    row:Hide()
    return row
end

function TrainerMenu:CreateCatalogRows(parent)
    local rows = {}
    for i = 1, 10 do
        local r = self:CreateCatalogRow(parent, i, rows)
        table.insert(rows, r)
    end
    parent.rows = rows
    self.catalogRows = rows
    return rows
end

function TrainerMenu:RestoreRowBorder(row)
    if not row or not row.flatIndex then return end
    local isSel = (row.flatIndex == self.selectedIndex)
    if isSel then
        row:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
        return
    end

    local entry = self.flattenedList and self.flattenedList[row.flatIndex]
    if entry then
        if entry.type == "SECTION_HEADER" then
            row:SetBackdropBorderColor(0.55, 0.42, 0.22, 0.60)
        elseif entry.type == "TREE_HEADER" then
            row:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.50)
        elseif entry.type == "EMPTY_NOTICE" then
            row:SetBackdropBorderColor(0.20, 0.18, 0.15, 0.15)
        else
            row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
        end
    else
        row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
    end
end

-- ----------------------------------------------------------------------------
-- 5d. PAINEL DE DETALHES & EVOLUÇÃO (FASE 4)
-- ----------------------------------------------------------------------------
function TrainerMenu:CreateDetailPanel(parent)
    local card = CreateFrame("Frame", "ConsoleMode_TrainerDetailPanel", parent)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -42)
    card:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
    card:Hide()

    -- 1. Cabeçalho da Habilidade: Ícone 48x48 + Título + Especialização + Requisitos
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(48)
    icon:SetHeight(48)
    icon:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
    card.icon = icon

    local iconBorder = CreateFrame("Frame", nil, card)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    iconBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    iconBorder:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.80)
    card.iconBorder = iconBorder

    -- Nome da Habilidade
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    titleText:SetPoint("RIGHT", card, "RIGHT", -4, 0)
    titleText:SetJustifyH("LEFT")
    self:ApplyFont(titleText, FONTS.titleBold, 18)
    card.titleText = titleText

    -- Subtítulo: Especialização • Nível • Custo
    local subText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -4)
    subText:SetPoint("RIGHT", card, "RIGHT", -4, 0)
    subText:SetJustifyH("LEFT")
    self:ApplyFont(subText, FONTS.medium, 13)
    card.subText = subText

    -- Badge de Status (ex: [NOVA HABILIDADE] / [UPGRADE DE GRAU] / [JÁ CONHECIDO])
    local badgeText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    badgeText:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -5)
    badgeText:SetPoint("RIGHT", card, "RIGHT", -4, 0)
    badgeText:SetJustifyH("LEFT")
    self:ApplyFont(badgeText, FONTS.bodyBold, 13)
    card.badgeText = badgeText

    -- Divisória abaixo do cabeçalho
    local hDiv = card:CreateTexture(nil, "ARTWORK")
    hDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    hDiv:SetHeight(2)
    hDiv:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -12)
    hDiv:SetPoint("RIGHT", card, "RIGHT", 0, 0)
    hDiv:SetVertexColor(0.5, 0.4, 0.28, 0.4)
    card.hDiv = hDiv

    -- 2. Card do Grau Atual no Grimório (se upgrade)
    local oldCard = CreateFrame("Frame", nil, card)
    oldCard:SetPoint("TOPLEFT", hDiv, "BOTTOMLEFT", 0, -8)
    oldCard:SetPoint("TOPRIGHT", hDiv, "BOTTOMRIGHT", 0, -8)
    oldCard:SetHeight(78)
    oldCard:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    oldCard:SetBackdropColor(0.06, 0.05, 0.04, 0.60)
    oldCard:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
    card.oldCard = oldCard

    local oldHeader = oldCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    oldHeader:SetPoint("TOPLEFT", oldCard, "TOPLEFT", 8, -6)
    self:ApplyFont(oldHeader, FONTS.bodyBold, 13)
    oldHeader:SetText("|cffaaaaaa[ATUALMENTE NO GRIMÓRIO]|r")
    oldCard.header = oldHeader

    local oldDesc = oldCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    oldDesc:SetPoint("TOPLEFT", oldHeader, "BOTTOMLEFT", 0, -4)
    oldDesc:SetPoint("BOTTOMRIGHT", oldCard, "BOTTOMRIGHT", -8, 6)
    oldDesc:SetJustifyH("LEFT")
    oldDesc:SetJustifyV("TOP")
    self:ApplyFont(oldDesc, FONTS.medium, 13)
    oldCard.desc = oldDesc

    -- Seta de Evolução
    local arrowText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrowText:SetPoint("TOP", oldCard, "BOTTOM", 0, -4)
    self:ApplyFont(arrowText, FONTS.titleBold, 13)
    arrowText:SetText("|cffe09a15▼ EVOLUÇÃO PARA O PRÓXIMO GRAU|r")
    card.arrowText = arrowText

    -- 3. Card do Novo Grau (Oferecido pelo Treinador)
    local newCard = CreateFrame("Frame", nil, card)
    newCard:SetPoint("TOPLEFT", oldCard, "BOTTOMLEFT", 0, -26)
    newCard:SetPoint("TOPRIGHT", oldCard, "BOTTOMRIGHT", 0, -26)
    newCard:SetHeight(86)
    newCard:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    newCard:SetBackdropColor(0.08, 0.07, 0.05, 0.75)
    newCard:SetBackdropBorderColor(0.55, 0.42, 0.22, 0.70)
    card.newCard = newCard

    local newHeader = newCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    newHeader:SetPoint("TOPLEFT", newCard, "TOPLEFT", 8, -6)
    self:ApplyFont(newHeader, FONTS.bodyBold, 13)
    newHeader:SetText("|cffe09a15[OFERECIDO PELO TREINADOR]|r")
    newCard.header = newHeader

    local newDesc = newCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newDesc:SetPoint("TOPLEFT", newHeader, "BOTTOMLEFT", 0, -4)
    newDesc:SetPoint("BOTTOMRIGHT", newCard, "BOTTOMRIGHT", -8, 6)
    newDesc:SetJustifyH("LEFT")
    newDesc:SetJustifyV("TOP")
    self:ApplyFont(newDesc, FONTS.medium, 13)
    newCard.desc = newDesc

    -- 4. Bloco Comparativo de Mudanças / Destaques
    local diffCard = CreateFrame("Frame", nil, card)
    diffCard:SetPoint("TOPLEFT", newCard, "BOTTOMLEFT", 0, -8)
    diffCard:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 4)
    diffCard:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    diffCard:SetBackdropColor(0.05, 0.04, 0.03, 0.60)
    diffCard:SetBackdropBorderColor(0.30, 0.25, 0.18, 0.40)
    card.diffCard = diffCard

    local diffHeader = diffCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    diffHeader:SetPoint("TOPLEFT", diffCard, "TOPLEFT", 8, -6)
    self:ApplyFont(diffHeader, FONTS.bodyBold, 13)
    diffHeader:SetText("|cffedd28cRESUMO & REQUISITOS:|r")
    diffCard.header = diffHeader

    local diffText = diffCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    diffText:SetPoint("TOPLEFT", diffHeader, "BOTTOMLEFT", 0, -4)
    diffText:SetPoint("BOTTOMRIGHT", diffCard, "BOTTOMRIGHT", -8, 6)
    diffText:SetJustifyH("LEFT")
    diffText:SetJustifyV("TOP")
    self:ApplyFont(diffText, FONTS.medium, 13)
    diffCard.text = diffText

    parent.detailCard = card
    self.detailCard = card
    return card
end

-- ----------------------------------------------------------------------------
-- 5e. CRIAÇÃO GERAL DA UI
-- ----------------------------------------------------------------------------
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

    -- Resumo do Carrinho no Cabeçalho (Botão Clicável)
    local cartSummaryBtn = CreateFrame("Button", "ConsoleMode_TrainerHeaderCartBtn", header)
    cartSummaryBtn:SetHeight(24)
    cartSummaryBtn:SetPoint("RIGHT", playerMoneyText, "LEFT", -20, 0)
    local cartSummaryText = cartSummaryBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cartSummaryText:SetPoint("RIGHT", cartSummaryBtn, "RIGHT", 0, 0)
    self:ApplyFont(cartSummaryText, FONTS.titleBold, 16)
    cartSummaryText:SetText("")
    header.cartSummaryText = cartSummaryText
    cartSummaryBtn:SetScript("OnClick", function()
        TrainerMenu:OnTriggerAction()
    end)

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

        local availCountText = colHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        availCountText:SetPoint("RIGHT", colHeader, "RIGHT", -6, 0)
        TrainerMenu:ApplyFont(availCountText, FONTS.medium, 14)
        availCountText:SetText("")
        col.availCountText = availCountText

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
    frame.leftCol = leftCol

    -- Barra de Busca
    self:CreateSearchBar(leftCol)

    -- Área interna da Lista de Habilidades com suporte a rolagem de mouse
    local listArea = CreateFrame("Frame", "ConsoleMode_TrainerListArea", leftCol)
    listArea:SetPoint("TOPLEFT", leftCol, "TOPLEFT", 8, -78)
    listArea:SetPoint("BOTTOMRIGHT", leftCol, "BOTTOMRIGHT", -8, 8)
    listArea:EnableMouseWheel(true)
    listArea:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            TrainerMenu:MoveSelection(-1)
        else
            TrainerMenu:MoveSelection(1)
        end
    end)
    leftCol.listArea = listArea

    -- Pool fixo de linhas
    self:CreateCatalogRows(listArea)

    -- Coluna Direita: Detalhes & Comparativo
    local rightCol = CreateColumnPanel("ConsoleMode_TrainerColRight", "DETALHES & EVOLUÇÃO DA HABILIDADE", ICONS.RB)
    rightCol:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", 0, 0)
    rightCol:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    rightCol:SetPoint("LEFT", divider, "RIGHT", 6, 0)
    rightCol.placeholder:SetText("|cffe09a15Selecione uma habilidade à esquerda para inspecionar.|r\n|cffaaaaaaUse o D-Pad ou clique do mouse para ver detalhes completos.|r")

    -- Cria o painel estruturado de detalhes
    self:CreateDetailPanel(rightCol)

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

    -- Ajusta quantidade de linhas visíveis conforme a altura disponível
    if self.frame.leftCol and self.frame.leftCol.listArea then
        local areaH = self.frame.leftCol.listArea:GetHeight()
        if areaH and areaH > 0 then
            local rowH = 42
            local gap  = 2
            local count = math.floor((areaH + gap) / (rowH + gap))
            if count < 6 then count = 6 end
            if count > 10 then count = 10 end
            self.visibleRowCount = count
        end
    end

    self:UpdateFooterHints()
    self:ScrollToSelection()
    self:UpdateCatalogRows()
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

    -- Total de disponíveis no catálogo
    local numAvail = table.getn(self.availableServices or {})
    if self.frame.leftCol and self.frame.leftCol.availCountText then
        if numAvail > 0 then
            self.frame.leftCol.availCountText:SetText("|cff1eff00(" .. numAvail .. " Disponíveis)|r")
        else
            self.frame.leftCol.availCountText:SetText("|cffaaaaaa(0 Disponíveis)|r")
        end
    end

    -- Resumo do Carrinho de Compras
    if self.frame.header and self.frame.header.cartSummaryText then
        local count = (self.GetCartCount and self:GetCartCount()) or 0
        if count > 0 then
            local totalCost = (self.GetCartTotalCost and self:GetCartTotalCost()) or 0
            self.frame.header.cartSummaryText:SetText("|cffe09a15Carrinho: " .. count .. " (" .. self:FormatMoneyText(totalCost) .. ")|r")
        else
            self.frame.header.cartSummaryText:SetText("")
        end
    end
end

-- ----------------------------------------------------------------------------
-- 6. SCANNER DO GRIMÓRIO DO JOGADOR (FASE 4: COMPARATIVO)
-- ----------------------------------------------------------------------------
function TrainerMenu:ScanSpellbook()
    local cache = {}
    if not GetSpellName then
        self.spellbookCache = cache
        return cache
    end

    local numTabs = 1
    if GetNumSpellTabs then
        numTabs = GetNumSpellTabs() or 1
    end

    for t = 1, numTabs do
        local tabName, _, offset, numSpells = nil, nil, 0, 0
        if GetSpellTabInfo then
            tabName, _, offset, numSpells = GetSpellTabInfo(t)
        end
        offset = offset or 0
        numSpells = numSpells or 0

        for s = (offset + 1), (offset + numSpells) do
            local spellName, spellRank = GetSpellName(s, BOOKTYPE_SPELL)
            if spellName and spellName ~= "" then
                -- Lê a descrição do feitiço no grimório via scanner tooltip
                local spellDesc = ""
                if trainerScanTip and trainerScanTip.SetSpell then
                    trainerScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
                    trainerScanTip:ClearLines()
                    pcall(function() trainerScanTip:SetSpell(s, BOOKTYPE_SPELL) end)
                    local nl = trainerScanTip:NumLines() or 0
                    local lines = {}
                    for l = 2, nl do
                        local txtObj = getglobal("ConsoleMode_TrainerScanTipTextLeft" .. l)
                        local rightObj = getglobal("ConsoleMode_TrainerScanTipTextRight" .. l)
                        local leftTxt = (txtObj and txtObj:GetText()) or ""
                        local rightTxt = (rightObj and rightObj:GetText()) or ""
                        if leftTxt ~= "" then
                            if rightTxt ~= "" then
                                table.insert(lines, leftTxt .. "  (" .. rightTxt .. ")")
                            else
                                table.insert(lines, leftTxt)
                            end
                        end
                    end
                    spellDesc = table.concat(lines, "\n")
                end

                local rankNum = 0
                if spellRank and spellRank ~= "" then
                    local _, _, r = string.find(spellRank, "(%d+)")
                    if r then rankNum = tonumber(r) or 0 end
                end

                local existing = cache[spellName]
                if not existing or rankNum >= existing.rankNum then
                    cache[spellName] = {
                        name     = spellName,
                        rankText = spellRank or "",
                        rankNum  = rankNum,
                        tabName  = tabName or "",
                        desc     = spellDesc,
                        spellId  = s,
                    }
                end
            end
        end
    end

    self.spellbookCache = cache
    return cache
end

-- ----------------------------------------------------------------------------
-- 6b. SCANNER DO TREINADOR, AGRUPAMENTO & LISTA UNIFICADA (FASE 3 & 4)
-- ----------------------------------------------------------------------------
function TrainerMenu:ScanTrainerServices()
    if self.isScanning then return end
    self.isScanning = true

    local numServices = 0
    if GetNumTrainerServices then
        numServices = GetNumTrainerServices() or 0
    end
    self.numServices = numServices

    local rawServices = {}
    local currentTree = "Geral"
    local treesOrder = {}
    local seenTrees = {}

    for i = 1, numServices do
        local serviceName, serviceSubText, serviceType, isExpanded = GetTrainerServiceInfo(i)
        if serviceName then
            if serviceType == "header" then
                currentTree = serviceName
                if not seenTrees[currentTree] then
                    seenTrees[currentTree] = true
                    table.insert(treesOrder, currentTree)
                end
            else
                local cost = 0
                if GetTrainerServiceCost then
                    local ok, val = pcall(function() return GetTrainerServiceCost(i) end)
                    if ok and type(val) == "number" then cost = val end
                end

                local icon = "Interface\\Icons\\INV_Misc_QuestionMark"
                if GetTrainerServiceIcon then
                    local ok, val = pcall(function() return GetTrainerServiceIcon(i) end)
                    if ok and type(val) == "string" and val ~= "" then icon = val end
                end

                local levelReq = 0
                if GetTrainerServiceLevelReq then
                    local ok, val = pcall(function() return GetTrainerServiceLevelReq(i) end)
                    if ok and type(val) == "number" then levelReq = val end
                end

                local desc = ""
                if GetTrainerServiceDescription then
                    local ok, val = pcall(function() return GetTrainerServiceDescription(i) end)
                    if ok and type(val) == "string" then desc = val end
                end

                local link = nil
                if GetTrainerServiceItemLink then
                    local ok, val = pcall(function() return GetTrainerServiceItemLink(i) end)
                    if ok and type(val) == "string" then link = val end
                end

                local item = {
                    index    = i,
                    name     = serviceName,
                    subText  = serviceSubText or "",
                    category = serviceType or "available", -- "available", "unavailable", "used"
                    cost     = cost,
                    icon     = icon,
                    levelReq = levelReq,
                    desc     = desc,
                    tree     = currentTree,
                    link     = link,
                }
                table.insert(rawServices, item)
            end
        end
    end

    self.rawServices = rawServices
    self.treesOrder = treesOrder

    self:ScanSpellbook()
    self:CategorizeServices()
    self:BuildFlattenedList()
    self:EnsureValidSelection()
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:RefreshHeader()

    self.isScanning = false
end

function TrainerMenu:CategorizeServices()
    local avail = {}
    local future = {}
    local used = {}

    local raw = self.rawServices or {}
    local n = table.getn(raw)
    for i = 1, n do
        local s = raw[i]
        if s.category == "available" then
            table.insert(avail, s)
        elseif s.category == "unavailable" then
            table.insert(future, s)
        elseif s.category == "used" then
            table.insert(used, s)
        end
    end

    self.availableServices = avail
    self.futureServices = future
    self.usedServices = used
end

function TrainerMenu:MatchesSearch(item, searchLower)
    if not searchLower or searchLower == "" then return true end
    if not item then return false end

    local name = string.lower(item.name or "")
    if string.find(name, searchLower, 1, true) then
        return true
    end

    local sub = string.lower(item.subText or "")
    if string.find(sub, searchLower, 1, true) then
        return true
    end

    local tree = string.lower(item.tree or "")
    if string.find(tree, searchLower, 1, true) then
        return true
    end

    return false
end

function TrainerMenu:BuildFlattenedList()
    local flat = {}
    local searchLower = nil
    if self.searchText and self.searchText ~= "" then
        searchLower = string.lower(string.gsub(self.searchText, "^%s*(.-)%s*$", "%1"))
        if searchLower == "" then searchLower = nil end
    end

    -- 1. Seção: DISPONÍVEIS PARA APRENDER
    local availFiltered = {}
    local numAvail = table.getn(self.availableServices or {})
    for i = 1, numAvail do
        local it = self.availableServices[i]
        if self:MatchesSearch(it, searchLower) then
            table.insert(availFiltered, it)
        end
    end

    table.insert(flat, {
        type = "SECTION_HEADER",
        id = "SECTION_AVAIL",
        text = "▼ DISPONÍVEIS PARA APRENDER (" .. table.getn(availFiltered) .. ")",
        count = table.getn(availFiltered),
        isInteractive = false,
    })

    local numAvailF = table.getn(availFiltered)
    if numAvailF > 0 then
        for i = 1, numAvailF do
            table.insert(flat, {
                type = "SERVICE_ITEM",
                item = availFiltered[i],
            })
        end
    else
        table.insert(flat, {
            type = "EMPTY_NOTICE",
            text = (searchLower and "Nenhuma disponível encontrada com o termo." or "Nenhuma habilidade disponível no momento."),
        })
    end

    -- 2. Seção: HABILIDADES FUTURAS (Colapsável por padrão, auto-expande na busca)
    local futureFiltered = {}
    local numFuture = table.getn(self.futureServices or {})
    for i = 1, numFuture do
        local it = self.futureServices[i]
        if self:MatchesSearch(it, searchLower) then
            table.insert(futureFiltered, it)
        end
    end

    local isFutureCol = self.isFutureCollapsed
    local futureLabel = ""
    if isFutureCol then
        futureLabel = "▶ HABILIDADES FUTURAS (" .. table.getn(futureFiltered) .. ")  |cffaaaaaa[A / Clique] Expandir|r"
    else
        futureLabel = "▼ HABILIDADES FUTURAS (" .. table.getn(futureFiltered) .. ")  |cffaaaaaa[A / Clique] Recolher|r"
    end

    table.insert(flat, {
        type = "SECTION_HEADER",
        id = "SECTION_FUTURE",
        text = futureLabel,
        count = table.getn(futureFiltered),
        isInteractive = true,
        isCollapsed = isFutureCol,
    })

    if not isFutureCol then
        local numFutureF = table.getn(futureFiltered)
        if numFutureF > 0 then
            local futureByTree = {}
            local order = {}
            local seen = {}

            local numKnownTrees = table.getn(self.treesOrder or {})
            for t = 1, numKnownTrees do
                local trName = self.treesOrder[t]
                if not seen[trName] then
                    seen[trName] = true
                    table.insert(order, trName)
                end
            end

            for i = 1, numFutureF do
                local it = futureFiltered[i]
                local tr = it.tree or "Geral"
                if not seen[tr] then
                    seen[tr] = true
                    table.insert(order, tr)
                end
                futureByTree[tr] = futureByTree[tr] or {}
                table.insert(futureByTree[tr], it)
            end

            local numOrder = table.getn(order)
            for t = 1, numOrder do
                local trName = order[t]
                local itemsInTree = futureByTree[trName]
                if itemsInTree and table.getn(itemsInTree) > 0 then
                    local treeKey = "FUTURE_" .. trName
                    local isTreeCollapsed = true
                    if self.collapsedTrees and self.collapsedTrees[treeKey] ~= nil then
                        isTreeCollapsed = self.collapsedTrees[treeKey]
                    end
                    local nTree = table.getn(itemsInTree)

                    local treeIcon = isTreeCollapsed and "▶ " or "▼ "
                    local treeHint = isTreeCollapsed and "  |cffaaaaaa[A] Expandir|r" or "  |cffaaaaaa[A] Recolher|r"

                    table.insert(flat, {
                        type = "TREE_HEADER",
                        id   = treeKey,
                        tree = trName,
                        section = "FUTURE",
                        text = treeIcon .. "Árvore: " .. trName .. " (" .. nTree .. ")" .. treeHint,
                        count = nTree,
                        isInteractive = true,
                        isCollapsed = isTreeCollapsed,
                    })

                    if not isTreeCollapsed then
                        for k = 1, nTree do
                            table.insert(flat, {
                                type = "SERVICE_ITEM",
                                item = itemsInTree[k],
                            })
                        end
                    end
                end
            end
        else
            table.insert(flat, {
                type = "EMPTY_NOTICE",
                text = (searchLower and "Nenhuma futura encontrada com o termo." or "Nenhuma habilidade futura."),
            })
        end
    end

    -- 3. Seção: JÁ APRENDIDAS (Colapsável por padrão, auto-expande na busca)
    local usedFiltered = {}
    local numUsed = table.getn(self.usedServices or {})
    for i = 1, numUsed do
        local it = self.usedServices[i]
        if self:MatchesSearch(it, searchLower) then
            table.insert(usedFiltered, it)
        end
    end

    local isCollapsed = self.isUsedCollapsed
    local usedLabel = ""
    if isCollapsed then
        usedLabel = "▶ JÁ APRENDIDAS (" .. table.getn(usedFiltered) .. ")  |cffaaaaaa[A / Clique] Expandir|r"
    else
        usedLabel = "▼ JÁ APRENDIDAS (" .. table.getn(usedFiltered) .. ")  |cffaaaaaa[A / Clique] Recolher|r"
    end

    table.insert(flat, {
        type = "SECTION_HEADER",
        id = "SECTION_USED",
        text = usedLabel,
        count = table.getn(usedFiltered),
        isInteractive = true,
        isCollapsed = isCollapsed,
    })

    if not isCollapsed then
        local numUsedF = table.getn(usedFiltered)
        if numUsedF > 0 then
            local usedByTree = {}
            local order = {}
            local seen = {}

            local numKnownTrees = table.getn(self.treesOrder or {})
            for t = 1, numKnownTrees do
                local trName = self.treesOrder[t]
                if not seen[trName] then
                    seen[trName] = true
                    table.insert(order, trName)
                end
            end

            for i = 1, numUsedF do
                local it = usedFiltered[i]
                local tr = it.tree or "Geral"
                if not seen[tr] then
                    seen[tr] = true
                    table.insert(order, tr)
                end
                usedByTree[tr] = usedByTree[tr] or {}
                table.insert(usedByTree[tr], it)
            end

            local numOrder = table.getn(order)
            for t = 1, numOrder do
                local trName = order[t]
                local itemsInTree = usedByTree[trName]
                if itemsInTree and table.getn(itemsInTree) > 0 then
                    local treeKey = "USED_" .. trName
                    local isTreeCollapsed = true
                    if self.collapsedTrees and self.collapsedTrees[treeKey] ~= nil then
                        isTreeCollapsed = self.collapsedTrees[treeKey]
                    end
                    local nTree = table.getn(itemsInTree)

                    local treeIcon = isTreeCollapsed and "▶ " or "▼ "
                    local treeHint = isTreeCollapsed and "  |cffaaaaaa[A] Expandir|r" or "  |cffaaaaaa[A] Recolher|r"

                    table.insert(flat, {
                        type = "TREE_HEADER",
                        id   = treeKey,
                        tree = trName,
                        section = "USED",
                        text = treeIcon .. "Árvore: " .. trName .. " (" .. nTree .. ")" .. treeHint,
                        count = nTree,
                        isInteractive = true,
                        isCollapsed = isTreeCollapsed,
                    })

                    if not isTreeCollapsed then
                        for k = 1, nTree do
                            table.insert(flat, {
                                type = "SERVICE_ITEM",
                                item = itemsInTree[k],
                            })
                        end
                    end
                end
            end
        else
            table.insert(flat, {
                type = "EMPTY_NOTICE",
                text = (searchLower and "Nenhuma aprendida encontrada com o termo." or "Nenhuma habilidade aprendida."),
            })
        end
    end

    self.flattenedList = flat
end

-- ----------------------------------------------------------------------------
-- 7. ATUALIZAÇÃO VISUAL DAS LINHAS DO CATÁLOGO & DETALHES
-- ----------------------------------------------------------------------------
function TrainerMenu:UpdateCatalogRows()
    if not self.frame or not self.catalogRows then return end

    local visibleCount = self.visibleRowCount or 8
    local flat = self.flattenedList or {}
    local offset = self.scrollOffset or 0

    if self.frame.leftCol and self.frame.leftCol.placeholder then
        if table.getn(flat) > 0 then
            self.frame.leftCol.placeholder:Hide()
        else
            self.frame.leftCol.placeholder:Show()
        end
    end

    local numRowsPool = table.getn(self.catalogRows)
    for i = 1, numRowsPool do
        local row = self.catalogRows[i]
        if i <= visibleCount then
            local flatIdx = offset + i
            local entry = flat[flatIdx]

            if entry then
                row:Show()
                row.flatIndex = flatIdx

                if entry.type == "SERVICE_ITEM" and entry.item then
                    local it = entry.item
                    row.headerText:Hide()

                    row.icon:Show()
                    row.iconBorder:Show()
                    row.nameText:Show()
                    row.subText:Show()
                    row.priceText:Show()

                    row.icon:SetTexture(it.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

                    local displayName = it.name
                    if it.subText and it.subText ~= "" then
                        displayName = displayName .. " (" .. it.subText .. ")"
                    end

                    local inCart = (it.category == "available") and self.IsItemInCart and self:IsItemInCart(it)
                    local checkMark = ""
                    if it.category == "available" then
                        checkMark = inCart and "|cff1eff00[✓] |r" or "|cff555555[ ] |r"
                    end

                    if it.category == "available" then
                        row.nameText:SetText(checkMark .. "|cffffffff" .. displayName .. "|r")
                        row.icon:SetVertexColor(1.0, 1.0, 1.0)
                    elseif it.category == "unavailable" then
                        row.nameText:SetText("|cffc0c0c0" .. displayName .. "|r")
                        row.icon:SetVertexColor(0.65, 0.65, 0.65)
                    else -- used
                        row.nameText:SetText("|cff888888" .. displayName .. "|r")
                        row.icon:SetVertexColor(0.50, 0.50, 0.50)
                    end

                    -- Subtítulo (Nível • Árvore)
                    local pLvl = UnitLevel("player") or 1
                    local subParts = {}
                    if it.category == "unavailable" then
                        local lvlColor = (it.levelReq and it.levelReq > pLvl) and "|cffff2020" or "|cffffffff"
                        if it.levelReq and it.levelReq > 0 then
                            table.insert(subParts, lvlColor .. "Requer Nv. " .. it.levelReq .. "|r")
                        end
                    else
                        if it.levelReq and it.levelReq > 0 then
                            table.insert(subParts, "Nv. " .. it.levelReq)
                        end
                    end
                    if it.tree and it.tree ~= "" then
                        table.insert(subParts, it.tree)
                    end
                    row.subText:SetText(table.concat(subParts, "  •  "))

                    -- Preço ou status
                    if it.category == "used" then
                        row.priceText:SetText("|cff888888Já Aprendido|r")
                    else
                        if it.cost and it.cost > 0 then
                            row.priceText:SetText(self:FormatMoneyText(it.cost))
                        else
                            row.priceText:SetText("|cff1eff00Grátis|r")
                        end
                    end

                    -- Estado Selecionado
                    local isSel = (not self.isSearchSelected) and (flatIdx == self.selectedIndex)
                    if isSel then
                        row.cursor:Show()
                        row.highlight:Show()
                        row:SetBackdropColor(0.20, 0.16, 0.10, 0.85)
                        row:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                    else
                        row.cursor:Hide()
                        row.highlight:Hide()
                        if inCart then
                            row:SetBackdropColor(0.10, 0.14, 0.08, 0.65)
                            row:SetBackdropBorderColor(0.25, 0.75, 0.35, 0.75)
                        else
                            row:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
                            row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
                        end
                    end

                elseif entry.type == "SECTION_HEADER" then
                    row.icon:Hide()
                    row.iconBorder:Hide()
                    row.nameText:Hide()
                    row.subText:Hide()
                    row.priceText:Hide()

                    row.headerText:Show()
                    self:ApplyFont(row.headerText, FONTS.titleBold, 15)
                    row.headerText:SetText("|cffe09a15" .. entry.text .. "|r")

                    local isSel = (not self.isSearchSelected) and (flatIdx == self.selectedIndex)
                    if isSel then
                        row.cursor:Show()
                        row.highlight:Show()
                        row:SetBackdropColor(0.25, 0.18, 0.08, 0.90)
                        row:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                    else
                        row.cursor:Hide()
                        row.highlight:Hide()
                        row:SetBackdropColor(0.16, 0.12, 0.07, 0.70)
                        row:SetBackdropBorderColor(0.55, 0.42, 0.22, 0.60)
                    end

                elseif entry.type == "TREE_HEADER" then
                    row.icon:Hide()
                    row.iconBorder:Hide()
                    row.nameText:Hide()
                    row.subText:Hide()
                    row.priceText:Hide()

                    row.headerText:Show()
                    self:ApplyFont(row.headerText, FONTS.titleBold, 14)
                    row.headerText:SetText("|cffedd28c" .. entry.text .. "|r")

                    local isSel = (not self.isSearchSelected) and (flatIdx == self.selectedIndex)
                    if isSel then
                        row.cursor:Show()
                        row.highlight:Show()
                        row:SetBackdropColor(0.20, 0.15, 0.08, 0.85)
                        row:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                    else
                        row.cursor:Hide()
                        row.highlight:Hide()
                        row:SetBackdropColor(0.12, 0.09, 0.06, 0.55)
                        row:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.50)
                    end

                elseif entry.type == "EMPTY_NOTICE" then
                    row.icon:Hide()
                    row.iconBorder:Hide()
                    row.nameText:Hide()
                    row.subText:Hide()
                    row.priceText:Hide()
                    row.cursor:Hide()
                    row.highlight:Hide()

                    row.headerText:Show()
                    self:ApplyFont(row.headerText, FONTS.medium, 13)
                    row.headerText:SetText("|cff777777  " .. entry.text .. "|r")

                    row:SetBackdropColor(0.04, 0.03, 0.02, 0.20)
                    row:SetBackdropBorderColor(0.20, 0.18, 0.15, 0.15)
                end
            else
                row:Hide()
                row.flatIndex = nil
            end
        else
            row:Hide()
            row.flatIndex = nil
        end
    end
end

-- ----------------------------------------------------------------------------
-- 7b. PROCESSAMENTO DE TOOLTIP, COMPARATIVO DE GRAU & DETALHES (FASE 4)
-- ----------------------------------------------------------------------------
function TrainerMenu:GetTrainerServiceTooltipData(serviceIndex)
    local data = {
        name     = "",
        stats    = {},
        desc     = "",
        reqs     = {},
        reagents = {},
    }

    if not serviceIndex or not trainerScanTip or not trainerScanTip.SetTrainerService then
        return data
    end

    trainerScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    trainerScanTip:ClearLines()
    local ok = pcall(function() trainerScanTip:SetTrainerService(serviceIndex) end)
    if not ok then return data end

    local nl = trainerScanTip:NumLines() or 0
    if nl == 0 then return data end

    local left1 = getglobal("ConsoleMode_TrainerScanTipTextLeft1")
    if left1 then data.name = left1:GetText() or "" end

    local inReagents = false
    local descLines = {}

    for l = 2, nl do
        local leftObj = getglobal("ConsoleMode_TrainerScanTipTextLeft" .. l)
        local rightObj = getglobal("ConsoleMode_TrainerScanTipTextRight" .. l)
        local leftTxt = (leftObj and leftObj:GetText()) or ""
        local rightTxt = (rightObj and rightObj:GetText()) or ""

        if leftTxt ~= "" then
            local r, g, b = 1, 1, 1
            if leftObj then r, g, b = leftObj:GetTextColor() end
            local isRed = (r and r > 0.8 and g and g < 0.35 and b and b < 0.35)

            if string.find(leftTxt, "Reagent") or string.find(leftTxt, "Reagente") then
                inReagents = true
            elseif inReagents then
                if string.find(leftTxt, "^Requer") or string.find(leftTxt, "^Requires") then
                    inReagents = false
                    table.insert(data.reqs, { text = leftTxt, isRed = isRed })
                else
                    table.insert(data.reagents, leftTxt)
                end
            elseif string.find(leftTxt, "^Requer") or string.find(leftTxt, "^Requires") then
                table.insert(data.reqs, { text = leftTxt, isRed = isRed })
            elseif string.find(leftTxt, "Mana") or string.find(leftTxt, "Raiva") or string.find(leftTxt, "Energia")
                or string.find(leftTxt, "Rage") or string.find(leftTxt, "Energy")
                or string.find(leftTxt, "alcance") or string.find(leftTxt, "range")
                or string.find(leftTxt, "lançamento") or string.find(leftTxt, "cast")
                or string.find(leftTxt, "Instant") or string.find(leftTxt, "recarga")
                or string.find(leftTxt, "cooldown") then
                local statLine = leftTxt
                if rightTxt ~= "" then
                    statLine = statLine .. "  (" .. rightTxt .. ")"
                end
                table.insert(data.stats, statLine)
            else
                table.insert(descLines, leftTxt)
            end
        end
    end

    data.desc = table.concat(descLines, "\n")
    return data
end

function TrainerMenu:ComputeDiffLines(oldDesc, newDesc)
    local diffs = {}
    if not oldDesc or not newDesc or oldDesc == "" or newDesc == "" then
        return diffs
    end

    local function ExtractNumbers(str)
        local nums = {}
        local pos = 1
        while true do
            local s, e, nStr = string.find(str, "(%d+)", pos)
            if not s then break end
            table.insert(nums, tonumber(nStr))
            pos = e + 1
        end
        return nums
    end

    local oldNums = ExtractNumbers(oldDesc)
    local newNums = ExtractNumbers(newDesc)

    local count = math.min(table.getn(oldNums), table.getn(newNums))
    for i = 1, count do
        local oldV = oldNums[i]
        local newV = newNums[i]
        if newV > oldV then
            local diff = newV - oldV
            local context = "no Efeito da Habilidade"
            local lowerNew = string.lower(newDesc)
            if string.find(lowerNew, "dano") or string.find(lowerNew, "damage") then
                context = "de Dano Adicional"
            elseif string.find(lowerNew, "cura") or string.find(lowerNew, "heal") then
                context = "de Cura Adicional"
            elseif string.find(lowerNew, "armadura") or string.find(lowerNew, "armor") then
                context = "de Armadura"
            elseif string.find(lowerNew, "vida") or string.find(lowerNew, "health") then
                context = "de Vida Adicional"
            elseif string.find(lowerNew, "mana") then
                context = "de Restauração de Mana"
            end
            table.insert(diffs, "|cff1eff00▲ +" .. diff .. " " .. context .. " (" .. oldV .. " ➔ " .. newV .. ")|r")
        end
    end

    return diffs
end

function TrainerMenu:ShowServiceDetail(item)
    if not self.frame or not self.detailCard or not item then return end
    local card = self.detailCard

    -- 1. Ícone da Habilidade
    card.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    if item.category == "available" then
        card.icon:SetVertexColor(1.0, 1.0, 1.0)
        card.iconBorder:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.85)
    elseif item.category == "unavailable" then
        card.icon:SetVertexColor(0.70, 0.70, 0.70)
        card.iconBorder:SetBackdropBorderColor(0.60, 0.25, 0.25, 0.70)
    else -- used
        card.icon:SetVertexColor(0.50, 0.50, 0.50)
        card.iconBorder:SetBackdropBorderColor(0.40, 0.40, 0.40, 0.60)
    end

    -- 2. Título (Nome e Grau se houver)
    local displayName = item.name or "Habilidade"
    if item.subText and item.subText ~= "" then
        displayName = displayName .. " (" .. item.subText .. ")"
    end
    card.titleText:SetText(displayName)

    -- 3. Subtítulo (Especialização • Nível • Custo)
    local subParts = {}
    if item.tree and item.tree ~= "" then
        table.insert(subParts, item.tree)
    end
    if item.levelReq and item.levelReq > 0 then
        local pLvl = UnitLevel("player") or 1
        local col = (pLvl >= item.levelReq) and "|cffffffff" or "|cffff2020"
        table.insert(subParts, col .. "Requer Nv. " .. item.levelReq .. "|r")
    end
    if item.category == "used" then
        table.insert(subParts, "|cff888888Já Aprendido|r")
    else
        table.insert(subParts, "Custo: " .. self:FormatMoneyText(item.cost or 0))
    end
    card.subText:SetText(table.concat(subParts, "  •  "))

    -- 4. Tooltip Scan dos dados do treinador
    local tipData = self:GetTrainerServiceTooltipData(item.index)
    local fullNewDesc = ""
    if table.getn(tipData.stats) > 0 then
        fullNewDesc = "|cff88ccff" .. table.concat(tipData.stats, "   •   ") .. "|r\n\n"
    end
    if tipData.desc ~= "" then
        fullNewDesc = fullNewDesc .. tipData.desc
    elseif item.desc and item.desc ~= "" then
        fullNewDesc = fullNewDesc .. item.desc
    else
        fullNewDesc = fullNewDesc .. "Nenhuma descrição fornecida pelo treinador."
    end

    -- 5. Checa Grimório do jogador
    local known = self.spellbookCache and self.spellbookCache[item.name]
    local newRankNum = 0
    if item.subText and item.subText ~= "" then
        local _, _, r = string.find(item.subText, "(%d+)")
        if r then newRankNum = tonumber(r) or 0 end
    end
    local knownRankNum = (known and known.rankNum) or 0

    local isUsed = (item.category == "used") or (known ~= nil and knownRankNum >= newRankNum and newRankNum > 0 and item.category ~= "available")
    local isUpgrade = false

    if not isUsed and known ~= nil then
        if newRankNum > knownRankNum or (newRankNum == 0 and knownRankNum == 0) then
            isUpgrade = true
        end
    end

    local playerMoney = GetMoney() or 0
    local cost = item.cost or 0
    local pLvl = UnitLevel("player") or 1

    if isUsed then
        -- MODO 1: JÁ APRENDIDA
        card.badgeText:SetText("|cff888888✓ HABILIDADE JÁ CONHECIDA NO GRIMÓRIO|r")

        card.oldCard:Hide()
        card.arrowText:Hide()

        card.newCard:ClearAllPoints()
        card.newCard:SetPoint("TOPLEFT", card.hDiv, "BOTTOMLEFT", 0, -6)
        card.newCard:SetPoint("TOPRIGHT", card.hDiv, "BOTTOMRIGHT", 0, -6)
        card.newCard:SetHeight(108)
        card.newCard:Show()

        card.newCard.header:SetText("|cff888888[GRAU CONHECIDO: " .. (item.subText ~= "" and item.subText or "Aprendido") .. "]|r")
        card.newCard.desc:SetText(fullNewDesc)

        card.diffCard:ClearAllPoints()
        card.diffCard:SetPoint("TOPLEFT", card.newCard, "BOTTOMLEFT", 0, -8)
        card.diffCard:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 4)
        card.diffCard:Show()

        card.diffCard.header:SetText("|cffaaaaaaSTATUS NO GRIMÓRIO:|r")
        local statusLines = {
            "|cff888888Esta habilidade já foi aprendida e está pronta para uso no seu Grimório.|r",
            "",
            "• Especialização: |cffffffff" .. (item.tree or "Geral") .. "|r",
            "• Grau no Grimório: |cffffffff" .. ((known and known.rankText ~= "") and known.rankText or (item.subText ~= "" and item.subText or "Máximo Aprendido")) .. "|r",
            "• Atalho: Pressione '|cffe09a15P|r' fora deste menu para abrir seu grimório.",
        }
        card.diffCard.text:SetText(table.concat(statusLines, "\n"))

    elseif isUpgrade then
        -- MODO 2: UPGRADE / EVOLUÇÃO DE GRAU
        local oldRankLabel = (known and known.rankText ~= "") and known.rankText or "Grau Atual"
        local newRankLabel = (item.subText ~= "") and item.subText or "Novo Grau"
        card.badgeText:SetText("|cffe09a15▲ EVOLUÇÃO DISPONÍVEL (" .. oldRankLabel .. " ➔ " .. newRankLabel .. ")|r")

        card.oldCard:ClearAllPoints()
        card.oldCard:SetPoint("TOPLEFT", card.hDiv, "BOTTOMLEFT", 0, -6)
        card.oldCard:SetPoint("TOPRIGHT", card.hDiv, "BOTTOMRIGHT", 0, -6)
        card.oldCard:SetHeight(76)
        card.oldCard:Show()

        card.oldCard.header:SetText("|cffaaaaaa[ATUALMENTE NO GRIMÓRIO: " .. oldRankLabel .. "]|r")
        card.oldCard.desc:SetText(known and known.desc ~= "" and known.desc or "Descrição não disponível no grimório.")

        card.arrowText:ClearAllPoints()
        card.arrowText:SetPoint("TOP", card.oldCard, "BOTTOM", 0, -4)
        card.arrowText:Show()

        card.newCard:ClearAllPoints()
        card.newCard:SetPoint("TOPLEFT", card.oldCard, "BOTTOMLEFT", 0, -26)
        card.newCard:SetPoint("TOPRIGHT", card.oldCard, "BOTTOMRIGHT", 0, -26)
        card.newCard:SetHeight(84)
        card.newCard:Show()

        card.newCard.header:SetText("|cffe09a15[NOVO GRAU: " .. newRankLabel .. "]|r")
        card.newCard.desc:SetText(fullNewDesc)

        card.diffCard:ClearAllPoints()
        card.diffCard:SetPoint("TOPLEFT", card.newCard, "BOTTOMLEFT", 0, -8)
        card.diffCard:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 4)
        card.diffCard:Show()

        card.diffCard.header:SetText("|cff1eff00MUDANÇAS & DESTAQUES:|r")

        local diffLines = self:ComputeDiffLines(known and known.desc, fullNewDesc)
        local summary = {}

        if table.getn(diffLines) > 0 then
            for d = 1, table.getn(diffLines) do
                table.insert(summary, diffLines[d])
            end
        else
            table.insert(summary, "|cffe09a15• Aumenta a eficácia e o poder geral da habilidade.|r")
        end

        table.insert(summary, "")
        table.insert(summary, "|cffedd28cRESUMO FINANCEIRO & REQUISITOS:|r")
        if cost > 0 then
            table.insert(summary, "• Custo do Treinamento: " .. self:FormatMoneyText(cost))
            if playerMoney >= cost then
                table.insert(summary, "• Saldo Restante: |cff1eff00" .. self:FormatMoneyText(playerMoney - cost) .. "|r")
            else
                table.insert(summary, "• |cffff2020Saldo Insuficiente! Faltam " .. self:FormatMoneyText(cost - playerMoney) .. "|r")
            end
        else
            table.insert(summary, "• Custo do Treinamento: |cff1eff00Grátis|r")
        end

        if item.levelReq and item.levelReq > 0 then
            if pLvl >= item.levelReq then
                table.insert(summary, "• Nível Requerido: " .. item.levelReq .. " (|cff1eff00Atendido|r)")
            else
                table.insert(summary, "• Nível Requerido: " .. item.levelReq .. " (|cffff2020Faltam " .. (item.levelReq - pLvl) .. " níveis|r)")
            end
        end

        if table.getn(tipData.reqs) > 0 then
            for r = 1, table.getn(tipData.reqs) do
                local req = tipData.reqs[r]
                if not string.find(req.text, "Nível") and not string.find(req.text, "Level") then
                    local c = req.isRed and "|cffff2020" or "|cffaaaaaa"
                    table.insert(summary, "• " .. c .. req.text .. "|r")
                end
            end
        end

        card.diffCard.text:SetText(table.concat(summary, "\n"))

    else
        -- MODO 3: NOVA HABILIDADE / RECEITA
        local badge = (self.trainerType == "tradeskill") and "|cff1eff00★ NOVA RECEITA DE PROFISSÃO ★|r" or "|cff1eff00★ NOVA HABILIDADE DE CLASSE ★|r"
        card.badgeText:SetText(badge)

        card.oldCard:Hide()
        card.arrowText:Hide()

        card.newCard:ClearAllPoints()
        card.newCard:SetPoint("TOPLEFT", card.hDiv, "BOTTOMLEFT", 0, -6)
        card.newCard:SetPoint("TOPRIGHT", card.hDiv, "BOTTOMRIGHT", 0, -6)
        card.newCard:SetHeight(108)
        card.newCard:Show()

        card.newCard.header:SetText("|cffe09a15[OFERECIDO PELO TREINADOR]|r")
        card.newCard.desc:SetText(fullNewDesc)

        card.diffCard:ClearAllPoints()
        card.diffCard:SetPoint("TOPLEFT", card.newCard, "BOTTOMLEFT", 0, -8)
        card.diffCard:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", 0, 4)
        card.diffCard:Show()

        card.diffCard.header:SetText("|cffedd28cDETALHES & REQUISITOS:|r")

        local summary = {}
        if self.trainerType == "tradeskill" and table.getn(tipData.reagents) > 0 then
            table.insert(summary, "|cffedd28cReagentes de Criação:|r")
            for rg = 1, table.getn(tipData.reagents) do
                table.insert(summary, "  • |cffffffff" .. tipData.reagents[rg] .. "|r")
            end
            table.insert(summary, "")
        end

        if cost > 0 then
            table.insert(summary, "• Custo do Treinamento: " .. self:FormatMoneyText(cost))
            if playerMoney >= cost then
                table.insert(summary, "• Saldo Restante: |cff1eff00" .. self:FormatMoneyText(playerMoney - cost) .. "|r")
            else
                table.insert(summary, "• |cffff2020Saldo Insuficiente! Faltam " .. self:FormatMoneyText(cost - playerMoney) .. "|r")
            end
        else
            table.insert(summary, "• Custo do Treinamento: |cff1eff00Grátis|r")
        end

        if item.levelReq and item.levelReq > 0 then
            if pLvl >= item.levelReq then
                table.insert(summary, "• Nível Requerido: " .. item.levelReq .. " (|cff1eff00Atendido|r)")
            else
                table.insert(summary, "• Nível Requerido: " .. item.levelReq .. " (|cffff2020Faltam " .. (item.levelReq - pLvl) .. " níveis|r)")
            end
        end

        if table.getn(tipData.reqs) > 0 then
            for r = 1, table.getn(tipData.reqs) do
                local req = tipData.reqs[r]
                if not string.find(req.text, "Nível") and not string.find(req.text, "Level") then
                    local c = req.isRed and "|cffff2020" or "|cffaaaaaa"
                    table.insert(summary, "• " .. c .. req.text .. "|r")
                end
            end
        end

        if table.getn(summary) == 0 then
            table.insert(summary, "• Nenhum requisito especial para aprender.")
        end

        card.diffCard.text:SetText(table.concat(summary, "\n"))
    end
end

function TrainerMenu:SelectSearchBar()
    self.isSearchSelected = true
    if self.searchContainer then
        self.searchContainer:SetBackdropBorderColor(1.0, 0.82, 0.20, 1.0)
        if self.searchContainer.highlight then
            self.searchContainer.highlight:Show()
        end
    end
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:UpdateFooterHints()
end

function TrainerMenu:DeselectSearchBar()
    if not self.isSearchSelected then return end
    self.isSearchSelected = false
    if self.searchContainer then
        self.searchContainer:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.70)
        if self.searchContainer.highlight then
            self.searchContainer.highlight:Hide()
        end
    end
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:UpdateFooterHints()
end

function TrainerMenu:UpdateRightCol()
    if not self.frame or not self.frame.rightCol then return end

    if self.isSearchSelected then
        if self.detailCard then
            self.detailCard:Hide()
        end
        if self.frame.rightCol.placeholder then
            self.frame.rightCol.placeholder:Show()
            self.frame.rightCol.placeholder:SetText("|cffe09a15BARRA DE BUSCA SELECIONADA|r\n\n|cffccccccFiltre habilidades por nome, grau ou especialização.|r\n|cffaaaaaaPressione [A] ou clique para abrir o Teclado Virtual.|r")
        end
        return
    end

    local entry = self.flattenedList and self.flattenedList[self.selectedIndex]
    if entry and entry.type == "SERVICE_ITEM" and entry.item then
        if self.frame.rightCol.placeholder then
            self.frame.rightCol.placeholder:Hide()
        end
        if self.detailCard then
            self.detailCard:Show()
            self:ShowServiceDetail(entry.item)
        end
    else
        if self.detailCard then
            self.detailCard:Hide()
        end
        if self.frame.rightCol.placeholder then
            self.frame.rightCol.placeholder:Show()
            if entry and entry.type == "SECTION_HEADER" then
                local act = entry.isCollapsed and "Expandir" or "Recolher"
                self.frame.rightCol.placeholder:SetText("|cffe09a15" .. entry.text .. "|r\n\n|cffccccccSeção do catálogo de treinamento.|r\n|cffaaaaaaPressione [A] ou clique para " .. act .. " esta seção.|r")
            elseif entry and entry.type == "TREE_HEADER" then
                local act = entry.isCollapsed and "Expandir" or "Recolher"
                self.frame.rightCol.placeholder:SetText("|cffedd28cÁrvore: " .. (entry.tree or "") .. "|r\n\n|cffccccccEspecialização de classe com " .. (entry.count or 0) .. " habilidades.|r\n|cffaaaaaaPressione [A] ou clique para " .. act .. " esta árvore.|r")
            elseif entry and entry.type == "EMPTY_NOTICE" then
                self.frame.rightCol.placeholder:SetText("|cffaaaaaa" .. entry.text .. "|r")
            else
                self.frame.rightCol.placeholder:SetText("|cffe09a15Selecione uma habilidade à esquerda para inspecionar.|r\n|cffaaaaaaUse o D-Pad ou clique do mouse para ver detalhes completos.|r")
            end
        end
    end
end

function TrainerMenu:UpdateRightColPlaceholder()
    self:UpdateRightCol()
end

-- ----------------------------------------------------------------------------
-- 8. NAVEGAÇÃO POR GAMEPAD, D-PAD, HOLD-TO-REPEAT & SELEÇÃO
-- ----------------------------------------------------------------------------
function TrainerMenu:IsEntrySelectable(entry)
    if not entry then return false end
    if entry.type == "SERVICE_ITEM" then return true end
    if entry.id == "SECTION_USED" then return true end
    if entry.id == "SECTION_FUTURE" then return true end
    if entry.type == "TREE_HEADER" then return true end
    return false
end

function TrainerMenu:EnsureValidSelection()
    local flat = self.flattenedList or {}
    local total = table.getn(flat)
    if total == 0 then
        self.selectedIndex = 1
        return
    end

    local cur = flat[self.selectedIndex]
    if cur and self:IsEntrySelectable(cur) then
        return
    end

    for i = 1, total do
        if self:IsEntrySelectable(flat[i]) then
            self.selectedIndex = i
            return
        end
    end

    self.selectedIndex = 1
end

function TrainerMenu:MoveSelection(delta)
    local flat = self.flattenedList or {}
    local total = table.getn(flat)

    if self.isSearchSelected then
        if delta > 0 then
            -- D-Pad DOWN: Sai da barra de busca e entra na lista de habilidades
            self:DeselectSearchBar()
            self:EnsureValidSelection()
            self:ScrollToSelection()
            PlaySound("igMainMenuOptionCheckBoxOn")
            return
        end
        return
    end

    if total == 0 then
        if delta < 0 then
            PlaySound("igMainMenuOptionCheckBoxOn")
            self:SelectSearchBar()
        end
        return
    end

    local cur = self.selectedIndex or 1
    local step = (delta > 0) and 1 or -1
    local nextIdx = cur + step

    -- Se o jogador está no topo da lista e aperta D-Pad UP: foca a barra de pesquisa!
    if delta < 0 and nextIdx < 1 then
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:SelectSearchBar()
        return
    end

    local found = false
    while nextIdx >= 1 and nextIdx <= total do
        if self:IsEntrySelectable(flat[nextIdx]) then
            self.selectedIndex = nextIdx
            PlaySound("igMainMenuOptionCheckBoxOn")
            self:ScrollToSelection()
            self:UpdateCatalogRows()
            self:UpdateRightColPlaceholder()
            self:UpdateFooterHints()
            found = true
            return
        end
        nextIdx = nextIdx + step
    end

    -- Se subiu por cima de itens não selecionáveis e passou do topo:
    if not found and delta < 0 and nextIdx < 1 then
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:SelectSearchBar()
        return
    end
end

function TrainerMenu:ScrollToSelection()
    local visibleCount = self.visibleRowCount or 8
    local total = table.getn(self.flattenedList or {})
    if total <= visibleCount then
        self.scrollOffset = 0
        return
    end

    local sel = self.selectedIndex or 1
    local offset = self.scrollOffset or 0

    if sel <= offset then
        offset = sel - 1
    elseif sel > (offset + visibleCount) then
        offset = sel - visibleCount
    end

    if offset < 0 then offset = 0 end
    local maxOffset = math.max(0, total - visibleCount)
    if offset > maxOffset then offset = maxOffset end

    self.scrollOffset = offset
end

function TrainerMenu:SelectIndex(flatIndex)
    if not flatIndex then return end
    local entry = self.flattenedList and self.flattenedList[flatIndex]
    if not entry or not self:IsEntrySelectable(entry) then return end

    self:DeselectSearchBar()
    self.selectedIndex = flatIndex
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:ScrollToSelection()
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:UpdateFooterHints()
end

function TrainerMenu:OnRowClick(flatIndex)
    if not flatIndex then return end
    self:DeselectSearchBar()
    local entry = self.flattenedList and self.flattenedList[flatIndex]
    if not entry then return end

    if entry.id == "SECTION_USED" then
        self.selectedIndex = flatIndex
        self:ToggleUsedSection()
    elseif entry.id == "SECTION_FUTURE" then
        self.selectedIndex = flatIndex
        self:ToggleFutureSection()
    elseif entry.type == "TREE_HEADER" then
        self.selectedIndex = flatIndex
        self:ToggleTree(entry.id)
    elseif entry.type == "SERVICE_ITEM" then
        local now = GetTime()
        local isDbl = (this and this.lastClickTime and (now - this.lastClickTime) < 0.35)
        if this then this.lastClickTime = now end

        self:SelectIndex(flatIndex)
        if entry.item and entry.item.category == "available" then
            if isDbl then
                if not self:IsItemInCart(entry.item) then
                    self:ToggleCartItem(entry.item)
                end
                self:OpenCartModal()
            else
                self:ToggleCartItem(entry.item)
            end
        end
    end
end

function TrainerMenu:ToggleUsedSection()
    self.isUsedCollapsed = not self.isUsedCollapsed
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:BuildFlattenedList()
    self:EnsureValidSelection()
    self:ScrollToSelection()
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:UpdateFooterHints()
end

function TrainerMenu:ToggleFutureSection()
    self.isFutureCollapsed = not self.isFutureCollapsed
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:BuildFlattenedList()
    self:EnsureValidSelection()
    self:ScrollToSelection()
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:UpdateFooterHints()
end

function TrainerMenu:ToggleTree(treeKey)
    if not treeKey then return end
    self.collapsedTrees = self.collapsedTrees or {}
    local curState = true
    if self.collapsedTrees[treeKey] ~= nil then
        curState = self.collapsedTrees[treeKey]
    end
    self.collapsedTrees[treeKey] = not curState
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:BuildFlattenedList()
    self:EnsureValidSelection()
    self:ScrollToSelection()
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:UpdateFooterHints()
end

-- Roteamento de Direcionais com Hold-to-Repeat contínuo
function TrainerMenu:OnDirection(direction)
    if not self.isOpen then return end
    if self:IsCartModalOpen() then
        if direction == "UP" then
            self:MoveCartSelection(-1)
        elseif direction == "DOWN" then
            self:MoveCartSelection(1)
        end
        return
    end

    if direction == "UP" then
        self:MoveSelection(-1)
    elseif direction == "DOWN" then
        self:MoveSelection(1)
    end
end

function TrainerMenu:StartRepeat(direction)
    if not self.isOpen then return end
    if direction == "UP" or direction == "DOWN" then
        self:OnDirection(direction)
        self.repeatState.direction = direction
        self.repeatState.timer = self.repeatState.initialDelay
        self:EnsureRepeatTicker()
    else
        self.repeatState.direction = nil
        self.repeatState.timer = 0
        self:OnDirection(direction)
    end
end

function TrainerMenu:StopRepeat(direction)
    if not direction or self.repeatState.direction == direction then
        self.repeatState.direction = nil
        self.repeatState.timer = 0
    end
end

function TrainerMenu:EnsureRepeatTicker()
    if self.repeatFrame then return end
    local f = CreateFrame("Frame", "ConsoleMode_TrainerRepeatTicker")
    f:SetScript("OnUpdate", function(a1, a2)
        if not TrainerMenu.isOpen then
            TrainerMenu.repeatState.direction = nil
            return
        end
        local dir = TrainerMenu.repeatState.direction
        if dir then
            local dt = (type(a2) == "number" and a2) or (type(a1) == "number" and a1) or (type(arg1) == "number" and arg1) or 0.016
            TrainerMenu.repeatState.timer = TrainerMenu.repeatState.timer - dt
            if TrainerMenu.repeatState.timer <= 0 then
                TrainerMenu:OnDirection(dir)
                TrainerMenu.repeatState.timer = TrainerMenu.repeatState.interval
            end
        end
    end)
    self.repeatFrame = f
end

-- Botão A no controle: Confirma no Modal, Abre VK na Busca, Alterna Seções/Árvores ou Marca Habilidade
function TrainerMenu:OnConfirm()
    if not self.isOpen then return end
    if self:IsCartModalOpen() then
        self:ConfirmCartPurchase()
        return
    end

    if self.isSearchSelected then
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:OpenSearchVK()
        return
    end

    local entry = self.flattenedList and self.flattenedList[self.selectedIndex]
    if not entry then return end

    if entry.id == "SECTION_USED" then
        self:ToggleUsedSection()
    elseif entry.id == "SECTION_FUTURE" then
        self:ToggleFutureSection()
    elseif entry.type == "TREE_HEADER" then
        self:ToggleTree(entry.id)
    elseif entry.type == "SERVICE_ITEM" then
        if entry.item and entry.item.category == "available" then
            self:ToggleCartItem(entry.item)
        else
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
    end
end

-- Botão X no controle: Limpa a busca ou Remove item do Carrinho
function TrainerMenu:OnSecondaryAction()
    if not self.isOpen then return end
    if self:IsCartModalOpen() then
        self:RemoveCurrentCartItem()
        return
    end

    if self.searchText and self.searchText ~= "" then
        self:ClearSearch()
        PlaySound("igMainMenuOptionCheckBoxOff")
    end
end

-- Botão Y no controle: Alterna seleção de todas as disponíveis
function TrainerMenu:OnContextAction()
    if not self.isOpen then return end
    if self:IsCartModalOpen() then return end
    self:SelectAllAvailable()
end

-- Botão RT no controle: Alterna Modal do Carrinho de Compras
function TrainerMenu:OnTriggerAction()
    if not self.isOpen then return end
    if self:IsCartModalOpen() then
        self:CloseCartModal()
    else
        self:OpenCartModal()
    end
end

-- ----------------------------------------------------------------------------
-- 9. BUSCA EM TEMPO REAL & INTEGRAÇÃO COM VIRTUALKEYBOARD
-- ----------------------------------------------------------------------------
function TrainerMenu:SetSearchFilter(text)
    text = text or ""
    self.searchText = text

    if self.searchEditBox and self.searchEditBox:GetText() ~= text then
        self.searchEditBox:SetText(text)
    end

    if self.searchPlaceholder then
        if text == "" then
            self.searchPlaceholder:Show()
        else
            self.searchPlaceholder:Hide()
        end
    end

    if self.searchClearBtn then
        if text == "" then
            self.searchClearBtn:Hide()
        else
            self.searchClearBtn:Show()
        end
    end

    -- Ao digitar qualquer termo na busca, auto-expande as seções e árvores
    local trimmed = string.gsub(text, "^%s*(.-)%s*$", "%1")
    if trimmed ~= "" then
        self.isFutureCollapsed = false
        self.isUsedCollapsed   = false
        self.collapsedTrees    = {}
        -- Marca árvores como expandidas na busca
        local numKnown = table.getn(self.treesOrder or {})
        for t = 1, numKnown do
            local tr = self.treesOrder[t]
            self.collapsedTrees["FUTURE_" .. tr] = false
            self.collapsedTrees["USED_" .. tr]   = false
        end
    else
        self.isFutureCollapsed = true
        self.isUsedCollapsed   = true
        self.collapsedTrees    = {}
    end

    self:BuildFlattenedList()
    self:EnsureValidSelection()
    self:ScrollToSelection()
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:UpdateFooterHints()
end

function TrainerMenu:ClearSearch()
    if self.searchEditBox then
        self.searchEditBox:SetText("")
    end
    self:SetSearchFilter("")
end

function TrainerMenu:OpenSearchVK()
    if not self.isOpen then return end
    local vk = ConsoleMode and ConsoleMode.VirtualKeyboard
    if vk and vk.Open then
        vk:Open({
            title         = "Buscar Habilidade",
            initialText   = self.searchText or "",
            maxLetters    = 24,
            targetEditBox = self.searchEditBox,
            onConfirm     = function(text)
                TrainerMenu:SetSearchFilter(text)
            end,
            onCancel      = function() end,
        })
    end
end

-- ----------------------------------------------------------------------------
-- 9b. SISTEMA DE SELEÇÃO MÚLTIPLA & CARRINHO DE COMPRAS (FASE 5)
-- ----------------------------------------------------------------------------
function TrainerMenu:GetItemCartKey(item)
    if not item then return "" end
    return tostring(item.name or "") .. "__" .. tostring(item.subText or "")
end

function TrainerMenu:IsItemInCart(item)
    if not item then return false end
    local key = self:GetItemCartKey(item)
    return (self.cartKeys and self.cartKeys[key] == true)
end

function TrainerMenu:GetCartCount()
    return table.getn(self.cartItems or {})
end

function TrainerMenu:GetCartTotalCost()
    local total = 0
    local items = self.cartItems or {}
    local n = table.getn(items)
    for i = 1, n do
        local it = items[i]
        if it and it.cost then
            total = total + it.cost
        end
    end
    return total
end

function TrainerMenu:ToggleCartItem(item)
    if not item or item.category ~= "available" then return end
    local key = self:GetItemCartKey(item)

    if self.cartKeys[key] then
        self.cartKeys[key] = nil
        local newItems = {}
        local n = table.getn(self.cartItems)
        for i = 1, n do
            local it = self.cartItems[i]
            if self:GetItemCartKey(it) ~= key then
                table.insert(newItems, it)
            end
        end
        self.cartItems = newItems
        PlaySound("igMainMenuOptionCheckBoxOff")
    else
        self.cartKeys[key] = true
        table.insert(self.cartItems, item)
        PlaySound("igMainMenuOptionCheckBoxOn")
    end

    self:UpdateCartVisuals()
end

function TrainerMenu:SelectAllAvailable()
    local avail = self.availableServices or {}
    local numAvail = table.getn(avail)
    if numAvail == 0 then return end

    local currentCount = self:GetCartCount()
    if currentCount >= numAvail then
        -- Desmarca todas
        self:ClearCart()
        PlaySound("igMainMenuOptionCheckBoxOff")
    else
        -- Marca todas as disponíveis
        for i = 1, numAvail do
            local it = avail[i]
            local key = self:GetItemCartKey(it)
            if not self.cartKeys[key] then
                self.cartKeys[key] = true
                table.insert(self.cartItems, it)
            end
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
    end

    self:UpdateCartVisuals()
end

function TrainerMenu:ClearCart()
    self.cartItems = {}
    self.cartKeys  = {}
    self:UpdateCartVisuals()
end

function TrainerMenu:UpdateCartVisuals()
    self:RefreshHeader()
    self:UpdateCatalogRows()
    self:UpdateFooterHints()
    if self:IsCartModalOpen() then
        self:UpdateCartModalVisuals()
    end
end

-- ----------------------------------------------------------------------------
-- 9c. MODAL DO CARRINHO DE TREINAMENTO (FASE 5)
-- ----------------------------------------------------------------------------
function TrainerMenu:CreateCartModalUI()
    if self.cartModalFrame then return self.cartModalFrame end

    local modal = CreateFrame("Frame", "ConsoleMode_TrainerCartModal", UIParent)
    modal:SetWidth(560)
    modal:SetHeight(470)
    modal:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    modal:SetFrameStrata("FULLSCREEN_DIALOG")
    modal:SetFrameLevel(60)
    modal:EnableMouse(true)
    modal:SetMovable(false)

    modal:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    modal:SetBackdropColor(0.06, 0.05, 0.04, 0.96)
    modal:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
    modal:Hide()

    -- Cabeçalho do Modal
    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -16)
    self:ApplyFont(title, FONTS.titleBold, 20)
    title:SetText("CARRINHO DE TREINAMENTO")
    title:SetTextColor(1.00, 0.82, 0.20, 1.0)
    modal.title = title

    local subTitle = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subTitle:SetPoint("TOP", title, "BOTTOM", 0, -3)
    self:ApplyFont(subTitle, FONTS.medium, 14)
    subTitle:SetText("(0 Habilidades Selecionadas)")
    subTitle:SetTextColor(0.80, 0.80, 0.80, 1.0)
    modal.subTitle = subTitle

    -- Botão Fechar no canto superior direito
    local closeBtn = CreateFrame("Button", "ConsoleMode_TrainerCartCloseBtn", modal)
    closeBtn:SetWidth(28)
    closeBtn:SetHeight(28)
    closeBtn:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -10, -10)
    closeBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    closeBtn:SetBackdropColor(0.12, 0.08, 0.06, 0.90)
    closeBtn:SetBackdropBorderColor(0.60, 0.45, 0.25, 0.80)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
    self:ApplyFont(closeText, FONTS.titleBold, 15)
    closeText:SetText("|cffff4040X|r")
    closeBtn.text = closeText

    closeBtn:SetScript("OnClick", function()
        TrainerMenu:CloseCartModal()
    end)
    closeBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.3, 0.3, 1.0)
    end)
    closeBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.45, 0.25, 0.80)
    end)

    -- Linha separadora do cabeçalho
    local sepTop = modal:CreateTexture(nil, "ARTWORK")
    sepTop:SetHeight(1)
    sepTop:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, -58)
    sepTop:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -16, -58)
    sepTop:SetTexture(1.0, 0.82, 0.20, 0.40)

    -- Cabeçalhos das Colunas da Lista
    local colHab = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colHab:SetPoint("TOPLEFT", modal, "TOPLEFT", 22, -64)
    self:ApplyFont(colHab, FONTS.medium, 13)
    colHab:SetText("HABILIDADE SELECIONADA")
    colHab:SetTextColor(0.65, 0.65, 0.65, 1.0)

    local colCusto = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colCusto:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -22, -64)
    self:ApplyFont(colCusto, FONTS.medium, 13)
    colCusto:SetText("CUSTO")
    colCusto:SetTextColor(0.65, 0.65, 0.65, 1.0)

    -- Área da Lista de Itens (5 linhas visíveis de 40px)
    local listContainer = CreateFrame("Frame", nil, modal)
    listContainer:SetPoint("TOPLEFT", modal, "TOPLEFT", 16, -82)
    listContainer:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -16, -82)
    listContainer:SetHeight(215)
    modal.listContainer = listContainer

    local rows = {}
    for i = 1, 5 do
        local row = CreateFrame("Button", "ConsoleMode_TrainerCartRow" .. i, listContainer)
        row:SetHeight(40)
        if i == 1 then
            row:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, 0)
            row:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", 0, 0)
        else
            row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -3)
            row:SetPoint("TOPRIGHT", rows[i - 1], "BOTTOMRIGHT", 0, -3)
        end

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        row:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
        row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)

        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.25)
        hl:SetAllPoints(row)
        hl:Hide()
        row.highlight = hl

        local cur = row:CreateTexture(nil, "OVERLAY")
        cur:SetWidth(12)
        cur:SetHeight(12)
        cur:SetPoint("LEFT", row, "LEFT", 4, 0)
        cur:SetTexture("Interface\\QuestFrame\\UI-Quest-BulletPoint")
        cur:SetVertexColor(1.0, 0.85, 0.20)
        cur:Hide()
        row.cursor = cur

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(30)
        icon:SetHeight(30)
        icon:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.icon = icon

        local iconBorder = CreateFrame("Frame", nil, row)
        iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        iconBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        row.iconBorder = iconBorder

        local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        priceText:SetPoint("RIGHT", row, "RIGHT", -36, 0)
        priceText:SetJustifyH("RIGHT")
        self:ApplyFont(priceText, FONTS.titleBold, 15)
        row.priceText = priceText

        -- Botão [X] para remover individualmente na linha
        local removeBtn = CreateFrame("Button", nil, row)
        removeBtn:SetWidth(24)
        removeBtn:SetHeight(24)
        removeBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        local removeLabel = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        removeLabel:SetPoint("CENTER", removeBtn, "CENTER", 0, 0)
        self:ApplyFont(removeLabel, FONTS.titleBold, 14)
        removeLabel:SetText("|cffff4040✕|r")
        removeBtn.label = removeLabel
        removeBtn:SetScript("OnClick", function()
            local p = this:GetParent()
            if p and p.cartItemIndex then
                local it = TrainerMenu.cartItems and TrainerMenu.cartItems[p.cartItemIndex]
                if it then
                    TrainerMenu:ToggleCartItem(it)
                    if TrainerMenu.cartSelectedIndex > TrainerMenu:GetCartCount() then
                        TrainerMenu.cartSelectedIndex = math.max(1, TrainerMenu:GetCartCount())
                    end
                    TrainerMenu:UpdateCartModalVisuals()
                end
            end
        end)
        row.removeBtn = removeBtn

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
        nameText:SetPoint("RIGHT", priceText, "LEFT", -8, 0)
        nameText:SetJustifyH("LEFT")
        self:ApplyFont(nameText, FONTS.bodyBold, 15)
        row.nameText = nameText

        local subText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        subText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
        subText:SetPoint("RIGHT", priceText, "LEFT", -8, 0)
        subText:SetJustifyH("LEFT")
        self:ApplyFont(subText, FONTS.medium, 13)
        row.subText = subText

        row.rowIndex = i
        row:RegisterForClicks("LeftButtonUp")
        row:SetScript("OnClick", function()
            if this.cartItemIndex then
                TrainerMenu.cartSelectedIndex = this.cartItemIndex
                TrainerMenu:UpdateCartModalVisuals()
            end
        end)

        row:SetScript("OnEnter", function()
            if this.cartItemIndex then
                local it = TrainerMenu.cartItems and TrainerMenu.cartItems[this.cartItemIndex]
                if it then
                    GameTooltip:SetOwner(modal, "ANCHOR_NONE")
                    GameTooltip:SetPoint("TOPLEFT", modal, "TOPRIGHT", 10, 0)
                    local ok = false
                    if it.index and GameTooltip.SetTrainerService then
                        ok = pcall(function() GameTooltip:SetTrainerService(it.index) end)
                    end
                    if not ok then
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(it.name or "Habilidade", 1, 1, 1)
                        if it.subText and it.subText ~= "" then
                            GameTooltip:AddLine(it.subText, 0.8, 0.8, 0.8)
                        end
                        if it.desc and it.desc ~= "" then
                            GameTooltip:AddLine(it.desc, 1, 0.82, 0, 1)
                        end
                    end
                    GameTooltip:Show()
                end
            end
        end)

        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        table.insert(rows, row)
    end
    modal.rows = rows

    -- Mensagem de carrinho vazio
    local emptyText = listContainer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER", listContainer, "CENTER", 0, 0)
    self:ApplyFont(emptyText, FONTS.bodyBold, 16)
    emptyText:SetText("Nenhuma habilidade no carrinho de compras.")
    emptyText:Hide()
    modal.emptyText = emptyText

    -- Indicador de Scroll
    local scrollNotice = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    scrollNotice:SetPoint("TOP", listContainer, "BOTTOM", 0, -3)
    self:ApplyFont(scrollNotice, FONTS.medium, 12)
    scrollNotice:SetText("")
    modal.scrollNotice = scrollNotice

    -- Card de Resumo Financeiro
    local summaryCard = CreateFrame("Frame", nil, modal)
    summaryCard:SetPoint("BOTTOM", modal, "BOTTOM", 0, 60)
    summaryCard:SetWidth(528)
    summaryCard:SetHeight(84)
    summaryCard:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    summaryCard:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
    summaryCard:SetBackdropBorderColor(0.40, 0.32, 0.22, 0.70)
    modal.summaryCard = summaryCard

    -- Linha 1: Custo Total
    local lblCost = summaryCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblCost:SetPoint("TOPLEFT", summaryCard, "TOPLEFT", 14, -10)
    self:ApplyFont(lblCost, FONTS.bodyBold, 14)
    lblCost:SetText("• Custo Total das Selecionadas:")
    lblCost:SetTextColor(0.85, 0.85, 0.85, 1.0)

    local valCost = summaryCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valCost:SetPoint("TOPRIGHT", summaryCard, "TOPRIGHT", -14, -10)
    self:ApplyFont(valCost, FONTS.titleBold, 15)
    valCost:SetText("0c")
    modal.valCost = valCost

    -- Linha 2: Saldo Atual
    local lblMoney = summaryCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblMoney:SetPoint("TOPLEFT", summaryCard, "TOPLEFT", 14, -32)
    self:ApplyFont(lblMoney, FONTS.bodyBold, 14)
    lblMoney:SetText("• Seu Saldo Atual:")
    lblMoney:SetTextColor(0.85, 0.85, 0.85, 1.0)

    local valMoney = summaryCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valMoney:SetPoint("TOPRIGHT", summaryCard, "TOPRIGHT", -14, -32)
    self:ApplyFont(valMoney, FONTS.titleBold, 15)
    valMoney:SetText("0c")
    modal.valMoney = valMoney

    -- Linha 3: Saldo Restante
    local lblRemaining = summaryCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lblRemaining:SetPoint("TOPLEFT", summaryCard, "TOPLEFT", 14, -54)
    self:ApplyFont(lblRemaining, FONTS.bodyBold, 14)
    lblRemaining:SetText("• Saldo Restante após Treinamento:")
    lblRemaining:SetTextColor(0.85, 0.85, 0.85, 1.0)
    modal.lblRemaining = lblRemaining

    local valRemaining = summaryCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valRemaining:SetPoint("TOPRIGHT", summaryCard, "TOPRIGHT", -14, -54)
    self:ApplyFont(valRemaining, FONTS.titleBold, 15)
    valRemaining:SetText("0c")
    modal.valRemaining = valRemaining

    -- Botões de Ação na Base
    local confirmBtn = CreateFrame("Button", "ConsoleMode_TrainerCartConfirmBtn", modal)
    confirmBtn:SetWidth(220)
    confirmBtn:SetHeight(32)
    confirmBtn:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 16, 14)
    confirmBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    confirmBtn:SetBackdropColor(0.12, 0.16, 0.08, 0.90)
    confirmBtn:SetBackdropBorderColor(0.30, 0.80, 0.30, 0.90)

    local confirmText = confirmBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    confirmText:SetPoint("CENTER", confirmBtn, "CENTER", 0, 0)
    self:ApplyFont(confirmText, FONTS.titleBold, 15)
    confirmText:SetText("[A] Confirmar Treinamento")
    confirmText:SetTextColor(0.40, 1.0, 0.40, 1.0)
    confirmBtn.text = confirmText

    confirmBtn:SetScript("OnClick", function()
        TrainerMenu:ConfirmCartPurchase()
    end)
    modal.confirmBtn = confirmBtn

    local cancelBtn = CreateFrame("Button", "ConsoleMode_TrainerCartCancelBtn", modal)
    cancelBtn:SetWidth(120)
    cancelBtn:SetHeight(32)
    cancelBtn:SetPoint("LEFT", confirmBtn, "RIGHT", 12, 0)
    cancelBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    cancelBtn:SetBackdropColor(0.10, 0.08, 0.06, 0.90)
    cancelBtn:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.80)

    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cancelText:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
    self:ApplyFont(cancelText, FONTS.titleBold, 15)
    cancelText:SetText("[B] Voltar")
    cancelText:SetTextColor(0.85, 0.85, 0.85, 1.0)
    cancelBtn.text = cancelText

    cancelBtn:SetScript("OnClick", function()
        TrainerMenu:CloseCartModal()
    end)
    modal.cancelBtn = cancelBtn

    -- Dica contextual à direita dos botões
    local hintsText = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hintsText:SetPoint("RIGHT", modal, "RIGHT", -20, 0)
    hintsText:SetPoint("CENTER", modal, "BOTTOM", 140, 30)
    self:ApplyFont(hintsText, FONTS.medium, 13)
    hintsText:SetText("|cffaaaaaa[D-Pad] Navegar  •  [X] Remover|r")
    modal.hintsText = hintsText

    -- Suporte a roda do mouse para scroll na lista
    modal:EnableMouseWheel(true)
    modal:SetScript("OnMouseWheel", function()
        local delta = arg1
        if delta > 0 then
            TrainerMenu:MoveCartSelection(-1)
        else
            TrainerMenu:MoveCartSelection(1)
        end
    end)

    self.cartModalFrame = modal
    return modal
end

function TrainerMenu:OpenCartModal()
    if not self.isOpen then return end
    if self:GetCartCount() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Seu carrinho de treinamento está vazio. Selecione habilidades com [A] ou marque todas com [Y].")
        PlaySound("igQuestFailed")
        return
    end

    self:CreateCartModalUI()
    self.cartSelectedIndex = 1
    self.cartScrollOffset = 0
    self.cartModalFrame:Show()
    self:UpdateCartModalVisuals()
    PlaySound("igMainMenuOpen")
end

function TrainerMenu:CloseCartModal()
    if self.cartModalFrame and self.cartModalFrame:IsVisible() then
        self.cartModalFrame:Hide()
        if GameTooltip:IsOwned(self.cartModalFrame) then
            GameTooltip:Hide()
        end
        PlaySound("igMainMenuClose")
    end
end

function TrainerMenu:IsCartModalOpen()
    return (self.cartModalFrame and self.cartModalFrame:IsVisible())
end

function TrainerMenu:MoveCartSelection(delta)
    if not self:IsCartModalOpen() then return end
    local count = self:GetCartCount()
    if count == 0 then return end

    local newIdx = (self.cartSelectedIndex or 1) + delta
    if newIdx < 1 then newIdx = 1 end
    if newIdx > count then newIdx = count end

    self.cartSelectedIndex = newIdx
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:UpdateCartModalVisuals()
end

function TrainerMenu:RemoveCurrentCartItem()
    if not self:IsCartModalOpen() then return end
    local count = self:GetCartCount()
    if count == 0 then return end

    local it = self.cartItems[self.cartSelectedIndex]
    if it then
        self:ToggleCartItem(it)
    end

    local newCount = self:GetCartCount()
    if self.cartSelectedIndex > newCount then
        self.cartSelectedIndex = math.max(1, newCount)
    end
    if self.cartScrollOffset > math.max(0, newCount - 5) then
        self.cartScrollOffset = math.max(0, newCount - 5)
    end

    self:UpdateCartModalVisuals()
end

function TrainerMenu:UpdateCartModalVisuals()
    local m = self.cartModalFrame
    if not m or not m:IsVisible() then return end

    local count = self:GetCartCount()
    m.subTitle:SetText("(" .. count .. (count == 1 and " Habilidade Selecionada)" or " Habilidades Selecionadas)"))

    if count == 0 then
        m.emptyText:Show()
        for r = 1, 5 do
            m.rows[r]:Hide()
        end
        m.scrollNotice:Hide()
    else
        m.emptyText:Hide()
        local maxVisible = 5
        if self.cartSelectedIndex > count then
            self.cartSelectedIndex = count
        end
        if self.cartSelectedIndex < 1 then
            self.cartSelectedIndex = 1
        end

        if self.cartSelectedIndex <= self.cartScrollOffset then
            self.cartScrollOffset = self.cartSelectedIndex - 1
        elseif self.cartSelectedIndex > self.cartScrollOffset + maxVisible then
            self.cartScrollOffset = self.cartSelectedIndex - maxVisible
        end
        if self.cartScrollOffset < 0 then self.cartScrollOffset = 0 end

        for r = 1, maxVisible do
            local row = m.rows[r]
            local itemIdx = self.cartScrollOffset + r
            local it = self.cartItems[itemIdx]

            if it then
                row:Show()
                row.cartItemIndex = itemIdx
                row.icon:SetTexture(it.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

                local dName = it.name or "Habilidade"
                if it.subText and it.subText ~= "" then
                    dName = dName .. " (" .. it.subText .. ")"
                end
                row.nameText:SetText("|cffffffff" .. dName .. "|r")
                row.subText:SetText("|cffaaaaaaNv. " .. (it.levelReq or 1) .. "  •  " .. (it.tree or "Geral") .. "|r")
                row.priceText:SetText(self:FormatMoneyText(it.cost or 0))

                if itemIdx == self.cartSelectedIndex then
                    row.cursor:Show()
                    row.highlight:Show()
                    row:SetBackdropColor(0.18, 0.14, 0.08, 0.80)
                    row:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
                else
                    row.cursor:Hide()
                    row.highlight:Hide()
                    row:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
                    row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
                end
            else
                row:Hide()
                row.cartItemIndex = nil
            end
        end

        if count > maxVisible then
            m.scrollNotice:Show()
            m.scrollNotice:SetText("Item " .. self.cartSelectedIndex .. " de " .. count .. "  (Use D-Pad ou Scroll)")
        else
            m.scrollNotice:Hide()
        end
    end

    -- Resumo Financeiro
    local totalCost = self:GetCartTotalCost()
    local playerMoney = GetMoney() or 0
    local remainingMoney = playerMoney - totalCost

    m.valCost:SetText(self:FormatMoneyText(totalCost))
    m.valMoney:SetText(self:FormatMoneyText(playerMoney))

    if count == 0 then
        m.lblRemaining:SetText("• Saldo Restante após Treinamento:")
        m.lblRemaining:SetTextColor(0.85, 0.85, 0.85, 1.0)
        m.valRemaining:SetText(self:FormatMoneyText(playerMoney))
        m.confirmBtn:Disable()
        m.confirmBtn:SetBackdropColor(0.08, 0.08, 0.08, 0.50)
        m.confirmBtn:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.50)
        m.confirmBtn.text:SetTextColor(0.50, 0.50, 0.50, 1.0)
    elseif remainingMoney >= 0 then
        m.lblRemaining:SetText("• Saldo Restante após Treinamento:")
        m.lblRemaining:SetTextColor(0.85, 0.85, 0.85, 1.0)
        m.valRemaining:SetText(self:FormatMoneyText(remainingMoney))
        m.confirmBtn:Enable()
        m.confirmBtn:SetBackdropColor(0.12, 0.16, 0.08, 0.90)
        m.confirmBtn:SetBackdropBorderColor(0.30, 0.80, 0.30, 0.90)
        m.confirmBtn.text:SetTextColor(0.40, 1.0, 0.40, 1.0)
    else
        local deficit = totalCost - playerMoney
        m.lblRemaining:SetText("• Saldo Insuficiente:")
        m.lblRemaining:SetTextColor(1.0, 0.25, 0.25, 1.0)
        m.valRemaining:SetText("|cffff2020Faltam " .. self:FormatMoneyText(deficit) .. "|r")
        m.confirmBtn:Disable()
        m.confirmBtn:SetBackdropColor(0.14, 0.06, 0.06, 0.70)
        m.confirmBtn:SetBackdropBorderColor(0.60, 0.20, 0.20, 0.70)
        m.confirmBtn.text:SetTextColor(0.60, 0.35, 0.35, 1.0)
    end

    -- Atualiza Tooltip Nativo se um item estiver selecionado
    local selItem = self.cartItems and self.cartItems[self.cartSelectedIndex]
    if selItem then
        GameTooltip:SetOwner(m, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", m, "TOPRIGHT", 10, 0)
        local ok = false
        if selItem.index and GameTooltip.SetTrainerService then
            ok = pcall(function() GameTooltip:SetTrainerService(selItem.index) end)
        end
        if not ok then
            GameTooltip:ClearLines()
            GameTooltip:AddLine(selItem.name or "Habilidade", 1, 1, 1)
            if selItem.subText and selItem.subText ~= "" then
                GameTooltip:AddLine(selItem.subText, 0.8, 0.8, 0.8)
            end
            if selItem.desc and selItem.desc ~= "" then
                GameTooltip:AddLine(selItem.desc, 1, 0.82, 0, 1)
            end
        end
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end
end

-- ----------------------------------------------------------------------------
-- 9d. FILA SERIALIZADA DE COMPRA EM BATCH (FASE 6)
-- ----------------------------------------------------------------------------
function TrainerMenu:ConfirmCartPurchase()
    if not self:IsCartModalOpen() then return end
    local count = self:GetCartCount()
    if count == 0 then
        PlaySound("igQuestFailed")
        return
    end

    local totalCost = self:GetCartTotalCost()
    local playerMoney = GetMoney() or 0
    if playerMoney < totalCost then
        PlaySound("igQuestFailed")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[ConsoleMode] Saldo insuficiente para realizar o treinamento.|r")
        if UIErrorsFrame and ERR_NOT_ENOUGH_MONEY and UIERRORS_HOLD_TIME then
            UIErrorsFrame:AddMessage(ERR_NOT_ENOUGH_MONEY, 1.0, 0.1, 0.1, 1.0, UIERRORS_HOLD_TIME)
        end
        return
    end

    local queue = {}
    for i = 1, count do
        table.insert(queue, self.cartItems[i])
    end

    self:CloseCartModal()

    self.purchaseState = {
        running      = true,
        queue        = queue,
        pos          = 1,
        acc          = 0,
        totalSpent   = 0,
        totalCount   = count,
        successCount = 0,
    }

    if not self.purchaseFrame then
        self.purchaseFrame = CreateFrame("Frame", "ConsoleMode_TrainerPurchaseFrame")
    end
    self.purchaseFrame:SetScript("OnUpdate", function()
        TrainerMenu:PurchaseQueue_OnUpdate(arg1)
    end)

    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Iniciando treinamento de " .. count .. " habilidades...")
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function TrainerMenu:PurchaseQueue_OnUpdate(dt)
    local st = self.purchaseState
    if not st or not st.running then return end

    st.acc = (st.acc or 0) + (dt or 0)
    if st.acc < 0.15 then return end
    st.acc = 0

    if not self.isOpen then
        self:PurchaseQueue_Stop(false)
        return
    end

    local q = st.queue or {}
    local total = table.getn(q)
    local pos = tonumber(st.pos) or 1
    if pos > total then
        self:PurchaseQueue_Stop(true)
        return
    end

    local it = q[pos]
    st.pos = pos + 1

    if it then
        local serviceIndex = it.index
        local found = false

        if serviceIndex and GetTrainerServiceInfo then
            local sName, sSub, sType = GetTrainerServiceInfo(serviceIndex)
            if sName == it.name and sType == "available" then
                found = true
            end
        end

        if not found and GetNumTrainerServices and GetTrainerServiceInfo then
            local num = GetNumTrainerServices() or 0
            for i = 1, num do
                local sName, sSub, sType = GetTrainerServiceInfo(i)
                if sName == it.name and (not it.subText or it.subText == "" or sSub == it.subText) and sType == "available" then
                    serviceIndex = i
                    found = true
                    break
                end
            end
        end

        if found and serviceIndex then
            local cost = (it.cost or 0)
            local currentMoney = GetMoney() or 0
            if currentMoney >= cost then
                if SelectTrainerService then
                    pcall(function() SelectTrainerService(serviceIndex) end)
                end
                if BuyTrainerService then
                    pcall(function() BuyTrainerService(serviceIndex) end)
                end

                st.totalSpent = (st.totalSpent or 0) + cost
                st.successCount = (st.successCount or 0) + 1
                PlaySound("SPELLBOOKSPELLCLICK")

                local displayName = it.name or "Habilidade"
                if it.subText and it.subText ~= "" then
                    displayName = displayName .. " (" .. it.subText .. ")"
                end
                DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Treinado: |cffffffff" .. displayName .. "|r (" .. self:FormatMoneyText(cost) .. ")")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[ConsoleMode]|r Saldo insuficiente para treinar: " .. (it.name or ""))
            end
        end
    end

    if (st.pos or 1) > total then
        self:PurchaseQueue_Stop(true)
    end
end

function TrainerMenu:PurchaseQueue_Stop(completed)
    local st = self.purchaseState
    if not st then return end
    st.running = false
    st.pos = 1

    if self.purchaseFrame then
        self.purchaseFrame:SetScript("OnUpdate", nil)
    end

    if completed then
        local count = st.successCount or 0
        local spent = st.totalSpent or 0
        if count > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff1eff00[ConsoleMode]|r Treinamento em lote concluído! " .. count .. " habilidades aprendidas (" .. self:FormatMoneyText(spent) .. ").")
            PlaySound("LOOTWINDOWCOINSOUND")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Treinamento finalizado.")
        end
    end

    self.purchaseState = nil
    self:ClearCart()
    self:ScanTrainerServices()
    self:RefreshHeader()
end

-- ----------------------------------------------------------------------------
-- 10. CICLO DE VIDA, ABERTURA E FECHAMENTO
-- ----------------------------------------------------------------------------
function TrainerMenu:Open()
    self:CreateUI()
    self:UpdateLayout()
    self:RefreshHeader()

    self:ClearCart()
    if self:IsCartModalOpen() then
        self:CloseCartModal()
    end

    self.searchText        = ""
    self.isFutureCollapsed = true
    self.isUsedCollapsed   = true
    self.collapsedTrees    = {}
    self.selectedIndex     = 1
    self.scrollOffset      = 0
    self.isSearchSelected  = false

    if self.searchContainer then
        self.searchContainer:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.70)
        if self.searchContainer.highlight then
            self.searchContainer.highlight:Hide()
        end
    end

    if self.searchEditBox then
        self.searchEditBox:SetText("")
    end
    if self.searchPlaceholder then
        self.searchPlaceholder:Show()
    end
    if self.searchClearBtn then
        self.searchClearBtn:Hide()
    end

    -- Varre os serviços oferecidos pelo treinador
    self:ScanTrainerServices()

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

    if self:IsCartModalOpen() then
        self:CloseCartModal()
    end
    if self.purchaseState and self.purchaseState.running then
        self:PurchaseQueue_Stop(false)
    end
    self:ClearCart()

    self.isOpen           = false
    self.trainerName      = nil
    self.trainerType      = nil
    self.numServices      = 0
    self.isScanning       = false
    self.isSearchSelected = false
    self.filtersConfigured = false
    self.isConfiguringFilters = false

    self.rawServices       = {}
    self.availableServices = {}
    self.futureServices    = {}
    self.usedServices      = {}
    self.treesOrder        = {}
    self.flattenedList     = {}
    self.isFutureCollapsed = true
    self.isUsedCollapsed   = true
    self.collapsedTrees    = {}
    self.searchText        = ""
    self.repeatState.direction = nil
    self.repeatState.timer     = 0

    if self.searchEditBox then
        self.searchEditBox:ClearFocus()
        self.searchEditBox:SetText("")
    end

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
    if self:IsCartModalOpen() then
        self:CloseCartModal()
        return
    end
    self:Close()
end

-- ----------------------------------------------------------------------------
-- 11. SUPRESSÃO SEGURA DO FRAME NATIVO DA BLIZZARD (Zero Taint)
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
-- 12. EVENTOS DO CICLO DE VIDA DO TREINADOR
-- ----------------------------------------------------------------------------
function TrainerMenu:EnsureFiltersAndExpansion()
    if self.filtersConfigured or self.isConfiguringFilters then return end
    self.isConfiguringFilters = true

    -- Garante que todos os tipos de serviços sejam exibidos pelo cliente Vanilla
    if SetTrainerServiceTypeFilter then
        if GetTrainerServiceTypeFilter then
            if not GetTrainerServiceTypeFilter("available") then
                SetTrainerServiceTypeFilter("available", 1)
            end
            if not GetTrainerServiceTypeFilter("unavailable") then
                SetTrainerServiceTypeFilter("unavailable", 1)
            end
            if not GetTrainerServiceTypeFilter("used") then
                SetTrainerServiceTypeFilter("used", 1)
            end
        else
            SetTrainerServiceTypeFilter("available", 1)
            SetTrainerServiceTypeFilter("unavailable", 1)
            SetTrainerServiceTypeFilter("used", 1)
        end
    end

    -- Expande todas as árvores/linhas colapsadas para disponibilizar a lista completa
    if ExpandTrainerSkillLine then
        local ok = pcall(function() ExpandTrainerSkillLine(0) end)
        if not ok and GetNumTrainerServices then
            local n = GetNumTrainerServices() or 0
            for i = 1, n do
                local _, _, sType, isExpanded = GetTrainerServiceInfo(i)
                if sType == "header" and not isExpanded then
                    pcall(function() ExpandTrainerSkillLine(i) end)
                end
            end
        end
    end

    self.filtersConfigured    = true
    self.isConfiguringFilters = false
end

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

    self.isOpen            = true
    self.filtersConfigured = false
    self.trainerName       = npcName
    self.trainerType       = trainerType

    -- 3. Configura os filtros (available, unavailable, used) e expande árvores
    self:EnsureFiltersAndExpansion()

    local numServices = 0
    if GetNumTrainerServices then
        numServices = GetNumTrainerServices() or 0
    end
    self.numServices = numServices

    -- 4. Abre a interface nobre do ConsoleMode
    self:Open()

    -- 5. Delay de segurança (50ms) para re-suprimir caso a Blizzard tente renderizar tardiamente
    if not self.safetyFrame then
        self.safetyFrame = CreateFrame("Frame", "ConsoleMode_TrainerSafetyFrame")
    end
    self.safetyFrame.t = 0
    self.safetyFrame:SetScript("OnUpdate", function(a1, a2)
        local dt = (type(a2) == "number" and a2) or (type(a1) == "number" and a1) or (type(arg1) == "number" and arg1) or 0.016
        this.t = (this.t or 0) + dt
        if this.t >= 0.05 then
            this:SetScript("OnUpdate", nil)
            TrainerMenu:SuppressDefaultFrame()
        end
    end)
end

function TrainerMenu:OnTrainerUpdate()
    if not self.isOpen or self.isScanning or self.isConfiguringFilters then return end
    if self.purchaseState and self.purchaseState.running then return end

    if not self.filtersConfigured then
        self:EnsureFiltersAndExpansion()
    end

    if GetNumTrainerServices then
        self.numServices = GetNumTrainerServices() or 0
    end
    self:ScanTrainerServices()
end

function TrainerMenu:OnTrainerClosed()
    if self.isOpen then
        self:Close()
    end
end

function TrainerMenu:OnMoneyUpdate()
    if not self.isOpen then return end
    self:RefreshHeader()
end

-- ----------------------------------------------------------------------------
-- 13. INICIALIZAÇÃO E REGISTRO DE EVENTOS
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
