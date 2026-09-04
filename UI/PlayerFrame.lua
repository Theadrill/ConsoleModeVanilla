--[[
    ConsoleMode - Vanilla
    UI/PlayerFrame.lua - Player Frame Console HUD

    Layout (3 Linhas x 3 Colunas):
      Linha 1 (Topo): [        ] [ BreathBar ] [          ]
      Linha 2 (Meio): [ HP bar ] [  Castbar  ] [ Resource ]
      Linha 3 (Base): [        ] [ Combo Pts ] [          ]
      [Portrait] esquerda, [Crest] abaixo do portrait

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
    gapX  = 26,   -- espaço horizontal entre portrait e container de barras (px)

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
    rowGap      = 6,     -- espaço vertical entre Linha 1 (Breath) e Linha 2 (HP/Cast/Recurso) (px)

    col1Width   = 140,   -- largura da barra de HP        (px)
    col2Width   = 140,   -- largura da castbar             (px)
    col3Width   = 140,   -- largura da barra de recurso    (px)
}

-- ----------------------------------------------------------------------------
-- BARRA DE RESPIRACAO (Linha 1, Coluna 2 — so visivel submerso)
-- Barra azul de agua que aparece quando MIRROR_TIMER BREATH inicia.
-- ----------------------------------------------------------------------------
CFG.Breath = {
    color     = { r = 0.0, g = 0.55, b = 1.0, a = 1.0 },  -- azul agua
    textFont  = "GameFontHighlightSmall",
    textSize  = nil,
    textColor = { r = 1.0, g = 1.0, b = 1.0 },
}

-- ----------------------------------------------------------------------------
-- AURAS - BUFFS E DEBUFFS (Coluna 1 - Grid Vertical)
-- Buffs acima da barra de HP (max 21 = 7 cols x 3 rows) crescem para cima.
-- Debuffs abaixo da barra de HP (max 14 = 7 cols x 2 rows) crescem para baixo.
-- ----------------------------------------------------------------------------
CFG.Auras = {
    size          = 18,   -- tamanho do icone quadrado (px)
    gap           = 2,    -- espaco entre icones adjacentes (px)
    maxCols       = 7,    -- maximo por linha (7 * 20px = 140px, largura da coluna 1)
    maxBuffRows   = 3,    -- maximo de linhas de buffs (cresce para cima)
    maxDebuffRows = 2,    -- maximo de linhas de debuffs (cresce para baixo)
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

-- ----------------------------------------------------------------------------
-- ÍCONE DE DESCANSO (ZZZ)
-- Posição e tamanho do indicador de descanso sobre o portrait.
-- ----------------------------------------------------------------------------
CFG.RestIcon = {
    show        = true,
    size        = 24,                       -- Tamanho do ícone (px)
    anchor      = "TOPLEFT",
    relAnchor   = "TOPLEFT",
    offsetX     = -4,                       -- Deslocamento X
    offsetY     = 2,                        -- Deslocamento Y
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

    -- Migracao: se posicao salva anterior era deslocada (x == -180), restaura para centro (0)
    -- para que o usuario veja o ajuste imediatamente apos /reload sem reset manual
    if ConsoleModeDB and ConsoleModeDB.positions and ConsoleModeDB.positions["PlayerFrame"] then
        local saved = ConsoleModeDB.positions["PlayerFrame"]
        if saved.x == -180 then
            saved.x = CFG.Anchor.defaultX
            f:ClearAllPoints()
            f:SetPoint(saved.point or CFG.Anchor.point, UIParent, saved.relPoint or CFG.Anchor.relPoint, saved.x, saved.y)
        end
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
    -- ÍCONE DE DESCANSO (ZZZ) COM FADE SUAVE
    -- Aparece sobre o portrait quando o personagem está descansando.
    -- FrameLevel maior que portraitFrame para ficar visível acima da moldura.
    -- -----------------------------------------------------------------------

    local function SuppressExternalRestIcons()
        local names = {
            "PlayerStatusIcon",
            "PlayerRestGlow",
            "PlayerRestIcon",
            "overlay",
            "DragonflightPlayerRestIcon",
            "TurtlePlayerRestIcon",
            "XPerl_Player_RestStatus",
        }
        for _, name in ipairs(names) do
            local obj = getglobal(name)
            if obj then
                if obj.UnregisterAllEvents then
                    obj:UnregisterAllEvents()
                end
                if obj.SetScript then
                    obj:SetScript("OnUpdate", nil)
                    obj:SetScript("OnEvent", nil)
                end
                if obj.Hide then
                    obj:Hide()
                end
                if obj.SetAlpha then
                    obj:SetAlpha(0)
                end
                if obj.SetTexture then
                    obj:SetTexture("")
                end
                obj.Show = function() end
            end
        end

        if PlayerFrame_UpdateStatus and not PlayerFrame_UpdateStatus_Hooked then
            PlayerFrame_UpdateStatus_Hooked = true
            local orig_UpdateStatus = PlayerFrame_UpdateStatus
            PlayerFrame_UpdateStatus = function()
                orig_UpdateStatus()
                if PlayerStatusIcon then PlayerStatusIcon:Hide() end
                if PlayerRestGlow then PlayerRestGlow:Hide() end
                if PlayerRestIcon then PlayerRestIcon:Hide() end
            end
        end
    end

    local restIcon = CreateFrame("Frame", "ConsoleModePlayerRestIcon", f)
    restIcon:SetWidth(CFG.RestIcon.size or 24)
    restIcon:SetHeight(CFG.RestIcon.size or 24)
    restIcon:SetPoint(
        CFG.RestIcon.anchor or "TOPLEFT",
        portrait,
        CFG.RestIcon.relAnchor or "TOPLEFT",
        CFG.RestIcon.offsetX or -4,
        CFG.RestIcon.offsetY or 2
    )
    restIcon:SetFrameLevel(f:GetFrameLevel() + 3)

    local restIconTex = restIcon:CreateTexture(nil, "OVERLAY")
    restIconTex:SetAllPoints(restIcon)
    restIconTex:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    restIconTex:SetTexCoord(0, 0.5, 0, 0.421875)

    function restIcon:UpdateResting()
        SuppressExternalRestIcons()
        if CFG.RestIcon.show and IsResting() then
            self:Show()
        else
            self:Hide()
        end
    end

    restIcon:RegisterEvent("PLAYER_UPDATE_RESTING")
    restIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    restIcon:SetScript("OnEvent", function()
        restIcon:UpdateResting()
    end)

    SuppressExternalRestIcons()
    restIcon:UpdateResting()
    f.restIcon = restIcon

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
    -- LINHA 1 — BARRA DE RESPIRACAO (BreathBar) — Coluna 2 Centro, acima da Linha 2
    -- Largura = col2Width, altura = CFG.Bars.height, gap vertical = CFG.Bars.rowGap
    -- Inicia oculta, aparece apenas ao nadar submerso (MIRROR_TIMER BREATH).
    -- -----------------------------------------------------------------------
    local breathBar = CreateFrame("StatusBar", "ConsoleModePlayerBreathBar", f)
    breathBar:SetWidth(CFG.Bars.col2Width)
    breathBar:SetHeight(CFG.Bars.height)
    breathBar:SetPoint("BOTTOMLEFT", barsContainer, "TOPLEFT", col2X, CFG.Bars.rowGap)
    breathBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    breathBar:SetStatusBarColor(CFG.Breath.color.r, CFG.Breath.color.g, CFG.Breath.color.b, CFG.Breath.color.a)
    breathBar:SetMinMaxValues(0, 1)
    breathBar:SetValue(1)
    breathBar:SetFrameLevel(barsContainer:GetFrameLevel() + 1)
    breathBar:Hide()
    breathBar.value = 0
    breathBar.maxValue = 1
    breathBar.scale = 1
    breathBar.paused = 0

    local breathText = breathBar:CreateFontString(nil, "OVERLAY", CFG.Breath.textFont)
    breathText:SetPoint("CENTER", breathBar, "CENTER", 0, 0)
    if CFG.Breath.textSize then
        local fontPath = breathText:GetFont()
        breathText:SetFont(fontPath, CFG.Breath.textSize)
    end
    breathText:SetTextColor(CFG.Breath.textColor.r, CFG.Breath.textColor.g, CFG.Breath.textColor.b)
    breathText:SetText("")
    breathBar.text = breathText
    f.breathBar = breathBar

    breathBar:SetScript("OnUpdate", function()
        if not this:IsVisible() then return end
        if this.paused and this.paused == 1 then return end
        local elapsed = arg1 or 0.016
        this.value = this.value - elapsed
        if this.value <= 0 then
            this.value = 0
            this:SetValue(0)
            this:Hide()
            return
        end
        this:SetValue(this.value)
        local secs = math.ceil(this.value)
        this.text:SetText("Respiracao " .. secs .. "s")
    end)



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
    -- AURAS - BUFFS E DEBUFFS (Coluna 1 - Grid Vertical)
    -- Buffs acima da HP (maxCols x maxBuffRows = 21), crescem para cima.
    -- Debuffs abaixo da HP (maxCols x maxDebuffRows = 14), crescem para baixo.
    -- Ancorados ao trailBar para respeitar rowGap especificado em CFG.Bars.rowGap.
    -- -----------------------------------------------------------------------
    local auraSize = CFG.Auras.size
    local auraGap = CFG.Auras.gap
    local auraMaxCols = CFG.Auras.maxCols
    local auraBuffMax = auraMaxCols * CFG.Auras.maxBuffRows
    local auraDebuffMax = auraMaxCols * CFG.Auras.maxDebuffRows

    local buffContainer = CreateFrame("Frame", "ConsoleModePlayerBuffs", f)
    buffContainer:SetWidth(CFG.Bars.col1Width)
    buffContainer:SetHeight(CFG.Auras.maxBuffRows * (auraSize + auraGap))
    buffContainer:SetPoint("BOTTOMLEFT", trailBar, "TOPLEFT", 0, CFG.Bars.rowGap)
    buffContainer:SetFrameLevel(barsContainer:GetFrameLevel() + 2)
    f.buffContainer = buffContainer

    local debuffContainer = CreateFrame("Frame", "ConsoleModePlayerDebuffs", f)
    debuffContainer:SetWidth(CFG.Bars.col1Width)
    debuffContainer:SetHeight(CFG.Auras.maxDebuffRows * (auraSize + auraGap))
    debuffContainer:SetPoint("TOPLEFT", trailBar, "BOTTOMLEFT", 0, -CFG.Bars.rowGap)
    debuffContainer:SetFrameLevel(barsContainer:GetFrameLevel() + 2)
    f.debuffContainer = debuffContainer

    f.buffs = {}
    f.debuffs = {}

    -- Pool de buffs (sem borda, apenas icone + contador)
    for i = 1, auraBuffMax do
        local col = math.mod((i - 1), auraMaxCols)
        local row = math.floor((i - 1) / auraMaxCols)
        local btn = CreateFrame("Button", nil, buffContainer)
        btn:SetWidth(auraSize)
        btn:SetHeight(auraSize)
        btn:SetPoint("BOTTOMLEFT", buffContainer, "BOTTOMLEFT", col * (auraSize + auraGap), row * (auraSize + auraGap))
        btn:EnableMouse(true)
        btn:RegisterForClicks("RightButtonUp")
        btn.auraIndex = i
        btn.isDebuff = false

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(btn)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        btn.iconTex = icon

        local countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
        countText:SetTextColor(1, 1, 1, 1)
        countText:SetText("")
        local cPath, cSize = countText:GetFont()
        if cPath then
            countText:SetFont(cPath, 10, "OUTLINE")
        end
        btn.countText = countText

        btn:SetScript("OnEnter", function()
            if GameTooltip then
                GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
                if this.isItemBuff and this.itemSlot then
                    GameTooltip:SetInventoryItem("player", this.itemSlot)
                elseif this.buffIndex then
                    GameTooltip:SetPlayerBuff(this.buffIndex)
                end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        btn:SetScript("OnClick", function()
            if arg1 == "RightButton" and this.buffIndex and not this.isItemBuff then
                CancelPlayerBuff(this.buffIndex)
            end
        end)

        btn:Hide()
        f.buffs[i] = btn
    end

    -- Pool de debuffs (com borda colorida por debuffType)
    for i = 1, auraDebuffMax do
        local col = math.mod((i - 1), auraMaxCols)
        local row = math.floor((i - 1) / auraMaxCols)
        local btn = CreateFrame("Button", nil, debuffContainer)
        btn:SetWidth(auraSize)
        btn:SetHeight(auraSize)
        btn:SetPoint("TOPLEFT", debuffContainer, "TOPLEFT", col * (auraSize + auraGap), -(row * (auraSize + auraGap)))
        btn:EnableMouse(true)
        btn.auraIndex = i
        btn.isDebuff = true

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(btn)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        btn.iconTex = icon

        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(btn)
        border:SetTexture("Interface\\Buttons\\UI-Debuff-Border")
        border:SetBlendMode("ADD")
        btn.borderTex = border

        local countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
        countText:SetTextColor(1, 1, 1, 1)
        countText:SetText("")
        local cPath2, cSize2 = countText:GetFont()
        if cPath2 then
            countText:SetFont(cPath2, 10, "OUTLINE")
        end
        btn.countText = countText

        btn:SetScript("OnEnter", function()
            if GameTooltip and this.buffIndex then
                GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetPlayerBuff(this.buffIndex)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)

        btn:Hide()
        f.debuffs[i] = btn
    end

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
    f:RegisterEvent("MIRROR_TIMER_START")
    f:RegisterEvent("MIRROR_TIMER_PAUSE")
    f:RegisterEvent("MIRROR_TIMER_STOP")
    f:RegisterEvent("MIRRORTIMER_START")
    f:RegisterEvent("MIRRORTIMER_PAUSE")
    f:RegisterEvent("MIRRORTIMER_STOP")
    f:RegisterEvent("PLAYER_AURAS_CHANGED")
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_INVENTORY_CHANGED")

    f:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            PF:HideDefaultBars()
            PF:UpdateAuras()
            -- Delay para o modelo do personagem terminar de carregar
            local delay = CreateFrame("Frame")
            delay.elapsed = 0
            delay:SetScript("OnUpdate", function()
                this.elapsed = this.elapsed + arg1
                if this.elapsed > 0.3 then
                    this:SetScript("OnUpdate", nil)
                    PF:Update()
                    PF:UpdateAuras()
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

        elseif event == "MIRROR_TIMER_START" or event == "MIRRORTIMER_START" then
            if arg1 == "BREATH" then
                local bb = PF.frame and PF.frame.breathBar
                if bb then
                    bb.value = (arg2 or 0) / 1000
                    bb.maxValue = (arg3 or 0) / 1000
                    bb.scale = arg4
                    bb.paused = arg5
                    bb:SetMinMaxValues(0, bb.maxValue)
                    bb:SetValue(bb.value)
                    local secs = math.ceil(bb.value)
                    bb.text:SetText("Respiracao " .. secs .. "s")
                    bb:Show()
                end
            end

        elseif event == "MIRROR_TIMER_STOP" or event == "MIRRORTIMER_STOP" then
            if arg1 == "BREATH" then
                local bb = PF.frame and PF.frame.breathBar
                if bb then bb:Hide() end
            end

        elseif event == "MIRROR_TIMER_PAUSE" or event == "MIRRORTIMER_PAUSE" then
            if arg1 == "BREATH" then
                local bb = PF.frame and PF.frame.breathBar
                if bb then
                    bb.paused = arg2 or arg5 or 0
                end
            end

        elseif event == "PLAYER_AURAS_CHANGED" then
            PF:UpdateAuras()

        elseif event == "UNIT_AURA" then
            if arg1 == "player" then PF:UpdateAuras() end

        elseif event == "UNIT_INVENTORY_CHANGED" then
            if arg1 == "player" then PF:UpdateAuras() end

        elseif arg1 == "player" then
            PF:UpdateBars()
        end
    end)

    self.frame = f
    self:HideDefaultBars()
    self:Update()
    PF:UpdateAuras()
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
-- LÓGICA: ATUALIZAÇÃO DAS AURAS (Buffs acima, Debuffs abaixo - Coluna 1)
-- ============================================================================

function PF:UpdateAuras()
    if not self.frame then return end
    if not self.frame.buffs or not self.frame.debuffs then return end

    local auraMaxBuffs = CFG.Auras.maxCols * CFG.Auras.maxBuffRows
    local auraMaxDebuffs = CFG.Auras.maxCols * CFG.Auras.maxDebuffRows

    -- Buffs: GetPlayerBuff(i, "HELPFUL") de 0 ate 31
    -- Primeiro: encantamentos temporarios de armas (GetWeaponEnchantInfo) integrados na grade de buffs
    local buffCount = 0
    if GetWeaponEnchantInfo then
        local hasMain, mainExp, mainCharges, hasOff, offExp, offCharges = GetWeaponEnchantInfo()
        if hasMain and buffCount < auraMaxBuffs then
            buffCount = buffCount + 1
            local btn = self.frame.buffs[buffCount]
            if btn then
                btn.iconTex:SetTexture(GetInventoryItemTexture("player", 16))
                btn.isItemBuff = true
                btn.itemSlot = 16
                btn.buffIndex = nil
                if mainCharges and mainCharges > 1 then
                    btn.countText:SetText(mainCharges)
                    btn.countText:Show()
                else
                    btn.countText:SetText("")
                    btn.countText:Hide()
                end
                btn:Show()
            end
        end
        if hasOff and buffCount < auraMaxBuffs then
            buffCount = buffCount + 1
            local btn = self.frame.buffs[buffCount]
            if btn then
                btn.iconTex:SetTexture(GetInventoryItemTexture("player", 17))
                btn.isItemBuff = true
                btn.itemSlot = 17
                btn.buffIndex = nil
                if offCharges and offCharges > 1 then
                    btn.countText:SetText(offCharges)
                    btn.countText:Show()
                else
                    btn.countText:SetText("")
                    btn.countText:Hide()
                end
                btn:Show()
            end
        end
    end
    for i = 0, 31 do
        local bIdx = GetPlayerBuff(i, "HELPFUL")
        if bIdx < 0 or buffCount >= auraMaxBuffs then break end
        local icon = GetPlayerBuffTexture(bIdx)
        if icon then
            buffCount = buffCount + 1
            local btn = self.frame.buffs[buffCount]
            if btn then
                local count = GetPlayerBuffApplications(bIdx)
                btn.iconTex:SetTexture(icon)
                btn.isItemBuff = false
                btn.itemSlot = nil
                btn.buffIndex = bIdx
                if count and count > 1 then
                    btn.countText:SetText(count)
                    btn.countText:Show()
                else
                    btn.countText:SetText("")
                    btn.countText:Hide()
                end
                btn:Show()
            end
        end
    end
    for j = buffCount + 1, auraMaxBuffs do
        local btn = self.frame.buffs[j]
        if btn then
            btn:Hide()
            btn.countText:SetText("")
            btn.countText:Hide()
        end
    end

    -- Debuffs: GetPlayerBuff(i, "HARMFUL") de 0 ate 15
    local debuffColors = {
        Magic   = { r = 0.2, g = 0.6, b = 1.0 },
        Curse   = { r = 0.6, g = 0.0, b = 1.0 },
        Poison  = { r = 0.0, g = 0.6, b = 0.0 },
        Disease = { r = 0.6, g = 0.4, b = 0.0 },
    }
    local debuffCount = 0
    for i = 0, 15 do
        local dIdx = GetPlayerBuff(i, "HARMFUL")
        if dIdx < 0 or debuffCount >= auraMaxDebuffs then break end
        local icon = GetPlayerBuffTexture(dIdx)
        if icon then
            debuffCount = debuffCount + 1
            local btn = self.frame.debuffs[debuffCount]
            if btn then
                local count = GetPlayerBuffApplications(dIdx)
                local debuffType = GetPlayerBuffDispelType(dIdx)
                btn.iconTex:SetTexture(icon)
                btn.buffIndex = dIdx
                if count and count > 1 then
                    btn.countText:SetText(count)
                    btn.countText:Show()
                else
                    btn.countText:SetText("")
                    btn.countText:Hide()
                end
                local col = debuffColors[debuffType] or { r = 0.8, g = 0.0, b = 0.0 }
                btn.borderTex:SetVertexColor(col.r, col.g, col.b, 1.0)
                btn:Show()
            end
        end
    end
    for j = debuffCount + 1, auraMaxDebuffs do
        local btn = self.frame.debuffs[j]
        if btn then
            btn:Hide()
            btn.countText:SetText("")
            btn.countText:Hide()
        end
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
    self:UpdateAuras()
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

    -- Ocultar barra de respiracao padrao da Blizzard (MirrorTimer BREATH)
    for i = 1, (MIRRORTIMER_NUMTIMERS or 3) do
        local mt = getglobal("MirrorTimer" .. i)
        if mt then
            mt:UnregisterAllEvents()
            mt:Hide()
            if mt.SetAlpha then mt:SetAlpha(0) end
            mt.Show = function() end
        end
    end
    if MirrorTimer_Show then
        if not PF._origMirrorTimerShow then
            PF._origMirrorTimerShow = MirrorTimer_Show
            MirrorTimer_Show = function(timer, val, maxv, scale, paused, label)
                if timer == "BREATH" then return end
                PF._origMirrorTimerShow(timer, val, maxv, scale, paused, label)
            end
        end
    end

    -- Suprimir frames de MirrorTimer de addons (turtle-dragonflight / DragonflightUI)
    local addonMirrors = {
        "DragonflightUIMirrorTimer1",
        "DragonflightUIMirrorTimer2",
        "DragonflightUIMirrorTimer3",
        "TurtleDragonflightMirrorTimer1",
        "TurtleDragonflightMirrorTimer2",
        "TurtleDragonflightMirrorTimer3",
        "DFMirrorTimer1",
        "DFMirrorTimer2",
        "DFMirrorTimer3",
        "Turtle_UIMirrorTimer1",
        "Turtle_UIMirrorTimer2",
        "Turtle_UIMirrorTimer3",
    }
    for _, barName in ipairs(addonMirrors) do
        local bar = getglobal(barName)
        if bar then
            if bar.UnregisterAllEvents then bar:UnregisterAllEvents() end
            if bar.Hide then bar:Hide() end
            if bar.SetAlpha then bar:SetAlpha(0) end
            bar.Show = function() end
        end
    end
    -- Ocultar BuffFrame padrao da Blizzard e auras de addons
    if BuffFrame then
        BuffFrame:UnregisterAllEvents()
        BuffFrame:Hide()
        if BuffFrame.SetAlpha then BuffFrame:SetAlpha(0) end
        BuffFrame.Show = function() end
    end
    local addonBuffFrames = {
        "DragonflightUIBuffFrame",
        "DragonflightUIDebuffFrame",
        "DragonflightUIAuras",
        "DFBuffFrame",
        "DFDebuffFrame",
        "TurtleDragonflightBuffFrame",
        "TurtleDragonflightDebuffFrame",
        "Turtle_UIBuffFrame",
        "Turtle_UIDebuffFrame",
    }
    for _, bfName in ipairs(addonBuffFrames) do
        local bf = getglobal(bfName)
        if bf then
            if bf.UnregisterAllEvents then bf:UnregisterAllEvents() end
            if bf.Hide then bf:Hide() end
            if bf.SetAlpha then bf:SetAlpha(0) end
            bf.Show = function() end
        end
    end

    if TemporaryEnchantFrame then
        TemporaryEnchantFrame:UnregisterAllEvents()
        TemporaryEnchantFrame:Hide()
        if TemporaryEnchantFrame.SetAlpha then TemporaryEnchantFrame:SetAlpha(0) end
        TemporaryEnchantFrame.Show = function() end
    end
end
