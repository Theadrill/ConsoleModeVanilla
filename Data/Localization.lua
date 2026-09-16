--[[
    ConsoleMode - Vanilla
    Data/Localization.lua

    FASE 1 - Registro global + loader do sistema de linguagem.
    Arquitetura modular por idioma, dirigida por registro:
    cada idioma vive em Data/Localization/localization_<id>.lua
    e registra UMA entrada em CM_Langs[id] com name, flag e strings.

    Contrato de registro (forma exata definida nesta fase):
    CM_RegisterLang(id, displayName, flagPath)
    CM_RegisterLang(id, displayName, luaPath, flagPath)
    CM_RegisterLang(id, luaPath, flagPath)
    Todas as tres formas sao aceitas. O .toc carrega este arquivo
    ANTES de cada localization_<id>.lua, e todos ANTES de UI.

    Acesso as strings sempre via CM:T("CHAVE").
    Fallback: idioma ativo, depois ptBR, depois chave crua. Nunca nil.
    SavedVariables guarda so o id: ConsoleModeDB.lang = "ptBR".
]]

CM_Langs = CM_Langs or {}
CM_LANG_ORDER = CM_LANG_ORDER or {}

local CM = ConsoleMode
local CM_DEFAULT_LANG = "ptBR"
local CM_FALLBACK_TEX = "Interface\\Icons\\INV_Misc_QuestionMark"
local CM_FALLBACK_TEX2 = "Interface\\AddOns\\ConsoleModeVanilla\\icon_outrange.tga"

-- Registra um idioma no loader. Nao apaga strings ja carregadas.
-- Aceita (id, nome, flag), (id, nome, luaPath, flag) ou (id, luaPath, flag).
function CM_RegisterLang(id, a2, a3, a4)
    if not id or id == "" then
        return
    end
    local displayName = id
    local flagPath = nil
    if a4 then
        displayName = a2
        flagPath = a4
    elseif a3 then
        if type(a2) == "string" and string.find(a2, "%.lua$") then
            displayName = id
        else
            displayName = a2
        end
        flagPath = a3
    elseif a2 then
        displayName = a2
    end
    if not displayName or displayName == "" then
        displayName = id
    end
    local entry = CM_Langs[id]
    if not entry then
        entry = {}
        CM_Langs[id] = entry
    end
    entry.name = displayName
    if flagPath and flagPath ~= "" then
        entry.flag = flagPath
    end
    if not entry.strings then
        entry.strings = {}
    end
    local found = false
    local n = table.getn(CM_LANG_ORDER)
    local i = 1
    while i <= n do
        if CM_LANG_ORDER[i] == id then
            found = true
        end
        i = i + 1
    end
    if not found then
        table.insert(CM_LANG_ORDER, id)
    end
end

-- Devolve o id ativo. Cai para ptBR se DB vazio ou id desconhecido.
function CM:GetActiveLangId()
    if ConsoleModeDB and ConsoleModeDB.lang then
        local want = ConsoleModeDB.lang
        if want and want ~= "" and CM_Langs[want] then
            return want
        end
    end
    return CM_DEFAULT_LANG
end

-- Acesso a string com fallback ativo, ptBR, chave crua. Nunca nil.
function CM:T(key)
    if not key or key == "" then
        return ""
    end
    local langId = CM_DEFAULT_LANG
    if ConsoleModeDB and ConsoleModeDB.lang then
        local want = ConsoleModeDB.lang
        if want and want ~= "" and CM_Langs[want] then
            langId = want
        end
    end
    local entry = CM_Langs[langId]
    if entry and entry.strings then
        local v = entry.strings[key]
        if v and v ~= "" then
            return v
        end
    end
    if langId ~= CM_DEFAULT_LANG then
        local base = CM_Langs[CM_DEFAULT_LANG]
        if base and base.strings then
            local b = base.strings[key]
            if b and b ~= "" then
                return b
            end
        end
    end
    return key
end

