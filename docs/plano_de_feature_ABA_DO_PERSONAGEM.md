# Plano de Feature: ABA DO PERSONAGEM (CHARACTER & STATUS SHEET) NO CONSOLEMODE

> [!CAUTION]
> **REGRAS MANDATÓRIAS DE CONTROLE DE VERSÃO E GIT (CRÍTICO):**
> 1. **PROIBIDO QUALQUER PUSH AUTOMÁTICO:** NUNCA executar `git push` sem que o usuário dê a ordem explícita no chat.
> 2. **PROCESSO UNITÁRIO DE PUSH:** Quando o usuário autorizar ou ordenar um push, a IA deve realizar **apenas um único push** da etapa aprovada e **aguardar novas instruções** antes de realizar qualquer outra ação.
> 3. **PARADA OBRIGATÓRIA ENTRE FASES:** Ao término de cada fase, a IA deve parar imediatamente, reportar o que foi implementado e fornecer as instruções exatas de teste no jogo (`/reload`). Nenhuma linha de código da fase subsequente pode ser escrita sem o "OK" explícito do usuário.

> [!IMPORTANT]
> **ESPECIFICAÇÕES TÉCNICAS DA PLATAFORMA & DIRETRIZ ARQUITETURAL:**
> - **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Build 5875) / Turtle WoW.
> - **Versão da Linguagem Lua:** **Lua 5.0** estrito (FrameXML clássico de 2004).
>   - **PROIBIDO** o uso do operador `#table` de Lua 5.1+ (usar `table.getn(t)` ou `getn(t)`).
>   - **PROIBIDO** o uso de `continue`, `goto` ou funções ausentes na versão 5.0.
>   - Toda alteração deve ser validada no compilador de sintaxe (`luac -p`) antes de qualquer teste.
> - **ARQUITETURA MODULAR ISOLADA (FIM DO INCHAÇO NO MAIN MENU):**
>   - O arquivo `UI/MainMenu.lua` já ultrapassa 14.000 linhas e é um monólito que será refatorado no futuro.
>   - **NÃO refatorar o MainMenu agora e NÃO colocar a lógica da tela do personagem dentro dele.**
>   - A tela do Personagem nascerá como um **módulo 100% desacoplado e independente**: `UI/CharacterScreen.lua`.
>   - Seguirá rigorosamente a arquitetura modular já consagrada no projeto em `UI/MerchantMenu.lua` e `UI/MailScreen.lua`.
>   - O `MainMenu.lua` terá apenas o acoplamento mínimo necessário: registrar a aba no menu (organizada em 2 linhas), instanciar o contêiner e repassar os eventos para o `ConsoleMode_CharacterScreen`.

---

## 1. Visão Geral da Feature

Atualmente, as informações completas do personagem no WoW 1.12 ficam espalhadas por janelas nativas arcaicas da Blizzard (`CharacterFrame`, `SkillFrame`, `ReputationFrame`, `HonorFrame`), projetadas para ponteiro de mouse e incompatíveis com a experiência de gamepad no Steam Deck.

Esta feature implementa a **Aba do Personagem ("PERSONAGEM")** acessada pelo `MainMenu`, consolidando **todos os dados do personagem** em um único lugar:

1. **Painel Esquerdo (Palco 3D Fixo - Preservado):**
   - Mantém exatamente a estrutura atual: visualizador 3D do personagem (com rotação pelo analógico direito), coluna de equipamentos e resumo rápido de status/buffs ativos estilo Zelda TotK.
2. **Barra de Abas Superior em 2 Linhas Centralizadas (Painel Direito):**
   - Como 6 abas não cabem em uma única linha horizontal sem esmagar o layout, a barra do painel direito é quebrada em **duas linhas de 3 botões centralizados**:
     - **Linha 1:** `[ Bolsas & Itens ]` `[ Livro de Magias ]` `[ Talentos ]`
     - **Linha 2:** `[ Missões & Mapa ]` `*[ PERSONAGEM ]*` `[ Opções / Binds ]`
   - Navegação contínua e cíclica pelos botões de ombro `[LB]` e `[RB]`.
