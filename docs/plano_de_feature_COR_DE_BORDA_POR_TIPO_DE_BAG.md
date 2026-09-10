# Plano de Feature: ESQUEMA DE CORES POR TIPO ESPECIAL DE BAG (MainMenu — Aba Bags)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido terminantemente o uso de operadores de Lua 5.1+ (como operador de tamanho `#table`, usar `table.getn(t)` ou `getn(t)`), `continue` ou `goto`.
> 3. **Arquitetura / Isolamento:**
>    - Esta feature vive **EXCLUSIVAMENTE** na aba Bags do `UI/MainMenu.lua`. Nada a ver com `UI/MerchantMenu.lua` (não tocar nele).
>    - Dentro do `MainMenu.lua`, tocar SOMENTE: parser/scan (`ParseItemData` ~L3545, `ScanInventory` ~L3695), grid base (`CreateGrid` ~L3297, só para criar o frame da nova borda), página de bags (`SetupBagsPage` ~L3896, `UpdateBagsPage` ~L4165) e tag no DetailCard (`card:ShowItem` ~L2814).
>    - PROIBIDO tocar em Spells, Talents, Quests/Mapa, System/Config, ItemCompare, coluna de equipamentos e paginação além do fill da bags.
> 4. **Identidade Visual Rigorosa do CONSOLEMODE:**
>    - **Tipografia Nobre:** Fontes aplicadas exclusivamente via `ApplyFont()`.
>    - **Paleta de Cores Oficial:** Dourado âmbar nobre (`|cffe09a15`), cinza suave para inativos (`|cffaaaaaa`), texto branco puro (`|cffffffff`), verde (`|cff1eff00`) e vermelho para erros (`|cffff2020`).
>    - **Backdrops Customizados:** `Interface\Tooltips\UI-Tooltip-Background` + `Interface\Tooltips\UI-Tooltip-Border`, mesmos insets do grid.
>    - **Hierarquia de foco intocável (ordem de prevalência):**
>      1. `slot.highlight` dourado (`1.0, 0.85, 0.2, 0.95`) = seleção/hover — SEMPRE por cima, nunca mexer.
>      2. `slot.border` = qualidade do item (`ITEM_QUALITY_COLORS`, alpha `0.95`) — NUNCA sobrepor (um épico numa Herb Bag continua roxo).
>      3. Nova `slot.bagBorder` = tipo da bag (alpha `0.75`, abaixo das duas acima).
> 5. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 6. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem autorização explícita do usuário. Cada fase = no máximo 1 commit, somente após validação.
> 7. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem validação no jogo via `/reload` e aprovação do usuário.

---

## 1. Visão Geral

A aba **Bags** do MainMenu renderiza o inventário como um **grid de slots** (até 80 `Button`s criados por `CreateGrid`, `UI/MainMenu.lua:3297`), preenchidos por `UpdateBagsPage` (`:4165`). Cada slot tem duas camadas de cor hoje:

- `slot.border` (moldura interna, `edgeSize=8`) = **cor de qualidade do item** via `ITEM_QUALITY_COLORS` (fallback cinza `0.8,0.8,0.8`), alpha `0.95` (`:4264`); slot vazio = bronze apagado (`0.45,0.40,0.35,0.30` em `:4270`).
- `slot.highlight` (overlay maior, `edgeSize=10`) = **dourado de seleção** (`CFG.Grid.highlightColor = 1.0,0.85,0.2,0.95`, `:290` + `:3358`). **Hover == seleção** (`OnEnter → SelectSlot`, `:3364`).

Não existe hoje nenhuma distinção por bag-container de origem: `ParseItemData` (`:3545`) guarda `bagID/slotID` mas nenhum `bagType`, e **nada no repo usa `GetContainerNumFreeSlots` ou `GetBagName`** (grep retorna 0 hits em todos os `.lua`). As categorias atuais (`ALL/EQUIP/USABLE/TRADE/MISC`, `:306-314`) classificam o **item**, não a bolsa.

