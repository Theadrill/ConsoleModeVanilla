# Plano de Feature: Indicador de Range (Olho de Alcance)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido usar operadores de Lua 5.1+ (como `#table`, usar `table.getn(t)` ou `getn(t)`).
> 3. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 4. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem o comando e autorização explícita do usuário.
> 5. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem fazer uma parada crítica, solicitar a validação do usuário no jogo via `/reload` e aguardar seu feedback/aprovação.

---

## 1. Visão Geral

Este feature adiciona um **indicador visual de range** ao centro do ActionHUD, entre os dois clusters de botões (D-Pad esquerdo e ABXY direito). O ícone mostra ao jogador se o seu target está dentro do alcance dos seus spells ranged, usando os ícones de olho já criados:

- 👁️ **Olho aberto branco** (`icon_inrange.png`): target **dentro do range**
- 🚫 **Olho riscado branco** (`icon_outrange.png`): target **fora do range**
- **Invisível**: sem target, ou classe melee (não precisa de indicador)

### 1.1. Comportamento esperado

| Estado | Ícone |
|--------|-------|
| Sem target | Invisível |
| Target + classe ranged + target no range | Olho aberto |
| Target + classe ranged + target fora do range | Olho riscado |
| Target + classe melee | Invisível (melee sempre alcança) |

### 1.2. Layout (ASCII)

```
         Cluster Esquerdo (D-Pad)          Cluster Direito (ABXY)
        ┌───────────────────┐              ┌───────────────────┐
        │     [DUP]         │              │         [Y]       │
        │                   │              │                   │
        │ [DLEFT]   [DRIGHT]│   👁️ OLHO   │ [X]        [B]    │
        │                   │              │                   │
        │     [DDOWN]       │              │         [A]       │
        └───────────────────┘              └───────────────────┘
                    ↑ gap de ~180px ↑
                    ícone centralizado em x=0
```

---

## 2. Arquitetura Técnica

### 2.1. APIs WoW 1.12 necessárias

| API | Uso | Disponível no 1.12 |
|-----|-----|---------------------|
| `UnitClass("player")` | Detectar classe do player (melee vs ranged) | ✅ |
| `UnitExists("target")` | Verificar se há target ativo | ✅ |
| `IsActionInRange(slot)` | Retorna `1` (in range), `0` (out of range), `nil` (sem range) | ✅ |
| `CheckInteractDistance("target", 1)` | Distância fixa ~5 jardas (melee) | ✅ |

> ⚠️ **Não usar:** `IsSpellInRange` (inexistente no 1.12 — é TBC+ 2.0).

### 2.2. Lógica de Detecção de Range

A abordagem usa **duas estratégias** dependendo da classe:

**Classe Melee** (Warrior, Rogue, Paladin):
- Range fixo via `CheckInteractDistance("target", 1)` (~5 jardas)
- Na prática, o ícone **nunca aparece** porque melee sempre alcança quando o target está perto o suficiente para ser selecionado
- Implementação: simplesmente **não criar** o ícone para classes melee

**Classe Ranged** (Hunter, Mage, Priest, Warlock, Druid, Shaman):
- Scanear os **slots da action bar** (1–120) procurando o primeiro slot que retorna um valor não-`nil` no `IsActionInRange`
- Usar esse slot como referência de range
- O próprio jogo calcula o range real do spell naquele slot — sem precisar de tabela hardcoded

**Por que scanear slots?**
- Macros retornam `nil` no `IsActionInRange` (o jogo não consegue determinar range de macros)
- O jogador pode ter slots vazios
- Scanear até achar o primeiro spell "real" com range garante que funciona para qualquer configuração de barra

### 2.3. Tabela de Classes

```lua
local MELEE_CLASSES = {
    ["WARRIOR"]  = true,
    ["ROGUE"]    = true,
    ["PALADIN"]  = true,
}

local RANGED_CLASSES = {
    ["HUNTER"]   = true,
    ["MAGE"]     = true,
    ["PRIEST"]   = true,
    ["WARLOCK"]  = true,
    ["DRUID"]    = true,
    ["SHAMAN"]   = true,
}
```

