<div align="center">

[🇧🇷 Português](#português) · [🇺🇸 English](#english) · [🇨🇳 简体中文](#简体中文)

</div>

# ConsoleMode - Vanilla

## Português

> ⚠️ **Aviso Legal**: Todo o código deste projeto foi desenvolvido tendo como base de referência e inspiração projetos open source da comunidade:
> - **[ConsoleExperienceClassic](https://github.com/pepordev/ConsoleExperienceClassic)** — addon para WoW 1.12 / Turtle WoW que serviu como referência técnica principal para a lógica de cursor de navegação, hooks de UI e compatibilidade com a API Vanilla.
> - **[ConsoleUI](https://github.com/racha/ConsoleUI)** — addon para WoW 1.12 / Turtle WoW que serviu como referência técnica para a solução de Smart Mouse Look (travamento de câmera persistente via companion binding no Steam Input).
> - **[ConsolePort](https://github.com/seblindfors/ConsolePort)** — addon para WoW Retail (licença [The Artistic License 2.0](https://github.com/seblindfors/ConsolePort/blob/master/LICENSE.md)) que serviu como referência de UX, design de experiência com controle e visão de produto.
>
> O ConsoleMode - Vanilla é um projeto derivado e independente, não afiliado a nenhum dos projetos acima.

**ConsoleMode - Vanilla** é um addon de experiência com controle/gamepad construído para World of Warcraft 1.12 (Vanilla / Turtle WoW), especialmente desenvolvido para dispositivos portáteis como o Steam Deck e para jogadores que preferem usar controles no PC.

> **Multilíngue:** o addon conta com um sistema próprio de localização modular (base ptBR com fallback e troca em runtime via `/cm lang`).
> O motor de tradução contextual e de jogo (UI, perícias, árvores de talentos e descrições dinâmicas em tempo real) está atualmente em desenvolvimento ativo e contínuo aprimoramento.

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
- **Mail (shirsig)**: Agradecimentos e créditos a [shirsig/Mail](https://github.com/shirsig/Mail) (addon de correio para WoW 1.12) como referência técnica de uso da API de correio (`Mail.lua`: fluxo `MAIL_SHOW`, `CheckInbox`/`MAIL_INBOX_UPDATE`, `TakeInboxMoney`/`TakeInboxItem`/`DeleteInboxItem`/`ReturnInboxItem` serializados por eventos) para a tela de correio (`UI/MailScreen.lua`).
- **Postal**: Agradecimentos e créditos a [Postal](https://github.com/CosminPOP/Postal) (addon de correio multi-item para WoW) como referência técnica do fluxo de envio com anexo (`Postal.lua:SendMail`: `ClickSendMailItemButton` prévio p/ limpar resíduo do slot + `PickupContainerItem` + `ClickSendMailItemButton` + verificação `GetSendMailItem` antes do `SendMail`, assunto fallback `[No Subject]` + sufixo `(Part X of Y)`, fila serializada por `MAIL_SEND_SUCCESS`; `ItemIsMailable` via tooltip p/ barrar item vinculado/quest/conjurado; **sem fracionamento** — o Postal nunca chama `SplitContainerItem` (só pilha cheia) e neste cliente o split é ignorado (anexa a pilha inteira)) para o anexo físico verificado (`UI/MailScreen.lua:AttachBagItem`/`ProcessSendStep`/`ItemIsMailable`, adaptado sem `ClearCursor` destrutivo).
- **BetterCharacterStats (moh, Bennylava, Lexie, Spit, Pepopo)**: Agradecimentos e créditos ao addon [BetterCharacterStats](https://github.com/moh/BetterCharacterStats) (v1.14.x, Interface 11200) como **fonte das fórmulas e da separação de seções** da ficha do personagem (`UI/CharacterScreen.lua`): as 8 categorias (Base Stats, Melee, Melee vs Boss, Ranged, Spell, Schools, Defenses, Defenses vs Boss), a técnica de regen de mana por classe via espírito (`helper.lua:GetManaRegen`), crítico mágico, poder de cura/dano por escola e as tabelas vs Boss (miss/dodge/glance vs alvo nível 63) — todas calculadas com APIs 1.12 permitidas (fórmulas + varredura de tooltips de equipamento/talentos/auras), sem nenhuma API Retail.

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

## TODO

O que foi feito e o que está planejado para as próximas versões do ConsoleMode - Vanilla:

### 🔧 Addon (Lua)
- [x] Cursor de navegação direcional e Auto-Snap em janelas de UI (D-Pad)
- [x] Injeção no GameMenu principal (`ConsoleMode - Settings`)
- [x] Painel de configurações in-game com 5 páginas de botões
- [x] Seletor visual de Action Bars integrado com Tooltip Scanner de magias reais
- [x] Suporte completo às combinações de modificadores (L2, R1, R2, L2+R2)
- [x] Menu Principal de Console integrado (Bolsas, Livro de Magias, Sistema, Provador 3D)
- [x] Tela de Correio (caixa de entrada + compor/enviar com anexos, fila multi-item)
- [ ] Correio com COD (pagamento contra entrega no envio e na retirada)
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

---

## English

> ⚠️ **Legal Notice**: All the code in this project was developed based on reference and inspiration from open source community projects:
> - **[ConsoleExperienceClassic](https://github.com/pepordev/ConsoleExperienceClassic)** — addon for WoW 1.12 / Turtle WoW that served as the main technical reference for the navigation cursor logic, UI hooks and Vanilla API compatibility.
> - **[ConsoleUI](https://github.com/racha/ConsoleUI)** — addon for WoW 1.12 / Turtle WoW that served as the technical reference for the Smart Mouse Look solution (persistent camera lock via Steam Input companion binding).
> - **[ConsolePort](https://github.com/seblindfors/ConsolePort)** — addon for Retail WoW (license [The Artistic License 2.0](https://github.com/seblindfors/ConsolePort/blob/master/LICENSE.md)) that served as reference for UX, gamepad experience design and product vision.
>
> ConsoleMode - Vanilla is a derived and independent project, not affiliated with any of the projects above.

**ConsoleMode - Vanilla** is a gamepad/controller experience addon built for World of Warcraft 1.12 (Vanilla / Turtle WoW), especially developed for handheld devices like the Steam Deck and for players who prefer using controllers on their PC.

> **Multilingual:** the addon features a modular localization system (ptBR base with fallback and runtime switching via `/cm lang`).
> The contextual game translation engine (UI, skills, talent trees, and real-time dynamic descriptions) is currently under active development and continuous refinement.

---

## 🎯 Objective

Bring a modern controller experience inspired by the renowned **ConsolePort** addon (available for Retail WoW) to the 1.12 Vanilla / Turtle WoW client, focused on performance, modularity, an integrated settings panel and fluid interface navigation.

---

## 📜 Credits

- **Pixel Frog (Tiny Swords)**: Credits and thanks to creator **Pixel Frog** for the visual assets and interface textures from the [Tiny Swords](https://pixelfrog-assets.itch.io/tiny-swords) package used in the Main Menu (Console Hub).
- **Shagu (Eric)**: Credits and thanks to developer [Shagu](https://shagu.org/) ([ShaguTweaks](https://github.com/shagu/ShaguTweaks) / [ShaguValue](https://github.com/shagu/ShaguValue) / [pfQuest](https://github.com/shagu/pfQuest)) for the item resale price database and for the zone/quest data reference of World of Warcraft Vanilla 1.12.1.
- **pfQuest - Class Trainers (Shagu / pfQuest)**: `Data/ClassTrainers.lua` catalog (160 NPCs - 9 classes: Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock, Druid) with `x,y` coordinates per zone and `ClassIcon_*` icon, extracted and curated from `Interface/AddOns/pfQuest/db/units.lua` + Vanilla 1.12 base and integrated into the map pins (`UI/MainMenu.lua:GetClassTrainersForZone`). Coverage: capitals (Stormwind 1519, Ironforge 1537, Darnassus 1657, Orgrimmar 1637, Thunder Bluff 1638, Undercity 1497) and starting villages (Elwynn, Dun Morogh, Teldrassil, Durotar, Tirisfal, Mulgore, Darkshore, Westfall, Loch Modan, Barrens, Silverpine etc.) with `fac` A/H support and `AltZoneMap` 1453-family.
- **LevelRange (Philip Hughes / Bull3t & Tenyar97)**: Level ranges per zone (`Data/ZoneLevels.lua`) extracted from the [LevelRange](https://github.com/Tenyar97/LevelRange-Turtle) addon (original author Philip Hughes — Bull3t, Turtle fork by Tenyar97 / rado-boy / blehz) under *unlimited* license with notice. Used to display `Name (min-max)` in the Regions and Instances lists.
- **Alegreya Sans**: Created by Juan Pablo del Peral ([Huerta Tipográfica](https://huertatipografica.com/)) under the [SIL Open Font License, Version 1.1](https://fonts.google.com/specimen/Alegreya+Sans/license), used for interface typography and readability.
- **Marcellus**: Created by Astigmatic ([Brian J. Bonislawsky](https://www.astigmatic.com/)) under the [SIL Open Font License, Version 1.1](https://fonts.google.com/specimen/Marcellus/license), used for interface titles and headers.
- **ConsoleExperienceClassic**: Thanks and credits to the creators and contributors of `ConsoleExperienceClassic` for the cursor navigation logic and reference implementations that inspired the navigation system of this project.
- **ConsoleUI**: Thanks and credits to [racha/ConsoleUI](https://github.com/racha/ConsoleUI) for the technical solution of persistent Mouse Look with companion binding (F9 + WASD).
- **ConsolePort**: Credit and inspiration to the original ConsolePort team for defining the gold standard of the gamepad experience in World of Warcraft.
- **Mail (shirsig)**: Thanks and credits to [shirsig/Mail](https://github.com/shirsig/Mail) (mail addon for WoW 1.12) as technical reference for using the mail API (`Mail.lua`: `MAIL_SHOW` flow, `CheckInbox`/`MAIL_INBOX_UPDATE`, `TakeInboxMoney`/`TakeInboxItem`/`DeleteInboxItem`/`ReturnInboxItem` serialized by events) for the mail screen (`UI/MailScreen.lua`).
- **Postal**: Thanks and credits to [Postal](https://github.com/CosminPOP/Postal) (multi-item mail addon for WoW) as technical reference for the attach-send flow (`Postal.lua:SendMail`: `ClickSendMailItemButton` first to clear slot residue + `PickupContainerItem` + `ClickSendMailItemButton` + `GetSendMailItem` check before `SendMail`, fallback subject `[No Subject]` + `(Part X of Y)` suffix, queue serialized by `MAIL_SEND_SUCCESS`; `ItemIsMailable` via tooltip to block bound/quest/conjured items; **no splitting** — Postal never calls `SplitContainerItem` (only full stacks) and in this client the split is ignored (attaches the whole stack)) for the physically verified attachment (`UI/MailScreen.lua:AttachBagItem`/`ProcessSendStep`/`ItemIsMailable`, adapted without destructive `ClearCursor`).
- **BetterCharacterStats (moh, Bennylava, Lexie, Spit, Pepopo)**: Thanks and credits to the [BetterCharacterStats](https://github.com/moh/BetterCharacterStats) addon (v1.14.x, Interface 11200) as the **source of the formulas and section separation** of the character sheet (`UI/CharacterScreen.lua`): the 8 categories (Base Stats, Melee, Melee vs Boss, Ranged, Spell, Schools, Defenses, Defenses vs Boss), the class-based mana regeneration technique via spirit (`helper.lua:GetManaRegen`), spell crit, healing/damage power per school and the vs-Boss tables (miss/dodge/glance vs level 63 target) — all calculated with allowed 1.12 APIs (formulas + equipment/talent/aura tooltip scanning), without any Retail API.

---

## 🎮 Features

- **In-Game Settings Panel (`ConsoleMode - Settings`)**:
  - Accessible right from the main WoW GameMenu (ESC) or via the `/cm config` command.
  - Visual grid with the 8 buttons of each of the 5 action pages.
  - Real-time display of the **exact icon and name of every ability/item/macro** bound to each combination (using the native WoW 1.12 Tooltip Scanner).
- **Integrated Action Bar Picker (`ActionBarPicker`)**:
  - Internal visual interface to bind any controller button directly to action bar slots (Main Bar, Bottom Left, Bottom Right, Right Side 1 and 2).
  - Full D-Pad directional navigation support with A-button confirmation.
  - Persistent binding saving without conflicting with the navigation mode.
- **Cursor Navigation & Auto-Snap**: Directional UI navigation with D-Pad between buttons, tabs and items in quest windows, NPC dialogs, bags and menus.
- **5 Action Pages (40 Slots)**: 5-page mapping via physical modifiers:
  - **Page 1 (Base)**: No modifier
  - **Page 2 (L2)**: `SHIFT`
  - **Page 3 (R1)**: `CTRL`
  - **Page 4 (R2)**: `ALT`
  - **Page 5 (L2+R2)**: `ALT + SHIFT` (Blizzard canonical order)
- **Smart Mouse Look & Mouse Mode**: Smart switching between camera control and mouse cursor mode via L3 / analog stick.
- **Profile Backup & Restore**: Save and restore your entire original keyboard/mouse layout at any time (`/cm controller` and `/cm keyboard`).
- **Action HUD cooldowns (clusters)**: icon darkens with a `swipe` animation + countdown number in the center (hides GCD ≤1.5s). Anchored pixel-perfect on the icon (36×36) via vanilla `CooldownFrameTemplate`.
- **Cooldowns in `/run` macros (SuperMacro)**: annotate the spell in the macro with a silent comment `/run -- Name` (e.g. `/run -- Earth Shock`) and the HUD mirrors the spell's `GetSpellCooldown` even when the macro does `if buff then return end`.

#### ⏳ Complex Macro Cooldowns (SuperMacro / `/run`)

Macros `/run` that call functions from SuperMacro's **Extended Lua** panel (`/run shock()`) don't display cooldowns natively. The Action HUD solves this by reading a comment in the macro.

**1. Required format (silent, doesn't create a speech bubble):**
```lua
/run -- Earth Shock
/run shock()
```
- The first line **must** start with `/` (`/run -- ` or `/script -- `) + the exact spell name as in the spellbook (`Earth Shock`, `Fireball`, `Lightning Shield`).
- **DON'T** use bare `-- Earth Shock` or `# Earth Shock` without `/` — vanilla sends them to the `SAY` channel (creates the `-- Earth Shock` bubble seen during testing).
- Alternatives also captured: `# Earth Shock` and `-- Earth Shock` (kept for compatibility, but they do SAY).

**2. Real example (`shock()` with buffs):**
```lua
/run -- Earth Shock
/run shock()
```
`shock()` can do `DoActiveWeaponBuff()->return`, `IsCurrentAction/Attack`, `UnitBuff` + `GetSpellName` for `Lightning Shield` and only in `Scenario 3` `CastSpellByName("Earth Shock")`. The HUD always shows only the `Earth Shock` cooldown (6s), ignoring weapon/shield, via cached `GetSpellCooldown(id, BOOKTYPE_SPELL)`.

**3. Flow:**
`ABXY pressed → GetActionText(slot) → GetMacroInfo → body → parse "-- Earth Shock" → GetSpellIdByName → GetSpellCooldown` every `0.10s` + `ACTIONBAR_UPDATE_COOLDOWN` → `CooldownFrame_SetTimer` + center number (hides GCD ≤1.5s).

**4. Tips:**
- The name must match exactly (`Earth Shock` ≠ `Earth shock` — case-insensitive is fine, but accents/spaces must match).
- After editing the macro, do `/reload` (the `macroSpellCache` clears on `UPDATE_BINDINGS`/`SPELLS_CHANGED`).
- Use it even for spells without a long cooldown — GCD stays as a swipe without a number.

---

## 🌐 Quest Translation System (ptBR)

ConsoleModeVanilla includes an integrated quest translation system to Brazilian Portuguese, ensuring quest titles, descriptions and objectives are displayed in the player's language right on the HUD and in the ConsoleMode menus — without requiring external addons.

1. **Embedded ptBR database (`Data/QuestDB_ptBR.lua`) with 6,685 quests translated to Brazilian Portuguese.** Static table `ConsoleMode_QuestDB[id] = { T, D, O }` loaded at startup, covering all the Vanilla 1.12 + Turtle WoW content available in ptBR.

2. **Data source: extracted and unified directly from pfQuest's open translation bases (Vanilla 1.12) and pfQuest-turtle (Turtle WoW exclusive quests).** Sources: `pfQuest/db/ptBR/quests.lua` (`pfDB['quests']['ptBR']`) and `pfQuest-turtle/db/ptBR/quests-turtle.lua` (`pfDB['quests']['ptBR-turtle']`), keeping fidelity to the Shagu/pfQuest community translations.

3. **Build mechanism: generated via the `tools/build_questdb.py` script, merging both bases and applying priority of Turtle WoW custom quests over Vanilla on ID collision.** `"_"` placeholders are ignored, conflicts are resolved with Turtle → Vanilla overwrite, deterministic output sorted by ID with the `AUTO-GENERATED. DO NOT EDIT MANUALLY.` header — re-generable at any time to update translations.

4. **Autonomy and Performance: ConsoleModeVanilla works 100% autonomously without necessarily depending on pfQuest being installed.** However, if the player has pfQuest active, the addon prioritizes in-memory dynamic reading (`pfDB`) and unloads the local base to save RAM on the 1.12 client — ideal for the limited footprint of WoW Vanilla.

---

## 🕹️ Controller Setup

WoW 1.12 (Vanilla / Turtle WoW) has **no native gamepad support**. So you need a remapping application that translates your controller buttons into keyboard keys before they reach the game.

ConsoleMode - Vanilla was designed to work with **any remapping application** (Steam Input, reWASD, JoyToKey, AntiMicroX, etc.). Just configure your controller buttons to the keys listed below.

---

### 📋 Key Mapping Table

Configure your remapping app as follows:

#### Sticks and Camera

| Physical Button | Key / Action |
|:---|:---|
| **Left Stick** | W / A / S / D (movement) |
| **Right Stick** | Mouse (camera — right mouse button held) |
| **L3** (left stick click) | Configurable key — Toggle Mouse Mode |
| **R3** (right stick click) | Right Mouse Button |

> 💡 **Mouse Mode**: When pressing L3, the right stick only moves the cursor on screen (without controlling the camera). Press L3 again to return to camera mode.

#### Fixed Buttons (always the same, regardless of page)

| Physical Button | Remapped Key | Function |
|:---|:---|:---|
| **L1** | `TAB` | Select nearest target |
| **Select / Back / −** | `M` | Open / Close world map |
| **Start / Menu / +** | `F11` *(or Escape)* | Open game menu / Close windows |

#### Quick Menu / Interface Shortcuts (Combos)

| Physical Button | Combined Keys | Function / Opened Window |
|:---|:---|:---|
| **L2 + Select** | `SHIFT + M` | Open / Close Character Window (C) |
| **L2 + Start** | `SHIFT + F11` | Open / Close Bags (B) |
| **R2 + Select** | `ALT + M` | Open / Close Talents (N) |
| **R2 + Start** | `ALT + F11` | Open / Close Spellbook (P) |

#### Page Modifiers (hold to activate the page)

| Physical Button | Key | Activated Page |
|:---|:---|:---|
| *(none)* | — | **Page 1: Base** |
| **L2** | `SHIFT` (held) | **Page 2: L2** |
| **R1** | `CTRL` (held) | **Page 3: R1** |
| **R2** | `ALT` (held) | **Page 4: R2** |
| **L2 + R2** | `ALT + SHIFT` (held) | **Page 5: L2+R2** |

#### Action Buttons (D-Pad and Face Buttons)

These buttons change function depending on the held modifier:

| Physical Button | No Mod | L2 (Shift) | R1 (Ctrl) | R2 (Alt) | L2+R2 (Alt+Shift) |
|:---|:---|:---|:---|:---|:---|
| **A** | `SPACE` | `SHIFT+SPACE` | `CTRL+SPACE` | `ALT+SPACE` | `ALT+SHIFT+SPACE` |
| **X** | `1` | `SHIFT+1` | `CTRL+1` | `ALT+1` | `ALT+SHIFT+1` |
| **Y** | `2` | `SHIFT+2` | `CTRL+2` | `ALT+2` | `ALT+SHIFT+2` |
| **B** | `3` | `SHIFT+3` | `CTRL+3` | `ALT+3` | `ALT+SHIFT+3` |
| **D-Pad ↑** | `7` | `SHIFT+7` | `CTRL+7` | `ALT+7` | `ALT+SHIFT+7` |
| **D-Pad ↓** | `8` | `SHIFT+8` | `CTRL+8` | `ALT+8` | `ALT+SHIFT+8` |
| **D-Pad ←** | `9` | `SHIFT+9` | `CTRL+9` | `ALT+9` | `ALT+SHIFT+9` |
| **D-Pad →** | `0` | `SHIFT+0` | `CTRL+0` | `ALT+0` | `ALT+SHIFT+0` |

#### 🧭 Navigation Mode (when any interface window is open)

When any game window (quests, NPC, bags, menus, settings, etc.) is open, the controls automatically assume interface navigation mode:

| Physical Button | Key / Action | Function in Navigation Mode |
|:---|:---|:---|
| **D-Pad ↑ ↓ ← →** | `7`, `8`, `9`, `0` | Move cursor between buttons, tabs and items of the window |
| **A** | `SPACE` | Confirm / Interact with the selected element |
| **B** | `3` | Cancel / Close current window (or drop the item from the cursor) |
| **L1** | `TAB` | **Left Click** on the element under the cursor |
| **R1** | `CTRL` | **Right Click** on the element under the cursor |
| **L2** | `SHIFT` | **Compare Equipment** (hold to show the comparative tooltip) |
| **R2** | `ALT` | *(Free / No action for now)* |

---

## ⌨️ Addon Commands

| Command | Function |
|:---|:---|
| `/cm` | Shows help with all commands |
| `/cm config` or `/cm settings` | Opens the **Settings & Keybindings Panel** |
| `/cm binds` | Opens the keybinding mapping screen directly |
| `/cm status` | Shows the current addon status |
| `/cm camera` | Enables/disables Smart Mouselook (Camera on Analog Stick) |
| `/cm mouse` | Enables/disables Mouse Mode manually (L3) |
| `/cm controller` | Applies the controller profile (makes a backup first) |
| `/cm keyboard` | Restores your original keyboard/mouse profile |
| `/cm debug` | Enables/disables the debug logger in chat |

---

## 简体中文

> **译者说明（AI Notice）**：本节中文文档由 AI 辅助生成，本地化与游戏内容翻译系统目前正在积极开发与持续完善中。

> ⚠️ **法律声明（Legal Notice）**：本项目的所有代码均参考并汲取了社区开源项目的灵感开发：
> - **[ConsoleExperienceClassic](https://github.com/pepordev/ConsoleExperienceClassic)** —— 适用于 WoW 1.12 / Turtle WoW 的插件，是本项目导航光标逻辑、UI 钩子（hooks）与 Vanilla API 兼容性的主要技术参考。
> - **[ConsoleUI](https://github.com/racha/ConsoleUI)** —— 适用于 WoW 1.12 / Turtle WoW 的插件，是本项目 Smart Mouse Look（通过 Steam Input 伴侣绑定实现持久摄像机锁定）方案的技术参考。
> - **[ConsolePort](https://github.com/seblindfors/ConsolePort)** —— 适用于 WoW 正式服（Retail）的插件（许可证 [The Artistic License 2.0](https://github.com/seblindfors/ConsolePort/blob/master/LICENSE.md)），是用户体验、手柄游戏体验设计与产品愿景方面的参考。
>
> ConsoleMode - Vanilla 是一个衍生且独立的项目，与上述任何项目均无关联。

**ConsoleMode - Vanilla** 是一款专为 World of Warcraft 1.12（Vanilla / Turtle WoW）打造的手柄/控制器体验插件，特别针对 Steam Deck 等掌上设备，也适合喜欢在电脑上使用控制器游玩的玩家。

> **多语言（Multilingual）**：本插件具备模块化本地化系统（以 ptBR 为基准支持回退，可通过 `/cm lang` 在运行时切换）。情境化游戏翻译引擎（UI、技能、天赋树与实时动态描述）目前正在积极开发与持续完善中。

---

## 🎯 目标

将知名插件 **ConsolePort**（适用于正式服）的现代手柄体验带入 1.12 Vanilla / Turtle WoW 客户端，聚焦于性能、模块化、集成式设置面板和流畅的界面导航。

---

## 📜 致谢

- **Pixel Frog（Tiny Swords）**：感谢作者 **Pixel Frog** 为主菜单（Console Hub）提供 [Tiny Swords](https://pixelfrog-assets.itch.io/tiny-swords) 资源包中的视觉素材与界面纹理。
- **Shagu（Eric）**：感谢开发者 [Shagu](https://shagu.org/)（[ShaguTweaks](https://github.com/shagu/ShaguTweaks) / [ShaguValue](https://github.com/shagu/ShaguValue) / [pfQuest](https://github.com/shagu/pfQuest)）提供的物品出售价格数据库，以及 World of Warcraft Vanilla 1.12.1 的区域/任务数据参考。
- **pfQuest - Class Trainers（Shagu / pfQuest）**：`Data/ClassTrainers.lua` 目录（160 个 NPC，9 个职业：Warrior、Paladin、Hunter、Rogue、Priest、Shaman、Mage、Warlock、Druid），包含各区域的 `x,y` 坐标和 `ClassIcon_*` 图标，提取并整理自 `Interface/AddOns/pfQuest/db/units.lua` + Vanilla 1.12 基础数据，并集成到地图标记中（`UI/MainMenu.lua:GetClassTrainersForZone`）。覆盖范围：主城（Stormwind 1519、Ironforge 1537、Darnassus 1657、Orgrimmar 1637、Thunder Bluff 1638、Undercity 1497）和新手村（Elwynn、Dun Morogh、Teldrassil、Durotar、Tirisfal、Mulgore、Darkshore、Westfall、Loch Modan、Barrens、Silverpine 等），支持 `fac` A/H 与 `AltZoneMap` 1453 系列。
- **LevelRange（Philip Hughes / Bull3t & Tenyar97）**：从 [LevelRange](https://github.com/Tenyar97/LevelRange-Turtle) 插件（原作者 Philip Hughes——Bull3t，Turtle 分支由 Tenyar97 / rado-boy / blehz 维护）提取的各区域等级范围（`Data/ZoneLevels.lua`），依 *unlimited* 许可证附注使用。用于在地区和副本列表中显示 `名称（最低-最高）`。
- **Alegreya Sans**：由 Juan Pablo del Peral（[Huerta Tipográfica](https://huertatipografica.com/)）创作，遵循 [SIL 开放字体许可证 1.1](https://fonts.google.com/specimen/Alegreya+Sans/license)，用于界面的排版与可读性。
- **Marcellus**：由 Astigmatic（[Brian J. Bonislawsky](https://www.astigmatic.com/)）创作，遵循 [SIL 开放字体许可证 1.1](https://fonts.google.com/specimen/Marcellus/license)，用于界面标题与页眉。
- **ConsoleExperienceClassic**：感谢 `ConsoleExperienceClassic` 的作者与贡献者提供的光标导航逻辑和参考实现，启发了本项目的导航系统。
- **ConsoleUI**：感谢 [racha/ConsoleUI](https://github.com/racha/ConsoleUI) 提供的持久 Mouse Look 技术方案（伴侣绑定，F9 + WASD）。
- **ConsolePort**：感谢 ConsolePort 原团队，他们定义了 World of Warcraft 手柄体验的金标准，并为本项目提供了灵感。
- **Mail（shirsig）**：感谢 [shirsig/Mail](https://github.com/shirsig/Mail)（适用于 WoW 1.12 的邮件插件），作为邮件 API 使用的技术参考（`Mail.lua`：`MAIL_SHOW` 流程、`CheckInbox`/`MAIL_INBOX_UPDATE`、`TakeInboxMoney`/`TakeInboxItem`/`DeleteInboxItem`/`ReturnInboxItem` 按事件串行化），用于邮件界面（`UI/MailScreen.lua`）。
- **Postal**：感谢 [Postal](https://github.com/CosminPOP/Postal)（适用于 WoW 的多物品邮件插件），作为带附件发送流程的技术参考（`Postal.lua:SendMail`：先执行 `ClickSendMailItemButton` 清除槽位残留 + `PickupContainerItem` + `ClickSendMailItemButton` + `SendMail` 之前的 `GetSendMailItem` 校验，回退主题 `[No Subject]` + 后缀 `（第 X 部分，共 Y 部分）`，由 `MAIL_SEND_SUCCESS` 串行化的发送队列；通过 tooltip 使用 `ItemIsMailable` 拦截绑定/任务/召唤物品；**不拆分**——Postal 从不调用 `SplitContainerItem`（仅完整堆叠），且此客户端中拆分会被忽略（会附加整个堆叠）），确保附件得到实际验证（`UI/MailScreen.lua:AttachBagItem`/`ProcessSendStep`/`ItemIsMailable`，在不使用破坏性 `ClearCursor` 的前提下进行了适配）。
- **BetterCharacterStats（moh、Bennylava、Lexie、Spit、Pepopo）**：感谢 [BetterCharacterStats](https://github.com/moh/BetterCharacterStats) 插件（v1.14.x，Interface 11200）作为角色界面（`UI/CharacterScreen.lua`）的**公式与分节来源**：8 个类别（基本属性 Base Stats、近战 Melee、对首领近战 Melee vs Boss、远程 Ranged、法术 Spell、学派 Schools、防御 Defenses、对首领防御 Defenses vs Boss）、通过精神值按职业计算法力回复的技巧（`helper.lua:GetManaRegen`）、法术暴击、各学派治疗/伤害强度，以及针对 63 级目标的对首领（未命中/躲闪/偏斜）表格——全部使用 1.12 允许的 API 计算（公式 + 装备/天赋/光环 tooltip 扫描），不使用任何正式服 API。

---

## 🎮 功能

- **游戏内设置面板（`ConsoleMode - Settings`）**：
  - 可直接从 WoW 主游戏菜单（ESC）进入，或通过 `/cm config` 命令打开。
  - 5 个动作页面中每页 8 个按钮的可视化网格。
  - 实时显示每个组合所绑定的**每个技能/物品/宏的精确图标与名称**（使用 WoW 1.12 原生 Tooltip 扫描器）。
- **集成式动作条选择器（`ActionBarPicker`）**：
  - 可视化内部界面，可将任意手柄按钮直接绑定到动作条槽位（主动作条、左下、右下、右侧 1 和 2）。
  - 完整的方向键（D-Pad）方向导航支持，A 键确认。
  - 绑定持久保存，且不干扰导航模式。
- **光标导航与自动吸附（Cursor Navigation & Auto-Snap）**：通过方向键（D-Pad）在任务窗口、NPC 对话、背包与菜单的按钮、标签页和物品之间进行方向性 UI 导航。
- **5 个动作页面（40 个槽位）**：通过物理修饰键实现 5 页映射：
  - **页面 1（基础）**：无修饰键
  - **页面 2（L2）**：`SHIFT`
  - **页面 3（R1）**：`CTRL`
  - **页面 4（R2）**：`ALT`
  - **页面 5（L2+R2）**：`ALT + SHIFT`（暴雪规范顺序）
- **Smart Mouse Look 与鼠标模式（Mouse Mode）**：通过 L3 / 摇杆在摄像机控制与鼠标光标模式之间智能切换。
- **配置备份与恢复（Profile Backup & Restore）**：随时保存并恢复您原始的键盘/鼠标布局（`/cm controller` 和 `/cm keyboard`）。
- **动作 HUD 冷却（集群）**：图标以 `swipe` 动画变暗，并在中心显示倒计时数字（隐藏 ≤1.5 秒的 GCD）。通过 Vanilla 的 `CooldownFrameTemplate` 精确定位在图标（36×36）上。
- **`/run` 宏的冷却（SuperMacro）**：在宏中用静默注释 `/run -- 名称` 标注技能（例如 `/run -- Earth Shock`），即使宏执行 `if buff then return end`，HUD 也会镜像显示该技能的 `GetSpellCooldown`。

#### ⏳ 复杂宏的冷却（SuperMacro / `/run`）

调用 SuperMacro **扩展 Lua** 面板函数的 `/run` 宏（`/run shock()`）无法原生显示冷却。Action HUD 通过读取宏中的注释来解决此问题。

**1. 必需格式（静默，不产生说话气泡）：**
```lua
/run -- Earth Shock
/run shock()
```
- 第一行**必须**以 `/` 开头（`/run -- ` 或 `/script -- `）+ 与技能书中完全一致的技能名称（`Earth Shock`、`Fireball`、`Lightning Shield`）。
- **不要**使用不带 `/` 的裸 `-- Earth Shock` 或 `# Earth Shock`——Vanilla 会将其发送到 `SAY` 频道（测试中会出现 `-- Earth Shock` 气泡）。
- 以下格式也能被识别：`# Earth Shock` 和 `-- Earth Shock`（为兼容性而保留，但会产生 SAY）。

**2. 真实示例（带 buff 的 `shock()`）：**
```lua
/run -- Earth Shock
/run shock()
```
`shock()` 可能执行 `DoActiveWeaponBuff()->return`、`IsCurrentAction/Attack`、用于 `Lightning Shield` 的 `UnitBuff` + `GetSpellName`，并且只在 `场景 3` 中执行 `CastSpellByName("Earth Shock")`。HUD 始终只显示 `Earth Shock` 的冷却（6 秒），忽略武器/护盾，通过带缓存的 `GetSpellCooldown(id, BOOKTYPE_SPELL)` 实现。

**3. 流程：**
`按下 ABXY → GetActionText(slot) → GetMacroInfo → 宏体 → 解析 "-- Earth Shock" → GetSpellIdByName → GetSpellCooldown`，每 `0.10 秒` 执行一次 + `ACTIONBAR_UPDATE_COOLDOWN` → `CooldownFrame_SetTimer` + 中央数字（隐藏 ≤1.5 秒的 GCD）。

**4. 提示：**
- 名称必须完全一致（`Earth Shock` ≠ `Earth shock`——不区分大小写没问题，但重音/空格必须匹配）。
- 编辑宏后请执行 `/reload`（`macroSpellCache` 缓存会在 `UPDATE_BINDINGS`/`SPELLS_CHANGED` 时清除）。
- 即使技能没有长时间冷却也请使用此功能——GCD 会只显示 swipe 而无数字。

---

## 🌐 任务翻译系统（ptBR）

ConsoleModeVanilla 内置集成的任务翻译系统（翻译为巴西葡语），确保任务标题、描述与目标直接以玩家语言显示在 HUD 和 ConsoleMode 菜单中——无需额外插件。

1. **内置 ptBR 数据库（`Data/QuestDB_ptBR.lua`），包含 6,685 条已翻译为巴西葡语的任务。** 静态表 `ConsoleMode_QuestDB[id] = { T, D, O }` 在启动时加载，覆盖 Vanilla 1.12 + Turtle WoW 所有可用的 ptBR 内容。

2. **数据来源：直接从 pfQuest（Vanilla 1.12）和 pfQuest-turtle（Turtle WoW 独占任务）的开放翻译库中提取并统一。** 来源：`pfQuest/db/ptBR/quests.lua`（`pfDB['quests']['ptBR']`）和 `pfQuest-turtle/db/ptBR/quests-turtle.lua`（`pfDB['quests']['ptBR-turtle']`），忠实于 Shagu/pfQuest 社区的翻译。

3. **编译机制：通过 `tools/build_questdb.py` 脚本生成，合并两个数据库，并在 ID 冲突时以 Turtle WoW 自定义任务优先。** `"_"` 占位符会被忽略，冲突通过 Turtle → Vanilla 覆盖解决，输出按 ID 确定性排序，并带有 `AUTO-GENERATED. DO NOT EDIT MANUALLY.`（自动生成，请勿手动编辑）标头——可随时重新生成以更新翻译。

4. **自主性与性能：ConsoleModeVanilla 100% 独立运行，不强制要求安装 pfQuest。** 但如果玩家已开启 pfQuest，插件会优先进行内存动态读取（`pfDB`）并卸载本地数据库，以节省 1.12 客户端的内存（RAM）——非常适合内存占用有限的 WoW Vanilla。

---

## 🕹️ 控制器设置

WoW 1.12（Vanilla / Turtle WoW）**本身不支持手柄（gamepad）**。因此需要一个重映射应用程序，在按键到达游戏之前将手柄按钮转换为键盘按键。

ConsoleMode - Vanilla 设计为可与**任何重映射应用程序**配合使用（Steam Input、reWASD、JoyToKey、AntiMicroX 等）。只需将手柄按钮配置为下面列出的按键即可。

---

### 📋 按键映射表

请按如下方式配置您的重映射应用：

#### 摇杆与摄像机

| 物理按钮 | 按键 / 动作 |
|:---|:---|
| **左摇杆** | W / A / S / D（移动） |
| **右摇杆** | 鼠标（摄像机——按住鼠标右键） |
| **L3**（按下左摇杆） | 可配置按键——切换鼠标模式（Mouse Mode） |
| **R3**（按下右摇杆） | 鼠标右键 |

> 💡 **鼠标模式（Mouse Mode）**：按下 L3 后，右摇杆只移动屏幕上的光标（不控制摄像机）。再次按下 L3 返回摄像机模式。

#### 固定按钮（始终相同，与页面无关）

| 物理按钮 | 重映射按键 | 功能 |
|:---|:---|:---|
| **L1** | `TAB` | 选择最近目标 |
| **Select / Back / −** | `M` | 打开 / 关闭世界地图 |
| **Start / Menu / +** | `F11` *（或 Esc）* | 打开游戏菜单 / 关闭窗口 |

#### 菜单 / 界面快捷组合（Combos）

| 物理按钮 | 组合按键 | 功能 / 打开的窗口 |
|:---|:---|:---|
| **L2 + Select** | `SHIFT + M` | 打开 / 关闭角色窗口（C） |
| **L2 + Start** | `SHIFT + F11` | 打开 / 关闭背包（B） |
| **R2 + Select** | `ALT + M` | 打开 / 关闭天赋（N） |
| **R2 + Start** | `ALT + F11` | 打开 / 关闭技能书（P） |

#### 页面修饰键（按住以激活页面）

| 物理按钮 | 按键 | 激活页面 |
|:---|:---|:---|
| *（无）* | — | **页面 1：基础** |
| **L2** | `SHIFT`（按住） | **页面 2：L2** |
| **R1** | `CTRL`（按住） | **页面 3：R1** |
| **R2** | `ALT`（按住） | **页面 4：R2** |
| **L2 + R2** | `ALT + SHIFT`（按住） | **页面 5：L2+R2** |

#### 动作按钮（方向键与面键）

这些按钮的功能取决于按住哪个修饰键：

| 物理按钮 | 无修饰 | L2（Shift） | R1（Ctrl） | R2（Alt） | L2+R2（Alt+Shift） |
|:---|:---|:---|:---|:---|:---|
| **A** | `SPACE` | `SHIFT+SPACE` | `CTRL+SPACE` | `ALT+SPACE` | `ALT+SHIFT+SPACE` |
| **X** | `1` | `SHIFT+1` | `CTRL+1` | `ALT+1` | `ALT+SHIFT+1` |
| **Y** | `2` | `SHIFT+2` | `CTRL+2` | `ALT+2` | `ALT+SHIFT+2` |
| **B** | `3` | `SHIFT+3` | `CTRL+3` | `ALT+3` | `ALT+SHIFT+3` |
| **D-Pad ↑** | `7` | `SHIFT+7` | `CTRL+7` | `ALT+7` | `ALT+SHIFT+7` |
| **D-Pad ↓** | `8` | `SHIFT+8` | `CTRL+8` | `ALT+8` | `ALT+SHIFT+8` |
| **D-Pad ←** | `9` | `SHIFT+9` | `CTRL+9` | `ALT+9` | `ALT+SHIFT+9` |
| **D-Pad →** | `0` | `SHIFT+0` | `CTRL+0` | `ALT+0` | `ALT+SHIFT+0` |

#### 🧭 导航模式（当任何界面窗口打开时）

当任何游戏窗口（任务、NPC、背包、菜单、设置等）打开时，控制器会自动进入界面导航模式：

| 物理按钮 | 按键 / 动作 | 导航模式下的功能 |
|:---|:---|:---|
| **方向键 ↑ ↓ ← →** | `7`、`8`、`9`、`0` | 在窗口的按钮、标签页和物品之间移动光标 |
| **A** | `SPACE` | 确认 / 与所选元素交互 |
| **B** | `3` | 取消 / 关闭当前窗口（或放下光标中的物品） |
| **L1** | `TAB` | 对光标下的元素进行**左键单击（Left Click）** |
| **R1** | `CTRL` | 对光标下的元素进行**右键单击（Right Click）** |
| **L2** | `SHIFT` | **比较装备**（按住显示对比 tooltip） |
| **R2** | `ALT` | *（空闲 / 目前无动作）* |

---

## ⌨️ 插件命令

| 命令 | 功能 |
|:---|:---|
| `/cm` | 显示所有命令的帮助 |
| `/cm config` 或 `/cm settings` | 打开 **设置与按键绑定面板** |
| `/cm binds` | 直接打开按键绑定映射界面 |
| `/cm status` | 显示插件当前状态 |
| `/cm camera` | 启用/禁用 Smart Mouselook（摇杆控制摄像机） |
| `/cm mouse` | 手动启用/禁用鼠标模式（L3） |
| `/cm controller` | 应用控制器配置（先进行备份） |
| `/cm keyboard` | 恢复原始键盘/鼠标配置 |
| `/cm debug` | 启用/禁用聊天中的调试日志 |