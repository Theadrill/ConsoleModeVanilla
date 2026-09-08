# Design Spec: Aba TALENTOS — ConsoleMode Vanilla

> **Versão do Jogo:** World of Warcraft Vanilla 1.12.1 (Turtle WoW)
> **Versão do Lua:** Lua 5.0 (FrameXML clássico). Proibido usar `#table`, `continue`, `goto` ou qualquer sintaxe Lua 5.1+.
> **Data:** 2026-09-08

---

## 1. Visão Geral

Adicionar uma nova aba **TALENTOS** ao Main Menu do ConsoleMode, posicionada logo após a aba "Livro de Magias" (SPELLS). A aba implementa um sistema completo de visualização e distribuição de pontos de talento, 100% navegável via gamepad, substituindo a necessidade de abrir o TalentFrame padrão da Blizzard.

### Premissas

- **WoW 1.12 não tem spec ativa.** O jogador distribui pontos livremente entre as 3 árvores de talentos da sua classe.
- A aba possui **duas telas internas**: Seleção de Especialização (Tela 1) e Árvore de Talentos (Tela 2).
- **API disponível:** `LearnTalent(tabIndex, talentIndex)` permite gastar pontos programaticamente sem taint restrictions (1.12 não tem secure frames).
- O botão **B** do gamepad tem comportamento contextual: fecha o MainMenu na Tela 1, mas volta pra Tela 1 na Tela 2.
- **Não capturar o keybinding N** nesta fase — o TalentFrame padrão da Blizzard continua acessível via N para comparação/teste.

### 1.1 Identidade Visual Mandatória (Padrão Existente do Projeto)

> [!IMPORTANT]
> É de suma importância manter 100% da integridade visual e consistência com os módulos já existentes do ConsoleMode:
> 1. **Tipografia:** Uso exclusivo das fontes embutidas:
>    - `Marcellus-Regular.ttf` para títulos de abas, cabeçalhos de spec e destaques nobres.
>    - `AlegreyaSans-Bold.ttf` para textos de corpo, valores numéricos e nomes de talentos.
>    - `AlegreyaSans-Medium.ttf` para subtítulos, requisitos e legendas de controle.
> 2. **Paleta de Cores e Códigos Hex:**
>    - Dourado âmbar nobre (`CFG.Tabs.activeColor` `{ r = 0.88, g = 0.60, b = 0.08 }` ou `|cffe09a15`).
>    - Cinza inativo (`CFG.Tabs.inactiveColor` `{ r = 0.65, g = 0.65, b = 0.65 }`).
>    - Branco limpo (`|cffffffff`) e cinza informativo (`|cffaaaaaa`).
>    - Destaque dourado de foco (`CFG.Grid.highlightColor` `{ r = 1.0, g = 0.85, b = 0.2, a = 0.95 }`).
> 3. **Formatos, Backdrops e 9-Slice:**
>    - Texturas de fundo: `Interface\Tooltips\UI-Tooltip-Background` escurecido translúcido (alpha 0.45 a 0.50).
>    - Bordas: `Interface\Tooltips\UI-Tooltip-Border` com insets e espessuras idênticas às abas BAGS, SPELLS e QUESTS.
> 4. **Controles e Ícones Gráficos:**
>    - Ícones de botões de controle Xbox (`CFG.Icons.LB`, `CFG.Icons.RB`, `CFG.Icons.LT`, `CFG.Icons.RT`, `CFG.Icons.A`, `CFG.Icons.B`, `CFG.Icons.DPAD`) em rodapés e indicadores.

---

## 2. API de Talentos Disponível (WoW 1.12)

