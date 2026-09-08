# Plano de Feature: MAPEADOR DE ATALHOS / BINDS (ConsoleMode Main Menu)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido terminantemente o uso de operadores de Lua 5.1+ (como operador de tamanho `#table`, usar `table.getn(t)` ou `getn(t)`), `continue` ou `goto`.
> 3. **Identidade Visual Rigorosa do MAIN MENU (Abandono Total da UI Clássica da Blizzard):**
>    - **ABANDONO TOTAL DO VISUAL ARCAICO:** É terminantemente proibido usar elementos da UI nativa clássica da Blizzard que a janela antiga usava (como `UIPanelButtonTemplate`, botões cinzas com chanfro vermelho de fechar, bordas de diálogo `UI-DialogBox-Border`, fontes padrão `GameFontNormal` puras sem tratamento, etc.).
>    - **ADOÇÃO EXCLUSIVA DO DESIGN SYSTEM DO MAIN MENU:** O visual deve ser 100% harmonizado com o restante do Main Menu (mesmo estilo das abas de Bolsas, Magias e Talentos):
>      - **Tipografia Nobre:** Todas as fontes devem ser aplicadas via `MainMenu:ApplyFont()`, utilizando exclusivamente `CFG.Fonts.titleFontFile` (`Marcellus-Regular.ttf` para títulos e cabeçalhos), `CFG.Fonts.bodyFontFile` (`AlegreyaSans-Bold.ttf` para corpo, botões e valores) e `CFG.Fonts.subFontFile` (`AlegreyaSans-Medium.ttf` para subtítulos, descrições e badges).
>      - **Paleta de Cores Oficial:** Dourado âmbar nobre (`CFG.Tabs.activeColor` `{ r = 0.88, g = 0.60, b = 0.08 }` / código de cor `|cffe09a15`), cinza suave para inativos (`{ r = 0.65, g = 0.65, b = 0.65 }`), texto branco puro (`|cffffffff`) e realces dourados de seleção (`CFG.Grid.highlightColor`).
>      - **Backdrops Customizados:** Fundos escurecidos translúcidos com alpha 0.35-0.50 (`Interface\Tooltips\UI-Tooltip-Background`), bordas finas com corte refinado (`Interface\Tooltips\UI-Tooltip-Border`), cantos com insets padronizados de 2-3px, e bordas de foco douradas dedicadas (`focusBorder`).
>      - **Controles de Console e Glifos:** Tags visuais com ícones das texturas oficiais do controle Xbox (`CFG.Icons.LT`, `CFG.Icons.RT`, `CFG.Icons.LB`, `CFG.Icons.RB`, `CFG.Icons.A`, `CFG.Icons.B`, `CFG.Icons.X`, `CFG.Icons.Y`) integradas diretamente nos cabeçalhos, botões e rodapés.
>      - **DetailCard Estilo Zelda:** Utilização direta do componente `MainMenu:CreateDetailCard()` na base da tela para exibir tooltips, descrições e status com riqueza de detalhes sem poluir a grade.
> 4. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 5. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem o comando e autorização explícita do usuário.
> 6. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem fazer uma parada crítica, solicitar a validação do usuário no jogo via `/reload` e aguardar seu feedback/aprovação.
> 7. **Validação Incremental por Partes:** O desenvolvimento deve ser validado estritamente passo a passo com placeholders preliminares antes da inserção de conteúdos finais.

---

## 1. Visão Geral

Substituir o antigo painel flutuante e arcaico de configurações (`ConfigFrame.lua`, `KeybindingsList.lua` e `ActionBarPicker.lua`), portando toda a experiência de mapeamento de atalhos e botões para **DENTRO do Main Menu**.

Atualmente, na aba **Configurações (SYSTEM)** do Main Menu, dentro da sub-aba **Configurações do Addon (ADDON_CFG)**, existe a opção *"Mapeador de Atalhos / Binds"*. Contudo, ao ser clicada, ela apenas fecha o Main Menu e abre uma janela cinza clássica com abas flutuantes estilo Blizzard 2004.

A proposta é transformar essa opção em uma transição suave de telas dentro do próprio pergaminho/painel do Main Menu, adotando a mesma arquitetura em duas telas que foi implementada na aba de **Talentos** (`specScreen` ➔ `treeScreen`).

---

## 2. Arquitetura de Telas & Fluxo de Navegação

