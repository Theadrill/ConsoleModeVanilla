-- ----------------------------------------------------------------------------
-- ConsoleModeVanilla - UI/MainMenuNav.lua
-- FASE 1: esqueleto (log + hold-to-repeat). FASE 2: BAGS piloto; FASE 3: SPELLS
-- (docs/plano_de_feature_DPAD_NO_MAIN_MENU.md): zonas TABBAR/EQUIP/CATS/GRID/SPCAT/SPGRID,
-- destaque ouro, A/B/Y consomem em BAGS; demais abas seguem em modo log.
-- Molde: UI/MailScreen.lua OnDirection e StartRepeat/StopRepeat (0.35s/0.12s).
-- Lua 5.0 / WoW 1.12 estrito: sem #t, sem goto/continue, sem table.unpack.
-- ----------------------------------------------------------------------------

ConsoleMode_MainMenuNav = ConsoleMode_MainMenuNav or {}
local Nav = ConsoleMode_MainMenuNav

-- Expor em ConsoleMode.mainMenuNav se ConsoleMode existir (sem sobrescrever).
local _CM = getglobal("ConsoleMode")
if _CM then
    if not _CM.mainMenuNav then
        _CM.mainMenuNav = Nav
    end
end

-- Estado (molde MailScreen.repeatState): hold-to-repeat do D-pad com
-- initialDelay 0.35s e interval 0.12s. Ticker tem frame proprio.
Nav.navState = Nav.navState or { direction = nil, timer = 0, initialDelay = 0.35, interval = 0.12 }
Nav.ticker = Nav.ticker or nil

-- FASE 2: foco por zona dentro da aba BAGS.
-- FASE 3: + spellCat/spellSlot para aba SPELLS (zonas SPCAT/SPGRID).
Nav.focus = Nav.focus or { zone = "GRID", tabIdx = 1, equipIndex = 1, catIndex = nil, gridIndex = 1, buffPos = 1, pageBtn = 1, returnZone = "GRID", spellCat = nil, spellSlot = nil, spellTab = nil }

-- ----------------------------------------------------------------------------
-- Helpers defensivos (nunca quebram se o frame/modulo nao existir).
-- ----------------------------------------------------------------------------
local function SafeIsVisible(frame)
    if not frame then return false end
    if type(frame.IsVisible) ~= "function" then return false end
    local ok, vis = pcall(function() return frame:IsVisible() end)
    if ok and vis then return true end
    return false
end

local function IsVKOpen()
    local cm = getglobal("ConsoleMode")
    if cm and cm.VirtualKeyboard and type(cm.VirtualKeyboard.IsOpen) == "function" then
        local vk = cm.VirtualKeyboard
        local ok, open = pcall(function() return vk:IsOpen() end)
        if ok and open then return true end
    end
    local vf = getglobal("ConsoleMode_VirtualKeyboard")
    if SafeIsVisible(vf) then return true end
    return false
end

local function IsQtyOpen()
    local cm = getglobal("ConsoleMode")
    local qp = nil
    if cm then qp = cm.QuantityPicker end
    if not qp then qp = getglobal("ConsoleMode_QuantityPicker") end
    if qp and type(qp.IsOpen) == "function" then
        local ok, open = pcall(function() return qp:IsOpen() end)
        if ok and open then return true end
    end
    if SafeIsVisible(qp) then return true end
    return false
end

local function IsContextMenuOpen()
    local cm = getglobal("ConsoleMode")
    if cm and cm.ui and cm.ui.contextMenu then
        local m = cm.ui.contextMenu
        if m.frame and type(m.frame.IsVisible) == "function" then
            local fr = m.frame
            local ok, vis = pcall(function() return fr:IsVisible() end)
            if ok and vis then return true end
        end
    end
    local cf = getglobal("ConsoleModeContextMenu")
    if SafeIsVisible(cf) then return true end
    return false
end

local function IsQuestDetailOpen()
    local cm = getglobal("ConsoleMode")
    if cm and cm.mainMenu and type(cm.mainMenu.IsQuestDetailVisible) == "function" then
        local mm = cm.mainMenu
        local ok, vis = pcall(function() return mm:IsQuestDetailVisible() end)
        if ok and vis then return true end
    end
    if cm and cm.mainMenu and cm.mainMenu.questDetailOverlay then
        if SafeIsVisible(cm.mainMenu.questDetailOverlay) then return true end
    end
    return false
end

local function MMNav_Log(msg)
    local dcf = getglobal("DEFAULT_CHAT_FRAME")
    if dcf and type(dcf.AddMessage) == "function" then
        dcf:AddMessage(msg)
    end
end

local function MMNav_PlayMove()
    local ps = getglobal("PlaySound")
    if type(ps) == "function" then
        pcall(ps, "igMainMenuOptionCheckBoxOn")
    end
end

local function MMNav_HideCursor()
    -- Cursor:Hide() esconde o visual sem zerar estado (nunca Disable).
    local cm = getglobal("ConsoleMode")
    if cm and cm.cursor and type(cm.cursor.Hide) == "function" then
        pcall(function() cm.cursor:Hide() end)
    end
end

-- ----------------------------------------------------------------------------
-- FASE 1: gate de atividade.
-- true SOMENTE se MainMenu visivel E Merchant/Mail fechados E nenhum modal
-- (VK/Qty/ContextMenu/questDetailOverlay) aberto.
-- ----------------------------------------------------------------------------
function Nav:IsActive()
    local mmFrame = getglobal("ConsoleModeMainMenuFrame")
    if not SafeIsVisible(mmFrame) then return false end
    local merchant = getglobal("ConsoleMode_MerchantMenu")
    if merchant and merchant.isOpen then return false end
    local mail = getglobal("ConsoleMode_MailScreen")
    if mail and mail.isOpen then return false end
    if IsVKOpen() then return false end
    if IsQtyOpen() then return false end
    if IsContextMenuOpen() then return false end
    if IsQuestDetailOpen() then return false end
    return true
end

-- ----------------------------------------------------------------------------
-- FASE 2: acesso as zonas BAGS (tudo defensivo; nil se aba ainda nao montada).
-- ----------------------------------------------------------------------------
local function Nav_GetMM()
    local cm = getglobal("ConsoleMode")
    if cm and cm.mainMenu then return cm.mainMenu end
    return getglobal("ConsoleModeMainMenu")
end

local function Nav_GetTabButtons()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.tabContainer then return nil end
    if not MM.tabContainer.tabBar then return nil end
    return MM.tabContainer.tabBar.buttons
end

local function Nav_GetCurrentTab()
    local MM = Nav_GetMM()
    if MM and MM.tabContainer and MM.tabContainer.currentTab then
        return MM.tabContainer.currentTab
    end
    return nil
end

local function Nav_GetEquipButtons()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.equipColumn then return nil end
    return MM.equipColumn.buttons
end

local function Nav_GetPageBags()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.tabContainer then return nil end
    if not MM.tabContainer.pages then return nil end
    return MM.tabContainer.pages["BAGS"]
end

local function Nav_GetCatButtons()
    local pb = Nav_GetPageBags()
    if not pb then return nil end
    return pb.catButtons
end

local function Nav_GetGrid()
    local pb = Nav_GetPageBags()
    if not pb then return nil end
    return pb.grid
end

-- FASE 3: acesso a aba SPELLS (defensivo; nil se aba ainda nao montada).
-- pageSpells = tabContainer.pages["SPELLS"]; activeScreen 1=cats/2=grid;
-- catButtons em pageSpells.catScreen.catContainer.catButtons; grade em pageSpells.grid.
local function Nav_GetPageSpells()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.tabContainer then return nil end
    if not MM.tabContainer.pages then return nil end
    return MM.tabContainer.pages["SPELLS"]
end

