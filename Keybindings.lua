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

-- Atalhos de Interface
_G["BINDING_HEADER_CONSOLEMODEUI"]      = "ConsoleMode - Atalhos de Interface"
_G["BINDING_NAME_CM_UI_CHARACTER"]      = "L2 + Select (Personagem - C)"
_G["BINDING_NAME_CM_UI_BAGS"]           = "L2 + Start (Bolsas - B)"
_G["BINDING_NAME_CM_UI_TALENTS"]        = "R2 + Select (Talentos - N)"
_G["BINDING_NAME_CM_UI_SPELLBOOK"]      = "R2 + Start (Livro de Magias - P)"

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
    -- Page 5: L2+R2 = ALT+SHIFT (ordem canônica da Blizzard)
    [5] = {
        A      = "ALT-SHIFT-SPACE",
        X      = "ALT-SHIFT-1",
        Y      = "ALT-SHIFT-2",
        B      = "ALT-SHIFT-3",
        DUP    = "ALT-SHIFT-7",
        DDOWN  = "ALT-SHIFT-8",
        DLEFT  = "ALT-SHIFT-9",
        DRIGHT = "ALT-SHIFT-0",
    },
}

-- Defaults fixos e atalhos de interface
-- L2 = SHIFT | R2 = ALT | R1 = CTRL
-- SELECT = M | START = F11 (com ESCAPE mantido no teclado como padrão)
local fixedDefaults = {
    CM_FIXED_SELECT = "M",
    CM_FIXED_START  = "F11",
    CM_UI_CHARACTER = "SHIFT-M",      -- L2 + Select (C)
    CM_UI_BAGS      = "SHIFT-F11",    -- L2 + Start (B)
    CM_UI_TALENTS   = "ALT-M",        -- R2 + Select (N)
    CM_UI_SPELLBOOK = "ALT-F11",      -- R2 + Start (P)
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
KB.defaults         = defaults

-- Inicialização e garantia de bindings de interface
function KB:Initialize()
    -- Mantém ESCAPE como tecla primária do menu e define F11 para o Start do controle
    SetBinding("ESCAPE", "TOGGLEGAMEMENU")
    SetBinding("F11", "CM_FIXED_START")
    
    -- Tecla M e Select vinculadas ao Menu Principal na aba Missões & Mapa
    SetBinding("M", "CM_FIXED_SELECT")
    SetBinding("m", "CM_FIXED_SELECT")
    
    -- Atalhos de controle com modificadores (L2/R2 + Select/Start)
    SetBinding("SHIFT-M", "CM_UI_CHARACTER")     -- L2 + Select (Personagem)
    SetBinding("SHIFT-F11", "CM_UI_BAGS")        -- L2 + Start (Bolsas)
    SetBinding("ALT-M", "CM_UI_TALENTS")         -- R2 + Select (Talentos)
    SetBinding("ALT-F11", "CM_UI_SPELLBOOK")     -- R2 + Start (Livro de Magias)
    
    -- Smart Mouse Look Companion (acionado pelo Steam Input ao mover WASD)
    SetBinding("F9", "CM_MOUSELOOK_START")
    
    -- Vincula TAB ao Smart Tab inteligente (L1: Aba Anterior em menus / Target em combate)
    SetBinding("TAB", "CM_SMART_TAB")
    
    -- AutoRun: = (padrão WoW), ALT-7 (R2 + D-Pad Up do profile) e ALT-UP
    SetBinding("=", "TOGGLEAUTORUN")
    SetBinding("ALT-7", "TOGGLEAUTORUN")
    SetBinding("ALT-UP", "TOGGLEAUTORUN")
    SetBinding("NUMPADMULTIPLY", "TOGGLEAUTORUN")
    
    -- Roteamento Automático de Interação com a DLL Interact.dll (R2 + A = ALT-SPACE)
    if type(InteractNearest) == "function" then
        SetBinding("ALT-SPACE", "CM_INTERACT")
        CM.logger:Log("Interact.dll detectada! R2 + A configurado automaticamente para Interagir.")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ConsoleMode]|r Interact DLL detectada! |cffffcc00R2 + A|r vinculado para Interagir.")
    end
    
    CM.logger:Log("Atalhos de Interface e Smart TAB inicializados.")
end

