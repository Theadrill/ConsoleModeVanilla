--[[
    ConsoleMode - Vanilla
    UI/MainMenu.lua - Hub Central do Menu Principal (Console / Zelda Style)

    Estrutura Visual:
      [====================== MENU PRINCIPAL ======================]
      |  [ PALCO DO PERSONAGEM (ESQUERDA) ]    |  [ CONTAINER DE ABAS (DIREITA) ]
      |  - Equipamentos (Esq)                  |  - [L1] Bolsas | Spells | Quests [R1]
      |  - Modelo 3D Jogador (Centro)          |  - Grid Categorizado de Slots (2D)
      |  - Atributos & Buffs Ativos (Dir)      |  - Painel Fixo de Detalhes / Tooltip (Zelda)
      [================ [D-Pad] (A) (Y) (B) [L1]/[R1] ===============]

    - FASE 1: Canvas 100% Responsivo por Porcentagem com renderização 9-Slice
    - FASE 2: Palco do Personagem 3D transparente (SetUnit('player')) com giro livre 360°
    - FASE 3: Lista de Equipamentos, Atributos Base e Lista Vertical de Buffs Ativos
    - FASE 4: Container de Abas Superiores com Alternância [L1] e [R1] (Gamepad)
    - FASE 5: Componentes Reutilizáveis (Grid & DetailCard), Scanner de Bolsas Categorizado
    - FONTES: Tipografia customizada de alta legibilidade (Marcellus + Alegreya Sans) com suporte completo a UTF-8/PT-BR
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
-- fontes, modelo 3D, equipamentos, status, buffs, abas, grids e detalhes
-- estão centralizadas aqui. Edite este bloco para ajustar a aparência.
-- ============================================================================

local CFG = {}

-- ----------------------------------------------------------------------------
-- 0. TIPOGRAFIA CUSTOMIZADA (MARCELLUS + ALEGREYA SANS - 100% PT-BR / UTF-8)
-- Fontes gratuitas de código aberto (SIL Open Font License) embutidas no addon.
-- ----------------------------------------------------------------------------
CFG.Fonts = {
    titleFontFile       = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\Marcellus-Regular.ttf",
    headerFontFile      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\Marcellus-Regular.ttf",
    bodyFontFile        = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    subFontFile         = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Medium.ttf",

    -- Estilo global de contorno ("" = sem outline / texto limpo, "OUTLINE" = contorno fino)
    outline             = "",
    shadowOffset        = { 1, -1 },            -- Deslocamento X e Y da sombra projetada (px) - Justo e suave
    shadowColor         = { 0.0, 0.0, 0.0, 0.90 }, -- Cor e opacidade da sombra (RGBA) - 90% de opacidade

    titleSize           = 18,
    tabSize             = 14,
    headerSize          = 13,
    playerNameSize      = 17,
    playerSubSize       = 13,                   -- Aumentado em ~25% (original: 11)
    itemNameSize        = 14,                   -- Aumentado em ~20% (original: 12)
    slotLabelSize       = 11,                   -- Aumentado em ~10% (original: 10)
    statSize            = 14,                   -- Aumentado em ~20% (original: 12)
    buffSize            = 12,                   -- Aumentado em ~10% (original: 11)
    footerSize          = 12,
    detailTitleSize     = 15,
    detailTypeSize      = 11,
    detailDescSize      = 12,
    gridCountSize       = 11,
    bagHeaderSize       = 15,                   -- Aumentado em +30% (original: 12)
    bagCatSize          = 14,                   -- Aumentado em +30% (original: 11)
}

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
    frameStrata     = "HIGH",               -- Camada de renderização (abaixo de FULLSCREEN_DIALOG / TOOLTIP)
    frameLevel      = 10,                   -- Nível de sobreposição dentro da strata
}

-- ----------------------------------------------------------------------------
-- 2. DIMMER DE FUNDO (EFEITO ESCURECIDO DE IMERSÃO)
-- ----------------------------------------------------------------------------
CFG.Dimmer = {
    enabled         = true,                 -- true = ativa o fundo escurecido, false = desativa
    frameStrata     = "MEDIUM",             -- Camada de renderização abaixo do menu principal
    frameLevel      = 5,                    -- Nível de sobreposição
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
    text            = "|cffe09a15MENU PRINCIPAL|r",
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
}

-- ----------------------------------------------------------------------------
-- 5.2. COLUNA DE EQUIPAMENTOS (FASE 3 - À ESQUERDA DO PERSONAGEM 3D)
-- Lista vertical com os slots e nomes dos itens equipados.
-- ----------------------------------------------------------------------------
CFG.Equipment = {
    width           = 168,                  -- Largura da coluna de equipamentos (px) - +20% do original (140)
    iconSize        = 26,                   -- Tamanho do ícone do slot (px) - +20% do original (22)
    itemHeight      = 28,                   -- Altura de cada linha de equipamento (px) - +16% do original (24)
    gapY            = 3,                    -- Espaçamento vertical entre os itens (px)
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
    width           = 150,                  -- Largura da coluna de status e buffs (px)
    buffIconSize    = 20,                   -- Tamanho do ícone de buff (px) - Aumentado em +10% (original: 18)
    buffGapY        = 5,                    -- Espaçamento vertical entre buffs (px)
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
-- 6.1. BARRA DE ABAS SUPERIORES E CONTAINERS (FASE 4 - NAVEGAÇÃO [L1] / [R1])
-- ----------------------------------------------------------------------------
CFG.Tabs = {
    barHeight       = 36,                   -- Altura da barra superior de abas (px)
    buttonHeight    = 28,                   -- Altura de cada botão de aba (px)
    gapX            = 6,                    -- Espaçamento horizontal entre os botões (px)
    activeColor     = { r = 0.88, g = 0.60, b = 0.08 }, -- Dourado âmbar mais escuro e nobre
    inactiveColor   = { r = 0.65, g = 0.65, b = 0.65 }, -- Cor cinza de aba inativa
    indicatorColor  = "|cffe09a15",         -- Dourado âmbar de alto contraste
    list = {
        { id = "BAGS",   name = "Bolsas & Itens",  shortName = "Bolsas" },
        { id = "SPELLS", name = "Livro de Magias", shortName = "Magias" },
        { id = "QUESTS", name = "Missões",         shortName = "Missões" },
        { id = "SYSTEM", name = "Configurações",   shortName = "Opções" },
    }
}

-- ----------------------------------------------------------------------------
-- 6.2. COMPONENTE DE GRID REUTILIZÁVEL (FASE 5 - BOLSAS, MAGIAS, MISSÕES)
-- ----------------------------------------------------------------------------
CFG.Grid = {
    slotSize        = 40,                   -- Tamanho do slot quadrado (px)
    gapX            = 6,                    -- Espaçamento horizontal mínimo (px)
    gapY            = 6,                    -- Espaçamento vertical (px)
    maxSlots        = 80,                   -- Capacidade máxima de slots instanciados no pool
    pageSize        = "auto",               -- 'auto' preenche todos os slots que cabem na tela (pagina apenas se exceder)
    emptySlotAlpha  = 0.22,                 -- Opacidade dos slots vazios
    highlightColor  = { r = 1.0, g = 0.85, b = 0.2, a = 0.95 }, -- Destaque dourado de foco
}

-- ----------------------------------------------------------------------------
-- 6.3. PAINEL FIXO DE DETALHES / TOOLTIP (FASE 5 - ESTILO ZELDA / CONSOLE)
-- ----------------------------------------------------------------------------
CFG.DetailCard = {
    height          = 135,                  -- Altura do painel fixo de detalhes na base (px)
    iconSize        = 34,                   -- Tamanho do ícone grande de detalhes (px)
    bgColor         = { r = 0.0, g = 0.0, b = 0.0, a = 0.50 },
    borderColor     = { r = 0.5, g = 0.4, b = 0.3, a = 0.6 },
}

-- ----------------------------------------------------------------------------
-- 6.4. CATEGORIAS DE BOLSAS E INVENTÁRIO (FASE 5)
-- ----------------------------------------------------------------------------
CFG.Bags = {
    categories = {
        { id = "ALL",    name = "Todos" },
        { id = "EQUIP",  name = "Equipamentos" },
        { id = "USABLE", name = "Consumíveis" },
        { id = "TRADE",  name = "Materiais" },
        { id = "MISC",   name = "Diversos" },
    }
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
-- 8. RODAPÉ DE ATALHOS (CONSOLE HINTS - PADRÃO DE CORES XBOX COM ALTO CONTRASTE)
-- ----------------------------------------------------------------------------
CFG.Footer = {
    height          = 36,                   -- Altura da barra de rodapé (px)
    paddingLeft     = 28,                   -- Margem esquerda (px)
    paddingRight    = -28,                  -- Margem direita (px)
    offsetY         = 12,                   -- Distância da base da janela (px)
    text            = "|cffe09a15[L1] / [R1]|r Abas   |   |cffe09a15[L2] / [R2]|r Filtros   |   |cffffffff[D-Pad]|r Navegar   |   |cff38b000(A)|r Usar/Equipar   |   |cff3399ff(Y)|r Ações   |   |cffdd3333(B)|r Fechar   |   |cffffffff[R-Stick]|r Girar 3D",
}

-- ----------------------------------------------------------------------------
-- 9. EFEITOS SONOROS NATIVOS
-- ----------------------------------------------------------------------------
CFG.Audio = {
    soundOpen       = "igMainMenuOpen",
    soundClose      = "igMainMenuClose",
    soundTabChange  = "igCharacterInfoTab",
    soundItemSelect = "igMiniMapZoomIn",
}

-- ============================================================================
-- HELPER DE APLICAÇÃO DE FONTES (COM SUPORTE UTF-8 / PT-BR E FALLBACK SEGURO)
-- ============================================================================

function MainMenu:ApplyFont(fontString, fontPath, size, outline)
    if not fontString then return end
    fontPath = fontPath or CFG.Fonts.bodyFontFile
    size = size or 12
    outline = outline or CFG.Fonts.outline or ""
    
    fontString:SetFont(fontPath, size, outline)
    
    if not fontString:GetFont() then
        fontString:SetFont("Fonts\\FRIZQT__.TTF", size, outline)
    end
    
    local so = CFG.Fonts.shadowOffset or { 1, -1 }
    local sc = CFG.Fonts.shadowColor or { 0, 0, 0, 0.90 }
    fontString:SetShadowOffset(so[1], so[2])
    fontString:SetShadowColor(sc[1], sc[2], sc[3], sc[4])
end

-- ============================================================================
-- TOOLTIP SCANNER PARA BUFFS E ITENS
-- ============================================================================

local scanTip = CreateFrame("GameTooltip", "ConsoleModeMMScanTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

function MainMenu:GetBuffName(buffIndexID)
    if not scanTip then return "Efeito Ativo" end
    scanTip:ClearLines()
    scanTip:SetPlayerBuff(buffIndexID)
    local textObj = _G["ConsoleModeMMScanTooltipTextLeft1"]
    local text = (textObj and textObj:GetText()) or "Efeito Ativo"
    return text
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

    -- Ajusta a largura proporcional dos botões de aba no painel direito
    if self.tabContainer and self.tabContainer.tabBar and self.tabContainer.tabBar.buttons then
        local rightW = targetW - (leftW + CFG.LeftPanel.paddingLeft + math.abs(CFG.RightPanel.paddingRight) + CFG.RightPanel.gapX)
        local usableTabW = rightW - 64
        local numTabs = table.getn(CFG.Tabs.list)
        local btnW = math.floor((usableTabW - ((numTabs - 1) * CFG.Tabs.gapX)) / numTabs)
        if btnW < 60 then btnW = 60 end

        for _, btn in ipairs(self.tabContainer.tabBar.buttons) do
            btn:SetWidth(btnW)
        end
    end
end

-- ============================================================================
-- 1. MODELO 3D DO PERSONAGEM (FASE 2)
-- ============================================================================

function MainMenu:CreatePlayerModel(leftPanel)
    if self.playerModel then return self.playerModel end

    local model = CreateFrame("DressUpModel", "ConsoleModeMM_PlayerModel", leftPanel)
    if not model then
        model = CreateFrame("PlayerModel", "ConsoleModeMM_PlayerModel", leftPanel)
    end

    model:SetPoint("CENTER", leftPanel, "CENTER", CFG.PlayerModel.offsetX, CFG.PlayerModel.offsetY)
    model:SetWidth(CFG.PlayerModel.width)
    model:SetHeight(CFG.PlayerModel.height)
    model:SetFrameLevel(leftPanel:GetFrameLevel() + 5)
    model.rotation = CFG.PlayerModel.defaultFacing or 0
    model.isWearingTryOn = false

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

        local nameText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        nameText:SetPoint("TOP", infoBox, "TOP", 0, 0)
        MainMenu:ApplyFont(nameText, CFG.Fonts.titleFontFile, CFG.Fonts.playerNameSize)
        nameText:SetText(UnitName("player") or "Jogador")

        local subText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        subText:SetPoint("TOP", nameText, "BOTTOM", 0, -2)
        MainMenu:ApplyFont(subText, CFG.Fonts.subFontFile, CFG.Fonts.playerSubSize)

        model.infoBox  = infoBox
        model.nameText = nameText
        model.subText  = subText
    end

    self.playerModel = model
    return model
end

function MainMenu:UpdatePlayerModel()
    if not self.playerModel then return end

    if self.playerModel.ClearModel and self.playerModel.SetUnit then
        self.playerModel:ClearModel()
        self.playerModel:SetUnit("player")
    end
    if self.playerModel.Dress then
        self.playerModel:Dress()
    end
    if self.playerModel.SetFacing then
        self.playerModel:SetFacing(self.playerModel.rotation or CFG.PlayerModel.defaultFacing or 0)
    end
    if self.playerModel.SetSequence then
        pcall(function() self.playerModel:SetSequence(0) end)
    end
    self.playerModel.isWearingTryOn = false

    if self.playerModel.nameText then
        local pName = UnitName("player") or "Jogador"
        self.playerModel.nameText:SetText("|cffe09a15" .. pName .. "|r")
    end

    if self.playerModel.subText then
        local guildName = GetGuildInfo("player")
        local race = UnitRace("player") or ""
        local class = UnitClass("player") or ""
        local level = UnitLevel("player") or 1

        if guildName then
            self.playerModel.subText:SetText("|cffd48c08<" .. guildName .. ">|r  |cffffffffNv " .. level .. " " .. race .. " " .. class .. "|r")
        else
            self.playerModel.subText:SetText("|cffffffffNv " .. level .. " " .. race .. " " .. class .. "|r")
        end
    end
end

function MainMenu:TryOnItem(itemLink, itemType)
    if not self.playerModel or not itemLink then return end
    if not self.playerModel.TryOn then return end

    local currentFacing = self.playerModel.rotation or (self.playerModel.GetFacing and self.playerModel:GetFacing()) or 0

    local ok = pcall(function()
        self.playerModel:TryOn(itemLink)
    end)

    if ok then
        self.playerModel.isWearingTryOn = true
        if self.playerModel.SetFacing then
            self.playerModel:SetFacing(currentFacing)
        end

        if itemType == "Weapon" or itemType == "Arma" then
            pcall(function() self.playerModel:SetSequence(26) end)
        elseif itemType == "Armor" or itemType == "Armadura" then
            pcall(function() self.playerModel:SetSequence(0) end)
        end
    end
end

function MainMenu:RestorePlayerModel()
    if not self.playerModel or not self.playerModel.isWearingTryOn then return end
    local currentFacing = self.playerModel.rotation or (self.playerModel.GetFacing and self.playerModel:GetFacing()) or 0
    if self.playerModel.Undress and self.playerModel.Dress then
        self.playerModel:Undress()
        self.playerModel:Dress()
        if self.playerModel.SetFacing then
            self.playerModel:SetFacing(currentFacing)
        end
        pcall(function() self.playerModel:SetSequence(0) end)
    elseif self.playerModel.ClearModel and self.playerModel.SetUnit then
        self.playerModel:ClearModel()
        self.playerModel:SetUnit("player")
        if self.playerModel.SetFacing then
            self.playerModel:SetFacing(currentFacing)
        end
        pcall(function() self.playerModel:SetSequence(0) end)
    end
    self.playerModel.isWearingTryOn = false
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
        btn:SetHeight(CFG.Equipment.itemHeight or 28)
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

        -- Moldura ao redor do ícone (Backdrop com 8 fatias nativo, sem glitch)
        local border = CreateFrame("Frame", nil, btn)
        border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.6)
        btn.border = border

        -- 1. Linha Superior: Nome do Slot (CABEÇA, PEITORAL, etc.)
        local slotText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slotText:SetPoint("LEFT", icon, "RIGHT", 7, 7)
        slotText:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
        slotText:SetJustifyH("LEFT")
        MainMenu:ApplyFont(slotText, CFG.Fonts.subFontFile, CFG.Fonts.slotLabelSize)
        btn.slotText = slotText

        -- 2. Linha Inferior: Nome do Item agrupado logo abaixo do slot
        local nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameText:SetPoint("TOPLEFT", slotText, "BOTTOMLEFT", 0, -1)
        nameText:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
        nameText:SetJustifyH("LEFT")
        MainMenu:ApplyFont(nameText, CFG.Fonts.bodyFontFile, CFG.Fonts.itemNameSize)
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
        local slotID = GetInventorySlotInfo(slotData.name)
        btn.invSlotID = slotID
        btn.isMMEquipSlot = true
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        btn:SetScript("OnClick", function()
            if arg1 == "RightButton" or (arg1 == "LeftButton" and not CursorHasItem() and not CursorHasSpell()) then
                if this.invSlotID and CM.ui and CM.ui.contextMenu and CM.ui.contextMenu.OpenForEquipItem then
                    CM.ui.contextMenu:OpenForEquipItem(this.invSlotID, this)
                end
            elseif arg1 == "LeftButton" and (CursorHasItem() or CursorHasSpell()) then
                if this.invSlotID then
                    PickupInventoryItem(this.invSlotID)
                end
            end
        end)

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

                if not itemName and scanTip then
                    scanTip:ClearLines()
                    scanTip:SetInventoryItem("player", slotID)
                    local textObj = _G["ConsoleModeMMScanTooltipTextLeft1"]
                    itemName = (textObj and textObj:GetText()) or slotLabel
                end

                itemName = itemName or slotLabel

                -- 1. Exibe o nome do slot em cima (menor)
                btn.slotText:SetText(CFG.Equipment.slotColor .. slotLabel .. "|r")

                -- 2. Exibe o nome do item embaixo sempre em branco
                btn.nameText:SetText("|cffffffff" .. itemName .. "|r")

                -- 3. A cor de raridade é expressa exclusivamente através da borda do ícone
                local r, g, b = 0.8, 0.8, 0.8
                if itemQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality] then
                    local color = ITEM_QUALITY_COLORS[itemQuality]
                    r, g, b = color.r, color.g, color.b
                elseif colorHex then
                    local hexR = tonumber(string.sub(colorHex, 1, 2), 16)
                    local hexG = tonumber(string.sub(colorHex, 3, 4), 16)
                    local hexB = tonumber(string.sub(colorHex, 5, 6), 16)
                    if hexR and hexG and hexB then
                        r, g, b = hexR / 255, hexG / 255, hexB / 255
                    end
                end
                btn.border:SetBackdropBorderColor(r, g, b, 0.95)
            else
                btn.icon:SetTexture(emptyTex or "Interface\\Icons\\INV_Misc_QuestionMark")
                btn.slotText:SetText(CFG.Equipment.emptyColor .. slotLabel .. "|r")
                btn.nameText:SetText(CFG.Equipment.emptyColor .. "(Vazio)|r")
                btn.border:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.4)
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
    local statsHeader = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsHeader:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    MainMenu:ApplyFont(statsHeader, CFG.Fonts.headerFontFile, CFG.Fonts.headerSize)
    statsHeader:SetText("|cffe09a15STATUS|r")

    local statLines = {}
    local statKeys = { "HP", "Recurso", "Força", "Agilidade", "Vigor", "Intelecto", "Espírito", "Armadura" }
    local prevStat = statsHeader

    for i, key in ipairs(statKeys) do
        local line = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line:SetPoint("TOPLEFT", prevStat, "BOTTOMLEFT", 0, -2)
        line:SetPoint("RIGHT", container, "RIGHT", 0, 0)
        line:SetJustifyH("LEFT")
        MainMenu:ApplyFont(line, CFG.Fonts.bodyFontFile, CFG.Fonts.statSize)
        statLines[key] = line
        prevStat = line
    end
    container.statLines = statLines

    -- 2. Linha Divisória Horizontal Sutil
    local statDiv = container:CreateTexture(nil, "ARTWORK")
    statDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    statDiv:SetHeight(1)
    statDiv:SetPoint("TOPLEFT", prevStat, "BOTTOMLEFT", 0, -6)
    statDiv:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    statDiv:SetVertexColor(0.5, 0.4, 0.3, 0.4)

    -- 3. Seção de Buffs Ativos (Estilo Zelda)
    local buffHeader = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buffHeader:SetPoint("TOPLEFT", statDiv, "BOTTOMLEFT", 0, -6)
    MainMenu:ApplyFont(buffHeader, CFG.Fonts.headerFontFile, CFG.Fonts.headerSize)
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

        -- Moldura do ícone de buff (Backdrop com 8 fatias nativo, sem glitch)
        local bBorder = CreateFrame("Frame", nil, row)
        bBorder:SetPoint("TOPLEFT", bIcon, "TOPLEFT", -2, 2)
        bBorder:SetPoint("BOTTOMRIGHT", bIcon, "BOTTOMRIGHT", 2, -2)
        bBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        bBorder:SetBackdropBorderColor(0.2, 0.8, 1.0, 0.7)
        row.border = bBorder

        -- Nome do Buff
        local bName = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bName:SetPoint("LEFT", bIcon, "RIGHT", 4, 0)
        bName:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        bName:SetJustifyH("LEFT")
        MainMenu:ApplyFont(bName, CFG.Fonts.bodyFontFile, CFG.Fonts.buffSize)
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

        lines["Força"]:SetText("|cffffffffForça:|r " .. (UnitStat("player", 1) or 0))
        lines["Agilidade"]:SetText("|cffffffffAgilidade:|r " .. (UnitStat("player", 2) or 0))
        lines["Vigor"]:SetText("|cffffffffVigor:|r " .. (UnitStat("player", 3) or 0))
        lines["Intelecto"]:SetText("|cffffffffIntelecto:|r " .. (UnitStat("player", 4) or 0))
        lines["Espírito"]:SetText("|cffffffffEspírito:|r " .. (UnitStat("player", 5) or 0))

        local baseArmor, armorEff = UnitArmor("player")
        lines["Armadura"]:SetText("|cffffffffArmadura:|r " .. (armorEff or 0))
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
-- 4. COMPONENTE REUTILIZÁVEL: PAINEL FIXO DE DETALHES / TOOLTIP (FASE 5)
-- Pode exibir detalhes de Itens, Magias, Habilidades ou Missões.
-- ============================================================================

function MainMenu:CreateDetailCard(parent, config)
    config = config or CFG.DetailCard

    local card = CreateFrame("Frame", nil, parent)
    card:SetHeight(config.height or 145)
    card:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    card:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- Fundo escurecido translúcido com borda suave
    card:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    local bgC = config.bgColor or { r = 0, g = 0, b = 0, a = 0.45 }
    local bdC = config.borderColor or { r = 0.5, g = 0.4, b = 0.3, a = 0.6 }
    card:SetBackdropColor(bgC.r, bgC.g, bgC.b, bgC.a)
    card:SetBackdropBorderColor(bdC.r, bdC.g, bdC.b, bdC.a)

    -- 1. Ícone Grande do Item / Magia
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(config.iconSize or 34)
    icon:SetHeight(config.iconSize or 34)
    icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
    card.icon = icon

    local iconBorder = CreateFrame("Frame", nil, card)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    iconBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    iconBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
    card.iconBorder = iconBorder

    -- 2. Título (Nome do Item com cor da Raridade)
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 2)
    titleText:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    titleText:SetJustifyH("LEFT")
    MainMenu:ApplyFont(titleText, CFG.Fonts.titleFontFile, CFG.Fonts.detailTitleSize)
    card.titleText = titleText

    -- 3. Subtítulo (Tipo de Item, Local do Slot, Nível Requerido)
    local typeText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
    typeText:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    typeText:SetJustifyH("LEFT")
    MainMenu:ApplyFont(typeText, CFG.Fonts.subFontFile, CFG.Fonts.detailTypeSize)
    card.typeText = typeText

    -- 4. Descrição / Atributos do Item
    local descText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    descText:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -6)
    descText:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 44)
    descText:SetJustifyH("LEFT")
    descText:SetJustifyV("TOP")
    MainMenu:ApplyFont(descText, CFG.Fonts.bodyFontFile, CFG.Fonts.detailDescSize)
    card.descText = descText

    -- 5. Preço de Venda do Item (Acima da seção do rodapé separador)
    local sellText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sellText:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 28)
    MainMenu:ApplyFont(sellText, CFG.Fonts.subFontFile, 11)
    card.sellText = sellText

    -- 6. Rodapé: Espaço Livre (Esquerda) e Moedas do Jogador (Direita) com linha divisória superior
    local footerBar = CreateFrame("Frame", nil, card)
    footerBar:SetHeight(22)
    footerBar:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 4)
    footerBar:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 4)
    card.footerBar = footerBar

    -- Linha Divisória sutil ACIMA da barra de rodapé (separador)
    local fDiv = footerBar:CreateTexture(nil, "ARTWORK")
    fDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    fDiv:SetHeight(1)
    fDiv:SetPoint("BOTTOMLEFT", footerBar, "TOPLEFT", 0, 2)
    fDiv:SetPoint("BOTTOMRIGHT", footerBar, "TOPRIGHT", 0, 2)
    fDiv:SetVertexColor(0.5, 0.4, 0.3, 0.4)
    card.fDiv = fDiv

    local slotsFreeText = footerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slotsFreeText:SetPoint("LEFT", footerBar, "LEFT", 0, 0)
    MainMenu:ApplyFont(slotsFreeText, CFG.Fonts.subFontFile, 12)
    slotsFreeText:SetText("|cffaaaaaaEspaço Livre:|r |cffffffff0 / 0|r")
    card.slotsFreeText = slotsFreeText

    local moneyText = footerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    moneyText:SetPoint("RIGHT", footerBar, "RIGHT", 0, 0)
    MainMenu:ApplyFont(moneyText, CFG.Fonts.bodyFontFile, 12)
    card.moneyText = moneyText

    -- Método para exibir dados de um item
    function card:ShowItem(itemData)
        if not itemData or not itemData.link then
            self:Clear("Nenhum item selecionado")
            return
        end

        self.icon:SetTexture(itemData.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        self.icon:Show()

        local r, g, b = 0.8, 0.8, 0.8
        if itemData.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemData.quality] then
            local qCol = ITEM_QUALITY_COLORS[itemData.quality]
            r, g, b = qCol.r, qCol.g, qCol.b
            self.titleText:SetText(qCol.hex .. (itemData.name or "Item") .. "|r")
        else
            self.titleText:SetText("|cffffffff" .. (itemData.name or "Item") .. "|r")
        end
        self.iconBorder:SetBackdropBorderColor(r, g, b, 0.95)
        self.iconBorder:Show()

        -- Formata subtítulo (ex: Cabeça - Armadura de Pano | Requer Nível 12)
        local sub = {}
        if itemData.equipLoc and itemData.equipLoc ~= "" then table.insert(sub, itemData.equipLoc) end
        if itemData.subType and itemData.subType ~= "" then table.insert(sub, itemData.subType) end
        local rLevel = tonumber(itemData.reqLevel) or 0
        if rLevel > 1 then table.insert(sub, "Req. Nv " .. rLevel) end
        self.typeText:SetText("|cffaaaaaa" .. table.concat(sub, "  •  ") .. "|r")

        -- Formata atributos e efeito
        local bodyLines = {}
        if itemData.statsLines and table.getn(itemData.statsLines) > 0 then
            for _, sLine in ipairs(itemData.statsLines) do
                table.insert(bodyLines, sLine)
            end
        end
        if itemData.desc and itemData.desc ~= "" then
            table.insert(bodyLines, "|cff00ff00" .. itemData.desc .. "|r")
        end

        if table.getn(bodyLines) > 0 then
            self.descText:SetText(table.concat(bodyLines, "\n"))
        else
            self.descText:SetText("|cff888888Sem informações adicionais.|r")
        end

        -- Preço de venda
        local sPrice = tonumber(itemData.sellPrice) or 0
        if sPrice > 0 then
            local gold = math.floor(sPrice / 10000)
            local silver = math.floor(math.mod(sPrice, 10000) / 100)
            local copper = math.mod(sPrice, 100)
            self.sellText:SetText(string.format("|cffaaaaaaVenda:|r |cffffd200%dg|r |cffc0c0c0%ds|r |cffcc8833%dc|r", gold, silver, copper))
        else
            self.sellText:SetText("|cff666666Sem valor de venda|r")
        end

        self:UpdateMoney()
        self:Show()
    end

    -- Método para limpar / estado vazio
    function card:Clear(msg)
        self.icon:Hide()
        self.iconBorder:Hide()
        self.titleText:SetText("|cff888888" .. (msg or "Nenhum item em foco") .. "|r")
        self.typeText:SetText("")
        self.descText:SetText("|cff555555Navegue com o D-Pad para inspecionar itens.|r")
        self.sellText:SetText("")
        self:UpdateMoney()
    end

    -- Atualiza o saldo de dinheiro do jogador no rodapé
    function card:UpdateMoney()
        local money = GetMoney() or 0
        local gold = math.floor(money / 10000)
        local silver = math.floor(math.mod(money, 10000) / 100)
        local copper = math.mod(money, 100)
        self.moneyText:SetText(string.format("|cffe09a15Ouro:|r |cffffd200%dg|r |cffc0c0c0%ds|r |cffcc8833%dc|r", gold, silver, copper))
    end

    card:Clear()
    return card
