# Plano de Feature — Mapeador de Binds no MainMenu (Sistema / Sub-Aba 2 → Binds → Picker)

> **Data:** 2026-09-13 | **Status:** Levantamento concluído — Plano faseado TESTÁVEL (F1..F5)
> **Escopo:** `UI/MainMenu.lua` + `Keybindings.lua` + `Cursor.lua` + `UI/MainMenuNav.lua` + `Data/KeybindingsList.lua` + `Data/{Spellbook,Bag,Macro}Picker.lua`

---

## 1. Contexto & Objetivo

Substituir a janela flutuante legada (`ConfigFrame.lua` 640x480 + `KeybindingsList` + `ActionBarPicker.lua`) — aberta via `/cm config` e botão *Mapeador de Atalhos / Binds* em `SYSTEM/ADDON_CFG` — por **2 telas nativas dentro do MainMenu**, no mesmo padrão Talentos `specScreen → treeScreen`.

Hierarquia alvo (`UI/MainMenu.lua:11445`): `ConsoleModeMainMenuFrame → RightPanel → TabContent → Page_SYSTEM → {headerBar/subContent/subPageGameMenu/subPageAddonCfg + ConsoleModeMM_BindsScreen:11686 + ConsoleModeMM_PickerScreen:11893}` — ambos `SetAllPoints(pageSystem)`, `Hide()` em `ShowBindsScreen/ShowPickerScreen`, guard `isBindsInitialized`, `activeSubScreen = nil|BINDS|PICKER:12496,13032`.

Fluxo: `ADDON_CFG --[A]--> BINDS (5 páginas x 8 físicos) --[A] no card--> PICKER (4 modos x N subTabs x grid 4x4) --[A] aplica ou [B] cancela--> BINDS --[B]--> ADDON_CFG`. `[X]` limpa slot focado. Slots alvo: `ACTIONBUTTON 1-12` + `MULTIACTIONBAR 1-4 (12 cada)` resolvidos por `SBP.ResolveTargetSlot:98`.

## 2. Visual & Layout (o que fica)

**BindsScreen** (`11686`): header 32h `+ title + BackBtn 95x24 RIGHT -6,0 (backdrop 0,0,0,0.45 border 0.5,0.4,0.3)`; `pageBar` 28h `5x PageBtn 86x24 + LT/RT 18x18` (`11893`); `BindsContent` TOP `pageBar` / BOTTOM `DetailCard` backdrop `edge12`; `clusters Left/Right Width 248` cada (D-PAD / ABXY); pool **8 `bindCards`** `BINDS_CLUSTER_DEFS:11536` (`DUP/DDOWN/DLEFT/DRIGHT + Y/X/B/A`), `Each 46h`, `CreateBindCard:11579` — `focusBorder` ouro `1.0,0.85,0.2` hide, `icon 34x34` `QuestionMark`, `iconBorder`, `glyphIcon 16x16 CFG.Icons.*`, `badge`, `nameText`, `OnEnter FocusBindsSlot`, `OnClick left OpenPickerForSlot / right ClearBinding`; `DetailCard 135h` via `CreateDetailCard:2762` footer `[A] Mapear | [X] Limpar | [LT]/[RT] Paginas | [B] Voltar`; `UpdateBindsPage:12290` pinta `pageButtons` ouro vs cinza, cards preenchido `tex+nome branco` vs vazio `QuestionMark cinza 0.5 + "(Vazio)" #888`; `FocusBindsSlot:12239` 3 estados (A-p1 fixo / com ação / vazio).

**PickerScreen** (`11893`): header 32h `[ SELETOR DE CONTEÚDO ] + BackBtn`; `DetailCard` footer `[B] Voltar ao Mapeador`; `modeBar 26h 4x ModeBtn Width floor((500-18)/4) 24h`; `subTabBar 24h` pool `subTabButtons tabW floor((496-(n-1)*4)/n) 22h` (`UpdatePickerSubTabs:12548` — `SPELLBOOK via SBP:GetSpellTabs`, `BAG` 4 fixos, `MACROS` 2, `BARS` 5 `PICKER_BAR_DEFINITIONS`); `grid 4x4 ConsoleModeMM_PickerGrid:12054` `16x Slot 120x48 gapX6 gapY5`, `icon 34x34 label rankLabel focusBorder`; `pageBar 24h Prev/Next + "Page X de Y"`, hide em `BARS`; `RefreshPickerGrid:12721` pagina `16 maxPages`, `EnableMouse(false)` se vazio; `FocusPickerSlot:12895`.

