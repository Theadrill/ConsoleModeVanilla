#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extrai todos os totens de Xamã e todas as habilidades raciais das 8 raças.
"""
import json
import pathlib

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")

spells = json.loads((TEMP / "spell_en.json").read_text(encoding="utf-8"))
auth = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))

racials_names = [
    "blood fury", "war stomp", "berserking", "will of the forsaken", "cannibalize",
    "perception", "the human spirit", "sword specialization", "mace specialization", "diplomacy",
    "stoneform", "frost resistance", "gun specialization", "find treasure",
    "escape artist", "expansive mind", "arcane resistance", "engineering specialization",
    "shadowmeld", "quickness", "wisp spirit", "nature resistance",
    "endurance", "cultivation", "beast slaying", "throwing specialization", "bow specialization",
    "regeneration", "underwater breathing", "shadow resistance"
]

totems = {}
racials = {}

for sid, e in spells.items():
    n = (e.get("n") or "").lower()
    r = (e.get("r") or "").lower()
    d = e.get("d") or ""
    if not d or d.startswith("Teaches"):
        continue
    if "totem" in n and "Rank" in e.get("r", ""):
        totems.setdefault(d, []).append((sid, e.get("n"), e.get("r")))
    elif any(rc in n for rc in racials_names) and ("racial" in r or "passive" in r or r == ""):
        racials.setdefault(d, []).append((sid, e.get("n"), e.get("r")))

print(f"Total de templates únicos de Totens com Rank: {len(totems)}")
print(f"Total de templates únicos de Raciais: {len(racials)}")

(ADDON_DIR / "tools" / "all_totems.json").write_text(json.dumps([
    {"en": d, "current_pt": auth.get(d, ""), "samples": [f"{n} ({r}) [id={sid}]" for sid, n, r in inst]}
    for d, inst in totems.items()
], indent=2, ensure_ascii=False), encoding="utf-8")

(ADDON_DIR / "tools" / "all_racials.json").write_text(json.dumps([
    {"en": d, "current_pt": auth.get(d, ""), "samples": [f"{n} ({r}) [id={sid}]" for sid, n, r in inst]}
    for d, inst in racials.items()
], indent=2, ensure_ascii=False), encoding="utf-8")
