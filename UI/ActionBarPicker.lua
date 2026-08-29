--[[
    ConsoleMode - Vanilla
    UI/ActionBarPicker.lua - Seletor de Slot / Magia

    Layout do painel (dentro do contentFrame do ConfigFrame):
    ┌─────────────────────────────────────────────────────┐
    │ Mapear: [combo]                          [Voltar]   │
    │ Selecione...                                        │
    │ [Spellbook]  [Barras de Ação]   ← linha 1 (modo)   │
    │ [Geral][Classe]... ou [1:Princ][2:InfEsq]...        │
    │                      ← linha 2 (sub-aba do modo)   │
    │ ┌──────── grade de conteúdo (420×270) ───────────┐  │
    │ │ btn btn btn btn  (spellbook: 4×4 com paginação)│  │
    │ │  ou  slot slot slot slot  (barras: 4×3)        │  │
    │ └────────────────────────────────────────────────┘  │
    │            [< Prev]  1/1  [Next >]  (só spellbook)  │
    └─────────────────────────────────────────────────────┘

    Compatível com Lua 5.0 / WoW 1.12
]]

local CM = ConsoleMode
CM.config = CM.config or {}
CM.config.picker = CM.config.picker or {}
local Picker = CM.config.picker

Picker.frame        = nil
Picker.active       = false
Picker.targetPage   = 1
Picker.targetBtnKey = nil
Picker.targetCombo  = nil
Picker.parentFrame  = nil

-- "SPELLBOOK", "BAG" ou "BARS"
Picker.mode         = "SPELLBOOK"
Picker.spellTabIdx  = 1   -- aba do spellbook selecionada
Picker.currentBar   = 1   -- barra de ação selecionada (usado só quando mode == BARS)
Picker.gridPage     = 1
Picker.spellsCache  = {}
Picker.itemsCache   = {}  -- itens usáveis das bags

-- Dimensões da grade (compartilhadas pelos dois modos)
local GRID_COLS  = 4
local GRID_ROWS  = 4       -- 4 linhas × 4 cols = 16 botões por página
local GRID_COUNT = GRID_COLS * GRID_ROWS
local BTN_W      = 100
local BTN_H      = 62
local BTN_GAP    = 4
local GRID_W     = GRID_COLS * (BTN_W + BTN_GAP) - BTN_GAP   -- 412
local GRID_H     = GRID_ROWS * (BTN_H + BTN_GAP) - BTN_GAP   -- 252

-- Definições das barras de ação
local BAR_DEFINITIONS = {
    [1] = { name = "Principal",    startSlot = 1,  bindingPrefix = "ACTIONBUTTON",         count = 12 },
    [2] = { name = "Inf. Esq",     startSlot = 61, bindingPrefix = "MULTIACTIONBAR1BUTTON", count = 12 },
    [3] = { name = "Inf. Dir",     startSlot = 49, bindingPrefix = "MULTIACTIONBAR2BUTTON", count = 12 },
    [4] = { name = "Lat. Dir 1",   startSlot = 25, bindingPrefix = "MULTIACTIONBAR3BUTTON", count = 12 },
    [5] = { name = "Lat. Dir 2",   startSlot = 37, bindingPrefix = "MULTIACTIONBAR4BUTTON", count = 12 },
}

