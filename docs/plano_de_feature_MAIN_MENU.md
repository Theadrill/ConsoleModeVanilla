# Plano de Feature: MAIN MENU (Menu Principal Console Hub)

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

## 6. Estilo Visual e Tematização

* **Fundo:** Cor sólida escurecida translúcida ou textura de pergaminho/dark fantasy estilizada compartilhada por todo o Hub.
* **Bordas e Seleção:** Molduras elegantes com destaques luminosos no elemento em foco (cursor dourado/brilhante estilo Zelda).
* **Feedback Sonoro:** Execução de sons nativos do cliente da Blizzard para confirmação, cancelamento e transição de abas.
