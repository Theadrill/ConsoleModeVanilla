# Plano de Feature: Quest Item Distributor (L2+R2 Cluster)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido usar operadores de Lua 5.1+ (como `#table`, usar `table.getn(t)` ou `getn(t)`).
> 3. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via `luac -p` antes de qualquer teste.
> 4. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem o comando e autorização explícita do usuário.
> 5. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem parada crítica, validação do usuário no jogo via `/reload`, e aguardar feedback/aprovação.

---

## 1. Visão Geral

Este feature adiciona um **distribuidor automático de itens de missão** que varre as bags do player em busca de itens tipo `quest` usáveis, e os distribui automaticamente nos slots do cluster L2+R2 (página 5), na ordem:

**Slot Order:**
```
Slot 39 (B) → Slot 38 (Y) → Slot 37 (X) → Slot 43 (D-UP) → Slot 44 (D-DOWN) → Slot 45 (D-LEFT) → Slot 46 (D-RIGHT)
```

**Regras:**
- ⚠️ **Slot 40 (L2+R2+A)** é **NUNCA** tocado — reservado para ring menu
- ⚠️ **Outras páginas (1-4)** e slots fora do cluster L2+R2 são **ignoradas**
- Se todos os 7 slots estão cheios com itens válidos → para (não coloca mais)
- Prioridade é **FIFO** (ordem de varredura das bags), não por rarity

### 1.1. Comportamento Esperado

| Estado | Ação |
|--------|------|
| Item quest novo aparece na bolsa | → Coloca no primeiro slot vago (39→38→37→43...) |
| Slot ocupado, item ainda existente | → Mantém, pula para próximo slot |
| Slot ocupado, item sumiu da bolsa | → Limpa slot, coloca novo item |
| 7 slots cheios com itens válidos | → Para, não usa outros slots |
| Sem itens quest usáveis | → Limpa todos os 7 slots |

---

## 2. Arquitetura Técnica

### 2.1. APIs WoW 1.12 Necessárias

| API | Uso | Disponível no 1.12 |
|-----|-----|---------------------|
| `GetContainerNumSlots(bagID)` | Numero de slots por bag | ✅ |
| `GetContainerItemInfo(bagID, slotID)` | Textura, count, locked, quality, readable | ✅ |
| `GetContainerItemLink(bagID, slotID)` | Item link (contém itemID) | ✅ |
| `GetItemInfo(itemID\|itemLink)` | Nome, tipo, subtipo, qualidade, equipLoc | ✅ |
| `GetActionInfo(slot)` | Verifica se slot tem item, qual itemID | ✅ |
| `HasAction(slot)` | Se slot tem algo | ✅ |
| `PickupContainerItem(bagID, slotID)` | Pega item da bag | ✅ |
| `PlaceAction(slot)` | Coloca item no slot da action bar | ✅ |
| `ClearSlot(slot)` | Limpa slot da action bar | ✅ |
| `ClearCursor()` | Limpa cursor | ✅ |
| `BAG_UPDATE` (evento) | Dispara quando bag muda | ✅ |
| `UNIT_INVENTORY_CHANGED` (evento) | Dispara quando inventário muda | ✅ |
| `CHAT_MSG_LOOT` (evento) | Mensagem de loot no chat | ✅ |

### 2.2. Integração com Código Existente

O addon já possui em `UI/BagPicker.lua`:
- `BP:GetUsableItems()` — escaneia bags 0-4, retorna lista de itens usáveis
- `BP:IsUsableItem(itemLink, bagID, slotID, readable)` — filtra itens por tipo/subtipo/tooltip
- `BP:ApplyItemBinding(...)` — já faz `PickupContainerItem` + `PlaceAction`

**Reutilizaremos** `BP:IsUsableItem()` e partes de `BP:GetUsableItems()` para filtragem de quest items.

### 2.3. Estrutura de Dados

```lua
-- Adicionar em CM (Core.lua) ou novo módulo
CM.questItemDistributor = {
    TARGET_SLOTS = {39, 38, 37, 43, 44, 45, 46},  -- B, Y, X, DUP, DDOWN, DLEFT, DRIGHT
    SCAN_INTERVAL = 3,  -- segundos entre scans
    slotMap = {},  -- [slot] = itemID atualmente no slot
    eventFrame = nil,
    updateTimer = 0,
}
```

### 2.4. Fluxo de Execução

