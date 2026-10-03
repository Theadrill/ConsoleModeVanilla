-- ============================================================================
-- TESTE DE LOADONDEMAND - Console Mode
-- ============================================================================
-- Como usar:
-- 1. Copie este arquivo inteiro
-- 2. No jogo, abra o chat e digite: /script
-- 3. Cole o código abaixo
-- 4. Pressione Enter
-- ============================================================================

DEFAULT_CHAT_FRAME:AddMessage("===== TESTE LOADONDEMAND =====")

-- Teste 1: Verificar se Core está carregado
local coreLoaded = (ConsoleMode ~= nil)
DEFAULT_CHAT_FRAME:AddMessage("1. Core addon carregado: " .. tostring(coreLoaded))

-- Teste 2: Verificar se Data está disponível (mas não carregado)
local name, title, notes, loadable, reason = GetAddOnInfo("ConsoleModeVanilla-Data")
local dataAvailable = (loadable ~= nil)
DEFAULT_CHAT_FRAME:AddMessage("2. Data addon disponivel: " .. tostring(dataAvailable))

-- Teste 3: Verificar se Data já está carregado
local dataLoaded = IsAddOnLoaded("ConsoleModeVanilla-Data")
DEFAULT_CHAT_FRAME:AddMessage("3. Data addon ja carregado: " .. tostring(dataLoaded))

-- Teste 4: Verificar se SpellDescDB está disponível (só existe se Data carregado)
local spellDBExists = (ConsoleMode_SpellDescDB ~= nil)
DEFAULT_CHAT_FRAME:AddMessage("4. SpellDescDB disponivel: " .. tostring(spellDBExists))

-- Teste 5: Tentar carregar Data manualmente
if ConsoleMode and ConsoleMode.LoadDataLake then
    DEFAULT_CHAT_FRAME:AddMessage("5. Tentando carregar Data Lake...")
    local success, reason = ConsoleMode:LoadDataLake("ManualTest")
    DEFAULT_CHAT_FRAME:AddMessage("   Resultado: " .. tostring(success) .. " (" .. reason .. ")")
else
    DEFAULT_CHAT_FRAME:AddMessage("5. ERRO: ConsoleMode.LoadDataLake nao existe!")
end

-- Teste 6: Verificar novamente se Data foi carregado
dataLoaded = IsAddOnLoaded("ConsoleModeVanilla-Data")
DEFAULT_CHAT_FRAME:AddMessage("6. Data addon agora carregado: " .. tostring(dataLoaded))

-- Teste 7: Verificar se SpellDescDB agora existe
spellDBExists = (ConsoleMode_SpellDescDB ~= nil)
DEFAULT_CHAT_FRAME:AddMessage("7. SpellDescDB agora disponivel: " .. tostring(spellDBExists))

if spellDBExists then
    -- Contar quantos spells existem
    local count = 0
    for k, v in pairs(ConsoleMode_SpellDescDB) do
        count = count + 1
        if count > 100 then break end -- Só contar primeiros 100 para não travar
    end
    DEFAULT_CHAT_FRAME:AddMessage("   -> Primeiros 100+ spells carregados!")
end

DEFAULT_CHAT_FRAME:AddMessage("===== FIM DO TESTE =====")