-- Resolve ConsoleMode.L para a tabela ativa. Chamar no login.
function CM:ResolveLocale()
    local langId = self:GetActiveLangId()
    local entry = CM_Langs[langId]
    if entry and entry.strings then
        ConsoleMode.L = entry.strings
    else
        local base = CM_Langs[CM_DEFAULT_LANG]
        if base and base.strings then
            ConsoleMode.L = base.strings
        else
            ConsoleMode.L = {}
        end
        langId = CM_DEFAULT_LANG
    end
    return langId
end

-- Devolve a flag do idioma ou textura fallback existente. Nunca nil.
function CM:GetLangFlag(id)
    local entry = nil
    if id and id ~= "" then
        entry = CM_Langs[id]
    end
    if entry and entry.flag and entry.flag ~= "" then
        return entry.flag
    end
    return CM_FALLBACK_TEX2
end

---------------------------------------------------------------------------
-- Acessores GamePT (Fase 7 - Localizacao de Conteudo de Jogo)
---------------------------------------------------------------------------

-- Traducao de perícias/profissoes (skills).
-- Lookup insensivel a maiusculas/minusculas com fallback ptBR -> original.
function CM:GamePT_Skill(skillName)
    if not skillName or skillName == "" then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return skillName
    end
    local key = string.lower(skillName)
    local entry = CM_Langs[activeId]
    if entry and entry.game and entry.game.skills then
        local v = entry.game.skills[key] or entry.game.skills[skillName]
        if v and v ~= "" then
            return v
        end
    end
    if activeId ~= "ptBR" then
        local base = CM_Langs["ptBR"]
        if base and base.game and base.game.skills then
            local b = base.game.skills[key] or base.game.skills[skillName]
            if b and b ~= "" then
                return b
            end
        end
    end
    return skillName
end

-- Regra de formato pura para rank/grau.
function CM:GamePT_Rank(rankStr)
    if not rankStr or rankStr == "" then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return rankStr
    end
    if rankStr == "Passive" then
        return "Passiva"
    end
    local res, count = string.gsub(rankStr, "Rank (%d+)", "Grau %1")
    if count > 0 then
        return res
    end
    return rankStr
end

-- Traducao de magias/habilidades (spells).
-- Lookup insensivel a maiusculas/minusculas com fallback ptBR -> original.
function CM:GamePT_Spell(spellName, rankStr)
    if not spellName or spellName == "" then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return spellName
    end
    local key = string.lower(spellName)
    local entry = CM_Langs[activeId]
    if entry and entry.game and entry.game.spells then
        local v = entry.game.spells[key] or entry.game.spells[spellName]
        if v and v ~= "" then
            return v
        end
    end
    if activeId ~= "ptBR" then
        local base = CM_Langs["ptBR"]
        if base and base.game and base.game.spells then
            local b = base.game.spells[key] or base.game.spells[spellName]
            if b and b ~= "" then
                return b
            end
        end
    end
    return spellName
end

-- Traducao de talentos por coordenada ou coordKey.
-- Aceita (classFile, tab, tier, col, origName) OU (coordKey, origName).
-- Retorna name, desc se tabela, string se string, ou origName.
function CM:GamePT_Talent(a1, a2, a3, a4, a5)
    local coordKey, origName
    if a5 ~= nil then
        coordKey = string.format("%s|%d|%d|%d", tostring(a1 or ""), tonumber(a2) or 0, tonumber(a3) or 0, tonumber(a4) or 0)
        origName = a5
    else
        coordKey = a1
        origName = a2
    end
    if not origName then
        origName = ""
    end
    if not coordKey or coordKey == "" then
        return origName
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return origName
    end
    local entry = CM_Langs[activeId]
    if entry and entry.game and entry.game.talents then
        local t = entry.game.talents[coordKey]
        if t then
            if type(t) == "table" then
                return t.name or origName, t.desc
            elseif type(t) == "string" and t ~= "" then
                return t
            end
        end
    end
    if activeId ~= "ptBR" then
        local base = CM_Langs["ptBR"]
        if base and base.game and base.game.talents then
            local t = base.game.talents[coordKey]
            if t then
                if type(t) == "table" then
                    return t.name or origName, t.desc
                elseif type(t) == "string" and t ~= "" then
                    return t
                end
            end
        end
    end
    return origName
