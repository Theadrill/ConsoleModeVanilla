-- ============================================================================
-- ConsoleModeVanilla - UI/AuctionScreen.lua
-- Tela de Leilão (Auction House) para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE 0: Fundação, Moldura 9-Slice, Abas e Hook de Abertura
-- FASE 1: Aba Comprar — Categorias, Navegação D-Pad, Filtros Salvos e Scan
-- FASE 2: Lista de Itens Agrupados, Detalhe do Leilão e Compra Fiel
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
    GOLD   = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_gold.tga",
    SILVER = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_silver.tga",
    COPPER = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_copper.tga",
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

local TIME_LEFT_KEYS = {
    [1] = "AH_TIME_SHORT",
    [2] = "AH_TIME_MEDIUM",
    [3] = "AH_TIME_LONG",
    [4] = "AH_TIME_VERY_LONG",
}

local TABS = {
    { key = "BUY",   labelKey = "AH_TAB_BUY" },
    { key = "SELL",  labelKey = "AH_TAB_SELL" },
    { key = "OWNER", labelKey = "AH_TAB_MY_AUCTIONS" }
}

local SORT_OPTIONS = {
    { key = "PRICE_UNIT_ASC",  labelKey = "AH_SORT_PRICE_UNIT_ASC" },
    { key = "PRICE_UNIT_DESC", labelKey = "AH_SORT_PRICE_UNIT_DESC" },
    { key = "BUYOUT_ASC",      labelKey = "AH_SORT_BUYOUT_ASC" },
    { key = "NAME_ASC",        labelKey = "AH_SORT_NAME_ASC" },
    { key = "NAME_DESC",       labelKey = "AH_SORT_NAME_DESC" },
    { key = "LEVEL_ASC",       labelKey = "AH_SORT_LEVEL_ASC" },
    { key = "LEVEL_DESC",      labelKey = "AH_SORT_LEVEL_DESC" },
    { key = "QUALITY_DESC",    labelKey = "AH_SORT_QUALITY_DESC" },
    { key = "QUALITY_ASC",     labelKey = "AH_SORT_QUALITY_ASC" },
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
AuctionScreen.buyStep             = "CATEGORIES" -- "CATEGORIES", "SUBCATEGORIES", "SLOTS", "FILTERS", "SCANNING", "ITEMS_LIST", "ITEM_DETAIL", "NO_RESULTS"
AuctionScreen.selectedCategory    = nil
AuctionScreen.selectedSubcategory = nil
AuctionScreen.selectedSlot        = nil
AuctionScreen.gridIndex           = 1
AuctionScreen.gridColumns         = 2
AuctionScreen.gridItems           = {}
AuctionScreen.filterRowIndex      = 1
AuctionScreen.summaryBtnIndex     = 1
AuctionScreen.activeFilters       = {
    name     = "",
    quality  = -1,
    minLevel = 0,
    maxLevel = 0,
    isUsable = 0,
}
AuctionScreen.scanResults         = {}
AuctionScreen.scanTotal           = 0

-- FASE 2: Estados de Itens Agrupados, Detalhes e Compra
AuctionScreen.groupedItems          = {}
AuctionScreen.selectedItemIndex     = 1
AuctionScreen.itemListScrollOffset  = 0
AuctionScreen.selectedGroupedItem   = nil
AuctionScreen.selectedAuctionIndex  = 1
AuctionScreen.itemDetailScrollOffset= 0
AuctionScreen.isConfirmModalOpen    = false
AuctionScreen.targetAuction         = nil
AuctionScreen.isBuyoutAction        = true

-- FASE 4: Estados de Ordenação / Classificar Por
AuctionScreen.isSortModalOpen       = false
AuctionScreen.selectedSortIndex     = 1
AuctionScreen.currentSortType       = "PRICE_UNIT_ASC"

-- Hold-to-repeat
AuctionScreen.repeatDir           = nil
AuctionScreen.repeatElapsed       = 0
AuctionScreen.repeatDelay         = 0.35
AuctionScreen.repeatRate          = 0.08

-- ----------------------------------------------------------------------------
-- 4. HELPERS DE FORMATAÇÃO, TIPOGRAFIA E 9-SLICE
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
    slices.bottom:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPLEFT", 0, 0)

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

function AuctionScreen:FormatMoney(totalCopper)
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

function AuctionScreen:CreateMoneyDisplay(parent, height, iconSize, align)
    height = height or 22
    iconSize = iconSize or 14
    align = align or "RIGHT"

    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(height)
    f:SetWidth(180)
    if parent and parent.GetFrameLevel then
        f:SetFrameLevel(parent:GetFrameLevel() + 5)
    end
    f.align = align
    f.iconSize = iconSize

    -- Copper
    local copperIcon = f:CreateTexture(nil, "OVERLAY")
    copperIcon:SetWidth(iconSize)
    copperIcon:SetHeight(iconSize)
    copperIcon:SetTexture(ICONS.COPPER)
    f.copperIcon = copperIcon

    local copperText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:ApplyFont(copperText, FONTS.bodyBold, 15)
    f.copperText = copperText

    -- Silver
    local silverIcon = f:CreateTexture(nil, "OVERLAY")
    silverIcon:SetWidth(iconSize)
    silverIcon:SetHeight(iconSize)
    silverIcon:SetTexture(ICONS.SILVER)
    f.silverIcon = silverIcon

    local silverText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:ApplyFont(silverText, FONTS.bodyBold, 15)
    f.silverText = silverText

    -- Gold
    local goldIcon = f:CreateTexture(nil, "OVERLAY")
    goldIcon:SetWidth(iconSize)
    goldIcon:SetHeight(iconSize)
    goldIcon:SetTexture(ICONS.GOLD)
    f.goldIcon = goldIcon

    local goldText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:ApplyFont(goldText, FONTS.bodyBold, 15)
    f.goldText = goldText

    -- None/Empty label (ex: "-" quando não há buyout)
    local noneText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self:ApplyFont(noneText, FONTS.bodyBold, 15)
    noneText:SetText("-")
    noneText:SetTextColor(0.60, 0.60, 0.60, 0.80)
    noneText:Hide()
    f.noneText = noneText

    return f
end

function AuctionScreen:SetMoneyDisplay(f, totalCopper)
    if not f then return end

    if not totalCopper or totalCopper <= 0 then
        f.goldIcon:Hide()
        f.goldText:Hide()
        f.silverIcon:Hide()
        f.silverText:Hide()
        f.copperIcon:Hide()
        f.copperText:Hide()
        f.noneText:ClearAllPoints()
        if f.align == "LEFT" then
            f.noneText:SetPoint("LEFT", f, "LEFT", 0, 0)
        else
            f.noneText:SetPoint("RIGHT", f, "RIGHT", 0, 0)
        end
        f.noneText:Show()
        return
    end

    f.noneText:Hide()

    local gold   = math.floor(totalCopper / 10000)
    local silver = math.floor(math.mod(totalCopper, 10000) / 100)
    local copper = math.floor(math.mod(totalCopper, 100))

    local showGold   = (gold > 0)
    local showSilver = (gold > 0 or silver > 0)
    local showCopper = true

    f.copperText:SetText(tostring(copper))
    f.copperText:Show()
    f.copperIcon:Show()

    if showSilver then
        f.silverText:SetText(tostring(silver))
        f.silverText:Show()
        f.silverIcon:Show()
    else
        f.silverText:Hide()
        f.silverIcon:Hide()
    end

    if showGold then
        f.goldText:SetText(tostring(gold))
        f.goldText:Show()
        f.goldIcon:Show()
    else
        f.goldText:Hide()
        f.goldIcon:Hide()
    end

    if f.align == "LEFT" then
        local prev = nil
        if showGold then
            f.goldText:ClearAllPoints()
            f.goldText:SetPoint("LEFT", f, "LEFT", 0, 0)
            f.goldIcon:ClearAllPoints()
            f.goldIcon:SetPoint("LEFT", f.goldText, "RIGHT", 2, 0)
            prev = f.goldIcon
        end

        if showSilver then
            f.silverText:ClearAllPoints()
            if prev then
                f.silverText:SetPoint("LEFT", prev, "RIGHT", 6, 0)
            else
                f.silverText:SetPoint("LEFT", f, "LEFT", 0, 0)
            end
            f.silverIcon:ClearAllPoints()
            f.silverIcon:SetPoint("LEFT", f.silverText, "RIGHT", 2, 0)
            prev = f.silverIcon
        end

        f.copperText:ClearAllPoints()
        if prev then
            f.copperText:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        else
            f.copperText:SetPoint("LEFT", f, "LEFT", 0, 0)
        end
        f.copperIcon:ClearAllPoints()
        f.copperIcon:SetPoint("LEFT", f.copperText, "RIGHT", 2, 0)
    else
        -- ALIGN RIGHT (Tabelas)
        f.copperIcon:ClearAllPoints()
        f.copperIcon:SetPoint("RIGHT", f, "RIGHT", 0, 0)
        f.copperText:ClearAllPoints()
        f.copperText:SetPoint("RIGHT", f.copperIcon, "LEFT", -2, 0)

        local prev = f.copperText
        if showSilver then
            f.silverIcon:ClearAllPoints()
            f.silverIcon:SetPoint("RIGHT", prev, "LEFT", -6, 0)
            f.silverText:ClearAllPoints()
            f.silverText:SetPoint("RIGHT", f.silverIcon, "LEFT", -2, 0)
            prev = f.silverText
        end

        if showGold then
            f.goldIcon:ClearAllPoints()
            f.goldIcon:SetPoint("RIGHT", prev, "LEFT", -6, 0)
            f.goldText:ClearAllPoints()
            f.goldText:SetPoint("RIGHT", f.goldIcon, "LEFT", -2, 0)
        end
    end
end

function AuctionScreen:GetItemVendorPrice(itemLink)
    if not itemLink then return 0 end
    local _, _, idStr = string.find(itemLink, "item:(%d+)")
    local itemID = tonumber(idStr)
    if not itemID then return 0 end

    if ConsoleMode_SellValues and ConsoleMode_SellValues[itemID] then
        return ConsoleMode_SellValues[itemID]
    elseif ShaguTweaks and ShaguTweaks.SellValueDB and ShaguTweaks.SellValueDB[itemID] then
        return ShaguTweaks.SellValueDB[itemID]
    elseif ShaguValueDB and ShaguValueDB[itemID] then
        return ShaguValueDB[itemID]
    elseif GetSellValue then
        return GetSellValue(itemLink) or 0
    elseif GetItemSellValue then
        return GetItemSellValue(itemLink) or 0
    end
    return 0
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

    if self.footerWidgets then
        for i = 1, table.getn(self.footerWidgets) do
            self.footerWidgets[i]:Hide()
        end
    end

    local hints = {}
    if self.isConfirmModalOpen then
        table.insert(hints, { icons = { "A" }, label = CM:T("AH_HINT_CONFIRM") })
        table.insert(hints, { icons = { "B" }, label = CM:T("AH_BTN_CANCEL") })
    elseif self.isSortModalOpen then
        table.insert(hints, { icons = { "A" }, label = CM:T("AH_HINT_SELECT") })
        table.insert(hints, { icons = { "DUP", "DDOWN" }, label = CM:T("AH_HINT_NAVIGATE") })
        table.insert(hints, { icons = { "B" }, label = CM:T("AH_BTN_CANCEL") })
    elseif self.currentTab == "BUY" then
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
            if self.filterRowIndex == 1 then
                table.insert(hints, { icons = { "A", "Y" }, label = CM:T("AH_HINT_TYPE_NAME") })
                table.insert(hints, { icons = { "X" },      label = CM:T("AH_HINT_CLEAR_NAME") })
            elseif self.filterRowIndex == 6 then
                table.insert(hints, { icons = { "A" },      label = CM:T("AH_HINT_SEARCH") })
            else
                table.insert(hints, { icons = { "DLEFT", "DRIGHT" }, label = CM:T("AH_HINT_ADJUST") })
                table.insert(hints, { icons = { "X" },      label = CM:T("AH_HINT_CLEAR_FILTER") })
            end
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_BACK") })
        elseif self.buyStep == "SCANNING" then
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_SCAN_ABORT") })
        elseif self.buyStep == "ITEMS_LIST" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_SELECT") })
            table.insert(hints, { icons = { "Y" },        label = CM:T("AH_HINT_SORT") })
            table.insert(hints, { icons = { "DALL" },     label = CM:T("AH_HINT_NAVIGATE") })
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_BACK") })
        elseif self.buyStep == "ITEM_DETAIL" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_BTN_BUYOUT") })
            table.insert(hints, { icons = { "Y" },        label = CM:T("AH_BTN_BID") })
            table.insert(hints, { icons = { "DALL" },     label = CM:T("AH_HINT_NAVIGATE") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_BACK") })
        elseif self.buyStep == "NO_RESULTS" or self.buyStep == "RESULTS_SUMMARY" then
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
-- 6. ÁREA DE CONTEÚDO (BREADCRUMB, GRID, FILTROS, SCANNING, LISTA, DETALHE)
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

    -- 5. Container de Resumo / Sem Resultados
    local summaryContainer = CreateFrame("Frame", "ConsoleMode_AuctionSummaryContainer", contentArea)
    summaryContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -12)
    summaryContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    summaryContainer:Hide()
    self.summaryContainer = summaryContainer
    self:CreateSummaryControls(summaryContainer)

    -- 6. Container da Lista de Itens Agrupados (FASE 2)
    local itemListContainer = CreateFrame("Frame", "ConsoleMode_AuctionItemListContainer", contentArea)
    itemListContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -8)
    itemListContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    itemListContainer:Hide()
    self.itemListContainer = itemListContainer
    self:CreateItemListControls(itemListContainer)

    -- 7. Container de Detalhes do Item Selecionado (FASE 2)
    local itemDetailContainer = CreateFrame("Frame", "ConsoleMode_AuctionItemDetailContainer", contentArea)
    itemDetailContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -8)
    itemDetailContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    itemDetailContainer:Hide()
    self.itemDetailContainer = itemDetailContainer
    self:CreateItemDetailControls(itemDetailContainer)

    -- 8. Modal de Confirmação de Compra (FASE 2)
    self:CreateConfirmModal(parent)

    -- 9. Modal de Ordenação / Classificar Por (FASE 4)
    self:CreateSortModal(parent)
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
    elseif self.buyStep == "ITEMS_LIST" then
        trail = trail .. sep .. "Resultados"
    elseif self.buyStep == "ITEM_DETAIL" then
        trail = trail .. sep .. "Resultados"
        if self.selectedGroupedItem and self.selectedGroupedItem.name then
            trail = trail .. sep .. self.selectedGroupedItem.name
        end
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
-- ----------------------------------------------------------------------------
-- 7b. INTEGRAÇÃO COM TECLADO VIRTUAL E HISTÓRICO RECENTE (FASE 3)
-- ----------------------------------------------------------------------------
function AuctionScreen:IsVKOpen()
    local vk = ConsoleMode and ConsoleMode.VirtualKeyboard
    if vk and vk.IsOpen then
        local ok, open = pcall(function() return vk:IsOpen() end)
        if ok and open then return true end
    end
    return false
