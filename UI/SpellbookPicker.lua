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

local CANONICAL_SLOTS = {
    [1] = {
        X      = { slot = 1,  action = "ACTIONBUTTON1" },
        Y      = { slot = 2,  action = "ACTIONBUTTON2" },
        B      = { slot = 3,  action = "ACTIONBUTTON3" },
        DUP    = { slot = 7,  action = "ACTIONBUTTON7" },
        DDOWN  = { slot = 8,  action = "ACTIONBUTTON8" },
        DLEFT  = { slot = 9,  action = "ACTIONBUTTON9" },
        DRIGHT = { slot = 10, action = "ACTIONBUTTON10" },
    },
    [2] = {
        X      = { slot = 61, action = "MULTIACTIONBAR1BUTTON1" },
        Y      = { slot = 62, action = "MULTIACTIONBAR1BUTTON2" },
        B      = { slot = 63, action = "MULTIACTIONBAR1BUTTON3" },
        A      = { slot = 64, action = "MULTIACTIONBAR1BUTTON4" },
        DUP    = { slot = 65, action = "MULTIACTIONBAR1BUTTON5" },
        DDOWN  = { slot = 66, action = "MULTIACTIONBAR1BUTTON6" },
        DLEFT  = { slot = 67, action = "MULTIACTIONBAR1BUTTON7" },
        DRIGHT = { slot = 68, action = "MULTIACTIONBAR1BUTTON8" },
    },
    [3] = {
        X      = { slot = 49, action = "MULTIACTIONBAR2BUTTON1" },
        Y      = { slot = 50, action = "MULTIACTIONBAR2BUTTON2" },
        B      = { slot = 51, action = "MULTIACTIONBAR2BUTTON3" },
        A      = { slot = 52, action = "MULTIACTIONBAR2BUTTON4" },
        DUP    = { slot = 53, action = "MULTIACTIONBAR2BUTTON5" },
        DDOWN  = { slot = 54, action = "MULTIACTIONBAR2BUTTON6" },
        DLEFT  = { slot = 55, action = "MULTIACTIONBAR2BUTTON7" },
        DRIGHT = { slot = 56, action = "MULTIACTIONBAR2BUTTON8" },
    },
    [4] = {
        X      = { slot = 25, action = "MULTIACTIONBAR3BUTTON1" },
        Y      = { slot = 26, action = "MULTIACTIONBAR3BUTTON2" },
        B      = { slot = 27, action = "MULTIACTIONBAR3BUTTON3" },
        A      = { slot = 28, action = "MULTIACTIONBAR3BUTTON4" },
        DUP    = { slot = 29, action = "MULTIACTIONBAR3BUTTON5" },
        DDOWN  = { slot = 30, action = "MULTIACTIONBAR3BUTTON6" },
        DLEFT  = { slot = 31, action = "MULTIACTIONBAR3BUTTON7" },
        DRIGHT = { slot = 32, action = "MULTIACTIONBAR3BUTTON8" },
    },
    [5] = {
        X      = { slot = 37, action = "MULTIACTIONBAR4BUTTON1" },
        Y      = { slot = 38, action = "MULTIACTIONBAR4BUTTON2" },
        B      = { slot = 39, action = "MULTIACTIONBAR4BUTTON3" },
        A      = { slot = 40, action = "MULTIACTIONBAR4BUTTON4" },
        DUP    = { slot = 41, action = "MULTIACTIONBAR4BUTTON5" },
        DDOWN  = { slot = 42, action = "MULTIACTIONBAR4BUTTON6" },
        DLEFT  = { slot = 43, action = "MULTIACTIONBAR4BUTTON7" },
        DRIGHT = { slot = 44, action = "MULTIACTIONBAR4BUTTON8" },
    },
}
SBP.CANONICAL_SLOTS = CANONICAL_SLOTS

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

    -- Usa o slot canônico correspondente à página e botão (garante integridade do layout do controle)
    if page and CANONICAL_SLOTS[page] and CANONICAL_SLOTS[page][btnKey] then
        local canonical = CANONICAL_SLOTS[page][btnKey]
        return canonical.slot, canonical.action
    end

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
            -- Filtra passivas: no 1.12 o rank/subname contém "Passive"
            -- (ex: "Passive", "Racial Passive", "Passive (Combat)")
            local rankStr = rank or ""
            local isPassive = false

            -- Tenta IsPassiveSpell se existir (Turtle WoW pode ter)
            if IsPassiveSpell then
                local ok, result = pcall(IsPassiveSpell, i, "spell")
                if ok and result then isPassive = true end
            end

            -- Fallback: checa se o rank contém "Passive"
            if not isPassive and string.find(string.lower(rankStr), "passive") then
                isPassive = true
            end

            if not isPassive then
                local icon = GetSpellTexture(i, "spell")
                tinsert(spells, { name = name, rank = rankStr, icon = icon, spellIndex = i })
            end
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
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("SPBOOK_ERR_KEY"))
        return false
    end

    local slot, bindingAction = self:ResolveTargetSlot(page, btnKey)
    if not slot then
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("SPBOOK_ERR_NOSLOT"))
        return false
    end

    -- Coloca a magia no slot
    local ok = pcall(function()
        PickupSpell(spell.spellIndex, "spell")
        PlaceAction(slot)
        ClearCursor()
    end)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("SPBOOK_ERR_PLACE_FMT"), slot))
        ClearCursor()
        return false
    end

    -- Aplica binding de forma segura preservando os atalhos de navegação do controle
    local KB = CM.keybindings or (ConsoleMode and ConsoleMode.keybindings)
    if KB and KB.ApplySingleGameBinding then
        KB:ApplySingleGameBinding(physKey, bindingAction)
    else
        SetBinding(physKey, bindingAction)
        local set = GetCurrentBindingSet()
        if not set or set == 0 then set = 1 end
        pcall(function() SaveBindings(set) end)
    end

    local rankStr = (spell.rank and spell.rank ~= "") and (" (" .. spell.rank .. ")") or ""
    DEFAULT_CHAT_FRAME:AddMessage(
        format(CM:T("SPBOOK_BOUND_FMT"), comboName, spell.name .. rankStr, slot)
    )
    PlaySound("igMainMenuOptionCheckBoxOn")

    if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.Update then
        CM.ui.actionHUD:Update()
    end

    return true
end
