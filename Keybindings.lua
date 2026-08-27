--[[
    ConsoleMode - Vanilla
    Keybindings.lua

    Gerencia:
    - Nomes legíveis dos bindings no menu de atalhos do WoW
    - 5 páginas de ação (Base, L2, R1, R2, R1+R2)
    - Defaults de teclado para cada botão/página
    - Backup e Restore completo de bindings + action bars por personagem
    - Detecção de chat aberto (desativa atalhos)
    - Toggle de Mouse Mode (L3)
]]

local CM = ConsoleMode

-- ============================================================
-- Nomes de Botões e Modificadores (para exibição no menu)
-- ============================================================
local buttonLabels = {
    A      = "A",
    X      = "X",
    Y      = "Y",
    B      = "B",
    DUP    = "D-Pad Cima",
    DDOWN  = "D-Pad Baixo",
    DLEFT  = "D-Pad Esquerda",
    DRIGHT = "D-Pad Direita",
}

local pageLabels = {
    [1] = "",
    [2] = "L2 + ",
    [3] = "R1 + ",
    [4] = "R2 + ",
    [5] = "L2+R2 + ",
}

-- Registra os headers das páginas
_G["BINDING_HEADER_CONSOLEMODEBASE"]   = "ConsoleMode - Base (Sem Modificador)"
_G["BINDING_HEADER_CONSOLEMMODEL2"]    = "ConsoleMode - L2 (Shift)"
_G["BINDING_HEADER_CONSOLEMODER1"]     = "ConsoleMode - R1 (Ctrl)"
_G["BINDING_HEADER_CONSOLEMODER2"]     = "ConsoleMode - R2 (Alt)"
_G["BINDING_HEADER_CONSOLEMODEL2R2"]   = "ConsoleMode - L2+R2 (Shift+Alt)"
_G["BINDING_HEADER_CONSOLEMODEFIXED"]  = "ConsoleMode - Botões Fixos"
_G["BINDING_HEADER_CONSOLEMODECURSOR"] = "ConsoleMode - Navegação de Cursor"

-- Registra nomes legíveis para todos os 40 slots de ação
for page = 1, 5 do
    for _, btn in ipairs({"A","X","Y","B","DUP","DDOWN","DLEFT","DRIGHT"}) do
        local key = "BINDING_NAME_CM_ACTION_" .. btn .. "_" .. page
        _G[key] = pageLabels[page] .. buttonLabels[btn]
    end
end

-- Menu Ring
_G["BINDING_HEADER_CONSOLEMODERING"]    = "ConsoleMode - Menu Ring"
_G["BINDING_NAME_CM_RING_MENU"]         = "L2+R2+A (Abrir Menu Ring)"

-- Nomes dos botões fixos
_G["BINDING_NAME_CM_FIXED_L1"]          = "L1 (Selecionar Alvo)"
_G["BINDING_NAME_CM_FIXED_SELECT"]      = "Select (Mapa)"
_G["BINDING_NAME_CM_FIXED_START"]       = "Start (Menu do Jogo)"
_G["BINDING_NAME_CM_TOGGLE_MOUSEMODE"]  = "L3 (Toggle Mouse Mode)"
_G["BINDING_NAME_CM_MOUSERIGHT"]        = "R3 (Clique Direito)"

-- Nomes dos bindings de cursor
_G["BINDING_NAME_CM_CURSOR_UP"]      = "Cursor: Cima"
_G["BINDING_NAME_CM_CURSOR_DOWN"]    = "Cursor: Baixo"
_G["BINDING_NAME_CM_CURSOR_LEFT"]    = "Cursor: Esquerda"
_G["BINDING_NAME_CM_CURSOR_RIGHT"]   = "Cursor: Direita"
_G["BINDING_NAME_CM_CURSOR_CONFIRM"] = "Cursor: Confirmar (A)"
_G["BINDING_NAME_CM_CURSOR_CANCEL"]  = "Cursor: Cancelar (B)"

-- ============================================================
-- Defaults de Teclado por Botão e Página
-- Formato: [página][botão] = "TECLA"
-- Modificadores: SHIFT (L2), CTRL (R1), ALT (R2), SHIFT-ALT (L2+R2)
-- ============================================================
local defaults = {
    -- Page 1: Base
    [1] = {
        A      = "SPACE",
        X      = "1",
        Y      = "2",
        B      = "3",
        DUP    = "7",
        DDOWN  = "8",
        DLEFT  = "9",
        DRIGHT = "0",
    },
    -- Page 2: L2 = SHIFT
    [2] = {
        A      = "SHIFT-SPACE",
        X      = "SHIFT-1",
        Y      = "SHIFT-2",
        B      = "SHIFT-3",
        DUP    = "SHIFT-7",
        DDOWN  = "SHIFT-8",
        DLEFT  = "SHIFT-9",
        DRIGHT = "SHIFT-0",
    },
    -- Page 3: R1 = CTRL
    [3] = {
        A      = "CTRL-SPACE",
        X      = "CTRL-1",
        Y      = "CTRL-2",
        B      = "CTRL-3",
        DUP    = "CTRL-7",
        DDOWN  = "CTRL-8",
        DLEFT  = "CTRL-9",
        DRIGHT = "CTRL-0",
    },
    -- Page 4: R2 = ALT
    [4] = {
        A      = "ALT-SPACE",
        X      = "ALT-1",
        Y      = "ALT-2",
        B      = "ALT-3",
        DUP    = "ALT-7",
        DDOWN  = "ALT-8",
        DLEFT  = "ALT-9",
        DRIGHT = "ALT-0",
    },
    -- Page 5: L2+R2 = SHIFT+ALT
    [5] = {
        A      = "SHIFT-ALT-SPACE",
        X      = "SHIFT-ALT-1",
        Y      = "SHIFT-ALT-2",
        B      = "SHIFT-ALT-3",
        DUP    = "SHIFT-ALT-7",
        DDOWN  = "SHIFT-ALT-8",
        DLEFT  = "SHIFT-ALT-9",
        DRIGHT = "SHIFT-ALT-0",
    },
}