end

function AuctionScreen:OpenFilterSearchVK()
    local vk = ConsoleMode and ConsoleMode.VirtualKeyboard
    if vk and vk.Open then
        vk:Open({
            title         = CM:T("AH_VK_SEARCH_TITLE") or "Buscar Item no Leilão",
            initialText   = self.activeFilters.name or "",
            maxLetters    = 32,
            onConfirm     = function(text)
                AuctionScreen.activeFilters.name = text or ""
                AuctionScreen:SaveCategoryFilters()
                AuctionScreen:UpdateFilterStyles()
                if text and text ~= "" then
                    AuctionScreen:AddRecentSearch(text)
                end
            end,
            onCancel      = function() end,
        })
    end
end

function AuctionScreen:AddRecentSearch(searchTerm)
    if not searchTerm or searchTerm == "" then return end
    ConsoleModeDB = ConsoleModeDB or {}
    ConsoleModeDB.ahRecentSearches = ConsoleModeDB.ahRecentSearches or {}

    local list = ConsoleModeDB.ahRecentSearches
    local filtered = {}
    local numList = table.getn(list)
    for i = 1, numList do
        if string.lower(list[i]) ~= string.lower(searchTerm) then
            table.insert(filtered, list[i])
        end
    end
    table.insert(filtered, 1, searchTerm)
    while table.getn(filtered) > 10 do
        table.remove(filtered)
    end
    ConsoleModeDB.ahRecentSearches = filtered
end

-- 8. TELA DE FILTROS SALVOS INTELIGENTES
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateFilterControls(parent)
    local rows = {}
    local rowLabels = {
        CM:T("AH_FILTER_ITEM_NAME"),
        CM:T("AH_FILTER_QUALITY"),
        CM:T("AH_FILTER_MIN_LEVEL"),
        CM:T("AH_FILTER_MAX_LEVEL"),
        CM:T("AH_FILTER_USABLE"),
    }

    local startY = -6
    local rowH = 44
    local rowGap = 8

    for i = 1, 5 do
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
            if this.rowIndex == 1 then
                AuctionScreen:OpenFilterSearchVK()
            end
        end)

        table.insert(rows, row)
    end

    -- Botão INICIAR BUSCA (Row 6)
    local searchBtn = CreateFrame("Button", "ConsoleMode_AuctionFilterSearchBtn", parent)
    searchBtn:SetHeight(50)
    searchBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 60, startY - (5 * (rowH + rowGap)) - 10)
    searchBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -60, startY - (5 * (rowH + rowGap)) - 10)

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

    searchBtn.rowIndex = 6
    searchBtn:SetScript("OnClick", function()
        AuctionScreen.filterRowIndex = 6
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
        self.activeFilters.name     = saved.name or ""
        self.activeFilters.quality  = saved.quality or -1
        self.activeFilters.minLevel = saved.minLevel or 0
        self.activeFilters.maxLevel = saved.maxLevel or 0
        self.activeFilters.isUsable = saved.isUsable or 0
    else
        self.activeFilters.name     = ""
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
        name     = self.activeFilters.name or "",
        quality  = self.activeFilters.quality,
        minLevel = self.activeFilters.minLevel,
        maxLevel = self.activeFilters.maxLevel,
        isUsable = self.activeFilters.isUsable,
    }
