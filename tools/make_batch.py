#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extrai um lote de templates para retradução no formato JSON.
"""
import json
import pathlib
import sys

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

def main():
    start = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    count = int(sys.argv[2]) if len(sys.argv) > 2 else 50

    ranked = json.loads((ADDON_DIR / "tools" / "player_class_ranked.json").read_text(encoding="utf-8"))
    auth = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))

    batch = ranked[start:start+count]
    out = []
    for i, item in enumerate(batch, start + 1):
        en = item["template_en"]
        curr_pt = auth.get(en, "")
        out.append({
            "idx": i,
            "count": item["count"],
            "sample": item["sample_spells"][0],
            "en": en,
            "curr_pt": curr_pt
        })

    out_file = ADDON_DIR / "tools" / f"batch_{start+1}_{start+count}.json"
    out_file.write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Salvo lote de {len(out)} itens em {out_file}")

if __name__ == "__main__":
    main()