local function Nav_GetSpellCats()
    local ps = Nav_GetPageSpells()
    if not ps then return nil end
    if ps.catButtons then return ps.catButtons end
    if ps.catScreen and ps.catScreen.catContainer and ps.catScreen.catContainer.catButtons then
        return ps.catScreen.catContainer.catButtons
    end
    return nil
end

local function Nav_GetSpellTabs()
    local ps = Nav_GetPageSpells()
    if not ps then return nil end
    if ps.tabButtons then return ps.tabButtons end
    if ps.headerBar and ps.headerBar.tabButtons then return ps.headerBar.tabButtons end
    return nil
end

local function Nav_GetSpellTabIdx()
    local ps = Nav_GetPageSpells()
    if ps and ps.currentTabIdx and type(ps.currentTabIdx) == "number" then return ps.currentTabIdx end
    return nil
end

local function Nav_GetSpellGrid()
    local ps = Nav_GetPageSpells()
    if not ps then return nil end
    return ps.grid
end

local function Nav_GetSpellActiveScreen()
    local ps = Nav_GetPageSpells()
    if not ps then return nil end
    if ps.activeScreen then return ps.activeScreen end
    return nil
end

local function Nav_GetSpellFocusedIdx()
    local ps = Nav_GetPageSpells()
    if ps then
        if ps.focusedCatIdx and type(ps.focusedCatIdx) == "number" then return ps.focusedCatIdx end
        if ps.catScreen and ps.catScreen.focusedCatIdx and type(ps.catScreen.focusedCatIdx) == "number" then
            return ps.catScreen.focusedCatIdx
        end
        if ps.selectedCat and type(ps.selectedCat) == "number" then return ps.selectedCat end
    end
    local grid = Nav_GetSpellGrid()
    if grid and grid.selectedSlotIndex and type(grid.selectedSlotIndex) == "number" then
        return nil
    end
    return nil
end

local function Nav_SpellCols()
    local grid = Nav_GetSpellGrid()
    local cols = 8
    if grid and grid.cols and type(grid.cols) == "number" and grid.cols >= 4 and grid.cols <= 11 then
        cols = grid.cols
    end
    if grid and grid.GetCapacity then
        local ok, _, c = pcall(function() return grid:GetCapacity() end)
        if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end
    end
    return cols
end

local function Nav_VisibleSpellGridCount()
    local grid = Nav_GetSpellGrid()
    if not grid or not grid.slots then return 0 end
    local n = 0
    local total = table.getn(grid.slots)
    for i = 1, total do
        local slot = grid.slots[i]
        if slot and type(slot.IsVisible) == "function" then
            local ok, vis = pcall(function() return slot:IsVisible() end)
            if ok and vis then n = n + 1 end
        end
    end
    return n
end

local function Nav_GetBuffRows()
    local MM = nil
    local okMM, mm = pcall(function() return Nav_GetMM() end)
    if okMM then MM = mm end
    if not MM then return nil end
    local ok, rows = pcall(function()
        if MM.statsAndBuffs then return MM.statsAndBuffs.buffRows end
        return nil
    end)
    if ok then return rows end
    return nil
end

-- BUFFS: rows visiveis topo->base (pool max 8, ordem crescente); ativa = IsVisible().
local function Nav_VisibleBuffs()
    local out = {}
    local rows = Nav_GetBuffRows()
    if not rows then return out end
    local n = 0
    local okN, nn = pcall(function() return table.getn(rows) end)
    if okN and type(nn) == "number" then n = nn end
    if n > 8 then n = 8 end
    for i = 1, n do
        local row = rows[i]
        if row and type(row.IsVisible) == "function" then
            local ok, vis = pcall(function() return row:IsVisible() end)
            if ok and vis then table.insert(out, row) end
        end
    end
    return out
end

local function Nav_BuffCount()
    local vis = Nav_VisibleBuffs()
    if not vis then return 0 end
    return table.getn(vis)
end

local function Nav_VisibleGridCount()
    local grid = Nav_GetGrid()
    if not grid or not grid.slots then return 0 end
    local n = 0
    local total = table.getn(grid.slots)
    for i = 1, total do
        local slot = grid.slots[i]
        if slot and type(slot.IsVisible) == "function" then
            local ok, vis = pcall(function() return slot:IsVisible() end)
            if ok and vis then n = n + 1 end
        end
    end
    return n
end

-- PAGENAV: botoes [<] [>] visiveis na ordem (pageNav escondido = vazio).
local function Nav_VisiblePageBtns()
    local out = {}
    local pb = Nav_GetPageBags()
    if not pb then return out end
    if pb.pageNav and type(pb.pageNav.IsVisible) == "function" then
        local ok, vis = pcall(function() return pb.pageNav:IsVisible() end)
        if not (ok and vis) then return out end
    end
    local prev = pb.prevPageBtn
    if prev and type(prev.IsVisible) == "function" then
        local ok, vis = pcall(function() return prev:IsVisible() end)
        if ok and vis then table.insert(out, prev) end
    end
    local nxt = pb.nextPageBtn
    if nxt and type(nxt.IsVisible) == "function" then
        local ok, vis = pcall(function() return nxt:IsVisible() end)
        if ok and vis then table.insert(out, nxt) end
    end
    return out
end

local function Nav_FindCatIndexForCurrent()
    local pb = Nav_GetPageBags()
    local cats = Nav_GetCatButtons()
    if not pb or not cats then return nil end
    local cur = pb.currentCategory
    if not cur then return nil end
    local n = table.getn(cats)
    for i = 1, n do
        local b = cats[i]
        if b and b.catData and b.catData.id == cur then return i end
    end
    return nil
end

