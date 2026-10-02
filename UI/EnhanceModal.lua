-- ============================================================================
-- ConsoleModeVanilla - UI/EnhanceModal.lua
-- Modal de Aprimoramento de Equipamentos para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_EnhanceModal = ConsoleMode_EnhanceModal or {}
local EnhanceModal = ConsoleMode_EnhanceModal
CM.enhanceModal = EnhanceModal

-- ----------------------------------------------------------------------------
-- 1. CONSTANTES E DESIGN SYSTEM (Consistência estrita com UI/MailScreen.lua)
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
    DUP    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DUP.tga",
    DDOWN  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DDOWN.tga",
}

local QUALITY_COLORS = {
    [0] = { r = 0.62, g = 0.62, b = 0.62, hex = "|cff9d9d9d" }, -- Pobre
    [1] = { r = 1.00, g = 1.00, b = 1.00, hex = "|cffffffff" }, -- Comum
    [2] = { r = 0.12, g = 1.00, b = 0.00, hex = "|cff1eff00" }, -- Incomum
    [3] = { r = 0.00, g = 0.44, b = 0.87, hex = "|cff0070dd" }, -- Raro
    [4] = { r = 0.64, g = 0.21, b = 0.93, hex = "|cffa335ee" }, -- Épico
    [5] = { r = 1.00, g = 0.50, b = 0.00, hex = "|cffff8000" }, -- Lendário
}

local NINESLICE = {
    texture    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Carved_9Slides.tga",
    cornerSize = 48,
    drawLayer  = "BACKGROUND",
    uv = {
        col = {
            { 0.0000, 0.2500 },
            { 0.2500, 0.5000 },
            { 0.5000, 0.7500 },
        },
        row = {
            { 0.0000, 0.2500 },
            { 0.2500, 0.5000 },
            { 0.5000, 0.7500 },
        }
    }
}

-- ----------------------------------------------------------------------------
-- 2. TABELA DE IDs E REGRAS DE CLASSIFICAÇÃO (Vanilla 1.12.1 + Turtle WoW)
-- ----------------------------------------------------------------------------
local KNOWN_ENHANCE_ITEMS = {
    -- Pedras de Afiar (Sharpening Stones) -> WEAPON_SHARP
    [2862]  = "WEAPON_SHARP", -- Rough Sharpening Stone
    [2863]  = "WEAPON_SHARP", -- Coarse Sharpening Stone
    [2871]  = "WEAPON_SHARP", -- Heavy Sharpening Stone
    [7964]  = "WEAPON_SHARP", -- Solid Sharpening Stone
    [12404] = "WEAPON_SHARP", -- Dense Sharpening Stone
    [18262] = "WEAPON_SHARP", -- Elemental Sharpening Stone
    [23122] = "WEAPON_SHARP", -- Consecrated Sharpening Stone

    -- Pedras de Peso (Weightstones) -> WEAPON_BLUNT
    [3239]  = "WEAPON_BLUNT", -- Rough Weightstone
    [3240]  = "WEAPON_BLUNT", -- Coarse Weightstone
    [3241]  = "WEAPON_BLUNT", -- Heavy Weightstone
    [7965]  = "WEAPON_BLUNT", -- Solid Weightstone
    [12643] = "WEAPON_BLUNT", -- Dense Weightstone
    [23123] = "WEAPON_BLUNT", -- Consecrated Weightstone

    -- Óleos de Mago e Mana (Wizard/Mana Oils) -> WEAPON_OIL
    [20749] = "WEAPON_OIL",   -- Minor Wizard Oil
    [20744] = "WEAPON_OIL",   -- Lesser Wizard Oil
    [20746] = "WEAPON_OIL",   -- Wizard Oil
    [20748] = "WEAPON_OIL",   -- Brilliant Wizard Oil
    [23123] = "WEAPON_OIL",   -- Blessed Wizard Oil
    [20745] = "WEAPON_OIL",   -- Minor Mana Oil
    [20747] = "WEAPON_OIL",   -- Lesser Mana Oil
    [20748] = "WEAPON_OIL",   -- Brilliant Mana Oil
    [3824]  = "WEAPON_OIL",   -- Shadow Oil
    [3829]  = "WEAPON_OIL",   -- Frost Oil

    -- Venenos de Ladino (Rogue Poisons) -> WEAPON_POISON
    [6947]  = "WEAPON_POISON", -- Instant Poison
    [6949]  = "WEAPON_POISON", -- Instant Poison II
    [6950]  = "WEAPON_POISON", -- Instant Poison III
    [8926]  = "WEAPON_POISON", -- Instant Poison IV
    [8927]  = "WEAPON_POISON", -- Instant Poison V
    [8928]  = "WEAPON_POISON", -- Instant Poison VI
    [2892]  = "WEAPON_POISON", -- Deadly Poison
    [2893]  = "WEAPON_POISON", -- Deadly Poison II
    [8984]  = "WEAPON_POISON", -- Deadly Poison III
    [8985]  = "WEAPON_POISON", -- Deadly Poison IV
    [20844] = "WEAPON_POISON", -- Deadly Poison V
    [3775]  = "WEAPON_POISON", -- Crippling Poison
    [3776]  = "WEAPON_POISON", -- Crippling Poison II
    [5237]  = "WEAPON_POISON", -- Mind-numbing Poison
    [6951]  = "WEAPON_POISON", -- Mind-numbing Poison II
    [9186]  = "WEAPON_POISON", -- Mind-numbing Poison III
    [10918] = "WEAPON_POISON", -- Wound Poison
    [10920] = "WEAPON_POISON", -- Wound Poison II
    [10921] = "WEAPON_POISON", -- Wound Poison III
    [10922] = "WEAPON_POISON", -- Wound Poison IV

    -- Kits de Armadura (Armor Kits) -> ARMOR_KIT
    [2304]  = "ARMOR_KIT",    -- Light Armor Kit
    [2313]  = "ARMOR_KIT",    -- Medium Armor Kit
    [4265]  = "ARMOR_KIT",    -- Heavy Armor Kit
    [8173]  = "ARMOR_KIT",    -- Thick Armor Kit
    [15564] = "ARMOR_KIT",    -- Rugged Armor Kit
    [18251] = "ARMOR_KIT",    -- Core Armor Kit

    -- Miras de Engenharia (Scopes) -> SCOPE
    [4405]  = "SCOPE",        -- Crude Scope
    [4406]  = "SCOPE",        -- Standard Scope
    [4407]  = "SCOPE",        -- Accurate Scope
    [10546] = "SCOPE",        -- Deadly Scope
    [10548] = "SCOPE",        -- Sniper Scope
    [18283] = "SCOPE",        -- Biznicks 247x128 Accurascope

    -- Espigões de Escudo (Shield Spikes) -> SHIELD_SPIKE
    [7967]  = "SHIELD_SPIKE", -- Iron Shield Spike
    [7969]  = "SHIELD_SPIKE", -- Mithril Shield Spike
    [12645] = "SHIELD_SPIKE", -- Thorium Shield Spike
}

