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

-- Traducao e normalizacao de atributos operacionais de feiticos (custo, tempo, alcance, recarga).
function CM:GamePT_SpellAttr(attrText)
    if not attrText or attrText == "" then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return attrText
    end

    local s = attrText
    -- Custo de recursos
    s = string.gsub(s, "(%d+)%s*Mana", "%1 de Mana")
    s = string.gsub(s, "(%d+)%s*Rage", "%1 de Fúria")
    s = string.gsub(s, "(%d+)%s*Energy", "%1 de Energia")

    -- Tempo de Lancamento
    if s == "Instant" or s == "Instant cast" then
        s = "Instantâneo"
    elseif s == "Channelled" or s == "Channeled" then
        s = "Canalizada"
    else
        s = string.gsub(s, "^Instant%s*cast$", "Instantâneo")
        s = string.gsub(s, "^Instant$", "Instantâneo")
        s = string.gsub(s, "^([%d%.]+)%s*sec%s*cast$", "%1 s de lançamento")
        s = string.gsub(s, "^([%d%.]+)%s*min%s*cast$", "%1 min de lançamento")
    end

    -- Alcance
    s = string.gsub(s, "([%d%.]+)%s*yd%s*range", "%1 m de alcance")
    s = string.gsub(s, "^Melee%s*Range", "Corpo a corpo")
    s = string.gsub(s, "^Unlimited%s*range", "Alcance ilimitado")

    -- Tempo de Recarga / Cooldown
    s = string.gsub(s, "([%d%.]+)%s*sec%s*cooldown", "Recarga: %1 s")
    s = string.gsub(s, "([%d%.]+)%s*min%s*cooldown", "Recarga: %1 min")
    s = string.gsub(s, "([%d%.]+)%s*hr%s*cooldown", "Recarga: %1 h")
    s = string.gsub(s, "([%d%.]+)%s*hour%s*cooldown", "Recarga: %1 h")

    return s
end

-- Traduz linhas de requisitos de ferramentas ou reagentes de feiticos (Tools: ... / Reagents: ...)
function CM:GamePT_SpellTool(line)
    if not line or line == "" then
        return line
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return line
    end

    local db = CM_SpellDesc_ptBR

    -- Tools: <item>
    local _, _, toolItem = string.find(line, "^Tools:%s*(.+)")
    if toolItem then
        local key = string.lower(toolItem)
        local transItem = nil
        if db and db.tools and db.tools[key] then
            transItem = db.tools[key]
        elseif self.GamePT_Item then
            transItem = self:GamePT_Item(toolItem)
        end
        transItem = transItem or toolItem
        return "|cffffd100Ferramentas:|r " .. transItem
    end

    -- Reagents: <item> [opcional (qty)]
    local _, _, reagentLine = string.find(line, "^Reagents:%s*(.+)")
    if reagentLine then
        local _, _, itemPart, qtyPart = string.find(reagentLine, "^(.-)%s*(%(%d+%))$")
        if not itemPart then
            itemPart = reagentLine
            qtyPart = ""
        end
        local key = string.lower(itemPart)
        local transItem = nil
        if db and db.reagents and db.reagents[key] then
            transItem = db.reagents[key]
        elseif self.GamePT_Item then
            transItem = self:GamePT_Item(itemPart)
        end
        transItem = transItem or itemPart
        if qtyPart and qtyPart ~= "" then
            return "|cffffd100Reagentes:|r " .. transItem .. " " .. qtyPart
        else
            return "|cffffd100Reagentes:|r " .. transItem
        end
    end

    return line
end

