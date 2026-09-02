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

Trazer uma experiência moderna de controle inspirada no renomado addon **ConsolePort** (disponível para o WoW Retail) para o cliente 1.12 Vanilla / Turtle WoW, com foco em performance, modularidade, painel de configurações integrado e navegação fluida de interface.

---

## 📜 Créditos

- **Pixel Frog (Tiny Swords)**: Créditos e agradecimentos ao criador **Pixel Frog** pelos assets visuais e texturas de interface do pacote [Tiny Swords](https://pixelfrog-assets.itch.io/tiny-swords) utilizados no Main Menu (Console Hub).
- **Shagu (Eric)**: Créditos e agradecimentos ao desenvolvedor [Shagu](https://shagu.org/) ([ShaguTweaks](https://github.com/shagu/ShaguTweaks) / [ShaguValue](https://github.com/shagu/ShaguValue) / [pfQuest](https://github.com/shagu/pfQuest)) pela base de dados de preços de venda de itens e pela referência de dados de zonas/missões do World of Warcraft Vanilla 1.12.1.
- **pfQuest - Instrutores de Classe (Shagu / pfQuest)**: Catálogo `Data/ClassTrainers.lua` (160 NPCs - 9 classes: Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock, Druid) com coordenadas `x,y` por zona e ícone `ClassIcon_*`, extraído e curado de `Interface/AddOns/pfQuest/db/units.lua` + base Vanilla 1.12 e integrado aos pins do mapa (`UI/MainMenu.lua:GetClassTrainersForZone`). Cobertura: capitais (Stormwind 1519, Ironforge 1537, Darnassus 1657, Orgrimmar 1637, Thunder Bluff 1638, Undercity 1497) e vilas iniciais (Elwynn, Dun Morogh, Teldrassil, Durotar, Tirisfal, Mulgore, Darkshore, Westfall, Loch Modan, Barrens, Silverpine etc.) com suporte a `fac` A/H e `AltZoneMap` 1453-family.
- **LevelRange (Philip Hughes / Bull3t & Tenyar97)**: Intervalos de nível por zona (`Data/ZoneLevels.lua`) extraídos do addon [LevelRange](https://github.com/Tenyar97/LevelRange-Turtle) (autor original Philip Hughes — Bull3t, fork Turtle por Tenyar97 / rado-boy / blehz) sob licença *unlimited* com aviso. Usado para exibir `Nome (min-max)` nas listas de Regiões e Instâncias.
- **Alegreya Sans**: Criada por Juan Pablo del Peral ([Huerta Tipográfica](https://huertatipografica.com/)) sob a licença [SIL Open Font License, Version 1.1](https://fonts.google.com/specimen/Alegreya+Sans/license), utilizada para tipografia e legibilidade da interface.
- **Marcellus**: Criada por Astigmatic ([Brian J. Bonislawsky](https://www.astigmatic.com/)) sob a licença [SIL Open Font License, Version 1.1](https://fonts.google.com/specimen/Marcellus/license), utilizada para títulos e cabeçalhos da interface.
- **ConsoleExperienceClassic**: Agradecimentos e créditos aos criadores e contribuidores do `ConsoleExperienceClassic` pela lógica de navegação via cursor e implementações de referência que inspiraram o sistema de navegação deste projeto.
- **ConsoleUI**: Agradecimentos e créditos a [racha/ConsoleUI](https://github.com/racha/ConsoleUI) pela solução técnica de Mouse Look persistente com companion binding (F9 + WASD).
- **ConsolePort**: Crédito e inspiração à equipe original do ConsolePort por definir o padrão de ouro da experiência com controle no World of Warcraft.

---

## 🎮 Funcionalidades

- **Painel de Configurações In-Game (`ConsoleMode - Settings`)**:
  - Acessível direto pelo GameMenu principal do WoW (ESC) ou via comando `/cm config`.
  - Grade visual com os 8 botões de cada uma das 5 páginas de ação.
  - Exibição em tempo real do **ícone e nome exato de cada habilidade/item/macro** vinculado a cada combinação (usando Tooltip Scanner nativo do WoW 1.12).
- **Seletor de Action Bars Integrado (`ActionBarPicker`)**:
  - Interface visual interna para vincular qualquer botão do controle diretamente a slots das barras de ação (Barra Principal, Inferior Esquerda, Inferior Direita, Lateral Direita 1 e 2).
  - Suporte completo a navegação direcional por D-Pad e confirmação com botão A.
  - Salvamento persistente de bindings sem conflito com o modo de navegação.
- **Cursor Navigation & Auto-Snap**: Navegação direcional de UI com D-Pad entre botões, abas e itens em janelas de missões, diálogos de NPCs, bolsas e menus.
- **5 Páginas de Ação (40 Slots)**: Mapeamento em 5 páginas via modificadores físicos:
  - **Página 1 (Base)**: Sem modificador
  - **Página 2 (L2)**: `SHIFT`
  - **Página 3 (R1)**: `CTRL`
  - **Página 4 (R2)**: `ALT`
  - **Página 5 (L2+R2)**: `ALT + SHIFT` (ordem canônica da Blizzard)
- **Smart Mouse Look & Mouse Mode**: Alternância inteligente entre controle de câmera e modo cursor de mouse via L3 / analógico.
- **Backup & Restore de Perfil**: Salve e restaure todo o seu layout original de teclado/mouse a qualquer momento (`/cm controller` e `/cm keyboard`).
- **Cooldown no Action HUD (clusters)**: ícone escurece com animação `swipe` + contador regressivo no centro (esconde GCD ≤1.5s). Ancorado pixel-perfect no ícone (36×36) via `CooldownFrameTemplate` vanilla.
- **Cooldown em macros `/run` (SuperMacro)**: anote a magia na macro com comentário silencioso `/run -- Nome` (ex: `/run -- Earth Shock`) e o HUD espelha o `GetSpellCooldown` da magia mesmo quando a macro faz `if buff then return end`.

#### ⏳ Cooldown em Macros Complexas (SuperMacro / `/run`)

Macros `/run` que chamam funções do painel **Extended Lua** do SuperMacro (`/run shock()`) não exibem cooldown nativamente. O Action HUD resolve isso lendo um comentário na macro.

**1. Formato obrigatório (silencioso, não gera balão de fala):**
```lua
/run -- Earth Shock
/run shock()
```
- Primeira linha **deve** começar com `/` (`/run -- ` ou `/script -- `) + nome exato da magia como no spellbook (`Earth Shock`, `Fireball`, `Lightning Shield`).
- **NÃO use** `-- Earth Shock` ou `# Earth Shock` crus sem `/` — vanilla envia pro canal `SAY` (gera o balão `-- Earth Shock` visto no teste).
- Alternativas também capturadas: `# Earth Shock` e `-- Earth Shock` (mantidas por compat, mas fazem SAY).

**2. Exemplo real (`shock()` com buffs):**
```lua
/run -- Earth Shock
/run shock()
```
`shock()` pode fazer `DoActiveWeaponBuff()->return`, `IsCurrentAction/Attack`, `UnitBuff` + `GetSpellName` p/ `Lightning Shield` e só em `Cenário 3` `CastSpellByName("Earth Shock")`. O HUD sempre mostra apenas o cooldown de `Earth Shock` (6s), ignorando arma/escudo, via `GetSpellCooldown(id, BOOKTYPE_SPELL)` com cache.

**3. Fluxo:**
`ABXY pressionado → GetActionText(slot) → GetMacroInfo → body → parse "-- Earth Shock" → GetSpellIdByName → GetSpellCooldown` a cada `0.10s` + `ACTIONBAR_UPDATE_COOLDOWN` → `CooldownFrame_SetTimer` + número central (esconde GCD ≤1.5s).

**4. Dicas:**
- Nome deve bater exato (`Earth Shock` ≠ `Earth shock` — case-insensitive ok, mas acentos/espaços devem bater).
- Após editar a macro faça `/reload` (cache `macroSpellCache` limpa em `UPDATE_BINDINGS`/`SPELLS_CHANGED`).
- Para magias sem cooldown longo use ainda assim — GCD ficará só com swipe sem número.

---

## 🌐 Sistema de Tradução de Quests (ptBR)

O ConsoleModeVanilla inclui um sistema integrado de tradução de quests para Português (Brasil), garantindo que títulos, descrições e objetivos de missões sejam exibidos no idioma do jogador direto no HUD e nos menus do ConsoleMode — sem addons externos obrigatórios.

1. **Base de dados ptBR embutida (`Data/QuestDB_ptBR.lua`) com 6.685 quests traduzidas para Português (Brasil).** Tabela estática `ConsoleMode_QuestDB[id] = { T, D, O }` carregada no startup, cobrindo todo o conteúdo Vanilla 1.12 + Turtle WoW disponível em ptBR.

2. **Origem dos dados: extraídos e unificados diretamente das bases abertas de tradução do pfQuest (Vanilla 1.12) e pfQuest-turtle (quests exclusivas do Turtle WoW).** Fontes: `pfQuest/db/ptBR/quests.lua` (`pfDB['quests']['ptBR']`) e `pfQuest-turtle/db/ptBR/quests-turtle.lua` (`pfDB['quests']['ptBR-turtle']`), mantendo fidelidade às traduções da comunidade Shagu/pfQuest.

3. **Mecanismo de compilação: gerado via script `tools/build_questdb.py`, mesclando as duas bases e aplicando prioridade das quests customizadas do Turtle WoW sobre o Vanilla em caso de colisão de IDs.** Placeholders `"_"` são ignorados, conflitos são resolvidos com sobrescrita Turtle → Vanilla, saída determinística ordenada por ID com header `AUTO-GERADO. NAO EDITAR MANUALMENTE.` — re-gerável a qualquer momento para atualizar as traduções.

4. **Autonomia e Performance: o ConsoleModeVanilla funciona de forma 100% autônoma sem depender obrigatoriamente do pfQuest instalado.** Porém, se o jogador tiver o pfQuest ativo, o addon prioriza a leitura dinâmica em memória (`pfDB`) e descarrega a base local para economizar memória RAM do cliente 1.12 — ideal para o footprint limitado do WoW Vanilla.

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
| **L2 + R2** | `ALT + SHIFT` (held) | **Página 5: L2+R2** |

#### Botões de Ação (D-Pad e Faciais)

Estes botões mudam de função dependendo do modificador segurado:

| Botão Físico | Sem Mod | L2 (Shift) | R1 (Ctrl) | R2 (Alt) | L2+R2 (Alt+Shift) |
|:---|:---|:---|:---|:---|:---|
| **A** | `SPACE` | `SHIFT+SPACE` | `CTRL+SPACE` | `ALT+SPACE` | `ALT+SHIFT+SPACE` |
| **X** | `1` | `SHIFT+1` | `CTRL+1` | `ALT+1` | `ALT+SHIFT+1` |
| **Y** | `2` | `SHIFT+2` | `CTRL+2` | `ALT+2` | `ALT+SHIFT+2` |
| **B** | `3` | `SHIFT+3` | `CTRL+3` | `ALT+3` | `ALT+SHIFT+3` |
| **D-Pad ↑** | `7` | `SHIFT+7` | `CTRL+7` | `ALT+7` | `ALT+SHIFT+7` |
| **D-Pad ↓** | `8` | `SHIFT+8` | `CTRL+8` | `ALT+8` | `ALT+SHIFT+8` |
| **D-Pad ←** | `9` | `SHIFT+9` | `CTRL+9` | `ALT+9` | `ALT+SHIFT+9` |
| **D-Pad →** | `0` | `SHIFT+0` | `CTRL+0` | `ALT+0` | `ALT+SHIFT+0` |

#### 🧭 Modo Navegação (quando qualquer janela de interface está aberta)

Quando qualquer janela do jogo (missões, NPC, bolsas, menus, configurações, etc.) estiver aberta, os controles assumem automaticamente o modo de navegação de interface:

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

## ⌨️ Comandos do Addon

| Comando | Função |
|:---|:---|
| `/cm` | Exibe a ajuda com todos os comandos |
| `/cm config` ou `/cm settings` | Abre o **Painel de Configurações e Keybindings** |
| `/cm binds` | Abre diretamente a tela de mapeamento de atalhos |
| `/cm status` | Mostra o status atual do addon |
| `/cm camera` | Ativa/desativa o Smart Mouselook (Câmera no Analógico) |
| `/cm mouse` | Ativa/desativa o Mouse Mode manualmente (L3) |
| `/cm controller` | Aplica o perfil de controle (faz backup antes) |
| `/cm keyboard` | Restaura seu perfil original de teclado/mouse |
| `/cm debug` | Ativa/desativa o logger de debug no chat |

---

## 🗺️ Roadmap

O que foi feito e o que está planejado para as próximas versões do ConsoleMode - Vanilla:

### 🔧 Addon (Lua)
- [x] Cursor de navegação direcional e Auto-Snap em janelas de UI (D-Pad)
- [x] Injeção no GameMenu principal (`ConsoleMode - Settings`)
- [x] Painel de configurações in-game com 5 páginas de botões
- [x] Seletor visual de Action Bars integrado com Tooltip Scanner de magias reais
- [x] Suporte completo às combinações de modificadores (L2, R1, R2, L2+R2)
- [x] Menu Principal de Console integrado (Bolsas, Livro de Magias, Sistema, Provador 3D)
- [ ] Diário de Missões & Mapa Mundi integrados (Estilo Retail Console)
- [ ] Painel Quest Tracker no HUD (Rastreamento de missões na tela)
- [ ] UI visual própria de Action Bars e HUD no estilo ConsolePort
- [ ] Suporte a Ring Menu / Radial Menu (L2 + R2 + A)
- [ ] Suporte a addons populares (pfUI, SuperMacro, SuperWoW, etc.)

### 🖥️ App Companion Próprio
- [ ] **ConsoleModeInput** — aplicativo standalone (sem necessidade de Steam ou apps de terceiros) que captura o controle diretamente via XInput/DirectInput e traduz os botões para o WoW.

### 🎮 Perfis de Controle
- [ ] Perfil `.vdf` oficial para Steam Input (Steam Deck + PC)
- [ ] Perfis por tipo de controle (Xbox, PlayStation, 8BitDo, Nintendo Switch Layout)
