# Plano de Feature: D-PAD NO MAIN MENU (sem cursor espacial)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido terminantemente o uso de operadores de Lua 5.1+ (como operador de tamanho `#table`, usar `table.getn(t)` ou `getn(t)`), `continue` ou `goto`.
> 3. **Arquitetura Modular Isolada (Fim do Monólito):**
>    - O `MainMenu.lua` atual tem ~13.500 linhas / ~599KB. Esta feature **NÃO DEVE** inchar ainda mais esse arquivo.
>    - A navegação nasce como módulo **100% independente e desacoplado**: `UI/MainMenuNav.lua`.
>    - Será carregado via `ConsoleModeVanilla.toc` (depois de `UI/MainMenu.lua`) e exposto como `ConsoleMode.mainMenuNav` (molde `CM.mailScreen` / `CM.merchantMenu`).
>    - `MainMenu.lua` só recebe hooks mínimos (expor getters de estado já existentes: `currentTab`, `selectedSlotIndex`, `selectedQuestIndex`, etc.). Nenhuma lógica de D-pad dentro dele.
> 4. **Identidade Visual Rigorosa do CONSOLEMODE:**
>    - Foco ouro padrão: borda `1.00, 0.82, 0.20, 1.00` + fundo `0.28, 0.20, 0.08, 0.95`; apagado `0.35, 0.28, 0.20, 0.40` + `0.10, 0.08, 0.06, 0.50` (molde `MailScreen:RefreshInboxList:1622-1636`, `RefreshComposeVisuals:2513-2540`).
>    - Som `igMainMenuOptionCheckBoxOn` a cada movimento (molde Mail).
>    - Glifos reais em `Media/Icons/Xbox/` (`A/B/X/Y/LB/RB/LT/RT.tga`), nunca texto `[A]` cru.
> 5. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via `luac -p` antes de qualquer teste.
> 6. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem autorização explícita do usuário.
> 7. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem validação no jogo via `/reload` e aprovação do usuário.

---

## 1. Visão Geral

Hoje o MainMenu navega por **cursor espacial** (`Cursor.lua:MoveDirection:1368-1527` → `FindBestInDirection:708-758` por distância euclidiana + `CollectButtons:664-702` + regras por aba em `FindFirstVisibleButton:493-608`). É impreciso em grades e exige `OnEnter/OnLeave` para tudo.

Mail (`MailScreen:OnDirection:5199`) e Merchant (`MerchantMenu:OnDirection:2305`) já provaram o padrão correto: **roteador `OnDirection(direction)` com estado explícito + hold-to-repeat próprio + bypass do cursor via early-return em `Keybindings.lua` antes de `CM.cursor`**. Não existe API genérica "eu cuido do meu D-pad" — o bypass é `if Module.isOpen then ... return end` hardcoded na ordem **VK > Merchant > Mail > QuantityPicker/ContextMenu > Cursor** (`Keybindings.lua:1102-1150`, `1173-1229`, `1231-1500`, `1502-1658`).

Objetivo: dar ao MainMenu o mesmo tratamento — D-pad determinístico por zona, sem cursor — aba por aba, em fases auditáveis.

---

## 2. Mapeamento consolidado (agentes, só leitura)

### 2.1 Telas do MainMenu (`MainMenu.lua:269-275`, `12666-12695`, `12701-12855`)

| Aba (`id`) | Título | Sub-estados |
|---|---|---|
| `BAGS` | Bolsas & Itens | `currentCategory` ALL/EQUIP/USABLE/TRADE/MISC (`4084`); `grid.selectedSlotIndex` (`3443,3554`) |
| `SPELLS` | Livro de Magias | `activeScreen` 1=categorias / 2=grid (`4733,5134,5165`); `focusedCatIdx` (`4734,5069`); `backBtn` (`4623`) |
| `TALENTS` | Talentos | `activeScreen` 1=specs / 2=árvore (`5929,6237`); `focusedSpecIdx` (`5453`); `focusedTalentSlot` (`5953`); `backBtn` (`5892`) |
| `QUESTS` | Missões & Mapa | `selectedQuestIndex` (`8600-8601`); `mapViewMode` ZONE (`31`); nav buttons Atual/Kalimdor/EK/Inst/Voltar (`6894`); overlay `questDetailOverlay` (`8334,8472`) |
| `SYSTEM` | Configurações | `currentSubTab` GAME_MENU/ADDON_CFG (`10433`); `activeSubScreen` nil/BINDS/PICKER (`10929,11975,12511`); `bindsScreen.focusedCard`; `pickerScreen.gridButtons[1..16]` |

