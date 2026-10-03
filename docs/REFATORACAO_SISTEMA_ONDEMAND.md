# Refatoração: Sistema LoadOnDemand para Data Lake

> **Objetivo:** Dividir o addon em 2 repositórios modulares para otimizar tempo de login e consumo de memória RAM.

---

## Problema Atual

**ConsoleModeVanilla** carrega **~40 MB** no login:
- `Core + UI + Media`: **8 MB** (necessário sempre)
- `Data/`: **15.75 MB** (usado sob demanda)

**Impacto:**
- Tempo de login: ~3 segundos
- RAM ocupada: 40 MB desde o login
- Atualizações de dados forçam reload completo da UI

---

## Solução: Arquitetura LoadOnDemand

### Estrutura Final (2 Addons)

```
Interface/AddOns/
├── ConsoleModeVanilla/              [Core - Sempre Carregado]
│   ├── ConsoleModeVanilla.toc       (Core, UI, Keybindings)
│   ├── Core.lua
│   ├── UI/*.lua
│   ├── Media/*.tga                  (6.27 MB)
│   └── Data/
│       ├── CityServicesDB.lua       (147 KB - hot path, manter)
│       ├── NPCs/*.lua               (555 KB - hot path, manter)
│       ├── Locales/*.lua            (1.03 MB - necessário sempre)
│       ├── SellValues.lua           (321 KB - hot path)
│       ├── MapOverlayData.lua       (22 KB)
│       ├── Instances.lua            (8 KB)
│       ├── ZoneLevels.lua           (2 KB)
│       ├── ZonePositions.lua        (4 KB)
│       └── ClassTrainers.lua        (21 KB)
│
└── ConsoleModeVanilla-Data/         [Data Lake - LoadOnDemand]
    ├── ConsoleModeVanilla-Data.toc
    │   ## Interface: 11200
    │   ## Title: ConsoleMode Data Lake
    │   ## Notes: Offline database (spells, quests, items) for ConsoleMode
    │   ## Author: Rodrigo Vernaschi
    │   ## Version: 0.1.0
    │   ## LoadOnDemand: 1
    │   ## RequiredDeps: ConsoleModeVanilla
    │
    └── Data/
        ├── SpellDescDB_ptBR.lua      (5.97 MB)
        ├── SpellDescDB_ptBR_octo.lua (1 KB)
        ├── QuestDB_ptBR.lua          (4.17 MB)
        ├── ItemDB_ptBR.lua           (2.63 MB)
        ├── ItemDescDB_ptBR.lua       (0.98 MB)
        ├── SpellDescriptions_ptBR.lua (37 KB)
        └── TalentDescriptions_ptBR.lua (122 KB)
```

### Resultado

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| **Tempo de login** | ~3s | ~0.5s | **83% mais rápido** |
| **RAM no login** | 40 MB | 8 MB | **80% menos** |
| **RAM após uso** | 40 MB | 24 MB | **40% menos** |

---

## Plano de Execução (7 Fases Testáveis)

### ✅ Fase 0: Preparação
- [x] Criar este documento de planejamento
- [x] Push para documentar a estratégia

### 🔄 Fase 1: Criar Repositório GitHub
**Objetivo:** Criar repo `ConsoleModeVanilla-Data` no GitHub

**Ações:**
```bash
cd C:\PROJETOS
mkdir ConsoleModeVanilla-Data
cd ConsoleModeVanilla-Data
git init
gh repo create Theadrill/ConsoleModeVanilla-Data --private --source=. --remote=origin
```

**Estrutura inicial:**
```
ConsoleModeVanilla-Data/
├── .gitignore
├── README.md
├── ConsoleModeVanilla-Data.toc
└── Data/
    └── (vazio por enquanto)
```

**Teste:** Verificar repo existe no GitHub e clone funciona.

---

### 🔄 Fase 2: Mover Arquivos de Data
**Objetivo:** Transferir arquivos pesados para o novo addon

**Arquivos a mover do Core → Data addon:**
```
SpellDescDB_ptBR.lua           5.97 MB
SpellDescDB_ptBR_octo.lua      1 KB
QuestDB_ptBR.lua               4.17 MB
ItemDB_ptBR.lua                2.63 MB
ItemDescDB_ptBR.lua            0.98 MB
SpellDescriptions_ptBR.lua     37 KB
TalentDescriptions_ptBR.lua    122 KB
────────────────────────────────────
TOTAL MOVIDO:                  13.92 MB
```

**Arquivos que FICAM no Core:**
```
CityServicesDB.lua             147 KB  (hot path - mapa)
NPCs/*.lua                     555 KB  (hot path - mapa)
Locales/*.lua                  1.03 MB (necessário sempre)
SellValues.lua                 321 KB  (hot path - vendor)
MapOverlayData.lua             22 KB
Instances.lua, ZoneLevels.lua, etc.
```

**Ações:**
1. Copiar arquivos pesados para `ConsoleModeVanilla-Data/Data/`
2. Criar `.toc` com `LoadOnDemand: 1`
3. Criar `README.md` explicando o addon
4. Commit e push no repo Data

