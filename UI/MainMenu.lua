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

ConsoleMode = ConsoleMode or {}
local CM = ConsoleMode
CM.mainMenu = CM.mainMenu or {}

local MainMenu = CM.mainMenu
_G["ConsoleModeMainMenu"] = MainMenu

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
    footerSize          = 16,                   -- Aumentado em +33% (original: 12)
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
    widthPercent    = 0.90,                 -- Fração da largura útil da tela (88%)
    heightPercent   = 0.85,                 -- Fração da altura útil da tela (84%)
    
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
    width           = 380,                  -- Largura expandida para preencher o palco esquerdo (px)
    height          = 460,                  -- Altura expandida para visualização completa (px)
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
    maxBuffs        = 8,                    -- Quantidade máxima de buffs visíveis na lista (inclui armas)
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
        { id = "QUESTS", name = "Missões & Mapa",  shortName = "Missões" },
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
-- 6.5. SUB-ABAS DE SISTEMA E CONFIGURAÇÕES (FASE 8)
-- ----------------------------------------------------------------------------
CFG.System = {
    subTabs = {
        { id = "GAME_MENU", name = "Opções do Jogo", shortName = "Opções" },
        { id = "ADDON_CFG", name = "Configurações do Addon", shortName = "Addon" },
    },
    -- Cores centralizadas e padronizadas para as opções do sistema
    itemTextColor   = "|cffffffff",         -- Cor branca uniforme para todos os títulos de botões
    badgeColor      = "|cffe09a15",         -- Cor âmbar/dourada para os números de índice [01], [02]...
    frameNameColor  = "|cff777777",         -- Cor cinza discreta para o nome técnico do frame
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
-- 8. ÍCONES GRÁFICOS DO CONTROLE (XBOX)
-- ----------------------------------------------------------------------------
CFG.Icons = {
    basePath = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\",
    A        = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\A.tga",
    B        = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\B.tga",
    X        = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\X.tga",
    Y        = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\Y.tga",
    LB       = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LB.tga",
    RB       = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\RB.tga",
    LT       = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LT.tga",
    RT       = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\RT.tga",
    DUP      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DUP.tga",
    DDOWN    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DDOWN.tga",
    DLEFT    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DLEFT.tga",
    DRIGHT   = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DRIGHT.tga",
    DALL     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\navigate_all_directions.tga",
}

-- ----------------------------------------------------------------------------
-- 9. RODAPÉ DE ATALHOS (CONSOLE HINTS)
-- ----------------------------------------------------------------------------
CFG.Footer = {
    height          = 36,                   -- Altura da barra de rodapé (px)
    paddingLeft     = 28,                   -- Margem esquerda (px)
    paddingRight    = -28,                  -- Margem direita (px)
    offsetY         = 12,                   -- Distância da base da janela (px)
    iconSize        = 18,                   -- Tamanho dos ícones gráficos no rodapé (px)
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
scanTip.money = 0
scanTip:SetScript("OnTooltipAddMoney", function()
    scanTip.money = arg1
end)

function MainMenu:GetBuffName(buffIndexID)
    if not scanTip then return "Efeito Ativo" end
    scanTip:ClearLines()
    scanTip:SetPlayerBuff(buffIndexID)
    local textObj = _G["ConsoleModeMMScanTooltipTextLeft1"]
    local text = (textObj and textObj:GetText()) or "Efeito Ativo"
    return text
end

function MainMenu:GetWeaponEnchantDetails(slotID)
    local icon = GetInventoryItemTexture("player", slotID) or "Interface\\Icons\\INV_Sword_04"
    local enchantName = (slotID == 16 and "Arma Principal") or "Arma Secundária"

    if not scanTip then return enchantName, icon end
    scanTip:ClearLines()
    scanTip:SetInventoryItem("player", slotID)

    local numLines = scanTip:NumLines() or 0
    for l = 1, numLines do
        local lineObj = _G["ConsoleModeMMScanTooltipTextLeft" .. l]
        if lineObj then
            local text = lineObj:GetText() or ""
            local r, g, b = lineObj:GetTextColor()
            -- Linhas de encantamento temporário de arma no WoW Vanilla são verdes (g > 0.8 e r < 0.3) ou contêm (X min/sec)
            if (g and g > 0.8 and r and r < 0.35) or string.find(text, "%(%d+ min%)") or string.find(text, "%(%d+ sec%)") or string.find(text, "%(%d+ hr%)") or string.find(text, "%(%d+ cargas%)") or string.find(text, "%(%d+ charges%)") then
                local cleanName = string.gsub(text, "%s*%b()", "")
                if cleanName ~= "" then
                    enchantName = cleanName
                    break
                end
            end
        end
    end

    return enchantName, icon
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
    if self.dressUpModel and self.animModel then return self.playerModel end

    -- 1. Modelo de Provador (DressUpModel para TryOn na Aba de Bolsas)
    local dressUpModel = getglobal("ConsoleModeMM_DressUpModel")
    if dressUpModel then
        dressUpModel:SetParent(leftPanel)
        dressUpModel:Show()
    else
        dressUpModel = CreateFrame("PlayerModel", "ConsoleModeMM_DressUpModel", leftPanel)
    end

    dressUpModel:SetPoint("CENTER", leftPanel, "CENTER", CFG.PlayerModel.offsetX, CFG.PlayerModel.offsetY)
    dressUpModel:SetWidth(CFG.PlayerModel.width)
    dressUpModel:SetHeight(CFG.PlayerModel.height)
    dressUpModel:SetFrameLevel(leftPanel:GetFrameLevel() + 3)
    dressUpModel.rotation = CFG.PlayerModel.defaultFacing or 0
    dressUpModel.rotateDir = 0
    dressUpModel.isWearingTryOn = false

    -- 2. Modelo de Animação (PlayerModel puro para SetSequence no Livro de Magias)
    local animModel = CreateFrame("PlayerModel", "ConsoleModeMM_AnimModel", leftPanel)
    animModel:SetPoint("CENTER", leftPanel, "CENTER", CFG.PlayerModel.offsetX, CFG.PlayerModel.offsetY)
    animModel:SetWidth(CFG.PlayerModel.width)
    animModel:SetHeight(CFG.PlayerModel.height)
    animModel:SetFrameLevel(leftPanel:GetFrameLevel() + 3)
    animModel.rotation = CFG.PlayerModel.defaultFacing or 0
    animModel.rotateDir = 0
    animModel:Hide()

    -- Configuração de Rotação e Drag para ambos os modelos
    local function setupModelInteractions(m)
        m:EnableMouse(true)
        m:SetScript("OnMouseDown", function()
            if arg1 == "LeftButton" or arg1 == "RightButton" then
                this.isDragging = true
                local curX, curY = GetCursorPosition()
                this.prevMouseX = curX
            end
        end)

        m:SetScript("OnMouseUp", function()
            this.isDragging = false
        end)

        m:SetScript("OnUpdate", function()
            -- 1. Rotação suave contínua via Analógico Esquerdo / Teclas A e D (WASD)
            if this.rotateDir and this.rotateDir ~= 0 then
                local delta = (arg1 or 0.016) * 3.5 * this.rotateDir
                this.rotation = (this.rotation or 0) + delta
                MainMenu.currentFacing = this.rotation
                if this.SetFacing then
                    this:SetFacing(this.rotation)
                end
            end

            -- 2. Rotação via arrasto de Mouse / Right Stick
            if this.isDragging then
                local curX, curY = GetCursorPosition()
                if this.prevMouseX then
                    local diffX = curX - this.prevMouseX
                    if diffX ~= 0 then
                        this.rotation = (this.rotation or 0) + (diffX * CFG.PlayerModel.rotateSpeed)
                        MainMenu.currentFacing = this.rotation
                        if this.SetFacing then
                            this:SetFacing(this.rotation)
                        end
                        this.prevMouseX = curX
                    end
                end
            end

            -- 3. Reprodução contínua da animação sem flickering (FASE 7)
            if this.activeSeq and this.activeSeq > 0 and this.animStartTime then
                local elapsedSec = GetTime() - this.animStartTime
                if elapsedSec < 1.6 then
                    if this.SetSequenceTime then
                        this:SetSequenceTime(this.activeSeq, elapsedSec * 1000)
                    end
                else
                    this.activeSeq = 0
                    this.animStartTime = nil
                    if this.SetSequence then
                        this:SetSequence(0)
                    end
                end
            end
        end)
    end

    setupModelInteractions(dressUpModel)
    setupModelInteractions(animModel)

    if CFG.PlayerModel.showPlayerName then
        local infoBox = CreateFrame("Frame", "ConsoleModeMM_PlayerInfo", leftPanel)
        infoBox:SetHeight(48)
        infoBox:SetPoint("BOTTOM", leftPanel, "BOTTOM", 0, 8)
        infoBox:SetPoint("LEFT", leftPanel, "LEFT", 12, 0)
        infoBox:SetPoint("RIGHT", leftPanel, "RIGHT", -12, 0)
        infoBox:SetFrameLevel(leftPanel:GetFrameLevel() + 15)

        local nameText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        nameText:SetPoint("TOP", infoBox, "TOP", 0, 0)
        MainMenu:ApplyFont(nameText, CFG.Fonts.titleFontFile, CFG.Fonts.playerNameSize)
        nameText:SetText(UnitName("player") or "Jogador")

        local subText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        subText:SetPoint("TOP", nameText, "BOTTOM", 0, -2)
        MainMenu:ApplyFont(subText, CFG.Fonts.subFontFile, CFG.Fonts.playerSubSize)

        dressUpModel.infoBox  = infoBox
        dressUpModel.nameText = nameText
        dressUpModel.subText  = subText
        animModel.infoBox     = infoBox
        animModel.nameText    = nameText
        animModel.subText     = subText
    end

    self.dressUpModel = dressUpModel
    self.animModel = animModel
    self.playerModel = dressUpModel
    self.currentFacing = CFG.PlayerModel.defaultFacing or 0

    return dressUpModel
end

function MainMenu:UpdatePlayerModel()
    if self.dressUpModel and self.dressUpModel.SetUnit then
        self.dressUpModel:SetUnit("player")
    end
    if self.animModel and self.animModel.SetUnit then
        self.animModel:SetUnit("player")
    end
    if self.playerModel.Dress then
        self.playerModel:Dress()
    end
    if self.playerModel.SetFacing then
        self.playerModel:SetFacing(self.playerModel.rotation or CFG.PlayerModel.defaultFacing or 0)
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

function MainMenu:TryOnItem(itemLink, itemType, equipLoc)
    if not self.playerModel or not itemLink then return end
    if not self.playerModel.TryOn then return end

    if self.lastTryOnLink == itemLink and self.playerModel.isWearingTryOn then
        return
    end

    local currentFacing = self.playerModel.rotation or (self.playerModel.GetFacing and self.playerModel:GetFacing()) or 0

    local _, _, extractedID = string.find(itemLink, "item:(%d+)")
    local numID = extractedID and tonumber(extractedID)

    local ok = false

    -- 1. Tenta por ID numérico direto (método nativo mais rápido do WoW 1.12)
    if numID then
        ok = pcall(function() self.playerModel:TryOn(numID) end)
    end

    -- 2. Tenta por hiperlink ou item string
    if not ok then
        ok = pcall(function() self.playerModel:TryOn(itemLink) end)
    end

    if ok then
        self.lastTryOnLink = itemLink
        self.playerModel.isWearingTryOn = true
        if self.playerModel.SetFacing then
            self.playerModel:SetFacing(currentFacing)
        end
    end
end

function MainMenu:RestorePlayerModel()
    if not self.playerModel then return end
    self.currentSpellPose = nil
    local currentFacing = self.playerModel.rotation or (self.playerModel.GetFacing and self.playerModel:GetFacing()) or 0
    if self.playerModel.isWearingTryOn then
        if self.playerModel.Dress then
            self.playerModel:Dress()
        elseif self.playerModel.SetUnit then
            self.playerModel:SetUnit("player")
        end
        self.playerModel.isWearingTryOn = false
        self.lastTryOnLink = nil
    end
    if self.playerModel.SetSequence then
        pcall(function() self.playerModel:SetSequence(0) end)
    end
    if self.playerModel.SetFacing then
        self.playerModel:SetFacing(currentFacing)
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
    container:SetFrameLevel(leftPanel:GetFrameLevel() + 10)

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
    container:SetFrameLevel(leftPanel:GetFrameLevel() + 10)

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

    -- 2. Atualiza Buffs Ativos e Encantamentos de Arma (Estilo Zelda)
    local rows = self.statsAndBuffs.buffRows
    if rows then
        local buffCount = 0

        -- 2.1. Encantamentos Temporários de Arma (Rockbiter, Flametongue, Windfury, Venenos, Óleos)
        local hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges = GetWeaponEnchantInfo()

        if hasMH and buffCount < CFG.StatsAndBuffs.maxBuffs then
            buffCount = buffCount + 1
            local row = rows[buffCount]
            local mhName, mhIcon = self:GetWeaponEnchantDetails(16)
            local timeLeft = (mhExp or 0) / 1000

            row.icon:SetTexture(mhIcon or "Interface\\Icons\\INV_Sword_04")

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

            row.name:SetText("|cffffffff" .. mhName .. "|r" .. durStr)
            row:Show()
        end

        if hasOH and buffCount < CFG.StatsAndBuffs.maxBuffs then
            buffCount = buffCount + 1
            local row = rows[buffCount]
            local ohName, ohIcon = self:GetWeaponEnchantDetails(17)
            local timeLeft = (ohExp or 0) / 1000

            row.icon:SetTexture(ohIcon or "Interface\\Icons\\INV_Sword_04")

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

            row.name:SetText("|cffffffff" .. ohName .. "|r" .. durStr)
            row:Show()
        end

        -- 2.2. Buffs Padrão do Jogador (HELPFUL)
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

function MainMenu:CreateMoneyWidget(parent, prefix, alignRight)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(16)
    frame:SetWidth(180)
    frame:SetFrameLevel(parent:GetFrameLevel() + 5)
    frame.alignRight = alignRight

    local copperIcon = frame:CreateTexture(nil, "OVERLAY")
    copperIcon:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_copper.tga")
    copperIcon:SetWidth(13)
    copperIcon:SetHeight(13)
    frame.copperIcon = copperIcon

    local copperText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    MainMenu:ApplyFont(copperText, CFG.Fonts.bodyFontFile, 12)
    frame.copperText = copperText

    local silverIcon = frame:CreateTexture(nil, "OVERLAY")
    silverIcon:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_silver.tga")
    silverIcon:SetWidth(13)
    silverIcon:SetHeight(13)
    frame.silverIcon = silverIcon

    local silverText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    MainMenu:ApplyFont(silverText, CFG.Fonts.bodyFontFile, 12)
    frame.silverText = silverText

    local goldIcon = frame:CreateTexture(nil, "OVERLAY")
    goldIcon:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\coin_gold.tga")
    goldIcon:SetWidth(13)
    goldIcon:SetHeight(13)
    frame.goldIcon = goldIcon

    local goldText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    MainMenu:ApplyFont(goldText, CFG.Fonts.bodyFontFile, 12)
    frame.goldText = goldText

    local prefixText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    MainMenu:ApplyFont(prefixText, CFG.Fonts.subFontFile, 12)
    prefixText:SetText(prefix or "|cffe09a15Moedas:|r")
    frame.prefixText = prefixText

    function frame:SetAmount(amount)
        amount = tonumber(amount) or 0
        local gold = math.floor(amount / 10000)
        local silver = math.floor(math.mod(amount, 10000) / 100)
        local copper = math.mod(amount, 100)

        if alignRight then
            copperIcon:ClearAllPoints()
            copperIcon:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
            copperIcon:Show()

            copperText:ClearAllPoints()
            copperText:SetPoint("RIGHT", copperIcon, "LEFT", -2, 0)
            copperText:SetText(tostring(copper))
            copperText:Show()

            local leftmost = copperText

            if silver > 0 or gold > 0 then
                silverIcon:ClearAllPoints()
                silverIcon:SetPoint("RIGHT", leftmost, "LEFT", -4, 0)
                silverIcon:Show()

                silverText:ClearAllPoints()
                silverText:SetPoint("RIGHT", silverIcon, "LEFT", -2, 0)
                silverText:SetText(tostring(silver))
                silverText:Show()

                leftmost = silverText
            else
                silverIcon:Hide()
                silverText:Hide()
            end

            if gold > 0 then
                goldIcon:ClearAllPoints()
                goldIcon:SetPoint("RIGHT", leftmost, "LEFT", -4, 0)
                goldIcon:Show()

                goldText:ClearAllPoints()
                goldText:SetPoint("RIGHT", goldIcon, "LEFT", -2, 0)
                goldText:SetText(tostring(gold))
                goldText:Show()

                leftmost = goldText
            else
                goldIcon:Hide()
                goldText:Hide()
            end

            prefixText:ClearAllPoints()
            prefixText:SetPoint("RIGHT", leftmost, "LEFT", -6, 0)
            prefixText:Show()
        else
            prefixText:ClearAllPoints()
            prefixText:SetPoint("LEFT", frame, "LEFT", 0, 0)
            prefixText:Show()

            local prev = prefixText

            if gold > 0 then
                goldText:ClearAllPoints()
                goldText:SetPoint("LEFT", prev, "RIGHT", 4, 0)
                goldText:SetText(tostring(gold))
                goldText:Show()

                goldIcon:ClearAllPoints()
                goldIcon:SetPoint("LEFT", goldText, "RIGHT", 2, 0)
                goldIcon:Show()

                prev = goldIcon
            else
                goldText:Hide()
                goldIcon:Hide()
            end

            if silver > 0 or gold > 0 then
                silverText:ClearAllPoints()
                silverText:SetPoint("LEFT", prev, "RIGHT", 4, 0)
                silverText:SetText(tostring(silver))
                silverText:Show()

                silverIcon:ClearAllPoints()
                silverIcon:SetPoint("LEFT", silverText, "RIGHT", 2, 0)
                silverIcon:Show()

                prev = silverIcon
            else
                silverText:Hide()
                silverIcon:Hide()
            end

            copperText:ClearAllPoints()
            copperText:SetPoint("LEFT", prev, "RIGHT", 4, 0)
            copperText:SetText(tostring(copper))
            copperText:Show()

            copperIcon:ClearAllPoints()
            copperIcon:SetPoint("LEFT", copperText, "RIGHT", 2, 0)
            copperIcon:Show()
        end

        frame:Show()
    end

    return frame
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
    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
    titleText:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    titleText:SetJustifyH("LEFT")
    MainMenu:ApplyFont(titleText, CFG.Fonts.titleFontFile, CFG.Fonts.detailTitleSize)
    card.titleText = titleText

    -- 3. Subtítulo (Tipo / Subtipo / Nível Requerido)
    local typeText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
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

    -- 5. Preço de Venda do Item (Widget gráfico nativo com ícones de moedas)
    local sellWidget = MainMenu:CreateMoneyWidget(card, "|cffaaaaaaVenda:|r", false)
    sellWidget:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 26)
    sellWidget:Hide()
    card.sellWidget = sellWidget

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

    local moneyWidget = MainMenu:CreateMoneyWidget(footerBar, "|cffe09a15Moedas:|r", true)
    moneyWidget:SetPoint("RIGHT", footerBar, "RIGHT", 0, 0)
    card.moneyWidget = moneyWidget

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

        -- Formata subtítulo (ex: Peitoral • Armadura de Malha • Req. Nv 12)
        local sub = {}
        local locName = nil
        if itemData.equipLoc and itemData.equipLoc ~= "" then
            locName = getglobal(itemData.equipLoc) or itemData.equipLoc
            if string.find(locName, "^INVTYPE_") then
                locName = nil
            end
        end

        local stName = itemData.subType
        if locName and locName ~= "" then
            table.insert(sub, locName)
        end
        if stName and stName ~= "" then
            -- Evita duplicidade se o slot e o subtipo forem idênticos (ex: Escudo / Shields)
            local isDuplicate = false
            if locName then
                local lLoc = string.lower(locName)
                local lSt = string.lower(stName)
                if lLoc == lSt or lSt == lLoc .. "s" or lLoc == lSt .. "s" then
                    isDuplicate = true
                end
            end
            if not isDuplicate then
                table.insert(sub, stName)
            end
        end

        local rLevel = tonumber(itemData.reqLevel) or 0
        if rLevel > 1 then
            table.insert(sub, "Req. Nv " .. rLevel)
        end
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

        -- Preço de venda com ícones gráficos oficiais
        local sPrice = tonumber(itemData.sellPrice) or 0
        if sPrice > 0 and self.sellWidget then
            self.sellWidget:SetAmount(sPrice)
            self.sellWidget:Show()
        elseif self.sellWidget then
            self.sellWidget:Hide()
        end

        self:UpdateMoney()
        self:Show()
    end

    -- Método para exibir dados de uma magia/habilidade
    function card:ShowSpell(spellData)
        if not spellData or not spellData.name then
            self:Clear("Nenhuma magia selecionada")
            return
        end

        self.icon:SetTexture(spellData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        self.icon:Show()
        self.iconBorder:Show()
        self.iconBorder:SetBackdropBorderColor(0.88, 0.60, 0.08, 0.95)

        self.titleText:SetText("|cffffd200" .. spellData.name .. "|r")
        
        local subInfo = {}
        if spellData.rank and spellData.rank ~= "" then
            table.insert(subInfo, "|cffffffff" .. spellData.rank .. "|r")
        end
        if spellData.castTime and spellData.castTime ~= "" then
            table.insert(subInfo, "|cffaaaaaa" .. spellData.castTime .. "|r")
        end
        if spellData.range and spellData.range ~= "" then
            table.insert(subInfo, "|cffaaaaaa" .. spellData.range .. "|r")
        end
        self.typeText:SetText(table.concat(subInfo, "  |  "))

        local bodyLines = {}
        if spellData.cost and spellData.cost ~= "" then
            table.insert(bodyLines, "|cff3399ff" .. spellData.cost .. "|r")
        end
        if spellData.cooldown and spellData.cooldown ~= "" then
            table.insert(bodyLines, "|cffff5555" .. spellData.cooldown .. "|r")
        end
        if spellData.desc and spellData.desc ~= "" then
            table.insert(bodyLines, "|cffffffff" .. spellData.desc .. "|r")
        end

        if table.getn(bodyLines) > 0 then
            self.descText:SetText(table.concat(bodyLines, "\n"))
        else
            self.descText:SetText("|cff888888Sem descrição adicional.|r")
        end

        if self.sellWidget then self.sellWidget:Hide() end
        if self.slotsFreeText then
            self.slotsFreeText:SetText("|cffe09a15Grimório:|r |cffffffff" .. (spellData.tabName or "Geral") .. "|r")
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
        if self.sellWidget then self.sellWidget:Hide() end
        self:UpdateMoney()
    end

    -- Atualiza o saldo de dinheiro do jogador no rodapé
    function card:UpdateMoney()
        if self.moneyWidget then
            self.moneyWidget:SetAmount(GetMoney() or 0)
        end
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

    function gridFrame:GetCapacity()
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

        -- 2. Calcula quantas linhas cabem estritamente sem invadir a área de tooltip abaixo
        local maxRows = math.floor((h + gy) / (s + gy))
        if maxRows < 1 then maxRows = 1 end
        local maxFit = c * maxRows

        self.cols = c
        self.maxRows = maxRows
        self.maxFitSlots = maxFit

        return maxFit, c, maxRows
    end

    -- Organiza os slots no layout de grade 2D responsivo que preenche 100% da largura e respeita a altura
    function gridFrame:LayoutSlots(visibleCount)
        local maxFit, c, maxRows = self:GetCapacity()

        local w = self:GetWidth()
        if not w or w < 100 then
            local totalW = (MainMenu.frame and MainMenu.frame:GetWidth()) or 980
            if totalW < 100 then totalW = 980 end
            local availableW = totalW - (CFG.LeftPanel.paddingLeft + math.abs(CFG.RightPanel.paddingRight) + CFG.RightPanel.gapX)
            local leftW = math.floor(availableW * CFG.LeftPanel.widthRatio)
            w = availableW - leftW
        end

        local s = self.slotSize or 40
        local minGapX = self.gapX or 6
        local gy = self.gapY or 6

        -- Distribui o gap horizontal de ponta a ponta para preencher 100% da largura
        local gx = minGapX
        if c > 1 then
            gx = math.floor((w - (c * s)) / (c - 1))
            if gx < 2 then gx = 2 end
        end

        local limit = visibleCount or maxFit
        if limit > maxFit then limit = maxFit end
        if limit > table.getn(self.slots) then limit = table.getn(self.slots) end

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
        local changed = (self.selectedSlotIndex ~= index)
        self.selectedSlotIndex = index
        for i, slot in ipairs(self.slots) do
            if i == index then
                slot.highlight:Show()
                if (changed or not self.lastDispatchedSlot) and self.onSlotFocused then
                    self.lastDispatchedSlot = index
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

        local _, _, idStr = string.find(rawLink, "item:(%d+)")
        local itemID = tonumber(idStr)

        -- Base de dados própria embutida + compatibilidade com addons de economia
        if itemID and ConsoleMode_SellValues and ConsoleMode_SellValues[itemID] then
            sellPrice = ConsoleMode_SellValues[itemID]
        elseif itemID and ShaguTweaks and ShaguTweaks.SellValueDB and ShaguTweaks.SellValueDB[itemID] then
            sellPrice = ShaguTweaks.SellValueDB[itemID]
        elseif itemID and ShaguValueDB and ShaguValueDB[itemID] then
            sellPrice = ShaguValueDB[itemID]
        elseif GetSellValue then
            sellPrice = GetSellValue(rawLink) or 0
        elseif ShaguValue then
            sellPrice = ShaguValue(rawLink) or 0
        elseif GetItemSellValue then
            sellPrice = GetItemSellValue(rawLink) or 0
        end
    end

    -- Varre as linhas do Tooltip para atributos e preço de venda
    scanTip.money = 0
    scanTip:ClearLines()
    scanTip:SetBagItem(bagID, slotID)

    if scanTip.money and scanTip.money > 0 then
        sellPrice = scanTip.money
    end

    local statsLines = {}
    local desc = ""
    local numLines = scanTip:NumLines() or 0

    for l = 2, numLines do
        local leftTextObj = _G["ConsoleModeMMScanTooltipTextLeft" .. l]
        local rightTextObj = _G["ConsoleModeMMScanTooltipTextRight" .. l]
        local leftText = (leftTextObj and leftTextObj:GetText()) or ""
        local rightText = (rightTextObj and rightTextObj:GetText()) or ""

        if leftText ~= "" then
            if string.find(leftText, "Preço de Venda:") or string.find(leftText, "Sell Price:") then
                local full = leftText .. " " .. rightText
                local g = tonumber(string.match(full, "(%d+)%s*g")) or 0
                local s = tonumber(string.match(full, "(%d+)%s*s")) or 0
                local c = tonumber(string.match(full, "(%d+)%s*c")) or 0
                if (g + s + c) > 0 then
                    sellPrice = (g * 10000) + (s * 100) + c
                end
            elseif string.find(leftText, "Uso:") or string.find(leftText, "Use:") or string.find(leftText, "Equipar:") then
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

function MainMenu:ParseSpellData(spellIndex, bookType)
    bookType = bookType or "spell"
    local name, rank = GetSpellName(spellIndex, bookType)
    if not name or name == "" then return nil end

    local icon = GetSpellTexture(spellIndex, bookType) or "Interface\\Icons\\INV_Misc_QuestionMark"
    local rankStr = rank or ""

    scanTip:ClearLines()
    scanTip:SetSpell(spellIndex, bookType)

    local cost = ""
    local range = ""
    local castTime = ""
    local cooldown = ""
    local descLines = {}

    local numLines = scanTip:NumLines()
    for l = 2, numLines do
        local leftObj = _G["ConsoleModeMMScanTooltipTextLeft" .. l]
        local rightObj = _G["ConsoleModeMMScanTooltipTextRight" .. l]
        local left = (leftObj and leftObj:GetText()) or ""
        local right = (rightObj and rightObj:GetText()) or ""

        if string.find(left, "Mana") or string.find(left, "Rage") or string.find(left, "Energy") or string.find(left, "Fúria") or string.find(left, "Energia") then
            cost = left
        elseif string.find(left, "cast") or string.find(left, "Instant") or string.find(left, "lançamento") or string.find(left, "Instantâneo") or string.find(left, "Canalizada") then
            castTime = left
        elseif left ~= "" and not string.find(left, "Rank") and not string.find(left, "Grau") then
            table.insert(descLines, left)
        end

        if string.find(right, "yd range") or string.find(right, "m de alcance") or string.find(right, "Melee Range") or string.find(right, "Corpo a corpo") then
            range = right
        elseif string.find(right, "cooldown") or string.find(right, "recarga") or string.find(right, "espera") then
            cooldown = right
        end
    end

    -- Classificação de Poses de Conjuração / Animação 3D (FASE 7)
    local lowerName = string.lower(name)
    local lowerRank = string.lower(rankStr)
    local isPassive = false

    if string.find(lowerRank, "passiv") or string.find(lowerName, "passive") or string.find(lowerName, "passiva") then
        isPassive = true
    end
    if IsPassiveSpell and IsPassiveSpell(spellIndex, bookType) then
        isPassive = true
    end
    if not isPassive then
        for _, d in ipairs(descLines) do
            if string.find(string.lower(d), "passive") or string.find(string.lower(d), "passiva") then
                isPassive = true
                break
            end
        end
    end

    local pose = 53 -- Padrão: SpellCastDirected (Arremesso frontal com a mão aberta)

    if isPassive then
        pose = 82 -- EmoteFlex (Pose de força/vigor para habilidades passivas)
    elseif string.find(lowerName, "shield bash") or string.find(lowerName, "shield slam") or string.find(lowerName, "pancada com escudo") then
        pose = 59 -- ShieldBash (Pancada frontal com escudo)
    elseif string.find(lowerName, "shield") or string.find(lowerName, "escudo") or string.find(lowerName, "block") or string.find(lowerName, "bloqueio")
       or string.find(lowerName, "armor") or string.find(lowerName, "armadura") or string.find(lowerName, "defens") then
        pose = 24 -- ShieldBlock (Postura de bloqueio com escudo)
    elseif string.find(lowerName, "totem") or string.find(lowerName, "summon") or string.find(lowerName, "conjurar") then
        pose = 54 -- SpellCastOmni (Conjuração mágica no chão)
    elseif string.find(lowerName, "heal") or string.find(lowerName, "cura") or string.find(lowerName, "wave") or string.find(lowerName, "onda")
       or string.find(lowerName, "renew") or string.find(lowerName, "rejuvenescer") or string.find(lowerName, "regrowth") or string.find(lowerName, "menor") or string.find(lowerName, "lesser") then
        pose = 125 -- ChannelCastOmni (Canalização de cura com mãos erguidas)
    elseif string.find(lowerName, "drain") or string.find(lowerName, "mind flay") or string.find(lowerName, "canaliz") then
        pose = 124 -- ChannelCastDirected (Canalização frontal direta)
    elseif string.find(lowerName, "shock") or string.find(lowerName, "choque") or string.find(lowerName, "bolt") or string.find(lowerName, "seta")
       or string.find(lowerName, "raio") or string.find(lowerName, "fire") or string.find(lowerName, "fogo") or string.find(lowerName, "frost")
       or string.find(lowerName, "gelo") or string.find(lowerName, "lava") or string.find(lowerName, "earth") or string.find(lowerName, "terra")
       or string.find(lowerName, "blast") or string.find(lowerName, "chama") or string.find(lowerName, "flame") or string.find(lowerName, "smite") then
        pose = 53 -- SpellCastDirected (Arremesso frontal com a mão aberta)
    elseif string.find(lowerName, "slam") or string.find(lowerName, "mortal") or string.find(lowerName, "cleave") or string.find(lowerName, "2h") then
        pose = 58 -- Special2H (Golpe pesado de duas mãos)
    elseif string.find(lowerName, "weapon") or string.find(lowerName, "arma") or string.find(lowerName, "rockbiter") or string.find(lowerName, "windfury")
       or string.find(lowerName, "flametongue") or string.find(lowerName, "frostbrand") or string.find(lowerName, "strike") or string.find(lowerName, "golpe")
       or string.find(lowerName, "attack") or string.find(lowerName, "ataque") or string.find(lowerName, "rend") or string.find(lowerName, "sinister") then
        pose = 57 -- Special1H (Golpe de uma mão sem flickering)
    elseif string.find(lowerName, "kick") or string.find(lowerName, "chute") or string.find(lowerName, "pummel") then
        pose = 95 -- Kick (Chute frontal)
    elseif string.find(lowerName, "whirlwind") or string.find(lowerName, "redemoinho") then
        pose = 126 -- Whirlwind (Giro 360° com a arma)
    elseif string.find(lowerName, "shoot") or string.find(lowerName, "tiro") or string.find(lowerName, "bow") or string.find(lowerName, "arco")
       or string.find(lowerName, "gun") or string.find(lowerName, "arma de fogo") or string.find(lowerName, "disparo") then
        pose = 46 -- AttackBow / Longo alcance
    elseif string.find(lowerName, "shout") or string.find(lowerName, "grito") or string.find(lowerName, "rage") or string.find(lowerName, "fúria")
       or string.find(lowerName, "roar") or string.find(lowerName, "rugido") or string.find(lowerName, "taunt") or string.find(lowerName, "provocar")
       or string.find(lowerName, "bloodlust") or string.find(lowerName, "heroism") then
        pose = 55 -- BattleRoar (Rugido de guerra com a cabeça para trás)
    elseif string.find(lowerName, "buff") or string.find(lowerName, "blessing") or string.find(lowerName, "bênção")
       or string.find(lowerName, "mark") or string.find(lowerName, "marca") or string.find(lowerName, "fortitude") then
        pose = 54 -- SpellCastOmni (Conjuração de buff com ambas as mãos)
    else
        pose = 53 -- SpellCastDirected / Arremesso de magia
    end

    return {
        spellIndex = spellIndex,
        bookType   = bookType,
        name       = name,
        rank       = rankStr,
        icon       = icon,
        cost       = cost,
        range      = range,
        castTime   = castTime,
        cooldown   = cooldown,
        desc       = table.concat(descLines, "\n"),
        pose       = pose,
    }
end

function MainMenu:ScanSpellbook(tabIndex)
    local spells = {}
    local numTabs = GetNumSpellTabs() or 0
    if numTabs == 0 then return { spells = {}, tabs = {} } end

    local tabs = {}
    for t = 1, numTabs do
        local name, icon, offset, numSpells = GetSpellTabInfo(t)
        if name and numSpells then
            table.insert(tabs, {
                id = t,
                name = name,
                icon = icon,
                offset = offset,
                numSpells = numSpells,
            })
        end
    end

    tabIndex = tabIndex or 1
    if tabIndex > table.getn(tabs) then tabIndex = 1 end
    local selectedTab = tabs[tabIndex]

    if selectedTab and selectedTab.numSpells > 0 then
        for s = selectedTab.offset + 1, selectedTab.offset + selectedTab.numSpells do
            local spellData = self:ParseSpellData(s, "spell")
            if spellData then
                spellData.tabName = selectedTab.name
                table.insert(spells, spellData)
            end
        end
    end

    return {
        spells = spells,
        tabs = tabs,
        currentTab = selectedTab,
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

    -- Indicador RT à direita
    local r2Hint = headerBar:CreateTexture(nil, "OVERLAY")
    r2Hint:SetWidth(20)
    r2Hint:SetHeight(20)
    r2Hint:SetPoint("RIGHT", headerBar, "RIGHT", 0, 0)
    r2Hint:SetTexture(CFG.Icons.RT)
    pageBags.r2Hint = r2Hint

    -- Botões de Filtro de Categoria (Ancorados da direita para esquerda para ordenar: [LT] Todos ... Diversos [RT])
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

    -- Indicador LT à esquerda da primeira categoria (Todos)
    local l2Hint = headerBar:CreateTexture(nil, "OVERLAY")
    l2Hint:SetWidth(20)
    l2Hint:SetHeight(20)
    l2Hint:SetPoint("RIGHT", prevCat, "LEFT", -6, 0)
    l2Hint:SetTexture(CFG.Icons.LT)
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
                MainMenu:TryOnItem(tryLink, itemData.itemType, itemData.equipLoc or itemData.itemEquipLoc)
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
    local grid = pageBags.grid
    local maxFit = grid:GetCapacity()
    local pageSize = CFG.Grid.pageSize
    if not pageSize or pageSize == "auto" then
        pageSize = maxFit
    end
    if pageSize < 1 then pageSize = 40 end

    local numItems = table.getn(items)
    local totalElements = numItems
    if curCat == "ALL" then
        totalElements = scanResult.totalSlots
    end

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
    local displaySlots = pageSize
    if displaySlots > maxFit then displaySlots = maxFit end

    grid:LayoutSlots(displaySlots)

    for slotIdx = 1, displaySlots do
        local globalIdx = startIndex + slotIdx - 1
        local slot = grid.slots[slotIdx]
        if slot then
            local itemData = (globalIdx <= totalElements) and items[globalIdx] or nil

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
    if totalElements > 0 and items[startIndex] and not items[startIndex].isEmpty then
        grid:SelectSlot(1)
    elseif totalElements > 0 and items[startIndex] then
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
-- 7.5. CONFIGURAÇÃO DA ABA 2: LIVRO DE MAGIAS & HABILIDADES (FASE 7)
-- ============================================================================

function MainMenu:TriggerSpellPose(poseSeq)
    if not self.animModel or not self.animModel:IsVisible() then return end
    poseSeq = poseSeq or 0
    self.currentSpellPose = poseSeq
    self.animModel.activeSeq = poseSeq
    self.animModel.animStartTime = GetTime()

    if self.animModel.SetSequenceTime then
        pcall(function() self.animModel:SetSequenceTime(poseSeq, 0) end)
    elseif self.animModel.SetSequence then
        pcall(function() self.animModel:SetSequence(poseSeq) end)
    end
end

function MainMenu:SetupSpellsPage(pageSpells)
    if pageSpells.isInitialized then return end

    -- 1. Barra de Cabeçalho / Abas do Grimório com [L2] e [R2]
    local headerBar = CreateFrame("Frame", "ConsoleModeMM_SpellsHeader", pageSpells)
    headerBar:SetHeight(32)
    headerBar:SetPoint("TOPLEFT", pageSpells, "TOPLEFT", 0, 0)
    headerBar:SetPoint("TOPRIGHT", pageSpells, "TOPRIGHT", 0, 0)

    -- Indicador RT à direita
    local r2Hint = headerBar:CreateTexture(nil, "OVERLAY")
    r2Hint:SetWidth(20)
    r2Hint:SetHeight(20)
    r2Hint:SetPoint("RIGHT", headerBar, "RIGHT", 0, 0)
    r2Hint:SetTexture(CFG.Icons.RT)
    pageSpells.r2Hint = r2Hint
    pageSpells.headerBar = headerBar
    pageSpells.currentTabIdx = 1

    -- 2. Painel Fixo de Detalhes da Magia (base)
    local detailCard = self:CreateDetailCard(pageSpells)
    pageSpells.detailCard = detailCard

    -- 3. Navegação de Páginas do Grimório
    local pageNav = CreateFrame("Frame", "ConsoleModeMM_SpellsPageNav", pageSpells)
    pageNav:SetHeight(26)
    pageNav:SetPoint("BOTTOMRIGHT", detailCard, "TOPRIGHT", 0, 4)
    pageNav:SetPoint("LEFT", detailCard, "RIGHT", -120, 0)

    local btnBackdrop = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
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

    prevPageBtn:SetScript("OnClick", function()
        MainMenu:PrevSpellPage()
    end)
    pageSpells.prevPageBtn = prevPageBtn

    local pageText = pageNav:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pageText:SetPoint("CENTER", pageNav, "CENTER", 0, 0)
    MainMenu:ApplyFont(pageText, CFG.Fonts.subFontFile, 13)
    pageText:SetText("|cffaaaaaaPág.|r |cffffffff1 / 1|r")
    pageSpells.pageText = pageText

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

    nextPageBtn:SetScript("OnClick", function()
        MainMenu:NextSpellPage()
    end)
    pageSpells.nextPageBtn = nextPageBtn
    pageSpells.pageNav = pageNav

    -- 4. Container e Grid 2D de Slots de Magias
    local gridContainer = CreateFrame("Frame", "ConsoleModeMM_SpellsGridContainer", pageSpells)
    gridContainer:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -8)
    gridContainer:SetPoint("BOTTOMRIGHT", detailCard, "TOPRIGHT", 0, 30)

    local grid = self:CreateGrid(gridContainer, 80, CFG.Grid)
    pageSpells.grid = grid

    -- Callbacks do Grid de Magias
    grid.onSlotFocused = function(slotIndex, spellData)
        if spellData and spellData.name then
            detailCard:ShowSpell(spellData)
            MainMenu:TriggerSpellPose(spellData.pose)
        else
            detailCard:Clear("Grimório")
            MainMenu:TriggerSpellPose(0)
        end
    end

    grid.onSlotClicked = function(slotIndex, spellData)
        if CursorHasItem() or CursorHasSpell() then
            -- Se já tiver algo no cursor, solta
            ClearCursor()
        elseif spellData and spellData.spellIndex then
            CastSpell(spellData.spellIndex, spellData.bookType or "spell")
            PlaySound("igSpellBookOpen")
        end
    end

    pageSpells.isInitialized = true
end

function MainMenu:UpdateSpellsPage(keepPage)
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageSpells = self.tabContainer.pages["SPELLS"]
    if not pageSpells then return end

    self:SetupSpellsPage(pageSpells)

    local curTabIdx = pageSpells.currentTabIdx or 1
    local scanResult = self:ScanSpellbook(curTabIdx)
    local spells = scanResult.spells
    local tabs = scanResult.tabs

    -- 1. Cria/Atualiza os botões das abas do grimório (Geral, Fogo, etc.)
    if not pageSpells.tabButtons then pageSpells.tabButtons = {} end
    for _, b in ipairs(pageSpells.tabButtons) do b:Hide() end

    local prevBtn = pageSpells.r2Hint
    local numTabs = table.getn(tabs)
    for i = numTabs, 1, -1 do
        local tabData = tabs[i]
        local btn = pageSpells.tabButtons[i]
        if not btn then
            btn = CreateFrame("Button", "ConsoleModeMM_SpellTab" .. i, pageSpells.headerBar)
            btn:SetHeight(24)
            local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            t:SetPoint("CENTER", btn, "CENTER", 0, 0)
            MainMenu:ApplyFont(t, CFG.Fonts.bodyFontFile, 14)
            btn.title = t
            pageSpells.tabButtons[i] = btn
        end

        btn.title:SetText(tabData.name)
        local txtW = math.floor(btn.title:GetStringWidth() or 60)
        if txtW < 40 then txtW = 40 end
        btn:SetWidth(txtW + 12)

        btn:ClearAllPoints()
        btn:SetPoint("RIGHT", prevBtn, "LEFT", -6, 0)
        btn:Show()

        btn.tabIdx = tabData.id
        btn:SetScript("OnClick", function()
            MainMenu:SelectSpellTab(this.tabIdx)
        end)

        if tabData.id == curTabIdx then
            btn.title:SetTextColor(CFG.Tabs.activeColor.r, CFG.Tabs.activeColor.g, CFG.Tabs.activeColor.b)
        else
            btn.title:SetTextColor(0.6, 0.6, 0.6)
        end

        prevBtn = btn
    end

    -- Cria o hint LT à esquerda da primeira sub-aba
    if not pageSpells.l2Hint then
        local l2Hint = pageSpells.headerBar:CreateTexture(nil, "OVERLAY")
        l2Hint:SetWidth(20)
        l2Hint:SetHeight(20)
        l2Hint:SetTexture(CFG.Icons.LT)
        pageSpells.l2Hint = l2Hint
    end
    pageSpells.l2Hint:ClearAllPoints()
    pageSpells.l2Hint:SetPoint("RIGHT", prevBtn, "LEFT", -6, 0)
    pageSpells.l2Hint:Show()

    -- 2. Paginação
    local grid = pageSpells.grid
    local maxFit = grid:GetCapacity()
    local totalElements = table.getn(spells)
    local pageSize = CFG.Grid.pageSize
    if not pageSize or pageSize == "auto" then
        pageSize = maxFit
    end
    if pageSize < 1 then pageSize = 40 end

    local totalPages = math.ceil(totalElements / pageSize)
    if totalPages < 1 then totalPages = 1 end

    if not keepPage then
        pageSpells.currentPage = 1
    end
    local curPage = pageSpells.currentPage or 1
    if curPage > totalPages then curPage = totalPages end
    if curPage < 1 then curPage = 1 end
    pageSpells.currentPage = curPage

    if pageSpells.pageText then
        pageSpells.pageText:SetText(string.format("|cffaaaaaaPág.|r |cffffffff%d / %d|r", curPage, totalPages))
    end
    if pageSpells.pageNav then
        if totalPages > 1 then
            pageSpells.pageNav:Show()
        else
            pageSpells.pageNav:Hide()
        end
    end

    -- 3. Preenche os slots de magias
    grid:Clear()
    local startIndex = (curPage - 1) * pageSize + 1
    local displaySlots = pageSize
    if displaySlots > maxFit then displaySlots = maxFit end

    grid:LayoutSlots(displaySlots)

    for slotIdx = 1, displaySlots do
        local globalIdx = startIndex + slotIdx - 1
        local slot = grid.slots[slotIdx]
        if slot then
            local spellData = (globalIdx <= totalElements) and spells[globalIdx] or nil
            if spellData and spellData.name then
                slot.icon:SetTexture(spellData.icon)
                slot.icon:Show()
                slot.icon:SetAlpha(1.0)
                slot.data = spellData

                -- Extrai apenas o número do rank (ex: "Rank 4" -> "4") para ficar limpo no slot
                local _, _, rNum = string.find(spellData.rank, "(%d+)")
                if rNum then
                    slot.countText:SetText(rNum)
                else
                    slot.countText:SetText("")
                end
                slot.border:SetBackdropBorderColor(0.88, 0.60, 0.08, 0.95)
            else
                slot.icon:SetTexture(nil)
                slot.icon:Hide()
                slot.countText:SetText("")
                slot.border:SetBackdropBorderColor(0.45, 0.40, 0.35, 0.30)
                slot.data = nil
            end
        end
    end

    if totalElements > 0 and spells[startIndex] then
        grid:SelectSlot(1)
    else
        pageSpells.detailCard:Clear("Grimório Vazio")
        MainMenu:TriggerSpellPose(0)
    end
end

function MainMenu:SelectSpellTab(tabIdx)
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageSpells = self.tabContainer.pages["SPELLS"]
    if not pageSpells then return end
    pageSpells.currentTabIdx = tabIdx
    pageSpells.currentPage = 1
    self:UpdateSpellsPage(false)
    if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
end

function MainMenu:NextSpellPage()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageSpells = self.tabContainer.pages["SPELLS"]
    if not pageSpells then return end
    pageSpells.currentPage = (pageSpells.currentPage or 1) + 1
    self:UpdateSpellsPage(true)
    if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
end

function MainMenu:PrevSpellPage()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageSpells = self.tabContainer.pages["SPELLS"]
    if not pageSpells then return end
    pageSpells.currentPage = (pageSpells.currentPage or 1) - 1
    self:UpdateSpellsPage(true)
    if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
end

-- ============================================================================
-- 7.4. CONFIGURAÇÃO DA ABA DE MISSÕES & MAPA MUNDI (FASE 9 - ETAPA 9.1)
-- ============================================================================

function MainMenu:SetupQuestsPage(pageQuests)
    if pageQuests.isInitialized then return end

    -- 1. Barra Superior de Cabeçalho da Aba de Missões & Mapa
    local headerBar = CreateFrame("Frame", "ConsoleModeMM_QuestsHeader", pageQuests)
    headerBar:SetHeight(30)
    headerBar:SetPoint("TOPLEFT", pageQuests, "TOPLEFT", 0, 0)
    headerBar:SetPoint("TOPRIGHT", pageQuests, "TOPRIGHT", 0, 0)
    pageQuests.headerBar = headerBar

    local headerTitle = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerTitle:SetPoint("LEFT", headerBar, "LEFT", 4, 0)
    MainMenu:ApplyFont(headerTitle, CFG.Fonts.titleFontFile, 14)
    headerTitle:SetText("|cffe09a15DIÁRIO DE MISSÕES & MAPA MUNDI|r")
    pageQuests.headerTitle = headerTitle

    local questCountText = headerBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    questCountText:SetPoint("RIGHT", headerBar, "RIGHT", -4, 0)
    MainMenu:ApplyFont(questCountText, CFG.Fonts.subFontFile, 12)
    questCountText:SetText("|cffaaaaaaMissões: |cffffffff0 / 20|r")
    pageQuests.questCountText = questCountText

    local headerDivider = headerBar:CreateTexture(nil, "ARTWORK")
    headerDivider:SetHeight(1)
    headerDivider:SetPoint("BOTTOMLEFT", headerBar, "BOTTOMLEFT", 0, 0)
    headerDivider:SetPoint("BOTTOMRIGHT", headerBar, "BOTTOMRIGHT", 0, 0)
    headerDivider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    headerDivider:SetVertexColor(0.5, 0.4, 0.3, 0.4)

    -- 2. Container da Área Dividida (Split Area: Mapa Amplo à Esquerda, Missões à Direita)
    local splitArea = CreateFrame("Frame", "ConsoleModeMM_QuestsSplitArea", pageQuests)
    splitArea:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -4)
    splitArea:SetPoint("BOTTOMRIGHT", pageQuests, "BOTTOMRIGHT", 0, 0)
    pageQuests.splitArea = splitArea

    -- 2.1. Sub-Painel Direito: Lista de Missões e Card de Detalhes (Sidebar Compacto de 280px)
    local questPanel = CreateFrame("Frame", "ConsoleModeMM_QuestsListPanel", splitArea)
    questPanel:SetWidth(280)
    questPanel:SetPoint("TOPRIGHT", splitArea, "TOPRIGHT", 0, 0)
    questPanel:SetPoint("BOTTOMRIGHT", splitArea, "BOTTOMRIGHT", 0, 0)
    pageQuests.questPanel = questPanel

    -- 2.2. Sub-Painel Esquerdo: Canvas do Mapa da Região (Área Panorâmica Expandida)
    local mapPanel = CreateFrame("Frame", "ConsoleModeMM_QuestsMapPanel", splitArea)
    mapPanel:SetPoint("TOPLEFT", splitArea, "TOPLEFT", 0, 0)
    mapPanel:SetPoint("BOTTOMLEFT", splitArea, "BOTTOMLEFT", 0, 0)
    mapPanel:SetPoint("RIGHT", questPanel, "LEFT", -10, 0)
    pageQuests.mapPanel = mapPanel

    -- Fundo do Painel do Mapa
    local mapBg = mapPanel:CreateTexture(nil, "BACKGROUND")
    mapBg:SetAllPoints(mapPanel)
    mapBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    mapBg:SetVertexColor(0.02, 0.02, 0.02, 0.70)
    mapPanel.bg = mapBg

    -- Borda sutil do Painel do Mapa
    local mapBorder = CreateFrame("Frame", nil, mapPanel)
    mapBorder:SetAllPoints(mapPanel)
    local mbTop = mapBorder:CreateTexture(nil, "OVERLAY")
    mbTop:SetHeight(1)
    mbTop:SetPoint("TOPLEFT", mapBorder, "TOPLEFT", 0, 0)
    mbTop:SetPoint("TOPRIGHT", mapBorder, "TOPRIGHT", 0, 0)
    mbTop:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    mbTop:SetVertexColor(0.5, 0.4, 0.3, 0.6)

    local mbBottom = mapBorder:CreateTexture(nil, "OVERLAY")
    mbBottom:SetHeight(1)
    mbBottom:SetPoint("BOTTOMLEFT", mapBorder, "BOTTOMLEFT", 0, 0)
    mbBottom:SetPoint("BOTTOMRIGHT", mapBorder, "BOTTOMRIGHT", 0, 0)
    mbBottom:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    mbBottom:SetVertexColor(0.5, 0.4, 0.3, 0.6)

    local mbLeft = mapBorder:CreateTexture(nil, "OVERLAY")
    mbLeft:SetWidth(1)
    mbLeft:SetPoint("TOPLEFT", mapBorder, "TOPLEFT", 0, 0)
    mbLeft:SetPoint("BOTTOMLEFT", mapBorder, "BOTTOMLEFT", 0, 0)
    mbLeft:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    mbLeft:SetVertexColor(0.5, 0.4, 0.3, 0.6)

    local mbRight = mapBorder:CreateTexture(nil, "OVERLAY")
    mbRight:SetWidth(1)
    mbRight:SetPoint("TOPRIGHT", mapBorder, "TOPRIGHT", 0, 0)
    mbRight:SetPoint("BOTTOMRIGHT", mapBorder, "BOTTOMRIGHT", 0, 0)
    mbRight:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    mbRight:SetVertexColor(0.5, 0.4, 0.3, 0.6)

    -- Cabeçalho do Mapa (Nome da Zona / Região)
    local mapHeader = CreateFrame("Frame", nil, mapPanel)
    mapHeader:SetHeight(24)
    mapHeader:SetPoint("TOPLEFT", mapPanel, "TOPLEFT", 6, -6)
    mapHeader:SetPoint("TOPRIGHT", mapPanel, "TOPRIGHT", -6, -6)

    local mapZoneTitle = mapHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mapZoneTitle:SetPoint("LEFT", mapHeader, "LEFT", 4, 0)
    MainMenu:ApplyFont(mapZoneTitle, CFG.Fonts.titleFontFile, 13)
    mapZoneTitle:SetText("|cffffffffZona Atual|r")
    mapPanel.zoneTitle = mapZoneTitle

    local mapCoordsText = mapHeader:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    mapCoordsText:SetPoint("RIGHT", mapHeader, "RIGHT", -4, 0)
    MainMenu:ApplyFont(mapCoordsText, CFG.Fonts.subFontFile, 11)
    mapCoordsText:SetText("|cffaaaaaaGPS: --, --|r")
    mapPanel.coordsText = mapCoordsText

    -- Viewport / Container do Canvas de Texturas do Mapa
    local mapCanvas = CreateFrame("Frame", "ConsoleModeMM_MapCanvas", mapPanel)
    mapCanvas:SetPoint("TOPLEFT", mapHeader, "BOTTOMLEFT", 0, -4)
    mapCanvas:SetPoint("BOTTOMRIGHT", mapPanel, "BOTTOMRIGHT", -6, 26)
    mapCanvas:EnableMouse(true)
    mapPanel.canvas = mapCanvas

    local mapCanvasBg = mapCanvas:CreateTexture(nil, "BACKGROUND")
    mapCanvasBg:SetAllPoints(mapCanvas)
    mapCanvasBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    mapCanvasBg:SetVertexColor(0.0, 0.0, 0.0, 0.5)

    -- ScrollFrame que atua como Viewport com Clipping Automático do Mapa (Estilo Carbonite)
    local mapScrollFrame = CreateFrame("ScrollFrame", "ConsoleModeMM_MapScrollFrame", mapCanvas)
    mapScrollFrame:SetAllPoints(mapCanvas)
    mapScrollFrame:EnableMouse(true)
    mapScrollFrame:EnableMouseWheel(true)
    mapCanvas.scrollFrame = mapScrollFrame
    mapCanvas.zoomFactor = 1.0
    mapCanvas.panX = 0
    mapCanvas.panY = 0

    -- Container Interno dos 12 Tiles de Textura do Mapa
    local mapTilesContainer = CreateFrame("Frame", "ConsoleModeMM_MapTilesContainer", mapScrollFrame)
    mapTilesContainer:SetPoint("CENTER", mapScrollFrame, "CENTER", 0, 0)
    mapScrollFrame:SetScrollChild(mapTilesContainer)
    mapCanvas.tilesContainer = mapTilesContainer

    -- 1. Criação dos 12 Tiles Base de Pergaminho
    local tiles = {}
    for i = 1, 12 do
        local tile = mapTilesContainer:CreateTexture("ConsoleModeMM_MapTile" .. i, "BACKGROUND")
        tiles[i] = tile
    end
    mapCanvas.tiles = tiles

    -- 2. Pool de Texturas de Overlay para Áreas Exploradas / Revelação Total (Sem Fog of War)
    local overlays = {}
    for oIdx = 1, 180 do
        local oTex = mapTilesContainer:CreateTexture("ConsoleModeMM_MapOverlay" .. oIdx, "ARTWORK")
        oTex:Hide()
        overlays[oIdx] = oTex
    end
    mapCanvas.overlays = overlays

    -- 3. Marcadores de Membros do Grupo (Party 1 a 4)
    local partyPins = {}
    for p = 1, 4 do
        local pin = CreateFrame("Frame", "ConsoleModeMM_MapPartyPin" .. p, mapTilesContainer)
        pin:SetWidth(18)
        pin:SetHeight(18)
        pin:SetFrameLevel(mapTilesContainer:GetFrameLevel() + 4)
        local ptTex = pin:CreateTexture(nil, "OVERLAY")
        ptTex:SetAllPoints(pin)
        ptTex:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon")
        pin.texture = ptTex
        pin:Hide()
        partyPins[p] = pin
    end
    mapCanvas.partyPins = partyPins

    -- 4. Marcador do Jogador com Seta Direcional em Tempo Real (Player GPS Pin)
    local playerPin = CreateFrame("Frame", "ConsoleModeMM_MapPlayerPin", mapTilesContainer)
    playerPin:SetWidth(26)
    playerPin:SetHeight(26)
    playerPin:SetFrameLevel(mapTilesContainer:GetFrameLevel() + 5)
    local pTex = playerPin:CreateTexture(nil, "OVERLAY")
    pTex:SetAllPoints(playerPin)
    pTex:SetTexture("Interface\\Minimap\\MinimapArrow")
    playerPin.texture = pTex
    mapCanvas.playerPin = playerPin

    -- Interações de Zoom por Roda do Mouse e Pan por Clique e Arraste (Estilo Carbonite)
    mapScrollFrame:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            MainMenu:MapZoomStep(1)
        else
            MainMenu:MapZoomStep(-1)
        end
    end)

    mapScrollFrame:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" or arg1 == "RightButton" then
            mapCanvas.isDragging = true
            local curX, curY = GetCursorPosition()
            mapCanvas.dragStartX = curX
            mapCanvas.dragStartY = curY
            mapCanvas.dragStartPanX = mapCanvas.panX or 0
            mapCanvas.dragStartPanY = mapCanvas.panY or 0
        end
    end)

    mapScrollFrame:SetScript("OnMouseUp", function()
        mapCanvas.isDragging = false
    end)

    -- Script para recalcular escala e carregar mapa assim que a janela é exibida ou redimensionada
    mapCanvas:SetScript("OnSizeChanged", function()
        if MainMenu and MainMenu.UpdateMapLayout then
            MainMenu:UpdateMapLayout(this)
            MainMenu:UpdateMapTextures(this)
            MainMenu:UpdateMapOverlays(this)
            MainMenu:UpdateMapPlayerPosition(this)
        end
    end)

    mapCanvas:SetScript("OnShow", function()
        if MainMenu and MainMenu.UpdateMapLayout then
            MainMenu:UpdateMapLayout(this)
            MainMenu:UpdateMapTextures(this)
            MainMenu:UpdateMapOverlays(this)
            MainMenu:UpdateMapPlayerPosition(this)
        end
    end)

    -- Loop de Atualização Contínua em Tempo Real do GPS, Rotação e Arraste do Mapa
    mapCanvas.elapsed = 0
    mapCanvas:SetScript("OnUpdate", function()
        -- 1. Movimentação por Arraste do Mouse com direção 1:1 natural e margem ampla
        if this.isDragging then
            local curX, curY = GetCursorPosition()
            local uiscale = UIParent:GetEffectiveScale() or 1.0
            local deltaX = (curX - (this.dragStartX or curX)) / uiscale
            local deltaY = (curY - (this.dragStartY or curY)) / uiscale
            local container = this.tilesContainer
            local canvasW = this:GetWidth() or 500
            local canvasH = this:GetHeight() or 340
            local totalW = (container and container:GetWidth()) or canvasW
            local totalH = (container and container:GetHeight()) or canvasH
            local maxPanX = math.max(0, (totalW - canvasW) / 2 + (canvasW * 0.45))
            local maxPanY = math.max(0, (totalH - canvasH) / 2 + (canvasH * 0.45))

            this.panX = math.max(-maxPanX, math.min(maxPanX, (this.dragStartPanX or 0) + deltaX))
            this.panY = math.max(-maxPanY, math.min(maxPanY, (this.dragStartPanY or 0) + deltaY))

            if container then
                container:ClearAllPoints()
                container:SetPoint("CENTER", this, "CENTER", this.panX, this.panY)
            end
        end

        -- 2. Movimentação suave contínua por Alavanca Analógica / D-Pad / WASD (L-Stick)
        local stickX = MainMenu.stickPanX or 0
        local stickY = MainMenu.stickPanY or 0
        if stickX ~= 0 or stickY ~= 0 then
            local speed = 480 -- pixels por segundo
            local dt = arg1 or 0.016
            if dt > 0.1 then dt = 0.016 end
            local dx = stickX * speed * dt
            local dy = stickY * speed * dt
            MainMenu:MapPan(dx, dy)
        end

        -- 3. Atualização suave da posição e rotação do jogador (30 FPS)
        this.elapsed = (this.elapsed or 0) + (arg1 or 0.016)
        if this.elapsed >= 0.033 then
            this.elapsed = 0
            if MainMenu and MainMenu.UpdateMapPlayerPosition then
                MainMenu:UpdateMapPlayerPosition(this)
            end
            if MainMenu and not MainMenu.mapShowingQuestZone then
                local curZone = (GetZoneText and GetZoneText()) or ""
                if curZone ~= "" and curZone ~= MainMenu.lastZoneText then
                    MainMenu.lastZoneText = curZone
                    if SetMapToCurrentZone then SetMapToCurrentZone() end
                    MainMenu:UpdateMapTextures(this)
                    MainMenu:UpdateMapOverlays(this)
                end
            end
        end
    end)

    -- Placeholder visual do Mapa (fallback se mapa não carregar)
    local mapPlaceholder = mapCanvas:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mapPlaceholder:SetPoint("CENTER", mapCanvas, "CENTER", 0, 10)
    MainMenu:ApplyFont(mapPlaceholder, CFG.Fonts.titleFontFile, 14)
    mapPlaceholder:SetText("|cffe09a15[ MAPA MUNDI & REGIÃO ]|r\n\n|cffaaaaaaCarregando texturas da zona...|r")
    mapPlaceholder:Hide()
    mapPanel.placeholder = mapPlaceholder

    -- Rodapé do Mapa com Dicas de Navegação
    local mapFooter = CreateFrame("Frame", nil, mapPanel)
    mapFooter:SetHeight(22)
    mapFooter:SetPoint("BOTTOMLEFT", mapPanel, "BOTTOMLEFT", 6, 4)
    mapFooter:SetPoint("BOTTOMRIGHT", mapPanel, "BOTTOMRIGHT", -6, 4)

    local mapHintText = mapFooter:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    mapHintText:SetPoint("CENTER", mapFooter, "CENTER", 0, 0)
    MainMenu:ApplyFont(mapHintText, CFG.Fonts.subFontFile, 11)
    mapHintText:SetText("|cff888888[LT] Zoom Out  •  [RT] Zoom In  •  [L-Stick / Drag] Mover Mapa Livre|r")
    mapPanel.hintText = mapHintText

    -- Botão VOLTAR (canto inferior direito do mapa, visível quando zona diferente da atual)
    local backButton = CreateFrame("Button", "ConsoleModeMM_MapBackButton", mapPanel, "UIPanelButtonTemplate")
    backButton:SetWidth(70)
    backButton:SetHeight(22)
    backButton:SetPoint("BOTTOMRIGHT", mapPanel, "BOTTOMRIGHT", -12, 30)
    if backButton.SetBackdrop then
        backButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        backButton:SetBackdropColor(0.08, 0.08, 0.12, 0.9)
        backButton:SetBackdropBorderColor(0.8, 0.65, 0.15, 0.8)
    end
    local btFont = backButton:GetFontString()
    if btFont and CFG.Fonts and CFG.Fonts.subFontFile then
        btFont:SetFont(CFG.Fonts.subFontFile, 11)
    end
    if backButton.SetText then backButton:SetText("|cffe09a15VOLTAR|r") end
    if backButton.SetHighlightTextColor then backButton:SetHighlightTextColor(1.0, 0.82, 0.0, 1.0) end
    if backButton.SetTextColor then backButton:SetTextColor(0.95, 0.75, 0.12, 1.0) end
    backButton:SetScript("OnClick", function()
        MainMenu:ResetMapToPlayer()
        if MainMenu.UpdateQuestsPage then MainMenu:UpdateQuestsPage() end
    end)
    backButton:Hide()
    mapPanel.backButton = backButton

    -- Card Fixo de Detalhes da Missão Selecionada (Parte Inferior - 150px)
    local detailCard = CreateFrame("Frame", "ConsoleModeMM_QuestDetailCard", questPanel)
    detailCard:SetHeight(150)
    detailCard:SetPoint("BOTTOMLEFT", questPanel, "BOTTOMLEFT", 0, 0)
    detailCard:SetPoint("BOTTOMRIGHT", questPanel, "BOTTOMRIGHT", 0, 0)
    questPanel.detailCard = detailCard

    local detailBg = detailCard:CreateTexture(nil, "BACKGROUND")
    detailBg:SetAllPoints(detailCard)
    detailBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    detailBg:SetVertexColor(0.03, 0.03, 0.03, 0.85)

    local detailBorder = CreateFrame("Frame", nil, detailCard)
    detailBorder:SetAllPoints(detailCard)
    local dbTop = detailBorder:CreateTexture(nil, "OVERLAY")
    dbTop:SetHeight(1)
    dbTop:SetPoint("TOPLEFT", detailBorder, "TOPLEFT", 0, 0)
    dbTop:SetPoint("TOPRIGHT", detailBorder, "TOPRIGHT", 0, 0)
    dbTop:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    dbTop:SetVertexColor(0.5, 0.4, 0.3, 0.6)

    local detailTitle = detailCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailTitle:SetPoint("TOPLEFT", detailCard, "TOPLEFT", 10, -8)
    detailTitle:SetPoint("RIGHT", detailCard, "RIGHT", -10, 0)
    detailTitle:SetJustifyH("LEFT")
    MainMenu:ApplyFont(detailTitle, CFG.Fonts.titleFontFile, 13)
    detailTitle:SetText("|cffe09a15Detalhes da Missão|r")
    detailCard.title = detailTitle

    local detailObjectives = detailCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detailObjectives:SetPoint("TOPLEFT", detailTitle, "BOTTOMLEFT", 0, -4)
    detailObjectives:SetPoint("RIGHT", detailCard, "RIGHT", -10, 0)
    detailObjectives:SetJustifyH("LEFT")
    MainMenu:ApplyFont(detailObjectives, CFG.Fonts.bodyFontFile, 11)
    detailObjectives:SetText("|cffaaaaaaSelecione uma missão na lista acima.|r")
    detailCard.objectives = detailObjectives

    -- Recompensas: Moedas, XP e Itens
    local rewardsFrame = CreateFrame("Frame", nil, detailCard)
    rewardsFrame:SetHeight(26)
    rewardsFrame:SetPoint("BOTTOMLEFT", detailCard, "BOTTOMLEFT", 10, 22)
    rewardsFrame:SetPoint("BOTTOMRIGHT", detailCard, "BOTTOMRIGHT", -10, 22)
    detailCard.rewardsFrame = rewardsFrame

    local moneyText = rewardsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    moneyText:SetPoint("LEFT", rewardsFrame, "LEFT", 0, 0)
    MainMenu:ApplyFont(moneyText, CFG.Fonts.subFontFile, 11)
    detailCard.money = moneyText

    local rewardSlots = {}
    for s = 1, 4 do
        local slot = CreateFrame("Button", "ConsoleModeMM_QuestRewardSlot" .. s, rewardsFrame)
        slot:SetWidth(22)
        slot:SetHeight(22)
        slot:SetPoint("RIGHT", rewardsFrame, "RIGHT", -((4 - s) * 26), 0)

        local sIcon = slot:CreateTexture(nil, "ARTWORK")
        sIcon:SetAllPoints(slot)
        slot.icon = sIcon

        local sBorder = slot:CreateTexture(nil, "OVERLAY")
        sBorder:SetAllPoints(slot)
        sBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        sBorder:SetBlendMode("ADD")
        slot.border = sBorder

        local sCount = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sCount:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 2, 2)
        MainMenu:ApplyFont(sCount, CFG.Fonts.subFontFile, 9)
        slot.count = sCount

        slot:SetScript("OnEnter", function()
            if this.rewardType and this.rewardIndex then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                if this.rewardType == "choice" then
                    GameTooltip:SetQuestLogItem("choice", this.rewardIndex)
                else
                    GameTooltip:SetQuestLogItem("reward", this.rewardIndex)
                end
                GameTooltip:Show()
            end
        end)

        slot:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        slot:Hide()
        rewardSlots[s] = slot
    end
    detailCard.rewardSlots = rewardSlots

    local detailFooter = detailCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detailFooter:SetPoint("BOTTOMLEFT", detailCard, "BOTTOMLEFT", 10, 5)
    MainMenu:ApplyFont(detailFooter, CFG.Fonts.subFontFile, 10)
    detailFooter:SetText("|cff888888(A) Ver no Mapa  •  (X) Rastrear no HUD  •  (Y) Ações|r")
    detailCard.footer = detailFooter

    -- Container da Lista de Missões (Parte Superior)
    local listContainer = CreateFrame("Frame", "ConsoleModeMM_QuestListContainer", questPanel)
    listContainer:SetPoint("TOPLEFT", questPanel, "TOPLEFT", 0, 0)
    listContainer:SetPoint("BOTTOMRIGHT", detailCard, "TOPRIGHT", 0, 6)
    listContainer:EnableMouseWheel(true)
    questPanel.listContainer = listContainer

    local listBg = listContainer:CreateTexture(nil, "BACKGROUND")
    listBg:SetAllPoints(listContainer)
    listBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    listBg:SetVertexColor(0.02, 0.02, 0.02, 0.50)

    listContainer:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            MainMenu:NavigateQuest(-1)
        else
            MainMenu:NavigateQuest(1)
        end
    end)

    local emptyText = listContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptyText:SetPoint("CENTER", listContainer, "CENTER", 0, 0)
    MainMenu:ApplyFont(emptyText, CFG.Fonts.titleFontFile, 13)
    emptyText:SetText("|cffaaaaaaNenhuma missão ativa no diário.|r")
    emptyText:Hide()
    questPanel.emptyText = emptyText

    questPanel.questButtons = {}
    pageQuests.isInitialized = true
