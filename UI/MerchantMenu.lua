-- ============================================================================
-- ConsoleModeVanilla - UI/MerchantMenu.lua
-- Sistema Modular de Interação com NPC Vendedor & Inventário Split-View
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_MerchantMenu = ConsoleMode_MerchantMenu or {}
local MerchantMenu = ConsoleMode_MerchantMenu
CM.merchantMenu = MerchantMenu

-- ----------------------------------------------------------------------------
-- 1. CONSTANTES DE DESIGN SYSTEM, RECURSOS & CORES
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
    GOLD   = "Interface\\MoneyFrame\\UI-GoldIcon",
    SILVER = "Interface\\MoneyFrame\\UI-SilverIcon",
    COPPER = "Interface\\MoneyFrame\\UI-CopperIcon",
}

local QUALITY_COLORS = {
    [0] = { r = 0.62, g = 0.62, b = 0.62, hex = "|cff9d9d9d" }, -- Pobre (Cinza)
    [1] = { r = 1.00, g = 1.00, b = 1.00, hex = "|cffffffff" }, -- Comum (Branco)
    [2] = { r = 0.12, g = 1.00, b = 0.00, hex = "|cff1eff00" }, -- Incomum (Verde)
    [3] = { r = 0.00, g = 0.44, b = 0.87, hex = "|cff0070dd" }, -- Raro (Azul)
    [4] = { r = 0.64, g = 0.21, b = 0.93, hex = "|cffa335ee" }, -- Épico (Roxo)
    [5] = { r = 1.00, g = 0.50, b = 0.00, hex = "|cffff8000" }, -- Lendário (Laranja)
}

local SUBTABS_BAGS = {
    { id = "ALL",        name = "Todos" },
    { id = "EQUIP",      name = "Equipamentos" },
    { id = "CONSUMABLE", name = "Consumíveis" },
    { id = "JUNK",       name = "Lixo" },
}

