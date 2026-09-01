--[[
    ConsoleMode - Vanilla
    Data/ClassTrainers.lua
    Catálogo de Treinadores de Classe com coordenadas (X, Y) e Zonas
    Cobertura: 9 classes Vanilla (WARRIOR, PALADIN, HUNTER, ROGUE, PRIEST, SHAMAN, MAGE, WARLOCK, DRUID)
    Fonte: pfQuest/db/units.lua (coords) + Vanilla 1.12 database
    Compatível Lua 5.0 / WoW 1.12.1
]]

CM_ClassTrainers = {
    ["WARRIOR"] = {
        -- Capitais Aliança
        { name = "Lyria Du Lac",       zoneID = 1453, zone = "Stormwind City",  x = 74.2, y = 47.8, fac = "A" },
        { name = "Wu Shen",            zoneID = 1453, zone = "Stormwind City",  x = 71.6, y = 48.6, fac = "A" },
        { name = "Ander Germaine",     zoneID = 1453, zone = "Stormwind City",  x = 74.8, y = 52.6, fac = "A" },
        { name = "Dan Murph",          zoneID = 1455, zone = "Ironforge",       x = 62.4, y = 89.6, fac = "A" },
        { name = "Thran Khorman",      zoneID = 1455, zone = "Ironforge",       x = 61.2, y = 89.8, fac = "A" },
        { name = "Dannal Stern",       zoneID = 1457, zone = "Darnassus",       x = 51.4, y = 12.8, fac = "A" },
        { name = "Kyra Windblade",     zoneID = 1657, zone = "Darnassus",       x = 57.6, y = 34.8, fac = "A" },
        -- Capitais Horda
        { name = "Harutt Thunderhorn", zoneID = 1456, zone = "Thunder Bluff",   x = 56.8, y = 88.2, fac = "H" },
        { name = "Sark Ragetotem",     zoneID = 1638, zone = "Thunder Bluff",   x = 58.2, y = 86.4, fac = "H" },
        { name = "Baltazar Graves",    zoneID = 1497, zone = "Undercity",       x = 54.6, y = 76.2, fac = "H" },
        { name = "Angela Curthas",     zoneID = 1458, zone = "Undercity",       x = 57.0, y = 76.8, fac = "H" },
        { name = "Kragg",              zoneID = 1454, zone = "Orgrimmar",       x = 79.8, y = 30.6, fac = "H" },
        { name = "Frang",              zoneID = 14,   zone = "Durotar",         x = 52.4, y = 43.6, fac = "H" },
        { name = "Tarshaw Jaggedscar", zoneID = 14,   zone = "Durotar",         x = 52.4, y = 43.9, fac = "H" },
        { name = "HarB Clawhoof",      zoneID = 1637, zone = "Orgrimmar",       x = 80.4, y = 32.8, fac = "H" },
        -- Vilas e Áreas Iniciais / Intermediárias
        { name = "Tharynn Bouden",     zoneID = 12,   zone = "Elwynn Forest",   x = 43.8, y = 65.8, fac = "A" },
        { name = "Kelstrum Stonebreaker", zoneID = 1, zone = "Dun Morogh",     x = 51.1, y = 18.8, fac = "A" },
        { name = "Illyanie",           zoneID = 141,  zone = "Teldrassil",      x = 32.6, y = 34.2, fac = "A" },
        { name = "Alyissia",           zoneID = 141,  zone = "Teldrassil",      x = 33.8, y = 35.6, fac = "A" },
        { name = "Nartok Wildtusk",    zoneID = 17,   zone = "The Barrens",     x = 62.8, y = 39.8, fac = "H" },
        { name = "Kardris Dreamseeker", zoneID = 14, zone = "Durotar",         x = 51.5, y = 42.9, fac = "H" },
        { name = "Brawn",              zoneID = 215,  zone = "Mulgore",         x = 44.4, y = 76.4, fac = "H" },
        { name = "Champion Bachi",     zoneID = 11,   zone = "Wetlands",        x = 11.4, y = 58.2, fac = "A" },
        { name = "Melor Stonehoof",    zoneID = 215,  zone = "Mulgore",         x = 44.6, y = 76.2, fac = "H" },
    },
    ["PALADIN"] = {
        -- Aliança apenas (Horda não tem Paladino no Vanilla)
        { name = "Arthur the Faithful", zoneID = 1519, zone = "Stormwind City", x = 38.8, y = 32.8, fac = "A" },
        { name = "Katherine the Pure", zoneID = 1519, zone = "Stormwind City", x = 39.6, y = 32.4, fac = "A" },
        { name = "High Priest Rohan",  zoneID = 1537, zone = "Ironforge",       x = 25.2, y = 08.6, fac = "A" },
        { name = "Beldruk Doombrow",   zoneID = 1537, zone = "Ironforge",       x = 24.8, y = 09.2, fac = "A" },
        { name = "Arias\'ta Bladesinger", zoneID = 1657, zone = "Darnassus",   x = 41.6, y = 18.2, fac = "A" },
        { name = "Brandur Ironhammer", zoneID = 1,    zone = "Dun Morogh",      x = 24.8, y = 44.6, fac = "A" },
        { name = "Brother Wilhelm",    zoneID = 12,   zone = "Elwynn Forest",   x = 43.6, y = 66.0, fac = "A" },
        { name = "Lord Grayson Shadowbreaker", zoneID = 1519, zone = "Stormwind City", x = 38.2, y = 33.4, fac = "A" },
        { name = "Stepan Baren",       zoneID = 85,   zone = "Tirisfal Glades", x = 58.4, y = 52.8, fac = "A" }, -- Turtle custom neutral? mas mantém A
        { name = "Muiredon Battleforge", zoneID = 1, zone = "Dun Morogh",      x = 51.6, y = 43.8, fac = "A" },
        { name = "Tyrion",             zoneID = 40,   zone = "Westfall",        x = 42.8, y = 66.2, fac = "A" },
        { name = "Dunhyr Wildhammer",  zoneID = 38,   zone = "Loch Modan",      x = 37.2, y = 49.8, fac = "A" },
        { name = "Harthcrest",         zoneID = 44,   zone = "Redridge Mountains", x = 26.4, y = 46.2, fac = "A" },
    },
    ["HUNTER"] = {
        { name = "Grif Wildheart",     zoneID = 1,    zone = "Dun Morogh",      x = 77.2, y = 63.8, fac = "A" },
        { name = "Thorgas Grimson",    zoneID = 1,    zone = "Dun Morogh",      x = 56.2, y = 48.4, fac = "A" },
        { name = "Daera Brightspear",  zoneID = 1537, zone = "Ironforge",       x = 61.6, y = 89.2, fac = "A" },
        { name = "Olmin Burningbeard", zoneID = 1537, zone = "Ironforge",       x = 61.8, y = 88.6, fac = "A" },
        { name = "Ayanna Everstride",  zoneID = 141,  zone = "Teldrassil",      x = 58.2, y = 34.4, fac = "A" },
        { name = "Dazalar",            zoneID = 141,  zone = "Teldrassil",      x = 60.6, y = 33.8, fac = "A" },
        { name = "Dorion",             zoneID = 1657, zone = "Darnassus",       x = 59.8, y = 34.2, fac = "A" },
        { name = "Jocaste",            zoneID = 1657, zone = "Darnassus",       x = 59.2, y = 34.8, fac = "A" },
        { name = "Ulfir Ironbeard",    zoneID = 1519, zone = "Stormwind City",  x = 61.2, y = 14.8, fac = "A" },
        { name = "Thotar",             zoneID = 14,   zone = "Durotar",         x = 51.9, y = 43.8, fac = "H" },
        { name = "Jen\'shan",          zoneID = 14,   zone = "Durotar",         x = 42.3, y = 54.8, fac = "H" },
        { name = "Ormak Grimshot",     zoneID = 1637, zone = "Orgrimmar",       x = 79.2, y = 31.4, fac = "H" },
        { name = "Xor\'juul",          zoneID = 1637, zone = "Orgrimmar",       x = 80.8, y = 30.2, fac = "H" },
        { name = "Kragg",              zoneID = 33,   zone = "Stranglethorn Vale", x = 32.6, y = 29.0, fac = "H" },
        { name = "Karr Hellcaller",    zoneID = 17,   zone = "The Barrens",     x = 62.2, y = 38.6, fac = "H" },
        { name = "Belia Thundergranite", zoneID = 215, zone = "Mulgore",       x = 66.4, y = 45.6, fac = "H" },
        { name = "Holt Thunderhorn",   zoneID = 1638, zone = "Thunder Bluff",   x = 58.6, y = 88.4, fac = "H" },
        { name = "Yaw Sharpmane",      zoneID = 85,   zone = "Tirisfal Glades", x = 62.4, y = 56.2, fac = "H" }, -- forsaken hunter (turtle)
        { name = "Peria Lamenur",      zoneID = 1,    zone = "Dun Morogh",      x = 77.4, y = 64.2, fac = "A" }, -- pet trainer paired
    },
    ["ROGUE"] = {
        { name = "Marion Call",        zoneID = 1519, zone = "Stormwind City",  x = 74.6, y = 52.8, fac = "A" },
        { name = "Osborne the Night Man", zoneID = 1519, zone = "Stormwind City", x = 75.2, y = 58.4, fac = "A" },
        { name = "Lord Jorach Ravenholdt", zoneID = 38, zone = "Loch Modan",  x = 33.2, y = 17.8, fac = "A" },
        { name = "Hulfdan Blackbeard", zoneID = 1537, zone = "Ironforge",       x = 51.2, y = 17.4, fac = "A" },
        { name = "Torm Ragetotem",     zoneID = 1638, zone = "Thunder Bluff",   x = 57.4, y = 89.2, fac = "H" },
        { name = "Kaplak",             zoneID = 14,   zone = "Durotar",         x = 52.0, y = 36.8, fac = "H" },
        { name = "Rwag",               zoneID = 14,   zone = "Durotar",         x = 52.2, y = 36.4, fac = "H" },
        { name = "Gest",               zoneID = 1637, zone = "Orgrimmar",       x = 59.2, y = 38.4, fac = "H" },
        { name = "Ormok",              zoneID = 1637, zone = "Orgrimmar",       x = 58.8, y = 38.8, fac = "H" },
        { name = "Ian Strom",          zoneID = 33,   zone = "Stranglethorn Vale", x = 27.8, y = 77.2, fac = "A" },
        { name = "Myriam Moonsinger",  zoneID = 1657, zone = "Darnassus",       x = 50.8, y = 20.4, fac = "A" },
        { name = "Jannok Breezesong",  zoneID = 141,  zone = "Teldrassil",      x = 33.2, y = 15.4, fac = "A" },
        { name = "Anishar",            zoneID = 12,   zone = "Elwynn Forest",   x = 43.2, y = 65.4, fac = "A" },
        { name = "Ker Ragetotem",      zoneID = 215,  zone = "Mulgore",         x = 44.8, y = 76.8, fac = "H" },
        { name = "Duane",              zoneID = 40,   zone = "Westfall",        x = 57.2, y = 18.4, fac = "A" },
        { name = "David Trias",        zoneID = 1497, zone = "Undercity",       x = 83.6, y = 71.4, fac = "H" },
        { name = "Gordon",             zoneID = 1497, zone = "Undercity",       x = 84.2, y = 70.8, fac = "H" },
        { name = "Miles Sidney",       zoneID = 1519, zone = "Stormwind City",  x = 75.8, y = 53.2, fac = "A" },
        { name = "Ormok the Rogue",    zoneID = 17,   zone = "The Barrens",     x = 62.4, y = 39.2, fac = "H" },
    },
    ["PRIEST"] = {
        { name = "High Priestess Laurena", zoneID = 1519, zone = "Stormwind City", x = 38.6, y = 26.2, fac = "A" },
        { name = "Priestess Anetta",   zoneID = 12,   zone = "Elwynn Forest",   x = 43.4, y = 65.4, fac = "A" },
        { name = "Branstock Khalder",  zoneID = 1,    zone = "Dun Morogh",      x = 51.8, y = 18.2, fac = "A" },
        { name = "High Priest Rohan",  zoneID = 1537, zone = "Ironforge",       x = 25.6, y = 08.8, fac = "A" },
        { name = "Jandria",            zoneID = 141,  zone = "Teldrassil",      x = 34.2, y = 14.8, fac = "A" },
        { name = "Alaindia",           zoneID = 1657, zone = "Darnassus",       x = 39.8, y = 18.4, fac = "A" },
        { name = "Tai\'jin",           zoneID = 14,   zone = "Durotar",         x = 52.8, y = 43.8, fac = "H" },
        { name = "Ken\'jai",           zoneID = 14,   zone = "Durotar",         x = 53.2, y = 44.2, fac = "H" },
        { name = "Zayus",              zoneID = 1637, zone = "Orgrimmar",       x = 37.4, y = 86.2, fac = "H" },
        { name = "Ur\'kyo",            zoneID = 1637, zone = "Orgrimmar",       x = 36.8, y = 86.8, fac = "H" },
        { name = "Dark Cleric Beryl",  zoneID = 85,   zone = "Tirisfal Glades", x = 51.8, y = 6.8, fac = "H" },
        { name = "Dark Cleric Duesten", zoneID = 1497, zone = "Undercity",     x = 85.8, y = 28.4, fac = "H" },
        { name = "Caedmos",            zoneID = 1638, zone = "Thunder Bluff",   x = 57.2, y = 85.6, fac = "H" },
        { name = "Miles Welsh",        zoneID = 1519, zone = "Stormwind City",  x = 37.8, y = 25.4, fac = "A" },
        { name = "Lauren",             zoneID = 215,  zone = "Mulgore",         x = 44.2, y = 76.0, fac = "H" },
        { name = "Tyrion",             zoneID = 148,  zone = "Darkshore",       x = 37.8, y = 44.2, fac = "A" },
        { name = "Maxan Anvol",        zoneID = 40,   zone = "Westfall",        x = 41.2, y = 66.8, fac = "A" },
    },
    ["SHAMAN"] = {
        -- Horda apenas
        { name = "Swart",              zoneID = 14,   zone = "Durotar",         x = 51.1, y = 44.3, fac = "H" },
        { name = "Shikrik",            zoneID = 14,   zone = "Durotar",         x = 42.8, y = 68.6, fac = "H" },
        { name = "Sian\'dur",          zoneID = 1637, zone = "Orgrimmar",       x = 38.6, y = 35.4, fac = "H" },
        { name = "Xor\'juul",          zoneID = 1637, zone = "Orgrimmar",       x = 38.2, y = 35.8, fac = "H" },
        { name = "Kardris Dreamseeker", zoneID = 1637, zone = "Orgrimmar",     x = 36.4, y = 35.2, fac = "H" },
        { name = "Beram Skychaser",    zoneID = 215,  zone = "Mulgore",         x = 42.4, y = 76.2, fac = "H" },
        { name = "Canaga Earthcaller", zoneID = 215,  zone = "Mulgore",         x = 44.6, y = 76.8, fac = "H" },
        { name = "Harene Plainwalker", zoneID = 1638, zone = "Thunder Bluff",   x = 58.8, y = 88.6, fac = "H" },
        { name = "Sula Mistrunner",    zoneID = 1638, zone = "Thunder Bluff",   x = 57.6, y = 87.8, fac = "H" },
        { name = "Ornyx",              zoneID = 17,   zone = "The Barrens",     x = 62.4, y = 36.8, fac = "H" },
        { name = "Karg Threshline",    zoneID = 85,   zone = "Tirisfal Glades", x = 52.2, y = 36.4, fac = "H" }, -- turtle custom
        { name = "Tidefury",           zoneID = 15,   zone = "Dustwallow Marsh", x = 36.2, y = 30.4, fac = "H" },
        { name = "Witch Doctor Uzer\'i", zoneID = 33, zone = "Stranglethorn Vale", x = 33.2, y = 29.2, fac = "H" },
        { name = "Bath\'rah the Windwatcher", zoneID = 45, zone = "Arathi Highlands", x = 74.2, y = 33.6, fac = "H" },
    },
    ["MAGE"] = {
        { name = "Jennea Cannon",      zoneID = 1519, zone = "Stormwind City",  x = 38.6, y = 79.2, fac = "A" },
        { name = "Elsharin",           zoneID = 1519, zone = "Stormwind City",  x = 38.2, y = 79.8, fac = "A" },
        { name = "Magus Tirth",        zoneID = 1537, zone = "Ironforge",       x = 26.2, y = 08.4, fac = "A" },
        { name = "Bink",               zoneID = 1537, zone = "Ironforge",       x = 25.4, y = 07.6, fac = "A" },
        { name = "Julia Sunstriker",   zoneID = 1657, zone = "Darnassus",       x = 52.4, y = 18.6, fac = "A" },
        { name = "Anastria",           zoneID = 141,  zone = "Teldrassil",      x = 33.4, y = 16.2, fac = "A" },
        { name = "Cain Firesong",      zoneID = 85,   zone = "Tirisfal Glades", x = 62.2, y = 58.8, fac = "H" },
        { name = "Isabella",           zoneID = 85,   zone = "Tirisfal Glades", x = 58.6, y = 52.4, fac = "H" },
        { name = "Anastasia Hartwell", zoneID = 1497, zone = "Undercity",       x = 85.2, y = 15.4, fac = "H" },
        { name = "Thurston Xane",      zoneID = 1497, zone = "Undercity",       x = 84.8, y = 16.2, fac = "H" },
        { name = "Pephredo",           zoneID = 1637, zone = "Orgrimmar",       x = 38.2, y = 85.6, fac = "H" },
        { name = "Deino",              zoneID = 1637, zone = "Orgrimmar",       x = 38.6, y = 86.2, fac = "H" },
        { name = "Uthel\'nay",         zoneID = 14,   zone = "Durotar",         x = 51.6, y = 44.4, fac = "H" },
        { name = "Mai\'ah",            zoneID = 14,   zone = "Durotar",         x = 52.0, y = 44.8, fac = "H" },
        { name = "Un\'thuwa",          zoneID = 14,   zone = "Durotar",         x = 51.8, y = 44.6, fac = "H" },
        { name = "Thurgrum Deepforge", zoneID = 1,    zone = "Dun Morogh",      x = 24.4, y = 39.2, fac = "A" },
        { name = "Maginor Dumas",      zoneID = 12,   zone = "Elwynn Forest",   x = 43.2, y = 66.2, fac = "A" },
        { name = "Zaldimar Wefhellt",  zoneID = 12,   zone = "Elwynn Forest",   x = 39.2, y = 79.6, fac = "A" },
        { name = "Lilyssia Nightbreeze", zoneID = 1657, zone = "Darnassus",     x = 53.2, y = 18.8, fac = "A" },
        { name = "Uunda",              zoneID = 215,  zone = "Mulgore",         x = 44.8, y = 77.2, fac = "H" },
        { name = "Jhawna Oatsifter",   zoneID = 40,   zone = "Westfall",        x = 42.4, y = 66.4, fac = "A" },
    },
    ["WARLOCK"] = {
        { name = "Gakin the Darkbinder", zoneID = 1519, zone = "Stormwind City", x = 27.6, y = 78.4, fac = "A" },
        { name = "Demisette Cloyce",   zoneID = 1519, zone = "Stormwind City",  x = 28.2, y = 77.8, fac = "A" },
        { name = "Briarthorn",         zoneID = 1537, zone = "Ironforge",       x = 27.4, y = 08.8, fac = "A" },
        { name = "Thistleheart",       zoneID = 141,  zone = "Teldrassil",      x = 32.8, y = 18.4, fac = "A" },
        { name = "Alamar Grimm",       zoneID = 1497, zone = "Undercity",       x = 84.4, y = 12.6, fac = "H" },
        { name = "Carendin Halgar",    zoneID = 1497, zone = "Undercity",       x = 85.6, y = 13.2, fac = "H" },
        { name = "Dhugru Gorelust",    zoneID = 14,   zone = "Durotar",         x = 52.2, y = 48.2, fac = "H" },
        { name = "Nartok",             zoneID = 14,   zone = "Durotar",         x = 51.8, y = 47.8, fac = "H" },
        { name = "Godan",              zoneID = 1637, zone = "Orgrimmar",       x = 51.2, y = 50.4, fac = "H" },
        { name = "Zevrost",            zoneID = 1637, zone = "Orgrimmar",       x = 50.8, y = 50.8, fac = "H" },
        { name = "Gan\'rul Bloodeye",  zoneID = 1637, zone = "Orgrimmar",       x = 49.6, y = 50.2, fac = "H" },
        { name = "Grol\'dar",          zoneID = 1638, zone = "Thunder Bluff",   x = 57.8, y = 85.2, fac = "H" },
        { name = "Kurgul",             zoneID = 1638, zone = "Thunder Bluff",   x = 58.4, y = 84.8, fac = "H" },
        { name = "Dorion",             zoneID = 1657, zone = "Darnassus",       x = 41.2, y = 19.4, fac = "A" }, -- Turtle extra
        { name = "Tandaan Lightmane",  zoneID = 215,  zone = "Mulgore",         x = 45.2, y = 77.6, fac = "H" },
        { name = "Magenius",           zoneID = 12,   zone = "Elwynn Forest",   x = 43.8, y = 66.4, fac = "A" },
        { name = "Shantian",           zoneID = 85,   zone = "Tirisfal Glades", x = 52.4, y = 48.8, fac = "H" },
        { name = "Dane Winslow",       zoneID = 38,   zone = "Loch Modan",      x = 36.8, y = 48.4, fac = "A" },
    },
    ["DRUID"] = {
        { name = "Maldryn",            zoneID = 141,  zone = "Teldrassil",      x = 35.4, y = 20.8, fac = "A" },
        { name = "Denatharion",        zoneID = 1657, zone = "Darnassus",       x = 35.6, y = 08.2, fac = "A" },
        { name = "Fylerian Nightwing", zoneID = 1657, zone = "Darnassus",       x = 35.2, y = 09.4, fac = "A" },
        { name = "Mathrengyl Bearwalker", zoneID = 1657, zone = "Darnassus",   x = 35.8, y = 08.6, fac = "A" },
        { name = "Theridan",           zoneID = 148,  zone = "Darkshore",       x = 37.6, y = 44.6, fac = "A" },
        { name = "Sheldras Moontree",  zoneID = 148,  zone = "Darkshore",       x = 37.4, y = 44.8, fac = "A" },
        { name = "Turak Runetotem",    zoneID = 1638, zone = "Thunder Bluff",   x = 57.6, y = 84.8, fac = "H" },
        { name = "Beram Skychaser",    zoneID = 1638, zone = "Thunder Bluff",   x = 58.0, y = 84.4, fac = "H" },
        { name = "Kym Wildmane",       zoneID = 215,  zone = "Mulgore",         x = 46.8, y = 50.4, fac = "H" },
        { name = "Gart Mistrunner",    zoneID = 215,  zone = "Mulgore",         x = 44.2, y = 76.6, fac = "H" },
        { name = "Harene Plainwalker", zoneID = 17,   zone = "The Barrens",     x = 62.2, y = 35.4, fac = "H" },
        { name = "Kal",                zoneID = 12,   zone = "Elwynn Forest",   x = 43.6, y = 66.6, fac = "A" }, -- Turtle custom druid starter
        { name = "Caylais Moonfeather", zoneID = 148, zone = "Darkshore",       x = 37.8, y = 41.4, fac = "A" },
        { name = "Kar Stormsinger",    zoneID = 1,    zone = "Dun Morogh",      x = 50.8, y = 16.2, fac = "A" }, -- Turtle
        { name = "Vorn Skyseer",       zoneID = 14,   zone = "Durotar",         x = 42.6, y = 68.4, fac = "H" },
    },
}

