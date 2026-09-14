# Mapas de Navegação: BINDS + PICKER

**Data:** 2026-09-14

**Ordem:** 1.BINDS antes de 2.PICKER

**Índice:**
- 1. MAPA DA TELA PRINCIPAL (BINDS)
  - 1.1 Status
  - 1.2 Diagrama
  - 1.3 Fontes
- 2. MAPA DO PICKER
  - 2.1 Status
  - 2.2 Diagrama
  - 2.3 Fontes
  - 2.4 Regras

## 1. MAPA DA TELA PRINCIPAL (BINDS)

### 1.1 Status

**Tela:** [MAPEADOR DE ATALHOS / BINDS]

**Print:** pageBar 1:Base / 2:L2 / 3:R1 / 4:R2 (foco) / 5:L2+R2 + LT/RT, clusters DIRECIONAL (D-PAD) 4 cards + BOTÕES FACIAIS (ABXY) 4 cards, foco atual R2 + D-Pad Esq (SELF ACTIONBUTTON9), footer [A]Mapear [X]Limpar [LT]/[RT]Paginas [B]Voltar.

### 1.2 Diagrama

```
              ============ MAPA DA TELA PRINCIPAL (BINDS) ============
Print: [MAPEADOR DE ATALHOS/BINDS] | Pagina 4:R2 (foco) | Card foco: R2 + D-Pad Esq.

[TABBAR] Bolsas & Itens | Livro de Magias | Talentos | Missoes & Mapa | Configuracoes*
   ^ DOWN (F3 alvo): TABBAR -> BINDS.CARDS (bindsIdx preservado, bindsPage atual)
   ^ UP da fileira 1 (F3 alvo): volta ao TABBAR (returnZone=SYS_BINDS)

+-- PAGEBAR (P1..P5): [1:Base][2:L2][3:R1][4:R2*][5:L2+R2] + LT/RT ----+
| LEFT/RIGHT no Nav: nao navega entre P1..P5 (F3 opcional; canônico=LT/RT)|
| A na pageBar: n/a (foco Nav fica nos CARDS; mouse: SelectBindsPage)     |
+------------------------------------------------------------------------+

+-- CARDS 8 (matriz 2 col x 4 lin; idx 1..8): ----------------------------+
| LEFT cluster (1..4):  1=DUP(Cima)  2=DDOWN(Baixo)                        |
|                       3=DLEFT(Esq*) 4=DRIGHT(Dir)                        |
| RIGHT cluster (5..8): 5=Y  6=X  7=B  8=A                                |
| Print: R2+ D-Pad Esq.=idx3 com borda ouro; demais apagados               |
| UP   : linha 1 (idx1,idx5) -> TABBAR (alvo F3; F1: morto=false)          |
|        linha 2..4 -> idx-1 mesma coluna (ex: idx3->idx2, idx7->idx6)     |
| DOWN : linha 4 (idx4,idx8) = TRAVA (ou PAGEBAR, F3 opcional)             |
|        linha 1..3 -> idx+1 mesma coluna (ex: idx3->idx4)                 |
| LEFT : RIGHT->LEFT mesma linha (idx5->idx1, idx6->idx2, idx7->idx3...)   |
|        LEFT = TRAVA (sem wrap p/ RIGHT)                                  |
| RIGHT: LEFT->RIGHT mesma linha (idx1->idx5, idx3->idx7...)               |
|        RIGHT = TRAVA (sem wrap p/ LEFT)                                  |
| Sem wrap circular. Slots vazios (?) sao destino valido (mapeaveis).     |
| A    : OpenPickerForSlot(bindCards[bindsIdx]) -> SYS_PICKER (bloqueia    |
|        A-pg1/Pulo com msg+igQuestFailed)                                 |
| X    : ClearBinding(page,btnKey) do card focado (bloqueia A-pg1)         |
| B    : -> ADDON_CFG (HandleBindsBack; F4: SYS_BINDS->ADDON_CFG)          |
+-------------------------------------------------------------------------+

BOTOES GLOBAIS NA BINDS (F1 real hoje):
  D-PAD  F1: morto (Nav_OnSysDirection retorna false; Cursor vira no-op com
         Nav ativo; com Nav inativo cai no espacial generico FindBestInDirection)
         F3 alvo: tabela acima, deterministico, sem GetCenter, sem teleport.
  [A]    consome => OpenPickerForSlot(card) => SYS_BINDS -> SYS_PICKER
  [B]    consome => HandleBindsBack() => SYS_BINDS -> SYS_ADDONCFG
  [X]    via HandleBindsClear/ClearBinding (nao pelo OnConfirm do Nav)
  [Y]    sem acao
  [LB/RB] consomem => SEM ACAO (proposital: nao trocar TABBAR)
  [LT/RT] consomem => SelectBindsPage(cur+-1 wrap 1..5) + bindsPage + repinta,
         1 passo por toque (sem duplo trigger modFrame+CM_Nav).
PILHA [B] F4: SYS_BINDS -> ADDON_CFG -> SUBTABS -> TABBAR -> Hide.
```

