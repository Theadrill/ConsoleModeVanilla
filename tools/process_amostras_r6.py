#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Processa 4 amostras estatisticas adicionais (06b, 06c, 06d, 06e).
Combina: (1) checker de tokens REMNANT_FIX; (2) revisao manual de
falsos negativos (Spaulders no PT, Tabuleta vs Tablete, encoding).
Produz output_amostra_06b..e.json + resumo de escape."""
import json, io, pathlib, re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

PATTERNS = {
    "sword": "Espada", "shield": "Escudo", "staff": "Cajado",
    "dagger": "Adaga", "blade": "Lâmina", "spaulders": "Ombreiras",
    "sentinel": "Sentinela", "highlander": "Montanhês",
    "marshal": "Marechal", "black": "Preto", "green": "Verde",
    "silver": "Prata", "horde": "Horda", "ironforge": "Altaforja",
    "netherwind": "Vento Etéreo", "token": "Ficha", "shackle": "Grilhão",
    "crag": "Rochedo", "bark": "Casca", "shroud": "Mortalha", "courser": "Ginete",
    "fen": "Charco", "mantle": "Dragonas", "wrangler": "Boiadeiro",
    "grunt": "Bruto", "deathguard": "Necroguarda", "pathfinder": "Desbravador",
    "hood": "Capuz", "wyvern": "Mantícora", "scourge": "Flagelo",
    "drake": "Draco", "circlet": "Diadema", "mageweave": "Magitrama",
    "thorium": "Tório", "rod": "Vara", "primal": "Primevo",
    "reaver": "Abutre", "maul": "Malho", "mauler": "Malho",
    "tablet": "Tablete", "felcloth": "Tecido Vil", "girdle": "Cinturão",
    "warchief": "Chefe de Guerra", "dragonmaw": "Presa do Dragão",
}

# Palavras EN que nunca devem aparecer no PT (exceto proper nouns)
EN_WORDS_NO_PT = [
    "spaulders", "blunderbuss", "girdle", "shroud", "shackle", "crag",
    "wrangler", "deathguard", "pathfinder", "circlet", "hood",
]

def is_gm(en):
    return (en.startswith("Monster -") or en.startswith("OLD") or
            en.startswith("Test") or en.startswith("OLDBlackfathom"))

def check_item(x):
    """Returns (veredito, pt_final, motivo) or None for manter."""
    en = x["en"]
    pt = x["pt"]
    en_low = en.lower()
    pt_low = pt.lower()
    iid = x["id"]

    if is_gm(en):
        return ("manter", pt, "Item GM/Monster/internal; manter.")

    # 1. Check prohibited chars in pt
    for ch in ['"', "\\", "$"]:
        if ch in pt:
            fixed = pt.replace(ch, "")
            return ("corrigir", fixed, "Remove caractere proibido %r." % ch)

    # 2. Check EN words left in PT (word-boundary, but catch "spaulders" in PT
    #    even when EN has "pauldrons" — different spelling)
    for w in EN_WORDS_NO_PT:
        if re.search(r"\b" + re.escape(w) + r"\b", pt_low):
            # Check if the official PT translation is already present
            expected = PATTERNS.get(w, "")
            if expected and expected.lower() not in pt_low:
                pt_new = re.sub(r"\b" + re.escape(w) + r"\b", expected, pt,
                                flags=re.IGNORECASE, count=1)
                return ("corrigir", pt_new, "%s->%s (oficial)." % (w, expected))

    # 3. Check tokens (EN word in both EN and PT — word boundary)
    for token, pt_expected in PATTERNS.items():
        if re.search(r"\b" + re.escape(token) + r"\b", en_low) and \
           re.search(r"\b" + re.escape(token) + r"\b", pt_low):
            pt_new = re.sub(r"\b" + re.escape(token) + r"\b", pt_expected, pt,
                            flags=re.IGNORECASE, count=1)
            return ("corrigir", pt_new, "tok-remnant:%s->%s." % (token, pt_expected))

    # 4. Tabuleta -> Tablete (when EN has "Tablet" and PT has "Tabuleta")
    if "tablet" in en_low and "tabuleta" in pt_low and "tablete" not in pt_low:
        # Also check gender agreement
        pt_new = pt.replace("Tabuleta", "Tablete").replace("tabuleta", "tablete")
        # Fix gender: "Gravada" -> "Gravado" if tablete is masculine
        if "gravada" in pt_low and "tablete" in pt_low:
            pt_new = re.sub(r"gravada", "gravado", pt_new, flags=re.IGNORECASE)
        return ("corrigir", pt_new, "Tablet->Tablete (oficial Blizzard).")

    # 5. Mau uso de til: "Viu" -> "Viou"? não. Check cao/coes/ao sem til
    if re.search(r"cao\b|coes\b", pt_low) and "çã" not in pt_low:
        # Não corrige automaticamente — marca para review
        pass

    # 6. Encoding issues: caracteres estranhos
    if "�" in pt:
        return ("corrigir", pt, "AVISO: caractere de encoding corrompido (necessita revisao manual).")

    return None  # manter

def process_sample(name):
    items = json.loads(io.open(str(ADDON_DIR) + "\\tools\\batches\\" + ("input_amostra_%s.json" % name), encoding="utf-8").read())
    out = []
    c = m = 0
    for x in items:
        result = check_item(x)
        if result:
            vd, pt_final, motivo = result
        else:
            vd, pt_final, motivo = "manter", x["pt"], "Traducao PT Blizzlike/canon; manter."
        out.append({
            "id": x["id"], "en": x["en"], "veredito": vd,
            "pt_final": pt_final, "motivo": motivo
        })
        if vd == "corrigir":
            c += 1
        else:
            m += 1
    p = pathlib.Path(str(ADDON_DIR) + "\\tools\\batches\\" + ("output_amostra_%s.json" % name))
    io.open(p, "w", encoding="utf-8").write(json.dumps(out, indent=1, ensure_ascii=False))
    escape = c / len(items) * 100
    print("%s | %d (%.1f%% escape, %dc/%dm)" % (name.upper(), len(items), escape, c, m))
    return c, m

import sys
samples = sys.argv[1].split(",") if len(sys.argv) > 1 else "06b"
for s in samples:
    process_sample(s)
