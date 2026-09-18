#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import pathlib

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

totems = json.loads((ADDON_DIR / "tools" / "all_totems.json").read_text(encoding="utf-8"))
racials = json.loads((ADDON_DIR / "tools" / "all_racials.json").read_text(encoding="utf-8"))

print(f"--- TOTENS ({len(totems)}) ---")
for t in totems:
    pt = t.get("current_pt", "")
    en = t.get("en", "")
    s = t.get("samples", ["?"])[0]
    print(f"[{s}]")
    print(f"  EN: {en}")
    print(f"  PT: {pt}")
    print()

print(f"--- RACIAIS ({len(racials)}) ---")
for r in racials:
    pt = r.get("current_pt", "")
    en = r.get("en", "")
    s = r.get("samples", ["?"])[0]
    print(f"[{s}]")
    print(f"  EN: {en}")
    print(f"  PT: {pt}")
    print()
