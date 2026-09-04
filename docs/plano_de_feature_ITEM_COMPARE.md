# Plano de Feature: FASE 14 — Sistema de Comparação de Equipamentos (Stat Diff Verde/Vermelho + Seção ⚔️ COMPARAÇÃO)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido usar operadores de Lua 5.1+ (como `#table`, usar `table.getn(t)` ou `getn(t)`).
> 3. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 4. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem o comando e autorização explícita do usuário.
> 5. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem fazer uma parada crítica, solicitar a validação do usuário no jogo via `/reload` e aguardar seu feedback/aprovação.

---

## 1. Visão Geral

A **FASE 14** adiciona o sistema de **comparação de equipamentos** ao Main Menu (Console Hub), respondendo à pergunta central do jogador ao passar o cursor sobre um item na bolsa: *"vale a pena equipar isso?"*.

O sistema atua em **duas frentes visuais simultâneas** na coluna `ConsoleModeMM_StatsColumn` (direita do modelo 3D):

### 1.1. Coluna de Stats Principais (sempre visível — 8 linhas fixas)

| Linha | Chave (`statLines`) | Fonte atual |
|---|---|---|
| 1 | `HP` | `UnitHealth` / `UnitHealthMax` |
| 2 | `Recurso` | `UnitMana` + `UnitPowerType` (Mana/Rage/Energia) |
| 3 | `Força` | `UnitStat("player", 1)` |
| 4 | `Agilidade` | `UnitStat("player", 2)` |
| 5 | `Vigor` | `UnitStat("player", 3)` |
| 6 | `Intelecto` | `UnitStat("player", 4)` |
| 7 | `Espírito` | `UnitStat("player", 5)` |
| 8 | `Armadura` | `UnitArmor("player")` (valor efetivo) |

**Comportamento ao hover em item equipável na bag:**
- Calcula a diferença de cada atributo (item da bag − item equipado no slot correspondente).
- Verde `(+X)` se aumenta → ex: `Força: 142 (+12)`.
- Vermelho `(-X)` se diminui → ex: `Força: 130 (-12)`.
- Branco sem sufixo se igual → ex: `Força: 142`.

> **Decisão técnica aprovada:** o diff dos 8 stats principais é calculado por **parsing de tooltip** (item equipado vs. hovered), pois `UnitStat()` só reflete o estado *atual* (antes do equip). O `UnitStat` é usado como **valor base** exibido; o **delta** vem do parsing. Isso evita equipar/desequipar de verdade.

### 1.2. Seção "⚔️ COMPARAÇÃO" (dinâmica — só aparece ao hover)

- Posição: **entre** os 8 stats principais e o header `BUFFS ATIVOS` (empurra os buffs para baixo via re-anchor).
- **Mostra APENAS stats secundários que MUDAM** (se ficou igual, não aparece — economiza espaço):
  - Armas: DPS, Dano (min–max), Velocidade.
  - Melee/físico: Poder de Ataque, Chance de Acerto (Hit%), Crítico%, Esquiva% (Dodge), Bloqueio% (Block).
  - Casters: Dano Mágico (Spell Damage), Cura (Healing).
- **Cores:**
  - 🟢 Verde `(+X)` / `(novo)`: aumentou ou stat inexistente no item equipado.
  - 🔴 Vermelho `(-X)`: diminuiu.
  - ⚪ Iguais: **omitidos**.
- **Ao sair do hover** (slot vazio, consumível, material, ou mouse fora): a seção **desaparece** (`Hide()`), os buffs **voltam** ao anchor original e as 8 linhas voltam ao branco.

### 1.3. Slots Duais (anéis e berloques)

- `INVTYPE_FINGER` (slots 11, 12) e `INVTYPE_TRINKET` (slots 13, 14) possuem **dois slots**.
- Regra: comparar o item da bag contra o **pior dos dois equipados** (menor soma de stats parseados) = **melhor upgrade possível**.
- Se um dos dois slots estiver vazio → compara contra o slot vazio (todo stat do novo item é "novo"/verde).

### 1.4. Layout resultante (ASCII)

```
Antes do hover (estado atual, inalterado):
+-- ConsoleModeMM_StatsColumn --+
| STATUS                        |
| HP: 4500 / 4500               |
| Mana: 100 / 100               |
| Força: 210                    |
| Agilidade: 115                |
| Vigor: 190                    |
| Intelecto: 80                 |
| Espírito: 65                  |
| Armadura: 4120                |
| ---------------- (statDiv)    |
| BUFFS ATIVOS                  |
| [+] Battle Shout (35m)        |
+-------------------------------+

Durante hover em item equipável:
+-- ConsoleModeMM_StatsColumn --+
| STATUS                        |
| HP: 4500 / 4500               |
| Força: 210 (+12)  <- verde    |
| Vigor: 190 (-5)   <- vermelho |
| ... (demais brancas)          |
| ----------------              |
| ⚔️ COMPARAÇÃO                 |
| DPS +3.2          <- verde    |
| +1% Crít.         <- verde    |
| -5 Armadura       <- vermelho |
| ----------------              |
| BUFFS ATIVOS (empurrados)     |
| [+] Battle Shout (35m)        |
+-------------------------------+
```

---

## 2. Arquitetura Técnica

### 2.1. APIs WoW 1.12 necessárias

