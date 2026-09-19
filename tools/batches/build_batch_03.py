#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera e valida o lote 03 de retraduções oficiais Blizzard pt-BR."""
import json
import pathlib
import sys

# Caminho do projeto
ADDON_DIR = pathlib.Path(r"C:\PROJETOS\ConsoleModeVanilla")
sys.path.insert(0, str(ADDON_DIR / "tools"))
from validate_spell_vars import validate_pair

INPUT_FILE = ADDON_DIR / "tools" / "batches" / "input_batch_03.json"
OUTPUT_FILE = ADDON_DIR / "tools" / "batches" / "output_batch_03.json"

translations = {
    # 303
    "Places the Hunter's Mark on the target, increasing the Ranged Attack Power of all attackers against that target by $s2.  In addition, the target of this ability can always be seen by the hunter whether it stealths or turns invisible.  The target also appears on the mini-map.  Lasts for $d.":
        "Coloca a Marca do Caçador no alvo, aumentando o poder de ataque de longo alcance de todos os atacantes contra esse alvo em $s2. Além disso, o alvo desta habilidade sempre pode ser visto pelo caçador, mesmo que use furtividade ou fique invisível. O alvo também aparece no minimapa. Dura $d s.",

    # 304
    "Swiftly attack the enemy for $s2% of weapon damage plus an additional $s1 damage.":
        "Ataca rapidamente o inimigo, causando $s2% do dano de arma mais $s1 de dano adicional.",

    # 305
    "Continuously fires a volley of ammo at the target area, causing $s1 Arcane damage to enemy targets within $a1 yards every second for $d.":
        "Dispara continuamente uma saraivada de projéteis na área-alvo, causando $s1 de dano Arcano a alvos inimigos a até $a1 metros a cada segundo por $d s.",

    # 306
    "Instantly fires your weapon, causing $s1 additional damage.":
        "Dispara instantaneamente a sua arma, causando $s1 de dano adicional.",

    # 307
    "Maims the enemy, causing $s1 damage and slowing the enemy's movement by $s2% for $d.":
        "Mutila o inimigo, causando $s1 de dano e reduzindo a velocidade de movimento dele em $s2% por $d s.",

    # 308
    "A quick kick that injures a single foe for $s1 damage.  It also interrupts spellcasting and prevents any spell in that school from being cast for $d.":
        "Um chute rápido que fere um único inimigo em $s1 de dano. Também interrompe o lançamento de feitiços e impede que qualquer feitiço daquela escola seja lançado por $d s.",

    # 309
    "Allows the rogue to sneak around, but reduces your speed by $s3%.  Lasts until cancelled.":
        "Permite que o ladino se mova sorrateiramente, mas reduz a sua velocidade em $s3%. Dura até ser cancelado.",

    # 310
    "Rake the target for $s1 damage and an additional $o2 damage over $d. Damage is increased by your Attack Power. Awards $s3 combo $lpoint:points;.":
        "Estraçalha o alvo, causando $s1 de dano e mais $s2 de dano adicional ao longo de $d s. O dano é aumentado pelo seu Poder de Ataque. Concede $s3 pontos de combo.",

    # 311
    "Fire a long range shot at the enemy, causing $s1 additional damage.":
        "Dispara um tiro de longo alcance contra o inimigo, causando $s1 de dano adicional.",

    # 312
    "Inflicts $s2% of weapon damage and reduces the enemy target's movement speed by $s1% for $d.":
        "Causa $s2% do dano de arma e reduz a velocidade de movimento do alvo inimigo em $s1% por $d s.",

    # 313
    "Stings the target, draining $o1 mana over $d.  Only one Sting per Hunter can be active on any one target.":
        "Pica o alvo, drenando $s1 de mana ao longo de $d s. Apenas uma Picada por Caçador pode ficar ativa em um mesmo alvo.",

    # 314
    "Inflicts normal damage plus $s1 to an enemy, stunning it for $d.":
        "Causa o dano normal mais $s1 a um inimigo, atordoando-o por $d s.",

    # 315
    "Increases Holy spell and ability damage by 3 and the effect from Holy healing by 6.":
        "Aumenta o dano causado por feitiços e habilidades Sagradas em 3 e o efeito de curas Sagradas em 6.",

    # 316
    "Transfers $*5;s1 Mana from the target to the caster over $d.":
        "Transfere $s1 de Mana do alvo para o lançador ao longo de $d s.",

    # 317
    "Silences an enemy, preventing it from casting spells for $d.":
        "Silencia um inimigo, impedindo-o de lançar feitiços por $d s.",

    # 318
    "Causes the enemy target to run in horror for $d and causes $s1 Shadow damage.  The caster gains 100% of the damage caused in health.":
        "Faz o alvo inimigo fugir aterrorizado por $d s e causa $s1 de dano de Sombra. O lançador recupera uma quantidade de vida igual a 100% do dano causado.",

    # 319
    "Reduces an enemy's armor by $s1 for $d. While affected, the target cannot use stealth or invisibility.":
        "Reduz a armadura de um inimigo em $s1 por $d s. Enquanto estiver afetado, o alvo não poderá usar furtividade ou invisibilidade.",

    # 320
    "Inflicts normal damage plus $s1 to an enemy, but only if attacking from behind. ":
        "Causa o dano normal mais $s1 a um inimigo, mas apenas se estiver atacando por trás.",

    # 321
    "Increases Armor by $s1 and frost resistance by $s3.   If an enemy strikes the caster, they may have their movement slowed by $7321s2% and the time between their attacks increased by $7321s1% for $7321d.  Only one type of Armor spell can be active on the Mage at any time.  Lasts $d.":
        "Aumenta a Armadura em $s1 e a resistência ao Gelo em $s2. Se um inimigo atingir o lançador, poderá ter sua velocidade de movimento reduzida em $s3% e o intervalo entre seus ataques aumentado em $s4% por $d1 s. Apenas um feitiço de Armadura pode estar ativo no Mago por vez. Dura $d2 s.",

    # 322
    "Instantly overpower the enemy, causing melee damage plus $s1.  Only useable after the target dodges.  The Overpower cannot be blocked, dodged or parried.":
        "Sobrepuja instantaneamente o inimigo, causando dano corpo a corpo mais $s1. Só pode ser usado após o alvo se esquivar. O Sobrepujar não pode ser bloqueado, esquivado ou aparado.",

    # 323
    "Call forth a succubus using the summoning circle.":
        "Evoca uma Súcubo utilizando o círculo de evocação.",

    # 324
    "Instantly sears the target with fire, causing $s1 Fire damage immediately and $o2 Fire damage over $d.":
        "Queima instantaneamente o alvo com fogo, causando $s1 de dano de Fogo imediato e mais $s2 de dano de Fogo ao longo de $d s.",

    # 325
    "Instantly shields you, absorbing $s1 damage and increasing your Frost damage by $s2%.  Lasts $d.  While the shield holds, spells will not be interrupted.":
        "Protege você instantaneamente com um escudo que absorve $s1 de dano e aumenta o seu dano de Gelo em $s2%. Dura $d s. Enquanto o escudo resistir, os feitiços não serão interrompidos.",

    # 326
    "Reduces the Physical damage dealt by an enemy by $s1 for $d. Only one curse per warlock can be active on any one target.":
        "Reduz o dano Físico causado por um inimigo em $s1 por $d s. Apenas uma maldição por Bruxo pode estar ativa em um mesmo alvo.",

    # 327
    "Strikes fear in an enemy, causing it to flee in terror for up to $d. Only 1 target can be feared at a time.":
        "Infunde medo em um inimigo, fazendo-o fugir aterrorizado por até $d s. Apenas 1 alvo pode ser amedrontado por vez.",

    # 328
    "A vicious strike that deals $s2% weapon damage and wounds the target, reducing the effectiveness of any healing by $s1% for $d.":
        "Um golpe cruel que causa $s2% do dano de arma e fere o alvo, reduzindo a eficácia de quaisquer curas em $s1% por $d s.",

    # 329
    "Inflicts $s1 damage to an enemy and stuns it for up to $d. You will automatically stop attacking. Target must be facing you. Any damage received by the stunned target will revive it.":
        "Causa $s1 de dano a um inimigo e o atordoa por até $d s. Você para de atacar automaticamente. O alvo precisa estar de frente para você. Qualquer dano sofrido pelo alvo atordoado o despertará.",

    # 330
    "Your next $n melee weapon swings strike an additional nearby opponent.":
        "Seus próximos $n golpes de arma corpo a corpo atingem um inimigo adicional próximo.",

    # 331
    "Transforms an enemy into a sheep, forcing it to wander around for up to $d. While wandering, the sheep cannot attack or cast spells, but regenerates very quickly. Any damage will transform the target back into its normal form. Only one target can be polymorphed at a time. Only works on beasts, dragons, giants, humanoids, and critters.":
        "Transforma um inimigo em uma ovelha, forçando-o a vagar desnorteado por até $d s. Enquanto vaga, a ovelha não pode atacar nem lançar feitiços, mas regenera vida muito rapidamente. Qualquer dano transformará o alvo de volta à sua forma normal. Apenas um alvo pode ser polimorfado por vez. Funciona apenas em feras, draconianos, gigantes, humanoides e criaturas.",

    # 332
    "Reduces the cooldown of your Stealth ability by $/1000;s1 secs.":
        "Reduz o tempo de recarga da sua habilidade Furtividade em $s1 s.",

    # 333
    "Stings the target, reducing Strength and Agility by $s1 for $d.  Only one Sting per Hunter can be active on any one target.":
        "Pica o alvo, reduzindo a Força e a Agilidade em $s1 por $d s. Apenas uma Picada por Caçador pode ficar ativa em um mesmo alvo.",

    # 334
    "Fires several missiles, hitting $x1 targets for an additional $s1 damage.":
        "Dispara vários projéteis, atingindo até $x1 alvos com $s1 de dano adicional.",

    # 335
    "Fires a volley of missiles at an enemy and its nearby allies, striking up to $x1 targets for normal damage plus $s1.":
        "Dispara uma saraivada de projéteis contra um inimigo e seus aliados próximos, atingindo até $x1 alvos com o dano normal mais $s1.",

    # 336
    "Inflicts normal damage plus $s1 to an enemy.":
        "Causa o dano normal mais $s1 a um inimigo.",

    # 337
    "Ignites the target, dealing $s1 Fire damage and consuming 3 sec of your Immolate spell to deal an amount of damage equal to it.":
        "Incendeia o alvo, causando $s1 de dano de Fogo e consumindo 3 s do seu feitiço Imolação para causar uma quantidade de dano equivalente.",

    # 338
    "Transfers $*10;s1 Health from the target to the caster over $d.":
        "Transfere $s1 de Vida do alvo para o lançador ao longo de $d s.",

    # 339
    "Increases the speed reduction of your Curse of Exhaustion by $s1%.":
        "Aumenta a redução de velocidade causada pela sua Maldição de Exaustão em $s1%.",

    # 340
    "Increases the speed bonus of your Aspect of the Cheetah and Aspect of the Pack by $s1%.":
        "Aumenta o bônus de velocidade dos seus feitiços Aspecto do Guepardo e Aspecto da Matilha em $s1%.",

    # 341
    "Increases the effect of your Concentration Aura by an additional $s1% and gives all group members affected by the aura an additional $s1% chance to resist Silence and Interrupt effects.":
        "Aumenta o efeito da sua Aura de Concentração em um adicional de $s1% e concede a todos os membros do grupo afetados pela aura um adicional de $s1% de chance de resistir a efeitos de Silêncio e Interrupção.",

    # 342
    "Enslaves the target demon, up to level $m1, forcing it to do your bidding.  While enslaved, the time between the demon's attacks is increased by $s2% and its casting speed is slowed by $s3%.  Lasts up to $d.":
        "Escraviza o demônio-alvo de nível até $m1, forçando-o a obedecer às suas ordens. Enquanto estiver escravizado, o intervalo entre os ataques do demônio aumenta em $s2% e sua velocidade de lançamento é reduzida em $s3%. Dura até $d s.",

    # 343
    "Instantly perform a reckless attack, dealing $s1 damage plus 35% of your Attack Power and increasing your movement speed by $51670s1% for $51670d.":
        "Desfere instantaneamente um ataque temerário, causando $s1 de dano mais 35% do seu Poder de Ataque e aumentando a sua velocidade de movimento em $s2% por $d s.",

    # 344
    "Rake the target for $s1 damage and an additional $o2 damage over $d.":
        "Estraçalha o alvo, causando $s1 de dano e mais $s2 de dano adicional ao longo de $d s.",

    # 345
    "Restores $s1 energy.":
        "Restaura $s1 de Energia.",

    # 346
    "Causes $s1 Shadow damage instantly, but the damage caused will begin healing itself after landing.":
        "Causa $s1 de dano de Sombra instantaneamente, mas o dano causado começará a se curar gradualmente após atingir o alvo.",

    # 347
    "Bashes the target with your shield for $s2 damage.  It also interrupts spellcasting and prevents any spell in that school from being cast for $d.":
        "Golpeia o alvo com o seu escudo, causando $s2 de dano. Também interrompe o lançamento de feitiços e impede que qualquer feitiço daquela escola seja lançado por $d s.",

    # 348
    "Counterattack an enemy for $s1 additional damage.   Riposte must follow a defensive action.":
        "Contra-ataca um inimigo, causando $s1 de dano adicional. Resposta só pode ser usada após uma ação defensiva.",

    # 349
    "Charge an enemy, generate $/10;s2 rage, and stun it for $7922d.  Cannot be used in combat.":
        "Investe contra um inimigo, gerando $s1 de Raiva e atordoando-o por $d s. Não pode ser usado em combate.",

    # 350
    "Increases Armor by $s1.  If an enemy strikes the caster, they may have their movement slowed by $6136s2% and the time between their attacks increased by $6136s1% for $6136d.  Only one type of Armor spell can be active on the Mage at any time.  Lasts $d.":
        "Aumenta a Armadura em $s1. Se um inimigo atingir o lançador, poderá ter sua velocidade de movimento reduzida em $s2% e o intervalo entre seus ataques aumentado em $s3% por $d1 s. Apenas um feitiço de Armadura pode estar ativo no Mago por vez. Dura $d2 s.",

    # 351
    "Disarm the enemy's weapon for $d.":
        "Desarma a arma do inimigo por $d s.",

    # 352
    "A targeted party member is protected from all physical attacks for $d, but during that time they cannot attack or use physical abilities.  Players may only have one Hand on them per Paladin at any one time.  Once protected, the target cannot be made invulnerable by Divine Shield, Divine Protection or Blessing of Protection again for $25771d.":
        "Um membro do grupo selecionado fica protegido de todos os ataques físicos por $d s, mas durante esse período não pode atacar nem usar habilidades físicas. Jogadores só podem ter uma Mão ativa por Paladino por vez. Uma vez protegido, o alvo não pode se tornar invulnerável novamente por Escudo Divino, Proteção Divina ou Bênção de Proteção por $d1 s."
}