Global sempre presente: `tabBar.buttons` (`12600-12633`), `equipColumn.buttons[1..17]` (`1127-1229`), coluna stats/buffs (`1304,1480`), modelo 3D (não focável, gira com R-Stick `953-978`).

Troca de abas: `SelectTab(tabID)` (`12701`), ciclo `CycleTabs(dir)` (`12857`, via `Cursor:CycleTabs:1813`), sub-categorias `CycleCategories` (`12881`, via `Cursor:CycleSubTabs:1958` + `Cursor:HandleQuestNavigation:1056`).

### 2.2 Padrão Mail a copiar (`MailScreen.lua`)

- Roteador `OnDirection` (`5199-5238`) com guardas modais primeiro (Money/Qty/VK/Confirm), depois `currentScreen`/`activeColumn`.
- Regra espacial: atravessa p/ área vizinha, borda sem vizinho = parado, **sem wrap** (`plano TELA_DE_MAIL.md:43-44`).
- `StartRepeat/StopRepeat/EnsureRepeatTicker` (`5261-5313`): UP/DOWN sempre repetem; LEFT/RIGHT só em grade; `0.35s` delay + `0.12s` intervalo.
- Bypass: `Keybindings.lua:1137-1150` (D-pad), `1205-1210` (A→`OnConfirm:5242`), `1417-1424` (B→`OnCancel:5167`), `1264-1282` (Y), `1353-1361` (X), `1519-1648` (LB/RB/LT/RT); `ExitNavigationMode:773` recusa sair se Mail aberta; `Hooks:CloseTopFrame:743-760` prioriza Mail.
- `MailScreen` nunca toca `Cursor:Enable/Disable/MoveTo` — só `CursorHasItem()` do jogo (`3968`).

### 2.3 Cursor hoje (`Cursor.lua`, `Keybindings.lua`, `Hooks.lua`, `Bindings.xml`)

- Binds físicos: `A=SPACE, X=1, Y=2, B=3, DUP=7, DDOWN=8, DLEFT=9, DRIGHT=0` (`Keybindings.lua:89-98`); swap combate↔navegação `EnterNavigationMode:631` / `Reapply:696` / `Exit:765`; `Bindings.xml:95-106` (`CM_CursorMove` com `runOnUp`, Confirm/Cancel/Use/Secondary, NavPrev/NextTab/SubTab).
- MainMenu entra em navegação via whitelist `Hooks.frames:18-97` (`ConsoleModeMainMenuFrame`) → `activeFrames` + `navigationMode` (`Hooks.lua:204,218,327-350,480-530`); telas custom (Merchant/Mail) fazem `Enter/ExitNavigationMode` no próprio `Open/Close` e nunca entram em `activeFrames`.
- A/B/L1 hoje no MainMenu: A→`Cursor:Click Left` (`1173-1229`, exceto mapa pág2 `OnMapPinClick:844`); B→pilha quest-detalhe/talents/spells/binds/map (`1392-1500`); X→limpa bind ou `ToggleQuestWatch:853` (`1308-1383`); Y→`OpenQuestContextMenu:864` senão `Click Right` (`1231-1306`); LB/RB→`CycleTabs`, LT/RT→`CycleCategories`/zoom mapa (`1502-1621`).

---

## 3. Rotas de navegação (para onde o D-pad vai passar)

Convenções: `TABBAR` = fileira de 5 abas no topo; `EQUIP` = coluna esquerda de 17 slots; `MAIN` = painel direito da aba ativa. UP/DOWN andam dentro da zona; LEFT/RIGHT atravessam zonas; borda sem vizinha = parado (sem wrap, igual Mail).

