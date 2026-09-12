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
Nav.focus = Nav.focus or { zone = "GRID", tabIdx = 1, equipIndex = 1, catIndex = nil, gridIndex = 1, buffPos = 1, pageBtn = 1, returnZone = "GRID", spellCat = nil, spellSlot = nil, spellTab = nil, talentSpec = nil, talentSlot = nil, spellPageBtn = 1, questIdx = nil, qDetail = false, npcIdx = 1, zonaGrupo = "NAV", zonaIdx = 1, qMapaOrigem = nil, mapaIdx = 1 }

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

-- FASE 4: acesso a aba TALENTS (defensivo; tudo via raiz MM, nunca na pagina).
-- pageTalents = tabContainer.pages["TALENTS"]; activeScreen 1=specs/2=arvore;
-- arvore: treeScreen.slotsByTierCol[tier 1..7][col 1..4], col1=topo;
-- slot visivel = IsVisible + talentData (skip escondidos, nada de indice linear).
local function Nav_GetPageTalents()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.tabContainer then return nil end
    if not MM.tabContainer.pages then return nil end
    return MM.tabContainer.pages["TALENTS"]
end

local function Nav_GetTalentActiveScreen()
    local pt = Nav_GetPageTalents()
    if not pt then return nil end
    if pt.activeScreen then return pt.activeScreen end
    return nil
end

local function Nav_TalentSlotVisible(slot)
    if not slot then return false end
    if not slot.talentData then return false end
    if type(slot.IsVisible) ~= "function" then return false end
    local ok, vis = pcall(function() return slot:IsVisible() end)
    if ok and vis then return true end
    return false
end

local function Nav_GetTalentFirstVisible()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.tabContainer or not MM.tabContainer.pages then return nil end
    local pt = MM.tabContainer.pages["TALENTS"]
    if not pt or not pt.treeScreen or not pt.treeScreen.slotsByTierCol then return nil end
    local grid = pt.treeScreen.slotsByTierCol
    for tier = 1, 7 do
        local row = grid[tier]
        if row then
            for col = 1, 4 do
                local slot = row[col]
                if Nav_TalentSlotVisible(slot) then return slot end
            end
        end
    end
    return nil
end

local function Nav_GetTalentSlotTierCol(slot)
    if not slot then return nil, nil end
    local tier = slot.tier
    local col = slot.column
    if type(tier) ~= "number" and slot.talentData and type(slot.talentData.tier) == "number" then tier = slot.talentData.tier end
    if type(col) ~= "number" and slot.talentData and type(slot.talentData.column) == "number" then col = slot.talentData.column end
    if type(tier) ~= "number" or type(col) ~= "number" then return nil, nil end
    return tier, col
end

local function Nav_GetTalentDefaultZone()
    local MM = Nav_GetMM()
    if not MM then return "TALENTS1" end
    if not MM.tabContainer or not MM.tabContainer.pages then return "TALENTS1" end
    local pt = MM.tabContainer.pages["TALENTS"]
    if pt and pt.activeScreen == 2 then return "TALENTS2" end
    return "TALENTS1"
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

-- SORT: sortBtn visivel (headerBar BAGS; MainMenu.lua:4280-4314).
local function Nav_SortVisible()
    local pb = Nav_GetPageBags()
    if not pb then return false end
    local sb = pb.sortBtn
    if not sb then return false end
    if type(sb.IsVisible) ~= "function" then return false end
    local ok, vis = pcall(function() return sb:IsVisible() end)
    if ok and vis then return true end
    return false
end

