-- ============================================================================
-- ConsoleModeVanilla - Descricoes Dinamicas de Feiticos & Magias (ptBR)
-- Motor Hibrido: Templates Canonicos + Templates Genericos com Preservacao de Valores
-- Traducao Contextual Humana de RPG (Padrao Oficial Blizzard pt-BR)
-- WoW 1.12.1 / Lua 5.0 estrito (sem '#', sem 'continue', sem 'gmatch')
-- ============================================================================

CM_SpellDesc_ptBR = CM_SpellDesc_ptBR or {}

-- ----------------------------------------------------------------------------
-- 1. Substituicoes Lexicais de Escolas, Atributos e Termos Frequentes
-- ----------------------------------------------------------------------------
CM_SpellDesc_ptBR.terms = {
    ["Fire"] = "Fogo",
    ["Frost"] = "Gelo",
    ["Nature"] = "Natureza",
    ["Shadow"] = "Sombra",
    ["Holy"] = "Sagrado",
    ["Arcane"] = "Arcano",
    ["Physical"] = "Fisico",
}

-- ----------------------------------------------------------------------------
-- 2. Templates Canonicos Mapeados por Nome da Magia (Chaves em minusculas)
-- ----------------------------------------------------------------------------
CM_SpellDesc_ptBR.spells = {
    -- SHAMAN
    ["earth shock"] = {
        {
            pat = "Instantly shocks the target with concussive force, causing (%d+ to %d+) Nature damage%. It also interrupts spellcasting and prevents any spell in that school from being cast for (%d+) sec%. Causes a medium amount of threat%.",
            tpl = "Eletrocuta instantaneamente o alvo com força concussiva, causando %s de dano de Natureza. Também interrompe o lançamento de feitiços e impede que qualquer feitiço daquela escola seja lançado por %s s. Causa uma quantidade média de ameaça."
        },
        {
            pat = "Instantly shocks the target with concussive force, causing (%d+) to (%d+) Nature damage%. It also interrupts spellcasting and prevents any spell in that school from being cast for (%d+) sec%. Causes a medium amount of threat%.",
            tpl = "Eletrocuta instantaneamente o alvo com força concussiva, causando %s a %s de dano de Natureza. Também interrompe o lançamento de feitiços e impede que qualquer feitiço daquela escola seja lançado por %s s. Causa uma quantidade média de ameaça."
        }
    },
    ["flame shock"] = {
        {
            pat = "Instantly sears the target with fire, causing (%d+) Fire damage immediately and (%d+) Fire damage over (%d+) sec%.",
            tpl = "Queima instantaneamente o alvo com fogo, causando %s de dano de Fogo imediatamente e %s de dano de Fogo ao longo de %s s."
        },
        {
            pat = "Instantly sears the target with fire, causing (%d+ to %d+) Fire damage immediately and (%d+) Fire damage over (%d+) sec%.",
            tpl = "Queima instantaneamente o alvo com fogo, causando %s de dano de Fogo imediatamente e %s de dano de Fogo ao longo de %s s."
        }
    },
    ["frost shock"] = {
        {
            pat = "Instantly shocks the target with frost, causing (%d+ to %d+) Frost damage and slowing the target's movement speed by (%d+)%% for (%d+) sec%.",
            tpl = "Eletrocuta instantaneamente o alvo com gelo, causando %s de dano de Gelo e reduzindo a velocidade de movimento do alvo em %s%% por %s s."
        },
        {
            pat = "Instantly shocks the target with frost, causing (%d+) to (%d+) Frost damage and slowing the target's movement speed by (%d+)%% for (%d+) sec%.",
            tpl = "Eletrocuta instantaneamente o alvo com gelo, causando %s a %s de dano de Gelo e reduzindo a velocidade de movimento do alvo em %s%% por %s s."
        }
    },
    ["lightning bolt"] = {
        {
            pat = "Casts a bolt of lightning at the target for (%d+ to %d+) Nature damage%.",
            tpl = "Lança um raio contra o alvo causando %s de dano de Natureza."
        },
        {
            pat = "Casts a bolt of lightning at the target for (%d+) to (%d+) Nature damage%.",
            tpl = "Lança um raio contra o alvo causando %s a %s de dano de Natureza."
        }
    },
    ["chain lightning"] = {
        {
            pat = "Hurls a lightning bolt at the enemy, dealing (%d+ to %d+) Nature damage and then jumping to additional nearby enemies%. Each jump reduces the damage by (%d+)%%%. Affects (%d+) targets%.",
            tpl = "Arremessa um raio no inimigo, causando %s de dano de Natureza e saltando para inimigos próximos adicionais. Cada salto reduz o dano em %s%%. Afeta %s alvos."
        },
        {
            pat = "Hurls a lightning bolt at the enemy, dealing (%d+) to (%d+) Nature damage and then jumping to additional nearby enemies%. Each jump reduces the damage by (%d+)%%%. Affects (%d+) targets%.",
            tpl = "Arremessa um raio no inimigo, causando %s a %s de dano de Natureza e saltando para inimigos próximos adicionais. Cada salto reduz o dano em %s%%. Afeta %s alvos."
        }
    },
    ["healing wave"] = {
        {
            pat = "Heals a friendly target for (%d+ to %d+)%.",
            tpl = "Cura um alvo aliado em %s."
        },
        {
            pat = "Heals a friendly target for (%d+) to (%d+)%.",
            tpl = "Cura um alvo aliado em %s a %s."
        }
    },
    ["lesser healing wave"] = {
        {
            pat = "Heals a friendly target for (%d+ to %d+)%.",
            tpl = "Cura um alvo aliado em %s."
        },
        {
            pat = "Heals a friendly target for (%d+) to (%d+)%.",
            tpl = "Cura um alvo aliado em %s a %s."
        }
    },
    ["chain heal"] = {
        {
            pat = "Heals the friendly target for (%d+ to %d+), then jumps to heal additional nearby party members%. Each jump reduces the effectiveness of the heal by (%d+)%%%. Heals (%d+) total targets%.",
            tpl = "Cura o alvo aliado em %s, saltando depois para curar membros do grupo próximos adicionais. Cada salto reduz a eficácia da cura em %s%%. Cura %s alvos no total."
        }
    },
    ["lightning shield"] = {
        {
            pat = "The caster is surrounded by (%d+) balls of lightning%. When a spell, melee or ranged attack hits the caster, the attacker will be struck for (%d+) Nature damage%. Only one ball will be active at a time%. This will not fire more than once every few seconds%. Lasts (%d+) min%.",
            tpl = "O lançador é cercado por %s esferas de raios. Quando um feitiço, ataque corpo a corpo ou de longo alcance atinge o lançador, o atacante é atingido por %s de dano de Natureza. Apenas uma esfera é ativada por vez. Dura %s min."
        }
    },
    ["rockbiter weapon"] = {
        {
            pat = "Imbue the Shaman's weapon with the earth's fury, increasing attack power by (%d+) and threat generated by melee attacks by (%d+)%%%. Lasts (%d+) min%.",
            tpl = "Infunde a arma do Xamã com a fúria da terra, aumentando o poder de ataque em %s e a ameaça gerada por ataques corpo a corpo em %s%%. Dura %s min."
        },
        {
            pat = "Imbue the Shaman's weapon with the earth's fury, increasing attack power by (%d+)%. Lasts (%d+) min%.",
            tpl = "Infunde a arma do Xamã com a fúria da terra, aumentando o poder de ataque em %s. Dura %s min."
        }
    },
    ["flametongue weapon"] = {
        {
            pat = "Imbue the Shaman's weapon with fire, increasing attack power by (%d+) and causing each hit to deal (%d+ to %d+) additional Fire damage based on the speed of the weapon%. Slower weapons deal more fire damage per swing%. Lasts (%d+) min%.",
            tpl = "Infunde a arma do Xamã com fogo, aumentando o poder de ataque em %s e fazendo com que cada golpe cause %s de dano de Fogo adicional baseado na velocidade da arma. Armas mais lentas causam mais dano de fogo por golpe. Dura %s min."
        }
    },
    ["windfury weapon"] = {
        {
            pat = "Imbue the Shaman's weapon with wind%. Each hit has a (%d+)%% chance of granting you (%d+) extra attacks with (%d+) bonus attack power%. Lasts (%d+) min%.",
            tpl = "Infunde a arma do Xamã com vento. Cada golpe tem %s%% de chance de conceder %s ataques adicionais com %s de bônus de poder de ataque. Dura %s min."
        }
    },

    ["frostbrand weapon"] = {
        {
            pat = "Imbue the Shaman's weapon with frost%. Each hit has a chance of causing (%d+ to %d+) Frost damage and slowing the target's movement speed by (%d+)%% for (%d+) sec%. Lasts (%d+) min%.",
            tpl = "Infunde a arma do Xamã com gelo. Cada golpe tem chance de causar %s de dano de Gelo e reduzir a velocidade de movimento do alvo em %s%% por %s s. Dura %s min."
        },
        {
            pat = "Imbue the Shaman's weapon with frost%. Each hit has a chance of causing (%d+) Frost damage and slowing the target's movement speed by (%d+)%% for (%d+) sec%. Lasts (%d+) min%.",
            tpl = "Infunde a arma do Xamã com gelo. Cada golpe tem chance de causar %s de dano de Gelo e reduzir a velocidade de movimento do alvo em %s%% por %s s. Dura %s min."
        }
    },
    ["stoneskin totem"] = {
        {
            pat = "Summons a Stoneskin Totem with 5 health at the feet of the caster%. The totem protects party members within (%d+) yards, reducing melee damage taken by (%d+)%. Lasts (%d+) min%.",
            tpl = "Evoca um Totem de Pele de Pedra com 5 de vida aos pés do lançador. O totem protege membros do grupo a até %s metros, reduzindo o dano corpo a corpo recebido em %s. Dura %s min."
        },
        {
            pat = "Summons a Stoneskin Totem with 5 health at the feet of the caster for (%d+) min%. The totem protects party members within (%d+) yards, reducing melee damage taken by (%d+)%.",
            tpl = "Evoca um Totem de Pele de Pedra com 5 de vida aos pés do lançador por %s min. O totem protege membros do grupo a até %s metros, reduzindo o dano corpo a corpo recebido em %s."
        }
    },
    ["earthbind totem"] = {
        {
            pat = "Summons an Earthbind Totem with 5 health at the feet of the caster for (%d+) sec that periodically pulses, slowing the movement speed of all nearby enemies within (%d+) yards for (%d+) sec%.",
            tpl = "Evoca um Totem de Prisão da Terra com 5 de vida aos pés do lançador por %s s que emite pulsos periódicos, reduzindo a velocidade de movimento de inimigos próximos a até %s metros por %s s."
        },
        {
            pat = "Summons an Earthbind Totem with 5 health at the feet of the caster for (%d+) sec that periodically pulses, slowing the movement speed of all nearby enemies within (%d+) yards%.",
            tpl = "Evoca um Totem de Prisão da Terra com 5 de vida aos pés do lançador por %s s que emite pulsos periódicos, reduzindo a velocidade de movimento de inimigos próximos a até %s metros."
        }
    },
    ["stoneclaw totem"] = {
        {
            pat = "Summons a Stoneclaw Totem with (%d+) health at the feet of the caster for (%d+) sec that taunts creatures within (%d+) yards to attack it%.",
            tpl = "Evoca um Totem da Garra de Pedra com %s de vida aos pés do lançador por %s s que provoca criaturas a até %s metros para atacá-lo."
        },
        {
            pat = "Summons a Stoneclaw Totem with (%d+) health at the feet of the caster for (%d+) sec that taunts creatures to attack it%.",
            tpl = "Evoca um Totem da Garra de Pedra com %s de vida aos pés do lançador por %s s que provoca criaturas para atacá-lo."
        }
    },
    ["strength of earth totem"] = {
        {
            pat = "Summons a Strength of Earth Totem with 5 health at the feet of the caster for (%d+) min%. The totem increases party members' Strength by (%d+) within (%d+) yards%.",
            tpl = "Evoca um Totem da Força da Terra com 5 de vida aos pés do lançador por %s min. O totem aumenta a Força de membros do grupo em %s a até %s metros."
        },
        {
            pat = "Summons a Strength of Earth Totem with 5 health at the feet of the caster for (%d+) min%. The totem increases the Strength of party members within (%d+) yards by (%d+)%.",
            tpl = "Evoca um Totem da Força da Terra com 5 de vida aos pés do lançador por %s min. O totem aumenta a Força de membros do grupo em até %s metros em %s."
        }
    },
    ["searing totem"] = {
        {
            pat = "Summons a Searing Totem with 5 health at the feet of the caster for (%d+) sec that attacks nearby enemies within (%d+) yards for (%d+ to %d+) Fire damage%.",
            tpl = "Evoca um Totem Calcinante com 5 de vida aos pés do lançador por %s s que ataca inimigos a até %s metros causando %s de dano de Fogo."
        },
        {
            pat = "Summons a Searing Totem with 5 health at the feet of the caster for (%d+) sec that attacks nearby enemies within (%d+) yards for (%d+) to (%d+) Fire damage%.",
            tpl = "Evoca um Totem Calcinante com 5 de vida aos pés do lançador por %s s que ataca inimigos a até %s metros causando %s a %s de dano de Fogo."
        }
    },
    ["fire nova totem"] = {
        {
            pat = "Summons a Fire Nova Totem with 5 health at the feet of the caster that detonates after 4 sec, causing (%d+ to %d+) Fire damage to all nearby enemies within (%d+) yards%.",
            tpl = "Evoca um Totem de Nova de Fogo com 5 de vida aos pés do lançador que detona após 4 s, causando %s de dano de Fogo a inimigos próximos a até %s metros."
        },
        {
            pat = "Summons a Fire Nova Totem with 5 health at the feet of the caster that detonates after 4 sec, causing (%d+) to (%d+) Fire damage to all nearby enemies within (%d+) yards%.",
            tpl = "Evoca um Totem de Nova de Fogo com 5 de vida aos pés do lançador que detona após 4 s, causando %s a %s de dano de Fogo a inimigos próximos a até %s metros."
        }
    },
    ["magma totem"] = {
        {
            pat = "Summons a Magma Totem with 5 health at the feet of the caster for (%d+) sec that causes (%d+) Fire damage to all nearby enemies within (%d+) yards every 2 seconds%.",
            tpl = "Evoca um Totem de Magma com 5 de vida aos pés do lançador por %s s que causa %s de dano de Fogo a inimigos próximos a até %s metros a cada 2 segundos."
        }
    },
    ["flametongue totem"] = {
        {
            pat = "Summons a Flametongue Totem with 5 health at the feet of the caster for (%d+) min%. Party members' weapons within (%d+) yards are imbued with fire, each hit causing (%d+ to %d+) additional Fire damage%.",
            tpl = "Evoca um Totem de Labaredas com 5 de vida aos pés do lançador por %s min. Armas de membros do grupo a até %s metros são imbuidas com fogo, cada golpe causando %s de dano de Fogo adicional."
        }
    },
    ["healing stream totem"] = {
        {
            pat = "Summons a Healing Stream Totem with 5 health at the feet of the caster for (%d+) sec that heals nearby group members for (%d+) every 2 seconds%.",
            tpl = "Evoca um Totem de Torrente Curativa com 5 de vida aos pés do lançador por %s s que cura membros do grupo próximos em %s a cada 2 segundos."
        },
        {
            pat = "Summons a Healing Stream Totem with 5 health at the feet of the caster for (%d+) min that heals nearby group members for (%d+) every 2 seconds%.",
            tpl = "Evoca um Totem de Torrente Curativa com 5 de vida aos pés do lançador por %s min que cura membros do grupo próximos em %s a cada 2 segundos."
        }
    },
    ["mana spring totem"] = {
        {
            pat = "Summons a Mana Spring Totem with 5 health at the feet of the caster for (%d+) sec that restores (%d+) mana every 2 seconds to party members within (%d+) yards%.",
            tpl = "Evoca um Totem de Fonte de Mana com 5 de vida aos pés do lançador por %s s que restaura %s de mana a cada 2 segundos para membros do grupo a até %s metros."
        },
        {
            pat = "Summons a Mana Spring Totem with 5 health at the feet of the caster for (%d+) min that restores (%d+) mana every 2 seconds to party members within (%d+) yards%.",
            tpl = "Evoca um Totem de Fonte de Mana com 5 de vida aos pés do lançador por %s min que restaura %s de mana a cada 2 segundos para membros do grupo a até %s metros."
        }
    },
    ["poison cleansing totem"] = {
        {
            pat = "Summons a Poison Cleansing Totem with 5 health at the feet of the caster for (%d+) min that attempts to remove 1 Poison effect from party members within (%d+) yards every (%d+) seconds%.",
            tpl = "Evoca um Totem de Purificação de Veneno com 5 de vida aos pés do lançador por %s min que tenta remover 1 efeito de Veneno de membros do grupo a até %s metros a cada %s segundos."
        }
    },
    ["disease cleansing totem"] = {
        {
            pat = "Summons a Disease Cleansing Totem with 5 health at the feet of the caster for (%d+) min that attempts to remove 1 Disease effect from party members within (%d+) yards every (%d+) seconds%.",
            tpl = "Evoca um Totem de Purificação de Doença com 5 de vida aos pés do lançador por %s min que tenta remover 1 efeito de Doença de membros do grupo a até %s metros a cada %s segundos."
        }
    },
    ["tremor totem"] = {
        {
            pat = "Summons a Tremor Totem with 5 health at the feet of the caster for (%d+) min that shakes the ground, removing Fear, Charm, and Sleep effects from party members within (%d+) yards%.",
            tpl = "Evoca um Totem de Tremor com 5 de vida aos pés do lançador por %s min que agita a terra, removendo efeitos de Medo, Encantamento e Sono de membros do grupo a até %s metros."
        }
    },
    ["grounding totem"] = {
        {
            pat = "Summons a Grounding Totem with 5 health at the feet of the caster for (%d+) sec that will redirect one harmful spell cast on a nearby party member to itself every (%d+) sec%.",
            tpl = "Evoca um Totem de Aterramento com 5 de vida aos pés do lançador por %s s que redireciona um feitiço nocivo lançado em membros próximos do grupo para si mesmo a cada %s s."
        }
    },
    ["grace of air totem"] = {
        {
            pat = "Summons a Grace of Air Totem with 5 health at the feet of the caster for (%d+) min%. The totem increases the Agility of party members within (%d+) yards by (%d+)%.",
            tpl = "Evoca um Totem da Graça do Ar com 5 de vida aos pés do lançador por %s min. O totem aumenta a Agilidade de membros do grupo em até %s metros em %s."
        }
    },
    ["windfury totem"] = {
        {
            pat = "Summons a Windfury Totem with 5 health at the feet of the caster for (%d+) min%. Party members' main hand weapons within (%d+) yards are imbued with wind, granting each hit a (%d+)%% chance of triggering (%d+) extra attacks with (%d+) bonus attack power%.",
            tpl = "Evoca um Totem de Fúria dos Ventos com 5 de vida aos pés do lançador por %s min. Armas principais de membros do grupo a até %s metros são imbuidas com vento, concedendo a cada golpe %s%% de chance de disparar %s ataques adicionais com %s de poder de ataque extra."
        }
    },
    ["ghost wolf"] = {
        {
            pat = "Transforms the Shaman into a Ghost Wolf, increasing movement speed by (%d+)%%%. Can only be used outdoors%.",
            tpl = "Transforma o Xamã em um Lobo Fantasma, aumentando a velocidade de movimento em %s%%. Pode ser usado apenas ao ar livre."
        }
    },
    ["astral recall"] = {
        {
            pat = "Yanks the caster through the astral planes back to your home location%. Speak to an Innkeeper in a different place to change your home location%.",
            tpl = "Puxa o lançador através dos planos astrais de volta ao seu local de refúgio. Fale com um Estalajadeiro em outro local para mudar sua pedra de regresso."
        }
    },
    ["reincarnation"] = {
        {
            pat = "Allows you to resurrect yourself upon death with (%d+)%% health and mana%. Cannot be used more than once every (%d+) min%.",
            tpl = "Permite ressuscitar a si mesmo após a morte com %s%% de vida e mana. Não pode ser usado mais de uma vez a cada %s min."
        }
    },
    ["purge"] = {
        {
            pat = "Purges the enemy target, removing (%d+) beneficial magic effects?%.",
            tpl = "Purifica o alvo inimigo, removendo %s efeito(s) mágico(s) benéfico(s)."
        }
    },
    ["cure poison"] = {
        {
            pat = "Cures 1 Poison effect on a friendly target%.",
            tpl = "Cura 1 efeito de Veneno em um alvo aliado."
        }
    },
    ["cure disease"] = {
        {
            pat = "Cures 1 Disease effect on a friendly target%.",
            tpl = "Cura 1 efeito de Doença em um alvo aliado."
        }
    },
    ["water walking"] = {
        {
            pat = "Allows the friendly target to walk on water for (%d+) min%. Any damage will cancel the effect%.",
            tpl = "Permite que o alvo aliado caminhe sobre a água por %s min. Qualquer dano recebido cancelará o efeito."
        }
    },
    ["water breathing"] = {
        {
            pat = "Allows the friendly target to breathe underwater for (%d+) min%.",
            tpl = "Permite que o alvo aliado respire debaixo d'água por %s min."
        }
    },
    ["ancestral spirit"] = {
        {
            pat = "Returns the spirit to the body, restoring a dead target to life with (%d+) health and (%d+) mana%. Cannot be cast when in combat%.",
            tpl = "Devolve o espírito ao corpo, trazendo um alvo morto de volta à vida com %s de vida e %s de mana. Não pode ser lançado em combate."
        }
    },
    ["far sight"] = {
        {
            pat = "Changes the caster's perspective to the targeted location for (%d+) min%.",
            tpl = "Muda a perspectiva do lançador para o local selecionado por %s min."
        }
    },
    -- GERAIS E RACIAIS
    ["attack"] = {
        {
            pat = "Attacks the target for weapon damage%.",
            tpl = "Ataca o alvo causando dano da arma."
        },
        {
            pat = "Continuously attack the target%.",
            tpl = "Ataca o alvo continuamente."
        }
    },
    ["auto attack"] = {
        {
            pat = "Attacks the target for weapon damage%.",
            tpl = "Ataca o alvo causando dano da arma."
        },
        {
            pat = "Continuously attack the target%.",
            tpl = "Ataca o alvo continuamente."
        }
    },
    ["shoot"] = {
        {
            pat = "Shoots the target with your ranged weapon%.",
            tpl = "Dispara no alvo com sua arma de longo alcance."
        }
    },
    ["throw"] = {
        {
            pat = "Throws your ranged weapon at the target%.",
            tpl = "Arremessa sua arma de arremesso no alvo."
        }
    },
    ["war stomp"] = {
        {
            pat = "Stuns up to (%d+) enemies within (%d+) yds for (%d+) sec%.",
            tpl = "Atordoa até %s inimigos em até %s metros por %s s."
        }
    },
    ["blood fury"] = {
        {
            pat = "Increases base melee attack power by (%d+) for (%d+) sec and reduces healing effects on you by (%d+)%% for (%d+) sec%.",
            tpl = "Aumenta o poder de ataque corpo a corpo básico em %s por %s s e reduz a eficácia de curas recebidas em %s%% por %s s."
        }
    },
    ["berserking"] = {
        {
            pat = "Increases your casting and attack speed by (%d+)%% to (%d+)%%%.?.*",
            tpl = "Aumenta a velocidade de lançamento e ataque em %s%% a %s%%. Dura 10 s."
        }
    },
    ["will of the forsaken"] = {
        {
            pat = "Provides immunity to Charm, Fear and Sleep while active%. Lasts (%d+) sec%.",
            tpl = "Concede imunidade a Encantamento, Medo e Sono enquanto ativo. Dura %s s."
        }
    },
    ["cannibalize"] = {
        {
            pat = "When activated, regenerates (%d+)%% of total health every (%d+) sec for (%d+) sec%. Only works on Humanoid or Undead corpses within (%d+) yds%. Any movement, action, or damage taken while Cannibalizing will cancel the effect%.",
            tpl = "Ao ser ativado, regenera %s%% da vida total a cada %s s por %s s. Funciona apenas em cadáveres Humanóides ou Mortos-vivos a até %s metros. Qualquer movimento cancela o efeito."
        }
    },
    -- WARRIOR
    ["heroic strike"] = {
        {
            pat = "A strong attack that increases melee damage by (%d+) and causes a high amount of threat%.",
            tpl = "Um ataque forte que aumenta o dano corpo a corpo em %s e causa uma quantidade alta de ameaça."
        }
    },
    ["rend"] = {
        {
            pat = "Wounds the target who bleeds for (%d+) damage over (%d+) sec%.",
            tpl = "Fere o alvo, fazendo-o sangrar por %s de dano ao longo de %s s."
        }
    },
    ["thunder clap"] = {
        {
            pat = "Blasts nearby enemies with thunder, increasing the time between their attacks by (%d+)%% for (%d+) sec and dealing (%d+) Nature damage to them%. Affects up to (%d+) targets%.",
            tpl = "Atinge inimigos próximos com um estrondo de trovão, aumentando o intervalo entre seus ataques em %s%% por %s s e causando %s de dano de Natureza a eles. Afeta até %s alvos."
        }
    },
    ["battle shout"] = {
        {
            pat = "The warrior shouts, increasing melee attack power of all party members within (%d+) yards by (%d+)%. Lasts (%d+) min%.",
            tpl = "O guerreiro brada, aumentando o poder de ataque corpo a corpo de todos os membros do grupo em até %s metros em %s. Dura %s min."
        }
    },
    ["demoralizing shout"] = {
        {
            pat = "Reduces the melee attack power of all nearby enemies by (%d+) for (%d+) sec%.",
            tpl = "Reduz o poder de ataque corpo a corpo de todos os inimigos próximos em %s por %s s."
        }
    },
    ["sunder armor"] = {
        {
            pat = "Sunders the target's armor, reducing armor by (%d+) per Sunder Armor and causes a high amount of threat%. Can be applied up to (%d+) times%. Lasts (%d+) sec%.",
            tpl = "Fende a armadura do alvo, reduzindo a armadura em %s por aplicação e causando uma grande quantidade de ameaça. Pode ser aplicado até %s vezes. Dura %s s."
        }
    },
    ["shield block"] = {
        {
            pat = "Increases chance to block by (%d+)%% and allows the warrior to block (%d+) additional attacks?%. Lasts (%d+) sec%.",
            tpl = "Aumenta a chance de bloqueio em %s%% e permite ao guerreiro bloquear %s ataque adicional. Dura %s s."
        }
    },

    -- ROGUE
    ["sinister strike"] = {
        {
            pat = "A vicious strike that deals (%d+) extra damage on top of your normal weapon damage%.",
            tpl = "Um golpe traiçoeiro que causa %s de dano adicional além do dano normal da arma."
        },
        {
            pat = "A vicious strike that deals normal weapon damage plus (%d+)%. Awards (%d+) combo point%.",
            tpl = "Um golpe traiçoeiro que causa o dano normal da arma mais %s. Concede %s ponto de combo."
        }
    },
    ["backstab"] = {
        {
            pat = "Backstab the target, causing (%d+)%% weapon damage plus (%d+) to the target%. Must be behind the target%. Only works with daggers%. Awards (%d+) combo point%.",
            tpl = "Apunhala o alvo pelas costas, causando %s%% do dano da arma mais %s. Requer estar atrás do alvo. Requer adaga. Concede %s ponto de combo."
        }
    },
    ["eviscerate"] = {
        {
            pat = "Finishing move that causes damage per combo point:.*",
            tpl = "Golpe finalizador que causa dano crescente de acordo com os pontos de combo acumulados no alvo."
        }
    },
    ["slice and dice"] = {
        {
            pat = "Finishing move that increases melee attack speed by (%d+)%%%. Lasts longer per combo point:.*",
            tpl = "Golpe finalizador que aumenta a velocidade de ataque corpo a corpo em %s%%. A duração aumenta de acordo com os pontos de combo."
        }
    },

    -- MAGE
    ["fireball"] = {
        {
            pat = "Hurls a fiery ball that causes (%d+ to %d+) Fire damage and an additional (%d+) Fire damage over (%d+) sec%.",
            tpl = "Arremessa uma bola de fogo que causa %s de dano de Fogo e mais %s de dano de Fogo ao longo de %s s."
        },
        {
            pat = "Hurls a fiery ball that causes (%d+) to (%d+) Fire damage and an additional (%d+) Fire damage over (%d+) sec%.",
            tpl = "Arremessa uma bola de fogo que causa %s a %s de dano de Fogo e mais %s de dano de Fogo ao longo de %s s."
        }
    },
    ["frostbolt"] = {
        {
            pat = "Launches a bolt of frost at the enemy, causing (%d+ to %d+) Frost damage and slowing movement speed by (%d+)%% for (%d+) sec%.",
            tpl = "Dispara uma seta de gelo no inimigo, causando %s de dano de Gelo e reduzindo a velocidade de movimento em %s%% por %s s."
        },
        {
            pat = "Launches a bolt of frost at the enemy, causing (%d+) to (%d+) Frost damage and slowing movement speed by (%d+)%% for (%d+) sec%.",
            tpl = "Dispara uma seta de gelo no inimigo, causando %s a %s de dano de Gelo e reduzindo a velocidade de movimento em %s%% por %s s."
        }
    },
    ["arcane intellect"] = {
        {
            pat = "Infuses the target with brilliance, increasing their Intellect by (%d+) for (%d+) min%.",
            tpl = "Infunde o alvo com brilho, aumentando seu Intelecto em %s por %s min."
        }
    },
    ["frost armor"] = {
        {
            pat = "Increases armor by (%d+)%. If an enemy strikes the caster with a melee attack, their movement speed is reduced by (%d+)%% and the time between their attacks is increased by (%d+)%% for (%d+) sec%. Lasts (%d+) min%.",
            tpl = "Aumenta a armadura em %s. Se um inimigo atingir o lançador com um ataque corpo a corpo, sua velocidade de movimento é reduzida em %s%% e o intervalo entre ataques é aumentado em %s%% por %s s. Dura %s min."
        }
    },

    -- PRIEST
    ["power word: fortitude"] = {
        {
            pat = "Power infuses the target, increasing their Stamina by (%d+) for (%d+) min%.",
            tpl = "O poder infunde o alvo, aumentando sua Determinação em %s por %s min."
        }
    },
    ["power word: shield"] = {
        {
            pat = "Draws on the soul of the friendly target to shield them, absorbing (%d+) damage%. Lasts (%d+) sec%. While the shield holds, spells will not be interrupted by damage%. Once shielded, the target cannot be shielded again for (%d+) sec%.",
            tpl = "Canaliza a alma do alvo aliado para protegê-lo, absorvendo %s de dano. Dura %s s. Enquanto o escudo estiver ativo, feitiços não serão interrompidos por dano. Após protegido, o alvo não pode receber outro escudo por %s s."
        }
    },
    ["renew"] = {
        {
            pat = "Heals the target for (%d+) over (%d+) sec%.",
            tpl = "Cura o alvo em %s ao longo de %s s."
        }
    },
    ["flash heal"] = {
        {
            pat = "Heals a friendly target for (%d+ to %d+)%.",
            tpl = "Cura um alvo aliado em %s."
        }
    },

    -- WARLOCK
    ["shadow bolt"] = {
        {
            pat = "Sends a shadowy bolt at the enemy, causing (%d+ to %d+) Shadow damage%.",
            tpl = "Lança uma seta sombria contra o inimigo, causando %s de dano de Sombra."
        },
        {
            pat = "Sends a shadowy bolt at the enemy, causing (%d+) to (%d+) Shadow damage%.",
            tpl = "Lança uma seta sombria contra o inimigo, causando %s a %s de dano de Sombra."
        }
    },
    ["corruption"] = {
        {
            pat = "Corrupts the target, causing (%d+) Shadow damage over (%d+) sec%.",
            tpl = "Corrompe o alvo, causando %s de dano de Sombra ao longo de %s s."
        }
    },
    ["curse of agony"] = {
        {
            pat = "Curses the target with agony, causing (%d+) Shadow damage over (%d+) sec%. This damage begins slowly, but increases as the curse reaches its full duration%. Only one Curse per Warlock can be active on any one target%.",
            tpl = "Amaldiçoa o alvo com agonia, causando %s de dano de Sombra ao longo de %s s. Este dano começa fraco, mas aumenta conforme a maldição atinge sua duração total. Apenas uma Maldição por Bruxo pode estar ativa em um alvo."
        }
    },
    ["immolate"] = {
        {
            pat = "Burns the enemy for (%d+) Fire damage and then an additional (%d+) Fire damage over (%d+) sec%.",
            tpl = "Queima o inimigo causando %s de dano de Fogo e mais %s de dano de Fogo adicional ao longo de %s s."
        }
    },

    -- DRUID
    ["healing touch"] = {
        {
            pat = "Heals a friendly target for (%d+ to %d+)%.",
            tpl = "Cura um alvo aliado em %s."
        },
        {
            pat = "Heals a friendly target for (%d+) to (%d+)%.",
            tpl = "Cura um alvo aliado em %s a %s."
        }
    },
    ["rejuvenation"] = {
        {
            pat = "Heals the target for (%d+) over (%d+) sec%.",
            tpl = "Cura o alvo em %s ao longo de %s s."
        }
    },
    ["moonfire"] = {
        {
            pat = "Burns the enemy for (%d+ to %d+) Arcane damage and then an additional (%d+) Arcane damage over (%d+) sec%.",
            tpl = "Queima o inimigo causando %s de dano Arcano e mais %s de dano Arcano ao longo de %s s."
        }
    },
    ["mark of the wild"] = {
        {
            pat = "Increases the friendly target's armor by (%d+) for (%d+) min%.",
            tpl = "Aumenta a armadura do alvo aliado em %s por %s min."
        },
        {
            pat = "Increases the friendly target's armor by (%d+), all attributes by (%d+) and all resistances by (%d+) for (%d+) min%.",
            tpl = "Aumenta a armadura do alvo aliado em %s, todos os atributos em %s e todas as resistências em %s por %s min."
        }
    },
}

