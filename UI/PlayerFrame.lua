--[[
    ConsoleMode - Vanilla
    UI/PlayerFrame.lua - Player Frame Console HUD

    Layout:
      [Portrait]  [  HP bar  ] [  Castbar  ] [ Resource  ]
      [  Crest ]  [          ] [           ] [◆ ◆ ◇ ◇ ◇ ]

    - Portrait quadrado à esquerda
    - Crest da classe ancorada abaixo do portrait com o nome sobre ela
    - Container de barras de largura FIXA à direita do portrait
    - Três colunas com offsets X absolutos dentro do container:
        Coluna 1 = HP       (sempre visível)
        Coluna 2 = Castbar  (aparece só ao conjurar/canalizar)
        Coluna 3 = Recurso  (mana/rage/energy/focus, dinâmico por classe)
    - Alterar a largura de uma barra NÃO desloca as demais
    - Segunda linha da coluna 3: combo points com losangos (só Rogue)
    - Shift + arrastar    → move o cluster inteiro
    - Shift + botão dir.  → reseta para posição padrão (centro horizontal)
    - Todas as barras flutuantes, sem fundo nem moldura
    - Texturas: CP_Diamond_Empty.tga, CP_Diamond_Fill.tga, Crests/CLASSE.tga
    - Compatível com Lua 5.0 / WoW 1.12
]]

local CM = ConsoleMode
CM.ui = CM.ui or {}
CM.ui.playerFrame = CM.ui.playerFrame or {}
local PF = CM.ui.playerFrame

PF.frame           = nil   -- frame raiz criado em Initialize()
PF.isCasting       = false
PF.isChanneling    = false
PF.castValue       = 0
PF.castDuration    = 0
PF.channelValue    = 0
PF.channelDuration = 0
PF.damageTrailVal  = 0
PF.damageTrailTimer = 0
PF.curHP           = 0

-- ============================================================================
-- ██████████████████████   BLOCO DE CONFIGURAÇÃO   ███████████████████████████
--
-- Todas as variáveis de posição, tamanho, cor e comportamento estão aqui.
-- Edite este bloco para personalizar o layout sem tocar na lógica abaixo.
-- ============================================================================

local CFG = {}

-- ----------------------------------------------------------------------------
-- ÂNCORA DO FRAME RAIZ
-- Posição padrão: centralizado horizontalmente na tela, altura configurável.
-- "CENTER" + offsetX=0 = centro exato da tela no eixo X.
-- Ajuste defaultY para subir/descer o cluster inteiro (negativo = desce).
-- Shift + arrastar move; Shift + botão dir. reseta para cá.
-- ----------------------------------------------------------------------------
CFG.Anchor = {
    point    = "BOTTOM",   -- ponto de ancoragem do frame (BOTTOM = base da tela)
    relPoint = "BOTTOM",   -- ponto relativo do UIParent
    defaultX = 0,          -- offset X: 0 = centralizado horizontalmente
    defaultY = 110,        -- offset Y: pixels acima do fundo da tela
}

-- ----------------------------------------------------------------------------
-- PORTRAIT
-- Quadrado com o rosto 2D do personagem.
-- Ancorado no LEFT do frame raiz.
-- ----------------------------------------------------------------------------
CFG.Portrait = {
    size  = 58,   -- largura e altura do quadrado do rosto (px)
    gapX  = 8,    -- espaço horizontal entre portrait e container de barras (px)

    -- Moldura da classe (configuração única padronizada para todas as classes)
    frameShow    = true,   -- true = exibe a moldura, false = oculta globalmente
    frameWidth   = 128,    -- largura da moldura (px)
    frameHeight  = 128,    -- altura da moldura (px)
    frameOffsetX = -34,    -- deslocamento X em relação ao LEFT do frame raiz (px)
    frameOffsetY = 0,      -- deslocamento Y em relação ao LEFT do frame raiz (px, positivo = sobe)
}

-- ----------------------------------------------------------------------------
-- CREST DA CLASSE
-- Textura da classe ancorada abaixo do portrait.
-- O nome do personagem é escrito centralizado sobre ela.
-- ----------------------------------------------------------------------------
CFG.Crest = {
    width   = 96,    -- largura da textura (px) — pode ser maior que o portrait
    height  = 64,    -- altura da textura (px)
    offsetY = 18,    -- espaço vertical entre portrait e crest (negativo = desce)

    -- Fonte e estilo do nome
    nameFont      = "GameFontHighlightSmall",  -- herda família da fonte base
    nameSize      = 12,   -- tamanho em pt — nil = usa o tamanho padrão da nameFont
    nameFlags     = "OUTLINE",  -- contorno: "" (nenhum), "OUTLINE" (fino 1px), "THICKOUTLINE" (espesso 2px)
    nameColor     = { r = 1.0, g = 0.9, b = 0.6 },  -- cor do texto (RGB 0-1)

    -- Sombra projetada do texto
    shadowEnable  = true,            -- true = ativa sombra projetada, false = desativa
    shadowOffsetX = 1,               -- deslocamento X da sombra (px, positivo = direita)
    shadowOffsetY = -1,              -- deslocamento Y da sombra (px, negativo = baixo)
    shadowColor   = { r = 0, g = 0, b = 0, a = 1.0 },  -- cor e opacidade da sombra (RGBA 0-1)

    -- Posicionamento do texto dentro da crest
    -- anchor/relAnchor: ponto do texto e ponto da crest a que ele se ancora
    --   ex: "CENTER"/"CENTER" = centralizado, "BOTTOM"/"BOTTOM" = base alinhada
    nameAnchor    = "CENTER",  -- ponto de ancoragem do próprio texto
    nameRelAnchor = "CENTER",  -- ponto da crest usado como referência
    nameOffsetX   = 0,         -- deslocamento horizontal fino (px)
    nameOffsetY   = 8,         -- deslocamento vertical fino (px, positivo = sobe)
}

