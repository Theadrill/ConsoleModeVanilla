# Plano de Feature: TELA DE CONFIGURAÇÕES & SISTEMA (ConsoleMode Main Menu)

> **Arquivo:** `docs/plano_de_feature_TELA_DE_CONFIGURACOES.md`  
> **Referência Técnica e Arquitetural:** Padrão modular estável de `UI/MainMenu.lua`, `UI/MainMenuNav.lua`, `UI/MailScreen.lua` e `UI/MerchantMenu.lua`.  
> **Data:** 13 de Setembro de 2026.

---

> [!IMPORTANT]
> ## REGRAS MANDATÓRIAS DE DESENVOLVIMENTO
> 1. **Versão do Jogo e Linguagem:** World of Warcraft Vanilla 1.12.1 (Interface 11200 / Turtle WoW) em **Lua 5.0 estrito**. Proibido terminantemente o uso de operadores e sintaxe de Lua 5.1+ (como operador `#t`, `continue`, `goto`, `table.unpack`, `string.gmatch`).
> 2. **Anti-Cheat e Segurança Blizzard:** Proibido o uso de automações invasivas ou chamadas que gerem *taint* (`ADDON_ACTION_BLOCKED`). Janelas e rotinas nativas protegidas (Logout, Quit, VideoOptions) devem ser disparadas por gatilhos de clique estritamente seguros ou diálogos oficiais `StaticPopup_Show`.
> 3. **Design System Vanilla MainMenu Rigoroso:**
>    - Tipografia Nobre: `CFG.Fonts.titleFontFile` (`Marcellus-Regular.ttf`), `CFG.Fonts.bodyFontFile` (`AlegreyaSans-Bold.ttf`) e `CFG.Fonts.subFontFile` (`AlegreyaSans-Medium.ttf`).
>    - Paleta de Cores Oficial: Âmbar Dourado (`|cffe09a15`), Dourado Brilhante (`|cffffd100`), Branco Puro (`|cffffffff`), Cinza Suave (`|cffaaaaaa` / `|cff666666`) e Verde Ativado (`|cff00ff00`).
>    - Backdrops escurecidos translúcidos (`UI-Tooltip-Background`), bordas douradas sutis e DetailCard Zelda-style na base para exibição de explicações e tooltips sem poluição visual.
> 4. **Pool Fixo e Gerenciamento de Memória:** Elementos de lista, toggles, sliders e botões devem ser pré-alocados ou reciclados com `:Show()`, `:Hide()` e `:SetText()`, sem recriação destrutiva em tempo de execução.
> 5. **Regra Crítica de Commit & Push:** **NENHUM PUSH AUTOMÁTICO**. O push só ocorre quando o usuário ordenar explicitamente. Nenhum commit intermediário sem aprovação prévia.
> 6. **Parada Crítica por Fase:** Ao final de cada fase (C1 a C5), pausar imediatamente para recarregamento do jogo (`/reload`) e teste no controle pelo usuário.
> 7. **Validação de Sintaxe Prévia:** Todo arquivo alterado deve ser validado via compilador `luac -p` antes de qualquer validação in-game.

---

## 1. Visão Geral da Tela de Configurações (`SYSTEM`)

A aba **Configurações (`SYSTEM`)** do Main Menu consolida em um único ambiente premium de console todas as operações de sistema do World of Warcraft e os ajustes de personalização do **ConsoleModeVanilla**.

### Estrutura em Duas Sub-Abas Principais:
1. **Sub-Aba 1: MENU DO JOGO (`GAME_MENU`)** — Acesso aos menus nativos do cliente WoW Vanilla (Vídeo, Áudio, Interface, Macros, Atalhos de Teclado, Ajuda/Suporte, Logout e Sair do Jogo) e integração automática com botões de Addons de terceiros detectados no jogo.
2. **Sub-Aba 2: CONFIGURAÇÕES DO ADDON (`ADDON_CFG`)** — Central de ajustes avançados do ConsoleMode: Mapeador de Binds integrado, Visibilidade de Barras de Ação, Sensibilidade e Deadzone de Analógicos, Câmera Dinâmica Inteligente, HUD/Posicionamento, Feedback Sonoro e Utilidades (/reload e reset de posições).

