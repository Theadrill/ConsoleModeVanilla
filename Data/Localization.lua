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
    if (not coordKey or coordKey == "") and origName == "" then
        return origName
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return origName
    end
    local entry = CM_Langs[activeId]
    if entry and entry.game and entry.game.talents then
        local t
        if origName ~= "" then
            t = entry.game.talents[string.lower(origName)] or entry.game.talents[origName]
        elseif coordKey and coordKey ~= "" then
            t = entry.game.talents[coordKey]
        end
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
            local t
            if origName ~= "" then
                t = base.game.talents[string.lower(origName)] or base.game.talents[origName]
            elseif coordKey and coordKey ~= "" then
                t = base.game.talents[coordKey]
            end
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

-- Traduz uma linha individual do tooltip de talento usando o motor de templates
function CM:GamePT_TalentLine(classFile, tabIndex, tier, col, talentName, rawLine, currentRank)
    if not rawLine or rawLine == "" then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return rawLine
    end

    local db = CM_TalentDesc_ptBR
    if not db then
        return rawLine
    end

    -- 0. Normalizacao imediata de cabecalhos de rank e requerimento de talentos
    local rMatch, rCount = string.gsub(rawLine, "^Rank (%d+)/(%d+)$", "Grau %1/%2")
    if rCount > 0 then return rMatch end
    rMatch, rCount = string.gsub(rawLine, "^Rank (%d+)$", "Grau %1")
    if rCount > 0 then return rMatch end
    if rawLine == "Next rank:" or rawLine == "Next rank" then return "Próximo grau:" end

    local reqMatch, reqCount = string.gsub(rawLine, "^Requires (%d+) points? in (.+) [Tt]alents?$", function(pts, spec)
        local specPT = db and db.substitutions and db.substitutions[spec] or spec
        return string.format("Requer %s ponto(s) em Talentos de %s", pts, specPT)
    end)
    if reqCount > 0 then return reqMatch end

    local gfind = string.gfind or string.gmatch

    -- 1. Motor Centrado no Talento (Mapeamento Direto por Nome do Talento)
    -- Se o talento estiver cadastrado em db.talents, extrai os números do tooltip
    -- e monta o texto diretamente no template em português. Zero adivinhação.
    if db.talents and talentName and talentName ~= "" then
        local key = string.lower(talentName)
        local tEntry = db.talents[key]
        if tEntry then
            if type(tEntry) == "table" then
                local r = (currentRank and currentRank > 0) and currentRank or 1
                return tEntry[r] or tEntry[1] or rawLine
            elseif type(tEntry) == "string" and tEntry ~= "" then
                if string.find(tEntry, "%%s") then
                    local nums = {}
                    for num in gfind(rawLine, "([%d%.]+)") do
                        table.insert(nums, num)
                    end
                    local unpackFn = unpack or table.unpack
                    local nCount = table.getn(nums)
                    for p = nCount + 1, 10 do
                        table.insert(nums, "")
                    end
                    local ok, formatted = pcall(string.format, tEntry, unpackFn(nums))
                    if ok and formatted then
                        return formatted
                    end
                else
                    return tEntry
                end
            end
        end
    end

    -- 2. Verifica se ha excecao de habilidade unica / capstone
    if db.exceptions and talentName and talentName ~= "" then
        local key = string.lower(talentName)
        local exc = db.exceptions[key]
        if not exc and classFile and tabIndex and tier and col then
            local coordKey = string.format("%s|%d|%d|%d", tostring(classFile), tonumber(tabIndex) or 0, tonumber(tier) or 0, tonumber(col) or 0)
            exc = db.exceptions[coordKey]
        end
        if exc then
            local isHeader = string.find(rawLine, "^Rank ") or string.find(rawLine, "^Next rank") or
                             string.find(rawLine, "Rage") or string.find(rawLine, "Energy") or
                             string.find(rawLine, "Mana") or string.find(rawLine, "cooldown") or
                             string.find(rawLine, "cast") or string.find(rawLine, "range") or
                             string.find(rawLine, "^Requires ")
            if not isHeader then
                if type(exc) == "table" then
                    local r = (currentRank and currentRank > 0) and currentRank or 1
                    return exc[r] or exc[1] or rawLine
                elseif type(exc) == "string" and exc ~= "" then
                    return exc
                end
            end
        end
    end

    -- 2. Funcao auxiliar para traduzir uma clausula/sentenca isolada
    local templates = db.templates
    local subs = db.substitutions
    local sortedKeys = db.sorted_sub_keys

    local function safeReplace(str, eng, pt)
        local sPos, ePos = string.find(str, eng, 1, true)
        while sPos do
            local prevChar = sPos > 1 and string.sub(str, sPos - 1, sPos - 1) or " "
            local nextChar = ePos < string.len(str) and string.sub(str, ePos + 1, ePos + 1) or " "
            local isWordBoundary = (not string.find(prevChar, "%a")) and (not string.find(nextChar, "%a"))
            if isWordBoundary then
                str = string.sub(str, 1, sPos - 1) .. pt .. string.sub(str, ePos + 1)
                sPos, ePos = string.find(str, eng, sPos + string.len(pt), true)
            else
                sPos, ePos = string.find(str, eng, ePos + 1, true)
            end
        end
        return str
    end

    local function translateClause(clause)
        if not templates then return clause end
        for i = 1, table.getn(templates) do
            local rule = templates[i]
            if string.find(clause, rule.pat) then
                local res = string.gsub(clause, rule.pat, rule.rep)
                if subs then
                    if sortedKeys then
                        for k = 1, table.getn(sortedKeys) do
                            local eng = sortedKeys[k]
                            if string.find(res, eng, 1, true) then
                                res = safeReplace(res, eng, subs[eng])
                            end
                        end
                    else
                        for eng, pt in pairs(subs) do
                            if string.find(res, eng, 1, true) then
                                res = safeReplace(res, eng, pt)
                            end
                        end
                    end
                end
                return res
            end
        end
        return clause
    end

    -- 3. Tenta casar a linha inteira primeiro
    local whole = translateClause(rawLine)
    if whole ~= rawLine then
        return whole
    end

    -- 4. Se a linha inteira nao casou e contem multiplas sentencas separadas por ". "
    if string.find(rawLine, "%.%s+") then
        local parts = {}
        local pos = 1
        local hasAnyMatch = false
        while true do
            local st, en = string.find(rawLine, "%.%s+", pos)
            local segment
            if st then
                segment = string.sub(rawLine, pos, st - 1)
                pos = en + 1
            else
                segment = string.sub(rawLine, pos)
            end
            segment = string.gsub(segment, "%.+$", "")
            segment = string.gsub(segment, "^%s+", "")
            segment = string.gsub(segment, "%s+$", "")
            if segment ~= "" then
                local trans = translateClause(segment)
                if trans ~= segment then
                    hasAnyMatch = true
                end
                trans = string.gsub(trans, "%.+$", "")
                table.insert(parts, trans)
            end
            if not st then break end
        end
        if table.getn(parts) > 0 and hasAnyMatch then
            return table.concat(parts, ". ") .. "."
        end
    end

    return rawLine
end

-- Traduz uma descricao completa de talento (multi-linhas)
function CM:GamePT_TalentDesc(classFile, tabIndex, tier, col, currentRank, maxRank, talentName, rawDesc)
    if not rawDesc or rawDesc == "" then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return rawDesc
    end

    local gfind = string.gfind or string.gmatch
    local out = ""
    for line in gfind(rawDesc, "([^\r\n]+)") do
        local trans = self:GamePT_TalentLine(classFile, tabIndex, tier, col, talentName, line, currentRank)
        if out == "" then
            out = trans
        else
            out = out .. "\n" .. trans
        end
    end
    return out ~= "" and out or rawDesc
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