end

-- ============================================================================
-- 5. COMPONENTE REUTILIZÁVEL: GRID GENÉRICO DE SLOTS (FASE 5)
-- ============================================================================

function MainMenu:CreateGrid(parent, maxSlots, config)
    config = config or CFG.Grid
    maxSlots = maxSlots or config.maxSlots or 64

    local gridFrame = CreateFrame("Frame", nil, parent)
    gridFrame:SetAllPoints(parent)

    local slotSize = config.slotSize or 38
    local gapX = config.gapX or 6
    local gapY = config.gapY or 6
    local cols = config.cols or 8

    local slots = {}

    for i = 1, maxSlots do
        local slotName = "ConsoleModeMM_BagSlot" .. i
        local slot = CreateFrame("Button", slotName, gridFrame)
        slot.isMMBagSlot = true
        slot.slotIndex = i
        slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        slot:SetWidth(slotSize)
        slot:SetHeight(slotSize)
        -- Fundo escurecido translúcido para o slot (estilo Zelda TotK)
        local bg = slot:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(slot)
        bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bg:SetVertexColor(0.0, 0.0, 0.0, 0.40)
        slot.bg = bg

        -- Ícone
        local icon = slot:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(slot)
        slot.icon = icon

        -- Moldura de Raridade (8 fatias nativo, sem glitch)
        local border = CreateFrame("Frame", nil, slot)
        border:SetPoint("TOPLEFT", slot, "TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 2, -2)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        border:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.4)
        slot.border = border

        -- Texto de Stack (Quantidade)
        local countText = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        countText:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
        MainMenu:ApplyFont(countText, CFG.Fonts.bodyFontFile, CFG.Fonts.gridCountSize, "OUTLINE")
        slot.countText = countText

        -- Destaque Dourado de Seleção Ativa (Estilo Zelda)
        local highlight = CreateFrame("Frame", nil, slot)
        highlight:SetPoint("TOPLEFT", slot, "TOPLEFT", -4, 4)
        highlight:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 4, -4)
        highlight:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        local hCol = config.highlightColor or { r = 1.0, g = 0.85, b = 0.2, a = 0.95 }
        highlight:SetBackdropBorderColor(hCol.r, hCol.g, hCol.b, hCol.a)
        highlight:Hide()
        slot.highlight = highlight

        -- Eventos de Mouse / Hover / Foco
        slot:SetScript("OnEnter", function()
            gridFrame:SelectSlot(this.slotIndex)
            if gridFrame.onSlotFocused then
                gridFrame.onSlotFocused(this.slotIndex, this.data)
            end
        end)

        slot:SetScript("OnLeave", function()
            if gridFrame.selectedSlotIndex ~= this.slotIndex then
                this.highlight:Hide()
            end
        end)

        slot:SetScript("OnClick", function()
            gridFrame:SelectSlot(this.slotIndex)
            if arg1 == "RightButton" then
                if this.data and this.data.bagID and this.data.slotID then
                    if CM.ui and CM.ui.contextMenu and CM.ui.contextMenu.OpenForBagItem then
                        CM.ui.contextMenu:OpenForBagItem(this.data.bagID, this.data.slotID, this)
                    end
                end
            else
                if gridFrame.onSlotClicked then
                    gridFrame.onSlotClicked(this.slotIndex, this.data)
                end
            end
        end)

        table.insert(slots, slot)
    end

    gridFrame.slots = slots
    gridFrame.slotSize = slotSize
    gridFrame.gapX = gapX
    gridFrame.gapY = gapY
    gridFrame.cols = cols
    gridFrame.selectedSlotIndex = 1

    -- Organiza os slots no layout de grade 2D responsivo que preenche 100% da largura e respeita a altura
    function gridFrame:LayoutSlots(visibleCount)
        local w = self:GetWidth()
        local h = self:GetHeight()

        -- Se a geometria ainda não resolveu no primeiro frame (w <= 100), calcula via targetW e targetH reais
        if not w or w < 100 then
            local totalW = (MainMenu.frame and MainMenu.frame:GetWidth()) or 980
            if totalW < 100 then totalW = 980 end
            local availableW = totalW - (CFG.LeftPanel.paddingLeft + math.abs(CFG.RightPanel.paddingRight) + CFG.RightPanel.gapX)
            local leftW = math.floor(availableW * CFG.LeftPanel.widthRatio)
            w = availableW - leftW
        end

        if not h or h < 100 then
            local totalH = (MainMenu.frame and MainMenu.frame:GetHeight()) or 620
            if totalH < 100 then totalH = 620 end
            h = totalH - (math.abs(CFG.RightPanel.paddingTop) + CFG.RightPanel.paddingBottom + CFG.Tabs.barHeight + CFG.DetailCard.height + 40)
        end

        local s = self.slotSize or 40
        local minGapX = self.gapX or 6
        local gy = self.gapY or 6

        -- 1. Calcula quantas colunas cabem perfeitamente na largura total
        local c = math.floor((w + minGapX) / (s + minGapX))
        if c < 4 then c = 4 end

        -- 2. Distribui o gap horizontal de ponta a ponta para preencher 100% da largura
        local gx = minGapX
        if c > 1 then
            gx = math.floor((w - (c * s)) / (c - 1))
            if gx < 2 then gx = 2 end
        end

        -- 3. Calcula quantas linhas cabem estritamente sem invadir a área de tooltip abaixo
        local maxRows = math.floor((h + gy) / (s + gy))
        if maxRows < 1 then maxRows = 1 end
        local maxFit = c * maxRows

        self.cols = c
        self.maxFitSlots = maxFit

        local limit = visibleCount or table.getn(self.slots)
        if limit > maxFit then limit = maxFit end

        for i, slot in ipairs(self.slots) do
            if i <= limit then
                local colIdx = math.mod(i - 1, c)
                local rowIdx = math.floor((i - 1) / c)
                local posX = colIdx * (s + gx)
                local posY = -(rowIdx * (s + gy))

                slot:ClearAllPoints()
                slot:SetPoint("TOPLEFT", self, "TOPLEFT", posX, posY)
                slot:Show()
            else
                slot:Hide()
            end
        end
    end

    -- Seleciona um slot no grid e dispara os callbacks
    function gridFrame:SelectSlot(index)
        self.selectedSlotIndex = index
        for i, slot in ipairs(self.slots) do
            if i == index then
                slot.highlight:Show()
                if slot.data and self.onSlotFocused then
                    self.onSlotFocused(index, slot.data)
                end
            else
                slot.highlight:Hide()
            end
        end
    end

    -- Limpa todos os slots
    function gridFrame:Clear()
        for _, slot in ipairs(self.slots) do
            slot.icon:SetTexture(nil)
            slot.countText:SetText("")
            slot.border:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.3)
            slot.data = nil
            slot.highlight:Hide()
        end
    end

    return gridFrame
