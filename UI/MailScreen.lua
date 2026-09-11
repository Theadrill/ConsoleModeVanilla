-- ============================================================================
-- ConsoleModeVanilla - UI/MailScreen.lua
-- Sistema Modular de Correio (Mailbox) em Split-View para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- NOTA (M3): supressao visual do MailFrame nativo (off-screen,
-- sem Hide/CloseMail) + registro de eventos + flags + logs + CAMADA DE DADOS
-- DE LEITURA do inbox (CheckInbox/GetInboxNumItems/GetInboxHeaderInfo com
-- guarda isOpen, filtros 1..3, paginacao logica) + JANELA split-view
-- (dimmer, 9-slice Carved_9Slides, header CORREIO+Sair, 2 colunas, footer)
-- + VISUAL M2 (7 linhas do inbox reutilizaveis, DetailCard da carta,
-- filtros LT/RT, paginacao, colunas LB/RB, OnDirection) + ACOES M3
-- (fileira RETIRAR|DEVOLVER|APAGAR no detalhe, A entra / B volta p/ lista,
-- Y retira tudo em fila serializada por MAIL_INBOX_UPDATE, modal de
-- confirmacao de APAGAR, CloseTopFrame via Hooks). SEM compor/envio (M4),
-- SEM VK, SEM fila multi-item de envio.
-- M4.1: detalhe full-height na inbox + telas INBOX<->COMPOR (LB/RB) +
-- compor estrutural (campos com EditBox reais, grade de inventario visual,
-- navegacao espacial; SEM envio, SEM VK, SEM modais de M4.2).
-- M4.2: VK nos 3 campos (contrato congelado §4.2, so consumo) + historico
-- (SV separada ConsoleModeMailHistory, teto 20) + modal de dinheiro (reels
-- Ouro 4 + Prata 2 + Cobre 2) + anexos (lista composeItems, 1 item por carta
-- no envio) + modal de quantidade + fila multi-item serializada por
-- MAIL_SEND_SUCCESS (aborta em MAIL_CLOSED). SEM M5, SEM COD.
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

-- M2: coluna com foco ("INBOX" esquerda / "DETAIL" direita) + hold-to-repeat
-- do D-Pad (molde MerchantMenu.repeatState; so UP/DOWN repete).
MailScreen.activeColumn = MailScreen.activeColumn or "INBOX"
MailScreen.repeatState  = MailScreen.repeatState or {
    direction = nil,
    timer = 0,
    initialDelay = 0.35,
    interval = 0.12,
}
MailScreen.repeatFrame = MailScreen.repeatFrame or nil

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
MailScreen.frame              = nil
MailScreen.dimmer             = nil

-- ----------------------------------------------------------------------------
-- 1b2. ESTADO M3: botoes do detalhe + modal de confirmacao + fila Retirar-Tudo
-- detailButtonIndex: 1=RETIRAR, 2=DEVOLVER, 3=APAGAR (foco com DETAIL ativo).
-- deleteConfirm: modal FULLSCREEN_DIALOG/50 p/ APAGAR com valores a retirar.
-- takeAllQueue: fila serializada (UMA carta por MAIL_INBOX_UPDATE).
-- ----------------------------------------------------------------------------
MailScreen.detailButtonIndex  = 1
MailScreen.actionBar          = nil
MailScreen.deleteConfirm      = { isOpen = false, pendingIndex = nil }
MailScreen.deleteConfirmFrame = nil
MailScreen.takeAllQueue       = { running = false, queue = {}, pos = 1, total = 0 }

-- ----------------------------------------------------------------------------
-- 1b3. ESTADO M4.1: telas INBOX<->COMPOR + compor estrutural (SEM envio)
-- currentScreen: "INBOX" (default ao abrir) ou "COMPOSE".
-- composeFocus: "FIELDS" (coluna esquerda) ou "INV" (grade da direita).
-- composeFieldIndex: 1=Para, 2=Assunto, 3=Mensagem, 4=Dinheiro, 5=Itens,
-- 6=ENVIAR. invIndex/invScrollOffset: navegacao da grade (invCols fixo).
-- composeTo/Subject/Body/Money: buffers estruturais (espelhos do texto das
-- EditBoxes; usados de verdade so em M4.2).
-- ----------------------------------------------------------------------------
MailScreen.currentScreen      = MailScreen.currentScreen or "INBOX"
MailScreen.composeFocus       = MailScreen.composeFocus or "FIELDS"
MailScreen.composeFieldIndex  = MailScreen.composeFieldIndex or 1
MailScreen.invIndex           = MailScreen.invIndex or 1
MailScreen.invScrollOffset    = MailScreen.invScrollOffset or 0
MailScreen.invCols            = 5
MailScreen.invRowsVisible     = 6
MailScreen.invItems           = MailScreen.invItems or {}
MailScreen.composeTo          = MailScreen.composeTo or ""
MailScreen.composeSubject     = MailScreen.composeSubject or ""
MailScreen.composeBody        = MailScreen.composeBody or ""
MailScreen.composeMoney       = MailScreen.composeMoney or ""
MailScreen.tabIndicator       = nil

-- ----------------------------------------------------------------------------
-- 1b4. ESTADO M4.2: anexos + modais + fila de envio (§7 M4)
-- composeItems: lista de {bag, slot, name, texture, count, qty} aceita na UI
-- (N itens); no envio sai 1 carta por item (limite 1.12), dinheiro so na 1a.
-- moneyModal: reels Ouro 4 + Prata 2 + Cobre 2 (§4.1: digits[1..8], wrap 0-9,
-- hold 0.35/0.12 via StartRepeat/OnDirection, <-/-> digito, A confirma, B
-- cancela). qtyModal: quantidade do item (teto = pilha, A confirma, B
-- cancela, mouse digita). sendQueue: fila serializada por MAIL_SEND_SUCCESS,
-- aborta em MAIL_CLOSED; pos-envio limpa tudo e permanece no compor.
-- ----------------------------------------------------------------------------
MailScreen.composeItems      = MailScreen.composeItems or {}
MailScreen.moneyModal        = MailScreen.moneyModal or { isOpen = false, digits = { 0, 0, 0, 0, 0, 0, 0, 0 }, digitIndex = 1 }
MailScreen.moneyModalFrame   = MailScreen.moneyModalFrame or nil
MailScreen.qtyModal          = MailScreen.qtyModal or { isOpen = false, bag = nil, slot = nil, qty = 1, maxQty = 1, itemName = "" }
MailScreen.qtyModalFrame     = MailScreen.qtyModalFrame or nil
MailScreen.sendQueue         = MailScreen.sendQueue or { running = false, letters = {}, pos = 1, total = 0 }

-- ----------------------------------------------------------------------------
-- 1c. DESIGN SYSTEM (M1 — molde UI/MerchantMenu.lua:17-50, copia 1:1 com
-- prefixo MailScreen; somente visual, sem logica de escrita)
-- ----------------------------------------------------------------------------
local FONTS = {
    titleBold = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    bodyBold  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    medium    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Medium.ttf",
    fallback  = "Fonts\\FRIZQT__.TTF",
}

local ICONS = {
    A      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\A.tga",
    B      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\B.tga",
    X      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\X.tga",
    Y      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\Y.tga",
    LB     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LB.tga",
    RB     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\RB.tga",
    LT     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LT.tga",
    RT     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\RT.tga",
    DUP    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DUP.tga",
    DDOWN  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DDOWN.tga",
    DLEFT  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DLEFT.tga",
    DRIGHT = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DRIGHT.tga",
    DALL   = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\navigate_all_directions.tga",
}

local QUALITY_COLORS = {
    [0] = { r = 0.62, g = 0.62, b = 0.62, hex = "|cff9d9d9d" }, -- Pobre (Cinza)
    [1] = { r = 1.00, g = 1.00, b = 1.00, hex = "|cffffffff" }, -- Comum (Branco)
    [2] = { r = 0.12, g = 1.00, b = 0.00, hex = "|cff1eff00" }, -- Incomum (Verde)
    [3] = { r = 0.00, g = 0.44, b = 0.87, hex = "|cff0070dd" }, -- Raro (Azul)
    [4] = { r = 0.64, g = 0.21, b = 0.93, hex = "|cffa335ee" }, -- Epico (Roxo)
    [5] = { r = 1.00, g = 0.50, b = 0.00, hex = "|cffff8000" }, -- Lendario (Laranja)
}

local NINESLICE = {
    texture    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Carved_9Slides.tga",
    cornerSize = 48,
    drawLayer  = "BACKGROUND",
    uv = {
        col = {
            { 0.0000, 0.2500 }, -- Esquerda (0 a 64px de 256px)
            { 0.2500, 0.5000 }, -- Centro (64 a 128px de 256px)
            { 0.5000, 0.7500 }, -- Direita (128 a 192px de 256px)
        },
        row = {
            { 0.0000, 0.2500 }, -- Topo (0 a 64px de 256px)
            { 0.2500, 0.5000 }, -- Centro (64 a 128px de 256px)
            { 0.5000, 0.7500 }, -- Fundo (128 a 192px de 256px)
        }
    }
}

-- ----------------------------------------------------------------------------
-- 1d. HELPERS TIPOGRAFICOS E FORMATAÇÃO DE MOEDAS (molde MerchantMenu:137-172)
-- ----------------------------------------------------------------------------
function MailScreen:ApplyFont(fontString, fontPath, size, outline, shadowOffset, shadowColor)
    if not fontString then return end
    fontPath = fontPath or FONTS.bodyBold
    size = size or 12
    outline = outline or ""

    local ok = fontString:SetFont(fontPath, size, outline)
    if not ok then
        fontString:SetFont(FONTS.fallback, size, outline)
    end

    local so = shadowOffset or { 1, -1 }
    local sc = shadowColor or { 0, 0, 0, 0.90 }
    fontString:SetShadowOffset(so[1], so[2])
    fontString:SetShadowColor(sc[1], sc[2], sc[3], sc[4])
end

-- Formata cobre bruto em texto colorido e estilizado
function MailScreen:FormatMoneyText(totalCopper)
    totalCopper = totalCopper or 0
    if totalCopper < 0 then totalCopper = 0 end

    local gold   = math.floor(totalCopper / 10000)
    local silver = math.floor(math.mod(totalCopper, 10000) / 100)
    local copper = math.floor(math.mod(totalCopper, 100))

    local text = ""
    if gold > 0 then
        text = text .. "|cffffd700" .. gold .. "g|r "
    end
    if silver > 0 or gold > 0 then
        text = text .. "|cffc7c7cf" .. silver .. "s|r "
    end
    text = text .. "|cffeda55f" .. copper .. "c|r"
    return text
end

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
-- 2d. CONSTRUCAO VISUAL BASE: 9-SLICE + DIMMER (M1 — molde MerchantMenu:814-900)
-- ----------------------------------------------------------------------------
function MailScreen:Create9Slice(parent, texturePath, cornerSize, uvMap, drawLayer)
    if not parent or not texturePath then return nil end

    cornerSize = cornerSize or NINESLICE.cornerSize
    uvMap = uvMap or NINESLICE.uv
    drawLayer = drawLayer or NINESLICE.drawLayer

    local slices = {}

    local function makeSlice(name, u1, u2, v1, v2)
        local tex = parent:CreateTexture(nil, drawLayer)
        tex:SetTexture(texturePath)
        tex:SetTexCoord(u1, u2, v1, v2)
        return tex
    end

    local c = uvMap.col
    local r = uvMap.row

    -- 1. Cantos fixos
    slices.topLeft = makeSlice("TopLeft", c[1][1], c[1][2], r[1][1], r[1][2])
    slices.topLeft:SetWidth(cornerSize)
    slices.topLeft:SetHeight(cornerSize)
    slices.topLeft:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    slices.topRight = makeSlice("TopRight", c[3][1], c[3][2], r[1][1], r[1][2])
    slices.topRight:SetWidth(cornerSize)
    slices.topRight:SetHeight(cornerSize)
    slices.topRight:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    slices.bottomLeft = makeSlice("BottomLeft", c[1][1], c[1][2], r[3][1], r[3][2])
    slices.bottomLeft:SetWidth(cornerSize)
    slices.bottomLeft:SetHeight(cornerSize)
    slices.bottomLeft:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)

    slices.bottomRight = makeSlice("BottomRight", c[3][1], c[3][2], r[3][1], r[3][2])
    slices.bottomRight:SetWidth(cornerSize)
    slices.bottomRight:SetHeight(cornerSize)
    slices.bottomRight:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- 2. Bordas Horizontais
    slices.top = makeSlice("Top", c[2][1], c[2][2], r[1][1], r[1][2])
    slices.top:SetHeight(cornerSize)
    slices.top:SetPoint("TOPLEFT", slices.topLeft, "TOPRIGHT", 0, 0)
    slices.top:SetPoint("TOPRIGHT", slices.topRight, "TOPLEFT", 0, 0)

    slices.bottom = makeSlice("Bottom", c[2][1], c[2][2], r[3][1], r[3][2])
    slices.bottom:SetHeight(cornerSize)
    slices.bottom:SetPoint("BOTTOMLEFT", slices.bottomLeft, "BOTTOMRIGHT", 0, 0)
    slices.bottom:SetPoint("BOTTOMRIGHT", slices.bottomRight, "BOTTOMLEFT", 0, 0)

    -- 3. Bordas Verticais
    slices.left = makeSlice("Left", c[1][1], c[1][2], r[2][1], r[2][2])
    slices.left:SetWidth(cornerSize)
    slices.left:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMLEFT", 0, 0)
    slices.left:SetPoint("BOTTOMLEFT", slices.bottomLeft, "TOPLEFT", 0, 0)

    slices.right = makeSlice("Right", c[3][1], c[3][2], r[2][1], r[2][2])
    slices.right:SetWidth(cornerSize)
    slices.right:SetPoint("TOPRIGHT", slices.topRight, "BOTTOMRIGHT", 0, 0)
    slices.right:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPRIGHT", 0, 0)

    -- 4. Centro (Preenchimento sem transparencia)
    slices.center = makeSlice("Center", c[2][1], c[2][2], r[2][1], r[2][2])
    slices.center:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMRIGHT", 0, 0)
    slices.center:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPLEFT", 0, 0)

    return slices
end

