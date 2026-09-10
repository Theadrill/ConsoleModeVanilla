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
-- CONSTANTES DE DESIGN SYSTEM & RECURSOS
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

-- ----------------------------------------------------------------------------
-- ESTADO DO MÓDULO
-- ----------------------------------------------------------------------------
MerchantMenu.isOpen       = false
MerchantMenu.initialized  = false
MerchantMenu.currentNPC   = nil
MerchantMenu.canRepair    = false
MerchantMenu.itemCount    = 0
MerchantMenu.announced    = false
MerchantMenu.scanFrame    = nil
MerchantMenu.frame        = nil
MerchantMenu.activeColumn = "VENDOR" -- "VENDOR" ou "BAGS"

-- ----------------------------------------------------------------------------
-- 1. HELPERS TIPOGRÁFICOS E VISUAIS
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
-- 2. SUPRESSÃO SEGURA DE BOLSAS E DA JANELA NATIVA DA BLIZZARD (MerchantFrame)
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
-- 3. TEXTURA 9-SLICE & DIMMER (IDÊNTICO AO MAIN MENU)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 4. DETAIL CARD (ESTILO ZELDA / CONSOLE RPG - IDÊNTICO AO MAIN MENU)
-- ----------------------------------------------------------------------------
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

    -- 2. Título (+20%: 16 -> 19)
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, 0)
    titleText:SetPoint("RIGHT", card, "RIGHT", -140, 0)
    titleText:SetJustifyH("LEFT")
    self:ApplyFont(titleText, FONTS.titleBold, 19)
    titleText:SetText("|cffe09a15Selecione um item para inspecionar|r")
    card.titleText = titleText

    -- Preço (+20%: 14 -> 17)
    local priceText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    priceText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -10)
    self:ApplyFont(priceText, FONTS.titleBold, 17)
    priceText:SetText("|cffaaaaaaPreço: |r--")
    card.priceText = priceText

    -- 3. Subtítulo (Tipo / Subtipo) (+20%: 12 -> 15)
    local typeText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    typeText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3)
    typeText:SetPoint("RIGHT", card, "RIGHT", -140, 0)
    typeText:SetJustifyH("LEFT")
    self:ApplyFont(typeText, FONTS.medium, 15)
    typeText:SetText("|cffaaaaaaNavegue pelas colunas para comprar ou vender itens|r")
    card.typeText = typeText

    -- 4. Descrição / Atributos (2 Colunas) (+20%: 11 -> 13)
    local descColLeft = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descColLeft:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -6)
    descColLeft:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 10)
    descColLeft:SetWidth(320)
    descColLeft:SetJustifyH("LEFT")
    descColLeft:SetJustifyV("TOP")
    self:ApplyFont(descColLeft, FONTS.bodyBold, 13)
    descColLeft:SetText("|cff888888Use [D-Pad] para navegar pela lista de mercadorias e pelas suas bolsas.|r")
    card.descColLeft = descColLeft

    local descColRight = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descColRight:SetPoint("TOPLEFT", descColLeft, "TOPRIGHT", 16, 0)
    descColRight:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 10)
    descColRight:SetJustifyH("LEFT")
    descColRight:SetJustifyV("TOP")
    self:ApplyFont(descColRight, FONTS.bodyBold, 13)
    descColRight:SetText("|cff888888Pressione [LB] ou [RB] para alternar entre a loja do NPC e seu inventário.|r")
    card.descColRight = descColRight

    return card
end

-- ----------------------------------------------------------------------------
-- 5. BARRA DE ATALHOS NO RODAPÉ (CONSOLE HINTS - ÍCONES +35%, TEXTO +20%)
-- ----------------------------------------------------------------------------
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

    for i, hint in ipairs(hints) do
        local groupFrame = CreateFrame("Frame", nil, container)
        groupFrame:SetHeight(34)

        local currentX = 0
        for _, iconKey in ipairs(hint.icons) do
            local texPath = ICONS[iconKey]
            local iconTex = groupFrame:CreateTexture(nil, "OVERLAY")

            -- Ícones aumentados em +35%: 20 -> 27px, 24 -> 32px
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

        -- Rótulos aumentados em +20%: 15 -> 18px
        local label = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
        self:ApplyFont(label, FONTS.bodyBold, 18)
        label:SetText(hint.label)
        label:SetTextColor(0.85, 0.85, 0.85, 0.95)

        local textW = math.floor(label:GetStringWidth() or 40)
        currentX = currentX + textW

        if i < table.getn(hints) then
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
    for _, widget in ipairs(widgets) do
        widget:SetPoint("LEFT", container, "CENTER", curX, 0)
        curX = curX + widget:GetWidth()
    end
    container:SetWidth(totalWidth)
end

