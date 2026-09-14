-- ============================================================================
-- ConsoleModeVanilla - UI/CharacterScreen.lua
-- FASE 4 RETRABALHO (docs/plano_de_feature_ABA_DO_PERSONAGEM.md, Fase 4):
-- 11 cards full-width 1 coluna separadas como o BetterCharacterStats:
-- Identidade, Base Stats, Recursos, Melee, Melee vs Boss, Ranged,
-- Spell, Schools, Defenses, Defenses vs Boss, Resistencias.
-- Tecnica BCS PORTADA (sem OptionalDeps, sem chamar BCS): formulas base
-- por classe via UnitStat + varredura de tooltips de gear/talentos/auras
-- com strfind em GameTooltip dedicado criado uma vez (pool fixo).
-- Referencia: BetterCharacterStats/helper.lua (GetManaRegen ~1687,
-- GetSpellCritChance ~669, GetSpellCritFromClass ~853, GetSpellPower,
-- GetHealingPower, tabelas vs Boss) e BetterCharacterStats.lua 16-25
-- (8 categorias) e 1365-1421 (6 stats por categoria).
-- Molde: UI/MerchantMenu.lua e UI/MailScreen.lua (namespace global,
-- Initialize/AttachTo/Show/Hide, pool fixo criado uma vez, identidade
-- visual Vanilla com fontes AlegreyaSans).
-- Compativel com WoW Vanilla 1.12.1 / Lua 5.0 estrito (usa table.getn e
-- ipairs; sem operador length novo, sem desvios novos, sem libs externas).
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_CharacterScreen = ConsoleMode_CharacterScreen or {}
local CharacterScreen = ConsoleMode_CharacterScreen
CM.characterScreen = CharacterScreen

-- ----------------------------------------------------------------------------
-- 1. DESIGN SYSTEM (molde MerchantMenu/MailScreen: so visual, sem logica)
-- ----------------------------------------------------------------------------
local FONTS = {
    titleBold = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    bodyBold  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    medium    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Medium.ttf",
    fallback  = "Fonts\\FRIZQT__.TTF",
}

local COLORS = {
    amberText   = "|cffe09a15",
    title       = { r = 1.00, g = 0.85, b = 0.20 },
    body        = { r = 0.96, g = 0.88, b = 0.68 },
    hint        = { r = 0.70, g = 0.65, b = 0.55 },
    bonusGreen  = "|cff20ff20",
    penaltyRed  = "|cffff4040",
    blockBg     = { r = 0.08, g = 0.06, b = 0.04, a = 0.85 },
    blockBorder = { r = 0.50, g = 0.40, b = 0.28, a = 0.65 },
}

-- Fallback de cor de classe caso RAID_CLASS_COLORS nao exista no cliente.
local FALLBACK_CLASS_COLORS = {
    WARRIOR = "|cffc79c6e",
    PALADIN = "|cfff58cba",
    HUNTER  = "|cffabd473",
    ROGUE   = "|cfffff569",
    PRIEST  = "|cffffffff",
    SHAMAN  = "|cff0070de",
    MAGE    = "|cff69ccf0",
    WARLOCK = "|cff9482c9",
    DRUID   = "|cffff7d0a",
}

local STAT_NAMES = { "Força", "Agilidade", "Vigor", "Intelecto", "Espírito" }
local SCHOOL_NAMES = { "Arcano", "Fogo", "Gelo", "Sagrado", "Natureza", "Sombra" }
local SCHOOL_KEYS  = { "arcane", "fire", "frost", "holy", "nature", "shadow" }

-- ----------------------------------------------------------------------------
-- 2. ESTADO DO MODULO (pool fixo: frames criados uma vez, nunca destruidos)
-- ----------------------------------------------------------------------------
CharacterScreen.initialized  = CharacterScreen.initialized or false
CharacterScreen.attached     = CharacterScreen.attached or false
CharacterScreen.isVisible    = CharacterScreen.isVisible or false
CharacterScreen.firstShown   = CharacterScreen.firstShown or false
CharacterScreen.parentFrame  = CharacterScreen.parentFrame or nil
CharacterScreen.scrollFrame  = CharacterScreen.scrollFrame or nil
CharacterScreen.scrollChild  = CharacterScreen.scrollChild or nil
CharacterScreen.eventFrame   = CharacterScreen.eventFrame or nil
CharacterScreen.scanTip      = CharacterScreen.scanTip or nil

-- Rolagem: offset atual (px), passo por toque no D-Pad, altura do conteudo.
CharacterScreen.scrollOffset = CharacterScreen.scrollOffset or 0
CharacterScreen.scrollStep   = CharacterScreen.scrollStep or 60
CharacterScreen.contentH     = CharacterScreen.contentH or 0
CharacterScreen.viewH        = CharacterScreen.viewH or 0

-- FASE 4: gap entre cards full-width 1 coluna.
CharacterScreen.cardGap = CharacterScreen.cardGap or 12

-- ----------------------------------------------------------------------------
-- 2b. CACHE DE SCAN (padrao BCS needScanGear: so re-escaneia sob demanda;
-- Refresh usa o cache, nunca escaneia a cada chamada).
-- ----------------------------------------------------------------------------
-- Flags sujas: marcadas pelos eventos, consumidas no inicio do Refresh.
CharacterScreen.scanGearDirty    = true
CharacterScreen.scanTalentsDirty = true
CharacterScreen.scanAurasDirty   = true
CharacterScreen.scanSkillsDirty  = true

-- Acumuladores de equipamento (slots 1-19 via tooltip dedicado).
CharacterScreen.gear = CharacterScreen.gear or nil
-- Acumuladores de talentos (varredura SetTalent, so quando dirty).
CharacterScreen.tal = CharacterScreen.tal or nil
-- Acumuladores de auras (buffs/debuffs do jogador, so quando dirty).
CharacterScreen.aur = CharacterScreen.aur or nil
-- Pericia de arma por slot (MH/OH/Ranged, so quando dirty).
CharacterScreen.skillCache = CharacterScreen.skillCache or nil
-- Set bonuses ja contabilizados (1x por set, padrao BCS SetBonus.*).
CharacterScreen.setSeen = CharacterScreen.setSeen or nil

local function CS_ResetScanTables()
    CharacterScreen.gear = {
        sp = 0, spOnly = 0, heal = 0, mp5 = 0,
        hit = 0, rangedHit = 0, spellHit = 0,
        crit = 0, rangedCrit = 0, spellCrit = 0,
        haste = 0, spellHaste = 0, casting = 0,
        arcane = 0, fire = 0, frost = 0,
        holy = 0, nature = 0, shadow = 0,
    }
    CharacterScreen.tal = {
        casting = 0, spiritPct = 0, ironclad = 0,
        hit = 0, spellHit = 0,
        spellHitFire = 0, spellHitFrost = 0, spellHitArcane = 0,
        spellHitShadow = 0, spellHitHoly = 0,
        spellCrit = 0, rangedCrit = 0, spellHaste = 0,
    }
    CharacterScreen.aur = {
        mp5 = 0, casting = 0, regenPct = 0,
        hit = 0, hitDebuff = 0, spellHit = 0,
        spellCrit = 0, rangedCrit = 0,
        sp = 0, spOnly = 0, heal = 0,
        haste = 0, spellHaste = 0,
    }
    CharacterScreen.skillCache = { mh = 0, oh = 0, ranged = 0 }
    CharacterScreen.setSeen = {}
end
CS_ResetScanTables()

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
local function CS_ApplyFont(fs, file, size)
    if not fs then return end
    -- Sem pcall engolindo erro (molde MainMenu:ApplyFont): SetFont 1.12
    -- retorna falsy quando o arquivo falha; ai cai para FRIZQT__.
    if type(fs.SetFont) == "function" then
        local ok = fs:SetFont(file, size, "")
        if not ok then
            fs:SetFont(FONTS.fallback, size, "")
        end
    end
    if type(fs.SetShadowOffset) == "function" then
        fs:SetShadowOffset(1, -1)
    end
    if type(fs.SetShadowColor) == "function" then
        fs:SetShadowColor(0.0, 0.0, 0.0, 0.90)
    end
end

local function CS_HidePlaceholder(parent)
    if parent and parent.placeholder and type(parent.placeholder.Hide) == "function" then
        parent.placeholder:Hide()
    end
end

local function CS_ChatError(msg)
    local dcf = getglobal("DEFAULT_CHAT_FRAME")
    if dcf and type(dcf.AddMessage) == "function" then
        dcf:AddMessage("|cffff4040[ConsoleMode/Character]|r " .. tostring(msg))
    end
end

local function CS_Clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function CS_Num(v, def)
    if type(v) == "number" then return v end
    return def or 0
end

-- Formata numero com 1 casa decimal; "—" se nao for numero.
local function CS_Fmt1(v)
    if type(v) ~= "number" then return "—" end
    return string.format("%.1f", v)
end

-- Formata numero com 2 casas decimais; "—" se nao for numero.
local function CS_Fmt2(v)
    if type(v) ~= "number" then return "—" end
    return string.format("%.2f", v)
end

-- DPS = dano medio / velocidade; "—" se velocidade zerada ou dados ruins.
local function CS_DPS(minD, maxD, speed)
    if type(minD) ~= "number" or type(maxD) ~= "number" then return "—" end
    if type(speed) ~= "number" or speed <= 0 then return "—" end
    return CS_Fmt1(((minD + maxD) / 2) / speed)
end

-- Barra textual proporcional 0..100+ (12 blocos); pool fixo de
-- FontStrings, sem criar textures novas. Lua 5.0 ok (string.rep).
local function CS_ResistBar(total)
    local t = CS_Num(total, 0)
    if t < 0 then t = 0 end
    local filled = math.floor((t / 100) * 12)
    if filled < 0 then filled = 0 end
    if filled > 12 then filled = 12 end
    return "[" .. string.rep("=", filled) .. string.rep(" ", 12 - filled) .. "]"
end

-- Cor hexadecimal da classe: RAID_CLASS_COLORS (1.12) ou fallback estatico.
local function CS_ClassColorHex(classFile)
    if type(RAID_CLASS_COLORS) == "table" and classFile and classFile ~= "" then
        local cc = RAID_CLASS_COLORS[classFile]
        if type(cc) == "table" and type(cc.r) == "number"
            and type(cc.g) == "number" and type(cc.b) == "number" then
            return string.format("|cff%02x%02x%02x",
                (cc.r or 1) * 255, (cc.g or 1) * 255, (cc.b or 1) * 255)
        end
    end
    if classFile and FALLBACK_CLASS_COLORS[classFile] then
        return FALLBACK_CLASS_COLORS[classFile]
    end
    return "|cffffffff"
end

-- Classe do jogador em MAIUSCULAS ("WARRIOR"); "" se API ausente.
local function CS_PlayerClass()
    if type(UnitClass) == "function" then
        local _, cf = UnitClass("player")
        if type(cf) == "string" and cf ~= "" then return cf end
    end
    return ""
end

-- Regra BCS (BetterCharacterStats.lua:701,798,1043,1467): classes com slot
-- de reliquia (paladino/xama/druida) nao tem card Ranged.
local function CS_HasRelicSlot()
    if type(UnitHasRelicSlot) == "function" then
        local ok, v = pcall(UnitHasRelicSlot, "player")
        if ok and v then return true end
    end
    return false
end

-- Offhand com arma? (1.12: OffhandHasWeapon() retorna 1/0/nil).
local function CS_OffhandHasWeapon()
    if type(OffhandHasWeapon) == "function" then
        local ok, v = pcall(OffhandHasWeapon)
        if ok and v == 1 then return true end
    end
    return false
end

-- Deteccao dos modos Turtle/Hardcore via varredura de buffs do jogador.
-- Retorna o texto pronto para exibicao; "Modo: Normal" quando nada achar.
local function CS_DetectTurtleMode()
    local foundHC = false
    local foundTurtle = false
    local function CS_ScanTexture(tex)
        if type(tex) ~= "string" or tex == "" then return end
        local low = string.lower(tex)
        if string.find(low, "hardcore", 1, true) then foundHC = true end
        if string.find(low, "turtle", 1, true)
            or string.find(low, "survival", 1, true)
            or string.find(low, "slow", 1, true)
            or string.find(low, "warmode", 1, true)
            or string.find(low, "ironman", 1, true) then
            foundTurtle = true
        end
    end
    if type(UnitBuff) == "function" then
        for i = 1, 32 do
            local ok, tex = pcall(UnitBuff, "player", i)
            if ok then CS_ScanTexture(tex) end
        end
    end
    if type(GetPlayerBuffTexture) == "function" then
        for i = 0, 31 do
            local ok, tex = pcall(GetPlayerBuffTexture, i)
            if ok then CS_ScanTexture(tex) end
        end
    end
    if foundHC then return "Modo: Hardcore Ativo" end
    if foundTurtle then return "Modo: Turtle Ativo" end
    return "Modo: Normal"
end

