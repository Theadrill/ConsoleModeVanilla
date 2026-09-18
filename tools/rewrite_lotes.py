"""Lotes de RETRADUCAO Blizzlike: ordena templates por impacto (n descs),
gera rw<N>_en.txt; aplica rw<N>_pt.txt por norm.
Uso: py tools/rewrite_lotes.py --plan      (gera plano + rw1_en.txt)
     py tools/rewrite_lotes.py --apply 1    (aplica rw1_pt.txt)
"""
import json
import pathlib
import re
import sys

THIS_DIR = pathlib.Path(__file__).resolve().parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")
BATCH = 200


def norm(s):
    t = s or ""
    for a, b in {"\u2019": "'", "\u2018": "'", "\u201a": "'",
                 "\u201c": '"', "\u201d": '"',
                 "\u2013": "-", "\u2014": "-", "\u2026": "...",
                 "\u00a0": " "}.items():
        t = t.replace(a, b)
    return re.sub(r"\s+", " ", t).strip().lower()


def load():
    spells = json.loads((TEMP / "spell_en.json").read_text(encoding="utf-8"))
    auth = json.loads((THIS_DIR / "spell_pt_authoral.json").read_text(encoding="utf-8"))
    return spells, auth


def plan():
    spells, auth = load()
    impact = {}
    for sid, e in spells.items():
        if e.get("d"):
            k = norm(e["d"])
            impact[k] = impact.get(k, 0) + 1
    items = [(impact.get(norm(k), 0), k) for k, v in auth.items() if v]
    items.sort(key=lambda t: -t[0])
    (TEMP / "rewrite_order.json").write_text(
        json.dumps([k for _, k in items], ensure_ascii=False), encoding="utf-8")
    print("templates com PT: %d" % len(items))
    nb = (len(items) + BATCH - 1) // BATCH
    print("lotes de %d: %d" % (BATCH, nb))
    dump(1, items)


def dump(n, items=None):
    if items is None:
        order = json.loads((TEMP / "rewrite_order.json").read_text(encoding="utf-8"))
    else:
        order = [k for _, k in items]
    batch = order[(n - 1) * BATCH:n * BATCH]
    with open(TEMP / ("rw%d_en.txt" % n), "w", encoding="utf-8") as fh:
        for i, en in enumerate(batch, 1):
            fh.write("### [%d]\nEN: %s\n\n" % (i, en))
    print("rw%d_en.txt: %d entradas" % (n, len(batch)))


def apply(n):
    spells, auth = load()
    order = json.loads((TEMP / "rewrite_order.json").read_text(encoding="utf-8"))
    batch = order[(n - 1) * BATCH:n * BATCH]
    pts = (TEMP / ("rw%d_pt.txt" % n)).read_text(encoding="utf-8").splitlines()
    assert len(batch) == len(pts), "EN %d != PT %d" % (len(batch), len(pts))
    have = {norm(k): k for k in auth}
    upd, skip = 0, 0
    for en, pt in zip(batch, pts):
        pt = pt.strip()
        if pt == "SKIP":
            skip += 1
            continue
        auth[have[norm(en)]] = pt
        upd += 1
    (THIS_DIR / "spell_pt_authoral.json").write_text(
        json.dumps(auth, ensure_ascii=False), encoding="utf-8")
    print("rw%d: upd=%d skip=%d" % (n, upd, skip))
    if n * BATCH < len(order):
        dump(n + 1)


if __name__ == "__main__":
    if sys.argv[1] == "--plan":
        plan()
    elif sys.argv[1] == "--apply":
        apply(int(sys.argv[2]))
    elif sys.argv[1] == "--dump":
        dump(int(sys.argv[2]))