end

function AuctionScreen:ResetCategoryFilters()
    self.activeFilters.name     = ""
    self.activeFilters.quality  = -1
    self.activeFilters.minLevel = 0
    self.activeFilters.maxLevel = 0
    self.activeFilters.isUsable = 0

    self:SaveCategoryFilters()
    self:UpdateFilterStyles()
end

function AuctionScreen:UpdateFilterStyles()
    if not self.filterRows then return end

    local qKey = QUALITY_KEYS[self.activeFilters.quality] or "AH_QUALITY_ALL"
    local qName = CM:T(qKey) or "All"
    local minLvlStr = (self.activeFilters.minLevel > 0) and tostring(self.activeFilters.minLevel) or CM:T("AH_LEVEL_ANY")
    local maxLvlStr = (self.activeFilters.maxLevel > 0) and tostring(self.activeFilters.maxLevel) or CM:T("AH_LEVEL_ANY")
    local usableStr = (self.activeFilters.isUsable == 1) and CM:T("AH_FILTER_YES") or CM:T("AH_FILTER_NO")

    -- Row 1: Termo de Busca / Nome do Item
    local nameVal = (self.activeFilters.name and self.activeFilters.name ~= "") and ('"' .. self.activeFilters.name .. '"') or CM:T("AH_FILTER_ENTER_NAME")
    local row1 = self.filterRows[1]
    if row1 then
        row1.val:SetText(nameVal)
        if self.activeFilters.name and self.activeFilters.name ~= "" then
            row1.val:SetTextColor(1.0, 0.90, 0.35, 1.0)
        else
            row1.val:SetTextColor(0.60, 0.60, 0.60, 0.80)
        end
    end

    -- Row 2: Qualidade / Raridade
    local row2 = self.filterRows[2]
    if row2 then
        row2.val:SetText("< " .. qName .. " >")
        local qColor = QUALITY_COLORS[self.activeFilters.quality]
        if qColor then
            row2.val:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)
        else
            row2.val:SetTextColor(0.90, 0.90, 0.90, 1.0)
        end
    end

    -- Row 3: Nível Mín
    local row3 = self.filterRows[3]
    if row3 then
        row3.val:SetText("< " .. minLvlStr .. " >")
        row3.val:SetTextColor(0.90, 0.90, 0.90, 1.0)
    end

    -- Row 4: Nível Máx
    local row4 = self.filterRows[4]
    if row4 then
        row4.val:SetText("< " .. maxLvlStr .. " >")
        row4.val:SetTextColor(0.90, 0.90, 0.90, 1.0)
    end

    -- Row 5: Usável
    local row5 = self.filterRows[5]
    if row5 then
        row5.val:SetText("< " .. usableStr .. " >")
        if self.activeFilters.isUsable == 1 then
            row5.val:SetTextColor(0.12, 1.0, 0.0, 1.0)
        else
            row5.val:SetTextColor(0.90, 0.90, 0.90, 1.0)
        end
    end

    -- Focus Highlights para todas as 6 linhas
    for i = 1, 6 do
        local row = self.filterRows[i]
        if row then
            local isFocused = (i == self.filterRowIndex)
            if i == 6 then
                if isFocused then
                    row:SetBackdropColor(0.35, 0.28, 0.12, 0.95)
                    row:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
                    row.label:SetTextColor(1.0, 0.95, 0.50, 1.0)
                else
                    row:SetBackdropColor(0.16, 0.12, 0.08, 0.85)
                    row:SetBackdropBorderColor(0.60, 0.48, 0.30, 0.70)
                    row.label:SetTextColor(0.85, 0.78, 0.60, 0.90)
                end
            else
                if isFocused then
                    row:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
                    row:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
                    row.lbl:SetTextColor(1.0, 0.92, 0.45, 1.0)
                else
                    row:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
                    row:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)
                    row.lbl:SetTextColor(0.80, 0.80, 0.80, 0.90)
                end
            end
        end
    end

    self:UpdateFooterHints()
end

function AuctionScreen:AdjustFilterValue(delta)
    if self.filterRowIndex == 1 then
        self:OpenFilterSearchVK()
    elseif self.filterRowIndex == 2 then
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
    elseif self.filterRowIndex == 3 then
        local val = self.activeFilters.minLevel + delta
        if val < 0 then val = 0 end
        if val > 60 then val = 60 end
        if self.activeFilters.maxLevel > 0 and val > self.activeFilters.maxLevel then
            val = self.activeFilters.maxLevel
        end
        self.activeFilters.minLevel = val
    elseif self.filterRowIndex == 4 then
        local val = self.activeFilters.maxLevel + delta
        if val < 0 then val = 0 end
        if val > 60 then val = 60 end
        if val > 0 and val < self.activeFilters.minLevel then
            val = self.activeFilters.minLevel
        end
        self.activeFilters.maxLevel = val
    elseif self.filterRowIndex == 5 then
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
-- 10. TELA DE RESUMO / SEM RESULTADOS
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
-- 11. FASE 2: LISTA DE ITENS AGRUPADOS (ITEMS_LIST)
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateItemListControls(parent)
    local headerFrame = CreateFrame("Frame", nil, parent)
    headerFrame:SetHeight(24)
    headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, 0)
    headerFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, 0)

    local colItem = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colItem:SetPoint("LEFT", headerFrame, "LEFT", 44, 0)
    self:ApplyFont(colItem, FONTS.titleBold, 15)
    colItem:SetText(CM:T("AH_COL_ITEM"))
    colItem:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colLevel = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colLevel:SetPoint("LEFT", headerFrame, "LEFT", 380, 0)
    self:ApplyFont(colLevel, FONTS.titleBold, 15)
    colLevel:SetText(CM:T("AH_COL_LEVEL"))
    colLevel:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colAuctions = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colAuctions:SetPoint("LEFT", headerFrame, "LEFT", 460, 0)
    self:ApplyFont(colAuctions, FONTS.titleBold, 15)
    colAuctions:SetText(CM:T("AH_COL_AUCTIONS_QTY") or "QTD LEILÕES")
    colAuctions:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colPrice = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colPrice:SetPoint("RIGHT", headerFrame, "RIGHT", -120, 0)
    self:ApplyFont(colPrice, FONTS.titleBold, 15)
    colPrice:SetText(CM:T("AH_COL_STARTING_FROM") or "A PARTIR DE")
    colPrice:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colVendor = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colVendor:SetPoint("RIGHT", headerFrame, "RIGHT", -16, 0)
    self:ApplyFont(colVendor, FONTS.titleBold, 15)
    colVendor:SetText(CM:T("AH_COL_VENDOR_PCT") or "% VENDOR")
    colVendor:SetTextColor(0.70, 0.65, 0.55, 1.0)

    -- Pool de 7 linhas visíveis
    local rows = {}
    local startY = -28
    local rowH = 46
    local rowGap = 6

    for i = 1, 7 do
        local row = CreateFrame("Button", "ConsoleMode_AuctionItemRow" .. i, parent)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, startY - ((i - 1) * (rowH + rowGap)))

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 10, edgeSize = 10,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        -- Ícone
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(34)
        icon:SetHeight(34)
        icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.icon = icon

        -- Nome do Item
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", icon, "RIGHT", 10, 0)
        nameText:SetWidth(320)
        nameText:SetJustifyH("LEFT")
        self:ApplyFont(nameText, FONTS.titleBold, 17)
        row.nameText = nameText

        -- Nível
        local lvlText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lvlText:SetPoint("LEFT", row, "LEFT", 380, 0)
        self:ApplyFont(lvlText, FONTS.bodyBold, 16)
        lvlText:SetTextColor(0.90, 0.90, 0.90, 1.0)
        row.lvlText = lvlText

        -- Quantidade de Leilões
        local countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countText:SetPoint("LEFT", row, "LEFT", 460, 0)
        self:ApplyFont(countText, FONTS.medium, 16)
        countText:SetTextColor(0.80, 0.80, 0.80, 0.90)
        row.countText = countText

        -- Preço Mínimo (com ícones de moedas)
        local priceDisplay = self:CreateMoneyDisplay(row, 24, 14, "RIGHT")
        priceDisplay:SetPoint("RIGHT", row, "RIGHT", -120, 0)
        row.priceDisplay = priceDisplay

        -- % Vendor
        local vendorText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        vendorText:SetPoint("RIGHT", row, "RIGHT", -16, 0)
        self:ApplyFont(vendorText, FONTS.titleBold, 15)
        row.vendorText = vendorText

        row.rowIdx = i
        row:SetScript("OnClick", function()
            local itemIndex = AuctionScreen.itemListScrollOffset + this.rowIdx
            AuctionScreen.selectedItemIndex = itemIndex
            AuctionScreen:UpdateItemList()
            AuctionScreen:OnConfirm()
        end)

        table.insert(rows, row)
    end

    -- Indicador de Posição (Ex: "Item 1 de 24")
    local posIndicator = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    posIndicator:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, -26)
    self:ApplyFont(posIndicator, FONTS.medium, 15)
    posIndicator:SetTextColor(0.65, 0.65, 0.65, 1.0)
    parent.posIndicator = posIndicator

    self.itemListRows = rows