-- Sub-abas da coluna VENDEDOR (Fase 5/6). Recompra usa API de buyback 1.12.
local SUBTABS_VENDOR = {
    { id = "ALL",     name = "Todos" },
    { id = "EQUIP",   name = "Equip" },
    { id = "CONSUM",  name = "Consum" },
    { id = "BUYBACK", name = "Recompra" },
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
-- 2. ESTADO DO MÓDULO
-- ----------------------------------------------------------------------------
MerchantMenu.isOpen           = false
MerchantMenu.initialized      = false
MerchantMenu.currentNPC       = nil
MerchantMenu.canRepair        = false
MerchantMenu.itemCount        = 0
MerchantMenu.announced        = false
MerchantMenu.scanFrame        = nil
MerchantMenu.frame            = nil
MerchantMenu.activeColumn     = "BAGS" -- "VENDOR" ou "BAGS"
MerchantMenu.bagSubTabIdx     = 1
MerchantMenu.selectedBagIndex = 1
MerchantMenu.bagScrollOffset  = 0
MerchantMenu.rawBagItems      = {}
MerchantMenu.filteredBagItems = {}

-- Estado da coluna VENDEDOR (Fase 5) + Fase 6 (modal/autosell/buyback/compare)
MerchantMenu.merchantItems       = {}
MerchantMenu.filteredVendorItems = {}
MerchantMenu.selectedVendorIndex = 1
MerchantMenu.vendorScrollOffset  = 0
MerchantMenu.vendorSubTabIdx     = 1
MerchantMenu.buybackItems        = {}
MerchantMenu.qtyModal            = { isOpen = false, vendorIndex = nil, qty = 1, maxQty = 1, unitPrice = 0, stock = 0, itemName = "" }

-- Autorepeat ao segurar o D-Pad (hold-to-scroll). Espelha Cursor.repeatState.
MerchantMenu.repeatState = {
    direction = nil,
    timer = 0,
    initialDelay = 0.35, -- espera antes de comecar a repetir
    interval = 0.12,     -- passo continuo (UP/DOWN)
}
MerchantMenu.repeatFrame = nil
MerchantMenu.qtyModalFrame       = nil
MerchantMenu.autoSell            = { running = false, queue = {}, pos = 1, gained = 0, acc = 0 }
MerchantMenu.compareState        = { lastKey = nil, isUpgrade = nil }

-- ----------------------------------------------------------------------------
-- 3. TOOLTIP SCANNER PARA PREÇOS DE VENDA & ATRIBUTOS (WOW 1.12)
-- ----------------------------------------------------------------------------
local scanTip = CreateFrame("GameTooltip", "ConsoleMode_MerchantScanTip", UIParent, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
scanTip.money = 0
scanTip:SetScript("OnTooltipAddMoney", function()
    scanTip.money = arg1
end)

-- ----------------------------------------------------------------------------
-- 4. HELPERS TIPOGRÁFICOS E FORMATAÇÃO DE MOEDAS
-- ----------------------------------------------------------------------------
function MerchantMenu:ApplyFont(fontString, fontPath, size, outline, shadowOffset, shadowColor)
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
function MerchantMenu:FormatMoneyText(totalCopper)
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
-- 5. SUPRESSÃO SEGURA DE BOLSAS E DA JANELA NATIVA DA BLIZZARD (MerchantFrame)
-- ----------------------------------------------------------------------------
function MerchantMenu:CloseAllOpenBags()
    for i = 1, 5 do
        local cf = getglobal("ContainerFrame" .. i)
        if cf and cf:IsVisible() then
            cf:Hide()
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

function MerchantMenu:SuppressDefaultFrame()
    if MerchantFrame then
        MerchantFrame.selectedTab = 1
        MerchantFrame:SetAlpha(0)
        MerchantFrame:EnableMouse(false)
        MerchantFrame:ClearAllPoints()
        MerchantFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 5000)
    end
    self:CloseAllOpenBags()
end

-- ----------------------------------------------------------------------------
-- 5b. RESOLVE GetItemInfo ROBUSTO (Turtle 9-ret sem itemLevel vs 1.12 padrão 10-ret)
-- 9-ret: nome, link, raridade, minLevel, tipo, subtipo, stack, equipLoc, textura
-- 10-ret: nome, link, raridade, level, minLevel, tipo, subtipo, stack, equipLoc, textura
-- Detecta pelo tipo do 5o retorno e sanitiza equipLoc (só INVTYPE_* passa).
-- ----------------------------------------------------------------------------
function MerchantMenu:ResolveItemInfo(itemIDorLink)
    if not itemIDorLink or not GetItemInfo then return nil end
    local a1, a2, a3, a4, a5, a6, a7, a8, a9, a10 = GetItemInfo(itemIDorLink)
    if not a1 then return nil end
    local quality = tonumber(a3) or 1
    local reqLevel, itemType, subType, equipLoc = 0, "", "", ""
    if type(a5) == "string" then
        reqLevel = tonumber(a4) or 0
        if type(a5) == "string" then itemType = a5 end
        if type(a6) == "string" then subType = a6 end
        if type(a8) == "string" then equipLoc = a8 end
    else
        reqLevel = tonumber(a5) or 0
        if type(a6) == "string" then itemType = a6 end
        if type(a7) == "string" then subType = a7 end
        if type(a9) == "string" then equipLoc = a9 end
    end
    if type(equipLoc) ~= "string" then equipLoc = "" end
    if string.find(equipLoc, "\\\\") or string.find(equipLoc, "Interface") or string.find(equipLoc, "INV_") then
        equipLoc = ""
    end
    if string.find(equipLoc, "^INVTYPE_") == nil then
        equipLoc = ""
    end
    if type(itemType) ~= "string" then itemType = "" end
    if type(subType) ~= "string" then subType = "" end
    return a1, quality, reqLevel, itemType, subType, equipLoc
end

-- ----------------------------------------------------------------------------
-- 6. LEITURA, CLASSIFICAÇÃO E FILTROS DO INVENTÁRIO DO JOGADOR (FASE 3)
-- ----------------------------------------------------------------------------
function MerchantMenu:ParseBagItem(bagID, slotID)
    local texture, itemCount, locked, quality, readable = GetContainerItemInfo(bagID, slotID)
    if not texture then return nil end

    itemCount = itemCount or 1
    local rawLink = GetContainerItemLink(bagID, slotID)

    local itemName = "Item Desconhecido"
    local itemQuality = quality or 1
    local itemReqLevel = 0
    local itemType = ""
    local itemSubType = ""
    local itemEquipLoc = ""

    local itemID = nil
    if rawLink then
        local _, _, idStr = string.find(rawLink, "item:(%d+)")
        itemID = tonumber(idStr)
    end

    if itemID then
        local n, q, reqL, t, st, eqL = self:ResolveItemInfo(itemID)
        if n then
            itemName = n
            itemQuality = tonumber(q) or itemQuality
            itemReqLevel = tonumber(reqL) or 0
            itemType = t or ""
            itemSubType = st or ""
            itemEquipLoc = eqL or ""
        end
    elseif rawLink then
        local n, q, reqL, t, st, eqL = self:ResolveItemInfo(rawLink)
        if n then
            itemName = n
            itemQuality = tonumber(q) or itemQuality
            itemReqLevel = tonumber(reqL) or 0
            itemType = t or ""
            itemSubType = st or ""
            itemEquipLoc = eqL or ""
        end
    end

    -- Preço de venda via Tooltip Scanner
    local sellPrice = 0
    scanTip.money = 0
    scanTip:ClearLines()
    pcall(function() scanTip:SetBagItem(bagID, slotID) end)
    -- Fallback (mesmo padrão do MainMenu e do ParseSimpleStats): se o SetBagItem
    -- não rendeu linhas (erro silenciado pelo pcall ou item fora de contexto),
    -- tenta de novo via hyperlink direto do link da bag.
    if (scanTip:NumLines() or 0) < 2 and rawLink then
        scanTip:ClearLines()
        local _, _, raw = string.find(rawLink, "(item:%d+:%d+:%d+:%d+)")
        local okLink = false
        if raw then okLink = pcall(function() scanTip:SetHyperlink(raw) end) end
        if not okLink then pcall(function() scanTip:SetHyperlink(rawLink) end) end
    end

    if scanTip.money and scanTip.money > 0 then
        sellPrice = scanTip.money
    elseif itemID then
        -- Fallback na base de dados própria embutida de Vanilla ou addons de economia
        local unitPrice = 0
        if ConsoleMode_SellValues and ConsoleMode_SellValues[itemID] then
            unitPrice = ConsoleMode_SellValues[itemID]
        elseif ShaguTweaks and ShaguTweaks.SellValueDB and ShaguTweaks.SellValueDB[itemID] then
            unitPrice = ShaguTweaks.SellValueDB[itemID]
        elseif ShaguValueDB and ShaguValueDB[itemID] then
            unitPrice = ShaguValueDB[itemID]
        elseif GetSellValue and rawLink then
            unitPrice = GetSellValue(rawLink) or 0
        elseif GetItemSellValue and rawLink then
            unitPrice = GetItemSellValue(rawLink) or 0
        end
        if unitPrice > 0 then
            sellPrice = unitPrice * itemCount
        end
    end

    -- Tooltip lines parsing (Atributos, Requisitos e Efeitos)
    local statsLines = {}
    local desc = ""
    local numLines = scanTip:NumLines() or 0
    for l = 2, numLines do
        local leftTextObj = _G["ConsoleMode_MerchantScanTipTextLeft" .. l]
        local rightTextObj = _G["ConsoleMode_MerchantScanTipTextRight" .. l]
        local leftText = (leftTextObj and leftTextObj:GetText()) or ""
        local rightText = (rightTextObj and rightTextObj:GetText()) or ""

        if leftText ~= "" then
            if string.find(leftText, "Preço de Venda:") or string.find(leftText, "Sell Price:") then
                -- já capturado via scanTip.money
            elseif string.find(leftText, "Uso:", 1, 1) or string.find(leftText, "Use:", 1, 1) or string.find(leftText, "Equipar:", 1, 1) then
                desc = leftText
                if rightText ~= "" then desc = desc .. " " .. rightText end
            elseif string.find(rightText, "Uso:", 1, 1) or string.find(rightText, "Use:", 1, 1) then
                desc = rightText
            elseif not string.find(leftText, "Venda:") and not string.find(leftText, "Sell:") then
                local lineStr = leftText
                if rightText ~= "" then
                    lineStr = lineStr .. "  " .. rightText
                end
                table.insert(statsLines, "|cffffffff" .. lineStr .. "|r")
            end
        end
    end

    -- Se GetItemInfo não retornou nome, recupera a linha 1 do Tooltip
    if itemName == "Item Desconhecido" or itemName == "" then
        local left1 = _G["ConsoleMode_MerchantScanTipTextLeft1"]
        local text1 = left1 and left1:GetText()
        if text1 and text1 ~= "" then
            itemName = text1
        end
    end

    -- Classificação de Categoria
    local cat = "MISC"
    if itemType == "Armadura" or itemType == "Armor" or itemType == "Arma" or itemType == "Weapon" or (itemEquipLoc and itemEquipLoc ~= "") then
        cat = "EQUIP"
    elseif itemType == "Consumível" or itemType == "Consumable" or itemType == "Potion" or itemType == "Food & Drink" then
        cat = "CONSUMABLE"
    elseif itemType == "Mercadoria" or itemType == "Trade Goods" or itemType == "Reagente" or itemType == "Reagent" then
        cat = "TRADE"
    end

    return {
        bagID       = bagID,
        slotID      = slotID,
        itemID      = itemID,
        name        = itemName,
        texture     = texture,
        count       = itemCount,
        quality     = itemQuality,
        link        = rawLink,
        reqLevel    = itemReqLevel,
        itemType    = itemType,
        subType     = itemSubType,
        equipLoc    = itemEquipLoc,
        category    = cat,
        statsLines  = statsLines,
        desc        = desc,
        sellPrice   = sellPrice,
    }
end

-- Re-scan fresco da linha de Uso/Efeito via hyperlink (defesa em profundidade:
-- o scan em massa do ParseBagItem pode perder a linha se o tooltip ainda nao
-- estava populado, e ParseVendorItem/ParseBuybackItem nunca varrem o tooltip).
-- Retorna "" quando nao ha linha de Uso: ou quando o scan falha. Lua 5.0.
function MerchantMenu:ScanUseLineFresh(itemLink)
    if not itemLink or not scanTip then return "" end
    scanTip:ClearLines()
    local ok = false
    local _, _, raw = string.find(itemLink, "(item:%d+:%d+:%d+:%d+)")
    if raw then ok = pcall(function() scanTip:SetHyperlink(raw) end) end
    if not ok then ok = pcall(function() scanTip:SetHyperlink(itemLink) end) end
    if not ok then return "" end
    local nl = scanTip:NumLines() or 0
    for l = 2, nl do
        local lo = getglobal("ConsoleMode_MerchantScanTipTextLeft" .. l)
        local ro = getglobal("ConsoleMode_MerchantScanTipTextRight" .. l)
        local lt = ""
        local rt = ""
        if lo then lt = lo:GetText() or "" end
        if ro then rt = ro:GetText() or "" end
        if string.find(lt, "Uso:", 1, 1) or string.find(lt, "Use:", 1, 1) or string.find(lt, "Equipar:", 1, 1) then
            if rt ~= "" then lt = lt .. " " .. rt end
            return lt
        end
        if string.find(rt, "Uso:", 1, 1) or string.find(rt, "Use:", 1, 1) then
            return rt
        end
    end
    return ""
end

function MerchantMenu:ScanPlayerBags()
    local rawItems = {}
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local itemData = self:ParseBagItem(bag, slot)
                if itemData then
                    table.insert(rawItems, itemData)
                end
            end
        end
    end
    self.rawBagItems = rawItems
    self:FilterBagItems()
end

-- ----------------------------------------------------------------------------
-- 6b. CATÁLOGO DO VENDEDOR (FASE 5 - WoW 1.12 / Lua 5.0)
-- Parse guarda .index original para BuyMerchantItem. Sem #table/continue/goto.
-- ----------------------------------------------------------------------------
function MerchantMenu:ParseVendorItem(mercIndex)
    if not mercIndex or mercIndex < 1 then return nil end
    if not GetMerchantItemInfo then return nil end
    local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(mercIndex)
    if not name then return nil end
    quantity = quantity or 1
    price = price or 0
    if type(numAvailable) ~= "number" then numAvailable = -1 end

    local link = nil
    if GetMerchantItemLink then
        link = GetMerchantItemLink(mercIndex)
    end
    local itemID = nil
    if link then
        local _, _, idStr = string.find(link, "item:(%d+)")
        itemID = tonumber(idStr)
    end

    local itemName = name
    local itemQuality = 1
    local itemReqLevel = 0
    local itemType = ""
    local itemSubType = ""
    local itemEquipLoc = ""
    if itemID and GetItemInfo then
        local n, q, reqL, t, st, eqL = self:ResolveItemInfo(itemID)
        if n then
            itemName = n
            itemQuality = tonumber(q) or 1
            itemReqLevel = tonumber(reqL) or 0
            itemType = t or ""
            itemSubType = st or ""
            itemEquipLoc = eqL or ""
        end
    end

    local cat = "MISC"
    if (itemEquipLoc and itemEquipLoc ~= "") or itemType == "Armor" or itemType == "Armadura" or itemType == "Weapon" or itemType == "Arma" then
        cat = "EQUIP"
    elseif itemType == "Consumable" or itemType == "Consumível" or itemType == "Potion" or itemType == "Food & Drink" then
        cat = "CONSUMABLE"
    end

    return {
        index = mercIndex,
        name = itemName,
        texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        price = price,
        count = quantity,
        numAvailable = numAvailable,
        isUsable = isUsable,
        itemID = itemID,
        link = link,
        quality = itemQuality,
        reqLevel = itemReqLevel,
        itemType = itemType,
        subType = itemSubType,
        equipLoc = itemEquipLoc,
        category = cat,
        isBuyback = false,
        statsLines = {},
        desc = "",
        sellPrice = 0,
    }
end

function MerchantMenu:ParseBuybackItem(bbIndex)
    if not bbIndex or bbIndex < 1 then return nil end
    if not GetBuybackItemInfo then return nil end
    local name, texture, price, quantity = GetBuybackItemInfo(bbIndex)
    if not name then return nil end
    quantity = quantity or 1
    price = price or 0
    local link = nil
    if GetBuybackItemLink then
        local ok, l = pcall(function() return GetBuybackItemLink(bbIndex) end)
        if ok then link = l end
    end
    local itemID = nil
    if link then
        local _, _, idStr = string.find(link, "item:(%d+)")
        itemID = tonumber(idStr)
    end
    local itemQuality, itemType, itemSubType, itemEquipLoc, itemReqLevel = 1, "", "", "", 0
    if itemID and GetItemInfo then
        local n, q, reqL, t, st, eqL = self:ResolveItemInfo(itemID)
        if n then
            name = n
            itemQuality = tonumber(q) or 1
            itemReqLevel = tonumber(reqL) or 0
            itemType = t or ""
            itemSubType = st or ""
            itemEquipLoc = eqL or ""
        end
    end
    return {
        index = nil,
        buybackIndex = bbIndex,
        name = name,
        texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
        price = price,
        count = quantity,
        numAvailable = 1,
        itemID = itemID,
        link = link,
        quality = itemQuality,
        reqLevel = itemReqLevel,
        itemType = itemType,
        subType = itemSubType,
        equipLoc = itemEquipLoc,
        category = "BUYBACK",
        isBuyback = true,
        statsLines = {},
        desc = "",
        sellPrice = 0,
    }
end

function MerchantMenu:ScanMerchantItems()
    local raw = {}
    if GetMerchantNumItems then
        local numItems = GetMerchantNumItems() or 0
        for i = 1, numItems do
            local data = self:ParseVendorItem(i)
            if data then
                table.insert(raw, data)
            end
        end
    end
    if GetNumBuybackItems then
        local bbCount = GetNumBuybackItems() or 0
        for b = 1, bbCount do
            local bb = self:ParseBuybackItem(b)
            if bb then
                table.insert(raw, bb)
            end
        end
    end
    self.merchantItems = raw
    self.itemCount = table.getn(raw)
    self:FilterVendorItems()
end

function MerchantMenu:ScanBuybackItems()
    local out = {}
    if not GetNumBuybackItems then
        self.buybackItems = out
        return out
    end
    local count = GetNumBuybackItems() or 0
    for i = 1, count do
        if GetBuybackItemInfo then
            local bb = self:ParseBuybackItem(i)
            if bb then
                table.insert(out, bb)
            end
        end
    end
    self.buybackItems = out
    return out
end

function MerchantMenu:FilterBagItems()
    local currentSubTab = SUBTABS_BAGS[self.bagSubTabIdx] or SUBTABS_BAGS[1]
    local filterId = currentSubTab.id
    local filtered = {}

    local raw = self.rawBagItems or {}
    local numRaw = table.getn(raw)
    for i = 1, numRaw do
        local item = raw[i]
        local match = false
        if filterId == "ALL" then
            match = true
        elseif filterId == "EQUIP" then
            match = (item.category == "EQUIP")
        elseif filterId == "CONSUMABLE" then
            match = (item.category == "CONSUMABLE")
        elseif filterId == "JUNK" then
            match = (item.quality == 0)
        end
        if match then
            table.insert(filtered, item)
        end
    end

    self.filteredBagItems = filtered

    local numFiltered = table.getn(filtered)
    if self.selectedBagIndex > numFiltered then
        self.selectedBagIndex = math.max(1, numFiltered)
    end
    if self.selectedBagIndex < 1 then
        self.selectedBagIndex = 1
    end

    -- Ajusta o offset de rolagem mantendo a seleção visível
    local visibleRows = 7
    if self.selectedBagIndex <= self.bagScrollOffset then
        self.bagScrollOffset = self.selectedBagIndex - 1
    elseif self.selectedBagIndex > (self.bagScrollOffset + visibleRows) then
        self.bagScrollOffset = self.selectedBagIndex - visibleRows
    end
    if self.bagScrollOffset < 0 then
        self.bagScrollOffset = 0
    end
    local maxOffset = math.max(0, numFiltered - visibleRows)
    if self.bagScrollOffset > maxOffset then
        self.bagScrollOffset = maxOffset
    end
end

-- Filtra merchantItems pela sub-aba ativa (Fase 5/6). Espelha FilterBagItems.
function MerchantMenu:FilterVendorItems()
    local tab = SUBTABS_VENDOR[self.vendorSubTabIdx] or SUBTABS_VENDOR[1]
    local filterId = tab.id
    if filterId == "BUYBACK" then
        local bb = self:ScanBuybackItems()
        self.filteredVendorItems = bb or {}
    else
        local filtered = {}
        local raw = self.merchantItems or {}
        local numRaw = table.getn(raw)
        for i = 1, numRaw do
            local item = raw[i]
            local match = false
            if filterId == "ALL" then
                if not item.isBuyback then match = true end
            elseif filterId == "EQUIP" then
                if not item.isBuyback and item.category == "EQUIP" then match = true end
            elseif filterId == "CONSUM" then
                if not item.isBuyback and item.category == "CONSUMABLE" then match = true end
            end
            if match then
                table.insert(filtered, item)
            end
        end
        self.filteredVendorItems = filtered
    end

    local numFiltered = table.getn(self.filteredVendorItems or {})
    if self.selectedVendorIndex > numFiltered then
        self.selectedVendorIndex = math.max(1, numFiltered)
    end
    if self.selectedVendorIndex < 1 then
        self.selectedVendorIndex = 1
    end
    local visibleRows = 7
    if self.selectedVendorIndex <= self.vendorScrollOffset then
        self.vendorScrollOffset = self.selectedVendorIndex - 1
    elseif self.selectedVendorIndex > (self.vendorScrollOffset + visibleRows) then
        self.vendorScrollOffset = self.selectedVendorIndex - visibleRows
    end
    if self.vendorScrollOffset < 0 then self.vendorScrollOffset = 0 end
    local maxOffset = math.max(0, numFiltered - visibleRows)
    if self.vendorScrollOffset > maxOffset then self.vendorScrollOffset = maxOffset end
end

function MerchantMenu:MoveVendorSelection(delta)
    local numItems = table.getn(self.filteredVendorItems or {})
    if numItems == 0 then return end
    local newIdx = (self.selectedVendorIndex or 1) + delta
    if newIdx < 1 then newIdx = 1 end
    if newIdx > numItems then newIdx = numItems end
    if newIdx ~= self.selectedVendorIndex then
        self.selectedVendorIndex = newIdx
        PlaySound("igMainMenuOptionCheckBoxOn")
        local visibleRows = 7
        if self.selectedVendorIndex <= self.vendorScrollOffset then
            self.vendorScrollOffset = self.selectedVendorIndex - 1
        elseif self.selectedVendorIndex > (self.vendorScrollOffset + visibleRows) then
            self.vendorScrollOffset = self.selectedVendorIndex - visibleRows
        end
        if self.vendorScrollOffset < 0 then self.vendorScrollOffset = 0 end
        local maxOffset = math.max(0, numItems - visibleRows)
        if self.vendorScrollOffset > maxOffset then self.vendorScrollOffset = maxOffset end
        self:UpdateVendorRows()
    end
end

function MerchantMenu:UpdateBagsSubTabBar()
    local rightCol = self.frame and self.frame.rightCol
    if not rightCol or not rightCol.tabsLabel then return end

    local parts = {}
    local num = table.getn(SUBTABS_BAGS)
    for idx = 1, num do
        local tab = SUBTABS_BAGS[idx]
        if idx == self.bagSubTabIdx then
            table.insert(parts, "|cffe09a15[ " .. tab.name .. " ]|r")
        else
            table.insert(parts, "|cff848484" .. tab.name .. "|r")
        end
    end

    rightCol.tabsLabel:SetText(table.concat(parts, "   "))
end

-- Barra de sub-abas da LOJA (Fase 5). Espelha UpdateBagsSubTabBar.
function MerchantMenu:UpdateVendorSubTabBar()
    local leftCol = self.frame and self.frame.leftCol
    if not leftCol or not leftCol.tabsLabel then return end
    local parts = {}
    local num = table.getn(SUBTABS_VENDOR)
    for idx = 1, num do
        local tab = SUBTABS_VENDOR[idx]
        if idx == self.vendorSubTabIdx then
            table.insert(parts, "|cffe09a15[ " .. tab.name .. " ]|r")
        else
            table.insert(parts, "|cff848484" .. tab.name .. "|r")
        end
    end
    leftCol.tabsLabel:SetText(table.concat(parts, "   "))
end

-- ----------------------------------------------------------------------------
-- 7. CONSTRUÇÃO VISUAL (9-SLICE, DIMMER, DETAILCARD, FOOTER, COLUNAS)
-- ----------------------------------------------------------------------------
function MerchantMenu:Create9Slice(parent, texturePath, cornerSize, uvMap, drawLayer)
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

    -- 4. Centro (Preenchimento sem transparência)
    slices.center = makeSlice("Center", c[2][1], c[2][2], r[2][1], r[2][2])
    slices.center:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMRIGHT", 0, 0)
    slices.center:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPLEFT", 0, 0)

    return slices
end

function MerchantMenu:CreateDimmer()
    if self.dimmer then return end

    local dimmer = CreateFrame("Frame", "ConsoleMode_MerchantDimmer", UIParent)
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

function MerchantMenu:CreateDetailCard(parent)
    local card = CreateFrame("Frame", "ConsoleMode_MerchantDetailCard", parent)
    card:SetHeight(154)
    card:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 28, 48)
    card:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 48)

    card:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
    card:SetBackdropBorderColor(0.50, 0.40, 0.28, 0.65)

    -- 1. Ícone
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(40)
    icon:SetHeight(40)
    icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
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

    -- 2. Preço de Venda / Compra (+20%: 14 -> 17)
    local priceText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    priceText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -10)
    priceText:SetJustifyH("RIGHT")
    self:ApplyFont(priceText, FONTS.titleBold, 17)
    priceText:SetText("|cffaaaaaaPreço: |r--")
    card.priceText = priceText

    -- 3. Título (+20%: 16 -> 19)
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, 0)
    titleText:SetPoint("RIGHT", priceText, "LEFT", -12, 0)
    titleText:SetJustifyH("LEFT")
    self:ApplyFont(titleText, FONTS.titleBold, 19)
    titleText:SetText("|cffe09a15Selecione um item para inspecionar|r")
    card.titleText = titleText

    -- 4. Subtítulo (Tipo / Subtipo / Nível) (+20%: 12 -> 15)
    local typeText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    typeText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3)
    typeText:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    typeText:SetJustifyH("LEFT")
    self:ApplyFont(typeText, FONTS.medium, 15)
    typeText:SetText("|cffaaaaaaNavegue pelas colunas para comprar ou vender itens|r")
    card.typeText = typeText

    -- 4b. Linha dedicada de Uso/Efeito (item.desc), abaixo do subtipo.
    -- Criada uma unica vez; ShowItemDetail atualiza, limpa ou esconde.
    local useText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    useText:SetPoint("TOPLEFT", typeText, "BOTTOMLEFT", 0, -2)
    useText:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    useText:SetJustifyH("LEFT")
    self:ApplyFont(useText, FONTS.bodyBold, 13)
    useText:SetText("")
    useText:Hide()
    card.useText = useText

    -- 5. Descrição / Atributos (2 Colunas) (+20%: 11 -> 13)
    local descColLeft = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descColLeft:SetPoint("TOPLEFT", useText, "BOTTOMLEFT", 0, -4)
    descColLeft:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 12, 10)
    descColLeft:SetWidth(340)
    descColLeft:SetJustifyH("LEFT")
    descColLeft:SetJustifyV("TOP")
    self:ApplyFont(descColLeft, FONTS.bodyBold, 13)
    descColLeft:SetText("|cff888888Use [D-Pad] para navegar pela lista de mercadorias e pelas suas bolsas.|r")
    card.descColLeft = descColLeft

    local descColRight = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descColRight:SetPoint("TOPLEFT", descColLeft, "TOPRIGHT", 16, 0)
    descColRight:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -12, 10)
    descColRight:SetJustifyH("LEFT")
    descColRight:SetJustifyV("TOP")
    self:ApplyFont(descColRight, FONTS.bodyBold, 13)
    descColRight:SetText("|cff888888Pressione [LB] ou [RB] para alternar entre a loja do NPC e seu inventário.|r")
    card.descColRight = descColRight

    return card
