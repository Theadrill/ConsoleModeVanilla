#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase 8.B-2: gera input batches de flavor (dedupe por texto normalizado).
Entrada: tools/itemdesc_flavor.json {id:{name,flavor}}.
Saida: tools/batches/input_itemdesc_01..NN.json [{en, ids, name}].
Uso: py tools/make_itemdesc_batches.py [--n 50]
"""
import json
import pathlib
import re
import sys

THIS_DIR = pathlib.Path(__file__).resolve().parent


def norm(s):
    return re.sub(r"\s+", " ", s or "").strip().lower()


def main():
    n = 50
    if "--n" in sys.argv:
        n = int(sys.argv[sys.argv.index("--n") + 1])
    flav = json.loads((THIS_DIR / "itemdesc_flavor.json").read_text(encoding="utf-8"))
    seen = {}
    for iid in sorted((int(k) for k in flav), key=int):
        e = flav[str(iid)]
        key = norm(e["flavor"])
        if key not in seen:
            seen[key] = {"en": e["flavor"], "ids": [], "name": e["name"]}
        seen[key]["ids"].append(iid)
    texts = sorted(seen.values(), key=lambda x: x["en"])
    print("flavor itens=%d unicos=%d" % (len(flav), len(texts)))
    batches = [texts[i:i + n] for i in range(0, len(texts), n)]
    for bi, b in enumerate(batches, 1):
        p = THIS_DIR / "batches" / ("input_itemdesc_%02d.json" % bi)
        p.write_text(json.dumps(b, ensure_ascii=False, indent=1), encoding="utf-8")
    print("lotes=%d (n=%d)" % (len(batches), n))


if __name__ == "__main__":
    main()