| API | Uso |
|---|---|
| `GetContainerItemLink(bagID, slotID)` | Link do item hovered na bag (já disponível em `itemData.link` / `rawLink`) |
| `GetInventoryItemLink("player", invSlotID)` | Link do item atualmente equipado no slot |
| `GetInventorySlotInfo(slotName)` | Converte nome de slot (`"Finger0Slot"`) → `invSlotID` numérico (já usado em `UpdateEquipmentColumn`, linha ~1070) |
| `GetItemInfo(rawLink)` → `itemEquipLoc` | Retorna `INVTYPE_*` (ex: `INVTYPE_HEAD`, `INVTYPE_FINGER`, `INVTYPE_WEAPON`); já capturado em `ParseItemData()` (linha ~2375) |
| `UnitStat("player", 1..5)` | Valor base exibido nas 5 linhas de atributo (já usado em `UpdateStatsAndBuffs`, linhas 1274–1278) |
| `UnitArmor("player")` | Valor base da linha Armadura (linha 1280) |
| `UnitHealth / UnitHealthMax / UnitMana / UnitManaMax / UnitPowerType` | Linhas HP e Recurso (inalteradas, sem diff) |
| `scanTip` (`ConsoleModeMMScanTooltip`, linha 410) + `SetHyperlink` / `SetInventoryItem` / `SetBagItem` | **Parsing de tooltip**: única fonte confiável de stats secundários no 1.12 (não existem `GetItemStats`/`GetDetailedItemLevelInfo` no Vanilla) |
| `GetPlayerBuff / GetPlayerBuffTexture / GetPlayerBuffTimeLeft` | Inalterados (buffs apenas descem/sobem visualmente) |

> ⚠️ **Não usar (inexistentes no 1.12):** `GetItemStats()`, `C_Item.*`, `GetContainerItemInfo` com mais de 4 retornos, operador `#`, `...` variádico 5.1, `string.match` com capturas complexas 5.1 (usar `string.find` + `tonumber`, padrão já adotado no arquivo).

### 2.2. Mapeamento `INVTYPE_*` → `invSlotID`

O 1.12 resolve nomes de slot via `GetInventorySlotInfo("SlotName")`. A tabela de correspondência a implementar (função `MainMenu:GetCompareSlotForEquipLoc(equipLoc)`):

| `equipLoc` (`INVTYPE_*`) | Slot(s) 1.12 | Observação |
|---|---|---|
| `INVTYPE_HEAD` | `HeadSlot` (1) | |
| `INVTYPE_NECK` | `NeckSlot` (2) | |
| `INVTYPE_SHOULDER` | `ShoulderSlot` (3) | |
| `INVTYPE_BODY` | `ShirtSlot` (4) | |
| `INVTYPE_CHEST` / `INVTYPE_ROBE` | `ChestSlot` (5) | |
| `INVTYPE_WAIST` | `WaistSlot` (6) | |
| `INVTYPE_LEGS` | `LegsSlot` (7) | |
| `INVTYPE_FEET` | `FeetSlot` (8) | |
| `INVTYPE_WRIST` | `WristSlot` (9) | |
| `INVTYPE_HAND` | `HandsSlot` (10) | |
| `INVTYPE_FINGER` | `Finger0Slot` (11) **e** `Finger1Slot` (12) | **Dual: comparar contra o pior** |
| `INVTYPE_TRINKET` | `Trinket0Slot` (13) **e** `Trinket1Slot` (14) | **Dual: comparar contra o pior** |
| `INVTYPE_CLOAK` | `BackSlot` (15) | |
| `INVTYPE_WEAPON` (1H) | `MainHandSlot` (16) | |
| `INVTYPE_SHIELD` / `INVTYPE_HOLDABLE` | `SecondaryHandSlot` (17) | |
| `INVTYPE_2HWEAPON` | `MainHandSlot` (16) | Off-hand ignorado no diff (regra: só main) |
| `INVTYPE_RANGED` / `INVTYPE_THROWN` / `INVTYPE_RANGEDRIGHT` / `INVTYPE_RELIC` | `RangedSlot` (18) | |
| `INVTYPE_TABARD` | `TabardSlot` (19) | Sem stats — hover não ativa comparação |
| `""` / `nil` / `INVTYPE_BAG` / `INVTYPE_AMMO` / `INVTYPE_QUIVER` | — | **Não equipável no sentido de stats → sem comparação** |

Implementação: `local slotID = GetInventorySlotInfo("Finger0Slot")` etc. Para duais, resolver os dois e escolher o pior (ver §2.4).

### 2.3. Estrutura de dados — cache de stats parseados

```lua
-- Bloco novo "FASE 14" em UI/MainMenu.lua (após UpdateStatsAndBuffs, ~linha 1390)
MainMenu.statCompareCache = MainMenu.statCompareCache or {}
-- Formato: statCompareCache[itemLinkString] = {
--   str=0, agi=0, sta=0, int=0, spi=0, armor=0,
--   hp=0, mana=0,
--   ap=0, hit=0, crit=0, dodge=0, block=0,
--   spellDmg=0, healing=0,
--   dps=0, minDmg=0, maxDmg=0, speed=0,
-- }
MainMenu.compareState = MainMenu.compareState or {
  active = false,        -- true enquanto hover em equipável
  hoveredLink = nil,     -- link do item da bag
  targetSlot = nil,      -- invSlotID comparado (ou o pior, se dual)
  baseTexts = {},        -- textos originais das 8 linhas (para restaurar)
}
```

- **Chave do cache:** string completa do `itemLink` (`|c...|H(item:...)|h[...]`) — dois itens iguais compartilham entrada.
- **Invalidação:**
  - `BAG_UPDATE` e `UNIT_INVENTORY_CHANGED`: limpar entradas dos links afetados (solução simples e segura: `MainMenu.statCompareCache = {}` — wipe total; volume de itens é pequeno e o re-parse é sob demanda no hover).
  - Registrar via frame de eventos dedicado `ConsoleModeMM_CompareEvents` (não poluir o handler principal do menu).
