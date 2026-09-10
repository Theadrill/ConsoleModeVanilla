-- ============================================================================
-- ConsoleModeVanilla - UI/MerchantMenu.lua
-- Sistema Modular de Interação com NPC Vendedor & Inventário Split-View
-- Compatível com WoW Vanilla 1.12.1 / Lua 5.0 (Turtle WoW)
-- ============================================================================

local CM = ConsoleMode or {}
ConsoleMode = CM

ConsoleMode_MerchantMenu = ConsoleMode_MerchantMenu or {}
local MerchantMenu = ConsoleMode_MerchantMenu
CM.merchantMenu = MerchantMenu

-- ----------------------------------------------------------------------------
-- ESTADO DO MÓDULO (FASE 1)
-- ----------------------------------------------------------------------------
MerchantMenu.isOpen       = false
MerchantMenu.initialized  = false
MerchantMenu.currentNPC   = nil
MerchantMenu.canRepair    = false
MerchantMenu.itemCount    = 0
MerchantMenu.announced    = false
MerchantMenu.scanFrame    = nil

-- ----------------------------------------------------------------------------
-- 1. SUPRESSÃO SEGURA DE BOLSAS E DA JANELA NATIVA DA BLIZZARD (MerchantFrame)
-- ----------------------------------------------------------------------------
-- Fecha qualquer container de bolsas padrão da Blizzard ou de addons
function MerchantMenu:CloseAllOpenBags()
    -- 1. Janelas de container padrão da Blizzard (ContainerFrame1..5)
    for i = 1, 5 do
        local cf = getglobal("ContainerFrame" .. i)
        if cf and cf:IsVisible() then
            cf:Hide()
        end
    end

    -- 2. Desativa flags e funções internas da Blizzard
    if CloseBackpack then pcall(CloseBackpack) end
    if CloseBag then
        for b = 1, 4 do
            pcall(function() CloseBag(b) end)
        end
    end
    if CloseAllBags then pcall(CloseAllBags) end

    -- 3. Suporte defensivo para addons de bolsa populares em Vanilla
    local bagnon = getglobal("Bagnon")
    if bagnon and bagnon:IsVisible() then pcall(function() bagnon:Hide() end) end
    local pfBag = getglobal("pfBag")
    if pfBag and pfBag:IsVisible() then pcall(function() pfBag:Hide() end) end
    local bagshui = getglobal("BagshuiBagsFrame")
    if bagshui and bagshui:IsVisible() then pcall(function() bagshui:Hide() end) end
end

-- Torna o MerchantFrame 100% invisível e sem interação, mas MANTÉM ele aberto
-- CRÍTICO NO WOW 1.12: Se der MerchantFrame:Hide(), a Blizzard executa
-- MerchantFrame_OnHide(), que chama CloseMerchant() e zera todos os itens!
function MerchantMenu:SuppressDefaultFrame()
    if MerchantFrame then
        MerchantFrame:SetAlpha(0)
        MerchantFrame:EnableMouse(false)
        MerchantFrame:ClearAllPoints()
        MerchantFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 5000)
    end
    self:CloseAllOpenBags()
end

-- ----------------------------------------------------------------------------
-- 2. SINCRONIZAÇÃO ASSÍNCRONA DO CATÁLOGO DO VENDEDOR (SMSG_MERCHANT_LIST)
-- ----------------------------------------------------------------------------
function MerchantMenu:StartItemScan()
    local attempts = 0
    if not self.scanFrame then
        self.scanFrame = CreateFrame("Frame", "ConsoleMode_MerchantScanFrame")
    end

    self.scanFrame:SetScript("OnUpdate", function()
        local dt = arg1 or 0
        this.elapsed = (this.elapsed or 0) + dt
        if this.elapsed >= 0.05 then
            this.elapsed = 0
            attempts = attempts + 1

            local count = 0
            if GetMerchantNumItems then
                count = GetMerchantNumItems() or 0
            end

            -- Se os itens já chegaram do servidor ou atingimos o tempo limite (0.6s)
            if count > 0 or attempts >= 12 then
                this:SetScript("OnUpdate", nil)
                MerchantMenu:AnnounceMerchant(count)
            end
        end
    end)
end

function MerchantMenu:AnnounceMerchant(itemCount)
    if self.announced or not self.isOpen then return end
    self.announced = true
    self.itemCount = itemCount or 0

    -- Feedback visual limpo no chat para validação da FASE 1
    local repairStr = self.canRepair and "|cff00ff00Sim|r" or "|cffaaaaaaNão|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Interação com Mercador detectada: |cffffffff" .. (self.currentNPC or "Vendedor") .. "|r (" .. self.itemCount .. " itens | Reparo: " .. repairStr .. ")")

    -- Reforço de fechamento das bolsas nativas
    self:CloseAllOpenBags()
