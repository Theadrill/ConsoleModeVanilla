-- ----------------------------------------------------------------------------
-- ConsoleModeVanilla - UI/MainMenuNav.lua
-- FASE 1 (docs/plano_de_feature_DPAD_NO_MAIN_MENU.md): esqueleto do modulo
-- de navegacao por D-pad do MainMenu (somente log + hold-to-repeat).
-- Molde: UI/MailScreen.lua OnDirection (5199-5238) e
-- StartRepeat/StopRepeat/EnsureRepeatTicker (5261-5313).
-- Lua 5.0 / WoW 1.12 estrito: sem #t, sem goto/continue, sem table.unpack;
-- usa getglobal/pcall defensivos e arg1 no OnUpdate.
-- ----------------------------------------------------------------------------

ConsoleMode_MainMenuNav = ConsoleMode_MainMenuNav or {}
local Nav = ConsoleMode_MainMenuNav

-- Expor em ConsoleMode.mainMenuNav se ConsoleMode existir (sem sobrescrever).
local _CM = getglobal("ConsoleMode")
if _CM then
    if not _CM.mainMenuNav then
        _CM.mainMenuNav = Nav
    end
end

-- Estado (molde MailScreen.repeatState): hold-to-repeat do D-pad com
-- initialDelay 0.35s e interval 0.12s. Ticker tem frame proprio.
Nav.navState = Nav.navState or { direction = nil, timer = 0, initialDelay = 0.35, interval = 0.12 }
Nav.ticker = Nav.ticker or nil

-- ----------------------------------------------------------------------------
-- Helpers defensivos (nunca quebram se o frame/modulo nao existir).
-- ----------------------------------------------------------------------------
local function SafeIsVisible(frame)
    if not frame then return false end
    if type(frame.IsVisible) ~= "function" then return false end
    local ok, vis = pcall(function() return frame:IsVisible() end)
    if ok and vis then return true end
    return false
end

local function IsVKOpen()
    local cm = getglobal("ConsoleMode")
    if cm and cm.VirtualKeyboard and type(cm.VirtualKeyboard.IsOpen) == "function" then
        local vk = cm.VirtualKeyboard
        local ok, open = pcall(function() return vk:IsOpen() end)
        if ok and open then return true end
    end
    local vf = getglobal("ConsoleMode_VirtualKeyboard")
    if SafeIsVisible(vf) then return true end
    return false
end

local function IsQtyOpen()
    local cm = getglobal("ConsoleMode")
    local qp = nil
    if cm then qp = cm.QuantityPicker end
    if not qp then qp = getglobal("ConsoleMode_QuantityPicker") end
    if qp and type(qp.IsOpen) == "function" then
        local ok, open = pcall(function() return qp:IsOpen() end)
        if ok and open then return true end
    end
    if SafeIsVisible(qp) then return true end
    return false
end

local function IsContextMenuOpen()
    local cm = getglobal("ConsoleMode")
    if cm and cm.ui and cm.ui.contextMenu then
        local m = cm.ui.contextMenu
        if m.frame and type(m.frame.IsVisible) == "function" then
            local fr = m.frame
            local ok, vis = pcall(function() return fr:IsVisible() end)
            if ok and vis then return true end
        end
    end
    local cf = getglobal("ConsoleModeContextMenu")
    if SafeIsVisible(cf) then return true end
    return false
end

local function IsQuestDetailOpen()
    local cm = getglobal("ConsoleMode")
    if cm and cm.mainMenu and type(cm.mainMenu.IsQuestDetailVisible) == "function" then
        local mm = cm.mainMenu
        local ok, vis = pcall(function() return mm:IsQuestDetailVisible() end)
        if ok and vis then return true end
    end
    if cm and cm.mainMenu and cm.mainMenu.questDetailOverlay then
        if SafeIsVisible(cm.mainMenu.questDetailOverlay) then return true end
    end
    return false
end

local function MMNav_Log(msg)
    local dcf = getglobal("DEFAULT_CHAT_FRAME")
    if dcf and type(dcf.AddMessage) == "function" then
        dcf:AddMessage(msg)
    end
end

