--[[
    GameConstants.lua
    Central configuration and constants for a generic cultivation game template.
    This file is the primary place to customize your game's content and balance.
    It is shared between the client and server for consistency.
]]

local GameConstants = {}

--------------------------------------------------------------------------------
-- GAME INFO
--------------------------------------------------------------------------------
GameConstants.VERSION = "1.0.0"
GameConstants.DATA_VERSION = 1.0

--------------------------------------------------------------------------------
-- PROGRESSION PATHS
-- Define the different progression paths for your game.
-- You can have one or more paths (e.g., Cultivation, Martial Arts, Demonic Path).
-- Each path has a series of realms or levels.
--------------------------------------------------------------------------------
GameConstants.PROGRESSION_PATHS = {
    -- Path 1: A typical spiritual energy cultivation path.
    PATH_1 = {
        Name = "Cultivation", -- The in-game name for this path.
        Realms = {
            [0] = {name = "Mortal", description = "An ordinary person with no special abilities.", lifespan = 80, maxResource = 0},
            [1] = {name = "Realm 1: Foundation", description = "Begin sensing and absorbing energy.", lifespan = 120, maxResource = 1000},
            [2] = {name = "Realm 2: Purification", description = "Refine and purify absorbed energy.", lifespan = 150, maxResource = 2500},
            [3] = {name = "Realm 3: Core Building", description = "Construct a stable energy core.", lifespan = 300, maxResource = 5000},
            [4] = {name = "Realm 4: Core Formation", description = "Solidify the energy core.", lifespan = 600, maxResource = 10000},
            [5] = {name = "Realm 5: Soul Development", description = "Develop spiritual consciousness from the core.", lifespan = 1200, maxResource = 25000},
            [6] = {name = "Realm 6: Transcendence", description = "Transcend mortal limitations.", lifespan = 2400, maxResource = 50000},
            -- Add as many realms as you need...
        }
    },
    -- Path 2: A body-based or martial arts path.
    PATH_2 = {
        Name = "Martial Arts", -- The in-game name for this path.
        Realms = {
            [0] = {name = "Untrained", description = "No formal training.", abilities = {}},
            [1] = {name = "Rank 1: Initiate", description = "Basic techniques.", abilities = {"Basic Combat"}},
            [2] = {name = "Rank 2: Adept", description = "Proficient practitioner.", abilities = {"Basic Combat", "Internal Energy"}},
            [3] = {name = "Rank 3: Master", description = "Master of the art.", abilities = {"Basic Combat", "Internal Energy", "Energy Projection"}},
            [4] = {name = "Rank 4: Grandmaster", description = "Can perceive opponent's intent.", abilities = {"Intent Reading", "Advanced Techniques"}},
            -- Add as many ranks as you need...
        }
    }
}

--------------------------------------------------------------------------------
-- TALENTS AND TRAITS
-- Define inherent player characteristics that affect gameplay.
--------------------------------------------------------------------------------
-- TALENTS (e.g., Spirit Roots): Aptitude for a specific progression path.
GameConstants.TALENTS = {
    -- This key (e.g., "TALENT_PATH_1") should correspond to a key in PROGRESSION_PATHS.
    PATH_1 = {
        Tiers = {
            None = {name = "None", multiplier = 0, description = "No aptitude for this path."},
            Low = {name = "Low", multiplier = 1.2, description = "Basic aptitude."},
            Medium = {name = "Medium", multiplier = 1.5, description = "Good aptitude."},
            High = {name = "High", multiplier = 2.0, description = "Excellent aptitude."},
            Legendary = {name = "Legendary", multiplier = 3.0, description = "Once-in-a-generation aptitude."}
        }
    }
}

-- BLOODLINES: Inherited traits with bonuses and restrictions.
GameConstants.BLOODLINES = {
    Human = {
        name = "Human",
        description = "Standard human bloodline.",
        bonuses = {},
        restrictions = {}
    },
    Beastkin = {
        name = "Beastkin",
        description = "Descendant of powerful beasts.",
        bonuses = {physicalPower = 1.3, earthAffinityBonus = 0.2},
        restrictions = {heavenAffinityPenalty = 0.1}
    },
    -- Add more bloodlines as needed.
}

-- SPECIAL ABILITIES (e.g., Emotions for Martial Arts)
GameConstants.SPECIAL_ABILITIES = {
    -- This key should correspond to a system (e.g., Martial Arts).
    PATH_2_ABILITIES = {
        Joy = {name = "Joy", color = Color3.fromRGB(255, 215, 0), effects = {speed = 1.2, agility = 1.3}},
        Anger = {name = "Anger", color = Color3.fromRGB(255, 0, 0), effects = {damage = 1.4, aggression = 1.5}},
        -- Add more abilities as needed.
    }
}

