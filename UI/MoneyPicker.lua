-- ============================================================================
-- ConsoleModeVanilla - UI/MoneyPicker.lua
-- Modal genérico de edição de valores monetários (compartilhado entre telas,
-- ex: MailScreen e AuctionScreen): 8 roletas de dígitos (4 ouro, 2 prata, 2 cobre),
-- navegação via D-Pad (Left/Right dígito, Up/Down girar 0-9), confirmação (A),
-- cancelamento (B), suporte a mouse wheel e botões clicáveis no rodapé.
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW).
-- ============================================================================

ConsoleMode_MoneyPicker = ConsoleMode_MoneyPicker or {}
local MP = ConsoleMode_MoneyPicker
local CM = ConsoleMode or {}
CM.MoneyPicker = MP

local FONTS = {
    titleBold = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    bodyBold  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    medium    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Medium.ttf",
    fallback  = "Fonts\\FRIZQT__.TTF",
}

local ICONS = {
    A      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\A.tga",
    B      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\B.tga",
    DUP    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DUP.tga",
    DDOWN  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DDOWN.tga",
    DLEFT  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DLEFT.tga",
    DRIGHT = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DRIGHT.tga",
}

local function ApplyFont(fontString, fontPath, size)
    if not fontString then return end
    fontPath = fontPath or FONTS.bodyBold
    size = size or 12
    local ok = fontString:SetFont(fontPath, size, "")
    if not ok then
        fontString:SetFont(FONTS.fallback, size, "")
    end
    fontString:SetShadowOffset(1, -1)
    fontString:SetShadowColor(0, 0, 0, 0.90)
end

local function FormatMoneyText(totalCopper)
    totalCopper = totalCopper or 0
    if totalCopper < 0 then totalCopper = 0 end

    local gold   = math.floor(totalCopper / 10000)
    local silver = math.floor(math.mod(totalCopper, 10000) / 100)
    local copper = math.floor(math.mod(totalCopper, 100))

    local text = ""
    if gold > 0 then
        text = text .. "|cffffd700" .. gold .. "g|r "
    end
    if silver > 0 or gold > 0 then
        text = text .. "|cffc7c7cf" .. silver .. "s|r "
    end
    text = text .. "|cffeda55f" .. copper .. "c|r"
    return text
end

local function GetPlayerCopper()
    if GetMoney then
        local ok, v = pcall(GetMoney)
        if ok and tonumber(v) then return tonumber(v) end
    end
    return 0
end

MP.state = MP.state or {
    isOpen      = false,
    title       = nil,
    copper      = 0,
    minCopper   = 0,
    maxCopper   = nil,
    showBalance = false,
    postageCost = 0,
    digitIndex  = 1,
    digits      = { 0, 0, 0, 0, 0, 0, 0, 0 },
    onConfirm   = nil,
    onCancel    = nil,
    ctx         = nil,
}

MP.frame = MP.frame or nil
MP.dimmer = MP.dimmer or nil

function MP:IsOpen()
    if self.state.isOpen then return true end
    if self.frame and self.frame.IsVisible and self.frame:IsVisible() then
        return true
    end
    return false
end

function MP:GetCopperFromDigits()
    local d = self.state.digits or {}
    local function dig(i) return tonumber(d[i]) or 0 end
    local gold = dig(1) * 1000 + dig(2) * 100 + dig(3) * 10 + dig(4)
    local silver = dig(5) * 10 + dig(6)
    local copper = dig(7) * 10 + dig(8)
    return (gold * 100 + silver) * 100 + copper
end

function MP:Open(cfg)
    cfg = cfg or {}
    if self:IsOpen() then self:Close(true) end

    local initialCopper = math.floor(tonumber(cfg.copper) or 0)
    if initialCopper < 0 then initialCopper = 0 end

    local gold = math.floor(initialCopper / 10000)
    local rem = initialCopper - gold * 10000
    local silver = math.floor(rem / 100)
    local co = rem - silver * 100
    if gold > 9999 then gold = 9999 end

    self.state.isOpen = true
    self.state.title = cfg.title or CM:T("MAIL_MONEY_TITLE") or "Definir Valor"
    self.state.copper = initialCopper
    self.state.minCopper = tonumber(cfg.minCopper) or 0
    self.state.maxCopper = tonumber(cfg.maxCopper)
    self.state.showBalance = cfg.showBalance or false
    self.state.postageCost = tonumber(cfg.postageCost) or 0
    self.state.digitIndex = 1
    self.state.digits = {
        math.floor(gold / 1000),
        math.floor(math.mod(gold, 1000) / 100),
        math.floor(math.mod(gold, 100) / 10),
        math.mod(gold, 10),
        math.floor(silver / 10),
        math.mod(silver, 10),
        math.floor(co / 10),
        math.mod(co, 10),
    }
    self.state.onConfirm = cfg.onConfirm
    self.state.onCancel = cfg.onCancel
    self.state.ctx = cfg.ctx

    self:CreateDimmer()
    self:CreateUI()
    self:UpdateVisuals()

    if self.dimmer then self.dimmer:Show() end
    if self.frame then self.frame:Show() end
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    return true
end