def run():
    input_data = json.loads(INPUT_FILE.read_text(encoding="utf-8"))
    print(f"Lendo {len(input_data)} templates de entrada...")

    # Verifica se todas as chaves de entrada estão mapeadas
    missing = []
    for item in input_data:
        en = item["en"]
        if en not in translations:
            missing.append(en)

    if missing:
        print(f"ERRO: {len(missing)} templates faltando no dicionário de tradução:")
        for m in missing:
            print("  -", repr(m))
        sys.exit(1)

    print("Todos os 50 templates do arquivo de entrada foram encontrados no mapeamento.")

    # Valida pares
    errors = []
    for en, pt in translations.items():
        ok, msg = validate_pair(en, pt)
        if not ok:
            errors.append(f"FALHA: {msg}\n  EN: {en}\n  PT: {pt}")

    if errors:
        print(f"ERRO: {len(errors)} falhas de validação encontradas:")
        for e in errors:
            print(e)
        sys.exit(1)

    print("Validação de variáveis 100% OK para todos os 50 itens!")

    # Grava output_batch_03.json com ensure_ascii=False e utf-8
    OUTPUT_FILE.write_text(json.dumps(translations, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Gravado com sucesso em: {OUTPUT_FILE}")

if __name__ == "__main__":
    run()