-- Traducao de descricoes completas de feiticos/magias (Spellbook / Grimorio)
function CM:GamePT_SpellDesc(spellName, rankStr, rawDesc)
    if not rawDesc or rawDesc == "" then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return rawDesc
    end

    local db = CM_SpellDesc_ptBR
    if not db then
        return rawDesc
    end

    local _unpack = unpack or (table and table.unpack)

    -- 0a. FASE 8: SpellDescDB por ID (fonte EN = Spell.dbc Turtle, PT autoral).
    -- Chave: lower(nome).."|"..grau (ex. "earth shock|grau7") + alias "nome|".
    -- PT preenchido vence tudo; PT vazio cai no legado abaixo e o EN sai integro.
    local descDBEntry = nil
    if ConsoleMode_SpellDescDB_ByKey and ConsoleMode_SpellDescDB and spellName then
        local rk = ""
        if rankStr and rankStr ~= "" then
            local _, _, rn = string.find(rankStr, "(%d+)")
            if rn then
                rk = "grau" .. rn
            elseif string.find(string.lower(rankStr), "pass") then
                rk = "passiva"
            end
        end
        local skey = string.lower(spellName) .. "|" .. rk
        local did = ConsoleMode_SpellDescDB_ByKey[skey]
        if not did and rk ~= "" then
            did = ConsoleMode_SpellDescDB_ByKey[string.lower(spellName) .. "|"]
        end
        if did then
            descDBEntry = ConsoleMode_SpellDescDB[did]
        elseif spellName and spellName ~= "" then
            -- FASE 8 bulk: sem entrada no DBC (patch criptografado ou
            -- server-side), registra nome + texto EN na fila p/ lote futuro.
            if ConsoleModeDB then
                ConsoleModeDB.spellMissing = ConsoleModeDB.spellMissing or {}
                local found = false
                local n = table.getn(ConsoleModeDB.spellMissing)
                local i = 1
                while i <= n do
                    if ConsoleModeDB.spellMissing[i].n == spellName then found = true end
                    i = i + 1
                end
                if not found and n < 60 then
                    table.insert(ConsoleModeDB.spellMissing,
                        { n = spellName, r = rankStr or "",
                          d = string.sub(rawDesc or "", 1, 300) })
                end
            end
        end
        -- Guarda diagnóstico da última consulta p/ /cm spelldbg
        CM._lastSpellDbg = CM._lastSpellDbg or {}
        CM._lastSpellDbg.name = spellName
        CM._lastSpellDbg.rank = rankStr
        CM._lastSpellDbg.key = skey
        CM._lastSpellDbg.id = did
        if descDBEntry and descDBEntry.pt and descDBEntry.pt ~= "" then
            CM._lastSpellDbg.src = "DB-PT"
        else
            CM._lastSpellDbg.src = "legado/EN"
        end
    end

    -- 0. Inicializa mapa reverso e aliases de nomes de feiticos em PT se necessario
    if not db._reverseMap and db.spells then
        db._reverseMap = {}
        local ptSpells = CM_Langs and CM_Langs["ptBR"] and CM_Langs["ptBR"].game and CM_Langs["ptBR"].game.spells
        if ptSpells then
            for en, pt in pairs(ptSpells) do
                if type(pt) == "string" and pt ~= "" then
                    local lowPT = string.lower(pt)
                    local lowEN = string.lower(en)
                    db._reverseMap[lowPT] = lowEN
                    if db.spells[lowEN] and not db.spells[lowPT] then
                        db.spells[lowPT] = db.spells[lowEN]
                    end
                end
            end
        end
        -- Aliases comuns adicionais de jogadores e macros
        if db.spells["searing totem"] and not db.spells["totem de fogo"] then
            db.spells["totem de fogo"] = db.spells["searing totem"]
        end
    end

    -- 1. Separa linhas de ferramentas, reagentes e requisitos do corpo real do feitico
    local headerLines = {}
    local bodyLines = {}
    local gfind = string.gfind or string.gmatch
    for line in gfind(rawDesc, "([^\r\n]+)") do
        local trimmed = string.gsub(line, "^%s+", "")
        trimmed = string.gsub(trimmed, "%s+$", "")
        if string.find(trimmed, "^Tools%s*:") or string.find(trimmed, "^Ferramentas%s*:") or
           string.find(trimmed, "^Reagents%s*:") or string.find(trimmed, "^Reagentes%s*:") then
            table.insert(headerLines, self:GamePT_SpellTool(trimmed))
        elseif string.find(trimmed, "^Requires%s+") or string.find(trimmed, "^Requer%s+") then
            local req = string.gsub(trimmed, "^Requires%s+", "")
            local locReq = req
            if CM_Grammar_ptBR and CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[req] then
                locReq = CM_Grammar_ptBR.terms[req]
            elseif CM_Grammar_ptBR and CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[string.gsub(req, "s$", "")] then
                locReq = CM_Grammar_ptBR.terms[string.gsub(req, "s$", "")]
            end
            table.insert(headerLines, "|cffffd100Requer " .. locReq .. "|r")
        elseif string.find(trimmed, "^%d+.*yd%s*range") or string.find(trimmed, "^%d+.*m%s*de alcance") or
               string.find(trimmed, "^Melee%s*Range") or string.find(trimmed, "^Corpo a corpo") then
            -- Linha redundante de alcance que caiu no descLines: descartada do corpo
        else
            table.insert(bodyLines, line)
        end
    end

    local bodyText = table.concat(bodyLines, "\n")
    if bodyText == "" and table.getn(headerLines) > 0 then
        return table.concat(headerLines, "\n")
    end

    local textToTranslate = bodyText ~= "" and bodyText or rawDesc
    local translatedBody = nil

    -- Normaliza espacos multiplos horizontais (preserva quebras de linha entre paragrafos)
    local normDesc = string.gsub(textToTranslate, "[ \t]+", " ")
    normDesc = string.gsub(normDesc, "^[ \t]+", "")
    normDesc = string.gsub(normDesc, "[ \t]+$", "")

    -- Forma canonica de descricoes (normaliza variantes sintaticas do Vanilla / Turtle WoW)
    local canonDesc = string.gsub(normDesc, "at your feet", "at the feet of the caster")
    canonDesc = string.gsub(canonDesc, "Magic", "magic")
    canonDesc = string.gsub(canonDesc, "%s+seconds", " sec")
    canonDesc = string.gsub(canonDesc, "%s+minutes", " min")

    local function TryMatchTemplates(entryList, s1, s2, s3)
        if not entryList then return nil end
        for _, item in ipairs(entryList) do
            if item.pat and item.tpl then
                local matches = { string.find(s1, item.pat) }
                if not matches[1] and s2 then
                    matches = { string.find(s2, item.pat) }
                end
                if not matches[1] and s3 then
                    matches = { string.find(s3, item.pat) }
                end
                if matches[1] then
                    local args = {}
                    local mLen = table.getn(matches)
                    for idx = 3, mLen do
                        local argVal = matches[idx]
                        if type(argVal) == "string" then
                            argVal = string.gsub(argVal, "(%d+)%s+to%s+(%d+)", "%1 a %2")
                            if CM_Grammar_ptBR and CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[argVal] then
                                argVal = CM_Grammar_ptBR.terms[argVal]
                            elseif CM_SpellDesc_ptBR and CM_SpellDesc_ptBR.terms and CM_SpellDesc_ptBR.terms[argVal] then
                                argVal = CM_SpellDesc_ptBR.terms[argVal]
                            end
                        end
                        table.insert(args, argVal)
                    end
                    if type(item.tpl) == "function" then
                        local ok, res = pcall(item.tpl, _unpack(args))
                        if ok and res and res ~= "" then
                            return res
                        end
                    elseif type(item.tpl) == "string" then
                        local ok, res = pcall(string.format, item.tpl, _unpack(args))
                        if ok and res and res ~= "" then
                            return res
                        end
                    end
                end
            end
        end
        return nil
    end

    local key = string.lower(spellName or "")
    local baseKey = string.gsub(key, "%s*%([^%)]*%)", "")
    baseKey = string.gsub(baseKey, "%s+[ivxldcm%d]+$", "")
    baseKey = string.gsub(baseKey, "^%s+", "")
    baseKey = string.gsub(baseKey, "%s+$", "")

    -- 2. Tenta casar nos templates canonicos especificos do feitico
    if db.spells then
        local entryList = db.spells[key] or db.spells[baseKey]
        if not entryList and db._reverseMap then
            local revKey = db._reverseMap[key] or db._reverseMap[baseKey]
            if revKey then
                entryList = db.spells[revKey]
            end
        end
        if entryList then
            translatedBody = TryMatchTemplates(entryList, normDesc, textToTranslate, canonDesc)
        end
    end

    -- 3. Se nao encontrou pelo nome exato, busca nos templates cujas palavras-chave batem com o texto
    if not translatedBody and db.spells then
        local lowerNorm = string.lower(normDesc)
        for sKey, entryList in pairs(db.spells) do
            if string.find(lowerNorm, sKey) then
                translatedBody = TryMatchTemplates(entryList, normDesc, textToTranslate, canonDesc)
                if translatedBody then break end
            end
        end
    end

    -- 4. Tenta casar nos templates genericos de feiticos
    if not translatedBody and db.genericTemplates then
        translatedBody = TryMatchTemplates(db.genericTemplates, normDesc, textToTranslate, canonDesc)
    end

    -- 4b. FASE 8: PT autoral do SpellDescDB (placeholders $ preservados).
    -- Extrai cada valor casando os literais do template EN contra o tooltip:
    -- o numero entre dois literais pertence ao $ do meio (ex.: o "30%" fixo
    -- de Chain Lightning nunca e confundido com o $x1 de alvos).
    -- Se o casamento falhar, cai no modo posicional legado.
    if not translatedBody and descDBEntry and descDBEntry.pt and descDBEntry.pt ~= "" then
        local args = nil
        if descDBEntry.d and descDBEntry.d ~= "" then
            args = self:GamePT_MatchTemplateValues(descDBEntry.d, normDesc)
        end
        if not args then
            args = self:GamePT_ExtractSemanticValues(normDesc, nil)
        end
        local ai = 0
        local nArgs = table.getn(args)
        local ptTpl = string.gsub(descDBEntry.pt, "%$[a-z]%d*", function(ph)
            ai = ai + 1
            if ai <= nArgs then
                return args[ai]
            else
                return ph
            end
        end)
        ptTpl = string.gsub(ptTpl, "%$[a-z]", function(ph)
            ai = ai + 1
            if ai <= nArgs then
                return args[ai]
            else
                return ph
            end
        end)
        translatedBody = ptTpl
    end

    -- 5. FASE 8: sem PT em nenhum nivel, o EN sai INTEGRO (textToTranslate).
    -- O Motor Universal foi removido deste caminho: meio-PT e pior que EN limpo;
    -- casos sem cobertura viram fila de traducao (SpellDescDB pt="" + spellMissing).

    local finalBody = translatedBody or textToTranslate
    if table.getn(headerLines) > 0 then
        return table.concat(headerLines, "\n") .. "\n" .. finalBody
    else
        return finalBody
    end
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