| Função | Retorno | Uso |
|--------|---------|-----|
| `GetNumTalentTabs()` | `numTabs` (integer) | Número de árvores de talento da classe |
| `GetTalentTabInfo(tabIndex)` | `name, icon, pointsSpent, background` | Dados da aba de spec |
| `GetNumTalents(tabIndex)` | `numTalents` (integer) | Total de talentos numa árvore |
| `GetTalentInfo(tabIndex, talentIndex)` | `name, icon, tier, column, currentRank, maxRank, isExceptional, meetsPrereq` | Dados de cada talento |
| `GetTalentPrereqs(tabIndex, talentIndex)` | `tier, column, isLearnable` | Pré-requisitos |
| `UnitCharacterPoints("player")` | `unspentPoints` | Pontos de talento disponíveis |
| `LearnTalent(tabIndex, talentIndex)` | — | Gasta 1 ponto no talento especificado |
| `GameTooltip:SetTalent(tab, index)` | — | Preenche tooltip com dados do talento |

**Eventos relevantes:**
- `CHARACTER_POINTS_CHANGED` — disparado quando pontos são ganhos ou gastos
- `SPELLS_CHANGED` — disparado quando um talento ensina nova spell/passiva

---

## 3. Fluxo de Navegação

```
[ABA TALENTS no MainMenu]
        │
        ▼
┌─────────────────────────────────┐
│  TELA 1: SELEÇÃO DE ESPEC       │
│                                  │
│  ┌──────┐  ┌──────┐  ┌──────┐  │
│  │  ELE │  │  ENH │  │  RES │  │
│  │ img  │  │ img  │  │ img  │  │
│  └──────┘  └──────┘  └──────┘  │
│  Elemental Enhancement Restoration│
│   12 pts    31 pts     8 pts   │
│                                  │
│  Pontos restantes: 5            │
└─────────────────────────────────┘
        │  A / D-Pad Baixo
        ▼
┌─────────────────────────────────┐
│  TELA 2: ÁRVORE DE TALENTOS     │
│                                  │
│     [C1]    [C2]    [C3]    [C4] │  Tier 1
│              [C2]    [C3]        │  Tier 2
│     [C1]            [C3]    [C4] │  Tier 3
│              ...                 │
│              [C2]    [C3]     ★  │  Tier 7
│                                  │
│  [B] Voltar    Pontos: 5/51     │
└─────────────────────────────────┘
```

---

## 4. Tela 1 — Seleção de Especialização

### 4.1 Layout

A Tela 1 ocupa todo o `ConsoleModeMM_TabContent` (rightPanel). O leftPanel (personagem 3D) permanece visível.

```
┌──────────────────────────────────────────────┐
│       Escolha uma Especialização              │  ← título centralizado
│                                              │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│   │          │ │          │ │          │    │
│   │  [IMG]   │ │  [IMG]   │ │  [IMG]   │    │  ← imagens de fundo
│   │          │ │          │ │          │    │     das specs
│   ├──────────┤ ├──────────┤ ├──────────┤    │
│   │Elemental │ │Enhancement│ │Restoration│   │  ← nome da spec
│   │  12 pts  │ │  31 pts  │ │   8 pts  │    │  ← pontos investidos
│   └──────────┘ └──────────┘ └──────────┘    │
│                                              │
│           Pontos restantes: 5                │  ← footer
└──────────────────────────────────────────────┘
```

### 4.2 Botão de Especialização (Componente)

Cada botão é composto por:

1. **Frame pai** (`Button`): dimensão fixa, layouts iguais para os 3
2. **Textura de fundo**: `GetTalentTabInfo(tabIndex)` retorna o path do background (ex: `Interface\TalentFrame\Background-Elemental`)
3. **Overlay escuro**: camada semi-transparente (`Interface\Tooltips\UI-Tooltip-Background`, alpha 0.4) sobre a imagem para legibilidade
4. **FontString nome**: texto centralizado abaixo da imagem, fonte `Marcellus-Regular`
5. **FontString pontos**: texto menor abaixo do nome, cor dourada, `"X pts"`
6. **Borda de foco**: textura de borda dourada que aparece quando o botão está selecionado pelo D-Pad

### 4.3 Estados Visuais do Botão

