# Plano de Feature: Organização Virtual do Inventário (Virtual Bag Sorter)

> **Status:** 100% Concluído e Homologado no Jogo  
> **Versão Alvo:** WoW 1.12.1 (Interface 11200) / Lua 5.0 (Turtle WoW)  
> **Data:** 13/10/2026  
> **Arquivo do Módulo:** `UI/InventorySorter.lua`  

---

## 1. Visão Geral e Motivação

### O Problema Atual
No inventário do `MainMenu` (`UI/MainMenu.lua`), a ordenação de itens depende do botão "ORGANIZAR" que invoca uma rotina mecânica (como `SortBags()`). No cliente WoW 1.12.1, essa rotina troca itens de lugar fisicamente entre os slots e bolsas do jogador (`PickupContainerItem`), o que causa:
1. **Lentidão / Gap Temporal:** O processo depende de confirmações do servidor via rede e eventos de `BAG_UPDATE`, ocorrendo em pequenos lotes e demorando segundos.
2. **Fragilidade Mecânica:** Se o jogador interagir com o inventário durante a troca física, itens podem ficar em posições inesperadas ou o processo pode interromper.
3. **Desorganização Contínua:** Ao pegar novos loots ou recompensas de missões, o inventário volta a ficar fragmentado até o jogador clicar em organizar novamente.

### A Solução: Organização Virtual (Presentation Layer)
Implementar uma **camada de apresentação virtual** onde:
* O addon **NÃO move** nenhum item mecanicamente nas bolsas reais do jogador. A Bag 0 Slot 1 e a Bag 3 Slot 4 continuam com os mesmos itens físicos no servidor do WoW.
* Ao abrir ou atualizar a aba `BAGS`, o addon escaneia os itens e os ordena **puramente em memória (< 1ms)** em Lua 5.0 antes de alimentar os slots visuais do Grid.
* Cada slot desenhado mantém mapeado seu `itemData.bagID` e `itemData.slotID` reais, de forma que ações do controle (usar item com `[A]`, abrir `ContextMenu`, comparar com equipado, Live Try-on 3D) continuam 100% transparentes e funcionais.
* **Resultado:** O inventário sempre aparece limpo, categorizado e arrumado instantaneamente ao abrir a interface, sem nenhum engasgo de rede ou gap mecânico.

---

## 2. Tratamento de Bolsas Especiais (Profissão, Aljavas, Almas)

As bolsas especiais (Quivers, Ammo Pouches, Soul Bags, Herb Bags, Mining Sacks, etc.) possuem restrições rígidas impostas pelo motor do jogo (ex.: armaduras não entram em aljavas).

### Diretriz de Separação
1. **Inventário Principal (Bolsas Normais):** Itens pertencentes às bolsas normais (Bag 0 a 4 do tipo normal) são agrupados e ordenados juntos.
2. **Bolsas Especiais Isoladas no Final:** Os itens e slots de bolsas especiais (reconhecidos via `bagKind ~= "NORMAL"`) são agrupados ao final da lista, mantendo suas molduras temáticas (`BAG_TYPE_COLORS`) e agrupando seus próprios espaços vazios específicos.
3. **Clareza Visual:** Isso impede que o jogador confunda um slot vazio de Aljava com espaço livre para guardar equipamentos.

---

## 3. Arquitetura e Configurações Globais (Início do Script)

O módulo será isolado em um novo arquivo `UI/InventorySorter.lua`, desacoplado do monólito do `MainMenu.lua`. No topo do script, haverá tabelas globais intuitivas para fácil edição e balanceamento das prioridades:

```lua
-- ============================================================================
-- CONSOLEMODE: CONFIGURAÇÃO DE PRIORIDADES DE ORDENAÇÃO VIRTUAL (Lua 5.0)
-- Menor número = maior prioridade (aparece primeiro no Grid)
-- ============================================================================

-- 1. Prioridade principal por Categoria do ConsoleMode
CONSOLEMODE_SORT_CATEGORY_PRIORITY = {
    QUEST       = 1,   -- Itens de Missão
    EQUIP       = 2,   -- Equipamentos (Armaduras, Armas, Acessórios)
    CONSUMABLE  = 3,   -- Consumíveis (Poções, Comidas, Bandagens, Elixires)
    TRADE       = 4,   -- Reagentes de Profissão / Trade Goods
    MISC        = 5,   -- Itens Diversos / Utilidades
    JUNK        = 6,   -- Lixo (Cinzas / Grey)
    EMPTY       = 99,  -- Slots Vazios (sempre no final)
}

-- 2. Prioridade de Equipamentos por Slot de Equipar (ItemEquipLoc)
CONSOLEMODE_SORT_EQUIPLOC_PRIORITY = {
    INVTYPE_HEAD           = 1,
    INVTYPE_NECK           = 2,
    INVTYPE_SHOULDER       = 3,
    INVTYPE_CHEST          = 4,
    INVTYPE_ROBE           = 4,
    INVTYPE_WAIST          = 5,
    INVTYPE_LEGS           = 6,
    INVTYPE_FEET           = 7,
    INVTYPE_WRIST          = 8,
    INVTYPE_HAND           = 9,
    INVTYPE_FINGER         = 10,
    INVTYPE_TRINKET        = 11,
    INVTYPE_CLOAK          = 12,
    INVTYPE_2HWEAPON       = 13,
    INVTYPE_WEAPONMAINHAND = 14,
    INVTYPE_WEAPON         = 15,
    INVTYPE_WEAPONOFFHAND  = 16,
    INVTYPE_HOLDABLE       = 17,
    INVTYPE_SHIELD         = 18,
    INVTYPE_RANGED         = 19,
    INVTYPE_RANGEDRIGHT    = 20,
    INVTYPE_RELIC          = 21,
    INVTYPE_TABARD         = 22,
    INVTYPE_BAG            = 23,
}

-- 3. Prioridade de Qualidade (Raridade)
-- Qualidade no WoW: 0=Poor, 1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary
-- Invertemos para que maior qualidade venha primeiro:
CONSOLEMODE_SORT_QUALITY_WEIGHT = {
    [5] = 1, -- Lendário
    [4] = 2, -- Épico
    [3] = 3, -- Raro
    [2] = 4, -- Incomum
    [1] = 5, -- Comum
    [0] = 6, -- Pobre/Cinza
}
```