-- Helper central: detecta linhas de cabecalho do tooltip de talento (custo, cast, range, rank, requires).
-- Usado tanto no motor de traducao quanto na agregacao da UI para evitar hijack de headers.
function CM:GamePT_IsTalentHeaderLine(rawLine)
    if not rawLine or rawLine == "" then return false end
    -- Rank / Next rank / Requires sao sempre cabecalho
    if string.find(rawLine, "^Rank ") then return true end
    if string.find(rawLine, "^Next rank") then return true end
    if string.find(rawLine, "^Requires ") then return true end
    -- Linhas curtas de custo/recurso
    if string.find(rawLine, "^%d+ Rage$") then return true end
    if string.find(rawLine, "^%d+ Energy$") then return true end
    if string.find(rawLine, "^%d+ Mana$") then return true end
    if string.find(rawLine, "^Instant$") then return true end
    if string.find(rawLine, "^Instant cast$") then return true end
    if string.find(rawLine, "^Channeled$") then return true end
    if string.find(rawLine, "^[%d%.]+ sec cast$") then return true end
    if string.find(rawLine, "^[%d%.]+ sec cooldown$") then return true end
    if string.find(rawLine, "^[%d%.]+ min cooldown$") then return true end
    if string.find(rawLine, "^[%d%.]+ hr cooldown$") then return true end
    if string.find(rawLine, "^%d+ yd range$") then return true end
    if string.find(rawLine, "^Melee Range$") then return true end
    if string.find(rawLine, "^Requires Melee") then return true end
    if string.find(rawLine, "^Requires Ranged") then return true end
    if string.find(rawLine, "^Requires Shields?$") then return true end
    if string.find(rawLine, "^Requires Shield$") then return true end
    return false
end

-- Helper central: extracao semantica de valores numericos em tooltips de talentos.
-- Reconhece ranges nativos ("X to Y") e faz folding inteligente ("X a Y") quando o
-- template em portugues usa um unico %s, ou preserva min e max caso o template use "%s a %s".
function CM:GamePT_ExtractSemanticValues(rawLine, tEntry)
    if not rawLine or rawLine == "" then return {} end
    local args = {}
    local hasDualRange = false
    if tEntry then
        if string.find(tEntry, "%%s%s+a%s+%%s") or string.find(tEntry, "%%s%s+até%s+%%s") or string.find(tEntry, "%%s%s*%-%%s") then
            hasDualRange = true
        end
    end

    local pos = 1
    local len = string.len(rawLine)
    while pos <= len do
        local rStart, rEnd, rMin, rMax = string.find(rawLine, "(%d+[%d%.]*)%s+to%s+(%d+[%d%.]*)", pos)
        local nStart, nEnd, nVal = string.find(rawLine, "(%d+[%d%.]*)", pos)

        if not nStart then
            break
        end

        if rStart and rStart == nStart then
            rMin = string.gsub(rMin, "%.$", "")
            rMax = string.gsub(rMax, "%.$", "")
            if hasDualRange then
                table.insert(args, rMin)
                table.insert(args, rMax)
            else
                table.insert(args, rMin .. " a " .. rMax)
            end
            pos = rEnd + 1
        else
            nVal = string.gsub(nVal, "%.$", "")
            if nVal ~= "" then
                table.insert(args, nVal)
            end
            pos = nEnd + 1
        end
    end
    return args
end