end

-- ============================================================================
-- 6. SCANNER E PARSER DE INVENTÁRIO (FASE 5)
-- ============================================================================

function MainMenu:ParseItemData(bagID, slotID)
    local texture, count, locked, quality, readable = GetContainerItemInfo(bagID, slotID)
    if not texture then return nil end

    local link = GetContainerItemLink(bagID, slotID)
    local itemName, rawLink, itemQuality, itemReqLevel, itemType, itemSubType, itemEquipLoc
    local sellPrice = 0

    if link then
        local _, _, _, rawL, nameFromL = string.find(link, "|c(%x+)|H(item:%d+:%d+:%d+:%d+)|h%[(.-)%]|h|r")
        itemName = nameFromL
        rawLink = rawL
    end

    if rawLink then
        local n, _, q, reqL, t, st, _, eqL = GetItemInfo(rawLink)
        if n then
            itemName = n
            itemQuality = tonumber(q) or 1
            itemReqLevel = tonumber(reqL) or 0
            itemType = t
            itemSubType = st
            itemEquipLoc = eqL
        end
    end

    -- Varre as linhas do Tooltip para atributos e preço de venda
    scanTip:ClearLines()
    scanTip:SetBagItem(bagID, slotID)

    local statsLines = {}
    local desc = ""
    local numLines = scanTip:NumLines()

    for l = 2, numLines do
        local leftTextObj = _G["ConsoleModeMMScanTooltipTextLeft" .. l]
        local leftText = (leftTextObj and leftTextObj:GetText()) or ""
        if leftText ~= "" then
            if string.find(leftText, "Uso:") or string.find(leftText, "Use:") or string.find(leftText, "Equipar:") then
                desc = leftText
            elseif not string.find(leftText, "Venda:") and not string.find(leftText, "Sell:") then
                table.insert(statsLines, "|cffffffff" .. leftText .. "|r")
            end
        end
    end

    -- Classifica em Categoria
    local cat = "MISC"
    if itemType == "Armadura" or itemType == "Armor" or itemType == "Arma" or itemType == "Weapon" then
        cat = "EQUIP"
    elseif itemType == "Consumível" or itemType == "Consumable" then
        cat = "USABLE"
    elseif itemType == "Mercadoria" or itemType == "Trade Goods" or itemType == "Reagente" or itemType == "Reagent" then
        cat = "TRADE"
    end

    return {
        bagID        = bagID,
        slotID       = slotID,
        name         = itemName or "Item",
        texture      = texture,
        count        = count or 1,
        quality      = quality or itemQuality or 1,
        link         = link,
        rawLink      = rawLink or link,
        reqLevel     = itemReqLevel or 0,
        itemType     = itemType or "",
        subType      = itemSubType or "",
        equipLoc     = itemEquipLoc or "",
        itemEquipLoc = itemEquipLoc or "",
        category     = cat,
        statsLines   = statsLines,
        desc         = desc,
        sellPrice    = sellPrice,
    }
