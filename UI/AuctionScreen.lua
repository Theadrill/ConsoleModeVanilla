-- ============================================================================
-- ConsoleModeVanilla - UI/AuctionScreen.lua
-- Tela de Leilão (Auction House) para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE 0: Fundação, Moldura 9-Slice, Abas e Hook de Abertura
-- FASE 1: Aba Comprar — Categorias, Navegação D-Pad, Filtros Salvos e Scan
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

local QUALITY_COLORS = {
    [-1] = { 1.00, 1.00, 1.00 }, -- Todas
    [0]  = { 0.62, 0.62, 0.62 }, -- Poor (Cinza)
    [1]  = { 1.00, 1.00, 1.00 }, -- Common (Branco)
    [2]  = { 0.12, 1.00, 0.00 }, -- Uncommon (Verde)
    [3]  = { 0.00, 0.44, 0.87 }, -- Rare (Azul)
    [4]  = { 0.64, 0.21, 0.93 }, -- Epic (Roxo)
    [5]  = { 1.00, 0.50, 0.00 }, -- Legendary (Laranja)
}

local QUALITY_KEYS = {
    [-1] = "AH_QUALITY_ALL",
    [0]  = "AH_QUALITY_POOR",
    [1]  = "AH_QUALITY_COMMON",
    [2]  = "AH_QUALITY_UNCOMMON",
    [3]  = "AH_QUALITY_RARE",
    [4]  = "AH_QUALITY_EPIC",
    [5]  = "AH_QUALITY_LEGENDARY",
}

local QUALITY_ORDER = { -1, 0, 1, 2, 3, 4, 5 }

local TABS = {
    { key = "BUY",   labelKey = "AH_TAB_BUY" },
    { key = "SELL",  labelKey = "AH_TAB_SELL" },
    { key = "OWNER", labelKey = "AH_TAB_MY_AUCTIONS" }
}