function MailScreen:CreateDimmer()
    if self.dimmer then return end

    local dimmer = CreateFrame("Frame", "ConsoleMode_MailDimmer", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("HIGH")
    dimmer:SetFrameLevel(9)
    dimmer:EnableMouse(true)
    dimmer:Hide()

    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints(dimmer)
    dimTex:SetTexture(0.0, 0.0, 0.0, 0.65)
    dimmer.texture = dimTex

    self.dimmer = dimmer
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
                packageIcon = packageIcon,
                stationeryIcon = stationeryIcon,
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
-- 2. CRIACAO DA UI (M1 — esqueleto split-view, molde MerchantMenu:1302-1612)
-- Ordem canonica: dimmer -> frame -> 9-slice -> UISpecialFrames/OnHide ->
-- titulo -> header+Sair -> contentArea -> divisor -> 2 colunas vazias -> footer.
-- SEM linhas do inbox, SEM detalhes, SEM filtros/paginacao visuais (M2+).
-- ----------------------------------------------------------------------------
function MailScreen:BuildFooterHintsSet(frameName, hints)
    local parent = self.frame
    local container = CreateFrame("Frame", frameName, parent)
    container:SetHeight(34)
    container:SetPoint("CENTER", parent, "BOTTOM", 0, 18)

    local totalWidth = 0
    local widgets = {}

    local numHints = table.getn(hints)
    for i = 1, numHints do
        local hint = hints[i]
        local groupFrame = CreateFrame("Frame", nil, container)
        groupFrame:SetHeight(34)

        local currentX = 0
        local numIcons = table.getn(hint.icons)
        for k = 1, numIcons do
            local iconKey = hint.icons[k]
            local texPath = ICONS[iconKey]
            local iconTex = groupFrame:CreateTexture(nil, "OVERLAY")

            local curIconW = 27
            local curIconH = 27
            if iconKey == "LB" or iconKey == "RB" or iconKey == "A" or iconKey == "B" or iconKey == "X" or iconKey == "Y" then
                curIconW = 32
                curIconH = 32
            end

            iconTex:SetWidth(curIconW)
            iconTex:SetHeight(curIconH)
            iconTex:SetTexture(texPath)
            iconTex:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
            currentX = currentX + curIconW + 3
        end

        currentX = currentX + 5

        local label = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
        self:ApplyFont(label, FONTS.bodyBold, 18)
        label:SetText(hint.label)
        label:SetTextColor(0.85, 0.85, 0.85, 0.95)

        local textW = math.floor(label:GetStringWidth() or 40)
        currentX = currentX + textW

        if i < numHints then
            local sep = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            sep:SetPoint("LEFT", groupFrame, "LEFT", currentX + 10, 0)
            self:ApplyFont(sep, FONTS.medium, 14)
            sep:SetText("|cff666666•|r")
            currentX = currentX + 10 + 14
        end

        groupFrame:SetWidth(currentX)
        table.insert(widgets, groupFrame)
        totalWidth = totalWidth + currentX
    end

    local startX = -math.floor(totalWidth / 2)
    local curX = startX
    local numWidgets = table.getn(widgets)
    for w = 1, numWidgets do
        local widget = widgets[w]
        widget:SetPoint("LEFT", container, "CENTER", curX, 0)
        curX = curX + widget:GetWidth()
    end
    container:SetWidth(totalWidth)
    return container
end

-- M4.1: footers por tela (§3.1). Dois sets persistentes criados 1x;
-- ShowInboxScreen/ShowComposeScreen alternam a visibilidade.
function MailScreen:CreateFooterHints(parent)
    local inboxHints = {
        { icons = { "DALL" },     label = "Navegar" },
        { icons = { "A" },        label = "Entrar no detalhe" },
        { icons = { "Y" },        label = "Retirar tudo" },
        { icons = { "LT", "RT" }, label = "Filtros" },
        { icons = { "RB" },       label = "Nova mensagem" },
        { icons = { "B" },        label = "Voltar/Fechar" },
    }
    local composeHints = {
        { icons = { "DALL" },     label = "Navegar" },
        { icons = { "A" },        label = "Selecionar" },
        { icons = { "X" },        label = "Tirar item" },
        { icons = { "Y" },        label = "Quantidade" },
        { icons = { "LT", "RT" }, label = "Pular metade" },
        { icons = { "LB" },       label = "Caixa" },
        { icons = { "B" },        label = "Voltar/Fechar" },
    }

    parent.inboxFooter = self:BuildFooterHintsSet("ConsoleMode_MailFooterInbox", inboxHints)
    parent.composeFooter = self:BuildFooterHintsSet("ConsoleMode_MailFooterCompose", composeHints)
    parent.composeFooter:Hide()
    -- Compat M1: UpdateLayout posiciona via footerContainer (aponta p/ inbox).
    parent.footerContainer = parent.inboxFooter
end

function MailScreen:UpdateFooterVisibility()
    if not self.frame then return end
    if self.currentScreen == "COMPOSE" then
        if self.frame.inboxFooter then self.frame.inboxFooter:Hide() end
        if self.frame.composeFooter then self.frame.composeFooter:Show() end
        self.frame.footerContainer = self.frame.composeFooter
    else
        if self.frame.composeFooter then self.frame.composeFooter:Hide() end
        if self.frame.inboxFooter then self.frame.inboxFooter:Show() end
        self.frame.footerContainer = self.frame.inboxFooter
    end
end

-- M4.1: indicador de aba centralizado sob o titulo CORREIO (§3.1):
-- "NOVA MENSAGEM [RB]" na inbox / "[LB] CAIXA DE MENSAGENS" no compor.
function MailScreen:CreateTabIndicator(parent)
    if self.tabIndicator then return self.tabIndicator end
    local bar = CreateFrame("Frame", "ConsoleMode_MailTabIndicator", parent)
    bar:SetHeight(22)
    bar:SetWidth(420)
    bar:SetPoint("TOP", parent, "TOP", 0, -40)

    -- Grupo INBOX: texto a esquerda, icone RB a direita.
    local gIn = CreateFrame("Frame", nil, bar)
    gIn:SetHeight(22)
    gIn:SetWidth(300)
    gIn:SetPoint("CENTER", bar, "CENTER", 0, 0)
    local inLabel = gIn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    inLabel:SetPoint("RIGHT", gIn, "CENTER", -4, 0)
    self:ApplyFont(inLabel, FONTS.titleBold, 15)
    inLabel:SetText("|cff848484NOVA MENSAGEM|r")
    local inIcon = gIn:CreateTexture(nil, "OVERLAY")
    inIcon:SetWidth(26)
    inIcon:SetHeight(26)
    inIcon:SetPoint("LEFT", gIn, "CENTER", 4, 0)
    inIcon:SetTexture(ICONS.RB)
    bar.groupInbox = gIn

    -- Grupo COMPOSE: icone LB a esquerda, texto a direita.
    local gCo = CreateFrame("Frame", nil, bar)
    gCo:SetHeight(22)
    gCo:SetWidth(300)
    gCo:SetPoint("CENTER", bar, "CENTER", 0, 0)
    local coIcon = gCo:CreateTexture(nil, "OVERLAY")
    coIcon:SetWidth(26)
    coIcon:SetHeight(26)
    coIcon:SetPoint("RIGHT", gCo, "CENTER", -4, 0)
    coIcon:SetTexture(ICONS.LB)
    local coLabel = gCo:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    coLabel:SetPoint("LEFT", gCo, "CENTER", 4, 0)
    self:ApplyFont(coLabel, FONTS.titleBold, 15)
    coLabel:SetText("|cff848484CAIXA DE MENSAGENS|r")
    bar.groupCompose = gCo
    gCo:Hide()

    self.tabIndicator = bar
    return bar
end

function MailScreen:UpdateTabIndicator()
    local bar = self.tabIndicator
    if not bar then return end
    if self.currentScreen == "COMPOSE" then
        if bar.groupInbox then bar.groupInbox:Hide() end
        if bar.groupCompose then bar.groupCompose:Show() end
    else
        if bar.groupCompose then bar.groupCompose:Hide() end
        if bar.groupInbox then bar.groupInbox:Show() end
    end
end

function MailScreen:CreateUI()
    if self.frame then return end

    -- Dimmer de fundo (Imersao console)
    self:CreateDimmer()

    -- Janela Principal (Sem transparencia, 9-slice esculpido oficial)
    local frame = CreateFrame("Frame", "ConsoleMode_MailFrame", UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(10)
    frame:SetMovable(false)
    frame:EnableMouse(true)
    frame:Hide()

    self.slices = self:Create9Slice(
        frame,
        NINESLICE.texture,
        NINESLICE.cornerSize,
        NINESLICE.uv,
        NINESLICE.drawLayer
    )

    table.insert(UISpecialFrames, "ConsoleMode_MailFrame")
    frame:SetScript("OnHide", function()
        if MailScreen.isOpen then
            MailScreen:Close()
        end
    end)

    self.frame = frame

    -- Titulo Superior Central
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", frame, "TOP", 0, -20)
    self:ApplyFont(titleText, FONTS.titleBold, 23)
    titleText:SetText("|cffe09a15CORREIO|r")
    frame.titleText = titleText

    -- M4.1: indicador de aba centralizado sob o titulo (§3.1).
    self:CreateTabIndicator(frame)

    -- Barra de Cabecalho (Botao Sair)
    local header = CreateFrame("Frame", "ConsoleMode_MailHeader", frame)
    header:SetHeight(32)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -18)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -18)
    frame.header = header

    -- Botao Sair com estilo do MainMenu (molde MerchantMenu:1362-1397)
    local closeBtn = CreateFrame("Button", "ConsoleMode_MailCloseBtn", header)
    closeBtn:SetWidth(96)
    closeBtn:SetHeight(28)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    closeBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    closeBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    closeBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local closeIcon = closeBtn:CreateTexture(nil, "OVERLAY")
    closeIcon:SetWidth(25)
    closeIcon:SetHeight(25)
    closeIcon:SetPoint("LEFT", closeBtn, "LEFT", 6, 0)
    closeIcon:SetTexture(ICONS.B)

    local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeTxt:SetPoint("LEFT", closeIcon, "RIGHT", 6, 0)
    self:ApplyFont(closeTxt, FONTS.titleBold, 16)
    closeTxt:SetText("Sair")

    closeBtn:SetScript("OnClick", function()
        MailScreen:Close()
    end)
    closeBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    closeBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    header.closeBtn = closeBtn

    -- Barra de Rodape com Atalhos do Controle
    self:CreateFooterHints(frame)

    -- Area Central de Conteudo Split-View
    -- NOTA M1: merchant usa BOTTOMRIGHT -28,210 por causa do card de 154px;
    -- o card do mail ainda NAO existe (M2), entao usa-se -28,60 deixando
    -- espaco para detalhe+footer futuros.
    local contentArea = CreateFrame("Frame", "ConsoleMode_MailContentArea", frame)
    contentArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -54)
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 60)
    frame.contentArea = contentArea

    -- Divisoria Central Vertical
    local divider = frame:CreateTexture("ConsoleMode_MailDivider", "ARTWORK")
    divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetWidth(2)
    divider:SetVertexColor(0.6, 0.5, 0.3, 0.4)
    divider:SetPoint("TOP", contentArea, "TOP", 0, 0)
    divider:SetPoint("BOTTOM", contentArea, "BOTTOM", 0, 0)
    divider:SetPoint("CENTER", contentArea, "CENTER", 0, 0)
    frame.divider = divider

    -- Helper M2: painel de coluna (molde MerchantMenu:1423-1532, copia 1:1
    -- com prefixo MailScreen): header + barra de filtros LT/RT + divisor +
    -- statusBar/paginacao + listArea + placeholder. Linhas e detalhe sao
    -- criados fora desta funcao (pool em CreateUI, M2).
    local function CreateColumnPanel(name, titleTextStr, iconTag)
        local col = CreateFrame("Frame", name, contentArea)
        col:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 12,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        col:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
        col:SetBackdropBorderColor(0.50, 0.40, 0.28, 0.65)

        -- Cabecalho da Coluna (Icones 30px, Texto 18px)
        local colHeader = CreateFrame("Frame", nil, col)
        colHeader:SetHeight(34)
        colHeader:SetPoint("TOPLEFT", col, "TOPLEFT", 8, -6)
        colHeader:SetPoint("TOPRIGHT", col, "TOPRIGHT", -8, -6)
        col.header = colHeader

        local tagIcon = colHeader:CreateTexture(nil, "OVERLAY")
        tagIcon:SetWidth(30)
        tagIcon:SetHeight(30)
        tagIcon:SetPoint("LEFT", colHeader, "LEFT", 0, 0)
        tagIcon:SetTexture(iconTag)
        col.tagIcon = tagIcon

        local colTitle = colHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        colTitle:SetPoint("LEFT", tagIcon, "RIGHT", 8, 0)
        MailScreen:ApplyFont(colTitle, FONTS.titleBold, 18)
        colTitle:SetText(titleTextStr)
        col.title = colTitle

        -- Barra de Filtros LT/RT (molde MerchantMenu subTabBar)
        local subTabBar = CreateFrame("Frame", nil, col)
        subTabBar:SetHeight(30)
        subTabBar:SetPoint("TOPLEFT", colHeader, "BOTTOMLEFT", 0, -2)
        subTabBar:SetPoint("TOPRIGHT", colHeader, "BOTTOMRIGHT", 0, -2)
        col.subTabBar = subTabBar

        local ltBtn = CreateFrame("Button", nil, subTabBar)
        ltBtn:SetWidth(27)
        ltBtn:SetHeight(27)
        ltBtn:SetPoint("LEFT", subTabBar, "LEFT", 2, 0)
        local ltHint = ltBtn:CreateTexture(nil, "OVERLAY")
        ltHint:SetAllPoints(ltBtn)
        ltHint:SetTexture(ICONS.LT)
        col.ltBtn = ltBtn

        local dleftHint = subTabBar:CreateTexture(nil, "OVERLAY")
        dleftHint:SetWidth(18)
        dleftHint:SetHeight(18)
        dleftHint:SetPoint("LEFT", ltBtn, "RIGHT", 2, 0)
        dleftHint:SetTexture(ICONS.DLEFT)
        dleftHint:SetAlpha(0.85)

        local rtBtn = CreateFrame("Button", nil, subTabBar)
        rtBtn:SetWidth(27)
        rtBtn:SetHeight(27)
        rtBtn:SetPoint("RIGHT", subTabBar, "RIGHT", -2, 0)
        local rtHint = rtBtn:CreateTexture(nil, "OVERLAY")
        rtHint:SetAllPoints(rtBtn)
        rtHint:SetTexture(ICONS.RT)
        col.rtBtn = rtBtn

        local drightHint = subTabBar:CreateTexture(nil, "OVERLAY")
        drightHint:SetWidth(18)
        drightHint:SetHeight(18)
        drightHint:SetPoint("RIGHT", rtBtn, "LEFT", -2, 0)
        drightHint:SetTexture(ICONS.DRIGHT)
        drightHint:SetAlpha(0.85)

        local tabsLabel = subTabBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tabsLabel:SetPoint("CENTER", subTabBar, "CENTER", 0, 0)
        MailScreen:ApplyFont(tabsLabel, FONTS.titleBold, 17)
        tabsLabel:SetText("")
        col.tabsLabel = tabsLabel

        -- Divisoria abaixo dos filtros
        local cDiv = col:CreateTexture(nil, "ARTWORK")
        cDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        cDiv:SetHeight(1)
        cDiv:SetPoint("TOPLEFT", subTabBar, "BOTTOMLEFT", 2, -2)
        cDiv:SetPoint("TOPRIGHT", subTabBar, "BOTTOMRIGHT", -2, -2)
        cDiv:SetVertexColor(0.5, 0.4, 0.3, 0.35)

        -- Barra Inferior de Status / Paginacao
        local statusBar = CreateFrame("Frame", nil, col)
        statusBar:SetHeight(24)
        statusBar:SetPoint("BOTTOMLEFT", col, "BOTTOMLEFT", 8, 6)
        statusBar:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", -8, 6)
        col.statusBar = statusBar

        local pageIndicator = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pageIndicator:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
        MailScreen:ApplyFont(pageIndicator, FONTS.medium, 14)
        col.pageIndicator = pageIndicator

        -- Area interna de Lista
        local listArea = CreateFrame("Frame", nil, col)
        listArea:SetPoint("TOPLEFT", cDiv, "BOTTOMLEFT", 0, -4)
        listArea:SetPoint("BOTTOMRIGHT", statusBar, "TOPRIGHT", 0, 2)
        listArea:EnableMouseWheel(true)
        col.listArea = listArea

        local placeholder = listArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        placeholder:SetPoint("CENTER", listArea, "CENTER", 0, 0)
        MailScreen:ApplyFont(placeholder, FONTS.medium, 16)
        placeholder:SetText("|cffaaaaaaEm breve|r")
        col.placeholder = placeholder

        return col
    end

    -- Coluna Esquerda: Caixa de Entrada (lista do inbox, M2)
    local leftCol = CreateColumnPanel("ConsoleMode_MailColLeft", "CAIXA DE ENTRADA", ICONS.LB)
    leftCol:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
    leftCol:SetPoint("BOTTOMLEFT", contentArea, "BOTTOMLEFT", 0, 0)
    leftCol:SetPoint("RIGHT", divider, "LEFT", -6, 0)
    leftCol.placeholder:SetText("|cffaaaaaaAbrindo correio...|r")
    leftCol.pageIndicator:SetText("|cff888888Caixa de entrada|r")
    frame.leftCol = leftCol

    leftCol.header:EnableMouse(true)
    leftCol.header:SetScript("OnMouseDown", function()
        if MailScreen.activeColumn ~= "INBOX" then
            MailScreen.activeColumn = "INBOX"
            MailScreen:UpdateColumnVisuals()
            MailScreen:RefreshInboxList()
        end
    end)

    -- Coluna Direita: detalhe FULL da carta + botoes (tela inbox; o compor
    -- virou tela propria em M4, nada de placeholder aqui).
    local rightCol = CreateColumnPanel("ConsoleMode_MailColRight", "CARTA", ICONS.RB)
    rightCol:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", 0, 0)
    rightCol:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    rightCol:SetPoint("LEFT", divider, "RIGHT", 6, 0)
    frame.rightCol = rightCol

    -- Direita sem filtros em M2: esconde LT/RT, rotulo estatico de detalhe.
    if rightCol.ltBtn then rightCol.ltBtn:Hide() end
    if rightCol.rtBtn then rightCol.rtBtn:Hide() end
    if rightCol.tabsLabel then
        rightCol.tabsLabel:SetText("|cff888888Detalhe da carta|r")
    end
    if rightCol.placeholder then rightCol.placeholder:Hide() end
    if rightCol.pageIndicator then rightCol.pageIndicator:SetText("") end

    rightCol.header:EnableMouse(true)
    rightCol.header:SetScript("OnMouseDown", function()
        if MailScreen.activeColumn ~= "DETAIL" then
            MailScreen.activeColumn = "DETAIL"
            MailScreen:UpdateColumnVisuals()
            MailScreen:RefreshInboxList()
        end
    end)

    -- Pool de 7 linhas do inbox (criado 1x; RefreshInboxList so atualiza).
    self:CreateInboxRows(leftCol.listArea)

    -- Detalhe da carta no topo da coluna direita (molde DetailCard, M2).
    local detailCard = self:CreateMailDetailCard(rightCol.listArea)
    rightCol.detailCard = detailCard

    -- M3: fileira de botoes-textura do detalhe (RETIRAR|DEVOLVER|APAGAR).
    local actionBar = self:CreateMailActionBar(rightCol.listArea, detailCard)
    rightCol.actionBar = actionBar
    rightCol.composeBox = nil

    -- LT/RT da esquerda: na inbox ciclam o filtro (foco volta p/ esquerda);
    -- no compor saltam p/ a primeira metade vizinha (M4.1, §3.2).
    if leftCol.ltBtn then
        leftCol.ltBtn:SetScript("OnClick", function()
            if MailScreen.currentScreen == "COMPOSE" then
                MailScreen:ComposeHalfJump(-1)
            else
                MailScreen.activeColumn = "INBOX"
                MailScreen:UpdateColumnVisuals()
                MailScreen:CycleInboxFilter(-1)
            end
        end)
    end
    if leftCol.rtBtn then
        leftCol.rtBtn:SetScript("OnClick", function()
            if MailScreen.currentScreen == "COMPOSE" then
                MailScreen:ComposeHalfJump(1)
            else
                MailScreen.activeColumn = "INBOX"
                MailScreen:UpdateColumnVisuals()
                MailScreen:CycleInboxFilter(1)
            end
        end)
    end

    -- Roda do mouse pagina a selecao do inbox (só na tela INBOX).
    leftCol.listArea:SetScript("OnMouseWheel", function()
        if MailScreen.currentScreen ~= "INBOX" then return end
        if arg1 > 0 then
            MailScreen:MoveInboxSelection(-1)
        else
            MailScreen:MoveInboxSelection(1)
        end
    end)

    -- M4.1: tela COMPOR estrutural (containers persistentes criados 1x).
    self:CreateComposeUI()

    self:UpdateFooterVisibility()
    self:UpdateTabIndicator()
    self:ShowInboxScreen()

    self:UpdateLayout()
end

-- ----------------------------------------------------------------------------
-- 2e. VISUAL M2: linhas do inbox, DetailCard, filtros, paginacao, navegacao
-- (molde UI/MerchantMenu.lua: linhas, DetailCard, filtros, paginacao).
-- SOMENTE LEITURA: GetInboxItem/Link com guarda isOpen + pcall, so como
-- dado de exibicao (nunca retira nada). Sem tooltip nesta fase.
-- ----------------------------------------------------------------------------
local MAIL_FILTERS = {
    { id = 1, name = "Todos" },
    { id = 2, name = "Nao lidos" },
    { id = 3, name = "Com anexo" },
}

local MAIL_LETTER_ICON = "Interface\\Icons\\INV_Misc_Note_01"

function MailScreen:TruncateText(text, maxChars)
    if not text or text == "" then return "" end
    text = tostring(text)
    maxChars = tonumber(maxChars) or 28
    if maxChars < 1 then maxChars = 1 end
    if string.len(text) > maxChars then
        return string.sub(text, 1, maxChars) .. "..."
    end
    return text
end

-- Resolve o icone de exibicao da carta: anexo -> icone do item (leitura
-- display-only com guarda+pcall); sem anexo -> selo stationery; fallback carta.
function MailScreen:GetMailIconTexture(item)
    if not item then return MAIL_LETTER_ICON end
    if item.hasItem then
        if self.isOpen and GetInboxItem then
            local ok, nm, tx = pcall(GetInboxItem, item.index)
            if ok and type(tx) == "string" and tx ~= "" then
                return tx
            end
        end
        if item.packageIcon and item.packageIcon ~= "" then
            return item.packageIcon
        end
        return MAIL_LETTER_ICON
    end
    if item.stationeryIcon and item.stationeryIcon ~= "" then
        return item.stationeryIcon
    end
    return MAIL_LETTER_ICON
end

function MailScreen:IsMailUnread(item)
    if not item then return false end
    return item.wasRead == nil or item.wasRead == false
end

function MailScreen:BuildMailBadges(item)
    local parts = {}
    if self:IsMailUnread(item) then
        table.insert(parts, "|cffff2020Nova|r")
    end
    if item.hasItem then
        table.insert(parts, "|cff1eff00Anexo|r")
    end
    if tonumber(item.money) and tonumber(item.money) > 0 then
        table.insert(parts, "|cffffd700$|r")
    end
    if tonumber(item.cod) and tonumber(item.cod) > 0 then
        table.insert(parts, "|cffff2020COD|r")
    end
    if table.getn(parts) == 0 then
        return "|cff666666--|r"
    end
    return table.concat(parts, " ")
end

function MailScreen:CreateInboxRows(parent)
    local rows = {}
    for i = 1, 7 do
        local row = CreateFrame("Button", "ConsoleMode_MailRow" .. i, parent)
        row:SetHeight(42)
        if i == 1 then
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -2)
            row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -2)
        else
            row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -2)
            row:SetPoint("TOPRIGHT", rows[i - 1], "BOTTOMRIGHT", 0, -2)
        end

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        row:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
        row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)

        -- Highlight de fundo quando selecionada
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.30)
        hl:SetAllPoints(row)
        hl:Hide()
        row.highlight = hl

        -- Cursor dourado na selecionada
        local cur = row:CreateTexture(nil, "OVERLAY")
        cur:SetWidth(12)
        cur:SetHeight(12)
        cur:SetPoint("LEFT", row, "LEFT", 4, 0)
        cur:SetTexture("Interface\\QuestFrame\\UI-Quest-BulletPoint")
        cur:SetVertexColor(1.0, 0.85, 0.20)
        cur:Hide()
        row.cursor = cur

        -- Icone do anexo (32px) ou selo de carta
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(32)
        icon:SetHeight(32)
        icon:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.icon = icon

        local iconBorder = CreateFrame("Frame", nil, row)
        iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        iconBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        row.iconBorder = iconBorder

        -- Dias restantes (direita, topo)
        local daysText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        daysText:SetPoint("RIGHT", row, "RIGHT", -8, 8)
        daysText:SetJustifyH("RIGHT")
        MailScreen:ApplyFont(daysText, FONTS.titleBold, 14)
        row.daysText = daysText

        -- Selos/badges (direita, base)
        local badgesText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badgesText:SetPoint("RIGHT", row, "RIGHT", -8, -9)
        badgesText:SetJustifyH("RIGHT")
        MailScreen:ApplyFont(badgesText, FONTS.bodyBold, 12)
        row.badgesText = badgesText

        -- Remetente (esquerda, topo)
        local senderText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        senderText:SetPoint("LEFT", icon, "RIGHT", 8, 8)
        senderText:SetPoint("RIGHT", daysText, "LEFT", -8, 0)
        senderText:SetJustifyH("LEFT")
        MailScreen:ApplyFont(senderText, FONTS.bodyBold, 16)
        row.senderText = senderText

        -- Assunto (esquerda, base)
        local subjectText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        subjectText:SetPoint("LEFT", icon, "RIGHT", 8, -9)
        subjectText:SetPoint("RIGHT", badgesText, "LEFT", -8, 0)
        subjectText:SetJustifyH("LEFT")
        MailScreen:ApplyFont(subjectText, FONTS.medium, 13)
        row.subjectText = subjectText

        row.slotIndex = i
        row:RegisterForClicks("LeftButtonUp")
        row:SetScript("OnClick", function()
            local itemIdx = (MailScreen.inboxScrollOffset or 0) + this.slotIndex
            MailScreen.activeColumn = "INBOX"
            MailScreen.selectedInboxIndex = itemIdx
            MailScreen:UpdateColumnVisuals()
            MailScreen:RefreshInboxList()
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        end)

        row:SetScript("OnEnter", function()
            local itemIdx = (MailScreen.inboxScrollOffset or 0) + this.slotIndex
            if MailScreen.activeColumn ~= "INBOX" or (MailScreen.selectedInboxIndex ~= itemIdx) then
                this:SetBackdropBorderColor(0.70, 0.60, 0.40, 0.80)
            end
        end)

        row:SetScript("OnLeave", function()
            local itemIdx = (MailScreen.inboxScrollOffset or 0) + this.slotIndex
            if MailScreen.activeColumn == "INBOX" and itemIdx == MailScreen.selectedInboxIndex then
                this:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
            else
                this:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
            end
        end)

        row:Hide()
        table.insert(rows, row)
    end
    parent.rows = rows
    return rows