- **Performance:** parsing só acontece **uma vez por link** (cache hit nas próximas vezes); tooltip scan reutiliza o `scanTip` global já existente (linha 410) — **não criar segundo GameTooltip**.

### 2.4. Parsing de tooltip — padrões regex bilíngues (PT-BR + EN)

> Cliente Turtle WoW pode estar em PT-BR ou EN. Todo padrão deve aceitar os dois idiomas. Usar `string.find(text, pattern)` com Lua 5.0 (sem quantificadores possessivos, sem `%d+%.?%d*` problemático — testar cada padrão).

Função: `MainMenu:ParseItemStats(itemLink)` — aceita link completo **ou** `rawLink` (`"item:1234:..."`); resolve via `scanTip:SetHyperlink`, percorre `ConsoleModeMMScanTooltipTextLeft1..N`, acumula na tabela de stats. Retorna tabela zerada (nunca `nil`) para simplificar o diff.

| Stat (chave) | Exemplos de linha no tooltip | Padrão PT-BR | Padrão EN |
|---|---|---|---|
| `str` | `+12 Força` | `^%+(%d+) For[^%a]` | `^%+(%d+) Strength` |
| `agi` | `+8 Agilidade` | `^%+(%d+) Agilidade` | `^%+(%d+) Agility` |
| `sta` | `+15 Vigor` | `^%+(%d+) Vigor` | `^%+(%d+) Stamina` |
| `int` | `+10 Intelecto` | `^%+(%d+) Intelecto` | `^%+(%d+) Intellect` |
| `spi` | `+6 Espírito` | `^%+(%d+) Esp` | `^%+(%d+) Spirit` |
| `armor` | `215 Armadura` | `^(%d+) Armadura` | `^(%d+) Armor` |
| `hp` | `+100 Vida` / Equip: +100 Health | `%+(%d+) Vida` | `%+(%d+) Health` |
| `mana` | `+80 Mana` | `%+(%d+) Mana` | `%+(%d+) Mana` |
| `ap` | `+24 Poder de Ataque` / Equip: +attack power | `%+(%d+) Poder de Ataque` | `%+(%d+) Attack Power` / `attack power` |
| `hit` | `+1% Chance de Acertar` | `(%d+)%%.*Acert` | `(%d+)%%.*Hit` |
| `crit` | `+1% Crít.` / Equip: +crit | `(%d+)%%.*Cr` | `(%d+)%%.*Crit` |
| `dodge` | `+1% Esquiva` | `(%d+)%%.*Esquiva` | `(%d+)%%.*Dodge` |
| `block` | `+2% Bloqueio` / `+15 Bloqueio` (valor) | `(%d+)%%?.*Bloqueio` / `%+(%d+) Bloqueio` | `(%d+)%%?.*Block` |
| `spellDmg` | `+9 Dano Mágico` / `+damage` | `%+(%d+) Dano` | `%+(%d+).*damage` / `Spell Damage` |
| `healing` | `+22 Cura` / `+healing` | `%+(%d+) Cura` | `%+(%d+).*Healing` |
| `dps` | `(12,5 dano por segundo)` | `([%d%,%.]+) dano por segundo` | `([%d%,%.]+) damage per second` |
| `minDmg/maxDmg/speed` | `44 - 115 Dano`, `Velocidade 1.90` | `(%d+)%s*%-%s*(%d+) Dano`, `Velocidade ([%d%,%.]+)` | `(%d+)%s*%-%s*(%d+) Damage`, `Speed ([%d%,%.]+)` |

**Notas:**
- Números decimais: normalizar vírgula→ponto (`string.gsub(numStr, ",", ".")`) antes de `tonumber`.
- Linhas "Equip:" / "Equipar:" / "Uso:" / "Use:" também contêm stats — **incluir** (ao contrário do `ParseItemData`, que as separa em `desc`).
- Linhas a **ignorar**: nome do item (linha 1), `Preço de Venda/Sell Price`, `Durabilidade/Durability`, `Vinculado/Soulbound`, `Único/Unique`, `Requer/Requires`, `Classes:/Classes:`, `Chance ao acertar:` (proc — não é stat comparável; manter fora da v1).
- Armas sem stats de atributo ainda geram diff de `dps/minDmg/maxDmg/speed`.

**Score para slots duais:** `score(stats) = str+agi+sta+int+spi + armor*0.1 + ap*0.5 + spellDmg + healing + dps*5`. O equipado com **menor score** é o alvo da comparação. (Heurística simples, documentada e suficiente para "melhor upgrade possível".)

### 2.5. Estrutura da seção dinâmica (frames, anchors, show/hide)

Criada **uma única vez** em `CreateStatsAndBuffsColumn` (linhas 1135–1255), logo após `statDiv`, e reutilizada:

```lua
-- Dentro de CreateStatsAndBuffsColumn, após statDiv (linha ~1171):
compareHeader  -- FontString "|cffffcc00⚔️ COMPARAÇÃO|r" (ApplyFont header)
compareDivTop  -- Texture divisória 1px (igual statDiv)
compareLines = {}  -- pool de até 8 FontStrings (bodyFont, statSize)
compareDivBottom -- Texture divisória 1px
-- Todos criados com :Hide() inicial.
```

**Re-anchor para empurrar buffs (solução sem recriar frames):**