-- SPPAGE (espelho PAGENAV): botoes [<] [>] de SPELLS visiveis na ordem (pageNav escondido = vazio).
local function Nav_VisibleSpellPageBtns()
    local out = {}
    local ps = Nav_GetPageSpells()
    if not ps then return out end
    if ps.pageNav and type(ps.pageNav.IsVisible) == "function" then
        local ok, vis = pcall(function() return ps.pageNav:IsVisible() end)
        if not (ok and vis) then return out end
    end
    local prev = ps.prevPageBtn
    if prev and type(prev.IsVisible) == "function" then
        local ok, vis = pcall(function() return prev:IsVisible() end)
        if ok and vis then table.insert(out, prev) end
    end
    local nxt = ps.nextPageBtn
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

    -- SORT: sem indice; invisivel volta p/ CATS.
    if f.zone == "SORT" and not Nav_SortVisible() then
        f.zone = "CATS"
    end
    -- SPPAGE (espelho PAGENAV): spellPageBtn 1..2; sem botao visivel volta p/ SPGRID.
    if not f.spellPageBtn or f.spellPageBtn < 1 then f.spellPageBtn = 1 end
    if f.zone == "SPPAGE" then
        local spbtns = Nav_VisibleSpellPageBtns()
        local nsp = 0
        if spbtns then nsp = table.getn(spbtns) end
        if nsp < 1 then
            f.zone = "SPGRID"
        elseif f.spellPageBtn > nsp then
            f.spellPageBtn = nsp
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
    -- FASE 4: clamp TALENTS (talentSpec init focusedSpecIdx ou 1;
    -- talentSlot = referencia ao slot focado, init focusedTalentSlot ou firstVisible).
    do
        local MM4 = Nav_GetMM()
        local pt4 = nil
        if MM4 and MM4.tabContainer and MM4.tabContainer.pages then
            pt4 = MM4.tabContainer.pages["TALENTS"]
        end
        if not f.talentSpec or f.talentSpec < 1 then
            if pt4 and type(pt4.focusedSpecIdx) == "number" and pt4.focusedSpecIdx >= 1 and pt4.focusedSpecIdx <= 3 then
                f.talentSpec = pt4.focusedSpecIdx
            else
                f.talentSpec = 1
            end
        end
        if f.talentSpec > 3 then f.talentSpec = 3 end
        if not Nav_TalentSlotVisible(f.talentSlot) then
            local keep = pt4 and pt4.focusedTalentSlot
            if Nav_TalentSlotVisible(keep) then
                f.talentSlot = keep
            else
                local fv = Nav_GetTalentFirstVisible()
                if fv then f.talentSlot = fv end
            end
        end
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

    if f.zone ~= "TABBAR" and f.zone ~= "EQUIP" and f.zone ~= "CATS" and f.zone ~= "GRID" and f.zone ~= "BUFFS" and f.zone ~= "PAGENAV" and f.zone ~= "SORT" and f.zone ~= "SPCAT" and f.zone ~= "SPGRID" and f.zone ~= "SPTABS" and f.zone ~= "SPPAGE" and f.zone ~= "TALENTS1" and f.zone ~= "TALENTS2" and f.zone ~= "QMISSOES" and f.zone ~= "QDETALHE" and f.zone ~= "ZONAS" and f.zone ~= "QNPCS" and f.zone ~= "QZONAS" and f.zone ~= "QMAPAS" then
        f.zone = "GRID"
    end
    if f.returnZone ~= "EQUIP" and f.returnZone ~= "CATS" and f.returnZone ~= "GRID" and f.returnZone ~= "BUFFS" and f.returnZone ~= "PAGENAV" and f.returnZone ~= "SORT" and f.returnZone ~= "SPCAT" and f.returnZone ~= "SPGRID" and f.returnZone ~= "SPTABS" and f.returnZone ~= "SPPAGE" and f.returnZone ~= "TALENTS1" and f.returnZone ~= "TALENTS2" and f.returnZone ~= "QMISSOES" and f.returnZone ~= "QDETALHE" and f.returnZone ~= "ZONAS" and f.returnZone ~= "QNPCS" and f.returnZone ~= "QZONAS" and f.returnZone ~= "QMAPAS" then
        f.returnZone = "GRID"
    end
    -- Conversao por aba: evita zona presa na aba errada (BAGS/SPELLS/TALENTS).
    local curTabEf = Nav_GetCurrentTab()
    if curTabEf == "SPELLS" then
        local scr = Nav_GetSpellActiveScreen()
        local defSp = "SPCAT"
        if scr == 2 then defSp = "SPGRID" end
        if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "TALENTS1" or f.zone == "TALENTS2" then
            f.zone = defSp
        end
        if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" then
            f.returnZone = defSp
        end
        if f.zone == "BUFFS" and bc < 1 then
            f.zone = defSp
        end
    elseif curTabEf == "BAGS" then
        if f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "TALENTS1" or f.zone == "TALENTS2" then
            f.zone = "GRID"
        end
        if f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" then
            f.returnZone = "GRID"
        end
    elseif curTabEf == "TALENTS" then
        local defTal = "TALENTS1"
        local scrT = Nav_GetTalentActiveScreen()
        if scrT == 2 then defTal = "TALENTS2" end
        if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" then
            f.zone = defTal
        end
        if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" then
            f.returnZone = defTal
        end
        if f.zone == "BUFFS" and bc < 1 then
            f.zone = defTal
        end
    elseif curTabEf == "QUESTS" then
        if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "TALENTS1" or f.zone == "TALENTS2" or f.zone == "EQUIP" or f.zone == "BUFFS" then
            f.zone = "QMISSOES"
        end
        if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" then
            f.returnZone = "QMISSOES"
        end
    else
        if f.zone == "QMISSOES" or f.zone == "QDETALHE" or f.zone == "ZONAS" or f.zone == "QNPCS" or f.zone == "QZONAS" or f.zone == "QMAPAS" then
            if curTabEf == "BAGS" then f.zone = "GRID"
            elseif curTabEf == "SPELLS" then f.zone = "SPCAT"
            elseif curTabEf == "TALENTS" then f.zone = "TALENTS1"
            else f.zone = "GRID" end
        end
        if f.returnZone == "QMISSOES" or f.returnZone == "QDETALHE" or f.returnZone == "ZONAS" or f.returnZone == "QNPCS" or f.returnZone == "QZONAS" or f.returnZone == "QMAPAS" then
            f.returnZone = "GRID"
        end
    end
    if f.zone == "QMISSOES" or f.zone == "QDETALHE" then
        if f.qDetail == nil then f.qDetail = (f.zone == "QDETALHE") end
        if f.zone == "QDETALHE" then f.qDetail = true end
        pcall(function() Nav_EnsureQuestIdx() end)
    elseif f.zone == "ZONAS" then
        if f.qDetail == nil then f.qDetail = false end
    elseif f.zone == "QNPCS" or f.zone == "QZONAS" or f.zone == "QMAPAS" then
        if f.qDetail == nil then f.qDetail = false end
        if not f.npcIdx or f.npcIdx < 1 then f.npcIdx = 1 end
        if not f.zonaGrupo then f.zonaGrupo = "NAV" end
        if f.zonaGrupo ~= "NAV" and f.zonaGrupo ~= "LISTA" then f.zonaGrupo = "NAV" end
        if not f.zonaIdx or f.zonaIdx < 1 then f.zonaIdx = 1 end
        pcall(function() Nav_EnsureNpcZonaFocus() end)
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

    -- FASE 4 TALENTS visual (via raiz MM, nunca na pagina):
    -- specs via FocusTalentSpecButton; arvore via FocusTalentSlot (focusBorder + DetailCard).
    -- FocusTalentSlot so em zone==TALENTS2 (foco unico interno); fora da zona nao chamar
    -- (arvore escondida junto da tela). backBtn fica p/ mouse nesta fase.
    do
        local MM4v = Nav_GetMM()
        if MM4v and MM4v.tabContainer and MM4v.tabContainer.currentTab == "TALENTS" then
            if f.zone == "TALENTS1" then
                if type(MM4v.FocusTalentSpecButton) == "function" then
                    local idx = f.talentSpec or 1
                    pcall(function() MM4v:FocusTalentSpecButton(idx) end)
                end
            else
                -- Foco unico (espelho SPCAT): fora de TALENTS1 repinta os 3 specButtons;
                -- ativa fica dim (ouro-apagado), demais inativas, sem highlight/focusBorder.
                pcall(function()
                    local page = MM4v and MM4v.tabContainer and MM4v.tabContainer.pages and MM4v.tabContainer.pages["TALENTS"]
                    local sbs = page and page.specButtons
                    if not sbs then return end
                    local activeIdx = f.talentSpec or page.focusedSpecIdx or 1
                    local n = table.getn(sbs)
                    for i = 1, n do
                        local b = sbs[i]
                        if b then
                            if b.focusBorder and type(b.focusBorder.Hide) == "function" then b.focusBorder:Hide() end
                            if b.highlight and type(b.highlight.Hide) == "function" then b.highlight:Hide() end
                            if i == activeIdx then
                                if b.activeBorder and type(b.activeBorder.Show) == "function" then b.activeBorder:Show() end
                                if b.inactiveBorder and type(b.inactiveBorder.Hide) == "function" then b.inactiveBorder:Hide() end
                                if b.specName and type(b.specName.SetTextColor) == "function" then b.specName:SetTextColor(0.88, 0.60, 0.08) end
                            else
                                if b.activeBorder and type(b.activeBorder.Hide) == "function" then b.activeBorder:Hide() end
                                if b.inactiveBorder and type(b.inactiveBorder.Show) == "function" then b.inactiveBorder:Show() end
                                if b.specName and type(b.specName.SetTextColor) == "function" then b.specName:SetTextColor(0.90, 0.90, 0.90) end
                            end
                        end
                    end
                end)
            end
            if f.zone == "TALENTS2" then
                if type(MM4v.FocusTalentSlot) == "function" and Nav_TalentSlotVisible(f.talentSlot) then
                    local slot = f.talentSlot
                    pcall(function() MM4v:FocusTalentSlot(slot) end)
                end
            else
                -- Espelho SPCAT/GRID else-hide: ao sair de TALENTS2 esconde o focus
                -- visuals de TODOS os allSlots sem zerar focusedTalentSlot/indices.
                pcall(function()
                    local page = MM4v and MM4v.tabContainer and MM4v.tabContainer.pages and MM4v.tabContainer.pages["TALENTS"]
                    local treeScreen = page and page.treeScreen
                    local allSlots = (treeScreen and treeScreen.allSlots) or (page and page.allSlots) or MM4v.allTalentSlots or MM4v.allSlots
                    if not allSlots then return end
                    local n = table.getn(allSlots)
                    for i = 1, n do
                        local s = allSlots[i]
                        if s then
                            if s.focusBorder and type(s.focusBorder.Hide) == "function" then s.focusBorder:Hide() end
                            if s.highlight and type(s.highlight.Hide) == "function" then s.highlight:Hide() end
                            if s.FocusBorder and s.FocusBorder ~= s.focusBorder and type(s.FocusBorder.Hide) == "function" then s.FocusBorder:Hide() end
                            if s.Highlight and s.Highlight ~= s.highlight and type(s.Highlight.Hide) == "function" then s.Highlight:Hide() end
                            if s.focus and type(s.focus.Hide) == "function" then s.focus:Hide() end
                            if s.hover and type(s.hover.Hide) == "function" then s.hover:Hide() end
                            if s.glow and type(s.glow.Hide) == "function" then s.glow:Hide() end
                            if s.focusGlow and type(s.focusGlow.Hide) == "function" then s.focusGlow:Hide() end
                            if s.selection and type(s.selection.Hide) == "function" then s.selection:Hide() end
                            if s.flash and type(s.flash.Hide) == "function" then s.flash:Hide() end
                            if type(s.UnlockHighlight) == "function" then pcall(function() s:UnlockHighlight() end) end
                        end
                    end
                end)
            end
        end
    end

    -- QUESTS visual (bug 2/12/20): mesma colecao hide/pintor, foco unico.
    -- QMISSOES/QDETALHE: focada ouro, ativa ambar; fora das zonas, repinta todas (so ativa ambar).
    do
        local curQ = Nav_GetCurrentTab()
        if curQ == "QUESTS" then
            pcall(function() Nav_PaintQuests() end)
            pcall(function() Nav_PaintNpcs() end)
            pcall(function() Nav_PaintZonas() end)
        else
            pcall(function()
                local qp = Nav_GetQuestPanel()
                if not qp or not qp.questButtons then return end
                local n = table.getn(qp.questButtons)
                local activeIdx = qp.selectedQuestIndex
                if not activeIdx then
                    local MMq = Nav_GetMM()
                    if MMq then activeIdx = MMq.selectedQuestIndex end
                end
                for i = 1, n do
                    local b = qp.questButtons[i]
                    if b and b.highlight then
                        if b.questLogIndex and activeIdx and b.questLogIndex == activeIdx and not b.isHeader then
                            b.highlight:Show()
                            b.highlight:SetVertexColor(0.88, 0.60, 0.08, 0.35)
                        else
                            b.highlight:Hide()
                        end
                    end
                end
            end)
            pcall(function() Nav_PaintNpcs() end)
            pcall(function() Nav_PaintZonas() end)
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

    -- SORT (BAGS): sortBtn focado ouro (backdrop; defensivo, espelho OnEnter/OnLeave MainMenu.lua:4294-4301).
    do
        local pbSort = Nav_GetPageBags()
        local sb = pbSort and pbSort.sortBtn
        if sb then
            if f.zone == "SORT" then
                if sb.fullHi and type(sb.fullHi.Show) == "function" then
                    pcall(function() sb.fullHi:Show() end)
                end
                if type(sb.SetBackdropBorderColor) == "function" then
                    pcall(function() sb:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.95) end)
                end
                if type(sb.SetBackdropColor) == "function" then
                    pcall(function() sb:SetBackdropColor(0.20, 0.15, 0.10, 0.90) end)
                elseif sb.highlight and type(sb.highlight.Show) == "function" then
                    pcall(function() sb.highlight:Show() end)
                end
            else
                if sb.fullHi and type(sb.fullHi.Hide) == "function" then
                    pcall(function() sb.fullHi:Hide() end)
                end
                if type(sb.SetBackdropBorderColor) == "function" then
                    pcall(function() sb:SetBackdropBorderColor(0.60, 0.48, 0.32, 0.85) end)
                end
                if type(sb.SetBackdropColor) == "function" then
                    pcall(function() sb:SetBackdropColor(0.12, 0.09, 0.06, 0.75) end)
                end
                if sb.highlight and type(sb.highlight.Hide) == "function" then
                    pcall(function() sb.highlight:Hide() end)
                end
            end
        end
    end

    -- SPPAGE (espelho PAGENAV): botao focado ouro (fullHi se existir, senao backdrop).
    do
        local psForPage = Nav_GetPageSpells()
        if psForPage and (psForPage.prevPageBtn or psForPage.nextPageBtn) then
            local spbtns = Nav_VisibleSpellPageBtns()
            local focusedSpBtn = nil
            if f.zone == "SPPAGE" and spbtns then
                local nspv = table.getn(spbtns)
                if f.spellPageBtn and f.spellPageBtn >= 1 and f.spellPageBtn <= nspv then
                    focusedSpBtn = spbtns[f.spellPageBtn]
                end
            end
            local allSpBtns = { psForPage.prevPageBtn, psForPage.nextPageBtn }
            for i = 1, 2 do
                local b = allSpBtns[i]
                if b then
                    if focusedSpBtn and b == focusedSpBtn then
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

