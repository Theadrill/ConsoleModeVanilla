--[[
    ConsoleMode - Vanilla
    Data/Instances.lua

    Banco curado de Instancias do WoW 1.12.1 (Vanilla) por mapa.
    Usado para separar a lista REGIOES (outdoor) da lista INSTANCIAS
    no modo CONTINENT do MainMenu. Lua 5.0 / WoW 1.12 compatível
    (sem # , sem ... variadico 5.1).

    Estrutura:
      byZone[zoneName] = { "Instance Name", ... }
      byContinent[cont] = { "Instance Name", ... }  -- cont 1=Kalimdor 2=Eastern Kingdoms
      details[instanceName] = { cont, zone, abbr, levels, players, type }
      isInstance[name] = true  -- lookup rapido para filtrar REGIOES
]]

local CM = ConsoleMode or {}
ConsoleMode = CM
CM.Instances = CM.Instances or {}

local byZone = {
    ["Durotar"] = { "Ragefire Chasm" },
    ["Barrens"] = { "Wailing Caverns", "Razorfen Kraul", "Razorfen Downs" },
    ["Ashenvale"] = { "Blackfathom Deeps" },
    ["Desolace"] = { "Maraudon" },
    ["Feralas"] = { "Dire Maul" },
    ["Tanaris"] = { "Zul'Farrak" },
    ["Silithus"] = { "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj" },
    ["Dustwallow Marsh"] = { "Onyxia's Lair" },
    ["Azshara"] = { },

    ["Westfall"] = { "The Deadmines" },
    ["Elwynn Forest"] = { "The Stockade" },
    ["Elwynn"] = { "The Stockade" },
    ["Dun Morogh"] = { "Gnomeregan" },
    ["Tirisfal Glades"] = { "Scarlet Monastery" },
    ["Tirisfal"] = { "Scarlet Monastery" },
    ["Silverpine Forest"] = { "Shadowfang Keep" },
    ["Silverpine"] = { "Shadowfang Keep" },
    ["Hillsbrad Foothills"] = { },
    ["Hillsbrad"] = { },
    ["Badlands"] = { "Uldaman" },
    ["Searing Gorge"] = { "Blackrock Depths" },
    ["Burning Steppes"] = { "Blackrock Spire", "Blackwing Lair" },
    ["Stranglethorn Vale"] = { "Zul'Gurub" },
    ["Stranglethorn"] = { "Zul'Gurub" },
    ["Swamp of Sorrows"] = { "The Temple of Atal'Hakkar" },
    ["Blasted Lands"] = { },
    ["Western Plaguelands"] = { "Scholomance" },
    ["Eastern Plaguelands"] = { "Stratholme" },
    ["Deadwind Pass"] = { },
    ["Stormwind City"] = { "The Stockade" },
    ["Ironforge"] = { "Gnomeregan" },

    ["Orgrimmar"] = { "Ragefire Chasm" },
    ["Undercity"] = { "Scarlet Monastery" },
}

local byContinent = {
    [1] = {
        "Wailing Caverns",
        "Razorfen Kraul",
        "Razorfen Downs",
        "Blackfathom Deeps",
        "Ragefire Chasm",
        "Maraudon",
        "Dire Maul",
        "Zul'Farrak",
        "Ruins of Ahn'Qiraj",
        "Temple of Ahn'Qiraj",
        "Onyxia's Lair",
    },
    [2] = {
        "The Deadmines",
        "The Stockade",
        "Gnomeregan",
        "Scarlet Monastery",
        "Shadowfang Keep",
        "Uldaman",
        "Blackrock Depths",
        "Blackrock Spire",
        "Blackwing Lair",
        "Zul'Gurub",
        "The Temple of Atal'Hakkar",
        "Scholomance",
        "Stratholme",
        "Molten Core",
    },
}

local details = {
    ["Ragefire Chasm"] = { cont = 1, zone = "Durotar", abbr = "RFC", levels = "13-18", players = "5", type = "Dungeon" },
    ["Wailing Caverns"] = { cont = 1, zone = "Barrens", abbr = "WC", levels = "17-24", players = "5", type = "Dungeon" },
    ["The Deadmines"] = { cont = 2, zone = "Westfall", abbr = "VC", levels = "17-26", players = "5", type = "Dungeon" },
    ["Shadowfang Keep"] = { cont = 2, zone = "Silverpine Forest", abbr = "SFK", levels = "22-30", players = "5", type = "Dungeon" },
    ["Blackfathom Deeps"] = { cont = 1, zone = "Ashenvale", abbr = "BFD", levels = "24-32", players = "5", type = "Dungeon" },
    ["The Stockade"] = { cont = 2, zone = "Stormwind City", abbr = "Stocks", levels = "24-32", players = "5", type = "Dungeon" },
    ["Gnomeregan"] = { cont = 2, zone = "Dun Morogh", abbr = "Gnomer", levels = "29-38", players = "5", type = "Dungeon" },
    ["Razorfen Kraul"] = { cont = 1, zone = "Barrens", abbr = "RFK", levels = "29-38", players = "5", type = "Dungeon" },
    ["Scarlet Monastery"] = { cont = 2, zone = "Tirisfal Glades", abbr = "SM", levels = "30-45", players = "5", type = "Dungeon" },
    ["Razorfen Downs"] = { cont = 1, zone = "Barrens", abbr = "RFD", levels = "37-46", players = "5", type = "Dungeon" },
    ["Uldaman"] = { cont = 2, zone = "Badlands", abbr = "Ulda", levels = "41-51", players = "5", type = "Dungeon" },
    ["Zul'Farrak"] = { cont = 1, zone = "Tanaris", abbr = "ZF", levels = "44-54", players = "5", type = "Dungeon" },
    ["Maraudon"] = { cont = 1, zone = "Desolace", abbr = "Mara", levels = "45-55", players = "5", type = "Dungeon" },
    ["The Temple of Atal'Hakkar"] = { cont = 2, zone = "Swamp of Sorrows", abbr = "ST", levels = "50-60", players = "5", type = "Dungeon" },
    ["Blackrock Depths"] = { cont = 2, zone = "Searing Gorge", abbr = "BRD", levels = "52-60", players = "5", type = "Dungeon" },
    ["Dire Maul"] = { cont = 1, zone = "Feralas", abbr = "DM", levels = "55-60", players = "5", type = "Dungeon" },
    ["Blackrock Spire"] = { cont = 2, zone = "Burning Steppes", abbr = "LBRS/UBRS", levels = "56-60", players = "10/15", type = "Dungeon" },
    ["Stratholme"] = { cont = 2, zone = "Eastern Plaguelands", abbr = "Strath", levels = "58-60", players = "5/10", type = "Dungeon" },
    ["Scholomance"] = { cont = 2, zone = "Western Plaguelands", abbr = "Scholo", levels = "58-60", players = "5/10", type = "Dungeon" },
    ["Zul'Gurub"] = { cont = 2, zone = "Stranglethorn Vale", abbr = "ZG", levels = "60", players = "20", type = "Raid" },
    ["Onyxia's Lair"] = { cont = 1, zone = "Dustwallow Marsh", abbr = "Ony", levels = "60", players = "40", type = "Raid" },
    ["Molten Core"] = { cont = 2, zone = "Burning Steppes", abbr = "MC", levels = "60", players = "40", type = "Raid" },
    ["Blackwing Lair"] = { cont = 2, zone = "Burning Steppes", abbr = "BWL", levels = "60", players = "40", type = "Raid" },
    ["Ruins of Ahn'Qiraj"] = { cont = 1, zone = "Silithus", abbr = "AQ20", levels = "60", players = "20", type = "Raid" },
    ["Temple of Ahn'Qiraj"] = { cont = 1, zone = "Silithus", abbr = "AQ40", levels = "60", players = "40", type = "Raid" },
}

local isInstance = {}
for z, list in pairs(byZone) do
    for i = 1, table.getn(list) do
        isInstance[list[i]] = true
    end
end
for c = 1, 2 do
    local list = byContinent[c]
    if list then
        for i = 1, table.getn(list) do
            isInstance[list[i]] = true
        end
    end
end
for n, _ in pairs(details) do isInstance[n] = true end
isInstance["GM Island"] = nil
isInstance["Blackstone Island"] = nil
isInstance["Caverns of Time"] = nil
isInstance["Hyjal"] = nil

CM.Instances.byZone = byZone
CM.Instances.byContinent = byContinent
CM.Instances.details = details
CM.Instances.isInstance = isInstance

function CM.Instances:IsDungeon(name)
    if not name or name == "" then return false end
    return self.isInstance[name] == true
end

function CM.Instances:GetForContinent(cont)
    if not cont then return {} end
    return self.byContinent[cont] or {}
end

function CM.Instances:GetForZone(zoneName)
    if not zoneName or zoneName == "" then return {} end
    return self.byZone[zoneName] or {}
end

function CM.Instances:GetDetail(name)
    return self.details[name]
end