-- ----------------------------------------------------------------------------
-- 2c. TOOLTIP DEDICADO DE SCAN (pool fixo: criado uma vez, nunca destruido;
-- SetInventoryItem/SetHyperlink + strfind, padrao BCS helper.lua:5-7).
-- ----------------------------------------------------------------------------
function CharacterScreen:EnsureScanTip()
    if self.scanTip then return self.scanTip end
    if type(CreateFrame) ~= "function" then return nil end
    local tip = CreateFrame("GameTooltip", "ConsoleMode_CharacterScanTooltip", nil, "GameTooltipTemplate")
    if not tip then return nil end
    local wf = getglobal("WorldFrame")
    if wf and type(tip.SetOwner) == "function" then
        tip:SetOwner(wf, "ANCHOR_NONE")
    end
    if type(tip.Hide) == "function" then tip:Hide() end
    self.scanTip = tip
    return tip
end

-- Itera as linhas de texto do tooltip dedicado; chama fn(text) por linha.
-- Lua 5.0: string.find/strfind, SEM gmatch.
local function CS_ForEachTipLine(tip, fn)
    if not tip or type(tip.NumLines) ~= "function" then return end
    if type(fn) ~= "function" then return end
    local tipName = nil
    if type(tip.GetName) == "function" then tipName = tip:GetName() end
    if type(tipName) ~= "string" or tipName == "" then return end
    local n = tip:NumLines()
    if type(n) ~= "number" or n <= 0 then return end
    for i = 1, n do
        local fs = getglobal(tipName .. "TextLeft" .. i)
        if fs and type(fs.GetText) == "function" then
            local ok, text = pcall(fs.GetText, fs)
            if ok and type(text) == "string" and text ~= "" then
                fn(text)
            end
        end
    end
end

-- Extrai numero de padrao Lua via strfind; 0 se nao casar (nunca nil).
local function CS_MatchNum(text, pattern)
    if type(text) ~= "string" or type(pattern) ~= "string" then return 0 end
    local _, _, v = strfind(text, pattern)
    if v then v = tonumber(v) end
    if type(v) == "number" then return v end
    return 0
end

-- ----------------------------------------------------------------------------
-- 2d. SCAN DE GEAR (tecnica BCS:GetSpellPower/GetHealingPower/GetManaRegen/
-- GetHitRating/GetSpellHitRating/GetSpellCritChance/GetHaste/GetBlockValue:
-- slots 1-19 + oleos da arma (slot 16); set bonus 1x por set via setSeen).
-- Cliente Turtle WoW em ingles: padroes literais em ingles.
-- ----------------------------------------------------------------------------

-- Padroes de linha NORMAL (fora de bloco "Set:"): { campo, padrao }.
local CS_GEAR_NORMAL = {
    -- Spell power generico (dano+cura).
    { "sp",     "Increases damage and healing done by magical spells and effects by up to (%d+)" },
    { "sp",     "Spell Damage %+(%d+)" },
    { "sp",     "%+(%d+) Spell Damage and Healing" },
    { "sp",     "%+(%d+) Damage and Healing Spells" },
    -- Dano magico apenas (Atiesh/Scythe de Elune).
    { "spOnly", "Increases your spell damage by up to (%d+) and your healing by up to %d+" },
    { "spOnly", "Increases damage done by magical spells and effects by up to (%d+)" },
    -- Cura apenas.
    { "heal",   "Increases healing done by spells and effects by up to (%d+)" },
    { "heal",   "Increases your spell damage by up to %d+ and your healing by up to (%d+)" },
    { "heal",   "Healing Spells %+(%d+)" },
    { "heal",   "%+(%d+) Healing Spells" },
    { "heal",   "Healing %+(%d+)" },
    -- MP5 (tecnica BCS:GetManaRegen).
    { "mp5",    "Mana Regen %+(%d+)" },
    { "mp5",    "Restores (%d+) mana per 5 sec" },
    { "mp5",    "Healing %+%d+ and (%d+) mana per 5 sec" },
    { "mp5",    "%+(%d+) mana every 5 sec" },
    { "casting","Allows (%d+)%% of your Mana regeneration to continue while casting" },
    -- Hit fisico / ranged / magico (tecnica BCS:GetHitRating).
    { "hit",      "Improves your chance to hit by (%d+)%%" },
    { "hit",      "Hit %+(%d+)" },
    { "hit",      "Improves your chance to hit with spells and attacks by (%d+)%%" },
    { "rangedHit","%+(%d+)%% Ranged Hit" },
    { "spellHit", "Improves your chance to hit with spells by (%d+)%%" },
    { "spellHit", "Spell Hit %+(%d+)" },
    { "spellHit", "Improves your chance to hit and get a critical strike with spells by (%d+)%%" },
    -- Crit fisico / ranged / magico.
    { "crit",       "Improves your chance to get a critical strike by (%d+)%%" },
    { "rangedCrit", "Improves your chance to get a critical strike with missile weapons by (%d+)%%" },
    { "rangedCrit", "%+(%d+)%% Critical Strike" },
    { "spellCrit",  "Improves your chance to get a critical strike with spells by (%d+)%%" },
    { "spellCrit",  "(%d+)%% Spell Critical Strike" },
    -- Haste (tecnica BCS:GetHaste).
    { "haste",      "Increases your attack and casting speed by (%d+)%%" },
    { "spellHaste", "Increases your casting speed by (%d+)%%" },
    { "haste",      "%+(%d+)%% Haste" },
    { "haste",      "Attack speed %+(%d+)%%" },
    -- Escolas (tecnica BCS:GetSpellPower(school)).
    { "arcane", "Increases damage done by Arcane spells and effects by up to (%d+)" },
    { "arcane", "%+(%d+) Arcane Spell Damage" },
    { "arcane", "Arcane Damage %+(%d+)" },
    { "fire",   "Increases damage done by Fire spells and effects by up to (%d+)" },
    { "fire",   "Fire Damage %+(%d+)" },
    { "fire",   "%+(%d+) Fire Spell Damage" },
    { "frost",  "Increases damage done by Frost spells and effects by up to (%d+)" },
    { "frost",  "Frost Damage %+(%d+)" },
    { "frost",  "%+(%d+) Frost Spell Damage" },
    { "holy",   "Increases damage done by Holy spells and effects by up to (%d+)" },
    { "holy",   "%+(%d+) Holy Spell Damage" },
    { "holy",   "Holy Damage %+(%d+)" },
    { "nature", "Increases damage done by Nature spells and effects by up to (%d+)" },
    { "nature", "%+(%d+) Nature Spell Damage" },
    { "nature", "Nature Damage %+(%d+)" },
    { "shadow", "Increases damage done by Shadow spells and effects by up to (%d+)" },
    { "shadow", "Shadow Damage %+(%d+)" },
    { "shadow", "%+(%d+) Shadow Spell Damage" },
}

-- Padroes de bloco "Set:": { campo, padrao } (1x por nome de set, como BCS).
local CS_GEAR_SET = {
    { "hit",       "^Set: Improves your chance to hit by (%d+)%%" },
    { "spellHit",  "^Set: Improves your chance to hit with spells by (%d+)%%" },
    { "crit",      "^Set: Improves your chance to get a critical strike by (%d+)%%" },
    { "spellCrit", "^Set: Improves your chance to get a critical strike with spells by (%d+)%%" },
    { "sp",        "^Set: Increases damage and healing done by magical spells and effects by up to (%d+)%%" },
    { "heal",      "^Set: Increases healing done by spells and effects by up to (%d+)%%" },
    { "mp5",       "^Set: Restores (%d+) mana per 5 sec" },
    { "casting",   "^Set: Allows (%d+)%% of your Mana regeneration to continue while casting" },
}

local function CS_ScanGearSlotLine(text, curSet, gear, seen)
    -- Cabecalho de set: "Nome do Set (3/8)".
    local _, _, setName = strfind(text, "(.+) %(%d+/%d+%)")
    if setName then return setName end
    if string.sub(text, 1, 4) == "Set:" then
        for i = 1, table.getn(CS_GEAR_SET) do
            local field = CS_GEAR_SET[i][1]
            local v = CS_MatchNum(text, CS_GEAR_SET[i][2])
            if v > 0 then
                if curSet then
                    local key = field .. "@" .. curSet
                    if not seen[key] then
                        seen[key] = true
                        gear[field] = (gear[field] or 0) + v
                    end
                end
            end
        end
        return curSet
    end
    for i = 1, table.getn(CS_GEAR_NORMAL) do
        local field = CS_GEAR_NORMAL[i][1]
        local v = CS_MatchNum(text, CS_GEAR_NORMAL[i][2])
        if v > 0 then
            gear[field] = (gear[field] or 0) + v
        end
    end
    return curSet
end

local function CS_ScanGear()
    local gear = CharacterScreen.gear
    local seen = {}
    CharacterScreen.setSeen = seen
    local tip = CharacterScreen:EnsureScanTip()
    if not tip or type(tip.SetInventoryItem) ~= "function" then return end
    if type(GetInventoryItemLink) ~= "function" then return end
    for slot = 1, 19 do
        local okHas, hasItem = pcall(tip.SetInventoryItem, tip, "player", slot)
        if okHas and hasItem then
            local curSet = nil
            CS_ForEachTipLine(tip, function(text)
                -- Re-resolve via hyperlink como o BCS (item base); se falhar,
                -- mantem as linhas do SetInventoryItem (com encantamentos).
                curSet = CS_ScanGearSlotLine(text, curSet, gear, seen)
            end)
            -- Segunda passada via hyperlink (texto do item base, sem a linha
            -- "Currently Equipped"): replica o BCS sem duplicar — so conta
            -- se o hyperlink existir; linhas de set sao dedupadas por setSeen
            -- e linhas normais podem duplicar, entao NAO re-soma normais:
            -- usa-se apenas o SetInventoryItem (que inclui oleos/encantos).
            -- (Decisao consciente: 1 passada = sem duplo-conto.)
        end
    end
    -- Oleos temporarios da arma (slot 16): SetInventoryItem mostra o
    -- encantamento ativo (tecnica BCS:GetSpellPower/GetManaRegen).
    do
        local okHas, hasItem = pcall(tip.SetInventoryItem, tip, "player", 16)
        if okHas and hasItem then
            CS_ForEachTipLine(tip, function(text)
                if string.find(text, "Brilliant Wizard Oil", 1, true) then
                    gear.sp = gear.sp + 36
                    gear.spellCrit = gear.spellCrit + 1
                elseif string.find(text, "Lesser Wizard Oil", 1, true) then
                    gear.sp = gear.sp + 16
                elseif string.find(text, "Minor Wizard Oil", 1, true) then
                    gear.sp = gear.sp + 8
                elseif string.find(text, "Wizard Oil", 1, true) then
                    gear.sp = gear.sp + 24
                end
                if string.find(text, "Brilliant Mana Oil", 1, true) then
                    gear.heal = gear.heal + 25
                    gear.mp5 = gear.mp5 + 12
                elseif string.find(text, "Lesser Mana Oil", 1, true) then
                    gear.mp5 = gear.mp5 + 8
                elseif string.find(text, "Minor Mana Oil", 1, true) then
                    gear.mp5 = gear.mp5 + 4
                end
            end)
        end
    end
    if type(tip.Hide) == "function" then tip:Hide() end
    if type(tip.ClearLines) == "function" then tip:ClearLines() end
end