--------------------------------------------------------------------------------
-- RESOURCES AND ITEMS
--------------------------------------------------------------------------------
-- Define all in-game resources and currencies.
GameConstants.RESOURCES = {
    PrimaryEnergy = {name = "Qi", description = "The primary energy for the main cultivation path.", maxStack = math.huge, category = "Energy"},
    Currency = {name = "Spirit Stones", description = "Crystallized energy used as currency.", maxStack = 999999, category = "Currency"},
    SectCurrency = {name = "Contribution Points", description = "Points earned through sect activities.", maxStack = 999999, category = "Currency"},
    SocialCurrency = {name = "Reputation", description = "Standing in the game world.", maxStack = math.huge, category = "Social"}
}

-- Define all consumable items like herbs and pills.
GameConstants.ITEMS = {
    Herbs = {
        Herb1 = {name = "Spirit Grass", description = "Common herb that slightly increases primary energy.", rarity = "Common", effects = {PrimaryEnergy = 10}, growthTime = 3600},
        Herb2 = {name = "Blood Lotus", description = "Rare herb that enhances physical strength.", rarity = "Rare", effects = {physicalPower = 0.1, PrimaryEnergy = 50}, growthTime = 21600},
    },
    Pills = {
        Pill1 = {name = "Energy Pill", description = "Helps with energy cultivation.", rarity = "Common", effects = {energyGainMultiplier = 1.5, duration = 3600}, ingredients = {"Herb1", "Herb1"}},
        Pill2 = {name = "Breakthrough Pill", description = "Assists with realm advancement.", rarity = "Rare", effects = {breakthroughChanceBonus = 0.2}, ingredients = {"Herb2", "Herb1", "Herb1"}},
    }
}

--------------------------------------------------------------------------------
-- GAME SYSTEMS CONFIGURATION
--------------------------------------------------------------------------------

-- CULTIVATION/TRAINING SYSTEM
GameConstants.CULTIVATION = {
    -- Define different types of training/cultivation activities.
    TYPES = {
        Meditation = {name = "Meditation", efficiency = 1.0, description = "Basic, stable cultivation."},
        EnergyGathering = {name = "Energy Gathering", efficiency = 1.2, description = "Faster, but less stable."},
        Formation = {name = "Formation Training", efficiency = 0.8, description = "Slow, but improves mastery."},
        Alchemy = {name = "Pill Refining", efficiency = 1.5, description = "Fastest, but requires resources."}
    },
    -- Time of day bonuses for cultivation.
    TIME_BONUSES = {
        Dawn = {startHour = 5, endHour = 7, multiplier = 1.3},
        Dusk = {startHour = 17, endHour = 19, multiplier = 1.3},
        Midnight = {startHour = 23, endHour = 2, multiplier = 1.2}
    },
    -- Base gain rates per second.
    BASE_GAIN_RATES = {
        ENERGY = 10,
        PROGRESS = 1
    },
    -- Diminishing returns for long sessions (reduces gain over 1 hour).
    DIMINISHING_RETURNS = {
        DURATION = 3600, -- seconds
        MIN_FACTOR = 0.1
    },
    -- Penalty for being in a higher realm (makes progression harder).
    REALM_DIFFICULTY_PENALTY = 0.05 -- Multiplied by realm level.
}

-- MARTIAL ARTS/TRAINING SYSTEM
GameConstants.MARTIAL_ARTS = {
    -- Define different types of training activities for the second progression path.
    TRAINING_TYPES = {
        BasicCombat = {name = "Basic Combat", efficiency = 1.0, requiredRealm = 1},
        IntentTraining = {name = "Intent Training", efficiency = 0.8, requiredRealm = 4},
        EmotionMastery = {name = "Emotion Mastery", efficiency = 0.6, requiredRealm = 5},
    },
    -- Bonus to training efficiency based on the player's martial realm level.
    REALM_EFFICIENCY_BONUS = 0.1,
    -- Base rate of progress gain per second during training.
    BASE_PROGRESS_GAIN = 5,
    -- Diminishing returns for long training sessions.
    DIMINISHING_RETURNS = {
        DURATION = 7200, -- seconds
        MIN_FACTOR = 0.1
    },
    -- Requirements for a player to change their emotion state.
    EMOTION_MASTERY_REQUIREMENT = {
        mastery = 10,
        realm = 5
    },
    -- Locations in the world that provide training bonuses.
    TRAINING_GROUNDS = {
        {position = Vector3.new(200, 0, 200), radius = 50, bonus = 1.2, type = "Basic"},
        {position = Vector3.new(-200, 0, 200), radius = 50, bonus = 1.5, type = "Intent"},
    }
}

-- PROGRESSION SYSTEM
GameConstants.PROGRESSION = {
    BASE_EXPERIENCE_REQUIRED = 1000,
    EXPERIENCE_SCALING = 1.5, -- Required XP = BASE * (SCALING ^ currentLevel)
    BREAKTHROUGH_BASE_CHANCE = 0.1,
    BREAKTHROUGH_FAILURE_PENALTY = 0.9, -- Chance multiplies by this on each failure.
    MAX_DAILY_BREAKTHROUGHS = 3,
    BREAKTHROUGH_FAILURE_PROGRESS_LOSS = 0.1, -- Lose 10% of progress on failure.
}

