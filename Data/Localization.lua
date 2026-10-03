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

-- Gate central das traducoes procedurais de jogo (GameLOC_).
-- Sem o irmao LoadOnDemand carregado nao ha DB; traduzir mesmo assim
-- (via MAPs/gsub do Core) mistura PT no cliente EN. Fechado = EN prevalece.
function CM:IsGameLOCActive()
    if self:GetActiveLangId() == "enUS" then return false end
    if self.DataLake and self.DataLake.loaded then return true end
    if self.GetLocalizationAddonName and IsAddOnLoaded then
        local addon = self:GetLocalizationAddonName()
        if IsAddOnLoaded(addon) then return true end
    end
    if IsAddOnLoaded then
        if IsAddOnLoaded("ConsoleModeVanilla-Localization-ptBR") then return true end
        if IsAddOnLoaded("ConsoleModeVanilla-Localization") then return true end
        if IsAddOnLoaded("ConsoleModeVanilla-Data") then return true end
    end
    return false
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
    -- Ultimo recurso: enUS (Core carrega sem Localization; default pode faltar)
    if langId ~= "enUS" and CM_DEFAULT_LANG ~= "enUS" then
        local en = CM_Langs["enUS"]
        if en and en.strings then
            local e = en.strings[key]
            if e and e ~= "" then
                return e
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
            -- Ultimo recurso: enUS (Core carrega sem Localization; default pode faltar)
            local en = CM_Langs["enUS"]
            if en and en.strings then
                ConsoleMode.L = en.strings
            else
                ConsoleMode.L = {}
            end
        end
        langId = CM_DEFAULT_LANG
    end
    -- OctoWoW: avisa uma vez por sessao quando a camada ativa via auto-detect.
    -- ResolveLocale roda no load (DEFAULT_CHAT_FRAME pode nao existir ainda)
    -- e de novo em VARIABLES_LOADED via Core.lua, onde o aviso de fato sai.
    if not self._octoNotified and DEFAULT_CHAT_FRAME and self:GetOctoMode() == "auto" and self:IsOctoRealm() and self:GetActiveLangId() == CM_DEFAULT_LANG then
        self._octoNotified = true
        local rn = ""
        if type(GetRealmName) == "function" and GetRealmName() then
            rn = GetRealmName()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r " .. format(self:T("OCTO_AUTO_MSG"), rn))
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
-- OctoWoW: deteccao por substring do reino + toggle de 3 estados.
-- O Octo troca o nome do reino com frequencia, por isso o match e por
-- substring ("octo" em qualquer parte, case-insensitive), nunca exato.
-- ConsoleModeDB.octoCompat: "auto" (default, segue o reino), "on", "off".
-- O overlay Octo e camada de traducao PT: fora do ptBR ele nunca ativa.
---------------------------------------------------------------------------
function CM:IsOctoRealm()
    local function hasOcto(s)
        if not s or s == "" then
            return false
        end
        return string.find(string.lower(s), "octo", 1, 1) ~= nil
    end
    -- 1. Nome do reino (API).
    if type(GetRealmName) == "function" then
        local rn = GetRealmName()
        if hasOcto(rn) then
            return true
        end
    end
    if type(GetCVar) ~= "function" then
        return false
    end
    -- 2. Nome do reino (CVar) — pode diferir da API em alguns clientes.
    local ok, cvRealm = pcall(GetCVar, "realmName")
    if ok and hasOcto(cvRealm) then
        return true
    end
    -- 3. Endereco do realmlist — o realm pode ter nome neutro ("Fun Server")
    -- mas o logon do Octo carrega "octo" no endereco.
    local okList, cvList = pcall(GetCVar, "realmList")
    if okList and hasOcto(cvList) then
        return true
    end
    return false
end

function CM:GetOctoMode()
    if ConsoleModeDB and ConsoleModeDB.octoCompat then
        local m = ConsoleModeDB.octoCompat
        if m == "on" or m == "off" or m == "auto" then
            return m
        end
        if m == true then
            return "on"
        end
        if m == false then
            return "off"
        end
    end
    return "auto"
end

function CM:IsOctoActive()
    local mode = self:GetOctoMode()
    if mode == "on" then
        return true
    end
    if mode == "off" then
        return false
    end
    if self:GetActiveLangId() ~= CM_DEFAULT_LANG then
        return false
    end
    return self:IsOctoRealm()
