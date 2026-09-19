#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Auditoria do PT EFETIVO (pos-norm, igual ao build): lista templates cujo PT
vencedor ainda parece SMS. Saida: tools/effective_sms.json
Uso: py tools/audit_effective_sms.py
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent


def norm(s):
    return re.sub(r"\s+", " ", s or "").strip().lower()


SMS_RES = [
    r"\bTotem \d+ por",
    r"\bPet \+\d",
    r"\bArma( com|:)",
    r"\bTutela:",
    r"Lenta bate mais",
    r"\bpra\b",
    r"\bnv\b",
    r"\+\$\w+ (ameaça|dano|vida|mana|poder)",
    r"^[^ ]+: \+",
    r"\bDano .* e atordoa\b",
]


def looks_sms(en, pt):
    if not pt.strip():
        return False
    for pat in SMS_RES:
        if re.search(pat, pt):
            return True
    # muito curto em relacao ao EN (menos de 45% dos chars, EN com 2+ frases)
    if len(pt) < 0.45 * len(en) and len(en) > 60:
        return True
    return False


def main():
    raw = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    eff = {}
    for k, v in raw.items():
        eff[norm(k)] = (k, v)  # ultimo vence, igual ao build
    print("raw keys:", len(raw), "| efetivos:", len(eff))
    ranked = json.loads((ADDON_DIR / "tools" / "player_class_ranked.json").read_text(encoding="utf-8"))
    ranked_norms = set(norm(x["template_en"]) for x in ranked)
    other = json.loads((ADDON_DIR / "tools" / "player_other_templates.json").read_text(encoding="utf-8"))
    other_norms = set(norm(x["template_en"]) for x in other)
    work = json.loads((ADDON_DIR / "tools" / "mpq_work.json").read_text(encoding="utf-8"))
    work_norms = set(norm(o["d"]) for o in work)
    flagged = []
    for nk, (rawk, pt) in eff.items():
        if not looks_sms(rawk, pt):
            continue
        scope = "ranked" if nk in ranked_norms else ("other" if nk in other_norms else ("orphan" if nk in work_norms else "tail"))
        flagged.append({"en": rawk, "pt": pt, "scope": scope})
    print("flagged:", len(flagged))
    byscope = {}
    for f in flagged:
        byscope[f["scope"]] = byscope.get(f["scope"], 0) + 1
    print("por escopo:", byscope)
    out = ADDON_DIR / "tools" / "effective_sms.json"
    out.write_text(json.dumps(flagged, indent=2, ensure_ascii=False), encoding="utf-8")
    print("escrito %s" % out)
    for f in flagged[:30]:
        print("[%s] %r => %r" % (f["scope"], f["en"][:75], f["pt"][:75]))


if __name__ == "__main__":
    main()
