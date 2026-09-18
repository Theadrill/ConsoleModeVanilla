#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import pathlib

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")

spells = json.loads((TEMP / "spell_en.json").read_text(encoding="utf-8"))
auth = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))

targets = ["fire nova", "blood fury"]

for sid, e in spells.items():
    n = (e.get("n") or "").lower()
    d = e.get("d") or ""
    if d and any(t in n for t in targets):
        print(f"ID={sid} | Name={e.get('n')} | Rank={e.get('r')}")
        print(f"  EN: {d}")
        print(f"  Current PT: {auth.get(d, 'NOT FOUND')}")
        print()