-- Garante foco valido (clampa índices; resolve catIndex inicial via categoria).
local function Nav_EnsureFocus()
    local f = Nav.focus
    local tabs = Nav_GetTabButtons()
    local nt = 0
    if tabs then nt = table.getn(tabs) end
    if nt < 1 then nt = 5 end
    if not f.tabIdx or f.tabIdx < 1 then f.tabIdx = 1 end
    if f.tabIdx > nt then f.tabIdx = nt end

    local eq = Nav_GetEquipButtons()
    local ne = 0
    if eq then ne = table.getn(eq) end
    if ne < 1 then ne = 17 end
    if not f.equipIndex or f.equipIndex < 1 then f.equipIndex = 1 end
    if f.equipIndex > ne then f.equipIndex = ne end

    local cats = Nav_GetCatButtons()
    local nc = 0
    if cats then nc = table.getn(cats) end
    if nc > 0 then
        if not f.catIndex then
            f.catIndex = Nav_FindCatIndexForCurrent() or nc
        end
        if f.catIndex < 1 then f.catIndex = 1 end
        if f.catIndex > nc then f.catIndex = nc end
    end

    local vis = Nav_VisibleGridCount()
    if vis > 0 then
        if not f.gridIndex or f.gridIndex < 1 then f.gridIndex = 1 end
        if f.gridIndex > vis then f.gridIndex = vis end
    else
        if not f.gridIndex or f.gridIndex < 1 then f.gridIndex = 1 end
    end

    if not f.pageBtn or f.pageBtn < 1 then f.pageBtn = 1 end
    if f.zone == "PAGENAV" then
        local pbtns = Nav_VisiblePageBtns()
        local np = 0
        if pbtns then np = table.getn(pbtns) end
        if np < 1 then
            f.zone = "GRID"
        elseif f.pageBtn > np then
            f.pageBtn = np
        end
    end

    if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
    local bc = Nav_BuffCount()
    if f.zone == "BUFFS" then
        if bc < 1 then
            f.zone = "GRID"
        elseif f.buffPos > bc then
            f.buffPos = bc
        end
    elseif bc > 0 and f.buffPos > bc then
        f.buffPos = bc
    end

    -- FASE 3: clamp SPELLS (spellCat init focusedCatIdx ou 1; spellSlot init selectedSlotIndex ou 1).
    local scats = Nav_GetSpellCats()
    local nsc = 0
    if scats then nsc = table.getn(scats) end
    if nsc > 0 then
        if not f.spellCat then
            f.spellCat = Nav_GetSpellFocusedIdx() or 1
        end
        if f.spellCat < 1 then f.spellCat = 1 end
        if f.spellCat > nsc then f.spellCat = nsc end
    else
        if not f.spellCat or f.spellCat < 1 then f.spellCat = 1 end
    end
    local svis = Nav_VisibleSpellGridCount()
    if svis > 0 then
        if not f.spellSlot then
            local sg = Nav_GetSpellGrid()
            if sg and sg.selectedSlotIndex and type(sg.selectedSlotIndex) == "number" and sg.selectedSlotIndex >= 1 and sg.selectedSlotIndex <= svis then
                f.spellSlot = sg.selectedSlotIndex
            else
                f.spellSlot = 1
            end
        end
        if f.spellSlot < 1 then f.spellSlot = 1 end
        if f.spellSlot > svis then f.spellSlot = svis end
    else
        -- fallback grade vazia: mantem slot 1 sem forcar troca de zona aqui.
        if not f.spellSlot or f.spellSlot < 1 then f.spellSlot = 1 end
    end
    if f.zone == "SPCAT" and nsc < 1 then
        if svis > 0 then f.zone = "SPGRID" end
    end
    local stabsEf = Nav_GetSpellTabs()
    local ntEf = 0
    if stabsEf then ntEf = table.getn(stabsEf) end
    if ntEf > 0 then
        if not f.spellTab then
            f.spellTab = Nav_GetSpellTabIdx() or 1
        end
        if f.spellTab < 1 then f.spellTab = 1 end
        if f.spellTab > ntEf then f.spellTab = ntEf end
    else
        if not f.spellTab or f.spellTab < 1 then f.spellTab = 1 end
        if f.zone == "SPTABS" then f.zone = "SPGRID" end
    end

    if f.zone ~= "TABBAR" and f.zone ~= "EQUIP" and f.zone ~= "CATS" and f.zone ~= "GRID" and f.zone ~= "BUFFS" and f.zone ~= "PAGENAV" and f.zone ~= "SPCAT" and f.zone ~= "SPGRID" and f.zone ~= "SPTABS" then
        f.zone = "GRID"
    end
    if f.returnZone ~= "EQUIP" and f.returnZone ~= "CATS" and f.returnZone ~= "GRID" and f.returnZone ~= "BUFFS" and f.returnZone ~= "PAGENAV" and f.returnZone ~= "SPCAT" and f.returnZone ~= "SPGRID" and f.returnZone ~= "SPTABS" then
        f.returnZone = "GRID"
    end
    -- Conversao por aba: evita zona BAGS presa em SPELLS e vice-versa.
    local curTabEf = Nav_GetCurrentTab()
    if curTabEf == "SPELLS" then
        local scr = Nav_GetSpellActiveScreen()
        local defSp = "SPCAT"
        if scr == 2 then defSp = "SPGRID" end
        if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" then
            f.zone = defSp
        end
        if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" then
            f.returnZone = defSp
        end
        if f.zone == "BUFFS" and bc < 1 then
            f.zone = defSp
        end
    elseif curTabEf == "BAGS" then
        if f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" then
            f.zone = "GRID"
        end
        if f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" then
            f.returnZone = "GRID"
        end
    end
end

