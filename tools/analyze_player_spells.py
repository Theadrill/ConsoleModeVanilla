#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Analisa e extrai templates do Spellbook de Jogador (classes, raciais, pets, profissoes).
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")

def load_spells():
    p = TEMP / "spell_en.json"
    return json.loads(p.read_text(encoding="utf-8"))

def main():
    spells = load_spells()
    print("Total spells in spell_en.json:", len(spells))

    # Vamos coletar spells que tem Rank (Rank 1, Rank 2, etc.) ou que pertencem a classes
    ranked = {}
    for sid, e in spells.items():
        r = e.get("r", "")
        d = e.get("d", "")
        n = e.get("n", "")
        if d and ("Rank" in r or "Grau" in r or "Racial" in r or "Passive" in r):
            ranked.setdefault(d, []).append((sid, n, r))

    print("Unique descriptions with Rank/Racial/Passive:", len(ranked))

    # Vamos ver quantas sao de classes conhecidas
    # Classes: Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock, Druid
    # Pet spells: Torment, Blood Pact, Firebolt, Phase Shift, etc.
    # Spells conhecidas no localization_ptBR.lua
    loc_file = ADDON_DIR / "Data" / "Localization" / "localization_ptBR.lua"
    loc_text = loc_file.read_text(encoding="utf-8")
    
    known_names = set(re.findall(r'\["([^"]+)"\]\s*=', loc_text))
    print("Known names/keys in localization_ptBR.lua:", len(known_names))

    player_descs = {}
    for sid, e in spells.items():
        n = e.get("n", "")
        d = e.get("d", "")
        r = e.get("r", "")
        if not d:
            continue
        # Se o nome esta no localization_ptBR ou tem rank
        if n.lower() in known_names or "Rank" in r:
            player_descs.setdefault(d, []).append((sid, n, r))

    print("Player-facing unique descriptions:", len(player_descs))

    # Salva lista de templates de player para inspecao
    output_path = ADDON_DIR / "tools" / "player_templates.json"
    summary = []
    for d, instances in player_descs.items():
        summary.append({
            "template_en": d,
            "count": len(instances),
            "sample_spells": [f"{n} ({r}) [id={sid}]" for sid, n, r in instances[:3]]
        })
    output_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Salvo {len(summary)} templates em {output_path}")

if __name__ == "__main__":
    main()
