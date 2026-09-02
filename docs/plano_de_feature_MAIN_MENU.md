# Plano de Feature: MAIN MENU (Menu Principal Console Hub)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido usar operadores de Lua 5.1+ (como `#table`, usar `table.getn(t)` ou `getn(t)`).
> 3. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 4. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem o comando e autorização explícita do usuário.
> 5. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem fazer uma parada crítica, solicitar a validação do usuário no jogo via `/reload` e aguardar seu feedback/aprovação.

---

## 1. Visão Geral

O **MAIN MENU** é um Hub centralizado de interface em tela cheia projetado especificamente para o **ConsoleMode - Vanilla** (WoW 1.12.1 / Turtle WoW / Lua 5.0), inspirado na consagrada interface de inventário e menu de *The Legend of Zelda: Breath of the Wild / Tears of the Kingdom*.

O objetivo é substituir a sobreposição clássica de janelas soltas e flutuantes da Blizzard por uma experiência imersiva, unificada e 100% navegável via controle (Gamepad / Steam Deck), integrando **Bolsas categorizadas**, **Livro de Habilidades (Spellbook)**, **Equipamentos**, **Status e Buffs**, além de um **Modelo 3D Integrado do Jogador** com animações e câmera dinâmica.

---

## 2. Investigação Técnica: Modelo 3D e Fundo Integrado

### A. Transparência Nativa do `PlayerModel` (Sem molduras/caixas)
* No WoW 1.12.1, o widget `CreateFrame("PlayerModel", ...)` **não possui textura de fundo ou borda por padrão**. Ele é uma viewport 3D puramente transparente que desenha apenas a malha 3D do personagem, iluminação e sombras.
* Isso significa que o personagem fica **perfeitamente integrado ao fundo do menu**, sem aquela "caixa cinza de preview" do WoW clássico. Ele parecerá estar de pé dentro do próprio menu sobre o fundo (cor sólida ou pergaminho), exatamente como o Link no Zelda.
* A lista de equipamentos (à esquerda), os atributos e a lista de buffs (à direita do personagem) ficam sobrepostos e integrados diretamente no mesmo espaço visual.

### B. Isolamento e Performance na Troca de Abas
* O painel do personagem à esquerda (Modelo 3D, Equipamentos, Stats, Buffs) é persistente e **nunca é recarregado ou destruído** durante a navegação.
* A barra de abas `[L1] ... [R1]` fica situada **no topo do Container da Direita**.
* Ao trocar de aba, apenas o conteúdo do container da direita é alternado (`AbaBolsas:Hide()` / `AbaSpellbook:Show()`), economizando ciclos de processamento e mantendo a transição instantânea e fluida.

---

## 3. Referências Visuais

* **Referência 1 (Estrutura de Abas, Grid e Painel Fixo de Detalhes):**  
  `C:\Users\rodri\AppData\Local\Temp\orca-paste-1788036388358-bcee052e-8f9d-4887-9991-8c0c02a691a5.png`  
  *Inspiração:* Navegação de abas no topo do container de conteúdo com botões de ombro (L/R), grid de itens destacados com cursor brilhante e painel fixo de detalhes/informações no canto inferior.

* **Referência 2 (Exibição de Status e Lista de Buffs Ativos):**  
  `C:\Users\rodri\AppData\Local\Temp\orca-paste-1788037599542-2e8f5b65-3f87-4fec-a245-b371e1c1d4bf.png`  
  *Inspiração:* Exibição limpa de atributos e lista vertical de efeitos/buffs ativos ao lado do modelo do personagem (ícone + nome do efeito).

---

## 4. Arquitetura Visual e Layout Integrado

```
+===================================================================================================================+
|                                         MENU PRINCIPAL (CONSOLE HUB)                                              |
+-------------------------------------------------------------------+-----------------------------------------------+
|                    PAINEL INTEGRADO DO PERSONAGEM                 |        CONTAINER DE CONTEUDO DA ABA           |
|                 (Modelo 3D Fluido sem Fundo / Canvas Unico)       |                                               |
|                                                                   |  +-----------------------------------------+  |
|  [EQUIPAMENTOS]          [PERSONAGEM 3D]       [STATUS & BUFFS]   |  | [L1]  (Bolsa) BOLSAS  (Spells) SPELLS  [R1] |  |
|                                                                   |  +-----------------------------------------+  |
|  [O] Cabeca            /===============\      Nivel 60 Guerreiro  |  CATEGORIA: EQUIPAMENTOS                      |
|  [O] Colar            /                 \     HP:  4500 / 4500    |  +----+ +----+ +----+ +----+ +----+ +----+    |
|  [O] Ombro           |   MODELO 3D DO    |    Rage: 100 / 100     |  | [X]| |    | |    | |    | |    | |    |    |
|  [O] Capa            |     JOGADOR       |    Ouro: 125g 40s      |  +----+ +----+ +----+ +----+ +----+ +----+    |
|  [O] Peito           |   RENDERIZADO     |                        |  +----+ +----+ +----+ +----+ +----+ +----+    |
|  [O] Punho           |   TRANSPARENTE    |    Forca: 210          |  |    | |    | |    | |    | |    | |    |    |
|  [O] Luvas           |   DIRETO SOBRE    |    Agilidade: 115      |  +----+ +----+ +----+ +----+ +----+ +----+    |
|  [O] Cinto           |     O FUNDO       |    Vigor: 190          |  CATEGORIA: CONSUMIVEIS                       |
|  [O] Pernas          |                   |    Armadura: 4120      |  +----+ +----+ +----+ +----+ +----+ +----+    |
|  [O] Botas           |   (Animacoes e    |                        |  |    | |    | |    | |    | |    | |    |    |
|  [O] Anel 1          |    Giro Livre)    |    BUFFS ATIVOS:       |  +----+ +----+ +----+ +----+ +----+ +----+    |
|  [O] Anel 2           \                 /     [+] Battle Shout    |                                               |
|  [O] Berloque 1        \===============/      [*] MotW (35m)      |  -------------------------------------------  |
|  [O] Berloque 2                               [~] Comida (12m)    |  PAINEL FIXO DE DETALHES (Tooltip Zelda)      |
|  [O] Arma Principal   Thrallgar <Guild>                           |  [ICONE] Thunderfury, Blessed Blade...        |
|  [O] Arma Secundaria  Orc Guerreiro                               |  Espada de Uma Mao  -  Dano: 44 - 115 (1.90)  |
|  [O] Longo Alcance                                                |  "Chance ao acertar: Dispara um raio..."      |
+===================================================================================================================+
| (D-Pad/L-Stick) Navegar   |   (A) Selecionar/Usar   |   (Y) Menu de Contexto   |   (B) Fechar   |   (R-Stick) Girar 3D   |
+===================================================================================================================+
```

