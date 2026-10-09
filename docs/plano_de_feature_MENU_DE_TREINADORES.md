# Plano de Feature: MENU DE TREINADORES DE CLASSE & PROFISSÕES (ConsoleMode)

> [!CAUTION]
> ## REGRAS MANDATÓRIAS DE DESENVOLVIMENTO (LEITURA OBRIGATÓRIA)
> 1. **NÃO FAZER PUSH ENQUANTO O USUÁRIO NÃO PEDIR.** Quando pedir, fazer push **UMA VEZ SÓ** e aguardar o próximo pedido explícito para fazer push de novo. Nunca fazer push automático ou por conta própria.
> 2. **WoW VERSÃO 1.12.1 (Interface 11200) / Lua 5.0 Estrito:**
>    - Proibido terminantemente sintaxe moderna (Lua 5.1+): NUNCA usar operador `#t` (usar `table.getn(t)`), `continue`, `goto`, `table.unpack` (usar `unpack`), bitwise (`&`, `|`), `gmatch` (usar `string.gfind`).
> 3. **AVISO DE SEGURANÇA DO WOW (Zero Taint / Warden):**
>    - NÃO usar funções protegidas, NÃO automatizar combate, NÃO violar restrições da UI do WoW.
> 4. **ARQUITETURA MODULAR ISOLADA (FIM DEFINITIVO DO MONÓLITO):**
>    - O `UI/MainMenu.lua` (+17.000 linhas) é um monólito legado e **NÃO DEVE RECEBER NENHUMA LINHA DESTA FEATURE**.
>    - O sistema nascerá como um módulo **100% independente, modular e desacoplado**: `UI/TrainerMenu.lua`.
>    - Será registrado no `ConsoleModeVanilla.toc` e inicializado de forma limpa por eventos em `Core.lua` / `Hooks.lua`.
> 5. **IDENTIDADE VISUAL RIGOROSA & PARIDADE TOTAL COM MERCHANTMENU:**
>    - **ABANDONO TOTAL DA JANELA DA BLIZZARD:** É terminantemente proibido renderizar a janela arcaica `ClassTrainerFrame` de 2004. Toda a interação ocorre na interface nobre do ConsoleMode.
>    - **Dimensões Idênticas ao Comércio:** Mesma largura (`screenW * 0.94`) e altura (`screenH * 0.85`), com limites mínimos de 840x520 e máximos de 1440x920.
>    - **Moldura Oficial 9-Slice:** Esculpida com textura oficial `Interface\AddOns\ConsoleModeVanilla\Media\Carved_9Slides.tga` e dimmer de imersão no fundo.
>    - **Tipografia Nobre:** Aplicada exclusivamente via `ApplyFont()` com `AlegreyaSans-Bold.ttf` e `AlegreyaSans-Medium.ttf`.
>    - **Paleta de Cores Canônica:** Dourado âmbar (`|cffe09a15`), branco puro (`|cffffffff`), verde de sucesso (`|cff1eff00`), vermelho de restrição (`|cffff2020`) e cinza para itens inativos (`|cffaaaaaa`).
>    - **Glifos Reais de Controle:** Ícones gráficos oficiais (`Media\Icons\Xbox\A.tga`, `B.tga`, `X.tga`, `Y.tga`, `RT.tga`, `LS.tga`, etc.).
> 6. **SUPORTE HÍBRIDO OBRIGATÓRIO (CONTROLE GAMEPAD + MOUSE COMPLETO):**
>    - Tudo o que o controle faz deve ser 100% acessível pelo mouse (cliques de seleção, duplo-clique de compra, scroll wheel da lista, botão de fechar no cabeçalho).
> 7. **ARQUITETURA AGNÓSTICA (CLASSE & PROFISSÃO):**
>    - A estrutura deve atender tanto treinadores de classe (Guerreiro, Mago, etc.) quanto treinadores de profissão (Ferraria, Alquimia, etc.), detectando via `GetTrainerType()`.
> 8. **VALIDAÇÃO DE SINTAXE OBRIGATÓRIA:** Todo arquivo alterado deve ser validado com `luac -p` antes de qualquer teste.
> 9. **PARADA CRÍTICA DE FASES:** NUNCA avançar para a fase seguinte sem validação no jogo via `/reload` e aprovação explícita do usuário.