-- ----------------------------------------------------------------------------
-- 6. CONSTRUÇÃO DO CANVAS E COLUNAS SPLIT-VIEW
-- ----------------------------------------------------------------------------
function MerchantMenu:CreateUI()
    if self.frame then return end

    -- 6.1. Dimmer de fundo (Imersão console)
    self:CreateDimmer()

    -- 6.2. Janela Principal (Sem transparência, 9-slice esculpido oficial)
    local frame = CreateFrame("Frame", "ConsoleMode_MerchantFrame", UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(10)
    frame:SetMovable(false)
    frame:EnableMouse(true)
    frame:Hide()

    -- Aplica a textura 9-Slice idêntica ao MainMenu
    self.slices = self:Create9Slice(
        frame,
        NINESLICE.texture,
        NINESLICE.cornerSize,
        NINESLICE.uv,
        NINESLICE.drawLayer
    )

    -- Permite fechar com a tecla ESC
    table.insert(UISpecialFrames, "ConsoleMode_MerchantFrame")
    frame:SetScript("OnHide", function()
        if MerchantMenu.isOpen then
            MerchantMenu:Close()
        end
    end)

    self.frame = frame

    -- 6.3. Título Superior Central (+20%: 19 -> 23)
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", frame, "TOP", 0, -20)
    self:ApplyFont(titleText, FONTS.titleBold, 23)
    titleText:SetText("|cffe09a15COMÉRCIO & REPAROS|r")
    frame.titleText = titleText

    -- 6.4. Barra de Cabeçalho (Nome do NPC, Saldo de Moedas e Botão Sair)
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

    -- Botão Sair com estilo idêntico aos botões do MainMenu (Ícone +35%: 18 -> 25px, Texto +20%: 13 -> 16px)
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

    -- 6.5. DetailCard Inferior
    local detailCard = self:CreateDetailCard(frame)
    frame.detailCard = detailCard

    -- 6.6. Barra de Rodapé com Atalhos do Controle
    self:CreateFooterHints(frame)

    -- 6.7. Área Central de Conteúdo Split-View
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

    -- Helper para construir coluna com acabamento amadeirado / pergaminho sólido
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

        local ltHint = subTabBar:CreateTexture(nil, "OVERLAY")
        ltHint:SetWidth(27)
        ltHint:SetHeight(27)
        ltHint:SetPoint("LEFT", subTabBar, "LEFT", 2, 0)
        ltHint:SetTexture(ICONS.LT)

        local rtHint = subTabBar:CreateTexture(nil, "OVERLAY")
        rtHint:SetWidth(27)
        rtHint:SetHeight(27)
        rtHint:SetPoint("RIGHT", subTabBar, "RIGHT", -2, 0)
        rtHint:SetTexture(ICONS.RT)

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

        -- Área interna de Lista
        local listArea = CreateFrame("Frame", nil, col)
        listArea:SetPoint("TOPLEFT", cDiv, "BOTTOMLEFT", 0, -4)
        listArea:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", -6, 6)
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
    frame.leftCol = leftCol

    -- Coluna Direita: Inventário
    local rightCol = CreateColumnPanel("ConsoleMode_MerchantColRight", "SEU INVENTÁRIO", ICONS.RB)
    rightCol:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", 0, 0)
    rightCol:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", 0, 0)
    rightCol:SetPoint("LEFT", divider, "RIGHT", 6, 0)
    rightCol.placeholder:SetText("|cffe09a15[ Bolsas do Jogador ]|r\n\n|cffaaaaaaPronto para conexão com o inventário|r\n|cff666666(Fase 3: Leitura e venda de bolsas)|r")
    frame.rightCol = rightCol
end

-- ----------------------------------------------------------------------------
-- 7. ATUALIZAÇÃO DE LAYOUT RESPONSIVO E DADOS
-- ----------------------------------------------------------------------------
function MerchantMenu:UpdateLayout()
    if not self.frame then return end

    local screenW = (UIParent and UIParent:GetWidth()) or 1024
    local screenH = (UIParent and UIParent:GetHeight()) or 768

    -- Proporções responsivas idênticas às do MainMenu (94% largura, 85% altura)
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

    -- Reposiciona a barra de rodapé centralizada
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

    -- Saldo do Jogador
    local playerMoney = GetMoney() or 0
    if self.frame.header and self.frame.header.playerMoneyText then
        self.frame.header.playerMoneyText:SetText(self:FormatMoneyText(playerMoney))
    end

    -- Atualiza visibilidade de reparo no rodapé
    if self.footerRepairWidget then
        if self.canRepair then
            self.footerRepairWidget:Show()
        else
            self.footerRepairWidget:Hide()
        end
    end
end

-- ----------------------------------------------------------------------------
-- 8. CONTROLE DE ABERTURA E FECHAMENTO
-- ----------------------------------------------------------------------------
function MerchantMenu:Open()
    self:CreateUI()
    self:UpdateLayout()
    self:RefreshHeader()

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

    -- Desativa o Modo de Navegação no Gamepad
    if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.ExitNavigationMode then
        ConsoleMode.keybindings:ExitNavigationMode()
    end

    CloseMerchant()
    PlaySound("igMainMenuClose")
    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Interação com Mercador encerrada.")
end

-- ----------------------------------------------------------------------------
-- 6. SINCRONIZAÇÃO ASSÍNCRONA DO CATÁLOGO DO VENDEDOR (SMSG_MERCHANT_LIST)
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
-- 7. MANIPULADORES DE EVENTOS
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

        if self.frame and self.frame:IsVisible() then
            self.frame:Hide()
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Interação com Mercador encerrada.")
    end
end

-- ----------------------------------------------------------------------------
-- 8. INICIALIZAÇÃO DO MÓDULO & REGISTRO DE EVENTOS
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

    ef:SetScript("OnEvent", function()
        if event == "MERCHANT_SHOW" then
            MerchantMenu:OnMerchantShow()
        elseif event == "MERCHANT_UPDATE" then
            MerchantMenu:OnMerchantUpdate()
        elseif event == "MERCHANT_CLOSED" then
            MerchantMenu:OnMerchantClosed()
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