end

-- DetailCard da carta (molde MerchantMenu:CreateDetailCard, adaptado a
-- coluna estreita: descricoes empilhadas; mesma tipografia/cores).
-- M4.1: card FULL-HEIGHT — preenche toda a vertical da coluna direita
-- (topo E base da listArea, reservando só a faixa da action bar na base);
-- a área de corpo (bodyText) expande e quebra o texto. Sem espaço vazio.
function MailScreen:CreateMailDetailCard(parent)
    local card = CreateFrame("Frame", "ConsoleMode_MailDetailCard", parent)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -2)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -2)
    card:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 40)
    card:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 40)

    card:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
    card:SetBackdropBorderColor(0.50, 0.40, 0.28, 0.65)

    -- 1. Icone
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(40)
    icon:SetHeight(40)
    icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
    icon:SetTexture(MAIL_LETTER_ICON)
    card.icon = icon

    local iconBorder = CreateFrame("Frame", nil, card)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    iconBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    iconBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
    card.iconBorder = iconBorder

    -- 2. Dinheiro / COD
    local priceText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    priceText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -10)
    priceText:SetJustifyH("RIGHT")
    self:ApplyFont(priceText, FONTS.titleBold, 17)
    priceText:SetText("")
    card.priceText = priceText

    -- 3. Assunto
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, 0)
    titleText:SetPoint("RIGHT", priceText, "LEFT", -12, 0)
    titleText:SetJustifyH("LEFT")
    self:ApplyFont(titleText, FONTS.titleBold, 19)
    titleText:SetText("|cff888888Nenhuma carta selecionada|r")
    card.titleText = titleText

    -- 4. Remetente
    local typeText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    typeText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3)
    typeText:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    typeText:SetJustifyH("LEFT")
    self:ApplyFont(typeText, FONTS.medium, 15)
    typeText:SetText("|cff666666Navegue pelo inbox usando o D-Pad|r")
    card.typeText = typeText

    -- 4b. Dias restantes
    local useText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    useText:SetPoint("TOPLEFT", typeText, "BOTTOMLEFT", 0, -2)
    useText:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    useText:SetJustifyH("LEFT")
    self:ApplyFont(useText, FONTS.bodyBold, 13)
    useText:SetText("")
    useText:Hide()
    card.useText = useText

    -- 5. Anexo + status (empilhados p/ caber na coluna)
    local descTop = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descTop:SetPoint("TOPLEFT", useText, "BOTTOMLEFT", 0, -4)
    descTop:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -4)
    descTop:SetJustifyH("LEFT")
    descTop:SetJustifyV("TOP")
    self:ApplyFont(descTop, FONTS.bodyBold, 13)
    descTop:SetText("|cff666666Sem cartas para exibir.|r")
    card.descTop = descTop

    local descBottom = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descBottom:SetPoint("TOPLEFT", descTop, "BOTTOMLEFT", 0, -2)
    descBottom:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -2)
    descBottom:SetJustifyH("LEFT")
    descBottom:SetJustifyV("TOP")
    self:ApplyFont(descBottom, FONTS.bodyBold, 13)
    descBottom:SetText("")
    card.descBottom = descBottom

    -- 6. Corpo da carta (M4.1: expande até a base do card, wrap/justify).
    local bodyText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyText:SetPoint("TOPLEFT", descBottom, "BOTTOMLEFT", 0, -6)
    bodyText:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -12, -10)
    bodyText:SetJustifyH("LEFT")
    bodyText:SetJustifyV("TOP")
    self:ApplyFont(bodyText, FONTS.medium, 14)
    bodyText:SetText("")
    card.bodyText = bodyText

    return card
end

-- Leitura display-only do corpo (guarda isOpen + pcall; nunca escreve).
function MailScreen:GetMailBodyText(item)
    if not item then return nil end
    if not self.isOpen then return nil end
    if not GetInboxText then return nil end
    local ok, text = pcall(GetInboxText, item.index)
    if ok and type(text) == "string" and text ~= "" then
        return text
    end
    return nil
end

function MailScreen:ShowMailDetail(item)
    local card = self.frame and self.frame.rightCol and self.frame.rightCol.detailCard
    if not card then return end

    if not item then
        card.icon:SetTexture(MAIL_LETTER_ICON)
        card.iconBorder:SetBackdropBorderColor(0.40, 0.35, 0.25, 0.60)
        card.titleText:SetText("|cff888888Nenhuma carta selecionada|r")
        card.priceText:SetText("")
        card.typeText:SetText("|cff666666Navegue pelo inbox usando o D-Pad|r")
        if card.useText then
            card.useText:SetText("")
            card.useText:Hide()
        end
        card.descTop:SetText("|cff666666Sem cartas para exibir.|r")
        card.descBottom:SetText("")
        if card.bodyText then card.bodyText:SetText("") end
        return
    end

    card.icon:SetTexture(self:GetMailIconTexture(item))
    if self:IsMailUnread(item) then
        card.iconBorder:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.90)
    else
        card.iconBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
    end

    local subject = item.subject
    if not subject or subject == "" then subject = "(sem assunto)" end
    card.titleText:SetText("|cffe09a15" .. self:TruncateText(subject, 26) .. "|r")

    local sender = item.sender or "Desconhecido"
    local senderStr = "|cffb0b0b0De: |cffffffff" .. self:TruncateText(sender, 26) .. "|r"
    if item.wasReturned then
        senderStr = senderStr .. " |cff888888(devolvida)|r"
    end
    card.typeText:SetText(senderStr)

    local money = tonumber(item.money) or 0
    local cod = tonumber(item.cod) or 0
    local priceStr = "|cff888888Sem dinheiro|r"
    if money > 0 and cod > 0 then
        priceStr = "|cffaaaaaaContem:|r " .. self:FormatMoneyText(money) .. "  |cffff2020COD|r"
    elseif money > 0 then
        priceStr = "|cffaaaaaaContem:|r " .. self:FormatMoneyText(money)
    elseif cod > 0 then
        priceStr = "|cffff2020COD:|r " .. self:FormatMoneyText(cod)
    end
    card.priceText:SetText(priceStr)

    if card.useText then
        if tonumber(item.daysLeft) then
            card.useText:SetText("|cffb0b0b0Expira em " .. tonumber(item.daysLeft) .. " dias|r")
            card.useText:Show()
        else
            card.useText:SetText("")
            card.useText:Hide()
        end
    end

    local attachStr = "|cff888888Nao|r"
    if item.hasItem then attachStr = "|cff1eff00Sim|r" end
    local statusStr = "|cff888888Lida|r"
    if self:IsMailUnread(item) then statusStr = "|cffff2020Nova|r" end
    card.descTop:SetText("|cffaaaaaaAnexo:|r " .. attachStr .. "   |cffaaaaaaStatus:|r " .. statusStr)

    local replyStr = "|cff888888Nao|r"
    if item.canReply then replyStr = "|cffffffffSim|r" end
    card.descBottom:SetText("|cffaaaaaaResposta:|r " .. replyStr)

    if card.bodyText then
        local body = self:GetMailBodyText(item)
        if not body or body == "" then
            body = "|cff666666(sem texto para exibir)|r"
        elseif string.len(body) > 600 then
            body = string.sub(body, 1, 600) .. "..."
        end
        card.bodyText:SetText("|cffaaaaaaTexto:|r " .. body)
    end
end

-- Atualiza SOMENTE as 7 linhas visiveis (pool criado em CreateUI) + detalhe
-- + paginacao. Sem tooltip nesta fase.
function MailScreen:RefreshInboxList()
    -- M4.1: telas exclusivas; no compor a camada inbox fica oculta
    -- (ShowInboxScreen reexibe ao voltar).
    if self.currentScreen == "COMPOSE" then return end
    local leftCol = self.frame and self.frame.leftCol
    if not leftCol or not leftCol.listArea or not leftCol.listArea.rows then return end

    local rows = leftCol.listArea.rows
    local filtered = self.filteredInbox or {}
    local numItems = table.getn(filtered)

    local rightCol = self.frame and self.frame.rightCol
    if rightCol and rightCol.pageIndicator then
        if numItems == 0 then
            rightCol.pageIndicator:SetText("")
        else
            rightCol.pageIndicator:SetText("|cff888888" .. numItems .. " carta(s)|r")
        end
    end

    if numItems == 0 then
        for i = 1, 7 do rows[i]:Hide() end
        leftCol.placeholder:SetText("|cffaaaaaaCaixa de entrada vazia.|r")
        leftCol.placeholder:Show()
        leftCol.pageIndicator:SetText("|cff666666Nenhuma carta|r")
        self:ShowMailDetail(nil)
        self:UpdateActionButtonsVisuals()
        return
    end

    leftCol.placeholder:Hide()

    if (self.selectedInboxIndex or 1) > numItems then
        self.selectedInboxIndex = numItems
    end
    if (self.selectedInboxIndex or 1) < 1 then
        self.selectedInboxIndex = 1
    end

    local selectedItem = nil
    for slotIdx = 1, 7 do
        local itemIdx = (self.inboxScrollOffset or 0) + slotIdx
        local row = rows[slotIdx]

        if itemIdx <= numItems then
            local item = filtered[itemIdx]
            local unread = self:IsMailUnread(item)

            row.icon:SetTexture(self:GetMailIconTexture(item))
            if unread then
                row.iconBorder:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.90)
            else
                row.iconBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
            end

            local senderColor = "|cffffffff"
            if unread then senderColor = "|cffe09a15" end
            row.senderText:SetText(senderColor .. self:TruncateText(item.sender or "?", 20) .. "|r")

            local subject = item.subject
            if not subject or subject == "" then subject = "(sem assunto)" end
            row.subjectText:SetText("|cffaaaaaa" .. self:TruncateText(subject, 30) .. "|r")

            if tonumber(item.daysLeft) then
                row.daysText:SetText("|cffb0b0b0" .. tonumber(item.daysLeft) .. "d|r")
            else
                row.daysText:SetText("|cff666666--|r")
            end
            row.badgesText:SetText(self:BuildMailBadges(item))

            if self.activeColumn == "INBOX" and itemIdx == self.selectedInboxIndex then
                row:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                row:SetBackdropColor(0.28, 0.20, 0.08, 0.95)
                row.highlight:Show()
                row.cursor:Show()
                selectedItem = item
            else
                row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
                row:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
                row.highlight:Hide()
                row.cursor:Hide()
                if itemIdx == self.selectedInboxIndex then
                    selectedItem = item
                end
            end

            row:Show()
        else
            row:Hide()
        end
    end

    local curPage = math.floor((self.selectedInboxIndex - 1) / 7) + 1
    local totalPages = math.ceil(numItems / 7)
    if totalPages < 1 then totalPages = 1 end
    local arrowUp = (self.inboxScrollOffset > 0) and "▲ " or ""
    local arrowDown = ((self.inboxScrollOffset + 7) < numItems) and " ▼" or ""
    leftCol.pageIndicator:SetText(string.format("%s|cffaaaaaaItem %d de %d|r  |cff888888(Pág. %d/%d)|r%s", arrowUp, self.selectedInboxIndex, numItems, curPage, totalPages, arrowDown))

    self:ShowMailDetail(selectedItem)
    self:UpdateActionButtonsVisuals()
end

function MailScreen:UpdateInboxFilterBar()
    local leftCol = self.frame and self.frame.leftCol
    if not leftCol then return end

    local parts = {}
    local num = table.getn(MAIL_FILTERS)
    for idx = 1, num do
        local f = MAIL_FILTERS[idx]
        if idx == (self.inboxFilter or 1) then
            table.insert(parts, "|cffe09a15[ " .. f.name .. " ]|r")
        else
            table.insert(parts, "|cff848484" .. f.name .. "|r")
        end
    end
    if leftCol.tabsLabel then
        leftCol.tabsLabel:SetText(table.concat(parts, "   "))
    end
    if leftCol.title then
        leftCol.title:SetText("CAIXA DE ENTRADA: " .. self:GetInboxFilterName())
    end
end

function MailScreen:UpdateColumnVisuals()
    if not self.frame then return end

    local leftCol  = self.frame.leftCol
    local rightCol = self.frame.rightCol
    if not leftCol or not rightCol then return end

    -- M4.1: no compor, o destaque segue composeFocus (FIELDS=esquerda).
    if self.currentScreen == "COMPOSE" then
        if self.composeFocus == "INV" then
            rightCol:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
            rightCol:SetBackdropColor(0.12, 0.09, 0.06, 0.90)
            rightCol.title:SetTextColor(1.00, 0.85, 0.25, 1.0)
            rightCol.tagIcon:SetVertexColor(1.0, 1.0, 1.0, 1.0)

            leftCol:SetBackdropBorderColor(0.40, 0.32, 0.22, 0.45)
            leftCol:SetBackdropColor(0.06, 0.05, 0.04, 0.75)
            leftCol.title:SetTextColor(0.60, 0.55, 0.50, 0.80)
            leftCol.tagIcon:SetVertexColor(0.6, 0.6, 0.6, 0.80)
        else
            leftCol:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
            leftCol:SetBackdropColor(0.12, 0.09, 0.06, 0.90)
            leftCol.title:SetTextColor(1.00, 0.85, 0.25, 1.0)
            leftCol.tagIcon:SetVertexColor(1.0, 1.0, 1.0, 1.0)

            rightCol:SetBackdropBorderColor(0.40, 0.32, 0.22, 0.45)
            rightCol:SetBackdropColor(0.06, 0.05, 0.04, 0.75)
            rightCol.title:SetTextColor(0.60, 0.55, 0.50, 0.80)
            rightCol.tagIcon:SetVertexColor(0.6, 0.6, 0.6, 0.80)
        end
        self:RefreshComposeVisuals()
        return
    end

    if self.activeColumn == "DETAIL" then
        rightCol:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
        rightCol:SetBackdropColor(0.12, 0.09, 0.06, 0.90)
        rightCol.title:SetTextColor(1.00, 0.85, 0.25, 1.0)
        rightCol.tagIcon:SetVertexColor(1.0, 1.0, 1.0, 1.0)

        leftCol:SetBackdropBorderColor(0.40, 0.32, 0.22, 0.45)
        leftCol:SetBackdropColor(0.06, 0.05, 0.04, 0.75)
        leftCol.title:SetTextColor(0.60, 0.55, 0.50, 0.80)
        leftCol.tagIcon:SetVertexColor(0.6, 0.6, 0.6, 0.80)
    else
        leftCol:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
        leftCol:SetBackdropColor(0.12, 0.09, 0.06, 0.90)
        leftCol.title:SetTextColor(1.00, 0.85, 0.25, 1.0)
        leftCol.tagIcon:SetVertexColor(1.0, 1.0, 1.0, 1.0)

        rightCol:SetBackdropBorderColor(0.40, 0.32, 0.22, 0.45)
        rightCol:SetBackdropColor(0.06, 0.05, 0.04, 0.75)
        rightCol.title:SetTextColor(0.60, 0.55, 0.50, 0.80)
        rightCol.tagIcon:SetVertexColor(0.6, 0.6, 0.6, 0.80)
    end
    self:UpdateActionButtonsVisuals()
end

function MailScreen:MoveInboxSelection(delta)
    local numItems = table.getn(self.filteredInbox or {})
    if numItems == 0 then return end

    local newIdx = (self.selectedInboxIndex or 1) + (tonumber(delta) or 0)
    if newIdx < 1 then newIdx = 1 end
    if newIdx > numItems then newIdx = numItems end

    if newIdx ~= self.selectedInboxIndex then
        self.selectedInboxIndex = newIdx
        if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end

        local visibleRows = 7
        if self.selectedInboxIndex <= self.inboxScrollOffset then
            self.inboxScrollOffset = self.selectedInboxIndex - 1
        elseif self.selectedInboxIndex > (self.inboxScrollOffset + visibleRows) then
            self.inboxScrollOffset = self.selectedInboxIndex - visibleRows
        end
        if self.inboxScrollOffset < 0 then self.inboxScrollOffset = 0 end
        local maxOffset = math.max(0, numItems - visibleRows)
        if self.inboxScrollOffset > maxOffset then self.inboxScrollOffset = maxOffset end

        self:RefreshInboxList()
    end
end

-- LT/RT: cicla 1=Todos,2=Nao-lidos,3=Com anexo via SetInboxFilter existente;
-- reseta selecao/pagina ao trocar. M4.1: so na tela INBOX (no compor, LT/RT
-- = ComposeHalfJump; telas sao exclusivas).
function MailScreen:CycleInboxFilter(delta)
    if not self.isOpen then return end
    if self.currentScreen ~= "INBOX" then return end
    local f = tonumber(self.inboxFilter) or 1
    f = f + (tonumber(delta) or 0)
    if f > 3 then f = 1 end
    if f < 1 then f = 3 end
    self:SetInboxFilter(f)
    self.selectedInboxIndex = 1
    self.inboxScrollOffset = 0
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:UpdateInboxFilterBar()
    self:RefreshInboxList()
end

-- LB/RB: alterna o foco entre as colunas (cursor visual).
-- M4.1: LB/RB passam a trocar de TELA (ShowInbox/ShowCompose); esta funcao
-- segue existindo por compatibilidade de guards, mas sem chamada ativa.
function MailScreen:ToggleColumn(delta)
    if not self.isOpen then return end
    if self.activeColumn == "INBOX" then
        self.activeColumn = "DETAIL"
    else
        self.activeColumn = "INBOX"
    end
    if PlaySound then PlaySound("igCharacterInfoTab") end
    self:UpdateColumnVisuals()
    self:RefreshInboxList()
end

-- ----------------------------------------------------------------------------
-- 2f-M4.1. TELAS INBOX<->COMPOR (§3.1): RB vai p/ compor, LB volta p/ caixa,
-- nas duas telas. Containers persistentes criados 1x (CreateComposeUI);
-- Show* alterna visibilidade + titulos + footer + indicador de aba.
-- B NUNCA troca de tela (pilha em OnCancel/CloseTopFrame).
-- ----------------------------------------------------------------------------
function MailScreen:ShowInboxScreen()
    if not self.isOpen then return end
    if not self.frame then return end
    self.currentScreen = "INBOX"
    self.activeColumn = "INBOX"

    local leftCol = self.frame.leftCol
    local rightCol = self.frame.rightCol
    if not leftCol or not rightCol then return end

    if leftCol.composeBox then leftCol.composeBox:Hide() end
    if rightCol.invGrid then rightCol.invGrid:Hide() end
    if rightCol.detailCard then rightCol.detailCard:Show() end
    if self.actionBar then self.actionBar:Show() end

    if rightCol.title then rightCol.title:SetText("CARTA") end
    if rightCol.tabsLabel then
        rightCol.tabsLabel:SetText("|cff888888Detalhe da carta|r")
    end

    self:ClearComposeFocus()
    self:UpdateTabIndicator()
    self:UpdateFooterVisibility()
    self:UpdateInboxFilterBar()
    self:UpdateColumnVisuals()
    self:RefreshInboxList()
    if PlaySound then PlaySound("igCharacterInfoTab") end
end