-- ----------------------------------------------------------------------------
-- 3. Templates Genericos de Descricoes de Magias (Regex Reutilizavel)
-- ----------------------------------------------------------------------------
CM_SpellDesc_ptBR.genericTemplates = {
    -- Curas Diretas
    {
        pat = "^Heals a friendly target for (%d+ to %d+)%.$",
        tpl = "Cura um alvo aliado em %s."
    },
    {
        pat = "^Heals a friendly target for (%d+) to (%d+)%.$",
        tpl = "Cura um alvo aliado em %s a %s."
    },
    -- Curas Periodicas (HoTs)
    {
        pat = "^Heals the target for (%d+) over (%d+) sec%.$",
        tpl = "Cura o alvo em %s ao longo de %s s."
    },
    -- Danos com Dano Inicial + Dano Periodico (ex: Imolate, Moonfire, etc.)
    {
        pat = "^Burns the enemy for (%d+ to %d+) ([%w%s]+) damage and then an additional (%d+) ([%w%s]+) damage over (%d+) sec%.$",
        tpl = function(m1, s1, m2, s2, dur)
            local escola = CM_SpellDesc_ptBR.terms[s1] or s1
            return string.format("Queima o inimigo causando %s de dano de %s e mais %s de dano de %s adicional ao longo de %s s.", m1, escola, m2, escola, dur)
        end
    },
    -- Danos Periodicos Simples (DoTs)
    {
        pat = "^Causes (%d+) ([%w%s]+) damage over (%d+) sec%.$",
        tpl = function(val, school, dur)
            local escola = CM_SpellDesc_ptBR.terms[school] or school
            return string.format("Causa %s de dano de %s ao longo de %s s.", val, escola, dur)
        end
    },
    -- Buffs de Atributo Simples
    {
        pat = "^Increases the target's ([%w%s]+) by (%d+) for (%d+) min%.$",
        tpl = function(attr, val, dur)
            local atMap = { ["Stamina"] = "Determinação", ["Intellect"] = "Intelecto", ["Strength"] = "Força", ["Agility"] = "Agilidade", ["Spirit"] = "Espírito", ["Armor"] = "armadura" }
            local nomeAt = atMap[attr] or attr
            return string.format("Aumenta %s do alvo em %s por %s min.", nomeAt, val, dur)
        end
    },
    -- Buffs de Armadura
    {
        pat = "^Increases armor by (%d+) for (%d+) min%.$",
        tpl = "Aumenta a armadura em %s por %s min."
    },
    {
        pat = "^Increases armor by (%d+)%.$",
        tpl = "Aumenta a armadura em %s."
    },
    -- Bônus de Dano de Arma
    {
        pat = "^An attack that increases melee damage by (%d+)%.$",
        tpl = "Um ataque que aumenta o dano corpo a corpo em %s."
    },
    {
        pat = "^A strike that deals (%d+) extra damage on top of your normal weapon damage%.$",
        tpl = "Um golpe que causa %s de dano adicional além do dano normal da arma."
    },
}