3. **Módulo Desacoplado da Ficha (`UI/CharacterScreen.lua`):**
   - Um arquivo limpo, modular e autônomo contendo a renderização da área scrollável, a leitura de todas as APIs do jogo e a gerência dos cards.
   - **Separação de seções espelhando o addon BetterCharacterStats v1.14.x (moh, Bennylava, Lexie, Spit, Pepopo) — ver créditos no `README.md`:** cada grupo abaixo vira um card próprio na ficha, na mesma ordem do addon:
     - **Identidade & Biografia** (Nome, Nível, Raça, Classe, Guilda, XP, Modos Hardcore/Turtle). Card próprio ConsoleMode (fora do BCS).
     - **Base Stats** (Força, Agilidade, Vigor, Intelecto, Espírito + Armadura).
     - **Melee** (Perícia de Arma, Dano, Velocidade de Ataque, Attack Power, Hit, Crítico Melee).
     - **Melee vs Boss** (Perícia de Arma, chance de Miss/Dodge do boss, redução de Glancing, Crit Cap, Crítico Efetivo vs alvo nível 63).
     - **Ranged** (Perícia Ranged, Dano, Velocidade, Ranged AP, Hit, Crítico Ranged). Oculto para classes com slot de relíquia (mesma regra do BCS).
     - **Spell** (Spell Power, Hit Mágico, Crítico Mágico, Cura (+Heal), Regen de Mana, Spell Haste).
     - **Schools** (Spell Power por escola: Arcano, Fogo, Gelo, Sagrado, Natureza, Sombra).
     - **Defenses** (Armadura, Defesa, Esquiva, Aparo, Bloqueio, Esquiva Total).
     - **Defenses vs Boss** (idem, com diferencial de +3 níveis vs alvo nível 63).
     - **Resistências Elementais** (Fogo, Natureza, Gelo, Sombra, Arcano com barras visuais). Card próprio ConsoleMode (fora do BCS, via `UnitResistance` real).
     - **Profissões & Ofícios** (Primárias, Secundárias e Sobrevivência/Tendas com barras `X/300`).
     - **Perícias de Armas & Armaduras** (Espadas, Machados, Arcos, etc. com barras `X/300`).
     - **Honra & JxJ (PvP)** (Rank militar, progresso semanal, abates hoje/ontem/vida).
     - **Reputações & Facções** (Capitais e facções com barras de amizade).
     - **Idiomas & Raciais** (Línguas conhecidas e passivas raciais).
   - **Técnica de cálculo (fonte: `BetterCharacterStats/helper.lua`):** a 1.12 NÃO expõe `GetManaRegen`/`GetSpellBonusDamage`/`GetSpellCritChance` — o BCS calcula tudo com APIs permitidas e a ficha replica a técnica: (a) fórmulas base por classe via `UnitStat` (ex. regen `spirit/4 + 12.5` para priest/mage); (b) varredura de tooltips de equipamento/talentos/auras com `strfind` (padrões `"Restores (%d+) mana per 5 sec."`, `"Mana Regen %+(%d+)"` etc.); (c) tabelas vs Boss derivadas da perícia de arma/defesa contra alvo nível 63. Nenhum número é inventado: onde não houver fórmula confiável, o card exibe `"—"` honesto até a técnica ser portada.
4. **Navegação & Cursor (D-Pad Direto + Arquitetura de Hover Adormecida):**
   - **Comportamento Atual:** A navegação nesta página é feita pelo **D-Pad (`Cima`/`Baixo`)**, rolando a página de forma contínua e direta.
   - **Infraestrutura de Hover Pré-Construída (Dormant):** Cada campo e card da ficha já é registrado em uma matriz de foco com callbacks `OnEnter`/`OnLeave` e bordas douradas ativas. Uma chave booleana `CharacterScreen.enableSlotNavigation = false` mantém o hover item a item desligado no momento, garantindo que no futuro baste mudar a flag para `true` para ter navegação slot-a-slot estilo console sem precisar reescrever nada.

---

## 2. Diagrama Visual em ASCII Art (Apresentação Completa "Long-Page")

