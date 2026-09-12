-- ----------------------------------------------------------------------------
-- ConsoleModeVanilla - UI/MainMenuNav.lua
-- FASE 1: esqueleto (log + hold-to-repeat). FASE 2: BAGS piloto
-- (docs/plano_de_feature_DPAD_NO_MAIN_MENU.md): zonas TABBAR/EQUIP/CATS/GRID,
-- destaque ouro, A/B/Y consomem em BAGS; demais abas seguem em modo log.
-- Molde: UI/MailScreen.lua OnDirection e StartRepeat/StopRepeat (0.35s/0.12s).
-- Lua 5.0 / WoW 1.12 estrito: sem #t, sem goto/continue, sem table.unpack.
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

-- FASE 2: foco por zona dentro da aba BAGS.
Nav.focus = Nav.focus or { zone = "GRID", tabIdx = 1, equipIndex = 1, catIndex = nil, gridIndex = 1, returnZone = "GRID" }

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

local function MMNav_PlayMove()
    local ps = getglobal("PlaySound")
    if type(ps) == "function" then
        pcall(ps, "igMainMenuOptionCheckBoxOn")
    end
end

local function MMNav_HideCursor()
    -- Cursor:Hide() esconde o visual sem zerar estado (nunca Disable).
    local cm = getglobal("ConsoleMode")
    if cm and cm.cursor and type(cm.cursor.Hide) == "function" then
        pcall(function() cm.cursor:Hide() end)
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

-- ----------------------------------------------------------------------------
-- FASE 2: acesso as zonas BAGS (tudo defensivo; nil se aba ainda nao montada).
-- ----------------------------------------------------------------------------
local function Nav_GetMM()
    local cm = getglobal("ConsoleMode")
    if cm and cm.mainMenu then return cm.mainMenu end
    return getglobal("ConsoleModeMainMenu")
end

local function Nav_GetTabButtons()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.tabContainer then return nil end
    if not MM.tabContainer.tabBar then return nil end
    return MM.tabContainer.tabBar.buttons
end

local function Nav_GetCurrentTab()
    local MM = Nav_GetMM()
    if MM and MM.tabContainer and MM.tabContainer.currentTab then
        return MM.tabContainer.currentTab
    end
    return nil
end

local function Nav_GetEquipButtons()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.equipColumn then return nil end
    return MM.equipColumn.buttons
end

local function Nav_GetPageBags()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.tabContainer then return nil end
    if not MM.tabContainer.pages then return nil end
    return MM.tabContainer.pages["BAGS"]
end

local function Nav_GetCatButtons()
    local pb = Nav_GetPageBags()
    if not pb then return nil end
    return pb.catButtons
end

local function Nav_GetGrid()
    local pb = Nav_GetPageBags()
    if not pb then return nil end
    return pb.grid
end

local function Nav_VisibleGridCount()
    local grid = Nav_GetGrid()
    if not grid or not grid.slots then return 0 end
    local n = 0
    local total = table.getn(grid.slots)
    for i = 1, total do
        local slot = grid.slots[i]
        if slot and type(slot.IsVisible) == "function" then
            local ok, vis = pcall(function() return slot:IsVisible() end)
            if ok and vis then n = n + 1 end
        end
    end
    return n
end

local function Nav_FindCatIndexForCurrent()
    local pb = Nav_GetPageBags()
    local cats = Nav_GetCatButtons()
    if not pb or not cats then return nil end
    local cur = pb.currentCategory
    if not cur then return nil end
    local n = table.getn(cats)
    for i = 1, n do
        local b = cats[i]
        if b and b.catData and b.catData.id == cur then return i end
    end
    return nil
end

-- Garante foco valido (clampa índices; resolve catIndex inicial via categoria).
local function Nav_EnsureFocus()
    local f = Nav.focus
    local tabs = Nav_GetTabButtons()
    local nt = 0
    if tabs then nt = table.getn(tabs) end
    if nt < 1 then nt = 5 end
    if not f.tabIdx or f.tabIdx < 1 then f.tabIdx = 1 end
    if f.tabIdx > nt then f.tabIdx = nt end

    local eq = Nav_GetEquipButtons()
    local ne = 0
    if eq then ne = table.getn(eq) end
    if ne < 1 then ne = 17 end
    if not f.equipIndex or f.equipIndex < 1 then f.equipIndex = 1 end
    if f.equipIndex > ne then f.equipIndex = ne end

    local cats = Nav_GetCatButtons()
    local nc = 0
    if cats then nc = table.getn(cats) end
    if nc > 0 then
        if not f.catIndex then
            f.catIndex = Nav_FindCatIndexForCurrent() or nc
        end
        if f.catIndex < 1 then f.catIndex = 1 end
        if f.catIndex > nc then f.catIndex = nc end
    end

    local vis = Nav_VisibleGridCount()
    if vis > 0 then
        if not f.gridIndex or f.gridIndex < 1 then f.gridIndex = 1 end
        if f.gridIndex > vis then f.gridIndex = vis end
    else
        if not f.gridIndex or f.gridIndex < 1 then f.gridIndex = 1 end
    end

    if f.zone ~= "TABBAR" and f.zone ~= "EQUIP" and f.zone ~= "CATS" and f.zone ~= "GRID" then
        f.zone = "GRID"
    end
    if f.returnZone ~= "EQUIP" and f.returnZone ~= "CATS" and f.returnZone ~= "GRID" then
        f.returnZone = "GRID"
    end