end

function CM:CycleOctoMode()
    local cur = self:GetOctoMode()
    local nxt = "on"
    if cur == "auto" then
        nxt = "on"
    elseif cur == "on" then
        nxt = "off"
    else
        nxt = "auto"
    end
    if not ConsoleModeDB then
        ConsoleModeDB = {}
    end
    ConsoleModeDB.octoCompat = nxt
    return nxt
end

-- Trata /cm octo [auto|on|off]. Sem arg mostra o estado atual.
function CM:HandleOctoCommand(arg)
    local want = arg or ""
    want = string.lower(want)
    want = string.gsub(want, "^%s+", "")
    want = string.gsub(want, "%s+$", "")
    local mode = nil
    if want == "auto" or want == "automatico" then
        mode = "auto"
    elseif want == "on" or want == "ligado" or want == "ativado" or want == "1" then
        mode = "on"
    elseif want == "off" or want == "desligado" or want == "desativado" or want == "0" then
        mode = "off"
    elseif want == "" then
        local rn = ""
        if type(GetRealmName) == "function" and GetRealmName() then
            rn = GetRealmName()
        end
        local rl = ""
        if type(GetCVar) == "function" then
            local okList, cvList = pcall(GetCVar, "realmList")
            if okList and cvList then
                rl = cvList
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r " .. format(self:T("OCTO_STATUS_FMT"), self:T("SYS_CFG_OCTO_" .. string.upper(self:GetOctoMode())), rn, rl))
        return
    end
    if not mode then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r " .. self:T("OCTO_USAGE"))
        return
    end
    if not ConsoleModeDB then
        ConsoleModeDB = {}
    end
    ConsoleModeDB.octoCompat = mode
    self:ResolveLocale()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r " .. format(self:T("OCTO_CHANGED_FMT"), self:T("SYS_CFG_OCTO_" .. string.upper(mode))))
    ReloadUI()
end

---------------------------------------------------------------------------
-- Acessores GameLOC (Fase 7 - Localizacao de Conteudo de Jogo)
---------------------------------------------------------------------------

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_Skill(skillName)
    if not self:IsGameLOCActive() then return skillName or "" end
    if self:GetActiveLangId() == "enUS" then return skillName or "" end
    return skillName or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_Rank(rankStr)
    if not self:IsGameLOCActive() then return rankStr or "" end
    if self:GetActiveLangId() == "enUS" then return rankStr or "" end
    return rankStr or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_Spell(spellName, rankStr)
    if not self:IsGameLOCActive() then return spellName or "" end
    if self:GetActiveLangId() == "enUS" then return spellName or "" end
    return spellName or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_SpellAttr(attrText)
    if not self:IsGameLOCActive() then return attrText or "" end
    if self:GetActiveLangId() == "enUS" then return attrText or "" end
    return attrText or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_SpellTool(line)
    if not self:IsGameLOCActive() then return line end
    if self:GetActiveLangId() == "enUS" then return line end
    return line
end

-- EN stub (Fase 3b-engine): Core returns nil; PT override lives in sibling.
function CM:GameLOC_ApplySpell(entry, liveNorm)
    if not self:IsGameLOCActive() then return nil end
    if self:GetActiveLangId() == "enUS" then return nil end
    return nil
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_SpellDesc(spellName, rankStr, rawDesc)
    if not self:IsGameLOCActive() then return rawDesc or "" end
    if self:GetActiveLangId() == "enUS" then return rawDesc or "" end
    return rawDesc or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_Talent(a1, a2, a3, a4, a5)
    local origName = a5
    if origName == nil then
        origName = a2
    end
    if origName == nil then
        origName = ""
    end
    if not self:IsGameLOCActive() then return origName, origName end
    if self:GetActiveLangId() == "enUS" then return origName, origName end
    return origName, origName
end

-- EN stub (Fase 3b-engine): Core reports no header; PT override lives in sibling.
function CM:GameLOC_IsTalentHeaderLine(rawLine)
    if not self:IsGameLOCActive() then return false end
    if self:GetActiveLangId() == "enUS" then return false end
    return false
end