---

## 2. Detalhamento da Sub-Aba 1: MENU DO JOGO (`GAME_MENU`)

A sub-aba `GAME_MENU` substitui o visual de menu cinza flutuante da Blizzard por uma lista vertical nobre em formato de cartões interativos.

```
┌────────────────────────────────────────────────────────────────────────┐
│ [SUB-ABAS]   [LT] ◄  [ OPÇÕES DO JOGO ]  •  [ CONFIGURAÇÕES ADDON ]  ► [RT]
├────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ [ 01 ]  [Ícone Vídeo]     Opções de Vídeo           (Blizzard)   │  │
│  │ [ 02 ]  [Ícone Áudio]     Opções de Áudio           (Blizzard)   │  │
│  │ [ 03 ]  [Ícone Interface] Opções de Interface       (Blizzard)   │  │
│  │ [ 04 ]  [Ícone Macros]    Gerenciador de Macros     (Blizzard)   │  │
│  │ [ 05 ]  [Ícone Atalhos]   Atalhos de Teclado        (Blizzard)   │  │
│  │ [ 06 ]  [Ícone Ajuda]     Ajuda & Suporte ao GM     (Blizzard)   │  │
│  │ [ 07 ]  [Ícone Addon]     Configuração: SuperMacro  (Addon)      │  │
│  │ [ 08 ]  [Ícone Logout]    Desconectar Personagem    (Sistema)    │  │
│  │ [ 09 ]  [Ícone Sair]      Sair do World of Warcraft (Sistema)    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────────────────────┤
│ [ DETAIL CARD - INFORMAÇÃO CONTEXTUAL ]                                │
│  ► Opções de Vídeo                                                     │
│    Ajuste de resolução, qualidade gráfica, taxa de quadros e brilho.  │
│    [A] Abrir Janela  •  [D-Pad UP/DOWN] Navegar  •  [B] Fechar Menu    │
└────────────────────────────────────────────────────────────────────────┘
```

### Funcionalidades e Regras da Sub-Aba `GAME_MENU`:
- **Scan Dinâmico de Botões:** Utiliza `ScanGameMenuButtons()` para ler botões registrados no `GameMenuFrame` (incluindo addons como SuperMacro, aux-addon, etc.).
- **Ícones Temáticos Contextuais:** Atribuição determinística de texturas para cada tipo de entrada:
  - Vídeo: `Interface\Icons\INV_Misc_Eye_01` ou `Spell_Shadow_PsychicScream`
  - Áudio: `Interface\Icons\INV_Misc_Ear_Human_01` ou `Spell_Shadow_Teleport`
  - Interface: `Interface\Icons\INV_Misc_Gear_01`
  - Macros: `Interface\Icons\INV_Misc_Book_09`
  - Atalhos: `Interface\Icons\INV_Misc_Key_04`
  - Ajuda: `Interface\Icons\INV_Misc_QuestionMark`
  - Logout / Sair: `Interface\Icons\Spell_Nature_TimeStop` / `Interface\Icons\Spell_Shadow_SacrificialShield`
- **Execução Segura:**
  - Opções que abrem janelas Blizzard (Vídeo, Áudio, Macros): fecham suavemente o MainMenu e abrem a tela alvo sem gerar conflito de camadas.
  - Logout e Sair: acionam diretamente a confirmação nativa segura `Logout()` / `Quit()` ou os diálogos `StaticPopup_Show("CAMP")` e `StaticPopup_Show("QUIT")`.
- **DetailCard Atualizado em Tempo Real:** Cada entrada foca um texto explicativo e objetivo sobre o que o botão faz.

---

## 3. Detalhamento da Sub-Aba 2: CONFIGURAÇÕES DO ADDON (`ADDON_CFG`)