end

-- Aplica o visual ouro + DetailCard + esconde o cursor espacial.
local function Nav_ApplyFocus()
    Nav_EnsureFocus()
    local f = Nav.focus
    MMNav_HideCursor()

    -- TABBAR: highlight do botao focado (somente highlight; nunca title).
    local tabs = Nav_GetTabButtons()
    if tabs then
        local n = table.getn(tabs)
        for i = 1, n do
            local btn = tabs[i]
            if btn then
                if f.zone == "TABBAR" and i == f.tabIdx then
                    if btn.highlight then pcall(function() btn.highlight:Show() end) end
                else
                    if btn.highlight then pcall(function() btn.highlight:Hide() end) end
                end
            end
        end
    end

    -- EQUIP: borda dourada + DetailCard do slot.
    local eq = Nav_GetEquipButtons()
    if eq then
        local n = table.getn(eq)
        for i = 1, n do
            local btn = eq[i]
            if btn and btn.border and type(btn.border.SetVertexColor) == "function" then
                if f.zone == "EQUIP" and i == f.equipIndex then
                    pcall(function() btn.border:SetVertexColor(1.0, 0.82, 0.20) end)
                else
                    pcall(function() btn.border:SetVertexColor(1.0, 1.0, 1.0) end)
                end
            end
        end
        if f.zone == "EQUIP" then
            local btn = eq[f.equipIndex]
            if btn and btn.invSlotID then
                local MM = Nav_GetMM()
                if MM and type(MM.GetActiveDetailCard) == "function" then
                    local ok, card = pcall(function() return MM:GetActiveDetailCard() end)
                    if ok and card and type(card.ShowEquipSlot) == "function" then
                        pcall(function() card:ShowEquipSlot(btn.invSlotID, btn.slotData) end)
                    end
                end
            end
        end
    end

    -- CATS: com foco (zone==CATS) foco ouro/ativo branco; sem foco ativa ouro.
    local cats = Nav_GetCatButtons()
    local pb = Nav_GetPageBags()
    local curCat = nil
    if pb then curCat = pb.currentCategory end
    if cats then
        local n = table.getn(cats)
        for i = 1, n do
            local btn = cats[i]
            if btn and btn.title and type(btn.title.SetTextColor) == "function" then
                if f.zone == "CATS" and i == f.catIndex then
                    pcall(function() btn.title:SetTextColor(1.0, 0.82, 0.20) end)
                elseif btn.catData and btn.catData.id == curCat then
                    if f.zone == "CATS" then
                        pcall(function() btn.title:SetTextColor(1.0, 1.0, 1.0) end)
                    else
                        pcall(function() btn.title:SetTextColor(1.0, 0.82, 0.20) end)
                    end
                else
                    pcall(function() btn.title:SetTextColor(0.6, 0.6, 0.6) end)
                end
            end
        end
    end

    -- GRID: usa SelectSlot (acende highlight + DetailCard + compare).
    if f.zone == "GRID" then
        local grid = Nav_GetGrid()
        if grid and type(grid.SelectSlot) == "function" then
            pcall(function() grid:SelectSlot(f.gridIndex) end)
        end
    end
end

-- Roteador OnDirection. FASE 2: BAGS tem navegação real; demais abas, log.
function Nav:OnDirection(direction)
    if not self:IsActive() then return end
    if Nav_GetCurrentTab() ~= "BAGS" then
        MMNav_Log("|cffe09a15[MMNav]|r " .. tostring(direction))
        MMNav_PlayMove()
        return
    end
    Nav_EnsureFocus()
    local moved = Nav_OnBagsDirection(direction)
    Nav_ApplyFocus()
    if moved then MMNav_PlayMove() end
