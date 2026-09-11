-- ============================================================================
-- ConsoleModeVanilla - UI/MailScreen.lua
-- Sistema Modular de Correio (Mailbox) em Split-View para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- NOTA (Passo 1 / Fase 1): somente esqueleto + registro. Sem chamadas de API
-- servidora, sem supressão do MailFrame, sem leitura de inbox e sem composicao.
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_MailScreen = ConsoleMode_MailScreen or {}
local MailScreen = ConsoleMode_MailScreen
CM.mailScreen = MailScreen

-- ----------------------------------------------------------------------------
-- 1. ESTADO DO MÓDULO (mínimo do Passo 1)
-- ----------------------------------------------------------------------------
MailScreen.isOpen      = false
MailScreen.initialized = false

-- ----------------------------------------------------------------------------
-- 2. CRIAÇÃO DA UI (stub do Passo 1 — frames reais entram no Passo 2)
-- ----------------------------------------------------------------------------
function MailScreen:CreateUI()
    -- Passo 2: criar dimmer + janela split-view (inbox + composição).
    return
end

-- ----------------------------------------------------------------------------
-- 3. ABERTURA / FECHAMENTO (stubs do Passo 1 — sem navegação ainda)
-- ----------------------------------------------------------------------------
function MailScreen:Open()
    self:CreateUI()
    self.isOpen = true
end

function MailScreen:Close()
    if not self.isOpen then return end
    self.isOpen = false
end

-- ----------------------------------------------------------------------------
-- 4. INICIALIZAÇÃO (idempotente; sem frames visíveis, sem eventos de mail)
-- ----------------------------------------------------------------------------
function MailScreen:Initialize()
    if self.initialized then return end
    self.initialized = true

    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Modulo inicializado (esqueleto do Passo 1).")
    end
end

-- Inicialização automática no carregamento do arquivo
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    MailScreen:Initialize()
end)
