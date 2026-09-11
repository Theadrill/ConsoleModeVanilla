-- ============================================================================
-- ConsoleModeVanilla - UI/MailScreen.lua
-- Sistema Modular de Correio (Mailbox) em Split-View para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- NOTA (Passo 4 / Fase 1): supressao visual do MailFrame nativo (off-screen,
-- sem Hide/CloseMail) + registro de eventos + flags + logs + CAMADA DE DADOS
-- DE LEITURA do inbox (CheckInbox/GetInboxNumItems/GetInboxHeaderInfo com
-- guarda isOpen, filtros 1..3, paginacao logica). SEM escrita
-- (TakeInbox*/DeleteInboxItem/ReturnInboxItem/SendMail/CloseMail),
-- SEM composicao e SEM frames visuais (visual split-view em passo futuro).
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
-- 1b. ESTADO DA CAMADA DE DADOS DO INBOX (Passo 4 — só dados, sem frames)
-- inboxFilter: 1=Todos, 2=Nao-lidos, 3=Com Anexo.
-- ----------------------------------------------------------------------------
MailScreen.inboxItems         = {}
MailScreen.filteredInbox      = {}
MailScreen.inboxFilter        = 1
MailScreen.inboxScanned       = false
MailScreen.selectedInboxIndex = 1
MailScreen.inboxScrollOffset  = 0

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
-- 2c. CAMADA DE DADOS DO INBOX (Passo 4 — SOMENTE LEITURA, sem frames)
-- ANTI-BLOQUEIO BLIZZARD: CheckInbox/GetInboxNumItems/GetInboxHeaderInfo
-- SOMENTE com isOpen == true (mailbox aberta). Nenhuma acao de escrita aqui.
-- GetInboxHeaderInfo (1.12) retorna 13 valores; `select` NAO existe no
-- Lua 5.0 (introduzido no 5.1), entao capturamos em 13 variaveis locais
-- explicitas via pcall por linha lida.
-- ----------------------------------------------------------------------------
function MailScreen:GetInboxFilterName()
    local f = self.inboxFilter or 1
    if f == 2 then
        return "Nao lidos"
    elseif f == 3 then
        return "Com anexo"
    end
    return "Todos"
end

function MailScreen:RequestInboxRefresh()
    if not self.isOpen then return end
    if not CheckInbox then return end
    -- Dispara MAIL_INBOX_UPDATE assincrono; o scan real acontece em OnInboxUpdate.
    pcall(CheckInbox)
end

function MailScreen:ScanInbox()
    if not self.isOpen then return end
    if not GetInboxNumItems then return end
    local okCount, n = pcall(GetInboxNumItems)
    if not okCount then return end
    n = tonumber(n) or 0
    if not n or n < 1 then
        self.inboxItems = {}
        self.filteredInbox = {}
        self.inboxScanned = true
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Inbox vazia.")
        end
        return
    end
    if not GetInboxHeaderInfo then return end
    local raw = {}
    for i = 1, n do
        local ok, packageIcon, stationeryIcon, sender, subject, money,
            codAmount, daysLeft, hasItem, wasRead, wasReturned,
            textCreated, canReply, isGM = pcall(GetInboxHeaderInfo, i)
        if ok and sender then
            table.insert(raw, {
                index = i,
                sender = sender,
                subject = subject,
                money = money or 0,
                cod = codAmount or 0,
                daysLeft = daysLeft,
                hasItem = hasItem,
                wasRead = wasRead,
                wasReturned = wasReturned,
                canReply = canReply,
                isGM = isGM,
            })
        end
    end
    self.inboxItems = raw
    self.inboxScanned = true
    self:FilterInbox()
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Inbox: " .. table.getn(raw) .. " cartas (filtro: " .. self:GetInboxFilterName() .. ").")
    end
end

function MailScreen:SetInboxFilter(f)
    f = tonumber(f) or 1
    f = math.floor(f)
    if f < 1 then f = 1 end
    if f > 3 then f = 3 end
    self.inboxFilter = f
    self:FilterInbox()
end

function MailScreen:FilterInbox()
    local f = self.inboxFilter or 1
    local filtered = {}
    local raw = self.inboxItems or {}
    local numRaw = table.getn(raw)
    for i = 1, numRaw do
        local item = raw[i]
        local match = false
        if f == 1 then
            match = true
        elseif f == 2 then
            if item.wasRead == nil or item.wasRead == false then match = true end
        elseif f == 3 then
            if item.hasItem then match = true end
        end
        if match then
            table.insert(filtered, item)
        end
    end
    self.filteredInbox = filtered

    -- Mantem selecao/scroll validos (molde MerchantMenu Filter*Items).
    local numFiltered = table.getn(filtered)
    if self.selectedInboxIndex > numFiltered then
        self.selectedInboxIndex = math.max(1, numFiltered)
    end
    if self.selectedInboxIndex < 1 then
        self.selectedInboxIndex = 1
    end
    local visibleRows = 7
    if self.selectedInboxIndex <= self.inboxScrollOffset then
        self.inboxScrollOffset = self.selectedInboxIndex - 1
    elseif self.selectedInboxIndex > (self.inboxScrollOffset + visibleRows) then
        self.inboxScrollOffset = self.selectedInboxIndex - visibleRows
    end
    if self.inboxScrollOffset < 0 then self.inboxScrollOffset = 0 end
    local maxOffset = math.max(0, numFiltered - visibleRows)
    if self.inboxScrollOffset > maxOffset then self.inboxScrollOffset = maxOffset end
end

-- Logica pura de paginacao (7 linhas por pagina), sem frames: pronta para
-- o visual futuro.
function MailScreen:GetInboxPage()
    local n = table.getn(self.filteredInbox or {})
    local totalPages = math.ceil(n / 7)
    if totalPages < 1 then totalPages = 1 end
    local idx = tonumber(self.selectedInboxIndex) or 1
    if idx < 1 then idx = 1 end
    if n > 0 and idx > n then idx = n end
    local page = math.floor((idx - 1) / 7) + 1
    if page < 1 then page = 1 end
    if page > totalPages then page = totalPages end
    return page, totalPages
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
    -- Passo 4: com a mailbox aberta o contexto e seguro; dispara refresh
    -- assincrono do inbox (o scan real acontece em OnInboxUpdate).
    self:RequestInboxRefresh()
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
    -- Passo 4: rescan de leitura (molde MerchantMenu:OnMerchantUpdate);
    -- ScanInbox tem guarda isOpen interna (anti-bloqueio).
    self:ScanInbox()
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
        CM.logger:Log("[MailScreen] Modulo inicializado (Passo 4: leitura + filtros).")
    end
end

-- Inicialização automática no carregamento do arquivo
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    MailScreen:Initialize()
end)
