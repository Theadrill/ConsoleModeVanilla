# Plano de Feature: MENU DE NPC, VENDEDORES & INVENTÁRIO SPLIT-VIEW (ConsoleMode)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido terminantemente o uso de operadores de Lua 5.1+ (como operador de tamanho `#table`, usar `table.getn(t)` ou `getn(t)`), `continue` ou `goto`.
> 3. **Identidade Visual Rigorosa do CONSOLEMODE (Abandono Total da UI Clássica da Blizzard):**
>    - **ABANDONO TOTAL DO VISUAL ARCAICO:** É terminantemente proibido renderizar a janela clássica `MerchantFrame` de 2004 da Blizzard. Toda a interação mercantil deve ocorrer na interface nativa do ConsoleMode.
>    - **Design System Harmonizado:**
>      - **Tipografia Nobre:** Fontes aplicadas exclusivamente via `ApplyFont()` utilizando `titleFontFile` e `headerFontFile` (`AlegreyaSans-Bold.ttf` com o mod de -9% de kerning), `bodyFontFile` (`AlegreyaSans-Bold.ttf`) e `subFontFile` (`AlegreyaSans-Medium.ttf`).
>      - **Paleta de Cores Oficial:** Dourado âmbar nobre (`|cffe09a15`), cinza suave para inativos (`|cffaaaaaa`), texto branco puro (`|cffffffff`), verde para cura/compra (`|cff1eff00`) e vermelho para erros/custos indisponíveis (`|cffff2020`).
>      - **Backdrops Customizados:** Fundos escurecidos translúcidos com alpha 0.40-0.85 (`Interface\Tooltips\UI-Tooltip-Background`), bordas finas com corte refinado (`Interface\Tooltips\UI-Tooltip-Border`) e cantos com insets padronizados de 2-3px.
>      - **Controles de Console e Glifos:** Tags visuais com ícones das texturas oficiais do controle (`[A]`, `[B]`, `[X]`, `[Y]`, `[LT]`, `[RT]`, `[LB]`, `[RB]`).
>      - **DetailCard Estilo RPG Console:** Painel inferior fixo de detalhes, comparação em tempo real com itens equipados e valores financeiros.
> 4. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 5. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem autorização explícita do usuário.
> 6. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem validação no jogo via `/reload` e aprovação do usuário.

---

## 1. Visão Geral

Atualmente, ao interagir com um NPC vendedor ou reparador no WoW 1.12, o jogo abre a clássica janela nativa `MerchantFrame` de 2004. No controle (especialmente no Steam Deck), essa janela apresenta diversas fricções:
- Exibe apenas 10 itens por página com botões pequenos.
- Exige movimentação de cursor virtual do mouse para inspecionar, comprar e vender.
- Abre as bolsas padrão da Blizzard de forma desconexa ou desalinhada, ocupando a tela de maneira desorganizada.
- Não oferece comparação direta entre os itens vendidos pelo NPC e os que o jogador já está vestindo.

A proposta desta feature é **interceptar a interação com NPCs comerciantes** e renderizar uma janela customizada completa em **Split-View (tela dividida)** no mesmo padrão estético e de usabilidade do Main Menu do ConsoleMode:
- **Coluna Esquerda:** Estoque do NPC Vendedor (lista ou grade com scroll contínuo e abas de categorias).
- **Coluna Direita:** Inventário do Jogador (bolsas organizadas, filtro de lixo/cinzas e itens equipáveis).
- **Painel Inferior (`DetailCard`):** Dados detalhados do item focado, comparação com o equipamento atual e atalhos rápidos do controle (`[A]` Comprar, `[X]` Vender, `[Y]` Reparar Tudo).

---

