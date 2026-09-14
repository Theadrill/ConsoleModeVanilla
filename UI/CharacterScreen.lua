-- ============================================================================
-- ConsoleModeVanilla - UI/CharacterScreen.lua
-- FASE 4 (docs/plano_de_feature_ABA_DO_PERSONAGEM.md): 8 cards reais
-- full-width 1 coluna (layout misto 2-colunas ADIADO pelo usuario):
-- Identidade, Atributos, Recursos + 5 novos de combate (Melee, Ranged,
-- Defesa, Magico, Resistencias).
-- Molde: UI/MerchantMenu.lua e UI/MailScreen.lua (namespace global,
-- Initialize/AttachTo/Show/Hide, pool fixo criado uma vez, identidade
-- visual Vanilla com fontes AlegreyaSans).
-- Compativel com WoW Vanilla 1.12.1 / Lua 5.0 estrito (usa table.getn e
-- ipairs; sem operador length novo, sem desvios novos, sem libs externas).
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_CharacterScreen = ConsoleMode_CharacterScreen or {}
local CharacterScreen = ConsoleMode_CharacterScreen
CM.characterScreen = CharacterScreen

-- ----------------------------------------------------------------------------
-- 1. DESIGN SYSTEM (molde MerchantMenu/MailScreen: so visual, sem logica)
-- ----------------------------------------------------------------------------
local FONTS = {
    titleBold = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    bodyBold  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    medium    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Medium.ttf",
    fallback  = "Fonts\\FRIZQT__.TTF",
}

local COLORS = {
    amberText   = "|cffe09a15",
    title       = { r = 1.00, g = 0.85, b = 0.20 },
    body        = { r = 0.96, g = 0.88, b = 0.68 },
    hint        = { r = 0.70, g = 0.65, b = 0.55 },
    bonusGreen  = "|cff20ff20",
    penaltyRed  = "|cffff4040",
    blockBg     = { r = 0.08, g = 0.06, b = 0.04, a = 0.85 },
    blockBorder = { r = 0.50, g = 0.40, b = 0.28, a = 0.65 },
}

-- Fallback de cor de classe caso RAID_CLASS_COLORS nao exista no cliente.
local FALLBACK_CLASS_COLORS = {
    WARRIOR = "|cffc79c6e",
    PALADIN = "|cfff58cba",
    HUNTER  = "|cffabd473",
    ROGUE   = "|cfffff569",
    PRIEST  = "|cffffffff",
    SHAMAN  = "|cff0070de",
    MAGE    = "|cff69ccf0",
    WARLOCK = "|cff9482c9",
    DRUID   = "|cffff7d0a",
}

local STAT_NAMES = { "Força", "Agilidade", "Vigor", "Intelecto", "Espírito" }

-- ----------------------------------------------------------------------------
-- 2. ESTADO DO MODULO (pool fixo: frames criados uma vez, nunca destruidos)
-- ----------------------------------------------------------------------------
CharacterScreen.initialized  = CharacterScreen.initialized or false
CharacterScreen.attached     = CharacterScreen.attached or false
CharacterScreen.isVisible    = CharacterScreen.isVisible or false
CharacterScreen.firstShown   = CharacterScreen.firstShown or false
CharacterScreen.parentFrame  = CharacterScreen.parentFrame or nil
CharacterScreen.scrollFrame  = CharacterScreen.scrollFrame or nil
CharacterScreen.scrollChild  = CharacterScreen.scrollChild or nil
CharacterScreen.cards        = CharacterScreen.cards or nil
CharacterScreen.eventFrame   = CharacterScreen.eventFrame or nil

-- Rolagem: offset atual (px), passo por toque no D-Pad, altura do conteudo.
CharacterScreen.scrollOffset = CharacterScreen.scrollOffset or 0
CharacterScreen.scrollStep   = CharacterScreen.scrollStep or 60
CharacterScreen.contentH     = CharacterScreen.contentH or 0
CharacterScreen.viewH        = CharacterScreen.viewH or 0

-- FASE 3: 3 cards reais (pool fixo). Alturas fixas por card + gap.
CharacterScreen.cardGap = CharacterScreen.cardGap or 12

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
local function CS_ApplyFont(fs, file, size)
    if not fs then return end
    -- Sem pcall engolindo erro (molde MainMenu:ApplyFont): SetFont 1.12
    -- retorna falsy quando o arquivo falha; ai cai para FRIZQT__.
    if type(fs.SetFont) == "function" then
        local ok = fs:SetFont(file, size, "")
        if not ok then
            fs:SetFont(FONTS.fallback, size, "")
        end
    end
    if type(fs.SetShadowOffset) == "function" then
        fs:SetShadowOffset(1, -1)
    end
    if type(fs.SetShadowColor) == "function" then
        fs:SetShadowColor(0.0, 0.0, 0.0, 0.90)
    end
end

local function CS_HidePlaceholder(parent)
    if parent and parent.placeholder and type(parent.placeholder.Hide) == "function" then
        parent.placeholder:Hide()
    end
end

local function CS_ChatError(msg)
    local dcf = getglobal("DEFAULT_CHAT_FRAME")
    if dcf and type(dcf.AddMessage) == "function" then
        dcf:AddMessage("|cffff4040[ConsoleMode/Character]|r " .. tostring(msg))
    end
end