---

## 4. Fases de Implementação e Critérios de Aceite

### Fase 1: Criação do Módulo `UI/InventorySorter.lua` e Algoritmo em Lua 5.0
* **Objetivo:** Criar o arquivo e implementar a função comparadora estrita compatível com Lua 5.0 (`table.sort`).
* **Regras de Comparação:**
  1. **Bolsas Normais vs Especiais:** Itens de bolsa normal vêm antes de itens de bolsa especial.
  2. **Itens vs Slots Vazios:** Itens ocupados vêm antes de slots vazios (`isEmpty`).
  3. **Categoria:** Ordenado por `CONSOLEMODE_SORT_CATEGORY_PRIORITY`.
  4. **Equipamentos:** Se ambos forem `EQUIP`, desempatar por `CONSOLEMODE_SORT_EQUIPLOC_PRIORITY` e depois por Nível Requerido (`reqLevel`) decrescente.
  5. **Qualidade:** Se da mesma categoria, maior qualidade vem primeiro (`CONSOLEMODE_SORT_QUALITY_WEIGHT`).
  6. **Nome / ID:** Ordem alfabética pelo nome do item para agrupar stacks iguais.
  7. **Slots Vazios:** Slots vazios de bolsas normais vêm primeiro, seguidos de slots vazios de bolsas especiais agrupados por `bagKind`.
* **Validação:** Validação estrita de sintaxe via `C:\Tools\lua50\luac50.exe -p UI/InventorySorter.lua`.

### Fase 2: Registro no `.toc` e Integração com `MainMenu:UpdateBagsPage`
* **Objetivo:** Conectar a ordenação virtual ao pipeline de renderização do `MainMenu`.
* **Modificações:**
  1. Registrar `UI\InventorySorter.lua` no `ConsoleModeVanilla.toc` imediatamente antes de `UI\MainMenu.lua`.
  2. Em `UI\MainMenu.lua` (`MainMenu:UpdateBagsPage`), logo após `local items = scanResult.items`:
     ```lua
     if ConsoleMode and ConsoleMode.SortInventoryItems then
         items = ConsoleMode:SortInventoryItems(items, curCat)
     end
     ```
  3. Atualizar o cálculo de paginação e o preenchimento do Grid com a lista ordenada.
* **Validação:** Abrir a aba `BAGS` no jogo. Constatar ordenação instantânea sem engasgos.

### Fase 3: Homologação de Interações Mecânicas e Consistência de Ações
* **Objetivo:** Garantir que 100% das ações continuam apontando com fidelidade para a bolsa física correta.
* **Testes:**
  * Uso de itens pelo controle (`[A]`) em itens consumíveis e equipamentos.
  * Abertura do menu de contexto (`ContextMenu`) e ações associadas.
  * Comparação com item equipado (DetailCard / Compare).
  * Live Try-On 3D do personagem no modelo.
  * Adicionar/remover itens (pegar loot, vender no vendor) e verificar se o `BAG_UPDATE` reordena perfeitamente.

### Fase 4: Limpeza do Botão Mecânico "Organizar"
* **Objetivo:** Avaliar a interface da aba `BAGS`.
* **Ajuste:** Como o inventário agora se auto-organiza virtualmente em tempo real, o botão antigo de "ORGANIZAR" (`ConsoleModeMM_BagsSortBtn`) torna-se obsoleto ou pode ser convertido em um toggle de ordenação (ex: "Ordenar: Automático / Físico") caso o jogador queira inspecionar as bolsas na disposição crua.

---

## 5. Critérios de Sucesso e Não-Regressão
1. **Zero Atraso (Instantâneo):** Tempo de cálculo imperceptível ao abrir a aba ou ao receber eventos de bolsa.
2. **Zero Poluição Global / Zero Memory Leak:** Tabelas temporárias recicladas ou de escopo local estrito.
3. **Compatibilidade Total WoW 1.12.1 / Lua 5.0:** Nenhuma chamada a métodos proibidos ou sintaxe moderna.
4. **Zero Taint:** Nenhuma chamada protegida em stack indevida.
