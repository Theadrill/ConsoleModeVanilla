-- ============================================================================
-- ConsoleModeVanilla - UI/AuctionScan.lua
-- Motor de Fila, Consulta e Scan de Leilões para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
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
AuctionScan.lastQueryTime      = 0
AuctionScan.currentPage        = 0
AuctionScan.totalPages         = 0
AuctionScan.onPageCallback     = nil
AuctionScan.onCompleteCallback = nil
AuctionScan.eventFrame         = nil

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
    self.currentPage        = 0
    self.totalPages         = 0
    self.onPageCallback     = nil
    self.onCompleteCallback = nil
end

-- ----------------------------------------------------------------------------
-- 3. INICIALIZAÇÃO E EVENTOS
-- ----------------------------------------------------------------------------
function AuctionScan:Init()
    if self.eventFrame then return end

    local ef = CreateFrame("Frame", "ConsoleMode_AuctionScanEventFrame")
    ef:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    ef:RegisterEvent("AUCTION_HOUSE_CLOSED")

    ef:SetScript("OnEvent", function()
        if event == "AUCTION_ITEM_LIST_UPDATE" then
            if AuctionScan.isScanning and AuctionScan.onPageCallback then
                AuctionScan.onPageCallback()
            end
        elseif event == "AUCTION_HOUSE_CLOSED" then
            AuctionScan:Reset()
        end
    end)

    self.eventFrame = ef
end

AuctionScan:Init()