---

## 5. Componentes do Sistema

### 5.1. Painel Esquerdo: Personagem Integrado, Equipamentos, Status e Buffs
1. **Lista de Equipamentos (À Esquerda do Personagem):**
   * Disposição vertical em linhas contendo o ícone do slot/item à esquerda e o nome completo do equipamento por extenso.
   * O cursor do controle navega diretamente sobre os equipamentos para inspecionar, trocar ou desequipar itens.
2. **Visualizador 3D Integrado (`PlayerModel` / `DressUpModel`):**
   * Renderização sem caixas/bordas, desenhada diretamente no plano de fundo comum do menu (`model:SetUnit("player")`).
   * **Giro Manual 360°:** O analógico direito (*R-Stick*) permite inspecionar o personagem de qualquer ângulo.
3. **Status Base e Atributos (À Direita do Personagem):**
   * Nível, Classe, Barras de Vida e Recurso (Mana/Rage/Energy), Ouro/Prata/Cobre.
   * Atributos primários (Força, Agilidade, Vigor, Intelecto, Espírito, Armadura, Poder de Ataque, Resistências Elementais).
4. **Lista de Buffs Ativos (Abaixo dos Status Base):**
   * Lista vertical inspirada no Zelda TotK/BotW com ícone do buff, nome do efeito e duração restante.

---

### 5.2. Sistema Dinâmico de Animações 3D e Câmera (`PlayerModel`)

O modelo 3D reage dinamicamente através da API nativa `model:SetSequence(animID)`:

#### A. Animações por Tipo de Ação
* **Consumíveis (Ao Usar item na bolsa):**
  * *Comida / Bebida / Poção:* Dispara animação de comer, beber ou pose de comemoração (*Cheer/Flex*), acompanhada do som característico.
  * *Bandagens / Pergaminhos:* Dispara animação de canalização (*ChannelCastOmni*) ou ajoelhar.
* **Equipamentos (Ao Equipar/Trocar peça):**
  * *Arma 1H / 2H:* Dispara saque e golpe no ar (*Attack1H / Attack2H*) ou postura de prontidão de combate (*Ready1H / Ready2H*).
  * *Escudo:* Dispara postura de bloqueio com escudo (*ShieldBlock*).
  * *Armaduras (Peitoral, Elmo, etc.):* Dispara pose de força (*Roar / Flex / Cheer*).
* **Spellbook (Ao Navegar o Cursor sobre Habilidades):**
  * *Magias com Tempo de Lançamento (Fireball, Heal):* O modelo entra na postura de conjuração com mãos erguidas (*SpellPrecast / ReadySpellOmni*).
  * *Habilidades Físicas / Melee (Golpe Heroico, Sinister Strike):* O modelo assume postura de combate corpo a corpo.
  * *Gritos / Buffs (Battle Shout, Mark of the Wild):* Dispara animação de rugido ou conjuração em área (*Roar / SpellCastArea*).
  * *Furtividade (Stealth / Prowl):* O modelo assume a postura agachada de stealth.
* **Retorno Automático ao Repouso (Idle):**
  * Após a conclusão da animação (~1.5 a 2 segundos), o modelo retorna suavemente para a postura padrão de respiração/repouso (*Stand - Sequence 0*).

#### B. Câmera Dinâmica e Zoom Inteligente
* Ao navegar para itens de **Elmo, Colar ou Ombros**, a câmera aproxima suavemente (*Zoom In*) no rosto/busto do personagem.
* Ao navegar para **Calças ou Botas**, a câmera se afasta (*Zoom Out*) para exibir o corpo inteiro.

