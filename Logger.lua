--[[
    ConsoleMode - Vanilla
    Logger.lua

    Sistema de log no chat para debug e desenvolvimento.
    Ativado por padrão durante o desenvolvimento.
    Toggle via /cm debug ou /cm logger
]]

local CM = ConsoleMode

-- ============================================================
-- Módulo Logger
-- ============================================================
CM.logger = {}
local Logger = CM.logger

-- Ativado por padrão (modo desenvolvimento)
Logger.enabled = true

-- Prefixo visual no chat
local PREFIX       = "|cffaaaaaa[|r|cff00ccffCM Debug|r|cffaaaaaa]|r "
local PREFIX_EVENT = "|cffaaaaaa[|r|cffffcc00CM Event|r|cffaaaaaa]|r "
local PREFIX_INPUT = "|cffaaaaaa[|r|cff88ff88CM Input|r|cffaaaaaa]|r "
local PREFIX_MODE  = "|cffaaaaaa[|r|cffff9900CM Mode|r|cffaaaaaa]|r "

-- ============================================================
-- Função principal de log
-- ============================================================
function Logger:Log(msg, category)
    if not Logger.enabled then return end

    local prefix = PREFIX
    if category == "event" then
        prefix = PREFIX_EVENT
    elseif category == "input" then
        prefix = PREFIX_INPUT
    elseif category == "mode" then
        prefix = PREFIX_MODE
    end

    DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(msg))
end

-- Atalhos por categoria
function Logger:LogEvent(msg)  Logger:Log(msg, "event")  end
function Logger:LogInput(msg)  Logger:Log(msg, "input")  end
function Logger:LogMode(msg)   Logger:Log(msg, "mode")   end

-- Log sempre visível no chat (independente do toggle, para debug crítico)
function Logger:Alert(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff6600[CM Alert]|r " .. tostring(msg))
end

-- ============================================================
-- Toggle do Logger
-- ============================================================
function Logger:Toggle()
    Logger.enabled = not Logger.enabled
    if Logger.enabled then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. "|cff00ff00Logger ATIVADO|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa[CM Debug]|r |cffff4444Logger DESATIVADO|r")
    end
end

-- ============================================================
-- Log de Status Geral (/cm status)
-- ============================================================
function Logger:PrintStatus()
    local KB = CM.keybindings
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00====== ConsoleMode Status ======|r")
    DEFAULT_CHAT_FRAME:AddMessage("  Versão:      |cffffd100" .. CM.version .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("  Debug Log:   " .. (Logger.enabled and "|cff00ff00ATIVO|r" or "|cffff4444INATIVO|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Mouse Mode:  " .. (KB and KB.mouseModeActive and "|cff00ff00ATIVO|r" or "|cffff4444INATIVO|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Navegação:   " .. (KB and KB.navigationMode and "|cff00ff00ATIVO (UI aberta)|r" or "|cffaaaaaa inativo|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Chat Aberto: " .. (KB and KB.chatActive and "|cffffcc00SIM (atalhos desativados)|r" or "|cffaaaaaa Não|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Personagem:  |cff00ccff" .. (UnitName("player") or "?") .. "|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00================================|r")
end

-- ============================================================
-- Interceptor de Teclas via OnUpdate
-- Usa polling de modificadores sem bloquear input do jogo
-- (EnableKeyboard bloquearia as teclas no WoW 1.12)
-- ============================================================
local keyLogger = CreateFrame("Frame", "ConsoleModeKeyLogger", UIParent)
local lastMods = ""

keyLogger:SetScript("OnUpdate", function()
    if not Logger.enabled then return end

    -- Detecta modificadores ativos via polling
    local mods = ""
    if IsShiftKeyDown()   then mods = mods .. "SHIFT+" end
    if IsControlKeyDown() then mods = mods .. "CTRL+" end
    if IsAltKeyDown()     then mods = mods .. "ALT+" end

    -- Loga apenas quando o estado de modificadores muda
    if mods ~= lastMods then
        lastMods = mods

        local pageName = "Base"
        if IsShiftKeyDown() and IsAltKeyDown() then
            pageName = "L2+R2"
        elseif IsControlKeyDown() and IsAltKeyDown() then
            pageName = "R1+R2"
        elseif IsAltKeyDown() then
            pageName = "R2"
        elseif IsControlKeyDown() then
            pageName = "R1"
        elseif IsShiftKeyDown() then
            pageName = "L2"
        end

        local KB = CM.keybindings
        local modeStr = "Hotkey"
        if KB then
            if KB.navigationMode then modeStr = "|cff00ccffNavegação|r"
            elseif KB.mouseModeActive then modeStr = "|cff88ff88Mouse|r"
            elseif KB.chatActive then modeStr = "|cffffcc00Chat|r"
            end
        end

        if mods ~= "" then
            Logger:LogInput(
                "Modificador: |cffffd100" .. mods .. "|r" ..
                " | Página: |cff00ccff" .. pageName .. "|r" ..
                " | Modo: " .. modeStr
            )
        end
    end
end)
