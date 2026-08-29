--[[
    ConsoleMode - Vanilla
    UI/MainMenu.lua - Hub Central do Menu Principal (Console / Zelda Style)

    Estrutura Visual:
      [====================== MENU PRINCIPAL ======================]
      |  [ PALCO DO PERSONAGEM (ESQUERDA) ]    |  [ CONTAINER DE ABAS & GRID ] |
      |  - Equipamentos (Esq)                  |  - Abas: [L1] Bolsas | Spells [R1]
      |  - Modelo 3D Jogador (Centro)          |  - Grid de Itens / Magias     |
      |  - Atributos & Buffs Ativos (Dir)      |  - Tooltip Fixo (Inf. Direita)|
      [=================== [D-Pad] (A) (Y) (B) ====================]

    - FASE 1: Canvas 100% Responsivo por Porcentagem com renderização 9-Slice
    - FASE 2: Palco do Personagem 3D transparente (SetUnit('player')) com giro livre 360°
    - FASE 3: Lista de Equipamentos, Atributos Base e Lista Vertical de Buffs Ativos
    - Suporte a navegação por Gamepad e teclado
    - Compatível com Lua 5.0 / WoW 1.12.1
]]

_G = getfenv(0)

local CM = ConsoleMode or {}
CM.mainMenu = CM.mainMenu or {}

local MainMenu = CM.mainMenu

-- ============================================================================
-- ██████████████████████   BLOCO DE CONFIGURAÇÃO   ███████████████████████████
--
-- Todas as variáveis visuais de posição, tamanho, proporção, texturas, cores,
-- fontes, modelo 3D, equipamentos, status e buffs estão centralizadas aqui.
-- Edite este bloco para ajustar a aparência sem mexer na lógica do código.
-- ============================================================================

local CFG = {}

-- ----------------------------------------------------------------------------
-- 1. JANELA PRINCIPAL (CANVAS ROOT RESPONSIVO)
-- Dimensionamento dinâmico baseado no tamanho da tela do jogador (UIParent).
-- ----------------------------------------------------------------------------
CFG.Window = {
    usePercentage   = true,                 -- true = calcula por porcentagem da tela, false = estático
    widthPercent    = 0.88,                 -- Fração da largura útil da tela (88%)
    heightPercent   = 0.84,                 -- Fração da altura útil da tela (84%)
    
    minWidth        = 840,                  -- Largura mínima para telas muito compactas (px)
    minHeight       = 520,                  -- Altura mínima (px)
    maxWidth        = 1440,                 -- Largura máxima para telas Ultrawide/4K (px)
    maxHeight       = 920,                  -- Altura máxima (px)

    staticWidth     = 980,                  -- Largura estática de fallback
    staticHeight    = 620,                  -- Altura estática de fallback

    point           = "CENTER",             -- Ponto de ancoragem na tela
    relPoint        = "CENTER",             -- Ponto relativo no UIParent
    offsetX         = 0,                    -- Deslocamento horizontal (0 = centralizado)
    offsetY         = 0,                    -- Deslocamento vertical (0 = centralizado)
    frameStrata     = "FULLSCREEN_DIALOG",  -- Camada de renderização
    frameLevel      = 100,                  -- Nível de sobreposição dentro da strata
}

-- ----------------------------------------------------------------------------
-- 2. DIMMER DE FUNDO (EFEITO ESCURECIDO DE IMERSÃO)
-- ----------------------------------------------------------------------------
CFG.Dimmer = {
    enabled         = true,                 -- true = ativa o fundo escurecido, false = desativa
    frameStrata     = "FULLSCREEN",         -- Camada de renderização
    frameLevel      = 50,                   -- Nível de sobreposição
    color           = { r = 0.0, g = 0.0, b = 0.0, a = 0.65 }, -- Cor e opacidade (RGBA 0-1)
}

-- ----------------------------------------------------------------------------
-- 3. TEXTURA 9-SLICE DE PERGAMINHO / BANNER
-- ----------------------------------------------------------------------------
CFG.NineSlice = {
    texture         = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Carved_9Slides.tga",
    cornerSize      = 48,                   -- Tamanho dos 4 cantos fixos (px)
    drawLayer       = "BACKGROUND",         -- Camada de desenho das fatias

    uv = {
        col = {
            { 0.0000, 0.2500 },             -- Esquerda (0 a 64px de 256px)
            { 0.2500, 0.5000 },             -- Centro (64 a 128px de 256px)
            { 0.5000, 0.7500 },             -- Direita (128 a 192px de 256px)
        },
        row = {
            { 0.0000, 0.2500 },             -- Topo (0 a 64px de 256px)
            { 0.2500, 0.5000 },             -- Meio (64 a 128px de 256px)
            { 0.5000, 0.7500 },             -- Fundo (128 a 192px de 256px)
        }
    }
}

-- ----------------------------------------------------------------------------
-- 4. TÍTULO SUPERIOR
-- ----------------------------------------------------------------------------
CFG.Title = {
    show            = true,                 -- true = exibe o título, false = oculta
    text            = "|cffffd200MENU PRINCIPAL|r",
    font            = "GameFontNormalLarge",-- Fonte base da Blizzard
    offsetY         = -22,                  -- Posição Y a partir do topo da janela (px)
}