-- TASK A: QUESTS (zonas QMISSOES lista vertical + QDETALHE inspecao).
-- Tudo via raiz MM (Nav_GetMM); loga se metodo ausente (bug 4).
-- QMISSOES: UP/DOWN via SelectQuest (foco unico + DetailCard, sem snap de mapa);
-- QDETALHE: so inspecao. Lista vertical = UP/DOWN (bug 8).
local function Nav_GetQuestPanel()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if not MM.tabContainer then return nil end
    if not MM.tabContainer.pages then return nil end
    local pq = MM.tabContainer.pages["QUESTS"]
    if not pq then return nil end
    return pq.questPanel
end

local function Nav_GetQuestButtons()
    local qp = Nav_GetQuestPanel()
    if not qp then return nil end
    return qp.questButtons
end

local function Nav_GetQuestSelectable()
    local out = {}
    local okN, numEntries = pcall(function()
        if type(getglobal("GetNumQuestLogEntries")) == "function" then
            return getglobal("GetNumQuestLogEntries")()
        end
        return 0
    end)
    if not okN or type(numEntries) ~= "number" or numEntries < 1 then return out end
    for i = 1, numEntries do
        local okT, title, _, _, isHeader = pcall(function()
            return getglobal("GetQuestLogTitle")(i)
        end)
        if okT and title and title ~= "" and not isHeader then
            table.insert(out, i)
        end
    end
    return out
end

local function Nav_EnsureQuestIdx()
    local f = Nav.focus
    if f.qDetail == nil then f.qDetail = false end
    local sel = Nav_GetQuestSelectable()
    local n = table.getn(sel)
    if n < 1 then
        if not f.questIdx or f.questIdx < 1 then f.questIdx = 1 end
        return f.questIdx
    end
    local qp = Nav_GetQuestPanel()
    local cur = f.questIdx
    if not cur or cur < 1 then
        local saved = nil
        if qp and type(qp.selectedQuestIndex) == "number" then saved = qp.selectedQuestIndex end
        if not saved then
            local MM = Nav_GetMM()
            if MM and type(MM.selectedQuestIndex) == "number" then saved = MM.selectedQuestIndex end
        end
        cur = saved or sel[1] or 1
    end
    local found = false
    for i = 1, n do
        if sel[i] == cur then found = true; break end
    end
    if not found then
        local qpSel = qp and qp.selectedQuestIndex
        local inList = false
        if qpSel then
            for i = 1, n do
                if sel[i] == qpSel then inList = true; break end
            end
        end
        if inList then cur = qpSel else cur = sel[1] end
    end
    f.questIdx = cur
    return cur
end

local function Nav_QuestHasReward(questIdx)
    local qp = Nav_GetQuestPanel()
    if qp and qp.detailCard then
        local dc = qp.detailCard
        local okR, hasVis = pcall(function()
            if dc.rewardSlots then
                local rn = table.getn(dc.rewardSlots)
                for s = 1, rn do
                    local slot = dc.rewardSlots[s]
                    if slot and type(slot.IsVisible) == "function" then
                        local okV, vis = pcall(function() return slot:IsVisible() end)
                        if okV and vis then return true end
                    end
                end
            end
            if dc.money and type(dc.money.IsVisible) == "function" then
                local okM, mvis = pcall(function() return dc.money:IsVisible() end)
                if okM and mvis then return true end
            end
            return false
        end)
        if okR and hasVis then return true end
    end
    local okQ, hasQ = pcall(function()
        if type(getglobal("GetNumQuestLogRewards")) == "function" and type(getglobal("GetNumQuestLogChoices")) == "function" then
            local nr = getglobal("GetNumQuestLogRewards")() or 0
            local nc = getglobal("GetNumQuestLogChoices")() or 0
            if nr > 0 or nc > 0 then return true end
        end
        if type(getglobal("GetQuestLogRewardMoney")) == "function" then
            local m = getglobal("GetQuestLogRewardMoney")() or 0
            if m > 0 then return true end
        end
        return false
    end)
    if okQ and hasQ then return true end
    return false
end

local function Nav_SelectQuestByIdx(targetIdx)
    local MM = Nav_GetMM()
    if not MM then return false end
    if type(MM.SelectQuest) ~= "function" then
        MMNav_Log("|cffe09a15[MMNav]|r SelectQuest ausente")
        return false
    end
    local qp = Nav_GetQuestPanel()
    if qp then
        local sel = Nav_GetQuestSelectable()
        local n = table.getn(sel)
        local pos = nil
        for i = 1, n do
            if sel[i] == targetIdx then pos = i; break end
        end
        if pos then
            local maxVisible = 10
            local curOffset = qp.questOffset or 0
            local entryIdx = pos
            if qp.entries then
                local okE, found = pcall(function()
                    for ei, ent in ipairs(qp.entries) do
                        if ent.index == targetIdx then return ei end
                    end
                    return nil
                end)
                if okE and found then entryIdx = found end
            end
            if entryIdx <= curOffset then
                qp.questOffset = math.max(0, entryIdx - 1)
            elseif entryIdx > curOffset + maxVisible then
                qp.questOffset = entryIdx - maxVisible
            end
        end
    end
    Nav.focus.questIdx = targetIdx
    pcall(function() MM:SelectQuest(targetIdx, true) end)
    -- bug 17: offset ajustado mas lista não re-renderizada → scroll visual fica preso.
    if qp and type(MM.UpdateQuestsPage) == "function" then
        pcall(function() MM:UpdateQuestsPage() end)
    end
    return true
end

-- Pintor unico das quests (bug 20: mesma colecao hide/pintor; bug 2: foco unico + else).
-- Focada ouro (1.0,0.82,0.20), ativa ambar (0.88,0.60,0.08) (bug 12).
local function Nav_PaintQuests()
    local f = Nav.focus
    local qp = Nav_GetQuestPanel()
    if not qp then return end
    local btns = qp.questButtons
    if not btns then return end
    local okN, n = pcall(function() return table.getn(btns) end)
    if not okN or type(n) ~= "number" or n < 1 then return end
    local activeIdx = qp.selectedQuestIndex
    if not activeIdx then
        local MM = Nav_GetMM()
        if MM then activeIdx = MM.selectedQuestIndex end
    end
    local inQuestZone = (f.zone == "QMISSOES" or f.zone == "QDETALHE")
    for i = 1, n do
        local b = btns[i]
        if b and not b.isHeader and b.highlight then
            local qli = b.questLogIndex
            if inQuestZone and qli and qli == f.questIdx then
                pcall(function() b.highlight:Show() end)
                pcall(function() b.highlight:SetVertexColor(1.0, 0.82, 0.20, 0.35) end)
            elseif qli and activeIdx and qli == activeIdx then
                pcall(function() b.highlight:Show() end)
                pcall(function() b.highlight:SetVertexColor(0.88, 0.60, 0.08, 0.35) end)
            else
                pcall(function() b.highlight:Hide() end)
            end
        elseif b and b.isHeader and b.highlight then
            pcall(function() b.highlight:Hide() end)
        end
    end
end

-- TASK B: QNPCS + QZONAS (bugs 2,4,5,8,10,12,20).
-- Estados: npcIdx=1, zonaGrupo="NAV", zonaIdx=1 (init no Nav.focus).
-- Getters via raiz MM (Nav_GetMM); loga se metodo ausente (bug 4).
-- Lista vertical = UP/DOWN (bug 8); mesma colecao hide/pintor, foco unico + else (bugs 2/20); ouro focada, ambar ativa quando houver (bug 12).
local function Nav_GetMapPanel()
    local MM = Nav_GetMM()
    if not MM then return nil end
    if MM.mapPanel then return MM.mapPanel end
    if MM.questMapPanel then return MM.questMapPanel end
    if MM.tabContainer and MM.tabContainer.pages then
        local pq = MM.tabContainer.pages["QUESTS"]
        if pq then
            if pq.mapPanel then return pq.mapPanel end
            if pq.map then return pq.map end
            if pq.questPanel and pq.questPanel.mapPanel then return pq.questPanel.mapPanel end
        end
    end
    return nil
end

local function Nav_GetNpcPanel()
    local mp = Nav_GetMapPanel()
    if not mp then return nil end
    if mp.NPCListPanel then return mp.NPCListPanel end
    if mp.npcListPanel then return mp.npcListPanel end
    if mp.NPCPanel then return mp.NPCPanel end
    if mp.npcPanel then return mp.npcPanel end
    if mp.npcList then return mp.npcList end
    return nil
end

local function Nav_GetVisibleNpcs()
    local out = {}
    local panel = Nav_GetNpcPanel()
    if not panel or not panel.buttons then return out end
    local okN, n = pcall(function() return table.getn(panel.buttons) end)
    if not okN or type(n) ~= "number" or n < 1 then return out end
    for i = 1, n do
        local b = panel.buttons[i]
        if b and SafeIsVisible(b) then table.insert(out, b) end
    end
    return out
