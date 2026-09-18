#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera lote completo de traduções Blizzlike humanas para TODOS os Totens e TODAS as Raciais.
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

totems = json.loads((ADDON_DIR / "tools" / "all_totems.json").read_text(encoding="utf-8"))
racials = json.loads((ADDON_DIR / "tools" / "all_racials.json").read_text(encoding="utf-8"))

translations = {}

def translate_totem(en):
    # Fire Nova Totem (evocação)
    if en.startswith("Summons a Fire Nova Totem"):
        return "Evoca um Totem de Nova de Fogo com $s1 de vida aos pés do lançador por $d s. A menos que seja destruído dentro de $t1 s, o totem detona causando $s2 de dano de Fogo a inimigos a até $a1 metros."
    
    # Searing Totem (evocação)
    if en.startswith("Summons a Searing Totem"):
        return "Evoca um Totem Incandescente com $s1 de vida aos pés do lançador por $d s que ataca repetidamente um inimigo a até $a1 metros, causando $s2 de dano de Fogo."
    
    # Magma Totem (evocação)
    if en.startswith("Summons a Magma Totem"):
        return "Evoca um Totem de Magma com $s1 de vida aos pés do lançador por $d s que causa $s2 de dano de Fogo a inimigos a até $a1 metros a cada $t1 segundos."
    
    # Healing Stream Totem (evocação)
    if en.startswith("Summons a Healing Stream Totem"):
        return "Evoca um Totem de Torrente Curativa com $s1 de vida aos pés do lançador por $d s que cura membros do grupo a até $a1 metros em $s2 a cada $t1 segundos."
    
    # Mana Spring Totem (evocação)
    if en.startswith("Summons a Mana Spring Totem"):
        return "Evoca um Totem de Fonte de Mana com $s1 de vida aos pés do lançador por $d s que restaura $s2 de mana a cada $t1 segundos dos membros do grupo a até $a1 metros."
    
    # Mana Tide Totem (evocação)
    if en.startswith("Summons a Mana Tide Totem"):
        return "Evoca um Totem de Maré de Mana com $s1 de vida aos pés do lançador por $d s que restaura $s2 de mana a cada $t1 segundos para todos os membros do grupo a até $a1 metros."
    
    # Stoneclaw Totem (evocação)
    if en.startswith("Summons a Stoneclaw Totem"):
        return "Evoca um Totem de Garra de Pedra com $s1 de vida aos pés do lançador por $d s que provoca criaturas a até $a1 metros para atacá-lo."
    
    # Stoneskin Totem (evocação)
    if en.startswith("Summons a Stoneskin Totem"):
        return "Evoca um Totem de Pele de Pedra com $s1 de vida aos pés do lançador. O totem protege membros do grupo a até $a1 metros, reduzindo o dano corpo a corpo sofrido em $s2. Dura $d s."
    
    # Strength of Earth Totem (evocação)
    if en.startswith("Summons a Strength of Earth Totem"):
        return "Evoca um Totem de Força da Terra com $s1 de vida aos pés do lançador. O totem aumenta a Força dos membros do grupo a até $a1 metros em $s2. Dura $d s."
    
    # Grace of Air Totem (evocação)
    if en.startswith("Summons a Grace of Air Totem"):
        return "Evoca um Totem de Graça do Ar com $s1 de vida aos pés do lançador. O totem aumenta a Agilidade dos membros do grupo a até $a1 metros em $s2. Dura $d s."
    
    # Windfury Totem (evocação)
    if en.startswith("Summons a Windfury Totem"):
        # Note: 20% é fixo no texto original
        return "Evoca um Totem de Fúria dos Ventos com $s1 de vida aos pés do lançador. O totem encanta com vento as armas da mão principal dos aliados a até $a1 metros, concedendo 20% de chance a cada golpe de desferir $s2 ataques extras com $s3 de poder de ataque adicional. Dura $d s."
    
    # Windwall Totem (evocação)
    if en.startswith("Summons a Windwall Totem"):
        return "Evoca um Totem de Cortina de Vento com $s1 de vida aos pés do lançador. O totem protege os aliados a até $a1 metros, reduzindo o dano de longo alcance sofrido em $s2. Dura $d s."
    
    # Frost Resistance Totem (evocação)
    if en.startswith("Summons a Frost Resistance Totem"):
        return "Evoca um Totem de Resistência ao Gelo com $s1 de vida aos pés do lançador. O totem aumenta a resistência a Gelo dos membros do grupo a até $a1 metros em $s2. Dura $d s."
    
    # Fire Resistance Totem (evocação)
    if en.startswith("Summons a Fire Resistance Totem"):
        return "Evoca um Totem de Resistência ao Fogo com $s1 de vida aos pés do lançador. O totem aumenta a resistência a Fogo dos membros do grupo a até $a1 metros em $s2. Dura $d s."
    
    # Nature Resistance Totem (evocação)
    if en.startswith("Summons a Nature Resistance Totem"):
        return "Evoca um Totem de Resistência à Natureza com $s1 de vida aos pés do lançador. O totem aumenta a resistência a Natureza dos membros do grupo a até $a1 metros em $s2. Dura $d s."
    
    # Poison Cleansing Totem (evocação)
    if en.startswith("Summons a Poison Cleansing Totem"):
        return "Evoca um Totem Purificador de Veneno com $s1 de vida aos pés do lançador que tenta remover 1 efeito de Veneno dos membros do grupo a até $a1 metros a cada $t1 segundos. Dura $d s."
    
    # Disease Cleansing Totem (evocação)
    if en.startswith("Summons a Disease Cleansing Totem"):
        return "Evoca um Totem Purificador de Doenças com $s1 de vida aos pés do lançador que tenta remover 1 efeito de Doença dos membros do grupo a até $a1 metros a cada $t1 segundos. Dura $d s."
    
    # Tremor Totem (evocação)
    if en.startswith("Summons a Tremor Totem"):
        return "Evoca um Totem de Tremor com $s1 de vida aos pés do lançador que abala o solo, removendo efeitos de Medo, Encantamento e Sono dos membros do grupo a até $a1 metros. Dura $d s."
    
    # Grounding Totem (evocação)
    if en.startswith("Summons a Grounding Totem"):
        return "Evoca um Totem de Aterramento com $s1 de vida aos pés do lançador que absorve um feitiço hostil lançado contra um membro do grupo a cada $t1 s. Não redireciona feitiços de efeito em área. Dura $d s."

    # Earthbind Totem (evocação)
    if en.startswith("Summons an Earthbind Totem"):
        if "slows the movement speed" in en:
            return "Evoca um Totem Aprisionador da Terra com $s1 de vida aos pés do lançador por $d s que reduz a velocidade de movimento de inimigos em um raio de $a1 metros."
        if "periodically reduces" in en:
            return "Evoca um Totem Aprisionador da Terra que dura $d s e periodicamente reduz a velocidade de movimento dos inimigos próximos para $s1% do normal."

    # Flametongue Totem (evocação)
    if en.startswith("Summons a Flametongue Totem"):
        return "Evoca um Totem de Labaredas com $s1 de vida aos pés do lançador que encanta as armas dos aliados a até $a1 metros com de $s2 a $s3 de dano de Fogo adicional. Armas lentas causam mais dano por golpe. Dura $d s."

    # Talentos e Modificadores de Totens
    if en == "Reduces the delay before your Fire Nova Totem activates by $/1000;s1 sec and decreases the threat generated by your Magma Totem by $s3%.":
        return "Reduz o intervalo antes da ativação do Totem de Nova de Fogo em $s1 s e diminui a ameaça gerada pelo Totem de Magma em $s2%."
    if en == "Reduces the Mana cost of your Magma Totem by $s1%.":
        return "Reduz o custo de mana do seu Totem de Magma em $s1%."
    if en == "Increases the duration of your Searing Totem by $s1%.":
        return "Aumenta a duração do seu Totem Incandescente em $s1%."
    if en == "Increases the Health of your Stoneclaw Totem by $s1%.":
        return "Aumenta os pontos de vida do seu Totem de Garra de Pedra em $s1%."
    if en == "Increases the effect of your Healing Stream Totem by $s1%.":
        return "Aumenta a eficácia de cura do seu Totem de Torrente Curativa em $s1%."
    if en == "Reduces mana cost of your Mana Spring Totem by $s2% and increases the effect of your Healing Stream Totem by $s1%.":
        return "Reduz o custo de mana do seu Totem de Fonte de Mana em $s1% e aumenta a eficácia do seu Totem de Torrente Curativa em $s2%."
    if en == "Increases the effects of your Flametongue and Windfury Totems by $s1%.":
        return "Aumenta a eficácia dos seus Totens de Labaredas e de Fúria dos Ventos em $s1%."
    if en == "Increases the amount of damage reduced by your Stoneskin Totem and Windwall Totem by $s1% and reduces the cooldown of your Grounding Totem by $/1000;s2 sec.":
        return "Aumenta a quantidade de dano reduzido pelos seus Totens de Pele de Pedra e Cortina de Vento em $s1% e reduz a recarga do seu Totem de Aterramento em $s2 s."

    return None