end

function MainMenu:ScanInventory(categoryFilter)
    categoryFilter = categoryFilter or "ALL"
    local items = {}
    local totalSlots = 0
    local freeSlots = 0

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            totalSlots = totalSlots + numSlots
            for slot = 1, numSlots do
                local itemData = self:ParseItemData(bag, slot)
                if itemData then
                    if categoryFilter == "ALL" or itemData.category == categoryFilter then
                        table.insert(items, itemData)
                    end
                else
                    freeSlots = freeSlots + 1
                    if categoryFilter == "ALL" then
                        table.insert(items, {
                            bagID   = bag,
                            slotID  = slot,
                            isEmpty = true,
                        })
                    end
                end
            end
        end
    end

    return {
        items       = items,
        totalSlots  = totalSlots,
        freeSlots   = freeSlots,
        playerMoney = GetMoney() or 0,
    }
end

-- ============================================================================
-- 7. CONFIGURAÇÃO DA ABA 1: BOLSAS & INVENTÁRIO (FASE 5)
-- ============================================================================

function MainMenu:SetupBagsPage(pageBags)
    if pageBags.isInitialized then return end

    -- 1. Barra de Cabeçalho / Filtros de Categoria (APENAS as abas com [L2] / [R2])
    local headerBar = CreateFrame("Frame", "ConsoleModeMM_BagsHeader", pageBags)
    headerBar:SetHeight(32)
    headerBar:SetPoint("TOPLEFT", pageBags, "TOPLEFT", 0, 0)
    headerBar:SetPoint("TOPRIGHT", pageBags, "TOPRIGHT", 0, 0)

    -- Indicador [R2] à direita
    local r2Hint = headerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r2Hint:SetPoint("RIGHT", headerBar, "RIGHT", 0, 0)
    MainMenu:ApplyFont(r2Hint, CFG.Fonts.headerFontFile, 12)
    r2Hint:SetText("|cffe09a15[R2]|r")
    pageBags.r2Hint = r2Hint

    -- Botões de Filtro de Categoria (Ancorados da direita para esquerda para ordenar: [L2] Todos ... Diversos [R2])
    local catButtons = {}
    local prevCat = r2Hint
    pageBags.currentCategory = "ALL"

    local numCats = table.getn(CFG.Bags.categories)
    for i = numCats, 1, -1 do
        local catData = CFG.Bags.categories[i]
        local catBtn = CreateFrame("Button", "ConsoleModeMM_BagCat" .. catData.id, headerBar)
        catBtn:SetHeight(24)

        local catTitle = catBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        catTitle:SetPoint("CENTER", catBtn, "CENTER", 0, 0)
        MainMenu:ApplyFont(catTitle, CFG.Fonts.bodyFontFile, CFG.Fonts.bagCatSize or 14)
        catTitle:SetText(catData.name)
        catBtn.title = catTitle
        catBtn.catData = catData

        -- Auto-dimensiona a largura do botão pelo tamanho do texto + 8px de respiro
        local txtW = math.floor(catTitle:GetStringWidth() or 60)
        if txtW < 40 then txtW = 40 end
        catBtn:SetWidth(txtW + 8)

        catBtn:SetPoint("RIGHT", prevCat, "LEFT", -6, 0)

        catBtn:SetScript("OnClick", function()
            pageBags.currentCategory = this.catData.id
            MainMenu:UpdateBagsPage()
            if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
        end)

        table.insert(catButtons, catBtn)
        prevCat = catBtn
    end
    pageBags.catButtons = catButtons

    -- Indicador [L2] à esquerda da primeira categoria (Todos)
    local l2Hint = headerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    l2Hint:SetPoint("RIGHT", prevCat, "LEFT", -6, 0)
    MainMenu:ApplyFont(l2Hint, CFG.Fonts.headerFontFile, 12)
    l2Hint:SetText("|cffe09a15[L2]|r")
    pageBags.l2Hint = l2Hint

    -- Linha Divisória abaixo do cabeçalho de filtros
    local hDiv = headerBar:CreateTexture(nil, "ARTWORK")
    hDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    hDiv:SetHeight(1)
    hDiv:SetPoint("BOTTOMLEFT", headerBar, "BOTTOMLEFT", 0, -2)
    hDiv:SetPoint("BOTTOMRIGHT", headerBar, "BOTTOMRIGHT", 0, -2)
    hDiv:SetVertexColor(0.5, 0.4, 0.3, 0.4)

    -- 2. Painel Fixo de Detalhes / Tooltip (Estilo Zelda) na base
    local detailCard = self:CreateDetailCard(pageBags, CFG.DetailCard)
    pageBags.detailCard = detailCard

    -- 3. Barra Centralizada de Paginação ACIMA do Painel de Tooltip [ < ] Pág. 1 / 8 [ > ]
    local pageNav = CreateFrame("Frame", "ConsoleModeMM_BagsPageNav", pageBags)
    pageNav:SetHeight(22)
    pageNav:SetWidth(150)
    pageNav:SetPoint("BOTTOM", detailCard, "TOP", 0, 4)

    local btnBackdrop = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 8,
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    }

    local prevPageBtn = CreateFrame("Button", nil, pageNav)
    prevPageBtn:SetWidth(24)
    prevPageBtn:SetHeight(22)
    prevPageBtn:SetPoint("LEFT", pageNav, "LEFT", 0, 0)
    prevPageBtn:SetBackdrop(btnBackdrop)
    prevPageBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    prevPageBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local prevTxt = prevPageBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    prevTxt:SetPoint("CENTER", prevPageBtn, "CENTER", 0, 0)
    MainMenu:ApplyFont(prevTxt, CFG.Fonts.headerFontFile, 14)
    prevTxt:SetText("|cffe09a15<|r")

    prevPageBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    prevPageBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    prevPageBtn:SetScript("OnClick", function()
        MainMenu:PrevBagPage()
    end)
    pageBags.prevPageBtn = prevPageBtn

    local pageText = pageNav:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pageText:SetPoint("CENTER", pageNav, "CENTER", 0, 0)
    MainMenu:ApplyFont(pageText, CFG.Fonts.subFontFile, 13)
    pageText:SetText("|cffaaaaaaPág.|r |cffffffff1 / 1|r")
    pageBags.pageText = pageText

    local nextPageBtn = CreateFrame("Button", nil, pageNav)
    nextPageBtn:SetWidth(24)
    nextPageBtn:SetHeight(22)
    nextPageBtn:SetPoint("RIGHT", pageNav, "RIGHT", 0, 0)
    nextPageBtn:SetBackdrop(btnBackdrop)
    nextPageBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    nextPageBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local nextTxt = nextPageBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nextTxt:SetPoint("CENTER", nextPageBtn, "CENTER", 0, 0)
    MainMenu:ApplyFont(nextTxt, CFG.Fonts.headerFontFile, 14)
    nextTxt:SetText("|cffe09a15>|r")

    nextPageBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    nextPageBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    nextPageBtn:SetScript("OnClick", function()
        MainMenu:NextBagPage()
    end)
    pageBags.nextPageBtn = nextPageBtn
    pageBags.pageNav = pageNav

    -- 4. Container e Grid 2D de Slots de Itens (fica acima da paginação e tooltip)
    local gridContainer = CreateFrame("Frame", "ConsoleModeMM_BagsGridContainer", pageBags)
    gridContainer:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -8)
    gridContainer:SetPoint("BOTTOMRIGHT", detailCard, "TOPRIGHT", 0, 30)

    local grid = self:CreateGrid(gridContainer, 80, CFG.Grid)
    pageBags.grid = grid

    -- Callbacks do Grid
    grid.onSlotFocused = function(slotIndex, itemData)
        if itemData and not itemData.isEmpty then
            detailCard:ShowItem(itemData)
            -- Live TryOn no Modelo 3D (FASE 6)
            local isEquippable = (itemData.equipLoc and itemData.equipLoc ~= "") or (itemData.itemEquipLoc and itemData.itemEquipLoc ~= "") or (itemData.category == "EQUIP")
            local tryLink = itemData.rawLink or itemData.link
            if isEquippable and tryLink then
                MainMenu:TryOnItem(tryLink, itemData.itemType)
            else
                MainMenu:RestorePlayerModel()
            end
        else
            detailCard:Clear("Slot Vazio")
            MainMenu:RestorePlayerModel()
        end
    end

    grid.onSlotClicked = function(slotIndex, itemData)
        if CursorHasItem() or CursorHasSpell() then
            if itemData and itemData.bagID and itemData.slotID then
                PickupContainerItem(itemData.bagID, itemData.slotID)
            else
                PutItemInBackpack()
            end
            PlaySound("igMainMenuOptionCheckBoxOn")
        elseif itemData and itemData.bagID and itemData.slotID and not itemData.isEmpty then
            -- Suporte nativo a usar/equipar item com o botão (A)
            UseContainerItem(itemData.bagID, itemData.slotID)
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
    end

    pageBags.isInitialized = true