-- ============================================================
-- Frame de Escuta de Modificadores (R1 / CTRL = Abas, L2 / SHIFT e R2 / ALT = Filtros)
-- ============================================================
local modFrame = CreateFrame("Frame", "ConsoleModeModFrame", UIParent)
local wasCtrlDown = false
local wasShiftDown = false
local wasAltDown = false

modFrame:SetScript("OnUpdate", function()
    local ctrlNow = IsControlKeyDown()
    local shiftNow = IsShiftKeyDown()
    local altNow = IsAltKeyDown()

    local isNav = (KB and KB.navigationMode) or (ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible())

    if isNav and not (KB and KB.chatActive) then
        local mm = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
        local isQuestsTab = (ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible()) and (mm and mm.tabContainer and mm.tabContainer.currentTab == "QUESTS")

        -- 1. R1 (CTRL) = Próxima Aba Principal
        if ctrlNow and not wasCtrlDown then
            if CM.cursor and CM.cursor.CycleTabs then
                CM.cursor:CycleTabs(1)
            end
        end

        -- 2. L2 (SHIFT / LT) = Zoom Out no mapa ou Sub-Aba Anterior
        if shiftNow and not wasShiftDown then
            if isQuestsTab and mm and mm.MapZoomStep then
                mm:MapZoomStep(-1)
            elseif CM.cursor and CM.cursor.CycleSubTabs then
                CM.cursor:CycleSubTabs(-1)
            end
        end

        -- 3. R2 (ALT / RT) = Zoom In no mapa ou Próxima Sub-Aba
        if altNow and not wasAltDown then
            if isQuestsTab and mm and mm.MapZoomStep then
                mm:MapZoomStep(1)
            elseif CM.cursor and CM.cursor.CycleSubTabs then
                CM.cursor:CycleSubTabs(1)
            end
        end
    end

    wasCtrlDown = ctrlNow
    wasShiftDown = shiftNow
    wasAltDown = altNow
end)

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
    if CM.camera and CM.camera.ToggleMouseMode then
        CM.camera:ToggleMouseMode()
        KB.mouseModeActive = CM.camera.disabledByMouseMode
    else
        KB.mouseModeActive = not KB.mouseModeActive
        if KB.mouseModeActive then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Mouse Mode |cff00ff00ATIVADO|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Mouse Mode |cffff4444DESATIVADO|r")
        end
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

    local Cursor = CM.cursor or (ConsoleMode and ConsoleMode.cursor)
    local Hooks = ConsoleMode and ConsoleMode.hooks
    if (Cursor and Cursor.IsAnyMacroOpen and Cursor:IsAnyMacroOpen()) or
       (Hooks and Hooks.IsAnyMacroOpen and Hooks:IsAnyMacroOpen()) then
        return
    end

    KB.navigationMode = true

    -- Destrava o mouselook ao abrir interfaces
    if CM_MouseLookStop then CM_MouseLookStop() end

    local keysToOverride = {
        defaults[1].DUP,
        defaults[1].DDOWN,
        defaults[1].DLEFT,
        defaults[1].DRIGHT,
        defaults[1].A,
        defaults[1].B,
        defaults[1].X,
        defaults[1].Y,
    }

    -- Salva a ação real que cada tecla executava antes
    KB.savedNavBindings = {}
    for _, key in ipairs(keysToOverride) do
        local action = GetBindingAction(key)
        if action and action ~= "" and not string.find(action, "^CM_CURSOR_") then
            KB.savedNavBindings[key] = action
        else
            if key == defaults[1].A then
                KB.savedNavBindings[key] = "JUMP"
            elseif key == defaults[1].B then
                KB.savedNavBindings[key] = "ACTIONBUTTON3"
            elseif key == defaults[1].X then
                KB.savedNavBindings[key] = "ACTIONBUTTON1"
            elseif key == defaults[1].Y then
                KB.savedNavBindings[key] = "ACTIONBUTTON2"
            end
        end
    end

    -- Aplica bindings de navegação no D-Pad e botões A, B, X, Y
    SetBinding(defaults[1].DUP,    "CM_CURSOR_UP")
    SetBinding(defaults[1].DDOWN,  "CM_CURSOR_DOWN")
    SetBinding(defaults[1].DLEFT,  "CM_CURSOR_LEFT")
    SetBinding(defaults[1].DRIGHT, "CM_CURSOR_RIGHT")
    SetBinding(defaults[1].A,      "CM_CURSOR_CONFIRM")   -- A: Clicar / Pegar Item
    SetBinding(defaults[1].B,      "CM_CURSOR_CANCEL")    -- B: Fechar / Cancelar
    SetBinding(defaults[1].Y,      "CM_CURSOR_USE")       -- Y: Usar Item / Botao Direito
    SetBinding(defaults[1].X,      "CM_CURSOR_SECONDARY") -- X: Acao Secundaria / Dividir

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Keybindings]|r Modo Navegacao ATIVADO (D-Pad = Navegar | A = Clicar | Y = Usar Item | B = Cancelar)")
    CM.logger:Log("Modo NAVEGAÇÃO ativado - D-Pad = cursor UI, A = Confirmar, Y = Usar Item, B = Cancelar")
