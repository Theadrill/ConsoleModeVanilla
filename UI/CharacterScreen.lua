-- ============================================================================
-- ConsoleModeVanilla - UI/CharacterScreen.lua
-- FASE 2 (docs/plano_de_feature_ABA_DO_PERSONAGEM.md): modulo isolado da aba
-- do Personagem — ScrollFrame + rolagem via D-Pad (UP/DOWN).
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
    blockBg     = { r = 0.08, g = 0.06, b = 0.04, a = 0.85 },
    blockBorder = { r = 0.50, g = 0.40, b = 0.28, a = 0.65 },
}

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
CharacterScreen.blocks       = CharacterScreen.blocks or nil

-- Rolagem: offset atual (px), passo por toque no D-Pad, altura do conteudo.
CharacterScreen.scrollOffset = CharacterScreen.scrollOffset or 0
CharacterScreen.scrollStep   = CharacterScreen.scrollStep or 60
CharacterScreen.contentH     = CharacterScreen.contentH or 0
CharacterScreen.viewH        = CharacterScreen.viewH or 0

CharacterScreen.numTestBlocks = 8
CharacterScreen.blockH       = 120
CharacterScreen.blockGap     = 12

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

    local contentH = (self.numTestBlocks * self.blockH)
        + ((self.numTestBlocks - 1) * self.blockGap) + 8
    self.contentH = contentH

    local scrollChild = CreateFrame("Frame", "ConsoleMode_CharacterScrollChild", scrollFrame)
    scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
    -- Largura explicita (padrao MainMenu 1.12): sem isto o child colapsa
    -- para 0px no primeiro frame e os blocos ficam invisiveis.
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

    self.blocks = {}

    local yOff = -4
    for i = 1, self.numTestBlocks do
        local block = CreateFrame("Frame", "ConsoleMode_CharacterTestBlock" .. i, scrollChild)
        block:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, yOff)
        block:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOff)
        block:SetHeight(self.blockH)
        block:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 12,
            insets   = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        block:SetBackdropColor(COLORS.blockBg.r, COLORS.blockBg.g, COLORS.blockBg.b, COLORS.blockBg.a)
        block:SetBackdropBorderColor(COLORS.blockBorder.r, COLORS.blockBorder.g, COLORS.blockBorder.b, COLORS.blockBorder.a)

        local title = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", block, "TOPLEFT", 12, -10)
        title:SetPoint("TOPRIGHT", block, "TOPRIGHT", -12, -10)
        title:SetJustifyH("LEFT")
        CS_ApplyFont(title, FONTS.titleBold, 16)
        title:SetText(COLORS.amberText .. "Bloco teste " .. i .. " — rolagem D-Pad|r")
        block.title = title

        local desc = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
        desc:SetPoint("TOPRIGHT", block, "TOPRIGHT", -12, -26)
        desc:SetJustifyH("LEFT")
        CS_ApplyFont(desc, FONTS.medium, 13)
        desc:SetText("Conteudo simulado da ficha (Fase 2). Use o D-Pad cima/baixo para rolar a pagina.")
        if type(desc.SetTextColor) == "function" then
            desc:SetTextColor(COLORS.body.r, COLORS.body.g, COLORS.body.b)
        end
        block.desc = desc

        local hint = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hint:SetPoint("BOTTOMLEFT", block, "BOTTOMLEFT", 12, 10)
        hint:SetPoint("BOTTOMRIGHT", block, "BOTTOMRIGHT", -12, 10)
        hint:SetJustifyH("LEFT")
        CS_ApplyFont(hint, FONTS.medium, 12)
        hint:SetText("[D-Pad Cima/Baixo] Rolar pagina")
        if type(hint.SetTextColor) == "function" then
            hint:SetTextColor(COLORS.hint.r, COLORS.hint.g, COLORS.hint.b)
        end
        block.hint = hint

        block:Show()
        table.insert(self.blocks, block)
        yOff = yOff - self.blockH - self.blockGap
    end

    -- Roda do mouse (b companion de mesa; o D-Pad continua sendo o principal).
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