Central de controle das opções do ConsoleMode, dividida em cartões de controle e widgets operáveis 100% via D-Pad:

```
┌────────────────────────────────────────────────────────────────────────┐
│ [SUB-ABAS]   [LT] ◄  [ OPÇÕES DO JOGO ]  •  [ CONFIGURAÇÕES ADDON ]  ► [RT]
├────────────────────────────────────────────────────────────────────────┤
│ ┌── [ MAPEAMENTO & ATALHOS ] ────────────────────────────────────────┐ │
│ │ [ 01 ] Mapeador de Atalhos / Binds                 [ ABRIR TELA > ]│ │
│ ├── [ INTERFACE & HUD ] ─────────────────────────────────────────────┤ │
│ │ [ 02 ] Barras de Ação da Direita (Blizzard)        [ ATIVADO ]     │ │
│ │ [ 03 ] Exibir Dicas de Botões no HUD (KeyHints)    [ ATIVADO ]     │ │
│ │ [ 04 ] Escala do HUD do ConsoleMode                ◄── [ 100% ] ──►│ │
│ ├── [ CONTROLE & SENSIBILIDADE ] ────────────────────────────────────┤ │
│ │ [ 05 ] Deadzone dos Analógicos (Zona Morta)        ◄── [ 15% ] ───►│ │
│ │ [ 06 ] Sensibilidade do Cursor Virtual             ◄── [ 1.2x ] ──►│ │
│ │ [ 07 ] Velocidade de Pan do Mapa (L-Stick)         ◄── [ 1.0x ] ──►│ │
│ ├── [ CÂMERA INTELIGENTE ] ──────────────────────────────────────────┤ │
│ │ [ 08 ] Auto-Pitch de Câmera em Movimento           [ ATIVADO ]     │ │
│ ├── [ SISTEMA & UTILIDADES ] ────────────────────────────────────────┤ │
│ │ [ 09 ] Resetar Posições dos Elementos de UI        [ RESTAURAR ]   │ │
│ │ [ 10 ] Recarregar Interface (/reload)              [ EXECUTAR ]    │ │
│ └────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────┤
│ [ DETAIL CARD - INFORMAÇÃO CONTEXTUAL ]                                │
│  ► Deadzone dos Analógicos (Zona Morta: 15%)                           │
│    Evita movimentos involuntários ou drift no analógico esquerdo.     │
│    [D-Pad LEFT/RIGHT] Ajustar Valor  •  [D-Pad UP/DOWN] Navegar        │
└────────────────────────────────────────────────────────────────────────┘
```

### Tipos de Widgets D-Pad:
1. **Toggle Widget (`[A]`):**
   - Alterna booleano entre `[ ATIVADO ]` (`|cff00ff00`) e `[ DESATIVADO ]` (`|cff888888`).
   - Salva imediatamente na tabela `ConsoleModeDB`.
   - Executa callback de sincronização visual em tempo real.
2. **Slider Widget (`[D-Pad LEFT / RIGHT]`):**
   - Permite incremento/decremento com passo configurável (ex: 5% em 5%, 0.1 em 0.1).
   - Exibe barra visual com valor central formatado.
   - Aplica a alteração imediatamente sem necessidade de confirmação extra.
3. **Action Button Widget (`[A]`):**
   - Executa funções imediatas como `/reload`, reset de frames ou abertura do Mapeador de Binds (`SYS_BINDS`).

---

## 4. Mapa Completo de Navegação D-Pad (`MainMenuNav.lua`)

