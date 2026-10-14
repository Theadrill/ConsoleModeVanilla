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

### FASE 3: Busca por Texto via Teclado Virtual e Histórico
* **Objetivo:** Integrar o teclado virtual existente e gerenciar recentes/favoritos.
* **Tarefas:**
  * Botão `(Y)` abre o `VirtualKeyboard.lua` com campo de busca.
  * Gravação de buscas recentes (últimas 10) e favoritos (`R3` para favoritar).
  * Atalho na tela inicial para repetir buscas recentes com 1 toque.
* **Teste no Jogo:** Apertar `(Y)`, digitar um termo no teclado virtual, buscar e verificar se aparece na lista de recentes.

---

### FASE 4: Aba Vender — Inventário, Espelhamento Exato, Quantidade & MAX
* **Objetivo:** Interface de venda dividida com comparação em tempo real.
* **Tarefas:**
  * Coluna esquerda do inventário filtrada (somente itens leiloáveis).
  * Modal sólido `[VENDER] [PESQUISAR]` ao pressionar `(A)` no item.
  * Tela dividida:
    * Esquerda: Leilões atuais do item.
    * Direita: Preço espelhado **exato** do leilão selecionado (sem undercut automático).
    * Cenário sem leilões: Foco direto na direita com preço sugerido a 120% do vendor (`SellValues.lua`).
  * Seção Quantidade & Stacks com botão interativo `[ MAX ]` que calcula stacks cheios + restante.
  * Linha de **RESUMO** ao vivo.
  * Gatilho `(RT)` abre modal de confirmação de postagem em 9-Slice.
* **Teste no Jogo:** Colocar um item para vender com múltiplos stacks, testar o botão `MAX`, confirmar e verificar o leilão criado.

---

### FASE 5: Aba Meus Leilões e Histórico de Vendas
* **Objetivo:** Gerenciar leilões ativos e histórico persistente.
* **Tarefas:**
  * Lista de leilões ativos do jogador (`GetNumAuctionItems("owner")`).
  * Ação de cancelar leilão com `(A)`.
  * Histórico de vendas finalizadas com atalho `(Y)` para Repostar direto na tela de venda.
* **Teste no Jogo:** Cancelar um leilão ativo; verificar se itens vendidos aparecem no histórico.

---

### FASE 6: Polimento Visual, Limpeza e Homologação
* **Objetivo:** Limpeza de comandos de depuração da fase de pesquisa e validação geral.
* **Tarefas:**
  * Remover ou desativar os comandos dev `/cm ahdump` e `/cm ahprobe`.
  * Verificação completa de vazamentos de memória (pool fixo de frames).
  * Validação com `luac50.exe -p` em 100% dos arquivos novos e alterados.
* **Teste no Jogo:** Validação completa de ponta a ponta com gamepad.
