--[[
    ConsoleMode - Vanilla
    UI/XPBar.lua - Barra de Experiencia Customizada
    
    Recursos:
    - Badge de Level integrado na lateral esquerda
    - Barra de preenchimento solida (Roxo padrao / Roxo escuro Rested)
    - Fundo escuro e solido
    - Texto de progresso (XP Atual / XP Maximo)
    - Movivel segurando Shift + Clique Esquerdo (posicao salva no ConsoleModeDB)
]]

local CM = ConsoleMode
CM.ui = CM.ui or {}
CM.ui.xpBar = CM.ui.xpBar or {}
local XPBar = CM.ui.xpBar

XPBar.frame = nil

function XPBar:Initialize()
    if self.frame then 
        self:Update()
        self.frame:Show()
        return 
    end
    
    -- Frame Principal Container
    local f = CreateFrame("Frame", "ConsoleModeXPBarFrame", UIParent)
    f:SetWidth(500)
    f:SetHeight(22)
    -- Torna o frame movivel, persistente e resetavel globalmente
    if CM.ui and CM.ui.MakeMovable then
        CM.ui:MakeMovable(f, "XPBar", "BOTTOM", "BOTTOM", 0, 10, CM:T("HUD_XP_BAR_NAME"))
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 10)
    end
    
    f:SetFrameStrata("MEDIUM")
    
    -- Badge de Level (quadradinho escuro na esquerda)
    local levelBadge = CreateFrame("Frame", "ConsoleModeXPLevelBadge", f)
    levelBadge:SetWidth(31)
    levelBadge:SetHeight(31)
    levelBadge:SetPoint("LEFT", f, "LEFT", -3, 0)
    levelBadge:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    levelBadge:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    levelBadge:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)
    
    local levelText = levelBadge:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    levelText:SetPoint("CENTER", levelBadge, "CENTER", 0, 0)
    levelText:SetText(tostring(UnitLevel("player") or 1))
    f.levelText = levelText
    
    -- Container / Fundo Solido da Barra de XP (colado perfeitamente no badge sem espaco)
    local barBg = CreateFrame("Frame", "ConsoleModeXPBarBackground", f)
    barBg:SetPoint("LEFT", levelBadge, "RIGHT", -3, 0)
    barBg:SetPoint("RIGHT", f, "RIGHT", 0, 0)
    barBg:SetHeight(22)
    barBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    barBg:SetBackdropColor(0.12, 0.12, 0.12, 0.95)
    barBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)
    
    -- Barra de Status Rested (Fica por tras da barra principal)
    local restedBar = CreateFrame("StatusBar", "ConsoleModeXPBarRestedStatus", barBg)
    restedBar:SetPoint("TOPLEFT", barBg, "TOPLEFT", 2, -2)
    restedBar:SetPoint("BOTTOMRIGHT", barBg, "BOTTOMRIGHT", -2, 2)
    restedBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    restedBar:SetStatusBarColor(0.30, 0.10, 0.48, 1.0) -- Roxo escuro para o Rested
    restedBar:SetMinMaxValues(0, 1)
    restedBar:SetValue(0)
    restedBar:SetFrameLevel(barBg:GetFrameLevel() + 1)
    f.restedBar = restedBar
    
    -- Barra de Status Principal (Preenchimento do XP Atual)
    local bar = CreateFrame("StatusBar", "ConsoleModeXPBarStatus", barBg)
    bar:SetPoint("TOPLEFT", barBg, "TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", barBg, "BOTTOMRIGHT", -2, 2)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.58, 0.2, 0.9, 1.0) -- Roxo padrao constante
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetFrameLevel(restedBar:GetFrameLevel() + 1)
    f.bar = bar
    
    -- Texto de XP (Atual / Max)
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetText("0 / 0")
    f.text = text
    
    -- Tooltip ao passar o mouse
    f:SetScript("OnEnter", function()
        local curXP = UnitXP("player")
        local maxXP = UnitXPMax("player")
        local restXP = GetXPExhaustion() or 0
        local pct = maxXP > 0 and math.floor((curXP / maxXP) * 100) or 0
        
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine(CM:T("HUD_XP_TITLE"), 1, 1, 1)
        GameTooltip:AddLine(format(CM:T("HUD_XP_FMT"), curXP, maxXP, pct), 0.8, 0.8, 0.8)
        if restXP > 0 then
            local restPct = math.floor((restXP / maxXP) * 100)
            GameTooltip:AddLine(format(CM:T("HUD_XP_RESTED_FMT"), restXP, restPct), 0.2, 0.6, 1.0)
        end
        GameTooltip:AddLine(CM:T("HUD_XP_DRAG"), 0.5, 0.5, 0.5)
        GameTooltip:AddLine(CM:T("HUD_XP_RESET"), 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Eventos de Atualizacao
    f:RegisterEvent("PLAYER_XP_UPDATE")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("UPDATE_EXHAUSTION")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    f:SetScript("OnEvent", function()
        XPBar:HideDefaultBars()
        XPBar:Update()
    end)
    
    self.frame = f
    self:HideDefaultBars()
    self:Update()
    f:Show()
end

function XPBar:HideDefaultBars()
    -- 1. Oculta a barra padrao da Blizzard (Vanilla 1.12)
    if MainMenuExpBar then
        MainMenuExpBar:Hide()
        MainMenuExpBar:UnregisterAllEvents()
        MainMenuExpBar:SetAlpha(0)
        MainMenuExpBar.Show = function() end
    end
    if MainMenuBarExpText then
        MainMenuBarExpText:Hide()
    end
    
    -- 2. Oculta a barra do Turtle-Dragonflight (tDFxpbar)
    local tdfBar = getglobal("tDFxpbar") or (xpbar and xpbar.GetName and xpbar:GetName() == "tDFxpbar" and xpbar)
    if tdfBar then
        tdfBar:Hide()
        tdfBar:UnregisterAllEvents()
        tdfBar:SetAlpha(0)
        tdfBar.Show = function() end
    end
    if xpbar_watcher then
        xpbar_watcher:UnregisterAllEvents()
        xpbar_watcher:SetScript("OnEvent", nil)
    end
    if xpbar_watcher_rest then
        xpbar_watcher_rest:UnregisterAllEvents()
        xpbar_watcher_rest:SetScript("OnEvent", nil)
    end
end

function XPBar:Update()
    if not self.frame then return end
    
    local playerLevel = UnitLevel("player")
    local curXP = UnitXP("player") or 0
    local maxXP = UnitXPMax("player") or 1
    local restXP = GetXPExhaustion()
    
    -- Atualiza texto do level
    if self.frame.levelText then
        self.frame.levelText:SetText(tostring(playerLevel))
    end
    
    -- Jogador no level maximo (60 no vanilla)
    if playerLevel >= 60 or maxXP == 0 then
        self.frame.bar:SetMinMaxValues(0, 1)
        self.frame.bar:SetValue(1)
        self.frame.bar:SetStatusBarColor(0.58, 0.2, 0.9, 1.0)
        if self.frame.restedBar then
            self.frame.restedBar:SetValue(0)
            self.frame.restedBar:Hide()
        end
        self.frame.text:SetText(CM:T("HUD_XP_MAX"))
        return
    end
    
    self.frame.bar:SetMinMaxValues(0, maxXP)
    self.frame.bar:SetValue(curXP)
    self.frame.bar:SetStatusBarColor(0.58, 0.2, 0.9, 1.0) -- Roxo padrao sempre
    
    -- Barra de XP Rested: cresce alem da barra de XP atual em roxo mais escuro
    if self.frame.restedBar then
        if restXP and restXP > 0 then
            self.frame.restedBar:SetMinMaxValues(0, maxXP)
            self.frame.restedBar:SetValue(math.min(curXP + restXP, maxXP))
            self.frame.restedBar:Show()
        else
            self.frame.restedBar:SetValue(0)
            self.frame.restedBar:Hide()
        end
    end
    
    -- Formata texto do progresso (ex: "6346 / 13700 (46%)")
    local pct = maxXP > 0 and math.floor((curXP / maxXP) * 100) or 0
    self.frame.text:SetText(curXP .. " / " .. maxXP .. " (" .. pct .. "%)")
end