---

## 1. Visão Geral da Feature

Ao interagir com um Treinador de Classe ou Treinador de Profissão no WoW 1.12, o jogo original abre a janela `ClassTrainerFrame` de 2004. No controle (especialmente no Steam Deck), essa janela clássica é extremamente defasada:
- Lista confusa e sem agrupamento inteligente.
- Não oferece comparação direta entre o grau que você já tem no Grimório e o novo grau a ser comprado.
- Não permite selecionar um conjunto de habilidades para compra em carrinho com resumo financeiro.
- Exige uso de cursor virtual do mouse para cada magia individual.

A proposta desta feature é **interceptar a interação com NPCs treinadores** e renderizar uma janela customizada em **Split-View** no mesmo padrão estético e dimensional do `MerchantMenu`:
- **Coluna Esquerda (Catálogo Inteligente):**
  - Barra de busca dinâmica no topo (com suporte a teclado físico, mouse e `VirtualKeyboard` no controle).
  - Seção 1 (Topo): **Disponíveis para Aprender** (foco imediato, subtítulo de nível e tree/categoria, custo).
  - Seção 2 (Meio): **Futuras Habilidades** (agrupadas por Especialização/Tree, com requisito de nível destacado em vermelho).
  - Seção 3 (Base): **Já Aprendidas** (recolhida por padrão para não poluir a tela, expansível com `[A]` ou clique, e com auto-expansão automática ao buscar termos na barra de pesquisa).
- **Coluna Direita (Comparativo em Tempo Real & Detalhes):**
  - Se o jogador já possui um grau anterior: Comparativo lado a lado **[Grau Atual no Grimório] ➔ [Novo Grau do Treinador]**, com destaque em verde para o aumento de dano/cura/efeito.
  - Se a habilidade for inédita: Badge dourada **★ NOVA HABILIDADE ★** com ficha técnica completa (tipo, recarga, custo de recurso e descrição).
  - Em profissões: Reagentes necessários e descrição do item produzido.
- **Sistema de Seleção Múltipla & Modal de Carrinho de Compras:**
  - O jogador pode marcar/desmarcar habilidades com `[A]` ou selecionar todas com `[Y]`.
  - Aperta `[RT]` ou clica para abrir a **Revisão do Treinamento (Carrinho)**: modal centralizado com resumo dos custos, saldo restante, scroll de itens e inspeção com tooltip nativo da Blizzard.
  - Ao confirmar, dispara uma **fila serializada de compra em batch** (ticker de 0.15s, sem risco de perda de pacotes e com zero taint).

---

## 2. Diagramas de Design Visual (ASCII Art - Alinhamento Fixo 94 Colunas)

### 2.1. Estado Normal (Seção "Já Aprendidas" Recolhida)

