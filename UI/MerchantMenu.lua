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
        MerchantFrame:SetAlpha(0)
        MerchantFrame:EnableMouse(false)
        MerchantFrame:ClearAllPoints()
        MerchantFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 5000)
    end
    self:CloseAllOpenBags()
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
        local n, _, q, reqL, t, st, _, eqL = GetItemInfo(itemID)
        if n then
            itemName = n
            itemQuality = tonumber(q) or itemQuality
            itemReqLevel = tonumber(reqL) or 0
            itemType = t or ""
            itemSubType = st or ""
            itemEquipLoc = eqL or ""
        end
    elseif rawLink then
        local n, _, q, reqL, t, st, _, eqL = GetItemInfo(rawLink)
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
            elseif string.find(leftText, "Uso:") or string.find(leftText, "Use:") or string.find(leftText, "Equipar:") then
                desc = leftText
                if rightText ~= "" then desc = desc .. " " .. rightText end
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

    -- 5. Descrição / Atributos (2 Colunas) (+20%: 11 -> 13)
    local descColLeft = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descColLeft:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -8)
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
        { icons = { "A" },        label = "Comprar" },
        { icons = { "X" },        label = "Vender" },
        { icons = { "Y" },        label = "Reparar Tudo", key = "REPAIR" },
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
        row:SetScript("OnClick", function()
            local itemIdx = (MerchantMenu.bagScrollOffset or 0) + this.slotIndex
            MerchantMenu.activeColumn = "BAGS"
            MerchantMenu.selectedBagIndex = itemIdx
            MerchantMenu:UpdateColumnVisuals()
            MerchantMenu:UpdateBagRows()
            PlaySound("igMainMenuOptionCheckBoxOn")
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

        local rtBtn = CreateFrame("Button", nil, subTabBar)
        rtBtn:SetWidth(27)
        rtBtn:SetHeight(27)
        rtBtn:SetPoint("RIGHT", subTabBar, "RIGHT", -2, 0)
        local rtHint = rtBtn:CreateTexture(nil, "OVERLAY")
        rtHint:SetAllPoints(rtBtn)
        rtHint:SetTexture(ICONS.RT)
        col.rtBtn = rtBtn

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
        return
    end

    local qColor = QUALITY_COLORS[item.quality or 1] or QUALITY_COLORS[1]

    card.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    card.iconBorder:SetBackdropBorderColor(qColor.r, qColor.g, qColor.b, 0.90)

    local countStr = (item.count and item.count > 1) and (" |cffffffff(x" .. item.count .. ")|r") or ""
    card.titleText:SetText(qColor.hex .. item.name .. "|r" .. countStr)

    -- Preço no DetailCard
    if item.sellPrice and item.sellPrice > 0 then
        local priceStr = "|cffaaaaaaPreço de Venda: |r" .. self:FormatMoneyText(item.sellPrice)
        if item.count and item.count > 1 then
            local unit = math.floor(item.sellPrice / item.count)
            if unit > 0 then
                priceStr = priceStr .. " |cff888888(" .. self:FormatMoneyText(unit) .. " cada)|r"
            end
        end
        card.priceText:SetText(priceStr)
    else
        card.priceText:SetText("|cff888888Sem valor de venda comercial|r")
    end

    -- Subtítulo: Tipo • Subtipo • Slot • Requisito
    local typeParts = {}
    if item.itemType and item.itemType ~= "" then table.insert(typeParts, item.itemType) end
    if item.subType and item.subType ~= "" then table.insert(typeParts, item.subType) end
    if item.equipLoc and item.equipLoc ~= "" then
        local slotText = getglobal(item.equipLoc) or item.equipLoc
        table.insert(typeParts, slotText)
    end
    if item.reqLevel and item.reqLevel > 0 then
        local pLvl = UnitLevel("player") or 1
        local reqColor = (item.reqLevel > pLvl) and "|cffff2020" or "|cffffffff"
        table.insert(typeParts, reqColor .. "Requer Nível " .. item.reqLevel .. "|r")
    end

    local subStr = table.concat(typeParts, "  •  ")
    if subStr == "" then subStr = "Item do Inventário" end
    card.typeText:SetText("|cffb0b0b0" .. subStr .. "|r")

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

    if item.desc and item.desc ~= "" then
        table.insert(rightLines, "|cff00ff00" .. item.desc .. "|r")
    end

    local leftText = table.concat(leftLines, "\n")
    local rightText = table.concat(rightLines, "\n")

    if leftText == "" then
        leftText = "|cff888888Nenhum atributo adicional.|r"
    end
    if rightText == "" then
        if item.sellPrice and item.sellPrice > 0 then
            rightText = "|cff888888Pronto para venda no vendedor.|r\n|cffaaaaaaPressione [X] para vender (Fase 5).|r"
        else
            rightText = "|cff666666Item sem preço de compra em mercadores.|r"
        end
    end

    card.descColLeft:SetText(leftText)
    card.descColRight:SetText(rightText)
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
    if self.activeColumn == "BAGS" then
        self.activeColumn = "VENDOR"
        PlaySound("igCharacterInfoTab")
        self:UpdateColumnVisuals()
        self:UpdateBagRows()
        self:ShowVendorPlaceholderDetail()
    else
        self.activeColumn = "BAGS"
        PlaySound("igCharacterInfoTab")
        self:UpdateColumnVisuals()
        self:UpdateBagRows()
    end
end

function MerchantMenu:CycleSubTab(delta)
    if not self.isOpen then return end

    if self.activeColumn == "BAGS" then
        local count = table.getn(SUBTABS_BAGS)
        self.bagSubTabIdx = self.bagSubTabIdx + delta
        if self.bagSubTabIdx > count then self.bagSubTabIdx = 1 end
        if self.bagSubTabIdx < 1 then self.bagSubTabIdx = count end
        PlaySound("igMainMenuOptionCheckBoxOn")
        self:UpdateBagsSubTabBar()
        self:FilterBagItems()
        self.selectedBagIndex = 1
        self.bagScrollOffset = 0
        self:UpdateBagRows()
    else
        -- Fase 4: sub-abas de itens do vendedor
    end
end

function MerchantMenu:OnDirection(direction)
    if not self.isOpen then return end

    if direction == "LEFT" then
        if self.activeColumn == "BAGS" then
            self:ToggleColumn(-1)
        end
    elseif direction == "RIGHT" then
        if self.activeColumn == "VENDOR" then
            self:ToggleColumn(1)
        end
    elseif direction == "UP" then
        if self.activeColumn == "BAGS" then
            self:MoveBagSelection(-1)
        end
    elseif direction == "DOWN" then
        if self.activeColumn == "BAGS" then
            self:MoveBagSelection(1)
        end
    end
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
    self:UpdateColumnVisuals()
    self:UpdateBagRows()

    if self.dimmer then
        self.dimmer:Show()
    end
    self.frame:Show()

    -- Ativa o Modo de Navegação no Gamepad
    if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.EnterNavigationMode then
        ConsoleMode.keybindings:EnterNavigationMode()
    end

    PlaySound("igMainMenuOpen")
end

function MerchantMenu:Close()
    if not self.isOpen then return end
    self.isOpen           = false
    self.announced        = false
    self.currentNPC       = nil
    self.canRepair        = false
    self.itemCount        = 0
    self.rawBagItems      = {}
    self.filteredBagItems = {}

    if self.scanFrame then
        self.scanFrame:SetScript("OnUpdate", nil)
    end

    if self.dimmer and self.dimmer:IsVisible() then
        self.dimmer:Hide()
    end

    if self.frame and self.frame:IsVisible() then
        self.frame:Hide()
    end

    -- Desativa o Modo de Navegação no Gamepad
    if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.ExitNavigationMode then
        ConsoleMode.keybindings:ExitNavigationMode()
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
    if self.isOpen and not self.announced then
        local count = (GetMerchantNumItems and GetMerchantNumItems()) or 0
        if count > 0 then
            if self.scanFrame then
                self.scanFrame:SetScript("OnUpdate", nil)
            end
            self:AnnounceMerchant(count)
        end
    end
end

function MerchantMenu:OnMerchantClosed()
    if self.isOpen then
        self.isOpen     = false
        self.announced  = false
        self.currentNPC = nil
        self.canRepair  = false
        self.itemCount  = 0

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
        MerchantFrame:SetScript("OnShow", function()
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

    ef:SetScript("OnEvent", function()
        if event == "MERCHANT_SHOW" then
            MerchantMenu:OnMerchantShow()
        elseif event == "MERCHANT_UPDATE" then
            MerchantMenu:OnMerchantUpdate()
        elseif event == "MERCHANT_CLOSED" then
            MerchantMenu:OnMerchantClosed()
        elseif event == "BAG_UPDATE" then
            MerchantMenu:OnBagUpdate()
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