-- ----------------------------------------------------------------------------
-- CONTAINER DE BARRAS
-- Frame invisível que contém as três colunas.
-- A largura é calculada automaticamente: col1Width + col2Width + col3Width + 2*colGap.
-- Alterar a largura de uma coluna não move as outras — cada uma tem offsetX fixo.
-- colGap = espaço em pixels entre colunas adjacentes.
-- ----------------------------------------------------------------------------
CFG.Bars = {
    height      = 16,    -- altura uniforme de todas as barras (px)
    colGap      = 6,     -- espaço entre colunas (px)

    col1Width   = 140,   -- largura da barra de HP        (px)
    col2Width   = 140,   -- largura da castbar             (px)
    col3Width   = 140,   -- largura da barra de recurso    (px)
}

-- ----------------------------------------------------------------------------
-- BARRA DE HP (coluna 1)
-- ----------------------------------------------------------------------------
CFG.HP = {
    -- Cor da barra principal
    color      = { r = 0.12, g = 0.85, b = 0.20, a = 1.0 },  -- verde esmeralda

    -- Cor da barra de damage trail (decai suavemente após dano)
    trailColor = { r = 0.95, g = 0.80, b = 0.10, a = 0.80 },  -- amarelo âmbar
    trailDelay = 0.35,   -- segundos de espera antes do trail começar a cair
    trailSpeed = 5.0,    -- velocidade do decay (multiplicador)

    -- Texto "128 / 128 (100%)" sobre a barra
    showText      = true,
    textFont      = "GameFontHighlightSmall",  -- fonte base
    textSize      = nil,   -- tamanho em pt — nil = usa o padrão da fonte
    textColor     = { r = 1.0, g = 1.0, b = 1.0 },  -- cor do texto (RGB 0-1)
    textAnchor    = "CENTER",  -- ponto de ancoragem do texto
    textRelAnchor = "CENTER",  -- ponto da barra usado como referência
    textOffsetX   = 0,         -- deslocamento horizontal fino (px)
    textOffsetY   = 0,         -- deslocamento vertical fino (px)
}

-- ----------------------------------------------------------------------------
-- CASTBAR (coluna 2)
-- Some completamente quando o jogador não está conjurando/canalizando.
-- Aparece automaticamente ao iniciar um cast.
-- ----------------------------------------------------------------------------
CFG.CastBar = {
    -- Cor ao conjurar normalmente
    castColor    = { r = 1.0, g = 0.75, b = 0.0,  a = 1.0 },  -- amarelo dourado
    -- Cor ao canalizar (channeling — barra regride)
    channelColor = { r = 0.2, g = 0.8,  b = 1.0,  a = 1.0 },  -- azul claro

    -- Texto do nome da magia (lado esquerdo da barra)
    spellFont      = "GameFontHighlightSmall",
    spellSize      = nil,   -- tamanho em pt — nil = padrão da fonte
    spellColor     = { r = 1.0, g = 1.0, b = 1.0 },
    spellAnchor    = "LEFT",
    spellRelAnchor = "LEFT",
    spellOffsetX   = 4,    -- recuo da borda esquerda (px)
    spellOffsetY   = 0,

    -- Texto do tempo restante (lado direito da barra)
    timeFont       = "GameFontHighlightSmall",
    timeSize       = nil,   -- tamanho em pt — nil = padrão da fonte
    timeColor      = { r = 1.0, g = 1.0, b = 1.0 },
    timeAnchor     = "RIGHT",
    timeRelAnchor  = "RIGHT",
    timeOffsetX    = -4,   -- recuo da borda direita (px, negativo = para dentro)
    timeOffsetY    = 0,
}

-- ----------------------------------------------------------------------------
-- BARRA DE RECURSO (coluna 3)
-- Cor muda automaticamente conforme o tipo de recurso da classe.
-- ----------------------------------------------------------------------------
CFG.Resource = {
    -- Cores por tipo de recurso (UnitPowerType: 0=mana 1=rage 2=focus 3=energy)
    colors = {
        [0] = { r = 0.00, g = 0.55, b = 1.00, a = 1.0 },  -- azul    mana
        [1] = { r = 0.90, g = 0.15, b = 0.15, a = 1.0 },  -- vermelho rage
        [2] = { r = 1.00, g = 0.50, b = 0.00, a = 1.0 },  -- laranja  focus
        [3] = { r = 1.00, g = 0.85, b = 0.10, a = 1.0 },  -- amarelo  energy
    },

    -- Texto sobre a barra de recurso
    showText      = true,
    textFont      = "GameFontHighlightSmall",
    textSize      = nil,   -- tamanho em pt — nil = padrão da fonte
    textColor     = { r = 1.0, g = 1.0, b = 1.0 },
    textAnchor    = "CENTER",
    textRelAnchor = "CENTER",
    textOffsetX   = 0,
    textOffsetY   = 0,
}

