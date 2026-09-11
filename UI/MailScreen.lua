-- ============================================================================
-- ConsoleModeVanilla - UI/MailScreen.lua
-- Sistema Modular de Correio (Mailbox) em Split-View para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- NOTA (Passo 3 / Fase 1): supressao visual do MailFrame nativo (off-screen,
-- sem Hide/CloseMail) + registro de eventos + flags + logs. Sem chamadas
-- de API servidora (SendMail, CheckInbox, GetInbox*, TakeInbox*, DeleteInboxItem,
-- ReturnInboxItem, CloseMail, ClickSendMailItemButton, SetSendMailMoney),
-- sem leitura de inbox e sem composicao.
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
-- 2b. SUPRESSAO SEGURA DO MAILFRAME NATIVO (Passo 3 — molde MerchantMenu)
-- NUNCA Hide() o nativo: mataria a sessao MAIL_SHOW -> MAIL_CLOSED.
-- So manipulacao visual (alpha/mouse/off-screen) + fechar bolsas.
-- ----------------------------------------------------------------------------
function MailScreen:CloseAllOpenBags()
    for i = 1, 5 do
        local cf = getglobal("ContainerFrame" .. i)
        if cf and cf:IsVisible() then
            pcall(function() cf:Hide() end)
        end
    end

    if CloseBackpack then pcall(CloseBackpack) end
    if CloseBag then
        for b = 1, 4 do
            pcall(function() CloseBag(b) end)
        end
    end
    if CloseAllBags then pcall(CloseAllBags) end

    local bagnon = getglobal("Bagnon")
    if bagnon and bagnon:IsVisible() then pcall(function() bagnon:Hide() end) end
    local pfBag = getglobal("pfBag")
    if pfBag and pfBag:IsVisible() then pcall(function() pfBag:Hide() end) end
    local bagshui = getglobal("BagshuiBagsFrame")
    if bagshui and bagshui:IsVisible() then pcall(function() bagshui:Hide() end) end
end

function MailScreen:SuppressDefaultFrame()
    if not MailFrame then return end
    pcall(function()
        if MailFrame.selectedTab then
            MailFrame.selectedTab = 1
        end
    end)
    pcall(function() MailFrame:SetAlpha(0) end)
    pcall(function() MailFrame:EnableMouse(false) end)
    pcall(function()
        MailFrame:ClearAllPoints()
        MailFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 5000)
    end)
    self:CloseAllOpenBags()
end

-- ----------------------------------------------------------------------------
-- 2. CRIAÇÃO DA UI (stub — frames reais entram em passo futuro)
-- ----------------------------------------------------------------------------
function MailScreen:CreateUI()
    -- Passo futuro: criar dimmer + janela split-view (inbox + composição).
    return
end

-- ----------------------------------------------------------------------------
-- 3. ABERTURA / FECHAMENTO (stubs — sem navegação ainda)
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
-- 4. MANIPULADORES DE EVENTOS (Passo 2 — só flags + logs, sem API servidora)
-- ----------------------------------------------------------------------------
function MailScreen:OnMailShow()
    if not self.initialized then return end
    self.isOpen = true
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Mailbox aberta.")
    end
    -- Passo 3: suprime o MailFrame nativo (visual, off-screen, sem Hide).
    self:SuppressDefaultFrame()
    -- Passo futuro: NAO chamar CheckInbox (leitura entra em passo futuro).
end

function MailScreen:OnMailClosed()
    if not self.initialized then return end
    self.isOpen = false
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Mailbox fechada.")
    end
    -- ANTI-BLOQUEIO: nunca encerrar sessao do NPC pelo addon neste passo.
    -- Nenhuma chamada de CloseMail ou similar aqui.
end

function MailScreen:OnInboxUpdate()
    if not self.initialized then return end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] MAIL_INBOX_UPDATE recebido.")
    end
end

function MailScreen:OnMailSendSuccess()
    if not self.initialized then return end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] MAIL_SEND_SUCCESS recebido.")
    end
end

function MailScreen:OnBagUpdate()
    if not self.initialized then return end
    -- Passo futuro (anexos): intencionalmente silencioso aqui para nao
    -- poluir o chat, pois BAG_UPDATE dispara com muita frequencia.
end

function MailScreen:OnMoneyUpdate()
    if not self.initialized then return end
    -- Passo futuro (seletor de dinheiro): silencioso pelo mesmo motivo.
end

-- ----------------------------------------------------------------------------
-- 5. INICIALIZAÇÃO (idempotente; event frame próprio, sem frames visíveis)
-- ----------------------------------------------------------------------------
function MailScreen:Initialize()
    if self.initialized then return end
    self.initialized = true

    -- Hook preventivo no OnShow do MailFrame (molde MerchantMenu:3073-3096).
    -- 1.12 nao tem HookScript: preserva o script original via GetScript/SetScript.
    if MailFrame then
        local orig_MailFrame_OnShow = MailFrame:GetScript("OnShow")
        MailFrame:SetScript("OnShow", function()
            if orig_MailFrame_OnShow then
                orig_MailFrame_OnShow()
            end
            MailScreen:SuppressDefaultFrame()
        end)

        -- Protecao no OnHide: com sessao aberta, engole o OnHide original para
        -- nao encerrar a sessao do NPC inadvertidamente. Sem sessao, repassa.
        local orig_MailFrame_OnHide = MailFrame:GetScript("OnHide")
        MailFrame:SetScript("OnHide", function()
            if not MailScreen.isOpen then
                if orig_MailFrame_OnHide then
                    orig_MailFrame_OnHide()
                end
            end
        end)
    end

    -- Event frame dedicado (molde: MerchantMenu). Idempotente: cria 1x.
    if not self.eventFrame then
        local ef = CreateFrame("Frame", "ConsoleMode_MailScreenEventFrame")
        ef:RegisterEvent("MAIL_SHOW")
        ef:RegisterEvent("MAIL_CLOSED")
        ef:RegisterEvent("MAIL_INBOX_UPDATE")
        ef:RegisterEvent("MAIL_SEND_SUCCESS")
        ef:RegisterEvent("BAG_UPDATE")
        ef:RegisterEvent("PLAYER_MONEY")

        ef:SetScript("OnEvent", function()
            if event == "MAIL_SHOW" then
                MailScreen:OnMailShow()
            elseif event == "MAIL_CLOSED" then
                MailScreen:OnMailClosed()
            elseif event == "MAIL_INBOX_UPDATE" then
                MailScreen:OnInboxUpdate()
            elseif event == "MAIL_SEND_SUCCESS" then
                MailScreen:OnMailSendSuccess()
            elseif event == "BAG_UPDATE" then
                MailScreen:OnBagUpdate()
            elseif event == "PLAYER_MONEY" then
                MailScreen:OnMoneyUpdate()
            end
        end)

        self.eventFrame = ef
    end

    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Modulo inicializado (Passo 3: supressao + eventos).")
    end
end

-- Inicialização automática no carregamento do arquivo
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    MailScreen:Initialize()
end)