end

function KB:ExitNavigationMode()
    if not KB.navigationMode then return end
    KB.navigationMode = false

    local keysToRestore = {
        defaults[1].DUP,
        defaults[1].DDOWN,
        defaults[1].DLEFT,
        defaults[1].DRIGHT,
        defaults[1].A,
        defaults[1].B,
        defaults[1].X,
        defaults[1].Y,
    }

    -- Restaura bindings originais de cada tecla
    for _, key in ipairs(keysToRestore) do
        local originalAction = KB.savedNavBindings[key]
        if originalAction and originalAction ~= "" and not string.find(originalAction, "^CM_CURSOR_") then
            SetBinding(key, originalAction)
        else
            if key == defaults[1].A then
                SetBinding(key, "JUMP")
            elseif key == defaults[1].B then
                SetBinding(key, "ACTIONBUTTON3")
            elseif key == defaults[1].X then
                SetBinding(key, "ACTIONBUTTON1")
            elseif key == defaults[1].Y then
                SetBinding(key, "ACTIONBUTTON2")
            end
        end
    end
    KB.savedNavBindings = {}

    -- Atualiza ActionHUD imediatamente
    if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.Update then
        CM.ui.actionHUD:Update()
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[CM Keybindings]|r Modo Navegacao DESATIVADO (Combate restaurado)")
    CM.logger:Log("Modo HOTKEY restaurado - D-Pad = ações de combate")
end

-- ============================================================
-- Funções Globais chamadas pelo Bindings.xml
-- ============================================================
function CM_Action(button, page)
    if CM.keybindings.chatActive then return end
    CM.logger:Log("Acao: Pagina " .. page .. " | Botao " .. button)

    -- Botao A na pagina 1 (Base/Sem modificador) = Pulo padrao do WoW
    if page == 1 and button == "A" then
        if Jump then Jump() end
        return
    end

    -- Botao A na pagina 2 (L2) no QUESTS = Confirmar selecao no mapa
    if page == 2 and button == "A" then
        local mm = (ConsoleMode and ConsoleMode.mainMenu) or nil
        if ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible() and mm and mm.tabContainer and mm.tabContainer.currentTab == "QUESTS" then
            if mm.OnMapPinClick then mm:OnMapPinClick() end
            return
        end
    end

    -- Botao X na pagina 1 (Base) no QUESTS = Rastrear/Parar Rastrear missao selecionada
    if page == 1 and button == "X" then
        local mm = (ConsoleMode and ConsoleMode.mainMenu) or nil
        if ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible() and mm and mm.tabContainer and mm.tabContainer.currentTab == "QUESTS" then
            if mm.selectedQuestIndex and mm.ToggleQuestWatch then
                mm:ToggleQuestWatch(mm.selectedQuestIndex)
            end
            return
        end
    end

    -- Botao Y na pagina 1 (Base) no QUESTS = Menu de contexto da missao
    if page == 1 and button == "Y" then
        local mm = (ConsoleMode and ConsoleMode.mainMenu) or nil
        if ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible() and mm and mm.tabContainer and mm.tabContainer.currentTab == "QUESTS" then
            if mm.IsQuestDetailVisible and mm:IsQuestDetailVisible() then return end
            if mm.selectedQuestIndex and mm.OpenQuestContextMenu then
                mm:OpenQuestContextMenu(mm.selectedQuestIndex)
            end
            return
        end
    end
end