-- Configuração de alvos equipados por categoria
local CATEGORY_CONFIG = {
    WEAPON_SHARP = {
        labelKey    = "ENHANCE_CAT_SHARP",
        label       = "Armas Cortantes",
        targetSlots = { 16, 17 }, -- Mão Principal, Mão Secundária
        slotKeys    = { [16] = "ENHANCE_SLOT_MAINHAND", [17] = "ENHANCE_SLOT_OFFHAND" },
        slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
    },
    WEAPON_BLUNT = {
        labelKey    = "ENHANCE_CAT_BLUNT",
        label       = "Armas de Impacto",
        targetSlots = { 16, 17 },
        slotKeys    = { [16] = "ENHANCE_SLOT_MAINHAND", [17] = "ENHANCE_SLOT_OFFHAND" },
        slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
    },
    WEAPON_OIL = {
        labelKey    = "ENHANCE_CAT_OIL",
        label       = "Armas",
        targetSlots = { 16, 17 },
        slotKeys    = { [16] = "ENHANCE_SLOT_MAINHAND", [17] = "ENHANCE_SLOT_OFFHAND" },
        slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
    },
    WEAPON_POISON = {
        labelKey    = "ENHANCE_CAT_POISON",
        label       = "Armas",
        targetSlots = { 16, 17 },
        slotKeys    = { [16] = "ENHANCE_SLOT_MAINHAND", [17] = "ENHANCE_SLOT_OFFHAND" },
        slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
    },
    ARMOR_KIT = {
        labelKey    = "ENHANCE_CAT_ARMOR",
        label       = "Armaduras",
        targetSlots = { 5, 7, 10, 8 }, -- Peito, Pernas, Mãos, Pés
        slotKeys    = { [5] = "ENHANCE_SLOT_CHEST", [7] = "ENHANCE_SLOT_LEGS", [10] = "ENHANCE_SLOT_HANDS", [8] = "ENHANCE_SLOT_FEET" },
        slotNames   = { [5] = "Peitoral", [7] = "Pernas", [10] = "Luvas", [8] = "Botas" },
        validEquipTypes = { "INVTYPE_CHEST", "INVTYPE_ROBE", "INVTYPE_LEGS", "INVTYPE_HANDS", "INVTYPE_FEET" },
    },
    SCOPE = {
        labelKey    = "ENHANCE_CAT_SCOPE",
        label       = "Arma de Longo Alcance",
        targetSlots = { 18 }, -- Ranged
        slotKeys    = { [18] = "ENHANCE_SLOT_RANGED" },
        slotNames   = { [18] = "Longo Alcance" },
        validEquipTypes = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT" },
    },
    SHIELD_SPIKE = {
        labelKey    = "ENHANCE_CAT_SHIELD",
        label       = "Escudo",
        targetSlots = { 17 }, -- OffHand
        slotKeys    = { [17] = "ENHANCE_SLOT_OFFHAND" },
        slotNames   = { [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_SHIELD" },
    },
}

function EnhanceModal:GetCategoryLabel(category)
    local cfg = CATEGORY_CONFIG[category]
    if cfg and cfg.labelKey and CM.T then
        return CM:T(cfg.labelKey)
    end
    return (cfg and cfg.label) or category or ""
end

function EnhanceModal:GetSlotName(category, slotID)
    local cfg = CATEGORY_CONFIG[category]
    if cfg and cfg.slotKeys and cfg.slotKeys[slotID] and CM.T then
        return CM:T(cfg.slotKeys[slotID])
    end
    if cfg and cfg.slotNames and cfg.slotNames[slotID] then
        return cfg.slotNames[slotID]
    end
    return ""
end

-- ----------------------------------------------------------------------------
-- 3. TOOLTIP SCANNER PARA CLASSIFICAÇÃO HEURÍSTICA (Fallback Universal)
-- ----------------------------------------------------------------------------
local scanTip = CreateFrame("GameTooltip", "ConsoleModeEnhanceScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- ----------------------------------------------------------------------------
-- 4. ESTADO DA SESSÃO ATIVA
-- ----------------------------------------------------------------------------
EnhanceModal.isOpen        = false
EnhanceModal.activeContext = nil
EnhanceModal.currentTab    = "EQUIP" -- "EQUIP" ou "BAGS"
EnhanceModal.frame         = nil
EnhanceModal.dimmer        = nil
EnhanceModal.equippedItems = {}
EnhanceModal.selectedIndex = 1
EnhanceModal.equipRows     = {}
EnhanceModal.repeatState   = {
    direction    = nil,
    timer        = 0,
    initialDelay = 0.35,
    interval     = 0.12,
}
EnhanceModal.repeatTicker  = nil

-- ----------------------------------------------------------------------------
-- 5. HELPERS DE UI E 9-SLICE (Padrão idêntico ao MailScreen.lua)
-- ----------------------------------------------------------------------------
function EnhanceModal:ApplyFont(fontString, fontPath, size, outline, shadowOffset, shadowColor)
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

function EnhanceModal:Create9Slice(parent, texturePath, cornerSize, uvMap, drawLayer)
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

    -- Cantos
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

    -- Bordas Horizontais
    slices.top = makeSlice("Top", c[2][1], c[2][2], r[1][1], r[1][2])
    slices.top:SetHeight(cornerSize)
    slices.top:SetPoint("TOPLEFT", slices.topLeft, "TOPRIGHT", 0, 0)
    slices.top:SetPoint("TOPRIGHT", slices.topRight, "TOPLEFT", 0, 0)

    slices.bottom = makeSlice("Bottom", c[2][1], c[2][2], r[3][1], r[3][2])
    slices.bottom:SetHeight(cornerSize)
    slices.bottom:SetPoint("BOTTOMLEFT", slices.bottomLeft, "BOTTOMRIGHT", 0, 0)
    slices.bottom:SetPoint("BOTTOMRIGHT", slices.bottomRight, "BOTTOMLEFT", 0, 0)

    -- Bordas Verticais
    slices.left = makeSlice("Left", c[1][1], c[1][2], r[2][1], r[2][2])
    slices.left:SetWidth(cornerSize)
    slices.left:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMLEFT", 0, 0)
    slices.left:SetPoint("BOTTOMLEFT", slices.bottomLeft, "TOPLEFT", 0, 0)

    slices.right = makeSlice("Right", c[3][1], c[3][2], r[2][1], r[2][2])
    slices.right:SetWidth(cornerSize)
    slices.right:SetPoint("TOPRIGHT", slices.topRight, "BOTTOMRIGHT", 0, 0)
    slices.right:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPRIGHT", 0, 0)

    -- Centro
    slices.center = makeSlice("Center", c[2][1], c[2][2], r[2][1], r[2][2])
    slices.center:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMRIGHT", 0, 0)
    slices.center:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPLEFT", 0, 0)

    return slices
end

function EnhanceModal:CreateDimmer()
    if self.dimmer then return end

    local dimmer = CreateFrame("Frame", "ConsoleMode_EnhanceDimmer", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:SetFrameLevel(25)
    dimmer:EnableMouse(true)
    dimmer:Hide()

    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints(dimmer)
    dimTex:SetTexture(0.0, 0.0, 0.0, 0.65)
    dimmer.texture = dimTex

    dimmer:SetScript("OnMouseDown", function()
        EnhanceModal:Close()
    end)

    self.dimmer = dimmer
end

function EnhanceModal:BuildIconHints(parent, frameName, hints, bottomOffset)
    bottomOffset = tonumber(bottomOffset) or 20
    local container = CreateFrame("Frame", frameName, parent)
    container:SetHeight(32)
    container:SetPoint("CENTER", parent, "BOTTOM", 0, bottomOffset)

    local totalWidth = 0
    local widgets = {}

    local numHints = table.getn(hints)
    for i = 1, numHints do
        local hint = hints[i]
        local groupFrame = CreateFrame("Frame", nil, container)
        groupFrame:SetHeight(32)

        local currentX = 0
        local numIcons = table.getn(hint.icons)
        for k = 1, numIcons do
            local iconKey = hint.icons[k]
            local texPath = ICONS[iconKey]
            if texPath then
                local iconTex = groupFrame:CreateTexture(nil, "OVERLAY")
                local curW = 28
                local curH = 28
                iconTex:SetWidth(curW)
                iconTex:SetHeight(curH)
                iconTex:SetTexture(texPath)
                iconTex:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
                currentX = currentX + curW + 2
            end
        end

        currentX = currentX + 4

        local label = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
        self:ApplyFont(label, FONTS.bodyBold, 15)
        label:SetText(hint.label)
        label:SetTextColor(0.85, 0.85, 0.85, 0.95)

        local textW = math.floor(label:GetStringWidth() or 40)
        currentX = currentX + textW

        if i < numHints then
            local sep = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            sep:SetPoint("LEFT", groupFrame, "LEFT", currentX + 4, 0)
            self:ApplyFont(sep, FONTS.medium, 13)
            sep:SetText("|cff666666•|r")
            currentX = currentX + 4 + 12
        end

        groupFrame:SetWidth(currentX)
        table.insert(widgets, groupFrame)
        totalWidth = totalWidth + currentX
    end

    local startX = -math.floor(totalWidth / 2)
    local curX = startX
    local numWidgets = table.getn(widgets)
    for w = 1, numWidgets do
        local widget = widgets[w]
        widget:SetPoint("LEFT", container, "CENTER", curX, 0)
        curX = curX + widget:GetWidth()
    end
    container:SetWidth(totalWidth)
    return container
end

-- ----------------------------------------------------------------------------
-- 6. MOTOR DE CLASSIFICAÇÃO (Fase 1: Core Interceptor)
-- ----------------------------------------------------------------------------
function EnhanceModal:ClassifyItem(bagID, slotID, itemLink, givenName)
    local rawLink = itemLink or (bagID and slotID and GetContainerItemLink(bagID, slotID))
    if not rawLink then return nil end

    local _, _, itemIDStr = string.find(rawLink, "item:(%d+)")
    local itemID = tonumber(itemIDStr)

    local category = nil

    -- 1. Verificação por ID Conhecido
    if itemID and KNOWN_ENHANCE_ITEMS[itemID] then
        category = KNOWN_ENHANCE_ITEMS[itemID]
    end

    -- 2. Fallback Heurístico por Nome e Tooltip
    if not category then
        local itemName = GetItemInfo(rawLink)
        if not itemName and bagID and slotID then
            scanTip:ClearLines()
            scanTip:SetBagItem(bagID, slotID)
            local line1 = getglobal("ConsoleModeEnhanceScanTipTextLeft1")
            if line1 and line1:GetText() then
                itemName = line1:GetText()
            end
        end

        if itemName then
            local lowerName = string.lower(itemName)
            if string.find(lowerName, "sharpening stone") or string.find(lowerName, "pedra de afiar") then
                category = "WEAPON_SHARP"
            elseif string.find(lowerName, "weightstone") or string.find(lowerName, "pedra de peso") then
                category = "WEAPON_BLUNT"
            elseif string.find(lowerName, "wizard oil") or string.find(lowerName, "mana oil") or
                   string.find(lowerName, "óleo de mago") or string.find(lowerName, "óleo de mana") or
                   string.find(lowerName, "oleo de mago") or string.find(lowerName, "oleo de mana") or
                   string.find(lowerName, "shadow oil") or string.find(lowerName, "frost oil") then
                category = "WEAPON_OIL"
            elseif string.find(lowerName, "poison") or string.find(lowerName, "veneno") then
                category = "WEAPON_POISON"
            elseif string.find(lowerName, "armor kit") or string.find(lowerName, "kit de armadura") then
                category = "ARMOR_KIT"
            elseif string.find(lowerName, "scope") or string.find(lowerName, "mira") then
                category = "SCOPE"
            elseif string.find(lowerName, "shield spike") or string.find(lowerName, "espigão de escudo") or string.find(lowerName, "espigao de escudo") then
                category = "SHIELD_SPIKE"
            end
        end

        -- Se ainda não classificou, inspeciona o Use/Uso no tooltip
        if not category and bagID and slotID then
            scanTip:ClearLines()
            scanTip:SetBagItem(bagID, slotID)
            local numLines = scanTip:NumLines()
            for l = 1, numLines do
                local lineObj = getglobal("ConsoleModeEnhanceScanTipTextLeft" .. l)
                if lineObj and lineObj:GetText() then
                    local lineText = string.lower(lineObj:GetText())
                    if string.find(lineText, "use:") or string.find(lineText, "uso:") then
                        if string.find(lineText, "afia uma arma") or string.find(lineText, "sharpen.*weapon") or string.find(lineText, "arma cortante") then
                            category = "WEAPON_SHARP"
                            break
                        elseif string.find(lineText, "peso para armas") or string.find(lineText, "blunt weapon") or string.find(lineText, "arma de contus") then
                            category = "WEAPON_BLUNT"
                            break
                        elseif string.find(lineText, "aplica.*veneno") or string.find(lineText, "coat.*poison") then
                            category = "WEAPON_POISON"
                            break
                        elseif string.find(lineText, "reforça.*armadura") or string.find(lineText, "reinforce.*armor") then
                            category = "ARMOR_KIT"
                            break
                        end
                    end
                end
            end
        end
    end

    if not category then return nil end

    local cfg = CATEGORY_CONFIG[category] or {}
    local name, _, quality, _, _, _, _, _, texture = GetItemInfo(rawLink)
    if not name or name == "" then
        name = givenName
    end
    if not name and bagID and slotID then
        scanTip:ClearLines()
        scanTip:SetBagItem(bagID, slotID)
        local line1 = getglobal("ConsoleModeEnhanceScanTipTextLeft1")
        if line1 and line1:GetText() then
            name = line1:GetText()
        end
    end
    if not texture and bagID and slotID then
        texture = GetContainerItemInfo(bagID, slotID)
    end

    local rawName = name
    local localizedName = name
    if CM and CM.GameLOC_Item then
        local tr = CM:GameLOC_Item(rawName, itemID or rawLink)
        if tr and tr ~= "" then
            localizedName = tr
        end
    end

    local defaultTitle = (CM.T and CM:T("ENHANCE_MODAL_TITLE")) or "Aprimoramento"
    return {
        category        = category,
        rawName         = rawName,
        categoryKey     = cfg.labelKey,
        categoryLabel   = cfg.label or category,
        targetSlots     = cfg.targetSlots or { 16, 17 },
        slotKeys        = cfg.slotKeys or {},
        slotNames       = cfg.slotNames or {},
        validEquipTypes = cfg.validEquipTypes or {},
        itemID          = itemID,
        itemLink        = rawLink,
        itemName        = localizedName or rawName or defaultTitle,
        itemQuality     = quality or 1,
        itemTexture     = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        bagID           = bagID,
        slotID          = slotID,
    }
end

-- ----------------------------------------------------------------------------
-- 6b. VARREDURA DE ITENS EQUIPADOS E COMPATIBILIDADE (Fase 3)
-- ----------------------------------------------------------------------------
function EnhanceModal:ScanItemEnhancement(slotID, bagID, itemSlotID)
    if not scanTip then return nil end

    scanTip:ClearLines()
    if slotID then
        scanTip:SetInventoryItem("player", slotID)
    elseif bagID and itemSlotID then
        scanTip:SetBagItem(bagID, itemSlotID)
    else
        return nil
    end

    local numLines = scanTip:NumLines() or 0
    if numLines <= 1 then
        -- Fallback nativo para armas equipadas se a tooltip estiver vazia
        if slotID and (slotID == 16 or slotID == 17) and GetWeaponEnchantInfo then
            local hasMH, mhExp, _, hasOH, ohExp, _ = GetWeaponEnchantInfo()
            if (slotID == 16 and hasMH) or (slotID == 17 and hasOH) then
                if MainMenu and MainMenu.GetWeaponEnchantDetails then
                    local wName = MainMenu:GetWeaponEnchantDetails(slotID)
                    if wName and wName ~= "" then
                        local exp = (slotID == 16 and mhExp) or ohExp or 0
                        local mins = math.floor(exp / 60000)
                        if mins > 0 then
                            return wName .. " (" .. mins .. " min)"
                        else
                            return wName
                        end
                    end
                end
            end
        end
        return nil
    end

    local tempEnhance = nil
    local permEnchant = nil

    for l = 2, numLines do
        local leftObj = getglobal("ConsoleModeEnhanceScanTipTextLeft" .. l)
        if leftObj then
            local text = leftObj:GetText()
            if text and text ~= "" then
                local r, g, b = leftObj:GetTextColor()
                local isGreen = (g and g > 0.70 and r and r < 0.35 and b and b < 0.35)
                local hasDuration = string.find(text, "%(%d+%s*min%)")
                    or string.find(text, "%(%d+%s*sec%)")
                    or string.find(text, "%(%d+%s*seg%)")
                    or string.find(text, "%(%d+%s*hr%)")
                    or string.find(text, "%(%d+%s*cargas?%)")
                    or string.find(text, "%(%d+%s*charges?%)")

                if isGreen or hasDuration then
                    local lower = string.lower(text)
                    local isIgnored = string.find(lower, "^equip")
                        or string.find(lower, "^equipar")
                        or string.find(lower, "^chance")
                        or string.find(lower, "^use")
                        or string.find(lower, "^usar")
                        or string.find(lower, "^set")
                        or string.find(lower, "^conjunto")
                        or string.find(lower, "feitiço:")
                        or string.find(lower, "spell:")
                        or string.find(lower, "^classes")
                        or string.find(lower, "^requer")
                        or string.find(lower, "^requires")
                        or string.find(lower, "^durab")
                        or string.find(lower, "^<")

                    if not isIgnored then
                        -- Se tem formato ou palavra-chave de aprimoramento temporário
                        if hasDuration or string.find(lower, "afiado") or string.find(lower, "sharpened")
                            or string.find(lower, "peso") or string.find(lower, "weightstone")
                            or string.find(lower, "óleo") or string.find(lower, "oil")
                            or string.find(lower, "veneno") or string.find(lower, "poison") then
                            if not tempEnhance then
                                tempEnhance = text
                            end
                        else
                            if not permEnchant then
                                permEnchant = text
                            end
                        end
                    end
                end
            end
        end
    end

    -- Se não encontrou temporário nas linhas, mas GetWeaponEnchantInfo confirma para armas
    if not tempEnhance and slotID and (slotID == 16 or slotID == 17) and GetWeaponEnchantInfo then
        local hasMH, mhExp, _, hasOH, ohExp, _ = GetWeaponEnchantInfo()
        if (slotID == 16 and hasMH) or (slotID == 17 and hasOH) then
            if MainMenu and MainMenu.GetWeaponEnchantDetails then
                local wName = MainMenu:GetWeaponEnchantDetails(slotID)
                if wName and wName ~= "" then
                    local exp = (slotID == 16 and mhExp) or ohExp or 0
                    local mins = math.floor(exp / 60000)
                    if mins > 0 then
                        tempEnhance = wName .. " (" .. mins .. " min)"
                    else
                        tempEnhance = wName
                    end
                end
            end
        end
    end

    if tempEnhance and permEnchant and tempEnhance ~= permEnchant then
        if string.len(tempEnhance .. " • " .. permEnchant) <= 38 then
            return tempEnhance .. " • " .. permEnchant
        else
            return tempEnhance
        end
    end

    return tempEnhance or permEnchant
end

function EnhanceModal:GetEquippedSlotInfo(slotID)
    local link = GetInventoryItemLink("player", slotID)
    local texture = GetInventoryItemTexture("player", slotID)
    if not link and not texture then
        return nil
    end

    local rawLink = nil
    local nameFromLink = nil
    local colorHex = nil
    local itemID = nil

    if link then
        local _, _, cHex, rLink, nLink = string.find(link, "|c(%x+)|H(item:[^|]+)|h%[(.-)%]|h|r")
        if rLink then
            rawLink = rLink
            nameFromLink = nLink
            colorHex = cHex
        else
            local _, _, idStr = string.find(link, "item:(%d+)")
            if idStr then
                itemID = tonumber(idStr)
                rawLink = "item:" .. idStr .. ":0:0:0"
            end
        end
        if not itemID and rawLink then
            local _, _, idStr = string.find(rawLink, "item:(%d+)")
            if idStr then
                itemID = tonumber(idStr)
            end
        end
    end

    local name, itemQuality, itemType, subType, equipLoc
    local queryTarget = rawLink or itemID or nameFromLink or link
    if queryTarget then
        local itemName, _, rarity, _, iType, sType, _, eqLoc = GetItemInfo(queryTarget)
        name = itemName or nameFromLink
        itemQuality = rarity
        itemType = iType
        subType = sType
        equipLoc = eqLoc
    end

    -- Fallback via Tooltip Scanner
    if (not name or not subType or subType == "") and slotID then
        scanTip:ClearLines()
        scanTip:SetInventoryItem("player", slotID)
        local line1 = getglobal("ConsoleModeEnhanceScanTipTextLeft1")
        if line1 and line1:GetText() and (not name or name == "") then
            name = line1:GetText()
        end
        -- Inspeciona linhas 2 a 4 para subtipo e equipLoc se faltar
        local numLines = scanTip:NumLines() or 0
        local maxL = numLines
        if maxL > 5 then maxL = 5 end
        for l = 2, maxL do
            local rObj = getglobal("ConsoleModeEnhanceScanTipTextRight" .. l)
            local lObj = getglobal("ConsoleModeEnhanceScanTipTextLeft" .. l)
            if rObj and rObj:GetText() and (not subType or subType == "") then
                local rt = rObj:GetText()
                if rt ~= "" and not string.find(rt, "%d") then
                    subType = rt
                end
            end
            if lObj and lObj:GetText() and (not equipLoc or equipLoc == "") then
                local lt = lObj:GetText()
                if string.find(lt, "Shield") or string.find(lt, "Escudo") then
                    equipLoc = "INVTYPE_SHIELD"
                end
            end
        end
    end

    -- Se itemQuality ainda for nil, tenta inferir pela cor hexadecimal do link
    if not itemQuality and colorHex then
        if colorHex == "ff9d9d9d" then itemQuality = 0
        elseif colorHex == "ffffffff" then itemQuality = 1
        elseif colorHex == "ff1eff00" then itemQuality = 2
        elseif colorHex == "ff0070dd" then itemQuality = 3
        elseif colorHex == "ffa335ee" then itemQuality = 4
        elseif colorHex == "ffff8000" then itemQuality = 5
        end
    end

    local localizedName = name
    if CM and CM.GameLOC_Item and (name or itemID or rawLink) then
        local tr = CM:GameLOC_Item(name, itemID or rawLink)
        if tr and tr ~= "" then
            localizedName = tr
        end
    end

    local enchantText = self:ScanItemEnhancement(slotID)

    return {
        slotID        = slotID,
        link          = link or rawLink,
        rawLink       = rawLink,
        itemID        = itemID,
        texture       = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        rawName       = name,
        name          = localizedName or name or "Item",
        quality       = itemQuality or 1,
        itemType      = itemType or "",
        subType       = subType or "",
        equipLoc      = equipLoc or "",
        enchantText   = enchantText,
    }
end

function EnhanceModal:IsItemCompatible(itemInfo, category)
    if not itemInfo or not category then return false end
    local cfg = CATEGORY_CONFIG[category]
    if not cfg then return false end

    local slot = itemInfo.slotID
    local st = string.lower(itemInfo.subType or "")
    local nm = string.lower(itemInfo.rawName or "")
    local eq = itemInfo.equipLoc or ""

    -- 1. KITS DE ARMADURA: qualquer peça equipada nos slots 5 (Peito), 7 (Pernas), 10 (Mãos), 8 (Pés)
    if category == "ARMOR_KIT" then
        if slot == 5 or slot == 7 or slot == 10 or slot == 8 then
            return true
        end
        if eq == "INVTYPE_CHEST" or eq == "INVTYPE_ROBE" or eq == "INVTYPE_LEGS" or eq == "INVTYPE_HANDS" or eq == "INVTYPE_FEET" then
            return true
        end
        return false
    end

    -- 2. MIRA DE ENGENHARIA: slot 18 (Ranged), exceto varinhas e relíquias
    if category == "SCOPE" then
        if slot == 18 then
            if string.find(st, "wand") or string.find(st, "varinha") or string.find(nm, "wand") or string.find(nm, "varinha") then
                return false
            end
            if string.find(st, "thrown") or string.find(st, "arremesso") or string.find(st, "relic") or string.find(st, "relíquia") then
                return false
            end
            return true
        end
        return false
    end

    -- 3. ESPIGÃO DE ESCUDO: slot 17 se for escudo
    if category == "SHIELD_SPIKE" then
        if slot == 17 then
            if eq == "INVTYPE_SHIELD" or string.find(st, "shield") or string.find(st, "escudo") or string.find(nm, "shield") or string.find(nm, "escudo") then
                return true
            end
        end
        return false
    end

    -- Armas Melee (Slots 16 e 17)
    if slot ~= 16 and slot ~= 17 then
        return false
    end

    -- Se for escudo ou item de mão secundária segurável (livro/frasco), não é arma melee
    if eq == "INVTYPE_SHIELD" or eq == "INVTYPE_HOLDABLE" then
        return false
    end
    if string.find(st, "shield") or string.find(st, "escudo") or string.find(nm, "shield") or string.find(nm, "escudo") then
        return false
    end

    -- 4. WEAPON_SHARP: armas cortantes (espadas, machados, adagas, armas de haste)
    if category == "WEAPON_SHARP" then
        if string.find(st, "mace") or string.find(st, "maça") or string.find(st, "maca") or
           string.find(st, "staff") or string.find(st, "stave") or string.find(st, "cajado") or
           string.find(st, "wand") or string.find(st, "varinha") or string.find(st, "bow") or
           string.find(st, "gun") or string.find(st, "crossbow") or string.find(st, "fist") or
           string.find(st, "punho") or
           string.find(nm, "mace") or string.find(nm, "maça") or string.find(nm, "mallet") or
           string.find(nm, "hammer") or string.find(nm, "martelo") or string.find(nm, "staff") or
           string.find(nm, "cajado") then
            return false
        end
        return true
    end

    -- 5. WEAPON_BLUNT: armas de impacto (maças, cajados)
    if category == "WEAPON_BLUNT" then
        if string.find(st, "sword") or string.find(st, "espada") or
           string.find(st, "axe") or string.find(st, "machado") or
           string.find(st, "dagger") or string.find(st, "adaga") or
           string.find(st, "polearm") or string.find(st, "haste") or
           string.find(st, "wand") or string.find(st, "varinha") or
           string.find(st, "bow") or string.find(st, "gun") or string.find(st, "crossbow") or
           string.find(nm, "sword") or string.find(nm, "espada") or
           string.find(nm, "axe") or string.find(nm, "machado") or
           string.find(nm, "dagger") or string.find(nm, "adaga") or
           string.find(nm, "blade") or string.find(nm, "lâmina") or string.find(nm, "lamina") then
            return false
        end
        return true
    end

    -- 6. WEAPON_OIL e WEAPON_POISON: qualquer arma corpo a corpo em 16 ou 17
    if category == "WEAPON_OIL" or category == "WEAPON_POISON" then
        return true
    end

    return true
end

function EnhanceModal:ScanEquippedItems()
    local results = {}
    if not self.activeContext then return results end

    local category = self.activeContext.category
    local cfg = CATEGORY_CONFIG[category]
    if not cfg or not cfg.targetSlots then return results end

    local numSlots = table.getn(cfg.targetSlots)
    for i = 1, numSlots do
        local slotID = cfg.targetSlots[i]
        local itemInfo = self:GetEquippedSlotInfo(slotID)
        if itemInfo and self:IsItemCompatible(itemInfo, category) then
            itemInfo.slotName = self:GetSlotName(category, slotID)
            table.insert(results, itemInfo)
        end
    end

    return results
end

-- ----------------------------------------------------------------------------
-- 7. CONSTRUÇÃO DA INTERFACE (Fase 2: View Shell & Ciclo de Vida)
-- ----------------------------------------------------------------------------
function EnhanceModal:CreateTabIndicator(parent)
    local bar = CreateFrame("Frame", "ConsoleMode_EnhanceTabIndicator", parent)
    bar:SetHeight(24)
    bar:SetWidth(360)
    bar:SetPoint("TOP", parent, "TOP", 0, -82)

    local function BuildTabGroup(text)
        local g = CreateFrame("Frame", nil, bar)
        g:SetHeight(24)
        g:SetWidth(360)
        g:SetPoint("CENTER", bar, "CENTER", 0, 0)

        local label = g:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("CENTER", g, "CENTER", 0, 0)
        EnhanceModal:ApplyFont(label, FONTS.titleBold, 17)
        label:SetText("|cffffffff" .. text .. "|r")
        g.label = label

        local lb = g:CreateTexture(nil, "OVERLAY")
        lb:SetWidth(24)
        lb:SetHeight(24)
        lb:SetPoint("RIGHT", label, "LEFT", -6, 0)
        lb:SetTexture(ICONS.LB)

        local rb = g:CreateTexture(nil, "OVERLAY")
        rb:SetWidth(24)
        rb:SetHeight(24)
        rb:SetPoint("LEFT", label, "RIGHT", 6, 0)
        rb:SetTexture(ICONS.RB)

        return g
    end

    local tabEquipText = (CM.T and CM:T("ENHANCE_TAB_EQUIP")) or "EQUIPADOS"
    local tabBagsText  = (CM.T and CM:T("ENHANCE_TAB_BAGS")) or "NA MOCHILA"
    bar.groupEquip = BuildTabGroup(tabEquipText)
    bar.groupBags  = BuildTabGroup(tabBagsText)
    bar.groupBags:Hide()

    self.tabIndicator = bar
    return bar
end

function EnhanceModal:UpdateTabIndicator()
    local bar = self.tabIndicator
    if not bar then return end

    if bar.groupEquip and bar.groupEquip.label then
        local tabEquipText = (CM.T and CM:T("ENHANCE_TAB_EQUIP")) or "EQUIPADOS"
        bar.groupEquip.label:SetText("|cffffffff" .. tabEquipText .. "|r")
    end
    if bar.groupBags and bar.groupBags.label then
        local tabBagsText = (CM.T and CM:T("ENHANCE_TAB_BAGS")) or "NA MOCHILA"
        bar.groupBags.label:SetText("|cffffffff" .. tabBagsText .. "|r")
    end

    if self.currentTab == "BAGS" then
        if bar.groupEquip then bar.groupEquip:Hide() end
        if bar.groupBags then bar.groupBags:Show() end
    else
        if bar.groupBags then bar.groupBags:Hide() end
        if bar.groupEquip then bar.groupEquip:Show() end
    end
end

function EnhanceModal:CreateUI()
    if self.frame then return end

    -- Dimmer de fundo
    self:CreateDimmer()

    -- Frame Principal (500x485)
    local frame = CreateFrame("Frame", "ConsoleMode_EnhanceModalFrame", UIParent)
    frame:SetWidth(500)
    frame:SetHeight(485)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(30)
    frame:EnableMouse(true)
    frame:Hide()

    -- 9-Slice esculpido idêntico ao MailScreen
    self.slices = self:Create9Slice(
        frame,
        NINESLICE.texture,
        NINESLICE.cornerSize,
        NINESLICE.uv,
        NINESLICE.drawLayer
    )

    table.insert(UISpecialFrames, "ConsoleMode_EnhanceModalFrame")

    frame:SetScript("OnHide", function()
        if EnhanceModal.isOpen then
            EnhanceModal:Close()
        end
    end)

    -- Botão Sair no cabeçalho
    local closeBtn = CreateFrame("Button", "ConsoleMode_EnhanceCloseBtn", frame)
    closeBtn:SetWidth(84)
    closeBtn:SetHeight(26)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -18)
    closeBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    closeBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    closeBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local closeIcon = closeBtn:CreateTexture(nil, "OVERLAY")
    closeIcon:SetWidth(22)
    closeIcon:SetHeight(22)
    closeIcon:SetPoint("LEFT", closeBtn, "LEFT", 5, 0)
    closeIcon:SetTexture(ICONS.B)

    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeTxt:SetPoint("LEFT", closeIcon, "RIGHT", 4, 0)
    self:ApplyFont(closeTxt, FONTS.titleBold, 14)
    closeTxt:SetText((CM.T and CM:T("ENHANCE_CLOSE")) or "Sair")
    closeTxt:SetTextColor(0.90, 0.85, 0.75, 1.0)
    closeBtn.text = closeTxt
    frame.closeBtn = closeBtn

    closeBtn:SetScript("OnClick", function()
        EnhanceModal:Close()
    end)

    -- Cabeçalho do Item Sendo Aplicado
    local itemHeader = CreateFrame("Frame", nil, frame)
    itemHeader:SetHeight(44)
    itemHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -20)
    itemHeader:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -10, 0)

    -- Ícone do item com borda
    local iconFrame = CreateFrame("Frame", nil, itemHeader)
    iconFrame:SetWidth(36)
    iconFrame:SetHeight(36)
    iconFrame:SetPoint("LEFT", itemHeader, "LEFT", 0, 0)
    iconFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    iconFrame:SetBackdropBorderColor(0.70, 0.60, 0.45, 0.90)

    local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 3, -3)
    iconTex:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -3, 3)
    iconTex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    itemHeader.iconTex = iconTex

    -- Nome e Subtítulo
    local titleText = itemHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -2)
    self:ApplyFont(titleText, FONTS.titleBold, 17)
    titleText:SetText((CM.T and CM:T("ENHANCE_MODAL_TITLE")) or "APRIMORAMENTO")
    itemHeader.titleText = titleText

    local subText = itemHeader:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
    self:ApplyFont(subText, FONTS.medium, 13)
    subText:SetText((CM.T and CM:T("ENHANCE_MODAL_SUBTITLE")) or "Selecione onde deseja aplicar")
    subText:SetTextColor(0.70, 0.70, 0.70, 0.90)
    itemHeader.subText = subText

    frame.itemHeader = itemHeader

    -- Indicador de Abas Centralizado: [LB] EQUIPADOS [RB]
    self:CreateTabIndicator(frame)

    -- Divisor sutil
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -112)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -112)
    divider:SetTexture(0.35, 0.28, 0.20, 0.60)
    frame.divider = divider

    -- Área de Conteúdo Central (Onde entrarão as listas nas Fases 3 e 5)
    local content = CreateFrame("Frame", "ConsoleMode_EnhanceContent", frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -120)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 54)
    content:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    content:SetBackdropColor(0.04, 0.04, 0.04, 0.65)
    content:SetBackdropBorderColor(0.40, 0.32, 0.22, 0.70)
    frame.content = content

    -- Placeholder temporário da Fase 2
    local placeholder = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placeholder:SetPoint("CENTER", content, "CENTER", 0, 0)
    self:ApplyFont(placeholder, FONTS.bodyBold, 15)
    placeholder:SetTextColor(0.75, 0.75, 0.75, 0.90)
    placeholder:SetText((CM.T and CM:T("ENHANCE_EMPTY_EQUIP")) or "Aba Equipados ativa\n(Aguardando Fase 3 para listar itens equipados)")
    content.placeholder = placeholder

    -- Linhas de equipamentos equipados (Fase 3)
    self:CreateEquipRows(content)

    -- Footer com prompts em texturas oficiais
    self:UpdateFooter()

    self.frame = frame