end

local function GetQuestLevelColor(level)
    if not level or level <= 0 then return 0.8, 0.8, 0.8 end
    local playerLevel = UnitLevel("player") or 1
    local diff = level - playerLevel
    if diff >= 5 then
        return 1.0, 0.1, 0.1 -- Vermelho (Muito difícil)
    elseif diff >= 3 then
        return 1.0, 0.5, 0.1 -- Laranja (Difícil)
    elseif diff >= -2 then
        return 1.0, 0.85, 0.1 -- Amarelo (Nível atual)
    elseif diff >= -4 then
        return 0.2, 0.9, 0.2 -- Verde (Fácil)
    else
        return 0.5, 0.5, 0.5 -- Cinza (Trivial)
    end
end

function MainMenu:CreateQuestListButton(parent, idx)
    local btn = CreateFrame("Button", "ConsoleModeMM_QuestBtn" .. idx, parent)
    btn:SetHeight(24)
    btn:SetWidth(272)
    btn:SetFrameLevel(parent:GetFrameLevel() + 2)

    local highlight = btn:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints(btn)
    highlight:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    highlight:SetVertexColor(0.88, 0.60, 0.08, 0.35)
    highlight:Hide()
    btn.highlight = highlight

    local headerBg = btn:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(btn)
    headerBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    headerBg:SetVertexColor(0.20, 0.15, 0.08, 0.65)
    headerBg:Hide()
    btn.headerBg = headerBg

    local tagText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tagText:SetPoint("LEFT", btn, "LEFT", 4, 0)
    tagText:SetWidth(38)
    tagText:SetHeight(18)
    tagText:SetJustifyH("LEFT")
    MainMenu:ApplyFont(tagText, CFG.Fonts.subFontFile, 11)
    btn.tagText = tagText

    local statusText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    statusText:SetWidth(60)
    statusText:SetHeight(18)
    statusText:SetJustifyH("RIGHT")
    MainMenu:ApplyFont(statusText, CFG.Fonts.subFontFile, 10)
    btn.statusText = statusText

    local trackIcon = btn:CreateTexture(nil, "OVERLAY")
    trackIcon:SetWidth(12)
    trackIcon:SetHeight(12)
    trackIcon:SetPoint("RIGHT", statusText, "LEFT", -2, 0)
    trackIcon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
    trackIcon:Hide()
    btn.trackIcon = trackIcon

    local titleText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", tagText, "RIGHT", 2, 0)
    titleText:SetPoint("RIGHT", trackIcon, "LEFT", -2, 0)
    titleText:SetHeight(18)
    titleText:SetJustifyH("LEFT")
    MainMenu:ApplyFont(titleText, CFG.Fonts.bodyFontFile, 11)
    btn.titleText = titleText

    btn:SetScript("OnEnter", function()
        if not this.isHeader then
            this.highlight:Show()
            this.highlight:SetVertexColor(0.88, 0.60, 0.08, 0.20)
        end
    end)

    btn:SetScript("OnLeave", function()
        local curSelected = (ConsoleMode and ConsoleMode.mainMenu and ConsoleMode.mainMenu.selectedQuestIndex) or 0
        if this.questLogIndex ~= curSelected or this.isHeader then
            this.highlight:Hide()
        else
            this.highlight:Show()
            this.highlight:SetVertexColor(0.88, 0.60, 0.08, 0.40)
        end
    end)

    btn:SetScript("OnClick", function()
        if not this.isHeader and this.questLogIndex then
            MainMenu:SelectQuest(this.questLogIndex, false)
            MainMenu:UpdateQuestsPage()
            if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
        end
    end)

    return btn
