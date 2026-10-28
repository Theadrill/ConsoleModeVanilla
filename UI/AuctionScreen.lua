-- ============================================================================
-- ConsoleModeVanilla - UI/AuctionScreen.lua
-- Tela de Leilão (Auction House) para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
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

-- Contraste de foco/seleção (DELTA GRANDE focado vs normal, identidade Vanilla mantida)
local SEL_BG = { 0.68, 0.50, 0.20, 1.0 }
local SEL_BORDER = { 1.0, 0.90, 0.35, 1.0 }
local NORMAL_BG = { 0.05, 0.04, 0.02, 0.85 }
local NORMAL_BORDER = { 0.35, 0.28, 0.18, 0.60 }
local SEL_TEXT = { 1.0, 0.92, 0.45 }

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
-- FASE 9: Cache de Scan em Memória (TTL 2 minutos)
AuctionScreen.scanCache                 = {}
AuctionScreen.CACHE_TTL                 = 120 -- 2 minutos

AuctionScreen.isSortModalOpen       = false
AuctionScreen.selectedSortIndex     = 1
AuctionScreen.currentSortType       = "PRICE_UNIT_ASC"

-- FASE 7: Estados da Aba Vender (Inventário, Espelhamento Exato, Quantidade & MAX)
AuctionScreen.sellStep                 = "INVENTORY" -- "INVENTORY", "LISTING"
AuctionScreen.sellBagItems             = {}
AuctionScreen.selectedSellIndex        = 1
AuctionScreen.selectedSellItem         = nil
AuctionScreen.sellScrollOffset         = 0
AuctionScreen.sellCompetitors          = {}
AuctionScreen.selectedCompetitorIndex  = 1
AuctionScreen.sellCompetitorScrollOffset = 0
AuctionScreen.sellListingPane          = "FORM" -- "FORM", "COMPETITORS"
AuctionScreen.sellFormRow              = 1 -- 1: Bid, 2: Buyout, 3: Duration, 4: StackSize, 5: NumStacks, 6: MaxBtn, 7: PostBtn
AuctionScreen.sellDurationIdx          = 1 -- 1: 2h, 2: 8h, 3: 24h
AuctionScreen.sellStackSize            = 1
AuctionScreen.sellNumStacks            = 1
AuctionScreen.sellBidPrice             = 0
AuctionScreen.sellBuyoutPrice          = 0
AuctionScreen.sellMoneyStepIdx         = 3 -- 1: 1c, 2: 10c, 3: 1s, 4: 10s, 5: 1g, 6: 5g, 7: 10g
AuctionScreen.isSellPostModalOpen      = false
AuctionScreen.sellPostBtnIndex         = 1 -- 1: Confirm, 2: Cancel
AuctionScreen.postSession              = nil
AuctionScreen.pendingSellScanItem      = nil

-- FASE 8: Estados da Aba Meus Leilões (Owner Auctions)
AuctionScreen.ownerAuctions            = {}
AuctionScreen.selectedOwnerIndex       = 1
AuctionScreen.ownerScrollOffset        = 0
AuctionScreen.isOwnerCancelModalOpen   = false
AuctionScreen.ownerCancelBtnIndex      = 1 -- 1: Confirm, 2: Cancel
AuctionScreen.targetCancelAuction      = nil

-- Hold-to-repeat
AuctionScreen.repeatDir           = nil
AuctionScreen.repeatElapsed       = 0
AuctionScreen.repeatDelay         = 0.35
AuctionScreen.repeatRate          = 0.08

-- ----------------------------------------------------------------------------
-- 4. HELPERS DE FORMATAÇÃO, TIPOGRAFIA, TOOLTIP SCANNER E 9-SLICE
-- ----------------------------------------------------------------------------
local scanTip = CreateFrame("GameTooltip", "ConsoleMode_AuctionScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

function AuctionScreen:ResetScanTip()
    if not scanTip then return end
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:ClearLines()
    for i = 1, 40 do
        local l = getglobal("ConsoleMode_AuctionScanTipTextLeft" .. i)
        local r = getglobal("ConsoleMode_AuctionScanTipTextRight" .. i)
        if l then l:SetText("") end
        if r then r:SetText("") end
    end
end

function AuctionScreen:ScanItemTooltip(itemLink, item)
    if not itemLink and not item then return nil end
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "ConsoleMode_AuctionScanTip", nil, "GameTooltipTemplate")
    end
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    self:ResetScanTip()

    local rawLink = nil
    if itemLink then
        local _, _, raw = string.find(itemLink, "(item:%d+:%d+:%d+:%d+)")
        if raw then
            rawLink = raw
        else
            local _, _, id = string.find(itemLink, "item:(%d+)")
            if id then
                rawLink = "item:" .. id .. ":0:0:0"
            end
        end
    end

    local okLink = false
    if rawLink then
        okLink = pcall(function() scanTip:SetHyperlink(rawLink) end)
    end
    if (not okLink or (scanTip:NumLines() or 0) < 2) and itemLink then
        pcall(function() scanTip:SetHyperlink(itemLink) end)
    end

    -- Fallback via SetAuctionItem caso o cache de hyperlinks não tenha retornado as linhas
    if (scanTip:NumLines() or 0) < 2 and item then
        local targetIndex = nil
        if item.auctions and item.auctions[1] and item.auctions[1].index then
            targetIndex = item.auctions[1].index
        elseif item.index then
            targetIndex = item.index
        end
        if targetIndex then
            scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
            scanTip:ClearLines()
            pcall(function() scanTip:SetAuctionItem("list", targetIndex) end)
        end
    end

    -- Fallback via SetBagItem para itens das bolsas (Aba Vender)
    if (scanTip:NumLines() or 0) < 2 and item and item.bagSlots and item.bagSlots[1] then
        local s = item.bagSlots[1]
        scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
        scanTip:ClearLines()
        pcall(function() scanTip:SetBagItem(s.bag, s.slot) end)
    end

    local l2Obj = getglobal("ConsoleMode_AuctionScanTipTextLeft2")
    local r2Obj = getglobal("ConsoleMode_AuctionScanTipTextRight2")
    local line2Left = (l2Obj and l2Obj:GetText()) or nil
    local line2Right = (r2Obj and r2Obj:GetText()) or nil

    local statsLines = {}
    local descLines = {}
    local numLines = scanTip:NumLines() or 0

    for l = 2, numLines do
        local leftObj = getglobal("ConsoleMode_AuctionScanTipTextLeft" .. l)
        local rightObj = getglobal("ConsoleMode_AuctionScanTipTextRight" .. l)
        local leftText = (leftObj and leftObj:GetText()) or ""
        local rightText = (rightObj and rightObj:GetText()) or ""

        if leftText ~= "" then
            if string.find(leftText, "Preço de Venda:") or string.find(leftText, "Sell Price:") then
                -- skip vendor sell line (captured separately in economic summary)
            elseif string.find(leftText, "Uso:", 1, 1) or string.find(leftText, "Use:", 1, 1)
                or string.find(leftText, "Equipar:", 1, 1) or string.find(leftText, "Equip:", 1, 1)
                or string.find(leftText, "Chance ao acertar:", 1, 1) or string.find(leftText, "Chance on hit:", 1, 1) then
                local fullEffect = leftText
                if rightText ~= "" then
                    local rLow = string.lower(rightText)
                    if string.find(rLow, "cooldown") or string.find(rLow, "recarga") then
                        if not string.find(rightText, "^%(") then
                            fullEffect = fullEffect .. " (" .. rightText .. ")"
                        else
                            fullEffect = fullEffect .. " " .. rightText
                        end
                    else
                        fullEffect = fullEffect .. "  " .. rightText
                    end
                end
                table.insert(descLines, fullEffect)
            elseif string.find(rightText, "Uso:", 1, 1) or string.find(rightText, "Use:", 1, 1)
                or string.find(rightText, "Equipar:", 1, 1) or string.find(rightText, "Equip:", 1, 1) then
                table.insert(descLines, rightText)
            elseif not string.find(leftText, "Venda:") and not string.find(leftText, "Sell:") then
                local lineStr = leftText
                if rightText ~= "" then
                    lineStr = lineStr .. "  " .. rightText
                end
                table.insert(statsLines, lineStr)
            end
        end
    end

    return {
        statsLines = statsLines,
        descLines  = descLines,
        line2Left  = line2Left,
        line2Right = line2Right,
    }
end

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

function AuctionScreen:CreateMoneyDisplay(parent, height, fontSize, align, width)
    height = height or 22
    fontSize = fontSize or 15
    align = align or "RIGHT"
    width = width or 150

    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(height)
    f:SetWidth(width)
    if parent and parent.GetFrameLevel then
        f:SetFrameLevel(parent:GetFrameLevel() + 5)
    end
    f.align = align

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetAllPoints(f)
    text:SetJustifyH(align)
    text:SetJustifyV("MIDDLE")
    self:ApplyFont(text, FONTS.bodyBold, fontSize)
    f.text = text

    return f
end

function AuctionScreen:SetMoneyDisplay(f, totalCopper)
    if not f or not f.text then return end

    if not totalCopper or totalCopper <= 0 then
        f.text:SetText("-")
        f.text:SetTextColor(0.60, 0.60, 0.60, 0.80)
        return
    end

    f.text:SetText(self:FormatMoney(totalCopper))
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
        -- Estilo MainMenu (UI/MainMenu.lua CreateTabContainer): botao sem
        -- caixa/backdrop, so texto + sublinhado dourado sob a aba ativa.
        local btn = CreateFrame("Button", "ConsoleMode_AuctionTabBtn" .. i, tabContainer)
        btn:SetHeight(26)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self:ApplyFont(label, FONTS.titleBold, 16)
        label:SetText(CM:T(tabData.labelKey))
        label:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.label = label

        local textW = math.floor(label:GetStringWidth() or 60)
        local btnW = textW + 28
        btn:SetWidth(btnW)
        btn:SetPoint("LEFT", tabContainer, "LEFT", totalW, 0)
        totalW = totalW + btnW + 6

        -- Sublinhado dourado da aba ativa (1 textura por aba, criada uma vez).
        local underline = btn:CreateTexture(nil, "OVERLAY")
        underline:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        underline:SetHeight(2)
        underline:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 0)
        underline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
        underline:SetVertexColor(0.88, 0.60, 0.08, 0.95)
        underline:Hide()
        btn.underline = underline

        btn.tabKey = tabData.key
        btn:SetScript("OnClick", function()
            AuctionScreen:SetTab(this.tabKey)
        end)
        btn:SetScript("OnEnter", function()
            if this.tabKey ~= AuctionScreen.currentTab then
                this.label:SetTextColor(0.95, 0.85, 0.40, 1.0)
            end
        end)
        btn:SetScript("OnLeave", function()
            if this.tabKey ~= AuctionScreen.currentTab then
                this.label:SetTextColor(0.52, 0.52, 0.52, 1.0)
            end
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
            btn.label:SetTextColor(0.88, 0.60, 0.08, 1.0)
            if btn.underline then btn.underline:Show() end
        else
            btn.label:SetTextColor(0.52, 0.52, 0.52, 1.0)
            if btn.underline then btn.underline:Hide() end
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
        local actionLabel = self.isBuyoutAction and (CM:T("AH_BTN_BUYOUT") or "Comprar") or (CM:T("AH_BTN_BID") or "Dar Lance")
        table.insert(hints, { icons = { "A" }, label = actionLabel })
        table.insert(hints, { icons = { "B" }, label = CM:T("AH_BTN_CANCEL") })
    elseif self.isSortModalOpen then
        table.insert(hints, { icons = { "A" }, label = CM:T("AH_HINT_SELECT") })
        table.insert(hints, { icons = { "DUP", "DDOWN" }, label = CM:T("AH_HINT_NAVIGATE") })
        table.insert(hints, { icons = { "B" }, label = CM:T("AH_BTN_CANCEL") })
    elseif self.currentTab == "BUY" then
        if self.buyStep == "CATEGORIES" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_SELECT") })
            table.insert(hints, { icons = { "Y" },        label = CM:T("AH_HINT_FILTER_CATEGORY") })
            table.insert(hints, { icons = { "DALL" },     label = CM:T("AH_HINT_NAVIGATE") })
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_CLOSE") })
        elseif self.buyStep == "SUBCATEGORIES" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_SELECT") })
            table.insert(hints, { icons = { "Y" },        label = CM:T("AH_HINT_FILTER_SUBCATEGORY") })
            table.insert(hints, { icons = { "DALL" },     label = CM:T("AH_HINT_NAVIGATE") })
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_BACK") })
        elseif self.buyStep == "SLOTS" then
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
            table.insert(hints, { icons = { "X" },        label = CM:T("AH_HINT_SORT") })
            table.insert(hints, { icons = { "Y" },        label = CM:T("AH_HINT_RESCAN") or "Re-Scan" })
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
    elseif self.currentTab == "SELL" then
        if self.isSellPostModalOpen then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_CONFIRM") or "Confirmar" })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_BTN_CANCEL") or "Cancelar" })
        elseif self.sellStep == "INVENTORY" then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_SELECT") })
            table.insert(hints, { icons = { "X" },        label = CM:T("AH_HINT_REFRESH") or "Atualizar" })
            table.insert(hints, { icons = { "DUP", "DDOWN" }, label = CM:T("AH_HINT_NAVIGATE") or "Navegar" })
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") or "Alternar Aba" })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_CLOSE") or "Fechar" })
        elseif self.sellStep == "LISTING" then
            if self.sellListingPane == "COMPETITORS" then
                table.insert(hints, { icons = { "A" },    label = CM:T("AH_HINT_MIRROR_PRICE") or "Espelhar Preço" })
                table.insert(hints, { icons = { "Y" },    label = CM:T("AH_HINT_RESCAN") or "Re-Scan" })
                table.insert(hints, { icons = { "B" },    label = CM:T("AH_HINT_BACK") or "Voltar ao Formulário" })
                table.insert(hints, { icons = { "DLEFT", "DRIGHT" }, label = CM:T("AH_SELL_SWITCH_COLUMN") or "Switch Column" })
                table.insert(hints, { icons = { "DUP", "DDOWN" }, label = CM:T("AH_HINT_NAVIGATE") or "Navegar" })
            else
                table.insert(hints, { icons = { "RT" },   label = CM:T("AH_HINT_POST_RT") or "Postar Leilão" })
                table.insert(hints, { icons = { "Y" },    label = CM:T("AH_SELL_BTN_MAX") or "MAX" })
                table.insert(hints, { icons = { "A" },    label = (self.sellFormRow == 6 and (CM:T("AH_SELL_BTN_MAX") or "MAX")) or (self.sellFormRow == 7 and (CM:T("AH_SELL_CONFIRM_POST") or "Postar")) or (CM:T("AH_HINT_SELECT") or "Editar") })
                if table.getn(self.sellCompetitors or {}) > 0 then
                    table.insert(hints, { icons = { "DLEFT", "DRIGHT" }, label = CM:T("AH_SELL_SWITCH_COLUMN") or "Switch Column" })
                end
                table.insert(hints, { icons = { "B" },    label = CM:T("AH_HINT_BACK") or "Voltar" })
            end
        end
    elseif self.currentTab == "OWNER" then
        if self.isOwnerCancelModalOpen then
            table.insert(hints, { icons = { "A" },        label = CM:T("AH_HINT_CONFIRM") or "Confirmar" })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_BTN_CANCEL") or "Cancelar" })
        else
            local total = table.getn(self.ownerAuctions or {})
            if total > 0 then
                table.insert(hints, { icons = { "A" },    label = CM:T("AH_HINT_CANCEL_AUCTION") or "Cancelar Leilão" })
            end
            table.insert(hints, { icons = { "X" },        label = CM:T("AH_HINT_REFRESH") or "Atualizar" })
            if total > 0 then
                table.insert(hints, { icons = { "DUP", "DDOWN" }, label = CM:T("AH_HINT_NAVIGATE") or "Navegar" })
            end
            table.insert(hints, { icons = { "LB", "RB" }, label = CM:T("AH_HINT_SWITCH_TAB") or "Alternar Aba" })
            table.insert(hints, { icons = { "B" },        label = CM:T("AH_HINT_CLOSE") or "Fechar" })
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

    -- 10. Container da Aba Vender (FASE 7)
    local sellContainer = CreateFrame("Frame", "ConsoleMode_AuctionSellContainer", contentArea)
    sellContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -8)
    sellContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    sellContainer:Hide()
    self.sellContainer = sellContainer
    self:CreateSellControls(sellContainer)

    -- 11. Container de Split View de Venda / Listagem (FASE 7)
    local sellListingContainer = CreateFrame("Frame", "ConsoleMode_AuctionSellListingContainer", contentArea)
    sellListingContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -8)
    sellListingContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    sellListingContainer:Hide()
    self.sellListingContainer = sellListingContainer
    self:CreateSellListingControls(sellListingContainer)

    -- 12. Modal de Confirmação de Postagem de Venda (FASE 7)
    self:CreateSellPostConfirmModal(parent)

    -- 13. Container da Aba Meus Leilões (FASE 8)
    local ownerContainer = CreateFrame("Frame", "ConsoleMode_AuctionOwnerContainer", contentArea)
    ownerContainer:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", 0, -8)
    ownerContainer:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    ownerContainer:Hide()
    self.ownerContainer = ownerContainer
    self:CreateOwnerControls(ownerContainer)

    -- 14. Modal de Confirmação de Cancelamento de Leilão (FASE 8)
    self:CreateOwnerCancelModal(parent)
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
        trail = trail .. sep .. (CM:T("AH_BREADCRUMB_RESULTS") or "Results")
    elseif self.buyStep == "ITEM_DETAIL" then
        trail = trail .. sep .. (CM:T("AH_BREADCRUMB_RESULTS") or "Results")
        if self.selectedGroupedItem and self.selectedGroupedItem.name then
            local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(self.selectedGroupedItem.name, self.selectedGroupedItem.link) or self.selectedGroupedItem.name
            trail = trail .. sep .. locName
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
    btn:SetScript("OnEnter", function()
        if AuctionScreen.gridIndex ~= this.btnIndex then
            AuctionScreen.gridIndex = this.btnIndex
            AuctionScreen:UpdateGridStyles()
        end
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
                btn:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                btn:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
                btn.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
                btn.arrow:SetTextColor(1.0, 0.85, 0.25, 1.0)
            else
                btn:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                btn:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
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
        row:SetScript("OnEnter", function()
            if AuctionScreen.filterRowIndex ~= this.rowIndex then
                AuctionScreen.filterRowIndex = this.rowIndex
                AuctionScreen:UpdateFilterStyles()
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
    searchBtn:SetScript("OnEnter", function()
        if AuctionScreen.filterRowIndex ~= 6 then
            AuctionScreen.filterRowIndex = 6
            AuctionScreen:UpdateFilterStyles()
        end
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
                    row:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                    row:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
                    row.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
                else
                    row:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                    row:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
                    row.label:SetTextColor(0.85, 0.78, 0.60, 0.90)
                end
            else
                if isFocused then
                    row:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                    row:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
                    row.lbl:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
                else
                    row:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                    row:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
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
    btn1:SetScript("OnEnter", function()
        if AuctionScreen.summaryBtnIndex ~= 1 then
            AuctionScreen.summaryBtnIndex = 1
            AuctionScreen:UpdateSummaryStyles()
        end
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
    btn2:SetScript("OnEnter", function()
        if AuctionScreen.summaryBtnIndex ~= 2 then
            AuctionScreen.summaryBtnIndex = 2
            AuctionScreen:UpdateSummaryStyles()
        end
    end)

    parent.btn1 = btn1
    parent.btn2 = btn2
end

function AuctionScreen:UpdateSummaryStyles()
    if not self.summaryContainer then return end
    local b1 = self.summaryContainer.btn1
    local b2 = self.summaryContainer.btn2

    if self.summaryBtnIndex == 1 then
        b1:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
        b1:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
        b1.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)

        b2:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
        b2:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
        b2.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
    else
        b2:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
        b2:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
        b2.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)

        b1:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
        b1:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
        b1.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
    end
end

-- ----------------------------------------------------------------------------
-- 11. FASE 2 & FASE 5: LISTA DE ITENS AGRUPADOS E SPLIT VIEW COM DETAIL CARD
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateItemListControls(parent)
    -- 1. Painel Esquerdo (Lista de Itens Agrupados)
    local listLeftPane = CreateFrame("Frame", "ConsoleMode_AuctionItemListLeft", parent)
    listLeftPane:SetWidth(540)
    listLeftPane:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, 0)
    listLeftPane:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 0)
    parent.listLeftPane = listLeftPane

    local topActionBar = CreateFrame("Frame", nil, listLeftPane)
    topActionBar:SetHeight(24)
    topActionBar:SetPoint("TOPLEFT", listLeftPane, "TOPLEFT", 6, 0)
    topActionBar:SetPoint("TOPRIGHT", listLeftPane, "TOPRIGHT", -6, 0)

    -- Botão Visual [ RE-SCAN (Y) ]
    local rescanBtn = CreateFrame("Button", "ConsoleMode_AuctionBuyRescanBtn", topActionBar)
    rescanBtn:SetWidth(106)
    rescanBtn:SetHeight(24)
    rescanBtn:SetPoint("RIGHT", topActionBar, "RIGHT", -6, 0)
    rescanBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    rescanBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    rescanBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local rescanIcon = rescanBtn:CreateTexture(nil, "OVERLAY")
    rescanIcon:SetWidth(18)
    rescanIcon:SetHeight(18)
    rescanIcon:SetPoint("LEFT", rescanBtn, "LEFT", 6, 0)
    rescanIcon:SetTexture(ICONS.Y)
    rescanBtn.icon = rescanIcon

    local rescanTxt = rescanBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rescanTxt:SetPoint("LEFT", rescanIcon, "RIGHT", 4, 0)
    self:ApplyFont(rescanTxt, FONTS.titleBold, 13)
    rescanTxt:SetText(CM:T("AH_BTN_RESCAN") or "Re-Scan")
    rescanTxt:SetTextColor(0.95, 0.82, 0.35, 1.0)
    rescanBtn.txt = rescanTxt

    rescanBtn:SetScript("OnClick", function()
        AuctionScreen:ExecuteSearch(true)
    end)
    rescanBtn:SetScript("OnEnter", function()
        rescanBtn:SetBackdropBorderColor(1.0, 0.84, 0.0, 1.0)
    end)
    rescanBtn:SetScript("OnLeave", function()
        rescanBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)

    -- Botão Visual [ CLASSIFICAR (X) ]
    local sortBtn = CreateFrame("Button", "ConsoleMode_AuctionBuySortBtn", topActionBar)
    sortBtn:SetWidth(110)
    sortBtn:SetHeight(24)
    sortBtn:SetPoint("RIGHT", rescanBtn, "LEFT", -6, 0)
    sortBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    sortBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    sortBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local sortIcon = sortBtn:CreateTexture(nil, "OVERLAY")
    sortIcon:SetWidth(18)
    sortIcon:SetHeight(18)
    sortIcon:SetPoint("LEFT", sortBtn, "LEFT", 6, 0)
    sortIcon:SetTexture(ICONS.X)
    sortBtn.icon = sortIcon

    local sortTxt = sortBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sortTxt:SetPoint("LEFT", sortIcon, "RIGHT", 4, 0)
    self:ApplyFont(sortTxt, FONTS.titleBold, 13)
    sortTxt:SetText(CM:T("AH_HINT_SORT") or "Classificar")
    sortTxt:SetTextColor(0.85, 0.85, 0.85, 1.0)
    sortBtn.txt = sortTxt

    sortBtn:SetScript("OnClick", function()
        AuctionScreen:OpenSortModal()
    end)
    sortBtn:SetScript("OnEnter", function()
        sortBtn:SetBackdropBorderColor(1.0, 0.84, 0.0, 1.0)
    end)
    sortBtn:SetScript("OnLeave", function()
        sortBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)

    local headerFrame = CreateFrame("Frame", nil, listLeftPane)
    headerFrame:SetHeight(24)
    headerFrame:SetPoint("TOPLEFT", listLeftPane, "TOPLEFT", 6, -26)
    headerFrame:SetPoint("TOPRIGHT", listLeftPane, "TOPRIGHT", -6, -26)

    local colItem = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colItem:SetPoint("LEFT", headerFrame, "LEFT", 44, 0)
    self:ApplyFont(colItem, FONTS.titleBold, 14)
    colItem:SetText(CM:T("AH_COL_ITEM"))
    colItem:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colLevel = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colLevel:SetPoint("LEFT", headerFrame, "LEFT", 188, 0)
    colLevel:SetWidth(28)
    colLevel:SetJustifyH("CENTER")
    self:ApplyFont(colLevel, FONTS.titleBold, 14)
    colLevel:SetText(CM:T("AH_COL_LEVEL"))
    colLevel:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colAuctions = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colAuctions:SetPoint("LEFT", headerFrame, "LEFT", 222, 0)
    colAuctions:SetWidth(92)
    colAuctions:SetJustifyH("LEFT")
    self:ApplyFont(colAuctions, FONTS.titleBold, 14)
    colAuctions:SetText(CM:T("AH_COL_AUCTIONS_QTY") or "LEILÕES")
    colAuctions:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colPrice = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colPrice:SetPoint("RIGHT", headerFrame, "RIGHT", -68, 0)
    colPrice:SetWidth(150)
    colPrice:SetJustifyH("CENTER")
    self:ApplyFont(colPrice, FONTS.titleBold, 14)
    colPrice:SetText(CM:T("AH_COL_STARTING_FROM") or "A PARTIR DE")
    colPrice:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colVendor = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colVendor:SetPoint("RIGHT", headerFrame, "RIGHT", -8, 0)
    colVendor:SetWidth(56)
    colVendor:SetJustifyH("RIGHT")
    self:ApplyFont(colVendor, FONTS.titleBold, 14)
    colVendor:SetText(CM:T("AH_COL_VENDOR_PCT") or "% LOJA")
    colVendor:SetTextColor(0.70, 0.65, 0.55, 1.0)

    -- Pool de 7 linhas visíveis
    local rows = {}
    local startY = -52
    local rowH = 46
    local rowGap = 6

    for i = 1, 7 do
        local row = CreateFrame("Button", "ConsoleMode_AuctionItemRow" .. i, listLeftPane)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", listLeftPane, "TOPLEFT", 6, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", listLeftPane, "TOPRIGHT", -6, startY - ((i - 1) * (rowH + rowGap)))

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
        nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        nameText:SetWidth(132)
        nameText:SetJustifyH("LEFT")
        self:ApplyFont(nameText, FONTS.titleBold, 16)
        row.nameText = nameText

        -- Nível
        local lvlText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lvlText:SetPoint("LEFT", row, "LEFT", 188, 0)
        lvlText:SetWidth(28)
        lvlText:SetJustifyH("CENTER")
        self:ApplyFont(lvlText, FONTS.bodyBold, 15)
        lvlText:SetTextColor(0.90, 0.90, 0.90, 1.0)
        row.lvlText = lvlText

        -- Quantidade de Leilões
        local countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countText:SetPoint("LEFT", row, "LEFT", 222, 0)
        countText:SetWidth(92)
        countText:SetJustifyH("LEFT")
        self:ApplyFont(countText, FONTS.medium, 14)
        countText:SetTextColor(0.80, 0.80, 0.80, 0.90)
        row.countText = countText

        -- Preço Mínimo (com ícones de moedas)
        -- Coluna propria de 150px: conteudo RIGHT dentro de [310,460],
        -- sem crescer por cima do countText [222,314] nem do % vendor.
        local priceDisplay = self:CreateMoneyDisplay(row, 24, 13, "RIGHT", 150)
        priceDisplay:SetPoint("RIGHT", row, "RIGHT", -68, 0)
        row.priceDisplay = priceDisplay

        -- % Vendor
        local vendorText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        vendorText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        vendorText:SetWidth(56)
        vendorText:SetJustifyH("RIGHT")
        self:ApplyFont(vendorText, FONTS.titleBold, 14)
        row.vendorText = vendorText

        row.rowIdx = i
        row:SetScript("OnClick", function()
            local itemIndex = (AuctionScreen.itemListScrollOffset or 0) + this.rowIdx
            AuctionScreen.selectedItemIndex = itemIndex
            AuctionScreen:UpdateItemList()
            AuctionScreen:OnConfirm()
        end)
        row:SetScript("OnEnter", function()
            local itemIndex = (AuctionScreen.itemListScrollOffset or 0) + this.rowIdx
            if itemIndex <= table.getn(AuctionScreen.groupedItems or {}) then
                if AuctionScreen.selectedItemIndex ~= itemIndex then
                    AuctionScreen.selectedItemIndex = itemIndex
                    AuctionScreen:UpdateItemList()
                end
            end
        end)

        table.insert(rows, row)
    end

    -- Indicador de Posição (Ex: "Item 1 de 24")
    local posIndicator = listLeftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    posIndicator:SetPoint("BOTTOMLEFT", listLeftPane, "BOTTOMLEFT", 10, -26)
    self:ApplyFont(posIndicator, FONTS.medium, 15)
    posIndicator:SetTextColor(0.65, 0.65, 0.65, 1.0)
    parent.posIndicator = posIndicator

    self.itemListRows = rows

    -- 2. Painel Direito (Card de Detalhes do Item - Split View FASE 5)
    self.detailCard = self:CreateDetailCard(parent, listLeftPane)