end

function MainMenu:UpdateBagsPage(keepPage)
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageBags = self.tabContainer.pages["BAGS"]
    if not pageBags then return end

    self:SetupBagsPage(pageBags)

    local curCat = pageBags.currentCategory or "ALL"
    local scanResult = self:ScanInventory(curCat)
    local items = scanResult.items

    -- 1. Atualiza botões de categoria
    if pageBags.catButtons then
        for _, btn in ipairs(pageBags.catButtons) do
            if btn.catData.id == curCat then
                btn.title:SetTextColor(CFG.Tabs.activeColor.r, CFG.Tabs.activeColor.g, CFG.Tabs.activeColor.b)
            else
                btn.title:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end

    -- 2. Atualiza contador de espaço livre na barra inferior do DetailCard
    if pageBags.detailCard and pageBags.detailCard.slotsFreeText then
        pageBags.detailCard.slotsFreeText:SetText(string.format("|cffaaaaaaEspaço Livre:|r |cffffffff%d / %d|r", scanResult.freeSlots, scanResult.totalSlots))
    end

    -- 3. Cálculo de Paginação
    local numItems = table.getn(items)
    local totalElements = numItems
    if curCat == "ALL" then
        totalElements = scanResult.totalSlots
    end

    local grid = pageBags.grid
    local pageSize = CFG.Grid.pageSize
    if not pageSize or pageSize == "auto" then
        pageSize = grid.maxFitSlots or 40
    end
    if pageSize < 1 then pageSize = 10 end

    local totalPages = math.ceil(totalElements / pageSize)
    if totalPages < 1 then totalPages = 1 end

    if not keepPage or not pageBags.currentPage then
        pageBags.currentPage = 1
    end
    if pageBags.currentPage > totalPages then pageBags.currentPage = totalPages end
    if pageBags.currentPage < 1 then pageBags.currentPage = 1 end
    local curPage = pageBags.currentPage

    -- Atualiza texto e controles de página acima do DetailCard
    if pageBags.pageText and pageBags.pageNav then
        if totalPages > 1 then
            pageBags.pageText:SetText(string.format("|cffaaaaaaPág.|r |cffffffff%d / %d|r", curPage, totalPages))
            pageBags.pageNav:Show()
        else
            pageBags.pageNav:Hide()
        end
    end

    -- 4. Preenche os slots da página atual
    grid:Clear()

    local startIndex = (curPage - 1) * pageSize + 1
    local endIndex = math.min(startIndex + pageSize - 1, totalElements)
    local pageCount = endIndex - startIndex + 1
    if pageCount < 0 then pageCount = 0 end

    grid:LayoutSlots(pageCount)

    for slotIdx = 1, pageCount do
        local globalIdx = startIndex + slotIdx - 1
        local slot = grid.slots[slotIdx]
        if slot then
            local itemData = items[globalIdx]

            if itemData and not itemData.isEmpty then
                slot.icon:SetTexture(itemData.texture)
                slot.icon:Show()
                slot.icon:SetAlpha(1.0)
                slot.data = itemData

                -- Quantidade no stack
                if itemData.count and itemData.count > 1 then
                    slot.countText:SetText(tostring(itemData.count))
                else
                    slot.countText:SetText("")
                end

                -- Borda com cor de qualidade
                local r, g, b = 0.8, 0.8, 0.8
                if itemData.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemData.quality] then
                    local col = ITEM_QUALITY_COLORS[itemData.quality]
                    r, g, b = col.r, col.g, col.b
                end
                slot.border:SetBackdropBorderColor(r, g, b, 0.95)
            else
                -- Slot vazio estilo Zelda: sem ícone, fundo escuro suave e borda sutil vazada
                slot.icon:SetTexture(nil)
                slot.icon:Hide()
                slot.countText:SetText("")
                slot.border:SetBackdropBorderColor(0.45, 0.40, 0.35, 0.30)
                slot.data = itemData
            end
        end
    end

    -- 5. Exibe o primeiro item da página no painel de detalhes por padrão
    if pageCount > 0 and items[startIndex] then
        grid:SelectSlot(1)
    else
        pageBags.detailCard:Clear("Inventário Vazio")
    end
