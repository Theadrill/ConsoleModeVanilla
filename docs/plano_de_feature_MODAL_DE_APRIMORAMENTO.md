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

### Fase 1: Motor de Detecção & Classificação de Consumíveis (Core Interceptor)
* **Objetivo:** Identificar com precisão quando o jogador aciona um item de aprimoramento com mira.
* **Tarefas:**
  * Monitorar a ativação de `SpellIsTargeting()` originada por `UseContainerItem` no inventário.
  * Identificar o consumível ativo (nome, textura, categoria e regras de compatibilidade) através de leitura estruturada de tooltip/link.
  * Guardar o contexto ativo em `EnhanceModal.activeEnhanceContext`.
* **Critério de Teste:** Ao apertar `A` em uma Pedra de Afiar na bolsa, o addon detecta o item e registra no log interno a categoria correta (`WEAPON_SHARP`) sem interromper a engine do jogo.

### Fase 2: Estrutura Visual do Modal & Ciclo de Vida (View Shell)
* **Objetivo:** Construir o shell visual do modal com a identidade idêntica ao `MailScreen.lua`.
* **Tarefas:**
  * Criar o frame principal com dimmer escuro e 9-slice `Carved_9Slides.tga`.
  * Criar o cabeçalho com o ícone e nome do item sendo aplicado.
  * Criar o indicador de abas com as texturas dos botões `[LB] EQUIPADOS [RB]` e `[LB] NA MOCHILA [RB]`.
  * Implementar a alternância visual das abas através dos bumpers `LB` e `RB`.
  * Implementar o footer com prompts em texturas (`A Aplicar`, `B Cancelar`, `LB/RB Alternar`).
  * Conectar o botão `B` e tecla `ESC` para executar `SpellStopTargeting()` e fechar o modal.
* **Critério de Teste:** Usar a pedra de afiar abre o modal centralizado na tela com estilo idêntico ao Mail. Pressionar `LB` e `RB` alterna visualmente as abas vazias. Pressionar `B` cancela a mira e fecha a janela.

### Fase 3: Aba "Equipados" - Carregamento Instantâneo & Navegação D-Pad
* **Objetivo:** Popular os slots equipados elegíveis e habilitar navegação de gamepad fluida.
* **Tarefas:**
  * Ler apenas os slots do corpo correspondentes à categoria do item ativo (ex: Slots 16 e 17 para armas).
  * Renderizar as linhas com:
    * Ícone do item equipado + borda de slot.
    * Nome do item com cor de raridade (`QUALITY_COLORS`).
    * Identificador do slot (ex: "Mão Principal", "Mão Secundária").
  * Implementar sistema de foco e navegação com D-Pad (`UP` / `DOWN`).
  * Foco inicial automático na primeira opção válida (Slot 16).
* **Critério de Teste:** Abrir o modal com a pedra de afiar exibe as armas equipadas com nomes coloridos e ícones. O D-Pad sobe e desce o cursor com destaque dourado sem atraso.

### Fase 4: Execução na Arma Equipada & Feedback de Ação
* **Objetivo:** Concluir a ação de aprimoramento no equipamento ativo.
* **Tarefas:**
  * No botão `A`, disparar `PickupInventoryItem(slotID)`.
  * Tocar som tátil de confirmação (`PlaySound("igMainMenuOptionCheckBoxOn")`).
  * Fechar o modal imediatamente e resetar o estado.
  * Habilitar suporte a clique direto de mouse na linha do modal para usuários híbridos.
* **Critério de Teste:** Selecionar a Mão Principal e apertar `A` afia a arma equipada! O buff temporário surge no tooltip da arma, o som toca e a janela se fecha.

### Fase 5: Aba "Na Mochila" - Varredura Sob Demanda (Lazy Scan) & Lista
* **Objetivo:** Escanear a mochila apenas sob demanda e listar itens compatíveis.
* **Tarefas:**
  * Implementar trigger de scan exclusivo no evento de alternância para a aba `[RB] Na Mochila`.
  * Varrer as bolsas filtrando apenas itens cujo tipo corresponda à categoria necessária (evitando custo em itens irrelevantes).
  * Renderizar a lista de itens da mochila com paginação/scroll caso ultrapasse a altura visível.
  * Exibir estado vazio estilizado ("Nenhum item compatível na mochila") se não houver itens válidos.
  * Armazenar em cache a lista escaneada durante a sessão aberta do modal.
* **Critério de Teste:** Ter armas sobressalentes na bolsa. Ao abrir o modal, a aba Equipados abre a 60 FPS; ao pressionar `RB`, a aba da mochila exibe as armas guardadas com seus nomes e ícones.

### Fase 6: Execução em Itens da Mochila & Tratamento de Resiliência
* **Objetivo:** Concluir a aplicação em itens guardados e blindar o sistema contra erros.
* **Tarefas:**
  * No botão `A` na aba da mochila, disparar `PickupContainerItem(bagID, slotID)`.
  * Fechar automaticamente o modal se o jogador entrar em combate (`PLAYER_REGEN_DISABLED`) ou fechar o menu principal.
  * Cancelar adequadamente o feitiço se o item consumível for consumido por outra ação ou se o cursor perder a mira (`CURRENT_SPELL_CAST_CHANGED`).
* **Critério de Teste:** Afiar uma arma guardada na bolsa funciona perfeitamente. Abrir o modal e iniciar combate fecha a janela sem prender a mira.

---

## 6. Próximos Passos
Após aprovação deste documento, o desenvolvimento seguirá estritamente a sequência das Fases 1 a 6, com validação de build (`luac`) e teste funcional ao término de cada etapa.
