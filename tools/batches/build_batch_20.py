# -*- coding: utf-8 -*-
import json
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from validate_spell_vars import validate_pair, count_en_vars, count_pt_vars

translations = {
    # 1
    "Teaches Frost Armor (Rank 3).":
        "Ensina Armadura de Gelo (Grau 3).",

    # 2
    "Teaches Frost Nova (Rank 3).":
        "Ensina Nova de Gelo (Grau 3).",

    # 3
    "Teaches Healing Touch (Rank 1).":
        "Ensina Toque de Cura (Grau 1).",

    # 4
    "Finishing move that causes damage per combo point, increased by Attack Power:\n   1 point  : 14-22 damage\n   2 points: 25-33 damage\n   3 points: 36-44 damage\n   4 points: 47-55 damage\n   5 points: 58-66 damage":
        "Golpe finalizador que causa dano por ponto de combo, aumentado pelo Poder de Ataque:\n   1 ponto  : 14-22 de dano\n   2 pontos: 25-33 de dano\n   3 pontos: 36-44 de dano\n   4 pontos: 47-55 de dano\n   5 pontos: 58-66 de dano",

    # 5
    "Finishing move that causes damage per combo point, increased by Attack Power:\n   1 point  : 25-39 damage\n   2 points: 44-58 damage\n   3 points: 63-77 damage\n   4 points: 82-96 damage\n   5 points: 101-115 damage":
        "Golpe finalizador que causa dano por ponto de combo, aumentado pelo Poder de Ataque:\n   1 ponto  : 25-39 de dano\n   2 pontos: 44-58 de dano\n   3 pontos: 63-77 de dano\n   4 pontos: 82-96 de dano\n   5 pontos: 101-115 de dano",

    # 6
    "Finishing move that causes damage per combo point, increased by Attack Power:\n   1 point  : 41-61 damage\n   2 points: 72-92 damage\n   3 points: 103-123 damage\n   4 points: 134-154 damage\n   5 points: 165-185 damage":
        "Golpe finalizador que causa dano por ponto de combo, aumentado pelo Poder de Ataque:\n   1 ponto  : 41-61 de dano\n   2 pontos: 72-92 de dano\n   3 pontos: 103-123 de dano\n   4 pontos: 134-154 de dano\n   5 pontos: 165-185 de dano",

    # 7
    "Ravage the target, causing $s2% damage plus 147 to the target.  Must be prowling and behind the target.  Awards $s3 combo $lpoint:points;.":
        "Devasta o alvo, causando $s2% de dano mais 147 ao alvo. Requer estar espreitando e atrás do alvo. Concede $s3 pontos de combo.",

    # 8
    "Ravage the target, causing $s2% damage plus 217 to the target.  Must be prowling and behind the target.  Awards $s3 combo $lpoint:points;.":
        "Devasta o alvo, causando $s2% de dano mais 217 ao alvo. Requer estar espreitando e atrás do alvo. Concede $s3 pontos de combo.",

    # 9
    "Shred the target, causing $s2% damage plus 72 to the target.  Must be behind the target.  Awards $s3 combo $lpoint:points;.":
        "Despedaça o alvo, causando $s2% de dano mais 72 ao alvo. Requer estar atrás do alvo. Concede $s3 pontos de combo.",

    # 10
    "Increases the Physical damage dealt by the caster by $s2 and speeds its movement by $s1% for $d. Also curses an enemy on the first successful hit, reducing the Physical damage it deals by $6922s2, reducing the magical damage it deals by $6922s3, and increasing the Physical damage it takes by $6922s1 for $6922d.":
        "Aumenta o dano Físico causado pelo lançador em $s2 e a sua velocidade de movimento em $s1% por $d s. Também amaldiçoa um inimigo no primeiro golpe bem-sucedido, reduzindo o dano Físico que ele causa em $s2, reduzindo o dano mágico que ele causa em $s3 e aumentando o dano Físico que ele recebe em $s1 por $d s.",

    # 11
    "Inflicts normal damage plus $s2 to an enemy when attacking from stealth, stunning it $d. Awards $s3 combo $lpoint:points;.":
        "Causa o dano normal mais $s2 a um inimigo ao atacar em furtividade, atordoando-o por $d s. Concede $s3 pontos de combo.",

    # 12
    "Launches a bolt of ice at an enemy, inflicting $s1 Frost damage.":
        "Dispara uma seta de gelo contra um inimigo, causando $s1 de dano de Gelo.",

    # 13
    "Surrounds an ally with a shield of crackling electricity that lasts $d. and inflicts $s1 Nature damage to melee attackers.":
        "Envolve um aliado com um escudo crepitante de eletricidade que dura $d s e causa $s1 de dano de Natureza a atacantes corpo a corpo.",

    # 14
    "Feed your pet the selected item.  Feeding your pet increases happiness.  Using food close to the pet's level will have a better result.":
        "Alimenta seu ajudante com o item selecionado. Alimentar seu ajudante aumenta a felicidade. Usar comida próxima ao nível do ajudante produzirá um resultado melhor.",

    # 15
    "Attempts to disengage from the target, reducing threat.  Cancels combat.":
        "Tenta se desvencilhar do alvo, reduzindo a ameaça. Cancela o combate.",

    # 16
    "Fires an explosive shot, causing $s1 additional damage to the target and exploding for $s2 damage to nearby enemies.":
        "Dispara um tiro explosivo, causando $s1 de dano adicional ao alvo e explodindo para causar $s2 de dano aos inimigos próximos.",

    # 17
    "Increases the next attack by $s1 damage.":
        "Aumenta o dano do próximo ataque em $s1.",

    # 18
    "Intimidates an enemy, causing it to flee in terror for $d. Only 1 target can be feared at a time.":
        "Intimida um inimigo, fazendo-o fugir aterrorizado por $d s. Apenas 1 alvo pode ser amedrontado por vez.",

    # 19
    "Charge an enemy, increasing speed and causing an additional $s2 damage on the first attack.":
        "Investe contra um inimigo, aumentando a velocidade e causando $s2 de dano adicional no primeiro ataque.",

    # 20
    "Attempts to finish off a wounded enemy, inflicting normal damage plus $s1. Execute can only be used on enemies that have 20% or less health.":
        "Tenta finalizar um inimigo ferido, causando o dano normal mais $s1. Executar só pode ser usado em inimigos que tenham 20% ou menos de vida.",

    # 21
    "Heals a target for an amount equal to the caster's maximum health.":
        "Cura um alvo em uma quantidade equivalente à vida máxima do lançador.",

    # 22
    "Assumes a balanced combat stance that generates rage when the warrior is hit, as well as when the warrior strikes an opponent. Lasts $d.":
        "Assume uma postura de combate equilibrada que gera raiva quando o guerreiro é atingido e quando ele golpeia um oponente. Dura $d s.",

    # 23
    "Allows the Imbiber to breathe water for $d.":
        "Permite ao usuário respirar debaixo d'água por $d s.",

    # 24
    "Restores 48 health per minute.":
        "Restaura 48 de vida por minuto.",

    # 25
    "Burns the enemy for $s1 damage and then an additional $o1 damage over $d.":
        "Queima o inimigo, causando $s1 de dano e mais $o1 de dano adicional ao longo de $d s.",

    # 26
    "Drains $o1 health over $d. from an enemy and its nearest ally, healing the caster for up to twice the amount of health stolen.":
        "Drena $o1 de vida ao longo de $d s de um inimigo e de seu aliado mais próximo, curando o lançador em até o dobro da quantidade de vida roubada.",

    # 27
    "Teaches Frostbolt (Rank 4).":
        "Ensina Seta de Gelo (Grau 4).",

    # 28
    "Teaches Seal of Wisdom (Rank 1).":
        "Ensina Selo da Sabedoria (Grau 1).",

    # 29
    "Heals the Paladin and nearby group members for $s1 every tick.":
        "Cura o Paladino e membros do grupo próximos em $s1 a cada pulso.",

    # 30
    "Assumes an aggressive stance that generates rage when the warrior strikes an opponent. Lasts $d.":
        "Assume uma postura agressiva que gera raiva quando o guerreiro golpeia um oponente. Dura $d s.",

    # 31
    "Bashes the target with your shield for $s2 damage and interrupting the spell being cast for $d.":
        "Golpeia o alvo com o seu escudo, causando $s2 de dano e interrompendo o feitiço que estiver sendo lançado por $d s.",

    # 32
    "Taunts the target to attack you, causing a medium amount of threat.  More effective than Taunt (Rank 1).":
        "Provoca o alvo para atacar você, gerando uma quantidade moderada de ameaça. Mais eficaz que Provocar (Grau 1).",

    # 33
    "Taunts the target to attack you, causing a high amount of threat.  More effective than Taunt (Rank 2).":
        "Provoca o alvo para atacar você, gerando uma grande quantidade de ameaça. Mais eficaz que Provocar (Grau 2).",

    # 34
    "When struck in combat has a $h% chance of inflicting $16783s1 Shadow damage to the attacker.":
        "Quando atingido em combate, tem $h% de chance de causar $s1 de dano de Sombra ao atacante.",

    # 35
    "When struck in combat has a $h% chance of inflicting $16784s1 Shadow damage to the attacker.":
        "Quando atingido em combate, tem $h% de chance de causar $s1 de dano de Sombra ao atacante.",

    # 36
    "Teaches Drain Life (Rank 4).":
        "Ensina Drenar Vida (Grau 4).",

    # 37
    "Taunts the creature, dealing $s2 Shadow damage and increasing the chance that it will attack the Voidwalker.  More effective than Torment (Rank 1).":
        "Provoca a criatura, causando $s2 de dano de Sombra e aumentando a chance de ela atacar o Emissário do Caos. Mais eficaz que Tormento (Grau 1).",

    # 38
    "Taunts the creature, dealing $s2 Shadow damage and increasing the chance that it will attack the Voidwalker.  More effective than Torment (Rank 2).":
        "Provoca a criatura, causando $s2 de dano de Sombra e aumentando a chance de ela atacar o Emissário do Caos. Mais eficaz que Tormento (Grau 2).",

    # 39
    "Taunts the creature, dealing $s2 Shadow damage and increasing the chance that it will attack the Voidwalker.  More effective than Torment (Rank 3).":
        "Provoca a criatura, causando $s2 de dano de Sombra e aumentando a chance de ela atacar o Emissário do Caos. Mais eficaz que Tormento (Grau 3).",

    # 40
    "Target is cured of poisons up to level 25.":
        "Cura o alvo de venenos de até nível 25.",

    # 41
    "Target is cured of poisons up to level 35.":
        "Cura o alvo de venenos de até nível 35.",

    # 42
    "Puts the caster in stealth mode, but slows its movement to $s2% of normal. Lasts until cancelled.":
        "Coloca o lançador em modo de furtividade, mas reduz sua velocidade de movimento para $s2% do normal. Dura até ser cancelado.",

    # 43
    "Conjures $M1 $lloaf:loaves; of bread, providing the mage and his allies with something to eat.":
        "Conjura $s1 pães, fornecendo ao mago e a seus aliados algo para comer.",

    # 44
    "Imbue the Shaman's weapon, increasing melee attack power by $10400s1 and all threat caused by $10400s2% when using that weapon.  Lasts for 1 hour.":
        "Encanta a arma do Xamã, aumentando o poder de ataque corpo a corpo em $s1 e toda a ameaça gerada em $s2% ao usar esta arma. Dura 1 hora.",

    # 45
    "Imbue the Shaman's weapon, increasing melee attack power by $15567s1 and all threat caused by $15567s2% when using that weapon.  Lasts for 1 hour.":
        "Encanta a arma do Xamã, aumentando o poder de ataque corpo a corpo em $s1 e toda a ameaça gerada em $s2% ao usar esta arma. Dura 1 hora.",

    # 46
    "Imbue the Shaman's weapon, increasing melee attack power by $15568s1 and all threat caused by $15568s2% when using that weapon.  Lasts for 1 hour.":
        "Encanta a arma do Xamã, aumentando o poder de ataque corpo a corpo em $s1 e toda a ameaça gerada em $s2% ao usar esta arma. Dura 1 hora.",

    # 47
    "Imbue the Shaman's weapon with fire.  Each hit causes $/77;8026m1 to $/25;8026M1 additional Fire damage, based on the speed of the weapon.  Slower weapons cause more fire damage per swing.  Lasts for 1 hour.":
        "Encanta a arma do Xamã com fogo. Cada golpe causa de $s1 a $s2 de dano de Fogo adicional, com base na velocidade da arma. Armas mais lentas causam mais dano de fogo por golpe. Dura 1 hora.",

    # 48
    "Imbue the Shaman's weapon with fire.  Each hit causes $/77;8028m1 to $/25;8028M1 additional Fire damage, based on the speed of the weapon.  Slower weapons cause more fire damage per swing.  Lasts for 1 hour.":
        "Encanta a arma do Xamã com fogo. Cada golpe causa de $s1 a $s2 de dano de Fogo adicional, com base na velocidade da arma. Armas mais lentas causam mais dano de fogo por golpe. Dura 1 hora.",

    # 49
    "Imbue the Shaman's weapon with fire.  Each hit causes $/77;8029m1 to $/25;8029M1 additional Fire damage, based on the speed of the weapon.  Slower weapons cause more fire damage per swing.  Lasts for 1 hour.":
        "Encanta a arma do Xamã com fogo. Cada golpe causa de $s1 a $s2 de dano de Fogo adicional, com base na velocidade da arma. Armas mais lentas causam mais dano de fogo por golpe. Dura 1 hora.",

    # 50
    "Imbue the Shaman's weapon with frost.  Each hit has a chance of causing $8034s2 additional Frost damage and slowing the target's movement speed by $8034s1% for $8034d.  Lasts for 1 hour.":
        "Encanta a arma do Xamã com gelo. Cada golpe tem uma chance de causar $s2 de dano de Gelo adicional e reduzir a velocidade de movimento do alvo em $s1% por $d s. Dura 1 hora."
}

# Verify against input_batch_20.json
with open("tools/batches/input_batch_20.json", "r", encoding="utf-8") as f:
    input_list = json.load(f)

errors = []
print(f"Total entries in input: {len(input_list)}")
print(f"Total entries in translations: {len(translations)}")

for idx, item in enumerate(input_list):
    en = item["en"]
    if en not in translations:
        errors.append(f"Missing translation for item {idx+1}: {en[:40]}...")
        continue
    pt = translations[en]
    ok, msg = validate_pair(en, pt)
    if not ok:
        errors.append(f"Validation failed for item {idx+1}:\n  EN: {en}\n  PT: {pt}\n  Error: {msg}")

if errors:
    print(f"FAILED with {len(errors)} errors:")
    for err in errors:
        print(err)
    sys.exit(1)
else:
    print("ALL 50 TRANSLATIONS VALIDATED PERFECTLY!")

# Save to output_batch_20.json
out_path = "tools/batches/output_batch_20.json"
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(translations, f, ensure_ascii=False, indent=2)

print(f"Saved to {out_path} successfully!")
