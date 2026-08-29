--[[
    ConsoleMode - Vanilla
    Hooks.lua
    
    Sistema de hooks para janelas do WoW 1.12
    Detecta abertura/fechamento de frames e inicializa navegação por cursor
]]

_G = getfenv(0)

ConsoleMode.hooks = ConsoleMode.hooks or {}
local Hooks = ConsoleMode.hooks

Hooks.initialized = false
Hooks.eventFrame = nil

-- Lista completa de frames para hookar
Hooks.frames = {
    -- Menu e Sistema
    { frame = "GameMenuFrame",               name = "Menu Principal" },
    { frame = "ConsoleModeSettingsFrame",    name = "ConsoleMode Configuracoes" },
    { frame = "OptionsFrame",                name = "Opcoes do Jogo" },
    { frame = "VideoOptionsFrame",           name = "Opcoes de Video" },
    { frame = "SoundOptionsFrame",           name = "Opcoes de Audio" },
    { frame = "UIOptionsFrame",              name = "Opcoes de Interface" },
    { frame = "KeyBindingFrame",             name = "Atalhos" },
    { frame = "HelpFrame",                   name = "Ajuda" },
    { frame = "CinematicFrame",              name = "Cinematics" },
    
    -- Configurações de Addons e Turtle WoW
    { frame = "AdvancedSettingsGUI",         name = "Turtle Configuracoes Avancadas" },
    { frame = "TDF_AdvancedSettingsGUI",     name = "Turtle-Dragonflight Configuracoes" },
    { frame = "myAddOnsFrame",               name = "myAddOns" },
    { frame = "MacroFrame",                  name = "Macros" },
    { frame = "SuperMacroFrame",             name = "SuperMacro" },
    { frame = "MAOptions",                   name = "MoveAnything" },
    
    -- Personagem e Social
    { frame = "CharacterFrame",              name = "Personagem" },
    { frame = "SpellBookFrame",              name = "Livro de Feiticos" },
    { frame = "TalentFrame",                 name = "Talentos" },
    { frame = "FriendsFrame",                name = "Amigos" },
    { frame = "DressUpFrame",                name = "Provador" },
    { frame = "InspectFrame",                name = "Inspecionar" },
    { frame = "ReadyCheckFrame",             name = "Ready Check" },
    
    -- Missões
    { frame = "QuestLogFrame",       name = "Diario de Missoes" },
    { frame = "QuestFrame",          name = "Missao" },
    { frame = "GossipFrame",         name = "Dialogo NPC" },
    
    -- Popups e Diálogos
    { frame = "ConsoleModeContextMenu", name = "Menu de Contexto Bolsa" },
    { frame = "StaticPopup1",        name = "Dialogo 1" },
    { frame = "StaticPopup2",        name = "Dialogo 2" },
    { frame = "StaticPopup3",        name = "Dialogo 3" },
    { frame = "StaticPopup4",        name = "Dialogo 4" },
    
    -- Inventário Padrão Blizzard
    { frame = "ContainerFrame1",     name = "Bolsa 1" },
    { frame = "ContainerFrame2",     name = "Bolsa 2" },
    { frame = "ContainerFrame3",     name = "Bolsa 3" },
    { frame = "ContainerFrame4",     name = "Bolsa 4" },
    { frame = "ContainerFrame5",     name = "Bolsa 5" },
    { frame = "ContainerFrame6",     name = "Bolsa Banco 1" },
    { frame = "ContainerFrame7",     name = "Bolsa Banco 2" },
    { frame = "ContainerFrame8",     name = "Bolsa Banco 3" },
    { frame = "ContainerFrame9",     name = "Bolsa Banco 4" },
    { frame = "ContainerFrame10",    name = "Bolsa Banco 5" },
    { frame = "ContainerFrame11",    name = "Bolsa Banco 6" },
    { frame = "ContainerFrame12",    name = "Bolsa Banco 7" },
    
    -- Addons de Bolsas Populares
    { frame = "SUCC_bag",            name = "Turtle-Dragonflight Bolsa" },
    { frame = "SUCC_bagBank",        name = "Turtle-Dragonflight Banco" },
    { frame = "pfBag",               name = "pfUI Bolsa" },
    { frame = "pfBank",              name = "pfUI Banco" },
    { frame = "BagshuiBagsFrame",    name = "Bagshui Bolsa" },
    { frame = "BagshuiBankFrame",    name = "Bagshui Banco" },
    { frame = "Bagnon",              name = "Bagnon Bolsa" },
    { frame = "BagnonBank",          name = "Bagnon Banco" },
    
    -- NPCs e Interações (Load-on-Demand)
    { frame = "MerchantFrame",       name = "Vendedor" },
    { frame = "TradeSkillFrame",     name = "Profissao" },
    { frame = "BankFrame",           name = "Banco" },
    { frame = "TaxiFrame",           name = "Rotas de Voo" },
    { frame = "ClassTrainerFrame",   name = "Treinador" },
    { frame = "AuctionFrame",        name = "Casa de Leiloes" },
    
    -- Correio e Loot
    { frame = "MailFrame",           name = "Correio" },
    { frame = "OpenMailFrame",       name = "Carta Aberta" },
    { frame = "LootFrame",           name = "Loot" },
    
    -- Comércio
    { frame = "TradeFrame",          name = "Troca" },
}

