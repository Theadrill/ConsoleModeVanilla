# Plano de Feature: COR DE BORDA POR TIPO ESPECIAL DE BAG (MerchantMenu)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido terminantemente o uso de operadores de Lua 5.1+ (como operador de tamanho `#table`, usar `table.getn(t)` ou `getn(t)`), `continue` ou `goto`.
> 3. **Arquitetura Modular Isolada (Fim do Monólito):**
>    - Esta feature **NÃO DEVE** ser colocada dentro de `MainMenu.lua`.
>    - Toda a implementação vive no módulo independente `UI/MerchantMenu.lua`.
> 4. **Identidade Visual Rigorosa do CONSOLEMODE:**
>    - **Tipografia Nobre:** Fontes aplicadas exclusivamente via `ApplyFont()`.
>    - **Paleta de Cores Oficial:** Dourado âmbar nobre (`|cffe09a15`), cinza suave para inativos (`|cffaaaaaa`), texto branco puro (`|cffffffff`), verde (`|cff1eff00`) e vermelho para erros (`|cffff2020`).
>    - **Backdrops Customizados:** Fundos escurecidos translúcidos (`Interface\Tooltips\UI-Tooltip-Background`), bordas finas (`Interface\Tooltips\UI-Tooltip-Border`), insets 2-3px.
>    - **Hierarquia de foco intocável:** Dourado puro (`1.00, 0.82, 0.20, 1.00`) é reservado EXCLUSIVAMENTE para a row selecionada. Nenhuma cor de bag pode roubar o foco.
> 5. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 6. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem autorização explícita do usuário. Cada fase = no máximo 1 commit, somente após validação.
> 7. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem validação no jogo via `/reload` e aprovação do usuário.

---

## 1. Visão Geral

Hoje a coluna "SEU INVENTÁRIO" do `MerchantMenu` trata as 5 bags (backpack + 4 equipadas) de forma idêntica: toda row não-selecionada usa borda bronze escura (`0.35, 0.28, 0.20, 0.40`), e a selecionada usa dourado puro. Não há nenhuma distinção visual entre um item guardado numa mochila normal e um item guardado numa bag especial (Aljava, Bolsa de Almas, Bolsa de Ervas, etc.).

A proposta é **colorir a borda da row conforme o tipo especial da bag-container onde o item está**, com cores temáticas que harmonizam com a paleta quente (marrom/âmbar/bronze) do addon:

- A detecção usa `GetContainerNumFreeSlots(bagID)`, cujo 2º retorno (`bagType`) é uma bitmask oficial do 1.12.
- Tipos custom do Turtle WoW sem bitmask própria (`Gem Bag`, `Meat Bag`, `Fish Bag` — ver print de referência) são detectados por fallback de substring no nome da bag via `GetBagName(bagID)`.
- Bag normal (`bagType == 0` e sem match de nome) mantém o bronze default atual — zero mudança visual para quem não usa bags especiais.

Tipos cobertos (conforme print de referência do usuário):

| Tipo | Origem da detecção |
| :--- | :--- |
| Bag (normal) | `bagType == 0`, sem match de nome → visual atual inalterado |
| Quiver (Aljava) | bitmask `1` |
| Ammo Pouch (Munição) | bitmask `2` |
| Soul Bag (Almas) | bitmask `4` |
| Leatherworking Bag | bitmask `8` |
| Herb Bag | bitmask `32` |
| Enchanting Bag | bitmask `64` |
| Engineering Bag | bitmask `128` |
| Mining Bag | bitmask `512` |
| Gem Bag | fallback por nome (`GetBagName` contém "Gem") — custom Turtle |
| Meat Bag | fallback por nome (contém "Meat") — custom Turtle |
| Fish Bag | fallback por nome (contém "Fish") — custom Turtle |

---

## 2. Diagramas de Design Visual (ASCII Art)

### 2.1. Coluna do inventário com bordas por tipo (rows NÃO selecionadas)

```
│ [RB] SEU INVENTÁRIO (46/60 slots)             │
│ Sub-Abas: [LT] [Todos] [Equip] [Cons] [Lixo]  │
├───────────────────────────────────────────────┤
│                                               │
│  ┌ bronze ──────────────────────────────┐     │
│  │ [Íc] Espada Quebrada (Cinza)   1s 20c│     │  ← Bag normal: bronze default atual
│  └──────────────────────────────────────┘     │
│  ┌ verde-ervas ─────────────────────────┐     │
│  │ [Íc] [x20] Erva Prateada       4s 00c│     │  ← Herb Bag: borda verde
│  └──────────────────────────────────────┘     │
│  ┌ roxo-alma ───────────────────────────┐     │
│  │ [Íc] Soul Shard                  sem │     │  ← Soul Bag: borda roxa
│  └──────────────────────────────────────┘     │
│ ►┌ DOURADO (selecionada) ───────────────┐     │
│  │ [Íc] [x200] Flecha de Ponta    4s 00c│     │  ← Selecionada: SEMPRE dourado puro
│  └──────────────────────────────────────┘     │     (cor da bag NÃO aparece aqui)
│    ... (Scroll contínuo com D-Pad Cima/Baixo) │
```