-- FASE 8: extracao dirigida pelo template EN (com $): cada valor e o numero
-- entre dois literais ("30%" fixo nunca cai num slot $). Retorna nil se algum
-- literal nao casar (chama quem chama a usar o modo posicional).
function CM:GamePT_MatchTemplateValues(enTemplate, renderedText)
    if not enTemplate or enTemplate == "" or not renderedText or renderedText == "" then
        return nil
    end
    local flatT = string.gsub(enTemplate, "%s+", " ")
    flatT = string.gsub(flatT, "%$[lg][^;]*;", "")
    local flatR = string.gsub(renderedText, "%s+", " ")
    local lowT = string.lower(flatT)
    local lowR = string.lower(flatR)
    -- Divide o template em literais (segs) e marcadores $ (marks)
    local segs = {}
    local nMarks = 0
    local pos = 1
    local tLen = string.len(lowT)
    while pos <= tLen do
        local s, e = string.find(lowT, "%$%S+", pos)
        if not s then
            break
        end
        table.insert(segs, string.sub(lowT, pos, s - 1))
        nMarks = nMarks + 1
        pos = e + 1
    end
    table.insert(segs, string.sub(lowT, pos))
    if nMarks == 0 then
        return nil
    end
    -- Localiza cada literal em ordem, uma unica passada
    local bounds = {}
    local fpos = 1
    local rLen = string.len(lowR)
    local si = 1
    while si <= table.getn(segs) do
        local seg = segs[si] or ""
        if seg == "" then
            bounds[si] = fpos
        else
            local s, e = string.find(lowR, seg, fpos, true)
            if not s then
                return nil
            end
            bounds[si] = s
            fpos = e + 1
        end
        si = si + 1
    end
    -- Gap i = entre o fim de segs[i] e o inicio de segs[i+1] = valor do $ i
    local args = {}
    local i = 1
    while i <= nMarks do
        local gapStart = bounds[i] + string.len(segs[i] or "")
        local gapEnd = bounds[i + 1] - 1
        if gapEnd > rLen then
            gapEnd = rLen
        end
        local gap = ""
        if gapEnd >= gapStart then
            gap = string.sub(flatR, gapStart, gapEnd)
        end
        local _, _, rMin, rMax = string.find(gap, "(%d+[%d%.]*)%s+to%s+(%d+[%d%.]*)")
        if rMin and rMax then
            rMin = string.gsub(rMin, "%.$", "")
            rMax = string.gsub(rMax, "%.$", "")
            table.insert(args, rMin .. " a " .. rMax)
        else
            local _, _, nVal = string.find(gap, "(%d+[%d%.]*)")
            if not nVal or nVal == "" then
                return nil
            end
            nVal = string.gsub(nVal, "%.$", "")
            table.insert(args, nVal)
        end
        i = i + 1
    end
    return args
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

    -- 0b. Requisito generico de talento (ex.: "Requires 5 points in Thundering Strikes")
    -- Cobre prereqs que nao terminam em "Talents" e que o bloco (0) acima nao pegou.
    do
        local genReq, genCount = string.gsub(rawLine, "^Requires (%d+) points? in (.+)$", function(pts, who)
            local ptWho = who
            if db.substitutions and db.substitutions[who] then
                ptWho = db.substitutions[who]
            else
                local low = string.lower(who)
                if db.substitutions and db.substitutions[low] then
                    ptWho = db.substitutions[low]
                else
                    -- tenta resolver nome do talento via game.talents (sem pcall recursivo)
                    local activeId = CM:GetActiveLangId()
                    if activeId ~= "enUS" then
                        local entry = CM_Langs[activeId]
                        local g = entry and entry.game and entry.game.talents
                        if g then
                            local v = g[low] or g[who]
                            if v then
                                if type(v) == "string" and v ~= "" then ptWho = v
                                elseif type(v) == "table" and v.name then ptWho = v.name end
                            end
                        end
                        if ptWho == who and activeId ~= "ptBR" then
                            local base = CM_Langs["ptBR"]
                            local bg = base and base.game and base.game.talents
                            if bg then
                                local bv = bg[low] or bg[who]
                                if bv then
                                    if type(bv) == "string" and bv ~= "" then ptWho = bv
                                    elseif type(bv) == "table" and bv.name then ptWho = bv.name end
                                end
                            end
                        end
                    end
                end
            end
            return string.format("Requer %s ponto(s) em %s", pts, ptWho)
        end)
        if genCount > 0 then return genReq end
    end

    -- 0c. Guard de cabecalho: delega ao helper central para evitar duplicacao
    -- e garantir consistencia com a agregacao da UI.
    local isHeader = self:GamePT_IsTalentHeaderLine(rawLine)

    -- 1. Motor Centrado no Talento (Mapeamento Direto por Nome do Talento)
    -- So aplica em linhas de descricao real; headers nunca entram aqui.
    -- Para entradas do tipo tabela (por rank), retorna direto (rank-aware).
    -- Para strings com %s, exige correspondencia semantica e paridade estrita
    -- entre valores identificados e placeholders para impedir o deslocamento em cascata.
    if not isHeader and db.talents and talentName and talentName ~= "" then
        local key = string.lower(talentName)
        local tEntry = db.talents[key]
        if tEntry then
            if type(tEntry) == "table" then
                local r = (currentRank and currentRank > 0) and currentRank or 1
                return tEntry[r] or tEntry[1] or rawLine
            elseif type(tEntry) == "string" and tEntry ~= "" then
                local phCount = 0
                for _ in gfind(tEntry, "%%s") do phCount = phCount + 1 end

                if phCount == 0 then
                    return tEntry
                end

                local args = self:GamePT_ExtractSemanticValues(rawLine, tEntry)
                if table.getn(args) == phCount then
                    local unpackFn = unpack or table.unpack
                    local callNums = {}
                    for i = 1, phCount do callNums[i] = args[i] end
                    for i = phCount + 1, 10 do callNums[i] = "" end
                    local ok, formatted = pcall(string.format, tEntry, unpackFn(callNums))
                    if ok and formatted then
                        return formatted
                    end
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
            if not self:GamePT_IsTalentHeaderLine(rawLine) then
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

    -- 5. Motor Semantico Universal (Camada 3 Heuristica Global para Talentos)
    if CM_Grammar_ptBR and CM_Grammar_ptBR.TranslateUniversal then
        local uTrans = CM_Grammar_ptBR.TranslateUniversal(rawLine)
        if uTrans and uTrans ~= "" and uTrans ~= rawLine then
            return uTrans
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

    local db = CM_TalentDesc_ptBR
    if db and talentName and talentName ~= "" then
        local key = string.lower(talentName)
        if db.talents and type(db.talents[key]) == "table" then
            local r = (currentRank and currentRank > 0) and currentRank or 1
            local t = db.talents[key][r] or db.talents[key][1]
            if t and t ~= "" then
                return t
            end
        end
        if db.exceptions and type(db.exceptions[key]) == "table" then
            local r = (currentRank and currentRank > 0) and currentRank or 1
            local t = db.exceptions[key][r] or db.exceptions[key][1]
            if t and t ~= "" then
                return t
            end
        end
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
    -- Fallback inteligente: auras e efeitos de feitiços compartilham o mesmo nome da magia
    if self.GamePT_Spell then
        local sp = self:GamePT_Spell(buffName)
        if sp and sp ~= buffName then
            return sp
        end
    end
    return buffName
end

---------------------------------------------------------------------------
-- Tradução de Conteúdo de Itens e Inventário (Fase 7.5)
---------------------------------------------------------------------------

local CM_ITEM_SUFFIXES = {
    ["of the Monkey"] = "do Macaco", ["of the monkey"] = "do Macaco",
    ["of the Eagle"] = "da Águia", ["of the eagle"] = "da Águia",
    ["of the Bear"] = "do Urso", ["of the bear"] = "do Urso",
    ["of the Whale"] = "da Baleia", ["of the whale"] = "da Baleia",
    ["of the Owl"] = "da Coruja", ["of the owl"] = "da Coruja",
    ["of the Gorilla"] = "do Gorila", ["of the gorilla"] = "do Gorila",
    ["of the Falcon"] = "do Falcão", ["of the falcon"] = "do Falcão",
    ["of the Wolf"] = "do Lobo", ["of the wolf"] = "do Lobo",
    ["of the Tiger"] = "do Tigre", ["of the tiger"] = "do Tigre",
    ["of the Boar"] = "do Javali", ["of the boar"] = "do Javali",
    ["of Strength"] = "da Força", ["of strength"] = "da Força",
    ["of Agility"] = "da Agilidade", ["of agility"] = "da Agilidade",
    ["of Stamina"] = "do Vigor", ["of stamina"] = "do Vigor",
    ["of Intellect"] = "do Intelecto", ["of intellect"] = "do Intelecto",
    ["of Spirit"] = "do Espírito", ["of spirit"] = "do Espírito",
    ["of Power"] = "do Poder", ["of power"] = "do Poder",
    ["of Defense"] = "da Defesa", ["of defense"] = "da Defesa",
    ["of Blocking"] = "do Bloqueio", ["of blocking"] = "do Bloqueio",
    ["of Healing"] = "da Cura", ["of healing"] = "da Cura",
    ["of Fire Wrath"] = "da Fúria do Fogo",
    ["of Frost Wrath"] = "da Fúria do Gelo",
    ["of Nature's Wrath"] = "da Fúria da Natureza",
    ["of Shadow Wrath"] = "da Fúria da Sombra",
    ["of Arcane Wrath"] = "da Fúria Arcana",
}