-- ----------------------------------------------------------------------------
-- 5. PAINEL ESQUERDO: PALCO DO PERSONAGEM (ESTRUTURA GERAL)
-- ----------------------------------------------------------------------------
CFG.LeftPanel = {
    paddingLeft     = 28,                   -- Margem em relação à borda esquerda do menu (px)
    paddingTop      = -50,                  -- Margem em relação ao topo do menu (px)
    paddingBottom   = 50,                   -- Margem em relação ao fundo do menu (px)
    widthRatio      = 0.46,                 -- 46% da largura útil interna da janela
}

-- ----------------------------------------------------------------------------
-- 5.1. MODELO 3D DO PERSONAGEM (FASE 2)
-- ----------------------------------------------------------------------------
CFG.PlayerModel = {
    width           = 220,                  -- Largura da viewport 3D (px)
    height          = 420,                  -- Altura da viewport 3D (px)
    offsetX         = 0,                    -- Deslocamento horizontal central (px)
    offsetY         = -10,                  -- Deslocamento vertical central (px)
    defaultFacing   = 0.0,                  -- Rotação inicial (radianos)
    rotateSpeed     = 0.03,                 -- Velocidade de giro com mouse/analógico
    enableMouseDrag = true,                 -- true = arrastar com mouse gira o boneco
    showPlayerName  = true,                 -- true = exibe nome e guilda na base
    nameFont        = "GameFontHighlightLarge",
    guildFont       = "GameFontNormalSmall",
}

-- ----------------------------------------------------------------------------
-- 5.2. COLUNA DE EQUIPAMENTOS (FASE 3 - À ESQUERDA DO PERSONAGEM 3D)
-- Lista vertical com os slots e nomes dos itens equipados.
-- ----------------------------------------------------------------------------
CFG.Equipment = {
    width           = 140,                  -- Largura da coluna de equipamentos (px)
    iconSize        = 22,                   -- Tamanho do ícone do slot (px)
    itemHeight      = 24,                   -- Altura de cada linha de equipamento (px)
    gapY            = 4,                    -- Espaçamento vertical entre os itens (px)
    slotFont        = "GameFontNormalSmall",-- Fonte do tipo de slot (menor)
    nameFont        = "GameFontHighlightSmall", -- Fonte do nome do item
    slotColor       = "|cff888888",         -- Cor do tipo de slot (ex: CABEÇA, PEITORAL)
    emptyColor      = "|cff555555",         -- Cor para slots vazios
    showEmptySlots  = true,                 -- true = exibe o nome do slot mesmo se vazio
    showDivider     = true,                 -- true = exibe linha divisória abaixo de cada slot
    dividerHeight   = 1,                    -- Espessura da linha divisória (px)
    dividerColor    = { r = 0.5, g = 0.4, b = 0.3, a = 0.35 }, -- Cor e opacidade da linha divisória
    dividerTexture  = "Interface\\Tooltips\\UI-Tooltip-Background",
    slots = {
        { name = "HeadSlot",          label = "CABEÇA" },
        { name = "NeckSlot",          label = "COLAR" },
        { name = "ShoulderSlot",      label = "OMBROS" },
        { name = "BackSlot",          label = "CAPA" },
        { name = "ChestSlot",         label = "PEITORAL" },
        { name = "WristSlot",         label = "PUNHOS" },
        { name = "HandsSlot",         label = "LUVAS" },
        { name = "WaistSlot",         label = "CINTO" },
        { name = "LegsSlot",          label = "PERNAS" },
        { name = "FeetSlot",          label = "BOTAS" },
        { name = "Finger0Slot",       label = "ANEL 1" },
        { name = "Finger1Slot",       label = "ANEL 2" },
        { name = "Trinket0Slot",      label = "BERLOQUE 1" },
        { name = "Trinket1Slot",      label = "BERLOQUE 2" },
        { name = "MainHandSlot",      label = "MÃO DIR." },
        { name = "SecondaryHandSlot", label = "MÃO ESQ." },
        { name = "RangedSlot",        label = "ALCANCE" },
    }
}

-- ----------------------------------------------------------------------------
-- 5.3. COLUNA DE ATRIBUTOS E BUFFS ATIVOS (FASE 3 - À DIREITA DO PERSONAGEM)
-- Exibição de atributos base e lista de buffs no estilo Zelda TotK/BotW.
-- ----------------------------------------------------------------------------
CFG.StatsAndBuffs = {
    width           = 135,                  -- Largura da coluna de status e buffs (px)
    headerFont      = "GameFontNormal",     -- Fonte dos cabeçalhos de seção
    statFont        = "GameFontHighlightSmall",
    buffIconSize    = 18,                   -- Tamanho do ícone de buff (px)
    buffGapY        = 4,                    -- Espaçamento vertical entre buffs (px)
    maxBuffs        = 6,                    -- Quantidade máxima de buffs visíveis na lista
    durationColor   = "|cff88ccff",         -- Cor do tempo restante do buff
    barColor        = { r = 0.2, g = 0.7, b = 1.0 }, -- Cor da barrinha de duração estilo Zelda
}

-- ----------------------------------------------------------------------------
-- 6. PAINEL DIREITO: CONTAINER DE CONTEÚDO DAS ABAS (BOLSAS / SPELLBOOK)
-- ----------------------------------------------------------------------------
CFG.RightPanel = {
    paddingRight    = -28,                  -- Margem em relação à borda direita do menu (px)
    paddingTop      = -50,                  -- Margem em relação ao topo do menu (px)
    paddingBottom   = 50,                   -- Margem em relação ao fundo do menu (px)
    gapX            = 16,                   -- Espaçamento entre o painel esquerdo e direito (px)
}