**Globals**: `ConsoleModeMM_BindsScreen/Header/BackBtn/PageBar/PageBtn1..5/Content/ClusterLeft/Right`, `ConsoleModeMM_PickerScreen/Header/BackBtn/Content/ModeBar/ModeBtn*/SubTabBar/SubTab*N/Grid/Slot1..16/PageBar/PrevBtn/NextBtn`. Estado `pageSystem.{bindsScreen.{bindCards,pageButtons,currentPage,focusedCard,detailCard,contentArea,leftCluster/rightCluster}, pickerScreen.{modeButtons,subTabButtons,gridButtons,currentMode/SubTab/gridPage/maxPages/itemsCache/focusedSlot}, targetBindCard, activeSubScreen}`.

**Identidade**: Vanilla bronze `0.5,0.4,0.3`, `UI-Tooltip-Border/Background`, dourado foco `1,0.85,0.2`, `CFG.DetailCard/Tabs.activeColor 0.88,0.6,0.08`. **Fragilidades**: widths fixas `86/95/248/120/500/496` ignoram `GetRightPanelDimensions`, clusters `516` fixo, `PageBtn` overflow em `840 minWidth`, duplo retângulo.

**Veredito visual**: MANTIDO cores/fontes/factory/clusters; REFATORADO layout fixo → `calc via GetRightPanelDimensions`; REMOVIDO `hover` como única fonte de foco e `GameTooltip` em subTab; `focusBorder` único indicador sincronizado com Nav.

## 3. Dados & Bindings (o que fica)

**Fonte canônica**: bindings nativos `GetBindingAction/SetBinding+SaveBindings` (`bindings-cache.wtf`), **não** `ConsoleModeDB` (SV só `positions/showRightActionBars/backup`). `KB.savedNavBindings{}:166` snapshot volátil, `savedMapBindings:1009`, `savedMoveBindings:13644`.

**Leitura**: `KBList:GetDisplayForButton:59-143` via `KEY_DEFAULTS→physKey→GetBindingAction` (+ fallback `savedNavBindings` se `^CM_`), parse `ACTIONBUTTON/MULTIACTIONBAR`, `GetActionTexture/Text` ou tooltip-scan; `MainMenu:GetBindButtonData:11557` delega.

**Escrita segura única**: `KB:ApplySingleGameBinding:714-763` (restore `savedNavBindings` temporário, `SetBinding`, update snapshot, `Restore/ApplyModelRotation`, `SaveBindings`, `ReapplyNavigation`). Demais pickers fallback `SetBinding+SaveBindings` direto (menos seguro).

**Espelhos byte-idênticos (drift risk)**: 4x `KEY_DEFAULTS` — `Keybindings.defaults:87-143`, `KeybindingsList.KEY_DEFAULTS:47-53`, `SBP.KEY_MAPPINGS:27-33`, `BINDS_KEY_DEFAULTS:11510-11516` — e 3x `BAR_DEFS`. Fonte canônica: `Keybindings.defaults + defaultPageActions:441-492`. Ex. `ALT-7` tradeoff `221-229` não atualiza espelhos.

**Alocação de slot**: `defaultPageActions[1]` `A=JUMP` resto `ACTIONBUTTON 1-3/7-10`, `[2-5]` `MULTIACTIONBAR 1-4`; `PAGE1_CANONICAL_SLOTS:86-94` sem `A`; `ResolveTargetSlot:98-120` reutiliza slot existente → canônico p1 → `FindNextEmptySlot:73-84` varre `BAR_DEFS` ordem `1→61→49→25→37`; `ClearBinding:12387` espelha (p1 restaura canônica, resto `nil`).

**Fluxo aplicar**: `card OnClick→OpenPickerForSlot` (bloqueia `A-p1`) `→ShowPickerScreen→SetPickerMode→UpdatePickerSubTabs→RefreshPickerGrid→OnPickerSlotClick:12960` dispatch `SBP:ApplySpellBinding:173 PickupSpell+PlaceAction / BP:ApplyItemBinding PickupContainerItem / MP:ApplyMacroBinding PickupMacro / BARS direto bindingPrefix+slotIndex` + `msg + ActionHUD:Update`.

**Limpar**: `ClearBinding` guard `A-p1`, `PickupAction+ClearCursor` se `HasAction`, `ApplySingleGameBinding` com `nil`/canônica; `HandleBindsClear:12455` via `X` do controle; triggers clique-dir / hint `X` / `CM_CursorSecondary`.

**Riscos P0**: zero `InCombatLockdown` guards — `SaveBindings` sem check; `ReapplyNavigationBindings:696-712 NO GUARD:700` sobrescreve 8 teclas p1 para `CM_CURSOR_*` até sair; `ExitNavigationMode:765-833` **impede sair** se `MainMenuNav/Merchant/Mail` visível → combate+menu aberto = D-Pad perdido; `savedNavBindings` só em `Enter + ApplySingle` → edição externa via `KeyBindingFrame` nativo deixa stale, `Exit` restaura obsoleto; tooltip-scan `scanTip SetAction→TextLeft1` frágil (locale, `NumLines`, `WrapName` byte-wise quebra PT-BR, falso negativo `HasUseEffectInTooltip`).