function CM_Fixed(button)
    if CM.keybindings.chatActive and button ~= "L1" then return end
    CM.logger:Log("Fixo: " .. button)
    
    if button == "START" then
        if ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible() then
            local mm2 = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
            if mm2 and mm2.IsQuestDetailVisible and mm2:IsQuestDetailVisible() then mm2:HideQuestDetail(); return end
            if mm2 and mm2.HandleMapBack and mm2:HandleMapBack() then return end
            if ConsoleMode.mainMenu and ConsoleMode.mainMenu.Hide then
                ConsoleMode.mainMenu:Hide()
            else
                ConsoleModeMainMenuFrame:Hide()
            end
            return
        end

        -- 1. Se o GameMenuFrame ja estiver aberto, fecha
        if GameMenuFrame and GameMenuFrame:IsVisible() then
            HideUIPanel(GameMenuFrame)
            return
        end
        
        -- 2. Se houver item ou feitiço preso no cursor, limpa a mão
        if CursorHasItem() or CursorHasSpell() then
            ClearCursor()
            return
        end
        
        -- 3. Tenta fechar qualquer janela de UI aberta
        if CM.hooks and CM.hooks.CloseTopFrame and CM.hooks:CloseTopFrame() then
            return
        end
        
        -- 4. Se houver um alvo selecionado, deseleciona (Clear Target igual ao ESC)
        if UnitExists("target") then
            ClearTarget()
            return
        end
        
        -- 5. Se nenhuma janela estava aberta e sem alvo, abre o Console Main Menu!
        if ConsoleMode.mainMenu and ConsoleMode.mainMenu.Show then
            ConsoleMode.mainMenu:Show()
        else
            ShowUIPanel(GameMenuFrame)
        end
        
    elseif button == "SELECT" then
        local mm = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
        if mm and mm.Toggle then
            mm:Toggle("QUESTS")
        else
            ToggleWorldMap()
        end
    elseif button == "L1" then
        TargetNearestEnemy()
    end
end

function CM_MouseLookStart()
    if CM.keybindings.chatActive or CM.keybindings.navigationMode then return end
    if MouselookStart and (not IsMouselooking or not IsMouselooking()) then
        pcall(MouselookStart)
    end
end

function CM_MouseLookStop()
    if MouselookStop and IsMouselooking() then
        pcall(MouselookStop)
    end
end

function CM_ToggleMouseMode()
    if IsMouselooking() then
        CM_MouseLookStop()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Mouse Mode: |cff00ff00ATIVADO|r (Cursor Livre)")
    else
        CM_MouseLookStart()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Mouse Mode: |cffff4444DESATIVADO|r (Câmera no Analógico)")
    end
end

function CM_MouseRight()
    CM_MouseLookStop()
    CM.logger:Log("R3: Clique Direito do Mouse (Mouselook Destravado)")
end

-- ============================================================
-- Modo de Controle Livre do Mapa (L-Stick / WASD / D-Pad)
-- ============================================================
function KB:EnterMapMode()
    if self.mapModeActive then return end
    self.mapModeActive = true
    self.savedMapBindings = {
        W = GetBindingAction("W"),
        w = GetBindingAction("w"),
        A = GetBindingAction("A"),
        a = GetBindingAction("a"),
        S = GetBindingAction("S"),
        s = GetBindingAction("s"),
        D = GetBindingAction("D"),
        d = GetBindingAction("d"),
        UP = GetBindingAction("UP"),
        DOWN = GetBindingAction("DOWN"),
        LEFT = GetBindingAction("LEFT"),
        RIGHT = GetBindingAction("RIGHT"),
    }
    SetBinding("W", "CM_MAP_UP")
    SetBinding("w", "CM_MAP_UP")
    SetBinding("S", "CM_MAP_DOWN")
    SetBinding("s", "CM_MAP_DOWN")
    SetBinding("A", "CM_MAP_LEFT")
    SetBinding("a", "CM_MAP_LEFT")
    SetBinding("D", "CM_MAP_RIGHT")
    SetBinding("d", "CM_MAP_RIGHT")
    SetBinding("UP", "CM_MAP_UP")
    SetBinding("DOWN", "CM_MAP_DOWN")
    SetBinding("LEFT", "CM_MAP_LEFT")
    SetBinding("RIGHT", "CM_MAP_RIGHT")
end