-- Tooltip scanner
local scanTip = CreateFrame("GameTooltip", "ConsoleModePickerScanTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- ============================================================================
-- HELPERS
-- ============================================================================

local function GetSlotInfo(slot)
    if not slot or slot <= 0 then return nil, "|cff888888(Vazio)|r" end
    local tex  = nil
    local name = nil

    local ok1, r1 = pcall(function() return GetActionTexture(slot) end)
    if ok1 and r1 then tex = r1 end

    local ok2, r2 = pcall(function() return GetActionText(slot) end)
    if ok2 and r2 and r2 ~= "" then name = r2 end

    if not name or name == "" then
        local ok3, has = pcall(function() return HasAction(slot) end)
        if ok3 and has then
            scanTip:ClearLines()
            local ok4 = pcall(function() scanTip:SetAction(slot) end)
            if ok4 then
                local t = ConsoleModePickerScanTooltipTextLeft1:GetText()
                if t and t ~= "" then name = t end
            end
            if not name or name == "" then name = "Acao " .. slot end
        else
            name = "|cff888888(Vazio)|r"
        end
    end
    return tex, name
end

-- Quebra nome longo em duas linhas no espaço mais próximo do centro
local function WrapName(s)
    if not s or string.len(s) <= 13 then return s or "" end
    local mid = math.floor(string.len(s) / 2)
    local bp  = nil
    for p = mid, 1, -1 do
        if string.sub(s, p, p) == " " then bp = p; break end
    end
    if not bp then
        for p = mid + 1, string.len(s) do
            if string.sub(s, p, p) == " " then bp = p; break end
        end
    end
    if bp then
        return string.sub(s, 1, bp - 1) .. "\n" .. string.sub(s, bp + 1)
    end
    return s
end

-- ============================================================================
-- CRIAÇÃO DA UI
-- ============================================================================

function Picker:CreateUI(parent)
    if self.frame then return end

    local f = CreateFrame("Frame", "ConsoleModeActionBarPickerFrame", parent)
    f:SetAllPoints(parent)

    -- ── Cabeçalho ────────────────────────────────────────────────────────────
    local titleStr = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleStr:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -12)
    titleStr:SetText("Mapear Tecla")
    f.titleStr = titleStr

    local subStr = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subStr:SetPoint("TOPLEFT", titleStr, "BOTTOMLEFT", 0, -3)
    subStr:SetText("Escolha a fonte e selecione uma magia ou slot.")
    f.subStr = subStr

    local backBtn = CreateFrame("Button", "ConsoleModePickerBackBtn", f, "UIPanelButtonTemplate")
    backBtn:SetWidth(80)
    backBtn:SetHeight(24)
    backBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -12)
    backBtn:SetText("Voltar")
    backBtn:SetScript("OnClick", function() Picker:Cancel() end)

    -- ── Linha 1 de abas: [Spellbook] [Barras de Ação] ────────────────────────
    local modeBar = CreateFrame("Frame", "ConsoleModePickerModeBar", f)
    modeBar:SetWidth(GRID_W)
    modeBar:SetHeight(24)
    modeBar:SetPoint("TOPLEFT", subStr, "BOTTOMLEFT", 0, -8)

    local modeSpell = CreateFrame("Button", "ConsoleModePickerModeSpell", modeBar, "UIPanelButtonTemplate")
    modeSpell:SetWidth(100)
    modeSpell:SetHeight(22)
    modeSpell:SetPoint("LEFT", modeBar, "LEFT", 0, 0)
    modeSpell:SetText("Spellbook")
    modeSpell:SetScript("OnClick", function() Picker:SetMode("SPELLBOOK") end)
    f.modeSpell = modeSpell

    local modeBar2 = CreateFrame("Button", "ConsoleModePickerModeBar2", modeBar, "UIPanelButtonTemplate")
    modeBar2:SetWidth(110)
    modeBar2:SetHeight(22)
    modeBar2:SetPoint("LEFT", modeSpell, "RIGHT", 5, 0)
    modeBar2:SetText("Barras de Acao")
    modeBar2:SetScript("OnClick", function() Picker:SetMode("BARS") end)
    f.modeBar2 = modeBar2

    local modeBag = CreateFrame("Button", "ConsoleModePickerModeBag", modeBar, "UIPanelButtonTemplate")
    modeBag:SetWidth(65)
    modeBag:SetHeight(22)
    modeBag:SetPoint("LEFT", modeBar2, "RIGHT", 5, 0)
    modeBag:SetText("Bag")
    modeBag:SetScript("OnClick", function() Picker:SetMode("BAG") end)
    f.modeBag = modeBag

    local modeMacro = CreateFrame("Button", "ConsoleModePickerModeMacro", modeBar, "UIPanelButtonTemplate")
    modeMacro:SetWidth(75)
    modeMacro:SetHeight(22)
    modeMacro:SetPoint("LEFT", modeBag, "RIGHT", 5, 0)
    modeMacro:SetText("Macros")
    modeMacro:SetScript("OnClick", function() Picker:SetMode("MACROS") end)
    f.modeMacro = modeMacro

    -- ── Linha 2 de abas: sub-abas (dinamicamente preenchidas) ────────────────
    local subTabBar = CreateFrame("Frame", "ConsoleModePickerSubTabBar", f)
    subTabBar:SetWidth(GRID_W)
    subTabBar:SetHeight(24)
    subTabBar:SetPoint("TOPLEFT", modeBar, "BOTTOMLEFT", 0, -4)
    f.subTabBar = subTabBar
    self.subTabButtons = {}

    -- ── Grade de conteúdo ────────────────────────────────────────────────────
    local gridFrame = CreateFrame("Frame", "ConsoleModePickerContentGrid", f)
    gridFrame:SetWidth(GRID_W)
    gridFrame:SetHeight(GRID_H)
    gridFrame:SetPoint("TOPLEFT", subTabBar, "BOTTOMLEFT", 0, -6)
    f.gridFrame = gridFrame

    -- Cria GRID_COUNT botões reutilizáveis
    self.gridButtons = {}
    for i = 1, GRID_COUNT do
        local col = math.mod(i - 1, GRID_COLS)
        local row = math.floor((i - 1) / GRID_COLS)

        local btn = CreateFrame("Button", "ConsoleModePickerGridBtn" .. i, gridFrame)
        btn:SetWidth(BTN_W)
        btn:SetHeight(BTN_H)
        btn:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", col * (BTN_W + BTN_GAP), -(row * (BTN_H + BTN_GAP)))
        btn:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(30)
        icon:SetHeight(30)
        icon:SetPoint("TOP", btn, "TOP", 0, -5)
        btn.icon = icon

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", -28, -2)
        label:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
        label:SetJustifyH("CENTER")
        label:SetJustifyV("TOP")
        btn.label = label

        local rankLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rankLabel:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
        rankLabel:SetTextColor(0.7, 0.7, 0.7)
        btn.rankLabel = rankLabel

        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonUp")

        local idx = i
        btn:SetScript("OnClick", function() Picker:OnGridClick(idx) end)
        btn:SetScript("OnEnter", function()
            this:SetBackdropBorderColor(1, 1, 0, 1)
            if this.tooltipSlot then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetAction(this.tooltipSlot)
                GameTooltip:Show()
            elseif this.tooltipSpell then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetSpell(this.tooltipSpell, "spell")
                GameTooltip:Show()
            elseif this.tooltipItem then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                pcall(function()
                    GameTooltip:SetBagItem(this.tooltipItem.bagID, this.tooltipItem.slotID)
                end)
                GameTooltip:Show()
            elseif this.tooltipMacro then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:AddLine(this.tooltipMacro.name, 1.0, 0.85, 0.2)
                if this.tooltipMacro.body and this.tooltipMacro.body ~= "" then
                    local preview = this.tooltipMacro.body
                    if string.len(preview) > 120 then
                        preview = string.sub(preview, 1, 117) .. "..."
                    end
                    GameTooltip:AddLine(preview, 0.8, 0.8, 0.8, 1)
                end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            this:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
            GameTooltip:Hide()
        end)

        self.gridButtons[i] = btn
    end

    -- ── Paginação (visível nos modos Spellbook, Bag e Macros) ─────────────────
    local prevBtn = CreateFrame("Button", "ConsoleModePickerPrevBtn", f, "UIPanelButtonTemplate")
    prevBtn:SetWidth(70)
    prevBtn:SetHeight(22)
    prevBtn:SetPoint("BOTTOMLEFT", gridFrame, "BOTTOMLEFT", 0, -28)
    prevBtn:SetText("< Prev")
    prevBtn:SetScript("OnClick", function()
        if Picker.gridPage > 1 then
            Picker.gridPage = Picker.gridPage - 1
            if Picker.mode == "BAG" then
                Picker:RefreshBagGrid()
            elseif Picker.mode == "MACROS" then
                Picker:RefreshMacroGrid()
            else
                Picker:RefreshSpellGrid()
            end
        end
    end)
    f.prevBtn = prevBtn

    local pageLabel = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pageLabel:SetPoint("LEFT", prevBtn, "RIGHT", 8, 0)
    pageLabel:SetText("1 / 1")
    f.pageLabel = pageLabel

    local nextBtn = CreateFrame("Button", "ConsoleModePickerNextBtn", f, "UIPanelButtonTemplate")
    nextBtn:SetWidth(70)
    nextBtn:SetHeight(22)
    nextBtn:SetPoint("LEFT", pageLabel, "RIGHT", 8, 0)
    nextBtn:SetText("Next >")
    nextBtn:SetScript("OnClick", function()
        local cacheSize = 0
        if Picker.mode == "BAG" then
            cacheSize = table.getn(Picker.itemsCache)
        elseif Picker.mode == "MACROS" then
            cacheSize = table.getn(Picker.macrosCache or {})
        else
            cacheSize = table.getn(Picker.spellsCache)
        end
        local total = math.ceil(cacheSize / GRID_COUNT)
        if total < 1 then total = 1 end
        if Picker.gridPage < total then
            Picker.gridPage = Picker.gridPage + 1
            if Picker.mode == "BAG" then
                Picker:RefreshBagGrid()
            elseif Picker.mode == "MACROS" then
                Picker:RefreshMacroGrid()
            else
                Picker:RefreshSpellGrid()
            end
        end
    end)
    f.nextBtn = nextBtn

    f:Hide()
    self.frame = f
