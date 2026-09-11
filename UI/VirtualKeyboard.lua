-- ============================================================================
-- ConsoleModeVanilla - UI/VirtualKeyboard.lua
-- Teclado Virtual desacoplado (servico sob demanda, sem eventos)
-- Compativel com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE VK-3: paginas abc/ABC/123/PT + X=shift + Y=espaco/nova-linha +
-- L1/R1 troca pagina + maxLetters + Backspace UTF-8 seguro.
-- Navegacao D-Pad estilo MerchantMenu (sem cursor snap).
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_VirtualKeyboard = ConsoleMode_VirtualKeyboard or {}
local VK = ConsoleMode_VirtualKeyboard
CM.VirtualKeyboard = VK
CM.virtualKeyboard = VK

-- ----------------------------------------------------------------------------
-- 1. ESTADO DO MODULO (VK-1 + VK-2)
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
VK.gridArea = VK.gridArea or nil
VK.hintText = VK.hintText or nil

-- Foco VK-2: indice 1-based na matriz keyCells[linha][coluna] (botoes reais)
VK.keyCells = VK.keyCells or {}
VK.selRow = VK.selRow or 1
VK.selCol = VK.selCol or 1

-- Pagina atual VK-3: 1=abc, 2=ABC, 3=123, 4=PT
VK.pageIdx = VK.pageIdx or 1
VK.pageText = VK.pageText or nil
VK.gridButtons = VK.gridButtons or {}

-- ----------------------------------------------------------------------------
-- 2. CONSTANTES VISUAIS VK-2 (molde QtyModal 420 + grade 40x40 MainMenu)
-- ----------------------------------------------------------------------------
local VK_KEY_W = 30
local VK_KEY_H = 30
local VK_GAP = 4
local VK_GRID_W = 384
local VK_GRID_H = 132

-- Teclas largas de acao compartilhadas entre paginas (somente leitura)
local VK_EXTRA_BACKSPACE = { label = "APAGAR", op = "backspace", w = 52, textSize = 11, r = 1, g = 0.35, b = 0.3 }
local VK_EXTRA_OK = { label = "OK", op = "accept", w = 40, textSize = 12, r = 0.2, g = 1, b = 0.2 }
local VK_EXTRA_SPACE = { label = "ESPACO", op = "space", w = 220, textSize = 11, r = 0.66, g = 0.66, b = 0.66 }

