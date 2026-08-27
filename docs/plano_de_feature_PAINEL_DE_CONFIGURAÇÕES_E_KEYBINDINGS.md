# Plano de Feature: Painel de Configurações e Mapeamento Visual de Keybindings

## 📌 Visão Geral

Este documento descreve o plano arquitetural, fluxo de UX e o **passo a passo atômico de implementação** para o **Painel de Configurações** (`ConsoleMode - Settings`) e o sistema de **Mapeamento Visual de Barras de Ação (ActionBars Picker)** no cliente World of Warcraft 1.12 (Vanilla / Turtle WoW).

---

## 🎯 Fluxo Completo da Experiência do Jogador (UX)

```
[ 1. GameMenuFrame ] ──> Clica em "ConsoleMode - Settings" (1º botão no topo)
         │
         ▼
[ 2. Painel de Configurações ] ──> Clica na aba "Keybindings"
         │
         ▼
[ 3. Lista de Combinações ] ──> Seleciona uma tecla (ex: L2 + X) e aperta [A]
         │
         ▼
[ 4. Menu de Destino ] ──> Escolhe "ActionBars" e aperta [A]
         │
         ▼
[ 5. Modo Picker Visual ]
  • Janela de config minimiza
  • Todas as barras de ação na tela são destacadas
  • Jogador navega com o D-Pad pelos slots reais de habilidades
  • Ao apertar [A] no slot desejado:
      => Salva o atalho no jogo (SetBinding + SaveBindings)
      => Reabre a lista com o slot atualizado!
  • Ao apertar [B]: Cancela e volta para a lista sem alterar.
```

---

## 🪜 Roteiro de Implementação Passo a Passo (Atômico e Testável)

A implementação será executada em **7 passos progressivos**, onde cada etapa pode ser testada e validada individualmente no jogo antes de avançar para a próxima:

---

### 🔹 PASSO 1: A Base Modular de UI & Comandos
- **Objetivo**: Criar a infraestrutura de pastas e carregamento de interface do addon.
- **Tarefas**:
  1. Criar o diretório `UI/` dentro do addon.
  2. Criar os arquivos iniciais `UI/ConfigFrame.lua`, `UI/KeybindingsList.lua` e `UI/ActionBarPicker.lua`.
  3. Registrar os novos arquivos no `ConsoleModeVanilla.toc`.
  4. Adicionar os comandos de chat `/cm config`, `/cm settings` e `/cm binds` no `Core.lua`.
- **🧪 Critério de Teste**: Digitar `/cm config` e ver o log no chat confirmando o carregamento da base de UI.

---

### 🔹 PASSO 2: Injeção do Botão no Topo do Menu Principal (`GameMenuFrame`)
- **Objetivo**: Inserir a opção `ConsoleMode - Settings` em primeiro lugar no menu do jogo.
- **Tarefas**:
  1. No `Hooks.lua`, criar o botão `GameMenuButtonConsoleMode` com o visual nativo da Blizzard.
  2. Expandir dinamicamente a altura do `GameMenuFrame` (+30px).
  3. Deslocar os botões nativos (`Options`, `Sound`, `UI Options`, `Macros`, etc.) para baixo.
  4. Posicionar o botão do ConsoleMode no topo com o texto `|cff00ff00ConsoleMode - Settings|r`.
  5. Ao clicar no botão: fecha o GameMenu e chama `ConsoleMode.config:Toggle()`.
- **🧪 Critério de Teste**: Pressionar <kbd>Start</kbd> no jogo e ver o novo botão no topo do menu, responsivo ao D-Pad e mouse.

---

### 🔹 PASSO 3: A Janela do Painel de Configurações (`ConsoleModeSettingsFrame`)
- **Objetivo**: Construir a janela principal de opções com abas laterais.
- **Tarefas**:
  1. Criar o frame flutuante centralizado com as texturas clássicas da Blizzard (`DialogBox-Background` e bordas douradas).
  2. Criar a coluna lateral de abas (com a primeira opção: **Atalhos / Keybindings**).
  3. Adicionar suporte nativo ao D-Pad para navegar entre as abas e fechar a janela com <kbd>B</kbd> ou <kbd>Start</kbd>.
  4. Adicionar rodapé informativo com prompts do controle: `[A] Selecionar`, `[B] Fechar`.