local CM_QUEST_ITEM_PREFIXES = {
    ["Horn"] = "Chifre", ["Head"] = "Cabeça", ["Claw"] = "Garra", ["Heart"] = "Coração",
    ["Eye"] = "Olho", ["Eyes"] = "Olhos", ["Blood"] = "Sangue", ["Tusk"] = "Presa",
    ["Tusks"] = "Presas", ["Fang"] = "Presa", ["Fangs"] = "Presas", ["Skin"] = "Pele",
    ["Scale"] = "Escama", ["Scales"] = "Escamas", ["Tail"] = "Cauda", ["Tooth"] = "Dente",
    ["Teeth"] = "Dentes", ["Feather"] = "Pena", ["Feathers"] = "Penas", ["Letter"] = "Carta",
    ["Key"] = "Chave", ["Note"] = "Nota", ["Token"] = "Ficha", ["Remains"] = "Restos",
    ["Tears"] = "Lágrimas", ["Hand"] = "Mão", ["Essence"] = "Essência", ["Symbol"] = "Símbolo",
    ["Badge"] = "Distintivo", ["Crest"] = "Brasão", ["Trophy"] = "Troféu", ["Mark"] = "Marca",
    ["Tome"] = "Tomo", ["Scroll"] = "Pergaminho", ["Book"] = "Livro", ["Skull"] = "Crânio",
    ["Bone"] = "Osso", ["Bones"] = "Ossos", ["Rib"] = "Costela", ["Femur"] = "Fêmur",
    ["Shard"] = "Fragmento", ["Shards"] = "Fragmentos", ["Crystal"] = "Cristal",
    ["Crystals"] = "Cristais", ["Gem"] = "Gema", ["Gems"] = "Gemas", ["Orb"] = "Orbe",
    ["Ring"] = "Anel", ["Amulet"] = "Amuleto", ["Pendant"] = "Pingente", ["Idol"] = "Ídolo",
    ["Staff"] = "Cajado", ["Blade"] = "Lâmina", ["Sword"] = "Espada", ["Dagger"] = "Adaga",
    ["Axe"] = "Machado", ["Hammer"] = "Martelo", ["Shield"] = "Escudo", ["Helm"] = "Elmo",
    ["Crown"] = "Coroa", ["Medallion"] = "Medalhão", ["Relic"] = "Relíquia",
}

-- Tradução do nome do item. Fonte da verdade por ID (ItemDB offline pfQuest+Turtle).
-- Aceita (name) ou (name, linkOrID). Link "item:1234:..." ou ID numerico tem prioridade;
-- fallback por nome via ByName, depois game.items legado, depois heuristicas.
function CM:GamePT_Item(itemName, itemLinkOrID)
    if (not itemName or itemName == "") and (not itemLinkOrID or itemLinkOrID == "") then
        return ""
    end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then
        return itemName or ""
    end
    -- 0. Resolve ID do item a partir do link ou numero direto
    local itemID = nil
    if itemLinkOrID then
        if type(itemLinkOrID) == "number" then
            itemID = itemLinkOrID
        elseif type(itemLinkOrID) == "string" and itemLinkOrID ~= "" then
            local _, _, idStr = string.find(itemLinkOrID, "item:(%d+)")
            if idStr then
                itemID = tonumber(idStr)
            else
                local asNum = tonumber(itemLinkOrID)
                if asNum then itemID = asNum end
            end
        end
    end
    -- 0a. pfDB em memoria tem prioridade (jogador com pfQuest ativo, mesma regra do QuestDB)
    if pfDB and pfDB["items"] then
        local langKey = "ptBR"
        if activeId ~= "ptBR" and pfDB["items"][activeId] then langKey = activeId end
        local t1 = pfDB["items"][langKey] or pfDB["items"]["ptBR"]
        local t2 = pfDB["items"][langKey .. "-turtle"] or pfDB["items"]["ptBR-turtle"]
        if itemID then
            if t2 and t2[itemID] and t2[itemID] ~= "" and t2[itemID] ~= "_" then return t2[itemID] end
            if t1 and t1[itemID] and t1[itemID] ~= "" and t1[itemID] ~= "_" then return t1[itemID] end
        end
    end
    -- 0b. ItemDB local (build_itemdb.py: vanilla + Turtle customs, Turtle vence)
    if itemID and ConsoleMode_ItemDB then
        local v = ConsoleMode_ItemDB[itemID]
        if v and v ~= "" then
            return v
        end
    end
    -- 0c. Fallback por nome EN -> ID -> PT (quando link/ID indisponivel, ex. reagentes de spell)
    if itemName and itemName ~= "" and ConsoleMode_ItemDB_ByName and ConsoleMode_ItemDB then
        local nid = ConsoleMode_ItemDB_ByName[string.lower(itemName)]
        if nid and ConsoleMode_ItemDB[nid] and ConsoleMode_ItemDB[nid] ~= "" then
            return ConsoleMode_ItemDB[nid]
        end
    end
    if not itemName or itemName == "" then
        return ""
    end
    local key = string.lower(itemName)
    local entry = CM_Langs[activeId]
    if entry and entry.game and entry.game.items then
        local v = entry.game.items[key] or entry.game.items[itemName]
        if v and v ~= "" then
            return v
        end
    end
    if activeId ~= "ptBR" then
        local base = CM_Langs["ptBR"]
        if base and base.game and base.game.items then
            local b = base.game.items[key] or base.game.items[itemName]
            if b and b ~= "" then
                return b
            end
        end
    end

    -- Decomposição de itens mágicos verdes com sufixo (ex: "Linen Belt of the Boar")
    local _, _, baseName, sfx = string.find(itemName, "^(.+)%s+(of%s+.+)$")
    if baseName and sfx and CM_ITEM_SUFFIXES and CM_ITEM_SUFFIXES[sfx] then
        local locBase = self:GamePT_Item(baseName)
        local locSfx = CM_ITEM_SUFFIXES[sfx]
        if locBase and locBase ~= baseName then
            return locBase .. " " .. locSfx
        else
            return baseName .. " " .. locSfx
        end
    end

    -- Decomposição sintática de itens de missões/lore X of Y (ex: "Horn of Echeyakee")
    local _, _, noun, entity = string.find(itemName, "^([%a%s]+)%s+of%s+(.+)$")
    if noun and entity then
        local locNoun = CM_QUEST_ITEM_PREFIXES[noun]
        if locNoun then
            local prep = "de"
            if string.find(entity, "^the%s+") then
                entity = string.gsub(entity, "^the%s+", "")
                prep = "do(a)"
            end
            if CM_Grammar_ptBR and CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[entity] then
                entity = CM_Grammar_ptBR.terms[entity]
            end
            return locNoun .. " " .. prep .. " " .. entity
        end
    end

    return itemName
end

