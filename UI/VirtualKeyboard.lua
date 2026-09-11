-- ============================================================================
-- ConsoleModeVanilla - UI/VirtualKeyboard.lua
-- Teclado Virtual desacoplado (servico sob demanda, sem eventos)
-- Compativel com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE VK-1: esqueleto + API + registro (sem grade, sem Keybindings,
-- sem Cursor, sem Hooks). Servico modal generico via Open/Close/IsOpen.
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_VirtualKeyboard = ConsoleMode_VirtualKeyboard or {}
local VK = ConsoleMode_VirtualKeyboard
CM.VirtualKeyboard = VK
CM.virtualKeyboard = VK

-- ----------------------------------------------------------------------------
-- 1. ESTADO DO MODULO (VK-1)
-- ----------------------------------------------------------------------------
VK.isOpen = false
VK.title = ""
VK.buffer = ""
VK.maxLetters = nil
VK.multiLine = false
VK.autoCompleteList = nil
VK.onConfirm = nil
VK.onCancel = nil
VK.targetEditBox = nil

VK.frame = VK.frame or nil
VK.titleText = VK.titleText or nil
VK.previewText = VK.previewText or nil

-- ----------------------------------------------------------------------------
-- 2. LOG PCALL-SAFE
-- ----------------------------------------------------------------------------
local function VK_Log(msg)
    if CM.logger and CM.logger.Log then
        pcall(function() CM.logger:Log(msg) end)
    end
end

-- ----------------------------------------------------------------------------
-- 3. CREATEUI STUB (frame vazio + title + preview + hint)
-- ----------------------------------------------------------------------------
function VK:CreateUI()
    if self.frame then
        return self.frame
    end

    local f = CreateFrame("Frame", "ConsoleMode_VirtualKeyboard", UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(50)
    f:SetWidth(420)
    f:SetHeight(260)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:EnableMouse(true)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(1, 0.82, 0.2, 0.95)
    f:Hide()

    local title = f:CreateFontString(nil, "ARTWORK")
    title:SetFont("Fonts\\FRIZQT__.TTF", 19)
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetTextColor(1, 0.82, 0.2)
    title:SetText("")
    self.titleText = title

    local preview = f:CreateFontString(nil, "ARTWORK")
    preview:SetFont("Fonts\\FRIZQT__.TTF", 16)
    preview:SetPoint("TOP", title, "BOTTOM", 0, -16)
    preview:SetTextColor(1, 1, 1)
    preview:SetText("")
    self.previewText = preview

    local hint = f:CreateFontString(nil, "ARTWORK")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 12)
    hint:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
    hint:SetTextColor(0.66, 0.66, 0.66)
    hint:SetText("VK-1 esqueleto")

    self.frame = f
    return f
end

-- ----------------------------------------------------------------------------
-- 4. UPDATEPREVIEW
-- ----------------------------------------------------------------------------
function VK:UpdatePreview()
    if self.previewText then
        local buf = self.buffer
        if buf == nil then
            buf = ""
        end
        pcall(function() self.previewText:SetText(buf .. "|") end)
    end
end

-- ----------------------------------------------------------------------------
-- 5. OPEN (valida onConfirm + guarda estado + clampa + Show + log)
-- ----------------------------------------------------------------------------
function VK:Open(config)
    if type(config) ~= "table" then
        VK_Log("[VirtualKeyboard] Open recusado: config invalido.")
        return nil
    end
    if type(config.onConfirm) ~= "function" then
        VK_Log("[VirtualKeyboard] Open recusado: onConfirm obrigatorio (function).")
        return nil
    end

    self:CreateUI()

    local initialText = config.initialText
    if initialText == nil then
        initialText = ""
    end
    initialText = tostring(initialText)

    local maxLetters = config.maxLetters
    if type(maxLetters) ~= "number" or maxLetters <= 0 then
        maxLetters = nil
    end

    if maxLetters and strlen(initialText) > maxLetters then
        initialText = strsub(initialText, 1, maxLetters)
    end

    self.title = tostring(config.title or "")
    self.buffer = initialText
    self.maxLetters = maxLetters
    if config.multiLine then
        self.multiLine = true
    else
        self.multiLine = false
    end
    self.autoCompleteList = config.autoCompleteList
    self.onConfirm = config.onConfirm
    self.onCancel = config.onCancel
    self.targetEditBox = config.targetEditBox
    self.isOpen = true

    if self.titleText then
        pcall(function() self.titleText:SetText(self.title) end)
    end
    self:UpdatePreview()

    if self.frame then
        self.frame:Show()
    end

    VK_Log("[VirtualKeyboard] Aberto: " .. self.title)
    return true
end

-- ----------------------------------------------------------------------------
-- 6. CLOSE (Hide + isOpen=false + onCancel pcall)
-- ----------------------------------------------------------------------------
function VK:Close()
    if self.frame then
        pcall(function() self.frame:Hide() end)
    end
    self.isOpen = false

    local cb = self.onCancel
    self.onCancel = nil
    self.onConfirm = nil

    if type(cb) == "function" then
        pcall(cb)
    end

    VK_Log("[VirtualKeyboard] Fechado.")
end

-- ----------------------------------------------------------------------------
-- 7. ISOPEN (flag OR IsVisible)
-- ----------------------------------------------------------------------------
function VK:IsOpen()
    if self.isOpen then
        return true
    end
    if self.frame then
        local ok, vis = pcall(function() return self.frame:IsVisible() end)
        if ok and vis then
            return true
        end
    end
    return false
end