A navegação do Mapeador de Atalhos funcionará em hierarquia de duas telas:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        MAIN MENU (CONSOLEMODE)                         │
│  ┌──────────────┐ ┌──────────────────────────────────────────────────┐ │
│  │              │ │ Bolsas │ Magias │ Talentos │ Missões │ OPÇÕES   │ │
│  │              │ └──────────────────────────────────────────────────┘ │
│  │              │   Sub-Abas: [LT] [Opções do Jogo] [Addon] [RT]      │
│  │  PAINEL 3D   │                                                      │
│  │  DO AVATAR   │   Na Sub-Aba ADDON_CFG:                              │
│  │  DO JOGADOR  │   ► [01] Mapeador de Atalhos / Binds ──────┐         │
│  │  (Mantido)   │     [02] Resetar Posições de UI            │ click   │
│  │              │     [03] Recarregar Interface (/reload)    │ ou [A]  │
│  │              │                                            ▼         │
│  │              │ ┌──────────────────────────────────────────────────┐ │
│  │              │ │ TELA 1: MAPEADOR DE COMBINAÇÕES (PÁGINAS 1 A 5)  │ │
│  │              │ │  [LT] Pág 1: Base | Pág 2: L2 | Pág 3: R1... [RT]│ │
│  │              │ │  ┌───────────────┐      ┌───────────────┐        │ │
│  │              │ │  │ Cluster D-Pad │      │ Cluster ABXY  │        │ │
│  │              │ │  │ [^] [v] [<] [>]      │ (Y) (A) (X) (B)       │ │
│  │              │ │  └───────┬───────┘      └───────────────┘        │ │
│  │              │ └──────────┼───────────────────────────────────────┘ │
│  │              │            │ [A] Selecionar Botão                    │
│  │              │            ▼                                         │
│  │              │ ┌──────────────────────────────────────────────────┐ │
│  │              │ │ TELA 2: SELETOR DE CONTEÚDO (O "PICKER")         │ │
│  │              │ │  Mapeando: [L2 + X]                [B] Voltar    │ │
│  │              │ │  [Spellbook] [Bolsas] [Macros] [Barras de Ação]  │ │
│  │              │ │  [Geral] [Spec 1] [Spec 2] [Spec 3]              │ │
│  │              │ │  ┌────────────────────────────────────────────┐  │ │
│  │              │ │  │  Grade 4x4 de Feitiços / Itens / Ações     │  │ │
│  │              │ │  └────────────────────────────────────────────┘  │ │
│  │              │ │  [< Prev]              1 / 2            [Next >] │ │
│  │              │ └──────────────────────────────────────────────────┘ │
│  │              │ ┌──────────────────────────────────────────────────┐ │
│  │              │ │ DETAIL CARD (Zelda Style - Tooltip e Ações)      │ │
│  │              │ └──────────────────────────────────────────────────┘ │
│  └──────────────┘ └──────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.1. Regras de Transição e Pilha de Telas (Back Navigation)
- **Entrada na Tela 1:** Pressionar `[A]` na opção *"Mapeador de Atalhos / Binds"* da sub-aba `ADDON_CFG`.
- **Tela 1 ➔ Tela 2:** Pressionar `[A]` em qualquer um dos 8 cards de combinação da página selecionada.
- **Tela 2 ➔ Tela 1:** Pressionar `[B]` na Tela 2 cancela o mapeamento e retorna à Tela 1 sem alterar a bind. Ao selecionar uma magia/item com `[A]`, a bind é gravada, o `ActionHUD` é atualizado instantaneamente e a visualização retorna à Tela 1 com feedback sonoro e visual.
- **Tela 1 ➔ ADDON_CFG:** Pressionar `[B]` na Tela 1 retorna à lista de opções do addon dentro da aba `SYSTEM`.
- **Desvincular Atalho (Limpar Slot):** Na Tela 1, pressionar `[X]` remove a ação associada ao botão focado (define como vazio).

---

## 3. Especificação da Tela 1 — Mapeador de Combinações

### 3.1. Cabeçalho de Navegação de Páginas ([LT] / [RT])
Permite alternar rapidamente entre as 5 páginas de ação do controle com gatilhos ou cliques:
- **Página 1:** Base (Sem Modificador)
- **Página 2:** L2 (Shift)
- **Página 3:** R1 (Ctrl)
- **Página 4:** R2 (Alt)
- **Página 5:** L2+R2 (Shift+Alt)

O cabeçalho exibirá:
- Ícone `[LT]` à esquerda.
- 5 botões de sub-abas compactos com acabamento nobre (`1: Base`, `2: L2`, `3: R1`, `4: R2`, `5: L2+R2`).
- Ícone `[RT]` à direita.

### 3.2. Grade dos 8 Botões de Controle (Clusters Visuais)
Em vez de uma lista genérica, a Tela 1 apresentará os 8 botões divididos visualmente em dois grupos harmônicos com a identidade do HUD:
- **Cluster Esquerdo (D-Pad):**
  - D-Pad Cima (`DUP`)
  - D-Pad Baixo (`DDOWN`)
  - D-Pad Esquerda (`DLEFT`)
  - D-Pad Direita (`DRIGHT`)
