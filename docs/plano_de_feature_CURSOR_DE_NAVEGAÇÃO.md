# Plano de Feature: Cursor de Navegação

## FONTE

Esta seção documenta em detalhes a engenharia reversa e a análise técnica realizada sobre a funcionalidade de **Cursor Navigation** presente no addon `ConsoleExperienceClassic` (versão 0.17.3 para WoW 1.12 / Turtle WoW).

### 1. Limitações e Descobertas do Motor do WoW 1.12
- **Impossibilidade de Controle do Mouse do SO**: No cliente Vanilla 1.12 não existem APIs Lua para mover a posição física do cursor do mouse do Windows (`SetCursorPosition` não existe de forma irrestrita para a UI).
- **Abordagem de Cursor Virtual**: O addon resolve isso criando frames visuais customizados (um ponteiro e uma moldura de destaque/highlight) que são reposicionados dinamicamente sobre os elementos da interface através de ancoragem (`SetPoint`).
- **Ausência de Sistema de Proteção/Taint**: Como a proteção de frames (`IsProtected`, `SecureActionButtonTemplate`) só foi introduzida na expansão The Burning Crusade (2.0), no 1.12 qualquer API nativa pode ser chamada livremente via Lua sem gerar falhas de segurança de execução.

### 2. Mecanismo de Auto-Snap e Descoberta de Elementos
- **Interceptação de Janelas (Hooks)**: O sistema monitora a abertura (`OnShow`) e o fechamento (`OnHide`) de mais de 60 frames nativos da Blizzard (como `GossipFrame`, `QuestFrame`, `MerchantFrame`, `ContainerFrame1-5`, `CharacterFrame`, `SpellBookFrame`, `StaticPopup1-4`, `TaxiFrame`, etc.) além de frames dinâmicos de addons de inventário (ex: pfUI, Bagshui, Bagnon).
- **Busca por Árvore (Depth-First Search)**: Ao abrir uma janela, o sistema percorre recursivamente os filhos da janela (`GetChildren()`) até encontrar o primeiro elemento interativo que esteja visível (`IsVisible()`), com dimensões mínimas válidas (>10px) e opacidade ativa.
- **Auto-Scroll Integrado**: Caso o elemento interativo localizado esteja dentro de um `ScrollFrame` e fora do campo visível, o sistema calcula e atualiza a barra de rolagem automaticamente para trazer o elemento para a visão do jogador.

### 3. Navegação Espacial e Vetorial (D-Pad / Analógico)
- **Cálculo de Vizinhos**: Ao receber um comando direcional (CIMA, BAIXO, ESQUERDA, DIREITA), o sistema mapeia o centro de todos os botões interativos visíveis na tela.
- **Filtragem por Cones Angulares**: Aplica filtros de ângulo (cones de 45° a 90°) para identificar quais botões estão verdadeiramente na direção desejada em relação à posição atual.
- **Distância Euclidiana Ponderada**: Dentre os botões válidos no cone de direção, o elemento com a menor distância vetorial é selecionado.
- **Wrapping (Dar a volta)**: Se não existirem botões na direção escolhida (ex: apertar para Cima no topo de uma lista), o algoritmo busca o botão mais distante no eixo oposto para permitir navegação cíclica sem travar o cursor.

### 4. Execução de Ações e Cliques Simulados
- **Roteamento de Tipos de Elementos**: Os cliques são despachados de acordo com o tipo de elemento focado:
  - **Bolsas/Inventário**: Despacha `PickupContainerItem` (para pegar ou mover) ou `UseContainerItem` (para usar/equipar diretamente com o botão direito).
  - **Equipamentos**: Executa `PickupInventoryItem` ou desequipa diretamente para a mochila via `PutItemInBackpack`.
  - **Sliders**: Altera valores diretamente com `SetValue(current + step)`.
  - **Caixas de Texto (EditBox)**: Abre teclado virtual ou atribui foco direto via `SetFocus()`.
  - **Botões Genéricos / Janelas de Diálogo**: Dispara `element:Click("LeftButton")` ou `element:Click("RightButton")`.
- **Tooltips Contextuais**: Exibe o `GameTooltip` oficial do elemento ancorado e adiciona prompts visuais de botões do controle indicando as ações disponíveis.

### 5. Gestão Dinâmica de Keybindings
- Ao detectar uma janela aberta, o sistema armazena os atalhos de teclado/D-Pad originais do jogador e injeta temporariamente os bindings de navegação do cursor.
- Ao fechar todas as janelas ativas, aplica um atraso (debounce de ~100ms) e restaura integralmente os atalhos normais do jogo.

---

## IDEIA INICIAL:

O objetivo com o **ConsoleMode - Vanilla** é criar um addon moderno, limpo, modular e ultraotimizado para o Turtle WoW / Vanilla 1.12, voltado especialmente para quem joga em dispositivos portáteis como o **Steam Deck** (ou com controles convencionais no PC).

Ao invés de carregar módulos pesados e legados que poluem a interface e o processamento, a ideia é reconstruir do zero uma experiência inspirada no consagrado **ConsolePort** do WoW Retail:

1. **Navegação Fluida de UI**: Permitir que qualquer janela aberta no jogo (missões, diálogos com NPCs, bolsas, banco, talentos, configurações) receba o foco imediato do cursor sem que o jogador precise tocar na tela ou usar o trackpad do Steam Deck como mouse.
2. **Auto-Snap Inteligente**: O foco deve ir direto para a opção mais relevante (ex: aceitar quest, primeira opção de diálogo, primeiro slot da bolsa) de forma instantânea e natural.
3. **Navegação Direcional Clara**: Usar o D-Pad para transitar entre botões e opções com feedback visual moderno e destaque claro do elemento atualmente selecionado.
4. **Interação com Botões de Ação**: Mapear os botões principais do controle (como A, B, X, Y) para confirmar, cancelar, usar itens e equipar de forma contextualizada.
5. **Código Enxuto e Independente**: Uma base de código independente de pacotes gigantes, focada em simplicidade, estabilidade no 1.12 e fácil manutenção.