end

-- ============================================================================
-- CONTROLE DE MODO (Spellbook / Barras)
-- ============================================================================

function Picker:SetMode(mode)
    self.mode = mode

    -- Destaca aba de modo ativa
    if self.frame then
        if mode == "SPELLBOOK" then
            self.frame.modeSpell:LockHighlight()
            self.frame.modeBar2:UnlockHighlight()
            self.frame.modeBag:UnlockHighlight()
            self.frame.modeMacro:UnlockHighlight()
        elseif mode == "BARS" then
            self.frame.modeSpell:UnlockHighlight()
            self.frame.modeBar2:LockHighlight()
            self.frame.modeBag:UnlockHighlight()
            self.frame.modeMacro:UnlockHighlight()
        elseif mode == "BAG" then
            self.frame.modeSpell:UnlockHighlight()
            self.frame.modeBar2:UnlockHighlight()
            self.frame.modeBag:LockHighlight()
            self.frame.modeMacro:UnlockHighlight()
        else  -- MACROS
            self.frame.modeSpell:UnlockHighlight()
            self.frame.modeBar2:UnlockHighlight()
            self.frame.modeBag:UnlockHighlight()
            self.frame.modeMacro:LockHighlight()
        end
    end

    -- Reconstrói sub-abas
    self:BuildSubTabs()

    -- Paginação: visível no Spellbook, Bag e Macros, oculta nas Barras
    if self.frame then
        if mode == "BARS" then
            self.frame.prevBtn:Hide()
            self.frame.pageLabel:Hide()
            self.frame.nextBtn:Hide()
        else
            self.frame.prevBtn:Show()
            self.frame.pageLabel:Show()
            self.frame.nextBtn:Show()
        end
    end