function MailScreen:ShowComposeScreen()
    if not self.isOpen then return end
    if not self.frame then return end
    self.currentScreen = "COMPOSE"
    -- Neutro p/ a pilha de B: sem modal/detalhe, B fecha o MAIL (OnCancel).
    self.activeColumn = "INBOX"
    self.composeFocus = "FIELDS"
    if not tonumber(self.composeFieldIndex) then self.composeFieldIndex = 1 end
    if self.composeFieldIndex < 1 then self.composeFieldIndex = 1 end
    if self.composeFieldIndex > 6 then self.composeFieldIndex = 6 end

    local leftCol = self.frame.leftCol
    local rightCol = self.frame.rightCol
    if not leftCol or not rightCol then return end

    -- Esconde a camada inbox (RefreshInboxList reexibe ao voltar).
    if leftCol.listArea and leftCol.listArea.rows then
        local rows = leftCol.listArea.rows
        local n = table.getn(rows)
        for i = 1, n do rows[i]:Hide() end
    end
    if leftCol.placeholder then leftCol.placeholder:Hide() end
    if rightCol.detailCard then rightCol.detailCard:Hide() end
    if self.actionBar then self.actionBar:Hide() end

    if leftCol.composeBox then leftCol.composeBox:Show() end
    if rightCol.invGrid then rightCol.invGrid:Show() end

    -- Titulos e barras da tela compor.
    if leftCol.title then leftCol.title:SetText("NOVA CARTA") end
    if leftCol.tabsLabel then
        leftCol.tabsLabel:SetText("|cff888888Campos da carta|r")
    end
    if leftCol.pageIndicator then
        leftCol.pageIndicator:SetText("|cff8888885 campos + enviar|r")
    end
    if rightCol.title then rightCol.title:SetText("INVENTÁRIO") end
    if rightCol.tabsLabel then
        rightCol.tabsLabel:SetText("|cff888888Grade da bolsa (visual)|r")
    end

    -- Restaura o texto das EditBoxes a partir dos buffers estruturais.
    if leftCol.composeBox and leftCol.composeBox.rows then
        local rows = leftCol.composeBox.rows
        local n = table.getn(rows)
        for i = 1, n do
            local r = rows[i]
            if r and r.editBox and r.bufferKey then
                r.editBox:SetText(MailScreen[r.bufferKey] or "")
            end
        end
    end

    self:UpdateTabIndicator()
    self:UpdateFooterVisibility()
    self:UpdateComposePostage()
    self:ScanComposeBags()
    self:RefreshComposeVisuals()
    self:UpdateColumnVisuals()
    if PlaySound then PlaySound("igCharacterInfoTab") end
end

function MailScreen:ClearComposeFocus()
    local box = self.frame and self.frame.leftCol and self.frame.leftCol.composeBox
    if not box or not box.rows then return end
    local n = table.getn(box.rows)
    for i = 1, n do
        local r = box.rows[i]
        if r and r.editBox then
            local eb = r.editBox
            pcall(function() eb:ClearFocus() end)
        end
    end
end

-- ----------------------------------------------------------------------------
-- 2f-M4.1 (cont.). TELA COMPOR ESTRUTURAL (SEM logica de envio — M4.2):
-- esquerda NOVA CARTA com 5 areas focaveis + ENVIAR; direita INVENTARIO em
-- grade estilo MainMenu (icone, borda por qualidade, quantidade; so VISUAL +
-- navegacao, sem mover nada). EditBoxes reais: mouse clica e digita de
-- verdade; A sobre campo so faz log (VK chega na M4.2; SEM VirtualKeyboard).
-- ----------------------------------------------------------------------------
local COMPOSE_FIELDS = {
    { key = "composeTo",      label = "PARA",     h = 44,  kind = "edit",   max = 64 },
    { key = "composeSubject", label = "ASSUNTO",  h = 44,  kind = "edit",   max = 64 },
    { key = "composeBody",    label = "MENSAGEM", h = 122, kind = "editml", max = 2000 },
    { key = "composeMoney",   label = "DINHEIRO", h = 44,  kind = "edit",   max = 32 },
    { key = "itens",          label = "ITENS",    h = 60,  kind = "static", max = 0 },
}

function MailScreen:CreateComposeUI()
    local leftCol = self.frame and self.frame.leftCol
    local rightCol = self.frame and self.frame.rightCol
    if not leftCol or not rightCol then return end
    if leftCol.composeBox then return end

    -- Esquerda: NOVA CARTA (cobre a listArea do inbox).
    local box = CreateFrame("Frame", "ConsoleMode_MailComposeBox", leftCol.listArea)
    box:SetAllPoints(leftCol.listArea)
    box:EnableMouse(true)
    box.rows = {}

    local prev = nil
    local numFields = table.getn(COMPOSE_FIELDS)
    for i = 1, numFields do
        local def = COMPOSE_FIELDS[i]
        local row = CreateFrame("Button", "ConsoleMode_MailComposeField" .. i, box)
        row:SetHeight(def.h)
        if not prev then
            row:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -2)
            row:SetPoint("TOPRIGHT", box, "TOPRIGHT", -4, -2)
        else
            row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6)
            row:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -6)
        end
        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        row:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
        row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)

        local cap = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cap:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -4)
        self:ApplyFont(cap, FONTS.titleBold, 13)
        cap:SetText("|cff848484" .. def.label .. "|r")
        row.caption = cap

        row.fieldIndex = i
        row.bufferKey = def.key
        row.isStatic = (def.kind == "static")

        if def.kind == "static" then
            local st = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            st:SetPoint("TOPLEFT", cap, "BOTTOMLEFT", 0, -3)
            st:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, -4)
            st:SetJustifyH("LEFT")
            st:SetJustifyV("TOP")
            self:ApplyFont(st, FONTS.medium, 14)
            st:SetText("|cff666666Nenhum item na carta.|r")
            row.staticText = st
        else
            local eb = CreateFrame("EditBox", "ConsoleMode_MailComposeEB" .. i, row)
            eb:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -18)
            eb:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 5)
            eb:SetFont(FONTS.medium, 15)
            eb:SetTextColor(1.0, 1.0, 1.0, 1.0)
            eb:SetAutoFocus(false)
            eb:EnableMouse(true)
            eb:SetMaxLetters(def.max or 64)
            eb:SetBackdrop({
                bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile     = true, tileSize = 8, edgeSize = 8,
                insets   = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            eb:SetBackdropColor(0.0, 0.0, 0.0, 0.55)
            eb:SetBackdropBorderColor(0.30, 0.25, 0.18, 0.60)
            eb:SetTextInsets(6, 6, 2, 2)
            eb.fieldIndex = i
            eb.bufferKey = def.key
            if def.kind == "editml" then
                pcall(function() eb:SetMultiLine(true) end)
            end
            eb:SetScript("OnEditFocusGained", function()
                MailScreen.composeFocus = "FIELDS"
                MailScreen.composeFieldIndex = this.fieldIndex
                MailScreen:RefreshComposeVisuals()
            end)
            eb:SetScript("OnEditFocusLost", function()
                if this.bufferKey then
                    MailScreen[this.bufferKey] = this:GetText() or ""
                end
                if this.bufferKey == "composeMoney" then
                    if MailScreen:AutoFillSubjectForMoney() then
                        MailScreen:RefreshComposeVisuals()
                    end
                end
            end)
            eb:SetScript("OnEscapePressed", function()
                this:ClearFocus()
            end)
            eb:SetScript("OnEnterPressed", function()
                if this.bufferKey then
                    MailScreen[this.bufferKey] = this:GetText() or ""
                end
                if this.bufferKey == "composeMoney" then
                    if MailScreen:AutoFillSubjectForMoney() then
                        MailScreen:RefreshComposeVisuals()
                    end
                end
                this:ClearFocus()
            end)
            row.editBox = eb
        end

        row:SetScript("OnClick", function()
            MailScreen.composeFocus = "FIELDS"
            MailScreen.composeFieldIndex = this.fieldIndex
            MailScreen:RefreshComposeVisuals()
            if this.editBox then
                this.editBox:SetFocus()
            end
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        end)
        row:SetScript("OnEnter", function()
            if MailScreen.composeFocus ~= "FIELDS" or MailScreen.composeFieldIndex ~= this.fieldIndex then
                this:SetBackdropBorderColor(0.70, 0.60, 0.40, 0.80)
            end
        end)
        row:SetScript("OnLeave", function()
            MailScreen:RefreshComposeVisuals()
        end)

        table.insert(box.rows, row)
        prev = row
    end

    -- Botao ENVIAR centralizado embaixo (indice 6; visual com postagem).
    local sendBtn = CreateFrame("Button", "ConsoleMode_MailComposeSend", box)
    sendBtn:SetWidth(250)
    sendBtn:SetHeight(34)
    sendBtn:SetPoint("TOP", prev, "BOTTOM", 0, -8)
    sendBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    sendBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    sendBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    local sendLabel = sendBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sendLabel:SetPoint("CENTER", sendBtn, "CENTER", 0, 0)
    self:ApplyFont(sendLabel, FONTS.titleBold, 15)
    sendLabel:SetText("ENVIAR (postagem 30c)")
    box.sendBtn = sendBtn
    box.sendLabel = sendLabel
    sendBtn:RegisterForClicks("LeftButtonUp")
    sendBtn:SetScript("OnClick", function()
        MailScreen.composeFocus = "FIELDS"
        MailScreen.composeFieldIndex = 6
        MailScreen:RefreshComposeVisuals()
        MailScreen:OnComposeConfirm()
    end)
    sendBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    sendBtn:SetScript("OnLeave", function()
        MailScreen:RefreshComposeVisuals()
    end)

    leftCol.composeBox = box
    box:Hide()

    -- Direita: INVENTARIO em grade estilo MainMenu (so VISUAL + navegacao).
    local grid = self:CreateInventoryGrid(rightCol.listArea)
    rightCol.invGrid = grid
end

-- Texto da postagem p/ o botao ENVIAR (leitura display-only com guarda+pcall;
-- fallback 30c do plano §3.1 quando o preco nao estiver disponivel).
function MailScreen:GetComposePostageText()
    if self.isOpen and GetSendMailPrice then
        local ok, price = pcall(GetSendMailPrice)
        if ok and tonumber(price) and tonumber(price) > 0 then
            return self:FormatMoneyText(tonumber(price))
        end
    end
    return "30c"
end

function MailScreen:UpdateComposePostage()
    local box = self.frame and self.frame.leftCol and self.frame.leftCol.composeBox
    if not box or not box.sendLabel then return end
    box.sendLabel:SetText("ENVIAR (postagem " .. self:GetComposePostageText() .. ")")
end

-- ----------------------------------------------------------------------------
-- 2f-M4.1 (cont.). GRADE DO INVENTARIO: leitura display-only das bolsas
-- (GetContainerNumSlots/Link/Info com guarda isOpen + pcall; nunca move nada).
-- Pool persistente de slots (invCols x invRowsVisible) com icone, borda por
-- qualidade (QUALITY_COLORS) e quantidade; navegacao por celulas + scroll.
-- ----------------------------------------------------------------------------
function MailScreen:CreateInventoryGrid(parent)
    local grid = CreateFrame("Frame", "ConsoleMode_MailInvGrid", parent)
    grid:SetAllPoints(parent)
    grid:EnableMouse(true)
    grid:EnableMouseWheel(true)
    grid.slots = {}

    local size = 40
    local gap = 6
    local total = self.invCols * self.invRowsVisible
    for i = 1, total do
        local s = CreateFrame("Button", "ConsoleMode_MailInvSlot" .. i, grid)
        s:SetWidth(size)
        s:SetHeight(size)
        local col0 = math.mod(i - 1, self.invCols)
        local row0 = math.floor((i - 1) / self.invCols)
        s:SetPoint("TOPLEFT", grid, "TOPLEFT", 6 + col0 * (size + gap), -(6 + row0 * (size + gap)))
        s:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        s:SetBackdropColor(0.10, 0.08, 0.06, 0.60)
        s:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)

        local icon = s:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", s, "TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", -3, 3)
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        s.icon = icon

        local count = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        count:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", -3, 2)
        count:SetJustifyH("RIGHT")
        self:ApplyFont(count, FONTS.titleBold, 13)
        count:SetText("")
        s.countText = count

        -- Moldura extra dourada do foco (borda dupla): o backdrop do slot
        -- mantem edgeSize 8; este anel sobreposto com edgeSize 16 e o mesmo
        -- ouro (1.00, 0.82, 0.20) engrossa o destaque sem mudar a identidade.
        local ring = CreateFrame("Frame", nil, s)
        ring:SetPoint("TOPLEFT", s, "TOPLEFT", -3, 3)
        ring:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 3, -3)
        ring:EnableMouse(false)
        ring:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        ring:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
        ring:Hide()
        s.focusRing = ring

        s.slotPos = i
        s:RegisterForClicks("LeftButtonUp")
        s:SetScript("OnClick", function()
            local idx = (MailScreen.invScrollOffset or 0) * MailScreen.invCols + this.slotPos
            local n = table.getn(MailScreen.invItems or {})
            if idx >= 1 and idx <= n then
                -- Mouse: 1o clique seleciona; clicar de novo no mesmo slot
                -- anexa (se livre) ou devolve a bolsa (se anexado).
                if MailScreen.composeFocus == "INV" and MailScreen.invIndex == idx then
                    local it = MailScreen:GetInvItemAt(idx)
                    if it and MailScreen:IsItemAttached(it.bag, it.slot) then
                        MailScreen:DetachItemAtInvIndex()
                    else
                        MailScreen:AttachSelectedItem()
                    end
                else
                    MailScreen.composeFocus = "INV"
                    MailScreen.invIndex = idx
                    MailScreen:RefreshComposeVisuals()
                    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
                end
            end
        end)
        s:SetScript("OnEnter", function()
            this:SetBackdropBorderColor(0.70, 0.60, 0.40, 0.80)
        end)
        s:SetScript("OnLeave", function()
            MailScreen:RefreshComposeVisuals()
        end)

        s:Hide()
        table.insert(grid.slots, s)
    end

    grid:SetScript("OnMouseWheel", function()
        if MailScreen.currentScreen ~= "COMPOSE" then return end
        if arg1 > 0 then
            MailScreen:ScrollInventory(-1)
        else
            MailScreen:ScrollInventory(1)
        end
    end)

    grid:Hide()
    return grid
end

function MailScreen:ScanComposeBags()
    self.invItems = {}
    if not self.isOpen then return end
    if not GetContainerNumSlots then return end
    for bag = 0, 4 do
        local okSlots, numSlots = pcall(GetContainerNumSlots, bag)
        numSlots = tonumber(numSlots) or 0
        if okSlots and numSlots > 0 then
            for slot = 1, numSlots do
                if GetContainerItemLink then
                    local okLink, link = pcall(GetContainerItemLink, bag, slot)
                    if okLink and link then
                        local tex, count, quality, itemName = nil, 1, 1, nil
                        if GetContainerItemInfo then
                            local okInfo, t, c, locked, q = pcall(GetContainerItemInfo, bag, slot)
                            if okInfo then
                                tex = t
                                if tonumber(c) then count = tonumber(c) end
                                if tonumber(q) then quality = tonumber(q) end
                            end
                        end
                        if GetItemInfo then
                            local okI, nm, ln, qq, lv, cl, sub, stack, sl, tx = pcall(GetItemInfo, link)
                            if okI then
                                if nm then itemName = tostring(nm) end
                                if tonumber(qq) then quality = tonumber(qq) end
                                if not tex and tx then tex = tx end
                            end
                        end
                        if not tex then
                            tex = "Interface\\Icons\\INV_Misc_QuestionMark"
                        end
                        table.insert(self.invItems, {
                            bag = bag,
                            slot = slot,
                            texture = tex,
                            count = count,
                            quality = quality,
                            name = itemName,
                        })
                    end
                end
            end
        end
    end

    local n = table.getn(self.invItems)
    if (self.invIndex or 1) > n then
        self.invIndex = math.max(1, n)
    end
    if (self.invIndex or 1) < 1 then self.invIndex = 1 end
    self:ClampInventoryScroll()
    -- M4.2: poda anexos cuja bag/slot esvaziou (pausado com envio rodando).
    self:PruneComposeItems()
    self:RefreshInventoryGrid()
end

function MailScreen:ClampInventoryScroll()
    local n = table.getn(self.invItems or {})
    local cols = self.invCols or 5
    local rowsVis = self.invRowsVisible or 6
    local maxOffset = math.max(0, math.ceil(n / cols) - rowsVis)
    if (self.invScrollOffset or 0) > maxOffset then self.invScrollOffset = maxOffset end
    if (self.invScrollOffset or 0) < 0 then self.invScrollOffset = 0 end
    -- Mantem o slot focado visivel.
    local idx = self.invIndex or 1
    local firstVisible = self.invScrollOffset * cols + 1
    local lastVisible = (self.invScrollOffset + rowsVis) * cols
    if idx < firstVisible then
        self.invScrollOffset = math.floor((idx - 1) / cols)
    elseif idx > lastVisible then
        self.invScrollOffset = math.floor((idx - 1) / cols) - rowsVis + 1
    end
    if self.invScrollOffset < 0 then self.invScrollOffset = 0 end
    if self.invScrollOffset > maxOffset then self.invScrollOffset = maxOffset end
end

function MailScreen:ScrollInventory(deltaRows)
    if self.currentScreen ~= "COMPOSE" then return end
    local cols = self.invCols or 5
    local n = table.getn(self.invItems or {})
    local maxOffset = math.max(0, math.ceil(n / cols) - (self.invRowsVisible or 6))
    local off = (self.invScrollOffset or 0) + (tonumber(deltaRows) or 0)
    if off < 0 then off = 0 end
    if off > maxOffset then off = maxOffset end
    if off ~= self.invScrollOffset then
        self.invScrollOffset = off
        self:RefreshInventoryGrid()
    end
end