end

function AuctionScreen:GroupScanResults()
    local grouped = {}
    local groupsByKey = {}
    local results = self.scanResults or {}
    local numResults = table.getn(results)

    for i = 1, numResults do
        local r = results[i]
        local key = r.name or "Unknown"
        if r.link then
            local _, _, id = string.find(r.link, "item:(%d+)")
            if id then key = id end
        end

        if not groupsByKey[key] then
            local vendorPrice = self:GetItemVendorPrice(r.link)
            local group = {
                key         = key,
                name        = r.name or "Unknown",
                texture     = r.texture or "Interface\\Icons\\INV_Misc_QuestionMark",
                quality     = r.quality or 0,
                level       = r.level or 0,
                link        = r.link,
                vendorPrice = vendorPrice,
                minBuyout   = r.buyoutPrice or 0,
                minBid      = r.minBid or r.bidAmount or 0,
                totalUnits  = r.count or 1,
                numAuctions = 1,
                auctions    = { r }
            }
            groupsByKey[key] = group
            table.insert(grouped, group)
        else
            local group = groupsByKey[key]
            table.insert(group.auctions, r)
            group.numAuctions = group.numAuctions + 1
            group.totalUnits = group.totalUnits + (r.count or 1)

            if r.buyoutPrice and r.buyoutPrice > 0 then
                if group.minBuyout == 0 or r.buyoutPrice < group.minBuyout then
                    group.minBuyout = r.buyoutPrice
                end
            end
            if r.minBid and r.minBid > 0 then
                if group.minBid == 0 or r.minBid < group.minBid then
                    group.minBid = r.minBid
                end
            end
        end
    end

    -- Ordena leilões dentro de cada grupo por menor preço de buyout
    for i = 1, table.getn(grouped) do
        local g = grouped[i]
        table.sort(g.auctions, function(a, b)
            local priceA = (a.buyoutPrice and a.buyoutPrice > 0) and a.buyoutPrice or 99999999
            local priceB = (b.buyoutPrice and b.buyoutPrice > 0) and b.buyoutPrice or 99999999
            return priceA < priceB
        end)
    end

    self.groupedItems = grouped
    self:ApplySort(self.currentSortType or "PRICE_UNIT_ASC")
end

function AuctionScreen:UpdateItemList()
    if not self.itemListRows then return end

    local totalItems = table.getn(self.groupedItems)
    local offset = self.itemListScrollOffset or 0

    for i = 1, 7 do
        local row = self.itemListRows[i]
        local itemIdx = offset + i

        if itemIdx <= totalItems then
            local item = self.groupedItems[itemIdx]
            local isFocused = (itemIdx == self.selectedItemIndex)

            row.icon:SetTexture(item.texture)
            local qColor = QUALITY_COLORS[item.quality] or { 1, 1, 1 }
            row.nameText:SetText(item.name)
            row.nameText:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

            local lvlStr = (item.level and item.level > 0) and tostring(item.level) or "-"
            row.lvlText:SetText(lvlStr)

            local countStr = string.format(CM:T("AH_COUNT_AUCTIONS_FMT") or "(%d leilões)", item.numAuctions)
            row.countText:SetText(countStr)

            local priceVal = (item.minBuyout and item.minBuyout > 0) and item.minBuyout or item.minBid
            self:SetMoneyDisplay(row.priceDisplay, priceVal)

            if item.vendorPrice and item.vendorPrice > 0 and priceVal and priceVal > 0 then
                local pct = math.floor((priceVal / item.vendorPrice) * 100)
                row.vendorText:SetText(pct .. "%")
                if pct <= 100 then
                    row.vendorText:SetTextColor(0.12, 1.0, 0.0, 1.0)
                else
                    row.vendorText:SetTextColor(1.0, 0.82, 0.20, 1.0)
                end
            else
                row.vendorText:SetText("-")
                row.vendorText:SetTextColor(0.60, 0.60, 0.60, 0.8)
            end

            if isFocused then
                row:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
                row:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
            else
                row:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
                row:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)
            end

            row:Show()
        else
            row:Hide()
        end
    end

    if self.itemListContainer and self.itemListContainer.posIndicator then
        if totalItems > 0 then
            self.itemListContainer.posIndicator:SetText(string.format("Item %d de %d", self.selectedItemIndex, totalItems))
        else
            self.itemListContainer.posIndicator:SetText("")
        end
    end
end

function AuctionScreen:ScrollItemList(delta)
    local total = table.getn(self.groupedItems)
    if total <= 0 then return end

    local newIdx = self.selectedItemIndex + delta
    if newIdx < 1 then newIdx = 1 end
    if newIdx > total then newIdx = total end

    self.selectedItemIndex = newIdx

    if self.selectedItemIndex <= self.itemListScrollOffset then
        self.itemListScrollOffset = self.selectedItemIndex - 1
    elseif self.selectedItemIndex > self.itemListScrollOffset + 7 then
        self.itemListScrollOffset = self.selectedItemIndex - 7
    end

    self:UpdateItemList()
end

-- ----------------------------------------------------------------------------
-- 12. FASE 2: TELA DE DETALHES DO ITEM (ITEM_DETAIL)
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateItemDetailControls(parent)
    -- Top Card do Item Selecionado
    local topCard = CreateFrame("Frame", nil, parent)
    topCard:SetHeight(52)
    topCard:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, 0)
    topCard:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, 0)
    topCard:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 10, edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    topCard:SetBackdropColor(0.12, 0.09, 0.06, 0.90)
    topCard:SetBackdropBorderColor(0.60, 0.48, 0.30, 0.85)

    local icon = topCard:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(40)
    icon:SetHeight(40)
    icon:SetPoint("LEFT", topCard, "LEFT", 8, 0)
    topCard.icon = icon

    local nameText = topCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    nameText:SetPoint("LEFT", icon, "RIGHT", 12, 4)
    self:ApplyFont(nameText, FONTS.titleBold, 20)
    topCard.nameText = nameText

    local subText = topCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subText:SetPoint("LEFT", icon, "RIGHT", 12, -14)
    self:ApplyFont(subText, FONTS.bodyBold, 15)
    subText:SetTextColor(0.80, 0.80, 0.80, 0.90)
    topCard.subText = subText

    local vendorLabel = topCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self:ApplyFont(vendorLabel, FONTS.bodyBold, 15)
    vendorLabel:SetTextColor(0.80, 0.80, 0.80, 0.90)
    vendorLabel:SetText("  •  " .. (CM:T("AH_VENDOR_PRICE_LABEL") or "Vendor:") .. " ")
    vendorLabel:Hide()
    topCard.vendorLabel = vendorLabel

    local vendorDisplay = self:CreateMoneyDisplay(topCard, 18, 13, "LEFT")
    vendorDisplay:Hide()
    topCard.vendorDisplay = vendorDisplay

    parent.topCard = topCard

    -- Cabeçalho da Tabela de Leilões
    local tableHeader = CreateFrame("Frame", nil, parent)
    tableHeader:SetHeight(22)
    tableHeader:SetPoint("TOPLEFT", topCard, "BOTTOMLEFT", 0, -8)
    tableHeader:SetPoint("TOPRIGHT", topCard, "BOTTOMRIGHT", 0, -8)

    local colSeller = tableHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colSeller:SetPoint("LEFT", tableHeader, "LEFT", 16, 0)
    self:ApplyFont(colSeller, FONTS.titleBold, 15)
    colSeller:SetText(CM:T("AH_COL_SELLER"))
    colSeller:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colStack = tableHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colStack:SetPoint("LEFT", tableHeader, "LEFT", 220, 0)
    self:ApplyFont(colStack, FONTS.titleBold, 15)
    colStack:SetText(CM:T("AH_COL_STACK") or "STACK")
    colStack:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colTime = tableHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colTime:SetPoint("LEFT", tableHeader, "LEFT", 340, 0)
    self:ApplyFont(colTime, FONTS.titleBold, 15)
    colTime:SetText(CM:T("AH_COL_TIME_LEFT"))
    colTime:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colBid = tableHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colBid:SetPoint("RIGHT", tableHeader, "RIGHT", -180, 0)
    self:ApplyFont(colBid, FONTS.titleBold, 15)
    colBid:SetText(CM:T("AH_COL_BID"))
    colBid:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colBuyout = tableHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colBuyout:SetPoint("RIGHT", tableHeader, "RIGHT", -16, 0)
    self:ApplyFont(colBuyout, FONTS.titleBold, 15)
    colBuyout:SetText(CM:T("AH_COL_BUYOUT"))
    colBuyout:SetTextColor(0.70, 0.65, 0.55, 1.0)

    -- Pool de 6 linhas de leilão individual
    local rows = {}
    local startY = -86
    local rowH = 46
    local rowGap = 6

    for i = 1, 6 do
        local row = CreateFrame("Button", "ConsoleMode_AuctionDetailRow" .. i, parent)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, startY - ((i - 1) * (rowH + rowGap)))

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 10, edgeSize = 10,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        local sellerText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        sellerText:SetPoint("LEFT", row, "LEFT", 16, 0)
        self:ApplyFont(sellerText, FONTS.titleBold, 16)
        row.sellerText = sellerText

        local stackText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        stackText:SetPoint("LEFT", row, "LEFT", 220, 0)
        self:ApplyFont(stackText, FONTS.titleBold, 17)
        stackText:SetTextColor(1.0, 0.90, 0.40, 1.0)
        row.stackText = stackText

        local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        timeText:SetPoint("LEFT", row, "LEFT", 340, 0)
        self:ApplyFont(timeText, FONTS.medium, 15)
        timeText:SetTextColor(0.80, 0.80, 0.80, 0.90)
        row.timeText = timeText

        local bidDisplay = self:CreateMoneyDisplay(row, 24, 14, "RIGHT")
        bidDisplay:SetPoint("RIGHT", row, "RIGHT", -180, 0)
        row.bidDisplay = bidDisplay

        local buyoutDisplay = self:CreateMoneyDisplay(row, 24, 14, "RIGHT")
        buyoutDisplay:SetPoint("RIGHT", row, "RIGHT", -16, 0)
        row.buyoutDisplay = buyoutDisplay

        row.rowIdx = i
        row:SetScript("OnClick", function()
            local auctionIdx = AuctionScreen.itemDetailScrollOffset + this.rowIdx
            AuctionScreen.selectedAuctionIndex = auctionIdx
            AuctionScreen:UpdateItemDetail()
            AuctionScreen:OnConfirm()
        end)

        table.insert(rows, row)
    end

    local posIndicator = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    posIndicator:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, -26)
    self:ApplyFont(posIndicator, FONTS.medium, 15)
    posIndicator:SetTextColor(0.65, 0.65, 0.65, 1.0)
    parent.posIndicator = posIndicator

    self.itemDetailRows = rows