#### C. Provador Dinâmico ao Vivo ("Live TryOn" na Bolsa)
* **Alta Performance com Ícones 2D no Grid:** O grid de itens permanece 100% leve e fluido utilizando ícones 2D nativos com molduras de qualidade e brilho (garantindo 0 impacto em FPS).
* **Experimentação em Tempo Real:** Ao navegar com o D-Pad sobre qualquer arma, escudo ou peça de armadura na bolsa, o modelo 3D do personagem à esquerda **experimenta a peça instantaneamente** via `model:TryOn(itemLink)` e assume a postura/animação correspondente.
* **Restauração Automática:** Ao mover o cursor para consumíveis, reagentes ou slots vazios, o modelo 3D restaura automaticamente o conjunto de equipamentos original que o jogador está vestindo (`model:SetUnit("player")`).

---

### 5.3. Painel Direito: Container de Conteúdo e Abas

#### Barra de Abas Interna (`[L1]` / `[R1]`)
* Localizada exclusivamente no topo do container da direita.
* Alternância rápida via botões de ombro (**L1 / R1** ou **LB / RB**).
* Ícone representativo com o título da aba destacada em evidência.
* Transição de conteúdo sem recarregar o painel do personagem à esquerda.

#### Aba 1: Bolsas / Inventário (BAG)
* Grid unificado consolidando todas as bolsas equipadas em um único painel.
* **Separação por Categorias:** Itens organizados visualmente em blocos ou filtros:
  * *Equipamentos* (Armas e Armaduras)
  * *Consumíveis* (Poções, Comidas, Bebidas, Elixires)
  * *Materiais / Reagentes* (Ervas, Minérios, Peles, Tecidos)
  * *Itens de Missão e Diversos*
* Navegação espacial 2D em grade via **D-Pad / Analógico Esquerdo** com moldura de destaque brilhante.

#### Aba 2: Livro de Habilidades (SPELLBOOK)
* Lista ou grid organizado de todas as magias e habilidades do jogador divididas por abas/escolas de classe.
* Permite visualizar detalhes da habilidade e atribuir atalhos diretamente para a action bar do controle.

---

### 5.4. Painel Fixo de Detalhes (Estilo Zelda Tooltip)
* Localizado no canto inferior direito do container.
* Em vez de tooltips flutuantes de mouse que cobrem itens vizinhos, todas as informações do item ou feitiço atualmente focado aparecem em uma área fixa e elegante.
* Exibe:
  * Ícone grande do elemento
  * Nome formatado com a cor de qualidade do item (Pobre, Comum, Incomum, Raro, Épico, Lendário)
  * Tipo de item / Escola de magia
  * Atributos, dano, velocidade, requerimentos de nível
  * Descrições completas, efeitos "Uso:", "Equip:" e "Chance ao acertar:"

---

### 5.5. Barra de Atalhos e Dicas do Controle (Rodapé)
* Linha inferior fixa com os botões físicos do controle e suas respectivas ações contextuais:
  * **(D-Pad / L-Stick):** Navegar no menu / grid
  * **(A):** Selecionar / Usar item / Abrir
  * **(Y):** Menu de Contexto / Ações (Aproveitando o sistema já existente)
  * **(B):** Voltar / Fechar Menu
  * **(R-Stick):** Girar modelo 3D do personagem

---

## 6. Estilo Visual, Textura e Sistema 9-Slice

### 6.1. Textura de Fundo Selecionada (`Carved_9Slides`)
* **Arquivo Base:** `Carved_9Slides.png` (Pacote *Tiny Swords*).
* **Dimensões Originais:** 192x192 pixels, composto por uma grade 3x3 perfeita de fatias de **64x64 pixels**.
* **Padrão:** Pergaminho/madeira talhada com bordas recortadas estilizadas.

### 6.2. Implementação do Sistema 9-Slice no WoW 1.12.1 (Padrão Unity)
Para evitar que a textura fique esticada, borrada ou deformada em telas maiores (Steam Deck, 1080p, 4K), o menu utiliza um renderizador customizado de **9-Slice (9 Fatias)** via sub-texturas e coordenadas UV (`SetTexCoord`):

```
+----------------+----------------+----------------+
|  Canto Sup.Esq |   Borda Topo   | Canto Sup.Dir  |  (Cantos: Tamanho fixo)
|    (Fixo)      | (Estica Horiz) |    (Fixo)      |
+----------------+----------------+----------------+
|   Borda Esq.   |     Centro     |   Borda Dir.   |  (Bordas: Esticam em 1 eixo)
| (Estica Vert)  |  (Preenche 2D) | (Estica Vert)  |
+----------------+----------------+----------------+
| Canto Inf.Esq  |  Borda Fundo   | Canto Inf.Dir  |  (Centro: Preenchimento total)
|    (Fixo)      | (Estica Horiz) |    (Fixo)      |
+----------------+----------------+----------------+
```

1. **4 Cantos (Tamanho Fixo):** Mantêm a escala fixa e nítida sem esticar.
2. **4 Bordas (Eixo Único):** As bordas superior/inferior esticam apenas na horizontal; as laterais esticam apenas na vertical.
3. **Centro (Preenchimento):** Preenche o interior do menu.
4. **Mapeamento UV (`SetTexCoord`):** Recorte preciso de cada quadrante da matriz.