## 4. Navegação — o gap

**Whitelist Nav** `MainMenuNav:1501-1506`: `TABBAR EQUIP CATS GRID BUFFS PAGENAV SORT SPCAT SPGRID SPTABS SPPAGE TALENTS1/2 QMISSOES QDETALHE ZONAS QNPCS QZONAS QMAPAS QLEITURA QNAV SYS_SUBTABS SYS_GAMEMENU SYS_ADDONCFG` — **sem** `SYS_BINDS* / SYS_PICKER*`. `Nav.focus` sem `bindsIdx/picker*`. `SYSTEM` converte qualquer zona de outras abas → `SYS_SUBTABS` sem cheque `activeSubScreen`.

**Ensure/Apply**: `Nav_EnsureFocus:1326` clamp por aba sem `bindsPage/bindsIdx/picker*`; `Nav_ApplyFocus:1578` pinta `TABBAR/EQUIP/CATS/GRID/.../SYS_*` sem `Nav_PaintBinds/Picker` → foco stale `SYS_ADDONCFG` ao entrar em `BINDS`.

**Cursor legado**: `MainMenuNavActive` gate (`MoveTo/Resync early-return` quando Nav ativo), `FindFirstVisibleButton` sniffer `BINDS/PICKER:533-542`; `HandlePickerNavigation:853` 4 casos `modeButtons↔subTabs↔grid 4x4↔pageBar` — **inativo quando Nav ativo** (`MoveTo` early-return). `MoveDirection:1397` ordem `QuantityPicker→HandlePickerNavigation→HandleQuestNavigation→zoneIdx→espacial genérico` com wrapping penaliza desvios `*2.0`, clusters `left/right` não-lineares → erro de borda + teleport; `BINDS` cai no genérico.

**Keybindings precedência** `Keybindings.lua:1538`: `VK→Merchant→Mail→Nav:OnConfirm/OnCancel (return true consome)→QuestDetail→TalentsBack→SpellsBack→HandleBindsBack:13069→…→CloseTopFrame→ExitNavigationMode`. Nav tem precedência real para `A/B/X/Y`, consome D-pad incondicional quando ativo, **NÃO consome `LT/RT/LB/RB`** (só log). `LT/RT/LB/RB` via `Cursor:CycleTabs/CycleSubTabs→MainMenu:CycleTabs/CycleCategories`. Com `BINDS`: ambos consomem `SelectBindsPage 1..5 wrap` (BINDS sequestra `LB/RB` que deveria trocar `TABBAR`). Com `PICKER`: `LT/RT` cicla `subTabs` de `SYSTEM` invisíveis (bug).

**[B] hoje**: `HandleBindsBack:13069 PICKER→BINDS→ADDON_CFG` chamado **depois** de `Nav:OnCancel em CM_CursorCancel:1538`; funciona mas fora do Nav (`Show/Hide + cursor:MoveTo`, `Nav.focus` stale, `returnZone` não preservado).

**Ordem `[B]` frágil** se `detailOverlay` leak; **duplo trigger** `LT/RT` via `modFrame poll + CM_Nav*`.

## 5. Integração, Legados & Riscos

**Disparo**: `SetBinding physKey→ACTIONBUTTON*` → `UseAction` nativo; `Pickup*/PlaceAction` permitidos no 1.12, sem taint (sem `SecureFrames`). `HideDefaultBars` hijack cosmético.

**Combate**: sem guards em `Keybindings` binds-edit; `ReapplyNavigation` sobrescreve p1 até sair; `Exit` guard impede sair se menu aberto → risco combate documentado `221-229`.

**Legados mortos coexistindo**: `ConfigFrame.lua` (`ConsoleModeSettingsFrame 640x480` via `CM.config:Initialize` sempre, aberto por `/cm config` e `GameMenuButton`), `KeybindingsList` frame (`KBList:Show:145-328` sob `ConfigFrame.contentFrame`), `ActionBarPicker` frame (`120-332` via `KBList:OnKeySelected`). Novo hub já substitui visualmente. `SpellbookPicker/BagPicker/MacroPicker` **puros de DADOS são mantidos** (`SBP.BAR_DEFS`, `ResolveTargetSlot`, `GetSpellTabs`, `Apply*Binding`).

**Outros legados**: `Hooks.lua` lista `problematicFrames+poll OnUpdate` que re-hooka, `Cursor.lua:1855` ref `ConfigFrame` legacy, `Toc` refs. Nenhum `TODO` em binds; tradeoffs documentados (`ALT-7`, `NO GUARD`).

## 6. O que manter / remover / refatorar (tabela)