end

function AuctionScreen:UpdateItemDetail()
    if not self.itemDetailRows or not self.selectedGroupedItem then return end

    local item = self.selectedGroupedItem
    local topCard = self.itemDetailContainer.topCard
    if topCard then
        topCard.icon:SetTexture(item.texture)
        local qColor = QUALITY_COLORS[item.quality] or { 1, 1, 1 }
        topCard.nameText:SetText(item.name)
        topCard.nameText:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

        local subInfo = string.format("Nível: %s  •  Total de Leilões: %d", (item.level and item.level > 0) and tostring(item.level) or "-", item.numAuctions or 1)
        topCard.subText:SetText(subInfo)

        if item.vendorPrice and item.vendorPrice > 0 then
            topCard.vendorLabel:ClearAllPoints()
            topCard.vendorLabel:SetPoint("LEFT", topCard.subText, "RIGHT", 4, 0)
            topCard.vendorLabel:Show()

            topCard.vendorDisplay:ClearAllPoints()
            topCard.vendorDisplay:SetPoint("LEFT", topCard.vendorLabel, "RIGHT", 2, 0)
            self:SetMoneyDisplay(topCard.vendorDisplay, item.vendorPrice)
            topCard.vendorDisplay:Show()
        else
            topCard.vendorLabel:Hide()
            topCard.vendorDisplay:Hide()
        end
    end

    local auctions = item.auctions or {}
    local totalAuctions = table.getn(auctions)
    local offset = self.itemDetailScrollOffset or 0

    for i = 1, 6 do
        local row = self.itemDetailRows[i]
        local auctionIdx = offset + i

        if auctionIdx <= totalAuctions then
            local a = auctions[auctionIdx]
            local isFocused = (auctionIdx == self.selectedAuctionIndex)

            row.sellerText:SetText(a.owner or "Desconhecido")
            row.stackText:SetText("x" .. (a.count or 1))

            local timeKey = TIME_LEFT_KEYS[a.timeLeft] or "AH_TIME_SHORT"
            row.timeText:SetText(CM:T(timeKey) or "")

            local bidVal = (a.bidAmount and a.bidAmount > 0) and a.bidAmount or (a.minBid or 0)
            self:SetMoneyDisplay(row.bidDisplay, bidVal)

            self:SetMoneyDisplay(row.buyoutDisplay, a.buyoutPrice)

            if isFocused then
                row:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
                row:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
            else
                row:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
                row:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)
            end

            row:Show()
        else
            row:Hide()
        end
    end

    if self.itemDetailContainer and self.itemDetailContainer.posIndicator then
        if totalAuctions > 0 then
            self.itemDetailContainer.posIndicator:SetText(string.format("Leilão %d de %d", self.selectedAuctionIndex, totalAuctions))
        else
            self.itemDetailContainer.posIndicator:SetText("")
        end
    end
end

function AuctionScreen:ScrollItemDetail(delta)
    if not self.selectedGroupedItem then return end
    local total = table.getn(self.selectedGroupedItem.auctions or {})
    if total <= 0 then return end

    local newIdx = self.selectedAuctionIndex + delta
    if newIdx < 1 then newIdx = 1 end
    if newIdx > total then newIdx = total end

    self.selectedAuctionIndex = newIdx

    if self.selectedAuctionIndex <= self.itemDetailScrollOffset then
        self.itemDetailScrollOffset = self.selectedAuctionIndex - 1
    elseif self.selectedAuctionIndex > self.itemDetailScrollOffset + 6 then
        self.itemDetailScrollOffset = self.selectedAuctionIndex - 6
    end

    self:UpdateItemDetail()
end

