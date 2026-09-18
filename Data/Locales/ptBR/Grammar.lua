-- ============================================================================
-- ConsoleModeVanilla - Data/Locales/ptBR/Grammar.lua
-- Motor Semântico Universal de Gramática e Vocabulário (ptBR)
-- Tradução procedural determinística baseada no padrão Blizzard pt-BR
-- WoW 1.12.1 / Lua 5.0 estrito (sem '#', sem 'continue', sem regex '|')
-- ============================================================================

CM_Grammar_ptBR = CM_Grammar_ptBR or {}

-- ----------------------------------------------------------------------------
-- 1. Dicionário Léxico de Escolas, Atributos, Perícias, Armas e Termos de Jogo
-- ----------------------------------------------------------------------------
CM_Grammar_ptBR.terms = {
    -- Escolas de Magia
    ["Fire"] = "Fogo",
    ["Frost"] = "Gelo",
    ["Nature"] = "Natureza",
    ["Shadow"] = "Sombra",
    ["Holy"] = "Sagrado",
    ["Arcane"] = "Arcano",
    ["Physical"] = "Físico",

    -- Atributos Primários e Secundários
    ["Stamina"] = "Vigor",
    ["Strength"] = "Força",
    ["Agility"] = "Agilidade",
    ["Intellect"] = "Intelecto",
    ["Spirit"] = "Espírito",
    ["Armor"] = "Armadura",
    ["Defense"] = "Defesa",
    ["attack power"] = "poder de ataque",
    ["Attack Power"] = "Poder de Ataque",
    ["melee attack power"] = "poder de ataque corpo a corpo",
    ["Melee Attack Power"] = "Poder de Ataque Corpo a Corpo",
    ["ranged attack power"] = "poder de ataque à distância",
    ["Ranged Attack Power"] = "Poder de Ataque à Distância",
    ["spell damage"] = "dano mágico",
    ["healing"] = "cura",
    ["Healing"] = "Cura",

    -- Perícias, Proficiências de Armas e Armaduras (Passivas)
    ["One-Handed Axes"] = "Machados de Uma Mão",
    ["Two-Handed Axes"] = "Machados de Duas Mãos",
    ["One-Handed Maces"] = "Maças de Uma Mão",
    ["Two-Handed Maces"] = "Maças de Duas Mãos",
    ["One-Handed Swords"] = "Espadas de Uma Mão",
    ["Two-Handed Swords"] = "Espadas de Duas Mãos",
    ["Polearms"] = "Armas de Haste",
    ["Staves"] = "Cajados",
    ["Staff"] = "Cajado",
    ["Daggers"] = "Adagas",
    ["Dagger"] = "Adaga",
    ["Fist Weapons"] = "Armas de Punho",
    ["Bows"] = "Arcos",
    ["Bow"] = "Arco",
    ["Crossbows"] = "Bestas",
    ["Crossbow"] = "Besta",
    ["Guns"] = "Armas de Fogo",
    ["Gun"] = "Arma de Fogo",
    ["Thrown"] = "Armas de Arremesso",
    ["Wands"] = "Varinhas",
    ["Wand"] = "Varinha",
    ["Shields"] = "Escudos",
    ["Shield"] = "Escudo",
    ["Cloth"] = "Tecido",
    ["Leather"] = "Couro",
    ["Mail"] = "Malha",
    ["Plate"] = "Placas",
    ["Plate Mail"] = "Armadura de Placas",
    ["Dual Wield"] = "Empunhar Duas Armas",
    ["Parry"] = "Aparo",
    ["Dodge"] = "Esquiva",
    ["Block"] = "Bloqueio",
    ["Shoot"] = "Disparo",
    ["Throw"] = "Arremesso",

    -- Categorias de Habilidades, Armas e Combate Comuns
    ["melee weapons"] = "armas corpo a corpo",
    ["ranged weapons"] = "armas de longo alcance",
    ["one-handed weapons"] = "armas de uma mão",
    ["two-handed weapons"] = "armas de duas mãos",
    ["one-handed melee weapons"] = "armas corpo a corpo de uma mão",
    ["two-handed melee weapons"] = "armas corpo a corpo de duas mãos",
    ["damaging spells"] = "feitiços de dano",
    ["healing spells"] = "feitiços de cura",
    ["offensive spells"] = "feitiços ofensivos",
    ["Shock spells"] = "feitiços de Choque",
    ["shock spells"] = "feitiços de Choque",
    ["Fire spells"] = "feitiços de Fogo",
    ["fire spells"] = "feitiços de Fogo",
    ["Frost spells"] = "feitiços de Gelo",
    ["frost spells"] = "feitiços de Gelo",
    ["Nature spells"] = "feitiços de Natureza",
    ["nature spells"] = "feitiços de Natureza",
    ["Shadow spells"] = "feitiços de Sombra",
    ["shadow spells"] = "feitiços de Sombra",
    ["Holy spells"] = "feitiços Sagrados",
    ["holy spells"] = "feitiços Sagrados",
    ["Arcane spells"] = "feitiços Arcanos",
    ["arcane spells"] = "feitiços Arcanos",
    ["melee attacks"] = "ataques corpo a corpo",
    ["ranged attacks"] = "ataques à distância",
    ["enemy melee attacks"] = "ataques corpo a corpo inimigos",
    ["enemy attacks"] = "ataques inimigos",
    ["critical strike"] = "acerto crítico",
    ["critical strikes"] = "acertos críticos",
    ["critical hit"] = "acerto crítico",
    ["critical hits"] = "acertos críticos",
    ["movement speed"] = "velocidade de movimento",
    ["attack speed"] = "velocidade de ataque",
    ["casting speed"] = "velocidade de lançamento",
    ["casting time"] = "tempo de lançamento",
    ["cast time"] = "tempo de lançamento",
    ["spells"] = "feitiços",
    ["spell"] = "feitiço",

    -- Formas e Posturas
    ["Bear Form"] = "Forma de Urso",
    ["Dire Bear Form"] = "Forma de Urso Hediondo",
    ["Cat Form"] = "Forma de Felino",
    ["Travel Form"] = "Forma de Viagem",
    ["Aquatic Form"] = "Forma Aquática",
    ["Moonkin Form"] = "Forma de Luniscado",
    ["Battle Stance"] = "Postura de Batalha",
    ["Defensive Stance"] = "Postura Defensiva",
    ["Berserker Stance"] = "Postura do Berserker",
    ["Stealth"] = "Furtividade",
    ["Shadowform"] = "Forma de Sombra",
    ["Ghost Wolf"] = "Lobo Fantasma",

    -- Alvos, Entidades e Preposições de Destino
    ["to the target"] = "ao alvo",
    ["to an enemy target"] = "a um alvo inimigo",
    ["to an enemy"] = "a um inimigo",
    ["to all nearby enemies"] = "a todos os inimigos próximos",
    ["to all enemies"] = "a todos os inimigos",
    ["to party members"] = "aos membros do grupo",
    ["to group members"] = "aos membros do grupo",
    ["to the caster"] = "ao lançador",
    ["at the feet of the caster"] = "aos pés do lançador",
    ["at your feet"] = "aos seus pés",
    ["In addition,"] = "Além disso,",
    ["in addition,"] = "além disso,",
    ["In addition"] = "Além disso",
    ["in addition"] = "além disso",
    ["The Crossroads"] = "Encruzilhada",
    ["the Crossroads"] = "Encruzilhada",
    ["Crossroads"] = "Encruzilhada",
    ["earthen fury"] = "fúria terrena",
    ["earthen"] = "terrena",
    ["Quest Item"] = "Item de Missão",
    ["Earthshaker Slam"] = "Golpe Abalador da Terra",
    ["earthshaker slam"] = "Golpe Abalador da Terra",
    ["Totemic Recall"] = "Revogação Totêmica",
    ["totemic recall"] = "Revogação Totêmica",
    ["Water Shield"] = "Escudo de Água",
    ["water shield"] = "Escudo de Água",
    ["Crusader Strike"] = "Golpe do Cruzado",
    ["crusader strike"] = "Golpe do Cruzado",
    ["Holy Strike"] = "Golpe Sagrado",
    ["holy strike"] = "Golpe Sagrado",
    ["the target"] = "o alvo",
    ["the enemy"] = "o inimigo",
    ["target"] = "alvo",
    ["friendly target"] = "alvo aliado",
    ["enemy target"] = "alvo inimigo",
    ["an enemy"] = "um inimigo",
    ["nearby enemies"] = "inimigos próximos",
    ["all nearby enemies"] = "todos os inimigos próximos",
    ["all enemies"] = "todos os inimigos",
    ["party members"] = "membros do grupo",
    ["group members"] = "membros do grupo",
    ["the caster"] = "o lançador",
    ["caster"] = "lançador",
    ["attacker"] = "atacante",

    -- Ameaça e Recursos
    ["Causes a high amount of threat"] = "Causa uma grande quantidade de ameaça",
    ["Causes a medium amount of threat"] = "Causa uma quantidade média de ameaça",
    ["causes a high amount of threat"] = "causa uma grande quantidade de ameaça",
    ["causes a medium amount of threat"] = "causa uma quantidade média de ameaça",
    ["threat"] = "ameaça",
    ["mana"] = "mana",
    ["Mana"] = "Mana",
    ["rage"] = "fúria",
    ["Rage"] = "Fúria",
    ["energy"] = "energia",
    ["Energy"] = "Energia",
    ["health"] = "vida",
    ["Health"] = "Vida",

    -- Restrições Comuns
    ["Only usable outdoors"] = "Só pode ser usado ao ar livre",
    ["Can only be used outdoors"] = "Só pode ser usado ao ar livre",
    ["Only usable in combat"] = "Só pode ser usado em combate",
    ["Cannot be used in combat"] = "Não pode ser usado em combate",
    ["Requires Stealth"] = "Requer Furtividade",
    ["Requires Shield"] = "Requer Escudo",
    ["Requires Shields"] = "Requer Escudo",
    ["Requires Melee Weapon"] = "Requer Arma Corpo a Corpo",
    ["Requires Ranged Weapon"] = "Requer Arma de Longo Alcance",
    ["Requires Daggers"] = "Requer Adagas",
    ["Requires Fishing Pole"] = "Requer Vara de Pesca",
}