end

function MerchantMenu:CreateFooterHints(parent)
    local hints = {
        { icons = { "LB", "RB" }, label = "Colunas" },
        { icons = { "LT", "RT" }, label = "Filtros" },
        { icons = { "DALL" },     label = "Navegar" },
        { icons = { "A" },        label = "Comprar 1x" },
        { icons = { "X" },        label = "Qtd/Vender" },
        { icons = { "Y" },        label = "Reparar / Lixo", key = "REPAIR" },
        { icons = { "B" },        label = "Fechar" },
    }

    local container = CreateFrame("Frame", "ConsoleMode_MerchantFooterContainer", parent)
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

        if hint.key == "REPAIR" then
            self.footerRepairWidget = groupFrame
        end
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

function MerchantMenu:CreateBagRows(parent)
    local rows = {}
    for i = 1, 7 do
        local row = CreateFrame("Button", "ConsoleMode_MerchantBagRow" .. i, parent)
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

        -- Highlight de fundo quando selecionado
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.30)
        hl:SetAllPoints(row)
        hl:Hide()
        row.highlight = hl

        -- Cursor indicador
        local cur = row:CreateTexture(nil, "OVERLAY")
        cur:SetWidth(12)
        cur:SetHeight(12)
        cur:SetPoint("LEFT", row, "LEFT", 4, 0)
        cur:SetTexture("Interface\\QuestFrame\\UI-Quest-BulletPoint")
        cur:SetVertexColor(1.0, 0.85, 0.20)
        cur:Hide()
        row.cursor = cur

        -- Ícone do item
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(32)
        icon:SetHeight(32)
        icon:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.icon = icon

        -- Borda de qualidade do ícone
        local iconBorder = CreateFrame("Frame", nil, row)
        iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
        iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
        iconBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        row.iconBorder = iconBorder

        -- Texto de quantidade (Stack)
        local stackText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        stackText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
        MerchantMenu:ApplyFont(stackText, FONTS.titleBold, 13, "OUTLINE")
        row.stackText = stackText

        -- Preço de venda
        local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        priceText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        priceText:SetJustifyH("RIGHT")
        MerchantMenu:ApplyFont(priceText, FONTS.titleBold, 15)
        row.priceText = priceText

        -- Nome do item
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        nameText:SetPoint("RIGHT", priceText, "LEFT", -8, 0)
        nameText:SetJustifyH("LEFT")
        MerchantMenu:ApplyFont(nameText, FONTS.bodyBold, 16)
        row.nameText = nameText

        row.slotIndex = i
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function()
            local itemIdx = (MerchantMenu.bagScrollOffset or 0) + this.slotIndex
            local wasSelected = (MerchantMenu.activeColumn == "BAGS" and MerchantMenu.selectedBagIndex == itemIdx)
            MerchantMenu.activeColumn = "BAGS"
            MerchantMenu.selectedBagIndex = itemIdx
            MerchantMenu:UpdateColumnVisuals()
            MerchantMenu:UpdateBagRows()

            if arg1 == "RightButton" or (arg1 == "LeftButton" and wasSelected) then
                MerchantMenu:SellSelectedItem()
            else
                PlaySound("igMainMenuOptionCheckBoxOn")
            end
        end)

        row:SetScript("OnEnter", function()
            local itemIdx = (MerchantMenu.bagScrollOffset or 0) + this.slotIndex
            if MerchantMenu.activeColumn ~= "BAGS" or (MerchantMenu.selectedBagIndex ~= itemIdx) then
                this:SetBackdropBorderColor(0.70, 0.60, 0.40, 0.80)
            end
        end)

        row:SetScript("OnLeave", function()
            local itemIdx = (MerchantMenu.bagScrollOffset or 0) + this.slotIndex
            if MerchantMenu.activeColumn == "BAGS" and itemIdx == MerchantMenu.selectedBagIndex then
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

-- Espelho de CreateBagRows para a LOJA (Fase 5). Mesma identidade visual.
function MerchantMenu:CreateVendorRows(parent)
    local rows = {}
    for i = 1, 7 do
        local row = CreateFrame("Button", "ConsoleMode_MerchantVendorRow" .. i, parent)
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
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.30)
        hl:SetAllPoints(row)
        hl:Hide()
        row.highlight = hl
        local cur = row:CreateTexture(nil, "OVERLAY")
        cur:SetWidth(12)
        cur:SetHeight(12)
        cur:SetPoint("LEFT", row, "LEFT", 4, 0)
        cur:SetTexture("Interface\\QuestFrame\\UI-Quest-BulletPoint")
        cur:SetVertexColor(1.0, 0.85, 0.20)
        cur:Hide()
        row.cursor = cur
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
        local stackText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        stackText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
        MerchantMenu:ApplyFont(stackText, FONTS.titleBold, 13, "OUTLINE")
        row.stackText = stackText
        local priceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        priceText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        priceText:SetJustifyH("RIGHT")
        MerchantMenu:ApplyFont(priceText, FONTS.titleBold, 15)
        row.priceText = priceText
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        nameText:SetPoint("RIGHT", priceText, "LEFT", -8, 0)
        nameText:SetJustifyH("LEFT")
        MerchantMenu:ApplyFont(nameText, FONTS.bodyBold, 16)
        row.nameText = nameText
        row.slotIndex = i
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function()
            local itemIdx = (MerchantMenu.vendorScrollOffset or 0) + this.slotIndex
            local wasSelected = (MerchantMenu.activeColumn == "VENDOR" and MerchantMenu.selectedVendorIndex == itemIdx)
            MerchantMenu.activeColumn = "VENDOR"
            MerchantMenu.selectedVendorIndex = itemIdx
            MerchantMenu:UpdateColumnVisuals()
            MerchantMenu:UpdateVendorRows()
            if wasSelected then
                MerchantMenu:BuySelectedItem()
            else
                PlaySound("igMainMenuOptionCheckBoxOn")
            end
        end)
        row:SetScript("OnEnter", function()
            local itemIdx = (MerchantMenu.vendorScrollOffset or 0) + this.slotIndex
            if MerchantMenu.activeColumn ~= "VENDOR" or (MerchantMenu.selectedVendorIndex ~= itemIdx) then
                this:SetBackdropBorderColor(0.70, 0.60, 0.40, 0.80)
            end
        end)
        row:SetScript("OnLeave", function()
            local itemIdx = (MerchantMenu.vendorScrollOffset or 0) + this.slotIndex
            if MerchantMenu.activeColumn == "VENDOR" and itemIdx == MerchantMenu.selectedVendorIndex then
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

function MerchantMenu:CreateUI()
    if self.frame then return end

    -- Dimmer de fundo (Imersão console)
    self:CreateDimmer()

    -- Janela Principal (Sem transparência, 9-slice esculpido oficial)
    local frame = CreateFrame("Frame", "ConsoleMode_MerchantFrame", UIParent)
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

    table.insert(UISpecialFrames, "ConsoleMode_MerchantFrame")
    frame:SetScript("OnHide", function()
        if MerchantMenu.isOpen then
            MerchantMenu:Close()
        end
    end)

    self.frame = frame

    -- Título Superior Central (+20%: 19 -> 23)
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", frame, "TOP", 0, -20)
    self:ApplyFont(titleText, FONTS.titleBold, 23)
    titleText:SetText("|cffe09a15COMÉRCIO & REPAROS|r")
    frame.titleText = titleText

    -- Barra de Cabeçalho (Nome do NPC, Saldo de Moedas e Botão Sair)
    local header = CreateFrame("Frame", "ConsoleMode_MerchantHeader", frame)
    header:SetHeight(32)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -18)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -18)
    frame.header = header

    -- Nome do NPC (+20%: 16 -> 19)
    local npcNameText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    npcNameText:SetPoint("LEFT", header, "LEFT", 0, 0)
    self:ApplyFont(npcNameText, FONTS.titleBold, 19)
    npcNameText:SetText("|cffffffffVendedor|r")
    header.npcNameText = npcNameText

    -- Saldo de Moedas (+20%: 15 -> 18)
    local playerMoneyText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playerMoneyText:SetPoint("RIGHT", header, "RIGHT", -110, 0)
    self:ApplyFont(playerMoneyText, FONTS.titleBold, 18)
    playerMoneyText:SetText("0g 0s 0c")
    header.playerMoneyText = playerMoneyText

    -- Botão Sair com estilo do MainMenu
    local closeBtn = CreateFrame("Button", "ConsoleMode_MerchantCloseBtn", header)
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
        MerchantMenu:Close()
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

    -- DetailCard Inferior
    local detailCard = self:CreateDetailCard(frame)
    frame.detailCard = detailCard

    -- Barra de Rodapé com Atalhos do Controle
    self:CreateFooterHints(frame)

    -- Área Central de Conteúdo Split-View
    local contentArea = CreateFrame("Frame", "ConsoleMode_MerchantContentArea", frame)
    contentArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -54)
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 210)
    frame.contentArea = contentArea

    -- Divisória Central Vertical
    local divider = frame:CreateTexture("ConsoleMode_MerchantDivider", "ARTWORK")
    divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetWidth(2)
    divider:SetVertexColor(0.6, 0.5, 0.3, 0.4)
    divider:SetPoint("TOP", contentArea, "TOP", 0, 0)
    divider:SetPoint("BOTTOM", contentArea, "BOTTOM", 0, 0)
    divider:SetPoint("CENTER", contentArea, "CENTER", 0, 0)
    frame.divider = divider

    -- Helper para construir coluna
    local function CreateColumnPanel(name, titleText, iconTag)
        local col = CreateFrame("Frame", name, contentArea)
        col:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 12,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        col:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
        col:SetBackdropBorderColor(0.50, 0.40, 0.28, 0.65)

        -- Cabeçalho da Coluna (Ícones +35%: 22 -> 30px, Texto +20%: 15 -> 18px)
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
        MerchantMenu:ApplyFont(colTitle, FONTS.titleBold, 18)
        colTitle:SetText(titleText)
        col.title = colTitle

        -- Barra de Sub-abas de Filtro (Ícones +35%: 20 -> 27px, Texto +20%: 14 -> 17px)
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
        MerchantMenu:ApplyFont(tabsLabel, FONTS.titleBold, 17)
        tabsLabel:SetText("|cffe09a15[ Todos ]|r   |cff848484[ Equipamentos ]|r   |cff848484[ Consumíveis ]|r")
        col.tabsLabel = tabsLabel

        -- Divisória abaixo das abas
        local cDiv = col:CreateTexture(nil, "ARTWORK")
        cDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        cDiv:SetHeight(1)
        cDiv:SetPoint("TOPLEFT", subTabBar, "BOTTOMLEFT", 2, -2)
        cDiv:SetPoint("TOPRIGHT", subTabBar, "BOTTOMRIGHT", -2, -2)
        cDiv:SetVertexColor(0.5, 0.4, 0.3, 0.35)

        -- Barra Inferior de Status / Paginação
        local statusBar = CreateFrame("Frame", nil, col)
        statusBar:SetHeight(24)
        statusBar:SetPoint("BOTTOMLEFT", col, "BOTTOMLEFT", 8, 6)
        statusBar:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", -8, 6)
        col.statusBar = statusBar

        local pageIndicator = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        pageIndicator:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
        MerchantMenu:ApplyFont(pageIndicator, FONTS.medium, 14)
        col.pageIndicator = pageIndicator

        -- Área interna de Lista
        local listArea = CreateFrame("Frame", nil, col)
        listArea:SetPoint("TOPLEFT", cDiv, "BOTTOMLEFT", 0, -4)
        listArea:SetPoint("BOTTOMRIGHT", statusBar, "TOPRIGHT", 0, 2)
        listArea:EnableMouseWheel(true)
        col.listArea = listArea

        local placeholder = listArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        placeholder:SetPoint("CENTER", listArea, "CENTER", 0, 0)
        MerchantMenu:ApplyFont(placeholder, FONTS.medium, 16)
        col.placeholder = placeholder

        return col
    end

    -- Coluna Esquerda: Vendedor
    local leftCol = CreateColumnPanel("ConsoleMode_MerchantColLeft", "LOJA DO VENDEDOR", ICONS.LB)
    leftCol:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
    leftCol:SetPoint("BOTTOMLEFT", contentArea, "BOTTOMLEFT", 0, 0)
    leftCol:SetPoint("RIGHT", divider, "LEFT", -6, 0)
    leftCol.placeholder:SetText("|cffe09a15[ Catálogo do Vendedor ]|r\n\n|cffaaaaaaSincronizando itens com o servidor...|r\n|cff666666(Fase 4: Exibição completa da loja)|r")
    leftCol.pageIndicator:SetText("|cff888888Catálogo do Vendedor|r")
    frame.leftCol = leftCol

    leftCol.header:EnableMouse(true)
    leftCol.header:SetScript("OnMouseDown", function()
        if MerchantMenu.activeColumn ~= "VENDOR" then
            MerchantMenu:ToggleColumn(-1)
        end
    end)

    -- Coluna Direita: Inventário
    local rightCol = CreateColumnPanel("ConsoleMode_MerchantColRight", "SEU INVENTÁRIO", ICONS.RB)
    rightCol:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", 0, 0)
    rightCol:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    rightCol:SetPoint("LEFT", divider, "RIGHT", 6, 0)
    frame.rightCol = rightCol

    rightCol.header:EnableMouse(true)
    rightCol.header:SetScript("OnMouseDown", function()
        if MerchantMenu.activeColumn ~= "BAGS" then
            MerchantMenu:ToggleColumn(1)
        end
    end)

    -- Cria as 7 linhas do inventário na coluna direita
    self:CreateBagRows(rightCol.listArea)

    -- Cria as 7 linhas da LOJA na coluna esquerda (Fase 5)
    self:CreateVendorRows(leftCol.listArea)
    if leftCol.ltBtn then
        leftCol.ltBtn:SetScript("OnClick", function()
            if MerchantMenu.activeColumn ~= "VENDOR" then
                MerchantMenu.activeColumn = "VENDOR"
                MerchantMenu:UpdateColumnVisuals()
            end
            MerchantMenu:CycleSubTab(-1)
        end)
    end
    if leftCol.rtBtn then
        leftCol.rtBtn:SetScript("OnClick", function()
            if MerchantMenu.activeColumn ~= "VENDOR" then
                MerchantMenu.activeColumn = "VENDOR"
                MerchantMenu:UpdateColumnVisuals()
            end
            MerchantMenu:CycleSubTab(1)
        end)
    end
    leftCol.listArea:SetScript("OnMouseWheel", function()
        if arg1 > 0 then MerchantMenu:MoveVendorSelection(-1) else MerchantMenu:MoveVendorSelection(1) end
    end)

    -- Ações dos botões [LT] e [RT] da coluna direita
    if rightCol.ltBtn then
        rightCol.ltBtn:SetScript("OnClick", function()
            MerchantMenu:CycleSubTab(-1)
        end)
    end
    if rightCol.rtBtn then
        rightCol.rtBtn:SetScript("OnClick", function()
            MerchantMenu:CycleSubTab(1)
        end)
    end

    -- Rolagem com a roda do mouse na lista de bolsas
    rightCol.listArea:SetScript("OnMouseWheel", function()
        local delta = arg1
        if delta > 0 then
            MerchantMenu:MoveBagSelection(-1)
        else
            MerchantMenu:MoveBagSelection(1)
        end
    end)