A proposta é adicionar uma **terceira camada** — `slot.bagBorder`, moldura fina DEDICADA ao tipo da bag — sem tocar em `border` (qualidade) nem `highlight` (foco). Por que não pintar `slot.border` diretamente: ela carrega informação de qualidade (raro/épico/lendário); pintar por bag apagaria isso. A decisão técnica correta, verificada no código, é:

- Item em bag especial → `slot.border` continua com a cor de **qualidade**, e a nova `slot.bagBorder` externa mostra a cor da **bag**.
- Item em bag normal (`NORMAL`) → `slot.bagBorder` fica **escondida**: visual pixel-idêntico ao atual.
- Slot vazio dentro de bag especial → `slot.bagBorder` aparece com alpha reduzido (`0.45`), mostrando a capacidade especial livre.
- DetailCard do item focado ganha tag da bag de origem (ex. `|cff33b333[Bolsa de Ervas]|r`).

Detecção: `GetContainerNumFreeSlots(bagID)` → 2º retorno `bagType` bitmask oficial (`1/2/4/8/32/64/128/512`) + `GetBagName(bagID)` com fallback por substring para os customs do Turtle WoW sem bitmask própria (`Gem Bag`, `Meat Bag`, `Fish Bag` — ver print de referência do usuário). Tudo com `pcall` de proteção e cache por `bagID` em `ScanInventory`, pois **nenhuma dessas duas APIs é usada hoje no repo** — a Fase 1 vai provar em jogo que elas existem e retornam o esperado no client Turtle.

Tipos cobertos (conforme print de referência do usuário):

| Tipo | Origem da detecção |
| :--- | :--- |
| Bag (normal) | `bagType == 0`, sem match de nome → `bagBorder` escondida, zero mudança visual |
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

### 2.1. Grid de bags com a terceira camada (camadas separadas por slot)

```
┌────────┬────────┬────────┬────────┐
│ normal │ HERB   │ SOUL   │ normal │
│ border │ border │ border │ border │
│ =quali │ =quali │ =quali │ =quali │
│ (sem   │ +bagBo │ +bagBo │ +HIGH- │
│ bagBor │ rder   │ rder   │ LIGHT  │
│ der)   │ verde  │ roxa   │ dourado│
└────────┴────────┴────────┴────────┘
   (a)      (b)      (c)       (d)

(a) item comum em bag normal: idêntico a hoje (border branca porad+sem moldura externa)
(b) item qualquer em Herb Bag: border mantém qualidade + moldura externa verde
(c) shard em Soul Bag: border mantém qualidade + moldura externa roxa
(d) slot focado (hover): highlight dourado POR CIMA de tudo — sempre prevalece
```

### 2.2. DetailCard com tag da bag de origem

```
│ DETAIL CARD:                                      │
│ ┌───────┐  |cff1eff00Erva Prateada|r               │
│ │ [ÍCONE]│  Consumível • Reagente                  │
│ └───────┘  |cff33b333[Bolsa de Ervas]|r • Herb Bag │
```

---

## 3. Tabela de Cores Proposta (`BAG_TYPE_COLORS`)

Moldura externa `slot.bagBorder`: mesmo `edgeFile` do grid (`UI-Tooltip-Border`), `edgeSize=6` (mais fina que `border=8` e `highlight=10`), alpha `0.75` em slot ocupado / `0.45` em slot vazio. Tons harmonizados com a paleta quente (marrom/âmbar/bronze) do addon:

| Chave | Tipo | R | G | B | Hex aprox. | Motivo |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `NORMAL` | Bag genérica | — | — | — | — | `bagBorder` escondida (inalterado) |
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
> **Objetivo de Teste:** O jogador abre o MainMenu na aba Bags e vê no chat a lista exata das suas bags detectadas (nome + tipo), provando que `GetContainerNumFreeSlots`/`GetBagName` existem e funcionam no client Turtle antes de qualquer mudança visual.