> **Nota sobre Druid:** Druids podem ser melee (Feral) ou ranged (Balance/Resto). Tratar como ranged é correto porque:
> - Se o druid está em forma de urso → os spells não têm range → `IsActionInRange` retorna `nil` → ícone não aparece (comportamento correto)
> - Se o druid está em forma humana com Wrath/Moonfire → range funciona normalmente

### 2.4. Estrutura de Dados

```lua
-- Adicionar em HUD (UI/ActionHUD.lua)
HUD.rangeIndicator = nil          -- frame do ícone
HUD.rangeUpdateTimer = 0          -- timer de polling (evitar spam de API)
HUD.RANGE_UPDATE_INTERVAL = 0.25  -- 4x por segundo é suficiente
HUD.isRangedClass = false         -- cache da classe (calculado 1x no login)
HUD.referenceSlot = nil           -- slot de referência com range válido
```

### 2.5. Fluxo de Atualização

```
OnUpdate (0.25s interval):
  ├─ sem target? → Hide() → return
  ├─ classe melee? → Hide() → return
  ├─ classe ranged:
  │   ├─ referenceSlot ainda válido? → usar ele
  │   ├─ referenceSlot não? → rescanear slots (1-120)
  │   ├─ achou slot com range?
  │   │   ├─ IsActionInRange(slot) == 1 → Show(icon_inrange)
  │   │   └─ IsActionInRange(slot) == 0 → Show(icon_outrange)
  │   └─ nenhum slot com range? → Hide()
  └─ Limite de taxa: não atualizar mais de 4x por segundo
```

---

## 3. Plano de Implementação em 3 Passos Incrementais e Testáveis

> Cada passo é **independente e testável in-game com `/reload`**, termina numa **PARADA CRÍTICA** com resultado esperado exato, e **não inclui commit/push**.

---

### **PASSO 1: Detecção de Classe + Infraestrutura do Frame** `[STATUS: ✅ CONCLUÍDA]`

#### Objetivo
Criar o frame do ícone centralizado entre os dois clusters, detectar a classe do player, e preparar a estrutura lógica. O ícone fica fixo (sem lógica de range ainda) para validar o posicionamento visual.

#### Tarefas
1. Em `UI/ActionHUD.lua`, após a criação dos clusters (após linha ~375), adicionar bloco `-- RANGE INDICATOR`:
   - Detectar classe: `local _, playerClass = UnitClass("player")`
   - Cache: `HUD.isRangedClass = RANGED_CLASSES[playerClass]`
   - Se não for ranged → parar aqui (não criar frame)
2. Criar frame `ConsoleModeRangeIndicator` como filho de `ConsoleModeActionHUDFrame`:
   - Anchor: `SetPoint("CENTER", f, "CENTER", 0, 0)` (centro exato entre clusters)
   - Tamanho: `64×64` (mesmo dos ícones PNG)
   - Strata: `MEDIUM` (acima do background, abaixo de tooltips)
   - `SetAlpha(1.0)`
3. Criar sub-frame de textura `texture` dentro do frame:
   - Tamanho: preencher todo o frame (`SetAllPoints`)
   - Textura inicial: `icon_inrange.png` (para visualizar na tela)
4. Criar `HUD.rangeIndicator = frame` e `HUD.rangeTexture = texture`
5. Inicialmente `frame:Show()` para validar posicionamento
6. Validar sintaxe: `luac -p UI/ActionHUD.lua`

#### Arquivos Modificados
- `UI/ActionHUD.lua` (bloco novo após criação dos clusters, ~linha 375)

