# Refatoração: Sistema de Localização Unificado

> **Objetivo:** Consolidar TODAS as traduções em um único addon genérico, facilitando a vida de tradutores e eliminando fragmentação.

---

## Problema Atual

### Fragmentação de Traduções

Hoje, um tradutor precisa editar arquivos em **3 lugares diferentes**:

```
ConsoleModeVanilla (Core):
├── Data/Locales/ptBR/
│   ├── UI.lua          (54 KB)   ← tradutor edita
│   ├── Grammar.lua     (47 KB)   ← tradutor edita
│   ├── Items.lua       (16 KB)   ← tradutor edita
│   ├── Spells.lua      (114 KB)  ← tradutor edita
│   ├── Talents.lua     (209 KB)  ← tradutor edita
│   └── NPC.lua         (601 KB)  ← tradutor edita
├── Data/Localization.lua          ← PT hardcoded no engine!
└── UI/MainMenu.lua                ← ~60 strings PT hardcoded!

ConsoleModeVanilla-Data:
└── Data/*_ptBR.lua    (13.59 MB) ← tradutor edita
```

**Total:** ~1.04 MB no Core + 13.59 MB no Data = **14.63 MB de traduções espalhadas**

### Impacto na Experiência do Tradutor

| Problema | Impacto |
|----------|---------|
| Arquivos em 2 addons diferentes | Confusão sobre onde editar |
| PT hardcoded no Core | Tradutor não consegue acessar |
| Nomes de arquivo com sufixo `_ptBR` | Tradutor precisa renomear tudo |
| Sem estrutura clara por idioma | Difícil criar nova tradução |

---

## Solução: Addon de Localização Genérico

### Arquitetura Alvo

```
ConsoleModeVanilla (Core) — INGLÊS MÍNIMO
├── ConsoleModeVanilla.toc
├── Core.lua, Hooks.lua, UI/*.lua, etc.
├── Data/Localization.lua        ← SÓ engine (sem PT hardcoded)
├── Data/DataLoader.lua          ← Detecta localization addon
├── Data/Locales/enUS/UI.lua     ← Fallback EN mínimo
└── Data/NPCs/*.lua, etc.        ← Dados de jogo (hot path)

ConsoleModeVanilla-Localization (LoadOnDemand) — TODAS AS TRADUÇÕES
├── ConsoleModeVanilla-Localization.toc
├── README.md                    ← Instruções para tradutor
└── Data/
    ├── language.lua             ← DEFINE O IDIOMA
    ├── UI.lua                   (54 KB)
    ├── Grammar.lua              (47 KB)
    ├── Items.lua                (16 KB)
    ├── Spells.lua               (114 KB)
    ├── Talents.lua              (209 KB)
    ├── NPC.lua                  (601 KB)
    ├── SpellDescDB.lua          (5.83 MB)
    ├── SpellDescriptions.lua    (37 KB)
    ├── QuestDB.lua              (4.07 MB)
    ├── ItemDB.lua               (2.57 MB)
    ├── ItemDescDB.lua           (0.95 MB)
    └── TalentDescriptions.lua   (122 KB)
```

**Total Localization addon:** ~14.6 MB (TUDO em um lugar só)

---

## Regras do Projeto

### Regra 1: Separação de Responsabilidades

| Addon | Conteúdo | Idioma |
|-------|----------|--------|
| **Core** | Lógica, UI, engine de localização, dados de jogo | Inglês (fallback) |
| **Localization** | Strings de interface, traduções de conteúdo, BDs de texto | Configurável via `language.lua` |

**Princípio:** Core funciona 100% em inglês sem nenhum addon de localização instalado.

### Regra 2: Repositório e Pasta do Addon por Idioma (`ConsoleModeVanilla-Localization-<LANG>`)

**PADRÃO:** `ConsoleModeVanilla-Localization-ptBR` (ou `ConsoleModeVanilla-Localization-ruRU`, `ConsoleModeVanilla-Localization-esES`)

**Motivo:** 
- No GitHub, cada comunidade mantém seu repositório dedicado.
- No WoW 1.12 (`Interface/AddOns/`), impede colisão de pastas e permite coexistência de múltiplos pacotes instalados.
- O Core detecta dinamicamente via `CM:GetLocalizationAddonName()` procurando primeiro `ConsoleModeVanilla-Localization-<activeLang>`.

### Regra 3: Arquivos Internos 100% Agnósticos (SEM Sufixos de Idioma)

**PROIBIDO dentro de `Data/`:** `GameLOC_ptBR.lua`, `flag_ptBR.tga`, `SpellDescDB_ptBR.lua`, `QuestDB_ptBR.lua`

**OBRIGATÓRIO dentro de `Data/`:** `GameLOC.lua`, `flag.tga`, `SpellDescDB.lua`, `QuestDB.lua`, `UI.lua`, `Grammar.lua`

**Motivo:** O tradutor de um novo idioma apenas clona o repositório como `ConsoleModeVanilla-Localization-<novoIdioma>`, edita `Data/language.lua` e traduz os arquivos existentes. **Nenhum arquivo interno é renomeado e o `.toc` nunca precisa ser alterado.**

### Regra 4: Zero PT Hardcoded no Core

**PROIBIDO:** Strings em português direto no código do Core:
```lua
-- ❌ ERRADO
frame.title:SetText("GRIMÓRIO & HABILIDADES")

-- ❌ ERRADO
DEFAULT_CHAT_FRAME:AddMessage("Addon SortBag não encontrado")
```

