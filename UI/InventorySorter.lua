--[[
================================================================================
ConsoleModeVanilla - UI/InventorySorter.lua
Módulo de Ordenação Virtual de Inventário (Presentation Layer)
Compatível estritamente com WoW 1.12.1 (Interface 11200) / Lua 5.0
================================================================================
Este módulo organiza virtualmente os itens exibidos no Grid do Main Menu sem
alterar a posição física real dos itens nas bolsas do jogador.
]]--

-- ============================================================================
-- 1. CONFIGURAÇÕES GLOBAIS DE PRIORIDADE & PRESETS
-- Menor valor numérico = Maior prioridade (aparece primeiro no Grid)
-- ============================================================================

-- Prioridade por Categoria identificada pelo ConsoleMode (Padrão Balanceado)
CONSOLEMODE_SORT_CATEGORY_PRIORITY = {
    QUEST       = 1,   -- Itens de Missão
    EQUIP       = 2,   -- Equipamentos (Armaduras, Armas, Acessórios)
    POTION      = 3,   -- Poções (Vida, Mana, etc.)
    FOOD        = 4,   -- Comidas e Bebidas
    USABLE      = 5,   -- Outros consumíveis / usáveis (Bandagens, Elixires, Scrolls)
    TRADE       = 6,   -- Reagentes de Profissão / Trade Goods
    MISC        = 7,   -- Diversos / Utilitários (Hearthstone, Chaves, etc.)
    JUNK        = 8,   -- Lixo (Cinzas / Grey)
    EMPTY       = 99,  -- Slots Vazios (SEMPRE POR ÚLTIMO)
}

-- Presets de Categoria selecionáveis pelo usuário
CONSOLEMODE_SORT_PRESETS = {
    BALANCED = CONSOLEMODE_SORT_CATEGORY_PRIORITY,
    EQUIP = {
        EQUIP  = 1,
        POTION = 2,
        FOOD   = 3,
        USABLE = 4,
        QUEST  = 5,
        TRADE  = 6,
        MISC   = 7,
        JUNK   = 8,
        EMPTY  = 99,
    },
    CONSUMABLE = {
        POTION = 1,
        FOOD   = 2,
        USABLE = 3,
        EQUIP  = 4,
        QUEST  = 5,
        TRADE  = 6,
        MISC   = 7,
        JUNK   = 8,
        EMPTY  = 99,
    },
    TRADE = {
        TRADE  = 1,
        QUEST  = 2,
        EQUIP  = 3,
        POTION = 4,
        FOOD   = 5,
        USABLE = 6,
        MISC   = 7,
        JUNK   = 8,
        EMPTY  = 99,
    },
}

-- Sub-prioridade interna para itens consumíveis / usáveis
CONSOLEMODE_SORT_USABLE_SUBPRIORITY = {
    POTION_HEALTH = 1,
    POTION_MANA   = 2,
    POTION_OTHER  = 3,
    ELIXIR        = 4,
    FLASK         = 5,
    BANDAGE       = 6,
    FOOD          = 7,
    DRINK         = 8,
    SCROLL        = 9,
    OTHER_USABLE  = 10,
}

-- Prioridade de Equipamentos por Slot de Equipar (itemEquipLoc)
CONSOLEMODE_SORT_EQUIPLOC_PRIORITY = {
    INVTYPE_HEAD           = 1,
    INVTYPE_NECK           = 2,
    INVTYPE_SHOULDER       = 3,
    INVTYPE_CHEST          = 4,
    INVTYPE_ROBE           = 4,
    INVTYPE_WAIST          = 5,
    INVTYPE_LEGS           = 6,
    INVTYPE_FEET           = 7,
    INVTYPE_WRIST          = 8,
    INVTYPE_HAND           = 9,
    INVTYPE_FINGER         = 10,
    INVTYPE_TRINKET        = 11,
    INVTYPE_CLOAK          = 12,
    INVTYPE_2HWEAPON       = 13,
    INVTYPE_WEAPONMAINHAND = 14,
    INVTYPE_WEAPON         = 15,
    INVTYPE_WEAPONOFFHAND  = 16,
    INVTYPE_HOLDABLE       = 17,
    INVTYPE_SHIELD         = 18,
    INVTYPE_RANGED         = 19,
    INVTYPE_RANGEDRIGHT    = 20,
    INVTYPE_RELIC          = 21,
    INVTYPE_TABARD         = 22,
    INVTYPE_BAG            = 23,
}

