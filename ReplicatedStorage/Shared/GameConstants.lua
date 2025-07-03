--[[
    GameConstants.lua
    Central configuration and constants for the Cultivation Game
    Shared between client and server for consistency
]]

local GameConstants = {}

-- Game Version
GameConstants.VERSION = "1.0.0"
GameConstants.DATA_VERSION = 1.0

-- Realm Definitions
GameConstants.CULTIVATION_REALMS = {
    [0] = {name = "Mortal", description = "No cultivation", lifespan = 80, maxQi = 0},
    [1] = {name = "Qi Gathering", description = "Begin absorbing spiritual energy", lifespan = 120, maxQi = 1000},
    [2] = {name = "Qi Refining", description = "Refine and purify gathered energy", lifespan = 150, maxQi = 2500},
    [3] = {name = "Qi Building", description = "Construct energy foundation", lifespan = 300, maxQi = 5000},
    [4] = {name = "Core Formation", description = "Form spiritual core", lifespan = 600, maxQi = 10000},
    [5] = {name = "Nascent Soul", description = "Develop spiritual consciousness", lifespan = 1200, maxQi = 25000},
    [6] = {name = "Heavenly Being", description = "Transcend mortal limitations", lifespan = 2400, maxQi = 50000},
    [7] = {name = "Four-Axis", description = "Manipulate attraction forces", lifespan = 50000, maxQi = 100000},
    [8] = {name = "Integration", description = "Integrate with natural laws", lifespan = 100000, maxQi = 250000},
    [9] = {name = "Star Shattering", description = "Gain power to affect celestial bodies", lifespan = 10000000, maxQi = 500000},
    [10] = {name = "Sacred Vessel", description = "Become a sacred vessel", lifespan = 10000000000, maxQi = 1000000},
    [11] = {name = "Entering Nirvana", description = "Approach true immortality", lifespan = math.huge, maxQi = 2500000}
}

GameConstants.MARTIAL_REALMS = {
    [0] = {name = "Untrained", description = "No martial training", abilities = {}},
    [1] = {name = "Third Rate", description = "Basic martial techniques", abilities = {"Basic Combat"}},
    [2] = {name = "Second Rate", description = "Proficient martial artist", abilities = {"Basic Combat", "Internal Energy"}},
    [3] = {name = "First Rate", description = "Master martial artist", abilities = {"Basic Combat", "Internal Energy", "External Projection"}},
    [4] = {name = "Peak Master", description = "See intent as colors", abilities = {"Intent Reading", "Basic Gang Qi"}},
    [5] = {name = "Three Flowers", description = "Master emotional intent", abilities = {"Intent Reading", "Emotion Mastery", "Gang Qi Formation"}},
    [6] = {name = "Five Energies", description = "Awaken divine consciousness", abilities = {"Intent Reading", "Emotion Mastery", "Gang Qi Formation", "Spirit Root Formation"}},
    [7] = {name = "Ultimate Pinnacle", description = "Create Gang Spheres", abilities = {"Intent Reading", "Emotion Mastery", "Gang Qi Formation", "Gang Spheres"}},
    [8] = {name = "First Manifestation", description = "Manifest heart essence", abilities = {"Intent Reading", "Emotion Mastery", "Gang Qi Formation", "Gang Spheres", "Heart Manifestation"}},
    [9] = {name = "Second Manifestation", description = "Integrate ideals to self", abilities = {"Intent Reading", "Emotion Mastery", "Gang Qi Formation", "Gang Spheres", "Heart Manifestation", "Ideal Integration"}},
    [10] = {name = "Third Manifestation", description = "Awaken martial arts heart", abilities = {"Intent Reading", "Emotion Mastery", "Gang Qi Formation", "Gang Spheres", "Heart Manifestation", "Ideal Integration", "Living Martial Arts"}}
}

-- Spirit Root Types
GameConstants.SPIRIT_ROOTS = {
    None = {multiplier = 0, description = "No spiritual aptitude"},
    Low = {multiplier = 1.2, description = "Basic spiritual aptitude"},
    Medium = {multiplier = 1.5, description = "Good spiritual aptitude"},
    High = {multiplier = 2.0, description = "Excellent spiritual aptitude"},
    Legendary = {multiplier = 3.0, description = "Legendary spiritual aptitude"}
}

-- Bloodline Types
GameConstants.BLOODLINES = {
    Human = {
        description = "Standard human bloodline",
        bonuses = {},
        restrictions = {}
    },
    BeastBlood = {
        description = "Descendant of spiritual beasts",
        bonuses = {physicalPower = 1.3, earthAffinityBonus = 0.2},
        restrictions = {heavenAffinityPenalty = 0.1}
    },
    DemonBlood = {
        description = "Descendant of demons",
        bonuses = {darkAffinityBonus = 0.3, combatPower = 1.2},
        restrictions = {lightAffinityPenalty = 0.2}
    },
    DragonBlood = {
        description = "Descendant of dragons",
        bonuses = {allAffinityBonus = 0.1, lifespan = 1.5, prestige = 2.0},
        restrictions = {pridePenalty = true}
    }
}

