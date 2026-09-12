# Plano de Refatoração: DIÁRIO DE MISSÕES & MAPA MUNDI (Modelo Mail-Style)

> **Arquivo:** `docs/plano_de_refatoração_missoes_mapas.md`  
> **Referência Técnica e Arquitetural:** Padrão modular estável de `UI/MailScreen.lua` e `UI/MerchantMenu.lua`.  
> **Data:** 12 de Setembro de 2026.

---

> [!IMPORTANT]
> ## REGRAS MANDATÓRIAS DE DESENVOLVIMENTO
> 1. **Versão do Jogo e Linguagem:** World of Warcraft Vanilla 1.12.1 (Turtle WoW) em **Lua 5.0**. Proibido terminantemente o uso de sintaxe de Lua 5.1+ (como `#t`, `continue`, `goto`, `table.unpack`).
> 2. **Anti-Cheat e Segurança Blizzard:** Proibido o uso de automações ou chamadas invasivas que gerem *taint* ou acionem proteção de UI (erro `ADDON_ACTION_BLOCKED`).
> 3. **Fidelidade Visual do ConsoleMode:** Manter exatamente o layout visual já construído e validado (Mapa amplo na esquerda, NPCs no canto superior esquerdo, botões de navegação no canto superior direito do mapa, lista de missões na sidebar direita de 280px e DetailCard de resumo embaixo).
> 4. **Mecânicas Intocáveis do Mapa:**
>    - **L-Stick (Analógico Esquerdo):** Pan livre contínuo do mapa (`stickPanX`/`stickPanY`).
>    - **Auto-rolagem inteligente:** Centraliza na missão focada, mas se o jogador mover o analógico ou arrastar o mapa, a auto-rolagem cancela imediatamente.
>    - **Gatilhos [LT] e [RT]:** Zoom Out e Zoom In do mapa.
> 5. **Regra de Parada Crítica por Fase (SEM COMMIT / SEM PUSH):** Ao final de cada fase, **nenhum commit e nenhum push será feito**. O trabalho pausa imediatamente para o usuário recarregar o jogo (`/reload`), testar no controle e validar. Somente após a aprovação explícita do usuário a fase será commitada e avançaremos para o próximo passo.
> 6. **Validação de Sintaxe Prévia:** Todo arquivo alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.

---

## 1. Visão Geral da Arquitetura e Objetivos

O objetivo desta refatoração é estabilizar a mecânica interna da aba **Missões & Mapa** do `MainMenu`, unificando a navegação com o padrão determinístico de botões já consolidado nas telas de **Mail** e **Mercador**, eliminando a destruição de frames em tempo de execução e resolvendo definitivamente o erro de segurança da Blizzard.

### O Fluxo da Nova Experiência:
1. **Lista de Missões (Direita):**
   - D-Pad `UP / DOWN` navega a lista com scroll vertical.
   - O `DetailCard` (resumo) atualiza instantaneamente com os objetivos (`[0/8]`) e ícones de recompensa.
   - O mapa na esquerda foca automaticamente na região/objetivo da missão.
   - **`Botão A` (Modal de Leitura da Missão):** Abre um modal central amplo e legível com o texto completo da história/narrativa da missão, com scroll vertical via D-Pad `UP / DOWN` e apenas dois botões reutilizáveis: `[X] Rastrear` e `[B] Sair` (ambos clicáveis também com o mouse). **Zero erros de segurança da Blizzard.**
   - **`Botão X`:** Alterna rastreamento no HUD direto da lista.
   - **`Botão Y`:** Abandona a missão selecionada (dispara o diálogo nativo seguro `StaticPopup_Show("ABANDON_QUEST")`).
2. **Travessia Esquerda ⇄ Direita (Navegação Espacial):**
   - Estando na Lista de Missões, `D-Pad LEFT` salta diretamente para a coluna de **Botões do Mapa** (`ATUAL`, `KALIMDOR`, `EASTERN KINGDOM`, `INSTANCIAS`, `VOLTAR`).
   - Da coluna de botões do mapa, `D-Pad LEFT` salta para a lista de **SERVIÇOS & NPCs**.
   - De **SERVIÇOS & NPCs**, `D-Pad RIGHT` volta para os botões do mapa, e deles `D-Pad RIGHT` volta para a lista de missões.
3. **Pool Fixo de Botões (Fim do `buttons = {}`):**
   - As listas de Zonas (Continentes) e de NPCs passam a utilizar pools fixos pré-alocados (32 botões para Zonas, 24 para NPCs), controlados apenas por `:Show()`, `:Hide()` e `:SetText()`. O timer de 0.5s de atualização de pins não recria frames e não rouba mais o foco.

---

## 2. Mapa Conceitual de Navegação D-Pad