local function CS_Clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function CS_Num(v, def)
    if type(v) == "number" then return v end
    return def or 0
end

-- Formata numero com 1 casa decimal; "—" se nao for numero.
local function CS_Fmt1(v)
    if type(v) ~= "number" then return "—" end
    return string.format("%.1f", v)
end

-- Formata numero com 2 casas decimais; "—" se nao for numero.
local function CS_Fmt2(v)
    if type(v) ~= "number" then return "—" end
    return string.format("%.2f", v)
end

-- DPS = dano medio / velocidade; "—" se velocidade zerada ou dados ruins.
local function CS_DPS(minD, maxD, speed)
    if type(minD) ~= "number" or type(maxD) ~= "number" then return "—" end
    if type(speed) ~= "number" or speed <= 0 then return "—" end
    return CS_Fmt1(((minD + maxD) / 2) / speed)
end

-- Barra textual proporcional 0..100+ (12 blocos); pool fixo de
-- FontStrings, sem criar textures novas. Lua 5.0 ok (string.rep).
local function CS_ResistBar(total)
    local t = CS_Num(total, 0)
    if t < 0 then t = 0 end
    local filled = math.floor((t / 100) * 12)
    if filled < 0 then filled = 0 end
    if filled > 12 then filled = 12 end
    return "[" .. string.rep("=", filled) .. string.rep(" ", 12 - filled) .. "]"
end

-- Cor hexadecimal da classe: RAID_CLASS_COLORS (1.12) ou fallback estatico.
local function CS_ClassColorHex(classFile)
    if type(RAID_CLASS_COLORS) == "table" and classFile and classFile ~= "" then
        local cc = RAID_CLASS_COLORS[classFile]
        if type(cc) == "table" and type(cc.r) == "number"
            and type(cc.g) == "number" and type(cc.b) == "number" then
            return string.format("|cff%02x%02x%02x",
                (cc.r or 1) * 255, (cc.g or 1) * 255, (cc.b or 1) * 255)
        end
    end
    if classFile and FALLBACK_CLASS_COLORS[classFile] then
        return FALLBACK_CLASS_COLORS[classFile]
    end
    return "|cffffffff"
end

-- Deteccao dos modos Turtle/Hardcore via varredura de buffs do jogador.
-- Retorna o texto pronto para exibicao; "Modo: Normal" quando nada achar.
local function CS_DetectTurtleMode()
    local foundHC = false
    local foundTurtle = false
    local function CS_ScanTexture(tex)
        if type(tex) ~= "string" or tex == "" then return end
        local low = string.lower(tex)
        if string.find(low, "hardcore", 1, true) then foundHC = true end
        if string.find(low, "turtle", 1, true)
            or string.find(low, "survival", 1, true)
            or string.find(low, "slow", 1, true)
            or string.find(low, "warmode", 1, true)
            or string.find(low, "ironman", 1, true) then
            foundTurtle = true
        end
    end
    if type(UnitBuff) == "function" then
        for i = 1, 32 do
            local ok, tex = pcall(UnitBuff, "player", i)
            if ok then CS_ScanTexture(tex) end
        end
    end
    if type(GetPlayerBuffTexture) == "function" then
        for i = 0, 31 do
            local ok, tex = pcall(GetPlayerBuffTexture, i)
            if ok then CS_ScanTexture(tex) end
        end
    end
    if foundHC then return "Modo: Hardcore Ativo" end
    if foundTurtle then return "Modo: Turtle Ativo" end
    return "Modo: Normal"
end

-- Altura visivel real do ScrollFrame (com fallback quando o layout 1.12
-- ainda nao calculou as dimensoes no primeiro frame).
function CharacterScreen:GetViewHeight()
    local vh = self.viewH or 0
    if self.scrollFrame and type(self.scrollFrame.GetHeight) == "function" then
        local h = self.scrollFrame:GetHeight()
        if type(h) == "number" and h > 0 then
            vh = h
        end
    end
    if not vh or vh <= 0 then
        vh = 380
    end
    self.viewH = vh
    return vh
end

function CharacterScreen:GetMaxScroll()
    local viewH = self:GetViewHeight()
    local maxScroll = (self.contentH or 0) - viewH
    if not maxScroll or maxScroll < 0 then
        maxScroll = 0
    end
    return maxScroll
end

-- Sincroniza a largura do ScrollChild com a largura real do ScrollFrame.
-- (Padrao que funciona em MainMenu.lua: zlContent/sc/GameMenu sc usam
-- SetWidth explicito — 222/460/536. So com TOPLEFT+TOPRIGHT o ScrollChild
-- 1.12 colapsa para largura 0 no primeiro frame e os blocos somem.)
function CharacterScreen:UpdateLayout()
    if not self.scrollFrame or not self.scrollChild then return end
    local w = 0
    if type(self.scrollFrame.GetWidth) == "function" then
        local sw = self.scrollFrame:GetWidth()
        if type(sw) == "number" and sw > 0 then w = sw end
    end
    if w <= 0 and self.parentFrame and type(self.parentFrame.GetWidth) == "function" then
        local pw = self.parentFrame:GetWidth()
        if type(pw) == "number" and pw > 16 then w = pw - 16 end
    end
    if w <= 0 then w = 460 end
    self.scrollChild:SetWidth(w)
    if self.contentH and self.contentH > 0 then
        self.scrollChild:SetHeight(self.contentH)
    end
