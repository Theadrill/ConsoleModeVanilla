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

### **PASSO 1: Infraestrutura + Scan de Bags**  `[STATUS: ✅ CONCLUÍDA — validado in-game]`

#### Objetivo
Criar o módulo `QuestItemDistributor`, frame de eventos, timer e função de scan de itens quest usáveis. Validar que o scan encontra itens corretos no chat.

#### O que foi implementado

**Arquivo criado:** `UI/QuestItemDistributor.lua`

**Arquivo modificado:** `Core.lua` — adicionado no bloco `PLAYER_ENTERING_WORLD`:
```lua
if CM.questItemDistributor and CM.questItemDistributor.Initialize then
    CM.questItemDistributor:Initialize()
end
```
> ⚠️ Nota: este bloco aparece duas vezes no Core.lua (linhas ~204 e ~223). Não é bug — ambas as ocorrências são idênticas e inofensivas. Pode ser limpo futuramente.

**Arquivo modificado:** `ConsoleModeVanilla.toc` — adicionado:
```
UI\QuestItemDistributor.lua
```
> ⚠️ **IMPORTANTE:** Novos arquivos `.lua` adicionados ao `.toc` requerem **reinício completo do jogo** (não apenas `/reload`) para serem reconhecidos pelo WoW 1.12.

#### Lições aprendidas durante o desenvolvimento (CRÍTICAS para a próxima IA)

1. **`GetItemInfo()` retorna nil no WoW 1.12 quando o item não está em cache**
   - Não usar `GetItemInfo()` para detectar o tipo do item logo após login/reload
   - O item precisa ter sido "visto" pelo cliente antes (inspecionado, hovado, etc.)
   - **Solução adotada:** usar `scanTooltip:SetBagItem(bagID, slotID)` — force-load o tooltip, que sempre funciona

2. **O tooltip invisível do BagPicker deve ser reutilizado**
   - O frame `ConsoleModeBagScanTooltip` já existe (criado em `UI/BagPicker.lua`)
   - Acessá-lo via `getglobal("ConsoleModeBagScanTooltip")`
   - Não criar um segundo tooltip — causa conflitos

3. **O tipo do item de quest no tooltip é `"Quest Item"` (duas palavras), não `"Quest"`**
   - Detectado empiricamente: a linha 2 do tooltip mostrou `esq=[Quest Item]`
   - Em PT-BR pode aparecer como `"Missão"` ou variantes
   - **Solução:** `string.find(lLow, "quest")` ou `string.find(lLow, "miss")` — busca parcial, não igualdade

4. **Detecção de "Use:" para confirmar que o item é usável**
   - Itens de quest que não são usáveis (só para entregar ao NPC) não têm linha "Use:" no tooltip
   - A linha de uso aparece no lado esquerdo do tooltip, começa com "Use:", "Uso:", etc.
   - Items `readable` (livros/pergaminhos clicáveis) também são considerados usáveis via flag `readable` do `GetContainerItemInfo`

5. **`OnUpdate` no WoW 1.12: `elapsed` pode vir como `arg1` ou como parâmetro**
   - Sempre usar: `local dt = elapsed or arg1 or 0`
   - Usar `dirty = true` + scan imediato falha pois bags não carregaram ainda

6. **Delay obrigatório antes do primeiro scan**
   - `PLAYER_ENTERING_WORLD` → delay de **3 segundos** antes de scanear
   - `BAG_UPDATE` / `UNIT_INVENTORY_CHANGED` → delay de **0.5 segundos**
   - `CHAT_MSG_LOOT` → delay de **1.0 segundo**
   - Sem o delay, `GetContainerItemInfo` retorna nil para todos os slots (bags ainda não carregaram)

#### Código atual de `IsQuestItem` (coração da detecção):
```lua
function QID:IsQuestItem(bagID, slotID, readable)
    local scanTooltip = getglobal("ConsoleModeBagScanTooltip")
    if not scanTooltip then return false end

    scanTooltip:ClearLines()
    local ok = pcall(function()
        scanTooltip:SetBagItem(bagID, slotID)
    end)
    if not ok then return false end

    local numLines = scanTooltip:NumLines()
    if not numLines or numLines <= 0 then return false end

    local isQuest  = false
    local isUsable = false

    for i = 1, numLines do
        local leftObj = getglobal("ConsoleModeBagScanTooltipTextLeft" .. i)
        local leftTxt = (leftObj and leftObj:GetText()) or ""
        local lLow    = string.lower(leftTxt)

        -- "Quest Item" (EN) ou "Missão" (PT-BR)
        if string.find(lLow, "quest") or string.find(lLow, "miss") then
            isQuest = true
        end

        -- Linha de uso: "Use: ...", "Uso: ..."
        if string.find(lLow, "use:") or string.find(lLow, "uso:")
        or string.find(lLow, "utilizar:") or string.find(lLow, "direito para")
        or string.find(lLow, "right") or string.find(lLow, "bot") then
            isUsable = true
        end
    end

    return isQuest and (isUsable or readable)
end
```