end

-- ----------------------------------------------------------------------------
-- 8. ATUALIZAÇÃO DE LAYOUT & ATUALIZAÇÃO DAS LINHAS DO INVENTÁRIO (FASE 3)
-- ----------------------------------------------------------------------------
function MerchantMenu:UpdateLayout()
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

function MerchantMenu:RefreshHeader()
    if not self.frame then return end

    local npcName = self.currentNPC or UnitName("npc") or "Vendedor"
    if self.frame.header and self.frame.header.npcNameText then
        self.frame.header.npcNameText:SetText("|cffffffff" .. npcName .. "|r")
    end

    local playerMoney = GetMoney() or 0
    if self.frame.header and self.frame.header.playerMoneyText then
        self.frame.header.playerMoneyText:SetText(self:FormatMoneyText(playerMoney))
    end

    if self.footerRepairWidget then
        if self.canRepair then
            self.footerRepairWidget:Show()
        else
            self.footerRepairWidget:Hide()
        end
    end
end

function MerchantMenu:UpdateColumnVisuals()
    if not self.frame then return end

    local leftCol  = self.frame.leftCol
    local rightCol = self.frame.rightCol
    if not leftCol or not rightCol then return end

    if self.activeColumn == "BAGS" then
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
end

function MerchantMenu:UpdateBagRows()
    local rightCol = self.frame and self.frame.rightCol
    if not rightCol or not rightCol.listArea or not rightCol.listArea.rows then return end

    local rows = rightCol.listArea.rows
    local filtered = self.filteredBagItems or {}
    local numItems = table.getn(filtered)

    if numItems == 0 then
        for i = 1, 7 do
            rows[i]:Hide()
        end
        rightCol.placeholder:SetText("|cffaaaaaaNenhum item encontrado nesta categoria.|r")
        rightCol.placeholder:Show()
        rightCol.pageIndicator:SetText("|cff666666Nenhum item|r")
        if self.activeColumn == "BAGS" then
            self:ShowItemDetail(nil)
        end
        return
    end

    rightCol.placeholder:Hide()

    local selectedItem = nil
    for slotIdx = 1, 7 do
        local itemIdx = (self.bagScrollOffset or 0) + slotIdx
        local row = rows[slotIdx]

        if itemIdx <= numItems then
            local item = filtered[itemIdx]
            local qColor = QUALITY_COLORS[item.quality or 1] or QUALITY_COLORS[1]

            row.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.iconBorder:SetBackdropBorderColor(qColor.r, qColor.g, qColor.b, 0.85)

            if item.count and item.count > 1 then
                row.stackText:SetText(item.count)
                row.stackText:Show()
            else
                row.stackText:Hide()
            end

            row.nameText:SetText(qColor.hex .. (item.name or "Item") .. "|r")

            if item.sellPrice and item.sellPrice > 0 then
                row.priceText:SetText(self:FormatMoneyText(item.sellPrice))
            else
                row.priceText:SetText("|cff666666Sem valor|r")
            end

            -- Linha selecionada
            if self.activeColumn == "BAGS" and itemIdx == self.selectedBagIndex then
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
            end

            row:Show()
        else
            row:Hide()
        end
    end

    -- Atualiza o indicador de posição / página no rodapé da coluna
    local curPage = math.floor((self.selectedBagIndex - 1) / 7) + 1
    local totalPages = math.ceil(numItems / 7)
    if totalPages < 1 then totalPages = 1 end

    local arrowUp = (self.bagScrollOffset > 0) and "▲ " or ""
    local arrowDown = ((self.bagScrollOffset + 7) < numItems) and " ▼" or ""
    rightCol.pageIndicator:SetText(string.format("%s|cffaaaaaaItem %d de %d|r  |cff888888(Pág. %d/%d)|r%s", arrowUp, self.selectedBagIndex, numItems, curPage, totalPages, arrowDown))

    if self.activeColumn == "BAGS" then
        self:ShowItemDetail(selectedItem)
    end
end

