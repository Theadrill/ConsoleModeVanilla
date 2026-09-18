#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extrai verdade EN de magias (dual layout) e mescla snapshot + patch local.
- Snapshot GitHub (162 campos: ID=0 Name=112 Rank=121 Desc=130 Tip=139)
- Patch local mpq (173 campos vanilla: Name=120 Rank=129 Desc=138 Tip=147)
Patch local vence em conflito de ID; snapshot adiciona IDs ausentes.
Uso: py tools/parse_spell_dbc.py [--snap <dbc>] [--local <dbc>] [--out <json>]
"""
import struct
import sys
import json

LAY162 = {"id": 0, "name": 112, "rank": 121, "desc": 130, "tip": 139}
LAY173 = {"id": 0, "name": 120, "rank": 129, "desc": 138, "tip": 147}


def parse(path, lay):
    data = open(path, "rb").read()
    magic, nrec, nf, rs, ss = struct.unpack("<4sIIII", data[:20])
    assert magic == b"WDBC", path
    nf_exp = 162 if lay is LAY162 else 173
    assert nf == nf_exp, "%s fields=%d" % (path, nf)
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


def opt(flag, default):
    if flag in sys.argv:
        i = sys.argv.index(flag)
        if i + 1 < len(sys.argv):
            return sys.argv[i + 1]
    return default


def main():
    snap_p = opt("--snap", r"C:\Users\rodri\AppData\Local\Temp\opencode\Spell.dbc")
    loc_p = opt("--local", r"C:\Users\rodri\AppData\Local\Temp\opencode\Spell_patch-7_mpq.dbc")
    out = opt("--out", r"C:\Users\rodri\AppData\Local\Temp\opencode\spell_en.json")
    snap = parse(snap_p, LAY162)
    print("snapshot: %d" % len(snap))
    local = parse(loc_p, LAY173)
    print("patch local: %d" % len(local))
    merged = dict(snap)
    overw = sum(1 for k in local if k in merged)
    merged.update(local)
    only_snap = sum(1 for k in snap if k not in local)
    print("merge: total=%d (local venceu %d, so-snapshot=%d)" % (len(merged), overw, only_snap))
    wn = sum(1 for e in merged.values() if e["n"])
    wd = sum(1 for e in merged.values() if e["d"])
    print("with_name=%d with_desc=%d" % (wn, wd))
    json.dump({str(k): v for k, v in merged.items()}, open(out, "w", encoding="utf-8"), ensure_ascii=False)
    print("wrote %s" % out)


if __name__ == "__main__":
    main()
