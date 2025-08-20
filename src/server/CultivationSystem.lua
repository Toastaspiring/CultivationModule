--[[
    CultivationSystem.lua
    Handles all cultivation-related mechanics. This system is now driven by GameConstants.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import shared modules
local GameConstants = require(ReplicatedStorage.Shared.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local CultivationSystem = {}
CultivationSystem.__index = CultivationSystem

-- Active state tables
local activeSessions = {}
local spiritualNodes = {}
local activeTribulations = {}

function CultivationSystem.new()
    local self = setmetatable({}, CultivationSystem)
    self:InitializeSpiritualNodes()
    self:SetupRemoteEvents()
    return self
end

function CultivationSystem:InitializePlayer(player, playerData)
    print("Initializing cultivation system for player:", player.Name)
    if not playerData.cultivation then
        local pathInfo = GameConstants.PROGRESSION_PATHS.PATH_1
        local realmInfo = pathInfo.Realms[playerData.realm_path1 or 0]

        playerData.cultivation = {
            currentQi = playerData.resources.PrimaryEnergy or 0,
            maxQi = realmInfo.maxResource,
            qiPurity = 1.0,
            cultivationProgress = 0,
            breakthroughAttempts = 0,
            lastCultivationTime = 0,
            techniques = {},
            formations = {},
            tribulationsPassed = 0,
            cultivationMethod = "Meditation" -- Default method
        }
    end
    RemoteEvents.FireClient("CultivationProgress", player, playerData.cultivation)
end

function CultivationSystem:CleanupPlayer(player)
    local userId = player.UserId
    if activeSessions[userId] then self:StopCultivation(player) end
    if activeTribulations[userId] then self:EndTribulation(player, false) end
    print("Cleaned up cultivation system for player:", player.Name)
end

function CultivationSystem:SetupRemoteEvents()
    RemoteEvents.ConnectEvent("StartCultivation", function(player, cultivationType, location)
        self:StartCultivation(player, cultivationType, location)
    end)
    RemoteEvents.ConnectEvent("StopCultivation", function(player)
        self:StopCultivation(player)
    end)
    RemoteEvents.ConnectEvent("AttemptBreakthrough", function(player, useItems)
        self:AttemptBreakthrough(player, useItems)
    end)
end

function CultivationSystem:StartCultivation(player, cultivationType, location)
    local userId = player.UserId
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then return end
    
    local talentInfo = GameConstants.TALENTS.PATH_1.Tiers[playerData.talent]
    if talentInfo and talentInfo.multiplier == 0 and playerData.cultivationRealm == 0 then
        RemoteEvents.FireClient("SystemMessage", player, "You have no talent for this path and cannot cultivate!")
        return
    end
    
    if activeSessions[userId] then
        RemoteEvents.FireClient("SystemMessage", player, "You are already cultivating!")
        return
    end
    
    if not GameConstants.CULTIVATION.TYPES[cultivationType] then
        warn("Invalid cultivation type:", cultivationType)
        return
    end
    
    local efficiency = self:CalculateCultivationEfficiency(player, cultivationType, location)
    
    activeSessions[userId] = {
        player = player,
        type = cultivationType,
        startTime = tick(),
        efficiency = efficiency,
        qiGained = 0,
        progressGained = 0
    }
    
    RemoteEvents.FireClient("CultivationProgress", player, { active = true, type = cultivationType, efficiency = efficiency })
end

function CultivationSystem:StopCultivation(player)
    local userId = player.UserId
    local session = activeSessions[userId]
    if not session then return end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if playerData then
        playerData.cultivation.currentQi = math.min(playerData.cultivation.currentQi + session.qiGained, playerData.cultivation.maxQi)
        playerData.cultivation.cultivationProgress = playerData.cultivation.cultivationProgress + session.progressGained
        playerData.resources.PrimaryEnergy = playerData.cultivation.currentQi
        gameManager:UpdatePlayerData(player, playerData)
    end
    
    activeSessions[userId] = nil
    RemoteEvents.FireClient("CultivationProgress", player, { active = false, qiGained = session.qiGained })
end

function CultivationSystem:CalculateCultivationEfficiency(player, cultivationType, location)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    if not playerData then return 1.0 end
    
    local baseEfficiency = 1.0
    
    -- Talent multiplier
    local talentInfo = GameConstants.TALENTS.PATH_1.Tiers[playerData.talent_path1]
    baseEfficiency = baseEfficiency * (talentInfo and talentInfo.multiplier or 1.0)
    
    -- Bloodline bonuses
    local bloodlineInfo = GameConstants.BLOODLINES[playerData.bloodline]
    if bloodlineInfo and bloodlineInfo.bonuses.heavenAffinityBonus then
        baseEfficiency = baseEfficiency * (1 + bloodlineInfo.bonuses.heavenAffinityBonus)
    end
    
    -- Location bonus
    baseEfficiency = baseEfficiency * self:GetLocationBonus(location)
    
    -- Cultivation type modifier
    local typeInfo = GameConstants.CULTIVATION.TYPES[cultivationType]
    baseEfficiency = baseEfficiency * (typeInfo and typeInfo.efficiency or 1.0)
    
    -- Time of day bonus
    baseEfficiency = baseEfficiency * self:GetTimeOfDayBonus()
    
    -- Realm difficulty penalty
    local realmPenalty = math.max(0.1, 1.0 - (playerData.realm_path1 * GameConstants.CULTIVATION.REALM_DIFFICULTY_PENALTY))
    baseEfficiency = baseEfficiency * realmPenalty
    
    return math.max(0.1, baseEfficiency)
end

function CultivationSystem:GetLocationBonus(location)
    if not location then return 1.0 end
    for _, node in pairs(spiritualNodes) do
        if node.active and (location - node.position).Magnitude <= node.radius then
            return node.bonus
        end
    end
    return 1.0
end

function CultivationSystem:GetTimeOfDayBonus()
    local hour = tonumber(string.sub(game.Lighting.TimeOfDay, 1, 2))
    for _, bonusInfo in pairs(GameConstants.CULTIVATION.TIME_BONUSES) do
        if hour >= bonusInfo.startHour and hour <= bonusInfo.endHour then
            return bonusInfo.multiplier
        end
    end
    return 1.0
end

function CultivationSystem:Update(deltaTime)
    for userId, session in pairs(activeSessions) do self:UpdateCultivationSession(session, deltaTime) end
    for _, node in pairs(spiritualNodes) do self:UpdateSpiritualNode(node, deltaTime) end
    for userId, tribulation in pairs(activeTribulations) do self:UpdateTribulation(tribulation, deltaTime) end
end

function CultivationSystem:UpdateCultivationSession(session, deltaTime)
    local qiGain = GameConstants.CULTIVATION.BASE_GAIN_RATES.ENERGY * session.efficiency * deltaTime
    local progressGain = GameConstants.CULTIVATION.BASE_GAIN_RATES.PROGRESS * session.efficiency * deltaTime
    
    local diminishConfig = GameConstants.CULTIVATION.DIMINISHING_RETURNS
    local diminishingFactor = math.max(diminishConfig.MIN_FACTOR, 1.0 - ((tick() - session.startTime) / diminishConfig.DURATION))
    
    session.qiGained = session.qiGained + (qiGain * diminishingFactor)
    session.progressGained = session.progressGained + (progressGain * diminishingFactor)
end

function CultivationSystem:AttemptBreakthrough(player, useItems)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    if not playerData then return end
    
    local currentRealm = playerData.realm_path1
    local nextRealm = currentRealm + 1
    local pathInfo = GameConstants.PROGRESSION_PATHS.PATH_1
    
    if not pathInfo.Realms[nextRealm] then
        RemoteEvents.FireClient("SystemMessage", player, "You have reached the highest realm!")
        return
    end
    
    if playerData.cultivation.cultivationProgress < GameConstants.GetExperienceRequired(currentRealm) then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient progress for breakthrough!")
        return
    end
    
    -- Calculate breakthrough chance
    local finalChance = GameConstants.GetBreakthroughChance(playerData.cultivation.breakthroughAttempts)
    
    -- Apply item bonuses (example)
    if useItems and useItems.Pill2 then -- Assumes Pill2 is a breakthrough pill
        local pillInfo = GameConstants.ITEMS.Pills.Pill2
        finalChance = finalChance + (pillInfo.effects.breakthroughChanceBonus or 0)
    end
    
    local success = math.random() < finalChance
    
    playerData.cultivation.breakthroughAttempts = playerData.cultivation.breakthroughAttempts + 1
    
    if success then
        playerData.realm_path1 = nextRealm
        playerData.cultivation.cultivationProgress = 0
        playerData.cultivation.breakthroughAttempts = 0
        playerData.cultivation.maxQi = pathInfo.Realms[nextRealm].maxResource
        
        if nextRealm >= GameConstants.TRIBULATIONS.TRIGGER_REALM then
            self:TriggerHeavenlyTribulation(player, nextRealm)
        end
        
        RemoteEvents.FireClient("BreakthroughResult", player, { success = true, newRealm = pathInfo.Realms[nextRealm].name })
    else
        local penalty = GameConstants.PROGRESSION.BREAKTHROUGH_FAILURE_PROGRESS_LOSS
        playerData.cultivation.cultivationProgress = playerData.cultivation.cultivationProgress * (1 - penalty)
        RemoteEvents.FireClient("BreakthroughResult", player, { success = false, penalty = penalty })
    end
    
    gameManager:UpdatePlayerData(player, playerData)
end

function CultivationSystem:TriggerHeavenlyTribulation(player, realm)
    local userId = player.UserId
    if activeTribulations[userId] then return end
    
    local tribulation = {
        player = player,
        realm = realm,
        startTime = tick(),
        duration = GameConstants.TRIBULATIONS.BASE_DURATION,
        waves = {},
        currentWave = 0
    }
    
    local waveCount = math.min(GameConstants.TRIBULATIONS.WAVE_COUNT_MAX, realm - 1)
    for i = 1, waveCount do
        table.insert(tribulation.waves, {
            waveNumber = i,
            power = realm * 100 * i,
            type = GameConstants.TRIBULATIONS.WAVE_TYPES[((i-1) % #GameConstants.TRIBULATIONS.WAVE_TYPES) + 1]
        })
    end
    
    activeTribulations[userId] = tribulation
    RemoteEvents.FireClient("HeavenlyTribulation", player, { waves = tribulation.waves, duration = tribulation.duration })
end

function CultivationSystem:UpdateTribulation(tribulation, deltaTime)
    -- Simplified tribulation update logic
end

function CultivationSystem:EndTribulation(player, success)
    local userId = player.UserId
    local tribulation = activeTribulations[userId]
    if not tribulation then return end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if success then
        playerData.cultivation.tribulationsPassed = playerData.cultivation.tribulationsPassed + 1
        local rewards = {
            qi = tribulation.realm * GameConstants.TRIBULATIONS.REWARD_MULTIPLIERS.ENERGY,
            experience = tribulation.realm * GameConstants.TRIBULATIONS.REWARD_MULTIPLIERS.EXPERIENCE,
        }
        playerData.cultivation.currentQi = playerData.cultivation.currentQi + rewards.qi
        playerData.experience = playerData.experience + rewards.experience
        RemoteEvents.FireClient("TribulationResult", player, { success = true, rewards = rewards })
    else
        local penalties = {
            qi = playerData.cultivation.currentQi * GameConstants.TRIBULATIONS.PENALTY_MULTIPLIERS.ENERGY_LOSS,
            progress = playerData.cultivation.cultivationProgress * GameConstants.TRIBULATIONS.PENALTY_MULTIPLIERS.PROGRESS_LOSS,
        }
        playerData.cultivation.currentQi = playerData.cultivation.currentQi - penalties.qi
        playerData.cultivation.cultivationProgress = playerData.cultivation.cultivationProgress - penalties.progress
        RemoteEvents.FireClient("TribulationResult", player, { success = false, penalties = penalties })
    end
    
    activeTribulations[userId] = nil
    gameManager:UpdatePlayerData(player, playerData)
end

function CultivationSystem:InitializeSpiritualNodes()
    for i, nodeData in ipairs(GameConstants.WORLD_NODES.NODE_LOCATIONS) do
        spiritualNodes[i] = {
            id = i,
            position = nodeData.position,
            radius = nodeData.radius,
            bonus = nodeData.bonus,
            type = nodeData.type,
            active = true,
            energy = 1000,
            maxEnergy = 1000,
            regenerationRate = 10,
            lastHarvest = {}
        }
    end
end

function CultivationSystem:UpdateSpiritualNode(node, deltaTime)
    node.energy = math.min(node.maxEnergy, node.energy + node.regenerationRate * deltaTime)
end

function CultivationSystem:GatherFromNode(player, nodeId)
    local node = spiritualNodes[nodeId]
    if not node or not node.active then
        RemoteEvents.FireClient("SystemMessage", player, "Invalid spiritual node!")
        return
    end
    
    if node.energy < 100 then
        RemoteEvents.FireClient("SystemMessage", player, GameConstants.WORLD_NODES.DEPLETED_MESSAGE)
        return
    end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    if not playerData then return end
    
    local harvestAmount = GameConstants.WORLD_NODES.BASE_HARVEST_AMOUNT
    harvestAmount = harvestAmount * (1 + (playerData.realm_path1 * GameConstants.WORLD_NODES.REALM_HARVEST_MULTIPLIER))
    
    node.energy = node.energy - harvestAmount
    playerData.cultivation.currentQi = playerData.cultivation.currentQi + harvestAmount
    
    gameManager:UpdatePlayerData(player, playerData)
    RemoteEvents.FireClient("ResourceUpdate", player, { type = "PrimaryEnergy", amount = harvestAmount, total = playerData.cultivation.currentQi })
end

return CultivationSystem