### 6.3. Requisitos Técnicos do Motor do WoW Vanilla
* **Conversão POT (Power of Two):** O WoW 1.12 requer dimensões de textura em potências de 2. A matriz de 192x192 é embutida em um canvas de **256x256** `.tga`.
* **Canal Alpha:** Formato **Targa 32-bit (TGA com Alpha de transparência)** para recortar perfeitamente as partes externas do pergaminho.

### 6.4. Bordas e Destaques
* **Seleção:** Molduras elegantes com destaques luminosos no elemento em foco (cursor dourado/brilhante estilo Zelda).
* **Feedback Sonoro:** Execução de sons nativos do cliente da Blizzard para confirmação, cancelamento e transição de abas.

---

## 7. Plano de Implementação em 12 Fases Incrementais

### **FASE 1: A "Casca" e a Textura 9-Slice (O Canvas do Menu)** `[STATUS: ✅ CONCLUÍDA]`
* **Tarefas:**
  1. Criação do arquivo `MainMenu.lua` no addon e registro no `.toc`.
  2. Conversão da textura `Carved_9Slides` para `.tga` 256x256 e criação da função auxiliar de 9-Slice em Lua.
  3. Criação da janela principal em tela cheia (com fundo de pergaminho 9-slice) e comando `/cm menu` (ou tecla) para abrir e fechar com o botão **(B)**.
  4. Divisão estrutural básica das duas grandes metades (Esquerda: Palco do Personagem / Direita: Container de Conteúdo).
* **Validação:** Concluída e testada em jogo via `/cm menu`.

### **FASE 2: O Palco do Personagem 3D & Giro no Analógico** `[STATUS: ✅ CONCLUÍDA]`
* **Tarefas:**
  1. Criação do frame `DressUpModel` transparente centralizado na metade esquerda.
  2. Chamada de `model:SetUnit("player")` para renderizar o personagem com as roupas atuais e animação de idle.
  3. Mapeamento do analógico direito (*R-Stick*) para girar o personagem em 360°.
* **Validação:** Concluída e validada com rotação contínua e suporte a TryOn.

### **FASE 3: Status Base, Buffs e Lista de Equipamentos (Lado Esquerdo)** `[STATUS: ✅ CONCLUÍDA]`
* **Tarefas:**
  1. Lista vertical de equipamentos à esquerda do boneco (ícones dos 19 slots + nomes dos itens por extenso com cor de qualidade).
  2. Coluna de Atributos e Buffs à direita do boneco (Nível, Classe, HP, Recurso, Ouro, Força/Agi/Vigor e lista de buffs com tempo restante).
* **Validação:** Concluída com renderização de slots de equipamentos reais, atributos dinâmicos e buffs ativos.

### **FASE 4: Container de Abas e Alternância com `[LB]` / `[RB]`** `[STATUS: ✅ CONCLUÍDA]`
* **Tarefas:**
  1. Criação do cabeçalho de abas no topo do container direito (`[LB] Bolsas | Spellbook | Missões | Configurações [RB]`).
  2. Alternância de abas via LB/RB no controle com som nativo da Blizzard.
  3. Alternância suave dos sub-frames da direita sem recarregar o lado esquerdo.
* **Validação:** Concluída com troca instantânea e ícones gráficos dedicados.

### **FASE 5: Grid de Bolsas Categorizado & Painel Fixo de Tooltip (Aba 1)** `[STATUS: ✅ CONCLUÍDA]`
* **Tarefas:**
  1. Leitura de itens das bolsas e agrupamento em blocos visuais (*Equipamentos*, *Consumíveis*, *Materiais*, *Outros*) com filtros `[LT]` / `[RT]`.
  2. Grid 2D leve com molduras de qualidade.
  3. Criação do Painel Fixo de Detalhes (Tooltip estilo Zelda) no canto inferior direito.
* **Validação:** Concluída com categorização completa e card de detalhes fixo.

### **FASE 6: Navegação D-Pad no Grid, Menu de Contexto (Y) e Live TryOn** `[STATUS: ✅ CONCLUÍDA]`
* **Tarefas:**
  1. Navegação espacial em grade via D-Pad com cursor de foco inteligente.
  2. Live TryOn: Ao parar sobre armas/armaduras na bolsa, o modelo 3D veste a peça ao vivo (`model:TryOn`) e faz pose; ao sair, restaura o set.
  3. Botão (A) para usar/equipar e (Y) para abrir o menu de contexto de ações flutuante com z-index de tooltip.
* **Validação:** Concluída e aprovada em jogo.

### **FASE 7: Aba de Spellbook & Poses de Conjuração no Modelo 3D (Aba 2)** `[STATUS: ✅ CONCLUÍDA]`
* **Tarefas:**
  1. Grid/Lista de magias e habilidades do jogador divididas por abas de classe/escola (`[LT]` / `[RT]`).
  2. Animações dinâmicas no modelo 3D conforme o tipo de magia selecionada (`model:SetSequenceTime` / poses de cast, ataque e buff).
  3. Painel fixo de detalhes exibindo custo de mana, alcance, cast time e descrição da magia.
* **Validação:** Concluída e integrada ao `MainMenu.lua`.

---

