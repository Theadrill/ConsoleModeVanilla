#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extrator exaustivo de candidatos PT-BR no codigo Lua do ConsoleModeVanilla.
Fase 3 (localizacao): garante que NENHUM texto em portugues passe batido.

Uso:
    python tools/extract_pt_candidates.py [--out docs/PT_CANDIDATOS.md]

Regras:
- Varre TODOS os .lua do addon (exceto .claude/, worktrees, backups).
- Candidato = literal de string com caractere nao-ASCII OU palavra-chave PT.
- Classificacao automatica (heuristica, agente revisa):
    COMMENT = linha de comentario (ignorada na saida)
    PARSER  = dentro de string.find/strfind/gfind/gsub (NAO TOCAR)
    DISPLAY = em SetText/AddMessage/format/concat (converter p/ CM:T)
    TABLE   = valor em tabela file-level (avaliar padrao tkey)
    OTHER   = resto (agente classifica)
- Saida: markdown com file:line + funcao + contexto + hint.
- Re-rodar apos conversoes: objetivo = zero candidatos DISPLAY/TABLE/OTHER.
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {".git", ".claude", "Media_BACKUP", "__pycache__", "node_modules"}
SKIP_FILES = set()

# Palavras PT sem acento (minúsculas) que indicam texto traduzível.
# Evitar falsos positivos de código: lista conservadora, agente filtra o resto.
PT_KEYWORDS = [
    "vazio", "vazia", "vazios", "vazias",
    "missao", "missoes", "missoes",
    "dano", "nivel", "nvl", "moeda", "moedas",
    "espaco", "espacos", "gratis", "gratuito",
    "botao", "botoes", "tecla", "teclas",
    "dourado", "prateado", "bronze",
    "cabeca", "corpo", "maos", "pernas", "pes",
    "forca", "agilidade", "vigor", "intelecto", "espirito", "armadura",
    "recompensa", "recompensas", "objetivo", "objetivos",
    "requer", "requisito", "requisitos",
    "aprender", "talento", "talentos",
    "magia", "magias", "grimorio", "feitico", "feiticos",
    "bolsa", "bolsas", "mala", "inventario",
    "correio", "carta", "cartas", "destinatario", "assunto", "mensagem",
    "enviar", "envio", "enviado", "receber", "retirar", "devolver", "apagar",
    "mercador", "vendedor", "vender", "comprar", "recompra",
    "vinculado", "unico", "sucata", "lixo",
    "durabilidade", "reparo", "reparar",
    "raca", "classe", "profissao", "profissoes",
    "masmorra", "masmorras", "instancia", "instancias",
    "zona", "zonas", "regiao", "regioes", "continente", "mundo", "mapa",
    "jogador", "personagem", "heroi",
    "sair", "voltar", "fechar", "cancelar", "confirmar", "continuar",
    "proximo", "anterior", "pagina", "paginas",
    "escolha", "selecione", "selecione", "navegue",
    "pressione", "clique", "arraste", "segure", "solte",
    "disponivel", "disponiveis", "indisponivel",
    "carregando", "salvo", "sucesso", "falhou", "falha", "erro",
    "atencao", "aviso", "cuidado",
    "tempo", "duracao", "segundo", "minuto", "hora",
    "vida", "mana", "energia", "furia", "raiva", "foco",
    "ataque", "defesa", "esquiva", "bloqueio", "critico", "acerto",
    "cura", "veneno", "doenca", "magico", "fisico",
    "grupo", "raide", "guilda", "amigo", "inimigo",
    "adicionar", "remover", "limpar", "mapear", "vincular",
    "configuracao", "configuracoes", "opcao", "opcoes", "idioma",
    "atalho", "atalhos", "controle", "teclado", "mouse",
]
PT_WORD_RE = re.compile(
    r"(?<![A-Za-z_])(" + "|".join(sorted(PT_KEYWORDS, key=len, reverse=True)) + r")(?![A-Za-z_])",
    re.IGNORECASE,
)
NON_ASCII_RE = re.compile(r"[^\x00-\x7F]")
PARSER_RE = re.compile(r"\b(string\.find|strfind|string\.gfind|string\.gmatch|gfind|gsub|string\.gsub)\s*\(")
DISPLAY_RE = re.compile(r"\b(SetText|AddMessage|format|Concat|concat)\b|(\.\.)")
FUNC_RE = re.compile(r"^\s*(?:local\s+)?function\s+([\w\.:]+)")


