#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Aplica output_itemdesc_NN.json em tools/item_pt_authoral.json {rawEN: PT}
e reconstrói Data/ItemDescDB_ptBR.lua. Valida antes (falha = sem efeito).
Uso: py tools/apply_itemdesc_batch.py <output_itemdesc_NN.json>
"""
import json
import pathlib
import re
import subprocess
import sys

THIS_DIR = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))
from validate_itemflavor import validate_dict, norm


def main():
    batch_path = pathlib.Path(sys.argv[1])
    if not batch_path.is_absolute():
        batch_path = THIS_DIR.parent / batch_path
    pairs = json.loads(batch_path.read_text(encoding="utf-8"))
    if isinstance(pairs, list):
        pairs = {it.get("en", it.get("template_en")): it.get("pt", it.get("pt_natural")) for it in pairs}
    errors, warns = validate_dict(pairs)
    if errors:
        print(f"VALIDACAO FALHOU ({len(errors)} erros):")
        for e in errors[:10]:
            print("  ERRO", e)
        sys.exit(1)
    print(f"validacao OK: {len(pairs)} pares, {len(warns)} avisos")
    auth_path = THIS_DIR / "item_pt_authoral.json"
    auth = json.loads(auth_path.read_text(encoding="utf-8")) if auth_path.exists() else {}
    authn = {norm(k): v for k, v in auth.items()}
    updated = added = 0
    for en, pt in pairs.items():
        k = norm(en)
        if k in authn and authn[k] != pt:
            # mesma norma, PT distinto entre lotes = conflito real
            print(f"CONFLITO entre lotes: {en[:70]!r}")
            sys.exit(1)
        if en in auth:
            if auth[en] != pt:
                auth[en] = pt
                updated += 1
        else:
            auth[en] = pt
            added += 1
    auth_path.write_text(json.dumps(auth, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"item_pt_authoral.json: {updated} atualizados, {added} novos")
    res = subprocess.run([sys.executable, str(THIS_DIR / "build_itemdescdb.py")],
                         capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print("ERRO build:", res.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
