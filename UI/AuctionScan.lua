-- ============================================================================
-- ConsoleModeVanilla - UI/AuctionScan.lua
-- Motor de Fila, Consulta e Scan Paginado de Leilões para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE 1: Motor de Consulta e Progresso Paginado
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_AuctionScan = ConsoleMode_AuctionScan or {}
local AuctionScan = ConsoleMode_AuctionScan
CM.auctionScan = AuctionScan

-- ----------------------------------------------------------------------------
-- 1. ESTADO DO SCANNER
-- ----------------------------------------------------------------------------
AuctionScan.isScanning         = false
AuctionScan.state              = "IDLE" -- "IDLE", "WAITING_READY", "WAITING_UPDATE"
AuctionScan.params             = nil
AuctionScan.currentPage        = 0
AuctionScan.totalPages         = 1
AuctionScan.totalCount         = 0
AuctionScan.results            = {}
AuctionScan.onPageCallback     = nil
AuctionScan.onCompleteCallback = nil
AuctionScan.onErrorCallback    = nil
AuctionScan.eventFrame         = nil
AuctionScan.tickerFrame        = nil
AuctionScan.waitTimer          = 0
AuctionScan.timeoutTimer       = 0

-- ----------------------------------------------------------------------------
-- 2. VERIFICAÇÃO DE CONSULTA (WoW 1.12 CanSendAuctionQuery)
-- ----------------------------------------------------------------------------
function AuctionScan:CanQuery()
    if CanSendAuctionQuery then
        local canQuery = CanSendAuctionQuery()
        return (canQuery and canQuery ~= 0 and canQuery ~= false)
    end
    return true
end

function AuctionScan:Reset()
    self.isScanning         = false
    self.state              = "IDLE"
    self.params             = nil
    self.currentPage        = 0
    self.totalPages         = 1
    self.totalCount         = 0
    self.results            = {}
    self.onPageCallback     = nil
    self.onCompleteCallback = nil
    self.onErrorCallback    = nil
    self.waitTimer          = 0
    self.timeoutTimer       = 0
end

-- ----------------------------------------------------------------------------
-- 3. INÍCIO E CONTROLE DO SCAN
-- ----------------------------------------------------------------------------
function AuctionScan:StartQuery(params, onPageCallback, onCompleteCallback, onErrorCallback)
    if not (ConsoleMode_AuctionScreen and ConsoleMode_AuctionScreen.isOpen) then
        if onErrorCallback then
            onErrorCallback("AUCTION_HOUSE_CLOSED")
        end
        return false
    end

    self:Reset()

    self.params = params or {}
    self.onPageCallback = onPageCallback
    self.onCompleteCallback = onCompleteCallback
    self.onErrorCallback = onErrorCallback
    self.isScanning = true
    self.state = "WAITING_READY"
    self.currentPage = 0
    self.totalPages = 1
    self.totalCount = 0
    self.results = {}
    self.waitTimer = 0
    self.timeoutTimer = 0

    if self:CanQuery() then
        self:SendPageQuery()
    end

    return true
end

function AuctionScan:AbortQuery()
    if not self.isScanning then return end

    local collected = self.results or {}
    local total = self.totalCount or 0
    local onComplete = self.onCompleteCallback

    self:Reset()

    if onComplete then
        pcall(function() onComplete(collected, total, true) end)
    end
end

function AuctionScan:SendPageQuery()
    if not self.params then return end

    local name         = self.params.name or ""
    local minLevel     = self.params.minLevel or 0
    local maxLevel     = self.params.maxLevel or 0
    local invTypeIndex = self.params.invTypeIndex or 0
    local classIndex   = self.params.classIndex or 0
    local subClassIdx  = self.params.subClassIndex or 0
    local isUsable     = self.params.isUsable or 0
    local qualityIndex = self.params.qualityIndex or -1
    local page         = self.currentPage or 0

    if QueryAuctionItems then
        QueryAuctionItems(
            name,
            minLevel,
            maxLevel,
            invTypeIndex,
            classIndex,
            subClassIdx,
            page,
            isUsable,
            qualityIndex
        )
        self.state = "WAITING_UPDATE"
        self.timeoutTimer = 0
    else
        self:Reset()
        if self.onErrorCallback then
            self.onErrorCallback("QUERY_FUNCTION_MISSING")
        end
    end