```text
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ [ÍCONE] TREINAMENTO DE CLASSE                14g 52s 10c  •  [B] FECHAR                      │
│ Treinador: Wu Shen <Treinador de Guerreiros>                                                 │
├──────────────────────────────────────────────┬───────────────────────────────────────────────┤
│ CATÁLOGO DE HABILIDADES      (4 Disponíveis) │ DETALHES & EVOLUÇÃO DA HABILIDADE             │
├──────────────────────────────────────────────┼───────────────────────────────────────────────┤
│ [ 🔍 Buscar habilidade...                  ] │ ┌─────────┐  Golpe Heroico                    │
│                                              │ │         │  Especialização: Armas            │
│ ▼ DISPONÍVEIS PARA APRENDER (4)              │ │ [ÍCONE] │  Custo: 15s 00c  •  Requer: Nv.16 │
│ ──────────────────────────────────────────── │ └─────────┘                                   │
│ ► [Íc] Golpe Heroico (Grau 3)        15s 00c │ ───────────────────────────────────────────── │
│        Nv. 16  •  Armas                      │ [GRAU ATUAL NO SEU GRIMÓRIO]                  │
│                                              │ Grau 2 • 15 de Fúria • Próximo Ataque         │
│   [Íc] Trovoada (Grau 2)              8s 50c │ "Um ataque violento que aumenta o dano corpo  │
│        Nv. 16  •  Proteção                   │  a corpo em 32."                              │
│                                              │                                               │
│ ▼ HABILIDADES FUTURAS (POR TREE)             │                ▼ EVOLUÇÃO                     │
│ ──────────────────────────────────────────── │                                               │
│ ◆ Árvore: Armas                              │ [NOVO GRAU A SER APRENDIDO]                   │
│   [Íc] Cutilada (Grau 1)             25s 00c │ Grau 3 • 15 de Fúria • Próximo Ataque         │
│        Requer Nv. 20  •  Armas               │ "Um ataque violento que aumenta o dano corpo  │
│                                              │  a corpo em 58."                              │
│ ◆ Árvore: Fúria                              │ ───────────────────────────────────────────── │
│   [Íc] Executar (Grau 1)              1g 20s │ COMPARATIVO DE MUDANÇAS:                      │
│        Requer Nv. 24  •  Fúria               │ ▲ +26 Dano Adicional (32 ➔ 58)                │
│                                              │ Custo de Fúria: Inalterado (15)               │
│ ▶ JÁ APRENDIDAS (14)  [A / Clique] Expandir  │ ───────────────────────────────────────────── │
│ ──────────────────────────────────────────── │ Saldo restante após treino: 14g 37s 10c       │
│   (Seção recolhida - auto-expande na busca)  │                                               │
│                                              │                                               │
│ ... (Scroll vertical com D-Pad Cima/Baixo)   │                                               │
│                                              │                                               │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│ BARRA DE AÇÕES DO CONTROLE & MOUSE:                                                          │
│ [A / Clique] Marcar / Expandir   •   [RT] Revisar Carrinho (0)   •   [Y] Marcar Todas        │
│ [D-Pad / Scroll] Navegar   •   [LS] Focar Busca   •   [X] Limpar Busca   •   [B] Fechar      │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2. Estado Expandido (Jogador Abriu a Seção "Já Aprendidas" ou Usou a Busca)

```text
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ [ÍCONE] TREINAMENTO DE CLASSE                14g 52s 10c  •  [B] FECHAR                      │
│ Treinador: Wu Shen <Treinador de Guerreiros>                                                 │
├──────────────────────────────────────────────┬───────────────────────────────────────────────┤
│ CATÁLOGO DE HABILIDADES      (4 Disponíveis) │ DETALHES & EVOLUÇÃO DA HABILIDADE             │
├──────────────────────────────────────────────┼───────────────────────────────────────────────┤
│ [ 🔍 Buscar habilidade...                  ] │ ┌─────────┐  Golpe Heroico                    │
│                                              │ │         │  Especialização: Armas            │
│ ▼ HABILIDADES FUTURAS (POR TREE)             │ │ [ÍCONE] │  Status: Já Conhecido no Grimório │
│ ──────────────────────────────────────────── │ └─────────┘                                   │
│ ◆ Árvore: Armas                              │ ───────────────────────────────────────────── │
│   [Íc] Cutilada (Grau 1)             25s 00c │ [HABILIDADE JÁ APRENDIDA]                     │
│        Requer Nv. 20  •  Armas               │ Grau 2 • 15 de Fúria • Próximo Ataque         │
│                                              │                                               │
│ ▼ JÁ APRENDIDAS (14)  [A / Clique] Recolher  │ "Um ataque violento que aumenta o dano corpo  │
│ ──────────────────────────────────────────── │  a corpo em 32."                              │
│ ◆ Árvore: Armas                              │                                               │
│ ► [Íc] Golpe Heroico (Grau 2)    Já Aprendid │ ───────────────────────────────────────────── │
│        Nv. 8  •  Armas                       │ INFORMAÇÕES DE REGISTRO:                      │
│                                              │ • Aprendido no Nível: 8                       │
│   [Íc] Golpe Heroico (Grau 1)    Já Aprendid │ • Status: Atualmente ativo no seu Grimório    │
│        Nv. 1  •  Armas                       │ • Próximo Upgrade: Grau 3 (Disponível no Nv.16│
│                                              │ ───────────────────────────────────────────── │
│   [Íc] Rend (Grau 1)             Já Aprendid │ Esta habilidade já faz parte do seu arsenal.  │
│        Nv. 4  •  Armas                       │ Não há custo adicional.                       │
│                                              │                                               │
│ ◆ Árvore: Fúria                              │                                               │
│   [Íc] Brado de Batalha (Grau 1) Já Aprendid │                                               │
│        Nv. 1  •  Fúria                       │                                               │
│                                              │                                               │
│ ... (Scroll vertical com D-Pad Cima/Baixo)   │                                               │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│ BARRA DE AÇÕES DO CONTROLE & MOUSE:                                                          │
│ [A / Clique] Recolher Seção   •   [RT] Revisar Carrinho (0)   •   [Y] Marcar Todas           │
│ [D-Pad / Scroll] Navegar   •   [LS] Focar Busca   •   [X] Limpar Busca   •   [B] Fechar      │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3. Modal de Confirmação do Carrinho de Treinamento (Aberto com [RT] ou Clique)

```text
┌──────────────────────────────────────────────────────────────────────┐
│ CARRINHO DE TREINAMENTO (3 Habilidades Selecionadas)                 │
├──────────────────────────────────────────────────────────────────────┤
│ Habilidade                                                  Custo    │
├──────────────────────────────────────────────────────────────────────┤
│ ► [✓] Golpe Heroico (Grau 3)                             15s 00c     │
│       Nv. 16  •  Armas                                               │
│                                                                      │
│   [✓] Trovoada (Grau 2)                                   8s 50c     │
│       Nv. 16  •  Proteção                                            │
│                                                                      │
│   [✓] Provocar (Grau 1)                                  12s 00c     │
│       Nv. 14  •  Proteção                                            │
│                                                                      │
│   ... (Scroll vertical com D-Pad se houver mais itens no carrinho)   │
│ ──────────────────────────────────────────────────────────────────── │
│ RESUMO FINANCEIRO:                                                   │
│ • Custo Total das Selecionadas:                     35s 50c          │
│ • Seu Saldo Atual:                              14g 52s 10c          │
│ • Saldo Restante após Treinamento:              14g 16s 60c          │
│ ──────────────────────────────────────────────────────────────────── │
├──────────────────────────────────────────────────────────────────────┤
│ [A / Clique] Confirmar Treinamento   •   [B / Clique] Cancelar       │
│ [D-Pad] Navegar Lista (Exibe Tooltip Nativo)   •   [X] Desmarcar Item│
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. Mapeamento de Controles & Texturas Gráficas Oficiais

O rodapé do menu e as dicas contextuais utilizarão exclusivamente as texturas oficiais de controle embutidas em `Interface\AddOns\ConsoleModeVanilla\Media\Icons\Xbox\`:

| Ação | Glifo Gráfico | Arquivo de Textura | Comportamento no Controle / Mouse |
| :--- | :--- | :--- | :--- |
| **Marcar / Expandir** | `[A]` | `Media\Icons\Xbox\A.tga` | Marca/desmarca habilidade ou expande/recolhe seção |
| **Fechar / Cancelar** | `[B]` | `Media\Icons\Xbox\B.tga` | Fecha o modal de carrinho ou fecha o treinador (`CloseTrainer()`) |
| **Limpar / Desmarcar** | `[X]` | `Media\Icons\Xbox\X.tga` | Limpa a barra de busca ou desmarca item no carrinho |
| **Marcar Todas** | `[Y]` | `Media\Icons\Xbox\Y.tga` | Seleciona todas as habilidades disponíveis de uma vez |
| **Revisar e Comprar** | `[RT]` | `Media\Icons\Xbox\RT.tga` | Abre o modal do Carrinho de Treinamento com as selecionadas |
| **Focar Busca** | `[LS]` | `Media\Icons\Xbox\LS.tga` | Foca o EditBox de busca e abre o VirtualKeyboard no controle |
| **Navegar Catálogo** | `[D-Pad]` | `Media\Icons\Xbox\navigate_all_directions.tga` | Scroll vertical com hold-to-repeat contínuo |
| **Clique / Roda** | Mouse | Mouse Nativo | Clique seleciona, duplo-clique compra, scroll rola a lista |

---

## 4. Cronograma de Fases TESTÁVEIS Passo a Passo

Cada fase foi desenhada para ser **100% testável no jogo imediatamente após a sua conclusão**, com parada mandatória para validação.

---

### 🟢 FASE 1: Detecção e Interceptação Segura do Treinador
> **Objetivo de Teste:** O jogador clica em qualquer Treinador de Classe ou Profissão no jogo e vê que o addon interceptou a ação com sucesso, suprimiu com segurança o `ClassTrainerFrame` nativo da Blizzard e imprimiu a mensagem de diagnóstico limpa no chat com o nome do NPC e o tipo de treinador (`class` ou `tradeskill`).

- [ ] Criar arquivo modular e isolado `UI/TrainerMenu.lua`.
- [ ] Registrar `UI/TrainerMenu.lua` no `ConsoleModeVanilla.toc`.
- [ ] Criar frame de eventos ouvindo `TRAINER_SHOW`, `TRAINER_UPDATE`, `TRAINER_CLOSED` e `PLAYER_MONEY`.
- [ ] Suprimir o frame nativo `ClassTrainerFrame` com segurança (`SetAlpha(0)`, `EnableMouse(false)`, mover off-screen sem causar *taint*).
- [ ] Ler metadados da interação: nome do NPC (`UnitName("npc")`), tipo de treinador (`GetTrainerType()`) e total de serviços (`GetNumTrainerServices()`).
- [ ] Exibir mensagem de confirmação no chat: `[ConsoleMode] Treinador detectado: <Nome> (Tipo: <Classe/Profissão>, <X> serviços)`.
- [ ] Garantir fechamento seguro via `TRAINER_CLOSED` ou ao afastar-se do NPC.
- [ ] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 1):** O jogador recarrega a UI (`/reload`), interage com um treinador de classe e valida se a janela velha da Blizzard sumiu e o log limpo apareceu no chat.

---

### 🟢 FASE 2: Esqueleto Visual Responsivo e Idêntico ao MerchantMenu (Canvas Split-View)
> **Objetivo de Teste:** Ao interagir com o treinador, abre o esqueleto visual completo da nova interface com a mesma moldura 9-slice esculpida, dimmer translúcido, dimensões proporcionais exatas do MerchantMenu, cabeçalho e rodapé com os glifos oficiais do controle.

- [ ] Construir a janela principal responsiva (`w = screenW * 0.94`, `h = screenH * 0.85`, limites 840x520 a 1440x920).
- [ ] Aplicar moldura 9-slice esculpida (`Carved_9Slides.tga`) e dimmer de imersão de fundo.
- [ ] Construir o Cabeçalho: Título dinâmico (`TREINAMENTO DE CLASSE` ou `TREINAMENTO DE PROFISSÃO`), nome do NPC em dourado (`|cffe09a15`), saldo de moedas do jogador e botão Fechar estilizado no canto superior direito.
- [ ] Estruturar as duas colunas:
  - Coluna Esquerda: painel do catálogo com moldura interna e placeholder.
  - Coluna Direita: painel de detalhes/comparativo com moldura interna e placeholder.
- [ ] Montar a barra de rodapé com as texturas gráficas reais dos botões de controle (`A.tga`, `B.tga`, `X.tga`, `Y.tga`, `RT.tga`, `LS.tga`).
- [ ] Vincular botão `[B]` / tecla `ESC` / clique no botão Fechar para chamar `CloseTrainer()`.
- [ ] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 2):** O jogador interage com o treinador e visualiza o canvas visual do ConsoleMode na tela com fechamento limpo.

---

### 🟢 FASE 3: Catálogo Estruturado, Seções com Collapse e Barra de Pesquisa
> **Objetivo de Teste:** O catálogo da esquerda exibe as três seções bem estruturadas (Disponíveis no topo, Futuras por Tree no meio, e Já Aprendidas recolhidas na base). O jogador pode navegar com o D-Pad/mouse, expandir a seção Já Aprendidas com `[A]`/clique, e usar a barra de pesquisa para filtrar em tempo real com auto-expansão.

- [x] Implementar scanner do catálogo do treinador via `GetNumTrainerServices()` e `GetTrainerServiceInfo(index)`.
- [x] Agrupar itens em 3 listas lógicas:
  - 1. **Disponíveis:** `category == "available"`.
  - 2. **Futuras:** `category == "unavailable"` agrupadas pelas escolas/trees de classe.
  - 3. **Já Aprendidas:** `category == "used"` agrupadas pelas escolas/trees.
- [x] Construir as linhas visuais (ícone 32x32, nome da magia, rank, nível requerido e custo).
- [x] Implementar comportamento de seções e árvores colapsáveis (recolhidas por padrão, alternam com `[A]` ou clique do mouse).
- [x] Criar a Barra de Pesquisa com foco bidirecional via D-Pad (UP do topo), clique de mouse, atalho `[LS]` e ativação do `VirtualKeyboard` desacoplado (`ConsoleMode.VirtualKeyboard`) ao apertar `[A]` ou clicar na barra.
- [x] Conectar filtro de texto em tempo real: ao digitar qualquer termo, as seções e árvores auto-expandem caso contenham resultados correspondentes.
- [x] Implementar navegação vertical por D-Pad com sistema de hold-to-repeat suave e scroll contínuo com a roda do mouse.
- [x] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 3):** O jogador navega por todas as seções do catálogo, expande a seção de já aprendidas e testa a busca em tempo real.

---

### 🟢 FASE 4: Painel de Detalhes e Comparativo de Ranks (Grimório vs Treinador)
> **Objetivo de Teste:** Ao navegar pelas habilidades no catálogo, a coluna da direita exibe os detalhes completos da habilidade focada. Se o jogador já possui um grau anterior no Grimório, mostra o comparativo lado a lado destacando em verde os aumentos de dano/cura. Se for uma magia inédita, exibe a badge dourada "NOVA HABILIDADE".

- [x] Implementar varredura do Grimório do jogador (`GetSpellName(i, BOOKTYPE_SPELL)`) para indexar os ranks atuais que o personagem já conhece.
- [x] Montar o cabeçalho do painel direito: ícone ampliado, nome da habilidade, especialização, custo e nível requerido.
- [x] Construir o bloco de comparação:
  - **Card do Grau Atual:** Descrição, custo de recurso e valores do rank existente no Grimório.
  - **Seta de Evolução (`▼ EVOLUÇÃO`)**.
  - **Card do Novo Grau:** Descrição e novos valores oferecidos pelo treinador.
  - **Diferenças em Destaque:** Exibir em verde (`|cff1eff00`) acréscimos numéricos (ex: `▲ +26 Dano Adicional`).
- [x] Construir o modo **Nova Habilidade**: quando a magia não possui rank anterior, renderizar o badge `★ NOVA HABILIDADE DE CLASSE ★` com ficha técnica completa.
- [x] Suporte a Profissões: quando `GetTrainerType() == "tradeskill"`, renderizar lista de reagentes/materiais necessários e o item criado pela receita.
- [x] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 4):** O jogador foca em magias de upgrade e magias novas, checando se a comparação de evolução reflete os valores reais do jogo.

---

### 🟢 FASE 5: Sistema de Seleção Múltipla & Modal de Carrinho de Compras
> **Objetivo de Teste:** O jogador seleciona múltiplas habilidades com `[A]` (ou clica nelas), vê o total acumulado no cabeçalho, pode marcar todas com `[Y]`, e abre o modal do Carrinho de Treinamento com `[RT]`. No modal, inspeciona as magias com o tooltip nativo da Blizzard, desmarca itens com `[X]` e visualiza o resumo financeiro exato.

- [x] Implementar estado de seleção múltipla (`selectedCart = {}`) no catálogo:
  - Apertar `[A]` ou clicar em uma habilidade disponível alterna o checkbox visual `[✓]`.
  - Atalho `[Y]`: marca todas as disponíveis ou desmarca todas.
  - Atualizar o contador no cabeçalho e na legenda: `[RT] Revisar Carrinho (X) [Yg Zs]`.
- [x] Construir o Modal do Carrinho de Treinamento centralizado:
  - Lista scrollável das habilidades marcadas com custo individual.
  - Painel de Resumo Financeiro: Custo Total, Saldo Atual e Saldo Restante após a compra.
  - Botão `[X]` para remover itens do carrinho diretamente no modal.
  - Ancorar o `GameTooltip` oficial do WoW ao lado do modal ao navegar pela lista com o D-Pad/mouse.
- [x] Vincular botões do modal: `[A]` para Confirmar Compra e `[B]` para Cancelar e retornar ao catálogo.
- [x] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 5):** O jogador monta carrinhos de compras variados, abre o modal, inspeciona tooltips e ajusta a seleção com segurança.

---

### 🟢 FASE 6: Fila Serializada de Compra em Batch, Sons e Homologação
> **Objetivo de Teste:** Ao confirmar a compra no modal do carrinho, o addon executa a compra de todas as habilidades selecionadas em sequência sem falhas, toca efeitos sonoros do jogo, atualiza o saldo e o Grimório instantaneamente e emite relatório limpo no chat.

- [x] Implementar fila de compra sequencial com ticker (`OnUpdate` a cada 0.15s, molde idêntico ao `AutoSell` do `MerchantMenu`):
  - Verifica saldo antes de cada compra.
  - Chama `BuyTrainerService(index)` para cada item selecionado.
  - Avança na fila com segurança sem sobrecarregar a comunicação com o servidor do WoW 1.12.
- [x] Tratar evento `TRAINER_UPDATE` para atualizar o catálogo dinamicamente (as habilidades compradas saem de Disponíveis e passam para Já Aprendidas).
- [x] Adicionar efeitos sonoros oficiais da Blizzard (`PlaySound("SPELLBOOKSPELLCLICK")` e som de moedas ao concluir).
- [x] Testar em Treinadores de Classe de diversas cidades e em Treinadores de Profissão (Ferraria, Alquimia, Primeiros Socorros).
- [x] Validação final de regressão e checagem de sintaxe estrita com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 6):** Homologação completa no cliente de jogo com gravação/testes reais.

---

## 5. Estrutura de Arquivos

```
Interface/AddOns/ConsoleModeVanilla/
├── ConsoleModeVanilla.toc          <-- Adiciona UI/TrainerMenu.lua
├── UI/
│   ├── TrainerMenu.lua             <-- NOVO MÓDULO 100% ISOLADO (Catálogo, Busca, Comparador, Carrinho, Batch)
│   ├── MerchantMenu.lua            <-- Intocado (referência arquitetural)
│   ├── MainMenu.lua                <-- Intocado (preservando o monólito sem novos inchaços)
│   └── ...
├── Hooks.lua                       <-- Interceptação de TRAINER_SHOW / ClassTrainerFrame
└── docs/
    └── plano_de_feature_MENU_DE_TREINADORES.md <-- Este documento oficial de planejamento
```