-- ----------------------------------------------------------------------------
-- FASE 1: gate de atividade.
-- true SOMENTE se MainMenu visivel E Merchant/Mail fechados E nenhum modal
-- (VK/Qty/ContextMenu/questDetailOverlay) aberto.
-- ----------------------------------------------------------------------------
function Nav:IsActive()
    local mmFrame = getglobal("ConsoleModeMainMenuFrame")
    if not SafeIsVisible(mmFrame) then return false end
    local merchant = getglobal("ConsoleMode_MerchantMenu")
    if merchant and merchant.isOpen then return false end
    local mail = getglobal("ConsoleMode_MailScreen")
    if mail and mail.isOpen then return false end
    if IsVKOpen() then return false end
    if IsQtyOpen() then return false end
    if IsContextMenuOpen() then return false end
    if IsQuestDetailOpen() then return false end
    return true
end

-- Roteador OnDirection (molde MailScreen:5199-5238). FASE 1: so log + som.
function Nav:OnDirection(direction)
    if not self:IsActive() then return end
    MMNav_Log("|cffe09a15[MMNav]|r " .. tostring(direction))
    local ps = getglobal("PlaySound")
    if type(ps) == "function" then
        pcall(ps, "igMainMenuOptionCheckBoxOn")
    end
end

-- Hold-to-repeat (molde MailScreen:5261-5313). UP/DOWN/LEFT/RIGHT repetem.
function Nav:StartRepeat(direction)
    if not self:IsActive() then return end
    self:OnDirection(direction)
    self.navState.direction = direction
    self.navState.timer = self.navState.initialDelay
    self:EnsureRepeatTicker()
end

function Nav:StopRepeat(direction)
    if not direction or self.navState.direction == direction then
        self.navState.direction = nil
        self.navState.timer = 0
    end
end

function Nav:EnsureRepeatTicker()
    if self.ticker then return end
    local f = CreateFrame("Frame", "ConsoleMode_MainMenuNavRepeatTicker")
    f:SetScript("OnUpdate", function()
        if not Nav:IsActive() then
            Nav.navState.direction = nil
            return
        end
        local dir = Nav.navState.direction
        if dir then
            local elapsed = arg1 or 0.016
            Nav.navState.timer = Nav.navState.timer - elapsed
            if Nav.navState.timer <= 0 then
                Nav:OnDirection(dir)
                Nav.navState.timer = Nav.navState.interval
            end
        end
    end)
    self.ticker = f
end

-- FASE 1: botoes nao consomem (Keybindings decidira; cursor ainda trata).
-- Mapeamento real: A=Confirm, B=Cancel, Y=Use, X=Secondary.
function Nav:OnConfirm()
    MMNav_Log("|cffe09a15[MMNav]|r A (fase1: cursor ainda trata)")
    return false
end

function Nav:OnCancel()
    MMNav_Log("|cffe09a15[MMNav]|r B (fase1: cursor ainda trata)")
    return false
end

function Nav:OnUse()
    MMNav_Log("|cffe09a15[MMNav]|r Y (fase1: cursor ainda trata)")
    return false
end

function Nav:OnSecondary()
    MMNav_Log("|cffe09a15[MMNav]|r X (fase1: cursor ainda trata)")
    return false
end

function Nav:OnNextTab()
    MMNav_Log("|cffe09a15[MMNav]|r RB (fase1: cursor ainda trata)")
    return false
end

function Nav:OnPrevTab()
    MMNav_Log("|cffe09a15[MMNav]|r LB (fase1: cursor ainda trata)")
    return false
end

function Nav:OnNextSubTab()
    MMNav_Log("|cffe09a15[MMNav]|r RT (fase1: cursor ainda trata)")
    return false
end

function Nav:OnPrevSubTab()
    MMNav_Log("|cffe09a15[MMNav]|r LT (fase1: cursor ainda trata)")
    return false
end

function Nav:OnSmartTab()
    MMNav_Log("|cffe09a15[MMNav]|r TAB (fase1: cursor ainda trata)")
    return false
end

-- Inicializacao vazia e segura: so garante defaults, sem eventos, sem
-- tocar em Cursor/Hooks/Keybindings.
function Nav:Initialize()
    self.navState = self.navState or { direction = nil, timer = 0, initialDelay = 0.35, interval = 0.12 }
    if self.navState.initialDelay == nil then self.navState.initialDelay = 0.35 end
    if self.navState.interval == nil then self.navState.interval = 0.12 end
    if self.navState.timer == nil then self.navState.timer = 0 end
    if self.ticker == nil then self.ticker = nil end
end