#### Validação (PARADA CRÍTICA)
**Como testar:**
1. `/reload` no jogo.
2. Olhar para o centro do ActionHUD → ícone de olho branco deve aparecer entre os dois clusters.
3. O ícone não deve sobrepor nenhum botão (D-Pad nem ABXY).
4. O ícone deve estar centralizado horizontal e verticalmente.

**Resultado esperado:** ícone visível no centro, sem sobreposição, tamanho correto.

**O que NÃO deve acontecer:** ícone aparecendo para classes melee, botões cobertos, ícone cortado ou desalinhado.

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 2: Lógica de Range + Polling** `[STATUS: ✅ CONCLUÍDA]`

#### Objetivo
Implementar a detecção de range: esconder/mostrar o ícone baseado na presença de target e no range do spell. Adicionar polling para atualização em tempo real.

#### Tarefas
1. Criar `HUD:FindReferenceSlot()`:
   - Scanear slots 1–120 com `IsActionInRange(slot)`
   - Retornar o primeiro slot que retorna `1` ou `0` (não `nil`)
   - Cache em `HUD.referenceSlot`; re-scanear se o slot cached retornar `nil`
2. Criar `HUD:UpdateRangeIndicator()`:
   - `if not UnitExists("target") then frame:Hide(); return end`
   - `if not HUD.isRangedClass then frame:Hide(); return end`
   - Chamar `FindReferenceSlot()`; se `nil` → `frame:Hide(); return`
   - `local inRange = IsActionInRange(HUD.referenceSlot)`
   - `if inRange == 1 then texture:SetTexture("icon_inrange.png")`
   - `if inRange == 0 then texture:SetTexture("icon_outrange.png")`
   - `frame:Show()`
3. Integrar no `OnUpdate` existente (linha ~387):
   - Adicionar timer `rangeUpdateTimer` com intervalo de 0.25s
   - Chamar `HUD:UpdateRangeIndicator()` a cada tick do timer
4. Adicionar listener para `PLAYER_TARGET_CHANGED`:
   - Criar frame de eventos `ConsoleModeRangeEvents`
   - Registrar `PLAYER_TARGET_CHANGED` → `HUD:UpdateRangeIndicator()` imediato (não esperar o próximo tick)
5. Validar sintaxe: `luac -p UI/ActionHUD.lua`

#### Arquivos Modificados
- `UI/ActionHUD.lua` (bloco RANGE INDICATOR + OnUpdate + frame de eventos)

#### Validação (PARADA CRÍTICA)
**Como testar (com classe ranged — Hunter, Mage, etc.):**
1. `/reload`, entrar no jogo.
2. **Sem target** → ícone invisível ✅
3. **Tab em um mob perto** (melee) → ícone aparece com **olho aberto** ✅
4. **Tab em um mob longe** (>30 jardas) → ícone aparece com **olho riscado** ✅
5. **Mover até o mob ficar perto** → ícone muda para **olho aberto** em tempo real ✅
6. **Limpar target** (ESC) → ícone desaparece ✅
7. Testar com macros na barra → o scan pula slots com macro e acha um spell real ✅

**Como testar (com classe melee — Warrior, Rogue, Paladin):**
1. `/reload` → ícone **não deve aparecer** em nenhuma situação ✅

**Resultado esperado:** range funciona para todas as classes ranged; melee não mostra ícone; transições são suaves.

**O que NÃO deve acontecer:** ícone preso visível após limpar target; erro de Lua com slots vazios; ícone piscando (update rápido demais).

**Aguardar confirmação do usuário antes de prosseguir.**

---

### **PASSO 3: Polimento e Edge Cases** `[STATUS: ✅ CONCLUÍDA]`

#### Objetivo
Tratar casos extremos, ajustar performance, e garantir estabilidade completa.

