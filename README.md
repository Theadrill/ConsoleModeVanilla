# ConsoleMode - Vanilla

**ConsoleMode - Vanilla** é um addon de experiência com controle/gamepad construído para World of Warcraft 1.12 (Vanilla / Turtle WoW), especialmente desenvolvido para dispositivos portáteis como o Steam Deck e para jogadores que preferem usar controles no PC.

---

## 🎯 Objetivo

Trazer uma experiência moderna de controle inspirada no renomado addon **ConsolePort** (disponível para o WoW Retail) para o cliente 1.12 Vanilla / Turtle WoW, com foco em performance, modularidade e navegação fluida de interface.

---

## 📜 Créditos

- **ConsoleExperienceClassic**: Agradecimentos e créditos aos criadores e contribuidores do `ConsoleExperienceClassic` pela lógica de navegação via cursor e implementações de referência que inspiraram o sistema de navegação deste projeto.
- **ConsolePort**: Crédito e inspiração à equipe original do ConsolePort por definir o padrão de ouro da experiência com controle no World of Warcraft.

---

## 🎮 Funcionalidades (Em Desenvolvimento)

- **Cursor Navigation**: Navegação fluida de UI com D-Pad e controle em janelas, menus, diálogos e bolsas.
- **Auto-Snap**: Foco automático em opções de diálogo, botões de aceitar/completar missões e interações com NPCs.
- **5 Páginas de Ação**: 40 slots de habilidades mapeados em 5 páginas via modificadores (L2, R1, R2, R1+R2 e Base).
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

| Botão Físico | Tecla | Função |
|:---|:---|:---|
| **L1** | `TAB` | Selecionar alvo mais próximo |
| **Select / Back / −** | `M` | Abrir mapa do mundo |
| **Start / Menu / +** | `ESCAPE` | Abrir menu do jogo |

#### Modificadores de Página (segurar para ativar a página)

| Botão Físico | Tecla | Página Ativada |
|:---|:---|:---|
| *(nenhum)* | — | **Página 1: Base** |
| **L2** | `SHIFT` (held) | **Página 2: L2** |
| **R1** | `CTRL` (held) | **Página 3: R1** |
| **R2** | `ALT` (held) | **Página 4: R2** |
| **R1 + R2** | `CTRL + ALT` (held) | **Página 5: R1+R2** |

#### Botões de Ação (D-Pad e Faciais)

Estes botões mudam de função dependendo do modificador segurado:

| Botão Físico | Sem Mod | L2 (Shift) | R1 (Ctrl) | R2 (Alt) | R1+R2 (Ctrl+Alt) |
|:---|:---|:---|:---|:---|:---|
| **A** | `SPACE` | `SHIFT+SPACE` | `CTRL+SPACE` | `ALT+SPACE` | `CTRL+ALT+SPACE` |
| **X** | `1` | `SHIFT+1` | `CTRL+1` | `ALT+1` | `CTRL+ALT+1` |
| **Y** | `2` | `SHIFT+2` | `CTRL+2` | `ALT+2` | `CTRL+ALT+2` |
| **B** | `3` | `SHIFT+3` | `CTRL+3` | `ALT+3` | `CTRL+ALT+3` |
| **D-Pad ↑** | `7` | `SHIFT+7` | `CTRL+7` | `ALT+7` | `CTRL+ALT+7` |
| **D-Pad ↓** | `8` | `SHIFT+8` | `CTRL+8` | `ALT+8` | `CTRL+ALT+8` |
| **D-Pad ←** | `9` | `SHIFT+9` | `CTRL+9` | `ALT+9` | `CTRL+ALT+9` |
| **D-Pad →** | `0` | `SHIFT+0` | `CTRL+0` | `ALT+0` | `CTRL+ALT+0` |

> 💡 **Modo Navegação**: Quando qualquer janela do jogo (missões, NPC, bolsas, etc.) estiver aberta, o D-Pad automaticamente passa a navegar entre os botões da janela. **A** confirma e **B** cancela/fecha.

#### Mouse Mode (quando L3 está ativo)

| Botão Físico | Tecla | Função |
|:---|:---|:---|
| **L2** | Botão Esquerdo do Mouse | Clicar |
| **R2** | Botão Direito do Mouse | Clicar direito |

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
| `/cm debug` | Ativa/desativa o logger de debug no chat |
| `/cm controller` | Aplica o perfil de controle (faz backup antes) |
| `/cm keyboard` | Restaura seu perfil original de teclado/mouse |
| `/cm backup` | Cria um backup manual dos bindings atuais |
| `/cm mouse` | Ativa/desativa o Mouse Mode manualmente |

---

## 📜 Créditos

- **ConsoleExperienceClassic**: Lógica de navegação via cursor de referência.
- **ConsolePort**: Inspiração e padrão de UX para controles no WoW.
