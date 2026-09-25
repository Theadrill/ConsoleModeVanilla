#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Aplica as 2 correções residual do revisa_extra AMOSTRA_06."""
import json, re, pathlib
ADDON = pathlib.Path(r"C:\PROJETOS\ConsoleModeVanilla")
DB = ADDON / "Data" / "ItemDB_ptBR.lua"
OV = ADDON / "tools" / "nomes_overrides.json"
fixes = {
    9562: ("Tablete Gravado com Runas", "Tabuleta->Tablete residual"),
    4123: ("Ombreiras de Metal de Gelo", "Spaulders->Ombreiras residual"),
}
src = DB.read_text(encoding="utf-8")
over = json.loads(OV.read_text(encoding="utf-8"))
for iid, (pt, motivo) in fixes.items():
    over[str(iid)] = {"pt": pt, "motivo": motivo}
    pat = re.compile(r'(\[%d\]\s*=\s*\")[^\"]*(\")' % iid)
    src = pat.sub(lambda m, p=pt: m.group(1) + p + m.group(2), src, count=1)
DB.write_text(src, encoding="utf-8")
OV.write_text(json.dumps(over, indent=1, ensure_ascii=False), encoding="utf-8")
print("overrides=%d" % len(over))
