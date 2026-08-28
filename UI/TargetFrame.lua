--[[
    ConsoleMode - Vanilla
    UI/TargetFrame.lua - Target Frame Console HUD
    
    Recursos:
    - Barra de Vida Larga e Imponente no Topo Central da Tela
    - Barra de Dano Residual (Damage Trail amarela com decaimento suave)
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
        CM.ui:MakeMovable(f, "TargetFrame", "TOP", "TOP", 0, -25, "Target Frame")
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

    -- 3. Retrato a Direita com Moldura Tematica Diamond (Inimigos/Monstros)
    local portraitFrame = CreateFrame("Frame", "ConsoleModeTargetPortrait", f)
    portraitFrame:SetWidth(72)
    portraitFrame:SetHeight(72)
    portraitFrame:SetPoint("RIGHT", f, "RIGHT", 4, -6)

    -- Fundo escuro atras do rosto do alvo
    local portraitBg = portraitFrame:CreateTexture(nil, "BACKGROUND")
    portraitBg:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\CP_Diamond_Empty.tga")
    portraitBg:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
    portraitBg:SetWidth(28)
    portraitBg:SetHeight(28)
    portraitBg:SetVertexColor(0.08, 0.08, 0.08, 1.0)

    -- Rosto 2D do alvo (reduzido pela metade para teste radical: 22x22)
    local portraitTex = portraitFrame:CreateTexture(nil, "ARTWORK")
    portraitTex:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
    portraitTex:SetWidth(50)
    portraitTex:SetHeight(50)
    portraitTex:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    f.portrait = portraitTex
    f.portraitFrame = portraitFrame

    -- Moldura Tematica de Inimigo / Classe (Sobreposta em OVERLAY)
    local portraitRing = portraitFrame:CreateTexture(nil, "OVERLAY")
    portraitRing:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\Portraits\\ENEMY.tga")
    portraitRing:SetAllPoints(portraitFrame)
    portraitRing:SetVertexColor(1.0, 1.0, 1.0, 1.0)
    f.portraitRing = portraitRing

    -- Icone de Caveira / Elite no retrato
    local eliteIcon = portraitFrame:CreateTexture(nil, "OVERLAY")
    eliteIcon:SetWidth(22)
    eliteIcon:SetHeight(22)
    eliteIcon:SetPoint("TOPRIGHT", portraitFrame, "TOPRIGHT", 2, 2)
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

    -- 5. Barra de Dano Residual (Damage Trail Amarela com decaimento suave)
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

    -- 9. Barra de Conjuracao / Cast Bar do Alvo (Logo abaixo da barra de poder)
    local castBg = CreateFrame("Frame", "ConsoleModeTargetCastBg", f)
    castBg:SetPoint("TOPLEFT", mpBg, "BOTTOMLEFT", 0, -2)
    castBg:SetPoint("RIGHT", hpBg, "RIGHT", 0, 0)
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

    local castBar = CreateFrame("StatusBar", "ConsoleModeTargetCastBar", castBg)
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

    -- 10. Bandeja de Debuffs / Auras (Abaixo da Cast Bar)
    f.debuffContainer = CreateFrame("Frame", "ConsoleModeTargetDebuffs", f)
    f.debuffContainer:SetPoint("TOPLEFT", castBg, "BOTTOMLEFT", 0, -4)
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

    -- Animacao Suave do Damage Trail e Cast Bar no OnUpdate
    f:SetScript("OnUpdate", function()
        if not UnitExists("target") then
            TF.isCasting = false
            f.castBg:Hide()
            return
        end
        
        local elapsed = arg1 or 0.016

        -- 1. Damage Trail
        if TF.curHP and TF.damageTrailVal > TF.curHP then
            TF.damageTrailTimer = TF.damageTrailTimer + elapsed
            if TF.damageTrailTimer > 0.35 then
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

        -- 2. Target Cast Bar
        if TF.isCasting and TF.castDuration and TF.castDuration > 0 then
            TF.castValue = TF.castValue + elapsed
            if TF.castValue >= TF.castDuration then
                TF.castValue = TF.castDuration
                TF.isCasting = false
                f.castBg:Hide()
            else
                f.castBar:SetValue(TF.castValue)
                local rem = TF.castDuration - TF.castValue
                f.castTimeText:SetText(string.format("%.1fs", rem))
            end
        end
    end)

    -- Eventos de Atualizacao e Combat Log para Cast do Alvo
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
    f:RegisterEvent("SPELLCAST_START")
    f:RegisterEvent("SPELLCAST_STOP")
    f:RegisterEvent("SPELLCAST_FAILED")
    f:RegisterEvent("SPELLCAST_INTERRUPTED")
    f:RegisterEvent("SPELLCAST_DELAYED")
    f:RegisterEvent("SPELLCAST_CHANNEL_START")
    f:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
    f:RegisterEvent("SPELLCAST_CHANNEL_STOP")
    f:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
    f:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF")
    f:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
    f:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")
    f:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
    f:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
    f:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
    f:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
    f:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
    f:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")

    local SPELL_CAST_TIMES = {
        ["Fireball"] = 3.0, ["Bola de Fogo"] = 3.0,
        ["Frostbolt"] = 2.5, ["Seta de Gelo"] = 2.5,
        ["Pyroblast"] = 6.0, ["Ignicarga"] = 6.0,
        ["Scorch"] = 1.5, ["Queimar"] = 1.5,
        ["Flamestrike"] = 3.0, ["Golpe Flamejante"] = 3.0,
        ["Shadow Bolt"] = 2.5, ["Seta Sombria"] = 2.5,
        ["Soul Fire"] = 4.0, ["Fogo da Alma"] = 4.0,
        ["Searing Pain"] = 1.5, ["Dor Calcinante"] = 1.5,
        ["Immolate"] = 1.5, ["Imolar"] = 1.5,
        ["Fear"] = 1.5, ["Medo"] = 1.5,
        ["Howl of Terror"] = 1.5, ["Uivo de Terror"] = 1.5,
        ["Holy Light"] = 2.5, ["Luz Sagrada"] = 2.5,
        ["Flash of Light"] = 1.5, ["Lampejo de Luz"] = 1.5,
        ["Greater Heal"] = 2.5, ["Cura Maior"] = 2.5, ["Cura Superior"] = 2.5,
        ["Heal"] = 2.5, ["Cura"] = 2.5,
        ["Flash Heal"] = 1.5, ["Cura Célere"] = 1.5,
        ["Smite"] = 2.0, ["Punição"] = 2.0,
        ["Holy Fire"] = 3.0, ["Fogo Sagrado"] = 3.0,
        ["Mind Blast"] = 1.5, ["Impacto Mental"] = 1.5,
        ["Mana Burn"] = 2.5, ["Queimar Mana"] = 2.5,
        ["Healing Wave"] = 2.5, ["Onda de Cura"] = 2.5,
        ["Lesser Healing Wave"] = 1.5, ["Onda de Cura Menor"] = 1.5,
        ["Chain Heal"] = 2.5, ["Cadeia de Cura"] = 2.5,
        ["Lightning Bolt"] = 2.5, ["Raio"] = 2.5,
        ["Chain Lightning"] = 2.0, ["Cadeia de Raios"] = 2.0,
        ["Healing Touch"] = 3.0, ["Toque de Cura"] = 3.0,
        ["Regrowth"] = 2.0, ["Recrescimento"] = 2.0,
        ["Wrath"] = 1.5, ["Ira"] = 1.5,
        ["Starfire"] = 3.0, ["Fogo Estelar"] = 3.0,
        ["Entangling Roots"] = 1.5, ["Raízes Enredantes"] = 1.5,
        ["Polymorph"] = 1.5, ["Polimorfia"] = 1.5,
        ["Aimed Shot"] = 3.0, ["Tiro Certo"] = 3.0,
        ["Hearthstone"] = 10.0, ["Pedra de Regresso"] = 10.0,
    }

    local function StartTargetCast(spellName, duration)
        local dur = duration or SPELL_CAST_TIMES[spellName] or 2.0
        TF.isCasting = true
        TF.castValue = 0
        TF.castDuration = dur
        f.castBar:SetMinMaxValues(0, dur)
        f.castBar:SetValue(0)
        f.castSpellText:SetText(spellName)
        f.castTimeText:SetText(string.format("%.1fs", dur))
        f.castBg:Show()
    end

    f:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            TF.isCasting = false
            f.castBg:Hide()
            TF:HideDefaultBars()
            TF:Update()
        elseif event == "PLAYER_ENTERING_WORLD" then
            TF:HideDefaultBars()
            TF:Update()
        elseif arg1 == "target" then
            TF:Update()
        -- Se o alvo for o proprio jogador, sincroniza diretamente com os eventos de spellcast nativos
        elseif UnitIsUnit("player", "target") then
            if event == "SPELLCAST_START" then
                local spellName = arg1 or ""
                local durationSec = (arg2 or 0) / 1000
                if durationSec > 0 then
                    StartTargetCast(spellName, durationSec)
                end
            elseif event == "SPELLCAST_STOP" or event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
                TF.isCasting = false
                f.castBg:Hide()
            elseif event == "SPELLCAST_DELAYED" then
                if TF.isCasting and TF.castDuration then
                    local delaySec = (arg1 or 0) / 1000
                    TF.castDuration = TF.castDuration + delaySec
                    f.castBar:SetMinMaxValues(0, TF.castDuration)
                end
            elseif event == "SPELLCAST_CHANNEL_START" then
                local durationSec = (arg1 or 0) / 1000
                local spellName = arg2 or ""
                if durationSec > 0 then
                    StartTargetCast(spellName, durationSec)
                end
            elseif event == "SPELLCAST_CHANNEL_STOP" then
                TF.isCasting = false
                f.castBg:Hide()
            end
        elseif string.find(event, "^CHAT_MSG_SPELL_") and arg1 and UnitExists("target") then
            local msg = arg1
            local tName = UnitName("target")
            if tName and string.find(msg, tName) then
                -- Comeca a lancar / begins to cast
                local _, _, caster, spell = string.find(msg, "^(.+) begins to cast (.+)%.")
                if not caster then
                    _, _, caster, spell = string.find(msg, "^(.+) begins to perform (.+)%.")
                end
                if not caster then
                    _, _, caster, spell = string.find(msg, "^(.+) começa a lançar (.+)%.")
                end
                if not caster then
                    _, _, caster, spell = string.find(msg, "^(.+) começa a usar (.+)%.")
                end

                if caster and caster == tName and spell then
                    StartTargetCast(spell)
                elseif string.find(msg, "is interrupted") or string.find(msg, "foi interrompido") then
                    TF.isCasting = false
                    f.castBg:Hide()
                end
            end
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

    local defaultTargetCastBars = {
        "tDFTargetCastbar",
        "tDF_TargetCastbar",
        "TargetCastBarFrame",
    }

    for _, barName in ipairs(defaultTargetCastBars) do
        local bar = getglobal(barName)
        if bar then
            bar:Hide()
            bar:UnregisterAllEvents()
            bar:SetAlpha(0)
            bar.Show = function() end
        end
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

    -- 3. Retrato e Moldura Dinamica do Alvo
    SetPortraitTexture(self.frame.portrait, "target")
    if UnitIsPlayer("target") then
        -- Alvo é um Jogador: usa a moldura da classe do jogador
        local _, tClass = UnitClass("target")
        tClass = tClass or "DEFAULT"
        local classPortraitTex = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Portraits\\" .. tClass .. ".tga"
        self.frame.portraitRing:SetTexture(classPortraitTex)
    elseif UnitIsEnemy("player", "target") or UnitCanAttack("player", "target") then
        -- Inimigo Hostil / Monstro / Boss: usa a moldura sinistra de Inimigos
        self.frame.portraitRing:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\Portraits\\ENEMY.tga")
    else
        -- NPC Amigável / Neutro / Comerciante / Cidadão: usa a moldura temática de NPC
        self.frame.portraitRing:SetTexture("Interface\\AddOns\\ConsoleModeVanilla\\Media\\Portraits\\NPC.tga")
    end

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