| Estado | Borda | Overlay | Significado |
|--------|-------|---------|-------------|
| **Inativo** | Sem borda | Escuro (alpha 0.5) | Sem foco do cursor |
| **Focado** | Dourada brilhante | Médio (alpha 0.35) | Cursor D-Pad está neste botão |
| **Hover** | Dourada sutil | Médio (alpha 0.35) | Mouse sobre (fallback para desktop) |

### 4.4 Dados exibidos por botão

Para cada uma das `GetNumTalentTabs()` specs:

- **Nome**: retornado por `GetTalentTabInfo(tabIndex)`
- **Background**: retornado por `GetTalentTabInfo(tabIndex)` (4º retorno)
- **Pontos investidos**: retornado por `GetTalentTabInfo(tabIndex)` (3º retorno)

### 4.5 Painel de detalhe (Tela 1)

Quando um botão de spec está focado, o painel de detalhe inferior (`detailCard`) mostra:

```
┌──────────────────────────────────────────────┐
│  [Ícone Grande]  Nome da Especialização       │
│                                              │
│  Descrição temática da spec (string fixa     │
│  por classe, definida em CFG.Talents.Specs)  │
│                                              │
│  XX pontos investidos nesta especialização   │
└──────────────────────────────────────────────┘
```

### 4.6 Navegação D-Pad (Tela 1)

| Input | Ação |
|-------|------|
| D-Pad Esquerda / Direita | Move foco entre os 3 botões |
| D-Pad Cima | N/A (sem ação) |
| D-Pad Baixo | N/A (sem ação) |
| A (Confirmar) | Entra na Tela 2 (árvore da spec focada) |
| B (Voltar) | Fecha o MainMenu (comportamento padrão) |
| LB / RB | Cicla foco entre os 3 botões |
| LT / RT | Cicla foco entre os 3 botões (consistente com LB/RB) |

---

## 5. Tela 2 — Árvore de Talentos

### 5.1 Layout Grid 7×4

A Tela 2 substitui o conteúdo da Tela 1 dentro do mesmo page frame. LeftPanel continua visível.

```
┌───────────────────────────────────────────────────────┐
│  ◄  Elemental                         12 pts gastos   │  ← Header
├───────────────────────────────────────────────────────┤
│                                                       │
│      [T1C1]   [T1C2]   [T1C3]   [T1C4]              │  Tier 1
│               [T2C2]   [T2C3]                         │  Tier 2
│      [T3C1]            [T3C3]   [T3C4]               │  Tier 3
│               [T4C2]   [T4C3]                         │  Tier 4
│      [T5C1]   [T5C2]            [T5C4]               │  Tier 5
│               [T6C2]   [T6C3]                         │  Tier 6
│               [T7C2]   [T7C3]              [T7C4] ★  │  Tier 7 (talento ultimate)
│                                                       │
├───────────────────────────────────────────────────────┤
│  [B] Voltar         Pontos: 5 restantes  de 51       │  ← Footer
└───────────────────────────────────────────────────────┘
```

- **7 tiers** (linhas), **4 colunas** possíveis
- Nem todas as posições têm talento — slots vazios são invisíveis e ignorados na navegação
- A posição `(tier, column)` de cada talento é dada por `GetTalentInfo(tab, index)`
- O **talento ultimate** (Tier 7) é marcado com ★ e só fica disponível com 31+ pontos na spec

### 5.2 Componente de Slot de Talento

Cada slot de talento visível é composto por:

```
┌────────────┐
│            │
│   [ICON]   │  ← textura do talento (GetTalentInfo retorna)
│            │
│   3 / 5    │  ← rank atual / rank máximo
│  ● ● ● ○ ○ │  ← dots indicando ranks aprendidos
│            │
└────────────┘
```

**Dimensões:** tamanho fixo (ex: 50×60 px), calculado proporcionalmente ao espaço disponível no content frame.

### 5.3 Estados Visuais do Slot

