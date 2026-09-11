-- ============================================================================
-- ConsoleModeVanilla - UI/VirtualKeyboard.lua
-- Teclado Virtual desacoplado (servico sob demanda, sem eventos)
-- Compativel com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE VK-3: paginas abc/ABC/123/PT + X=apagar + Y=shift +
-- A=inserir + B=fechar + L1/R1 troca pagina + Start=OK +
-- maxLetters + Backspace UTF-8 seguro.
-- FASE VK-4: suggestRow generica (ate 4, prefixo case-insensitive via
-- strlower, UP da 1a fileira sobe, A preenche sem fechar, DOWN volta).
-- VK nunca le nem escreve SavedVariables: so consome a lista do Open.
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
VK.hintContainer = VK.hintContainer or nil

-- Foco VK-2: indice 1-based na matriz keyCells[linha][coluna] (botoes reais)
VK.keyCells = VK.keyCells or {}
VK.selRow = VK.selRow or 1
VK.selCol = VK.selCol or 1

-- Pagina atual VK-3: 1=abc, 2=ABC, 3=123, 4=PT
VK.pageIdx = VK.pageIdx or 1
VK.pageText = VK.pageText or nil
VK.gridButtons = VK.gridButtons or {}

-- Autocomplete generico VK-4: fileira de ate VK_SUGGEST_MAX botoes entre o
-- preview e a grade. focusZone vale "grid" ou "suggest". suggestList guarda
-- os matches filtrados (vazia = fileira escondida). suggestIdx e o foco
-- dentro da fileira (1-based). returnCol guarda a coluna da grade para o
-- DOWN das sugestoes voltar ao ponto de origem. Invariante: suggestList
-- nao vazia equivale a fileira visivel (HideSuggestions limpa a lista).
VK.suggestRow = VK.suggestRow or nil
VK.suggestButtons = VK.suggestButtons or {}
VK.suggestList = VK.suggestList or {}
VK.suggestIdx = VK.suggestIdx or 1
VK.focusZone = VK.focusZone or "grid"
VK.returnCol = VK.returnCol or 1

-- Hold-to-repeat (molde MerchantMenu.repeatState + Cursor.repeatState):
-- kind "DIR" repete OnDirection na direcao segurada (D-Pad);
-- kind "BACKSPACE" repete Backspace (X). Passo imediato + delay 0.35s +
-- intervalo 0.12s via EnsureRepeatTicker (OnUpdate, sem dependencias).
VK.repeatState = VK.repeatState or {
    kind = nil,
    direction = nil,
    timer = 0,
    initialDelay = 0.35,
    interval = 0.12,
}
VK.repeatFrame = VK.repeatFrame or nil

-- Borda de subida do R2 (Steam = modificador ALT): false = solto.
-- Semeada no Open com o estado real do modificador (pre-segurar o R2
-- nao confirma na abertura) e atualizada a cada OnUpdate mesmo com o
-- VK fechado (sem disparar fora do VK).
VK.altWasDown = VK.altWasDown or false

-- ----------------------------------------------------------------------------
-- 2. CONSTANTES VISUAIS VK-2 (molde QtyModal 420 + grade 40x40 MainMenu)
-- ----------------------------------------------------------------------------
local VK_KEY_W = 30
local VK_KEY_H = 30
local VK_GAP = 4
local VK_GRID_W = 384
local VK_GRID_H = 132

-- Fileira de sugestoes VK-4: ate 4 botoes lado a lado na largura da grade
-- (4 vezes 93 mais 3 gaps de 4 = 384). Altura 30 igual as teclas (mesma
-- identidade: VK_CreateKey, ApplyFont, destaque ouro). Fonte 12 para caber
-- nome de personagem. Custo vertical: fileira 30 mais gaps 6 e 6 = 42 no
-- lugar do gap antigo de 10, por isso o frame cresce de 260 para 292 sem
-- apertar grade, preview nem hints.
local VK_SUGGEST_MAX = 4
local VK_SUGGEST_W = 93
local VK_SUGGEST_H = 30
local VK_SUGGEST_FONT = 12
local VK_FRAME_H = 292