-- ----------------------------------------------------------------------------
-- 13. FASE 2: MODAL DE CONFIRMAÇÃO DE COMPRA (9-SLICE)
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateConfirmModal(parent)
    local modalDimmer = CreateFrame("Frame", "ConsoleMode_AuctionModalDimmer", parent)
    modalDimmer:SetFrameStrata("DIALOG")
    modalDimmer:SetFrameLevel(45)
    modalDimmer:SetAllPoints(UIParent)
    modalDimmer:EnableMouse(true)
    modalDimmer:Hide()

    local bg = modalDimmer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(modalDimmer)
    bg:SetTexture(0, 0, 0, 0.70)
    modalDimmer.bg = bg

    local modal = CreateFrame("Frame", "ConsoleMode_AuctionConfirmModal", modalDimmer)
    modal:SetWidth(480)
    modal:SetHeight(280)
    modal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(50)
    modal:EnableMouse(true)

    self:Create9Slice(modal, NINESLICE.texture, NINESLICE.cornerSize, NINESLICE.uv, NINESLICE.drawLayer)

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -20)
    self:ApplyFont(title, FONTS.titleBold, 22)
    title:SetTextColor(1.0, 0.85, 0.25, 1.0)
    modal.title = title

    local itemIcon = modal:CreateTexture(nil, "ARTWORK")
    itemIcon:SetWidth(38)
    itemIcon:SetHeight(38)
    itemIcon:SetPoint("TOPLEFT", modal, "TOPLEFT", 28, -60)
    modal.itemIcon = itemIcon

    local itemName = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemName:SetPoint("LEFT", itemIcon, "RIGHT", 12, 0)
    itemName:SetPoint("RIGHT", modal, "RIGHT", -28, 0)
    itemName:SetJustifyH("LEFT")
    self:ApplyFont(itemName, FONTS.titleBold, 18)
    modal.itemName = itemName

    -- Linha 1: Preço da Transação
    local priceLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    priceLabel:SetPoint("TOPLEFT", itemIcon, "BOTTOMLEFT", 0, -16)
    self:ApplyFont(priceLabel, FONTS.bodyBold, 16)
    priceLabel:SetTextColor(0.95, 0.82, 0.35, 1.0)
    modal.priceLabel = priceLabel

    local priceDisplay = self:CreateMoneyDisplay(modal, 20, 15, "LEFT")
    priceDisplay:SetPoint("LEFT", priceLabel, "RIGHT", 8, 0)
    modal.priceDisplay = priceDisplay

    -- Linha 2: Seu Dinheiro
    local myMoneyLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    myMoneyLabel:SetPoint("TOPLEFT", priceLabel, "BOTTOMLEFT", 0, -10)
    self:ApplyFont(myMoneyLabel, FONTS.medium, 15)
    myMoneyLabel:SetTextColor(0.75, 0.75, 0.75, 1.0)
    myMoneyLabel:SetText(CM:T("AH_MODAL_YOUR_MONEY") or "Seu Dinheiro:")
    modal.myMoneyLabel = myMoneyLabel

    local myMoneyDisplay = self:CreateMoneyDisplay(modal, 20, 14, "LEFT")
    myMoneyDisplay:SetPoint("LEFT", myMoneyLabel, "RIGHT", 8, 0)
    modal.myMoneyDisplay = myMoneyDisplay

    -- Linha 3: Saldo Restante
    local remainingLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    remainingLabel:SetPoint("TOPLEFT", myMoneyLabel, "BOTTOMLEFT", 0, -10)
    self:ApplyFont(remainingLabel, FONTS.medium, 15)
    remainingLabel:SetTextColor(0.75, 0.75, 0.75, 1.0)
    remainingLabel:SetText(CM:T("AH_MODAL_REMAINING") or "Saldo Restante:")
    modal.remainingLabel = remainingLabel

    local remainingDisplay = self:CreateMoneyDisplay(modal, 20, 14, "LEFT")
    remainingDisplay:SetPoint("LEFT", remainingLabel, "RIGHT", 8, 0)
    modal.remainingDisplay = remainingDisplay

    -- Linha 4: Aviso de Fundos Insuficientes
    local warningText = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warningText:SetPoint("TOPLEFT", remainingLabel, "BOTTOMLEFT", 0, -8)
    self:ApplyFont(warningText, FONTS.titleBold, 15)
    warningText:SetTextColor(1.0, 0.20, 0.20, 1.0)
    warningText:SetText("")
    modal.warningText = warningText

    -- Botões Confirmar / Cancelar
    local btnContainer = CreateFrame("Frame", nil, modal)
    btnContainer:SetHeight(40)
    btnContainer:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 24, 20)
    btnContainer:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -24, 20)

    local btnConfirm = CreateFrame("Button", "ConsoleMode_AuctionModalConfirmBtn", btnContainer)
    btnConfirm:SetWidth(190)
    btnConfirm:SetHeight(38)
    btnConfirm:SetPoint("LEFT", btnContainer, "LEFT", 10, 0)
    btnConfirm:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btnConfirm:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
    btnConfirm:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)

    local lConf = btnConfirm:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lConf:SetPoint("CENTER", btnConfirm, "CENTER", 0, 0)
    self:ApplyFont(lConf, FONTS.titleBold, 16)
    lConf:SetText(CM:T("AH_HINT_CONFIRM"))
    btnConfirm.label = lConf
    btnConfirm:SetScript("OnClick", function()
        AuctionScreen:ExecutePurchase()
    end)
    modal.btnConfirm = btnConfirm

    local btnCancel = CreateFrame("Button", "ConsoleMode_AuctionModalCancelBtn", btnContainer)
    btnCancel:SetWidth(190)
    btnCancel:SetHeight(38)
    btnCancel:SetPoint("RIGHT", btnContainer, "RIGHT", -10, 0)
    btnCancel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btnCancel:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
    btnCancel:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)

    local lCanc = btnCancel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lCanc:SetPoint("CENTER", btnCancel, "CENTER", 0, 0)
    self:ApplyFont(lCanc, FONTS.titleBold, 16)
    lCanc:SetText(CM:T("AH_BTN_CANCEL"))
    btnCancel.label = lCanc
    btnCancel:SetScript("OnClick", function()
        AuctionScreen:CloseConfirmModal()
    end)
    modal.btnCancel = btnCancel

    self.modalDimmer = modalDimmer
    self.confirmModal = modal
end

function AuctionScreen:OpenConfirmModal(auction, isBuyout)
    if not auction or not self.confirmModal then return end

    self.targetAuction = auction
    self.isBuyoutAction = isBuyout
    self.isConfirmModalOpen = true

    local m = self.confirmModal
    local price = isBuyout and (auction.buyoutPrice or 0) or (auction.minBid or auction.bidAmount or 0)
    local myMoney = GetMoney() or 0

    if isBuyout then
        m.title:SetText(CM:T("AH_BUYOUT_CONFIRM_TITLE"))
        m.priceLabel:SetText(CM:T("AH_MODAL_BUYOUT_LABEL") or "Preço de Compra:")
    else
        m.title:SetText(CM:T("AH_BID_CONFIRM_TITLE"))
        m.priceLabel:SetText(CM:T("AH_MODAL_BID_LABEL") or "Valor do Lance:")
    end

    self:SetMoneyDisplay(m.priceDisplay, price)
    self:SetMoneyDisplay(m.myMoneyDisplay, myMoney)

    m.itemIcon:SetTexture(auction.texture)
    local qColor = QUALITY_COLORS[auction.quality] or { 1, 1, 1 }
    m.itemName:SetText(auction.name .. " (x" .. (auction.count or 1) .. ")")
    m.itemName:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

    if myMoney < price then
        m.remainingLabel:Hide()
        m.remainingDisplay:Hide()
        m.warningText:SetText(CM:T("AH_MSG_CANNOT_AFFORD"))
        m.btnConfirm:Disable()
        m.btnConfirm:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        m.btnConfirm:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.5)
        m.btnConfirm.label:SetTextColor(0.5, 0.5, 0.5, 1.0)
    else
        local remaining = myMoney - price
        m.remainingLabel:Show()
        m.remainingDisplay:Show()
        self:SetMoneyDisplay(m.remainingDisplay, remaining)
        m.warningText:SetText("")
        m.btnConfirm:Enable()
        m.btnConfirm:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
        m.btnConfirm:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        m.btnConfirm.label:SetTextColor(1.0, 0.90, 0.40, 1.0)
    end

    self.modalDimmer:Show()
    self:UpdateFooterHints()
end

function AuctionScreen:CloseConfirmModal()
    if not self.isConfirmModalOpen then return end

    self.isConfirmModalOpen = false
    self.targetAuction = nil
    if self.modalDimmer then
        self.modalDimmer:Hide()
    end
    self:UpdateFooterHints()
end

-- ----------------------------------------------------------------------------
-- 13.5. FASE 4: MODAL DE ORDENAÇÃO / CLASSIFICAR POR (SORT MODAL)
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateSortModal(parent)
    local sortDimmer = CreateFrame("Frame", "ConsoleMode_AuctionSortModalDimmer", self.frame)
    sortDimmer:SetAllPoints(self.frame)
    sortDimmer:SetFrameStrata("DIALOG")
    sortDimmer:SetFrameLevel(45)
    sortDimmer:EnableMouse(true)
    sortDimmer:Hide()

    local bg = sortDimmer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(sortDimmer)
    bg:SetTexture(0, 0, 0, 0.70)
    sortDimmer.bg = bg

    local modal = CreateFrame("Frame", "ConsoleMode_AuctionSortModal", sortDimmer)
    modal:SetWidth(460)
    modal:SetHeight(420)
    modal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(50)
    modal:EnableMouse(true)

    self:Create9Slice(modal, NINESLICE.texture, NINESLICE.cornerSize, NINESLICE.uv, NINESLICE.drawLayer)

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -20)
    self:ApplyFont(title, FONTS.titleBold, 22)
    title:SetTextColor(1.0, 0.85, 0.25, 1.0)
    title:SetText(CM:T("AH_SORT_TITLE"))
    modal.title = title

    local sub = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -6)
    self:ApplyFont(sub, FONTS.medium, 14)
    sub:SetTextColor(0.70, 0.65, 0.55, 1.0)
    sub:SetText(CM:T("AH_SORT_HINT"))
    modal.sub = sub

    local optRows = {}
    local startY = -68
    local rowH = 32
    local rowGap = 4
    local numOpts = table.getn(SORT_OPTIONS)

    for i = 1, numOpts do
        local opt = SORT_OPTIONS[i]
        local row = CreateFrame("Button", "ConsoleMode_AuctionSortRow" .. i, modal)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", modal, "TOPLEFT", 28, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -28, startY - ((i - 1) * (rowH + rowGap)))

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", row, "LEFT", 12, 0)
        self:ApplyFont(lbl, FONTS.medium, 15)
        lbl:SetText(CM:T(opt.labelKey))
        row.lbl = lbl

        local activeTag = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        activeTag:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        self:ApplyFont(activeTag, FONTS.titleBold, 13)
        activeTag:SetTextColor(0.12, 1.0, 0.0, 1.0)
        activeTag:SetText(CM:T("AH_SORT_ACTIVE"))
        activeTag:Hide()
        row.activeTag = activeTag

        row.optKey = opt.key
        local idx = i
        row:SetScript("OnClick", function()
            AuctionScreen.selectedSortIndex = idx
            local o = SORT_OPTIONS[idx]
            if o then
                AuctionScreen:ApplySort(o.key)
            end
            AuctionScreen:CloseSortModal()
        end)

        table.insert(optRows, row)
    end

    modal.rows = optRows
    self.sortModalDimmer = sortDimmer
    self.sortModal = modal