function MailScreen:RefreshInventoryGrid()
    local grid = self.frame and self.frame.rightCol and self.frame.rightCol.invGrid
    if not grid or not grid.slots then return end
    local items = self.invItems or {}
    local n = table.getn(items)
    local cols = self.invCols or 5
    local numSlots = table.getn(grid.slots)

    local rightCol = self.frame.rightCol
    if rightCol and rightCol.pageIndicator then
        if n == 0 then
            rightCol.pageIndicator:SetText("|cff666666Bolsas vazias|r")
        else
            rightCol.pageIndicator:SetText("|cff888888" .. n .. " item(s)|r")
        end
    end

    for i = 1, numSlots do
        local s = grid.slots[i]
        local itemIdx = (self.invScrollOffset or 0) * cols + i
        if itemIdx >= 1 and itemIdx <= n then
            local it = items[itemIdx]
            s.icon:SetTexture(it.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            local qc = QUALITY_COLORS[tonumber(it.quality) or 1] or QUALITY_COLORS[1]
            if (tonumber(it.count) or 1) > 1 then
                s.countText:SetText(tostring(it.count))
            else
                s.countText:SetText("")
            end
            -- M4.2: slot anexado = fundo/borda VERMELHOS + badge "NA CARTA"
            -- (foco ouro tem precedencia na borda; badge segue visivel).
            -- Foco = borda dupla: cor ouro no backdrop + anel extra (edge 16).
            local attached = self:IsItemAttached(it.bag, it.slot)
            local isFocused = (self.composeFocus == "INV" and itemIdx == (self.invIndex or 1))
            if isFocused then
                s:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                s:SetBackdropColor(0.28, 0.20, 0.08, 0.95)
            elseif attached then
                s:SetBackdropBorderColor(1.00, 0.15, 0.15, 1.00)
                s:SetBackdropColor(0.30, 0.05, 0.05, 0.85)
            else
                s:SetBackdropBorderColor(qc.r, qc.g, qc.b, 0.85)
                s:SetBackdropColor(0.10, 0.08, 0.06, 0.60)
            end
            if attached then
                s.icon:SetVertexColor(0.55, 0.55, 0.55)
            else
                s.icon:SetVertexColor(1.0, 1.0, 1.0)
            end
            if not s.badge then
                local bdg = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                bdg:SetPoint("TOP", s, "TOP", 0, -1)
                self:ApplyFont(bdg, FONTS.titleBold, 9)
                bdg:SetText("NA CARTA")
                bdg:SetTextColor(1.0, 0.25, 0.25, 1.0)
                s.badge = bdg
            end
            if attached then
                s.badge:Show()
            else
                s.badge:Hide()
            end
            if s.focusRing then
                if isFocused then
                    s.focusRing:Show()
                else
                    s.focusRing:Hide()
                end
            end
            s:Show()
        else
            s:Hide()
        end
    end
end

function MailScreen:RefreshComposeVisuals()
    local box = self.frame and self.frame.leftCol and self.frame.leftCol.composeBox
    if box and box.rows then
        local n = table.getn(box.rows)
        for i = 1, n do
            local r = box.rows[i]
            if self.composeFocus == "FIELDS" and (self.composeFieldIndex or 1) == r.fieldIndex then
                r:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                r:SetBackdropColor(0.28, 0.20, 0.08, 0.95)
            else
                r:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
                r:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
            end
        end
        if box.sendBtn then
            if self.composeFocus == "FIELDS" and (self.composeFieldIndex or 1) == 6 then
                box.sendBtn:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                box.sendBtn:SetBackdropColor(0.28, 0.20, 0.08, 0.95)
            else
                box.sendBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
                box.sendBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
            end
        end
    end
    -- M4.2: texto da area ITENS acompanha a lista de anexos.
    self:UpdateComposeItemsText()
    self:RefreshInventoryGrid()
end

-- ----------------------------------------------------------------------------
-- 2f-M4.1 (cont.). NAVEGACAO ESPACIAL DO COMPOR (§3.2): D-Pad move o foco na
-- direcao; atravessa p/ a area vizinha (campos<->inventario); borda sem
-- vizinho = parado; sem wrap. Telas sao exclusivas (sem travessia entre
-- telas). LT/RT = salto p/ o primeiro elemento da proxima/anterior metade.
-- ----------------------------------------------------------------------------
function MailScreen:MoveComposeField(delta)
    if not self.isOpen then return end
    local idx = (self.composeFieldIndex or 1) + (tonumber(delta) or 0)
    if idx < 1 then idx = 1 end
    if idx > 6 then idx = 6 end
    if idx ~= self.composeFieldIndex then
        self.composeFocus = "FIELDS"
        self.composeFieldIndex = idx
        if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        self:RefreshComposeVisuals()
    elseif self.composeFocus ~= "FIELDS" then
        self.composeFocus = "FIELDS"
        self:RefreshComposeVisuals()
    end
end

function MailScreen:ComposeFocusInv()
    if not self.isOpen then return end
    local n = table.getn(self.invItems or {})
    self.composeFocus = "INV"
    if (self.invIndex or 1) < 1 then self.invIndex = 1 end
    if n > 0 and self.invIndex > n then self.invIndex = n end
    self:ClampInventoryScroll()
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:RefreshComposeVisuals()
end

function MailScreen:MoveInvSelection(direction)
    if not self.isOpen then return end
    local items = self.invItems or {}
    local n = table.getn(items)
    local cols = self.invCols or 5
    local idx = self.invIndex or 1

    if n == 0 then
        if direction == "LEFT" then
            self.composeFocus = "FIELDS"
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
            self:RefreshComposeVisuals()
        end
        return
    end

    local col = math.mod(idx - 1, cols) + 1
    local newIdx = nil
    if direction == "LEFT" then
        if col == 1 then
            -- Atravessa p/ a area vizinha (campos).
            self.composeFocus = "FIELDS"
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
            self:RefreshComposeVisuals()
            return
        end
        newIdx = idx - 1
    elseif direction == "RIGHT" then
        if idx >= n or col == cols then return end
        newIdx = idx + 1
    elseif direction == "UP" then
        if idx - cols < 1 then return end
        newIdx = idx - cols
    elseif direction == "DOWN" then
        if idx + cols > n then return end
        newIdx = idx + cols
    else
        return
    end

    if newIdx and newIdx ~= idx then
        self.invIndex = newIdx
        self:ClampInventoryScroll()
        if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        self:RefreshComposeVisuals()
    end
end

-- LT/RT no compor: salto p/ o primeiro elemento da proxima (RT) /
-- anterior (LT) metade (topo dos campos / slot 1 do inventario).
function MailScreen:ComposeHalfJump(delta)
    if not self.isOpen then return end
    if self.currentScreen ~= "COMPOSE" then return end
    local half = 1
    if self.composeFocus == "INV" then half = 2 end
    half = half + (tonumber(delta) or 0)
    if half < 1 then half = 1 end
    if half > 2 then half = 2 end
    if half == 1 then
        self.composeFocus = "FIELDS"
        self.composeFieldIndex = 1
    else
        self.composeFocus = "INV"
        self.invIndex = 1
        self.invScrollOffset = 0
    end
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:RefreshComposeVisuals()
end

function MailScreen:OnComposeDirection(direction)
    if not self.isOpen then return end
    if self.composeFocus == "INV" then
        self:MoveInvSelection(direction)
        return
    end
    if direction == "UP" then
        self:MoveComposeField(-1)
    elseif direction == "DOWN" then
        self:MoveComposeField(1)
    elseif direction == "RIGHT" then
        self:ComposeFocusInv()
    elseif direction == "LEFT" then
        -- Borda sem vizinho = parado.
    end
end

-- ----------------------------------------------------------------------------
-- 2f-M4.2. BOTOES DO COMPOR (reais): A abre VK / modal de dinheiro / anexa /
-- ENVIAR; X devolve item anexado a bolsa (de qualquer foco); Y abre o modal
-- de quantidade. Com VK/modal aberto, A/X/Y pertencem a eles (guardas).
-- ----------------------------------------------------------------------------
function MailScreen:OnComposeConfirm()
    if not self.isOpen then return end
    if self.currentScreen ~= "COMPOSE" then return end
    if self:IsVKOpen() then return end
    if self:IsMoneyModalOpen() then
        self:MoneyModalConfirm()
        return
    end
    if self:IsQtyModalOpen() then
        self:QtyModalConfirm()
        return
    end
    if self:IsConfirmOpen() then return end
    if self.sendQueue and self.sendQueue.running then return end
    if self.composeFocus == "INV" then
        self:AttachSelectedItem()
        return
    end
    local idx = tonumber(self.composeFieldIndex) or 1
    if idx == 6 then
        self:TrySendMail()
    elseif idx == 5 then
        -- A na area ITENS leva o foco p/ o inventario (escolha do anexo).
        self:ComposeFocusInv()
    elseif idx == 4 then
        self:OpenMoneyModal()
    else
        self:OpenVKForField(idx)
    end
end

function MailScreen:OnComposeSecondary()
    if not self.isOpen then return end
    if self.currentScreen ~= "COMPOSE" then return end
    -- X com VK/modal aberto pertence a eles (no VK, X = backspace).
    if self:IsVKOpen() then return end
    if self:IsMoneyModalOpen() then return end
    if self:IsQtyModalOpen() then return end
    if self:IsConfirmOpen() then return end
    if self.sendQueue and self.sendQueue.running then return end
    -- X sobre item anexado o devolve a bolsa, de onde estiver o foco.
    self:DetachItemAtInvIndex()
end

function MailScreen:OnComposeUse()
    if not self.isOpen then return end
    if self.currentScreen ~= "COMPOSE" then return end
    -- Y com VK/modal aberto pertence a eles (no VK, Y = shift). Y no compor
    -- nunca e TakeAll (TakeAll so existe na inbox, M4.1 mantido).
    if self:IsVKOpen() then return end
    if self:IsMoneyModalOpen() then return end
    if self:IsQtyModalOpen() then return end
    if self:IsConfirmOpen() then return end
    if self.sendQueue and self.sendQueue.running then return end
    self:OpenQtyModalForInvIndex()
end

-- ----------------------------------------------------------------------------
-- 2f-M4.2 (I). HISTORICO + VK NOS 3 CAMPOS (§3.1/§4.2 + §7 M4)
-- Contrato VK congelado (so consumo, nunca edicao): Open({title,
-- initialText, maxLetters, multiLine, autoCompleteList, onConfirm*,
-- onCancel, targetEditBox}), Close(), IsOpen(). O VK nunca le/escreve SV:
-- o MailScreen monta autoCompleteList = alts + historico e aplica a politica
-- (move-para-frente, sem duplicata, teto 20) no onConfirm, em SV separada
-- ConsoleModeMailHistory (+1 nome na linha SavedVariables do .toc).
-- Se o VK estiver ausente ou falhar, fallback = focar o EditBox (fisico).
-- ----------------------------------------------------------------------------
function MailScreen:TrimText(s)
    s = tostring(s or "")
    local n = string.len(s)
    local i = 1
    while i <= n do
        local ch = string.sub(s, i, i)
        if ch == " " or ch == "\t" or ch == "\n" or ch == "\r" then
            i = i + 1
        else
            break
        end
    end
    local j = n
    while j >= i do
        local ch = string.sub(s, j, j)
        if ch == " " or ch == "\t" or ch == "\n" or ch == "\r" then
            j = j - 1
        else
            break
        end
    end
    if j < i then return "" end
    return string.sub(s, i, j)
end

-- Garante a SV ConsoleModeMailHistory SEM nunca substituir a referencia da
-- tabela carregada (sustenta o /reload): cria so se ausente; se presente,
-- sanitiza IN PLACE (fora nao-strings/vazios, teto 20 do fim). Chamada apos
-- VARIABLES_LOADED (Initialize/autoInit) e em todo acesso.
function MailScreen:EnsureMailHistory()
    if type(ConsoleModeMailHistory) ~= "table" then
        ConsoleModeMailHistory = {}
        return ConsoleModeMailHistory
    end
    local h = ConsoleModeMailHistory
    local n = table.getn(h)
    for i = n, 1, -1 do
        local v = h[i]
        if type(v) ~= "string" or self:TrimText(v) == "" then
            table.remove(h, i)
        end
    end
    while table.getn(h) > 20 do
        table.remove(h)
    end
    return h
end

function MailScreen:GetMailHistory()
    return self:EnsureMailHistory()
end

function MailScreen:PushMailHistory(name)
    name = self:TrimText(name or "")
    if name == "" then return end
    local h = self:GetMailHistory()
    local lname = string.lower(name)
    local n = table.getn(h)
    for i = n, 1, -1 do
        if string.lower(tostring(h[i] or "")) == lname then
            table.remove(h, i)
        end
    end
    table.insert(h, 1, name)
    while table.getn(h) > 20 do
        table.remove(h)
    end
    -- Reancora a global na tabela mutada (garante que a SV serializada no
    -- /reload/logout e exatamente este conteudo; politica intacta).
    ConsoleModeMailHistory = h
end

-- Alts = nomes dos outros chars (fonte existente no addon: chaves de
-- ConsoleModeDB.backup, um backup de binds por personagem; se vazio, lista
-- vazia + historico). Ordenada p/ UX estavel.
function MailScreen:GetAltsList()
    local alts = {}
    if ConsoleModeDB and type(ConsoleModeDB.backup) == "table" then
        for name in pairs(ConsoleModeDB.backup) do
            if type(name) == "string" and name ~= "" then
                table.insert(alts, name)
            end
        end
        table.sort(alts)
    end
    return alts
end

function MailScreen:BuildAutoCompleteList()
    local out = {}
    local seen = {}
    local alts = self:GetAltsList()
    local na = table.getn(alts)
    for i = 1, na do
        local nm = self:TrimText(alts[i] or "")
        if nm ~= "" and not seen[string.lower(nm)] then
            seen[string.lower(nm)] = true
            table.insert(out, nm)
        end
    end
    local h = self:GetMailHistory()
    local nh = table.getn(h)
    for i = 1, nh do
        local nm = self:TrimText(h[i] or "")
        if nm ~= "" and not seen[string.lower(nm)] then
            seen[string.lower(nm)] = true
            table.insert(out, nm)
        end
    end
    return out
end

function MailScreen:IsVKOpen()
    local vk = CM and CM.VirtualKeyboard
    if vk and vk.IsOpen then
        local ok, open = pcall(function() return vk:IsOpen() end)
        if ok and open then return true end
    end
    return false
end

function MailScreen:GetComposeEditBox(fieldIndex)
    local box = self.frame and self.frame.leftCol and self.frame.leftCol.composeBox
    if not box or not box.rows then return nil end
    local n = table.getn(box.rows)
    for i = 1, n do
        local r = box.rows[i]
        if r and r.fieldIndex == fieldIndex and r.editBox then
            return r.editBox
        end
    end
    return nil
end

-- Copia o texto atual das EditBoxes p/ os buffers (leitura display-only;
-- garante que texto digitado sem perder o foco entre no envio/VK).
function MailScreen:SyncComposeBuffersFromUI()
    local box = self.frame and self.frame.leftCol and self.frame.leftCol.composeBox
    if not box or not box.rows then return end
    local n = table.getn(box.rows)
    for i = 1, n do
        local r = box.rows[i]
        if r and r.editBox and r.bufferKey then
            local ok, txt = pcall(function() return r.editBox:GetText() end)
            if ok and type(txt) == "string" then
                MailScreen[r.bufferKey] = txt
            end
        end
    end
    self:AutoFillSubjectForMoney()
end

function MailScreen:GetFirstAttachName()
    local list = self.composeItems or {}
    if table.getn(list) >= 1 and list[1] and list[1].name then
        return tostring(list[1].name)
    end
    return nil
end

-- A sobre Para/Assunto/Mensagem: abre o VK com guards nil em tudo; fallback
-- = focar o EditBox p/ digitacao fisica. Preserva \n e acentos (buffer
-- opaco, sem parse). Assunto preenche com o nome do 1o anexo se vazio.
function MailScreen:OpenVKForField(fieldIndex)
    if not self.isOpen then return false end
    fieldIndex = tonumber(fieldIndex) or 0
    if fieldIndex < 1 or fieldIndex > 3 then return false end
    self:SyncComposeBuffersFromUI()
    local eb = self:GetComposeEditBox(fieldIndex)
    local vk = CM and CM.VirtualKeyboard
    if vk and vk.Open then
        local title = "Texto"
        local initial = ""
        local maxL = 64
        local multi = false
        local acList = nil
        if fieldIndex == 1 then
            title = "Destinatário"
            initial = self.composeTo or ""
            maxL = 64
            multi = false
            acList = self:BuildAutoCompleteList()
        elseif fieldIndex == 2 then
            title = "Assunto"
            maxL = 64
            multi = false
            initial = self.composeSubject or ""
            if initial == "" then
                initial = self:GetFirstAttachName() or ""
            end
        else
            title = "Mensagem"
            initial = self.composeBody or ""
            maxL = 2000
            multi = true
        end
        local cfg = {
            title = title,
            initialText = initial,
            maxLetters = maxL,
            multiLine = multi,
            autoCompleteList = acList,
            targetEditBox = eb,
            onConfirm = function(text) MailScreen:OnVKConfirm(fieldIndex, text) end,
            onCancel = function() end,
        }
        local ok, opened = pcall(function() return vk:Open(cfg) end)
        if ok and opened then return true end
    end
    if eb then
        pcall(function() eb:SetFocus() end)
    end
    return false
end

-- onConfirm do VK: salva o buffer + historico (Para) + refresh visual.
function MailScreen:OnVKConfirm(fieldIndex, text)
    text = tostring(text or "")
    if fieldIndex == 1 then
        self.composeTo = text
        self:PushMailHistory(text)
    elseif fieldIndex == 2 then
        self.composeSubject = text
    elseif fieldIndex == 3 then
        self.composeBody = text
    else
        return
    end
    local eb = self:GetComposeEditBox(fieldIndex)
    if eb then
        pcall(function() eb:SetText(text) end)
    end
    self:RefreshComposeVisuals()
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Campo atualizado via teclado virtual.")
    end
end

-- ----------------------------------------------------------------------------
-- 2f-M4.2 (II). ANEXOS (§3.1/§7 M4)
-- A sobre slot com item anexa a carta (lista composeItems aceita N; no envio
-- sai 1 item por carta). Slot anexado = fundo/borda VERMELHOS + badge
-- "NA CARTA". X sobre item anexado (qualquer foco) o devolve a bolsa. O item
-- so sai da bolsa no momento do envio (PickupContainerItem +
-- ClickSendMailItemButton, com isOpen). Assunto auto-preenche com o nome do
-- 1o item se vazio.
-- ----------------------------------------------------------------------------
function MailScreen:GetInvItemAt(idx)
    local items = self.invItems or {}
    idx = tonumber(idx) or 0
    if idx < 1 or idx > table.getn(items) then return nil end
    return items[idx]
end

function MailScreen:FindAttached(bag, slot)
    local list = self.composeItems or {}
    local n = table.getn(list)
    for i = 1, n do
        local e = list[i]
        if e and e.bag == bag and e.slot == slot then
            return i, e
        end
    end
    return nil, nil
end

function MailScreen:IsItemAttached(bag, slot)
    local pos, _ = self:FindAttached(bag, slot)
    if pos then return true end
    return false
end

function MailScreen:AutoFillSubject()
    local subj = self:TrimText(self.composeSubject or "")
    if subj ~= "" then return end
    local nm = self:GetFirstAttachName()
    if not nm or nm == "" then return end
    self.composeSubject = nm
    local eb = self:GetComposeEditBox(2)
    if eb then
        pcall(function() eb:SetText(nm) end)
    end
end

-- Regra dinheiro-sem-itens (Turtle barra assunto curto no envio): se ha
-- dinheiro (>0), sem itens anexados e assunto vazio, preenche "gold".
-- Nunca sobrescreve assunto digitado; com itens, a regra do 1o item vale.
function MailScreen:AutoFillSubjectForMoney()
    if table.getn(self.composeItems or {}) > 0 then return false end
    if self:TrimText(self.composeSubject or "") ~= "" then return false end
    local money = math.floor(tonumber(self.composeMoney) or 0)
    if money <= 0 then return false end
    self.composeSubject = "gold"
    local eb = self:GetComposeEditBox(2)
    if eb then
        pcall(function() eb:SetText("gold") end)
    end
    return true
end

function MailScreen:AttachSelectedItem()
    if not self.isOpen then return end
    if self.sendQueue and self.sendQueue.running then return end
    local it = self:GetInvItemAt(self.invIndex)
    if not it then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Nenhum item selecionado para anexar.")
        end
        return
    end
    if self:IsItemAttached(it.bag, it.slot) then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Item ja esta na carta.")
        end
        return
    end
    local qty = tonumber(it.count) or 1
    if qty < 1 then qty = 1 end
    table.insert(self.composeItems, {
        bag = it.bag,
        slot = it.slot,
        name = it.name or "Item",
        texture = it.texture,
        count = qty,
        qty = qty,
    })
    self:AutoFillSubject()
    self:UpdateComposeItemsText()
    self:RefreshComposeVisuals()
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Anexado: " .. tostring(it.name or "Item") .. " x" .. qty .. ".")
    end
end

function MailScreen:DetachItemAtInvIndex()
    if not self.isOpen then return end
    if self.sendQueue and self.sendQueue.running then return end
    local it = self:GetInvItemAt(self.invIndex)
    if not it then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Nenhum item sob o cursor para tirar.")
        end
        return
    end
    local pos, _ = self:FindAttached(it.bag, it.slot)
    if not pos then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Item nao esta na carta.")
        end
        return
    end
    local e = self.composeItems[pos]
    local nm = (e and e.name) or it.name or "Item"
    table.remove(self.composeItems, pos)
    self:UpdateComposeItemsText()
    self:RefreshComposeVisuals()
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Devolvido a bolsa: " .. tostring(nm) .. ".")
    end
end

-- Remove da lista entradas cuja bag/slot nao tem mais item (leitura com
-- guarda+pcall; nunca move nada). Pausado com fila de envio rodando.
function MailScreen:PruneComposeItems()
    if self.sendQueue and self.sendQueue.running then return end
    if not GetContainerItemLink then return end
    local list = self.composeItems or {}
    local n = table.getn(list)
    for i = n, 1, -1 do
        local e = list[i]
        local gone = true
        if e and e.bag ~= nil and e.slot ~= nil then
            local ok, link = pcall(GetContainerItemLink, e.bag, e.slot)
            if ok and link then gone = false end
        end
        if gone then table.remove(list, i) end
    end
    self:UpdateComposeItemsText()
end

-- Texto da area ITENS (linha 5): 1o anexo + contador (max 2 linhas; row h=60).
function MailScreen:UpdateComposeItemsText()
    local box = self.frame and self.frame.leftCol and self.frame.leftCol.composeBox
    if not box or not box.rows then return end
    local stRow = nil
    local n = table.getn(box.rows)
    for i = 1, n do
        local r = box.rows[i]
        if r and r.fieldIndex == 5 and r.staticText then
            stRow = r.staticText
        end
    end
    if not stRow then return end
    local list = self.composeItems or {}
    local total = table.getn(list)
    if total == 0 then
        stRow:SetText("|cff666666Nenhum item na carta.|r")
        return
    end
    local e = list[1]
    local nm = (e and e.name) or "Item"
    local q = (e and tonumber(e.qty)) or 1
    if total == 1 then
        stRow:SetText("|cffffffff• " .. self:TruncateText(nm, 24) .. "|r |cffaaaaaax" .. q .. "|r")
    else
        stRow:SetText("|cffffffff• " .. self:TruncateText(nm, 24) .. "|r |cffaaaaaax" .. q .. "|r  |cff888888(+" .. (total - 1) .. ")|r")
    end
end

-- ----------------------------------------------------------------------------
-- 2f-M4.2 (III). MODAL DE QUANTIDADE (§7 M4: Y no inventario do compor)
-- FULLSCREEN_DIALOG/50 (molde MerchantMenu qty modal): D-Pad UP/DOWN ajusta
-- (hold via StartRepeat/OnDirection), teto = tamanho da pilha, A confirma
-- (define a quantidade do item na lista), B cancela, mouse digita o numero
-- na EditBox + botoes clicaveis.
-- ----------------------------------------------------------------------------
function MailScreen:CreateQtyModalUI()
    if self.qtyModalFrame then return self.qtyModalFrame end
    local m = CreateFrame("Frame", "ConsoleMode_MailQtyModal", UIParent)
    m:SetWidth(420)
    m:SetHeight(260)
    m:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    m:SetFrameStrata("FULLSCREEN_DIALOG")
    m:SetFrameLevel(50)
    m:EnableMouse(true)
    m:SetMovable(false)
    m:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    m:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
    m:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
    m:Hide()

    local title = m:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", m, "TOP", 0, -14)
    self:ApplyFont(title, FONTS.titleBold, 19)
    title:SetText("|cffe09a15Quantidade|r")
    m.title = title

    local name = m:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("TOP", title, "BOTTOM", 0, -6)
    name:SetWidth(380)
    name:SetJustifyH("CENTER")
    self:ApplyFont(name, FONTS.titleBold, 16)
    name:SetText("|cffffffffItem|r")
    m.nameText = name

    local qty = m:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    qty:SetPoint("CENTER", m, "CENTER", 0, 18)
    self:ApplyFont(qty, FONTS.titleBold, 30)
    qty:SetText("|cffe09a15x1|r")
    m.qtyText = qty

    -- EditBox p/ o mouse digitar o numero (D-Pad ajusta o mesmo valor).
    local eb = CreateFrame("EditBox", "ConsoleMode_MailQtyModalEB", m)
    eb:SetWidth(110)
    eb:SetHeight(28)
    eb:SetPoint("CENTER", m, "CENTER", 0, -22)
    eb:SetFont(FONTS.medium, 16)
    eb:SetTextColor(1.0, 1.0, 1.0, 1.0)
    eb:SetAutoFocus(false)
    eb:EnableMouse(true)
    eb:SetMaxLetters(5)
    eb:SetJustifyH("CENTER")
    pcall(function() eb:SetNumeric(true) end)
    eb:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    eb:SetBackdropColor(0.0, 0.0, 0.0, 0.55)
    eb:SetBackdropBorderColor(0.30, 0.25, 0.18, 0.60)
    eb:SetScript("OnEnterPressed", function()
        MailScreen:QtyModalConfirm()
    end)
    eb:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    eb:SetScript("OnEditFocusLost", function()
        MailScreen:QtyModalSyncFromEditBox()
    end)
    m.qtyEditBox = eb

    local hints = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hints:SetPoint("BOTTOM", m, "BOTTOM", 0, 52)
    hints:SetWidth(390)
    hints:SetJustifyH("CENTER")
    self:ApplyFont(hints, FONTS.titleBold, 14)
    hints:SetText("|cffffffff[D-Pad Up/Down]|r ajustar   |cffffffff[A]|r confirmar   |cffffffff[B]|r cancelar")
    m.hints = hints

    local confirmBtn = CreateFrame("Button", "ConsoleMode_MailQtyConfirmYes", m)
    confirmBtn:SetWidth(150)
    confirmBtn:SetHeight(28)
    confirmBtn:SetPoint("BOTTOMLEFT", m, "BOTTOM", -160, 10)
    confirmBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    confirmBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    confirmBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    local confirmTxt = confirmBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    confirmTxt:SetPoint("CENTER", confirmBtn, "CENTER", 0, 0)
    MailScreen:ApplyFont(confirmTxt, FONTS.titleBold, 15)
    confirmTxt:SetText("Confirmar")
    confirmBtn:SetScript("OnClick", function()
        MailScreen:QtyModalConfirm()
    end)
    confirmBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
    end)
    confirmBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)
    m.confirmBtn = confirmBtn

    local cancelBtn = CreateFrame("Button", "ConsoleMode_MailQtyConfirmNo", m)
    cancelBtn:SetWidth(150)
    cancelBtn:SetHeight(28)
    cancelBtn:SetPoint("BOTTOMRIGHT", m, "BOTTOM", 160, 10)
    cancelBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    cancelBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    cancelBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    local cancelTxt = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cancelTxt:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
    MailScreen:ApplyFont(cancelTxt, FONTS.titleBold, 15)
    cancelTxt:SetText("Cancelar")
    cancelBtn:SetScript("OnClick", function()
        MailScreen:CloseQtyModal()
    end)
    cancelBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
    end)
    cancelBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)
    m.cancelBtn = cancelBtn

    m:SetScript("OnHide", function()
        MailScreen.qtyModal.isOpen = false
    end)
    table.insert(UISpecialFrames, "ConsoleMode_MailQtyModal")

    self.qtyModalFrame = m
    return m
