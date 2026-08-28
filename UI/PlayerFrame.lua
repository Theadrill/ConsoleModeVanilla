--[[
    ConsoleMode - Vanilla
    UI/PlayerFrame.lua - Player Frame Console HUD
    
    Recursos:
    - Medalhão Circular à Esquerda com o Retrato do Jogador
    - Barra de Vida Verde Vibrante Superior
    - Barra de Recursos (Mana / Fúria / Energia) Inferior
    - Damage Trail suave pós-dano
    - Texto de HP e Recursos limpo e integrado
    - Ocultação segura do PlayerFrame original da Blizzard
    - Movível com Shift + Drag e resetável com /cm resetui
]]

local CM = ConsoleMode
CM.ui = CM.ui or {}
CM.ui.playerFrame = CM.ui.playerFrame or {}
local PF = CM.ui.playerFrame

PF.frame = nil
PF.damageTrailVal = 0
PF.damageTrailTimer = 0

-- ============================================================================
-- ⚙️ CONFIGURAÇÃO DE LAYOUT DO PLAYER FRAME (Ajuste suas posições e tamanhos aqui!)
-- ============================================================================
PF.Layout = {
    -- 1. Placa de Pedra Integral (Full Frame Background)
    Panel = {
        width = 250,            -- Largura total do painel de pedra
        height = 116,           -- Altura total do painel de pedra
        initialX = 20,          -- Posição X inicial na tela
        initialY = -20,         -- Posição Y inicial na tela
    },

    -- 2. Retrato do Jogador (Nicho Esquerdo de Pedra)
    Portrait = {
        width = 64,             -- Largura do nicho do retrato
        height = 64,            -- Altura do nicho do retrato
        offsetX = 16,           -- Posição X em relação ao lado esquerdo do painel
        offsetY = 2,            -- Posição Y em relação ao centro vertical
        faceWidth = 60,         -- Largura do rosto 2D/3D
        faceHeight = 60,        -- Altura do rosto 2D/3D
    },

    -- 3. Badge de Nível (Canto inferior direito do retrato)
    LevelBadge = {
        width = 20,             -- Largura do badge de nível
        height = 20,            -- Altura do badge de nível
        offsetX = 2,            -- Posição X em relação ao canto do retrato
        offsetY = -2,           -- Posição Y em relação ao canto do retrato
    },

    -- 4. Container e Brasão do Nome do Jogador
    Name = {
        width = 130,            -- Largura do brasão do nome
        height = 80,            -- Altura do brasão do nome
        offsetX = 70,           -- Posição X em relação ao topo esquerdo do painel
        offsetY = 25,           -- Posição Y em relação ao topo esquerdo do painel
        textOffsetY = 8,        -- Offset Y do texto dentro do brasão
    },

    -- 5. Barra de Conjuramento (Cast Bar) - Fica ACIMA da barra de vida
    CastBar = {
        width = 140,            -- Largura da barra de cast
        height = 18,            -- Altura da barra de cast
        offsetX = 90,           -- Posição X em relação ao topo esquerdo do painel
        offsetY = -28,          -- Posição Y em relação ao topo esquerdo do painel
        alwaysShow = true,      -- ⬅️ Deixa a moldura da barra de cast SEMPRE visível
    },

    -- 6. Barra de Vida (HP)
    HP = {
        width = 140,            -- Largura da barra de vida
        height = 18,            -- Altura da barra de vida
        offsetX = 90,           -- Posição X em relação ao topo esquerdo do painel
        offsetY = -48,          -- Posição Y em relação ao topo esquerdo do painel
    },

    -- 7. Barra de Recursos (Mana / Fúria / Energia)
    Power = {
        width = 120,            -- Largura da barra de poder
        height = 14,            -- Altura da barra de poder
        offsetY = -4,           -- Espaçamento Y abaixo da barra de vida
    },

    -- 8. Combo Points (5 Losangos de Ladino / Druida)
    ComboPoints = {
        size = 13,              -- Tamanho de cada losango
        spacing = 15,           -- Espaçamento horizontal entre os losangos
        offsetX = 0,            -- Deslocamento Horizontal (X) em relação à barra de recursos
        offsetY = 2,            -- Deslocamento Vertical (Y) -> Números maiores SOBEM!
    },
}

