#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Monta a fila final de órfãos Turtle player-facing (Fase 8.C-órfãos):
A) 238 sem PT (mpq_orphans_player.json)
B) customs/modificadas COM PT (revisão humana: manter ou reescrever)
Filtro player-facing: Rank no grau OU nome em Spells.lua.
Saída: tools/mpq_queue.json
"""
import json
import pathlib
import re
import struct

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")


def parse(path, lay):
    data = open(path, "rb").read()
    magic, nrec, nf, rs, ss = struct.unpack("<4sIIII", data[:20])
    assert magic == b"WDBC" and nf == lay["nf"], path
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
                    "d": gs(vals[lay["desc"]])}
    return out


def main():
    snap = parse(str(TEMP / "Spell.dbc"), {"id": 0, "name": 112, "rank": 121, "desc": 130, "nf": 162})
    # Final e o ultimo patch com Spell.dbc (patch-9 para varredura completa)
    final_path = TEMP / "Spell_patch-9.dbc"
    if not final_path.exists():
        final_path = TEMP / "Spell_patch-7.dbc"
        if not final_path.exists():
            final_path = TEMP / "Spell_patch-7_mpq.dbc"
    p7 = parse(str(final_path), {"id": 0, "name": 120, "rank": 129, "desc": 138, "nf": 173})
    auth = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    loc = (ADDON_DIR / "Data" / "Locales" / "ptBR" / "Spells.lua").read_text(encoding="utf-8")
    known = set(re.findall(r'\["([^"]+)"\]', loc))
    known_low = set(k.lower() for k in known)

    def is_player(e):
        return ("Rank" in e.get("r", "")) or (e["n"] in known) or (e["n"].lower() in known_low)

    queue = []
    for sid, e in p7.items():
        if not e["d"]:
            continue
        is_custom = sid not in snap
        is_mod = (not is_custom) and ((e["n"], e["r"], e["d"]) !=
                                      (snap[sid]["n"], snap[sid]["r"], snap[sid]["d"]))
        if not (is_custom or is_mod) or not is_player(e):
            continue
        pt = auth.get(e["d"], "")
        queue.append({"id": sid, "kind": "custom" if is_custom else "modified",
                      "n": e["n"], "r": e["r"], "d": e["d"],
                      "curr_pt": pt, "need": "new" if not pt.strip() else "review"})
    queue.sort(key=lambda o: o["id"])
    new_n = sum(1 for o in queue if o["need"] == "new")
    rev_n = sum(1 for o in queue if o["need"] == "review")
    print("fila player-facing Turtle: %d (novos=%d, revisar=%d)" % (len(queue), new_n, rev_n))
    print("Totemic Recall:", [o for o in queue if o["id"] == 45513])
    out = ADDON_DIR / "tools" / "mpq_queue.json"
    out.write_text(json.dumps(queue, indent=2, ensure_ascii=False), encoding="utf-8")
    print("escrito %s" % out)


if __name__ == "__main__":
    main()