| Estado | Aparência | Condição |
|--------|-----------|----------|
| **Disponível** | Ícone brilho total, borda dourada, dots vazios | `meetsPrereq == true` E `currentRank < maxRank` E pontos disponíveis |
| **Aprendido** | Ícone brilho total, borda dourada, dots preenchidos parcialmente | `currentRank > 0` E `currentRank < maxRank` |
| **Max Rank** | Ícone brilho total, borda dourada sólida, todos os dots preenchidos | `currentRank == maxRank` |
| **Bloqueado** | Ícone escurecido (desaturado + alpha reduzido), sem borda | `meetsPrereq == false` |
| **Vazio** | Invisível (não criado) | Não existe talento nessa posição no grid |

### 5.4 Indicadores de Rank (Dots)

Abaixo do rank numérico, uma fileira de dots circulares:

- **Preenchido** (cor dourada): rank aprendido
- **Vazio** (cor cinza, contorno): rank disponível
- Quantidade total de dots = `maxRank` do talento

Exemplo para talento com maxRank 5 e currentRank 3:
```
● ● ● ○ ○
```

### 5.5 Pré-requisitos — Indicação Visual

Sem linhas de conexão entre talentos. A dependência é comunicada por:

1. **Estado do slot**: talento bloqueado fica escurecido/desaturado
2. **Tooltip no painel de detalhe**: ao focar um talento, mostra "Requer: [Nome] (Rank X/Y)" em vermelho se não atendido, verde se atendido
3. **Efeito de glow sutil** (opcional): quando um talento é aprendido, um flash breve nos talentos que ele desbloqueou

### 5.6 Painel de Detalhe (Tela 2 — bottom card)

Quando um talento está focado:

```
┌──────────────────────────────────────────────────┐
│  [Ícone Grande 40×40]  Chain Lightning           │
│                         Rank 2/3                 │
│                                                  │
│  Lança um raio que saltou para 3 alvos.          │
│  Causa 115 de dano natureza.                     │
│                                                  │
│  Próximo rank: 145 de dano natureza.             │
│                                                  │
│  Requer: Call of Thunder (2/5)     [em verde]    │
└──────────────────────────────────────────────────┘
```

**Dados exibidos:**
- Nome do talento: `GetTalentInfo(tab, index)` → 1º retorno
- Rank: `currentRank` / `maxRank`
- Descrição: `GameTooltip:SetTalent(tab, index)` → ler linhas do tooltip
- Requisitos: `GetTalentPrereqs(tab, index)` → buscar nome do talento prerequisite

### 5.7 Header da Tela 2

```
◄  [Nome da Spec]              [XX] pts gastos
```

- **◄** indicador de que LT/RT troca de spec
- **Nome da Spec**: retornado por `GetTalentTabInfo(tabIndex)`
- **Pontos gastos**: retornado por `GetTalentTabInfo(tabIndex)`

### 5.8 Footer da Tela 2

```
[B] Voltar         Pontos: [X] restantes  de [Y]
```

- **[B] Voltar**: indicador visual de que B volta pra Tela 1
- **Pontos restantes**: `UnitCharacterPoints("player")`
- **Total de pontos**: soma de todos os `pointsSpent` das 3 specs + pontos restantes

### 5.9 Navegação D-Pad (Tela 2)

| Input | Ação |
|-------|------|
| D-Pad Cima | Move foco para o talento mais próximo no tier acima |
| D-Pad Baixo | Move foco para o talento mais próximo no tier abaixo |
| D-Pad Esquerda | Move foca para o talento mais próximo à esquerda (mesmo tier) |
| D-Pad Direita | Move foco para o talento mais próximo à direita (mesmo tier) |
| A (Confirmar) | Gasta 1 ponto no talento focado (se disponível e não max) |
| B (Voltar) | Volta pra Tela 1 (**NÃO fecha** o MainMenu) |
| LB / RB | Troca spec ciclando (Elemental → Enhancement → Restoration) sem sair da Tela 2 |
| LT / RT | Troca spec ciclando (consistente com LB/RB) |