end

-- Defer 0.05s via OnUpdate (mesmo padrao do MainMenu BAGS/SPELLS):
-- o layout 1.12 ainda nao calculou as dimensoes no primeiro frame.
function CharacterScreen:ScheduleLayoutRefresh()
    if not self.scrollFrame then return end
    if self._layoutRetry then
        self._layoutRetry.t = 0
        if type(self._layoutRetry.Show) == "function" then
            self._layoutRetry:Show()
        end
        return
    end
    local f = CreateFrame("Frame", nil, self.scrollFrame)
    f.t = 0
    f:SetScript("OnUpdate", function()
        this.t = this.t + arg1
        if this.t >= 0.05 then
            this:SetScript("OnUpdate", nil)
            this:Hide()
            CharacterScreen:UpdateLayout()
            if CharacterScreen.isVisible and CharacterScreen.scrollFrame then
                CharacterScreen.scrollFrame:Show()
                if type(CharacterScreen.scrollFrame.SetVerticalScroll) == "function" then
                    CharacterScreen.scrollFrame:SetVerticalScroll(CharacterScreen.scrollOffset or 0)
                end
            end
        end
    end)
    self._layoutRetry = f
end

-- ----------------------------------------------------------------------------
-- 3. CRIACAO DA UI (pool fixo: executar uma unica vez)
-- ----------------------------------------------------------------------------

-- Cria um card com titulo ambar + N linhas de texto. Pool fixo: chamado
-- apenas dentro de CreateUI; Refresh() so atualiza os FontStrings.
local function CS_MakeCard(scrollChild, name, titleText, height, numLines)
    local card = CreateFrame("Frame", name, scrollChild)
    card:SetHeight(height)
    card:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    card:SetBackdropColor(COLORS.blockBg.r, COLORS.blockBg.g, COLORS.blockBg.b, COLORS.blockBg.a)
    card:SetBackdropBorderColor(COLORS.blockBorder.r, COLORS.blockBorder.g, COLORS.blockBorder.b, COLORS.blockBorder.a)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
    title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -10)
    title:SetJustifyH("LEFT")
    CS_ApplyFont(title, FONTS.titleBold, 16)
    title:SetText(COLORS.amberText .. tostring(titleText) .. "|r")
    card.title = title

    card.lines = {}
    for i = 1, numLines do
        local y = -(30 + ((i - 1) * 20))
        local fs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", card, "TOPLEFT", 12, y)
        fs:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, y)
        fs:SetJustifyH("LEFT")
        CS_ApplyFont(fs, FONTS.medium, 13)
        if type(fs.SetTextColor) == "function" then
            fs:SetTextColor(COLORS.body.r, COLORS.body.g, COLORS.body.b)
        end
        fs:SetText("...")
        table.insert(card.lines, fs)
    end

    card:Show()
    return card
end

function CharacterScreen:CreateUI(parent)
    if self.scrollFrame then return end
    if not parent then return end

    -- Esconde o placeholder temporario da FASE 1 ("Modulo em Carregamento").
    CS_HidePlaceholder(parent)

    local scrollFrame = CreateFrame("ScrollFrame", "ConsoleMode_CharacterScrollFrame", parent)
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
    scrollFrame:EnableMouse(true)
    scrollFrame:EnableMouseWheel(true)

    -- FASE 4: 8 cards reais full-width 1 coluna; contentH dinamico
    -- (soma das alturas + gaps + padding inferior).
    local cardH1 = 200
    local cardH2 = 190
    local cardH3 = 150
    local cardH4 = 170
    local cardH5 = 150
    local cardH6 = 200
    local cardH7 = 170
    local cardH8 = 170
    local gap = self.cardGap or 12
    local contentH = cardH1 + cardH2 + cardH3 + cardH4 + cardH5
        + cardH6 + cardH7 + cardH8 + (gap * 7) + 8
    self.contentH = contentH

    local scrollChild = CreateFrame("Frame", "ConsoleMode_CharacterScrollChild", scrollFrame)
    scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
    -- Largura explicita (padrao MainMenu 1.12): sem isto o child colapsa
    -- para 0px no primeiro frame e os cards ficam invisiveis.
    local parentW = 0
    if type(parent.GetWidth) == "function" then
        local pw = parent:GetWidth()
        if type(pw) == "number" and pw > 16 then parentW = pw - 16 end
    end
    if parentW <= 0 then parentW = 460 end
    scrollChild:SetWidth(parentW)
    scrollChild:SetHeight(contentH)
    scrollFrame:SetScrollChild(scrollChild)
    -- SetVerticalScroll so DEPOIS do SetScrollChild (offset 0 garantido).
    self.scrollOffset = 0
    scrollFrame:SetVerticalScroll(0)

    self.cards = {}

    local yOff = -4

    local card1 = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCard1", "IDENTIDADE & BIOGRAFIA", cardH1, 6)
    card1:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
    card1:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
    table.insert(self.cards, card1)
    yOff = yOff - cardH1 - gap

    local card2 = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCard2", "ATRIBUTOS PRIMARIOS", cardH2, 6)
    card2:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
    card2:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
    table.insert(self.cards, card2)
    yOff = yOff - cardH2 - gap

    local card3 = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCard3", "RECURSOS & REGENERACAO", cardH3, 4)
    card3:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
    card3:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
    table.insert(self.cards, card3)
    yOff = yOff - cardH3 - gap

    -- FASE 4: 5 cards de combate (pool fixo, full-width 1 coluna).
    local card4 = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCard4", "COMBATE CORPO A CORPO (MELEE)", cardH4, 5)
    card4:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
    card4:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
    table.insert(self.cards, card4)
    yOff = yOff - cardH4 - gap

    local card5 = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCard5", "COMBATE A DISTANCIA (RANGED)", cardH5, 4)
    card5:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
    card5:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
    table.insert(self.cards, card5)
    yOff = yOff - cardH5 - gap

    local card6 = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCard6", "DEFESA & SOBREVIVENCIA", cardH6, 6)
    card6:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
    card6:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
    table.insert(self.cards, card6)
    yOff = yOff - cardH6 - gap

    local card7 = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCard7", "PODER MAGICO & CURA", cardH7, 5)
    card7:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
    card7:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
    table.insert(self.cards, card7)
    yOff = yOff - cardH7 - gap

    local card8 = CS_MakeCard(scrollChild, "ConsoleMode_CharacterCard8", "RESISTENCIAS ELEMENTAIS", cardH8, 5)
    card8:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
    card8:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
    table.insert(self.cards, card8)
    yOff = yOff - cardH8 - gap

    -- Roda do mouse (companheiro de mesa; o D-Pad continua sendo o principal).
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1 or 0
        if delta > 0 then
            CharacterScreen:Scroll(-CharacterScreen.scrollStep)
        elseif delta < 0 then
            CharacterScreen:Scroll(CharacterScreen.scrollStep)
        end
    end)

    scrollFrame:Hide()

    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild

    self:EnsureEventFrame()
    self:Refresh()
