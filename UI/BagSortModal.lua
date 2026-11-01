--[[
================================================================================
ConsoleModeVanilla - UI/BagSortModal.lua
Modal de Configurações da Ordenação Virtual (Virtual Sort Options)
Compatível estritamente com WoW 1.12.1 (Interface 11200) / Lua 5.0
================================================================================
Módulo satélite desacoplado: gerencia a interface visual, navegação via D-Pad
e ajuste de preferências do Virtual Sort sem inchar o MainMenu.
]]--

ConsoleMode_BagSortModal = ConsoleMode_BagSortModal or {}
local Modal = ConsoleMode_BagSortModal
local CM = ConsoleMode or {}
CM.BagSortModal = Modal

-- ============================================================================
-- 1. CONSTANTES VISUAIS & ASSETS
-- ============================================================================
local FONTS = {
    titleBold = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    medium    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Medium.ttf",
    fallback  = "Fonts\\FRIZQT__.TTF",
}

local ICONS = {
    A      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\A.tga",
    B      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\B.tga",
    X      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\X.tga",
    Y      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\Y.tga",
    DUP    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DUP.tga",
    DDOWN  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DDOWN.tga",
    DLEFT  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DLEFT.tga",
    DRIGHT = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DRIGHT.tga",
}

local NINESLICE = {
    texture    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Carved_9Slides.tga",
    cornerSize = 48,
    drawLayer  = "BACKGROUND",
    uv = {
        col = {
            { 0.0000, 0.2500 },
            { 0.2500, 0.5000 },
            { 0.5000, 0.7500 },
        },
        row = {
            { 0.0000, 0.2500 },
            { 0.2500, 0.5000 },
            { 0.5000, 0.7500 },
        }
    }
}

local OPTION_DEFS = {
    {
        key = "enabled",
        labelKey = "BAGS_SORT_OPT_ENABLED",
        type = "TOGGLE",
    },
    {
        key = "mode",
        labelKey = "BAGS_SORT_OPT_MODE",
        type = "CYCLE",
        values = { "CATEGORY", "QUALITY", "NAME", "LEVEL" },
        textKeys = {
            CATEGORY = "BAGS_SORT_MODE_CATEGORY",
            QUALITY  = "BAGS_SORT_MODE_QUALITY",
            NAME     = "BAGS_SORT_MODE_NAME",
            LEVEL    = "BAGS_SORT_MODE_LEVEL",
        }
    },
    {
        key = "preset",
        labelKey = "BAGS_SORT_OPT_PRESET",
        type = "CYCLE",
        values = { "BALANCED", "EQUIP", "CONSUMABLE", "TRADE" },
        textKeys = {
            BALANCED   = "BAGS_SORT_PRESET_BALANCED",
            EQUIP      = "BAGS_SORT_PRESET_EQUIP",
            CONSUMABLE = "BAGS_SORT_PRESET_CONSUMABLE",
            TRADE      = "BAGS_SORT_PRESET_TRADE",
        }
    },
    {
        key = "questOnTop",
        labelKey = "BAGS_SORT_OPT_QUEST_TOP",
        type = "TOGGLE",
    },
    {
        key = "groupByName",
        labelKey = "BAGS_SORT_OPT_GROUP_NAME",
        type = "TOGGLE",
    },
}

-- ============================================================================
-- 2. ESTADO INTERNO DO MODAL
-- ============================================================================
Modal.isOpen = false
Modal.selectedRow = 1
Modal.frame = nil
Modal.dimmer = nil
Modal.rows = nil

local function ApplyFont(fontString, fontPath, size)
    if not fontString then return end
    fontPath = fontPath or FONTS.medium
    size = size or 13
    local ok = fontString:SetFont(fontPath, size, "")
    if not ok then
        fontString:SetFont(FONTS.fallback, size, "")
    end
    fontString:SetShadowOffset(1, -1)
    fontString:SetShadowColor(0, 0, 0, 0.90)
end

