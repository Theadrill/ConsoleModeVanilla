--[[
    ConsoleMode - Vanilla
    UI/MainMenu.lua - Hub Central do Menu Principal (Console / Zelda Style)

    Estrutura Visual:
      [====================== MENU PRINCIPAL ======================]
      |  [ PALCO DO PERSONAGEM ]   |  [ CONTAINER DE ABAS & GRID ] |
      |  - Equipamentos (Esq)      |  - Abas: [L1] Bolsas | Spells [R1]
      |  - Modelo 3D Jogador       |  - Grid de Itens / Magias     |
      |  - Atributos e Buffs (Dir) |  - Tooltip Fixo (Inf. Direita)|
      [=================== [D-Pad] (A) (Y) (B) ====================]

    - FASE 1: Canvas 100% Responsivo por Porcentagem com renderização 9-Slice
    - FASE 2: Palco do Personagem 3D transparente (SetUnit('player')) com giro livre 360°
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
-- fontes, modelo 3D e efeitos estão centralizadas aqui.
-- Edite este bloco para ajustar a aparência sem mexer na lógica do código.
-- ============================================================================

local CFG = {}

-- ----------------------------------------------------------------------------
-- 1. JANELA PRINCIPAL (CANVAS ROOT RESPONSIVO)
-- Dimensionamento dinâmico baseado no tamanho da tela do jogador (UIParent).
-- Em telas pequenas (Steam Deck) ou TVs 4K, o menu se adapta proporcionalmente!
-- ----------------------------------------------------------------------------
CFG.Window = {
    usePercentage   = true,                 -- true = calcula por porcentagem da tela, false = usa staticWidth/Height
    widthPercent    = 0.88,                 -- Fração da largura útil da tela (88%)
    heightPercent   = 0.84,                 -- Fração da altura útil da tela (84%)
    
    minWidth        = 840,                  -- Largura mínima para telas muito compactas (px)
    minHeight       = 520,                  -- Altura mínima (px)
    maxWidth        = 1440,                 -- Largura máxima para telas Ultrawide/4K (px)
    maxHeight       = 920,                  -- Altura máxima (px)

    staticWidth     = 980,                  -- Largura estática de fallback se usePercentage = false
    staticHeight    = 620,                  -- Altura estática de fallback se usePercentage = false

    point           = "CENTER",             -- Ponto de ancoragem na tela
    relPoint        = "CENTER",             -- Ponto relativo no UIParent
    offsetX         = 0,                    -- Deslocamento horizontal (0 = centralizado)
    offsetY         = 0,                    -- Deslocamento vertical (0 = centralizado)
    frameStrata     = "FULLSCREEN_DIALOG",  -- Camada de renderização (acima da UI comum)
    frameLevel      = 100,                  -- Nível de sobreposição dentro da strata
}

-- ----------------------------------------------------------------------------
-- 2. DIMMER DE FUNDO (EFEITO ESCURECIDO DE IMERSÃO)
-- Escurece o mundo 3D do jogo por trás do menu ao abrir (estilo console).
-- ----------------------------------------------------------------------------
CFG.Dimmer = {
    enabled         = true,                 -- true = ativa o fundo escurecido, false = desativa
    frameStrata     = "FULLSCREEN",         -- Camada de renderização (atrás da janela principal)
    frameLevel      = 50,                   -- Nível de sobreposição
    color           = { r = 0.0, g = 0.0, b = 0.0, a = 0.65 }, -- Cor e opacidade (RGBA 0-1)
}

-- ----------------------------------------------------------------------------
-- 3. TEXTURA 9-SLICE DE PERGAMINHO / BANNER
-- Configuração do renderizador de 9 fatias (Padrão Unity / Sliced Image).
-- Mantém cantos em escala 1:1 nítida e estica apenas as bordas e centro.
-- ----------------------------------------------------------------------------
CFG.NineSlice = {
    texture         = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Carved_9Slides.tga",
    cornerSize      = 48,                   -- Tamanho dos 4 cantos fixos (px)
    drawLayer       = "BACKGROUND",         -- Camada de desenho das fatias

    -- Mapeamento das coordenadas UV da textura (Canvas POT 256x256 / Imagem 192x192)
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
-- Texto de cabeçalho no topo central do menu.
-- ----------------------------------------------------------------------------
CFG.Title = {
    show            = true,                 -- true = exibe o título, false = oculta
    text            = "|cffffd200MENU PRINCIPAL|r",
    font            = "GameFontNormalLarge",-- Fonte base da Blizzard
    offsetY         = -22,                  -- Posição Y a partir do topo da janela (px)
}

-- ----------------------------------------------------------------------------
-- 5. PAINEL ESQUERDO: PALCO DO PERSONAGEM (ESTRUTURA GERAL)
-- Ocupa a metade esquerda do menu. O modelo 3D é desenhado aqui sem fundo.
-- ----------------------------------------------------------------------------
CFG.LeftPanel = {
    paddingLeft     = 28,                   -- Margem em relação à borda esquerda do menu (px)
    paddingTop      = -50,                  -- Margem em relação ao topo do menu (px)
    paddingBottom   = 50,                   -- Margem em relação ao fundo do menu (px)
    widthRatio      = 0.46,                 -- 46% da largura útil interna da janela
}

-- ----------------------------------------------------------------------------
-- 5.1. MODELO 3D DO PERSONAGEM (PLAYER MODEL - FASE 2)
-- Viewport 3D transparente integrado diretamente ao fundo de pergaminho.
-- ----------------------------------------------------------------------------
CFG.PlayerModel = {
    width           = 320,                  -- Largura da viewport 3D (px)
    height          = 440,                  -- Altura da viewport 3D (px)
    offsetX         = 0,                    -- Deslocamento X no centro do palco esquerdo (px)
    offsetY         = -15,                  -- Deslocamento Y no centro do palco esquerdo (px)
    defaultFacing   = 0.0,                  -- Rotação inicial em radianos (0 = de frente)
    rotateSpeed     = 0.03,                 -- Velocidade de rotação ao arrastar o mouse / analógico
    enableMouseDrag = true,                 -- true = clicar e arrastar com o mouse gira o personagem
    showPlayerName  = true,                 -- true = exibe o nome e classe/raça/guilda na base do boneco
    nameFont        = "GameFontHighlightLarge", -- Fonte do nome do personagem
    guildFont       = "GameFontNormalSmall",    -- Fonte da guilda / raça / classe
}

-- ----------------------------------------------------------------------------
-- 6. PAINEL DIREITO: CONTAINER DE CONTEÚDO DAS ABAS (BOLSAS / SPELLBOOK)
-- Ocupa a metade direita do menu. As abas e o grid de itens ficam aqui.
-- ----------------------------------------------------------------------------
CFG.RightPanel = {
    paddingRight    = -28,                  -- Margem em relação à borda direita do menu (px)
    paddingTop      = -50,                  -- Margem em relação ao topo do menu (px)
    paddingBottom   = 50,                   -- Margem em relação ao fundo do menu (px)
    gapX            = 16,                   -- Espaçamento entre o painel esquerdo e direito (px)
}

-- ----------------------------------------------------------------------------
-- 7. DIVISÓRIA CENTRAL
-- Linha visual que separa elegantemente o lado do personagem e o das abas.
-- ----------------------------------------------------------------------------
CFG.Divider = {
    show            = true,                 -- true = exibe a divisória, false = oculta
    texture         = "Interface\\Tooltips\\UI-Tooltip-Border",
    width           = 2,                    -- Espessura da divisória (px)
    paddingTop      = 0,                    -- Alinhamento vertical topo
    paddingBottom   = 0,                    -- Alinhamento vertical base
    color           = { r = 0.6, g = 0.5, b = 0.3, a = 0.4 }, -- Cor e opacidade (RGBA)
}

-- ----------------------------------------------------------------------------
-- 8. RODAPÉ DE ATALHOS (CONSOLE HINTS)
-- Barra inferior com as legendas dos botões do controle.
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
-- Sons reproduzidos ao abrir, fechar ou alternar abas no menu.
-- ----------------------------------------------------------------------------
CFG.Audio = {
    soundOpen       = "igMainMenuOpen",
    soundClose      = "igMainMenuClose",
    soundTabChange  = "igCharacterInfoTab",
}

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

        -- Aplica os limites mínimos e máximos (Clamping)
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

    -- Calcula a largura proporcional do painel esquerdo
    local availableW = targetW - (CFG.LeftPanel.paddingLeft + math.abs(CFG.RightPanel.paddingRight) + CFG.RightPanel.gapX)
    local leftW = math.floor(availableW * CFG.LeftPanel.widthRatio)

    if self.frame.leftPanel then
        self.frame.leftPanel:SetWidth(leftW)
    end

    -- Alinha a divisória central exatamente no meio do espaçamento entre os dois painéis
    if self.frame.divider and self.frame.leftPanel then
        self.frame.divider:ClearAllPoints()
        local divGap = math.floor(CFG.RightPanel.gapX / 2)
        self.frame.divider:SetPoint("TOP", self.frame.leftPanel, "TOPRIGHT", divGap, CFG.Divider.paddingTop)
        self.frame.divider:SetPoint("BOTTOM", self.frame.leftPanel, "BOTTOMRIGHT", divGap, CFG.Divider.paddingBottom)
    end
end

-- ============================================================================
-- MODELO 3D DO PERSONAGEM (FASE 2)
-- ============================================================================

function MainMenu:CreatePlayerModel(leftPanel)
    if self.playerModel then return self.playerModel end

    -- 1. Frame PlayerModel sem fundo (transparência nativa do motor 3D)
    local model = CreateFrame("PlayerModel", "ConsoleModeMM_PlayerModel", leftPanel)
    model:SetPoint("CENTER", leftPanel, "CENTER", CFG.PlayerModel.offsetX, CFG.PlayerModel.offsetY)
    model:SetWidth(CFG.PlayerModel.width)
    model:SetHeight(CFG.PlayerModel.height)
    model:SetFrameLevel(leftPanel:GetFrameLevel() + 5)
    model.rotation = CFG.PlayerModel.defaultFacing or 0

    -- 2. Interação de Rotação 360° via Mouse Drag
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

    -- 3. Nome e Informações do Jogador na Base do Modelo
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

    -- Carrega o personagem atual com todas as armaduras e armas
    self.playerModel:ClearModel()
    self.playerModel:SetUnit("player")
    self.playerModel:SetFacing(self.playerModel.rotation or CFG.PlayerModel.defaultFacing or 0)
    self.playerModel:SetSequence(0) -- Stand / Idle animation

    -- Atualiza textos de Nome, Guilda, Raça e Classe
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

function MainMenu:RotatePlayerModel(delta)
    if not self.playerModel then return end
    delta = delta or 0.1
    self.playerModel.rotation = (self.playerModel.rotation or 0) + delta
    self.playerModel:SetFacing(self.playerModel.rotation)
end

-- ============================================================================
-- CRIAÇÃO DA JANELA PRINCIPAL (MAIN MENU FRAME)
-- ============================================================================

function MainMenu:CreateUI()
    if self.frame then return end

    -- 1. Dimmer de Fundo (Escurece o mundo do jogo para imersão console)
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

    -- 3. Aplica a Textura 9-Slice de Pergaminho/Madeira Talhada
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

    -- 5.1. Cria o Modelo 3D no Palco Esquerdo (FASE 2)
    self:CreatePlayerModel(leftPanel)

    -- 6. Painel Direito: Container de Conteúdo e Abas (Direita)
    local rightPanel = CreateFrame("Frame", "ConsoleModeMM_RightPanel", frame)
    rightPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingTop)
    rightPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", CFG.RightPanel.paddingRight, CFG.RightPanel.paddingBottom)
    rightPanel:SetPoint("LEFT", leftPanel, "RIGHT", CFG.RightPanel.gapX, 0)
    frame.rightPanel = rightPanel

    -- Marcador visual temporário para validação da Fase 1/2
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
initFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        MainMenu:CreateUI()
    elseif event == "DISPLAY_SIZE_CHANGED" then
        if MainMenu.UpdateLayout then
            MainMenu:UpdateLayout()
        end
    elseif event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_MODEL_CHANGED" then
        if arg1 == "player" and MainMenu.frame and MainMenu.frame:IsVisible() then
            MainMenu:UpdatePlayerModel()
        end
    end
end)