end

-- ----------------------------------------------------------------------------
-- 3b. REFRESH (rele as APIs 1.12 e atualiza os FontStrings do pool fixo)
-- ----------------------------------------------------------------------------
function CharacterScreen:Refresh()
    if not self.cards then return end

    -- CARD 1: Identidade & Biografia.
    local c1 = self.cards[1]
    if c1 and c1.lines and table.getn(c1.lines) >= 6 then
        local name = "?"
        if type(UnitName) == "function" then
            name = UnitName("player") or "?"
        end
        local level = 0
        if type(UnitLevel) == "function" then
            level = UnitLevel("player") or 0
        end
        local race = "?"
        if type(UnitRace) == "function" then
            race = UnitRace("player") or "?"
        end
        local classLoc = "?"
        local classFile = ""
        if type(UnitClass) == "function" then
            local a, b = UnitClass("player")
            if a and a ~= "" then classLoc = a end
            if b and b ~= "" then classFile = b end
        end
        local classHex = CS_ClassColorHex(classFile)

        local gname = nil
        local grank = nil
        if type(GetGuildInfo) == "function" then
            local ok, a, b = pcall(GetGuildInfo, "player")
            if ok then
                gname = a
                grank = b
            end
        end

        local prank = 0
        if type(UnitPVPRank) == "function" then
            prank = UnitPVPRank("player") or 0
        end
        local prankName = "Sem posto"
        if prank and prank > 0 and type(GetPVPRankInfo) == "function" then
            local ok, n = pcall(GetPVPRankInfo, prank)
            if ok and type(n) == "string" and n ~= "" then
                prankName = n
            end
        end

        local curXP = 0
        if type(UnitXP) == "function" then
            curXP = UnitXP("player") or 0
        end
        local maxXP = 0
        if type(UnitXPMax) == "function" then
            maxXP = UnitXPMax("player") or 0
        end
        local pct = 0
        if maxXP and maxXP > 0 then
            pct = math.floor((curXP / maxXP) * 100)
        end
        local rest = 0
        if type(GetXPExhaustion) == "function" then
            rest = GetXPExhaustion() or 0
        end
        if type(rest) ~= "number" then rest = 0 end

        local modeText = CS_DetectTurtleMode()

        c1.lines[1]:SetText("|cffffffff" .. tostring(name) .. "|r  Niv " .. tostring(CS_Num(level, 0)))
        c1.lines[2]:SetText(tostring(race) .. "  " .. classHex .. tostring(classLoc) .. "|r")
        if gname and gname ~= "" then
            c1.lines[3]:SetText("Guilda: " .. tostring(gname) .. " (" .. tostring(grank or "?") .. ")")
        else
            c1.lines[3]:SetText("Guilda: Sem guilda")
        end
        if prank and prank > 0 then
            c1.lines[4]:SetText("Posto: " .. tostring(prankName) .. " (Rank " .. tostring(prank) .. ")")
        else
            c1.lines[4]:SetText("Posto: Sem posto")
        end
        if rest > 0 then
            c1.lines[5]:SetText("XP: " .. tostring(curXP) .. "/" .. tostring(maxXP)
                .. " (" .. tostring(pct) .. "%)  Descansado")
        else
            c1.lines[5]:SetText("XP: " .. tostring(curXP) .. "/" .. tostring(maxXP)
                .. " (" .. tostring(pct) .. "%)")
        end
        c1.lines[6]:SetText(tostring(modeText))
    end

    -- CARD 2: Atributos Primarios (UnitStat 1..5: base, efetivo, pos, neg)
    -- + Armadura (UnitArmor: base, efetivo, armor, bonus — linha 6).
    local c2 = self.cards[2]
    if c2 and c2.lines and table.getn(c2.lines) >= 6 then
        for i = 1, 5 do
            local a, b, c, d = nil, nil, nil, nil
            if type(UnitStat) == "function" then
                a, b, c, d = UnitStat("player", i)
            end
            local eff = CS_Num(b, CS_Num(a, 0))
            local pos = CS_Num(c, 0)
            local neg = CS_Num(d, 0)
            local txt = tostring(STAT_NAMES[i]) .. ": " .. tostring(eff)
            if pos > 0 then
                txt = txt .. " " .. COLORS.bonusGreen .. "(+" .. tostring(pos) .. ")|r"
            elseif neg > 0 then
                txt = txt .. " " .. COLORS.penaltyRed .. "(-" .. tostring(neg) .. ")|r"
            end
            c2.lines[i]:SetText(txt)
        end
        local abase, aeff, aarmor, abonus = nil, nil, nil, nil
        if type(UnitArmor) == "function" then
            local ok, a, b, c, d = pcall(UnitArmor, "player")
            if ok then
                abase, aeff, aarmor, abonus = a, b, c, d
            end
        end
        local effArmor = CS_Num(aeff, CS_Num(aarmor, CS_Num(abase, 0)))
        local bonusArmor = CS_Num(abonus, 0)
        local armorTxt = "Armadura: " .. tostring(effArmor)
        if bonusArmor > 0 then
            armorTxt = armorTxt .. " " .. COLORS.bonusGreen .. "(+" .. tostring(bonusArmor) .. ")|r"
        end
        c2.lines[6]:SetText(armorTxt)
    end

    -- CARD 3: Recursos & Regeneracao. Sem API de regen na 1.12: exibe "—"
    -- em vez de numero falso.
    local c3 = self.cards[3]
    if c3 and c3.lines and table.getn(c3.lines) >= 4 then
        local hp = 0
        if type(UnitHealth) == "function" then
            hp = UnitHealth("player") or 0
        end
        local hpMax = 0
        if type(UnitHealthMax) == "function" then
            hpMax = UnitHealthMax("player") or 0
        end
        local mp = 0
        if type(UnitMana) == "function" then
            mp = UnitMana("player") or 0
        end
        local mpMax = 0
        if type(UnitManaMax) == "function" then
            mpMax = UnitManaMax("player") or 0
        end
        local ptype = 0
        if type(UnitPowerType) == "function" then
            ptype = UnitPowerType("player") or 0
        end
        local pname = "Mana"
        if ptype == 1 then
            pname = "Furia"
        elseif ptype == 3 then
            pname = "Energia"
        end
        c3.lines[1]:SetText("Vida: " .. tostring(hp) .. " / " .. tostring(hpMax))
        c3.lines[2]:SetText(tostring(pname) .. ": " .. tostring(mp) .. " / " .. tostring(mpMax))
        c3.lines[3]:SetText("Regen. Vida: — (sem API na 1.12)")
        c3.lines[4]:SetText("Regen. " .. tostring(pname) .. ": — (sem API na 1.12)")
    end

    -- CARD 4: Melee. UnitAttackPower (base/pos/neg -> efetivo),
    -- UnitDamage (min/max/offMin/offMax; off nil/zero = escudo),
    -- UnitAttackSpeed (main/off), DPS calculado, GetCritChance,
    -- GetHitModifier com type check (senao "—").
    local c4 = self.cards[4]
    if c4 and c4.lines and table.getn(c4.lines) >= 5 then
        local apBase, apPos, apNeg = nil, nil, nil
        if type(UnitAttackPower) == "function" then
            local ok, a, b, c = pcall(UnitAttackPower, "player")
            if ok then
                apBase, apPos, apNeg = a, b, c
            end
        end
        local apEff = CS_Num(apBase, 0) + CS_Num(apPos, 0) + CS_Num(apNeg, 0)
        local apTxt = "Poder de Ataque: " .. tostring(apEff)
        if CS_Num(apPos, 0) > 0 then
            apTxt = apTxt .. " " .. COLORS.bonusGreen .. "(+" .. tostring(CS_Num(apPos, 0)) .. ")|r"
        elseif CS_Num(apNeg, 0) < 0 then
            apTxt = apTxt .. " " .. COLORS.penaltyRed .. "(" .. tostring(CS_Num(apNeg, 0)) .. ")|r"
        end
        c4.lines[1]:SetText(apTxt)

        local dMin, dMax, dOffMin, dOffMax = nil, nil, nil, nil
        if type(UnitDamage) == "function" then
            local ok, a, b, c, d = pcall(UnitDamage, "player")
            if ok then
                dMin, dMax, dOffMin, dOffMax = a, b, c, d
            end
        end
        local sMain, sOff = nil, nil
        if type(UnitAttackSpeed) == "function" then
            local ok, a, b = pcall(UnitAttackSpeed, "player")
            if ok then
                sMain, sOff = a, b
            end
        end
        local mainTxt = "Arma principal: " .. tostring(CS_Num(dMin, 0)) .. "-" .. tostring(CS_Num(dMax, 0))
            .. "  Vel: " .. CS_Fmt2(sMain) .. "s  DPS: " .. CS_DPS(dMin, dMax, sMain)
        c4.lines[2]:SetText(mainTxt)

        local offMinN = CS_Num(dOffMin, 0)
        local offMaxN = CS_Num(dOffMax, 0)
        if (type(dOffMin) == "number" or type(dOffMax) == "number")
            and (offMinN > 0 or offMaxN > 0) then
            c4.lines[3]:SetText("Off-hand: " .. tostring(offMinN) .. "-" .. tostring(offMaxN)
                .. "  Vel: " .. CS_Fmt2(sOff) .. "s  DPS: " .. CS_DPS(dOffMin, dOffMax, sOff))
        else
            c4.lines[3]:SetText("Off-hand: -- (Escudo)")
        end

        local crit = nil
        if type(GetCritChance) == "function" then
            local ok, v = pcall(GetCritChance)
            if ok and type(v) == "number" then crit = v end
        end
        if type(crit) == "number" then
            c4.lines[4]:SetText("Critico: " .. CS_Fmt1(crit) .. "%")
        else
            c4.lines[4]:SetText("Critico: —")
        end

        local hit = nil
        if type(GetHitModifier) == "function" then
            local ok, v = pcall(GetHitModifier)
            if ok and type(v) == "number" then hit = v end
        end
        if type(hit) == "number" then
            c4.lines[5]:SetText("Acerto (Hit): " .. CS_Fmt1(hit) .. "%")
        else
            c4.lines[5]:SetText("Acerto (Hit): —")
        end
    end

    -- CARD 5: Ranged. UnitRangedAttackPower, UnitRangedDamage (2 ou 3
    -- retornos conforme o build: min/max ou speed/min/max),
    -- velocidade via UnitRangedAttackSpeed com type check (senao "—"),
    -- crit via GetRangedCritChance com fallback GetCritChance.
    local c5 = self.cards[5]
    if c5 and c5.lines and table.getn(c5.lines) >= 4 then
        local rapBase, rapPos, rapNeg = nil, nil, nil
        if type(UnitRangedAttackPower) == "function" then
            local ok, a, b, c = pcall(UnitRangedAttackPower, "player")
            if ok then
                rapBase, rapPos, rapNeg = a, b, c
            end
        end
        local rapEff = CS_Num(rapBase, 0) + CS_Num(rapPos, 0) + CS_Num(rapNeg, 0)
        c5.lines[1]:SetText("Poder de Ataque (dist.): " .. tostring(rapEff))

        local rMin, rMax, rSpeedFromDmg = nil, nil, nil
        if type(UnitRangedDamage) == "function" then
            local ok, a, b, c = pcall(UnitRangedDamage, "player")
            if ok then
                if type(c) == "number" and type(a) == "number" and type(b) == "number" then
                    rSpeedFromDmg, rMin, rMax = a, b, c
                elseif type(a) == "number" and type(b) == "number" then
                    rMin, rMax = a, b
                end
            end
        end
        local rSpeed = rSpeedFromDmg
        if type(UnitRangedAttackSpeed) == "function" then
            local ok, v = pcall(UnitRangedAttackSpeed, "player")
            if ok and type(v) == "number" then rSpeed = v end
        end
        if type(rMin) == "number" and type(rMax) == "number" then
            local spdTxt = "—"
            if type(rSpeed) == "number" then spdTxt = CS_Fmt2(rSpeed) .. "s" end
            c5.lines[2]:SetText("Dano: " .. tostring(CS_Num(rMin, 0)) .. "-" .. tostring(CS_Num(rMax, 0))
                .. "  Vel: " .. spdTxt .. "  DPS: " .. CS_DPS(rMin, rMax, rSpeed))
        else
            c5.lines[2]:SetText("Dano: — (sem arma de longo alcance)")
        end

        local rcrit = nil
        if type(GetRangedCritChance) == "function" then
            local ok, v = pcall(GetRangedCritChance)
            if ok and type(v) == "number" then rcrit = v end
        end
        if type(rcrit) ~= "number" and type(GetCritChance) == "function" then
            local ok, v = pcall(GetCritChance)
            if ok and type(v) == "number" then rcrit = v end
        end
        if type(rcrit) == "number" then
            c5.lines[3]:SetText("Critico (dist.): " .. CS_Fmt1(rcrit) .. "%")
        else
            c5.lines[3]:SetText("Critico (dist.): —")
        end

        local rhit = nil
        if type(GetHitModifier) == "function" then
            local ok, v = pcall(GetHitModifier)
            if ok and type(v) == "number" then rhit = v end
        end
        if type(rhit) == "number" then
            c5.lines[4]:SetText("Acerto (Hit): " .. CS_Fmt1(rhit) .. "%")
        else
            c5.lines[4]:SetText("Acerto (Hit): —")
        end
    end

    -- CARD 6: Defesa. UnitArmor (valor + texto honesto, sem formula
    -- exata de mitigacao na 1.12), UnitDefense (atual/max),
    -- GetDodgeChance/GetParryChance/GetBlockChance/GetShieldBlock.
    local c6 = self.cards[6]
    if c6 and c6.lines and table.getn(c6.lines) >= 6 then
        local dbase, deff, darmor, dbonus = nil, nil, nil, nil
        if type(UnitArmor) == "function" then
            local ok, a, b, c, d = pcall(UnitArmor, "player")
            if ok then
                dbase, deff, darmor, dbonus = a, b, c, d
            end
        end
        local effArmor = CS_Num(deff, CS_Num(darmor, CS_Num(dbase, 0)))
        c6.lines[1]:SetText("Armadura: " .. tostring(effArmor) .. " (sem formula exata na 1.12)")

        local defCur, defMax = nil, nil
        if type(UnitDefense) == "function" then
            local ok, a, b = pcall(UnitDefense, "player")
            if ok then
                defCur, defMax = a, b
            end
        end
        if type(defCur) == "number" then
            c6.lines[2]:SetText("Defesa: " .. tostring(defCur) .. " / " .. tostring(CS_Num(defMax, defCur)))
        else
            c6.lines[2]:SetText("Defesa: —")
        end

        local dodge = nil
        if type(GetDodgeChance) == "function" then
            local ok, v = pcall(GetDodgeChance)
            if ok and type(v) == "number" then dodge = v end
        end
        if type(dodge) == "number" then
            c6.lines[3]:SetText("Esquiva: " .. CS_Fmt1(dodge) .. "%")
        else
            c6.lines[3]:SetText("Esquiva: —")
        end

        local parry = nil
        if type(GetParryChance) == "function" then
            local ok, v = pcall(GetParryChance)
            if ok and type(v) == "number" then parry = v end
        end
        if type(parry) == "number" then
            c6.lines[4]:SetText("Aparo: " .. CS_Fmt1(parry) .. "%")
        else
            c6.lines[4]:SetText("Aparo: —")
        end

        local block = nil
        if type(GetBlockChance) == "function" then
            local ok, v = pcall(GetBlockChance)
            if ok and type(v) == "number" then block = v end
        end
        if type(block) == "number" then
            c6.lines[5]:SetText("Bloqueio: " .. CS_Fmt1(block) .. "%")
        else
            c6.lines[5]:SetText("Bloqueio: —")
        end

        local blockVal = nil
        if type(GetShieldBlock) == "function" then
            local ok, v = pcall(GetShieldBlock)
            if ok and type(v) == "number" then blockVal = v end
        end
        if type(blockVal) == "number" then
            c6.lines[6]:SetText("Valor de Bloqueio: " .. tostring(blockVal))
        else
            c6.lines[6]:SetText("Valor de Bloqueio: —")
        end
    end

    -- CARD 7: Magico. 1.12 puro NAO tem GetSpellBonusDamage nem
    -- GetPlayerSpellBonus: type check em ambas; se nenhuma existir,
    -- linhas honestas "+0 (sem API na 1.12)". NUNCA inventar numero.
    -- Critico via GetSpellCritChance com type check (senao "—").
    local c7 = self.cards[7]
    if c7 and c7.lines and table.getn(c7.lines) >= 5 then
        local hasSpellAPI = (type(GetSpellBonusDamage) == "function")
            or (type(GetPlayerSpellBonus) == "function")
        if hasSpellAPI then
            c7.lines[1]:SetText("Poder de Cura (+Heal): (via API — ver tooltip)")
            c7.lines[2]:SetText("Sagrado/Fogo/Natureza: (via API — ver tooltip)")
            c7.lines[3]:SetText("Gelo/Sombra/Arcano: (via API — ver tooltip)")
        else
            c7.lines[1]:SetText("Poder de Cura (+Heal): +0 (sem API na 1.12)")
            c7.lines[2]:SetText("Sagrado/Fogo/Natureza: +0 (sem API na 1.12)")
            c7.lines[3]:SetText("Gelo/Sombra/Arcano: +0 (sem API na 1.12)")
        end
        local scrit = nil
        if type(GetSpellCritChance) == "function" then
            local ok, v = pcall(GetSpellCritChance)
            if ok and type(v) == "number" then scrit = v end
        end
        if type(scrit) == "number" then
            c7.lines[4]:SetText("Critico Magico: " .. CS_Fmt1(scrit) .. "%")
        else
            c7.lines[4]:SetText("Critico Magico: —")
        end
        c7.lines[5]:SetText("Regen. Mana (MP5): — (sem API na 1.12)")
    end

    -- CARD 8: Resistencias. UnitResistance("player", 2..6)
    -- (indice 1 = Armadura, pulado). Exibe total + barra textual
    -- proporcional via string.rep; sem criar textures novas.
    local c8 = self.cards[8]
    if c8 and c8.lines and table.getn(c8.lines) >= 5 then
        local resNames = { "Fogo", "Natureza", "Gelo", "Sombra", "Arcano" }
        for i = 1, 5 do
            local rid = i + 1
            local rbase, rtotal, rpos, rneg = nil, nil, nil, nil
            if type(UnitResistance) == "function" then
                local ok, a, b, c, d = pcall(UnitResistance, "player", rid)
                if ok then
                    rbase, rtotal, rpos, rneg = a, b, c, d
                end
            end
            local tot = CS_Num(rtotal, CS_Num(rbase, 0))
            local line = tostring(resNames[i]) .. ": " .. tostring(tot)
                .. " " .. CS_ResistBar(tot)
            local pos = CS_Num(rpos, 0)
            local neg = CS_Num(rneg, 0)
            if pos > 0 then
                line = line .. " " .. COLORS.bonusGreen .. "(+" .. tostring(pos) .. ")|r"
            elseif neg < 0 then
                line = line .. " " .. COLORS.penaltyRed .. "(" .. tostring(neg) .. ")|r"
            end
            c8.lines[i]:SetText(line)
        end
    end
