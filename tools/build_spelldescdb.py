#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera Data/SpellDescDB_ptBR.lua a partir do spell_en.json (merge snapshot+patch).
Formato: ConsoleMode_SpellDescDB[id] = { n, r, d, t, pt }
+ ConsoleMode_SpellDescDB_ByKey["nome|grauN"] = id (+ alias "nome|" p/ rankless).
PT vem de tools/spell_pt_authoral.json {EN-template: PT} (chave case-insensitive).
Uso: py tools/build_spelldescdb.py [<spell_en.json>]
"""
import json
import pathlib
import re
import sys

THIS_DIR = pathlib.Path(__file__).resolve().parent
ADDON_DIR = THIS_DIR.parent
OUTPUT = ADDON_DIR / "Data" / "SpellDescDB_ptBR.lua"


def escape_lua_string(s):
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\r", "\\r")
    s = s.replace("\n", "\\n")
    return s


TYPO_MAP = {
    "\u2019": "'", "\u2018": "'", "\u201a": "'", "`": "'",
    "\u201c": '"', "\u201d": '"', "\u201e": '"',
    "\u2013": "-", "\u2014": "-", "\u2026": "...", "\u00a0": " ",
}


def norm(s):
    # Case-insensitive de proposito: o Turtle tem variantes do mesmo
    # template que diferem so em maiuscula ("fire" vs "Fire"); o PT
    # posicional e identico para elas. Dobra tambem tipograficos do DBC
    # (’ U+2019, — U+2014) para ASCII, senao o match falha.
    t = s or ""
    for a, b in TYPO_MAP.items():
        t = t.replace(a, b)
    return re.sub(r"\s+", " ", t).strip().lower()


def rank_key(rank):
    m = re.search(r"(\d+)", rank or "")
    if m:
        return "grau" + m.group(1)
    if (rank or "").lower().startswith("pass"):
        return "passiva"
    return ""


def ranknum(r):
    m = re.search(r"(\d+)", r or "")
    return int(m.group(1)) if m else 999


# Homonimos confirmados por auditoria: mesmo nome, magias diferentes.
# O ByKey resolve por NOME, entao a entrada do grimorio do jogador vence
# a do pet/monstro Outrora: "attack|" -> 7389 (pet) em vez de 6603 (basico).
BYKEY_OVERRIDES = {
    # nome|grau: id correto
    "attack|": 6603,      # Ataque basico (desc vazia -> EN integro) vence o pet 7389
    "barkskin|": 22812,   # Barkskin druida vence o 20655 (texto de cura alheio)
}


def score(entry):
    d = entry.get("d") or ""
    if d and not d.startswith("Teaches "):
        return 2
    if d:
        return 1
    return 0


def main():
    default_repo = THIS_DIR / "spell_en.json"
    default_temp = pathlib.Path(
        r"C:\Users\rodri\AppData\Local\Temp\opencode\spell_en.json")
    fallback = str(default_repo if default_repo.exists() else default_temp)
    src = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(fallback)
    spells = json.loads(src.read_text(encoding="utf-8"))
    ids = sorted((int(k) for k in spells), key=int)
    with_desc = sum(1 for k in ids if spells[str(k)]["d"])
    print("spells=%d com_desc=%d" % (len(ids), with_desc))

    authoral = {}
    auth_path = THIS_DIR / "spell_pt_authoral.json"
    if auth_path.exists():
        raw_auth = json.loads(auth_path.read_text(encoding="utf-8"))
        authoral = {norm(k): v for k, v in raw_auth.items()}
        print("authoral PT templates: %d" % len(authoral))

    bykey = {}
    for sid in ids:
        e = spells[str(sid)]
        if not e["n"]:
            continue
        key = e["n"].lower() + "|" + rank_key(e["r"])
        if key not in bykey:
            bykey[key] = sid
        else:
            prev = spells[str(bykey[key])]
            if score(e) > score(prev):
                bykey[key] = sid
    # Fallback sem rank ("nome|"): menor rank com descricao real.
    byname_best = {}
    for sid in ids:
        e = spells[str(sid)]
        if not e["n"] or not e["d"] or e["d"].startswith("Teaches "):
            continue
        k = e["n"].lower()
        rn = ranknum(e["r"])
        if k not in byname_best or rn < byname_best[k][0]:
            byname_best[k] = (rn, sid)
    for k, (_, sid) in byname_best.items():
        if k + "|" not in bykey:
            bykey[k + "|"] = sid
    for k, sid in BYKEY_OVERRIDES.items():
        bykey[k] = sid

    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("-- AUTO-GERADO. NAO EDITAR MANUALMENTE (exceto via spell_pt_authoral.json + rebuild).\n")
        fh.write("-- Gerado por tools/build_spelldescdb.py a partir do Spell.dbc do Turtle (EN canonico).\n")
        fh.write("-- Traducao autoral em tools/spell_pt_authoral.json (preservar $). pt vazio = usa EN integro.\n")
        fh.write("ConsoleMode_SpellDescDB = {}\n")
        for sid in ids:
            e = spells[str(sid)]
            if not e["n"]:
                continue
            pt = authoral.get(norm(e["d"]), "")
            fh.write('ConsoleMode_SpellDescDB[%d] = { n="%s", r="%s", d="%s", t="%s", pt="%s" }\n' % (
                sid, escape_lua_string(e["n"]), escape_lua_string(e["r"]),
                escape_lua_string(e["d"]), escape_lua_string(e["t"]), escape_lua_string(pt)))
        fh.write("ConsoleMode_SpellDescDB_ByKey = {}\n")
        for key in sorted(bykey):
            fh.write('ConsoleMode_SpellDescDB_ByKey["%s"] = %d\n' % (escape_lua_string(key), bykey[key]))
    print("escrito %s (%d spells, %d chaves)" % (OUTPUT, len(ids), len(bykey)))


if __name__ == "__main__":
    main()