**OBRIGATÓRIO:** Uso de `CM:T()` com chave em inglês:
```lua
-- ✅ CORRETO
frame.title:SetText(CM:T("SPELLBOOK_TITLE"))

-- ✅ CORRETO
DEFAULT_CHAT_FRAME:AddMessage(CM:T("ADDON_SORTBAG_NOT_FOUND"))
```

**Motivo:** Core deve funcionar em inglês puro. Traduções ficam APENAS no Localization addon.

### Regra 5: Detecção Automática de Idioma

O Core NÃO deve ter lógica específica para cada idioma. A detecção deve ser genérica:

```lua
-- ✅ CORRETO (genérico)
if CM.Localization and CM.Localization.lang then
    activeLocale = CM.Localization.lang
end

-- ❌ ERRADO (hardcoded)
if CM_Langs["ptBR"] then
    activeLocale = "ptBR"
end
```

### Regra 6: Um Idioma por Vez (Limitação WoW 1.12)

**Realidade técnica:** WoW 1.12 não suporta addons com mesmo nome de pasta.

**Consequência:** Usuário só pode ter UM addon `ConsoleModeVanilla-Localization` instalado por vez.

**Solução futura:** Se alguém quiser distribuir Russo, renomeia para `ConsoleModeVanilla-Localization-RUS` antes de instalar. Assim pode coexistir com ptBR.

### Regra 7: Estrutura do `language.lua`

**Formato obrigatório:**

```lua
-- ============================================
-- LANGUAGE CONFIGURATION
-- ============================================
-- Translator: Change the values below to your language
-- ============================================

CM_LANG = "ptBR"                    -- Language code (ex: "RUS", "ESP", "FRA", "DEU")
CM_LANG_NAME = "Português (Brasil)" -- Human-readable language name
CM_LANG_FLAG = "Interface\\AddOns\\ConsoleModeVanilla-Localization\\Data\\flag.tga"

-- ============================================
-- DO NOT EDIT BELOW THIS LINE
-- ============================================
```

**Motivo:** Tradutor só precisa editar 3 linhas. Resto é automático.

---

## Fluxo do Tradutor (Experiência Alvo)

### Criar Nova Tradução (ex: Russo)

```
Passo 1: Baixar
   git clone https://github.com/Theadrill/ConsoleModeVanilla-Localization

Passo 2: Configurar Idioma
   Abrir Data/language.lua
   Mudar: CM_LANG = "ptBR" → CM_LANG = "RUS"
   Mudar: CM_LANG_NAME = "Português (Brasil)" → CM_LANG_NAME = "Русский"

Passo 3: Traduzir Arquivos
   Data/UI.lua         → traduzir strings da interface
   Data/Grammar.lua    → traduzir regras gramaticais
   Data/Items.lua      → traduzir nomes de itens
   Data/Spells.lua     → traduzir nomes de feitiços
   Data/Talents.lua    → traduzir nomes de talentos
   Data/NPC.lua        → traduzir nomes/roles de NPCs
   Data/SpellDescDB.lua    → traduzir descrições de feitiços
   Data/QuestDB.lua        → traduzir textos de missões
   Data/ItemDB.lua         → traduzir nomes de itens (DB)
   Data/ItemDescDB.lua     → traduzir descrições de itens
   Data/TalentDescriptions.lua → traduzir descrições de talentos

Passo 4: Testar
   Copiar pasta para Interface/AddOns/
   /reload no jogo
   Verificar se traduções aparecem

Passo 5: Distribuir
   (Opcional) Renomear pasta para ConsoleModeVanilla-Localization-RUS
   Criar release no GitHub
   Compartilhar com comunidade
```

**Tempo estimado:** Tradutor experiente, ~20-40 horas (depende do tamanho do conteúdo).

**NÃO precisa:**
- ❌ Editar código do Core
- ❌ Criar novo arquivo .toc
- ❌ Renomear centenas de variáveis
- ❌ Entender engine de localização
- ❌ Baixar outros idiomas

---

## Plano de Execução (7 Fases Testáveis)

### ✅ Fase 0: Preparação (Concluída)
- [x] Criar este documento de planejamento
- [x] Estabelecer regras do projeto
- [x] Definir estrutura alvo

---

### ✅ Fase 1: Reestruturar Repositório Data → Localization (Concluída)

**Objetivo:** Renomear e reorganizar o repositório atual para a nova estrutura.

**Ações:**

1.1. Renomear repositório no GitHub:
   - `ConsoleModeVanilla-Data` → `ConsoleModeVanilla-Localization`

1.2. Atualizar `.toc` com novo nome:
   ```
   ## Title: ConsoleMode - Localization
   ## Notes: Localization pack for ConsoleModeVanilla (all translations in one place)
   ```

1.3. Remover sufixos `_ptBR` dos arquivos:
   - `SpellDescDB_ptBR.lua` → `SpellDescDB.lua`
   - `QuestDB_ptBR.lua` → `QuestDB.lua`
   - `ItemDB_ptBR.lua` → `ItemDB.lua`
   - `ItemDescDB_ptBR.lua` → `ItemDescDB.lua`
   - `SpellDescriptions_ptBR.lua` → `SpellDescriptions.lua`
   - `TalentDescriptions_ptBR.lua` → `TalentDescriptions.lua`
   - `SpellDescDB_ptBR_octo.lua` → `SpellDescDB_octo.lua`