-- Teclas largas de acao compartilhadas entre paginas (somente leitura).
-- APAGAR exibe glifo X a esquerda + texto "APAGAR" (o glifo e o botao X
-- que aciona a tecla). Largura dinamica em BuildGrid: w = 3 + 14 + 4 +
-- texto + 6 (texto medido via GetStringWidth apos SetText + fonte
-- aplicada), minimo `w` declarado. OK/ESPACO usam a mesma medicao com
-- minimo `w` (na pratica seguem nos valores fixos). Orcamento da grade:
-- 384px; se o APAGAR estourar a fileira 2, as letras dessa fileira
-- encolhem o minimo necessario (sem tocar as outras fileiras).
local VK_EXTRA_BACKSPACE = { label = "APAGAR", op = "backspace", w = 52, textSize = 11, r = 1, g = 0.35, b = 0.3, icon = "X" }
local VK_EXTRA_OK = { label = "OK", op = "accept", w = 40, textSize = 12, r = 0.2, g = 1, b = 0.2 }
local VK_EXTRA_SPACE = { label = "ESPACO", op = "space", w = 220, textSize = 11, r = 0.66, g = 0.66, b = 0.66 }

-- Geometria do APAGAR dinamico (espelha VK_CreateKey: glifo 14px a 3px da
-- borda esquerda, gap 4px ate o texto, pad direito 6px) + valvula de
-- escape (fonte 10) + piso das letras na compensacao de fileira.
local VK_BS_MARGIN_L = 3
local VK_BS_GLYPH_W = 14
local VK_BS_TEXT_GAP = 4
local VK_BS_PAD_R = 6
local VK_BS_FONT_FALLBACK = 10
local VK_EXTRA_PAD_X = 12
local VK_KEY_W_MIN = 26

-- Glifos de gamepad disponiveis no addon (inventario real em
-- Media/Icons/Xbox/: A, B, X, Y, LB, RB, LT, RT, DUP, DDOWN, DLEFT,
-- DRIGHT, navigate_all_directions). INEXISTENTES: Start, Select e
-- icones de funcao (seta-apagar, check, espaco).
local VK_ICON_BASE = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\"
local VK_ICONS = {
    A  = VK_ICON_BASE .. "A.tga",
    B  = VK_ICON_BASE .. "B.tga",
    X  = VK_ICON_BASE .. "X.tga",
    Y  = VK_ICON_BASE .. "Y.tga",
    LB = VK_ICON_BASE .. "LB.tga",
    RB = VK_ICON_BASE .. "RB.tga",
}

-- Linha de hints: glifo + verbo em texto. L1=LB e R1=RB (nomenclatura
-- fisica L1/R1 x textura LB/RB). Start mantido em texto (sem .tga).
-- Layout compacto: frame 420px, area util ~390px, teto de 380px para a
-- linha completa (centralizada via container). Valores reduzidos apos
-- overflow no Steam Deck (glifos face 16->14, LB/RB 22->19, fonte 12->11,
-- gaps 10->4, pads 4/5/12->2/2/medido). Trava: gap encolhe ate 2 p/ caber.
local VK_HINT_MAX_W = 380
local VK_HINT_FONT = 11
local VK_HINT_ICON = 14
local VK_HINT_ICON_WIDE = 19
local VK_HINT_ICON_PAD = 1
local VK_HINT_TEXT_PAD = 2
local VK_HINT_SEP_PAD = 2
local VK_HINT_GAP = 4
local VK_HINT_GAP_MIN = 2
local VK_HINTS = {
    { icons = { "A" },        label = "inserir" },
    { icons = { "B" },        label = "fechar" },
    { icons = { "X" },        label = "apagar" },
    { icons = { "Y" },        label = "maiusc" },
    { icons = { "LB", "RB" }, label = "pág" },
    { icons = { },            label = "Start OK" },
}

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

