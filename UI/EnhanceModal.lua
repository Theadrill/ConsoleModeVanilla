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
        label       = "Armas Cortantes",
        targetSlots = { 16, 17 }, -- Mão Principal, Mão Secundária
        slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
    },
    WEAPON_BLUNT = {
        label       = "Armas de Impacto",
        targetSlots = { 16, 17 },
        slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
    },
    WEAPON_OIL = {
        label       = "Armas",
        targetSlots = { 16, 17 },
        slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
    },
    WEAPON_POISON = {
        label       = "Armas",
        targetSlots = { 16, 17 },
        slotNames   = { [16] = "Mão Principal", [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
    },
    ARMOR_KIT = {
        label       = "Armaduras",
        targetSlots = { 5, 7, 10, 8 }, -- Peito, Pernas, Mãos, Pés
        slotNames   = { [5] = "Peitoral", [7] = "Pernas", [10] = "Luvas", [8] = "Botas" },
        validEquipTypes = { "INVTYPE_CHEST", "INVTYPE_ROBE", "INVTYPE_LEGS", "INVTYPE_HANDS", "INVTYPE_FEET" },
    },
    SCOPE = {
        label       = "Arma de Longo Alcance",
        targetSlots = { 18 }, -- Ranged
        slotNames   = { [18] = "Longo Alcance" },
        validEquipTypes = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT" },
    },
    SHIELD_SPIKE = {
        label       = "Escudo",
        targetSlots = { 17 }, -- OffHand
        slotNames   = { [17] = "Mão Secundária" },
        validEquipTypes = { "INVTYPE_SHIELD" },
    },
}

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
function EnhanceModal:ClassifyItem(bagID, slotID, itemLink)
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
    if not texture and bagID and slotID then
        texture = GetContainerItemInfo(bagID, slotID)
    end

    return {
        category        = category,
        categoryLabel   = cfg.label or category,
        targetSlots     = cfg.targetSlots or { 16, 17 },
        slotNames       = cfg.slotNames or {},
        validEquipTypes = cfg.validEquipTypes or {},
        itemID          = itemID,
        itemLink        = rawLink,
        itemName        = name or "Item de Aprimoramento",
        itemQuality     = quality or 1,
        itemTexture     = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        bagID           = bagID,
        slotID          = slotID,
    }
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

    bar.groupEquip = BuildTabGroup("EQUIPADOS")
    bar.groupBags  = BuildTabGroup("NA MOCHILA")
    bar.groupBags:Hide()

    self.tabIndicator = bar
    return bar
end

function EnhanceModal:UpdateTabIndicator()
    local bar = self.tabIndicator
    if not bar then return end
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

    -- Frame Principal (500x380)
    local frame = CreateFrame("Frame", "ConsoleMode_EnhanceModalFrame", UIParent)
    frame:SetWidth(500)
    frame:SetHeight(380)
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
    closeTxt:SetText("Sair")
    closeTxt:SetTextColor(0.90, 0.85, 0.75, 1.0)

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
    titleText:SetText("Aprimoramento")
    itemHeader.titleText = titleText

    local subText = itemHeader:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
    self:ApplyFont(subText, FONTS.medium, 13)
    subText:SetText("Selecione onde deseja aplicar")
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
    placeholder:SetText("Aba Equipados ativa\n(Aguardando Fase 3 para listar itens)")
    content.placeholder = placeholder

    -- Footer com prompts em texturas oficiais
    local footerHints = {
        { icons = { "A" },        label = "Aplicar" },
        { icons = { "B" },        label = "Cancelar" },
        { icons = { "LB", "RB" }, label = "Alternar Aba" },
    }
    frame.footer = self:BuildIconHints(frame, "ConsoleMode_EnhanceFooter", footerHints, 18)

    self.frame = frame
end

function EnhanceModal:UpdateContentPlaceholder()
    if not self.frame or not self.frame.content or not self.frame.content.placeholder then return end
    if self.currentTab == "BAGS" then
        self.frame.content.placeholder:SetText("Aba Na Mochila ativa\n(Aguardando Fase 5 para listar itens da bolsa)")
    else
        self.frame.content.placeholder:SetText("Aba Equipados ativa\n(Aguardando Fase 3 para listar itens equipados)")
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
        local qCol = QUALITY_COLORS[self.activeContext.itemQuality or 1] or QUALITY_COLORS[1]
        self.frame.itemHeader.titleText:SetText((qCol.hex or "|cffffffff") .. (self.activeContext.itemName or "Aprimoramento") .. "|r")
        self.frame.itemHeader.subText:SetText("Alvo: " .. (self.activeContext.categoryLabel or "Equipamento"))
        if self.activeContext.itemTexture then
            self.frame.itemHeader.iconTex:SetTexture(self.activeContext.itemTexture)
        end
    end

    self:UpdateTabIndicator()
    self:UpdateContentPlaceholder()

    if self.dimmer then self.dimmer:Show() end
    self.frame:Show()

    PlaySound("igMainMenuOpen")
end

function EnhanceModal:Close()
    if not self.isOpen and not (self.frame and self.frame:IsVisible()) then return end

    self.isOpen = false

    -- Cancela o modo de mira da engine do WoW se ainda estiver ativo
    if SpellIsTargeting and SpellIsTargeting() then
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