```
                        ┌──────────────────────────────┐
                        │   ZONA: SYS_SUBTABS          │
                        │  [GAME_MENU] ◄──► [ADDON_CFG]│
                        └──────────────┬───────────────┘
                     [LT] / [RT]       │  D-Pad DOWN
                     (Ciclo Direto)    ▼
        ┌──────────────────────────────┴──────────────────────────────┐
        │                                                             │
        ▼                                                             ▼
┌──────────────────────────────┐              ┌──────────────────────────────┐
│  ZONA: SYS_GAMEMENU          │              │  ZONA: SYS_ADDONCFG          │
│  • Opções de Vídeo           │              │  • Mapeador de Binds         │
│  • Opções de Áudio           │              │  • Barras de Ação (Toggle)   │
│  • Opções de Interface       │              │  • Deadzone (Slider L/R)     │
│  • Macros / Atalhos          │              │  • Sensibilidade (Slider L/R)│
│  • Logout / Sair             │              │  • Reset UI / ReloadUI       │
│                              │              │                              │
│  D-Pad UP/DOWN: Rola lista   │              │  D-Pad UP/DOWN: Rola lista   │
│  [A]: Abre janela / Popup    │              │  [A]: Toggle / Ação          │
│  [B]: Fecha MainMenu         │              │  D-Pad L/R: Ajusta Slider    │
└──────────────────────────────┘              └──────────────┬───────────────┘
                                                             │ [A] no Mapeador
                                                             ▼
                                              ┌──────────────────────────────┐
                                              │  ZONA: SYS_BINDS             │
                                              │  (Mapeador Integrado)        │
                                              │  [B]: Retorna para ADDON_CFG │
                                              └──────────────────────────────┘
```

### Regras de Roteamento no `MainMenuNav.lua`:
- **Ciclo Global de Sub-Abas (`[LT]` / `[RT]`):**
  - Estando em qualquer zona da aba `SYSTEM`, apertar `[LT]` ou `[RT]` alterna instantaneamente entre as sub-abas `GAME_MENU` e `ADDON_CFG`, mantendo o foco no primeiro item válido da lista correspondente.
- **Zona `SYS_GAMEMENU`:**
  - `D-Pad UP / DOWN`: Navegação sequencial vertical entre os botões detectados.
  - `Botão [A]`: Executa o clique do botão associado ou dispara o popup seguro.
  - `Botão [B]`: Fecha o MainMenu.
- **Zona `SYS_ADDONCFG`:**
  - `D-Pad UP / DOWN`: Navegação sequencial vertical entre os itens de configuração.
  - `Botão [A]`:
    - Em Toggles: inverte o estado e atualiza o texto/badge.
    - Em Botões de Ação: executa a rotina (ex: transição para `SYS_BINDS` ou `ReloadUI()`).
  - `D-Pad LEFT / RIGHT`:
    - Em Sliders: incrementa/decrementa o valor numérico respeitando limites `min` e `max`.
  - `Botão [B]`: Fecha o MainMenu.

---

## 5. Cronograma de Fases TESTÁVEIS Passo a Passo

---

### 🟢 FASE C1: Estrutura Base, Barra de Sub-Abas e DetailCard Integrado
> **Objetivo de Teste:** O jogador abre o Main Menu na aba Configurações (`SYSTEM`). A barra de sub-abas superior responde perfeitamente aos gatilhos `[LT]` e `[RT]`. O `DetailCard` inferior atualiza suas informações e botões de ajuda conforme a sub-aba ativa. As zonas `SYS_SUBTABS`, `SYS_GAMEMENU` e `SYS_ADDONCFG` são registradas no `MainMenuNav.lua`.

- [ ] **C1.1.** Padronização do container `pageSystem` em `UI/MainMenu.lua` seguindo o design system do MainMenu (backdrop translúcido, bordas nobres, título estilizado).
- [ ] **C1.2.** Criação e ancoragem do `DetailCard` dedicado no rodapé da página `SYSTEM`, reutilizando `MainMenu:CreateDetailCard()`.
- [ ] **C1.3.** Barra de Sub-Abas estilizada com glifos `[LT]` e `[RT]` e alternância estável entre `GAME_MENU` e `ADDON_CFG`.
- [ ] **C1.4.** Registro e roteamento inicial das zonas no `UI/MainMenuNav.lua` (`SYS_SUBTABS`, `SYS_GAMEMENU`, `SYS_ADDONCFG`).
- [ ] **C1.5.** Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE C1):**
  - O jogador faz `/reload` no jogo.
  - Abre a aba Configurações pelo D-Pad ou menu.
  - Pressiona `[LT]` e `[RT]` e valida a troca suave entre as sub-abas sem piscar e sem erros de script.
  - Valida se o `DetailCard` exibe as informações contextuais corretas.