end

local function Nav_GetRawNpcButtons()
    local panel = Nav_GetNpcPanel()
    if not panel or not panel.buttons then return nil end
    return panel.buttons
end

-- Voltar desabilitado: isDisabled ou alpha .55 ou mouse-off/enable-off (bug 10).
local function Nav_NavBtnDisabled(btn)
    if not btn then return true end
    if btn.isDisabled then return true end
    if type(btn.GetAlpha) == "function" then
        local ok, a = pcall(function() return btn:GetAlpha() end)
        if ok and type(a) == "number" and a < 0.6 then return true end
    end
    if type(btn.IsEnabled) == "function" then
        local ok, en = pcall(function() return btn:IsEnabled() end)
        if ok and en == false then return true end
    end
    if type(btn.IsMouseEnabled) == "function" then
        local ok, me = pcall(function() return btn:IsMouseEnabled() end)
        if ok and me == false then return true end
    end
    return false
end

local function Nav_GetVisibleMapNav()
    local out = {}
    local mp = Nav_GetMapPanel()
    if not mp or not mp.navButtons then return out end
    local okN, n = pcall(function() return table.getn(mp.navButtons) end)
    if not okN or type(n) ~= "number" or n < 1 then return out end
    for i = 1, n do
        local b = mp.navButtons[i]
        if b and SafeIsVisible(b) and not Nav_NavBtnDisabled(b) then
            table.insert(out, b)
        end
    end
    return out
end

local function Nav_GetRawNavButtons()
    local mp = Nav_GetMapPanel()
    if not mp or not mp.navButtons then return nil end
    return mp.navButtons
end

local function Nav_GetZoneListFrame()
    local mp = Nav_GetMapPanel()
    if mp then
        if mp.ContinentZoneList then return mp.ContinentZoneList end
        if mp.continentZoneList then return mp.continentZoneList end
        if mp.zoneListFrame then return mp.zoneListFrame end
        if mp.zoneList then return mp.zoneList end
    end
    local gf = getglobal("ConsoleModeMM_ContinentZoneList")
    if gf then return gf end
    return nil
end

local function Nav_GetVisibleZones()
    local out = {}
    local zf = Nav_GetZoneListFrame()
    if not zf then return out end
    if not SafeIsVisible(zf) then return out end
    if not zf.buttons then return out end
    local okN, n = pcall(function() return table.getn(zf.buttons) end)
    if not okN or type(n) ~= "number" or n < 1 then return out end
    for i = 1, n do
        local b = zf.buttons[i]
        if b and SafeIsVisible(b) then table.insert(out, b) end
    end
    return out
end

local function Nav_GetRawZoneButtons()
    local zf = Nav_GetZoneListFrame()
    if not zf or not zf.buttons then return nil end
    return zf.buttons
end

-- QMAPAS: sub-lista de mapas de uma zona (INSTANCIAS).
-- Mora no mesmo frame da lista de zonas (mapPanel.zoneListFrame.buttons,
-- ver MainMenu:BuildInstancesListForZone / ShowInstancesForCurrentView,
-- zoneListMode == "INSTANCES", itens com .zoneName/.parentZone).
-- Getter so visiveis; vazio se frame oculto/ausente.
local function Nav_GetVisibleMapas()
    local out = {}
    local zf = Nav_GetZoneListFrame()
    if not zf then return out end
    if not SafeIsVisible(zf) then return out end
    if not zf.buttons then return out end
    local okN, n = pcall(function() return table.getn(zf.buttons) end)
    if not okN or type(n) ~= "number" or n < 1 then return out end
    for i = 1, n do
        local b = zf.buttons[i]
        if b and SafeIsVisible(b) then table.insert(out, b) end
    end
    return out
end

local function Nav_GetRawMapaButtons()
    local zf = Nav_GetZoneListFrame()
    if not zf or not zf.buttons then return nil end
    return zf.buttons
end

-- EnsureFocus valida: invisivel -> fallback (bug 5).
function Nav_EnsureNpcZonaFocus()
    local f = Nav.focus
    if not f.npcIdx or f.npcIdx < 1 then f.npcIdx = 1 end
    if not f.zonaGrupo then f.zonaGrupo = "NAV" end
    if f.zonaGrupo ~= "NAV" and f.zonaGrupo ~= "LISTA" then f.zonaGrupo = "NAV" end
    if not f.zonaIdx or f.zonaIdx < 1 then f.zonaIdx = 1 end
    if f.zone == "QNPCS" then
        local npcs = Nav_GetVisibleNpcs()
        local n = table.getn(npcs)
        if n < 1 then
            f.npcIdx = 1
        else
            if f.npcIdx > n then f.npcIdx = n end
            local b = npcs[f.npcIdx]
            if not b or not SafeIsVisible(b) then f.npcIdx = 1 end
        end
    elseif f.zone == "QZONAS" then
        local nav = Nav_GetVisibleMapNav()
        local nn = table.getn(nav)
        local zones = Nav_GetVisibleZones()
        local nz = table.getn(zones)
        if f.zonaGrupo == "NAV" then
            if nn < 1 then
                if nz > 0 then f.zonaGrupo = "LISTA"; f.zonaIdx = 1 else f.zonaIdx = 1 end
            else
                if f.zonaIdx > nn then f.zonaIdx = nn end
                local b = nav[f.zonaIdx]
                if not b or not SafeIsVisible(b) or Nav_NavBtnDisabled(b) then f.zonaIdx = 1 end
            end
        else
            if nz < 1 then
                f.zonaGrupo = "NAV"
                if nn > 0 and f.zonaIdx > nn then f.zonaIdx = nn end
                if f.zonaIdx < 1 then f.zonaIdx = 1 end
            else
                if f.zonaIdx > nz then f.zonaIdx = nz end
                local zb = zones[f.zonaIdx]
                if not zb or not SafeIsVisible(zb) then f.zonaIdx = 1 end
            end
        end
    elseif f.zone == "QMAPAS" then
        if not f.mapaIdx or f.mapaIdx < 1 then f.mapaIdx = 1 end
        local mapas = Nav_GetVisibleMapas()
        local nm = table.getn(mapas)
        if nm < 1 then
            f.zone = "QZONAS"
            f.zonaGrupo = "LISTA"
            if f.qMapaOrigem and f.qMapaOrigem >= 1 then
                f.zonaIdx = f.qMapaOrigem
            elseif not f.zonaIdx or f.zonaIdx < 1 then
                f.zonaIdx = 1
            end
        else
            if f.mapaIdx > nm then f.mapaIdx = nm end
            local mb = mapas[f.mapaIdx]
            if not mb or not SafeIsVisible(mb) then f.mapaIdx = 1 end
        end
    end
end

-- Pintor generico ouro + else (bug 2/12/20): focada ouro (1.0,0.82,0.20), demais default.
local function Nav_PaintOneButton(btn, isFocus)
    if not btn then return end
    if isFocus then
        if btn.highlight and type(btn.highlight.Show) == "function" then
            pcall(function() btn.highlight:Show() end)
            if type(btn.highlight.SetVertexColor) == "function" then
                pcall(function() btn.highlight:SetVertexColor(1.0, 0.82, 0.20, 0.35) end)
            end
        end
        if btn.fullHi and type(btn.fullHi.Show) == "function" then
            pcall(function() btn.fullHi:Show() end)
        end
        if btn.label and type(btn.label.SetTextColor) == "function" then
            pcall(function() btn.label:SetTextColor(1.0, 0.82, 0.20) end)
        end
        if btn.title and type(btn.title.SetTextColor) == "function" then
            pcall(function() btn.title:SetTextColor(1.0, 0.82, 0.20) end)
        end
        if btn.catName and type(btn.catName.SetTextColor) == "function" then
            pcall(function() btn.catName:SetTextColor(1.0, 0.82, 0.20) end)
        end
        if type(btn.SetBackdropBorderColor) == "function" then
            pcall(function() btn:SetBackdropBorderColor(1.0, 0.82, 0.20, 0.95) end)
        end
        if type(btn.LockHighlight) == "function" then
            pcall(function() btn:LockHighlight() end)
        end
        if btn.bg and type(btn.bg.SetVertexColor) == "function" then
            pcall(function() btn.bg:SetVertexColor(0.22, 0.18, 0.10, 1.0) end)
        end
    else
        if btn.highlight and type(btn.highlight.Hide) == "function" then
            pcall(function() btn.highlight:Hide() end)
        end
        if btn.fullHi and type(btn.fullHi.Hide) == "function" then
            pcall(function() btn.fullHi:Hide() end)
        end
        if type(btn.UnlockHighlight) == "function" then
            pcall(function() btn:UnlockHighlight() end)
        end
        if type(btn.SetBackdropBorderColor) == "function" then
            pcall(function() btn:SetBackdropBorderColor(0.5, 0.4, 0.28, 0.65) end)
        end
        if btn.label and type(btn.label.SetTextColor) == "function" then
            pcall(function() btn.label:SetTextColor(0.96, 0.88, 0.68, 1.0) end)
        end
        if btn.title and type(btn.title.SetTextColor) == "function" then
            pcall(function() btn.title:SetTextColor(0.96, 0.88, 0.68, 1.0) end)
        end
        if btn.bg and type(btn.bg.SetVertexColor) == "function" then
            pcall(function() btn.bg:SetVertexColor(0.14, 0.12, 0.09, 0.9) end)
        end
    end