end

-- FASE 2: navegação BAGS. Retorna true se moveu/tratou.
function Nav_OnBagsDirection(direction)
    local f = Nav.focus
    if direction == "UP" then
        if f.zone == "TABBAR" then return false end
        if f.zone == "EQUIP" then
            if f.equipIndex > 1 then f.equipIndex = f.equipIndex - 1 return true end
            f.returnZone = "EQUIP"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "CATS" then
            f.returnZone = "CATS"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "GRID" then
            local grid = Nav_GetGrid()
            local cols = 8
            if grid and grid.cols then cols = grid.cols end
            if grid and grid.GetCapacity then local ok, _, c = pcall(function() return grid:GetCapacity() end) if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end end
            if (f.gridIndex - cols) >= 1 then
                f.gridIndex = f.gridIndex - cols
                return true
            end
            f.returnZone = "GRID"
            f.zone = "CATS"
            return true
        end
        return false
    end
    if direction == "DOWN" then
        if f.zone == "TABBAR" then
            f.zone = f.returnZone or "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "EQUIP" then
            local eq = Nav_GetEquipButtons()
            local ne = 17
            if eq then ne = table.getn(eq) end
            if f.equipIndex < ne then f.equipIndex = f.equipIndex + 1 return true end
            return false
        end
        if f.zone == "CATS" then
            f.zone = "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "GRID" then
            local grid = Nav_GetGrid()
            local cols = 8
            if grid and grid.cols then cols = grid.cols end
            if grid and grid.GetCapacity then local ok, _, c = pcall(function() return grid:GetCapacity() end) if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end end
            local vis = Nav_VisibleGridCount()
            if (f.gridIndex + cols) <= vis then
                f.gridIndex = f.gridIndex + cols
                return true
            end
            return false
        end
        return false
    end
    if direction == "LEFT" then
        if f.zone == "TABBAR" then
            if f.tabIdx > 1 then f.tabIdx = f.tabIdx - 1 return true end
            return false
        end
        if f.zone == "EQUIP" then return false end
        if f.zone == "CATS" then
            local cats = Nav_GetCatButtons()
            local nc = 0
            if cats then nc = table.getn(cats) end
            if f.catIndex and f.catIndex < nc then
                f.catIndex = f.catIndex + 1
                return true
            end
            f.zone = "EQUIP"
            return true
        end
        if f.zone == "GRID" then
            local grid = Nav_GetGrid()
            local cols = 8
            if grid and grid.cols then cols = grid.cols end
            if grid and grid.GetCapacity then local ok, _, c = pcall(function() return grid:GetCapacity() end) if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end end
            if math.mod(f.gridIndex - 1, cols) ~= 0 then
                f.gridIndex = f.gridIndex - 1
                return true
            end
            f.zone = "EQUIP"
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if direction == "RIGHT" then
        if f.zone == "TABBAR" then
            local tabs = Nav_GetTabButtons()
            local nt = 5
            if tabs then nt = table.getn(tabs) end
            if f.tabIdx < nt then f.tabIdx = f.tabIdx + 1 return true end
            return false
        end
        if f.zone == "EQUIP" then
            f.zone = "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "CATS" then
            local cats = Nav_GetCatButtons()
            local nc = 0
            if cats then nc = table.getn(cats) end
            if f.catIndex and f.catIndex > 1 then
                f.catIndex = f.catIndex - 1
                return true
            end
            f.zone = "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "GRID" then
            local grid = Nav_GetGrid()
            local cols = 8
            if grid and grid.cols then cols = grid.cols end
            if grid and grid.GetCapacity then local ok, _, c = pcall(function() return grid:GetCapacity() end) if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end end
            local vis = Nav_VisibleGridCount()
            if math.mod(f.gridIndex, cols) ~= 0 and (f.gridIndex + 1) <= vis then
                f.gridIndex = f.gridIndex + 1
                return true
            end
            return false
        end
        return false
    end
    return false
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