-- Render da loja (Fase 5). Segue padrão de UpdateBagRows.
function MerchantMenu:UpdateVendorRows()
    local leftCol = self.frame and self.frame.leftCol
    if not leftCol or not leftCol.listArea or not leftCol.listArea.rows then return end
    local rows = leftCol.listArea.rows
    local filtered = self.filteredVendorItems or {}
    local numItems = table.getn(filtered)
    if numItems == 0 then
        for i = 1, 7 do rows[i]:Hide() end
        leftCol.placeholder:SetText("|cffaaaaaaNenhum item à venda nesta categoria.|r")
        leftCol.placeholder:Show()
        leftCol.pageIndicator:SetText("|cff666666Loja vazia|r")
        if self.activeColumn == "VENDOR" then self:ShowItemDetail(nil) end
        return
    end
    leftCol.placeholder:Hide()
    local selectedItem = nil
    for slotIdx = 1, 7 do
        local itemIdx = (self.vendorScrollOffset or 0) + slotIdx
        local row = rows[slotIdx]
        if itemIdx <= numItems then
            local item = filtered[itemIdx]
            local qColor = QUALITY_COLORS[item.quality or 1] or QUALITY_COLORS[1]
            row.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.iconBorder:SetBackdropBorderColor(qColor.r, qColor.g, qColor.b, 0.85)
            if item.count and item.count > 1 then
                row.stackText:SetText(item.count)
                row.stackText:Show()
            else
                row.stackText:Hide()
            end
            local nameStr = qColor.hex .. (item.name or "Item") .. "|r"
            if item.isBuyback then
                nameStr = nameStr .. " |cff888888(Recompra)|r"
            elseif item.numAvailable and item.numAvailable >= 0 then
                nameStr = nameStr .. " |cffffd700(x" .. item.numAvailable .. ")|r"
            end
            row.nameText:SetText(nameStr)
            if item.price and item.price > 0 then
                local affordable = (GetMoney() or 0) >= item.price
                if affordable then
                    row.priceText:SetText(self:FormatMoneyText(item.price))
                else
                    row.priceText:SetText("|cffff2020" .. self:FormatMoneyText(item.price) .. "|r")
                end
            else
                row.priceText:SetText("|cff666666Sem preço|r")
            end
            if self.activeColumn == "VENDOR" and itemIdx == self.selectedVendorIndex then
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
            end
            row:Show()
        else
            row:Hide()
        end
    end
    local curPage = math.floor((self.selectedVendorIndex - 1) / 7) + 1
    local totalPages = math.ceil(numItems / 7)
    if totalPages < 1 then totalPages = 1 end
    local arrowUp = (self.vendorScrollOffset > 0) and "▲ " or ""
    local arrowDown = ((self.vendorScrollOffset + 7) < numItems) and " ▼" or ""
    leftCol.pageIndicator:SetText(string.format("%s|cffaaaaaaItem %d de %d|r  |cff888888(Pág. %d/%d)|r%s", arrowUp, self.selectedVendorIndex, numItems, curPage, totalPages, arrowDown))
    if self.activeColumn == "VENDOR" then
        self:ShowItemDetail(selectedItem)
    end
end

-- ----------------------------------------------------------------------------
-- ITEM COMPARE (Fase 6 - reusa MainMenu quando disponível, fallback simples)
-- ----------------------------------------------------------------------------
function MerchantMenu:ParseSimpleStats(itemLink)
    local acc = { str = 0, agi = 0, sta = 0, int = 0, spi = 0 }
    if not itemLink or not scanTip then return acc end
    scanTip:ClearLines()
    local ok = false
    local _, _, raw = string.find(itemLink, "(item:%d+:%d+:%d+:%d+)")
    if raw then ok = pcall(function() scanTip:SetHyperlink(raw) end) end
    if not ok then ok = pcall(function() scanTip:SetHyperlink(itemLink) end) end
    if not ok then return acc end
    local nl = scanTip:NumLines() or 0
    for l = 2, nl do
        local lo = getglobal("ConsoleMode_MerchantScanTipTextLeft" .. l)
        local t = nil
        if lo then t = lo:GetText() end
        if t and t ~= "" then
            local _, _, v = string.find(t, "^%+(%d+)%s+For")
            if v then
                acc.str = acc.str + (tonumber(v) or 0)
            else
                local _, _, v2 = string.find(t, "^%+(%d+)%s+Agilidade")
                if v2 then
                    acc.agi = acc.agi + (tonumber(v2) or 0)
                else
                    local _, _, v3 = string.find(t, "^%+(%d+)%s+Vigor")
                    if v3 then
                        acc.sta = acc.sta + (tonumber(v3) or 0)
                    else
                        local _, _, v4 = string.find(t, "^%+(%d+)%s+Intelecto")
                        if v4 then
                            acc.int = acc.int + (tonumber(v4) or 0)
                        else
                            local _, _, v5 = string.find(t, "^%+(%d+)%s+Esp")
                            if v5 then acc.spi = acc.spi + (tonumber(v5) or 0) end
                        end
                    end
                end
            end
        end
    end
    return acc
end

function MerchantMenu:ResolveEquippedLink(item)
    if not item then return nil end
    local eq = item.equipLoc or ""
    if eq == "" and item.link and GetItemInfo then
        local _, _, _, _, _, eqL = self:ResolveItemInfo(item.link)
        if eqL then eq = eqL end
    end
    if eq == "" or eq == "INVTYPE_NON_EQUIP" or eq == "INVTYPE_BAG" then return nil end
    local MM = nil
    if ConsoleMode then MM = ConsoleMode.mainMenu end
    if MM and MM.GetCompareSlotForEquipLoc then
        local ok, slot = pcall(function() return MM:GetCompareSlotForEquipLoc(eq) end)
        if ok and slot then
            if type(slot) == "table" then
                if table.getn(slot) > 0 then
                    return GetInventoryItemLink("player", slot[1]), nil
                end
                return nil
            else
                return GetInventoryItemLink("player", slot), nil
            end
        end
    end
    return nil
end

function MerchantMenu:FormatCompareDiffs(item)
    if not item then return "", nil end
    local eqLoc = item.equipLoc or ""
    if type(eqLoc) ~= "string" or string.find(eqLoc, "^INVTYPE_") == nil then
        return "", nil
    end
    if eqLoc == "" or eqLoc == "INVTYPE_NON_EQUIP" or eqLoc == "INVTYPE_BAG" then
        return "", nil
    end
    local MM = nil
    if ConsoleMode then MM = ConsoleMode.mainMenu end
    if MM and MM.ComputeCompareDiff then
        local ok, cmp = pcall(function() return MM:ComputeCompareDiff(item) end)
        if ok and cmp and cmp.diffs then
            local up, down = 0, 0
            for k, v in pairs(cmp.diffs) do
                v = tonumber(v) or 0
                if v > 0 then up = up + 1 end
                if v < 0 then down = down + 1 end
            end
            if up == 0 and down == 0 then return "", nil end
            local txt = ""
            if MM.FormatCompareDiffDebug then
                local ok2, t2 = pcall(function() return MM:FormatCompareDiffDebug(cmp.diffs) end)
                if ok2 and t2 then txt = t2 end
            end
            if txt == "" then
                if up > 0 and down == 0 then txt = "|cff1eff00[Melhoria]|r" end
                if down > 0 and up == 0 then txt = "|cffff2020[Pior]|r" end
            end
            local vs = ""
            if cmp.vsName and cmp.vsName ~= "" then vs = "  |cff888888(vs. " .. cmp.vsName .. ")|r" end
            local verdict = nil
            if up > 0 and down == 0 then verdict = true end
            if down > 0 and up == 0 then verdict = false end
            return "|cffaaaaaaComparar:|r " .. txt .. vs, verdict
        end
    end
    local eqLink = self:ResolveEquippedLink(item)
    if not eqLink then
        return "|cff1eff00[Melhoria]|r |cffaaaaaa(slot vazio)|r", true
    end
    local newS = self:ParseSimpleStats(item.link)
    local oldS = self:ParseSimpleStats(eqLink)
    local keys = { "str", "agi", "sta", "int", "spi" }
    local labels = { "For", "Agi", "Vig", "Int", "Esp" }
    local parts = {}
    local up, down = 0, 0
    local numKeys = table.getn(keys)
    for i = 1, numKeys do
        local k = keys[i]
        local d = (tonumber(newS[k]) or 0) - (tonumber(oldS[k]) or 0)
        if d ~= 0 then
            if d > 0 then
                up = up + 1
                table.insert(parts, "|cff1eff00" .. labels[i] .. " +" .. d .. "|r")
            else
                down = down + 1
                table.insert(parts, "|cffff2020" .. labels[i] .. " " .. d .. "|r")
            end
        end
    end
    if table.getn(parts) == 0 then return "", nil end
    local eqName = GetItemInfo(eqLink) or "equipado"
    local verdict = nil
    if up > 0 and down == 0 then verdict = true end
    if down > 0 and up == 0 then verdict = false end
    return "|cffaaaaaaComparar:|r " .. table.concat(parts, " ") .. "  |cff888888(vs. " .. eqName .. ")|r", verdict
end

function MerchantMenu:ApplyCompareToCard(item)
    local card = self.frame and self.frame.detailCard
    if not card then return end
    if not item then
        card:SetBackdropBorderColor(0.50, 0.40, 0.28, 0.65)
        return
    end
    local line, verdict = self:FormatCompareDiffs(item)
    if line and line ~= "" then
        local cur = ""
        if card.descColRight and card.descColRight.GetText then
            local ok, t = pcall(function() return card.descColRight:GetText() end)
            if ok and t then cur = t end
        end
        card.descColRight:SetText(cur .. "\n" .. line)
    end
    if verdict == true then
        card:SetBackdropBorderColor(0.12, 1.00, 0.00, 0.95)
    elseif verdict == false then
        card:SetBackdropBorderColor(1.00, 0.13, 0.13, 0.95)
    end
    self.compareState.lastKey = item.link or item.name
    self.compareState.isUpgrade = verdict
end

function MerchantMenu:ShowItemDetail(item)
    local card = self.frame and self.frame.detailCard
    if not card then return end

    if not item then
        card.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        card.iconBorder:SetBackdropBorderColor(0.40, 0.35, 0.25, 0.60)
        card.titleText:SetText("|cff888888Nenhum item selecionado|r")
        card.priceText:SetText("")
        card.typeText:SetText("|cff666666Navegue pelas bolsas usando o direcional [D-Pad]|r")
        card.descColLeft:SetText("|cff666666Suas bolsas estão vazias ou a categoria selecionada não possui itens.|r")
        card.descColRight:SetText("")
        if card.useText then
            card.useText:SetText("")
            card.useText:Hide()
        end
        return
    end

    local qColor = QUALITY_COLORS[item.quality or 1] or QUALITY_COLORS[1]

    card.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    card.iconBorder:SetBackdropBorderColor(qColor.r, qColor.g, qColor.b, 0.90)

    local countStr = (item.count and item.count > 1) and (" |cffffffff(x" .. item.count .. ")|r") or ""
    card.titleText:SetText(qColor.hex .. item.name .. "|r" .. countStr)

    -- Preço no DetailCard (venda da bolsa ou compra da loja)
    if item.sellPrice and item.sellPrice > 0 then
        local priceStr = "|cffaaaaaaPreço de Venda: |r" .. self:FormatMoneyText(item.sellPrice)
        if item.count and item.count > 1 then
            local unit = math.floor(item.sellPrice / item.count)
            if unit > 0 then
                priceStr = priceStr .. " |cff888888(" .. self:FormatMoneyText(unit) .. " cada)|r"
            end
        end
        card.priceText:SetText(priceStr)
    elseif item.price and item.price > 0 then
        local extra = ""
        if item.isBuyback then
            extra = " |cffffd700(Recompra)|r"
        elseif item.numAvailable and item.numAvailable >= 0 then
            extra = " |cffaaaaaa(estoque: " .. item.numAvailable .. ")|r"
        end
        card.priceText:SetText("|cffaaaaaaPreço de Compra: |r" .. self:FormatMoneyText(item.price) .. extra)
    else
        card.priceText:SetText("|cff888888Sem valor de venda comercial|r")
    end

    -- Subtítulo: Tipo • Subtipo • Slot • Requisito
    local typeParts = {}
    if item.itemType and item.itemType ~= "" then table.insert(typeParts, item.itemType) end
    if item.subType and item.subType ~= "" then table.insert(typeParts, item.subType) end
    if item.equipLoc and item.equipLoc ~= "" then
        local eq = item.equipLoc
        if type(eq) == "string" and string.find(eq, "^INVTYPE_") then
            local slotText = getglobal(eq)
            if type(slotText) == "string" and slotText ~= "" then
                table.insert(typeParts, slotText)
            end
        end
    end
    if item.reqLevel and item.reqLevel > 0 then
        local pLvl = UnitLevel("player") or 1
        local reqColor = (item.reqLevel > pLvl) and "|cffff2020" or "|cffffffff"
        table.insert(typeParts, reqColor .. "Requer Nível " .. item.reqLevel .. "|r")
    end

    local subStr = table.concat(typeParts, "  •  ")
    if subStr == "" then subStr = "Item do Inventário" end
    card.typeText:SetText("|cffb0b0b0" .. subStr .. "|r")

    -- Linha dedicada de Uso (campo proprio abaixo do subtipo): usa item.desc;
    -- se vazio, tenta um re-scan fresco via hyperlink antes de desistir.
    if (not item.desc or item.desc == "") and item.link then
        local fresh = self:ScanUseLineFresh(item.link)
        if fresh and fresh ~= "" then item.desc = fresh end
    end
    if card.useText then
        if item.desc and item.desc ~= "" then
            card.useText:SetText("|cff00ff00" .. item.desc .. "|r")
            card.useText:Show()
        else
            card.useText:SetText("")
            card.useText:Hide()
        end
    end

    -- 2 Colunas de Descrição / Atributos
    local leftLines = {}
    local rightLines = {}

    local numStats = table.getn(item.statsLines or {})
    local half = math.ceil(numStats / 2)
    if half < 1 then half = 1 end

    for i = 1, numStats do
        if i <= half then
            table.insert(leftLines, item.statsLines[i])
        else
            table.insert(rightLines, item.statsLines[i])
        end
    end

    -- (A linha de Uso/Efeito agora mora no campo dedicado card.useText.)

    local leftText = table.concat(leftLines, "\n")
    local rightText = table.concat(rightLines, "\n")

    if leftText == "" then
        leftText = "|cff888888Nenhum atributo adicional.|r"
    end
    if rightText == "" then
        if item.sellPrice and item.sellPrice > 0 then
            rightText = "|cff888888Pronto para venda no vendedor.|r\n|cffaaaaaaPressione [X] para vender.|r"
        elseif item.price and item.price > 0 then
            rightText = "|cff888888Pressione [A] para comprar 1x.|r\n|cffaaaaaaPressione [X] para quantidade.|r"
        else
            rightText = "|cff666666Item sem preço de compra em mercadores.|r"
        end
    end

    card.descColLeft:SetText(leftText)
    card.descColRight:SetText(rightText)
    self:ApplyCompareToCard(item)