end

function MainMenu:NextBagPage()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageBags = self.tabContainer.pages["BAGS"]
    if not pageBags then return end
    pageBags.currentPage = (pageBags.currentPage or 1) + 1
    self:UpdateBagsPage(true)
    if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
end

function MainMenu:PrevBagPage()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageBags = self.tabContainer.pages["BAGS"]
    if not pageBags then return end
    pageBags.currentPage = (pageBags.currentPage or 1) - 1
    self:UpdateBagsPage(true)
    if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
end

-- ============================================================================
-- 8. CONTAINER DE ABAS E NAVEGAÇÃO [L1] / [R1] (FASE 4 - PAINEL DIREITO)
-- ============================================================================

function MainMenu:CreateTabContainer(rightPanel)
    if self.tabContainer then return self.tabContainer end

    -- 1. Barra Superior de Abas (com indicadores de gatilho [L1] e [R1])
    local tabBar = CreateFrame("Frame", "ConsoleModeMM_TabBar", rightPanel)
    tabBar:SetHeight(CFG.Tabs.barHeight)
    tabBar:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, 0)

    -- Indicador [L1] à esquerda
    local l1Hint = tabBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    l1Hint:SetPoint("LEFT", tabBar, "LEFT", 2, 0)
    MainMenu:ApplyFont(l1Hint, CFG.Fonts.headerFontFile, CFG.Fonts.tabSize)
    l1Hint:SetText(CFG.Tabs.indicatorColor .. "[L1]|r")

    -- Indicador [R1] à direita
    local r1Hint = tabBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    r1Hint:SetPoint("RIGHT", tabBar, "RIGHT", -2, 0)
    MainMenu:ApplyFont(r1Hint, CFG.Fonts.headerFontFile, CFG.Fonts.tabSize)
    r1Hint:SetText(CFG.Tabs.indicatorColor .. "[R1]|r")

    -- Container Central dos Botões de Aba
    local tabsCenter = CreateFrame("Frame", "ConsoleModeMM_TabsCenter", tabBar)
    tabsCenter:SetPoint("LEFT", l1Hint, "RIGHT", 6, 0)
    tabsCenter:SetPoint("RIGHT", r1Hint, "LEFT", -6, 0)
    tabsCenter:SetHeight(CFG.Tabs.buttonHeight)

    local tabButtons = {}
    local prevTab = nil

    for i, tabData in ipairs(CFG.Tabs.list) do
        local tabBtn = CreateFrame("Button", "ConsoleModeMM_TabBtn" .. tabData.id, tabsCenter)
        tabBtn:SetHeight(CFG.Tabs.buttonHeight)
        tabBtn:SetWidth(100)

        if not prevTab then
            tabBtn:SetPoint("LEFT", tabsCenter, "LEFT", 0, 0)
        else
            tabBtn:SetPoint("LEFT", prevTab, "RIGHT", CFG.Tabs.gapX, 0)
        end

        local title = tabBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("CENTER", tabBtn, "CENTER", 0, 0)
        MainMenu:ApplyFont(title, CFG.Fonts.headerFontFile, CFG.Fonts.tabSize)
        title:SetText(tabData.name)
        tabBtn.title = title

        -- Linha dourada de destaque da aba ativa (Estilo Zelda)
        local highlight = tabBtn:CreateTexture(nil, "OVERLAY")
        highlight:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        highlight:SetHeight(2)
        highlight:SetPoint("BOTTOMLEFT", tabBtn, "BOTTOMLEFT", 2, 0)
        highlight:SetPoint("BOTTOMRIGHT", tabBtn, "BOTTOMRIGHT", -2, 0)
        highlight:SetVertexColor(CFG.Tabs.activeColor.r, CFG.Tabs.activeColor.g, CFG.Tabs.activeColor.b, 0.95)
        highlight:Hide()
        tabBtn.highlight = highlight

        tabBtn.tabData = tabData
        tabBtn:SetScript("OnClick", function()
            MainMenu:SelectTab(this.tabData.id)
        end)

        table.insert(tabButtons, tabBtn)
        prevTab = tabBtn
    end
    tabBar.buttons = tabButtons

    -- 2. Linha divisória horizontal abaixo da barra de abas
    local barDivider = tabBar:CreateTexture(nil, "ARTWORK")
    barDivider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    barDivider:SetHeight(1)
    barDivider:SetPoint("BOTTOMLEFT", tabBar, "BOTTOMLEFT", 0, 0)
    barDivider:SetPoint("BOTTOMRIGHT", tabBar, "BOTTOMRIGHT", 0, 0)
    barDivider:SetVertexColor(0.5, 0.4, 0.3, 0.4)

    -- 3. Container de Conteúdo das Páginas
    local contentFrame = CreateFrame("Frame", "ConsoleModeMM_TabContent", rightPanel)
    contentFrame:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -6)
    contentFrame:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", 0, 0)

    -- Criação dos Painéis de Conteúdo para cada Aba
    local pages = {}

    -- Página 1: Bolsas & Inventário (Fase 5/6)
    local pageBags = CreateFrame("Frame", "ConsoleModeMM_Page_BAGS", contentFrame)
    pageBags:SetAllPoints(contentFrame)
    pages["BAGS"] = pageBags

    -- Página 2: Livro de Magias & Habilidades (Fase 7)
    local pageSpells = CreateFrame("Frame", "ConsoleModeMM_Page_SPELLS", contentFrame)
    pageSpells:SetAllPoints(contentFrame)
    local spellsPlaceholder = pageSpells:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    spellsPlaceholder:SetPoint("CENTER", pageSpells, "CENTER", 0, 30)
    MainMenu:ApplyFont(spellsPlaceholder, CFG.Fonts.titleFontFile, 15, "")
    spellsPlaceholder:SetText("|cff00ffcc[ ABA 2: LIVRO DE MAGIAS & GRIMÓRIO ]|r\n\n|cffaaaaaaPronto para receber as magias na Fase 7|r")
    pages["SPELLS"] = pageSpells

    -- Página 3: Diário de Missões
    local pageQuests = CreateFrame("Frame", "ConsoleModeMM_Page_QUESTS", contentFrame)
    pageQuests:SetAllPoints(contentFrame)
    local questsPlaceholder = pageQuests:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    questsPlaceholder:SetPoint("CENTER", pageQuests, "CENTER", 0, 30)
    MainMenu:ApplyFont(questsPlaceholder, CFG.Fonts.titleFontFile, 15, "")
    questsPlaceholder:SetText("|cffffcc00[ ABA 3: DIÁRIO DE MISSÕES ]|r\n\n|cffaaaaaaRegistro de aventuras e objetivos ativos|r")
    pages["QUESTS"] = pageQuests

    -- Página 4: Sistema e Configurações
    local pageSystem = CreateFrame("Frame", "ConsoleModeMM_Page_SYSTEM", contentFrame)
    pageSystem:SetAllPoints(contentFrame)
    local sysPlaceholder = pageSystem:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    sysPlaceholder:SetPoint("CENTER", pageSystem, "CENTER", 0, 30)
    MainMenu:ApplyFont(sysPlaceholder, CFG.Fonts.titleFontFile, 15, "")
    sysPlaceholder:SetText("|cffffffff[ ABA 4: CONFIGURAÇÕES DO CONSOLEMODE ]|r\n\n|cff888888Clique no botão abaixo para abrir os ajustes do addon|r")
    
    local sysBtn = CreateFrame("Button", "ConsoleModeMM_OpenConfigBtn", pageSystem, "UIPanelButtonTemplate")
    sysBtn:SetWidth(180)
    sysBtn:SetHeight(28)
    sysBtn:SetPoint("TOP", sysPlaceholder, "BOTTOM", 0, -16)
    sysBtn:SetText("Abrir Ajustes de Binds")
    sysBtn:SetScript("OnClick", function()
        if ConsoleMode.config and ConsoleMode.config.Show then
            ConsoleMode.config:Show()
        end
    end)
    pages["SYSTEM"] = pageSystem

    self.tabContainer = {
        tabBar = tabBar,
        content = contentFrame,
        pages = pages,
        currentTab = "BAGS"
    }

    return self.tabContainer