-- ----------------------------------------------------------------------------
-- 7. DIVISÓRIA CENTRAL
-- ----------------------------------------------------------------------------
CFG.Divider = {
    show            = true,                 -- true = exibe a divisória, false = oculta
    texture         = "Interface\\Tooltips\\UI-Tooltip-Border",
    width           = 2,                    -- Espessura da divisória (px)
    paddingTop      = 0,
    paddingBottom   = 0,
    color           = { r = 0.6, g = 0.5, b = 0.3, a = 0.4 },
}

-- ----------------------------------------------------------------------------
-- 8. RODAPÉ DE ATALHOS (CONSOLE HINTS)
-- ----------------------------------------------------------------------------
CFG.Footer = {
    height          = 36,                   -- Altura da barra de rodapé (px)
    paddingLeft     = 28,                   -- Margem esquerda (px)
    paddingRight    = -28,                  -- Margem direita (px)
    offsetY         = 12,                   -- Distância da base da janela (px)
    font            = "GameFontNormalSmall",
    text            = "|cffffffff[D-Pad/L-Stick]|r Navegar   |   |cffffffff(A)|r Selecionar   |   |cffffffff(Y)|r Menu de Contexto   |   |cffffffff(B)|r Fechar   |   |cffffffff[R-Stick / Mouse]|r Girar 3D",
}

-- ----------------------------------------------------------------------------
-- 9. EFEITOS SONOROS NATIVOS
-- ----------------------------------------------------------------------------
CFG.Audio = {
    soundOpen       = "igMainMenuOpen",
    soundClose      = "igMainMenuClose",
    soundTabChange  = "igCharacterInfoTab",
}

-- ============================================================================
-- TOOLTIP SCANNER PARA BUFFS E ITENS
-- ============================================================================

