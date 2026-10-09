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

-- Elementos de Interface
TrainerMenu.dimmer           = nil
TrainerMenu.frame            = nil
TrainerMenu.footerWidgets    = nil
TrainerMenu.searchContainer  = nil
TrainerMenu.searchEditBox    = nil
TrainerMenu.searchPlaceholder= nil
TrainerMenu.searchClearBtn   = nil

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

    local selEntry = self.flattenedList and self.flattenedList[self.selectedIndex]
    local isUsedHeader   = (selEntry and selEntry.id == "SECTION_USED")
    local isFutureHeader = (selEntry and selEntry.id == "SECTION_FUTURE")
    local isTreeHeader   = (selEntry and selEntry.type == "TREE_HEADER")

    -- Adapta dinamicamente a legenda do Botão A conforme foco
    if self.footerWidgets[1] and self.footerWidgets[1].label then
        if isUsedHeader then
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
function TrainerMenu:CreateSearchBar(parent)
    local searchBar = CreateFrame("Frame", "ConsoleMode_TrainerSearchBar", parent)
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
-- 5d. CRIAÇÃO GERAL DA UI
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
end

-- ----------------------------------------------------------------------------
-- 6. SCANNER DO TREINADOR, AGRUPAMENTO & LISTA UNIFICADA (FASE 3)
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

                    if it.category == "available" then
                        row.nameText:SetText("|cffffffff" .. displayName .. "|r")
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
                    local isSel = (flatIdx == self.selectedIndex)
                    if isSel then
                        row.cursor:Show()
                        row.highlight:Show()
                        row:SetBackdropColor(0.20, 0.16, 0.10, 0.85)
                        row:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                    else
                        row.cursor:Hide()
                        row.highlight:Hide()
                        row:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
                        row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
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

                    local isSel = (flatIdx == self.selectedIndex)
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

                    local isSel = (flatIdx == self.selectedIndex)
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

function TrainerMenu:UpdateRightColPlaceholder()
    if not self.frame or not self.frame.rightCol or not self.frame.rightCol.placeholder then return end

    local entry = self.flattenedList and self.flattenedList[self.selectedIndex]
    if entry and entry.type == "SERVICE_ITEM" and entry.item then
        local it = entry.item
        local rankStr = (it.subText and it.subText ~= "") and (" (" .. it.subText .. ")") or ""
        self.frame.rightCol.placeholder:SetText("|cffe09a15" .. it.name .. rankStr .. "|r\n\n|cffccccccEspecialização: " .. (it.tree or "Geral") .. "|r\n|cffaaaaaaCusto: " .. self:FormatMoneyText(it.cost or 0) .. "  •  Requer: Nv. " .. (it.levelReq or 1) .. "|r\n\n|cff888888(Fase 4: Comparativo Grimório vs Treinador)|r")
    else
        self.frame.rightCol.placeholder:SetText("|cffe09a15Selecione uma habilidade à esquerda para inspecionar.|r\n|cffaaaaaa(Fase 4: Comparativo Grimório vs Treinador)|r")
    end
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
    if total == 0 then return end

    local cur = self.selectedIndex or 1
    local step = (delta > 0) and 1 or -1
    local nextIdx = cur + step

    while nextIdx >= 1 and nextIdx <= total do
        if self:IsEntrySelectable(flat[nextIdx]) then
            self.selectedIndex = nextIdx
            PlaySound("igMainMenuOptionCheckBoxOn")
            self:ScrollToSelection()
            self:UpdateCatalogRows()
            self:UpdateRightColPlaceholder()
            self:UpdateFooterHints()
            return
        end
        nextIdx = nextIdx + step
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

    self.selectedIndex = flatIndex
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:ScrollToSelection()
    self:UpdateCatalogRows()
    self:UpdateRightColPlaceholder()
    self:UpdateFooterHints()
end

function TrainerMenu:OnRowClick(flatIndex)
    if not flatIndex then return end
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
        self:SelectIndex(flatIndex)
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

-- Botão A no controle: Alterna Seção Já Aprendidas / Futuras, Alterna Árvores ou Seleciona Habilidade
function TrainerMenu:OnConfirm()
    if not self.isOpen then return end
    local entry = self.flattenedList and self.flattenedList[self.selectedIndex]
    if not entry then return end

    if entry.id == "SECTION_USED" then
        self:ToggleUsedSection()
    elseif entry.id == "SECTION_FUTURE" then
        self:ToggleFutureSection()
    elseif entry.type == "TREE_HEADER" then
        self:ToggleTree(entry.id)
    elseif entry.type == "SERVICE_ITEM" then
        PlaySound("igMainMenuOptionCheckBoxOn")
        -- Na Fase 5: alternará checkbox de carrinho [✓]
    end
end

-- Botão X no controle: Limpa a busca
function TrainerMenu:OnSecondaryAction()
    if not self.isOpen then return end
    if self.searchText and self.searchText ~= "" then
        self:ClearSearch()
        PlaySound("igMainMenuOptionCheckBoxOff")
    end
end

-- Botão Y no controle: (Preparado para Fase 5 - Marcar Todas)
function TrainerMenu:OnContextAction()
    if not self.isOpen then return end
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
            title       = "Buscar Habilidade",
            initialText = self.searchText or "",
            maxLetters  = 24,
            onConfirm   = function(text)
                TrainerMenu:SetSearchFilter(text)
            end,
            onCancel    = function() end,
        })
    end
end

-- ----------------------------------------------------------------------------
-- 10. CICLO DE VIDA, ABERTURA E FECHAMENTO
-- ----------------------------------------------------------------------------
function TrainerMenu:Open()
    self:CreateUI()
    self:UpdateLayout()
    self:RefreshHeader()

    self.searchText        = ""
    self.isFutureCollapsed = true
    self.isUsedCollapsed   = true
    self.collapsedTrees    = {}
    self.selectedIndex     = 1
    self.scrollOffset      = 0
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

    self.isOpen      = false
    self.trainerName = nil
    self.trainerType = nil
    self.numServices = 0
    self.isScanning  = false
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