end

-- ============================================================================
-- SUB-ABAS
-- ============================================================================

function Picker:BuildSubTabs()
    -- Limpa sub-abas antigas
    for _, btn in ipairs(self.subTabButtons) do
        btn:Hide()
    end
    self.subTabButtons = {}

    local subTabBar = self.frame.subTabBar
    local TAB_W = 80
    local TAB_GAP = 4

    if self.mode == "SPELLBOOK" then
        -- Sub-abas = abas do spellbook (GetSpellTabInfo)
        local SBP = CM.config and CM.config.spellbookPicker
        local tabs = SBP and SBP:GetSpellTabs() or {}

        -- Trunca nome da aba para caber no botão (máx 8 chars + "…")
        local function TruncTab(s)
            if not s then return "" end
            if string.len(s) <= 9 then return s end
            return string.sub(s, 1, 8) .. "..."
        end

        for i, tab in ipairs(tabs) do
            local tabNum = i
            -- Interrompe se não couber na largura total
            local xPos = (i - 1) * (TAB_W + TAB_GAP)
            if xPos + TAB_W > GRID_W then break end

            local btn = CreateFrame("Button", "ConsoleModePickerSpellTab" .. i, subTabBar, "UIPanelButtonTemplate")
            btn:SetWidth(TAB_W)
            btn:SetHeight(22)
            btn:SetPoint("LEFT", subTabBar, "LEFT", xPos, 0)
            btn:SetText(TruncTab(tab.name))
            btn:SetScript("OnClick", function()
                Picker.spellTabIdx = tabNum
                Picker.gridPage = 1
                Picker:HighlightSubTab(tabNum)
                Picker:LoadSpellTab(tabNum)
            end)
            -- Tooltip com nome completo ao passar o mouse
            btn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetText(tab.name)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            tinsert(self.subTabButtons, btn)
        end

        -- Seleciona aba ativa
        self:HighlightSubTab(self.spellTabIdx)
        self:LoadSpellTab(self.spellTabIdx)

    elseif self.mode == "BARS" then
        -- Sub-abas = 5 barras de ação
        for b = 1, 5 do
            local barNum = b
            local btn = CreateFrame("Button", "ConsoleModePickerBarTab" .. b, subTabBar, "UIPanelButtonTemplate")
            btn:SetWidth(TAB_W)
            btn:SetHeight(22)
            btn:SetPoint("LEFT", subTabBar, "LEFT", (b - 1) * (TAB_W + TAB_GAP), 0)
            btn:SetText(BAR_DEFINITIONS[b].name)
            btn:SetScript("OnClick", function()
                Picker.currentBar = barNum
                Picker:HighlightSubTab(barNum)
                Picker:RefreshBarGrid()
            end)
            tinsert(self.subTabButtons, btn)
        end

        -- Seleciona barra ativa
        self:HighlightSubTab(self.currentBar)
        self:RefreshBarGrid()

    elseif self.mode == "MACROS" then
        -- Sub-abas de Macros: [Gerais] e [Personagem]
        local macroTabs = { "Gerais", "Personagem" }
        for t = 1, 2 do
            local tabNum = t
            local btn = CreateFrame("Button", "ConsoleModePickerMacroTab" .. t, subTabBar, "UIPanelButtonTemplate")
            btn:SetWidth(100)
            btn:SetHeight(22)
            btn:SetPoint("LEFT", subTabBar, "LEFT", (t - 1) * (100 + TAB_GAP), 0)
            btn:SetText(macroTabs[t])
            btn:SetScript("OnClick", function()
                Picker.macroTabIdx = tabNum
                Picker.gridPage = 1
                Picker:HighlightSubTab(tabNum)
                Picker:LoadMacroTab(tabNum)
            end)
            tinsert(self.subTabButtons, btn)
        end

        self.macroTabIdx = self.macroTabIdx or 1
        self:HighlightSubTab(self.macroTabIdx)
        self:LoadMacroTab(self.macroTabIdx)

    else
        -- Modo BAG: sem sub-abas, carrega itens usáveis das bags
        self:RefreshBagGrid()
    end