-- Paginas VK-3 (cada fileira: teclas op insert + opcional extra de acao)
local VK_PAGES = {
    { name = "abc", rows = {
        { keys = { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p" } },
        { keys = { "a", "s", "d", "f", "g", "h", "j", "k", "l" }, extra = VK_EXTRA_BACKSPACE },
        { keys = { "z", "x", "c", "v", "b", "n", "m", ",", ".", "@" }, extra = VK_EXTRA_OK },
        { keys = { }, extra = VK_EXTRA_SPACE },
    } },
    { name = "ABC", rows = {
        { keys = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" } },
        { keys = { "A", "S", "D", "F", "G", "H", "J", "K", "L" }, extra = VK_EXTRA_BACKSPACE },
        { keys = { "Z", "X", "C", "V", "B", "N", "M", ",", ".", "@" }, extra = VK_EXTRA_OK },
        { keys = { }, extra = VK_EXTRA_SPACE },
    } },
    { name = "123", rows = {
        { keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" } },
        { keys = { "-", "/", ":", ";", "(", ")", "+", "*", "?" }, extra = VK_EXTRA_BACKSPACE },
        { keys = { "_", "|", "~", "<", ">", "=", "[", "]", "{", "}" }, extra = VK_EXTRA_OK },
        { keys = { }, extra = VK_EXTRA_SPACE },
    } },
    { name = "PT", rows = {
        { keys = { "ã", "õ", "ç", "á", "é", "í", "ó", "ú", "â", "ê" } },
        { keys = { "à", "è", "ì", "ò", "ù", "î", "ô", "û" }, extra = VK_EXTRA_BACKSPACE },
        { keys = { "ä", "ë", "ï", "ö", "ü", "ñ", "ý", "ÿ", "æ", "œ" }, extra = VK_EXTRA_OK },
        { keys = { }, extra = VK_EXTRA_SPACE },
    } },
}

-- ----------------------------------------------------------------------------
-- 3. LOG + SOM + FONTE (pcall-safe)
-- ----------------------------------------------------------------------------
local function VK_Log(msg)
    if CM.logger and CM.logger.Log then
        pcall(function() CM.logger:Log(msg) end)
    end
end

local function VK_Play(sound)
    if PlaySound then
        pcall(function() PlaySound(sound) end)
    end
end

-- Prefere a fonte nobre do MerchantMenu (AlegreyaSans-Bold); cai para
-- FRIZQT__ quando o modulo nao esta ao alcance. Lua 5.0.
local function VK_ApplyFont(fs, size)
    if not fs then
        return
    end
    local mm = ConsoleMode_MerchantMenu
    if mm and mm.ApplyFont then
        local ok = pcall(function() mm:ApplyFont(fs, nil, size) end)
        if ok then
            return
        end
    end
    pcall(function()
        fs:SetFont("Fonts\\FRIZQT__.TTF", size)
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.9)
    end)
end

-- ----------------------------------------------------------------------------
-- 4. CREATEUI (frame FULLSCREEN_DIALOG + titulo + preview + grade + hints)
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
    title:SetPoint("TOP", f, "TOP", 0, -12)
    VK_ApplyFont(title, 19)
    title:SetTextColor(1, 0.82, 0.2)
    title:SetText("")
    self.titleText = title

    local preview = f:CreateFontString(nil, "ARTWORK")
    preview:SetPoint("TOP", title, "BOTTOM", 0, -6)
    preview:SetWidth(380)
    preview:SetJustifyH("LEFT")
    VK_ApplyFont(preview, 16)
    preview:SetTextColor(1, 1, 1)
    preview:SetText("")
    self.previewText = preview

    local grid = CreateFrame("Frame", nil, f)
    grid:SetWidth(VK_GRID_W)
    grid:SetHeight(VK_GRID_H)
    grid:SetPoint("TOP", preview, "BOTTOM", 0, -10)
    self.gridArea = grid

    local page = f:CreateFontString(nil, "ARTWORK")
    page:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -12)
    VK_ApplyFont(page, 12)
    page:SetTextColor(0.66, 0.66, 0.66)
    page:SetText("[abc]")
    self.pageText = page

    self:BuildGrid()

    local hints = f:CreateFontString(nil, "ARTWORK")
    hints:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    hints:SetWidth(390)
    hints:SetJustifyH("CENTER")
    VK_ApplyFont(hints, 12)
    hints:SetText("[A] inserir  [B] apagar  [X] maiusc  [Y] espaço  [L1/R1] pág  [Start] OK")
    self.hintText = hints

    self.frame = f
    return f
end

-- Constroi uma tecla real da grade (molde slots 40x40 MainMenu + QtyModal)
local function VK_CreateKey(parent, label, size, r, g, b)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.10, 0.08, 0.06, 0.50)
    btn:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)

    local hl = btn:CreateTexture(nil, "BACKGROUND")
    hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.30)
    hl:SetAllPoints(btn)
    hl:Hide()
    btn.highlight = hl

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
    VK_ApplyFont(fs, size)
    fs:SetTextColor(r, g, b)
    fs:SetText(label)
    btn.labelText = fs

    return btn
end