end

function MainMenu:SelectTab(tabID, playSoundEffect)
    if not self.tabContainer then return end

    local container = self.tabContainer
    tabID = tabID or "BAGS"

    -- 1. Alterna a visibilidade dos containers de conteúdo
    for id, pageFrame in pairs(container.pages) do
        if id == tabID then
            pageFrame:Show()
        else
            pageFrame:Hide()
        end
    end

    -- 2. Atualiza estilos dos botões de aba
    if container.tabBar and container.tabBar.buttons then
        for _, tabBtn in ipairs(container.tabBar.buttons) do
            if tabBtn.tabData.id == tabID then
                tabBtn.title:SetTextColor(CFG.Tabs.activeColor.r, CFG.Tabs.activeColor.g, CFG.Tabs.activeColor.b)
                tabBtn.highlight:Show()
            else
                tabBtn.title:SetTextColor(CFG.Tabs.inactiveColor.r, CFG.Tabs.inactiveColor.g, CFG.Tabs.inactiveColor.b)
                tabBtn.highlight:Hide()
            end
        end
    end

    container.currentTab = tabID

    -- Se abriu a aba de Bolsas, atualiza o inventário
    if tabID == "BAGS" then
        self:UpdateBagsPage()
    else
        self:RestorePlayerModel()
    end

    if playSoundEffect ~= false and CFG.Audio.soundTabChange then
        PlaySound(CFG.Audio.soundTabChange)
    end