-- ----------------------------------------------------------------------------
-- 2. MATRIZ DE CATEGORIAS E SLOTS (TURTLE WOW 1.18.1 / VANILLA 1.12.1)
-- ----------------------------------------------------------------------------
local CATEGORIES = {
    {
        id = "WEAPON",
        labelKey = "AH_CAT_WEAPON",
        classIndex = 1,
        hasSubcategories = true,
        subcategories = {
            { id = "AXES", labelKey = "AH_WEAPON_AXES", hasSlots = true, slots = {
                { labelKey = "AH_SUBCAT_ALL", subClassIndex = 0 },
                { labelKey = "AH_SUBCAT_ONE_HANDED", subClassIndex = 1 },
                { labelKey = "AH_SUBCAT_TWO_HANDED", subClassIndex = 2 },
            }},
            { id = "MACES", labelKey = "AH_WEAPON_MACES", hasSlots = true, slots = {
                { labelKey = "AH_SUBCAT_ALL", subClassIndex = 0 },
                { labelKey = "AH_SUBCAT_ONE_HANDED", subClassIndex = 5 },
                { labelKey = "AH_SUBCAT_TWO_HANDED", subClassIndex = 6 },
            }},
            { id = "SWORDS", labelKey = "AH_WEAPON_SWORDS", hasSlots = true, slots = {
                { labelKey = "AH_SUBCAT_ALL", subClassIndex = 0 },
                { labelKey = "AH_SUBCAT_ONE_HANDED", subClassIndex = 8 },
                { labelKey = "AH_SUBCAT_TWO_HANDED", subClassIndex = 9 },
            }},
            { id = "DAGGERS", labelKey = "AH_WEAPON_DAGGERS", subClassIndex = 13 },
            { id = "FIST", labelKey = "AH_WEAPON_FIST", subClassIndex = 11 },
            { id = "STAVES", labelKey = "AH_WEAPON_STAVES", subClassIndex = 10 },
            { id = "POLEARMS", labelKey = "AH_WEAPON_POLEARMS", subClassIndex = 7 },
            { id = "BOWS", labelKey = "AH_WEAPON_BOWS", subClassIndex = 3 },
            { id = "GUNS", labelKey = "AH_WEAPON_GUNS", subClassIndex = 4 },
            { id = "CROSSBOWS", labelKey = "AH_WEAPON_CROSSBOWS", subClassIndex = 15 },
            { id = "WANDS", labelKey = "AH_WEAPON_WANDS", subClassIndex = 16 },
            { id = "THROWN", labelKey = "AH_WEAPON_THROWN", subClassIndex = 14 },
            { id = "FISHING", labelKey = "AH_WEAPON_FISHING", subClassIndex = 17 },
            { id = "MISC_WEAPON", labelKey = "AH_WEAPON_MISC", subClassIndex = 12 },
            { id = "ALL_WEAPONS", labelKey = "AH_SUBCAT_ALL_WEAPONS", subClassIndex = 0 },
        }
    },
    {
        id = "ARMOR",
        labelKey = "AH_CAT_ARMOR",
        classIndex = 2,
        hasSubcategories = true,
        subcategories = {
            { id = "CLOTH", labelKey = "AH_ARMOR_CLOTH", subClassIndex = 2, hasSlots = true, slots = {
                { labelKey = "AH_SLOT_ALL", slotIndex = 0 },
                { labelKey = "AH_SLOT_HEAD", slotIndex = 1 },
                { labelKey = "AH_SLOT_SHOULDER", slotIndex = 3 },
                { labelKey = "AH_SLOT_BACK", slotIndex = 13 },
                { labelKey = "AH_SLOT_CHEST", slotIndex = 5 },
                { labelKey = "AH_SLOT_WRIST", slotIndex = 9 },
                { labelKey = "AH_SLOT_HANDS", slotIndex = 10 },
                { labelKey = "AH_SLOT_WAIST", slotIndex = 6 },
                { labelKey = "AH_SLOT_LEGS", slotIndex = 7 },
                { labelKey = "AH_SLOT_FEET", slotIndex = 8 },
            }},
            { id = "LEATHER", labelKey = "AH_ARMOR_LEATHER", subClassIndex = 3, hasSlots = true, slots = {
                { labelKey = "AH_SLOT_ALL", slotIndex = 0 },
                { labelKey = "AH_SLOT_HEAD", slotIndex = 1 },
                { labelKey = "AH_SLOT_SHOULDER", slotIndex = 3 },
                { labelKey = "AH_SLOT_CHEST", slotIndex = 5 },
                { labelKey = "AH_SLOT_WRIST", slotIndex = 9 },
                { labelKey = "AH_SLOT_HANDS", slotIndex = 10 },
                { labelKey = "AH_SLOT_WAIST", slotIndex = 6 },
                { labelKey = "AH_SLOT_LEGS", slotIndex = 7 },
                { labelKey = "AH_SLOT_FEET", slotIndex = 8 },
            }},
            { id = "MAIL", labelKey = "AH_ARMOR_MAIL", subClassIndex = 4, hasSlots = true, slots = {
                { labelKey = "AH_SLOT_ALL", slotIndex = 0 },
                { labelKey = "AH_SLOT_HEAD", slotIndex = 1 },
                { labelKey = "AH_SLOT_SHOULDER", slotIndex = 3 },
                { labelKey = "AH_SLOT_CHEST", slotIndex = 5 },
                { labelKey = "AH_SLOT_WRIST", slotIndex = 9 },
                { labelKey = "AH_SLOT_HANDS", slotIndex = 10 },
                { labelKey = "AH_SLOT_WAIST", slotIndex = 6 },
                { labelKey = "AH_SLOT_LEGS", slotIndex = 7 },
                { labelKey = "AH_SLOT_FEET", slotIndex = 8 },
            }},
            { id = "PLATE", labelKey = "AH_ARMOR_PLATE", subClassIndex = 5, hasSlots = true, slots = {
                { labelKey = "AH_SLOT_ALL", slotIndex = 0 },
                { labelKey = "AH_SLOT_HEAD", slotIndex = 1 },
                { labelKey = "AH_SLOT_SHOULDER", slotIndex = 3 },
                { labelKey = "AH_SLOT_CHEST", slotIndex = 5 },
                { labelKey = "AH_SLOT_WRIST", slotIndex = 9 },
                { labelKey = "AH_SLOT_HANDS", slotIndex = 10 },
                { labelKey = "AH_SLOT_WAIST", slotIndex = 6 },
                { labelKey = "AH_SLOT_LEGS", slotIndex = 7 },
                { labelKey = "AH_SLOT_FEET", slotIndex = 8 },
            }},
            { id = "ACCESSORIES", labelKey = "AH_ARMOR_ACCESSORIES", subClassIndex = 1, hasSlots = true, slots = {
                { labelKey = "AH_SLOT_ALL", slotIndex = 0 },
                { labelKey = "AH_SLOT_NECK", slotIndex = 2 },
                { labelKey = "AH_SLOT_FINGER", slotIndex = 11 },
                { labelKey = "AH_SLOT_TRINKET", slotIndex = 12 },
                { labelKey = "AH_SLOT_OFFHAND", slotIndex = 14 },
                { labelKey = "AH_SLOT_SHIRT", slotIndex = 4 },
                { labelKey = "AH_SLOT_CHEST", slotIndex = 5 },
            }},
            { id = "SHIELDS", labelKey = "AH_ARMOR_SHIELDS", subClassIndex = 6 },
            { id = "LIBRAMS", labelKey = "AH_ARMOR_LIBRAMS", subClassIndex = 7 },
            { id = "IDOLS", labelKey = "AH_ARMOR_IDOLS", subClassIndex = 8 },
            { id = "TOTEMS", labelKey = "AH_ARMOR_TOTEMS", subClassIndex = 9 },
            { id = "ALL_ARMOR", labelKey = "AH_SUBCAT_ALL_ARMOR", subClassIndex = 0 },
        }
    },
    { id = "CONTAINER", labelKey = "AH_CAT_CONTAINER", classIndex = 3 },
    { id = "CONSUMABLE", labelKey = "AH_CAT_CONSUMABLE", classIndex = 4 },
    { id = "TRADE_GOODS", labelKey = "AH_CAT_TRADE_GOODS", classIndex = 5 },
    {
        id = "PROJECTILE",
        labelKey = "AH_CAT_PROJECTILE",
        classIndex = 6,
        hasSubcategories = true,
        subcategories = {
            { id = "ALL_PROJ", labelKey = "AH_SUBCAT_ALL", subClassIndex = 0 },
            { id = "ARROW", label = "Arrows", subClassIndex = 1 },
            { id = "BULLET", label = "Bullets", subClassIndex = 2 },
        }
    },
    {
        id = "QUIVER",
        labelKey = "AH_CAT_QUIVER",
        classIndex = 7,
        hasSubcategories = true,
        subcategories = {
            { id = "ALL_QUIV", labelKey = "AH_SUBCAT_ALL", subClassIndex = 0 },
            { id = "QUIVER_BAG", label = "Quivers", subClassIndex = 1 },
            { id = "AMMO_POUCH", label = "Ammo Pouches", subClassIndex = 2 },
        }
    },
    {
        id = "RECIPE",
        labelKey = "AH_CAT_RECIPE",
        classIndex = 8,
        hasSubcategories = true,
        subcategories = {
            { id = "ALL_RECIPES", labelKey = "AH_SUBCAT_ALL", subClassIndex = 0 },
            { id = "REC_BOOK", label = "Books", subClassIndex = 1 },
            { id = "REC_LW", label = "Leatherworking", subClassIndex = 2 },
            { id = "REC_TAILOR", label = "Tailoring", subClassIndex = 3 },
            { id = "REC_ENG", label = "Engineering", subClassIndex = 4 },
            { id = "REC_BS", label = "Blacksmithing", subClassIndex = 5 },
            { id = "REC_COOK", label = "Cooking", subClassIndex = 6 },
            { id = "REC_ALCH", label = "Alchemy", subClassIndex = 7 },
            { id = "REC_FA", label = "First Aid", subClassIndex = 8 },
            { id = "REC_ENCH", label = "Enchanting", subClassIndex = 9 },
            { id = "REC_FISH", label = "Fishing", subClassIndex = 10 },
            { id = "REC_JC", label = "Jewelcrafting", subClassIndex = 11 },
            { id = "REC_SURV", label = "Survival", subClassIndex = 12 },
        }
    },
    { id = "MISCELLANEOUS", labelKey = "AH_CAT_MISCELLANEOUS", classIndex = 10 },
    { id = "ALL", labelKey = "AH_CAT_ALL", classIndex = 0 }
}

