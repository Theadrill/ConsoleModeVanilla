#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Caca-tudo: cobertura PT por template no merge, priorizado.
Prioriza templates usados por spells de Rank<=10 (leveling) e depois frequencia.
Uso: py tools/coverage_spells.py [--lote N]  (gera loteN.txt no Temp)
"""
import json
import re
import sys
from collections import defaultdict

spells = json.load(open(r"C:\Users\rodri\AppData\Local\Temp\opencode\spell_en.json", encoding="utf-8"))
auth = json.load(open("tools/spell_pt_authoral.json", encoding="utf-8"))
TYPO_MAP = {
    "\u2019": "'", "\u2018": "'", "\u201a": "'", "`": "'",
    "\u201c": '"', "\u201d": '"', "\u201e": '"',
    "\u2013": "-", "\u2014": "-", "\u2026": "...", "\u00a0": " ",
}


def norm(s):
    t = s or ""
    for a, b in TYPO_MAP.items():
        t = t.replace(a, b)
    return re.sub(r"\s+", " ", t).strip().lower()
akeys = set(norm(k) for k in auth)


def ranknum(r):
    m = re.search(r"(\d+)", r or "")
    return int(m.group(1)) if m else 999


groups = defaultdict(list)
for sid, e in spells.items():
    if e["d"] and norm(e["d"]) not in akeys and not e["d"].startswith("Teaches "):
        groups[norm(e["d"])].append((int(sid), e["n"], e["r"], e["d"]))

tot_desc = sum(len(v) for v in groups.values())
print("templates sem PT: %d | descs descobertas: %d" % (len(groups), tot_desc))

scored = []
for tpl, ids in groups.items():
    low = sum(1 for _, _, r, _ in ids if ranknum(r) <= 10)
    scored.append((tpl, len(ids), low, ids[0]))
scored.sort(key=lambda b: (-b[2], -b[1]))

n = 200
batch = scored[:n]
print("lote: %d templates cobrem %d descs (%d rank<=10)" % (
    len(batch), sum(b[1] for b in batch), sum(b[2] for b in batch)))
name = "lote3.txt"
args = sys.argv[1:]
i = 0
while i < len(args):
    if args[i] == "--lote" and i + 1 < len(args):
        name = "lote%d.txt" % int(args[i + 1])
        i += 1
    i += 1
out = []
for i, (tpl, cnt, low, ex) in enumerate(batch):
    orig = ex[3]
    out.append("### [%d] (%dx, low %dx) ex: %s %s (id %d)\nEN: %s\nPT: \n" % (
        i + 1, cnt, low, ex[1], ex[2], ex[0], orig))
open(r"C:\Users\rodri\AppData\Local\Temp\opencode\\" + name, "w", encoding="utf-8").write("\n".join(out))
print("salvo", name)