-- EN stub (Fase 3b-engine): Core returns no values; PT override lives in sibling.
function CM:GameLOC_ExtractSemanticValues(rawLine, tEntry)
    if not self:IsGameLOCActive() then return {} end
    if self:GetActiveLangId() == "enUS" then return {} end
    return {}
end

-- EN stub (Fase 3b-engine): Core returns nil; PT override lives in sibling.
function CM:GameLOC_MatchTemplateValues(enTemplate, renderedText)
    if not self:IsGameLOCActive() then return nil end
    if self:GetActiveLangId() == "enUS" then return nil end
    return nil
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_TalentLine(classFile, tabIndex, tier, col, talentName, rawLine, currentRank)
    if not self:IsGameLOCActive() then return rawLine or "" end
    if self:GetActiveLangId() == "enUS" then return rawLine or "" end
    return rawLine or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_TalentDesc(classFile, tabIndex, tier, col, currentRank, maxRank, talentName, rawDesc)
    if not self:IsGameLOCActive() then return rawDesc or "" end
    if self:GetActiveLangId() == "enUS" then return rawDesc or "" end
    return rawDesc or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_Buff(buffName)
    if not self:IsGameLOCActive() then return buffName or "" end
    if self:GetActiveLangId() == "enUS" then return buffName or "" end
    return buffName or ""
end

---------------------------------------------------------------------------
-- Tradução de Conteúdo de Itens e Inventário (Fase 7.5)
---------------------------------------------------------------------------

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_Item(itemName, itemLinkOrID)
    if not self:IsGameLOCActive() then return itemName or "" end
    if self:GetActiveLangId() == "enUS" then return itemName or "" end
    return itemName or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_EquipLoc(equipLoc)
    if not self:IsGameLOCActive() then return equipLoc or "" end
    if self:GetActiveLangId() == "enUS" then return equipLoc or "" end
    return equipLoc or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_ItemSubType(subType)
    if not self:IsGameLOCActive() then return subType or "" end
    if self:GetActiveLangId() == "enUS" then return subType or "" end
    return subType or ""
end

-- EN stub (Fase 3b-engine): Core echoes input; PT override lives in sibling.
function CM:GameLOC_ItemStat(statLine)
    if not self:IsGameLOCActive() then return statLine or "" end
    if self:GetActiveLangId() == "enUS" then return statLine or "" end
    return statLine or ""
end

-- EN stub (Fase 3b-engine): Core returns nil; PT override lives in sibling.
function CM:GameLOC_ItemDesc(itemLinkOrID, liveLine)
    if not self:IsGameLOCActive() then return nil end
    if self:GetActiveLangId() == "enUS" then return nil end
    return nil
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

---------------------------------------------------------------------------
-- Aliases legados GamePT_ (retrocompatibilidade, zero regressao).
-- A API canonica e GameLOC_. Estes aliases garantem que qualquer chamada
-- antiga (addon externo ou linha obscura) continue funcionando.
---------------------------------------------------------------------------
CM.GamePT_Skill = CM.GameLOC_Skill
CM.GamePT_Rank = CM.GameLOC_Rank
CM.GamePT_Spell = CM.GameLOC_Spell
CM.GamePT_SpellAttr = CM.GameLOC_SpellAttr
CM.GamePT_SpellTool = CM.GameLOC_SpellTool
CM.GamePT_ApplySpellPT = CM.GameLOC_ApplySpell
CM.GamePT_SpellDesc = CM.GameLOC_SpellDesc
CM.GamePT_Talent = CM.GameLOC_Talent
CM.GamePT_IsTalentHeaderLine = CM.GameLOC_IsTalentHeaderLine
CM.GamePT_ExtractSemanticValues = CM.GameLOC_ExtractSemanticValues
CM.GamePT_MatchTemplateValues = CM.GameLOC_MatchTemplateValues
CM.GamePT_TalentLine = CM.GameLOC_TalentLine
CM.GamePT_TalentDesc = CM.GameLOC_TalentDesc
CM.GamePT_Buff = CM.GameLOC_Buff
CM.GamePT_Item = CM.GameLOC_Item
CM.GamePT_EquipLoc = CM.GameLOC_EquipLoc
CM.GamePT_ItemSubType = CM.GameLOC_ItemSubType
CM.GamePT_ItemStat = CM.GameLOC_ItemStat
CM.GamePT_ItemDesc = CM.GameLOC_ItemDesc