```
EVENTOS: BAG_UPDATE / UNIT_INVENTORY_CHANGED / CHAT_MSG_LOOT / PLAYER_ENTERING_WORLD
    ↓
Timer 3s: DistributeQuestItems()
    ↓
GetUsableQuestItems() → lista FIFO de items [item1, item2, ...]
    ↓
FOR item in questItems:
    FOR slot in TARGET_SLOTS:
        slot vazio? → coloca item
        slot ocupado? → itemID existe na bolsa? → sim: mantém | não: limpa+coloca novo
    ↓
Se 7 slots cheios → STOP
```

---

## 3. Plano de Implementação em 3 Passos Incrementais e Testáveis

### **PASSO 1: Infraestrutura + Scan de Bags**  `[STATUS: PENDENTE]`

#### Objetivo
Criar o módulo `QuestItemDistributor`, frame de eventos, timer e função de scan de itens quest usáveis. Validar que o scan encontra itens corretos no chat.

#### Tarefas
1. Criar `UI/QuestItemDistributor.lua`:
   - Module skeleton: `CM.questItemDistributor = {}`
   - `TARGET_SLOTS = {39, 38, 37, 43, 44, 45, 46}`
   - `SCAN_INTERVAL = 3`
   - `CM.questItemDistributor.slotMap = {}`
2. Criar event frame (herdando padrão de `Core.lua`):
   - Registrar: `BAG_UPDATE`, `UNIT_INVENTORY_CHANGED`, `PLAYER_ENTERING_WORLD`, `CHAT_MSG_LOOT`
   - `OnEvent` → marca dirty flag
3. Criar `GetUsableQuestItems()`:
   - Reutiliza `BP:GetUsableItems()` (já existe)
   - Filtra apenas itens com `itemType == "quest"` (já filtrado por `IsUsableItem`)
   - Retorna lista FIFO: `{ bagID, slotID, itemLink, itemID }`
4. Integrar no `Core.lua`:
   - `if CM.questItemDistributor and CM.questItemDistributor.Initialize then CM.questItemDistributor:Initialize() end`
   - No bloco `PLAYER_ENTERING_WORLD`
5. Debug: `print` temporário listando itens encontrados via `/reload`
6. Validar sintaxe: `luac -p UI/QuestItemDistributor.lua`

