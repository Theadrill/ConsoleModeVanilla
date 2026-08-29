--[[
    ConsoleMode - Vanilla
    Core.lua

    Inicialização principal do addon.
    Cria o frame global ConsoleMode que todos os módulos usam.
]]

_G = getfenv(0)

-- Frame principal global do Addon (funciona como namespace e frame de eventos)
ConsoleMode = CreateFrame("Frame", "ConsoleModeMainFrame", UIParent)
ConsoleMode.version = "0.1.0"
ConsoleMode.name    = "ConsoleMode - Vanilla"
ConsoleMode.debug   = true  -- ✅ Flag para logs verbosos (iniciando ON por padrão para debug)

local CM = ConsoleMode

-- ============================================================
-- Sistema Centralizado de Posicionamento e Movimentacao de UI
-- Permite que qualquer elemento (XPBar, ActionBars, Frames) seja
-- arrastavel com Shift+Left e resetavel com Shift+Right
-- ============================================================
CM.ui = CM.ui or {}
CM.ui.registeredFrames = {}

function CM.ui:MakeMovable(frame, key, defaultPoint, defaultRelPoint, defaultX, defaultY, friendlyName)
    if not frame or not key then return end
    
    friendlyName = friendlyName or key
    defaultPoint = defaultPoint or "CENTER"
    defaultRelPoint = defaultRelPoint or defaultPoint
    defaultX = defaultX or 0
    defaultY = defaultY or 0
    
    -- Registra nos frames gerenciados
    CM.ui.registeredFrames[key] = {
        frame = frame,
        key = key,
        defaultPoint = defaultPoint,
        defaultRelPoint = defaultRelPoint,
        defaultX = defaultX,
        defaultY = defaultY,
        friendlyName = friendlyName
    }
    
    -- Carrega posicao salva ou aplica default
    local saved = ConsoleModeDB and ConsoleModeDB.positions and ConsoleModeDB.positions[key]
    if saved and saved.point then
        frame:ClearAllPoints()
        frame:SetPoint(saved.point, UIParent, saved.relPoint or saved.point, saved.x or 0, saved.y or 0)
    else
        frame:ClearAllPoints()
        frame:SetPoint(defaultPoint, UIParent, defaultRelPoint, defaultX, defaultY)
    end
    
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    frame:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            this:StartMoving()
            this.isMoving = true
        end
    end)
    
    frame:SetScript("OnDragStop", function()
        if this.isMoving then
            this:StopMovingOrSizing()
            this.isMoving = false
            
            if not ConsoleModeDB then ConsoleModeDB = {} end
            if not ConsoleModeDB.positions then ConsoleModeDB.positions = {} end
            
            local point, _, relPoint, x, y = this:GetPoint()
            ConsoleModeDB.positions[key] = {
                point = point,
                relPoint = relPoint,
                x = x,
                y = y
            }
        end
    end)
    
    frame:SetScript("OnMouseUp", function()
        if arg1 == "RightButton" and IsShiftKeyDown() then
            CM.ui:ResetPosition(key)
        end
    end)
end

function CM.ui:ResetPosition(key)
    local info = CM.ui.registeredFrames[key]
    if not info or not info.frame then return end
    
    info.frame:ClearAllPoints()
    info.frame:SetPoint(info.defaultPoint, UIParent, info.defaultRelPoint, info.defaultX, info.defaultY)
    
    if ConsoleModeDB and ConsoleModeDB.positions then
        ConsoleModeDB.positions[key] = nil
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r " .. info.friendlyName .. " restaurado para a posicao padrao!")
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function CM.ui:ResetAllPositions()
    for key, _ in pairs(CM.ui.registeredFrames) do
        CM.ui:ResetPosition(key)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Todas as posicoes da interface foram restauradas!")
end

-- Registra eventos principais
CM:RegisterEvent("ADDON_LOADED")
CM:RegisterEvent("VARIABLES_LOADED")
CM:RegisterEvent("PLAYER_ENTERING_WORLD")
CM:RegisterEvent("PLAYER_LOGOUT")

