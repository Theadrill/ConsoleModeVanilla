import json
import sys
import os

sys.path.append('tools')
import validate_spell_vars as validator

translations = {
    # 0 (ranked_idx=759, sample="Purge (Rank 1) [id=558]")
    "Teaches Purge.":
        "Ensina Expurgar.",

    # 1 (ranked_idx=760, sample="Exorcism (Rank 3) [id=559]")
    "Teaches Exorcism (Rank 3).":
        "Ensina Exorcismo (Grau 3).",

    # 2 (ranked_idx=761, sample="Water Walking (Rank 1) [id=562]")
    "Teaches Water Walking.":
        "Ensina Caminhar sobre a Água.",

    # 3 (ranked_idx=762, sample="Moonfire (Rank 6) [id=563]")
    "Teaches Moonfire (Rank 6).":
        "Ensina Fogo Lunar (Grau 6).",

    # 4 (ranked_idx=763, sample="Healing Wave (Rank 3) [id=565]")
    "Teaches Healing Wave (Rank 3).":
        "Ensina Onda de Cura (Grau 3).",

    # 5 (ranked_idx=764, sample="Lightning Bolt (Rank 3) [id=566]")
    "Teaches Lightning Bolt (Rank 3).":
        "Ensina Raio (Grau 3).",

    # 6 (ranked_idx=765, sample="Far Sight (Rank 1) [id=570]")
    "Teaches Far Sight.":
        "Ensina Visão Distante.",

    # 7 (ranked_idx=766, sample="Moonfire (Rank 3) [id=573]")
    "Teaches Moonfire (Rank 3).":
        "Ensina Fogo Lunar (Grau 3).",

    # 8 (ranked_idx=767, sample="Fade (Rank 1) [id=586]")
    "Fade out, discouraging enemies from attacking you for $d.":
        "Desvanece, desencorajando os inimigos de atacarem você por $d s.",

    # 9 (ranked_idx=768, sample="Conjure Food (Rank 1) [id=587]")
    "Conjures $s1 $lmuffin:muffins;, providing the mage and $ghis:her; allies with something to eat.\n\nConjured items disappear if logged out for more than 15 minutes.":
        "Conjura $s1 bolinhos, fornecendo ao mago e a seus aliados algo para comer.\n\nItens conjurados desaparecem se você permanecer desconectado por mais de 15 minutos.",

    # 10 (ranked_idx=769, sample="Conjure Food (Rank 2) [id=597]")
    "Conjures $s1 $lloaf:loaves; of bread, providing the mage and $ghis:her; allies with something to eat.\n\nConjured items disappear if logged out for more than 15 minutes.":
        "Conjura $s1 pães, fornecendo ao mago e a seus aliados algo para comer.\n\nItens conjurados desaparecem se você permanecer desconectado por mais de 15 minutos.",

    # 11 (ranked_idx=770, sample="Curse of Doom () [id=603]")
    "Curses the target with impending doom, causing $s1 Shadow damage after $d.  If the target dies from this damage, there is a chance that a Doomguard will be summoned.  Cannot be cast on players. Only one Curse per Warlock can be active on any one target.":
        "Amaldiçoa o alvo com uma perdição iminente, causando $s1 de dano de Sombra após $d s. Se o alvo morrer com este dano, há uma chance de evocar um Guarda Apocalíptico. Não pode ser lançado em jogadores. Apenas uma Maldição por Bruxo pode ficar ativa em um mesmo alvo.",

    # 12 (ranked_idx=771, sample="Dampen Magic () [id=604]")
    "Dampens magic used against the targeted party member, decreasing damage taken from spells by $8451s1% and healing spells by $8451s2%.  Lasts $8451d.":
        "Atenua a magia usada contra o membro do grupo selecionado, reduzindo o dano sofrido por feitiços em $s1% e a cura de feitiços em $s2%. Dura $d s.",

    # 13 (ranked_idx=772, sample="Mind Control (Rank 1) [id=605]")
    "Controls a humanoid mind up to level $s1, but increases the time between its attacks by $s3%.  Lasts up to $d.":
        "Controla a mente de um humanoide de até nível $s1, mas aumenta o intervalo entre os ataques dele em $s3%. Dura até $d s.",

    # 14 (ranked_idx=773, sample="Conjure Food (Rank 1) [id=608]")
    "Teaches Conjure Food (Rank 1).":
        "Ensina Conjurar Comida (Grau 1).",

    # 15 (ranked_idx=774, sample="Shadow Word: Pain (Rank 1) [id=610]")
    "Teaches Shadow Word: Pain (Rank 1).":
        "Ensina Palavra Sombria: Dor (Grau 1).",

    # 16 (ranked_idx=775, sample="Seal of Sacrifice (Rank 1) [id=611]")
    "Teaches Seal of Sacrifice (Rank 1).":
        "Ensina Selo de Sacrifício (Grau 1).",

    # 17 (ranked_idx=776, sample="Holy Smite (Rank 2) [id=612]")
    "Teaches Holy Smite (Rank 2).":
        "Ensina Punição Sagrada (Grau 2).",

    # 18 (ranked_idx=777, sample="Lesser Heal (Rank 2) [id=613]")
    "Teaches Lesser Heal (Rank 2).":
        "Ensina Cura Menor (Grau 2).",

    # 19 (ranked_idx=778, sample="Shadow Word: Fumble (Rank 1) [id=614]")
    "Teaches Shadow Word: Fumble (Rank 1).":
        "Ensina Palavra Sombria: Fumble (Grau 1).",

    # 20 (ranked_idx=779, sample="Dispel Magic (Rank 1) [id=615]")
    "Teaches Dispel Magic (Rank 1).":
        "Ensina Dissipar Magia (Grau 1).",

    # 21 (ranked_idx=780, sample="Shadow Word: Pain (Rank 2) [id=616]")
    "Teaches Shadow Word: Pain (Rank 2).":
        "Ensina Palavra Sombria: Dor (Grau 2).",

    # 22 (ranked_idx=781, sample="Prayer of Healing (Rank 1) [id=618]")
    "Teaches Prayer of Healing (Rank 1).":
        "Ensina Prece de Cura (Grau 1).",

    # 23 (ranked_idx=782, sample="Conjure Food (Rank 2) [id=619]")
    "Teaches Conjure Food (Rank 2).":
        "Ensina Conjurar Comida (Grau 2).",

    # 24 (ranked_idx=783, sample="Holy Smite (Rank 3) [id=620]")
    "Teaches Holy Smite (Rank 3).":
        "Ensina Punição Sagrada (Grau 3).",

    # 25 (ranked_idx=784, sample="Healing Totem (Rank 1) [id=621]")
    "Teaches Healing Totem (Rank 1).":
        "Ensina Totem de Cura (Grau 1).",

    # 26 (ranked_idx=785, sample="Lesser Heal (Rank 3) [id=622]")
    "Teaches Lesser Heal (Rank 3).":
        "Ensina Cura Menor (Grau 3).",

    # 27 (ranked_idx=786, sample="Inner Fire (Rank 3) [id=624]")
    "Teaches Inner Fire (Rank 2).":
        "Ensina Fogo Interior (Grau 2).",

    # 28 (ranked_idx=787, sample="Curse of Archimonde (Rank 1) [id=625]")
    "Teaches Curse of Archimonde.":
        "Ensina Maldição de Archimonde.",

    # 29 (ranked_idx=788, sample="Seal of Might (Rank 3) [id=626]")
    "Teaches Seal of Might (Rank 3).":
        "Ensina Selo do Poder (Grau 3).",

    # 30 (ranked_idx=789, sample="Mind Control (Rank 1) [id=627]")
    "Teaches Mind Control.":
        "Ensina Controle Mental.",

    # 31 (ranked_idx=790, sample="Healing Totem (Rank 3) [id=631]")
    "Teaches Healing Totem (Rank 3).":
        "Ensina Totem de Cura (Grau 3).",

    # 32 (ranked_idx=791, sample="Healing Totem (Rank 4) [id=632]")
    "Teaches Healing Totem (Rank 4).":
        "Ensina Totem de Cura (Grau 4).",

    # 33 (ranked_idx=792, sample="Lay on Hands (Rank 1) [id=633]")
    "Heals a friendly target for an amount equal to the Paladin's maximum health.  Drains all of the Paladin's remaining mana when used.":
        "Cura um alvo aliado em um valor equivalente ao máximo de vida do Paladino. Drena toda a mana restante do Paladino ao ser usado.",

    # 34 (ranked_idx=793, sample="Blessing of Reckoning (Rank 1) [id=648]")
    "Places a Blessing on a friendly target that lasts $d.  Every time the Blessed character strikes an enemy, the Blessed character gains $1136s1 health.  Players may only have one Blessing on them per Paladin at any one time.":
        "Concede uma Bênção a um alvo aliado que dura $d s. Cada vez que o personagem Abençoado atingir um inimigo, o personagem Abençoado recupera $s1 de vida. Jogadores só podem ter uma Bênção ativa por Paladino por vez.",

    # 35 (ranked_idx=794, sample="Seal of Might (Rank 1) [id=653]")
    "Teaches Seal of Might (Rank 1).":
        "Ensina Selo do Poder (Grau 1).",

    # 36 (ranked_idx=795, sample="Fear (Rank 2) [id=654]")
    "Teaches Fear (Rank 2).":
        "Ensina Medo (Grau 2).",

    # 37 (ranked_idx=796, sample="Holy Light (Rank 2) [id=656]")
    "Teaches Holy Light (Rank 2).":
        "Ensina Luz Sagrada (Grau 2).",

    # 38 (ranked_idx=797, sample="Create Greater Healthstone (Rank 4) [id=657]")
    "Teaches Create Greater Healthstone.":
        "Ensina Criar Pedra de Vida Maior.",

    # 39 (ranked_idx=798, sample="Invisibility Totem (Rank 1) [id=658]")
    "Teaches Invisibility Totem.":
        "Ensina Totem de Invisibilidade.",

    # 40 (ranked_idx=799, sample="Divine Shield (Rank 1) [id=659]")
    "Teaches Divine Shield (Rank 1).":
        "Ensina Escudo Divino (Grau 1).",

    # 41 (ranked_idx=800, sample="Seal of Might (Rank 2) [id=662]")
    "Teaches Seal of Might (Rank 2).":
        "Ensina Selo do Poder (Grau 2).",

    # 42 (ranked_idx=801, sample="Fear (Rank 3) [id=663]")
    "Teaches Fear (Rank 3).":
        "Ensina Medo (Grau 3).",

    # 43 (ranked_idx=802, sample="Holy Light (Rank 3) [id=664]")
    "Teaches Holy Light (Rank 3).":
        "Ensina Luz Sagrada (Grau 3).",

    # 44 (ranked_idx=803, sample="Holy Strike (Rank 2) [id=678]")
    "Strike your target for $s1 Holy damage, restoring $51755s1 health and $51875s1 mana to you and 4 allies within $51875a1 yards. The healing effect is reduced by half on yourself.":
        "Golpeia o seu alvo causando $s1 de dano Sagrado, restaurando $s2 de vida e $s3 de mana a você e a 4 aliados a até $a1 metros. O efeito de cura é reduzido pela metade em você mesmo.",

    # 45 (ranked_idx=804, sample="Holy Strike (Rank 1) [id=679]")
    "Strike your target for $s1 Holy damage, restoring $51301s1 health and $51324s1 mana to you and 4 allies within $51324a1 yards. The healing effect is reduced by half on yourself.":
        "Golpeia o seu alvo causando $s1 de dano Sagrado, restaurando $s2 de vida e $s3 de mana a você e a 4 aliados a até $a1 metros. O efeito de cura é reduzido pela metade em você mesmo.",

    # 46 (ranked_idx=805, sample="Holy Strike (Rank 4) [id=680]")
    "Strike your target for $s1 Holy damage, restoring $51757s1 health and $51877s1 mana to you and 4 allies within $51877a1 yards. The healing effect is reduced by half on yourself.":
        "Golpeia o seu alvo causando $s1 de dano Sagrado, restaurando $s2 de vida e $s3 de mana a você e a 4 aliados a até $a1 metros. O efeito de cura é reduzido pela metade em você mesmo.",

    # 47 (ranked_idx=806, sample="Summon Imp (Summon) [id=688]")
    "Summons an Imp under the command of the Warlock.":
        "Evoca um Diabrete sob o comando do Bruxo.",

    # 48 (ranked_idx=807, sample="Summon Felhunter (Summon) [id=691]")
    "Summons a Felhunter under the command of the Warlock.":
        "Evoca um Caçador Vil sob o comando do Bruxo.",

    # 49 (ranked_idx=808, sample="Summon Voidwalker (Summon) [id=697]")
    "Summons a Voidwalker under the command of the Warlock.":
        "Evoca um Emissário do Caos sob o comando do Bruxo."
}