```text
+======================================================================================================================================================+
|                                                           |cffe09a15[ MENU PRINCIPAL ]|r                                                             |
+--------------------------------------------------------------+---------------------------------------------------------------------------------------+
|                       PAINEL ESQUERDO                        |                                    PAINEL DIREITO                                     |
|               (PALCO 3D DO PERSONAGEM - FIXO)                |             (BARRA DE ABAS EM 2 LINHAS + CONTEÚDO SCROLLÁVEL DA FICHA)                |
+--------------------------------------------------------------+---------------------------------------------------------------------------------------+
|                                                              |                                                                                       |
| [CABEÇA]  Capacete de Placas         FOR  142 [=====]  (12)  |   [LB]        [ Bolsas & Itens ]    [ Livro de Magias ]    [ Talentos ]               |
| [COLAR]   Pingente do Sol            AGI   84 [===  ]  ( 5)  |                                                                                       |
| [OMBROS]  Ombreiras da Vanguarda     VIG  165 [======] (18)  |               [ Missões & Mapa ]    *[ PERSONAGEM ]*       [ Opções / Binds ]     [RB] |
| [CAPA]    Capa de Couro Pesado       INT   32 [=    ]        |   ---------------------------------------------------------------------------------   |
| [PEITORAL]Armadura de Ferro          ESP   48 [==   ]        |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|           /---------------------\    BUFFS ATIVOS:           |   | IDENTIDADE & BIOGRAFIA                                                        |   |
|           |                     |    [*] Grito de Batalha    |   | Rodrigo Vernaschi  <Os Guardiões de Ferro>               Humano Guerreiro Niv 60|   |
|           |                     |        [==========]  12m   |   | Posto: Sargento-Mor (Rank 5)        Facção: Aliança     Modo: Hardcore Ativo   |   |
| [PUNHOS]  |     PERSONAGEM      |    [*] Intelecto Arcano    |   | XP: [=============================== 100%] 60/60        Status: Descansado(200%)|   |
| [LUVAS]   |         3D          |        [========  ]  28m   |   +-------------------------------------------------------------------------------+   |
| [CINTO]   |   (Giro livre com   |    [*] Pedra de Fogo       |                                                                                       |
| [PERNAS]  |   analógico dir.)   |        [======    ]  18m   |   +-------------------------------------------------------------------------------+   |
| [BOTAS]   |                     |    [*] Bênção do Poder     |   | ATRIBUTOS PRIMÁRIOS & RECURSOS                                                |   |
|           \---------------------/        [===========] 54m   |   |  Vida Máxima:  4.280 HP  (Regen: 38 HP/s fora de comb. / 0 HP/s em comb.)     |   |
| [ANEL 1]  Anel de Ouro Puro                                  |   |  Fúria/Mana:     100 Fúria                                                    |   |
| [ANEL 2]  Selo do Guerreiro          ARMADURA TOTAL:         |   |  Força:        142  (+284 Attack Power, +28 Valor de Bloqueio)                |   |
| [BERL. 1] Insígnia da Aliança        4.890  (Redução: 52%)   |   |  Agilidade:     84  (+168 Armadura, +4.2% Crítico Físico, +4.2% Esquiva)      |   |
| [BERL. 2] Ícone de Coragem                                   |   |  Vigor:        165  (+1.650 Pontos de Vida)                                   |   |
|                                                              |   |  Intelecto:     32  (+480 Mana, +0.5% Crítico Mágico)                          |   |
| [MÃO DIR] Lâmina da Bravura          DEFESA:                 |   |  Espírito:      48  (+18 HP regen/5s fora de combate)                          |   |
| [MÃO ESQ] Escudo Muralha do Leão     300 / 300               |   +-------------------------------------------------------------------------------+   |
| [ALCANCE] Balestra de Carvalho                               |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | COMBATE CORPO A CORPO (MELEE)                                                 |   |
|                                                              |   |  Poder de Ataque (AP):    684          Habilidade de Arma:     300 / 300      |   |
|                                                              |   |  Arma Principal (1H):    142 - 188 Dano Velocidade: 2.60s       DPS: 82.5    |   |
|                                                              |   |  Arma Secundária (Off):   -- (Escudo)   Velocidade: ----        DPS: ----    |   |
|                                                              |   |  Acerto Crítico Melee:   14.8%         Chance de Acerto (Hit):  +5.0%       |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | COMBATE À DISTÂNCIA (RANGED)                                                  |   |
|                                                              |   |  Poder de Ataque à Dist.: 210          Perícia em Balestras:   295 / 300      |   |
|                                                              |   |  Dano de Longo Alcance:    88 - 124    Velocidade: 2.80s       DPS: 42.1    |   |
|                                                              |   |  Crítico à Distância:    8.2%          Chance de Acerto (Hit):  +2.0%       |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | DEFESA & SOBREVIVÊNCIA                                                        |   |
|                                                              |   |  Armadura:     4.890  (52.4% absorção contra alvos de nível 60)               |   |
|                                                              |   |  Habilidade de Defesa:   300 / 300 (Reduz chance de receber crítico em +0.0%) |   |
|                                                              |   |  Esquiva (Dodge):         8.4%         Aparo (Parry):           12.2%       |   |
|                                                              |   |  Bloqueio (Block):       18.5%         Valor de Bloqueio:       145 Dano    |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | RESISTÊNCIAS ELEMENTAIS & MÁGICAS                                             |   |
|                                                              |   |  (Fogo)      Fogo:      85  [==========          ]  (28% redução média)       |   |
|                                                              |   |  (Natureza)  Natureza:  40  [=====               ]  (14% redução média)       |   |
|                                                              |   |  (Gelo)      Gelo:      20  [==                  ]  ( 7% redução média)       |   |
|                                                              |   |  (Sombra)    Sombra:    60  [=======             ]  (20% redução média)       |   |
|                                                              |   |  (Arcano)    Arcano:     0  [                    ]  ( 0% redução média)       |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | PODER MÁGICO & CONJURAÇÃO (SPELL & HEAL)                                      |   |
|                                                              |   |  Poder de Cura (+Heal):    +0          Dano Mágico Geral:       +0          |   |
|                                                              |   |  Sagrado:   +0    Fogo:    +0   Natureza: +0                                  |   |
|                                                              |   |  Gelo:      +0    Sombra:  +0   Arcano:   +0                                  |   |
|                                                              |   |  Crítico Mágico Geral:   2.4%          Spell Penetration:        0          |   |
|                                                              |   |  Regeneração Mana (MP5):  0 MP5 ativo / 22 MP5 fora da regra dos 5 seg.      |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | PROFISSÕES & OFÍCIOS                                                          |   |
|                                                              |   |  [Ferraria]      Ferraria (Armaduras)    [======================]  300 / 300  |   |
|                                                              |   |  [Mineração]     Mineração               [======================]  300 / 300  |   |
|                                                              |   |  [Culinária]     Culinária               [==================    ]  255 / 300  |   |
|                                                              |   |  [1º Socorros]   Primeiros Socorros      [======================]  300 / 300  |   |
|                                                              |   |  [Pesca]         Pesca                   [============          ]  160 / 300  |   |
|                                                              |   |  [Sobrevivência] Sobrevivência (Tendas)  [=================     ]  230 / 300  |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | PERÍCIAS DE ARMAS & PROFICIÊNCIAS                                             |   |
|                                                              |   |  Espadas de 1 Mão:  [======================] 300 / 300  (Cap Máximo)          |   |
|                                                              |   |  Machados de 1 Mão: [======================] 300 / 300  (Cap Máximo)          |   |
|                                                              |   |  Maças de 1 Mão:    [======================] 300 / 300  (Cap Máximo)          |   |
|                                                              |   |  Espadas de 2 Mãos: [======================] 300 / 300  (Cap Máximo)          |   |
|                                                              |   |  Balestras:         [====================  ] 295 / 300                        |   |
|                                                              |   |  Armas de Haste:    [==================    ] 250 / 300                        |   |
|                                                              |   |  Desarmado:         [==============        ] 190 / 300                        |   |
|                                                              |   |  Armaduras:         Tecido, Couro, Malha, Placas, Escudos                     |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | HONRA & JXJ (PVP)                                                             |   |
|                                                              |   |  Posto Atual: Sargento-Mor (Rank 5)      Progresso Semanal: [======== ] 42%   |   |
|                                                              |   |  Maior Posto Alcançado: Cavaleiro-Tenente (Rank 7)                            |   |
|                                                              |   |  Abates de Hoje:    14 HKs (182 Honra)   Abates de Ontem:   48 HKs (950 Honra)|   |
|                                                              |   |  Esta Semana:      124 HKs (3.410 Honra) Total da Vida:   1.842 HKs (0 DKs)   |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | REPUTAÇÕES & FACÇÕES                                                            |   |
|                                                              |   |  Ventobravo (Stormwind)    [========================] Exaltado    (1.000/999) |   |
|                                                              |   |  Altaforja (Ironforge)     [====================    ] Reverenciado(14.200/21k)|   |
|                                                              |   |  Darnassus                 [==============          ] Honrado     (4.500/12k) |   |
|                                                              |   |  Alvorada Argêntea         [=================       ] Reverenciado(8.900/21k) |   |
|                                                              |   |  Círculo Cenariano         [============            ] Honrado     (2.100/12k) |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | IDIOMAS & HABILIDADES RACIAIS                                                 |   |
|                                                              |   |  Idiomas:  Comum (100%), Anão (Compreensão 0%)                                |   |
|                                                              |   |  Raciais:  O Espírito Humano (+5% Espírito), Diplomacia (+10% Reputação),     |   |
|                                                              |   |            Especialização em Espadas (+5 Perícia), Percepção (Furtividade)    |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |                                                                                       |
|                                                              |   +-------------------------------------------------------------------------------+   |
|                                                              |   | DETAIL CARD INFERIOR (ESTILO ZELDA / CONSOLE RPG):                            |   |
|                                                              |   | [ÍCONE] |cffe09a15Poder de Ataque Corpo a Corpo (Attack Power)|r               |   |
|                                                              |   | Aumenta o dano causado com armas brancas em 48.8 DPS. Base: 120 / Bônus: +564 |   |
|                                                              |   | [D-Pad Cima/Baixo] Rolar Página          [B] Voltar                           |   |
|                                                              |   +-------------------------------------------------------------------------------+   |
+--------------------------------------------------------------+---------------------------------------------------------------------------------------+
```

