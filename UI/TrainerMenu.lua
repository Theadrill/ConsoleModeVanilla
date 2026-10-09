-- ============================================================================
-- ConsoleModeVanilla - UI/TrainerMenu.lua
-- Sistema Modular de Treinamento de Classe e Profissões para Console/Gamepad
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- FASE 1: Detecção e Interceptação Segura do Treinador (Zero Taint / Warden Safe)
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_TrainerMenu = ConsoleMode_TrainerMenu or {}
local TrainerMenu = ConsoleMode_TrainerMenu
CM.trainerMenu = TrainerMenu

-- ----------------------------------------------------------------------------
-- 1. CONSTANTES VISUAIS, DESIGN SYSTEM & RECURSOS
-- ----------------------------------------------------------------------------
local FONTS = {
    titleBold = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    bodyBold  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Bold.ttf",
    medium    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Fonts\\AlegreyaSans-Medium.ttf",
    fallback  = "Fonts\\FRIZQT__.TTF",
}

local ICONS = {
    A      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\A.tga",
    B      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\B.tga",
    X      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\X.tga",
    Y      = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\Y.tga",
    LB     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LB.tga",
    RB     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\RB.tga",
    LT     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LT.tga",
    RT     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\RT.tga",
    LS     = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\LS.tga",
    DUP    = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DUP.tga",
    DDOWN  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DDOWN.tga",
    DLEFT  = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DLEFT.tga",
    DRIGHT = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\DRIGHT.tga",
    DALL   = "Interface\\AddOns\\ConsoleModeVanilla\\Media\\Icons\\Xbox\\navigate_all_directions.tga",
    GOLD   = "Interface\\MoneyFrame\\UI-GoldIcon",
    SILVER = "Interface\\MoneyFrame\\UI-SilverIcon",
    COPPER = "Interface\\MoneyFrame\\UI-CopperIcon",
}

local COLORS = {
    amber   = "|cffe09a15",
    white   = "|cffffffff",
    green   = "|cff1eff00",
    red     = "|cffff2020",
    gray    = "|cffaaaaaa",
    goldHex = "|cffffd700",
}

-- ----------------------------------------------------------------------------
-- 2. ESTADO DO MÓDULO (FASE 1)
-- ----------------------------------------------------------------------------
TrainerMenu.isOpen      = false
TrainerMenu.initialized = false
TrainerMenu.trainerName = nil
TrainerMenu.trainerType = nil
TrainerMenu.numServices = 0

-- ----------------------------------------------------------------------------
-- 3. SUPRESSÃO SEGURA DO FRAME NATIVO DA BLIZZARD (Zero Taint)
-- Torna ClassTrainerFrame invisível off-screen sem dar Hide() para manter a sessão
-- ----------------------------------------------------------------------------
function TrainerMenu:SuppressDefaultFrame()
    local f = ClassTrainerFrame or getglobal("ClassTrainerFrame")
    if f then
        f:SetAlpha(0)
        f:EnableMouse(false)
        f:ClearAllPoints()
        f:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 5000)
    end
end

-- ----------------------------------------------------------------------------
-- 4. EVENTOS DO CICLO DE VIDA DO TREINADOR
-- ----------------------------------------------------------------------------
function TrainerMenu:OnTrainerShow()
    -- 1. Suprime o frame nativo off-screen
    self:SuppressDefaultFrame()

    -- 2. Lê os metadados oficiais da interação
    local npcName = UnitName("npc")
    if not npcName or npcName == "" then
        npcName = "Treinador"
    end

    local trainerType = "class"
    if GetTrainerType then
        trainerType = GetTrainerType() or "class"
    end

    local numServices = 0
    if GetNumTrainerServices then
        numServices = GetNumTrainerServices() or 0
    end

    self.isOpen      = true
    self.trainerName = npcName
    self.trainerType = trainerType
    self.numServices = numServices

    -- 3. Formata tipo legível para o log de diagnóstico da Fase 1
    local typeLabel = "Classe"
    if trainerType == "tradeskill" then
        typeLabel = "Profissão"
    end

    -- 4. Exibe mensagem de confirmação limpa no chat
    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Treinador detectado: " .. tostring(npcName) .. " (Tipo: " .. typeLabel .. ", " .. tostring(numServices) .. " serviços)")

    -- 5. Delay de segurança (50ms) para re-suprimir caso a Blizzard tente renderizar tardiamente
    local delayedSafety = CreateFrame("Frame")
    delayedSafety:SetScript("OnUpdate", function()
        this.t = (this.t or 0) + (arg1 or 0)
        if this.t >= 0.05 then
            this:SetScript("OnUpdate", nil)
            TrainerMenu:SuppressDefaultFrame()
        end
    end)
end

function TrainerMenu:OnTrainerUpdate()
    if not self.isOpen then return end

    if GetNumTrainerServices then
        self.numServices = GetNumTrainerServices() or 0
    end
end

function TrainerMenu:OnTrainerClosed()
    if self.isOpen then
        self.isOpen      = false
        self.trainerName = nil
        self.trainerType = nil
        self.numServices = 0
    end
end

function TrainerMenu:OnMoneyUpdate()
    if not self.isOpen then return end
    -- Futura atualização de saldo no cabeçalho (Fase 2)
end

-- ----------------------------------------------------------------------------
-- 5. FECHAMENTO SEGURO VIA BOTÃO [B] / ESC / HOOKS
-- ----------------------------------------------------------------------------
function TrainerMenu:Close()
    if not self.isOpen then return end

    self.isOpen      = false
    self.trainerName = nil
    self.trainerType = nil
    self.numServices = 0

    if CloseTrainer then
        CloseTrainer()
    end
    PlaySound("igMainMenuClose")
end

function TrainerMenu:OnCancel()
    self:Close()
end

-- ----------------------------------------------------------------------------
-- 6. INICIALIZAÇÃO E REGISTRO DE EVENTOS
-- ----------------------------------------------------------------------------
function TrainerMenu:Initialize()
    if self.initialized then return end
    self.initialized = true

    local ef = CreateFrame("Frame", "ConsoleMode_TrainerEventFrame")
    ef:RegisterEvent("TRAINER_SHOW")
    ef:RegisterEvent("TRAINER_UPDATE")
    ef:RegisterEvent("TRAINER_CLOSED")
    ef:RegisterEvent("PLAYER_MONEY")

    ef:SetScript("OnEvent", function()
        if event == "TRAINER_SHOW" then
            TrainerMenu:OnTrainerShow()
        elseif event == "TRAINER_UPDATE" then
            TrainerMenu:OnTrainerUpdate()
        elseif event == "TRAINER_CLOSED" then
            TrainerMenu:OnTrainerClosed()
        elseif event == "PLAYER_MONEY" then
            TrainerMenu:OnMoneyUpdate()
        end
    end)
end

-- Inicialização automática no carregamento das variáveis/login
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    TrainerMenu:Initialize()
end)