function MP:Close(silent)
    self.state.isOpen = false
    self.state.onConfirm = nil
    self.state.onCancel = nil
    self.state.ctx = nil

    if self.dimmer and self.dimmer.IsVisible and self.dimmer:IsVisible() then
        self.dimmer:Hide()
    end
    if self.frame and self.frame.IsVisible and self.frame:IsVisible() then
        self.frame:Hide()
    end
    if not silent then
        if PlaySound then PlaySound("igMainMenuClose") end
    end
end

function MP:Cancel()
    if not self:IsOpen() then return end
    local cb, ctx = self.state.onCancel, self.state.ctx
    self:Close()
    if cb then pcall(cb, ctx) end
end

function MP:Confirm()
    if not self:IsOpen() then return end
    local total = self:GetCopperFromDigits()

    -- Validação de piso
    if self.state.minCopper and total < self.state.minCopper then
        total = self.state.minCopper
    end

    -- Validação de teto (ex: saldo em correio)
    if self.state.maxCopper and total > self.state.maxCopper then
        if CM.logger and CM.logger.Log then
            CM.logger:Log(string.format(CM:T("MAIL_LOG_MONEY_ABOVE") or "Valor acima do saldo (%s).", FormatMoneyText(self.state.maxCopper)))
        end
        if PlaySound then PlaySound("igQuestFailed") end
        return
    end

    local cb, ctx = self.state.onConfirm, self.state.ctx
    self:Close(true)
    if cb then
        pcall(cb, total, ctx)
    end
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
end

function MP:Spin(delta)
    if not self:IsOpen() then return end
    delta = tonumber(delta) or 0
    local idx = tonumber(self.state.digitIndex) or 1
    if idx < 1 then idx = 1 end
    if idx > 8 then idx = 8 end
    local d = self.state.digits or {}
    local cur = tonumber(d[idx]) or 0
    cur = math.mod(cur + delta, 10)
    if cur < 0 then cur = cur + 10 end
    d[idx] = cur
    if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
    self:UpdateVisuals()
end

function MP:Direction(direction)
    if not self:IsOpen() then return end
    if direction == "LEFT" then
        local idx = (tonumber(self.state.digitIndex) or 1) - 1
        if idx < 1 then idx = 1 end
        if idx ~= self.state.digitIndex then
            self.state.digitIndex = idx
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
            self:UpdateVisuals()
        end
    elseif direction == "RIGHT" then
        local idx = (tonumber(self.state.digitIndex) or 1) + 1
        if idx > 8 then idx = 8 end
        if idx ~= self.state.digitIndex then
            self.state.digitIndex = idx
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
            self:UpdateVisuals()
        end
    elseif direction == "UP" then
        self:Spin(1)
    elseif direction == "DOWN" then
        self:Spin(-1)
    end
end

function MP:UpdateVisuals()
    local m = self.frame
    if not m then return end

    if m.title then
        m.title:SetText(tostring(self.state.title or "Definir Valor"))
    end

    local d = self.state.digits or {}
    local active = tonumber(self.state.digitIndex) or 1
    for i = 1, 8 do
        local b = m.digitBtns and m.digitBtns[i]
        local t = m.digitTexts and m.digitTexts[i]
        if b and t then
            t:SetText(tostring(tonumber(d[i]) or 0))
            if i == active then
                b:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.00)
                b:SetBackdropColor(0.28, 0.20, 0.08, 0.95)
            else
                b:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.60)
                b:SetBackdropColor(0.0, 0.0, 0.0, 0.55)
            end
        end
    end

    local total = self:GetCopperFromDigits()
    if m.totalText then
        local fmt = CM:T("MAIL_TOTAL_FMT") or "Total: %s"
        m.totalText:SetText(format(fmt, FormatMoneyText(total)))
    end

    if m.balanceText then
        if self.state.showBalance then
            local balance = GetPlayerCopper()
            local postage = tonumber(self.state.postageCost) or 0
            local fmt = CM:T("MAIL_BALANCE_FMT") or "Saldo: %s  |  Taxa: %s"
            local line = format(fmt, FormatMoneyText(balance), FormatMoneyText(postage))
            if total > balance then
                line = line .. (CM:T("MAIL_BALANCE_LOW") or " |cffff2020(insuficiente)|r")
            end
            m.balanceText:SetText(line)
            m.balanceText:Show()
        else
            m.balanceText:SetText("")
            m.balanceText:Hide()
        end
    end
