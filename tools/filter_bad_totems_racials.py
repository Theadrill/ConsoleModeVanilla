#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

totems = json.loads((ADDON_DIR / "tools" / "all_totems.json").read_text(encoding="utf-8"))
racials = json.loads((ADDON_DIR / "tools" / "all_racials.json").read_text(encoding="utf-8"))

def needs_review(pt):
    if not pt:
        return True
    bad = [
        r": \+", r";", r"Totem \d+ por", r"Poder \+", r"Lenta bate", r"pra beber", r"pra comer",
        r"Some se deslogar", r"Pet \+", r"Arma:", r"na hora", r"Mete medo", r"viva em", r"causa.*a \d+ m"
    ]
    return any(re.search(b, pt, re.IGNORECASE) for b in bad) or len(pt) < 25

bad_totems = [t for t in totems if needs_review(t.get("current_pt", ""))]
bad_racials = [r for r in racials if needs_review(r.get("current_pt", ""))]

print(f"Totens que precisam de retradução humana: {len(bad_totems)} de {len(totems)}")
print(f"Raciais que precisam de retradução humana: {len(bad_racials)} de {len(racials)}")

(ADDON_DIR / "tools" / "totems_to_fix.json").write_text(json.dumps(bad_totems, indent=2, ensure_ascii=False), encoding="utf-8")
(ADDON_DIR / "tools" / "racials_to_fix.json").write_text(json.dumps(bad_racials, indent=2, ensure_ascii=False), encoding="utf-8")