---

### 🟢 FASE C2: Sub-Aba 1 (Menu do Jogo - `GAME_MENU`) com Ícones e Execução Segura
> **Objetivo de Teste:** O jogador navega pela lista do `GAME_MENU` via `D-Pad UP / DOWN`. Cada item exibe seu ícone temático e badge estilizado. Ao passar por uma opção, o `DetailCard` detalha a função do botão. Ao pressionar `[A]`, abre a janela correspondente (Vídeo, Áudio, Interface, Macros) ou aciona a confirmação de Logout/Quit com total segurança.

- [ ] **C2.1.** Refatoração do `ScanGameMenuButtons()` e `UpdateGameMenuSubPage()` com pool fixo de até 16 botões estilizados em `UI/MainMenu.lua`.
- [ ] **C2.2.** Mapeamento dos ícones clássicos temáticos para cada botão nativo (Vídeo, Áudio, Interface, Atalhos, Macros, Ajuda, Logout, Sair).
- [ ] **C2.3.** Integração do `DetailCard` para cada item focado no `SYS_GAMEMENU`.
- [ ] **C2.4.** Execução segura dos comandos ao apertar `[A]`:
  - Fechamento suave do MainMenu antes de exibir janelas de configuração pesadas da Blizzard.
  - Confirmação de Logout/Quit via popups oficiais.
- [ ] **C2.5.** Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE C2):**
  - O jogador faz `/reload`.
  - Navega pelos botões do `GAME_MENU` com o D-Pad e valida a exibição dos ícones e textos.
  - Testa abrir as Opções de Vídeo e Macros com `[A]`.
  - Testa selecionar Logout e valida a abertura do popup seguro de confirmação.

---

### 🟢 FASE C3: Sub-Aba 2 (Configurações do Addon - `ADDON_CFG`) com Widgets D-Pad
> **Objetivo de Teste:** O jogador acessa `ADDON_CFG`. A lista apresenta categorias claras com opções de Toggle (`[A]`), Sliders (`[LEFT / RIGHT]`) e Botões de Ação. Alterar qualquer valor reflete imediatamente no jogo e é salvo em `ConsoleModeDB`.

- [ ] **C3.1.** Estruturação da lista de opções de configuração em `UI/MainMenu.lua` com suporte a tipos de widgets: `TOGGLE`, `SLIDER` e `ACTION`.
- [ ] **C3.2.** Implementação dos Toggles com `[A]`:
  - Barras da Direita (Blizzard): ativa/desativa visibilidade.
  - Dicas de Controle (KeyHints HUD): ativa/desativa exibição.
  - Auto-Pitch de Câmera: ativa/desativa ajuste inteligente de inclinação.
- [ ] **C3.3.** Implementação dos Sliders com `[D-Pad LEFT / RIGHT]`:
  - Deadzone dos analógicos (5% a 30%, passo de 5%).
  - Sensibilidade do cursor virtual (0.5x a 3.0x, passo de 0.1x).
  - Velocidade do Pan de Mapa (0.5x a 2.5x, passo de 0.1x).
- [ ] **C3.4.** Conexão direta com `ConsoleModeDB` e aplicação instantânea de cada propriedade.
- [ ] **C3.5.** Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE C3):**
  - O jogador faz `/reload`.
  - Alterna os toggles com `[A]` e valida a mudança visual imediata.
  - Ajusta os sliders com `LEFT / RIGHT` e valida o feedback numérico na barra.
  - Executa a ação de Resetar Posições de UI e valida a mensagem no chat.

---