#### Arquivos Modificados
- `UI/QuestItemDistributor.lua` (NOVO)
- `Core.lua` (1 linha: registra módulo no PLAYER_ENTERING_WORLD)
- `ConsoleModeVanilla.toc` (adiciona `UI\QuestItemDistributor.lua`)

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload` no jogo.
2. Abrir bolsa com item de quest usável.
3. Ver no chat (debug print) a lista de items encontrados: `[CM-Quest] Found: <itemName> (bag=<bagID> slot=<slotID>)`.
4. Garantir que itens NÃO quest são ignorados.
5. Garantir que itens quest NÃO usáveis são ignorados.

**Resultado esperado:** Scan encontra todos os itens quest usáveis na bolsa, imprime no chat, zero erros de Lua.

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 2: Distribuição nos Slots + Sync** `[STATUS: PENDENTE]`

#### Objetivo
Implementar a lógica de distribuição: colocar itens nos 7 slots na ordem definida, verificar se itens existem ainda, limpar slots órfãos.

#### Tarefas
1. Criar `DistributeQuestItems()`:
   - Chama `GetUsableQuestItems()`
   - Se lista vazia → limpa todos os 7 slots
   - Se lista não vazia → distribui na ordem `TARGET_SLOTS`
2. Para cada slot:
   - `slot vazio?` → `PickupContainerItem(bag,slot)` + `PlaceAction(slotN)` + `ClearCursor()`
   - `slot cheio?` → `GetActionInfo(slot)` → compara itemID com itens na bolsa
     - ✅ Encontrado → mantém
     - ❌ Não encontrado → `ClearSlot(slot)` + coloca novo item
3. Track `slotMap[slot] = itemID` para comparação rápida
4. OnUpdate timer: chama `DistributeQuestItems()` a cada 3s
5. Remover debug prints do Passo 1
6. Validar sintaxe: `luac -p UI/QuestItemDistributor.lua`

#### Arquivos Modificados
- `UI/QuestItemDistributor.lua` (expande funcionalidades)

#### Validação (PARADA CRÍTICA)
**Como testar (com itens quest na bolsa):**
1. `/reload`, jogador com 2-3 itens de quest usáveis.
2. Abrir bolsa → observar slots 39, 38, 37 preenchidos com itens.
3. Destruir/consurmar um item → slot é limpo e reutilizado.
4. Fechar todas as bags → `/reload` → slots são limpos (ClearSlot).
5. Colocar item em slot 40 (A) → **NÃO deve ser tocado**.
6. Colocar item em slot 36 (outra página) → **NÃO deve ser tocado**.

**Resultado esperado:** Itens distribuídos corretamente nos 7 slots, sync automático, slots de outras páginas preservados.

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 3: Edge Cases + Performance** `[STATUS: PENDENTE]`

#### Objetivo
Tratar casos extremos, otimizar performance, e garantir estabilidade completa.

#### Tarefas
1. **Re-scan inteligente:** Só faz scan completo se `BAG_UPDATE` ou `UNIT_INVENTORY_CHANGED` disparar (não só timer).
2. **Throttle por evento:** Evita múltiplos scans em cascata (ex: loot múltiplo) — cooldown de 0.5s entre scans por evento.
3. **pcall protection:** Wrapprove `PickupContainerItem`, `PlaceAction`, `ClearSlot` em `pcall`.
4. **7 slots cheios:** Quando todos ocupados com items válidos → early-out (não varre items sobrando).
5. **Performance:** Confirmar 3s timer não causa lag; eventos síncronos são rápidos (30-60 itens max).
6. **Cleanup final:** Zero `print` debug; comentários em PT-BR; `luac -p` limpo.
7. Atualizar este doc: `PASSO 3` → `[STATUS: ✅ CONCLUÍDA]`

#### Arquivos Modificados
- `UI/QuestItemDistributor.lua` (edge cases + pcall + early-out)

#### Validação (PARADA CRÍTICA — bateria final)
**Como testar:**
1. `/reload`; abrir bolsa com 1 item de quest.
2. `PickupContainerItem` + `PlaceAction` manual → distribui automaticamente.
3. Testar **race condition**: loot rápido de 5 items → todos distribuídos sem perda.
4. Testar **slot 40 (A)**: colocar item manualmente → não é removido pelo distributor.
5. Testar **página 1 Slot 1**: colocar item manualmente → não é tocado.
6. Testar **Druid forma urso**: sem items quest → todos os 7 slots limpos.
7. Stress: abrir/fechar bags rapidamente → sem crash, sem lag.
8. `/reload` final → estado preservado (slotMap não persiste, mas redistribui corretamente).

**Resultado esperado:** Feature estável, respeita boundaries, zero regressão.

**Após aprovação: aguardar comando explícito do usuário para commit/push. NÃO commitar por conta própria.**

---

## 4. Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Player tem items quest em slots manuais (39-46) | Média | Preservar: se itemID no slot não mudou, manter. Só substituir se slot está com item "inválido" (sumiu da bolsa). |
| Race condition: loot múltiplo antes do BAG_UPDATE | Média | Timer fallback de 3s garante eventual consistency; pcall protege contra erros. |
| Performance: scan a cada 3s em máquina lenta | Baixa | Scan é O(n) em ~60 slots max; 30-60 items total. Negligível. |
| Slot 40 (A) conflitos com ring menu | Baixa | Hardcoded: `TARGET_SLOTS` nunca inclui 40. |
| Macros no slot 39-46 confundem o sistema | Baixa | `GetActionInfo` retorna actionType="macro" → tratar como não-item, limpar se não for quest item. |

---

## 5. Critérios de Aceite

- [ ] Scan de bags encontra todos os items do tipo `quest` usáveis, em ordem FIFO.
- [ ] Items distribuídos nos slots 39→38→37→43→44→45→46.
- [ ] Slot vazio recebe item; slot com item válido é preservado.
- [ ] Slot com item órfão (sumiu da bolsa) é limpo e reutilizado.
- [ ] **Slot 40 (L2+R2+A) NUNCA é tocado.**
- [ ] **Slots de outras páginas (1-36, 41-42, 47-48) NUNCA são tocados.**
- [ ] Quando não há items quest → todos os 7 slots são limpos.
- [ ] `luac -p UI/QuestItemDistributor.lua` limpo; zero erros de Lua.
- [ ] Zero regressão em `IsUsableItem()` ou `GetUsableItems()` do BagPicker.
- [ ] Usuário validou cada PARADA CRÍTICA in-game e aprovou explicitamente.

---

## 6. Histórico de Execução

| Passo | Status | Data de validação | Observações |
|---|---|---|---|
| 1 — Infra + Scan | ⏳ PENDENTE | — | A aguardar implementação |
| 2 — Distribuição + Sync | ⏳ PENDENTE | — | A aguardar Passo 1 |
| 3 — Edge Cases + Perf | ⏳ PENDENTE | — | A aguardar Passo 2 |
