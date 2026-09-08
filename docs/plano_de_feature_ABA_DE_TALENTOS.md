# Plano de Feature: ABA DE TALENTOS (ConsoleMode Main Menu)

> [!IMPORTANT]
> **REGRAS MANDATÓRIAS DE DESENVOLVIMENTO:**
> 1. **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW).
> 2. **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido usar operadores de Lua 5.1+ (como `#table`, usar `table.getn(t)` ou `getn(t)`), `continue` ou `goto`.
> 3. **Identidade Visual Rigorosa:** É de suma importância manter 100% da identidade visual já existente do projeto:
>    - **Tipografia:** Fontes embutidas `Marcellus-Regular.ttf` (títulos, abas e cabeçalhos), `AlegreyaSans-Bold.ttf` (corpo e destaque) e `AlegreyaSans-Medium.ttf` (subtítulos e indicadores).
>    - **Paleta de Cores:** Dourado âmbar clássico (`CFG.Tabs.activeColor` `{ r = 0.88, g = 0.60, b = 0.08 }` / `|cffe09a15`), cinza inativo (`{ r = 0.65, g = 0.65, b = 0.65 }`), texto branco puro (`|cffffffff`) e realces dourados (`highlightColor`).
>    - **Formatos e Backdrops:** Fundos escurecidos translúcidos (`Interface\Tooltips\UI-Tooltip-Background`, alpha 0.45-0.50), bordas 9-slice / tooltip borders suaves (`Interface\Tooltips\UI-Tooltip-Border`), cantos com insets padronizados, cards estilo console/Zelda.
>    - **Controles e Ícones:** Glifos do controle Xbox ([LB], [RB], [LT], [RT], [D-Pad], [A], [B]) nos rodapés e cabeçalhos.
> 4. **Validação de Sintaxe:** Todo arquivo `.lua` criado ou alterado deve ser validado via compilador de sintaxe (`luac -p`) antes de qualquer teste.
> 5. **Regra Crítica de Commit:** NUNCA fazer commit ou push sem o comando e autorização explícita do usuário.
> 6. **Regra de Parada Crítica de Fases:** NUNCA avançar para a fase seguinte sem fazer uma parada crítica, solicitar a validação do usuário no jogo via `/reload` e aguardar seu feedback/aprovação.
> 7. **Validação Incremental por Partes:** O desenvolvimento deve ser validado estritamente passo a passo com placeholders preliminares antes da inserção de conteúdos finais.

---

## 1. Visão Geral

Adicionar uma nova aba **TALENTOS** ao Main Menu do ConsoleMode Vanilla, posicionada logo após a aba "Livro de Magias" (SPELLS). A feature permite ao jogador visualizar e distribuir pontos de talento de forma 100% navegável via gamepad, sem necessidade de abrir o TalentFrame padrão da Blizzard.

### Por que essa feature?

O TalentFrame padrão da Blizzard foi projetado para mouse e teclado. Em modo console/gamepad, navegar a árvore de talentos com o cursor virtual é lento e frustrante. Uma UI customizada, projetada para D-Pad e botões de ombro, transforma a experiência de distribuição de talentos em algo fluido e imersivo.

### Premissas Técnicas

- **WoW 1.12 não tem spec ativa.** O jogador distribui pontos livremente entre as 3 árvores.
- **API `LearnTalent(tabIndex, talentIndex)` disponível.** Permite gastar pontos programaticamente sem restrictions de secure frames (1.12 não tem taint system).
- **Turtle WoW usa DBCs padrão 1.12** com talent trees customizadas. As APIs retornam dados corretos automaticamente.
- **Não capturar keybinding N** nesta fase — o TalentFrame padrão continua acessível para comparação.

---

## 2. Arquitetura de Telas

A aba TALENTS possui **duas telas internas** com navegação hierárquica:

```
┌─────────────────────────────────────────┐
│           MAIN MENU (existent)           │
│  ┌─────┐ ┌────────────────────────────┐ │
│  │     │ │ Bolsas │ Magias │TALENTOS│ │
│  │ 3D  │ │        │        │ Missões│ │
│  │ Mod │ │   Content Area              │ │
│  │     │ │                             │ │
│  │     │ │  ┌─────────────────────┐   │ │
│  │     │ │  │  TELA 1: 3 BOTS DE │   │ │
│  │     │ │  │  ESPECIALIZAÇÃO     │   │ │
│  │     │ │  └────────┬────────────┘   │ │
│  └─────┘ │           │ click          │ │
│          │  ┌────────▼────────────┐   │ │
│          │  │  TELA 2: ÁRVORE DE  │   │ │
│          │  │  TALENTOS (grid)    │   │ │
│          │  └─────────────────────┘   │ │
│          └────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Tela 1 → Tela 2
- **Entrar:** A ou D-Pad Baixo num botão de spec
- **Voltar:** B (volta pra Tela 1, NÃO fecha o MainMenu)

### Tela 2 → Tela 2 (troca de spec)
- **LB / RB / LT / RT:** Cicla entre as 3 specs sem sair da Tela 2

---

## 3. Tela 1 — Seleção de Especialização

### 3.1 Layout

Três botões grandes posicionados horizontalmente no content area:

```
┌──────────────────────────────────────────────┐
│       Escolha uma Especialização              │
│                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │  ████    │ │  ████    │ │  ████    │    │  ← imagem de fundo
│  │  ████    │ │  ████    │ │  ████    │    │    da spec
│  ├──────────┤ ├──────────┤ ├──────────┤    │
│  │Elemental │ │Enhancement│ │Restoration│   │  ← nome
│  │  12 pts  │ │  31 pts  │ │   8 pts  │    │  ← pontos investidos
│  └──────────┘ └──────────┘ └──────────┘    │
│                                              │
│           Pontos restantes: 5                │
└──────────────────────────────────────────────┘
```

### 3.2 Dados por botão

Cada botão usa dados de `GetTalentTabInfo(tabIndex)`:
- **Nome** (1º retorno): exibido como texto do botão
- **Background** (4º retorno): textura de fundo do botão
- **Pontos investidos** (3º retorno): exibido abaixo do nome

### 3.3 Painel de detalhe

Ao focar um botão, o detail card mostra nome, descrição temática (definida em `CFG.Talents.Specs`) e pontos investidos.

### 3.4 Navegação

| Input | Ação |
|-------|------|
| D-Pad ←/→ | Navega entre os 3 botões |
| A | Entra na Tela 2 |
| B | Fecha o MainMenu |
| LB/RB/LT/RT | Cicla entre os 3 botões |

---

## 4. Tela 2 — Árvore de Talentos (Grid 7×4)

### 4.1 Layout

Grid limpo com slots posicionados conforme a tree original do WoW:

```
┌───────────────────────────────────────────────────┐
│  ◄  Elemental                        12 pts gastos│  ← Header
├───────────────────────────────────────────────────┤
│                                                   │
│      [T1C1]   [T1C2]   [T1C3]   [T1C4]          │  Tier 1
│               [T2C2]   [T2C3]                     │  Tier 2
│      [T3C1]            [T3C3]   [T3C4]           │  Tier 3
│               ...                                 │
│               [T7C2]   [T7C3]              [T7C4]★│  Tier 7
│                                                   │
├───────────────────────────────────────────────────┤
│  [B] Voltar          Pontos: 5 restantes  de 51   │  ← Footer
└───────────────────────────────────────────────────┘
```

- **Posição de cada talento**: determinada por `GetTalentInfo(tab, index)` → retorna `tier` (1-7) e `column` (1-4)
- **Slots vazios**: invisíveis, ignorados na navegação D-Pad
- **Talento ultimate** (Tier 7): só disponível com 31+ pontos na spec

### 4.2 Componente de Slot

Cada slot mostra:
- Ícone do talento
- Rank numérico: `currentRank / maxRank`
- Dots de rank: `● ● ● ○ ○` (preenchidos = aprendidos)

### 4.3 Estados Visuais

| Estado | Cor/Borda | Condição |
|--------|-----------|----------|
| Disponível | Dourado, brilho total | Prereqs atendidos, pode upar |
| Aprendido | Dourado, dots parciais | Tem pontos, pode upar mais |
| Max Rank | Dourado sólido, todos dots | Rank máximo atingido |
| Bloqueado | Cinza, desaturado | Prereqs não atendidos |
| Vazio | Invisível | Sem talento nessa posição |

### 4.4 Pré-requisitos

Indicados por:
1. Estado bloqueado do slot (escurecido)
2. Texto no painel de detalhe: "Requer: [Nome] (Rank X/Y)"
3. Flash sutil ao desbloquear talentos dependentes

### 4.5 Navegação

| Input | Ação |
|-------|------|
| D-Pad ↑/↓/←/→ | Navega grid (pula slots vazios) |
| A | Gasta 1 ponto (LearnTalent) |
| B | Volta pra Tela 1 |
| LB/RB/LT/RT | Troca spec sem sair da Tela 2 |

---

## 5. Comportamento do Botão B

Ponto crítico de UX. O B precisa ter gate contextual:

```
B pressionado:
  → Se aba == TALENTS E Tela 2 ativa:
      Voltar pra Tela 1 (NÃO fechar menu)
  → Senão:
      Fechar MainMenu (comportamento padrão)