end

function MainMenu:UpdateQuestsPage()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageQuests = self.tabContainer.pages["QUESTS"]
    if not pageQuests then return end

    self:SetupQuestsPage(pageQuests)

    local numEntries, numQuests = 0, 0
    if GetNumQuestLogEntries then
        numEntries, numQuests = GetNumQuestLogEntries()
    end
    numEntries = numEntries or 0
    numQuests = numQuests or 0
    if numQuests == 0 and numEntries > 0 then
        numQuests = numEntries
    end

    if pageQuests.questCountText then
        pageQuests.questCountText:SetText(string.format("|cffaaaaaaMissões: |cffffffff%d / 20|r", numQuests))
    end

    -- Renderiza e atualiza os 12 tiles dinâmicos, overlays e pin do jogador (Etapas 9.2, 9.3, 9.4)
    if pageQuests.mapPanel and pageQuests.mapPanel.canvas then
        self:UpdateMapLayout(pageQuests.mapPanel.canvas)
        self:UpdateMapTextures(pageQuests.mapPanel.canvas)
        self:UpdateMapOverlays(pageQuests.mapPanel.canvas)
        self:UpdateMapPlayerPosition(pageQuests.mapPanel.canvas)
    end

    -- Atualiza informações do Título da Zona / Nível do Mapa
    if pageQuests.mapPanel and pageQuests.mapPanel.zoneTitle then
        local titleText = "Azeroth"

        if self.mapShowingQuestZone and self.mapZoneName then
            titleText = self.mapZoneName
        else
            local currentZone = (GetCurrentMapZone and GetCurrentMapZone()) or 0
            local currentCont = (GetCurrentMapContinent and GetCurrentMapContinent()) or 0

            if currentCont == 0 then
                titleText = "Azeroth (Mundo)"
            elseif currentZone == 0 then
                if currentCont == 1 then
                    titleText = "Kalimdor (Continente)"
                elseif currentCont == 2 then
                    titleText = "Reinos do Leste (Continente)"
                else
                    titleText = "Continente"
                end
            else
                local zoneName = (GetZoneText and GetZoneText()) or (GetSubZoneText and GetSubZoneText()) or "Azeroth"
                if zoneName == "" then zoneName = "Azeroth" end
                titleText = zoneName
            end
        end

        pageQuests.mapPanel.zoneTitle:SetText(string.format("|cffffffff%s|r", titleText))
    end

    local questPanel = pageQuests.questPanel
    if not questPanel or not questPanel.listContainer then return end

    -- Coleta todas as entradas válidas do QuestLog
    local entries = {}
    for i = 1, numEntries do
        local questTitle, level, questTag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i)
        if questTitle and questTitle ~= "" then
            table.insert(entries, {
                index = i,
                title = questTitle,
                level = level,
                tag = questTag,
                isHeader = isHeader,
                isComplete = isComplete,
            })
        end
    end

    local totalItems = table.getn(entries)
    local maxVisible = 10
    local offset = questPanel.questOffset or 0
    if offset > math.max(0, totalItems - maxVisible) then
        offset = math.max(0, totalItems - maxVisible)
        questPanel.questOffset = offset
    end

    local questButtons = questPanel.questButtons
    local curY = 4
    local buttonHeight = 24
    local gapY = 2
    local firstSelectableIndex = nil
    local selectedFound = false
    local currentSelected = questPanel.selectedQuestIndex

    for slot = 1, maxVisible do
        local itemData = entries[slot + offset]
        local btn = questButtons[slot]
        if not btn then
            btn = MainMenu:CreateQuestListButton(questPanel.listContainer, slot)
            questButtons[slot] = btn
        end

        if itemData then
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", questPanel.listContainer, "TOPLEFT", 4, -curY)
            btn:SetWidth(questPanel.listContainer:GetWidth() > 0 and (questPanel.listContainer:GetWidth() - 8) or 272)
            btn:SetHeight(buttonHeight)
            btn.questLogIndex = itemData.index
            btn.isHeader = itemData.isHeader

            if itemData.isHeader then
                btn:Disable()
                btn.headerBg:Show()
                btn.highlight:Hide()
                btn.tagText:SetText("")
                btn.titleText:SetText("|cffe09a15[ " .. itemData.title .. " ]|r")
                btn.titleText:ClearAllPoints()
                btn.titleText:SetPoint("LEFT", btn, "LEFT", 8, 0)
                btn.titleText:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
                btn.statusText:SetText("")
                btn.trackIcon:Hide()
            else
                btn:Enable()
                btn.headerBg:Hide()
                if not firstSelectableIndex then firstSelectableIndex = itemData.index end
                if currentSelected == itemData.index then selectedFound = true end

                -- Tag de Nível e Dificuldade
                local r, g, b = GetQuestLevelColor(itemData.level)
                local tagStr = ""
                if itemData.tag == "ELITE" then
                    tagStr = string.format("|cff%02x%02x%02x[%d+]|r", r*255, g*255, b*255, itemData.level or 0)
                elseif itemData.tag == "DUNGEON" then
                    tagStr = string.format("|cff%02x%02x%02x[%dD]|r", r*255, g*255, b*255, itemData.level or 0)
                elseif itemData.tag == "RAID" then
                    tagStr = string.format("|cff%02x%02x%02x[%dR]|r", r*255, g*255, b*255, itemData.level or 0)
                elseif itemData.level and itemData.level > 0 then
                    tagStr = string.format("|cff%02x%02x%02x[%d]|r", r*255, g*255, b*255, itemData.level)
                end
                btn.tagText:SetText(tagStr)

                btn.titleText:ClearAllPoints()
                btn.titleText:SetPoint("LEFT", btn.tagText, "RIGHT", 2, 0)
                btn.titleText:SetPoint("RIGHT", btn.trackIcon, "LEFT", -2, 0)
                btn.titleText:SetText(itemData.title)

                -- Status de Conclusão / Progresso
                if itemData.isComplete and itemData.isComplete > 0 then
                    btn.statusText:SetText("|cff00ff00(Completa)|r")
                elseif itemData.isComplete and itemData.isComplete < 0 then
                    btn.statusText:SetText("|cffff2020(Falhou)|r")
                else
                    local numObj = (GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(itemData.index)) or 0
                    local doneCount = 0
                    for obj = 1, numObj do
                        local _, _, isDone = GetQuestLogLeaderBoard(obj, itemData.index)
                        if isDone then doneCount = doneCount + 1 end
                    end
                    if numObj > 0 then
                        btn.statusText:SetText(string.format("|cffffcc00[%d/%d]|r", doneCount, numObj))
                    else
                        btn.statusText:SetText("")
                    end
                end

                -- Ícone de rastreamento no HUD
                if IsQuestWatched and IsQuestWatched(itemData.index) then
                    btn.trackIcon:Show()
                else
                    btn.trackIcon:Hide()
                end

                if currentSelected == itemData.index then
                    btn.highlight:Show()
                    btn.highlight:SetVertexColor(0.88, 0.60, 0.08, 0.35)
                else
                    btn.highlight:Hide()
                end
            end

            btn:Show()
            curY = curY + buttonHeight + gapY
        else
            btn:Hide()
        end
    end

    if totalItems == 0 then
        if questPanel.emptyText then questPanel.emptyText:Show() end
        if questPanel.detailCard then questPanel.detailCard:Hide() end
    else
        if questPanel.emptyText then questPanel.emptyText:Hide() end
        if questPanel.detailCard then questPanel.detailCard:Show() end

        local toSelect = (selectedFound and currentSelected) or firstSelectableIndex
        if toSelect then
            self:SelectQuest(toSelect, true)
        end
    end
