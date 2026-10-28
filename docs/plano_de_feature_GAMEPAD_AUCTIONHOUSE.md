# Plano Mestre: Tela de Leilão (ConsoleModeVanilla - Gamepad UI)

> [!CAUTION]
> ## LEITURA OBRIGATÓRIA ANTES DE QUALQUER AÇÃO:
> Leia e siga **À RISCA** o arquivo [`AI_CONTEXTO_ADDON_1.12.md`](../AI_CONTEXTO_ADDON_1.12.md).
> Todas as regras inegociáveis contidas nele são lei: **Lua 5.0.3 estrito** (validado via `C:\Tools\lua50\luac50.exe`), **zero API Retail**, **zero funções protegidas em stacks de gamepad**, **PUSH SOMENTE QUANDO O USUÁRIO PEDIR EXPLÍCITAMENTE (uma vez só)**, **modais com fundo 9-slice sólido (`Carved_9Slides.tga`)**, e **localização 100% via `CM:T()`**.
>
> ### AVISO CRÍTICO DE LOCALIZAÇÃO (ZERO DEPENDÊNCIA DE WoWTranslate.dll):
> **Não temos NADA a ver com `WoWTranslate.dll`.** Essa DLL traduz apenas mensagens do chat no servidor chinês e **NÃO traduz elementos da UI nem do cliente**. Toda a tradução do ConsoleMode é **100% proprietária e feita por nós mesmos**: o core define as chaves base em inglês em `Data/Locales/enUS/UI.lua` e a tradução para português é entregue pelo addon irmão oficial [`ConsoleModeVanilla-Localization-ptBR`](https://github.com/Theadrill/ConsoleModeVanilla-Localization-ptBR). Nunca depender nem assumir tradução via DLLs injetadas.

> **Ambiente:** World of Warcraft 1.12.1 (Turtle WoW 1.18.1)  
> **Linguagem:** Lua 5.0.3 estrito (zero sintaxe moderna, validado via `luac50.exe`)  
> **Identidade Visual:** Clássica Vanilla / ConsoleMode (9-Slice `Carved_9Slides.tga` para janela e modais)  
> **Localização:** 100% via `CM:T("AH_...")` em `Data/Locales/enUS/UI.lua` + addon irmão pt-BR (zero strings hardcoded)  
> **Arquitetura:** Desacoplada do `MainMenu.lua` (`UI/AuctionScreen.lua` + `UI/AuctionScan.lua`)

---

## 1. Princípios de Engenharia e Regras Inegociáveis

1. **Anti-Monólito / Reuso Total:**
   * Código de UI em `UI/AuctionScreen.lua`.
   * Motor de fila e scan de leilão em `UI/AuctionScan.lua`.
   * Reuso direto de `UI/VirtualKeyboard.lua` para entrada de texto (`Y`).
   * Reuso direto de `Data/SellValues.lua` para `%V` e preço sugerido (120%).
   * Reuso dos ícones de gamepad oficiais do addon (`Media/Buttons/` ou markup inline `|T...:16:16|t`).
   * Fundo e modais obrigatoriamente usando `Create9Slice` com `Media/Carved_9Slides.tga` (opaco, sem transparência).
2. **Segurança WoW 1.12 / Anti-Cheat:**
   * Compras e lances disparados estritamente por clique/confirmação explícita do usuário (`PlaceAuctionBid`).
   * Zero automação de compra em loop.
3. **Respeito aos limites do cliente 1.12:**
   * Scan paginado respeitando `CanSendAuctionQuery()` (~1 página a cada 3 a 4 segundos).
   * Barra de progresso visível durante scans.

---

## 2. Matriz Validada de Categorias e Slots (Turtle WoW 1.18.1)

Baseada nas sondas empíricas reais (`ahdump.txt` e `ahprobe.txt` + `ahprobe_retry.txt`):

* **Armas (`Weapon`):**
  * Machados, Maças, Espadas: Passo 1 (Família) → Passo 2 (1 Mão / 2 Mãos) → Passo 3 (Filtros).
  * Adagas, Armas de Punho: Direto (1 Mão implícito) → Filtros.
  * Cajados, Astas: Direto (2 Mãos implícito) → Filtros.
  * À Distância (Arcos, Armas de Fogo, Bestas, Varinhas, Arremesso): Direto → Filtros.
  * Outras (Diversos, Varas de Pescar): Direto → Filtros.
* **Armaduras (`Armor`):**
  * **Tecido (`Cloth`):** Cabeça, Ombros, Peito, Cintura, Pernas, Pés, Pulsos, Mãos e **Costas (Capas)**.
  * **Couro (`Leather`), Malha (`Mail`), Placa (`Plate`):** Cabeça, Ombros, Peito, Cintura, Pernas, Pés, Pulsos, Mãos.
  * **Diversos (`Miscellaneous`):** Colar (`Neck`), Anel (`Finger`), Berloque (`Trinket`), Mão Secundária (`Held In Off-hand`), Camisa (`Shirt`), Peito Cosmético (`Chest`).
  * **Escudos, Librams, Ídolos, Totens:** Sem seleção de slot (direto para filtros).
* **Filtros Salvos Inteligentes (Raridade + Nível):**
  * Salvos em `ConsoleModeDB.ahFilters[categoryKey]`.
  * Último filtro usado persiste por categoria. Botão `(X)` limpa para "Todas" e "0 a 0".

---

## 3. Fases Testáveis de Implementação

### FASE 0: Fundação, Localização e Hook de Abertura
* **Objetivo:** Preparar a base limpa e os ganchos do jogo.
* **Tarefas:**
  * Criar `UI/AuctionScreen.lua` e `UI/AuctionScan.lua` e registrá-los em `ConsoleModeVanilla.toc`.
  * Cadastrar todo o dicionário `AH_*` em `Data/Locales/enUS/UI.lua` (títulos, abas, botões, colunas, filtros, mensagens).
  * Registrar hook para o evento `AUCTION_HOUSE_SHOW` e `AUCTION_HOUSE_CLOSED`:
    * Esconder a janela Blizzard padrão (`AuctionFrame:Hide()`).
    * Garantir carregamento autônomo dos dados (`DataLoader` / `SellValues`).
    * Abrir a tela do ConsoleMode com moldura em 9-Slice `Carved_9Slides.tga`.
* **Teste no Jogo:** Falar com o leiloeiro abre a moldura vazia estilizada com as 3 abas [COMPRAR] [VENDER] [MEUS LEILÕES] e botões de gamepad estilizados.

---

### FASE 1: Aba Comprar — Categorias, Navegação D-Pad e Filtros Salvos
* **Objetivo:** Navegar na árvore de categorias até os filtros e disparar a query Blizzard.
* **Tarefas:**
  * Grid de botões 4x2 para classes principais (Armas, Armaduras, etc.).
  * Telas de passos intermediários com botões grandes (Família → 1M/2M, Material → Slot).
  * Tela de Filtros (Raridade com `< >` colorido, Faixa de Nível com `< >`, salvamento inteligente em `ConsoleModeDB`).
  * Disparo de `QueryAuctionItems` com barra de progresso visual.
* **Teste no Jogo:** Navegar por Armas > Machados > 2 Mãos > Filtros > Buscar. Ver a barra de progresso escanear.

---

### FASE 2: Lista de Itens, Detalhe do Leilão e Compra Fiel
* **Objetivo:** Exibir resultados agrupados por item, abrir leilões individuais e comprar com confirmação.
* **Tarefas:**
  * Lista de itens encontrados com preço "A partir de", contagem de leilões e `%V` (calculado via `Data/SellValues.lua`).
  * Tela de detalhe do item selecionado (`A`): lista de leilões individuais (sem quantidade customizável, stack fechado conforme o leilão).
  * Modal de confirmação de compra sólido em 9-Slice `Carved_9Slides.tga`.
  * Disparo de `PlaceAuctionBid("list", index, buyoutPrice)` e feedback de sucesso no topo.
* **Teste no Jogo:** Buscar um item barato, abrir seus leilões, selecionar um stack e comprar via modal. Validar desconto de ouro e recebimento no correio.

---

### FASE 3: Barra de Pesquisa por Nome na Tela de Filtros (Virtual Keyboard) e Histórico [CONCLUÍDO]
* **Objetivo:** Adicionar campo de busca textual na tela de Filtros com teclado virtual e suporte na query da Blizzard.
* **Tarefas:**
  * Linha de busca textual na tela `SEARCH FILTERS` (`Nome do Item: [ Digite para buscar... ]`).
  * Foco na linha e pressão de `(A)` ou `(Y)` abre o `VirtualKeyboard.lua`.
  * Botão `(X)` limpa o termo digitado rapidamente.
  * Integração com `QueryAuctionItems(name, ...)` enviando o nome digitado em conjunto com a categoria/subcategoria selecionada.
  * Gravação de buscas recentes (últimas 10) e favoritos (`R3` para favoritar).
* **Teste no Jogo:** Entrar em Armaduras > Tecido > Filtros, selecionar o campo de busca, digitar um nome no teclado virtual e disparar a busca. Conferir se a Blizzard retorna apenas itens da categoria com esse nome.

---

### FASE 4: Modal de Ordenação (Classificar Por) na Tela de Resultados com Tecla (Y) [CONCLUÍDO]
* **Objetivo:** Permitir ao jogador reordenar a lista de resultados (`ITEMS_LIST`) dinamicamente através de um modal gamepad aberto pela tecla `(Y)`.
* **Tarefas:**
  * Modal sólido em 9-Slice `Carved_9Slides.tga` centralizado (`ConsoleMode_AuctionSortModal`).
  * 9 opções completas de ordenação (Preço Unitário asc/desc, Buyout asc, Nome asc/desc, Nível asc/desc, Raridade desc/asc).
  * Navegação D-Pad Cima/Baixo entre as opções com destaque visual e tag `(Ativo)`.
  * Confirmação com `(A)`: reordena `self.groupedItems`, reseta seleção e scroll para o topo, re-renderiza a lista e fecha o modal.
  * Cancelamento com `(B)` ou `(Y)`: fecha o modal sem alterar.
  * Atualização dos footer hints da lista: `(A) Ver Leilões | (Y) Classificar | (B) Nova Busca`.
* **Teste no Jogo:** Fazer uma busca ampla (ex: Cloth), ver a lista de resultados, apertar `(Y)`, escolher "Preço Unitário: Maior ao Menor" e confirmar com `(A)`. A lista deve atualizar instantaneamente com os itens mais caros no topo.

---

### FASE 5: Split View na Tela de Resultados (Master-Detail) com Card de Tooltip Padronizado (Lógica da Bag no MainMenu) e Resumo Econômico [CONCLUÍDO]
* **Objetivo:** Transformar a tela de resultados em layout dividido (duas colunas), exibindo os dados completos e atributos do item selecionado à direita em tempo real conforme navega com o D-Pad, eliminando a necessidade de mouse hover no gamepad.
* **Tarefas:**
  * **Coluna Esquerda (~60% de largura):**
    * Reduzir a largura das linhas da lista para ~560px (Ícone, Nome do Item, Nível, Qtd Leilões, Preço Inicial e % Vendor).
  * **Coluna Direita (~40% de largura | Card de Informações em 9-Slice `Carved_9Slides.tga`):**
    * Implementar card de detalhes seguindo rigorosamente a **mesma arquitetura e lógica do tooltip de bolsa do `MainMenu.lua`** (`CreateDetailCard` / `ShowItem`):
      * Ícone grande com borda colorida por raridade (`iconBorder`).
      * Título com nome localizado (`ConsoleMode:GameLOC_Item`).
      * Tipo de item e slot de equipamento (`ConsoleMode:GameLOC_EquipLoc` / `ConsoleMode:GameLOC_ItemSubType`).
      * Extração de linhas de stats via `GameTooltip` scanner (`statsLines`: Dano, Velocidade, DPS, Atributos +Força/Agilidade/etc., Requisitos, Efeitos de Uso/Equip).
      * Preservação da compatibilidade com o addon irmão de tradução [`ConsoleModeVanilla-Localization-ptBR`](https://github.com/Theadrill/ConsoleModeVanilla-Localization-ptBR).
    * **Mini Resumo de Mercado no rodapé do Card:**
      * Preço no Vendedor (Vendor Sell Price) com widgets de moedas.
      * Total de leilões e total de unidades disponíveis no mercado.
      * Percentual comparativo contra o preço de loja (`% Vendor`).
* **Teste no Jogo:** Ao buscar espadas ou armaduras, navegar pelas linhas com o D-Pad e verificar o card à direita atualizando instantaneamente com todos os atributos, dano, stats traduzidos e preço de venda.

---

### FASE 6: Atalho Fast-Track (Y) na Navegação de Categorias e Subcategorias [CONCLUÍDO]
* **Objetivo:** Permitir ao jogador pular direto para a tela de filtros a partir de qualquer nível da árvore de categorias.
* **Tarefas:**
  * Atalho `(Y)` em `CATEGORIES`: seleciona a categoria principal e abre `SEARCH FILTERS` diretamente (com `subclassIndex = nil` e `invTypeIndex = nil`).
  * Atalho `(Y)` em `SUBCATEGORIES`: seleciona a subcategoria e abre `SEARCH FILTERS` diretamente (com `invTypeIndex = nil`).
  * Atualização dinâmica da legenda inferior: `(A) Selecionar | (Y) Filtrar Categoria | (B) Voltar`.
  * Breadcrumb dinâmico refletindo o salto (ex: `BUY > Armaduras > FILTROS DE BUSCA`).
* **Teste no Jogo:** Posicionar o cursor em "Armas" na tela inicial e apertar `(Y)`. A tela de filtros deve abrir imediatamente. Disparar a busca e verificar se lista todas as armas.

---

### FASE 7: Aba Vender — Inventário, Scan Automático, Espelhamento Exato, Quantidade & MAX [EM IMPLEMENTAÇÃO — FLUXO SEM MODAL]
* **Objetivo:** Interface de venda dividida com comparação em tempo real e scan automático ao selecionar o item.
* **Decisão do PO (14/10/2026, vale sobre versões anteriores):** SEM modal `[VENDER] [PESQUISAR]`. Clicou/(A) no item da bag = começa scan automaticamente e vai para a tela de venda com os valores scaneados.
* **Tarefas:**
  * Coluna esquerda do inventário filtrada (somente itens leiloáveis).
  * SEM modal de ação: `(A)` ou clique no item dispara `AuctionScan:StartQuery` com `name = item.name` e demais filtros zerados (`class/sub/slot = 0`, `quality = -1`, `min/max = 0`, `isUsable = 0`) e abre o LISTING imediatamente em estado "pesquisando".
  * Tela dividida:
    * Esquerda: Leilões atuais do item (preenchidos ao completar o scan via `LoadSellCompetitors` + `MirrorCompetitorPrice(1)`; antes disso exibe estado de pesquisa).
    * Direita: Preço espelhado **exato** do leilão selecionado (sem undercut automático).
    * Cenário sem leilões/erro/timeout: Foco direto na direita com preço sugerido a 120% do vendor (`SellValues.lua`).
  * Atalho `(Y)` "Pesquisar Mercado" na INVENTORY removido (pesquisa virou automática); `(X)` segue atualizando o inventário.
  * Seção Quantidade & Stacks com botão interativo `[ MAX ]` que calcula stacks cheios + restante.
  * Linha de **RESUMO** ao vivo.
  * Gatilho `(RT)` abre modal de confirmação de postagem em 9-Slice.
  * Blindagens 1.12: `pcall(AuctionFrameTab_OnClick, 1)` silencioso antes do scan (servidor só responde na aba Browse), debounce/`isScanning` contra duplo `(A)`, `AbortQuery` ao voltar/fechar, validação de `pendingSellScanItem` no `onComplete`.
* **Teste no Jogo:** Abrir SELL fresco (`/reload` antes), pressionar `(A)` num item sabidamente listado: sem modal, LISTING abre pesquisando e depois lista concorrentes reais. Repetir com item sem oferta: fallback 120% vendor. Testar duplo `(A)` rápido e `B` no meio do scan sem erro Lua.

---

### FASE 8: Aba Meus Leilões e Cancelamento de Leilão [CONCLUÍDO]
* **Objetivo:** Gerenciar leilões ativos do jogador e cancelamento com segurança.
* **Tarefas Concluídas:**
  * Lista de leilões ativos do jogador (`GetNumAuctionItems("owner")` com disparo de `GetOwnerAuctionItems()` no `AUCTION_OWNED_LIST_UPDATE`).
  * Tabela com colunas completas: Ícone, Nome com Raridade, Pilha, Tempo restante, Maior Lance (High Bidder), Lance Atual e Compra Imediata.
  * Modal 9-Slice de cancelamento com alertas inteligentes (aviso de perda de depósito vs venda imediata ao maior lance).
  * Feedback sonoro e no chat.

---

### FASE 9: Cache de Scan (TTL 2min), Botões [RE-SCAN] (Y) e Inversão de Atalhos [CONCLUÍDO]
* **Objetivo:** Cache inteligente de leilões por 2 minutos evitando queries repetidas desnecessárias e atalhos rápidos de Re-scan e MAX.
* **Especificação Detalhada:**
  * **Cache em Memória (TTL 2 minutos):**
    * Ao pesquisar um item na aba `SELL` ou `BUY`, guardar os resultados agrupados/concorrentes indexados pela chave do item com timestamp (`GetTime()`).
    * Ao trocar de item e voltar em menos de 2 minutos, carregar instantaneamente do cache em memória sem disparar query no servidor.
  * **Botão [RE-SCAN] com Textura (Y) nas Tabelas:**
    * **Aba SELL (Split View de Venda):** Botão visual `[ RE-SCAN (Y) ]` no topo da coluna esquerda (acima de Market Competitors).
      * Pressionar `(Y)` enquanto estiver na coluna da esquerda força um novo scan descartando o cache.
      * Pressionar `(Y)` enquanto estiver na coluna da direita (`FORM`) executa o atalho rápido de preencher quantidade máxima permitida (`MAX`: stack size no teto e number of stacks no teto possível).
    * **Aba BUY (Lista de Resultados / ITEMS_LIST):** Botão visual `[ RE-SCAN (Y) ]` no topo da lista.
      * Atalho de ordenação (`Sort / Classificar Por`) migra de `(Y)` para `(X)`, mantendo a consistência do `(Y)` como Re-scan global em ambas as abas.
      * Atalho `(Y)` executa nova query no servidor com os filtros ativos.

---

### FASE 10: Polimento Visual, Limpeza e Homologação [CONCLUÍDO]
* **Objetivo:** Limpeza de comandos de depuração da fase de pesquisa e validação geral.
* **Tarefas:**
  * Remover ou desativar os comandos dev `/cm ahdump` e `/cm ahprobe`.
  * Verificação completa de vazamentos de memória (pool fixo de frames).
  * Validação com `luac50.exe -p` em 100% dos arquivos novos e alterados.
* **Teste no Jogo:** Validação completa de ponta a ponta com gamepad.


---

## 4. Integração com o Sistema de Linguagem e Localização (pt-BR)

### Diagnóstico Técnico
1. **Dicionário da Interface (Data/UI.lua do addon irmão):**
   * As 225 chaves `AH_*` existem exclusivamente em inglês em `ConsoleModeVanilla/Data/Locales/enUS/UI.lua`.
   * O repositório irmão `ConsoleModeVanilla-Localization-ptBR` ainda não possui nenhuma dessas chaves, forçando o fallback em inglês mesmo com idioma pt-BR ativo.
2. **Nomes de Itens e Atributos de Tooltip:**
   * Itens retornados pela Blizzard vêm em inglês nativo. A exibição visual consome `ConsoleMode:GameLOC_Item` e `GameLOC_ItemDesc`, mas a ordenação alfabética (A-Z) precisa respeitar os nomes traduzidos.
3. **Busca Textual Bilíngue (Virtual Keyboard) vs Servidor em Inglês:**
   * A API do servidor 1.12 `QueryAuctionItems(name, ...)` compara com nomes em inglês. Digitar `"Barra de Cobre"` no Virtual Keyboard falha se não houver um mapeamento reverso (`ptBR -> enUS`) antes do envio.
4. **NPCs Leiloeiros:**
   * Exibição do nome e cargo dos leiloeiros das capitais integrada ao banco de dados CapycraftDB / `NPC.lua`.

---

### Fases Testáveis de Localização:

#### FASE 11: Dicionário Completo de UI da Auction House em pt-BR
* **Objetivo:** Tradução 100% oficial e sincronização das 225 chaves `AH_*` para o addon irmão `ConsoleModeVanilla-Localization-ptBR`.
* **Tarefas:**
  * Tradução das abas (`COMPRAR`, `VENDER`, `MEUS LEILÕES`), botões, legendas, cabeçalhos de tabela.
  * Tradução de todas as categorias, subcategorias e slots de armas e armaduras.
  * Tradução dos critérios do modal de ordenação e avisos dos modais de confirmação/cancelamento.
  * Injeção das chaves em `ConsoleModeVanilla-Localization-ptBR/Data/UI.lua`.
* **Teste no Jogo:** Abrir o leiloeiro com `/cm lang ptBR`. Verificar que 100% dos textos fixos, menus, categorias e botões aparecem em português.

---

#### FASE 12: Cobertura de GameLOC nos Itens e Ordenação Alfabética Localizada
* **Objetivo:** Garantir exibição de nomes traduzidos em todas as abas e ordenação alfabética correta em pt-BR.
* **Tarefas:**
  * Auditoria de `GameLOC_Item` em todas as views (lista agrupada, detalhes, concorrentes, formulário, resumo de venda e meus leilões).
  * Atualização da ordenação `NAME_ASC` e `NAME_DESC` em `AuctionScreen:SortGroupedItems` para comparar `locName` quando o idioma ativo for ptBR.
  * Garantir que o tooltip split-view exiba stats e requisitos traduzidos via `GameLOC_ItemDesc` e `GameLOC_EquipLoc`.
* **Teste no Jogo:** Visualizar itens no mercado e ordenar de A a Z conferindo a ordem pelo nome em português.

---

#### FASE 13: Busca Textual Bilíngue com Resolução Reversa (ptBR ➔ enUS)
* **Objetivo:** Permitir ao jogador digitar nomes em português no teclado virtual e encontrar o item no servidor em inglês.
* **Tarefas:**
  * Implementar lookup reverso no banco de dados de itens (`ItemDB`): dado um termo digitado em português, identificar o nome original em inglês do item.
  * Se houver correspondência, enviar o termo em inglês para `QueryAuctionItems`, mantendo o termo digitado pelo jogador no campo visual.
  * Suporte no Virtual Keyboard para autocomplete a partir do nome em português.
* **Teste no Jogo:** Digitar "Linho" ou "Cobre" no filtro de busca com Virtual Keyboard. Confirmar que a busca no servidor retorna "Linen Cloth" e "Copper Bar".

---

#### FASE 14: Nome e Cargo do Leiloeiro Localizado e Homologação Final
* **Objetivo:** Exibir nome e título de NPC autênticos no cabeçalho do leilão.
* **Tarefas:**
  * Conectar `UnitName("npc")` com a API `ConsoleMode:GetNPCDisplayName(id, enName)` e `ConsoleMode:GetNPCRole(id, enRole)`.
  * Validação geral em capitais da Horda e da Aliança.
* **Teste no Jogo:** Falar com leiloeiros em Ironforge, Stormwind e Orgrimmar e verificar nome e título traduzidos no cabeçalho.