- [ ] Em `ScanInventory` (`UI/MainMenu.lua:3695`), cachear por `bagID` (0–4): 2º retorno de `GetContainerNumFreeSlots(bag)` + `GetBagName(bag)`, ambos com `pcall` de proteção (nenhuma das duas APIs é usada hoje no repo — podem não existir/retornar `nil`).
- [ ] Implementar `MainMenu:ResolveBagKind(bagID, bagType, bagName)`: primeiro bitmask oficial (`1/2/4/8/32/64/128/512`), depois fallback por substring lower-case no nome (`"soul"`, `"herb"`, `"enchant"`, `"engineer"`, `"mining"`, `"leather"`, `"quiver"`, `"ammo"`/`"pouch"`, `"gem"`, `"meat"`, `"fish"` com `string.find(..., 1, true)`), senão `"NORMAL"`.
- [ ] Adicionar campos `bagKind` e `bagName` ao retorno de `ParseItemData` (`:3672`, via cache do scan; assinatura de chamada intacta) — inclusive nas entradas `isEmpty` (`:3714`), que já carregam `bagID/slotID`.
- [ ] Ao abrir a aba Bags (`SetupBagsPage`/`UpdateBagsPage`), imprimir no chat uma linha por bag: `[ConsoleMode] Bag <id>: "<nome>" -> <KIND> (type=<n>)`.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 1):** O jogador dá `/reload`, abre o MainMenu nas Bags com bags especiais equipadas e confirma no chat que cada bag foi identificada com o KIND correto. **Sem esta confirmação (especialmente Gem/Meat/Fish do Turtle), as cores das fases seguintes não fazem sentido.** Commit somente após aprovação.

---

### 🟢 FASE 2: Tabela de cores + helper de resolução (sem mudança visual)
> **Objetivo de Teste:** O jogador abre a aba Bags e vê no chat a cor resolvida para cada bag, podendo pedir ajuste de qualquer cor antes de ela aparecer na tela.

- [ ] Criar constante `BAG_TYPE_COLORS` (tabela da Seção 3) próxima a `CFG.Grid` (`UI/MainMenu.lua:281-290`).
- [ ] Implementar `MainMenu:GetBagBorderColor(bagKind)` → retorna `r, g, b` (aceita `nil`/desconhecido com segurança, caindo no bronze default).
- [ ] Estender o log da Fase 1 com a cor: `[ConsoleMode] Bag <id>: "<nome>" -> <KIND> (r,g,b)`.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 2):** O jogador dá `/reload`, confere as cores listadas no chat e aprova ou pede troca de qualquer cor da tabela. Nenhum pixel muda nesta fase. Commit somente após aprovação.

---

### 🟢 FASE 3: Moldura `bagBorder` nos slots do grid
> **Objetivo de Teste:** O jogador vê a moldura externa colorida nos slots que estão em bags especiais; slots em bag normal ficam pixel-idênticos a antes.

- [ ] Em `CreateGrid` (`UI/MainMenu.lua:3297`, junto da criação de `slot.border` `:3332` e `slot.highlight` `:3350`): criar `slot.bagBorder` — `Frame` com `edgeFile` do grid, `edgeSize=6`, pontos `-3,3 / 3,-3` (entre `border` e `highlight`), cor inicial invisível (`Hide()`).
- [ ] Em `UpdateBagsPage`, no fill (`:4239-4274`): após pintar `slot.border` por qualidade (`:4264`, INTOCADO), se `itemData.bagKind ~= "NORMAL"` mostrar `slot.bagBorder` com a cor da tabela (alpha `0.75`); senão `Hide()`.
- [ ] Na branch de slot vazio (`:4267-4270`, border bronze apagado INTOCADO): se a bag de origem do slot vazio for especial, mostrar `slot.bagBorder` com alpha `0.45`; senão `Hide()`.
- [ ] `grid:Clear()` (`:3525`): esconder `slot.bagBorder` junto (estado limpo, sem cor presa).
- [ ] `SelectSlot` (`:3506`), `OnEnter/OnLeave` (`:3364-3372`), paginação e filtros: **intocados** — o highlight dourado continua passando por cima.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 3):** O jogador dá `/reload` e confirma: (a) slots em bags especiais com moldura externa da cor certa; (b) slots em bag normal idênticos a antes; (c) épico/raro em bag especial mantém a border de qualidade + moldura da bag; (d) trocar de filtro/página não deixa cor presa. Commit somente após aprovação.