end

function MailScreen:IsQtyModalOpen()
    if self.qtyModal and self.qtyModal.isOpen then return true end
    if self.qtyModalFrame and self.qtyModalFrame:IsVisible() then return true end
    return false
end

function MailScreen:OpenQtyModalForInvIndex()
    if not self.isOpen then return end
    if self.currentScreen ~= "COMPOSE" then return end
    if self:IsVKOpen() then return end
    if self:IsMoneyModalOpen() then return end
    if self.sendQueue and self.sendQueue.running then return end
    local it = self:GetInvItemAt(self.invIndex)
    if not it then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Sem item para definir quantidade.")
        end
        return
    end
    local maxQ = tonumber(it.count) or 1
    if maxQ < 1 then maxQ = 1 end
    local _, e = self:FindAttached(it.bag, it.slot)
    local startQ = maxQ
    if e and tonumber(e.qty) then
        startQ = tonumber(e.qty)
        if startQ < 1 then startQ = 1 end
        if startQ > maxQ then startQ = maxQ end
    end
    self.qtyModal.isOpen = true
    self.qtyModal.bag = it.bag
    self.qtyModal.slot = it.slot
    self.qtyModal.qty = startQ
    self.qtyModal.maxQty = maxQ
    self.qtyModal.itemName = it.name or "Item"
    self:CreateQtyModalUI()
    self:UpdateQtyModalVisuals()
    self.qtyModalFrame:Show()
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
end

function MailScreen:CloseQtyModal(silent)
    self.qtyModal.isOpen = false
    self.qtyModal.bag = nil
    self.qtyModal.slot = nil
    self.qtyModal.qty = 1
    if self.qtyModalFrame and self.qtyModalFrame:IsVisible() then
        self.qtyModalFrame:Hide()
    end
    if not silent then
        if PlaySound then PlaySound("igMainMenuClose") end
    end
end

function MailScreen:QtyModalAdjust(delta)
    if not self:IsQtyModalOpen() then return end
    delta = tonumber(delta) or 0
    local q = (tonumber(self.qtyModal.qty) or 1) + delta
    local mx = tonumber(self.qtyModal.maxQty) or 1
    if q < 1 then q = 1 end
    if q > mx then q = mx end
    if q ~= self.qtyModal.qty then
        self.qtyModal.qty = q
        if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        self:UpdateQtyModalVisuals()
    end
end

function MailScreen:QtyModalSyncFromEditBox()
    if not self:IsQtyModalOpen() then return end
    local m = self.qtyModalFrame
    if not m or not m.qtyEditBox then return end
    local ok, txt = pcall(function() return m.qtyEditBox:GetText() end)
    if not ok then return end
    local q = math.floor(tonumber(txt) or (self.qtyModal.qty or 1))
    local mx = tonumber(self.qtyModal.maxQty) or 1
    if q < 1 then q = 1 end
    if q > mx then q = mx end
    self.qtyModal.qty = q
    self:UpdateQtyModalVisuals()
end

function MailScreen:QtyModalDirection(direction)
    if direction == "UP" then
        self:QtyModalAdjust(1)
    elseif direction == "DOWN" then
        self:QtyModalAdjust(-1)
    end
end

-- A no modal: define a quantidade do item na lista (anexa se ainda nao
-- estiver); B cancela sozinho (CloseQtyModal).
function MailScreen:QtyModalConfirm()
    if not self:IsQtyModalOpen() then return end
    if not self.isOpen then
        self:CloseQtyModal(true)
        return
    end
    self:QtyModalSyncFromEditBox()
    local bag = self.qtyModal.bag
    local slot = self.qtyModal.slot
    local qty = tonumber(self.qtyModal.qty) or 1
    local nm = self.qtyModal.itemName or "Item"
    self:CloseQtyModal(true)
    if bag == nil or slot == nil then return end
    local pos, e = self:FindAttached(bag, slot)
    if pos and e then
        e.qty = qty
    else
        local it = self:GetInvItemAt(self.invIndex)
        local tex = nil
        local count = qty
        if it and it.bag == bag and it.slot == slot then
            tex = it.texture
            count = tonumber(it.count) or qty
        end
        table.insert(self.composeItems, {
            bag = bag, slot = slot, name = nm, texture = tex,
            count = count, qty = qty,
        })
    end
    self:AutoFillSubject()
    self:UpdateComposeItemsText()
    self:RefreshComposeVisuals()
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Quantidade: " .. tostring(nm) .. " x" .. qty .. ".")
    end
end

function MailScreen:UpdateQtyModalVisuals()
    local m = self.qtyModalFrame
    if not m then return end
    local qty = tonumber(self.qtyModal.qty) or 1
    local mx = tonumber(self.qtyModal.maxQty) or 1
    if m.nameText then
        m.nameText:SetText("|cffffffff" .. tostring(self.qtyModal.itemName or "Item") .. "|r")
    end
    if m.qtyText then
        m.qtyText:SetText("|cffe09a15x" .. qty .. "|r  |cff888888/ " .. mx .. "|r")
    end
    if m.qtyEditBox then
        local ok, cur = pcall(function() return m.qtyEditBox:GetText() end)
        if ok and tostring(cur or "") ~= tostring(qty) then
            pcall(function() m.qtyEditBox:SetText(tostring(qty)) end)
        end
    end
end

-- ----------------------------------------------------------------------------
-- 2f-M4.2 (IV). MODAL DE DINHEIRO (§4.1: reels por digito, estilo alarme)
-- FULLSCREEN_DIALOG/50: Ouro = 4 digitos, Prata = 2, Cobre = 2 (wrap 0-9).
-- D-Pad LEFT/RIGHT seleciona o digito; UP/DOWN gira (hold 0.35/0.12 via
-- StartRepeat/OnDirection); A confirma (salva copper total em composeMoney +
-- refresh), B cancela sozinho. Validacao saldo (GetMoney) + taxa
-- (GetSendMailPrice) com guarda+pcall. A EditBox do campo segue digitavel
-- (fallback fisico); mouse clica no digito + roda do mouse gira + botoes.
-- ----------------------------------------------------------------------------
-- Dimmer escuro proprio do modal de dinheiro (FULLSCREEN_DIALOG/49, logo
-- abaixo do modal/50): escurece a janela do correio atras sem tocar nos
-- reels/conteudo. Molde do dimmer principal (CreateDimmer), so UI.
function MailScreen:CreateMoneyModalDimmer()
    if self.moneyModalDimmer then return self.moneyModalDimmer end
    local d = CreateFrame("Frame", "ConsoleMode_MailMoneyDimmer", UIParent)
    d:SetAllPoints(UIParent)
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:SetFrameLevel(49)
    d:EnableMouse(true)
    d:Hide()
    local dimTex = d:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints(d)
    dimTex:SetTexture(0.0, 0.0, 0.0, 0.65)
    d.texture = dimTex
    self.moneyModalDimmer = d
    return d
end

function MailScreen:CreateMoneyModalUI()
    if self.moneyModalFrame then return self.moneyModalFrame end
    self:CreateMoneyModalDimmer()
    local m = CreateFrame("Frame", "ConsoleMode_MailMoneyModal", UIParent)
    m:SetWidth(480)
    m:SetHeight(330)
    m:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    m:SetFrameStrata("FULLSCREEN_DIALOG")
    m:SetFrameLevel(50)
    m:EnableMouse(true)
    m:EnableMouseWheel(true)
    m:SetMovable(false)
    m:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    -- Fundo da janela TODA solido (alfa 1.0): sem transparencia residual.
    m:SetBackdropColor(0.08, 0.06, 0.04, 1.0)
    m:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
    m:Hide()

    local title = m:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", m, "TOP", 0, -14)
    self:ApplyFont(title, FONTS.titleBold, 19)
    title:SetText("|cffe09a15Dinheiro|r")
    m.title = title

    -- Fileira de 8 reels: passo 50px (44 larg + 6 gap), +10 apos grupos.
    local row = CreateFrame("Frame", nil, m)
    row:SetWidth(414)
    row:SetHeight(56)
    row:SetPoint("TOP", m, "TOP", 0, -48)
    m.digitRow = row
    m.digitBtns = {}
    m.digitTexts = {}

    local x = 0
    for i = 1, 8 do
        if i == 5 or i == 7 then x = x + 10 end
        local di = i
        local b = CreateFrame("Button", "ConsoleMode_MailMoneyDigit" .. i, row)
        b:SetWidth(44)
        b:SetHeight(56)
        b:SetPoint("LEFT", row, "LEFT", x, 0)
        b:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        b:SetBackdropColor(0.0, 0.0, 0.0, 0.55)
        b:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.60)
        local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        t:SetPoint("CENTER", b, "CENTER", 0, 0)
        MailScreen:ApplyFont(t, FONTS.titleBold, 26)
        t:SetText("0")
        b.digitPos = di
        b:RegisterForClicks("LeftButtonUp")
        b:SetScript("OnClick", function()
            MailScreen.moneyModal.digitIndex = this.digitPos
            MailScreen:UpdateMoneyModalVisuals()
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        end)
        m.digitBtns[di] = b
        m.digitTexts[di] = t
        x = x + 50
    end

    -- Rotulos dos grupos (centros relativos ao centro da fileira de 414px:
    -- ouro 97-207=-110; prata 251-207=44; cobre 355-207=148).
    local goldL = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    goldL:SetPoint("TOP", row, "BOTTOM", -110, -2)
    self:ApplyFont(goldL, FONTS.titleBold, 13)
    goldL:SetText("|cffffd700OURO|r")
    local silverL = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    silverL:SetPoint("TOP", row, "BOTTOM", 44, -2)
    self:ApplyFont(silverL, FONTS.titleBold, 13)
    silverL:SetText("|cffc7c7cfPRATA|r")
    local copperL = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    copperL:SetPoint("TOP", row, "BOTTOM", 148, -2)
    self:ApplyFont(copperL, FONTS.titleBold, 13)
    copperL:SetText("|cffeda55fCOBRE|r")

    local total = m:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    total:SetPoint("TOP", row, "BOTTOM", 0, -24)
    total:SetWidth(440)
    total:SetJustifyH("CENTER")
    self:ApplyFont(total, FONTS.titleBold, 18)
    total:SetText("")
    m.totalText = total

    local balance = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    balance:SetPoint("TOP", total, "BOTTOM", 0, -4)
    balance:SetWidth(440)
    balance:SetJustifyH("CENTER")
    self:ApplyFont(balance, FONTS.bodyBold, 14)
    balance:SetText("")
    m.balanceText = balance

    local hints = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hints:SetPoint("BOTTOM", m, "BOTTOM", 0, 52)
    hints:SetWidth(450)
    hints:SetJustifyH("CENTER")
    self:ApplyFont(hints, FONTS.titleBold, 14)
    hints:SetText("|cffffffff[D-Pad Esq/Dir]|r digito   |cffffffff[Up/Down]|r girar   |cffffffff[A]|r confirmar   |cffffffff[B]|r cancelar")
    m.hints = hints

    local confirmBtn = CreateFrame("Button", "ConsoleMode_MailMoneyConfirmYes", m)
    confirmBtn:SetWidth(150)
    confirmBtn:SetHeight(28)
    confirmBtn:SetPoint("BOTTOMLEFT", m, "BOTTOM", -160, 10)
    confirmBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    confirmBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    confirmBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    local confirmIcon = confirmBtn:CreateTexture(nil, "OVERLAY")
    confirmIcon:SetWidth(22)
    confirmIcon:SetHeight(22)
    confirmIcon:SetPoint("LEFT", confirmBtn, "LEFT", 6, 0)
    confirmIcon:SetTexture(ICONS.A)
    local confirmTxt = confirmBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    confirmTxt:SetPoint("LEFT", confirmIcon, "RIGHT", 5, 0)
    MailScreen:ApplyFont(confirmTxt, FONTS.titleBold, 15)
    confirmTxt:SetText("Confirmar")
    confirmBtn:SetScript("OnClick", function()
        MailScreen:MoneyModalConfirm()
    end)
    confirmBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    confirmBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    m.confirmBtn = confirmBtn

    local cancelBtn = CreateFrame("Button", "ConsoleMode_MailMoneyConfirmNo", m)
    cancelBtn:SetWidth(150)
    cancelBtn:SetHeight(28)
    cancelBtn:SetPoint("BOTTOMRIGHT", m, "BOTTOM", 160, 10)
    cancelBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    cancelBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    cancelBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    local cancelIcon = cancelBtn:CreateTexture(nil, "OVERLAY")
    cancelIcon:SetWidth(22)
    cancelIcon:SetHeight(22)
    cancelIcon:SetPoint("LEFT", cancelBtn, "LEFT", 6, 0)
    cancelIcon:SetTexture(ICONS.B)
    local cancelTxt = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cancelTxt:SetPoint("LEFT", cancelIcon, "RIGHT", 5, 0)
    MailScreen:ApplyFont(cancelTxt, FONTS.titleBold, 15)
    cancelTxt:SetText("Cancelar")
    cancelBtn:SetScript("OnClick", function()
        MailScreen:CloseMoneyModal()
    end)
    cancelBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    cancelBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    m.cancelBtn = cancelBtn

    m:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            MailScreen:MoneyModalSpin(1)
        else
            MailScreen:MoneyModalSpin(-1)
        end
    end)
    m:SetScript("OnHide", function()
        MailScreen.moneyModal.isOpen = false
        if MailScreen.moneyModalDimmer and MailScreen.moneyModalDimmer:IsVisible() then
            MailScreen.moneyModalDimmer:Hide()
        end
    end)
    table.insert(UISpecialFrames, "ConsoleMode_MailMoneyModal")

    self.moneyModalFrame = m
    return m
end

function MailScreen:IsMoneyModalOpen()
    if self.moneyModal and self.moneyModal.isOpen then return true end
    if self.moneyModalFrame and self.moneyModalFrame:IsVisible() then return true end
    return false
end

function MailScreen:IsComposeModalOpen()
    if self:IsVKOpen() then return true end
    if self:IsMoneyModalOpen() then return true end
    if self:IsQtyModalOpen() then return true end
    return false
end

function MailScreen:MoneyModalCopper()
    local d = self.moneyModal.digits or {}
    local function dig(i)
        return tonumber(d[i]) or 0
    end
    local gold = dig(1) * 1000 + dig(2) * 100 + dig(3) * 10 + dig(4)
    local silver = dig(5) * 10 + dig(6)
    local copper = dig(7) * 10 + dig(8)
    return (gold * 100 + silver) * 100 + copper
end

function MailScreen:GetPlayerCopper()
    if GetMoney then
        local ok, v = pcall(GetMoney)
        if ok and tonumber(v) then return tonumber(v) end
    end
    return 0
end