1.4. Criar `Data/language.lua`:
   ```lua
   CM_LANG = "ptBR"
   CM_LANG_NAME = "Português (Brasil)"
   CM_LANG_FLAG = "Interface\\AddOns\\ConsoleModeVanilla-Localization\\Data\\flag_ptBR.tga"
   ```

1.5. Atualizar variáveis globais nos arquivos (remover sufixo `_ptBR`):
   - `ConsoleMode_SpellDescDB` (sem `_ptBR`)
   - `ConsoleMode_QuestDB`
   - `ConsoleMode_ItemDB`
   - `ConsoleMode_ItemDescDB`

1.6. Atualizar `.toc` para carregar novos nomes:
   ```
   Data\language.lua
   Data\SpellDescDB.lua
   Data\SpellDescDB_octo.lua
   Data\SpellDescriptions.lua
   Data\QuestDB.lua
   Data\ItemDB.lua
   Data\ItemDescDB.lua
   Data\TalentDescriptions.lua
   ```

**Teste Fase 1:**
```
1. Fazer push do repositório renomeado
2. Clonar localmente
3. Verificar que todos os arquivos têm nomes corretos (sem _ptBR)
4. Verificar que language.lua existe e define CM_LANG = "ptBR"
5. luac -p em todos os .lua para validar sintaxe
```

**Resultado esperado:** Repositório renomeado, arquivos sem sufixo, language.lua criado.

---

### ✅ Fase 2: Mover Locales do Core para Localization Addon (Concluída)

**Objetivo:** Transferir arquivos de tradução do Core para o addon de localização.

**Ações:**

2.1. Copiar arquivos de `Core/Data/Locales/ptBR/` para `Localization/Data/`:
   - `UI.lua` → `Data/UI.lua`
   - `Grammar.lua` → `Data/Grammar.lua`
   - `Items.lua` → `Data/Items.lua`
   - `Spells.lua` → `Data/Spells.lua`
   - `Talents.lua` → `Data/Talents.lua`
   - `NPC.lua` → `Data/NPC.lua`
   - `flag_ptBR.tga` → `Data/flag_ptBR.tga`

2.2. Atualizar referências de caminho de flag em `UI.lua`:
   ```lua
   -- Antes:
   CM_Langs["ptBR"].flag = "Interface\\AddOns\\ConsoleModeVanilla\\Data\\Locales\\ptBR\\flag_ptBR.tga"
   
   -- Depois:
   CM_Langs["ptBR"].flag = "Interface\\AddOns\\ConsoleModeVanilla-Localization\\Data\\flag_ptBR.tga"
   ```

2.3. Atualizar `.toc` do Localization addon:
   ```
   Data\language.lua
   Data\UI.lua
   Data\Grammar.lua
   Data\Items.lua
   Data\Spells.lua
   Data\Talents.lua
   Data\NPC.lua
   Data\SpellDescDB.lua
   ...
   ```

2.4. Remover arquivos copiados do Core:
   - Deletar `Core/Data/Locales/ptBR/` (exceto manter enUS)

2.5. Atualizar `Core/ConsoleModeVanilla.toc`:
   - Remover linhas:
     ```
     Data\Locales\ptBR\UI.lua
     Data\Locales\ptBR\Grammar.lua
     Data\Locales\ptBR\Items.lua
     Data\Locales\ptBR\Spells.lua
     Data\Locales\ptBR\Talents.lua
     Data\Locales\ptBR\NPC.lua
     ```

**Teste Fase 2:**
```
1. Verificar que Localization addon tem TODOS os arquivos (6 do Locales + 7 DBs = 13 arquivos)
2. Verificar que Core não tem mais ptBR (só enUS)
3. luac -p em todos os .lua
4. Verificar tamanho do Localization addon (~14.6 MB)
5. Verificar tamanho do Core (~9.2 MB, redução de 1 MB)
```

**Resultado esperado:** Localization addon com 13 arquivos de tradução. Core limpo de ptBR.

---

### ✅ Fase 3: Extrair PT Hardcoded do Core (Concluída)

**Objetivo:** Remover todas as strings em português do código do Core, substituindo por `CM:T()`.

**Ações:**

3.1. **Inventário completo de strings PT hardcoded:**
   - `UI/MainMenu.lua`: ~60 strings
   - `UI/MerchantMenu.lua`: 1 string
   - `Data/Localization.lua`: PT literals (suffixes, prefixes, GameLOC strings)

3.2. **Criar mapeamento de chaves no `Localization/Data/UI.lua`:**

Adicionar ao final do arquivo `UI.lua` do Localization addon:

```lua
-- ============================================
-- MAINMENU STRINGS (extracted from hardcoded PT)
-- ============================================
CM_Langs["ptBR"].strings.STAT_STRENGTH = "Força: "
CM_Langs["ptBR"].strings.STAT_SPIRIT = "Espírito: "
CM_Langs["ptBR"].strings.SPELLBOOK_TITLE = "Grimório:"
CM_Langs["ptBR"].strings.SPELLBOOK_HEADER = "GRIMÓRIO & HABILIDADES"
CM_Langs["ptBR"].strings.SPELLBOOK_CHOOSE_SPEC = "Escolha uma Especialização ou Categoria"
CM_Langs["ptBR"].strings.SPELLBOOK_INSTRUCTIONS = "...Navegue com [D-Pad] ou [LT]/[RT] e selecione uma categoria do grimório..."
CM_Langs["ptBR"].strings.SPELLBOOK_FOOTER = "[D-Pad] Navegar • [A] Lançar Magia • [B] Voltar"
CM_Langs["ptBR"].strings.TALENTS_TITLE = "ESPECIALIZAÇÕES & TALENTOS"
CM_Langs["ptBR"].strings.TALENTS_CHOOSE_SPEC = "Escolha uma Especialização"
CM_Langs["ptBR"].strings.TALENTS_INSTRUCTIONS = "...selecione uma das 3 árvores de talentos..."
CM_Langs["ptBR"].strings.TALENTS_SPEC_PREFIX = "Especialização "
CM_Langs["ptBR"].strings.TALENTS_CHANGE_SPEC = "Trocar Especialização"
CM_Langs["ptBR"].strings.TALENTS_TRANSLATION_HEADER = "TRADUÇÃO (PORTUGUÊS)"
CM_Langs["ptBR"].strings.TALENTS_ORIGINAL_HEADER = "DESCRIÇÃO ORIGINAL (CLIENT EN)"
CM_Langs["ptBR"].strings.TALENTS_MAX_RANK = "Grau Máximo Aprendido"
CM_Langs["ptBR"].strings.TALENTS_REQUIREMENTS_NOT_MET = "Requisitos não atendidos"
CM_Langs["ptBR"].strings.TALENTS_NO_POINTS = "Sem pontos disponíveis"
CM_Langs["ptBR"].strings.QUESTS_TITLE = "DIÁRIO DE MISSÕES & MAPA MUNDI"
CM_Langs["ptBR"].strings.QUESTS_COUNT = "Missões: "
CM_Langs["ptBR"].strings.MAP_HEADER = "[ MAPA MUNDI & REGIÃO ]"
CM_Langs["ptBR"].strings.MAP_LOADING = "Carregando texturas da zona..."
CM_Langs["ptBR"].strings.MAP_SERVICES = "SERVIÇOS & NPCs"
CM_Langs["ptBR"].strings.QUEST_DETAILS = "Detalhes da Missão"
CM_Langs["ptBR"].strings.QUEST_SELECT_PROMPT = "Selecione uma missão na lista acima."
CM_Langs["ptBR"].strings.QUEST_FOOTER = "(A) Ler Missão • (X) Rastrear • (Y) Abandonar"
CM_Langs["ptBR"].strings.QUEST_EMPTY = "Nenhuma missão ativa no diário."
CM_Langs["ptBR"].strings.QUEST_NO_OBJECTIVES = "Sem objetivos específicos."
CM_Langs["ptBR"].strings.KEYBINDS_TITLE = "[A] Mapear | [X] Limpar | [LT]/[RT] Páginas | [B] Voltar"
CM_Langs["ptBR"].strings.KEYBINDS_HEADER = "Modo Console — Atalhos do Controle..."
CM_Langs["ptBR"].strings.KEYBINDS_FACE_BUTTONS = "BOTÕES FACIAIS (ABXY)"
CM_Langs["ptBR"].strings.KEYBINDS_CONTENT_SELECTOR = "[ SELETOR DE CONTEÚDO ]"
CM_Langs["ptBR"].strings.KEYBINDS_PAGE_FORMAT = "Página %d de %d"
CM_Langs["ptBR"].strings.KEYBINDS_NEXT = "Próxima >"
CM_Langs["ptBR"].strings.KEYBINDS_NATIVE_ACTION = "Ação Nativa do Jogo (Fixo)"
CM_Langs["ptBR"].strings.KEYBINDS_INVENTORY_ITEM = "Item do Inventário (Bolsas)"
CM_Langs["ptBR"].strings.ERROR_SORTBAG_NOT_FOUND = "Addon SortBag não encontrado — ORGANIZAR indisponível."
CM_Langs["ptBR"].strings.ERROR_NO_TALENT_POINTS = "Você não tem pontos de talento disponíveis."
CM_Langs["ptBR"].strings.QUEST_TRACKING_REMOVED = "[Missões] Rastreamento removido: %s"
CM_Langs["ptBR"].strings.QUEST_TRACKING_LIMIT = "[Missões] Limite de 5 missões rastreadas atingido."
CM_Langs["ptBR"].strings.QUEST_TRACKING_ADDED = "[Missões] Rastreamento ativado: %s"
CM_Langs["ptBR"].strings.QUEST_SHARE_NO_PARTY = "[Missões] É necessário estar em um grupo para compartilhar missões."
CM_Langs["ptBR"].strings.QUEST_SHARE_CANNOT = "[Missões] Esta missão não pode ser compartilhada."
CM_Langs["ptBR"].strings.QUEST_SHARED = "[Missões] Missão compartilhada: %s"
CM_Langs["ptBR"].strings.QUEST_FALLBACK = "Missão"
CM_Langs["ptBR"].strings.UI_POSITIONS_RESTORED = "Posições dos elementos de interface restauradas com sucesso!"
CM_Langs["ptBR"].strings.KEYBINDS_PAGE1_RESERVED = "O botão A na Página 1 é reservado para Pulo / Interagir."
CM_Langs["ptBR"].strings.MAPPINS_CANVAS_UNAVAILABLE = "[MapPins] canvas indisponível (abra o mapa)."
CM_Langs["ptBR"].strings.MAPPINS_NO_FRAME = "[MapPins] nenhum frame estranho visível"
CM_Langs["ptBR"].strings.MERCHANT_UNWANTED_ITEM = "O mercador não deseja esse item."
CM_Langs["ptBR"].strings.BAG_PICKER = "Bolsas"
CM_Langs["ptBR"].strings.CHARACTER_PICKER = "Personagem"

-- ============================================
-- ENGLISH FALLBACKS
-- ============================================
CM_Langs["enUS"] = CM_Langs["enUS"] or {}
CM_Langs["enUS"].strings = CM_Langs["enUS"].strings or {}
CM_Langs["enUS"].strings.STAT_STRENGTH = "Strength: "
CM_Langs["enUS"].strings.STAT_SPIRIT = "Spirit: "
CM_Langs["enUS"].strings.SPELLBOOK_TITLE = "Spellbook:"
CM_Langs["enUS"].strings.SPELLBOOK_HEADER = "SPELLBOOK & ABILITIES"
... (etc, todas as strings em inglês)
```

