#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Recupera spell_en.json ({id: {n,r,d,t}}) a partir de Data/SpellDescDB_ptBR.lua.
Quebra-galho quando o spell_en.json local (artefato fora do git, cf. default
em tools/build_spelldescdb.py) se perde: o .lua contem n/r/d/t integros,
round-trip sem perda (escape_lua_string e reversivel).
Uso: py tools/recover_spell_en.py [destino]  (default = path esperado pelo build)
"""
import json
import pathlib
import re
import sys

THIS_DIR = pathlib.Path(__file__).resolve().parent
ADDON_DIR = THIS_DIR.parent
LUA = ADDON_DIR / "Data" / "SpellDescDB_ptBR.lua"
DEFAULT_DEST = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\spell_en.json")

PAT = re.compile(
    r'ConsoleMode_SpellDescDB\[(\d+)\] = \{ n="(.*)", r="(.*)", d="(.*)", t="(.*)", pt="(.*)" \}')


def un(s):
    return s.replace('\\"', '"').replace("\\n", "\n").replace("\\r", "\r").replace("\\\\", "\\")


def main():
    dest = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_DEST
    spells = {}
    for m in PAT.finditer(LUA.read_text(encoding="utf-8")):
        sid, n, r, d, t, _pt = m.groups()
        spells[sid] = {"n": un(n), "r": un(r), "d": un(d), "t": un(t)}
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(spells, ensure_ascii=False), encoding="utf-8")
    print("spells=%d com_desc=%d -> %s"
          % (len(spells), sum(1 for v in spells.values() if v["d"]), dest))


if __name__ == "__main__":
    main()