-- ============================================================================
-- FUNÇÕES DE HOOK DE FRAMES
-- ============================================================================

function Hooks:HookFrame(frame, name)
    if not frame then return false end
    if frame.cmHooked then return false end
    if not frame.GetScript or not frame.SetScript then return false end

    local frameName = frame:GetName() or "Unknown"
    
    local oldOnShow = frame:GetScript("OnShow")
    local oldOnHide = frame:GetScript("OnHide")

    frame:SetScript("OnShow", function()
        if oldOnShow then oldOnShow() end
        Hooks:OnFrameShow(this)
    end)

    frame:SetScript("OnHide", function()
        if oldOnHide then oldOnHide() end
        Hooks:OnFrameHide(this)
    end)

    frame.cmHooked = true
    
    -- ✅ CRÍTICO: Se o frame já está visível ao hookar, inicializa o cursor
    if frame:IsVisible() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[CM]|r Frame " .. frameName .. " ja esta visivel, inicializando cursor...")
        self:OnFrameShow(frame)
    end
    
    return true
end

function Hooks:OnFrameShow(frame)
    if not frame then 
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM OnFrameShow]|r frame is NIL!")
        return 
    end

    local name = frame:GetName() or "?"
    DEFAULT_CHAT_FRAME:AddMessage("|cffff6600[CM]|r JANELA ABRIU: " .. name)

    local Cursor = ConsoleMode.cursor
    if not Cursor then 
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM OnFrameShow]|r ConsoleMode.cursor is NIL!")
        return 
    end

    if Cursor.state.activeFrames[frame] then 
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[CM OnFrameShow]|r Frame " .. name .. " ja esta em activeFrames, ignorando")
        return 
    end
    
    Cursor.state.activeFrames[frame] = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM OnFrameShow]|r Frame " .. name .. " adicionado a activeFrames")

    -- Se for o GameMenuFrame, garante a injeção e alinhamento do botão
    if name == "GameMenuFrame" and Hooks.InjectGameMenuButton then
        Hooks:InjectGameMenuButton()
    end

    -- Garante que o cursor fique na camada visual correta
    if Cursor.EnsureOnTop then
        Cursor:EnsureOnTop(frame)
    end

    -- Ativa modo de navegacao no controle (D-Pad move cursor, A confirma, B cancela)
    if ConsoleMode.keybindings and ConsoleMode.keybindings.EnterNavigationMode then
        ConsoleMode.keybindings:EnterNavigationMode()
    end

    -- ✅ CRITICO: Detectar se e frame de addon de bolsa (pfUI, Bagshui, Bagnon, Turtle-Dragonflight)
    -- Esses addons criam botoes dinamicamente DEPOIS do OnShow
    local isPfUIBag = (name == "pfBag" or name == "pfBank")
    local isBagshuiBag = (name == "BagshuiBagsFrame" or name == "BagshuiBankFrame")
    local isBagnonBag = (name == "Bagnon" or name == "BagnonBank")
    local isTurtleDFBag = (name == "SUCC_bag" or name == "SUCC_bagBank")
    
    if isPfUIBag or isBagshuiBag or isBagnonBag or isTurtleDFBag then
        local addonName = isPfUIBag and "pfUI" or (isBagshuiBag and "Bagshui" or (isBagnonBag and "Bagnon" or "Turtle-Dragonflight"))
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[CM]|r Frame de " .. addonName .. " detectado, aguardando botoes...")
        
        -- Retry ate 10x (1 segundo total) esperando os botoes aparecerem
        local delayFrame = CreateFrame("Frame")
        local attempts = 0
        delayFrame:SetScript("OnUpdate", function()
            this.elapsed = (this.elapsed or 0) + arg1
            attempts = attempts + 1
            
            if this.elapsed > 0.1 and attempts <= 10 then
                this.elapsed = 0
                local allButtons = Cursor:CollectButtons(frame, {})
                local count = table.getn(allButtons)
                
                if count > 0 then
                    this:SetScript("OnUpdate", nil)
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM]|r " .. count .. " botoes encontrados! Inicializando...")
                    Hooks:InitCursorOnFrame(frame)
                elseif attempts >= 10 then
                    this:SetScript("OnUpdate", nil)
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM]|r Timeout: nenhum botao em " .. addonName)
                    Hooks:InitCursorOnFrame(frame)
                end
            end
        end)
    else
        -- Para frames normais, inicializa com delay pequeno (50ms)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM OnFrameShow]|r Criando delay de 50ms antes de InitCursorOnFrame...")
        local delay = CreateFrame("Frame")
        delay:SetScript("OnUpdate", function()
            this.elapsed = (this.elapsed or 0) + arg1
            if this.elapsed > 0.05 then
                this:SetScript("OnUpdate", nil)
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM OnFrameShow]|r Delay terminado, chamando InitCursorOnFrame...")
                Hooks:InitCursorOnFrame(frame)
            end
        end)
    end