### 2.2. DetailCard com tag da bag de origem

```
│ DETAIL CARD:                                      │
│ ┌───────┐  |cff1eff00Erva Prateada|r               │
│ │ [ÍCONE]│  Consumível • Reagente                  │
│ └───────┘  |cff33cc33[Bolsa de Ervas]|r • Herb Bag │
```

---

## 3. Tabela de Cores Proposta (`BAG_TYPE_COLORS`)

Todas com alpha `0.85` na borda (mesmo alpha do `iconBorder` de qualidade), harmonizando com o bronze/dourado existente:

| Chave | Tipo | R | G | B | Hex aprox. | Motivo |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `NORMAL` | Bag genérica | 0.35 | 0.28 | 0.20 | `#594733` | Bronze default atual (inalterado) |
| `QUIVER` | Aljava | 0.85 | 0.55 | 0.10 | `#D98C1A` | Madeira/couro de aljava |
| `AMMO` | Bolsa de Munição | 0.55 | 0.55 | 0.65 | `#8C8CA6` | Metal de projétil |
| `SOUL` | Bolsa de Almas | 0.55 | 0.20 | 0.80 | `#8C33CC` | Lore warlock/soul shard |
| `LEATHER` | Couraria | 0.65 | 0.40 | 0.20 | `#A66633` | Couro curtido |
| `HERB` | Ervas | 0.20 | 0.70 | 0.20 | `#33B333` | Natureza/herbalism |
| `ENCHANT` | Encantamento | 0.20 | 0.55 | 0.90 | `#338CE6` | Azul arcano |
| `ENGINEER` | Engenharia | 0.75 | 0.45 | 0.15 | `#BF7326` | Cobre/engrenagem |
| `MINING` | Mineração | 0.60 | 0.35 | 0.10 | `#99591A` | Minério/ferrugem |
| `GEM` | Gemas (Turtle) | 0.20 | 0.80 | 0.80 | `#33CCCC` | Ciano de gema lapidada |
| `MEAT` | Carne (Turtle) | 0.80 | 0.25 | 0.20 | `#CC4033` | Vermelho carne |
| `FISH` | Peixe (Turtle) | 0.20 | 0.50 | 0.75 | `#3380BF` | Azul água |

> NOTA: valores finais sujeitos a ajuste do usuário após ver no jogo (Fase 2).

---

## 4. Cronograma de Fases TESTÁVEIS Passo a Passo

Cada fase foi estruturada para ser **100% testável no jogo imediatamente após a sua conclusão** e gera **no máximo 1 commit**, somente com autorização. **Nenhuma mudança visual ocorre nas Fases 1-2** (só diagnóstico via chat) — o visual entra nas Fases 3-4.

---

### 🟢 FASE 1: Identificação das bags do usuário (sem mudança visual)
> **Objetivo de Teste:** O jogador abre o merchant e vê no chat a lista exata das suas bags detectadas (nome + tipo), provando que a detecção funciona antes de qualquer mudança visual.

- [ ] Em `ScanPlayerBags`, cachear por `bagID` (0–4): `local _, bType = GetContainerNumFreeSlots(bag)` + `GetBagName(bag)` com `pcall` de proteção (APIs podem não existir em todo client).
- [ ] Implementar `ResolveBagKind(bagID, bagType, bagName)`: primeiro bitmask oficial (`1/2/4/8/32/64/128/512`), depois fallback por substring no nome (`"Gem"`, `"Meat"`, `"Fish"`, `"Herb"`, `"Soul"`, `"Enchant"`, `"Engineer"`, `"Mining"`, `"Leather"`, `"Quiver"`, `"Ammo"`, `"Pouch"`), senão `"NORMAL"`.
- [ ] Adicionar campos `bagKind` e `bagName` ao retorno de `ParseBagItem` (via cache passado por parâmetro, sem quebrar a assinatura atual).
- [ ] Ao abrir o merchant (`Open`), imprimir no chat uma linha por bag: `[ConsoleMode] Bag <id>: "<nome>" → <KIND> (type=<n>)`.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 1):** O jogador dá `/reload`, abre qualquer vendedor com bags especiais equipadas e confirma no chat que cada bag foi identificada com o KIND correto. **Sem esta confirmação, as cores da Fase 2 não fazem sentido.** Commit somente após aprovação.

---

### 🟢 FASE 2: Tabela de cores + helper de resolução (sem mudança visual)
> **Objetivo de Teste:** O jogador abre o merchant e vê no chat a cor resolvida para cada bag, podendo pedir ajuste de qualquer cor antes de ela aparecer na tela.

