#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extrai todas as variantes de templates de Flametongue, Rockbiter e Earthbind.
"""
import json
import pathlib

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")

spells = json.loads((TEMP / "spell_en.json").read_text(encoding="utf-8"))

targets = ["flametongue weapon", "rockbiter weapon", "earthbind totem"]
matches = {}
for sid, e in spells.items():
    n = (e.get("n") or "").lower()
    d = e.get("d") or ""
    if d and any(t in n for t in targets):
        matches.setdefault(d, []).append((sid, e.get("n"), e.get("r")))

print(f"Total de templates únicos encontrados: {len(matches)}")
for d, instances in matches.items():
    print("---")
    print("EN:", d)
    print("Spells:", [f"{n} ({r}) [id={sid}]" for sid, n, r in instances])