---

## 3. Mapeamento de APIs do WoW Vanilla 1.12.1 / Turtle WoW

| Seção | Dados Extraídos | Chamadas de API (WoW 1.12) |
| :--- | :--- | :--- |
| **Identidade** | Nome, Nível, Raça, Classe, Guilda | `UnitName("player")`, `UnitLevel("player")`, `UnitRace("player")`, `UnitClass("player")`, `GetGuildInfo("player")` |
| **Rank & XP** | Rank PvP atual, XP, XP Máx, Rested | `UnitPVPRank("player")`, `GetPVPRankInfo(...)`, `UnitXP("player")`, `UnitXPMax("player")`, `GetXPExhaustion()` |
| **Modos Turtle** | Hardcore, Slow&Steady, Warmode | Varredura de buffs no player (`UnitBuff("player", i)`) com checagem de texturas e nomes conhecidos |
| **Atributos Base** | Força, Agilidade, Vigor, Int, Espírito | `UnitStat("player", 1..5)` (retorna base, stat, posBuff, negBuff) |
| **Vida e Recursos**| HP Máx, Recurso Máx, Tipo (Fúria/Mana) | `UnitHealthMax("player")`, `UnitManaMax("player")`, `UnitPowerType("player")` |
| **Combate Melee** | AP, Dano, Speed, DPS, Crítico, Hit | `UnitAttackPower("player")`, `UnitDamage("player")`, `UnitAttackSpeed("player")`, `GetCritChance()` |
| **Combate Ranged**| Ranged AP, Dano, Speed, DPS, Crítico | `UnitRangedAttackPower("player")`, `UnitRangedDamage("player")`, `GetRangedCritChance()` |
| **Defesas** | Armadura, Defesa, Dodge, Parry, Block | `UnitArmor("player")`, `UnitDefense("player")`, `GetDodgeChance()`, `GetParryChance()`, `GetBlockChance()` |
| **Resistências** | Fogo, Natureza, Gelo, Sombra, Arcano | `UnitResistance("player", 1..6)` (retorna base, total, posBuff, negBuff) |
| **Profissões** | Primárias, Culinária, Pesca, Survival | `GetNumSkillLines()`, `GetSkillLineInfo(index)` |
| **Perícias Armas** | Espadas, Machados, Maças, Arcos, etc. | `GetSkillLineInfo(index)` sob o cabeçalho de Armas |
| **Honra & JxJ** | HKs Hoje/Ontem/Semana/Total, Pontos | `GetPVPRankInfo()`, `GetInspectHonorData()` |
| **Reputações** | Nome da Facção, Nível (Odiado..Exaltado) | `GetNumFactions()`, `GetFactionInfo(index)` |

