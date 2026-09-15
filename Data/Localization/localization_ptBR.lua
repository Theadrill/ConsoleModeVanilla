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
    -- FASE 2: CharacterScreen (ficha do personagem). Valores byte-identicos
    -- aos hardcoded originais de UI/CharacterScreen.lua (UTF-8 sem BOM).
    -- Chaves _FMT vao ao format() no codigo (%% = % literal); demais vao
    -- diretas ao SetText. |cff sempre DENTRO do valor, nunca no codigo.
    -- Titulos dos cards (CS_MakeCard).
    CHAR_TITLE_IDENT = "IDENTIDADE & BIOGRAFIA",
    CHAR_TITLE_BASE = "ATRIBUTOS PRIMÁRIOS (BASE STATS)",
    CHAR_TITLE_RES = "RECURSOS & REGENERAÇÃO",
    CHAR_TITLE_MELEE = "COMBATE CORPO A CORPO (MELEE)",
    CHAR_TITLE_MELEE_BOSS = "MELEE VS BOSS (NÍVEL 63)",
    CHAR_TITLE_RANGED = "COMBATE A DISTÂNCIA (RANGED)",
    CHAR_TITLE_SPELL = "PODER MÁGICO (SPELL)",
    CHAR_TITLE_SCHOOLS = "ESCOLAS DE MAGIA (SCHOOLS)",
    CHAR_TITLE_DEF = "DEFESA & SOBREVIVÊNCIA",
    CHAR_TITLE_DEF_BOSS = "DEFESA VS BOSS (NÍVEL 63)",
    CHAR_TITLE_RESIST = "RESISTÊNCIAS ELEMENTAIS",
    CHAR_TITLE_WEAPON = "PERÍCIAS DE ARMAS",
    CHAR_TITLE_PROF = "PROFISSÕES",
    CHAR_TITLE_SEC = "OFÍCIOS",
    CHAR_TITLE_REP = "REPUTAÇÕES",
    CHAR_TITLE_HONOR = "HONRA & JXJ (PVP)",
    CHAR_TITLE_HONOR_COLORED = "|cffc03028HONRA & JXJ (PVP)|r",
    CHAR_TITLE_LANG = "IDIOMAS & RACIAIS",
    -- DetailCard (rodape): titulo + corpo (corpo com \n separa as 2 linhas).
    CHAR_DETAIL_IDENT_TITLE = "Identidade",
    CHAR_DETAIL_IDENT_BODY = "Nome, nível, raça, guilda e XP.\nDescansado = bônus de XP; Turtle/Hardcore ativo.",
    CHAR_DETAIL_BASE_TITLE = "Base",
    CHAR_DETAIL_BASE_BODY = "For/Agi/Vig/Int/Esp + Armadura.\nAgi: +2 Armadura/cada; +crítico/esquiva. Verde (+X) = buffs.",
    CHAR_DETAIL_RES_TITLE = "Recursos",
    CHAR_DETAIL_RES_BODY = "Vida/Mana/Fúria/Energia atuais.\nRegen Mana = base(Esp) + MP5x0,4; em combate só % casting.",
    CHAR_DETAIL_MELEE_TITLE = "Melee",
    CHAR_DETAIL_MELEE_BODY = "Perícia, dano, velocidade e AP.\n14 AP = 1 DPS no dano da arma. Hit reduz erro.",
    CHAR_DETAIL_MELEEBOSS_TITLE = "Melee vs Boss",
    CHAR_DETAIL_MELEEBOSS_BODY = "Melee vs alvo nv 63 (+3).\nMiss/Dodge sobem; Glancing ~40%; Crit Cap limita crítico.",
    CHAR_DETAIL_RANGED_TITLE = "Ranged",
    CHAR_DETAIL_RANGED_BODY = "Arco/arma/faca: dano, DPS e RAP.\nVarinha ignora RAP (dano mágico). Hit como no melee.",
    CHAR_DETAIL_SPELL_TITLE = "Spell",
    CHAR_DETAIL_SPELL_BODY = "Spell Power, hit/crítico e +Heal.\nHit evita erro; crítico +50% dano (cura dobra c/ talento).",
    CHAR_DETAIL_SCHOOLS_TITLE = "Escolas",
    CHAR_DETAIL_SCHOOLS_BODY = "Bônus por escola somam ao genérico.\nVerde = bônus próprio; total = genérico + escola.",
    CHAR_DETAIL_DEF_TITLE = "Defesa",
    CHAR_DETAIL_DEF_BODY = "Armadura reduz dano físico %.\nDefesa + esquiva/aparo/bloqueio; Total = miss 5% + tudo.",
    CHAR_DETAIL_DEFBOSS_TITLE = "Defesa vs Boss",
    CHAR_DETAIL_DEFBOSS_BODY = "Defesa vs nv 63.\n-0,6% esquiva/aparo/bloqueio; armadura vale menos %.",
    CHAR_DETAIL_RESIST_TITLE = "Resistências",
    CHAR_DETAIL_RESIST_BODY = "Fogo/Nat/Gelo/Sombra/Arcano X/100.\n100 = teto prático; (+) buff, (-) penalidade.",
    CHAR_DETAIL_WEAPON_TITLE = "Armas",
    CHAR_DETAIL_WEAPON_BODY = "Perícias X/max por arma (barras).\nUse a arma p/ subir; +5 perícia = -miss/glancing.",
    CHAR_DETAIL_PROF_TITLE = "Profissões",
    CHAR_DETAIL_PROF_BODY = "Primárias (max 2) X/max.\nSuba criando itens; bônus de gear contam no modificador.",
    CHAR_DETAIL_SEC_TITLE = "Ofícios",
    CHAR_DETAIL_SEC_BODY = "Culinária/Primeiros Socorros/Pesca.\nSem limite; cozinhar/pescar dão regen e buffs.",
    CHAR_DETAIL_REP_TITLE = "Reputações",
    CHAR_DETAIL_REP_BODY = "Barras por facção + status.\nExaltado = desconto e itens; barra cheia sobe nível.",
    CHAR_DETAIL_HONOR_TITLE = "Honra",
    CHAR_DETAIL_HONOR_BODY = "Posto, progresso semanal e HKs.\nHKs hoje/ontem/vida; posto sobe c/ honra semanal.",
    CHAR_DETAIL_LANG_TITLE = "Idiomas",
    CHAR_DETAIL_LANG_BODY = "Idiomas falados + raciais.\nRaciais são fixas da raça; ver spellbook (K = skills).",
    -- Nomes de atributos e escolas (labels do addon; valores do jogo entram via format).
    CHAR_STAT_STR = "Força",
    CHAR_STAT_AGI = "Agilidade",
    CHAR_STAT_STA = "Vigor",
    CHAR_STAT_INT = "Intelecto",
    CHAR_STAT_SPI = "Espírito",
    CHAR_SCHOOL_ARCANE = "Arcano",
    CHAR_SCHOOL_FIRE = "Fogo",
    CHAR_SCHOOL_FROST = "Gelo",
    CHAR_SCHOOL_HOLY = "Sagrado",
    CHAR_SCHOOL_NATURE = "Natureza",
    CHAR_SCHOOL_SHADOW = "Sombra",
    -- Tipos de poder (Recursos).
    CHAR_POWER_MANA = "Mana",
    CHAR_POWER_RAGE = "Fúria",
    CHAR_POWER_ENERGY = "Energia",
    -- Modos Turtle/Hardcore.
    CHAR_MODE_HARDCORE = "Modo: Hardcore Ativo",
    CHAR_MODE_TURTLE = "Modo: Turtle Ativo",
    CHAR_MODE_NORMAL = "Modo: Normal",
    -- Card Identidade.
    CHAR_IDENT_NAME_FMT = "|cffffffff%s|r  Niv %s",
    CHAR_IDENT_GUILD_FMT = "Guilda: %s (%s)",
    CHAR_IDENT_NO_GUILD = "Guilda: Sem guilda",
    CHAR_IDENT_RANK_FMT = "Posto: %s (Rank %s)",
    CHAR_IDENT_NO_RANK = "Posto: Sem posto",
    CHAR_IDENT_RANK_UNKNOWN = "Sem posto",
    CHAR_IDENT_XP_REST_FMT = "XP: %s/%s (%s%%)  Descansado",
    CHAR_IDENT_XP_FMT = "XP: %s/%s (%s%%)",
    -- Card Base (stats + armadura; sufixo generico de modificador).
    CHAR_BASE_STAT_FMT = "%s: %s",
    CHAR_BASE_ARMOR_FMT = "Armadura: %s",
    CHAR_MOD_POS_FMT = "(+%s)|r",
    CHAR_MOD_NEG_FMT = "(%s)|r",
    -- Card Recursos.
    CHAR_RES_HP_FMT = "Vida: %s / %s",
    CHAR_RES_MP_FMT = "%s: %s / %s",
    CHAR_RES_HP_REGEN_NONE = "Regen. Vida: — (sem fórmula na 1.12)",
    CHAR_RES_MANA_FMT = "Regen. Mana: %d (%d MP2 em combate)",
    CHAR_RES_MANA_SIMPLE_FMT = "Regen. Mana: %d MP2",
    CHAR_RES_NONMANA_FMT = "Regen. %s: — (sem fórmula na 1.12)",
    -- Card Melee.
    CHAR_MELEE_SKILL_DUAL_FMT = "Perícia de Arma: %s | %s",
    CHAR_MELEE_SKILL_FMT = "Perícia de Arma: %s",
    CHAR_MELEE_DMG_FMT = "Dano: %s-%s  DPS: %s",
    CHAR_MELEE_SPEED_FMT = "Velocidade: %ss",
    CHAR_MELEE_AP_FMT = "Poder de Ataque: %s",
    CHAR_MELEE_HIT_FMT = "Acerto (Hit): +%s%%",
    CHAR_MELEE_CRIT_FMT = "Crítico: %s%%",
    CHAR_MELEE_CRIT_NONE = "Crítico: —",
    -- Card Melee vs Boss.
    CHAR_BOSS_MISS_DUAL_FMT = "Miss vs Boss: %s%% | %s%%",
    CHAR_BOSS_MISS_FMT = "Miss vs Boss: %s%%",
    CHAR_BOSS_DODGE_DUAL_FMT = "Dodge vs Boss: %s%% | %s%%",
    CHAR_BOSS_DODGE_FMT = "Dodge vs Boss: %s%%",
    CHAR_BOSS_GLANCE_DUAL_FMT = "Glancing: %s%% | %s%%",
    CHAR_BOSS_GLANCE_FMT = "Glancing: %s%%",
    CHAR_BOSS_CAP_DUAL_FMT = "Crit Cap: %s%% | %s%%",
    CHAR_BOSS_CAP_FMT = "Crit Cap: %s%%",
    CHAR_BOSS_EFF_DUAL_FMT = "Crítico Efetivo: %s%% | %s%%",
    CHAR_BOSS_EFF_FMT = "Crítico Efetivo: %s%%",
    CHAR_BOSS_EFF_NONE = "Crítico Efetivo: —",
    -- Card Ranged.
    CHAR_RANGED_SKILL_FMT = "Perícia Ranged: %s",
    CHAR_RANGED_NO_WEAPON = "Dano: — (sem arma de longo alcance)",
    CHAR_RANGED_NO_SPEED = "Velocidade: —",
    CHAR_RANGED_NO_RAP = "Poder de Ataque (dist.): —",
    CHAR_RANGED_RAP_FMT = "Poder de Ataque (dist.): %s",
    CHAR_RANGED_CRIT_FMT = "Crítico (dist.): %s%%",
    -- Card Spell.
    CHAR_SPELL_POWER_FMT = "Spell Power: +%s",
    CHAR_SPELL_POWER_SEC_FMT = "Spell Power: +%s (%s)",
    CHAR_SPELL_HIT_FMT = "Hit Mágico: +%s%%",
    CHAR_SPELL_CRIT_FMT = "Crítico Mágico: %s%%",
    CHAR_SPELL_HEAL_FMT = "Poder de Cura (+Heal): +%s",
    CHAR_SPELL_REGEN_FMT = "Regen. Mana: %d (%d em combate)",
    CHAR_SPELL_NO_MANA = "Regen. Mana: — (sem mana)",
    CHAR_SPELL_HASTE_FMT = "Spell Haste: %s%%",
    -- Card Escolas (linha por escola).
    CHAR_SCHOOL_LINE_FMT = "%s: +%s",
    -- Cards Defesa e Defesa vs Boss.
    CHAR_DEF_ARMOR_FMT = "Armadura: %s (%s%% vs niv %s)",
    CHAR_DEFBOSS_ARMOR_FMT = "Armadura: %s (%s%% vs niv 63)",
    CHAR_DEF_DEFENSE_FMT = "Defesa: %s / %s",
    CHAR_DEF_NO_DEFENSE = "Defesa: —",
    CHAR_DEF_DODGE_FMT = "Esquiva: %s%%",
    CHAR_DEF_NO_DODGE = "Esquiva: —",
    CHAR_DEF_PARRY_FMT = "Aparo: %s%%",
    CHAR_DEF_NO_PARRY = "Aparo: —",
    CHAR_DEF_BLOCK_FMT = "Bloqueio: %s%%",
    CHAR_DEF_NO_BLOCK = "Bloqueio: —",
    CHAR_DEF_TOTAL_FMT = "Esquiva Total: %s%%",
    CHAR_DEF_NO_TOTAL = "Esquiva Total: —",
    -- Card Resistencias (linha por escola).
    CHAR_RES_LINE_FMT = "%s: %s / 100",
    -- Linhas de pericia/profissao (nome do jogo entra via format; cor dentro do valor).
    CHAR_SKILL_LINE_FMT = "%s  %s/%s",
    CHAR_SKILL_MOD_FMT = " |cff20ff20(+%s)|r",
    -- Card Pericias de Armas.
    CHAR_WEAPON_NO_HEADER = "Perícias: — (cabeçalho não achado)",
    CHAR_WEAPON_NONE = "Sem perícias de arma",
    CHAR_WEAPON_MORE_FMT = "... (+%s ver SkillFrame K)",
    -- Cards Profissoes / Oficios.
    CHAR_PROF_NONE = "Sem profissões",
    CHAR_PROF_MORE_FMT = "... (+%s ver SkillFrame K)",
    CHAR_SEC_NONE = "Sem ofícios",
    CHAR_SEC_MORE_FMT = "... (+%s ver SkillFrame K)",
    -- Card Reputacoes.
    CHAR_REP_NONE = "Sem reputações",
    CHAR_REP_MORE_FMT = "... (+%s ver Reputação U)",
    CHAR_STANDING_1 = "Odiado",
    CHAR_STANDING_2 = "Hostil",
    CHAR_STANDING_3 = "Inamistoso",
    CHAR_STANDING_4 = "Neutro",
    CHAR_STANDING_5 = "Amistoso",
    CHAR_STANDING_6 = "Honrado",
    CHAR_STANDING_7 = "Reverenciado",
    CHAR_STANDING_8 = "Exaltado",
    -- Card Honra.
    CHAR_HONOR_RANK_FMT = "Posto atual: %s (Rank %s)",
    CHAR_HONOR_RANK_NUM_FMT = "Posto atual: Rank %s",
    CHAR_HONOR_NO_RANK = "Posto atual: Sem posto",
    CHAR_HONOR_PROGRESS_FMT = "Progresso semanal: %s%%",
    CHAR_HONOR_NO_PROGRESS = "Progresso semanal: —",
    CHAR_HONOR_TODAY_FMT = "Abates hoje: %s HKs (%s honra)",
    CHAR_HONOR_TODAY_HK_FMT = "Abates hoje: %s HKs",
    CHAR_HONOR_TODAY_NONE = "Abates hoje: —",
    CHAR_HONOR_YEST_FMT = "Abates ontem: %s HKs (%s honra)",
    CHAR_HONOR_YEST_HK_FMT = "Abates ontem: %s HKs",
    CHAR_HONOR_YEST_NONE = "Abates ontem: —",
    CHAR_HONOR_LIFE_FMT = "Total da vida: %s HKs",
    CHAR_HONOR_LIFE_NONE = "Total da vida: —",
    -- Card Idiomas & Raciais.
    CHAR_LANG_NONE = "Idiomas: — (ver SkillFrame K)",
    CHAR_LANG_ONE_FMT = "Idioma: %s",
    CHAR_LANG_MORE_FMT = "Idioma: %s (+%s outros)",
    CHAR_LANG_RACIAL_FMT = "Racial: %s",
    CHAR_LANG_RACIAL_OTHER_FMT = "Raciais (%s): ver spellbook",
    CHAR_LANG_NO_RACIAL = "Raciais: —",
    CHAR_RACIAL_HUMAN_1 = "Percepção",
    CHAR_RACIAL_HUMAN_2 = "Diplomacia (+10% rep.)",
    CHAR_RACIAL_HUMAN_3 = "Espírito Humano (+5% Esp.)",
    CHAR_RACIAL_HUMAN_4 = "Espadas +5",
    CHAR_RACIAL_DWARF_1 = "Resist. Gelo",
    CHAR_RACIAL_DWARF_2 = "Armas de Fogo +5",
    CHAR_RACIAL_DWARF_3 = "Localizar Tesouro",
    CHAR_RACIAL_DWARF_4 = "Forma de Pedra",
    CHAR_RACIAL_NIGHTELF_1 = "Rapidez (esquiva)",
    CHAR_RACIAL_NIGHTELF_2 = "Fusão na Sombra",
    CHAR_RACIAL_NIGHTELF_3 = "Espírito Wisp",
    CHAR_RACIAL_NIGHTELF_4 = "Resist. Natureza",
    CHAR_RACIAL_GNOME_1 = "Mente Expansiva (+5% Int)",
    CHAR_RACIAL_GNOME_2 = "Resist. Arcano",
    CHAR_RACIAL_GNOME_3 = "Artista da Fuga",
    CHAR_RACIAL_GNOME_4 = "Engenharia +15",
    CHAR_RACIAL_ORC_1 = "Rustidez (stun)",
    CHAR_RACIAL_ORC_2 = "Comando (pet)",
    CHAR_RACIAL_ORC_3 = "Machados +5",
    CHAR_RACIAL_ORC_4 = "Fúria Sangrenta",
    CHAR_RACIAL_UNDEAD_1 = "Vontade Renegada",
    CHAR_RACIAL_UNDEAD_2 = "Canibalizar",
    CHAR_RACIAL_UNDEAD_3 = "Respir. Subaquática",
    CHAR_RACIAL_UNDEAD_4 = "Resist. Sombra",
    CHAR_RACIAL_TAUREN_1 = "Vigor (+5% Vida)",
    CHAR_RACIAL_TAUREN_2 = "Cultivo (+15 Herb.)",
    CHAR_RACIAL_TAUREN_3 = "Resist. Natureza",
    CHAR_RACIAL_TAUREN_4 = "Pisão de Guerra",
    CHAR_RACIAL_TROLL_1 = "Regeneração",
    CHAR_RACIAL_TROLL_2 = "Mata-Feras",
    CHAR_RACIAL_TROLL_3 = "Arco/Arremesso +5",
    CHAR_RACIAL_TROLL_4 = "Berserk",
    -- Erros internos de chat (prefixo |cff fica no codigo, texto na tabela).
    CHAR_MSG_ATTACH_NIL = "AttachTo recebeu parent nil",
    CHAR_MSG_CREATEUI_FAIL = "CreateUI falhou (scrollFrame nil)",
    CHAR_MSG_SHOW_NIL = "Show com scrollFrame nil (AttachTo nao rodou?)",
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