-- Defaults fixos
local fixedDefaults = {
    CM_FIXED_L1     = "TAB",
    CM_FIXED_SELECT = "M",
    CM_FIXED_START  = "ESCAPE",
}

-- ============================================================
-- Módulo de Keybindings
-- ============================================================
CM.keybindings = {}
local KB = CM.keybindings

KB.mouseModeActive  = false
KB.chatActive       = false
KB.navigationMode   = false  -- true quando uma janela de UI está aberta
KB.savedNavBindings = {}     -- bindings salvas antes de entrar no modo navegação

-- ============================================================
-- Aplicar Defaults
-- ============================================================
function KB:ApplyDefaults()
    -- Ações das 5 páginas
    for page = 1, 5 do
        for btn, key in pairs(defaults[page]) do
            local bindName = "CM_ACTION_" .. btn .. "_" .. page
            SetBinding(key, bindName)
            CM.logger:Log("Default: " .. key .. " -> " .. bindName)
        end
    end

    -- Botões fixos
    for bindName, key in pairs(fixedDefaults) do
        SetBinding(key, bindName)
        CM.logger:Log("Fixed: " .. key .. " -> " .. bindName)
    end

    SaveBindings(GetCurrentBindingSet())
    CM.logger:Log("Defaults aplicados e salvos.")
end

-- ============================================================
-- Backup: salva TODOS os bindings + action bars do personagem
-- ============================================================
function KB:BackupProfile()
    if not ConsoleModeDB then ConsoleModeDB = {} end
    if not ConsoleModeDB.backup then ConsoleModeDB.backup = {} end

    local backup = {}

    -- Backup de todos os bindings
    backup.bindings = {}
    for i = 1, 500 do
        local action = GetBindingAction(i)
        if action and action ~= "" then
            local key = GetBindingByIndex(i)
            if key then
                backup.bindings[key] = action
            end
        end
    end

    -- Backup de todas as action bars (slots 1-120 no 1.12)
    backup.actions = {}
    for slot = 1, 120 do
        local actionType, id, subType = GetActionInfo(slot)
        if actionType then
            backup.actions[slot] = { actionType = actionType, id = id, subType = subType }
        end
    end

    backup.timestamp = date("%d/%m/%Y %H:%M")
    ConsoleModeDB.backup[UnitName("player")] = backup

    CM.logger:Log("Backup criado para " .. UnitName("player") .. " em " .. backup.timestamp)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Backup salvo! Use |cffffd100/cm keyboard|r para restaurar.")
end

-- ============================================================
-- Restore: restaura bindings + action bars do backup
-- ============================================================
function KB:RestoreProfile()
    if not ConsoleModeDB or not ConsoleModeDB.backup then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Nenhum backup encontrado!")
        return
    end

    local playerName = UnitName("player")
    local backup = ConsoleModeDB.backup[playerName]

    if not backup then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Nenhum backup para " .. playerName .. "!")
        return
    end

    -- Limpa todos os bindings atuais
    for i = 1, 500 do
        local key = GetBindingByIndex(i)
        if key then
            SetBinding(key, nil)
        end
    end

    -- Restaura bindings salvos
    if backup.bindings then
        for key, action in pairs(backup.bindings) do
            SetBinding(key, action)
        end
    end

    SaveBindings(GetCurrentBindingSet())

    CM.logger:Log("Perfil de teclado restaurado para " .. playerName)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Perfil original de teclado restaurado!")
end

-- ============================================================
-- Toggle Mouse Mode (L3)
-- ============================================================
function KB:ToggleMouseMode()
    KB.mouseModeActive = not KB.mouseModeActive

    if KB.mouseModeActive then
        -- No mouse mode: L2 = clique esquerdo, R2 = clique direito
        -- (gerenciado pelo remapper externo / Steam Input)
        -- O addon apenas registra o estado e notifica
        CM.logger:Log("Mouse Mode: ATIVADO - Analógico direito move cursor")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Mouse Mode |cff00ff00ATIVADO|r")
    else
        CM.logger:Log("Mouse Mode: DESATIVADO - Analógico direito controla câmera")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Mouse Mode |cffff4444DESATIVADO|r")
    end