end

function AuctionScreen:CreateDetailCard(parent, listLeftPane)
    local card = CreateFrame("Frame", "ConsoleMode_AuctionDetailCard", parent)
    card:SetPoint("TOPLEFT", listLeftPane, "TOPRIGHT", 14, 0)
    card:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 0)

    -- Background esculpido 9-slice sólido
    card.slices = self:Create9Slice(
        card,
        NINESLICE.texture,
        NINESLICE.cornerSize,
        NINESLICE.uv,
        NINESLICE.drawLayer
    )

    -- 1. Ícone Superior Grande
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(44)
    icon:SetHeight(44)
    icon:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -16)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    card.icon = icon

    local iconBorder = CreateFrame("Frame", nil, card)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    iconBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    iconBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
    card.iconBorder = iconBorder

    -- 2. Título (Nome do Item)
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, 0)
    titleText:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    titleText:SetJustifyH("LEFT")
    self:ApplyFont(titleText, FONTS.titleBold, 19)
    titleText:SetText(CM:T("AH_CARD_NO_SELECTION"))
    card.titleText = titleText

    -- 3. Subtítulo (Tipo / Subtipo / Slot / Req Level / Soulbound / Unique)
    local typeText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    typeText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -4)
    typeText:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    typeText:SetJustifyH("LEFT")
    self:ApplyFont(typeText, FONTS.medium, 14)
    typeText:SetTextColor(0.75, 0.75, 0.75, 1.0)
    card.typeText = typeText

    -- 4. Divisória Horizontal Superior
    local hDiv = card:CreateTexture(nil, "ARTWORK")
    hDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    hDiv:SetHeight(1)
    hDiv:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -68)
    hDiv:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -68)
    hDiv:SetVertexColor(0.5, 0.4, 0.3, 0.35)
    card.hDiv = hDiv

    -- 5. Divisória Horizontal Inferior (Separando Stats do Resumo Econômico)
    local fDiv = card:CreateTexture(nil, "ARTWORK")
    fDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    fDiv:SetHeight(1)
    fDiv:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 14, 76)
    fDiv:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 76)
    fDiv:SetVertexColor(0.5, 0.4, 0.3, 0.45)
    card.fDiv = fDiv

    -- 6. Colunas de Stats e Descrição (Corpo central)
    local descColLeft = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descColLeft:SetPoint("TOPLEFT", hDiv, "BOTTOMLEFT", 2, -8)
    descColLeft:SetPoint("BOTTOMLEFT", fDiv, "TOPLEFT", 2, 8)
    descColLeft:SetWidth(180)
    descColLeft:SetJustifyH("LEFT")
    descColLeft:SetJustifyV("TOP")
    self:ApplyFont(descColLeft, FONTS.bodyBold, 13)
    card.descColLeft = descColLeft

    local descColRight = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descColRight:SetPoint("TOPLEFT", descColLeft, "TOPRIGHT", 12, 0)
    descColRight:SetPoint("BOTTOMRIGHT", fDiv, "TOPRIGHT", -2, 8)
    descColRight:SetJustifyH("LEFT")
    descColRight:SetJustifyV("TOP")
    self:ApplyFont(descColRight, FONTS.bodyBold, 13)
    card.descColRight = descColRight

    -- 7. Rodapé do Card: Resumo Econômico / Mercado
    local marketHeader = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    marketHeader:SetPoint("TOPLEFT", fDiv, "BOTTOMLEFT", 2, -6)
    self:ApplyFont(marketHeader, FONTS.titleBold, 13)
    marketHeader:SetText(CM:T("AH_CARD_MARKET_SUMMARY"))
    marketHeader:SetTextColor(0.92, 0.82, 0.45, 1.0)
    card.marketHeader = marketHeader

    local marketAuctions = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    marketAuctions:SetPoint("TOPLEFT", marketHeader, "BOTTOMLEFT", 0, -3)
    self:ApplyFont(marketAuctions, FONTS.bodyBold, 13)
    marketAuctions:SetTextColor(0.85, 0.85, 0.85, 1.0)
    card.marketAuctions = marketAuctions

    local vendorLabel = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    vendorLabel:SetPoint("TOPLEFT", marketAuctions, "BOTTOMLEFT", 0, -4)
    self:ApplyFont(vendorLabel, FONTS.bodyBold, 13)
    vendorLabel:SetTextColor(0.70, 0.70, 0.70, 1.0)
    vendorLabel:SetText(CM:T("AH_CARD_VENDOR_LABEL"))
    card.vendorLabel = vendorLabel

    local vendorDisplay = self:CreateMoneyDisplay(card, 18, 13, "LEFT")
    vendorDisplay:SetPoint("LEFT", vendorLabel, "RIGHT", 6, 0)
    card.vendorDisplay = vendorDisplay

    local vendorPct = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    vendorPct:SetPoint("LEFT", vendorDisplay, "RIGHT", 10, 0)
    self:ApplyFont(vendorPct, FONTS.titleBold, 13)
    card.vendorPct = vendorPct

    return card
end