-- ----------------------------------------------------------------------------
-- COMBO POINTS (segunda linha, coluna 3 — somente Rogue)
-- Losangos aparecem/somem dinamicamente. Invisíveis para outras classes.
-- ----------------------------------------------------------------------------
CFG.ComboPoints = {
    count   = 5,    -- total de pontos (fixo: 5 para Rogue)
    size    = 20,   -- largura E altura de cada losango (px) — aumente para losangos maiores
    spacing = nil,  -- distância entre centros (px) — nil = distribui automaticamente pela largura da castbar
    offsetY = -3,   -- deslocamento vertical abaixo da castbar (negativo = desce)
    offsetX = 0,    -- deslocamento horizontal em relação à borda esquerda da castbar

    -- 1 a 4 pontos: dourado
    colorNormal = { r = 1.0, g = 0.85, b = 0.0,  a = 1.0 },
    -- 5º ponto (finalizador): laranja-vermelho
    colorFull   = { r = 1.0, g = 0.22, b = 0.05, a = 1.0 },
}

-- ============================================================================
-- FIM DO BLOCO DE CONFIGURAÇÃO
-- ============================================================================




-- ============================================================================
-- LÓGICA: INICIALIZAÇÃO
-- ============================================================================

function PF:Initialize()
    if self.frame then
        self:HideDefaultBars()
        self:Update()
        return
    end

    -- Calcula offsets X absolutos das colunas dentro do container de barras.
    -- Coluna 1 começa em 0. Coluna 2 começa após col1 + gap. Idem coluna 3.
    -- Estes valores são usados em SetPoint para que cada coluna seja
    -- independente das demais — mudar col1Width não move col2 ou col3.
    local col1X = 0
    local col2X = col1X + CFG.Bars.col1Width + CFG.Bars.colGap
    local col3X = col2X + CFG.Bars.col2Width + CFG.Bars.colGap

    -- totalWidth calculado automaticamente: soma das três colunas + dois gaps.
    -- Garante que o container seja exatamente do tamanho das barras, sem sobra.
    local barsTotal = CFG.Bars.col1Width + CFG.Bars.col2Width + CFG.Bars.col3Width
                      + (CFG.Bars.colGap * 2)

    -- Largura total do frame raiz = portrait + gap + container de barras
    local rootWidth  = CFG.Portrait.size + CFG.Portrait.gapX + barsTotal
    local rootHeight = CFG.Bars.height

    -- -----------------------------------------------------------------------
    -- FRAME RAIZ
    -- Tamanho real para que o drag cubra a área visível do cluster.
    -- EnableMouse e RegisterForDrag habilitados para o shift+drag.
    -- -----------------------------------------------------------------------
    local f = CreateFrame("Button", "ConsoleModePlayerFrame", UIParent)
    f:SetWidth(rootWidth)
    f:SetHeight(rootHeight)
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)

    -- Posicionamento persistente via sistema do Core (salva/restaura posição)
    if CM.ui and CM.ui.MakeMovable then
        CM.ui:MakeMovable(
            f, "PlayerFrame",
            CFG.Anchor.point, CFG.Anchor.relPoint,
            CFG.Anchor.defaultX, CFG.Anchor.defaultY,
            "Player Frame"
        )
    else
        f:SetPoint(
            CFG.Anchor.point, UIParent, CFG.Anchor.relPoint,
            CFG.Anchor.defaultX, CFG.Anchor.defaultY
        )
    end

    -- Shift + arrastar esquerdo = mover
    f:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            this:StartMoving()
            this.isMoving = true
        end
    end)

    -- Soltar botão = parar de mover e salvar posição
    f:SetScript("OnDragStop", function()
        if this.isMoving then
            this:StopMovingOrSizing()
            this.isMoving = false
            if not ConsoleModeDB then ConsoleModeDB = {} end
            if not ConsoleModeDB.positions then ConsoleModeDB.positions = {} end
            local point, _, relPoint, x, y = this:GetPoint()
            ConsoleModeDB.positions["PlayerFrame"] = {
                point = point, relPoint = relPoint, x = x, y = y
            }
        end
    end)

    -- Clique esquerdo simples (sem Shift) = se targetar
    f:SetScript("OnClick", function()
        if arg1 == "LeftButton" and not IsShiftKeyDown() then
            TargetUnit("player")
        end
    end)

    -- Shift + botão direito = resetar para posição padrão
    f:SetScript("OnMouseUp", function()
        if arg1 == "RightButton" and IsShiftKeyDown() then
            if CM.ui and CM.ui.ResetPosition then
                CM.ui:ResetPosition("PlayerFrame")
            else
                f:ClearAllPoints()
                f:SetPoint(
                    CFG.Anchor.point, UIParent, CFG.Anchor.relPoint,
                    CFG.Anchor.defaultX, CFG.Anchor.defaultY
                )
                if ConsoleModeDB and ConsoleModeDB.positions then
                    ConsoleModeDB.positions["PlayerFrame"] = nil
                end
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Player Frame restaurado para a posicao padrao!")
            end
        end
    end)

    -- -----------------------------------------------------------------------
    -- PORTRAIT
    -- Ancorado no LEFT do frame raiz, centralizado verticalmente.
    -- -----------------------------------------------------------------------
    local portrait = f:CreateTexture("ConsoleModePlayerPortrait", "ARTWORK")
    portrait:SetWidth(CFG.Portrait.size)
    portrait:SetHeight(CFG.Portrait.size)
    portrait:SetPoint("LEFT", f, "LEFT", 0, 0)
    portrait:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    f.portrait = portrait

    -- Moldura da classe sobreposta ao portrait (Media/Portraits/CLASSE.tga)
    -- A textura real é definida em PF:Update() após detectar a classe.
    local portraitFrame = f:CreateTexture("ConsoleModePlayerPortraitFrame", "OVERLAY")
    portraitFrame:SetWidth(CFG.Portrait.frameWidth)
    portraitFrame:SetHeight(CFG.Portrait.frameHeight)
    portraitFrame:SetPoint("LEFT", f, "LEFT", CFG.Portrait.frameOffsetX, CFG.Portrait.frameOffsetY)
    if not CFG.Portrait.frameShow then
        portraitFrame:Hide()
    end
    f.portraitFrame = portraitFrame

    -- -----------------------------------------------------------------------
    -- CREST DA CLASSE
    -- Ancorada abaixo do portrait, centralizada no eixo X dele.
    -- -----------------------------------------------------------------------
    local crestFrame = CreateFrame("Frame", "ConsoleModePlayerCrestFrame", f)
    crestFrame:SetWidth(CFG.Crest.width)
    crestFrame:SetHeight(CFG.Crest.height)
    crestFrame:SetPoint("TOP", portrait, "BOTTOM", 0, CFG.Crest.offsetY)
    crestFrame:SetFrameLevel(f:GetFrameLevel() + 1)

    local crestTex = crestFrame:CreateTexture(nil, "ARTWORK")
    crestTex:SetAllPoints(crestFrame)
    f.crestTex = crestTex

    local nameText = crestFrame:CreateFontString(nil, "OVERLAY", CFG.Crest.nameFont)
    nameText:SetPoint(
        CFG.Crest.nameAnchor, crestFrame, CFG.Crest.nameRelAnchor,
        CFG.Crest.nameOffsetX, CFG.Crest.nameOffsetY
    )
    local fontPath, fontSize, fontFlags = nameText:GetFont()
    local finalSize = CFG.Crest.nameSize or fontSize or 12
    local finalFlags = CFG.Crest.nameFlags or fontFlags or ""
    if fontPath then
        nameText:SetFont(fontPath, finalSize, finalFlags)
    end
    nameText:SetTextColor(CFG.Crest.nameColor.r, CFG.Crest.nameColor.g, CFG.Crest.nameColor.b)

    -- Sombra projetada
    if CFG.Crest.shadowEnable then
        nameText:SetShadowOffset(CFG.Crest.shadowOffsetX or 1, CFG.Crest.shadowOffsetY or -1)
        if CFG.Crest.shadowColor then
            local sc = CFG.Crest.shadowColor
            nameText:SetShadowColor(sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 1.0)
        end
    else
        nameText:SetShadowOffset(0, 0)
    end
    f.nameText = nameText

    -- -----------------------------------------------------------------------
    -- CONTAINER DE BARRAS
    -- Frame invisível de largura fixa. As colunas são ancoradas com offsetX
    -- absoluto dentro dele — independentes umas das outras.
    -- -----------------------------------------------------------------------
    local barsContainer = CreateFrame("Frame", "ConsoleModePlayerBarsContainer", f)
    barsContainer:SetWidth(barsTotal)
    barsContainer:SetHeight(CFG.Bars.height)
    barsContainer:SetPoint("LEFT", portrait, "RIGHT", CFG.Portrait.gapX, 0)
    barsContainer:SetFrameLevel(f:GetFrameLevel() + 1)
    f.barsContainer = barsContainer



    -- -----------------------------------------------------------------------
    -- COLUNA 1 — HP BAR
    -- offsetX = col1X (sempre 0 = borda esquerda do container)
    -- -----------------------------------------------------------------------
    local trailBar = CreateFrame("StatusBar", "ConsoleModePlayerTrailBar", barsContainer)
    trailBar:SetWidth(CFG.Bars.col1Width)
    trailBar:SetHeight(CFG.Bars.height)
    trailBar:SetPoint("LEFT", barsContainer, "LEFT", col1X, 0)
    trailBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    trailBar:SetStatusBarColor(
        CFG.HP.trailColor.r, CFG.HP.trailColor.g,
        CFG.HP.trailColor.b, CFG.HP.trailColor.a
    )
    trailBar:SetMinMaxValues(0, 1)
    trailBar:SetValue(1)
    trailBar:SetFrameLevel(barsContainer:GetFrameLevel())
    f.trailBar = trailBar

    local hpBar = CreateFrame("StatusBar", "ConsoleModePlayerHPBar", barsContainer)
    hpBar:SetWidth(CFG.Bars.col1Width)
    hpBar:SetHeight(CFG.Bars.height)
    hpBar:SetPoint("LEFT", barsContainer, "LEFT", col1X, 0)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(CFG.HP.color.r, CFG.HP.color.g, CFG.HP.color.b, CFG.HP.color.a)
    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(1)
    hpBar:SetFrameLevel(barsContainer:GetFrameLevel() + 1)
    f.hpBar = hpBar

    local hpText = hpBar:CreateFontString(nil, "OVERLAY", CFG.HP.textFont)
    hpText:SetPoint(
        CFG.HP.textAnchor, hpBar, CFG.HP.textRelAnchor,
        CFG.HP.textOffsetX, CFG.HP.textOffsetY
    )
    if CFG.HP.textSize then
        local fontPath = hpText:GetFont()
        hpText:SetFont(fontPath, CFG.HP.textSize)
    end
    hpText:SetTextColor(CFG.HP.textColor.r, CFG.HP.textColor.g, CFG.HP.textColor.b)
    hpText:SetText("")
    f.hpText = hpText

    -- -----------------------------------------------------------------------
    -- COLUNA 2 — CASTBAR
    -- offsetX = col2X (fixo, não depende da largura da HP bar)
    -- Oculta por padrão; aparece ao iniciar conjuração.
    -- -----------------------------------------------------------------------
    local castBar = CreateFrame("StatusBar", "ConsoleModePlayerCastBar", barsContainer)
    castBar:SetWidth(CFG.Bars.col2Width)
    castBar:SetHeight(CFG.Bars.height)
    castBar:SetPoint("LEFT", barsContainer, "LEFT", col2X, 0)
    castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    castBar:SetStatusBarColor(
        CFG.CastBar.castColor.r, CFG.CastBar.castColor.g,
        CFG.CastBar.castColor.b, CFG.CastBar.castColor.a
    )
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    castBar:SetFrameLevel(barsContainer:GetFrameLevel() + 1)
    castBar:Hide()
    f.castBar = castBar

    local castSpellText = castBar:CreateFontString(nil, "OVERLAY", CFG.CastBar.spellFont)
    castSpellText:SetPoint(
        CFG.CastBar.spellAnchor, castBar, CFG.CastBar.spellRelAnchor,
        CFG.CastBar.spellOffsetX, CFG.CastBar.spellOffsetY
    )
    if CFG.CastBar.spellSize then
        local fontPath = castSpellText:GetFont()
        castSpellText:SetFont(fontPath, CFG.CastBar.spellSize)
    end
    castSpellText:SetTextColor(CFG.CastBar.spellColor.r, CFG.CastBar.spellColor.g, CFG.CastBar.spellColor.b)
    castSpellText:SetText("")
    f.castSpellText = castSpellText

    local castTimeText = castBar:CreateFontString(nil, "OVERLAY", CFG.CastBar.timeFont)
    castTimeText:SetPoint(
        CFG.CastBar.timeAnchor, castBar, CFG.CastBar.timeRelAnchor,
        CFG.CastBar.timeOffsetX, CFG.CastBar.timeOffsetY
    )
    if CFG.CastBar.timeSize then
        local fontPath = castTimeText:GetFont()
        castTimeText:SetFont(fontPath, CFG.CastBar.timeSize)
    end
    castTimeText:SetTextColor(CFG.CastBar.timeColor.r, CFG.CastBar.timeColor.g, CFG.CastBar.timeColor.b)
    castTimeText:SetText("")
    f.castTimeText = castTimeText

    -- -----------------------------------------------------------------------
    -- COLUNA 3 — RESOURCE BAR
    -- offsetX = col3X (fixo, não depende das larguras anteriores)
    -- -----------------------------------------------------------------------
    local resBar = CreateFrame("StatusBar", "ConsoleModePlayerResBar", barsContainer)
    resBar:SetWidth(CFG.Bars.col3Width)
    resBar:SetHeight(CFG.Bars.height)
    resBar:SetPoint("LEFT", barsContainer, "LEFT", col3X, 0)
    resBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    resBar:SetMinMaxValues(0, 1)
    resBar:SetValue(1)
    resBar:SetFrameLevel(barsContainer:GetFrameLevel() + 1)
    f.resBar = resBar

    local resText = resBar:CreateFontString(nil, "OVERLAY", CFG.Resource.textFont)
    resText:SetPoint(
        CFG.Resource.textAnchor, resBar, CFG.Resource.textRelAnchor,
        CFG.Resource.textOffsetX, CFG.Resource.textOffsetY
    )
    if CFG.Resource.textSize then
        local fontPath = resText:GetFont()
        resText:SetFont(fontPath, CFG.Resource.textSize)
    end
    resText:SetTextColor(CFG.Resource.textColor.r, CFG.Resource.textColor.g, CFG.Resource.textColor.b)
    resText:SetText("")
    f.resText = resText

    -- -----------------------------------------------------------------------
    -- COMBO POINTS (linha 2, coluna 2 — somente Rogue)
    -- Ancorados abaixo da castbar com offsetX absoluto igual ao col2X.
    -- spacing automático: distribui os losangos uniformemente pela largura da castbar.
    -- -----------------------------------------------------------------------
    -- Calcula spacing: divide a largura da castbar em (count) fatias iguais.
    -- Se CFG.ComboPoints.spacing for definido manualmente, usa ele.
    local cpSpacing = CFG.ComboPoints.spacing or (CFG.Bars.col2Width / CFG.ComboPoints.count)

    local comboContainer = CreateFrame("Frame", "ConsoleModePlayerComboPoints", barsContainer)
    comboContainer:SetWidth(CFG.Bars.col2Width)
    comboContainer:SetHeight(CFG.ComboPoints.size)
    comboContainer:SetPoint(
        "TOPLEFT", barsContainer, "BOTTOMLEFT",
        col2X + CFG.ComboPoints.offsetX, CFG.ComboPoints.offsetY
    )
    comboContainer:Hide()
    f.comboContainer = comboContainer

    f.comboPoints = {}
    for i = 1, CFG.ComboPoints.count do
        local cp = CreateFrame("Frame", "ConsoleModePlayerCP" .. i, comboContainer)
        cp:SetWidth(CFG.ComboPoints.size)
        cp:SetHeight(CFG.ComboPoints.size)
        -- Centraliza cada losango na sua fatia: offset = (i-0.5) * spacing - size/2
        local cpX = (i - 0.5) * cpSpacing - (CFG.ComboPoints.size / 2)
        cp:SetPoint("LEFT", comboContainer, "LEFT", cpX, 0)

        local emptyTex = cp:CreateTexture(nil, "BACKGROUND")
        emptyTex:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\CP_Diamond_Empty.tga")
        emptyTex:SetAllPoints(cp)
        cp.empty = emptyTex

        local fillTex = cp:CreateTexture(nil, "ARTWORK")
        fillTex:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\CP_Diamond_Fill.tga")
        fillTex:SetAllPoints(cp)
        fillTex:Hide()
        cp.fill = fillTex

        f.comboPoints[i] = cp
    end

    -- -----------------------------------------------------------------------
    -- OnUpdate: damage trail + castbar timer
    -- -----------------------------------------------------------------------
    f:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0.016

        -- Damage trail (decai suavemente após levar dano)
        if PF.curHP and PF.damageTrailVal > PF.curHP then
            PF.damageTrailTimer = PF.damageTrailTimer + elapsed
            if PF.damageTrailTimer > CFG.HP.trailDelay then
                local speed = (PF.damageTrailVal - PF.curHP) * CFG.HP.trailSpeed * elapsed
                PF.damageTrailVal = PF.damageTrailVal - speed
                if PF.damageTrailVal <= PF.curHP then
                    PF.damageTrailVal = PF.curHP
                end
                PF.frame.trailBar:SetValue(PF.damageTrailVal)
            end
        elseif PF.curHP then
            PF.damageTrailVal   = PF.curHP
            PF.damageTrailTimer = 0
            PF.frame.trailBar:SetValue(PF.curHP)
        end

        -- Castbar conjurando (barra avança)
        if PF.isCasting and PF.castDuration and PF.castDuration > 0 then
            PF.castValue = PF.castValue + elapsed
            if PF.castValue >= PF.castDuration then
                PF.castValue = PF.castDuration
                PF:ResetCastBar()
            else
                PF.frame.castBar:SetValue(PF.castValue)
                local rem = PF.castDuration - PF.castValue
                PF.frame.castTimeText:SetText(string.format("%.1fs", rem))
            end

        -- Castbar canalizando (barra regride)
        elseif PF.isChanneling and PF.channelDuration and PF.channelDuration > 0 then
            PF.channelValue = PF.channelValue - elapsed
            if PF.channelValue <= 0 then
                PF.channelValue = 0
                PF:ResetCastBar()
            else
                PF.frame.castBar:SetValue(PF.channelValue)
                PF.frame.castTimeText:SetText(string.format("%.1fs", PF.channelValue))
            end
        end
    end)

    -- -----------------------------------------------------------------------
    -- Registro de eventos
    -- -----------------------------------------------------------------------
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("UNIT_MANA")
    f:RegisterEvent("UNIT_MAXMANA")
    f:RegisterEvent("UNIT_RAGE")
    f:RegisterEvent("UNIT_MAXRAGE")
    f:RegisterEvent("UNIT_ENERGY")
    f:RegisterEvent("UNIT_MAXENERGY")
    f:RegisterEvent("UNIT_FOCUS")
    f:RegisterEvent("UNIT_MAXFOCUS")
    f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    f:RegisterEvent("UNIT_MODEL_CHANGED")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("PLAYER_COMBO_POINTS")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("SPELLCAST_START")
    f:RegisterEvent("SPELLCAST_STOP")
    f:RegisterEvent("SPELLCAST_FAILED")
    f:RegisterEvent("SPELLCAST_INTERRUPTED")
    f:RegisterEvent("SPELLCAST_DELAYED")
    f:RegisterEvent("SPELLCAST_CHANNEL_START")
    f:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
    f:RegisterEvent("SPELLCAST_CHANNEL_STOP")

    f:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            PF:HideDefaultBars()
            -- Delay para o modelo do personagem terminar de carregar
            local delay = CreateFrame("Frame")
            delay.elapsed = 0
            delay:SetScript("OnUpdate", function()
                this.elapsed = this.elapsed + arg1
                if this.elapsed > 0.3 then
                    this:SetScript("OnUpdate", nil)
                    PF:Update()
                end
            end)

        elseif event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" then
            if arg1 == "player" then
                SetPortraitTexture(PF.frame.portrait, "player")
            end

        elseif event == "PLAYER_COMBO_POINTS" or event == "PLAYER_TARGET_CHANGED" then
            PF:UpdateComboPoints()

        elseif event == "PLAYER_LEVEL_UP" then
            PF:Update()

        elseif event == "SPELLCAST_START" then
            local spellName   = arg1 or ""
            local durationSec = (arg2 or 0) / 1000
            if durationSec > 0 then
                PF.isCasting      = true
                PF.isChanneling   = false
                PF.castValue      = 0
                PF.castDuration   = durationSec
                local cb = PF.frame.castBar
                cb:SetMinMaxValues(0, durationSec)
                cb:SetValue(0)
                cb:SetStatusBarColor(
                    CFG.CastBar.castColor.r, CFG.CastBar.castColor.g,
                    CFG.CastBar.castColor.b, CFG.CastBar.castColor.a
                )
                PF.frame.castSpellText:SetText(spellName)
                PF.frame.castTimeText:SetText(string.format("%.1fs", durationSec))
                cb:Show()
            end

        elseif event == "SPELLCAST_STOP" then
            if PF.isCasting then PF:ResetCastBar() end

        elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
            PF:ResetCastBar()

        elseif event == "SPELLCAST_DELAYED" then
            if PF.isCasting and PF.castDuration then
                local delaySec = (arg1 or 0) / 1000
                PF.castDuration = PF.castDuration + delaySec
                PF.frame.castBar:SetMinMaxValues(0, PF.castDuration)
            end

        elseif event == "SPELLCAST_CHANNEL_START" then
            local durationSec = (arg1 or 0) / 1000
            local spellName   = arg2 or ""
            if durationSec > 0 then
                PF.isChanneling    = true
                PF.isCasting       = false
                PF.channelValue    = durationSec
                PF.channelDuration = durationSec
                local cb = PF.frame.castBar
                cb:SetMinMaxValues(0, durationSec)
                cb:SetValue(durationSec)
                cb:SetStatusBarColor(
                    CFG.CastBar.channelColor.r, CFG.CastBar.channelColor.g,
                    CFG.CastBar.channelColor.b, CFG.CastBar.channelColor.a
                )
                PF.frame.castSpellText:SetText(spellName)
                PF.frame.castTimeText:SetText(string.format("%.1fs", durationSec))
                cb:Show()
            end

        elseif event == "SPELLCAST_CHANNEL_UPDATE" then
            if PF.isChanneling then
                PF.channelValue = (arg1 or 0) / 1000
            end

        elseif event == "SPELLCAST_CHANNEL_STOP" then
            if PF.isChanneling then PF:ResetCastBar() end

        elseif arg1 == "player" then
            PF:UpdateBars()
        end
    end)

    self.frame = f
    self:HideDefaultBars()
    self:Update()
    f:Show()