| Item | Veredito | Nota |
| :--- | :--- | :--- |
| `bindsScreen/pickerScreen` estrutura, `CreateBindCard:11579`, `DetailCard:2762`, clusters D-PAD/ABXY, `UpdateBindsPage:12290`, `FocusBindsSlot:12239`, `RefreshPickerGrid:12721`, `FocusPickerSlot:12895` | **MANTER** | Base visual já conforme sistema; só corrigir widths/overflow |
| `Keybindings` core `ApplySingleGameBinding:714`, `ReapplyNavigation:696`, `ResolveTargetSlot:98`, `savedNavBindings` snapshot | **MANTER** | Endurecer guards combate + stale |
| `SBP/BP/MP` dados (`SBP.BAR_DEFS`, `GetSpellTabs`, `Apply*Binding:173`) | **MANTER** | Desacoplados de frame |
| Cores/fontes/backdrops (`CFG.*`, `0.5,0.4,0.3`, `1,0.85,0.2`, `Alegreya/Marcellus`, `UI-Tooltip-*`) | **MANTER** | Identidade Vanilla |
| `ConfigFrame.lua` + `KeybindingsList` frame + `ActionBarPicker` frame + refs `Hooks/Toc/Cursor:1855` | **REMOVER (arquivar)** | Substituídos pelo hub; manter só módulos de dados |
| `hover` como única fonte de foco, `GameTooltip` em `subTab` | **REMOVER** | Foco só via Nav + `focusBorder` |
| `poll OnUpdate` duplo `LT/RT` (`modFrame` + `CM_Nav*`) | **REMOVER** | Centralizar no Nav |
| 4x `KEY_DEFAULTS` espelhos + 3x `BAR_DEFS` espelhos | **REFATORAR** | Unificar em fonte canônica única (`Keybindings.defaults`) |
| Layout fixo `86/95/248/120/500/496` | **REFATORAR** | `calc via GetRightPanelDimensions` |
| `savedNavBindings` stale + `SaveBindings` sem guard | **REFATORAR** | Re-fotografar só `false→true`, só restaurar se ainda `CM_CURSOR_*`, expor `RefreshSnapshot`, `KB:PersistBindings` centralizado com `InCombatLockdown` |
| `HandlePickerNavigation` fora do Nav + espacial genérico p/ BINDS | **REFATORAR** | Migrar para Nav zones |
| `LB/RB` sequestrado, `LT/RT` atravessando abas escondidas | **REFATORAR** | `LT/RT` consome só quando Nav em `SYS_BINDS/PICKER` |

## 7. Lições de Mapa/Missões aplicáveis

(a) **`EQUIP→SPCAT/TALENTS1` quebrou `[B]`** → adicionar `SYS_BINDS*` à whitelist `1501` + conversão `SYSTEM` por `activeSubScreen` (não genérica para `SYS_SUBTABS`). (b) **Ordem `Nav:OnCancel` vs fallbacks** → `HandleBindsBack:13069` deve ser **dentro** do Nav (antes de `Keybindings` fallback), preservando `returnZone`. (c) **Pool fixo vs recriação** → binds/picker já fixo OK (8 cards + 16 slots); não recriar frames em `Update*`, só `Show/Hide/SetText`. (d) **Pintura foco sem zerar** → `Nav_ApplyFocus:1578` esconde todos os highlights antes de pintar binds/picker (mesmo bug que gerava stale em missões). (e) **`savedNavBindings` stale** → endurecer snapshot (re-fotografar só `false→true`, só restaurar se ainda `CM_CURSOR_*`, expor `RefreshSnapshot`) — igual lição `savedMapBindings`.

## 8. Investigação complementar (pré-F1, sem código, obrigatória antes de tocar MainMenuNav)

- [ ] **I.1 `GetRightPanelDimensions` vs widths fixas:** auditar `MainMenu:UpdateLayout:804` + `GetRightPanelDimensions:775` vs `86/95/248/120/500/496` fixos; definir cálculo de `pageBtnW/modeBtnW/clusterW/gridSlotW` responsivo e validar overflow em `minWidth 840`.
- [ ] **I.2 `PLAYER_REGEN_*` e `PersistBindings`:** mapear onde expor `KB:PersistBindings()` com guarda `InCombatLockdown()` e onde recapturar `savedNavBindings` (`false→true`); avaliar `PLAYER_REGEN_ENABLED` como gatilho seguro.
- [ ] **I.3 `WrapName` PT-BR:** confirmar `ActionBarPicker:98 string.len/sub` byte-wise vs `utf8`; provar se quebra acento e decidir se mantém ou troca por truncamento por `getn`/substring segura Lua 5.0.
- [ ] **I.4 `LT/RT/LB/RB` ponto único de consumo:** validar físicos em `Keybindings.lua` vs `Cursor.lua` + `modFrame:341` poll; decidir quem consome em `BINDS` vs `PICKER` para eliminar duplo trigger.