function AuctionScreen:UpdateItemCard(item, targetCard)
    local card = targetCard or self.detailCard
    if not card then return end

    if not item or not item.link then
        card.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        card.iconBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.6)
        card.titleText:SetText(CM:T("AH_CARD_NO_SELECTION"))
        card.titleText:SetTextColor(0.6, 0.6, 0.6, 1.0)
        card.typeText:SetText("")
        card.descColLeft:SetText("")
        card.descColRight:SetText("")
        card.descColRight:Hide()
        card.hDiv:Hide()
        card.fDiv:Hide()
        card.marketHeader:Hide()
        card.marketAuctions:Hide()
        card.vendorLabel:Hide()
        card.vendorDisplay:Hide()
        card.vendorPct:Hide()
        return
    end

    card.hDiv:Show()
    card.fDiv:Show()
    card.marketHeader:Show()
    card.marketAuctions:Show()

    -- 1. Ícone e Borda por Raridade
    card.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    local qColor = QUALITY_COLORS[item.quality] or { 0.8, 0.8, 0.8 }
    card.iconBorder:SetBackdropBorderColor(qColor[1], qColor[2], qColor[3], 0.95)

    -- 2. Título Traduzido
    local locItemName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
    card.titleText:SetText(locItemName)
    card.titleText:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

    -- 3. Informações de GetItemInfo (Subtipo, Slot, Req Level)
    local rawLink = nil
    if item.link then
        local _, _, raw = string.find(item.link, "(item:%d+:%d+:%d+:%d+)")
        rawLink = raw
        if not rawLink then
            local _, _, id = string.find(item.link, "item:(%d+)")
            if id then rawLink = "item:" .. id .. ":0:0:0" end
        end
    end
    local _, _, idStr = string.find(item.link or "", "item:(%d+)")
    local itemID = tonumber(idStr)
    local _, _, _, itemLevel, reqL, itemType, itemSubType, itemStackCount, itemEquipLoc = GetItemInfo(rawLink or itemID or item.name)

    -- 4. Tooltip Scanner: Stats e Efeitos (passando item para fallback SetAuctionItem)
    local scanData = self:ScanItemTooltip(item.link, item)

    local locEquip = nil
    if itemEquipLoc and itemEquipLoc ~= "" then
        locEquip = (ConsoleMode and ConsoleMode.GameLOC_EquipLoc) and ConsoleMode:GameLOC_EquipLoc(itemEquipLoc) or getglobal(itemEquipLoc)
        if not locEquip or string.find(locEquip, "^INVTYPE_") then
            locEquip = (ConsoleMode and ConsoleMode.GameLOC_EquipLoc) and ConsoleMode:GameLOC_EquipLoc(itemEquipLoc) or nil
        end
    end
    -- Fallback se GetItemInfo ainda não tiver retornado equipLoc na primeira consulta
    if (not locEquip or locEquip == "") and scanData and scanData.line2Left then
        local l2 = scanData.line2Left
        local lowerL2 = string.lower(l2)
        if not string.find(lowerL2, "dano") and not string.find(lowerL2, "damage")
           and not string.find(lowerL2, "armadura") and not string.find(lowerL2, "armor")
           and not string.find(lowerL2, "requer") and not string.find(lowerL2, "requires") then
            locEquip = (ConsoleMode and ConsoleMode.GameLOC_EquipLoc) and ConsoleMode:GameLOC_EquipLoc(l2) or l2
        end
    end

    local stName = (ConsoleMode and ConsoleMode.GameLOC_ItemSubType) and ConsoleMode:GameLOC_ItemSubType(itemSubType) or itemSubType
    -- Fallback se GetItemInfo ainda não tiver retornado subType na primeira consulta
    if (not stName or stName == "") and scanData and scanData.line2Right then
        local r2 = scanData.line2Right
        local lowerR2 = string.lower(r2)
        if not string.find(lowerR2, "velocidade") and not string.find(lowerR2, "speed") then
            stName = (ConsoleMode and ConsoleMode.GameLOC_ItemSubType) and ConsoleMode:GameLOC_ItemSubType(r2) or r2
        end
    end

    local subParts = {}
    if locEquip and locEquip ~= "" then
        table.insert(subParts, locEquip)
    end
    if stName and stName ~= "" then
        local isDup = false
        if locEquip then
            local lLoc = string.lower(locEquip)
            local lSt = string.lower(stName)
            if lLoc == lSt or lSt == lLoc .. "s" or lLoc == lSt .. "s" then isDup = true end
        end
        if not isDup then
            table.insert(subParts, stName)
        end
    end

    local rLevel = tonumber(reqL) or tonumber(item.level) or 0
    if rLevel > 1 then
        local pLevel = UnitLevel("player") or 0
        if rLevel > pLevel then
            table.insert(subParts, string.format(CM:T("ITEM_REQLVL_RED_FMT") or "|cffff2020Requer Nível %d|r", rLevel))
        else
            table.insert(subParts, string.format(CM:T("ITEM_REQLVL_FMT") or "Requer Nível %d", rLevel))
        end
    end

    local cardLines = {}
    local isSoulbound = false
    local isUnique = false

    if scanData and scanData.statsLines then
        for _, sLine in ipairs(scanData.statsLines) do
            local lower = string.lower(sLine)
            local skip = false
            if string.find(lower, "head") or string.find(lower, "neck") or string.find(lower, "shoulder") or string.find(lower, "shirt") or string.find(lower, "chest") or string.find(lower, "waist") or string.find(lower, "legs") or string.find(lower, "feet") or string.find(lower, "wrist") or string.find(lower, "hands") or string.find(lower, "finger") or string.find(lower, "trinket") or string.find(lower, "back") or string.find(lower, "main hand") or string.find(lower, "off hand") or string.find(lower, "ranged") or string.find(lower, "tabard") or string.find(lower, "held in off%-hand") or string.find(lower, "two%-hand") or string.find(lower, "one%-hand") or string.find(lower, "cabe") or string.find(lower, "pesco") or string.find(lower, "ombros") or string.find(lower, "camisa") or string.find(lower, "peitoral") or string.find(lower, "cintura") or string.find(lower, "pernas") or string.find(lower, "pés") or string.find(lower, "punhos") or string.find(lower, "mãos") or string.find(lower, "dedo") or string.find(lower, "berloque") or string.find(lower, "costas") or string.find(lower, "duas mãos") or string.find(lower, "uma mão") or string.find(lower, "mão principal") or string.find(lower, "mão secundária") then
                skip = true
            elseif locEquip and locEquip ~= "" and (lower == string.lower(locEquip) or string.find(lower, string.lower(locEquip))) then
                skip = true
            elseif stName and stName ~= "" and (lower == string.lower(stName) or string.find(lower, string.lower(stName))) then
                skip = true
            elseif string.find(lower, "soulbound") or string.find(lower, "ligado") or string.find(lower, "vinculado") or string.find(lower, "binds when") then
                isSoulbound = true
                skip = true
            elseif string.find(lower, "unique") or string.find(lower, "único") or string.find(lower, "unico") then
                isUnique = true
                skip = true
            elseif string.find(lower, "requires level") or string.find(lower, "requer n") or string.find(lower, "req%. nv") then
                skip = true
            elseif string.find(lower, "durability") or string.find(lower, "durabilidade") then
                skip = true
            end

            if not skip then
                local locLine = nil
                if ConsoleMode and ConsoleMode.GameLOC_ItemDesc then
                    locLine = ConsoleMode:GameLOC_ItemDesc(rawLink or item.link, sLine)
                end
                if not locLine then
                    locLine = (ConsoleMode and ConsoleMode.GameLOC_ItemStat) and ConsoleMode:GameLOC_ItemStat(sLine) or sLine
                end

                if string.find(locLine, "Uso:") or string.find(locLine, "Use:") or string.find(locLine, "Equipar:") or string.find(locLine, "Equip:") then
                    table.insert(cardLines, "|cff00ff00" .. locLine .. "|r")
                elseif string.find(lower, "classes:") or string.find(lower, "races:") or string.find(lower, "raças:") or string.find(lower, "racas:") then
                    table.insert(cardLines, "|cffff2020" .. locLine .. "|r")
                elseif string.find(sLine, "^\"") or string.find(sLine, "^%“") then
                    table.insert(cardLines, "|cffffd100" .. locLine .. "|r")
                else
                    table.insert(cardLines, "|cffffffff" .. locLine .. "|r")
                end
            end
        end
    end

    if scanData and scanData.descLines then
        for _, dLine in ipairs(scanData.descLines) do
            local locDesc = nil
            if ConsoleMode and ConsoleMode.GameLOC_ItemDesc then
                locDesc = ConsoleMode:GameLOC_ItemDesc(rawLink or item.link, dLine)
            end
            if not locDesc then
                locDesc = (ConsoleMode and ConsoleMode.GameLOC_ItemStat) and ConsoleMode:GameLOC_ItemStat(dLine) or dLine
            end
            table.insert(cardLines, "|cff00ff00" .. locDesc .. "|r")
        end
    end

    if isSoulbound then table.insert(subParts, CM:T("ITEM_SOULBOUND_TAG") or "|cff00ccffVinculado|r") end
    if isUnique then table.insert(subParts, CM:T("ITEM_UNIQUE_TAG") or "|cffffffffÚnico|r") end
    card.typeText:SetText("|cffaaaaaa" .. table.concat(subParts, "  •  ") .. "|r")

    -- 5. Renderização em Fluxo Contínuo (Coluna 1 prioritária, Coluna 2 como continuação se transbordar)
    local rawW = card:GetWidth()
    local cardW = (rawW and rawW > 0) and rawW or 420
    if cardW < 240 then cardW = 420 end

    local rawH = card:GetHeight()
    local cardH = (rawH and rawH > 0) and rawH or 480
    if cardH < 260 then cardH = 480 end

    local availH = cardH - 160
    if availH < 180 then availH = 180 end

    -- Em fonte 13, cada linha ocupa ~17px de altura
    local maxVisualLines = math.floor(availH / 17)
    if maxVisualLines < 9 then maxVisualLines = 9 end
    if maxVisualLines > 16 then maxVisualLines = 16 end

    -- Calcula o peso visual das linhas em largura cheia (~52 caracteres por linha)
    local totalVisualLines = 0
    for _, lineText in ipairs(cardLines) do
        local clean = string.gsub(lineText, "|c%x%x%x%x%x%x%x%x", "")
        clean = string.gsub(clean, "|r", "")
        local cLen = string.len(clean)
        local w = 1
        if cLen > 52 then
            w = math.ceil(cLen / 52)
        end
        totalVisualLines = totalVisualLines + w
    end

    if totalVisualLines <= maxVisualLines then
        -- Todas as linhas cabem na Coluna 1. Usa largura total do card e oculta Coluna 2
        card.descColLeft:SetWidth(math.max(180, cardW - 32))
        if table.getn(cardLines) > 0 then
            card.descColLeft:SetText(table.concat(cardLines, "\n"))
        else
            card.descColLeft:SetText(CM:T("DETAIL_NO_INFO") or "Sem informações adicionais")
        end
        card.descColRight:SetText("")
        card.descColRight:Hide()
    else
        -- Excede a capacidade da primeira coluna: preenche Coluna 1 e continua o excedente na Coluna 2
        local colW = math.floor((cardW - 46) / 2)
        if colW < 140 then colW = 140 end

        local col1Lines = {}
        local col2Lines = {}
        local col1Visual = 0

        for _, lineText in ipairs(cardLines) do
            local clean = string.gsub(lineText, "|c%x%x%x%x%x%x%x%x", "")
            clean = string.gsub(clean, "|r", "")
            local cLen = string.len(clean)
            -- Em meia coluna (~200px), linhas com mais de 30 caracteres dobram de altura
            local w = 1
            if cLen > 30 then
                w = math.ceil(cLen / 30)
            end

            if table.getn(col1Lines) == 0 or (col1Visual + w) <= maxVisualLines then
                table.insert(col1Lines, lineText)
                col1Visual = col1Visual + w
            else
                table.insert(col2Lines, lineText)
            end
        end

        card.descColLeft:SetWidth(colW)
        card.descColLeft:SetText(table.concat(col1Lines, "\n"))

        card.descColRight:ClearAllPoints()
        card.descColRight:SetPoint("TOPLEFT", card.descColLeft, "TOPRIGHT", 14, 0)
        card.descColRight:SetPoint("BOTTOMRIGHT", card.fDiv, "TOPRIGHT", -2, 8)
        card.descColRight:SetWidth(colW)
        card.descColRight:SetText(table.concat(col2Lines, "\n"))
        card.descColRight:Show()
    end

    -- 6. Resumo Econômico
    if item.totalCount then
        local totalFmt = CM:T("AH_SELL_TOTAL_ITEMS_FMT") or "Total: %d item(s)"
        card.marketAuctions:SetText(string.format(totalFmt, item.totalCount))
    else
        local numAuctions = item.numAuctions or 1
        local totalUnits = item.totalUnits or 1
        local totalFmt = CM:T("AH_CARD_TOTAL_AUCTIONS_FMT") or "%d leilões (%d unidades)"
        card.marketAuctions:SetText(string.format(totalFmt, numAuctions, totalUnits))
    end

    local vPrice = item.vendorPrice or 0
    if vPrice > 0 then
        card.vendorLabel:Show()
        self:SetMoneyDisplay(card.vendorDisplay, vPrice)
        card.vendorDisplay:Show()

        local priceVal = (item.minBuyout and item.minBuyout > 0) and item.minBuyout or item.minBid
        if priceVal and priceVal > 0 then
            local pct = math.floor((priceVal / vPrice) * 100)
            local pctFmt = CM:T("AH_CARD_VENDOR_COMPARE_FMT") or "%d%% de loja"
            card.vendorPct:SetText(string.format(pctFmt, pct))
            if pct <= 100 then
                card.vendorPct:SetTextColor(0.12, 1.0, 0.0, 1.0)
            else
                card.vendorPct:SetTextColor(1.0, 0.82, 0.20, 1.0)
            end
            card.vendorPct:Show()
        else
            card.vendorPct:Hide()
        end
    else
        card.vendorLabel:Hide()
        card.vendorDisplay:Hide()
        card.vendorPct:Hide()
    end
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
            local locItemName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
            row.nameText:SetText(locItemName)
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
                row:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                row:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
                row.nameText:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
            else
                row:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                row:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
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

    -- Atualiza Card de Detalhes da Split View (FASE 5)
    local selectedItem = self.groupedItems[self.selectedItemIndex]
    self:UpdateItemCard(selectedItem)
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
    colBid:SetPoint("RIGHT", tableHeader, "RIGHT", -166, 0)
    colBid:SetWidth(150)
    colBid:SetJustifyH("CENTER")
    self:ApplyFont(colBid, FONTS.titleBold, 15)
    colBid:SetText(CM:T("AH_COL_BID"))
    colBid:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colBuyout = tableHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colBuyout:SetPoint("RIGHT", tableHeader, "RIGHT", -16, 0)
    colBuyout:SetWidth(150)
    colBuyout:SetJustifyH("CENTER")
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
        sellerText:SetPoint("RIGHT", row, "LEFT", 210, 0)
        sellerText:SetJustifyH("LEFT")
        self:ApplyFont(sellerText, FONTS.titleBold, 16)
        row.sellerText = sellerText

        local stackText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        stackText:SetPoint("LEFT", row, "LEFT", 220, 0)
        stackText:SetWidth(100)
        stackText:SetJustifyH("LEFT")
        self:ApplyFont(stackText, FONTS.titleBold, 17)
        stackText:SetTextColor(1.0, 0.90, 0.40, 1.0)
        row.stackText = stackText

        local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        timeText:SetPoint("LEFT", row, "LEFT", 340, 0)
        timeText:SetWidth(90)
        timeText:SetJustifyH("LEFT")
        self:ApplyFont(timeText, FONTS.medium, 15)
        timeText:SetTextColor(0.80, 0.80, 0.80, 0.90)
        row.timeText = timeText

        local bidDisplay = self:CreateMoneyDisplay(row, 24, 13, "RIGHT", 150)
        bidDisplay:SetPoint("RIGHT", row, "RIGHT", -166, 0)
        row.bidDisplay = bidDisplay

        local buyoutDisplay = self:CreateMoneyDisplay(row, 24, 13, "RIGHT", 150)
        buyoutDisplay:SetPoint("RIGHT", row, "RIGHT", -16, 0)
        row.buyoutDisplay = buyoutDisplay

        row.rowIdx = i
        row:SetScript("OnClick", function()
            local auctionIdx = (AuctionScreen.itemDetailScrollOffset or 0) + this.rowIdx
            AuctionScreen.selectedAuctionIndex = auctionIdx
            AuctionScreen:UpdateItemDetail()
            AuctionScreen:OnConfirm()
        end)
        row:SetScript("OnEnter", function()
            local auctions = AuctionScreen.selectedGroupedItem and AuctionScreen.selectedGroupedItem.auctions or {}
            local auctionIdx = (AuctionScreen.itemDetailScrollOffset or 0) + this.rowIdx
            if auctionIdx <= table.getn(auctions) then
                if AuctionScreen.selectedAuctionIndex ~= auctionIdx then
                    AuctionScreen.selectedAuctionIndex = auctionIdx
                    AuctionScreen:UpdateItemDetail()
                end
            end
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
        local locItemName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
        topCard.nameText:SetText(locItemName)
        local qColor = QUALITY_COLORS[item.quality] or { 1, 1, 1 }
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
                row:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                row:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
                row.sellerText:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
            else
                row:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                row:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
                row.sellerText:SetTextColor(1.0, 1.0, 1.0, 1.0)
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
    btnConfirm:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
    btnConfirm:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])

    local lConf = btnConfirm:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lConf:SetPoint("CENTER", btnConfirm, "CENTER", 0, 0)
    self:ApplyFont(lConf, FONTS.titleBold, 16)
    lConf:SetText(CM:T("AH_HINT_CONFIRM"))
    btnConfirm.label = lConf
    btnConfirm:SetScript("OnClick", function()
        AuctionScreen:ExecutePurchase()
    end)
    btnConfirm:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    btnConfirm:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
        this:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
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
    btnCancel:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
    btnCancel:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])

    local lCanc = btnCancel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lCanc:SetPoint("CENTER", btnCancel, "CENTER", 0, 0)
    self:ApplyFont(lCanc, FONTS.titleBold, 16)
    lCanc:SetText(CM:T("AH_BTN_CANCEL"))
    btnCancel.label = lCanc
    btnCancel:SetScript("OnClick", function()
        AuctionScreen:CloseConfirmModal()
    end)
    btnCancel:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    btnCancel:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
        this:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
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
        m.btnConfirm.label:SetText(CM:T("AH_BTN_BUYOUT") or "Comprar")
    else
        m.title:SetText(CM:T("AH_BID_CONFIRM_TITLE"))
        m.priceLabel:SetText(CM:T("AH_MODAL_BID_LABEL") or "Valor do Lance:")
        m.btnConfirm.label:SetText(CM:T("AH_BTN_BID") or "Dar Lance")
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
        m.btnConfirm:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
        m.btnConfirm:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
        m.btnConfirm.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
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
        row:SetScript("OnEnter", function()
            if AuctionScreen.selectedSortIndex ~= idx then
                AuctionScreen.selectedSortIndex = idx
                AuctionScreen:UpdateSortModalStyles()
            end
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
                row:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                row:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
                row.lbl:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
            else
                row:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                row:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
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

-- ----------------------------------------------------------------------------
-- 14b. CACHE DE SCAN EM MEMÓRIA E RE-SCAN (FASE 9)
-- ----------------------------------------------------------------------------
function AuctionScreen:GetCacheEntry(key)
    if not key or not self.scanCache then return nil end
    local entry = self.scanCache[key]
    if not entry then return nil end
    local now = GetTime()
    if (now - (entry.timestamp or 0)) <= (self.CACHE_TTL or 120) then
        return entry
    end
    self.scanCache[key] = nil
    return nil
end

function AuctionScreen:SetCacheEntry(key, results, totalCount)
    if not key then return end
    if not self.scanCache then self.scanCache = {} end
    self.scanCache[key] = {
        results    = results,
        totalCount = totalCount or (results and table.getn(results)) or 0,
        timestamp  = GetTime(),
    }
end

function AuctionScreen:InvalidateCacheEntry(key)
    if key and self.scanCache and self.scanCache[key] then
        self.scanCache[key] = nil
    end
end

function AuctionScreen:GetBuyCacheKey()
    local f = self.activeFilters or {}
    local catKey = (self.selectedCategory and self.selectedCategory.key) or "ALL"
    local subKey = (self.selectedSubcategory and self.selectedSubcategory.key) or "ALL"
    local slotKey = (self.selectedSlot and self.selectedSlot.key) or "ALL"
    return string.format("BUY:%s:%s:%s:%s:%d:%d:%d:%d",
        catKey, subKey, slotKey,
        f.name or "",
        f.minLevel or 0,
        f.maxLevel or 0,
        f.quality or -1,
        f.isUsable or 0
    )
end

function AuctionScreen:GetSellCacheKey(item)
    if not item then return nil end
    local realName = self:GetBagItemRealName(item) or item.name or ""
    return "SELL:" .. realName
end

function AuctionScreen:RescanSellListing()
    if self.selectedSellItem then
        self:OpenSellListingWithScan(self.selectedSellItem, true)
    end
end

function AuctionScreen:ExecuteSearch(forceRescan)
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

    local cacheKey = self:GetBuyCacheKey()
    if not forceRescan then
        local cached = self:GetCacheEntry(cacheKey)
        if cached then
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[ConsoleMode AH]|r " .. string.format(CM:T("AH_CACHE_LOADED_FMT") or "Loaded %s auctions from memory cache (TTL 2m)", tostring(cached.totalCount or (cached.results and table.getn(cached.results)) or 0)))
            end
            self:ProcessSearchResults(cached.results, cached.totalCount)
            return
        end
    else
        self:InvalidateCacheEntry(cacheKey)
    end

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
                    AuctionScreen:SetCacheEntry(cacheKey, results, totalCount)
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

    local blizzBtn = CreateFrame("Button", "ConsoleMode_AuctionBlizzardBtn", header)
    blizzBtn:SetWidth(118)
    blizzBtn:SetHeight(28)
    blizzBtn:SetPoint("RIGHT", closeBtn, "LEFT", -8, 0)
    blizzBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    blizzBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    blizzBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local blizzTxt = blizzBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    blizzTxt:SetPoint("CENTER", blizzBtn, "CENTER", 0, 0)
    self:ApplyFont(blizzTxt, FONTS.titleBold, 16)
    blizzTxt:SetText(CM:T("AH_BUTTON_BLIZZARD_AH"))

    blizzBtn:SetScript("OnClick", function()
        AuctionScreen:OpenBlizzardAH()
    end)
    blizzBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    blizzBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    header.blizzBtn = blizzBtn

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
-- 15. ABA VENDER (FASE 7: INVENTÁRIO, ESPELHAMENTO, SPLIT VIEW, MAX, POSTAGEM)
-- ----------------------------------------------------------------------------
local SELL_MONEY_STEPS = { 1, 10, 100, 1000, 10000, 50000, 100000 }
local SELL_MONEY_LABELS = { "1c", "10c", "1s", "10s", "1g", "5g", "10g" }

function AuctionScreen:IsItemAuctionable(bag, slot)
    if not bag or not slot then return false end
    local texture, count, locked = GetContainerItemInfo(bag, slot)
    if not texture or (count and count <= 0) then return false end
    if locked then return false end

    local link = GetContainerItemLink(bag, slot)
    if not link then return false end

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount = GetItemInfo(link)
    if itemType == "Quest" or itemType == "Missão" then
        return false
    end

    local tip = self.bagScanTooltip
    if not tip then
        local ok, t = pcall(CreateFrame, "GameTooltip", "ConsoleModeAuctionScanTooltip", UIParent, "GameTooltipTemplate")
        if ok and t then
            self.bagScanTooltip = t
            tip = t
        end
    end

    if tip then
        pcall(function() tip:SetOwner(UIParent, "ANCHOR_NONE") end)
        for i = 1, 30 do
            local line = getglobal(tip:GetName() .. "TextLeft" .. i)
            if line then pcall(function() line:SetText("") end) end
        end
        local okSet = pcall(function() tip:SetBagItem(bag, slot) end)
        if okSet then
            local nLines = tip:NumLines() or 0
            for i = 1, nLines do
                local line = getglobal(tip:GetName() .. "TextLeft" .. i)
                if line then
                    local text = line:GetText()
                    if text and text ~= "" then
                        local lText = string.lower(text)
                        if (ITEM_SOULBOUND and text == ITEM_SOULBOUND)
                           or (ITEM_BIND_QUEST and text == ITEM_BIND_QUEST)
                           or (ITEM_CONJURED and text == ITEM_CONJURED)
                           or (ITEM_BIND_ON_PICKUP and text == ITEM_BIND_ON_PICKUP)
                           or string.find(lText, "soulbound")
                           or string.find(lText, "vinculado")
                           or string.find(lText, "ligado")
                           or string.find(lText, "conjurado")
                           or string.find(lText, "conjured")
                           or string.find(lText, "quest item")
                           or string.find(lText, "item de miss") then
                            pcall(function() tip:Hide() end)
                            return false
                        end
                    end
                end
            end
        end
        pcall(function() tip:Hide() end)
    end

    return true
end

function AuctionScreen:GetBagItemRealName(entry)
    if entry and entry.name and entry.name ~= "" and entry.name ~= "Unknown" then
        return entry.name
    end
    local link = (entry and entry.link) or nil
    if link then
        local ok, rName = pcall(GetItemInfo, link)
        if ok and rName and rName ~= "" and rName ~= "Unknown" then
            return rName
        end
        local _, _, cap = string.find(link, "%[(.-)%]")
        if cap and cap ~= "" and cap ~= "Unknown" then
            return cap
        end
    end
    return nil
end

function AuctionScreen:GetItemKey(link)
    if not link then return nil end
    local _, _, id, ench, suf = string.find(link, "item:(%d+):(%d+):(%d+)")
    if id then
        return id .. ":" .. (suf or "0")
    end
    local _, _, simpleId = string.find(link, "item:(%d+)")
    if simpleId then
        return simpleId .. ":0"
    end
    return nil
end

function AuctionScreen:GetAuctionableBagItems()
    local items = {}
    local itemsByKey = {}

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            if self:IsItemAuctionable(bag, slot) then
                local texture, count, locked, quality = GetContainerItemInfo(bag, slot)
                local link = GetContainerItemLink(bag, slot)
                local itemName, itemLink, itemRarity, itemLevel, itemType, itemSubType, itemStackCount, itemEquipLoc = GetItemInfo(link)

                local key = self:GetItemKey(link) or itemName or "item"

                if not itemsByKey[key] then
                    local vendorPrice = self:GetItemVendorPrice(link)
                    local entryName = itemName
                    if not entryName or entryName == "" then
                        if link then
                            local _, _, cap = string.find(link, "%[(.-)%]")
                            if cap and cap ~= "" then entryName = cap end
                        end
                    end
                    local maxS = tonumber(itemStackCount) or 1
                    if maxS <= 1 and count and count > 1 then
                        maxS = count
                    end
                    local entry = {
                        key         = key,
                        name        = entryName or "Unknown",
                        texture     = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
                        quality     = itemRarity or quality or 0,
                        link        = link,
                        level       = itemLevel or 0,
                        itemType    = itemType or "",
                        itemSubType = itemSubType or "",
                        maxStack    = maxS,
                        vendorPrice = vendorPrice,
                        totalCount  = count or 1,
                        bagSlots    = { { bag = bag, slot = slot, count = count or 1 } }
                    }
                    itemsByKey[key] = entry
                    table.insert(items, entry)
                else
                    local entry = itemsByKey[key]
                    entry.totalCount = entry.totalCount + (count or 1)
                    if count and count > (entry.maxStack or 1) then
                        entry.maxStack = count
                    end
                    table.insert(entry.bagSlots, { bag = bag, slot = slot, count = count or 1 })
                end
            end
        end
    end

    table.sort(items, function(a, b)
        local qA = a.quality or 0
        local qB = b.quality or 0
        if qA ~= qB then return qA > qB end
        return (a.name or "") < (b.name or "")
    end)

    return items
end

function AuctionScreen:RefreshSellInventory()
    self.sellBagItems = self:GetAuctionableBagItems()
    local total = table.getn(self.sellBagItems)

    if self.selectedSellIndex > total then
        self.selectedSellIndex = math.max(1, total)
    end
    if self.selectedSellIndex < 1 and total > 0 then
        self.selectedSellIndex = 1
    end

    self.selectedSellItem = (total > 0) and self.sellBagItems[self.selectedSellIndex] or nil
    self:UpdateSellInventory()
end

function AuctionScreen:CreateSellControls(parent)
    local sellLeftPane = CreateFrame("Frame", "ConsoleMode_AuctionSellLeft", parent)
    sellLeftPane:SetWidth(540)
    sellLeftPane:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, 0)
    sellLeftPane:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 0)
    parent.sellLeftPane = sellLeftPane

    local headerFrame = CreateFrame("Frame", nil, sellLeftPane)
    headerFrame:SetHeight(24)
    headerFrame:SetPoint("TOPLEFT", sellLeftPane, "TOPLEFT", 6, 0)
    headerFrame:SetPoint("TOPRIGHT", sellLeftPane, "TOPRIGHT", -6, 0)

    local colItem = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colItem:SetPoint("LEFT", headerFrame, "LEFT", 44, 0)
    self:ApplyFont(colItem, FONTS.titleBold, 14)
    colItem:SetText(CM:T("AH_COL_ITEM") or "ITEM")
    colItem:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colCount = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colCount:SetPoint("RIGHT", headerFrame, "RIGHT", -10, 0)
    colCount:SetWidth(44)
    colCount:SetJustifyH("CENTER")
    self:ApplyFont(colCount, FONTS.titleBold, 14)
    colCount:SetText(CM:T("AH_SELL_STACK_SIZE") or "QTD")
    colCount:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colVendor = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colVendor:SetPoint("RIGHT", headerFrame, "RIGHT", -64, 0)
    colVendor:SetWidth(150)
    colVendor:SetJustifyH("CENTER")
    self:ApplyFont(colVendor, FONTS.titleBold, 14)
    colVendor:SetText(CM:T("AH_CARD_VENDOR_LABEL") or "LOJA")
    colVendor:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local rows = {}
    local startY = -28
    local rowH = 46
    local rowGap = 6

    for i = 1, 7 do
        local row = CreateFrame("Button", "ConsoleMode_AuctionSellRow" .. i, sellLeftPane)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", sellLeftPane, "TOPLEFT", 6, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", sellLeftPane, "TOPRIGHT", -6, startY - ((i - 1) * (rowH + rowGap)))

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 10, edgeSize = 10,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(34)
        icon:SetHeight(34)
        icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.icon = icon

        local iconBorder = CreateFrame("Frame", nil, row)
        iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        iconBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        iconBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
        row.iconBorder = iconBorder

        local countBadge = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countBadge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
        self:ApplyFont(countBadge, FONTS.titleBold, 12)
        countBadge:SetTextColor(1.0, 1.0, 1.0, 1.0)
        row.countBadge = countBadge

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -3)
        nameText:SetPoint("RIGHT", row, "RIGHT", -214, 0)
        nameText:SetJustifyH("LEFT")
        self:ApplyFont(nameText, FONTS.titleBold, 16)
        row.nameText = nameText

        local subText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        subText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
        subText:SetPoint("RIGHT", row, "RIGHT", -214, 0)
        subText:SetJustifyH("LEFT")
        self:ApplyFont(subText, FONTS.medium, 13)
        subText:SetTextColor(0.65, 0.65, 0.65, 1.0)
        row.subText = subText

        local totalCountText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        totalCountText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        totalCountText:SetWidth(44)
        totalCountText:SetJustifyH("RIGHT")
        self:ApplyFont(totalCountText, FONTS.titleBold, 15)
        totalCountText:SetTextColor(0.95, 0.82, 0.35, 1.0)
        row.totalCountText = totalCountText

        local vendorDisplay = self:CreateMoneyDisplay(row, 24, 13, "RIGHT", 150)
        vendorDisplay:SetPoint("RIGHT", row, "RIGHT", -64, 0)
        row.vendorDisplay = vendorDisplay

        local rIdx = i
        row:SetScript("OnClick", function()
            local targetIdx = (AuctionScreen.sellScrollOffset or 0) + rIdx
            if targetIdx <= table.getn(AuctionScreen.sellBagItems) then
                AuctionScreen.selectedSellIndex = targetIdx
                AuctionScreen.selectedSellItem = AuctionScreen.sellBagItems[targetIdx]
                AuctionScreen:UpdateSellInventory()
                AuctionScreen:OpenSellListingWithScan(AuctionScreen.selectedSellItem)
            end
        end)
        row:SetScript("OnEnter", function()
            local targetIdx = (AuctionScreen.sellScrollOffset or 0) + rIdx
            if targetIdx <= table.getn(AuctionScreen.sellBagItems or {}) then
                if AuctionScreen.selectedSellIndex ~= targetIdx then
                    AuctionScreen.selectedSellIndex = targetIdx
                    AuctionScreen.selectedSellItem = AuctionScreen.sellBagItems[targetIdx]
                    AuctionScreen:UpdateSellInventory()
                end
            end
        end)

        table.insert(rows, row)
    end
    sellLeftPane.rows = rows

    local emptyText = sellLeftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyText:SetPoint("CENTER", sellLeftPane, "CENTER", 0, 0)
    self:ApplyFont(emptyText, FONTS.titleBold, 16)
    emptyText:SetTextColor(0.65, 0.65, 0.65, 1.0)
    emptyText:SetText(CM:T("AH_SELL_NO_ITEMS") or "No auctionable items found in your bags.")
    emptyText:Hide()
    sellLeftPane.emptyText = emptyText

    self.sellDetailCard = self:CreateDetailCard(parent, sellLeftPane)