local function Create9Slice(parent, texturePath, cornerSize, uvMap, drawLayer)
    cornerSize = cornerSize or 48
    drawLayer = drawLayer or "BACKGROUND"
    local slices = {}

    for r = 1, 3 do
        slices[r] = {}
        for c = 1, 3 do
            local tex = parent:CreateTexture(nil, drawLayer)
            tex:SetTexture(texturePath)
            tex:SetTexCoord(uvMap.col[c][1], uvMap.col[c][2], uvMap.row[r][1], uvMap.row[r][2])
            slices[r][c] = tex
        end
    end

    -- Cantos
    slices[1][1]:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    slices[1][1]:SetWidth(cornerSize)
    slices[1][1]:SetHeight(cornerSize)

    slices[1][3]:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    slices[1][3]:SetWidth(cornerSize)
    slices[1][3]:SetHeight(cornerSize)

    slices[3][1]:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    slices[3][1]:SetWidth(cornerSize)
    slices[3][1]:SetHeight(cornerSize)

    slices[3][3]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    slices[3][3]:SetWidth(cornerSize)
    slices[3][3]:SetHeight(cornerSize)

    -- Bordas
    slices[1][2]:SetPoint("TOPLEFT", slices[1][1], "TOPRIGHT", 0, 0)
    slices[1][2]:SetPoint("BOTTOMRIGHT", slices[1][3], "BOTTOMLEFT", 0, 0)

    slices[3][2]:SetPoint("TOPLEFT", slices[3][1], "TOPRIGHT", 0, 0)
    slices[3][2]:SetPoint("BOTTOMRIGHT", slices[3][3], "BOTTOMLEFT", 0, 0)

    slices[2][1]:SetPoint("TOPLEFT", slices[1][1], "BOTTOMLEFT", 0, 0)
    slices[2][1]:SetPoint("BOTTOMRIGHT", slices[3][1], "TOPRIGHT", 0, 0)

    slices[2][3]:SetPoint("TOPLEFT", slices[1][3], "BOTTOMLEFT", 0, 0)
    slices[2][3]:SetPoint("BOTTOMRIGHT", slices[3][3], "TOPRIGHT", 0, 0)

    -- Centro
    slices[2][2]:SetPoint("TOPLEFT", slices[1][1], "BOTTOMRIGHT", 0, 0)
    slices[2][2]:SetPoint("BOTTOMRIGHT", slices[3][3], "TOPLEFT", 0, 0)

    return slices
end