**Algoritmo de navegação D-Pad:**
1. A partir da posição atual `(tier, column)`, calcular a direção alvo
2. Buscar o slot existente mais próximo naquela direção
3. Se não houver slot na direção, manter posição atual
4. Atualizar foco e refresh do painel de detalhe

---

## 6. Integração com o MainMenu

### 6.1 Registro da Aba

Em `CFG.Tabs.list`, inserir após SPELLS:

```lua
{ id = "TALENTS", name = "Talentos", shortName = "Talento" }
```

### 6.2 Page Frame

Em `MainMenu:CreateTabContainer(rightPanel)`:

```lua
local pageTalents = CreateFrame("Frame", "ConsoleModeMM_Page_TALENTS", contentFrame)
pageTalents:SetAllPoints(contentFrame)
pages["TALENTS"] = pageTalents
```

### 6.3 Métodos necessários

| Método | Responsabilidade |
|--------|-----------------|
| `MainMenu:SetupTalentsPage(page)` | Cria componentes da Tela 1 e Tela 2 (lazy, uma única vez) |
| `MainMenu:UpdateTalentsPage(keepPage)` | Lê dados via API, renderiza estado atual |
| `MainMenu:ShowTalentSpecScreen()` | Mostra Tela 1, esconde Tela 2 |
| `MainMenu:ShowTalentTreeScreen(tabIndex)` | Mostra Tela 2 da spec especificada, esconde Tela 1 |
| `MainMenu:SelectTalentSpec(tabIndex)` | Navega para spec (usado por LB/RB/LT/RT na Tela 2) |
| `MainMenu:SpendTalentPoint(tabIndex, talentIndex)` | Wrapper seguro de `LearnTalent()` com validações |

### 6.4 Integração em SelectTab

```lua
elseif tabID == "TALENTS" then
    self:RestorePlayerModel()
    self:UpdateLayout()
    self:UpdateTalentsPage()
```

### 6.5 Integração em CycleCategories (LT/RT)

Na aba TALENTS, LT/RT tem comportamento contextual:
- **Tela 1**: cicla foco entre os 3 botões de spec
- **Tela 2**: troca a spec exibida (cicla entre as 3 árvores)

### 6.6 Modelo 3D

- **Tela 1**: `RestorePlayerModel()` — pose neutra
- **Tela 2**: `RestorePlayerModel()` — pose neutra (sem animação de spell)

### 6.7 Resumo de visibilidade por tela

| Componente | Tela 1 | Tela 2 |
|------------|--------|--------|
| LeftPanel (3D model) | Visível | Visível |
| TabBar | Visível | Visível |
| Header specs | Visível (título) | Visível (nome spec + pts) |
| Botões de spec (3x) | Visível | Oculto |
| Grid de talentos | Oculto | Visível |
| Painel de detalhe | Visível (info spec) | Visível (info talento) |
| Footer | Visível (pontos restantes) | Visível (voltar + pontos) |

---

## 7. Comportamento do Botão B (Gate Contextual)

### 7.1 Árvore de estados

```
MainMenu aberto (qualquer aba)
    │
    └── Aba TALENTS selecionada
        │
        ├── Tela 1 (specs) ativa
        │   └── B pressionado → Fecha MainMenu (padrão)
        │
        └── Tela 2 (árvore) ativa
            └── B pressionado → Volta pra Tela 1
                                NÃO fecha MainMenu
```

### 7.2 Implementação conceitual

O handler do B (em `Keybindings.lua` ou `Cursor.lua`) precisa verificar:

```
Se aba atual == "TALENTS" E Tela 2 está ativa:
    → Chamar MainMenu:ShowTalentSpecScreen()
    → Consumir o input (não propagar pra fechar menu)
Senão:
    → Comportamento padrão do B (fechar menu)
```

### 7.3 Segurança para explorer mode

- O B só é "sequestrado" quando o jogador está **na Tela 2 da aba TALENTS**
- Ao voltar pra Tela 1, o B retorna ao comportamento normal imediatamente
- Fora da aba TALENTS, tudo funciona como antes
- Não há risco de perder o uso do B em outros contextos