end

function Hooks:InitCursorOnFrame(frame)
    if not frame then return end
    
    local Cursor = ConsoleMode.cursor
    if not Cursor then return end
    if not frame:IsVisible() then return end

    local frameName = frame:GetName() or "?"
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM InitCursor]|r Inicializando cursor em: " .. frameName)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM InitCursor]|r Buscando primeiro botao...")
    
    if Cursor.EnsureOnTop then
        Cursor:EnsureOnTop(frame)
    end

    local firstButton = Cursor:FindFirstVisibleButton(frame)
    
    if firstButton then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM]|r ✓ Auto-snap: " .. (firstButton:GetName() or "unnamed"))
        Cursor:Enable()
        Cursor:MoveTo(firstButton)
        Cursor:UpdateState()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM]|r ❌ Nenhum botao encontrado em: " .. frameName)
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM]|r Estrutura do frame:")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM]|r   Tipo: " .. (frame:GetObjectType() or "unknown"))
        local children = { frame:GetChildren() }
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM]|r   Children: " .. table.getn(children))
    end
end

function Hooks:OnFrameHide(frame)
    if not frame then return end
    
    -- Debounce: espera 100ms para confirmar que realmente fechou
    local debounce = CreateFrame("Frame")
    debounce:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + arg1
        if this.elapsed > 0.1 then
            this:SetScript("OnUpdate", nil)
            if not frame:IsVisible() then
                Hooks:ProcessFrameHide(frame)
            end
        end
    end)
end

function Hooks:ProcessFrameHide(frame)
    local Cursor = ConsoleMode.cursor
    if not Cursor then return end

    Cursor.state.activeFrames[frame] = nil

    local nextFrame = nil
    for f, _ in pairs(Cursor.state.activeFrames) do
        if f:IsVisible() then nextFrame = f; break end
    end

    if nextFrame then
        Hooks:InitCursorOnFrame(nextFrame)
    else
        Cursor:Disable()
        if ConsoleMode.keybindings and ConsoleMode.keybindings.ExitNavigationMode then
            ConsoleMode.keybindings:ExitNavigationMode()
        end
    end
end

-- ============================================================================
-- SISTEMA DE RE-CHECAGEM DE FRAMES PENDENTES
-- ============================================================================