-- Emotion Types for Martial Arts
GameConstants.EMOTIONS = {
    Joy = {color = Color3.fromRGB(255, 215, 0), effects = {speed = 1.2, agility = 1.3}},
    Anger = {color = Color3.fromRGB(255, 0, 0), effects = {damage = 1.4, aggression = 1.5}},
    Sorrow = {color = Color3.fromRGB(0, 0, 139), effects = {defense = 1.3, endurance = 1.4}},
    Pleasure = {color = Color3.fromRGB(128, 0, 128), effects = {precision = 1.3, technique = 1.2}},
    Love = {color = Color3.fromRGB(255, 192, 203), effects = {healing = 1.5, support = 1.4}},
    Hate = {color = Color3.fromRGB(139, 0, 0), effects = {armorPen = 1.3, critical = 1.4}},
    Desire = {color = Color3.fromRGB(0, 0, 0), effects = {absorption = 1.3, drain = 1.2}}
}

-- Resource Types
GameConstants.RESOURCES = {
    Qi = {
        name = "Qi",
        description = "Basic spiritual energy",
        maxStack = math.huge,
        category = "Energy"
    },
    SpiritStones = {
        name = "Spirit Stones",
        description = "Crystallized spiritual energy",
        maxStack = 999999,
        category = "Currency"
    },
    ContributionPoints = {
        name = "Contribution Points",
        description = "Points earned through sect activities",
        maxStack = 999999,
        category = "Currency"
    },
    Reputation = {
        name = "Reputation",
        description = "Standing in the cultivation world",
        maxStack = math.huge,
        category = "Social"
    }
}

-- Herb Types
GameConstants.HERBS = {
    SpiritGrass = {
        name = "Spirit Grass",
        description = "Common herb that slightly increases qi",
        rarity = "Common",
        effects = {qi = 10},
        growthTime = 3600 -- 1 hour
    },
    BloodLotus = {
        name = "Blood Lotus",
        description = "Rare herb that enhances physical strength",
        rarity = "Rare",
        effects = {physicalPower = 0.1, qi = 50},
        growthTime = 21600 -- 6 hours
    },
    DragonScale = {
        name = "Dragon Scale Herb",
        description = "Legendary herb with immense power",
        rarity = "Legendary",
        effects = {qi = 500, breakthrough = 0.1},
        growthTime = 86400 -- 24 hours
    }
}

-- Pill Types
GameConstants.PILLS = {
    QiGatheringPill = {
        name = "Qi Gathering Pill",
        description = "Helps with qi cultivation",
        rarity = "Common",
        effects = {qiGain = 1.5, duration = 3600},
        ingredients = {"SpiritGrass", "SpiritGrass", "SpiritGrass"}
    },
    BreakthroughPill = {
        name = "Breakthrough Pill",
        description = "Assists with realm advancement",
        rarity = "Rare",
        effects = {breakthroughChance = 0.2},
        ingredients = {"BloodLotus", "SpiritGrass", "SpiritGrass", "SpiritGrass", "SpiritGrass"}
    },
    ImmortalityPill = {
        name = "Immortality Pill",
        description = "Grants temporary immortality",
        rarity = "Legendary",
        effects = {lifespan = 1000, allStats = 2.0},
        ingredients = {"DragonScale", "BloodLotus", "BloodLotus", "SpiritGrass", "SpiritGrass", "SpiritGrass", "SpiritGrass", "SpiritGrass"}
    }
}

-- Combat Constants
GameConstants.COMBAT = {
    BASE_DAMAGE = 100,
    CRITICAL_MULTIPLIER = 2.0,
    DODGE_CHANCE_BASE = 0.05,
    BLOCK_CHANCE_BASE = 0.1,
    INTENT_PREDICTION_WINDOW = 0.5, -- seconds
    COMBO_TIMEOUT = 2.0, -- seconds
    MAX_COMBO_LENGTH = 10
}

-- Sect Constants
GameConstants.SECTS = {
    MIN_MEMBERS_TO_CREATE = 5,
    MAX_MEMBERS_PER_SECT = 1000,
    SECT_WAR_COOLDOWN = 86400, -- 24 hours
    TERRITORY_CONTROL_RADIUS = 500, -- studs
    CONTRIBUTION_DECAY_RATE = 0.01 -- per day
}