-- Aplica o visual ouro + DetailCard + esconde o cursor espacial.
local function Nav_ApplyFocus()
    Nav_EnsureFocus()
    local f = Nav.focus
    MMNav_HideCursor()

    -- TABBAR: highlight do botao focado (somente highlight; nunca title).
    -- Preserva a aba ativa de SelectTab (tabData.id == currentTab).
    local tabs = Nav_GetTabButtons()
    if tabs then
        local curTab = nil
        local okMM, MMM = pcall(function() return Nav_GetMM() end)
        if okMM and MMM and MMM.tabContainer then curTab = MMM.tabContainer.currentTab end
        local n = table.getn(tabs)
        for i = 1, n do
            local btn = tabs[i]
            if btn then
                if f.zone == "TABBAR" and i == f.tabIdx then
                    if btn.highlight then pcall(function() btn.highlight:Show() end) end
                elseif curTab and btn.tabData and btn.tabData.id == curTab then
                    if btn.highlight then pcall(function() btn.highlight:Show() end) end
                else
                    if btn.highlight then pcall(function() btn.highlight:Hide() end) end
                end
            end
        end
    end

    -- EQUIP: borda dourada + DetailCard do slot.
    -- Frame 1.12 nao tem SetVertexColor em Frame: border e Frame com
    -- backdrop (cf. MainMenu.lua:1289,1294), API correta e SetBackdropBorderColor.
    local eq = Nav_GetEquipButtons()
    if eq then
        local MMEquip = Nav_GetMM()
        local canRestore = MMEquip and type(MMEquip.UpdateEquipmentColumn) == "function"
        if canRestore then
            pcall(function() MMEquip:UpdateEquipmentColumn() end)
        end
        local n = table.getn(eq)
        for i = 1, n do
            local btn = eq[i]
            if btn then
                local hasFullHi = btn.fullHi and type(btn.fullHi.Show) == "function" and type(btn.fullHi.Hide) == "function"
                if hasFullHi then
                    if f.zone == "EQUIP" and i == f.equipIndex then
                        pcall(function() btn.fullHi:Show() end)
                    else
                        pcall(function() btn.fullHi:Hide() end)
                    end
                elseif btn.border and type(btn.border.SetBackdropBorderColor) == "function" then
                    if f.zone == "EQUIP" and i == f.equipIndex then
                        pcall(function() btn.border:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.95) end)
                    elseif btn and type(btn.ApplyFocus) == "function" then
                        pcall(function() btn:ApplyFocus() end)
                    elseif not canRestore then
                        pcall(function() btn.border:SetBackdropBorderColor(1, 1, 1, 0.6) end)
                    end
                end
            end
        end
        if f.zone == "EQUIP" then
            local btn = eq[f.equipIndex]
            if btn and btn.invSlotID then
                local MM = Nav_GetMM()
                if MM and type(MM.GetActiveDetailCard) == "function" then
                    local ok, card = pcall(function() return MM:GetActiveDetailCard() end)
                    if ok and card and type(card.ShowEquipSlot) == "function" then
                        pcall(function() card:ShowEquipSlot(btn.invSlotID, btn.slotData) end)
                    end
                end
            end
        end
    end

    -- CATS: foco ouro; ativa sempre ambar; demais cinza.
    local cats = Nav_GetCatButtons()
    local pb = Nav_GetPageBags()
    local curCat = nil
    if pb then curCat = pb.currentCategory end
    if cats then
        local n = table.getn(cats)
        for i = 1, n do
            local btn = cats[i]
            if btn and btn.title and type(btn.title.SetTextColor) == "function" then
                if f.zone == "CATS" and i == f.catIndex then
                    pcall(function() btn.title:SetTextColor(1.0, 0.82, 0.20) end)
                elseif btn.catData and btn.catData.id == curCat then
                    -- igual CFG.Tabs.activeColor (MainMenu.lua:264; CFG é local)
                    pcall(function() btn.title:SetTextColor(0.88, 0.60, 0.08) end)
                else
                    pcall(function() btn.title:SetTextColor(0.6, 0.6, 0.6) end)
                end
            end
        end
    end

    -- GRID: usa SelectSlot (acende highlight + DetailCard + compare).
    -- Foco unico: fora do GRID, esconde TODOS os slot.highlights sem tocar
    -- em selectedSlotIndex (nunca grid:Clear()).
    local gridForFocus = Nav_GetGrid()
    if f.zone == "GRID" then
        if gridForFocus and type(gridForFocus.SelectSlot) == "function" then
            pcall(function() gridForFocus:SelectSlot(f.gridIndex) end)
        end
    else
        if gridForFocus and gridForFocus.slots then
            local okG, totalG = pcall(function() return table.getn(gridForFocus.slots) end)
            if okG and type(totalG) == "number" and totalG > 0 then
                for gi = 1, totalG do
                    local gslot = gridForFocus.slots[gi]
                    if gslot and gslot.highlight and type(gslot.highlight.Hide) == "function" then
                        pcall(function() gslot.highlight:Hide() end)
                    end
                end
            end
        end
    end

    -- FASE 3 SPELLS visual:
    -- SPCAT usa FocusSpellCategoryButton (pinta + DetailCard + pose);
    -- SPGRID usa grid:SelectSlot; fora de SPGRID esconde highlights sem zerar selectedSlotIndex.
    -- SPCAT repinta TODOS os cards a cada ApplyFocus (espelho CATS/SPTABS/GRID else-hide):
    -- focado so recebe ouro em zone==SPCAT; fora disso, ativa fica dim e demais inativos.
    local MMVis = Nav_GetMM()
    if f.zone == "SPCAT" then
        if MMVis and type(MMVis.FocusSpellCategoryButton) == "function" then
            local idx = f.spellCat or 1
            pcall(function() MMVis:FocusSpellCategoryButton(idx) end)
        end
    else
        pcall(function()
            local page = MMVis and MMVis.tabContainer and MMVis.tabContainer.pages and MMVis.tabContainer.pages["SPELLS"]
            local cbs = page and page.catButtons
            if not cbs then return end
            local activeIdx = f.spellCat or page.focusedCatIdx or 1
            local n = table.getn(cbs)
            for i = 1, n do
                local b = cbs[i]
                if b then
                    if b.focusBorder and type(b.focusBorder.Hide) == "function" then b.focusBorder:Hide() end
                    if b.highlight and type(b.highlight.Hide) == "function" then b.highlight:Hide() end
                    if i == activeIdx then
                        if b.activeBorder and type(b.activeBorder.Show) == "function" then b.activeBorder:Show() end
                        if b.inactiveBorder and type(b.inactiveBorder.Hide) == "function" then b.inactiveBorder:Hide() end
                        if b.catName and type(b.catName.SetTextColor) == "function" then b.catName:SetTextColor(0.88, 0.60, 0.08) end
                    else
                        if b.activeBorder and type(b.activeBorder.Hide) == "function" then b.activeBorder:Hide() end
                        if b.inactiveBorder and type(b.inactiveBorder.Show) == "function" then b.inactiveBorder:Show() end
                        if b.catName and type(b.catName.SetTextColor) == "function" then b.catName:SetTextColor(0.90, 0.90, 0.90) end
                    end
                end
            end
        end)
    end
    local spellGridForFocus = Nav_GetSpellGrid()
    if f.zone == "SPGRID" then
        if spellGridForFocus and type(spellGridForFocus.SelectSlot) == "function" then
            pcall(function() spellGridForFocus:SelectSlot(f.spellSlot) end)
        end
    else
        if spellGridForFocus and spellGridForFocus.slots then
            local okS, totalS = pcall(function() return table.getn(spellGridForFocus.slots) end)
            if okS and type(totalS) == "number" and totalS > 0 then
                for si = 1, totalS do
                    local sslot = spellGridForFocus.slots[si]
                    if sslot and sslot.highlight and type(sslot.highlight.Hide) == "function" then
                        pcall(function() sslot.highlight:Hide() end)
                    end
                end
            end
        end
    end

    -- SPTABS: aba de escola focada ouro (defensivo: border ou highlight).
    local spellTabsForFocus = Nav_GetSpellTabs()
    if spellTabsForFocus then
        local okT, totalT = pcall(function() return table.getn(spellTabsForFocus) end)
        if okT and type(totalT) == "number" and totalT > 0 then
            local curTi = Nav_GetSpellTabIdx() or f.spellTab or 1
            for ti = 1, totalT do
                local tbtn = spellTabsForFocus[ti]
                if tbtn then
                    local isFocusTab = (f.zone == "SPTABS" and ti == (f.spellTab or curTi))
                    local isActiveTab = (ti == curTi)
                    if isFocusTab then
                        if type(tbtn.SetBackdropBorderColor) == "function" then
                            pcall(function() tbtn:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.95) end)
                        elseif tbtn.highlight and type(tbtn.highlight.Show) == "function" then
                            pcall(function() tbtn.highlight:Show() end)
                        elseif type(tbtn.LockHighlight) == "function" then
                            pcall(function() tbtn:LockHighlight() end)
                        end
                    elseif isActiveTab then
                        if tbtn.highlight and type(tbtn.highlight.Show) == "function" then
                            pcall(function() tbtn.highlight:Show() end)
                        end
                    else
                        if tbtn.highlight and type(tbtn.highlight.Hide) == "function" then
                            pcall(function() tbtn.highlight:Hide() end)
                        end
                        if type(tbtn.UnlockHighlight) == "function" then
                            pcall(function() tbtn:UnlockHighlight() end)
                        end
                        if type(tbtn.SetBackdropBorderColor) == "function" then
                            pcall(function() tbtn:SetBackdropBorderColor(0.5, 0.4, 0.28, 0.65) end)
                        end
                    end
                end
            end
        end
    end

    -- PAGENAV: botao focado ouro; demais voltam ao default.
    local pbForPage = Nav_GetPageBags()
    if pbForPage and (pbForPage.prevPageBtn or pbForPage.nextPageBtn) then
        local pbtns = Nav_VisiblePageBtns()
        local focusedBtn = nil
        if f.zone == "PAGENAV" and pbtns then
            local npv = table.getn(pbtns)
            if f.pageBtn and f.pageBtn >= 1 and f.pageBtn <= npv then
                focusedBtn = pbtns[f.pageBtn]
            end
        end
        local allBtns = { pbForPage.prevPageBtn, pbForPage.nextPageBtn }
        for i = 1, 2 do
            local b = allBtns[i]
            if b then
                if focusedBtn and b == focusedBtn then
                    if b.fullHi and type(b.fullHi.Show) == "function" then
                        pcall(function() b.fullHi:Show() end)
                    elseif type(b.SetBackdropBorderColor) == "function" then
                        pcall(function() b:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.95) end)
                    elseif type(b.LockHighlight) == "function" then
                        pcall(function() b:LockHighlight() end)
                    elseif b.highlight and type(b.highlight.Show) == "function" then
                        pcall(function() b.highlight:Show() end)
                    end
                else
                    if b.fullHi and type(b.fullHi.Hide) == "function" then
                        pcall(function() b.fullHi:Hide() end)
                    end
                    if type(b.SetBackdropBorderColor) == "function" then
                        pcall(function() b:SetBackdropBorderColor(0.5, 0.4, 0.28, 0.65) end)
                    end
                    if type(b.UnlockHighlight) == "function" then
                        pcall(function() b:UnlockHighlight() end)
                    end
                    if b.highlight and type(b.highlight.Hide) == "function" then
                        pcall(function() b.highlight:Hide() end)
                    end
                end
            end
        end
    end

    -- BUFFS: row focada ouro + DetailCard ShowBuffRow; demais voltam ao default.
    local buffRows = Nav_GetBuffRows()
    if buffRows then
        local vis = Nav_VisibleBuffs()
        local focusedRow = nil
        if f.zone == "BUFFS" then
            local nvis = table.getn(vis)
            if f.buffPos and f.buffPos >= 1 and f.buffPos <= nvis then
                focusedRow = vis[f.buffPos]
            end
        end
        local npool = 0
        local okN, pn = pcall(function() return table.getn(buffRows) end)
        if okN and type(pn) == "number" then npool = pn end
        if npool > 8 then npool = 8 end
        for i = 1, npool do
            local row = buffRows[i]
            if row then
                local hasFullHi = row.fullHi and type(row.fullHi.Show) == "function" and type(row.fullHi.Hide) == "function"
                if hasFullHi then
                    if focusedRow and row == focusedRow then
                        pcall(function() row.fullHi:Show() end)
                    else
                        pcall(function() row.fullHi:Hide() end)
                    end
                elseif row.border and type(row.border.SetBackdropBorderColor) == "function" then
                    local b = row.border
                    if focusedRow and row == focusedRow then
                        pcall(function() b:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.95) end)
                    else
                        pcall(function() b:SetBackdropBorderColor(0.2, 0.8, 1.0, 0.7) end)
                    end
                end
            end
        end
        if focusedRow then
            local MM = Nav_GetMM()
            if MM and type(MM.GetActiveDetailCard) == "function" then
                local ok, card = pcall(function() return MM:GetActiveDetailCard() end)
                if ok and card and type(card.ShowBuffRow) == "function" then
                    pcall(function() card:ShowBuffRow(focusedRow) end)
                end
            end
        end
    end
