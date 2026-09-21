# DB-ORIGINAL — Banco de Texto Cru dos MPQs (Capycraft & OctoWoW)

Pasta local de extração dos DBCs cliente 1.12.1 para auditoria Blizzlike contextual.

## Estrutura

- `raw/` — dumps crus `.dbc` por patch (`Spell_patch.dbc`, `Spell_patch-4.dbc`, `Item.dbc`...), ignorados no git.
- `extracted/` — JSONs normalizados por tipo (`spells/*.json`, `items/*.json`, `quests/*.json`, `npcs/*.json`, `dialogs/*.json`, `areas/*.json`), ignorados no git (gerados localmente).
- `catalog/` — manifests versionados (CSV/JSON) que listam o que existe sem enviar os binários.
  - `catalog/manifest.json` — inventário de todos os `patch*.MPQ` (Capy vs Octo), tamanhos e hashes parciais.
  - `catalog/dbc_index.json` — índice de DBCs de texto encontrados por MPQ (`Spell`, `Item`, `QuestCache`, `Creature`, `NpcText`, `AreaTable`, `Talent`, etc.).
  - `catalog/stats.json` — contagens por tipo (nrec, com desc/nome, customs vs snapshot).

## Regra profissional Blizzlike

1. **Capy é base sem sobrescrita.** Octo entra como overlay não-destrutivo (`Octo → Capy → vanilla` via `mpq_orphans_octo.json` / `SpellDescDB_ptBR_octo.lua` futuro), nunca em `DB-ORIGINAL/raw` único.
2. **Extração por MPQ, não por Temp.** Ordem cliente `patch.MPQ → patch-2 → patch-3 → patch-4 → patch-5 → patch-6 → patch-7 → patch-8 → patch-9 → patch-A → Patch-B..Y`, com `mpyq.MPQArchive(..., listfile=False)` contornando `Encryption is not supported yet` nos patches criptografados.
3. **Catalogação por tipo, não dump cego.** Cada DBC é classificado por schema (162 vs 173 campos para Spell; schemas próprios para Item/Quest/NpcText) e exportado como JSON por tipo, com `id`, `name`, `desc`/`text` normalizados. Quest e NPC usam `QuestCache.wdb`/`NpcText.dbc` quando houver.

## Como usar

```bash
py tools/extract_db_original.py        # extrai tudo para DB-ORIGINAL/raw + extracted + catalog
py tools/audit_db_original.py          # compara Capy vs Octo por tipo e gera flagged tail
py tools/build_spelldescdb.py          # funde authoral (sem tocar DB-ORIGINAL)
```

Nada em `raw/` ou `extracted/` entra no repo — só `catalog/` e este README.