end

-- ----------------------------------------------------------------------------
-- 4. PROCESSAMENTO DA PÁGINA (AUCTION_ITEM_LIST_UPDATE)
-- ----------------------------------------------------------------------------
function AuctionScan:OnAuctionListUpdate()
    if not self.isScanning or self.state ~= "WAITING_UPDATE" then return end

    local batchCount, totalCount = GetNumAuctionItems("list")
    batchCount = batchCount or 0
    totalCount = totalCount or 0

    self.totalCount = totalCount
    local pages = math.ceil(totalCount / 50)
    if pages < 1 then pages = 1 end
    self.totalPages = pages

    for i = 1, batchCount do
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", i)
        local link = GetAuctionItemLink("list", i)
        local timeLeft = GetAuctionItemTimeLeft("list", i)

        table.insert(self.results, {
            name         = name or "",
            texture      = texture or "",
            count        = count or 1,
            quality      = quality or 0,
            canUse       = canUse,
            level        = level or 0,
            minBid       = minBid or 0,
            minIncrement = minIncrement or 0,
            buyoutPrice  = buyoutPrice or 0,
            bidAmount    = bidAmount or 0,
            highBidder   = highBidder,
            owner        = owner or "",
            link         = link,
            timeLeft     = timeLeft or 1,
            page         = self.currentPage,
            index        = i
        })
    end

    if self.onPageCallback then
        local ok, err = pcall(function()
            AuctionScan.onPageCallback(AuctionScan.currentPage, AuctionScan.totalPages, batchCount, totalCount)
        end)
    end

    -- Se já escaneamos a última página ou não há mais itens no lote
    if (self.currentPage + 1 >= self.totalPages) or (batchCount == 0) then
        local collected = self.results
        local total = self.totalCount
        local onComplete = self.onCompleteCallback
        self:Reset()
        if onComplete then
            pcall(function() onComplete(collected, total, false) end)
        end
    else
        -- Prepara próxima página imediatamente
        self.currentPage = self.currentPage + 1
        self.state = "WAITING_READY"
        self.waitTimer = 0
        if self:CanQuery() then
            self:SendPageQuery()
        end
    end
end

-- ----------------------------------------------------------------------------
-- 5. LOOP DE ATUALIZAÇÃO (OnUpdate)
-- ----------------------------------------------------------------------------
function AuctionScan:OnUpdate(dt)
    if not self.isScanning then return end

    dt = dt or arg1 or 0.1

    if self.state == "WAITING_READY" then
        self.waitTimer = self.waitTimer + dt
        if self:CanQuery() then
            self:SendPageQuery()
        end
    elseif self.state == "WAITING_UPDATE" then
        self.timeoutTimer = self.timeoutTimer + dt
        -- Timeout de segurança: 5.0 segundos sem resposta da Blizzard (padrão aux-addon)
        if self.timeoutTimer > 5.0 then
            local collected = self.results
            local total = self.totalCount
            local onComplete = self.onCompleteCallback
            self:Reset()
            if onComplete then
                pcall(function() onComplete(collected, total, false) end)
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- 6. INICIALIZAÇÃO DE EVENTOS E FRAME TICKER
-- ----------------------------------------------------------------------------
function AuctionScan:Init()
    if self.eventFrame then return end

    local ef = CreateFrame("Frame", "ConsoleMode_AuctionScanEventFrame")
    ef:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    ef:RegisterEvent("AUCTION_HOUSE_CLOSED")

    ef:SetScript("OnEvent", function()
        if event == "AUCTION_ITEM_LIST_UPDATE" then
            AuctionScan:OnAuctionListUpdate()
        elseif event == "AUCTION_HOUSE_CLOSED" then
            AuctionScan:AbortQuery()
        end
    end)

    ef:SetScript("OnUpdate", function()
        AuctionScan:OnUpdate(arg1)
    end)

    self.eventFrame = ef
end

AuctionScan:Init()
