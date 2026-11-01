# Plano de Feature: Painel de Configurações da Ordenação Virtual (Virtual Sort Options)

> **Status:** Proposto / Em Planejamento  
> **Versão Alvo:** WoW 1.12.1 (Interface 11200) / Lua 5.0 (Turtle WoW)  
> **Ambiente:** Handheld (Steam Deck 1280x800) & Desktop PC  
> **Data:** 01/11/2026  
> **Módulos Envolvidos:**
> - `UI/InventorySorter.lua` (Extensão do motor dinâmico e presets)
> - `UI/BagSortModal.lua` (Novo módulo satélite desacoplado — isolado do monólito)
> - `Data/Locales/enUS/UI.lua` (Dicionário base do addon)
> - `../ConsoleModeVanilla-Localization-ptBR/Data/UI.lua` (Dicionário ptBR irmão)
> - `UI/MainMenu.lua` (Apenas ponte mínima: rótulo e disparo no `sortBtn`)
> - `UI/MainMenuNav.lua` (Apenas interceptação de input modal quando aberto)
> - `ConsoleModeVanilla.toc` (Registro do novo arquivo na ordem correta)

---

## 1. Diretrizes Arquiteturais Mandatórias

### 1.1. Não Alimentar o Monólito `MainMenu.lua`
Seguindo a política de arquitetura modular estabelecida para o projeto:
- **Zero inchaço no `MainMenu.lua`:** O modal, sua janela, seus frames, labels, texturas, pool de widgets e lógica interna de navegação residem **100% dentro de um novo módulo desacoplado** (`UI/BagSortModal.lua`).
- **Ponte Mínima no `MainMenu`:** Apenas apontar o clique do botão existente `pageBags.sortBtn` para `ConsoleMode_BagSortModal:Open()`.
- **Roteamento Limpo no `MainMenuNav`:** Quando `ConsoleMode_BagSortModal:IsOpen()`, o navegador delega o input com uma única verificação limpa no topo dos manipuladores de evento, similar ao padrão do `QuantityPicker` e `EnhanceModal`.

### 1.2. Reuso Máximo de Componentes (Zero Código Duplicado)
Para evitar redundância e garantir consistência estética e de performance:
1. **Motor de Apresentação:** Reaproveitar `UI/InventorySorter.lua` como motor de cálculo único — apenas parametrizando seus comparadores a partir das configurações salvas.
2. **Textura 9-Slice de Pergaminho:** Reaproveitar a textura clássica oficial do projeto (`Media/Carved_9Slides.tga`) e o helper já validado de 9-Slice (`MainMenu:Create9Slice` ou utilitário equivalente).
3. **Tipografia & Paleta Oficial:** Reuso das fontes já carregadas (`CFG.Fonts` / `AlegreyaSans-Bold`, `AlegreyaSans-Medium`) e cores padrão (dourado `#ffe09a` para seleção ativa, bronze para bordas).
4. **Áudio Nativo:** Reuso das chamadas de som Blizzlike existentes (`soundItemSelect`, `soundMenuClose`).
5. **Pipeline de Renderização:** Reuso de `MainMenu:UpdateBagsPage()` para recálculo instantâneo sem recriar nenhum slot visual.

### 1.3. Aderência Estrita ao Sistema de Linguagem (`docs/plano_de_feature_SISTEMA_DE_LINGUAGEM.md`)
Conforme a padronização oficial de localização do ConsoleMode:
- **Zero Strings Hardcoded:** Nenhuma palavra em português ou inglês inserida no código. 100% dos textos visíveis na interface são obtidos via `CM:T("BAGS_SORT_*")`.
- **Chaves Semânticas:** Formato `MODULO_ASSUNTO_DETALHE` em caixa alta sem acentos nas chaves (`BAGS_SORT_TITLE`, `BAGS_SORT_OPT_MODE`, `BAGS_SORT_VAL_ON`, etc.).
- **Paridade de Locales:** Injeção das chaves nos dois arquivos correspondentes:
  1. `Data/Locales/enUS/UI.lua` (pacote base em inglês do addon).
  2. `ConsoleModeVanilla-Localization-ptBR/Data/UI.lua` (pacote em português brasileiro do repositório irmão).