-- Medicao real de texto para os extras largos (Lua 5.0 / 1.12).
-- Aplica a fonte no tamanho pedido, faz SetText e le GetStringWidth.
-- Usa um FontString oculto reutilizado (sem tocar em paginas, foco,
-- hints, autocomplete, hold-repeat, mapa de botoes ou opacidade).
local VK_measureFS = nil
local function VK_MeasureTextWidth(label, size)
    if label == nil or label == "" then
        return 0
    end
    if not UIParent then
        return 0
    end
    if not VK_measureFS then
        VK_measureFS = UIParent:CreateFontString(nil, "OVERLAY")
    end
    local fs = VK_measureFS
    if not fs then
        return 0
    end
    VK_ApplyFont(fs, size)
    pcall(function() fs:SetText(label) end)
    local tw = 0
    local ok, val = pcall(function() return fs:GetStringWidth() end)
    if ok and type(val) == "number" then
        tw = val
    end
    return tw
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
    f:SetHeight(VK_FRAME_H)
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

    -- VK-4: fileira de sugestoes entre o preview e a grade (ancora
    -- estavel: a grade ancora na fileira, entao esconder a fileira nao
    -- move nada e nada se sobrepoe; o espaco extra vem do frame maior).
    local suggest = CreateFrame("Frame", nil, f)
    suggest:SetWidth(VK_GRID_W)
    suggest:SetHeight(VK_SUGGEST_H)
    suggest:SetPoint("TOP", preview, "BOTTOM", 0, -6)
    suggest:Hide()
    self.suggestRow = suggest

    local grid = CreateFrame("Frame", nil, f)
    grid:SetWidth(VK_GRID_W)
    grid:SetHeight(VK_GRID_H)
    grid:SetPoint("TOP", suggest, "BOTTOM", 0, -6)
    self.gridArea = grid

    local page = f:CreateFontString(nil, "ARTWORK")
    page:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -12)
    VK_ApplyFont(page, 12)
    page:SetTextColor(0.66, 0.66, 0.66)
    page:SetText("[abc]")
    self.pageText = page

    self:BuildGrid()

    -- VK-4: botoes da fileira de sugestoes (comecam escondidos).
    self:BuildSuggestRow()

    -- Rodape de hints com glifos reais (molde MerchantMenu:CreateFooterHints
    -- e MainMenu:CreateFooterHints): Texture via SetTexture + verbo em
    -- FontString. Sem escapes |T| inline (sem precedente no repo / 1.12).
    self:BuildHints(f)

    self.frame = f
    return f
end

-- Linha de hints com icones do gamepad + verbos em texto (A=inserir,
-- B=fechar, X=apagar, Y=maiusc, LB+RB=pag, Start=OK em texto).
-- Titulo, preview e indicador de pagina nao sao tocados aqui.
function VK:BuildHints(f)
    local container = CreateFrame("Frame", nil, f)
    container:SetHeight(18)
    container:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    self.hintContainer = container

    local totalWidth = 0
    local contentW = 0
    local widgets = {}

    local numHints = table.getn(VK_HINTS)
    for i = 1, numHints do
        local hint = VK_HINTS[i]
        local group = CreateFrame("Frame", nil, container)
        group:SetHeight(18)

        local currentX = 0
        local numIcons = table.getn(hint.icons)
        for k = 1, numIcons do
            local texPath = VK_ICONS[hint.icons[k]]
            if texPath then
                local iconTex = group:CreateTexture(nil, "OVERLAY")
                local iw = VK_HINT_ICON
                if hint.icons[k] == "LB" or hint.icons[k] == "RB" then
                    iw = VK_HINT_ICON_WIDE
                end
                iconTex:SetWidth(iw)
                iconTex:SetHeight(VK_HINT_ICON)
                iconTex:SetTexture(texPath)
                iconTex:SetPoint("LEFT", group, "LEFT", currentX, 0)
                currentX = currentX + iw + VK_HINT_ICON_PAD
            end
        end

        currentX = currentX + VK_HINT_TEXT_PAD

        local label = group:CreateFontString(nil, "OVERLAY")
        label:SetPoint("LEFT", group, "LEFT", currentX, 0)
        VK_ApplyFont(label, VK_HINT_FONT)
        label:SetTextColor(0.85, 0.85, 0.85, 0.95)
        label:SetText(hint.label)
        local textW = math.floor(label:GetStringWidth() or 40)
        currentX = currentX + textW

        if i < numHints then
            local sep = group:CreateFontString(nil, "OVERLAY")
            sep:SetPoint("LEFT", group, "LEFT", currentX + VK_HINT_SEP_PAD, 0)
            VK_ApplyFont(sep, VK_HINT_FONT)
            sep:SetText("|cff666666•|r")
            local sepW = math.floor(sep:GetStringWidth() or 5)
            currentX = currentX + VK_HINT_SEP_PAD + sepW
        end

        group:SetWidth(currentX)
        table.insert(widgets, group)
        contentW = contentW + currentX
    end

    -- Trava de seguranca: encolhe o gap entre grupos para caber em
    -- VK_HINT_MAX_W; nunca deixa o container estourar (centralizado).
    local gap = VK_HINT_GAP
    local numGaps = numHints - 1
    if numGaps > 0 and (contentW + gap * numGaps) > VK_HINT_MAX_W then
        gap = math.floor((VK_HINT_MAX_W - contentW) / numGaps)
        if gap < VK_HINT_GAP_MIN then
            gap = VK_HINT_GAP_MIN
        end
    end
    if numGaps > 0 then
        totalWidth = contentW + gap * numGaps
    else
        totalWidth = contentW
    end
    if totalWidth > VK_HINT_MAX_W then
        totalWidth = VK_HINT_MAX_W
    end

    container:SetWidth(totalWidth)
    local curOffset = 0
    local numWidgets = table.getn(widgets)
    for w = 1, numWidgets do
        local widget = widgets[w]
        widget:SetPoint("LEFT", container, "LEFT", curOffset, 0)
        curOffset = curOffset + widget:GetWidth() + gap
    end