end

-- ----------------------------------------------------------------------------
-- 7b. LINHAS DE EQUIPAMENTO E NAVEGAÇÃO ESPACIAL (Fase 3)
-- ----------------------------------------------------------------------------
function EnhanceModal:CreateEquipRows(parent)
    if self.equipRows and table.getn(self.equipRows) > 0 then return end
    self.equipRows = {}

    local rowH = 68
    local rowGap = 6

    for i = 1, 4 do
        local row = CreateFrame("Button", "ConsoleMode_EnhanceRow" .. i, parent)
        row:SetHeight(rowH)
        if i == 1 then
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
            row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4)
        else
            row:SetPoint("TOPLEFT", self.equipRows[i - 1], "BOTTOMLEFT", 0, -rowGap)
            row:SetPoint("TOPRIGHT", self.equipRows[i - 1], "BOTTOMRIGHT", 0, -rowGap)
        end

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        row:SetBackdropColor(0.08, 0.07, 0.05, 0.60)
        row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)

        -- Highlight de seleção
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.35)
        hl:SetAllPoints(row)
        hl:Hide()
        row.highlight = hl

        -- Bullet dourado de foco
        local cur = row:CreateTexture(nil, "OVERLAY")
        cur:SetWidth(12)
        cur:SetHeight(12)
        cur:SetPoint("LEFT", row, "LEFT", 4, 0)
        cur:SetTexture("Interface\\QuestFrame\\UI-Quest-BulletPoint")
        cur:SetVertexColor(1.0, 0.85, 0.20)
        cur:Hide()
        row.cursor = cur

        -- Ícone do item (42x42)
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(42)
        icon:SetHeight(42)
        icon:SetPoint("LEFT", row, "LEFT", 14, 0)
        row.icon = icon

        -- Borda do ícone com cor de qualidade
        local iconBorder = CreateFrame("Frame", nil, row)
        iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        iconBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        row.iconBorder = iconBorder

        -- Prompt lateral de ação: [A] Aplicar
        local prompt = CreateFrame("Frame", nil, row)
        prompt:SetHeight(24)
        prompt:SetWidth(80)
        prompt:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        prompt:Hide()

        local pIcon = prompt:CreateTexture(nil, "OVERLAY")
        pIcon:SetWidth(20)
        pIcon:SetHeight(20)
        pIcon:SetPoint("LEFT", prompt, "LEFT", 0, 0)
        pIcon:SetTexture(ICONS.A)
        prompt.icon = pIcon

        local pTxt = prompt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pTxt:SetPoint("LEFT", pIcon, "RIGHT", 4, 0)
        self:ApplyFont(pTxt, FONTS.titleBold, 13)
        pTxt:SetText((CM.T and CM:T("ENHANCE_HINT_APPLY")) or "Aplicar")
        pTxt:SetTextColor(0.90, 0.85, 0.70, 1.0)
        prompt.text = pTxt

        row.applyPrompt = prompt

        -- Linha 1: Slot e SubTipo
        local slotText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        slotText:SetPoint("TOPLEFT", row, "TOPLEFT", 68, -8)
        slotText:SetPoint("RIGHT", prompt, "LEFT", -6, 0)
        slotText:SetJustifyH("LEFT")
        self:ApplyFont(slotText, FONTS.titleBold, 12)
        row.slotText = slotText

        -- Linha 2: Nome do item colorido
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 68, -25)
        nameText:SetPoint("RIGHT", prompt, "LEFT", -6, 0)
        nameText:SetJustifyH("LEFT")
        self:ApplyFont(nameText, FONTS.titleBold, 15)
        row.nameText = nameText

        -- Linha 3: Status de Aprimoramento / Encantamento ativo
        local enchantText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        enchantText:SetPoint("TOPLEFT", row, "TOPLEFT", 68, -45)
        enchantText:SetPoint("RIGHT", prompt, "LEFT", -6, 0)
        enchantText:SetJustifyH("LEFT")
        self:ApplyFont(enchantText, FONTS.bodyBold, 12)
        row.enchantText = enchantText

        -- Suporte a mouse/híbrido
        local rowIdx = i
        row:SetScript("OnEnter", function()
            EnhanceModal:SetSelectedIndex(rowIdx)
        end)
        row:SetScript("OnClick", function()
            EnhanceModal:SetSelectedIndex(rowIdx)
            EnhanceModal:OnConfirm()
        end)

        row:Hide()
        table.insert(self.equipRows, row)
    end