end

-- Roteador OnDirection. FASE 2: BAGS real; FASE 3: SPELLS real; demais, log.
function Nav:OnDirection(direction)
    if not self:IsActive() then return end
    local curTab = Nav_GetCurrentTab()
    if curTab == "SPELLS" then
        Nav_EnsureFocus()
        local movedSp = Nav_OnSpellsDirection(direction)
        Nav_ApplyFocus()
        if movedSp then MMNav_PlayMove() end
        return
    end
    if curTab ~= "BAGS" then
        MMNav_Log("|cffe09a15[MMNav]|r " .. tostring(direction))
        MMNav_PlayMove()
        return
    end
    Nav_EnsureFocus()
    local moved = Nav_OnBagsDirection(direction)
    Nav_ApplyFocus()
    if moved then MMNav_PlayMove() end
end

-- FASE 3: navegacao SPELLS. Zonas SPCAT (fileira horizontal tela1), SPTABS
-- (fileira de abas de escola tela2) e SPGRID (grade tela2);
-- TABBAR/EQUIP/BUFFS compartilhadas funcionam igual a BAGS.
-- Retorna true se moveu/tratou.
function Nav_OnSpellsDirection(direction)
    local f = Nav.focus
    if direction == "UP" then
        if f.zone == "TABBAR" then return false end
        if f.zone == "EQUIP" then
            if f.equipIndex > 1 then f.equipIndex = f.equipIndex - 1 return true end
            f.returnZone = "EQUIP"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "SPCAT" then
            f.returnZone = "SPCAT"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "SPTABS" then
            f.returnZone = "SPTABS"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "SPGRID" then
            local cols = Nav_SpellCols()
            if (f.spellSlot - cols) >= 1 then
                f.spellSlot = f.spellSlot - cols
                return true
            end
            local upTabs = Nav_GetSpellTabs()
            local upNt = 0
            if upTabs then upNt = table.getn(upTabs) end
            if upNt > 0 then
                f.zone = "SPTABS"
                if not f.spellTab then f.spellTab = Nav_GetSpellTabIdx() or 1 end
                if f.spellTab < 1 then f.spellTab = 1 end
                if f.spellTab > upNt then f.spellTab = upNt end
                Nav_EnsureFocus()
                return true
            end
            f.returnZone = "SPGRID"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "BUFFS" then
            local bc = Nav_BuffCount()
            if bc < 1 then
                local scrB = Nav_GetSpellActiveScreen()
                if scrB == 2 then f.zone = "SPGRID" else f.zone = "SPCAT" end
                Nav_EnsureFocus()
                return true
            end
            if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
            if f.buffPos > bc then f.buffPos = bc end
            if f.buffPos > 1 then
                f.buffPos = f.buffPos - 1
                return true
            end
            f.returnZone = "BUFFS"
            f.zone = "TABBAR"
            return true
        end
        return false
    end
    if direction == "DOWN" then
        if f.zone == "TABBAR" then
            f.zone = f.returnZone or "SPCAT"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "EQUIP" then
            local eq = Nav_GetEquipButtons()
            local ne = 17
            if eq then ne = table.getn(eq) end
            if f.equipIndex < ne then f.equipIndex = f.equipIndex + 1 return true end
            return false
        end
        if f.zone == "SPCAT" then
            return false
        end
        if f.zone == "SPTABS" then
            f.zone = "SPGRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "SPGRID" then
            local cols = Nav_SpellCols()
            local svis = Nav_VisibleSpellGridCount()
            if (f.spellSlot + cols) <= svis then
                f.spellSlot = f.spellSlot + cols
                return true
            end
            return false
        end
        if f.zone == "BUFFS" then
            local bc = Nav_BuffCount()
            if bc < 1 then
                local scrB2 = Nav_GetSpellActiveScreen()
                if scrB2 == 2 then f.zone = "SPGRID" else f.zone = "SPCAT" end
                Nav_EnsureFocus()
                return true
            end
            if not f.buffPos or f.buffPos < 1 then
                f.buffPos = 1
                Nav_EnsureFocus()
                return true
            end
            if f.buffPos > bc then
                f.buffPos = bc
                return true
            end
            if f.buffPos < bc then
                f.buffPos = f.buffPos + 1
                return true
            end
            return false
        end
        return false
    end
    if direction == "LEFT" then
        if f.zone == "TABBAR" then
            if f.tabIdx > 1 then f.tabIdx = f.tabIdx - 1 return true end
            return false
        end
        if f.zone == "EQUIP" then return false end
        if f.zone == "SPCAT" then
            local scats = Nav_GetSpellCats()
            local nsc = 0
            if scats then nsc = table.getn(scats) end
            if nsc < 1 then return false end
            if not f.spellCat or f.spellCat < 1 then f.spellCat = 1 end
            if f.spellCat > nsc then f.spellCat = nsc end
            if f.spellCat <= 1 then
                local bcSPL = Nav_BuffCount()
                if bcSPL and bcSPL > 0 then
                    f.returnZone = "SPCAT"
                    f.zone = "BUFFS"
                    if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
                    if f.buffPos > bcSPL then f.buffPos = bcSPL end
                    Nav_EnsureFocus()
                    return true
                end
            end
            f.spellCat = f.spellCat - 1
            if f.spellCat < 1 then f.spellCat = nsc end
            local MMLeft = Nav_GetMM()
            if MMLeft and type(MMLeft.FocusSpellCategoryButton) == "function" then
                local idxL = f.spellCat
                pcall(function() MMLeft:FocusSpellCategoryButton(idxL) end)
            end
            return true
        end
        if f.zone == "SPTABS" then
            local tabsL = Nav_GetSpellTabs()
            local ntL = 0
            if tabsL then ntL = table.getn(tabsL) end
            if ntL < 1 then return false end
            if not f.spellTab then f.spellTab = Nav_GetSpellTabIdx() or 1 end
            if f.spellTab < 1 then f.spellTab = 1 end
            if f.spellTab > ntL then f.spellTab = ntL end
            f.spellTab = f.spellTab - 1
            if f.spellTab < 1 then f.spellTab = ntL end
            local MMSL = Nav_GetMM()
            if MMSL and type(MMSL.SelectSpellTab) == "function" then
                local idxSL = f.spellTab
                pcall(function() MMSL:SelectSpellTab(idxSL) end)
            end
            return true
        end
        if f.zone == "BUFFS" then
            f.zone = "EQUIP"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "SPGRID" then
            local cols = Nav_SpellCols()
            if math.mod(f.spellSlot - 1, cols) ~= 0 then
                f.spellSlot = f.spellSlot - 1
                return true
            end
            local bc = Nav_BuffCount()
            if bc > 0 then
                f.returnZone = "SPGRID"
                f.zone = "BUFFS"
                if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
                if f.buffPos > bc then f.buffPos = bc end
                Nav_EnsureFocus()
                return true
            end
            f.returnZone = "SPGRID"
            f.zone = "EQUIP"
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if direction == "RIGHT" then
        if f.zone == "TABBAR" then
            local tabs = Nav_GetTabButtons()
            local nt = 5
            if tabs then nt = table.getn(tabs) end
            if f.tabIdx < nt then f.tabIdx = f.tabIdx + 1 return true end
            return false
        end
        if f.zone == "EQUIP" then
            local bc = Nav_BuffCount()
            if bc > 0 then
                f.returnZone = "EQUIP"
                f.zone = "BUFFS"
                if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
                if f.buffPos > bc then f.buffPos = bc end
                Nav_EnsureFocus()
                return true
            end
            local scrE = Nav_GetSpellActiveScreen()
            local curE = Nav_GetCurrentTab()
            if curE == "BAGS" then
                f.zone = "GRID"
            elseif curE == "SPELLS" or curE == nil then
                if scrE == 2 then f.zone = "SPGRID" else f.zone = "SPCAT" end
            else
                f.zone = "GRID"
            end
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "SPCAT" then
            local scatsR = Nav_GetSpellCats()
            local nscR = 0
            if scatsR then nscR = table.getn(scatsR) end
            if nscR < 1 then return false end
            if not f.spellCat or f.spellCat < 1 then f.spellCat = 1 end
            if f.spellCat > nscR then f.spellCat = nscR end
            f.spellCat = f.spellCat + 1
            if f.spellCat > nscR then f.spellCat = 1 end
            local MMRight = Nav_GetMM()
            if MMRight and type(MMRight.FocusSpellCategoryButton) == "function" then
                local idxR = f.spellCat
                pcall(function() MMRight:FocusSpellCategoryButton(idxR) end)
            end
            return true
        end
        if f.zone == "SPTABS" then
            local tabsR = Nav_GetSpellTabs()
            local ntR = 0
            if tabsR then ntR = table.getn(tabsR) end
            if ntR < 1 then return false end
            if not f.spellTab then f.spellTab = Nav_GetSpellTabIdx() or 1 end
            if f.spellTab < 1 then f.spellTab = 1 end
            if f.spellTab > ntR then f.spellTab = ntR end
            f.spellTab = f.spellTab + 1
            if f.spellTab > ntR then f.spellTab = 1 end
            local MMSR = Nav_GetMM()
            if MMSR and type(MMSR.SelectSpellTab) == "function" then
                local idxSR = f.spellTab
                pcall(function() MMSR:SelectSpellTab(idxSR) end)
            end
            return true
        end
        if f.zone == "BUFFS" then
            f.returnZone = "BUFFS"
            local curRB = Nav_GetCurrentTab()
            if curRB == "BAGS" then
                f.zone = "GRID"
            elseif curRB == "SPELLS" then
                local scrRB = Nav_GetSpellActiveScreen()
                if scrRB == 2 then f.zone = "SPGRID" else f.zone = "SPCAT" end
            else
                f.zone = "GRID"
            end
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "SPGRID" then
            local cols = Nav_SpellCols()
            local svis = Nav_VisibleSpellGridCount()
            if math.mod(f.spellSlot, cols) ~= 0 and (f.spellSlot + 1) <= svis then
                f.spellSlot = f.spellSlot + 1
                return true
            end
            return false
        end
        return false
    end
    return false
