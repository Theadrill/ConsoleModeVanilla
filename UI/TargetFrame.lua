--[[
    ConsoleMode - Vanilla
    UI/TargetFrame.lua - Target Frame Estilo Dark Souls / Boss Bar
    
    Recursos:
    - Barra de Vida Larga e Imponente no Topo Central da Tela
    - Barra de Dano Residual (Damage Trail amarela com decaimento suave estilo Souls)
    - Barra de Mana / Energia / Furia fina abaixo da vida
    - Retrato em Medalhao a Direita com suporte nativo a textura de retrato
    - Nivel, Nome e Indicador de Elite / Boss em tipografia dourada
    - Bandeja de Debuffs / Auras do alvo logo abaixo
    - Movivel com Shift + Drag e resetavel com /cm resetui
    - Ocultacao segura do TargetFrame original da Blizzard
]]

local CM = ConsoleMode
CM.ui = CM.ui or {}
CM.ui.targetFrame = CM.ui.targetFrame or {}
local TF = CM.ui.targetFrame

TF.frame = nil
TF.debuffFrames = {}
TF.damageTrailVal = 0
TF.damageTrailTimer = 0

function TF:Initialize()
    if self.frame then
        self:HideDefaultBars()
        self:Update()
        return
    end

    -- Container Principal
    local f = CreateFrame("Button", "ConsoleModeTargetFrame", UIParent)
    f:SetWidth(480)
    f:SetHeight(70)
    
    if CM.ui and CM.ui.MakeMovable then
        CM.ui:MakeMovable(f, "TargetFrame", "TOP", "TOP", 0, -25, "Target Frame (Dark Souls)")
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -25)
    end
    
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Clique no frame = Menu de Contexto
    f:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            if UnitExists("target") and TargetFrameDropDown then
                HideDropDownMenu(1)
                TargetFrameDropDown.point = "TOPRIGHT"
                TargetFrameDropDown.relativePoint = "BOTTOMRIGHT"
                ToggleDropDownMenu(1, nil, TargetFrameDropDown, f:GetName(), 0, 0)
            end
        end
    end)

    -- 1. Nivel e Classificacao (Lv. 60 [Boss / Elite])
    local levelText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelText:SetPoint("TOP", f, "TOP", -30, 0)
    levelText:SetText("")
    f.levelText = levelText

    -- 2. Nome do Alvo (Tipografia dourada grande centralizada)
    local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("TOP", levelText, "BOTTOM", 0, -2)
    nameText:SetText("")
    f.nameText = nameText

    -- 3. Retrato a Direita (Medalhao estilizado)
    local portraitFrame = CreateFrame("Frame", "ConsoleModeTargetPortrait", f)
    portraitFrame:SetWidth(52)
    portraitFrame:SetHeight(52)
    portraitFrame:SetPoint("RIGHT", f, "RIGHT", 0, -6)
    portraitFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    portraitFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    portraitFrame:SetBackdropBorderColor(0.6, 0.5, 0.2, 1.0) -- Borda Dourada / Bronze

    local portraitTex = portraitFrame:CreateTexture(nil, "ARTWORK")
    portraitTex:SetPoint("TOPLEFT", portraitFrame, "TOPLEFT", 4, -4)
    portraitTex:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", -4, 4)
    portraitTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.portrait = portraitTex
    f.portraitFrame = portraitFrame

    -- Icone de Caveira / Elite no retrato
    local eliteIcon = portraitFrame:CreateTexture(nil, "OVERLAY")
    eliteIcon:SetWidth(20)
    eliteIcon:SetHeight(20)
    eliteIcon:SetPoint("TOPLEFT", portraitFrame, "TOPLEFT", -6, 6)
    eliteIcon:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    eliteIcon:Hide()
    f.eliteIcon = eliteIcon

    -- 4. Fundo Escuro da Barra de Vida
    local hpBg = CreateFrame("Frame", "ConsoleModeTargetHPBg", f)
    hpBg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -32)
    hpBg:SetPoint("RIGHT", portraitFrame, "LEFT", -6, 0)
    hpBg:SetHeight(18)
    hpBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    hpBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    hpBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)
    f.hpBg = hpBg

    -- 5. Barra de Dano Residual (Damage Trail Amarela estilo Dark Souls)
    local trailBar = CreateFrame("StatusBar", "ConsoleModeTargetDamageTrail", hpBg)
    trailBar:SetPoint("TOPLEFT", hpBg, "TOPLEFT", 2, -2)
    trailBar:SetPoint("BOTTOMRIGHT", hpBg, "BOTTOMRIGHT", -2, 2)
    trailBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    trailBar:SetStatusBarColor(0.95, 0.8, 0.1, 0.85) -- Amarelo ouro
    trailBar:SetMinMaxValues(0, 1)
    trailBar:SetValue(0)
    f.trailBar = trailBar

    -- 6. Barra de Vida Principal (Carmesim / Vermelho)
    local hpBar = CreateFrame("StatusBar", "ConsoleModeTargetHPBar", hpBg)
    hpBar:SetPoint("TOPLEFT", hpBg, "TOPLEFT", 2, -2)
    hpBar:SetPoint("BOTTOMRIGHT", hpBg, "BOTTOMRIGHT", -2, 2)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(0.85, 0.12, 0.12, 1.0) -- Carmesim
    hpBar:SetMinMaxValues(0, 1)
    hpBar:SetValue(1)
    hpBar:SetFrameLevel(trailBar:GetFrameLevel() + 1)
    f.hpBar = hpBar

    -- Texto de Vida (Atual / Max ou %)
    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hpText:SetPoint("CENTER", hpBar, "CENTER", 0, 0)
    hpText:SetText("")
    f.hpText = hpText

    -- 7. Fundo Escuro da Barra de Mana / Poder
    local mpBg = CreateFrame("Frame", "ConsoleModeTargetMPBg", f)
    mpBg:SetPoint("TOPLEFT", hpBg, "BOTTOMLEFT", 0, -2)
    mpBg:SetPoint("RIGHT", hpBg, "RIGHT", 0, 0)
    mpBg:SetHeight(7)
    mpBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    mpBg:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    mpBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    f.mpBg = mpBg

    -- 8. Barra de Mana / Poder (Pequena e Fina)
    local mpBar = CreateFrame("StatusBar", "ConsoleModeTargetMPBar", mpBg)
    mpBar:SetPoint("TOPLEFT", mpBg, "TOPLEFT", 1, -1)
    mpBar:SetPoint("BOTTOMRIGHT", mpBg, "BOTTOMRIGHT", -1, 1)
    mpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    mpBar:SetStatusBarColor(0.0, 0.55, 1.0, 1.0) -- Azul Mana
    mpBar:SetMinMaxValues(0, 1)
    mpBar:SetValue(1)
    f.mpBar = mpBar

    -- 9. Bandeja de Debuffs / Auras (Abaixo das barras)
    f.debuffContainer = CreateFrame("Frame", "ConsoleModeTargetDebuffs", f)
    f.debuffContainer:SetPoint("TOPLEFT", mpBg, "BOTTOMLEFT", 0, -6)
    f.debuffContainer:SetWidth(420)
    f.debuffContainer:SetHeight(26)
    
    for i = 1, 12 do
        local dBtn = CreateFrame("Frame", "ConsoleModeTargetDebuff" .. i, f.debuffContainer)
        dBtn:SetWidth(22)
        dBtn:SetHeight(22)
        dBtn:SetPoint("LEFT", f.debuffContainer, "LEFT", (i - 1) * 26, 0)
        
        local icon = dBtn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(dBtn)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        dBtn.icon = icon

        local border = dBtn:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        border:SetAllPoints(dBtn)
        dBtn.border = border

        local count = dBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
        count:SetPoint("BOTTOMRIGHT", dBtn, "BOTTOMRIGHT", 2, -2)
        count:SetText("")
        dBtn.count = count

        dBtn:Hide()
        self.debuffFrames[i] = dBtn
    end

    -- Animacao Suave do Damage Trail no OnUpdate
    f:SetScript("OnUpdate", function()
        if not UnitExists("target") then return end
        
        local elapsed = arg1 or 0.016
        if TF.curHP and TF.damageTrailVal > TF.curHP then
            TF.damageTrailTimer = TF.damageTrailTimer + elapsed
            if TF.damageTrailTimer > 0.35 then -- Espera 350ms antes de comecar a drenar
                local speed = (TF.damageTrailVal - TF.curHP) * 5 * elapsed
                TF.damageTrailVal = TF.damageTrailVal - speed
                if TF.damageTrailVal <= TF.curHP then
                    TF.damageTrailVal = TF.curHP
                end
                TF.frame.trailBar:SetValue(TF.damageTrailVal)
            end
        elseif TF.curHP then
            TF.damageTrailVal = TF.curHP
            TF.frame.trailBar:SetValue(TF.curHP)
            TF.damageTrailTimer = 0
        end
    end)

    -- Eventos de Atualizacao
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
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
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("UNIT_LEVEL")
    f:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")

    f:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            TF:HideDefaultBars()
            TF:Update()
        elseif arg1 == "target" then
            TF:Update()
        end
    end)

    self.frame = f
    self:HideDefaultBars()
    self:Update()