end

function MerchantMenu:ShowVendorPlaceholderDetail()
    local card = self.frame and self.frame.detailCard
    if not card then return end

    card.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    card.iconBorder:SetBackdropBorderColor(0.50, 0.40, 0.30, 0.80)
    card.titleText:SetText("|cffe09a15Loja do Vendedor (" .. (self.itemCount or 0) .. " itens)|r")
    card.priceText:SetText("|cffaaaaaaPressione [RB] para o seu Inventário|r")
    card.typeText:SetText("|cff888888Fase 4: Catálogo Completo do Vendedor|r")
    card.descColLeft:SetText("|cffccccccOs itens à venda pelo NPC serão listados aqui na próxima fase.|r\n|cffaaaaaaVocê poderá comprar itens usando o botão [A].|r")
    card.descColRight:SetText("|cff888888Pressione [RB] no controle ou clique na coluna da direita para voltar a inspecionar seu inventário.|r")
    if card.useText then
        card.useText:SetText("")
        card.useText:Hide()
    end
end

-- ----------------------------------------------------------------------------
-- 9. NAVEGAÇÃO POR GAMEPAD / DIRECIONAIS (FASE 3)
-- ----------------------------------------------------------------------------
function MerchantMenu:MoveBagSelection(delta)
    local numItems = table.getn(self.filteredBagItems or {})
    if numItems == 0 then return end

    local newIdx = (self.selectedBagIndex or 1) + delta
    if newIdx < 1 then
        newIdx = 1
    elseif newIdx > numItems then
        newIdx = numItems
    end

    if newIdx ~= self.selectedBagIndex then
        self.selectedBagIndex = newIdx
        PlaySound("igMainMenuOptionCheckBoxOn")

        local visibleRows = 7
        if self.selectedBagIndex <= self.bagScrollOffset then
            self.bagScrollOffset = self.selectedBagIndex - 1
        elseif self.selectedBagIndex > (self.bagScrollOffset + visibleRows) then
            self.bagScrollOffset = self.selectedBagIndex - visibleRows
        end
        if self.bagScrollOffset < 0 then
            self.bagScrollOffset = 0
        end
        local maxOffset = math.max(0, numItems - visibleRows)
        if self.bagScrollOffset > maxOffset then
            self.bagScrollOffset = maxOffset
        end

        self:UpdateBagRows()
    end
end

function MerchantMenu:ToggleColumn(delta)
    local targetCol = nil
    if delta == -1 then
        if self.activeColumn == "VENDOR" then
            targetCol = "BAGS"
        else
            targetCol = "VENDOR"
        end
    elseif delta == 1 then
        if self.activeColumn == "BAGS" then
            targetCol = "VENDOR"
        else
            targetCol = "BAGS"
        end
    else
        if self.activeColumn == "BAGS" then
            targetCol = "VENDOR"
        else
            targetCol = "BAGS"
        end
    end

    self.activeColumn = targetCol
    PlaySound("igCharacterInfoTab")
    self:UpdateColumnVisuals()
    self:UpdateBagRows()
    self:UpdateVendorRows()

    if self.activeColumn == "VENDOR" then
        local sel = self.filteredVendorItems and self.filteredVendorItems[self.selectedVendorIndex]
        self:ShowItemDetail(sel)
    end
end

function MerchantMenu:CycleSubTab(delta)
    if not self.isOpen then return end

    -- Salto entre colunas: qualquer troca de coluna cai na aba TODOS (indice 1).
    -- VENDEDOR(Todos/Equip/Consum/Recompra) <-> BOLSAS(Todos/Equip/Consum/Lixo).
    -- BOLSAS Todos + LEFT => VENDEDOR Todos | VENDEDOR Todos + LEFT => BOLSAS Todos.
    local function JumpToColumn(newColumn, newSubIdx)
        self.activeColumn = newColumn
        if newColumn == "VENDOR" then
            self.vendorSubTabIdx = newSubIdx
            self.selectedVendorIndex = 1
            self.vendorScrollOffset = 0
        else
            self.bagSubTabIdx = newSubIdx
            self.selectedBagIndex = 1
            self.bagScrollOffset = 0
        end
        PlaySound("igCharacterInfoTab")
        self:UpdateBagsSubTabBar()
        self:UpdateVendorSubTabBar()
        self:UpdateColumnVisuals()
        self:FilterBagItems()
        self:FilterVendorItems()
        self.selectedBagIndex = math.max(1, math.min(self.selectedBagIndex or 1, math.max(1, table.getn(self.filteredBagItems or {}))))
        self.selectedVendorIndex = math.max(1, math.min(self.selectedVendorIndex or 1, math.max(1, table.getn(self.filteredVendorItems or {}))))
        self:UpdateBagRows()
        self:UpdateVendorRows()
    end

    if self.activeColumn == "BAGS" then
        local count = table.getn(SUBTABS_BAGS)
        local nextIdx = self.bagSubTabIdx + delta
        if nextIdx > count then
            JumpToColumn("VENDOR", 1)
            return
        end
        if nextIdx < 1 then
            JumpToColumn("VENDOR", 1)
            return
        end
        self.bagSubTabIdx = nextIdx
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:UpdateBagsSubTabBar()
        self:FilterBagItems()
        self.selectedBagIndex = 1
        self.bagScrollOffset = 0
        self:UpdateBagRows()
    else
        -- VENDOR: Todos / Equip / Consum / Recompra (Fase 5/6)
        local count = table.getn(SUBTABS_VENDOR)
        local nextIdx = self.vendorSubTabIdx + delta
        if nextIdx > count then
            JumpToColumn("BAGS", 1)
            return
        end
        if nextIdx < 1 then
            JumpToColumn("BAGS", 1)
            return
        end
        self.vendorSubTabIdx = nextIdx
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:UpdateVendorSubTabBar()
        self:FilterVendorItems()
        self.selectedVendorIndex = 1
        self.vendorScrollOffset = 0
        self:UpdateVendorRows()
    end
end

function MerchantMenu:OnDirection(direction)
    if not self.isOpen then return end

    if self:IsQtyModalOpen() then
        if direction == "LEFT" then self:QtyModalAdjust(-1) return end
        if direction == "RIGHT" then self:QtyModalAdjust(1) return end
        if direction == "UP" then self:QtyModalAdjust(5) return end
        if direction == "DOWN" then self:QtyModalAdjust(-5) return end
        return
    end

    if direction == "LEFT" then
        self:CycleSubTab(-1)
    elseif direction == "RIGHT" then
        self:CycleSubTab(1)
    elseif direction == "UP" then
        if self.activeColumn == "BAGS" then
            self:MoveBagSelection(-1)
        else
            self:MoveVendorSelection(-1)
        end
    elseif direction == "DOWN" then
        if self.activeColumn == "BAGS" then
            self:MoveBagSelection(1)
        else
            self:MoveVendorSelection(1)
        end
    end
end

-- Hold-to-scroll: passo imediato + repeticao continua via OnUpdate (somente UP/DOWN).
function MerchantMenu:StartRepeat(direction)
    if not self.isOpen then return end
    if direction == "UP" or direction == "DOWN" then
        self:OnDirection(direction)
        self.repeatState.direction = direction
        self.repeatState.timer = self.repeatState.initialDelay
        self:EnsureRepeatTicker()
    else
        -- LEFT/RIGHT: passo unico, sem repeat (evita spam de abas)
        self.repeatState.direction = nil
        self.repeatState.timer = 0
        self:OnDirection(direction)
    end
end

function MerchantMenu:StopRepeat(direction)
    if not direction or self.repeatState.direction == direction then
        self.repeatState.direction = nil
        self.repeatState.timer = 0
    end
end

function MerchantMenu:EnsureRepeatTicker()
    if self.repeatFrame then return end
    local f = CreateFrame("Frame", "ConsoleMode_MerchantRepeatTicker")
    f:SetScript("OnUpdate", function()
        if not MerchantMenu.isOpen then
            MerchantMenu.repeatState.direction = nil
            return
        end
        local dir = MerchantMenu.repeatState.direction
        if dir then
            local elapsed = arg1 or 0.016
            MerchantMenu.repeatState.timer = MerchantMenu.repeatState.timer - elapsed
            if MerchantMenu.repeatState.timer <= 0 then
                MerchantMenu:OnDirection(dir)
                MerchantMenu.repeatState.timer = MerchantMenu.repeatState.interval
            end
        end
    end)
    self.repeatFrame = f
end

-- ----------------------------------------------------------------------------
-- 9. AÇÕES MERCANTIS: VENDA E REPARO (FASE 5)
-- ----------------------------------------------------------------------------
function MerchantMenu:SellSelectedItem()
    if not self.isOpen then return end
    if self.activeColumn ~= "BAGS" then return end

    local item = self.filteredBagItems and self.filteredBagItems[self.selectedBagIndex]
    if not item then return end

    self:SellItem(item.bagID, item.slotID, item)
end

function MerchantMenu:SellItem(bagID, slotID, item)
    if not self.isOpen or not bagID or not slotID then return end

    if MerchantFrame and MerchantFrame:IsShown() then
        MerchantFrame.selectedTab = 1
    end

    if item and (not item.sellPrice or item.sellPrice <= 0) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[ConsoleMode]|r Este item não pode ser vendido ao mercador.")
        if UIErrorsFrame and UIERRORS_HOLD_TIME then
            UIErrorsFrame:AddMessage("O mercador não deseja esse item.", 1.0, 0.1, 0.1, 1.0, UIERRORS_HOLD_TIME)
        end
        PlaySound("igQuestFailed")
        return
    end

    local texture, count, locked = GetContainerItemInfo(bagID, slotID)
    if not texture or locked then return end

    ClearCursor()
    UseContainerItem(bagID, slotID)
    PlaySound("igMainMenuOptionCheckBoxOn")

    local name = (item and item.name) or "Item"
    local priceStr = (item and item.sellPrice and item.sellPrice > 0) and (" por " .. self:FormatMoneyText(item.sellPrice)) or ""
    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Item vendido: " .. ((item and item.link) or name) .. priceStr)
end