## 2. Arquitetura de Telas & Fluxo de Interação

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   NPC VENDEDOR & INVENTÁRIO (CONSOLEMODE)                        │
├────────────────────────────────────────┬─────────────────────────────────────────┤
│ [LB] LOJA DO NPC: [Nome do NPC]        │ [RB] SEU INVENTÁRIO (48/60)             │
│ Sub-Abas: [LT] Todos | Equip | Cons [RT]│ Sub-Abas: [LT] Todos | Lixo | Cons [RT]  │
├────────────────────────────────────────┼─────────────────────────────────────────┤
│                                        │                                         │
│  ► [Íc] Poção de Mana Maior    12s 50c │    [Íc] Espada Quebrada (Lixo)    1s 20c│
│    [Íc] Pão de Centeio           1s 10c│  ► [Íc] Elixir de Agilidade (x5) 15s 00c│
│    [Íc] Flecha Pesada (x200)     4s 00c│    [Íc] Couro Médio (x20)        12s 40c│
│    [Íc] Arco Curto de Bordo     85s 00c│    [Íc] Botas de Malha Gastas     4s 80c│
│    ... (Scroll contínuo suave)         │    ... (Scroll contínuo suave)          │
│                                        │                                         │
├────────────────────────────────────────┴─────────────────────────────────────────┤
│ DETAIL CARD (Painel Inferior Fixo estilo Zelda / Console RPG)                    │
│ [Ícone] Elixir de Agilidade (Consumível)                                         │
│ Aumenta a Agilidade em 15 pontos por 1 hora.                                     │
│ Preço de Venda: 15 Prata | Dinheiro Atual: 4 Ouro, 12 Prata, 80 Cobre            │
├──────────────────────────────────────────────────────────────────────────────────┤
│ BARRA DE AÇÕES DO CONTROLE:                                                      │
│ [A] Comprar/Usar  •  [X] Vender Item  •  [Y] Reparar Tudo (84s)  •  [B] Fechar   │
│ [R3] Vender Todo o Lixo Cinza  •  [LB]/[RB] Alternar Coluna  •  [LT]/[RT] Filtros │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### 2.1. Navegação por Controle
- **`[LB]` / `[RB]`:** Alterna o foco ativo entre a **Coluna da Loja** e a **Coluna do Inventário**.
- **`D-Pad Cima / Baixo`:** Navega verticalmente pelos itens da coluna ativa.
- **`D-Pad Esquerda / Direita`:** Alterna páginas ou sub-abas de filtro (`[LT]` / `[RT]`).
- **`[A]`:**
  - Na Loja: Compra 1 unidade do item selecionado (ou abre popup de quantidade se for stackável).
  - No Inventário: Vende o item focado para o NPC.
- **`[X]`:**
  - Na Loja: Abre seletor de quantidade de compra direta (`1`, `5`, `10`, `Máximo`).
  - No Inventário: Venda rápida imediata sem confirmação.
- **`[Y]`:** Se o NPC for reparador (`CanMerchantRepair()`), repara todos os equipamentos com confirmação de custo.
- **`[R3] (Aperto do Analógico Direito)`:** Vende automaticamente todos os itens de qualidade cinza (lixo) da bolsa com sumário de ouro ganho.
- **`[B]` ou `ESC`:** Fecha a loja chamando `CloseMerchant()`.

---

## 3. Especificação Técnica dos Módulos

### 3.1. Interceptação de Eventos (`MerchantFrame Hook`)
1. **`MERCHANT_SHOW`:**
   - Oculta imediatamente o `MerchantFrame` nativo:
     ```lua
     MerchantFrame:Hide()
     MerchantFrame:ClearAllPoints()
     MerchantFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 500) -- Off-screen seguro
     ```
   - Dispara a abertura da janela customizada do ConsoleMode: `ConsoleMode_MerchantUI:Open()`.
   - Lê as informações do NPC via `UnitName("npc")` e determina se o NPC repara (`CanMerchantRepair()`).
2. **`MERCHANT_CLOSED`:**
   - Fecha suavemente a janela customizada e reseta cursores de foco.
3. **`MERCHANT_UPDATE`:**
   - Atualiza estoque de itens de quantidade limitada (ex: receitas que esgotam).
4. **`BAG_UPDATE`:**
   - Re-escaneia as bolsas do jogador para atualizar a coluna do inventário em tempo real após cada compra ou venda.
5. **`PLAYER_MONEY`:**
   - Atualiza os widgets de moedas (ouro, prata, cobre) no rodapé da janela.

---

