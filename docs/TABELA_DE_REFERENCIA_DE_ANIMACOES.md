# Tabela de Referência de Animações M2 (WoW Vanilla 1.12.1)

Este documento contém o catálogo completo das sequências de animação (`Sequence IDs`) do motor de renderização de modelos 3D (`.m2`) e da base de dados `AnimationData.dbc` do World of Warcraft 1.12.1.

---

## 📌 Diagnóstico Técnico de Comportamento no PlayerModel

### 1. Animações de Magia e Emotes (100% Fluidas)
- **IDs:** `53` (`SpellCastDirected`), `54` (`SpellCastOmni`), `124` (`ChannelCastDirected`), `125` (`ChannelCastOmni`), `55` (`BattleRoar`), `68` (`EmoteCheer`), `69` (`EmoteDance`), `82` (`EmoteFlex`), etc.
- **Comportamento:** Executam com suavidade total a 60 FPS nos frames de interface `PlayerModel`.

### 2. Animações Melee com Arma Embainhada (Flickering nos IDs 17 e 18)
- **IDs:** `17` (`Attack1H`), `18` (`Attack2H`).
- **Por que ocorre o flickering:** No motor `.m2`, as sequências `Attack1H` e `Attack2H` realizam a interpolação dos ossos de empunhadura da arma (`Hand Bone Attachment`). Em janelas de interface (UI), o modelo do jogador encontra-se com as armas embainhadas (`Sheathed Attachment` na cintura/costas). O motor tenta alternar bruscamente entre a pose embainhada e a mão armada durante o balanço, gerando artefato visual de flickering.
- **Alternativas Fluidas para Golpes Físicos:**
  - `57`: **Special1H** (Habilidade especial com uma mão)
  - `58`: **Special2H** (Habilidade especial com duas mãos)
  - `95`: **Kick** (Chute frontal)
  - `126`: **Whirlwind** (Redemoinho / giro 360°)
  - `82`: **EmoteFlex** (Pose de força corporal)

---

## 📋 Catálogo Completo de IDs de Animação (.m2)

