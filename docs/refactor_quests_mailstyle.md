# Refatoração LISTAS QUESTS → Modelo MAIL-style

> **Briefing completo** para a próxima IA e para validação. Estado em 12/Set/2026.

---

## 1. Estado atual arquitetônico (confirmado A/B/C)

### Containers — TODOS FIXOS (criados uma vez em `SetupQuestsPage:6522`)
- `pageQuests.questPanel` → `questPanel.listContainer` = `ConsoleModeMM_QuestListContainer` (MainMenu.lua:7190).
- `pageQuests.mapPanel.zoneListFrame` = `ConsoleModeMM_ContinentZoneList` (MainMenu.lua:7048).
- `pageQuests.mapPanel.npcListPanel` = `ConsoleModeMM_MapNPCListPanel` (MainMenu.lua:6911).

> **Crucial:** não existe `mapListFrame` e `npcListFrame`. Zonas e mapas compartilham o **mesmo** `zoneListFrame` (ver `zoneListMode` MainMenuNav.lua:1503-1505).

### Botões — MISTO (este é o vilão)
| Lista      | Botões        | Globals?      | Trigger rebuild                          |
|------------|---------------|---------------|------------------------------------------|
| **Missões**  | **REUSO** (`Hide/Show`, nunca recria) | ✅ `ConsoleModeMM_QuestBtn{1..10}` (MainMenu.lua:7238) | `QUEST_LOG_UPDATE` → `UpdateQuestsPage` |
| **Zonas/Mapas** | **DESTROI+RECRIA** (`buttons={}` + `CreateFrame(nil)`) | ❌ nil (MainMenu.lua:7989, 8116, 8246) | Nav/click → `BuildInstancesList*` |
| **NPCs**       | **DESTROI+RECRIA** (cache `sig` skip) | ❌ nil (`UpdateNPCServicePins`, MainMenu.lua:10243-10271) | polling 0.5s (MainMenu.lua:6881) + pfQuest hook (10412) |

### Gating/eventos
- `QUEST_LOG_UPDATE` → `UpdateQuestsPage` (MainMenu.lua:13669-13672), gated `currentTab=="QUESTS"`.
- `ZONE_CHANGED_*` → `UpdateQuestsPage` (MainMenu.lua:13643-13652), early-return se `mapShowingQuestZone or CONTINENT`.
- `UpdateNPCServicePins` roda em polling OnUpdate **concorrente** com o D-pad (0.5s, MainMenu.lua:6871-6883) + disparado via `UpdateQuestsPage` (MainMenu.lua:7356) + pfQuest hook (10412).
- Navegação do Nav (`MainMenuNav.lua:3089-3095`) chama `BuildInstancesListForZone` + `UpdateQuestsPage` — **o `UpdateQuestsPage` aqui é que reseta o foco.**

---

## 2. Diagnóstico cruzado (raiz)

### Foco global corrompido (sintoma: "nada responde depois de visitar QUESTS, BAGS perde hover no 1º movimento")
- `Nav.focus.zonaIdx`/`npcIdx` sobrevivem a rebuilds (`SetupQuestsPage:7216`) que **destróem** os botões.
- `Nav_GetVisibleZones/NPCs` devolve lista nova; `Nav.focus.zonaIdx` vira apontador para slot vazio.
- `UpdateQuestsPage` (gatilhado por eventos e pela própria navegação: MainMenuNav.lua:3094,8026) reseta `questOffset` e `selectedQuestIndex` → pintor `Nav_PaintQuests` (MainMenuNav.lua:1352-1371) pula itens fora do offset.

### Destruição + concorrência (sintoma: DOWN pula, LEFT fantasma)
- `zoneListFrame.buttons={}` em rebuilds (`BuildInstancesList*`, MainMenu.lua:7944,8097,8220) invalida globals `nil` que o `getglobal` do Nav resolveria.
- Polling OnUpdate de NPCs (`0.5s`, MainMenu.lua:6881) **sobrescreve** `npcListPanel.buttons` entre o movimento do D-pad e o paint — foco perdido no meio do `OnDirection`.
- `UpdateNavButtonHighlight` faz `zoneListFrame:Hide()` (`UpdateNavButtonHighlight`, MainMenu.lua:8040-8041) **enquanto Nav foca** — invalida `SafeIsVisible` e força fallback para `Nav_bug22`.

