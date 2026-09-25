#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase N — detecção DETERMINÍSTICA de crosstalk via reverse-lookup de PT.

Crosstalk: PT de item A aparece num ID cujo EN é item B (dados pfQuest
importados com texto pt errado no id errado). Detectamos quando o mesmo
texto PT (normalizado) aparece em 2+ IDs com ENs diferentes: o item
"perdedor" (menor similaridade EN-PT) é crosstalk.

Output: tools/batches/crosstalk_errors.json [{id, en, pt, similar_id, similar_en}]
"""
import json, pathlib, re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
WOW_BASE = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns")
ENTRY_RE = re.compile(r"\[(\d+)\]\s*=\s*('(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")", re.DOTALL)

def unescape_lua(s):
    return s[1:-1].replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")

def load_map(path):
    out = {}
    try:
        src = pathlib.Path(path).read_text(encoding="utf-8")
    except OSError:
        return out
    for m in ENTRY_RE.finditer(src):
        try:
            out[int(m.group(1))] = unescape_lua(m.group(2))
        except ValueError:
            pass
    return out

def load_pt_db():
    out = {}
    src = (ADDON_DIR / "Data" / "ItemDB_ptBR.lua").read_text(encoding="utf-8")
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\"([^\"]*)\"", src):
        out[int(m.group(1))] = m.group(2)
    return out

def norm_pt(s):
    s = s.lower()
    s = re.sub(r"[àáâãäå]", "a", s)
    s = re.sub(r"[èéêë]", "e", s)
    s = re.sub(r"[ìíîï]", "i", s)
    s = re.sub(r"[òóôõö]", "o", s)
    s = re.sub(r"[ùúûü]", "u", s)
    s = re.sub(r"[ç]", "c", s)
    return s.strip()

def word_overlap(en, pt):
    STOP = set("a an the of to and in on for with at by from is this a o e a da de do di das dos duas em para com sem por sobre no na e ou se".split())
    ew = set(w for w in re.findall(r"[a-z]+", en.lower()) if w not in STOP and len(w) > 2)
    pw = set(w for w in re.findall(r"[a-z]+", norm_pt(pt)) if w not in STOP and len(w) > 2)
    return len(ew & pw), len(ew), len(pw)

def main():
    en = load_map(WOW_BASE / "pfQuest" / "db" / "enUS" / "items.lua")
    en.update(load_map(WOW_BASE / "pfQuest-turtle" / "db" / "enUS" / "items-turtle.lua"))
    pt = load_pt_db()
    over = json.loads((ADDON_DIR / "tools" / "nomes_overrides.json").read_text(encoding="utf-8"))
    overrides = set(int(k) for k in over.keys())

    # Group by normalized PT
    pt_groups = {}
    for i, p in pt.items():
        key = norm_pt(p)
        if len(key) < 4:
            continue
        pt_groups.setdefault(key, []).append(i)

    crosstalk = []
    for key, ids in pt_groups.items():
        if len(ids) < 2:
            continue
        # Check if ENs differ (not Monster items with same pt)
        ens = set(en.get(i, "") for i in ids)
        if len(ens) <= 1:
            continue
        # Pick the "winner" = item with lowest EN-PT word overlap
        scored = []
        for i in ids:
            if i in overrides:
                scored.append((i, -1, en.get(i,""), pt[i]))
                continue
            common, ne, npw = word_overlap(en.get(i, ""), pt[i])
            scored.append((i, common, en.get(i, ""), pt[i]))
        scored.sort(key=lambda x: x[1])
        if scored[0][1] < scored[-1][1]:
            loser = scored[0]
            winner = scored[-1]
            crosstalk.append({
                "id": loser[0], "en": loser[2], "pt": loser[3],
                "similar_id": winner[0], "similar_en": winner[2],
                "overlap_loser": loser[1], "overlap_winner": winner[1]
            })
    print("Crosstalk detectados:", len(crosstalk))
    out = ADDON_DIR / "tools" / "batches" / "crosstalk_errors.json"
    out.write_text(json.dumps(crosstalk, indent=1, ensure_ascii=False), encoding="utf-8")
    print("Salvo:", out.name)
    for c in crosstalk[:20]:
        print("  id %d %s -> %s | (winner id %d: %s)" % (
            c["id"], c["en"][:40], c["pt"][:50], c["similar_id"], c["similar_en"][:40]))

if __name__ == "__main__":
    main()
