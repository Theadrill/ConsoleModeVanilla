#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase N — aplica vereditos de julgamento humano em Data/ItemDB_ptBR.lua.

Entrada: tools/batches/output_nomes_NN.json (ou output_amostra_NN.json):
  [{id, veredito: "manter"|"corrigir", pt_final, motivo}]
Efeito: só veredito=corrigir altera o DB; cada correção é registrada em
  tools/nomes_overrides.json ({id: {pt, motivo}}) para sobreviver a
  rebuilds futuros via tools/build_itemdb.py (rodar este apply depois).
Validação: id existe no DB; pt_final não-vazio e != EN quando corrige;
  sem placeholders $ em nomes (nome nunca tem variável).
Uso: py tools/apply_nomes.py tools/batches/output_nomes_01.json
"""
import json
import pathlib
import re
import sys

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
DB = ADDON_DIR / "Data" / "ItemDB_ptBR.lua"
OVERRIDES = ADDON_DIR / "tools" / "nomes_overrides.json"


def main():
    if len(sys.argv) < 2:
        print("Uso: py tools/apply_nomes.py <lote_output.json>")
        sys.exit(1)
    verdicts = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    src = DB.read_text(encoding="utf-8")
    try:
        over = json.loads(OVERRIDES.read_text(encoding="utf-8"))
    except OSError:
        over = {}
    n_ok = n_keep = 0
    errors = []
    for v in verdicts:
        i, vd = v.get("id"), v.get("veredito")
        pt = (v.get("pt_final") or "").strip()
        if vd not in ("manter", "corrigir"):
            errors.append("id %s: veredito inválido %r" % (i, vd))
            continue
        if vd == "manter":
            n_keep += 1
            continue
        if not pt:
            errors.append("id %s: corrigir com pt_final vazio" % i)
            continue
        if "$" in pt:
            errors.append("id %s: nome com placeholder $: %r" % (i, pt))
            continue
        pat = re.compile(r"(\[%d\]\s*=\s*\")[^\"]*(\")" % i)
        if not pat.search(src):
            errors.append("id %s: não achado no DB" % i)
            continue
        if v.get("en") and pt == v["en"]:
            errors.append("id %s: pt_final == EN (nada traduzido)" % i)
            continue
        src = pat.sub(lambda m: m.group(1) + pt + m.group(2), src, count=1)
        over[str(i)] = {"pt": pt, "motivo": v.get("motivo") or ""}
        n_ok += 1
    if errors:
        print("ERROS (%d):" % len(errors))
        for e in errors[:10]:
            print("  ", e)
        sys.exit(1)
    DB.write_text(src, encoding="utf-8")
    OVERRIDES.write_text(json.dumps(over, indent=1, ensure_ascii=False), encoding="utf-8")
    print("OK: %d corrigidos, %d mantidos, overrides=%d" % (n_ok, n_keep, len(over)))


if __name__ == "__main__":
    main()