local scanTip = CreateFrame("GameTooltip", "ConsoleModeMMScanTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

function MainMenu:GetBuffName(buffIndexID)
    scanTip:ClearLines()
    scanTip:SetPlayerBuff(buffIndexID)
    local text = ConsoleModeMMScanTooltipTextLeft1:GetText()
    return text or "Efeito Ativo"
end

-- ============================================================================
-- RENDERIZADOR 9-SLICE (Padrão Unity / Sliced Image no WoW 1.12)
-- ============================================================================

function MainMenu:Create9Slice(parent, texturePath, cornerSize, uvMap, drawLayer)
    if not parent or not texturePath then return nil end

    cornerSize = cornerSize or CFG.NineSlice.cornerSize
    uvMap = uvMap or CFG.NineSlice.uv
    drawLayer = drawLayer or CFG.NineSlice.drawLayer

    local slices = {}

    local function makeSlice(name, u1, u2, v1, v2)
        local tex = parent:CreateTexture(nil, drawLayer)
        tex:SetTexture(texturePath)
        tex:SetTexCoord(u1, u2, v1, v2)
        return tex
    end

    local c = uvMap.col
    local r = uvMap.row

    -- 1. Cantos (Tamanho fixo)
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

    -- 2. Bordas Horizontais (Esticam no eixo X)
    slices.top = makeSlice("Top", c[2][1], c[2][2], r[1][1], r[1][2])
    slices.top:SetHeight(cornerSize)
    slices.top:SetPoint("TOPLEFT", slices.topLeft, "TOPRIGHT", 0, 0)
    slices.top:SetPoint("TOPRIGHT", slices.topRight, "TOPLEFT", 0, 0)

    slices.bottom = makeSlice("Bottom", c[2][1], c[2][2], r[3][1], r[3][2])
    slices.bottom:SetHeight(cornerSize)
    slices.bottom:SetPoint("BOTTOMLEFT", slices.bottomLeft, "BOTTOMRIGHT", 0, 0)
    slices.bottom:SetPoint("BOTTOMRIGHT", slices.bottomRight, "BOTTOMLEFT", 0, 0)

    -- 3. Bordas Verticais (Esticam no eixo Y)
    slices.left = makeSlice("Left", c[1][1], c[1][2], r[2][1], r[2][2])
    slices.left:SetWidth(cornerSize)
    slices.left:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMLEFT", 0, 0)
    slices.left:SetPoint("BOTTOMLEFT", slices.bottomLeft, "TOPLEFT", 0, 0)

    slices.right = makeSlice("Right", c[3][1], c[3][2], r[2][1], r[2][2])
    slices.right:SetWidth(cornerSize)
    slices.right:SetPoint("TOPRIGHT", slices.topRight, "BOTTOMRIGHT", 0, 0)
    slices.right:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPRIGHT", 0, 0)

    -- 4. Centro (Preenchimento)
    slices.center = makeSlice("Center", c[2][1], c[2][2], r[2][1], r[2][2])
    slices.center:SetPoint("TOPLEFT", slices.topLeft, "BOTTOMRIGHT", 0, 0)
    slices.center:SetPoint("BOTTOMRIGHT", slices.bottomRight, "TOPLEFT", 0, 0)

    return slices
end

-- ============================================================================
-- CÁLCULO E ATUALIZAÇÃO RESPONSIVA DE LAYOUT
-- ============================================================================

function MainMenu:UpdateLayout()
    if not self.frame then return end

    local targetW, targetH

    if CFG.Window.usePercentage then
        local screenW = (UIParent and UIParent:GetWidth()) or 1024
        local screenH = (UIParent and UIParent:GetHeight()) or 768

        targetW = math.floor(screenW * CFG.Window.widthPercent)
        targetH = math.floor(screenH * CFG.Window.heightPercent)

        if CFG.Window.minWidth and targetW < CFG.Window.minWidth then targetW = CFG.Window.minWidth end
        if CFG.Window.maxWidth and targetW > CFG.Window.maxWidth then targetW = CFG.Window.maxWidth end
        if CFG.Window.minHeight and targetH < CFG.Window.minHeight then targetH = CFG.Window.minHeight end
        if CFG.Window.maxHeight and targetH > CFG.Window.maxHeight then targetH = CFG.Window.maxHeight end
    else
        targetW = CFG.Window.staticWidth
        targetH = CFG.Window.staticHeight
    end

    self.frame:SetWidth(targetW)
    self.frame:SetHeight(targetH)

    local availableW = targetW - (CFG.LeftPanel.paddingLeft + math.abs(CFG.RightPanel.paddingRight) + CFG.RightPanel.gapX)
    local leftW = math.floor(availableW * CFG.LeftPanel.widthRatio)

    if self.frame.leftPanel then
        self.frame.leftPanel:SetWidth(leftW)
    end

    if self.frame.divider and self.frame.leftPanel then
        self.frame.divider:ClearAllPoints()
        local divGap = math.floor(CFG.RightPanel.gapX / 2)
        self.frame.divider:SetPoint("TOP", self.frame.leftPanel, "TOPRIGHT", divGap, CFG.Divider.paddingTop)
        self.frame.divider:SetPoint("BOTTOM", self.frame.leftPanel, "BOTTOMRIGHT", divGap, CFG.Divider.paddingBottom)
    end
end

-- ============================================================================
-- 1. MODELO 3D DO PERSONAGEM (FASE 2)
-- ============================================================================

function MainMenu:CreatePlayerModel(leftPanel)
    if self.playerModel then return self.playerModel end

    local model = CreateFrame("PlayerModel", "ConsoleModeMM_PlayerModel", leftPanel)
    model:SetPoint("CENTER", leftPanel, "CENTER", CFG.PlayerModel.offsetX, CFG.PlayerModel.offsetY)
    model:SetWidth(CFG.PlayerModel.width)
    model:SetHeight(CFG.PlayerModel.height)
    model:SetFrameLevel(leftPanel:GetFrameLevel() + 5)
    model.rotation = CFG.PlayerModel.defaultFacing or 0

    if CFG.PlayerModel.enableMouseDrag then
        model:EnableMouse(true)
        model:SetScript("OnMouseDown", function()
            if arg1 == "LeftButton" or arg1 == "RightButton" then
                this.isDragging = true
                local curX, curY = GetCursorPosition()
                this.prevMouseX = curX
            end
        end)

        model:SetScript("OnMouseUp", function()
            this.isDragging = false
        end)

        model:SetScript("OnUpdate", function()
            if this.isDragging then
                local curX, curY = GetCursorPosition()
                if this.prevMouseX then
                    local diffX = curX - this.prevMouseX
                    if diffX ~= 0 then
                        this.rotation = (this.rotation or 0) + (diffX * CFG.PlayerModel.rotateSpeed)
                        this:SetFacing(this.rotation)
                        this.prevMouseX = curX
                    end
                end
            end
        end)
    end

    if CFG.PlayerModel.showPlayerName then
        local infoBox = CreateFrame("Frame", "ConsoleModeMM_PlayerInfo", leftPanel)
        infoBox:SetHeight(48)
        infoBox:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 8)
        infoBox:SetPoint("LEFT", leftPanel, "LEFT", 12, 0)
        infoBox:SetPoint("RIGHT", leftPanel, "RIGHT", -12, 0)

        local nameText = infoBox:CreateFontString(nil, "OVERLAY", CFG.PlayerModel.nameFont)
        nameText:SetPoint("TOP", infoBox, "TOP", 0, 0)
        nameText:SetText(UnitName("player") or "Jogador")

        local subText = infoBox:CreateFontString(nil, "OVERLAY", CFG.PlayerModel.guildFont)
        subText:SetPoint("TOP", nameText, "BOTTOM", 0, -2)

        model.infoBox  = infoBox
        model.nameText = nameText
        model.subText  = subText
    end

    self.playerModel = model
    return model
end

function MainMenu:UpdatePlayerModel()
    if not self.playerModel then return end

    self.playerModel:ClearModel()
    self.playerModel:SetUnit("player")
    self.playerModel:SetFacing(self.playerModel.rotation or CFG.PlayerModel.defaultFacing or 0)
    self.playerModel:SetSequence(0)

    if self.playerModel.nameText then
        local pName = UnitName("player") or "Jogador"
        self.playerModel.nameText:SetText("|cffffd200" .. pName .. "|r")
    end

    if self.playerModel.subText then
        local guildName = GetGuildInfo("player")
        local race = UnitRace("player") or ""
        local class = UnitClass("player") or ""
        local level = UnitLevel("player") or 1

        if guildName then
            self.playerModel.subText:SetText("|cffffcc00<" .. guildName .. ">|r  |cffffffffNv " .. level .. " " .. race .. " " .. class .. "|r")
        else
            self.playerModel.subText:SetText("|cffffffffNv " .. level .. " " .. race .. " " .. class .. "|r")
        end
    end
end