-- Peso por Qualidade / Raridade do item (WoW: 0=Pobre até 5=Lendário)
CONSOLEMODE_SORT_QUALITY_WEIGHT = {
    [5] = 1, -- Lendário (laranja)
    [4] = 2, -- Épico (roxo)
    [3] = 3, -- Raro (azul)
    [2] = 4, -- Incomum (verde)
    [1] = 5, -- Comum (branco)
    [0] = 6, -- Pobre / Lixo (cinza)
}

-- Configurações padrão do Virtual Sort
CONSOLEMODE_DEFAULT_SORT_CONFIG = {
    enabled     = true,
    mode        = "CATEGORY",   -- "CATEGORY", "QUALITY", "NAME", "LEVEL"
    preset      = "BALANCED",   -- "BALANCED", "EQUIP", "CONSUMABLE", "TRADE"
    questOnTop  = true,
    groupByName = true,
}

local activeSortConfig = nil

-- ============================================================================
-- 2. CLASSIFICADOR AVANÇADO DE CONSUMÍVEIS (POTION vs FOOD vs BANDAGE)
-- ============================================================================
local function ClassifyItemType(item)
    if not item or item.isEmpty then
        return "EMPTY", 99
    end

    -- Itens Cinzas = JUNK
    if item.quality == 0 then
        return "JUNK", 1
    end

    local cat = item.category or "MISC"
    local rawName = item.name or ""
    local name = string.lower(rawName)
    local subType = string.lower(item.subType or "")
    local desc = string.lower(item.desc or "")

    -- Hearthstone tem destaque especial em MISC
    if string.find(name, "hearthstone") or string.find(name, "pedra de regresso") then
        return "MISC", 0
    end

    -- Quest items
    if cat == "QUEST" or string.find(subType, "quest") or string.find(subType, "miss") then
        return "QUEST", 1
    end

    -- Equipamentos
    if cat == "EQUIP" or (item.equipLoc and item.equipLoc ~= "") then
        return "EQUIP", 1
    end

    -- Distinção de Consumíveis (Potions vs Food vs Bandages)
    if cat == "USABLE" or item.itemType == "Consumable" or item.itemType == "Consumível" then
        -- Poções de Vida
        if string.find(name, "healing potion") or string.find(name, "poção de cura") or string.find(name, "pocao de cura")
           or string.find(desc, "restores %d+ to %d+ health") or string.find(desc, "restaura %d+ a %d+ de vida") then
            return "POTION", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.POTION_HEALTH
        end

        -- Poções de Mana
        if string.find(name, "mana potion") or string.find(name, "poção de mana") or string.find(name, "pocao de mana")
           or string.find(desc, "restores %d+ to %d+ mana") or string.find(desc, "restaura %d+ a %d+ de mana") then
            return "POTION", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.POTION_MANA
        end

        -- Outras Poções / Poções em geral
        if string.find(name, "potion") or string.find(name, "poção") or string.find(name, "pocao")
           or string.find(subType, "potion") or string.find(subType, "poção") then
            return "POTION", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.POTION_OTHER
        end

        -- Elixires e Frascos
        if string.find(name, "elixir") or string.find(subType, "elixir") then
            return "USABLE", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.ELIXIR
        end
        if string.find(name, "flask") or string.find(subType, "flask") or string.find(name, "frasco") then
            return "USABLE", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.FLASK
        end

        -- Bandagens
        if string.find(name, "bandage") or string.find(name, "bandagem") or string.find(subType, "bandage") then
            return "USABLE", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.BANDAGE
        end

        -- Comidas (Food)
        if string.find(subType, "food") or string.find(subType, "comida")
           or string.find(desc, "must remain seated while eating") or string.find(desc, "comer")
           or string.find(name, "meat") or string.find(name, "bread") or string.find(name, "carne") or string.find(name, "pão") then
            return "FOOD", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.FOOD
        end

        -- Bebidas (Drink)
        if string.find(subType, "drink") or string.find(subType, "bebida")
           or string.find(desc, "must remain seated while drinking") or string.find(desc, "beber")
           or string.find(name, "water") or string.find(name, "milk") or string.find(name, "água") or string.find(name, "leite") then
            return "FOOD", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.DRINK
        end

        -- Pergaminhos (Scrolls)
        if string.find(name, "scroll") or string.find(name, "pergaminho") then
            return "USABLE", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.SCROLL
        end

        return "USABLE", CONSOLEMODE_SORT_USABLE_SUBPRIORITY.OTHER_USABLE
    end

    if cat == "TRADE" then
        return "TRADE", 1
    end

    return cat, 1
