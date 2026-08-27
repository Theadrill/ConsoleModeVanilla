--[[
    ConsoleMode - Vanilla
    Cursor.lua
    
    Implementação de cursor virtual para navegação de interface via controle.
    Compatível com Lua 5.0 (WoW 1.12 / Turtle WoW).
]]

_G = getfenv(0)

ConsoleMode.cursor = ConsoleMode.cursor or {}
local Cursor = ConsoleMode.cursor

Cursor.state = {
    enabled = false,
    currentButton = nil,
    currentFrame = nil,
    activeFrames = {},
    allButtons = {},
    closest = { up = nil, down = nil, left = nil, right = nil },
    distances = { up = 999999, down = 999999, left = 999999, right = 999999 },
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

-- ============================================================================
-- POSICIONAMENTO E VISIBILIDADE
-- ============================================================================

function Cursor:EnsureOnTop(frame)
    if frame then
        local frameName = frame:GetName()
        if frameName == "WorldMapFrame" then
            cursorFrame:SetParent(frame)
            highlightFrame:SetParent(frame)
            cursorFrame:SetFrameStrata("TOOLTIP")
            cursorFrame:SetFrameLevel(1001)
            highlightFrame:SetFrameStrata("TOOLTIP")
            highlightFrame:SetFrameLevel(1000)
            return
        end
    end

    cursorFrame:SetParent(UIParent)
    highlightFrame:SetParent(UIParent)
    cursorFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    cursorFrame:SetFrameLevel(1001)
    highlightFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    highlightFrame:SetFrameLevel(1000)
end

function Cursor:UpdatePosition(button)
    if not button then 
        self:Hide()
        return 
    end
    
    if not button.GetCenter then
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

    local w = button:GetWidth() or 32
    local h = button:GetHeight() or 32
    highlightFrame:ClearAllPoints()
    highlightFrame:SetPoint("CENTER", button, "CENTER", 0, 0)
    highlightFrame:SetWidth(w + 10)
    highlightFrame:SetHeight(h + 10)
    highlightFrame:Show()
end

function Cursor:FindParentScrollFrame(button)
    if not button then return nil end
    local parent = button:GetParent()
    local depth = 0
    while parent and depth < 20 do
        local parentName = parent:GetName() or ""
        if string.find(parentName, "ScrollChild") then
            local sName = string.gsub(parentName, "ScrollChild", "ScrollFrame")
            local sf = getglobal(sName)
            if sf then return sf end
        end
        if string.find(parentName, "ScrollFrame") and parent.GetVerticalScroll then
            return parent
        end
        parent = parent:GetParent()
        depth = depth + 1
    end
    return nil
end

function Cursor:ScrollToShowButton(button)
    if not button then return end
    local scrollFrame = self:FindParentScrollFrame(button)
    if not scrollFrame then return end
    
    local scrollBarName = scrollFrame:GetName() and (scrollFrame:GetName() .. "ScrollBar")
    local scrollBar = scrollBarName and getglobal(scrollBarName)
    if not scrollBar or not scrollBar.GetValue or not scrollBar.SetValue then return end
    
    local sfBottom = scrollFrame:GetBottom()
    local sfTop = scrollFrame:GetTop()
    local btnBottom = button:GetBottom()
    local btnTop = button:GetTop()
    
    if not sfBottom or not sfTop or not btnBottom or not btnTop then return end
    
    local currentScroll = scrollBar:GetValue()
    local minScroll, maxScroll = scrollBar:GetMinMaxValues()
    
    if btnBottom < sfBottom then
        local needed = sfBottom - btnBottom + 10
        local newScroll = currentScroll + needed
        if newScroll > maxScroll then newScroll = maxScroll end
        scrollBar:SetValue(newScroll)
    elseif btnTop > sfTop then
        local needed = btnTop - sfTop + 10
        local newScroll = currentScroll - needed
        if newScroll < minScroll then newScroll = minScroll end
        scrollBar:SetValue(newScroll)
    end
end

function Cursor:MoveTo(button)
    if not button then return end
    
    local prevButton = self.state.currentButton
    if prevButton and prevButton ~= button then
        local onLeave = prevButton.GetScript and prevButton:GetScript("OnLeave")
        if onLeave then
            pcall(function()
                this = prevButton
                onLeave()
            end)
        end
        if GameTooltip then GameTooltip:Hide() end
    end
    
    self.state.currentButton = button
    self.state.currentFrame = button.GetParent and button:GetParent() or nil
    
    self:ScrollToShowButton(button)
    self:UpdatePosition(button)
    
    local onEnter = button.GetScript and button:GetScript("OnEnter")
    if onEnter then
        pcall(function()
            this = button
            onEnter()
        end)
    end
    
    self:UpdateState()
end

function Cursor:Show()
    if self.state.currentButton then 
        self:UpdatePosition(self.state.currentButton) 
    end
end

function Cursor:Hide()
    cursorFrame:Hide()
    highlightFrame:Hide()
    if GameTooltip then GameTooltip:Hide() end
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
    self.state.distances = { up = 999999, down = 999999, left = 999999, right = 999999 }
    self:Hide()
end

-- ============================================================================
-- DETECÇÃO DE ELEMENTOS INTERATIVOS
-- ============================================================================

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
    
    local fname = frame:GetName() or ""
    
    -- Para SUCC_bag / SUCC_bagBank (Turtle-Dragonflight): preferir primeiro slot de item
    if fname == "SUCC_bag" or fname == "SUCC_bagBank" then
        local firstItem = getglobal(fname .. "Item1")
        if firstItem and firstItem:IsVisible() then
            return firstItem
        end
    end
    
    -- Para bolsas normais da Blizzard: preferir primeiro item
    if string.find(fname, "ContainerFrame%d+") then
        local firstItem = getglobal(fname .. "Item1")
        if firstItem and firstItem:IsVisible() then
            return firstItem
        end
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
    
    local fname = frame:GetName() or ""
    
    -- Para SUCC_bag / SUCC_bagBank (Turtle-Dragonflight): coletar slots e botoes especiais
    if fname == "SUCC_bag" or fname == "SUCC_bagBank" then
        local size = frame.size or 140
        for i = 1, size do
            local item = getglobal(fname .. "Item" .. i)
            if item and item:IsVisible() then
                table.insert(result, item)
            end
        end
        if frame.closeButton and frame.closeButton:IsVisible() then
            table.insert(result, frame.closeButton)
        end
        if frame.toggleButton and frame.toggleButton:IsVisible() then
            table.insert(result, frame.toggleButton)
        end
        if frame.keyringButton and frame.keyringButton:IsVisible() then
            table.insert(result, frame.keyringButton)
        end
        return result
    end
    
    if self:IsInteractive(frame) and not self:ShouldIgnore(frame) then
        table.insert(result, frame)
    end
    
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        self:CollectButtons(child, result)
    end
    
    return result
end

-- ============================================================================
-- NAVEGAÇÃO E DIREÇÃO (LUA 5.0 COMPATÍVEL - SEM MATH.HUGE)
-- ============================================================================

function Cursor:FindBestInDirection(current, direction, allButtons)
    if not current or not current.GetCenter then return nil end
    
    local currentX, currentY = current:GetCenter()
    if not currentX or not currentY then return nil end
    
    local bestButton = nil
    local bestScore = 999999
    direction = string.upper(direction or "")
    
    for _, btn in ipairs(allButtons) do
        if btn ~= current and btn:IsVisible() and btn.GetCenter then
            local bx, by = btn:GetCenter()
            if bx and by then
                local dx = bx - currentX
                local dy = by - currentY
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist > 0 then
                    local isValid = false
                    local score = 999999
                    
                    if direction == "UP" and dy > 2 then
                        isValid = true
                        -- Penaliza desvios horizontais
                        score = dist + (math.abs(dx) * 2.0)
                    elseif direction == "DOWN" and dy < -2 then
                        isValid = true
                        -- Penaliza desvios horizontais
                        score = dist + (math.abs(dx) * 2.0)
                    elseif direction == "LEFT" and dx < -2 then
                        isValid = true
                        -- Penaliza desvios verticais
                        score = dist + (math.abs(dy) * 2.0)
                    elseif direction == "RIGHT" and dx > 2 then
                        isValid = true
                        -- Penaliza desvios verticais
                        score = dist + (math.abs(dy) * 2.0)
                    end
                    
                    if isValid and score < bestScore then
                        bestScore = score
                        bestButton = btn
                    end
                end
            end
        end
    end
    
    return bestButton
end

function Cursor:FindClosest(current, allButtons)
    local closest = {
        up = self:FindBestInDirection(current, "UP", allButtons),
        down = self:FindBestInDirection(current, "DOWN", allButtons),
        left = self:FindBestInDirection(current, "LEFT", allButtons),
        right = self:FindBestInDirection(current, "RIGHT", allButtons),
    }
    local minDistances = { up = 0, down = 0, left = 0, right = 0 }
    return closest, minDistances
end

function Cursor:UpdateState()
    local allButtons = {}
    
    for frame, _ in pairs(self.state.activeFrames) do
        if frame and frame:IsVisible() then 
            self:CollectButtons(frame, allButtons) 
        end
    end
    
    self.state.allButtons = allButtons
    self.state.closest, self.state.distances = self:FindClosest(self.state.currentButton, allButtons)
end

function Cursor:MoveDirection(direction)
    if not self.state.enabled then 
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Cursor]|r Navegacao inativa (nenhuma janela ativa no cursor)")
        return 
    end
    
    local currentButton = self.state.currentButton
    if not currentButton then 
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Cursor]|r Nenhum botao selecionado atualmente")
        return 
    end
    
    self:UpdateState()
    
    direction = string.upper(direction or "")
    local targetButton = self:FindBestInDirection(currentButton, direction, self.state.allButtons)
    
    -- Fallback: Se nao encontrou botao direto na direcao, tenta wrapping para o lado oposto
    if not targetButton then
        local opposite = (direction == "UP" and "DOWN") or 
                         (direction == "DOWN" and "UP") or 
                         (direction == "LEFT" and "RIGHT") or 
                         (direction == "RIGHT" and "LEFT")
                         
        local currentX, currentY = currentButton:GetCenter()
        if currentX and currentY and self.state.allButtons then
            local maxDist = 0
            for _, btn in ipairs(self.state.allButtons) do
                if btn ~= currentButton and btn:IsVisible() and btn.GetCenter then
                    local bx, by = btn:GetCenter()
                    if bx and by then
                        local dx = bx - currentX
                        local dy = by - currentY
                        
                        if (direction == "LEFT" or direction == "RIGHT") and math.abs(dy) < 50 then
                            if direction == "LEFT" and dx > maxDist then
                                maxDist = dx
                                targetButton = btn
                            elseif direction == "RIGHT" and (-dx) > maxDist then
                                maxDist = -dx
                                targetButton = btn
                            end
                        elseif (direction == "UP" or direction == "DOWN") and math.abs(dx) < 50 then
                            if direction == "UP" and (-dy) > maxDist then
                                maxDist = -dy
                                targetButton = btn
                            elseif direction == "DOWN" and dy > maxDist then
                                maxDist = dy
                                targetButton = btn
                            end
                        end
                    end
                end
            end
        end
    end
    
    if targetButton then
        local fromName = currentButton:GetName() or "unnamed"
        local toName = targetButton:GetName() or "unnamed"
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Move]|r " .. direction .. ": " .. fromName .. " -> " .. toName)
        self:MoveTo(targetButton)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[CM Move]|r Nenhum botao para: " .. direction .. " (total na tela: " .. table.getn(self.state.allButtons) .. ")")
    end