#### Tarefas
1. **Re-scan de slots:** Se o `referenceSlot` cached开始retornar `nil` (spell foi removido da barra), re-scanear automaticamente.
2. **Transição suave:** Opcionalmente, adicionar `SetAlpha` de fade (0.1s) ao trocar entre olho aberto/riscado para evitar flash brusco.
3. **Performance:** Confirmar que o polling de 0.25s não causa lag; ajustar para 0.5s se necessário.
4. **Proteção contra erros:** Wrappear `IsActionInRange` em `pcall`以防 (para macros ou slots corrompidos que possam causar erro).
5. **Limpeza:** Remover qualquer `print`/debug; comentar bloco RANGE INDICATOR em PT-BR; `luac -p` final.
6. Mover ícones PNG para pasta adequada do addon (ex: `Textures/`) se necessário.
7. Atualizar este doc: `PASSO 3` → `[STATUS: ✅ CONCLUÍDA]` (só após aprovação do usuário).

#### Arquivos Modificados
- `UI/ActionHUD.lua` (ajustes finos no bloco RANGE INDICATOR)
- Possivelmente mover PNGs para `Textures/`

#### Validação (PARADA CRÍTICA — bateria final)
**Como testar:**
1. `/reload`; testar **Hunter** com Auto Shot na barra → range funciona.
2. Testar **Mage** com Frostbolt → range funciona.
3. Testar **Warrior** → nenhum ícone em nenhuma situação.
4. Testar com **barra cheia de macros** → scan pula macros e acha spell real.
5. Testar **Druid em forma de urso** → spells não têm range → ícone some corretamente.
6. Testar **trocar de página da action bar** → se o spell de referência mudou, re-scan corretamente.
7. Stress: Tab em 10+ mobs rapidamente → sem lag, sem erro, sem ícone preso.
8. `/reload` final de confirmação com o usuário olhando.

**Resultado esperado:** indicador estável, funcional para todas as classes ranged, invisível para melee, sem regressão em features existentes.

**Após aprovação: aguardar comando explícito do usuário para commit/push. NÃO commitar por conta própria.**

---

## 4. Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|---|---|---|
| `IsActionInRange` retorna `nil` para todos os slots (barra só com macros) | Média | Scanear 1-120; se nenhum slot retorna valor → esconder ícone (comportamento seguro) |
| `IsActionInRange` pode causar erro em slots corrompidos | Baixa | Wrappear em `pcall` |
| Polling causa micro-lag | Baixa | Intervalo de 0.25s é barato; ajustar para 0.5s se necessário |
| Druid em forma animal não tem spells ranged | Baixa | `IsActionInRange` retorna `nil` → ícone some (comportamento correto) |
| Spell removido da barra durante gameplay | Baixa | Re-scan automático quando referenceSlot retorna `nil` |
| Ícone PNG não encontrado (path errado) | Baixa | Validar path no Passo 1; usar `Texture\` path relativo ao addon |

---

## 5. Critérios de Aceite

- [ ] Ícone aparece no centro exato entre os dois clusters, sem sobrepor botões.
- [ ] Ícone só aparece quando há target ativo.
- [ ] Classes ranged mostram olho aberto (in range) ou riscado (out of range).
- [ ] Classes melee não mostram ícone em nenhuma situação.
- [ ] Transições entre range/in-range são atualizadas em tempo real (<0.5s de latência).
- [ ] Funciona com macros na barra (scan pula macros e acha spell real).
- [ ] `luac -p UI/ActionHUD.lua` limpo; zero erros de Lua; sem regressão em features existentes.
- [ ] Usuário validou cada PARADA CRÍTICA in-game e aprovou explicitamente.

---

## 6. Histórico de Execução

| Passo | Status | Data de validação | Observações |
|---|---|---|---|
| 1 — Detecção de Classe + Frame | ✅ CONCLUÍDA | — | Implementado em UI/ActionHUD.lua |
| 2 — Lógica de Range + Polling | ✅ CONCLUÍDA | — | Implementado em UI/ActionHUD.lua |
| 3 — Polimento e Edge Cases | ✅ CONCLUÍDA | — | CheckInteractDistance não funcionou; usa slot 34 com PickupSpell/PickupAction + IsActionInRange |