### Warm frio (bloqueado 1ª vez)
- `SelectQuestLogEntry` + `GetQuestLogQuestText` no 1º `Show` precisam de geometria/layout — o overlay precisa ser **aquecido com dados reais** (`WarmQuestDetailClean`, contexto limpo) antes do primeiro `Show`.

---

## 3. Plano MAIL-style aprovado

### Filosofia
> **Unificar contrato visual + manter contrato de navegação existente.** Nada muda na lógica de foco ordinal do Nav (`Nav.focus.zone/questIdx/zonaIdx`). Só os *renderers* são convertidos para pool fixo + globals nomeados.

### Etapa 1 — Missões (`questPanel`)
- [x] `questButtons` já é pool reusado — NÃO tocar.
- [ ] Persistir `questOffset` + `selectedQuestIndex` entre abas: gravar em `pageQuests` antes de rebuilds e restaurar no `UpdateQuestsPage`.
- [ ] `Nav_PaintQuests` (MainMenuNav.lua:1352-1371): fallback `btn.bg:SetVertexColor` quando `btn.highlight` nil.
- [ ] Warm frio: `WarmQuestDetailClean` já implementado (MainMenu.lua ~8540)? Confirmar chamado de `CreateUI` + `QUEST_LOG_UPDATE` (MainMenuNav.lua:3083-3095).

### Etapa 2 — Zonas/Mapas (`zoneListFrame`)
- [ ] Converter `BuildContinentZoneList` / `BuildInstancesListForZone` / `BuildInstancesList` para **pool fixo de 32 botões** nomeados `ConsoleMode_ZoneListFrameButton{i}` (MainMenu.lua:8220,7944,8097).
- [ ] Nunca mais `frame.buttons={}` — `for i=1,poolSize do pool[i]:Hide() end` + reuse.
- [ ] Persistir/normalizar `Nav.focus.zonaIdx` pós-rebuild (`if zonaIdx > n then zonaIdx=n end`).
- [ ] `UpdateNavButtonHighlight`: **não** fazer `zoneListFrame:Hide()` quando `currentTab==QUESTS` (MainMenu.lua:8236-8247).

### Etapa 3 — NPCs (`npcListPanel`)
- [ ] Converter `UpdateNPCServicePins` para **pool fixo** 24 botões `ConsoleMode_NPCListFrameButton{i}` (MainMenuBar.lua:10254-10271).
- [ ] Cache `sig` preservado; apenas `SetText/Hide/Show` no reuse.
- [ ] **Bloquear polling OnUpdate durante navegação ativa na QNPCS:** flag `Nav_focusLock`; `UpdateNPCServicePins` pula rebuild se `Nav.focus.zone=="QNPCS" and Nav_focusLock`.

### Etapa 4 — Warm + ticker (bloqueado 1ª vez)
- [ ] `WarmQuestDetailClean` (MainMenu.lua ~8540): `SelectQuestLogEntry` + `GetQuestLogQuestText` + `SetText` no 1º não-header + `Show/GetHeight/Hide` oculto. Rodar de: `CreateUI`, `Show`, `QUEST_LOG_UPDATE` com `QUESTS` construída — nunca de `OpenForQuest/OpenQuestContextMenu/ExecuteAction`.
- [ ] `ContextMenu:ExecuteAction` (ContextMenu.lua:449-482): só gravar `pendingQuestDetail/pendingQuestAbandon` + `Close()` + `return`; consumo em `OnUpdate` limpo via ticker.
- [ ] `ShowQuestDetail` (MainMenu.lua:8652-8771): `SelectQuestLogEntry` + `GetQuestLogQuestText` sem `pcall` no caminho feliz (pcall só como fallback defensivo).

---

## 4. Sequência de agentes sugerida (ordem de implementação)