-- ----------------------------------------------------------------------------
-- 3. ESTADO DO MÓDULO
-- ----------------------------------------------------------------------------
AuctionScreen.isOpen              = false
AuctionScreen.initialized         = false
AuctionScreen.currentTab          = "BUY" -- "BUY", "SELL", "OWNER"
AuctionScreen.frame               = nil
AuctionScreen.dimmer              = nil
AuctionScreen.eventFrame          = nil
AuctionScreen.footerWidgets       = nil

-- Estados da Aba Comprar (Buy Tab)
AuctionScreen.buyStep             = "CATEGORIES" -- "CATEGORIES", "SUBCATEGORIES", "SLOTS", "FILTERS", "SCANNING", "RESULTS_SUMMARY"
AuctionScreen.selectedCategory    = nil
AuctionScreen.selectedSubcategory = nil
AuctionScreen.selectedSlot        = nil
AuctionScreen.gridIndex           = 1
AuctionScreen.gridColumns         = 2
AuctionScreen.gridItems           = {}
AuctionScreen.filterRowIndex      = 1
AuctionScreen.summaryBtnIndex     = 1
AuctionScreen.activeFilters       = {
    quality  = -1,
    minLevel = 0,
    maxLevel = 0,
    isUsable = 0,
}
AuctionScreen.scanResults         = {}
AuctionScreen.scanTotal           = 0

-- Hold-to-repeat
AuctionScreen.repeatDir           = nil
AuctionScreen.repeatElapsed       = 0
AuctionScreen.repeatDelay         = 0.35
AuctionScreen.repeatRate          = 0.08

-- ----------------------------------------------------------------------------
-- 4. HELPERS DE TIPOGRAFIA E 9-SLICE
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
-- 5. CRIAÇÃO DE ELEMENTOS DA INTERFACE (DIMMER, ABAS, HEADER, FOOTER)
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

    local lbIcon = tabContainer:CreateTexture(nil, "ARTWORK")
    lbIcon:SetWidth(26)
    lbIcon:SetHeight(26)
    lbIcon:SetTexture(ICONS.LB)
    lbIcon:SetPoint("LEFT", tabContainer, "LEFT", 0, 0)

    local tabButtons = {}
    local totalW = 26 + 10

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

function AuctionScreen:UpdateFooterHints()
    if not self.frame or not self.frame.footerContainer then return end
    local container = self.frame.footerContainer

    -- Destrói widgets antigos
    if self.footerWidgets then
        for i = 1, table.getn(self.footerWidgets) do
            self.footerWidgets[i]:Hide()
        end
    end

    local hints = {}
    if self.currentTab == "BUY" then
        if self.buyStep == "CATEGORIES" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_SELECT") })
            table.insert(hints, { icons = { "DALL" },     label = CM:T("AH_HINT_NAVIGATE") })
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_CLOSE") })
        elseif self.buyStep == "SUBCATEGORIES" or self.buyStep == "SLOTS" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_SELECT") })
            table.insert(hints, { icons = { "DALL" },     label = CM:T("AH_HINT_NAVIGATE") })
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_BACK") })
        elseif self.buyStep == "FILTERS" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_CONFIRM") })
            table.insert(hints, { icons = { "DLEFT", "DRIGHT" }, label = CM:T("AH_HINT_ADJUST") })
            table.insert(hints, { icons = { "X" },        label = CM:T("AH_HINT_CLEAR_FILTER") })
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_BACK") })
        elseif self.buyStep == "SCANNING" then
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_SCAN_ABORT") })
        elseif self.buyStep == "RESULTS_SUMMARY" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_SELECT") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_BACK") })
        end
    else
        table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_SELECT") })
        table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") })
        table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_CLOSE") })
    end

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
-- 6. ÁREA DE CONTEÚDO (BREADCRUMB, GRID, FILTROS, SCANNING)
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateContentArea(parent)
    local contentArea = CreateFrame("Frame", "ConsoleMode_AuctionContentArea", parent)
    contentArea:SetPoint("TOPLEFT", parent, "TOPLEFT", 28, -86)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 62)
    parent.contentArea = contentArea

    -- 1. Breadcrumb Bar
    local breadcrumb = CreateFrame("Frame", "ConsoleMode_AuctionBreadcrumb", contentArea)
    breadcrumb:SetHeight(28)
    breadcrumb:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 8, 0)
    breadcrumb:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", -8, 0)

    local bcText = breadcrumb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bcText:SetPoint("LEFT", breadcrumb, "LEFT", 4, 0)
    self:ApplyFont(bcText, FONTS.titleBold, 18)
    bcText:SetTextColor(0.95, 0.82, 0.35, 1.0)
    breadcrumb.text = bcText
    self.breadcrumb = breadcrumb

    -- 2. Container da Grade de Botões (Categorias, Subcategorias, Slots)
    local gridContainer = CreateFrame("Frame", "ConsoleMode_AuctionGridContainer", contentArea)
    gridContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -12)
    gridContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    self.gridContainer = gridContainer
    self.gridButtons = {}

    -- 3. Container da Tela de Filtros
    local filterContainer = CreateFrame("Frame", "ConsoleMode_AuctionFilterContainer", contentArea)
    filterContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -12)
    filterContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    filterContainer:Hide()
    self.filterContainer = filterContainer
    self:CreateFilterControls(filterContainer)

    -- 4. Container de Scan / Barra de Progresso
    local scanContainer = CreateFrame("Frame", "ConsoleMode_AuctionScanContainer", contentArea)
    scanContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -12)
    scanContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    scanContainer:Hide()
    self.scanContainer = scanContainer
    self:CreateScanControls(scanContainer)

    -- 5. Container de Resumo dos Resultados (Fase 1 finish state)
    local summaryContainer = CreateFrame("Frame", "ConsoleMode_AuctionSummaryContainer", contentArea)
    summaryContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -12)
    summaryContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    summaryContainer:Hide()
    self.summaryContainer = summaryContainer
    self:CreateSummaryControls(summaryContainer)
end