-- ----------------------------------------------------------------------------
-- 2e. SCAN DE TALENTOS (tecnica BCS: SetTalent + strfind; subconjunto
-- curado de alto valor: regen while casting, Spiritual Guidance, Ironclad,
-- hit fisico/magico, spell crit, ranged crit, spell haste).
-- ----------------------------------------------------------------------------
local function CS_ScanTalents()
    local tal = CharacterScreen.tal
    tal.casting = 0
    tal.spiritPct = 0
    tal.ironclad = 0
    tal.hit = 0
    tal.spellHit = 0
    tal.spellHitFire = 0
    tal.spellHitFrost = 0
    tal.spellHitArcane = 0
    tal.spellHitShadow = 0
    tal.spellHitHoly = 0
    tal.spellCrit = 0
    tal.rangedCrit = 0
    tal.spellHaste = 0
    local tip = CharacterScreen:EnsureScanTip()
    if not tip or type(tip.SetTalent) ~= "function" then return end
    if type(GetNumTalentTabs) ~= "function" then return end
    if type(GetNumTalents) ~= "function" then return end
    if type(GetTalentInfo) ~= "function" then return end
    local nTabs = GetNumTalentTabs()
    if type(nTabs) ~= "number" or nTabs <= 0 then return end
    for tab = 1, nTabs do
        local nTal = GetNumTalents(tab)
        if type(nTal) == "number" and nTal > 0 then
            for talent = 1, nTal do
                local okT, nameT, _, _, _, rankT = pcall(GetTalentInfo, tab, talent)
                local rank = 0
                if okT and type(rankT) == "number" then rank = rankT end
                if rank > 0 then
                    local okS = pcall(tip.SetTalent, tip, tab, talent)
                    if okS then
                    local matched = false
                    CS_ForEachTipLine(tip, function(text)
                        if matched then return end
                        local low = string.lower(text)
                        local v = 0
                        -- Meditation / Reflection / Arcane Meditation (MP while casting).
                        v = CS_MatchNum(low, "allows (%d+)%% of your mana regeneration to continue while casting")
                        if v > 0 then tal.casting = tal.casting + v matched = true return end
                        -- Spiritual Guidance (priest): +% dano/cura do espirito.
                        v = CS_MatchNum(low, "increases spell damage and healing by up to (%d+)%% of your total spirit")
                        if v > 0 then tal.spiritPct = v matched = true return end
                        -- Ironclad (paladino/Turtle): +% cura da armadura.
                        v = CS_MatchNum(low, "increases your healing power by (%d+)%% of your armor")
                        if v > 0 then tal.ironclad = v matched = true return end
                        -- Precision (rogue): hit melee.
                        v = CS_MatchNum(low, "increases your chance to hit with melee weapons by (%d+)%%")
                        if v > 0 then tal.hit = tal.hit + v matched = true return end
                        -- Surefooted (hunter): hit.
                        v = CS_MatchNum(low, "increases hit chance by (%d+)%%")
                        if v > 0 then tal.hit = tal.hit + v matched = true return end
                        -- Natural Weapons / Precision / Elemental Devastation:
                        -- hit melee + spells.
                        v = CS_MatchNum(low, "chance to hit with melee attacks and spells by (%d+)%%")
                        if v > 0 then
                            tal.hit = tal.hit + v
                            tal.spellHit = tal.spellHit + v
                            matched = true
                            return
                        end
                        v = CS_MatchNum(low, "chance to hit with spells and melee attacks by (%d+)%%")
                        if v > 0 then
                            tal.hit = tal.hit + v
                            tal.spellHit = tal.spellHit + v
                            matched = true
                            return
                        end
                        -- Elemental Precision (mage): fogo+gelo.
                        v = CS_MatchNum(low, "resist your frost and fire spells by (%d+)%%")
                        if v > 0 then
                            tal.spellHitFire = tal.spellHitFire + v
                            tal.spellHitFrost = tal.spellHitFrost + v
                            matched = true
                            return
                        end
                        -- Arcane Focus (mage): arcano.
                        v = CS_MatchNum(low, "resist your arcane spells by (%d+)%%")
                        if v > 0 then tal.spellHitArcane = tal.spellHitArcane + v matched = true return end
                        -- Piercing Light (priest): sagrado/disciplina.
                        v = CS_MatchNum(low, "resist your holy and discipline spells by (%d+)%%")
                        if v > 0 then tal.spellHitHoly = tal.spellHitHoly + v matched = true return end
                        -- Shadow Focus (priest) / Suppression (warlock): sombra.
                        v = CS_MatchNum(low, "resist your shadow spells by (%d+)%%")
                        if v > 0 then tal.spellHitShadow = tal.spellHitShadow + v matched = true return end
                        v = CS_MatchNum(low, "resist your affliction spells by (%d+)%%")
                        if v > 0 then tal.spellHitShadow = tal.spellHitShadow + v matched = true return end
                        -- Critical Mass (mage): crit fogo.
                        v = CS_MatchNum(low, "increases the critical strike chance of your fire spells by (%d+)%%")
                        if v > 0 then tal.spellCrit = tal.spellCrit + v matched = true return end
                        -- Arcane Instability (mage; "srike" = typo original BCS).
                        v = CS_MatchNum(low, "increases your spell damage and critical srike chance by (%d+)%%")
                        if v > 0 then tal.spellCrit = tal.spellCrit + v matched = true return end
                        -- Devastation (warlock): crit destruicao.
                        v = CS_MatchNum(low, "increases the critical strike chance of your destruction spells by (%d+)%%")
                        if v > 0 then tal.spellCrit = tal.spellCrit + v matched = true return end
                        -- Divinity (priest): crit sagrado/disciplina.
                        v = CS_MatchNum(low, "increases the critical effect chance of your holy and discipline spells by (%d+)%%")
                        if v > 0 then tal.spellCrit = tal.spellCrit + v matched = true return end
                        -- Lethal Shots (hunter): crit ranged.
                        v = CS_MatchNum(low, "increases your critical strike chance with ranged weapons by (%d+)%%")
                        if v > 0 then tal.rangedCrit = tal.rangedCrit + v matched = true return end
                        -- Mental Agility (priest/Turtle): spell haste.
                        v = CS_MatchNum(low, "your spell casting speed by (%d+)%%")
                        if v > 0 then tal.spellHaste = tal.spellHaste + v matched = true return end
                    end)
                    end
                end
            end
        end
    end
    if type(tip.Hide) == "function" then tip:Hide() end
    if type(tip.ClearLines) == "function" then tip:ClearLines() end
end

-- ----------------------------------------------------------------------------
-- 2f. SCAN DE AURAS (tecnica BCS:GetPlayerAura: buffs 0-31 HELPFUL e
-- debuffs 0-6 HARMFUL via SetPlayerBuff + strfind; subconjunto curado).
-- ----------------------------------------------------------------------------
local function CS_ScanAuraLines(text, aur)
    local v = 0
    -- MP5 de consumiveis/efeitos (multiplicadores BCS: Nightfin x2.5,
    -- Second Wind x5 por tick de 1s).
    v = CS_MatchNum(text, "Restores (%d+) mana per 5 sec")
    if v > 0 then aur.mp5 = aur.mp5 + v return end
    v = CS_MatchNum(text, "Regenerate (%d+) mana per 5 sec")
    if v > 0 then aur.mp5 = aur.mp5 + v return end
    v = CS_MatchNum(text, "Regenerating (%d+) Mana every 5 seconds")
    if v > 0 then aur.mp5 = aur.mp5 + (v * 2.5) return end
    v = CS_MatchNum(text, "Mana Regeneration increased by (%d+) every 5 seconds")
    if v > 0 then aur.mp5 = aur.mp5 + (v * 2.5) return end
    v = CS_MatchNum(text, "Restores (%d+) mana every 1 sec")
    if v > 0 then aur.mp5 = aur.mp5 + (v * 5) return end
    v = CS_MatchNum(text, "Restores (%d+) mana per 5 seconds")
    if v > 0 then aur.mp5 = aur.mp5 + v return end
    -- Regen % (Innervate dobra a base).
    v = CS_MatchNum(text, "Mana regeneration increased by (%d+)%%")
    if v > 0 then aur.regenPct = aur.regenPct + v end
    -- While-casting (Mage Armor, Aura of the Blue Dragon, Sylvan...).
    v = CS_MatchNum(text, "(%d+)%% of your Mana regeneration continuing while casting")
    if v > 0 then aur.casting = aur.casting + v return end
    v = CS_MatchNum(text, "(%d+)%% of your mana regeneration to continue while casting")
    if v > 0 then aur.casting = aur.casting + v return end
    v = CS_MatchNum(text, "Allows (%d+)%% of mana regeneration while casting")
    if v > 0 then aur.casting = aur.casting + v return end
    v = CS_MatchNum(text, "(%d+)%% Mana regeneration may continue while casting")
    if v > 0 then aur.casting = aur.casting + v return end
    -- Hit / spell hit / crit de buffs.
    v = CS_MatchNum(text, "Chance to hit increased by (%d+)%%")
    if v > 0 then aur.hit = aur.hit + v return end
    v = CS_MatchNum(text, "Improves your chance to hit by (%d+)%%")
    if v > 0 then aur.hit = aur.hit + v return end
    v = CS_MatchNum(text, "Spell hit chance increased by (%d+)%%")
    if v > 0 then aur.spellHit = aur.spellHit + v return end
    v = CS_MatchNum(text, "Chance for a critical hit with a spell increased by (%d+)%%")
    if v > 0 then aur.spellCrit = aur.spellCrit + v return end
    v = CS_MatchNum(text, "Increases spell critical chance by (%d+)%%")
    if v > 0 then aur.spellCrit = aur.spellCrit + v return end
    v = CS_MatchNum(text, "Chance to get a critical strike with spells is increased by (%d+)%%")
    if v > 0 then aur.spellCrit = aur.spellCrit + v return end
    v = CS_MatchNum(text, "Critical strike chance with spells and melee attacks increased by (%d+)%%")
    if v > 0 then aur.spellCrit = aur.spellCrit + v return end
    if string.find(text, "Inner Focus", 1, true) then aur.spellCrit = aur.spellCrit + 25 return end
    v = CS_MatchNum(text, "Critical hit chance increases by (%d+)%%")
    if v > 0 then aur.rangedCrit = aur.rangedCrit + v return end
    -- Spell power / cura de buffs.
    v = CS_MatchNum(text, "Magical damage dealt is increased by up to (%d+)")
    if v > 0 then aur.spOnly = aur.spOnly + v return end
    v = CS_MatchNum(text, "Increases damage and healing done by magical spells and effects by up to (%d+)%%")
    if v > 0 then aur.sp = aur.sp + v return end
    v = CS_MatchNum(text, "Healing done by magical spells is increased by up to (%d+)")
    if v > 0 then aur.heal = aur.heal + v return end
    v = CS_MatchNum(text, "Increases healing done by magical spells and effects by up to (%d+)")
    if v > 0 then aur.heal = aur.heal + v return end
    v = CS_MatchNum(text, "Healing done is increased by up to (%d+)")
    if v > 0 then aur.heal = aur.heal + v return end
    v = CS_MatchNum(text, "Healing increased by up to (%d+)")
    if v > 0 then aur.heal = aur.heal + v return end
    v = CS_MatchNum(text, "Healing Bonus increased by (%d+)")
    if v > 0 then aur.heal = aur.heal + v return end
    -- Haste de buffs (subconjunto BCS:GetHaste).
    v = CS_MatchNum(text, "Increases attack speed by (%d+)%%")
    if v > 0 then aur.haste = aur.haste + v return end
    v = CS_MatchNum(text, "Increases attack and spell casting speed by (%d+)%%")
    if v > 0 then aur.haste = aur.haste + v return end
    v = CS_MatchNum(text, "Casting speed increased by (%d+)%%")
    if v > 0 then aur.spellHaste = aur.spellHaste + v return end
    v = CS_MatchNum(text, "Attack and casting speed increased by (%d+)%%")
    if v > 0 then aur.haste = aur.haste + v return end
end

local function CS_ScanAuras()
    local aur = CharacterScreen.aur
    aur.mp5 = 0 aur.casting = 0 aur.regenPct = 0
    aur.hit = 0 aur.hitDebuff = 0 aur.spellHit = 0
    aur.spellCrit = 0 aur.rangedCrit = 0
    aur.sp = 0 aur.spOnly = 0 aur.heal = 0
    aur.haste = 0 aur.spellHaste = 0
    local tip = CharacterScreen:EnsureScanTip()
    if not tip or type(tip.SetPlayerBuff) ~= "function" then return end
    if type(GetPlayerBuff) ~= "function" then return end
    for i = 0, 31 do
        local okB, idx = pcall(GetPlayerBuff, i, "HELPFUL")
        if okB and type(idx) == "number" and idx > -1 then
            pcall(tip.SetPlayerBuff, tip, idx)
            CS_ForEachTipLine(tip, function(text)
                CS_ScanAuraLines(text, aur)
            end)
        end
    end
    -- Debuffs que reduzem hit (tecnica BCS:GetHitRating hit_debuff).
    for i = 0, 6 do
        local okB, idx = pcall(GetPlayerBuff, i, "HARMFUL")
        if okB and type(idx) == "number" and idx > -1 then
            pcall(tip.SetPlayerBuff, tip, idx)
            CS_ForEachTipLine(tip, function(text)
                local v = CS_MatchNum(text, "Chance to hit reduced by (%d+)%%")
                if v > 0 then aur.hitDebuff = aur.hitDebuff + v return end
                v = CS_MatchNum(text, "Chance to hit decreased by (%d+)%%")
                if v > 0 then aur.hitDebuff = aur.hitDebuff + v return end
                if string.find(text, "Lowered chance to hit", 1, true) then
                    aur.hitDebuff = aur.hitDebuff + 25
                end
            end)
        end
    end
    if type(tip.Hide) == "function" then tip:Hide() end
    if type(tip.ClearLines) == "function" then tip:ClearLines() end
end

-- ----------------------------------------------------------------------------
-- 2g. PERICIA DE ARMA (tecnica BCS:GetWeaponSkill/GetWeaponSkillForWeaponType/
-- GetMHWeaponSkill/GetOHWeaponSkill/GetRangedWeaponSkill via GetSkillLineInfo
-- + GetItemInfo; cache com needScanSkills).
-- ----------------------------------------------------------------------------
local CS_WEAPON_SKILL_MAP = {
    ["Daggers"]            = "Daggers",
    ["One-Handed Swords"]  = "Swords",
    ["Two-Handed Swords"]  = "Two-Handed Swords",
    ["One-Handed Axes"]    = "Axes",
    ["Two-Handed Axes"]    = "Two-Handed Axes",
    ["One-Handed Maces"]   = "Maces",
    ["Two-Handed Maces"]   = "Two-Handed Maces",
    ["Staves"]             = "Staves",
    ["Polearms"]           = "Polearms",
    ["Fist Weapons"]       = "Unarmed",
    ["Bows"]               = "Bows",
    ["Crossbows"]          = "Crossbows",
    ["Guns"]               = "Guns",
    ["Thrown"]             = "Thrown",
    ["Wands"]              = "Wands",
}

