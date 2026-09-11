-- ============================================================================
-- ConsoleModeVanilla - UI/QuantityPicker.lua
-- Modal generico de quantidade (mesma janela p/ mail e main menu): titulo,
-- nome do item, numero grande xN/max, EditBox numerica p/ mouse, hints com
-- icones (D-Pad ajustar, A confirmar, B cancelar) + botoes clicaveis.
-- Uso: QuantityPicker:Open({title, itemName, qty, maxQty, onConfirm, onCancel,
-- ctx}); fim via onConfirm(qty, ctx) / onCancel(ctx). Direcao: UP/DOWN +-1,
-- LEFT/RIGHT +-5 (teto = maxQty). B/A/mouse via chamador ou botoes internos.
-- Compativel com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW).
-- ============================================================================

ConsoleMode_QuantityPicker = ConsoleMode_QuantityPicker or {}
local QP = ConsoleMode_QuantityPicker
local CM = ConsoleMode or {}
CM.QuantityPicker = QP

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

QP.state = QP.state or {
    isOpen = false, title = "Quantidade", itemName = "Item",
    qty = 1, maxQty = 1, onConfirm = nil, onCancel = nil, ctx = nil,
}
QP.frame = QP.frame or nil

function QP:IsOpen()
    if self.state.isOpen then return true end
    if self.frame and self.frame.IsVisible and self.frame:IsVisible() then
        return true
    end
    return false
end

function QP:Open(cfg)
    cfg = cfg or {}
    if self:IsOpen() then self:Close(true) end
    local maxQ = math.floor(tonumber(cfg.maxQty) or 1)
    if maxQ < 1 then maxQ = 1 end
    local q = math.floor(tonumber(cfg.qty) or maxQ)
    if q < 1 then q = 1 end
    if q > maxQ then q = maxQ end
    self.state.isOpen = true
    self.state.title = tostring(cfg.title or "Quantidade")
    self.state.itemName = tostring(cfg.itemName or "Item")
    self.state.qty = q
    self.state.maxQty = maxQ
    self.state.onConfirm = cfg.onConfirm
    self.state.onCancel = cfg.onCancel
    self.state.ctx = cfg.ctx
    self:CreateUI()
    self:UpdateVisuals()
    self.frame:Show()
    return true
end

function QP:Close(silent)
    self.state.isOpen = false
    self.state.onConfirm = nil
    self.state.onCancel = nil
    self.state.ctx = nil
    if self.frame and self.frame.IsVisible and self.frame:IsVisible() then
        self.frame:Hide()
    end
    if not silent then
        if PlaySound then PlaySound("igMainMenuClose") end
    end
end

function QP:Cancel()
    if not self:IsOpen() then return end
    local cb, ctx = self.state.onCancel, self.state.ctx
    self:Close()
    if cb then pcall(cb, ctx) end
end

function QP:Confirm()
    if not self:IsOpen() then return end
    self:SyncFromEditBox()
    local q = tonumber(self.state.qty) or 1
    local cb, ctx = self.state.onConfirm, self.state.ctx
    self:Close(true)
    if cb then pcall(cb, q, ctx) end
end

function QP:Adjust(delta)
    if not self:IsOpen() then return end
    delta = tonumber(delta) or 0
    local q = (tonumber(self.state.qty) or 1) + delta
    local mx = tonumber(self.state.maxQty) or 1
    if q < 1 then q = 1 end
    if q > mx then q = mx end
    if q ~= self.state.qty then
        self.state.qty = q
        if PlaySound then PlaySound("igMainMenuOptionCheckBoxOn") end
        self:UpdateVisuals()
    end
end

function QP:Direction(direction)
    if direction == "UP" then
        self:Adjust(1)
    elseif direction == "DOWN" then
        self:Adjust(-1)
    elseif direction == "LEFT" then
        self:Adjust(-5)
    elseif direction == "RIGHT" then
        self:Adjust(5)
    end
end

function QP:SyncFromEditBox()
    if not self:IsOpen() then return end
    local m = self.frame
    if not m or not m.qtyEditBox then return end
    local ok, txt = pcall(function() return m.qtyEditBox:GetText() end)
    if not ok then return end
    local q = math.floor(tonumber(txt) or (self.state.qty or 1))
    local mx = tonumber(self.state.maxQty) or 1
    if q < 1 then q = 1 end
    if q > mx then q = mx end
    self.state.qty = q
    self:UpdateVisuals()
end

function QP:UpdateVisuals()
    local m = self.frame
    if not m then return end
    local qty = tonumber(self.state.qty) or 1
    local mx = tonumber(self.state.maxQty) or 1
    if m.title then
        m.title:SetText("|cffe09a15" .. tostring(self.state.title or "Quantidade") .. "|r")
    end
    if m.nameText then
        m.nameText:SetText("|cffffffff" .. tostring(self.state.itemName or "Item") .. "|r")
    end
    if m.qtyText then
        m.qtyText:SetText("|cffe09a15x" .. qty .. "|r  |cff888888/ " .. mx .. "|r")
    end
    if m.qtyEditBox then
        local ok, cur = pcall(function() return m.qtyEditBox:GetText() end)
        if ok and tostring(cur or "") ~= tostring(qty) then
            pcall(function() m.qtyEditBox:SetText(tostring(qty)) end)
        end
    end