---

## 8. Ação de Gastar Ponto (LearnTalent Wrapper)

### 8.1 Validações antes de chamar LearnTalent

```lua
function MainMenu:SpendTalentPoint(tabIndex, talentIndex)
    -- 1. Verificar pontos disponíveis
    local unspent = UnitCharacterPoints("player")
    if unspent < 1 then return false, "NO_POINTS" end

    -- 2. Verificar dados do talento
    local name, _, tier, column, currentRank, maxRank, _, meetsPrereq =
        GetTalentInfo(tabIndex, talentIndex)
    if not name then return false, "INVALID_TALENT" end

    -- 3. Verificar rank máximo
    if currentRank >= maxRank then return false, "MAX_RANK" end

    -- 4. Verificar pré-requisitos
    if not meetsPrereq then return false, "PREREQS_NOT_MET" end

    -- 5. Gastar o ponto
    LearnTalent(tabIndex, talentIndex)
    return true
end
```

### 8.2 Feedback ao jogador

| Retorno | Feedback visual/sonoro |
|---------|----------------------|
| `true` | Flash no slot, play sound, refresh grid |
| `"NO_POINTS"` | Mensagem "Sem pontos de talento disponíveis" |
| `"MAX_RANK"` | Mensagem "Talento já está no rank máximo" |
| `"PREREQS_NOT_MET"` | Mensagem "Pré-requisitos não atendidos" |

### 8.3 Atualização automática

Após `LearnTalent()` bem-sucedido:
1. O evento `CHARACTER_POINTS_CHANGED` é disparado pelo cliente
2. O addon pode escutar este evento para chamar `UpdateTalentsPage()`
3. Ou atualizar imediatamente após a chamada (mais responsivo)

---

## 9. Dados de Configuração (CFG.Talents)

### 9.1 Estrutura proposta

```lua
CFG.Talents = {
    -- Layout do grid
    Grid = {
        slotWidth      = 50,     -- largura do slot de talento
        slotHeight     = 60,     -- altura do slot de talento
        gapX           = 12,     -- espaçamento horizontal entre slots
        gapY           = 10,     -- espaçamento vertical entre tiers
        cols           = 4,      -- colunas do grid
        tiers          = 7,      -- tiers do grid
    },

    -- Layout dos botões de spec (Tela 1)
    SpecButton = {
        width          = 140,    -- largura do botão
        height         = 160,    -- altura total (imagem + texto)
        imageHeight    = 110,    -- altura da imagem de fundo
        gap            = 20,     -- espaçamento entre botões
    },

    -- Cores
    Colors = {
        available      = { r = 0.88, g = 0.60, b = 0.08 },  -- dourado
        learned        = { r = 0.20, g = 0.80, b = 0.20 },  -- verde
        maxRank        = { r = 0.88, g = 0.60, b = 0.08 },  -- dourado sólido
        locked         = { r = 0.40, g = 0.40, b = 0.40 },  -- cinza
        dotEmpty       = { r = 0.30, g = 0.30, b = 0.30 },  -- cinza escuro
        dotFilled      = { r = 0.88, g = 0.60, b = 0.08 },  -- dourado
        headerText     = "|cffe09a15",                        -- código de cor WoW
    },

    -- Descrições das specs por classe (texto temático fixo)
    Specs = {
        ["SHAMAN"] = {
            [1] = { name = "Elemental",   desc = "Magia ofensiva — foco em feitiços de fogo, raio e natureza com alto dano em área." },
            [2] = { name = "Enhancement", desc = "Combatente corpo-a-corpo — foco em armas, Attack Power e golpes devastadores." },
            [3] = { name = "Restoration", desc = "Curador — foco em magias de cura, totems de suporte e sustain de grupo." },
        },
        -- Outras classes conforme necessário
    },

    -- Áudio
    Audio = {
        soundSpecSelect  = "igCharacterInfoTab",    -- som ao entrar numa spec
        soundTalentLearn = "igSkillUp",              -- som ao gastar ponto
        soundTalentMax   = "igAbility",              -- som ao atingir rank máximo
        soundNavigate    = nil,                      -- sem som de navegação extra
    },
}
```