### 1.3 Fontes

- `UI/MainMenu.lua` SetupKeybindingsPage 11679, BindsScreen 11686, header 11692/11701, backBtn 11705, pageBar 11746/PageBtn 11773, DetailCard 11811/footer 11814, clusters 11842/11865, bindCards 11887/CreateBindCard 11579, BINDS_CLUSTER_DEFS 11536, BINDS_PAGE_INFO 11502, SelectBindsPage 12354, UpdateBindsPage 12290, FocusBindsSlot 12239, OpenPickerForSlot 12367, ClearBinding 12387, HandleBindsClear 12455, ShowBindsScreen 12479, HandleBindsBack 13069
- `UI/MainMenuNav.lua` bindsPage/bindsIdx clamp 1531-1535, Ensure SYSTEM 1591-1624, OnDirection 2696-2705, OnSysDirection 2289-2320 (sem OnBindsDirection), OnConfirm SYS_BINDS 3753-3775, OnCancel SYS_BINDS 4112-4120, OnNext/PrevTab 4493-4509, OnNext/PrevSubTab 4511-4559
- `Keybindings.lua` modFrame 341-420, CM_Nav 1604-1755
- `Cursor.lua` FindFirstVisibleButton 542-548, MoveDirection 1397-1563, FindBestInDirection 731-781 (BINDS sem handler próprio)

## 2. MAPA DO PICKER

**Tela:** [MAPEANDO: R2 + D-Pad Cima] — modeBar Grimório/Bolsas/Macros/Barras, subTabs General/Companions/Elemental/Enhancement/Restoration, grid 4x4, pageBar Anterior/Próxima.

### 2.1 Status

**F1 (comportamento atual):** zona única `SYS_PICKER`, D-pad morto (`OnDirection` retorna `false`), `A`/`LT`/`RT`/`LB`/`RB` consomem sem ação, `B` volta para `SYS_BINDS`.

**Referência comportamental:** `Cursor.lua` `HandlePickerNavigation:853` + alvo F3/F4.

- F3 alvo: navegação direcional completa por regiões (MODEBAR → SUBTABS → GRID → PAGEBAR → TABBAR), sem wrap, sem espacial genérico, UP fileira-1/SUB/MODE => TABBAR com `returnZone`.
- F4 alvo: dispatch de `A` por região, pilha de `B` determinística (PAGEBAR → GRID → SUBTABS → MODE → SYS_BINDS → ADDON_CFG → SUBTABS → TABBAR → Hide), `LT`/`RT` com consumo único e ação contextual, `LB`/`RB` consumindo sem ação no Picker.

### 2.2 Diagrama