function MerchantMenu:RepairAll()
    if not self.isOpen or not self.canRepair then return end

    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or (repairCost or 0) <= 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Seus equipamentos não precisam de reparos.")
        return
    end

    local playerMoney = GetMoney() or 0
    if playerMoney < repairCost then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[ConsoleMode]|r Dinheiro insuficiente para reparar todos os itens (" .. self:FormatMoneyText(repairCost) .. ").")
        if UIErrorsFrame and ERR_NOT_ENOUGH_MONEY and UIERRORS_HOLD_TIME then
            UIErrorsFrame:AddMessage(ERR_NOT_ENOUGH_MONEY, 1.0, 0.1, 0.1, 1.0, UIERRORS_HOLD_TIME)
        end
        PlaySound("igQuestFailed")
        return
    end

    RepairAllItems()
    PlaySound("ITEM_REPAIR")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Todos os itens foram reparados por " .. self:FormatMoneyText(repairCost) .. "!")
    self:RefreshHeader()
end

-- ----------------------------------------------------------------------------
-- 9b. COMPRA / RECOMPRA (FASE 5 - corrige BuySelectedItem nil)
-- ----------------------------------------------------------------------------
function MerchantMenu:BuySelectedItem()
    if not self.isOpen then return end
    if self:IsQtyModalOpen() then self:QtyModalConfirm() return end
    if self.activeColumn ~= "VENDOR" then return end
    local item = self.filteredVendorItems and self.filteredVendorItems[self.selectedVendorIndex]
    if not item then return end
    if item.isBuyback then
        self:BuybackSelectedItem()
    else
        self:BuyItem(item.index, 1, item)
    end
end

function MerchantMenu:BuyItem(mercIndex, qty, item)
    if not self.isOpen or not mercIndex then return end
    qty = qty or 1
    if MerchantFrame and MerchantFrame:IsShown() then
        MerchantFrame.selectedTab = 1
    end
    local price = (item and item.price) or 0
    if price <= 0 and GetMerchantItemInfo then
        local _, _, p = GetMerchantItemInfo(mercIndex)
        price = p or 0
    end
    local total = price
    if qty > 1 and item and item.count and item.count > 0 then
        total = math.floor(price / item.count) * qty
        if total < price then total = price end
    elseif qty > 1 then
        total = price * qty
    end
    local money = GetMoney() or 0
    if money < total then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[ConsoleMode]|r Dinheiro insuficiente (" .. self:FormatMoneyText(total) .. ").")
        if UIErrorsFrame and ERR_NOT_ENOUGH_MONEY and UIERRORS_HOLD_TIME then
            UIErrorsFrame:AddMessage(ERR_NOT_ENOUGH_MONEY, 1.0, 0.1, 0.1, 1.0, UIERRORS_HOLD_TIME)
        end
        PlaySound("igQuestFailed")
        return
    end
    if BuyMerchantItem then
        pcall(function() BuyMerchantItem(mercIndex, qty) end)
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
    local label = (item and item.link) or ((item and item.name) or "Item")
    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Item comprado: " .. label .. " por " .. self:FormatMoneyText(total))
    self:RefreshHeader()
    self:ScanMerchantItems()
    self:UpdateVendorRows()
end

function MerchantMenu:BuybackSelectedItem()
    if not self.isOpen then return end
    local item = self.filteredVendorItems and self.filteredVendorItems[self.selectedVendorIndex]
    if not item or not item.isBuyback then return end
    local idx = tonumber(item.buybackIndex) or 0
    if idx < 1 then return end
    local price = tonumber(item.price) or 0
    if (GetMoney() or 0) < price then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[ConsoleMode]|r Dinheiro insuficiente para recomprar.")
        PlaySound("igQuestFailed")
        return
    end
    if BuybackItem then
        pcall(function() BuybackItem(idx) end)
        PlaySound("igMainMenuOptionCheckBoxOn")
        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Recomprado: " .. tostring(item.link or item.name))
    end
    self:ScanMerchantItems()
    self:UpdateVendorRows()
    self:RefreshHeader()
end

-- X no vendor abre modal Qtd; X nas bags vende. Roteado por Keybindings.
function MerchantMenu:VendorSecondaryAction()
    if not self.isOpen then return end
    if self:IsQtyModalOpen() then self:QtyModalConfirm() return end
    if self.activeColumn == "VENDOR" then
        local tab = SUBTABS_VENDOR[self.vendorSubTabIdx] or SUBTABS_VENDOR[1]
        if tab.id == "BUYBACK" then
            self:BuybackSelectedItem()
            return
        end
        local item = self.filteredVendorItems and self.filteredVendorItems[self.selectedVendorIndex]
        if not item then return end
        if item.isBuyback then
            self:BuybackSelectedItem()
        else
            self:OpenQtyModal(item.index)
        end
    else
        self:SellSelectedItem()
    end
end

-- ----------------------------------------------------------------------------
-- 9c. MODAL DE QUANTIDADE (FASE 6)
-- ----------------------------------------------------------------------------
function MerchantMenu:CreateQtyModalUI()
    if self.qtyModalFrame then return self.qtyModalFrame end
    local m = CreateFrame("Frame", "ConsoleMode_MerchantQtyModal", UIParent)
    m:SetWidth(420)
    m:SetHeight(230)
    m:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    m:SetFrameStrata("FULLSCREEN_DIALOG")
    m:SetFrameLevel(50)
    m:EnableMouse(true)
    m:SetMovable(false)
    m:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
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
    qty:SetPoint("CENTER", m, "CENTER", 0, 10)
    self:ApplyFont(qty, FONTS.titleBold, 30)
    qty:SetText("|cffe09a15x1|r")
    m.qtyText = qty
    local cost = m:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cost:SetPoint("TOP", qty, "BOTTOM", 0, -8)
    cost:SetWidth(380)
    cost:SetJustifyH("CENTER")
    self:ApplyFont(cost, FONTS.titleBold, 15)
    cost:SetText("")
    m.costText = cost
    local rest = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rest:SetPoint("TOP", cost, "BOTTOM", 0, -4)
    rest:SetWidth(380)
    rest:SetJustifyH("CENTER")
    self:ApplyFont(rest, FONTS.titleBold, 13)
    rest:SetText("")
    m.restText = rest
    local hints = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hints:SetPoint("BOTTOM", m, "BOTTOM", 0, 14)
    hints:SetWidth(390)
    hints:SetJustifyH("CENTER")
    self:ApplyFont(hints, FONTS.titleBold, 14)
    hints:SetText("|cffffffff[A]|r |cff1eff00confirmar|r   |cffffffff[B]|r |cffff2020cancelar|r   |cffe09a15[D-Pad </>] +-1  [Up/Down] +-5|r")
    m.hints = hints
    self.qtyModalFrame = m
    return m
end

function MerchantMenu:CalcQtyMax(unitPrice, stock)
    unitPrice = tonumber(unitPrice) or 0
    stock = tonumber(stock) or 0
    if unitPrice <= 0 then return 1 end
    local money = GetMoney() or 0
    local byMoney = math.floor(money / unitPrice)
    if byMoney < 1 then byMoney = 1 end
    if stock == nil or stock < 0 then stock = byMoney end
    if stock < 1 then stock = 1 end
    local maxQty = byMoney
    if stock < maxQty then maxQty = stock end
    if maxQty < 1 then maxQty = 1 end
    return maxQty
end

function MerchantMenu:OpenQtyModal(vendorIndex)
    if not self.isOpen then return end
    vendorIndex = tonumber(vendorIndex) or 0
    if vendorIndex < 1 then return end
    if not GetMerchantItemInfo then return end
    local name, texture, price, quantity, numAvailable = GetMerchantItemInfo(vendorIndex)
    if not name then return end
    price = tonumber(price) or 0
    if price <= 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[ConsoleMode]|r Este item não tem preço de compra.")
        PlaySound("igQuestFailed")
        return
    end
    local stock = tonumber(numAvailable) or -1
    if stock < 0 then
        local money = GetMoney() or 0
        stock = math.floor(money / price)
        if stock < 1 then stock = 1 end
    end
    self:CreateQtyModalUI()
    self.qtyModal.isOpen = true
    self.qtyModal.vendorIndex = vendorIndex
    self.qtyModal.unitPrice = price
    self.qtyModal.stock = stock
    self.qtyModal.maxQty = self:CalcQtyMax(price, stock)
    self.qtyModal.qty = 1
    self.qtyModal.itemName = name
    self.qtyModal.itemTex = texture
    self:UpdateQtyModalVisuals()
    self.qtyModalFrame:Show()
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function MerchantMenu:CloseQtyModal()
    self.qtyModal.isOpen = false
    self.qtyModal.vendorIndex = nil
    self.qtyModal.qty = 1
    if self.qtyModalFrame and self.qtyModalFrame:IsVisible() then
        self.qtyModalFrame:Hide()
    end
    PlaySound("igMainMenuClose")
end

function MerchantMenu:IsQtyModalOpen()
    if self.qtyModal and self.qtyModal.isOpen then return true end
    if self.qtyModalFrame and self.qtyModalFrame:IsVisible() then return true end
    return false
end

function MerchantMenu:QtyModalAdjust(delta)
    if not self:IsQtyModalOpen() then return end
    delta = tonumber(delta) or 0
    local q = (self.qtyModal.qty or 1) + delta
    local mx = self.qtyModal.maxQty or 1
    if q < 1 then q = 1 end
    if q > mx then q = mx end
    if q ~= self.qtyModal.qty then
        self.qtyModal.qty = q
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:UpdateQtyModalVisuals()
    end
end

function MerchantMenu:QtyModalConfirm()
    if not self:IsQtyModalOpen() then return end
    local idx = tonumber(self.qtyModal.vendorIndex) or 0
    local qty = tonumber(self.qtyModal.qty) or 1
    if idx < 1 then self:CloseQtyModal() return end
    local item = self.filteredVendorItems and self.filteredVendorItems[self.selectedVendorIndex]
    self:CloseQtyModal()
    self:BuyItem(idx, qty, item)
end

function MerchantMenu:UpdateQtyModalVisuals()
    local m = self.qtyModalFrame
    if not m then return end
    local qty = tonumber(self.qtyModal.qty) or 1
    local mx = tonumber(self.qtyModal.maxQty) or 1
    local unit = tonumber(self.qtyModal.unitPrice) or 0
    local total = unit * qty
    local money = GetMoney() or 0
    local rest = money - total
    if rest < 0 then rest = 0 end
    m.title:SetText("|cffe09a15Quantidade|r")
    m.nameText:SetText("|cffffffff" .. tostring(self.qtyModal.itemName or "Item") .. "|r")
    m.qtyText:SetText("|cffe09a15x" .. qty .. "|r  |cff888888/ " .. mx .. "|r")
    m.costText:SetText("|cffaaaaaaTotal:|r " .. self:FormatMoneyText(total) .. "  |cff888888(unit. " .. self:FormatMoneyText(unit) .. ")|r")
    if total > money then
        m.restText:SetText("|cffff2020Saldo insuficiente após compra.|r")
    else
        m.restText:SetText("|cffaaaaaaRestante:|r " .. self:FormatMoneyText(rest))
    end
end

-- ----------------------------------------------------------------------------
-- 9d. AUTO-SELL JUNK (FASE 6 - [R3]/DUP, loop OnUpdate 0.15s)
-- ----------------------------------------------------------------------------
function MerchantMenu:BuildAutoSellQueue()
    local q = {}
    local raw = self.rawBagItems or {}
    local n = table.getn(raw)
    for i = 1, n do
        local it = raw[i]
        if it then
            if (tonumber(it.quality) or 1) == 0 and (tonumber(it.sellPrice) or 0) > 0 then
                local tex, cnt, locked = GetContainerItemInfo(it.bagID, it.slotID)
                if tex and not locked then
                    table.insert(q, { bagID = it.bagID, slotID = it.slotID, sellPrice = it.sellPrice })
                end
            end
        end
    end
    return q
end