```
[TABBAR: BAGS SPELLS TALENTS QUESTS SYSTEM]   (LB/RB cicla abas em qualquer zona)
        ↕ (UP da zona MAIN sobe p/ TABBAR; DOWN da TABBAR volta p/ última zona)
[EQUIP 17 slots] ⇄ [MAIN da aba ativa]
```

- **BAGS:** `EQUIP` (vertical 17) ⇄ `CATS` (fileira ALL/EQUIP/USABLE/TRADE/MISC) ⇄ `GRID` (grade paginada, `Next/PrevBagPage:4493`). DOWN da última fileira da grade = parado (paginação por LT/RT ou botão Sort `4218`).
- **SPELLS tela 1:** lista vertical `catButtons` (`5060`); RIGHT ou A entra na tela 2; **tela 2:** grade `grid.slots` + `backBtn` (`4623`); B ou LEFT na 1ª coluna volta p/ tela 1 (molde `HandleSpellsBack:5186`).
- **TALENTS tela 1:** lista `specButtons[1..3]` (`5445`); A entra na árvore; **tela 2:** grade da árvore `allSlots` (`5933`) + `backBtn` (`5892`); B volta (molde `HandleTalentsBack:6290`).
- **QUESTS lista:** `questButtons[1..10]` vertical (`8593`); RIGHT ou A entra no detalhe (`rewardSlots[1..4]` + ações Ver-no-Mapa/X-Rastrear/Y-Ações); B volta p/ lista; overlay `questDetailOverlay` (`8334`) rouba tudo até B fechar. **MAPA:** nav buttons Atual/Kalimdor/EK/Inst/Voltar (`6894`) em fileira + listas de zona/NPC; LT/RT = zoom (`MapZoomStep`), não filtro.
- **SYSTEM:** `subButtons` (GAME_MENU/ADDON_CFG `10431`) ⇄ `rows` (lista do GameMenu/addon `10503-10512`); sub-tela BINDS: `bindCards` vertical (`11318,11724`); sub-tela PICKER: `modeButtons` ⇄ `subTabButtons` ⇄ `gridButtons[1..16]` + paginação (`828-1042` no Cursor, a portar).

Botões globais: **LB/RB** = `CycleTabs` (`12857`); **LT/RT** = `CycleCategories` por aba (`12881`: BAGS categoria, SPELLS tab, TALENTS spec, SYSTEM subTab/binds page, QUESTS zoom); **A** = click esquerdo na zona focada; **B** = pilha de volta (overlay → sub-tela → aba → fechar, mesma ordem de `Keybindings.lua:1392-1500`); **X** = secundário (QUESTS rastrear `8174`, BINDS limpar); **Y** = contexto (QUESTS menu `8287`, senão click direito).

---

## 4. Cronograma de Fases TESTÁVEIS Passo a Passo

Cada fase é **100% testável no jogo imediatamente após a sua conclusão**. Nenhuma fase avança sem `/reload` + aprovação do usuário. Validar sintaxe com `luac -p` antes de cada teste.

---

### 🟢 FASE 1: Esqueleto `MainMenuNav` + bypass do cursor (sem mudar foco ainda)
> **Objetivo de Teste:** O jogador abre o MainMenu, aperta o D-pad e vê no chat `[MMNav] UP/DOWN/LEFT/RIGHT` — e o cursor espacial **não se move mais** dentro do MainMenu.

