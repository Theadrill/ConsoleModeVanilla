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
Nav.focus = Nav.focus or { zone = "GRID", tabIdx = 1, equipIndex = 1, catIndex = nil, gridIndex = 1, buffPos = 1, pageBtn = 1, returnZone = "GRID", spellCat = nil, spellSlot = nil, spellTab = nil, talentSpec = nil, talentSlot = nil, spellPageBtn = 1, questIdx = nil, qDetail = false, npcIdx = 1, zonaIdx = 1, qMapaOrigem = nil, mapaIdx = 1, bindsPage = 1, bindsIdx = 1, pickerMode = 1, pickerSubIdx = 1, pickerGridIdx = 1, pickerPage = 1, pickerSection = "MODE", pickerPageBtn = 1 }

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

local function IsLangPickerOpen()
    local cm = getglobal("ConsoleMode")
    if cm and cm.mainMenu and type(cm.mainMenu.IsLangPickerOpen) == "function" then
        local ok, vis = pcall(function() return cm.mainMenu:IsLangPickerOpen() end)
        if ok and vis then return true end
    end
    local pf = getglobal("ConsoleModeMM_LangPicker")
    if SafeIsVisible(pf) then return true end
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
        -- MMNav_Log("|cffe09a15[MMNav]|r SelectQuest ausente") -- NOLOG 2026-09-14
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
    if type(MM.FocusMapOnQuest) == "function" then
        pcall(function() MM:FocusMapOnQuest(targetIdx) end)
    end
    if qp and type(MM.UpdateQuestsPage) == "function" then
        pcall(function() MM:UpdateQuestsPage() end)
    end
    return true
end

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
    local inQuestZone = (f.zone == "QMISSOES" or f.zone == "QDETALHE" or f.zone == "QLEITURA")
    for i = 1, n do
        local b = btns[i]
        if b and not b.isHeader then
            local qli = b.questLogIndex
            if inQuestZone and qli and qli == f.questIdx then
                if b.highlight then
                    pcall(function() b.highlight:Show() end)
                    pcall(function() b.highlight:SetVertexColor(1.0, 0.85, 0.15, 0.55) end)
                end
                if b.underline then
                    pcall(function()
                        b.underline:Show()
                        b.underline:SetVertexColor(0.08, 0.06, 0.04, 0.95)
                    end)
                end
                if b.borderTex and type(b.borderTex.SetVertexColor) == "function" then
                    pcall(function() b.borderTex:SetVertexColor(1.0, 0.85, 0.20, 1.0) end)
                end
                if b.border and type(b.border.SetVertexColor) == "function" then
                    pcall(function() b.border:SetVertexColor(1.0, 0.85, 0.20, 1.0) end)
                end
                if type(b.SetBackdropBorderColor) == "function" then
                    pcall(function() b:SetBackdropBorderColor(1.0, 0.85, 0.20, 1.0) end)
                end
                if b.titleText and type(b.titleText.SetTextColor) == "function" then
                    pcall(function() b.titleText:SetTextColor(1.0, 0.95, 0.40) end)
                end
                if b.title and type(b.title.SetTextColor) == "function" then
                    pcall(function() b.title:SetTextColor(1.0, 0.95, 0.40) end)
                end
                if b.nameFS and type(b.nameFS.SetTextColor) == "function" then
                    pcall(function() b.nameFS:SetTextColor(1.0, 0.95, 0.40) end)
                end
                if b.label and type(b.label.SetTextColor) == "function" then
                    pcall(function() b.label:SetTextColor(1.0, 0.95, 0.40) end)
                end
            elseif qli and activeIdx and qli == activeIdx then
                if b.highlight then
                    pcall(function() b.highlight:Show() end)
                    pcall(function() b.highlight:SetVertexColor(0.85, 0.55, 0.08, 0.28) end)
                end
                if b.underline then
                    pcall(function()
                        b.underline:Show()
                        b.underline:SetVertexColor(0.08, 0.06, 0.04, 0.95)
                    end)
                end
                if b.borderTex and type(b.borderTex.SetVertexColor) == "function" then
                    pcall(function() b.borderTex:SetVertexColor(0.45, 0.38, 0.22, 0.5) end)
                end
                if b.border and type(b.border.SetVertexColor) == "function" then
                    pcall(function() b.border:SetVertexColor(0.45, 0.38, 0.22, 0.5) end)
                end
                if type(b.SetBackdropBorderColor) == "function" then
                    pcall(function() b:SetBackdropBorderColor(0.5, 0.4, 0.28, 0.65) end)
                end
                if b.titleText and type(b.titleText.SetTextColor) == "function" then
                    pcall(function() b.titleText:SetTextColor(0.96, 0.88, 0.68) end)
                end
                if b.title and type(b.title.SetTextColor) == "function" then
                    pcall(function() b.title:SetTextColor(0.96, 0.88, 0.68) end)
                end
                if b.nameFS and type(b.nameFS.SetTextColor) == "function" then
                    pcall(function() b.nameFS:SetTextColor(0.96, 0.88, 0.68) end)
                end
                if b.label and type(b.label.SetTextColor) == "function" then
                    pcall(function() b.label:SetTextColor(0.96, 0.88, 0.68) end)
                end
            else
                if b.highlight then
                    pcall(function() b.highlight:Hide() end)
                end
                if b.underline then
                    pcall(function()
                        b.underline:Show()
                        b.underline:SetVertexColor(0.45, 0.38, 0.22, 0.45)
                    end)
                end
                if b.borderTex and type(b.borderTex.SetVertexColor) == "function" then
                    pcall(function() b.borderTex:SetVertexColor(0.45, 0.38, 0.22, 0.5) end)
                end
                if b.border and type(b.border.SetVertexColor) == "function" then
                    pcall(function() b.border:SetVertexColor(0.45, 0.38, 0.22, 0.5) end)
                end
                if type(b.SetBackdropBorderColor) == "function" then
                    pcall(function() b:SetBackdropBorderColor(0.5, 0.4, 0.28, 0.65) end)
                end
                if b.titleText and type(b.titleText.SetTextColor) == "function" then
                    pcall(function() b.titleText:SetTextColor(0.96, 0.88, 0.68) end)
                end
                if b.title and type(b.title.SetTextColor) == "function" then
                    pcall(function() b.title:SetTextColor(0.96, 0.88, 0.68) end)
                end
                if b.nameFS and type(b.nameFS.SetTextColor) == "function" then
                    pcall(function() b.nameFS:SetTextColor(0.96, 0.88, 0.68) end)
                end
                if b.label and type(b.label.SetTextColor) == "function" then
                    pcall(function() b.label:SetTextColor(0.96, 0.88, 0.68) end)
                end
            end
        elseif b and b.isHeader then
            if b.highlight then
                pcall(function() b.highlight:Hide() end)
            end
            if b.underline then
                pcall(function() b.underline:Hide() end)
            end
        end
    end
end

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

local function Nav_EnsureNpcZonaFocus()
    local f = Nav.focus
    if not f.npcIdx or f.npcIdx < 1 then f.npcIdx = 1 end
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
        local zones = Nav_GetVisibleZones()
        local nz = table.getn(zones)
        if nz < 1 then
            f.zonaIdx = 1
        else
            if f.zonaIdx > nz then f.zonaIdx = nz end
            local zb = zones[f.zonaIdx]
            if not zb or not SafeIsVisible(zb) then f.zonaIdx = 1 end
        end
    elseif f.zone == "QMAPAS" then
        if not f.mapaIdx or f.mapaIdx < 1 then f.mapaIdx = 1 end
        local mapas = Nav_GetVisibleMapas()
        local nm = table.getn(mapas)
        if nm < 1 then
            f.zone = "QZONAS"
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
        if btn.nameFS and type(btn.nameFS.SetTextColor) == "function" then
            pcall(function() btn.nameFS:SetTextColor(1.0, 0.82, 0.20) end)
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
        if btn.borderTex and type(btn.borderTex.SetVertexColor) == "function" then
            pcall(function() btn.borderTex:SetVertexColor(1.0, 0.82, 0.20, 0.95) end)
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
        if btn.borderTex and type(btn.borderTex.SetVertexColor) == "function" then
            pcall(function() btn.borderTex:SetVertexColor(0.45, 0.38, 0.22, 0.5) end)
        end
        if btn.label and type(btn.label.SetTextColor) == "function" then
            pcall(function() btn.label:SetTextColor(0.96, 0.88, 0.68, 1.0) end)
        end
        if btn.nameFS and type(btn.nameFS.SetTextColor) == "function" then
            pcall(function() btn.nameFS:SetTextColor(0.96, 0.88, 0.68, 1.0) end)
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

local function Nav_PaintQnav()
    local f = Nav.focus
    local rawNav = Nav_GetRawNavButtons()
    if not rawNav then return end
    local okN, n = pcall(function() return table.getn(rawNav) end)
    if not okN or type(n) ~= "number" or n < 1 then return end
    local inZone = (f.zone == "QNAV")
    for i = 1, n do
        local b = rawNav[i]
        if b then
            if inZone and i == (f.navIdx or 1) then
                Nav_PaintOneButton(b, true)
            else
                Nav_PaintOneButton(b, false)
            end
        end
    end
end

local function Nav_PaintMapas()
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

local function Nav_PaintZonas()
    local f = Nav.focus
    local raw = Nav_GetRawZoneButtons()
    if not raw then return end
    local okN, n = pcall(function() return table.getn(raw) end)
    if not okN or type(n) ~= "number" or n < 1 then return end
    local vis = Nav_GetVisibleZones()
    local inZone = (f.zone == "QZONAS")
    local posByBtn = {}
    local vc = table.getn(vis)
    for vi = 1, vc do
        local vb = vis[vi]
        if vb then posByBtn[vb] = vi end
    end
    local focusedBtn = nil
    for i = 1, n do
        local b = raw[i]
        if b then
            local vpos = posByBtn[b]
            if vpos and inZone and vpos == f.zonaIdx then
                Nav_PaintOneButton(b, true)
                focusedBtn = b
            else
                Nav_PaintOneButton(b, false)
            end
        end
    end
    if inZone and focusedBtn then
        local MM = Nav_GetMM()
        if MM then
            if focusedBtn.zoneName and not focusedBtn.isInstance and type(MM.ShowZonePinForZone) == "function" then
                MM:ShowZonePinForZone(focusedBtn.zoneName, focusedBtn.zoneCont)
            elseif type(MM.HideZonePin) == "function" then
                MM:HideZonePin()
            end
        end
    end
    if inZone and f.zonaIdx then
        local zf = Nav_GetZoneListFrame()
        local sf = (zf and zf.scrollFrame) or getglobal("ConsoleModeMM_ZoneListScroll")
        if sf and sf.GetVerticalScroll then
            local btnH = 28
            local gap = 3
            local cur = sf:GetVerticalScroll() or 0
            local vpH = sf:GetHeight() or 200
            if vpH <= 0 then vpH = 200 end
            local visRows = math.floor(vpH / (btnH + gap))
            if visRows < 1 then visRows = 6 end
            local firstVis = math.floor(cur / (btnH + gap)) + 1
            local lastVis = firstVis + visRows - 1
            if f.zonaIdx < firstVis then
                sf:SetVerticalScroll((f.zonaIdx - 1) * (btnH + gap))
            elseif f.zonaIdx > lastVis then
                sf:SetVerticalScroll((f.zonaIdx - visRows) * (btnH + gap))
            end
        end
    end
end

local function Nav_GetBindsState()
    local okMM, MMM = pcall(function() return Nav_GetMM() end)
    if not okMM or not MMM or not MMM.tabContainer or not MMM.tabContainer.pages then return nil end
    local pageSystem = MMM.tabContainer.pages["SYSTEM"]
    if not pageSystem then return nil end
    return pageSystem
end

local function Nav_IsBindsScreenVisible()
    local ps = Nav_GetBindsState()
    if not ps then return false end
    if ps.activeSubScreen ~= "BINDS" then return false end
    if ps.bindsScreen and type(ps.bindsScreen.IsVisible) == "function" then
        local ok, v = pcall(function() return ps.bindsScreen:IsVisible() end)
        if ok then return v end
    end
    return ps.activeSubScreen == "BINDS"
end

local function Nav_IsPickerScreenVisible()
    local ps = Nav_GetBindsState()
    if not ps then return false end
    if ps.activeSubScreen ~= "PICKER" then return false end
    if ps.pickerScreen and type(ps.pickerScreen.IsVisible) == "function" then
        local ok, v = pcall(function() return ps.pickerScreen:IsVisible() end)
        if ok then return v end
    end
    return ps.activeSubScreen == "PICKER"
end

local function Nav_GetSysSubTabs()
    local okMM, MMM = pcall(function() return Nav_GetMM() end)
    if not okMM or not MMM or not MMM.tabContainer or not MMM.tabContainer.pages then return nil end
    local pageSystem = MMM.tabContainer.pages["SYSTEM"]
    if not pageSystem then return nil end
    return pageSystem.subTabButtons or pageSystem.subButtons
end

local function Nav_GetVisibleGameMenuButtons()
    local out = {}
    local okMM, MMM = pcall(function() return Nav_GetMM() end)
    if not okMM or not MMM or not MMM.tabContainer or not MMM.tabContainer.pages then return out end
    local pageSystem = MMM.tabContainer.pages["SYSTEM"]
    if not pageSystem or not pageSystem.subPageGameMenu or not pageSystem.subPageGameMenu.rows then return out end
    local rows = pageSystem.subPageGameMenu.rows
    local n = table.getn(rows)
    for i = 1, n do
        local b = rows[i]
        if b and SafeIsVisible(b) then
            table.insert(out, b)
        end
    end
    return out
