# ConsoleMode - Vanilla

> ⚠️ **Aviso Legal**: Todo o código deste projeto foi desenvolvido tendo como base de referência e inspiração projetos open source da comunidade:
> - **[ConsoleExperienceClassic](https://github.com/pepordev/ConsoleExperienceClassic)** — addon para WoW 1.12 / Turtle WoW que serviu como referência técnica principal para a lógica de cursor de navegação, hooks de UI e compatibilidade com a API Vanilla.
> - **[ConsoleUI](https://github.com/racha/ConsoleUI)** — addon para WoW 1.12 / Turtle WoW que serviu como referência técnica para a solução de Smart Mouse Look (travamento de câmera persistente via companion binding no Steam Input).
> - **[ConsolePort](https://github.com/seblindfors/ConsolePort)** — addon para WoW Retail (licença [The Artistic License 2.0](https://github.com/seblindfors/ConsolePort/blob/master/LICENSE.md)) que serviu como referência de UX, design de experiência com controle e visão de produto.
>
> O ConsoleMode - Vanilla é um projeto derivado e independente, não afiliado a nenhum dos projetos acima.

**ConsoleMode - Vanilla** é um addon de experiência com controle/gamepad construído para World of Warcraft 1.12 (Vanilla / Turtle WoW), especialmente desenvolvido para dispositivos portáteis como o Steam Deck e para jogadores que preferem usar controles no PC.

---

## 🎯 Objetivo

Trazer uma experiência moderna de controle inspirada no renomado addon **ConsolePort** (disponível para o WoW Retail) para o cliente 1.12 Vanilla / Turtle WoW, com foco em performance, modularidade e navegação fluida de interface.

---

## 📜 Créditos

- **ConsoleExperienceClassic**: Agradecimentos e créditos aos criadores e contribuidores do `ConsoleExperienceClassic` pela lógica de navegação via cursor e implementações de referência que inspiraram o sistema de navegação deste projeto.
- **ConsoleUI**: Agradecimentos e créditos a [racha/ConsoleUI](https://github.com/racha/ConsoleUI) pela solução técnica de Mouse Look persistente com companion binding (F9 + WASD).
- **ConsolePort**: Crédito e inspiração à equipe original do ConsolePort por definir o padrão de ouro da experiência com controle no World of Warcraft.

---

## 🎮 Funcionalidades (Em Desenvolvimento)

- **Cursor Navigation**: Navegação fluida de UI com D-Pad e controle em janelas, menus, diálogos e bolsas.
- **Auto-Snap**: Foco automático em opções de diálogo, botões de aceitar/completar missões e interações com NPCs.
- **5 Páginas de Ação**: 40 slots de habilidades mapeados em 5 páginas via modificadores (L2, R1, R2, L2+R2 e Base).
- **Mouse Mode**: Alternância entre modo câmera e modo cursor de mouse via L3.
- **Backup & Restore**: Salva e restaura seu layout original de teclado/mouse com um comando.
- **Interface amigável para controles**: Otimizado para dispositivos portáteis (Steam Deck, ROG Ally, etc.).

---

## 🕹️ Configuração do Controle

O WoW 1.12 (Vanilla / Turtle WoW) **não possui suporte nativo a gamepads**. Por isso, é necessário um aplicativo de remapeamento que traduza os botões do seu controle em teclas de teclado antes de chegarem ao jogo.

O ConsoleMode - Vanilla foi projetado para funcionar com **qualquer aplicativo de remapeamento** (Steam Input, reWASD, JoyToKey, AntiMicroX, etc.). Basta configurar os botões do seu controle para as teclas listadas abaixo.

---

### 📋 Tabela de Mapeamento de Teclas

Configure seu app de remapeamento da seguinte forma:

#### Analógicos e Câmera

| Botão Físico | Tecla / Ação |
|:---|:---|
| **Analógico Esquerdo** | W / A / S / D (movimento) |
| **Analógico Direito** | Mouse (câmera — botão direito do mouse segurado) |
| **L3** (clique analógico esq.) | Tecla configurável — Toggle Mouse Mode |
| **R3** (clique analógico dir.) | Botão Direito do Mouse |

> 💡 **Mouse Mode**: Ao pressionar L3, o analógico direito passa a mover apenas o cursor na tela (sem controlar a câmera). Pressione L3 novamente para voltar ao modo câmera.

#### Botões Fixos (sempre iguais, independente de página)

| Botão Físico | Tecla Remapeada | Função |
|:---|:---|:---|
| **L1** | `TAB` | Selecionar alvo mais próximo |
| **Select / Back / −** | `M` | Abrir / Fechar mapa do mundo |
| **Start / Menu / +** | `F11` *(ou Escape)* | Abrir menu do jogo / Fechar janelas |

#### Atalhos Rápidos de Menus / Interface (Combos)

| Botão Físico | Teclas Combinadas | Função / Janela Aberta |
|:---|:---|:---|
| **L2 + Select** | `SHIFT + M` | Abrir / Fechar Janela de Personagem (C) |
| **L2 + Start** | `SHIFT + F11` | Abrir / Fechar Bolsas (B) |
| **R2 + Select** | `ALT + M` | Abrir / Fechar Talentos (N) |
| **R2 + Start** | `ALT + F11` | Abrir / Fechar Livro de Magias (P) |

#### Modificadores de Página (segurar para ativar a página)

| Botão Físico | Tecla | Página Ativada |
|:---|:---|:---|
| *(nenhum)* | — | **Página 1: Base** |
| **L2** | `SHIFT` (held) | **Página 2: L2** |
| **R1** | `CTRL` (held) | **Página 3: R1** |
| **R2** | `ALT` (held) | **Página 4: R2** |
| **L2 + R2** | `SHIFT + ALT` (held) | **Página 5: L2+R2** |

#### Botões de Ação (D-Pad e Faciais)

Estes botões mudam de função dependendo do modificador segurado:

| Botão Físico | Sem Mod | L2 (Shift) | R1 (Ctrl) | R2 (Alt) | L2+R2 (Shift+Alt) |
|:---|:---|:---|:---|:---|:---|
| **A** | `SPACE` | `SHIFT+SPACE` | `CTRL+SPACE` | `ALT+SPACE` | `SHIFT+ALT+SPACE` |
| **X** | `1` | `SHIFT+1` | `CTRL+1` | `ALT+1` | `SHIFT+ALT+1` |
| **Y** | `2` | `SHIFT+2` | `CTRL+2` | `ALT+2` | `SHIFT+ALT+2` |
| **B** | `3` | `SHIFT+3` | `CTRL+3` | `ALT+3` | `SHIFT+ALT+3` |
| **D-Pad ↑** | `7` | `SHIFT+7` | `CTRL+7` | `ALT+7` | `SHIFT+ALT+7` |
| **D-Pad ↓** | `8` | `SHIFT+8` | `CTRL+8` | `ALT+8` | `SHIFT+ALT+8` |
| **D-Pad ←** | `9` | `SHIFT+9` | `CTRL+9` | `ALT+9` | `SHIFT+ALT+9` |
| **D-Pad →** | `0` | `SHIFT+0` | `CTRL+0` | `ALT+0` | `SHIFT+ALT+0` |

#### 🧭 Modo Navegação (quando qualquer janela de interface está aberta)

Quando qualquer janela do jogo (missões, NPC, bolsas, menus, etc.) estiver aberta, os controles assumem automaticamente o modo de navegação de interface:

| Botão Físico | Tecla / Ação | Função no Modo Navegação |
|:---|:---|:---|
| **D-Pad ↑ ↓ ← →** | `7`, `8`, `9`, `0` | Mover cursor entre os botões, abas e itens da janela |
| **A** | `SPACE` | Confirmar / Interagir com o elemento selecionado |
| **B** | `3` | Cancelar / Fechar janela atual (ou soltar item do cursor) |
| **L1** | `TAB` | **Clique Esquerdo** (`Left Click`) no elemento sob o cursor |
| **R1** | `CTRL` | **Clique Direito** (`Right Click`) no elemento sob o cursor |
| **L2** | `SHIFT` | **Comparar Equipamento** (segurar exibe o tooltip comparativo) |
| **R2** | `ALT` | *(Livre / Sem ação por enquanto)* |

---

### 🎮 Steam Input (Steam Deck / PC com Steam)

Se você usa o **Steam Deck** ou joga com o Steam aberto no PC, o Steam Input é a forma mais simples de configurar o controle:

1. Abra o Steam e adicione o executável do Turtle WoW como **"Jogo não-Steam"**.
2. Com o jogo na biblioteca, vá em **⚙️ Gerenciar → Configurar Layout do Controle**.
3. Crie uma nova configuração e mapeie cada botão conforme a tabela acima.
4. Salve e exporte como arquivo local (`.vdf`).

> 📁 Em breve disponibilizaremos um arquivo `.vdf` pronto para importar diretamente no Steam. Fique de olho nas releases do repositório!

---

## ⌨️ Comandos do Addon

| Comando | Função |
|:---|:---|
| `/cm` | Exibe a ajuda com todos os comandos |
| `/cm status` | Mostra o status atual do addon |
| `/cm camera` | Ativa/desativa o Smart Mouselook (Câmera no Analógico) |
| `/cm mouse` | Ativa/desativa o Mouse Mode manualmente (L3) |
| `/cm controller` | Aplica o perfil de controle (faz backup antes) |
| `/cm keyboard` | Restaura seu perfil original de teclado/mouse |
| `/cm debug` | Ativa/desativa o logger de debug no chat |

---

## 🗺️ Roadmap

O que está planejado para as próximas versões do ConsoleMode - Vanilla:

### 🔧 Addon (Lua)
- [ ] Cursor de navegação visual na tela (ponteiro + highlight)
- [ ] Auto-Snap: foco automático ao abrir janelas (Quest, NPC, Bolsas, etc.)
- [ ] Navegação direcional completa entre elementos de UI (D-Pad)
- [ ] Execução de cliques e interações via controle
- [ ] Tooltips contextuais com dicas de botões do controle
- [ ] UI de configuração in-game para personalizar bindings e páginas
- [ ] Suporte a addons populares (pfUI, SuperWoW, etc.)

### 🖥️ App Companion Próprio
- [ ] **ConsoleModeInput** — aplicativo standalone (sem necessidade de Steam ou qualquer app de terceiro) que captura o controle diretamente via XInput/DirectInput e traduz os botões para o WoW, similar ao que o WoWMapper fazia para o ConsolePort antigamente. O objetivo é que o jogador instale apenas o addon + o app companion e tenha tudo funcionando sem depender de nenhuma plataforma externa.

### 🎮 Perfis de Controle
- [ ] Perfil `.vdf` oficial para Steam Input (Steam Deck + PC)
- [ ] Suporte ao WoWMapper para PC sem Steam
- [ ] Perfis por tipo de controle (Xbox, PlayStation, 8BitDo, Steam Deck)

---

## 📜 Créditos

- **ConsoleExperienceClassic**: Lógica de navegação via cursor de referência.
- **ConsolePort**: Inspiração e padrão de UX para controles no WoW.
- **WoWMapper** (Topher Sheridan): Referência e inspiração para o futuro app companion.
