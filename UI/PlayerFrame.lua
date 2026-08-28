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
    f:SetWidth(320)
    f:SetHeight(64)
    
    if CM.ui and CM.ui.MakeMovable then
        CM.ui:MakeMovable(f, "PlayerFrame", "TOPLEFT", "TOPLEFT", 20, -20, "Player Frame")
    else
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)
    end
    
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Clique direito = Menu do Jogador (Loot, Reset Instances, etc.)
    f:SetScript("OnClick", function()
        if arg1 == "RightButton" and PlayerFrameDropDown then
            HideDropDownMenu(1)
            PlayerFrameDropDown.point = "TOPLEFT"
            PlayerFrameDropDown.relativePoint = "BOTTOMLEFT"
            ToggleDropDownMenu(1, nil, PlayerFrameDropDown, f:GetName(), 0, 0)
        end
    end)

    -- 1. Medalhão Nórdico do Jogador (Retrato à Esquerda)
    local portraitFrame = CreateFrame("Frame", "ConsoleModePlayerPortrait", f)
    portraitFrame:SetWidth(54)
    portraitFrame:SetHeight(54)
    portraitFrame:SetPoint("LEFT", f, "LEFT", 0, 0)
    portraitFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    portraitFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    portraitFrame:SetBackdropBorderColor(0.55, 0.55, 0.55, 1.0) -- Prata / Metal Nórdico

    local portraitTex = portraitFrame:CreateTexture(nil, "ARTWORK")
    portraitTex:SetPoint("TOPLEFT", portraitFrame, "TOPLEFT", 4, -4)
    portraitTex:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", -4, 4)
    portraitTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.portrait = portraitTex
    f.portraitFrame = portraitFrame

    -- Badge de Nível colado no medalhão (canto inferior direito)
    local levelBadge = CreateFrame("Frame", "ConsoleModePlayerLevelBadge", portraitFrame)
    levelBadge:SetWidth(20)
    levelBadge:SetHeight(20)
    levelBadge:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", 4, -4)
    levelBadge:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    levelBadge:SetBackdropColor(0.08, 0.08, 0.08, 1.0)
    levelBadge:SetBackdropBorderColor(0.55, 0.55, 0.55, 1.0)

    local levelText = levelBadge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelText:SetPoint("CENTER", levelBadge, "CENTER", 0, 0)
    levelText:SetText(tostring(UnitLevel("player") or 1))
    f.levelText = levelText

    -- Nome do Jogador acima da barra
    local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("BOTTOMLEFT", portraitFrame, "TOPRIGHT", 6, -2)
    nameText:SetText(UnitName("player") or "")
    f.nameText = nameText

    -- 2. Fundo da Barra de Vida
    local hpBg = CreateFrame("Frame", "ConsoleModePlayerHPBg", f)
    hpBg:SetPoint("LEFT", portraitFrame, "RIGHT", 4, 4)
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

    -- 3. Fundo da Barra de Recursos (Furia / Mana / Energia)
    local mpBg = CreateFrame("Frame", "ConsoleModePlayerMPBg", f)
    mpBg:SetPoint("TOPLEFT", hpBg, "BOTTOMLEFT", 0, -2)
    mpBg:SetWidth(100) -- ⬅️ LARGURA PROPRIA DA BARRA DE RECURSOS (atualmente 180px)
    mpBg:SetHeight(9)  -- ⬅️ Altura da barra de recursos
    mpBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    mpBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    mpBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    f.mpBg = mpBg

    -- Barra de Recursos
    local mpBar = CreateFrame("StatusBar", "ConsoleModePlayerMPBar", mpBg)
    mpBar:SetPoint("TOPLEFT", mpBg, "TOPLEFT", 1, -1)
    mpBar:SetPoint("BOTTOMRIGHT", mpBg, "BOTTOMRIGHT", -1, 1)
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

    -- Damage Trail no OnUpdate
    f:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0.016
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
    end)

    -- Eventos
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
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")

    f:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            PF:HideDefaultBars()
            PF:Update()
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
end

function PF:Update()
    if not self.frame then return end
    self.frame:Show()

    -- 1. Nome e Nível
    local name = UnitName("player") or "Jogador"
    self.frame.nameText:SetText(name)
    self.frame.levelText:SetText(tostring(UnitLevel("player") or 1))

    -- 2. Retrato
    SetPortraitTexture(self.frame.portrait, "player")

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

        local mpPct = maxPower > 0 and math.floor((curPower / maxPower) * 100) or 0
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
end