```
┌───────────────────────────────────────────────────────────┐ ┌─────────────────────────────────┐
│ [SERVIÇOS & NPCs] (Pool 24)       [ATUAL]                 │ │ [ LISTA DE MISSÕES ] (Pool 10)  │
│  • Brax Goldgrasp                  [KALIMDOR]             │ │  ► Portador de más notícias     │
│  • Flarnt Tightstitch              [EASTERN KINGDOM]      │ │    DV-500                       │
│  • Toxx Ringweave                  [INSTANCIAS]           │ │    Acidente de mineração        │
│  ... (D-Pad UP/DOWN)               [VOLTAR]               │ │  ... (D-Pad UP/DOWN)            │
│                                    (D-Pad UP/DOWN)        │ ├─────────────────────────────────┤
│                  ( CANVAS DO MAPA )                       │ │ [ DETAIL CARD - RESUMO ]        │
│       L-Stick = Pan Livre  •  LT/RT = Zoom                │ │  Objetivos [0/1] & Recompensas  │
│       Auto-rolagem cancela ao mover L-Stick               │ │  (A) Ler • (X) HUD • (Y) Ações  │
└───────────────────────────────────────────────────────────┘ └─────────────────────────────────┘
                ◄── [D-Pad LEFT] ──              ◄── [D-Pad LEFT] ──
                ── [D-Pad RIGHT] ──►             ── [D-Pad RIGHT] ──►
```

---

## 3. Cronograma de Fases TESTÁVEIS Passo a Passo

---

### 🟢 FASE 1: Modal de Leitura da Missão (Botão [A]) e Ações Diretas ([X] e [Y])
> **Objetivo de Teste:** O jogador está na lista de missões. Ao apertar `[A]`, abre o Modal de Leitura com o texto completo da missão, que rola com `D-Pad UP / DOWN`. O modal possui apenas dois botões: `[X] Rastrear` e `[B] Sair`. Ao apertar `[Y]` na lista, abandona a missão pelo popup oficial da Blizzard. **Zero menus de contexto flutuantes e ZERO erros de segurança da Blizzard.**

- [ ] **1.1.** Criar/reutilizar o frame pré-alocado `ConsoleModeMM_QuestReadingModal` em `UI/MainMenu.lua` (estilo pergaminho nobre com backdrop escurecido, título dourado, scrollframe amplo e texto com formatação limpa).
- [ ] **1.2.** Criar no rodapé do modal os 2 botões de ação reutilizáveis com as texturas de controle:
  - Botão `[X] Rastrear`: alterna o status de rastreio da missão ativa (`IsQuestWatched`, `AddQuestWatch`, `RemoveQuestWatch`).
  - Botão `[B] Sair`: fecha o modal (`Hide()`) e retorna o foco para a missão selecionada na lista.
  - Ambos os botões com scripts de clique de mouse nativos (`OnClick`, `OnEnter`, `OnLeave`).
- [ ] **1.3.** Conectar o preenchimento de dados de forma passiva em `ShowQuestReadingModal(questLogIndex)`:
  - Ler título, nível e objetivos via `GetQuestLogTitle(questLogIndex)`.
  - Ler descrição e objetivos de `GetQuestLogQuestText()` ou da base local traduzida `Data/QuestDB_ptBR.lua` sem acionar `SelectQuestLogEntry` de dentro do clique do gamepad.
- [ ] **1.4.** Em `UI/MainMenuNav.lua`:
  - Tratar `OnConfirm (A)` quando `f.zone == "QMISSOES"`: abre o modal de leitura e define a zona como `QLEITURA`.
  - Na zona `QLEITURA`:
    - `D-Pad UP / DOWN`: rola o scrollframe do texto da missão.
    - `Botão X`: aciona a alternância de rastreamento.
    - `Botão B` / tecla `ESC`: fecha o modal e devolve `f.zone = "QMISSOES"`.
  - Tratar `OnUse (Y)` quando `f.zone == "QMISSOES"`: chama direto o diálogo nativo `StaticPopup_Show("ABANDON_QUEST", questTitle)`.
- [ ] **1.5.** Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 1):**
  - O jogador faz `/reload` no jogo.
  - Abre a aba Missões & Mapa (`SELECT` ou pelo menu).
  - Aperta `[A]` em uma missão: valida se o modal de leitura abre limpo, sem nenhum erro de segurança na tela.
  - Rola o texto da história com o D-Pad para cima e para baixo.
  - Testa o botão `[X]` (rastrear) e fecha com `[B]` ou clicando em Sair com o mouse.
  - Aperta `[Y]` na lista e valida se o popup clássico da Blizzard para abandonar a missão abre perfeitamente.

---