end

local function Nav_GetVisibleAddonCfgButtons()
    local out = {}
    local okMM, MMM = pcall(function() return Nav_GetMM() end)
    if not okMM or not MMM or not MMM.tabContainer or not MMM.tabContainer.pages then return out end
    local pageSystem = MMM.tabContainer.pages["SYSTEM"]
    if not pageSystem or not pageSystem.subPageAddonCfg or not pageSystem.subPageAddonCfg.rows then return out end
    local rows = pageSystem.subPageAddonCfg.rows
    local n = table.getn(rows)
    for i = 1, n do
        local b = rows[i]
        if b and SafeIsVisible(b) then
            table.insert(out, b)
        end
    end
    return out
end

local function Nav_PaintSysSubTabs()
    local f = Nav.focus
    local subTabs = Nav_GetSysSubTabs()
    if not subTabs then return end
    local n = table.getn(subTabs)
    local inZone = (f.zone == "SYS_SUBTABS")
    local curSubTab = nil
    local okMM, MMM = pcall(function() return Nav_GetMM() end)
    if okMM and MMM and MMM.tabContainer and MMM.tabContainer.pages then
        local pageSystem = MMM.tabContainer.pages["SYSTEM"]
        if pageSystem then curSubTab = pageSystem.currentSubTab end
    end

    for i = 1, n do
        local btn = subTabs[i]
        if btn then
            local isFocus = (inZone and i == (f.sysSubTabIdx or 1))
            local isActive = (btn.subTabData and btn.subTabData.id == curSubTab) or (i == (f.sysSubTabIdx or 1))
            if isFocus then
                if btn.highlight then pcall(function() btn.highlight:Show() end) end
                if btn.title then
                    pcall(function() btn.title:SetTextColor(1.0, 0.85, 0.2) end)
                end
            elseif isActive then
                if btn.highlight then pcall(function() btn.highlight:Hide() end) end
                if btn.title then
                    pcall(function() btn.title:SetTextColor(0.88, 0.60, 0.08) end)
                end
            else
                if btn.highlight then pcall(function() btn.highlight:Hide() end) end
                if btn.title then
                    pcall(function() btn.title:SetTextColor(0.6, 0.6, 0.6) end)
                end
            end
        end
    end
end

local function Nav_PaintAddonCfg()
    local f = Nav.focus
    local abtns = Nav_GetVisibleAddonCfgButtons()
    local n = table.getn(abtns)
    local inZone = (f.zone == "SYS_ADDONCFG")
    local curA = f.addonCfgIdx or 1

    for i = 1, n do
        local row = abtns[i]
        if row then
            local isFocus = (inZone and i == curA)
            if isFocus then
                if row.highlightBar then pcall(function() row.highlightBar:Show() end) end
                if row.bg then pcall(function() row.bg:SetVertexColor(1.0, 0.85, 0.2, 0.18) end) end
                if row.title then pcall(function() row.title:SetTextColor(1.0, 0.85, 0.2) end) end
            else
                if row.highlightBar then pcall(function() row.highlightBar:Hide() end) end
                if row.bg then pcall(function() row.bg:SetVertexColor(0.0, 0.0, 0.0, 0.30) end) end
                if row.title then pcall(function() row.title:SetTextColor(1.0, 1.0, 1.0) end) end
            end
        end
    end

    if inZone and f.addonCfgIdx then
        local okMM, MMM = pcall(function() return Nav_GetMM() end)
        local pageSystem = okMM and MMM and MMM.tabContainer and MMM.tabContainer.pages and MMM.tabContainer.pages["SYSTEM"]
        local subPage = pageSystem and pageSystem.subPageAddonCfg
        local sf = (subPage and subPage.scrollFrame) or getglobal("ConsoleModeMM_AddonCfgScrollFrame")
        if sf and sf.GetVerticalScroll then
            local btnH = 38
            local gap = 6
            local cur = sf:GetVerticalScroll() or 0
            local vpH = sf:GetHeight() or 300
            if vpH <= 0 then vpH = 300 end
            local visRows = math.floor(vpH / (btnH + gap))
            if visRows < 1 then visRows = 6 end
            local firstVis = math.floor(cur / (btnH + gap)) + 1
            local lastVis = firstVis + visRows - 1
            if f.addonCfgIdx < firstVis then
                sf:SetVerticalScroll((f.addonCfgIdx - 1) * (btnH + gap))
            elseif f.addonCfgIdx > lastVis then
                sf:SetVerticalScroll((f.addonCfgIdx - visRows) * (btnH + gap))
            end
        end
    end
end

local function Nav_PaintGameMenu()
    local f = Nav.focus
    local gbtns = Nav_GetVisibleGameMenuButtons()
    local n = table.getn(gbtns)
    local inZone = (f.zone == "SYS_GAMEMENU")

    for i = 1, n do
        local row = gbtns[i]
        if row then
            local isFocus = (inZone and i == f.gameMenuIdx)
            if isFocus then
                if row.highlightBar then pcall(function() row.highlightBar:Show() end) end
                if row.highlight and row.highlight ~= row.highlightBar then pcall(function() row.highlight:Show() end) end
                if row.bg then pcall(function() row.bg:SetVertexColor(1.0, 0.85, 0.2, 0.18) end) end
                if row.title then pcall(function() row.title:SetTextColor(1.0, 0.85, 0.2) end) end
                if row.label and row.label ~= row.title then pcall(function() row.label:SetTextColor(1.0, 0.85, 0.2) end) end
                if row.nameFS and row.nameFS ~= row.title then pcall(function() row.nameFS:SetTextColor(1.0, 0.85, 0.2) end) end
            else
                if row.highlightBar then pcall(function() row.highlightBar:Hide() end) end
                if row.highlight and row.highlight ~= row.highlightBar then pcall(function() row.highlight:Hide() end) end
                if row.bg then pcall(function() row.bg:SetVertexColor(0.0, 0.0, 0.0, 0.30) end) end
                if row.title then pcall(function() row.title:SetTextColor(1.0, 1.0, 1.0) end) end
                if row.label and row.label ~= row.title then pcall(function() row.label:SetTextColor(1.0, 1.0, 1.0) end) end
                if row.nameFS and row.nameFS ~= row.title then pcall(function() row.nameFS:SetTextColor(1.0, 1.0, 1.0) end) end
            end
        end
    end

    if inZone and f.gameMenuIdx then
        local okMM, MMM = pcall(function() return Nav_GetMM() end)
        local pageSystem = okMM and MMM and MMM.tabContainer and MMM.tabContainer.pages and MMM.tabContainer.pages["SYSTEM"]
        local subPage = pageSystem and pageSystem.subPageGameMenu
        local sf = (subPage and subPage.scrollFrame) or getglobal("ConsoleModeMM_GameMenuScrollFrame")
        if sf and sf.GetVerticalScroll then
            local btnH = 38
            local gap = 6
            local cur = sf:GetVerticalScroll() or 0
            local vpH = sf:GetHeight() or 300
            if vpH <= 0 then vpH = 300 end
            local visRows = math.floor(vpH / (btnH + gap))
            if visRows < 1 then visRows = 6 end
            local firstVis = math.floor(cur / (btnH + gap)) + 1
            local lastVis = firstVis + visRows - 1
            if f.gameMenuIdx < firstVis then
                sf:SetVerticalScroll((f.gameMenuIdx - 1) * (btnH + gap))
            elseif f.gameMenuIdx > lastVis then
                sf:SetVerticalScroll((f.gameMenuIdx - visRows) * (btnH + gap))
            end
        end
    end
end