end

function EnhanceModal:RenderEquippedTab()
    if not self.frame or not self.frame.content then return end
    local content = self.frame.content

    local count = table.getn(self.equippedItems or {})
    if count == 0 then
        if content.placeholder then
            content.placeholder:SetText((CM.T and CM:T("ENHANCE_NO_EQUIP_FOUND")) or "Nenhum equipamento compatível equipado.\nPressione [RB] para verificar itens na mochila.")
            content.placeholder:Show()
        end
        for i = 1, 4 do
            if self.equipRows and self.equipRows[i] then self.equipRows[i]:Hide() end
        end
        self.selectedIndex = 0
        return
    end

    if content.placeholder then
        content.placeholder:Hide()
    end

    for i = 1, 4 do
        local row = self.equipRows and self.equipRows[i]
        local itemInfo = self.equippedItems[i]
        if row and itemInfo then
            row.itemInfo = itemInfo
            row.icon:SetTexture(itemInfo.texture)

            local qCol = QUALITY_COLORS[itemInfo.quality or 1] or QUALITY_COLORS[1]
            row.iconBorder:SetBackdropBorderColor(qCol.r, qCol.g, qCol.b, 0.90)

            local locSubType = itemInfo.subType
            if CM and CM.GameLOC_ItemSubType and locSubType and locSubType ~= "" then
                locSubType = CM:GameLOC_ItemSubType(locSubType)
            end
            local subTypePart = ""
            if locSubType and locSubType ~= "" then
                subTypePart = "  |cff888888(" .. locSubType .. ")|r"
            end

            row.slotText:SetText("|cffffd100" .. string.upper(itemInfo.slotName or "") .. "|r" .. subTypePart)
            row.nameText:SetText((qCol.hex or "|cffffffff") .. (itemInfo.name or "Item") .. "|r")

            if row.enchantText then
                if itemInfo.enchantText and itemInfo.enchantText ~= "" then
                    row.enchantText:SetText("|cff00ff00" .. itemInfo.enchantText .. "|r")
                else
                    local noEnc = (CM.T and CM:T("ENHANCE_NO_CURRENT_ENCHANT")) or "Nenhum aprimoramento ativo"
                    row.enchantText:SetText("|cff666666" .. noEnc .. "|r")
                end
            end

            if row.applyPrompt and row.applyPrompt.text then
                row.applyPrompt.text:SetText((CM.T and CM:T("ENHANCE_HINT_APPLY")) or "Aplicar")
            end

            row:Show()
        elseif row then
            row:Hide()
        end
    end