-- ============================================================================
-- 2. COLUNA DE EQUIPAMENTOS (FASE 3 - ESQUERDA DO PERSONAGEM)
-- ============================================================================

function MainMenu:CreateEquipmentColumn(leftPanel)
    if self.equipColumn then return self.equipColumn end

    local container = CreateFrame("Frame", "ConsoleModeMM_EquipColumn", leftPanel)
    container:SetWidth(CFG.Equipment.width)
    container:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 4, -8)
    container:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMLEFT", 4, 52)

    container.buttons = {}
    local prev = nil

    for i, slotData in ipairs(CFG.Equipment.slots) do
        local btn = CreateFrame("Button", "ConsoleModeMM_EquipSlot" .. i, container)
        btn:SetHeight(CFG.Equipment.itemHeight or 24)
        btn:SetPoint("LEFT", container, "LEFT", 0, 0)
        btn:SetPoint("RIGHT", container, "RIGHT", 0, 0)

        if not prev then
            btn:SetPoint("TOP", container, "TOP", 0, 0)
        else
            btn:SetPoint("TOP", prev, "BOTTOM", 0, -CFG.Equipment.gapY)
        end

        -- Ícone do Slot
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(CFG.Equipment.iconSize)
        icon:SetHeight(CFG.Equipment.iconSize)
        icon:SetPoint("LEFT", btn, "LEFT", 0, 0)
        btn.icon = icon

        -- Moldura sutil ao redor do ícone
        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
        border:SetVertexColor(0.7, 0.7, 0.7, 0.6)
        btn.border = border

        -- 1. Linha Superior: Nome do Slot (CABEÇA, PEITORAL, etc.)
        local slotText = btn:CreateFontString(nil, "OVERLAY", CFG.Equipment.slotFont)
        slotText:SetPoint("LEFT", icon, "RIGHT", 5, 5)
        slotText:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
        slotText:SetJustifyH("LEFT")
        btn.slotText = slotText

        -- 2. Linha Inferior: Nome do Item agrupado logo abaixo do slot
        local nameText = btn:CreateFontString(nil, "OVERLAY", CFG.Equipment.nameFont)
        nameText:SetPoint("TOPLEFT", slotText, "BOTTOMLEFT", 0, -1)
        nameText:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
        nameText:SetJustifyH("LEFT")
        btn.nameText = nameText

        -- 3. Linha divisória horizontal sólida e sutil abaixo de cada slot
        if CFG.Equipment.showDivider then
            local div = btn:CreateTexture(nil, "BACKGROUND")
            div:SetTexture(CFG.Equipment.dividerTexture)
            div:SetHeight(CFG.Equipment.dividerHeight or 1)
            div:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
            div:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
            local dCol = CFG.Equipment.dividerColor
            div:SetVertexColor(dCol.r, dCol.g, dCol.b, dCol.a)
            btn.div = div
        end

        btn.slotData = slotData
        table.insert(container.buttons, btn)
        prev = btn
    end

    self.equipColumn = container
    return container
end

function MainMenu:UpdateEquipmentColumn()
    if not self.equipColumn or not self.equipColumn.buttons then return end

    for _, btn in ipairs(self.equipColumn.buttons) do
        local slotName = btn.slotData.name
        local slotLabel = btn.slotData.label
        local slotID, emptyTex = GetInventorySlotInfo(slotName)

        if slotID then
            local itemTexture = GetInventoryItemTexture("player", slotID)
            local itemLink = GetInventoryItemLink("player", slotID)

            if itemTexture and itemLink then
                btn.icon:SetTexture(itemTexture)

                -- Extrai nome, itemID e cor diretamente da estrutura do itemLink no Vanilla 1.12
                local _, _, colorHex, rawLink, nameFromLink = string.find(itemLink, "|c(%x+)|H(item:%d+:%d+:%d+:%d+)|h%[(.-)%]|h|r")
                
                local itemName = nameFromLink
                local itemQuality = nil

                if rawLink then
                    local nameFromInfo, _, qualityFromInfo = GetItemInfo(rawLink)
                    if nameFromInfo then
                        itemName = nameFromInfo
                        itemQuality = qualityFromInfo
                    end
                end

                -- Fallback via Scanner Tooltip caso GetItemInfo falhe
                if not itemName then
                    scanTip:ClearLines()
                    scanTip:SetInventoryItem("player", slotID)
                    itemName = ConsoleModeMMScanTooltipTextLeft1:GetText()
                end

                itemName = itemName or slotLabel

                -- 1. Exibe o nome do slot em cima (menor)
                btn.slotText:SetText(CFG.Equipment.slotColor .. slotLabel .. "|r")

                -- 2. Exibe o nome do item embaixo com a cor de qualidade
                if colorHex then
                    btn.nameText:SetText("|c" .. colorHex .. itemName .. "|r")
                elseif itemQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality] then
                    local color = ITEM_QUALITY_COLORS[itemQuality]
                    btn.nameText:SetText(color.hex .. itemName .. "|r")
                    btn.border:SetVertexColor(color.r, color.g, color.b, 0.9)
                else
                    btn.nameText:SetText("|cffffffff" .. itemName .. "|r")
                    btn.border:SetVertexColor(0.8, 0.8, 0.8, 0.6)
                end
            else
                btn.icon:SetTexture(emptyTex or "Interface\\Icons\\INV_Misc_QuestionMark")
                btn.slotText:SetText(CFG.Equipment.emptyColor .. slotLabel .. "|r")
                btn.nameText:SetText(CFG.Equipment.emptyColor .. "(Vazio)|r")
                btn.border:SetVertexColor(0.4, 0.4, 0.4, 0.4)
            end
        end
    end
