#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera Data/ItemDB_ptBR.lua a partir de pfQuest + pfQuest-turtle (EN + ptBR).
- pfQuest/db/enUS/items.lua                 -> pfDB['items']['enUS']       (fonte da verdade EN vanilla)
- pfQuest/db/ptBR/items.lua                 -> pfDB['items']['ptBR']       (PT vanilla comunidade)
- pfQuest-turtle/db/enUS/items-turtle.lua   -> pfDB['items']['enUS-turtle'] (fonte da verdade EN customs)
- pfQuest-turtle/db/ptBR/items-turtle.lua   -> pfDB['items']['ptBR-turtle'] (PT customs comunidade)
Turtle tem prioridade sobre vanilla em conflito de ID.
Saida: Data/ItemDB_ptBR.lua com ConsoleMode_ItemDB[id] = "Nome PT"
       e ConsoleMode_ItemDB_ByName["lower(en)"] = id (fallback quando link/ID indisponivel).
"""
import pathlib
import re

THIS_DIR = pathlib.Path(__file__).resolve().parent
ADDON_DIR = THIS_DIR.parent
WOW_BASE = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns")
VANILLA_EN = WOW_BASE / "pfQuest" / "db" / "enUS" / "items.lua"
VANILLA_PT = WOW_BASE / "pfQuest" / "db" / "ptBR" / "items.lua"
TURTLE_EN = WOW_BASE / "pfQuest-turtle" / "db" / "enUS" / "items-turtle.lua"
TURTLE_PT = WOW_BASE / "pfQuest-turtle" / "db" / "ptBR" / "items-turtle.lua"
OUTPUT = ADDON_DIR / "Data" / "ItemDB_ptBR.lua"

# [id] = "Name"  (aspas simples ou duplas, com escapes)
ENTRY_RE = re.compile(r"\[(\d+)\]\s*=\s*('(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")", re.DOTALL)

def unescape_lua(s):
    q = s[0]
    body = s[1:-1]
    tmp = body.replace("\\\\", "\x00")
    if q == '"':
        tmp = tmp.replace('\\"', '"')
    else:
        tmp = tmp.replace("\\'", "'")
    tmp = tmp.replace("\x00", "\\")
    return tmp

def parse_items(path):
    text = pathlib.Path(path).read_text(encoding="utf-8-sig", errors="strict")
    out = {}
    for m in ENTRY_RE.finditer(text):
        iid = int(m.group(1))
        try:
            out[iid] = unescape_lua(m.group(2))
        except Exception:
            continue
    return out

def escape_lua_string(s):
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\r", "\\r")
    s = s.replace("\n", "\\n")
    return s

def main():
    print("Lendo vanilla EN: %s" % VANILLA_EN)
    v_en = parse_items(VANILLA_EN)
    print("  vanilla enUS items: %d" % len(v_en))
    print("Lendo vanilla PT: %s" % VANILLA_PT)
    v_pt = parse_items(VANILLA_PT)
    print("  vanilla ptBR items: %d" % len(v_pt))
    print("Lendo turtle EN: %s" % TURTLE_EN)
    t_en = parse_items(TURTLE_EN)
    print("  turtle enUS items: %d" % len(t_en))
    print("Lendo turtle PT: %s" % TURTLE_PT)
    t_pt = parse_items(TURTLE_PT)
    print("  turtle ptBR items: %d" % len(t_pt))

    # Merge EN (verdade): vanilla base + turtle sobrescreve
    en = dict(v_en)
    overw_en = 0
    for iid, name in t_en.items():
        if iid in en:
            overw_en += 1
        en[iid] = name
    # Merge PT: vanilla base + turtle sobrescreve; falta PT -> EN
    pt = dict(v_pt)
    overw_pt = 0
    for iid, name in t_pt.items():
        if iid in pt:
            overw_pt += 1
        pt[iid] = name

    ids = sorted(en.keys())
    missing_pt = 0
    for iid in ids:
        if iid not in pt or not pt[iid] or pt[iid] == "_":
            pt[iid] = en[iid]
            missing_pt += 1

    print("Total IDs EN: %d (turtle overwrote %d)" % (len(ids), overw_en))
    print("PT merged, turtle overwrote %d, fallback EN: %d" % (overw_pt, missing_pt))

    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("-- AUTO-GERADO. NAO EDITAR MANUALMENTE.\n")
        fh.write("-- Gerado por tools/build_itemdb.py a partir de pfQuest/db + pfQuest-turtle/db (enUS/ptBR)\n")
        fh.write("-- Turtle tem prioridade sobre vanilla em conflito de ID. IDs sem PT usam EN.\n")
        fh.write("ConsoleMode_ItemDB = {}\n")
        for iid in ids:
            fh.write('ConsoleMode_ItemDB[%d] = "%s"\n' % (iid, escape_lua_string(pt[iid])))
        fh.write("ConsoleMode_ItemDB_ByName = {}\n")
        for iid in ids:
            en_name = en[iid]
            if en_name and en_name != "_":
                fh.write('ConsoleMode_ItemDB_ByName["%s"] = %d\n' % (escape_lua_string(en_name.lower()), iid))
    print("Escrito: %s (%d itens)" % (OUTPUT, len(ids)))

if __name__ == "__main__":
    main()