function KB:ExitMapMode()
    if not self.mapModeActive then return end
    self.mapModeActive = false
    if self.savedMapBindings then
        for key, action in pairs(self.savedMapBindings) do
            if action and action ~= "" then
                SetBinding(key, action)
            else
                SetBinding(key, nil)
            end
        end
        self.savedMapBindings = nil
    end
    local mm = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
    if mm then
        mm.stickPanX = 0
        mm.stickPanY = 0
    end
end

function CM_ToggleUI(uiType)
    if CM.keybindings.chatActive then return end
    CM.logger:Log("UI Toggle: " .. tostring(uiType))
    
    if uiType == "Character" then
        ToggleCharacter("PaperDollFrame")
    elseif uiType == "Bags" then
        if OpenAllBags then
            local allOpen = false
            for i = 0, 4 do
                if IsBagOpen(i) then
                    allOpen = true
                    break
                end
            end
            if allOpen then
                CloseAllBags()
            else
                OpenAllBags()
            end
        else
            ToggleBackpack()
        end
    elseif uiType == "Talents" then
        if ToggleTalentFrame then
            ToggleTalentFrame()
        elseif TalentFrame_LoadUI then
            TalentFrame_LoadUI()
            ShowUIPanel(TalentFrame)
        end
    elseif uiType == "SpellBook" then
        ToggleSpellBook(BOOKTYPE_SPELL)
    end
end

function CM_MapPanStick(direction, keystate)
    if CM.keybindings and CM.keybindings.chatActive then return end
    local mm = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
    if mm and mm.OnStickPan then
        mm:OnStickPan(direction, keystate)
    end
end

function CM_CursorMove(direction, keystate)
    if CM.keybindings and CM.keybindings.chatActive then return end

    -- Proteção: se o cursor não estiver ativo em nenhuma janela, desativa modo navegação
    if not CM.cursor or not CM.cursor.state.enabled or not CM.cursor.state.currentButton then
        CM.keybindings:ExitNavigationMode()
        return
    end
    
    if keystate == "up" then
        if CM.cursor.StopRepeat then
            CM.cursor:StopRepeat(direction)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM Key]|r D-Pad: " .. tostring(direction))
        CM.logger:Log("Cursor: Mover " .. tostring(direction))
        if CM.cursor.StartRepeat then
            CM.cursor:StartRepeat(direction)
        else
            CM.cursor:MoveDirection(direction)
        end
    end
end

function CM_CursorConfirm()
    if CM.keybindings.chatActive then return end
    
    if not CM.cursor or not CM.cursor.state.enabled then
        if Jump then Jump() end
        return
    end

    -- Se o Menu de Contexto estiver no modo SPLIT, [A] confirma o split
    local ctxMenu = CM.ui and CM.ui.contextMenu
    if ctxMenu and ctxMenu.frame and ctxMenu.frame:IsVisible() and ctxMenu.currentMode == "SPLIT" then
        ctxMenu:ConfirmSplit()
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Key]|r Botao A (Confirmar/Clicar)")
    CM.logger:Log("Cursor: Confirmar (A)")
    CM.cursor:Click("LeftButton")
end

function CM_CursorUse()
    if CM.keybindings.chatActive then return end
    if CM.ui and CM.ui.contextMenu and CM.ui.contextMenu.frame and CM.ui.contextMenu.frame:IsVisible() then
        CM.ui.contextMenu:Close()
        return
    end
    local mm = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
    if ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible() and mm and mm.tabContainer and mm.tabContainer.currentTab == "QUESTS" then
        if mm.IsQuestDetailVisible and mm:IsQuestDetailVisible() then return end
        local sel = mm.selectedQuestIndex
        if sel and sel > 0 then
            local t, _, _, isHeader = GetQuestLogTitle(sel)
            if t and not isHeader then
                mm:OpenQuestContextMenu(sel)
                return
            end
        end
    end
    if not CM.cursor or not CM.cursor.state.enabled or not CM.cursor.state.currentButton then
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Key]|r Botao Y (Usar Item / Botao Direito)")
    CM.logger:Log("Cursor: Usar Item / Botao Direito (Y)")
    CM.cursor:Click("RightButton")
end

function CM_CursorSecondary()
    if CM.keybindings.chatActive then return end
    
    if CursorHasItem() or CursorHasSpell() then
        ClearCursor()
        return
    end
    
    if CM.cursor and CM.cursor.state and CM.cursor.state.currentButton then
        local btn = CM.cursor.state.currentButton
        if btn and btn.Click then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Key]|r Botao X (Acao Secundaria)")
            btn:Click("LeftButton")
        end
    end