local function CS_GetWeaponSkillByName(skillName)
    if type(skillName) ~= "string" or skillName == "" then return 0 end
    if type(GetSkillLineInfo) ~= "function" then return 0 end
    for idx = 1, 500 do
        local ok, name, _, _, rank, _, mod = pcall(GetSkillLineInfo, idx)
        if not ok then return 0 end
        if name == nil then return 0 end
        if name == skillName then
            return CS_Num(rank, 0) + CS_Num(mod, 0)
        end
    end
    return 0
end

local function CS_GetItemSubType(invSlotName)
    if type(GetInventorySlotInfo) ~= "function" then return nil end
    if type(GetInventoryItemLink) ~= "function" then return nil end
    if type(GetItemInfo) ~= "function" then return nil end
    local okS, invSlot = pcall(GetInventorySlotInfo, invSlotName)
    if not okS or type(invSlot) ~= "number" then return nil end
    local okL, link = pcall(GetInventoryItemLink, "player", invSlot)
    if not okL or type(link) ~= "string" or link == "" then return nil end
    local _, _, itemId = strfind(link, "(item:%d+:%d+:%d+:%d+)")
    if not itemId then return nil end
    local okI, _, _, _, _, _, subType = pcall(GetItemInfo, itemId)
    if not okI then return nil end
    if type(subType) == "string" and subType ~= "" then return subType end
    return nil
end

local function CS_GetWeaponSkillForSlot(invSlotName)
    local subType = CS_GetItemSubType(invSlotName)
    local skillName = nil
    if type(subType) == "string" then skillName = CS_WEAPON_SKILL_MAP[subType] end
    if type(skillName) ~= "string" then skillName = "Unarmed" end
    return CS_GetWeaponSkillByName(skillName)
end

local function CS_ScanSkills()
    local sc = CharacterScreen.skillCache
    sc.mh = CS_GetWeaponSkillForSlot("MainHandSlot")
    sc.oh = CS_GetWeaponSkillForSlot("SecondaryHandSlot")
    sc.ranged = CS_GetWeaponSkillForSlot("RangedSlot")
end

-- ----------------------------------------------------------------------------
-- 2h. FORMULAS BCS PORTADAS (com guards; nunca concatenar nil).
-- ----------------------------------------------------------------------------

-- BCS:GetMissChanceRaw/BCS:GetMissChance/BCS:GetDualWieldMissChance.
-- Ramo TURTLE_WOW_VERSION quando o global existir (nosso alvo = Turtle).
-- Forward declaration: CS_MissChanceRaw usa CS_MeleeHitRaw em runtime.
local CS_MeleeHitRaw = nil
local function CS_MissChanceRaw(wepSkill)
    local ws = CS_Num(wepSkill, 0)
    local diff = ws - 315
    local miss = 5
    if type(getglobal("TURTLE_WOW_VERSION")) ~= "nil" then
        miss = miss - (diff * 0.2) - CS_MeleeHitRaw()
    else
        if diff < -10 then
            miss = miss - diff * 0.2
        else
            miss = miss - diff * 0.1
        end
        local hitChance = CS_MeleeHitRaw()
        if diff < -10 and hitChance > 0 then hitChance = hitChance - 1 end
        miss = miss - hitChance
    end
    return miss
end

local function CS_MissChance(wepSkill)
    return CS_Clamp(CS_MissChanceRaw(wepSkill), 0, 60)
end

local function CS_DualWieldMissChance(wepSkill)
    return CS_Clamp(CS_MissChanceRaw(wepSkill) + 19, 0, 60)
end

-- BCS:GetGlanceChance (10 + 15*2 = 40%) e BCS:GetGlanceReduction.
local function CS_GlanceChance()
    return 10 + 15 * 2
end

local function CS_GlanceReduction(wepSkill)
    local ws = CS_Num(wepSkill, 0)
    if type(getglobal("TURTLE_WOW_VERSION")) ~= "nil" then
        return 65 + (ws - 300) * 2
    end
    local diff = 315 - ws
    local low = math.max(math.min(1.3 - 0.05 * diff, 0.91), 0.01)
    local high = math.max(math.min(1.2 - 0.03 * diff, 0.99), 0.2)
    return 100 * ((high - low) / 2 + low)
end

-- BCS:GetDodgeChance(wepSkill) vs boss.
local function CS_BossDodgeChance(wepSkill)
    local ws = CS_Num(wepSkill, 0)
    local d = 5 + (315 - ws) * 0.1
    if d < 0 then d = 0 end
    return d
end

-- BCS:GetCritCap / BCS:GetDualWieldCritCap.
local function CS_CritCap(wepSkill)
    local cap = 100 - CS_MissChance(wepSkill) - CS_GlanceChance() - CS_BossDodgeChance(wepSkill)
    return CS_Clamp(cap, 0, 100)
end

local function CS_DualWieldCritCap(wepSkill)
    local cap = 100 - CS_DualWieldMissChance(wepSkill) - CS_GlanceChance() - CS_BossDodgeChance(wepSkill)
    return CS_Clamp(cap, 0, 100)
end

-- Hit fisico (BCS:GetHitRating): talentos + gear + auras - debuff (>= 0).
CS_MeleeHitRaw = function()
    local g = CharacterScreen.gear
    local t = CharacterScreen.tal
    local a = CharacterScreen.aur
    if not g or not t or not a then return 0 end
    return (t.hit or 0) + (g.hit or 0) + (a.hit or 0)
end

local function CS_MeleeHit()
    local a = CharacterScreen.aur
    local debuff = 0
    if a then debuff = a.hitDebuff or 0 end
    local hit = CS_MeleeHitRaw() - debuff
    if hit < 0 then hit = 0 end
    return hit
end

-- BCS:GetRangedHitRating.
local function CS_RangedHit()
    local g = CharacterScreen.gear
    local a = CharacterScreen.aur
    local rh = 0
    local debuff = 0
    if g then rh = g.rangedHit or 0 end
    if a then debuff = a.hitDebuff or 0 end
    local hit = CS_MeleeHitRaw() + rh - debuff
    if hit < 0 then hit = 0 end
    return hit
end

-- BCS:GetSpellHitRating -> hit geral + por escola.
local function CS_SpellHit()
    local g = CharacterScreen.gear
    local t = CharacterScreen.tal
    local a = CharacterScreen.aur
    local base = 0
    local fire, frost, arcane, shadow, holy = 0, 0, 0, 0, 0
    if g then base = base + (g.spellHit or 0) end
    if t then
        base = base + (t.spellHit or 0)
        fire = fire + (t.spellHitFire or 0)
        frost = frost + (t.spellHitFrost or 0)
        arcane = arcane + (t.spellHitArcane or 0)
        shadow = shadow + (t.spellHitShadow or 0)
        holy = holy + (t.spellHitHoly or 0)
    end
    if a then base = base + (a.spellHit or 0) end
    return base, fire, frost, arcane, shadow, holy
end

-- BCS:GetSpellCritChance (formula intelecto/classe vmangos + gear/auras/
-- talentos; GetSpellCritFromClass por-magia omitido — exibe o generico).
local function CS_SpellCritBase()
    local class = CS_PlayerClass()
    local intellect = 0
    if type(UnitStat) == "function" then
        local _, v = UnitStat("player", 4)
        intellect = CS_Num(v, 0)
    end
    local level = 0
    if type(UnitLevel) == "function" then level = UnitLevel("player") or 0 end
    level = CS_Num(level, 0)
    local crit = 0
    if class == "MAGE" or class == "PALADIN" then
        crit = 3.7 + intellect / (14.77 + 0.65 * level)
    elseif class == "WARLOCK" then
        crit = 3.18 + intellect / (11.30 + 0.82 * level)
    elseif class == "PRIEST" then
        crit = 2.97 + intellect / (10.03 + 0.82 * level)
    elseif class == "DRUID" then
        crit = 3.33 + intellect / (12.41 + 0.79 * level)
    elseif class == "SHAMAN" then
        crit = 3.54 + intellect / (11.51 + 0.8 * level)
    end
    local g = CharacterScreen.gear
    local t = CharacterScreen.tal
    local a = CharacterScreen.aur
    if g then crit = crit + (g.spellCrit or 0) end
    if t then crit = crit + (t.spellCrit or 0) end
    if a then crit = crit + (a.spellCrit or 0) end
    return crit
end

-- BCS:GetRangedCritChance (formula agilidade/classe vmangos + gear/talentos/
-- auras + modificador de pericia de BCS:SetRangedCritChance).
local function CS_RangedCrit()
    local class = CS_PlayerClass()
    local agility = 0
    if type(UnitStat) == "function" then
        local _, v = UnitStat("player", 2)
        agility = CS_Num(v, 0)
    end
    local level = 0
    if type(UnitLevel) == "function" then level = UnitLevel("player") or 0 end
    level = CS_Num(level, 0)
    local v1, v60 = 0, 0
    if class == "MAGE" then v1, v60 = 12.9, 20
    elseif class == "ROGUE" then v1, v60 = 2.2, 29
    elseif class == "HUNTER" then v1, v60 = 3.5, 53
    elseif class == "PRIEST" then v1, v60 = 11, 20
    elseif class == "WARLOCK" then v1, v60 = 8.4, 20
    elseif class == "WARRIOR" then v1, v60 = 3.9, 20
    else return 0 end
    local rate = v1 * (60 - level) / 59 + v60 * (level - 1) / 59
    if rate <= 0 then return 0 end
    local crit = agility / rate
    if class == "MAGE" then crit = crit + 3.2
    elseif class == "PRIEST" then crit = crit + 3
    elseif class == "WARLOCK" then crit = crit + 2 end
    local g = CharacterScreen.gear
    local t = CharacterScreen.tal
    local a = CharacterScreen.aur
    if g then crit = crit + (g.rangedCrit or 0) end
    if t then crit = crit + (t.rangedCrit or 0) end
    if a then crit = crit + (a.rangedCrit or 0) end
    -- Modificador de pericia (BCS:SetRangedCritChance).
    local sc = CharacterScreen.skillCache
    local skill = 0
    if sc then skill = sc.ranged or 0 end
    local diff = skill - (level * 5)
    if skill >= (level * 5) then
        crit = crit + (diff * 0.04)
    else
        crit = crit + (diff * 0.2)
    end
    if crit < 0 then crit = 0 end
    return crit
end

-- BCS:GetManaRegen: base espirito/classe + casting% + MP5.
local function CS_ManaRegen()
    local class = CS_PlayerClass()
    local spirit = 0
    if type(UnitStat) == "function" then
        local _, v = UnitStat("player", 5)
        spirit = CS_Num(v, 0)
    end
    local base = 0
    if class == "DRUID" or class == "HUNTER" or class == "PALADIN" or class == "WARLOCK" then
        base = (spirit / 5 + 15)
    elseif class == "MAGE" or class == "PRIEST" then
        base = (spirit / 4 + 12.5)
    elseif class == "SHAMAN" then
        base = (spirit / 5 + 17)
    end
    local g = CharacterScreen.gear
    local t = CharacterScreen.tal
    local a = CharacterScreen.aur
    local casting = 0
    local mp5 = 0
    local regenPct = 0
    if g then
        casting = casting + (g.casting or 0)
        mp5 = mp5 + (g.mp5 or 0)
    end
    if t then casting = casting + (t.casting or 0) end
    if a then
        casting = casting + (a.casting or 0)
        mp5 = mp5 + (a.mp5 or 0)
        regenPct = a.regenPct or 0
    end
    if regenPct > 0 and base > 0 then
        base = base + (base * (regenPct / 100))
    end
    -- Racial humano (BCS:GetManaRegen).
    if type(UnitRace) == "function" then
        local _, raceFile = UnitRace("player")
        if raceFile == "Human" then casting = casting + 5 end
    end
    casting = CS_Clamp(casting, 0, 100)
    return base, casting, mp5
end

-- BCS:GetSpellPower (sem escola): dano+cura, maior escola, nome, dano-only.
local function CS_SpellPower()
    local g = CharacterScreen.gear
    local t = CharacterScreen.tal
    local a = CharacterScreen.aur
    local gearSP, gearOnly = 0, 0
    local arcane, fire, frost, holy, nature, shadow = 0, 0, 0, 0, 0, 0
    if g then
        gearSP = g.sp or 0
        gearOnly = g.spOnly or 0
        arcane = g.arcane or 0
        fire = g.fire or 0
        frost = g.frost or 0
        holy = g.holy or 0
        nature = g.nature or 0
        shadow = g.shadow or 0
    end
    local talSP = 0
    if t and (t.spiritPct or 0) > 0 then
        local spirit = 0
        if type(UnitStat) == "function" then
            local _, v = UnitStat("player", 5)
            spirit = CS_Num(v, 0)
        end
        talSP = math.floor(((t.spiritPct or 0) / 100) * spirit)
    end
    local aurSP, aurOnly = 0, 0
    if a then
        aurSP = a.sp or 0
        aurOnly = a.spOnly or 0
    end
    local damageAndHealing = gearSP + talSP + aurSP
    local damageOnly = gearOnly + aurOnly
    local secondary = 0
    local secondaryName = ""
    if arcane > secondary then secondary, secondaryName = arcane, "Arcano" end
    if fire > secondary then secondary, secondaryName = fire, "Fogo" end
    if frost > secondary then secondary, secondaryName = frost, "Gelo" end
    if holy > secondary then secondary, secondaryName = holy, "Sagrado" end
    if nature > secondary then secondary, secondaryName = nature, "Natureza" end
    if shadow > secondary then secondary, secondaryName = shadow, "Sombra" end
    return damageAndHealing, secondary, secondaryName, damageOnly