- Estado normal: `buffHeader:SetPoint("TOPLEFT", statDiv, "BOTTOMLEFT", 0, -6)` (linha 1175 — guardar como âncora original).
- Estado comparação: `buffHeader:ClearAllPoints(); buffHeader:SetPoint("TOPLEFT", compareDivBottom, "BOTTOMLEFT", 0, -6)`; `compareHeader` ancorado em `statDiv`; linhas empilhadas; `compareDivBottom` fecha a seção.
- Restauração: reverter `buffHeader` para `statDiv` e `Hide()` em todos os elementos da seção.
- **Pool fixo de 8 linhas** evita criação/destruição por frame (GC do 1.12 é sensível); linhas não usadas ficam `Hide()`.

**Cores de diff (padrão do addon):**
- Verde: `|cff33ff33` (+X) • Vermelho: `|cffff4444` (−X) • Branco: `|cffffffff` (base).
- Formato linha principal: `"|cffffffffForça:|r 210 |cff33ff33(+12)|r"`.

### 2.6. Pontos de integração no `MainMenu.lua` existente

| # | Local | Alteração |
|---|---|---|
| 1 | Após `UpdateStatsAndBuffs` (~linha 1389) | **Bloco novo "FASE 14"**: `statCompareCache`, `compareState`, `GetCompareSlotForEquipLoc`, `ScoreStats`, `ParseItemStats`, `ShowCompare`, `HideCompare`, `RefreshCompareSection` |
| 2 | `CreateStatsAndBuffsColumn` (~linha 1171, após `statDiv`) | Criar `compareHeader`, `compareDivTop`, pool `compareLines[8]`, `compareDivBottom` (todos `Hide()`); guardar `container.compareUI = {...}` |
| 3 | `grid.onSlotFocused` da bag (linha 2872) | Após `detailCard:ShowItem` + TryOn: `if equipável → MainMenu:ShowCompare(itemData) else → MainMenu:HideCompare()` |
| 4 | `OnEnter` dos botões de equipamento (linha 1047) | Opcional v1: **não** comparar ao hover em item equipado (só bag→equipado). Manter `ShowEquipSlot` inalterado |
| 5 | Slot vazio / consumível (`else` linha 2883) | Chamar `MainMenu:HideCompare()` + `RestorePlayerModel()` (já existe) |
| 6 | `UpdateStatsAndBuffs` (linha 1257) | **Guardar textos base** em `compareState.baseTexts` a cada refresh; se `compareState.active`, reaplicar diff por cima (evita que o refresh periódico apague o verde/vermelho). **Não** mudar assinatura da função |
| 7 | Fechamento do menu / troca de aba | `HideCompare()` ao `Hide()` do menu (evita seção presa visível) |
| 8 | Eventos `BAG_UPDATE` / `UNIT_INVENTORY_CHANGED` | Frame dedicado só para `statCompareCache = {}` (+ `HideCompare()` se inventário mudou com comparação ativa) |

### 2.7. O que NÃO fazer (limites da v1)

- Sem tooltip flutuante de comparação (todo diff vive na coluna de stats — decisão aprovada).
- Sem diff nas linhas HP/Recurso (valores dinâmicos de combate; parsing de `+Vida/+Mana` é volátil — manter branco).
- Sem comparação de `Chance ao acertar` (procs) nem resistências.
- Sem alterar `DetailCard`, `ParseItemData`, grid ou paginação.
- Sem som novo; sem config nova (pode ir para ConfigFrame em fase futura).

---

## 3. Plano de Implementação em 8 Passos Incrementais e Testáveis

> Cada passo é **independente e testável in-game com `/reload`**, termina numa **PARADA CRÍTICA** com resultado esperado exato, e **não inclui commit/push**. Se um passo depende de outro, eles foram fundidos num único passo.

---

### **PASSO 1: Infraestrutura de Parsing e Cache (puro Lua, sem UI)** `[STATUS: ⏳ PENDENTE]`

#### Objetivo
Criar as funções auxiliares de parsing de stats via `scanTip` e o sistema de cache por `itemLink`, sem tocar em nenhuma UI. Tudo testável via `/script` no chat.

#### Tarefas
1. Criar bloco `-- FASE 14: Sistema de Comparação` em `UI/MainMenu.lua` após `UpdateStatsAndBuffs` (após linha ~1389).
2. Criar `MainMenu.statCompareCache = {}` e `MainMenu.compareState = { active=false, hoveredLink=nil, targetSlot=nil, baseTexts={} }`.
3. Criar `MainMenu:ParseItemStats(itemLink)`:
   - Aceita link completo ou `rawLink`; usa `scanTip:SetHyperlink`.
   - Percorre `ConsoleModeMMScanTooltipTextLeft1..N` com padrões bilíngues PT-BR + EN (§2.4).
   - Retorna tabela completa zerada (nunca `nil`); grava no cache antes de retornar.
   - Hit de cache: retorna `statCompareCache[itemLink]` direto.
4. Criar `MainMenu:GetCompareSlotForEquipLoc(equipLoc)` com a tabela §2.2 (retorna `invSlotID` único, `{id1,id2}` para duais, ou `nil`).
5. Criar `MainMenu:ScoreStats(stats)` (heurística §2.4).
6. Validar sintaxe: `luac -p UI/MainMenu.lua` (Lua 5.0, sem `#`).

