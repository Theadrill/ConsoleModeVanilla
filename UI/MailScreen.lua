-- ============================================================================
-- ConsoleModeVanilla - UI/MailScreen.lua
-- Sistema Modular de Correio (Mailbox) em Split-View para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- NOTA (M1): supressao visual do MailFrame nativo (off-screen,
-- sem Hide/CloseMail) + registro de eventos + flags + logs + CAMADA DE DADOS
-- DE LEITURA do inbox (CheckInbox/GetInboxNumItems/GetInboxHeaderInfo com
-- guarda isOpen, filtros 1..3, paginacao logica) + ESQUELETO VISUAL split-view
-- (dimmer, 9-slice Carved_9Slides, header CORREIO+Sair, 2 colunas vazias,
-- footer). SEM escrita (TakeInbox*/DeleteInboxItem/ReturnInboxItem/SendMail/
-- CloseMail), SEM linhas do inbox/detalhes/filtros visuais (M2), SEM acoes,
-- SEM compor/envio, SEM modal, SEM CloseTopFrame (M3+).
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
MailScreen.frame              = nil
MailScreen.dimmer             = nil

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
function MailScreen:CreateFooterHints(parent)
    -- Hints M1 (resto entra nas fases seguintes).
    local hints = {
        { icons = { "LB", "RB" }, label = "Colunas" },
        { icons = { "LT", "RT" }, label = "Filtros" },
        { icons = { "DALL" },     label = "Navegar" },
        { icons = { "A" },        label = "Abrir" },
        { icons = { "B" },        label = "Fechar" },
    }

    local container = CreateFrame("Frame", "ConsoleMode_MailFooterContainer", parent)
    container:SetHeight(34)
    container:SetPoint("CENTER", parent, "BOTTOM", 0, 18)
    parent.footerContainer = container

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

    -- Helper M1: painel de coluna VAZIO (titulo + placeholder; linhas em M2)
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

        -- Area interna vazia (linhas do inbox entram em M2)
        local listArea = CreateFrame("Frame", nil, col)
        listArea:SetPoint("TOPLEFT", colHeader, "BOTTOMLEFT", 0, -6)
        listArea:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", -8, 8)
        col.listArea = listArea

        local placeholder = listArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        placeholder:SetPoint("CENTER", listArea, "CENTER", 0, 0)
        MailScreen:ApplyFont(placeholder, FONTS.medium, 16)
        placeholder:SetText("|cffaaaaaaEm breve|r")
        col.placeholder = placeholder

        return col
    end

    -- Coluna Esquerda: Caixa de Entrada
    local leftCol = CreateColumnPanel("ConsoleMode_MailColLeft", "CAIXA DE ENTRADA", ICONS.LB)
    leftCol:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
    leftCol:SetPoint("BOTTOMLEFT", contentArea, "BOTTOMLEFT", 0, 0)
    leftCol:SetPoint("RIGHT", divider, "LEFT", -6, 0)
    frame.leftCol = leftCol

    -- Coluna Direita: Composicao (em breve)
    local rightCol = CreateColumnPanel("ConsoleMode_MailColRight", "COMPOSIÇÃO (em breve)", ICONS.RB)
    rightCol:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", 0, 0)
    rightCol:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    rightCol:SetPoint("LEFT", divider, "RIGHT", 6, 0)
    frame.rightCol = rightCol

    self:UpdateLayout()
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
        CM.logger:Log("[MailScreen] Modulo inicializado (M1: janela + leitura + filtros).")
    end
end

-- Inicialização automática no carregamento do arquivo
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    MailScreen:Initialize()
end)