**Teste:** Copiar `ConsoleModeVanilla-Data/` para `Interface/AddOns/` e verificar que aparece na lista de addons (desabilitado por padrão).

---

### 🔄 Fase 3: Adicionar Loader Inteligente no Core
**Objetivo:** Criar sistema de carregamento automático

**Arquivo:** `ConsoleModeVanilla/Data/DataLoader.lua`

```lua
-- ============================================================================
-- ConsoleMode - Vanilla: Data Lake Loader (LoadOnDemand)
-- ============================================================================

local CM = ConsoleMode

CM.DataLake = CM.DataLake or {
    loaded = false,
    available = false,
    requestedBy = nil
}

-- Verifica se o addon de dados está instalado
function CM:CheckDataLakeAvailable()
    local name, title, notes, loadable, reason = GetAddOnInfo("ConsoleModeVanilla-Data")
    self.DataLake.available = (loadable ~= nil)
    return self.DataLake.available
end

-- Carrega o Data Lake sob demanda
function CM:LoadDataLake(requestedBy)
    if self.DataLake.loaded then
        return true, "already_loaded"
    end
    
    if not self:CheckDataLakeAvailable() then
        return false, "not_installed"
    end
    
    local loaded, reason = LoadAddOn("ConsoleModeVanilla-Data")
    
    if loaded then
        self.DataLake.loaded = true
        self.DataLake.requestedBy = requestedBy
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Data Lake carregado (13.92 MB) - via " .. (requestedBy or "manual"))
        return true, "loaded"
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[ConsoleMode]|r Erro ao carregar Data Lake: " .. (reason or "unknown"))
        return false, reason
    end
end

-- Fallback gracioso se Data Lake não estiver disponível
function CM:GetSpellDesc(spellId)
    if not self.DataLake.loaded then
        self:LoadDataLake("SpellBook")
    end
    
    if ConsoleMode_SpellDescDB and ConsoleMode_SpellDescDB[spellId] then
        return ConsoleMode_SpellDescDB[spellId]
    end
    
    return nil
end

function CM:GetQuestData(questId)
    if not self.DataLake.loaded then
        self:LoadDataLake("QuestLog")
    end
    
    if ConsoleMode_QuestDB and ConsoleMode_QuestDB[questId] then
        return ConsoleMode_QuestDB[questId]
    end
    
    return nil
end

function CM:GetItemName(itemId)
    if not self.DataLake.loaded then
        self:LoadDataLake("ItemLookup")
    end
    
    if ConsoleMode_ItemDB and ConsoleMode_ItemDB[itemId] then
        return ConsoleMode_ItemDB[itemId]
    end
    
    return nil
end

-- Auto-load ao abrir certas janelas
function CM:SetupDataLakeTriggers()
    -- Carregar ao abrir SpellBook
    hooksecurefunc("ToggleSpellBook", function(bookType)
        if not CM.DataLake.loaded then
            CM:LoadDataLake("SpellBook")
        end
    end)
    
    -- Carregar ao abrir Quest Log
    hooksecurefunc("ToggleQuestLog", function()
        if not CM.DataLake.loaded then
            CM:LoadDataLake("QuestLog")
        end
    end)
end

-- Inicializar verificação
CM:CheckDataLakeAvailable()
```

**Ações:**
1. Criar `DataLoader.lua`
2. Adicionar no `.toc` após `Core.lua`
3. Atualizar `UI/MainMenu.lua` para usar `CM:GetSpellDesc()` em vez de acessar direto

**Teste:** Abrir o jogo, verificar login rápido, abrir Main Menu → SpellBook e ver mensagem de carregamento.

---

### 🔄 Fase 4: Remover Arquivos Pesados do Core
**Objetivo:** Limpar repo Core após migração

**Ações:**
1. Deletar arquivos movidos de `ConsoleModeVanilla/Data/`
2. Atualizar `ConsoleModeVanilla.toc` (remover linhas dos arquivos deletados)
3. Commit com mensagem clara: "refactor: move data lake to separate LoadOnDemand addon"

**Teste:** 
- `/reload` no jogo com AMBOS addons habilitados
- Verificar que tudo funciona
- Desabilitar `ConsoleModeVanilla-Data` e verificar fallback gracioso

---

### 🔄 Fase 5: Atualizar Geradores Python
**Objetivo:** Scripts Python devem gerar arquivos no repo correto

**Arquivos a atualizar:**
```
C:\PROJETOS\CapycraftDB\tools\export_to_addon.py
```

**Mudança:**
```python
# Antes:
ADDON_PATH = "../ConsoleModeVanilla/Data"

# Depois:
CORE_ADDON_PATH = "../ConsoleModeVanilla/Data"      # CityServicesDB, NPCs, Locales
DATA_ADDON_PATH = "../ConsoleModeVanilla-Data/Data"  # SpellDescDB, QuestDB, ItemDB
```

**Ações:**
1. Atualizar lógica de export para separar arquivos
2. Rodar `export_to_addon.py` e validar destinos
3. Commit no CapycraftDB