end

local function Nav_PaintNpcs()
    local f = Nav.focus
    local raw = Nav_GetRawNpcButtons()
    if not raw then return end
    local okN, n = pcall(function() return table.getn(raw) end)
    if not okN or type(n) ~= "number" or n < 1 then return end
    local vis = Nav_GetVisibleNpcs()
    local inZone = (f.zone == "QNPCS")
    local posByBtn = {}
    local vc = table.getn(vis)
    for vi = 1, vc do
        local vb = vis[vi]
        if vb then posByBtn[vb] = vi end
    end
    for i = 1, n do
        local b = raw[i]
        if b then
            local vpos = posByBtn[b]
            if vpos and inZone and vpos == f.npcIdx then
                Nav_PaintOneButton(b, true)
            else
                Nav_PaintOneButton(b, false)
            end
        end
    end
end

local function Nav_PaintZonas()
    local f = Nav.focus
    local inZone = (f.zone == "QZONAS")
    local rawNav = Nav_GetRawNavButtons()
    if rawNav then
        local okN, n = pcall(function() return table.getn(rawNav) end)
        if okN and type(n) == "number" and n >= 1 then
            local visNav = Nav_GetVisibleMapNav()
            local posByBtn = {}
            local vc = table.getn(visNav)
            for vi = 1, vc do
                local vb = visNav[vi]
                if vb then posByBtn[vb] = vi end
            end
            for i = 1, n do
                local b = rawNav[i]
                if b then
                    local vpos = posByBtn[b]
                    if vpos and inZone and f.zonaGrupo == "NAV" and vpos == f.zonaIdx then
                        Nav_PaintOneButton(b, true)
                    else
                        Nav_PaintOneButton(b, false)
                    end
                end
            end
        end
    end
    local rawZ = Nav_GetRawZoneButtons()
    if rawZ then
        local okZ, nz = pcall(function() return table.getn(rawZ) end)
        if okZ and type(nz) == "number" and nz >= 1 then
            local visZ = Nav_GetVisibleZones()
            local posByZ = {}
            local vz = table.getn(visZ)
            for vi = 1, vz do
                local vb = visZ[vi]
                if vb then posByZ[vb] = vi end
            end
            for i = 1, nz do
                local b = rawZ[i]
                if b then
                    local vpos = posByZ[b]
                    if vpos and inZone and f.zonaGrupo == "LISTA" and vpos == f.zonaIdx then
                        Nav_PaintOneButton(b, true)
                    else
                        Nav_PaintOneButton(b, false)
                    end
                end
            end
        end
    end
    Nav_PaintMapas()
end

-- QMAPAS: ouro no item focado (mapaIdx), else nos demais (bug 2/12/20).
-- Mesmo frame da lista de zonas (INSTANCIAS); so pinta quando zone == QMAPAS.
function Nav_PaintMapas()
    local f = Nav.focus
    if f.zone ~= "QMAPAS" then
        local rawM = Nav_GetRawMapaButtons()
        if rawM then
            local okN, n = pcall(function() return table.getn(rawM) end)
            if okN and type(n) == "number" and n >= 1 then
                for i = 1, n do
                    local b = rawM[i]
                    if b then Nav_PaintOneButton(b, false) end
                end
            end
        end
        return
    end
    local rawM = Nav_GetRawMapaButtons()
    if not rawM then return end
    local okN, n = pcall(function() return table.getn(rawM) end)
    if not okN or type(n) ~= "number" or n < 1 then return end
    local vis = Nav_GetVisibleMapas()
    local posByBtn = {}
    local vc = table.getn(vis)
    for vi = 1, vc do
        local vb = vis[vi]
        if vb then posByBtn[vb] = vi end
    end
    if not f.mapaIdx or f.mapaIdx < 1 then f.mapaIdx = 1 end
    for i = 1, n do
        local b = rawM[i]
        if b then
            local vpos = posByBtn[b]
            if vpos and vpos == f.mapaIdx then
                Nav_PaintOneButton(b, true)
            else
                Nav_PaintOneButton(b, false)
            end
        end
    end
end

-- QNPCS: UP/DOWN param no fim (bug 8: sem wrap); UP primeira -> TABBAR; RIGHT -> QZONAS; LEFT=false.
function Nav_OnQnpcsDirection(direction)
    local f = Nav.focus
    local npcs = Nav_GetVisibleNpcs()
    local n = table.getn(npcs)
    if direction == "UP" then
        if n < 1 then return false end
        if not f.npcIdx or f.npcIdx < 1 then f.npcIdx = 1 end
        if f.npcIdx > n then f.npcIdx = n end
        if f.npcIdx <= 1 then
            f.zone = "TABBAR"
            Nav_EnsureFocus()
            return true
        end
        f.npcIdx = f.npcIdx - 1
        return true
    end
    if direction == "DOWN" then
        if n < 1 then return false end
        if not f.npcIdx or f.npcIdx < 1 then f.npcIdx = 1 end
        if f.npcIdx > n then f.npcIdx = n end
        if f.npcIdx >= n then return false end
        f.npcIdx = f.npcIdx + 1
        return true
    end
    if direction == "RIGHT" then
        f.zone = "QZONAS"
        f.zonaGrupo = "NAV"
        f.zonaIdx = 1
        Nav_EnsureFocus()
        return true
    end
    if direction == "LEFT" then
        return false
    end
    return false
end

-- QZONAS: dois grupos verticais (NAV em cima, LISTA embaixo).
-- UP/DOWN dentro do grupo; DOWN ultimo NAV -> LISTA (se visivel, senao parado);
-- UP primeira LISTA -> NAV; UP do NAV -> TABBAR; LEFT -> QNPCS; RIGHT -> QMISSOES.
function Nav_OnQzonasDirection(direction)
    local f = Nav.focus
    if not f.zonaGrupo then f.zonaGrupo = "NAV" end
    if f.zonaGrupo ~= "NAV" and f.zonaGrupo ~= "LISTA" then f.zonaGrupo = "NAV" end
    if not f.zonaIdx or f.zonaIdx < 1 then f.zonaIdx = 1 end
    local nav = Nav_GetVisibleMapNav()
    local nn = table.getn(nav)
    local zones = Nav_GetVisibleZones()
    local nz = table.getn(zones)
    if direction == "UP" then
        if f.zonaGrupo == "LISTA" then
            if nz < 1 then
                f.zonaGrupo = "NAV"
                Nav_EnsureFocus()
                return true
            end
            if f.zonaIdx > nz then f.zonaIdx = nz end
            if f.zonaIdx > 1 then
                f.zonaIdx = f.zonaIdx - 1
                return true
            end
            f.zonaGrupo = "NAV"
            if nn > 0 then f.zonaIdx = nn else f.zonaIdx = 1 end
            Nav_EnsureFocus()
            return true
        else
            if nn < 1 then return false end
            if f.zonaIdx > nn then f.zonaIdx = nn end
            if f.zonaIdx > 1 then
                f.zonaIdx = f.zonaIdx - 1
                return true
            end
            f.zone = "TABBAR"
            Nav_EnsureFocus()
            return true
        end
    end
    if direction == "DOWN" then
        if f.zonaGrupo == "NAV" then
            if nn < 1 then return false end
            if f.zonaIdx > nn then f.zonaIdx = nn end
            if f.zonaIdx < nn then
                f.zonaIdx = f.zonaIdx + 1
                return true
            end
            if nz > 0 then
                f.zonaGrupo = "LISTA"
                f.zonaIdx = 1
                Nav_EnsureFocus()
                return true
            end
            return false
        else
            if nz < 1 then return false end
            if f.zonaIdx > nz then f.zonaIdx = nz end
            if f.zonaIdx < nz then
                f.zonaIdx = f.zonaIdx + 1
                return true
            end
            return false
        end
    end
    if direction == "LEFT" then
        f.zone = "QNPCS"
        if not f.npcIdx or f.npcIdx < 1 then f.npcIdx = 1 end
        Nav_EnsureFocus()
        return true
    end
    if direction == "RIGHT" then
        f.zone = "QMISSOES"
        f.qDetail = false
        Nav_EnsureFocus()
        return true
    end
    return false
end

-- QMAPAS: sub-lista de mapas da zona (INSTANCIAS). UP/DOWN so scroll, param
-- nos fins (sem wrap); LEFT/RIGHT/UP-na-primeira = false (nada).
function Nav_OnQmapasDirection(direction)
    local f = Nav.focus
    if not f.mapaIdx or f.mapaIdx < 1 then f.mapaIdx = 1 end
    local mapas = Nav_GetVisibleMapas()
    local n = table.getn(mapas)
    if n < 1 then return false end
    if f.mapaIdx > n then f.mapaIdx = n end
    if direction == "UP" then
        if f.mapaIdx <= 1 then return false end
        f.mapaIdx = f.mapaIdx - 1
        return true
    end
    if direction == "DOWN" then
        if f.mapaIdx >= n then return false end
        f.mapaIdx = f.mapaIdx + 1
        return true
    end
    if direction == "LEFT" then return false end
    if direction == "RIGHT" then return false end
    return false
end