---

## 4. Cronograma de Fases TESTÁVEIS Passo a Passo

Cada fase foi planejada para gerar um entregável **100% testável no jogo via `/reload`**. A IA **NÃO** avança para a fase seguinte sem a validação e autorização do usuário.

---

### 🟢 FASE 1: Reorganização da Barra de Abas em 2 Linhas (3+3) no MainMenu
> **Objetivo de Teste:** O jogador abre o menu principal e visualiza a barra superior do painel direito distribuída em **2 linhas de 3 botões centralizados**. Ao alternar abas com `[LB]` e `[RB]`, a navegação percorre as 6 abas sequencialmente (incluindo a nova aba *"Personagem"*), e o destaque visual transita perfeitamente entre a linha superior e a inferior.

- [ ] Modificar exclusivamente a estrutura de abas em `UI/MainMenu.lua` e `UI/MainMenuNav.lua`:
  - Inserir `{ id = "CHARACTER", name = "Personagem", shortName = "Personagem" }` na tabela `CFG.Tabs.list`.
  - Reorganizar a renderização geométrica da barra de abas em 2 linhas de 3 botões centralizados:
    - Linha 1: `Bolsas` (1), `Magias` (2), `Talentos` (3).
    - Linha 2: `Missões` (4), `Personagem` (5), `Opções` (6).
  - Atualizar o cálculo de navegação cíclica (`1..6`) nos métodos `CycleTabs`, `OnNextTab` e `OnPrevTab`.