-- ============================================================================
-- 3. CRIAÇÃO DA INTERFACE (POOL FIXO SINGLETON)
-- ============================================================================
function Modal:CreateUI()
    if self.frame then return end

    -- 3.1. Dimmer
    local dimmer = CreateFrame("Frame", "ConsoleMode_BagSortModalDimmer", UIParent)
    dimmer:SetAllPoints(UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:SetFrameLevel(45)
    dimmer:EnableMouse(true)
    dimmer:Hide()

    local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
    dimTex:SetAllPoints(dimmer)
    dimTex:SetTexture(0, 0, 0, 0.70)
    dimmer.bg = dimTex

    dimmer:SetScript("OnMouseDown", function()
        Modal:Close()
    end)

    -- 3.2. Janela Central (Dimensões adaptativas para Steam Deck 1280x800)
    local modal = CreateFrame("Frame", "ConsoleMode_BagSortModalFrame", dimmer)
    modal:SetWidth(520)
    modal:SetHeight(410)
    modal:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(50)
    modal:EnableMouse(true)
    modal:SetScript("OnMouseDown", function() end)

    Create9Slice(modal, NINESLICE.texture, NINESLICE.cornerSize, NINESLICE.uv, NINESLICE.drawLayer)

    -- 3.3. Cabeçalho
    local title = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", modal, "TOP", 0, -20)
    ApplyFont(title, FONTS.titleBold, 20)
    title:SetTextColor(1.0, 0.85, 0.25, 1.0)
    title:SetText(CM:T("BAGS_SORT_MODAL_TITLE"))
    modal.title = title

    local sub = modal:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -4)
    ApplyFont(sub, FONTS.medium, 13)
    sub:SetTextColor(0.85, 0.85, 0.85, 1.0)
    sub:SetText(CM:T("BAGS_SORT_MODAL_SUB"))
    modal.sub = sub

    local div = modal:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    div:SetPoint("TOPLEFT", modal, "TOPLEFT", 26, -60)
    div:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -26, -60)
    div:SetTexture(0.60, 0.48, 0.32, 0.60)

    -- 3.4. Pool Fixo de 5 Linhas de Opções
    local rows = {}
    local startY = -70
    local rowH = 36
    local rowGap = 5
    local numDefs = table.getn(OPTION_DEFS)

    for i = 1, numDefs do
        local def = OPTION_DEFS[i]
        local row = CreateFrame("Button", "ConsoleMode_BagSortRow" .. i, modal)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", modal, "TOPLEFT", 26, startY - ((i - 1) * (rowH + rowGap)))
        row:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -26, startY - ((i - 1) * (rowH + rowGap)))

        row:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })

        -- Label do Nome da Opção (à esquerda)
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", row, "LEFT", 14, 0)
        ApplyFont(lbl, FONTS.titleBold, 15)
        lbl:SetText(CM:T(def.labelKey))
        row.lbl = lbl

        -- Seta Esquerda < (visível quando focada)
        local arrowL = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        arrowL:SetPoint("RIGHT", row, "RIGHT", -170, 0)
        ApplyFont(arrowL, FONTS.titleBold, 16)
        arrowL:SetTextColor(1.0, 0.85, 0.25, 0.90)
        arrowL:SetText("<")
        row.arrowL = arrowL

        -- Valor Atual (centralizado entre as setas)
        local valTxt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valTxt:SetPoint("CENTER", row, "RIGHT", -95, 0)
        ApplyFont(valTxt, FONTS.titleBold, 14)
        row.valTxt = valTxt

        -- Seta Direita > (visível quando focada)
        local arrowR = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        arrowR:SetPoint("RIGHT", row, "RIGHT", -18, 0)
        ApplyFont(arrowR, FONTS.titleBold, 16)
        arrowR:SetTextColor(1.0, 0.85, 0.25, 0.90)
        arrowR:SetText(">")
        row.arrowR = arrowR

        local idx = i
        row:SetScript("OnEnter", function()
            if Modal.selectedRow ~= idx then
                Modal.selectedRow = idx
                Modal:UpdateRows()
            end
        end)

        row:SetScript("OnClick", function()
            Modal.selectedRow = idx
            local cx = GetCursorPosition()
            local s = row:GetEffectiveScale() or 1
            local left = row:GetLeft() or 0
            local width = row:GetWidth() or 400
            local mid = left + (width / 2)
            if (cx / s) < mid then
                Modal:CycleOption(idx, -1)
            else
                Modal:CycleOption(idx, 1)
            end
        end)

        rows[i] = row
    end

    modal.rows = rows

    -- 3.5. Rodapé com Texturas Reais do Gamepad (Padrão Oficial do MainMenu)
    local footer = CreateFrame("Frame", "ConsoleMode_BagSortFooter", modal)
    footer:SetHeight(30)
    footer:SetPoint("BOTTOM", modal, "BOTTOM", 0, 16)

    local hintDefs = {
        { icons = { ICONS.DUP, ICONS.DDOWN }, tKey = "HINT_NAVIGATE", isDpad = true },
        { icons = { ICONS.DLEFT, ICONS.DRIGHT }, tKey = "BAGS_SORT_HINT_CHANGE", isDpad = true },
        { icons = { ICONS.A }, tKey = "HINT_CONFIRM", isAction = true },
        { icons = { ICONS.Y }, tKey = "BAGS_SORT_HINT_RESET", isAction = true },
        { icons = { ICONS.B }, tKey = "HINT_CLOSE", isAction = true },
    }

    local iconGap = 2
    local labelGap = 5
    local groupGap = 16
    local currentX = 0
    local footerHints = {}

    for h = 1, table.getn(hintDefs) do
        local hint = hintDefs[h]
        local groupFrame = CreateFrame("Frame", nil, footer)
        groupFrame:SetHeight(28)
        groupFrame:SetPoint("LEFT", footer, "LEFT", currentX, 0)

        local groupX = 0
        for ic = 1, table.getn(hint.icons) do
            local iconTex = groupFrame:CreateTexture(nil, "OVERLAY")
            local curW = 25
            local curH = 25
            if hint.isDpad then
                curW = 21
                curH = 21
            end
            iconTex:SetWidth(curW)
            iconTex:SetHeight(curH)
            iconTex:SetTexture(hint.icons[ic])
            iconTex:SetPoint("LEFT", groupFrame, "LEFT", groupX, 0)
            groupX = groupX + curW + iconGap
        end

        local iconsTotalW = groupX - iconGap
        local textStartX = iconsTotalW + labelGap

        local lbl = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", groupFrame, "LEFT", textStartX, 0)
        ApplyFont(lbl, FONTS.medium, 14)
        lbl:SetTextColor(0.85, 0.85, 0.85, 0.95)
        lbl:SetText(CM:T(hint.tKey))

        local textW = math.floor(lbl:GetStringWidth() or 40)
        local totalGroupW = textStartX + textW
        groupFrame:SetWidth(totalGroupW)

        currentX = currentX + totalGroupW + groupGap
        table.insert(footerHints, {
            lbl = lbl,
            tKey = hint.tKey,
            group = groupFrame,
            iconsTotalW = iconsTotalW,
        })
    end

    local totalFooterWidth = currentX - groupGap
    footer:SetWidth(totalFooterWidth)

    footer.hints = footerHints
    modal.footer = footer

    self.dimmer = dimmer
    self.frame = modal
    self.rows = rows