end

-- Poder por escola (BCS:SetSpellPower(statFrame, school)):
-- total = generico + dano-only + bonus da escola.
local function CS_SchoolPower(key)
    local base, _, _, dmgOnly = CS_SpellPower()
    local fromSchool = 0
    local g = CharacterScreen.gear
    if g and type(key) == "string" then fromSchool = g[key] or 0 end
    return (base or 0) + (dmgOnly or 0) + (fromSchool or 0), (fromSchool or 0)
end

-- BCS:GetHealingPower (simplificado honesto): cura-only gear + generico +
-- Ironclad; Tree of Life de grupo omitido (exige party scan — ver nota).
local function CS_HealingTotal()
    local damageAndHealing = CS_SpellPower()
    damageAndHealing = CS_Num(damageAndHealing, 0)
    local g = CharacterScreen.gear
    local t = CharacterScreen.tal
    local a = CharacterScreen.aur
    local healOnly = 0
    if g then healOnly = healOnly + (g.heal or 0) end
    if a then healOnly = healOnly + (a.heal or 0) end
    local ironcladBonus = 0
    if t and (t.ironclad or 0) > 0 then
        local armorBase = 0
        if type(UnitArmor) == "function" then
            local ok, b = pcall(UnitArmor, "player")
            if ok then armorBase = CS_Num(b, 0) end
        end
        local agility = 0
        if type(UnitStat) == "function" then
            local _, v = UnitStat("player", 2)
            agility = CS_Num(v, 0)
        end
        local armorFromGear = armorBase - (agility * 2)
        if armorFromGear < 0 then armorFromGear = 0 end
        ironcladBonus = math.floor(((t.ironclad or 0) / 100) * armorFromGear)
    end
    return damageAndHealing + healOnly + ironcladBonus, healOnly, ironcladBonus
end

-- BCS:GetHaste (subconjunto honesto: gear + racial + auras/talentos scan).
local function CS_Haste()
    local g = CharacterScreen.gear
    local t = CharacterScreen.tal
    local a = CharacterScreen.aur
    local haste, spellHaste = 0, 0
    if type(UnitRace) == "function" then
        local _, raceFile = UnitRace("player")
        if raceFile == "NightElf" then haste = haste + 1 end
    end
    if g then
        haste = haste + (g.haste or 0)
        spellHaste = spellHaste + (g.spellHaste or 0)
    end
    if t then spellHaste = spellHaste + (t.spellHaste or 0) end
    if a then
        haste = haste + (a.haste or 0)
        spellHaste = spellHaste + (a.spellHaste or 0)
    end
    return haste, spellHaste
end

-- BCS:GetEffectiveDodgeChance/Parry/BlockChance (leveldiff 0 ou 3).
local function CS_EffDodge(leveldiff)
    local d = nil
    if type(GetDodgeChance) == "function" then
        local ok, v = pcall(GetDodgeChance)
        if ok and type(v) == "number" then d = v end
    end
    if type(d) ~= "number" then return nil end
    d = d - ((5 * CS_Num(leveldiff, 0)) * 0.04)
    if d < 0 then d = 0 end
    return d
end

local function CS_EffParry(leveldiff)
    local p = nil
    if type(GetParryChance) == "function" then
        local ok, v = pcall(GetParryChance)
        if ok and type(v) == "number" then p = v end
    end
    if type(p) ~= "number" then return nil end
    p = p - ((5 * CS_Num(leveldiff, 0)) * 0.04)
    if p < 0 then p = 0 end
    return p
end

local function CS_EffBlock(leveldiff)
    local b = nil
    if type(GetBlockChance) == "function" then
        local ok, v = pcall(GetBlockChance)
        if ok and type(v) == "number" then b = v end
    end
    if type(b) ~= "number" then return nil end
    b = b - ((5 * CS_Num(leveldiff, 0)) * 0.04)
    if b < 0 then b = 0 end
    return b
end

-- BCS:SetTotalAvoidance: miss 5 + skillDiff*0.04 + block + parry + dodge.
local function CS_TotalAvoidance(leveldiff)
    local ld = CS_Num(leveldiff, 0)
    local base, mod = nil, nil
    if type(UnitDefense) == "function" then
        local ok, a, b = pcall(UnitDefense, "player")
        if ok then base, mod = a, b end
    end
    if type(base) ~= "number" then return nil end
    local skillDiff = (base + CS_Num(mod, 0)) - (300 + (ld * 5))
    local missChance = 5 + (skillDiff * 0.04)
    local block = CS_EffBlock(ld) or 0
    local parry = CS_EffParry(ld) or 0
    local dodge = CS_EffDodge(ld) or 0
    local total = missChance + block + parry + dodge
    if total < 0 then total = 0 end
    return total
end

-- Reducao de armadura (BCS:SetArmor): effArmor/((85*nivel)+400).
local function CS_ArmorReduction(effArmor, level)
    effArmor = CS_Num(effArmor, 0)
    level = CS_Num(level, 1)
    if level <= 0 then level = 1 end
    local ar = effArmor / ((85 * level) + 400)
    return 100 * (ar / (ar + 1))
end

-- Altura visivel real do ScrollFrame (com fallback quando o layout 1.12
-- ainda nao calculou as dimensoes no primeiro frame).
function CharacterScreen:GetViewHeight()
    local vh = self.viewH or 0
    if self.scrollFrame and type(self.scrollFrame.GetHeight) == "function" then
        local h = self.scrollFrame:GetHeight()
        if type(h) == "number" and h > 0 then
            vh = h
        end
    end
    if not vh or vh <= 0 then
        vh = 380
    end
    self.viewH = vh
    return vh
end

function CharacterScreen:GetMaxScroll()
    local viewH = self:GetViewHeight()
    local maxScroll = (self.contentH or 0) - viewH
    if not maxScroll or maxScroll < 0 then
        maxScroll = 0
    end
    return maxScroll
end

-- Sincroniza a largura do ScrollChild com a largura real do ScrollFrame.
-- (Padrao que funciona em MainMenu.lua: zlContent/sc/GameMenu sc usam
-- SetWidth explicito — 222/460/536. So com TOPLEFT+TOPRIGHT o ScrollChild
-- 1.12 colapsa para largura 0 no primeiro frame e os blocos somem.)
function CharacterScreen:UpdateLayout()
    if not self.scrollFrame or not self.scrollChild then return end
    local w = 0
    if type(self.scrollFrame.GetWidth) == "function" then
        local sw = self.scrollFrame:GetWidth()
        if type(sw) == "number" and sw > 0 then w = sw end
    end
    if w <= 0 and self.parentFrame and type(self.parentFrame.GetWidth) == "function" then
        local pw = self.parentFrame:GetWidth()
        if type(pw) == "number" and pw > 16 then w = pw - 16 end
    end
    if w <= 0 then w = 460 end
    self.scrollChild:SetWidth(w)
    if self.contentH and self.contentH > 0 then
        self.scrollChild:SetHeight(self.contentH)
    end
end

-- Defer 0.05s via OnUpdate (mesmo padrao do MainMenu BAGS/SPELLS):
-- o layout 1.12 ainda nao calculou as dimensoes no primeiro frame.
function CharacterScreen:ScheduleLayoutRefresh()
    if not self.scrollFrame then return end
    if self._layoutRetry then
        self._layoutRetry.t = 0
        if type(self._layoutRetry.Show) == "function" then
            self._layoutRetry:Show()
        end
        return
    end
    local f = CreateFrame("Frame", nil, self.scrollFrame)
    f.t = 0
    f:SetScript("OnUpdate", function()
        this.t = this.t + arg1
        if this.t >= 0.05 then
            this:SetScript("OnUpdate", nil)
            this:Hide()
            CharacterScreen:UpdateLayout()
            if CharacterScreen.isVisible and CharacterScreen.scrollFrame then
                CharacterScreen.scrollFrame:Show()
                if type(CharacterScreen.scrollFrame.SetVerticalScroll) == "function" then
                    CharacterScreen.scrollFrame:SetVerticalScroll(CharacterScreen.scrollOffset or 0)
                end
            end
        end
    end)
    self._layoutRetry = f
end

-- ----------------------------------------------------------------------------
-- 3. CRIACAO DA UI (pool fixo: executar uma unica vez)
-- ----------------------------------------------------------------------------

-- Cria um card com titulo ambar + N linhas de texto. Pool fixo: chamado
-- apenas dentro de CreateUI; Refresh() so atualiza os FontStrings.
local function CS_MakeCard(scrollChild, name, titleText, height, numLines)
    local card = CreateFrame("Frame", name, scrollChild)
    card:SetHeight(height)
    -- Guards 1.12: sem backdrop o card ainda aparece (degradacao graciosa
    -- em vez de abortar o CreateUI inteiro e travar no placeholder).
    if type(card.SetBackdrop) == "function" then
        card:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 12,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 },
        })
    end
    if type(card.SetBackdropColor) == "function" then
        card:SetBackdropColor(COLORS.blockBg.r, COLORS.blockBg.g, COLORS.blockBg.b, COLORS.blockBg.a)
    end
    if type(card.SetBackdropBorderColor) == "function" then
        card:SetBackdropBorderColor(COLORS.blockBorder.r, COLORS.blockBorder.g, COLORS.blockBorder.b, COLORS.blockBorder.a)
    end

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
    title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -10)
    title:SetJustifyH("LEFT")
    CS_ApplyFont(title, FONTS.titleBold, 16)
    title:SetText(COLORS.amberText .. tostring(titleText) .. "|r")
    card.title = title

    card.lines = {}
    for i = 1, numLines do
        local y = -(30 + ((i - 1) * 20))
        local fs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", card, "TOPLEFT", 12, y)
        fs:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, y)
        fs:SetJustifyH("LEFT")
        CS_ApplyFont(fs, FONTS.medium, 13)
        if type(fs.SetTextColor) == "function" then
            fs:SetTextColor(COLORS.body.r, COLORS.body.g, COLORS.body.b)
        end
        fs:SetText("...")
        table.insert(card.lines, fs)
    end

    card.cardH = height
    card:Show()
    return card
end

-- Empilha os cards visiveis (Ranged oculto p/ relic classes), recalcula
-- contentH = soma das alturas + gaps + padding. Pool fixo: so reposiciona.
function CharacterScreen:LayoutCards()
    if not self.cardOrder or not self.scrollChild then return end
    local gap = self.cardGap or 12
    local yOff = -4
    local first = true
    local totalH = 0
    local n = table.getn(self.cardOrder)
    for i = 1, n do
        local card = self.cardOrder[i]
        if card then
            local show = true
            if card == self.cardRanged and CS_HasRelicSlot() then
                show = false
            end
            if show then
                if type(card.Show) == "function" then card:Show() end
                card:ClearAllPoints()
                card:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 4, yOff)
                card:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", -4, yOff)
                local h = card.cardH or 170
                yOff = yOff - h - gap
                if first then
                    totalH = h
                    first = false
                else
                    totalH = totalH + gap + h
                end
            else
                if type(card.Hide) == "function" then card:Hide() end
            end
        end
    end
    totalH = totalH + 8
    self.contentH = totalH
    if type(self.scrollChild.SetHeight) == "function" then
        self.scrollChild:SetHeight(totalH)
    end
end