function PF:Initialize()
    if self.frame then
        self:HideDefaultBars()
        self:Update()
        return
    end

    local cfg = PF.Layout

    -- Container Principal da Placa de Pedra
    local f = CreateFrame("Button", "ConsoleModePlayerFrame", UIParent)
    f:SetWidth(cfg.Panel.width)
    f:SetHeight(cfg.Panel.height)
    
    if CM.ui and CM.ui.MakeMovable then
        CM.ui:MakeMovable(f, "PlayerFrame", "TOPLEFT", "TOPLEFT", cfg.Panel.initialX, cfg.Panel.initialY, "Player Frame")
    else
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", cfg.Panel.initialX, cfg.Panel.initialY)
    end
    
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Função unificada de clique do PlayerFrame
    local function OnPlayerFrameClick()
        if arg1 == "LeftButton" then
            TargetUnit("player")
        elseif arg1 == "RightButton" and PlayerFrameDropDown then
            HideDropDownMenu(1)
            PlayerFrameDropDown.point = "TOPLEFT"
            PlayerFrameDropDown.relativePoint = "BOTTOMLEFT"
            ToggleDropDownMenu(1, nil, PlayerFrameDropDown, f:GetName(), 0, 0)
        end
    end

    f:SetScript("OnClick", OnPlayerFrameClick)

    local function MakeSubClickable(sub)
        sub:EnableMouse(true)
        sub:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        sub:SetScript("OnClick", OnPlayerFrameClick)
        sub:SetScript("OnMouseDown", function()
            if IsShiftKeyDown() and arg1 == "LeftButton" then
                f:StartMoving()
                f.isMoving = true
            end
        end)
        sub:SetScript("OnMouseUp", function()
            if f.isMoving then
                f:StopMovingOrSizing()
                f.isMoving = false
                if CM.ui and CM.ui.SaveFramePosition then
                    CM.ui:SaveFramePosition("PlayerFrame", f)
                end
            end
        end)
    end

    -- 1. Textura da Placa de Pedra Integral (Full Frame Background)
    local panelBg = f:CreateTexture(nil, "BACKGROUND")
    panelBg:SetAllPoints(f)
    panelBg:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\Frames\\DEFAULT.tga")
    f.panelBg = panelBg

    -- 2. Retrato do Jogador (Encaixado no nicho esquerdo de pedra)
    local portraitFrame = CreateFrame("Button", "ConsoleModePlayerPortraitFrame", f)
    portraitFrame:SetWidth(cfg.Portrait.width)
    portraitFrame:SetHeight(cfg.Portrait.height)
    portraitFrame:SetPoint("LEFT", f, "LEFT", cfg.Portrait.offsetX, cfg.Portrait.offsetY)
    MakeSubClickable(portraitFrame)

    -- Fundo escuro do retrato atras do rosto
    local portraitBg = portraitFrame:CreateTexture(nil, "BACKGROUND")
    portraitBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    portraitBg:SetAllPoints(portraitFrame)
    portraitBg:SetVertexColor(0.04, 0.04, 0.04, 0.95)

    -- Rosto 2D/3D do personagem
    local portraitTex = portraitFrame:CreateTexture(nil, "ARTWORK")
    portraitTex:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
    portraitTex:SetWidth(cfg.Portrait.faceWidth)
    portraitTex:SetHeight(cfg.Portrait.faceHeight)
    portraitTex:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    f.portrait = portraitTex
    f.portraitFrame = portraitFrame

    -- Badge de Nível no canto inferior direito do retrato
    local levelBadge = CreateFrame("Frame", "ConsoleModePlayerLevelBadge", portraitFrame)
    levelBadge:SetWidth(cfg.LevelBadge.width)
    levelBadge:SetHeight(cfg.LevelBadge.height)
    levelBadge:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", cfg.LevelBadge.offsetX, cfg.LevelBadge.offsetY)
    levelBadge:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    levelBadge:SetBackdropColor(0.06, 0.06, 0.06, 1.0)
    levelBadge:SetBackdropBorderColor(0.65, 0.65, 0.65, 1.0)

    local levelText = levelBadge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelText:SetPoint("CENTER", levelBadge, "CENTER", 0, 0)
    levelText:SetText(tostring(UnitLevel("player") or 1))
    f.levelText = levelText

    -- 3. Container e Brasão do Nome do Jogador
    local nameFrame = CreateFrame("Frame", "ConsoleModePlayerNameFrame", f)
    nameFrame:SetWidth(cfg.Name.width)
    nameFrame:SetHeight(cfg.Name.height)
    nameFrame:SetPoint("TOPLEFT", f, "TOPLEFT", cfg.Name.offsetX, cfg.Name.offsetY)
    nameFrame:SetFrameLevel(f:GetFrameLevel() + 1)
    f.nameFrame = nameFrame

    -- Textura de Fundo do Brasão
    local nameBg = nameFrame:CreateTexture(nil, "BACKGROUND")
    nameBg:SetAllPoints(nameFrame)
    nameBg:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\NamePlate_Crest.tga")
    f.nameBg = nameBg

    -- Texto do Nome do Jogador
    local nameText = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("CENTER", nameFrame, "CENTER", 0, cfg.Name.textOffsetY)
    nameText:SetText(UnitName("player") or "")
    f.nameText = nameText

    -- 4. Barra de Conjuramento / Cast Bar (Fica ACIMA da Barra de Vida)
    local castBg = CreateFrame("Frame", "ConsoleModePlayerCastBg", f)
    castBg:SetPoint("TOPLEFT", f, "TOPLEFT", cfg.CastBar.offsetX, cfg.CastBar.offsetY)
    castBg:SetWidth(cfg.CastBar.width)
    castBg:SetHeight(cfg.CastBar.height)
    castBg:SetFrameLevel(f:GetFrameLevel() + 3)
    castBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    castBg:SetBackdropColor(0.08, 0.08, 0.08, 1.0)
    castBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    if cfg.CastBar.alwaysShow then
        castBg:Show()
    else
        castBg:Hide()
    end
    f.castBg = castBg

    local castBar = CreateFrame("StatusBar", "ConsoleModePlayerCastBar", castBg)
    castBar:SetPoint("TOPLEFT", castBg, "TOPLEFT", 1, -1)
    castBar:SetPoint("BOTTOMRIGHT", castBg, "BOTTOMRIGHT", -1, 1)
    castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    castBar:SetStatusBarColor(1.0, 0.75, 0.0, 1.0) -- Amarelo Dourado
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    f.castBar = castBar

    local castSpellText = castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    castSpellText:SetPoint("LEFT", castBar, "LEFT", 4, 0)
    castSpellText:SetText("")
    f.castSpellText = castSpellText

    local castTimeText = castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    castTimeText:SetPoint("RIGHT", castBar, "RIGHT", -4, 0)
    castTimeText:SetText("")
    f.castTimeText = castTimeText

    local function ResetCastBar()
        PF.isCasting = false
        PF.isChanneling = false
        if cfg.CastBar.alwaysShow then
            f.castBar:SetValue(0)
            f.castSpellText:SetText("")
            f.castTimeText:SetText("")
            f.castBg:Show()
        else
            f.castBg:Hide()
        end
    end

    -- 5. Fundo da Barra de Vida (Encaixado no painel direito de pedra)
    local hpBg = CreateFrame("Button", "ConsoleModePlayerHPBg", f)
    hpBg:SetPoint("TOPLEFT", f, "TOPLEFT", cfg.HP.offsetX, cfg.HP.offsetY)
    hpBg:SetWidth(cfg.HP.width)
    hpBg:SetHeight(cfg.HP.height)
    hpBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    hpBg:SetBackdropColor(0.06, 0.06, 0.06, 1.0)
    hpBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1.0)
    MakeSubClickable(hpBg)
    f.hpBg = hpBg

    -- Damage Trail Amarelo (Decaimento suave)
    local trailBar = CreateFrame("StatusBar", "ConsoleModePlayerDamageTrail", hpBg)
    trailBar:SetPoint("TOPLEFT", hpBg, "TOPLEFT", 2, -2)
    trailBar:SetPoint("BOTTOMRIGHT", hpBg, "BOTTOMRIGHT", -2, 2)
    trailBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    trailBar:SetStatusBarColor(0.95, 0.8, 0.1, 0.85) -- Amarelo dano
    trailBar:SetMinMaxValues(0, 1)
    trailBar:SetValue(0)
    f.trailBar = trailBar

    -- Barra de Vida Principal (Verde Esmeralda)
    local hpBar = CreateFrame("StatusBar", "ConsoleModePlayerHPBar", hpBg)
    hpBar:SetPoint("TOPLEFT", hpBg, "TOPLEFT", 2, -2)
    hpBar:SetPoint("BOTTOMRIGHT", hpBg, "BOTTOMRIGHT", -2, 2)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(0.12, 0.85, 0.2, 1.0) -- Verde Esmeralda
    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(1)
    hpBar:SetFrameLevel(trailBar:GetFrameLevel() + 1)
    f.hpBar = hpBar

    -- Texto de Vida
    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hpText:SetPoint("CENTER", hpBar, "CENTER", 0, 0)
    f.hpText = hpText

    -- 6. Fundo da Barra de Mana / Poder
    local mpBg = CreateFrame("Button", "ConsoleModePlayerMPBg", f)
    mpBg:SetPoint("TOPLEFT", hpBg, "BOTTOMLEFT", 0, cfg.Power.offsetY)
    mpBg:SetWidth(cfg.Power.width)
    mpBg:SetHeight(cfg.Power.height)
    mpBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    mpBg:SetBackdropColor(0.06, 0.06, 0.06, 1.0)
    mpBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1.0)
    MakeSubClickable(mpBg)
    f.mpBg = mpBg

    -- Barra de Recursos Principal (Azul / Amarelo / Vermelho)
    local mpBar = CreateFrame("StatusBar", "ConsoleModePlayerMPBar", mpBg)
    mpBar:SetPoint("TOPLEFT", mpBg, "TOPLEFT", 2, -2)
    mpBar:SetPoint("BOTTOMRIGHT", mpBg, "BOTTOMRIGHT", -2, 2)
    mpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    mpBar:SetStatusBarColor(0.0, 0.55, 1.0, 1.0)
    mpBar:SetMinMaxValues(0, 1)
    mpBar:SetValue(1)
    f.mpBar = mpBar

    -- Texto de Mana
    local mpText = mpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mpText:SetPoint("CENTER", mpBar, "CENTER", 0, 0)
    mpText:SetText("")
    f.mpText = mpText

    -- 7. Combo Points (5 Losangos / Diamantes perfeitamente alinhados na borda esquerda)
    local comboContainer = CreateFrame("Frame", "ConsoleModePlayerComboPoints", f)
    comboContainer:SetPoint("TOPLEFT", mpBg, "BOTTOMLEFT", cfg.ComboPoints.offsetX, cfg.ComboPoints.offsetY)
    comboContainer:SetWidth(cfg.ComboPoints.spacing * 5)
    comboContainer:SetHeight(16)
    f.comboContainer = comboContainer
    f.comboPoints = {}

    for i = 1, 5 do
        local cp = CreateFrame("Frame", "ConsoleModePlayerCP" .. i, comboContainer)
        cp:SetWidth(cfg.ComboPoints.size)
        cp:SetHeight(cfg.ComboPoints.size)
        cp:SetPoint("LEFT", comboContainer, "LEFT", (i - 1) * cfg.ComboPoints.spacing, 0)

        -- Losango de Fundo / Slot Inativo
        local empty = cp:CreateTexture(nil, "BACKGROUND")
        empty:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\CP_Diamond_Empty.tga")
        empty:SetAllPoints(cp)
        cp.empty = empty

        -- Losango Ativo (Preenchido e Colorido)
        local fill = cp:CreateTexture(nil, "ARTWORK")
        fill:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\CP_Diamond_Fill.tga")
        fill:SetAllPoints(cp)
        fill:Hide()
        cp.fill = fill

        f.comboPoints[i] = cp
    end

    -- Damage Trail e Cast Bar no OnUpdate
    f:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0.016

        -- 1. Damage Trail
        if PF.curHP and PF.damageTrailVal > PF.curHP then
            PF.damageTrailTimer = PF.damageTrailTimer + elapsed
            if PF.damageTrailTimer > 0.35 then
                local speed = (PF.damageTrailVal - PF.curHP) * 5 * elapsed
                PF.damageTrailVal = PF.damageTrailVal - speed
                if PF.damageTrailVal <= PF.curHP then
                    PF.damageTrailVal = PF.curHP
                end
                PF.frame.trailBar:SetValue(PF.damageTrailVal)
            end
        elseif PF.curHP then
            PF.damageTrailVal = PF.curHP
            PF.frame.trailBar:SetValue(PF.curHP)
            PF.damageTrailTimer = 0
        end

        -- 2. Cast Bar (Conjurando)
        if PF.isCasting and PF.castDuration and PF.castDuration > 0 then
            PF.castValue = PF.castValue + elapsed
            if PF.castValue >= PF.castDuration then
                PF.castValue = PF.castDuration
                ResetCastBar()
            else
                f.castBar:SetValue(PF.castValue)
                local rem = PF.castDuration - PF.castValue
                f.castTimeText:SetText(string.format("%.1fs", rem))
            end
        -- 3. Cast Bar (Canalizando)
        elseif PF.isChanneling and PF.channelDuration and PF.channelDuration > 0 then
            PF.channelValue = PF.channelValue - elapsed
            if PF.channelValue <= 0 then
                PF.channelValue = 0
                ResetCastBar()
            else
                f.castBar:SetValue(PF.channelValue)
                f.castTimeText:SetText(string.format("%.1fs", PF.channelValue))
            end
        end
    end)

    -- Eventos de Status e Spellcast
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
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
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
            PF:Update()
            -- Delay de garantia para o modelo 3D do personagem carregar ao logar
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
                SetPortraitTexture(f.portrait, "player")
            end
        elseif event == "PLAYER_COMBO_POINTS" or event == "PLAYER_TARGET_CHANGED" then
            PF:Update()
        elseif event == "SPELLCAST_START" then
            -- arg1 = spell name, arg2 = duration in ms
            local spellName = arg1 or ""
            local durationSec = (arg2 or 0) / 1000
            if durationSec > 0 then
                PF.isCasting = true
                PF.isChanneling = false
                PF.castValue = 0
                PF.castDuration = durationSec
                f.castBar:SetMinMaxValues(0, durationSec)
                f.castBar:SetValue(0)
                f.castBar:SetStatusBarColor(1.0, 0.75, 0.0, 1.0) -- Amarelo Dourado
                f.castSpellText:SetText(spellName)
                f.castTimeText:SetText(string.format("%.1fs", durationSec))
                f.castBg:Show()
            end
        elseif event == "SPELLCAST_STOP" then
            if PF.isCasting then
                ResetCastBar()
            end
        elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
            ResetCastBar()
        elseif event == "SPELLCAST_DELAYED" then
            -- arg1 = delay in ms
            if PF.isCasting and PF.castDuration then
                local delaySec = (arg1 or 0) / 1000
                PF.castDuration = PF.castDuration + delaySec
                f.castBar:SetMinMaxValues(0, PF.castDuration)
            end
        elseif event == "SPELLCAST_CHANNEL_START" then
            -- arg1 = duration in ms, arg2 = spell name
            local durationSec = (arg1 or 0) / 1000
            local spellName = arg2 or ""
            if durationSec > 0 then
                PF.isChanneling = true
                PF.isCasting = false
                PF.channelValue = durationSec
                PF.channelDuration = durationSec
                f.castBar:SetMinMaxValues(0, durationSec)
                f.castBar:SetValue(durationSec)
                f.castBar:SetStatusBarColor(0.2, 0.8, 1.0, 1.0) -- Azul Claro Canalizado
                f.castSpellText:SetText(spellName)
                f.castTimeText:SetText(string.format("%.1fs", durationSec))
                f.castBg:Show()
            end
        elseif event == "SPELLCAST_CHANNEL_UPDATE" then
            -- arg1 = remaining duration in ms
            if PF.isChanneling then
                local remSec = (arg1 or 0) / 1000
                PF.channelValue = remSec
            end
        elseif event == "SPELLCAST_CHANNEL_STOP" then
            if PF.isChanneling then
                ResetCastBar()
            end
        elseif arg1 == "player" then
            PF:Update()
        end
    end)

    self.frame = f
    self:HideDefaultBars()
    self:Update()
    f:Show()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Player]|r PlayerFrame inicializado com sucesso!")