-- F2.1 PINTURA BINDS (pool fixo; sem criar frames; so Show/Hide/SetTextColor/SetBackdropColor/SetBackdropBorderColor).
-- Espelho MainMenu.lua FocusBindsSlot (~12239) e UpdateBindsPage (~12290).
local function Nav_PaintBinds()
    local f = Nav.focus
    if not f then return end
    local ps = Nav_GetBindsState()
    if not ps then return end
    local bindsScreen = ps.bindsScreen
    if not bindsScreen then return end
    local inBinds = (f.zone == "SYS_BINDS")
    local curPage = f.bindsPage or 1
    if bindsScreen.currentPage and type(bindsScreen.currentPage) == "number" then
        curPage = bindsScreen.currentPage
    end
    local focusPage = f.bindsPage or curPage
    local pbs = bindsScreen.pageButtons
    if pbs then
        for p = 1, 5 do
            local btn = pbs[p]
            if btn then
                local isFocus = (inBinds and p == focusPage)
                local isActive = (p == curPage)
                if isFocus then
                    if btn.title then pcall(function() btn.title:SetTextColor(1.0, 0.85, 0.2) end) end
                    pcall(function() btn:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                    pcall(function() btn:SetBackdropColor(0.25, 0.18, 0.05, 0.70) end)
                elseif isActive then
                    if btn.title then pcall(function() btn.title:SetTextColor(0.88, 0.60, 0.08) end) end
                    pcall(function() btn:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                    pcall(function() btn:SetBackdropColor(0.25, 0.18, 0.05, 0.70) end)
                else
                    if btn.title then pcall(function() btn.title:SetTextColor(0.65, 0.65, 0.65) end) end
                    pcall(function() btn:SetBackdropBorderColor(0.4, 0.35, 0.25, 0.40) end)
                    pcall(function() btn:SetBackdropColor(0, 0, 0, 0.35) end)
                end
            end
        end
    end
    local cards = bindsScreen.bindCards
    if cards then
        local focusIdx = f.bindsIdx or 1
        for i = 1, 8 do
            local card = cards[i]
            if card then
                local isFocus = (inBinds and i == focusIdx)
                if isFocus then
                    if card.focusBorder then pcall(function() card.focusBorder:Show() end) end
                    pcall(function() card:SetBackdropColor(0.20, 0.16, 0.06, 0.65) end)
                    pcall(function() card:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                else
                    if card.focusBorder then pcall(function() card.focusBorder:Hide() end) end
                    pcall(function() card:SetBackdropColor(0, 0, 0, 0.40) end)
                    pcall(function() card:SetBackdropBorderColor(0.4, 0.35, 0.25, 0.5) end)
                end
            end
        end
        if inBinds then
            local target = cards[focusIdx]
            if target then
                local okMM, MMM = pcall(function() return Nav_GetMM() end)
                if okMM and MMM and type(MMM.FocusBindsSlot) == "function" then
                    pcall(function() MMM:FocusBindsSlot(target) end)
                end
            end
        end
    end
end

-- F2.2 PINTURA PICKER (pool fixo; sem criar frames; sem zerar currentMode/currentSubTab/gridPage).
-- Espelho MainMenu.lua SetPickerMode (~12510), HighlightPickerSubTab e FocusPickerSlot (~12895).
local function Nav_PaintPicker()
    local f = Nav.focus
    if not f then return end
    local ps = Nav_GetBindsState()
    if not ps then return end
    local pickerScreen = ps.pickerScreen
    if not pickerScreen then return end
    local inPicker = (f.zone == "SYS_PICKER")
    local sec = f.pickerSection
    if sec ~= "MODE" and sec ~= "SUB" and sec ~= "GRID" and sec ~= "PAGE" then sec = "MODE" end
    local currentMode = pickerScreen.currentMode
    local mbs = pickerScreen.modeButtons
    if mbs then
        local okN, nm = pcall(function() return table.getn(mbs) end)
        if okN and type(nm) == "number" and nm > 0 then
            local modeIdx = f.pickerMode or 1
            for i = 1, nm do
                local btn = mbs[i]
                if btn then
                    local isActive = (btn.modeId ~= nil and btn.modeId == currentMode)
                    local isFocusMode = (inPicker and sec == "MODE" and i == modeIdx)
                    if isFocusMode then
                        if btn.title then pcall(function() btn.title:SetTextColor(1.0, 0.85, 0.2) end) end
                        pcall(function() btn:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                        pcall(function() btn:SetBackdropColor(0.25, 0.18, 0.05, 0.70) end)
                    elseif isActive then
                        if btn.title then pcall(function() btn.title:SetTextColor(0.88, 0.60, 0.08) end) end
                        pcall(function() btn:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                        pcall(function() btn:SetBackdropColor(0.25, 0.18, 0.05, 0.70) end)
                    else
                        if btn.title then pcall(function() btn.title:SetTextColor(0.65, 0.65, 0.65) end) end
                        pcall(function() btn:SetBackdropBorderColor(0.4, 0.35, 0.25, 0.40) end)
                        pcall(function() btn:SetBackdropColor(0, 0, 0, 0.45) end)
                    end
                end
            end
        end
    end
    local stbs = pickerScreen.subTabButtons
    if stbs then
        local okS, ns = pcall(function() return table.getn(stbs) end)
        if okS and type(ns) == "number" and ns > 0 then
            local subIdx = f.pickerSubIdx or 1
            for i = 1, ns do
                local btn = stbs[i]
                if btn then
                    local isFocus = (inPicker and sec == "SUB" and i == subIdx)
                    if isFocus then
                        if btn.title then pcall(function() btn.title:SetTextColor(1.0, 0.85, 0.2) end) end
                        pcall(function() btn:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                        pcall(function() btn:SetBackdropColor(0.25, 0.18, 0.05, 0.70) end)
                    else
                        if btn.title then pcall(function() btn.title:SetTextColor(0.65, 0.65, 0.65) end) end
                        pcall(function() btn:SetBackdropBorderColor(0.4, 0.35, 0.25, 0.40) end)
                        pcall(function() btn:SetBackdropColor(0, 0, 0, 0.40) end)
                    end
                end
            end
        end
    end
    local gbs = pickerScreen.gridButtons
    if gbs then
        local gridIdx = f.pickerGridIdx or 1
        for i = 1, 16 do
            local btn = gbs[i]
            if btn then
                local isFocus = (inPicker and sec == "GRID" and i == gridIdx)
                if isFocus then
                    if btn.focusBorder then pcall(function() btn.focusBorder:Show() end) end
                    pcall(function() btn:SetBackdropColor(0.20, 0.16, 0.06, 0.65) end)
                    pcall(function() btn:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                else
                    if btn.focusBorder then pcall(function() btn.focusBorder:Hide() end) end
                    pcall(function() btn:SetBackdropColor(0, 0, 0, 0.40) end)
                    pcall(function() btn:SetBackdropBorderColor(0.4, 0.35, 0.25, 0.5) end)
                end
            end
        end
        if inPicker and sec == "GRID" then
            local target = gbs[gridIdx]
            if target and target.itemData then
                local okMM2, MMM2 = pcall(function() return Nav_GetMM() end)
                if okMM2 and MMM2 and type(MMM2.FocusPickerSlot) == "function" then
                    pcall(function() MMM2:FocusPickerSlot(target) end)
                end
            end
        end
    end
    local pb = pickerScreen.pageBar
    if pb then
        local prev = pb.prevBtn
        local nxt = pb.nextBtn
        local pageBtn = f.pickerPageBtn or 1
        if pageBtn < 1 then pageBtn = 1 end
        if pageBtn > 2 then pageBtn = 2 end
        if prev then
            local isF = (inPicker and sec == "PAGE" and pageBtn == 1)
            local lbl = prev.text or prev.title
            if isF then
                if lbl then pcall(function() lbl:SetTextColor(1.0, 0.85, 0.2) end) end
                pcall(function() prev:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                pcall(function() prev:SetBackdropColor(0.25, 0.18, 0.05, 0.70) end)
            else
                if lbl then pcall(function() lbl:SetTextColor(0.65, 0.65, 0.65) end) end
                pcall(function() prev:SetBackdropBorderColor(0.4, 0.35, 0.25, 0.5) end)
                pcall(function() prev:SetBackdropColor(0, 0, 0, 0.45) end)
            end
        end
        if nxt then
            local isF2 = (inPicker and sec == "PAGE" and pageBtn == 2)
            local lbl2 = nxt.text or nxt.title
            if isF2 then
                if lbl2 then pcall(function() lbl2:SetTextColor(1.0, 0.85, 0.2) end) end
                pcall(function() nxt:SetBackdropBorderColor(1.0, 0.85, 0.2, 0.95) end)
                pcall(function() nxt:SetBackdropColor(0.25, 0.18, 0.05, 0.70) end)
            else
                if lbl2 then pcall(function() lbl2:SetTextColor(0.65, 0.65, 0.65) end) end
                pcall(function() nxt:SetBackdropBorderColor(0.4, 0.35, 0.25, 0.5) end)
                pcall(function() nxt:SetBackdropColor(0, 0, 0, 0.45) end)
            end
        end
    end
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

    if not f.sysSubTabIdx or f.sysSubTabIdx < 1 then f.sysSubTabIdx = 1 end
    if f.sysSubTabIdx > 2 then f.sysSubTabIdx = 2 end

    if not f.gameMenuIdx or f.gameMenuIdx < 1 then f.gameMenuIdx = 1 end
    if f.zone == "SYS_GAMEMENU" then
        local gbtns = Nav_GetVisibleGameMenuButtons()
        local ngm = 0
        if gbtns then ngm = table.getn(gbtns) end
        if ngm < 1 then
            f.zone = "SYS_SUBTABS"
        elseif f.gameMenuIdx > ngm then
            f.gameMenuIdx = ngm
        end
    end

    if not f.addonCfgIdx or f.addonCfgIdx < 1 then f.addonCfgIdx = 1 end
    if f.zone == "SYS_ADDONCFG" then
        local abtns = Nav_GetVisibleAddonCfgButtons()
        local na = 0
        if abtns then na = table.getn(abtns) end
        if na < 1 then
            f.zone = "SYS_SUBTABS"
        elseif f.addonCfgIdx > na then
            f.addonCfgIdx = na
        end
    end

    -- F1 BINDS/PICKER: indices (pool fixo 8 cards + picker 4x4).
    if not f.bindsPage or f.bindsPage < 1 then f.bindsPage = 1 end
    if f.bindsPage > 5 then f.bindsPage = 5 end
    if not f.bindsIdx or f.bindsIdx < 1 then f.bindsIdx = 1 end
    if f.bindsIdx > 8 then f.bindsIdx = 8 end
    if not f.pickerMode or f.pickerMode < 1 then f.pickerMode = 1 end
    if f.pickerMode > 4 then f.pickerMode = 4 end
    if not f.pickerSubIdx or f.pickerSubIdx < 1 then f.pickerSubIdx = 1 end
    if not f.pickerGridIdx or f.pickerGridIdx < 1 then f.pickerGridIdx = 1 end
    if f.pickerGridIdx > 16 then f.pickerGridIdx = 16 end
    if not f.pickerPage or f.pickerPage < 1 then f.pickerPage = 1 end
    if f.pickerSection ~= "MODE" and f.pickerSection ~= "SUB" and f.pickerSection ~= "GRID" and f.pickerSection ~= "PAGE" then f.pickerSection = "MODE" end
    if not f.pickerPageBtn or f.pickerPageBtn < 1 then f.pickerPageBtn = 1 end
    if f.pickerPageBtn > 2 then f.pickerPageBtn = 2 end

    if f.zone ~= "TABBAR" and f.zone ~= "EQUIP" and f.zone ~= "CATS" and f.zone ~= "GRID" and f.zone ~= "BUFFS" and f.zone ~= "PAGENAV" and f.zone ~= "SORT" and f.zone ~= "SPCAT" and f.zone ~= "SPGRID" and f.zone ~= "SPTABS" and f.zone ~= "SPPAGE" and f.zone ~= "TALENTS1" and f.zone ~= "TALENTS2" and f.zone ~= "QMISSOES" and f.zone ~= "QDETALHE" and f.zone ~= "ZONAS" and f.zone ~= "QNPCS" and f.zone ~= "QZONAS" and f.zone ~= "QMAPAS" and f.zone ~= "QLEITURA" and f.zone ~= "QNAV" and f.zone ~= "SYS_SUBTABS" and f.zone ~= "SYS_GAMEMENU" and f.zone ~= "SYS_ADDONCFG" and f.zone ~= "SYS_BINDS" and f.zone ~= "SYS_PICKER" and f.zone ~= "HEADER_LANG" then
        f.zone = "GRID"
    end
    if f.returnZone ~= "EQUIP" and f.returnZone ~= "CATS" and f.returnZone ~= "GRID" and f.returnZone ~= "BUFFS" and f.returnZone ~= "PAGENAV" and f.returnZone ~= "SORT" and f.returnZone ~= "SPCAT" and f.returnZone ~= "SPGRID" and f.returnZone ~= "SPTABS" and f.returnZone ~= "SPPAGE" and f.returnZone ~= "TALENTS1" and f.returnZone ~= "TALENTS2" and f.returnZone ~= "QMISSOES" and f.returnZone ~= "QDETALHE" and f.returnZone ~= "ZONAS" and f.returnZone ~= "QNPCS" and f.returnZone ~= "QZONAS" and f.returnZone ~= "QMAPAS" and f.returnZone ~= "QLEITURA" and f.returnZone ~= "QNAV" and f.returnZone ~= "SYS_SUBTABS" and f.returnZone ~= "SYS_GAMEMENU" and f.returnZone ~= "SYS_ADDONCFG" and f.returnZone ~= "SYS_BINDS" and f.returnZone ~= "SYS_PICKER" and f.returnZone ~= "HEADER_LANG" then
        f.returnZone = "GRID"
    end
    -- Conversao por aba: evita zona presa na aba errada (BAGS/SPELLS/TALENTS/QUESTS/SYSTEM).
    local curTabEf = Nav_GetCurrentTab()
    if curTabEf == "SPELLS" then
        local scr = Nav_GetSpellActiveScreen()
        local defSp = "SPCAT"
        if scr == 2 then defSp = "SPGRID" end
        if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "EQUIP" or f.zone == "TALENTS1" or f.zone == "TALENTS2" or f.zone == "QMISSOES" or f.zone == "QDETALHE" or f.zone == "ZONAS" or f.zone == "QNPCS" or f.zone == "QZONAS" or f.zone == "QMAPAS" or f.zone == "QLEITURA" or f.zone == "QNAV" or f.zone == "SYS_SUBTABS" or f.zone == "SYS_GAMEMENU" or f.zone == "SYS_ADDONCFG" then
            f.zone = defSp
        end
        if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "EQUIP" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" or f.returnZone == "QMISSOES" or f.returnZone == "QDETALHE" or f.returnZone == "ZONAS" or f.returnZone == "QNPCS" or f.returnZone == "QZONAS" or f.returnZone == "QMAPAS" or f.returnZone == "QLEITURA" or f.returnZone == "QNAV" or f.returnZone == "SYS_SUBTABS" or f.returnZone == "SYS_GAMEMENU" or f.returnZone == "SYS_ADDONCFG" then
            f.returnZone = defSp
        end
        if f.zone == "BUFFS" and bc < 1 then
            f.zone = defSp
        end
    elseif curTabEf == "BAGS" then
        if f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "TALENTS1" or f.zone == "TALENTS2" or f.zone == "QMISSOES" or f.zone == "QDETALHE" or f.zone == "ZONAS" or f.zone == "QNPCS" or f.zone == "QZONAS" or f.zone == "QMAPAS" or f.zone == "QLEITURA" or f.zone == "QNAV" or f.zone == "SYS_SUBTABS" or f.zone == "SYS_GAMEMENU" or f.zone == "SYS_ADDONCFG" then
            f.zone = "GRID"
        end
        if f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" or f.returnZone == "QMISSOES" or f.returnZone == "QDETALHE" or f.returnZone == "ZONAS" or f.returnZone == "QNPCS" or f.returnZone == "QZONAS" or f.returnZone == "QMAPAS" or f.returnZone == "QLEITURA" or f.returnZone == "QNAV" or f.returnZone == "SYS_SUBTABS" or f.returnZone == "SYS_GAMEMENU" or f.returnZone == "SYS_ADDONCFG" then
            f.returnZone = "GRID"
        end
    elseif curTabEf == "TALENTS" then
        local defTal = "TALENTS1"
        local scrT = Nav_GetTalentActiveScreen()
        if scrT == 2 then defTal = "TALENTS2" end
        if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "EQUIP" or f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "QMISSOES" or f.zone == "QDETALHE" or f.zone == "ZONAS" or f.zone == "QNPCS" or f.zone == "QZONAS" or f.zone == "QMAPAS" or f.zone == "QLEITURA" or f.zone == "QNAV" or f.zone == "SYS_SUBTABS" or f.zone == "SYS_GAMEMENU" or f.zone == "SYS_ADDONCFG" then
            f.zone = defTal
        end
        if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "EQUIP" or f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" or f.returnZone == "QMISSOES" or f.returnZone == "QDETALHE" or f.returnZone == "ZONAS" or f.returnZone == "QNPCS" or f.returnZone == "QZONAS" or f.returnZone == "QMAPAS" or f.returnZone == "QLEITURA" or f.returnZone == "QNAV" or f.returnZone == "SYS_SUBTABS" or f.returnZone == "SYS_GAMEMENU" or f.returnZone == "SYS_ADDONCFG" then
            f.returnZone = defTal
        end
        if f.zone == "BUFFS" and bc < 1 then
            f.zone = defTal
        end
    elseif curTabEf == "QUESTS" then
        if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "TALENTS1" or f.zone == "TALENTS2" or f.zone == "EQUIP" or f.zone == "BUFFS" or f.zone == "SYS_SUBTABS" or f.zone == "SYS_GAMEMENU" or f.zone == "SYS_ADDONCFG" then
            f.zone = "QMISSOES"
        end
        if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" or f.returnZone == "EQUIP" or f.returnZone == "BUFFS" or f.returnZone == "SYS_SUBTABS" or f.returnZone == "SYS_GAMEMENU" or f.returnZone == "SYS_ADDONCFG" then
            f.returnZone = "QMISSOES"
        end
    elseif curTabEf == "SYSTEM" then
        -- F1 BINDS/PICKER: activeSubScreen decide sub-zona; sem generica p/ SYS_SUBTABS quando em BINDS/PICKER.
        local psEf = Nav_GetBindsState()
        local subEf = psEf and psEf.activeSubScreen
        if subEf == "BINDS" then
            if f.zone ~= "SYS_BINDS" and f.zone ~= "TABBAR" and f.zone ~= "HEADER_LANG" then f.zone = "SYS_BINDS" end
        elseif subEf == "PICKER" then
            if f.zone ~= "SYS_PICKER" and f.zone ~= "TABBAR" and f.zone ~= "HEADER_LANG" then f.zone = "SYS_PICKER" end
        else
            if f.zone == "CATS" or f.zone == "GRID" or f.zone == "PAGENAV" or f.zone == "SORT" or f.zone == "SPCAT" or f.zone == "SPGRID" or f.zone == "SPTABS" or f.zone == "SPPAGE" or f.zone == "TALENTS1" or f.zone == "TALENTS2" or f.zone == "EQUIP" or f.zone == "BUFFS" or f.zone == "QMISSOES" or f.zone == "QDETALHE" or f.zone == "ZONAS" or f.zone == "QNPCS" or f.zone == "QZONAS" or f.zone == "QMAPAS" or f.zone == "QLEITURA" or f.zone == "QNAV" then
                f.zone = "SYS_SUBTABS"
            end
        end
        if not subEf then
            if f.returnZone == "CATS" or f.returnZone == "GRID" or f.returnZone == "PAGENAV" or f.returnZone == "SORT" or f.returnZone == "SPCAT" or f.returnZone == "SPGRID" or f.returnZone == "SPTABS" or f.returnZone == "SPPAGE" or f.returnZone == "TALENTS1" or f.returnZone == "TALENTS2" or f.returnZone == "EQUIP" or f.returnZone == "BUFFS" or f.returnZone == "QMISSOES" or f.returnZone == "QDETALHE" or f.returnZone == "ZONAS" or f.returnZone == "QNPCS" or f.returnZone == "QZONAS" or f.returnZone == "QMAPAS" or f.returnZone == "QLEITURA" or f.returnZone == "QNAV" then
                f.returnZone = "SYS_SUBTABS"
            end
        end
        -- Conversao quando activeSubScreen existe nao toca returnZone (lição EQUIP→SPCAT/TALENTS1).
        if f.zone == "SYS_BINDS" or f.zone == "SYS_PICKER" then
            -- clamp leve de pickerSubIdx pelo num de subTabs visiveis (se existir)
            local psClamp = Nav_GetBindsState()
            if f.zone == "SYS_PICKER" and psClamp and psClamp.pickerScreen and psClamp.pickerScreen.subTabButtons then
                local okN, nst = pcall(function() return table.getn(psClamp.pickerScreen.subTabButtons) end)
                if okN and type(nst) == "number" and nst >= 1 then
                    if not f.pickerSubIdx or f.pickerSubIdx < 1 then f.pickerSubIdx = 1 end
                    if f.pickerSubIdx > nst then f.pickerSubIdx = nst end
                end
            end
            if psClamp and psClamp.pickerScreen and psClamp.pickerScreen.maxPages then
                local mp = psClamp.pickerScreen.maxPages
                if type(mp) == "number" and mp >= 1 and f.pickerPage > mp then f.pickerPage = mp end
            end
        end
    end
    if f.zone == "QMISSOES" or f.zone == "QDETALHE" then
        if f.qDetail == nil then f.qDetail = (f.zone == "QDETALHE") end
        if f.zone == "QDETALHE" then f.qDetail = true end
        pcall(function() Nav_EnsureQuestIdx() end)
    elseif f.zone == "QNAV" then
        if f.qDetail == nil then f.qDetail = false end
        if not f.navIdx or f.navIdx < 1 then f.navIdx = 1 end
        local rawNav = Nav_GetRawNavButtons()
        local n = (rawNav and table.getn(rawNav)) or 5
        if f.navIdx > n then f.navIdx = n end
    elseif f.zone == "ZONAS" then
        if f.qDetail == nil then f.qDetail = false end
    elseif f.zone == "QNPCS" or f.zone == "QZONAS" or f.zone == "QMAPAS" then
        if f.qDetail == nil then f.qDetail = false end
        if not f.npcIdx or f.npcIdx < 1 then f.npcIdx = 1 end
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
            pcall(function() Nav_PaintQnav() end)
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
                    if b then
                        if b.isHeader then
                            if b.highlight then pcall(function() b.highlight:Hide() end) end
                            if b.underline then pcall(function() b.underline:Hide() end) end
                        else
                            if b.questLogIndex and activeIdx and b.questLogIndex == activeIdx then
                                if b.highlight then
                                    b.highlight:Show()
                                    b.highlight:SetVertexColor(0.85, 0.55, 0.08, 0.28)
                                end
                                if b.underline then
                                    b.underline:Show()
                                    b.underline:SetVertexColor(0.08, 0.06, 0.04, 0.95)
                                end
                            else
                                if b.highlight then
                                    b.highlight:Hide()
                                end
                                if b.underline then
                                    b.underline:Show()
                                    b.underline:SetVertexColor(0.45, 0.38, 0.22, 0.45)
                                end
                            end
                        end
                    end
                end
            end)
            pcall(function() Nav_PaintNpcs() end)
            pcall(function() Nav_PaintQnav() end)
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

    do
        local curSys = Nav_GetCurrentTab()
        if curSys == "SYSTEM" then
            pcall(function() Nav_PaintSysSubTabs() end)
            pcall(function() Nav_PaintGameMenu() end)
            pcall(function() Nav_PaintAddonCfg() end)
            pcall(function() Nav_PaintBinds() end)
            pcall(function() Nav_PaintPicker() end)
        end
    end

    -- HEADER_LANG: destaque do botao-flag no topo esquerdo do MainMenu
    do
        local MMH = Nav_GetMM()
        local flagBtn = MMH and MMH.frame and MMH.frame.langFlagBtn
        if flagBtn then
            local nb = flagBtn.navBorder
            if f.zone == "HEADER_LANG" then
                if nb then
                    pcall(function()
                        nb:SetBackdropBorderColor(1.0, 0.85, 0.20, 1.0)
                        nb:Show()
                    end)
                end
                if flagBtn.SetBackdropBorderColor then
                    pcall(function() flagBtn:SetBackdropBorderColor(1.0, 0.85, 0.20, 1.0) end)
                end
            else
                if nb and nb.Hide then
                    pcall(function() nb:Hide() end)
                end
                if flagBtn.SetBackdropBorderColor then
                    pcall(function() flagBtn:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.80) end)
                end
            end
        end
    end
end

function Nav:EnsureFocus()
    Nav_EnsureFocus()
end

function Nav:ApplyFocus()
    Nav_ApplyFocus()
end

function Nav_OnSysSubTabsDirection(direction)
    local f = Nav.focus
    if not f.sysSubTabIdx or f.sysSubTabIdx < 1 then f.sysSubTabIdx = 1 end
    if direction == "UP" then
        f.zone = "TABBAR"
        f.returnZone = "SYS_SUBTABS"
        Nav_EnsureFocus()
        return true
    end
    if direction == "DOWN" then
        if f.sysSubTabIdx == 2 then
            f.zone = "SYS_ADDONCFG"
            f.addonCfgIdx = 1
        else
            f.zone = "SYS_GAMEMENU"
            f.gameMenuIdx = 1
        end
        Nav_EnsureFocus()
        return true
    end
    if direction == "LEFT" then
        if f.sysSubTabIdx > 1 then
            f.sysSubTabIdx = f.sysSubTabIdx - 1
            local okMM, MMM = pcall(function() return Nav_GetMM() end)
            if okMM and MMM and type(MMM.SelectSystemSubTab) == "function" then
                pcall(function() MMM:SelectSystemSubTab(f.sysSubTabIdx) end)
            end
            return true
        end
        return false
    end
    if direction == "RIGHT" then
        if f.sysSubTabIdx < 2 then
            f.sysSubTabIdx = f.sysSubTabIdx + 1
            local okMM, MMM = pcall(function() return Nav_GetMM() end)
            if okMM and MMM and type(MMM.SelectSystemSubTab) == "function" then
                pcall(function() MMM:SelectSystemSubTab(f.sysSubTabIdx) end)
            end
            return true
        end
        return false
    end
    return false
end

function Nav_OnSysGameMenuDirection(direction)
    local f = Nav.focus
    local gbtns = Nav_GetVisibleGameMenuButtons()
    local n = table.getn(gbtns)
    if direction == "UP" then
        if not f.gameMenuIdx or f.gameMenuIdx < 1 then f.gameMenuIdx = 1 end
        if f.gameMenuIdx <= 1 then
            f.zone = "SYS_SUBTABS"
            f.sysSubTabIdx = 1
            Nav_EnsureFocus()
            return true
        end
        f.gameMenuIdx = f.gameMenuIdx - 1
        return true
    end
    if direction == "DOWN" then
        if n < 1 then return false end
        if not f.gameMenuIdx or f.gameMenuIdx < 1 then f.gameMenuIdx = 1 end
        if f.gameMenuIdx >= n then return false end
        f.gameMenuIdx = f.gameMenuIdx + 1
        return true
    end
    if direction == "LEFT" then
        return false
    end
    if direction == "RIGHT" then
        f.sysSubTabIdx = 2
        f.zone = "SYS_ADDONCFG"
        f.addonCfgIdx = 1
        local okMM, MMM = pcall(function() return Nav_GetMM() end)
        if okMM and MMM and type(MMM.SelectSystemSubTab) == "function" then
            pcall(function() MMM:SelectSystemSubTab(2) end)
        end
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        return true
    end
    return false
end

function Nav_OnSysAddonCfgDirection(direction)
    local f = Nav.focus
    local abtns = Nav_GetVisibleAddonCfgButtons()
    local n = table.getn(abtns)
    if direction == "UP" then
        if not f.addonCfgIdx or f.addonCfgIdx < 1 then f.addonCfgIdx = 1 end
        if f.addonCfgIdx <= 1 then
            f.zone = "SYS_SUBTABS"
            f.sysSubTabIdx = 2
            Nav_EnsureFocus()
            return true
        end
        f.addonCfgIdx = f.addonCfgIdx - 1
        return true
    end
    if direction == "DOWN" then
        if n < 1 then return false end
        if not f.addonCfgIdx or f.addonCfgIdx < 1 then f.addonCfgIdx = 1 end
        if f.addonCfgIdx >= n then return false end
        f.addonCfgIdx = f.addonCfgIdx + 1
        return true
    end
    if direction == "LEFT" then
        f.sysSubTabIdx = 1
        f.zone = "SYS_GAMEMENU"
        f.gameMenuIdx = 1
        local okMM, MMM = pcall(function() return Nav_GetMM() end)
        if okMM and MMM and type(MMM.SelectSystemSubTab) == "function" then
            pcall(function() MMM:SelectSystemSubTab(1) end)
        end
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        return true
    end
    if direction == "RIGHT" then
        return false
    end
    return false
end

-- F3.1 BINDS: matriz 2col x 4lin (1..4 esq DUP/DDOWN/DLEFT/DRIGHT + 5..8 dir Y/X/B/A).
function Nav_OnSysBindsDirection(direction)
    local f = Nav.focus
    if not f then return false end
    if not f.bindsIdx or f.bindsIdx < 1 then f.bindsIdx = 1 end
    if f.bindsIdx > 8 then f.bindsIdx = 8 end
    local idx = f.bindsIdx
    local row = math.mod(idx - 1, 4) + 1
    if direction == "UP" then
        if row == 1 then
            f.zone = "TABBAR"
            f.returnZone = "SYS_BINDS"
            Nav_EnsureFocus()
            return true
        end
        f.bindsIdx = idx - 1
        return true
    end
    if direction == "DOWN" then
        if row == 4 then return false end
        f.bindsIdx = idx + 1
        return true
    end
    if direction == "LEFT" then
        if idx >= 5 and idx <= 8 then
            f.bindsIdx = idx - 4
            return true
        end
        return false
    end
    if direction == "RIGHT" then
        if idx >= 1 and idx <= 4 then
            f.bindsIdx = idx + 4
            return true
        end
        return false
    end
    return false
end

local function Nav_PickerPageBarVisible(scr)
    if not scr then return false end
    if scr.currentMode == "BARS" then return false end
    local pb = scr.pageBar
    if not pb then return false end
    if type(pb.IsVisible) ~= "function" then return false end
    local ok, vis = pcall(function() return pb:IsVisible() end)
    if ok and vis then return true end
    return false
end

-- F3.1 PICKER: secoes MODE/SUB/GRID/PAGE (espelho Cursor.lua HandlePickerNavigation:853 casos A/B/C/D).
function Nav_OnSysPickerDirection(direction)
    local f = Nav.focus
    if not f then return false end
    local sec = f.pickerSection
    if sec ~= "MODE" and sec ~= "SUB" and sec ~= "GRID" and sec ~= "PAGE" then
        sec = "MODE"
        f.pickerSection = "MODE"
    end
    local ps = Nav_GetBindsState()
    if not ps or not ps.pickerScreen then return false end
    local scr = ps.pickerScreen
    if direction ~= "UP" and direction ~= "DOWN" and direction ~= "LEFT" and direction ~= "RIGHT" then return false end
    if sec == "MODE" then
        if not f.pickerMode or f.pickerMode < 1 then f.pickerMode = 1 end
        if f.pickerMode > 4 then f.pickerMode = 4 end
        local pm = f.pickerMode
        if direction == "LEFT" then
            if pm <= 1 then return false end
            f.pickerMode = pm - 1
            f.pickerSubIdx = 1
            local mbs = scr.modeButtons
            local dest = mbs and mbs[f.pickerMode]
            local mid = dest and dest.modeId
            if mid then
                local MM = Nav_GetMM()
                if MM and type(MM.SetPickerMode) == "function" then
                    pcall(function() MM:SetPickerMode(mid) end)
                end
            end
            f.pickerSubIdx = 1
            return true
        end
        if direction == "RIGHT" then
            if pm >= 4 then return false end
            f.pickerMode = pm + 1
            f.pickerSubIdx = 1
            local mbs2 = scr.modeButtons
            local dest2 = mbs2 and mbs2[f.pickerMode]
            local mid2 = dest2 and dest2.modeId
            if mid2 then
                local MM2 = Nav_GetMM()
                if MM2 and type(MM2.SetPickerMode) == "function" then
                    pcall(function() MM2:SetPickerMode(mid2) end)
                end
            end
            f.pickerSubIdx = 1
            return true
        end
        if direction == "DOWN" then
            f.pickerSection = "SUB"
            Nav_EnsureFocus()
            return true
        end
        if direction == "UP" then
            f.zone = "TABBAR"
            f.returnZone = "SYS_PICKER"
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if sec == "SUB" then
        local stbs = scr.subTabButtons
        local n = 0
        if stbs then n = table.getn(stbs) end
        if not f.pickerSubIdx or f.pickerSubIdx < 1 then f.pickerSubIdx = 1 end
        if n >= 1 and f.pickerSubIdx > n then f.pickerSubIdx = n end
        local j = f.pickerSubIdx
        if direction == "LEFT" then
            if n < 1 then return false end
            if j <= 1 then return false end
            f.pickerSubIdx = j - 1
            scr.currentSubTab = f.pickerSubIdx
            local MM = Nav_GetMM()
            if MM and type(MM.RefreshPickerGrid) == "function" then
                pcall(function() MM:RefreshPickerGrid() end)
            end
            local gbs = scr.gridButtons
            local first = 1
            if gbs then
                for i = 1, 16 do
                    local b = gbs[i]
                    if b and b.itemData then first = i break end
                end
            end
            f.pickerGridIdx = first
            return true
        end
        if direction == "RIGHT" then
            if n < 1 then return false end
            if j >= n then return false end
            f.pickerSubIdx = j + 1
            scr.currentSubTab = f.pickerSubIdx
            local MM2 = Nav_GetMM()
            if MM2 and type(MM2.RefreshPickerGrid) == "function" then
                pcall(function() MM2:RefreshPickerGrid() end)
            end
            local gbs2 = scr.gridButtons
            local first2 = 1
            if gbs2 then
                for i = 1, 16 do
                    local b2 = gbs2[i]
                    if b2 and b2.itemData then first2 = i break end
                end
            end
            f.pickerGridIdx = first2
            return true
        end
        if direction == "UP" then
            f.pickerSection = "MODE"
            Nav_EnsureFocus()
            return true
        end
        if direction == "DOWN" then
            local col = math.mod((f.pickerGridIdx or 1) - 1, 4) + 1
            local cand = col
            local gbs3 = scr.gridButtons
            if gbs3 then
                local cb = gbs3[cand]
                if not cb or not cb.itemData then
                    for i = 1, 16 do
                        local b3 = gbs3[i]
                        if b3 and b3.itemData then cand = i break end
                    end
                end
            end
            f.pickerGridIdx = cand
            f.pickerSection = "GRID"
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if sec == "GRID" then
        if not f.pickerGridIdx or f.pickerGridIdx < 1 then f.pickerGridIdx = 1 end
        if f.pickerGridIdx > 16 then f.pickerGridIdx = 16 end
        local idx = f.pickerGridIdx
        local row = math.floor((idx - 1) / 4) + 1
        local col = math.mod(idx - 1, 4) + 1
        if direction == "UP" then
            if row == 1 then
                f.pickerSection = "SUB"
                Nav_EnsureFocus()
                return true
            end
            f.pickerGridIdx = idx - 4
            return true
        end
        if direction == "DOWN" then
            if row == 4 then
                if Nav_PickerPageBarVisible(scr) then
                    f.pickerSection = "PAGE"
                    if not f.pickerPageBtn or f.pickerPageBtn < 1 then f.pickerPageBtn = 1 end
                    if f.pickerPageBtn > 2 then f.pickerPageBtn = 2 end
                    Nav_EnsureFocus()
                    return true
                end
                return false
            end
            f.pickerGridIdx = idx + 4
            return true
        end
        if direction == "LEFT" then
            if col == 1 then return false end
            f.pickerGridIdx = idx - 1
            return true
        end
        if direction == "RIGHT" then
            if col == 4 then return false end
            f.pickerGridIdx = idx + 1
            return true
        end
        return false
    end
    if sec == "PAGE" then
        if not Nav_PickerPageBarVisible(scr) then
            if direction == "UP" then
                f.pickerSection = "GRID"
                Nav_EnsureFocus()
                return true
            end
            return false
        end
        if not f.pickerPageBtn or f.pickerPageBtn < 1 then f.pickerPageBtn = 1 end
        if f.pickerPageBtn > 2 then f.pickerPageBtn = 2 end
        if direction == "LEFT" then
            if f.pickerPageBtn == 1 then f.pickerPageBtn = 2 else f.pickerPageBtn = 1 end
            return true
        end
        if direction == "RIGHT" then
            if f.pickerPageBtn == 1 then f.pickerPageBtn = 2 else f.pickerPageBtn = 1 end
            return true
        end
        if direction == "UP" then
            if f.pickerPageBtn == 1 then f.pickerGridIdx = 13 else f.pickerGridIdx = 16 end
            f.pickerSection = "GRID"
            Nav_EnsureFocus()
            return true
        end
        if direction == "DOWN" then return false end
        return false
    end
    return false
end

function Nav_OnSysDirection(direction)
    local f = Nav.focus
    if f.zone == "HEADER_LANG" then
        if direction == "DOWN" or direction == "RIGHT" then
            f.zone = "TABBAR"
            f.tabIdx = 1
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if f.zone == "TABBAR" then
        if direction == "UP" then
            if f.tabIdx == 1 then
                f.returnZone = "TABBAR"
                f.zone = "HEADER_LANG"
                Nav_EnsureFocus()
                return true
            end
            return false
        end
        if direction == "DOWN" then
            local curTab = Nav_GetCurrentTab()
            if curTab == "SYSTEM" then
                local ps = Nav_GetBindsState()
                local sub = ps and ps.activeSubScreen
                if sub == "BINDS" then
                    f.zone = "SYS_BINDS"
                    f.returnZone = "SYS_BINDS"
                    Nav_EnsureFocus()
                    return true
                end
                if sub == "PICKER" then
                    f.zone = "SYS_PICKER"
                    f.returnZone = "SYS_PICKER"
                    f.pickerSection = "MODE"
                    Nav_EnsureFocus()
                    return true
                end
            end
            f.zone = "SYS_SUBTABS"
            f.sysSubTabIdx = f.sysSubTabIdx or 1
            Nav_EnsureFocus()
            return true
        end
        if direction == "LEFT" then
            if f.tabIdx > 1 then f.tabIdx = f.tabIdx - 1 return true end
            return false
        end
        if direction == "RIGHT" then
            local tabs = Nav_GetTabButtons()
            local nt = (tabs and table.getn(tabs)) or 5
            if f.tabIdx < nt then f.tabIdx = f.tabIdx + 1 return true end
            return false
        end
        return false
    end
    if f.zone == "SYS_SUBTABS" then
        return Nav_OnSysSubTabsDirection(direction)
    end
    if f.zone == "SYS_GAMEMENU" then
        return Nav_OnSysGameMenuDirection(direction)
    end
    if f.zone == "SYS_ADDONCFG" then
        return Nav_OnSysAddonCfgDirection(direction)
    end
    if f.zone == "SYS_BINDS" then return Nav_OnSysBindsDirection(direction) end
    if f.zone == "SYS_PICKER" then return Nav_OnSysPickerDirection(direction) end
    return false
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
        local sf = getglobal("ConsoleModeMM_MapNPCScrollFrame")
        if sf and sf.GetVerticalScroll then
            local btnH = 28
            local gap = 3
            local cur = sf:GetVerticalScroll() or 0
            local vpH = sf:GetHeight() or 200
            if vpH <= 0 then vpH = 200 end
            local visRows = math.floor(vpH / (btnH + gap))
            if visRows < 1 then visRows = 6 end
            local firstVis = math.floor(cur / (btnH + gap)) + 1
            if f.npcIdx < firstVis then
                sf:SetVerticalScroll((f.npcIdx - 1) * (btnH + gap))
            end
        end
        return true
    end
    if direction == "DOWN" then
        if n < 1 then return false end
        if not f.npcIdx or f.npcIdx < 1 then f.npcIdx = 1 end
        if f.npcIdx > n then f.npcIdx = n end
        if f.npcIdx >= n then return false end
        f.npcIdx = f.npcIdx + 1
        local sf = getglobal("ConsoleModeMM_MapNPCScrollFrame")
        if sf and sf.GetVerticalScroll then
            local btnH = 28
            local gap = 3
            local cur = sf:GetVerticalScroll() or 0
            local vpH = sf:GetHeight() or 200
            if vpH <= 0 then vpH = 200 end
            local visRows = math.floor(vpH / (btnH + gap))
            if visRows < 1 then visRows = 6 end
            local firstVis = math.floor(cur / (btnH + gap)) + 1
            local lastVis = firstVis + visRows - 1
            if f.npcIdx > lastVis then
                sf:SetVerticalScroll((f.npcIdx - visRows) * (btnH + gap))
            end
        end
        return true
    end
    if direction == "RIGHT" then
        local zf = Nav_GetZoneListFrame()
        local vz = Nav_GetVisibleZones()
        if zf and SafeIsVisible(zf) and table.getn(vz) > 0 then
            f.zone = "QZONAS"
            f.zonaIdx = 1
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            return true
        end
        f.zone = "QNAV"
        f.navIdx = f.navIdx or 1
        Nav_EnsureFocus()
        Nav_ApplyFocus()
        return true
    end
    if direction == "LEFT" then
        return false
    end
    return false
end

function Nav_OnQnavDirection(direction)
    local f = Nav.focus
    if not f.navIdx or f.navIdx < 1 then f.navIdx = 1 end
    local rawNav = Nav_GetRawNavButtons()
    local n = (rawNav and table.getn(rawNav)) or 5
    if f.navIdx > n then f.navIdx = n end
    if direction == "UP" then
        if f.navIdx <= 1 then
            f.zone = "TABBAR"
            Nav_EnsureFocus()
            return true
        end
        f.navIdx = f.navIdx - 1
        return true
    end
    if direction == "DOWN" then
        if f.navIdx >= n then return false end
        f.navIdx = f.navIdx + 1
        return true
    end
    if direction == "RIGHT" then
        local zf = Nav_GetZoneListFrame()
        local vz = Nav_GetVisibleZones()
        if zf and SafeIsVisible(zf) and vz and table.getn(vz) > 0 then
            f.zone = "QZONAS"
            f.zonaIdx = 1
            Nav_EnsureFocus()
            return true
        end
        f.zone = "QMISSOES"
        f.qDetail = false
        Nav_EnsureFocus()
        return true
    end
    if direction == "LEFT" then
        local npcPanel = Nav_GetNpcPanel()
        local npcs = Nav_GetVisibleNpcs()
        if npcPanel and SafeIsVisible(npcPanel) and npcs and table.getn(npcs) > 0 then
            f.zone = "QNPCS"
            f.npcIdx = 1
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    return false
end

function Nav_OnQzonasDirection(direction)
    local f = Nav.focus
    local zones = Nav_GetVisibleZones()
    local n = table.getn(zones)
    if direction == "UP" then
        if n < 1 then return false end
        if not f.zonaIdx or f.zonaIdx < 1 then f.zonaIdx = 1 end
        if f.zonaIdx > n then f.zonaIdx = n end
        if f.zonaIdx <= 1 then
            f.zone = "TABBAR"
            Nav_EnsureFocus()
            return true
        end
        f.zonaIdx = f.zonaIdx - 1
        local zf = Nav_GetZoneListFrame()
        local sf = (zf and zf.scrollFrame) or getglobal("ConsoleModeMM_ZoneListScroll")
        if sf and sf.GetVerticalScroll then
            local btnH = 28
            local gap = 3
            local cur = sf:GetVerticalScroll() or 0
            local vpH = sf:GetHeight() or 200
            if vpH <= 0 then vpH = 200 end
            local visRows = math.floor(vpH / (btnH + gap))
            if visRows < 1 then visRows = 6 end
            local firstVis = math.floor(cur / (btnH + gap)) + 1
            if f.zonaIdx < firstVis then
                sf:SetVerticalScroll((f.zonaIdx - 1) * (btnH + gap))
            end
        end
        return true
    end
    if direction == "DOWN" then
        if n < 1 then return false end
        if not f.zonaIdx or f.zonaIdx < 1 then f.zonaIdx = 1 end
        if f.zonaIdx > n then f.zonaIdx = n end
        if f.zonaIdx >= n then return false end
        f.zonaIdx = f.zonaIdx + 1
        local zf = Nav_GetZoneListFrame()
        local sf = (zf and zf.scrollFrame) or getglobal("ConsoleModeMM_ZoneListScroll")
        if sf and sf.GetVerticalScroll then
            local btnH = 28
            local gap = 3
            local cur = sf:GetVerticalScroll() or 0
            local vpH = sf:GetHeight() or 200
            if vpH <= 0 then vpH = 200 end
            local visRows = math.floor(vpH / (btnH + gap))
            if visRows < 1 then visRows = 6 end
            local firstVis = math.floor(cur / (btnH + gap)) + 1
            local lastVis = firstVis + visRows - 1
            if f.zonaIdx > lastVis then
                sf:SetVerticalScroll((f.zonaIdx - visRows) * (btnH + gap))
            end
        end
        return true
    end
    if direction == "LEFT" then
        local npcPanel = Nav_GetNpcPanel()
        local npcs = Nav_GetVisibleNpcs()
        if npcPanel and SafeIsVisible(npcPanel) and npcs and table.getn(npcs) > 0 then
            f.zone = "QNPCS"
            f.npcIdx = 1
            Nav_EnsureFocus()
            return true
        end
        f.zone = "QNAV"
        f.navIdx = f.navIdx or 1
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
    if f.zone == "HEADER_LANG" then
        if direction == "DOWN" or direction == "RIGHT" then
            f.zone = "TABBAR"
            f.tabIdx = 5
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if f.zone == "QLEITURA" or IsQuestDetailOpen() then
        local MM = Nav_GetMM()
        local overlay = MM and MM.questDetailOverlay
        if overlay and overlay.scroll then
            local cur = overlay.scroll:GetVerticalScroll() or 0
            local maxScroll = 0
            if overlay.scroll.GetVerticalScrollRange then
                maxScroll = overlay.scroll:GetVerticalScrollRange() or 0
            end
            if direction == "UP" then
                local nextScroll = cur - 40
                if nextScroll < 0 then nextScroll = 0 end
                overlay.scroll:SetVerticalScroll(nextScroll)
                return true
            elseif direction == "DOWN" then
                local nextScroll = cur + 40
                if maxScroll > 0 and nextScroll > maxScroll then nextScroll = maxScroll end
                overlay.scroll:SetVerticalScroll(nextScroll)
                return true
            end
        end
        return false
    end
    Nav_EnsureQuestIdx()
    if f.zone == "TABBAR" then
        if direction == "UP" then
            if f.tabIdx == 1 or f.tabIdx == 5 then
                f.returnZone = "TABBAR"
                f.zone = "HEADER_LANG"
                Nav_EnsureFocus()
                return true
            end
            return false
        end
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
                if MM and type(MM.FocusMapOnQuest) == "function" then
                    pcall(function() MM:FocusMapOnQuest(f.questIdx) end)
                end
            end
            return true
        end
        return false
    end
    if f.zone == "ZONAS" then
        f.zone = "QZONAS"
        if not f.zonaIdx or f.zonaIdx < 1 then f.zonaIdx = 1 end
        Nav_EnsureFocus()
        return Nav_OnQzonasDirection(direction)
    end
    if f.zone == "QNPCS" then
        return Nav_OnQnpcsDirection(direction)
    end
    if f.zone == "QNAV" then
        return Nav_OnQnavDirection(direction)
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
        local zf = Nav_GetZoneListFrame()
        local vz = Nav_GetVisibleZones()
        if zf and SafeIsVisible(zf) and table.getn(vz) > 0 then
            f.zone = "QZONAS"
            f.zonaIdx = 1
        else
            f.zone = "QNAV"
            f.navIdx = f.navIdx or 1
        end
        f.qDetail = false
        Nav_EnsureFocus()
        Nav_ApplyFocus()
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

    if IsLangPickerOpen() then
        local MM = Nav_GetMM()
        if MM and type(MM.NavLangPickerDirection) == "function" then
            local handled = MM:NavLangPickerDirection(direction)
            if handled then MMNav_PlayMove() end
            return
        end
    end

    local curTab = Nav_GetCurrentTab()
    if curTab == "CHARACTER" then
        -- FASE 2 Aba Personagem: UP/DOWN rolam o ScrollFrame do modulo
        -- isolado UI/CharacterScreen.lua (guards; nunca quebra as outras abas).
        local csMod = getglobal("ConsoleMode_CharacterScreen")
        if csMod and type(csMod.OnDirection) == "function" then
            local okCs, consumedCs = pcall(function() return csMod:OnDirection(direction) end)
            if okCs and consumedCs then MMNav_PlayMove() end
            return
        end
        MMNav_PlayMove()
        return
    end
    if curTab == "SYSTEM" then
        Nav_EnsureFocus()
        local movedSys = Nav_OnSysDirection(direction)
        Nav_ApplyFocus()
        if movedSys then MMNav_PlayMove() end
        return
    end
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
        -- MMNav_Log("|cffe09a15[MMNav]|r " .. tostring(direction)) -- NOLOG 2026-09-14
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
    if f.zone == "HEADER_LANG" then
        if direction == "DOWN" or direction == "RIGHT" then
            if f.returnZone == "EQUIP" then
                f.zone = "EQUIP"
                if not f.equipIndex or f.equipIndex < 1 then f.equipIndex = 1 end
            else
                f.zone = "TABBAR"
                f.tabIdx = 4
            end
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if direction == "UP" then
        if f.zone == "TABBAR" then
            if f.tabIdx == 1 or f.tabIdx == 4 then
                f.returnZone = "TABBAR"
                f.zone = "HEADER_LANG"
                Nav_EnsureFocus()
                return true
            end
            return false
        end
        if f.zone == "EQUIP" then
            if f.equipIndex > 1 then f.equipIndex = f.equipIndex - 1 return true end
            -- Slot HEAD (equipIndex 1): UP vai para a bandeira no header.
            f.returnZone = "EQUIP"
            f.zone = "HEADER_LANG"
            Nav_EnsureFocus()
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
    local MM = Nav_GetMM()
    if MM and MM.IsTalentInspectModalOpen and MM:IsTalentInspectModalOpen() then
        if direction == "UP" or direction == "DOWN" then
            local scroll = getglobal("ConsoleModeMM_TalentInspectScroll")
            if scroll then
                local cur = scroll:GetVerticalScroll() or 0
                local step = 32
                if direction == "UP" then
                    scroll:SetVerticalScroll(math.max(0, cur - step))
                else
                    scroll:SetVerticalScroll(cur + step)
                end
                return true
            end
        end
        return true
    end

    local f = Nav.focus
    if f.zone == "HEADER_LANG" then
        if direction == "DOWN" or direction == "RIGHT" then
            if f.returnZone == "EQUIP" then
                f.zone = "EQUIP"
                if not f.equipIndex or f.equipIndex < 1 then f.equipIndex = 1 end
            else
                f.zone = "TABBAR"
                f.tabIdx = 3
            end
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if direction == "UP" then
        if f.zone == "TABBAR" then
            if f.tabIdx == 1 then
                f.returnZone = "TABBAR"
                f.zone = "HEADER_LANG"
                Nav_EnsureFocus()
                return true
            end
            return false
        end
        if f.zone == "EQUIP" then
            if f.equipIndex > 1 then f.equipIndex = f.equipIndex - 1 return true end
            -- Slot HEAD (equipIndex 1): UP vai para a bandeira no header.
            f.returnZone = "EQUIP"
            f.zone = "HEADER_LANG"
            Nav_EnsureFocus()
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
    if f.zone == "HEADER_LANG" then
        if direction == "DOWN" or direction == "RIGHT" then
            -- DOWN volta para a origem: EQUIP (slot HEAD) ou TABBAR (aba BAGS).
            if f.returnZone == "EQUIP" then
                f.zone = "EQUIP"
                if not f.equipIndex or f.equipIndex < 1 then f.equipIndex = 1 end
            else
                f.zone = "TABBAR"
                f.tabIdx = 1
            end
            Nav_EnsureFocus()
            return true
        end
        return false
    end
    if direction == "UP" then
        if f.zone == "TABBAR" then
            if f.tabIdx == 1 then
                f.returnZone = "TABBAR"
                f.zone = "HEADER_LANG"
                Nav_EnsureFocus()
                return true
            end
            return false
        end
        if f.zone == "EQUIP" then
            if f.equipIndex > 1 then f.equipIndex = f.equipIndex - 1 return true end
            -- Slot HEAD (equipIndex 1): UP vai para a bandeira no header.
            f.returnZone = "EQUIP"
            f.zone = "HEADER_LANG"
            Nav_EnsureFocus()
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
    local MM = Nav_GetMM()
    if MM and MM.IsTalentInspectModalOpen and MM:IsTalentInspectModalOpen() then
        if type(MM.ConfirmTalentInspectModal) == "function" then
            MM:ConfirmTalentInspectModal()
        end
        return true
    end

    if IsLangPickerOpen() then
        local MM = Nav_GetMM()
        if MM and type(MM.ConfirmLangPicker) == "function" then
            local ok = MM:ConfirmLangPicker()
            if ok then MMNav_PlayMove() end
            return true
        end
        return true
    end

    if self.focus and self.focus.zone == "HEADER_LANG" then
        local MM = Nav_GetMM()
        if MM and type(MM.OpenLangPicker) == "function" then
            MM:OpenLangPicker()
            MMNav_PlayMove()
            return true
        end
        return true
    end

    local curTabCf = Nav_GetCurrentTab()
    if curTabCf == "SYSTEM" then
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
        if fs.zone == "SYS_SUBTABS" then
            local subTabs = Nav_GetSysSubTabs()
            local idx = fs.sysSubTabIdx or 1
            local b = subTabs and subTabs[idx]
            if b then
                pcall(function() b:Click() end)
                return true
            end
            local MM = Nav_GetMM()
            if MM and type(MM.SelectSystemSubTab) == "function" then
                pcall(function() MM:SelectSystemSubTab(idx) end)
                return true
            end
            return false
        end
        if fs.zone == "SYS_GAMEMENU" then
            local gbtns = Nav_GetVisibleGameMenuButtons()
            local idx = fs.gameMenuIdx or 1
            local b = gbtns and gbtns[idx]
            if b then
                pcall(function() b:Click() end)
                return true
            end
            return false
        end
        if fs.zone == "SYS_ADDONCFG" then
            local abtns = Nav_GetVisibleAddonCfgButtons()
            local idx = fs.addonCfgIdx or 1
            local b = abtns and abtns[idx]
            if b then
                pcall(function() b:Click() end)
                -- Se clicou na 1a linha (Binds), a tela muda para sub-estado BINDS;
                -- registra no Nav para OnCancel/Dpad não ficarem stales (F1 minimo).
                local ps = Nav_GetBindsState()
                if ps and ps.activeSubScreen == "BINDS" then
                    fs.zone = "SYS_BINDS"
                    fs.returnZone = "SYS_BINDS"
                    fs.bindsIdx = 1
                    if ps.bindsScreen and ps.bindsScreen.currentPage then fs.bindsPage = ps.bindsScreen.currentPage end
                    local MM = Nav_GetMM()
                    if MM and type(MM.FocusBindsSlot) == "function" and ps.bindsScreen and ps.bindsScreen.bindCards and ps.bindsScreen.bindCards[1] then
                        pcall(function() MM:FocusBindsSlot(ps.bindsScreen.bindCards[1]) end)
                    end
                    Nav_EnsureFocus()
                    Nav_ApplyFocus()
                end
                return true
            end
            return false
        end
        if fs.zone == "SYS_BINDS" then
            local ps = Nav_GetBindsState()
            if ps and ps.bindsScreen and ps.bindsScreen.bindCards then
                local idx = fs.bindsIdx or 1
                local b = ps.bindsScreen.bindCards[idx]
                if b and type(b.GetScript) == "function" then
                    local MM = Nav_GetMM()
                    if MM and type(MM.OpenPickerForSlot) == "function" then
                        pcall(function() MM:OpenPickerForSlot(b) end)
                        local ps2 = Nav_GetBindsState()
                        if ps2 and ps2.activeSubScreen == "PICKER" then
                            fs.zone = "SYS_PICKER"
                            fs.pickerSection = "MODE"
                            if not fs.pickerMode or fs.pickerMode < 1 then fs.pickerMode = 1 end
                            if not fs.pickerSubIdx or fs.pickerSubIdx < 1 then fs.pickerSubIdx = 1 end
                            if not fs.pickerGridIdx or fs.pickerGridIdx < 1 then fs.pickerGridIdx = 1 end
                            if not fs.pickerPageBtn or fs.pickerPageBtn < 1 then fs.pickerPageBtn = 1 end
                            fs.returnZone = "SYS_BINDS"
                            Nav_EnsureFocus()
                            Nav_ApplyFocus()
                        end
                    end
                end
            end
            return true
        end
        if fs.zone == "SYS_PICKER" then
            local sec = fs.pickerSection
            if sec ~= "MODE" and sec ~= "SUB" and sec ~= "GRID" and sec ~= "PAGE" then sec = "MODE" fs.pickerSection = "MODE" end
            local psc = Nav_GetBindsState()
            local scrc = psc and psc.pickerScreen
            local MMc = Nav_GetMM()
            if sec == "MODE" then
                if scrc and scrc.modeButtons and MMc and type(MMc.SetPickerMode) == "function" then
                    local pm = fs.pickerMode or 1
                    if pm < 1 then pm = 1 end
                    if pm > 4 then pm = 4 end
                    fs.pickerMode = pm
                    local mb = scrc.modeButtons[pm]
                    local mid = mb and mb.modeId
                    if mid then pcall(function() MMc:SetPickerMode(mid) end) end
                end
                fs.pickerSubIdx = 1
                fs.pickerSection = "SUB"
                Nav_EnsureFocus()
                Nav_ApplyFocus()
                return true
            end
            if sec == "SUB" then
                if scrc then
                    local sj = fs.pickerSubIdx or 1
                    if sj < 1 then sj = 1 end
                    scrc.currentSubTab = sj
                    if MMc and type(MMc.RefreshPickerGrid) == "function" then
                        pcall(function() MMc:RefreshPickerGrid() end)
                    end
                    local gbs = scrc.gridButtons
                    local first = 1
                    if gbs then
                        for i = 1, 16 do
                            local gb = gbs[i]
                            if gb and gb.itemData then first = i break end
                        end
                    end
                    fs.pickerGridIdx = first
                end
                fs.pickerSection = "GRID"
                Nav_EnsureFocus()
                Nav_ApplyFocus()
                return true
            end
            if sec == "GRID" then
                if scrc and scrc.gridButtons then
                    local gi = fs.pickerGridIdx or 1
                    if gi < 1 then gi = 1 end
                    if gi > 16 then gi = 16 end
                    fs.pickerGridIdx = gi
                    local btn = scrc.gridButtons[gi]
                    if btn and btn.itemData then
                        if MMc and type(MMc.OnPickerSlotClick) == "function" then
                            pcall(function() MMc:OnPickerSlotClick(btn) end)
                        end
                        Nav_EnsureFocus()
                        Nav_ApplyFocus()
                        return true
                    end
                end
                return true
            end
            if sec == "PAGE" then
                if scrc then
                    local pb = fs.pickerPageBtn or 1
                    if pb < 1 then pb = 1 end
                    if pb > 2 then pb = 2 end
                    fs.pickerPageBtn = pb
                    local mp = scrc.maxPages or 1
                    if type(mp) ~= "number" or mp < 1 then mp = 1 end
                    local gp = scrc.gridPage or 1
                    if type(gp) ~= "number" or gp < 1 then gp = 1 end
                    if gp > mp then gp = mp end
                    if pb == 1 then
                        gp = gp - 1
                        if gp < 1 then gp = 1 end
                    else
                        gp = gp + 1
                        if gp > mp then gp = mp end
                    end
                    scrc.gridPage = gp
                    if MMc and type(MMc.RefreshPickerGrid) == "function" then
                        pcall(function() MMc:RefreshPickerGrid() end)
                    end
                end
                Nav_EnsureFocus()
                Nav_ApplyFocus()
                return true
            end
            return true
        end
        return false
    end
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
        if fq.zone == "QLEITURA" or IsQuestDetailOpen() then
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
            if MM then
                if type(MM.FocusMapOnQuest) == "function" then
                    pcall(function() MM:FocusMapOnQuest(idx) end)
                end
                if type(MM.SelectQuest) == "function" then
                    pcall(function() MM:SelectQuest(idx, true) end)
                end
                if type(MM.ShowQuestDetail) == "function" then
                    pcall(function() MM:ShowQuestDetail(idx) end)
                    fq.zone = "QLEITURA"
                end
                Nav_ApplyFocus()
                return true
            else
                -- MMNav_Log("|cffe09a15[MMNav]|r MM ausente") -- NOLOG 2026-09-14
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
        if fq.zone == "QNAV" then
            local rawNav = Nav_GetRawNavButtons()
            local idx = fq.navIdx or 1
            local b = rawNav and rawNav[idx]
            if not b then return false end
            pcall(function() b:Click() end)
            local zf = Nav_GetZoneListFrame()
            if zf and SafeIsVisible(zf) then
                local vz = Nav_GetVisibleZones()
                if vz and table.getn(vz) > 0 then
                    fq.zone = "QZONAS"
                    fq.zonaIdx = 1
                end
            else
                fq.zone = "QNAV"
            end
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            return true
        end
        if fq.zone == "QZONAS" or fq.zone == "ZONAS" then
            local zones = Nav_GetVisibleZones()
            local zb = zones and zones[fq.zonaIdx]
            if not zb then return false end
            pcall(function() zb:Click() end)
            local zf = Nav_GetZoneListFrame()
            if zf and type(zf.Hide) == "function" then
                zf:Hide()
            end
            local MM = Nav_GetMM()
            if MM then
                if type(MM.HideZonePin) == "function" then
                    MM:HideZonePin()
                end
                if type(MM.HideInstancesList) == "function" then
                    MM:HideInstancesList()
                end
            end
            fq.zone = "QNAV"
            fq.navIdx = fq.navIdx or 1
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            return true
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
            local MM = Nav_GetMM()
            if MM then
                if MM.IsTalentInspectModalOpen and MM:IsTalentInspectModalOpen() then
                    MM:ConfirmTalentInspectModal()
                else
                    if slot and slot.talentData then
                        if type(MM.ShowTalentInspectModal) == "function" then
                            MM:ShowTalentInspectModal(slot)
                        elseif type(MM.SpendTalentPoint) == "function" then
                            local ti, tj = slot.talentData.tabIndex, slot.talentData.talentIndex
                            pcall(function() MM:SpendTalentPoint(ti, tj) end)
                        end
                    end
                end
            end
            return true
        end
        return false
    end
    if curTabCf ~= "BAGS" then
        -- MMNav_Log("|cffe09a15[MMNav]|r A (fase1: cursor ainda trata)") -- NOLOG 2026-09-14
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
    local MM = Nav_GetMM()
    if MM and MM.IsTalentInspectModalOpen and MM:IsTalentInspectModalOpen() then
        if type(MM.HideTalentInspectModal) == "function" then
            MM:HideTalentInspectModal()
            MMNav_PlayMove()
        end
        return true
    end

    if not self:IsActive() then return false end

    if IsLangPickerOpen() then
        local MM = Nav_GetMM()
        if MM and type(MM.CloseLangPicker) == "function" then
            MM:CloseLangPicker()
            MMNav_PlayMove()
            return true
        end
        return true
    end

    if self.focus and self.focus.zone == "HEADER_LANG" then
        self.focus.zone = self.focus.returnZone or "TABBAR"
        self:EnsureFocus()
        self:ApplyFocus()
        MMNav_PlayMove()
        return true
    end

    local curTabCx = Nav_GetCurrentTab()
    if curTabCx == "SYSTEM" then
        Nav_EnsureFocus()
        local fs = self.focus
        -- F1 BINDS/PICKER: regresso deterministico antes de SYS_GAMEMENU/ADDONCFG (lição SPCAT/TALENTS1→TABBAR).
        if fs.zone == "SYS_PICKER" then
            local MM = Nav_GetMM()
            if MM and type(MM.HandleBindsBack) == "function" then pcall(function() MM:HandleBindsBack() end) end
            fs.zone = "SYS_BINDS"
            fs.returnZone = "SYS_BINDS"
            if not fs.bindsIdx or fs.bindsIdx < 1 then fs.bindsIdx = 1 end
            if fs.bindsIdx > 8 then fs.bindsIdx = 8 end
            local psb = Nav_GetBindsState()
            if MM and type(MM.FocusBindsSlot) == "function" and psb and psb.bindsScreen and psb.bindsScreen.bindCards then
                local bi = fs.bindsIdx or 1
                local card = psb.bindsScreen.bindCards[bi]
                if not card then card = psb.bindsScreen.bindCards[1] bi = 1 end
                if card then pcall(function() MM:FocusBindsSlot(card) end) end
                fs.bindsIdx = bi
            end
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        if fs.zone == "SYS_BINDS" then
            local MM = Nav_GetMM()
            if MM and type(MM.HandleBindsBack) == "function" then pcall(function() MM:HandleBindsBack() end) else fs.zone = "SYS_ADDONCFG" end
            if fs.zone == "SYS_BINDS" then fs.zone = "SYS_ADDONCFG" end
            fs.returnZone = "SYS_BINDS"
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        if fs.zone == "SYS_GAMEMENU" or fs.zone == "SYS_ADDONCFG" then
            fs.zone = "SYS_SUBTABS"
            fs.returnZone = fs.zone
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        if fs.zone == "SYS_SUBTABS" then
            fs.zone = "TABBAR"
            fs.returnZone = "SYS_SUBTABS"
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        if fs.zone == "TABBAR" then
            local MM = Nav_GetMM()
            if MM and type(MM.Hide) == "function" then
                MM:Hide()
                return true
            end
        end
        return false
    end
    if curTabCx == "QUESTS" then
        Nav_EnsureFocus()
        local fq = self.focus
        if IsQuestDetailOpen() or fq.zone == "QLEITURA" then
            local MM = Nav_GetMM()
            if MM and type(MM.HideQuestDetail) == "function" then
                MM:HideQuestDetail()
            end
            fq.zone = "QMISSOES"
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        if fq.zone == "QZONAS" or fq.zone == "QMAPAS" or fq.zone == "ZONAS" then
            local zf = Nav_GetZoneListFrame()
            if zf and type(zf.Hide) == "function" then
                zf:Hide()
            end
            local MM = Nav_GetMM()
            if MM then
                if type(MM.HideZonePin) == "function" then
                    MM:HideZonePin()
                end
                if type(MM.HideInstancesList) == "function" then
                    MM:HideInstancesList()
                end
            end
            fq.zone = "QNAV"
            fq.navIdx = fq.navIdx or 1
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
        if self.focus and self.focus.zone == "SPGRID" then
            if isGridScreen then
                local MM = Nav_GetMM()
                if MM and type(MM.ShowSpellCategoryScreen) == "function" then
                    pcall(function() MM:ShowSpellCategoryScreen() end)
                elseif MM and type(MM.HandleSpellsBack) == "function" then
                    pcall(function() MM:HandleSpellsBack() end)
                end
            end
            self.focus.zone = "SPCAT"
            if ps and type(ps.focusedCatIdx) == "number" then self.focus.spellCat = ps.focusedCatIdx end
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
            fsp.returnZone = "SPCAT"
            fsp.zone = "TABBAR"
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
        if MM and MM.IsTalentInspectModalOpen and MM:IsTalentInspectModalOpen() then
            MM:HideTalentInspectModal()
            MMNav_PlayMove()
            return true
        end
        local pt = nil
        if MM and MM.tabContainer and MM.tabContainer.pages then
            pt = MM.tabContainer.pages["TALENTS"]
        end
        local scr = pt and pt.activeScreen
        if self.focus and self.focus.zone == "TALENTS2" then
            if scr == 2 then
                if MM and type(MM.HandleTalentsBack) == "function" then
                    pcall(function() MM:HandleTalentsBack() end)
                end
            end
            self.focus.zone = "TALENTS1"
            if pt and type(pt.focusedSpecIdx) == "number" then self.focus.talentSpec = pt.focusedSpecIdx end
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
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
            ftp.returnZone = "TALENTS1"
            ftp.zone = "TABBAR"
            Nav_EnsureFocus()
            Nav_ApplyFocus()
            MMNav_PlayMove()
            return true
        end
        return false
    end
    if curTabCx ~= "BAGS" then
        -- MMNav_Log("|cffe09a15[MMNav]|r B (fase1: cursor ainda trata)") -- NOLOG 2026-09-14
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
            if MM and type(MM.AbandonSelectedQuest) == "function" then
                pcall(function() MM:AbandonSelectedQuest(idx) end)
                return true
            else
                -- MMNav_Log("|cffe09a15[MMNav]|r AbandonSelectedQuest ausente") -- NOLOG 2026-09-14
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
        -- MMNav_Log("|cffe09a15[MMNav]|r Y (fase1: cursor ainda trata)") -- NOLOG 2026-09-14
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
        if IsQuestDetailOpen() or fq.zone == "QLEITURA" then
            local MM = Nav_GetMM()
            local overlay = MM and MM.questDetailOverlay
            local idx = (overlay and overlay.currentQuestIndex) or fq.questIdx
            if idx and idx >= 1 and MM and type(MM.ToggleQuestWatch) == "function" then
                pcall(function() MM:ToggleQuestWatch(idx) end)
                if overlay and overlay.trackBtn and overlay.trackBtn.label and type(IsQuestWatched) == "function" then
                    -- FASE 3 (linguagem): rotulos via CM:T em runtime (mesmo conceito do MainMenu).
                    local cmNav = getglobal("ConsoleMode")
                    if IsQuestWatched(idx) then
                        overlay.trackBtn.label:SetText(cmNav:T("HINT_UNTRACK"))
                    else
                        overlay.trackBtn.label:SetText(cmNav:T("HINT_TRACK"))
                    end
                end
                return true
            end
            return false
        end
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
                -- MMNav_Log("|cffe09a15[MMNav]|r ToggleQuestWatch ausente") -- NOLOG 2026-09-14
                return false
            end
        end
        return false
    end
    -- MMNav_Log("|cffe09a15[MMNav]|r X (fase2 BAGS: sem acao)") -- NOLOG 2026-09-14
    return false
end

function Nav:OnNextTab()
    if Nav.focus and (Nav.focus.zone == "SYS_BINDS" or Nav.focus.zone == "SYS_PICKER") then return true end
    local ps = Nav_GetBindsState()
    local sub = ps and ps.activeSubScreen
    if sub == "BINDS" or sub == "PICKER" then return true end
    -- MMNav_Log("|cffe09a15[MMNav]|r RB (fase2: cursor ainda trata)") -- NOLOG 2026-09-14
    return false
end

function Nav:OnPrevTab()
    if Nav.focus and (Nav.focus.zone == "SYS_BINDS" or Nav.focus.zone == "SYS_PICKER") then return true end
    local ps = Nav_GetBindsState()
    local sub = ps and ps.activeSubScreen
    if sub == "BINDS" or sub == "PICKER" then return true end
    -- MMNav_Log("|cffe09a15[MMNav]|r LB (fase2: cursor ainda trata)") -- NOLOG 2026-09-14
    return false
end

function Nav:OnNextSubTab()
    local ps = Nav_GetBindsState()
    local sub = ps and ps.activeSubScreen
    local inBindsOrPicker = (Nav.focus and (Nav.focus.zone == "SYS_BINDS" or Nav.focus.zone == "SYS_PICKER")) or (sub == "BINDS" or sub == "PICKER")
    if inBindsOrPicker then
        if sub == "PICKER" then
            return true
        end
        if sub == "BINDS" then
            local MM = Nav_GetMM()
            if MM and type(MM.SelectBindsPage) == "function" then
                local cur = (ps and ps.bindsScreen and ps.bindsScreen.currentPage) or (Nav.focus and Nav.focus.bindsPage) or 1
                local nxt = cur + 1
                if nxt > 4 then nxt = 1 end
                pcall(function() MM:SelectBindsPage(nxt) end)
                if Nav.focus then Nav.focus.bindsPage = nxt end
                if Nav.focus and MM and type(MM.FocusBindsSlot) == "function" and ps and ps.bindsScreen and ps.bindsScreen.bindCards then
                    local bi = Nav.focus.bindsIdx or 1
                    if bi < 1 then bi = 1 end
                    if bi > 8 then bi = 8 end
                    Nav.focus.bindsIdx = bi
                    local card = ps.bindsScreen.bindCards[bi]
                    if card then pcall(function() MM:FocusBindsSlot(card) end) end
                end
                Nav_EnsureFocus()
                Nav_ApplyFocus()
            end
            return true
        end
        return true
    end
    -- DEMANDA 2: LT/RT em SYSTEM sincroniza currentSubTab + sysSubTabIdx (sem depender de Cursor:CycleSubTabs)
    if Nav_GetCurrentTab() == "SYSTEM" and not (ps and ps.activeSubScreen) then
        local MM = Nav_GetMM()
        if MM and type(MM.SelectSystemSubTab) == "function" and MM.tabContainer and MM.tabContainer.pages then
            local pageSystem = MM.tabContainer.pages["SYSTEM"]
            if pageSystem then
                local curId = pageSystem.currentSubTab or "GAME_MENU"
                local subTabs = pageSystem.subTabs
                local total = 0
                if subTabs then total = table.getn(subTabs) end
                local curIdx = 1
                if total > 0 then
                    for i = 1, total do
                        local st = subTabs[i]
                        if st and st.id == curId then curIdx = i; break end
                    end
                    -- fallback se currentSubTab numerico
                    if type(curId) == "number" and curId >= 1 and curId <= total then curIdx = curId end
                else
                    if curId == "ADDON_CFG" then curIdx = 2 else curIdx = 1 end
                    total = 2
                    subTabs = { { id = "GAME_MENU" }, { id = "ADDON_CFG" } }
                end
                local nextIdx = curIdx + 1
                if nextIdx > total then nextIdx = 1 end
                local nextId = subTabs[nextIdx] and subTabs[nextIdx].id or "GAME_MENU"
                if Nav.focus then Nav.focus.sysSubTabIdx = nextIdx end
                pcall(function() MM:SelectSystemSubTab(nextId) end)
                -- Se estava dentro das listas, espelha o movimento lateral RIGHT/LEFT
                if Nav.focus then
                    if Nav.focus.zone == "SYS_SUBTABS" then
                        if nextId == "ADDON_CFG" then
                            Nav.focus.zone = "SYS_ADDONCFG"
                            Nav.focus.addonCfgIdx = 1
                        else
                            Nav.focus.zone = "SYS_GAMEMENU"
                            Nav.focus.gameMenuIdx = 1
                        end
                    elseif Nav.focus.zone == "SYS_GAMEMENU" and nextId == "ADDON_CFG" then
                        Nav.focus.zone = "SYS_ADDONCFG"
                        Nav.focus.addonCfgIdx = 1
                    elseif Nav.focus.zone == "SYS_ADDONCFG" and nextId == "GAME_MENU" then
                        Nav.focus.zone = "SYS_GAMEMENU"
                        Nav.focus.gameMenuIdx = 1
                    end
                end
                Nav_EnsureFocus()
                Nav_ApplyFocus()
                return true
            end
        end
    end
    -- RT em TALENTS: cicla especialização ou árvore e fecha modal se aberto
    if Nav_GetCurrentTab() == "TALENTS" then
        local MM = Nav_GetMM()
        if MM and MM.tabContainer and MM.tabContainer.pages then
            local pageTalents = MM.tabContainer.pages["TALENTS"]
            if pageTalents then
                if MM.IsTalentInspectModalOpen and MM:IsTalentInspectModalOpen() then
                    if type(MM.HideTalentInspectModal) == "function" then
                        MM:HideTalentInspectModal()
                    end
                end
                local activeScreen = pageTalents.activeScreen or 1
                local curIdx = pageTalents.focusedSpecIdx or (Nav.focus and Nav.focus.talentSpec) or 1
                local nextIdx = curIdx + 1
                if nextIdx > 3 then nextIdx = 1 end

                if activeScreen == 2 then
                    if type(MM.ShowTalentTreeScreen) == "function" then
                        MM:ShowTalentTreeScreen(nextIdx)
                    end
                    if Nav.focus then
                        Nav.focus.talentSpec = nextIdx
                        Nav.focus.zone = "TALENTS2"
                        local fv = Nav_GetTalentFirstVisible()
                        if fv then
                            Nav.focus.talentSlot = fv
                            if type(MM.FocusTalentSlot) == "function" then
                                pcall(function() MM:FocusTalentSlot(fv) end)
                            end
                        end
                    end
                else
                    if Nav.focus then
                        Nav.focus.talentSpec = nextIdx
                        Nav.focus.zone = "TALENTS1"
                    end
                    if type(MM.FocusTalentSpecButton) == "function" then
                        pcall(function() MM:FocusTalentSpecButton(nextIdx, true) end)
                    end
                end
                Nav_EnsureFocus()
                Nav_ApplyFocus()
                PlaySound("igMainMenuOptionCheckBoxOn")
                return true
            end
        end
    end
    -- MMNav_Log("|cffe09a15[MMNav]|r RT (fase2: cursor ainda trata)") -- NOLOG 2026-09-14
    return false
end

function Nav:OnPrevSubTab()
    local ps = Nav_GetBindsState()
    local sub = ps and ps.activeSubScreen
    local inBindsOrPicker = (Nav.focus and (Nav.focus.zone == "SYS_BINDS" or Nav.focus.zone == "SYS_PICKER")) or (sub == "BINDS" or sub == "PICKER")
    if inBindsOrPicker then
        if sub == "PICKER" then
            return true
        end
        if sub == "BINDS" then
            local MM = Nav_GetMM()
            if MM and type(MM.SelectBindsPage) == "function" then
                local cur = (ps and ps.bindsScreen and ps.bindsScreen.currentPage) or (Nav.focus and Nav.focus.bindsPage) or 1
                local prv = cur - 1
                if prv < 1 then prv = 4 end
                pcall(function() MM:SelectBindsPage(prv) end)
                if Nav.focus then Nav.focus.bindsPage = prv end
                if Nav.focus and MM and type(MM.FocusBindsSlot) == "function" and ps and ps.bindsScreen and ps.bindsScreen.bindCards then
                    local bi = Nav.focus.bindsIdx or 1
                    if bi < 1 then bi = 1 end
                    if bi > 8 then bi = 8 end
                    Nav.focus.bindsIdx = bi
                    local card = ps.bindsScreen.bindCards[bi]
                    if card then pcall(function() MM:FocusBindsSlot(card) end) end
                end
                Nav_EnsureFocus()
                Nav_ApplyFocus()
            end
            return true
        end
        return true
    end
    -- DEMANDA 2: LT (prev) em SYSTEM sincroniza currentSubTab + sysSubTabIdx
    if Nav_GetCurrentTab() == "SYSTEM" and not (ps and ps.activeSubScreen) then
        local MM = Nav_GetMM()
        if MM and type(MM.SelectSystemSubTab) == "function" and MM.tabContainer and MM.tabContainer.pages then
            local pageSystem = MM.tabContainer.pages["SYSTEM"]
            if pageSystem then
                local curId = pageSystem.currentSubTab or "GAME_MENU"
                local subTabs = pageSystem.subTabs
                local total = 0
                if subTabs then total = table.getn(subTabs) end
                local curIdx = 1
                if total > 0 then
                    for i = 1, total do
                        local st = subTabs[i]
                        if st and st.id == curId then curIdx = i; break end
                    end
                    if type(curId) == "number" and curId >= 1 and curId <= total then curIdx = curId end
                else
                    if curId == "ADDON_CFG" then curIdx = 2 else curIdx = 1 end
                    total = 2
                    subTabs = { { id = "GAME_MENU" }, { id = "ADDON_CFG" } }
                end
                local prevIdx = curIdx - 1
                if prevIdx < 1 then prevIdx = total end
                local prevId = subTabs[prevIdx] and subTabs[prevIdx].id or "GAME_MENU"
                if Nav.focus then Nav.focus.sysSubTabIdx = prevIdx end
                pcall(function() MM:SelectSystemSubTab(prevId) end)
                if Nav.focus then
                    if Nav.focus.zone == "SYS_SUBTABS" then
                        if prevId == "ADDON_CFG" then
                            Nav.focus.zone = "SYS_ADDONCFG"
                            Nav.focus.addonCfgIdx = 1
                        else
                            Nav.focus.zone = "SYS_GAMEMENU"
                            Nav.focus.gameMenuIdx = 1
                        end
                    elseif Nav.focus.zone == "SYS_GAMEMENU" and prevId == "ADDON_CFG" then
                        Nav.focus.zone = "SYS_ADDONCFG"
                        Nav.focus.addonCfgIdx = 1
                    elseif Nav.focus.zone == "SYS_ADDONCFG" and prevId == "GAME_MENU" then
                        Nav.focus.zone = "SYS_GAMEMENU"
                        Nav.focus.gameMenuIdx = 1
                    end
                end
                Nav_EnsureFocus()
                Nav_ApplyFocus()
                return true
            end
        end
    end
    -- LT em TALENTS: cicla especialização ou árvore (reverso) e fecha modal se aberto
    if Nav_GetCurrentTab() == "TALENTS" then
        local MM = Nav_GetMM()
        if MM and MM.tabContainer and MM.tabContainer.pages then
            local pageTalents = MM.tabContainer.pages["TALENTS"]
            if pageTalents then
                if MM.IsTalentInspectModalOpen and MM:IsTalentInspectModalOpen() then
                    if type(MM.HideTalentInspectModal) == "function" then
                        MM:HideTalentInspectModal()
                    end
                end
                local activeScreen = pageTalents.activeScreen or 1
                local curIdx = pageTalents.focusedSpecIdx or (Nav.focus and Nav.focus.talentSpec) or 1
                local prevIdx = curIdx - 1
                if prevIdx < 1 then prevIdx = 3 end

                if activeScreen == 2 then
                    if type(MM.ShowTalentTreeScreen) == "function" then
                        MM:ShowTalentTreeScreen(prevIdx)
                    end
                    if Nav.focus then
                        Nav.focus.talentSpec = prevIdx
                        Nav.focus.zone = "TALENTS2"
                        local fv = Nav_GetTalentFirstVisible()
                        if fv then
                            Nav.focus.talentSlot = fv
                            if type(MM.FocusTalentSlot) == "function" then
                                pcall(function() MM:FocusTalentSlot(fv) end)
                            end
                        end
                    end
                else
                    if Nav.focus then
                        Nav.focus.talentSpec = prevIdx
                        Nav.focus.zone = "TALENTS1"
                    end
                    if type(MM.FocusTalentSpecButton) == "function" then
                        pcall(function() MM:FocusTalentSpecButton(prevIdx, true) end)
                    end
                end
                Nav_EnsureFocus()
                Nav_ApplyFocus()
                PlaySound("igMainMenuOptionCheckBoxOn")
                return true
            end
        end
    end
    -- MMNav_Log("|cffe09a15[MMNav]|r LT (fase2: cursor ainda trata)") -- NOLOG 2026-09-14
    return false
end

function Nav:OnSmartTab()
    -- MMNav_Log("|cffe09a15[MMNav]|r TAB (fase2: cursor ainda trata)") -- NOLOG 2026-09-14
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
    self.focus = self.focus or { zone = "GRID", tabIdx = 1, equipIndex = 1, catIndex = nil, gridIndex = 1, buffPos = 1, pageBtn = 1, returnZone = "GRID", spellCat = nil, spellSlot = nil, spellTab = nil, talentSpec = nil, talentSlot = nil, spellPageBtn = 1, questIdx = nil, qDetail = false, bindsPage = 1, bindsIdx = 1, pickerMode = 1, pickerSubIdx = 1, pickerGridIdx = 1, pickerPage = 1, pickerSection = "MODE", pickerPageBtn = 1 }
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
    if self.focus.bindsPage == nil or self.focus.bindsPage < 1 then self.focus.bindsPage = 1 end
    if self.focus.bindsPage > 5 then self.focus.bindsPage = 5 end
    if self.focus.bindsIdx == nil or self.focus.bindsIdx < 1 then self.focus.bindsIdx = 1 end
    if self.focus.bindsIdx > 8 then self.focus.bindsIdx = 8 end
    if self.focus.pickerMode == nil or self.focus.pickerMode < 1 then self.focus.pickerMode = 1 end
    if self.focus.pickerMode > 4 then self.focus.pickerMode = 4 end
    if self.focus.pickerSubIdx == nil or self.focus.pickerSubIdx < 1 then self.focus.pickerSubIdx = 1 end
    if self.focus.pickerGridIdx == nil or self.focus.pickerGridIdx < 1 then self.focus.pickerGridIdx = 1 end
    if self.focus.pickerGridIdx > 16 then self.focus.pickerGridIdx = 16 end
    if self.focus.pickerPage == nil or self.focus.pickerPage < 1 then self.focus.pickerPage = 1 end
    if self.focus.pickerSection ~= "MODE" and self.focus.pickerSection ~= "SUB" and self.focus.pickerSection ~= "GRID" and self.focus.pickerSection ~= "PAGE" then self.focus.pickerSection = "MODE" end
    if self.focus.pickerPageBtn == nil or self.focus.pickerPageBtn < 1 then self.focus.pickerPageBtn = 1 end
    if self.focus.pickerPageBtn > 2 then self.focus.pickerPageBtn = 2 end
end