### **FASE 8: Aba de Configurações & Integração Dinâmica do Game Menu** `[STATUS: ✅ CONCLUÍDA]`
* **Objetivo:** Adicionar a aba principal de `CONFIGURAÇÕES` com duas sub-abas internas (`OPÇÕES` e `CONFIGURAÇÕES DO ADDON`), integrando uma varredura genérica do menu original do jogo sem nenhum hardcode.
* **Sub-etapas Detalhadas de Execução:**
  * **Etapa 8.1 - Setup da Aba e Sub-abas:** `[STATUS: ✅ CONCLUÍDA]`
    1. Criação do botão da aba no cabeçalho superior (`[LB] Bolsas | Spellbook | Missões | Configurações [RB]`).
    2. Criação do sub-cabeçalho interno navegável via `[LT]` / `[RT]`:
       - Sub-aba 1: `OPÇÕES` (Opções do Jogo e Menus de Sistema/Addons).
       - Sub-aba 2: `CONFIGURAÇÕES DO ADDON` (Painel ConsoleMode).
  * **Etapa 8.2 - Varredura Dinâmica e Listagem em Texto Puro:** `[STATUS: ✅ CONCLUÍDA]`
    1. Executar varredura automática dos filhos de `GameMenuFrame` (`GameMenuFrame:GetChildren()`).
    2. Filtrar botões válidos e extrair seus títulos (`GetText()`).
    3. Exibir todos os botões descobertos (Blizzard + Addons instalados como SuperMacro) em uma lista vertical com sanitização e cores padronizadas.
  * **Etapa 8.3 - Integração dos Cliques (`OnClick`):** `[STATUS: ✅ CONCLUÍDA]`
    1. Conectar a ação de cada item da lista para disparar o `Click()` correspondente do botão nativo original.
    2. Esconder/fechar o Main Menu ao acionar a opção para exibir a janela correspondente aberta na tela.
  * **Etapa 8.4 - Integração do Painel de Configurações do Addon:** `[STATUS: ✅ CONCLUÍDA]`
    1. Sub-aba do Addon configurada com as opções essenciais de console (Mapeador de Binds, Resetar Posições, Recarregar Interface).
  * **Etapa 8.5 - Estilização Visual e Navegação via Controle:** `[STATUS: ✅ CONCLUÍDA]`
1. Acabamento visual limpo sem badges numéricos, alinhamento à esquerda, hover e foco interativo do cursor.
* **Validação:** Concluída e testada em jogo com sucesso.

---

#### **FASE 9: Diário de Missões & Mapa Mundi Integrados (Padrão Retail Console)** `[STATUS: ✅ CONCLUÍDO]`
* **Objetivo:** Criar uma experiência unificada e moderna de **Diário de Missões + Mapa Mundi** na aba `MISSÕES & MAPA` (`ConsoleModeMM_Page_QUESTS`), inspirada no layout integrado do WoW Retail e adaptada à estética e controles de console:
  * **Painel Esquerdo:** Viewport dinâmico do **Mapa da Região** com navegação espacial, GPS do jogador em tempo real e zoom.
  * **Painel Direito:** **Diário de Missões** completo com lista de quests por zona, contadores de objetivos em tempo real e painel de recompensas.
* **Compatibilidade Dinâmica:**
  * 100% compatível com todas as zonas nativas do WoW Vanilla e **todas as novas regiões customizadas do Turtle WoW** (Gilneas, Hyjal, Tel'Abim, Alah'Thalas, etc.) através de chamadas dinâmicas às APIs do client (`GetMapZones`, `GetMapInfo`, `GetPlayerMapPosition`).
* **Mapeamento de Controles Limpo (Sem Conflitos com Steam Input):**
  * **Analógico Esquerdo (L-Stick / WASD):** Pan contínuo e suave pelo mapa em 360° (preserva o Analógico Direito como mouse nativo).
  * **Gatilhos `[LT]` / `[RT]`:** Zoom Out (Zona &rarr; Continente &rarr; Mundo) e Zoom In (Mundo &rarr; Continente &rarr; Zona).
  * **D-Pad (Cima / Baixo):** Navega pela lista de missões no Diário.
  * **Botão `(A)`:** Focar missão / Recentralizar mapa na zona da missão ou no jogador.
  * **Botão `(X)`:** Alternar rastreamento da missão no HUD (`IsQuestWatched` / `AddQuestWatch`).
  * **Botão `(Y)`:** Menu de Contexto da Missão (Abandonar / Compartilhar no grupo).
  * **Botão `(B)`:** Fechar Menu Principal.
  * **Botões `[LB]` / `[RB]`:** Alternar entre abas principais (`BOLSAS` | `SPELLBOOK` | `MISSÕES & MAPA` | `CONFIGURAÇÕES`).

---

### **Sub-etapas Detalhadas de Execução (Fase 9):**

* **Etapa 9.1 - Layout Split e Estrutura dos Containers (`ConsoleModeMM_Page_QUESTS`):** `[STATUS: ✅ CONCLUÍDA]`
* **Etapa 9.2 - Renderização do Canvas de Mapa (12 Tiles Dinâmicos):** `[STATUS: ✅ CONCLUÍDA]`
* **Etapa 9.3 - Sistema de Pan (L-Stick) e Zoom (`[LT]` / `[RT]`):** `[STATUS: ✅ CONCLUÍDA]`
* **Etapa 9.4 - GPS em Tempo Real (Player Pin & Party Pins):** `[STATUS: ✅ CONCLUÍDA]`
* **Etapa 9.5 - Scanner do Diário de Missões e Lista Categorizada:** `[STATUS: ✅ CONCLUÍDA]`
* **Etapa 9.6 - Sinergia Total, Foco Automático e Ações do Controle:** `[STATUS: ✅ CONCLUÍDA]`
* **Validação:** Concluída e testada com sucesso in-game.