function AuctionScreen:UpdateBreadcrumb()
    if not self.breadcrumb or not self.breadcrumb.text then return end

    local sep = CM:T("AH_BREADCRUMB_SEP") or " > "
    local trail = CM:T("AH_TAB_BUY")

    if self.selectedCategory then
        local catName = CM:T(self.selectedCategory.labelKey) or self.selectedCategory.label or ""
        trail = trail .. sep .. catName
    end

    if self.selectedSubcategory then
        local subName = CM:T(self.selectedSubcategory.labelKey) or self.selectedSubcategory.label or ""
        trail = trail .. sep .. subName
    end

    if self.selectedSlot then
        local slotName = CM:T(self.selectedSlot.labelKey) or self.selectedSlot.label or ""
        trail = trail .. sep .. slotName
    end

    if self.buyStep == "FILTERS" then
        trail = trail .. sep .. CM:T("AH_FILTER_TITLE")
    elseif self.buyStep == "SCANNING" then
        trail = trail .. sep .. CM:T("AH_SEARCHING")
    end

    self.breadcrumb.text:SetText(trail)
end

-- ----------------------------------------------------------------------------
-- 7. GRADE DE SELEÇÃO DINÂMICA (CATEGORIAS / SUBCAT / SLOTS)
-- ----------------------------------------------------------------------------
function AuctionScreen:GetOrCreateGridButton(index)
    if self.gridButtons[index] then
        return self.gridButtons[index]
    end

    local btn = CreateFrame("Button", "ConsoleMode_AuctionGridBtn" .. index, self.gridContainer)
    btn:SetHeight(48)

    btn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 12, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", btn, "LEFT", 16, 0)
    label:SetPoint("RIGHT", btn, "RIGHT", -16, 0)
    label:SetJustifyH("LEFT")
    self:ApplyFont(label, FONTS.titleBold, 17)
    btn.label = label

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow:SetPoint("RIGHT", btn, "RIGHT", -14, 0)
    self:ApplyFont(arrow, FONTS.titleBold, 16)
    arrow:SetText(">")
    arrow:SetTextColor(0.60, 0.50, 0.30, 0.8)
    btn.arrow = arrow

    btn.btnIndex = index
    btn:SetScript("OnClick", function()
        AuctionScreen.gridIndex = this.btnIndex
        AuctionScreen:UpdateGridStyles()
        AuctionScreen:OnConfirm()
    end)

    self.gridButtons[index] = btn
    return btn
end

function AuctionScreen:PopulateGrid(items, columns)
    self.gridItems = items or {}
    self.gridColumns = columns or 2
    local totalItems = table.getn(self.gridItems)

    if self.gridIndex > totalItems then
        self.gridIndex = 1
    end
    if self.gridIndex < 1 and totalItems > 0 then
        self.gridIndex = 1
    end

    local containerW = self.gridContainer:GetWidth()
    if containerW < 100 then containerW = 800 end
    local gapX = 14
    local gapY = 10
    local btnW = math.floor((containerW - ((self.gridColumns - 1) * gapX)) / self.gridColumns)
    local btnH = 46

    -- Esconde botões extras
    for i = 1, table.getn(self.gridButtons) do
        self.gridButtons[i]:Hide()
    end

    for i = 1, totalItems do
        local item = self.gridItems[i]
        local btn = self:GetOrCreateGridButton(i)

        local row = math.floor((i - 1) / self.gridColumns)
        local col = math.mod(i - 1, self.gridColumns)

        local posX = col * (btnW + gapX)
        local posY = -row * (btnH + gapY)

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", self.gridContainer, "TOPLEFT", posX, posY)
        btn:SetWidth(btnW)
        btn:SetHeight(btnH)

        local text = CM:T(item.labelKey) or item.label or ""
        btn.label:SetText(text)
        btn:Show()
    end

    self:UpdateGridStyles()
end

function AuctionScreen:UpdateGridStyles()
    local totalItems = table.getn(self.gridItems)
    for i = 1, totalItems do
        local btn = self.gridButtons[i]
        if btn and btn:IsShown() then
            local isFocused = (i == self.gridIndex)
            if isFocused then
                btn:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
                btn:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
                btn.label:SetTextColor(1.0, 0.92, 0.45, 1.0)
                btn.arrow:SetTextColor(1.0, 0.85, 0.25, 1.0)
            else
                btn:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
                btn:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)
                btn.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
                btn.arrow:SetTextColor(0.50, 0.40, 0.25, 0.6)
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- 8. TELA DE FILTROS SALVOS INTELIGENTES
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateFilterControls(parent)
    local rows = {}
    local rowLabels = {
        CM:T("AH_FILTER_QUALITY"),
        CM:T("AH_FILTER_MIN_LEVEL"),
        CM:T("AH_FILTER_MAX_LEVEL"),
        CM:T("AH_FILTER_USABLE"),
    }

    local startY = -10
    local rowH = 46
    local rowGap = 10

    for i = 1, 4 do
        local row = CreateFrame("Button", "ConsoleMode_AuctionFilterRow" .. i, parent)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 60, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -60, startY - ((i - 1) * (rowH + rowGap)))

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 12, edgeSize = 12,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 }
        })

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", row, "LEFT", 20, 0)
        self:ApplyFont(lbl, FONTS.titleBold, 17)
        lbl:SetText(rowLabels[i])
        row.lbl = lbl

        local val = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        val:SetPoint("RIGHT", row, "RIGHT", -20, 0)
        self:ApplyFont(val, FONTS.titleBold, 17)
        row.val = val

        row.rowIndex = i
        row:SetScript("OnClick", function()
            AuctionScreen.filterRowIndex = this.rowIndex
            AuctionScreen:UpdateFilterStyles()
        end)

        table.insert(rows, row)
    end

    -- Botão INICIAR BUSCA (Row 5)
    local searchBtn = CreateFrame("Button", "ConsoleMode_AuctionFilterSearchBtn", parent)
    searchBtn:SetHeight(52)
    searchBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 60, startY - (4 * (rowH + rowGap)) - 14)
    searchBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -60, startY - (4 * (rowH + rowGap)) - 14)

    searchBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 12, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    local sLabel = searchBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    sLabel:SetPoint("CENTER", searchBtn, "CENTER", 0, 0)
    self:ApplyFont(sLabel, FONTS.titleBold, 20)
    sLabel:SetText(CM:T("AH_FILTER_BTN_SEARCH"))
    searchBtn.label = sLabel

    searchBtn.rowIndex = 5
    searchBtn:SetScript("OnClick", function()
        AuctionScreen.filterRowIndex = 5
        AuctionScreen:UpdateFilterStyles()
        AuctionScreen:ExecuteSearch()
    end)

    table.insert(rows, searchBtn)
    self.filterRows = rows
