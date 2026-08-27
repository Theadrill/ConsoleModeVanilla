--[[
    ConsoleMode - Vanilla
    Core initialization and Hello World test
]]

-- Namespace global do Addon
ConsoleMode = {
    version = "0.1.0",
    name = "ConsoleMode - Vanilla"
}

-- Criação do Frame principal de eventos
local eventFrame = CreateFrame("Frame", "ConsoleModeEventFrame", UIParent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "ConsoleModeVanilla" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r v" .. ConsoleMode.version .. " carregado com sucesso!")
    elseif event == "PLAYER_ENTERING_WORLD" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Bem-vindo ao Turtle WoW! Digite |cffffd100/consolemode|r ou |cffffd100/cm|r para comandos.")
    end
end)

-- Comandos Slash (/consolemode ou /cm)
SLASH_CONSOLEMODE1 = "/consolemode"
SLASH_CONSOLEMODE2 = "/cm"
SlashCmdList["CONSOLEMODE"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00======================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffConsoleMode - Vanilla|r v" .. ConsoleMode.version)
    DEFAULT_CHAT_FRAME:AddMessage("Status: |cff00ff00Ativo|r (Modo Desenvolvimento)")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00======================================|r")
end