end

-- ============================================================================
-- 7.6. ETAPA 9.6: SINERGIA DE MISSÕES - ZONA, RASTREAMENTO E AÇÕES
-- ============================================================================

function MainMenu:GetQuestZone(questLogIndex)
    if not questLogIndex or questLogIndex <= 0 then return nil end
    local numEntries = (GetNumQuestLogEntries and GetNumQuestLogEntries()) or 0
    local zoneName = nil
    for i = 1, numEntries do
        local title, level, questTag, isHeader = GetQuestLogTitle(i)
        if isHeader then
            zoneName = title
        end
        if i == questLogIndex then
            break
        end
    end
    return zoneName
end

function MainMenu:SwitchMapToZone(zoneName)
    if not zoneName or zoneName == "" then return false end
    for cont = 1, 4 do
        local zones = {GetMapZones(cont)}
        for zoneIdx, name in ipairs(zones) do
            if name == zoneName then
                SetMapZoom(cont, zoneIdx)
                local fileName = (GetMapInfo and GetMapInfo()) or zoneName
                self.mapContinent = cont
                self.mapZoneIdx = zoneIdx
                self.mapZoneName = zoneName
                self.mapFileName = fileName
                self.mapShowingQuestZone = true
                self:UpdateBackButton()
                return true
            end
        end
    end
    return false
