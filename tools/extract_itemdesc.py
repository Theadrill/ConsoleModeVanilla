#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase 8.B-0: extrai do Tortoise SQLite (Turtle 1.12) a materia-prima de ItemDescDB.
Fonte: tortoise.sqlite (fora do git; ver §8.7 do plano p/ re-download).
Tortoise -> somente IDs presentes no ItemDB Capy (autoridade de IDs).
Saida (arquivos magros, sem duplicar descs — build resolve via spell_en/authoral):
  tools/itemdesc_flavor.json   {id: {name, flavor}} (fila humana 8.B-2)
  tools/itemdesc_spellmap.json {id: [{trig, spell}]} (runtime 8.B-1, gratis)
Uso: py tools/extract_itemdesc.py [--sqlite <path>]
"""
import json
import pathlib
import re
import sqlite3
import sys

THIS_DIR = pathlib.Path(__file__).resolve().parent
ADDON_DIR = THIS_DIR.parent
DEFAULT_SQLITE = pathlib.Path(
    r"C:\Users\rodri\AppData\Local\Temp\opencode\tortoise.sqlite")

TRIG = {0: "use", 1: "equip", 2: "chance"}


def opt(flag, default):
    if flag in sys.argv:
        i = sys.argv.index(flag)
        if i + 1 < len(sys.argv):
            return sys.argv[i + 1]
    return default


def norm(s):
    return re.sub(r"\s+", " ", s or "").strip().lower()


def main():
    sqlite_p = pathlib.Path(opt("--sqlite", str(DEFAULT_SQLITE)))
    auth = json.loads((THIS_DIR / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    authn = set(norm(k) for k in auth)
    lua = (ADDON_DIR / "Data" / "ItemDB_ptBR.lua").read_text(encoding="utf-8")
    capy_ids = set(int(m.group(1)) for m in re.finditer(r"\[(\d+)\]\s*=", lua))
    print("capy ids: %d | authoral templates: %d" % (len(capy_ids), len(authn)))

    con = sqlite3.connect(str(sqlite_p))
    con.row_factory = sqlite3.Row
    spells = {r["entry"]: dict(r) for r in
              con.execute("SELECT entry, name, description FROM spells")}
    flavor, smap, n_links, n_free, n_nopt = {}, {}, 0, 0, 0
    for r in con.execute(
            "SELECT entry, name, description, spellid_1, spelltrigger_1, "
            "spellid_2, spelltrigger_2, spellid_3, spelltrigger_3, "
            "spellid_4, spelltrigger_4, spellid_5, spelltrigger_5 FROM items"):
        eid = r["entry"]
        if eid not in capy_ids:
            continue
        f = (r["description"] or "").strip()
        if f:
            flavor[eid] = {"name": r["name"], "flavor": f}
        links = []
        for n in (1, 2, 3, 4, 5):
            sid = r["spellid_%d" % n] or 0
            if not sid:
                continue
            sp = spells.get(sid)
            if not sp or not (sp["description"] or "").strip():
                continue
            trig = TRIG.get(r["spelltrigger_%d" % n] or 0, "other")
            links.append({"trig": trig, "spell": sid})
            n_links += 1
            if norm(sp["description"]) in authn:
                n_free += 1
            else:
                n_nopt += 1
        if links:
            smap[eid] = links
    con.close()
    pf = THIS_DIR / "itemdesc_flavor.json"
    ps = THIS_DIR / "itemdesc_spellmap.json"
    pf.write_text(json.dumps(flavor, ensure_ascii=False, indent=1), encoding="utf-8")
    ps.write_text(json.dumps(smap, ensure_ascii=False), encoding="utf-8")
    print("flavor: %d itens -> %s (%d bytes)" % (len(flavor), pf.name, pf.stat().st_size))
    print("spellmap: %d itens, %d links (gratis=%d semPT=%d) -> %s (%d bytes)"
          % (len(smap), n_links, n_free, n_nopt, ps.name, ps.stat().st_size))


if __name__ == "__main__":
    main()