end

-- Frame de eventos criado uma unica vez; OnEvent so atualiza se visivel.
function CharacterScreen:EnsureEventFrame()
    if self.eventFrame then return end
    local f = CreateFrame("Frame", "ConsoleMode_CharacterEventFrame")
    if type(f.RegisterEvent) == "function" then
        f:RegisterEvent("UNIT_STATS")
        f:RegisterEvent("UNIT_HEALTH")
        f:RegisterEvent("UNIT_MANA")
        f:RegisterEvent("PLAYER_XP_UPDATE")
        f:RegisterEvent("UNIT_INVENTORY_CHANGED")
        -- FASE 4 (canonicos 1.12): combate/defesa/resistencias.
        f:RegisterEvent("UNIT_ATTACK_POWER")
        f:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
        f:RegisterEvent("UNIT_RESISTANCES")
    end
    f:SetScript("OnEvent", function()
        if event and string.sub(event, 1, 5) == "UNIT_" and arg1 ~= "player" then
            return
        end
        if CharacterScreen.isVisible then
            CharacterScreen:Refresh()
        end
    end)
    self.eventFrame = f
end

-- ----------------------------------------------------------------------------
-- 4. CICLO DE VIDA (molde MerchantMenu/MailScreen)
-- ----------------------------------------------------------------------------
function CharacterScreen:Initialize()
    if self.initialized then return end
    self.initialized = true
