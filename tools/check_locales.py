#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ConsoleMode - Vanilla
tools/check_locales.py

Validador de paridade entre os pacotes de idioma (Fase 6).
Roda FORA do jogo, sem dependencias (apenas stdlib). Uso:

    python3 tools/check_locales.py [--root <dir>]

-p/--root  aponta para a raiz do addon (default: diretorio atual).

LOGICA
- localization_ptBR.lua e a REFERENCIA (base completa).
- Cada localization_<id>.lua presente e comparado contra a base:
    MISSING  = chave existe no ptBR e falta no idioma.
    EXTRA    = chave existe no idioma e nao existe no ptBR.
- O arquivo localization_TEMPLATE.lua (molde inerte cru) e PULADO
  por nome: ele nao e registro real e nao deve entrar no diff.
- Modo formato (WARNING, nao quebra exit): para chaves presentes nos
  dois, compara a contagem de especificadores %s/%d/%f (multiset,
  ordem ignorada) e o par de cores |cff<hex6>|r. "%%" literal conta
  como 0 especificador.
- Modo .toc (WARNING): confere a ordem canonica de carga:
  Data\\Localization.lua ANTES de todas as Data\\Localization\\localization_*.lua,
  e todas estas ANTES da primeira linha UI\\.

EXIT CODE
    0  zero MISSING/EXTRA (warnings nao afetam).
    1  qualquer MISSING ou EXTRA.
