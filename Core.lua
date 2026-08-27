--[[
    ConsoleMode - Vanilla
    Core.lua

    Inicialização principal do addon.
    Cria o namespace global, registra eventos e comandos slash.
]]

-- Namespace global do Addon
ConsoleMode = {
    version = "0.1.0",
    name    = "ConsoleMode - Vanilla"
}

local CM = ConsoleMode

-- Frame principal de eventos
local eventFrame = CreateFrame("Frame", "ConsoleModeEventFrame", UIParent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("CHAT_MSG_SAY")         -- detectar chat ativo (futuro: EditBox hooks)

eventFrame:SetScript("OnEvent", function()
    -- Addon carregado
    if event == "ADDON_LOADED" and arg1 == "ConsoleModeVanilla" then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ff00[ConsoleMode]|r v" .. CM.version .. " carregado. " ..
            "Logger: |cff00ff00ATIVO|r | Digite |cffffd100/cm|r para ajuda."
        )

    -- Variáveis salvas carregadas: hora de inicializar módulos
    elseif event == "VARIABLES_LOADED" then
        -- Garante que o banco de dados existe
        ConsoleModeDB = ConsoleModeDB or {}

        -- NOTA: ApplyDefaults() desativado durante desenvolvimento.
        -- Ative manualmente com /cm controller quando quiser testar o perfil de controle.
        -- if CM.keybindings then
        --     if not ConsoleModeDB.defaultsApplied then
        --         CM.keybindings:ApplyDefaults()
        --         ConsoleModeDB.defaultsApplied = true
        --     end
        -- end

        CM.logger:LogEvent("VARIABLES_LOADED - Módulos inicializados. Use /cm controller para ativar perfil de controle.")

    -- Entrando no mundo
    elseif event == "PLAYER_ENTERING_WORLD" then
        CM.logger:LogEvent("PLAYER_ENTERING_WORLD - Bem vindo, " .. (UnitName("player") or "Aventureiro") .. "!")

    -- Logout: salva bindings
    elseif event == "PLAYER_LOGOUT" then
        SaveBindings(GetCurrentBindingSet())
        CM.logger:LogEvent("PLAYER_LOGOUT - Bindings salvos.")
    end
end)

-- ============================================================
-- Comandos Slash
-- ============================================================
SLASH_CONSOLEMODE1 = "/consolemode"
SLASH_CONSOLEMODE2 = "/cm"

SlashCmdList["CONSOLEMODE"] = function(msg)
    local cmd = string.lower(msg or "")

    if cmd == "debug" or cmd == "logger" then
        -- Toggle do logger
        CM.logger:Toggle()

    elseif cmd == "status" then
        -- Status geral
        CM.logger:PrintStatus()

    elseif cmd == "controller" then
        -- Ativa perfil de controle (salva backup antes)
        CM.keybindings:BackupProfile()
        CM.keybindings:ApplyDefaults()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Perfil de |cff00ccffcontrole|r ativado!")

    elseif cmd == "keyboard" then
        -- Restaura perfil original de teclado
        CM.keybindings:RestoreProfile()

    elseif cmd == "backup" then
        -- Cria backup manualmente
        CM.keybindings:BackupProfile()

    elseif cmd == "mouse" then
        -- Toggle Mouse Mode manualmente via chat
        CM.keybindings:ToggleMouseMode()

    else
        -- Ajuda
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00====== ConsoleMode - Vanilla ======|r")

        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100/cm status|r     - Status geral do addon")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100/cm debug|r      - Toggle do logger de debug")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100/cm controller|r - Ativa perfil de controle (faz backup antes)")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100/cm keyboard|r   - Restaura perfil original de teclado")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100/cm backup|r     - Cria backup manual dos bindings atuais")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100/cm mouse|r      - Toggle Mouse Mode")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00==================================|r")
    end
end