end

function TF:HideDefaultBars()
    if TargetFrame then
        TargetFrame:Hide()
        TargetFrame:UnregisterAllEvents()
        TargetFrame:SetAlpha(0)
        TargetFrame.Show = function() end
    end
    if ComboFrame then
        ComboFrame:SetAlpha(0)
    end
end

function TF:Update()
    if not self.frame then return end

    if not UnitExists("target") then
        self.frame:Hide()
        return
    end

    self.frame:Show()

    -- 1. Nome do Alvo
    local name = UnitName("target") or "Desconhecido"
    self.frame.nameText:SetText(name)

    -- 2. Nivel e Classificacao
    local level = UnitLevel("target")
    local classification = UnitClassification("target") or "normal"
    local classText = ""

    if classification == "worldboss" then
        classText = " [Chefe Mundial]"
        self.frame.eliteIcon:Show()
    elseif classification == "rareelite" then
        classText = " [Raro Elite]"
        self.frame.eliteIcon:Show()
    elseif classification == "elite" then
        classText = " [Elite]"
        self.frame.eliteIcon:Show()
    elseif classification == "rare" then
        classText = " [Raro]"
        self.frame.eliteIcon:Hide()
    else
        self.frame.eliteIcon:Hide()
    end

    if level and level > 0 then
        self.frame.levelText:SetText("Nível " .. level .. classText)
    else
        self.frame.levelText:SetText("Nível ?? " .. classText) -- Boss / Caveira
    end

    -- 3. Retrato
    SetPortraitTexture(self.frame.portrait, "target")

    -- 4. Vida
    local curHP = UnitHealth("target") or 0
    local maxHP = UnitHealthMax("target") or 1
    self.curHP = curHP

    self.frame.hpBar:SetMinMaxValues(0, maxHP)
    self.frame.hpBar:SetValue(curHP)

    self.frame.trailBar:SetMinMaxValues(0, maxHP)
    if not self.damageTrailVal or self.damageTrailVal < curHP or self.damageTrailVal > maxHP then
        self.damageTrailVal = curHP
        self.frame.trailBar:SetValue(curHP)
    end

    -- Cor da Vida baseada em Hostilidade / Reação (Amigável = Verde, Inimigo = Vermelho, Neutro = Amarelo)
    if UnitIsEnemy("player", "target") then
        self.frame.hpBar:SetStatusBarColor(0.85, 0.15, 0.15, 1.0) -- Vermelho Inimigo
    elseif UnitIsFriend("player", "target") then
        self.frame.hpBar:SetStatusBarColor(0.15, 0.85, 0.25, 1.0) -- Verde Vivo Amigável / Jogador
    else
        self.frame.hpBar:SetStatusBarColor(0.95, 0.80, 0.15, 1.0) -- Amarelo Neutro
    end

    local hpPct = maxHP > 0 and math.floor((curHP / maxHP) * 100) or 0
    self.frame.hpText:SetText(curHP .. " / " .. maxHP .. " (" .. hpPct .. "%)")

    -- 5. Poder / Mana / Energia / Furia
    local pType = UnitPowerType("target")
    local curPower = UnitMana("target") or 0
    local maxPower = UnitManaMax("target") or 1

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
    else
        self.frame.mpBg:Hide()
    end

    -- 6. Debuffs do Alvo
    for i = 1, 12 do
        local debuffTex, count, debuffType = UnitDebuff("target", i)
        local btn = self.debuffFrames[i]
        if btn then
            if debuffTex then
                btn.icon:SetTexture(debuffTex)
                if count and count > 1 then
                    btn.count:SetText(tostring(count))
                else
                    btn.count:SetText("")
                end
                
                -- Cor da borda por tipo de debuff (Magia = Azul, Veneno = Verde, Maldicao = Roxo, Doenca = Marrom)
                if debuffType == "Magic" then
                    btn.border:SetVertexColor(0.2, 0.6, 1.0)
                elseif debuffType == "Poison" then
                    btn.border:SetVertexColor(0.0, 0.8, 0.0)
                elseif debuffType == "Curse" then
                    btn.border:SetVertexColor(0.6, 0.0, 1.0)
                elseif debuffType == "Disease" then
                    btn.border:SetVertexColor(0.6, 0.4, 0.0)
                else
                    btn.border:SetVertexColor(0.8, 0.0, 0.0)
                end
                
                btn:Show()
            else
                btn:Hide()
            end
        end
    end
end