1. **Agente 1 — Warm + ticker + Select direto (frio)**
   - `Create UI/MainMenu.lua`
   - Criar `WarmQuestDetailClean` (MainMenu.lua ~8540) — `SelectQuestLogEntry`+`GetQuestLogQuestText`+`SetText`+`Show/GetHeight/Hide` em `pcall`.
   - Registrar chamadas de contexto limpo: `initFrame OnEvent` (`CreateUI`, `PLAYER_LOGIN`, `VARIABLES_LOADED`, `QUEST_LOG_UPDATE` com QUESTS page pronta) + `MainMenu:Show` + `MainMenu:SelectTab("QUESTS")`.
   - `ContextMenu:OpenForQuest` — remover warm (tainted); manter criação via `CreateQuestDetailOverlay` só.
   - `ContextMenu:ExecuteAction` — `QUEST_DETAIL`/`QUEST_ABANDON` só gravam `pendingQuestDetail`/`pendingQuestAbandon` + `Close()` + `return`.
   - Criar ticker limpo `EnsureQuestDetailTicker` (`OnUpdate`) que consome `pending` e chama `ShowQuestDetail`/`AbandonSelectedQuest`.
   - `MainMenu:ShowQuestDetail` — remover fallback "use o mouse"; `Select`+`GetText` no caminho feliz (`pcall` só defensivo).
   - `MainMenu:AbandonSelectedQuest` — `Select`+`SetAbandon`+`StaticPopup_Show` seguro (1.12 StaticPopup é seguro).

2. **Agente 2 — Missões (persistir offset+focus)**
   - `Create UI/MainMenu.lua`
   - Persistir `questOffset` + `selectedQuestIndex` entre abas.
   - `Nav_PaintQuests`: fallback `bg` quando `highlight` nil.

3. **Agente 3 — Zonas/Mapas (pool fixo + globals)**
   - `Create UI/MainMenu.lua`
   - Converter `BuildContinentZoneList`/`BuildInstancesListForZone`/`BuildInstancesList` para pool fixo 32 `ConsoleMode_ZoneListFrameButton{i}`.
   - `UpdateNavButtonHighlight`: não `Hide()` zoneList em QUESTS.
   - `Nav_PaintZonas`: usar globals nomeados.

4. **Agente 4 — NPCs (pool fixo + lock de polling)**
   - `Create UI/MainMenu.lua`
   - Converter `UpdateNPCServicePins` para pool fixo 24 `ConsoleMode_NPCListFrameButton{i}`.
   - `Nav_focusLock` p/ bloquear polling durante navegação QNPCS.

5. **Agente 5 — Integração/Reset inter-abas**
   - `Create UI/MainMenu.lua`
   - `Nav_EnsureFocus` ao trocar `currentTab~=QUESTS` forçar `zone=GRID/CATS`.
   - `Nav_ApplyFocus` repintar aba atual mesmo `f.zone` stale.

### Validação por etapa
- [ ] Etapa 1: `/reload` → QUESTS → `Y` → `A` em detalhes 1ª vez (sem mouse antes, sem popup).
- [ ] Etapa 2: navegação DOWN por lista de missões sem pular, manter scroll.
- [ ] Etapa 3: LEFT de QMISSOES → QZONAS (hover 1º botão), DOWN navega, A expande, B volta.
- [ ] Etapa 4: navegação QNPCS não trava; troca de zona atualiza lista com foco preservado.
- [ ] Etapa 5: BAGS/Spell/Talents não perdem hover após visitar QUESTS; `/reload` só se necessário.

---

## 5. Notas técnicas pós-fix

### `Nav_bug22` (destino inválido)
> `Nav_EnsureNpcZonaFocus` (MainMenuNav.lua:1534-1589): `zone==QZONAS` + grupo `NAV` — valida `nav[zonaIdx]` visível+não-disabled. Grupo `LISTA` — valida `zones[zonaIdx]` visível. Destino inválido: volta para `QMISSOES` + `qDetail=false` + `Nav_EnsureFocus`. **Mantido**, mas sem mutar `zone` quando chamado de `Ensure` (só validar no `Apply`, não no `Move`).

### `Nav_questListButtons`
> `questButtons[slot]` criado via `CreateQuestListButton` com global `ConsoleModeMM_QuestBtn{idx}` (`SetupQuestsPage:6558`, `MainMenu.lua:7238`). Slot 1 = header (`btn.headerBg:Show`), slots 2-n = itens. `questOffset` via `maxVisible=10` manual (`MainMenu.lua:7423`).