3.3. **Substituir strings hardcoded no `Core/UI/MainMenu.lua`:**

Exemplo (linha 1648):
```lua
-- Antes:
valueStr = "|cffffffff" .. GetStrength() .. "|r"
labelStr = "Força: "

-- Depois:
valueStr = "|cffffffff" .. GetStrength() .. "|r"
labelStr = CM:T("STAT_STRENGTH")
```

Repetir para todas as ~60 ocorrências.

3.4. **Extrair PT literals de `Core/Data/Localization.lua`:**

Mover para `Localization/Data/GameLOC.lua` (novo arquivo):

```lua
-- ============================================
-- GAMELOC LITERALS (PT-BR)
-- ============================================

CM_ITEM_SUFFIXES = {
    ["do Macaco"] = true,
    ["da Águia"] = true,
    ["do Urso"] = true,
    -- ... (resto dos suffixes)
}

CM_QUEST_ITEM_PREFIXES = {
    ["Chifre"] = true,
    ["Garra"] = true,
    ["Coração"] = true,
    -- ... (resto dos prefixes)
}

CM_GAMELOC_STRINGS = {
    PASSIVE = "Passiva",
    RANK_FORMAT = "Grau %1",
    MANA_COST = "de Mana",
    RAGE_COST = "de Fúria",
    ENERGY_COST = "de Energia",
    INSTANT = "Instantâneo",
    CHANNELED = "Canalizada",
    MELEE_RANGE = "Corpo a corpo",
    COOLDOWN = "Recarga: ",
    TOOLS_HEADER = "Ferramentas:",
    REAGENTS_HEADER = "Reagentes:",
    REQUIRES = "Requer",
    NEXT_RANK = "Próximo grau:",
    REQUIRES_TALENTS_FORMAT = "Requer %s ponto(s) em Talentos de %s",
    REQUIRES_SPELL_FORMAT = "Requer %s ponto(s) em %s",
    RANK_PROGRESS_FORMAT = "Grau %1/%2",
    -- ... (resto das strings)
}
```

E substituir no `Core/Data/Localization.lua`:

```lua
-- Antes:
local passiveText = "Passiva"

-- Depois:
local passiveText = (CM_GAMELOC_STRINGS and CM_GAMELOC_STRINGS.PASSIVE) or "Passive"
```

3.5. **Atualizar `.toc` do Localization addon:**
```
Data\language.lua
Data\UI.lua
Data\GameLOC.lua           ← NOVO
Data\Grammar.lua
...
```

**Teste Fase 3:**
```
1. luac -p em todos os arquivos modificados
2. grep "\"" no Core/UI/MainMenu.lua e verificar que não há strings PT
3. grep "Passiva\|Grau\|Mana\|Ferramentas" no Core/Data/Localization.lua (zero resultados)
4. Verificar que Localization/Data/UI.lua tem todas as novas chaves
5. Verificar que Localization/Data/GameLOC.lua existe e tem literais PT
```

**Resultado esperado:** Core 100% em inglês. Todas as strings PT movidas para Localization addon.

---

### ✅ Fase 4: Atualizar DataLoader para Detecção Genérica (Concluída)

**Objetivo:** DataLoader deve detectar qualquer localization addon, não apenas ptBR.

**Ações:**

4.1. Renomear addon detectado no DataLoader:

```lua
-- Antes:
function CM:CheckDataLakeAvailable()
    local name, title, notes, loadable, reason = GetAddOnInfo("ConsoleModeVanilla-Data")
    -- ...
end

-- Depois:
function CM:CheckLocalizationAvailable()
    local name, title, notes, loadable, reason = GetAddOnInfo("ConsoleModeVanilla-Localization")
    self.Localization = self.Localization or {}
    self.Localization.available = (loadable ~= nil)
    return self.Localization.available
end
```

4.2. Renomear função de carregamento:

```lua
-- Antes:
function CM:LoadDataLake(requestedBy)
    -- ...
    local loaded, reason = LoadAddOn("ConsoleModeVanilla-Data")
    -- ...
end

-- Depois:
function CM:LoadLocalization(requestedBy)
    if self.Localization.loaded then
        return true, "already_loaded"
    end
    
    if not self:CheckLocalizationAvailable() then
        return false, "not_installed"
    end
    
    local loaded, reason = LoadAddOn("ConsoleModeVanilla-Localization")
    
    if loaded then
        self.Localization.loaded = true
        self.Localization.lang = CM_LANG or "unknown"
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Localization loaded: " .. self.Localization.lang .. " (~14.6 MB)")
        return true, "loaded"
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[ConsoleMode]|r Failed to load localization: " .. (reason or "unknown"))
        return false, reason
    end
end
```

4.3. Atualizar triggers:

```lua
-- No MainMenu.lua OnShow:
-- Antes:
if ConsoleMode and ConsoleMode.LoadDataLake then
    ConsoleMode:LoadDataLake("MainMenu")
end

-- Depois:
if ConsoleMode and ConsoleMode.LoadLocalization then
    ConsoleMode:LoadLocalization("MainMenu")
end
```

4.4. Atualizar comando slash:

```lua
-- Antes:
SLASH_CMDATALAKE1 = "/cmdatalake"

-- Depois:
SLASH_CMLOC1 = "/cmloc"
SlashCmdList["CMLOC"] = function(msg)
    if msg == "load" then
        local success, reason = CM:LoadLocalization("SlashCommand")
        -- ...
    elseif msg == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Localization Status:")
        DEFAULT_CHAT_FRAME:AddMessage("  Available: " .. tostring(CM.Localization.available))
        DEFAULT_CHAT_FRAME:AddMessage("  Loaded: " .. tostring(CM.Localization.loaded))
        DEFAULT_CHAT_FRAME:AddMessage("  Language: " .. (CM.Localization.lang or "n/a"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Localization Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /cmloc load   - Force load localization addon")
        DEFAULT_CHAT_FRAME:AddMessage("  /cmloc status - Show status")
    end
end
```

**Teste Fase 4:**
```
1. luac -p no DataLoader.lua
2. grep "Data" no DataLoader.lua (verificar que não menciona "Data" addon)
3. grep "Localization" no DataLoader.lua (deve aparecer)
4. Verificar que MainMenu.lua chama LoadLocalization
5. Testar /cmloc status no jogo
```

**Resultado esperado:** DataLoader renomeado e funcionando com Localization addon.

---

### ✅ Fase 5: Atualizar Geradores Python (CapycraftDB) (Concluída)

**Objetivo:** Scripts Python devem gerar arquivos para o Localization addon (sem sufixos).

**Ações:**

5.1. Atualizar `CapycraftDB/tools/export_to_addon.py`:

```python
# Antes:
CORE_ADDON_PATH = "../ConsoleModeVanilla/Data"
DATA_ADDON_PATH = "../ConsoleModeVanilla-Data/Data"

# Depois:
CORE_ADDON_PATH = "../ConsoleModeVanilla/Data"
LOCALIZATION_ADDON_PATH = "../ConsoleModeVanilla-Localization/Data"

# Antes:
output_files = {
    "SpellDescDB_ptBR.lua": DATA_ADDON_PATH,
    "QuestDB_ptBR.lua": DATA_ADDON_PATH,
    "ItemDB_ptBR.lua": DATA_ADDON_PATH,
    # ...
}

# Depois:
output_files = {
    "SpellDescDB.lua": LOCALIZATION_ADDON_PATH,
    "QuestDB.lua": LOCALIZATION_ADDON_PATH,
    "ItemDB.lua": LOCALIZATION_ADDON_PATH,
    # ...
}

# Antes:
ConsoleMode_SpellDescDB_ptBR = {}

# Depois:
ConsoleMode_SpellDescDB = {}
```

5.2. Atualizar todos os geradores:
- `build_spelldescdb.py` → gera `SpellDescDB.lua` (sem `_ptBR`)
- `build_questdb.py` → gera `QuestDB.lua`
- `build_itemdb.py` → gera `ItemDB.lua`
- `build_itemdescdb.py` → gera `ItemDescDB.lua`

5.3. Testar regeneração:
```bash
cd C:\PROJETOS\CapycraftDB
python tools/export_to_addon.py
```

**Teste Fase 5:**
```
1. Rodar export_to_addon.py
2. Verificar que arquivos são gerados em Localization/Data/
3. Verificar que nomes NÃO têm sufixo _ptBR
4. Verificar que variáveis globais NÃO têm sufixo _ptBR
5. luac -p em todos os arquivos gerados
```

**Resultado esperado:** Geradores Python atualizados e funcionando.

---

### ✅ Fase 6: Documentação para Tradutores (Concluída)

**Objetivo:** Criar documentação clara para quem quiser traduzir.

**Ações:**

6.1. Criar `Localization/README.md`:

```markdown
# ConsoleModeVanilla - Localization Pack

This addon contains ALL translations for ConsoleModeVanilla.

## Current Language: Portuguese (Brazil)

To create a translation for your language, follow these steps:

### Step 1: Download
git clone https://github.com/Theadrill/ConsoleModeVanilla-Localization

### Step 2: Configure Language
Open `Data/language.lua` and change:
- `CM_LANG = "ptBR"` → `CM_LANG = "YourLangCode"`  (ex: "RUS", "ESP", "FRA")
- `CM_LANG_NAME = "Português (Brasil)"` → `CM_LANG_NAME = "Your Language Name"`

### Step 3: Translate Files

| File | Content | Estimated Lines |
|------|---------|-----------------|
| UI.lua | Interface strings (menus, buttons, messages) | ~300 |
| Grammar.lua | Grammar rules and term translations | ~200 |
| Items.lua | Item name mappings (common items) | ~100 |
| Spells.lua | Spell and buff name mappings | ~500 |
| Talents.lua | Talent name mappings by coordinates | ~800 |
| NPC.lua | NPC names and roles | ~9,500 |
| SpellDescDB.lua | Spell descriptions (full text) | ~26,000 |
| QuestDB.lua | Quest texts (titles, descriptions, objectives) | ~6,600 |
| ItemDB.lua | Item names database (all items) | ~24,500 |
| ItemDescDB.lua | Item descriptions and flavor text | ~5,000 |
| TalentDescriptions.lua | Talent description templates | ~300 |

**Total:** ~74,000 lines to translate

### Step 4: Test
1. Copy the folder to `Interface/AddOns/ConsoleModeVanilla-Localization`
2. Launch WoW and `/reload`
3. Open Console Mode (START button)
4. Verify translations appear correctly

### Step 5: Share
1. (Optional) Rename folder to `ConsoleModeVanilla-Localization-YourLang` to avoid conflicts
2. Create a release on GitHub
3. Share with the community!

## File Format Guidelines

### UI.lua
Strings use the format:
```lua
CM_Langs["YourLangCode"].strings.KEY = "Translated String"
```

### SpellDescDB.lua
Spells use the format:
```lua
ConsoleMode_SpellDescDB[spellID] = {
    n = "Spell Name",
    r = "Rank 1",
    d = "Description in English",
    t = "Tooltip text",
    pt = "Translated description"  -- Change 'pt' to your language code if you want
}
```

### QuestDB.lua
Quests use the format:
```lua
ConsoleMode_QuestDB[questID] = {
    T = "Quest Title",
    D = "Quest Description",
    O = "Quest Objectives"
}
```

## Questions?
Open an issue on GitHub: https://github.com/Theadrill/ConsoleModeVanilla/issues
```

