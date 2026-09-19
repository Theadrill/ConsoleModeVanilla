import json
import sys
import os

sys.path.append('tools')
import validate_spell_vars as validator

translations = {
    # 0 (ranked_idx=809)
    "Begins a ritual that summons the targeted group member.  Requires the caster and 2 additional party members to complete the ritual.  In order to participate, all players must be out of combat and right-click the portal and not move until the ritual is complete.":
        "Inicia um ritual que evoca o membro do grupo selecionado. Requer o lançador e 2 membros adicionais do grupo para completar o ritual. Para participar, todos os jogadores devem estar fora de combate, clicar com o botão direito no portal e não se mover até que o ritual seja concluído.",

    # 1 (ranked_idx=810)
    "Reduces the attack speed of the target by $s1% for $d sec.  Only one Curse per Warlock can be active on any one target.":
        "Reduz a velocidade de ataque do alvo em $s1% por $d s. Apenas uma Maldição por Bruxo pode ficar ativa em um mesmo alvo.",

    # 2 (ranked_idx=811)
    "Blasts all enemies in a 10 yard radius with $s1 flame damage.":
        "Atinge todos os inimigos em um raio de 10 metros, causando $s1 de dano de Fogo.",

    # 3 (ranked_idx=812)
    "Summons a Succubus under the command of the Warlock.":
        "Evoca uma Súcubo sob o comando do Bruxo.",

    # 4 (ranked_idx=813)
    "Teaches Drain Life (Rank 1).":
        "Ensina Dreno de Vida (Grau 1).",

    # 5 (ranked_idx=814)
    "Teaches you the spell Immolate (Rank 1).":
        "Ensina a você o feitiço Imolação (Grau 1).",

    # 6 (ranked_idx=815)
    "Teaches Create Soulstone.":
        "Ensina Criar Pedra da Alma.",

    # 7 (ranked_idx=816)
    "Teaches Shadow Bolt (Rank 2).":
        "Ensina Seta Sombria (Grau 2).",

    # 8 (ranked_idx=817)
    "Creates a holy Lightwell near the priest.  Members of your raid or party can click the Lightwell to restore $7001o1 health over $7001d. Lightwell lasts for $d or 5 charges.":
        "Cria um Poço de Luz sagrado perto do sacerdote. Membros do seu grupo ou raide podem clicar no Poço de Luz para restaurar $s1 de vida ao longo de $d s. O Poço de Luz dura $d s ou 5 cargas.",

    # 9 (ranked_idx=818)
    "Teaches Drain Life (Rank 2).":
        "Ensina Dreno de Vida (Grau 2).",

    # 10 (ranked_idx=819)
    "Teaches Cripple.":
        "Ensina Aleijar.",

    # 11 (ranked_idx=820)
    "Teaches Curse of Weakness (Rank 1).":
        "Ensina Maldição da Fraqueza (Grau 1).",

    # 12 (ranked_idx=821)
    "Teaches Health Funnel (Rank 1).":
        "Ensina Canalizar Vida (Grau 1).",

    # 13 (ranked_idx=822)
    "Teaches Shadow Bolt (Rank 3).":
        "Ensina Seta Sombria (Grau 3).",

    # 14 (ranked_idx=823)
    "Teaches Immolate (Rank 2).":
        "Ensina Imolação (Grau 2).",

    # 15 (ranked_idx=824)
    "Teaches Divine Protection (Rank 2).":
        "Ensina Proteção Divina (Grau 2).",

    # 16 (ranked_idx=825)
    "Teaches Drain Life (Rank 3).":
        "Ensina Dreno de Vida (Grau 3).",

    # 17 (ranked_idx=826)
    "Conjures a mana agate that can be used to instantly restore $5405s1 mana.\n\nConjured items disappear if logged out for more than 15 minutes.":
        "Conjura uma ágata de mana que pode ser usada para restaurar instantaneamente $s1 de mana.\n\nItens conjurados desaparecem se você permanecer desconectado por mais de 15 minutos.",

    # 18 (ranked_idx=827)
    "Shapeshift into cat form, increasing melee attack power by $3025s1 plus Agility.  Also protects the caster from Polymorph effects and allows the use of various cat abilities.\n\nThe act of shapeshifting frees the caster of Polymorph and Movement Impairing effects.":
        "Assume a forma de felino, aumentando o poder de ataque corpo a corpo em $s1 mais a Agilidade. Também protege o lançador contra efeitos de Polimorfia e permite o uso de várias habilidades de felino.\n\nO ato de mudar de forma liberta o lançador de efeitos de Polimorfia e de redução de movimento.",

    # 19 (ranked_idx=828)
    "Attempts to disengage from the target, reducing threat.  Character exits combat mode.":
        "Tenta se desvencilhar do alvo, reduzindo a ameaça. O personagem sai do modo de combate.",

    # 20 (ranked_idx=829)
    "Transforms the druid into a travel form, increasing movement speed by $5419s1%.  Also protects the caster from Polymorph effects.  Only useable outdoors.\n\nThe act of shapeshifting frees the caster of Polymorph and Movement Impairing effects.":
        "Transforma o druida em uma forma de viagem, aumentando a velocidade de movimento em $s1%. Também protege o lançador contra efeitos de Polimorfia. Só pode ser usado ao ar livre.\n\nO ato de mudar de forma liberta o lançador de efeitos de Polimorfia e de redução de movimento.",

    # 21 (ranked_idx=830)
    "Teaches Faerie Fire (Rank 1).":
        "Ensina Fogo das Fadas (Grau 1).",

    # 22 (ranked_idx=831)
    "Teaches Thorns (Rank 1).":
        "Ensina Espinhos (Grau 1).",

    # 23 (ranked_idx=832)
    "Teaches Entangling Roots (Rank 1).":
        "Ensina Raízes Enredantes (Grau 1).",

    # 24 (ranked_idx=833)
    "Teaches Tranquility (Rank 1).":
        "Ensina Tranquilidade (Grau 1).",

    # 25 (ranked_idx=834)
    "Teaches Faerie Fire (Rank 2).":
        "Ensina Fogo das Fadas (Grau 2).",

    # 26 (ranked_idx=835)
    "Teaches Thorns (Rank 2).":
        "Ensina Espinhos (Grau 2).",

    # 27 (ranked_idx=836)
    "Restores 6 health per minute.":
        "Restaura 6 pontos de vida por minuto.",

    # 28 (ranked_idx=837)
    "Teaches Frostbolt (Rank 3).":
        "Ensina Seta de Gelo (Grau 3).",

    # 29 (ranked_idx=838)
    "Teaches Ice Armor (Rank 2).":
        "Ensina Armadura de Gelo (Grau 2).",

    # 30 (ranked_idx=839)
    "Teaches Flamestrike (Rank 1).":
        "Ensina Golpe Flamejante (Grau 1).",

    # 31 (ranked_idx=840)
    "Pummel (Learn).":
        "Esmurrar (Aprender).",

    # 32 (ranked_idx=841)
    "Transforms the enemy into a helpless sheep that cannot cast spells or attack and movement speed is reduced by $s2% for up to $d.":
        "Transforma o inimigo em uma ovelha indefesa que não pode lançar feitiços nem atacar, e cuja velocidade de movimento é reduzida em $s2% por até $d s.",

    # 33 (ranked_idx=842)
    "Teaches Polymorph: Chicken.":
        "Ensina Polimorfia: Galinha.",

    # 34 (ranked_idx=843)
    "Teaches Renew (Rank 6).":
        "Ensina Renovar (Grau 6).",

    # 35 (ranked_idx=844)
    "Teaches Drain Mana (Rank 2).":
        "Ensina Dreno de Mana (Grau 2).",

    # 36 (ranked_idx=845)
    "Teaches Seal of Righteousness (Rank 1).":
        "Ensina Selo da Retidão (Grau 1).",

    # 37 (ranked_idx=846)
    "Teaches Frost Nova (Rank 2).":
        "Ensina Nova de Gelo (Grau 2).",

    # 38 (ranked_idx=847)
    "Teaches Renew (Rank 4).":
        "Ensina Renovar (Grau 4).",

    # 39 (ranked_idx=848)
    "Reduces the damage taken from melee attacks, ranged attacks and spells by $s1% for $d.":
        "Reduz o dano sofrido de ataques corpo a corpo, ataques de longo alcance e feitiços em $s1% por $d s.",

    # 40 (ranked_idx=849)
    "Teaches Flamestrike (Rank 2).":
        "Ensina Golpe Flamejante (Grau 2).",

    # 41 (ranked_idx=850)
    "Teaches Agitating Totem (Rank 3).":
        "Ensina Totem Agitador (Grau 3).",

    # 42 (ranked_idx=851)
    "Teaches Moonfire (Rank 5).":
        "Ensina Fogo Lunar (Grau 5).",

    # 43 (ranked_idx=852)
    "Teaches Holy Smite (Rank 6).":
        "Ensina Punição Sagrada (Grau 6).",

    # 44 (ranked_idx=853)
    "Teaches Renew (Rank 5).":
        "Ensina Renovar (Grau 5).",

    # 45 (ranked_idx=854)
    "Teaches Sentry Totem.":
        "Ensina Totem Sentinela.",

    # 46 (ranked_idx=855)
    "Teaches Blink (Rank 2).":
        "Ensina Lampejo (Grau 2).",

    # 47 (ranked_idx=856)
    "The caster is surrounded by $n globes of unstable lightning for $d. When a spell, melee or ranged attack hits the caster, the attacker will be struck for $26366s1 Nature damage, spending one globe. This effect can only occur once every 3 sec. Only one elemental shield can be active on the Shaman at any one time.":
        "O lançador é envolvido por $n esferas de relâmpagos instáveis por $d s. Quando um feitiço, ataque corpo a corpo ou de longo alcance atinge o lançador, o atacante é atingido, sofrendo $s1 de dano de Natureza e consumindo uma esfera. Este efeito só pode ocorrer uma vez a cada 3 s. Apenas um escudo elemental pode ficar ativo no Xamã por vez.",

    # 48 (ranked_idx=857)
    "Teaches Lightning Shield (Rank 3).":
        "Ensina Escudo de Raios (Grau 3).",

    # 49 (ranked_idx=858)
    "Teaches Healing Wave (Rank 4).":
        "Ensina Onda de Cura (Grau 4)."
}

# Validation
with open('tools/batches/input_batch_13.json', 'r', encoding='utf-8') as f:
    inputs = json.load(f)

assert len(inputs) == 50, f"Expected 50 inputs, got {len(inputs)}"
assert len(translations) == 50, f"Expected 50 translations, got {len(translations)}"

all_ok = True
for i, item in enumerate(inputs):
    en = item['en']
    if en not in translations:
        print(f"MISSING translation for [{i}]: {en}")
        all_ok = False
        continue
    pt = translations[en]
    ok, msg = validator.validate_pair(en, pt)
    if not ok:
        print(f"FAILED validation for [{i}] ({item.get('sample')}):\n  EN: {en}\n  PT: {pt}\n  Reason: {msg}")
        all_ok = False
    else:
        print(f"[{i:02d}] OK | {item.get('sample')}")

if all_ok:
    output_path = 'tools/batches/output_batch_13.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(translations, f, ensure_ascii=False, indent=2)
    print(f"\nSUCCESS! Wrote 50 validated translations to {output_path}")
else:
    print("\nVALIDATION FAILED. Please fix issues.")
    sys.exit(1)
