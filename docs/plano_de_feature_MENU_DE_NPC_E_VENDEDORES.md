# Plano de Feature: MENU DE NPC, VENDEDORES & INVENTÁRIO SPLIT-VIEW (ConsoleMode)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido terminantemente o uso de operadores de Lua 5.1+ (como operador de tamanho `#table`, usar `table.getn(t)` ou `getn(t)`), `continue` ou `goto`.
> 3. **Arquitetura Modular Isolada (Fim do Monólito):**
>    - O `MainMenu.lua` atual tornou-se um arquivo excessivamente volumoso (+13.000 linhas).
>    - Esta feature **NÃO DEVE** ser colocada dentro de `MainMenu.lua`.
>    - O sistema nascerá como um módulo **100% independente e desacoplado**: `UI/MerchantMenu.lua`.
>    - Será carregado via `ConsoleModeVanilla.toc` e inicializado por eventos no `Core.lua` / `Hooks.lua`.
> 4. **Identidade Visual Rigorosa do CONSOLEMODE (Abandono Total da UI Clássica da Blizzard):**
>    - **ABANDONO TOTAL DO VISUAL ARCAICO:** É terminantemente proibido renderizar a janela clássica `MerchantFrame` de 2004 da Blizzard. Toda a interação mercantil deve ocorrer na interface nativa do ConsoleMode.
>    - **Tipografia Nobre:** Fontes aplicadas exclusivamente via `ApplyFont()` utilizando `titleFontFile` e `headerFontFile` (`AlegreyaSans-Bold.ttf` com o mod de -9% de kerning), `bodyFontFile` (`AlegreyaSans-Bold.ttf`) e `subFontFile` (`AlegreyaSans-Medium.ttf`).
>    - **Paleta de Cores Oficial:** Dourado âmbar nobre (`|cffe09a15`), cinza suave para inativos (`|cffaaaaaa`), texto branco puro (`|cffffffff`), verde para cura/compra (`|cff1eff00`) e vermelho para erros/custos indisponíveis (`|cffff2020`).
>    - **Backdrops Customizados:** Fundos escurecidos translúcidos com alpha 0.40-0.85 (`Interface\Tooltips\UI-Tooltip-Background`), bordas finas com corte refinado (`Interface\Tooltips\UI-Tooltip-Border`) e cantos com insets padronizados de 2-3px.
>    - **Glifos e Texturas Oficiais de Botões:** O rodapé e as legendas de ações **DEVEM** usar as texturas gráficas reais de controle já existentes no addon (`Interface\AddOns\ConsoleModeVanilla\Media\Icons\Xbox\`), como `A.tga`, `B.tga`, `X.tga`, `Y.tga`, `LB.tga`, `RB.tga`, `LT.tga`, `RT.tga`.
>    - **DetailCard Estilo RPG Console:** Painel inferior fixo de detalhes, comparação em tempo real com itens equipados (`ItemCompare`) e valores financeiros.
> 5. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 6. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem autorização explícita do usuário.
> 7. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem validação no jogo via `/reload` e aprovação do usuário.

---

## 1. Visão Geral

Ao interagir com um NPC vendedor ou reparador no WoW 1.12, o jogo abre a janela nativa `MerchantFrame` de 2004. No controle (especialmente no Steam Deck), essa janela apresenta limitações severas:
- Exibe apenas 10 itens por página com paginação arcaica.
- Exige movimentação do cursor virtual do mouse para inspecionar, comprar e vender.
- Abre as bolsas padrão da Blizzard de forma desconexa ou desalinhada, poluindo a tela.
- Não oferece comparação direta entre os itens vendidos pelo NPC e os que o jogador já está vestindo.

A proposta desta feature é **interceptar a interação com NPCs comerciantes** e renderizar uma janela customizada completa em **Split-View (tela dividida)** no mesmo padrão estético do ConsoleMode:
- **Coluna Esquerda:** Estoque do NPC Vendedor (lista com scroll contínuo e abas de categorias).
- **Coluna Direita:** Inventário do Jogador (bolsas organizadas, filtro de lixo/cinzas e itens equipáveis).
- **Painel Inferior (`DetailCard`):** Dados detalhados do item focado, comparação com o equipamento atual e atalhos rápidos do controle com ícones gráficos oficiais (`[A]`, `[X]`, `[Y]`, `[B]`).

---

## 2. Diagramas de Design Visual (ASCII Art)

### 2.1. Tela Principal (Split-View: Loja do NPC & Inventário do Jogador)

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ [LOGO] COMÉRCIO & REPAROS                                            (X) 14g 52s 10c  •  [B] SAIR│
│ NPC: |cffe09a15Barkeep Daby|r  <Taverneiro & Vendedor de Suprimentos>                             │
├──────────────────────────────────────────────────┬───────────────────────────────────────────────┤
│ [LB] LOJA DO VENDEDOR (18 itens)                 │ [RB] SEU INVENTÁRIO (46/60 slots)             │
│ Sub-Abas: [LT] [Todos] [Equip] [Cons] [Buyback]  │ Sub-Abas: [LT] [Todos] [Equip] [Cons] [Lixo]  │
├──────────────────────────────────────────────────┼───────────────────────────────────────────────┤
│                                                  │                                               │
│  ► [Íc] [x5] Poção de Vida Maior         15s 00c │    [Íc] Espada Quebrada (Cinza)         1s 20c│
│    [Íc] [x20] Pão Doce de Centeio         2s 40c │    [Íc] Presa Lascada (Cinza)             45c│
│    [Íc] Arco Curto de Bordo              85s 00c │  * [Íc] [x4] Elixir de Agilidade       12s 00c│
│    [Íc] Receita: Óleo de Fogo [1 rest.]  25s 00c │    [Íc] [x20] Couro Pesado             24s 50c│
│    [Íc] Flecha de Ponta Fina (x200)       4s 00c │    [Íc] Túnica de Seda Rúnica           2g 10s│
│    [Íc] Cantil de Água Fresca             1s 20c │    [Íc] Botas de Couro Gasto           18s 00c│
│    [Íc] Bandagem de Seda Pesada           8s 50c │    [Íc] Minério de Ferro (x14)         15s 20c│
│    ... (Scroll contínuo com D-Pad Cima/Baixo)    │    ... (Scroll contínuo com D-Pad Cima/Baixo) │
│                                                  │                                               │
├──────────────────────────────────────────────────┴───────────────────────────────────────────────┤
│ DETAIL CARD (Zelda / Console RPG Style - Base Fixa):                                             │
│ ┌───────┐  |cff1eff00Poção de Vida Maior|r                              Preço por Unidade:  3s 00c│
│ │       │  Consumível • Nível Requerido: 35                     Preço do Pacote (x5): 15s 00c│
│ │ [ÍCONE]│  ─────────────────────────────────────────────────────────────────────────────────  │
│ │       │  "Restaura 450 a 580 de vida instantaneamente ao ser consumida."                       │
│ └───────┘  • Tempo de recarga: 2 min  •  Máximo empilhável: 20 unidades                         │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ BARRA DE AÇÕES & STATUS DO CONTROLE (Glifos Gráficos Oficiais):                                  │
│ [A] Comprar 1x  •  [X] Comprar Quantidade...  •  [Y] Reparar Tudo (84s 20c)  •  [B] Fechar Loja │
│ [R3] Vender Lixos Cinzas (Auto-Sell)  •  [LB]/[RB] Alternar Colunas  •  [LT]/[RT] Filtros        │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2. DetailCard com Comparação em Tempo Real (`ItemCompare`)

```
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ DETAIL CARD COM COMPARAÇÃO:                                                                      │
│ ┌───────┐  |cff0070ddCota de Malha do Gladiador|r    │ COMPARANDO COM SEU EQUIPAMENTO ATUAL:     │
│ │       │  Peitoral (Malha) • 280 Armadura           │ Cota de Malha Desgastada (210 Armadura)   │
│ │ [ÍCONE]│  +12 Força                                │ +8 Força                                  │
│ │       │  +8 Agilidade                              │ +6 Vigor                                  │
│ └───────┘  +14 Vigor                                 │                                           │
│ ─────────────────────────────────────────────────────┴────────────────────────────────────────── │
│ DIFERENÇAS: |cff1eff00+70 Armadura|r  •  |cff1eff00+4 Força|r  •  |cff1eff00+8 Agilidade|r  •  |cff1eff00+8 Vigor|r         │
│ Preço de Compra: 3 Ouro, 40 Prata | Seu Saldo: 14 Ouro, 52 Prata, 10 Cobre                       │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3. Modal Popup de Quantidade (para Stacks de Comida, Água, Flechas)

```
                         ┌───────────────────────────────────────────────┐
                         │   COMPRAR EM QUANTIDADE: Poção de Vida Maior  │
                         ├───────────────────────────────────────────────┤
                         │                                               │
                         │          <   [ 10 ] UNIDADES   >              │
                         │                                               │
                         │   [Min: 1]   [Pilha: 5]   [10]   [Máx: 20]   │
                         │                                               │
                         │   Custo Total: |cffffffff30s 00c|r            │
                         │   Saldo Restante: |cffffffff14g 22s 10c|r     │
                         │                                               │
                         ├───────────────────────────────────────────────┤
                         │   [D-Pad < / >] Ajustar Quantidade            │
                         │   [A] Confirmar Compra   •   [B] Cancelar     │
                         └───────────────────────────────────────────────┘
```

---

## 3. Legendas de Controle & Texturas Gráficas Oficiais

O rodapé do menu e as dicas visuais utilizarão diretamente as texturas embutidas em `CFG.Icons` (`Interface\AddOns\ConsoleModeVanilla\Media\Icons\Xbox\`):

| Ação | Glifo / Textura | Arquivo de Textura |
| :--- | :--- | :--- |
| **Comprar / Usar** | `[A]` | `Media\Icons\Xbox\A.tga` |
| **Voltar / Fechar** | `[B]` | `Media\Icons\Xbox\B.tga` |
| **Vender / Quantidade** | `[X]` | `Media\Icons\Xbox\X.tga` |
| **Reparar Tudo** | `[Y]` | `Media\Icons\Xbox\Y.tga` |
| **Focar Loja do NPC** | `[LB]` | `Media\Icons\Xbox\LB.tga` |
| **Focar Inventário** | `[RB]` | `Media\Icons\Xbox\RB.tga` |
| **Filtro Anterior** | `[LT]` | `Media\Icons\Xbox\LT.tga` |
| **Próximo Filtro** | `[RT]` | `Media\Icons\Xbox\RT.tga` |
| **Navegar Itens** | `[D-Pad]` | `Media\Icons\Xbox\navigate_all_directions.tga` |
| **Vender Todo o Lixo** | `[R3]` | `Media\Icons\Xbox\RS.tga` |

---

## 4. Cronograma de Fases TESTÁVEIS Passo a Passo

Cada fase foi estruturada para ser **100% testável no jogo imediatamente após a sua conclusão**. Nenhuma fase avança sem validação e feedback do usuário.

---

### 🟢 FASE 1: Detecção e Interceptação do Mercador
> **Objetivo de Teste:** O jogador clica em qualquer NPC vendedor e vê que o addon interceptou a ação com sucesso, suprimiu a janela velha da Blizzard e exibiu os dados do NPC no chat.

- [ ] Criar arquivo modular isolado `UI/MerchantMenu.lua`.
- [ ] Registrar `UI/MerchantMenu.lua` no `ConsoleModeVanilla.toc`.
- [ ] Criar frame de eventos ouvindo `MERCHANT_SHOW` e `MERCHANT_CLOSED`.
- [ ] Suprimir o `MerchantFrame` nativo com segurança (ocultar e mover off-screen).
- [ ] Extrair metadados da interação: nome do NPC (`UnitName("npc")`), se o NPC repara (`CanMerchantRepair()`) e total de itens à venda (`GetMerchantNumItems()`).
- [ ] Exibir mensagem limpa de confirmação: `[ConsoleMode] Interação com Mercador detectada: <Nome do NPC> (<X> itens, Reparo: Sim/Não)`.
- [ ] Garantir fechamento limpo via evento `MERCHANT_CLOSED` ou ao afastar-se do NPC.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 1):** O jogador recarrega a UI (`/reload`), clica em um mercador no jogo e valida se a janela velha da Blizzard sumiu e a detecção apareceu perfeitamente.

---

### 🟢 FASE 2: Esqueleto Visual da Interface (Canvas Split-View)
> **Objetivo de Teste:** O jogador interage com o mercador e vê o esqueleto visual completo da nova interface abrir no lugar da janela da Blizzard: as duas colunas, o cabeçalho nobre, o DetailCard e o rodapé com as texturas de botões.

- [ ] Construir a janela principal responsiva com proporções do ConsoleMode (largura ~92%, altura ~84% da tela).
- [ ] Montar o Cabeçalho: título do menu, nome do NPC em dourado (`|cffe09a15`), status de reparo e saldo de moedas do jogador.
- [ ] Criar a estrutura das duas colunas:
  - Coluna Esquerda: painel do Vendedor com moldura, sub-abas e placeholder.
  - Coluna Direita: painel do Inventário com moldura, sub-abas e placeholder.
- [ ] Construir a base fixa do `DetailCard` (estilo Zelda) com campos de ícone grande, título, subtítulo e descrição.
- [ ] Montar a barra de rodapé exibindo as texturas gráficas oficiais dos botões (`A.tga`, `B.tga`, `X.tga`, `Y.tga`, `LB.tga`, `RB.tga`, `LT.tga`, `RT.tga`).
- [ ] Vincular o botão `[B]` / tecla `ESC` para fechar a interface chamando `CloseMerchant()`.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 2):** O jogador interage com o NPC e visualiza a moldura visual completa e limpa do ConsoleMode na tela do jogo.

---

### 🟢 FASE 3: Inventário do Jogador Funcional (Coluna Direita)
> **Objetivo de Teste:** O jogador abre a janela e vê todos os itens das suas bolsas listados na coluna direita com ícones, cores de raridade, quantidades e preços de venda, podendo navegar com o D-Pad.

- [ ] Implementar o scanner de bolsas (slots `0` a `4`), lendo ícones, links, quantidades e durabilidades.
- [ ] Implementar o extrator de preço de venda via tooltip scanning (`SetBagItem(bag, slot)`).
- [ ] Construir as linhas de itens na coluna direita (ícone, nome colorido por raridade, quantidade, preço de venda em moedas).
- [ ] Implementar scroll contínuo e navegação vertical via D-Pad/Analógico na coluna do inventário.
- [ ] Conectar o evento `BAG_UPDATE` para que qualquer alteração nas bolsas atualize a coluna instantaneamente.
- [ ] Conectar o item focado ao `DetailCard` inferior, exibindo seu tooltip completo ao navegar.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 3):** O jogador abre a loja e navega fluidamente pelo seu próprio inventário na coluna da direita.

---

### 🟢 FASE 4: Estoque do Mercador Funcional (Coluna Esquerda)
> **Objetivo de Teste:** O jogador vê todo o catálogo de itens do NPC na coluna da esquerda com preços de compra, estoques limitados e sub-abas de filtro funcionais.

- [ ] Implementar leitura do catálogo do vendedor via `GetMerchantNumItems()` e `GetMerchantItemInfo(index)`.
- [ ] Construir as linhas de itens da loja (ícone, nome colorido, preço de compra, aviso de quantidade restante em receitas).
- [ ] Implementar scroll contínuo para acomodar catálogos grandes sem paginação arcaica de 10 em 10 itens.
- [ ] Implementar sub-abas de filtro de catálogo (`Todos`, `Equipamentos`, `Consumíveis`).
- [ ] Conectar o item selecionado da loja ao `DetailCard` para visualização dos seus atributos.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 4):** O jogador navega pelos itens vendidos pelo NPC na coluna da esquerda e filtra por categorias.

---

### 🟢 FASE 5: Integração das Ações e Botões do Controle (Comprar, Vender e Reparar)
> **Objetivo de Teste:** O jogador consegue alternar entre colunas com `[LB]`/`[RB]`, comprar itens com `[A]`, vender itens da bolsa com `[X]`, e consertar os equipamentos com `[Y]`.

- [ ] Implementar alternância fluida de foco entre a Coluna do Vendedor e a Coluna do Inventário via `[LB]` e `[RB]`.
- [ ] Implementar ação de **Compra**: pressionar `[A]` na coluna do vendedor executa `BuyMerchantItem(index, 1)` com som nativo de compra.
- [ ] Implementar ação de **Venda**: pressionar `[X]` ou `[A]` na coluna do inventário executa `UseContainerItem(bag, slot)` para vender o item selecionado ao NPC.
- [ ] Implementar ação de **Reparo**: se o NPC for reparador (`CanMerchantRepair()`), pressionar `[Y]` executa `RepairAllItems()`, toca som e atualiza o saldo e durabilidades.
- [ ] Conectar o evento `PLAYER_MONEY` para atualizar os valores de ouro/prata/cobre em tempo real na tela após cada operação.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 5):** O jogador compra, vende e repara itens usando exclusivamente os botões do controle.

---

### 🟢 FASE 6: Modal de Quantidade, Auto-Sell de Lixo, ItemCompare e Polimento
> **Objetivo de Teste:** O jogador compra pilhas de itens com o modal de quantidade, vende todos os lixos cinzas com um único clique (`[R3]`), compara armaduras em tempo real e acessa a recompra (Buyback).

- [ ] Implementar modal de compra de quantidade ao pressionar `[X]` na loja para itens stackáveis (ajuste com D-Pad `< / >`, cálculo de custo total e confirmação com `[A]`).
- [ ] Implementar recurso de **Auto-Sell Junk** via `[R3]`: varre e vende todos os itens cinzas automaticamente exibindo o ouro ganho.
- [ ] Integrar comparação de itens em tempo real no `DetailCard`: ao focar em armas/armaduras, compara lado a lado com o equipamento atualmente vestido no slot correspondente (`ItemCompare`).
- [ ] Implementar sub-aba de **Recompra (Buyback)** na coluna do vendedor usando `GetNumBuybackItems()` e `BuybackItem(index)` para desfazer vendas acidentais.
- [ ] Polimento de efeitos sonoros, foco dourado animado e transições suaves.
- [ ] Validação de sintaxe final via `luac -p` e checagem de regressão geral.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 6):** Teste geral completo em múltiplos NPCs de comércio e reparo.

---

## 5. Estrutura de Arquivos

```
Interface/AddOns/ConsoleModeVanilla/
├── ConsoleModeVanilla.toc          <-- Adiciona UI/MerchantMenu.lua
├── UI/
│   ├── MerchantMenu.lua            <-- NOVO MÓDULO INDEPENDENTE (Loja, Inventário, DetailCard, Ações)
│   ├── MainMenu.lua                <-- Intocado (preservando o monólito existente sem novos inchaços)
│   └── ...
├── Hooks.lua                       <-- Interceptação complementar de frames nativos
└── docs/
    └── plano_de_feature_MENU_DE_NPC_E_VENDEDORES.md <-- Este documento
```