end

function AuctionScreen:GetCurrentCategoryKey()
    local classIdx = self.selectedCategory and self.selectedCategory.classIndex or 0
    local subIdx = self.selectedSubcategory and (self.selectedSubcategory.subClassIndex or 0) or 0
    local slotIdx = self.selectedSlot and (self.selectedSlot.slotIndex or self.selectedSlot.subClassIndex or 0) or 0
    return classIdx .. "_" .. subIdx .. "_" .. slotIdx
end

function AuctionScreen:LoadCategoryFilters()
    local catKey = self:GetCurrentCategoryKey()
    ConsoleModeDB = ConsoleModeDB or {}
    ConsoleModeDB.ahFilters = ConsoleModeDB.ahFilters or {}

    local saved = ConsoleModeDB.ahFilters[catKey]
    if saved then
        self.activeFilters.quality  = saved.quality or -1
        self.activeFilters.minLevel = saved.minLevel or 0
        self.activeFilters.maxLevel = saved.maxLevel or 0
        self.activeFilters.isUsable = saved.isUsable or 0
    else
        self.activeFilters.quality  = -1
        self.activeFilters.minLevel = 0
        self.activeFilters.maxLevel = 0
        self.activeFilters.isUsable = 0
    end
end

function AuctionScreen:SaveCategoryFilters()
    local catKey = self:GetCurrentCategoryKey()
    ConsoleModeDB = ConsoleModeDB or {}
    ConsoleModeDB.ahFilters = ConsoleModeDB.ahFilters or {}

    ConsoleModeDB.ahFilters[catKey] = {
        quality  = self.activeFilters.quality,
        minLevel = self.activeFilters.minLevel,
        maxLevel = self.activeFilters.maxLevel,
        isUsable = self.activeFilters.isUsable,
    }
end

function AuctionScreen:ResetCategoryFilters()
    self.activeFilters.quality  = -1
    self.activeFilters.minLevel = 0
    self.activeFilters.maxLevel = 0
    self.activeFilters.isUsable = 0
    self:SaveCategoryFilters()
    self:UpdateFilterStyles()
end

function AuctionScreen:UpdateFilterStyles()
    if not self.filterRows then return end

    -- 1. Qualidade
    local qKey = QUALITY_KEYS[self.activeFilters.quality] or "AH_QUALITY_ALL"
    local qName = CM:T(qKey) or "All"
    local qColor = QUALITY_COLORS[self.activeFilters.quality] or { 1, 1, 1 }
    self.filterRows[1].val:SetText("< " .. qName .. " >")
    self.filterRows[1].val:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

    -- 2. Min Level
    local minStr = (self.activeFilters.minLevel == 0) and CM:T("AH_LEVEL_ANY") or tostring(self.activeFilters.minLevel)
    self.filterRows[2].val:SetText("< " .. minStr .. " >")
    self.filterRows[2].val:SetTextColor(1.0, 0.85, 0.30, 1.0)

    -- 3. Max Level
    local maxStr = (self.activeFilters.maxLevel == 0) and CM:T("AH_LEVEL_ANY") or tostring(self.activeFilters.maxLevel)
    self.filterRows[3].val:SetText("< " .. maxStr .. " >")
    self.filterRows[3].val:SetTextColor(1.0, 0.85, 0.30, 1.0)

    -- 4. Usable Only
    local useStr = (self.activeFilters.isUsable == 1) and CM:T("AH_FILTER_YES") or CM:T("AH_FILTER_NO")
    self.filterRows[4].val:SetText("< " .. useStr .. " >")
    if self.activeFilters.isUsable == 1 then
        self.filterRows[4].val:SetTextColor(0.12, 1.0, 0.0, 1.0)
    else
        self.filterRows[4].val:SetTextColor(0.70, 0.70, 0.70, 1.0)
    end

    -- Destaque da linha focada
    for i = 1, 5 do
        local row = self.filterRows[i]
        local isFocused = (i == self.filterRowIndex)

        if i == 5 then
            -- Botão Iniciar Busca
            if isFocused then
                row:SetBackdropColor(0.35, 0.25, 0.10, 0.98)
                row:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
                row.label:SetTextColor(1.0, 0.95, 0.50, 1.0)
            else
                row:SetBackdropColor(0.14, 0.10, 0.06, 0.85)
                row:SetBackdropBorderColor(0.50, 0.40, 0.22, 0.75)
                row.label:SetTextColor(0.85, 0.75, 0.55, 0.90)
            end
        else
            if isFocused then
                row:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
                row:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
                row.lbl:SetTextColor(1.0, 0.90, 0.40, 1.0)
            else
                row:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
                row:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)
                row.lbl:SetTextColor(0.80, 0.80, 0.80, 0.90)
            end
        end
    end
end

function AuctionScreen:AdjustFilterValue(delta)
    if self.filterRowIndex == 1 then
        -- Ciclar Qualidade
        local currentIdx = 1
        local numQ = table.getn(QUALITY_ORDER)
        for i = 1, numQ do
            if QUALITY_ORDER[i] == self.activeFilters.quality then
                currentIdx = i
                break
            end
        end
        local nextIdx = currentIdx + delta
        if nextIdx < 1 then nextIdx = numQ end
        if nextIdx > numQ then nextIdx = 1 end
        self.activeFilters.quality = QUALITY_ORDER[nextIdx]
    elseif self.filterRowIndex == 2 then
        -- Min Level (0 a 60)
        local val = self.activeFilters.minLevel + delta
        if val < 0 then val = 0 end
        if val > 60 then val = 60 end
        if self.activeFilters.maxLevel > 0 and val > self.activeFilters.maxLevel then
            val = self.activeFilters.maxLevel
        end
        self.activeFilters.minLevel = val
    elseif self.filterRowIndex == 3 then
        -- Max Level (0 a 60)
        local val = self.activeFilters.maxLevel + delta
        if val < 0 then val = 0 end
        if val > 60 then val = 60 end
        if val > 0 and val < self.activeFilters.minLevel then
            val = self.activeFilters.minLevel
        end
        self.activeFilters.maxLevel = val
    elseif self.filterRowIndex == 4 then
        -- Usable Only (0 ou 1)
        if self.activeFilters.isUsable == 1 then
            self.activeFilters.isUsable = 0
        else
            self.activeFilters.isUsable = 1
        end
    end

    self:SaveCategoryFilters()
    self:UpdateFilterStyles()
