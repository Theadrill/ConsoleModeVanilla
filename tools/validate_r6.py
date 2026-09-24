#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Valida output de lotes R6 antes do apply."""
import json, io, sys, pathlib

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

def validate(lote):
    inp = json.loads(io.open(str(ADDON_DIR) + "\\tools\\batches\\" + ("input_nomes_r6_%s.json" % lote), encoding="utf-8").read())
    out = json.loads(io.open(str(ADDON_DIR) + "\\tools\\batches\\" + ("output_nomes_r6_%s.json" % lote), encoding="utf-8").read())
    print("=== LOTE %s ===" % lote)
    print("Input: %d | Output: %d" % (len(inp), len(out)))
    ok = True
    for v in out:
        keys = set(v.keys())
        if not {'id','en','veredito','pt_final','motivo'} <= keys:
            print("  ERRO id=%s: chaves faltando %s" % (v.get('id'), keys))
            ok = False
        if v.get('veredito') not in ('manter','corrigir'):
            print("  ERRO id=%s: veredito invalido %r" % (v.get('id'), v.get('veredito')))
            ok = False
        pt = v.get('pt_final','')
        if '"' in pt or '\\' in pt or '$' in pt:
            print("  ERRO id=%s: caracter proibido em pt_final: %r" % (v.get('id'), pt))
            ok = False
        if v.get('veredito') == 'corrigir' and pt == v.get('en',''):
            print("  ERRO id=%s: pt_final == EN" % v.get('id'))
            ok = False
    c = sum(1 for v in out if v.get('veredito') == 'corrigir')
    m = sum(1 for v in out if v.get('veredito') == 'manter')
    print("  corrigir=%d | manter=%d | formato OK=%s" % (c, m, ok))
    inp_ids = set(x['id'] for x in inp)
    out_ids = set(x['id'] for x in out)
    if inp_ids != out_ids:
        print("  MISMATCH de IDs! faltam: %s, extras: %s" % (inp_ids - out_ids, out_ids - inp_ids))
    else:
        print("  IDs conferem (%d/%d)" % (len(out_ids), len(inp_ids)))
    return ok

if __name__ == "__main__":
    ok = True
    for lote in sys.argv[1:]:
        ok = validate(lote) and ok
    sys.exit(0 if ok else 1)
