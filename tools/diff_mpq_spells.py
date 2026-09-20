#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Varredura MPQ por MPQ (Fase 8.C-órfãos): difa Spell.dbc do snapshot + cada
patch (patch_MPQ -> patch-2 -> patch-3 -> patch-5 -> patch-6 -> patch-7),
classifica CUSTOM (ID novo) vs MODIFICADO (mesmo ID, texto mudou) e lista os
órfãos player-facing com descrição sem PT autoral.
Uso: py tools/diff_mpq_spells.py
Saída: tools/mpq_orphans.json + resumo no stdout.
"""
import json
import pathlib
import struct

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")

LAY162 = {"id": 0, "name": 112, "rank": 121, "desc": 130, "tip": 139, "nf": 162}
LAY173 = {"id": 0, "name": 120, "rank": 129, "desc": 138, "tip": 147, "nf": 173}

CHAIN = [
    ("snapshot", TEMP / "Spell.dbc", LAY162),
    ("patch", TEMP / "Spell_patch.dbc", LAY173),
    ("patch-2", TEMP / "Spell_patch-2.dbc", LAY173),
    ("patch-3", TEMP / "Spell_patch-3.dbc", LAY173),
    ("patch-4", TEMP / "Spell_patch-4.dbc", LAY173),
    ("patch-5", TEMP / "Spell_patch-5.dbc", LAY173),
    ("patch-6", TEMP / "Spell_patch-6.dbc", LAY173),
    ("patch-7", TEMP / "Spell_patch-7.dbc", LAY173),
    ("patch-8", TEMP / "Spell_patch-8.dbc", LAY173),
    ("patch-9", TEMP / "Spell_patch-9.dbc", LAY173),
]
# CHAIN completa MPQ-por-MPQ (turtle wow\Data): snapshot + patch..patch-9
# via mpyq(listfile=False) extraidos em 20/09/2026. Patch-A/B..Y nao
# contem Spell.dbc (verificado). Dumps Spell_patch*.dbc no Temp.


def parse(path, lay):
    data = open(path, "rb").read()
    magic, nrec, nf, rs, ss = struct.unpack("<4sIIII", data[:20])
    assert magic == b"WDBC", path
    assert nf == lay["nf"], "%s fields=%d" % (path, nf)
    recs = data[20:20 + nrec * rs]
    sblock = data[20 + nrec * rs:]

    def gs(off):
        if off <= 0 or off >= len(sblock):
            return ""
        end = sblock.find(b"\x00", off)
        return sblock[off:end].decode("utf-8", errors="replace")

    out = {}
    for r in range(nrec):
        vals = struct.unpack("<%di" % nf, recs[r * rs:(r + 1) * rs])
        sid = vals[lay["id"]]
        if sid <= 0:
            continue
        out[sid] = {"n": gs(vals[lay["name"]]), "r": gs(vals[lay["rank"]]),
                    "d": gs(vals[lay["desc"]]), "t": gs(vals[lay["tip"]])}
    return out


def main():
    layers = []
    for label, path, lay in CHAIN:
        if not path.exists():
            print("AUSENTE:", path)
            continue
        m = parse(str(path), lay)
        layers.append((label, m))
        print("%s: %d spells (%d com desc)" % (label, len(m), sum(1 for e in m.values() if e["d"])))

    base_label, base = layers[0]
    base_ids = set(base)
    seen = {}  # sid -> first patch label
    for label, m in layers:
        for sid in m:
            if sid not in seen:
                seen[sid] = label
    final_label, final = layers[-1]

    customs, modified = {}, {}
    for sid, e in final.items():
        if sid not in base_ids:
            customs[sid] = e
        else:
            b = base[sid]
            if (e["n"], e["r"], e["d"]) != (b["n"], b["r"], b["d"]):
                modified[sid] = {"old": b, "new": e}
    print("CUSTOM (IDs novos no %s vs %s): %d" % (final_label, base_label, len(customs)))
    print("MODIFICADOS (mesmo ID, texto mudou): %d" % len(modified))

    auth = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    orphans = []
    for sid, e in customs.items():
        if e["d"] and not auth.get(e["d"], "").strip():
            orphans.append({"id": sid, "kind": "custom", "first": seen[sid],
                            "n": e["n"], "r": e["r"], "d": e["d"]})
    for sid, m in modified.items():
        e = m["new"]
        if e["d"] and not auth.get(e["d"], "").strip():
            orphans.append({"id": sid, "kind": "modified", "first": seen[sid],
                            "n": e["n"], "r": e["r"], "d": e["d"],
                            "old_d": m["old"]["d"]})
    orphans.sort(key=lambda o: o["id"])
    print("ORFAOS com desc SEM PT autoral: %d (custom=%d modified=%d)" % (
        len(orphans), sum(1 for o in orphans if o["kind"] == "custom"),
        sum(1 for o in orphans if o["kind"] == "modified")))
    out = ADDON_DIR / "tools" / "mpq_orphans.json"
    out.write_text(json.dumps(orphans, indent=2, ensure_ascii=False), encoding="utf-8")
    print("escrito %s" % out)


if __name__ == "__main__":
    main()