end

function AuctionScreen:UpdateSortModalStyles()
    if not self.sortModal or not self.sortModal.rows then return end

    local numOpts = table.getn(SORT_OPTIONS)
    for i = 1, numOpts do
        local row = self.sortModal.rows[i]
        local opt = SORT_OPTIONS[i]
        if row and opt then
            local isFocused = (i == self.selectedSortIndex)
            local isActive = (opt.key == self.currentSortType)

            if isActive then
                row.activeTag:Show()
            else
                row.activeTag:Hide()
            end

            if isFocused then
                row:SetBackdropColor(0.24, 0.18, 0.10, 0.95)
                row:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
                row.lbl:SetTextColor(1.0, 0.92, 0.45, 1.0)
            else
                row:SetBackdropColor(0.09, 0.07, 0.05, 0.80)
                row:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.65)
                if isActive then
                    row.lbl:SetTextColor(0.95, 0.85, 0.40, 0.90)
                else
                    row.lbl:SetTextColor(0.80, 0.80, 0.80, 0.90)
                end
            end
        end
    end
end

function AuctionScreen:OpenSortModal()
    if not self.sortModal then return end

    self.selectedSortIndex = 1
    local numOpts = table.getn(SORT_OPTIONS)
    for i = 1, numOpts do
        if SORT_OPTIONS[i].key == self.currentSortType then
            self.selectedSortIndex = i
            break
        end
    end

    self.isSortModalOpen = true
    self:UpdateSortModalStyles()
    self.sortModalDimmer:Show()
    self:UpdateFooterHints()
end

function AuctionScreen:CloseSortModal()
    if not self.isSortModalOpen then return end

    self.isSortModalOpen = false
    if self.sortModalDimmer then
        self.sortModalDimmer:Hide()
    end
    self:UpdateFooterHints()
end

function AuctionScreen:ApplySort(sortType)
    self.currentSortType = sortType or "PRICE_UNIT_ASC"
    if not self.groupedItems or table.getn(self.groupedItems) == 0 then return end

    local currentType = self.currentSortType
    table.sort(self.groupedItems, function(a, b)
        if currentType == "PRICE_UNIT_ASC" then
            local pA = (a.minBuyout and a.minBuyout > 0) and a.minBuyout or (a.minBid or 99999999)
            local pB = (b.minBuyout and b.minBuyout > 0) and b.minBuyout or (b.minBid or 99999999)
            if pA ~= pB then return pA < pB end
            if a.name ~= b.name then return (a.name or "") < (b.name or "") end
            return false
        elseif currentType == "PRICE_UNIT_DESC" then
            local pA = (a.minBuyout and a.minBuyout > 0) and a.minBuyout or (a.minBid or 0)
            local pB = (b.minBuyout and b.minBuyout > 0) and b.minBuyout or (b.minBid or 0)
            if pA ~= pB then return pA > pB end
            if a.name ~= b.name then return (a.name or "") < (b.name or "") end
            return false
        elseif currentType == "BUYOUT_ASC" then
            local pA = (a.minBuyout and a.minBuyout > 0) and a.minBuyout or 99999999
            local pB = (b.minBuyout and b.minBuyout > 0) and b.minBuyout or 99999999
            if pA ~= pB then return pA < pB end
            if a.name ~= b.name then return (a.name or "") < (b.name or "") end
            return false
        elseif currentType == "NAME_ASC" then
            if a.name ~= b.name then return (a.name or "") < (b.name or "") end
            return false
        elseif currentType == "NAME_DESC" then
            if a.name ~= b.name then return (a.name or "") > (b.name or "") end
            return false
        elseif currentType == "LEVEL_ASC" then
            local lA = a.level or 0
            local lB = b.level or 0
            if lA ~= lB then return lA < lB end
            if a.name ~= b.name then return (a.name or "") < (b.name or "") end
            return false
        elseif currentType == "LEVEL_DESC" then
            local lA = a.level or 0
            local lB = b.level or 0
            if lA ~= lB then return lA > lB end
            if a.name ~= b.name then return (a.name or "") < (b.name or "") end
            return false
        elseif currentType == "QUALITY_DESC" then
            local qA = a.quality or 0
            local qB = b.quality or 0
            if qA ~= qB then return qA > qB end
            if a.name ~= b.name then return (a.name or "") < (b.name or "") end
            return false
        elseif currentType == "QUALITY_ASC" then
            local qA = a.quality or 0
            local qB = b.quality or 0
            if qA ~= qB then return qA < qB end
            if a.name ~= b.name then return (a.name or "") < (b.name or "") end
            return false
        end
        if a.name ~= b.name then return (a.name or "") < (b.name or "") end
        return false
    end)

    self.selectedItemIndex = 1
    self.itemListScrollOffset = 0
    if self.buyStep == "ITEMS_LIST" then
        self:UpdateItemList()
    end
end

function AuctionScreen:ExecutePurchase()
    local auction = self.targetAuction
    if not auction then return end

    local isBuyout = self.isBuyoutAction
    local price = isBuyout and (auction.buyoutPrice or 0) or (auction.minBid or auction.bidAmount or 0)
    local myMoney = GetMoney() or 0

    if myMoney < price then
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("AH_MSG_CANNOT_AFFORD"))
        return
    end

    PlaceAuctionBid("list", auction.index, price)

    if isBuyout then
        local msg = string.format(CM:T("AH_MSG_BUYOUT_SUCCESS_FMT"), auction.name or "")
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    else
        local msg = string.format(CM:T("AH_MSG_BID_SUCCESS_FMT"), auction.name or "")
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end

    self:CloseConfirmModal()

    -- Remove o leilão comprado da lista em memória do item selecionado
    if self.selectedGroupedItem and self.selectedGroupedItem.auctions then
        local remaining = {}
        for i = 1, table.getn(self.selectedGroupedItem.auctions) do
            local a = self.selectedGroupedItem.auctions[i]
            if a ~= auction then
                table.insert(remaining, a)
            end
        end
        self.selectedGroupedItem.auctions = remaining
        self.selectedGroupedItem.numAuctions = table.getn(remaining)

        if table.getn(remaining) == 0 then
            local newGrouped = {}
            for i = 1, table.getn(self.groupedItems) do
                if self.groupedItems[i] ~= self.selectedGroupedItem then
                    table.insert(newGrouped, self.groupedItems[i])
                end
            end
            self.groupedItems = newGrouped
            if table.getn(newGrouped) == 0 then
                self:SetBuyStep("NO_RESULTS")
            else
                if self.selectedItemIndex > table.getn(newGrouped) then
                    self.selectedItemIndex = table.getn(newGrouped)
                end
                self:SetBuyStep("ITEMS_LIST")
            end
        else
            if self.selectedAuctionIndex > table.getn(remaining) then
                self.selectedAuctionIndex = table.getn(remaining)
            end
            self:UpdateItemDetail()
        end
    end
end

-- ----------------------------------------------------------------------------
-- 14. CONTROLE DE PASSOS (FLOW DA ABA COMPRAR)
-- ----------------------------------------------------------------------------
function AuctionScreen:SetBuyStep(step)
    self.buyStep = step

    self.gridContainer:Hide()
    self.filterContainer:Hide()
    self.scanContainer:Hide()
    self.summaryContainer:Hide()
    self.itemListContainer:Hide()
    self.itemDetailContainer:Hide()
    self:CloseConfirmModal()
    self:CloseSortModal()

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
        if self.scanContainer and self.scanContainer.pageText then
            local progFmt = CM:T("AH_SCAN_PROGRESS_FMT") or "Scanning page %d..."
            self.scanContainer.pageText:SetText(string.format(progFmt, 1))
        end
        if self.scanContainer and self.scanContainer.countText then
            self.scanContainer.countText:SetText("")
        end
        if self.scanContainer and self.scanContainer.progressBar and self.scanContainer.progressBar.fill then
            self.scanContainer.progressBar.fill:SetWidth(10)
        end
        self.scanContainer:Show()
    elseif step == "NO_RESULTS" then
        self.summaryContainer.summaryText:SetText(CM:T("AH_NO_RESULTS"))
        self.summaryBtnIndex = 2
        self:UpdateSummaryStyles()
        self.summaryContainer:Show()
    elseif step == "RESULTS_SUMMARY" then
        local foundFmt = CM:T("AH_SCAN_FOUND_FMT") or "%d auctions found."
        self.summaryContainer.summaryText:SetText(string.format(foundFmt, self.scanTotal or 0))
        self.summaryBtnIndex = 1
        self:UpdateSummaryStyles()
        self.summaryContainer:Show()
    elseif step == "ITEMS_LIST" then
        self:UpdateItemList()
        self.itemListContainer:Show()
    elseif step == "ITEM_DETAIL" then
        self:UpdateItemDetail()
        self.itemDetailContainer:Show()
    end

    self:UpdateBreadcrumb()
    self:UpdateFooterHints()