end

-- Constroi uma tecla real da grade (molde slots 40x40 MainMenu + QtyModal).
-- iconPath opcional: glifo do gamepad que aciona a tecla de acao.
-- APAGAR (icone X + texto) usa glifo a esquerda e rotulo deslocado;
-- o ramo icone-sem-texto (glifo centralizado) fica para botoes futuros.
-- Largura do botao vem de BuildGrid (dinamica para os extras).
local function VK_CreateKey(parent, label, size, r, g, b, iconPath)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.10, 0.08, 0.06, 0.80)
    btn:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)

    local hl = btn:CreateTexture(nil, "BACKGROUND")
    hl:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.30)
    hl:SetAllPoints(btn)
    hl:Hide()
    btn.highlight = hl

    local fs = btn:CreateFontString(nil, "OVERLAY")
    local glyph = nil
    if iconPath then
        glyph = btn:CreateTexture(nil, "OVERLAY")
        glyph:SetWidth(14)
        glyph:SetHeight(14)
        glyph:SetTexture(iconPath)
        if label == nil or label == "" then
            glyph:SetPoint("CENTER", btn, "CENTER", 0, 0)
            fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        else
            glyph:SetPoint("LEFT", btn, "LEFT", 3, 0)
            fs:SetPoint("CENTER", btn, "CENTER", 8, 0)
        end
    else
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
    end
    VK_ApplyFont(fs, size)
    fs:SetTextColor(r, g, b)
    fs:SetText(label)
    btn.labelText = fs
    btn.glyph = glyph

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
            table.insert(cells, { label = def.extra.label, op = def.extra.op, char = nil, icon = def.extra.icon,
                w = def.extra.w, textSize = def.extra.textSize, r = def.extra.r, g = def.extra.g, b = def.extra.b })
        end

        -- Largura dinamica dos extras: mede o texto real (SetText + fonte
        -- aplicada via VK_MeasureTextWidth) e soma o cromo do botao.
        -- APAGAR (com icone): 3 + 14 + 4 + texto + 6, minimo `w`.
        -- OK/ESPACO (sem icone): texto + 12, minimo `w` (seguem fixos).
        local numCellsPre = table.getn(cells)
        for ci = 1, numCellsPre do
            local cdpre = cells[ci]
            if cdpre.op == "backspace" or cdpre.op == "accept" or cdpre.op == "space" then
                local twpre = math.floor(VK_MeasureTextWidth(cdpre.label, cdpre.textSize) or 0)
                if cdpre.op == "backspace" and cdpre.icon then
                    local dynw = VK_BS_MARGIN_L + VK_BS_GLYPH_W + VK_BS_TEXT_GAP + twpre + VK_BS_PAD_R
                    if dynw < cdpre.w then
                        dynw = cdpre.w
                    end
                    cdpre.w = dynw
                else
                    local dynw2 = twpre + VK_EXTRA_PAD_X
                    if dynw2 < cdpre.w then
                        dynw2 = cdpre.w
                    end
                    cdpre.w = dynw2
                end
            end
        end

        local rowW = 0
        local numCells = table.getn(cells)
        for ci = 1, numCells do
            rowW = rowW + cells[ci].w
        end
        if numCells > 1 then
            rowW = rowW + ((numCells - 1) * VK_GAP)
        end

        -- Orcamento 384px: se a fileira com APAGAR estourar, encolhe SO as
        -- letras dessa fileira (uniforme, piso VK_KEY_W_MIN, so o
        -- necessario; outras fileiras e alinhamento intactos). Valvula de
        -- escape: remede o APAGAR em 10px e repete o ajuste.
        if rowW > VK_GRID_W then
            local hasBS = false
            local nLetters = 0
            for ci = 1, numCells do
                if cells[ci].op == "backspace" then
                    hasBS = true
                end
                if cells[ci].op == "insert" then
                    nLetters = nLetters + 1
                end
            end
            if hasBS and nLetters > 0 then
                local over = rowW - VK_GRID_W
                local per = math.floor((over + nLetters - 1) / nLetters)
                local newW = VK_KEY_W - per
                if newW < VK_KEY_W_MIN then
                    newW = VK_KEY_W_MIN
                end
                if newW < VK_KEY_W then
                    for ci = 1, numCells do
                        if cells[ci].op == "insert" then
                            cells[ci].w = newW
                        end
                    end
                    rowW = 0
                    for ci = 1, numCells do
                        rowW = rowW + cells[ci].w
                    end
                    if numCells > 1 then
                        rowW = rowW + ((numCells - 1) * VK_GAP)
                    end
                end
                if rowW > VK_GRID_W then
                    for ci = 1, numCells do
                        if cells[ci].op == "backspace" then
                            cells[ci].textSize = VK_BS_FONT_FALLBACK
                            local twfb = math.floor(VK_MeasureTextWidth(cells[ci].label, VK_BS_FONT_FALLBACK) or 0)
                            local dynfb = VK_BS_MARGIN_L + VK_BS_GLYPH_W + VK_BS_TEXT_GAP + twfb + VK_BS_PAD_R
                            if dynfb < VK_EXTRA_BACKSPACE.w then
                                dynfb = VK_EXTRA_BACKSPACE.w
                            end
                            cells[ci].w = dynfb
                        end
                    end
                    rowW = 0
                    for ci = 1, numCells do
                        rowW = rowW + cells[ci].w
                    end
                    if numCells > 1 then
                        rowW = rowW + ((numCells - 1) * VK_GAP)
                    end
                    if rowW > VK_GRID_W then
                        local over2 = rowW - VK_GRID_W
                        local per2 = math.floor((over2 + nLetters - 1) / nLetters)
                        local newW2 = VK_KEY_W - per2
                        if newW2 < VK_KEY_W_MIN then
                            newW2 = VK_KEY_W_MIN
                        end
                        for ci = 1, numCells do
                            if cells[ci].op == "insert" then
                                cells[ci].w = newW2
                            end
                        end
                        rowW = 0
                        for ci = 1, numCells do
                            rowW = rowW + cells[ci].w
                        end
                        if numCells > 1 then
                            rowW = rowW + ((numCells - 1) * VK_GAP)
                        end
                    end
                end
            end
        end

        local x = (VK_GRID_W - rowW) / 2
        local y = -((ri - 1) * (VK_KEY_H + VK_GAP))
        for ci = 1, numCells do
            local cd = cells[ci]
            local iconPath = nil
            if cd.icon then
                iconPath = VK_ICONS[cd.icon]
            end
            local btn = VK_CreateKey(grid, cd.label, cd.textSize, cd.r, cd.g, cd.b, iconPath)
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