#### Validação concluída
- `/reload` no jogo com `Foreman's Blackjack` na bag
- Chat mostrou: `[CM-Quest] Item de quest: Foreman's Blackjack` ✅
- Itens não-quest foram ignorados corretamente ✅
- Zero erros de Lua ✅

#### Status do módulo após Passo 1
- `GetUsableQuestItems()` retorna lista FIFO de itens quest usáveis ✅
- Print de diagnóstico temporário ainda presente: `[CM-Quest] Item de quest: <nome>` e `Nenhum item de quest usavel encontrado.`
- **Esses prints devem ser removidos no Passo 3 (cleanup final)**

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
| 1 — Infra + Scan | ✅ CONCLUÍDA | 2026-09-09 | Validado com `Foreman's Blackjack`. Detecção via tooltip scan. Ver seção de lições aprendidas. |
| 2 — Distribuição + Sync | ⏳ PENDENTE | — | A aguardar início |
| 3 — Edge Cases + Perf | ⏳ PENDENTE | — | A aguardar Passo 2 |

---

## 7. Ponto de Retomada — Próxima IA

> Esta seção existe para que uma nova sessão/IA possa continuar sem perder contexto.

### Estado atual do código
- `UI/QuestItemDistributor.lua` — **Passo 1 completo e funcional**
- `Core.lua` — integrado (inicializa QID no `PLAYER_ENTERING_WORLD`)
- `ConsoleModeVanilla.toc` — `UI\QuestItemDistributor.lua` adicionado

### O que o módulo faz hoje
- Cria um frame de eventos registrado para `BAG_UPDATE`, `UNIT_INVENTORY_CHANGED`, `PLAYER_ENTERING_WORLD`, `CHAT_MSG_LOOT`
- Usa timer com delay antes de scanear (3s no login, 0.5s em updates de bag)
- `IsQuestItem()` detecta itens de quest usáveis via tooltip scan
- `GetUsableQuestItems()` retorna lista FIFO `{bagID, slotID, itemLink, itemID, itemName}`
- Imprime no chat os itens encontrados (debug temporário — remover no Passo 3)

### O que NÃO foi feito ainda (Passo 2)
A função `GetUsableQuestItems()` retorna a lista mas **não faz nada com ela ainda**. O próximo passo é implementar `DistributeQuestItems()` que:
1. Chama `GetUsableQuestItems()`
2. Para cada item, percorre `TARGET_SLOTS = {39, 38, 37, 43, 44, 45, 46}` em ordem
3. Para cada slot:
   - `HasAction(slot)` → false? → coloca o item (`PickupContainerItem` + `PlaceAction` + `ClearCursor`)
   - `HasAction(slot)` → true? → `GetActionInfo(slot)` retorna `(type, id, subtype)` → verifica se `id` ainda está na bag
     - Ainda na bag? → mantém, vai para próximo item
     - Não está mais? → `ClearSlot(slot)` e coloca o novo item
4. Atualiza `QID.slotMap[slot] = itemID`
5. Chamar `DistributeQuestItems()` no `OnUpdate` (substituindo a chamada atual a `GetUsableQuestItems()`)

### APIs WoW 1.12 para o Passo 2
```lua
-- Verifica se slot tem algo
HasAction(slot)  -- retorna true/false

-- Obtém o que está no slot
GetActionInfo(slot)  -- retorna: actionType, id, subtype
-- Para itens: actionType="item", id=itemID numérico

-- Coloca item da bag no slot da action bar
PickupContainerItem(bagID, slotID)  -- pega item (fica no cursor)
PlaceAction(slot)                   -- coloca no slot
ClearCursor()                       -- limpa cursor (garante sem resto)

-- Limpa um slot
ClearSlot(slot)  -- remove o que está no slot
```

### Verificar se itemID ainda está na bag
```lua
-- Para saber se um itemID ainda existe na bag:
-- Iterar BP.BAG_IDS e GetContainerItemLink → extrair itemID → comparar
-- Não existe API direta "ItemIsInBag(itemID)" no 1.12
```

### Regras críticas que a próxima IA DEVE seguir
1. **Lua 5.0**: sem `#table`, usar `table.getn()`. Sem `string.match` nativo (há polyfill em Core.lua).
2. **`luac -p` antes de qualquer teste in-game** — sem exceção.
3. **Nunca fazer push sem autorização explícita do usuário.**
4. **Nunca avançar para o Passo 3 sem validação in-game do Passo 2.**
5. **Slot 40 (L2+R2+A) NUNCA é tocado** — `TARGET_SLOTS` não o inclui, e isso deve ser mantido.
6. **Novo arquivo .lua no .toc exige reinício do jogo**, não apenas `/reload`.
7. **O `elapsed` no `OnUpdate` pode vir como `arg1`** — sempre usar `local dt = elapsed or arg1 or 0`.