end

-- ----------------------------------------------------------------------------
-- 9. TELA DE PROGRESSO DO SCAN
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateScanControls(parent)
    local statusText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    statusText:SetPoint("TOP", parent, "TOP", 0, -40)
    self:ApplyFont(statusText, FONTS.titleBold, 22)
    statusText:SetText(CM:T("AH_SEARCHING"))
    statusText:SetTextColor(1.0, 0.85, 0.25, 1.0)
    parent.statusText = statusText

    local pageText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pageText:SetPoint("TOP", statusText, "BOTTOM", 0, -12)
    self:ApplyFont(pageText, FONTS.bodyBold, 17)
    pageText:SetText("")
    parent.pageText = pageText

    local countText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countText:SetPoint("TOP", pageText, "BOTTOM", 0, -8)
    self:ApplyFont(countText, FONTS.medium, 16)
    countText:SetText("")
    countText:SetTextColor(0.80, 0.80, 0.80, 0.90)
    parent.countText = countText

    -- Barra de Progresso Visual
    local barBg = CreateFrame("Frame", "ConsoleMode_AuctionProgressBarBg", parent)
    barBg:SetWidth(420)
    barBg:SetHeight(22)
    barBg:SetPoint("TOP", countText, "BOTTOM", 0, -20)
    barBg:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    barBg:SetBackdropColor(0.06, 0.05, 0.04, 0.90)
    barBg:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.80)

    local barFill = barBg:CreateTexture(nil, "ARTWORK")
    barFill:SetHeight(16)
    barFill:SetPoint("LEFT", barBg, "LEFT", 3, 0)
    barFill:SetTexture(0.95, 0.78, 0.20, 0.95)
    barFill:SetWidth(10)
    barBg.fill = barFill
    parent.progressBar = barBg
end

function AuctionScreen:UpdateScanProgress(currentPage, totalPages, batchCount, totalCount)
    if not self.scanContainer then return end

    local pageFmt = CM:T("AH_SCAN_PAGE_FMT") or "Page %d of %d..."
    local foundFmt = CM:T("AH_SCAN_FOUND_FMT") or "%d auctions found."

    self.scanContainer.pageText:SetText(string.format(pageFmt, currentPage + 1, totalPages))
    self.scanContainer.countText:SetText(string.format(foundFmt, totalCount))

    local progress = (currentPage + 1) / totalPages
    if progress > 1.0 then progress = 1.0 end
    if progress < 0.02 then progress = 0.02 end

    local maxW = 420 - 6
    self.scanContainer.progressBar.fill:SetWidth(math.floor(maxW * progress))
end

-- ----------------------------------------------------------------------------
-- 10. TELA DE RESUMO DE RESULTADOS (Fase 1 Finish State)
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateSummaryControls(parent)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", parent, "TOP", 0, -40)
    self:ApplyFont(title, FONTS.titleBold, 24)
    title:SetText(CM:T("AH_TITLE"))
    title:SetTextColor(1.0, 0.85, 0.25, 1.0)
    parent.title = title

    local summaryText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    summaryText:SetPoint("TOP", title, "BOTTOM", 0, -16)
    self:ApplyFont(summaryText, FONTS.bodyBold, 18)
    summaryText:SetText("")
    parent.summaryText = summaryText

    -- Botões de ação pós-busca
    local btnContainer = CreateFrame("Frame", nil, parent)
    btnContainer:SetHeight(48)
    btnContainer:SetWidth(440)
    btnContainer:SetPoint("TOP", summaryText, "BOTTOM", 0, -32)

    local btn1 = CreateFrame("Button", "ConsoleMode_AuctionSummaryBtn1", btnContainer)
    btn1:SetWidth(200)
    btn1:SetHeight(44)
    btn1:SetPoint("LEFT", btnContainer, "LEFT", 10, 0)
    btn1:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    local l1 = btn1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    l1:SetPoint("CENTER", btn1, "CENTER", 0, 0)
    self:ApplyFont(l1, FONTS.titleBold, 16)
    l1:SetText(CM:T("AH_BTN_SEARCH_AGAIN"))
    btn1.label = l1
    btn1.idx = 1
    btn1:SetScript("OnClick", function()
        AuctionScreen.summaryBtnIndex = 1
        AuctionScreen:UpdateSummaryStyles()
        AuctionScreen:ExecuteSearch()
    end)

    local btn2 = CreateFrame("Button", "ConsoleMode_AuctionSummaryBtn2", btnContainer)
    btn2:SetWidth(200)
    btn2:SetHeight(44)
    btn2:SetPoint("RIGHT", btnContainer, "RIGHT", -10, 0)
    btn2:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    local l2 = btn2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    l2:SetPoint("CENTER", btn2, "CENTER", 0, 0)
    self:ApplyFont(l2, FONTS.titleBold, 16)
    l2:SetText(CM:T("AH_BTN_CHANGE_FILTERS"))
    btn2.label = l2
    btn2.idx = 2
    btn2:SetScript("OnClick", function()
        AuctionScreen.summaryBtnIndex = 2
        AuctionScreen:UpdateSummaryStyles()
        AuctionScreen:SetBuyStep("FILTERS")
    end)

    parent.btn1 = btn1
    parent.btn2 = btn2
end

function AuctionScreen:UpdateSummaryStyles()
    if not self.summaryContainer then return end
    local b1 = self.summaryContainer.btn1
    local b2 = self.summaryContainer.btn2

    if self.summaryBtnIndex == 1 then
        b1:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
        b1:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        b1.label:SetTextColor(1.0, 0.90, 0.40, 1.0)

        b2:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
        b2:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)
        b2.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
    else
        b2:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
        b2:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        b2.label:SetTextColor(1.0, 0.90, 0.40, 1.0)

        b1:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
        b1:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)
        b1.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
    end
end

