--[[
    ConsoleMode - Vanilla
    UI/BagPicker.lua

    Módulo auxiliar: leitura das bags do player, filtro de itens usáveis
    e aplicação do binding item→slot→tecla.

    A UI é gerida pelo ActionBarPicker (modo "BAG") para evitar sobreposição
    de frames. Este arquivo só expõe lógica.

    Compatível com Lua 5.0 / WoW 1.12
]]

local CM = ConsoleMode
CM.config = CM.config or {}
CM.config.bagPicker = CM.config.bagPicker or {}
local BP = CM.config.bagPicker

-- IDs das bags: 0 = mochila principal, 1-4 = bags equipadas
BP.BAG_IDS = { 0, 1, 2, 3, 4 }

-- Scanner tooltip invisível para ler texto de itens
local scanTooltip = CreateFrame("GameTooltip", "ConsoleModeBagScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Tipos de item que fazem sentido bindar (strings localizadas EN/PT)
BP.USABLE_TYPES = {
    ["consumable"]      = true,
    ["consumables"]     = true,
    ["consumível"]      = true,
    ["consumíveis"]     = true,
    ["quest"]           = true,
    ["missão"]          = true,
    ["key"]             = true,
    ["chave"]           = true,
    ["miscellaneous"]   = true,
    ["diversos"]        = true,
}

-- Sub-tipos de Consumable ou Miscellaneous que são usáveis
BP.USABLE_SUBTYPES = {
    ["food & drink"]      = true,
    ["food and drink"]    = true,
    ["comida e bebida"]   = true,
    ["potion"]            = true,
    ["poção"]             = true,
    ["potions"]           = true,
    ["poções"]            = true,
    ["elixir"]            = true,
    ["flask"]             = true,
    ["frasco"]            = true,
    ["bandage"]           = true,
    ["bandagem"]          = true,
    ["scroll"]            = true,
    ["pergaminho"]        = true,
    ["item enhancement"]  = true,
    ["explosives"]        = true,
    ["explosivos"]        = true,
    ["poison"]            = true,
    ["veneno"]            = true,
    ["consumable"]        = true,
    ["other"]             = true,
    ["outro"]             = true,
    ["outros"]            = true,
    ["junk"]              = true,
    ["lixo"]              = true,
    ["companion pets"]    = true,
    ["mascotes"]          = true,
    ["mounts"]            = true,
    ["montarias"]         = true,
    ["holiday"]           = true,
}

-- Itens excluídos de aparecer no bind
BP.EXCLUDED_SUBTYPES = {
    ["arrow"]             = true,
    ["flecha"]            = true,
    ["bullet"]            = true,
    ["projétil"]          = true,
    ["projectile"]        = true,
    ["soul shard"]        = true,
}

-- ============================================================================
-- LEITURA DAS BAGS
-- ============================================================================

-- Verifica via tooltip se o item possui efeito "Use:", "Equip:" ou similar
function BP:HasUseEffectInTooltip(bagID, slotID)
    if not bagID or not slotID then return false end

    scanTooltip:ClearLines()
    local ok = pcall(function()
        scanTooltip:SetBagItem(bagID, slotID)
    end)
    if not ok then return false end

    local numLines = scanTooltip:NumLines()
    if not numLines or numLines <= 0 then return false end

    for i = 1, numLines do
        local leftTextObj = getglobal("ConsoleModeBagScanTooltipTextLeft" .. i)
        local text = leftTextObj and leftTextObj:GetText()
        if text and text ~= "" then
            local textLower = string.lower(text)
            -- Efeitos de uso comuns
            if string.find(textLower, "^use:") or string.find(textLower, "^uso:")
               or string.find(textLower, "^equip:") or string.find(textLower, "^equipar:")
               or string.find(textLower, "right click to") or string.find(textLower, "botão direito")
               or string.find(textLower, "cooldown") or string.find(textLower, "recarga")
               or string.find(textLower, "restores") or string.find(textLower, "restaura")
               or string.find(textLower, "increases") or string.find(textLower, "aumenta")
               or string.find(textLower, "teaches") or string.find(textLower, "ensina") then
                return true
            end
        end
    end

    return false
end

-- Verifica se um item (pelo seu itemLink) é usável e deve aparecer na lista.
-- Retorna true/false.
function BP:IsUsableItem(itemLink, bagID, slotID, readable)
    if not itemLink then return false end

    -- 1. Identifica o ID do item
    local _, _, itemIDStr = string.find(itemLink, "item:(%d+)")
    local itemID = tonumber(itemIDStr)

    -- Hearthstone (Pedra de Regresso) é sempre usável (itemID 6948)
    if itemID == 6948 then return true end

    -- Fragmento de Alma (Soul Shard) não deve ser bindado diretamente (itemID 6265)
    if itemID == 6265 then return false end

    -- 2. Leitura via GetItemInfo
    -- Assinatura oficial WoW 1.12:
    -- itemName, itemLink, itemQuality, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
    local itemName, _, itemQuality, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc = GetItemInfo(itemID or itemLink)

    local typeLower = string.lower(itemType or "")
    local subLower  = string.lower(itemSubType or "")

    -- Se for projétil/flecha/bala, ignora
    if typeLower == "projectile" or self.EXCLUDED_SUBTYPES[subLower] then
        return false
    end

    -- Se for consumível por tipo principal
    if typeLower == "consumable" or typeLower == "consumables" or typeLower == "consumível" or typeLower == "consumíveis" then
        return true
    end

    -- Se o subtipo for explicitamente de consumível/utilitário
    if self.USABLE_SUBTYPES[subLower] then
        -- Se for Junk ou Other, confirma se tem efeito de uso no tooltip
        if subLower == "junk" or subLower == "lixo" or subLower == "other" or subLower == "outro" or subLower == "outros" then
            if self:HasUseEffectInTooltip(bagID, slotID) then
                return true
            end
            if readable then return true end
            return false
        end
        return true
    end

    -- Se for equipável (armas, armaduras, berloques/trinkets, ferramentas)
    if itemEquipLoc and itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_NON_EQUIP" then
        return true
    end

    -- Se for item de Quest ou Chave
    if typeLower == "quest" or typeLower == "missão" or typeLower == "key" or typeLower == "chave" then
        if self:HasUseEffectInTooltip(bagID, slotID) or readable then
            return true
        end
    end

    -- 3. Verificação definitiva via Tooltip (para itens customizados de servidor privado, etc.)
    if self:HasUseEffectInTooltip(bagID, slotID) then
        return true
    end

    if readable then
        return true
    end

    return false
end

-- Varre todas as bags e retorna lista de itens usáveis:
-- { name, icon, count, quality, bagID, slotID, itemLink }
function BP:GetUsableItems()
    local items = {}

    for _, bagID in ipairs(self.BAG_IDS) do
        local numSlots = GetContainerNumSlots(bagID)
        if numSlots and numSlots > 0 then
            for slotID = 1, numSlots do
                local texture, count, locked, quality, readable =
                    GetContainerItemInfo(bagID, slotID)

                if texture then
                    local itemLink = GetContainerItemLink(bagID, slotID)
                    if itemLink and self:IsUsableItem(itemLink, bagID, slotID, readable) then
                        -- Extrai o nome do itemLink ou de GetItemInfo
                        local name = nil
                        local ok, n = pcall(function()
                            local nm = GetItemInfo(itemLink)
                            return nm
                        end)
                        if ok and n then name = n end
                        if not name or name == "" then
                            -- Fallback: extrai o nome do itemLink
                            -- formato: |cffXXXXXX|Hitem:ID:...|h[Nome]|h|r
                            local _, _, extracted = string.find(itemLink, "%[(.-)%]")
                            name = extracted or "Item"
                        end

                        tinsert(items, {
                            name     = name,
                            icon     = texture,
                            count    = count or 1,
                            quality  = quality or 0,
                            bagID    = bagID,
                            slotID   = slotID,
                            itemLink = itemLink,
                        })
                    end
                end
            end
        end
    end

    return items
end

-- ============================================================================
-- APLICAR BINDING
-- ============================================================================

function BP:ApplyItemBinding(page, btnKey, comboName, item)
    -- Reutiliza o SBP para resolução de slot (mesma lógica)
    local SBP = CM.config and CM.config.spellbookPicker
    if not SBP then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro interno: SBP nao encontrado!")
        return false
    end

    local physKey = SBP.KEY_MAPPINGS[page] and SBP.KEY_MAPPINGS[page][btnKey]
    if not physKey then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro: tecla fisica nao encontrada!")
        return false
    end

    local slot, bindingAction = SBP:ResolveTargetSlot(page, btnKey)
    if not slot then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Sem slot disponivel! Libere um slot nas barras de acao.")
        return false
    end

    -- Pega o item da bag e coloca no slot da action bar
    local ok = pcall(function()
        PickupContainerItem(item.bagID, item.slotID)
        PlaceAction(slot)
        ClearCursor()
    end)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ConsoleMode]|r Erro ao colocar item no slot " .. slot .. "!")
        ClearCursor()
        return false
    end

    -- Aplica binding
    local KB = CM.keybindings
    if KB and KB.navigationMode and KB.savedNavBindings then
        for k, act in pairs(KB.savedNavBindings) do
            if act and act ~= "" and not string.find(act, "^CM_CURSOR_") then
                SetBinding(k, act)
            elseif k == "TAB" then
                SetBinding("TAB", "TARGETNEARESTENEMY")
            end
        end
    end

    SetBinding(physKey, bindingAction)

    if KB and KB.savedNavBindings then
        KB.savedNavBindings[physKey] = bindingAction
    end

    local set = GetCurrentBindingSet()
    if not set or set == 0 then set = 1 end
    pcall(function() SaveBindings(set) end)

    if KB and KB.navigationMode and KB.defaults and KB.defaults[1] then
        local d1 = KB.defaults[1]
        SetBinding(d1.DUP,    "CM_CURSOR_UP")
        SetBinding(d1.DDOWN,  "CM_CURSOR_DOWN")
        SetBinding(d1.DLEFT,  "CM_CURSOR_LEFT")
        SetBinding(d1.DRIGHT, "CM_CURSOR_RIGHT")
        SetBinding(d1.A,      "CM_CURSOR_CONFIRM")
        SetBinding(d1.B,      "CM_CURSOR_CANCEL")
    end

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ff00[ConsoleMode]|r |cffffcc00" .. comboName
        .. "|r vinculado a |cff88ccff" .. item.name
        .. "|r (slot " .. slot .. ")!"
    )
    PlaySound("igMainMenuOptionCheckBoxOn")

    if CM.ui and CM.ui.actionHUD and CM.ui.actionHUD.Update then
        CM.ui.actionHUD:Update()
    end

    return true
end
