--[[
    ConsoleMode - Vanilla
    UI/XPBar.lua - Barra de Experiencia Customizada
    
    Recursos:
    - Badge de Level integrado na lateral esquerda
    - Barra de preenchimento solida (Roxo padrao / Azul Rested)
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
    
    -- Carrega posicao salva ou define posicao padrao (parte inferior da tela)
    local savedPos = ConsoleModeDB and ConsoleModeDB.xpBarPosition
    if savedPos and savedPos.point then
        f:SetPoint(savedPos.point, UIParent, savedPos.relPoint, savedPos.x, savedPos.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end
    
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    
    -- Movimentacao com Shift + Clique Esquerdo
    f:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            this:StartMoving()
            this.isMoving = true
        end
    end)
    
    f:SetScript("OnDragStop", function()
        if this.isMoving then
            this:StopMovingOrSizing()
            this.isMoving = false
            
            -- Salva a nova posicao
            if not ConsoleModeDB then ConsoleModeDB = {} end
            local point, _, relPoint, x, y = this:GetPoint()
            ConsoleModeDB.xpBarPosition = {
                point = point,
                relPoint = relPoint,
                x = x,
                y = y
            }
        end
    end)
    
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
    
    -- Barra de Status (Preenchimento)
    local bar = CreateFrame("StatusBar", "ConsoleModeXPBarStatus", barBg)
    bar:SetPoint("TOPLEFT", barBg, "TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", barBg, "BOTTOMRIGHT", -2, 2)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
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
        GameTooltip:AddLine("Experiencia", 1, 1, 1)
        GameTooltip:AddLine(string.format("XP: %d / %d (%d%%)", curXP, maxXP, pct), 0.8, 0.8, 0.8)
        if restXP > 0 then
            local restPct = math.floor((restXP / maxXP) * 100)
            GameTooltip:AddLine(string.format("Descansado: +%d (%d%%)", restXP, restPct), 0.2, 0.6, 1.0)
        end
        GameTooltip:AddLine("|cff888888(Segure Shift + Clique Esquerdo para arrastar)|r", 0.5, 0.5, 0.5)
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
        XPBar:Update()
    end)
    
    self.frame = f
    self:Update()
    f:Show()
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
        self.frame.bar:SetStatusBarColor(0.58, 0.2, 0.9, 1.0) -- Roxo
        self.frame.text:SetText("Level Maximo (60)")
        return
    end
    
    self.frame.bar:SetMinMaxValues(0, maxXP)
    self.frame.bar:SetValue(curXP)
    
    -- Cor: Azul se estiver com bonus de descanso (Rested), Roxo se for XP normal
    if restXP and restXP > 0 then
        self.frame.bar:SetStatusBarColor(0.25, 0.45, 0.95, 1.0) -- Azul Rested
    else
        self.frame.bar:SetStatusBarColor(0.58, 0.2, 0.9, 1.0)  -- Roxo Padrao
    end
    
    -- Formata texto do progresso (ex: "6346 / 13700 (46%)")
    local pct = maxXP > 0 and math.floor((curXP / maxXP) * 100) or 0
    self.frame.text:SetText(curXP .. " / " .. maxXP .. " (" .. pct .. "%)")
end