```
                          ================= MAPA DO PICKER =================
   Print: [MAPEANDO: R2 + D-Pad Cima] | Mode: Grimorio | Sub: General | Pag: 1 de 1

   [TABBAR] Bolsas & Itens | Livro de Magias | Talentos | Missoes & Mapa | Configuracoes*
      ^ DOWN (F3 alvo): TABBAR -> PICKER.MODE (Grimorio, preserva pickerMode)
      ^ UP do PICKER.MODE (F3 alvo): volta ao TABBAR (returnZone=SYS_PICKER)

   +-- MODEBAR (M1..M4): [Grimorio*][Bolsas][Macros][Barras] ----------------+
   | LEFT : M(i) -> M(i-1)  (trava em M1)                                    |
   | RIGHT: M(i) -> M(i+1)  (trava em M4)                                    |
   | DOWN : M(i) -> SUB mais proxima em X (fallback: GRID R1C1)               |
   | UP   : -> TABBAR (alvo F3; legado consome/bloqueia)                      |
   | A    : SetPickerMode(M) + UpdatePickerSubTabs + RefreshPickerGrid        |
   | B    : -> SYS_BINDS (HandleBindsBack; F4 pilha: MODE->BINDS)             |
   +--------------- DOWN ------------------ UP ------------------------------+
                           v                       ^
   +-- SUBTABS (Sn): [General*][Companions][Elemental][Enhancement][Restor.] -+
   | N varia: SPELLBOOK=GetSpellTabs / BAG=4 / MACROS=2 / BARS=5             |
   | LEFT : S(j) -> S(j-1)  (trava em S1)                                    |
   | RIGHT: S(j) -> S(j+1)  (trava em Sn)                                    |
   | UP   : S(j) -> MODE mais proximo em X                                   |
   | DOWN : S(j) -> GRID fileira 1 (R1C1..R1C4) mais proxima em X            |
   | A    : seleciona subTab + RefreshPickerGrid (foco vai p/ GRID)           |
   | B    : -> MODE (F4 pilha; legado: ->BINDS direto)                        |
   +------------------ DOWN ------------------ UP ---------------------------+
                                  v                       ^
   +-- GRID 4x4 (R1C1..R4C4 = idx 1..16) ------------------------------------+
   | Print: R1: Attack|Blood Fury|Exhaustion|Find Minerals                    |
   |        R2: Find Trees|Skinning|Smelting|Survival                         |
   |        R3-R4: (?) vazios = EnableMouse(false), pulaveis, nao destino    |
   | UP   : fileira 1 -> SUB (X-proxima) | fileira 2..4 -> idx-4 (mesma col)  |
   | DOWN : fileira 4 -> PAGEBAR (col<=2 => <Anterior, senao Proxima>)        |
   |        fileira 1..3 -> idx+4 (mesma col)                                 |
   | LEFT : col 2..4 -> idx-1 | col 1 = TRAVA (sem wrap)                      |
   | RIGHT: col 1..3 -> idx+1 | col 4 = TRAVA (sem wrap)                      |
   | A    : OnPickerSlotClick(slot) -> ApplySpell/Item/Macro/Bar + ShowBinds  |
   | B    : -> SUBTABS (F4 pilha; legado: ->BINDS direto)                     |
   +------------------ DOWN ------------------ UP ---------------------------+
                                  v                       ^
   +-- PAGEBAR: [< Anterior]  Pagina 1 de 1  [Proxima >] ---------------------+
   | (Hide se mode==BARS)                                                    |
   | LEFT : Proxima -> Anterior | RIGHT: Anterior -> Proxima                  |
   | UP   : Anterior -> GRID R4C1 (idx13) | Proxima -> GRID R4C4 (idx16)       |
   | DOWN : TRAVA (consome)                                                  |
   | A    : Anterior => gridPage-1 | Proxima => gridPage+1 + Refresh           |
   | B    : -> GRID (F4 pilha; legado: ->BINDS direto)                        |
   +-------------------------------------------------------------------------+

   BOTOES GLOBAIS NO PICKER (F1 real hoje):
     [B]      consome => HandleBindsBack() => SYS_PICKER -> SYS_BINDS (zone+returnZone)
     [A]      consome => SEM ACAO (F4 alvo: dispatch por regiao acima)
     [X]      sem acao no Picker (so limpa em SYS_BINDS)
     [Y]      sem acao
     [LB/RB]  consomem => SEM ACAO (proposital: nao trocar TABBAR BAGS/TALENTS)
     [LT/RT]  consomem => SEM ACAO (F4 alvo abaixo; bug antigo: cicle GAME_MENU/ADDON_CFG)
     D-PAD    F1: morto (OnDirection retorna false). F3 alvo: tabela acima, sem wrap,
              sem espacial generico, UP fileira-1/SUB/MODE => TABBAR com returnZone.

   F4 ALVO p/ LT/RT (consumo unico, sem duplo trigger modFrame+CM_Nav):
     LT/RT em GRID    => gridPage +-1 (wrap 1..maxPages) + Refresh, sem sair da zona
     LT/RT em SUBTABS => S(j) +-1 + Refresh, sem ciclar GAME_MENU/ADDON_CFG escondidas
     LT/RT em MODE    => consome sem acao (ou nada), nunca SelectBindsPage
     LB/RB em PICKER  => consomem sem acao (liberam TABBAR; fim do sequestro de abas)

   PILHA [B] F4 (deterministica):
     PAGEBAR -> GRID -> SUBTABS -> MODE -> SYS_BINDS -> ADDON_CFG -> SUBTABS -> TABBAR -> Hide
     Cada passo: EnsureFocus + ApplyFocus + PlayMove + return true.
```

### 2.3 Fontes

- `UI/MainMenuNav.lua` (Ensure 1595-1624, OnDirection 2696-2704, OnConfirm 3764-3778, OnCancel 4102-4110, OnNext/PrevTab 4493-4509, OnNext/PrevSubTab 4511-4559)
- `Cursor.lua` (HandlePickerNavigation 853-1078 casos A/B/C/D, MoveDirection 1397-1520)
- `Keybindings.lua` (modFrame 341-420, CM_Nav 1604-1755)
- `UI/MainMenu.lua` (SetupKeybindingsPage 11679, modeBar 11981, subTabBar 12037, grid 12054, pageBar 12152, SetPickerMode 12510, RefreshPickerGrid 12721, FocusPickerSlot 12895, OnPickerSlotClick 12960, ShowPickerScreen 13016, HandleBindsBack 13069)

### 2.4 Regras

- Lua 5.0 estrito.
- Pool fixo, sem `CreateFrame` em runtime.
- Nenhum `.lua` foi alterado; somente este `.md` foi criado.