### `MailScreen` vs `MerchantMenu`
> Ambas usam globals fixos (`MailScreen.lua`) / frames custom (`MerchantMenu.lua`). Navegação é **4-direcional estável** (UP/DOWN/LEFT/RIGHT com clamp); LEFT na borda do detalhe volta para a lista. Nenhum rebuild destrutivo; todos os botões têm `SetBackdrop` + `OnEnter/OnLeave` simétricos. Warm em `PLAYER_LOGIN`.
> **Formato-alvo:** espelhar este padrão. `SetBackdrop` + `bg border highlight texture` + `OnEnter/Leave` simétricos + pool fixo.
> **Known bugs 1-23** (docs/plano_de_feature_DPAD_NO_MAIN_MENU.md §6) aplicados preventivamente: especialmente bug 4 (`UpdateNPCServicePins` rebuild destrutivo) e bug 17 (`UpdateQuestsPage` reset de foco).
> **Known bug 24 (novo)** — `zoneListFrame:Hide()` em `UpdateNavButtonHighlight` (`MainMenu.lua:8040-8041`) invalida `SafeIsVisible` e força fallback para `Nav_bug22` quando `zone==QZONAS` e Nav foca. Fix: não `Hide()` quando `currentTab==QUESTS`.
> **Known bug 25 (novo)** — polling OnUpdate de NPCs (`MainMenu.lua:6863-6883`): `UpdateNPCServicePins` roda a cada 0.5s, corrompendo `npcListPanel.buttons` entre movimento do D-pad e paint. Fix: `Nav_focusLock` pulando rebuild quando `Nav.focus.zone=="QNPCS" and Nav_focusLock`.
> **Known bug 26 (novo)** — `questOffset` não persistido entre abas (`UpdateQuestsPage:7558`): reseta para 0 em rebuilds de zona → `Nav_PaintQuests` pula itens fora do offset. Fix: salvar/restaurar `questOffset` em `pageQuests` antes/depois de rebuilds.
> **Known bug 27 (novo, corrigido em passo anterior)** — `Nav_SelectQuestByIdx` (`MainMenuNav.lua:1299-1337`) ajusta `questOffset` mas não re-renderiza; lista física não sobe. Fix aplicado (`MainMenuNav.lua:1337-1340`): chamar `MM:UpdateQuestsPage()` pós-ajuste.
> **Known bug 28 (novo)** — `Show` direto de overlay de detalhes (ContextMenu.lua:463-468) no stack tainted do A cria `blocked`; warm não resolvi porque rodava dentro de `OpenQuestContextMenu` (stack tainted pelo Y). Fix: warm limpo de `PLAYER_LOGIN/CREATE_UI` + `ExecuteAction` só grava `pending`.
> **Known bug 29 (novo)** — `UpdateMapLayout` (`MainMenu.lua:7351-7355`) roda antes `UpdateNavButtonHighlight` (linha 7400), pintando sobre o Nav focado. Fix: trocar ordem (Nav último) ou `UpdateNavButtonHighlight` respeitar foco.
> **Known bug 30 (novo)** — `GetNumQuestLeaderBoards` (`MainMenu.lua:7502`) em `UpdateQuestsPage` durante rebuild de zona causa stutter no D-pad; pode ser adiado.

---

## 6. Arquivos de interesse
- `UI/MainMenuNav.lua` — Nav foco, rotas, pintores, `Nav_bug22/questListButtons`
- `UI/MainMenu.lua` — `SetupQuestsPage` (containers), `UpdateQuestsPage` (lista missões), `BuildInstancesList*` (zonas/mapas), `UpdateNPCServicePins` (NPCs), `WarmQuestDetailClean`, `ShowQuestDetail`, `UpdateNavButtonHighlight`
- `UI/ContextMenu.lua` — `OpenForQuest`, `ExecuteAction`, `pendingQuestDetail`, `UpdateQuestFocus`
- `Cursor.lua` — `activeFrames/MoveTo` (MailScreen:5261-5313 espelho)
- `Hooks.lua` — eventos `QUEST_LOG_UPDATE/ZONE_CHANGED/WORLD_MAP_UPDATE`

---

> **Status geral:** Arquitetura MAIL-style é viável com caveat de dados contextuais. Plano aprovado; aguarda implementação sequencial.