end

-- ============================================================================
-- 3. COLUNA DE ATRIBUTOS E BUFFS (FASE 3 - DIREITA DO PERSONAGEM)
-- ============================================================================

function MainMenu:CreateStatsAndBuffsColumn(leftPanel)
    if self.statsAndBuffs then return self.statsAndBuffs end

    local container = CreateFrame("Frame", "ConsoleModeMM_StatsColumn", leftPanel)
    container:SetWidth(CFG.StatsAndBuffs.width)
    container:SetPoint("TOPRIGHT", leftPanel, "TOPRIGHT", -4, -8)
    container:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -4, 52)

    -- 1. Seção de Atributos Base
    local statsHeader = container:CreateFontString(nil, "OVERLAY", CFG.StatsAndBuffs.headerFont)
    statsHeader:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    statsHeader:SetText("|cffffd200STATUS|r")

    local statLines = {}
    local statKeys = { "HP", "Recurso", "Força", "Agilidade", "Vigor", "Intelecto", "Espírito", "Armadura", "Ouro" }
    local prevStat = statsHeader

    for i, key in ipairs(statKeys) do
        local line = container:CreateFontString(nil, "OVERLAY", CFG.StatsAndBuffs.statFont)
        line:SetPoint("TOPLEFT", prevStat, "BOTTOMLEFT", 0, -2)
        line:SetPoint("RIGHT", container, "RIGHT", 0, 0)
        line:SetJustifyH("LEFT")
        statLines[key] = line
        prevStat = line
    end
    container.statLines = statLines

    -- 2. Linha Divisória Horizontal Sutil
    local statDiv = container:CreateTexture(nil, "ARTWORK")
    statDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    statDiv:SetHeight(1)
    statDiv:SetPoint("TOPLEFT", prevStat, "BOTTOMLEFT", 0, -6)
    statDiv:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    statDiv:SetVertexColor(0.5, 0.4, 0.3, 0.4)

    -- 3. Seção de Buffs Ativos (Estilo Zelda)
    local buffHeader = container:CreateFontString(nil, "OVERLAY", CFG.StatsAndBuffs.headerFont)
    buffHeader:SetPoint("TOPLEFT", statDiv, "BOTTOMLEFT", 0, -6)
    buffHeader:SetText("|cff00ffccBUFFS ATIVOS|r")

    local buffRows = {}
    local prevBuff = buffHeader

    for b = 1, CFG.StatsAndBuffs.maxBuffs do
        local row = CreateFrame("Frame", "ConsoleModeMM_BuffRow" .. b, container)
        row:SetHeight(CFG.StatsAndBuffs.buffIconSize)
        row:SetPoint("LEFT", container, "LEFT", 0, 0)
        row:SetPoint("RIGHT", container, "RIGHT", 0, 0)
        row:SetPoint("TOP", prevBuff, "BOTTOM", 0, -CFG.StatsAndBuffs.buffGapY)

        -- Ícone do Buff
        local bIcon = row:CreateTexture(nil, "ARTWORK")
        bIcon:SetWidth(CFG.StatsAndBuffs.buffIconSize)
        bIcon:SetHeight(CFG.StatsAndBuffs.buffIconSize)
        bIcon:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.icon = bIcon

        -- Moldura do ícone de buff
        local bBorder = row:CreateTexture(nil, "OVERLAY")
        bBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        bBorder:SetPoint("TOPLEFT", bIcon, "TOPLEFT", -1, 1)
        bBorder:SetPoint("BOTTOMRIGHT", bIcon, "BOTTOMRIGHT", 1, -1)
        bBorder:SetVertexColor(0.2, 0.8, 1.0, 0.7)

        -- Nome do Buff
        local bName = row:CreateFontString(nil, "OVERLAY", CFG.StatsAndBuffs.statFont)
        bName:SetPoint("LEFT", bIcon, "RIGHT", 4, 0)
        bName:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        bName:SetJustifyH("LEFT")
        row.name = bName

        -- Barrinha decorativa de duração estilo Zelda abaixo do nome
        local bBar = row:CreateTexture(nil, "BACKGROUND")
        bBar:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bBar:SetHeight(2)
        bBar:SetPoint("TOPLEFT", bName, "BOTTOMLEFT", 0, -1)
        bBar:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local barC = CFG.StatsAndBuffs.barColor
        bBar:SetVertexColor(barC.r, barC.g, barC.b, 0.8)
        row.bar = bBar

        row:Hide()
        table.insert(buffRows, row)
        prevBuff = row
    end
    container.buffRows = buffRows

    self.statsAndBuffs = container
    return container
end