end

-- ============================================================================
-- 3. FUNÇÃO COMPARADORA ESTRITA DINÂMICA (Lua 5.0)
-- Retorna true estritamente se 'a' deve vir antes de 'b'.
-- ============================================================================
local function InventorySortComparator(a, b)
    if not a then return false end
    if not b then return true end

    -- REGRA MESTRA: Itens ocupados SEMPRE vêm antes de qualquer slot vazio!
    local aEmpty = a.isEmpty and true or false
    local bEmpty = b.isEmpty and true or false
    if aEmpty ~= bEmpty then
        return not aEmpty -- Se a tem item e b é vazio, a vem antes (true)
    end

    -- Se ambos forem slots vazios:
    if aEmpty and bEmpty then
        -- Bolsas normais vazias vêm antes de bolsas especiais vazias
        local aSpecial = (a.bagKind and a.bagKind ~= "NORMAL") and true or false
        local bSpecial = (b.bagKind and b.bagKind ~= "NORMAL") and true or false
        if aSpecial ~= bSpecial then
            return not aSpecial
        end
        local aBag = a.bagID or a.bag or 0
        local bBag = b.bagID or b.bag or 0
        if aBag ~= bBag then
            return aBag < bBag
        end
        local aSlot = a.slotID or a.slot or 0
        local bSlot = b.slotID or b.slot or 0
        return aSlot < bSlot
    end

    -- DAQUI PARA BAIXO: AMBOS SÃO ITENS OCUPADOS (NUNCA VAZIOS)

    -- Bolsas normais vs Bolsas especiais (ex: munição em aljavas vai pro fim dos itens)
    local aSpecial = (a.bagKind and a.bagKind ~= "NORMAL") and true or false
    local bSpecial = (b.bagKind and b.bagKind ~= "NORMAL") and true or false
    if aSpecial ~= bSpecial then
        return not aSpecial
    end

    local cfg = activeSortConfig or CONSOLEMODE_DEFAULT_SORT_CONFIG

    -- Classifica a categoria e sub-prioridade
    local aCat, aSubPrio = ClassifyItemType(a)
    local bCat, bSubPrio = ClassifyItemType(b)

    -- Itens de Missão no Topo (se ativado)
    if cfg.questOnTop then
        local aQuest = (aCat == "QUEST")
        local bQuest = (bCat == "QUEST")
        if aQuest ~= bQuest then
            return aQuest
        end
    end

    local sortMode = cfg.mode or "CATEGORY"
    local presetTable = CONSOLEMODE_SORT_PRESETS[cfg.preset] or CONSOLEMODE_SORT_CATEGORY_PRIORITY

    -- 3.1. MODO: CATEGORIA (Padrão)
    if sortMode == "CATEGORY" then
        local aCatPrio = presetTable[aCat] or 50
        local bCatPrio = presetTable[bCat] or 50
        if aCatPrio ~= bCatPrio then
            return aCatPrio < bCatPrio
        end

        -- Sub-prioridade dentro da categoria (ex: Potion Health < Potion Mana < Food < Drink)
        if aSubPrio ~= bSubPrio then
            return aSubPrio < bSubPrio
        end

        -- Se ambos forem EQUIP: desempate por slot de equipar e nível
        if aCat == "EQUIP" and bCat == "EQUIP" then
            local aEquipPrio = CONSOLEMODE_SORT_EQUIPLOC_PRIORITY[a.equipLoc or ""] or 50
            local bEquipPrio = CONSOLEMODE_SORT_EQUIPLOC_PRIORITY[b.equipLoc or ""] or 50
            if aEquipPrio ~= bEquipPrio then
                return aEquipPrio < bEquipPrio
            end

            local aReq = tonumber(a.reqLevel) or 0
            local bReq = tonumber(b.reqLevel) or 0
            if aReq ~= bReq then
                return aReq > bReq -- Nível maior primeiro
            end
        end

        -- Qualidade / Raridade (maior qualidade primeiro)
        local aQual = tonumber(a.quality) or 1
        local bQual = tonumber(b.quality) or 1
        local aQualWeight = CONSOLEMODE_SORT_QUALITY_WEIGHT[aQual] or 50
        local bQualWeight = CONSOLEMODE_SORT_QUALITY_WEIGHT[bQual] or 50
        if aQualWeight ~= bQualWeight then
            return aQualWeight < bQualWeight
        end

        -- Nome alfabético (agrupa itens idênticos)
        if cfg.groupByName then
            local aName = a.name or ""
            local bName = b.name or ""
            if aName ~= bName then
                return aName < bName
            end
        end

        -- Quantidade / Stacks (maior quantidade primeiro)
        local aCount = tonumber(a.count) or 1
        local bCount = tonumber(b.count) or 1
        if aCount ~= bCount then
            return aCount > bCount
        end

    -- 3.2. MODO: QUALIDADE / RARIDADE
    elseif sortMode == "QUALITY" then
        local aQual = tonumber(a.quality) or 1
        local bQual = tonumber(b.quality) or 1
        local aQualWeight = CONSOLEMODE_SORT_QUALITY_WEIGHT[aQual] or 50
        local bQualWeight = CONSOLEMODE_SORT_QUALITY_WEIGHT[bQual] or 50
        if aQualWeight ~= bQualWeight then
            return aQualWeight < bQualWeight
        end

        local aCatPrio = presetTable[aCat] or 50
        local bCatPrio = presetTable[bCat] or 50
        if aCatPrio ~= bCatPrio then
            return aCatPrio < bCatPrio
        end

        if cfg.groupByName then
            local aName = a.name or ""
            local bName = b.name or ""
            if aName ~= bName then
                return aName < bName
            end
        end

        local aCount = tonumber(a.count) or 1
        local bCount = tonumber(b.count) or 1
        if aCount ~= bCount then
            return aCount > bCount
        end

    -- 3.3. MODO: NOME (A-Z)
    elseif sortMode == "NAME" then
        local aName = a.name or ""
        local bName = b.name or ""
        if aName ~= bName then
            return aName < bName
        end

        local aCount = tonumber(a.count) or 1
        local bCount = tonumber(b.count) or 1
        if aCount ~= bCount then
            return aCount > bCount
        end

        local aQual = tonumber(a.quality) or 1
        local bQual = tonumber(b.quality) or 1
        local aQualWeight = CONSOLEMODE_SORT_QUALITY_WEIGHT[aQual] or 50
        local bQualWeight = CONSOLEMODE_SORT_QUALITY_WEIGHT[bQual] or 50
        if aQualWeight ~= bQualWeight then
            return aQualWeight < bQualWeight
        end

    -- 3.4. MODO: NÍVEL DO ITEM
    elseif sortMode == "LEVEL" then
        local aReq = tonumber(a.reqLevel) or 0
        local bReq = tonumber(b.reqLevel) or 0
        if aReq ~= bReq then
            return aReq > bReq -- Nível maior primeiro
        end

        local aQual = tonumber(a.quality) or 1
        local bQual = tonumber(b.quality) or 1
        local aQualWeight = CONSOLEMODE_SORT_QUALITY_WEIGHT[aQual] or 50
        local bQualWeight = CONSOLEMODE_SORT_QUALITY_WEIGHT[bQual] or 50
        if aQualWeight ~= bQualWeight then
            return aQualWeight < bQualWeight
        end

        local aCatPrio = presetTable[aCat] or 50
        local bCatPrio = presetTable[bCat] or 50
        if aCatPrio ~= bCatPrio then
            return aCatPrio < bCatPrio
        end

        if cfg.groupByName then
            local aName = a.name or ""
            local bName = b.name or ""
            if aName ~= bName then
                return aName < bName
            end
        end

        local aCount = tonumber(a.count) or 1
        local bCount = tonumber(b.count) or 1
        if aCount ~= bCount then
            return aCount > bCount
        end
    end

    -- Critério final de estabilidade determinística (Bag e Slot original)
    local aBag = a.bagID or a.bag or 0
    local bBag = b.bagID or b.bag or 0
    if aBag ~= bBag then
        return aBag < bBag
    end
    local aSlot = a.slotID or a.slot or 0
    local bSlot = b.slotID or b.slot or 0
    return aSlot < bSlot
