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

function PF:Initialize()
    if self.frame then
        self:HideDefaultBars()
        self:Update()
        return
    end

    -- Container Principal
    local f = CreateFrame("Button", "ConsoleModePlayerFrame", UIParent)
    f:SetWidth(360)
    f:SetHeight(96)
    
    if CM.ui and CM.ui.MakeMovable then
        CM.ui:MakeMovable(f, "PlayerFrame", "TOPLEFT", "TOPLEFT", 20, -20, "Player Frame")
    else
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)
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

    -- 1. Retrato do Jogador com Moldura Tematica por Classe (+50% maior: 84x84)
    local portraitFrame = CreateFrame("Button", "ConsoleModePlayerPortraitFrame", f)
    portraitFrame:SetWidth(84)
    portraitFrame:SetHeight(84)
    portraitFrame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 4)
    MakeSubClickable(portraitFrame)

    -- Fundo escuro do retrato atras do rosto
    local portraitBg = portraitFrame:CreateTexture(nil, "BACKGROUND")
    portraitBg:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\CP_Diamond_Empty.tga")
    portraitBg:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
    portraitBg:SetWidth(50)
    portraitBg:SetHeight(50)
    portraitBg:SetVertexColor(0.08, 0.08, 0.08, 1.0)

    -- Textura 2D/3D do rosto do personagem (visivel pelo corte diamond central)
    local portraitTex = portraitFrame:CreateTexture(nil, "ARTWORK")
    portraitTex:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
    portraitTex:SetWidth(42)
    portraitTex:SetHeight(44)
    portraitTex:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    f.portrait = portraitTex
    f.portraitFrame = portraitFrame

    -- Moldura Tematica de Classe em Losango (Sobreposta em OVERLAY)
    local portraitRing = portraitFrame:CreateTexture(nil, "OVERLAY")
    portraitRing:SetAllPoints(portraitFrame)
    portraitRing:SetVertexColor(1.0, 1.0, 1.0, 1.0)
    f.portraitRing = portraitRing

    -- Badge de Nível no canto inferior direito
    local levelBadge = CreateFrame("Frame", "ConsoleModePlayerLevelBadge", portraitFrame)
    levelBadge:SetWidth(22)
    levelBadge:SetHeight(22)
    levelBadge:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", -2, -2)
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

    -- Nome do Jogador acima da barra
    local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("BOTTOMLEFT", portraitFrame, "RIGHT", 8, 20)
    nameText:SetText(UnitName("player") or "")
    f.nameText = nameText

    -- 2. Fundo da Barra de Vida (Alinhamento Perfeito)
    local hpBg = CreateFrame("Button", "ConsoleModePlayerHPBg", f)
    hpBg:SetPoint("LEFT", portraitFrame, "RIGHT", 6, -10)
    hpBg:SetWidth(140)
    hpBg:SetHeight(16)
    hpBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    hpBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    hpBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
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

    -- Barra de Vida Verde Vibrante
    local hpBar = CreateFrame("StatusBar", "ConsoleModePlayerHPBar", hpBg)
    hpBar:SetPoint("TOPLEFT", hpBg, "TOPLEFT", 2, -2)
    hpBar:SetPoint("BOTTOMRIGHT", hpBg, "BOTTOMRIGHT", -2, 2)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(0.18, 0.85, 0.28, 1.0) -- Verde
    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(1)
    hpBar:SetFrameLevel(trailBar:GetFrameLevel() + 1)
    f.hpBar = hpBar

    -- Texto de Vida
    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hpText:SetPoint("CENTER", hpBar, "CENTER", 0, 0)
    hpText:SetText("")
    f.hpText = hpText

    -- 3. Fundo da Barra de Recursos (Alinhamento 100% igual ao HP)
    local mpBg = CreateFrame("Button", "ConsoleModePlayerMPBg", f)
    mpBg:SetPoint("TOPLEFT", hpBg, "BOTTOMLEFT", 0, -2)
    mpBg:SetWidth(100) -- Largura propria da barra de recursos
    mpBg:SetHeight(10) -- Altura da barra de recursos
    mpBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    mpBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    mpBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
    MakeSubClickable(mpBg)
    f.mpBg = mpBg

    -- Barra de Recursos
    local mpBar = CreateFrame("StatusBar", "ConsoleModePlayerMPBar", mpBg)
    mpBar:SetPoint("TOPLEFT", mpBg, "TOPLEFT", 2, -2)
    mpBar:SetPoint("BOTTOMRIGHT", mpBg, "BOTTOMRIGHT", -2, 2)
    mpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    mpBar:SetStatusBarColor(0.0, 0.55, 1.0, 1.0) -- Azul Mana
    mpBar:SetMinMaxValues(0, 1)
    mpBar:SetValue(1)
    f.mpBar = mpBar

    -- Texto de Recursos
    local mpText = mpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mpText:SetPoint("CENTER", mpBar, "CENTER", 0, 0)
    mpText:SetText("")
    f.mpText = mpText

    -- 5. Combo Points (5 Losangos / Diamantes perfeitamente alinhados na borda esquerda)
    local comboContainer = CreateFrame("Frame", "ConsoleModePlayerComboPoints", f)
    comboContainer:SetPoint("TOPLEFT", mpBg, "BOTTOMLEFT", 0, -4)
    comboContainer:SetWidth(100)
    comboContainer:SetHeight(16)
    f.comboContainer = comboContainer
    f.comboPoints = {}

    for i = 1, 5 do
        local cp = CreateFrame("Frame", "ConsoleModePlayerCP" .. i, comboContainer)
        cp:SetWidth(13)
        cp:SetHeight(13)
        cp:SetPoint("LEFT", comboContainer, "LEFT", (i - 1) * 15, 0)

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

    -- 4. Barra de Conjuração / Cast Bar (Amarela Ouro, logo acima do HP)
    local castBg = CreateFrame("Frame", "ConsoleModePlayerCastBg", f)
    castBg:SetPoint("BOTTOMLEFT", hpBg, "TOPLEFT", 0, 2)
    castBg:SetPoint("BOTTOMRIGHT", hpBg, "TOPRIGHT", 0, 2)
    castBg:SetHeight(12)
    castBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    castBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    castBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    castBg:Hide()
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
                PF.isCasting = false
                f.castBg:Hide()
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
                PF.isChanneling = false
                f.castBg:Hide()
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
                PF.isCasting = false
                f.castBg:Hide()
            end
        elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
            PF.isCasting = false
            PF.isChanneling = false
            f.castBg:Hide()
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
                PF.isChanneling = false
                f.castBg:Hide()
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

    -- 2. Retrato e Moldura de Classe
    SetPortraitTexture(self.frame.portrait, "player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass or "DEFAULT"
    local classPortraitTex = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Portraits\\" .. playerClass .. ".tga"
    self.frame.portraitRing:SetTexture(classPortraitTex)

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