end

-- ============================================================================
-- INTERAÇÃO E CLIQUES
-- ============================================================================

function Cursor:Click(mouseButton)
    mouseButton = mouseButton or "LeftButton"
    local button = self.state.currentButton
    if not button or not button:IsVisible() then return end
    
    local bname = button:GetName() or ""
    
    -- EditBox: foca para escrita
    if button:IsObjectType("EditBox") then
        button:SetFocus()
        return
    end
    
    -- Slider: altera valor
    if button:IsObjectType("Slider") then
        local minVal, maxVal = button:GetMinMaxValues()
        local cur = button:GetValue()
        local step = button:GetValueStep() or ((maxVal - minVal) / 10)
        if mouseButton == "LeftButton" then
            button:SetValue(cur + step)
        else
            button:SetValue(cur - step)
        end
        return
    end
    
    -- Bolsas e Inventario (Blizzard, pfUI, Bagshui, Bagnon, Turtle-Dragonflight SUCC_bag)
    local isSUCCBag = string.find(bname, "SUCC_bagItem%d+") or string.find(bname, "SUCC_bagBankItem%d+")
    local isBagItem = string.find(bname, "ContainerFrame%d+Item%d+") or 
                      string.find(bname, "pfBag%-?%d+item%d+") or 
                      string.find(bname, "BagshuiBagsItem%d+") or 
                      string.find(bname, "BagshuiBankItem%d+") or 
                      string.find(bname, "BagnonItem%d+") or
                      isSUCCBag
                      
    if isBagItem then
        local bagID, slotID = nil, nil
        
        if isSUCCBag then
            local parent = button:GetParent()
            if parent and parent.GetID then
                bagID = parent:GetID()
                slotID = button:GetID()
            end
        else
            local _, _, cFrameNum = string.find(bname, "ContainerFrame(%d+)")
            if cFrameNum then
                bagID = tonumber(cFrameNum) - 1
                slotID = button:GetID()
            end
        end
        
        if bagID and slotID then
            if mouseButton == "RightButton" then
                -- Usar item diretamente
                UseContainerItem(bagID, slotID)
                self:UpdateState()
                return
            elseif mouseButton == "LeftButton" then
                -- Se ja tem item na mão, colocar/trocar
                if CursorHasItem() or CursorHasSpell() then
                    PickupContainerItem(bagID, slotID)
                elseif button.Click then
                    button:Click(mouseButton)
                else
                    PickupContainerItem(bagID, slotID)
                end
                self:UpdateState()
                return
            end
        end
    end
    
    -- Equipamento do personagem: botao direito desequipa para a bolsa
    if mouseButton == "RightButton" and string.find(bname, "Character[A-Za-z0-9]+Slot") then
        local slotId = button:GetID()
        if slotId then
            PickupInventoryItem(slotId)
            PutItemInBackpack()
            if CursorHasItem() then ClearCursor() end
            self:UpdateState()
            return
        end
    end
    
    -- Clique normal
    if button.Click then
        button:Click(mouseButton)
    elseif button.GetScript then
        local script = button:GetScript("OnClick") or button:GetScript("OnMouseDown")
        if script then
            pcall(function()
                this = button
                arg1 = mouseButton
                script()
            end)
        end
    end
    
    self:UpdateState()
end