6.2. Criar `Core/docs/TRANSLATOR_GUIDE.md`:

```markdown
# Translator Guide - ConsoleModeVanilla

## Overview

ConsoleModeVanilla uses a separate addon for translations called **ConsoleModeVanilla-Localization**.

All translation work happens in that addon. You do NOT need to edit the Core addon.

## Quick Start

1. Download: https://github.com/Theadrill/ConsoleModeVanilla-Localization
2. Edit `Data/language.lua` to set your language
3. Translate files in `Data/`
4. Install and test

See full guide in the Localization addon's README.

## Architecture

```
ConsoleModeVanilla (Core)
  ↓ requires
ConsoleModeVanilla-Localization (LoadOnDemand)
```

The Core addon works in English without any localization addon installed.
Installing the Localization addon adds translated text.

## Supported Languages

- Portuguese (Brazil) - `ptBR` (official)
- Your language here! (create a fork and translate)

## FAQ

**Q: Can I have multiple languages installed at once?**
A: Not with the same folder name. Rename one to `ConsoleModeVanilla-Localization-RUS` to install alongside ptBR.

**Q: Do I need to edit the .toc file?**
A: No! Just edit `language.lua` and translate the data files.

**Q: How long does translation take?**
A: ~20-40 hours for an experienced translator. The biggest files are SpellDescDB (~26k spells) and ItemDB (~24k items).

**Q: Can I use machine translation?**
A: You can use it as a starting point, but please review and correct for grammar, context, and game terminology.
```

6.3. Atualizar `Core/docs/REFATORACAO_SISTEMA_ONDEMAND.md`:
- Adicionar seção sobre Localization addon
- Explicar mudança de Data → Localization

**Teste Fase 6:**
```
1. Ler README.md do Localization addon (verificar clareza)
2. Ler TRANSLATOR_GUIDE.md do Core (verificar clareza)
3. Verificar links funcionam
4. Seguir o guia passo a passo simulando um tradutor novo
```

**Resultado esperado:** Documentação completa e clara para tradutores.

---

### ✅ Fase 7: Testes Finais e Validação (Concluída e Homologada)

**Objetivo:** Garantir que tudo funciona perfeitamente antes de release.

**Checklist de Testes:**

**7.1. Teste sem Localization addon (fallback EN):**
- [x] Core carrega sem erros
- [x] Interface aparece em inglês
- [x] Comandos funcionam
- [x] Mapa/NPCs funcionam (dados hot path)
- [x] Nenhuma mensagem de erro de localização

**7.2. Teste com Localization addon (ptBR):**
- [x] Login rápido (<1s)
- [x] Ao abrir Main Menu, aparece mensagem: "Localization loaded: ptBR (~14.6 MB)"
- [x] Interface aparece em português
- [x] Descrições de feitiços em PT (SpellDescDB)
- [x] Textos de missões em PT (QuestDB)
- [x] Nomes de itens em PT (ItemDB)
- [x] NPCs com nomes PT

**7.3. Teste comando `/cmloc`:**
- [x] `/cmloc status` mostra: Available: true, Loaded: true, Language: ptBR
- [x] `/cmloc load` (se já carregado): "already_loaded"

**7.4. Teste fallback gracioso:**
- [x] Desinstalar Localization addon
- [x] `/reload` no jogo
- [x] Core funciona em inglês sem erros
- [x] `/cmloc status` mostra: Available: false, Loaded: false

**7.5. Teste de tradução simulada (RUS):**
- [x] Copiar Localization addon
- [x] Editar `language.lua` → `CM_LANG = "RUS"`
- [x] Editar alguns valores em `UI.lua` para Russo (simulado)
- [x] Instalar e testar
- [x] Verificar que mensagem mostra "Localization loaded: RUS"
- [x] Verificar que strings alteradas aparecem em Russo

**7.6. Teste de performance:**
- [x] Medir tempo de login (deve ser <1s)
- [x] Medir memória RAM do Core no login (deve ser ~9-10 MB)
- [x] Medir memória RAM após carregar Localization (~24 MB total)
- [x] Verificar que não há lag ao abrir Main Menu

