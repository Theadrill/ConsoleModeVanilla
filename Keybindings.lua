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
    CM_FIXED_L1     = "TAB",
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

-- Inicialização e garantia de bindings de interface
function KB:Initialize()
    -- Mantém ESCAPE como tecla primária do menu e define F11 para o Start do controle
    SetBinding("ESCAPE", "TOGGLEGAMEMENU")
    SetBinding("F11", "CM_FIXED_START")
    
    -- Atalhos de controle com modificadores (L2/R2 + Select/Start)
    SetBinding("SHIFT-M", "CM_UI_CHARACTER")     -- L2 + Select (Personagem)
    SetBinding("SHIFT-F11", "CM_UI_BAGS")        -- L2 + Start (Bolsas)
    SetBinding("ALT-M", "CM_UI_TALENTS")         -- R2 + Select (Talentos)
    SetBinding("ALT-F11", "CM_UI_SPELLBOOK")     -- R2 + Start (Livro de Magias)
    
    -- Smart Mouse Look Companion (acionado pelo Steam Input ao mover WASD)
    SetBinding("F9", "CM_MOUSELOOK_START")
    
    -- Aplica bindings customizados salvos no ConsoleModeDB
    self:ApplyCustomBindings()
    
    CM.logger:Log("Atalhos de Interface e MouseLook F9 inicializados.")
end

-- ============================================================
-- Aplica os bindings customizados salvos pelo jogador
-- ============================================================
function KB:ApplyCustomBindings()
    if not ConsoleModeDB or not ConsoleModeDB.customBindings then return end
    for key, action in pairs(ConsoleModeDB.customBindings) do
        if key and action and action ~= "" then
            SetBinding(key, action)
            if self.savedNavBindings then
                self.savedNavBindings[key] = action
            end
        end
    end
    SaveBindings(GetCurrentBindingSet())
end

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
        "TAB",
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
            elseif key == "TAB" then
                KB.savedNavBindings[key] = "TARGETNEARESTEMY"
            end
        end
    end

    -- Aplica bindings de navegação no D-Pad, botões A, B e L1/R1
    SetBinding(defaults[1].DUP,    "CM_CURSOR_UP")
    SetBinding(defaults[1].DDOWN,  "CM_CURSOR_DOWN")
    SetBinding(defaults[1].DLEFT,  "CM_CURSOR_LEFT")
    SetBinding(defaults[1].DRIGHT, "CM_CURSOR_RIGHT")
    SetBinding(defaults[1].A,      "CM_CURSOR_CONFIRM")
    SetBinding(defaults[1].B,      "CM_CURSOR_CANCEL")
    SetBinding("TAB",              "CM_CURSOR_CLICK_LEFT")

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Keybindings]|r Modo Navegacao ATIVADO (D-Pad = Navegar | A = Confirmar | B = Cancelar | L1 = Left Click)")
    CM.logger:Log("Modo NAVEGAÇÃO ativado - D-Pad = cursor UI, A = Confirmar, B = Cancelar, L1 = Clique Esquerdo")
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
        "TAB",
    }

    -- Restaura bindings originais de cada tecla
    for _, key in ipairs(keysToRestore) do
        local originalAction = KB.savedNavBindings[key]
        if not originalAction or originalAction == "" then
            originalAction = ConsoleModeDB and ConsoleModeDB.customBindings and ConsoleModeDB.customBindings[key]
        end
        
        if originalAction and originalAction ~= "" then
            SetBinding(key, originalAction)
        else
            -- Fallbacks seguros caso não estivesse salvo
            if key == defaults[1].A then
                SetBinding(key, "JUMP")
            elseif key == defaults[1].B then
                SetBinding(key, "ACTIONBUTTON3")
            elseif key == "TAB" then
                SetBinding(key, "TARGETNEARESTEMY")
            elseif key == defaults[1].DUP then
                SetBinding(key, "CM_ACTION_DUP_1")
            elseif key == defaults[1].DDOWN then
                SetBinding(key, "CM_ACTION_DDOWN_1")
            elseif key == defaults[1].DLEFT then
                SetBinding(key, "CM_ACTION_DLEFT_1")
            elseif key == defaults[1].DRIGHT then
                SetBinding(key, "CM_ACTION_DRIGHT_1")
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
    CM.logger:Log("Ação: Página " .. page .. " | Botão " .. button)
    
    -- Botao A na pagina 1 (Base/Sem modificador) = Pulo padrão do WoW
    if page == 1 and button == "A" then
        JumpOrAscendStart()
    end