-- ----------------------------------------------------------------------------
-- 5b. AUTOCOMPLETE GENERICO VK-4 (so consome a lista do Open)
-- ----------------------------------------------------------------------------
-- Constroi os botoes da fileira de sugestoes (mesma identidade das teclas:
-- VK_CreateKey com backdrop tooltip, alpha 0.80 intacto, ApplyFont e
-- destaque ouro via RefreshFocus). OnEnter foca, OnClick foca e preenche.
function VK:BuildSuggestRow()
    local row = self.suggestRow
    if not row then
        return
    end
    self.suggestButtons = {}
    for i = 1, VK_SUGGEST_MAX do
        local btn = VK_CreateKey(row, "", VK_SUGGEST_FONT, 1, 1, 1, nil)
        btn:SetWidth(VK_SUGGEST_W)
        btn:SetHeight(VK_SUGGEST_H)
        btn:SetPoint("LEFT", row, "LEFT", (i - 1) * (VK_SUGGEST_W + VK_GAP), 0)
        btn.suggestIdx = i
        btn:SetScript("OnEnter", function()
            VK:FocusSuggestion(this.suggestIdx)
        end)
        btn:SetScript("OnClick", function()
            VK:FocusSuggestion(this.suggestIdx)
            VK:AcceptSuggestion()
        end)
        pcall(function() btn:Hide() end)
        table.insert(self.suggestButtons, btn)
    end
    pcall(function() row:Hide() end)
end