#### Arquivos Modificados
- `UI/MainMenu.lua` (bloco novo após linha ~1389; nenhuma função existente alterada).

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload` no jogo.
2. Equipe qualquer arma/armadura com stats.
3. Executar no chat:
   ```
   /script local s = MainMenu:ParseItemStats(GetInventoryItemLink("player", 16)); print("STR:", s.str, "STA:", s.sta, "DPS:", s.dps)
   ```
4. Executar de novo o mesmo comando (deve vir do cache, mesmo resultado).
5. Executar:
   ```
   /script print(MainMenu:GetCompareSlotForEquipLoc("INVTYPE_FINGER")); print(MainMenu:GetCompareSlotForEquipLoc("INVTYPE_HEAD")); print(MainMenu:GetCompareSlotForEquipLoc("INVTYPE_BAG"))
   ```

**Resultado esperado:**
- Passo 3 imprime os stats reais da arma equipada (ex: `STR: 5 STA: 0 DPS: 12.5`). Segundo run idêntico, sem erro.
- Passo 5 imprime tabela `{11,12}` (dual), `1` (head) e `nil` (bag).

**O que NÃO deve acontecer:** erros de Lua no chat, `nil` em stats que existem visivelmente no tooltip do item, travamento no `/reload`.

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 2: Detecção de Slot + Cálculo de Diff (log no chat, sem UI)** `[STATUS: ⏳ PENDENTE]`

#### Objetivo
Conectar `itemData` da bag → slot(s) de destino → diff numérico, provando a lógica de comparação fim a fim **antes** de mexer em qualquer pixel. O resultado aparece como texto no chat.

#### Tarefas
1. Criar `MainMenu:GetCompareTarget(itemData)`:
   - Lê `itemData.equipLoc` (fallback `itemEquipLoc`, depois `GetItemInfo` se vazio).
   - Se não-equipável (`""`, `nil`, `INVTYPE_BAG`, `INVTYPE_AMMO`, `INVTYPE_QUIVER`, `INVTYPE_TABARD`) → retorna `nil`.
   - Se dual (`FINGER`/`TRINKET`): parseia os dois equipados (+ slot vazio = tabela zerada), escolhe o de **menor `ScoreStats`**; retorna `{ slotID, equippedLink }`.
   - Demais: retorna `{ slotID, GetInventoryItemLink("player", slotID) }` (link pode ser `nil` = slot vazio).
2. Criar `MainMenu:ComputeCompareDiff(itemData)`:
   - `newStats = ParseItemStats(itemData.link ou rawLink)`, `oldStats = ParseItemStats(equippedLink)` (ou tabela zerada se slot vazio).
   - Retorna `{ diffs = {str=+12, ...}, newStats, oldStats, slotID }` (só chaves com `new ~= old` entram em `diffs`).
3. Hook **temporário de debug** em `grid.onSlotFocused` (linha ~2872): após o bloco TryOn existente, `if equipável → ComputeCompareDiff + print no chat` (`DEFAULT_CHAT_FRAME:AddMessage` com resumo `Força +12, Vigor -5`); senão, imprime `[Compare] item não comparável`.
4. `luac -p` antes do `/reload`.

#### Arquivos Modificados
- `UI/MainMenu.lua` (bloco FASE 14 + ~6 linhas de debug dentro do `onSlotFocused` existente).

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload`, abrir o menu (`/cm menu`), aba Bolsas.
2. Navegar com D-Pad sobre uma **arma/armadura com stats** → chat deve mostrar ex: `[Compare] Slot 5: Força +12, Vigor -5`.
3. Navegar sobre **consumível/material/Hearthstone** → chat mostra `[Compare] item não comparável`.
4. Navegar sobre **anel** com dois anéis equipados → chat mostra diff contra o pior (desequipe o melhor anel e confirme que o diff muda de alvo).
5. Slot de destino **vazio** (ex: sem capa) + hover em capa na bag → todos os stats aparecem como positivos.

**Resultado esperado:** diffs numéricos corretos conferindo com leitura manual dos dois tooltips (equipado vs. bag).

**O que NÃO deve acontecer:** nenhuma mudança visual ainda (coluna continua branca); nenhum erro ao focar slot vazio do grid.

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 3: Diff Visual na Coluna de Stats Principais (verde/vermelho)** `[STATUS: ⏳ PENDENTE]`

#### Objetivo
Aplicar o diff do Passo 2 nas 8 linhas fixas (`HP, Recurso, Força, Agi, Vigor, Int, Espírito, Armadura`), colorindo de verde/vermelho, e restaurar ao sair do hover. **Remove** os prints de debug do Passo 2.

#### Tarefas
1. Criar `MainMenu:ShowCompare(itemData)`:
   - Chama `GetCompareTarget` (se `nil` → `HideCompare()` e retorna).
   - Chama `ComputeCompareDiff`; guarda `compareState = {active=true, hoveredLink, targetSlot}`.
   - Para cada uma das 8 chaves: monta texto `Base (+X)` / `Base (-X)` / `Base` usando `UnitStat`/`UnitArmor`/`UnitHealth` como base e `diffs` como delta; aplica cores `|cff33ff33` / `|cffff4444`.
   - HP e Recurso: sempre re-render branco (sem diff na v1, mas reescritos para manter formato após hover).
2. Criar `MainMenu:HideCompare()`:
   - Se `not active` → retorna imediatamente (idempotente).
   - Re-executa `UpdateStatsAndBuffs()` (restaura textos brancos) e marca `active=false`.
3. Proteger `UpdateStatsAndBuffs`: ao final, se `compareState.active` e `hoveredLink` válido, reaplicar `ShowCompare` por cima (evita refresh periódico apagando as cores). Implementar via flag, sem mudar a assinatura.
4. Substituir o debug do Passo 2 no `onSlotFocused` (linha ~2872) pela chamada real: `if itemData e não vazio → ShowCompare(itemData) else → HideCompare()`.
5. `luac -p` antes do `/reload`.

