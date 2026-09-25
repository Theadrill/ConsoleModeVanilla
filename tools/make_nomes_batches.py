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
Uso: py tools/make_nomes_batches.py [rodada=1]
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
    enlow = (en or "").lower()
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
    # RODADA 2 (EN-ancorado, classes confirmadas na AMOSTRA-01):
    if "cloak" in enlow and "cloak" in low:
        s.append("en-remnant:cloak")
    if "scourge" in enlow and "praga" in low:
        s.append("scourge=praga?")
    if re.search(r"\bhood\b", enlow) and "capô" in low:
        s.append("hood=capo?")
    if en.startswith("Plans:") and pt.startswith("Receita:"):
        s.append("plans=receita?")
    if en.startswith("Pattern:") and pt.startswith("Molde:"):
        s.append("pattern=molde?")
    if "omoplata" in low:
        s.append("omoplata?")
    if "\\" in pt:
        s.append("barra-invertida")
    if "blunderbuss" in enlow and "espingarda" in low:
        s.append("blunderbuss=espingarda?")
    if re.search(r"\bmaul\b", enlow) and "martelo" in low:
        s.append("maul=martelo?")
    # Trava anti-regressão (decisão usuário 24/09): Pattern: SEMPRE Molde:.
    if en.startswith("Pattern:") and not pt.startswith("Molde:"):
        s.append("pattern!=molde")
    # RODADA 3 (classes da AMOSTRA-02):
    EN_GARMENT = ["pauldrons", "bracers", "cloak", "pants", "gauntlets",
                  "leggings", "shoulderpads", "handwraps", "headpiece"]
    for w in EN_GARMENT:
        if re.search(r"\b%s\b" % w, enlow) and re.search(r"\b%s\b" % w, low):
            s.append("en-remnant:" + w)
            break
    if re.search(r"\bvert\b", enlow) and re.search(r"\bvert\b", low):
        s.append("vert?")
    if re.search(r"\bdrake\b", enlow) and not re.search(r"draco", low):
        s.append("drake!=draco?")
    if "stormpike" in enlow and "lançatroz" not in low:
        s.append("stormpike?")
    if "mageweave" in enlow and "mageweave" in low:
        s.append("mageweave?")
    if "felcloth" in enlow and "felcloth" in low:
        s.append("felcloth?")
    if re.search(r"\bcirclet\b", enlow) and ("circlet" in low or "coroa" in low):
        s.append("circlet?")
    if re.search(r"\bmauler\b", enlow) and "mauler" in low:
        s.append("mauler?")
    if "jazeraint" in enlow and "cota de malha" not in low:
        s.append("jazeraint?")
    if re.search(r"\brank\b", enlow) and re.search(r"\brank\b", low):
        s.append("rank-em-item?")
    # RODADA 4 (classes da AMOSTRA-03; decisão Dragonmaw=Presa QuestDB 65x):
    if "dragonmaw" in enlow and "boca do drag" in low:
        s.append("dragonmaw=boca?")
    if re.search(r"\bgirdle\b", enlow) and re.search(r"\bcinto\b", low):
        s.append("girdle=cinto?")
    REMNANTS_R4 = ["grips", "candle", "pioneer", "runic", "primal", "wraith",
                   "parachute", "gyro", "briefing", "silksand", "warpwood",
                   "mosshoof", "antler", "shackle", "choker", "bauble", "cinch",
                   "headdress", "mantle", "bindings", "fang", "paw", "rod",
                   "ward", "wraps", "shroud", "raiments"]
    # RODADA 5 (generalização: resíduo EN token a token; decisão = dica,
    # veredito continua humano. KEEP = nome próprio/oficial mantido.)
    REMNANT_KEEP = {"monster", "mithril", "elixir", "raptor", "dorei",
                    "qiraji", "elemental", "revantusk", "cenarion", "frostwolf",
                    "zandalar", "hakkari", "kazgrim", "orgrimmar", "sayge",
                    "manual", "imperial", "metal", "ritual", "formal",
                    "murloc", "naga", "ogre", "troll", "gnoll", "kobold",
                    "totem", "rune", "glyph", "idol", "voodoo", "mojo"}
    # RODADA 6 (AMOSTRA-05 + Padrões OBRIGATÓRIOS consolidados): expansão
    # REMNANT_FIX com termos sem tradução revelados pela amostra + padrões
    # oficiais ausentes do detector. None = proper noun / decidir caso a caso.
    REMNANT_FIX = {"sword": "Espada", "shield": "Escudo", "staff": "Cajado",
                   "dagger": "Adaga", "blade": "Lâmina", "spaulders": "Ombreiras",
                   "sentinel": "Sentinela", "highlander": "Montanhês",
                   "marshal": "Marechal", "token": "Ficha", "black": "Preto",
                   "green": "Verde", "silver": "Prata", "horde": "Horda",
                   "ironforge": "Altaforja", "netherwind": "Vento Etéreo",
                   "sabatons": None, "offhand": None, "jeweled": None,
                   "shackle": "Grilhão", "crag": "Rochedo", "bark": "Casca",
                   "shroud": "Mortalha", "courser": "Ginete", "brazecore": None,
                   "fen": "Charco", "maiden": None, "mantle": "Dragonas",
                   "morning star": None, "punch": None, "gauze": None,
                   "wrangler": "Boiadeiro", "grunt": "Bruto", "deathguard": "Necroguarda",
                   "pathfinder": "Desbravador", "ember": None, "worg": "Worg",
                   "hood": "Capuz", "wyvern": "Mantícora", "scourge": "Flagelo",
                   "drake": "Draco", "circlet": "Diadema", "mageweave": "Magitrama",
                   "thorium": "Tório", "rod": "Vara", "primal": "Primevo",
                   "reaver": "Abutre", "maul": "Malho", "tablet": "Tablete",
                   "felcloth": "Tecido Vil", "mauler": "Malho", "girdle": "Cinturão",
                   "warchief": "Chefe de Guerra", "dragonmaw": "Presa do Dragão",
                   "robe": "Túnica", "pauldrons": "Ombreiras", "bracers": "Braçadeiras",
                   "gauntlets": "Luvas de Batalha", "leggings": "Perneiras",
                   "breastplate": "Armadura", "greaves": "Coberturas",
                   "handwraps": "Faixas de Mão", "trinket": "Trinket", "ranged": "Arma de Distância",
                   "polearm": "Arma de Haste", "libram": "Tratado", "mace": "Malho",
                   "gavel": "Mazo", "orb": "Orbe", "gem": "Gema", "crown": "Coroa",
                   "helmet": "Capacete", "helmet": "Capacete", "greaves": "Coberturas",
                   "gauntlets": "Luvas de Batalha", "head": "Capacete", "waist": "Cinto",
                   "shoulder": "Ombreiras", "chest": "Peito", "legs": "Pernas",
                   "feet": "Pés", "weapon": "Arma", "armor": "Armadura", "mail": "Malha",
                   "plate": "Placa", "cloth": "Tecido", "leather": "Couro"}
    for w, hint in REMNANT_FIX.items():
        if re.search(r"\b%s\b" % w, enlow) and re.search(r"\b%s\b" % w, low):
            s.append("tok-remnant:%s=>%s" % (w, hint or "?"))
            break
    # RODADA 8 (classes da AMOSTRA-07 + validações 07b-e): type-mismatch.
    # PT contém uma palavra de tipo de item cujo equivalente EN nao esta
    # presente no EN desse item -> forte sinal de crosstalk/erro categorico.
    PT2EN_TYPE = {"luvas": "glove", "botas": "boot", "capa": "cape",
                  "escudo": "shield", "coroa": "crown", "cinto": "belt",
                  "amuleto": "amulet", "anel": "ring", "perneira": "leg",
                  "calça": "pants", "túnica": "robe", "armadura": "chest",
                  "sandália": "sandal"}
    for pt_word, en_type in PT2EN_TYPE.items():
        if re.search(r"\b%s\b" % pt_word, low) and not re.search(r"\b%s" % en_type, enlow):
            s.append("type-mismatch:%s!=%s" % (pt_word, en_type))
            break
    return s