end

function EnhanceModal:SetSelectedIndex(index)
    local count = table.getn(self.equippedItems or {})
    if count == 0 then
        self.selectedIndex = 0
        return
    end

    if index < 1 then index = 1 end
    if index > count then index = count end
    self.selectedIndex = index

    for i = 1, 4 do
        local row = self.equipRows and self.equipRows[i]
        if row and row:IsShown() then
            if i == index then
                row:SetBackdropColor(0.22, 0.17, 0.10, 0.90)
                row:SetBackdropBorderColor(0.90, 0.75, 0.28, 0.95)
                if row.highlight then row.highlight:Show() end
                if row.cursor then row.cursor:Show() end
                if row.applyPrompt then row.applyPrompt:Show() end
            else
                row:SetBackdropColor(0.08, 0.07, 0.05, 0.60)
                row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
                if row.highlight then row.highlight:Hide() end
                if row.cursor then row.cursor:Hide() end
                if row.applyPrompt then row.applyPrompt:Hide() end
            end
        end
    end
end

function EnhanceModal:GetSelectedTarget()
    if self.currentTab == "EQUIP" then
        if self.equippedItems and self.selectedIndex and self.selectedIndex > 0 then
            return self.equippedItems[self.selectedIndex]
        end
    end
    return nil
end