def strip_comment(line):
    """Remove comentario -- fora de strings (heuristica simples)."""
    out = []
    i = 0
    quote = None
    n = len(line)
    while i < n:
        c = line[i]
        if quote:
            if c == "\\" and i + 1 < n:
                out.append(c)
                out.append(line[i + 1])
                i += 2
                continue
            if c == quote:
                quote = None
            out.append(c)
        else:
            if c in ("'", '"'):
                quote = c
                out.append(c)
            elif c == "-" and i + 1 < n and line[i + 1] == "-":
                break
            else:
                out.append(c)
        i += 1
    return "".join(out)


def find_strings(code):
    """Retorna literais de string (conteudo) da linha de codigo (sem comentario)."""
    found = []
    i = 0
    n = len(code)
    while i < n:
        c = code[i]
        if c in ("'", '"'):
            j = i + 1
            buf = []
            while j < n:
                if code[j] == "\\" and j + 1 < n:
                    buf.append(code[j + 1])
                    j += 2
                    continue
                if code[j] == c:
                    break
                buf.append(code[j])
                j += 1
            found.append("".join(buf))
            i = j + 1
        else:
            i += 1
    return found


def iter_lua_files():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in sorted(filenames):
            if not fn.endswith(".lua"):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT)
            if rel in SKIP_FILES:
                continue
            yield full, rel


def main():
    out_path = None
    if "--out" in sys.argv:
        out_path = sys.argv[sys.argv.index("--out") + 1]
    rows = []
    totals = {"DISPLAY": 0, "TABLE": 0, "OTHER": 0, "PARSER": 0}
    for full, rel in iter_lua_files():
        try:
            with io.open(full, encoding="utf-8") as fh:
                lines = fh.read().splitlines()
        except (OSError, UnicodeError) as exc:
            rows.append((rel, 0, "-", "READ-FAIL: %s" % exc, "OTHER", ""))
            continue
        func = "-"
        in_table = 0
        for idx, raw in enumerate(lines, 1):
            m = FUNC_RE.match(raw)
            if m:
                func = m.group(1)
            in_table += raw.count("{") - raw.count("}")
            code = strip_comment(raw)
            if code.strip() == "":
                continue
            lits = find_strings(code)
            hits = [s for s in lits if NON_ASCII_RE.search(s) or PT_WORD_RE.search(s)]
            if not hits:
                continue
            if PARSER_RE.search(code):
                hint = "PARSER"
            elif DISPLAY_RE.search(code):
                hint = "DISPLAY"
            elif in_table > 0 and ("=" in code):
                hint = "TABLE"
            else:
                hint = "OTHER"
            totals[hint] = totals.get(hint, 0) + 1
            rows.append((rel, idx, func, " | ".join(hits), hint, raw.strip()[:220]))
    doc = []
    doc.append("# Candidatos PT-BR no codigo (gerado por tools/extract_pt_candidates.py)")
    doc.append("")
    doc.append("Objetivo: zero itens DISPLAY/TABLE/OTHER. PARSER = nao tocar.")
    doc.append("")
    doc.append("Resumo: %s" % (", ".join("%s=%d" % (k, totals.get(k, 0)) for k in ("DISPLAY", "TABLE", "OTHER", "PARSER")),))
    doc.append("")
    doc.append("| arquivo:linha | funcao | hint | literal | codigo |")
    doc.append("|---|---|---|---|---|")
    for rel, idx, func, lits, hint, code in rows:
        if hint == "PARSER":
            continue
        lits = lits.replace("|", "\\|")
        code = code.replace("|", "\\|")
        doc.append("| %s:%d | %s | %s | %s | %s |" % (rel, idx, func, hint, lits, code))
    text = "\n".join(doc) + "\n"
    if out_path:
        with io.open(os.path.join(ROOT, out_path), "w", encoding="utf-8") as fh:
            fh.write(text)
        print("OK: %s (%d linhas, %d candidatos nao-parser)" % (
            out_path, len(doc),
            totals.get("DISPLAY", 0) + totals.get("TABLE", 0) + totals.get("OTHER", 0)))
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
