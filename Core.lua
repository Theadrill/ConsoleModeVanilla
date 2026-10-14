--[[
    ConsoleMode - Vanilla
    Core.lua

    Inicialização principal do addon.
    Cria o frame global ConsoleMode que todos os módulos usam.
]]

_G = getfenv(0)

-- Polyfill para string.match no Lua 5.0 (WoW 1.12 / Vanilla)
if not string.match then
    string.match = function(str, pattern, init)
        if not str then return nil end
        local _, _, c1, c2, c3, c4, c5 = string.find(str, pattern, init)
        if c1 ~= nil then return c1, c2, c3, c4, c5 end
        local s, e = string.find(str, pattern, init)
        if s then return string.sub(str, s, e) end
        return nil
    end
end

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
    
    DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_POS_RESET_FMT"), info.friendlyName))
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function CM.ui:ResetAllPositions()
    for key, _ in pairs(CM.ui.registeredFrames) do
        CM.ui:ResetPosition(key)
    end
    DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_POS_ALL"))
end

-- Registra eventos principais
CM:RegisterEvent("ADDON_LOADED")
CM:RegisterEvent("VARIABLES_LOADED")
CM:RegisterEvent("PLAYER_ENTERING_WORLD")
CM:RegisterEvent("PLAYER_LOGOUT")

CM:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "ConsoleModeVanilla" then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ff00[ConsoleMode]|r " .. format(CM:T("MSG_LOADED_FMT"), CM.version)
        )

    elseif event == "VARIABLES_LOADED" then
        ConsoleModeDB = ConsoleModeDB or {}
        if not ConsoleModeDB.lang or not CM_Langs or not CM_Langs[ConsoleModeDB.lang] then
            local defLang = "ptBR"
            if type(GetLocale) == "function" then
                local g = GetLocale()
                if g and CM_Langs and CM_Langs[g] then
                    defLang = g
                end
            end
            ConsoleModeDB.lang = defLang
        end
        if CM.ResolveLocale then
            CM:ResolveLocale()
        end
        if ConsoleModeDB.showRightActionBars == nil then
            ConsoleModeDB.showRightActionBars = true
        end
        if ConsoleModeDB.enableAUXSupport == nil then
            ConsoleModeDB.enableAUXSupport = true
        end
        -- Sincroniza a config do cursor com ConsoleModeDB
        if CM.cursor and CM.cursor.config then
            CM.cursor.config.enableAUX = (ConsoleModeDB.enableAUXSupport ~= false)
        end
        -- DEFAULT_CHAT_FRAME:AddMessage("|cffff6600[CM]|r " .. CM:T("MSG_VARIABLES_LOADED")) -- NOLOG
        
        -- ✅ CRÍTICO: Verificar se módulos foram carregados
        -- DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[CM Core]|r " .. CM:T("MSG_CHECKING_MODULES")) -- NOLOG
        -- DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_CHECK_CURSOR_FMT"), (CM.cursor and "|cff00ff00OK|r" or "|cffff4444NIL|r"))) -- NOLOG
        -- DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_CHECK_HOOKS_FMT"), (CM.hooks and "|cff00ff00OK|r" or "|cffff4444NIL|r"))) -- NOLOG
        
        if not CM.cursor then
            DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_ERR_CURSOR"))
            return
        end
        
        if not CM.hooks then
            DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_ERR_HOOKS"))
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
        -- Inicializa Quest Item Distributor
        if CM.questItemDistributor and CM.questItemDistributor.Initialize then
            CM.questItemDistributor:Initialize()
        end
        -- Inicializa Menu de Mercador (NPC Merchant)
        if CM.merchantMenu and CM.merchantMenu.Initialize then
            CM.merchantMenu:Initialize()
        end
        -- Inicializa Menu de Correio (Mailbox) — Passo 1: só esqueleto
        if CM.mailScreen and CM.mailScreen.Initialize then
            CM.mailScreen:Initialize()
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

    elseif event == "PLAYER_LOGOUT" then
        -- Garante que o modo de navegação seja encerrado antes do WoW salvar os bindings no disco
        if CM.keybindings and CM.keybindings.navigationMode then
            CM.keybindings:ExitNavigationMode()
        end
        local set = GetCurrentBindingSet()
        if not set or set == 0 then set = 1 end
        pcall(function() SaveBindings(set) end)
    end