end

-- ============================================================================
-- 4. INTERFACE PÚBLICA & CONFIGURAÇÕES
-- ============================================================================
ConsoleMode = ConsoleMode or {}

--- Retorna a configuração ativa de ordenação com fallback para os padrões.
function ConsoleMode:GetVirtualSortConfig()
    if not ConsoleModeDB then ConsoleModeDB = {} end
    if not ConsoleModeDB.virtualSort then ConsoleModeDB.virtualSort = {} end
    local vs = ConsoleModeDB.virtualSort
    local cfg = {}

    if vs.enabled == nil then
        cfg.enabled = CONSOLEMODE_DEFAULT_SORT_CONFIG.enabled
    else
        cfg.enabled = (vs.enabled == true)
    end

    cfg.mode = vs.mode or CONSOLEMODE_DEFAULT_SORT_CONFIG.mode
    cfg.preset = vs.preset or CONSOLEMODE_DEFAULT_SORT_CONFIG.preset

    if vs.questOnTop == nil then
        cfg.questOnTop = CONSOLEMODE_DEFAULT_SORT_CONFIG.questOnTop
    else
        cfg.questOnTop = (vs.questOnTop == true)
    end

    if vs.groupByName == nil then
        cfg.groupByName = CONSOLEMODE_DEFAULT_SORT_CONFIG.groupByName
    else
        cfg.groupByName = (vs.groupByName == true)
    end

    return cfg