-- ----------------------------------------------------------------------------
-- 11. CONTROLE DE PASSOS (FLOW DA ABA COMPRAR)
-- ----------------------------------------------------------------------------
function AuctionScreen:SetBuyStep(step)
    self.buyStep = step

    self.gridContainer:Hide()
    self.filterContainer:Hide()
    self.scanContainer:Hide()
    self.summaryContainer:Hide()

    if step == "CATEGORIES" then
        self.selectedCategory = nil
        self.selectedSubcategory = nil
        self.selectedSlot = nil
        self:PopulateGrid(CATEGORIES, 2)
        self.gridContainer:Show()
    elseif step == "SUBCATEGORIES" then
        self.selectedSubcategory = nil
        self.selectedSlot = nil
        if self.selectedCategory and self.selectedCategory.subcategories then
            self:PopulateGrid(self.selectedCategory.subcategories, 2)
            self.gridContainer:Show()
        else
            self:SetBuyStep("FILTERS")
            return
        end
    elseif step == "SLOTS" then
        self.selectedSlot = nil
        if self.selectedSubcategory and self.selectedSubcategory.slots then
            self:PopulateGrid(self.selectedSubcategory.slots, 2)
            self.gridContainer:Show()
        else
            self:SetBuyStep("FILTERS")
            return
        end
    elseif step == "FILTERS" then
        self:LoadCategoryFilters()
        self:UpdateFilterStyles()
        self.filterContainer:Show()
    elseif step == "SCANNING" then
        self.scanContainer:Show()
    elseif step == "RESULTS_SUMMARY" then
        local foundFmt = CM:T("AH_SCAN_FOUND_FMT") or "%d auctions found."
        self.summaryContainer.summaryText:SetText(string.format(foundFmt, self.scanTotal or 0))
        self.summaryBtnIndex = 1
        self:UpdateSummaryStyles()
        self.summaryContainer:Show()
    end

    self:UpdateBreadcrumb()
    self:UpdateFooterHints()
end

function AuctionScreen:ExecuteSearch()
    self:SetBuyStep("SCANNING")

    local classIdx = self.selectedCategory and self.selectedCategory.classIndex or 0
    local subIdx = 0
    local slotIdx = 0

    if self.selectedSubcategory then
        if self.selectedSubcategory.subClassIndex then
            subIdx = self.selectedSubcategory.subClassIndex
        end
    end

    if self.selectedSlot then
        if self.selectedSlot.slotIndex then
            slotIdx = self.selectedSlot.slotIndex
        elseif self.selectedSlot.subClassIndex then
            subIdx = self.selectedSlot.subClassIndex
        end
    end

    local queryParams = {
        name          = "",
        minLevel      = self.activeFilters.minLevel or 0,
        maxLevel      = self.activeFilters.maxLevel or 0,
        invTypeIndex  = slotIdx or 0,
        classIndex    = classIdx or 0,
        subClassIndex = subIdx or 0,
        isUsable      = self.activeFilters.isUsable or 0,
        qualityIndex  = self.activeFilters.quality or -1,
    }

    local scan = CM.auctionScan or ConsoleMode_AuctionScan
    if scan then
        scan:StartQuery(
            queryParams,
            function(currentPage, totalPages, batchCount, totalCount)
                AuctionScreen:UpdateScanProgress(currentPage, totalPages, batchCount, totalCount)
            end,
            function(results, totalCount, wasAborted)
                AuctionScreen.scanResults = results
                AuctionScreen.scanTotal = totalCount
                if wasAborted then
                    AuctionScreen:SetBuyStep("FILTERS")
                else
                    AuctionScreen:SetBuyStep("RESULTS_SUMMARY")
                end
            end,
            function(err)
                AuctionScreen:SetBuyStep("FILTERS")
            end
        )
    end
end

-- ----------------------------------------------------------------------------
-- 12. CRIAÇÃO DA INTERFACE PRINCIPAL
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

    -- Conteúdo Central Dinâmico
    self:CreateContentArea(frame)

    -- Footer Hints
    local footerContainer = CreateFrame("Frame", "ConsoleMode_AuctionFooterContainer", frame)
    footerContainer:SetHeight(34)
    footerContainer:SetPoint("CENTER", frame, "BOTTOM", 0, 28)
    frame.footerContainer = footerContainer

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
-- 13. NAVEGAÇÃO ENTRE ABAS
-- ----------------------------------------------------------------------------
function AuctionScreen:SetTab(tabKey)
    if self.currentTab == tabKey then return end
    self.currentTab = tabKey
    self:UpdateTabStyles()

    if tabKey == "BUY" then
        self:SetBuyStep("CATEGORIES")
    else
        -- Abas SELL e OWNER serão implementadas nas fases seguintes
        self.gridContainer:Hide()
        self.filterContainer:Hide()
        self.scanContainer:Hide()
        self.summaryContainer:Hide()
        if self.breadcrumb and self.breadcrumb.text then
            local tabLabel = (tabKey == "SELL") and CM:T("AH_TAB_SELL") or CM:T("AH_TAB_MY_AUCTIONS")
            self.breadcrumb.text:SetText(tabLabel)
        end
        self:UpdateFooterHints()
    end
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
-- 14. MAPEAMENTO DE BOTÕES DO CONTROLE (A, B, X, Y, D-PAD)
-- ----------------------------------------------------------------------------
function AuctionScreen:OnDirection(direction)
    if not self.isOpen then return end

    if self.currentTab == "BUY" then
        if self.buyStep == "CATEGORIES" or self.buyStep == "SUBCATEGORIES" or self.buyStep == "SLOTS" then
            local total = table.getn(self.gridItems)
            if total <= 0 then return end

            local cols = self.gridColumns or 2
            local cur = self.gridIndex

            if direction == "UP" then
                if cur > cols then
                    cur = cur - cols
                end
            elseif direction == "DOWN" then
                if cur + cols <= total then
                    cur = cur + cols
                end
            elseif direction == "LEFT" then
                if cur > 1 then
                    cur = cur - 1
                end
            elseif direction == "RIGHT" then
                if cur < total then
                    cur = cur + 1
                end
            end

            self.gridIndex = cur
            self:UpdateGridStyles()
        elseif self.buyStep == "FILTERS" then
            if direction == "UP" then
                self.filterRowIndex = self.filterRowIndex - 1
                if self.filterRowIndex < 1 then self.filterRowIndex = 5 end
                self:UpdateFilterStyles()
            elseif direction == "DOWN" then
                self.filterRowIndex = self.filterRowIndex + 1
                if self.filterRowIndex > 5 then self.filterRowIndex = 1 end
                self:UpdateFilterStyles()
            elseif direction == "LEFT" then
                self:AdjustFilterValue(-1)
            elseif direction == "RIGHT" then
                self:AdjustFilterValue(1)
            end
        elseif self.buyStep == "RESULTS_SUMMARY" then
            if direction == "LEFT" or direction == "UP" then
                self.summaryBtnIndex = 1
                self:UpdateSummaryStyles()
            elseif direction == "RIGHT" or direction == "DOWN" then
                self.summaryBtnIndex = 2
                self:UpdateSummaryStyles()
            end
        end
    end