- **Cores Embutidas nas Strings:** Sequências de cor `|cff...|r` mantidas no dicionário de tradução, nunca concatenadas no meio do código.
- **Formatação Segura:** Mensagens parametrizadas usam sufixo `_FMT` com `%s`/`%d` via `format()`.

---

## 2. Design Visual & Ergonomia Handheld (Steam Deck)

### 2.1. Anatomia do Modal (`ConsoleMode_BagSortModal`)
* **Dimmer Escuro:** Frame com `SetFrameStrata("DIALOG")`, `SetFrameLevel(45)`, preenchendo a tela com `0, 0, 0, 0.70` para foco visual imediato.
* **Janela Central:** `460px` de largura por `400px` de altura.
  * Bordas e cantos esculpidos via textura 9-Slice clássica (`Media/Carved_9Slides.tga`).
* **Cabeçalho:**
  * Título: `CM:T("BAGS_SORT_TITLE")` ("ORDENAÇÃO DAS BOLSAS" / "BAG SORTING"), dourado (`1.0, 0.85, 0.25`), 20px, negrito.
  * Subtítulo: `CM:T("BAGS_SORT_SUBTITLE")` ("Ajuste as prioridades da organização virtual"), branco suave, 13px.
* **Linhas de Configuração (5 Linhas Pré-Alocadas em Pool Fixo):**
  * Altura de `36px` com espaçamento de `4px`.
  * Foco ativo: Borda dourada (`1.0, 0.85, 0.25`), fundo marrom escuro iluminado (`0.22, 0.17, 0.10, 0.90`).
  * Indicadores laterais: Setas `<` e `>` nos valores para indicar alternância cíclica via D-Pad Esquerda/Direita.
* **Rodapé com Texturas Reais do Gamepad (100% Ícones TGA):**
  * Nada de texto cru como `[A]` ou `[D-Pad]`.
  * Ícones reais de `Media/Icons/Xbox/`:
    * `DUP.tga` + `DDOWN.tga` + `CM:T("HINT_NAVIGATE")` ("navegar")
    * `DLEFT.tga` + `DRIGHT.tga` ou `A.tga` + `CM:T("BAGS_SORT_HINT_CHANGE")` ("alterar")
    * `Y.tga` + `CM:T("BAGS_SORT_HINT_RESET")` ("padrões")
    * `B.tga` + `CM:T("HINT_CLOSE")` ("fechar")

---

## 3. Matriz de Configurações do Virtual Sort

| Linha | Configuração | Chave (`ConsoleModeDB.virtualSort`) | Valores Possíveis | Descrição / Efeito |
|---|---|---|---|---|
| **1** | **Organização Virtual** | `enabled` | `Ativada` / `Desativada` | Liga ou desliga o virtual sort. Se desligada, as bolsas mostram a ordem física nativa (Bag 0..4). |
| **2** | **Critério Principal** | `mode` | `Categoria` / `Qualidade` / `Nome (A-Z)` / `Nível` | Regra mestra da ordenação primária no Grid. |
| **3** | **Perfil de Categoria** | `preset` | `Balanceado` / `Equipamentos` / `Consumíveis` / `Profissão` | Define a hierarquia de categorias quando no modo Categoria. |
| **4** | **Itens de Missão** | `questOnTop` | `No Topo` / `Normal` | Garante que itens de missão sempre fiquem nas primeiras posições. |
| **5** | **Agrupar Itens Iguais** | `groupByName` | `Sim` / `Não` | Mantém itens idênticos lado a lado para rápida identificação de stacks. |

### 3.1. Presets de Categoria (Reaproveitados no Motor)
- **Balanceado:** `Missões (1) > Equipamentos (2) > Poções (3) > Comida (4) > Usáveis (5) > Trade (6) > Diversos (7) > Lixo (8)`
- **Equipamentos:** `Equipamentos (1) > Poções/Comida (2) > Missões (3) > Trade (4) > Diversos (5) > Lixo (6)`
- **Consumíveis:** `Poções (1) > Comida/Bebida (2) > Usáveis (3) > Equipamentos (4) > Missões (5) > Trade (6) > Lixo (7)`
- **Profissão & Farm:** `Trade/Materiais (1) > Missões (2) > Equipamentos (3) > Consumíveis (4) > Diversos (5) > Lixo (6)`