function EnhanceModal:OnDirection(direction)
    if not self.isOpen then return end
    if self.currentTab == "EQUIP" then
        local count = table.getn(self.equippedItems or {})
        if count <= 1 then return end

        local newIndex = self.selectedIndex or 1
        if direction == "UP" then
            newIndex = newIndex - 1
            if newIndex < 1 then newIndex = count end
        elseif direction == "DOWN" then
            newIndex = newIndex + 1
            if newIndex > count then newIndex = 1 end
        end

        if newIndex ~= self.selectedIndex then
            self:SetSelectedIndex(newIndex)
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
    end
end

function EnhanceModal:EnsureRepeatTicker()
    if self.repeatTicker then return end
    local ticker = CreateFrame("Frame", "ConsoleMode_EnhanceRepeatTicker", UIParent)
    ticker:SetScript("OnUpdate", function()
        EnhanceModal:OnRepeatUpdate(arg1)
    end)
    self.repeatTicker = ticker
end

function EnhanceModal:OnRepeatUpdate(dt)
    if not self.isOpen or not self.repeatState or not self.repeatState.direction then
        return
    end

    dt = dt or 0
    self.repeatState.timer = self.repeatState.timer - dt
    if self.repeatState.timer <= 0 then
        self.repeatState.timer = self.repeatState.interval
        self:OnDirection(self.repeatState.direction)
    end