end

function MainMenu:EnsureMapZone()
    if self.mapContinent and self.mapZoneIdx then
        SetMapZoom(self.mapContinent, self.mapZoneIdx)
    end
end

function MainMenu:GetCurrentMapFileName()
    if self.mapShowingQuestZone and self.mapFileName then
        return self.mapFileName
    end
    if SetMapToCurrentZone then SetMapToCurrentZone() end
    local file = (GetMapInfo and GetMapInfo()) or ""
    if file and file ~= "" and file ~= "Cosmic" and file ~= "Azeroth" then
        return file
    end
    local zt = (GetZoneText and GetZoneText()) or ""
    if zt ~= "" then
        return string.gsub(zt, " ", "")
    end
    return file or ""
end

function MainMenu:ResetMapToPlayer()
    if SetMapToCurrentZone then SetMapToCurrentZone() end
    self.mapShowingQuestZone = false
    self.mapContinent = nil
    self.mapZoneIdx = nil
    self.mapZoneName = nil
    self.mapFileName = nil
    self:UpdateBackButton()
end

function MainMenu:UpdateBackButton()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageQuests = self.tabContainer.pages["QUESTS"]
    if not pageQuests or not pageQuests.mapPanel or not pageQuests.mapPanel.backButton then return end
    local btn = pageQuests.mapPanel.backButton
    if self.mapShowingQuestZone then
        btn:Show()
    else
        btn:Hide()
    end
end

function MainMenu:FocusMapOnQuest(questLogIndex)
    local zoneName = self:GetQuestZone(questLogIndex)
    if zoneName then
        local playerZone = (GetZoneText and GetZoneText()) or ""
        if zoneName ~= playerZone then
            self.mapShowingQuestZone = true
        else
            self.mapShowingQuestZone = false
        end
        self:SwitchMapToZone(zoneName)
        self:UpdateBackButton()
    end
end

function MainMenu:ToggleQuestWatch(questLogIndex)
    if not questLogIndex or questLogIndex <= 0 then return end
    local numEntries = (GetNumQuestLogEntries and GetNumQuestLogEntries()) or 0
    if questLogIndex > numEntries then return end

    local title, level, questTag, isHeader = GetQuestLogTitle(questLogIndex)
    if isHeader then return end

    if IsQuestWatched and IsQuestWatched(questLogIndex) then
        if RemoveQuestWatch then
            RemoveQuestWatch(questLogIndex)
        end
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[Missões]|r Rastreamento removido: |cffffffff" .. (title or "?") .. "|r")
        end
    else
        local numWatches = (GetNumQuestWatches and GetNumQuestWatches()) or 0
        if numWatches >= 5 then
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[Missões]|r Limite de 5 missões rastreadas atingido.")
            end
            return
        end
        if AddQuestWatch then
            AddQuestWatch(questLogIndex)
        end
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[Missões]|r Rastreamento ativado: |cffffffff" .. (title or "?") .. "|r")
        end
    end

    if QuestWatch_Update then
        QuestWatch_Update()
    end

    self:UpdateQuestsPage()
end

function MainMenu:AbandonSelectedQuest()
    local questIndex = self.selectedQuestIndex
    if not questIndex or questIndex <= 0 then return end

    local title, level, questTag, isHeader = GetQuestLogTitle(questIndex)
    if isHeader then return end

    if SelectQuestLogEntry then
        SelectQuestLogEntry(questIndex)
    end

    if SetAbandonQuest then
        SetAbandonQuest()
    end

    local questName = (GetAbandonQuestName and GetAbandonQuestName()) or title or "_MISSÃO_"
    local items = (GetAbandonQuestItems and GetAbandonQuestItems()) or nil

    if items then
        StaticPopup_Hide("ABANDON_QUEST")
        StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", questName, items)
    else
        StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS")
        StaticPopup_Show("ABANDON_QUEST", questName)
    end
end

function MainMenu:ShareSelectedQuest()
    local questIndex = self.selectedQuestIndex
    if not questIndex or questIndex <= 0 then return end

    local title, level, questTag, isHeader = GetQuestLogTitle(questIndex)
    if isHeader then return end

    local numParty = (GetNumPartyMembers and GetNumPartyMembers()) or 0
    if numParty <= 0 then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[Missões]|r É necessário estar em um grupo para compartilhar missões.")
        end
        return
    end

    if SelectQuestLogEntry then
        SelectQuestLogEntry(questIndex)
    end

    local canShare = (GetQuestLogPushable and GetQuestLogPushable()) or false
    if not canShare then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[Missões]|r Esta missão não pode ser compartilhada.")
        end
        return
    end

    if QuestLogPushQuest then
        QuestLogPushQuest()
    end

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[Missões]|r Missão compartilhada: |cffffffff" .. (title or "?") .. "|r")
    end
end

function MainMenu:OpenQuestContextMenu(questLogIndex)
    if not questLogIndex or questLogIndex <= 0 then return end

    local title, level, questTag, isHeader = GetQuestLogTitle(questLogIndex)
    if isHeader then return end

    if CM.ui and CM.ui.contextMenu and CM.ui.contextMenu.OpenForQuest then
        CM.ui.contextMenu:OpenForQuest(questLogIndex, title)
    end
end

function MainMenu:SelectQuest(questLogIndex, suppressMapSwitch)
    if not questLogIndex or questLogIndex <= 0 then return end
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageQuests = self.tabContainer.pages["QUESTS"]
    if not pageQuests or not pageQuests.questPanel then return end

    local questPanel = pageQuests.questPanel
    questPanel.selectedQuestIndex = questLogIndex
    self.selectedQuestIndex = questLogIndex

    if questPanel.questButtons then
        for _, btn in ipairs(questPanel.questButtons) do
            if btn.questLogIndex == questLogIndex and not btn.isHeader then
                btn.highlight:Show()
                btn.highlight:SetVertexColor(0.88, 0.60, 0.08, 0.35)
            else
                btn.highlight:Hide()
            end
        end
    end

    if SelectQuestLogEntry then
        SelectQuestLogEntry(questLogIndex)
    end

    if not suppressMapSwitch then
        self:FocusMapOnQuest(questLogIndex)
    end

    local questTitle, level, questTag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(questLogIndex)
    local questDescription, questObjectives = GetQuestLogQuestText()
    local detailCard = questPanel.detailCard
    if not detailCard then return end

    local r, g, b = GetQuestLevelColor(level)
    local levelStr = (level and level > 0) and string.format("|cff%02x%02x%02x[%d]|r ", r*255, g*255, b*255, level) or ""
    detailCard.title:SetText(levelStr .. "|cffffffff" .. (questTitle or "Missão") .. "|r")

    -- Formata lista de objetivos
    local numObj = (GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(questLogIndex)) or 0
    local objStr = ""
    for j = 1, numObj do
        local text, itemType, isDone = GetQuestLogLeaderBoard(j, questLogIndex)
        if text and text ~= "" then
            local bullet = isDone and "|cff00ff00✔ |r" or "|cffffcc00- |r"
            local col = isDone and "|cff88cc88" or "|cffffffff"
            objStr = objStr .. bullet .. col .. text .. "|r\n"
        end
    end

    if objStr ~= "" then
        detailCard.objectives:SetText(objStr)
    elseif questObjectives and questObjectives ~= "" then
        detailCard.objectives:SetText("|cffcccccc" .. questObjectives .. "|r")
    elseif questDescription and questDescription ~= "" then
        detailCard.objectives:SetText("|cffaaaaaa" .. questDescription .. "|r")
    else
        detailCard.objectives:SetText("|cff888888Sem objetivos específicos.|r")
    end

    -- Recompensas em Dinheiro
    local money = (GetQuestLogRewardMoney and GetQuestLogRewardMoney()) or 0
    if money > 0 then
        local gold = math.floor(money / 10000)
        local silver = math.floor(math.mod(money, 10000) / 100)
        local copper = math.mod(money, 100)
        local moneyStr = "|cffaaaaaaRecompensa: |r"
        if gold > 0 then moneyStr = moneyStr .. string.format("|cffffd700%dg |r", gold) end
        if silver > 0 or gold > 0 then moneyStr = moneyStr .. string.format("|cffc7c7cf%ds |r", silver) end
        moneyStr = moneyStr .. string.format("|cffeda55f%dc|r", copper)
        detailCard.money:SetText(moneyStr)
        detailCard.money:Show()
    else
        detailCard.money:Hide()
    end

    -- Recompensas em Itens
    local numRewards = (GetNumQuestLogRewards and GetNumQuestLogRewards()) or 0
    local numChoices = (GetNumQuestLogChoices and GetNumQuestLogChoices()) or 0
    local rewardSlots = detailCard.rewardSlots

    local slotIdx = 1
    -- Itens fixos
    for r = 1, numRewards do
        if slotIdx <= 4 then
            local name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(r)
            local slot = rewardSlots[slotIdx]
            if slot and texture then
                slot.icon:SetTexture(texture)
                slot.count:SetText((numItems and numItems > 1) and tostring(numItems) or "")
                local qr, qg, qb = 1, 1, 1
                if quality and GetItemQualityColor then
                    qr, qg, qb = GetItemQualityColor(quality)
                end
                slot.border:SetVertexColor(qr, qg, qb, 0.9)
                slot.rewardType = "reward"
                slot.rewardIndex = r
                slot:Show()
                slotIdx = slotIdx + 1
            end
        end
    end

    -- Itens de escolha
    for c = 1, numChoices do
        if slotIdx <= 4 then
            local name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo(c)
            local slot = rewardSlots[slotIdx]
            if slot and texture then
                slot.icon:SetTexture(texture)
                slot.count:SetText((numItems and numItems > 1) and tostring(numItems) or "")
                local qr, qg, qb = 1, 1, 1
                if quality and GetItemQualityColor then
                    qr, qg, qb = GetItemQualityColor(quality)
                end
                slot.border:SetVertexColor(qr, qg, qb, 0.9)
                slot.rewardType = "choice"
                slot.rewardIndex = c
                slot:Show()
                slotIdx = slotIdx + 1
            end
        end
    end

    -- Esconde slots restantes
    for s = slotIdx, 4 do
        if rewardSlots[s] then rewardSlots[s]:Hide() end
    end
end

function MainMenu:NavigateQuest(delta)
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageQuests = self.tabContainer.pages["QUESTS"]
    if not pageQuests or not pageQuests.questPanel then return end

    local questPanel = pageQuests.questPanel
    local numEntries = (GetNumQuestLogEntries and GetNumQuestLogEntries()) or 0
    if numEntries == 0 then return end

    local selectable = {}
    local currentPos = 1
    for i = 1, numEntries do
        local questTitle, level, questTag, isHeader = GetQuestLogTitle(i)
        if questTitle and questTitle ~= "" and not isHeader then
            table.insert(selectable, i)
            if i == questPanel.selectedQuestIndex then
                currentPos = table.getn(selectable)
            end
        end
    end

    if table.getn(selectable) == 0 then return end

    local nextPos = currentPos + delta
    if nextPos < 1 then nextPos = table.getn(selectable)
    elseif nextPos > table.getn(selectable) then nextPos = 1 end

    local targetIndex = selectable[nextPos]
    if targetIndex then
        local maxVisible = 10
        local curOffset = questPanel.questOffset or 0
        if nextPos <= curOffset then
            questPanel.questOffset = math.max(0, nextPos - 1)
        elseif nextPos > curOffset + maxVisible then
            questPanel.questOffset = nextPos - maxVisible
        end

        self:SelectQuest(targetIndex, false)
        self:UpdateQuestsPage()
        if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
    end
end

function MainMenu:UpdateMapLayout(mapCanvas)
    if not mapCanvas or not mapCanvas.tilesContainer or not mapCanvas.tiles then return end

    local container = mapCanvas.tilesContainer
    local canvasW = mapCanvas:GetWidth() or 500
    local canvasH = mapCanvas:GetHeight() or 340

    -- Dimensões nativas do WorldMap da Blizzard no Vanilla (1002 x 668 px)
    local origW = 1002
    local origH = 668

    local baseScale = math.min(canvasW / origW, canvasH / origH)
    local zoom = mapCanvas.zoomFactor or 1.0
    local effectiveScale = baseScale * zoom

    local finalW = math.floor(origW * effectiveScale)
    local finalH = math.floor(origH * effectiveScale)

    container:SetWidth(finalW)
    container:SetHeight(finalH)
    mapCanvas.currentScale = effectiveScale

    -- Larguras das 4 colunas (256, 256, 256, 234 px escaladas com zoom)
    local colW = {
        math.floor(256 * effectiveScale),
        math.floor(256 * effectiveScale),
        math.floor(256 * effectiveScale),
        finalW - (math.floor(256 * effectiveScale) * 3)
    }

    -- Alturas das 3 linhas (256, 256, 156 px escaladas com zoom)
    local rowH = {
        math.floor(256 * effectiveScale),
        math.floor(256 * effectiveScale),
        finalH - (math.floor(256 * effectiveScale) * 2)
    }

    -- Posiciona cada um dos 12 tiles dentro da matriz
    local tiles = mapCanvas.tiles
    local curY = 0

    for row = 1, 3 do
        local curX = 0
        local h = rowH[row]
        local bottomCoord = (row == 3) and (156 / 256) or 1.0

        for col = 1, 4 do
            local idx = (row - 1) * 4 + col
            local w = colW[col]
            local rightCoord = (col == 4) and (234 / 256) or 1.0

            local tile = tiles[idx]
            if tile then
                tile:ClearAllPoints()
                tile:SetPoint("TOPLEFT", container, "TOPLEFT", curX, -curY)
                tile:SetWidth(w)
                tile:SetHeight(h)
                tile:SetTexCoord(0, rightCoord, 0, bottomCoord)
            end
            curX = curX + w
        end
        curY = curY + h
    end

    -- Limites amplos de pan com margens confortáveis (permite centralizar qualquer ponto da borda)
    local maxPanX = math.max(0, (finalW - canvasW) / 2 + (canvasW * 0.45))
    local maxPanY = math.max(0, (finalH - canvasH) / 2 + (canvasH * 0.45))

    if zoom <= 1.0 then
        mapCanvas.panX = 0
        mapCanvas.panY = 0
    else
        mapCanvas.panX = math.max(-maxPanX, math.min(maxPanX, mapCanvas.panX or 0))
        mapCanvas.panY = math.max(-maxPanY, math.min(maxPanY, mapCanvas.panY or 0))
    end

    container:ClearAllPoints()
    container:SetPoint("CENTER", mapCanvas, "CENTER", mapCanvas.panX or 0, mapCanvas.panY or 0)
end

