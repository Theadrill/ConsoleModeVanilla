#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Revisao final de 4 amostras adicionais + AMOSTRA-06.
Re-verifica falsos negativos: (1) palavras EN no PT; (2) Tabuleta->Tablete;
(3) concordancia de genero; (4) encoding corrompido."""
import json, io, pathlib, re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
BATCHES = ["amostra_10"]

EN_WORDS_IN_PT = [
    "spaulders", "blunderbuss", "girdle", "shrouds", "shroud",
    "shackle", "crag", "wrangler", "deathguard", "pathfinder",
    "circlet", "hood", "wyvern", "scourge", "warchief",
    "reaver", "mauler", "maul", "tablet", "felcloth", "primal",
    "sword", "shield", "staff", "dagger", "blade", "sabaton",
    "offhand", "mara", "gloves", "boots", "bracers",
]

def is_gm(en):
    return (en.startswith("Monster -") or en.startswith("OLD") or
            en.startswith("Test") or en.startswith("OLDBlackfathom"))

for suffix in BATCHES:
    p = str(ADDON_DIR) + "\\tools\\batches\\input_" + suffix + ".json"
    try:
        items = json.loads(io.open(p, encoding="utf-8").read())
    except FileNotFoundError:
        print("%s: arquivo nao encontrado" % suffix)
        continue
    
    flags = []
    for x in items:
        en = x["en"]
        pt = x["pt"]
        en_low = en.lower()
        pt_low = pt.lower()

        if is_gm(en):
            continue

        item_flags = []

        # (1) EN words in PT
        for w in EN_WORDS_IN_PT:
            if re.search(r"\b" + re.escape(w) + r"\b", pt_low) and w not in en_low:
                # EN word in PT but not in EN — suspicious
                item_flags.append("EN-no-PT:%s" % w)

        # (2) Tabuleta vs Tablete
        if "tabuleta" in pt_low and "tablet" in en_low:
            if "tablete" not in pt_low:
                item_flags.append("Tabuleta->Tablete")

        # (3) Encoding issues
        if "\ufffd" in pt or "�" in pt:
            item_flags.append("ENCODING-CORROMPIDO")

        # (4) Gender: "Tablete Antiga" -> "Tablete Antigo"
        if "tablete" in pt_low and "antiga" in pt_low:
            item_flags.append("genero:Antiga->Antigo")

        # (5) "Spaulders" in PT when EN has "pauldrons" or "shoulder"
        if "spaulders" in pt_low and ("pauldr" in en_low or "shoulder" in en_low):
            expected_pt = "ombreiras" if "pauldr" in en_low else "ombereiras"
            item_flags.append("Spaulders->%s" % expected_pt)

        if item_flags:
            flags.append((x["id"], en, pt, item_flags))

    print("\n=== %s: %d/%d flagados ===" % (suffix.upper(), len(flags), len(items)))
    for iid, en, pt, f in flags:
        print("  id=%d: %s -> %s | %s" % (iid, en[:40], pt[:50], ", ".join(f)))