### 🟢 FASE C4: Integração do Mapeador de Binds no Main Menu (`SYS_BINDS`)
> **Objetivo de Teste:** Ao selecionar *"Mapeador de Atalhos / Binds"* na sub-aba `ADDON_CFG` e apertar `[A]`, o conteúdo do Main Menu transiciona suavemente para a interface integrada de Mapeamento de Binds (estilo tela de Talentos), sem abrir janelas cinzas flutuantes. Ao pressionar `[B]`, retorna de forma limpa para a sub-aba `ADDON_CFG`.

- [ ] **C4.1.** Portar a tela principal de Mapeamento de Combinações (`KeybindingsList.lua`) para dentro do container de sub-página `SYS_BINDS` no `UI/MainMenu.lua`.
- [ ] **C4.2.** Roteamento da zona `SYS_BINDS` no `UI/MainMenuNav.lua`:
  - Navegação pelos clusters de botões do controle (D-Pad, ABXY, Gatilhos e Ombros).
  - `[A]` abre o seletor integrado de magias/itens (`Picker`).
  - `[B]` cancela/volta para a lista de `ADDON_CFG`.
- [ ] **C4.3.** Desativação completa da antiga janela flutuante `ConfigFrame.lua` legada.
- [ ] **C4.4.** Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE C4):**
  - O jogador faz `/reload`.
  - Entra no Mapeador de Binds pelo Main Menu e valida a navegação interna nos botões do gamepad.
  - Testa voltar com `[B]` para a lista de opções do addon.

---

### 🟢 FASE C5: Polimento Visual, Efeitos Sonoros e Teste Geral de Regressão
> **Objetivo de Teste:** A tela de configurações opera com fluidez máxima. Sons de navegação e confirmação tocam apropriadamente. A transição entre abas (Bolsas, Magias, Talentos, Missões, Configurações) mantém todos os estados íntegros. Zero erros de script e zero *taint*.

- [ ] **C5.1.** Integração dos efeitos sonoros oficiais de seleção e clique (`PlaySound(CFG.Audio.soundItemSelect)`).
- [ ] **C5.2.** Refinamento de cores de seleção, realces dourados e alinhamentos de texto.
- [ ] **C5.3.** Teste de regressão inter-abas completo (Bolsas ⇄ Magias ⇄ Talentos ⇄ Missões & Mapa ⇄ Configurações).
- [ ] **C5.4.** Validação final de sintaxe via `luac -p` em todos os módulos tocados.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE C5):**
  - O jogador realiza o teste completo com gamepad e mouse em todo o ecossistema do addon.

---

## 6. Resumo de Arquivos Impactados

| Arquivo | Natureza da Modificação |
| :--- | :--- |
| `docs/plano_de_feature_TELA_DE_CONFIGURACOES.md` | **Este documento** de planejamento arquitetural e UX da tela de Configurações. |
| `UI/MainMenu.lua` | Refatoração da página `SYSTEM`, sub-páginas `GAME_MENU`, `ADDON_CFG`, `SYS_BINDS`, widgets D-Pad e DetailCard. |
| `UI/MainMenuNav.lua` | Roteador direcional D-Pad para zonas `SYS_SUBTABS`, `SYS_GAMEMENU`, `SYS_ADDONCFG` e `SYS_BINDS`. |
| `ConfigFrame.lua` / `KeybindingsList.lua` | Desativação de frames legados flutuantes e redirecionamento para o Main Menu. |

---

## 7. Compromisso de Execução
- **SEM PUSH AUTOMÁTICO.**
- **SEM COMMITS INTERMEDIÁRIOS SEM AUTORIZAÇÃO.**
- **PARADA OBRIGATÓRIA NO FIM DE CADA FASE PARA VALIDAÇÃO NO JOGO PELO USUÁRIO.**

---

## 8. PRÓXIMA TELA: BINDS DO ADDON (levantamento concluído — falta investigação complementar + plano de implementação)