end

--- Salva um campo individual na configuração persistida.
function ConsoleMode:SetVirtualSortConfig(key, value)
    if not key then return end
    if not ConsoleModeDB then ConsoleModeDB = {} end
    if not ConsoleModeDB.virtualSort then ConsoleModeDB.virtualSort = {} end
    ConsoleModeDB.virtualSort[key] = value
end

--- Restaura as configurações de ordenação para os valores de fábrica.
function ConsoleMode:ResetVirtualSortConfig()
    if not ConsoleModeDB then ConsoleModeDB = {} end
    ConsoleModeDB.virtualSort = {
        enabled     = CONSOLEMODE_DEFAULT_SORT_CONFIG.enabled,
        mode        = CONSOLEMODE_DEFAULT_SORT_CONFIG.mode,
        preset      = CONSOLEMODE_DEFAULT_SORT_CONFIG.preset,
        questOnTop  = CONSOLEMODE_DEFAULT_SORT_CONFIG.questOnTop,
        groupByName = CONSOLEMODE_DEFAULT_SORT_CONFIG.groupByName,
    }
end

--- Ordena virtualmente a lista de itens escaneados do inventário.
-- @param items (table) Lista de itemData retornada por MainMenu:ScanInventory
-- @param currentCategory (string) Categoria ativa ("ALL", "EQUIP", etc.)
-- @return (table) A lista de itens ordenada
function ConsoleMode:SortInventoryItems(items, currentCategory)
    if not items or table.getn(items) <= 1 then
        return items
    end

    local cfg = self:GetVirtualSortConfig()

    -- Se a ordenação virtual estiver desativada pelo jogador:
    -- Mantém a ordem física real dos slots das bolsas (Bag 0..4, Slot 1..N)
    if not cfg.enabled then
        return items
    end

    -- Copia superficial para segurança da referência
    local sorted = {}
    local num = table.getn(items)
    for i = 1, num do
        sorted[i] = items[i]
    end

    activeSortConfig = cfg
    table.sort(sorted, InventorySortComparator)
    activeSortConfig = nil

    return sorted
end
