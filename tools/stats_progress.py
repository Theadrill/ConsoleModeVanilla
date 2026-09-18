#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Calcula estatísticas de cobertura e progresso da retradução.
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

def main():
    content = (ADDON_DIR / "Data" / "SpellDescDB_ptBR.lua").read_text(encoding="utf-8")
    pts = re.findall(r'pt="([^"]*)"', content)
    non_empty = [p for p in pts if p.strip()]
    print(f"Total de spells no DB: {len(pts)}")
    print(f"Total de spells com tradução ativa (PT preenchido): {len(non_empty)}")

    auth = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    print(f"Total de templates em spell_pt_authoral.json: {len(auth)}")

    ranked = json.loads((ADDON_DIR / "tools" / "player_class_ranked.json").read_text(encoding="utf-8"))
    print(f"Total de templates ranqueados de classe: {len(ranked)}")

if __name__ == "__main__":
    main()