-- Filtra autoCompleteList por PREFIXO do buffer (case-insensitive via
-- strlower), mostrando ate VK_SUGGEST_MAX. Lista nil ou vazia, buffer sem
-- match: fileira escondida e comportamento atual intacto. Buffer vazio casa
-- com tudo (prefixo vazio), entao mostra os primeiros da lista. Sem teto
-- de lista nesta fase (o teto de 20 e politica do MailScreen na VK-5).
function VK:UpdateSuggestions()
    local list = self.autoCompleteList
    if type(list) ~= "table" or table.getn(list) < 1 then
        self:HideSuggestions()
        return
    end
    local buf = self.buffer or ""
    local prefix = strlower(buf)
    local preLen = strlen(prefix)
    local matches = {}
    local n = table.getn(list)
    for i = 1, n do
        local cand = list[i]
        if type(cand) == "string" and cand ~= "" then
            if strsub(strlower(cand), 1, preLen) == prefix then
                table.insert(matches, cand)
                if table.getn(matches) >= VK_SUGGEST_MAX then
                    break
                end
            end
        end
    end
    local m = table.getn(matches)
    if m < 1 then
        self:HideSuggestions()
        return
    end
    self.suggestList = matches
    local sbtns = self.suggestButtons or {}
    for i = 1, VK_SUGGEST_MAX do
        local btn = sbtns[i]
        if btn then
            if i <= m then
                local label = matches[i]
                pcall(function()
                    btn.labelText:SetText(label)
                    btn:Show()
                end)
            else
                pcall(function() btn:Hide() end)
            end
        end
    end
    if self.suggestRow then
        pcall(function() self.suggestRow:Show() end)
    end
    if self.focusZone == "suggest" then
        if (tonumber(self.suggestIdx) or 1) > m then
            self.suggestIdx = m
        end
        self:RefreshFocus()
    end
end

-- Esconde a fileira e limpa os matches. Se o foco estava nas sugestoes,
-- devolve para a grade (coluna de origem) para nunca strandar o foco.
function VK:HideSuggestions()
    self.suggestList = {}
    if self.suggestRow then
        pcall(function() self.suggestRow:Hide() end)
    end
    local sbtns = self.suggestButtons or {}
    local ns = table.getn(sbtns)
    for i = 1, ns do
        local btn = sbtns[i]
        if btn then
            pcall(function() btn:Hide() end)
        end
    end
    if self.focusZone == "suggest" then
        self.focusZone = "grid"
        self:FocusCell(1, tonumber(self.returnCol) or tonumber(self.selCol) or 1)
    end
end

-- A numa sugestao PREENCHE o buffer com ela (sem fechar) e refiltra em
-- seguida (a fileira pode esconder se nao houver mais match). O foco volta
-- para a 1a fileira da grade. Respeita maxLetters: se o nome nao couber,
-- recusa com som de erro igual ao InsertChar (nunca trunca nome).
function VK:AcceptSuggestion()
    local list = self.suggestList or {}
    local s = list[tonumber(self.suggestIdx) or 1]
    if type(s) ~= "string" or s == "" then
        return
    end
    if self.maxLetters and strlen(s) > self.maxLetters then
        VK_Play("igQuestFailed")
        return
    end
    self.buffer = s
    self:UpdatePreview()
    VK_Play("igMainMenuOptionCheckBoxOn")
    self:UpdateSuggestions()
    self.focusZone = "grid"
    self:FocusCell(1, tonumber(self.returnCol) or 1)
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
-- (Passa por InsertChar, entao a fileira refiltra sozinha: prefixo com
-- espaco ou quebra em geral nao casa e a fileira esconde.)
function VK:InsertSpace()
    if self.multiLine then
        self:InsertChar("\n")
    else
        self:InsertChar(" ")
    end
end

-- ----------------------------------------------------------------------------
-- 5. FOCO + NAVEGACAO (OnDirection 2D com wrap por fileira + suggestRow)
-- ----------------------------------------------------------------------------
-- Pinta o foco conforme focusZone: na grade, a celula (selRow, selCol);
-- nas sugestoes, o botao suggestIdx (grade toda apagada). Mesma identidade:
-- borda ouro mais highlight visivel no foco, resto apagado.
function VK:RefreshFocus()
    local inSuggest = (self.focusZone == "suggest")
    local rows = self.keyCells
    if rows then
        local n = table.getn(rows)
        for ri = 1, n do
            local row = rows[ri]
            local m = table.getn(row)
            for ci = 1, m do
                local btn = row[ci]
                if btn then
                    if (not inSuggest) and ri == self.selRow and ci == self.selCol then
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
    local sbtns = self.suggestButtons
    if sbtns then
        local ns = table.getn(sbtns)
        for i = 1, ns do
            local sbtn = sbtns[i]
            if sbtn then
                if inSuggest and i == self.suggestIdx then
                    pcall(function()
                        sbtn:SetBackdropBorderColor(1, 0.82, 0.2, 0.95)
                        if sbtn.highlight then sbtn.highlight:Show() end
                    end)
                else
                    pcall(function()
                        sbtn:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.40)
                        if sbtn.highlight then sbtn.highlight:Hide() end
                    end)
                end
            end
        end
    end
