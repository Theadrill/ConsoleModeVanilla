--[[
    ConsoleMode - Vanilla
    Cursor.lua
]]

_G = getfenv(0)

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Cursor.lua]|r Iniciando carregamento do modulo Cursor...")

if not ConsoleMode then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Cursor.lua]|r ERRO: ConsoleMode nao existe!")
    return
end

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Cursor.lua]|r ConsoleMode existe, criando namespace...")

ConsoleMode.cursor = ConsoleMode.cursor or {}
local Cursor = ConsoleMode.cursor

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Cursor.lua]|r Namespace criado com sucesso!")

Cursor.state = {
    enabled       = false,
    currentButton = nil,
    currentFrame  = nil,
    activeFrames  = {},
    allButtons    = {},
    closest       = { up = nil, down = nil, left = nil, right = nil },
}

-- Frame do Ponteiro
local cursorFrame = CreateFrame("Frame", "ConsoleModeCursorFrame", UIParent)
cursorFrame:SetWidth(32)
cursorFrame:SetHeight(32)
cursorFrame:SetFrameStrata("FULLSCREEN_DIALOG")
cursorFrame:SetFrameLevel(1001)
cursorFrame:Hide()

local cursorTexture = cursorFrame:CreateTexture(nil, "OVERLAY")
cursorTexture:SetTexture("Interface\\CURSOR\\Point")
cursorTexture:SetAllPoints(cursorFrame)
Cursor.frame = cursorFrame

-- Frame do Highlight
local highlightFrame = CreateFrame("Frame", "ConsoleModeCursorHighlight", UIParent)
highlightFrame:SetFrameStrata("FULLSCREEN_DIALOG")
highlightFrame:SetFrameLevel(1000)
highlightFrame:Hide()

local highlightTexture = highlightFrame:CreateTexture(nil, "OVERLAY")
highlightTexture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
highlightTexture:SetBlendMode("ADD")
highlightTexture:SetAllPoints(highlightFrame)
highlightTexture:SetVertexColor(1, 1, 0, 0.7)
Cursor.highlight = highlightFrame

function Cursor:UpdatePosition(button)
    if not button then self:Hide(); return end
    local x, y = button:GetCenter()
    if not x or not y then self:Hide(); return end

    cursorFrame:ClearAllPoints()
    cursorFrame:SetPoint("CENTER", button, "BOTTOM", 8, 0)
    cursorFrame:Show()

    local w = button:GetWidth()
    local h = button:GetHeight()
    highlightFrame:ClearAllPoints()
    highlightFrame:SetPoint("CENTER", button, "CENTER", 0, 0)
    highlightFrame:SetWidth(w + 10)
    highlightFrame:SetHeight(h + 10)
    highlightFrame:Show()
end

function Cursor:MoveTo(button)
    if not button then return end
    if button == self.state.currentButton then return end
    self.state.currentButton = button
    self:UpdatePosition(button)
end

function Cursor:Show()
    if self.state.currentButton then self:UpdatePosition(self.state.currentButton) end
end

function Cursor:Hide()
    cursorFrame:Hide()
    highlightFrame:Hide()
end

function Cursor:Enable()
    self.state.enabled = true
end

function Cursor:Disable()
    self.state.enabled = false
    self.state.currentButton = nil
    self.state.currentFrame  = nil
    self.state.allButtons    = {}
    self.state.closest       = { up = nil, down = nil, left = nil, right = nil }
    self:Hide()
end

function Cursor:IsInteractive(frame)
    if not frame then 
        return false 
    end
    
    if not frame:IsVisible() then 
        return false 
    end
    
    local ftype = frame:GetObjectType()
    local frameName = frame:GetName() or "unnamed"
    
    -- ✅ BOTÕES: Aceita se for Button E estiver visível
    if ftype == "Button" then
        -- Se tem IsEnabled, verifica se está habilitado
        if frame.IsEnabled then
            local enabled = frame:IsEnabled()
            if ConsoleMode.debug then
                DEFAULT_CHAT_FRAME:AddMessage("    |cff88ccff[IsInteractive]|r " .. frameName .. " is Button, IsEnabled=" .. tostring(enabled))
            end
            return enabled
        end
        -- Se não tem IsEnabled, aceita se estiver visível (muitos botões no 1.12 não têm IsEnabled)
        if ConsoleMode.debug then
            DEFAULT_CHAT_FRAME:AddMessage("    |cff88ccff[IsInteractive]|r " .. frameName .. " is Button (no IsEnabled), accepting")
        end
        return true
    end
    
    -- ✅ CHECKBUTTONS: Sempre aceita (RadioButton, CheckBox)
    if ftype == "CheckButton" then
        if frame.IsEnabled then
            local enabled = frame:IsEnabled()
            if ConsoleMode.debug then
                DEFAULT_CHAT_FRAME:AddMessage("    |cff88ccff[IsInteractive]|r " .. frameName .. " is CheckButton, IsEnabled=" .. tostring(enabled))
            end
            return enabled
        end
        if ConsoleMode.debug then
            DEFAULT_CHAT_FRAME:AddMessage("    |cff88ccff[IsInteractive]|r " .. frameName .. " is CheckButton (no IsEnabled), accepting")
        end
        return true
    end
    
    -- ✅ EDITBOX: Sempre aceita (caixas de texto)
    if ftype == "EditBox" then
        if ConsoleMode.debug then
            DEFAULT_CHAT_FRAME:AddMessage("    |cff88ccff[IsInteractive]|r " .. frameName .. " is EditBox, accepting")
        end
        return true
    end
    
    -- ✅ SLIDER: Sempre aceita (barras de ajuste)
    if ftype == "Slider" then
        if ConsoleMode.debug then
            DEFAULT_CHAT_FRAME:AddMessage("    |cff88ccff[IsInteractive]|r " .. frameName .. " is Slider, accepting")
        end
        return true
    end
    
    -- ✅ FRAMES COM SCRIPTS: Se tem OnClick ou OnMouseDown, é interativo
    local hasOnClick = frame:GetScript("OnClick") ~= nil
    local hasOnMouseDown = frame:GetScript("OnMouseDown") ~= nil
    
    if hasOnClick or hasOnMouseDown then
        if ConsoleMode.debug then
            DEFAULT_CHAT_FRAME:AddMessage("    |cff88ccff[IsInteractive]|r " .. frameName .. " has scripts (OnClick=" .. tostring(hasOnClick) .. ", OnMouseDown=" .. tostring(hasOnMouseDown) .. "), accepting")
        end
        return true
    end
    
    return false