| ID | Nome Técnico (.m2 / DBC) | Descrição do Movimento | Categoria |
| :---: | :--- | :--- | :--- |
| **0** | `Stand` | Posição de repouso / respiração idle padrão | Base |
| **1** | `Death` | Animação de cair morto no chão | Combate / Morte |
| **2** | `Spell` | Canalização mágica simples | Magia |
| **3** | `Stop` | Parada de movimento | Movimentação |
| **4** | `Walk` | Caminhada padrão | Movimentação |
| **5** | `Run` | Corrida padrão | Movimentação |
| **6** | `Dead` | Corpo estirado no chão sem movimento | Morte |
| **7** | `Rise` | Levantar-se do chão / ressuscitar | Morte / Ressurreição |
| **8** | `StandWound` | Reação ao receber dano leve (ombro/cabeça para trás) | Dano |
| **9** | `CombatWound` | Reação ao receber dano em combate | Dano |
| **10** | `CombatCritical` | Reação a dano crítico forte (corpo projetado para trás) | Dano |
| **11** | `ShuffleLeft` | Passo lateral para a esquerda | Movimentação |
| **12** | `ShuffleRight` | Passo lateral para a direita | Movimentação |
| **13** | `Walkbackwards` | Caminhada de marcha à ré | Movimentação |
| **14** | `Stun` | Atordoado / cambaleando com a cabeça baixa | Efeito de Controle |
| **15** | `HandsClosed` | Posição ereta com as mãos fechadas | Postura |
| **16** | `AttackUnarmed` | Soco / golpe desarmado | Combate Melee |
| **17** | `Attack1H` | Golpe de arma de uma mão | Combate Melee |
| **18** | `Attack2H` | Golpe pesado de arma de duas mãos | Combate Melee |
| **19** | `Attack2HL` | Golpe de arma de haste / cajado de duas mãos | Combate Melee |
| **20** | `ParryUnarmed` | Aparar golpe desarmado | Defensivo |
| **21** | `Parry1H` | Aparar golpe com arma de uma mão | Defensivo |
| **22** | `Parry2H` | Aparar golpe com arma de duas mãos | Defensivo |
| **23** | `Parry2HL` | Aparar golpe com arma de haste | Defensivo |
| **24** | `ShieldBlock` | Postura de bloqueio com escudo | Defensivo |
| **25** | `ReadyUnarmed` | Postura de guarda desarmado | Postura de Prontidão |
| **26** | `Ready1H` | Postura de guarda com arma de uma mão | Postura de Prontidão |
| **27** | `Ready2H` | Postura de guarda com arma de duas mãos | Postura de Prontidão |
| **28** | `Ready2HL` | Postura de guarda com arma de haste / cajado | Postura de Prontidão |
| **29** | `ReadyBow` | Postura de mira com arco | Longo Alcance |
| **30** | `Dodge` | Esquiva corporal rápida | Defensivo |
| **31** | `SpellPrecast` | Preparação e canalização de feitiço com mãos erguidas | Magia |
| **32** | `SpellCast` | Lançamento rápido de feitiço | Magia |
| **33** | `SpellCastArea` | Conjuração mágica em área com braços abertos | Magia |
| **34** | `NPCWelcome` | Saudação amigável de NPC | Social |
| **35** | `NPCGoodbye` | Despedida de NPC | Social |
| **36** | `Block` | Bloqueio padrão | Defensivo |
| **37** | `JumpStart` | Início do pulo | Movimentação |
| **38** | `Jump` | Meio do pulo no ar | Movimentação |
| **39** | `JumpEnd` | Aterrissagem do pulo | Movimentação |
| **40** | `Fall` | Queda contínua no ar | Movimentação |
| **41** | `SwimIdle` | Flutuação parada na água | Natação |
| **42** | `Swim` | Nado para frente | Natação |
| **43** | `SwimLeft` | Nado para a esquerda | Natação |
| **44** | `SwimRight` | Nado para a direita | Natação |
| **45** | `SwimBackwards` | Nado de costas | Natação |
| **46** | `AttackBow` | Disparo com arco | Longo Alcance |
| **47** | `FireBow` | Soltura da flecha do arco | Longo Alcance |
| **48** | `ReadyRifle` | Postura de mira com rifle/arma de fogo | Longo Alcance |
| **49** | `AttackRifle` | Disparo de rifle com recuo | Longo Alcance |
| **50** | `Loot` | Abaixar e saquear corpo/baú | Interação |
| **51** | `ReadySpellDirected` | Postura de mira mágica direcionada | Magia |
| **52** | `ReadySpellOmni` | Postura de prontidão mágica com mãos erguidas | Magia |
| **53** | `SpellCastDirected` | **Arremesso de magia para a frente com a mão aberta** | Magia Direta (Shocks/Bolts) |
| **54** | `SpellCastOmni` | **Conjuração mágica com ambas as mãos abertas** | Magia Omni (Totens/Buffs) |
| **55** | `BattleRoar` | **Rugido de batalha com a cabeça para trás** | Buff / Grito de Guerra |
| **56** | `ReadyAbility` | Postura de prontidão para habilidade especial | Combate |
| **57** | `Special1H` | Golpe especial com arma de uma mão | Combate Melee |
| **58** | `Special2H` | Golpe especial com arma de duas mãos | Combate Melee |
| **59** | `ShieldBash` | Pancada frontal com o escudo | Combate Melee |
| **60** | `EmoteTalk` | Gesto de conversa casual | Emote |
| **61** | `EmoteEat` | Sentar e comer | Emote / Consumível |
| **62** | `EmoteWork` | Animação de trabalho/forja | Emote |
| **63** | `EmoteUseStanding` | Interação de pé com objeto | Emote |
| **64** | `EmoteTalkExclamation` | Conversa enfática/exclamação | Emote |
| **65** | `EmoteTalkQuestion` | Gesto de dúvida/pergunta | Emote |
| **66** | `EmoteBow` | Reverência cortês curvando o tronco | Emote |
| **67** | `EmoteWave` | Aceno com a mão | Emote |
| **68** | `EmoteCheer` | Celebração erguendo os punhos para cima | Emote |
| **69** | `EmoteDance` | Dança completa da raça | Emote |
| **70** | `EmoteLaugh` | Risada com movimento de tronco | Emote |
| **71** | `EmoteSleep` | Deitar e dormir | Emote |
| **72** | `EmoteSitGround` | Sentar no chão | Emote |
| **73** | `EmoteRude` | Cruza os braços em sinal de provocação | Emote |
| **74** | `EmoteRoar` | Rugido emote | Emote |
| **75** | `EmoteKneel` | Ajoelhar-se em respeito | Emote |
| **76** | `EmoteKiss` | Mandar beijo | Emote |
| **77** | `EmoteCry` | Chorar cobrindo o rosto | Emote |
| **78** | `EmoteChicken` | Dança da galinha | Emote |
| **79** | `EmoteBeg` | Implorar com as mãos postas | Emote |
| **80** | `EmoteApplaud` | Bater palmas | Emote |
| **81** | `EmoteShout` | Grito com as mãos na boca | Emote |
| **82** | `EmoteFlex` | Pose de fisiculturista mostrando os músculos | Emote |
| **83** | `EmoteShy` | Gesto de timidez | Emote |
| **84** | `EmotePoint` | Apontar para frente com o dedo | Emote |
| **85** | `Attack1HPierce` | Estocada perfurante com arma 1H (adaga/espada) | Combate Melee |
| **86** | `Attack2HLoosePierce` | Estocada com arma 2H | Combate Melee |
| **87** | `AttackOff` | Golpe com a mão secundária (Dual Wield) | Combate Melee |
| **88** | `AttackOffPierce` | Estocada com a mão secundária | Combate Melee |
| **89** | `Sheath` | Guardar arma nas costas/cintura | Equipamento |
| **90** | `HipSheath` | Guardar arma na cintura | Equipamento |
| **91** | `Mount` | Montar em criatura | Montaria |
| **92** | `RunRight` | Corrida diagonal para direita | Movimentação |
| **93** | `RunLeft` | Corrida diagonal para esquerda | Movimentação |
| **94** | `MountSpecial` | Emote especial da montaria | Montaria |
| **95** | `Kick` | Chute frontal rápido | Combate Melee |
| **96** | `SitGroundDown` | Transição para sentar no chão | Movimentação |
| **97** | `SitGround` | Sentado no chão | Postura |
| **98** | `SitGroundUp` | Transição para levantar do chão | Movimentação |
| **99** | `SleepDown` | Transição para deitar | Movimentação |
| **100** | `Sleep` | Deitado dormindo | Postura |
| **101** | `SleepUp` | Transição para levantar da cama | Movimentação |
| **102** | `SitChairLow` | Sentar em banco baixo | Postura |
| **103** | `SitChairMed` | Sentar em cadeira média | Postura |
| **104** | `SitChairHigh` | Sentar em trono / cadeira alta | Postura |
| **105** | `LoadBow` | Encaixar flecha no arco | Longo Alcance |
| **106** | `LoadRifle` | Recarregar rifle | Longo Alcance |
| **107** | `AttackThrown` | Arremesso de arma de arremesso | Longo Alcance |
| **108** | `ReadyThrown` | Postura de arremesso | Longo Alcance |
| **109** | `HoldBow` | Segurar arco em repouso | Longo Alcance |
| **110** | `HoldRifle` | Segurar rifle em repouso | Longo Alcance |
| **111** | `HoldThrown` | Segurar adaga de arremesso | Longo Alcance |
| **112** | `LoadThrown` | Preparar arremesso | Longo Alcance |
| **113** | `EmoteSalute` | Continência militar | Emote |
| **114** | `KneelStart` | Transição para ajoelhar | Emote |
| **115** | `KneelLoop` | Ajoelhado em reverência contínua | Emote |
| **116** | `KneelEnd` | Transição para levantar-se | Emote |
| **117** | `AttackUnarmedOff` | Soco com a mão secundária | Combate Melee |
| **118** | `SpecialUnarmed` | Golpe especial desarmado | Combate Melee |
| **119** | `StealthWalk` | Caminhada furtiva (Rogue/Druid) | Furtividade |
| **120** | `StealthStand` | Postura parada furtiva | Furtividade |
| **121** | `Knockdown` | Derrubado no chão por impacto | Combate |
| **122** | `EatingLoop` | Mastigando comida | Consumível |
| **123** | `UseStandingLoop` | Interagindo com objeto continuamente | Interação |
| **124** | `ChannelCastDirected` | **Canalização mágica direcionada** (Drain Life, Mind Flay) | Magia Canalizada |
| **125** | `ChannelCastOmni` | **Canalização mágica de cura com mãos erguidas** (Healing Wave) | Cura / Suporte |
| **126** | `Whirlwind` | **Redemoinho / giro 360° completo com a arma** | Combate Físico |
| **127** | `Birth` | Animação de nascimento/surgimento | Criação |
| **128** | `UseStandingStart` | Início de uso de objeto | Interação |
| **129** | `UseStandingEnd` | Fim de uso de objeto | Interação |

---

## 🎮 Mapeamento Recomendado para o Grimório (ConsoleMode)

```lua
-- Magias Diretas de Dano (Earth Shock, Flame Shock, Lightning Bolt, Fireball)
pose = 53 -- SpellCastDirected (Arremesso frontal com a mão aberta)

-- Curas e Suporte (Healing Wave, Lesser Healing Wave, Rejuvenation)
pose = 125 -- ChannelCastOmni (Canalização contínua com mãos erguidas)

-- Totens e Escudos Elementais (Lightning Shield, Stoneskin Totem, Bênçãos)
pose = 54 -- SpellCastOmni (Conjuração com ambas as mãos abertas)

-- Golpes Físicos / Melee (Rockbiter, Flametongue, Sinister Strike, Rend)
pose = 57 -- Special1H (Golpe especial sem conflito de ossos de arma)

-- Habilidades com Escudo (Block, Shield Block, Shield Bash)
pose = 24 -- ShieldBlock / 59 ShieldBash

-- Gritos de Guerra e Fúria (Bloodlust, Battle Shout, Bloodrage)
pose = 55 -- BattleRoar (Rugido de guerra)
```
