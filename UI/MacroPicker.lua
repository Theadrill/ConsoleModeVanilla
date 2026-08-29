--[[
    ConsoleMode - Vanilla
    UI/MacroPicker.lua

    Módulo auxiliar: leitura de Macros (Gerais da Conta e do Personagem)
    e aplicação do binding macro↓slot↓tecla.

    Compat�vel com Lua 5.0 / WoW1 1.12
]]

local CM = ConsoleMode
CM.config = CM.config or {}
CM.config.macroPicker = CM.config.macroPicker or {}
local MP = CM.config.macroPicker

-- ==========================================================================
-- LEITURA DE MACROS
-- ==========================================================================

-- Retorna a lista de macros gerais da conta índices 1 a 18 no WoW 1.12
function MP:GetAccountMacros()
    local macros = {}
    for i = 1, 18 do
        local name, texture, body = GetMacroInfo(i)
        if name and name ~= "" then
            tinsert(macros, {
                index   = i,
                name    = name,
                icon    = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
                body    = body or "",
                isLocal = false,
            })
        end
    end
    return macros
end

-- Retorna a lista de macros específicas do personagem índices 19 a 36 no WoW 1.12
function MP:GetCharacterMacros()
    local macros = {}
    for i = 19, 36 do
        local name, texture, body = GetMacroInfo(i)
        if name and name ~= "" then
            tinsert(macros, {
                index   = i,
                name    = name,
                icon    = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
                body    = body or "",
                isLocal = true,
            })
        end
    end
    return macros
end

-- ==========================================================================
-- APLICAR BINDING
-- ==========================================================================

function MP:ApplyMacroBinding(page, btnKey, comboName, macro)
    local SBP = CM.config and CM.config.spellbookPicker
    if not SBP then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro interno: SBP nao encontrado!")
        return false
   end

    local physKey = SBP.KEY_MAPPINGS[page] and SBP.KEY_MAPPINGS[page][btnKey]
    if not physKey then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro; tecla fisica nao encontrada!")
        return false
    end

    local slot, bindingAction = SBP:ResolveTargetSlot(page, btnKey)
    if not slot then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Sem slot disponivel! Libere um slot nas barras de acao.")
        return false
    end

    -- Pega a macro e coloca no slot da action bar
    local ok = pcall(function()
        PickupMacro(macro.index)
        PlaceAction(slot)
        ClearCursor()
    end)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro ao colocar macro no slot " .. slot .. "!")
        ClearCursor()
        return false
    end

    -- Aplica binding
    local KB = CM.keybindings
    if KB and KB.navigationMode and KB.savedNavBindings then
        for k, act in pairs(KB.savedNavBindings) do
            if act and act ~= "" and not string.find(act, "^CM_CURSOR_") then
                SetBinding(k, act)
            elseif k == "TAB" then
                SetBinding("TAB", "TARGETNEARESTENEMY")
            end
        end
    end

    SetBinding(physKey, bindingAction)

    if KB and KB.savedNavBindings then
        KB.savedNavBindings[physKey] = bindingAction
    end

    local set = GetCurrentBindingSet()
    if not set or set == 0 then set = 1 end
    pcall(function() SaveBindings(set) end)

    if KB and KB.navigationMode and KB.defaults and KB.defaults[1] then
        local d1 = KB.defaults[1]
        SetBinding(d1.DUP,    "CM_CURSOR_UP")
        SetBinding(d1.DDOWN,  "CM_CURSOR_DOWN")
        SetBinding(d1.DLEFT,  "CM_CURSOR_LEFT")
        SetBinding(d1.DRIGHT, "CM_CURSOR_RIGHT")
        SetBinding(d1.A,      "CM_CURSOR_CONFIRM")
        SetBinding(d1.B,      "CM_CURSOR_CANCEL")
   end

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ff00[ConsoleMode]|r |cffffcc00" .. comboName
        .. "|r vinculado a macro |cff88ccff#" .. macro.name
        .. "|r (slot " .. slot .. ")!"
    )
    PlaySound("igMainMenuOptionCheckBoxOn")

    if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.Update then
        CM.ui.actionHUD:Update()
    end

    return true
end