end

-- ============================================================
-- Detecção de Chat Aberto (bloqueia atalhos durante digitação)
-- ============================================================
function KB:OnChatActivated()
    KB.chatActive = true
    CM.logger:Log("Chat ABERTO - Atalhos do controle desativados")
end

function KB:OnChatDeactivated()
    KB.chatActive = false
    CM.logger:Log("Chat FECHADO - Atalhos do controle reativados")
end

-- ============================================================
-- Modo Navegação: swap D-Pad para cursor quando janela abre
-- ============================================================
function KB:EnterNavigationMode()
    if KB.navigationMode then return end
    KB.navigationMode = true

    -- Salva bindings atuais do D-Pad das 5 páginas
    KB.savedNavBindings = {}
    for page = 1, 5 do
        for _, btn in ipairs({"DUP","DDOWN","DLEFT","DRIGHT"}) do
            local bindName = "CM_ACTION_" .. btn .. "_" .. page
            KB.savedNavBindings[bindName] = GetBindingKey(bindName)
        end
        -- Salva também A e B para confirmar/cancelar
        KB.savedNavBindings["CM_ACTION_A_" .. page] = GetBindingKey("CM_ACTION_A_" .. page)
        KB.savedNavBindings["CM_ACTION_B_" .. page] = GetBindingKey("CM_ACTION_B_" .. page)
    end

    -- Aplica bindings de navegação no D-Pad (sem modificador por enquanto)
    SetBinding(defaults[1].DUP,    "CM_CURSOR_UP")
    SetBinding(defaults[1].DDOWN,  "CM_CURSOR_DOWN")
    SetBinding(defaults[1].DLEFT,  "CM_CURSOR_LEFT")
    SetBinding(defaults[1].DRIGHT, "CM_CURSOR_RIGHT")
    SetBinding(defaults[1].A,      "CM_CURSOR_CONFIRM")
    SetBinding(defaults[1].B,      "CM_CURSOR_CANCEL")

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Keybindings]|r Modo Navegacao ATIVADO (7,8,9,0 = D-Pad | Space = A | 3 = B)")
    CM.logger:Log("Modo NAVEGAÇÃO ativado - D-Pad = cursor UI, A = Confirmar, B = Cancelar")
end

function KB:ExitNavigationMode()
    if not KB.navigationMode then return end
    KB.navigationMode = false

    -- Restaura bindings originais do D-Pad
    for bindName, key in pairs(KB.savedNavBindings) do
        if key then
            SetBinding(key, bindName)
        end
    end
    KB.savedNavBindings = {}

    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[CM Keybindings]|r Modo Navegacao DESATIVADO (Combate restaurado)")
    CM.logger:Log("Modo HOTKEY restaurado - D-Pad = ações de combate")
end

-- ============================================================
-- Funções Globais chamadas pelo Bindings.xml
-- ============================================================
function CM_Action(button, page)
    if CM.keybindings.chatActive then return end
    CM.logger:Log("Ação: Página " .. page .. " | Botão " .. button)
    
    -- Botao A na pagina 1 (Base/Sem modificador) = Pulo padrão do WoW
    if page == 1 and button == "A" then
        JumpOrAscendStart()
    end
end

function CM_Fixed(button)
    if CM.keybindings.chatActive and button ~= "L1" then return end
    CM.logger:Log("Fixo: " .. button)
end

function CM_ToggleMouseMode()
    CM.keybindings:ToggleMouseMode()
end

function CM_MouseRight()
    CM.logger:Log("R3: Clique Direito do Mouse")
end

function CM_CursorMove(direction)
    if CM.keybindings.chatActive then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM Key]|r D-Pad: " .. tostring(direction))
    CM.logger:Log("Cursor: Mover " .. tostring(direction))
    if CM.cursor and CM.cursor.MoveDirection then
        CM.cursor:MoveDirection(direction)
    end
end

function CM_CursorConfirm()
    if CM.keybindings.chatActive then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Key]|r Botao A (Confirmar/Clicar)")
    CM.logger:Log("Cursor: Confirmar (A)")
    if CM.cursor and CM.cursor.Click then
        CM.cursor:Click("LeftButton")
    end
end

function CM_CursorCancel()
    if CM.keybindings.chatActive then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Key]|r Botao B (Cancelar/Fechar)")
    CM.logger:Log("Cursor: Cancelar (B)")
    if CM.cursor and CM.cursor.Click then
        CM.cursor:Click("RightButton")
    end
end

-- ============================================================
-- Menu Ring (L2 + R2 + A) — IMPLEMENTAÇÃO FUTURA
-- ============================================================
function CM_OpenRingMenu()
    if CM.keybindings.chatActive then return end
    CM.logger:Log("Menu Ring: Abrir (L2+R2+A) — Em desenvolvimento!")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Menu Ring |cffffcc00em breve!|r")
end