**Teste:** Regenerar dados e verificar que vão para os lugares certos.

---

### 🔄 Fase 6: Documentação e README
**Objetivo:** Explicar aos usuários como instalar

**Ações:**
1. Atualizar `ConsoleModeVanilla/README.md` mencionando addon Data
2. Criar `ConsoleModeVanilla-Data/README.md` explicando propósito
3. Adicionar instruções de instalação em ambos

**Estrutura README Data:**
```markdown
# ConsoleModeVanilla-Data

Data Lake offline (13.92 MB) para o addon **ConsoleModeVanilla**.

## O que é?

Banco de dados completo de:
- **26.320 feitiços** traduzidos PT-BR
- **6.685 missões** do Turtle WoW
- **24.542 itens** catalogados

## Por que separado?

- **Login 83% mais rápido** (3s → 0.5s)
- **80% menos RAM** no login (40 MB → 8 MB)
- Carregamento sob demanda (LoadOnDemand)

## Instalação

1. Baixe e extraia em `Interface/AddOns/ConsoleModeVanilla-Data/`
2. **Requer:** ConsoleModeVanilla core addon
3. Habilite ambos addons no character select

## Uso

O addon carrega automaticamente quando você:
- Abre o Livro de Feitiços (SpellBook)
- Abre o Registro de Missões (Quest Log)
- Interage com Vendedores (Merchant)

## Desenvolvimento

Este addon é gerado automaticamente por scripts Python do projeto **CapycraftDB**.
```

**Teste:** Ler documentação e verificar clareza.

---

### 🔄 Fase 7: Testes Finais e Release
**Objetivo:** Validar tudo funciona em produção

**Checklist:**
- [ ] Login sem Data addon = Core funciona (com avisos)
- [ ] Login com Data addon = Carregamento LoD funciona
- [ ] Abrir SpellBook = Data carrega automaticamente
- [ ] Abrir Quest Log = Dados de missão aparecem
- [ ] Abrir Merchant = Preços e nomes corretos
- [ ] `/reload` = Tudo persiste corretamente
- [ ] Consumo de memória = <10 MB no login, ~24 MB após uso
- [ ] Performance = Sem lag ou freeze

**Ações finais:**
1. Criar release tag `v0.1.0-data-lake` em ambos repos
2. Atualizar `.toc` Version em ambos
3. Push final

---

## Compatibilidade e Rollback

### Se algo der errado:
1. Desabilitar `ConsoleModeVanilla-Data`
2. Reverter commit "refactor: move data lake" no Core
3. Os arquivos ainda existem no Git history

### Branch de segurança:
Antes da Fase 4, criar branch `pre-data-split` no Core para rollback fácil.

---

## Métricas de Sucesso

| KPI | Meta |
|-----|------|
| Tempo de login | <1s |
| RAM no login | <10 MB |
| RAM após uso completo | <25 MB |
| Tempo de carregamento Data Lake | <2s |
| Taxa de erro LoadOnDemand | 0% |

---

## Cronograma Estimado

| Fase | Tempo | Status |
|------|-------|--------|
| Fase 0: Preparação | 10 min | ✅ Concluído |
| Fase 1: Criar Repo | 15 min | 🔄 Próximo |
| Fase 2: Mover Arquivos | 20 min | ⏸️ Aguardando |
| Fase 3: Loader Inteligente | 30 min | ⏸️ Aguardando |
| Fase 4: Limpar Core | 15 min | ⏸️ Aguardando |
| Fase 5: Atualizar Geradores | 20 min | ⏸️ Aguardando |
| Fase 6: Documentação | 15 min | ⏸️ Aguardando |
| Fase 7: Testes Finais | 30 min | ⏸️ Aguardando |
| **TOTAL** | **~2.5 horas** | |

---

## Notas Técnicas

### Por que LoadOnDemand funciona no WoW 1.12?

O FrameXML do Vanilla já suporta `LoadAddOn()` nativamente. Addons grandes como **Atlas**, **pfQuest** e **aux-addon** já usam essa técnica.

### Ordem de carregamento:
1. WoW carrega `ConsoleModeVanilla` (RequiredDeps: nenhuma)
2. `ConsoleModeVanilla-Data` fica dormindo (LoadOnDemand: 1)
3. Ao chamar `LoadAddOn("ConsoleModeVanilla-Data")`, WoW carrega o `.toc` e executa todos os arquivos listados
4. Variáveis globais (`ConsoleMode_SpellDescDB`, etc.) ficam disponíveis

### Possível Fase 8 (futuro): Modularização Granular

Dividir Data em sub-módulos ainda menores:
```
ConsoleModeVanilla-Data-Spells/   (5.97 MB)
ConsoleModeVanilla-Data-Quests/   (4.17 MB)
ConsoleModeVanilla-Data-Items/    (3.61 MB)
```

Carrega apenas o necessário por contexto. Economia adicional de ~10-15 MB de RAM.

---

**Última atualização:** 2026-10-03 01:00 UTC  
**Status:** Fase 0 concluída, aguardando execução da Fase 1
