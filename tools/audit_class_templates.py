#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Verifica o estado atual dos 2180 templates de classe em spell_pt_authoral.json.
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

TYPO_MAP = {
    "\u2019": "'", "\u2018": "'", "\u201a": "'", "`": "'",
    "\u201c": '"', "\u201d": '"', "\u201e": '"',
    "\u2013": "-", "\u2014": "-", "\u2026": "...", "\u00a0": " ",
}

def norm(s):
    t = s or ""
    for a, b in TYPO_MAP.items():
        t = t.replace(a, b)
    return re.sub(r"\s+", " ", t).strip().lower()

def is_telegraphic(pt):
    if not pt:
        return False
    # Padrões telegráficos flagrados
    bad_patterns = [
        r": \+",
        r"Lenta bate mais",
        r"pra beber",
        r"pra comer",
        r"Some se deslogar",
        r"Pet \+",
        r"Totem \d+ por",
        r"Arma:",
        r"Arma com fogo:",
        r"\+.*poder e",
        r"s; lentidão",
        r"Sem acumular",
        r"Só nv \d+",
        r"Perna/cabeça",
        r"Peito:",
        r"Manto:",
    ]
    return any(re.search(p, pt, re.IGNORECASE) for p in bad_patterns)

def main():
    templates = json.loads((ADDON_DIR / "tools" / "player_class_templates.json").read_text(encoding="utf-8"))
    auth = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    norm_auth = {norm(k): v for k, v in auth.items()}

    total = len(templates)
    has_pt = 0
    telegraphic = 0
    empty_or_missing = 0

    items_to_fix = []

    for t in templates:
        en = t["template_en"]
        n_en = norm(en)
        pt = norm_auth.get(n_en, "")
        if pt:
            has_pt += 1
            if is_telegraphic(pt):
                telegraphic += 1
                items_to_fix.append({"template_en": en, "current_pt": pt, "reason": "telegraphic", "samples": t["sample_spells"]})
        else:
            empty_or_missing += 1
            items_to_fix.append({"template_en": en, "current_pt": "", "reason": "missing", "samples": t["sample_spells"]})

    print(f"Total templates de classe: {total}")
    print(f"Com PT: {has_pt} (sendo {telegraphic} claramente telegráficos detectados)")
    print(f"Sem PT ou vazios: {empty_or_missing}")
    print(f"Total prioritário imediato para retradução: {len(items_to_fix)}")

    (ADDON_DIR / "tools" / "class_templates_audit.json").write_text(
        json.dumps(items_to_fix, indent=2, ensure_ascii=False), encoding="utf-8")

if __name__ == "__main__":
    main()