function MerchantMenu:AutoSellJunk()
    if not self.isOpen then return end
    if self.autoSell.running then return end
    if self:IsQtyModalOpen() then return end
    if MerchantFrame and MerchantFrame:IsShown() then MerchantFrame.selectedTab = 1 end
    local queue = self:BuildAutoSellQueue()
    if table.getn(queue) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Nenhum lixo (cinza) para vender.")
        PlaySound("igQuestFailed")
        return
    end
    self.autoSell.running = true
    self.autoSell.queue = queue
    self.autoSell.pos = 1
    self.autoSell.gained = 0
    self.autoSell.acc = 0
    if not self.autoSellFrame then
        self.autoSellFrame = CreateFrame("Frame", "ConsoleMode_MerchantAutoSellFrame")
    end
    self.autoSellFrame:SetScript("OnUpdate", function()
        MerchantMenu:AutoSell_OnUpdate(arg1)
    end)
    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Vendendo " .. table.getn(queue) .. " itens cinza...")
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function MerchantMenu:AutoSell_OnUpdate(dt)
    local st = self.autoSell
    if not st.running then return end
    st.acc = (st.acc or 0) + (dt or 0)
    if st.acc < 0.15 then return end
    st.acc = 0
    if not self.isOpen then
        self:AutoSell_Stop(false)
        return
    end
    local q = st.queue or {}
    local total = table.getn(q)
    local pos = tonumber(st.pos) or 1
    if pos > total then
        self:AutoSell_Stop(true)
        return
    end
    local entry = q[pos]
    st.pos = pos + 1
    if entry then
        local tex, cnt, locked = GetContainerItemInfo(entry.bagID, entry.slotID)
        if tex and not locked then
            ClearCursor()
            pcall(function() UseContainerItem(entry.bagID, entry.slotID) end)
            st.gained = (st.gained or 0) + (tonumber(entry.sellPrice) or 0)
        end
    end
    if (st.pos or 1) > total then
        self:AutoSell_Stop(true)
    end
end

function MerchantMenu:AutoSell_Stop(announce)
    local st = self.autoSell
    st.running = false
    st.pos = 1
    if self.autoSellFrame then self.autoSellFrame:SetScript("OnUpdate", nil) end
    if announce then
        local g = tonumber(st.gained) or 0
        if g > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff1eff00[ConsoleMode]|r Lixo vendido: +" .. self:FormatMoneyText(g))
            PlaySound("ITEM_REPAIR")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Auto-sell concluído (sem ganho).")
        end
        st.gained = 0
        st.queue = {}
        self:OnBagUpdate()
        self:RefreshHeader()
    end
end

function MerchantMenu:IsAutoSelling()
    if self.autoSell and self.autoSell.running then return true end
    return false
end

-- ----------------------------------------------------------------------------
-- 10. CONTROLE DE ABERTURA, ATUALIZAÇÃO E FECHAMENTO
-- ----------------------------------------------------------------------------
function MerchantMenu:OnBagUpdate()
    if not self.isOpen then return end
    self:ScanPlayerBags()
    self:UpdateBagRows()
    self:RefreshHeader()
end

function MerchantMenu:Open()
    self:CreateUI()
    self:UpdateLayout()
    self:RefreshHeader()

    -- FASE 3: Inicializa colunas e varredura do inventário
    self.activeColumn     = "BAGS"
    self.bagSubTabIdx     = 1
    self.selectedBagIndex = 1
    self.bagScrollOffset  = 0

    self:UpdateBagsSubTabBar()
    self:ScanPlayerBags()
    -- FASE 5: inicializa loja do vendedor
    self.vendorSubTabIdx     = 1
    self.selectedVendorIndex = 1
    self.vendorScrollOffset  = 0
    self:UpdateVendorSubTabBar()
    self:ScanMerchantItems()
    self:UpdateColumnVisuals()
    self:UpdateBagRows()
    self:UpdateVendorRows()

    if self.dimmer then
        self.dimmer:Show()
    end
    self.frame:Show()

    -- Ativa e reforça o Modo de Navegação no Gamepad
    if ConsoleMode and ConsoleMode.keybindings then
        -- Evita reentrada: só entra no modo navegação se ainda não estiver ativo
        if not ConsoleMode.keybindings.navigationMode then
            if ConsoleMode.keybindings.EnterNavigationMode then
                ConsoleMode.keybindings:EnterNavigationMode()
            end
        else
            -- Já está em navegação — apenas reaplica os bindings do D-Pad para garantir integridade
            if ConsoleMode.keybindings.ReapplyNavigationBindings then
                ConsoleMode.keybindings:ReapplyNavigationBindings()
            end
        end
    end

    PlaySound("igMainMenuOpen")
end

function MerchantMenu:Close()
    if not self.isOpen then return end
    if self:IsQtyModalOpen() then self:CloseQtyModal() end
    if self:IsAutoSelling() then self:AutoSell_Stop(false) end
    self.isOpen           = false
    self.announced        = false
    self.currentNPC       = nil
    self.canRepair        = false
    self.itemCount        = 0
    self.rawBagItems      = {}
    self.filteredBagItems = {}
    self.merchantItems       = {}
    self.filteredVendorItems = {}
    self.selectedVendorIndex = 1
    self.vendorScrollOffset  = 0
    self.vendorSubTabIdx     = 1
    self.repeatState.direction = nil
    self.repeatState.timer = 0

    if self.scanFrame then
        self.scanFrame:SetScript("OnUpdate", nil)
    end

    if self.dimmer and self.dimmer:IsVisible() then
        self.dimmer:Hide()
    end

    if self.frame and self.frame:IsVisible() then
        self.frame:Hide()
    end

    -- Desativa o Modo de Navegação no Gamepad de forma forçada
    if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.ExitNavigationMode then
        ConsoleMode.keybindings:ExitNavigationMode(true)
    end

    CloseMerchant()
    PlaySound("igMainMenuClose")
    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Interação com Mercador encerrada.")
end

-- ----------------------------------------------------------------------------
-- 11. SINCRONIZAÇÃO ASSÍNCRONA DO CATÁLOGO DO VENDEDOR (SMSG_MERCHANT_LIST)
-- ----------------------------------------------------------------------------
function MerchantMenu:StartItemScan()
    local attempts = 0
    if not self.scanFrame then
        self.scanFrame = CreateFrame("Frame", "ConsoleMode_MerchantScanFrame")
    end

    self.scanFrame:SetScript("OnUpdate", function()
        local dt = arg1 or 0
        this.elapsed = (this.elapsed or 0) + dt
        if this.elapsed >= 0.05 then
            this.elapsed = 0
            attempts = attempts + 1

            local count = 0
            if GetMerchantNumItems then
                count = GetMerchantNumItems() or 0
            end

            -- Se os itens já chegaram do servidor ou atingimos o tempo limite (0.6s)
            if count > 0 or attempts >= 12 then
                this:SetScript("OnUpdate", nil)
                MerchantMenu:AnnounceMerchant(count)
            end
        end
    end)
end

function MerchantMenu:AnnounceMerchant(itemCount)
    if self.announced or not self.isOpen then return end
    self.announced = true
    self.itemCount = itemCount or 0

    -- Atualiza dados e abre a janela do ConsoleMode
    self:Open()

    -- Feedback visual limpo no chat para validação
    local repairStr = self.canRepair and "|cff00ff00Sim|r" or "|cffaaaaaaNão|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Interação com Mercador detectada: |cffffffff" .. (self.currentNPC or "Vendedor") .. "|r (" .. self.itemCount .. " itens | Reparo: " .. repairStr .. ")")

    -- Reforço de fechamento das bolsas nativas
    self:CloseAllOpenBags()
end

-- ----------------------------------------------------------------------------
-- 12. MANIPULADORES DE EVENTOS
-- ----------------------------------------------------------------------------
function MerchantMenu:OnMerchantShow()
    -- 1. Torna MerchantFrame invisível off-screen (sem dar Hide para não fechar a sessão)
    self:SuppressDefaultFrame()

    -- 2. Extrai metadados imediatos (Nome e Reparo)
    local npcName = UnitName("npc")
    if not npcName or npcName == "" then
        npcName = "Vendedor"
    end

    local canRepair = false
    if CanMerchantRepair then
        canRepair = CanMerchantRepair() and true or false
    end

    self.isOpen     = true
    self.announced  = false
    self.currentNPC = npcName
    self.canRepair  = canRepair
    self.itemCount  = 0

    -- 3. Inicia verificação assíncrona dos itens do servidor
    local instantCount = (GetMerchantNumItems and GetMerchantNumItems()) or 0
    if instantCount > 0 then
        self:AnnounceMerchant(instantCount)
    else
        self:StartItemScan()
    end

    -- 4. Delay de segurança (60ms) para fechar qualquer bolsa que abra assincronamente
    local delayedSafety = CreateFrame("Frame")
    delayedSafety:SetScript("OnUpdate", function()
        this.t = (this.t or 0) + (arg1 or 0)
        if this.t >= 0.06 then
            this:SetScript("OnUpdate", nil)
            MerchantMenu:CloseAllOpenBags()
        end
    end)
end

function MerchantMenu:OnMerchantUpdate()
    if not self.isOpen then return end
    if not self.announced then
        local count = (GetMerchantNumItems and GetMerchantNumItems()) or 0
        if count > 0 then
            if self.scanFrame then
                self.scanFrame:SetScript("OnUpdate", nil)
            end
            self:AnnounceMerchant(count)
        end
    else
        -- Loja aberta: compra/venda/recompra mudou estoque -> rescan
        self:ScanMerchantItems()
        self:UpdateVendorRows()
        self:RefreshHeader()
    end
end

function MerchantMenu:OnMoneyUpdate()
    if not self.isOpen then return end
    self:RefreshHeader()
    if self.activeColumn == "VENDOR" then
        self:UpdateVendorRows()
    end
end

function MerchantMenu:OnMerchantClosed()
    if self:IsQtyModalOpen() then self:CloseQtyModal() end
    if self:IsAutoSelling() then self:AutoSell_Stop(false) end
    if self.isOpen then
        self.isOpen     = false
        self.announced  = false
        self.currentNPC = nil
        self.canRepair  = false
        self.itemCount  = 0
        self.merchantItems = {}
        self.filteredVendorItems = {}
        self.selectedVendorIndex = 1
        self.vendorScrollOffset = 0
        self.vendorSubTabIdx = 1
        if self.autoSellFrame then
            self.autoSellFrame:SetScript("OnUpdate", nil)
        end

        if self.scanFrame then
            self.scanFrame:SetScript("OnUpdate", nil)
        end

        if self.dimmer and self.dimmer:IsVisible() then
            self.dimmer:Hide()
        end

        if self.frame and self.frame:IsVisible() then
            self.frame:Hide()
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Interação com Mercador encerrada.")
    end
end

-- ----------------------------------------------------------------------------
-- 13. INICIALIZAÇÃO DO MÓDULO & REGISTRO DE EVENTOS
-- ----------------------------------------------------------------------------
function MerchantMenu:Initialize()
    if self.initialized then return end
    self.initialized = true

    -- Hook preventivo no OnShow do MerchantFrame
    if MerchantFrame then
        local orig_MerchantFrame_OnShow = MerchantFrame:GetScript("OnShow")
        MerchantFrame:SetScript("OnShow", function()
            if orig_MerchantFrame_OnShow then
                orig_MerchantFrame_OnShow()
            end
            MerchantFrame.selectedTab = 1
            MerchantFrame:SetAlpha(0)
            MerchantFrame:EnableMouse(false)
            MerchantFrame:ClearAllPoints()
            MerchantFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 5000)
            MerchantMenu:CloseAllOpenBags()
        end)

        -- Proteção no OnHide: impede que CloseMerchant() seja chamado inadvertidamente
        local orig_MerchantFrame_OnHide = MerchantFrame:GetScript("OnHide")
        MerchantFrame:SetScript("OnHide", function()
            if not MerchantMenu.isOpen then
                if orig_MerchantFrame_OnHide then
                    orig_MerchantFrame_OnHide()
                end
            end
        end)
    end

    -- Frame de Eventos Dedicado do MerchantMenu
    local ef = CreateFrame("Frame", "ConsoleMode_MerchantEventFrame")
    ef:RegisterEvent("MERCHANT_SHOW")
    ef:RegisterEvent("MERCHANT_UPDATE")
    ef:RegisterEvent("MERCHANT_CLOSED")
    ef:RegisterEvent("BAG_UPDATE")
    ef:RegisterEvent("PLAYER_MONEY")

    ef:SetScript("OnEvent", function()
        if event == "MERCHANT_SHOW" then
            MerchantMenu:OnMerchantShow()
        elseif event == "MERCHANT_UPDATE" then
            MerchantMenu:OnMerchantUpdate()
        elseif event == "MERCHANT_CLOSED" then
            MerchantMenu:OnMerchantClosed()
        elseif event == "BAG_UPDATE" then
            MerchantMenu:OnBagUpdate()
        elseif event == "PLAYER_MONEY" then
            MerchantMenu:OnMoneyUpdate()
        end
    end)
end

-- Inicialização automática no carregamento do arquivo
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    MerchantMenu:Initialize()
end)
