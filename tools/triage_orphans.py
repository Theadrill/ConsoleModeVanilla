#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Triagem dos órfãos MPQ: separa player-facing (Rank ou nome conhecido em
Spells.lua) da cauda de monstros/NPCs. Gera tools/mpq_orphans_player.json.
Uso: py tools/triage_orphans.py
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent


def main():
    orphans = json.loads((ADDON_DIR / "tools" / "mpq_orphans.json").read_text(encoding="utf-8"))
    print("orfãos totais:", len(orphans))
    print("Totemic Recall 45513:", [o for o in orphans if o["id"] == 45513])

    loc = (ADDON_DIR / "Data" / "Locales" / "ptBR" / "Spells.lua").read_text(encoding="utf-8")
    known = set(re.findall(r'\["([^"]+)"\]', loc))
    known_low = set(k.lower() for k in known)

    player, tail = [], []
    for o in orphans:
        is_player = ("Rank" in o.get("r", "")) or (o["n"] in known) or (o["n"].lower() in known_low)
        (player if is_player else tail).append(o)
    print("player-facing (rank ou nome conhecido):", len(player))
    print("cauda monstros/NPC:", len(tail))
    for o in player[:20]:
        print(" ", o["id"], o["kind"], repr(o["n"]), repr(o["r"]), repr(o["d"][:80]))
    out = ADDON_DIR / "tools" / "mpq_orphans_player.json"
    out.write_text(json.dumps(player, indent=2, ensure_ascii=False), encoding="utf-8")
    print("escrito %s" % out)

    # Segunda passada: customs/modificadas COM PT autoral mas suspeito (curto demais).
    import struct as _st

    def _parse(path, lay):
        data = open(path, "rb").read()
        _magic, _nrec, _nf, _rs, _ss = _st.unpack("<4sIIII", data[:20])
        _recs = data[20:20 + _nrec * _rs]
        _sb = data[20 + _nrec * _rs:]

        def _gs(off):
            if off <= 0 or off >= len(_sb):
                return ""
            _end = _sb.find(b"\x00", off)
            return _sb[off:_end].decode("utf-8", errors="replace")

        _out = {}
        for _r in range(_nrec):
            _vals = _st.unpack("<%di" % _nf, _recs[_r * _rs:(_r + 1) * _rs])
            _sid = _vals[lay["id"]]
            if _sid <= 0:
                continue
            _out[_sid] = {"n": _gs(_vals[lay["name"]]), "r": _gs(_vals[lay["rank"]]),
                          "d": _gs(_vals[lay["desc"]])}
        return _out

    _snap = _parse(str(pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\Spell.dbc")),
                   {"id": 0, "name": 112, "rank": 121, "desc": 130})
    _p7 = _parse(str(pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode\Spell_patch-7_mpq.dbc")),
                 {"id": 0, "name": 120, "rank": 129, "desc": 138})
    _auth = json.loads((ADDON_DIR / "tools" / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    _sus = []
    for _sid, _e in _p7.items():
        if not _e["d"]:
            continue
        _is_custom = _sid not in _snap
        _is_mod = (not _is_custom) and ((_e["n"], _e["r"], _e["d"]) !=
                                        (_snap[_sid]["n"], _snap[_sid]["r"], _snap[_sid]["d"]))
        if not (_is_custom or _is_mod):
            continue
        _pt = _auth.get(_e["d"], "")
        if _pt.strip() and len(_pt) < 60:
            _sus.append({"id": _sid, "kind": "custom" if _is_custom else "modified",
                         "n": _e["n"], "r": _e["r"], "d": _e["d"], "pt": _pt})
    _sus.sort(key=lambda o: o["id"])
    print("SUSPEITOS (custom/mod com PT curto <60):", len(_sus))
    for _o in _sus[:25]:
        print(" ", _o["id"], _o["kind"], repr(_o["n"]), "=>", repr(_o["pt"]))
    _out2 = ADDON_DIR / "tools" / "mpq_suspects.json"
    _out2.write_text(json.dumps(_sus, indent=2, ensure_ascii=False), encoding="utf-8")
    print("escrito %s" % _out2)


if __name__ == "__main__":
    main()