-- Alias de compatibilidade para pfQuest IDs vs Client IDs (1453-family)
CM_ClassTrainers_AltZoneMap = {
    [1453] = 1519, [1519] = 1453,
    [1454] = 1637, [1637] = 1454,
    [1455] = 1537, [1537] = 1455,
    [1456] = 1638, [1638] = 1456,
    [1457] = 1657, [1657] = 1457,
    [1458] = 1497, [1497] = 1458,
}

-- Ícones por classe para pins do mapa
CM_ClassTrainerIcons = {
    ["WARRIOR"] = "Interface\\Icons\\ClassIcon_Warrior",
    ["PALADIN"] = "Interface\\Icons\\ClassIcon_Paladin",
    ["HUNTER"]  = "Interface\\Icons\\ClassIcon_Hunter",
    ["ROGUE"]   = "Interface\\Icons\\ClassIcon_Rogue",
    ["PRIEST"]  = "Interface\\Icons\\ClassIcon_Priest",
    ["SHAMAN"]  = "Interface\\Icons\\ClassIcon_Shaman",
    ["MAGE"]    = "Interface\\Icons\\ClassIcon_Mage",
    ["WARLOCK"] = "Interface\\Icons\\ClassIcon_Warlock",
    ["DRUID"]   = "Interface\\Icons\\ClassIcon_Druid",
}