function MainMenu:UpdateStatsAndBuffs()
    if not self.statsAndBuffs then return end

    -- 1. Atualiza Atributos Base
    local lines = self.statsAndBuffs.statLines
    if lines then
        local hp = UnitHealth("player") or 0
        local maxHP = UnitHealthMax("player") or 1
        lines["HP"]:SetText("|cffffffffHP:|r |cff00ff00" .. hp .. "|r / " .. maxHP)

        local pType = UnitPowerType("player") -- 0 = Mana, 1 = Rage, 2 = Focus, 3 = Energy
        local mana = UnitMana("player") or 0
        local maxMana = UnitManaMax("player") or 1
        local powerName = (pType == 1 and "Rage") or (pType == 3 and "Energia") or "Mana"
        local powerColor = (pType == 1 and "|cffff3333") or (pType == 3 and "|cffffff00") or "|cff00ccff"
        lines["Recurso"]:SetText("|cffffffff" .. powerName .. ":|r " .. powerColor .. mana .. "|r / " .. maxMana)

        lines["Força"]:SetText("|cffaaaaaaForça:|r |cffffffff" .. (UnitStat("player", 1) or 0) .. "|r")
        lines["Agilidade"]:SetText("|cffaaaaaaAgilidade:|r |cffffffff" .. (UnitStat("player", 2) or 0) .. "|r")
        lines["Vigor"]:SetText("|cffaaaaaaVigor:|r |cffffffff" .. (UnitStat("player", 3) or 0) .. "|r")
        lines["Intelecto"]:SetText("|cffaaaaaaIntelecto:|r |cffffffff" .. (UnitStat("player", 4) or 0) .. "|r")
        lines["Espírito"]:SetText("|cffaaaaaaEspírito:|r |cffffffff" .. (UnitStat("player", 5) or 0) .. "|r")

        local baseArmor, armorEff = UnitArmor("player")
        lines["Armadura"]:SetText("|cffaaaaaaArmadura:|r |cffffffff" .. (armorEff or 0) .. "|r")

        -- Dinheiro
        local money = GetMoney() or 0
        local gold = math.floor(money / 10000)
        local silver = math.floor(math.mod(money, 10000) / 100)
        local copper = math.mod(money, 100)
        lines["Ouro"]:SetText(string.format("|cffffd200%dg|r |cffc0c0c0%ds|r |cffcc8833%dc|r", gold, silver, copper))
    end

    -- 2. Atualiza Buffs Ativos (Estilo Zelda)
    local rows = self.statsAndBuffs.buffRows
    if rows then
        local buffCount = 0
        for i = 0, 31 do
            local buffIndex = GetPlayerBuff(i, "HELPFUL")
            if buffIndex < 0 or buffCount >= CFG.StatsAndBuffs.maxBuffs then
                break
            end

            buffCount = buffCount + 1
            local row = rows[buffCount]
            local tex = GetPlayerBuffTexture(buffIndex)
            local timeLeft = GetPlayerBuffTimeLeft(buffIndex)
            local buffName = self:GetBuffName(buffIndex)

            row.icon:SetTexture(tex or "Interface\\Icons\\Spell_Holy_WordFortitude")

            -- Formata a duração (ex: 35m, 12s, 1h)
            local durStr = ""
            if timeLeft and timeLeft > 0 then
                if timeLeft >= 3600 then
                    durStr = " " .. CFG.StatsAndBuffs.durationColor .. "(" .. math.floor(timeLeft / 3600) .. "h)|r"
                elseif timeLeft >= 60 then
                    durStr = " " .. CFG.StatsAndBuffs.durationColor .. "(" .. math.floor(timeLeft / 60) .. "m)|r"
                else
                    durStr = " " .. CFG.StatsAndBuffs.durationColor .. "(" .. math.floor(timeLeft) .. "s)|r"
                end
            end

            row.name:SetText("|cffffffff" .. buffName .. "|r" .. durStr)
            row:Show()
        end

        -- Esconde as linhas sobressalentes
        for b = buffCount + 1, CFG.StatsAndBuffs.maxBuffs do
            rows[b]:Hide()
        end
    end
end

-- ============================================================================
-- CRIAÇÃO DA JANELA PRINCIPAL (MAIN MENU FRAME)
-- ============================================================================