end)

function CM:ToggleRightActionBars(forcedState)
    if not ConsoleModeDB then ConsoleModeDB = {} end
    local newVal
    if forcedState ~= nil then
        newVal = forcedState and true or false
    else
        local cur = (ConsoleModeDB.showRightActionBars ~= false)
        newVal = not cur
    end
    ConsoleModeDB.showRightActionBars = newVal
    if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.UpdateRightBarsVisibility then
        CM.ui.actionHUD:UpdateRightBarsVisibility()
    end
    local statusStr = newVal and CM:T("MSG_BARS_ON") or CM:T("MSG_BARS_OFF")
    DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_BARS_FMT"), statusStr))
    return newVal
end

-- DEV ONLY: sonda do leilao. Consulta Armadura (subclasses 1..5) x locais (1..14), 1 consulta por vez,
-- respeitando CanSendAuctionQuery. Grava a matriz em dev_logs\ahprobe.txt (ExportFile).
function CM:RunAHProbe(arg)
    local out = DEFAULT_CHAT_FRAME
    local probe = CM.ahProbe
    if arg == "stop" then
        if probe and probe.frame then probe.frame:SetScript("OnUpdate", nil); probe.frame:UnregisterAllEvents() end
        CM.ahProbe = nil
        out:AddMessage("[CM ahprobe] stopped.")
        return
    end
    if type(ExportFile) ~= "function" then
        out:AddMessage("|cffff5555[CM ahprobe]|r ExportFile not available.")
        return
    end
    if not (AuctionFrame and AuctionFrame:IsVisible()) then
        out:AddMessage("|cffff5555[CM ahprobe]|r Open the Auction House window first.")
        return
    end
    if probe and probe.running then
        out:AddMessage("[CM ahprobe] already running. Use /cm ahprobe stop")
        return
    end

    local classIdx = 2
    local classes = { GetAuctionItemClasses() }
    local subs = { GetAuctionItemSubClasses(classIdx) }
    local queue = {}
    local s, k
    local isRetry = (arg == "retry")
    if isRetry then
        -- sub: 1=Misc 2=Cloth 3=Leather 4=Mail 5=Plate | slot: 1=Head 2=Neck 3=Shoulder 4=Shirt 5=Chest 6=Waist 7=Legs 8=Feet 9=Wrist 10=Hands 11=Finger 12=Trinket 13=Back 14=OffHand
        local retryList = {
            { 1, 5 }, { 1, 7 }, { 1, 14 },
            { 2, 3 }, { 2, 5 }, { 2, 7 }, { 2, 9 }, { 2, 14 },
            { 3, 4 }, { 4, 9 }, { 5, 7 },
        }
        local i
        for i = 1, table.getn(retryList) do
            table.insert(queue, { sub = retryList[i][1], slot = retryList[i][2] })
        end
    else
        for s = 1, 5 do
            for k = 1, 14 do
                table.insert(queue, { sub = s, slot = k })
            end
        end
    end

    probe = { queue = queue, idx = 1, waiting = false, t = 0, gap = 0, running = true, rows = {}, last = 0 }
    probe.fileName = isRetry and "ahprobe_retry" or "ahprobe"
    probe.timeout = isRetry and 30 or 15
    probe.minGap = isRetry and 6 or 0
    probe.progressEvery = isRetry and 0 or 14
    CM.ahProbe = probe
    local slotsList = { GetAuctionInvTypes(classIdx, 1) }

    local function slotLabel(k)
        local g = slotsList[k] and getglobal(slotsList[k])
        return g or tostring(k)
    end

    local function flush(final)
        local lines = {}
        table.insert(lines, "AUCTION PROBE " .. date("%Y-%m-%d %H:%M:%S") .. (final and " (done)" or " (partial)") .. (isRetry and " [retry]" or ""))
        table.insert(lines, "class " .. classIdx .. " = " .. tostring(classes[classIdx]))
        local i
        for i = 1, table.getn(probe.rows) do
            local r = probe.rows[i]
            table.insert(lines, tostring(subs[r.sub]) .. " / " .. slotLabel(r.slot) .. " : " .. r.result)
        end
        ExportFile(probe.fileName, table.concat(lines, "\n"))
    end

    local function advance()
        probe.waiting = false
        probe.gap = 0
        probe.idx = probe.idx + 1
        if probe.idx > table.getn(probe.queue) then
            probe.running = false
            probe.frame:SetScript("OnUpdate", nil)
            probe.frame:UnregisterAllEvents()
            flush(true)
            out:AddMessage("[CM ahprobe] done -> dev_logs\\" .. probe.fileName .. ".txt")
        elseif probe.progressEvery > 0 and math.mod(probe.idx, probe.progressEvery) == 1 then
            flush(false)
            out:AddMessage("[CM ahprobe] " .. (probe.idx - 1) .. "/" .. table.getn(probe.queue))
        end
    end

    local f = probe.frame or CreateFrame("Frame")
    probe.frame = f
    f:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    f:SetScript("OnEvent", function()
        local p = CM.ahProbe
        if p and p.running and p.waiting then
            local batch, total = GetNumAuctionItems("list")
            local q = p.queue[p.idx]
            table.insert(p.rows, { sub = q.sub, slot = q.slot, result = "total=" .. tostring(total) .. " batch=" .. tostring(batch) })
            advance()
        end
    end)
    f:SetScript("OnUpdate", function()
        local p = CM.ahProbe
        if not (p and p.running) then return end
        if not (AuctionFrame and AuctionFrame:IsVisible()) then
            p.running = false
            f:SetScript("OnUpdate", nil)
            f:UnregisterAllEvents()
            flush(false)
            out:AddMessage("|cffff5555[CM ahprobe]|r Auction window closed, partial result saved.")
            return
        end
        if not p.waiting then
            p.gap = (p.gap or 0) + arg1
            if p.gap >= p.minGap and CanSendAuctionQuery() then
                local q = p.queue[p.idx]
                QueryAuctionItems("", 0, 0, q.slot, classIdx, q.sub, 0, 0, -1)
                p.waiting = true
                p.t = 0
            end
        else
            p.t = p.t + arg1
            if p.t > p.timeout then
                local q = p.queue[p.idx]
                table.insert(p.rows, { sub = q.sub, slot = q.slot, result = "TIMEOUT" })
                advance()
            end
        end
    end)
    out:AddMessage("[CM ahprobe] started: " .. table.getn(queue) .. " queries (~" .. math.floor(table.getn(queue) * 4 / 60 + 0.5) .. " min). /cm ahprobe stop cancels.")