---

## 10. Sequência de Eventos (Lifecycle)

### 10.1 Ao abrir a aba TALENTS

1. `SelectTab("TALENTS")` é chamado
2. Page frame `pages["TALENTS"]` fica visível
3. `UpdateTalentsPage()` é chamado
4. `SetupTalentsPage()` roda na primeira vez (lazy init)
5. Tela 1 é mostrada (bots de spec)
6. Dados das specs são lidos via API
7. Bots são renderizados com pontos atuais
8. Cursor D-Pad é sincronizado no primeiro botão

### 10.2 Ao selecionar uma spec (entrar na Tela 2)

1. Usuário pressiona A ou D-Pad Baixo no botão de spec
2. `ShowTalentTreeScreen(tabIndex)` é chamado
3. Botões de spec são ocultados
4. Header é atualizado com nome da spec
5. Grid de talentos é populado via `GetTalentInfo()`
6. Cada talento é renderizado no slot correspondente `(tier, column)`
7. Estado visual é calculado para cada slot
8. Cursor D-Pad é sincronizado no primeiro talento disponível

### 10.3 Ao gastar um ponto

1. Usuário pressiona A num talento focado
2. `SpendTalentPoint(tabIndex, talentIndex)` é chamado
3. Validações são executadas
4. `LearnTalent(tabIndex, talentIndex)` é chamado
5. Flash visual no slot, som de aprendizado
6. Grid é atualizado (ranks, estados, dots)
7. Footer é atualizado (pontos restantes)
8. Header é atualizado (pontos gastos na spec)
9. Talentos desbloqueados pelo novo rank são recalculados

### 10.4 Ao trocar de spec na Tela 2 (LB/RB)

1. Usuário pressiona LB ou RB
2. Índice da spec é ciclado (1→2→3→1)
3. Grid é reconstruído com dados da nova spec
4. Header é atualizado
5. Cursor é reposicionado

### 10.5 Ao voltar pra Tela 1 (B na Tela 2)

1. Usuário pressiona B
2. Grid de talentos é ocultado
3. Botões de spec são mostrados
4. Foco retorna ao último botão de spec visitado
5. B retorna ao comportamento padrão

---

## 11. Dependências e Arquivos Afetados

| Arquivo | Mudança |
|---------|---------|
| `UI/MainMenu.lua` | Adicionar TALENTS a CFG.Tabs.list, criar page frame, implementar Setup/Update/Show methods, integrar em SelectTab e CycleCategories |
| `Keybindings.lua` | Gate contextual no handler do B para a Tela 2 |
| `Cursor.lua` | Navegação D-Pad adaptada para grid 7×4 e botões de spec |
| `ConsoleModeVanilla.toc` | Não requer mudança ( MainMenu.lua já é carregado) |
| `Media/` | Possíveis novas texturas de borda dourada para slots de talento |

---

## 12. Fora do Escopo (Esta Fase)

- Captura do keybinding N para abrir a aba TALENTS diretamente
- Talent planner / build saver
- Comparação de builds
- Shared profiles entre personagens
- Animações complexas de transição entre telas

---

## 13. Riscos e Mitigações

| Risco | Mitigação |
|-------|-----------|
| Grid 7×4 pode não caber em telas menores (Steam Deck) | Calcular slot size proporcional ao content frame; usar scroll se necessário |
| Talentos com posição não padrão no grid | Usar `tier` e `column` retornados por `GetTalentInfo()` como fonte da verdade |
| performance ao redesenhar grid a cada ponto gasto | Reutilizar frames dos slots; apenas atualizar texturas/estados |
| B sequestrado causando confusão | Feedback visual claro no footer ("[B] Voltar" aparece só na Tela 2) |
| Turtle WoW tem talent trees customizadas | `GetTalentInfo()` retorna dados do DBC do server — funciona automaticamente |