---

## 9. Plano faseado TESTÁVEL — F1..F5 (parada crítica com /reload ao fim de cada fase)

### F1 — Zonas + Ensure (fiação mínima para o Nav enxergar Binds/Picker)
> **Objetivo de teste:** com `/reload`, o Nav já reconhece `SYS_BINDS_*`/`SYS_PICKER_*` ao entrar em `BINDS`/`PICKER`; `TABBAR` continua estável; `luac -p` limpo. Não precisa pintar nem navegar ainda — só não regredir ao stale `SYS_ADDONCFG`.

- [ ] **F1.1** Criar zonas `MainMenuNav.lua:1501`: `SYS_BINDS` (sub-estado BINDS = `SYS_BINDS_PAGE` + `SYS_BINDS_CARDS`), `SYS_PICKER_MODE`/`SYS_PICKER_SUBTABS`/`SYS_PICKER_GRID`/`SYS_PICKER_PAGEBAR`. Estender `Nav.focus` (`28`) com `bindsPage (1..5)`, `bindsIdx (1..8)`, `pickerMode (1..4)`, `pickerSubTabIdx`, `pickerGridIdx (1..16)`, `pickerPage`, `returnZone`.
- [ ] **F1.2** `Nav_EnsureFocus:1326` — branch `SYSTEM`: quando `pageSystem.activeSubScreen=="BINDS"` converte para `SYS_BINDS_*`, quando `"PICKER"` para `SYS_PICKER_*`; fora disso mantiene `SYS_SUBTABS/GAMEMENU/ADDONCFG` como antes (lição `EQUIP→SPCAT` → não converter genérico). Clamp: `bindsPage 1..5`, `bindsIdx 1..8`, `pickerMode 1..4`, `pickerSubTabIdx` dinâmico via `subTabButtons getn`, `pickerGridIdx` só em slot visível (`HasAction`/`EnableMouse`), `pickerPage 1..maxPages`.
- [ ] **F1.3** Abrir `BINDS` via `[A]` em `ADDON_CFG` já cai em zona Nav válida; fechar `BINDS` sem Nav já não deixa `focus stale`.
- [ ] **F1.4** `luac -p UI/MainMenuNav.lua` + `UI/MainMenu.lua`; `git diff --stat` só `MainMenuNav.lua`.
- **Parada F1 — o que testar no jogo:**
  1. `/reload` → `SYSTEM → ADDON_CFG → [A]` em "Mapeador de Atalhos / Binds" → `BINDS` abre.
  2. Em `BINDS`, apertar `[B]` uma vez → volta a `ADDON_CFG` (mesmo que ainda sem pintura Nav, não pode fechar o MainMenu nem ficar preso).
  3. Em `BINDS`, escolher um card → `PICKER` abre; `[B]` → volta a `BINDS`.
  4. `LB/RB` com `BINDS` aberto não pode fechar o MainMenu nem pular aba para `BAGS/TALENTS` (comportamento atual sequestrado precisa ao menos não travar).
  5. `luac -p` ok.

---

### F2 — Pintura (o Nav passa a pintar; Cursor sai do caminho)
> **Objetivo de teste:** cards, pageButtons, mode/subTab e grid ganham highlight dourado só quando sua zona está focada; ao sair, todos zerados (sem stale — lição QZONAS/QNPCS).

- [ ] **F2.1** `Nav_ApplyFocus:1578` → novos pintores `Nav_PaintBinds` + `Nav_PaintPicker` (padrão `Nav_PaintOneButton:934`):
  - `bindsScreen`: `pageButtons` borda `ouro 1,0.85,0.2` só no `bindsPage` vs apagado nos demais; `bindCards[bindsIdx]` `focusBorder:Show()` + `SetBackdropColor 0.20,0.16,0.06` vs `Hide` nos outros; `DetailCard` via `FocusBindsSlot` sincronizado com `bindsIdx` (3 estados: A-p1 fixo / com ação / vazio) sempre refletindo o índice do Nav.
  - `pickerScreen`: `modeButtons[pickerMode]` ouro, `subTabButtons[pickerSubTabIdx]` ouro, `gridButtons[pickerGridIdx]` `focusBorder` ouro, `Prev/Next` em pageBar quando foco estiver lá; demais escondidos. `DetailCard` via `FocusPickerSlot`.
  - Fora de `SYS_BINDS*`/`SYS_PICKER*`: esconder **todos** os `focusBorder`/`highlight` de binds/picker (sem tocar em `selectedSlotIndex`-like; só visual).
