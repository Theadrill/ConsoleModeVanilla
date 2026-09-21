#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extrai todo texto traduzivel dos MPQs para DB-ORIGINAL (Capy base, Octo overlay).
Categorias: spells, items, quests, npcs/npctext, creatures, areas, talents, etc.
Cada DBC -> JSON normalizado em DB-ORIGINAL/extracted/<patch>/<tipo>.json
+ catalog/dbc_index.json + catalog/manifest.json + catalog/stats.json
Uso: py tools/extract_db_original.py [--capy-only | --octo-only] [--limit N]
"""
import json
import pathlib
import struct
import hashlib
import re
import sys

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent
OUT_ROOT = ADDON_DIR / "DB-ORIGINAL"
RAW_DIR = OUT_ROOT / "raw"
EXTRACTED_DIR = OUT_ROOT / "extracted"
CATALOG_DIR = OUT_ROOT / "catalog"
TEMP = pathlib.Path(r"C:\Users\rodri\AppData\Local\Temp\opencode")

CAPY_DATA = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\turtle wow\Data")
OCTO_DATA = pathlib.Path(r"C:\Users\rodri\OneDrive\wow\octowow\Data")

# Patch order cliente 1.12: patch.MPQ base, depois patch-2..9, patch-A, Patch-B..Y
PATCH_ORDER = [
    "patch.MPQ",
    "patch-2.MPQ", "patch-2.mpq",
    "patch-3.mpq",
    "patch-4.mpq",
    "patch-5.mpq",
    "patch-6.mpq",
    "patch-7.mpq",
    "patch-8.mpq",
    "patch-9.mpq",
    "patch-A.mpq", "patch-A.MPQ",
    "Patch-B.mpq", "Patch-C.mpq", "Patch-F.mpq", "Patch-T.mpq", "Patch-W.mpq", "Patch-X.mpq", "Patch-Y.mpq",
    "patch-1.mpq",  # só Octo
]

# Mapeamento DBC -> tipo lógico (nome do arquivo dentro do MPQ)
DBC_MAP = {
    # Spells (já validado)
    "DBFilesClient\\Spell.dbc": ("spells", "spell", {"id": 0, "name": 120, "rank": 129, "desc": 138, "tip": 147, "nf": 173}),
    "DBFilesClient/Spell.dbc": ("spells", "spell", {"id": 0, "name": 120, "rank": 129, "desc": 138, "tip": 147, "nf": 173}),
    # Items
    "DBFilesClient\\Item.dbc": ("items", "item", None),  # schema variavel, extrair bruto
    "DBFilesClient/Item.dbc": ("items", "item", None),
    "DBFilesClient\\ItemDisplayInfo.dbc": ("items", "item_display", None),
    "DBFilesClient\\ItemSet.dbc": ("items", "item_set", None),
    # Quests (via QuestCache.wdb ou QuestTemplate em DBC)
    "DBFilesClient\\QuestCache.wdb": ("quests", "quest_cache", None),
    "DBFilesClient\\QuestInfo.dbc": ("quests", "quest_info", None),
    # NPCs / Creatures / Dialogs
    "DBFilesClient\\CreatureDisplayInfo.dbc": ("npcs", "creature_display", None),
    "DBFilesClient\\CreatureModelData.dbc": ("npcs", "creature_model", None),
    "DBFilesClient\\NpcText.dbc": ("npcs", "npc_text", None),
    "DBFilesClient\\GossipText.dbc": ("dialogs", "gossip_text", None),
    # Areas / Zones
    "DBFilesClient\\AreaTable.dbc": ("areas", "area_table", None),
    "DBFilesClient\\Map.dbc": ("areas", "map", None),
    # Talents / Skills
    "DBFilesClient\\Talent.dbc": ("talents", "talent", None),
    "DBFilesClient\\TalentTab.dbc": ("talents", "talent_tab", None),
    "DBFilesClient\\SkillLine.dbc": ("skills", "skill_line", None),
    "DBFilesClient\\SkillLineAbility.dbc": ("skills", "skill_line_ability", None),
    # Outros texto-ricos
    "DBFilesClient\\SpellIcon.dbc": ("spells", "spell_icon", None),
    "DBFilesClient\\ChrRaces.dbc": ("misc", "chr_races", None),
    "DBFilesClient\\ChrClasses.dbc": ("misc", "chr_classes", None),
}

SNAPSHOT_DBC = TEMP / "Spell.dbc"  # vanilla snapshot nf162

def mpyq_list_candidates(mpq_path):
    """Lista candidatos de DBC relevantes sem depender de listfile (criptografado)."""
    candidates = list(DBC_MAP.keys())
    # Normaliza duplicatas
    norm = {}
    for k in candidates:
        nk = k.replace("/", "\\").lower()
        norm[nk] = k
    return list(norm.values())

def extract_one(mpq_path, dbc_internal, out_bytes_path):
    """Tenta extrair um DBC interno do MPQ para out_bytes_path (via mpyq)."""
    try:
        import mpyq
        ar = mpyq.MPQArchive(str(mpq_path), listfile=False)
        # Tenta ambas barras
        for cand in [dbc_internal, dbc_internal.replace("\\", "/"), dbc_internal.replace("/", "\\")]:
            try:
                data = ar.read_file(cand)
                if data is not None:
                    out_bytes_path.write_bytes(data)
                    return True, len(data)
            except Exception:
                continue
        return False, 0
    except Exception as e:
        return False, str(e)

def hash_head(path, n=1048576):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in [f.read(n), f.read(n), f.read(n)]:
            if chunk:
                h.update(chunk)
    return h.hexdigest()[:16]

def main():
    capy_only = "--capy-only" in sys.argv
    octo_only = "--octo-only" in sys.argv

    # Limpa/lista patches em ordem
    def list_patches(base):
        out = []
        for name in PATCH_ORDER:
            p = base / name
            alt = base / name.lower()
            alt2 = base / name.upper()
            for cand in [p, alt, alt2]:
                if cand.exists():
                    out.append(cand)
                    break
        # dedup por lower
        seen = {}
        for p in out:
            k = p.name.lower()
            if k not in seen:
                seen[k] = p
        # ordena por PATCH_ORDER
        order_idx = {n.lower(): i for i, n in enumerate(PATCH_ORDER)}
        return sorted(seen.values(), key=lambda p: order_idx.get(p.name.lower(), 99))

    capy_patches = list_patches(CAPY_DATA) if not octo_only else []
    octo_patches = list_patches(OCTO_DATA) if not capy_only else []

    print(f"Capy patches: {[p.name for p in capy_patches]}")
    print(f"Octo patches: {[p.name for p in octo_patches]}")

    manifest = {"capy": [], "octo": [], "snapshot": None}
    dbc_index = {"capy": {}, "octo": {}, "snapshot": {}}
    stats = {"capy": {}, "octo": {}, "snapshot": {}}

    # Snapshot vanilla
    if SNAPSHOT_DBC.exists():
        manifest["snapshot"] = {"file": str(SNAPSHOT_DBC), "size": SNAPSHOT_DBC.stat().st_size, "hash": hash_head(SNAPSHOT_DBC)}
        # index snapshot: só Spell
        try:
            data = SNAPSHOT_DBC.read_bytes()
            magic, nrec, nf, rs, ss = struct.unpack("<4sIIII", data[:20])
            dbc_index["snapshot"]["DBFilesClient\\Spell.dbc"] = {"nrec": nrec, "nf": nf, "rs": rs, "path": str(SNAPSHOT_DBC)}
            stats["snapshot"]["spells"] = {"nrec": nrec, "with_desc": 0}  # desc contada depois se extrair
        except Exception as e:
            print("snapshot parse fail", e)

    # Extrai por patch
    for label, patches in [("capy", capy_patches), ("octo", octo_patches)]:
        for mpq in patches:
            h = hash_head(mpq)
            manifest[label].append({"file": str(mpq), "name": mpq.name, "size": mpq.stat().st_size, "hash": h})
            patch_tag = mpq.stem  # patch, patch-2, etc
            raw_patch_dir = RAW_DIR / label / patch_tag
            raw_patch_dir.mkdir(parents=True, exist_ok=True)
            extracted_patch_dir = EXTRACTED_DIR / label / patch_tag
            extracted_patch_dir.mkdir(parents=True, exist_ok=True)

            for dbc_internal in mpyq_list_candidates(mpq):
                # Normaliza nome arquivo para raw
                safe = dbc_internal.replace("\\", "_").replace("/", "_")
                raw_out = raw_patch_dir / safe
                ok, n = extract_one(mpq, dbc_internal, raw_out)
                if ok:
                    # Registra no dbc_index
                    try:
                        data = raw_out.read_bytes()
                        magic, nrec, nf, rs, ss = struct.unpack("<4sIIII", data[:20])
                        key = dbc_internal
                        if key not in dbc_index[label]:
                            dbc_index[label][key] = []
                        dbc_index[label][key].append({"patch": patch_tag, "mpq": str(mpq), "raw": str(raw_out), "size": n, "nrec": nrec, "nf": nf, "rs": rs})
                        # Stats por tipo
                        tipo = DBC_MAP.get(dbc_internal, (dbc_internal, dbc_internal, None))[0]
                        stats[label].setdefault(tipo, {"files": 0, "nrec_total": 0})
                        stats[label][tipo]["files"] += 1
                        stats[label][tipo]["nrec_total"] += nrec
                    except Exception as e:
                        print(f"parse fail {dbc_internal} in {mpq.name}: {e}")

    CATALOG_DIR.mkdir(parents=True, exist_ok=True)
    (CATALOG_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    (CATALOG_DIR / "dbc_index.json").write_text(json.dumps(dbc_index, indent=2, ensure_ascii=False), encoding="utf-8")
    (CATALOG_DIR / "stats.json").write_text(json.dumps(stats, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"escrito {CATALOG_DIR / 'manifest.json'}")
    print(f"escrito {CATALOG_DIR / 'dbc_index.json'}")
    print(f"escrito {CATALOG_DIR / 'stats.json'}")
    print(json.dumps(stats, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
