# Plano de Feature: Modal de Aprimoramento de Equipamentos para Console

## 1. Visão Geral e Objetivo
Criar uma interface modal moderna, elegante e 100% nativa para controle/gamepad, acionada automaticamente sempre que o jogador utiliza consumíveis de aprimoramento com mira (Pedras de Afiar, Pedras de Peso, Óleos Mágicos, Venenos de Ladino, Kits de Armadura, Miras de Engenharia e Espigões de Escudo). 

A interface elimina a necessidade de cursor de mouse livre, permitindo que o jogador selecione rapidamente o item de destino (seja uma peça atualmente equipada ou um item guardado na mochila) através do D-Pad e confirme a aplicação com um simples toque no botão `A`.

---

## 2. Diretrizes Estritas de Design Visual e Identidade do Projeto
O visual do modal deve seguir **rigorosamente a mesma linguagem visual concisa da tela de correio (`UI/MailScreen.lua`) e do sistema de menus do ConsoleMode**:

1. **Backdrop & Janela (9-Slice Esculpido):**
   * Dimmer de tela cheia escurecendo o fundo (`0.0, 0.0, 0.0, 0.65`) para foco e imersão de console.
   * Frame principal com textura oficial 9-slice esculpida (`Interface\AddOns\ConsoleModeVanilla\Media\Carved_9Slides.tga`), tamanho de canto `48px` e opacidade total (sem transparência de fundo).
2. **Tipografia Padrão do Addon:**
   * Títulos: `AlegreyaSans-Bold.ttf` com sombreamento padrão (`SetShadowOffset(1, -1)`).
   * Itens e descrições: `AlegreyaSans-Bold.ttf` e `AlegreyaSans-Medium.ttf`.
3. **Indicador de Abas Centralizado (Estilo MailScreen):**
   * Localizado abaixo do título da janela.
   * Exibição em trio centralizado com **texturas oficiais dos botões** (`ICONS.LB` e `ICONS.RB`), nunca texto cru tipo "LB":
     * `[Textura LB] EQUIPADOS [Textura RB]`
     * `[Textura LB] NA MOCHILA [Textura RB]`
4. **Legendas e Rodapé (Footer Prompts):**
   * **PROIBIDO** o uso de strings textuais como `[A]`, `[B]`, `[LB]`.
   * **SEMPRE** utilizar texturas reais dos botões de controle registradas no addon:
     * `ICONS.A` (`Media\Icons\Xbox\A.tga`)
     * `ICONS.B` (`Media\Icons\Xbox\B.tga`)
     * `ICONS.LB` / `ICONS.RB` (`Media\Icons\Xbox\LB.tga` / `RB.tga`)
     * `ICONS.DUP` / `ICONS.DDOWN` para navegação vertical.
5. **Cores de Qualidade de Item:**
   * Utilizar a tabela `QUALITY_COLORS` idêntica ao `MailScreen.lua` (Cinza, Branco, Verde, Azul, Roxo, Laranja) com bordas e highlights padronizados.

---

## 3. Validação Técnica (WoW Vanilla 1.12.1 / Lua 5.0)

### 3.1 Ausência de Taint e Execução Segura
* No WoW 1.12 **não existe sistema de Taint** nem `SecureActionButtonTemplate`.
* Quando um item com alvo é usado via `UseContainerItem(bag, slot)`, a engine ativa `SpellIsTargeting() == true`.
* A engine do WoW 1.12 aceita a aplicação programática do aprimoramento por duas APIs nativas:
  * **Em Item Equipado:** `PickupInventoryItem(invSlotID)`
  * **Em Item na Mochila:** `PickupContainerItem(bagID, slotID)`
* Caso o jogador cancele no controle (botão `B`), o feitiço é abortado limpamente através de `SpellStopTargeting()`.

### 3.2 Arquitetura de Performance (Lazy Scanning)
* **Aba "Equipados" (Custo O(1) ~ 0.001ms):**
  * Inspeciona diretamente apenas os slots relevantes do corpo (ex: Slots 16 e 17 para armas; 5, 7, 8, 10 para kits).
  * O modal abre instantaneamente sem qualquer micro-travamento.
* **Aba "Na Mochila" (Custo Sob Demanda):**
  * As bolsas **NÃO são varridas** na abertura do modal.
  * O escaneamento da mochila só é disparado **se e quando o jogador alternar para a aba [RB]**.
  * Os resultados da varredura são cacheados durante o tempo de vida do modal aberto, evitando processamento redundante se o jogador alternar entre abas repetidamente.