end

function CM_Fixed(button)
    if CM.keybindings.chatActive and button ~= "L1" then return end
    CM.logger:Log("Fixo: " .. button)
    
    if button == "START" then
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
        
        -- 5. Se nenhuma janela estava aberta e sem alvo, abre o Menu do Jogo
        ShowUIPanel(GameMenuFrame)
        
    elseif button == "SELECT" then
        ToggleWorldMap()
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

function CM_CursorMove(direction)
    if CM.keybindings.chatActive then return end
    
    -- Proteção: se o cursor não estiver ativo em nenhuma janela, desativa modo navegação
    if not CM.cursor or not CM.cursor.state.enabled or not CM.cursor.state.currentButton then
        CM.keybindings:ExitNavigationMode()
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM Key]|r D-Pad: " .. tostring(direction))
    CM.logger:Log("Cursor: Mover " .. tostring(direction))
    CM.cursor:MoveDirection(direction)
end

function CM_CursorConfirm()
    if CM.keybindings.chatActive then return end
    
    -- Proteção: se o cursor não estiver ativo em nenhuma janela, força saída e pula
    if not CM.cursor or not CM.cursor.state.enabled or not CM.cursor.state.currentButton then
        CM.keybindings:ExitNavigationMode()
        JumpOrAscendStart()
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Key]|r Botao A (Confirmar/Clicar)")
    CM.logger:Log("Cursor: Confirmar (A)")
    CM.cursor:Click("LeftButton")
end

function CM_CursorCancel()
    if CM.keybindings.chatActive then return end
    
    -- 1. Se estiver com item ou magia no cursor do mouse, limpa a mão
    if CursorHasItem() or CursorHasSpell() then
        ClearCursor()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Key]|r Botao B (Item no cursor limpo)")
        return
    end
    
    -- 2. Fecha a janela de UI ativa usando método oficial do WoW
    if CM.hooks and CM.hooks.CloseTopFrame and CM.hooks:CloseTopFrame() then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[CM Key]|r Botao B (Janela fechada)")
        return
    end
    
    -- 3. Fallback: Se nenhuma janela fechou, desativa modo de navegação
    if CM.keybindings and CM.keybindings.ExitNavigationMode then
        CM.keybindings:ExitNavigationMode()
    end
end

function CM_CursorClickLeft()
    if CM.keybindings.chatActive then return end
    if not CM.cursor or not CM.cursor.state.enabled or not CM.cursor.state.currentButton then
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Key]|r L1: Clique Esquerdo")
    CM.cursor:Click("LeftButton")
end

function CM_CursorClickRight()
    if CM.keybindings.chatActive then return end
    if not CM.cursor or not CM.cursor.state.enabled or not CM.cursor.state.currentButton then
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CM Key]|r R1: Clique Direito")
    CM.cursor:Click("RightButton")
end

-- ============================================================
-- Menu Ring (L2 + R2 + A) — IMPLEMENTAÇÃO FUTURA
-- ============================================================
function CM_OpenRingMenu()
    if CM.keybindings.chatActive then return end
    CM.logger:Log("Menu Ring: Abrir (L2+R2+A) — Em desenvolvimento!")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ConsoleMode]|r Menu Ring |cffffcc00em breve!|r")
end