#### Arquivos Modificados
- `UI/MainMenu.lua` (bloco FASE 14 + `onSlotFocused` + final de `UpdateStatsAndBuffs`).

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload`, abrir o menu, aba Bolsas.
2. Focar peça **melhor** que a equipada → linha correspondente fica verde: ex `Força: 210 (+12)`.
3. Focar peça **pior** → linha fica vermelha: ex `Vigor: 190 (-5)`.
4. Focar peça **igual** no stat → linha branca sem sufixo.
5. Mover foco para **consumível / slot vazio** → todas as linhas voltam ao branco imediatamente.
6. Aguardar ~30s com hover ativo (refresh de buffs) → cores **permanecem** (não piscam nem somem).

**Resultado esperado:** cores exatas, sufixos `(+X)`/`(-X)` corretos, restauração instantânea.

**O que NÃO deve acontecer:** HP/Recurso coloridos; linhas presas em verde após sair do hover; erros ao trocar de aba com comparação ativa.

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 4: Seção Dinâmica "⚔️ COMPARAÇÃO" (estrutura + show/hide, ainda vazia)** `[STATUS: ⏳ PENDENTE]`

#### Objetivo
Criar os frames da seção (header, divisórias, pool de 8 linhas) e o mecanismo de **re-anchor dos buffs** (empurra para baixo / restaura), sem preencher conteúdo ainda. Valida o layout isoladamente.

#### Tarefas
1. Em `CreateStatsAndBuffsColumn` (após `statDiv`, ~linha 1171):
   - Criar `compareDivTop` (textura 1px), `compareHeader` (FontString `|cffffcc00⚔️ COMPARAÇÃO|r`), pool `compareLines[8]` (FontStrings `Hide()`), `compareDivBottom` (textura 1px).
   - Guardar em `container.compareUI`; largura = `CFG.StatsAndBuffs.width` (150px); fonte `bodyFontFile/statSize`.
   - **Não alterar** a âncora original do `buffHeader` (continua em `statDiv` por padrão).
2. Criar `MainMenu:RefreshCompareSection()`:
   - `if not active → Hide() tudo + re-ancorar buffHeader em statDiv; return`.
   - `if active (modo teste deste passo) → Show() header + 1 linha placeholder "|cff888888(nenhum stat secundário)|r" + re-ancorar buffHeader em compareDivBottom`.
3. Integrar: `ShowCompare` chama `RefreshCompareSection()` ao final; `HideCompare` também.
4. `luac -p` antes do `/reload`.

#### Arquivos Modificados
- `UI/MainMenu.lua` (`CreateStatsAndBuffsColumn` + bloco FASE 14).

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload`, abrir o menu.
2. Focar item **equipável** na bag → seção `⚔️ COMPARAÇÃO` aparece entre stats e buffs, com placeholder cinza; **buffs descem visivelmente**.
3. Mover para consumível/slot vazio → seção **some**, buffs **sobem** de volta ao lugar original (pixel a pixel, sem sobreposição nem buraco).
4. Repetir 5x rapidamente (stress de show/hide) → sem flicker, sem linhas fantasmas.
5. Fechar e reabrir o menu com hover ativo → estado limpo (sem seção presa).

**Resultado esperado:** push/pull dos buffs suave e reversível; placeholder visível só durante hover em equipável.

**O que NÃO deve acontecer:** buffs sobrepostos ao header, seção visível sem hover, erro de anchor (`ClearAllPoints` faltando).

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 5: Preenchimento da Seção com Stats Secundários** `[STATUS: ⏳ PENDENTE]`

#### Objetivo
Trocar o placeholder pela lista real de diffs secundários (só os que mudam), com cores e formatação final.

#### Tarefas
1. Estender `RefreshCompareSection()` para consumir `compareState.diffs`:
   - Ordem fixa de exibição: `DPS`, `Dano` (min–max), `Velocidade`, `Poder de Ataque`, `Hit%`, `Crit%`, `Dodge%`, `Block%`, `Spell Damage`, `Healing`, `Armadura*`, `HP*`, `Mana*` (*só se vierem de `Equip:` — ex: +100 Vida).
   - Regra de visibilidade: **só entra na lista se `new ~= old`**; verde se `new > old` (ou `old == 0` → sufixo `(novo)` quando aplicável), vermelho se menor.
   - Formatação: `DPS +3.2`, `Dano 44-115 (+8-20)`, `Velocidade 1.90 (-0.20)`, `+1% Crít.`, `+24 Poder de Ataque`, `+9 Dano Mágico`, `+22 Cura`.
   - Se **nenhum** secundário mudou → mostra 1 linha cinza `(stats iguais)` em vez de seção vazia (feedback explícito).
   - Pool de 8 linhas: se diffs > 8, mostra os 8 primeiros por prioridade da ordem fixa; linhas excedentes `Hide()`.
2. Re-ancorar `compareDivBottom` após a última linha visível; buffs continuam empurrados.
3. `luac -p` antes do `/reload`.

