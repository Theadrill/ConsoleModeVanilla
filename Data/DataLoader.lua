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
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[ConsoleMode]|r DataLake: muitas tentativas de carregamento, abortando")
        return false, "too_many_attempts"
    end
    
    -- Tentar carregar
    local loaded, reason = LoadAddOn("ConsoleModeVanilla-Data")
    
    if loaded then
        self.DataLake.loaded = true
        self.DataLake.requestedBy = requestedBy
        
        -- Mensagem de sucesso no chat
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Data Lake carregado (13.59 MB) - via " .. (requestedBy or "manual"))
        return true, "loaded"
    else
        -- Mensagem de erro
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[ConsoleMode]|r Erro ao carregar Data Lake: " .. (reason or "unknown"))
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
        DEFAULT_CHAT_FRAME:AddMessage("  Disponivel: " .. tostring(CM.DataLake.available))
        DEFAULT_CHAT_FRAME:AddMessage("  Carregado: " .. tostring(CM.DataLake.loaded))
        DEFAULT_CHAT_FRAME:AddMessage("  Requisitado por: " .. (CM.DataLake.requestedBy or "n/a"))
        DEFAULT_CHAT_FRAME:AddMessage("  Tentativas: " .. CM.DataLake.loadAttempts)
        
        -- Informações adicionais de debug
        local dataAddonLoaded = IsAddOnLoaded("ConsoleModeVanilla-Data")
        DEFAULT_CHAT_FRAME:AddMessage("  Addon carregado (IsAddOnLoaded): " .. tostring(dataAddonLoaded))
        
        local spellDBExists = (ConsoleMode_SpellDescDB ~= nil)
        DEFAULT_CHAT_FRAME:AddMessage("  SpellDescDB existe: " .. tostring(spellDBExists))
        
        if spellDBExists then
            local count = 0
            for k, v in pairs(ConsoleMode_SpellDescDB) do
                count = count + 1
                if count > 1000 then break end
            end
            DEFAULT_CHAT_FRAME:AddMessage("  Spells carregados: " .. count .. "+")
        end
    elseif msg == "test" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Executando teste LoadOnDemand...")
        
        local name, title, notes, loadable, reason = GetAddOnInfo("ConsoleModeVanilla-Data")
        DEFAULT_CHAT_FRAME:AddMessage("1. Data addon disponivel: " .. tostring(loadable ~= nil))
        
        local dataLoaded = IsAddOnLoaded("ConsoleModeVanilla-Data")
        DEFAULT_CHAT_FRAME:AddMessage("2. Data addon ja carregado: " .. tostring(dataLoaded))
        
        if not dataLoaded then
            DEFAULT_CHAT_FRAME:AddMessage("3. Carregando Data Lake...")
            local success, reason = CM:LoadDataLake("TestCommand")
            DEFAULT_CHAT_FRAME:AddMessage("   Resultado: " .. tostring(success) .. " (" .. reason .. ")")
        end
        
        dataLoaded = IsAddOnLoaded("ConsoleModeVanilla-Data")
        DEFAULT_CHAT_FRAME:AddMessage("4. Data addon agora carregado: " .. tostring(dataLoaded))
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Teste concluido!")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Data Lake Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /cmdatalake load   - Forca carregamento")
        DEFAULT_CHAT_FRAME:AddMessage("  /cmdatalake status - Mostra status detalhado")
        DEFAULT_CHAT_FRAME:AddMessage("  /cmdatalake test   - Executa teste completo")
    end
end

-- ============================================================================
-- Inicialização
-- ============================================================================

-- Verificar disponibilidade ao carregar o addon
CM:CheckDataLakeAvailable()