```

**Segurança:** O B só é sequestrado dentro da Tela 2 de talentos. Ao voltar pra Tela 1, retorna ao comportamento normal imediatamente.

---

## 6. Ação de Gastar Ponto

`LearnTalent(tabIndex, talentIndex)` é chamada diretamente — sem secure frames no 1.12.

### Validações pré-chamada:
1. `UnitCharacterPoints("player") >= 1` (tem pontos)
2. `currentRank < maxRank` (não está no máximo)
3. `meetsPrereq == true` (pré-requisitos atendidos)

### Feedback:
- Sucesso: flash visual + som `igSkillUp`
- Sem pontos: mensagem de aviso
- Rank máximo: mensagem de aviso
- Prereqs não atendidos: mensagem de aviso

---

## 7. Fases de Implementação & Validação Incremental

> [!IMPORTANT]
> **PROTOCOLO DE VALIDAÇÃO PASSO A PASSO:**
> Cada fase abaixo é uma etapa isolada de validação com **Parada Crítica Obrigatória**.
> O desenvolvedor só avança para a fase seguinte após a validação presencial do usuário no jogo via `/reload`.

### FASE 1 — Infraestrutura da Aba com Placeholder Visual
- [x] Adicionar `{ id = "TALENTS", name = "Talentos", shortName = "Talento" }` em `CFG.Tabs.list` (após `SPELLS`)
- [x] Criar page frame `ConsoleModeMM_Page_TALENTS` em `CreateTabContainer`
- [x] Implementar `SetupTalentsPage()` e `UpdateTalentsPage()` exibindo uma tela de placeholder elegante com a identidade visual completa do addon:
  - Fundo translúcido escurecido (`UI-Tooltip-Background`) e borda suave (`UI-Tooltip-Border`)
  - Cabeçalho com tipografia `Marcellus-Regular` e cor âmbar (`|cffe09a15`)
  - Subtítulo explicativo em `AlegreyaSans-Medium` confirmando a inicialização da aba
  - Rodapé com indicador de controle
- [x] Integrar no `SelectTab()` (preservando o palco 3D do personagem à esquerda via `RestorePlayerModel`)
- [x] Integrar no `CycleCategories()` (suporte a [LT]/[RT])
- [x] Validar sintaxe com `luac -p`
- [x] **PARADA CRÍTICA 1:** Solicitar teste do usuário no jogo via `/reload` para validar que a aba "Talentos" aparece na barra, alterna com [LB]/[RB] e renderiza o placeholder visual perfeitamente integrado.

### FASE 2 — Tela 1: Especializações com Placeholders de Imagem
- [x] Criar componente de botão de especialização (`SpecButton`) para as 3 specs da classe (lidas dinamicamente via `GetTalentTabInfo(1..3)` ou fallback)
- [x] Implementar um **placeholder visual no lugar de cada imagem de fundo** (área escura com borda e ícone/texto provisório, reservando as dimensões exatas para as texturas que o usuário irá fornecer posteriormente)
- [x] Exibir nome da especialização (`Marcellus-Regular`), pontos já investidos (`AlegreyaSans-Bold`, dourado) e overlay translúcido
- [x] Implementar foco e navegação horizontal D-Pad entre os 3 botões com highlight dourado clássico
- [x] Implementar o Detail Card inferior temático exibindo as informações da especialização focada
- [x] Validar sintaxe com `luac -p`
- [x] **PARADA CRÍTICA 2:** Solicitar teste do usuário no jogo via `/reload` para validar o layout dos 3 botões, placeholders de imagem, dados de pontos e navegação D-Pad.

### FASE 3 — Transição Tela 1 → Tela 2 com Placeholders de Árvore
- [x] Implementar transição ao pressionar **A** ou **D-Pad Baixo** em uma das 3 especializações
- [x] Ao invés de carregar a árvore completa de uma vez, exibir a **Tela 2 com um placeholder específico da especialização selecionada**:
  - Cabeçalho da spec selecionada com nome e pontos gastos
  - Área central com frame placeholder da árvore temática
  - Rodapé estilizado com indicação "[B] Voltar" e total de pontos restantes
- [x] Implementar o **Gate Contextual do Botão B** em `Keybindings.lua`:
  - Na Tela 2 de talentos, o botão B retorna para a Tela 1 (seleção de specs) e NÃO fecha o MainMenu
  - Na Tela 1 de talentos, o botão B fecha o MainMenu (comportamento padrão)
- [x] Permitir alternar entre os placeholders das 3 specs na Tela 2 via [LB]/[RB] e [LT]/[RT]
- [x] Validar sintaxe com `luac -p`
- [x] **PARADA CRÍTICA 3:** Solicitar teste do usuário no jogo via `/reload` para validar clique de entrada, transição de tela, alternância de specs e retorno pelo botão B.

### FASE 4 — Implementação Incremental das Árvores de Talentos (Árvore por Árvore)
Implementar e validar as árvores reais individualmente, garantindo máxima estabilidade:
- [x] **Sub-Fase 4.1: Árvore da Especialização 1**
  - Mapear talentos reais via `GetTalentInfo(1, index)`
  - Renderizar grid 7×4 de slots reais para a Spec 1 (ícones, rank `current/max`, dots indicadores, bordas por estado)
  - Detail card exibindo tooltip real do talento focado
  - **PARADA CRÍTICA 4.1:** Validação da Spec 1 no jogo via `/reload`
- [x] **Sub-Fase 4.2: Árvore da Especialização 2**
  - Mapear e renderizar grid 7×4 para a Spec 2
  - **PARADA CRÍTICA 4.2:** Validação da Spec 2 no jogo via `/reload`
- [x] **Sub-Fase 4.3: Árvore da Especialização 3**
  - Mapear e renderizar grid 7×4 para a Spec 3
  - **PARADA CRÍTICA 4.3:** Validação da Spec 3 no jogo via `/reload`

### FASE 5 — Ação de Gastar Ponto (LearnTalent)
- [x] Implementar método seguro `MainMenu:SpendTalentPoint(tabIndex, talentIndex)` com validações:
  1. Pontos disponíveis (`UnitCharacterPoints("player") >= 1`)
  2. Rank inferior ao máximo (`currentRank < maxRank`)
  3. Pré-requisitos cumpridos (`meetsPrereq == true`)
- [x] Feedback visual de flash no slot e áudio (`igSkillUp` / `igAbility`)
- [x] Atualização em tempo real do grid, pontos gastos e rodapé
- [x] Tratar evento `CHARACTER_POINTS_CHANGED` para sincronização
- [x] Validar sintaxe com `luac -p`
- [x] **PARADA CRÍTICA 5:** Solicitar teste de distribuição de pontos no jogo via `/reload`.

### FASE 6 — Imagens de Fundo Finais e Polish Visual
- [x] Suporte automático a texturas de fundo da Blizzard para as specs com fallback limpo
- [x] Inserir descrições temáticas das specs em `CFG.Talents.Specs`
- [x] Ajustes finais de responsividade, proporções e alinhamentos horizontais e verticais
- [x] Teste completo do fluxo de ponta a ponta
- [x] **VALIDAÇÃO FINAL**

---

## 8. Configuração de Áudio

| Evento | Som | Descrição |
|--------|-----|-----------|
| Entrar numa spec (Tela 1 → 2) | `igCharacterInfoTab` | Transição de tela |
| Gastar ponto | `igSkillUp` | Aprendizado |
| Rank máximo | `igAbility` | Conquista |
| Trocar spec (LB/RB) | `igCharacterInfoTab` | Ciclagem |

---

## 9. Arquivos Afetados

| Arquivo | Tipo de Mudança |
|---------|-----------------|
| `UI/MainMenu.lua` | Adicionar tab, criar page, implementar Setup/Update/Show, integrar SelectTab + CycleCategories |
| `Keybindings.lua` | Gate contextual do botão B para Tela 2 de talentos |
| `Cursor.lua` | Navegação D-Pad adaptada para grid 7×4 e botões de spec |
| `Media/` | Possíveis novas texturas (borda dourada de slot) |

---

## 10. Fora do Escopo (Esta Feature)

- Captura do keybinding N (abrir aba diretamente)
- Talent planner / build saver
- Comparação de builds entre specs
- Shared profiles entre personagens
- Animações complexas de transição

---

## 11. Documentos Relacionados

- **Design Spec completo:** `docs/superpowers/specs/2026-09-08-talents-tab-design.md`
- **Plano do Main Menu (referência):** `docs/plano_de_feature_MAIN_MENU.md`

---

## 12. Critérios de Aceite

1. Aba TALENTS aparece na tab bar do MainMenu após "Livro de Magias"
2. Tela 1 mostra 3 botões de spec com imagem, nome e pontos investidos
3. Ao clicar numa spec, entra na Tela 2 com grid de talentos
4. Grid mostra todos os talentos nas posições corretas (tier × column)
5. Estados visuais estão corretos (disponível, aprendido, max, bloqueado)
6. Botão A gasta ponto com validações corretas
7. Botão B volta pra Tela 1 (não fecha menu) estando na Tela 2
8. LB/RB troca spec na Tela 2 sem voltar pra Tela 1
9. Painel de detalhe mostra info do talento focado
10. Tudo funciona via gamepad sem necessidade de mouse