end

function CM_CursorCancel()
    if CM.keybindings.chatActive then return end
    local mmQ = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
    if mmQ and mmQ.IsQuestDetailVisible and mmQ:IsQuestDetailVisible() then
        mmQ:HideQuestDetail()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Key]|r Botao B (Detalhes da Missao)")
        return
    end
    -- 0. Se o Menu de Contexto estiver aberto
    local ctxMenu = CM.ui and CM.ui.contextMenu
    if ctxMenu and ctxMenu.frame and ctxMenu.frame:IsVisible() then
        if ctxMenu.currentMode == "SPLIT" then
            ctxMenu:SwitchToMenuView()
        else
            ctxMenu:Close()
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Key]|r Botao B (Menu de Contexto)")
        return
    end

    -- Se a janela de Dividir Pilha (StackSplitFrame) estiver aberta, fecha ela
    if StackSplitFrame and StackSplitFrame:IsVisible() then
        if StackSplitCancelButton and StackSplitCancelButton.Click then
            StackSplitCancelButton:Click()
        else
            StackSplitFrame:Hide()
        end
        return
    end

    -- 1. Se estiver com item ou magia no cursor do mouse, limpa a mão
    if CursorHasItem() or CursorHasSpell() then
        ClearCursor()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Key]|r Botao B (Item no cursor limpo)")
        return
    end
    
    local mm = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
    if mm and mm.HandleMapBack and ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible() then
        if mm:HandleMapBack() then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Key]|r Botao B (Mapa: voltar)")
            return
        end
    end
    if CM.hooks and CM.hooks.CloseTopFrame and CM.hooks:CloseTopFrame() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Key]|r Botao B (Janela fechada)")
        return
    end
    
    -- 3. Fallback: Se nenhuma janela fechou, desativa modo de navegação
    if CM.keybindings and CM.keybindings.ExitNavigationMode then
        CM.keybindings:ExitNavigationMode()
    end
end

function CM_NavNextTab()
    if CM.keybindings.chatActive then return end
    if CM.cursor and CM.cursor.CycleTabs then
        CM.cursor:CycleTabs(1)
    end
end

function CM_NavPrevTab()
    if CM.keybindings.chatActive then return end
    if CM.cursor and CM.cursor.CycleTabs then
        CM.cursor:CycleTabs(-1)
    end
end

function CM_NavNextSubTab()
    if CM.keybindings and CM.keybindings.chatActive then return end
    local mm = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
    if ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible() and mm and mm.tabContainer and mm.tabContainer.currentTab == "QUESTS" then
        if mm.MapZoomStep then mm:MapZoomStep(1) end
        return
    end
    if CM.cursor and CM.cursor.CycleSubTabs then
        CM.cursor:CycleSubTabs(1)
    end
end

function CM_NavPrevSubTab()
    if CM.keybindings and CM.keybindings.chatActive then return end
    local mm = (ConsoleMode and ConsoleMode.mainMenu) or _G["ConsoleModeMainMenu"]
    if ConsoleModeMainMenuFrame and ConsoleModeMainMenuFrame:IsVisible() and mm and mm.tabContainer and mm.tabContainer.currentTab == "QUESTS" then
        if mm.MapZoomStep then mm:MapZoomStep(-1) end
        return
    end
    if CM.cursor and CM.cursor.CycleSubTabs then
        CM.cursor:CycleSubTabs(-1)
    end
end

function CM_SmartTab()
    if CM.keybindings and CM.keybindings.chatActive then return end
    
    -- 1. Se estiver no modo de navegação com janelas abertas: Aba Anterior (L1)
    if CM.keybindings and CM.keybindings.navigationMode then
        if CM.cursor and CM.cursor.CycleTabs then
            local cycled = CM.cursor:CycleTabs(-1)
            if cycled then return end
        end
    end
    
    -- 2. Modo Combate / Mundo Aberto: Target Nearest Enemy nativo
    TargetNearestEnemy()
end

-- ============================================================
-- Interação Automática via Interact.dll (R2 + A)
-- ============================================================
function CM_Interact(autoLoot)
    if CM.keybindings and CM.keybindings.chatActive then return end
    if type(InteractNearest) == "function" then
        local mode = autoLoot or 0
        InteractNearest(mode)
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