- **Cluster Direito (Botões Faciais):**
  - Botão Cima (`Y`)
  - Botão Baixo (`A`) — *Na Página 1, fixo em Pulo / Jump*
  - Botão Esquerda (`X`)
  - Botão Direita (`B`)

#### Elementos de cada Card de Botão (210x62px):
1. **Ícone da Ação (36x36px):**
   - Textura real da magia, item ou macro vinculada.
   - Borda chanfrada de metal escuro com realce sutil.
   - Se vazio: exibe slot translúcido com `INV_Misc_QuestionMark`.
2. **Badge do Botão / Combinação:**
   - Texto em dourado âmbar (`|cffe09a15`), ex: `L2 + X`, `R2 + D-Pad Cima`, `Base: Y`.
3. **Nome da Ação Vinculada:**
   - Texto em branco puro (`|cffffffff`), truncado de forma elegante ou com rank: ex: `Fireball (Rank 4)`.
   - Se vazio: exibe `|cff888888(Vazio)|r`.
4. **Borda de Foco Dourada:**
   - Realce de seleção ativo no botão atualmente focado pelo D-Pad ou mouse.

### 3.3. Painel de Detalhes na Base (`detailCard`)
Aproveita a infraestrutura já existente do `MainMenu:CreateDetailCard(parent)`:
- Exibe o ícone grande da ação focada.
- Nome e Rank da habilidade.
- Tecla física real e slot associado (ex: `Tecla física: 7 — Ação: Barra Principal Slot 7`).
- Tooltip ou descrição curta do item/magia.
- Rodapé com as instruções de controle:
  `|cffe09a15[A]|r Mapear   |   |cffe09a15[X]|r Limpar   |   |cffe09a15[LT]/[RT]|r Páginas   |   |cffe09a15[B]|r Voltar`

---

## 4. Especificação da Tela 2 — Seletor de Conteúdo (Picker)

Ao selecionar um botão para mapear, a Tela 2 é exibida ocupando a área central.

### 4.1. Sub-cabeçalho da Tela 2
- **À esquerda:** Texto de identificação `Mapeando Combinação: [L2 + X]` com ícone da combinação.
- **À direita:** Botão de cancelamento `[B] Voltar`.

### 4.2. Linha 1 de Abas: Fontes de Ação
Quatro botões com o mesmo estilo das sub-abas do Main Menu:
1. **Livro de Magias (`SPELLBOOK`)**
2. **Bolsas & Consumíveis (`BAG`)**
3. **Macros (`MACROS`)**
4. **Barras de Ação Diretas (`BARS`)**

### 4.3. Linha 2 de Sub-Abas Contextuais
Preenchida dinamicamente conforme a fonte selecionada:
- **Se `SPELLBOOK`:** Abas de classe reais do jogador obtidas via `GetSpellTabInfo` (ex: `Geral`, `Armas`, `Fúria`, `Proteção`).
- **Se `BAG`:** Filtro de itens usáveis das bolsas 0 a 4 (ex: `Todos Usáveis`, `Poções & Elixires`, `Comida & Bebida`, `Diversos`).
- **Se `MACROS`:** `Macros Gerais` (1 a 18) e `Macros do Personagem` (19 a 36).
- **Se `BARS`:** `Barra Principal` (1-12), `Inferior Esquerda` (61-72), `Inferior Direita` (49-60), `Lateral 1` (25-36), `Lateral 2` (37-48).

### 4.4. Grade de Conteúdo (Grid 4x4 — 16 Slots)
- Grade perfeitamente alinhada com as dimensões internas do pergaminho (4 colunas x 4 linhas).
- Cada botão (slot de 98x58px) possui:
  - Ícone quadrado de 32x32px com cantos escurecidos.
  - Nome do item/magia quebrado em até 2 linhas (`WrapName`).
  - Rank em cinza discreto (`Rank 2`, `Rank 6`).
  - Quantidade/stacks no canto inferior direito para itens de bolsa.
  - Hover/foco com borda dourada.
- **Paginação inferior:**
  `[< Anterior]   Página X de Y   [Próxima >]`

### 4.5. Painel de Detalhes em Tempo Real
Conforme o jogador move o foco com o D-Pad sobre os botões da grade do Picker, o `detailCard` na base exibe o tooltip completo da habilidade/item/macro selecionada (custo de mana, tempo de lançamento, alcance, dano e descrição).