end

-- ============================================================================
-- LÓGICA: RESET DA CASTBAR
-- ============================================================================

function PF:ResetCastBar()
    self.isCasting    = false
    self.isChanneling = false
    self.castValue    = 0
    self.channelValue = 0
    if self.frame then
        self.frame.castBar:SetValue(0)
        self.frame.castSpellText:SetText("")
        self.frame.castTimeText:SetText("")
        self.frame.castBar:Hide()
    end
end

-- ============================================================================
-- LÓGICA: ATUALIZAÇÃO DAS BARRAS DE HP E RECURSO
-- ============================================================================

function PF:UpdateBars()
    if not self.frame then return end

    -- HP
    local curHP = UnitHealth("player") or 0
    local maxHP = UnitHealthMax("player") or 1
    self.curHP = curHP

    self.frame.hpBar:SetMinMaxValues(0, maxHP)
    self.frame.hpBar:SetValue(curHP)
    self.frame.trailBar:SetMinMaxValues(0, maxHP)

    -- Reinicia trail se o valor saiu do intervalo válido
    if not self.damageTrailVal
    or self.damageTrailVal > maxHP
    or self.damageTrailVal < curHP then
        self.damageTrailVal = curHP
        self.frame.trailBar:SetValue(curHP)
    end

    if CFG.HP.showText then
        local pct = maxHP > 0 and math.floor((curHP / maxHP) * 100) or 0
        self.frame.hpText:SetText(curHP .. " / " .. maxHP .. " (" .. pct .. "%)")
    end

    -- Recurso (mana / rage / energy / focus)
    local pType  = UnitPowerType("player") or 0
    local curRes = UnitMana("player") or 0
    local maxRes = UnitManaMax("player") or 0

    if maxRes > 0 then
        self.frame.resBar:Show()
        self.frame.resBar:SetMinMaxValues(0, maxRes)
        self.frame.resBar:SetValue(curRes)

        local c = CFG.Resource.colors[pType] or CFG.Resource.colors[0]
        self.frame.resBar:SetStatusBarColor(c.r, c.g, c.b, c.a)

        if CFG.Resource.showText then
            if pType == 1 then
                self.frame.resText:SetText(curRes .. " Rage")
            elseif pType == 3 then
                self.frame.resText:SetText(curRes .. " Energy")
            else
                self.frame.resText:SetText(curRes .. " / " .. maxRes)
            end
        end
    else
        self.frame.resBar:Hide()
    end