-- ----------------------------------------------------------------------------
-- 2. Motor Heurístico de Tradução Semântica Universal
-- WoW 1.12.1 / Lua 5.0 (Padrões estritos sem operadores regex como '|' ou '#')
-- ----------------------------------------------------------------------------
function CM_Grammar_ptBR.TranslateUniversal(text)
    if not text or text == "" then return "" end

    local s = text

    -- 1. Normalização de Espaços e Quebras
    s = string.gsub(s, "%s+", " ")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")

    -- 2. Unidades de Medida e Prazos (Duração, Alcance, Cadência)
    s = string.gsub(s, "([%d%.]+)%s*seconds", "%1 s")
    s = string.gsub(s, "([%d%.]+)%s*sec", "%1 s")
    s = string.gsub(s, "([%d%.]+)%s*minutes", "%1 min")
    s = string.gsub(s, "([%d%.]+)%s*min", "%1 min")
    s = string.gsub(s, "([%d%.]+)%s*hours?", "%1 h")
    s = string.gsub(s, "([%d%.]+)%s*hr", "%1 h")
    s = string.gsub(s, "([%d%.]+)%s*yards", "%1 metros")
    s = string.gsub(s, "([%d%.]+)%s*yds", "%1 metros")
    s = string.gsub(s, "([%d%.]+)%s*yd", "%1 metros")

    -- 3. Efeitos de Equipamento (Equip: / Use: / Chance on hit:)
    s = string.gsub(s, "^Equip:%s*", "Equipar: ")
    s = string.gsub(s, "^Use:%s*", "Uso: ")
    s = string.gsub(s, "^Chance on hit:%s*", "Chance ao acertar: ")

    s = string.gsub(s, "Increases damage and healing done by magical spells and effects by up to (%d+)%.?", "Aumenta o dano e a cura de feitiços e efeitos mágicos em até %1.")
    s = string.gsub(s, "Increases healing done by spells and effects by up to (%d+)%.?", "Aumenta a cura de feitiços e efeitos em até %1.")
    s = string.gsub(s, "Improves your chance to get a critical strike by (%d+)%%%.?", "Aumenta sua chance de acerto crítico em %1%%.")
    s = string.gsub(s, "Improves your chance to hit by (%d+)%%%.?", "Aumenta sua chance de acerto em %1%%.")
    s = string.gsub(s, "Increases your chance to get a critical strike with spells by (%d+)%%%.?", "Aumenta a chance de acerto crítico com feitiços em %1%%.")
    s = string.gsub(s, "Increases your chance to hit with spells by (%d+)%%%.?", "Aumenta a chance de acerto com feitiços em %1%%.")
    s = string.gsub(s, "Increases your chance to dodge an attack by (%d+)%%%.?", "Aumenta sua chance de esquivar de ataques em %1%%.")
    s = string.gsub(s, "Increases your chance to parry an attack by (%d+)%%%.?", "Aumenta sua chance de aparar ataques em %1%%.")
    s = string.gsub(s, "Increases your chance to block attacks with a shield by (%d+)%%%.?", "Aumenta sua chance de bloquear ataques com escudo em %1%%.")
    s = string.gsub(s, "Increases the block value of your shield by (%d+)%.?", "Aumenta o valor de bloqueio do seu escudo em %1.")
    s = string.gsub(s, "Restores (%d+) mana per 5 sec%.?", "Restaura %1 de mana a cada 5 s.")
    s = string.gsub(s, "Restores (%d+) health per 5 sec%.?", "Restaura %1 de vida a cada 5 s.")
    s = string.gsub(s, "Teaches you how to (.+)%.?", "Ensina como %1.")
    s = string.gsub(s, "Permanently (.+)%.?", "Permanentemente %1.")

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

    -- Ações Imperativas de Itens de Missão e Interação
    s = string.gsub(s, "(%a+)\'s Lair", "Covil de %1")
    s = string.gsub(s, "Lair", "Covil")
    s = string.gsub(s, "[Bb]low near ([^%.]+)%.?", "Toque próximo ao %1.")
    s = string.gsub(s, "[Uu]se near ([^%.]+)%.?", "Use próximo a %1.")
    s = string.gsub(s, "[Pp]lace near ([^%.]+)%.?", "Coloque próximo a %1.")
    s = string.gsub(s, "[Pp]lant near ([^%.]+)%.?", "Plante próximo a %1.")
    s = string.gsub(s, "[Oo]pen ([^%.]+)%.?", "Abra %1.")
    s = string.gsub(s, "[Rr]ead ([^%.]+)%.?", "Leia %1.")
    s = string.gsub(s, "<[Rr]ight%s+[Cc]lick%s+to%s+[Oo]pen%>", "<Clique com o botão direito para abrir>")
    s = string.gsub(s, "<[Rr]ight%s+[Cc]lick%s+to%s+[Rr]ead%>", "<Clique com o botão direito para ler>")
    s = string.gsub(s, "[Rr]ight%s+[Cc]lick%s+to%s+[Oo]pen", "Clique com o botão direito para abrir")
    s = string.gsub(s, "[Rr]ight%s+[Cc]lick%s+to%s+[Rr]ead", "Clique com o botão direito para ler")

    -- 4. Dano Direto, Escolas Elementais e Verbos Ofensivos
    -- Causes
    s = string.gsub(s, "Causes (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "Causa " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "causes (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "causa " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "Causes (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "Causa " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "causes (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "causa " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "Causes (%d+) ([%a]+) damage", function(val, sc)
        return "Causa " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "causes (%d+) ([%a]+) damage", function(val, sc)
        return "causa " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)

    -- Deals
    s = string.gsub(s, "Deals (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "Causa " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "deals (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "causa " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "Deals (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "Causa " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "deals (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "causa " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "Deals (%d+) ([%a]+) damage", function(val, sc)
        return "Causa " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "deals (%d+) ([%a]+) damage", function(val, sc)
        return "causa " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)

    -- Inflicts
    s = string.gsub(s, "Inflicts (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "Inflige " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "inflicts (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "inflige " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "Inflicts (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "Inflige " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "inflicts (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "inflige " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "Inflicts (%d+) ([%a]+) damage", function(val, sc)
        return "Inflige " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "inflicts (%d+) ([%a]+) damage", function(val, sc)
        return "inflige " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)

    -- Causing / Dealing / Inflicting
    s = string.gsub(s, "causing (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "causando " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "causing (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "causando " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "causing (%d+) ([%a]+) damage", function(val, sc)
        return "causando " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "dealing (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "causando " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "dealing (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "causando " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "dealing (%d+) ([%a]+) damage", function(val, sc)
        return "causando " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "inflicting (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "infligindo " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "inflicting (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "infligindo " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "inflicting (%d+) ([%a]+) damage", function(val, sc)
        return "infligindo " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)

    -- Burns
    s = string.gsub(s, "Burns the enemy for (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "Queima o inimigo causando " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "burns the enemy for (%d+ to %d+) ([%a]+) damage", function(val, sc)
        return "queima o inimigo causando " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "Burns the enemy for (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "Queima o inimigo causando " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "burns the enemy for (%d+) to (%d+) ([%a]+) damage", function(v1, v2, sc)
        return "queima o inimigo causando " .. v1 .. " a " .. v2 .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "Burns the enemy for (%d+) ([%a]+) damage", function(val, sc)
        return "Queima o inimigo causando " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "burns the enemy for (%d+) ([%a]+) damage", function(val, sc)
        return "queima o inimigo causando " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)

    -- Dano Adicional
    s = string.gsub(s, "an additional (%d+) ([%a]+) damage", function(val, sc)
        return "mais " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc) .. " adicional"
    end)
    s = string.gsub(s, "plus (%d+) ([%a]+) damage", function(val, sc)
        return "mais " .. val .. " de dano de " .. (CM_Grammar_ptBR.terms[sc] or sc)
    end)
    s = string.gsub(s, "plus (%d+) damage", "mais %1 de dano")
    s = string.gsub(s, "([%d%.]+) additional damage", "mais %1 de dano adicional")

    -- 5. Cura Direta e Cura Contínua (HoTs)
    s = string.gsub(s, "Heals a friendly target for (%d+ to %d+)", "Cura um alvo aliado em %1")
    s = string.gsub(s, "heals a friendly target for (%d+ to %d+)", "cura um alvo aliado em %1")
    s = string.gsub(s, "Heals a friendly target for (%d+) to (%d+)", "Cura um alvo aliado em %1 a %2")
    s = string.gsub(s, "heals a friendly target for (%d+) to (%d+)", "cura um alvo aliado em %1 a %2")
    s = string.gsub(s, "Heals a friendly target for (%d+)", "Cura um alvo aliado em %1")
    s = string.gsub(s, "heals a friendly target for (%d+)", "cura um alvo aliado em %1")
    s = string.gsub(s, "Heals the friendly target for (%d+ to %d+)", "Cura o alvo aliado em %1")
    s = string.gsub(s, "Heals the target for (%d+ to %d+)", "Cura o alvo em %1")
    s = string.gsub(s, "Heals the target for (%d+) to (%d+)", "Cura o alvo em %1 a %2")
    s = string.gsub(s, "Heals the target for (%d+)", "Cura o alvo em %1")
    s = string.gsub(s, "Heals an ally for (%d+ to %d+)", "Cura um aliado em %1")
    s = string.gsub(s, "Heals you for (%d+ to %d+)", "Cura você em %1")
    s = string.gsub(s, "Heals you for (%d+)", "Cura você em %1")
    s = string.gsub(s, "Heals (%d+) damage", "Cura %1 de dano")
    s = string.gsub(s, "heals (%d+) damage", "cura %1 de dano")
    s = string.gsub(s, "Restores (%d+ to %d+) health", "Restaura %1 de vida")
    s = string.gsub(s, "restores (%d+ to %d+) health", "restaura %1 de vida")
    s = string.gsub(s, "Restores (%d+) to (%d+) health", "Restaura %1 a %2 de vida")
    s = string.gsub(s, "restores (%d+) to (%d+) health", "restaura %1 a %2 de vida")
    s = string.gsub(s, "Restores (%d+) health", "Restaura %1 de vida")
    s = string.gsub(s, "restores (%d+) health", "restaura %1 de vida")
    s = string.gsub(s, "Restores (%d+ to %d+) mana", "Restaura %1 de mana")
    s = string.gsub(s, "restores (%d+ to %d+) mana", "restaura %1 de mana")
    s = string.gsub(s, "Restores (%d+) to (%d+) mana", "Restaura %1 a %2 de mana")
    s = string.gsub(s, "restores (%d+) to (%d+) mana", "restaura %1 a %2 de mana")
    s = string.gsub(s, "Restores (%d+) mana", "Restaura %1 de mana")
    s = string.gsub(s, "restores (%d+) mana", "restaura %1 de mana")
    s = string.gsub(s, "Restores (%d+) energy", "Restaura %1 de energia")
    s = string.gsub(s, "restores (%d+) energy", "restaura %1 de energia")
    s = string.gsub(s, "Restores (%d+) rage", "Restaura %1 de fúria")
    s = string.gsub(s, "restores (%d+) rage", "restaura %1 de fúria")

    -- 6. Absorção de Dano e Escudos
    s = string.gsub(s, "absorbing up to (%d+) damage", "absorvendo até %1 de dano")
    s = string.gsub(s, "Absorbing up to (%d+) damage", "Absorvendo até %1 de dano")
    s = string.gsub(s, "absorbing (%d+) damage", "absorvendo %1 de dano")
    s = string.gsub(s, "Absorbing (%d+) damage", "Absorvendo %1 de dano")
    s = string.gsub(s, "absorbs up to (%d+) damage", "absorve até %1 de dano")
    s = string.gsub(s, "Absorbs up to (%d+) damage", "Absorve até %1 de dano")
    s = string.gsub(s, "absorbs (%d+) damage", "absorve %1 de dano")
    s = string.gsub(s, "Absorbs (%d+) damage", "Absorve %1 de dano")

    -- 7. Talentos e Modificadores Globais (Cooldowns, Tempos de Lançamento, Custos)
    s = string.gsub(s, "Reduces the cooldown of your (.-) by ([%d%.]+) s", "Reduz o tempo de recarga de %1 em %2 s")
    s = string.gsub(s, "reduces the cooldown of your (.-) by ([%d%.]+) s", "reduz o tempo de recarga de %1 em %2 s")
    s = string.gsub(s, "Reduces the cooldown of (.-) by ([%d%.]+) s", "Reduz o tempo de recarga de %1 em %2 s")
    s = string.gsub(s, "reduces the cooldown of (.-) by ([%d%.]+) s", "reduz o tempo de recarga de %1 em %2 s")
    s = string.gsub(s, "Reduces the cooldown of your (.-) by (%d+) min", "Reduz o tempo de recarga de %1 em %2 min")
    s = string.gsub(s, "reduces the cooldown of your (.-) by (%d+) min", "reduz o tempo de recarga de %1 em %2 min")
    s = string.gsub(s, "Reduces the cooldown of (.-) by (%d+) min", "Reduz o tempo de recarga de %1 em %2 min")
    s = string.gsub(s, "reduces the cooldown of (.-) by (%d+) min", "reduz o tempo de recarga de %1 em %2 min")

    s = string.gsub(s, "Reduces the cast time of your (.-) by ([%d%.]+) s", "Reduz o tempo de lançamento de %1 em %2 s")
    s = string.gsub(s, "reduces the cast time of your (.-) by ([%d%.]+) s", "reduz o tempo de lançamento de %1 em %2 s")
    s = string.gsub(s, "Reduces the cast time of (.-) by ([%d%.]+) s", "Reduz o tempo de lançamento de %1 em %2 s")
    s = string.gsub(s, "reduces the cast time of (.-) by ([%d%.]+) s", "reduz o tempo de lançamento de %1 em %2 s")
    s = string.gsub(s, "Reduces the casting time of your (.-) by ([%d%.]+) s", "Reduz o tempo de lançamento de %1 em %2 s")
    s = string.gsub(s, "reduces the casting time of your (.-) by ([%d%.]+) s", "reduz o tempo de lançamento de %1 em %2 s")
    s = string.gsub(s, "Reduces the casting time of (.-) by ([%d%.]+) s", "Reduz o tempo de lançamento de %1 em %2 s")
    s = string.gsub(s, "reduces the casting time of (.-) by ([%d%.]+) s", "reduz o tempo de lançamento de %1 em %2 s")

    s = string.gsub(s, "Reduces the mana cost of your (.-) by (%d+)%%", "Reduz o custo de mana de %1 em %2%%")
    s = string.gsub(s, "reduces the mana cost of your (.-) by (%d+)%%", "reduz o custo de mana de %1 em %2%%")
    s = string.gsub(s, "Reduces the mana cost of (.-) by (%d+)%%", "Reduz o custo de mana de %1 em %2%%")
    s = string.gsub(s, "reduces the mana cost of (.-) by (%d+)%%", "reduz o custo de mana de %1 em %2%%")
    s = string.gsub(s, "Reduces the rage cost of your (.-) by (%d+)", "Reduz o custo de fúria de %1 em %2")
    s = string.gsub(s, "reduces the rage cost of your (.-) by (%d+)", "reduz o custo de fúria de %1 em %2")
    s = string.gsub(s, "Reduces the rage cost of (.-) by (%d+)", "Reduz o custo de fúria de %1 em %2")
    s = string.gsub(s, "reduces the rage cost of (.-) by (%d+)", "reduz o custo de fúria de %1 em %2")
    s = string.gsub(s, "Reduces the energy cost of your (.-) by (%d+)", "Reduz o custo de energia de %1 em %2")
    s = string.gsub(s, "reduces the energy cost of your (.-) by (%d+)", "reduz o custo de energia de %1 em %2")
    s = string.gsub(s, "Reduces the energy cost of (.-) by (%d+)", "Reduz o custo de energia de %1 em %2")
    s = string.gsub(s, "reduces the energy cost of (.-) by (%d+)", "reduz o custo de energia de %1 em %2")

    s = string.gsub(s, "Increases the critical strike damage bonus of your (.-) by (%d+)%%", "Aumenta o bônus de dano de acerto crítico de %1 em %2%%")
    s = string.gsub(s, "increases the critical strike damage bonus of your (.-) by (%d+)%%", "aumenta o bônus de dano de acerto crítico de %1 em %2%%")
    s = string.gsub(s, "Increases the critical strike damage bonus of (.-) by (%d+)%%", "Aumenta o bônus de dano de acerto crítico de %1 em %2%%")
    s = string.gsub(s, "increases the critical strike damage bonus of (.-) by (%d+)%%", "aumenta o bônus de dano de acerto crítico de %1 em %2%%")

    s = string.gsub(s, "Increases your critical strike chance with (.-) by (%d+)%%", "Aumenta sua chance de acerto crítico com %1 em %2%%")
    s = string.gsub(s, "increases your critical strike chance with (.-) by (%d+)%%", "aumenta sua chance de acerto crítico com %1 em %2%%")
    s = string.gsub(s, "Increases critical strike chance with (.-) by (%d+)%%", "Aumenta a chance de acerto crítico com %1 em %2%%")
    s = string.gsub(s, "increases critical strike chance with (.-) by (%d+)%%", "aumenta a chance de acerto crítico com %1 em %2%%")
    s = string.gsub(s, "Increases your critical strike chance by (%d+)%%", "Aumenta sua chance de acerto crítico em %1%%")
    s = string.gsub(s, "increases your critical strike chance by (%d+)%%", "aumenta sua chance de acerto crítico em %1%%")
    s = string.gsub(s, "Increases critical strike chance by (%d+)%%", "Aumenta a chance de acerto crítico em %1%%")
    s = string.gsub(s, "increases critical strike chance by (%d+)%%", "aumenta a chance de acerto crítico em %1%%")

    s = string.gsub(s, "Increases the damage done by your (.-) by (%d+)%%", "Aumenta o dano causado por %1 em %2%%")
    s = string.gsub(s, "increases the damage done by your (.-) by (%d+)%%", "aumenta o dano causado por %1 em %2%%")
    s = string.gsub(s, "Increases the damage done by (.-) by (%d+)%%", "Aumenta o dano causado por %1 em %2%%")
    s = string.gsub(s, "increases the damage done by (.-) by (%d+)%%", "aumenta o dano causado por %1 em %2%%")
    s = string.gsub(s, "Increases damage done by your (.-) by (%d+)%%", "Aumenta o dano causado por %1 em %2%%")
    s = string.gsub(s, "increases damage done by your (.-) by (%d+)%%", "aumenta o dano causado por %1 em %2%%")
    s = string.gsub(s, "Increases damage done by (.-) by (%d+)%%", "Aumenta o dano causado por %1 em %2%%")
    s = string.gsub(s, "increases damage done by (.-) by (%d+)%%", "aumenta o dano causado por %1 em %2%%")

    s = string.gsub(s, "Increases healing done by your (.-) by (%d+)%%", "Aumenta a cura realizada por %1 em %2%%")
    s = string.gsub(s, "increases healing done by your (.-) by (%d+)%%", "aumenta a cura realizada por %1 em %2%%")
    s = string.gsub(s, "Increases healing done by (.-) by (%d+)%%", "Aumenta a cura realizada por %1 em %2%%")
    s = string.gsub(s, "increases healing done by (.-) by (%d+)%%", "aumenta a cura realizada por %1 em %2%%")

    s = string.gsub(s, "Increases the range of your (.-) by (%d+) metros", "Aumenta o alcance de %1 em %2 metros")
    s = string.gsub(s, "increases the range of your (.-) by (%d+) metros", "aumenta o alcance de %1 em %2 metros")
    s = string.gsub(s, "Increases the range of (.-) by (%d+) metros", "Aumenta o alcance de %1 em %2 metros")
    s = string.gsub(s, "increases the range of (.-) by (%d+) metros", "aumenta o alcance de %1 em %2 metros")

    s = string.gsub(s, "Increases the duration of your (.-) by (%d+) s", "Aumenta a duração de %1 em %2 s")
    s = string.gsub(s, "increases the duration of your (.-) by (%d+) s", "aumenta a duração de %1 em %2 s")
    s = string.gsub(s, "Increases the duration of (.-) by (%d+) s", "Aumenta a duração de %1 em %2 s")
    s = string.gsub(s, "increases the duration of (.-) by (%d+) s", "aumenta a duração de %1 em %2 s")
    s = string.gsub(s, "Increases the duration of (.-) by (%d+) min", "Aumenta a duração de %1 em %2 min")
    s = string.gsub(s, "increases the duration of (.-) by (%d+) min", "aumenta a duração de %1 em %2 min")

    s = string.gsub(s, "Increases your chance to hit by (%d+)%%", "Aumenta sua chance de acerto em %1%%")
    s = string.gsub(s, "increases your chance to hit by (%d+)%%", "aumenta sua chance de acerto em %1%%")
    s = string.gsub(s, "Increases your chance to dodge by (%d+)%%", "Aumenta sua chance de esquivar em %1%%")
    s = string.gsub(s, "increases your chance to dodge by (%d+)%%", "aumenta sua chance de esquivar em %1%%")
    s = string.gsub(s, "Increases your chance to parry by (%d+)%%", "Aumenta sua chance de aparar em %1%%")
    s = string.gsub(s, "increases your chance to parry by (%d+)%%", "aumenta sua chance de aparar em %1%%")
    s = string.gsub(s, "Increases your chance to block by (%d+)%%", "Aumenta sua chance de bloquear em %1%%")
    s = string.gsub(s, "increases your chance to block by (%d+)%%", "aumenta sua chance de bloquear em %1%%")
    s = string.gsub(s, "Increases your chance to resist (.-) by (%d+)%%", "Aumenta sua chance de resistir a %1 em %2%%")
    s = string.gsub(s, "increases your chance to resist (.-) by (%d+)%%", "aumenta sua chance de resistir a %1 em %2%%")

    s = string.gsub(s, "Gives your (.-) a (%d+)%% chance to (.-)%.?", "Concede a %1 uma chance de %2%% de %3.")
    s = string.gsub(s, "gives your (.-) a (%d+)%% chance to (.-)%.?", "concede a %1 uma chance de %2%% de %3.")
    s = string.gsub(s, "Gives a (%d+)%% chance to (.-)%.?", "Concede uma chance de %1%% de %2.")
    s = string.gsub(s, "gives a (%d+)%% chance to (.-)%.?", "concede uma chance de %1%% de %2.")

    -- 8. Buffs, Modificadores de Atributos e Velocidade
    s = string.gsub(s, "Increases attack power by (%d+)", "Aumenta o poder de ataque em %1")
    s = string.gsub(s, "increases attack power by (%d+)", "aumenta o poder de ataque em %1")
    s = string.gsub(s, "Increases melee attack power by (%d+)", "Aumenta o poder de ataque corpo a corpo em %1")
    s = string.gsub(s, "increases melee attack power by (%d+)", "aumenta o poder de ataque corpo a corpo em %1")
    s = string.gsub(s, "Increases ranged attack power by (%d+)", "Aumenta o poder de ataque à distância em %1")
    s = string.gsub(s, "increases ranged attack power by (%d+)", "aumenta o poder de ataque à distância em %1")
    s = string.gsub(s, "Increases armor by (%d+)", "Aumenta a armadura em %1")
    s = string.gsub(s, "increases armor by (%d+)", "aumenta a armadura em %1")
    s = string.gsub(s, "Increases defense skill by (%d+)", "Aumenta a perícia de defesa em %1")
    s = string.gsub(s, "increases defense skill by (%d+)", "aumenta a perícia de defesa em %1")
    s = string.gsub(s, "Increases defense by (%d+)", "Aumenta a defesa em %1")
    s = string.gsub(s, "increases defense by (%d+)", "aumenta a defesa em %1")

    s = string.gsub(s, "Increases the target's ([%a]+) by (%d+)", function(at, val)
        return "Aumenta o(a) " .. (CM_Grammar_ptBR.terms[at] or at) .. " do alvo em " .. val
    end)
    s = string.gsub(s, "increases the target's ([%a]+) by (%d+)", function(at, val)
        return "aumenta o(a) " .. (CM_Grammar_ptBR.terms[at] or at) .. " do alvo em " .. val
    end)
    s = string.gsub(s, "Increases your ([%a]+) by (%d+)", function(at, val)
        return "Aumenta seu(sua) " .. (CM_Grammar_ptBR.terms[at] or at) .. " em " .. val
    end)
    s = string.gsub(s, "increases your ([%a]+) by (%d+)", function(at, val)
        return "aumenta seu(sua) " .. (CM_Grammar_ptBR.terms[at] or at) .. " em " .. val
    end)
    s = string.gsub(s, "Increases ([%a]+) by (%d+)", function(at, val)
        return "Aumenta " .. (CM_Grammar_ptBR.terms[at] or at) .. " em " .. val
    end)
    s = string.gsub(s, "increases ([%a]+) by (%d+)", function(at, val)
        return "aumenta " .. (CM_Grammar_ptBR.terms[at] or at) .. " em " .. val
    end)

    s = string.gsub(s, "increasing movement speed by (%d+)%%", "aumentando a velocidade de movimento em %1%%")
    s = string.gsub(s, "slowing movement speed by (%d+)%%", "reduzindo a velocidade de movimento em %1%%")
    s = string.gsub(s, "slowing their movement speed by (%d+)%%", "reduzindo a velocidade de movimento deles em %1%%")
    s = string.gsub(s, "slowing the target's movement speed by (%d+)%%", "reduzindo a velocidade de movimento do alvo em %1%%")
    s = string.gsub(s, "reduces the movement speed of .* by (%d+)%%", "reduz a velocidade de movimento dos inimigos em %1%%")

    -- 9. Controle de Grupo, Atordoamento e Efeitos
    s = string.gsub(s, "Stuns the target for (%d+) s", "Atordoa o alvo por %1 s")
    s = string.gsub(s, "stuns the target for (%d+) s", "atordoa o alvo por %1 s")
    s = string.gsub(s, "Stuns the target", "Atordoa o alvo")
    s = string.gsub(s, "stuns the target", "atordoa o alvo")
    s = string.gsub(s, "Stuns up to (%d+) enemies", "Atordoa até %1 inimigos")
    s = string.gsub(s, "stuns up to (%d+) enemies", "atordoa até %1 inimigos")
    s = string.gsub(s, "Silences the target for (%d+) s", "Silencia o alvo por %1 s")
    s = string.gsub(s, "silences the target for (%d+) s", "silencia o alvo por %1 s")
    s = string.gsub(s, "Silences the enemy for (%d+) s", "Silencia o inimigo por %1 s")
    s = string.gsub(s, "silences the enemy for (%d+) s", "silencia o inimigo por %1 s")
    s = string.gsub(s, "Fears the target for (%d+) s", "Aterroriza o alvo por %1 s")
    s = string.gsub(s, "fears the target for (%d+) s", "aterroriza o alvo por %1 s")
    s = string.gsub(s, "Disorients the target for (%d+) s", "Desorienta o alvo por %1 s")
    s = string.gsub(s, "disorients the target for (%d+) s", "desorienta o alvo por %1 s")
    s = string.gsub(s, "Incapacitates the target for (%d+) s", "Incapacita o alvo por %1 s")
    s = string.gsub(s, "incapacitates the target for (%d+) s", "incapacita o alvo por %1 s")
    s = string.gsub(s, "Immobilizes the target for (%d+) s", "Imobiliza o alvo por %1 s")
    s = string.gsub(s, "immobilizes the target for (%d+) s", "imobiliza o alvo por %1 s")

    -- 10. Ataques de Arma, Golpes e Pontos de Combo
    s = string.gsub(s, "An attack that increases melee damage by (%d+)", "Um ataque que aumenta o dano corpo a corpo em %1")
    s = string.gsub(s, "A strike that deals (%d+) extra damage on top of your normal weapon damage", "Um golpe que causa %1 de dano adicional além do dano normal da arma")
    s = string.gsub(s, "A vicious strike that deals normal weapon damage plus (%d+)", "Um golpe traiçoeiro que causa o dano normal da arma mais %1")
    s = string.gsub(s, "A strong attack that increases melee damage by (%d+)", "Um ataque forte que aumenta o dano corpo a corpo em %1")
    s = string.gsub(s, "Finishing move that increases melee attack speed by (%d+)%%", "Golpe finalizador que aumenta a velocidade de ataque corpo a corpo em %1%%")
    s = string.gsub(s, "Finishing move that causes damage per combo point", "Golpe finalizador que causa dano crescente de acordo com os pontos de combo")
    s = string.gsub(s, "Finishing move that", "Golpe finalizador que")
    s = string.gsub(s, "Awards (%d+) combo points?", "Concede %1 ponto(s) de combo")
    s = string.gsub(s, "awards (%d+) combo points?", "concede %1 ponto(s) de combo")

    -- Golpes com Provocação / Efeitos Especiais de Postura
    s = string.gsub(s, "Slam the target with (.-), taunting it to attack you%.%s*Has no effect if the target is already attacking you%.?", function(fury)
        local locFury = (CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[fury]) or fury
        return "Golpeia o alvo com " .. locFury .. ", provocando-o para atacar você. Não tem efeito se o alvo já estiver atacando você."
    end)
    s = string.gsub(s, "slam the target with (.-), taunting it to attack you%.%s*Has no effect if the target is already attacking you%.?", function(fury)
        local locFury = (CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[fury]) or fury
        return "golpeia o alvo com " .. locFury .. ", provocando-o para atacar você. Não tem efeito se o alvo já estiver atacando você."
    end)
    s = string.gsub(s, "Slam the target with (.-), taunting it to attack you%.?", function(fury)
        local locFury = (CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[fury]) or fury
        return "Golpeia o alvo com " .. locFury .. ", provocando-o para atacar você."
    end)
    s = string.gsub(s, "slam the target with (.-), taunting it to attack you%.?", function(fury)
        local locFury = (CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[fury]) or fury
        return "golpeia o alvo com " .. locFury .. ", provocando-o para atacar você."
    end)
    s = string.gsub(s, "Slam the target with (.-)%.?", function(fury)
        local locFury = (CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[fury]) or fury
        return "Golpeia o alvo com " .. locFury .. "."
    end)
    s = string.gsub(s, "slam the target with (.-)%.?", function(fury)
        local locFury = (CM_Grammar_ptBR.terms and CM_Grammar_ptBR.terms[fury]) or fury
        return "golpeia o alvo com " .. locFury .. "."
    end)
    s = string.gsub(s, "taunting it to attack you%.?", "provocando-o para atacar você.")
    s = string.gsub(s, "taunting the target to attack you%.?", "provocando o alvo para atacar você.")
    s = string.gsub(s, "Has no effect if the target is already attacking you%.?", "Não tem efeito se o alvo já estiver atacando você.")
    s = string.gsub(s, "has no effect if the target is already attacking you%.?", "não tem efeito se o alvo já estiver atacando você.")
    s = string.gsub(s, "Has no effect if (.-) is already attacking you%.?", "Não tem efeito se %1 já estiver atacando você.")
    s = string.gsub(s, "has no effect if (.-) is already attacking you%.?", "não tem efeito se %1 já estiver atacando você.")

    -- Restituição e Gerenciamento de Totens / Recursos
    s = string.gsub(s, "Returns your totems to the earth, refunding (%d+)%% of the mana required to cast each totem destroyed by (.-)%.?", "Devolve seus totens à terra, restituindo %1%% do mana necessário para evocar cada totem destruído por %2.")
    s = string.gsub(s, "returns your totems to the earth, refunding (%d+)%% of the mana required to cast each totem destroyed by (.-)%.?", "devolve seus totens à terra, restituindo %1%% do mana necessário para evocar cada totem destruído por %2.")
    s = string.gsub(s, "Returns your totems to the earth, refunding (%d+)%% of the mana required to cast each totem%.?", "Devolve seus totens à terra, restituindo %1%% do mana necessário para evocar cada totem.")
    s = string.gsub(s, "returns your totems to the earth, refunding (%d+)%% of the mana required to cast each totem%.?", "devolve seus totens à terra, restituindo %1%% do mana necessário para evocar cada totem.")
    s = string.gsub(s, "Returns (your .-) to the earth", "Devolve %1 à terra")
    s = string.gsub(s, "returns (your .-) to the earth", "devolve %1 à terra")
    s = string.gsub(s, "refunding (%d+)%% of the mana required to cast each totem", "restituindo %1%% do mana necessário para evocar cada totem")

    -- 11. Fórmulas de Duração e Requisitos
    s = string.gsub(s, "Lasts (%d+) s%.?", "Dura %1 s.")
    s = string.gsub(s, "lasts (%d+) s%.?", "dura %1 s.")
    s = string.gsub(s, "Lasts (%d+) min%.?", "Dura %1 min.")
    s = string.gsub(s, "lasts (%d+) min%.?", "dura %1 min.")
    s = string.gsub(s, "Lasts (%d+) h%.?", "Dura %1 h.")
    s = string.gsub(s, "lasts (%d+) h%.?", "dura %1 h.")
    s = string.gsub(s, "over (%d+) s", "ao longo de %1 s")
    s = string.gsub(s, "every (%d+) s", "a cada %1 s")
    s = string.gsub(s, "every (%d+%.?%d*) s", "a cada %1 s")
    s = string.gsub(s, "for (%d+) s", "por %1 s")
    s = string.gsub(s, "for (%d+) min", "por %1 min")
    s = string.gsub(s, "within (%d+) metros", "a até %1 metros")
    s = string.gsub(s, "within (%d+ to %d+) metros", "a até %1 metros")

    -- 12. Passivas de Classe, Armas e Armaduras
    s = string.gsub(s, "Allows the use of ([%a%s%-]+)%.?", function(item)
        local loc = CM_Grammar_ptBR.terms[item] or item
        return "Permite o uso de " .. loc .. "."
    end)
    s = string.gsub(s, "allows the use of ([%a%s%-]+)%.?", function(item)
        local loc = CM_Grammar_ptBR.terms[item] or item
        return "permite o uso de " .. loc .. "."
    end)
    s = string.gsub(s, "Allows ([%a%s%-]+) to be used%.?", function(item)
        local loc = CM_Grammar_ptBR.terms[item] or item
        return "Permite que " .. loc .. " sejam usados."
    end)
    s = string.gsub(s, "allows ([%a%s%-]+) to be used%.?", function(item)
        local loc = CM_Grammar_ptBR.terms[item] or item
        return "permite que " .. loc .. " sejam usados."
    end)
    s = string.gsub(s, "Allows dual wielding of one%-handed weapons%.?", "Permite o uso de armas de uma mão em ambas as mãos.")
    s = string.gsub(s, "Gives a chance to parry enemy melee attacks%.?", "Concede chance de aparar ataques corpo a corpo inimigos.")
    s = string.gsub(s, "Gives a chance to dodge enemy attacks%.?", "Concede chance de esquivar de ataques inimigos.")
    s = string.gsub(s, "Gives a chance to block enemy attacks with a shield%.?", "Concede chance de bloquear ataques inimigos com um escudo.")
    s = string.gsub(s, "Gives a chance to ([^%.]+)%.?", function(action)
        return "Concede chance de " .. action .. "."
    end)

    -- 13. Preposições de Alvo Comuns
    s = string.gsub(s, "to the target", "ao alvo")
    s = string.gsub(s, "to an enemy target", "a um alvo inimigo")
    s = string.gsub(s, "to an enemy", "a um inimigo")
    s = string.gsub(s, "to all nearby enemies", "a todos os inimigos próximos")
    s = string.gsub(s, "to all enemies", "a todos os inimigos")
    s = string.gsub(s, "to up to (%d+) enemies", "a até %1 inimigos")
    s = string.gsub(s, "to up to (%d+) nearby enemies", "a até %1 inimigos próximos")
    s = string.gsub(s, "to up to (%d+) targets", "a até %1 alvos")
    s = string.gsub(s, "to up to (%d+) nearby targets", "a até %1 alvos próximos")
    s = string.gsub(s, "to party members", "aos membros do grupo")
    s = string.gsub(s, "to group members", "aos membros do grupo")
    s = string.gsub(s, "to the caster", "ao lançador")
    s = string.gsub(s, "at the feet of the caster", "aos pés do lançador")
    s = string.gsub(s, "at your feet", "aos seus pés")

    -- 14. Substituição de Termos Residuais Ordenados por Comprimento Decrescente
    if not CM_Grammar_ptBR._sortedTerms then
        CM_Grammar_ptBR._sortedTerms = {}
        for eng, pt in pairs(CM_Grammar_ptBR.terms) do
            table.insert(CM_Grammar_ptBR._sortedTerms, { eng = eng, pt = pt, len = string.len(eng) })
        end
        table.sort(CM_Grammar_ptBR._sortedTerms, function(a, b) return a.len > b.len end)
    end
    for _, item in ipairs(CM_Grammar_ptBR._sortedTerms) do
        s = string.gsub(s, "%f[%a]" .. item.eng .. "%f[%A]", item.pt)
    end

    -- 15. Normalização Final de ranges numéricos ('to' -> 'a')
    s = string.gsub(s, "(%d+)%s+to%s+(%d+)", "%1 a %2")
    s = string.gsub(s, "per 5 sec%.?", "a cada 5 s.")
    s = string.gsub(s, "per 5 s%.?", "a cada 5 s.")
    s = string.gsub(s, "de dano de Arcano", "de dano Arcano")
    s = string.gsub(s, "de dano de Físico", "de dano Físico")
    s = string.gsub(s, "de dano de Sagrado", "de dano Sagrado")

    return s
end