function CharacterScreen:CreateUI(parent)
    if self.scrollFrame then return end
    if not parent then return end

    -- Esconde o placeholder temporario da FASE 1 ("Modulo em Carregamento").
    CS_HidePlaceholder(parent)

    -- SEM EnsureScanTip aqui (lazy-init): o tooltip dedicado de scan e
    -- criado sob demanda no primeiro Refresh (cada CS_Scan* chama
    -- EnsureScanTip). Assim a UI (cards + hide do placeholder) nunca
    -- depende da criacao da GameTooltip dedicada.
    local scrollFrame = CreateFrame("ScrollFrame", "ConsoleMode_CharacterScrollFrame", parent)
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
    if type(scrollFrame.EnableMouse) == "function" then
        scrollFrame:EnableMouse(true)
    end
    if type(scrollFrame.EnableMouseWheel) == "function" then
        scrollFrame:EnableMouseWheel(true)
    end

    local scrollChild = CreateFrame("Frame", "ConsoleMode_CharacterScrollChild", scrollFrame)
    scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
    -- Largura explicita (padrao MainMenu 1.12): sem isto o child colapsa
    -- para 0px no primeiro frame e os cards ficam invisiveis.
    local parentW = 0
    if type(parent.GetWidth) == "function" then
        local pw = parent:GetWidth()
        if type(pw) == "number" and pw > 16 then parentW = pw - 16 end
    end
    if parentW <= 0 then parentW = 460 end
    scrollChild:SetWidth(parentW)
    scrollChild:SetHeight(400)
    scrollFrame:SetScrollChild(scrollChild)
    -- SetVerticalScroll so DEPOIS do SetScrollChild (offset 0 garantido).
    self.scrollOffset = 0
    if type(scrollFrame.SetVerticalScroll) == "function" then
        scrollFrame:SetVerticalScroll(0)
    end

    -- FASE 4: 11 cards BCS (6 linhas por categoria BCS) + Identidade (6),
    -- Recursos (4) e Resistencias (5). Pool fixo: criados uma vez aqui.
    self.cardIdent     = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardIdent", "IDENTIDADE & BIOGRAFIA", 200, 6)
    self.cardBase      = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardBase", "ATRIBUTOS PRIMARIOS (BASE STATS)", 190, 6)
    self.cardRes       = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardRes", "RECURSOS & REGENERACAO", 150, 4)
    self.cardMelee     = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardMelee", "COMBATE CORPO A CORPO (MELEE)", 190, 6)
    self.cardMeleeBoss = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardMeleeBoss", "MELEE VS BOSS (NIVEL 63)", 190, 6)
    self.cardRanged    = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardRanged", "COMBATE A DISTANCIA (RANGED)", 190, 6)
    self.cardSpell     = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardSpell", "PODER MAGICO (SPELL)", 190, 6)
    self.cardSchools   = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardSchools", "ESCOLAS DE MAGIA (SCHOOLS)", 190, 6)
    self.cardDef       = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardDef", "DEFESA & SOBREVIVENCIA", 190, 6)
    self.cardDefBoss   = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardDefBoss", "DEFESA VS BOSS (NIVEL 63)", 190, 6)
    self.cardResist    = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCardResist", "RESISTENCIAS ELEMENTAIS", 170, 5)

    self.cardOrder = {
        self.cardIdent, self.cardBase, self.cardRes,
        self.cardMelee, self.cardMeleeBoss, self.cardRanged,
        self.cardSpell, self.cardSchools,
        self.cardDef, self.cardDefBoss, self.cardResist,
    }

    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild
    self:LayoutCards()

    -- Roda do mouse (companheiro de mesa; o D-Pad continua sendo o principal).
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1 or 0
        if delta > 0 then
            CharacterScreen:Scroll(-CharacterScreen.scrollStep)
        elseif delta < 0 then
            CharacterScreen:Scroll(CharacterScreen.scrollStep)
        end
    end)

    scrollFrame:Hide()

    self:EnsureEventFrame()
    self:Refresh()
end

-- ----------------------------------------------------------------------------
-- 3b. REFRESH (consome flags sujas -> scan; atualiza FontStrings do pool)
-- ----------------------------------------------------------------------------

-- Consome as flags de scan (padrao BCS needScanGear/needScanTalents/
-- needScanAuras/needScanSkills): Refresh usa cache, nunca escaneia direto.
local function CS_ConsumeScans()
    if CharacterScreen.scanGearDirty then
        CharacterScreen.scanGearDirty = false
        CS_ScanGear()
    end
    if CharacterScreen.scanTalentsDirty then
        CharacterScreen.scanTalentsDirty = false
        CS_ScanTalents()
    end
    if CharacterScreen.scanAurasDirty then
        CharacterScreen.scanAurasDirty = false
        CS_ScanAuras()
    end
    if CharacterScreen.scanSkillsDirty then
        CharacterScreen.scanSkillsDirty = false
        CS_ScanSkills()
    end
end

-- ----------------------------------------------------------------------------
-- 3a. TABELA UNICA DE HELPERS (Lua 5.0: 1 upvalue em vez de N).
-- Cada Refresh* referencia apenas H (+ self), nunca os locals CS_* diretos.
-- ----------------------------------------------------------------------------
local H = {
    ConsumeScans = CS_ConsumeScans,
    Num = CS_Num,
    Fmt1 = CS_Fmt1,
    Fmt2 = CS_Fmt2,
    DPS = CS_DPS,
    ResistBar = CS_ResistBar,
    ClassColorHex = CS_ClassColorHex,
    PlayerClass = CS_PlayerClass,
    OffhandHasWeapon = CS_OffhandHasWeapon,
    DetectTurtleMode = CS_DetectTurtleMode,
    MissChance = CS_MissChance,
    DualWieldMissChance = CS_DualWieldMissChance,
    GlanceReduction = CS_GlanceReduction,
    BossDodgeChance = CS_BossDodgeChance,
    CritCap = CS_CritCap,
    DualWieldCritCap = CS_DualWieldCritCap,
    MeleeHit = CS_MeleeHit,
    RangedHit = CS_RangedHit,
    SpellHit = CS_SpellHit,
    SpellCritBase = CS_SpellCritBase,
    RangedCrit = CS_RangedCrit,
    ManaRegen = CS_ManaRegen,
    SpellPower = CS_SpellPower,
    SchoolPower = CS_SchoolPower,
    HealingTotal = CS_HealingTotal,
    Haste = CS_Haste,
    EffDodge = CS_EffDodge,
    EffParry = CS_EffParry,
    EffBlock = CS_EffBlock,
    TotalAvoidance = CS_TotalAvoidance,
    ArmorReduction = CS_ArmorReduction,
    Colors = COLORS,
    StatNames = STAT_NAMES,
    SchoolNames = SCHOOL_NAMES,
    SchoolKeys = SCHOOL_KEYS,
}

local function CS_RefreshIdent(self)
-- CARD 1: Identidade & Biografia.
    local c1 = self.cardIdent
    if c1 and c1.lines and table.getn(c1.lines) >= 6 then
        local name = "?"
        if type(UnitName) == "function" then
            name = UnitName("player") or "?"
        end
        local level = 0
        if type(UnitLevel) == "function" then
            level = UnitLevel("player") or 0
        end
        local race = "?"
        if type(UnitRace) == "function" then
            race = UnitRace("player") or "?"
        end
        local classLoc = "?"
        local classFile = ""
        if type(UnitClass) == "function" then
            local a, b = UnitClass("player")
            if a and a ~= "" then classLoc = a end
            if b and b ~= "" then classFile = b end
        end
        local classHex = H.ClassColorHex(classFile)

        local gname = nil
        local grank = nil
        if type(GetGuildInfo) == "function" then
            local ok, a, b = pcall(GetGuildInfo, "player")
            if ok then
                gname = a
                grank = b
            end
        end

        local prank = 0
        if type(UnitPVPRank) == "function" then
            prank = UnitPVPRank("player") or 0
        end
        local prankName = "Sem posto"
        if prank and prank > 0 and type(GetPVPRankInfo) == "function" then
            local ok, n = pcall(GetPVPRankInfo, prank)
            if ok and type(n) == "string" and n ~= "" then
                prankName = n
            end
        end

        local curXP = 0
        if type(UnitXP) == "function" then
            curXP = UnitXP("player") or 0
        end
        local maxXP = 0
        if type(UnitXPMax) == "function" then
            maxXP = UnitXPMax("player") or 0
        end
        local pct = 0
        if maxXP and maxXP > 0 then
            pct = math.floor((curXP / maxXP) * 100)
        end
        local rest = 0
        if type(GetXPExhaustion) == "function" then
            rest = GetXPExhaustion() or 0
        end
        if type(rest) ~= "number" then rest = 0 end

        local modeText = H.DetectTurtleMode()

        c1.lines[1]:SetText("|cffffffff" .. tostring(name) .. "|r  Niv " .. tostring(H.Num(level, 0)))
        c1.lines[2]:SetText(tostring(race) .. "  " .. classHex .. tostring(classLoc) .. "|r")
        if gname and gname ~= "" then
            c1.lines[3]:SetText("Guilda: " .. tostring(gname) .. " (" .. tostring(grank or "?") .. ")")
        else
            c1.lines[3]:SetText("Guilda: Sem guilda")
        end
        if prank and prank > 0 then
            c1.lines[4]:SetText("Posto: " .. tostring(prankName) .. " (Rank " .. tostring(prank) .. ")")
        else
            c1.lines[4]:SetText("Posto: Sem posto")
        end
        if rest > 0 then
            c1.lines[5]:SetText("XP: " .. tostring(curXP) .. "/" .. tostring(maxXP)
                .. " (" .. tostring(pct) .. "%)  Descansado")
        else
            c1.lines[5]:SetText("XP: " .. tostring(curXP) .. "/" .. tostring(maxXP)
                .. " (" .. tostring(pct) .. "%)")
        end
        c1.lines[6]:SetText(tostring(modeText))
    end
end

local function CS_RefreshBase(self)
-- CARD 2: Base Stats BCS (UnitStat 1..5 com bonus) + Armadura (UnitArmor).
    local c2 = self.cardBase
    if c2 and c2.lines and table.getn(c2.lines) >= 6 then
        for i = 1, 5 do
            local a, b, c, d = nil, nil, nil, nil
            if type(UnitStat) == "function" then
                a, b, c, d = UnitStat("player", i)
            end
            local eff = H.Num(b, H.Num(a, 0))
            local pos = H.Num(c, 0)
            local neg = H.Num(d, 0)
            local txt = tostring(H.StatNames[i]) .. ": " .. tostring(eff)
            if pos > 0 then
                txt = txt .. " " .. H.Colors.bonusGreen .. "(+" .. tostring(pos) .. ")|r"
            elseif neg > 0 then
                txt = txt .. " " .. H.Colors.penaltyRed .. "(-" .. tostring(neg) .. ")|r"
            end
            c2.lines[i]:SetText(txt)
        end
        local abase, aeff, aarmor, abonus = nil, nil, nil, nil
        if type(UnitArmor) == "function" then
            local ok, a, b, c, d = pcall(UnitArmor, "player")
            if ok then
                abase, aeff, aarmor, abonus = a, b, c, d
            end
        end
        local effArmor = H.Num(aeff, H.Num(aarmor, H.Num(abase, 0)))
        local bonusArmor = H.Num(abonus, 0)
        local armorTxt = "Armadura: " .. tostring(effArmor)
        if bonusArmor > 0 then
            armorTxt = armorTxt .. " " .. H.Colors.bonusGreen .. "(+" .. tostring(bonusArmor) .. ")|r"
        end
        c2.lines[6]:SetText(armorTxt)
    end
end

local function CS_RefreshRes(self)
-- CARD 3: Recursos & Regeneracao. Regen de mana CALCULADA (mesma tecnica
    -- do card Spell); regen de vida sem formula confiavel: "—" honesto
    -- (BCS:GetHPRegen e um stub vazio no proprio BCS).
    local c3 = self.cardRes
    if c3 and c3.lines and table.getn(c3.lines) >= 4 then
        local hp = 0
        if type(UnitHealth) == "function" then
            hp = UnitHealth("player") or 0
        end
        local hpMax = 0
        if type(UnitHealthMax) == "function" then
            hpMax = UnitHealthMax("player") or 0
        end
        local mp = 0
        if type(UnitMana) == "function" then
            mp = UnitMana("player") or 0
        end
        local mpMax = 0
        if type(UnitManaMax) == "function" then
            mpMax = UnitManaMax("player") or 0
        end
        local ptype = 0
        if type(UnitPowerType) == "function" then
            ptype = UnitPowerType("player") or 0
        end
        local pname = "Mana"
        if ptype == 1 then
            pname = "Furia"
        elseif ptype == 3 then
            pname = "Energia"
        end
        c3.lines[1]:SetText("Vida: " .. tostring(hp) .. " / " .. tostring(hpMax))
        c3.lines[2]:SetText(tostring(pname) .. ": " .. tostring(mp) .. " / " .. tostring(mpMax))
        c3.lines[3]:SetText("Regen. Vida: — (sem formula na 1.12)")
        if ptype == 0 then
            local base, casting, mp5 = H.ManaRegen()
            local mp2 = (mp5 or 0) * 0.4
            local totalRegen = (base or 0) + mp2
            local whileCasting = ((casting or 0) / 100) * (base or 0) + mp2
            if math.floor(whileCasting) ~= math.floor(totalRegen) then
                c3.lines[4]:SetText("Regen. Mana: " .. string.format("%d (%d MP2 em combate)", totalRegen, whileCasting))
            else
                c3.lines[4]:SetText("Regen. Mana: " .. string.format("%d MP2", totalRegen))
            end
        else
            c3.lines[4]:SetText("Regen. " .. tostring(pname) .. ": — (sem formula na 1.12)")
        end
    end
end

