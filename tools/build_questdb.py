#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera Data/QuestDB_ptBR.lua a partir de pfQuest e pfQuest-turtle ptBR + enUS.
- pfQuest/db/ptBR/quests.lua              -> pfDB['quests']['ptBR']
- pfQuest-turtle/db/ptBR/quests-turtle.lua -> pfDB['quests']['ptBR-turtle']
- pfQuest/db/enUS/quests.lua              -> pfDB['quests']['enUS']      (para lookup por titulo ingles)
- pfQuest-turtle/db/enUS/quests-turtle.lua -> pfDB['quests']['enUS-turtle']
Turtle tem prioridade (sobrescreve vanilla se conflito).
Placeholders "_" sao ignorados.
Saida: Data/QuestDB_ptBR.lua com ConsoleMode_QuestDB = { [id] = { T=..., D=..., O=... } }
       e ConsoleMode_QuestDB_ByTitle = { ["English Title"] = id } para autonomia 100% sem pfQuest.
"""
import pathlib
import re
import os

# Paths relative to this script
THIS_DIR = pathlib.Path(__file__).resolve().parent
ADDON_DIR = THIS_DIR.parent  # ConsoleModeVanilla
VANILLA_PATH = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns\pfQuest\db\ptBR\quests.lua")
TURTLE_PATH = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns\pfQuest-turtle\db\ptBR\quests-turtle.lua")
VANILLA_EN_PATH = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns\pfQuest\db\enUS\quests.lua")
TURTLE_EN_PATH = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Interface\AddOns\pfQuest-turtle\db\enUS\quests-turtle.lua")
OUTPUT_PATH = ADDON_DIR / "Data" / "QuestDB_ptBR.lua"

def escape_lua_string(s):
    # Escape para literal Lua com aspas duplas
    # Ordem: \ -> \\, " -> \", \n -> \n, \r -> \r
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\r", "\\r")
    s = s.replace("\n", "\\n")
    return s

def parse_quests_file(path):
    text = pathlib.Path(path).read_text(encoding="utf-8", errors="strict")
    quests = {}
    placeholders = 0

    # Conta placeholders
    placeholders = len(re.findall(r'\[\d+\]\s*=\s*"_"', text))

    # Encontra todos os blocos [id] = { ... }
    # Usa abordagem de varredura manual para lidar com aspas escapadas
    # Regex para inicio de bloco
    pattern_start = re.compile(r'\[(\d+)\]\s*=\s*\{')
    pos = 0
    text_len = len(text)
    while True:
        m = pattern_start.search(text, pos)
        if not m:
            break
        qid = int(m.group(1))
        brace_start = m.end() - 1  # pos of {
        # Encontra fechamento correspondente do bloco da quest
        # Como o bloco so tem 1 nivel de chaves e valores sao strings com aspas, podemos buscar
        # ate encontrar "}," no nivel 1.
        # Scan character por character respeitando strings
        depth = 0
        i = brace_start
        in_string = False
        escape = False
        block_end = -1
        while i < text_len:
            ch = text[i]
            if in_string:
                if escape:
                    escape = False
                elif ch == "\\":
                    escape = True
                elif ch == '"':
                    in_string = False
            else:
                if ch == '"':
                    in_string = True
                elif ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        block_end = i
                        break
            i += 1
        if block_end == -1:
            pos = m.end()
            continue
        block = text[brace_start:block_end+1]  # inclui { ... }

        # Extrai campos T, D, O dentro do bloco (ordem qualquer)
        # Cada campo: ["T"] = "valor"  (valor pode conter \" escapado)
        def extract_field(name):
            # pattern: ["NAME"] = "((?:\\.|[^"\\])* )"
            pat = re.compile(r'\["' + re.escape(name) + r'"\]\s*=\s*"((?:\\.|[^"\\])*)"', re.DOTALL)
            fm = pat.search(block)
            if fm:
                raw = fm.group(1)
                # Desescapa \" e \\ para obter string real, depois re-escaparemos ao gerar
                tmp = raw.replace(r"\\", "\x00")
                tmp = tmp.replace(r'\"', '"')
                tmp = tmp.replace(r"\'", "'")
                tmp = tmp.replace("\x00", "\\")
                return tmp
            return None

        t = extract_field("T")
        d = extract_field("D")
        o = extract_field("O")

        # Se nao tiver T, ignora (entrada invalida)
        if t is not None:
            quests[qid] = {"T": t, "D": d if d is not None else "", "O": o if o is not None else ""}
        # else: pode ser entrada vazia, ignora

        pos = block_end + 1

    return quests, placeholders

def main():
    print(f"Lendo vanilla ptBR: {VANILLA_PATH}")
    vanilla, ph_v = parse_quests_file(VANILLA_PATH)
    print(f"  quests vanilla ptBR: {len(vanilla)} placeholders: {ph_v}")

    print(f"Lendo turtle ptBR: {TURTLE_PATH}")
    turtle, ph_t = parse_quests_file(TURTLE_PATH)
    print(f"  quests turtle ptBR: {len(turtle)} placeholders: {ph_t}")

    # Merge ptBR com prioridade turtle
    merged = {}
    for qid, data in vanilla.items():
        merged[qid] = data
    overwritten = 0
    added = 0
    for qid, data in turtle.items():
        if qid in merged:
            overwritten += 1
        else:
            added += 1
        merged[qid] = data
    print(f"Merge ptBR: total={len(merged)} overwritten={overwritten} added={added} (turtle prioridade)")

    # Leitura enUS para indice por titulo ingles
    print(f"Lendo vanilla enUS: {VANILLA_EN_PATH}")
    vanilla_en, ph_ve = parse_quests_file(VANILLA_EN_PATH)
    print(f"  quests vanilla enUS: {len(vanilla_en)} placeholders: {ph_ve}")

    print(f"Lendo turtle enUS: {TURTLE_EN_PATH}")
    turtle_en, ph_te = parse_quests_file(TURTLE_EN_PATH)
    print(f"  quests turtle enUS: {len(turtle_en)} placeholders: {ph_te}")

    en_merged = {}
    for qid, data in vanilla_en.items():
        en_merged[qid] = data
    overwritten_en = 0
    added_en = 0
    for qid, data in turtle_en.items():
        if qid in en_merged:
            overwritten_en += 1
        else:
            added_en += 1
        en_merged[qid] = data
    print(f"Merge enUS: total={len(en_merged)} overwritten={overwritten_en} added={added_en} (turtle prioridade)")

    # Construir lookup ByTitle: titulo ingles -> id
    by_title = {}
    duplicate_titles = 0
    missing_en = 0
    for qid in sorted(merged.keys()):
        en_entry = en_merged.get(qid)
        if en_entry and en_entry.get("T"):
            title_en = en_entry["T"]
            if title_en in by_title:
                duplicate_titles += 1
            by_title[title_en] = qid
        else:
            missing_en += 1
    print(f"ByTitle: entries={len(by_title)} duplicates_overwritten={duplicate_titles} missing_en={missing_en}")

    # Gera arquivo de saida
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8", newline="\n") as f:
        f.write("-- AUTO-GERADO. NAO EDITAR MANUALMENTE.\n")
        f.write("-- Gerado por tools/build_questdb.py a partir de pfQuest/db/ptBR/quests.lua, pfQuest-turtle/db/ptBR/quests-turtle.lua, pfQuest/db/enUS/quests.lua e pfQuest-turtle/db/enUS/quests-turtle.lua\n")
        f.write("-- Turtle tem prioridade sobre vanilla em conflito de ID.\n")
        f.write("ConsoleMode_QuestDB = {}\n")
        for qid in sorted(merged.keys()):
            data = merged[qid]
            t = escape_lua_string(data.get("T", ""))
            d = escape_lua_string(data.get("D", ""))
            o = escape_lua_string(data.get("O", ""))
            f.write(f'ConsoleMode_QuestDB[{qid}] = {{ T="{t}", D="{d}", O="{o}" }}\n')
        f.write("ConsoleMode_QuestDB_ByTitle = {}\n")
        for title_en in sorted(by_title.keys()):
            qid = by_title[title_en]
            t_esc = escape_lua_string(title_en)
            f.write(f'ConsoleMode_QuestDB_ByTitle["{t_esc}"] = {qid}\n')

    print(f"Gerado: {OUTPUT_PATH} com {len(merged)} quests e {len(by_title)} byTitle")
    # Valida tamanho
    lines = OUTPUT_PATH.read_text(encoding="utf-8").splitlines()
    print(f"  linhas: {len(lines)} bytes: {OUTPUT_PATH.stat().st_size}")

if __name__ == "__main__":
    main()