### 3.2. Coluna Esquerda: Estoque do Vendedor

#### Leitura de Dados (API WoW 1.12):
```lua
local numItems = GetMerchantNumItems()
for i = 1, numItems do
    local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(i)
    local link = GetMerchantItemLink(i)
    local maxStack = GetMerchantItemMaxStack(i)
    -- Armazenamento no cache local de exibição
end
```

#### Abas de Filtragem do Vendedor:
- **Todos:** Exibe todos os itens à venda.
- **Equipamentos:** Armas, escudos e armaduras.
- **Consumíveis:** Comidas, bebidas, poções, elixires, reagentes e flechas/munição.
- **Recompra (Buyback):** Itens vendidos recentemente pelo jogador nesta sessão, acessíveis via `GetNumBuybackItems()` e `BuybackItem(index)`.

#### Lista com Scroll Contínuo:
- Em vez de travar em 10 itens por página como a Blizzard fazia, a lista acomoda todos os itens em um `ScrollFrame` nobre com rolagem suave automática acompanhando o cursor do D-Pad.

---

### 3.3. Coluna Direita: Inventário do Jogador

#### Reutilização da Mecânica de Bolsas do ConsoleMode:
- Varre as 5 bolsas (`0` a `4`) usando `GetContainerNumSlots(bag)` e `GetContainerItemInfo(bag, slot)`.
- Extrai preço de venda através de tooltip scanning com `SetBagItem(bag, slot)`.
- **Filtros rápidos:**
  - **Todos:** Todos os itens do inventário.
  - **Lixo (Cinzas):** Apenas itens vendáveis de qualidade 0 (`|cff9d9d9d`).
  - **Equipamentos:** Armas e armaduras no inventário.
  - **Consumíveis:** Itens de consumo geral.

#### Execução de Venda:
```lua
-- No WoW 1.12, enquanto a sessão do mercador estiver aberta:
UseContainerItem(bagID, slotID)
```
Essa chamada nativa efetua a venda imediata do item e credita as moedas.

---

### 3.4. Sistema de Reparo (`Repair Widget`)
- Se `CanMerchantRepair()` retornar `true`:
  - Um widget de reparo em destaque âmbar é exibido no topo ou rodapé.
  - `GetRepairAllCost()` informa o custo em cobre e se o jogador tem itens para reparar.
  - Ao pressionar `[Y]`:
    - Verifica se o jogador possui ouro suficiente.
    - Executa `RepairAllItems()`.
    - Toca som de reparo (`PlaySound("ITEM_REPAIR")`) e exibe mensagem flutuante de sucesso.

---

### 3.5. Sistema de Venda Automática de Lixo ("Junk Auto-Sell")
- Ao pressionar `[R3]` ou clicar no botão dedicado:
  - O addon itera pelos slots das bolsas procurando itens de qualidade cinza vendáveis.
  - Executa a venda em lote respeitando uma cadência de 0.05s (para evitar travamento de pacotes no servidor 1.12).
  - Exibe no chat e no rodapé: *"Vendido [X] itens de lixo por [Y Ouro, Z Prata, W Cobre]"*.

---

### 3.6. Popup Seletor de Quantidade (Modal de Compra de Stacks)
Para compra de itens empilháveis (água, comida, reagentes, projéteis):
- Pressionar `[X]` na Loja abre um modal central translúcido.
- Permite selecionar a quantidade com `D-Pad Esquerda/Direita`:
  - `1`, `5`, `10`, `Pilha Completa (ex: 20)`, ou `Máximo que o dinheiro comporta`.
- Exibe o custo total calculado em tempo real.
- `[A]` Confirma e chama `BuyMerchantItem(itemIndex, count)`.
- `[B]` Cancela o modal.

---

## 4. Fases de Desenvolvimento & Critérios de Parada