end

function MainMenu:CycleTabs(direction)
    if not self.tabContainer then return false end

    direction = direction or 1
    local curTab = self.tabContainer.currentTab or "BAGS"
    local list = CFG.Tabs.list
    local total = table.getn(list)
    local curIdx = 1

    for i, t in ipairs(list) do
        if t.id == curTab then
            curIdx = i
            break
        end
    end

    local nextIdx = curIdx + direction
    if nextIdx > total then nextIdx = 1 end
    if nextIdx < 1 then nextIdx = total end

    self:SelectTab(list[nextIdx].id, true)
    return true
end

function MainMenu:CycleCategories(direction)
    if not self.tabContainer or not self.tabContainer.pages then return false end
    local pageBags = self.tabContainer.pages["BAGS"]
    if not pageBags or not pageBags:IsVisible() then return false end

    direction = direction or 1
    local cats = CFG.Bags.categories
    local total = table.getn(cats)
    local curCat = pageBags.currentCategory or "ALL"
    local curIdx = 1

    for i, c in ipairs(cats) do
        if c.id == curCat then
            curIdx = i
            break
        end
    end

    local nextIdx = curIdx + direction
    if nextIdx > total then nextIdx = 1 end
    if nextIdx < 1 then nextIdx = total end

    pageBags.currentCategory = cats[nextIdx].id
    self:UpdateBagsPage()

    if CFG.Audio.soundItemSelect then
        PlaySound(CFG.Audio.soundItemSelect)
    end
    return true
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
        local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleText:SetPoint("TOP", frame, "TOP", 0, CFG.Title.offsetY)
        MainMenu:ApplyFont(titleText, CFG.Fonts.titleFontFile, CFG.Fonts.titleSize)
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

    -- 6. Painel Direito: Container de Conteúdo e Abas (FASE 4 - Direita)
    local rightPanel = CreateFrame("Frame", "ConsoleModeMM_RightPanel", frame)
    rightPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingTop)
    rightPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingBottom)
    rightPanel:SetPoint("LEFT", leftPanel, "RIGHT", CFG.RightPanel.gapX, 0)
    frame.rightPanel = rightPanel

    -- 6.1. Cria a Barra de Abas e Containers de Páginas (FASE 4)
    self:CreateTabContainer(rightPanel)

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

    local footerText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerText:SetPoint("CENTER", footer, "CENTER", 0, 0)
    MainMenu:ApplyFont(footerText, CFG.Fonts.bodyFontFile, CFG.Fonts.footerSize)
    footerText:SetText(CFG.Footer.text)

    -- 9. Fechamento com tecla Escape
    table.insert(UISpecialFrames, "ConsoleModeMainMenuFrame")

    -- 10. Eventos OnShow / OnHide integrados aos Hooks do ConsoleMode
    frame:SetScript("OnShow", function()
        MainMenu:UpdateLayout()
        MainMenu:UpdatePlayerModel()
        MainMenu:UpdateEquipmentColumn()
        MainMenu:UpdateStatsAndBuffs()

        local cur = (MainMenu.tabContainer and MainMenu.tabContainer.currentTab) or "BAGS"
        MainMenu:SelectTab(cur, false)

        if dimmer then dimmer:Show() end
        if CFG.Audio.soundOpen then PlaySound(CFG.Audio.soundOpen) end
        if ConsoleMode.hooks and ConsoleMode.hooks.OnFrameShow then
            ConsoleMode.hooks:OnFrameShow(this)
        end
    end)

    frame:SetScript("OnHide", function()
        MainMenu:RestorePlayerModel()
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
        self:RestorePlayerModel()
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
initFrame:RegisterEvent("BAG_UPDATE")
initFrame:RegisterEvent("ITEM_LOCK_CHANGED")

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
        elseif event == "PLAYER_AURAS_CHANGED" or event == "UNIT_HEALTH" or event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" then
            MainMenu:UpdateStatsAndBuffs()
        elseif event == "PLAYER_MONEY" then
            if MainMenu.tabContainer and MainMenu.tabContainer.currentTab == "BAGS" then
                MainMenu:UpdateBagsPage()
            end
        elseif event == "BAG_UPDATE" or event == "ITEM_LOCK_CHANGED" then
            if MainMenu.tabContainer and MainMenu.tabContainer.currentTab == "BAGS" then
                MainMenu:UpdateBagsPage()
            end
        end
    end
end)