local function CS_RefreshMelee(self)
-- CARD 4: Melee BCS (SetWeaponSkill/SetDamage/SetAttackSpeed/
    -- SetAttackPower/SetHitRating MELEE/SetMeleeCritChance).
    -- Critico melee usa GetCritChance NATIVO (PaperDoll 1.12). Desvio
    -- consciente do BCS: BCS:GetCritChance() varre o spellbook atras de
    -- "chance to crit" (nao reflete crit melee do PaperDoll); o nativo e
    -- o valor correto e testavel lado a lado.
    local c4 = self.cardMelee
    if c4 and c4.lines and table.getn(c4.lines) >= 6 then
        local sc = self.skillCache
        local mhSkill, ohSkill = 0, 0
        if sc then mhSkill, ohSkill = sc.mh or 0, sc.oh or 0 end
        if H.OffhandHasWeapon() then
            c4.lines[1]:SetText("Pericia de Arma: " .. tostring(mhSkill) .. " | " .. tostring(ohSkill))
        else
            c4.lines[1]:SetText("Pericia de Arma: " .. tostring(mhSkill))
        end

        local dMin, dMax, dOffMin, dOffMax = nil, nil, nil, nil
        if type(UnitDamage) == "function" then
            local ok, a, b, c, d = pcall(UnitDamage, "player")
            if ok then
                dMin, dMax, dOffMin, dOffMax = a, b, c, d
            end
        end
        local sMain, sOff = nil, nil
        if type(UnitAttackSpeed) == "function" then
            local ok, a, b = pcall(UnitAttackSpeed, "player")
            if ok then
                sMain, sOff = a, b
            end
        end
        -- BCS:AddDamageTooltip (BetterCharacterStats.lua:311-312): a Blizzard
        -- exibe inteiros (PaperDoll trunca com %d; BCS: floor/ceil). DPS usa
        -- os valores crus (floats) com 1 casa — ver H.DPS.
        c4.lines[2]:SetText("Dano: " .. tostring(math.floor(H.Num(dMin, 0))) .. "-" .. tostring(math.floor(H.Num(dMax, 0)))
            .. "  DPS: " .. H.DPS(dMin, dMax, sMain))
        c4.lines[3]:SetText("Velocidade: " .. H.Fmt2(sMain) .. "s")

        local apBase, apPos, apNeg = nil, nil, nil
        if type(UnitAttackPower) == "function" then
            local ok, a, b, c = pcall(UnitAttackPower, "player")
            if ok then
                apBase, apPos, apNeg = a, b, c
            end
        end
        local apEff = H.Num(apBase, 0) + H.Num(apPos, 0) + H.Num(apNeg, 0)
        local apTxt = "Poder de Ataque: " .. tostring(apEff)
        if H.Num(apPos, 0) > 0 then
            apTxt = apTxt .. " " .. H.Colors.bonusGreen .. "(+" .. tostring(H.Num(apPos, 0)) .. ")|r"
        elseif H.Num(apNeg, 0) < 0 then
            apTxt = apTxt .. " " .. H.Colors.penaltyRed .. "(" .. tostring(H.Num(apNeg, 0)) .. ")|r"
        end
        c4.lines[4]:SetText(apTxt)

        c4.lines[5]:SetText("Acerto (Hit): +" .. H.Fmt1(H.MeleeHit()) .. "%")

        local crit = nil
        if type(GetCritChance) == "function" then
            local ok, v = pcall(GetCritChance)
            if ok and type(v) == "number" then crit = v end
        end
        if type(crit) == "number" then
            c4.lines[6]:SetText("Critico: " .. H.Fmt1(crit) .. "%")
        else
            c4.lines[6]:SetText("Critico: —")
        end
    end
end

local function CS_RefreshMeleeBoss(self)
-- CARD 5: Melee vs Boss BCS (alvo nivel 63: pericia, Miss, Dodge,
    -- Glancing, Crit Cap, Critico Efetivo = min(crit-3, cap)).
    local c5 = self.cardMeleeBoss
    if c5 and c5.lines and table.getn(c5.lines) >= 6 then
        local sc = self.skillCache
        local mhSkill, ohSkill = 0, 0
        if sc then mhSkill, ohSkill = sc.mh or 0, sc.oh or 0 end
        local dual = H.OffhandHasWeapon()
        if dual then
            c5.lines[1]:SetText("Pericia de Arma: " .. tostring(mhSkill) .. " | " .. tostring(ohSkill))
        else
            c5.lines[1]:SetText("Pericia de Arma: " .. tostring(mhSkill))
        end
        if dual then
            c5.lines[2]:SetText("Miss vs Boss: " .. H.Fmt1(H.DualWieldMissChance(mhSkill))
                .. "% | " .. H.Fmt1(H.DualWieldMissChance(ohSkill)) .. "%")
            c5.lines[3]:SetText("Dodge vs Boss: " .. H.Fmt1(H.BossDodgeChance(mhSkill))
                .. "% | " .. H.Fmt1(H.BossDodgeChance(ohSkill)) .. "%")
            c5.lines[4]:SetText("Glancing: " .. H.Fmt1(H.GlanceReduction(mhSkill))
                .. "% | " .. H.Fmt1(H.GlanceReduction(ohSkill)) .. "%")
            c5.lines[5]:SetText("Crit Cap: " .. H.Fmt1(H.DualWieldCritCap(mhSkill))
                .. "% | " .. H.Fmt1(H.DualWieldCritCap(ohSkill)) .. "%")
        else
            c5.lines[2]:SetText("Miss vs Boss: " .. H.Fmt1(H.MissChance(mhSkill)) .. "%")
            c5.lines[3]:SetText("Dodge vs Boss: " .. H.Fmt1(H.BossDodgeChance(mhSkill)) .. "%")
            c5.lines[4]:SetText("Glancing: " .. H.Fmt1(H.GlanceReduction(mhSkill)) .. "%")
            c5.lines[5]:SetText("Crit Cap: " .. H.Fmt1(H.CritCap(mhSkill)) .. "%")
        end
        local crit = nil
        if type(GetCritChance) == "function" then
            local ok, v = pcall(GetCritChance)
            if ok and type(v) == "number" then crit = v end
        end
        if type(crit) == "number" then
            local effCrit = crit - 3
            if dual then
                local a = effCrit
                if a > H.DualWieldCritCap(mhSkill) then a = H.DualWieldCritCap(mhSkill) end
                local b = effCrit
                if b > H.DualWieldCritCap(ohSkill) then b = H.DualWieldCritCap(ohSkill) end
                c5.lines[6]:SetText("Critico Efetivo: " .. H.Fmt1(a) .. "% | " .. H.Fmt1(b) .. "%")
            else
                local cap = H.CritCap(mhSkill)
                if effCrit > cap then effCrit = cap end
                c5.lines[6]:SetText("Critico Efetivo: " .. H.Fmt1(effCrit) .. "%")
            end
        else
            c5.lines[6]:SetText("Critico Efetivo: —")
        end
    end
end

local function CS_RefreshRanged(self)
-- CARD 6: Ranged BCS (oculto p/ relic classes — mesma regra BCS).
    -- Varinha (HasWandEquipped): RAP "--" (regra BCS:SetRangedAttackPower).
    local c6 = self.cardRanged
    if c6 and c6.lines and table.getn(c6.lines) >= 6 then
        local sc = self.skillCache
        local rSkill = 0
        if sc then rSkill = sc.ranged or 0 end
        c6.lines[1]:SetText("Pericia Ranged: " .. tostring(rSkill))

        local rMin, rMax, rSpeedFromDmg = nil, nil, nil
        if type(UnitRangedDamage) == "function" then
            local ok, a, b, c = pcall(UnitRangedDamage, "player")
            if ok then
                if type(c) == "number" and type(a) == "number" and type(b) == "number" then
                    rSpeedFromDmg, rMin, rMax = a, b, c
                elseif type(a) == "number" and type(b) == "number" then
                    rMin, rMax = a, b
                end
            end
        end
        local rSpeed = rSpeedFromDmg
        if type(UnitRangedAttackSpeed) == "function" then
            local ok, v = pcall(UnitRangedAttackSpeed, "player")
            if ok and type(v) == "number" then rSpeed = v end
        end
        if type(rMin) == "number" and type(rMax) == "number" then
            -- Mesmo padrao do Melee/BCS: inteiros via floor, DPS com 1 casa.
            c6.lines[2]:SetText("Dano: " .. tostring(math.floor(H.Num(rMin, 0))) .. "-" .. tostring(math.floor(H.Num(rMax, 0)))
                .. "  DPS: " .. H.DPS(rMin, rMax, rSpeed))
        else
            c6.lines[2]:SetText("Dano: — (sem arma de longo alcance)")
        end
        if type(rSpeed) == "number" then
            c6.lines[3]:SetText("Velocidade: " .. H.Fmt2(rSpeed) .. "s")
        else
            c6.lines[3]:SetText("Velocidade: —")
        end

        local isWand = false
        if type(HasWandEquipped) == "function" then
            local ok, v = pcall(HasWandEquipped)
            if ok and v then isWand = true end
        end
        if isWand then
            c6.lines[4]:SetText("Poder de Ataque (dist.): --")
        else
            local rapBase, rapPos, rapNeg = nil, nil, nil
            if type(UnitRangedAttackPower) == "function" then
                local ok, a, b, c = pcall(UnitRangedAttackPower, "player")
                if ok then
                    rapBase, rapPos, rapNeg = a, b, c
                end
            end
            local rapEff = H.Num(rapBase, 0) + H.Num(rapPos, 0) + H.Num(rapNeg, 0)
            c6.lines[4]:SetText("Poder de Ataque (dist.): " .. tostring(rapEff))
        end

        c6.lines[5]:SetText("Acerto (Hit): +" .. H.Fmt1(H.RangedHit()) .. "%")
        c6.lines[6]:SetText("Critico (dist.): " .. H.Fmt1(H.RangedCrit()) .. "%")
    end
end

local function CS_RefreshSpell(self)
-- CARD 7: Spell BCS (SetSpellPower/SetHitRating SPELL/SetSpellCritChance/
    -- SetHealing/SetManaRegen/SetSpellHaste). Haste = gear+racial+auras+
    -- talentos (subconjunto honesto; 0% quando nada equipa).
    local c7 = self.cardSpell
    if c7 and c7.lines and table.getn(c7.lines) >= 6 then
        local dmgHeal, secondary, secName, dmgOnly = H.SpellPower()
        local totalSP = H.Num(dmgHeal, 0) + H.Num(dmgOnly, 0) + H.Num(secondary, 0)
        local spTxt = "Spell Power: +" .. tostring(totalSP)
        if H.Num(secondary, 0) > 0 then
            spTxt = spTxt .. " (" .. tostring(secName) .. ")"
        end
        c7.lines[1]:SetText(spTxt)

        local sHit = H.SpellHit()
        c7.lines[2]:SetText("Hit Magico: +" .. H.Fmt1(sHit) .. "%")
        c7.lines[3]:SetText("Critico Magico: " .. H.Fmt1(H.SpellCritBase()) .. "%")

        local healTotal = H.HealingTotal()
        c7.lines[4]:SetText("Poder de Cura (+Heal): +" .. tostring(H.Num(healTotal, 0)))

        local ptype = 0
        if type(UnitPowerType) == "function" then
            ptype = UnitPowerType("player") or 0
        end
        if ptype == 0 or H.PlayerClass() == "DRUID" then
            local base, casting, mp5 = H.ManaRegen()
            local mp2 = (mp5 or 0) * 0.4
            local totalRegen = (base or 0) + mp2
            local whileCasting = ((casting or 0) / 100) * (base or 0) + mp2
            if math.floor(whileCasting) ~= math.floor(totalRegen) then
                c7.lines[5]:SetText("Regen. Mana: " .. string.format("%d (%d em combate)", totalRegen, whileCasting))
            else
                c7.lines[5]:SetText("Regen. Mana: " .. string.format("%d MP2", totalRegen))
            end
        else
            c7.lines[5]:SetText("Regen. Mana: N/A (sem mana)")
        end

        local haste, spellHaste = H.Haste()
        c7.lines[6]:SetText("Spell Haste: " .. tostring(H.Num(haste, 0) + H.Num(spellHaste, 0)) .. "%")
    end
end

local function CS_RefreshSchools(self)
-- CARD 8: Schools BCS (SetSpellPower por escola: generico + dano-only
    -- + bonus da escola; verde quando a escola tem bonus proprio).
    local c8 = self.cardSchools
    if c8 and c8.lines and table.getn(c8.lines) >= 6 then
        for i = 1, 6 do
            local total, fromSchool = H.SchoolPower(H.SchoolKeys[i])
            local txt = tostring(H.SchoolNames[i]) .. ": +" .. tostring(H.Num(total, 0))
            if H.Num(fromSchool, 0) > 0 then
                txt = H.Colors.bonusGreen .. txt .. "|r"
            end
            c8.lines[i]:SetText(txt)
        end
    end
end

