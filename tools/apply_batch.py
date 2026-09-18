#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Aplica um lote de retradução humana Blizzlike em tools/spell_pt_authoral.json,
com validação estrita de variáveis e rebuild automático de Data/SpellDescDB_ptBR.lua.
"""
import json
import pathlib
import subprocess
import sys
from validate_spell_vars import validate_pair

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

def main():
    if len(sys.argv) < 2:
        print("Uso: py tools/apply_batch.py <caminho_do_lote_traduzido.json>")
        sys.exit(1)

    batch_path = pathlib.Path(sys.argv[1])
    if not batch_path.is_absolute():
        batch_path = ADDON_DIR / batch_path

    translations = json.loads(batch_path.read_text(encoding="utf-8"))
    # Suporta tanto {"EN": "PT"} quanto [{"en": "...", "pt": "..."}]
    pairs = {}
    if isinstance(translations, dict):
        pairs = translations
    elif isinstance(translations, list):
        for item in translations:
            en = item.get("en") or item.get("template_en")
            pt = item.get("pt") or item.get("pt_natural")
            if en and pt:
                pairs[en] = pt

    print(f"Validando {len(pairs)} pares de tradução...")
    errors = []
    for en, pt in pairs.items():
        ok, msg = validate_pair(en, pt)
        if not ok:
            errors.append(f"ERRO: '{en}' -> '{pt}': {msg}")

    if errors:
        print(f"Foram encontrados {len(errors)} erros de validação de variáveis:")
        for err in errors[:10]:
            print("  ", err)
        if len(errors) > 10:
            print(f"  ... e mais {len(errors) - 10} erros.")
        sys.exit(1)

    print("Validação de variáveis 100% OK!")

    # Carrega spell_pt_authoral.json
    auth_file = ADDON_DIR / "tools" / "spell_pt_authoral.json"
    auth = json.loads(auth_file.read_text(encoding="utf-8"))

    updated = 0
    added = 0
    for en, pt in pairs.items():
        if en in auth:
            if auth[en] != pt:
                auth[en] = pt
                updated += 1
        else:
            auth[en] = pt
            added += 1

    auth_file.write_text(json.dumps(auth, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"spell_pt_authoral.json atualizado: {updated} atualizados, {added} novos.")

    # Reconstrói Data/SpellDescDB_ptBR.lua
    print("Reconstruindo Data/SpellDescDB_ptBR.lua...")
    res = subprocess.run([sys.executable, str(ADDON_DIR / "tools" / "build_spelldescdb.py")], capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print("ERRO ao executar build_spelldescdb.py:", res.stderr)
        sys.exit(1)

    print("Lote aplicado e validado com sucesso!")

if __name__ == "__main__":
    main()