- [ ] **F2.2** Remover (`hover` como única fonte de foco e `GameTooltip` em subTab) apenas como gatilho primário — manter `OnEnter` como espelho para mouse, mas Nav é fonte primária.
- [ ] **F2.3** Garantir gate `MainMenuNavActive()` desativa `Cursor:HandlePickerNavigation` + `MoveDirection` genérico quando Nav pinta binds/picker (mesmo padrão de `QNAV/QNPCS`).
- [ ] **F2.4** `luac -p` em todos os tocados.
- **Parada F2 — o que testar:**
  1. Em `BINDS`, `D-Pad` ainda pode não mover (F3), mas o card aberto já nasce com borda ouro no índice do Nav.
  2. Trocar de página com `LT/RT` (novo ou legado) repinta a pageBar corretamente.
  3. Sair de `BINDS` com `[B]` → `ADDON_CFG` sem `focusBorder` fantasma em cards.
  4. Entrar no `PICKER` → `modeBar` com 1 item dourado, sem dois itens dourados simultâneos.
  5. `luac -p` ok.

---

### F3 — Direções determinísticas + UP→TABBAR (sem espacial genérico)
> **Objetivo de teste:** o jogador navega **sem depender de `Cursor:FindBestInDirection`**: clusters left/right 2×4, modeBar 4, subTabs N, grid 4×4 e pageBar com UP regresso correto (lição SPCAT/TALENTS1 → TABBAR). QOL futuro `LEFT/RIGHT` entre seções só aqui se for leve; senão fica em F5.

- [ ] **F3.1** `Nav:OnDirection` → roteador `Nav_OnBindsDirection` / `Nav_OnPickerDirection` (sem `GetCenter`):
  - `SYS_BINDS_CARDS` 8 cards como matriz `2 colunas × 4 linhas` (`1..4 left, 5..8 right`): `UP` decrementa linha com clamp ou `UP` da fileira 1 → `TABBAR` (com `returnZone="SYS_BINDS_CARDS"` para `DOWN` voltar); `DOWN` oposto; `LEFT` coluna `right→left`, coluna `left` já é limite (não wrap para right); `RIGHT` `left→right`, `right` é limite. Sem wrap circular.
  - `SYS_BINDS_PAGE`: `LEFT/RIGHT` navega entre as 5 páginas com wrap idêntico ao Nav (opcional; LT/RT em F4 é o canônico); `DOWN` → `SYS_BINDS_CARDS` primeira linha da coluna sob o cursor; `UP` → `TABBAR`.
  - `SYS_PICKER_*`: portar `HandlePickerNavigation:853` para índices: `MODE 4` `LEFT/RIGHT` + `DOWN→SUBTABS`; `SUBTABS N` `LEFT/RIGHT` + `UP→MODE` / `DOWN→GRID` linhas 1..4; `GRID 4×4` `UP` primeira fileira → `SUBTABS`, fileira 2..4 `UP/DOWN` entre `row,col`, `LEFT/RIGHT` dentro da fileira, `DOWN` última fileira → `PAGEBAR`; `PAGEBAR` `LEFT/RIGHT` entre `Prev/Next` + `UP→GRID`. Slots vazios (`EnableMouse false`) são **puláveis** mas não navegáveis como destino final.
- [ ] **F3.2** `Nav_OnTabbarDirection` → `DOWN` quando `activeSubScreen=="BINDS"` cai em `SYS_BINDS_CARDS bindsIdx=1` (ou `bindsPage` se já houve página); quando `"PICKER"` cai em `SYS_PICKER_MODE` (espelho de `DOWN TABBAR → BINDS`).
- [ ] **F3.3** `luac -p`; sem `CreateFrame` em runtime, só índices.
- **Parada F3 — o que testar:**
  1. Em `BINDS`, `UP/DOWN/LEFT/RIGHT` movem entre os 8 cards deterministicamente, sem teleport para canto oposto.
  2. `UP` na fileira 1 de `BINDS` sobe ao `TABBAR` (highlight na TabBar, DetailCard de abas); `DOWN` do `TABBAR` retorna a `BINDS` ao mesmo `bindsIdx`.
  3. Em `PICKER`, `modeBar → subTabs → grid → pageBar → grid` navega sem `cursor:MoveTo`.
  4. `[B]` em qualquer sub-zona do Picker não atravessa subTabs escondidas de `SYSTEM`.
  5. `luac -p` ok.

---

### F4 — [A]/[B]/[X] no Nav + LT/RT (consumo único, sem duplicidade)
> **Objetivo de teste:** `[A]` abre/mapeia, `[X]` limpa, `[B]` regressa na pilha determinística `PICKER(_PAGEBAR→GRID→SUBTABS→MODE)→BINDS→ADDON_CFG→SUBTABS→TABBAR→Hide`; `LT/RT` consomem só na zona certa, `LB/RB` liberados.

