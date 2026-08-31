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

## 7. Plano de Implementação em 11 Fases Incrementais

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
  1. Criação do cabeçalho de abas no topo do container direito (`[LB] Bolsas | Spellbook [RB]`).
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

### **FASE 8: Aba 3 (Configurações) & Integração Dinâmica do Game Menu** `[STATUS: ⏳ PENDENTE / PRÓXIMA FASE]`
* **Objetivo:** Adicionar a 3ª aba principal (`CONFIGURAÇÕES`) com duas sub-abas internas (`OPÇÕES` e `CONFIGURAÇÕES DO ADDON`), integrando uma varredura genérica do menu original do jogo sem nenhum hardcode.
* **Sub-etapas Detalhadas de Execução:**
  * **Etapa 8.1 - Setup da Aba e Sub-abas:**
    1. Criação do botão da 3ª aba no cabeçalho superior (`[LB] Bolsas | Spellbook | Configurações [RB]`).
    2. Criação do sub-cabeçalho interno navegável via `[LT]` / `[RT]`:
       - Sub-aba 1: `OPÇÕES` (Opções do Jogo e Menus de Sistema/Addons).
       - Sub-aba 2: `CONFIGURAÇÕES DO ADDON` (Painel ConsoleMode).
  * **Etapa 8.2 - Varredura Dinâmica e Listagem em Texto Puro (Validação):**
    1. Executar varredura automática dos filhos de `GameMenuFrame` (`GameMenuFrame:GetChildren()`).
    2. Filtrar botões válidos e extrair seus títulos (`GetText()`).
    3. Exibir todos os botões descobertos (Blizzard + Addons instalados como SuperMacro) em uma lista vertical em texto simples/padrão para validação em jogo.
  * **Etapa 8.3 - Integração dos Cliques (`OnClick`):**
    1. Conectar a ação de cada item da lista para disparar o `Click()` correspondente do botão nativo original.
    2. Esconder/fechar o Main Menu ao acionar a opção para exibir a janela correspondente aberta na tela.
  * **Etapa 8.4 - Integração do Painel de Configurações do Addon:**
    1. Vincular o painel existente do `ConsoleMode` (mapeamento de binds, sensibilidades, deadzones, HUD) na Sub-aba 2.
  * **Etapa 8.5 - Estilização Visual e Navegação via Controle:**
    1. Aplicar o acabamento visual definitivo dos botões da lista (moldura, hover, foco do D-Pad, ícones e visual de console).
* **Validação:** Abrir a aba de Configurações, alternar entre as duas sub-abas via `[LT]` / `[RT]`, visualizar todos os menus (incluindo addons de terceiros) listados dinamicamente e abri-los via controle.

---

### **FASE 9: Câmera Dinâmica (Zoom), Animações de Consumo e Polimento Final** `[STATUS: ⏳ PENDENTE]`
* **Tarefas:**
  1. Zoom inteligente da câmera 3D focado no elmo/ombros ou corpo inteiro.
  2. Animações de comer/beber no modelo 3D ao usar consumíveis.
  3. Mapeamento de abertura pelo botão Start e ajustes finos de responsividade.
* **Validação:** Menu completo, fluido, polido e 100% funcional no gameplay com controle.

### **FASE 10: Inspeção de Equipamentos Equipados & Buffs no Painel Fixo de Tooltip** `[STATUS: ⏳ PENDENTE]`
* **Tarefas:**
  1. Conectar a coluna de Equipamentos da esquerda ao Painel Fixo de Detalhes (`DetailCard`): ao passar o mouse ou focar via controle em qualquer slot de equipamento (Elmo, Peitoral, Arma, etc.), exibir todos os atributos, durabilidade e encantamentos no painel fixo à direita.
  2. Conectar a coluna de Buffs Ativos da esquerda ao `DetailCard`: ao focar em qualquer buff/debuff, exibir o nome com destaque, descrição completa do efeito mágico e tempo restante no painel fixo.
  3. Navegação contínua e sem atritos entre os equipamentos da esquerda e as abas da direita via D-Pad para uma experiência 100% unificada de console.
* **Validação:** Focar em elmos, armas equipadas e buffs na lateral esquerda e ver seus dados completos carregando instantaneamente no painel fixo da direita.

### **FASE 11: Sistema de Comparação de Equipamentos na Coluna de Atributos do Personagem (Stat Diff - Verde/Vermelho)** `[STATUS: ⏳ PENDENTE]`
* **Tarefas:**
  1. Detecção automática do slot de equipamento correspondente ao passar o cursor sobre qualquer item equipável na mochila (Elmo, Peitoral, Arma, etc.).
  2. Leitura e cálculo diferencial entre os atributos do item da bolsa e o item atualmente equipado naquele slot (`GetInventoryItemLink`).
  3. Atualização dinâmica e em tempo real da **Coluna de Atributos do Personagem** (à direita do modelo 3D):
     - **Ganhos de Atributos:** Se a peça da bolsa for superior, o atributo correspondente (Força, Agilidade, Vigor, Intelecto, Espírito, Armadura) fica destacado em **Verde** exibindo o ganho entre parênteses: `142 (+12)`.
     - **Perdas de Atributos:** Se a peça equipada for superior à da bolsa (ou seja, equipar a nova peça reduziria seus status), o atributo correspondente fica destacado em **Vermelho** exibindo a perda entre parênteses: `130 (-12)`.
     - **Sem Alteração:** Atributos não afetados permanecem na cor padrão branca/dourada.
  4. Restauração instantânea dos valores e cores padrão da coluna de atributos ao retirar o foco de itens equipáveis ou focar em slots vazios/consumíveis.
* **Validação:** Focar em elmos, armas e armaduras na mochila e observar a coluna de atributos ao lado do personagem 3D colorir instantaneamente em verde `(+X)` ou vermelho `(-X)` mostrando o impacto real de equipar aquele item.