function VK:BuildGrid()
    local grid = self.gridArea
    if not grid then
        return
    end
    -- Frames 1.12 nao sao destruidos: esconde os botoes da pagina anterior.
    if self.gridButtons then
        local nb = table.getn(self.gridButtons)
        for i = 1, nb do
            local old = self.gridButtons[i]
            if old then
                pcall(function()
                    old:Hide()
                    old:SetScript("OnEnter", nil)
                    old:SetScript("OnClick", nil)
                end)
            end
        end
    end
    self.gridButtons = {}
    self.keyCells = {}

    local page = VK_PAGES[self.pageIdx or 1] or VK_PAGES[1]
    local VK_PAGE_ROWS = page.rows
    local numRows = table.getn(VK_PAGE_ROWS)
    for ri = 1, numRows do
        local def = VK_PAGE_ROWS[ri]
        local row = {}
        local cells = {}
        local n = table.getn(def.keys)
        for ci = 1, n do
            local ch = def.keys[ci]
            table.insert(cells, { label = ch, op = "insert", char = ch, w = VK_KEY_W, textSize = 15, r = 1, g = 1, b = 1 })
        end
        if def.extra then
            table.insert(cells, { label = def.extra.label, op = def.extra.op, char = nil,
                w = def.extra.w, textSize = def.extra.textSize, r = def.extra.r, g = def.extra.g, b = def.extra.b })
        end

        local rowW = 0
        local numCells = table.getn(cells)
        for ci = 1, numCells do
            rowW = rowW + cells[ci].w
        end
        if numCells > 1 then
            rowW = rowW + ((numCells - 1) * VK_GAP)
        end

        local x = (VK_GRID_W - rowW) / 2
        local y = -((ri - 1) * (VK_KEY_H + VK_GAP))
        for ci = 1, numCells do
            local cd = cells[ci]
            local btn = VK_CreateKey(grid, cd.label, cd.textSize, cd.r, cd.g, cd.b)
            local bw = cd.w
            local bh = VK_KEY_H
            if cd.op == "space" then
                bh = 26
            end
            btn:SetWidth(bw)
            btn:SetHeight(bh)
            btn:SetPoint("TOPLEFT", grid, "TOPLEFT", x, y)
            btn.vkRow = ri
            btn.vkCol = ci
            btn.vkOp = cd.op
            btn.vkChar = cd.char
            btn:SetScript("OnEnter", function()
                VK:FocusCell(this.vkRow, this.vkCol)
            end)
            btn:SetScript("OnClick", function()
                VK:FocusCell(this.vkRow, this.vkCol)
                VK:ActivateFocused()
            end)
            x = x + bw + VK_GAP
            table.insert(row, btn)
            table.insert(self.gridButtons, btn)
        end
        table.insert(self.keyCells, row)
    end

    self.selRow = 1
    self.selCol = 1
    self:FocusCell(1, 1)
    self:UpdatePageText()
end

function VK:UpdatePageText()
    if self.pageText then
        local page = VK_PAGES[self.pageIdx or 1] or VK_PAGES[1]
        pcall(function() self.pageText:SetText("[" .. page.name .. "]") end)
    end
end

-- VK-3: troca de pagina com wrap circular (L1/R1).
function VK:NextPage(delta)
    local n = table.getn(VK_PAGES)
    if n < 1 then
        return
    end
    local idx = (tonumber(self.pageIdx) or 1) + (tonumber(delta) or 1)
    while idx > n do
        idx = idx - n
    end
    while idx < 1 do
        idx = idx + n
    end
    self.pageIdx = idx
    self:BuildGrid()
    self:FocusCell(1, 1)
    VK_Play("igMainMenuOptionCheckBoxOn")
end

-- VK-3: shift alterna abc/ABC; de 123/PT pula para ABC.
function VK:ToggleShift()
    local idx = tonumber(self.pageIdx) or 1
    if idx == 1 then
        self.pageIdx = 2
    elseif idx == 2 then
        self.pageIdx = 1
    else
        self.pageIdx = 2
    end
    self:BuildGrid()
    self:FocusCell(1, 1)
    VK_Play("igMainMenuOptionCheckBoxOn")
end

-- VK-3: Y insere espaco, ou quebra de linha se multiLine.
function VK:InsertSpace()
    if self.multiLine then
        self:InsertChar("\n")
    else
        self:InsertChar(" ")
    end
end