- [ ] **F4.1** `Nav:OnConfirm [A]`:
  - `SYS_BINDS_CARDS`: guarda `targetBindCard = bindCards[bindsIdx]`; bloqueia `A-p1` (msg `igQuestFailed` já em `OpenPickerForSlot:12369`) preservado; senão `ShowPickerScreen()` → `SetPickerMode(currentMode ou SPELLBOOK)` e entra em `SYS_PICKER_MODE pickerMode=1 subTab=1 grid=1`.
  - `SYS_PICKER_MODE/SUBTABS`: `SetPickerMode` / `RefreshPickerGrid` + foco correspondente (mantém identidade; sem recriar frames).
  - `SYS_PICKER_GRID`: `OnPickerSlotClick` dispatch por modo (`SBP/BP/MP/BARS`) já existente (`12960`) — Nav só resolve `pickerGridIdx → itemData → click`; ao aplicar, `ShowBindsScreen()` + `UpdateBindsPage()` + `Nav_EnsureFocus()` já em `SYS_BINDS_CARDS` com página e `bindsIdx` de origem.
  - `SYS_PICKER_PAGEBAR`: `Prev/Next` → `RefreshPickerGrid` com `gridPage`.
- [ ] **F4.2** `Nav:OnCancel [B]` (prioridade antes do fallback `HandleBindsBack:13069` em `Keybindings:1538`):
  - `PICKER_PAGEBAR → PICKER_GRID`, `PICKER_GRID → PICKER_SUBTABS`, `PICKER_SUBTABS → PICKER_MODE`, `PICKER_MODE → SYS_BINDS` (`ShowBindsScreen()` + `bindsIdx` do `targetBindCard`), `SYS_BINDS_* → ADDON_CFG` (`ShowAddonConfigSubPage()` + `SelectSystemSubTab(ADDON_CFG)` + `returnZone` preservado), depois `ADDON_CFG → SYS_SUBTABS → TABBAR → Hide` já existente (`3988`). Cada transição `Nav_EnsureFocus() + Nav_ApplyFocus() + MMNav_PlayMove() + return true` (consome).
- [ ] **F4.3** `Nav:OnSecondary [X]` (via `CM_CursorSecondary:1455`): só em `SYS_BINDS*` → `ClearBinding(bindsPage, btnKey de bindCards[bindsIdx])` (mesmo guard `A-p1` + `HasAction` + `ApplySingleGameBinding` + `UpdateBindsPage` + `DetailCard` sync).
- [ ] **F4.4** `Nav:OnNext/PrevSubTab` `[LT/RT]` (antes consomem `Cursor:CycleSubTabs`):
  - Em `SYS_BINDS*` → `SelectBindsPage(cur±1 wrap 1..5)` + `bindsPage` + repintar sem sair da zona.
  - Em `SYS_PICKER_GRID` → paginar `gridPage 1..maxPages` do picker (não `SelectBindsPage`).
  - Em `SYS_PICKER_SUBTABS` → ciclar `subTabIdx` (`UpdatePickerSubTabs` + `RefreshPickerGrid`) — não ciclar `GAME_MENU/ADDON_CFG` escondidas (bug antigo).
  - Fora de binds/picker → comportamento `SYSTEM` original intacto (`GAME_MENU/ADDON_CFG` via `SelectSystemSubTab`).
- [ ] **F4.5** `Nav:OnNext/PrevTab` `[LB/RB]` **não** consomem quando Nav em `SYS_BINDS*`/`SYS_PICKER*` — deixam passar para `TABBAR` (corrige "BINDS sequestra LB/RB").
- [ ] **F4.6** Eliminar duplo trigger `LT/RT` centralizando no Nav: `modFrame:341 poll IsControl/Shift/Alt` duplicando `CM_Nav*` é removido ou gateado (`if Nav:IsActive() and activeSubScreen in {BINDS,PICKER} then return`), mantendo 1 consumo por frame.
- [ ] **F4.7** `luac -p` em `UI/MainMenuNav.lua + UI/MainMenu.lua + Keybindings.lua + Cursor.lua`.
- **Parada F4 — o que testar:**
  1. `BINDS`: `[A]` no card abre Picker; `[X]` limpa o card focado (sem clicar com mouse); `[B]` volta a `BINDS` e segundo `[B]` a `ADDON_CFG`.
  2. `PICKER`: `[A]` em `SPELLBOOK / bag / macro / bar` aplica o bind e volta a `BINDS` com o card mapeado já repintado.
  3. `PICKER`: `[B]` sobe `grid→subTabs→mode→binds` sem pular nível.
  4. `BINDS`: `LT/RT` ciclam 5 páginas 1 vez por toque (sem duplo passo).
  5. `BINDS`: `LB/RB` não ciclam mais páginas; `UP` da fileira 1 sobe a `TABBAR`, `LEFT/RIGHT` entre seções só após liberação explícita.
  6. `luac -p` ok.