function Nav_OnQuestsDirection(direction)
    local f = Nav.focus
    if Nav_GetCurrentTab() ~= "QUESTS" then return false end
    Nav_EnsureQuestIdx()
    if f.zone == "TABBAR" then
        if direction == "DOWN" then
            f.zone = "QMISSOES"
            f.qDetail = false
            Nav_EnsureFocus()
            local qp = Nav_GetQuestPanel()
            if qp and qp.selectedQuestIndex then f.questIdx = qp.selectedQuestIndex end
            Nav_EnsureQuestIdx()
            if qp then
                local MM = Nav_GetMM()
                if MM and type(MM.SelectQuest) == "function" then
                    pcall(function() MM:SelectQuest(f.questIdx, true) end)
                end
            end
            return true
        end
        return false
    end
    if f.zone == "ZONAS" then
        f.zone = "QZONAS"
        if not f.zonaGrupo then f.zonaGrupo = "NAV" end
        if not f.zonaIdx or f.zonaIdx < 1 then f.zonaIdx = 1 end
        Nav_EnsureFocus()
        if direction == "RIGHT" then
            f.zone = "QMISSOES"
            f.qDetail = false
            Nav_EnsureFocus()
            return true
        end
        return Nav_OnQzonasDirection(direction)
    end
    if f.zone == "QNPCS" then
        return Nav_OnQnpcsDirection(direction)
    end
    if f.zone == "QZONAS" then
        return Nav_OnQzonasDirection(direction)
    end
    if f.zone == "QMAPAS" then
        return Nav_OnQmapasDirection(direction)
    end
    if f.zone == "QDETALHE" then
        if direction == "UP" then
            f.zone = "QMISSOES"
            f.qDetail = false
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if f.zone ~= "QMISSOES" then return false end
    if direction == "UP" then
        local sel = Nav_GetQuestSelectable()
        local n = table.getn(sel)
        if n < 1 then return false end
        local pos = nil
        for i = 1, n do
            if sel[i] == f.questIdx then pos = i; break end
        end
        if not pos then
            Nav_EnsureQuestIdx()
            for i = 1, n do
                if sel[i] == f.questIdx then pos = i; break end
            end
        end
        if not pos then return false end
        if pos <= 1 then
            f.zone = "TABBAR"
            Nav_EnsureFocus()
            return true
        end
        Nav_SelectQuestByIdx(sel[pos - 1])
        return true
    end
    if direction == "DOWN" then
        local sel = Nav_GetQuestSelectable()
        local n = table.getn(sel)
        if n < 1 then return false end
        local pos = nil
        for i = 1, n do
            if sel[i] == f.questIdx then pos = i; break end
        end
        if not pos then
            Nav_EnsureQuestIdx()
            for i = 1, n do
                if sel[i] == f.questIdx then pos = i; break end
            end
        end
        if not pos then return false end
        if pos >= n then
            if Nav_QuestHasReward(f.questIdx) then
                f.zone = "QDETALHE"
                f.qDetail = true
                Nav_EnsureFocus()
                return true
            end
            return false
        end
        Nav_SelectQuestByIdx(sel[pos + 1])
        return true
    end
    if direction == "LEFT" then
        f.zone = "QZONAS"
        f.qDetail = false
        if not Nav_GetQuestPanel() then
            f.zone = "QMISSOES"
            Nav_EnsureFocus()
            return false
        end
        local zlist = Nav_GetVisibleZones()
        if zlist and table.getn(zlist) > 0 then
            f.zonaGrupo = "LISTA"
        else
            f.zonaGrupo = "NAV"
        end
        f.zonaIdx = 1
        Nav_EnsureFocus()
        return true
    end
    if direction == "RIGHT" then
        return false
    end
    return false
end

-- Roteador OnDirection. FASE 2: BAGS real; FASE 3: SPELLS real; demais, log.
function Nav:OnDirection(direction)
    if not self:IsActive() then return end
    local curTab = Nav_GetCurrentTab()
    if curTab == "TALENTS" then
        Nav_EnsureFocus()
        local movedT = Nav_OnTalentsDirection(direction)
        Nav_ApplyFocus()
        if movedT then MMNav_PlayMove() end
        return
    end
    if curTab == "SPELLS" then
        Nav_EnsureFocus()
        local movedSp = Nav_OnSpellsDirection(direction)
        Nav_ApplyFocus()
        if movedSp then MMNav_PlayMove() end
        return
    end
    if curTab == "QUESTS" then
        Nav_EnsureFocus()
        local movedQ = Nav_OnQuestsDirection(direction)
        Nav_ApplyFocus()
        if movedQ then MMNav_PlayMove() end
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
        if f.zone == "SPPAGE" then
            f.returnZone = "SPPAGE"
            f.zone = "SPGRID"
            Nav_EnsureFocus()
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
            -- SPGRID DOWN hoje vai p/ lugar nenhum (return false); SPPAGE entra depois:
            -- ultima fileira sem fileira abaixo -> SPPAGE (se pageNav visivel).
            local pgSpDown = Nav_VisibleSpellPageBtns()
            local npSpDown = 0
            if pgSpDown then npSpDown = table.getn(pgSpDown) end
            if npSpDown > 0 then
                f.zone = "SPPAGE"
                if not f.spellPageBtn or f.spellPageBtn < 1 then f.spellPageBtn = 1 end
                if f.spellPageBtn > npSpDown then f.spellPageBtn = npSpDown end
                return true
            end
            return false
        end
        if f.zone == "SPPAGE" then
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
        if f.zone == "SPPAGE" then
            local pgSL = Nav_VisibleSpellPageBtns()
            local npSL = 0
            if pgSL then npSL = table.getn(pgSL) end
            if npSL < 1 then
                f.zone = "SPGRID"
                Nav_EnsureFocus()
                return true
            end
            if not f.spellPageBtn or f.spellPageBtn < 1 then f.spellPageBtn = 1 end
            if f.spellPageBtn > npSL then f.spellPageBtn = npSL end
            if npSL > 1 then
                f.spellPageBtn = f.spellPageBtn - 1
                if f.spellPageBtn < 1 then f.spellPageBtn = npSL end
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
            elseif curE == "TALENTS" then
                f.returnZone = "EQUIP"
                local scrTE = Nav_GetTalentActiveScreen()
                if scrTE == 2 then f.zone = "TALENTS2" else f.zone = "TALENTS1" end
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
            elseif curRB == "TALENTS" then
                local scrTRB = Nav_GetTalentActiveScreen()
                if scrTRB == 2 then f.zone = "TALENTS2" else f.zone = "TALENTS1" end
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
        if f.zone == "SPPAGE" then
            local pgSR = Nav_VisibleSpellPageBtns()
            local npSR = 0
            if pgSR then npSR = table.getn(pgSR) end
            if npSR < 1 then
                f.zone = "SPGRID"
                Nav_EnsureFocus()
                return true
            end
            if not f.spellPageBtn or f.spellPageBtn < 1 then f.spellPageBtn = 1 end
            if f.spellPageBtn > npSR then f.spellPageBtn = npSR end
            if npSR > 1 then
                f.spellPageBtn = f.spellPageBtn + 1
                if f.spellPageBtn > npSR then f.spellPageBtn = 1 end
            end
            return true
        end
        return false
    end
    return false
end