function Hooks:TryHookPendingFrames()
    -- Varre todos os frames da lista e tenta hookar os que ainda não foram hookados
    for _, frameInfo in ipairs(self.frames) do
        local frame = getglobal(frameInfo.frame)
        if frame and not frame.cmHooked then
            if self:HookFrame(frame, frameInfo.name) then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[CM]|r Late hook: " .. frameInfo.frame)
                
                -- Se o frame já está visível, inicializa o cursor
                if frame:IsVisible() then
                    self:OnFrameShow(frame)
                end
            end
        end
    end
    
    -- ✅ CRÍTICO: Verificação especial para TalentFrame
    -- TalentFrame existe mas às vezes não dispara OnShow corretamente
    local talentFrame = getglobal("TalentFrame")
    if talentFrame and talentFrame:IsVisible() then
        local Cursor = ConsoleMode.cursor
        if Cursor and not Cursor.state.activeFrames[talentFrame] then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[CM]|r TalentFrame detectado visível mas não inicializado, forçando...")
            self:OnFrameShow(talentFrame)
        end
    end
    
    -- Também tenta hookar dropdown menus que podem ter sido criados
    for i = 1, 10 do
        local frame = getglobal("DropDownList" .. i)
        if frame and not frame.cmHooked then
            self:HookFrame(frame, "DropDown " .. i)
        end
    end
end

-- ============================================================================
-- INICIALIZAÇÃO E SISTEMA DE EVENTOS
-- ============================================================================