-- Mapeamento oficial de slots/locais de equipamento Blizzard
local CM_EQUIPLOC_MAP = {
    ["INVTYPE_HEAD"] = "Cabeça", ["Head"] = "Cabeça", ["head"] = "Cabeça",
    ["INVTYPE_NECK"] = "Pescoço", ["Neck"] = "Pescoço", ["neck"] = "Pescoço",
    ["INVTYPE_SHOULDER"] = "Ombros", ["Shoulder"] = "Ombros", ["shoulder"] = "Ombros",
    ["INVTYPE_BODY"] = "Camisa", ["Shirt"] = "Camisa", ["shirt"] = "Camisa",
    ["INVTYPE_CHEST"] = "Torso", ["Chest"] = "Torso", ["chest"] = "Torso",
    ["INVTYPE_ROBE"] = "Veste", ["Robe"] = "Veste", ["robe"] = "Veste",
    ["INVTYPE_WAIST"] = "Cintura", ["Waist"] = "Cintura", ["waist"] = "Cintura",
    ["INVTYPE_LEGS"] = "Pernas", ["Legs"] = "Pernas", ["legs"] = "Pernas",
    ["INVTYPE_FEET"] = "Pés", ["Feet"] = "Pés", ["feet"] = "Pés",
    ["INVTYPE_WRIST"] = "Pulsos", ["Wrist"] = "Pulsos", ["wrist"] = "Pulsos",
    ["INVTYPE_HAND"] = "Mãos", ["Hands"] = "Mãos", ["hands"] = "Mãos",
    ["INVTYPE_FINGER"] = "Dedo", ["Finger"] = "Dedo", ["finger"] = "Dedo",
    ["INVTYPE_TRINKET"] = "Berloque", ["Trinket"] = "Berloque", ["trinket"] = "Berloque",
    ["INVTYPE_CLOAK"] = "Costas", ["Cloak"] = "Costas", ["cloak"] = "Costas", ["Back"] = "Costas", ["back"] = "Costas",
    ["INVTYPE_WEAPON"] = "Uma Mão", ["One-Hand"] = "Uma Mão", ["one-hand"] = "Uma Mão",
    ["INVTYPE_SHIELD"] = "Escudo", ["Shield"] = "Escudo", ["shield"] = "Escudo",
    ["INVTYPE_2HWEAPON"] = "Duas Mãos", ["Two-Hand"] = "Duas Mãos", ["two-hand"] = "Duas Mãos",
    ["INVTYPE_WEAPONMAINHAND"] = "Mão Principal", ["Main Hand"] = "Mão Principal", ["main hand"] = "Mão Principal",
    ["INVTYPE_WEAPONOFFHAND"] = "Mão Secundária", ["Off Hand"] = "Mão Secundária", ["off hand"] = "Mão Secundária",
    ["INVTYPE_HOLDABLE"] = "Empunhado na Mão Secundária", ["Held in Off-hand"] = "Empunhado na Mão Secundária", ["Held In Off-hand"] = "Empunhado na Mão Secundária",
    ["INVTYPE_RANGED"] = "Longo Alcance", ["Ranged"] = "Longo Alcance", ["ranged"] = "Longo Alcance",
    ["INVTYPE_THROWN"] = "Arremesso", ["Thrown"] = "Arremesso", ["thrown"] = "Arremesso",
    ["INVTYPE_RANGEDRIGHT"] = "Longo Alcance",
    ["INVTYPE_RELIC"] = "Relíquia", ["Relic"] = "Relíquia", ["relic"] = "Relíquia",
    ["INVTYPE_TABARD"] = "Tabardo", ["Tabard"] = "Tabardo", ["tabard"] = "Tabardo",
    ["INVTYPE_BAG"] = "Bolsa", ["Bag"] = "Bolsa", ["bag"] = "Bolsa",
    ["INVTYPE_AMMO"] = "Munição", ["Ammo"] = "Munição", ["ammo"] = "Munição",
}

function CM:GamePT_EquipLoc(equipLoc)
    if not equipLoc or equipLoc == "" then return "" end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then return equipLoc end
    return CM_EQUIPLOC_MAP[equipLoc] or equipLoc
end

-- Mapeamento oficial de subtipos de itens Blizzard
local CM_SUBTYPE_MAP = {
    -- Armaduras
    ["Cloth"] = "Tecido", ["cloth"] = "Tecido",
    ["Leather"] = "Couro", ["leather"] = "Couro",
    ["Mail"] = "Malha", ["mail"] = "Malha",
    ["Plate"] = "Placas", ["plate"] = "Placas",
    ["Shields"] = "Escudos", ["Shield"] = "Escudo", ["shields"] = "Escudos", ["shield"] = "Escudo",
    ["Buckler"] = "Broquel", ["buckler"] = "Broquel",
    ["Libram"] = "Livro Sagrado", ["Idol"] = "Ídolo", ["Totem"] = "Totem",
    -- Armas
    ["One-Handed Swords"] = "Espadas de Uma Mão", ["one-handed swords"] = "Espadas de Uma Mão",
    ["Two-Handed Swords"] = "Espadas de Duas Mãos", ["two-handed swords"] = "Espadas de Duas Mãos",
    ["One-Handed Axes"] = "Machados de Uma Mão", ["one-handed axes"] = "Machados de Uma Mão",
    ["Two-Handed Axes"] = "Machados de Duas Mãos", ["two-handed axes"] = "Machados de Duas Mãos",
    ["One-Handed Maces"] = "Maças de Uma Mão", ["one-handed maces"] = "Maças de Uma Mão",
    ["Two-Handed Maces"] = "Maças de Duas Mãos", ["two-handed maces"] = "Maças de Duas Mãos",
    ["Daggers"] = "Adagas", ["daggers"] = "Adagas", ["Dagger"] = "Adaga",
    ["Polearms"] = "Armas de Haste", ["polearms"] = "Armas de Haste",
    ["Staves"] = "Cajados", ["staves"] = "Cajados", ["Staff"] = "Cajado",
    ["Fist Weapons"] = "Armas de Punho", ["fist weapons"] = "Armas de Punho",
    ["Bows"] = "Arcos", ["bows"] = "Arcos", ["Bow"] = "Arco",
    ["Crossbows"] = "Bestas", ["crossbows"] = "Bestas", ["Crossbow"] = "Besta",
    ["Guns"] = "Armas de Fogo", ["guns"] = "Armas de Fogo", ["Gun"] = "Arma de Fogo",
    ["Wands"] = "Varinhas", ["wands"] = "Varinhas", ["Wand"] = "Varinha",
    ["Thrown"] = "Armas de Arremesso", ["thrown"] = "Armas de Arremesso",
    ["Fishing Pole"] = "Vara de Pesca", ["Fishing Poles"] = "Varas de Pesca",
    ["Miscellaneous"] = "Diversos", ["miscellaneous"] = "Diversos",
    -- Consumíveis
    ["Consumable"] = "Consumível", ["consumable"] = "Consumível",
    ["Potion"] = "Poção", ["potion"] = "Poção",
    ["Elixir"] = "Elixir", ["elixir"] = "Elixir",
    ["Flask"] = "Frasco", ["flask"] = "Frasco",
    ["Scroll"] = "Pergaminho", ["scroll"] = "Pergaminho",
    ["Food & Drink"] = "Comida e Bebida", ["food & drink"] = "Comida e Bebida",
    ["Food"] = "Comida", ["Drink"] = "Bebida",
    ["Bandage"] = "Bandagem", ["bandage"] = "Bandagem",
    -- Bolsas
    ["Bag"] = "Bolsa", ["bag"] = "Bolsa",
    ["Soul Bag"] = "Bolsa de Almas", ["soul bag"] = "Bolsa de Almas",
    ["Herb Bag"] = "Bolsa de Ervas", ["herb bag"] = "Bolsa de Ervas",
    ["Enchanting Bag"] = "Bolsa de Encantamento", ["enchanting bag"] = "Bolsa de Encantamento",
    ["Engineering Bag"] = "Bolsa de Engenharia", ["engineering bag"] = "Bolsa de Engenharia",
    ["Mining Bag"] = "Bolsa de Mineração", ["mining bag"] = "Bolsa de Mineração",
    ["Quiver"] = "Aljava", ["quiver"] = "Aljava",
    ["Ammo Pouch"] = "Bolsa de Munição", ["ammo pouch"] = "Bolsa de Munição",
    -- Comércio e Outros
    ["Trade Goods"] = "Itens de Comércio", ["trade goods"] = "Itens de Comércio",
    ["Parts"] = "Peças", ["parts"] = "Peças",
    ["Explosives"] = "Explosivos", ["explosives"] = "Explosivos",
    ["Devices"] = "Dispositivos", ["devices"] = "Dispositivos",
    ["Reagent"] = "Reagente", ["reagent"] = "Reagente",
    ["Quest"] = "Missão", ["quest"] = "Missão",
    ["Key"] = "Chave", ["key"] = "Chave",
    ["Junk"] = "Lixo", ["junk"] = "Lixo",
}