end

function AuctionScreen:UpdateSellInventory()
    if not self.sellContainer or not self.sellContainer.sellLeftPane then return end
    local leftPane = self.sellContainer.sellLeftPane
    local rows = leftPane.rows
    local totalItems = table.getn(self.sellBagItems)

    if totalItems == 0 then
        leftPane.emptyText:Show()
        for i = 1, 7 do
            if rows[i] then rows[i]:Hide() end
        end
        if self.sellDetailCard then
            self:UpdateItemCard(nil, self.sellDetailCard)
        end
        self:UpdateFooterHints()
        return
    end

    leftPane.emptyText:Hide()

    for i = 1, 7 do
        local row = rows[i]
        local itemIdx = (self.sellScrollOffset or 0) + i
        if itemIdx <= totalItems then
            local item = self.sellBagItems[itemIdx]
            row.item = item

            local qColor = QUALITY_COLORS[item.quality] or { 0.8, 0.8, 0.8 }
            row.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.iconBorder:SetBackdropBorderColor(qColor[1], qColor[2], qColor[3], 0.90)

            local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
            row.nameText:SetText(locName)
            row.nameText:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

            local subParts = {}
            if item.itemSubType and item.itemSubType ~= "" then
                local stName = (ConsoleMode and ConsoleMode.GameLOC_ItemSubType) and ConsoleMode:GameLOC_ItemSubType(item.itemSubType) or item.itemSubType
                table.insert(subParts, stName)
            end
            if item.maxStack and item.maxStack > 1 then
                table.insert(subParts, "Pilha máx " .. item.maxStack)
            end
            row.subText:SetText(table.concat(subParts, " • "))

            row.totalCountText:SetText(tostring(item.totalCount))
            if item.totalCount > 1 then
                row.countBadge:SetText(tostring(item.totalCount))
                row.countBadge:Show()
            else
                row.countBadge:Hide()
            end

            self:SetMoneyDisplay(row.vendorDisplay, item.vendorPrice or 0)

            local isSelected = (itemIdx == self.selectedSellIndex)
            if isSelected then
                row:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                row:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
                row.nameText:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
            else
                row:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                row:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
            end

            row:Show()
        else
            row:Hide()
        end
    end

    if self.selectedSellItem and self.sellDetailCard then
        self:UpdateItemCard(self.selectedSellItem, self.sellDetailCard)
    end

    self:UpdateFooterHints()
end

function AuctionScreen:CreateSellListingControls(parent)
    local listingLeftPane = CreateFrame("Frame", "ConsoleMode_AuctionSellListingLeft", parent)
    listingLeftPane:SetWidth(540)
    listingLeftPane:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, 0)
    listingLeftPane:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 0)
    parent.listingLeftPane = listingLeftPane

    -- Barra de progresso do scan (pool fixo, criado uma vez; mesmo visual do BUY)
    local sellScanPageText = listingLeftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sellScanPageText:SetPoint("TOP", listingLeftPane, "TOP", 0, -30)
    self:ApplyFont(sellScanPageText, FONTS.bodyBold, 17)
    sellScanPageText:SetText("")
    sellScanPageText:Hide()
    listingLeftPane.sellScanPageText = sellScanPageText

    local sellScanBar = CreateFrame("Frame", "ConsoleMode_AuctionSellScanBarBg", listingLeftPane)
    sellScanBar:SetWidth(420)
    sellScanBar:SetHeight(22)
    sellScanBar:SetPoint("TOP", sellScanPageText, "BOTTOM", 0, -12)
    sellScanBar:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    sellScanBar:SetBackdropColor(0.06, 0.05, 0.04, 0.90)
    sellScanBar:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.80)

    local sellScanFill = sellScanBar:CreateTexture(nil, "ARTWORK")
    sellScanFill:SetHeight(16)
    sellScanFill:SetPoint("LEFT", sellScanBar, "LEFT", 3, 0)
    sellScanFill:SetTexture(0.95, 0.78, 0.20, 0.95)
    sellScanFill:SetWidth(10)
    sellScanBar.fill = sellScanFill
    sellScanBar:Hide()
    listingLeftPane.sellScanBar = sellScanBar

    local topActionBar = CreateFrame("Frame", nil, listingLeftPane)
    topActionBar:SetHeight(24)
    topActionBar:SetPoint("TOPLEFT", listingLeftPane, "TOPLEFT", 6, 0)
    topActionBar:SetPoint("TOPRIGHT", listingLeftPane, "TOPRIGHT", -6, 0)

    local cTitle = topActionBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cTitle:SetPoint("LEFT", topActionBar, "LEFT", 8, 0)
    self:ApplyFont(cTitle, FONTS.titleBold, 15)
    cTitle:SetText(CM:T("AH_SELL_COMPETITORS_TITLE") or "Concorrentes no Mercado")
    cTitle:SetTextColor(0.95, 0.82, 0.35, 1.0)

    -- Botão Visual [ RE-SCAN (Y) ]
    local rescanBtn = CreateFrame("Button", "ConsoleMode_AuctionSellRescanBtn", topActionBar)
    rescanBtn:SetWidth(106)
    rescanBtn:SetHeight(24)
    rescanBtn:SetPoint("RIGHT", topActionBar, "RIGHT", -6, 0)
    rescanBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    rescanBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    rescanBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local rescanIcon = rescanBtn:CreateTexture(nil, "OVERLAY")
    rescanIcon:SetWidth(18)
    rescanIcon:SetHeight(18)
    rescanIcon:SetPoint("LEFT", rescanBtn, "LEFT", 6, 0)
    rescanIcon:SetTexture(ICONS.Y)
    rescanBtn.icon = rescanIcon

    local rescanTxt = rescanBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rescanTxt:SetPoint("LEFT", rescanIcon, "RIGHT", 4, 0)
    self:ApplyFont(rescanTxt, FONTS.titleBold, 13)
    rescanTxt:SetText(CM:T("AH_BTN_RESCAN") or "Re-Scan")
    rescanTxt:SetTextColor(0.95, 0.82, 0.35, 1.0)
    rescanBtn.txt = rescanTxt

    rescanBtn:SetScript("OnClick", function()
        AuctionScreen:RescanSellListing()
    end)
    rescanBtn:SetScript("OnEnter", function()
        rescanBtn:SetBackdropBorderColor(1.0, 0.84, 0.0, 1.0)
    end)
    rescanBtn:SetScript("OnLeave", function()
        rescanBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)

    local compHeader = CreateFrame("Frame", nil, listingLeftPane)
    compHeader:SetHeight(24)
    listingLeftPane.compHeader = compHeader
    compHeader:SetPoint("TOPLEFT", listingLeftPane, "TOPLEFT", 6, -26)
    compHeader:SetPoint("TOPRIGHT", listingLeftPane, "TOPRIGHT", -6, -26)

    local colStack = compHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colStack:SetPoint("LEFT", compHeader, "LEFT", 192, 0)
    colStack:SetWidth(48)
    colStack:SetJustifyH("CENTER")
    self:ApplyFont(colStack, FONTS.titleBold, 13)
    colStack:SetText(CM:T("AH_SELL_STACK_SIZE") or "QTD")
    colStack:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colUnitBid = compHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colUnitBid:SetPoint("RIGHT", compHeader, "RIGHT", -166, 0)
    colUnitBid:SetWidth(150)
    colUnitBid:SetJustifyH("CENTER")
    self:ApplyFont(colUnitBid, FONTS.titleBold, 13)
    colUnitBid:SetText(CM:T("AH_SELL_BID_PRICE") or "LANCE UNIT.")
    colUnitBid:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colUnitBuy = compHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colUnitBuy:SetPoint("RIGHT", compHeader, "RIGHT", -16, 0)
    colUnitBuy:SetWidth(150)
    colUnitBuy:SetJustifyH("CENTER")
    self:ApplyFont(colUnitBuy, FONTS.titleBold, 13)
    colUnitBuy:SetText(CM:T("AH_SELL_BUYOUT_PRICE") or "COMPRA UNIT.")
    colUnitBuy:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local compRows = {}
    local startY = -52
    local rowH = 46
    local rowGap = 6

    for i = 1, 6 do
        local row = CreateFrame("Button", "ConsoleMode_AuctionCompRow" .. i, listingLeftPane)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", listingLeftPane, "TOPLEFT", 6, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", listingLeftPane, "TOPRIGHT", -6, startY - ((i - 1) * (rowH + rowGap)))

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 10, edgeSize = 10,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        local sellerText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        sellerText:SetPoint("LEFT", row, "LEFT", 10, 0)
        sellerText:SetPoint("RIGHT", row, "LEFT", 186, 0)
        sellerText:SetJustifyH("LEFT")
        self:ApplyFont(sellerText, FONTS.titleBold, 15)
        row.sellerText = sellerText

        local stackText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        stackText:SetPoint("LEFT", row, "LEFT", 192, 0)
        stackText:SetWidth(48)
        stackText:SetJustifyH("LEFT")
        self:ApplyFont(stackText, FONTS.titleBold, 15)
        stackText:SetTextColor(0.95, 0.82, 0.35, 1.0)
        row.stackText = stackText

        local unitBidDisplay = self:CreateMoneyDisplay(row, 24, 13, "RIGHT", 150)
        unitBidDisplay:SetPoint("RIGHT", row, "RIGHT", -166, 0)
        row.unitBidDisplay = unitBidDisplay

        local unitBuyDisplay = self:CreateMoneyDisplay(row, 24, 13, "RIGHT", 150)
        unitBuyDisplay:SetPoint("RIGHT", row, "RIGHT", -16, 0)
        row.unitBuyDisplay = unitBuyDisplay

        row.rowIdx = i
        row:SetScript("OnClick", function()
            local absIdx = (AuctionScreen.sellCompetitorScrollOffset or 0) + this.rowIdx
            local n = table.getn(AuctionScreen.sellCompetitors or {})
            if absIdx < 1 then absIdx = 1 end
            if n > 0 and absIdx > n then absIdx = n end
            AuctionScreen.selectedCompetitorIndex = absIdx
            AuctionScreen:MirrorCompetitorPrice(absIdx)
            AuctionScreen.sellListingPane = "FORM"
            AuctionScreen:UpdateSellListingStyles()
        end)
        row:SetScript("OnEnter", function()
            local absIdx = (AuctionScreen.sellCompetitorScrollOffset or 0) + this.rowIdx
            local n = table.getn(AuctionScreen.sellCompetitors or {})
            if absIdx <= n and n > 0 then
                if AuctionScreen.sellListingPane ~= "COMPETITORS" or AuctionScreen.selectedCompetitorIndex ~= absIdx then
                    AuctionScreen.sellListingPane = "COMPETITORS"
                    AuctionScreen.selectedCompetitorIndex = absIdx
                    AuctionScreen:UpdateSellListingStyles()
                end
            end
        end)

        table.insert(compRows, row)
    end
    listingLeftPane.rows = compRows

    local emptyText = listingLeftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyText:SetPoint("CENTER", listingLeftPane, "CENTER", 0, 20)
    self:ApplyFont(emptyText, FONTS.titleBold, 16)
    emptyText:SetTextColor(0.65, 0.65, 0.65, 1.0)
    emptyText:SetText(CM:T("AH_SELL_NO_COMPETITORS") or "No active auctions found for this item.")
    emptyText:Hide()
    listingLeftPane.emptyText = emptyText

    local suggestedTag = listingLeftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    suggestedTag:SetPoint("TOP", emptyText, "BOTTOM", 0, -10)
    self:ApplyFont(suggestedTag, FONTS.medium, 14)
    suggestedTag:SetTextColor(0.12, 1.0, 0.0, 1.0)
    suggestedTag:SetText(CM:T("AH_SELL_SUGGESTED_PRICE") or "Suggested (120% vendor)")
    suggestedTag:Hide()
    listingLeftPane.suggestedTag = suggestedTag

    -- 2. Coluna Direita: Formulário de Venda
    local listingRightPane = CreateFrame("Frame", "ConsoleMode_AuctionSellListingRight", parent)
    listingRightPane:SetPoint("TOPLEFT", listingLeftPane, "TOPRIGHT", 14, 0)
    listingRightPane:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 0)
    parent.listingRightPane = listingRightPane

    self:Create9Slice(listingRightPane, NINESLICE.texture, NINESLICE.cornerSize, NINESLICE.uv, NINESLICE.drawLayer)

    local itemIcon = listingRightPane:CreateTexture(nil, "ARTWORK")
    itemIcon:SetWidth(44)
    itemIcon:SetHeight(44)
    itemIcon:SetPoint("TOPLEFT", listingRightPane, "TOPLEFT", 18, -16)
    listingRightPane.itemIcon = itemIcon

    local itemIconBorder = CreateFrame("Frame", nil, listingRightPane)
    itemIconBorder:SetPoint("TOPLEFT", itemIcon, "TOPLEFT", -2, 2)
    itemIconBorder:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT", 2, -2)
    itemIconBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    listingRightPane.itemIconBorder = itemIconBorder

    local itemName = listingRightPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemName:SetPoint("TOPLEFT", itemIcon, "TOPRIGHT", 12, 0)
    itemName:SetPoint("RIGHT", listingRightPane, "RIGHT", -16, 0)
    itemName:SetJustifyH("LEFT")
    self:ApplyFont(itemName, FONTS.titleBold, 19)
    listingRightPane.itemName = itemName

    local itemBagInfo = listingRightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemBagInfo:SetPoint("TOPLEFT", itemName, "BOTTOMLEFT", 0, -4)
    itemBagInfo:SetPoint("RIGHT", listingRightPane, "RIGHT", -16, 0)
    itemBagInfo:SetJustifyH("LEFT")
    self:ApplyFont(itemBagInfo, FONTS.medium, 14)
    itemBagInfo:SetTextColor(0.75, 0.75, 0.75, 1.0)
    listingRightPane.itemBagInfo = itemBagInfo

    local hDiv = listingRightPane:CreateTexture(nil, "ARTWORK")
    hDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    hDiv:SetHeight(1)
    hDiv:SetPoint("TOPLEFT", listingRightPane, "TOPLEFT", 14, -68)
    hDiv:SetPoint("TOPRIGHT", listingRightPane, "TOPRIGHT", -14, -68)
    hDiv:SetVertexColor(0.5, 0.4, 0.3, 0.35)

    local formRows = {}
    local fStartY = -76
    local fRowH = 34
    local fGap = 4

    for i = 1, 7 do
        local r = CreateFrame("Button", "ConsoleMode_AuctionSellFormRow" .. i, listingRightPane)
        if i == 7 then
            r:SetWidth(106)
            r:SetHeight(30)
            r:SetPoint("TOP", listingRightPane, "TOP", 0, fStartY - ((i - 1) * (fRowH + fGap)) - 2)
            r:SetBackdrop({
                bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile     = true, tileSize = 8, edgeSize = 8,
                insets   = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            r:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
            r:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

            local postIcon = r:CreateTexture(nil, "OVERLAY")
            postIcon:SetWidth(24)
            postIcon:SetHeight(24)
            postIcon:SetPoint("LEFT", r, "LEFT", 10, 0)
            postIcon:SetTexture(ICONS.RT)
            r.postIcon = postIcon

            local postTxt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            postTxt:SetPoint("LEFT", postIcon, "RIGHT", 6, 0)
            self:ApplyFont(postTxt, FONTS.titleBold, 16)
            postTxt:SetText("POST")
            r.postTxt = postTxt

            r:SetScript("OnEnter", function()
                AuctionScreen.sellListingPane = "FORM"
                AuctionScreen.sellFormRow = 7
                AuctionScreen:UpdateSellListingStyles()
            end)
        else
            r:SetHeight(fRowH)
            r:SetPoint("TOPLEFT", listingRightPane, "TOPLEFT", 16, fStartY - ((i - 1) * (fRowH + fGap)))
            r:SetPoint("TOPRIGHT", listingRightPane, "TOPRIGHT", -16, fStartY - ((i - 1) * (fRowH + fGap)))
            r:SetBackdrop({
                bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile     = true, tileSize = 8, edgeSize = 8,
                insets   = { left = 2, right = 2, top = 2, bottom = 2 }
            })

            local lbl = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", r, "LEFT", 12, 0)
            self:ApplyFont(lbl, FONTS.titleBold, 15)
            r.lbl = lbl

            local val = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            val:SetPoint("RIGHT", r, "RIGHT", -12, 0)
            self:ApplyFont(val, FONTS.bodyBold, 15)
            r.val = val

            if i == 1 or i == 2 then
                local mDisp = self:CreateMoneyDisplay(r, 24, 13, "RIGHT", 150)
                mDisp:SetPoint("RIGHT", r, "RIGHT", -10, 0)
                r.moneyDisplay = mDisp
            end
        end

        local rowIdx = i
        r.rowIdx = i
        r:SetScript("OnClick", function()
            AuctionScreen.sellListingPane = "FORM"
            AuctionScreen.sellFormRow = this.rowIdx
            if this.rowIdx == 6 then
                AuctionScreen:ApplyMaxStacks()
            elseif this.rowIdx == 7 then
                AuctionScreen:OpenSellPostConfirmModal()
            elseif this.rowIdx == 1 then
                AuctionScreen:OpenSellMoneyPicker("BID")
            elseif this.rowIdx == 2 then
                AuctionScreen:OpenSellMoneyPicker("BUYOUT")
            elseif this.rowIdx == 3 then
                AuctionScreen.sellDurationIdx = (AuctionScreen.sellDurationIdx or 1) + 1
                if AuctionScreen.sellDurationIdx > 3 then AuctionScreen.sellDurationIdx = 1 end
                AuctionScreen:UpdateSellListingStyles()
            elseif this.rowIdx == 4 then
                AuctionScreen:OpenSellStackSizePicker()
            elseif this.rowIdx == 5 then
                AuctionScreen:OpenSellNumStacksPicker()
            end
            AuctionScreen:UpdateSellListingStyles()
        end)
        if i ~= 7 then
            r:SetScript("OnEnter", function()
                if AuctionScreen.sellListingPane ~= "FORM" or AuctionScreen.sellFormRow ~= this.rowIdx then
                    AuctionScreen.sellListingPane = "FORM"
                    AuctionScreen.sellFormRow = this.rowIdx
                    AuctionScreen:UpdateSellListingStyles()
                end
            end)
        end

        table.insert(formRows, r)
    end
    listingRightPane.formRows = formRows

    formRows[1].lbl:SetText(CM:T("AH_SELL_BID_PRICE") or "Lance Inicial")
    formRows[2].lbl:SetText(CM:T("AH_SELL_BUYOUT_PRICE") or "Compra Imediata")
    formRows[3].lbl:SetText(CM:T("AH_SELL_DURATION") or "Duração")
    formRows[4].lbl:SetText(CM:T("AH_SELL_STACK_SIZE") or "Tamanho da Pilha")
    formRows[5].lbl:SetText(CM:T("AH_SELL_NUM_STACKS") or "Número de Pilhas")
    formRows[6].lbl:SetText(CM:T("AH_SELL_BTN_MAX") or "MAX")
    formRows[6].val:SetText("[ Calcular Máximo de Pilhas ]")

    local sDiv = listingRightPane:CreateTexture(nil, "ARTWORK")
    sDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    sDiv:SetHeight(1)
    sDiv:SetPoint("BOTTOMLEFT", listingRightPane, "BOTTOMLEFT", 14, 122)
    sDiv:SetPoint("BOTTOMRIGHT", listingRightPane, "BOTTOMRIGHT", -14, 122)
    sDiv:SetVertexColor(0.5, 0.4, 0.3, 0.45)

    local sumHeader = listingRightPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sumHeader:SetPoint("TOPLEFT", sDiv, "BOTTOMLEFT", 4, -6)
    self:ApplyFont(sumHeader, FONTS.titleBold, 15)
    sumHeader:SetText(CM:T("AH_SELL_SUMMARY_HEADER") or "RESUMO DO LEILÃO")
    sumHeader:SetTextColor(0.95, 0.82, 0.35, 1.0)

    local sumTotalItems = listingRightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sumTotalItems:SetPoint("TOPLEFT", sumHeader, "BOTTOMLEFT", 0, -3)
    self:ApplyFont(sumTotalItems, FONTS.medium, 14)
    sumTotalItems:SetTextColor(0.85, 0.85, 0.85, 1.0)
    listingRightPane.sumTotalItems = sumTotalItems

    local sumUnitPriceLabel = listingRightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sumUnitPriceLabel:SetPoint("TOPLEFT", sumTotalItems, "BOTTOMLEFT", 0, -3)
    self:ApplyFont(sumUnitPriceLabel, FONTS.medium, 14)
    sumUnitPriceLabel:SetText(CM:T("AH_SELL_UNIT_PRICE") or "Preço por Unidade:")
    sumUnitPriceLabel:SetTextColor(0.85, 0.85, 0.85, 1.0)
    listingRightPane.sumUnitPriceLabel = sumUnitPriceLabel

    local sumUnitPriceDisplay = self:CreateMoneyDisplay(listingRightPane, 20, 14, "LEFT")
    sumUnitPriceDisplay:SetPoint("LEFT", sumUnitPriceLabel, "RIGHT", 6, 0)
    listingRightPane.sumUnitPriceDisplay = sumUnitPriceDisplay

    local sumBuyoutLabel = listingRightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sumBuyoutLabel:SetPoint("TOPLEFT", sumUnitPriceLabel, "BOTTOMLEFT", 0, -3)
    self:ApplyFont(sumBuyoutLabel, FONTS.medium, 14)
    sumBuyoutLabel:SetText(CM:T("AH_SELL_ESTIMATED_PROFIT") or "Total Buyout:")
    sumBuyoutLabel:SetTextColor(0.85, 0.85, 0.85, 1.0)
    listingRightPane.sumBuyoutLabel = sumBuyoutLabel

    local sumBuyoutDisplay = self:CreateMoneyDisplay(listingRightPane, 20, 14, "LEFT")
    sumBuyoutDisplay:SetPoint("LEFT", sumBuyoutLabel, "RIGHT", 6, 0)
    listingRightPane.sumBuyoutDisplay = sumBuyoutDisplay

    local sumDepositLabel = listingRightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sumDepositLabel:SetPoint("TOPLEFT", sumBuyoutLabel, "BOTTOMLEFT", 0, -3)
    self:ApplyFont(sumDepositLabel, FONTS.medium, 14)
    sumDepositLabel:SetText("Taxa Depósito:")
    sumDepositLabel:SetTextColor(0.70, 0.70, 0.70, 1.0)
    listingRightPane.sumDepositLabel = sumDepositLabel

    local sumDepositDisplay = self:CreateMoneyDisplay(listingRightPane, 20, 14, "LEFT")
    sumDepositDisplay:SetPoint("LEFT", sumDepositLabel, "RIGHT", 6, 0)
    listingRightPane.sumDepositDisplay = sumDepositDisplay
end

function AuctionScreen:OpenSellInventory()
    local invScan = CM.auctionScan or ConsoleMode_AuctionScan
    if invScan and self.pendingSellScanItem and invScan.isScanning then
        pcall(function() invScan:AbortQuery() end)
    end
    self.pendingSellScanItem = nil
    self.sellScanActive = nil
    self:SetSellScanVisible(false)
    self.sellStep = "INVENTORY"
    self:CloseSellPostConfirmModal()

    if self.sellListingContainer then self.sellListingContainer:Hide() end
    if self.sellContainer then self.sellContainer:Show() end

    self:RefreshSellInventory()

    if self.breadcrumb and self.breadcrumb.text then
        local sep = CM:T("AH_BREADCRUMB_SEP") or " > "
        self.breadcrumb.text:SetText(CM:T("AH_TAB_SELL") .. sep .. (CM:T("AH_SELL_BAG_TITLE") or "Your Inventory"))
    end

    self:UpdateFooterHints()
end

function AuctionScreen:OpenSellListing(item)
    if not item then return end
    local staleScan = CM.auctionScan or ConsoleMode_AuctionScan
    if staleScan and staleScan.isScanning and self.pendingSellScanItem then
        self.pendingSellScanItem = nil
        self.sellScanActive = nil
        pcall(function() staleScan:AbortQuery() end)
    end
    self.sellStep = "LISTING"
    self.selectedSellItem = item
    self.sellListingPane = "FORM"
    self.sellFormRow = 1
    self.sellDurationIdx = 1
    self.sellStackSize = 1
    self.sellNumStacks = 1
    self.sellMoneyStepIdx = 3

    if self.sellContainer then self.sellContainer:Hide() end
    if self.sellListingContainer then self.sellListingContainer:Show() end
    self:SetSellScanVisible(false)

    self:LoadSellCompetitors(item)

    if table.getn(self.sellCompetitors) > 0 then
        self.selectedCompetitorIndex = 1
        self.sellCompetitorScrollOffset = 0
        self:MirrorCompetitorPrice(1)
    else
        local vPrice = item.vendorPrice or 0
        local suggestedUnit = math.max(1, math.floor(vPrice * 1.2))
        self.sellBidPrice = math.max(1, math.floor(suggestedUnit * 0.85)) * self.sellStackSize
        self.sellBuyoutPrice = suggestedUnit * self.sellStackSize
    end

    if self.breadcrumb and self.breadcrumb.text then
        local sep = CM:T("AH_BREADCRUMB_SEP") or " > "
        local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
        self.breadcrumb.text:SetText(CM:T("AH_TAB_SELL") .. sep .. locName)
    end

    self:UpdateSellListingStyles()
    self:UpdateFooterHints()
end

function AuctionScreen:OpenSellListingWithScan(item, forceRescan)
    if not item then return end
    self.pendingSellScanItem = item
    self:OpenSellListing(item)
    self.pendingSellScanItem = item

    local sellCacheKey = self:GetSellCacheKey(item)
    if not forceRescan then
        local cached = self:GetCacheEntry(sellCacheKey)
        if cached then
            self.pendingSellScanItem = nil
            self.sellScanActive = nil
            self:SetSellScanVisible(false)
            self.scanResults = cached.results
            self:GroupScanResults()
            self:LoadSellCompetitors(item)
            if self.sellCompetitors and table.getn(self.sellCompetitors) > 0 then
                self.selectedCompetitorIndex = 1
                self.sellCompetitorScrollOffset = 0
                self:MirrorCompetitorPrice(1)
                self.sellListingPane = "COMPETITORS"
            end
            self:UpdateSellCompetitorsList()
            self:UpdateSellListingStyles()
            self:UpdateFooterHints()
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[ConsoleMode AH]|r " .. string.format(CM:T("AH_CACHE_LOADED_FMT") or "Loaded %s auctions from memory cache (TTL 2m)", tostring(cached.totalCount or (cached.results and table.getn(cached.results)) or 0)))
            end
            return
        end
    else
        self:InvalidateCacheEntry(sellCacheKey)
    end

    local scan = CM.auctionScan or ConsoleMode_AuctionScan
    if not scan or not scan.StartQuery then
        self.pendingSellScanItem = nil
        self.sellScanActive = nil
        return
    end

    if AuctionFrameTab_OnClick then
        pcall(AuctionFrameTab_OnClick, 1)
    end

    if scan.isScanning then
        pcall(function() scan:AbortQuery() end)
    end
    self.pendingSellScanItem = item
    self.sellScanActive = true
    local scanName = self:GetBagItemRealName(item)
    if not scanName or scanName == "" or scanName == "Unknown" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode AH]|r Scan: cannot identify item name, using vendor suggestion")
        end
        self.pendingSellScanItem = nil
        self.sellScanActive = nil
        self:UpdateSellCompetitorsList()
        return
    end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[ConsoleMode AH]|r Scan: " .. tostring(scanName) .. "...")
    end
    self:UpdateSellCompetitorsList()
    self:SetSellScanVisible(true)

    local queryParams = {
        name          = scanName,
        minLevel      = 0,
        maxLevel      = 0,
        invTypeIndex  = 0,
        classIndex    = 0,
        subClassIndex = 0,
        isUsable      = 0,
        qualityIndex  = -1,
    }

    scan:StartQuery(
        queryParams,
        function(currentPage, totalPages, batchCount, totalCount)
            if not AuctionScreen.isOpen then return end
            if AuctionScreen.sellStep ~= "LISTING" then return end
            if AuctionScreen.pendingSellScanItem ~= item then return end
            AuctionScreen:UpdateSellScanProgress(currentPage, totalPages, batchCount, totalCount)
        end,
        function(results, totalCount, wasAborted)
            if not AuctionScreen.isOpen then
                AuctionScreen.sellScanActive = nil
                return
            end
            if AuctionScreen.sellStep ~= "LISTING" then
                AuctionScreen.sellScanActive = nil
                return
            end
            if AuctionScreen.pendingSellScanItem ~= AuctionScreen.selectedSellItem then
                AuctionScreen.sellScanActive = nil
                return
            end
            if AuctionScreen.pendingSellScanItem ~= item then
                AuctionScreen.sellScanActive = nil
                return
            end
            AuctionScreen.pendingSellScanItem = nil
            AuctionScreen.sellScanActive = nil
            AuctionScreen:SetSellScanVisible(false)
            if wasAborted then return end
            local total = 0
            if results then total = table.getn(results) end
            if total == 0 then
                if DEFAULT_CHAT_FRAME then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode AH]|r Scan: no auctions found, using vendor suggestion")
                end
                AuctionScreen:UpdateSellCompetitorsList()
                return
            end
            local targetId = nil
            if item.link then
                local _, _, foundId = string.find(item.link, "item:(%d+)")
                if foundId then targetId = foundId end
            end
            local matchCount = 0
            for i = 1, total do
                local r = results[i]
                if r then
                    if r.name == scanName then
                        matchCount = matchCount + 1
                    elseif targetId and r.link then
                        local _, _, rid = string.find(r.link, "item:(%d+)")
                        if rid and rid == targetId then
                            matchCount = matchCount + 1
                        end
                    end
                end
            end
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[ConsoleMode AH]|r Scan done: " .. tostring(totalCount or total) .. " auctions (" .. tostring(matchCount) .. " match)")
            end
            if matchCount == 0 then return end
            AuctionScreen:SetCacheEntry(sellCacheKey, results, totalCount or total)
            AuctionScreen.scanResults = results
            AuctionScreen:GroupScanResults()
            AuctionScreen:LoadSellCompetitors(item)
            if AuctionScreen.sellCompetitors and table.getn(AuctionScreen.sellCompetitors) > 0 then
                AuctionScreen.selectedCompetitorIndex = 1
                AuctionScreen.sellCompetitorScrollOffset = 0
                AuctionScreen:MirrorCompetitorPrice(1)
                AuctionScreen.sellListingPane = "COMPETITORS"
                AuctionScreen:UpdateSellCompetitorsList()
                AuctionScreen:UpdateSellListingStyles()
                AuctionScreen:UpdateFooterHints()
            end
            AuctionScreen:UpdateSellCompetitorsList()
            AuctionScreen:UpdateSellListingStyles()
            AuctionScreen:UpdateFooterHints()
        end,
        function(err)
            AuctionScreen.pendingSellScanItem = nil
            AuctionScreen.sellScanActive = nil
            AuctionScreen:SetSellScanVisible(false)
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode AH]|r Scan error: " .. tostring(err))
            end
            AuctionScreen:UpdateSellCompetitorsList()
        end
    )