---

## 4. Cronograma de Fases TESTÁVEIS e Auditáveis pelo PO

A execução segue o padrão de liderança técnica: modular, passos testáveis com parada obrigatória para o PO validar in-game, e validação de sintaxe estrita com **Lua 5.0 real** (`C:\Tools\lua50\luac50.exe -p`).

---

### 🟢 FASE 1: Motor Dinâmico em `UI/InventorySorter.lua` & Dicionário nos Locales
> **Objetivo Observável:** O motor de ordenação virtual passa a consultar configurações dinâmicas com fallback seguro para os padrões já existentes. As chaves de localização são injetadas em `enUS` e `ptBR`.
> **Não mexe no `MainMenu.lua` nesta fase.**

- [ ] **Configuração Padrão e Acesso Seguro:**
  - Criar `CONSOLEMODE_DEFAULT_SORT_CONFIG` e métodos `ConsoleMode:GetSortConfig()` e `ConsoleMode:SetSortConfig(k, v)`.
  - Persistência estruturada em `ConsoleModeDB.virtualSort`.
- [ ] **Comparador Dinâmico:**
  - Atualizar `InventorySortComparator(a, b)` para respeitar `cfg.enabled` (retorna ordem original se falso), `cfg.mode`, `cfg.preset`, `cfg.questOnTop` e `cfg.groupByName`.
- [ ] **Injeção de Chaves de Localização (Conforme `plano_de_feature_SISTEMA_DE_LINGUAGEM.md`):**
  - Adicionar as chaves `BAGS_SORT_*` em `Data/Locales/enUS/UI.lua`.
  - Adicionar as mesmas chaves traduzidas em `../ConsoleModeVanilla-Localization-ptBR/Data/UI.lua`.
- [ ] **Validação Toolchain:**
  - Rodar `C:\Tools\lua50\luac50.exe -p` em `UI/InventorySorter.lua`, `Data/Locales/enUS/UI.lua` e no `UI.lua` do ptBR.
- **🛑 PARADA DE AUDITORIA (FASE 1):**
  - Confirmação de 0 erros no Lua 5.0. O PO pode rodar `/reload` no jogo e confirmar que o inventário continua abrindo e ordenando perfeitamente com os valores padrão.

---

### 🟢 FASE 2: Criação do Módulo Desacoplado `UI/BagSortModal.lua`
> **Objetivo Observável:** Criação do módulo satélite independente com janela 9-Slice, Dimmer, linhas de navegação e barra inferior com texturas do gamepad.
> **Totalmente desacoplado do `MainMenu.lua`.**

- [ ] **Módulo Satélite `ConsoleMode_BagSortModal`:**
  - Criação de `UI/BagSortModal.lua` com estado `isOpen`, `selectedRow` e referências pré-alocadas (pool fixo, zero criação dinâmica em runtime).
  - Dimmer em camada `DIALOG`, janela central com 9-Slice (`Carved_9Slides.tga`).
  - Cabeçalho com fontes e cores oficiais.
  - Pool de 5 linhas interativas (fundo escuro, borda dourada quando focada, labels e valores com setas `<` `>`).
  - Rodapé de atalhos utilizando exclusivamente **texturas** de `Media/Icons/Xbox/` (`DUP`, `DDOWN`, `DLEFT`, `DRIGHT`, `A`, `B`, `Y`).
- [ ] **Registro no `.toc`:**
  - Inserir `UI\BagSortModal.lua` em `ConsoleModeVanilla.toc` imediatamente após `UI\InventorySorter.lua` e antes de `UI\MainMenu.lua`.
- [ ] **Validação Toolchain:**
  - `C:\Tools\lua50\luac50.exe -p UI/BagSortModal.lua` com exit code 0.