end

local function BuildHints(parent, frameName, hints, bottomOffset)
    local container = CreateFrame("Frame", frameName, parent)
    container:SetHeight(34)
    container:SetPoint("CENTER", parent, "BOTTOM", 0, bottomOffset or 52)

    local totalWidth = 0
    local widgets = {}
    local numHints = table.getn(hints)
    for i = 1, numHints do
        local hint = hints[i]
        local groupFrame = CreateFrame("Frame", nil, container)
        groupFrame:SetHeight(34)
        local currentX = 0
        local numIcons = table.getn(hint.icons)
        for k = 1, numIcons do
            local texPath = ICONS[hint.icons[k]]
            if texPath then
                local iconTex = groupFrame:CreateTexture(nil, "OVERLAY")
                iconTex:SetWidth(27)
                iconTex:SetHeight(27)
                iconTex:SetTexture(texPath)
                iconTex:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
                currentX = currentX + 27 + 3
            end
        end
        currentX = currentX + 5
        local label = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", groupFrame, "LEFT", currentX, 0)
        ApplyFont(label, FONTS.bodyBold, 18)
        label:SetText(hint.label)
        label:SetTextColor(0.85, 0.85, 0.85, 0.95)
        local textW = math.floor(label:GetStringWidth() or 40)
        currentX = currentX + textW
        if i < numHints then
            local sep = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            sep:SetPoint("LEFT", groupFrame, "LEFT", currentX + 5, 0)
            ApplyFont(sep, FONTS.medium, 14)
            sep:SetText("|cff666666•|r")
            currentX = currentX + 5 + 14
        end
        groupFrame:SetWidth(currentX)
        table.insert(widgets, groupFrame)
        totalWidth = totalWidth + currentX
    end
    local curX = -math.floor(totalWidth / 2)
    local numWidgets = table.getn(widgets)
    for w = 1, numWidgets do
        local widget = widgets[w]
        widget:SetPoint("LEFT", container, "CENTER", curX, 0)
        curX = curX + widget:GetWidth()
    end
    container:SetWidth(totalWidth)
    return container
end

function MP:CreateDimmer()
    if self.dimmer then return self.dimmer end
    local d = CreateFrame("Frame", "ConsoleMode_MoneyPickerDimmer", UIParent)
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:SetFrameLevel(45)
    d:SetAllPoints(UIParent)
    d:EnableMouse(true)
    local bg = d:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(d)
    bg:SetTexture(0, 0, 0, 0.65)
    d.bg = bg
    d:Hide()
    self.dimmer = d
    return d
end

