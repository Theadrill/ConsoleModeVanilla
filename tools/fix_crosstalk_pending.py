#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Aplica correções para os 5 crosstalk edge-case pendentes."""
import json, pathlib, re
ADDON = pathlib.Path(r"C:\PROJETOS\ConsoleModeVanilla")
DB = ADDON / "Data" / "ItemDB_ptBR.lua"
OVER = ADDON / "tools/nomes_overrides.json"
# (id, pt_final, motivo) — heuristic correções para cross-talk
PENDING_FIXES = {
    6196: ("Cassetete de Noboru", "crosstalk: Truncheon recebeu PT de Noboru's Cudgel"),
    80821: ("Hatetalon", "crosstalk: recebeu Garra Hatefury do id 6246"),
    61486: ("Cinto Violeta", "crosstalk: recebeu Tragan Violeta do id 8526"),
    13137: ("Ironweaver", "crosstalk: recebeu Cinto de Ironweave do id 22306"),
    41269: ("Camisa Social Preta de Manga Arregaçada", "crosstalk: recebeu Camisa Darcy do id 41273"),
}
src = DB.read_text(encoding="utf-8")
over = json.loads(OVER.read_text(encoding="utf-8"))
n = 0
for iid, (pt_final, motivo) in PENDING_FIXES.items():
    pat = re.compile(r'(\[%d\]\s*=\s*\")[^\"]*(\")' % iid)
    if not pat.search(src):
        print("id %d: NOT FOUND in DB" % iid); continue
    src = pat.sub(lambda m: m.group(1) + pt_final + m.group(2), src, count=1)
    over[str(iid)] = {"pt": pt_final, "motivo": motivo}
    n += 1
    print("id %d: -> %s" % (iid, pt_final))
DB.write_text(src, encoding="utf-8")
OVER.write_text(json.dumps(over, indent=1, ensure_ascii=False), encoding="utf-8")
print("OK: %d correcoes aplicadas, overrides=%d" % (n, len(over)))