end

local function BuildHints(parent, frameName, hints)
    local container = CreateFrame("Frame", frameName, parent)
    container:SetHeight(34)
    container:SetPoint("CENTER", parent, "BOTTOM", 0, 52)

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

function QP:CreateUI()
    if self.frame then return self.frame end
    local m = CreateFrame("Frame", "ConsoleMode_QuantityPicker", UIParent)
    m:SetWidth(420)
    m:SetHeight(260)
    m:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    m:SetFrameStrata("FULLSCREEN_DIALOG")
    m:SetFrameLevel(50)
    m:EnableMouse(true)
    m:SetMovable(false)
    m:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    m:SetBackdropColor(0.08, 0.06, 0.04, 0.85)
    m:SetBackdropBorderColor(1.00, 0.82, 0.20, 0.95)
    m:Hide()

    local title = m:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", m, "TOP", 0, -14)
    ApplyFont(title, FONTS.titleBold, 19)
    title:SetText("|cffe09a15Quantidade|r")
    m.title = title

    local name = m:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("TOP", title, "BOTTOM", 0, -6)
    name:SetWidth(380)
    name:SetJustifyH("CENTER")
    ApplyFont(name, FONTS.titleBold, 16)
    name:SetText("|cffffffffItem|r")
    m.nameText = name

    local qty = m:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    qty:SetPoint("CENTER", m, "CENTER", 0, 18)
    ApplyFont(qty, FONTS.titleBold, 30)
    qty:SetText("|cffe09a15x1|r")
    m.qtyText = qty

    local eb = CreateFrame("EditBox", "ConsoleMode_QuantityPickerEB", m)
    eb:SetWidth(110)
    eb:SetHeight(28)
    eb:SetPoint("CENTER", m, "CENTER", 0, -22)
    eb:SetFont(FONTS.medium, 16)
    eb:SetTextColor(1.0, 1.0, 1.0, 1.0)
    eb:SetAutoFocus(false)
    eb:EnableMouse(true)
    eb:SetMaxLetters(5)
    eb:SetJustifyH("CENTER")
    pcall(function() eb:SetNumeric(true) end)
    eb:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    eb:SetBackdropColor(0.0, 0.0, 0.0, 0.55)
    eb:SetBackdropBorderColor(0.30, 0.25, 0.18, 0.60)
    eb:SetScript("OnEnterPressed", function()
        local qp = ConsoleMode_QuantityPicker
        if qp then qp:Confirm() end
    end)
    eb:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    eb:SetScript("OnEditFocusLost", function()
        local qp = ConsoleMode_QuantityPicker
        if qp then qp:SyncFromEditBox() end
    end)
    m.qtyEditBox = eb

    m.hints = BuildHints(m, "ConsoleMode_QuantityPickerHints", {
        { icons = { "DDOWN", "DUP" }, label = "ajustar" },
        { icons = { "A" },            label = "confirmar" },
        { icons = { "B" },            label = "cancelar" },
    })

    local function styleBtn(btn)
        btn:SetWidth(150)
        btn:SetHeight(28)
        btn:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        btn:SetBackdropColor(0.12, 0.09, 0.06, 0.75)
        btn:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end

    local confirmBtn = CreateFrame("Button", "ConsoleMode_QuantityPickerYes", m)
    styleBtn(confirmBtn)
    confirmBtn:SetPoint("BOTTOMLEFT", m, "BOTTOM", -160, 10)
    local confirmTxt = confirmBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    confirmTxt:SetPoint("CENTER", confirmBtn, "CENTER", 0, 0)
    ApplyFont(confirmTxt, FONTS.titleBold, 15)
    confirmTxt:SetText("Confirmar")
    confirmBtn:SetScript("OnClick", function()
        local qp = ConsoleMode_QuantityPicker
        if qp then qp:Confirm() end
    end)
    confirmBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
    end)
    confirmBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)
    m.confirmBtn = confirmBtn

    local cancelBtn = CreateFrame("Button", "ConsoleMode_QuantityPickerNo", m)
    styleBtn(cancelBtn)
    cancelBtn:SetPoint("BOTTOMRIGHT", m, "BOTTOM", 160, 10)
    local cancelTxt = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cancelTxt:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
    ApplyFont(cancelTxt, FONTS.titleBold, 15)
    cancelTxt:SetText("Cancelar")
    cancelBtn:SetScript("OnClick", function()
        local qp = ConsoleMode_QuantityPicker
        if qp then qp:Cancel() end
    end)
    cancelBtn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
    end)
    cancelBtn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85)
    end)
    m.cancelBtn = cancelBtn

    m:SetScript("OnHide", function()
        local qp = ConsoleMode_QuantityPicker
        if qp then qp.state.isOpen = false end
    end)
    table.insert(UISpecialFrames, "ConsoleMode_QuantityPicker")

    self.frame = m
    return m
end