-- ----------------------------------------------------------------------------
-- 5. FOCO + NAVEGACAO (OnDirection 2D com wrap por fileira)
-- ----------------------------------------------------------------------------
function VK:FocusCell(r, c)
    local rows = self.keyCells
    if not rows then
        return
    end
    local n = table.getn(rows)
    if n < 1 then
        return
    end
    r = tonumber(r) or 1
    c = tonumber(c) or 1
    if r < 1 then r = 1 end
    if r > n then r = n end
    local rowLen = table.getn(rows[r])
    if rowLen < 1 then
        return
    end
    if c < 1 then c = 1 end
    if c > rowLen then c = rowLen end

    self.selRow = r
    self.selCol = c
    for ri = 1, n do
        local row = rows[ri]
        local m = table.getn(row)
        for ci = 1, m do
            local btn = row[ci]
            if btn then
                if ri == r and ci == c then
                    pcall(function()
                        btn:SetBackdropBorderColor(1, 0.82, 0.2, 0.95)
                        if btn.highlight then btn.highlight:Show() end
                    end)
                else
                    pcall(function()
                        btn:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
                        if btn.highlight then btn.highlight:Hide() end
                    end)
                end
            end
        end
    end
end

function VK:OnDirection(dir)
    local d = string.upper(dir or "")
    if d ~= "UP" and d ~= "DOWN" and d ~= "LEFT" and d ~= "RIGHT" then
        return
    end
    local rows = self.keyCells
    if not rows then
        return
    end
    local n = table.getn(rows)
    if n < 1 then
        return
    end
    local r = tonumber(self.selRow) or 1
    local c = tonumber(self.selCol) or 1
    if r < 1 then r = 1 end
    if r > n then r = n end
    local rowLen = table.getn(rows[r])
    if rowLen < 1 then
        return
    end
    if c < 1 then c = 1 end
    if c > rowLen then c = rowLen end

    if d == "LEFT" then
        c = c - 1
        if c < 1 then c = rowLen end
    elseif d == "RIGHT" then
        c = c + 1
        if c > rowLen then c = 1 end
    elseif d == "UP" then
        r = r - 1
        if r < 1 then r = n end
        local nl = table.getn(rows[r])
        if c > nl then c = nl end
    else
        r = r + 1
        if r > n then r = 1 end
        local nl2 = table.getn(rows[r])
        if c > nl2 then c = nl2 end
    end

    self:FocusCell(r, c)
    VK_Play("igMainMenuOptionCheckBoxOn")
end

-- ----------------------------------------------------------------------------
-- 6. EDICAO (InsertChar com maxLetters + Backspace byte-safe simples)
-- ----------------------------------------------------------------------------
function VK:UpdatePreview()
    if self.previewText then
        local buf = self.buffer
        if buf == nil then
            buf = ""
        end
        pcall(function() self.previewText:SetText(buf .. "|") end)
    end
    if self.targetEditBox and self.targetEditBox.SetText then
        local snap = self.buffer or ""
        pcall(function() self.targetEditBox:SetText(snap) end)
    end
end

function VK:InsertChar(ch)
    ch = tostring(ch or "")
    if ch == "" then
        return
    end
    local buf = self.buffer or ""
    if self.maxLetters and (strlen(buf) + strlen(ch) > self.maxLetters) then
        VK_Play("igQuestFailed")
        return
    end
    self.buffer = buf .. ch
    self:UpdatePreview()
    VK_Play("igMainMenuOptionCheckBoxOn")
end

function VK:Backspace()
    local buf = self.buffer or ""
    local len = strlen(buf)
    if len <= 0 then
        return
    end
    -- UTF-8 seguro: remove a sequencia completa do ultimo caractere
    -- (bytes de continuacao 0x80-0xBF grudados no byte lider).
    local cut = len
    while cut > 1 do
        local b = string.byte(buf, cut)
        if b and b >= 128 and b < 192 then
            cut = cut - 1
        else
            break
        end
    end
    self.buffer = strsub(buf, 1, cut - 1)
    self:UpdatePreview()
    VK_Play("igMainMenuOptionCheckBoxOn")