function MailScreen:GetPostageCopper()
    if self.isOpen and GetSendMailPrice then
        local ok, price = pcall(GetSendMailPrice)
        if ok and tonumber(price) and tonumber(price) > 0 then
            return tonumber(price)
        end
    end
    return 30
end

function MailScreen:OpenMoneyModal()
    if not self.isOpen then return end
    if self.currentScreen ~= "COMPOSE" then return end
    if self:IsVKOpen() then return end
    if self:IsQtyModalOpen() then return end
    if self.sendQueue and self.sendQueue.running then return end
    self:SyncComposeBuffersFromUI()
    local copper = math.floor(tonumber(self.composeMoney) or 0)
    if copper < 0 then copper = 0 end
    local gold = math.floor(copper / 10000)
    local rem = copper - gold * 10000
    local silver = math.floor(rem / 100)
    local co = rem - silver * 100
    if gold > 9999 then gold = 9999 end
    self.moneyModal.digits = {
        math.floor(gold / 1000),
        math.floor(math.mod(gold, 1000) / 100),
        math.floor(math.mod(gold, 100) / 10),
        math.mod(gold, 10),
        math.floor(silver / 10),
        math.mod(silver, 10),
        math.floor(co / 10),
        math.mod(co, 10),
    }
    self.moneyModal.digitIndex = 1
    self.moneyModal.isOpen = true
    self:CreateMoneyModalUI()
    self:UpdateMoneyModalVisuals()
    if self.moneyModalDimmer then
        self.moneyModalDimmer:Show()
    end
    self.moneyModalFrame:Show()
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
end

function MailScreen:CloseMoneyModal(silent)
    self.moneyModal.isOpen = false
    if self.moneyModalDimmer and self.moneyModalDimmer:IsVisible() then
        self.moneyModalDimmer:Hide()
    end
    if self.moneyModalFrame and self.moneyModalFrame:IsVisible() then
        self.moneyModalFrame:Hide()
    end
    if not silent then
        if PlaySound then PlaySound("igMainMenuClose") end
    end
end

-- Gira o digito ativo com wrap circular 0-9 (§4.1).
function MailScreen:MoneyModalSpin(delta)
    if not self:IsMoneyModalOpen() then return end
    delta = tonumber(delta) or 0
    local idx = tonumber(self.moneyModal.digitIndex) or 1
    if idx < 1 then idx = 1 end
    if idx > 8 then idx = 8 end
    local d = self.moneyModal.digits or {}
    local cur = tonumber(d[idx]) or 0
    cur = math.mod(cur + delta, 10)
    d[idx] = cur
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:UpdateMoneyModalVisuals()
end

function MailScreen:MoneyModalDirection(direction)
    if direction == "LEFT" then
        local idx = (tonumber(self.moneyModal.digitIndex) or 1) - 1
        if idx < 1 then idx = 1 end
        if idx ~= self.moneyModal.digitIndex then
            self.moneyModal.digitIndex = idx
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
            self:UpdateMoneyModalVisuals()
        end
    elseif direction == "RIGHT" then
        local idx = (tonumber(self.moneyModal.digitIndex) or 1) + 1
        if idx > 8 then idx = 8 end
        if idx ~= self.moneyModal.digitIndex then
            self.moneyModal.digitIndex = idx
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
            self:UpdateMoneyModalVisuals()
        end
    elseif direction == "UP" then
        self:MoneyModalSpin(1)
    elseif direction == "DOWN" then
        self:MoneyModalSpin(-1)
    end
end

-- A no modal: valida saldo + taxa e salva o copper total em composeMoney.
function MailScreen:MoneyModalConfirm()
    if not self:IsMoneyModalOpen() then return end
    if not self.isOpen then
        self:CloseMoneyModal(true)
        return
    end
    local total = self:MoneyModalCopper()
    local balance = self:GetPlayerCopper()
    if total > balance then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Dinheiro acima do saldo (" .. self:FormatMoneyText(balance) .. ").")
        end
        if PlaySound then PlaySound("igQuestFailed") end
        return
    end
    self.composeMoney = tostring(total)
    local eb = self:GetComposeEditBox(4)
    if eb then
        pcall(function() eb:SetText(tostring(total)) end)
    end
    self:AutoFillSubjectForMoney()
    self:CloseMoneyModal(true)
    self:RefreshComposeVisuals()
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Dinheiro anexado: " .. self:FormatMoneyText(total) .. ".")
    end
end

function MailScreen:UpdateMoneyModalVisuals()
    local m = self.moneyModalFrame
    if not m then return end
    local d = self.moneyModal.digits or {}
    local active = tonumber(self.moneyModal.digitIndex) or 1
    for i = 1, 8 do
        local b = m.digitBtns and m.digitBtns[i]
        local t = m.digitTexts and m.digitTexts[i]
        if b and t then
            t:SetText(tostring(tonumber(d[i]) or 0))
            if i == active then
                b:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                b:SetBackdropColor(0.28, 0.20, 0.08, 0.95)
            else
                b:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.60)
                b:SetBackdropColor(0.0, 0.0, 0.0, 0.55)
            end
        end
    end
    local total = self:MoneyModalCopper()
    if m.totalText then
        m.totalText:SetText("|cffaaaaaaTotal:|r " .. self:FormatMoneyText(total))
    end
    if m.balanceText then
        local balance = self:GetPlayerCopper()
        local postage = self:GetPostageCopper()
        local line = "|cffaaaaaaSaldo:|r " .. self:FormatMoneyText(balance) .. "  |cffaaaaaaPostagem:|r " .. self:FormatMoneyText(postage)
        if total > balance then
            line = line .. "  |cffff2020(saldo insuficiente)|r"
        end
        m.balanceText:SetText(line)
    end
end

-- ----------------------------------------------------------------------------
-- 2f-M4.2 (V). ENVIO + FILA MULTI-ITEM (§7 M4)
-- ENVIAR valida (destinatario nao vazio; saldo >= N x postagem + dinheiro
-- anexado) e envia 1 carta por item (limite 1.12), copiando assunto+texto; o
-- dinheiro vai so na 1a carta. Anexacao fisica (PickupContainerItem ou
-- SplitContainerItem p/ pilha parcial + ClickSendMailItemButton) e
-- SetSendMailMoney acontecem SO no momento do envio, com isOpen (regra de
-- ouro). Fila serializada por MAIL_SEND_SUCCESS; aborta em MAIL_CLOSED.
-- Pos-envio limpa TODOS os campos/itens e permanece no compor.
-- ----------------------------------------------------------------------------
function MailScreen:TrySendMail()
    if not self.isOpen then return end
    if self.currentScreen ~= "COMPOSE" then return end
    if self:IsComposeModalOpen() then return end
    if self:IsConfirmOpen() then return end
    local st = self.sendQueue
    if st.running then return end
    if self.takeAllQueue and self.takeAllQueue.running then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Aguarde a retirada terminar para enviar.")
        end
        return
    end
    if not SendMail then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Envio indisponivel (API SendMail ausente).")
        end
        return
    end
    self:SyncComposeBuffersFromUI()
    local to = self:TrimText(self.composeTo or "")
    if to == "" then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Informe o destinatario (campo Para).")
        end
        if PlaySound then PlaySound("igQuestFailed") end
        return
    end
    -- Caminho do teclado fisico/ENVIAR tambem persiste o destinatario na SV
    -- (o VK ja persiste no OnVKConfirm; dedup move-para-frente evita dobra).
    self:PushMailHistory(to)
    local subject = tostring(self.composeSubject or "")
    local body = tostring(self.composeBody or "")
    local money = math.floor(tonumber(self.composeMoney) or 0)
    if money < 0 then money = 0 end
    local items = self.composeItems or {}
    local numItems = table.getn(items)
    if numItems == 0 and money > 0 and self:TrimText(subject) == "" then
        subject = "gold"
        self.composeSubject = "gold"
        local eb2 = self:GetComposeEditBox(2)
        if eb2 then
            pcall(function() eb2:SetText("gold") end)
        end
    end
    if numItems == 0 and money == 0 and self:TrimText(subject) == "" and self:TrimText(body) == "" then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Nada a enviar (carta vazia).")
        end
        if PlaySound then PlaySound("igQuestFailed") end
        return
    end
    local postage = self:GetPostageCopper()
    local total = numItems
    if total < 1 then total = 1 end
    local balance = self:GetPlayerCopper()
    local needed = total * postage + money
    if balance < needed then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Saldo insuficiente: precisa de " .. self:FormatMoneyText(needed) .. " (" .. total .. "x postagem + dinheiro).")
        end
        if PlaySound then PlaySound("igQuestFailed") end
        return
    end
    local letters = {}
    if numItems == 0 then
        table.insert(letters, { money = money })
    else
        for i = 1, numItems do
            local e = items[i]
            local lm = 0
            if i == 1 then lm = money end
            table.insert(letters, {
                bag = e.bag, slot = e.slot,
                qty = tonumber(e.qty) or 1,
                name = e.name or "Item",
                money = lm,
            })
        end
    end
    st.running = true
    st.letters = letters
    st.pos = 1
    st.total = table.getn(letters)
    st.to = to
    st.subject = subject
    st.body = body
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Enviando 1 de " .. st.total .. "...")
    end
    self:ProcessSendStep()
end

-- Envia a carta da posicao atual (anexo fisico + dinheiro + SendMail).
function MailScreen:ProcessSendStep()
    local st = self.sendQueue
    if not st.running then return end
    if not self.isOpen then
        self:StopSendQueue(false)
        return
    end
    local pos = tonumber(st.pos) or 1
    local letter = st.letters[pos]
    if not letter then
        self:FinishSendQueue()
        return
    end
    -- 1. Anexo fisico (so agora o item sai da bolsa).
    if letter.bag ~= nil and letter.slot ~= nil then
        local qty = tonumber(letter.qty) or 1
        if qty < 1 then qty = 1 end
        if qty > 1 and SplitContainerItem then
            pcall(SplitContainerItem, letter.bag, letter.slot, qty)
        elseif PickupContainerItem then
            pcall(PickupContainerItem, letter.bag, letter.slot)
        end
        if ClickSendMailItemButton then
            pcall(ClickSendMailItemButton)
        end
    end
    -- 2. Dinheiro (so na 1a carta; zera nas demais).
    if SetSendMailMoney then
        pcall(SetSendMailMoney, tonumber(letter.money) or 0)
    end
    -- 3. Envio (assunto+texto copiados em todas as cartas).
    pcall(SendMail, st.to, st.subject, st.body)
end

-- Avanca UMA carta por MAIL_SEND_SUCCESS (nunca presume estado; re-age se a
-- mailbox fechar via OnMailClosed -> StopSendQueue).
function MailScreen:AdvanceSendQueue()
    local st = self.sendQueue
    if not st or not st.running then return end
    if not self.isOpen then
        self:StopSendQueue(false)
        return
    end
    st.pos = (tonumber(st.pos) or 1) + 1
    if st.pos > (tonumber(st.total) or 0) then
        self:FinishSendQueue()
        return
    end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Enviando " .. st.pos .. " de " .. st.total .. "...")
    end
    self:ProcessSendStep()
end

function MailScreen:StopSendQueue(announce)
    local st = self.sendQueue
    if not st then return end
    local was = st.running
    st.running = false
    st.letters = {}
    st.pos = 1
    st.total = 0
    if announce and was then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Envio concluido.")
        end
    end
end

function MailScreen:FinishSendQueue()
    self:StopSendQueue(false)
    self:ClearComposeAfterSend()
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Carta enviada.")
    end
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
end

-- Pos-envio: limpa TODOS os campos/itens e permanece no compor.
function MailScreen:ClearComposeAfterSend()
    self.composeTo = ""
    self.composeSubject = ""
    self.composeBody = ""
    self.composeMoney = ""
    self.composeItems = {}
    local box = self.frame and self.frame.leftCol and self.frame.leftCol.composeBox
    if box and box.rows then
        local n = table.getn(box.rows)
        for i = 1, n do
            local r = box.rows[i]
            if r and r.editBox then
                pcall(function() r.editBox:SetText("") end)
            end
        end
    end
    self:ClearComposeFocus()
    self:UpdateComposeItemsText()
    self:UpdateComposePostage()
    self:ScanComposeBags()
    self:RefreshComposeVisuals()
end

-- ----------------------------------------------------------------------------
-- 2f. M3: FILEIRA DE BOTOES-TEXTURA DO DETALHE (molde botao Sair: backdrop
-- + icone + hover ouro; nunca texto puro como botao). A entra no detalhe
-- (foco em RETIRAR); D-Pad <-/-> percorre os 3 com clamp (para sem vizinho);
-- B volta p/ lista (pilha em OnCancel/CloseTopFrame). Mouse clica direto.
-- ----------------------------------------------------------------------------
local MAIL_DETAIL_BUTTONS = {
    { key = "RETIRAR",  label = "RETIRAR",  icon = "Interface\\MoneyFrame\\UI-GoldIcon", action = "take" },
    { key = "DEVOLVER", label = "DEVOLVER", icon = "Interface\\Icons\\INV_Misc_Note_01", action = "return" },
    { key = "APAGAR",   label = "APAGAR",   icon = nil, action = "delete" },
}

function MailScreen:CreateMailActionBar(parent, anchorTop)
    if self.actionBar then return self.actionBar end

    -- M4.1: action bar na faixa inferior da coluna (abaixo do card full-height,
    -- que reserva 40px na base); mesma fileira RETIRAR|DEVOLVER|APAGAR da M3.
    local bar = CreateFrame("Frame", "ConsoleMode_MailActionBar", parent)
    bar:SetHeight(34)
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 2)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 2)

    bar.buttons = {}
    local numDefs = table.getn(MAIL_DETAIL_BUTTONS)
    for i = 1, numDefs do
        local def = MAIL_DETAIL_BUTTONS[i]
        local b = CreateFrame("Button", "ConsoleMode_MailActionBtn" .. def.key, bar)
        b:SetWidth(118)
        b:SetHeight(30)
        b:SetPoint("CENTER", bar, "CENTER", (i - 2) * 122, 0)
        b:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        b:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
        b:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

        local iconPath = def.icon or ICONS.X
        local bIcon = b:CreateTexture(nil, "OVERLAY")
        bIcon:SetWidth(22)
        bIcon:SetHeight(22)
        bIcon:SetPoint("LEFT", b, "LEFT", 6, 0)
        bIcon:SetTexture(iconPath)

        local bTxt = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bTxt:SetPoint("LEFT", bIcon, "RIGHT", 5, 0)
        MailScreen:ApplyFont(bTxt, FONTS.titleBold, 14)
        bTxt:SetText(def.label)

        b.actionIndex = i
        b.actionKey = def.action
        b:RegisterForClicks("LeftButtonUp")
        b:SetScript("OnClick", function()
            MailScreen.activeColumn = "DETAIL"
            MailScreen.detailButtonIndex = this.actionIndex
            MailScreen:UpdateColumnVisuals()
            MailScreen:UpdateActionButtonsVisuals()
            MailScreen:DoDetailAction(this.actionIndex)
        end)
        b:SetScript("OnEnter", function()
            this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
            this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
        end)
        b:SetScript("OnLeave", function()
            MailScreen:UpdateActionButtonsVisuals()
        end)

        table.insert(bar.buttons, b)
    end

    self.actionBar = bar
    self:UpdateActionButtonsVisuals()
    return bar
end

function MailScreen:UpdateActionButtonsVisuals()
    local bar = self.actionBar
    if not bar or not bar.buttons then return end
    local n = table.getn(bar.buttons)
    for i = 1, n do
        local b = bar.buttons[i]
        if self.activeColumn == "DETAIL" and (self.detailButtonIndex or 1) == i then
            b:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
            b:SetBackdropColor(0.28, 0.20, 0.08, 0.95)
        else
            b:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
            b:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
        end
    end
end

function MailScreen:EnterDetail()
    if not self.isOpen then return end
    if self:IsConfirmOpen() then return end
    local n = table.getn(self.filteredInbox or {})
    if n == 0 then return end
    self.activeColumn = "DETAIL"
    self.detailButtonIndex = 1
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:UpdateColumnVisuals()
    self:RefreshInboxList()
end

function MailScreen:BackToList()
    if not self.isOpen then return end
    self.activeColumn = "INBOX"
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:UpdateColumnVisuals()
    self:RefreshInboxList()
end

function MailScreen:MoveDetailButton(delta)
    if not self.isOpen then return end
    local idx = (self.detailButtonIndex or 1) + (tonumber(delta) or 0)
    if idx < 1 then idx = 1 end
    if idx > 3 then idx = 3 end
    if idx ~= self.detailButtonIndex then
        self.detailButtonIndex = idx
        if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        self:UpdateActionButtonsVisuals()
    end
end

function MailScreen:DoDetailAction(idx)
    if not self.isOpen then return end
    idx = tonumber(idx) or 1
    if idx == 1 then
        self:TakeSelectedMail()
    elseif idx == 2 then
        self:ReturnSelectedMail()
    elseif idx == 3 then
        self:DeleteSelectedMail()
    end
end

function MailScreen:GetSelectedMail()
    local filtered = self.filteredInbox or {}
    local idx = tonumber(self.selectedInboxIndex) or 1
    if idx < 1 then idx = 1 end
    if idx > table.getn(filtered) then return nil end
    return filtered[idx]
end

-- ----------------------------------------------------------------------------
-- 2g. M3: ACOES SERVIDORAS DO INBOX (ANTI-BLOQUEIO: SOMENTE com isOpen true,
-- entre MAIL_SHOW e MAIL_CLOSED; nunca CloseMail; nunca Hide no nativo).
-- Apos cada acao, re-scan via MAIL_INBOX_UPDATE (RequestInboxRefresh dispara
-- CheckInbox; o servidor confirma e OnInboxUpdate faz o ScanInbox real).
-- ----------------------------------------------------------------------------
function MailScreen:TakeFromIndex(inboxIndex, tag)
    if not self.isOpen then return end
    inboxIndex = tonumber(inboxIndex) or 0
    if inboxIndex < 1 then return end
    if not GetInboxHeaderInfo then return end
    local ok, packageIcon, stationeryIcon, sender, subject, money,
        codAmount, daysLeft, hasItem = pcall(GetInboxHeaderInfo, inboxIndex)
    if not ok or not sender then return end
    money = tonumber(money) or 0
    local tookMoney = false
    local tookItem = false
    if money > 0 and TakeInboxMoney then
        pcall(TakeInboxMoney, inboxIndex)
        tookMoney = true
    end
    if hasItem and TakeInboxItem then
        pcall(TakeInboxItem, inboxIndex)
        tookItem = true
    end
    local parts = {}
    if tookMoney then table.insert(parts, self:FormatMoneyText(money)) end
    if tookItem then table.insert(parts, "anexo") end
    local what = table.concat(parts, " + ")
    if what == "" then what = "nada a retirar" end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] " .. tostring(tag or "Retirado") .. " de " .. tostring(sender) .. ": " .. what .. ".")
    end
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
end

function MailScreen:TakeSelectedMail()
    if not self.isOpen then return end
    if self:IsConfirmOpen() then return end
    local item = self:GetSelectedMail()
    if not item then return end
    self:TakeFromIndex(item.index, "Retirado")
    self:RequestInboxRefresh()
end

function MailScreen:ReturnSelectedMail()
    if not self.isOpen then return end
    if self:IsConfirmOpen() then return end
    local item = self:GetSelectedMail()
    if not item then return end
    if ReturnInboxItem then
        pcall(ReturnInboxItem, item.index)
    end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Carta devolvida a " .. tostring(item.sender or "?") .. ".")
    end
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:RequestInboxRefresh()
end

function MailScreen:DeleteSelectedMail()
    if not self.isOpen then return end
    if self:IsConfirmOpen() then return end
    local item = self:GetSelectedMail()
    if not item then return end
    local money = tonumber(item.money) or 0
    if money > 0 or item.hasItem then
        self:OpenDeleteConfirm(item.index)
        return
    end
    self:DeleteIndex(item.index)
end

function MailScreen:DeleteIndex(inboxIndex)
    if not self.isOpen then return end
    inboxIndex = tonumber(inboxIndex) or 0
    if inboxIndex < 1 then return end
    if DeleteInboxItem then
        pcall(DeleteInboxItem, inboxIndex)
    end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Carta apagada.")
    end
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:RequestInboxRefresh()
end