end

function AuctionScreen:LoadSellCompetitors(item)
    self.sellCompetitors = {}
    if not item then return end

    for _, g in ipairs(self.groupedItems or {}) do
        if g.name == item.name or g.key == item.key then
            for _, a in ipairs(g.auctions or {}) do
                table.insert(self.sellCompetitors, a)
            end
            break
        end
    end

    if table.getn(self.sellCompetitors) == 0 then
        local targetId = nil
        if item.link then
            local _, _, foundId = string.find(item.link, "item:(%d+)")
            if foundId then targetId = foundId end
        end
        for _, r in ipairs(self.scanResults or {}) do
            if r.name == item.name then
                table.insert(self.sellCompetitors, r)
            elseif targetId and r.link then
                local _, _, rid = string.find(r.link, "item:(%d+)")
                if rid and rid == targetId then
                    table.insert(self.sellCompetitors, r)
                end
            end
        end
    end

    table.sort(self.sellCompetitors, function(a, b)
        local countA = (a.count and a.count > 0) and a.count or 1
        local countB = (b.count and b.count > 0) and b.count or 1
        local unitA = (a.buyoutPrice and a.buyoutPrice > 0) and math.floor(a.buyoutPrice / countA) or 99999999
        local unitB = (b.buyoutPrice and b.buyoutPrice > 0) and math.floor(b.buyoutPrice / countB) or 99999999
        return unitA < unitB
    end)

    local nComp = table.getn(self.sellCompetitors)
    if (self.selectedCompetitorIndex or 1) > nComp then
        self.selectedCompetitorIndex = math.max(1, nComp)
    end
    if (self.selectedCompetitorIndex or 1) < 1 then
        self.selectedCompetitorIndex = 1
    end
    local maxOff = nComp - 6
    if maxOff < 0 then maxOff = 0 end
    if (self.sellCompetitorScrollOffset or 0) > maxOff then
        self.sellCompetitorScrollOffset = maxOff
    end

    self:UpdateSellCompetitorsList()
end

function AuctionScreen:UpdateSellCompetitorsList()
    if not self.sellListingContainer or not self.sellListingContainer.listingLeftPane then return end
    local leftPane = self.sellListingContainer.listingLeftPane
    local rows = leftPane.rows
    local numComps = (self.sellCompetitors and table.getn(self.sellCompetitors)) or 0

    if self.sellScanActive then
        if rows then
            for i = 1, 6 do
                if rows[i] then rows[i]:Hide() end
            end
        end
        if leftPane.emptyText then leftPane.emptyText:Hide() end
        if leftPane.suggestedTag then leftPane.suggestedTag:Hide() end
        return
    end

    if numComps == 0 then
        if self.sellScanActive and leftPane.sellScanPageText and leftPane.sellScanBar then
            for i = 1, 6 do
                if rows[i] then rows[i]:Hide() end
            end
            return
        end
        if self.sellScanActive then
            local scanText = CM:T("AH_SCAN_PROGRESS_FMT") or "Scanning page %d..."
            leftPane.emptyText:SetText(string.format(scanText, 1))
            leftPane.emptyText:Show()
            leftPane.suggestedTag:Hide()
        else
            leftPane.emptyText:SetText(CM:T("AH_SELL_NO_COMPETITORS") or "No active auctions found for this item.")
            leftPane.emptyText:Show()
            leftPane.suggestedTag:Show()
        end
        for i = 1, 6 do
            if rows[i] then rows[i]:Hide() end
        end
        return
    end

    leftPane.emptyText:Hide()
    leftPane.suggestedTag:Hide()

    local offset = self.sellCompetitorScrollOffset or 0
    if offset < 0 then
        offset = 0
        self.sellCompetitorScrollOffset = 0
    end
    local maxOffset = numComps - 6
    if maxOffset < 0 then maxOffset = 0 end
    if offset > maxOffset then
        offset = maxOffset
        self.sellCompetitorScrollOffset = offset
    end

    for i = 1, 6 do
        local row = rows[i]
        local compIdx = offset + i
        if compIdx <= numComps then
            local comp = self.sellCompetitors[compIdx]
            local count = (comp.count and comp.count > 0) and comp.count or 1
            local unitBid = math.floor((comp.minBid or comp.bidAmount or 0) / count)
            local unitBuyout = math.floor((comp.buyoutPrice or 0) / count)

            local seller = comp.owner or comp.seller or "Leilão"
            local timeLeftIdx = comp.timeLeft or comp.duration
            local durKey = (timeLeftIdx and TIME_LEFT_KEYS[timeLeftIdx]) or "AH_TIME_SHORT"
            row.sellerText:SetText(seller .. " (" .. (CM:T(durKey) or "") .. ")")

            row.stackText:SetText("x" .. tostring(count))
            self:SetMoneyDisplay(row.unitBidDisplay, unitBid)
            self:SetMoneyDisplay(row.unitBuyDisplay, unitBuyout)

            local isSelected = (self.sellListingPane == "COMPETITORS" and compIdx == self.selectedCompetitorIndex)
            if isSelected then
                row:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                row:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
                row.sellerText:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)
            else
                row:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                row:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
                row.sellerText:SetTextColor(1.0, 1.0, 1.0, 1.0)
            end

            row:Show()
        else
            row:Hide()
        end
    end
end

function AuctionScreen:SetSellScanVisible(visible)
    if not self.sellListingContainer or not self.sellListingContainer.listingLeftPane then return end
    local leftPane = self.sellListingContainer.listingLeftPane
    if not leftPane.sellScanPageText or not leftPane.sellScanBar then return end
    if visible then
        local progFmt = CM:T("AH_SCAN_PROGRESS_FMT") or "Scanning page %d..."
        leftPane.sellScanPageText:SetText(string.format(progFmt, 1))
        if leftPane.sellScanBar.fill then
            leftPane.sellScanBar.fill:SetWidth(10)
        end
        leftPane.sellScanPageText:Show()
        leftPane.sellScanBar:Show()
        if leftPane.compHeader then leftPane.compHeader:Hide() end
        if leftPane.rows then
            for i = 1, 6 do
                if leftPane.rows[i] then leftPane.rows[i]:Hide() end
            end
        end
        if leftPane.emptyText then leftPane.emptyText:Hide() end
        if leftPane.suggestedTag then leftPane.suggestedTag:Hide() end
    else
        leftPane.sellScanPageText:Hide()
        leftPane.sellScanBar:Hide()
        if leftPane.compHeader then leftPane.compHeader:Show() end
        self:UpdateSellCompetitorsList()
    end
end

function AuctionScreen:UpdateSellScanProgress(currentPage, totalPages, batchCount, totalCount)
    if not self.sellScanActive then return end
    if not self.sellListingContainer or not self.sellListingContainer.listingLeftPane then return end
    local leftPane = self.sellListingContainer.listingLeftPane
    if not leftPane.sellScanPageText or not leftPane.sellScanBar or not leftPane.sellScanBar.fill then return end
    self:SetSellScanVisible(true)
    totalPages = totalPages or 1
    if totalPages < 1 then totalPages = 1 end
    currentPage = currentPage or 0
    local pageFmt = CM:T("AH_SCAN_PAGE_FMT") or "Page %d of %d..."
    leftPane.sellScanPageText:SetText(string.format(pageFmt, currentPage + 1, totalPages))
    local progress = (currentPage + 1) / totalPages
    if progress > 1.0 then progress = 1.0 end
    if progress < 0.02 then progress = 0.02 end
    local maxW = 420 - 6
    leftPane.sellScanBar.fill:SetWidth(math.floor(maxW * progress))
end

function AuctionScreen:MirrorCompetitorPrice(compIndex)
    if not self.sellCompetitors or not self.sellCompetitors[compIndex] then return end
    local comp = self.sellCompetitors[compIndex]
    local count = (comp.count and comp.count > 0) and comp.count or 1
    local unitBid = math.floor((comp.minBid or comp.bidAmount or 0) / count)
    local unitBuyout = math.floor((comp.buyoutPrice or 0) / count)

    self.sellBidPrice = math.max(1, unitBid * self.sellStackSize)
    self.sellBuyoutPrice = math.max(0, unitBuyout * self.sellStackSize)
    self:UpdateSellListingStyles()
end

function AuctionScreen:ScrollSellCompetitors(delta)
    local total = table.getn(self.sellCompetitors or {})
    if total <= 0 then return end

    local newIdx = (self.selectedCompetitorIndex or 1) + delta
    if newIdx < 1 then newIdx = 1 end
    if newIdx > total then newIdx = total end

    self.selectedCompetitorIndex = newIdx

    local offset = self.sellCompetitorScrollOffset or 0
    if newIdx <= offset then
        self.sellCompetitorScrollOffset = newIdx - 1
    elseif newIdx > offset + 6 then
        self.sellCompetitorScrollOffset = newIdx - 6
    end

    self:MirrorCompetitorPrice(newIdx)
    self:UpdateSellCompetitorsList()
end

function AuctionScreen:CycleSellMoneyStep()
    self.sellMoneyStepIdx = (self.sellMoneyStepIdx or 3) + 1
    if self.sellMoneyStepIdx > table.getn(SELL_MONEY_STEPS) then
        self.sellMoneyStepIdx = 1
    end
    self:UpdateSellListingStyles()
end

function AuctionScreen:AdjustSellMoney(moneyType, delta)
    local step = SELL_MONEY_STEPS[self.sellMoneyStepIdx or 3] or 100
    if moneyType == "BID" then
        local val = (self.sellBidPrice or 0) + (delta * step)
        if val < 1 then val = 1 end
        self.sellBidPrice = val
        if self.sellBuyoutPrice > 0 and self.sellBidPrice > self.sellBuyoutPrice then
            self.sellBuyoutPrice = self.sellBidPrice
        end
    else
        local val = (self.sellBuyoutPrice or 0) + (delta * step)
        if val < 0 then val = 0 end
        self.sellBuyoutPrice = val
        if self.sellBuyoutPrice > 0 and self.sellBuyoutPrice < self.sellBidPrice then
            self.sellBidPrice = self.sellBuyoutPrice
        end
    end
    self:UpdateSellListingStyles()
end

function AuctionScreen:IsMoneyModalOpen()
    local mp = CM.MoneyPicker or ConsoleMode_MoneyPicker
    if mp and mp.IsOpen then return mp:IsOpen() end
    return false
end

function AuctionScreen:OpenSellMoneyPicker(moneyType)
    local mp = CM.MoneyPicker or ConsoleMode_MoneyPicker
    if not mp or not mp.Open then return end

    local curVal = (moneyType == "BID") and (self.sellBidPrice or 0) or (self.sellBuyoutPrice or 0)
    local title = (moneyType == "BID") and (CM:T("AH_SELL_BID_PRICE") or "Lance Inicial") or (CM:T("AH_SELL_BUYOUT_PRICE") or "Compra Imediata")
    local minC = (moneyType == "BID") and 1 or 0

    mp:Open({
        title       = title,
        copper      = curVal,
        minCopper   = minC,
        maxCopper   = nil,
        showBalance = false,
        onConfirm   = function(copper)
            if moneyType == "BID" then
                if copper < 1 then copper = 1 end
                AuctionScreen.sellBidPrice = copper
                if AuctionScreen.sellBuyoutPrice > 0 and AuctionScreen.sellBidPrice > AuctionScreen.sellBuyoutPrice then
                    AuctionScreen.sellBuyoutPrice = AuctionScreen.sellBidPrice
                end
            else
                AuctionScreen.sellBuyoutPrice = copper
                if AuctionScreen.sellBuyoutPrice > 0 and AuctionScreen.sellBuyoutPrice < AuctionScreen.sellBidPrice then
                    AuctionScreen.sellBidPrice = AuctionScreen.sellBuyoutPrice
                end
            end
            AuctionScreen:UpdateSellListingStyles()
        end,
        onCancel    = function() end,
    })
end

function AuctionScreen:OpenSellMoneyVK(moneyType)
    self:OpenSellMoneyPicker(moneyType)
end

function AuctionScreen:IsQtyModalOpen()
    local qp = CM.QuantityPicker or ConsoleMode_QuantityPicker
    if qp and qp.IsOpen then return qp:IsOpen() end
    return false
end

function AuctionScreen:GetMaxUnitsPerStack(item)
    if not item then return 1 end
    local total = tonumber(item.totalCount) or 1
    if total < 1 then total = 1 end

    local maxGame = tonumber(item.maxStack) or 0
    if maxGame > 1 then
        return math.min(maxGame, total)
    end
    return total
end

function AuctionScreen:SetSellStackSize(newS)
    local item = self.selectedSellItem
    if not item then return end

    local maxS = self:GetMaxUnitsPerStack(item)
    newS = tonumber(newS) or 1
    if newS < 1 then newS = 1 end
    if newS > maxS then newS = maxS end

    local prevS = self.sellStackSize or 1
    self.sellStackSize = newS

    if prevS > 0 and prevS ~= newS then
        local unitBid = math.floor((self.sellBidPrice or 1) / prevS)
        local unitBuy = math.floor((self.sellBuyoutPrice or 0) / prevS)
        self.sellBidPrice = math.max(1, unitBid * newS)
        self.sellBuyoutPrice = math.max(0, unitBuy * newS)
    end

    local maxStacks = math.max(1, math.floor((item.totalCount or 1) / newS))
    if (self.sellNumStacks or 1) > maxStacks then
        self.sellNumStacks = maxStacks
    end

    self:UpdateSellListingStyles()
end

function AuctionScreen:SetSellNumStacks(newNum)
    local item = self.selectedSellItem
    if not item then return end

    local u = self.sellStackSize or 1
    if u < 1 then u = 1 end
    local maxStacks = math.max(1, math.floor((item.totalCount or 1) / u))
    newNum = tonumber(newNum) or 1
    if newNum < 1 then newNum = 1 end
    if newNum > maxStacks then newNum = maxStacks end

    self.sellNumStacks = newNum
    self:UpdateSellListingStyles()