function MainMenu:UpdateMapTextures(mapCanvas)
    if not mapCanvas or not mapCanvas.tiles then return end

    local mapFileName = self:GetCurrentMapFileName()
    
    -- Fallback inteligente caso a zona não retorne nome direto (ex: instâncias ou continentes)
    if not mapFileName or mapFileName == "" then
        local cont = (GetCurrentMapContinent and GetCurrentMapContinent()) or 0
        if cont == 1 then
            mapFileName = "Kalimdor"
        elseif cont == 2 then
            mapFileName = "EasternKingdoms"
        else
            mapFileName = "Cosmic"
        end
    end

    mapCanvas.currentMapFile = mapFileName
    local tiles = mapCanvas.tiles
    for i = 1, 12 do
        local tile = tiles[i]
        if tile then
            local texPath = "Interface\\WorldMap\\" .. mapFileName .. "\\" .. mapFileName .. i
            tile:SetTexture(texPath)
            local row = math.floor((i - 1) / 4) + 1
            local col = math.mod((i - 1), 4) + 1
            local rightCoord = (col == 4) and (234 / 256) or 1.0
            local bottomCoord = (row == 3) and (156 / 256) or 1.0
            tile:SetTexCoord(0, rightCoord, 0, bottomCoord)
            tile:Show()
        end
    end

    if mapCanvas:GetParent() and mapCanvas:GetParent().placeholder then
        mapCanvas:GetParent().placeholder:Hide()
    end
end

local function GetNextPowerOfTwo(val)
    local p = 16
    while p < val do
        p = p * 2
    end
    return p
end

local mapOverlayErrata = {
    ["Interface\\WorldMap\\Tirisfal\\BRIGHTWATERLAKE"] = { offsetX = 584 },
    ["Interface\\WorldMap\\Silverpine\\BERENSPERIL"] = { offsetY = 415 },
}

function MainMenu:UpdateMapOverlays(mapCanvas)
    if not mapCanvas or not mapCanvas.tilesContainer or not mapCanvas.overlays then return end

    self:EnsureMapZone()
    local container = mapCanvas.tilesContainer
    local scale = mapCanvas.currentScale or 0.5
    if scale <= 0 then scale = 0.5 end

    local mapFileName = mapCanvas.currentMapFile or self:GetCurrentMapFileName()
    local overlays = mapCanvas.overlays
    local totalPool = table.getn(overlays)
    local overlayPoolIdx = 1

    -- Identifica as áreas que o personagem já explorou fisicamente
    local alreadyknown = {}
    local numExplored = (GetNumMapOverlays and GetNumMapOverlays()) or 0
    for i = 1, numExplored do
        local textureName = GetMapOverlayInfo(i)
        if textureName and textureName ~= "" then
            alreadyknown[textureName] = true
        end
    end

    local overlayData = nil
    if mapFileName and mapFileName ~= "" then
        overlayData = (ConsoleMode and ConsoleMode.MapOverlayData and ConsoleMode.MapOverlayData[mapFileName])
            or (ShaguTweaks and ShaguTweaks.MapOverlayData and ShaguTweaks.MapOverlayData[mapFileName])
    end

    if overlayData and table.getn(overlayData) > 0 then
        -- Revelação Total do Mapa: Revela estradas, vilas e relevo sem Fog of War
        local prefix = "Interface\\WorldMap\\" .. mapFileName .. "\\"
        for _, hash in ipairs(overlayData) do
            local _, _, name, wStr, hStr, xStr, yStr = string.find(hash, "^([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)")
            if name and wStr and hStr and xStr and yStr then
                local textureWidth = tonumber(wStr) or 0
                local textureHeight = tonumber(hStr) or 0
                local offsetX = tonumber(xStr) or 0
                local offsetY = tonumber(yStr) or 0
                local baseTexPath = prefix .. name

                if mapOverlayErrata[baseTexPath] then
                    if mapOverlayErrata[baseTexPath].offsetX then offsetX = mapOverlayErrata[baseTexPath].offsetX end
                    if mapOverlayErrata[baseTexPath].offsetY then offsetY = mapOverlayErrata[baseTexPath].offsetY end
                end

                if textureWidth > 0 and textureHeight > 0 then
                    local numWide = math.ceil(textureWidth / 256)
                    local numHigh = math.ceil(textureHeight / 256)
                    local isExplored = alreadyknown[baseTexPath] or false

                    for j = 1, numHigh do
                        local texturePixelHeight, textureFileHeight
                        if j < numHigh then
                            texturePixelHeight, textureFileHeight = 256, 256
                        else
                            texturePixelHeight = math.mod(textureHeight, 256)
                            if texturePixelHeight == 0 then texturePixelHeight = 256 end
                            textureFileHeight = GetNextPowerOfTwo(texturePixelHeight)
                        end

                        for k = 1, numWide do
                            local texturePixelWidth, textureFileWidth
                            if k < numWide then
                                texturePixelWidth, textureFileWidth = 256, 256
                            else
                                texturePixelWidth = math.mod(textureWidth, 256)
                                if texturePixelWidth == 0 then texturePixelWidth = 256 end
                                textureFileWidth = GetNextPowerOfTwo(texturePixelWidth)
                            end

                            local tex = overlays[overlayPoolIdx]
                            if tex then
                                local texCoordX = texturePixelWidth / textureFileWidth
                                local texCoordY = texturePixelHeight / textureFileHeight

                                local posX = math.floor((offsetX + (256 * (k - 1))) * scale)
                                local posY = math.floor((offsetY + (256 * (j - 1))) * scale)

                                tex:ClearAllPoints()
                                tex:SetPoint("TOPLEFT", container, "TOPLEFT", posX, -posY)
                                tex:SetWidth(math.floor(texturePixelWidth * scale))
                                tex:SetHeight(math.floor(texturePixelHeight * scale))
                                tex:SetTexCoord(0, texCoordX, 0, texCoordY)
                                local textureIndex = ((j - 1) * numWide) + k
                                tex:SetTexture(baseTexPath .. textureIndex)

                                -- Áreas já exploradas = 100% de brilho; Áreas inexploradas = sombra nítida (0.50)
                                if isExplored then
                                    tex:SetVertexColor(1, 1, 1, 1)
                                else
                                    tex:SetVertexColor(0.50, 0.50, 0.50, 0.90)
                                end
                                tex:Show()

                                overlayPoolIdx = overlayPoolIdx + 1
                            end
                        end
                    end
                end
            end
        end
    else
        -- Fallback nativo
        for i = 1, numExplored do
            local textureName, textureWidth, textureHeight, offsetX, offsetY = GetMapOverlayInfo(i)
            if textureName and textureName ~= "" and textureWidth and textureHeight and textureWidth > 0 and textureHeight > 0 then
                local numWide = math.ceil(textureWidth / 256)
                local numHigh = math.ceil(textureHeight / 256)

                for j = 1, numHigh do
                    local texturePixelHeight, textureFileHeight
                    if j < numHigh then
                        texturePixelHeight, textureFileHeight = 256, 256
                    else
                        texturePixelHeight = math.mod(textureHeight, 256)
                        if texturePixelHeight == 0 then texturePixelHeight = 256 end
                        textureFileHeight = GetNextPowerOfTwo(texturePixelHeight)
                    end

                    for k = 1, numWide do
                        local texturePixelWidth, textureFileWidth
                        if k < numWide then
                            texturePixelWidth, textureFileWidth = 256, 256
                        else
                            texturePixelWidth = math.mod(textureWidth, 256)
                            if texturePixelWidth == 0 then texturePixelWidth = 256 end
                            textureFileWidth = GetNextPowerOfTwo(texturePixelWidth)
                        end

                        local tex = overlays[overlayPoolIdx]
                        if tex then
                            local texCoordX = texturePixelWidth / textureFileWidth
                            local texCoordY = texturePixelHeight / textureFileHeight

                            local posX = math.floor((offsetX + (256 * (k - 1))) * scale)
                            local posY = math.floor((offsetY + (256 * (j - 1))) * scale)

                            tex:ClearAllPoints()
                            tex:SetPoint("TOPLEFT", container, "TOPLEFT", posX, -posY)
                            tex:SetWidth(math.floor(texturePixelWidth * scale))
                            tex:SetHeight(math.floor(texturePixelHeight * scale))
                            tex:SetTexCoord(0, texCoordX, 0, texCoordY)
                            local textureIndex = ((j - 1) * numWide) + k
                            tex:SetTexture(textureName .. textureIndex)
                            tex:SetVertexColor(1, 1, 1, 1)
                            tex:Show()

                            overlayPoolIdx = overlayPoolIdx + 1
                        end
                    end
                end
            end
        end
    end

    -- Esconde texturas de overlay excedentes do pool
    for j = overlayPoolIdx, totalPool do
        if overlays[j] then
            overlays[j]:Hide()
        end
    end
end

-- Rotação trigonométrica de textura em 2D (WoW Vanilla 1.12)
local function RotateMapTexture(texture, angle)
    if not texture or not texture.SetTexCoord then return end
    local c = math.cos(angle)
    local s = math.sin(angle)
    local ulx = 0.5 + (-0.5) * c - (-0.5) * s
    local uly = 0.5 + (-0.5) * s + (-0.5) * c
    local llx = 0.5 + (-0.5) * c - ( 0.5) * s
    local lly = 0.5 + (-0.5) * s + ( 0.5) * c
    local urx = 0.5 + ( 0.5) * c - (-0.5) * s
    local ury = 0.5 + ( 0.5) * s + (-0.5) * c
    local lrx = 0.5 + ( 0.5) * c - ( 0.5) * s
    local lry = 0.5 + ( 0.5) * s + ( 0.5) * c
    texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

local minimapArrowModel = nil
local function GetPlayerFacingAngle()
    if GetPlayerFacing then
        local f = GetPlayerFacing()
        if f and f ~= 0 then return f end
    end
    if pfQuestCompat and pfQuestCompat.GetPlayerFacing then
        local f = pfQuestCompat.GetPlayerFacing()
        if f and f ~= 0 then return f end
    end
    if not minimapArrowModel and Minimap and Minimap.GetChildren then
        for _, child in ipairs({Minimap:GetChildren()}) do
            if child:IsObjectType("Model") and not child:GetName() then
                local m = child:GetModel()
                if m and string.find(string.lower(m), "interface\\minimap\\minimaparrow") then
                    minimapArrowModel = child
                    break
                end
            end
        end
    end
    if minimapArrowModel and minimapArrowModel.GetFacing then
        return minimapArrowModel:GetFacing() or 0
    end
    return 0
end

function MainMenu:UpdateMapPlayerPosition(mapCanvas)
    if not mapCanvas or not mapCanvas.tilesContainer or not mapCanvas.playerPin then return end

    local container = mapCanvas.tilesContainer
    local containerW = container:GetWidth() or 0
    local containerH = container:GetHeight() or 0

    if containerW <= 0 or containerH <= 0 then return end

    local isQuestView = self.mapShowingQuestZone and self.mapFileName

    local px, py = 0, 0
    if isQuestView then
        local curCont = (GetCurrentMapContinent and GetCurrentMapContinent()) or 0
        local curZone = (GetCurrentMapZone and GetCurrentMapZone()) or 0
        local playerZoneText = (GetZoneText and GetZoneText()) or ""
        if self.mapZoneName and playerZoneText ~= "" and self.mapZoneName == playerZoneText then
            if SetMapToCurrentZone then SetMapToCurrentZone() end
            if GetPlayerMapPosition then
                px, py = GetPlayerMapPosition("player")
            end
            self:EnsureMapZone()
        else
            if GetPlayerMapPosition then
                local tx, ty = GetPlayerMapPosition("player")
                if tx and ty and (tx > 0 or ty > 0) then
                    px, py = 0, 0
                else
                    px, py = 0, 0
                end
            end
            self:EnsureMapZone()
            px, py = 0, 0
        end
    else
        if SetMapToCurrentZone then SetMapToCurrentZone() end
        if GetPlayerMapPosition then
            px, py = GetPlayerMapPosition("player")
        end
    end

    local scale = mapCanvas.currentScale or ((containerW > 0 and containerW / 1002) or 0.5)
    local effW = 1002 * scale
    local effH = 668 * scale

    local playerPin = mapCanvas.playerPin
    if px and py and (px > 0 or py > 0) then
        local posX = px * effW
        local posY = -py * effH

        playerPin:ClearAllPoints()
        playerPin:SetPoint("CENTER", container, "TOPLEFT", posX, posY)

        local facing = GetPlayerFacingAngle()
        if playerPin.texture then
            RotateMapTexture(playerPin.texture, facing)
        end
        playerPin:Show()

        if mapCanvas:GetParent() and mapCanvas:GetParent().coordsText then
            mapCanvas:GetParent().coordsText:SetText(string.format("|cffe09a15GPS: |cffffffff%.1f, %.1f|r", px * 100, py * 100))
        end
    else
        playerPin:Hide()
        if mapCanvas:GetParent() and mapCanvas:GetParent().coordsText then
            if isQuestView then
                mapCanvas:GetParent().coordsText:SetText("|cff888888GPS: fora da zona visualizada|r")
            else
                mapCanvas:GetParent().coordsText:SetText("|cff888888GPS: Indisponível|r")
            end
        end
    end

    if mapCanvas.partyPins then
        local numParty = (GetNumPartyMembers and GetNumPartyMembers()) or 0
        for p = 1, 4 do
            local pin = mapCanvas.partyPins[p]
            if pin then
                if p <= numParty and GetPlayerMapPosition then
                    local pX, pY
                    if isQuestView then
                        pX, pY = 0, 0
                    else
                        pX, pY = GetPlayerMapPosition("party" .. p)
                    end
                    if pX and pY and (pX > 0 or pY > 0) then
                        pin:ClearAllPoints()
                        pin:SetPoint("CENTER", container, "TOPLEFT", pX * effW, -pY * effH)
                        pin:Show()
                    else
                        pin:Hide()
                    end
                else
                    pin:Hide()
                end
            end
        end
    end
end

-- ============================================================================
-- NAVEGAÇÃO DE ZOOM SUAVE E PAN (ESTILO CARBONITE)
-- ============================================================================

function MainMenu:MapZoomStep(delta)
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageQuests = self.tabContainer.pages["QUESTS"]
    if not pageQuests or not pageQuests.mapPanel or not pageQuests.mapPanel.canvas then return end

    local mapCanvas = pageQuests.mapPanel.canvas
    local curZoom = mapCanvas.zoomFactor or 1.0
    local step = (delta > 0) and 0.30 or -0.30
    local newZoom = curZoom + step

    if newZoom < 1.0 then
        newZoom = 1.0
    elseif newZoom > 3.5 then
        newZoom = 3.5
    end

    mapCanvas.zoomFactor = newZoom

    local canvasW = mapCanvas:GetWidth() or 500
    local canvasH = mapCanvas:GetHeight() or 340
    local origW = 1002
    local origH = 668
    local baseScale = math.min(canvasW / origW, canvasH / origH)
    local effectiveScale = baseScale * newZoom
    local finalW = math.floor(origW * effectiveScale)
    local finalH = math.floor(origH * effectiveScale)

    local maxPanX = math.max(0, (finalW - canvasW) / 2 + (canvasW * 0.45))
    local maxPanY = math.max(0, (finalH - canvasH) / 2 + (canvasH * 0.45))

    if newZoom <= 1.0 then
        mapCanvas.panX = 0
        mapCanvas.panY = 0
    elseif newZoom > curZoom and curZoom <= 1.05 then
        -- Primeiro Zoom In: Centraliza automaticamente na posição do jogador
        local px, py = 0, 0
        if GetPlayerMapPosition then
            if SetMapToCurrentZone then SetMapToCurrentZone() end
            px, py = GetPlayerMapPosition("player")
        end
        if px and py and (px > 0 or py > 0) then
            local targetPanX = (0.5 - px) * finalW
            local targetPanY = (py - 0.5) * finalH
            mapCanvas.panX = math.max(-maxPanX, math.min(maxPanX, targetPanX))
            mapCanvas.panY = math.max(-maxPanY, math.min(maxPanY, targetPanY))
        else
            mapCanvas.panX = 0
            mapCanvas.panY = 0
        end
    else
        mapCanvas.panX = math.max(-maxPanX, math.min(maxPanX, mapCanvas.panX or 0))
        mapCanvas.panY = math.max(-maxPanY, math.min(maxPanY, mapCanvas.panY or 0))
    end

    self:EnsureMapZone()
    self:UpdateMapLayout(mapCanvas)
    self:UpdateMapOverlays(mapCanvas)
    self:UpdateMapPlayerPosition(mapCanvas)
    PlaySound("igMainMenuOptionCheckBoxOn")
end

MainMenu.stickPanX = 0
MainMenu.stickPanY = 0

function MainMenu:OnStickPan(direction, keystate)
    local isDown = (keystate ~= "up")

    if direction == "UP" then
        self.stickPanY = isDown and -1 or 0
    elseif direction == "DOWN" then
        self.stickPanY = isDown and 1 or 0
    elseif direction == "LEFT" then
        self.stickPanX = isDown and 1 or 0
    elseif direction == "RIGHT" then
        self.stickPanX = isDown and -1 or 0
    end
end

function MainMenu:MapPan(dx, dy)
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageQuests = self.tabContainer.pages["QUESTS"]
    if not pageQuests or not pageQuests.mapPanel or not pageQuests.mapPanel.canvas then return end

    local mapCanvas = pageQuests.mapPanel.canvas
    local canvasW = mapCanvas:GetWidth() or 500
    local canvasH = mapCanvas:GetHeight() or 340
    local container = mapCanvas.tilesContainer
    local totalW = (container and container:GetWidth()) or canvasW
    local totalH = (container and container:GetHeight()) or canvasH

    local maxPanX = math.max(0, (totalW - canvasW) / 2 + (canvasW * 0.45))
    local maxPanY = math.max(0, (totalH - canvasH) / 2 + (canvasH * 0.45))

    if maxPanX <= 0 and maxPanY <= 0 then return end

    mapCanvas.panX = math.max(-maxPanX, math.min(maxPanX, (mapCanvas.panX or 0) + dx))
    mapCanvas.panY = math.max(-maxPanY, math.min(maxPanY, (mapCanvas.panY or 0) + dy))

    if container then
        container:ClearAllPoints()
        container:SetPoint("CENTER", mapCanvas, "CENTER", mapCanvas.panX, mapCanvas.panY)
    end
end

function MainMenu:CycleCategories(direction)
    local curTab = self.tabContainer and self.tabContainer.currentTab
    if curTab == "QUESTS" then
        if direction and direction < 0 then
            -- Zoom Out (LT)
            self:MapZoomStep(-1)
            return true
        else
            -- Zoom In (RT)
            self:MapZoomStep(1)
            return true
        end
    end
    return false
end

-- (UpdateQuestsPage definido acima, na seção 7.4)

-- ============================================================================
-- 7.3. CONFIGURAÇÃO DA ABA DE SISTEMA E CONFIGURAÇÕES (FASE 8 - ETAPA 8.1)
-- ============================================================================