-- World Event Constants
GameConstants.WORLD_EVENTS = {
    AncientHerbGarden = {
        duration = 1800, -- 30 minutes
        spawnChance = 0.1, -- per hour
        maxParticipants = 50,
        rewards = {
            herbs = {"SpiritGrass", "BloodLotus"},
            spiritStones = {min = 100, max = 1000}
        }
    },
    MeteorShower = {
        duration = 600, -- 10 minutes
        spawnChance = 0.05, -- per hour
        rewards = {
            spiritStones = {min = 500, max = 5000},
            materials = {"StarIron", "CelestialCrystal"}
        }
    },
    EnlightenmentOpportunity = {
        duration = 900, -- 15 minutes
        spawnChance = 0.2, -- per hour
        rewards = {
            experience = {min = 1000, max = 10000},
            breakthroughChance = 0.1
        }
    }
}

-- UI Constants
GameConstants.UI = {
    FADE_TIME = 0.3,
    NOTIFICATION_DURATION = 5.0,
    TOOLTIP_DELAY = 0.5,
    ANIMATION_SPEED = 0.2,
    MAX_CHAT_MESSAGES = 100
}

-- Audio Constants
GameConstants.AUDIO = {
    MASTER_VOLUME = 0.8,
    SFX_VOLUME = 0.7,
    MUSIC_VOLUME = 0.5,
    AMBIENT_VOLUME = 0.3
}

-- Network Constants
GameConstants.NETWORK = {
    MAX_REMOTE_CALLS_PER_MINUTE = 60,
    DATA_SYNC_INTERVAL = 30, -- seconds
    HEARTBEAT_INTERVAL = 5, -- seconds
    TIMEOUT_DURATION = 30 -- seconds
}

-- Progression Constants
GameConstants.PROGRESSION = {
    BASE_EXPERIENCE_REQUIRED = 1000,
    EXPERIENCE_SCALING = 1.5,
    BREAKTHROUGH_BASE_CHANCE = 0.1,
    BREAKTHROUGH_FAILURE_PENALTY = 0.9,
    MAX_DAILY_BREAKTHROUGHS = 3
}

-- Economy Constants
GameConstants.ECONOMY = {
    STARTING_SPIRIT_STONES = 100,
    DAILY_LOGIN_BONUS = 50,
    SECT_CONTRIBUTION_RATE = 0.1,
    TRADE_TAX_RATE = 0.05,
    AUCTION_HOUSE_FEE = 0.1
}

-- PvP Constants
GameConstants.PVP = {
    SAFE_ZONE_RADIUS = 200, -- around spawn points
    PVP_COOLDOWN = 300, -- 5 minutes after combat
    REPUTATION_LOSS_ON_DEATH = 100,
    ITEM_DROP_CHANCE_ON_DEATH = 0.1,
    SECT_WAR_DURATION = 3600 -- 1 hour
}

-- Utility Functions
function GameConstants.GetRealmInfo(realmType, level)
    if realmType == "Cultivation" then
        return GameConstants.CULTIVATION_REALMS[level]
    elseif realmType == "Martial" then
        return GameConstants.MARTIAL_REALMS[level]
    end
    return nil
end

function GameConstants.GetExperienceRequired(currentLevel)
    return math.floor(GameConstants.PROGRESSION.BASE_EXPERIENCE_REQUIRED * (GameConstants.PROGRESSION.EXPERIENCE_SCALING ^ currentLevel))
end

function GameConstants.GetBreakthroughChance(attempts, baseChance)
    local chance = baseChance or GameConstants.PROGRESSION.BREAKTHROUGH_BASE_CHANCE
    return math.min(0.95, chance * (GameConstants.PROGRESSION.BREAKTHROUGH_FAILURE_PENALTY ^ attempts))
end

function GameConstants.GetSpiritRootMultiplier(spiritRoot)
    local rootInfo = GameConstants.SPIRIT_ROOTS[spiritRoot]
    return rootInfo and rootInfo.multiplier or 1.0
end

function GameConstants.GetEmotionEffects(emotion)
    local emotionInfo = GameConstants.EMOTIONS[emotion]
    return emotionInfo and emotionInfo.effects or {}
end

function GameConstants.IsValidRealm(realmType, level)
    if realmType == "Cultivation" then
        return GameConstants.CULTIVATION_REALMS[level] ~= nil
    elseif realmType == "Martial" then
        return GameConstants.MARTIAL_REALMS[level] ~= nil
    end
    return false
end

function GameConstants.GetMaxQi(cultivationLevel)
    local realmInfo = GameConstants.CULTIVATION_REALMS[cultivationLevel]
    return realmInfo and realmInfo.maxQi or 0
end

function GameConstants.GetLifespan(cultivationLevel)
    local realmInfo = GameConstants.CULTIVATION_REALMS[cultivationLevel]
    return realmInfo and realmInfo.lifespan or 80
end

return GameConstants