- [ ] Criar módulo isolado `UI/MainMenuNav.lua` (`ConsoleMode.mainMenuNav`, tabela `navState = { zone, tabID, equipIndex, catIndex, gridIndex }`), sem lógica de aba ainda.
- [ ] Registrar `UI/MainMenuNav.lua` no `ConsoleModeVanilla.toc` logo após `UI/MainMenu.lua`.
- [ ] Implementar `MainMenuNav:IsActive()` (MainMenu visível E nenhum modal roubando: VK/Qty/ContextMenu/questDetailOverlay) + `OnDirection(direction)` roteador só com log + som.
- [ ] Implementar `StartRepeat/StopRepeat/EnsureRepeatTicker` (molde `MailScreen:5261-5313`: `0.35s`/`0.12s`; UP/DOWN repetem, LEFT/RIGHT repetem).
- [ ] Inserir early-return em `Keybindings.lua` na mesma posição do Mail: `CM_CursorMove` (`~1137`), `CM_CursorConfirm/Use/Secondary/Cancel`, `CM_NavPrev/NextTab/SubTab`, `CM_SmartTab` — `if MainMenuNav:IsActive() then ... return end`.
- [ ] Travar `ExitNavigationMode` com MainMenu aberto (molde `Keybindings.lua:769-779` do Mail) e priorizar no `Hooks:CloseTopFrame`.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 1):** `/reload` → abrir MainMenu (`START` ou `/cm menu`) → D-pad mostra `[MMNav] ...` no chat e o cursor não se mexe; fechar continua funcionando com `B`.

---

### 🟢 FASE 2: BAGS piloto (zonas TABBAR ⇄ EQUIP ⇄ CATS ⇄ GRID + destaque ouro)
> **Objetivo de Teste:** O jogador navega a aba BAGS inteira só no D-pad: sobe à TABBAR, desce ao EQUIP, atravessa p/ categorias e grade, com borda ouro.

- [ ] Estado `zone` (`TABBAR/EQUIP/CATS/GRID`) + índices (`tabIdx`, `equipIndex 1..17`, `catIndex`, `gridIndex`) espelhando `currentCategory:4084` e `selectedSlotIndex:3443`.
- [ ] `OnBagsDirection`: UP/DOWN dentro da zona; LEFT/RIGHT atravessam EQUIP⇄CATS⇄GRID; UP do MAIN sobe p/ TABBAR, DOWN volta; borda = parado.
- [ ] Destaque ouro (molde Mail `1622-1636`): aplicar `SetBackdropBorderColor(ouro)` na zona/índice focado + `DetailCard` no `OnEnter` correspondente (`1216-1221`, `3553-3572`).
- [ ] `OnConfirm (A)` = click esquerdo do focado; `OnCancel (B)` na grade volta p/ CATS, senão fecha (pilha futura).
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 2):** `/reload` → aba BAGS → percorrer TABBAR/EQUIP/CATS/GRID nos 4 sentidos, ouro acompanha, A equipa/usa, B volta sem fechar à toa.

---

### 🟢 FASE 3: SPELLS (tela categorias ⇄ grade + voltar)
> **Objetivo de Teste:** O jogador entra em SPELLS, desce a lista de categorias, aperta A/RIGHT e cai na grade de magias, navega a grade e volta com B.

- [ ] Reusar zonas: tela 1 = lista `catButtons` vertical (`FocusSpellCategoryButton:5060`, `focusedCatIdx:4734`); tela 2 = grade `grid.slots` + `backBtn:4623`.
- [ ] `OnSpellsDirection`: tela 1 UP/DOWN na lista, RIGHT/A → `ShowSpellGridScreen` (`5153`); tela 2 grade 2D + LEFT na 1ª coluna ou B → `HandleSpellsBack` (`5186`).
- [ ] Ouro + `DetailCard`/pose (`UpdateSpellCategories:4881`, `UpdateSpellsPage:5199`).
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 3):** `/reload` → SPELLS → lista → grade → B volta p/ lista → B volta p/ BAGS ou fecha (conforme pilha definida).

---

### 🟢 FASE 4: TALENTS (specs ⇄ árvore + voltar)
> **Objetivo de Teste:** O jogador lista as 3 specs, entra na árvore com A, navega os talentos na grade e volta com B.

- [ ] Tela 1 = `specButtons[1..3]` (`FocusTalentSpecButton:5445`); tela 2 = `allSlots` da árvore (`FocusTalentSlot:5933`) + `backBtn:5892`.
- [ ] `OnTalentsDirection`: mesma regra SPELLS; B → `HandleTalentsBack` (`6290`).
- [ ] Ouro + tooltip de talento.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 4):** `/reload` → TALENTS → specs → árvore → B volta sem perder o spec focado.