end

function AuctionScreen:OpenSellStackSizePicker()
    local item = self.selectedSellItem
    if not item then return end
    local maxS = self:GetMaxUnitsPerStack(item)
    local qp = CM.QuantityPicker or ConsoleMode_QuantityPicker
    if not qp or not qp.Open then return end
    qp:Open({
        title = CM:T("AH_SELL_STACK_SIZE") or "Tamanho da Pilha",
        itemName = item.name or "Item",
        qty = self.sellStackSize or 1,
        maxQty = maxS,
        onConfirm = function(newQty)
            AuctionScreen:SetSellStackSize(newQty)
        end,
        onCancel = function() end,
    })
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
end

function AuctionScreen:OpenSellNumStacksPicker()
    local item = self.selectedSellItem
    if not item then return end
    local u = self.sellStackSize or 1
    if u < 1 then u = 1 end
    local maxStacks = math.max(1, math.floor((item.totalCount or 1) / u))
    local qp = CM.QuantityPicker or ConsoleMode_QuantityPicker
    if not qp or not qp.Open then return end
    qp:Open({
        title = CM:T("AH_SELL_NUM_STACKS") or "Número de Pilhas",
        itemName = item.name or "Item",
        qty = self.sellNumStacks or 1,
        maxQty = maxStacks,
        onConfirm = function(newQty)
            AuctionScreen:SetSellNumStacks(newQty)
        end,
        onCancel = function() end,
    })
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
end

function AuctionScreen:AdjustSellStackSize(delta)
    local newS = (self.sellStackSize or 1) + (delta or 0)
    self:SetSellStackSize(newS)
end

function AuctionScreen:AdjustSellNumStacks(delta)
    local newNum = (self.sellNumStacks or 1) + (delta or 0)
    self:SetSellNumStacks(newNum)
end

function AuctionScreen:ApplyMaxStacks()
    local item = self.selectedSellItem
    if not item then return end

    local total = item.totalCount or 1
    local maxS = self:GetMaxUnitsPerStack(item)

    local prevS = self.sellStackSize or 1
    self.sellStackSize = maxS
    self.sellNumStacks = math.max(1, math.floor(total / self.sellStackSize))

    if prevS > 0 and self.sellStackSize ~= prevS then
        local unitBid = math.floor((self.sellBidPrice or 1) / prevS)
        local unitBuy = math.floor((self.sellBuyoutPrice or 0) / prevS)
        self.sellBidPrice = math.max(1, unitBid * self.sellStackSize)
        self.sellBuyoutPrice = math.max(0, unitBuy * self.sellStackSize)
    end

    self:UpdateSellListingStyles()
end

function AuctionScreen:CalculateSellDeposit()
    local item = self.selectedSellItem
    if not item then return 0 end

    local factor = 0.15
    if self.sellDurationIdx == 2 then
        factor = 0.60
    elseif self.sellDurationIdx == 3 then
        factor = 1.20
    end

    local vPrice = item.vendorPrice or 0
    if vPrice <= 0 then return 0 end

    local unitDeposit = math.max(1, math.floor(vPrice * factor))
    return unitDeposit * (self.sellStackSize or 1) * (self.sellNumStacks or 1)
end

function AuctionScreen:UpdateSellListingStyles()
    if not self.sellListingContainer or not self.sellListingContainer.listingRightPane then return end
    local rightPane = self.sellListingContainer.listingRightPane
    local item = self.selectedSellItem
    if not item then return end

    local qColor = QUALITY_COLORS[item.quality] or { 0.8, 0.8, 0.8 }
    rightPane.itemIcon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    rightPane.itemIconBorder:SetBackdropBorderColor(qColor[1], qColor[2], qColor[3], 0.95)

    local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
    rightPane.itemName:SetText(locName)
    rightPane.itemName:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

    local bagInfo = string.format("Disponível na bolsa: %d • Preço Loja: %s", item.totalCount, self:FormatMoney(item.vendorPrice or 0))
    rightPane.itemBagInfo:SetText(bagInfo)

    local durLabels = {
        CM:T("AH_SELL_DURATION_2H") or "2 Horas",
        CM:T("AH_SELL_DURATION_8H") or "8 Horas",
        CM:T("AH_SELL_DURATION_24H") or "24 Horas"
    }

    local rows = rightPane.formRows
    self:SetMoneyDisplay(rows[1].moneyDisplay, self.sellBidPrice or 0)
    self:SetMoneyDisplay(rows[2].moneyDisplay, self.sellBuyoutPrice or 0)
    rows[3].val:SetText(durLabels[self.sellDurationIdx or 1] or "")
    rows[4].val:SetText(tostring(self.sellStackSize or 1))
    rows[5].val:SetText(tostring(self.sellNumStacks or 1))

    local stepLabel = SELL_MONEY_LABELS[self.sellMoneyStepIdx or 3] or "1s"
    for i = 1, 7 do
        local r = rows[i]
        local isFocused = (self.sellListingPane == "FORM" and i == self.sellFormRow)
        if isFocused then
            r:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
            r:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
            if r.lbl then r.lbl:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0) end
            if r.postTxt then r.postTxt:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0) end
        else
            if i == 7 then
                r:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
                r:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
                if r.postTxt then r.postTxt:SetTextColor(1.0, 1.0, 1.0, 1.0) end
            else
                r:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                r:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
                if r.lbl then r.lbl:SetTextColor(0.80, 0.80, 0.80, 0.90) end
            end
        end
    end

    local stackS = self.sellStackSize or 1
    local numS = self.sellNumStacks or 1
    local totalUnits = stackS * numS
    local totalBuyout = (self.sellBuyoutPrice or 0) * numS
    local unitPrice = (stackS > 0) and math.floor((self.sellBuyoutPrice or 0) / stackS) or (self.sellBuyoutPrice or 0)
    local deposit = self:CalculateSellDeposit()

    rightPane.sumTotalItems:SetText(string.format("Total: %d item(s) (%d pilha(s) de %d)", totalUnits, numS, stackS))
    self:SetMoneyDisplay(rightPane.sumUnitPriceDisplay, unitPrice)
    self:SetMoneyDisplay(rightPane.sumBuyoutDisplay, totalBuyout)
    self:SetMoneyDisplay(rightPane.sumDepositDisplay, deposit)

    self:UpdateSellCompetitorsList()
    self:UpdateFooterHints()
end

function AuctionScreen:CreateSellPostConfirmModal(parent)
    local modalDimmer = CreateFrame("Frame", "ConsoleMode_AuctionSellPostDimmer", parent)
    modalDimmer:SetFrameStrata("DIALOG")
    modalDimmer:SetFrameLevel(45)
    modalDimmer:SetAllPoints(UIParent)
    modalDimmer:EnableMouse(true)
    modalDimmer:Hide()

    local bg = modalDimmer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(modalDimmer)
    bg:SetTexture(0, 0, 0, 0.70)
    modalDimmer.bg = bg

    local modal = CreateFrame("Frame", "ConsoleMode_AuctionSellPostModal", modalDimmer)
    modal:SetWidth(480)
    modal:SetHeight(320)
    modal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(50)
    modal:EnableMouse(true)

    self:Create9Slice(modal, NINESLICE.texture, NINESLICE.cornerSize, NINESLICE.uv, NINESLICE.drawLayer)

    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -20)
    self:ApplyFont(title, FONTS.titleBold, 22)
    title:SetTextColor(1.0, 0.85, 0.25, 1.0)
    title:SetText(CM:T("AH_SELL_CONFIRM_TITLE") or "Confirmar Postagem?")
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

    local qtyText = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    qtyText:SetPoint("TOPLEFT", itemIcon, "BOTTOMLEFT", 0, -12)
    self:ApplyFont(qtyText, FONTS.bodyBold, 15)
    qtyText:SetTextColor(0.85, 0.85, 0.85, 1.0)
    modal.qtyText = qtyText

    local unitPriceLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    unitPriceLabel:SetPoint("TOPLEFT", qtyText, "BOTTOMLEFT", 0, -8)
    self:ApplyFont(unitPriceLabel, FONTS.bodyBold, 15)
    unitPriceLabel:SetTextColor(0.85, 0.85, 0.85, 1.0)
    unitPriceLabel:SetText(CM:T("AH_SELL_UNIT_PRICE") or "Preço por Unidade:")
    modal.unitPriceLabel = unitPriceLabel

    local unitPriceDisplay = self:CreateMoneyDisplay(modal, 20, 14, "LEFT")
    unitPriceDisplay:SetPoint("LEFT", unitPriceLabel, "RIGHT", 8, 0)
    modal.unitPriceDisplay = unitPriceDisplay

    local buyoutLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    buyoutLabel:SetPoint("TOPLEFT", unitPriceLabel, "BOTTOMLEFT", 0, -8)
    self:ApplyFont(buyoutLabel, FONTS.bodyBold, 15)
    buyoutLabel:SetTextColor(0.95, 0.82, 0.35, 1.0)
    buyoutLabel:SetText(CM:T("AH_SELL_ESTIMATED_PROFIT") or "Total Buyout:")
    modal.buyoutLabel = buyoutLabel

    local buyoutDisplay = self:CreateMoneyDisplay(modal, 20, 14, "LEFT")
    buyoutDisplay:SetPoint("LEFT", buyoutLabel, "RIGHT", 8, 0)
    modal.buyoutDisplay = buyoutDisplay

    local depositLabel = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    depositLabel:SetPoint("TOPLEFT", buyoutLabel, "BOTTOMLEFT", 0, -8)
    self:ApplyFont(depositLabel, FONTS.medium, 14)
    depositLabel:SetTextColor(0.70, 0.70, 0.70, 1.0)
    depositLabel:SetText("Taxa de Depósito:")
    modal.depositLabel = depositLabel

    local depositDisplay = self:CreateMoneyDisplay(modal, 20, 14, "LEFT")
    depositDisplay:SetPoint("LEFT", depositLabel, "RIGHT", 8, 0)
    modal.depositDisplay = depositDisplay

    local btnContainer = CreateFrame("Frame", nil, modal)
    btnContainer:SetHeight(40)
    btnContainer:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 24, 20)
    btnContainer:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -24, 20)

    local btnConfirm = CreateFrame("Button", "ConsoleMode_AuctionSellConfirmBtn", btnContainer)
    btnConfirm:SetWidth(190)
    btnConfirm:SetHeight(38)
    btnConfirm:SetPoint("LEFT", btnContainer, "LEFT", 10, 0)
    btnConfirm:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    local lConf = btnConfirm:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lConf:SetPoint("CENTER", btnConfirm, "CENTER", 15, 0)
    self:ApplyFont(lConf, FONTS.titleBold, 16)
    lConf:SetText(CM:T("AH_HINT_CONFIRM") or "Confirmar")
    btnConfirm.label = lConf

    local iconA = btnConfirm:CreateTexture(nil, "OVERLAY")
    iconA:SetWidth(28)
    iconA:SetHeight(28)
    iconA:SetPoint("RIGHT", lConf, "LEFT", -6, 0)
    iconA:SetTexture(ICONS.A)
    btnConfirm.icon = iconA

    btnConfirm:SetScript("OnClick", function()
        AuctionScreen:ExecutePostAuction()
    end)
    btnConfirm:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    btnConfirm:SetScript("OnLeave", function()
        AuctionScreen:UpdateSellPostModalStyles()
    end)
    modal.btnConfirm = btnConfirm

    local btnCancel = CreateFrame("Button", "ConsoleMode_AuctionSellCancelBtn", btnContainer)
    btnCancel:SetWidth(190)
    btnCancel:SetHeight(38)
    btnCancel:SetPoint("RIGHT", btnContainer, "RIGHT", -10, 0)
    btnCancel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    local lCanc = btnCancel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lCanc:SetPoint("CENTER", btnCancel, "CENTER", 15, 0)
    self:ApplyFont(lCanc, FONTS.titleBold, 16)
    lCanc:SetText(CM:T("AH_BTN_CANCEL") or "Cancelar")
    btnCancel.label = lCanc

    local iconB = btnCancel:CreateTexture(nil, "OVERLAY")
    iconB:SetWidth(28)
    iconB:SetHeight(28)
    iconB:SetPoint("RIGHT", lCanc, "LEFT", -6, 0)
    iconB:SetTexture(ICONS.B)
    btnCancel.icon = iconB

    btnCancel:SetScript("OnClick", function()
        AuctionScreen:CloseSellPostConfirmModal()
    end)
    btnCancel:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    btnCancel:SetScript("OnLeave", function()
        AuctionScreen:UpdateSellPostModalStyles()
    end)
    modal.btnCancel = btnCancel

    self.sellPostModalDimmer = modalDimmer
    self.sellPostModal = modal
end

function AuctionScreen:OpenSellPostConfirmModal()
    local item = self.selectedSellItem
    if not item or not self.sellPostModal then return end

    self.isSellPostModalOpen = true
    self.sellPostBtnIndex = 1

    local modal = self.sellPostModal
    local qColor = QUALITY_COLORS[item.quality] or { 0.8, 0.8, 0.8 }
    modal.itemIcon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
    modal.itemName:SetText(locName)
    modal.itemName:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

    local stackS = self.sellStackSize or 1
    local numS = self.sellNumStacks or 1
    local totalUnits = stackS * numS
    modal.qtyText:SetText(string.format("%d pilha(s) de %d unidade(s) • Total: %d", numS, stackS, totalUnits))

    local unitPrice = (stackS > 0) and math.floor((self.sellBuyoutPrice or 0) / stackS) or (self.sellBuyoutPrice or 0)
    self:SetMoneyDisplay(modal.unitPriceDisplay, unitPrice)

    local totalBuyout = (self.sellBuyoutPrice or 0) * numS
    self:SetMoneyDisplay(modal.buyoutDisplay, totalBuyout)

    local deposit = self:CalculateSellDeposit()
    self:SetMoneyDisplay(modal.depositDisplay, deposit)

    self:UpdateSellPostModalStyles()
    self.sellPostModalDimmer:Show()
    self:UpdateFooterHints()
end

function AuctionScreen:CloseSellPostConfirmModal()
    self.isSellPostModalOpen = false
    if self.sellPostModalDimmer then
        self.sellPostModalDimmer:Hide()
    end
    self:UpdateFooterHints()
end

function AuctionScreen:UpdateSellPostModalStyles()
    if not self.sellPostModal then return end
    local modal = self.sellPostModal

    if self.sellPostBtnIndex == 1 then
        modal.btnConfirm:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
        modal.btnConfirm:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
        modal.btnConfirm.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)

        modal.btnCancel:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
        modal.btnCancel:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
        modal.btnCancel.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
    else
        modal.btnCancel:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
        modal.btnCancel:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
        modal.btnCancel.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)

        modal.btnConfirm:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
        modal.btnConfirm:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
        modal.btnConfirm.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
    end
end

-- ----------------------------------------------------------------------------
-- 15b. MOTOR DE POSTAGEM DE LEILÃO (ARQUITETURA AUX-ADDON PARA WOW 1.12)
-- ----------------------------------------------------------------------------
-- Baseado no mecanismo de core/stack.lua e core/post.lua do aux-addon:
-- 1. Nunca posta diretamente de um slot onde count ~= stackSize solicitado.
-- 2. Se o slot tiver count > stackSize, transfere o excesso para outro slot
--    (stack parcial com espaço ou slot vazio de bolsa normal).
-- 3. Se tiver count < stackSize, junta itens de outro slot até completar stackSize.
-- 4. Aguarda confirmação do container (slots desbloqueados e contagem exata).
-- 5. Com o slot tendo exatamente stackSize e desbloqueado:
--    ClearCursor() -> ClickAuctionSellItemButton() -> ClearCursor()
--    PickupContainerItem(bag, slot) -> ClickAuctionSellItemButton() -> ClearCursor()
--    StartAuction(bidPrice, buyoutPrice, durMinutes)
-- 6. Aguarda CHAT_MSG_SYSTEM com ERR_AUCTION_STARTED para confirmar cada leilão.
-- 7. Se numStacks > 1, avança sequencialmente para o próximo stack até concluir.
-- ----------------------------------------------------------------------------

function AuctionScreen:IsMatchingSellItem(bag, slot, targetKey)
    if not targetKey then return false end
    local link = GetContainerItemLink(bag, slot)
    if not link then return false end
    local key = self:GetItemKey(link)
    if key ~= targetKey then return false end
    if not self:IsItemAuctionable(bag, slot) then return false end
    return true
end

function AuctionScreen:IsBagNormalContainer(bag)
    if bag == 0 then return true end
    local bagLink = GetInventoryItemLink("player", ContainerIDToInventoryID(bag))
    if not bagLink then return false end
    local _, _, _, _, _, _, bagSubClass = GetItemInfo(bagLink)
    if not bagSubClass then return true end

    local normalBagName = nil
    if GetAuctionItemSubClasses then
        normalBagName = (GetAuctionItemSubClasses(3))
    end
    if normalBagName and bagSubClass == normalBagName then
        return true
    end

    local l = string.lower(bagSubClass)
    if string.find(l, "bag") or string.find(l, "bolsa") then
        if not string.find(l, "soul") and not string.find(l, "herb") and not string.find(l, "alma") and not string.find(l, "erva") and not string.find(l, "enchant") and not string.find(l, "encant") and not string.find(l, "eng") then
            return true
        end
    end
    return false
end

function AuctionScreen:FindEmptyBagSlot()
    for bag = 0, 4 do
        if self:IsBagNormalContainer(bag) then
            local numSlots = GetContainerNumSlots(bag) or 0
            for slot = 1, numSlots do
                local texture, count, locked = GetContainerItemInfo(bag, slot)
                if not texture and not locked then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

function AuctionScreen:FindPartialItemSlot(targetKey, maxStack, excludeBag, excludeSlot)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            if not (bag == excludeBag and slot == excludeSlot) then
                if self:IsMatchingSellItem(bag, slot, targetKey) then
                    local _, count, locked = GetContainerItemInfo(bag, slot)
                    if count and count < maxStack and not locked then
                        return bag, slot, count
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

function AuctionScreen:FindExactItemSlot(targetKey, targetSize)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            if self:IsMatchingSellItem(bag, slot, targetKey) then
                local _, count, locked = GetContainerItemInfo(bag, slot)
                if count and count == targetSize and not locked then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

function AuctionScreen:FindAnyItemSlot(targetKey)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            if self:IsMatchingSellItem(bag, slot, targetKey) then
                local _, count, locked = GetContainerItemInfo(bag, slot)
                if count and count > 0 and not locked then
                    return bag, slot, count
                end
            end
        end
    end
    return nil, nil, nil
end

function AuctionScreen:FindAnotherItemSlot(targetKey, excludeBag, excludeSlot)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            if not (bag == excludeBag and slot == excludeSlot) then
                if self:IsMatchingSellItem(bag, slot, targetKey) then
                    local _, count, locked = GetContainerItemInfo(bag, slot)
                    if count and count > 0 and not locked then
                        return bag, slot, count
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

function AuctionScreen:ExecutePostAuction()
    local item = self.selectedSellItem
    if not item then return end

    self:CloseSellPostConfirmModal()

    if self.postSession and self.postSession.active then
        return
    end

    local itemKey = self:GetItemKey(item.link) or item.key
    if not itemKey then
        UIErrorsFrame:AddMessage(CM:T("AH_SELL_PICKUP_FAILED") or "Couldn't pick up item for auction.", 1.0, 0.2, 0.2, 1.0)
        return
    end

    local durMinutes = 120
    if self.sellDurationIdx == 2 then
        durMinutes = 480
    elseif self.sellDurationIdx == 3 then
        durMinutes = 1440
    end

    local minBid = self.sellBidPrice or 1
    local buyout = self.sellBuyoutPrice or 0
    if minBid < 1 then minBid = 1 end

    local stackSize = self.sellStackSize or 1
    local numStacks = self.sellNumStacks or 1

    self.postSession = {
        active      = true,
        itemKey     = itemKey,
        itemName    = item.name,
        itemLink    = item.link,
        maxStack    = item.maxStack or 1,
        stackSize   = stackSize,
        numStacks   = numStacks,
        posted      = 0,
        duration    = durMinutes,
        bidPrice    = minBid,
        buyoutPrice = buyout,
        step        = "STACKING",
        timer       = 0,
        waitData    = nil
    }

    self:ProcessPostStack()
end

function AuctionScreen:ProcessPostStack()
    local ps = self.postSession
    if not ps or not ps.active then return end

    if ps.posted >= ps.numStacks then
        self:FinishPostSession(true)
        return
    end

    -- 1. Procura slot que ja tenha o tamanho exato do stack e esteja destravado
    local exactBag, exactSlot = self:FindExactItemSlot(ps.itemKey, ps.stackSize)
    if exactBag and exactSlot then
        self:DoPostAuction(exactBag, exactSlot)
        return
    end

    -- 2. Busca qualquer slot destravado com o item
    local tBag, tSlot, tCount = self:FindAnyItemSlot(ps.itemKey)
    if not tBag then
        -- Checa se ha algum slot travado aguardando liberacao do servidor
        local hasLocked = false
        for b = 0, 4 do
            local numSlots = GetContainerNumSlots(b) or 0
            for s = 1, numSlots do
                if self:IsMatchingSellItem(b, s, ps.itemKey) then
                    local _, _, lk = GetContainerItemInfo(b, s)
                    if lk then hasLocked = true end
                end
            end
        end
        if hasLocked then
            ps.step = "STACKING"
            ps.timer = 0
            return
        end

        if ps.posted > 0 then
            self:FinishPostSession(true)
        else
            self:AbortPostSession("AH_SELL_NO_ITEMS")
        end
        return
    end

    -- 3. Slot tem mais itens que stackSize: divide o excesso
    if tCount > ps.stackSize then
        local excess = tCount - ps.stackSize
        local dBag, dSlot, dCount = self:FindPartialItemSlot(ps.itemKey, ps.maxStack, tBag, tSlot)
        if not dBag then
            dBag, dSlot = self:FindEmptyBagSlot()
            dCount = 0
        end

        if not dBag then
            self:AbortPostSession("AH_SELL_BAGS_FULL")
            return
        end

        local space = ps.maxStack - dCount
        local toMove = math.min(space, excess)
        local expectedDest = dCount + toMove

        if CursorHasItem() then ClearCursor() end
        SplitContainerItem(tBag, tSlot, toMove)
        PickupContainerItem(dBag, dSlot)
        if CursorHasItem() then ClearCursor() end

        ps.step = "WAIT_STACK"
        ps.timer = 0
        ps.waitData = {
            dBag = dBag,
            dSlot = dSlot,
            expectedCount = expectedDest,
            tBag = tBag,
            tSlot = tSlot
        }
        return
    end

    -- 4. Slot tem menos itens que stackSize: puxa de outro slot
    if tCount < ps.stackSize then
        local sBag, sSlot, sCount = self:FindAnotherItemSlot(ps.itemKey, tBag, tSlot)
        if not sBag then
            if ps.posted > 0 then
                self:FinishPostSession(true)
            else
                self:AbortPostSession("AH_SELL_NO_ITEMS")
            end
            return
        end

        local needed = ps.stackSize - tCount
        local toMove = math.min(sCount, needed)
        local expectedTarget = tCount + toMove

        if CursorHasItem() then ClearCursor() end
        if sCount <= toMove then
            PickupContainerItem(sBag, sSlot)
        else
            SplitContainerItem(sBag, sSlot, toMove)
        end
        PickupContainerItem(tBag, tSlot)
        if CursorHasItem() then ClearCursor() end

        ps.step = "WAIT_STACK"
        ps.timer = 0
        ps.waitData = {
            dBag = tBag,
            dSlot = tSlot,
            expectedCount = expectedTarget,
            tBag = sBag,
            tSlot = sSlot
        }
        return
    end