end

function AuctionScreen:ProcessSearchResults(results, totalCount)
    self.scanResults = results or {}
    self.scanTotal = totalCount or 0

    if self.scanTotal == 0 or table.getn(self.scanResults) == 0 then
        self:SetBuyStep("NO_RESULTS")
    else
        self:GroupScanResults()
        self:SetBuyStep("ITEMS_LIST")
    end
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

    local searchName = self.activeFilters.name or ""
    if searchName ~= "" then
        self:AddRecentSearch(searchName)
    end

    local queryParams = {
        name          = searchName,
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
                if wasAborted then
                    AuctionScreen:SetBuyStep("FILTERS")
                else
                    AuctionScreen:ProcessSearchResults(results, totalCount)
                end
            end,
            function(err)
                DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode AH]|r Scan error: " .. tostring(err))
                AuctionScreen:SetBuyStep("FILTERS")
            end
        )
    end
end

-- ----------------------------------------------------------------------------
-- 15. CRIAÇÃO DA INTERFACE PRINCIPAL
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

    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", frame, "TOP", 0, -18)
    self:ApplyFont(titleText, FONTS.titleBold, 26)
    titleText:SetText(CM:T("AH_TITLE"))
    frame.titleText = titleText

    self:CreateTabIndicator(frame)

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

    self:CreateContentArea(frame)

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
-- 16. NAVEGAÇÃO ENTRE ABAS
-- ----------------------------------------------------------------------------
function AuctionScreen:SetTab(tabKey)
    if self.currentTab == tabKey then return end
    self.currentTab = tabKey
    self:UpdateTabStyles()

    if tabKey == "BUY" then
        self:SetBuyStep("CATEGORIES")
    else
        self.gridContainer:Hide()
        self.filterContainer:Hide()
        self.scanContainer:Hide()
        self.summaryContainer:Hide()
        self.itemListContainer:Hide()
        self.itemDetailContainer:Hide()
        self:CloseConfirmModal()
        if self.breadcrumb and self.breadcrumb.text then
            local tabLabel = (tabKey == "SELL") and CM:T("AH_TAB_SELL") or CM:T("AH_TAB_MY_AUCTIONS")
            self.breadcrumb.text:SetText(tabLabel)
        end
        self:UpdateFooterHints()
    end
end

function AuctionScreen:SwitchTab(delta)
    if self:IsVKOpen() then return end
    if self.isConfirmModalOpen then return end
    if self.isSortModalOpen then return end

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
-- 17. MAPEAMENTO DE BOTÕES DO CONTROLE (A, B, X, Y, D-PAD)
-- ----------------------------------------------------------------------------
function AuctionScreen:OnDirection(direction)
    if not self.isOpen then return end
    if self:IsVKOpen() then return end
    if self.isConfirmModalOpen then return end

    if self.isSortModalOpen then
        local numOpts = table.getn(SORT_OPTIONS)
        if direction == "UP" then
            self.selectedSortIndex = self.selectedSortIndex - 1
            if self.selectedSortIndex < 1 then self.selectedSortIndex = numOpts end
            self:UpdateSortModalStyles()
        elseif direction == "DOWN" then
            self.selectedSortIndex = self.selectedSortIndex + 1
            if self.selectedSortIndex > numOpts then self.selectedSortIndex = 1 end
            self:UpdateSortModalStyles()
        end
        return
    end

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
                if self.filterRowIndex < 1 then self.filterRowIndex = 6 end
                self:UpdateFilterStyles()
            elseif direction == "DOWN" then
                self.filterRowIndex = self.filterRowIndex + 1
                if self.filterRowIndex > 6 then self.filterRowIndex = 1 end
                self:UpdateFilterStyles()
            elseif direction == "LEFT" then
                self:AdjustFilterValue(-1)
            elseif direction == "RIGHT" then
                self:AdjustFilterValue(1)
            end
        elseif self.buyStep == "ITEMS_LIST" then
            if direction == "UP" then
                self:ScrollItemList(-1)
            elseif direction == "DOWN" then
                self:ScrollItemList(1)
            end
        elseif self.buyStep == "ITEM_DETAIL" then
            if direction == "UP" then
                self:ScrollItemDetail(-1)
            elseif direction == "DOWN" then
                self:ScrollItemDetail(1)
            end
        elseif self.buyStep == "NO_RESULTS" or self.buyStep == "RESULTS_SUMMARY" then
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
    if self:IsVKOpen() then return end

    if self.isConfirmModalOpen then
        self:ExecutePurchase()
        return
    end

    if self.isSortModalOpen then
        local opt = SORT_OPTIONS[self.selectedSortIndex]
        if opt then
            self:ApplySort(opt.key)
        end
        self:CloseSortModal()
        return
    end

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
            if self.filterRowIndex == 1 then
                self:OpenFilterSearchVK()
            elseif self.filterRowIndex == 6 then
                self:ExecuteSearch()
            else
                self:AdjustFilterValue(1)
            end
        elseif self.buyStep == "ITEMS_LIST" then
            local item = self.groupedItems[self.selectedItemIndex]
            if item then
                self.selectedGroupedItem = item
                self.selectedAuctionIndex = 1
                self.itemDetailScrollOffset = 0
                self:SetBuyStep("ITEM_DETAIL")
            end
        elseif self.buyStep == "ITEM_DETAIL" then
            if self.selectedGroupedItem and self.selectedGroupedItem.auctions then
                local auction = self.selectedGroupedItem.auctions[self.selectedAuctionIndex]
                if auction then
                    if auction.buyoutPrice and auction.buyoutPrice > 0 then
                        self:OpenConfirmModal(auction, true)
                    else
                        self:OpenConfirmModal(auction, false)
                    end
                end
            end
        elseif self.buyStep == "NO_RESULTS" or self.buyStep == "RESULTS_SUMMARY" then
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
    if self:IsVKOpen() then return end
    if self.isConfirmModalOpen then return end
    if self.isSortModalOpen then return end

    if self.currentTab == "BUY" and self.buyStep == "FILTERS" then
        if self.filterRowIndex == 1 then
            self.activeFilters.name = ""
            self:SaveCategoryFilters()
            self:UpdateFilterStyles()
        else
            self:ResetCategoryFilters()
        end
    end
end

function AuctionScreen:OnContextAction()
    if not self.isOpen then return end
    if self:IsVKOpen() then return end
    if self.isConfirmModalOpen then return end

    if self.isSortModalOpen then
        self:CloseSortModal()
        return
    end

    if self.currentTab == "BUY" then
        if self.buyStep == "FILTERS" then
            self:OpenFilterSearchVK()
        elseif self.buyStep == "ITEMS_LIST" then
            self:OpenSortModal()
        elseif self.buyStep == "ITEM_DETAIL" then
            if self.selectedGroupedItem and self.selectedGroupedItem.auctions then
                local auction = self.selectedGroupedItem.auctions[self.selectedAuctionIndex]
                if auction then
                    self:OpenConfirmModal(auction, false)
                end
            end
        end
    end
end

function AuctionScreen:OnCancel()
    if not self.isOpen then return end
    if self:IsVKOpen() then return end

    if self.isConfirmModalOpen then
        self:CloseConfirmModal()
        return
    end

    if self.isSortModalOpen then
        self:CloseSortModal()
        return
    end

    if self.currentTab == "BUY" then
        if self.buyStep == "SCANNING" then
            local scan = CM.auctionScan or ConsoleMode_AuctionScan
            if scan then scan:AbortQuery() end
            self:SetBuyStep("FILTERS")
            return
        elseif self.buyStep == "ITEM_DETAIL" then
            self:SetBuyStep("ITEMS_LIST")
            return
        elseif self.buyStep == "ITEMS_LIST" then
            self:SetBuyStep("FILTERS")
            return
        elseif self.buyStep == "NO_RESULTS" or self.buyStep == "RESULTS_SUMMARY" then
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
-- 18. REPEAT DE D-PAD (HOLD-TO-REPEAT)
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
-- 19. ABERTURA E FECHAMENTO
-- ----------------------------------------------------------------------------
function AuctionScreen:Open()
    if not self.initialized then
        self:CreateUI()
    end

    if CM.LoadDataLake then
        pcall(function() CM:LoadDataLake("AuctionScreen") end)
    end

    if AuctionFrame then
        AuctionFrame:ClearAllPoints()
        AuctionFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 10000)
        AuctionFrame:SetAlpha(0)
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

    self:CloseConfirmModal()
    self:CloseSortModal()

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
-- 20. GANCHOS DE EVENTO (AUCTION_HOUSE_SHOW / AUCTION_HOUSE_CLOSED)
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