end

-- Comandos Slash
SLASH_CONSOLEMODE1 = "/consolemode"
SLASH_CONSOLEMODE2 = "/cm"

SlashCmdList["CONSOLEMODE"] = function(msg)
    local rawMsg = msg or ""
    local _, _, first, rest = string.find(rawMsg, "^%s*(%S+)%s*(.*)$")
    local cmd = string.lower(first or "")
    rest = rest or ""
    rest = string.gsub(rest, "^%s+", "")
    rest = string.gsub(rest, "%s+$", "")

    if cmd == "lang" or cmd == "idioma" or cmd == "language" then
        if CM.HandleLangCommand then
            CM:HandleLangCommand(rest)
        else
            DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_LANG_NOLOADER"))
        end

    elseif cmd == "octo" or cmd == "octowow" then
        if CM.HandleOctoCommand then
            CM:HandleOctoCommand(rest)
        end

    elseif cmd == "rightbars" or cmd == "barras" or cmd == "barradireita" then
        CM:ToggleRightActionBars()

    elseif cmd == "config" or cmd == "settings" or cmd == "binds" then
        if CM.config and CM.config.Toggle then
            CM.config:Toggle()
        end

    elseif cmd == "ahprobe" then
        CM:RunAHProbe(string.lower(rest))

    elseif cmd == "ahdump" then
        -- DEV ONLY: despeja categorias do leilao (Classe > Subclasse > locais) em dev_logs\ahdump.txt via ExportFile.
        local out = DEFAULT_CHAT_FRAME
        if type(ExportFile) ~= "function" then
            out:AddMessage("|cffff5555[CM ahdump]|r ExportFile not available (SuperWoW/nampower not loaded).")
        elseif not GetAuctionItemClasses then
            out:AddMessage("|cffff5555[CM ahdump]|r Auction API not available.")
        else
            local lines = {}
            local function slotNames(c, s)
                local names = {}
                local slots = { GetAuctionInvTypes(c, s) }
                local i
                for i = 1, table.getn(slots) do
                    local g = getglobal(slots[i])
                    table.insert(names, (g or tostring(slots[i])) .. "{" .. tostring(slots[i]) .. "}")
                end
                return table.concat(names, ", ")
            end
            table.insert(lines, "AUCTION CATEGORY DUMP " .. date("%Y-%m-%d %H:%M:%S"))
            table.insert(lines, "Build: " .. tostring((GetBuildInfo())))
            local classes = { GetAuctionItemClasses() }
            local c
            for c = 1, table.getn(classes) do
                table.insert(lines, "")
                table.insert(lines, "[" .. c .. "] " .. tostring(classes[c]))
                table.insert(lines, "    slots(class-level): " .. slotNames(c, 0))
                local subs = { GetAuctionItemSubClasses(c) }
                local s
                for s = 1, table.getn(subs) do
                    table.insert(lines, "  [" .. c .. "." .. s .. "] " .. tostring(subs[s]) .. " -> " .. slotNames(c, s))
                end
            end
            table.insert(lines, "")
            local q
            for q = 0, 6 do
                local qn = getglobal("ITEM_QUALITY" .. q .. "_DESC")
                if qn then table.insert(lines, "quality " .. q .. " = " .. qn) end
            end
            ExportFile("ahdump", table.concat(lines, "\n"))
            out:AddMessage("[CM ahdump] " .. table.getn(lines) .. " lines -> dev_logs\\ahdump.txt")
        end

    elseif cmd == "filetest" then
        -- DEV ONLY: valida ExportFile (SuperWoW/nampower). Saida em <cliente>\imports\ (junction -> dev_logs).
        local out = DEFAULT_CHAT_FRAME
        if type(ExportFile) ~= "function" then
            out:AddMessage("|cffff5555[CM filetest]|r ExportFile not available (SuperWoW/nampower not loaded).")
        else
            local ok1 = pcall(ExportFile, "filetest", "ok-imports " .. date("%Y-%m-%d %H:%M:%S"))
            out:AddMessage("[CM filetest] imports\\filetest: " .. (ok1 and "called" or "ERROR"))
            local ok2 = pcall(ExportFile, "..\\Interface\\AddOns\\ConsoleModeVanilla\\dev_logs\\filetest_rel", "ok-relative")
            out:AddMessage("[CM filetest] relative path: " .. (ok2 and "called" or "ERROR"))
            out:AddMessage("[CM filetest] Check dev_logs\\ for filetest*.txt")
        end

    elseif cmd == "xp" then
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_XP_DONE"))
        if CM.ui and CM.ui.xpBar then
            CM.ui.xpBar:Initialize()
            if CM.ui.xpBar.frame then
                CM.ui.xpBar.frame:Show()
                CM.ui.xpBar:Update()
                DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_XP_SHOWN"))
            else
                DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_XP_NIL"))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_XP_NOMOD"))
        end

    elseif cmd == "status" then
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_STATUS_HEAD"))
        DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_STATUS_VER_FMT"), CM.version))
        local hooksState = CM:T("MSG_STATE_NIL")
        if CM.hooks then
            if CM.hooks.initialized then hooksState = CM:T("MSG_STATE_INIT") else hooksState = CM:T("MSG_STATE_LOADED") end
        end
        DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_STATUS_HOOKS_FMT"), hooksState))
        local cursorState = CM:T("MSG_STATE_NIL")
        if CM.cursor then
            if CM.cursor.state.enabled then cursorState = CM:T("MSG_STATE_ACTIVE") else cursorState = CM:T("MSG_STATE_INACTIVE") end
        end
        DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_STATUS_CURSOR_FMT"), cursorState))
        local debugState = CM:T("MSG_OFF")
        if CM.debug then debugState = CM:T("MSG_ON") end
        DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_STATUS_DEBUG_FMT"), debugState))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_STATUS_FOOT"))

    elseif cmd == "debug" then
        CM.debug = not CM.debug
        local dbgMode = CM:T("MSG_DEBUG_OFF")
        if CM.debug then dbgMode = CM:T("MSG_DEBUG_ON") end
        DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_DEBUG_FMT"), dbgMode))
        local dbgDetail = CM:T("MSG_DEBUG_DISABLED")
        if CM.debug then dbgDetail = CM:T("MSG_DEBUG_ENABLED") end
        DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_DEBUG_DETAIL_FMT"), dbgDetail))

    elseif cmd == "spelldbg" then
        local d = CM._lastSpellDbg
        if not d or not d.name then
            DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_DBG_SPELL_OPEN_FIRST"))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[spelldbg]|r name=" .. tostring(d.name) .. " rank=" .. tostring(d.rank))
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[spelldbg]|r key=" .. tostring(d.key) .. " id=" .. tostring(d.id) .. " src=" .. tostring(d.src))
            if d.id and ConsoleMode_SpellDescDB and ConsoleMode_SpellDescDB[d.id] then
                local e = ConsoleMode_SpellDescDB[d.id]
                local haspt = (e.pt and e.pt ~= "") and "SIM" or "NAO"
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[spelldbg]|r pt=" .. haspt .. " dbdesc=" .. tostring(string.sub(e.d or "", 1, 60)))
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff8888[spelldbg]|r sem entrada no SpellDescDB")
            end
        end

    elseif cmd == "spellmissing" then
        local q = ConsoleModeDB and ConsoleModeDB.spellMissing
        local n = (q and table.getn(q)) or 0
        DEFAULT_CHAT_FRAME:AddMessage(string.format(CM:T("MSG_DBG_SPELLMISSING_FMT"), n))
        if q then
            local i = 1
            while i <= n do
                local e = q[i]
                if type(e) == "table" then
                    DEFAULT_CHAT_FRAME:AddMessage("  - " .. tostring(e.n) .. " [" .. tostring(e.r) .. "]")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("  - " .. tostring(e))
                end
                i = i + 1
            end
        end

    elseif cmd == "dedup" or cmd == "qid" then
        if CM.questItemDistributor and CM.questItemDistributor.ForceDeduplicate then
            CM.questItemDistributor:ForceDeduplicate()
        end

    elseif cmd == "controller" then
        if CM.keybindings and CM.keybindings.ApplyDefaults then
            CM.keybindings:ApplyDefaults()
            DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_PROFILE_OK"))
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
            
            DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_FRAME_HEAD"))
            DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_FRAME_NAME_FMT"), name))
            DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_FRAME_TYPE_FMT"), ftype))
            DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_FRAME_PARENT_FMT"), parentName))
            local visState = CM:T("MSG_NO")
            if frame:IsVisible() then visState = CM:T("MSG_YES") end
            DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_FRAME_VIS_FMT"), visState))
            
            if CM.cursor and CM.cursor.IsInteractive then
                local interactive = CM.cursor:IsInteractive(frame)
                local interState = CM:T("MSG_NO")
                if interactive then interState = CM:T("MSG_YES") end
                DEFAULT_CHAT_FRAME:AddMessage(format(CM:T("MSG_FRAME_INTER_FMT"), interState))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_FRAME_NONE"))
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
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_HEAD"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_MENU"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_CONFIG"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_RESETUI"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_CONTROLLER"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_KEYBOARD"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_MOUSE"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_STATUS"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_LANG"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_DEBUG"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_FRAME"))
        DEFAULT_CHAT_FRAME:AddMessage(CM:T("MSG_HELP_INIT"))
    end
end