end

function AuctionScreen:DoPostAuction(tBag, tSlot)
    local ps = self.postSession
    if not ps or not ps.active then return end

    local _, count, locked = GetContainerItemInfo(tBag, tSlot)
    if locked then
        ps.step = "STACKING"
        ps.timer = 0
        return
    end

    if count ~= ps.stackSize then
        ps.step = "STACKING"
        ps.timer = 0
        self:ProcessPostStack()
        return
    end

    if CursorHasItem() then ClearCursor() end
    ClickAuctionSellItemButton()
    ClearCursor()
    PickupContainerItem(tBag, tSlot)
    ClickAuctionSellItemButton()
    ClearCursor()

    local sellName, _, sellCount = GetAuctionSellItemInfo()
    if not sellName or sellCount ~= ps.stackSize then
        ClearCursor()
        ClickAuctionSellItemButton()
        ClearCursor()
        self:AbortPostSession("AH_SELL_PICKUP_FAILED")
        return
    end

    local postOk = pcall(function()
        StartAuction(ps.bidPrice, ps.buyoutPrice, ps.duration)
    end)
    if CursorHasItem() then ClearCursor() end

    if not postOk then
        ClearCursor()
        ClickAuctionSellItemButton()
        ClearCursor()
        self:AbortPostSession("AH_SELL_PICKUP_FAILED")
        return
    end

    ps.step = "WAIT_POST"
    ps.timer = 0
end

function AuctionScreen:UpdatePostSession(dt)
    local ps = self.postSession
    if not ps or not ps.active then return end

    if ps.step == "COOLDOWN" then
        ps.timer = ps.timer - dt
        if ps.timer <= 0 then
            ps.step = "STACKING"
            self:ProcessPostStack()
        end
        return
    end

    if ps.step == "WAIT_STACK" then
        ps.timer = ps.timer + dt
        if ps.timer > 2.5 then
            if CursorHasItem() then ClearCursor() end
            ps.waitData = nil
            ps.step = "STACKING"
            self:ProcessPostStack()
            return
        end

        local wd = ps.waitData
        if wd then
            local _, dCount, dLocked = GetContainerItemInfo(wd.dBag, wd.dSlot)
            local _, _, tLocked = GetContainerItemInfo(wd.tBag, wd.tSlot)
            if not dLocked and not tLocked and dCount == wd.expectedCount then
                ps.waitData = nil
                ps.step = "STACKING"
                self:ProcessPostStack()
            end
        end
        return
    end

    if ps.step == "WAIT_POST" then
        ps.timer = ps.timer + dt
        if ps.timer > 4.0 then
            local sellName = GetAuctionSellItemInfo()
            if not sellName then
                self:OnAuctionPostSuccess()
            else
                ClearCursor()
                ClickAuctionSellItemButton()
                ClearCursor()
                self:AbortPostSession("AH_SELL_TIMEOUT")
            end
        end
        return
    end

    if ps.step == "STACKING" then
        self:ProcessPostStack()
        return
    end
end

function AuctionScreen:OnPostSystemMessage(msg)
    local ps = self.postSession
    if not ps or not ps.active then return end

    if msg == ERR_AUCTION_STARTED then
        self:OnAuctionPostSuccess()
    elseif msg == ERR_NOT_ENOUGH_MONEY or msg == ERR_AUCTION_REPAIR_ITEM or msg == ERR_AUCTION_DATABASE_ERROR then
        ClearCursor()
        ClickAuctionSellItemButton()
        ClearCursor()
        self:AbortPostSession(nil, msg)
    end
end

function AuctionScreen:OnAuctionPostSuccess()
    local ps = self.postSession
    if not ps or not ps.active then return end
    if ps.step ~= "WAIT_POST" then return end

    ps.posted = ps.posted + 1
    if ps.posted < ps.numStacks then
        ps.step = "COOLDOWN"
        ps.timer = 0.15
    else
        self:FinishPostSession(true)
    end
end

function AuctionScreen:OnPostBagUpdate(bag)
    local ps = self.postSession
    if not ps or not ps.active then return end

    if ps.step == "WAIT_STACK" and ps.waitData then
        local wd = ps.waitData
        local _, dCount, dLocked = GetContainerItemInfo(wd.dBag, wd.dSlot)
        local _, _, tLocked = GetContainerItemInfo(wd.tBag, wd.tSlot)
        if not dLocked and not tLocked and dCount == wd.expectedCount then
            ps.waitData = nil
            ps.step = "STACKING"
            self:ProcessPostStack()
        end
    end
end

function AuctionScreen:FinishPostSession(success)
    local ps = self.postSession
    if not ps then return end

    if CursorHasItem() then ClearCursor() end
    ClickAuctionSellItemButton()
    ClearCursor()

    if success and ps.posted > 0 then
        PlaySound("LOOT_COIN")
        local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(ps.itemName, ps.itemLink) or ps.itemName
        local msg
        if ps.posted == 1 then
            msg = string.format(CM:T("AH_SELL_SUCCESS_FMT") or "Auction for %s created successfully!", locName)
        else
            msg = string.format(CM:T("AH_SELL_MULTI_SUCCESS_FMT") or "%d auction(s) for %s created successfully!", ps.posted, locName)
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r " .. msg)
        if UIErrorsFrame then
            UIErrorsFrame:AddMessage(msg, 1.0, 0.85, 0.25, 1.0)
        end
    end

    self.postSession = nil
    self:RefreshSellInventory()

    if self.selectedSellItem and self.selectedSellItem.totalCount and self.selectedSellItem.totalCount > 0 then
        local total = self.selectedSellItem.totalCount
        if (self.sellStackSize or 1) > total then
            self.sellStackSize = math.min(self.selectedSellItem.maxStack or 1, total)
        end
        local maxStacks = math.max(1, math.floor(total / (self.sellStackSize or 1)))
        if (self.sellNumStacks or 1) > maxStacks then
            self.sellNumStacks = maxStacks
        end
        self:UpdateSellListingStyles()
    else
        self:OpenSellInventory()
    end
end

function AuctionScreen:AbortPostSession(reasonKey, customMsg)
    local ps = self.postSession
    if CursorHasItem() then ClearCursor() end
    ClickAuctionSellItemButton()
    ClearCursor()

    self.postSession = nil

    local err = customMsg
    if not err and reasonKey then
        err = CM:T(reasonKey)
    end
    if err and UIErrorsFrame then
        UIErrorsFrame:AddMessage(err, 1.0, 0.2, 0.2, 1.0)
    end

    self:RefreshSellInventory()
    if self.selectedSellItem and self.selectedSellItem.totalCount and self.selectedSellItem.totalCount > 0 then
        self:UpdateSellListingStyles()
    else
        self:OpenSellInventory()
    end
end

function AuctionScreen:OnTriggerAction()
    if not self.isOpen then return end
    if self:IsVKOpen() then return end
    if self.isConfirmModalOpen or self.isSortModalOpen or self:IsQtyModalOpen() or self:IsMoneyModalOpen() then return end

    if self.currentTab == "SELL" and self.sellStep == "LISTING" then
        if not self.isSellPostModalOpen then
            self:OpenSellPostConfirmModal()
        else
            self:ExecutePostAuction()
        end
    end
end

-- ----------------------------------------------------------------------------
-- 15c. ABA MEUS LEILÕES (FASE 8: OWNER AUCTIONS & CANCELAMENTO)
-- ----------------------------------------------------------------------------
function AuctionScreen:CreateOwnerControls(parent)
    local headerFrame = CreateFrame("Frame", nil, parent)
    headerFrame:SetHeight(24)
    headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, 0)
    headerFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, 0)

    local colItem = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colItem:SetPoint("LEFT", headerFrame, "LEFT", 44, 0)
    self:ApplyFont(colItem, FONTS.titleBold, 14)
    colItem:SetText(CM:T("AH_COL_ITEM") or "ITEM")
    colItem:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colStack = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colStack:SetPoint("LEFT", headerFrame, "LEFT", 260, 0)
    colStack:SetWidth(50)
    colStack:SetJustifyH("CENTER")
    self:ApplyFont(colStack, FONTS.titleBold, 14)
    colStack:SetText(CM:T("AH_COL_STACK") or "PILHA")
    colStack:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colTime = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colTime:SetPoint("LEFT", headerFrame, "LEFT", 325, 0)
    colTime:SetWidth(80)
    colTime:SetJustifyH("LEFT")
    self:ApplyFont(colTime, FONTS.titleBold, 14)
    colTime:SetText(CM:T("AH_COL_TIME_LEFT") or "DURAÇÃO")
    colTime:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colBidder = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colBidder:SetPoint("LEFT", headerFrame, "LEFT", 415, 0)
    colBidder:SetWidth(110)
    colBidder:SetJustifyH("LEFT")
    self:ApplyFont(colBidder, FONTS.titleBold, 14)
    colBidder:SetText(CM:T("AH_COL_HIGH_BIDDER") or "MAIOR LANCE")
    colBidder:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colBid = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colBid:SetPoint("RIGHT", headerFrame, "RIGHT", -166, 0)
    colBid:SetWidth(150)
    colBid:SetJustifyH("CENTER")
    self:ApplyFont(colBid, FONTS.titleBold, 14)
    colBid:SetText(CM:T("AH_COL_BID") or "LANCE ATUAL")
    colBid:SetTextColor(0.70, 0.65, 0.55, 1.0)

    local colBuyout = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colBuyout:SetPoint("RIGHT", headerFrame, "RIGHT", -16, 0)
    colBuyout:SetWidth(150)
    colBuyout:SetJustifyH("CENTER")
    self:ApplyFont(colBuyout, FONTS.titleBold, 14)
    colBuyout:SetText(CM:T("AH_COL_BUYOUT") or "COMPRA IMEDIATA")
    colBuyout:SetTextColor(0.70, 0.65, 0.55, 1.0)

    -- Pool de 7 linhas visíveis
    local rows = {}
    local startY = -28
    local rowH = 46
    local rowGap = 6

    for i = 1, 7 do
        local row = CreateFrame("Button", "ConsoleMode_AuctionOwnerRow" .. i, parent)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, startY - ((i - 1) * (rowH + rowGap)))

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 10, edgeSize = 10,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(34)
        icon:SetHeight(34)
        icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.icon = icon

        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        nameText:SetWidth(200)
        nameText:SetJustifyH("LEFT")
        self:ApplyFont(nameText, FONTS.titleBold, 16)
        row.nameText = nameText

        local stackText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        stackText:SetPoint("LEFT", row, "LEFT", 260, 0)
        stackText:SetWidth(50)
        stackText:SetJustifyH("CENTER")
        self:ApplyFont(stackText, FONTS.titleBold, 16)
        stackText:SetTextColor(1.0, 0.90, 0.40, 1.0)
        row.stackText = stackText

        local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        timeText:SetPoint("LEFT", row, "LEFT", 325, 0)
        timeText:SetWidth(80)
        timeText:SetJustifyH("LEFT")
        self:ApplyFont(timeText, FONTS.medium, 14)
        timeText:SetTextColor(0.80, 0.80, 0.80, 0.90)
        row.timeText = timeText

        local bidderText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bidderText:SetPoint("LEFT", row, "LEFT", 415, 0)
        bidderText:SetWidth(110)
        bidderText:SetJustifyH("LEFT")
        self:ApplyFont(bidderText, FONTS.medium, 14)
        bidderText:SetTextColor(0.70, 0.85, 0.70, 1.0)
        row.bidderText = bidderText

        local bidDisplay = self:CreateMoneyDisplay(row, 24, 13, "RIGHT", 150)
        bidDisplay:SetPoint("RIGHT", row, "RIGHT", -166, 0)
        row.bidDisplay = bidDisplay

        local buyoutDisplay = self:CreateMoneyDisplay(row, 24, 13, "RIGHT", 150)
        buyoutDisplay:SetPoint("RIGHT", row, "RIGHT", -16, 0)
        row.buyoutDisplay = buyoutDisplay

        row.rowIdx = i
        row:SetScript("OnClick", function()
            local realIdx = (AuctionScreen.ownerScrollOffset or 0) + this.rowIdx
            AuctionScreen.selectedOwnerIndex = realIdx
            AuctionScreen:UpdateOwnerList()
            AuctionScreen:OpenOwnerCancelModal()
        end)
        row:SetScript("OnEnter", function()
            local realIdx = (AuctionScreen.ownerScrollOffset or 0) + this.rowIdx
            AuctionScreen.selectedOwnerIndex = realIdx
            AuctionScreen:UpdateOwnerList()
        end)

        table.insert(rows, row)
    end
    parent.rows = rows

    local emptyText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    emptyText:SetPoint("CENTER", parent, "CENTER", 0, 10)
    self:ApplyFont(emptyText, FONTS.titleBold, 20)
    emptyText:SetTextColor(0.65, 0.60, 0.50, 1.0)
    emptyText:SetText(CM:T("AH_MY_AUCTIONS_EMPTY") or "Você não possui leilões ativos.")
    emptyText:Hide()
    parent.emptyText = emptyText

    local posIndicator = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    posIndicator:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -16, 8)
    self:ApplyFont(posIndicator, FONTS.medium, 14)
    posIndicator:SetTextColor(0.65, 0.65, 0.65, 1.0)
    parent.posIndicator = posIndicator

    self.ownerRows = rows
end

function AuctionScreen:RefreshOwnerAuctions()
    if GetOwnerAuctionItems then
        pcall(GetOwnerAuctionItems)
    end

    local total = 0
    if GetNumAuctionItems then
        local ok, val = pcall(GetNumAuctionItems, "owner")
        if ok and val then total = tonumber(val) or 0 end
    end

    local items = {}
    for i = 1, total do
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("owner", i)
        local link = GetAuctionItemLink("owner", i)
        local timeLeft = GetAuctionItemTimeLeft("owner", i)
        table.insert(items, {
            index        = i,
            name         = name or "Unknown",
            texture      = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
            count        = count or 1,
            quality      = quality or 0,
            level        = level or 0,
            minBid       = minBid or 0,
            buyoutPrice  = buyoutPrice or 0,
            bidAmount    = bidAmount or 0,
            highBidder   = highBidder,
            owner        = owner,
            link         = link,
            timeLeft     = timeLeft or 1,
        })
    end

    self.ownerAuctions = items
    local numItems = table.getn(items)

    if self.selectedOwnerIndex > numItems then
        self.selectedOwnerIndex = math.max(1, numItems)
    end
    if self.selectedOwnerIndex < 1 and numItems > 0 then
        self.selectedOwnerIndex = 1
    end

    if self.selectedOwnerIndex <= self.ownerScrollOffset then
        self.ownerScrollOffset = math.max(0, self.selectedOwnerIndex - 1)
    elseif self.selectedOwnerIndex > self.ownerScrollOffset + 7 then
        self.ownerScrollOffset = self.selectedOwnerIndex - 7
    end

    self:UpdateOwnerList()
    self:UpdateFooterHints()
end

function AuctionScreen:UpdateOwnerList()
    if not self.ownerRows or not self.ownerContainer then return end

    local items = self.ownerAuctions or {}
    local total = table.getn(items)
    local offset = self.ownerScrollOffset or 0

    if total == 0 then
        self.ownerContainer.emptyText:Show()
        for i = 1, 7 do
            self.ownerRows[i]:Hide()
        end
        if self.ownerContainer.posIndicator then
            self.ownerContainer.posIndicator:SetText("")
        end
        return
    else
        self.ownerContainer.emptyText:Hide()
    end

    for i = 1, 7 do
        local row = self.ownerRows[i]
        local idx = offset + i

        if idx <= total then
            local item = items[idx]
            local isSel = (idx == self.selectedOwnerIndex)

            row.icon:SetTexture(item.texture)

            local qColor = QUALITY_COLORS[item.quality] or { 1, 1, 1 }
            local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
            row.nameText:SetText(locName)
            row.nameText:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

            row.stackText:SetText("x" .. tostring(item.count or 1))

            local timeKey = TIME_LEFT_KEYS[item.timeLeft] or "AH_TIME_SHORT"
            row.timeText:SetText(CM:T(timeKey) or "")

            if item.highBidder and item.highBidder ~= "" then
                row.bidderText:SetText(item.highBidder)
                row.bidderText:SetTextColor(0.40, 1.0, 0.40, 1.0)
            else
                row.bidderText:SetText(CM:T("AH_NO_BIDS") or "Sem Lances")
                row.bidderText:SetTextColor(0.60, 0.60, 0.60, 0.85)
            end

            local bidVal = (item.bidAmount and item.bidAmount > 0) and item.bidAmount or (item.minBid or 0)
            self:SetMoneyDisplay(row.bidDisplay, bidVal)
            self:SetMoneyDisplay(row.buyoutDisplay, item.buyoutPrice)

            if isSel then
                row:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
                row:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
            else
                row:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
                row:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
            end

            row:Show()
        else
            row:Hide()
        end
    end

    if self.ownerContainer.posIndicator then
        if total > 0 then
            self.ownerContainer.posIndicator:SetText(string.format("Leilão %d de %d", self.selectedOwnerIndex, total))
        else
            self.ownerContainer.posIndicator:SetText("")
        end
    end
end

function AuctionScreen:ScrollOwnerList(delta)
    local total = table.getn(self.ownerAuctions or {})
    if total <= 0 then return end

    local newIdx = (self.selectedOwnerIndex or 1) + delta
    if newIdx < 1 then newIdx = 1 end
    if newIdx > total then newIdx = total end

    self.selectedOwnerIndex = newIdx

    if self.selectedOwnerIndex <= self.ownerScrollOffset then
        self.ownerScrollOffset = self.selectedOwnerIndex - 1
    elseif self.selectedOwnerIndex > self.ownerScrollOffset + 7 then
        self.ownerScrollOffset = self.selectedOwnerIndex - 7
    end

    self:UpdateOwnerList()
end

function AuctionScreen:CreateOwnerCancelModal(parent)
    local modalDimmer = CreateFrame("Frame", "ConsoleMode_AuctionOwnerCancelDimmer", parent)
    modalDimmer:SetFrameStrata("DIALOG")
    modalDimmer:SetFrameLevel(45)
    modalDimmer:SetAllPoints(UIParent)
    modalDimmer:EnableMouse(true)
    modalDimmer:Hide()

    local bg = modalDimmer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(modalDimmer)
    bg:SetTexture(0, 0, 0, 0.70)
    modalDimmer.bg = bg

    local modal = CreateFrame("Frame", "ConsoleMode_AuctionOwnerCancelModal", modalDimmer)
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
    title:SetText(CM:T("AH_CANCEL_CONFIRM_TITLE") or "CANCELAR LEILÃO")
    modal.title = title

    local itemIcon = modal:CreateTexture(nil, "ARTWORK")
    itemIcon:SetWidth(40)
    itemIcon:SetHeight(40)
    itemIcon:SetPoint("TOPLEFT", modal, "TOPLEFT", 28, -60)
    modal.itemIcon = itemIcon

    local itemName = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemName:SetPoint("LEFT", itemIcon, "RIGHT", 12, 0)
    itemName:SetPoint("RIGHT", modal, "RIGHT", -28, 0)
    itemName:SetJustifyH("LEFT")
    self:ApplyFont(itemName, FONTS.titleBold, 18)
    modal.itemName = itemName

    local descText = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descText:SetPoint("TOPLEFT", itemIcon, "BOTTOMLEFT", 0, -16)
    descText:SetPoint("RIGHT", modal, "RIGHT", -28, 0)
    descText:SetJustifyH("LEFT")
    self:ApplyFont(descText, FONTS.bodyBold, 15)
    descText:SetTextColor(0.85, 0.85, 0.85, 1.0)
    modal.descText = descText

    local warnText = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warnText:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -12)
    warnText:SetPoint("RIGHT", modal, "RIGHT", -28, 0)
    warnText:SetJustifyH("LEFT")
    self:ApplyFont(warnText, FONTS.medium, 14)
    warnText:SetTextColor(1.0, 0.40, 0.40, 1.0)
    modal.warnText = warnText

    local btnContainer = CreateFrame("Frame", nil, modal)
    btnContainer:SetHeight(40)
    btnContainer:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 24, 20)
    btnContainer:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -24, 20)

    local btnConfirm = CreateFrame("Button", "ConsoleMode_AuctionOwnerCancelConfirmBtn", btnContainer)
    btnConfirm:SetWidth(190)
    btnConfirm:SetHeight(38)
    btnConfirm:SetPoint("LEFT", btnContainer, "LEFT", 10, 0)
    btnConfirm:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    local lConf = btnConfirm:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lConf:SetPoint("CENTER", btnConfirm, "CENTER", 15, 0)
    self:ApplyFont(lConf, FONTS.titleBold, 16)
    lConf:SetText(CM:T("AH_CANCEL_AUCTION_BTN") or "Cancelar Leilão")
    btnConfirm.label = lConf

    local iconA = btnConfirm:CreateTexture(nil, "OVERLAY")
    iconA:SetWidth(28)
    iconA:SetHeight(28)
    iconA:SetPoint("RIGHT", lConf, "LEFT", -6, 0)
    iconA:SetTexture(ICONS.A)
    btnConfirm.icon = iconA

    btnConfirm:SetScript("OnClick", function()
        AuctionScreen:ExecuteCancelAuction()
    end)
    btnConfirm:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    btnConfirm:SetScript("OnLeave", function()
        AuctionScreen:UpdateOwnerCancelModalStyles()
    end)
    modal.btnConfirm = btnConfirm

    local btnCancel = CreateFrame("Button", "ConsoleMode_AuctionOwnerCancelDismissBtn", btnContainer)
    btnCancel:SetWidth(190)
    btnCancel:SetHeight(38)
    btnCancel:SetPoint("RIGHT", btnContainer, "RIGHT", -10, 0)
    btnCancel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    local lCanc = btnCancel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lCanc:SetPoint("CENTER", btnCancel, "CENTER", 15, 0)
    self:ApplyFont(lCanc, FONTS.titleBold, 16)
    lCanc:SetText(CM:T("AH_BTN_CANCEL") or "Voltar")
    btnCancel.label = lCanc

    local iconB = btnCancel:CreateTexture(nil, "OVERLAY")
    iconB:SetWidth(28)
    iconB:SetHeight(28)
    iconB:SetPoint("RIGHT", lCanc, "LEFT", -6, 0)
    iconB:SetTexture(ICONS.B)
    btnCancel.icon = iconB

    btnCancel:SetScript("OnClick", function()
        AuctionScreen:CloseOwnerCancelModal()
    end)
    btnCancel:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    btnCancel:SetScript("OnLeave", function()
        AuctionScreen:UpdateOwnerCancelModalStyles()
    end)
    modal.btnCancel = btnCancel

    self.ownerCancelModalDimmer = modalDimmer
    self.ownerCancelModal = modal