end

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
    self.focusZone = "grid"
    self:RefreshFocus()
end

-- VK-4: leva o foco para a sugestao i (1-based, com clamp). Sem matches,
-- recusa (fileira escondida nao recebe foco).
function VK:FocusSuggestion(i)
    local m = table.getn(self.suggestList or {})
    if m < 1 then
        return
    end
    i = tonumber(i) or 1
    if i < 1 then i = 1 end
    if i > m then i = m end
    self.suggestIdx = i
    self.focusZone = "suggest"
    self:RefreshFocus()
end

function VK:OnDirection(dir)
    local d = string.upper(dir or "")
    if d ~= "UP" and d ~= "DOWN" and d ~= "LEFT" and d ~= "RIGHT" then
        return
    end
    -- VK-4: dentro das sugestoes, LEFT e RIGHT navegam com wrap, DOWN
    -- volta para a grade (coluna de origem) e UP fica parado (topo).
    if self.focusZone == "suggest" then
        local m = table.getn(self.suggestList or {})
        if m < 1 then
            self.focusZone = "grid"
            self:FocusCell(1, tonumber(self.returnCol) or 1)
            return
        end
        local idx = tonumber(self.suggestIdx) or 1
        if d == "LEFT" then
            idx = idx - 1
            if idx < 1 then idx = m end
            self:FocusSuggestion(idx)
            VK_Play("igMainMenuOptionCheckBoxOn")
        elseif d == "RIGHT" then
            idx = idx + 1
            if idx > m then idx = 1 end
            self:FocusSuggestion(idx)
            VK_Play("igMainMenuOptionCheckBoxOn")
        elseif d == "DOWN" then
            self.focusZone = "grid"
            self:FocusCell(1, tonumber(self.returnCol) or 1)
            VK_Play("igMainMenuOptionCheckBoxOn")
        end
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

    -- VK-4: UP a partir da 1a fileira da grade sobe para as sugestoes
    -- quando ha matches (guarda a coluna para o DOWN voltar). Sem matches,
    -- cai no comportamento normal (wrap para a ultima fileira).
    if d == "UP" and r == 1 then
        local m = table.getn(self.suggestList or {})
        if m > 0 then
            self.returnCol = c
            local idx = tonumber(self.suggestIdx) or 1
            if idx < 1 or idx > m then idx = 1 end
            self:FocusSuggestion(idx)
            VK_Play("igMainMenuOptionCheckBoxOn")
            return
        end
    end

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

-- Hold-to-repeat (molde MerchantMenu:StartRepeat/StopRepeat/
-- EnsureRepeatTicker + Cursor.repeatState 0.35/0.12): D-Pad repete
-- OnDirection na direcao segurada; "BACKSPACE" (X) repete Backspace.
-- Passo imediato + ticker via OnUpdate. Acoes de passo unico
-- (A/B/Y/L1/R1/Start) NAO passam por aqui: disparam 1x por pressao.
function VK:StartRepeat(id)
    if not self:IsOpen() then
        return
    end
    local key = string.upper(id or "")
    if key == "UP" or key == "DOWN" or key == "LEFT" or key == "RIGHT" then
        self:OnDirection(key)
        self.repeatState.kind = "DIR"
        self.repeatState.direction = key
        self.repeatState.timer = self.repeatState.initialDelay
        self:EnsureRepeatTicker()
    elseif key == "BACKSPACE" then
        self:Backspace()
        self.repeatState.kind = "BACKSPACE"
        self.repeatState.direction = nil
        self.repeatState.timer = self.repeatState.initialDelay
        self:EnsureRepeatTicker()
    end
end

function VK:StopRepeat(id)
    if not id then
        self.repeatState.kind = nil
        self.repeatState.direction = nil
        self.repeatState.timer = 0
        return
    end
    local key = string.upper(id)
    if key == "BACKSPACE" then
        if self.repeatState.kind == "BACKSPACE" then
            self.repeatState.kind = nil
            self.repeatState.timer = 0
        end
    elseif self.repeatState.direction == key then
        self.repeatState.kind = nil
        self.repeatState.direction = nil
        self.repeatState.timer = 0
    end
end

function VK:StopAllRepeat()
    self.repeatState.kind = nil
    self.repeatState.direction = nil
    self.repeatState.timer = 0
end