#### Arquivos Modificados
- `UI/MainMenu.lua` (só `RefreshCompareSection` no bloco FASE 14).

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload`, focar **arma melhor** na bag → seção mostra ex: `DPS +3.2` verde, `Dano 44-115 (+8-20)` verde.
2. Focar arma **pior** → mesmos stats em vermelho com `(-X)`.
3. Focar armadura com `+1% Crít.` que o equipado não tem → linha verde com `(novo)`.
4. Focar item cujos secundários são **idênticos** → seção mostra `(stats iguais)` em cinza (ou só diffs principais coloridos, sem linhas falsas).
5. Item com **8+ diffs** → no máximo 8 linhas, sem estourar a coluna nem cobrir os buffs.

**Resultado esperado:** apenas stats que mudam, cores corretas, formatação legível em 150px sem corte (`SetJustifyH LEFT`, sem `...`).

**O que NÃO deve acontecer:** stat igual aparecendo na seção; número com vírgula quebrando `tonumber`; linha cortada pela borda da coluna.

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 6: Restauração Total ao Sair do Hover + Troca de Aba + Fechamento** `[STATUS: ⏳ PENDENTE]`

#### Objetivo
Blindar todos os caminhos de saída para que **nenhum** estado de comparação vaze (cores presas, seção fantasma, anchor quebrado).

#### Tarefas
1. Revisar `HideCompare()` para limpeza total e idempotente:
   - `active=false, hoveredLink=nil, targetSlot=nil, diffs=nil`.
   - `Hide()` em `compareHeader/divTop/divBottom/todas as compareLines`.
   - Re-ancorar `buffHeader → statDiv` (âncora original, offset `-6`).
   - Re-executar `UpdateStatsAndBuffs()` (textos brancos).
2. Chamar `HideCompare()` em todos os exits:
   - `onSlotFocused` com `itemData == nil` / `isEmpty` (já parcial — confirmar).
   - `OnLeave` dos botões de equipamento (linha ~1053, hoje vazio) → **não** ativa nada, mas garante que sair do equip não deixa rastro (defensivo).
   - Troca de aba (`SelectTab` / equivalente) e `MainMenu:Hide()` (fechamento do menu).
   - `BAG_UPDATE` / `UNIT_INVENTORY_CHANGED` (via frame dedicado — ver Passo 7; aqui ao menos o hook de Hide).
3. `luac -p` antes do `/reload`.

#### Arquivos Modificados
- `UI/MainMenu.lua` (bloco FASE 14 + `onSlotFocused` + `OnLeave` equip + `Hide`/troca de aba).

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload`; focar item equipável (seção visível, stats verdes) → mover para **slot vazio** → tudo branco, seção some, buffs sobem.
2. Com comparação ativa, **trocar de aba** (Bolsas→Magias→Bolsas) → estado limpo.
3. Com comparação ativa, **fechar o menu** (`B`) e reabrir → estado limpo.
4. Com comparação ativa, **equipar o item** via `(A)` → após equipar, hover mostra diff zero/branco (já que agora é o equipado).
5. Repetir 1–4 com **anéis/berloques**.

**Resultado esperado:** impossível deixar a UI "presa" em estado de comparação por qualquer caminho.

**O que NÃO deve acontecer:** seção visível com menu fechado; `UpdateStatsAndBuffs` errorando com `compareUI == nil` (guard para menu ainda não construído).

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 7: Lógica de Slots Duais (anéis + berloques = pior dos dois)** `[STATUS: ⏳ PENDENTE]`

#### Objetivo
Implementar e validar isoladamente a regra "compara contra o pior dos dois", incluindo slots vazios e cache.

#### Tarefas
1. Finalizar ramo dual em `GetCompareTarget` (se ainda parcial do Passo 2):
   - Resolver `Finger0Slot` (11) + `Finger1Slot` (12); `Trinket0Slot` (13) + `Trinket1Slot` (14).
   - Parsear ambos (slot vazio = tabela zerada com `isEmpty=true`).
   - Alvo = menor `ScoreStats`; desempate: **slot 1** (Finger0/Trinket0).
   - Retornar também `altSlotID` + `altScore` para debug/exibição futura.
2. Indicar o alvo na seção: primeira linha de contexto cinza `↳ vs. [Nome do item equipado]` (nome via `GetItemInfo`), para o jogador saber contra qual dos dois comparou.
3. Criar frame de eventos `ConsoleModeMM_CompareEvents`: `BAG_UPDATE` + `UNIT_INVENTORY_CHANGED` → `statCompareCache = {}` (wipe) + se `active`, `HideCompare()` (inventário mudou sob o hover).
4. `luac -p` antes do `/reload`.