end

function AuctionScreen:OnConfirm()
    if not self.isOpen then return end

    if self.currentTab == "BUY" then
        if self.buyStep == "CATEGORIES" then
            local item = self.gridItems[self.gridIndex]
            if not item then return end
            self.selectedCategory = item

            if item.hasSubcategories then
                self.gridIndex = 1
                self:SetBuyStep("SUBCATEGORIES")
            else
                self.filterRowIndex = 1
                self:SetBuyStep("FILTERS")
            end
        elseif self.buyStep == "SUBCATEGORIES" then
            local item = self.gridItems[self.gridIndex]
            if not item then return end
            self.selectedSubcategory = item

            if item.hasSlots then
                self.gridIndex = 1
                self:SetBuyStep("SLOTS")
            else
                self.filterRowIndex = 1
                self:SetBuyStep("FILTERS")
            end
        elseif self.buyStep == "SLOTS" then
            local item = self.gridItems[self.gridIndex]
            if not item then return end
            self.selectedSlot = item

            self.filterRowIndex = 1
            self:SetBuyStep("FILTERS")
        elseif self.buyStep == "FILTERS" then
            if self.filterRowIndex == 5 then
                self:ExecuteSearch()
            elseif self.filterRowIndex == 4 then
                self:AdjustFilterValue(1)
            else
                self:AdjustFilterValue(1)
            end
        elseif self.buyStep == "RESULTS_SUMMARY" then
            if self.summaryBtnIndex == 1 then
                self:ExecuteSearch()
            else
                self:SetBuyStep("FILTERS")
            end
        end
    end
end

function AuctionScreen:OnSecondaryAction()
    if not self.isOpen then return end

    if self.currentTab == "BUY" and self.buyStep == "FILTERS" then
        -- Botão X: Limpar Filtros
        self:ResetCategoryFilters()
    end
end

function AuctionScreen:OnContextAction()
    if not self.isOpen then return end
    -- Botão Y (Reservado para Teclado Virtual na Fase 3)
end

function AuctionScreen:OnCancel()
    if not self.isOpen then return end

    if self.currentTab == "BUY" then
        if self.buyStep == "SCANNING" then
            local scan = CM.auctionScan or ConsoleMode_AuctionScan
            if scan then scan:AbortQuery() end
            self:SetBuyStep("FILTERS")
            return
        elseif self.buyStep == "RESULTS_SUMMARY" then
            self:SetBuyStep("FILTERS")
            return
        elseif self.buyStep == "FILTERS" then
            if self.selectedSlot then
                self.selectedSlot = nil
                self.gridIndex = 1
                self:SetBuyStep("SLOTS")
            elseif self.selectedSubcategory then
                self.selectedSubcategory = nil
                self.gridIndex = 1
                self:SetBuyStep("SUBCATEGORIES")
            else
                self.selectedCategory = nil
                self.gridIndex = 1
                self:SetBuyStep("CATEGORIES")
            end
            return
        elseif self.buyStep == "SLOTS" then
            self.selectedSlot = nil
            self.gridIndex = 1
            self:SetBuyStep("SUBCATEGORIES")
            return
        elseif self.buyStep == "SUBCATEGORIES" then
            self.selectedSubcategory = nil
            self.gridIndex = 1
            self:SetBuyStep("CATEGORIES")
            return
        elseif self.buyStep == "CATEGORIES" then
            self:Close()
            return
        end
    else
        self:Close()
    end
end

-- ----------------------------------------------------------------------------
-- 15. REPEAT DE D-PAD (HOLD-TO-REPEAT)
-- ----------------------------------------------------------------------------
function AuctionScreen:StartRepeat(direction)
    self:OnDirection(direction)
    self.repeatDir = direction
    self.repeatElapsed = 0
end

function AuctionScreen:StopRepeat(direction)
    if self.repeatDir == direction then
        self.repeatDir = nil
        self.repeatElapsed = 0
    end
end

-- ----------------------------------------------------------------------------
-- 16. ABERTURA E FECHAMENTO
-- ----------------------------------------------------------------------------
function AuctionScreen:Open()
    if not self.initialized then
        self:CreateUI()
    end

    if CM.LoadDataLake then
        pcall(function() CM:LoadDataLake("AuctionScreen") end)
    end

    if AuctionFrame and AuctionFrame:IsVisible() then
        AuctionFrame:Hide()
    end

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
    self:SetTab("BUY")
    self:SetBuyStep("CATEGORIES")

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

    local scan = CM.auctionScan or ConsoleMode_AuctionScan
    if scan and scan.isScanning then
        scan:AbortQuery()
    end

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

-- ----------------------------------------------------------------------------
-- 17. GANCHOS DE EVENTO (AUCTION_HOUSE_SHOW / AUCTION_HOUSE_CLOSED)
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

    ef:SetScript("OnUpdate", function()
        if AuctionScreen.isOpen and AuctionScreen.repeatDir then
            AuctionScreen.repeatElapsed = AuctionScreen.repeatElapsed + arg1
            if AuctionScreen.repeatElapsed >= AuctionScreen.repeatDelay then
                AuctionScreen:OnDirection(AuctionScreen.repeatDir)
                AuctionScreen.repeatElapsed = AuctionScreen.repeatDelay - AuctionScreen.repeatRate
            end
        end
    end)

    self.eventFrame = ef
end

AuctionScreen:InitEvents()