end

-- ============================================================================
-- 4. ATUALIZAÇÃO DINÂMICA DO LAYOUT E LARGURA (RODAPÉ & JANELA)
-- ============================================================================
--- Recalcula a largura dos textos do rodapé e ajusta dinamicamente a largura
-- do modal para acomodar confortavelmente traduções de qualquer idioma/tamanho.
function Modal:UpdateFooterLayout()
    if not self.frame or not self.frame.footer or not self.frame.footer.hints then return end
    local footer = self.frame.footer
    local groupGap = 16
    local labelGap = 5
    local currentX = 0
    local numHints = table.getn(footer.hints)

    for h = 1, numHints do
        local item = footer.hints[h]
        if item.lbl and item.tKey then
            item.lbl:SetText(CM:T(item.tKey))
        end
        local strW = math.ceil(item.lbl:GetStringWidth() or 30)
        if strW < 20 then strW = 20 end
        local totalGroupW = item.iconsTotalW + labelGap + strW
        item.group:SetWidth(totalGroupW)
        item.group:ClearAllPoints()
        item.group:SetPoint("LEFT", footer, "LEFT", currentX, 0)
        currentX = currentX + totalGroupW + groupGap
    end

    local totalFooterWidth = currentX - groupGap
    footer:SetWidth(totalFooterWidth)

    -- Largura adaptativa: calcula a largura necessária com margens de 40px em cada lado
    -- para respeitar o 9-slice esculpido (cornerSize=48) sem sobrepor ou vazar texto.
    local minWidth = 520
    local padding = 80
    local requiredWidth = totalFooterWidth + padding
    local finalWidth = math.max(minWidth, requiredWidth)

    self.frame:SetWidth(finalWidth)
end

-- ============================================================================
-- 5. ATUALIZAÇÃO VISUAL DAS LINHAS
-- ============================================================================
function Modal:UpdateRows()
    if not self.frame or not self.rows then return end

    if self.frame.title then
        self.frame.title:SetText(CM:T("BAGS_SORT_MODAL_TITLE"))
    end
    if self.frame.sub then
        self.frame.sub:SetText(CM:T("BAGS_SORT_MODAL_SUB"))
    end

    -- Ajusta o rodapé e a largura do modal dinamicamente
    self:UpdateFooterLayout()

    local cfg = CM:GetVirtualSortConfig()
    local numDefs = table.getn(OPTION_DEFS)

    for i = 1, numDefs do
        local def = OPTION_DEFS[i]
        local row = self.rows[i]
        local isFocused = (i == self.selectedRow)

        -- Atualiza label (para suportar troca de idioma runtime)
        row.lbl:SetText(CM:T(def.labelKey))

        -- Estilo do Backdrop
        if isFocused then
            row:SetBackdropColor(0.22, 0.17, 0.10, 0.90)
            row:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
            row.lbl:SetTextColor(1.0, 0.95, 0.70, 1.0)
            row.arrowL:Show()
            row.arrowR:Show()
        else
            row:SetBackdropColor(0.08, 0.07, 0.05, 0.60)
            row:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.50)
            row.lbl:SetTextColor(0.80, 0.80, 0.80, 1.0)
            row.arrowL:Hide()
            row.arrowR:Hide()
        end

        -- Valor Atual Formatado
        if def.type == "TOGGLE" then
            local val = cfg[def.key]
            if def.key == "enabled" then
                if val then
                    row.valTxt:SetText(CM:T("BAGS_SORT_VAL_ON"))
                else
                    row.valTxt:SetText(CM:T("BAGS_SORT_VAL_OFF"))
                end
            else
                if val then
                    row.valTxt:SetText(CM:T("BAGS_SORT_VAL_YES"))
                else
                    row.valTxt:SetText(CM:T("BAGS_SORT_VAL_NO"))
                end
            end
        elseif def.type == "CYCLE" then
            local val = cfg[def.key]
            local tKey = def.textKeys[val] or val
            row.valTxt:SetText(CM:T(tKey))
        end
    end