### 4.6. Mecânica de Aplicação e Persistência
Ao pressionar `[A]` em uma opção da grade:
1. É invocada a rotina de aplicação correspondente (`SBP:ApplySpellBinding`, `BP:ApplyItemBinding`, `MP:ApplyMacroBinding` ou bind direto de slot).
2. O slot de barra e a tecla física recebem a bind de combate.
3. Se a bind for na Página 1 de uma tecla substituída no menu, o snapshot em `KB.savedNavBindings` é imediatamente atualizado para preservar a integridade.
4. O `ActionHUD` tem seu `Update()` chamado na hora para sincronizar o visual.
5. Um som de confirmação nobre (`soundItemSelect`) é tocado.
6. A Tela 2 se fecha suavemente e a visualização retorna à Tela 1 com a bind já atualizada.

---

## 5. Plano de Execução em Fases Incrementais

### 🔹 FASE 1: Estrutura Base e Transição no Main Menu
- [ ] Implementar `MainMenu:SetupKeybindingsPage(pageSystem)` criando os containers `pageSystem.bindsScreen` (Tela 1) e `pageSystem.pickerScreen` (Tela 2).
- [ ] Alterar o botão *"Mapeador de Atalhos / Binds"* em `subPageAddonCfg` para navegar para a `bindsScreen` em vez de chamar `ConsoleMode.config:Show()`.
- [ ] Configurar a lógica do botão `[B]` para voltar de `bindsScreen` para `subPageAddonCfg`.
- [ ] **PARADA CRÍTICA:** Testar no WoW com `/reload` se o clique no menu abre a nova tela vazia e se `[B]` retorna normalmente.

### 🔹 FASE 2: Construção da Tela 1 (Mapeador de Combinações)
- [ ] Criar o cabeçalho superior de páginas com as 5 abas (`1: Base` a `5: L2+R2`) e indicadores `[LT]` / `[RT]`.
- [ ] Construir a grade visual dos 8 cards de botões (D-Pad e Face Buttons) com ícones, badges e nomes.
- [ ] Conectar a leitura das binds reais (`KBList:GetDisplayForButton`) aos 8 cards da página ativa.
- [ ] Conectar o `detailCard` inferior com foco nos botões de combinação.
- [ ] Adicionar suporte à ação de desvincular (`[X]` Limpar).
- [ ] **PARADA CRÍTICA:** Testar no WoW se as 5 páginas alternam perfeitamente e se todos os 8 botões mostram as magias/itens corretos configurados.

### 🔹 FASE 3: Construção da Tela 2 (Seletor de Conteúdo / Picker UI)
- [ ] Criar a `pickerScreen` com sub-cabeçalho indicando a combinação alvo (ex: `Mapeando: L2 + X`) e botão `[B] Voltar`.
- [ ] Implementar a linha 1 de abas de modos (`Spellbook`, `Bolsas`, `Macros`, `Barras`).
- [ ] Implementar a linha 2 de sub-abas dinâmicas.
- [ ] Implementar a grade 4x4 (16 botões) com botões de paginação `< Anterior` e `Próxima >`.
- [ ] **PARADA CRÍTICA:** Testar no WoW se clicar em uma combinação da Tela 1 abre a Tela 2 e se `[B]` retorna para a Tela 1.

### 🔹 FASE 4: Integração das Fontes de Dados e Mecânica de Bind
- [ ] Integrar dados do Livro de Magias (`SBP:GetSpellTabs`, `SBP:GetSpellsForTab`) com paginação e filtro de passivas.
- [ ] Integrar dados de Itens Usáveis das Bolsas (`BP:GetUsableBagItems`).
- [ ] Integrar dados de Macros (`MP:GetAccountMacros`, `MP:GetCharacterMacros`).
- [ ] Integrar dados das Barras de Ação Diretas (Slots 1 a 72).
- [ ] Conectar a seleção de um item da grade à aplicação da bind (`ApplySpellBinding`, `ApplyItemBinding`, etc.).
- [ ] Conectar o `detailCard` para exibir o tooltip do item focado na grade.
- [ ] **PARADA CRÍTICA:** Fazer um teste real de mapear uma magia, um item de bolsa e uma macro e verificar se o `ActionHUD` atualiza e o combate funciona.

### 🔹 FASE 5: Navegação via Gamepad, Polimento e Limpeza
- [ ] Registrar os botões das Telas 1 e 2 no `Cursor.lua` para navegação 100% fluida por D-Pad.
- [ ] Redirecionar comandos slash `/cm binds`, `/cm config`, `/cm settings` para abrir o Main Menu direto no Mapeador de Binds.
- [ ] Desativar/aposentar a criação da janela clássica `ConsoleModeSettingsFrame`.
- [ ] Validação de sintaxe com `luac -p` em todos os arquivos modificados.
- [ ] **PARADA CRÍTICA:** Revisão final completa com o usuário.