---

#### **FASE 10: Navegação de Mapa por Continentes (Gamepad-First — Lista Vertical)** `[STATUS: ✅ CONCLUÍDO]`
* **Objetivo:** Permitir navegação livre entre mapas sem mouse, com foco total em gamepad/console (Steam Deck). Inspirado no WorldMap clássico (clique em região → entra, `B` volta) mas adaptado para controle: 3 botões fixos em lista vertical no canto inferior direito do painel do mapa.
* **Layout:**
  * Pilha vertical `ATUAL` (topo) → `KALIMDOR` → `EASTERN KINGDOMS` (base), ancorada `BOTTOMRIGHT` do `mapPanel` acima do `mapFooter` (`-6,4`) sem invadir `mapCanvas` (`-6,26`).
  * Sempre visíveis; highlight/borda dourada no ativo (`mapViewMode` + `mapContinentView`).
* **Estados:**
  * `mapViewMode = "ZONE" | "CONTINENT"` + `mapContinentView = 1|2` em `MainMenu` (`UI/MainMenu.lua`).
* **Handlers (`UI/MainMenu.lua`):**
  * `NavToCurrent()` — `ResetMapToPlayer() + ZONE + UpdateEverything + ResetCursorZoneMode()`.
  * `NavToContinent(cont)` — `SetMapZoom(cont,0) + CONTINENT + mapContinentView=cont + zoom 1.0/pan 0 + desativa drag livre + BuildContinentZoneButtons(cont) + ativa cursor`.
  * `NavToZone(zoneName)` — `SwitchMapToZone(zoneName) + ZONE`.
* **Cursor de zona (só em `CONTINENT`):**
  2. Tabela `ContinentZoneCoords` + `BuildContinentZoneButtons`.
  3. Modo cursor (`CollectButtons`/`FindFirstVisibleButton`/bloqueio de pan/`B` volta).
  4. Polimento hint (`[D-Pad] Zonas • [A] Entrar • [B] Voltar` em `CONTINENT`), esconder pins, guard `ZONE_CHANGED`.
* **Validação:** `luac -p` (Lua 5.0) + `/reload` Turtle: abrir `QUESTS`, navegar `ATUAL/KALIMDOR/EASTERN KINGDOMS` (mouse+gamepad), D-Pad entre zonas, `A` entra, `B` volta, `ZONE_CHANGED` preserva `CONTINENT`.
* **Compatibilidade:** WoW 1.12.1 / Lua 5.0 — sem `#table`, sem `...` variádico 5.1, validar com `luac -p` a cada edição.

---

### **FASE 11: Menu de Contexto da Missão (Y) — Detalhes / Abandonar** `[STATUS: ✅ CONCLUÍDO]`
* **Objetivo:** Ao pressionar `Y` (Gamepad) / tecla de contexto com foco em qualquer missão não-header da lista `MISSÕES & MAPA` (`ConsoleModeMM_Page_QUESTS` → `questPanel.listContainer`), abrir menu de contexto flutuante com duas ações: `Detalhes da Missão` e `Abandonar Missão`. `Detalhes` abre painel flutuante central com texto completo da missão; `B` fecha painel flutuante com prioridade sobre `HandleMapBack`/`CloseTopFrame`. `Abandonar` dispara fluxo nativo de abandono com confirmação (`StaticPopup ABANDON_QUEST`).
* **Implementado:** Overlay modal com scroll `questDetailOverlay` integrado em `ShowQuestDetail` e fluxo nativo de abandono em `AbandonSelectedQuest`.

---

### **FASE 12: Sistema de Tradução de Missões (Híbrido pfQuest + DB Local ptBR)** `[STATUS: ✅ CONCLUÍDO]`
* **Objetivo:** Integrar tradução completa em Português (pt-BR) para os textos de missões exibidos no `ConsoleModeVanilla` (tanto no **Card de Resumo Lateral**, no **Modal Flutuante de Detalhes com Scroll**, quanto na **Lista Vertical de Missões da Esquerda**).
* **Arquitetura Híbrida Inteligente (Sem dependência obrigatória):**
  1. **Nível 1 — `pfQuest` (Mais Atualizado):** Se o jogador tiver o `pfQuest` / `pfQuest-turtle` ativo, utilizamos diretamente as tabelas globais em memória (`pfDB["quests"]["ptBR-turtle"]` e `pfDB["quests"]["ptBR"]`), capturando o ID da quest via `pfDatabase:GetQuestIDs(questLogIndex)`.
  2. **Nível 2 — DB Local Embutido (`Data/QuestDB_ptBR.lua`):** Caso o jogador não utilize o `pfQuest`, o `ConsoleModeVanilla` carrega seu próprio banco de dados de 6.685 missões (`ConsoleMode_QuestDB`), construído a partir das bases do Vanilla 1.12 e do Turtle WoW, permitindo busca $O(1)$ por ID e lookup reverso por Título em inglês (`ConsoleMode_QuestDB_ByTitle`).
  3. **Otimização Crítica de RAM (WoW 1.12):** No evento `PLAYER_LOGIN` / `ADDON_LOADED`, se o addon detectar que o `pfDB["quests"]["ptBR"]` já existe na memória global, as tabelas locais embutidas são liberadas (`ConsoleMode_QuestDB = nil` e `ConsoleMode_QuestDB_ByTitle = nil`) e `collectgarbage()` é disparado, liberando ~4 MB de memória do cliente 1.12.
  4. **Fallback Transparente:** Caso uma missão nova/não catalogada seja selecionada, os textos originais em inglês da Blizzard são mantidos sem quebrar a interface.