---

### F5 — Legados + hardening + polimento (sem regressão de abas)
> **Objetivo de teste:** janela legada desativada sem ressurreição, tabelas unificadas sem drift, binds não se perdem em combate, validado `BAGS ⇄ SPELLS ⇄ TALENTS ⇄ QUESTS ⇄ SYSTEM` completo.

- [ ] **F5.1** Arquivar (não reescrever): `ConfigFrame.lua` (`ConsoleModeSettingsFrame`), `KeybindingsList` frame (`KBList:Show 145-328`), `ActionBarPicker` frame (`120-332`) + refs `Hooks:39/555/668-734/835`, `Cursor:1855/1863`, `Toc 13-15`, `Core:167-201` (`CM.config:Initialize` duplicado). Manter `SBP/BP/MP` puros de dados.
- [ ] **F5.2** Unificar espelhos: 4× `KEY_DEFAULTS` → fonte `Keybindings.defaults`, 3× `BAR_DEFS` → `SBP.BAR_DEFS`; `MainMenu:11510 BINDS_KEY_DEFAULTS`/`ActionHUD:26 KEY_MAPPINGS` passam a importar.
- [ ] **F5.3** `KB:PersistBindings()` centralizado (`GetCurrentBindingSet or 1` + `pcall SaveBindings` + guarda `InCombatLockdown()==1 → adiado para PLAYER_REGEN_ENABLED`); endurecer `savedNavBindings` (re-fotografar só `false→true`, restaurar só se ainda `CM_CURSOR_*`, expor `KB:RefreshNavSnapshot()`; `ApplySingleGameBinding:739` já atualiza 1 tecla — manter).
- [ ] **F5.4** Polimento visual pontual: `GetRightPanelDimensions` em `SetupKeybindingsPage`/`RefreshPickerGrid` (sem CreateFrame em runtime, só `SetWidth/SetPoint` responsivo), corrigir `WrapName` PT-BR e `HasUseEffectInTooltip` falsos negativos, manter paleta Bronze/DetailCard/`Marcellus`/`Alegreya` intacta.
- [ ] **F5.5** `luac -p` em todos `.lua` tocados + regressão inter-abas com gamepad e mouse.
- **Parada F5 — o que testar:**
  1. `/cm config` e botões legados não abrem mais janela cinza (ou redirecionam a `SYSTEM → Binds`).
  2. Editar bind → `/reload` → `/logout` → relogar — bind persiste; editar via `KeyBindingFrame` nativo não é revertido ao fechar `MainMenu`.
  3. Abrir `BINDS` e entrar em combate sem fechar → `LT/RT` não dá duplo passo, D-Pad da p1 não fica perdido após `ExitNavigationMode`.
  4. Validar `BAGS/SPELLS/TALENTS/QUESTS/SYSTEM` — foco, sublinhado e `B` em `SPCAT/TALENTS1` continuam ok (regressão F5 completa).
  5. `luac -p` zero erros.

---

## 10. O que falta antes de codar (checklist rápido)

- [ ] Auditar `GetRightPanelDimensions` (I.1) e decidir `SetWidth` responsivo de `pageBtn/modeBtn/cluster/gridSlot` sem recriar frames.
- [ ] Confirmar mapa físico `LT/RT/LB/RB` em `Bindings.xml:95-112` vs `Keybindings:1664/1703` para escolher ponto único de consumo no Nav.
- [ ] Aceitar que A-p1 (Pulo) segue bloqueado com msg — sem alternativa exposta nesta fase.

## 11. Regras do projeto

1. **WoW 1.12.1 / Lua 5.0** — proibido `#t`, `continue`, `goto`, `table.unpack`; usar `table.getn/getn`.
2. **Sem taint** — sem `SecureFrames`; `Pickup*/PlaceAction` OK no 1.12.
3. **Identidade MainMenu** — `MainMenu:ApplyFont` com `CFG.Fonts.titleFontFile (Marcellus-Regular) / bodyFontFile (AlegreyaSans-Bold) / subFontFile (AlegreyaSans-Medium)`, `CFG.Tabs.activeColor 0.88,0.60,0.08`, `CFG.Grid.highlightColor`, backdrops `UI-Tooltip-Background/Border` alpha `0.35-0.50`, `focusBorder` dourado, glifos `CFG.Icons.LT/RT/LB/RB/A/B/X/Y`, `CreateDetailCard` Zelda-style.
4. **`luac -p`** obrigatório em todo `.lua` alterado antes de `/reload`.
5. **Sem commit/push sem autorização explícita**; **parada crítica** ao fim de cada fase para validação no jogo.
6. **Validação incremental** com placeholders antes de conteúdo final.
