#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase N — amostragem do "limpo" (Camada 2, prova estatística de cobertura).

Sorteia N ids fora da fila de suspeitos (seed fixa p/ reprodutibilidade)
e gera tools/batches/input_amostra_RR.json [{id, en, pt}].
Julgamento idêntico ao dos suspeitos (output_amostra_RR.json).
Escape = corrigir/amostra. Meta: 0/300 (<1% a 95% — regra do 3/n).
Se > 1%: defeitos viram suspeitos + detector ganha sinal novo (loop).
Uso: py tools/make_amostra_nomes.py [rodada=1] [n=300]
"""
import json
import pathlib
import random
import re
import sys

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
WOW_BASE = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns")
ENTRY_RE = re.compile(r"\[(\d+)\]\s*=\s*('(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")", re.DOTALL)


def unescape_lua(s):
    return s[1:-1].replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def main():
    rodada = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 300
    # Lê a fila da rodada atual (nomes_queue.json = R1; nomes_queue_rX.json = R2+)
    qpath = ("nomes_queue_r%d.json" % rodada) if rodada >= 2 else "nomes_queue.json"
    queue = json.loads((ADDON_DIR / "tools" / qpath).read_text(encoding="utf-8"))
    sus = set(q["id"] for q in queue)
    # Exclui também itens já corrigidos (overrides) para não re-amostrar
    try:
        over = json.loads((ADDON_DIR / "tools" / "nomes_overrides.json").read_text(encoding="utf-8"))
        sus |= set(int(k) for k in over.keys())
    except OSError:
        pass
    pt = {}
    src = (ADDON_DIR / "Data" / "ItemDB_ptBR.lua").read_text(encoding="utf-8")
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\"([^\"]*)\"", src):
        pt[int(m.group(1))] = m.group(2)
    en = {}
    for f in (WOW_BASE / "pfQuest" / "db" / "enUS" / "items.lua",
              WOW_BASE / "pfQuest-turtle" / "db" / "enUS" / "items-turtle.lua"):
        try:
            s = f.read_text(encoding="utf-8")
        except OSError:
            continue
        for m in ENTRY_RE.finditer(s):
            try:
                en[int(m.group(1))] = unescape_lua(m.group(2))
            except ValueError:
                pass
    clean = sorted(i for i in pt if i not in sus)
    rnd = random.Random(1000 + rodada)
    amostra = rnd.sample(clean, min(n, len(clean)))
    out = [{"id": i, "en": en.get(i, ""), "pt": pt[i]} for i in amostra]
    p = ADDON_DIR / "tools" / "batches" / ("input_amostra_%02d.json" % rodada)
    p.write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
    print("rodada %d: amostra %d (limpo=%d) -> %s" % (rodada, len(out), len(clean), p.name))


if __name__ == "__main__":
    main()