### 🟢 FASE 2: Estabilização com Pool Fixo de Zonas e NPCs (Fim do `buttons = {}`)
> **Objetivo de Teste:** As listas de Zonas (`zoneListFrame`) e de NPCs (`npcListPanel`) utilizam pools fixos de botões pré-alocados. O loop OnUpdate de 0.5s de NPCs não recria mais botões e não interfere na memória durante a execução do jogo.

- [ ] **2.1.** Pool Fixo de Zonas e Instâncias em `UI/MainMenu.lua`:
  - Pré-alocar 32 botões `ConsoleMode_ZoneListButton1..32` como filhos estáveis de `zoneListFrame.scrollChild`.
  - Refatorar `BuildContinentZoneList` e `BuildInstancesListForZone` para **nunca mais** executar `frame.buttons = {}` com `CreateFrame`. Apenas preencher os dados dos botões existentes, dar `:Show()` nos necessários e `:Hide()` no restante do pool.
  - **Preservar a formatação de níveis e instâncias da zona:**
    - Modo `REGIOES`: exibe cada zona com seu intervalo de nível `Nome (min-max)` (ex: `Ashenvale (18-30)`, `Durotar (1-10)`), extraído de `Data/ZoneLevels.lua`.
    - Modo `INSTANCIAS`: exibe as instâncias contextuais da zona atual com seus níveis `Nome (min-max)` (ex: `Blackfathom Deeps (24-32)` em Ashenvale), extraídos de `Data/Instances.lua` e `Data/ZoneLevels.lua`.
    - Rodapé do mapa exibindo: `[D-Pad] Navegar · [A] Entrar · [B] Voltar`.
- [ ] **2.2.** Pool Fixo de NPCs em `UI/MainMenu.lua`:
  - Pré-alocar 24 botões `ConsoleMode_NPCListButton1..24` como filhos estáveis de `npcListPanel.scrollChild`.
  - Refatorar `UpdateNPCServicePins` para reutilizar o pool de 24 botões, atualizando nome, ícone e função do NPC sem recriar objetos.
- [ ] **2.3.** Trava de concorrência (`Nav_focusLock`):
  - Inserir guarda no loop OnUpdate de 0.5s de NPCs: se `MainMenuNav.focus.zone == "QNPCS"`, o loop não altera o layout nem a visibilidade dos botões.
- [ ] **2.4.** Remover chamadas indevidas de `zoneListFrame:Hide()` em rotinas secundárias de highlight.
- [ ] **2.5.** Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 2):**
  - O jogador faz `/reload` no jogo.
  - Interage com o mapa e valida se as listas de NPCs, Zonas com níveis `(min-max)` e Instâncias contextuais continuam exibindo todos os seus dados perfeitamente, sem falhas de layout e com performance estável.

---

### 🟢 FASE 3: Navegação Espacial Direcional (Missões ⇄ Botões do Mapa ⇄ NPCs)
> **Objetivo de Teste:** O jogador navega livremente pelo D-Pad entre as 3 colunas da tela: saindo da Lista de Missões para a coluna de botões do mapa com `D-Pad LEFT`, e dos botões do mapa para o painel de NPCs com outro `D-Pad LEFT`. O caminho inverso com `D-Pad RIGHT` devolve o foco para a lista de missões.

- [ ] **3.1.** Mapeamento das 3 zonas no `UI/MainMenuNav.lua`:
  - `QMISSOES`: Lista de Missões (coluna direita).
  - `QNAV`: Coluna dos 5 botões de navegação do mapa (`ATUAL`, `KALIMDOR`, `EASTERN KINGDOM`, `INSTANCIAS`, `VOLTAR`).
  - `QNPCS`: Painel de Serviços & NPCs (canto superior esquerdo do mapa).
- [ ] **3.2.** Regras de Travessia Horizontal no `OnDirection`:
  - Em `QMISSOES`: `D-Pad LEFT` move para `QNAV` (focando no botão ativo ou no primeiro, `ATUAL`).
  - Em `QNAV`:
    - `D-Pad RIGHT` move de volta para `QMISSOES`.
    - `D-Pad LEFT` move para `QNPCS` (se o painel de NPCs estiver visível).
  - Em `QNPCS`: `D-Pad RIGHT` move de volta para `QNAV`.
- [ ] **3.3.** Regras Verticais (`D-Pad UP / DOWN`):
  - Em `QNAV`: navega sequencialmente entre os 5 botões verticais com realce dourado padrão (`SetVertexColor(1.0, 0.82, 0.20)`).
  - Em `QNPCS`: navega pelos NPCs da lista com auto-scroll vertical.
- [ ] **3.4.** Suprimir hooks residuais do `Cursor.lua` que tentavam gerenciar navegação de missões (`HandleQuestNavigation`).
- [ ] **3.5.** Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 3):**
  - O jogador faz `/reload`.
  - Testa a navegação completa em cruz: desce nas missões, aperta `LEFT` e o foco vai para os botões do mapa; aperta `LEFT` de novo e entra nos NPCs; aperta `RIGHT` duas vezes e volta suavemente para as missões.