-- TRIBULATION SYSTEM (Challenging events on breakthrough)
GameConstants.TRIBULATIONS = {
    TRIGGER_REALM = 4, -- Realm at which tribulations start.
    BASE_DURATION = 300, -- seconds
    WAVE_COUNT_MAX = 9,
    -- Define wave types. The system will cycle through these.
    WAVE_TYPES = {"Lightning", "Thunder", "Wind", "Fire", "Ice"},
    -- Reward and penalty multipliers based on the realm level.
    REWARD_MULTIPLIERS = {
        ENERGY = 1000,
        EXPERIENCE = 500,
        REPUTATION = 100
    },
    PENALTY_MULTIPLIERS = {
        ENERGY_LOSS = 0.5, -- Lose 50% of current energy.
        PROGRESS_LOSS = 0.3 -- Lose 30% of current progress.
    }
}

-- WORLD NODES (e.g., Spiritual energy hotspots)
GameConstants.WORLD_NODES = {
    HARVEST_COOLDOWN = 86400, -- 24 hours
    BASE_HARVEST_AMOUNT = 100,
    REALM_HARVEST_MULTIPLIER = 0.2, -- Bonus harvest per realm level.
    DEPLETED_MESSAGE = "This node is temporarily depleted.",
    -- Define the locations and properties of nodes in the world.
    NODE_LOCATIONS = {
        {position = Vector3.new(0, 0, 0), radius = 100, bonus = 1.5, type = "Balanced"},
        {position = Vector3.new(500, 0, 500), radius = 80, bonus = 2.0, type = "Fire"},
        {position = Vector3.new(-500, 0, 500), radius = 80, bonus = 2.0, type = "Water"},
        -- Add more nodes as needed.
    }
}

-- COMBAT SYSTEM
GameConstants.COMBAT = {
    BASE_DAMAGE = 100,
    CRITICAL_MULTIPLIER = 2.0,
    DODGE_CHANCE_BASE = 0.05,
    BLOCK_CHANCE_BASE = 0.1,
}

-- SECT/FACTION SYSTEM
GameConstants.SECTS = {
    MIN_MEMBERS_TO_CREATE = 5,
    MAX_MEMBERS_PER_SECT = 1000,
    SECT_WAR_COOLDOWN = 86400, -- 24 hours
}

-- WORLD EVENTS
GameConstants.WORLD_EVENTS = {
    Event1 = {
        name = "Energy Convergence",
        type = "cultivation_boost",
        duration = 3600,
        cooldown = 86400,
        spawnChance = 0.1,
        effect = {cultivation_speed = 1.5},
        rewards = {}
    },
    Event2 = {
        name = "Sect War Declaration Period",
        type = "pvp_event",
        duration = 7200,
        cooldown = 172800,
        spawnChance = 0.05,
        effect = {sect_war_enabled = true},
        rewards = {}
    },
    Event3 = {
        name = "Rare Resource Spawn",
        type = "resource_event",
        duration = 1800,
        cooldown = 43200,
        spawnChance = 0.2,
        effect = {rare_resource_multiplier = 3},
        rewards = {
            items = {"Herb2"},
            currency = {min = 100, max = 1000}
        }
    }
}

-- ECONOMY
GameConstants.ECONOMY = {
    STARTING_CURRENCY = 100,
    DAILY_LOGIN_BONUS = 50,
    TRADE_TAX_RATE = 0.05,
}

-- PVP
GameConstants.PVP = {
    SAFE_ZONE_RADIUS = 200,
    PVP_COOLDOWN = 300, -- 5 minutes after combat
    REPUTATION_LOSS_ON_DEATH = 100,
    ITEM_DROP_CHANCE_ON_DEATH = 0.1,
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS (These should not need customization)
--------------------------------------------------------------------------------

function GameConstants.GetRealmInfo(pathName, level)
    for _, pathData in pairs(GameConstants.PROGRESSION_PATHS) do
        if pathData.Name == pathName then
            return pathData.Realms[level]
        end
    end
    return nil
end

function GameConstants.GetExperienceRequired(currentLevel)
    return math.floor(GameConstants.PROGRESSION.BASE_EXPERIENCE_REQUIRED * (GameConstants.PROGRESSION.EXPERIENCE_SCALING ^ currentLevel))
end

function GameConstants.GetBreakthroughChance(attempts)
    local baseChance = GameConstants.PROGRESSION.BREAKTHROUGH_BASE_CHANCE
    return math.min(0.95, baseChance * (GameConstants.PROGRESSION.BREAKTHROUGH_FAILURE_PENALTY ^ attempts))
end

function GameConstants.GetTalentMultiplier(pathName, talentName)
    local pathTalents = GameConstants.TALENTS[pathName]
    if pathTalents then
        for _, talentData in pairs(pathTalents.Tiers) do
            if talentData.name == talentName then
                return talentData.multiplier
            end
        end
    end
    return 1.0
end

return GameConstants