- [ ] Criar o contêiner vazio hospedeiro `self.tabContainer.pages["CHARACTER"]` com texto temporário *"Aba Personagem - Módulo em Carregamento"*.
- [ ] Validar a sintaxe via `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 1):** O jogador recarrega a UI (`/reload`), abre o menu e valida se as abas agora ocupam 2 linhas de 3 botões centralizados e se a troca via `[LB]`/`[RB]` funciona sem erros de Lua.

---

### 🟢 FASE 2: Criação do Módulo Isolado `UI/CharacterScreen.lua` & ScrollFrame com D-Pad
> **Objetivo de Teste:** O arquivo `UI/CharacterScreen.lua` é criado de forma desacoplada e registrado no `.toc`. Ao abrir a aba "Personagem", o `MainMenu` chama o módulo, que renderiza seu contêiner com `ScrollFrame` no painel direito e permite rolar a tela verticalmente para cima e para baixo usando o D-Pad do controle.

- [ ] Criar o arquivo modular independente `UI/CharacterScreen.lua`:
  - Declarar namespace global `ConsoleMode_CharacterScreen = ConsoleMode_CharacterScreen or {}`.
  - Exportar para `ConsoleMode.characterScreen`.
  - Métodos do ciclo de vida: `Initialize()`, `AttachTo(parentFrame)`, `Show()`, `Hide()`, `OnDirection(direction)`.
- [ ] Registrar `UI/CharacterScreen.lua` no `ConsoleModeVanilla.toc`.
- [ ] Construir a infraestrutura de rolagem dentro de `UI/CharacterScreen.lua`:
  - Criar `ScrollFrame` e `ScrollChild` dimensionados para a área direita do menu.
  - Inserir blocos de teste com alturas definidas para simular o layout vertical "long-page".
  - Implementar método `CharacterScreen:Scroll(delta)` com cálculo de limites (`min` / `max`).
- [ ] No `MainMenuNav.lua`, quando a aba ativa for `CHARACTER`, encaminhar `UP` e `DOWN` do D-Pad para `ConsoleMode_CharacterScreen:OnDirection(direction)`.
- [ ] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 2):** O jogador seleciona a aba "Personagem" no menu e utiliza o D-Pad para rolar os blocos de teste verticalmente com fluidez.

---

### 🟢 FASE 3: Cards de Identidade, Base Stats e Recursos (Dados Reais)
> **Objetivo de Teste:** Os blocos de teste são substituídos pelos 3 primeiros cards reais preenchidos com os dados dinâmicos do personagem do jogador: Identidade/Bio, Base Stats no padrão BetterCharacterStats (5 atributos + Armadura) e Recursos (Vida, Mana/Fúria/Energia e taxas de regeneração — regen calculada pela técnica BCS na Fase 4).

- [ ] Implementar dentro de `UI/CharacterScreen.lua`:
  - **Card Identidade & Biografia:** Nome, Nível, Classe (colorida pela cor da classe), Raça, Guilda com patente, Posto PvP, barra de XP atual e detecção de auras do Turtle WoW (Hardcore/Turtle Mode).
  - **Card Atributos Primários:** Força, Agilidade, Vigor, Intelecto e Espírito via `UnitStat("player", 1..5)`, com exibição de valor base e bônus (`posBuff`/`negBuff`) em verde/vermelho.
  - **Card Recursos & Regeneração:** Vida máxima com HP/s (fora e dentro de combate), Recurso Máximo (Fúria, Energia ou Mana) e taxa estimada de MP5.
- [ ] Conectar os eventos de atualização de dados (`UNIT_STATS`, `UNIT_HEALTH`, `UNIT_MANA`, `PLAYER_XP_UPDATE`).
- [ ] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 3):** O jogador confere os valores numéricos dos seus atributos, ganha um buff (ex: Grito de Batalha, Intelecto Arcano) e confirma se os números e cores de bônus mudam em tempo real.

---

### 🟢 FASE 4: Cards de Estatísticas de Combate no padrão BetterCharacterStats (Base, Melee, Melee vs Boss, Ranged, Spell, Schools, Defenses, Defenses vs Boss + Resistências)
> **Objetivo de Teste:** A página passa a exibir os cards de combate **separados exatamente como o addon BetterCharacterStats separa** (dropdown `PLAYERSTAT_*`): Base Stats, Melee, Melee vs Boss, Ranged, Spell, Schools, Defenses, Defenses vs Boss — mais o card próprio de Resistências Elementais. Valores calculados pela técnica do BCS (fórmulas + scan de tooltips), sem número inventado.

- [ ] Implementar dentro de `UI/CharacterScreen.lua` (1 card por grupo BCS, full-width, pool fixo):
  - **Card Base Stats:** Força, Agilidade, Vigor, Intelecto, Espírito (`UnitStat` 1..5 com bônus verde/vermelho) + Armadura (`UnitArmor`).
  - **Card Melee:** Perícia de Arma, Dano main/off (`UnitDamage`), Velocidade (`UnitAttackSpeed`), Attack Power (`UnitAttackPower`), Hit melee, Crítico (`GetCritChance`).
  - **Card Melee vs Boss:** Perícia de Arma + Miss/Dodge do boss, redução de Glancing, Crit Cap e Crítico Efetivo vs alvo nível 63 (tabelas derivadas da perícia — técnica `BCS:SetBossMissChance/SetBossDodgeChance/SetBossGlanceReduction/SetBossCritCap/SetEffectiveBossCrit`).
  - **Card Ranged:** Perícia Ranged, Dano, Velocidade, Ranged AP, Hit, Crítico Ranged (oculto p/ classes com relíquia, regra BCS).
  - **Card Spell:** Spell Power, Hit mágico, Crítico mágico (`BCS:GetSpellCritChance`), Cura (+Heal), Regen de Mana (`BCS:GetManaRegen`: fórmula espírito/classe + scan MP5) e Spell Haste.
  - **Card Schools:** Spell Power por escola — Arcano, Fogo, Gelo, Sagrado, Natureza, Sombra (scan de bônus por escola).
  - **Card Defenses:** Armadura, Defesa (`UnitDefense`), Esquiva, Aparo, Bloqueio (`GetDodge/Parry/BlockChance`), Esquiva Total.
  - **Card Defenses vs Boss:** idem com diferencial +3 níveis (técnica `BCS:SetDodge/SetParry/SetBlock/SetTotalAvoidance` com `levelDiff = 3`).
  - **Card Resistências Elementais (próprio ConsoleMode):** barras proporcionais Fogo/Natureza/Gelo/Sombra/Arcano via `UnitResistance` real.
- [ ] Conectar os eventos `UNIT_ATTACK_POWER`, `UNIT_RANGED_ATTACK_POWER`, `UNIT_RESISTANCES` e `UNIT_INVENTORY_CHANGED` (o scan de gear re-roda sob `needScanGear`, padrão BCS).
- [ ] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 4):** O jogador equipa/desequipa arma/escudo e confirma DPS/Defesa/Bloqueio atualizando; compara cada card lado a lado com o BetterCharacterStats (modo comparação com strata rebaixado) e confirma fidelidade — incluindo Melee vs Boss e Mana Regen.

---

### 🟢 FASE 5: Cards de Profissões, Perícias de Armas, Honra/PvP e Reputações
> **Objetivo de Teste:** O jogador rola a ficha e visualiza suas profissões com barras de progresso `X/300` (incluindo Sobrevivência do Turtle WoW), perícias com armas, histórico de Honra/PvP e progresso com as facções principais.

- [ ] Implementar dentro de `UI/CharacterScreen.lua`:
  - **Card Profissões & Ofícios:** Varredura de `GetSkillLineInfo` para listar profissões primárias e secundárias com barras de progresso visual `X/300`.
  - **Card Perícias de Armas:** Leitura das armas utilizáveis pela classe com suas respectivas perícias atuais e tetos máximos.
  - **Card Honra & JxJ:** Posto atual, barra de progresso semanal, maior rank na carreira, abates com honra (hoje, ontem, semana e total) e dishonorable kills.
  - **Card Reputações & Facções:** Varredura de `GetFactionInfo` listando as facções principais com status de reputação (Neutro a Exaltado) e valores de barra.
  - **Card Idiomas & Raciais:** Lista de línguas dominadas e raciais passivas da raça do jogador.
- [ ] Conectar os eventos `SKILL_LINES_CHANGED`, `UPDATE_FACTION` e `PLAYER_PVP_KILLS_CHANGED`.
- [ ] Validar sintaxe com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 5):** O jogador compara os valores das barras de profissão, armas e reputações com as janelas padrão do jogo e confirma a fidelidade das informações.

---

### 🟢 FASE 6: Infraestrutura Oculta de Hover/Navegação por Slots, DetailCard & Polimento
> **Objetivo de Teste:** A matriz completa de navegação slot-a-slot está construída e registrada na memória, com suporte a foco individual e explicações detalhadas no `DetailCard`, mas **mantida desligada pela flag de controle** (`enableSlotNavigation = false`), com o D-Pad continuando a rolar a página diretamente.

- [ ] Implementar o sistema de navegação estruturada em `UI/CharacterScreen.lua`:
  - Criar tabela de slots navegáveis `CharacterScreen.navSlots = {}`.
  - Registrar cada card e linha de atributo com coordenadas verticais de foco e dados explicativos.
  - Criar a flag de controle: `CharacterScreen.enableSlotNavigation = false`.
    - Quando `false` (padrão atual): D-Pad rola a página suavemente.
    - Quando `true` (modo futuro): D-Pad move a moldura de seleção slot por slot, centraliza o scroll e atualiza o `DetailCard`.
- [ ] Construir o `DetailCard` inferior no rodapé da página com ícone, título em âmbar (`|cffe09a15`) e texto explicativo com a fórmula de como cada atributo afeta o personagem na classe atual.
- [ ] Polimento tipográfico com fontes oficiais (`AlegreyaSans-Bold.ttf`, `AlegreyaSans-Medium.ttf`), paleta de cores e espaçamentos nobres.
- [ ] Validação de sintaxe final com `luac -p`.
- **🛑 PARADA CRÍTICA DE VALIDAÇÃO (FASE 6):** Teste geral do menu principal, alternância entre as 6 abas, rolagem fluida e ausência completa de qualquer erro de execução no Lua.

---

## 5. Estrutura de Arquivos

```
Interface/AddOns/ConsoleModeVanilla/
├── ConsoleModeVanilla.toc          <-- Adiciona UI\CharacterScreen.lua
├── UI/
│   ├── CharacterScreen.lua         <-- NOVO MÓDULO INDEPENDENTE (Cards, APIs, Scroll, Hover Slots)
│   ├── MainMenu.lua                <-- Modificação mínima: barra de abas em 2 linhas e hospedeiro da aba
│   ├── MainMenuNav.lua             <-- Ciclo de abas 1..6 no LB/RB e repasse do D-Pad para CharacterScreen
│   ├── MerchantMenu.lua            <-- Intocado (módulo independente existente)
│   ├── MailScreen.lua              <-- Intocado (módulo independente existente)
│   └── ...
└── docs/
    └── plano_de_feature_ABA_DO_PERSONAGEM.md <-- Este documento
```

---

> [!CAUTION]
> **LEMBRETE MANDATÓRIO FINAL:**
> - **NÃO FAZER PUSH SEM ORDEM EXPLÍCITA DO USUÁRIO NO CHAT.**
> - **QUANDO O USUÁRIO ORDENAR O PUSH, FAZER APENAS UMA VEZ E AGUARDAR ANTES DE QUALQUER NOVO PASSO.**
