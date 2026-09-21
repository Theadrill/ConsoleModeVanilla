#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera os lotes da Fase 8.C — Tail NPC a partir de mpq_orphans.json.
Total: 2.087 tail NPC
Excluindo os 356 que já têm PT genérico via norm(d).
Total a traduzir: 1.731 itens em lotes de 50 (35 lotes: 34 de 50 e 1 de 31).
Saída: tools/batches/input_tail_npc_01.json .. input_tail_npc_35.json
"""
import json
import pathlib
import re

ADDON_DIR = pathlib.Path(__file__).resolve().parent.parent

TYPO_MAP = {
    "\u2019": "'", "\u2018": "'", "\u201c": '"', "\u201d": '"',
    "\u2013": "-", "\u2014": "-", "\u2026": "...", "\u00a0": " ",
}

def norm(s):
    t = s or ""
    for a, b in TYPO_MAP.items():
        t = t.replace(a, b)
    return re.sub(r"\s+", " ", t).strip().lower()

def main():
    orphans_file = ADDON_DIR / "tools" / "mpq_orphans.json"
    player_file = ADDON_DIR / "tools" / "mpq_orphans_player.json"
    auth_file = ADDON_DIR / "tools" / "spell_pt_authoral.json"

    orphans = json.loads(orphans_file.read_text(encoding="utf-8"))
    player = json.loads(player_file.read_text(encoding="utf-8"))
    auth = json.loads(auth_file.read_text(encoding="utf-8"))

    player_ids = {o["id"] for o in player}
    norm_auth = {norm(k): v for k, v in auth.items() if v.strip()}

    tail_all = [o for o in orphans if o["id"] not in player_ids]
    tail_with_pt = [o for o in tail_all if norm(o["d"]) in norm_auth]
    tail_without_pt = [o for o in tail_all if norm(o["d"]) not in norm_auth]

    print(f"Total orphans: {len(orphans)}")
    print(f"Player orphans: {len(player)}")
    print(f"Tail NPC total: {len(tail_all)}")
    print(f"Tail NPC com PT (norm): {len(tail_with_pt)}")
    print(f"Tail NPC sem PT (norm): {len(tail_without_pt)}")

    assert len(tail_without_pt) == 1731, f"Esperado 1731, obtido {len(tail_without_pt)}"

    # Ordena por ID para consistência e reprodutibilidade
    tail_without_pt.sort(key=lambda x: x["id"])

    # Salva também um arquivo de índice unificado tools/tail_npc_queue.json
    queue_data = []
    for o in tail_without_pt:
        item = {
            "oid": o["id"],
            "kind": o.get("kind", "custom"),
            "need": "new",
            "sample": f"{o.get('n', '')} {o.get('r', '')}".strip(),
            "en": o["d"],
            "curr_pt": ""
        }
        queue_data.append(item)

    queue_file = ADDON_DIR / "tools" / "tail_npc_queue.json"
    queue_file.write_text(json.dumps(queue_data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Gravado {queue_file} com {len(queue_data)} entradas.")

    batch_size = 50
    batches_dir = ADDON_DIR / "tools" / "batches"
    batches_dir.mkdir(parents=True, exist_ok=True)

    batch_idx = 1
    for i in range(0, len(queue_data), batch_size):
        chunk = queue_data[i:i + batch_size]
        fname = batches_dir / f"input_tail_npc_{batch_idx:02d}.json"
        fname.write_text(json.dumps(chunk, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"  {fname.name}: {len(chunk)} itens (IDs {chunk[0]['oid']}..{chunk[-1]['oid']})")
        batch_idx += 1

    total_batches = batch_idx - 1
    print(f"Geração concluída com sucesso! Total de {total_batches} lotes gerados.")

if __name__ == "__main__":
    main()