- **🧪 Critério de Teste**: Clicar em "ConsoleMode - Settings" no menu e ver a janela de opções abrir e fechar perfeitamente pelo controle.

---

### 🔹 PASSO 4: Lista de Combinações de Teclas (Keybindings List)
- **Objetivo**: Renderizar no painel direito a lista de combinações das 5 páginas de ação.
- **Tarefas**:
  1. Criar a visualização das 5 páginas (Página 1: Base, Página 2: L2, Página 3: R1, Página 4: R2, Página 5: L2+R2).
  2. Listar as 8 combinações de cada página (A, B, X, Y, D-Pad Cima, Baixo, Esquerda, Direita).
  3. Ler os bindings atuais do jogador em tempo real e exibir ao lado de cada botão:
     - Nome da ação vinculada.
     - Ícone da habilidade/item colocado naquele slot (via `GetActionTexture`).
  4. Permitir navegar por toda a lista de 40 combinações usando o D-Pad.
- **🧪 Critério de Teste**: Abrir a aba de Keybindings e visualizar com precisão todos os 40 slots e suas magias atuais.

---

### 🔹 PASSO 5: Menu de Destino da Ação (Submenu Modal)
- **Objetivo**: Abrir as opções de mapeamento ao selecionar uma combinação.
- **Tarefas**:
  1. Ao pressionar <kbd>A</kbd> sobre uma combinação da lista (ex: `L2 + X`), abrir uma janela modal com as opções:
     - 🎯 **Barras de Ação (ActionBars)** *(Escolher slot na tela)*
     - 🗑️ **Desvincular Atalho (Limpar)** *(Remove a ação daquele botão)*
     - ❌ **Voltar**
  2. Navegação ágil com D-Pad e confirmação com <kbd>A</kbd>.
- **🧪 Critério de Teste**: Selecionar qualquer botão da lista e ver o submenu abrir com foco automático.

---

### 🔹 PASSO 6: O Mapeador Visual Interativo de ActionBars (O Picker)
- **Objetivo**: Permitir que o jogador escolha o slot diretamente nas barras de ação na tela.
- **Tarefas**:
  1. **Modo Picker**: A janela de configurações se oculta temporariamente e surge um banner superior:
     `|cff00ff00Mapeando: [L2 + X]|r — Navegue com o D-Pad e aperte [A] no slot desejado ([B] Cancelar)`.
  2. **Iluminação de Slots**: Identificar e aplicar moldura de destaque pulsante em todos os slots de todas as barras visíveis (Principal, BottomLeft, BottomRight, RightBar, LeftBar, Bonus/Stance).
  3. **Navegação Spatial pelos Slots**: O D-Pad transita suavemente de um slot para o outro na tela, abrindo o `GameTooltip` oficial da magia/item.
  4. **Gravação do Binding**: Ao apertar <kbd>A</kbd>:
     - Salva o binding via `SetBinding(tecla, "ACTIONBUTTON" .. id)` ou `CM_ACTION_...`.
     - Grava permanentemente com `SaveBindings(GetCurrentBindingSet())`.
     - Reabre o painel de configurações com a lista atualizada e com o novo ícone!
  5. **Cancelamento**: Ao apertar <kbd>B</kbd>, sai do modo picker sem alterar nada.
- **🧪 Critério de Teste**: Mapear uma habilidade diretamente escolhendo um slot na barra e usar a magia em combate!

---

### 🔹 PASSO 7: Polimento, Compatibilidade de Addons e Documentação
- **Objetivo**: Garantir estabilidade com interfaces customizadas e documentar.
- **Tarefas**:
  1. Compatibilidade do Picker com as barras de ação de addons (ex: Turtle-Dragonflight UI e pfUI).
  2. Ajustes de animações e polimento visual dos destaques.
  3. Atualização do `README.md` com as novas instruções de configuração in-game.
- **🧪 Critério de Teste**: Teste geral de ponta a ponta com controle físico e teclado.