function MP:CreateUI()
    if self.frame then return self.frame end

    local m = CreateFrame("Frame", "ConsoleMode_MoneyPicker", UIParent)
    m:SetWidth(480)
    m:SetHeight(330)
    m:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    m:SetFrameStrata("FULLSCREEN_DIALOG")
    m:SetFrameLevel(50)
    m:EnableMouse(true)
    m:EnableMouseWheel(true)
    m:SetMovable(false)
    m:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    m:SetBackdropColor(0.08, 0.06, 0.04, 1.0)
    m:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
    m:Hide()

    local title = m:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", m, "TOP", 0, -14)
    ApplyFont(title, FONTS.titleBold, 19)
    title:SetText(CM:T("MAIL_MONEY_TITLE") or "Definir Valor")
    m.title = title

    -- Fileira de 8 reels: passo 50px (44 larg + 6 gap), +10 após grupos.
    local row = CreateFrame("Frame", nil, m)
    row:SetWidth(414)
    row:SetHeight(56)
    row:SetPoint("TOP", m, "TOP", 0, -48)
    m.digitRow = row
    m.digitBtns = {}
    m.digitTexts = {}

    local x = 0
    for i = 1, 8 do
        if i == 5 or i == 7 then x = x + 10 end
        local di = i
        local b = CreateFrame("Button", "ConsoleMode_MoneyPickerDigit" .. i, row)
        b:SetWidth(44)
        b:SetHeight(56)
        b:SetPoint("LEFT", row, "LEFT", x, 0)
        b:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        b:SetBackdropColor(0.0, 0.0, 0.0, 0.55)
        b:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.60)
        local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        t:SetPoint("CENTER", b, "CENTER", 0, 0)
        ApplyFont(t, FONTS.titleBold, 26)
        t:SetText("0")
        b.digitPos = di
        b:RegisterForClicks("LeftButtonUp")
        b:SetScript("OnClick", function()
            MP.state.digitIndex = this.digitPos
            MP:UpdateVisuals()
            if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        end)
        m.digitBtns[di] = b
        m.digitTexts[di] = t
        x = x + 50
    end

    -- Rótulos dos grupos (ouro, prata, cobre)
    local goldL = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    goldL:SetPoint("TOP", row, "BOTTOM", -110, -2)
    ApplyFont(goldL, FONTS.titleBold, 13)
    goldL:SetText(CM:T("MAIL_GOLD") or "Ouro")

    local silverL = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    silverL:SetPoint("TOP", row, "BOTTOM", 44, -2)
    ApplyFont(silverL, FONTS.titleBold, 13)
    silverL:SetText(CM:T("MAIL_SILVER") or "Prata")

    local copperL = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    copperL:SetPoint("TOP", row, "BOTTOM", 148, -2)
    ApplyFont(copperL, FONTS.titleBold, 13)
    copperL:SetText(CM:T("MAIL_COPPER") or "Cobre")

    local total = m:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    total:SetPoint("TOP", row, "BOTTOM", 0, -24)
    total:SetWidth(440)
    total:SetJustifyH("CENTER")
    ApplyFont(total, FONTS.titleBold, 18)
    total:SetText("")
    m.totalText = total

    local balance = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    balance:SetPoint("TOP", total, "BOTTOM", 0, -4)
    balance:SetWidth(440)
    balance:SetJustifyH("CENTER")
    ApplyFont(balance, FONTS.bodyBold, 14)
    balance:SetText("")
    m.balanceText = balance

    -- Hints de controle com ícones
    local moneyHints = {
        { icons = { "DLEFT", "DRIGHT" }, label = CM:T("MAIL_HINT_DIGIT") or "dígito" },
        { icons = { "DUP", "DDOWN" },    label = CM:T("MAIL_HINT_SPIN") or "girar" },
        { icons = { "A" },               label = CM:T("HINT_CONFIRM") or "confirmar" },
        { icons = { "B" },               label = CM:T("HINT_CANCEL") or "cancelar" },
    }
    m.hints = BuildHints(m, "ConsoleMode_MoneyPickerHints", moneyHints, 52)

    local confirmBtn = CreateFrame("Button", "ConsoleMode_MoneyPickerConfirmYes", m)
    confirmBtn:SetWidth(150)
    confirmBtn:SetHeight(28)
    confirmBtn:SetPoint("BOTTOMLEFT", m, "BOTTOM", -160, 10)
    confirmBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    confirmBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    confirmBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local confirmIcon = confirmBtn:CreateTexture(nil, "OVERLAY")
    confirmIcon:SetWidth(22)
    confirmIcon:SetHeight(22)
    confirmIcon:SetPoint("LEFT", confirmBtn, "LEFT", 6, 0)
    confirmIcon:SetTexture(ICONS.A)

    local confirmTxt = confirmBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    confirmTxt:SetPoint("LEFT", confirmIcon, "RIGHT", 5, 0)
    ApplyFont(confirmTxt, FONTS.titleBold, 15)
    confirmTxt:SetText(CM:T("MAIL_CONFIRM") or "Confirmar")
    confirmBtn:SetScript("OnClick", function()
        MP:Confirm()
    end)
    confirmBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    confirmBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    m.confirmBtn = confirmBtn

    local cancelBtn = CreateFrame("Button", "ConsoleMode_MoneyPickerConfirmNo", m)
    cancelBtn:SetWidth(150)
    cancelBtn:SetHeight(28)
    cancelBtn:SetPoint("BOTTOMRIGHT", m, "BOTTOM", 160, 10)
    cancelBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    cancelBtn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    cancelBtn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)

    local cancelIcon = cancelBtn:CreateTexture(nil, "OVERLAY")
    cancelIcon:SetWidth(22)
    cancelIcon:SetHeight(22)
    cancelIcon:SetPoint("LEFT", cancelBtn, "LEFT", 6, 0)
    cancelIcon:SetTexture(ICONS.B)

    local cancelTxt = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cancelTxt:SetPoint("LEFT", cancelIcon, "RIGHT", 5, 0)
    ApplyFont(cancelTxt, FONTS.titleBold, 15)
    cancelTxt:SetText(CM:T("BTN_CANCEL") or "Cancelar")
    cancelBtn:SetScript("OnClick", function()
        MP:Cancel()
    end)
    cancelBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        this:SetBackdropColor(0.20, 0.15, 0.10, 0.90)
    end)
    cancelBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
        this:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
    end)
    m.cancelBtn = cancelBtn

    m:SetScript("OnMouseWheel", function()
        if arg1 > 0 then
            MP:Spin(1)
        else
            MP:Spin(-1)
        end
    end)
    m:SetScript("OnHide", function()
        MP.state.isOpen = false
        if MP.dimmer and MP.dimmer:IsVisible() then
            MP.dimmer:Hide()
        end
    end)
    table.insert(UISpecialFrames, "ConsoleMode_MoneyPicker")

    self.frame = m
    return m
end