* **Passos Detalhados de Execução (Isolados e com Validação Individual):**

  * **Passo 12.1 - Construção e Registro do DB Local Embutido (`Data/QuestDB_ptBR.lua`):** `[STATUS: ✅ CONCLUÍDO]`
    1. Script `tools/build_questdb.py` criado e executado, unificando 4.433 quests Vanilla + 2.252 exclusivas do Turtle WoW (total 6.685 quests) com prioridade do Turtle WoW em colisões de ID.
    2. Arquivo `Data/QuestDB_ptBR.lua` registrado no `ConsoleModeVanilla.toc`.
    3. *Validação:* `QuestDB: true total real: 6685` validado in-game via chat.

  * **Passo 12.2 - Engine Unificada de Resolução (`MainMenu:GetQuestTranslation`):** `[STATUS: ✅ CONCLUÍDO]`
    1. Helper `MainMenu:GetQuestTranslation(questLogIndex, rawTitle, rawDesc, rawObj)` implementado em `UI/MainMenu.lua`.
    2. Resolução autônoma por ID e por Título em inglês (`ConsoleMode_QuestDB_ByTitle`).
    3. Desalocação automática de RAM em `PLAYER_LOGIN` e `ADDON_LOADED` quando `pfDB` presente.
    4. *Validação:* Testado in-game com pfQuest ativo e desativado com 100% de sucesso.

  * **Passo 12.3 - Tradução do Card de Resumo Lateral (`MainMenu:SelectQuest`):** `[STATUS: ✅ CONCLUÍDO]`
    1. Título traduzido com nível colorido preservado (`[Level] Nome em Português`).
    2. Objetivos exibidos em formato limpo por linhas de bullets (`-` / `✔`), com verbos traduzidos (`slain` -> `abatido(s)`).
    3. Quests sem contadores limpas de códigos brutos da Blizzard (`$B`, `$N`).
    4. *Validação:* Testado e aprovado in-game.

  * **Passo 12.4 - Tradução do Modal Flutuante com Scroll (`MainMenu:ShowQuestDetail`):** `[STATUS: ✅ CONCLUÍDO]`
    1. Narrativa longa traduzida em português com substituição dinâmica de `$N` (nome do jogador), `$C` (classe) e `$R` (raça).
    2. Subtítulo com o nome original em inglês em cinza suave (`|cff888888`) para consultas fáceis no Wowhead / Turtle DB.
    3. Aplicação de fontes UTF-8 do ConsoleMode (`Marcellus` e `Alegreya Sans`), corrigindo renderização de acentos e o caractere `ç`.
    4. Recálculo dinâmico da altura do `scrollChild` para rolagem suave.
    5. *Validação:* Testado e aprovado in-game.

  * **Passo 12.5 - Refinamentos de UX e Navegação Gamepad-First:** `[STATUS: ✅ CONCLUÍDO]`
    1. **Auto-seleção no Foco (D-Pad):** Navegar na lista de missões atualiza o card lateral e o índice da missão selecionada em tempo real no `OnEnter` (`suppressMapSwitch = true`), permitindo apertar `(Y)` diretamente sem precisar apertar `(A)` antes.
    2. **Tradução da Lista Vertical:** Botões da lista da esquerda atualizados em `MainMenu:UpdateQuestsPage` para exibir os títulos traduzidos em português.
    3. Validação de sintaxe total com `luac -p` em todos os arquivos modificados.
    4. *Validação:* Validado e aprovado in-game.

---

### **FASE 13: Inspeção de Equipamentos Equipados & Buffs no Painel Fixo de Tooltip** `[STATUS: ✅ CONCLUÍDO]`
* **Tarefas Concluídas:**
  1. **Inspeção de Equipamentos no `DetailCard`:** Conectada a coluna de Equipamentos da esquerda (`MainMenu.equipColumn`) ao Painel Fixo de Detalhes (`DetailCard`), exibindo ícone, nome na cor da raridade, atributos, durabilidade e efeitos mágicos sem tooltips soltos flutuando na tela.
  2. **Tratamento de Slots Vazios:** Exibição elegante do ícone translúcido do compartimento, título `(Vazio)` em cinza e texto explicativo.
  3. **Snapping Magnético do Cursor nos Buffs:** Linhas da coluna de buffs ativos transformadas em botões interativos (`Button` com `EnableMouse`), permitindo snapping instantâneo do D-Pad do controle e cancelamento com clique direito.
  4. **Inspeção de Buffs Ativos & Armas:** Ao focar/fazer snap em qualquer buff ou encantamento temporário de arma, exibe no `DetailCard` o ícone grande, título em destaque, tempo restante e descrição completa do efeito.
  5. **Layout em 2 Colunas e Zero Cortes:** Redesenho completo da área central do `DetailCard` em 2 colunas horizontais (Esquerda: Dano/Velocidade/DPS/Armadura; Direita: Atributos/Efeitos especiais/Durabilidade), aproveitando 100% da largura da tela sem reticências (`...`).
  6. **Subtítulo Rico no Topo:** `SLOT • Subtipo • Dur. X/Y • Soulbound • Único • Req. Nv X` centralizados na linha superior, com remoção de duplicidades no corpo de texto.
  7. **Colapso Inteligente da Coluna:** Caso o item não possua estatísticas de combate (Hearthstone, anéis, consumíveis), a coluna direita colapsa automaticamente para a esquerda com largura total de 380px.
  8. **Preservação de Foco Ativo:** Sincronização em segundo plano de moedas e bolsas sem forçar o reset cego para o primeiro item da bag.
