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

-- ----------------------------------------------------------------------------
-- 5. MOTOR DE CLASSIFICAÇÃO (Fase 1: Core Interceptor)
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
-- 6. HOOK / INTERCEPTADOR DE USO (Fase 1: Interceptor & Log de Diagnóstico)
-- ----------------------------------------------------------------------------
function EnhanceModal:OnItemUsed(itemData, enhanceInfo)
    if not enhanceInfo then return end

    self.activeContext = enhanceInfo
    self.currentTab = "EQUIP"

    local logMsg = string.format("|cff00ff00[EnhanceModal]|r Aprimoramento detectado: %s (Categoria: %s, Alvos: %s)",
        enhanceInfo.itemName or "Desconhecido",
        enhanceInfo.category or "N/A",
        enhanceInfo.categoryLabel or "N/A"
    )

    if CM.Logger and CM.Logger.Log then
        CM.Logger:Log(logMsg)
    else
        DEFAULT_CHAT_FRAME:AddMessage(logMsg)
    end
end
