#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Valida output_itemdesc_NN.json {EN: PT} (flavor/lore, sem $ em geral).
Falhas: PT vazio, PT==EN, contagem de $ diferente, multiset de numeros diferente,
        colisao de norm com PTs distintos no mesmo arquivo.
Avisos (nao falham): PT < 40% das palavras do EN (possivel SMS), PT vazio p/ EN curto.
Uso: py tools/validate_itemflavor.py <output.json>  (exit 1 se falha)
"""
import json
import pathlib
import re
import sys


def norm(s):
    return re.sub(r"\s+", " ", s or "").strip().lower()


def numbers(s):
    return sorted(re.findall(r"\d+(?:\.\d+)?", s or ""))


def dollars(s):
    return len(re.findall(r"\$[a-zA-Z]\d*", s or ""))


def validate_dict(pairs):
    errors, warns = [], []
    seen_norm = {}
    for en, pt in pairs.items():
        tag = repr(en[:60])
        if not pt or not pt.strip():
            errors.append(f"VAZIO: {tag}")
            continue
        if pt == en:
            # Excecao: fragmento de nome proprio (assinatura "-Feralas", ".")
            # ate 3 palavras, todas capitalizadas/pontuacao -> so avisa.
            frag = en.strip()
            if len(frag.split()) <= 3 and (
                    re.fullmatch(r"[.\-]+", frag) or re.fullmatch(
                    r"[.\-]?[A-ZÀ-Ý][\w'’\-.]*(\s+[A-ZÀ-Ý][\w'’\-.]*)*[.\-]?", frag)):
                warns.append(f"NOME-PROPRIO mantido: {tag}")
                continue
            errors.append(f"IGUAL: {tag}")
            continue
        if dollars(en) != dollars(pt):
            errors.append(f"CIFRAO: EN={dollars(en)} PT={dollars(pt)} {tag}")
        if numbers(en) != numbers(pt):
            errors.append(f"NUMEROS: {numbers(en)} vs {numbers(pt)} {tag}")
        k = norm(en)
        if k in seen_norm and seen_norm[k] != pt:
            errors.append(f"COLISAO norm, PTs distintos: {tag}")
        seen_norm[k] = pt
        ew, pw = len(en.split()), len(pt.split())
        if ew > 4 and pw < 0.4 * ew:
            warns.append(f"SMS? {ew}->{pw} palavras: {tag}")
    return errors, warns


def main():
    p = pathlib.Path(sys.argv[1])
    pairs = json.loads(p.read_text(encoding="utf-8"))
    if isinstance(pairs, list):  # tolera [{"en","pt"}]
        pairs = {it.get("en", it.get("template_en")): it.get("pt", it.get("pt_natural")) for it in pairs}
    errors, warns = validate_dict(pairs)
    print(f"{p.name}: pares={len(pairs)} erros={len(errors)} avisos={len(warns)}")
    for w in warns[:8]:
        print("  AVISO", w)
    for e in errors[:15]:
        print("  ERRO", e)
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
