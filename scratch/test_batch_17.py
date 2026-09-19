# -*- coding: utf-8 -*-
import json
import sys
sys.path.append('C:/PROJETOS/ConsoleModeVanilla/tools')
from validate_spell_vars import validate_pair

translations = {
    "Teleports the caster to Undercity.": "Teleporta o lançador para a Cidade Baixa.",
    "Teleports the caster to Darnassus.": "Teleporta o lançador para Darnassus.",
    "Teleports the caster to Thunder Bluff.": "Teleporta o lançador para o Penhasco do Trovão.",
    "Teleports the caster to Orgrimmar.": "Teleporta o lançador para Orgrimmar.",
    "Teaches Immolate (Rank 4).": "Ensina Imolação (Grau 4).",
    "Teaches Exorcism (Rank 1).": "Ensina Exorcismo (Grau 1).",
    "Teaches Seal of Reckoning (Rank 1).": "Ensina Selo do Ajuste de Contas (Grau 1).",
    "Teaches Seal of Reckoning (Rank 2).": "Ensina Selo do Ajuste de Contas (Grau 2).",
    "Teaches Conjure Water (Rank 2).": "Ensina Conjurar Água (Grau 2).",
    "Teaches Divine Protection (Rank 1).": "Ensina Proteção Divina (Grau 1).",
    "Teaches Health Funnel (Rank 2).": "Ensina Canalizar Vida (Grau 2).",
    "Teaches Health Funnel (Rank 3).": "Ensina Canalizar Vida (Grau 3).",
    "Teaches Health Funnel (Rank 4).": "Ensina Canalizar Vida (Grau 4).",
    "Teaches Seal of Wisdom (Rank 2).": "Ensina Selo da Sabedoria (Grau 2).",
    "Taunts the creature, dealing $s2 Shadow damage and increasing the chance that it will attack the Voidwalker.": "Provoca a criatura, causando $s2 de dano de Sombra e aumentando a chance de ela atacar o Emissário do Caos.",
    "Teaches Conjure Mana Gem.": "Ensina Conjurar Gema de Mana.",
    "Teaches Purify.": "Ensina Purificar.",
    "Teaches Earthbind Totem.": "Ensina Totem Aprisionador da Terra.",
    "Teaches Shock (Rank 4).": "Ensina Choque (Grau 4).",
    "Teaches Shock (Rank 5).": "Ensina Choque (Grau 5).",
    "Teaches Serpent Totem (Rank 1).": "Ensina Totem da Serpente (Grau 1).",
    "Teaches Hellfire.": "Ensina Fogo do Inferno.",
    "Teaches Healing Touch (Rank 6).": "Ensina Toque de Cura (Grau 6).",
    "Teaches Wrath (Rank 6).": "Ensina Cólera (Grau 6).",
    "Teaches Cure Poison (Rank 3).": "Ensina Curar Veneno (Grau 3).",
    "Teaches Rejuvenation (Rank 6).": "Ensina Rejuvenescimento (Grau 6).",
    "Teaches Serpent Totem (Rank 2).": "Ensina Totem da Serpente (Grau 2).",
    "Teaches Rain of Fire (Rank 2).": "Ensina Chuva de Fogo (Grau 2).",
    "Teaches Shadow Word: Pain (Rank 5).": "Ensina Palavra Sombria: Dor (Grau 5).",
    "Teaches Heal (Rank 1).": "Ensina Cura (Grau 1).",
    "Allows an engineer to make basic contraptions up to a maximum potential skill of 75.  Requires stone and metal found with the mining skill.": "Permite que um engenheiro crie engenhocas básicas até uma perícia máxima potencial de 75. Requer pedra e metal encontrados com a perícia de Mineração.",
    "Increases the caster's chance to dodge by $s1%. Lasts until cancelled.": "Aumenta a chance de esquiva do lançador em $s1%. Dura até ser cancelado.",
    "Increases your Health by 40.": "Aumenta a sua Vida em 40.",
    "Increases your Health by 50.": "Aumenta a sua Vida em 50.",
    "Increases your Health by 60.": "Aumenta a sua Vida em 60.",
    "Increases your Health by 80.": "Aumenta a sua Vida em 80.",
    "Does $o1 fire damage to all enemies in the area of effect over $d.": "Causa $s1 de dano de Fogo a todos os inimigos na área de efeito ao longo de $d s.",
    "Increases your chance to block with a Shield (not a Buckler) by 2%.": "Aumenta a sua chance de bloquear com um Escudo (não um Broquel) em 2%.",
    "Increases your chance to block with a shield by 2%.": "Aumenta a sua chance de bloquear com um escudo em 2%.",
    "Increases your chance to block with a Shield (not a Buckler) by 4% and reflects $s2% of hostile spells back at the caster.": "Aumenta a sua chance de bloquear com um Escudo (não um Broquel) em 4% e reflete $s2% dos feitiços hostis de volta ao lançador.",
    "Increases your chance to block with a Shield (not a Buckler) by 5% and reflects $s2% of hostile spells back at the caster.": "Aumenta a sua chance de bloquear com um Escudo (não um Broquel) em 5% e reflete $s2% dos feitiços hostis de volta ao lançador.",
    "Increases your chance to block with a Shield (not a Buckler) by 2% and reflects 1% of hostile spells back at the caster.": "Aumenta a sua chance de bloquear com um Escudo (não um Broquel) em 2% e reflete 1% dos feitiços hostis de volta ao lançador.",
    "Increases your chance to block with a Shield (not a Buckler) by 1%.": "Aumenta a sua chance de bloquear com um Escudo (não um Broquel) em 1%.",
    "Teaches your tamed spider the Web ability. Web renders an enemy unable to move.\nRequires: \nPet Level 22+": "Ensina à sua aranha domesticada a habilidade Teia. Teia deixa um inimigo incapaz de se mover.\nRequer: \nNível do Ajudante 22+",
    "Teaches your tamed spider the Web ability. Web renders an enemy unable to move.\nRequires: \nPet Level 30+": "Ensina à sua aranha domesticada a habilidade Teia. Teia deixa um inimigo incapaz de se mover.\nRequer: \nNível do Ajudante 30+",
    "Teaches your tamed spider the Web ability. Web renders an enemy unable to move.\nRequires: \nPet Level 37+": "Ensina à sua aranha domesticada a habilidade Teia. Teia deixa um inimigo incapaz de se mover.\nRequer: \nNível do Ajudante 37+",
    "Teaches your tamed tall strider the Healing Tongue ability. Healing Tongue heals friendly targets from a short range.\nRequires: \nPet Level 22+": "Ensina ao seu moa domesticado a habilidade Língua Curativa. Língua Curativa cura alvos aliados a curta distância.\nRequer: \nNível do Ajudante 22+",
    "Teaches your tamed tall strider the Healing Tongue ability. Healing Tongue heals friendly targets from a short range.\nRequires: \nPet Level 28+": "Ensina ao seu moa domesticado a habilidade Língua Curativa. Língua Curativa cura alvos aliados a curta distância.\nRequer: \nNível do Ajudante 28+",
    "Increases Holy spell and ability damage by 4 and the effect from Holy healing by 8.": "Aumenta o dano de feitiços e habilidades Sagrados em 4 e o efeito de curas Sagradas em 8.",
    "Increases Holy spell and ability damage by 6 and the effect from Holy healing by 12.": "Aumenta o dano de feitiços e habilidades Sagrados em 6 e o efeito de curas Sagradas em 12."
}

with open('C:/PROJETOS/ConsoleModeVanilla/tools/batches/input_batch_17.json', 'r', encoding='utf-8') as f:
    batch_input = json.load(f)

print(f"Batch input items: {len(batch_input)}")
print(f"Translations items: {len(translations)}")

missing = []
for item in batch_input:
    en = item['en']
    if en not in translations:
        missing.append(en)
    else:
        ok, msg = validate_pair(en, translations[en])
        if not ok:
            print(f"Validation error for: {en}\nPT: {translations[en]}\nMsg: {msg}")

if missing:
    print(f"Missing {len(missing)} items: {missing}")
else:
    print("All 50 items matched and validated!")
