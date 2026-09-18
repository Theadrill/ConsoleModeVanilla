#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ordena os templates de classe por impacto (frequência de uso no client)
e gera lotes estruturados em JSON para tradução humana com mapeamento exato {EN: PT}.
"""
import json
import pathlib

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

def main():
    templates = json.loads((ADDON_DIR / "tools" / "player_class_templates.json").read_text(encoding="utf-8"))
    # Ordenar por count decrescente (mais usados no client primeiro)
    templates.sort(key=lambda t: -t["count"])

    print(f"Total de templates de classe: {len(templates)}")
    print(f"Exemplo do top 10 mais frequentes:")
    for i, t in enumerate(templates[:10], 1):
        print(f"[{i}] ({t['count']}x) {t['sample_spells'][0]}: {t['template_en'][:70]}...")

    # Salva os templates ordenados por impacto
    (ADDON_DIR / "tools" / "player_class_ranked.json").write_text(
        json.dumps(templates, indent=2, ensure_ascii=False), encoding="utf-8")

if __name__ == "__main__":
    main()