end

-- FASE 2: navegação BAGS. Retorna true se moveu/tratou.
function Nav_OnBagsDirection(direction)
    local f = Nav.focus
    if direction == "UP" then
        if f.zone == "TABBAR" then return false end
        if f.zone == "EQUIP" then
            if f.equipIndex > 1 then f.equipIndex = f.equipIndex - 1 return true end
            f.returnZone = "EQUIP"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "CATS" then
            f.returnZone = "CATS"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "GRID" then
            local grid = Nav_GetGrid()
            local cols = 8
            if grid and grid.cols then cols = grid.cols end
            if grid and grid.GetCapacity then local ok, _, c = pcall(function() return grid:GetCapacity() end) if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end end
            if (f.gridIndex - cols) >= 1 then
                f.gridIndex = f.gridIndex - cols
                return true
            end
            f.returnZone = "GRID"
            f.zone = "CATS"
            return true
        end
        if f.zone == "PAGENAV" then
            f.returnZone = "PAGENAV"
            f.zone = "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "BUFFS" then
            local bc = Nav_BuffCount()
            if bc < 1 then
                f.zone = "GRID"
                Nav_EnsureFocus()
                return true
            end
            if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
            if f.buffPos > bc then f.buffPos = bc end
            if f.buffPos > 1 then
                f.buffPos = f.buffPos - 1
                return true
            end
            f.returnZone = "BUFFS"
            f.zone = "TABBAR"
            return true
        end
        return false
    end
    if direction == "DOWN" then
        if f.zone == "TABBAR" then
            f.zone = f.returnZone or "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "EQUIP" then
            local eq = Nav_GetEquipButtons()
            local ne = 17
            if eq then ne = table.getn(eq) end
            if f.equipIndex < ne then f.equipIndex = f.equipIndex + 1 return true end
            return false
        end
        if f.zone == "CATS" then
            f.zone = "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "GRID" then
            local grid = Nav_GetGrid()
            local cols = 8
            if grid and grid.cols then cols = grid.cols end
            if grid and grid.GetCapacity then local ok, _, c = pcall(function() return grid:GetCapacity() end) if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end end
            local vis = Nav_VisibleGridCount()
            if (f.gridIndex + cols) <= vis then
                f.gridIndex = f.gridIndex + cols
                return true
            end
            local pgDown = Nav_VisiblePageBtns()
            local npDown = 0
            if pgDown then npDown = table.getn(pgDown) end
            if npDown > 0 then
                f.zone = "PAGENAV"
                if not f.pageBtn or f.pageBtn < 1 then f.pageBtn = 1 end
                if f.pageBtn > npDown then f.pageBtn = npDown end
                return true
            end
            return false
        end
        if f.zone == "PAGENAV" then
            return false
        end
        if f.zone == "BUFFS" then
            local bc = Nav_BuffCount()
            if bc < 1 then
                f.zone = "GRID"
                Nav_EnsureFocus()
                return true
            end
            if not f.buffPos or f.buffPos < 1 then
                f.buffPos = 1
                Nav_EnsureFocus()
                return true
            end
            if f.buffPos > bc then
                f.buffPos = bc
                return true
            end
            if f.buffPos < bc then
                f.buffPos = f.buffPos + 1
                return true
            end
            return false
        end
        return false
    end
    if direction == "LEFT" then
        if f.zone == "TABBAR" then
            if f.tabIdx > 1 then f.tabIdx = f.tabIdx - 1 return true end
            return false
        end
        if f.zone == "EQUIP" then return false end
        if f.zone == "CATS" then
            local cats = Nav_GetCatButtons()
            local nc = 0
            if cats then nc = table.getn(cats) end
            if f.catIndex and f.catIndex < nc then
                f.catIndex = f.catIndex + 1
                return true
            end
            f.zone = "EQUIP"
            return true
        end
        if f.zone == "BUFFS" then
            f.zone = "EQUIP"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "GRID" then
            local grid = Nav_GetGrid()
            local cols = 8
            if grid and grid.cols then cols = grid.cols end
            if grid and grid.GetCapacity then local ok, _, c = pcall(function() return grid:GetCapacity() end) if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end end
            if math.mod(f.gridIndex - 1, cols) ~= 0 then
                f.gridIndex = f.gridIndex - 1
                return true
            end
            local bc = Nav_BuffCount()
            if bc > 0 then
                f.zone = "BUFFS"
                if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
                if f.buffPos > bc then f.buffPos = bc end
                Nav_EnsureFocus()
                return true
            end
            f.zone = "EQUIP"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "PAGENAV" then
            local pgL = Nav_VisiblePageBtns()
            local npL = 0
            if pgL then npL = table.getn(pgL) end
            if npL < 1 then
                f.zone = "GRID"
                Nav_EnsureFocus()
                return true
            end
            if not f.pageBtn or f.pageBtn < 1 then f.pageBtn = 1 end
            if f.pageBtn > npL then f.pageBtn = npL end
            if npL > 1 then
                f.pageBtn = f.pageBtn - 1
                if f.pageBtn < 1 then f.pageBtn = npL end
            end
            return true
        end
        return false
    end
    if direction == "RIGHT" then
        if f.zone == "TABBAR" then
            local tabs = Nav_GetTabButtons()
            local nt = 5
            if tabs then nt = table.getn(tabs) end
            if f.tabIdx < nt then f.tabIdx = f.tabIdx + 1 return true end
            return false
        end
        if f.zone == "EQUIP" then
            local bc = Nav_BuffCount()
            if bc > 0 then
                f.zone = "BUFFS"
                if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
                if f.buffPos > bc then f.buffPos = bc end
                Nav_EnsureFocus()
                return true
            end
            local curEB = Nav_GetCurrentTab()
            if curEB == "SPELLS" then
                local scrEB = Nav_GetSpellActiveScreen()
                if scrEB == 2 then f.zone = "SPGRID" else f.zone = "SPCAT" end
            else
                f.zone = "GRID"
            end
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "CATS" then
            local cats = Nav_GetCatButtons()
            local nc = 0
            if cats then nc = table.getn(cats) end
            if f.catIndex and f.catIndex > 1 then
                f.catIndex = f.catIndex - 1
                return true
            end
            f.zone = "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "BUFFS" then
            f.returnZone = "BUFFS"
            local curBRB = Nav_GetCurrentTab()
            if curBRB == "BAGS" then
                f.zone = "GRID"
            elseif curBRB == "SPELLS" then
                local scrBRB = Nav_GetSpellActiveScreen()
                if scrBRB == 2 then f.zone = "SPGRID" else f.zone = "SPCAT" end
            else
                f.zone = "GRID"
            end
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "GRID" then
            local grid = Nav_GetGrid()
            local cols = 8
            if grid and grid.cols then cols = grid.cols end
            if grid and grid.GetCapacity then local ok, _, c = pcall(function() return grid:GetCapacity() end) if ok and type(c) == "number" and c >= 4 and c <= 11 then cols = c end end
            local vis = Nav_VisibleGridCount()
            if math.mod(f.gridIndex, cols) ~= 0 and (f.gridIndex + 1) <= vis then
                f.gridIndex = f.gridIndex + 1
                return true
            end
            return false
        end
        if f.zone == "PAGENAV" then
            local pgR = Nav_VisiblePageBtns()
            local npR = 0
            if pgR then npR = table.getn(pgR) end
            if npR < 1 then
                f.zone = "GRID"
                Nav_EnsureFocus()
                return true
            end
            if not f.pageBtn or f.pageBtn < 1 then f.pageBtn = 1 end
            if f.pageBtn > npR then f.pageBtn = npR end
            if npR > 1 then
                f.pageBtn = f.pageBtn + 1
                if f.pageBtn > npR then f.pageBtn = 1 end
            end
            return true
        end
        return false
    end
    return false