- **🛑 PARADA DE AUDITORIA (FASE 2):**
  - O PO pode abrir o modal no jogo via comando de teste no chat ou script (ex.: `/script ConsoleMode_BagSortModal:Open()`) e inspecionar a qualidade visual, as texturas e o alinhamento na tela do Steam Deck.

---

### 🟢 FASE 3: Conexão Mínima no `MainMenu.lua` & Roteamento no `MainMenuNav.lua`
> **Objetivo Observável:** O botão antigo "Organizar" é atualizado para "Opções de Ordenação" (com ícone `[X]` em textura). Apertar `[X]` nas bolsas ou navegar até o botão e teclar `[A]` abre o modal. O D-Pad navega entre as linhas do modal e `[B]` fecha com segurança.

- [ ] **Ponte no `UI/MainMenu.lua`:**
  - Atualizar o botão `pageBags.sortBtn`:
    - Texto via `CM:T("BAGS_SORT_BTN_LABEL")` ("Opções de Ordenação" / "Sort Options").
    - Manter textura do ícone `[X]` (`CFG.Icons.X`).
    - `OnClick`: invoca `ConsoleMode_BagSortModal:Open()`.
- [ ] **Roteamento no `UI/MainMenuNav.lua`:**
  - Quando `ConsoleMode_BagSortModal:IsOpen()` estiver ativo:
    - `OnUp` / `OnDown`: navega entre as linhas do modal.
    - `OnLeft` / `OnRight` / `OnButtonA`: cicla as opções da linha selecionada.
    - `OnButtonB`: fecha o modal e retorna foco às bolsas.
    - `OnButtonY`: restaura os valores padrão.
  - Ao pressionar `[X]` na aba `BAGS`: abre o modal `ConsoleMode_BagSortModal:Open()`.
  - Ao pressionar `[A]` na zona `"SORT"`: abre o modal `ConsoleMode_BagSortModal:Open()`.
- [ ] **Validação Toolchain:**
  - `C:\Tools\lua50\luac50.exe -p` em `UI/MainMenu.lua` e `UI/MainMenuNav.lua`.
- **🛑 PARADA DE AUDITORIA (FASE 3):**
  - O PO testa com o controle no jogo: pressionar `[X]` abre o modal; D-Pad navega entre as 5 opções; `[B]` fecha e o cursor volta para onde estava.

---

### 🟢 FASE 4: Reatividade em Tempo Real, Áudio e Feedback
> **Objetivo Observável:** Ao alterar qualquer opção (ex.: mudar modo de ordenação ou desligar/ligar), os itens nas bolsas se reordenam instantaneamente em segundo plano aos olhos do jogador, acompanhados de som de clique do WoW.

- [ ] **Atualização Reativa:**
  - Ao alterar qualquer opção no modal, invocar `MainMenu:UpdateBagsPage()` para atualização instantânea em memória dos slots do Grid.
  - Tocar efeito sonoro `soundItemSelect` ao trocar valores e `soundMenuClose` ao fechar.
- [ ] **Ação `[Y]` (Restaurar Padrões):**
  - Reseta os valores em `ConsoleModeDB.virtualSort` para os padrões originais, atualiza a UI do modal e reordena as bolsas.
- [ ] **Validação Toolchain:**
  - `C:\Tools\lua50\luac50.exe -p` em todos os arquivos modificados.
- **🛑 PARADA DE AUDITORIA (FASE 4):**
  - O PO alterna entre "Ativada" e "Desativada" e observa os itens voltando para a ordem física das bolsas instantaneamente; ao reativar, reordenam no ato.

---

### 🟢 FASE 5: Homologação no Jogo pelo PO e Atualização do `README.md`
> **Objetivo Observável:** Teste de ponta a ponta sem regressão nas bolsas, compra/venda em vendedores, envio de correio e manuseio de itens. Fechamento formal do item no roadmap.

- [x] **Auditoria de Não-Regressão:**
  - Testar uso de consumíveis com `[A]`.
  - Testar abertura de menu de contexto em itens.
  - Testar comparação de equipamentos no DetailCard.
  - Testar arrastar/mover itens com o mouse.