### Fase 1: Interceptação e Estrutura Básica do Frame (Split-View Skeleton)
- [ ] Criar arquivo `UI/MerchantMenu.lua`.
- [ ] Implementar interceptação de eventos `MERCHANT_SHOW` e `MERCHANT_CLOSED`.
- [ ] Ocultar com segurança o `MerchantFrame` nativo de 2004.
- [ ] Criar janela principal responsiva com proporções do design system (duas colunas + DetailCard na base).
- [ ] Exibir cabeçalho com nome do NPC (`UnitName("npc")`) e título/função.
- [ ] Validar sintaxe com `luac -p`.
- **PARADA CRÍTICA DE VALIDAÇÃO:** Testar abertura/fechamento ao interagir com um vendor no jogo via `/reload`.

### Fase 2: Carregamento do Estoque do Vendedor (Coluna Esquerda)
- [ ] Implementar varredura da API `GetMerchantNumItems()` e `GetMerchantItemInfo()`.
- [ ] Construir cards de item com ícone, borda de qualidade, nome, quantidade e preço em moedas formatadas.
- [ ] Implementar scroll contínuo e navegação via D-Pad/Analógico.
- [ ] Implementar sub-abas de filtro (`Todos`, `Equipamentos`, `Consumíveis`).
- [ ] Integrar compra direta de 1 unidade via botão `[A]`.
- [ ] Validar sintaxe com `luac -p`.
- **PARADA CRÍTICA DE VALIDAÇÃO:** Testar navegação e compra de itens de teste no vendor.

### Fase 3: Carregamento do Inventário do Jogador (Coluna Direita & Venda)
- [ ] Conectar scanner de bolsas à coluna direita.
- [ ] Exibir preço de venda de cada item obtido via tooltip scanner.
- [ ] Implementar alternância de coluna via `[LB]` / `[RB]`.
- [ ] Implementar venda de item selecionado via botão `[X]` ou `[A]`.
- [ ] Atualizar inventário e moedas automaticamente com os eventos `BAG_UPDATE` e `PLAYER_MONEY`.
- [ ] Validar sintaxe com `luac -p`.
- **PARADA CRÍTICA DE VALIDAÇÃO:** Testar venda de itens e sincronização de saldo.

### Fase 4: Painel de Detalhes (`DetailCard`), Comparação & Recompra
- [ ] Exibir no `DetailCard` inferior os dados completos do item focado (seja do vendor ou da bolsa).
- [ ] Conectar comparador de itens (`ItemCompare` / stats contra o item vestido).
- [ ] Construir aba de **Recompra (Buyback)** listando itens recuperáveis via `GetBuybackItemInfo()`.
- [ ] Validar sintaxe com `luac -p`.
- **PARADA CRÍTICA DE VALIDAÇÃO:** Testar comparação de armaduras e recompra de itens vendidos.

### Fase 5: Sistema de Reparo & Venda Rápida de Lixo (Junk Auto-Sell)
- [ ] Implementar detecção de reparo com `CanMerchantRepair()` e `GetRepairAllCost()`.
- [ ] Criar botão e atalho `[Y]` para reparo completo com feedback sonoro.
- [ ] Implementar rotina de venda automática de lixo cinza via `[R3]` / botão com sumário de lucro.
- [ ] Validar sintaxe com `luac -p`.
- **PARADA CRÍTICA DE VALIDAÇÃO:** Testar reparo de itens e venda de lixo em vendors de equipamento.

### Fase 6: Modal de Quantidade, Polimento Visual & Atalhos Finais
- [ ] Implementar modal de compra de múltiplas unidades com slider/D-Pad.
- [ ] Polir sombras, contornos de foco dourado, animações suaves e glifos do controle.
- [ ] Suporte robusto ao cancelamento por distância (se o jogador andar para longe do NPC).
- [ ] Validação final completa de sintaxe e regressão de todos os outros menus do addon.
- **PARADA CRÍTICA DE VALIDAÇÃO:** Teste geral de estresse em múltiplos tipos de vendedores (comida, reagentes, armaduras, armas).

---

## 5. Arquitetura de Arquivos

- `UI/MerchantMenu.lua`: Módulo principal contendo a interface, eventos e renderização do menu de NPC.
- `Hooks.lua`: Registro de interceptação e supressão de frames nativos (`MerchantFrame`).
- `ConsoleModeVanilla.toc`: Adição do novo módulo `UI/MerchantMenu.lua` na sequência correta de carregamento.