end

-- Hold-to-repeat (molde MailScreen:5261-5313). UP/DOWN/LEFT/RIGHT repetem.
function Nav:StartRepeat(direction)
    if not self:IsActive() then return end
    self:OnDirection(direction)
    self.navState.direction = direction
    self.navState.timer = self.navState.initialDelay
    self:EnsureRepeatTicker()
end

function Nav:StopRepeat(direction)
    if not direction or self.navState.direction == direction then
        self.navState.direction = nil
        self.navState.timer = 0
    end
end

function Nav:EnsureRepeatTicker()
    if self.ticker then return end
    local f = CreateFrame("Frame", "ConsoleMode_MainMenuNavRepeatTicker")
    f:SetScript("OnUpdate", function()
        if not Nav:IsActive() then
            Nav.navState.direction = nil
            return
        end
        local dir = Nav.navState.direction
        if dir then
            local elapsed = arg1 or 0.016
            Nav.navState.timer = Nav.navState.timer - elapsed
            if Nav.navState.timer <= 0 then
                Nav:OnDirection(dir)
                Nav.navState.timer = Nav.navState.interval
            end
        end
    end)
    self.ticker = f
end

-- FASE 2: A/B/Y consomem em BAGS (retornam true); FASE 3: + SPELLS; demais, false.
function Nav:OnConfirm()
    if not self:IsActive() then return false end
    local curTabCf = Nav_GetCurrentTab()
    if curTabCf == "SPELLS" then
        Nav_EnsureFocus()
        local fs = self.focus
        if fs.zone == "TABBAR" then
            local tabs = Nav_GetTabButtons()
            local MM = Nav_GetMM()
            if tabs and tabs[fs.tabIdx] then
                local btn = tabs[fs.tabIdx]
                if btn then pcall(function() btn:Click() end) end
                return true
            end
            if MM and type(MM.SelectTab) == "function" then return true end
            return true
        end
        if fs.zone == "EQUIP" then
            local eq = Nav_GetEquipButtons()
            if eq and eq[fs.equipIndex] then
                pcall(function() eq[fs.equipIndex]:Click("LeftButton") end)
            end
            return true
        end
        if fs.zone == "BUFFS" then
            return true
        end
        if fs.zone == "SPCAT" then
            local MM = Nav_GetMM()
            if MM then
                if type(MM.FocusSpellCategoryButton) == "function" then
                    local idx = fs.spellCat or 1
                    pcall(function() MM:FocusSpellCategoryButton(idx) end)
                end
                if type(MM.ShowSpellGridScreen) == "function" then
                    local idx2 = fs.spellCat or 1
                    pcall(function() MM:ShowSpellGridScreen(idx2) end)
                end
            end
            fs.zone = "SPGRID"
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            return true
        end
        if fs.zone == "SPGRID" then
            local grid = Nav_GetSpellGrid()
            if grid and grid.slots and grid.slots[fs.spellSlot] then
                pcall(function() grid.slots[fs.spellSlot]:Click("LeftButton") end)
            end
            return true
        end
        return false
    end
    if curTabCf ~= "BAGS" then
        MMNav_Log("|cffe09a15[MMNav]|r A (fase1: cursor ainda trata)")
        return false
    end
    Nav_EnsureFocus()
    local f = self.focus
    if f.zone == "TABBAR" then
        local tabs = Nav_GetTabButtons()
        local MM = Nav_GetMM()
        if tabs and tabs[f.tabIdx] then
            local btn = tabs[f.tabIdx]
            if btn then pcall(function() btn:Click() end) end
            return true
        end
        if MM and type(MM.SelectTab) == "function" then return true end
        return true
    end
    if f.zone == "EQUIP" then
        local eq = Nav_GetEquipButtons()
        if eq and eq[f.equipIndex] then
            pcall(function() eq[f.equipIndex]:Click("LeftButton") end)
        end
        return true
    end
    if f.zone == "CATS" then
        local cats = Nav_GetCatButtons()
        if cats and cats[f.catIndex] then
            pcall(function() cats[f.catIndex]:Click() end)
            self.focus.catIndex = Nav_FindCatIndexForCurrent() or self.focus.catIndex
            Nav_ApplyFocus()
        end
        return true
    end
    if f.zone == "GRID" then
        local grid = Nav_GetGrid()
        if grid and grid.slots and grid.slots[f.gridIndex] then
            pcall(function() grid.slots[f.gridIndex]:Click("LeftButton") end)
        end
        return true
    end
    if f.zone == "BUFFS" then
        return true
    end
    if f.zone == "PAGENAV" then
        local pgC = Nav_VisiblePageBtns()
        local npC = 0
        if pgC then npC = table.getn(pgC) end
        local pbtn = nil
        if f.pageBtn and f.pageBtn >= 1 and f.pageBtn <= npC then
            pbtn = pgC[f.pageBtn]
        end
        if pbtn then pcall(function() pbtn:Click() end) end
        return true
    end
    return false