---

### 🟢 FASE 4: Ativação dos Botões do Mapa e Seleção de Continente / Zonas / Instâncias
> **Objetivo de Teste:** Estando na coluna de botões do mapa (`QNAV`), apertar `[A]` em `ATUAL` centraliza a zona atual; apertar `[A]` em `KALIMDOR` ou `EASTERN KINGDOM` abre o painel `REGIOES` com as zonas e seus níveis `(min-max)`; apertar `[A]` em `INSTÂNCIAS` abre o painel `INSTANCIAS` com as masmorras da zona atual e seus níveis. O foco entra na lista; `[A]` seleciona e carrega o mapa correspondente; `[B]` fecha a lista e devolve o foco para a coluna de botões (`QNAV`).

- [ ] **4.1.** Em `MainMenuNav.lua`:
  - Tratar `OnConfirm (A)` quando `f.zone == "QNAV"`: aciona o clique do botão selecionado (`ATUAL`, `KALIMDOR`, `EASTERN KINGDOM`, `INSTANCIAS`, `VOLTAR`).
- [ ] **4.2.** Sub-zona `QZONAS`:
  - Quando a lista de zonas/instâncias abrir (`zoneListFrame:Show()`), direcionar o foco para `QZONAS`.
  - Em `QZONAS`:
    - `D-Pad UP / DOWN`: navega pelas zonas/instâncias com scroll suave.
    - `Botão A`: seleciona a zona ou instância, carrega o mapa correspondente e fecha a lista.
    - `Botão B`: cancela, fecha a lista (`zoneListFrame:Hide()`) e devolve o foco para a coluna de botões (`QNAV`).
- [ ] **4.3.** Validação de sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 4):**
  - O jogador faz `/reload`.
  - Navega até `KALIMDOR` no D-Pad e aperta `[A]`: valida o painel `REGIOES` com os níveis `(min-max)`.
  - Navega pelas zonas, escolhe uma com `[A]` e vê o mapa carregar.
  - Navega até `INSTANCIAS` e aperta `[A]`: valida a exibição das instâncias da zona atual com seus níveis `(min-max)`.
  - Testa apertar `[B]` para fechar a lista e voltar o foco para a coluna de botões.

---

### 🟢 FASE 5: Preservação do L-Stick (Pan), LT/RT (Zoom) e Regressão Geral
> **Objetivo de Teste:** O jogador valida que mover o analógico esquerdo (L-Stick) continua movimentando o mapa livremente em qualquer direção, os gatilhos LT/RT continuam controlando o zoom sem qualquer conflito com o D-Pad, e a troca de abas com LB/RB (Bolsas, Magias, Talentos, Missões) mantém todos os focos íntegros.

- [ ] **5.1.** Garantir que `stickPanX` e `stickPanY` continuam operando de forma 100% independente do D-Pad durante todo o tempo em que a aba de Missões estiver ativa.
- [ ] **5.2.** Assegurar que os comandos de zoom `[LT]` e `[RT]` funcionam no mapa em qualquer zona da tela de missões.
- [ ] **5.3.** Teste de troca inter-abas:
  - Ir para Bolsas com `[LB]` → voltar para Missões com `[RB]`: a missão anteriormente selecionada deve permanecer destacada sem piscar.
  - Visitar Livro de Magias e Talentos e certificar que nenhuma outra aba perdeu o comportamento do D-Pad.
- [ ] **5.4.** Validação de sintaxe final via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 5):**
  - O jogador faz `/reload` e realiza o teste geral de controle e mouse em toda a interface do jogo.

---

## 4. Resumo de Arquivos Impactados

| Arquivo | Natureza da Modificação |
| :--- | :--- |
| `docs/plano_de_refatoração_missoes_mapas.md` | **Este documento** de planejamento em fases testáveis. |
| `UI/MainMenu.lua` | Criação do Modal de Leitura de Missão, pools fixos para Zonas (32) e NPCs (24), e remoção de chamadas destrutivas. |
| `UI/MainMenuNav.lua` | Roteador direcional D-Pad para as zonas `QMISSOES`, `QLEITURA`, `QNAV`, `QZONAS`, `QNPCS` e eliminação de nós. |
| `Cursor.lua` | Desativação de rotinas legadas de navegação de missões para evitar concorrência com o `MainMenuNav`. |

---

## 5. Compromisso de Execução
- **SEM PUSH AUTOMÁTICO.**
- **SEM COMMITS INTERMEDIÁRIOS SEM APROVAÇÃO.**
- **PARADA OBRIGATÓRIA NO FIM DE CADA UMA DAS 5 FASES PARA TESTE DO USUÁRIO NO JOGO.**