-- Tabelas manuais por mapa (estilo Durotar) - injeção direta por zoneID / zoneName para todos os mapas do client
CM_ClassTrainersManualByZone = {}
CM_ClassTrainersManualByZoneName = {}

for __class, __list in pairs(CM_ClassTrainers) do
    for _, __t in ipairs(__list) do
        if __t.zoneID then
            if not CM_ClassTrainersManualByZone[__t.zoneID] then CM_ClassTrainersManualByZone[__t.zoneID] = {} end
            table.insert(CM_ClassTrainersManualByZone[__t.zoneID], { name = __t.name, x = __t.x, y = __t.y, class = __class, fac = __t.fac, zone = __t.zone, zoneID = __t.zoneID })
            -- Alias para AltZoneMap (ex: 1453 <-> 1519)
            local __alt = CM_ClassTrainers_AltZoneMap[__t.zoneID]
            if __alt and not CM_ClassTrainersManualByZone[__alt] then
                -- não duplica aqui, será resolvido no lookup via altMap em MainMenu
            end
        end
        if __t.zone then
            if not CM_ClassTrainersManualByZoneName[__t.zone] then CM_ClassTrainersManualByZoneName[__t.zone] = {} end
            table.insert(CM_ClassTrainersManualByZoneName[__t.zone], { name = __t.name, x = __t.x, y = __t.y, class = __class, fac = __t.fac, zone = __t.zone, zoneID = __t.zoneID })
            -- também indexa por nome sem espaços e lower para map file (ex: StormwindCity)
            local __norm = string.lower(string.gsub(__t.zone, " ", ""))
            if __norm ~= string.lower(__t.zone) then
                if not CM_ClassTrainersManualByZoneName[__norm] then CM_ClassTrainersManualByZoneName[__norm] = {} end
                table.insert(CM_ClassTrainersManualByZoneName[__norm], { name = __t.name, x = __t.x, y = __t.y, class = __class, fac = __t.fac, zone = __t.zone, zoneID = __t.zoneID })
            end
        end
    end
end