def translate_racial(en):
    # Blood Fury
    if "Increases attack power by $*2;s1" in en or ("Blood Fury" in en and "attack power" in en):
        return "Aumenta o poder de ataque corpo a corpo em $s1 e o dano de feitiços e efeitos mágicos em até $s2 por $d s, mas reduz a eficácia de quaisquer curas recebidas por você em $s3% por $d1 s."
    if "Instantly increases your rage by $/10;s1." in en:
        return "Aumenta instantaneamente a sua Raiva em $s1 pontos."
    
    # War Stomp
    if "Stuns up to $i enemies within $a1 yds for $d." in en or "Stuns up to $i enemies" in en:
        return "Bate no chão com violência, atordoando até $i inimigos a até $a1 metros por $d s."
    
    # Berserking
    if "Increases your attack speed by $s1% to $s2%" in en or "Increases your casting and attack speed by $s1% to $s2%" in en:
        return "Aumenta a velocidade dos seus ataques e lançamento de feitiços em $s1% a $s2%. Com menos vida restante, o bônus de velocidade é maior. Dura $d s."
    
    # Will of the Forsaken
    if "Provides immunity to Charm, Fear and Sleep" in en:
        return "Concede imunidade aos efeitos de Encantamento, Medo e Sono enquanto estiver ativa. Também pode ser usada se você já estiver sob o efeito de Encantamento, Medo ou Sono. Dura $d s."
    
    # Cannibalize
    if "Increases health regeneration by $s1%" in en and "humanoid or undead corpse" in en:
        return "Quando ativado, regenera $s1% da Vida total a cada $t1 s por $d s. Só pode ser usado perto de cadáveres humanoides ou mortos-vivos a até 5 metros. Qualquer ação cancela o efeito."
    
    # Perception
    if "Dramatically increases stealth detection for $d." in en:
        return "Aumenta drasticamente a sua detecção de alvos em furtividade por $d s."
    
    # The Human Spirit
    if "Spirit increased by $s1%." in en:
        return "Aumenta o seu Espírito total em $s1%."
    
    # Sword Specialization
    if "Sword and Two-Handed Sword skill increased by $s1." in en:
        return "Perícia com Espadas e Espadas de Duas Mãos aumentada em $s1."
    
    # Mace Specialization
    if "Mace and Two-Handed Mace skill increased by $s1." in en:
        return "Perícia com Maças e Maças de Duas Mãos aumentada em $s1."
    
    # Diplomacy
    if "Reputation gains increased by $s1%." in en:
        return "Ganhos de reputação aumentados em $s1%."
    
    # Stoneform
    if "While active, grants immunity to Bleed, Poison, and Disease" in en:
        return "Enquanto ativa, concede imunidade a Sangramento, Veneno e Doença, além de aumentar a sua armadura em $s1 por $d s."
    
    # Resistances
    if "Your resistance to Frost spells is increased by $s1." in en:
        return "Aumenta a sua resistência a feitiços de Gelo em $s1."
    if "Your resistance to Nature spells is increased by $m1." in en or "Your resistance to Nature spells is increased by $s1." in en:
        return "Aumenta a sua resistência a feitiços de Natureza em $s1."
    if "Your resistance to Shadow spells is increased by $s1." in en:
        return "Aumenta a sua resistência a feitiços de Sombra em $s1."
    if "Your resistance to Arcane spells is increased by $s1." in en:
        return "Aumenta a sua resistência a feitiços Arcanos em $s1."
    
    # Gun Specialization
    if "Guns skill increased by $s1." in en:
        return "Perícia com Armas de Fogo aumentada em $s1."
    
    # Find Treasure
    if "Allows the dwarf to sense nearby treasure" in en:
        return "Permite que o anão sinta a presença de tesouros próximos, fazendo-os aparecer no minimapa. Dura $d s."
    
    # Escape Artist
    if "Escape the effects of any immobilization or movement speed reduction effect." in en:
        return "Liberta o lançador de quaisquer efeitos de imobilização ou de redução de velocidade de movimento."
    
    # Expansive Mind
    if "Intellect increased by $s1%." in en:
        return "Aumenta o seu Intelecto total em $s1%."
    
    # Engineering Specialization
    if "Engineering skill increased by $s1." in en:
        return "Perícia em Engenharia aumentada em $s1."
    
    # Shadowmeld
    if "Activate to slip into the shadows" in en:
        if "$20581d" in en or "$d" in en:
            return "Ative para deslizar nas sombras, reduzindo a chance de inimigos detectarem a sua presença. Permanece ativo até se mover e continua ativo por $d s após qualquer ação. Ladinos e Druidas com Fusão Sombria são mais difíceis de detectar em furtividade."
        return "Ative para deslizar nas sombras, reduzindo a chance de inimigos detectarem a sua presença. Permanece ativo até se mover ou realizar qualquer ação."
    
    # Quickness
    if "Dodge chance increased by $s1%." in en:
        return "Aumenta a sua chance de Esquiva em $s1%."
    
    # Wisp Spirit
    if "Transform into a wisp upon death" in en:
        return "Transforma-se em um Fogo-fátuo após a morte, aumentando a velocidade de movimento em $s1%."
    
    # Endurance
    if "Total Health increased by $s1%." in en:
        return "Aumenta a sua Vida total em $s1%."
    
    # Cultivation
    if "Herbalism skill increased by $s1." in en:
        return "Perícia em Herborismo aumentada em $s1."
    
    # Beast Slaying
    if "Damage dealt versus Beasts increased by $s1%." in en:
        return "Dano causado contra Feras aumentado em $s1%."
    
    # Throwing Specialization
    if "Throwing Weapons skill increased by $s1." in en:
        return "Perícia com Armas de Arremesso aumentada em $s1."
    
    # Bow Specialization
    if "Bow skill increased by $s1." in en:
        return "Perícia com Arcos aumentada em $s1."
    
    # Regeneration
    if "Health regeneration rate increased by $s1%." in en:
        return "Taxa de regeneração de vida aumentada em $s1%. $s2% da sua regeneração de vida total pode continuar ativa durante o combate."
    
    # Underwater Breathing
    if "Underwater breath lasts $s1% longer than normal." in en:
        return "A sua respiração debaixo d'água dura $s1% a mais que o normal."

    return None

for t in totems:
    en = t["en"]
    tr = translate_totem(en)
    if tr:
        translations[en] = tr

for r in racials:
    en = r["en"]
    tr = translate_racial(en)
    if tr:
        translations[en] = tr

print(f"Total de traduções geradas: {len(translations)}")

out_path = ADDON_DIR / "tools" / "batches" / "batch_totems_racials_translated.json"
out_path.write_text(json.dumps(translations, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"Salvo em {out_path}")
