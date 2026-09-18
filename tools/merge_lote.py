"""Merge a prova de erro: le o EN exato do loteN.txt, casa com ptN.txt por ordem.
Uso: py tools/merge_lote.py 11
- lote11.txt em Temp; pt11.txt em Temp (200 linhas, SKIP = pular).
- Chave armazenada = EN com whitespace colapsado (build faz match por norm).
- Reporta adicionados / ja-tinham (norm-dupe) / skips.
"""
import json
import pathlib
import re
import sys

THIS_DIR = pathlib.Path(__file__).resolve().parent
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")


def norm(s):
    t = s or ""
    for a, b in {"\u2019": "'", "\u2018": "'", "\u201a": "'",
                 "\u201c": '"', "\u201d": '"',
                 "\u2013": "-", "\u2014": "-", "\u2026": "...",
                 "\u00a0": " "}.items():
        t = t.replace(a, b)
    return re.sub(r"\s+", " ", t).strip().lower()


def parse_lote(text):
    chunks = re.split(r"(?m)^### \[\d+\]", text)
    entries = []
    for ch in chunks[1:]:
        m = re.search(r"EN:(.*?)\nPT:", ch, re.S)
        if not m:
            continue
        en = re.sub(r"\s+", " ", m.group(1)).strip()
        entries.append(en)
    return entries


def main():
    n = sys.argv[1]
    lote = (TEMP / ("lote%s.txt" % n)).read_text(encoding="utf-8")
    pts = (TEMP / ("pt%s.txt" % n)).read_text(encoding="utf-8").splitlines()
    ens = parse_lote(lote)
    print("lote%s: %d EN x %d PT" % (n, len(ens), len(pts)))
    assert len(ens) == len(pts), "contagem EN != PT"
    auth_path = THIS_DIR / "spell_pt_authoral.json"
    d = json.loads(auth_path.read_text(encoding="utf-8"))
    have = {norm(k) for k in d}
    added, dup, skip = 0, 0, 0
    for en, pt in zip(ens, pts):
        pt = pt.strip()
        if pt == "SKIP":
            skip += 1
            continue
        if norm(en) in have:
            dup += 1
            print("  JA-TINHA: %.70s" % en)
            continue
        d[en] = pt
        have.add(norm(en))
        added += 1
    auth_path.write_text(json.dumps(d, ensure_ascii=False), encoding="utf-8")
    print("add=%d dup=%d skip=%d total=%d" % (added, dup, skip, len(d)))


if __name__ == "__main__":
    main()