def main():
    input_path = 'tools/batches/input_batch_12.json'
    output_path = 'tools/batches/output_batch_12.json'

    with open(input_path, 'r', encoding='utf-8') as f:
        batch = json.load(f)

    print(f"Total templates in input batch: {len(batch)}")
    print(f"Total translations defined: {len(translations)}")

    errors = 0
    missing = 0
    for idx, item in enumerate(batch):
        en = item['en']
        if en not in translations:
            print(f"[MISSING] Item {idx+1}: {en[:60]}...")
            missing += 1
            continue

        pt = translations[en]
        ok, msg = validator.validate_pair(en, pt)
        if not ok:
            print(f"[ERROR] Item {idx+1} (idx={item.get('ranked_idx')}): {msg}")
            print(f"   EN: {en}")
            print(f"   PT: {pt}")
            errors += 1
        else:
            print(f"[OK] Item {idx+1} ({item.get('sample')})")

    if missing > 0 or errors > 0:
        print(f"\nFAILED: {missing} missing, {errors} errors.")
        sys.exit(1)

    print("\nAll 50 templates passed validation perfectly!")

    # Write output_batch_12.json in order of input_batch_12.json
    output_data = {}
    for item in batch:
        en = item['en']
        output_data[en] = translations[en]

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)

    print(f"Successfully saved {len(output_data)} translations to {output_path}")

if __name__ == '__main__':
    main()