end

-- ============================================================================
-- LÓGICA: ATUALIZAÇÃO DOS COMBO POINTS (somente Rogue)
-- ============================================================================

function PF:UpdateComboPoints()
    if not self.frame then return end

    local _, playerClass = UnitClass("player")
    playerClass = playerClass or ""

    if playerClass ~= "ROGUE" then
        self.frame.comboContainer:Hide()
        return
    end

    local cpCount = GetComboPoints("target") or GetComboPoints() or 0

    self.frame.comboContainer:Show()

    for i = 1, CFG.ComboPoints.count do
        local cp = self.frame.comboPoints[i]
        if cp then
            if i <= cpCount then
                cp.fill:Show()
                if i == CFG.ComboPoints.count then
                    cp.fill:SetVertexColor(
                        CFG.ComboPoints.colorFull.r,
                        CFG.ComboPoints.colorFull.g,
                        CFG.ComboPoints.colorFull.b,
                        CFG.ComboPoints.colorFull.a
                    )
                else
                    cp.fill:SetVertexColor(
                        CFG.ComboPoints.colorNormal.r,
                        CFG.ComboPoints.colorNormal.g,
                        CFG.ComboPoints.colorNormal.b,
                        CFG.ComboPoints.colorNormal.a
                    )
                end
            else
                cp.fill:Hide()
            end
        end
    end