end

function Nav:OnCancel()
    if not self:IsActive() then return false end
    local curTabCx = Nav_GetCurrentTab()
    if curTabCx == "SPELLS" then
        local ps = Nav_GetPageSpells()
        local scr = nil
        if ps then scr = ps.activeScreen end
        local isGridScreen = (scr == 2)
        if scr == nil then
            isGridScreen = (self.focus and self.focus.zone == "SPGRID")
        end
        if isGridScreen then
            local MM = Nav_GetMM()
            if MM and type(MM.ShowSpellCategoryScreen) == "function" then
                pcall(function() MM:ShowSpellCategoryScreen() end)
            elseif MM and type(MM.HandleSpellsBack) == "function" then
                pcall(function() MM:HandleSpellsBack() end)
            end
            self.focus.zone = "SPCAT"
            if ps and type(ps.focusedCatIdx) == "number" then self.focus.spellCat = ps.focusedCatIdx end
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        Nav_EnsureFocus()
        local fsp = self.focus
        if fsp and fsp.zone == "SPCAT" then
            fsp.zone = "EQUIP"
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        if fsp and fsp.zone == "SPTABS" then
            fsp.zone = "SPGRID"
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        return false
    end
    if curTabCx ~= "BAGS" then
        MMNav_Log("|cffe09a15[MMNav]|r B (fase1: cursor ainda trata)")
        return false
    end
    Nav_EnsureFocus()
    local f = self.focus
    if f.zone == "GRID" then
        f.zone = "CATS"
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        MMNav_PlayMove()
        return true
    end
    if f.zone == "CATS" then
        f.zone = "EQUIP"
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        MMNav_PlayMove()
        return true
    end
    if f.zone == "BUFFS" then
        f.zone = "GRID"
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        MMNav_PlayMove()
        return true
    end
    if f.zone == "PAGENAV" then
        f.zone = "GRID"
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        MMNav_PlayMove()
        return true
    end
    return false
end

function Nav:OnUse()
    if not self:IsActive() then return false end
    local curTabUs = Nav_GetCurrentTab()
    if curTabUs == "SPELLS" then
        Nav_EnsureFocus()
        local fu = self.focus
        if fu.zone == "EQUIP" then
            local eq = Nav_GetEquipButtons()
            if eq and eq[fu.equipIndex] then
                pcall(function() eq[fu.equipIndex]:Click("RightButton") end)
            end
            return true
        end
        if fu.zone == "SPGRID" then
            local grid = Nav_GetSpellGrid()
            if grid and grid.slots and grid.slots[fu.spellSlot] then
                pcall(function() grid.slots[fu.spellSlot]:Click("RightButton") end)
            end
            return true
        end
        if fu.zone == "BUFFS" then
            local vis = Nav_VisibleBuffs()
            local row = nil
            if vis and fu.buffPos then row = vis[fu.buffPos] end
            local isVis = false
            if row and type(row.IsVisible) == "function" then
                local ok, v = pcall(function() return row:IsVisible() end)
                if ok and v then isVis = true end
            end
            if isVis and not row.isWeaponEnchant and row.buffIndex then
                local MM = Nav_GetMM()
                if MM and type(MM.OpenBuffContextMenu) == "function" then
                    pcall(function() MM:OpenBuffContextMenu(row.buffIndex, row) end)
                end
                return true
            end
            return false
        end
        return false
    end
    if curTabUs ~= "BAGS" then
        MMNav_Log("|cffe09a15[MMNav]|r Y (fase1: cursor ainda trata)")
        return false
    end
    Nav_EnsureFocus()
    local f = self.focus
    if f.zone == "EQUIP" then
        local eq = Nav_GetEquipButtons()
        if eq and eq[f.equipIndex] then
            pcall(function() eq[f.equipIndex]:Click("RightButton") end)
        end
        return true
    end
    if f.zone == "GRID" then
        local grid = Nav_GetGrid()
        if grid and grid.slots and grid.slots[f.gridIndex] then
            pcall(function() grid.slots[f.gridIndex]:Click("RightButton") end)
        end
        return true
    end
    if f.zone == "BUFFS" then
        local vis = Nav_VisibleBuffs()
        local row = nil
        if vis and f.buffPos then row = vis[f.buffPos] end
        local isVis = false
        if row and type(row.IsVisible) == "function" then
            local ok, v = pcall(function() return row:IsVisible() end)
            if ok and v then isVis = true end
        end
        if isVis and not row.isWeaponEnchant and row.buffIndex then
            local MM = Nav_GetMM()
            if MM and type(MM.OpenBuffContextMenu) == "function" then
                pcall(function() MM:OpenBuffContextMenu(row.buffIndex, row) end)
            end
            return true
        end
        return false
    end
    return false
end

function Nav:OnSecondary()
    if not self:IsActive() then return false end
    MMNav_Log("|cffe09a15[MMNav]|r X (fase2 BAGS: sem acao)")
    return false
end

function Nav:OnNextTab()
    MMNav_Log("|cffe09a15[MMNav]|r RB (fase2: cursor ainda trata)")
    return false
end

function Nav:OnPrevTab()
    MMNav_Log("|cffe09a15[MMNav]|r LB (fase2: cursor ainda trata)")
    return false
end

function Nav:OnNextSubTab()
    MMNav_Log("|cffe09a15[MMNav]|r RT (fase2: cursor ainda trata)")
    return false
end

function Nav:OnPrevSubTab()
    MMNav_Log("|cffe09a15[MMNav]|r LT (fase2: cursor ainda trata)")
    return false
end

function Nav:OnSmartTab()
    MMNav_Log("|cffe09a15[MMNav]|r TAB (fase2: cursor ainda trata)")
    return false
end

-- Sincroniza tabIdx com a aba aberta (chamado ao abrir/trocar de aba).
function Nav:SyncTab()
    local cur = Nav_GetCurrentTab()
    local tabs = Nav_GetTabButtons()
    if cur and tabs then
        local n = table.getn(tabs)
        for i = 1, n do
            local btn = tabs[i]
            if btn and btn.tabData and btn.tabData.id == cur then
                self.focus.tabIdx = i
                break
            end
        end
    end
end

-- Inicializacao vazia e segura: so garante defaults, sem eventos, sem
-- tocar em Cursor/Hooks/Keybindings.
function Nav:Initialize()
    self.navState = self.navState or { direction = nil, timer = 0, initialDelay = 0.35, interval = 0.12 }
    if self.navState.initialDelay == nil then self.navState.initialDelay = 0.35 end
    if self.navState.interval == nil then self.navState.interval = 0.12 end
    if self.navState.timer == nil then self.navState.timer = 0 end
    if self.ticker == nil then self.ticker = nil end
    self.focus = self.focus or { zone = "GRID", tabIdx = 1, equipIndex = 1, catIndex = nil, gridIndex = 1, buffPos = 1, pageBtn = 1, returnZone = "GRID", spellCat = nil, spellSlot = nil, spellTab = nil }
    if self.focus.buffPos == nil or self.focus.buffPos < 1 then self.focus.buffPos = 1 end
    if self.focus.pageBtn == nil or self.focus.pageBtn < 1 then self.focus.pageBtn = 1 end
    if self.focus.spellCat ~= nil and self.focus.spellCat < 1 then self.focus.spellCat = 1 end
    if self.focus.spellSlot == nil or self.focus.spellSlot < 1 then self.focus.spellSlot = 1 end
    if self.focus.spellTab == nil or self.focus.spellTab < 1 then self.focus.spellTab = 1 end
end