end

-- Traducao de buffs/debuffs.
-- Lookup insensivel a maiusculas/minusculas com fallback ptBR -> original.
function CM:GamePT_Buff(buffName)
    if not buffName or buffName == "" then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return buffName
    end
    local key = string.lower(buffName)
    local entry = CM_Langs[activeId]
    if entry and entry.game and entry.game.buffs then
        local v = entry.game.buffs[key] or entry.game.buffs[buffName]
        if v and v ~= "" then
            return v
        end
    end
    if activeId ~= "ptBR" then
        local base = CM_Langs["ptBR"]
        if base and base.game and base.game.buffs then
            local b = base.game.buffs[key] or base.game.buffs[buffName]
            if b and b ~= "" then
                return b
            end
        end
    end
    return buffName
end

-- Lista idiomas do registro no chat. Usado por /cm lang sem arg.
function CM:ShowLangList()
    local activeId = self:GetActiveLangId()
    local activeName = activeId
    local ae = CM_Langs[activeId]
    if ae and ae.name then
        activeName = ae.name
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r " .. format(self:T("LANG_ACTIVE_FMT"), activeId .. " (" .. activeName .. ")"))
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r " .. self:T("LANG_LIST_HEADER"))
    local n = table.getn(CM_LANG_ORDER)
    local i = 1
    while i <= n do
        local lid = CM_LANG_ORDER[i]
        local le = CM_Langs[lid]
        local lname = lid
        if le and le.name then
            lname = le.name
        end
        local mark = " "
        if lid == activeId then
            mark = "x"
        end
        DEFAULT_CHAT_FRAME:AddMessage("  [" .. mark .. "] " .. format(self:T("LANG_AVAILABLE_FMT"), lid, lname))
        i = i + 1
    end
    local orderIds = ""
    i = 1
    while i <= n do
        if i > 1 then
            orderIds = orderIds .. "|"
        end
        orderIds = orderIds .. CM_LANG_ORDER[i]
        i = i + 1
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff888888" .. format(self:T("LANG_USAGE_FMT"), orderIds) .. "|r")
end

-- Trata /cm lang [id]. Sem arg lista, arg valido salva e recarrega via ReloadUI.
function CM:HandleLangCommand(arg)
    local want = arg or ""
    want = string.gsub(want, "^%s+", "")
    want = string.gsub(want, "%s+$", "")
    if not want or want == "" then
        self:ShowLangList()
        return
    end
    local lower = string.lower(want)
    local canonical = nil
    local n = table.getn(CM_LANG_ORDER)
    local i = 1
    while i <= n do
        local lid = CM_LANG_ORDER[i]
        if string.lower(lid) == lower then
            canonical = lid
        end
        i = i + 1
    end
    if canonical then
        if not ConsoleModeDB then
            ConsoleModeDB = {}
        end
        ConsoleModeDB.lang = canonical
        self:ResolveLocale()
        local le = CM_Langs[canonical]
        local lname = canonical
        if le and le.name then
            lname = le.name
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r " .. format(self:T("LANG_CHANGED_FMT"), canonical .. " (" .. lname .. ")"))
        ReloadUI()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r " .. format(self:T("LANG_UNKNOWN_FMT"), want))
        self:ShowLangList()
    end
end

-- Registro Fase 1: portugues e a base completa. Novos idiomas entram
-- abaixo desta linha, uma chamada por idioma, sem tocar no resto.
CM_RegisterLang("ptBR", "Português (Brasil)", "Data\\Localization\\localization_ptBR.lua", "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_ptBR.tga")
CM_RegisterLang("enUS", "English (US)", "Data\\Localization\\localization_enUS.lua", "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_enUS.tga")

-- Resolve cedo com default. VARIABLES_LOADED resolve de novo com SavedVariables.
CM:ResolveLocale()