-- FASE 4: navegacao TALENTS. page = tabContainer.pages["TALENTS"]; activeScreen 1=specs/2=arvore.
-- TALENTS1: lista vertical 3 specs. TALENTS2: arvore posicional 7 tiers x 4 cols (col1=topo),
-- sempre p/ vizinho VISIVEL mais proximo (skip escondidos, nada de indice linear).
-- TABBAR/EQUIP/BUFFS compartilhadas funcionam igual a BAGS (reaproveite codigo BAGS);
-- EQUIP/BUFFS RIGHT voltam via tab-aware (tela1->TALENTS1, tela2->TALENTS2).
-- Tudo via raiz MM=Nav_GetMM(), nunca na pagina. Retorna true se moveu/tratou.
function Nav_OnTalentsDirection(direction)
    local f = Nav.focus
    if direction == "UP" then
        if f.zone == "TABBAR" then return false end
        if f.zone == "EQUIP" then
            if f.equipIndex > 1 then f.equipIndex = f.equipIndex - 1 return true end
            f.returnZone = "EQUIP"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "TALENTS1" then
            f.returnZone = "TALENTS1"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "TALENTS2" then
            local MM = Nav_GetMM()
            local tier, col = Nav_GetTalentSlotTierCol(f.talentSlot)
            if MM and tier and col then
                local grid = MM.tabContainer and MM.tabContainer.pages and MM.tabContainer.pages["TALENTS"] and MM.tabContainer.pages["TALENTS"].treeScreen and MM.tabContainer.pages["TALENTS"].treeScreen.slotsByTierCol
                if grid then
                    local c = col + 1
                    while c <= 4 do
                        local row = grid[tier]
                        local cand = row and row[c]
                        if Nav_TalentSlotVisible(cand) then
                            f.talentSlot = cand
                            if type(MM.FocusTalentSlot) == "function" then
                                local s = cand
                                pcall(function() MM:FocusTalentSlot(s) end)
                            end
                            return true
                        end
                        c = c + 1
                    end
                end
            end
            f.returnZone = "TALENTS2"
            f.zone = "TABBAR"
            return true
        end
        if f.zone == "BUFFS" then
            local bc = Nav_BuffCount()
            if bc < 1 then
                f.zone = Nav_GetTalentDefaultZone()
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
            f.zone = f.returnZone or Nav_GetTalentDefaultZone()
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
        if f.zone == "TALENTS1" then return false end
        if f.zone == "TALENTS2" then
            local MM = Nav_GetMM()
            local tier, col = Nav_GetTalentSlotTierCol(f.talentSlot)
            if MM and tier and col then
                local grid = MM.tabContainer and MM.tabContainer.pages and MM.tabContainer.pages["TALENTS"] and MM.tabContainer.pages["TALENTS"].treeScreen and MM.tabContainer.pages["TALENTS"].treeScreen.slotsByTierCol
                if grid then
                    local c = col - 1
                    while c >= 1 do
                        local row = grid[tier]
                        local cand = row and row[c]
                        if Nav_TalentSlotVisible(cand) then
                            f.talentSlot = cand
                            if type(MM.FocusTalentSlot) == "function" then
                                local s = cand
                                pcall(function() MM:FocusTalentSlot(s) end)
                            end
                            return true
                        end
                        c = c - 1
                    end
                end
            end
            return false
        end
        if f.zone == "BUFFS" then
            local bc = Nav_BuffCount()
            if bc < 1 then
                f.zone = Nav_GetTalentDefaultZone()
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
        if f.zone == "TALENTS1" then
            if not f.talentSpec or f.talentSpec < 1 then f.talentSpec = 1 end
            if f.talentSpec > 3 then f.talentSpec = 3 end
            if f.talentSpec <= 1 then
                local bc = Nav_BuffCount()
                if bc > 0 then
                    f.returnZone = "TALENTS1"
                    f.zone = "BUFFS"
                    if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
                    if f.buffPos > bc then f.buffPos = bc end
                    Nav_EnsureFocus()
                    return true
                end
            end
            f.talentSpec = f.talentSpec - 1
            if f.talentSpec < 1 then f.talentSpec = 3 end
            local MM = Nav_GetMM()
            if MM and type(MM.FocusTalentSpecButton) == "function" then
                local idx = f.talentSpec
                pcall(function() MM:FocusTalentSpecButton(idx, true) end)
            end
            return true
        end
        if f.zone == "TALENTS2" then
            local MM = Nav_GetMM()
            local tier, col = Nav_GetTalentSlotTierCol(f.talentSlot)
            if tier and col and tier > 1 and MM then
                local grid = MM.tabContainer and MM.tabContainer.pages and MM.tabContainer.pages["TALENTS"] and MM.tabContainer.pages["TALENTS"].treeScreen and MM.tabContainer.pages["TALENTS"].treeScreen.slotsByTierCol
                if grid then
                    local t = tier - 1
                    while t >= 1 do
                        local row = grid[t]
                        local cand = row and row[col]
                        if Nav_TalentSlotVisible(cand) then
                            f.talentSlot = cand
                            if type(MM.FocusTalentSlot) == "function" then
                                local s = cand
                                pcall(function() MM:FocusTalentSlot(s) end)
                            end
                            return true
                        end
                        t = t - 1
                    end
                    return false
                end
            end
            if tier and tier <= 1 then
                local bc = Nav_BuffCount()
                if bc > 0 then
                    f.returnZone = "TALENTS2"
                    f.zone = "BUFFS"
                    if not f.buffPos or f.buffPos < 1 then f.buffPos = 1 end
                    if f.buffPos > bc then f.buffPos = bc end
                    Nav_EnsureFocus()
                    return true
                end
                f.returnZone = "TALENTS2"
                f.zone = "EQUIP"
                Nav_EnsureFocus()
                return true
            end
            return false
        end
        if f.zone == "BUFFS" then
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
            f.zone = Nav_GetTalentDefaultZone()
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "TALENTS1" then
            if not f.talentSpec or f.talentSpec < 1 then f.talentSpec = 1 end
            if f.talentSpec > 3 then f.talentSpec = 3 end
            f.talentSpec = f.talentSpec + 1
            if f.talentSpec > 3 then f.talentSpec = 1 end
            local MM = Nav_GetMM()
            if MM and type(MM.FocusTalentSpecButton) == "function" then
                local idx = f.talentSpec
                pcall(function() MM:FocusTalentSpecButton(idx, true) end)
            end
            return true
        end
        if f.zone == "TALENTS2" then
            local MM = Nav_GetMM()
            local tier, col = Nav_GetTalentSlotTierCol(f.talentSlot)
            if MM and tier and col then
                local grid = MM.tabContainer and MM.tabContainer.pages and MM.tabContainer.pages["TALENTS"] and MM.tabContainer.pages["TALENTS"].treeScreen and MM.tabContainer.pages["TALENTS"].treeScreen.slotsByTierCol
                if grid then
                    local t = tier + 1
                    while t <= 7 do
                        local row = grid[t]
                        local cand = row and row[col]
                        if Nav_TalentSlotVisible(cand) then
                            f.talentSlot = cand
                            if type(MM.FocusTalentSlot) == "function" then
                                local s = cand
                                pcall(function() MM:FocusTalentSlot(s) end)
                            end
                            return true
                        end
                        t = t + 1
                    end
                end
            end
            return false
        end
        if f.zone == "BUFFS" then
            f.returnZone = "BUFFS"
            f.zone = Nav_GetTalentDefaultZone()
            Nav_EnsureFocus()
            return true
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
        if f.zone == "SORT" then
            f.returnZone = "SORT"
            f.zone = "CATS"
            Nav_EnsureFocus()
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
            if Nav_SortVisible() then
                f.zone = "SORT"
                Nav_EnsureFocus()
                return true
            end
            f.zone = "GRID"
            Nav_EnsureFocus()
            return true
        end
        if f.zone == "SORT" then
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
            elseif curEB == "TALENTS" then
                f.returnZone = "EQUIP"
                local scrTEB = Nav_GetTalentActiveScreen()
                if scrTEB == 2 then f.zone = "TALENTS2" else f.zone = "TALENTS1" end
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
            elseif curBRB == "TALENTS" then
                local scrTBRB = Nav_GetTalentActiveScreen()
                if scrTBRB == 2 then f.zone = "TALENTS2" else f.zone = "TALENTS1" end
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
    if curTabCf == "QUESTS" then
        Nav_EnsureFocus()
        local fq = self.focus
        if fq.zone == "TABBAR" then
            local tabs = Nav_GetTabButtons()
            local MM = Nav_GetMM()
            if tabs and tabs[fq.tabIdx] then
                local btn = tabs[fq.tabIdx]
                if btn then pcall(function() btn:Click() end) end
                return true
            end
            if MM and type(MM.SelectTab) == "function" then return true end
            return true
        end
        if fq.zone == "QMISSOES" or fq.zone == "QDETALHE" then
            local idx = fq.questIdx
            if not idx or idx < 1 then
                pcall(function() Nav_EnsureQuestIdx() end)
                idx = fq.questIdx
            end
            if not idx or idx < 1 then return false end
            local MM = Nav_GetMM()
            if MM and type(MM.FocusMapOnQuest) == "function" then
                pcall(function() MM:FocusMapOnQuest(idx) end)
                if type(MM.SelectQuest) == "function" then
                    pcall(function() MM:SelectQuest(idx, true) end)
                end
                Nav_ApplyFocus()
                return true
            else
                MMNav_Log("|cffe09a15[MMNav]|r FocusMapOnQuest ausente")
                return false
            end
        end
        if fq.zone == "QNPCS" then
            local npcs = Nav_GetVisibleNpcs()
            local b = npcs and npcs[fq.npcIdx]
            if not b then return false end
            pcall(function() b:Click() end)
            Nav_ApplyFocus()
            return true
        end
        if fq.zone == "QZONAS" or fq.zone == "ZONAS" then
            local grupo = fq.zonaGrupo or "NAV"
            if fq.zone == "ZONAS" then grupo = "NAV" end
            if grupo == "NAV" then
                local nav = Nav_GetVisibleMapNav()
                local b = nav and nav[fq.zonaIdx]
                if not b then return false end
                pcall(function() b:Click() end)
                Nav_ApplyFocus()
                return true
            else
                local zones = Nav_GetVisibleZones()
                local zb = zones and zones[fq.zonaIdx]
                if not zb then return false end
                local MM = Nav_GetMM()
                if MM and type(MM.SwitchMapToZone) == "function" and zb.zoneName then
                    local zn = zb.zoneName
                    pcall(function() MM:SwitchMapToZone(zn) end)
                    if type(MM.BuildInstancesListForZone) == "function" then
                        pcall(function() MM:BuildInstancesListForZone(zn) end)
                    elseif type(MM.ShowInstancesForCurrentView) == "function" then
                        pcall(function() MM:ShowInstancesForCurrentView() end)
                    end
                    if type(MM.UpdateQuestsPage) == "function" then
                        pcall(function() MM:UpdateQuestsPage() end)
                    end
                elseif zb then
                    pcall(function() zb:Click() end)
                else
                    MMNav_Log("|cffe09a15[MMNav]|r SwitchMapToZone ausente")
                    return false
                end
                fq.qMapaOrigem = fq.zonaIdx
                fq.mapaIdx = 1
                fq.zone = "QMAPAS"
                Nav_EnsureFocus()
                Nav_ApplyFocus()
                return true
            end
        end
        if fq.zone == "QMAPAS" then
            if not fq.mapaIdx or fq.mapaIdx < 1 then fq.mapaIdx = 1 end
            local mapas = Nav_GetVisibleMapas()
            local mb = mapas and mapas[fq.mapaIdx]
            if not mb then return false end
            local MM = Nav_GetMM()
            if mb.zoneName then
                local zn = mb.zoneName
                local entered = false
                if MM and type(MM.SwitchMapToDungeon) == "function" then
                    local ok, ret = pcall(function() return MM:SwitchMapToDungeon(zn) end)
                    if ok and ret then entered = true end
                end
                if not entered and MM and type(MM.SwitchMapToZone) == "function" then
                    pcall(function() MM:SwitchMapToZone(zn) end)
                    entered = true
                end
                if not entered then
                    pcall(function() mb:Click() end)
                end
                if MM and type(MM.UpdateQuestsPage) == "function" then
                    pcall(function() MM:UpdateQuestsPage() end)
                end
            else
                pcall(function() mb:Click() end)
            end
            Nav_ApplyFocus()
            return true
        end
        return false
    end
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
        if fs.zone == "SPPAGE" then
            local pgSC = Nav_VisibleSpellPageBtns()
            local npSC = 0
            if pgSC then npSC = table.getn(pgSC) end
            local spbtn = nil
            if fs.spellPageBtn and fs.spellPageBtn >= 1 and fs.spellPageBtn <= npSC then
                spbtn = pgSC[fs.spellPageBtn]
            end
            if spbtn then pcall(function() spbtn:Click() end) end
            return true
        end
        return false
    end
    if curTabCf == "TALENTS" then
        Nav_EnsureFocus()
        local ft = self.focus
        if ft.zone == "TABBAR" then
            local tabs = Nav_GetTabButtons()
            local MM = Nav_GetMM()
            if tabs and tabs[ft.tabIdx] then
                local btn = tabs[ft.tabIdx]
                if btn then pcall(function() btn:Click() end) end
                return true
            end
            if MM and type(MM.SelectTab) == "function" then return true end
            return true
        end
        if ft.zone == "EQUIP" then
            local eq = Nav_GetEquipButtons()
            if eq and eq[ft.equipIndex] then
                pcall(function() eq[ft.equipIndex]:Click("LeftButton") end)
            end
            return true
        end
        if ft.zone == "BUFFS" then
            return true
        end
        if ft.zone == "TALENTS1" then
            local MM = Nav_GetMM()
            if MM then
                if type(MM.FocusTalentSpecButton) == "function" then
                    local idx = ft.talentSpec or 1
                    pcall(function() MM:FocusTalentSpecButton(idx) end)
                end
                if type(MM.ShowTalentTreeScreen) == "function" then
                    local idx2 = ft.talentSpec or 1
                    pcall(function() MM:ShowTalentTreeScreen(idx2) end)
                end
            end
            ft.zone = "TALENTS2"
            local MM2 = Nav_GetMM()
            if MM2 and MM2.tabContainer and MM2.tabContainer.pages then
                local pt2 = MM2.tabContainer.pages["TALENTS"]
                if pt2 and Nav_TalentSlotVisible(pt2.focusedTalentSlot) then
                    ft.talentSlot = pt2.focusedTalentSlot
                else
                    local fv = Nav_GetTalentFirstVisible()
                    if fv then ft.talentSlot = fv end
                end
            end
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            return true
        end
        if ft.zone == "TALENTS2" then
            local slot = ft.talentSlot
            if slot and slot.talentData and slot.talentData.tabIndex and slot.talentData.talentIndex then
                local MM = Nav_GetMM()
                if MM and type(MM.SpendTalentPoint) == "function" then
                    local ti, tj = slot.talentData.tabIndex, slot.talentData.talentIndex
                    pcall(function() MM:SpendTalentPoint(ti, tj) end)
                end
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
    if f.zone == "SORT" then
        local pbS = Nav_GetPageBags()
        if pbS and pbS.sortBtn then pcall(function() pbS.sortBtn:Click() end) end
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
    if curTabCx == "QUESTS" then
        Nav_EnsureFocus()
        local fq = self.focus
        -- IsActive() ja barra menu de contexto e overlay (questDetail):
        -- retorna false la, entao B nao e consumido aqui (cursor fecha).
        -- Sem duplicar checks de IsContextMenuOpen/IsQuestDetailOpen.
        if fq.zone == "QMAPAS" then
            fq.zone = "QZONAS"
            fq.zonaGrupo = "LISTA"
            if fq.qMapaOrigem and fq.qMapaOrigem >= 1 then
                fq.zonaIdx = fq.qMapaOrigem
            elseif not fq.zonaIdx or fq.zonaIdx < 1 then
                fq.zonaIdx = 1
            end
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        if fq.zone == "QDETALHE" then
            fq.zone = "QMISSOES"
            fq.qDetail = false
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        return false
    end
    if curTabCx == "SPELLS" then
        local ps = Nav_GetPageSpells()
        local scr = nil
        if ps then scr = ps.activeScreen end
        local isGridScreen = (scr == 2)
        if scr == nil then
            isGridScreen = (self.focus and self.focus.zone == "SPGRID")
        end
        if self.focus and self.focus.zone == "SPPAGE" then
            self.focus.zone = "SPGRID"
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
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
    if curTabCx == "TALENTS" then
        local MM = Nav_GetMM()
        local pt = nil
        if MM and MM.tabContainer and MM.tabContainer.pages then
            pt = MM.tabContainer.pages["TALENTS"]
        end
        local scr = pt and pt.activeScreen
        if scr == 2 or (scr == nil and self.focus and self.focus.zone == "TALENTS2") then
            if MM and type(MM.HandleTalentsBack) == "function" then
                pcall(function() MM:HandleTalentsBack() end)
            end
            self.focus.zone = "TALENTS1"
            if pt and type(pt.focusedSpecIdx) == "number" then self.focus.talentSpec = pt.focusedSpecIdx end
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        Nav_EnsureFocus()
        local ftp = self.focus
        if ftp and ftp.zone == "TALENTS1" then
            ftp.zone = "EQUIP"
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
    if f.zone == "SORT" then
        f.zone = "CATS"
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
    if curTabUs == "QUESTS" then
        Nav_EnsureFocus()
        local fq = self.focus
        if fq.zone == "QMISSOES" or fq.zone == "QDETALHE" then
            local idx = fq.questIdx
            if not idx or idx < 1 then
                pcall(function() Nav_EnsureQuestIdx() end)
                idx = fq.questIdx
            end
            if not idx or idx < 1 then return false end
            local MM = Nav_GetMM()
            if MM and type(MM.OpenQuestContextMenu) == "function" then
                pcall(function() MM:OpenQuestContextMenu(idx) end)
                return true
            else
                MMNav_Log("|cffe09a15[MMNav]|r OpenQuestContextMenu ausente")
                return false
            end
        end
        return false
    end
    if curTabUs == "TALENTS" then
        return false
    end
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
    local curTabSec = Nav_GetCurrentTab()
    if curTabSec == "QUESTS" then
        Nav_EnsureFocus()
        local fq = self.focus
        if fq.zone == "QMISSOES" or fq.zone == "QDETALHE" then
            local idx = fq.questIdx
            if not idx or idx < 1 then
                pcall(function() Nav_EnsureQuestIdx() end)
                idx = fq.questIdx
            end
            if not idx or idx < 1 then return false end
            local MM = Nav_GetMM()
            if MM and type(MM.ToggleQuestWatch) == "function" then
                pcall(function() MM:ToggleQuestWatch(idx) end)
                Nav_ApplyFocus()
                return true
            else
                MMNav_Log("|cffe09a15[MMNav]|r ToggleQuestWatch ausente")
                return false
            end
        end
        return false
    end
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
    self.focus = self.focus or { zone = "GRID", tabIdx = 1, equipIndex = 1, catIndex = nil, gridIndex = 1, buffPos = 1, pageBtn = 1, returnZone = "GRID", spellCat = nil, spellSlot = nil, spellTab = nil, talentSpec = nil, talentSlot = nil, spellPageBtn = 1, questIdx = nil, qDetail = false }
    if self.focus.questIdx ~= nil and self.focus.questIdx < 1 then self.focus.questIdx = nil end
    if self.focus.qDetail == nil then self.focus.qDetail = false end
    if self.focus.buffPos == nil or self.focus.buffPos < 1 then self.focus.buffPos = 1 end
    if self.focus.pageBtn == nil or self.focus.pageBtn < 1 then self.focus.pageBtn = 1 end
    if self.focus.spellPageBtn == nil or self.focus.spellPageBtn < 1 then self.focus.spellPageBtn = 1 end
    if self.focus.spellCat ~= nil and self.focus.spellCat < 1 then self.focus.spellCat = 1 end
    if self.focus.spellSlot == nil or self.focus.spellSlot < 1 then self.focus.spellSlot = 1 end
    if self.focus.spellTab == nil or self.focus.spellTab < 1 then self.focus.spellTab = 1 end
    if self.focus.talentSpec ~= nil and self.focus.talentSpec < 1 then self.focus.talentSpec = 1 end
    if self.focus.talentSpec ~= nil and self.focus.talentSpec > 3 then self.focus.talentSpec = 3 end
end