- [ ] Criar constante `BAG_TYPE_COLORS` (tabela da Seção 3) no topo de `UI/MerchantMenu.lua`, próxima a `QUALITY_COLORS`.
- [ ] Implementar `MerchantMenu:GetBagBorderColor(bagKind)` → retorna `r, g, b` (fallback para bronze default se KIND desconhecido; aceita `nil` com segurança).
- [ ] Estender o log de `Open` da Fase 1 com a cor: `[ConsoleMode] Bag <id>: "<nome>" → <KIND> (r,g,b)`.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 2):** O jogador dá `/reload`, confere as cores listadas no chat e aprova ou pede troca de qualquer cor da tabela. Nenhum pixel muda nesta fase. Commit somente após aprovação.

---

### 🟢 FASE 3: Borda colorida nas rows não-selecionadas
> **Objetivo de Teste:** O jogador vê as bordas das rows do inventário coloridas por tipo de bag, com bag normal idêntica a antes.

- [ ] Em `UpdateBagRows`, na branch NÃO-selecionada (atual `L1642`), trocar a cor fixa pela cor de `GetBagBorderColor(item.bagKind)` quando `bagKind ~= "NORMAL"`; bag normal mantém `(0.35, 0.28, 0.20, 0.40)` exatamente como hoje.
- [ ] Em `OnLeave` de `CreateBagRows` (atual `L1080`), restaurar a cor especial da bag em vez do bronze genérico (consultar o item da row via `bagScrollOffset + slotIndex`).
- [ ] Branch SELECIONADA (`L1636`) e `OnEnter` de selecionada: **intocadas** — dourado puro sempre prevalece.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 3):** O jogador dá `/reload`, abre o vendedor, confirma: (a) itens em bags especiais com borda da cor certa; (b) itens em bag normal visualmente idênticos a antes; (c) ao mover a seleção, a row anterior volta à cor da sua bag (não ao bronze genérico). Commit somente após aprovação.

---

### 🟢 FASE 4: Hover, seleção e tag no DetailCard
> **Objetivo de Teste:** Hover e seleção comportam-se corretamente sobre rows coloridas, e o DetailCard mostra de qual bag especial o item veio.

- [ ] `OnEnter` (atual `L1071`): hover sobre row de bag especial usa a cor da bag clareada (mesmo RGB, alpha `0.80` padrão de hover) em vez do marrom-hover genérico; bag normal mantém hover atual.
- [ ] Garantir que ao selecionar uma row colorida, ela fica 100% dourada (foco), e ao desselecionar volta à cor da bag (regressão da Fase 3).
- [ ] Em `ShowItemDetail`, se `item.bagKind ~= "NORMAL"`, anexar tag colorida ao subtítulo: ex. `|cff33b333[Bolsa de Ervas]|r` (cor = mesma da borda, via hex da tabela).
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 4):** O jogador dá `/reload` e valida hover, seleção/desseleção e a tag no DetailCard. Commit somente após aprovação.

---

### 🟢 FASE 5: Regressão geral e polimento Turtle
> **Objetivo de Teste:** Nada do que funcionava quebrou; tipos custom do Turtle (Gem/Meat/Fish) detectados em contas reais.

- [ ] Revisar `FilterBagItems` (abas Todos/Equip/Consum/Lixo), `CycleSubTab` circular, buyback, autosell e `UpdateVendorRows`: nenhum deles pode ter mudado de comportamento (vendor rows NÃO recebem cor de bag).
- [ ] Testar com personagem que tenha quiver/ammo pouch equipados (hunter) e profissões com bags (herb/mining/enchanting) — confirmar KIND e cor.
- [ ] Testar cenário sem nenhuma bag especial: inventário deve estar pixel-idêntico ao comportamento anterior.
- [ ] Validação de sintaxe final via `luac -p` + checagem de regressão geral.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 5):** Teste geral completo. Commit final somente após aprovação.

---

## 5. Estrutura de Arquivos

```
Interface/AddOns/ConsoleModeVanilla/
├── UI/
│   └── MerchantMenu.lua            <-- ÚNICO arquivo alterado (todas as 5 fases)
│       ├── BAG_TYPE_COLORS         <-- NOVO (Fase 2, próximo a QUALITY_COLORS)
│       ├── ResolveBagKind()        <-- NOVO (Fase 1)
│       ├── GetBagBorderColor()     <-- NOVO (Fase 2)
│       ├── ParseBagItem()          <-- +campos bagKind/bagName (Fase 1)
│       ├── ScanPlayerBags()        <-- +cache bagType/bagName (Fase 1)
│       ├── UpdateBagRows()         <-- +borda por bagKind (Fase 3)
│       ├── CreateBagRows()         <-- OnEnter/OnLeave respeitam bagKind (Fases 3-4)
│       └── ShowItemDetail()        <-- +tag da bag de origem (Fase 4)
└── docs/
    └── plano_de_feature_COR_DE_BORDA_POR_TIPO_DE_BAG.md <-- Este documento
```
