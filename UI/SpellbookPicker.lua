--[[
    ConsoleMode - Vanilla
    UI/SpellbookPicker.lua

    Módulo auxiliar: lógica de resolução de slot e leitura do spellbook.
    A UI é gerida inteiramente pelo ActionBarPicker para evitar sobreposição
    de frames.

    Compatível com Lua 5.0 / WoW 1.12
]]

local CM = ConsoleMode
CM.config = CM.config or {}
CM.config.spellbookPicker = CM.config.spellbookPicker or {}
local SBP = CM.config.spellbookPicker

-- Definições das barras de ação (ordem de busca para slot vazio)
SBP.BAR_DEFS = {
    { startSlot = 1,  bindingPrefix = "ACTIONBUTTON",          count = 12 },
    { startSlot = 61, bindingPrefix = "MULTIACTIONBAR1BUTTON",  count = 12 },
    { startSlot = 49, bindingPrefix = "MULTIACTIONBAR2BUTTON",  count = 12 },
    { startSlot = 25, bindingPrefix = "MULTIACTIONBAR3BUTTON",  count = 12 },
    { startSlot = 37, bindingPrefix = "MULTIACTIONBAR4BUTTON",  count = 12 },
}

-- Mapeamento físico de página+botão → tecla real
SBP.KEY_MAPPINGS = {
    [1] = { A="SPACE",           X="1",           Y="2",           B="3",           DUP="7",           DDOWN="8",           DLEFT="9",           DRIGHT="0" },
    [2] = { A="SHIFT-SPACE",     X="SHIFT-1",     Y="SHIFT-2",     B="SHIFT-3",     DUP="SHIFT-7",     DDOWN="SHIFT-8",     DLEFT="SHIFT-9",     DRIGHT="SHIFT-0" },
    [3] = { A="CTRL-SPACE",      X="CTRL-1",      Y="CTRL-2",      B="CTRL-3",      DUP="CTRL-7",      DDOWN="CTRL-8",      DLEFT="CTRL-9",      DRIGHT="CTRL-0" },
    [4] = { A="ALT-SPACE",       X="ALT-1",       Y="ALT-2",       B="ALT-3",       DUP="ALT-7",       DDOWN="ALT-8",       DLEFT="ALT-9",       DRIGHT="ALT-0" },
    [5] = { A="ALT-SHIFT-SPACE", X="ALT-SHIFT-1", Y="ALT-SHIFT-2", B="ALT-SHIFT-3", DUP="ALT-SHIFT-7", DDOWN="ALT-SHIFT-8", DLEFT="ALT-SHIFT-9", DRIGHT="ALT-SHIFT-0" },
}

-- ============================================================================
-- RESOLUÇÃO DE SLOT
-- ============================================================================

-- Converte um binding action (ex: "ACTIONBUTTON7") em (slotReal, bindingAction).
function SBP:ParseBindingAction(boundAction)
    if not boundAction or boundAction == "" then return nil, nil end
    local _, _, n

    _, _, n = string.find(boundAction, "^ACTIONBUTTON(%d+)$")
    if n then
        local idx = tonumber(n)
        return self.BAR_DEFS[1].startSlot + idx - 1, "ACTIONBUTTON" .. idx
    end
    _, _, n = string.find(boundAction, "^MULTIACTIONBAR1BUTTON(%d+)$")
    if n then
        local idx = tonumber(n)
        return self.BAR_DEFS[2].startSlot + idx - 1, "MULTIACTIONBAR1BUTTON" .. idx
    end
    _, _, n = string.find(boundAction, "^MULTIACTIONBAR2BUTTON(%d+)$")
    if n then
        local idx = tonumber(n)
        return self.BAR_DEFS[3].startSlot + idx - 1, "MULTIACTIONBAR2BUTTON" .. idx
    end
    _, _, n = string.find(boundAction, "^MULTIACTIONBAR3BUTTON(%d+)$")
    if n then
        local idx = tonumber(n)
        return self.BAR_DEFS[4].startSlot + idx - 1, "MULTIACTIONBAR3BUTTON" .. idx
    end
    _, _, n = string.find(boundAction, "^MULTIACTIONBAR4BUTTON(%d+)$")
    if n then
        local idx = tonumber(n)
        return self.BAR_DEFS[5].startSlot + idx - 1, "MULTIACTIONBAR4BUTTON" .. idx
    end
    return nil, nil