-- FASE 2: A/B/Y consomem em BAGS (retornam true); demais abas, false.
function Nav:OnConfirm()
    if not self:IsActive() then return false end
    if Nav_GetCurrentTab() ~= "BAGS" then
        MMNav_Log("|cffe09a15[MMNav]|r A (fase1: cursor ainda trata)")
        return false
    end
    Nav_EnsureFocus()
    local f = self.focus
    if f.zone == "TABBAR" then
        local tabs = Nav_GetTabButtons()
        local MM = Nav_GetMM()
        if tabs and tabs[f.tabIdx] then
            local btn = tabs[f.tabIdx]
            if btn then pcall(function() btn:Click() end) end
            return true
        end
        if MM and type(MM.SelectTab) == "function" then return true end
        return true
    end
    if f.zone == "EQUIP" then
        local eq = Nav_GetEquipButtons()
        if eq and eq[f.equipIndex] then
            pcall(function() eq[f.equipIndex]:Click("LeftButton") end)
        end
        return true
    end
    if f.zone == "CATS" then
        local cats = Nav_GetCatButtons()
        if cats and cats[f.catIndex] then
            pcall(function() cats[f.catIndex]:Click() end)
            self.focus.catIndex = Nav_FindCatIndexForCurrent() or self.focus.catIndex
            Nav_ApplyFocus()
        end
        return true
    end
    if f.zone == "GRID" then
        local grid = Nav_GetGrid()
        if grid and grid.slots and grid.slots[f.gridIndex] then
            pcall(function() grid.slots[f.gridIndex]:Click("LeftButton") end)
        end
        return true
    end
    return false
end

function Nav:OnCancel()
    if not self:IsActive() then return false end
    if Nav_GetCurrentTab() ~= "BAGS" then
        MMNav_Log("|cffe09a15[MMNav]|r B (fase1: cursor ainda trata)")
        return false
    end
    Nav_EnsureFocus()
    local f = self.focus
    if f.zone == "GRID" then
        f.zone = "CATS"
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        MMNav_PlayMove()
        return true
    end
    if f.zone == "CATS" then
        f.zone = "EQUIP"
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        MMNav_PlayMove()
        return true
    end
    return false
end

function Nav:OnUse()
    if not self:IsActive() then return false end
    if Nav_GetCurrentTab() ~= "BAGS" then
        MMNav_Log("|cffe09a15[MMNav]|r Y (fase1: cursor ainda trata)")
        return false
    end
    Nav_EnsureFocus()
    local f = self.focus
    if f.zone == "EQUIP" then
        local eq = Nav_GetEquipButtons()
        if eq and eq[f.equipIndex] then
            pcall(function() eq[f.equipIndex]:Click("RightButton") end)
        end
        return true
    end
    if f.zone == "GRID" then
        local grid = Nav_GetGrid()
        if grid and grid.slots and grid.slots[f.gridIndex] then
            pcall(function() grid.slots[f.gridIndex]:Click("RightButton") end)
        end
        return true
    end
    return false
end

function Nav:OnSecondary()
    if not self:IsActive() then return false end
    MMNav_Log("|cffe09a15[MMNav]|r X (fase2 BAGS: sem acao)")
    return false
end

function Nav:OnNextTab()
    MMNav_Log("|cffe09a15[MMNav]|r RB (fase2: cursor ainda trata)")
    return false
end

function Nav:OnPrevTab()
    MMNav_Log("|cffe09a15[MMNav]|r LB (fase2: cursor ainda trata)")
    return false
end

function Nav:OnNextSubTab()
    MMNav_Log("|cffe09a15[MMNav]|r RT (fase2: cursor ainda trata)")
    return false
end

function Nav:OnPrevSubTab()
    MMNav_Log("|cffe09a15[MMNav]|r LT (fase2: cursor ainda trata)")
    return false
end

function Nav:OnSmartTab()
    MMNav_Log("|cffe09a15[MMNav]|r TAB (fase2: cursor ainda trata)")
    return false
end

-- Sincroniza tabIdx com a aba aberta (chamado ao abrir/trocar de aba).
function Nav:SyncTab()
    local cur = Nav_GetCurrentTab()
    local tabs = Nav_GetTabButtons()
    if cur and tabs then
        local n = table.getn(tabs)
        for i = 1, n do
            local btn = tabs[i]
            if btn and btn.tabData and btn.tabData.id == cur then
                self.focus.tabIdx = i
                break
            end
        end
    end
end

-- Inicializacao vazia e segura: so garante defaults, sem eventos, sem
-- tocar em Cursor/Hooks/Keybindings.
function Nav:Initialize()
    self.navState = self.navState or { direction = nil, timer = 0, initialDelay = 0.35, interval = 0.12 }
    if self.navState.initialDelay == nil then self.navState.initialDelay = 0.35 end
    if self.navState.interval == nil then self.navState.interval = 0.12 end
    if self.navState.timer == nil then self.navState.timer = 0 end
    if self.ticker == nil then self.ticker = nil end
    self.focus = self.focus or { zone = "GRID", tabIdx = 1, equipIndex = 1, catIndex = nil, gridIndex = 1, returnZone = "GRID" }
end
