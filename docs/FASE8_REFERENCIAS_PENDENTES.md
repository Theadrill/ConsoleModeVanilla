# Referências da Fase 8 — PENDENTES DE VALIDAÇÃO
> Guardadas para crédito no README **somente se os dados realmente funcionarem** no build.
> Não adicionar ao README antes da validação no jogo.

## Fontes de dados (fonte da verdade EN offline)

1. **Shagu / pfQuest** — `Interface/AddOns/pfQuest/db/{enUS,ptBR}/items.lua`
   Nomes de itens vanilla 1.12 por ID (17.712). PT da comunidade.
   Repo: https://github.com/shagu/pfQuest
   Status: VALIDADO — `Data/ItemDB_ptBR.lua` gerado e funcional.

2. **Shagu / pfQuest-turtle** — `Interface/AddOns/pfQuest-turtle/db/{enUS,ptBR}/items-turtle.lua`
   Nomes de itens customs do Turtle WoW por ID (8.294 EN / 20.358 PT).
   Repo: https://github.com/shagu/pfQuest-turtle
   Status: VALIDADO — merge no ItemDB com prioridade Turtle.

3. **oplancelot / Turtle-WOW-DBC** — `dbc.MPQ/DBFilesClient/Spell.json`
   DBCs do Turtle 1.18 exportados (Ladik MPQ Editor + WDBX Editor): `Spell`,
   `SpellCastTimes`, `SpellDuration`, `SpellRadius`, `SpellRange`, etc.
   Repo: https://github.com/oplancelot/Turtle-WOW-DBC
   Status: A VALIDAR — destino: `Data/SpellDescDB_ptBR.lua`.

4. **kofoednielsen / twow-items** (+ McPewPew / ItemTooltipLogger)
   Tooltips EN completos de itens do Turtle (varredura IDs 0–120000 via addon
   `ItemTooltipLogger`, pipeline `pipeline.sh` com parser).
   Repo dados: https://github.com/kofoednielsen/twow-items
   Logger: https://github.com/McPewPew/ItemTooltipLogger
   Status: A VALIDAR — destino: `Data/ItemDescDB_ptBR.lua`.

## Ferramentas de referência

5. **suprsokr / vanilladbc-cli** + **suprsokr / VanillaDBDefs**
   Conversor DBC ↔ CSV/JSON para build 1.12.1.5875 (plano B caso o JSON do item 3 falhe).
   https://github.com/suprsokr/vanilladbc-cli
   https://github.com/suprsokr/VanillaDBDefs
   Status: reserva, usar só se necessário.