end

-- ============================================================================
-- 5. CICLAGEM E ALTERAÇÃO DE OPÇÕES (EXCLUSIVAMENTE D-PAD ESQ/DIR OU CLIQUE)
-- ============================================================================
function Modal:CycleOption(rowIdx, step)
    if not rowIdx or rowIdx < 1 or rowIdx > table.getn(OPTION_DEFS) then return end
    step = step or 1

    local def = OPTION_DEFS[rowIdx]
    local cfg = CM:GetVirtualSortConfig()

    if def.type == "TOGGLE" then
        local currentVal = cfg[def.key]
        local newVal = not currentVal
        CM:SetVirtualSortConfig(def.key, newVal)
    elseif def.type == "CYCLE" then
        local currentVal = cfg[def.key]
        local vals = def.values
        local numVals = table.getn(vals)
        local curIdx = 1

        for v = 1, numVals do
            if vals[v] == currentVal then
                curIdx = v
                break
            end
        end

        local nextIdx = curIdx + step
        if nextIdx > numVals then
            nextIdx = 1
        elseif nextIdx < 1 then
            nextIdx = numVals
        end

        CM:SetVirtualSortConfig(def.key, vals[nextIdx])
    end

    if PlaySound then
        PlaySound("igMainMenuOptionCheckBoxOn")
    end

    self:UpdateRows()

    -- Reatividade em tempo real: reorganiza as bolsas no MainMenu imediatamente
    if MainMenu and MainMenu.UpdateBagsPage then
        pcall(function() MainMenu:UpdateBagsPage(true) end)
    end
end

-- ============================================================================
-- 6. RESTAURAR PADRÕES (ATALHO [Y])
-- ============================================================================
function Modal:ResetDefaults()
    CM:ResetVirtualSortConfig()
    self:UpdateRows()

    if PlaySound then
        PlaySound("igMainMenuOptionCheckBoxOn")
    end

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r " .. CM:T("BAGS_SORT_RESET_MSG"))
    end

    if MainMenu and MainMenu.UpdateBagsPage then
        pcall(function() MainMenu:UpdateBagsPage(true) end)
    end
end

-- ============================================================================
-- 7. NAVEGAÇÃO VIA GAMEPAD / D-PAD (DIRECIONAL PURO)
-- ============================================================================
function Modal:OnNavigate(direction)
    if not self.isOpen then return false end

    local numDefs = table.getn(OPTION_DEFS)

    if direction == "UP" then
        if self.selectedRow > 1 then
            self.selectedRow = self.selectedRow - 1
        else
            self.selectedRow = numDefs
        end
        self:UpdateRows()
        if PlaySound then PlaySound("igMainMenuOption") end
        return true
    elseif direction == "DOWN" then
        if self.selectedRow < numDefs then
            self.selectedRow = self.selectedRow + 1
        else
            self.selectedRow = 1
        end
        self:UpdateRows()
        if PlaySound then PlaySound("igMainMenuOption") end
        return true
    elseif direction == "LEFT" then
        self:CycleOption(self.selectedRow, -1)
        return true
    elseif direction == "RIGHT" then
        self:CycleOption(self.selectedRow, 1)
        return true
    end

    return false
end

-- ============================================================================
-- 8. CONTROLE DE ABERTURA / FECHAMENTO
-- ============================================================================
function Modal:IsOpen()
    if self.isOpen then return true end
    if self.dimmer and self.dimmer.IsVisible and self.dimmer:IsVisible() then
        return true
    end
    return false
end

function Modal:Open()
    if CM and CM.LoadDataLake and CM.DataLake and not CM.DataLake.loaded then
        CM:LoadDataLake("BagSortModal")
    end

    self:CreateUI()
    if not self.dimmer then return end

    self.selectedRow = 1
    self.isOpen = true
    self.dimmer:Show()
    self:UpdateRows()

    if PlaySound then
        PlaySound("igMainMenuOpen")
    end
end

function Modal:Close()
    if not self.isOpen and (not self.dimmer or not self.dimmer:IsVisible()) then return end

    self.isOpen = false
    if self.dimmer then
        self.dimmer:Hide()
    end

    if PlaySound then
        PlaySound("igMainMenuClose")
    end
end