def main():
    import sys
    rodada = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    suffix = "" if rodada == 1 else ("_r%d" % rodada)
    en = load_map(WOW_BASE / "pfQuest" / "db" / "enUS" / "items.lua")
    en.update(load_map(WOW_BASE / "pfQuest-turtle" / "db" / "enUS" / "items-turtle.lua"))
    print("EN carregado:", len(en))
    pt = load_pt_db()
    print("PT carregado:", len(pt))
    # Rodada 2+: exclui ids já CORRIGIDOS (overrides), mas re-julga
    # ids MANTIDOS que os sinais novos alcançarem.
    corrigidos = set()
    if rodada >= 2:
        try:
            over = json.loads((ADDON_DIR / "tools" / "nomes_overrides.json").read_text(encoding="utf-8"))
            corrigidos = set(int(k) for k in over.keys())
        except OSError:
            pass
        print("já corrigidos (excluídos):", len(corrigidos))
    queue = []
    for i, p in pt.items():
        if i in corrigidos:
            continue
        e = en.get(i)
        if not e:
            queue.append({"id": i, "en": "", "pt": p, "sinais": ["sem-en"]})
            continue
        sg = sinais(i, e, p)
        if sg:
            queue.append({"id": i, "en": e, "pt": p, "sinais": sg})
    queue.sort(key=lambda x: x["id"])
    print("rodada %d suspeitos:" % rodada, len(queue), "de", len(pt))
    (ADDON_DIR / "tools" / ("nomes_queue%s.json" % suffix)).write_text(
        json.dumps(queue, indent=1, ensure_ascii=False), encoding="utf-8")
    chunks = [queue[i:i + 100] for i in range(0, len(queue), 100)]
    for n, ch in enumerate(chunks, 1):
        p = ADDON_DIR / "tools" / "batches" / ("input_nomes%s_%02d.json" % (suffix, n))
        p.write_text(json.dumps(
            [{"id": q["id"], "en": q["en"], "pt": q["pt"], "sinais": q["sinais"]} for q in ch],
            indent=1, ensure_ascii=False), encoding="utf-8")
    print("lotes input_nomes%s_01..%02d" % (suffix, len(chunks)))


if __name__ == "__main__":
    main()
