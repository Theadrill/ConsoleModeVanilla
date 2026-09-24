#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase L (Legados): gera fila de revisao humanlike/Blizzlike de PTs autorais
suspeitos de estilo telegrafico/SMS que escaparam do auditor por padroes.

Criterios de flag (UNIAO):
  1. word-ratio: PT com metade ou menos das palavras do EN (EN com 4+ palavras).
  2. padroes SMS estendidos (alem dos de audit_effective_sms.py).
Exclui PT vazio. Dedupe por norma igual ao build (ultimo vence).

Saidas:
  tools/legado_queue.json ................ indice [{n, en, curr_pt, scope}]
  tools/batches/input_legado_01..N.json .. lotes de 50 [{en, curr_pt, scope}]

Loop por lote (tradutor): input_legado_NN.json -> output_legado_NN.json
  ([{en, pt}] final, reescrito ou mantido) -> validate_pair ->
  py tools/apply_batch.py tools/batches/output_legado_NN.json ->
  luac -p Data/SpellDescDB_ptBR.lua -> ledger PROGRESSO_LEGADO.txt -> commit.
Regra de quota: max 2 agentes tradutores simultaneos.

Uso: py tools/make_legado_batches.py
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

SMS_EXTRA = [
    r"\bpros\b",
    r"\bInvoca/dispensa\b",
    r"\bnos pisantes\b",
    r"^\S+ \+\d+\.$",
    r"^\S+ -\$\w+",
    r"^Teleporta pros\b",
    r"^Joga espinho\.$",
    r"^Disfarce de \w+\.$",
]


def norm(s):
    return re.sub(r"\s+", " ", s or "").strip().lower()


def looks_short(en, pt):
    ew = len(en.split())
    pw = len(pt.split())
    return ew >= 4 and pw * 2 <= ew


def looks_extra(pt):
    return any(re.search(p, pt) for p in SMS_EXTRA)


def main():
    raw = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    eff = {}
    for k, v in raw.items():
        eff[norm(k)] = (k, v)  # ultimo vence, igual ao build
    print("raw:", len(raw), "| efetivos:", len(eff))

    ranked = json.loads((ADDON_DIR / "tools" / "player_class_ranked.json").read_text(encoding="utf-8"))
    ranked_norms = set(norm(x["template_en"]) for x in ranked)
    other = json.loads((ADDON_DIR / "tools" / "player_other_templates.json").read_text(encoding="utf-8"))
    other_norms = set(norm(x["template_en"]) for x in other)
    work = json.loads((ADDON_DIR / "tools" / "mpq_work.json").read_text(encoding="utf-8"))
    work_norms = set(norm(o["d"]) for o in work)

    queue = []
    for nk, (en, pt) in eff.items():
        if not (pt or "").strip():
            continue
        if not (looks_short(en, pt) or looks_extra(pt)):
            continue
        if nk in ranked_norms:
            scope = "ranked"
        elif nk in other_norms:
            scope = "other"
        elif nk in work_norms:
            scope = "orphan"
        else:
            scope = "tail"
        queue.append({"en": en, "curr_pt": pt, "scope": scope})
    queue.sort(key=lambda x: (x["scope"], x["en"]))
    for i, q in enumerate(queue, 1):
        q["n"] = i
    print("candidatos:", len(queue))
    byscope = {}
    for q in queue:
        byscope[q["scope"]] = byscope.get(q["scope"], 0) + 1
    print("por escopo:", byscope)

    (ADDON_DIR / "tools" / "legado_queue.json").write_text(
        json.dumps(queue, indent=1, ensure_ascii=False), encoding="utf-8")

    chunks = [queue[i:i + 50] for i in range(0, len(queue), 50)]
    for n, ch in enumerate(chunks, 1):
        out = [{"en": q["en"], "curr_pt": q["curr_pt"], "scope": q["scope"]} for q in ch]
        p = ADDON_DIR / "tools" / "batches" / ("input_legado_%02d.json" % n)
        p.write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8")
    print("lotes input_legado_01..%02d (%d itens/lote, ultimo pode ser menor)" % (len(chunks), 50))


if __name__ == "__main__":
    main()