---

## 4. Mapeamento de Consumíveis e Regras de Alvo

| Categoria | Família de Itens | Restrições de Tipo | Slots Equipados Elegíveis |
| :--- | :--- | :--- | :--- |
| **Armas Cortantes** | Pedras de Afiar (Sharpening Stones) | Espadas, Adagas, Machados, Armas de Haste | Mão Principal (16), Mão Secundária (17) |
| **Armas de Impacto** | Pedras de Peso (Weightstones) | Maças, Cajados, Armas de Punho | Mão Principal (16), Mão Secundária (17) |
| **Óleos Mágicos** | Óleos de Mago e Mana (Wizard/Mana Oils) | Qualquer arma corpo a corpo ou bastão | Mão Principal (16), Mão Secundária (17) |
| **Venenos** | Venenos de Ladino (Poisons) | Qualquer arma corpo a corpo | Mão Principal (16), Mão Secundária (17) |
| **Kits de Armadura** | Kits de Armadura Leve a Robusto | Peitorais, Calças, Luvas e Botas | Torso (5), Pernas (7), Mãos (10), Pés (8) |
| **Miras** | Miras de Engenharia (Scopes) | Arcos, Bestas, Armas de Fogo | Longo Alcance / Ranged (18) |
| **Espigões** | Espigões de Escudo (Shield Spikes) | Apenas Escudos | Mão Secundária (17) *(se for Escudo)* |

---

## 5. Fases de Implementação Testáveis (Big Tech / Phased Engineering)

Para garantir qualidade de nível industrial e validação contínua em cada passo, o desenvolvimento é fatiado em etapas atômicas e testáveis:

### Fase 1: Motor de Detecção & Classificação de Consumíveis (Core Interceptor) [CONCLUÍDO]
* **Objetivo:** Identificar com precisão quando o jogador aciona um item de aprimoramento com mira.
* **Status:** Entregue e validado.

### Fase 2: Estrutura Visual do Modal & Ciclo de Vida (View Shell) [CONCLUÍDO]
* **Objetivo:** Construir o shell visual do modal com a identidade idêntica ao `MailScreen.lua`.
* **Status:** Entregue e validado.

### Fase 3: Aba "Equipados" - Carregamento Instantâneo & Navegação D-Pad [CONCLUÍDO]
* **Objetivo:** Popular os slots equipados elegíveis e habilitar navegação de gamepad fluida.
* **Status:** Entregue e validado.

### Fase 4: Execução na Arma Equipada & Feedback de Ação [CONCLUÍDO]
* **Objetivo:** Concluir a ação de aprimoramento no equipamento ativo.
* **Status:** Entregue e validado.

### Fase 5: Aba "Na Mochila" - Varredura Sob Demanda (Lazy Scan) & Lista [CONCLUÍDO]
* **Objetivo:** Escanear a mochila apenas sob demanda e listar itens compatíveis.
* **Status:** Entregue e validado.

### Fase 6: Execução em Itens da Mochila & Tratamento de Resiliência [CONCLUÍDO]
* **Objetivo:** Concluir a aplicação em itens guardados e blindar o sistema contra erros.
* **Tarefas Concluídas:**
  * No botão `A` na aba da mochila, dispara `PickupContainerItem(bagID, slotID)`.
  * Fecha automaticamente o modal se o jogador entrar em combate (`PLAYER_REGEN_DISABLED`), morrer (`PLAYER_DEAD`), perder controle (`PLAYER_CONTROL_LOST`) ou deixar o mundo (`PLAYER_LEAVING_WORLD`).
  * Fecha automaticamente com o fechamento do MainMenu (`OnHide`).
  * Cancelamento defensivo no diálogo nativo `REPLACE_ENCHANT` e `REPLACE_TRADESKILL_ENCHANT`, evitando que o cursor fique travado em modo mira caso o jogador cancele a substituição.
  * Prioridade máxima no botão `B` para fechar o diálogo de confirmação (`StaticPopup`) antes de qualquer outra janela de fundo.
* **Status:** Entregue e validado.

---

## 6. Status do Projeto
Todas as 6 fases foram concluídas com sucesso e integradas à branch `main`.