function CM:GamePT_ItemSubType(subType)
    if not subType or subType == "" then return "" end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then return subType end
    return CM_SUBTYPE_MAP[subType] or subType
end

-- Tradução procedural de linhas de atributos, efeitos e requisitos de itens
function CM:GamePT_ItemStat(statLine)
    if not statLine or statLine == "" then return "" end
    local activeId = self:GetActiveLangId()
    if activeId == "enUS" then return statLine end

    local s = statLine

    -- 1. Vínculos e Estados
    if s == "Quest Item" then return "Item de Missão" end
    if s == "Quest" then return "Missão" end
    s = string.gsub(s, "^Quest Item$", "Item de Missão")
    s = string.gsub(s, "^Quest$", "Missão")
    s = string.gsub(s, "Binds when picked up", "Vincula-se ao ser recolhido")
    s = string.gsub(s, "Binds when equipped", "Vincula-se quando equipado")
    s = string.gsub(s, "Binds when used", "Vincula-se quando usado")
    s = string.gsub(s, "Soulbound", "Vinculado")
    s = string.gsub(s, "Unique", "Único")

    -- 2. Dano, Velocidade e Armadura
    s = string.gsub(s, "(%d+)%s*-%s*(%d+)%s+Damage", "%1 - %2 de Dano")
    s = string.gsub(s, "Speed%s+([%d%.]+)", "Velocidade %1")
    s = string.gsub(s, "%(([%d%.]+)%s+damage%s+per%s+second%)", "(%1 de dano por segundo)")
    s = string.gsub(s, "(%d+)%s+Armor", "%1 de Armadura")
    s = string.gsub(s, "(%d+)%s+Block", "%1 de Bloqueio")

    -- 3. Atributos Primários (+X Stat)
    s = string.gsub(s, "%+(%d+)%s+Strength", "+%1 de Força")
    s = string.gsub(s, "%+(%d+)%s+Agility", "+%1 de Agilidade")
    s = string.gsub(s, "%+(%d+)%s+Stamina", "+%1 de Vigor")
    s = string.gsub(s, "%+(%d+)%s+Intellect", "+%1 de Intelecto")
    s = string.gsub(s, "%+(%d+)%s+Spirit", "+%1 de Espírito")
    s = string.gsub(s, "%+(%d+)%s+Attack Power", "+%1 de Poder de Ataque")
    s = string.gsub(s, "%+(%d+)%s+[aA]rmor", "+%1 de Armadura")

    -- 4. Resistências
    s = string.gsub(s, "%+(%d+)%s+Fire Resistance", "+%1 de Resistência ao Fogo")
    s = string.gsub(s, "%+(%d+)%s+Frost Resistance", "+%1 de Resistência ao Gelo")
    s = string.gsub(s, "%+(%d+)%s+Nature Resistance", "+%1 de Resistência à Natureza")
    s = string.gsub(s, "%+(%d+)%s+Shadow Resistance", "+%1 de Resistência à Sombra")
    s = string.gsub(s, "%+(%d+)%s+Arcane Resistance", "+%1 de Resistência ao Arcano")

    -- 5. Requisitos e Durabilidade
    s = string.gsub(s, "Durability%s+(%d+)%s*/%s*(%d+)", "Durabilidade %1 / %2")
    s = string.gsub(s, "Requires Level%s+(%d+)", "Requer Nível %1")
    s = string.gsub(s, "Requires%s+([%a%s]+)%s*%((%d+)%)", function(prof, lvl)
        local locProf = CM and CM.GamePT_Skill and CM:GamePT_Skill(prof) or prof
        return string.format("Requer %s (%s)", locProf, lvl)
    end)
    s = string.gsub(s, "Classes:%s*(.+)", function(clsList)
        local c = clsList
        c = string.gsub(c, "Warrior", "Guerreiro")
        c = string.gsub(c, "Paladin", "Paladino")
        c = string.gsub(c, "Hunter", "Caçador")
        c = string.gsub(c, "Rogue", "Ladino")
        c = string.gsub(c, "Priest", "Sacerdote")
        c = string.gsub(c, "Shaman", "Xamã")
        c = string.gsub(c, "Mage", "Mago")
        c = string.gsub(c, "Warlock", "Bruxo")
        c = string.gsub(c, "Druid", "Druida")
        return "Classes: " .. c
    end)
    s = string.gsub(s, "Races:%s*(.+)", function(raceList)
        local r = raceList
        r = string.gsub(r, "Human", "Humano")
        r = string.gsub(r, "Orc", "Orc")
        r = string.gsub(r, "Dwarf", "Anão")
        r = string.gsub(r, "Night Elf", "Elfo Noturno")
        r = string.gsub(r, "Undead", "Renegado")
        r = string.gsub(r, "Tauren", "Tauren")
        r = string.gsub(r, "Gnome", "Gnomo")
        r = string.gsub(r, "Troll", "Troll")
        return "Raças: " .. r
    end)

    -- 6. Prefixos de Efeitos
    s = string.gsub(s, "^Use:%s*", "Uso: ")
    s = string.gsub(s, "^Equip:%s*", "Equipar: ")
    s = string.gsub(s, "^Chance on hit:%s*", "Chance ao acertar: ")

    -- Normalização de Recarga de Itens (CD: 30 s / 60.0 min)
    s = string.gsub(s, "%(%s*CD:%s*([%d%.]+)%s*([%a]+)%s*%)", "(Recarga: %1 %2)")
    s = string.gsub(s, "CD:%s*([%d%.]+)%s*([%a]+)", "Recarga: %1 %2")
    s = string.gsub(s, "%(%s*(%d+%.?%d*)%s*Min%s*[Cc]ooldown%s*%)", "(Recarga: %1 min)")
    s = string.gsub(s, "%(%s*(%d+%.?%d*)%s*Sec%s*[Cc]ooldown%s*%)", "(Recarga: %1 s)")
    s = string.gsub(s, "%(%s*(%d+%.?%d*)%s*Hr%s*[Cc]ooldown%s*%)", "(Recarga: %1 h)")

    -- Efeito canônico da Pedra de Regresso (Hearthstone)
    s = string.gsub(s, "[Rr]eturns?%s+you%s+to%s+([^%.]+)%.%s*[Ss]peak to an [Ii]nnkeeper in a different place to change your home location%.?", "Retorna você a %1. Fale com um Estalajadeiro em outro local para mudar sua pedra de regresso.")
    s = string.gsub(s, "[Rr]eturns?%s+to%s+([^%.]+)%.%s*Speak to an [Ii]nnkeeper in a different place to change your home location%.?", "Retorna a %1. Fale com um Estalajadeiro em outro local para mudar sua pedra de regresso.")
    s = string.gsub(s, "[Rr]eturns?%s+you%s+to%s+([^%.]+)%.?", "Retorna você a %1.")
    s = string.gsub(s, "[Rr]eturns?%s+to%s+([^%.]+)%.?", "Retorna a %1.")
    s = string.gsub(s, "Speak to an [Ii]nnkeeper in a different place to change your home location%.?", "Fale com um Estalajadeiro em outro local para mudar sua pedra de regresso.")

    -- Comidas, Bebidas e Bandagens
    s = string.gsub(s, "Must remain seated while eating%.?", "Deve permanecer sentado enquanto come.")
    s = string.gsub(s, "Must remain seated while drinking%.?", "Deve permanecer sentado enquanto bebe.")
    s = string.gsub(s, "Heals (%d+) damage over (%d+) sec%.?", "Cura %1 de dano ao longo de %2 s.")
    s = string.gsub(s, "Recently Bandaged", "Enfaixado Recentemente")

    -- 6b. Motor Semântico Universal para efeitos de Uso / Equipar / Chance e instruções de itens
    if CM_Grammar_ptBR and CM_Grammar_ptBR.TranslateUniversal then
        local prefix, effect = nil, nil
        if string.find(s, "^Uso:%s*(.+)") then
            prefix = "Uso: "
            local _, _, ef = string.find(s, "^Uso:%s*(.+)")
            effect = ef
        elseif string.find(s, "^Equipar:%s*(.+)") then
            prefix = "Equipar: "
            local _, _, ef = string.find(s, "^Equipar:%s*(.+)")
            effect = ef
        elseif string.find(s, "^Chance ao acertar:%s*(.+)") then
            prefix = "Chance ao acertar: "
            local _, _, ef = string.find(s, "^Chance ao acertar:%s*(.+)")
            effect = ef
        else
            local u = CM_Grammar_ptBR.TranslateUniversal(s)
            if u and u ~= "" and u ~= s then
                s = u
            end
        end
        if prefix and effect then
            local u = CM_Grammar_ptBR.TranslateUniversal(effect)
            if u and u ~= "" then
                s = prefix .. u
            end
        end
    end

    -- 7. Efeitos Frequentes de Poções, Comidas e Itens
    s = string.gsub(s, "Restores (%d+ to %d+) health%.", "Restaura %1 de vida.")
    s = string.gsub(s, "Restores (%d+) to (%d+) health%.", "Restaura %1 a %2 de vida.")
    s = string.gsub(s, "Restores (%d+) health over (%d+) sec%.", "Restaura %1 de vida ao longo de %2 s.")
    s = string.gsub(s, "Restores (%d+ to %d+) mana%.", "Restaura %1 de mana.")
    s = string.gsub(s, "Restores (%d+) to (%d+) mana%.", "Restaura %1 a %2 de mana.")
    s = string.gsub(s, "Restores (%d+) mana over (%d+) sec%.", "Restaura %1 de mana ao longo de %2 s.")
    s = string.gsub(s, "Increases attack power by (%d+)%.", "Aumenta o poder de ataque em %1.")
    s = string.gsub(s, "Increases armor by (%d+)%.", "Aumenta a armadura em %1.")
    s = string.gsub(s, "Increases Stamina by (%d+) for (%d+) min%.", "Aumenta o Vigor em %1 por %2 min.")
    s = string.gsub(s, "Increases Strength by (%d+) for (%d+) min%.", "Aumenta a Força em %1 por %2 min.")
    s = string.gsub(s, "Increases Intellect by (%d+) for (%d+) min%.", "Aumenta o Intelecto em %1 por %2 min.")
    s = string.gsub(s, "Increases Agility by (%d+) for (%d+) min%.", "Aumenta a Agilidade em %1 por %2 min.")
    s = string.gsub(s, "Increases Spirit by (%d+) for (%d+) min%.", "Aumenta o Espírito em %1 por %2 min.")
    s = string.gsub(s, "Increases defense by (%d+)%.", "Aumenta a defesa em %1.")
    s = string.gsub(s, "Increases spell damage and healing by up to (%d+)%.", "Aumenta o dano mágico e a cura em até %1.")
    s = string.gsub(s, "Increases damage and healing done by magical spells and effects by up to (%d+)%.", "Aumenta o dano e a cura realizados por feitiços e efeitos mágicos em até %1.")
    s = string.gsub(s, "Increases healing done by spells and effects by up to (%d+)%.", "Aumenta a cura realizada por feitiços e efeitos em até %1.")
    s = string.gsub(s, "Restores (%d+) mana per 5 sec%.", "Restaura %1 de mana a cada 5 s.")
    s = string.gsub(s, "Improves your chance to get a critical strike by (%d+)%%%.?", "Aumenta sua chance de conseguir um acerto crítico em %1%%.")
    s = string.gsub(s, "Improves your chance to hit with all spells and attacks by (%d+)%%%.?", "Aumenta sua chance de acertar com todos os feitiços e ataques em %1%%.")

    -- Ranges numéricos 'to' -> 'a'
    s = string.gsub(s, "(%d+)%s+to%s+(%d+)", "%1 a %2")

    return s
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
CM_RegisterLang("ptBR", "Português (Brasil)", "Data\\Locales\\ptBR\\UI.lua", "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Locales\\ptBR\\flag_ptBR.tga")
CM_RegisterLang("enUS", "English (US)", "Data\\Locales\\enUS\\UI.lua", "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Locales\\enUS\\flag_enUS.tga")

-- Resolve cedo com default. VARIABLES_LOADED resolve de novo com SavedVariables.
CM:ResolveLocale()