#### Arquivos Modificados
- `UI/MainMenu.lua` (bloco FASE 14: `GetCompareTarget`, `RefreshCompareSection` linha de contexto, frame de eventos).

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload`; equipar **dois anéis diferentes** (um bom, um ruim); focar anel novo na bag → seção mostra `↳ vs. [nome do anel ruim]` e diffs calculados contra ele.
2. **Desequipar** o anel ruim (slot vazio) → focar o mesmo anel da bag → diff mostra tudo como ganho/`(novo)` vs. slot vazio.
3. Repetir 1–2 com **berloques**.
4. Mover item na bag (dispara `BAG_UPDATE`) com comparação ativa → cache limpo sem erro; próximo hover re-parseia corretamente.
5. `/script print(table.getn(...))` — N/A; em vez disso: `/script local c=0; for _ in pairs(MainMenu.statCompareCache) do c=c+1 end; print("cache:", c)` antes e depois de mover item (deve zerar e recrescer).

**Resultado esperado:** alvo sempre o pior; slot vazio tratado como upgrade total; cache invalidado corretamente.

**O que NÃO deve acontecer:** comparar contra o melhor (upgrade subestimado); erro quando ambos os slots vazios; `↳ vs.` mostrando nome errado/nil.

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 8: Polimento Final — Edge Cases, Performance e Validação Completa** `[STATUS: ⏳ PENDENTE]`

#### Objetivo
Fechar a FASE 14 com tratamento de casos extremos, checagem de performance/legibilidade e bateria final de testes. Sem funcionalidade nova.

#### Tarefas
1. **Edge cases:**
   - Item da bag **igual ao equipado** (mesmo link): diff zero → linhas brancas + `(stats iguais)`.
   - `2HWEAPON` na bag com off-hand equipado: comparar só main (16); **não** sugerir diff no off-hand; documentar no código.
   - `INVTYPE_TABARD` / camisas: nunca ativam comparação.
   - Tooltip com `DPS` em formato `12,5` (vírgula PT-BR): normalizar antes de `tonumber`.
   - Item com `Use:` (consumível equipável, ex: berloque com uso): stats de `Equip:` entram no diff; texto de `Uso:` ignorado (não é stat).
   - Menu aberto sem `compareUI` (outras abas): todos os entry points com `guard if not self.statsAndBuffs.compareUI then return end`.
2. **Performance:**
   - Confirmar zero alocação por frame: pool fixo, cache hit, nenhum `CreateFrame` dentro de `ShowCompare`/`RefreshCompareSection`.
   - `BAG_UPDATE` faz wipe (não re-parse): custo O(1).
3. **Legibilidade 150px:** revisar strings longas (`Poder de Ataque` → `P. de Ataque` se cortar); garantir `SetJustifyH("LEFT")` e altura de linha sem sobreposição.
4. **Limpeza:** remover qualquer `print`/debug restante; comentar bloco FASE 14 em PT-BR; `luac -p` final.
5. Atualizar `docs/plano_de_feature_MAIN_MENU.md` FASE 14 → `[STATUS: ✅ CONCLUÍDA]` (só após aprovação do usuário neste passo).

#### Arquivos Modificados
- `UI/MainMenu.lua` (ajustes finos no bloco FASE 14).
- `docs/plano_de_feature_MAIN_MENU.md` (status da FASE 14).

#### Validação (PARADA CRÍTICA — bateria final)
**Como testar:**
1. `/reload`; percorrer **todos os tipos**: elmo, peito, arma 1H, arma 2H, escudo, anel ×2, berloque ×2, capa, pescoço, ombros, botas → diffs corretos em cada um.
2. Itens **não comparáveis** (comida, reagente, Hearthstone, projétil, bolsa): nenhuma mudança visual, nenhum erro.
3. Stress: navegar rápido por 20+ itens seguidos → sem lag, sem erro, sem seção fantasma.
4. Recarregar com buffs ativos (8+) + comparação ativa → buffs descem sem sobrepor a seção e sobem ao sair.
5. `/reload` final de confirmação com o usuário olhando.

**Resultado esperado:** FASE 14 completa, estável e legível; usuário aprova explicitamente.

**O que NÃO deve acontecer:** qualquer erro de Lua em qualquer cenário acima; qualquer texto cortado ou sobreposto.

**Após aprovação: aguardar comando explícito do usuário para commit/push. NÃO commitar por conta própria.**

---

## 4. Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Padrões regex não casam com linhas reais do Turtle (PT-BR custom) | Alta | Passo 1 valida via `/script` com itens reais; padrões ajustados antes de qualquer UI; fallback: linha não parseada = stat 0 (nunca erro) |
| `SetHyperlink` falha para item não cacheado | Média | `pcall` + fallback `SetBagItem(bagID, slotID)` usando `itemData.bagID/slotID` quando disponível |
| Números com vírgula decimal PT-BR quebram `tonumber` | Média | Normalizar `"," → "."` em todo número capturado |
| Refresh periódico de buffs apaga cores | Média | Passo 3: reaplicação por cima via `compareState.active` (flag, sem timer novo) |
| Coluna de 150px corta textos longos | Média | Passo 8: abreviações + teste visual; pool com `SetJustifyH LEFT` |
| `BAG_UPDATE` dispara em rajada (loot) e limpa cache em loop | Baixa | Wipe O(1) é barato; re-parse é lazy (só no próximo hover) |
| Dual-slot confunde o jogador (contra qual comparou?) | Baixa | Linha de contexto `↳ vs. [nome]` (Passo 7) |

---

## 5. Critérios de Aceite da FASE 14

- [ ] Hover em qualquer equipável colore os 8 stats principais (verde/vermelho/branco) corretamente.
- [ ] Seção `⚔️ COMPARAÇÃO` aparece só ao hover, só com stats que mudam, empurrando buffs.
- [ ] Saída do hover restaura tudo por todos os caminhos (slot vazio, consumível, troca de aba, fechar menu, equipar).
- [ ] Anéis/berloques comparam contra o pior dos dois, com indicação `↳ vs.`.
- [ ] `luac -p UI/MainMenu.lua` limpo; zero erros de Lua em todos os cenários; sem regressão nas FASEs 1–13.
- [ ] Usuário validou cada PARADA CRÍTICA in-game e aprovou explicitamente.

---

## 6. Histórico de Execução

| Passo | Status | Data de validação | Observações |
|---|---|---|---|
| 1 — Infraestrutura de Parsing e Cache | ⏳ PENDENTE | — | |
| 2 — Detecção de Slot + Diff (log chat) | ⏳ PENDENTE | — | |
| 3 — Diff Visual nos Stats Principais | ⏳ PENDENTE | — | |
| 4 — Seção Dinâmica (estrutura vazia) | ⏳ PENDENTE | — | |
| 5 — Preenchimento Stats Secundários | ⏳ PENDENTE | — | |
| 6 — Restauração Total | ⏳ PENDENTE | — | |
| 7 — Slots Duais | ⏳ PENDENTE | — | |
| 8 — Polimento Final | ⏳ PENDENTE | — | |