end

function AuctionScreen:OpenOwnerCancelModal()
    local item = self.ownerAuctions and self.ownerAuctions[self.selectedOwnerIndex]
    if not item or not self.ownerCancelModal then return end

    self.targetCancelAuction = item
    self.isOwnerCancelModalOpen = true
    self.ownerCancelBtnIndex = 1

    local modal = self.ownerCancelModal
    local qColor = QUALITY_COLORS[item.quality] or { 0.8, 0.8, 0.8 }
    modal.itemIcon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")

    local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
    modal.itemName:SetText(locName .. " (x" .. tostring(item.count or 1) .. ")")
    modal.itemName:SetTextColor(qColor[1], qColor[2], qColor[3], 1.0)

    local msgFmt = CM:T("AH_CANCEL_CONFIRM_MSG_FMT") or "Tem certeza que deseja cancelar o leilão de %s?"
    modal.descText:SetText(string.format(msgFmt, locName))

    if item.highBidder and item.highBidder ~= "" then
        modal.warnText:SetText(CM:T("AH_CANCEL_HAS_BIDS_WARNING") or "Atenção: Este leilão já possui lances! Ao cancelar, você venderá o item ao maior comprador pelo lance atual.")
    else
        modal.warnText:SetText(CM:T("AH_CANCEL_FORFEIT_DEPOSIT") or "Ao cancelar este leilão, a taxa de depósito não será reembolsada.")
    end

    self:UpdateOwnerCancelModalStyles()
    self.ownerCancelModalDimmer:Show()
    self:UpdateFooterHints()
end

function AuctionScreen:CloseOwnerCancelModal()
    self.isOwnerCancelModalOpen = false
    self.targetCancelAuction = nil
    if self.ownerCancelModalDimmer then
        self.ownerCancelModalDimmer:Hide()
    end
    self:UpdateFooterHints()
end

function AuctionScreen:UpdateOwnerCancelModalStyles()
    if not self.ownerCancelModal then return end
    local modal = self.ownerCancelModal

    if self.ownerCancelBtnIndex == 1 then
        modal.btnConfirm:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
        modal.btnConfirm:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
        modal.btnConfirm.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)

        modal.btnCancel:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
        modal.btnCancel:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
        modal.btnCancel.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
    else
        modal.btnCancel:SetBackdropColor(SEL_BG[1], SEL_BG[2], SEL_BG[3], SEL_BG[4])
        modal.btnCancel:SetBackdropBorderColor(SEL_BORDER[1], SEL_BORDER[2], SEL_BORDER[3], SEL_BORDER[4])
        modal.btnCancel.label:SetTextColor(SEL_TEXT[1], SEL_TEXT[2], SEL_TEXT[3], 1.0)

        modal.btnConfirm:SetBackdropColor(NORMAL_BG[1], NORMAL_BG[2], NORMAL_BG[3], NORMAL_BG[4])
        modal.btnConfirm:SetBackdropBorderColor(NORMAL_BORDER[1], NORMAL_BORDER[2], NORMAL_BORDER[3], NORMAL_BORDER[4])
        modal.btnConfirm.label:SetTextColor(0.80, 0.80, 0.80, 0.90)
    end
end

function AuctionScreen:ExecuteCancelAuction()
    local item = self.targetCancelAuction
    self:CloseOwnerCancelModal()
    if not item or not item.index then return end

    if CancelAuction then
        CancelAuction(item.index)
        local locName = (ConsoleMode and ConsoleMode.GameLOC_Item) and ConsoleMode:GameLOC_Item(item.name, item.link) or item.name
        local msg = CM:T("AH_MSG_AUCTION_CANCELLED") or "Leilão cancelado."
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r " .. msg .. " (" .. locName .. ")")
        end
        if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    end
end

-- ----------------------------------------------------------------------------
-- 16. NAVEGAÇÃO ENTRE ABAS
-- ----------------------------------------------------------------------------
function AuctionScreen:SetTab(tabKey)
    if self.currentTab == tabKey then return end
    self.currentTab = tabKey
    self:UpdateTabStyles()

    self:CloseConfirmModal()
    self:CloseSortModal()
    self:CloseSellPostConfirmModal()
    self:CloseOwnerCancelModal()

    if tabKey == "BUY" then
        if AuctionFrameTab_OnClick then pcall(AuctionFrameTab_OnClick, 1) end
        if self.sellContainer then self.sellContainer:Hide() end
        if self.sellListingContainer then self.sellListingContainer:Hide() end
        if self.ownerContainer then self.ownerContainer:Hide() end
        self:SetBuyStep("CATEGORIES")
    elseif tabKey == "SELL" then
        if AuctionFrameTab_OnClick then pcall(AuctionFrameTab_OnClick, 2) end
        self.gridContainer:Hide()
        self.filterContainer:Hide()
        self.scanContainer:Hide()
        self.summaryContainer:Hide()
        self.itemListContainer:Hide()
        self.itemDetailContainer:Hide()
        if self.ownerContainer then self.ownerContainer:Hide() end
        self:OpenSellInventory()
    else
        -- OWNER (Aba 3 da Blizzard: Auctions / Meus Leilões)
        if AuctionFrameTab_OnClick then pcall(AuctionFrameTab_OnClick, 3) end
        if GetOwnerAuctionItems then
            pcall(GetOwnerAuctionItems)
        end
        self.gridContainer:Hide()
        self.filterContainer:Hide()
        self.scanContainer:Hide()
        self.summaryContainer:Hide()
        self.itemListContainer:Hide()
        self.itemDetailContainer:Hide()
        if self.sellContainer then self.sellContainer:Hide() end
        if self.sellListingContainer then self.sellListingContainer:Hide() end
        if self.ownerContainer then self.ownerContainer:Show() end
        if self.breadcrumb and self.breadcrumb.text then
            self.breadcrumb.text:SetText(CM:T("AH_TAB_MY_AUCTIONS") or "My Auctions")
        end
        self:RefreshOwnerAuctions()
        self:UpdateFooterHints()
    end
end

function AuctionScreen:SwitchTab(delta)
    if self:IsVKOpen() then return end
    if self.isConfirmModalOpen or self.isOwnerCancelModalOpen then return end
    if self.isSortModalOpen then return end
    if self:IsQtyModalOpen() or self:IsMoneyModalOpen() then return end

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
    if self:IsMoneyModalOpen() then
        local mp = CM.MoneyPicker or ConsoleMode_MoneyPicker
        if mp and mp.Direction then
            mp:Direction(direction)
        end
        return
    end
    if self:IsQtyModalOpen() then
        local qp = CM.QuantityPicker or ConsoleMode_QuantityPicker
        if qp and qp.Direction then
            qp:Direction(direction)
        end
        return
    end
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

    if self.currentTab == "SELL" then
        if self.isSellPostModalOpen then
            if direction == "LEFT" or direction == "RIGHT" then
                self.sellPostBtnIndex = (self.sellPostBtnIndex == 1) and 2 or 1
                self:UpdateSellPostModalStyles()
            end
            return
        end

        if self.sellStep == "INVENTORY" then
            local total = table.getn(self.sellBagItems)
            if total <= 0 then return end

            if direction == "UP" then
                if self.selectedSellIndex > 1 then
                    self.selectedSellIndex = self.selectedSellIndex - 1
                    if self.selectedSellIndex <= self.sellScrollOffset then
                        self.sellScrollOffset = self.selectedSellIndex - 1
                    end
                    self.selectedSellItem = self.sellBagItems[self.selectedSellIndex]
                    self:UpdateSellInventory()
                end
            elseif direction == "DOWN" then
                if self.selectedSellIndex < total then
                    self.selectedSellIndex = self.selectedSellIndex + 1
                    if self.selectedSellIndex > self.sellScrollOffset + 7 then
                        self.sellScrollOffset = self.selectedSellIndex - 7
                    end
                    self.selectedSellItem = self.sellBagItems[self.selectedSellIndex]
                    self:UpdateSellInventory()
                end
            end
            return
        elseif self.sellStep == "LISTING" then
            if self.sellListingPane == "COMPETITORS" then
                local numComp = table.getn(self.sellCompetitors or {})
                if numComp <= 0 then return end

                if direction == "UP" then
                    self:ScrollSellCompetitors(-1)
                elseif direction == "DOWN" then
                    self:ScrollSellCompetitors(1)
                elseif direction == "LEFT" or direction == "RIGHT" then
                    -- LEFT/RIGHT no COMPETITORS volta p/ FORM.
                    self.sellListingPane = "FORM"
                    self:UpdateSellListingStyles()
                end
                return
            else
                if direction == "UP" then
                    self.sellFormRow = self.sellFormRow - 1
                    if self.sellFormRow < 1 then self.sellFormRow = 7 end
                    self:UpdateSellListingStyles()
                elseif direction == "DOWN" then
                    self.sellFormRow = self.sellFormRow + 1
                    if self.sellFormRow > 7 then self.sellFormRow = 1 end
                    self:UpdateSellListingStyles()
                elseif direction == "LEFT" or direction == "RIGHT" then
                    -- PO: LEFT/RIGHT no FORM apenas troca de coluna FORM -> COMPETITORS.
                    -- Edicao direta de valores via D-pad removida; AdjustSell* ficam
                    -- orfas p/ os modais.
                    if table.getn(self.sellCompetitors or {}) > 0 then
                        self.sellListingPane = "COMPETITORS"
                        self:UpdateSellListingStyles()
                    end
                end
                return
            end
        end
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

    if self.currentTab == "OWNER" then
        if self.isOwnerCancelModalOpen then
            if direction == "LEFT" or direction == "RIGHT" then
                self.ownerCancelBtnIndex = (self.ownerCancelBtnIndex == 1) and 2 or 1
                self:UpdateOwnerCancelModalStyles()
            end
            return
        end

        if direction == "UP" then
            self:ScrollOwnerList(-1)
        elseif direction == "DOWN" then
            self:ScrollOwnerList(1)
        end
        return
    end
end

function AuctionScreen:OnConfirm()
    if not self.isOpen then return end
    if self:IsVKOpen() then return end
    if self:IsMoneyModalOpen() then
        local mp = CM.MoneyPicker or ConsoleMode_MoneyPicker
        if mp and mp.Confirm then
            mp:Confirm()
        end
        return
    end
    if self:IsQtyModalOpen() then
        local qp = CM.QuantityPicker or ConsoleMode_QuantityPicker
        if qp and qp.Confirm then
            qp:Confirm()
        end
        return
    end

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
    elseif self.currentTab == "SELL" then
        if self.isSellPostModalOpen then
            if self.sellPostBtnIndex == 1 then
                self:ExecutePostAuction()
            else
                self:CloseSellPostConfirmModal()
            end
            return
        end

        if self.sellStep == "INVENTORY" then
            local item = self.sellBagItems[self.selectedSellIndex]
            if item then
                self.selectedSellItem = item
                self:OpenSellListingWithScan(item)
            end
            return
        elseif self.sellStep == "LISTING" then
            if self.sellListingPane == "COMPETITORS" then
                self:MirrorCompetitorPrice(self.selectedCompetitorIndex or 1)
                self.sellListingPane = "FORM"
                self:UpdateSellListingStyles()
                return
            end

            if self.sellFormRow == 1 then
                self:OpenSellMoneyVK("BID")
            elseif self.sellFormRow == 2 then
                self:OpenSellMoneyVK("BUYOUT")
            elseif self.sellFormRow == 3 then
                self.sellDurationIdx = (self.sellDurationIdx or 1) + 1
                if self.sellDurationIdx > 3 then self.sellDurationIdx = 1 end
                self:UpdateSellListingStyles()
            elseif self.sellFormRow == 4 then
                self:OpenSellStackSizePicker()
            elseif self.sellFormRow == 5 then
                self:OpenSellNumStacksPicker()
            elseif self.sellFormRow == 6 then
                self:ApplyMaxStacks()
            elseif self.sellFormRow == 7 then
                self:OpenSellPostConfirmModal()
            end
            return
        end
    elseif self.currentTab == "OWNER" then
        if self.isOwnerCancelModalOpen then
            if self.ownerCancelBtnIndex == 1 then
                self:ExecuteCancelAuction()
            else
                self:CloseOwnerCancelModal()
            end
            return
        end

        local item = self.ownerAuctions and self.ownerAuctions[self.selectedOwnerIndex]
        if item then
            self:OpenOwnerCancelModal()
        end
        return
    end
end

function AuctionScreen:OnSecondaryAction()
    if not self.isOpen then return end
    if self:IsVKOpen() then return end
    if self:IsQtyModalOpen() or self:IsMoneyModalOpen() then return end
    if self.isConfirmModalOpen then return end

    if self.isSortModalOpen then
        self:CloseSortModal()
        return
    end

    if self.currentTab == "BUY" then
        if self.buyStep == "FILTERS" then
            if self.filterRowIndex == 1 then
                self.activeFilters.name = ""
                self:SaveCategoryFilters()
                self:UpdateFilterStyles()
            else
                self:ResetCategoryFilters()
            end
        elseif self.buyStep == "ITEMS_LIST" then
            -- FASE 9: (X) abre o Modal de Ordenação
            self:OpenSortModal()
            return
        end
    elseif self.currentTab == "SELL" then
        if self.sellStep == "INVENTORY" then
            self:RefreshSellInventory()
            return
        end
    elseif self.currentTab == "OWNER" then
        self:RefreshOwnerAuctions()
        return
    end
end

function AuctionScreen:OnContextAction()
    if not self.isOpen then return end
    if self:IsVKOpen() then return end
    if self:IsQtyModalOpen() or self:IsMoneyModalOpen() then return end
    if self.isConfirmModalOpen then return end

    if self.isSortModalOpen then
        self:CloseSortModal()
        return
    end

    if self.currentTab == "BUY" then
        if self.buyStep == "CATEGORIES" then
            local cat = self.gridItems and self.gridItems[self.gridIndex]
            if cat then
                self.selectedCategory = cat
                self.selectedSubcategory = nil
                self.selectedSlot = nil
                self.filterRowIndex = 1
                self:SetBuyStep("FILTERS")
            end
        elseif self.buyStep == "SUBCATEGORIES" then
            local sub = self.gridItems and self.gridItems[self.gridIndex]
            if sub then
                self.selectedSubcategory = sub
                self.selectedSlot = nil
                self.filterRowIndex = 1
                self:SetBuyStep("FILTERS")
            end
        elseif self.buyStep == "FILTERS" then
            self:OpenFilterSearchVK()
        elseif self.buyStep == "ITEMS_LIST" then
            -- FASE 9: (Y) executa nova query no servidor com os filtros ativos (Re-scan)
            self:ExecuteSearch(true)
            return
        elseif self.buyStep == "ITEM_DETAIL" then
            if self.selectedGroupedItem and self.selectedGroupedItem.auctions then
                local auction = self.selectedGroupedItem.auctions[self.selectedAuctionIndex]
                if auction then
                    self:OpenConfirmModal(auction, false)
                end
            end
        end
    elseif self.currentTab == "SELL" then
        if self.sellStep == "INVENTORY" then
            return
        elseif self.sellStep == "LISTING" then
            -- FASE 9: (Y) na esquerda força Re-Scan; (Y) na direita executa MAX!
            if self.sellListingPane == "COMPETITORS" then
                self:RescanSellListing()
                return
            elseif self.sellListingPane == "FORM" then
                self:ApplyMaxStacks()
                return
            end
        end
    end
end

function AuctionScreen:OnCancel()
    if not self.isOpen then return end
    if self:IsVKOpen() then return end
    if self:IsMoneyModalOpen() then
        local mp = CM.MoneyPicker or ConsoleMode_MoneyPicker
        if mp and mp.Cancel then
            mp:Cancel()
        end
        return
    end
    if self:IsQtyModalOpen() then
        local qp = CM.QuantityPicker or ConsoleMode_QuantityPicker
        if qp and qp.Cancel then
            qp:Cancel()
        end
        return
    end

    if self.isConfirmModalOpen then
        self:CloseConfirmModal()
        return
    end

    if self.isSortModalOpen then
        self:CloseSortModal()
        return
    end

    if self.isSellPostModalOpen then
        self:CloseSellPostConfirmModal()
        return
    end

    if self.isOwnerCancelModalOpen then
        self:CloseOwnerCancelModal()
        return
    end

    if self.postSession and self.postSession.active then
        self:AbortPostSession()
        return
    end

    if self.currentTab == "SELL" then
        if self.sellStep == "LISTING" then
            if self.sellListingPane == "COMPETITORS" then
                self.sellListingPane = "FORM"
                self:UpdateSellListingStyles()
                return
            end
            if self:IsMoneyModalOpen() then
                local mp = CM.MoneyPicker or ConsoleMode_MoneyPicker
                if mp and mp.Close then
                    mp:Close(true)
                end
            end
            if self:IsQtyModalOpen() then
                local qp = CM.QuantityPicker or ConsoleMode_QuantityPicker
                if qp and qp.Close then
                    qp:Close(true)
                end
            end
            local cancelScan = CM.auctionScan or ConsoleMode_AuctionScan
            if cancelScan and self.pendingSellScanItem and cancelScan.isScanning then
                pcall(function() cancelScan:AbortQuery() end)
            end
            self.pendingSellScanItem = nil
            self.sellScanActive = nil
            self:OpenSellInventory()
            return
        elseif self.sellStep == "INVENTORY" then
            self:Close()
            return
        end
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

    if self:IsMoneyModalOpen() then
        local mp = CM.MoneyPicker or ConsoleMode_MoneyPicker
        if mp and mp.Close then
            mp:Close(true)
        end
    end

    if self:IsQtyModalOpen() then
        local qp = CM.QuantityPicker or ConsoleMode_QuantityPicker
        if qp and qp.Close then
            qp:Close(true)
        end
    end

    self:CloseConfirmModal()
    self:CloseSortModal()
    self:CloseSellPostConfirmModal()
    self:CloseOwnerCancelModal()

    if self.postSession and self.postSession.active then
        self:AbortPostSession()
    end

    if CursorHasItem() then
        ClearCursor()
    end

    local scan = CM.auctionScan or ConsoleMode_AuctionScan
    if scan and scan.isScanning then
        scan:AbortQuery()
    end
    self.pendingSellScanItem = nil
    self.sellScanActive = nil
    self:SetSellScanVisible(false)

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

function AuctionScreen:OpenBlizzardAH()
    local scan = CM.auctionScan or ConsoleMode_AuctionScan
    if scan and scan.isScanning then
        pcall(function() scan:AbortQuery() end)
    end
    self.pendingSellScanItem = nil
    self.sellScanActive = nil

    if self.postSession and self.postSession.active then
        self:AbortPostSession()
    end

    self.isOpen = false
    if self.frame then
        self.frame:Hide()
    end
    if self.dimmer then
        self.dimmer:Hide()
    end

    if CM.keybindings and CM.keybindings.ExitNavigationMode then
        CM.keybindings:ExitNavigationMode()
    end

    if AuctionFrame then
        AuctionFrame:ClearAllPoints()
        AuctionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        AuctionFrame:SetAlpha(1)
        AuctionFrame:Show()
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
    ef:RegisterEvent("BAG_UPDATE")
    ef:RegisterEvent("CHAT_MSG_SYSTEM")
    ef:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")

    ef:SetScript("OnEvent", function()
        if event == "AUCTION_HOUSE_SHOW" then
            AuctionScreen:Open()
        elseif event == "AUCTION_HOUSE_CLOSED" then
            AuctionScreen:Close(true)
        elseif event == "BAG_UPDATE" then
            if AuctionScreen.postSession and AuctionScreen.postSession.active then
                AuctionScreen:OnPostBagUpdate(arg1)
            elseif AuctionScreen.isOpen and AuctionScreen.currentTab == "SELL" and AuctionScreen.sellStep == "INVENTORY" then
                AuctionScreen:RefreshSellInventory()
            end
        elseif event == "AUCTION_OWNED_LIST_UPDATE" then
            if AuctionScreen.isOpen and AuctionScreen.currentTab == "OWNER" then
                AuctionScreen:RefreshOwnerAuctions()
            end
        elseif event == "CHAT_MSG_SYSTEM" then
            AuctionScreen:OnPostSystemMessage(arg1)
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
        if AuctionScreen.postSession and AuctionScreen.postSession.active then
            AuctionScreen:UpdatePostSession(arg1)
        end
    end)

    self.eventFrame = ef
end

-- ----------------------------------------------------------------------------
-- 21. LEFT/RIGHT (D-PAD) ALTERNAM PAINEL FORM ⇄ COMPETITORS NO LISTING
-- RT (R2) segue postando via OnTriggerAction (post global no LISTING, nao
-- so na linha 7). LT (L2) nao alterna painel: volta ao comportamento padrao
-- anterior (cursor:CycleSubTabs). ToggleSellListingPane e usada apenas
-- pelo D-pad LEFT/RIGHT.
-- ----------------------------------------------------------------------------
function AuctionScreen:ToggleSellListingPane()
    if not self.isOpen then return false end
    if self:IsVKOpen() then return false end
    if CM.keybindings and CM.keybindings.chatActive then return false end
    if self.isConfirmModalOpen or self.isSortModalOpen then return false end
    if self.isSellPostModalOpen then return false end
    if self.currentTab ~= "SELL" or self.sellStep ~= "LISTING" then return false end
    if table.getn(self.sellCompetitors or {}) <= 0 then return true end
    if self.sellListingPane == "FORM" then
        self.sellListingPane = "COMPETITORS"
    else
        self.sellListingPane = "FORM"
    end
    self:UpdateSellListingStyles()
    return true
end

AuctionScreen:InitEvents()
