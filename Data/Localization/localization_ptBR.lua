--[[
    ConsoleMode - Vanilla
    Data/Localization/localization_ptBR.lua

    FASE 1 - Pacote piloto ptBR (base completa futura).
    Um arquivo = um id. Nunca declarar outro idioma aqui.
    Tabela plana CHAVE = "texto", sem nesting, sem metatables.
    Arquivo salvo em UTF-8 sem BOM. Acento so no valor, nunca na chave.
    Acesso sempre via CM:T("CHAVE"). Nunca indexar CM_Langs direto em UI.
]]

CM_Langs = CM_Langs or {}
CM_LANG_ORDER = CM_LANG_ORDER or {}

CM_Langs["ptBR"] = CM_Langs["ptBR"] or {}
CM_Langs["ptBR"].name = "Português (Brasil)"
CM_Langs["ptBR"].flag = "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Localization\\flag_ptBR.tga"
CM_Langs["ptBR"].strings = {
    TAB_BAGS = "Bolsas & Itens",
    TAB_CHARACTER = "Personagem",
    TAB_TALENTS = "Talentos",
    TAB_SPELLS = "Livro de Magias",
    TAB_QUESTS = "Missões",
    TAB_SYSTEM = "Sistema",
    BTN_CLOSE = "Sair",
    BTN_OK = "OK",
    BTN_CANCEL = "Cancelar",
    HINT_CONFIRM = "confirmar",
    HINT_CANCEL = "cancelar",
    HINT_CLOSE = "fechar",
    HINT_NAVIGATE = "navegar",
    HINT_SELECT = "selecionar",
    HINT_BACK = "voltar",
    HINT_RELOAD = "recarregar",
    MSG_LOADED_FMT = "v%s carregado.",
    MSG_VARIABLES_LOADED = "VARIABLES_LOADED disparou.",
    MSG_CHECKING_MODULES = "Verificando módulos...",
    MSG_RELOAD_REQUIRED = "É necessário /reload para aplicar.",
    LANG_TITLE = "Idioma / Language",
    LANG_ACTIVE_FMT = "Idioma ativo: %s",
    LANG_LIST_HEADER = "Idiomas disponíveis:",
    LANG_AVAILABLE_FMT = "%s - %s",
    LANG_USAGE_FMT = "Uso: /cm lang [%s]",
    LANG_CHANGED_FMT = "Idioma alterado para %s. Digite /reload para aplicar.",
    LANG_UNKNOWN_FMT = "Idioma desconhecido: \"%s\".",
    LANG_RELOAD_HINT = "Digite /reload para aplicar o novo idioma.",
    LANG_HELP_HINT = "Use /cm lang [id] para trocar de idioma.",
    LANG_CURRENT_FMT = "Atual: %s",
}

-- Defesa contra ordem de .toc invertida: garante ptBR na ordem.
do
    local want = "ptBR"
    local found = false
    local n = table.getn(CM_LANG_ORDER)
    local i = 1
    while i <= n do
        if CM_LANG_ORDER[i] == want then
            found = true
        end
        i = i + 1
    end
    if not found then
        table.insert(CM_LANG_ORDER, want)
    end
end