local function CS_RefreshDef(self)
-- CARD 9: Defenses BCS leveldiff 0 (SetArmor/SetDefense/SetDodge/
    -- SetParry/SetBlock/SetTotalAvoidance). Armadura mostra a reducao %
    -- (formula BCS:SetArmor) em vez de texto "sem formula".
    local c9 = self.cardDef
    if c9 and c9.lines and table.getn(c9.lines) >= 6 then
        local dbase, deff, darmor, dbonus = nil, nil, nil, nil
        if type(UnitArmor) == "function" then
            local ok, a, b, c, d = pcall(UnitArmor, "player")
            if ok then
                dbase, deff, darmor, dbonus = a, b, c, d
            end
        end
        local effArmor = H.Num(deff, H.Num(darmor, H.Num(dbase, 0)))
        local level = 0
        if type(UnitLevel) == "function" then level = UnitLevel("player") or 0 end
        local red = H.ArmorReduction(effArmor, level)
        c9.lines[1]:SetText("Armadura: " .. tostring(effArmor)
            .. " (" .. H.Fmt1(red) .. "% vs niv " .. tostring(H.Num(level, 0)) .. ")")

        local defCur, defMax = nil, nil
        if type(UnitDefense) == "function" then
            local ok, a, b = pcall(UnitDefense, "player")
            if ok then
                defCur, defMax = a, b
            end
        end
        if type(defCur) == "number" then
            c9.lines[2]:SetText("Defesa: " .. tostring(defCur) .. " / " .. tostring(H.Num(defMax, defCur)))
        else
            c9.lines[2]:SetText("Defesa: —")
        end

        local dodge = H.EffDodge(0)
        if type(dodge) == "number" then
            c9.lines[3]:SetText("Esquiva: " .. H.Fmt1(dodge) .. "%")
        else
            c9.lines[3]:SetText("Esquiva: —")
        end
        local parry = H.EffParry(0)
        if type(parry) == "number" then
            c9.lines[4]:SetText("Aparo: " .. H.Fmt1(parry) .. "%")
        else
            c9.lines[4]:SetText("Aparo: —")
        end
        local block = H.EffBlock(0)
        if type(block) == "number" then
            c9.lines[5]:SetText("Bloqueio: " .. H.Fmt1(block) .. "%")
        else
            c9.lines[5]:SetText("Bloqueio: —")
        end
        local total = H.TotalAvoidance(0)
        if type(total) == "number" then
            c9.lines[6]:SetText("Esquiva Total: " .. H.Fmt1(total) .. "%")
        else
            c9.lines[6]:SetText("Esquiva Total: —")
        end
    end
end

local function CS_RefreshDefBoss(self)
-- CARD 10: Defenses vs Boss BCS leveldiff 3 (diferencial +3 niveis).
    local c10 = self.cardDefBoss
    if c10 and c10.lines and table.getn(c10.lines) >= 6 then
        local dbase, deff, darmor = nil, nil, nil
        if type(UnitArmor) == "function" then
            local ok, a, b, c = pcall(UnitArmor, "player")
            if ok then
                dbase, deff, darmor = a, b, c
            end
        end
        local effArmor = H.Num(deff, H.Num(darmor, H.Num(dbase, 0)))
        local red = H.ArmorReduction(effArmor, 63)
        c10.lines[1]:SetText("Armadura: " .. tostring(effArmor)
            .. " (" .. H.Fmt1(red) .. "% vs niv 63)")

        local defCur, defMax = nil, nil
        if type(UnitDefense) == "function" then
            local ok, a, b = pcall(UnitDefense, "player")
            if ok then
                defCur, defMax = a, b
            end
        end
        if type(defCur) == "number" then
            c10.lines[2]:SetText("Defesa: " .. tostring(defCur) .. " / " .. tostring(H.Num(defMax, defCur)))
        else
            c10.lines[2]:SetText("Defesa: —")
        end

        local dodge = H.EffDodge(3)
        if type(dodge) == "number" then
            c10.lines[3]:SetText("Esquiva: " .. H.Fmt1(dodge) .. "%")
        else
            c10.lines[3]:SetText("Esquiva: —")
        end
        local parry = H.EffParry(3)
        if type(parry) == "number" then
            c10.lines[4]:SetText("Aparo: " .. H.Fmt1(parry) .. "%")
        else
            c10.lines[4]:SetText("Aparo: —")
        end
        local block = H.EffBlock(3)
        if type(block) == "number" then
            c10.lines[5]:SetText("Bloqueio: " .. H.Fmt1(block) .. "%")
        else
            c10.lines[5]:SetText("Bloqueio: —")
        end
        local total = H.TotalAvoidance(3)
        if type(total) == "number" then
            c10.lines[6]:SetText("Esquiva Total: " .. H.Fmt1(total) .. "%")
        else
            c10.lines[6]:SetText("Esquiva Total: —")
        end
    end
end

local function CS_RefreshResist(self)
-- CARD 11: Resistencias. UnitResistance("player", 2..6)
    -- (indice 1 = Armadura, pulado). Exibe total + barra textual
    -- proporcional via string.rep; sem criar textures novas.
    local c11 = self.cardResist
    if c11 and c11.lines and table.getn(c11.lines) >= 5 then
        local resNames = { "Fogo", "Natureza", "Gelo", "Sombra", "Arcano" }
        for i = 1, 5 do
            local rid = i + 1
            local rbase, rtotal, rpos, rneg = nil, nil, nil, nil
            if type(UnitResistance) == "function" then
                local ok, a, b, c, d = pcall(UnitResistance, "player", rid)
                if ok then
                    rbase, rtotal, rpos, rneg = a, b, c, d
                end
            end
            local tot = H.Num(rtotal, H.Num(rbase, 0))
            local line = tostring(resNames[i]) .. ": " .. tostring(tot)
                .. " " .. H.ResistBar(tot)
            local pos = H.Num(rpos, 0)
            local neg = H.Num(rneg, 0)
            if pos > 0 then
                line = line .. " " .. H.Colors.bonusGreen .. "(+" .. tostring(pos) .. ")|r"
            elseif neg < 0 then
                line = line .. " " .. H.Colors.penaltyRed .. "(" .. tostring(neg) .. ")|r"
            end
            c11.lines[i]:SetText(line)
        end
    end
end

function CharacterScreen:Refresh()
    if not self.cardOrder then return end
    H.ConsumeScans()
    if self.cardIdent then CS_RefreshIdent(self) end
    if self.cardBase then CS_RefreshBase(self) end
    if self.cardRes then CS_RefreshRes(self) end
    if self.cardMelee then CS_RefreshMelee(self) end
    if self.cardMeleeBoss then CS_RefreshMeleeBoss(self) end
    if self.cardRanged then CS_RefreshRanged(self) end
    if self.cardSpell then CS_RefreshSpell(self) end
    if self.cardSchools then CS_RefreshSchools(self) end
    if self.cardDef then CS_RefreshDef(self) end
    if self.cardDefBoss then CS_RefreshDefBoss(self) end
    if self.cardResist then CS_RefreshResist(self) end
    self:LayoutCards()
end


-- Frame de eventos criado uma unica vez; OnEvent so atualiza se visivel.
-- Flags sujas (padrao BCS): UNIT_INVENTORY_CHANGED -> gear+skills,
-- SKILL_LINES_CHANGED -> skills, CHARACTER_POINTS_CHANGED -> talentos,
-- PLAYER_AURAS_CHANGED -> auras. Todos validos na 1.12 (BCS registra os
-- mesmos em BetterCharacterStats.lua).
function CharacterScreen:EnsureEventFrame()
    if self.eventFrame then return end
    local f = CreateFrame("Frame", "ConsoleMode_CharacterEventFrame")
    if type(f.RegisterEvent) == "function" then
        f:RegisterEvent("UNIT_STATS")
        f:RegisterEvent("UNIT_HEALTH")
        f:RegisterEvent("UNIT_MANA")
        f:RegisterEvent("PLAYER_XP_UPDATE")
        f:RegisterEvent("UNIT_INVENTORY_CHANGED")
        f:RegisterEvent("UNIT_ATTACK_POWER")
        f:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
        f:RegisterEvent("UNIT_RESISTANCES")
        f:RegisterEvent("SKILL_LINES_CHANGED")
        f:RegisterEvent("CHARACTER_POINTS_CHANGED")
        f:RegisterEvent("PLAYER_AURAS_CHANGED")
    end
    f:SetScript("OnEvent", function()
        if event and string.sub(event, 1, 5) == "UNIT_" and arg1 ~= "player" then
            return
        end
        if event == "UNIT_INVENTORY_CHANGED" then
            CharacterScreen.scanGearDirty = true
            CharacterScreen.scanSkillsDirty = true
        elseif event == "SKILL_LINES_CHANGED" then
            CharacterScreen.scanSkillsDirty = true
        elseif event == "CHARACTER_POINTS_CHANGED" then
            CharacterScreen.scanTalentsDirty = true
        elseif event == "PLAYER_AURAS_CHANGED" then
            CharacterScreen.scanAurasDirty = true
        end
        if CharacterScreen.isVisible then
            CharacterScreen:Refresh()
        end
    end)
    self.eventFrame = f
end

-- ----------------------------------------------------------------------------
-- 4. CICLO DE VIDA (molde MerchantMenu/MailScreen)
-- ----------------------------------------------------------------------------
function CharacterScreen:Initialize()
    if self.initialized then return end
    self.initialized = true
end

function CharacterScreen:AttachTo(parentFrame)
    self:Initialize()
    if not parentFrame then
        CS_ChatError("AttachTo recebeu parent nil")
        return
    end
    -- Placeholder escondido AQUI (antes de CreateUI): se a construcao da
    -- UI falhar, o erro vai ao chat via pcall do SelectTab em vez de o
    -- modulo travar para sempre em "Modulo em Carregamento".
    CS_HidePlaceholder(parentFrame)
    self.parentFrame = parentFrame
    if not self.attached then
        self:CreateUI(parentFrame)
        self.attached = (self.scrollFrame ~= nil)
        if not self.attached then
            CS_ChatError("CreateUI falhou (scrollFrame nil)")
            return
        end
    elseif self.scrollFrame and self.scrollFrame:GetParent() ~= parentFrame then
        self.scrollFrame:SetParent(parentFrame)
        self.scrollFrame:ClearAllPoints()
        self.scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 8, -8)
        self.scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -8, 8)
    end
    CS_HidePlaceholder(parentFrame)
    self:EnsureEventFrame()
    self:UpdateLayout()
end

function CharacterScreen:Show()
    -- Garante a page hospedeira visivel (o loop Show/Hide do SelectTab roda
    -- antes do AttachTo; re-afirma aqui para nada sobrescrever).
    if self.parentFrame and type(self.parentFrame.Show) == "function" then
        self.parentFrame:Show()
    end
    CS_HidePlaceholder(self.parentFrame)
    if self.scrollFrame then
        self.scrollFrame:Show()
    else
        CS_ChatError("Show com scrollFrame nil (AttachTo nao rodou?)")
        return
    end
    self.isVisible = true
    -- Primeiro Show sempre parte do offset 0 (nada de fallback 380 jogando
    -- o conteudo para fora da vista).
    if not self.firstShown then
        self.scrollOffset = 0
        self.firstShown = true
    end
    -- Dados vivos a cada abertura.
    self:Refresh()
    -- Reaplica o offset atual (o layout 1.12 pode zerar o scroll no Hide).
    if type(self.scrollFrame.SetVerticalScroll) == "function" then
        self.scrollFrame:SetVerticalScroll(CS_Clamp(self.scrollOffset or 0, 0, self:GetMaxScroll()))
    end
    self:UpdateLayout()
    self:ScheduleLayoutRefresh()
end

function CharacterScreen:Hide()
    self.isVisible = false
    if self.scrollFrame and type(self.scrollFrame.Hide) == "function" then
        self.scrollFrame:Hide()
    end
end

function CharacterScreen:IsVisible()
    return self.isVisible
end

-- ----------------------------------------------------------------------------
-- 5. ROLAGEM (Scroll com clamp 0..(contentH - viewH))
-- ----------------------------------------------------------------------------
function CharacterScreen:Scroll(delta)
    if not self.scrollFrame then return 0 end
    local maxScroll = self:GetMaxScroll()
    local cur = self.scrollOffset or 0
    cur = CS_Clamp(cur + (delta or 0), 0, maxScroll)
    self.scrollOffset = cur
    if type(self.scrollFrame.SetVerticalScroll) == "function" then
        self.scrollFrame:SetVerticalScroll(cur)
    end
    return cur
end

-- D-Pad: UP volta (offset -step), DOWN avanca (offset +step).
-- Retorna true quando consome a direcao (contrato do MainMenuNav).
function CharacterScreen:OnDirection(direction)
    if direction == "UP" then
        self:Scroll(-(self.scrollStep or 60))
        return true
    elseif direction == "DOWN" then
        self:Scroll(self.scrollStep or 60)
        return true
    end
    return false
end

-- Inicializacao automatica no carregamento (molde MailScreen: so marca o
-- modulo como inicializado; o AttachTo acontece via MainMenu:SelectTab).
local csAutoInit = CreateFrame("Frame")
csAutoInit:RegisterEvent("VARIABLES_LOADED")
csAutoInit:SetScript("OnEvent", function()
    CharacterScreen:Initialize()
end)