end

function CharacterScreen:AttachTo(parentFrame)
    self:Initialize()
    if not parentFrame then
        CS_ChatError("AttachTo recebeu parent nil")
        return
    end
    self.parentFrame = parentFrame
    if not self.attached then
        self:CreateUI(parentFrame)
        self.attached = (self.scrollFrame ~= nil)
        if not self.attached then
            CS_ChatError("CreateUI falhou (scrollFrame nil)")
            return
        end
    elseif self.scrollFrame and self.scrollFrame:GetParent() ~= parentFrame then
        self.scrollFrame:SetParent(parentFrame)
        self.scrollFrame:ClearAllPoints()
        self.scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 8, -8)
        self.scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -8, 8)
    end
    CS_HidePlaceholder(parentFrame)
    self:EnsureEventFrame()
    self:UpdateLayout()
end

function CharacterScreen:Show()
    -- Garante a page hospedeira visivel (o loop Show/Hide do SelectTab roda
    -- antes do AttachTo; re-afirma aqui para nada sobrescrever).
    if self.parentFrame and type(self.parentFrame.Show) == "function" then
        self.parentFrame:Show()
    end
    CS_HidePlaceholder(self.parentFrame)
    if self.scrollFrame then
        self.scrollFrame:Show()
    else
        CS_ChatError("Show com scrollFrame nil (AttachTo nao rodou?)")
        return
    end
    self.isVisible = true
    -- Primeiro Show sempre parte do offset 0 (nada de fallback 380 jogando
    -- o conteudo para fora da vista).
    if not self.firstShown then
        self.scrollOffset = 0
        self.firstShown = true
    end
    -- Dados vivos a cada abertura.
    self:Refresh()
    -- Reaplica o offset atual (o layout 1.12 pode zerar o scroll no Hide).
    if type(self.scrollFrame.SetVerticalScroll) == "function" then
        self.scrollFrame:SetVerticalScroll(CS_Clamp(self.scrollOffset or 0, 0, self:GetMaxScroll()))
    end
    self:UpdateLayout()
    self:ScheduleLayoutRefresh()
