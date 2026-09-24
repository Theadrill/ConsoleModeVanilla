#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera 4 amostras estatisticas adicionais (seeds diferentes) da base
'limpa' R6 para validacao cruzada. Saida: input_amostra_06b..e.json."""
import json, io, random, pathlib, re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
Addon_DIR = ADDON_DIR
WOW_BASE = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns")
ENTRY_RE = re.compile(r"\[(\d+)\]\s*=\s*('(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")", re.DOTALL)

def unescape_lua(s):
    return s[1:-1].replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")

# Load EN
def load_en():
    en = {}
    for f in [WOW_BASE / "pfQuest/db/enUS/items.lua",
              WOW_BASE / "pfQuest-turtle/db/enUS/items-turtle.lua"]:
        try:
            for m in ENTRY_RE.finditer(f.read_text(encoding="utf-8")):
                try: en[int(m.group(1))] = unescape_lua(m.group(2))
                except ValueError: pass
        except OSError: pass
    return en

# Load PT (current ItemDB)
def load_pt():
    out = {}
    src = (ADDON_DIR / "Data/ItemDB_ptBR.lua").read_text(encoding="utf-8")
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\"([^\"]*)\"", src):
        out[int(m.group(1))] = m.group(2)
    return out

en = load_en()
pt = load_pt()
print("EN:", len(en), "PT:", len(pt))

# Load R6 suspects
queue = json.loads(io.open(ADDON_DIR / "tools/nomes_queue_r6.json", encoding="utf-8").read())
sus = set(q["id"] for q in queue)

# Exclude overrides (already corrected)
over = json.loads(io.open(ADDON_DIR / "tools/nomes_overrides.json", encoding="utf-8").read())
sus |= set(int(k) for k in over.keys())

print("Suspeitos+corrigidos excluidos:", len(sus))
clean = sorted(i for i in pt if i not in sus)
print("Clean disponiveis:", len(clean))

# Generate 4 samples with different seeds
suffixes = ["b", "c", "d", "e"]
seeds = [7006, 8006, 9006, 10006]
for suffix, seed in zip(suffixes, seeds):
    rnd = random.Random(seed)
    amostra = rnd.sample(clean, min(300, len(clean)))
    out = [{"id": i, "en": en.get(i, ""), "pt": pt[i]} for i in amostra]
    p = ADDON_DIR / "tools/batches" / ("input_amostra_06%s.json" % suffix)
    p.write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
    print("Gerado: %s (300 itens, seed=%d)" % (p.name, seed))