function MainMenu:CreateUI()
    if self.frame then return end

    -- 1. Dimmer de Fundo
    local dimmer = CreateFrame("Frame", "ConsoleModeMainMenuDimmer", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata(CFG.Dimmer.frameStrata)
    dimmer:SetFrameLevel(CFG.Dimmer.frameLevel)
    dimmer:EnableMouse(true)
    dimmer:Hide()

    if CFG.Dimmer.enabled then
        local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
        dimTex:SetAllPoints(dimmer)
        local dColor = CFG.Dimmer.color
        dimTex:SetTexture(dColor.r, dColor.g, dColor.b, dColor.a)
    end
    self.dimmer = dimmer

    -- 2. Frame Principal da Janela
    local frame = CreateFrame("Frame", "ConsoleModeMainMenuFrame", UIParent)
    frame:SetPoint(CFG.Window.point, UIParent, CFG.Window.relPoint, CFG.Window.offsetX, CFG.Window.offsetY)
    frame:SetFrameStrata(CFG.Window.frameStrata)
    frame:SetFrameLevel(CFG.Window.frameLevel)
    frame:EnableMouse(true)
    frame:Hide()

    -- 3. Aplica a Textura 9-Slice de Pergaminho
    self.slices = self:Create9Slice(
        frame, 
        CFG.NineSlice.texture, 
        CFG.NineSlice.cornerSize, 
        CFG.NineSlice.uv, 
        CFG.NineSlice.drawLayer
    )

    -- 4. Título Superior Central
    if CFG.Title.show then
        local titleText = frame:CreateFontString(nil, "OVERLAY", CFG.Title.font)
        titleText:SetPoint("TOP", frame, "TOP", 0, CFG.Title.offsetY)
        titleText:SetText(CFG.Title.text)
        frame.title = titleText
    end

    -- 5. Painel Esquerdo: Palco do Personagem (Esquerda)
    local leftPanel = CreateFrame("Frame", "ConsoleModeMM_LeftPanel", frame)
    leftPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.LeftPanel.paddingLeft, CFG.LeftPanel.paddingTop)
    leftPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.LeftPanel.paddingLeft, CFG.LeftPanel.paddingBottom)
    frame.leftPanel = leftPanel

    -- 5.1. Coluna de Equipamentos (FASE 3 - À Esquerda do Modelo)
    self:CreateEquipmentColumn(leftPanel)

    -- 5.2. Modelo 3D do Personagem (FASE 2 - Centro do Palco)
    self:CreatePlayerModel(leftPanel)

    -- 5.3. Coluna de Atributos e Buffs (FASE 3 - À Direita do Modelo)
    self:CreateStatsAndBuffsColumn(leftPanel)

    -- 6. Painel Direito: Container de Conteúdo e Abas (Direita)
    local rightPanel = CreateFrame("Frame", "ConsoleModeMM_RightPanel", frame)
    rightPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingTop)
    rightPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingBottom)
    rightPanel:SetPoint("LEFT", leftPanel, "RIGHT", CFG.RightPanel.gapX, 0)
    frame.rightPanel = rightPanel

    -- Marcador visual temporário para validação das Fases iniciais
    local rightHeader = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rightHeader:SetPoint("TOP", rightPanel, "TOP", 0, -10)
    rightHeader:SetText("|cffffcc00[ Container de Conteúdo da Aba ]|r")

    -- 7. Divisória Central Sutil
    if CFG.Divider.show then
        local divider = frame:CreateTexture(nil, "ARTWORK")
        divider:SetTexture(CFG.Divider.texture)
        divider:SetWidth(CFG.Divider.width)
        local divCol = CFG.Divider.color
        divider:SetVertexColor(divCol.r, divCol.g, divCol.b, divCol.a)
        frame.divider = divider
    end

    -- 8. Rodapé com Dicas do Controle (Console Hints)
    local footer = CreateFrame("Frame", "ConsoleModeMM_Footer", frame)
    footer:SetHeight(CFG.Footer.height)
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.Footer.paddingLeft, CFG.Footer.offsetY)
    footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", CFG.Footer.paddingRight, CFG.Footer.offsetY)
    frame.footer = footer

    local footerText = footer:CreateFontString(nil, "OVERLAY", CFG.Footer.font)
    footerText:SetPoint("CENTER", footer, "CENTER", 0, 0)
    footerText:SetText(CFG.Footer.text)

    -- 9. Fechamento com tecla Escape
    table.insert(UISpecialFrames, "ConsoleModeMainMenuFrame")

    -- 10. Eventos OnShow / OnHide integrados aos Hooks do ConsoleMode
    frame:SetScript("OnShow", function()
        MainMenu:UpdateLayout()
        MainMenu:UpdatePlayerModel()
        MainMenu:UpdateEquipmentColumn()
        MainMenu:UpdateStatsAndBuffs()

        if dimmer then dimmer:Show() end
        if CFG.Audio.soundOpen then PlaySound(CFG.Audio.soundOpen) end
        if ConsoleMode.hooks and ConsoleMode.hooks.OnFrameShow then
            ConsoleMode.hooks:OnFrameShow(this)
        end
    end)

    frame:SetScript("OnHide", function()
        if dimmer then dimmer:Hide() end
        if CFG.Audio.soundClose then PlaySound(CFG.Audio.soundClose) end
        if ConsoleMode.hooks and ConsoleMode.hooks.OnFrameHide then
            ConsoleMode.hooks:OnFrameHide(this)
        end
    end)

    self.frame = frame

    -- Aplica o layout inicial
    self:UpdateLayout()
end

-- ============================================================================
-- CONTROLE DE EXIBIÇÃO / TOGGLE
-- ============================================================================

function MainMenu:Show()
    if not self.frame then
        self:CreateUI()
    end
    if self.frame then
        self.frame:Show()
    end
end

function MainMenu:Hide()
    if self.frame and self.frame:IsVisible() then
        self.frame:Hide()
    end
end

function MainMenu:Toggle()
    if self.frame and self.frame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

-- Inicializa a casca visual no carregamento e escuta eventos de atualização
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
initFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
initFrame:RegisterEvent("UNIT_MODEL_CHANGED")
initFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
initFrame:RegisterEvent("UNIT_HEALTH")
initFrame:RegisterEvent("UNIT_MANA")
initFrame:RegisterEvent("UNIT_RAGE")
initFrame:RegisterEvent("UNIT_ENERGY")
initFrame:RegisterEvent("PLAYER_MONEY")
initFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        MainMenu:CreateUI()
    elseif event == "DISPLAY_SIZE_CHANGED" then
        if MainMenu.UpdateLayout then
            MainMenu:UpdateLayout()
        end
    elseif MainMenu.frame and MainMenu.frame:IsVisible() then
        if event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_MODEL_CHANGED" then
            if arg1 == "player" then
                MainMenu:UpdatePlayerModel()
                MainMenu:UpdateEquipmentColumn()
            end
        elseif event == "PLAYER_AURAS_CHANGED" or event == "UNIT_HEALTH" or event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or event == "PLAYER_MONEY" then
            MainMenu:UpdateStatsAndBuffs()
        end
    end
end)