end

-- Ativa a tecla em foco: letra/ponto insere, APAGAR apaga, OK confirma
function VK:ActivateFocused()
    local rows = self.keyCells
    if not rows then
        return
    end
    local r = tonumber(self.selRow) or 1
    local c = tonumber(self.selCol) or 1
    if r < 1 or r > table.getn(rows) then
        return
    end
    local row = rows[r]
    if c < 1 or c > table.getn(row) then
        return
    end
    local btn = row[c]
    if not btn then
        return
    end
    local op = btn.vkOp
    if op == "accept" then
        self:Accept()
    elseif op == "backspace" then
        self:Backspace()
    elseif op == "space" then
        self:InsertSpace()
    elseif btn.vkChar then
        self:InsertChar(btn.vkChar)
    end
end

-- A no controle: ativa a tecla em foco (OK em foco = confirma de verdade)
function VK:Confirm()
    self:ActivateFocused()
end

-- Start / tecla OK: fecha e entrega o buffer via onConfirm (pcall)
function VK:Accept()
    if not self:IsOpen() then
        return
    end
    local text = self.buffer or ""
    local cb = self.onConfirm
    self.onCancel = nil
    self.onConfirm = nil
    if self.frame then
        pcall(function() self.frame:Hide() end)
    end
    self.isOpen = false
    self:RestoreDpad()
    VK_Play("igMainMenuOptionCheckBoxOn")
    VK_Log("[VirtualKeyboard] Confirmado: " .. text)
    if type(cb) == "function" then
        pcall(function() cb(text) end)
    end
end

-- B no controle: com texto apaga 1 char (passo unico); vazio cancela
function VK:OnCancel()
    local buf = self.buffer or ""
    if strlen(buf) > 0 then
        self:Backspace()
        return
    end
    self:Close()
end

-- ----------------------------------------------------------------------------
-- 7. OPEN (valida onConfirm + guarda estado + clampa + Show + foco inicial)
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

    -- Sempre abre na pagina abc (previsivel para o auditor).
    self.pageIdx = 1
    self:BuildGrid()

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
    self:FocusCell(1, 1)
    self:SequesterDpad()
    VK_Play("igMainMenuOpen")

    VK_Log("[VirtualKeyboard] Aberto: " .. self.title)
    return true
end

-- Estilo MerchantMenu: sequestra o D-Pad para a grade interna sem usar o
-- cursor de navegacao (sem MoveTo, sem tocar no global `this`). O
-- CM_CursorMove ja desvia para VK:OnDirection quando IsOpen(); aqui so
-- garantimos que o modo navegacao esteja ativo. FocusCell cuida do
-- destaque visual da tecla (borda ouro + highlight).
function VK:SequesterDpad()
    local kb = ConsoleMode and ConsoleMode.keybindings
    if not kb then
        return
    end
    if not kb.navigationMode then
        if kb.EnterNavigationMode then
            pcall(function() kb:EnterNavigationMode() end)
        end
    else
        if kb.ReapplyNavigationBindings then
            pcall(function() kb:ReapplyNavigationBindings() end)
        end
    end
end

-- Devolve o D-Pad ao normal: ExitNavigationMode sem force recusa sair
-- sozinho se Mail/Merchant/MainMenu seguem abertos; senao restaura os
-- binds do jogo. Sem tocar no cursor.
function VK:RestoreDpad()
    if ConsoleMode and ConsoleMode.keybindings and ConsoleMode.keybindings.ExitNavigationMode then
        pcall(function() ConsoleMode.keybindings:ExitNavigationMode() end)
    end
end

-- ----------------------------------------------------------------------------
-- 8. CLOSE (Hide + isOpen=false + onCancel pcall)
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

    self:RestoreDpad()
    VK_Play("igMainMenuClose")
    VK_Log("[VirtualKeyboard] Fechado.")
end

-- ----------------------------------------------------------------------------
-- 9. ISOPEN (flag OR IsVisible)
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
