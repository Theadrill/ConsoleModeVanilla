#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fase N (Nomes de itens) — CAMADA 0: detector de SUSPEITOS (nunca juiz).

Sinais (uniao; qualquer um enfileira):
  A. divergencia estrutural EN<->PT: contagem de palavras muito diferente,
     numeral romano ausente/divergente, numero arabico divergente.
  B. anomalia mecanica no PT: consoante triplicada, espaco duplo,
     maiuscula apos minuscula no meio da palavra, "cao/coes" sem til,
     "nt " suspeito ("Batida no Chão" x "Trovoada" se resolve no julgamento).
  C. typos conhecidos (lista aberta): glugelo etc.

Saidas:
  tools/nomes_queue.json ............. [{id, en, pt, sinais[]}]
  tools/batches/input_nomes_01..N.json lotes de 100 [{id, en, pt, sinais}]

Loop (julgamento humano, agentes): input -> output_nomes_NN [{id, veredito,
  pt_final, motivo}] -> apply_nomes (só veredito=corrigir) -> luac ->
  ledger PROGRESSO_NOMES.txt -> commit. Amostragem do "limpo" em separado.
Uso: py tools/make_nomes_batches.py
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
WOW_BASE = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns")

ENTRY_RE = re.compile(r"\[(\d+)\]\s*=\s*('(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")", re.DOTALL)
ROMAN = re.compile(r"\b([IVXLCDM]+)\b")
NUM = re.compile(r"\d+")
KNOWN = ["glugelo"]

CONSONANTS = set("bcdfgjklmnpqrstvwxz")


def unescape_lua(s):
    body = s[1:-1]
    return body.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


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


def sinais(i, en, pt):
    s = []
    ew, pw = len(en.split()), len(pt.split())
    if ew >= 3 and (pw * 2 <= ew or ew * 2 <= pw):
        s.append("wordcount:%d->%d" % (ew, pw))
    re_en, re_pt = ROMAN.findall(en), ROMAN.findall(pt)
    if re_en != re_pt:
        s.append("romano:%s->%s" % (re_en, re_pt))
    if sorted(NUM.findall(en)) != sorted(NUM.findall(pt)):
        s.append("numero")
    low = pt.lower()
    if re.search(r"([%s])\1\1" % "".join(sorted(CONSONANTS)), low):
        s.append("consoante-tripla")
    if "  " in pt:
        s.append("espaco-duplo")
    if re.search(r"[a-zà-ÿ][A-Z]", pt):
        s.append("maiuscula-meio")
    if re.search(r"cao\b|coes\b|ao\b", low) and "çã" not in low and "çõ" not in low:
        s.append("sem-til?")
    for k in KNOWN:
        if k in low:
            s.append("conhecido:" + k)
    return s


def main():
    en = load_map(WOW_BASE / "pfQuest" / "db" / "enUS" / "items.lua")
    en.update(load_map(WOW_BASE / "pfQuest-turtle" / "db" / "enUS" / "items-turtle.lua"))
    print("EN carregado:", len(en))
    pt = load_pt_db()
    print("PT carregado:", len(pt))
    queue = []
    for i, p in pt.items():
        e = en.get(i)
        if not e:
            queue.append({"id": i, "en": "", "pt": p, "sinais": ["sem-en"]})
            continue
        sg = sinais(i, e, p)
        if sg:
            queue.append({"id": i, "en": e, "pt": p, "sinais": sg})
    queue.sort(key=lambda x: x["id"])
    print("suspeitos:", len(queue), "de", len(pt))
    (ADDON_DIR / "tools" / "nomes_queue.json").write_text(
        json.dumps(queue, indent=1, ensure_ascii=False), encoding="utf-8")
    chunks = [queue[i:i + 100] for i in range(0, len(queue), 100)]
    for n, ch in enumerate(chunks, 1):
        p = ADDON_DIR / "tools" / "batches" / ("input_nomes_%02d.json" % n)
        p.write_text(json.dumps(
            [{"id": q["id"], "en": q["en"], "pt": q["pt"], "sinais": q["sinais"]} for q in ch],
            indent=1, ensure_ascii=False), encoding="utf-8")
    print("lotes input_nomes_01..%02d" % len(chunks))


if __name__ == "__main__":
    main()