end

function PF:HideDefaultBars()
    if PlayerFrame then
        PlayerFrame:Hide()
        PlayerFrame:UnregisterAllEvents()
        PlayerFrame:SetAlpha(0)
        PlayerFrame.Show = function() end
    end

    if ComboFrame then
        ComboFrame:Hide()
        ComboFrame:UnregisterAllEvents()
        ComboFrame:SetAlpha(0)
        ComboFrame.Show = function() end
    end

    local defaultCastBars = {
        "CastingBarFrame",
        "tDFImprovedCastbar",
        "tDFImprovedCastbarFrame",
        "tDFCastbar",
        "tDF_Castbar",
        "tDFTargetCastbar",
        "tDF_TargetCastbar",
    }

    for _, barName in ipairs(defaultCastBars) do
        local bar = getglobal(barName)
        if bar then
            bar:Hide()
            bar:UnregisterAllEvents()
            bar:SetAlpha(0)
            bar.Show = function() end
        end
    end
end

function PF:Update()
    if not self.frame then return end
    self.frame:Show()

    -- 1. Nome e Nível
    local name = UnitName("player") or "Jogador"
    self.frame.nameText:SetText(name)
    self.frame.levelText:SetText(tostring(UnitLevel("player") or 1))

    -- 2. Retrato e Placa de Classe Integral
    SetPortraitTexture(self.frame.portrait, "player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass or "DEFAULT"
    local classFrameTex = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Frames\\" .. playerClass .. ".tga"
    self.frame.panelBg:SetTexture(classFrameTex)

    -- 3. Vida
    local curHP = UnitHealth("player") or 0
    local maxHP = UnitHealthMax("player") or 1
    self.curHP = curHP

    self.frame.hpBar:SetMinMaxValues(0, maxHP)
    self.frame.hpBar:SetValue(curHP)

    self.frame.trailBar:SetMinMaxValues(0, maxHP)
    if not self.damageTrailVal or self.damageTrailVal < curHP or self.damageTrailVal > maxHP then
        self.damageTrailVal = curHP
        self.frame.trailBar:SetValue(curHP)
    end

    local hpPct = maxHP > 0 and math.floor((curHP / maxHP) * 100) or 0
    self.frame.hpText:SetText(curHP .. " / " .. maxHP .. " (" .. hpPct .. "%)")

    -- 4. Poder / Furia / Mana / Energia
    local pType = UnitPowerType("player")
    local curPower = UnitMana("player") or 0
    local maxPower = UnitManaMax("player") or 1

    if maxPower > 0 then
        self.frame.mpBg:Show()
        self.frame.mpBar:SetMinMaxValues(0, maxPower)
        self.frame.mpBar:SetValue(curPower)

        if pType == 0 then
            self.frame.mpBar:SetStatusBarColor(0.0, 0.55, 1.0, 1.0) -- Azul Mana
        elseif pType == 1 then
            self.frame.mpBar:SetStatusBarColor(0.9, 0.15, 0.15, 1.0) -- Vermelho Furia
        elseif pType == 2 then
            self.frame.mpBar:SetStatusBarColor(1.0, 0.5, 0.0, 1.0)   -- Laranja Foco
        elseif pType == 3 then
            self.frame.mpBar:SetStatusBarColor(1.0, 0.85, 0.1, 1.0)  -- Amarelo Energia
        else
            self.frame.mpBar:SetStatusBarColor(0.0, 0.55, 1.0, 1.0)
        end

        if pType == 1 then
            self.frame.mpText:SetText(curPower .. " Rage")
        elseif pType == 3 then
            self.frame.mpText:SetText(curPower .. " Energy")
        else
            self.frame.mpText:SetText(curPower .. " / " .. maxPower)
        end
    else
        self.frame.mpBg:Hide()
    end

    -- 5. Combo Points (5 Losangos / Diamantes)
    local cpCount = GetComboPoints("target") or GetComboPoints() or 0
    local _, playerClass = UnitClass("player")
    local isComboClass = (playerClass == "ROGUE" or playerClass == "DRUID")
    
    if isComboClass and self.frame.comboContainer then
        self.frame.comboContainer:Show()
        for i = 1, 5 do
            local cp = self.frame.comboPoints[i]
            if cp and cp.fill and cp.empty then
                if i <= cpCount then
                    cp.fill:Show()
                    if i == 5 then
                        -- 5º Ponto: Vermelho / Laranja Finalizador
                        cp.fill:SetVertexColor(1.0, 0.22, 0.05, 1.0)
                    else
                        -- 1 a 4 Pontos: Amarelo Dourado Brilhante
                        cp.fill:SetVertexColor(1.0, 0.85, 0.0, 1.0)
                    end
                else
                    cp.fill:Hide()
                end
            end
        end
    elseif self.frame.comboContainer then
        self.frame.comboContainer:Hide()
    end
end