---

### 🟢 FASE 4: Tag da bag no DetailCard
> **Objetivo de Teste:** Ao focar um item de bag especial, o DetailCard mostra de qual bag ele veio; hover/seleção continuam dourados.

- [ ] Em `card:ShowItem` (`UI/MainMenu.lua:2814`, após título/subtipo ~`:2827-2831`): se `itemData.bagKind ~= "NORMAL"`, anexar tag colorida com o hex da tabela (ex. `|cff33b333[Bolsa de Ervas]|r`); bag normal não mostra nada (card inalterado).
- [ ] Hover (`OnEnter → SelectSlot`) e `card:Clear("Slot Vazio")` (`:4122`): validar que nada muda de comportamento — hover continua dourado, slot vazio continua sem tag.
- [ ] Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 4):** O jogador dá `/reload` e valida tag no card para cada tipo especial + ausência de tag em bag normal. Commit somente após aprovação.

---

### 🟢 FASE 5: Regressão geral e polimento Turtle
> **Objetivo de Teste:** Nada do que funcionava quebrou; tipos custom do Turtle detectados em contas reais.

- [ ] Revisar filtros de categoria (`LT/RT`, `CycleCategories` `:12691`), paginação (`Next/PrevBagPage` `:4303/4316`), ordenação (botão sort `:4048`), menu de contexto (`RightButton → OpenForBagItem` `:3377`), `TryOnItem`/model 3D e `ItemCompare`: nenhum pode ter mudado de comportamento.
- [ ] Testar com hunter (quiver/ammo pouch) e profissões com bags (herb/mining/enchanting/engineering) — confirmar KIND, cor da moldura e tag.
- [ ] Testar cenário sem nenhuma bag especial: grid e card devem estar pixel-idênticos ao comportamento anterior.
- [ ] Validação de sintaxe final via `luac -p` + checagem de regressão geral.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 5):** Teste geral completo. Commit final somente após aprovação.

---

## 5. Estrutura de Arquivos

```
Interface/AddOns/ConsoleModeVanilla/
├── UI/
│   └── MainMenu.lua                  <-- ÚNICO arquivo alterado (todas as 5 fases)
│       ├── BAG_TYPE_COLORS           <-- NOVO (Fase 2, próximo a CFG.Grid ~L281)
│       ├── ResolveBagKind()          <-- NOVO (Fase 1, junto ao scanner ~L3695)
│       ├── GetBagBorderColor()       <-- NOVO (Fase 2)
│       ├── ParseItemData()           <-- +campos bagKind/bagName (Fase 1, ~L3545)
│       ├── ScanInventory()           <-- +cache bagType/bagName (Fase 1, ~L3695)
│       ├── CreateGrid()              <-- +slot.bagBorder (Fase 3, ~L3297)
│       ├── grid:Clear()              <-- esconde bagBorder (Fase 3, ~L3525)
│       ├── UpdateBagsPage()          <-- aplica bagBorder (Fase 3, ~L4239)
│       └── card:ShowItem()           <-- +tag da bag (Fase 4, ~L2814)
│   └── MerchantMenu.lua              <-- INTOCADO (fora de escopo desta feature)
└── docs/
    └── plano_de_feature_COR_DE_BORDA_POR_TIPO_DE_BAG.md <-- Este documento (reescrito: escopo movido de MerchantMenu para MainMenu/Bags)
```

## 6. Histórico de escopo

- v1 (commit `8bdc2ee`): plano escopado para `UI/MerchantMenu.lua` (rows vendedor/inventário) — **descartado**: implementação parcial da Fase 1 chegou a ser escrita e foi **totalmente revertida** (`git checkout -- UI/MerchantMenu.lua`), sem deixar resíduos.
- v2 (atual): escopo correto — aba **Bags do MainMenu** (grid de slots). Verificação de código feita por agentes exploradores: grid `CreateGrid:3297`, border de qualidade `UpdateBagsPage:4264`, highlight dourado `CFG.Grid.highlightColor:290`, DetailCard `ShowItem:2814`, categorias `:306-314`.