- [x] **Atualização do `README.md`:**
  - Marcar o item como concluído:
    `- [x] Painel de Configurações do Virtual Sort (substituir o botão 'Organizar' das bolsas por um atalho/botão que abre as opções e prioridades da ordenação virtual)`
- **🛑 APROVAÇÃO FINAL:** Entrega formalizada e aprovada pelo PO.

---

## 6. Seção de FIXES & Refinamentos Homologados pelo PO

Demandas identificadas durante o teste prático in-game pelo PO para ajuste antes do encerramento da feature:

- [x] **FIX 1 — Correção de Itens de Missão:** Quando a opção `questOnTop` estiver desativada (`questOnTop == false`), os itens de missão não devem ser forçados na primeira posição; devem respeitar a hierarquia normal de sua categoria ou ficar junto aos itens comuns.
- [x] **FIX 2 — Acentuação & Caracteres nas Janelas do Addon:** Restaurar a acentuação correta em português (`ç`, `ã`, `õ`, `é`, etc.) nas strings do modal em `ConsoleModeVanilla-Localization-ptBR/Data/UI.lua`, visto que a fonte personalizada do addon (`AlegreyaSans`) possui suporte completo a esses glifos.
- [x] **FIX 3 & 4 — Reformulação da Navegação & Prevenção de Falso Reset:**
  - Desvincular o botão `[A]` da ciclagem de opções.
  - Alternância de opções feita **exclusivamente via D-Pad Esquerda / Direita** (e clique direto nas setas `<` `>`).
  - Botão `[A]` passa a ter função ergonômica padrão de **Confirmar / Salvar e Fechar o Modal** (`Modal:Close()`), eliminando o problema em que apertar `[A]` para sair alterava a opção de volta aos padrões.
  - Botão `[B]` para Fechar/Cancelar.
  - Botão `[Y]` exclusivo para Restaurar Padrões de Fábrica.
- [x] **FIX 5 — Legibilidade do Rodapé (Handheld / Steam Deck):**
  - Aumentar os ícones do gamepad no footer de 18px para 25px (padrão oficial do `MainMenu`).
  - Aumentar a fonte das legendas de 12px para 14px (`AlegreyaSans-Medium`).
  - Ajustar o espaçamento das legendas.
- [x] **FIX 6 — Largura Dinâmica e Adaptativa do Modal (Suporte a Idiomas da Comunidade):**
  - Identificado overflow visual do footer vazando a borda esculpida à direita.
  - Implementado `Modal:UpdateFooterLayout()` que calcula dinamicamente a largura ocupada por cada legenda via `GetStringWidth()`, permitindo suporte a qualquer idioma customizado sem edição de código fonte.
  - O modal agora adapta sua largura dinamicamente (`math.max(520, totalFooterWidth + 80)`), garantindo 40px de respiro interno nas margens esculpidas de 9-slice (`cornerSize = 48`) em qualquer resolução ou idioma.
- [x] **FIX 7 — Eliminação Definitiva do Reset ao Entrar no Modal:**
  - *Causa Raiz Identificada:* No Vanilla, o atalho `CM_CURSOR_SECONDARY` (botão `[X]`) possui `runOnUp="true"` para suportar o repeat de backspace do Virtual Keyboard. Ao abrir o modal apertando `[X]` nas Bolsas, o evento `down` abria o modal (`IsOpen() = true`), e o subsequente evento `up` (ao soltar o botão `[X]`) caía no manipulador de `Nav:OnSecondary()` onde uma chamada indevida a `ResetDefaults()` era executada imediatamente!
  - *Correção:*
    1. Removida a chamada indevida a `ResetDefaults()` de `Nav:OnSecondary()`.
    2. Adicionado bloqueio `if keystate ~= "up" then` no despacho de `OnSecondary` em `Keybindings.lua` e `Keybindings-STEAMDECK.lua`.
    3. Restaurar Padrões agora é acionado exclusivamente pelo botão `[Y]` (`Nav:OnUse()`), conforme indicado na legenda do rodapé.