CM:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "ConsoleModeVanilla" then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ff00[ConsoleMode]|r v" .. CM.version .. " carregado."
        )

    elseif event == "VARIABLES_LOADED" then
        ConsoleModeDB = ConsoleModeDB or {}
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6600[CM]|r VARIABLES_LOADED disparou.")
        
        -- ✅ CRÍTICO: Verificar se módulos foram carregados
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM Core]|r Verificando módulos...")
        DEFAULT_CHAT_FRAME:AddMessage("  CM.cursor: " .. (CM.cursor and "|cff00ff00OK|r" or "|cffff4444NIL|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  CM.hooks:  " .. (CM.hooks and "|cff00ff00OK|r" or "|cffff4444NIL|r"))
        
        if not CM.cursor then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Core]|r ❌ ERRO: Cursor module não carregou! Abortando inicialização.")
            return
        end
        
        if not CM.hooks then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Core]|r ❌ ERRO: Hooks module não carregou! Abortando inicialização.")
            return
        end

        -- Inicializa keybindings
        if CM.keybindings and CM.keybindings.Initialize then
            CM.keybindings:Initialize()
        end

        -- Inicializa painel de configurações
        if CM.config and CM.config.Initialize then
            CM.config:Initialize()
        end

        -- Inicializa barra de experiência customizada
        if CM.ui and CM.ui.xpBar and CM.ui.xpBar.Initialize then
            CM.ui.xpBar:Initialize()
        end

        -- Inicializa Action HUD de controle
        if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.Initialize then
            CM.ui.actionHUD:Initialize()
        end

        -- Inicializa Player Frame
        if CM.ui and CM.ui.playerFrame and CM.ui.playerFrame.Initialize then
            CM.ui.playerFrame:Initialize()
        end

        -- Inicializa Target Frame
        if CM.ui and CM.ui.targetFrame and CM.ui.targetFrame.Initialize then
            CM.ui.targetFrame:Initialize()
        end

        -- Inicializa hooks somente se módulos existem
        if CM.hooks and CM.hooks.Initialize then
            CM.hooks:Initialize()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if CM.keybindings and CM.keybindings.Initialize then
            CM.keybindings:Initialize()
        end
        if CM.config and CM.config.Initialize then
            CM.config:Initialize()
        end
        if CM.ui and CM.ui.xpBar and CM.ui.xpBar.Initialize then
            CM.ui.xpBar:Initialize()
        end
        if CM.ui and CM.ui.actionHUD then
            if CM.ui.actionHUD.Initialize then CM.ui.actionHUD:Initialize() end
            if CM.ui.actionHUD.HideDefaultBars then CM.ui.actionHUD:HideDefaultBars() end
        end
        if CM.ui and CM.ui.playerFrame then
            if CM.ui.playerFrame.Initialize then CM.ui.playerFrame:Initialize() end
            if CM.ui.playerFrame.HideDefaultBars then CM.ui.playerFrame:HideDefaultBars() end
        end
        if CM.ui and CM.ui.targetFrame then
            if CM.ui.targetFrame.Initialize then CM.ui.targetFrame:Initialize() end
            if CM.ui.targetFrame.HideDefaultBars then CM.ui.targetFrame:HideDefaultBars() end
        end

    end
end)

-- Comandos Slash
SLASH_CONSOLEMODE1 = "/consolemode"
SLASH_CONSOLEMODE2 = "/cm"

