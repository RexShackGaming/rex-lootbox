Config = {}

Config.Debug = false
Config.Image = 'rsg-inventory/html/images/' -- Locaion where your images are stored

-- Loot box prop models (RDR2 prop names)
Config.LootBoxModels = {
    'mp006_p_mp006_cratecanvase01x',
}

-- Spawn locations where loot boxes can appear
Config.SpawnLocations = {
    { coords = vec3(-57.17, 908.51, 208.70),     radius = 1.5 }, -- valentine area
    { coords = vec3(-208.78, 300.17, 96.61),     radius = 1.5 }, -- valentine area
    { coords = vec3(-663.75, 594.29, 105.59),    radius = 1.5 }, -- valentine area
    { coords = vec3(-1601.78, -417.47, 176.33),  radius = 1.5 }, -- strawberry area
    { coords = vec3(-1969.25, -293.48, 192.47),  radius = 1.5 }, -- strawberry area
    { coords = vec3(-1710.02, -676.07, 153.75),  radius = 1.5 }, -- strawberry area
    { coords = vec3(-889.42, -1083.10, 59.55),   radius = 1.5 }, -- blackwater area
    { coords = vec3(-776.00, -1881.35, 54.76),   radius = 1.5 }, -- blackwater area
    { coords = vec3(-759.87, -739.91, 53.18),    radius = 1.5 }, -- blackwater area
    { coords = vec3(-3480.16, -2123.81, -1.03),  radius = 1.5 }, -- armadillo area
    { coords = vec3(-4037.54, -2861.17, -8.09),  radius = 1.5 }, -- armadillo area
    { coords = vec3(-3326.10, -2866.90, -6.07),  radius = 1.5 }, -- armadillo area
    { coords = vec3(-5381.26, -2854.14, 13.26),  radius = 1.5 }, -- tumbleweed area
    { coords = vec3(-5616.90, -3031.49, 2.59),   radius = 1.5 }, -- tumbleweed area
    { coords = vec3(-5203.62, -3209.87, -18.10), radius = 1.5 }, -- tumbleweed area
    { coords = vec3(2746.19, 1640.22, 157.87),   radius = 1.5 }, -- annesburg area
    { coords = vec3(2691.07, 1219.02, 113.13),   radius = 1.5 }, -- annesburg area
    { coords = vec3(2354.13, 1454.24, 143.54),   radius = 1.5 }, -- annesburg area
    { coords = vec3(2248.42, -1103.35, 43.19),   radius = 1.5 }, -- stdenis area
    { coords = vec3(2199.88, -1469.00, 41.72),   radius = 1.5 }, -- stdenis area
    { coords = vec3(2633.19, -776.81, 42.36),    radius = 1.5 }, -- stdenis area
    { coords = vec3(3236.00, -581.34, 42.85),    radius = 1.5 }, -- stdenis area (prison)
    { coords = vec3(1130.27, -1505.16, 54.99),   radius = 1.5 }, -- rhodes area
    { coords = vec3(1783.77, -1278.62, 42.59),   radius = 1.5 }, -- rhodes area
}

-- Loot box settings
Config.Settings = {
    -- How many loot boxes spawn at once
    MaxActiveBoxes = 1,

    -- Time in seconds before a box despawns automatically
    BoxTimeout = 1800, -- 30 minutes

    -- Time in seconds before a new box spawns at a location
    RespawnTime = 900, -- 15 minutes

    -- Minimum distance player must be from box to interact
    InteractDistance = 2.0,

    -- Whether to show blips on map
    ShowBlips = true,
    BlipSprite = 'blip_chest', -- Barrel/box blip
    BlipScale = 0.5,
    BlipColor = 'BLIP_MODIFIER_MP_COLOR_6',
}

-- Item pools for random loot generation
-- Each pool has items with min/max amounts and weight (probability)
Config.ItemPools = {
    -- Common items pool
    common = {
        { item = 'bread',             minAmount = 1, maxAmount = 5, weight = 10 },
        { item = 'water',             minAmount = 1, maxAmount = 5, weight = 10 },
        { item = 'stew',              minAmount = 1, maxAmount = 3, weight = 10 },
        { item = 'beer',              minAmount = 1, maxAmount = 5, weight = 10 },
        { item = 'canteen0',          minAmount = 1, maxAmount = 1, weight = 10 },
        { item = 'ammo_box_revolver', minAmount = 1, maxAmount = 1, weight = 10 },
        { item = 'ammo_box_pistol',   minAmount = 1, maxAmount = 1, weight = 10 },
        { item = 'ammo_box_repeater', minAmount = 1, maxAmount = 1, weight = 10 },
        { item = 'ammo_box_rifle',    minAmount = 1, maxAmount = 1, weight = 10 },
        { item = 'ammo_box_shotgun',  minAmount = 1, maxAmount = 1, weight = 10 },
    },
    
    -- Uncommon items pool
    uncommon = {
        { item = 'weapon_melee_knife',        minAmount = 1, maxAmount = 1, weight = 25 },
        { item = 'weapon_melee_lantern',      minAmount = 1, maxAmount = 1, weight = 25 },
        { item = 'weapon_kit_binoculars',     minAmount = 1, maxAmount = 1, weight = 25 },
        { item = 'weapon_revolver_cattleman', minAmount = 1, maxAmount = 1, weight = 25 },
    },
    
    -- Rare items pool
    rare = {
        { item = 'weapon_revolver_cattleman',            minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_revolver_cattleman_mexican',    minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_revolver_doubleaction',         minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_revolver_doubleaction_gambler', minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_revolver_schofield',            minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_revolver_lemat',                minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_revolver_navy',                 minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_revolver_navy_crossover',       minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_pistol_volcanic',               minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_pistol_m1899',                  minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_pistol_mauser',                 minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_pistol_semiauto',               minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_repeater_carbine',              minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_repeater_winchester',           minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_repeater_henry',                minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_repeater_evans',                minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_rifle_varmint',                 minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_rifle_springfield',             minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_rifle_boltaction',              minAmount = 1, maxAmount = 1, weight = 5 },
        { item = 'weapon_rifle_elephant',                minAmount = 1, maxAmount = 1, weight = 1 },
        { item = 'weapon_sniperrifle_rollingblock',      minAmount = 1, maxAmount = 1, weight = 2 },
        { item = 'weapon_shotgun_doublebarrel',          minAmount = 1, maxAmount = 1, weight = 2 },
    },
}

-- Loot tier configuration
-- Determines which item pool is used when opening a box
Config.LootTiers = {
    { pool = 'common', chance = 60 },    -- 60% chance for common loot
    { pool = 'uncommon', chance = 30 },  -- 30% chance for uncommon loot
    { pool = 'rare', chance = 10 },      -- 10% chance for rare loot
}

-- Stash configuration
Config.Stash = {
    -- Prefix for stash IDs
    Prefix = 'lootbox_',
    
    -- Max weight/slots for the stash (depends on inventory system)
    MaxSlots = 10,
    MaxWeight = 100000, -- 100kg in grams
}