Última tela pendente do MainMenu. Levantamento técnico profundo concluído (somente leitura, nada modificado). **Ainda falta: investigação complementar + plano de implementação em fases.**

### 8.1 Fluxo de acesso
- Entrada: Sub-Aba 2 → 1ª linha "Mapeador de Atalhos / Binds" (`MainMenu.lua:11300`, `UpdateAddonConfigSubPage`) → `ShowBindsScreen()`.
- Binds (`ConsoleModeMM_BindsScreen`, `11686`) e Picker (`ConsoleModeMM_PickerScreen`, `11893`) são **sub-estados** (`pageSystem.activeSubScreen`: `nil`/`BINDS`/`PICKER`), frames irmãos criados uma vez via `SetupKeybindingsPage()` (`11679`).
- `[B]` volta pela pilha `HandleBindsBack()` (`13069`): PICKER→BINDS→ADDON_CFG (via `CM_CursorCancel` + botões Voltar).

### 8.2 Estrutura visual (funciona, não reescrever)
- bindsScreen: header + barra de 5 páginas (Base/L2/R1/R2/L2+R2, LT/RT) + DetailCard inferior + pool de 8 cards (4 D-Pad + 4 ABXY, `CreateBindCard()`, `11579`), cada um com ícone, badge do combo, nome da ação e borda de foco.
- pickerScreen: header `[ MAPEANDO: <combo> ]` + 4 modos (Grimório/Bolsas/Macros/Barras) + sub-abas dinâmicas + grade 4×4 (`PickerSlot1..16`) + paginação.

### 8.3 Modelo de dados (funciona, unificar espelhos)
- Binds vivem nos **bindings nativos do WoW** (`GetBindingAction`/`SetBinding` + `SaveBindings`), não em SV do addon.
- Formato: (página 1-5, botão) → tecla física → ação (`ACTIONBUTTONn`/`MULTIACTIONBARnBUTTONn`/`JUMP`...).
- **3 tabelas-espelho** (`Keybindings.defaults`, `SBP.KEY_MAPPINGS`, `BINDS_KEY_DEFAULTS`): unificar pontualmente, sem rewrite.
- Escrita única segura: `KB:ApplySingleGameBinding()` (`Keybindings.lua:714`).

### 8.4 Edição (funciona, manter)
- Slot → picker → conteúdo → confirmar (`Pickup*+PlaceAction` + `ApplySingleGameBinding`); sem captura de input, mapeamento físico fixo.
- Limpar: clique direito / `[X]` / botão X; A-pág1 (Pulo) bloqueado.

### 8.5 Navegação gamepad — O MAIOR GAP (é aqui que o trabalho está)
- **Não existem zonas `SYS_BINDS_*` no `MainMenuNav`** (só `SYS_SUBTABS`/`SYS_GAMEMENU`/`SYS_ADDONCFG`).
- O que funciona hoje vem do **Cursor legado** (D-Pad geométrico, `[A]` clica, `[B]` via fallback, `[X]` limpa, `[LT]/[RT]` troca páginas).
- Trabalho futuro = **fiação, não reconstrução**: criar zonas `SYS_BINDS_*`, pintura de foco, handlers direcionais, `[A]/[B]` no Nav.

### 8.6 Integração e legados
- Disparo 100% nativo via ActionBar; sem taint prático no 1.12; sem guardas de combate na edição.
- Legado morto candidato a arquivamento (não rewrite): `ConfigFrame.lua`, frame do `KeybindingsList`, frame do `ActionBarPicker`.
- Leitura de nomes via tooltip-scan é frágil; `savedNavBindings` pode reverter edição externa — endurecer depois.

---

## 9. QOL FUTURO: LEFT/RIGHT GLOBAL ENTRE SEÇÕES (visão geral, sem profundidade)

Como passo futuro de qualidade de vida, a ideia é aplicar por cima o mesmo atalho LEFT/RIGHT de troca de seção/sub-aba usado na tela SYSTEM em todas as telas do addon, sem detalhar implementação agora.
