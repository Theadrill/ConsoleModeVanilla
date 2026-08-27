--[[
    ConsoleMode - Vanilla
    Cursor.lua
]]

_G = getfenv(0)

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Cursor.lua]|r Iniciando carregamento...")

ConsoleMode.cursor = ConsoleMode.cursor or {}
local Cursor = ConsoleMode.cursor

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Cursor.lua]|r Namespace criado!")

Cursor.state = {
    enabled = false,
    currentButton = nil,
    currentFrame = nil,
    activeFrames = {},
    allButtons = {},
    closest = { up = nil, down = nil, left = nil, right = nil },
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
    if not button then 
        self:Hide()
        return 
    end
    
    local x, y = button:GetCenter()
    if not x or not y then 
        self:Hide()
        return 
    end

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
    if self.state.currentButton then 
        self:UpdatePosition(self.state.currentButton) 
    end
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
    self.state.currentFrame = nil
    self.state.allButtons = {}
    self.state.closest = { up = nil, down = nil, left = nil, right = nil }
    self:Hide()
end

function Cursor:IsInteractive(frame)
    if not frame then return false end
    if not frame:IsVisible() then return false end
    
    local ftype = frame:GetObjectType()
    
    if ftype == "Button" then
        if frame.IsEnabled then
            return frame:IsEnabled()
        end
        return true
    end
    
    if ftype == "CheckButton" then
        if frame.IsEnabled then
            return frame:IsEnabled()
        end
        return true
    end
    
    if ftype == "EditBox" then
        return true
    end
    
    if ftype == "Slider" then
        return true
    end
    
    -- ✅ CRÍTICO: Usar pcall para evitar erro se frame não suporta scripts
    local hasOnClick = false
    local hasOnMouseDown = false
    
    local success, result = pcall(function() return frame:GetScript("OnClick") end)
    if success and result then
        hasOnClick = true
    end
    
    success, result = pcall(function() return frame:GetScript("OnMouseDown") end)
    if success and result then
        hasOnMouseDown = true
    end
    
    if hasOnClick or hasOnMouseDown then
        return true
    end
    
    return false
end

local ignorePatterns = {
    "MoneyFrameGoldButton",
    "MoneyFrameSilverButton",
    "MoneyFrameCopperButton",
    "DropDownList%d+Button",
}

function Cursor:ShouldIgnore(frame)
    local name = frame:GetName()
    if not name then return false end
    
    for _, pattern in ipairs(ignorePatterns) do
        if string.find(name, pattern) then
            return true
        end
    end
    
    return false
end

function Cursor:FindFirstVisibleButton(frame)
    if not frame or not frame:IsVisible() then
        return nil
    end
    
    if self:IsInteractive(frame) and not self:ShouldIgnore(frame) then
        return frame
    end
    
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        local found = self:FindFirstVisibleButton(child)
        if found then return found end
    end
    
    return nil
end

function Cursor:CollectButtons(frame, result)
    result = result or {}
    if not frame or not frame:IsVisible() then return result end
    
    if self:IsInteractive(frame) and not self:ShouldIgnore(frame) then
        table.insert(result, frame)
    end
    
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        self:CollectButtons(child, result)
    end
    
    return result
end

function Cursor:FindClosest(current, allButtons)
    local closest = { up = nil, down = nil, left = nil, right = nil }
    local dist = { up = math.huge, down = math.huge, left = math.huge, right = math.huge }
    
    if not current then return closest end
    
    local cx, cy = current:GetCenter()
    if not cx or not cy then return closest end

    for _, btn in ipairs(allButtons) do
        if btn ~= current and btn:IsVisible() then
            local bx, by = btn:GetCenter()
            if bx and by then
                local dx = bx - cx
                local dy = by - cy
                local d = math.sqrt(dx * dx + dy * dy)
                
                if d > 0 then
                    local adx = math.abs(dx)
                    local ady = math.abs(dy)
                    
                    if dy > 0 and ady >= adx and d < dist.up then
                        dist.up = d
                        closest.up = btn
                    end
                    
                    if dy < 0 and ady >= adx and d < dist.down then
                        dist.down = d
                        closest.down = btn
                    end
                    
                    if dx > 0 and adx >= ady and d < dist.right then
                        dist.right = d
                        closest.right = btn
                    end
                    
                    if dx < 0 and adx >= ady and d < dist.left then
                        dist.left = d
                        closest.left = btn
                    end
                end
            end
        end
    end
    
    return closest
end

function Cursor:UpdateState()
    local allButtons = {}
    
    for frame, _ in pairs(self.state.activeFrames) do
        if frame:IsVisible() then 
            self:CollectButtons(frame, allButtons) 
        end
    end
    
    self.state.allButtons = allButtons
    self.state.closest = self:FindClosest(self.state.currentButton, allButtons)
end

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Cursor.lua]|r Carregado completamente!")