end

-- Lista de padrões de nomes de frames que devem ser ignorados
local ignorePatterns = {
    "MoneyFrameGoldButton",
    "MoneyFrameSilverButton", 
    "MoneyFrameCopperButton",
    "DropDownList%d+Button",
}

function Cursor:ShouldIgnore(frame)
    local name = frame:GetName()
    if not name then return false end
    
    -- Verifica cada padrão
    for _, pattern in ipairs(ignorePatterns) do
        if string.find(name, pattern) then
            return true
        end
    end
    
    return false
end

function Cursor:FindFirstVisibleButton(frame, depth)
    depth = depth or 0
    local indent = string.rep("  ", depth)
    
    if not frame then 
        if ConsoleMode.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM FindFirst]|r frame is nil")
        end
        return nil 
    end
    
    if not frame:IsVisible() then 
        if ConsoleMode.debug then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM FindFirst]|r frame not visible: " .. (frame:GetName() or "unnamed"))
        end
        return nil 
    end
    
    local frameName = frame:GetName() or "unnamed"
    local frameType = frame:GetObjectType() or "unknown"
    
    if ConsoleMode.debug then
        DEFAULT_CHAT_FRAME:AddMessage(indent .. "|cff888888[CM FindFirst]|r Checking: " .. frameName .. " (type: " .. frameType .. ")")
    end
    
    -- Verifica se este frame é interativo
    local isInteractive = self:IsInteractive(frame)
    local shouldIgnore = self:ShouldIgnore(frame)
    
    if ConsoleMode.debug then
        DEFAULT_CHAT_FRAME:AddMessage(indent .. "  Interactive: " .. (isInteractive and "|cff00ff00YES|r" or "|cffff4444NO|r") .. 
                                               ", Ignore: " .. (shouldIgnore and "|cffffcc00YES|r" or "|cff00ff00NO|r"))
    end
    
    if isInteractive and not shouldIgnore then
        if ConsoleMode.debug then
            DEFAULT_CHAT_FRAME:AddMessage(indent .. "|cff00ff00[CM FindFirst]|r FOUND: " .. frameName)
        end
        return frame
    end
    
    -- Busca recursivamente nos filhos
    local children = { frame:GetChildren() }
    if ConsoleMode.debug then
        DEFAULT_CHAT_FRAME:AddMessage(indent .. "  Children count: " .. table.getn(children))
    end
    
    for i, child in ipairs(children) do
        local found = self:FindFirstVisibleButton(child, depth + 1)
        if found then return found end
    end
    
    return nil
end

function Cursor:CollectButtons(frame, result)
    if not frame or not frame:IsVisible() then return end
    result = result or {}
    if self:IsInteractive(frame) and not self:ShouldIgnore(frame) then
        result[#result + 1] = frame
    end
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        self:CollectButtons(child, result)
    end
    return result
end

function Cursor:FindClosest(current, allButtons)
    local closest = { up = nil, down = nil, left = nil, right = nil }
    local dist    = { up = math.huge, down = math.huge, left = math.huge, right = math.huge }
    if not current then return closest end
    local cx, cy = current:GetCenter()
    if not cx or not cy then return closest end

    for _, btn in ipairs(allButtons) do
        if btn ~= current and btn:IsVisible() then
            local bx, by = btn:GetCenter()
            if bx and by then
                local dx = bx - cx
                local dy = by - cy
                local d  = math.sqrt(dx*dx + dy*dy)
                if d > 0 then
                    local adx = math.abs(dx)
                    local ady = math.abs(dy)
                    if dy > 0 and ady >= adx and d < dist.up then dist.up = d; closest.up = btn end
                    if dy < 0 and ady >= adx and d < dist.down then dist.down = d; closest.down = btn end
                    if dx > 0 and adx >= ady and d < dist.right then dist.right = d; closest.right = btn end
                    if dx < 0 and adx >= ady and d < dist.left then dist.left = d; closest.left = btn end
                end
            end
        end
    end
    return closest
end

function Cursor:UpdateState()
    local allButtons = {}
    for frame, _ in pairs(self.state.activeFrames) do
        if frame:IsVisible() then self:CollectButtons(frame, allButtons) end
    end
    self.state.allButtons = allButtons
    self.state.closest    = self:FindClosest(self.state.currentButton, allButtons)
end

-- ✅ Log de conclusão do carregamento
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Cursor.lua]|r ✓ Modulo Cursor carregado completamente!")


-- ✅ Log de conclusão do carregamento
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Cursor.lua]|r ✓ Modulo Cursor carregado completamente!")