"""

import os
import re
import sys

BASE_LANG_ID = "ptBR"
TEMPLATE_NAME = "localization_TEMPLATE.lua"

KEY_RE = re.compile(r'^\s*([A-Z][A-Z0-9_]*)\s*=\s*"(.*)"\s*,?\s*(?:--.*)?\s*$')
BLOCK_OPEN_RE = re.compile(r"\.?\s*strings\s*=\s*\\?\{")
BLOCK_CLOSE_RE = re.compile(r"^\s*}\s*,?\s*(?:--.*)?\s*$")
SPEC_RE = re.compile(r"%(s|d|f)")
CFF_RE = re.compile(r"\|cff[0-9a-fA-F]{6}", re.IGNORECASE)


def lua_path(root, fname):
    return os.path.join(root, "Data", "Localization", fname)


def parse_strings(path):
    """Extrai {chave: valor} do bloco `strings = { ... }` do arquivo.

    A partir da linha que abre o bloco ate a primeira linha de fechamento
    `}` (tabela plana, uma chave por linha, sem nesting). Ignora a linha
    de abertura, metadados (name/flag/game), comentarios e linhas fora
    do bloco.
    """
    out = {}
    try:
        with open(path, "r", encoding="utf-8-sig") as fh:
            lines = fh.readlines()
    except OSError as exc:
        sys.stderr.write("ERROR: nao leu %s: %s\n" % (path, exc))
        return out
    in_block = False
    for line in lines:
        if not in_block:
            if BLOCK_OPEN_RE.search(line):
                in_block = True
            continue
        if BLOCK_CLOSE_RE.match(line):
            in_block = False
            continue
        if line.lstrip().startswith("--"):
            continue
        m = KEY_RE.match(line)
        if m:
            out[m.group(1)] = m.group(2)
    return out


def spec_counts(value):
    value = value.replace("%%", "")
    counts = {"s": 0, "d": 0, "f": 0}
    for m in SPEC_RE.finditer(value):
        counts[m.group(1)] += 1
    return counts


def color_counts(value):
    return (len(CFF_RE.findall(value)), value.count("|r"))


def fmt_spec(c):
    return "s:%d d:%d f:%d" % (c["s"], c["d"], c["f"])


def check_file(lang_id, base, path, warn):
    """Compara um pacote contra a base. Retorna (missing, extra, nkeys)."""
    data = parse_strings(path)
    missing = sorted(k for k in base if k not in data)
    extra = sorted(k for k in data if k not in base)
    for k in missing:
        sys.stdout.write("MISSING %s\n" % k)
    for k in extra:
        sys.stdout.write("EXTRA %s\n" % k)
    if warn:
        for k in sorted(k for k in data if k in base):
            pb = spec_counts(base[k])
            ll = spec_counts(data[k])
            if pb != ll:
                sys.stdout.write(
                    "WARN-FMT %s pt=(%s) %s=(%s)\n" % (k, fmt_spec(pb), lang_id, fmt_spec(ll)))
            pcol = color_counts(base[k])
            lcol = color_counts(data[k])
            if pcol != lcol:
                sys.stdout.write(
                    "WARN-COLOR %s pt=(cff:%d r:%d) %s=(cff:%d r:%d)\n"
                    % (k, pcol[0], pcol[1], lang_id, lcol[0], lcol[1]))
    sys.stdout.write(
        "[%s] keys=%d missing=%d extra=%d\n" % (lang_id, len(data), len(missing), len(extra)))
    return missing, extra, len(data)


def check_toc(root):
    """Confere a ordem canonica de carga no .toc. Returna True se ok."""
    toc = os.path.join(root, "ConsoleModeVanilla.toc")
    want_bad = False
    try:
        with open(toc, "r", encoding="utf-8-sig") as fh:
            lines = [ln.strip() for ln in fh.readlines() if ln.strip() and not ln.lstrip().startswith("#")]
    except OSError as exc:
        sys.stdout.write("WARN-TOC nao leu .toc: %s\n" % exc)
        return False
    idx_base = None
    idx_lang = []
    idx_ui = None
    for i, ln in enumerate(lines):
        low = ln.lower()
        if low.startswith("data\\localization.lua") or low.startswith("data\\localization.lua "):
            if idx_base is None:
                idx_base = i
        elif low.startswith("data\\localization\\localization_") and low.endswith(".lua"):
            idx_lang.append(i)
        elif low.startswith("ui\\"):
            if idx_ui is None:
                idx_ui = i
            continue
        elif low.startswith("data\\") and "localization" in low:
            continue
    if idx_base is not None and idx_lang:
        if idx_base > min(idx_lang):
            sys.stdout.write(
                "WARN-TOC Data\\Localization.lua (linha %d) deve vir ANTES das localization_*.lua (primeira na linha %d)\n"
                % (idx_base, min(idx_lang)))
            want_bad = True
    if idx_ui is not None:
        bad_lang = [i for i in idx_lang if i > idx_ui]
        if bad_lang:
            sys.stdout.write(
                "WARN-TOC localization_*.lua (linhas %s) devem vir ANTES da primeira UI\\ (linha %d)\n"
                % (",".join(str(i) for i in bad_lang), idx_ui))
            want_bad = True
    elif idx_lang:
        sys.stdout.write("WARN-TOC nenhuma linha UI\\ encontrada no .toc\n")
        want_bad = True
    if not want_bad:
        sys.stdout.write("[toc] ordem canonica OK (Localization.lua antes de localization_*.lua antes de UI\\)\n")
    else:
        sys.stdout.write("[toc] ordem canonica VIOLADA\n")
    return not want_bad


def main():
    root = "."
    args = sys.argv[1:]
    while args:
        a = args.pop(0)
        if a in ("--root", "-p"):
            if not args:
                sys.stderr.write("ERROR: --root precisa de valor\n")
                return 2
            root = args.pop(0)
        else:
            sys.stderr.write("WARNING: argumento ignorado: %s\n" % a)
    root = os.path.abspath(root)
    ldir = os.path.join(root, "Data", "Localization")
    base_path = os.path.join(ldir, "localization_%s.lua" % BASE_LANG_ID)

    sys.stdout.write("ConsoleMode - Validador de Locales (Fase 6)\n")
    sys.stdout.write("Base de referencia: %s\n" % os.path.relpath(base_path, root))
    if not os.path.exists(base_path):
        sys.stderr.write("ERROR: base nao encontrada: %s\n" % base_path)
        return 2

    base = parse_strings(base_path)
    total_missing = 0
    total_extra = 0
    checked = 0

    for fname in sorted(os.listdir(ldir)):
        m = re.match(r"^localization_([A-Za-z0-9_]+)\.lua$", fname)
        if not m:
            continue
        if fname == TEMPLATE_NAME:
            continue
        if m.group(1) == BASE_LANG_ID:
            continue
        lang_id = m.group(1)
        checked += 1
        sys.stdout.write("\n=== %s ===\n" % fname)
        miss, extra, _n = check_file(lang_id, base, os.path.join(ldir, fname), warn=True)
        total_missing += len(miss)
        total_extra += len(extra)

    sys.stdout.write("\n=== resumo ===\n")
    if checked == 0:
        sys.stdout.write("Nenhum localization_<id>.lua encontrado para validar.\n")
        return 2
    sys.stdout.write("idiomas validados: %d (base %s excluida do loop; only langs != base)\n" % (checked, BASE_LANG_ID))
    sys.stdout.write("MISSING total: %d\nEXTRA total: %d\n" % (total_missing, total_extra))
    check_toc(root)
    if total_missing == 0 and total_extra == 0:
        sys.stdout.write("\nRESULTADO: OK (paridade perfeita).\n")
        return 0
    sys.stdout.write("\nRESULTADO: FALHOU (%d missing, %d extra).\n" % (total_missing, total_extra))
    return 1


if __name__ == "__main__":
    sys.exit(main())