-- Gerado por tools/build_full_npc_db.py (FASE 4 - API)
-- NPC_Core.lua: API de consulta rapida no WoW (Lua 5.0, WoW 1.12.1).
-- NAO usar sintaxe Lua 5.1+ (sem #t, continue, goto, bitwise, table.unpack).
ConsoleMode = ConsoleMode or {}
ConsoleMode_NPC_Kalimdor = ConsoleMode_NPC_Kalimdor or {}
ConsoleMode_NPC_EasternKingdoms = ConsoleMode_NPC_EasternKingdoms or {}
ConsoleMode_NPC_CustomTurtle = ConsoleMode_NPC_CustomTurtle or {}
ConsoleMode_NPC_ptBR = ConsoleMode_NPC_ptBR or {}

-- Fallback transparente: retorna nome PT-BR se existir, senao o nome original.
function ConsoleMode:GetNPCDisplayName(npcID, rawName)
    if npcID ~= nil and ConsoleMode_NPC_ptBR ~= nil then
        local entry = ConsoleMode_NPC_ptBR[npcID]
        if entry ~= nil and entry.name ~= nil and entry.name ~= "" then
            return entry.name
        end
    end
    return rawName
end

function ConsoleMode:GetNPCRole(npcID, rawRole)
    if npcID ~= nil and ConsoleMode_NPC_ptBR ~= nil then
        local entry = ConsoleMode_NPC_ptBR[npcID]
        if entry ~= nil and entry.role ~= nil and entry.role ~= "" then
            return entry.role
        end
    end
    return rawRole
end

-- Retorna x, y (ou nil, nil) procurando nas 3 particoes.
function ConsoleMode:GetNPCCoords(npcID)
    if npcID == nil then
        return nil, nil
    end
    local t = ConsoleMode_NPC_Kalimdor[npcID]
    if t == nil then
        t = ConsoleMode_NPC_EasternKingdoms[npcID]
    end
    if t == nil then
        t = ConsoleMode_NPC_CustomTurtle[npcID]
    end
    if t ~= nil then
        return t[3], t[4]
    end
    return nil, nil
end

-- Retorna name, role, x, y de uma vez (name/role ja com fallback PT-BR).
function ConsoleMode:GetNPCInfo(npcID)
    if npcID == nil then
        return nil, nil, nil, nil
    end
    local t = ConsoleMode_NPC_Kalimdor[npcID]
    if t == nil then
        t = ConsoleMode_NPC_EasternKingdoms[npcID]
    end
    if t == nil then
        t = ConsoleMode_NPC_CustomTurtle[npcID]
    end
    if t == nil then
        return nil, nil, nil, nil
    end
    local name = self:GetNPCDisplayName(npcID, t[1])
    local role = self:GetNPCRole(npcID, t[2])
    return name, role, t[3], t[4]
end

-- Helper de registro/injecao (ex.: testes ou merges manuais).
-- dbName: "kalimdor", "eastern" ou "custom".
function ConsoleMode:SetNPCDB(dbName, npcID, npcName, npcRole, x, y)
    local db = nil
    if dbName == "kalimdor" then
        db = ConsoleMode_NPC_Kalimdor
    elseif dbName == "eastern" then
        db = ConsoleMode_NPC_EasternKingdoms
    else
        db = ConsoleMode_NPC_CustomTurtle
    end
    db[npcID] = { npcName, npcRole, x, y }
    return db[npcID]
end

-- Contagem simples Lua 5.0 (sem #t; usa table.getn apenas em lista array).
function ConsoleMode:GetNPCPartitionCount(dbName)
    local db = nil
    if dbName == "kalimdor" then
        db = ConsoleMode_NPC_Kalimdor
    elseif dbName == "eastern" then
        db = ConsoleMode_NPC_EasternKingdoms
    else
        db = ConsoleMode_NPC_CustomTurtle
    end
    local n = 0
    for k, v in db do
        n = n + 1
    end
    return n
end