function VK:EnsureRepeatTicker()
    if self.repeatFrame then
        return
    end
    local f = CreateFrame("Frame", "ConsoleMode_VirtualKeyboardRepeatTicker")
    f:SetScript("OnUpdate", function()
        -- R2 (Steam) equivale ao modificador ALT: borda de subida com o
        -- VK aberto confirma (mesmo efeito do Start/botao OK, via
        -- VK:Accept, passo unico sem repeat). Fechado, so atualiza a
        -- borda e nunca confirma (R2 em outras telas nao faz nada aqui).
        local altNow = false
        if IsAltKeyDown then
            local okA, valA = pcall(IsAltKeyDown)
            if okA and valA then
                altNow = true
            end
        end
        if not VK:IsOpen() then
            VK.repeatState.kind = nil
            VK.repeatState.direction = nil
            VK.repeatState.timer = 0
            VK.altWasDown = altNow
            return
        end
        local kind = VK.repeatState.kind
        if kind then
            local elapsed = arg1 or 0.016
            VK.repeatState.timer = VK.repeatState.timer - elapsed
            if VK.repeatState.timer <= 0 then
                if kind == "DIR" then
                    local dir = VK.repeatState.direction
                    if dir then
                        VK:OnDirection(dir)
                        VK.repeatState.timer = VK.repeatState.interval
                    else
                        VK.repeatState.kind = nil
                        VK.repeatState.timer = 0
                    end
                elseif kind == "BACKSPACE" then
                    VK:Backspace()
                    local buf = VK.buffer or ""
                    if strlen(buf) <= 0 then
                        VK.repeatState.kind = nil
                        VK.repeatState.timer = 0
                    else
                        VK.repeatState.timer = VK.repeatState.interval
                    end
                else
                    VK.repeatState.kind = nil
                    VK.repeatState.timer = 0
                end
            end
        end
        -- R2 confirma: borda de subida do ALT com o VK aberto (passo
        -- unico, fora do repeat acima). chatActive bloqueia igual aos
        -- demais botoes do cursor.
        if altNow and not VK.altWasDown then
            local chatOn = false
            local vkb = ConsoleMode and ConsoleMode.keybindings
            if vkb and vkb.chatActive then
                chatOn = true
            end
            if not chatOn then
                VK:Accept()
            end
        end
        VK.altWasDown = altNow
    end)
    self.repeatFrame = f
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
    self:UpdateSuggestions()
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
    self:UpdateSuggestions()
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

-- A no controle: na grade ativa a tecla em foco (OK em foco = confirma de
-- verdade); nas sugestoes preenche o buffer sem fechar (VK-4).
function VK:Confirm()
    if self.focusZone == "suggest" then
        self:AcceptSuggestion()
        return
    end
    self:ActivateFocused()
end

-- Start / tecla OK: fecha e entrega o buffer via onConfirm (pcall)
function VK:Accept()
    if not self:IsOpen() then
        return
    end
    self:StopAllRepeat()
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

-- (VK:OnCancel removido: sem chamadores. B chama Close() direto via
-- CM_CursorCancel em Keybindings.lua e Hooks:CloseTopFrame chama Close().
-- O campo self.onCancel, callback de cancelamento do Open(), segue intacto.)

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

    -- Estado de repeat sempre limpo ao abrir (sem heranca de sessao anterior).
    self:StopAllRepeat()

    -- R2 (ALT) pre-segurado nao pode confirmar na abertura: garante o
    -- ticker (criado sob demanda no StartRepeat) rodando desde ja e
    -- semeia a borda com o estado real do modificador.
    self:EnsureRepeatTicker()
    local altHeld = false
    if IsAltKeyDown then
        local okA, valA = pcall(IsAltKeyDown)
        if okA and valA then
            altHeld = true
        end
    end
    self.altWasDown = altHeld

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
    self.autoCompleteList = nil
    if type(config.autoCompleteList) == "table" then
        self.autoCompleteList = config.autoCompleteList
    end
    self.onConfirm = config.onConfirm
    self.onCancel = config.onCancel
    self.targetEditBox = config.targetEditBox
    self.isOpen = true

    -- VK-4: foco sempre comeca na grade; a fileira filtra pelo buffer
    -- inicial (lista nil ou vazia = escondida, comportamento intacto).
    self.focusZone = "grid"
    self.suggestIdx = 1
    self.returnCol = 1

    if self.titleText then
        pcall(function() self.titleText:SetText(self.title) end)
    end
    self:UpdatePreview()
    self:UpdateSuggestions()

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
-- CM_CursorMove ja desvia para VK:StartRepeat/StopRepeat quando IsOpen(); aqui so
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
    self:StopAllRepeat()
    self.focusZone = "grid"
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