-- ----------------------------------------------------------------------------
-- 2h. M3: MODAL DE CONFIRMACAO DE APAGAR (molde MerchantMenu qty modal:
-- FULLSCREEN_DIALOG/50, titulo + texto + A confirma / B cancela + botoes
-- clicaveis p/ mouse). Abre quando a carta tem dinheiro/anexo nao retirado.
-- ----------------------------------------------------------------------------
function MailScreen:CreateDeleteConfirmUI()
    if self.deleteConfirmFrame then return self.deleteConfirmFrame end
    local m = CreateFrame("Frame", "ConsoleMode_MailDeleteConfirm", UIParent)
    m:SetWidth(440)
    m:SetHeight(240)
    m:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    m:SetFrameStrata("FULLSCREEN_DIALOG")
    m:SetFrameLevel(50)
    m:EnableMouse(true)
    m:SetMovable(false)
    m:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    m:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
    m:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
    m:Hide()

    local title = m:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", m, "TOP", 0, -14)
    self:ApplyFont(title, FONTS.titleBold, 19)
    title:SetText("|cffe09a15Apagar carta?|r")
    m.title = title

    local info = m:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOP", title, "BOTTOM", 0, -8)
    info:SetWidth(400)
    info:SetJustifyH("CENTER")
    self:ApplyFont(info, FONTS.titleBold, 15)
    info:SetText("")
    m.infoText = info

    local warn = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warn:SetPoint("TOP", info, "BOTTOM", 0, -8)
    warn:SetWidth(400)
    warn:SetJustifyH("CENTER")
    self:ApplyFont(warn, FONTS.bodyBold, 14)
    warn:SetText("|cffff2020A carta ainda tem dinheiro ou anexo nao retirado.|r")
    m.warnText = warn

    local hints = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hints:SetPoint("BOTTOM", m, "BOTTOM", 0, 44)
    hints:SetWidth(400)
    hints:SetJustifyH("CENTER")
    self:ApplyFont(hints, FONTS.titleBold, 14)
    hints:SetText("|cffffffff[A]|r |cff1eff00confirmar|r   |cffffffff[B]|r |cffff2020cancelar|r")
    m.hints = hints

    local confirmBtn = CreateFrame("Button", "ConsoleMode_MailDeleteConfirmYes", m)
    confirmBtn:SetWidth(150)
    confirmBtn:SetHeight(28)
    confirmBtn:SetPoint("BOTTOMLEFT", m, "BOTTOM", -160, 10)
    confirmBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    confirmBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    confirmBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    local confirmTxt = confirmBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    confirmTxt:SetPoint("CENTER", confirmBtn, "CENTER", 0, 0)
    MailScreen:ApplyFont(confirmTxt, FONTS.titleBold, 15)
    confirmTxt:SetText("Apagar")
    confirmBtn:SetScript("OnClick", function()
        MailScreen:ConfirmDelete()
    end)
    confirmBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
    end)
    confirmBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)
    m.confirmBtn = confirmBtn

    local cancelBtn = CreateFrame("Button", "ConsoleMode_MailDeleteConfirmNo", m)
    cancelBtn:SetWidth(150)
    cancelBtn:SetHeight(28)
    cancelBtn:SetPoint("BOTTOMRIGHT", m, "BOTTOM", 160, 10)
    cancelBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    cancelBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    cancelBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    local cancelTxt = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cancelTxt:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
    MailScreen:ApplyFont(cancelTxt, FONTS.titleBold, 15)
    cancelTxt:SetText("Cancelar")
    cancelBtn:SetScript("OnClick", function()
        MailScreen:CloseDeleteConfirm()
    end)
    cancelBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
    end)
    cancelBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)
    m.cancelBtn = cancelBtn

    self.deleteConfirmFrame = m
    return m
end

function MailScreen:IsConfirmOpen()
    if self.deleteConfirm and self.deleteConfirm.isOpen then return true end
    if self.deleteConfirmFrame and self.deleteConfirmFrame:IsVisible() then return true end
    return false
end

function MailScreen:OpenDeleteConfirm(inboxIndex)
    if not self.isOpen then return end
    inboxIndex = tonumber(inboxIndex) or 0
    if inboxIndex < 1 then return end
    local m = self:CreateDeleteConfirmUI()
    local label = "Carta " .. inboxIndex
    if GetInboxHeaderInfo then
        local ok, packageIcon, stationeryIcon, sender, subject, money,
            codAmount, daysLeft, hasItem = pcall(GetInboxHeaderInfo, inboxIndex)
        if ok and sender then
            local subj = subject
            if not subj or subj == "" then subj = "(sem assunto)" end
            label = "|cffffffff" .. self:TruncateText(subj, 30) .. "|r|cffaaaaaa de " .. self:TruncateText(tostring(sender), 22) .. "|r"
        end
    end
    m.infoText:SetText(label)
    self.deleteConfirm.isOpen = true
    self.deleteConfirm.pendingIndex = inboxIndex
    m:Show()
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Confirmar APAGAR: carta com valores nao retirados.")
    end
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
end

function MailScreen:CloseDeleteConfirm()
    self.deleteConfirm.isOpen = false
    self.deleteConfirm.pendingIndex = nil
    if self.deleteConfirmFrame and self.deleteConfirmFrame:IsVisible() then
        self.deleteConfirmFrame:Hide()
    end
    if PlaySound then PlaySound("igMainMenuClose") end
end

function MailScreen:ConfirmDelete()
    if not self:IsConfirmOpen() then return end
    local idx = tonumber(self.deleteConfirm.pendingIndex) or 0
    self:CloseDeleteConfirm()
    if idx >= 1 then
        self:DeleteIndex(idx)
    end
end

-- ----------------------------------------------------------------------------
-- 2i. M3: FILA SERIALIZADA RETIRAR-TUDO (Y na inbox, sem modal/VK aberto).
-- Processa UMA carta por vez, avancando a cada MAIL_INBOX_UPDATE (e
-- MAIL_SEND_SUCCESS); re-scan pelo evento, nunca presume estado. Aborta com
-- seguranca se a mailbox fechar (MAIL_CLOSED limpa a fila).
-- ----------------------------------------------------------------------------
function MailScreen:TakeAllInbox()
    if not self.isOpen then return end
    if self.currentScreen ~= "INBOX" then return end
    if self:IsConfirmOpen() then return end
    -- M4.2: Y no compor nunca e TakeAll (OnComposeUse abre quantidade); na
    -- inbox, nao compete com fila de envio rodando.
    if self.sendQueue and self.sendQueue.running then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Aguarde o envio terminar para retirar tudo.")
        end
        return
    end
    local st = self.takeAllQueue
    if st.running then return end
    local raw = self.inboxItems or {}
    local q = {}
    local n = table.getn(raw)
    for i = 1, n do
        local it = raw[i]
        if it and ((tonumber(it.money) or 0) > 0 or it.hasItem) then
            table.insert(q, it.index)
        end
    end
    if table.getn(q) == 0 then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Nada a retirar: nenhuma carta com dinheiro ou anexo.")
        end
        return
    end
    st.running = true
    st.queue = q
    st.pos = 1
    st.total = table.getn(q)
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Retirando tudo: " .. st.total .. " carta(s)...")
    end
    self:ProcessTakeAllStep()
end

function MailScreen:ProcessTakeAllStep()
    local st = self.takeAllQueue
    if not st.running then return end
    if not self.isOpen then
        self:StopTakeAll(false)
        return
    end
    local total = table.getn(st.queue or {})
    local pos = tonumber(st.pos) or 1
    if pos > total then
        self:StopTakeAll(true)
        return
    end
    local idx = st.queue[pos]
    st.pos = pos + 1
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Retirando " .. pos .. " de " .. total .. "...")
    end
    self:TakeFromIndex(idx, "Retirado")
    self:RequestInboxRefresh()
end

function MailScreen:AdvanceTakeAll()
    local st = self.takeAllQueue
    if not st then return end
    if not st.running then return end
    if not self.isOpen then
        self:StopTakeAll(false)
        return
    end
    self:ProcessTakeAllStep()
end

function MailScreen:StopTakeAll(announce)
    local st = self.takeAllQueue
    if not st then return end
    local was = st.running
    st.running = false
    st.queue = {}
    st.pos = 1
    st.total = 0
    if announce and was then
        if CM.logger and CM.logger.Log then
            CM.logger:Log("[MailScreen] Retirada concluida.")
        end
        if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    end
end

-- ----------------------------------------------------------------------------
-- 2j. M3: PILHA DE B (§3.2: modal aberto -> B fecha so o modal; detalhe
-- focado -> B volta p/ lista; senao -> fecha MAIL). Roteada por Keybindings
-- (CM_CursorCancel) e Hooks:CloseTopFrame, com guards nil nos chamadores.
-- ----------------------------------------------------------------------------
function MailScreen:OnCancel()
    if not self.isOpen then return end
    -- M4.2: B fecha so o topo da pilha (VK/modal -> detalhe -> fecha). O VK e
    -- fechado pelo Keybindings/Hooks antes de chegar aqui; guardas por seguranca.
    if self:IsVKOpen() then return end
    if self:IsQtyModalOpen() then
        self:CloseQtyModal()
        return
    end
    if self:IsMoneyModalOpen() then
        self:CloseMoneyModal()
        return
    end
    if self:IsConfirmOpen() then
        self:CloseDeleteConfirm()
        return
    end
    -- M4.1: B nunca troca de tela; no compor sem modal/detalhe, B fecha o MAIL.
    if self.currentScreen == "COMPOSE" then
        self:Close()
        return
    end
    if self.activeColumn == "DETAIL" then
        self:BackToList()
        return
    end
    self:Close()
end

-- M4.1: D-Pad espacial (§3.2). Inbox: move o foco na direcao; <-/-> atravessa
-- lista<->detalhe (filtros seguem em LT/RT); borda sem vizinho = parado; sem
-- wrap. Compor: roteado p/ OnComposeDirection (telas sao exclusivas).
function MailScreen:OnDirection(direction)
    if not self.isOpen then return end
    -- M4.2: com modal de dinheiro/quantidade aberto, o D-Pad pertence a ele
    -- (UP/DOWN com hold via StartRepeat; no VK, o Keybindings desvia antes).
    if self:IsMoneyModalOpen() then
        self:MoneyModalDirection(direction)
        return
    end
    if self:IsQtyModalOpen() then
        self:QtyModalDirection(direction)
        return
    end
    if self:IsVKOpen() then return end
    if self:IsConfirmOpen() then return end
    if self.currentScreen == "COMPOSE" then
        self:OnComposeDirection(direction)
        return
    end
    if self.activeColumn == "DETAIL" then
        if direction == "LEFT" then
            if (self.detailButtonIndex or 1) > 1 then
                self:MoveDetailButton(-1)
            else
                self:BackToList()
            end
        elseif direction == "RIGHT" then
            self:MoveDetailButton(1)
        end
        return
    end
    if direction == "LEFT" then
        return
    elseif direction == "RIGHT" then
        self:EnterDetail()
    elseif direction == "UP" then
        self:MoveInboxSelection(-1)
    elseif direction == "DOWN" then
        self:MoveInboxSelection(1)
    end
end

-- A (M3 mantido + M4.1): modal aberto = confirma APAGAR; compor = acao
-- estrutural (so log); detalhe focado = ativa o botao em foco; lista = entra.
function MailScreen:OnConfirm()
    if not self.isOpen then return end
    if self:IsConfirmOpen() then
        self:ConfirmDelete()
        return
    end
    if self.currentScreen == "COMPOSE" then
        self:OnComposeConfirm()
        return
    end
    if self.activeColumn == "DETAIL" then
        self:DoDetailAction(self.detailButtonIndex or 1)
        return
    end
    self:EnterDetail()
end

-- Hold-to-repeat do D-Pad (molde MerchantMenu: so UP/DOWN repete).
function MailScreen:StartRepeat(direction)
    if not self.isOpen then return end
    if direction == "UP" or direction == "DOWN" then
        self:OnDirection(direction)
        self.repeatState.direction = direction
        self.repeatState.timer = self.repeatState.initialDelay
        self:EnsureRepeatTicker()
    else
        self.repeatState.direction = nil
        self.repeatState.timer = 0
        self:OnDirection(direction)
    end
end

function MailScreen:StopRepeat(direction)
    if not direction or self.repeatState.direction == direction then
        self.repeatState.direction = nil
        self.repeatState.timer = 0
    end
end

function MailScreen:EnsureRepeatTicker()
    if self.repeatFrame then return end
    local f = CreateFrame("Frame", "ConsoleMode_MailRepeatTicker")
    f:SetScript("OnUpdate", function()
        if not MailScreen.isOpen then
            MailScreen.repeatState.direction = nil
            return
        end
        local dir = MailScreen.repeatState.direction
        if dir then
            local elapsed = arg1 or 0.016
            MailScreen.repeatState.timer = MailScreen.repeatState.timer - elapsed
            if MailScreen.repeatState.timer <= 0 then
                MailScreen:OnDirection(dir)
                MailScreen.repeatState.timer = MailScreen.repeatState.interval
            end
        end
    end)
    self.repeatFrame = f
end

-- ----------------------------------------------------------------------------
-- 2b. ATUALIZACAO DE LAYOUT (M1 — molde MerchantMenu:1617-1640)
-- ----------------------------------------------------------------------------
function MailScreen:UpdateLayout()
    if not self.frame then return end

    local screenW = (UIParent and UIParent:GetWidth()) or 1024
    local screenH = (UIParent and UIParent:GetHeight()) or 768

    local w = math.floor(screenW * 0.94)
    local h = math.floor(screenH * 0.85)

    if w < 840 then w = 840 end
    if h < 520 then h = 520 end
    if w > 1440 then w = 1440 end
    if h > 920 then h = 920 end

    self.frame:SetWidth(w)
    self.frame:SetHeight(h)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    if self.frame.footerContainer then
        self.frame.footerContainer:ClearAllPoints()
        self.frame.footerContainer:SetPoint("CENTER", self.frame, "BOTTOM", 0, 18)
    end
    -- M4.1: os dois sets de footer sao centralizados; o visivel e alternado
    -- por ShowInboxScreen/ShowComposeScreen (UpdateFooterVisibility).
    if self.frame.inboxFooter then
        self.frame.inboxFooter:ClearAllPoints()
        self.frame.inboxFooter:SetPoint("CENTER", self.frame, "BOTTOM", 0, 18)
    end
    if self.frame.composeFooter then
        self.frame.composeFooter:ClearAllPoints()
        self.frame.composeFooter:SetPoint("CENTER", self.frame, "BOTTOM", 0, 18)
    end
end

-- ----------------------------------------------------------------------------
-- 3. ABERTURA / FECHAMENTO (M1 — reais, molde MerchantMenu:2830-2930)
-- ANTI-BLOQUEIO: so UI (Show/Hide); nenhuma API servidora de mail aqui
-- (nada de Take/Delete/Return/SendMail/CloseMail; nunca Hide no nativo).
-- ----------------------------------------------------------------------------
function MailScreen:Open()
    -- Idempotente via self.frame (CreateUI retorna de imediato se ja existe).
    self:CreateUI()
    self:UpdateLayout()

    if self.dimmer then
        self.dimmer:Show()
    end
    if self.frame then
        self.frame:Show()
    end
    self.isOpen = true

    -- M2/M4.1: sincroniza o visual com os dados em cache (o rescan assincrono
    -- chega via OnInboxUpdate e atualiza de novo). Sempre abre na INBOX.
    self:ShowInboxScreen()

    -- Ativa e reforca o Modo de Navegacao no Gamepad (guards nil).
    if CM and CM.keybindings then
        if not CM.keybindings.navigationMode then
            if CM.keybindings.EnterNavigationMode then
                CM.keybindings:EnterNavigationMode()
            end
        else
            if CM.keybindings.ReapplyNavigationBindings then
                CM.keybindings:ReapplyNavigationBindings()
            end
        end
    end

    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Janela aberta.")
    end
end

function MailScreen:Close()
    if not self.isOpen then return end
    self.isOpen = false

    -- M3: aborta a fila Retirar-Tudo e fecha o modal sem confirmar.
    self:StopTakeAll(false)
    -- M4.2: aborta a fila de envio e fecha os modais do compor.
    self:StopSendQueue(false)
    self:CloseMoneyModal(true)
    self:CloseQtyModal(true)
    if self.deleteConfirm then
        self.deleteConfirm.isOpen = false
        self.deleteConfirm.pendingIndex = nil
    end
    if self.deleteConfirmFrame and self.deleteConfirmFrame:IsVisible() then
        self.deleteConfirmFrame:Hide()
    end

    if self.dimmer and self.dimmer:IsVisible() then
        self.dimmer:Hide()
    end

    if self.frame and self.frame:IsVisible() then
        self.frame:Hide()
    end

    -- Desativa o Modo de Navegacao no Gamepad de forma forcada (guards nil).
    if CM and CM.keybindings and CM.keybindings.ExitNavigationMode then
        CM.keybindings:ExitNavigationMode(true)
    end

    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Janela fechada.")
    end
    -- ANTI-BLOQUEIO: nunca encerrar a sessao do NPC pelo addon (sem CloseMail).
end

-- ----------------------------------------------------------------------------
-- 4. MANIPULADORES DE EVENTOS (Passo 2 — só flags + logs, sem API servidora)
-- ----------------------------------------------------------------------------
function MailScreen:OnMailShow()
    if not self.initialized then return end
    self.isOpen = true
    -- M3: sessao nova, fila antiga nenhuma (defensivo; MAIL_CLOSED ja limpa).
    self:StopTakeAll(false)
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Mailbox aberta.")
    end
    -- Passo 3: suprime o MailFrame nativo (visual, off-screen, sem Hide).
    self:SuppressDefaultFrame()
    -- Passo 4: com a mailbox aberta o contexto e seguro; dispara refresh
    -- assincrono do inbox (o scan real acontece em OnInboxUpdate).
    self:RequestInboxRefresh()
    -- M1: abre a janela definitiva (idempotente; so UI, sem API servidora).
    self:Open()
end

function MailScreen:OnMailClosed()
    if not self.initialized then return end
    -- M3: mailbox fechou = fila Retirar-Tudo aborta com seguranca.
    self:StopTakeAll(false)
    -- M4.2: mailbox fechou = fila de envio aborta (regra de ouro: sem API
    -- servidora fora de MAIL_SHOW -> MAIL_CLOSED).
    self:StopSendQueue(false)
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] Mailbox fechada.")
    end
    -- M1: fecha SO a UI propria (sem re-encerrar sessao: sem CloseMail).
    self:Close()
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
    -- M2/M4.1: atualizacao reativa do visual apos o scan (so na INBOX; no
    -- compor os dados atualizam em silencio sem tocar na grade/titulos).
    if self.isOpen and self.frame and self.currentScreen == "INBOX" then
        self:UpdateInboxFilterBar()
        self:RefreshInboxList()
    end
    -- M3: fila Retirar-Tudo avanca UMA carta por MAIL_INBOX_UPDATE.
    self:AdvanceTakeAll()
end

function MailScreen:OnMailSendSuccess()
    if not self.initialized then return end
    if CM.logger and CM.logger.Log then
        CM.logger:Log("[MailScreen] MAIL_SEND_SUCCESS recebido.")
    end
    -- M3: contrato de fila serializada (envios sao M4; so avanca a fila).
    self:AdvanceTakeAll()
    -- M4.2: fila de envio avanca UMA carta por MAIL_SEND_SUCCESS.
    self:AdvanceSendQueue()
end

function MailScreen:OnBagUpdate()
    if not self.initialized then return end
    -- M4.1: grade do compor acompanha as bolsas em silencio (BAG_UPDATE
    -- dispara com frequencia; sem logs aqui). Fora do compor, nada a fazer.
    if self.isOpen and self.currentScreen == "COMPOSE" then
        self:ScanComposeBags()
    end
end

function MailScreen:OnMoneyUpdate()
    if not self.initialized then return end
    -- M4.1: mantem o custo de postagem do ENVIAR atualizado em silencio.
    if self.isOpen and self.currentScreen == "COMPOSE" then
        self:UpdateComposePostage()
    end
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
        CM.logger:Log("[MailScreen] Modulo inicializado (M3: janela + leitura + acoes do inbox).")
    end
end

-- Inicialização automática no carregamento do arquivo
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    MailScreen:Initialize()
    -- SVs ja carregadas neste ponto: garante o historico sem clobber.
    MailScreen:EnsureMailHistory()
end)
