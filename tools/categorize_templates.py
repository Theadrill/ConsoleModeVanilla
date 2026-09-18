#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Classifica os templates de jogador por categoria de relevância:
1. Class Abilities (Guerreiro, Paladino, Caçador, Ladino, Sacerdote, Xamã, Mago, Bruxo, Druida)
2. Racials (Tauren, Orc, Troll, Undead, Humano, Anão, Gnomo, Elfo Noturno)
3. Professions / Trade Skills (Alquimia, Ferraria, Encantamento, Engenharia, Primeiros Socorros, etc.)
4. Pets / Minions (Warlock pets, Hunter pets)
5. Outros
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")

CLASS_KEYWORDS = [
    # Shaman
    "totem", "shock", "lightning", "chain lightning", "healing wave", "ancestral",
    "windfury", "flametongue", "rockbiter", "frostbrand", "water walking", "water breathing",
    "far sight", "reincarnation", "purge",
    # Warrior
    "strike", "shout", "rend", "charge", "intercept", "overpower", "slam", "whirlwind",
    "shield bash", "shield block", "shield wall", "taunt", "mocking blow", "retaliation",
    "recklessness", "death wish", "bloodthirst", "mortal strike", "sunder armor", "disarm",
    "pummel", "berserker rage", "bloodrage", "hamstring",
    # Paladin
    "seal", "judgment", "blessing", "aura", "holy light", "flash of light", "lay on hands",
    "hammer of justice", "exorcism", "holy wrath", "consecration", "cleanse", "purify",
    "divine shield", "divine protection", "righteous fury", "repentance", "holy shock",
    # Hunter
    "shot", "sting", "trap", "aspect", "track", "mend pet", "feed pet", "tame beast",
    "revive pet", "concussive", "aimed shot", "multi-shot", "flare", "raptor strike",
    "mongoose bite", "wing clip", "disengage", "feign death", "volley",
    # Rogue
    "stealth", "vanish", "sinister strike", "backstab", "gouge", "evasion", "sprint",
    "kick", "kidney shot", "cheap shot", "ambush", "garrote", "rupture", "eviscerate",
    "slice and dice", "blind", "sap", "distract", "pick pocket", "lockpicking", "poisons",
    # Priest
    "heal", "greater heal", "flash heal", "renew", "prayer of healing", "power word",
    "shadow word", "smite", "holy fire", "mind blast", "mind flay", "mind control",
    "psychic scream", "fade", "inner fire", "dispel magic", "cure disease", "abolish disease",
    "shadowform", "vampiric embrace", "silence", "mana burn",
    # Mage
    "fireball", "frostbolt", "arcane missiles", "scorch", "pyroblast", "fire blast",
    "flamestrike", "blast wave", "cone of cold", "frost nova", "blizzard", "ice armor",
    "frost armor", "mage armor", "arcane intellect", "arcane brilliance", "dampen magic",
    "amplify magic", "slow fall", "blink", "counterspell", "polymorph", "teleport",
    "portal", "conjure", "mana shield", "ice barrier", "combustion", "evocation",
    # Warlock
    "shadow bolt", "immolate", "corruption", "curse of", "drain soul", "drain life",
    "drain mana", "life tap", "health funnel", "create healthstone", "create soulstone",
    "create spellstone", "create firestone", "summon imp", "summon voidwalker",
    "summon succubus", "summon felhunter", "fear", "howl of terror", "banish",
    "hellfire", "rain of fire", "searing pain", "shadowburn", "conflagrate", "death coil",
    # Druid
    "healing touch", "rejuvenation", "regrowth", "tranquility", "mark of the wild",
    "thorns", "moonfire", "starfire", "wrath", "insect swarm", "entangling roots",
    "hibernate", "faerie fire", "demoralizing roar", "bash", "maul", "swipe", "feral charge",
    "claw", "shred", "rip", "rake", "bite", "ravage", "prowl", "cower", "dash", "cure poison"
]

def main():
    templates = json.loads((ADDON_DIR / "tools" / "player_templates.json").read_text(encoding="utf-8"))
    print(f"Carregados {len(templates)} templates")

    class_spells = []
    others = []

    for t in templates:
        tpl_en = t["template_en"].lower()
        samples = " ".join(t["sample_spells"]).lower()
        
        is_class = any(kw in samples or kw in tpl_en for kw in CLASS_KEYWORDS)
        if is_class:
            class_spells.append(t)
        else:
            others.append(t)

    print(f"Templates de Habilidades de Classe/Pet/Racial: {len(class_spells)}")
    print(f"Demais templates de jogador/profissão/itens: {len(others)}")

    (ADDON_DIR / "tools" / "player_class_templates.json").write_text(
        json.dumps(class_spells, indent=2, ensure_ascii=False), encoding="utf-8")
    (ADDON_DIR / "tools" / "player_other_templates.json").write_text(
        json.dumps(others, indent=2, ensure_ascii=False), encoding="utf-8")

if __name__ == "__main__":
    main()
