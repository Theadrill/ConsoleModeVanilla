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
-- 1. CONFIGURAÇÕES GLOBAIS DE PRIORIDADE (FÁCIL CUSTOMIZAÇÃO)
-- Menor valor numérico = Maior prioridade (aparece primeiro no Grid)
-- ============================================================================

-- Prioridade por Categoria identificada pelo ConsoleMode
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
-- 3. FUNÇÃO COMPARADORA ESTRITA (Lua 5.0)
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

    -- Classifica a categoria e sub-prioridade
    local aCat, aSubPrio = ClassifyItemType(a)
    local bCat, bSubPrio = ClassifyItemType(b)

    -- Prioridade principal de Categoria
    local aCatPrio = CONSOLEMODE_SORT_CATEGORY_PRIORITY[aCat] or 50
    local bCatPrio = CONSOLEMODE_SORT_CATEGORY_PRIORITY[bCat] or 50
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
    local aName = a.name or ""
    local bName = b.name or ""
    if aName ~= bName then
        return aName < bName
    end

    -- Quantidade / Stacks (maior quantidade primeiro)
    local aCount = tonumber(a.count) or 1
    local bCount = tonumber(b.count) or 1
    if aCount ~= bCount then
        return aCount > bCount
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
-- 4. INTERFACE PÚBLICA
-- ============================================================================
ConsoleMode = ConsoleMode or {}

--- Ordena virtualmente a lista de itens escaneados do inventário.
-- @param items (table) Lista de itemData retornada por MainMenu:ScanInventory
-- @param currentCategory (string) Categoria ativa ("ALL", "EQUIP", etc.)
-- @return (table) A lista de itens ordenada
function ConsoleMode:SortInventoryItems(items, currentCategory)
    if not items or table.getn(items) <= 1 then
        return items
    end

    -- Copia superficial para segurança da referência
    local sorted = {}
    local num = table.getn(items)
    for i = 1, num do
        sorted[i] = items[i]
    end

    table.sort(sorted, InventorySortComparator)
    return sorted
end
