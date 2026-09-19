#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera lotes de revisao S01.. a partir de effective_sms.json (scope=other).
Uso: py tools/make_sms_batches.py
"""
import json
import pathlib

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent


def main():
    flagged = json.loads((ADDON_DIR / "tools" / "effective_sms.json").read_text(encoding="utf-8"))
    other = [f for f in flagged if f["scope"] == "other"]
    print("other:", len(other))
    chunks = [other[i:i + 50] for i in range(0, len(other), 50)]
    n = 0
    for ch in chunks:
        n += 1
        out = [{"en": f["en"], "curr_pt": f["pt"], "sample": "", "need": "review"} for f in ch]
        p = ADDON_DIR / "tools" / "batches" / ("input_sms_%02d.json" % n)
        p.write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8")
        print("input_sms_%02d.json" % n, len(out))


if __name__ == "__main__":
    main()