end

-- ----------------------------------------------------------------------------
-- 3. MANIPULADORES DE EVENTOS
-- ----------------------------------------------------------------------------
function MerchantMenu:OnMerchantShow()
    -- 1. Torna MerchantFrame invisível off-screen (sem dar Hide para não fechar a sessão)
    self:SuppressDefaultFrame()

    -- 2. Extrai metadados imediatos (Nome e Reparo)
    local npcName = UnitName("npc")
    if not npcName or npcName == "" then
        npcName = "Vendedor"
    end

    local canRepair = false
    if CanMerchantRepair then
        canRepair = CanMerchantRepair() and true or false
    end

    self.isOpen     = true
    self.announced  = false
    self.currentNPC = npcName
    self.canRepair  = canRepair
    self.itemCount  = 0

    -- 3. Inicia verificação assíncrona dos itens do servidor
    local instantCount = (GetMerchantNumItems and GetMerchantNumItems()) or 0
    if instantCount > 0 then
        self:AnnounceMerchant(instantCount)
    else
        self:StartItemScan()
    end

    -- 4. Delay de segurança (60ms) para fechar qualquer bolsa que abra assincronamente
    local delayedSafety = CreateFrame("Frame")
    delayedSafety:SetScript("OnUpdate", function()
        this.t = (this.t or 0) + (arg1 or 0)
        if this.t >= 0.06 then
            this:SetScript("OnUpdate", nil)
            MerchantMenu:CloseAllOpenBags()
        end
    end)
end

function MerchantMenu:OnMerchantUpdate()
    if self.isOpen and not self.announced then
        local count = (GetMerchantNumItems and GetMerchantNumItems()) or 0
        if count > 0 then
            if self.scanFrame then
                self.scanFrame:SetScript("OnUpdate", nil)
            end
            self:AnnounceMerchant(count)
        end
    end
end

function MerchantMenu:OnMerchantClosed()
    if self.isOpen then
        self.isOpen     = false
        self.announced  = false
        self.currentNPC = nil
        self.canRepair  = false
        self.itemCount  = 0

        if self.scanFrame then
            self.scanFrame:SetScript("OnUpdate", nil)
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cffe09a15[ConsoleMode]|r Interação com Mercador encerrada.")
    end
end

-- ----------------------------------------------------------------------------
-- 4. INICIALIZAÇÃO DO MÓDULO & REGISTRO DE EVENTOS
-- ----------------------------------------------------------------------------
function MerchantMenu:Initialize()
    if self.initialized then return end
    self.initialized = true

    -- Hook preventivo no OnShow do MerchantFrame
    -- 1) NÃO chama OpenAllBags()
    -- 2) Move para fora da tela e torna invisível (alpha 0)
    -- 3) Mantém IsVisible() verdadeiro para a Blizzard não chamar CloseMerchant()
    if MerchantFrame then
        MerchantFrame:SetScript("OnShow", function()
            MerchantFrame:SetAlpha(0)
            MerchantFrame:EnableMouse(false)
            MerchantFrame:ClearAllPoints()
            MerchantFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", 0, 5000)
            MerchantMenu:CloseAllOpenBags()
        end)

        -- Proteção no OnHide: impede que CloseMerchant() seja chamado inadvertidamente
        local orig_MerchantFrame_OnHide = MerchantFrame:GetScript("OnHide")
        MerchantFrame:SetScript("OnHide", function()
            if not MerchantMenu.isOpen then
                if orig_MerchantFrame_OnHide then
                    orig_MerchantFrame_OnHide()
                end
            end
        end)
    end

    -- Frame de Eventos Dedicado do MerchantMenu
    local ef = CreateFrame("Frame", "ConsoleMode_MerchantEventFrame")
    ef:RegisterEvent("MERCHANT_SHOW")
    ef:RegisterEvent("MERCHANT_UPDATE")
    ef:RegisterEvent("MERCHANT_CLOSED")

    ef:SetScript("OnEvent", function()
        if event == "MERCHANT_SHOW" then
            MerchantMenu:OnMerchantShow()
        elseif event == "MERCHANT_UPDATE" then
            MerchantMenu:OnMerchantUpdate()
        elseif event == "MERCHANT_CLOSED" then
            MerchantMenu:OnMerchantClosed()
        end
    end)
end

-- Inicialização automática no carregamento do arquivo
local autoInit = CreateFrame("Frame")
autoInit:RegisterEvent("VARIABLES_LOADED")
autoInit:RegisterEvent("PLAYER_LOGIN")
autoInit:SetScript("OnEvent", function()
    MerchantMenu:Initialize()
end)