function MainMenu:SetupSystemPage(pageSystem)
    if pageSystem.isInitialized then return end

    -- 1. Barra de Cabeçalho / Sub-Abas com [LT] e [RT]
    local headerBar = CreateFrame("Frame", "ConsoleModeMM_SystemHeader", pageSystem)
    headerBar:SetHeight(32)
    headerBar:SetPoint("TOPLEFT", pageSystem, "TOPLEFT", 0, 0)
    headerBar:SetPoint("TOPRIGHT", pageSystem, "TOPRIGHT", 0, 0)
    pageSystem.headerBar = headerBar

    -- Indicador RT à direita
    local r2Hint = headerBar:CreateTexture(nil, "OVERLAY")
    r2Hint:SetWidth(20)
    r2Hint:SetHeight(20)
    r2Hint:SetPoint("RIGHT", headerBar, "RIGHT", 0, 0)
    r2Hint:SetTexture(CFG.Icons.RT)
    pageSystem.r2Hint = r2Hint

    -- Botões das Sub-Abas: ancorados da direita para a esquerda
    local subButtons = {}
    local prevBtn = r2Hint
    pageSystem.currentSubTab = "GAME_MENU"

    local numSubTabs = table.getn(CFG.System.subTabs)
    for i = numSubTabs, 1, -1 do
        local tabData = CFG.System.subTabs[i]
        local subBtn = CreateFrame("Button", "ConsoleModeMM_SysSubTab_" .. tabData.id, headerBar)
        subBtn:SetHeight(24)

        local title = subBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("CENTER", subBtn, "CENTER", 0, 0)
        MainMenu:ApplyFont(title, CFG.Fonts.bodyFontFile, CFG.Fonts.bagCatSize or 14)
        title:SetText(tabData.name)
        subBtn.title = title
        subBtn.subTabData = tabData

        local txtW = math.floor(title:GetStringWidth() or 80)
        if txtW < 50 then txtW = 50 end
        subBtn:SetWidth(txtW + 16)

        subBtn:SetPoint("RIGHT", prevBtn, "LEFT", -6, 0)

        subBtn:SetScript("OnClick", function()
            MainMenu:SelectSystemSubTab(this.subTabData.id)
            if CFG.Audio.soundItemSelect then PlaySound(CFG.Audio.soundItemSelect) end
        end)

        table.insert(subButtons, subBtn)
        prevBtn = subBtn
    end
    pageSystem.subButtons = subButtons

    -- Indicador LT à esquerda da primeira sub-aba
    local l2Hint = headerBar:CreateTexture(nil, "OVERLAY")
    l2Hint:SetWidth(20)
    l2Hint:SetHeight(20)
    l2Hint:SetPoint("RIGHT", prevBtn, "LEFT", -6, 0)
    l2Hint:SetTexture(CFG.Icons.LT)
    pageSystem.l2Hint = l2Hint

    -- Linha Divisória abaixo do cabeçalho de sub-abas
    local hDiv = headerBar:CreateTexture(nil, "ARTWORK")
    hDiv:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    hDiv:SetHeight(1)
    hDiv:SetPoint("BOTTOMLEFT", headerBar, "BOTTOMLEFT", 0, -2)
    hDiv:SetPoint("BOTTOMRIGHT", headerBar, "BOTTOMRIGHT", 0, -2)
    hDiv:SetVertexColor(0.5, 0.4, 0.3, 0.4)

    -- 2. Container de Conteúdo das Sub-Abas
    local subContent = CreateFrame("Frame", "ConsoleModeMM_SystemSubContent", pageSystem)
    subContent:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -8)
    subContent:SetPoint("BOTTOMRIGHT", pageSystem, "BOTTOMRIGHT", 0, 0)
    pageSystem.subContent = subContent

    -- Sub-Página 1: Opções do Jogo & Menus de Sistema (Etapa 8.2 / 8.3)
    local subPageGameMenu = CreateFrame("Frame", "ConsoleModeMM_SubPage_GAME_MENU", subContent)
    subPageGameMenu:SetAllPoints(subContent)
    pageSystem.subPageGameMenu = subPageGameMenu

    local gmHeader = subPageGameMenu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gmHeader:SetPoint("TOPLEFT", subPageGameMenu, "TOPLEFT", 12, -8)
    MainMenu:ApplyFont(gmHeader, CFG.Fonts.titleFontFile, 15, "")
    gmHeader:SetText("|cffe09a15[ MENUS DO SISTEMA & ADDONS DETECTADOS ]|r")
    subPageGameMenu.header = gmHeader

    local gmSubText = subPageGameMenu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    gmSubText:SetPoint("TOPLEFT", gmHeader, "BOTTOMLEFT", 0, -4)
    MainMenu:ApplyFont(gmSubText, CFG.Fonts.subFontFile, 12, "")
    gmSubText:SetText("|cffaaaaaaVarredura dinâmica de botões nativos e de addons|r")
    subPageGameMenu.subText = gmSubText

    local gmListContainer = CreateFrame("Frame", "ConsoleModeMM_GMListContainer", subPageGameMenu)
    gmListContainer:SetPoint("TOPLEFT", gmSubText, "BOTTOMLEFT", 0, -10)
    gmListContainer:SetPoint("BOTTOMRIGHT", subPageGameMenu, "BOTTOMRIGHT", -12, 10)
    subPageGameMenu.listContainer = gmListContainer
    subPageGameMenu.rows = {}

    -- Sub-Página 2: Configurações do ConsoleMode (Etapa 8.4)
    local subPageAddonCfg = CreateFrame("Frame", "ConsoleModeMM_SubPage_ADDON_CFG", subContent)
    subPageAddonCfg:SetAllPoints(subContent)
    pageSystem.subPageAddonCfg = subPageAddonCfg

    pageSystem.isInitialized = true
end

function MainMenu:CleanButtonText(text, buttonName)
    if not text then return "" end

    local clean = string.gsub(text, "\r", "")

    -- Remove códigos de cor pré-existentes da Blizzard ou Addons (ex: |cff00ff00...|r)
    clean = string.gsub(clean, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")

    -- Tratamento especial para addons como SuperMacro que empilham letras verticalmente
    if buttonName and string.find(string.lower(buttonName), "supermacro") then
        return "SuperMacro"
    end

    if string.find(clean, "\n") then
        -- Se todas as linhas individuais tiverem até 2 caracteres (ex: M\nA\nC\nR\nO\nS), junta direto
        local isSingleCharVertical = true
        for line in string.gfind(clean, "[^\n]+") do
            if string.len(line) > 2 then
                isSingleCharVertical = false
            end
        end

        if isSingleCharVertical then
            clean = string.gsub(clean, "\n", "")
        else
            clean = string.gsub(clean, "\n", " ")
        end
    end

    -- Remove espaços extras nas extremidades
    clean = string.gsub(clean, "^%s+", "")
    clean = string.gsub(clean, "%s+$", "")

    -- Desambiguação de botões nativos que compartilham o mesmo texto genérico "Options"
    if buttonName == "GameMenuButtonOptions" and (clean == "Options" or clean == "OPTIONS") then
        clean = "Video Options"
    elseif buttonName == "GameMenuButtonUIOptions" and (clean == "Options" or clean == "OPTIONS") then
        clean = "Interface Options"
    elseif buttonName == "GameMenuButtonSoundOptions" and (clean == "Options" or clean == "OPTIONS") then
        clean = "Sound Options"
    end

    return clean
end

function MainMenu:ScanGameMenuButtons()
    local buttons = {}
    if not GameMenuFrame then return buttons end

    local children = { GameMenuFrame:GetChildren() }
    local n = table.getn(children)
    for i = 1, n do
        local child = children[i]
        if child and child.GetObjectType and child:GetObjectType() == "Button" then
            local text = child:GetText()
            local name = child:GetName() or ""
            if text and text ~= "" and name ~= "GameMenuFrameHeader" then
                local cleanText = MainMenu:CleanButtonText(text, name)
                if cleanText and cleanText ~= "" then
                    table.insert(buttons, {
                        frame = child,
                        name = name ~= "" and name or ("GameMenuChild" .. i),
                        text = cleanText,
                        rawText = text,
                        top = (child.GetTop and child:GetTop()) or (1000 - i),
                    })
                end
            end
        end
    end

    -- Ordena por posição vertical (de cima para baixo no GameMenu original)
    table.sort(buttons, function(a, b)
        if a.top and b.top and a.top ~= b.top then
            return a.top > b.top
        end
        return false
    end)

    return buttons
end

function MainMenu:UpdateGameMenuSubPage()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageSystem = self.tabContainer.pages["SYSTEM"]
    if not pageSystem or not pageSystem.subPageGameMenu then return end

    local subPage = pageSystem.subPageGameMenu
    local buttons = self:ScanGameMenuButtons()
    local count = table.getn(buttons)

    if subPage.subText then
        subPage.subText:SetText(string.format("|cffaaaaaaTotal de botões detectados: |cffffffff%d|r |cffaaaaaa(Blizzard + Addons)|r", count))
    end

    if not subPage.rows then subPage.rows = {} end

    local rowHeight = 24
    local rowGap = 3
    local startY = -4

    local bColor = CFG.System.badgeColor or "|cffe09a15"
    local tColor = CFG.System.itemTextColor or "|cffffffff"
    local fColor = CFG.System.frameNameColor or "|cff777777"

    for i = 1, count do
        local btnData = buttons[i]
        local row = subPage.rows[i]
        if not row then
            row = CreateFrame("Button", "ConsoleModeMM_GMBtn_" .. i, subPage.listContainer)
            row:SetHeight(rowHeight)
            row:SetPoint("LEFT", subPage.listContainer, "LEFT", 0, 0)
            row:SetPoint("RIGHT", subPage.listContainer, "RIGHT", 0, 0)

            -- Fundo translúcido com destaque visual
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(row)
            bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
            bg:SetVertexColor(0.0, 0.0, 0.0, 0.25)
            row.bg = bg

            -- Linha de destaque dourada à esquerda ao focar
            local highlightBar = row:CreateTexture(nil, "OVERLAY")
            highlightBar:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
            highlightBar:SetWidth(3)
            highlightBar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            highlightBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
            highlightBar:SetVertexColor(1.0, 0.85, 0.2, 0.95)
            highlightBar:Hide()
            row.highlightBar = highlightBar

            local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("LEFT", row, "LEFT", 12, 0)
            MainMenu:ApplyFont(title, CFG.Fonts.bodyFontFile, 14)
            row.title = title

            -- Eventos de foco / mouse hover
            row:SetScript("OnEnter", function()
                this.bg:SetVertexColor(1.0, 0.85, 0.2, 0.18)
                if this.highlightBar then this.highlightBar:Show() end
            end)

            row:SetScript("OnLeave", function()
                this.bg:SetVertexColor(0.0, 0.0, 0.0, 0.25)
                if this.highlightBar then this.highlightBar:Hide() end
            end)

            -- Ação OnClick (Etapa 8.3)
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row:SetScript("OnClick", function()
                if this.btnData and this.btnData.frame then
                    local targetBtn = this.btnData.frame
                    local targetName = this.btnData.name or ""
                    PlaySound("igMainMenuOptionCheckBoxOn")

                    MainMenu:Hide()

                    if targetName == "ConsoleModeMM_OpenConfigBtn" or targetName == "GameMenuButtonConsoleMode" then
                        if ConsoleMode.config and ConsoleMode.config.Show then
                            ConsoleMode.config:Show()
                        end
                    elseif targetName == "GameMenuButtonOptions" then
                        if OptionsFrame_Toggle then
                            OptionsFrame_Toggle()
                        elseif OptionsFrame then
                            ShowUIPanel(OptionsFrame)
                            if not OptionsFrame:IsVisible() then OptionsFrame:Show() end
                        elseif targetBtn.Click then
                            targetBtn:Click()
                        end
                    elseif targetName == "GameMenuButtonSoundOptions" then
                        if SoundOptionsFrame_Toggle then
                            SoundOptionsFrame_Toggle()
                        elseif SoundOptionsFrame then
                            ShowUIPanel(SoundOptionsFrame)
                            if not SoundOptionsFrame:IsVisible() then SoundOptionsFrame:Show() end
                        elseif targetBtn.Click then
                            targetBtn:Click()
                        end
                    elseif targetName == "GameMenuButtonUIOptions" then
                        if UIOptionsFrame_Toggle then
                            UIOptionsFrame_Toggle()
                        elseif UIOptionsFrame then
                            ShowUIPanel(UIOptionsFrame)
                            if not UIOptionsFrame:IsVisible() then UIOptionsFrame:Show() end
                        elseif targetBtn.Click then
                            targetBtn:Click()
                        end
                    elseif targetName == "GameMenuButtonKeybindings" then
                        if KeyBindingFrame_Toggle then
                            KeyBindingFrame_Toggle()
                        elseif KeyBindingFrame then
                            ShowUIPanel(KeyBindingFrame)
                            if not KeyBindingFrame:IsVisible() then KeyBindingFrame:Show() end
                        elseif targetBtn.Click then
                            targetBtn:Click()
                        end
                    elseif targetName == "GameMenuButtonMacros" then
                        if ShowMacroFrame then
                            ShowMacroFrame()
                        elseif targetBtn.Click then
                            targetBtn:Click()
                        end
                    else
                        if targetBtn.Click then
                            targetBtn:Click()
                        elseif targetBtn:GetScript("OnClick") then
                            local fn = targetBtn:GetScript("OnClick")
                            fn()
                        end
                    end
                end
            end)

            subPage.rows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", subPage.listContainer, "TOPLEFT", 0, startY - (i - 1) * (rowHeight + rowGap))
        row:SetPoint("TOPRIGHT", subPage.listContainer, "TOPRIGHT", 0, startY - (i - 1) * (rowHeight + rowGap))

        row.title:SetText(string.format("%s%s|r", tColor, btnData.text))
        if row.frameName then row.frameName:SetText("") end
        row.btnData = btnData
        row:Show()
    end

    -- Oculta linhas excedentes
    local totalRows = table.getn(subPage.rows)
    if totalRows > count then
        for j = count + 1, totalRows do
            subPage.rows[j]:Hide()
        end
    end
end

function MainMenu:UpdateAddonConfigSubPage()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageSystem = self.tabContainer.pages["SYSTEM"]
    if not pageSystem or not pageSystem.subPageAddonCfg then return end

    local subPage = pageSystem.subPageAddonCfg
    if subPage.isPopulated then return end

    -- Header
    local header = subPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", subPage, "TOPLEFT", 12, -8)
    MainMenu:ApplyFont(header, CFG.Fonts.titleFontFile, 15, "")
    header:SetText("|cffe09a15[ CONSOLEMODE - PAINEL DE CONTROLE ]|r")
    subPage.header = header

    local subText = subPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subText:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    MainMenu:ApplyFont(subText, CFG.Fonts.subFontFile, 12, "")
    subText:SetText("|cffaaaaaaGerencie atalhos do controle, sensibilidade e elementos visuais|r")
    subPage.subText = subText

    local listContainer = CreateFrame("Frame", "ConsoleModeMM_AddonCfgListContainer", subPage)
    listContainer:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -10)
    listContainer:SetPoint("BOTTOMRIGHT", subPage, "BOTTOMRIGHT", -12, 10)
    subPage.listContainer = listContainer

    local options = {
        {
            title = "Mapeador de Atalhos / Binds",
            desc = "Configurar habilidades, itens e macros dos botões do controle (Páginas 1 a 5)",
            onClick = function()
                MainMenu:Hide()
                if ConsoleMode.config and ConsoleMode.config.Show then
                    ConsoleMode.config:Show()
                end
            end,
        },
        {
            title = "Resetar Posições dos Elementos de UI",
            desc = "Restaura o posicionamento original de fábrica de todos os frames arrastáveis",
            onClick = function()
                if ConsoleModeDB then
                    ConsoleModeDB.positions = {}
                end
                if ConsoleMode.ui and ConsoleMode.ui.registeredFrames then
                    for key, data in pairs(ConsoleMode.ui.registeredFrames) do
                        if data.frame then
                            data.frame:ClearAllPoints()
                            data.frame:SetPoint(data.defaultPoint or "CENTER", UIParent, data.defaultRelPoint or data.defaultPoint or "CENTER", data.defaultX or 0, data.defaultY or 0)
                        end
                    end
                end
                if DEFAULT_CHAT_FRAME then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Posições dos elementos de interface restauradas com sucesso!")
                end
            end,
        },
        {
            title = "Recarregar Interface (/reload)",
            desc = "Reinicia a interface do World of Warcraft para aplicar configurações",
            onClick = function()
                ReloadUI()
            end,
        },
    }

    subPage.rows = {}
    local rowHeight = 38
    local rowGap = 6
    local startY = -4

    local bColor = CFG.System.badgeColor or "|cffe09a15"
    local tColor = CFG.System.itemTextColor or "|cffffffff"
    local numOptions = table.getn(options)

    for i = 1, numOptions do
        local opt = options[i]
        local row = CreateFrame("Button", "ConsoleModeMM_AddonCfgBtn_" .. i, listContainer)
        row:SetHeight(rowHeight)
        row:SetPoint("LEFT", listContainer, "LEFT", 0, 0)
        row:SetPoint("RIGHT", listContainer, "RIGHT", 0, 0)
        row:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, startY - (i - 1) * (rowHeight + rowGap))
        row:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", 0, startY - (i - 1) * (rowHeight + rowGap))

        -- Fundo translúcido
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bg:SetVertexColor(0.0, 0.0, 0.0, 0.30)
        row.bg = bg

        -- Barra de destaque dourada
        local highlightBar = row:CreateTexture(nil, "OVERLAY")
        highlightBar:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        highlightBar:SetWidth(3)
        highlightBar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        highlightBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        highlightBar:SetVertexColor(1.0, 0.85, 0.2, 0.95)
        highlightBar:Hide()
        row.highlightBar = highlightBar

        local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -6)
        MainMenu:ApplyFont(title, CFG.Fonts.bodyFontFile, 14)
        title:SetText(string.format("%s%s|r", tColor, opt.title))
        row.title = title

        local desc = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        desc:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 12, 5)
        MainMenu:ApplyFont(desc, CFG.Fonts.subFontFile, 11)
        desc:SetText(string.format("|cff888888%s|r", opt.desc))
        row.desc = desc

        row:SetScript("OnEnter", function()
            this.bg:SetVertexColor(1.0, 0.85, 0.2, 0.18)
            if this.highlightBar then this.highlightBar:Show() end
        end)

        row:SetScript("OnLeave", function()
            this.bg:SetVertexColor(0.0, 0.0, 0.0, 0.30)
            if this.highlightBar then this.highlightBar:Hide() end
        end)

        row.optData = opt
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            if this.optData and this.optData.onClick then
                this.optData.onClick()
            end
        end)

        table.insert(subPage.rows, row)
    end

    subPage.isPopulated = true
end

function MainMenu:SelectSystemSubTab(subTabID)
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageSystem = self.tabContainer.pages["SYSTEM"]
    if not pageSystem then return end

    self:SetupSystemPage(pageSystem)

    subTabID = subTabID or "GAME_MENU"
    pageSystem.currentSubTab = subTabID

    -- Alterna visibilidade das sub-páginas
    if pageSystem.subPageGameMenu then
        if subTabID == "GAME_MENU" then
            pageSystem.subPageGameMenu:Show()
            self:UpdateGameMenuSubPage()
        else
            pageSystem.subPageGameMenu:Hide()
        end
    end

    if pageSystem.subPageAddonCfg then
        if subTabID == "ADDON_CFG" then
            pageSystem.subPageAddonCfg:Show()
            self:UpdateAddonConfigSubPage()
        else
            pageSystem.subPageAddonCfg:Hide()
        end
    end

    -- Atualiza estilo dos botões da sub-aba
    if pageSystem.subButtons then
        for _, btn in ipairs(pageSystem.subButtons) do
            if btn.subTabData and btn.subTabData.id == subTabID then
                btn.title:SetTextColor(CFG.Tabs.activeColor.r, CFG.Tabs.activeColor.g, CFG.Tabs.activeColor.b)
            else
                btn.title:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end

    if ConsoleMode and ConsoleMode.cursor and ConsoleMode.cursor.Resync then
        ConsoleMode.cursor:Resync()
    end
end

function MainMenu:UpdateSystemPage()
    if not self.tabContainer or not self.tabContainer.pages then return end
    local pageSystem = self.tabContainer.pages["SYSTEM"]
    if not pageSystem then return end

    self:SetupSystemPage(pageSystem)
    self:SelectSystemSubTab(pageSystem.currentSubTab or "GAME_MENU")