---

### 🟢 FASE 5: QUESTS + MAPA (lista ⇄ detalhe ⇄ mapa + overlay)
> **Objetivo de Teste:** O jogador navega as 10 quests, entra no detalhe (recompensas + ações), abre o mapa, troca de continente/zona e fecha o overlay só com o controle.

- [ ] Lista `questButtons[1..10]` vertical (`SelectQuest:8593`, `selectedQuestIndex:8600`); RIGHT/A → detalhe (`rewardSlots[1..4]:6994` + ações Ver-no-Mapa/X-Rastrear/Y-Ações `7031,8174,8287`); B → volta p/ lista.
- [ ] Overlay `questDetailOverlay` (`8334,8472,8307`): quando visível, D-pad/A/B pertencem a ele até B fechar.
- [ ] Mapa: fileira nav (Atual/Kalimdor/EK/Inst/Voltar `6894`) ⇄ listas zona/NPC; LT/RT = `MapZoomStep` (não filtro); A no pin = `OnMapPinClick` (exceção `Keybindings:844` preservada).
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 5):** `/reload` → QUESTS → lista → detalhe → mapa/continente → overlay abre/fecha, X rastreia, Y abre menu.

---

### 🟢 FASE 6: SYSTEM + botões globais + desligamento do cursor + regressão
> **Objetivo de Teste:** O jogador percorre SYSTEM (sub-abas, linhas, binds, picker), usa LB/RB/LT/RT/A/B/X/Y em todas as abas, e o cursor espacial nunca mais aparece dentro do MainMenu.

- [ ] SYSTEM: `subButtons` ⇄ `rows` (`10431,10503-10512`); BINDS `bindCards` vertical (`11318,11724`, X limpa `1368`); PICKER `modeButtons` ⇄ `subTabButtons` ⇄ `gridButtons[1..16]` + paginação (portar `Cursor.lua:828-1042`).
- [ ] Globais: LB/RB = `CycleTabs:12857` de qualquer zona; LT/RT = `CycleCategories:12881` (QUESTS = zoom); A = click esquerdo, B = pilha overlay→sub-tela→aba→fechar (ordem `Keybindings:1392-1500`), X/Y contextuais por aba.
- [ ] Desligar cursor no MainMenu: remover `ConsoleModeMainMenuFrame` do caminho espacial (`FindFirstVisibleButton:493-608`, `CollectButtons:664-702`) quando `MainMenuNav:IsActive()`, mantendo cursor para os demais frames da whitelist.
- [ ] Regressão: Merchant/Mail/VK/Qty/ContextMenu intactos (ordem VK > Merchant > Mail > MainMenuNav > Cursor); `START` abre/fecha, `SELECT` vai p/ QUESTS (`881-965`).
- [ ] Validação de sintaxe final via `luac -p` e checagem de regressão geral.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 6):** teste geral nas 5 abas só com controle + mouse clicável ainda funciona; cursor espacial não reaparece no MainMenu.

---

## 5. Estrutura de Arquivos

```
Interface/AddOns/ConsoleModeVanilla/
├── ConsoleModeVanilla.toc          <-- Adiciona UI/MainMenuNav.lua após UI/MainMenu.lua
├── UI/
│   ├── MainMenuNav.lua             <-- NOVO MÓDULO (router OnDirection, repeat, zonas por aba, ouro)
│   ├── MainMenu.lua                <-- Intocado (só getters já existentes; sem lógica de D-pad)
│   ├── MerchantMenu.lua            <-- Intocado (ordem de interceptação preservada)
│   ├── MailScreen.lua              <-- Intocado (ordem de interceptação preservada)
│   └── ...
├── Keybindings.lua                 <-- Early-returns p/ MainMenuNav (molde Mail) + trava ExitNavigationMode
├── Hooks.lua                       <-- CloseTopFrame prioriza overlay do MainMenu antes do resto
└── docs/
    └── plano_de_feature_DPAD_NO_MAIN_MENU.md <-- Este documento
```
