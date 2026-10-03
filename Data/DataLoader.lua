-- ============================================================================
-- ConsoleMode - Vanilla: Data Lake Loader (LoadOnDemand)
-- ============================================================================
-- Gerencia o carregamento sob demanda do addon ConsoleModeVanilla-Data.
-- O Data Lake contém 13.59 MB de dados (spells, quests, items) que só são
-- carregados quando necessário, otimizando o tempo de login.
-- ============================================================================

local CM = ConsoleMode

CM.DataLake = CM.DataLake or {
    loaded = false,
    available = false,
    requestedBy = nil,
    loadAttempts = 0
}

-- ============================================================================
-- Verificação de Disponibilidade
-- ============================================================================

function CM:CheckDataLakeAvailable()
    local name, title, notes, loadable, reason = GetAddOnInfo("ConsoleModeVanilla-Data")
    self.DataLake.available = (loadable ~= nil)
    
    if self.DataLake.available then
        CM:Log("DataLake addon detectado (disponível para carregamento)", "INFO")
    else
        CM:Log("DataLake addon não instalado - usando fallback", "WARN")
    end
    
    return self.DataLake.available
end

-- ============================================================================
-- Carregamento Sob Demanda
-- ============================================================================

function CM:LoadDataLake(requestedBy)
    -- Já carregado
    if self.DataLake.loaded then
        return true, "already_loaded"
    end
    
    -- Incrementar tentativas
    self.DataLake.loadAttempts = self.DataLake.loadAttempts + 1
    
    -- Verificar se está instalado
    if not self:CheckDataLakeAvailable() then
        return false, "not_installed"
    end
    
    -- Prevenir loops infinitos
    if self.DataLake.loadAttempts > 3 then
        CM:Log("DataLake: muitas tentativas de carregamento, abortando", "ERROR")
        return false, "too_many_attempts"
    end
    
    -- Tentar carregar
    local loaded, reason = LoadAddOn("ConsoleModeVanilla-Data")
    
    if loaded then
        self.DataLake.loaded = true
        self.DataLake.requestedBy = requestedBy
        
        -- Mensagem de sucesso no chat
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Data Lake carregado (13.59 MB) - via " .. (requestedBy or "manual"))
        
        CM:Log("DataLake carregado com sucesso via " .. (requestedBy or "manual"), "INFO")
        return true, "loaded"
    else
        -- Mensagem de erro
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[ConsoleMode]|r Erro ao carregar Data Lake: " .. (reason or "unknown"))
        
        CM:Log("DataLake falhou ao carregar: " .. (reason or "unknown"), "ERROR")
        return false, reason
    end
end

-- ============================================================================
-- Helpers de Acesso com Fallback Gracioso
-- ============================================================================

function CM:GetSpellDesc(spellId)
    -- Tentar carregar Data Lake se não estiver carregado
    if not self.DataLake.loaded then
        self:LoadDataLake("SpellLookup")
    end
    
    -- Acessar dados se disponíveis
    if ConsoleMode_SpellDescDB and ConsoleMode_SpellDescDB[spellId] then
        return ConsoleMode_SpellDescDB[spellId]
    end
    
    -- Fallback: retornar nil (cliente usará cache padrão)
    return nil
end

function CM:GetQuestData(questId)
    -- Tentar carregar Data Lake se não estiver carregado
    if not self.DataLake.loaded then
        self:LoadDataLake("QuestLookup")
    end
    
    -- Acessar dados se disponíveis
    if ConsoleMode_QuestDB and ConsoleMode_QuestDB[questId] then
        return ConsoleMode_QuestDB[questId]
    end
    
    -- Fallback: retornar nil
    return nil
end

function CM:GetItemName(itemId)
    -- Tentar carregar Data Lake se não estiver carregado
    if not self.DataLake.loaded then
        self:LoadDataLake("ItemLookup")
    end
    
    -- Acessar dados se disponíveis
    if ConsoleMode_ItemDB and ConsoleMode_ItemDB[itemId] then
        return ConsoleMode_ItemDB[itemId]
    end
    
    -- Fallback: usar GetItemInfo do cliente
    local name = GetItemInfo(itemId)
    return name
end

function CM:GetItemDesc(itemId)
    -- Tentar carregar Data Lake se não estiver carregado
    if not self.DataLake.loaded then
        self:LoadDataLake("ItemDescLookup")
    end
    
    -- Acessar dados se disponíveis
    if ConsoleMode_ItemDescDB and ConsoleMode_ItemDescDB[itemId] then
        return ConsoleMode_ItemDescDB[itemId]
    end
    
    -- Fallback: retornar nil
    return nil
end

-- ============================================================================
-- Auto-Load Triggers (Hooks em Janelas do WoW)
-- ============================================================================

function CM:SetupDataLakeTriggers()
    -- Trigger 1: Ao abrir SpellBook
    local originalToggleSpellBook = ToggleSpellBook
    ToggleSpellBook = function(bookType)
        if not CM.DataLake.loaded then
            CM:LoadDataLake("SpellBook")
        end
        return originalToggleSpellBook(bookType)
    end
    
    -- Trigger 2: Ao abrir Quest Log
    local originalToggleQuestLog = ToggleQuestLog
    ToggleQuestLog = function()
        if not CM.DataLake.loaded then
            CM:LoadDataLake("QuestLog")
        end
        return originalToggleQuestLog()
    end
    
    -- Trigger 3: Ao abrir Main Menu do addon (força load)
    -- (já será hookado no MainMenu.lua via CM:LoadDataLake("MainMenu"))
    
    CM:Log("DataLake triggers configurados (SpellBook, QuestLog)", "INFO")
end

-- ============================================================================
-- Comando Slash para Debug
-- ============================================================================

SLASH_CMDATALAKE1 = "/cmdatalake"
SlashCmdList["CMDATALAKE"] = function(msg)
    if msg == "load" then
        local success, reason = CM:LoadDataLake("SlashCommand")
        if success then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Data Lake carregado: " .. reason)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[ConsoleMode]|r Falha ao carregar: " .. reason)
        end
    elseif msg == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Data Lake Status:")
        DEFAULT_CHAT_FRAME:AddMessage("  Disponível: " .. tostring(CM.DataLake.available))
        DEFAULT_CHAT_FRAME:AddMessage("  Carregado: " .. tostring(CM.DataLake.loaded))
        DEFAULT_CHAT_FRAME:AddMessage("  Requisitado por: " .. (CM.DataLake.requestedBy or "n/a"))
        DEFAULT_CHAT_FRAME:AddMessage("  Tentativas: " .. CM.DataLake.loadAttempts)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Data Lake Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /cmdatalake load   - Força carregamento")
        DEFAULT_CHAT_FRAME:AddMessage("  /cmdatalake status - Mostra status")
    end
end

-- ============================================================================
-- Inicialização
-- ============================================================================

-- Verificar disponibilidade ao carregar o addon
CM:CheckDataLakeAvailable()