* **Validação:** Testado, aprovado e validado in-game pelo usuário.

---

### **FASE 14: Sistema de Comparação de Equipamentos na Coluna de Atributos do Personagem (Stat Diff - Verde/Vermelho)** `[STATUS: ⏳ PRÓXIMA FASE]`
* **Tarefas:**
  1. Detecção automática do slot de equipamento correspondente ao passar o cursor sobre qualquer item equipável na mochila (Elmo, Peitoral, Arma, etc.).
  2. Leitura e cálculo diferencial entre os atributos do item da bolsa e o item atualmente equipado naquele slot (`GetInventoryItemLink`).
  3. Atualização dinâmica e em tempo real da **Coluna de Atributos do Personagem** (à direita do modelo 3D):
     - **Ganhos de Atributos:** Se a peça da bolsa for superior, o atributo correspondente (Força, Agilidade, Vigor, Intelecto, Espírito, Armadura) fica destacado em **Verde** exibindo o ganho entre parênteses: `142 (+12)`.
     - **Perdas de Atributos:** Se a peça equipada for superior à da bolsa (ou seja, equipar a nova peça reduziria seus status), o atributo correspondente fica destacado em **Vermelho** exibindo a perda entre parênteses: `130 (-12)`.
     - **Sem Alteração:** Atributos não afetados permanecem na cor padrão branca/dourada.
  4. Restauração instantânea dos valores e cores padrão da coluna de atributos ao retirar o foco de itens equipáveis ou focar em slots vazios/consumíveis.
* **Validação:** Focar em elmos, armas e armaduras na mochila e observar a coluna de atributos ao lado do personagem 3D colorir instantaneamente em verde `(+X)` ou vermelho `(-X)` mostrando o impacto real de equipar aquele item.

---

### **FASE 15: Câmera Dinâmica (Zoom), Animações de Consumo e Polimento Final** `[STATUS: ⏳ PENDENTE]`
* **Tarefas:**
  1. Zoom inteligente da câmera 3D focado no elmo/ombros ou corpo inteiro.
  2. Animações de comer/beber no modelo 3D ao usar consumíveis.
  3. Mapeamento de abertura pelo botão Start e ajustes finos de responsividade.
* **Validação:** Menu completo, fluido, polido e 100% funcional no gameplay com controle.

---

### **FASE 16: Correção / Refinamento dos Pins de Zona no Mapa Continente** `[STATUS: ⏳ WIP — pins aproximados / requer ajuste manual]`
* **Contexto:** `feat(map) pin de zona no CONTINENTE` (71a7193) implementou `Data/ZonePositions.lua` (`cont/x/y` 0-1 em 1002×668) + `zonePin` em `mapTilesContainer` com `ShowZonePinForZone/HideZonePin/UpdateZonePinPosition` e `OnEnter/OnLeave` na lista `REGIOES` (também dispara via `Cursor:MoveTo`). Muitos pins ficaram fora da zona correta; alguns corretos — posições ainda aproximadas.
* **Tarefas:**
  1. Refinar manualmente `Data/ZonePositions.lua` zona a zona em jogo `/reload` comparando `Kalimdor`/`EasternKingdoms` vanilla e Turtle custom (`Gilneas`, `Hyjal`, `Alah'Thalas`, `Tel'Abim` etc.) — ajustar `x/y` até pin cair dentro do contorno/label da zona no `tilesContainer` (considerar `currentScale`/`effW/effH` e `panX/panY`).
  2. Validar todos os `GetMapZones(1)` e `GetMapZones(2)` — adicionar faltantes e remover obsoletos; cont `>2` ignorado na v1.
  3. `luac -p Data/ZonePositions.lua` + `UI/MainMenu.lua` a cada lote de ajustes; sem `#`, Lua 5.0.
  4. Não alterar API de pin — só valores `x/y`; manter hide fora de `CONTINENT`, em `INSTANCIAS` e ao `SwitchMapToZone/Reset`.
* **Validação:** Em `CONTINENT`, hover/D-Pad em cada item de `REGIOES` mostra pin amarelo + label exatamente sobre a área da zona no mapa; sem pin fantasma ao trocar continente/zona.
* **Commit:** Não fazer commit/push até autorização; marcar no histórico que foi WIP de posicionamento.