end

function EnhanceModal:StartRepeat(direction)
    if not self.isOpen then return end
    if direction == "UP" or direction == "DOWN" then
        self:OnDirection(direction)
        self.repeatState.direction = direction
        self.repeatState.timer = self.repeatState.initialDelay
        self:EnsureRepeatTicker()
    else
        self.repeatState.direction = nil
    end
end

function EnhanceModal:StopRepeat(direction)
    if not self.repeatState then return end
    if not direction or self.repeatState.direction == direction then
        self.repeatState.direction = nil
    end
end

function EnhanceModal:OnConfirm()
    if not self.isOpen then return end
    local target = self:GetSelectedTarget()
    if not target then return end

    if self.currentTab == "EQUIP" then
        if target.slotID then
            -- Se por algum motivo o cursor não estiver no modo de mira da magia,
            -- reaciona o consumível da bolsa para engajar SpellIsTargeting
            if SpellIsTargeting and not SpellIsTargeting() then
                if self.activeContext and self.activeContext.bagID and self.activeContext.slotID then
                    UseContainerItem(self.activeContext.bagID, self.activeContext.slotID)
                end
            end

            -- Aplica a magia de aprimoramento no slot equipado
            if SpellIsTargeting and SpellIsTargeting() then
                PickupInventoryItem(target.slotID)
            end
            PlaySound("igMainMenuOptionCheckBoxOn")
            self:Close(true)
        end
    end