end

function CharacterScreen:Hide()
    self.isVisible = false
    if self.scrollFrame and type(self.scrollFrame.Hide) == "function" then
        self.scrollFrame:Hide()
    end
end

function CharacterScreen:IsVisible()
    return self.isVisible
end

-- ----------------------------------------------------------------------------
-- 5. ROLAGEM (Scroll com clamp 0..(contentH - viewH))
-- ----------------------------------------------------------------------------
function CharacterScreen:Scroll(delta)
    if not self.scrollFrame then return 0 end
    local maxScroll = self:GetMaxScroll()
    local cur = self.scrollOffset or 0
    cur = CS_Clamp(cur + (delta or 0), 0, maxScroll)
    self.scrollOffset = cur
    if type(self.scrollFrame.SetVerticalScroll) == "function" then
        self.scrollFrame:SetVerticalScroll(cur)
    end
    return cur
end

-- D-Pad: UP volta (offset -step), DOWN avanca (offset +step).
-- Retorna true quando consome a direcao (contrato do MainMenuNav).
function CharacterScreen:OnDirection(direction)
    if direction == "UP" then
        self:Scroll(-(self.scrollStep or 60))
        return true
    elseif direction == "DOWN" then
        self:Scroll(self.scrollStep or 60)
        return true
    end
    return false
end

-- Inicializacao automatica no carregamento (molde MailScreen: so marca o
-- modulo como inicializado; o AttachTo acontece via MainMenu:SelectTab).
local csAutoInit = CreateFrame("Frame")
csAutoInit:RegisterEvent("VARIABLES_LOADED")
csAutoInit:SetScript("OnEvent", function()
    CharacterScreen:Initialize()
end)
