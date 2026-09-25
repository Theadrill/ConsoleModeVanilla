#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase N — correção automática de padrões CLAROS e determinísticos.
Varre TODOS os itens não-override e aplica correções onde o padrão for
inconfundível, gerando novos overrides em nomes_overrides.json.

Padrões:
  1. Tabuleta -> Tablete (quando EN tem "tablet")
  2. Residual EN conhecido: palavras EN no PT que deveriam ser PT
     (robe->túnica, vessel->recipiente, etc.)
  3. Encoding corrompido (caractere substituto U+FFFD)
"""
import json, pathlib, re, sys

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
DB = ADDON_DIR / "Data" / "ItemDB_ptBR.lua"
OVERRIDES = ADDON_DIR / "tools" / "nomes_overrides.json"
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

# (en_lower_substring, pt_word_regex, replacement)
RESIDUAL_FIXES = [
    (r"\brobe\b", "robe", "túnica"),
    (r"\bvessel\b", "vessel", "recipiente"),
    (r"\btarge\b", "targe", "escudo"),
    (r"\bshard\b", "shard", ""),  # Fragmento ja esta no PT
]

PATTERN_REPL = [
    (re.compile(r"(?i)\brobes\b"), "robe", "Túnicas"),
    (re.compile(r"(?i)\brobe\b"), "robe", "Túnica"),
    (re.compile(r"(?i)\bvessel\b"), "vessel", "Recipiente"),
    (re.compile(r"(?i)\btarge\b"), "targe", "Broquel"),
    (re.compile(r"(?i)\bmace\b"), "mace", "Malho"),
    (re.compile(r"(?i)\bgavel\b"), "gavel", "Mazo"),
    (re.compile(r"(?i)\borb\b"), "orb", "Orbe"),
]

def main():
    en = load_map(WOW_BASE / "pfQuest" / "db" / "enUS" / "items.lua")
    en.update(load_map(WOW_BASE / "pfQuest-turtle" / "db" / "enUS" / "items-turtle.lua"))
    pt = load_pt_db()
    over = json.loads(OVERRIDES.read_text(encoding="utf-8")) if OVERRIDES.exists() else {}
    corrigidos = set(int(k) for k in over.keys())
    src = DB.read_text(encoding="utf-8")
    n_fix = 0
    for i, p in pt.items():
        if i in corrigidos:
            continue
        e = en.get(i, "")
        if not e:
            continue
        original = p
        low = p.lower()
        enlow = e.lower()
        new_pt = p
        motivo_parts = []
        # 1. Tabuleta -> Tablete
        if "tablet" in enlow and "tabuleta" in low:
            new_pt = re.sub(r"(?i)\btabuleta\b", "Tablete", new_pt)
            motivo_parts.append("tabuleta->tablete")
        # 2. Residual EN no PT -> substitui pelo PT (independente do EN)
        for pat, pt_word, repl in PATTERN_REPL:
            if pat.search(new_pt):
                new_pt = pat.sub(repl, new_pt)
                motivo_parts.append("residual:%s->%s" % (pt_word, repl))
        # 3. Encoding corrompido
        if "\ufffd" in new_pt or "�" in new_pt:
            motivo_parts.append("encoding-corrompido")
        if new_pt != original and motivo_parts:
            over[str(i)] = {"pt": new_pt, "motivo": "; ".join(motivo_parts)}
            pat = re.compile(r"(\[%d\]\s*=\s*\")[^\"]*(\")" % i)
            src = pat.sub(lambda m: m.group(1) + new_pt + m.group(2), src, count=1)
            n_fix += 1
    if n_fix == 0:
        print("Nenhuma correcao automatica aplicada.")
        return
    DB.write_text(src, encoding="utf-8")
    OVERRIDES.write_text(json.dumps(over, indent=1, ensure_ascii=False), encoding="utf-8")
    print("OK: %d correcoes automaticas, overrides=%d" % (n_fix, len(over)))

if __name__ == "__main__":
    main()