SlashCmdList["CONSOLEMODE"] = function(msg)
    local cmd = string.lower(msg or "")

    if cmd == "config" or cmd == "settings" or cmd == "binds" then
        if CM.config and CM.config.Toggle then
            CM.config:Toggle()
        end

    elseif cmd == "xp" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Comando /cm xp executado!")
        if CM.ui and CM.ui.xpBar then
            CM.ui.xpBar:Initialize()
            if CM.ui.xpBar.frame then
                CM.ui.xpBar.frame:Show()
                CM.ui.xpBar:Update()
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r XPBar: frame exibido e atualizado!")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r XPBar: frame é nil!")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r XPBar module não carregado no CM.ui!")
        end

    elseif cmd == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00====== ConsoleMode Status ======|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Versao:    " .. CM.version)
        DEFAULT_CHAT_FRAME:AddMessage("  Hooks:     " .. (CM.hooks and (CM.hooks.initialized and "|cff00ff00Inicializado|r" or "|cffffcc00Carregado mas nao init|r") or "|cffff4444NIL|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Cursor:    " .. (CM.cursor and (CM.cursor.state.enabled and "|cff00ff00ATIVO|r" or "|cffaaaaaaInativo|r") or "|cffff4444NIL|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Debug:     " .. (CM.debug and "|cffffcc00ON|r" or "|cff888888OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00================================|r")

    elseif cmd == "debug" then
        CM.debug = not CM.debug
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM]|r Modo debug: " .. (CM.debug and "|cffffcc00LIGADO|r" or "|cff888888DESLIGADO|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa[CM]|r Logs verbosos estao " .. (CM.debug and "habilitados" or "desabilitados"))

    elseif cmd == "controller" then
        if CM.keybindings and CM.keybindings.ApplyDefaults then
            CM.keybindings:ApplyDefaults()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM]|r Perfil de controle aplicado com sucesso!")
        end

    elseif cmd == "keyboard" then
        if CM.keybindings and CM.keybindings.RestoreProfile then
            CM.keybindings:RestoreProfile()
        end

    elseif cmd == "mouse" then
        if CM.keybindings and CM.keybindings.ToggleMouseMode then
            CM.keybindings:ToggleMouseMode()
        end

    elseif cmd == "init" then
        if CM.keybindings and CM.keybindings.Initialize then
            CM.keybindings:Initialize()
        end
        if CM.hooks then
            CM.hooks.initialized = false
            CM.hooks:Initialize()
        end

    elseif cmd == "test" then
        local f = getglobal("CharacterFrame")
        if f and CM.hooks then
            CM.hooks:OnFrameShow(f)
        end

    elseif cmd == "frame" then
        local frame = GetMouseFocus()
        if frame then
            local name = frame:GetName() or "(unnamed)"
            local ftype = frame:GetObjectType() or "unknown"
            local parent = frame:GetParent()
            local parentName = parent and (parent:GetName() or "(unnamed parent)") or "none"
            
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Frame Debug]|r")
            DEFAULT_CHAT_FRAME:AddMessage("  Nome:      |cffffcc00" .. name .. "|r")
            DEFAULT_CHAT_FRAME:AddMessage("  Tipo:      |cff88ccff" .. ftype .. "|r")
            DEFAULT_CHAT_FRAME:AddMessage("  Parent:    |cffcccccc" .. parentName .. "|r")
            DEFAULT_CHAT_FRAME:AddMessage("  Visivel:   " .. (frame:IsVisible() and "|cff00ff00SIM|r" or "|cffff4444NAO|r"))
            
            if CM.cursor and CM.cursor.IsInteractive then
                local interactive = CM.cursor:IsInteractive(frame)
                DEFAULT_CHAT_FRAME:AddMessage("  Interativo: " .. (interactive and "|cff00ff00SIM|r" or "|cffff4444NAO|r"))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM]|r Nenhum frame sob o mouse")
        end

    elseif cmd == "menu" then
        if CM.mainMenu and CM.mainMenu.Toggle then
            CM.mainMenu:Toggle()
        end

    elseif cmd == "resetui" then
        if CM.ui and CM.ui.ResetAllPositions then
            CM.ui:ResetAllPositions()
        end

    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ConsoleMode:|r Comandos disponiveis:")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm menu|r       - Abre/Fecha o Menu Principal (Console Hub)")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm config|r     - Abre o Painel de Configuracoes")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm resetui|r    - Restaura todas as posicoes de UI para o padrao")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm controller|r - Aplica perfil de controle completo")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm keyboard|r   - Restaura perfil de teclado/mouse")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm mouse|r      - Alterna Mouse Mode (Cursor Livre)")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm status|r     - Mostra status do addon")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm debug|r      - Liga/desliga logs verbosos")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm frame|r      - Identifica frame sob o mouse")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00/cm init|r       - Re-inicializa hooks e bindings")
    end
end