end

function EnhanceModal:UpdateFooter()
    if not self.frame then return end
    if self.frame.footer then
        self.frame.footer:Hide()
        self.frame.footer = nil
    end

    local footerHints = {
        { icons = { "A" },        label = (CM.T and CM:T("ENHANCE_HINT_APPLY")) or "Aplicar" },
        { icons = { "B" },        label = (CM.T and CM:T("ENHANCE_HINT_CANCEL")) or "Cancelar" },
        { icons = { "LB", "RB" }, label = (CM.T and CM:T("ENHANCE_HINT_CYCLE_TABS")) or "Alternar Aba" },
    }
    self.frame.footer = self:BuildIconHints(self.frame, "ConsoleMode_EnhanceFooter", footerHints, 18)
end

function EnhanceModal:UpdateContentPlaceholder()
    if not self.frame or not self.frame.content or not self.frame.content.placeholder then return end
    if self.currentTab == "BAGS" then
        for i = 1, 4 do
            if self.equipRows and self.equipRows[i] then self.equipRows[i]:Hide() end
        end
        self.frame.content.placeholder:SetText((CM.T and CM:T("ENHANCE_EMPTY_BAGS")) or "Aba Na Mochila ativa\n(Aguardando Fase 5 para listar itens da bolsa)")
        self.frame.content.placeholder:Show()
    else
        self:RenderEquippedTab()
        self:SetSelectedIndex(self.selectedIndex or 1)
    end
end

-- ----------------------------------------------------------------------------
-- 8. CICLO DE VIDA (Open / Close / SetTab / ToggleTab)
-- ----------------------------------------------------------------------------
function EnhanceModal:Open(itemData, enhanceInfo)
    self:CreateUI()
    if not self.frame then return end

    self.activeContext = enhanceInfo or self.activeContext
    self.isOpen = true
    self.currentTab = "EQUIP"

    -- Atualiza cabeçalho com informações do consumível
    if self.activeContext and self.frame.itemHeader then
        local displayName = self.activeContext.itemName
        if CM and CM.GameLOC_Item then
            local tr = CM:GameLOC_Item(self.activeContext.rawName or self.activeContext.itemName, self.activeContext.itemID or self.activeContext.itemLink)
            if tr and tr ~= "" then
                displayName = tr
            end
        end

        local qCol = QUALITY_COLORS[self.activeContext.itemQuality or 1] or QUALITY_COLORS[1]
        local title = displayName or (CM.T and CM:T("ENHANCE_MODAL_TITLE")) or "APRIMORAMENTO"
        self.frame.itemHeader.titleText:SetText((qCol.hex or "|cffffffff") .. title .. "|r")

        local catLabel = self:GetCategoryLabel(self.activeContext.category)
        local targetPrefix = (CM.T and CM:T("ENHANCE_TARGET_PREFIX")) or "Alvo: "
        self.frame.itemHeader.subText:SetText(targetPrefix .. catLabel)

        if self.activeContext.itemTexture then
            self.frame.itemHeader.iconTex:SetTexture(self.activeContext.itemTexture)
        end
    end

    if self.frame.closeBtn and self.frame.closeBtn.text then
        self.frame.closeBtn.text:SetText((CM.T and CM:T("ENHANCE_CLOSE")) or "Sair")
    end

    self.equippedItems = self:ScanEquippedItems()
    self:UpdateTabIndicator()
    self:UpdateContentPlaceholder()
    self:SetSelectedIndex(1)
    self:UpdateFooter()

    if self.dimmer then self.dimmer:Show() end
    self.frame:Show()

    PlaySound("igMainMenuOpen")
end

function EnhanceModal:Close(isConfirmed)
    if not self.isOpen and not (self.frame and self.frame:IsVisible()) then return end

    self.isOpen = false
    if self.repeatState then
        self.repeatState.direction = nil
    end

    -- Cancela o modo de mira da engine do WoW se o usuário cancelou/saiu sem confirmar
    if not isConfirmed and SpellIsTargeting and SpellIsTargeting() then
        SpellStopTargeting()
    end

    if self.frame then self.frame:Hide() end
    if self.dimmer then self.dimmer:Hide() end

    self.activeContext = nil
    PlaySound("igMainMenuClose")
end

function EnhanceModal:SetTab(tabKey)
    if tabKey ~= "EQUIP" and tabKey ~= "BAGS" then return end
    if self.currentTab == tabKey then return end

    self.currentTab = tabKey
    self:UpdateTabIndicator()
    self:UpdateContentPlaceholder()
    PlaySound("igCharacterInfoTab")
end

function EnhanceModal:CycleTabs(dir)
    dir = dir or 1
    if dir > 0 then
        if self.currentTab == "EQUIP" then
            self:SetTab("BAGS")
        else
            self:SetTab("EQUIP")
        end
    else
        if self.currentTab == "BAGS" then
            self:SetTab("EQUIP")
        else
            self:SetTab("BAGS")
        end
    end
end

function EnhanceModal:ToggleTab()
    self:CycleTabs(1)
end

-- ----------------------------------------------------------------------------
-- 9. HOOK / INTERCEPTADOR DE USO (Chamado ao usar o consumível nas bolsas)
-- ----------------------------------------------------------------------------
function EnhanceModal:OnItemUsed(itemData, enhanceInfo)
    if not enhanceInfo then return end

    self:Open(itemData, enhanceInfo)
end

-- ----------------------------------------------------------------------------
-- 10. MONITORAMENTO DE EVENTOS DE JOGO (Resiliência & Segurança)
-- ----------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame", "ConsoleMode_EnhanceEventFrame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

eventFrame:SetScript("OnEvent", function()
    if not EnhanceModal.isOpen then return end

    if event == "PLAYER_REGEN_DISABLED" then
        EnhanceModal:Close()
    end
end)

-- Hook defensivo: o diálogo nativo REPLACE_ENCHANT da Blizzard não tem OnCancel padrão,
-- deixando o cursor preso em modo de mira (glow) se o jogador clicar em 'Não'.
if StaticPopupDialogs and StaticPopupDialogs["REPLACE_ENCHANT"] then
    local origCancel = StaticPopupDialogs["REPLACE_ENCHANT"].OnCancel
    StaticPopupDialogs["REPLACE_ENCHANT"].OnCancel = function()
        if origCancel then origCancel() end
        if SpellIsTargeting and SpellIsTargeting() then
            SpellStopTargeting()
        end
    end
end
if StaticPopupDialogs and StaticPopupDialogs["REPLACE_TRADESKILL_ENCHANT"] then
    local origCancel = StaticPopupDialogs["REPLACE_TRADESKILL_ENCHANT"].OnCancel
    StaticPopupDialogs["REPLACE_TRADESKILL_ENCHANT"].OnCancel = function()
        if origCancel then origCancel() end
        if SpellIsTargeting and SpellIsTargeting() then
            SpellStopTargeting()
        end
    end
end