end

-- ============================================================================
-- LÓGICA: ATUALIZAÇÃO COMPLETA (portrait + crest + barras + combo)
-- ============================================================================

function PF:Update()
    if not self.frame then return end
    self.frame:Show()

    -- Portrait
    SetPortraitTexture(self.frame.portrait, "player")

    -- Moldura da classe sobre o portrait
    local _, playerClass = UnitClass("player")
    playerClass = playerClass or "DEFAULT"
    if self.frame.portraitFrame then
        self.frame.portraitFrame:SetWidth(CFG.Portrait.frameWidth)
        self.frame.portraitFrame:SetHeight(CFG.Portrait.frameHeight)
        self.frame.portraitFrame:ClearAllPoints()
        self.frame.portraitFrame:SetPoint("LEFT", self.frame, "LEFT", CFG.Portrait.frameOffsetX, CFG.Portrait.frameOffsetY)
        self.frame.portraitFrame:SetTexture(
            "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Portraits\\" .. playerClass .. ".tga"
        )
        if CFG.Portrait.frameShow then
            self.frame.portraitFrame:Show()
        else
            self.frame.portraitFrame:Hide()
        end
    end

    -- Crest da classe e nome
    self.frame.crestTex:SetTexture(
        "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Crests\\" .. playerClass .. ".tga"
    )
    self.frame.nameText:SetText(UnitName("player") or "")

    self:UpdateBars()
    self:UpdateComboPoints()
end

-- ============================================================================
-- LÓGICA: ESCONDER FRAMES PADRÃO DA BLIZZARD
-- ============================================================================

function PF:HideDefaultBars()
    if PlayerFrame then
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:Hide()
        PlayerFrame:SetAlpha(0)
        PlayerFrame.Show = function() end
    end

    if ComboFrame then
        ComboFrame:UnregisterAllEvents()
        ComboFrame:Hide()
        ComboFrame:SetAlpha(0)
        ComboFrame.Show = function() end
    end

    local castBarsToHide = {
        "CastingBarFrame",
        "tDFImprovedCastbar",
        "tDFImprovedCastbarFrame",
        "tDFCastbar",
        "tDF_Castbar",
        "tDFTargetCastbar",
        "tDF_TargetCastbar",
    }
    for _, barName in ipairs(castBarsToHide) do
        local bar = getglobal(barName)
        if bar then
            bar:UnregisterAllEvents()
            bar:Hide()
            bar:SetAlpha(0)
            bar.Show = function() end
        end
    end
end
