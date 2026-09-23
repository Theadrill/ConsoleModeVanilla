#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase 8.B: gera Data/ItemDescDB_ptBR.lua a partir do spellmap + PT autoral.
Entradas: tools/itemdesc_spellmap.json {id:[{trig,spell}]} (8.B-0, Tortoise)
          tools/item_pt_authoral.json {id:{use,equip,flavor}} (8.B-2, opcional)
Saida: Data/ItemDescDB_ptBR.lua:
  ConsoleMode_ItemDescDB[id] = { s={ {t="use",s=SPELLID}, ... }, f="flavor PT" }
Somente links cuja magia tem PT no spell_pt_authoral entram em `s`
(magia sem PT = fallback ItemStat, sem linha morta no DB).
Uso: py tools/build_itemdescdb.py
"""
import json
import pathlib
import re

THIS_DIR = pathlib.Path(__file__).resolve().parent
ADDON_DIR = THIS_DIR.parent
OUTPUT = ADDON_DIR / "Data" / "ItemDescDB_ptBR.lua"


def escape_lua_string(s):
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\r", "\\r")
    s = s.replace("\n", "\\n")
    return s


def norm(s):
    return re.sub(r"\s+", " ", s or "").strip().lower()


def main():
    smap = json.loads((THIS_DIR / "itemdesc_spellmap.json").read_text(encoding="utf-8"))
    auth_path = THIS_DIR / "spell_pt_authoral.json"
    authn = set()
    if auth_path.exists():
        authn = set(norm(k) for k, v in
                    json.loads(auth_path.read_text(encoding="utf-8")).items() if v)
    # EN das magias p/ conferir PT: via Temp spell_en (fora do git) ou tortoise; fallback: mantem link
    flavor_auth = {}
    fa_path = THIS_DIR / "item_pt_authoral.json"
    if fa_path.exists():
        raw = json.loads(fa_path.read_text(encoding="utf-8"))
        if isinstance(raw, dict):
            flavor_auth = {norm(k): v for k, v in raw.items() if v}

    # spellID -> tem PT? Barato: carrega d->pt do authoral
    # e o EN de cada spell via repo (fallback Temp) quando disponivel.
    spell_en = {}
    se_repo = THIS_DIR / "spell_en.json"
    se_temp = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\spell_en.json")
    se_path = se_repo if se_repo.exists() else se_temp
    if se_path.exists():
        spell_en = json.loads(se_path.read_text(encoding="utf-8"))

    n_items, n_links, n_skip, n_flav = 0, 0, 0, 0
    # flavor EN por id (p/ casar com o authoral por norma)
    flav_en = {}
    fl_path = THIS_DIR / "itemdesc_flavor.json"
    if fl_path.exists():
        for k, v in json.loads(fl_path.read_text(encoding="utf-8")).items():
            flav_en[int(k)] = v.get("flavor", "")
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("-- AUTO-GERADO por tools/build_itemdescdb.py. NAO EDITAR MANUALMENTE.\n")
        fh.write("-- Links item->magia via Tortoise SQLite (§8.7); flavor via item_pt_authoral.json.\n")
        fh.write("ConsoleMode_ItemDescDB = {}\n")
        for iid in sorted(set(int(k) for k in smap) | set(flav_en), key=int):
            links = []
            for lk in smap.get(str(iid), []):
                sid = lk.get("spell")
                if not sid:
                    continue
                d = (spell_en.get(str(sid)) or {}).get("d", "")
                if d and norm(d) in authn:
                    links.append((lk.get("trig", "use"), sid))
                elif not d:
                    links.append((lk.get("trig", "use"), sid))
                else:
                    n_skip += 1
            fpt = flavor_auth.get(norm(flav_en.get(iid, "")), "")
            if fpt:
                n_flav += 1
            if not links and not fpt:
                continue
            parts = []
            for trig, sid in links:
                parts.append('{ t = "%s", s = %d }' % (trig, sid))
                n_links += 1
            fh.write("ConsoleMode_ItemDescDB[%d] = { s = { %s }, f = \"%s\" }\n"
                     % (iid, ", ".join(parts), escape_lua_string(fpt)))
            n_items += 1
    print("itens=%d links=%d flavorPT=%d (magia-sem-PT pulados=%d) -> %s (%d bytes)"
          % (n_items, n_links, n_flav, n_skip, OUTPUT, OUTPUT.stat().st_size))


if __name__ == "__main__":
    main()