end

-- Próximo slot vazio nas barras 1-5 em ordem.
function SBP:FindNextEmptySlot()
    for _, bar in ipairs(self.BAR_DEFS) do
        for i = 1, bar.count do
            local slot = bar.startSlot + i - 1
            local ok, has = pcall(function() return HasAction(slot) end)
            if ok and not has then
                return slot, bar.bindingPrefix .. i
            end
        end
    end
    return nil, nil
end

-- Resolve slot alvo para (page, btnKey).
-- Retorna (slot, bindingAction).
function SBP:ResolveTargetSlot(page, btnKey)
    local physKey = self.KEY_MAPPINGS[page] and self.KEY_MAPPINGS[page][btnKey]
    if not physKey then return nil, nil end

    local boundAction = GetBindingAction(physKey)
    if boundAction and string.find(boundAction, "^CM_") then
        local KB = CM.keybindings
        if KB and KB.savedNavBindings and KB.savedNavBindings[physKey] then
            boundAction = KB.savedNavBindings[physKey]
        end
    end

    local slot, bindingAction = self:ParseBindingAction(boundAction)
    if slot then return slot, bindingAction end

    return self:FindNextEmptySlot()
end

-- ============================================================================
-- LEITURA DO SPELLBOOK
-- ============================================================================

function SBP:GetSpellTabs()
    local tabs = {}
    local numTabs = GetNumSpellTabs()
    if not numTabs then return tabs end
    for i = 1, numTabs do
        local name, icon, offset, numSpells = GetSpellTabInfo(i)
        if name and numSpells and numSpells > 0 then
            tinsert(tabs, { name = name, icon = icon, offset = offset, numSpells = numSpells })
        end
    end
    return tabs
end

function SBP:GetSpellsForTab(tabInfo)
    local spells = {}
    for i = tabInfo.offset + 1, tabInfo.offset + tabInfo.numSpells do
        local name, rank = GetSpellName(i, "spell")
        if name and name ~= "" then
            local icon = GetSpellTexture(i, "spell")
            tinsert(spells, { name = name, rank = rank or "", icon = icon, spellIndex = i })
        end
    end
    return spells
end

-- ============================================================================
-- APLICAR BINDING (chamado pelo ActionBarPicker após confirmação)
-- ============================================================================

function SBP:ApplySpellBinding(page, btnKey, comboName, spell)
    local physKey = self.KEY_MAPPINGS[page] and self.KEY_MAPPINGS[page][btnKey]
    if not physKey then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro: tecla fisica nao encontrada!")
        return false
    end

    local slot, bindingAction = self:ResolveTargetSlot(page, btnKey)
    if not slot then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Sem slot disponivel! Libere um slot nas barras de acao.")
        return false
    end

    -- Coloca a magia no slot
    local ok = pcall(function()
        PickupSpell(spell.spellIndex, "spell")
        PlaceAction(slot)
        ClearCursor()
    end)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro ao colocar magia no slot " .. slot .. "!")
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

    local rankStr = (spell.rank and spell.rank ~= "") and (" (" .. spell.rank .. ")") or ""
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ff00[ConsoleMode]|r |cffffcc00" .. comboName .. "|r vinculado a |cff88ccff"
        .. spell.name .. rankStr .. "|r (slot " .. slot .. ")!"
    )
    PlaySound("igMainMenuOptionCheckBoxOn")

    if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.Update then
        CM.ui.actionHUD:Update()
    end

    return true
end