end

function Picker:HighlightSubTab(activeIdx)
    for i, btn in ipairs(self.subTabButtons) do
        if i == activeIdx then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end
end

-- ============================================================================
-- GRADE — SPELLBOOK
-- ============================================================================

function Picker:LoadSpellTab(tabNum)
    local SBP = CM.config and CM.config.spellbookPicker
    if not SBP then self.spellsCache = {}; self:RefreshSpellGrid(); return end

    local tabs = SBP:GetSpellTabs()
    local tab  = tabs[tabNum]
    if not tab then
        self.spellsCache = {}
    else
        self.spellsCache = SBP:GetSpellsForTab(tab)
    end
    self.gridPage = 1
    self:RefreshSpellGrid()
end

function Picker:RefreshSpellGrid()
    local total      = table.getn(self.spellsCache)
    local totalPages = math.ceil(total / GRID_COUNT)
    if totalPages < 1 then totalPages = 1 end
    if self.gridPage > totalPages then self.gridPage = totalPages end

    self.frame.pageLabel:SetText(self.gridPage .. " / " .. totalPages)

    local offset = (self.gridPage - 1) * GRID_COUNT

    for i = 1, GRID_COUNT do
        local btn   = self.gridButtons[i]
        local spell = self.spellsCache[offset + i]

        btn.tooltipSlot  = nil
        btn.tooltipSpell = nil

        if spell then
            btn.spell = spell
            btn.icon:SetTexture(spell.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            btn.label:SetText(WrapName(spell.name))
            btn.rankLabel:SetText(spell.rank ~= "" and spell.rank or "")
            btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
            btn:EnableMouse(true)
            btn.tooltipSpell = spell.spellIndex
        else
            btn.spell = nil
            btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            btn.label:SetText("")
            btn.rankLabel:SetText("")
            btn:SetBackdropColor(0.05, 0.05, 0.05, 0.4)
            btn:EnableMouse(false)
        end
        btn:Show()
    end
end

-- ============================================================================
-- GRADE — BARRAS DE AÇÃO (12 slots, usa apenas os primeiros GRID_COUNT botões)
-- ============================================================================

function Picker:RefreshBarGrid()
    local barDef = BAR_DEFINITIONS[self.currentBar]
    if not barDef then return end

    -- Barras têm 12 slots, mas a grade tem GRID_COUNT (16) botões.
    -- Preenchemos os 12 primeiros e deixamos os 4 últimos vazios.
    for i = 1, GRID_COUNT do
        local btn = self.gridButtons[i]
        btn.spell        = nil
        btn.tooltipSlot  = nil
        btn.tooltipSpell = nil

        if i <= 12 then
            local realSlot = barDef.startSlot + i - 1
            local tex, name = GetSlotInfo(realSlot)
            btn.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
            btn.label:SetText(WrapName(name))
            btn.rankLabel:SetText("#" .. i)
            btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
            btn:EnableMouse(true)
            btn.slotIndex    = i
            btn.tooltipSlot  = realSlot
        else
            btn.icon:SetTexture("")
            btn.label:SetText("")
            btn.rankLabel:SetText("")
            btn:SetBackdropColor(0.03, 0.03, 0.03, 0.3)
            btn:EnableMouse(false)
            btn.slotIndex = nil
        end
        btn:Show()
    end
end

-- ============================================================================
-- GRADE — BAG (itens usáveis das bags 0-4, paginado)
-- ============================================================================

function Picker:RefreshBagGrid()
    local BP = CM.config and CM.config.bagPicker
    if not BP then
        self.itemsCache = {}
    else
        self.itemsCache = BP:GetUsableItems()
    end

    local total      = table.getn(self.itemsCache)
    local totalPages = math.ceil(total / GRID_COUNT)
    if totalPages < 1 then totalPages = 1 end
    if self.gridPage > totalPages then self.gridPage = totalPages end

    self.frame.pageLabel:SetText(self.gridPage .. " / " .. totalPages)

    local offset = (self.gridPage - 1) * GRID_COUNT

    for i = 1, GRID_COUNT do
        local btn  = self.gridButtons[i]
        local item = self.itemsCache[offset + i]

        btn.spell        = nil
        btn.tooltipSlot  = nil
        btn.tooltipSpell = nil
        btn.tooltipItem  = nil
        btn.bagItem      = nil

        if item then
            btn.bagItem = item
            btn.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            -- Mostra quantidade se > 1
            local displayName = WrapName(item.name)
            btn.label:SetText(displayName)
            -- rankLabel mostra quantidade do stack
            if item.count and item.count > 1 then
                btn.rankLabel:SetText("x" .. item.count)
            else
                btn.rankLabel:SetText("")
            end
            btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
            btn:EnableMouse(true)
            btn.tooltipItem = { bagID = item.bagID, slotID = item.slotID }
        else
            btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            btn.label:SetText("")
            btn.rankLabel:SetText("")
            btn:SetBackdropColor(0.05, 0.05, 0.05, 0.4)
            btn:EnableMouse(false)
        end
        btn:Show()
    end
end

-- ============================================================================
-- GRADE — MACROS (Gerais da Conta e do Personagem)
-- ============================================================================

function Picker:LoadMacroTab(tabIdx)
    self.macroTabIdx = tabIdx
    local MP = CM.config and CM.config.macroPicker
    if not MP then
        self.macrosCache = {}
    elseif tabIdx == 1 then
        self.macrosCache = MP:GetAccountMacros()
    else
        self.macrosCache = MP:GetCharacterMacros()
    end
    self:RefreshMacroGrid()
end

function Picker:RefreshMacroGrid()
    self.macrosCache = self.macrosCache or {}
    local total      = table.getn(self.macrosCache)
    local totalPages = math.ceil(total / GRID_COUNT)
    if totalPages < 1 then totalPages = 1 end
    if self.gridPage > totalPages then self.gridPage = totalPages end

    self.frame.pageLabel:SetText(self.gridPage .. " / " .. totalPages)

    local offset = (self.gridPage - 1) * GRID_COUNT

    for i = 1, GRID_COUNT do
        local btn   = self.gridButtons[i]
        local macro = self.macrosCache[offset + i]

        btn.spell        = nil
        btn.tooltipSlot  = nil
        btn.tooltipSpell = nil
        btn.tooltipItem  = nil
        btn.tooltipMacro = nil
        btn.bagItem      = nil
        btn.macro        = nil

        if macro then
            btn.macro = macro
            btn.icon:SetTexture(macro.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local displayName = WrapName(macro.name)
            btn.label:SetText(displayName)
            btn.rankLabel:SetText("")
            btn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
            btn:EnableMouse(true)
            btn.tooltipMacro = macro
        else
            btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            btn.label:SetText("")
            btn.rankLabel:SetText("")
            btn:SetBackdropColor(0.05, 0.05, 0.05, 0.4)
            btn:EnableMouse(false)
        end
        btn:Show()
    end
end

-- ============================================================================
-- CLIQUE NA GRADE
-- ============================================================================

function Picker:OnGridClick(idx)
    if not self.active then return end

    if self.mode == "SPELLBOOK" then
        local offset = (self.gridPage - 1) * GRID_COUNT
        local btn    = self.gridButtons[idx]
        local spell  = btn and btn.spell
        if not spell then return end

        local SBP = CM.config and CM.config.spellbookPicker
        if SBP then
            SBP:ApplySpellBinding(self.targetPage, self.targetBtnKey, self.targetCombo, spell)
        end
        self:Cancel()

    elseif self.mode == "BAG" then
        local btn  = self.gridButtons[idx]
        local item = btn and btn.bagItem
        if not item then return end

        local BP = CM.config and CM.config.bagPicker
        if BP then
            BP:ApplyItemBinding(self.targetPage, self.targetBtnKey, self.targetCombo, item)
        end
        self:Cancel()

    elseif self.mode == "MACROS" then
        local btn   = self.gridButtons[idx]
        local macro = btn and btn.macro
        if not macro then return end

        local MP = CM.config and CM.config.macroPicker
        if MP then
            MP:ApplyMacroBinding(self.targetPage, self.targetBtnKey, self.targetCombo, macro)
        end
        self:Cancel()

    else
        -- Modo barras: funciona igual ao ConfirmSlotByIndex antigo
        local btn = self.gridButtons[idx]
        if not btn or not btn.slotIndex then return end

        local barDef = BAR_DEFINITIONS[self.currentBar]
        if not barDef then return end

        local slotIndex    = btn.slotIndex
        local bindingAction = barDef.bindingPrefix .. slotIndex
        local KEY_MAPPINGS = CM.config.spellbookPicker and CM.config.spellbookPicker.KEY_MAPPINGS
        local physKey = KEY_MAPPINGS and KEY_MAPPINGS[self.targetPage] and KEY_MAPPINGS[self.targetPage][self.targetBtnKey]

        if not physKey then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro ao vincular tecla!")
            self:Cancel()
            return
        end

        local KB = CM.keybindings
        if KB and KB.navigationMode and KB.savedNavBindings then
            for k, act in pairs(KB.savedNavBindings) do
                if act and act ~= "" and not string.find(act, "^CM_CURSOR_") then
                    SetBinding(k, act)
                elseif k == "TAB" then
                    SetBinding("TAB", "TARGETNEARESTENEMY")
                end
            end
        end

        SetBinding(physKey, bindingAction)

        if KB and KB.savedNavBindings then
            KB.savedNavBindings[physKey] = bindingAction
        end

        local set = GetCurrentBindingSet()
        if not set or set == 0 then set = 1 end
        pcall(function() SaveBindings(set) end)

        if KB and KB.navigationMode and KB.defaults and KB.defaults[1] then
            local d1 = KB.defaults[1]
            SetBinding(d1.DUP,    "CM_CURSOR_UP")
            SetBinding(d1.DDOWN,  "CM_CURSOR_DOWN")
            SetBinding(d1.DLEFT,  "CM_CURSOR_LEFT")
            SetBinding(d1.DRIGHT, "CM_CURSOR_RIGHT")
            SetBinding(d1.A,      "CM_CURSOR_CONFIRM")
            SetBinding(d1.B,      "CM_CURSOR_CANCEL")
        end

        local realSlot = barDef.startSlot + slotIndex - 1
        local _, actionName = GetSlotInfo(realSlot)
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ff00[ConsoleMode]|r |cffffcc00" .. self.targetCombo
            .. "|r vinculado a |cff88ccff" .. (actionName or ("Slot " .. slotIndex))
            .. "|r (" .. barDef.name .. ")!"
        )
        PlaySound("igMainMenuOptionCheckBoxOn")

        if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.Update then
            CM.ui.actionHUD:Update()
        end

        self:Cancel()
    end
end

-- ============================================================================
-- SHOW / CANCEL
-- ============================================================================

function Picker:Show(parent, page, btnKey, comboName)
    self.parentFrame  = parent
    self.targetPage   = page    or 1
    self.targetBtnKey = btnKey
    self.targetCombo  = comboName or "?"

    self:CreateUI(parent)

    self.active = true
    self.frame.titleStr:SetText("Mapear: |cffffcc00" .. self.targetCombo .. "|r")

    -- Começa sempre no modo Spellbook
    self.mode       = "SPELLBOOK"
    self.spellTabIdx = 1
    self.gridPage   = 1

    self:SetMode("SPELLBOOK")

    self.frame:Show()
end

function Picker:Cancel()
    self.active = false
    if self.frame then
        self.frame:Hide()
    end

    local kbList = CM.config and CM.config.keybindingsList
    if kbList and self.parentFrame then
        kbList:Show(self.parentFrame)
        kbList:SelectPage(self.targetPage or 1)
    end
end