**7.7. Teste de regeneração (CapycraftDB):**
- [x] Rodar `python tools/export_to_addon.py`
- [x] Verificar que arquivos são gerados corretamente
- [x] Verificar que nomes não têm sufixo `_ptBR`
- [x] `luac -p` em todos os arquivos gerados
- [x] Verificar que variáveis globais não têm sufixo

**7.8. Validação Lua 5.0:**
- [x] `luac -p` em TODOS os .lua do Core
- [x] `luac -p` em TODOS os .lua do Localization
- [x] Verificar que não há `#t`, `continue`, `goto`, `table.unpack`
- [x] Verificar que não há `require()` ou `loadstring()`

**Resultado esperado:** Todos os testes passam. Sistema 100% funcional.

---

## Métricas de Sucesso

| KPI | Meta | Como Medir |
|-----|------|------------|
| **Tempo de login** | <1s | Cronometrar do character select até addon carregado |
| **RAM Core no login** | <10 MB | `/run DEFAULT_CHAT_FRAME:AddMessage(gcinfo())` ao entrar |
| **RAM após Localization** | ~24 MB | Após abrir Main Menu |
| **Arquivos que tradutor edita** | 12 em 1 addon | Contar arquivos em Localization/Data/ |
| **PT hardcoded no Core** | 0 strings | `grep -r "Força\|Missões\|Grimório" Core/` (zero resultados) |
| **Tamanho Localization** | ~14.6 MB | Somar todos os .lua |
| **Tempo para criar tradução** | <40h | Feedback de tradutor beta |

---

## Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Breaking changes ao extrair PT hardcoded | Média | Alto | Usar `CM:T()` com fallback para string original; testar extensivamente |
| Variáveis globais renomeadas quebram código | Baixa | Alto | Buscar todas as referências antes de renomear; atualizar geradores Python |
| Localization não carrega (LoadOnDemand falha) | Baixa | Médio | Fallback para EN funciona; adicionar debug logs |
| Tradutores confusos com novo fluxo | Média | Baixo | Documentação clara + README com exemplos |
| Conflito de nomes de addon (múltiplos idiomas) | Média | Baixo | Documentar que tradutor deve renomear pasta para coexistir |
| Performance ruim (14.6 MB de dados) | Baixa | Médio | LoadOnDemand já otimiza; testar em Steam Deck |

---

## Rollback Plan

Se algo der errado durante a refatoração:

**Fase 1-2:** 
- Reverter commits no Localization repo
- Manter Data addon antigo funcionando

**Fase 3-4:**
- Branch de segurança `pre-localization-refactor` no Core
- Reverter para branch se necessário

**Fase 5:**
- Geradores Python mantêm backup dos arquivos antigos
- Rollback via git no CapycraftDB

**Fase 6-7:**
- Apenas documentação, sem risco de quebrar código

---

## Cronograma Estimado

| Fase | Tempo Estimado | Complexidade | Status |
|------|----------------|--------------|--------|
| Fase 0: Preparação | 30 min | Baixa | ✅ Concluído |
| Fase 1: Reestruturar Repo | 45 min | Média | ✅ Concluído |
| Fase 2: Mover Locales | 30 min | Baixa | ✅ Concluído |
| Fase 3: Extrair PT Hardcoded | 2-3 horas | Alta | ✅ Concluído |
| Fase 4: Atualizar DataLoader | 30 min | Média | ✅ Concluído |
| Fase 5: Atualizar Geradores Python | 45 min | Média | ✅ Concluído |
| Fase 6: Documentação | 45 min | Baixa | ✅ Concluído |
| Fase 7: Testes Finais | 1-2 horas | Média | ✅ Concluído |
| **TOTAL** | **6-8 horas** | | **100% Homologado** |

---

## Status da Execução

**Status:** ✅ 100% CONCLUÍDO E HOMOLOGADO
- **Core (`ConsoleModeVanilla`):** Commit `7f6b3d8` (Core 100% EN limpo, stubs do engine em `Data/Localization.lua`, 1324 chaves sincronizadas em `Data/Locales/enUS/UI.lua`, zero PT em código executável).
- **Irmão ([ConsoleModeVanilla-Localization-ptBR](https://github.com/Theadrill/ConsoleModeVanilla-Localization-ptBR)):** Estrutura 100% agnóstica (`GameLOC.lua` + `flag.tga`), packs completos, 1324 chaves PT, overrides validados em jogo: Cabeça, Ajudantes, Vincula-se, Grau X, de Fera.

**Última atualização:** 2026-10-03 04:30 BRT

---

## Notas Finais

Este plano representa uma **refatoração major** do sistema de localização. Os objetivos foram plenamente atingidos:

1. ✅ **Simplificar a vida do tradutor** (1 addon, sem sufixos, sem renomear)
2. ✅ **Limpar o Core** (100% inglês, zero PT hardcoded)
3. ✅ **Manter performance** (LoadOnDemand, fallback gracioso)
4. ✅ **Preparar para múltiplos idiomas** (estrutura genérica, escalável)

**Benefício principal:** Tradutor baixa 1 addon, edita `language.lua`, traduz arquivos, pronto. Não precisa entender engine, não precisa tocar no Core, não precisa criar novos arquivos.

**Trade-off aceitável:** Não dá pra ter múltiplos idiomas no mesmo addon (limitação WoW 1.12). Solução: tradutor renomeia pasta se quiser coexistir com outro idioma.

**Próximos passos:** Sistema de localização concluído e homologado. Pronto para desenvolvimento de novas features.