function Hooks:Initialize()
    if self.initialized then return end

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM]|r Inicializando sistema de hooks...")

    -- Hook inicial de todos os frames que já existem
    local count = 0
    for _, info in ipairs(self.frames) do
        local frame = getglobal(info.frame)
        if frame then
            if self:HookFrame(frame, info.name) then
                count = count + 1
            end
        end
    end

    -- Hook dropdown menus
    for i = 1, 10 do
        local frame = getglobal("DropDownList" .. i)
        if frame then
            if self:HookFrame(frame, "DropDown " .. i) then
                count = count + 1
            end
        end
    end

    -- ✅ CRÍTICO: Criar frame de eventos para detectar frames load-on-demand
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        
        -- Eventos de frames que são criados sob demanda e diálogos de missões
        self.eventFrame:RegisterEvent("MERCHANT_SHOW")
        self.eventFrame:RegisterEvent("BANKFRAME_OPENED")
        self.eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
        self.eventFrame:RegisterEvent("TRAINER_SHOW")
        self.eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
        self.eventFrame:RegisterEvent("MAIL_SHOW")
        self.eventFrame:RegisterEvent("TAXIMAP_OPENED")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.eventFrame:RegisterEvent("SPELLS_CHANGED")
        self.eventFrame:RegisterEvent("WORLD_MAP_UPDATE")
        
        -- Eventos de Transição de Missões / Diálogos de NPCs
        self.eventFrame:RegisterEvent("QUEST_GREETING")
        self.eventFrame:RegisterEvent("QUEST_DETAIL")
        self.eventFrame:RegisterEvent("QUEST_PROGRESS")
        self.eventFrame:RegisterEvent("QUEST_COMPLETE")
        self.eventFrame:RegisterEvent("QUEST_FINISHED")
        self.eventFrame:RegisterEvent("GOSSIP_SHOW")
        self.eventFrame:RegisterEvent("GOSSIP_CLOSED")
        
        self.eventFrame:SetScript("OnEvent", function()
            if event == "PLAYER_ENTERING_WORLD" then
                local delayFrame = CreateFrame("Frame")
                delayFrame:SetScript("OnUpdate", function()
                    this.elapsed = (this.elapsed or 0) + arg1
                    if this.elapsed > 1.0 then
                        this:SetScript("OnUpdate", nil)
                        Hooks:TryHookPendingFrames()
                    end
                end)
            elseif event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "QUEST_DETAIL" or event == "QUEST_GREETING" or event == "GOSSIP_SHOW" then
                -- Diálogo ou etapa de missão mudou: re-sincroniza o cursor no novo botão
                local qf = (QuestFrame and QuestFrame:IsVisible() and QuestFrame) or (GossipFrame and GossipFrame:IsVisible() and GossipFrame)
                if qf then
                    local Cursor = ConsoleMode.cursor
                    if Cursor then
                        Cursor.state.activeFrames[qf] = true
                        local delayQ = CreateFrame("Frame")
                        delayQ:SetScript("OnUpdate", function()
                            this.elapsed = (this.elapsed or 0) + arg1
                            if this.elapsed > 0.04 then
                                this:SetScript("OnUpdate", nil)
                                Hooks:InitCursorOnFrame(qf)
                            end
                        end)
                    end
                end
            else
                Hooks:TryHookPendingFrames()
            end
        end)
        
        -- ✅ Monitoramento em tempo real (a cada 0.1s) de abertura e fechamento de janelas
        self.eventFrame:SetScript("OnUpdate", function()
            this.elapsed = (this.elapsed or 0) + arg1
            if this.elapsed > 0.1 then
                this.elapsed = 0
                
                local Cursor = ConsoleMode.cursor
                if Cursor then
                    -- 1. Se o botão atual sumiu ou virou a página, auto-resync no novo botão!
                    if Cursor.state.enabled and Cursor.state.currentButton and not Cursor.state.currentButton:IsVisible() then
                        Cursor:Resync()
                    end

                    -- 2. Verifica se os frames atualmente ativos ainda estão visíveis
                    local anyFrameVisible = false
                    for frame, _ in pairs(Cursor.state.activeFrames) do
                        if frame and frame:IsVisible() then
                            anyFrameVisible = true
                        else
                            Cursor.state.activeFrames[frame] = nil
                        end
                    end
                    
                    -- Se nenhuma janela estiver aberta mas o modo navegação ainda estiver ligado, desativa na hora!
                    if not anyFrameVisible and Cursor.state.enabled then
                        Cursor:Disable()
                        if ConsoleMode.keybindings and ConsoleMode.keybindings.ExitNavigationMode then
                            ConsoleMode.keybindings:ExitNavigationMode()
                        end
                    end
                    
                    -- 3. Detecta frames que abriram sem disparar OnShow padrao
                    local problematicFrames = { 
                        "TalentFrame", "WorldMapFrame", "SUCC_bag", "SUCC_bagBank", "pfBag", "pfBank", "BagshuiBagsFrame", "Bagnon",
                        "OptionsFrame", "AdvancedSettingsGUI", "TDF_AdvancedSettingsGUI", "myAddOnsFrame", "MacroFrame", "SuperMacroFrame", "MAOptions", "KeyBindingFrame", "HelpFrame", "MailFrame", "InspectFrame", "DressUpFrame", "ConsoleModeSettingsFrame"
                    }
                    for _, frameName in ipairs(problematicFrames) do
                        local frame = getglobal(frameName)
                        if frame and frame:IsVisible() and not Cursor.state.activeFrames[frame] then
                            Hooks:OnFrameShow(frame)
                        end
                    end
                    
                    -- 3. Detecção de movimento do mouse físico para reativar o cursor do mouse
                    local curX, curY = GetCursorPosition()
                    if Hooks.lastMouseX and Hooks.lastMouseY then
                        local dx = math.abs(curX - Hooks.lastMouseX)
                        local dy = math.abs(curY - Hooks.lastMouseY)
                        if dx > 10 or dy > 10 then
                            -- O jogador mexeu no mouse físico!
                            local mouseFocus = GetMouseFocus()
                            if mouseFocus and Cursor.state.enabled and Cursor:IsInteractive(mouseFocus) then
                                Cursor:MoveTo(mouseFocus)
                            end
                        end
                    end
                    Hooks.lastMouseX = curX
                    Hooks.lastMouseY = curY
                    
                    -- 4. Detecção de Shift (L2) para comparação de equipamentos em tempo real
                    local isShift = (IsShiftKeyDown and IsShiftKeyDown()) and true or false
                    if isShift ~= Hooks.lastShiftState then
                        Hooks.lastShiftState = isShift
                        if Cursor.state.enabled and Cursor.state.currentButton then
                            local btn = Cursor.state.currentButton
                            local onEnter = btn.GetScript and btn:GetScript("OnEnter")
                            if onEnter then
                                pcall(function()
                                    this = btn
                                    onEnter()
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end

    -- Injeta botão do ConsoleMode no topo do Menu Principal
    Hooks:InjectGameMenuButton()

    -- Hook no WorldFrame para destravar mouselook no clique direito
    if WorldFrame and not Hooks.worldFrameHooked then
        local oldDown = WorldFrame:GetScript("OnMouseDown")
        WorldFrame:SetScript("OnMouseDown", function()
            if arg1 == "RightButton" and CM_MouseLookStop then
                CM_MouseLookStop()
            end
            if oldDown then oldDown() end
        end)
        Hooks.worldFrameHooked = true
    end

    self.initialized = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM]|r Hooks inicializados: " .. count .. " frames hookados.")
end

function Hooks:InjectGameMenuButton()
    if not GameMenuFrame then return end
    
    if not GameMenuButtonConsoleMode then
        local btn = CreateFrame("Button", "GameMenuButtonConsoleMode", GameMenuFrame, "GameMenuButtonTemplate")
        btn:SetText("|cff00ff00ConsoleMode - Settings|r")
        btn:SetWidth(144)
        btn:SetHeight(21)
        
        btn:SetScript("OnClick", function()
            HideUIPanel(GameMenuFrame)
            if ConsoleMode.config and ConsoleMode.config.Show then
                ConsoleMode.config:Show()
            end
        end)
    end
    
    local cmBtn = GameMenuButtonConsoleMode
    
    -- Coleta todos os botões padrão do GameMenuFrame (largura > 100px)
    local buttons = {}
    local sideTabs = {}
    local children = { GameMenuFrame:GetChildren() }
    for _, child in ipairs(children) do
        if child and child:IsObjectType("Button") and child ~= cmBtn and child:IsVisible() then
            local w = child:GetWidth() or 0
            local h = child:GetHeight() or 0
            -- Botões normais do menu têm largura aproximada de 130-160px
            if w >= 100 and h <= 35 then
                table.insert(buttons, child)
            else
                -- Abas laterais (como SuperMacro ou outros addons)
                table.insert(sideTabs, child)
            end
        end
    end
    
    -- Ordena os botões normais por GetTop() decrescente (do mais alto para o mais baixo)
    table.sort(buttons, function(a, b)
        local topA = a:GetTop() or 0
        local topB = b:GetTop() or 0
        return topA > topB
    end)
    
    -- Posiciona o botão do ConsoleMode no topo
    cmBtn:ClearAllPoints()
    cmBtn:SetPoint("TOP", GameMenuFrame, "TOP", 0, -16)
    
    -- Encadeia todos os demais botões um abaixo do outro com espaçamento uniforme de -2px
    local prevButton = cmBtn
    for _, btn in ipairs(buttons) do
        btn:ClearAllPoints()
        btn:SetPoint("TOP", prevButton, "BOTTOM", 0, -2)
        prevButton = btn
    end
    
    -- Mantém as abas laterais ancoradas na borda lateral direita do GameMenu
    for _, tab in ipairs(sideTabs) do
        tab:ClearAllPoints()
        tab:SetPoint("LEFT", GameMenuFrame, "RIGHT", -4, 0)
    end
    
    -- Ajusta a altura exata do GameMenuFrame
    local totalButtons = table.getn(buttons) + 1
    local totalHeight = 16 + (totalButtons * 23) + 12
    GameMenuFrame:SetHeight(totalHeight)
end

function Hooks:CloseTopFrame()
    local Cursor = ConsoleMode.cursor
    if Cursor and Cursor.state.activeFrames then
        for frame, _ in pairs(Cursor.state.activeFrames) do
            if frame and frame:IsVisible() then
                local frameName = frame:GetName() or ""
                if frameName == "WorldMapFrame" then
                    ToggleWorldMap()
                elseif frameName == "CharacterFrame" then
                    ToggleCharacter("PaperDollFrame")
                elseif frameName == "SpellBookFrame" then
                    ToggleSpellBook(BOOKTYPE_SPELL)
                elseif frameName == "TalentFrame" then
                    if ToggleTalentFrame then ToggleTalentFrame() else HideUIPanel(frame) end
                elseif frameName == "QuestLogFrame" then
                    ToggleQuestLog()
                elseif frameName == "FriendsFrame" then
                    ToggleFriendsFrame()
                elseif frameName == "ConsoleModeActionBarPickerFrame" or frameName == "ConsoleModePickerBanner" then
                    -- Cancela o picker ao apertar B e volta para a lista de atalhos
                    local picker = ConsoleMode.config and ConsoleMode.config.picker
                    if picker and picker.Cancel then
                        picker:Cancel()
                    else
                        frame:Hide()
                    end
                elseif HideUIPanel and (frame:GetParent() == UIParent or UIPanelWindows[frameName]) then
                    HideUIPanel(frame)
                elseif frame.Hide then
                    frame:Hide()
                end
                return true
            end
        end
    end
    return false
end