end

-- ============================================================================
-- 8. CONTAINER DE ABAS E NAVEGAÇÃO [L1] / [R1] (FASE 4 - PAINEL DIREITO)
-- ============================================================================

function MainMenu:CreateTabContainer(rightPanel)
    if self.tabContainer then return self.tabContainer end

    -- 1. Barra Superior de Abas (com indicadores de gatilho [L1] e [R1] fixos e alinhados à direita)
    local tabBar = CreateFrame("Frame", "ConsoleModeMM_TabBar", rightPanel)
    tabBar:SetHeight(CFG.Tabs.barHeight)
    tabBar:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, 0)
    tabBar:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, 0)

    -- Indicador RB fixo na extremidade direita
    local r1Hint = tabBar:CreateTexture(nil, "OVERLAY")
    r1Hint:SetWidth(22)
    r1Hint:SetHeight(22)
    r1Hint:SetPoint("RIGHT", tabBar, "RIGHT", -2, 0)
    r1Hint:SetTexture(CFG.Icons.RB)
    tabBar.r1Hint = r1Hint

    -- Indicador LB à esquerda do bloco de abas
    local l1Hint = tabBar:CreateTexture(nil, "OVERLAY")
    l1Hint:SetWidth(22)
    l1Hint:SetHeight(22)
    l1Hint:SetTexture(CFG.Icons.LB)
    tabBar.l1Hint = l1Hint

    -- Container dos Botões de Aba (alinhado à direita, encostado no RB)
    local tabsCenter = CreateFrame("Frame", "ConsoleModeMM_TabsCenter", tabBar)
    tabsCenter:SetPoint("RIGHT", r1Hint, "LEFT", -6, 0)
    tabsCenter:SetHeight(CFG.Tabs.buttonHeight)

    local tabButtons = {}
    local tabBtnWidth = 104
    local gapX = CFG.Tabs.gapX or 6

    for i, tabData in ipairs(CFG.Tabs.list) do
        local tabBtn = CreateFrame("Button", "ConsoleModeMM_TabBtn" .. tabData.id, tabsCenter)
        tabBtn:SetHeight(CFG.Tabs.buttonHeight)

        local title = tabBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("CENTER", tabBtn, "CENTER", 0, 0)
        MainMenu:ApplyFont(title, CFG.Fonts.headerFontFile, CFG.Fonts.tabSize)
        title:SetText(tabData.name)
        tabBtn.title = title

        local strWidth = math.floor(title:GetStringWidth() or 80)
        local btnW = math.max(tabBtnWidth, strWidth + 14)
        tabBtn:SetWidth(btnW)

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
    end

    -- Posiciona os botões da esquerda para a direita dentro do container alinhado à direita
    local curX = 0
    local numButtons = table.getn(tabButtons)
    for idx, btn in ipairs(tabButtons) do
        btn:SetPoint("LEFT", tabsCenter, "LEFT", curX, 0)
        curX = curX + btn:GetWidth() + (idx < numButtons and gapX or 0)
    end
    tabsCenter:SetWidth(curX)

    -- Ancara o [LB] exatamente à esquerda do primeiro botão de aba
    l1Hint:SetPoint("RIGHT", tabsCenter, "LEFT", -6, 0)

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
    pages["SPELLS"] = pageSpells

    -- Página 3: Diário de Missões & Mapa Mundi (Fase 9)
    local pageQuests = CreateFrame("Frame", "ConsoleModeMM_Page_QUESTS", contentFrame)
    pageQuests:SetAllPoints(contentFrame)
    pages["QUESTS"] = pageQuests

    -- Página 4: Sistema e Configurações (Fase 8)
    local pageSystem = CreateFrame("Frame", "ConsoleModeMM_Page_SYSTEM", contentFrame)
    pageSystem:SetAllPoints(contentFrame)
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
            if tabBtn.tabData and tabBtn.tabData.id == tabID then
                tabBtn.title:SetTextColor(CFG.Tabs.activeColor.r, CFG.Tabs.activeColor.g, CFG.Tabs.activeColor.b)
                if tabBtn.highlight then tabBtn.highlight:Show() end
            else
                tabBtn.title:SetTextColor(CFG.Tabs.inactiveColor.r, CFG.Tabs.inactiveColor.g, CFG.Tabs.inactiveColor.b)
                if tabBtn.highlight then tabBtn.highlight:Hide() end
            end
        end
    end

    container.currentTab = tabID

    -- Se abriu a aba de Bolsas ou Magias, alterna o modelo 3D correspondente e atualiza o grid
    local facing = self.currentFacing or 0
    if tabID == "QUESTS" then
        if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.EnterMapMode then
            ConsoleMode.keybindings:EnterMapMode()
        end

        -- Na aba de Missões & Mapa, recolhe o palco do personagem 3D e expande o painel de conteúdo
        if self.frame and self.frame.leftPanel then self.frame.leftPanel:Hide() end
        if self.frame and self.frame.divider then self.frame.divider:Hide() end
        if self.frame and self.frame.rightPanel then
            self.frame.rightPanel:ClearAllPoints()
            self.frame.rightPanel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.LeftPanel.paddingLeft, CFG.RightPanel.paddingTop)
            self.frame.rightPanel:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingBottom)
        end
        self:RestorePlayerModel()
        self:UpdateQuestsPage()
    else
        if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.ExitMapMode then
            ConsoleMode.keybindings:ExitMapMode()
        end

        -- Ao sair da aba QUESTS, reseta o mapa para a zona do jogador
        self:ResetMapToPlayer()

        -- Nas demais abas, restaura o painel do personagem à esquerda e a divisão central
        if self.frame and self.frame.leftPanel then self.frame.leftPanel:Show() end
        if self.frame and self.frame.divider then self.frame.divider:Show() end
        if self.frame and self.frame.rightPanel and self.frame.leftPanel then
            self.frame.rightPanel:ClearAllPoints()
            self.frame.rightPanel:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingTop)
            self.frame.rightPanel:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingBottom)
            self.frame.rightPanel:SetPoint("LEFT", self.frame.leftPanel, "RIGHT", CFG.RightPanel.gapX, 0)
        end

        if tabID == "BAGS" then
            if self.animModel then self.animModel:Hide() end
            if self.dressUpModel then
                self.dressUpModel:Show()
                if self.dressUpModel.SetFacing then self.dressUpModel:SetFacing(facing) end
            end
            self.playerModel = self.dressUpModel
            self:UpdateBagsPage()
        elseif tabID == "SPELLS" then
            if self.dressUpModel then self.dressUpModel:Hide() end
            if self.animModel then
                self.animModel:Show()
                self.animModel:SetUnit("player")
                if self.animModel.SetFacing then self.animModel:SetFacing(facing) end
                if self.animModel.SetSequence then self.animModel:SetSequence(0) end
            end
            self.playerModel = self.animModel
            self.currentSpellPose = 0
            self:UpdateSpellsPage()
        elseif tabID == "SYSTEM" then
            self:RestorePlayerModel()
            self:UpdateSystemPage()
        else
            self:RestorePlayerModel()
        end
    end

    -- Resincroniza o cursor do D-Pad na nova aba
    if ConsoleMode and ConsoleMode.cursor and ConsoleMode.cursor.Resync then
        ConsoleMode.cursor:Resync()
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
    local curTab = self.tabContainer.currentTab or "BAGS"

    if curTab == "BAGS" then
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

    elseif curTab == "SPELLS" then
        local pageSpells = self.tabContainer.pages["SPELLS"]
        if not pageSpells or not pageSpells:IsVisible() then return false end

        direction = direction or 1
        local numTabs = GetNumSpellTabs() or 1
        local curIdx = pageSpells.currentTabIdx or 1
        local nextIdx = curIdx + direction
        if nextIdx > numTabs then nextIdx = 1 end
        if nextIdx < 1 then nextIdx = numTabs end

        self:SelectSpellTab(nextIdx)
        return true

    elseif curTab == "SYSTEM" then
        local pageSystem = self.tabContainer.pages["SYSTEM"]
        if not pageSystem or not pageSystem:IsVisible() then return false end

        direction = direction or 1
        local subTabs = CFG.System.subTabs
        local total = table.getn(subTabs)
        local curSubTab = pageSystem.currentSubTab or "GAME_MENU"
        local curIdx = 1

        for i, st in ipairs(subTabs) do
            if st.id == curSubTab then
                curIdx = i
                break
            end
        end

        local nextIdx = curIdx + direction
        if nextIdx > total then nextIdx = 1 end
        if nextIdx < 1 then nextIdx = total end

        self:SelectSystemSubTab(subTabs[nextIdx].id)
        if CFG.Audio.soundItemSelect then
            PlaySound(CFG.Audio.soundItemSelect)
        end
        return true
    end

    return false
end

-- ============================================================================
-- HELPER DE RODAPÉ COM ÍCONES GRÁFICOS DO CONTROLE
-- ============================================================================

function MainMenu:CreateFooterHints(footer)
    local hints = {
        { icons = { "LB", "RB" }, label = "Abas" },
        { icons = { "LT", "RT" }, label = "Filtros" },
        { icons = { "DALL" },     label = "Navegar" },
        { icons = { "A" },        label = "Usar / Equipar" },
        { icons = { "Y" },        label = "Ações" },
        { icons = { "B" },        label = "Fechar" },
    }

    local iconSize = CFG.Footer.iconSize or 18
    local iconGap = 2
    local labelGap = 5
    local groupGap = 16

    local container = CreateFrame("Frame", "ConsoleModeMM_FooterContainer", footer)
    container:SetHeight(26)
    container:SetPoint("CENTER", footer, "CENTER", 0, 0)

    local totalWidth = 0
    local widgets = {}

    for i, hint in ipairs(hints) do
        local groupFrame = CreateFrame("Frame", nil, container)
        groupFrame:SetHeight(26)

        local currentX = 0
        for _, iconKey in ipairs(hint.icons) do
            local texPath = CFG.Icons[iconKey] or (CFG.Icons.basePath .. iconKey .. ".tga")
            local iconTex = groupFrame:CreateTexture(nil, "OVERLAY")
            
            -- Tamanho customizado por tipo de botão no rodapé
            local curIconW = iconSize
            local curIconH = iconSize
            if iconKey == "LB" or iconKey == "RB" then
                curIconW = 25
                curIconH = 25
            elseif iconKey == "A" or iconKey == "B" or iconKey == "X" or iconKey == "Y" then
                curIconW = 20  -- +10% de tamanho para botões frontais (18px -> 20px)
                curIconH = 20
            end

            iconTex:SetWidth(curIconW)
            iconTex:SetHeight(curIconH)
            iconTex:SetTexture(texPath)
            iconTex:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
            currentX = currentX + curIconW + iconGap
        end

        currentX = currentX - iconGap + labelGap

        local label = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
        MainMenu:ApplyFont(label, CFG.Fonts.bodyFontFile, CFG.Fonts.footerSize or 12)
        label:SetText(hint.label)
        label:SetTextColor(0.85, 0.85, 0.85, 0.95)

        local textW = math.floor(label:GetStringWidth() or 40)
        currentX = currentX + textW

        if i < table.getn(hints) then
            local sep = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            sep:SetPoint("LEFT", groupFrame, "LEFT", currentX + 8, 0)
            MainMenu:ApplyFont(sep, CFG.Fonts.subFontFile, 12)
            sep:SetText("|cff666666•|r")
            currentX = currentX + 8 + 12
        end

        groupFrame:SetWidth(currentX)
        table.insert(widgets, groupFrame)
        totalWidth = totalWidth + currentX + (i < table.getn(hints) and groupGap or 0)
    end

    container:SetWidth(totalWidth)
    local curOffset = 0
    for _, w in ipairs(widgets) do
        w:SetPoint("LEFT", container, "LEFT", curOffset, 0)
        curOffset = curOffset + w:GetWidth() + groupGap
    end

    footer.hintContainer = container
end

-- Funções globais de rotação de modelo para os bindings nativos
function CM_ModelRotateLeft(keystate)
    if not MainMenu or not MainMenu.playerModel then return end
    if keystate == "up" then
        MainMenu.playerModel.rotateDir = 0
    else
        MainMenu.playerModel.rotateDir = -1
    end
end

function CM_ModelRotateRight(keystate)
    if not MainMenu or not MainMenu.playerModel then return end
    if keystate == "up" then
        MainMenu.playerModel.rotateDir = 0
    else
        MainMenu.playerModel.rotateDir = 1
    end
end

function MainMenu:ApplyModelRotationBindings()
    self.savedMoveBindings = {}
    local keysToSwap = { "A", "D", "Q", "E", "LEFT", "RIGHT", "a", "d", "q", "e" }
    
    local kTL1, kTL2 = GetBindingKey("TURNLEFT")
    local kTR1, kTR2 = GetBindingKey("TURNRIGHT")
    local kSL1, kSL2 = GetBindingKey("STRAFELEFT")
    local kSR1, kSR2 = GetBindingKey("STRAFERIGHT")

    if kTL1 then table.insert(keysToSwap, kTL1) end
    if kTL2 then table.insert(keysToSwap, kTL2) end
    if kTR1 then table.insert(keysToSwap, kTR1) end
    if kTR2 then table.insert(keysToSwap, kTR2) end
    if kSL1 then table.insert(keysToSwap, kSL1) end
    if kSL2 then table.insert(keysToSwap, kSL2) end
    if kSR1 then table.insert(keysToSwap, kSR1) end
    if kSR2 then table.insert(keysToSwap, kSR2) end

    for _, key in ipairs(keysToSwap) do
        local action = GetBindingAction(key)
        if action and action ~= "" and action ~= "CM_MODEL_ROTATE_LEFT" and action ~= "CM_MODEL_ROTATE_RIGHT" then
            self.savedMoveBindings[key] = action
        end
    end

    SetBinding("A", "CM_MODEL_ROTATE_LEFT")
    SetBinding("Q", "CM_MODEL_ROTATE_LEFT")
    SetBinding("a", "CM_MODEL_ROTATE_LEFT")
    SetBinding("q", "CM_MODEL_ROTATE_LEFT")
    if kTL1 then SetBinding(kTL1, "CM_MODEL_ROTATE_LEFT") end
    if kSL1 then SetBinding(kSL1, "CM_MODEL_ROTATE_LEFT") end

    SetBinding("D", "CM_MODEL_ROTATE_RIGHT")
    SetBinding("E", "CM_MODEL_ROTATE_RIGHT")
    SetBinding("d", "CM_MODEL_ROTATE_RIGHT")
    SetBinding("e", "CM_MODEL_ROTATE_RIGHT")
    if kTR1 then SetBinding(kTR1, "CM_MODEL_ROTATE_RIGHT") end
    if kSR1 then SetBinding(kSR1, "CM_MODEL_ROTATE_RIGHT") end
end

function MainMenu:RestoreModelRotationBindings()
    if not self.savedMoveBindings then return end
    for key, action in pairs(self.savedMoveBindings) do
        SetBinding(key, action)
    end
    self.savedMoveBindings = nil
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

    -- 8. Rodapé com Dicas do Controle (Console Hints com Ícones Gráficos Xbox)
    local footer = CreateFrame("Frame", "ConsoleModeMM_Footer", frame)
    footer:SetHeight(CFG.Footer.height)
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CFG.Footer.paddingLeft, CFG.Footer.offsetY)
    footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", CFG.Footer.paddingRight, CFG.Footer.offsetY)
    frame.footer = footer

    self:CreateFooterHints(footer)

    -- 9. Fechamento com tecla Escape
    table.insert(UISpecialFrames, "ConsoleModeMainMenuFrame")

    -- 10. Eventos OnShow / OnHide integrados aos Hooks do ConsoleMode
    frame:SetScript("OnShow", function()
        MainMenu:ApplyModelRotationBindings()

        MainMenu:UpdateLayout()
        MainMenu:UpdatePlayerModel()
        MainMenu:UpdateEquipmentColumn()
        MainMenu:UpdateStatsAndBuffs()

        if not MainMenu.mapShowingQuestZone then
            if SetMapToCurrentZone then SetMapToCurrentZone() end
            MainMenu.lastZoneText = (GetZoneText and GetZoneText()) or ""
        end

        local cur = (MainMenu.tabContainer and MainMenu.tabContainer.currentTab) or "BAGS"
        MainMenu:SelectTab(cur, false)

        if dimmer then dimmer:Show() end
        if CFG.Audio.soundOpen then PlaySound(CFG.Audio.soundOpen) end
        if ConsoleMode.hooks and ConsoleMode.hooks.OnFrameShow then
            ConsoleMode.hooks:OnFrameShow(this)
        end
    end)

    frame:SetScript("OnHide", function()
        if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.ExitMapMode then
            ConsoleMode.keybindings:ExitMapMode()
        end

        MainMenu:RestoreModelRotationBindings()
        if MainMenu.playerModel then
            MainMenu.playerModel.rotateDir = 0
        end

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

function MainMenu:Show(initialTab)
    if not self.frame then
        self:CreateUI()
    end
    if initialTab and self.tabContainer then
        self.tabContainer.currentTab = initialTab
    end
    if self.frame then
        if self.frame:IsVisible() and initialTab then
            self:SelectTab(initialTab, false)
        else
            self.frame:Show()
        end
    end
end

function MainMenu:Hide()
    if self.frame and self.frame:IsVisible() then
        self:RestorePlayerModel()
        self:ResetMapToPlayer()
        self.frame:Hide()
    end
end

function MainMenu:Toggle(initialTab)
    if self.frame and self.frame:IsVisible() then
        if initialTab and self.tabContainer and self.tabContainer.currentTab ~= initialTab then
            self:SelectTab(initialTab, false)
        else
            self:Hide()
        end
    else
        self:Show(initialTab)
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
initFrame:RegisterEvent("QUEST_LOG_UPDATE")
initFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
initFrame:RegisterEvent("ZONE_CHANGED")

initFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        MainMenu:CreateUI()
        if SetMapToCurrentZone then SetMapToCurrentZone() end
        MainMenu.lastZoneText = (GetZoneText and GetZoneText()) or ""
    elseif event == "DISPLAY_SIZE_CHANGED" then
        if MainMenu.UpdateLayout then
            MainMenu:UpdateLayout()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        local newZone = (GetZoneText and GetZoneText()) or ""
        if SetMapToCurrentZone then SetMapToCurrentZone() end
        MainMenu.lastZoneText = newZone
        if MainMenu.frame and MainMenu.frame:IsVisible() then
            if MainMenu.tabContainer and MainMenu.tabContainer.currentTab == "QUESTS" then
                if MainMenu.mapShowingQuestZone then return end
                MainMenu:UpdateQuestsPage()
            end
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
        elseif event == "QUEST_LOG_UPDATE" then
            if MainMenu.tabContainer and MainMenu.tabContainer.currentTab == "QUESTS" then
                MainMenu:UpdateQuestsPage()
            end
        end
    end
end)

-- Slash Command para Teste Rápido de Sequências de Animação
SLASH_CMANIM1 = "/anim"
SlashCmdList["CMANIM"] = function(msg)
    local id = tonumber(msg)
    if id then
        MainMenu.animTestSequence = id - 1
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[Anim Test]|r Próximo ID definido para: |cffffffff" .. id .. "|r (navegue no grid ou use /anim <num>)")
        end
        MainMenu:TriggerSpellPose(id)
    else
        MainMenu.animTestSequence = -1
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[Anim Test]|r Sequenciador resetado para ID 0. Navegue pelos slots do Grimório para avançar +1 a cada slot.")
        end
        MainMenu:TriggerSpellPose(0)
    end
end
