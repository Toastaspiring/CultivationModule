--[[
    CultivationSystem.lua
    Handles all cultivation-related mechanics including qi gathering, realm advancement,
    spiritual energy manipulation, and heavenly tribulations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Import shared modules
local GameConstants = require(ReplicatedStorage.Shared.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local CultivationSystem = {}
CultivationSystem.__index = CultivationSystem

-- Active cultivation sessions
local activeSessions = {}

-- Spiritual energy nodes in the world
local spiritualNodes = {}

-- Heavenly tribulation events
local activeTribulations = {}

function CultivationSystem.new()
    local self = setmetatable({}, CultivationSystem)
    
    -- Initialize spiritual energy nodes
    self:InitializeSpiritualNodes()
    
    -- Set up remote event handlers
    self:SetupRemoteEvents()
    
    return self
end

function CultivationSystem:InitializePlayer(player, playerData)
    print("Initializing cultivation system for player:", player.Name)
    
    -- Set up player's cultivation data if not exists
    if not playerData.cultivation then
        playerData.cultivation = {
            currentQi = playerData.resources.qi or 100,
            maxQi = GameConstants.GetMaxQi(playerData.cultivationRealm),
            qiPurity = 1.0,
            cultivationProgress = 0,
            breakthroughAttempts = 0,
            lastCultivationTime = 0,
            techniques = {},
            formations = {},
            spiritualRoots = {
                wood = 0,
                fire = 0,
                earth = 0,
                metal = 0,
                water = 0
            },
            tribulationsPassed = 0,
            cultivationMethod = "Basic Qi Gathering"
        }
    end
    
    -- Send initial cultivation data to client
    RemoteEvents.FireClient("CultivationProgress", player, playerData.cultivation)
end

function CultivationSystem:CleanupPlayer(player)
    local userId = player.UserId
    
    -- Stop any active cultivation session
    if activeSessions[userId] then
        self:StopCultivation(player)
    end
    
    -- Clean up any active tribulations
    if activeTribulations[userId] then
        self:EndTribulation(player, false)
    end
    
    print("Cleaned up cultivation system for player:", player.Name)
end

function CultivationSystem:SetupRemoteEvents()
    -- Start cultivation session
    RemoteEvents.ConnectEvent("StartCultivation", function(player, cultivationType, location)
        self:StartCultivation(player, cultivationType, location)
    end)
    
    -- Stop cultivation session
    RemoteEvents.ConnectEvent("StopCultivation", function(player)
        self:StopCultivation(player)
    end)
    
    -- Attempt breakthrough
    RemoteEvents.ConnectEvent("AttemptBreakthrough", function(player, useItems)
        self:AttemptBreakthrough(player, useItems)
    end)
    
    -- Gather spiritual energy from nodes
    RemoteEvents.ConnectEvent("GatherSpiritualEnergy", function(player, nodeId)
        self:GatherFromNode(player, nodeId)
    end)
    
    -- Use cultivation technique
    RemoteEvents.ConnectEvent("UseCultivationTechnique", function(player, techniqueId, target)
        self:UseTechnique(player, techniqueId, target)
    end)
end

function CultivationSystem:StartCultivation(player, cultivationType, location)
    local userId = player.UserId
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        warn("No player data found for cultivation start")
        return
    end
    
    -- Check if player can cultivate
    if playerData.spiritRoot == "None" and playerData.cultivationRealm == 0 then
        RemoteEvents.FireClient("SystemMessage", player, "You have no spirit root and cannot cultivate!")
        return
    end
    
    -- Check if already cultivating
    if activeSessions[userId] then
        RemoteEvents.FireClient("SystemMessage", player, "You are already cultivating!")
        return
    end
    
    -- Validate cultivation type
    local validTypes = {"Meditation", "QiGathering", "Formation", "PillRefining"}
    local isValidType = false
    for _, validType in ipairs(validTypes) do
        if cultivationType == validType then
            isValidType = true
            break
        end
    end
    
    if not isValidType then
        warn("Invalid cultivation type:", cultivationType)
        return
    end
    
    -- Calculate cultivation efficiency based on location and spirit root
    local efficiency = self:CalculateCultivationEfficiency(player, cultivationType, location)
    
    -- Create cultivation session
    local session = {
        player = player,
        type = cultivationType,
        location = location,
        startTime = tick(),
        efficiency = efficiency,
        qiGained = 0,
        progressGained = 0
    }
    
    activeSessions[userId] = session
    
    print("Started cultivation session for", player.Name, "- Type:", cultivationType, "Efficiency:", efficiency)
    
    -- Notify client
    RemoteEvents.FireClient("CultivationProgress", player, {
        active = true,
        type = cultivationType,
        efficiency = efficiency,
        startTime = session.startTime
    })
end

function CultivationSystem:StopCultivation(player)
    local userId = player.UserId
    local session = activeSessions[userId]
    
    if not session then
        return
    end
    
    -- Calculate final gains
    local duration = tick() - session.startTime
    local finalQiGain = session.qiGained
    local finalProgressGain = session.progressGained
    
    -- Apply gains to player data
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if playerData then
        playerData.cultivation.currentQi = math.min(
            playerData.cultivation.currentQi + finalQiGain,
            playerData.cultivation.maxQi
        )
        playerData.cultivation.cultivationProgress = playerData.cultivation.cultivationProgress + finalProgressGain
        playerData.resources.qi = playerData.cultivation.currentQi
        
        -- Update statistics
        playerData.stats.totalPlayTime = playerData.stats.totalPlayTime + duration
        
        gameManager:UpdatePlayerData(player, playerData)
    end
    
    -- Clean up session
    activeSessions[userId] = nil
    
    print("Stopped cultivation session for", player.Name, "- Qi gained:", finalQiGain, "Progress:", finalProgressGain)
    
    -- Notify client
    RemoteEvents.FireClient("CultivationProgress", player, {
        active = false,
        qiGained = finalQiGain,
        progressGained = finalProgressGain
    })
end

function CultivationSystem:CalculateCultivationEfficiency(player, cultivationType, location)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return 1.0
    end
    
    local baseEfficiency = 1.0
    
    -- Spirit root multiplier
    local spiritRootMultiplier = GameConstants.GetSpiritRootMultiplier(playerData.spiritRoot)
    baseEfficiency = baseEfficiency * spiritRootMultiplier
    
    -- Bloodline bonuses
    local bloodlineInfo = GameConstants.BLOODLINES[playerData.bloodline]
    if bloodlineInfo and bloodlineInfo.bonuses then
        if bloodlineInfo.bonuses.heavenAffinityBonus then
            baseEfficiency = baseEfficiency * (1 + bloodlineInfo.bonuses.heavenAffinityBonus)
        end
    end
    
    -- Location bonuses (spiritual energy nodes)
    local locationBonus = self:GetLocationBonus(location)
    baseEfficiency = baseEfficiency * locationBonus
    
    -- Cultivation type modifiers
    local typeModifiers = {
        Meditation = 1.0,
        QiGathering = 1.2,
        Formation = 0.8, -- Slower but more stable
        PillRefining = 1.5 -- Faster but requires resources
    }
    
    baseEfficiency = baseEfficiency * (typeModifiers[cultivationType] or 1.0)
    
    -- Time of day bonuses (certain times are better for cultivation)
    local timeBonus = self:GetTimeOfDayBonus()
    baseEfficiency = baseEfficiency * timeBonus
    
    -- Realm efficiency (higher realms are harder to progress)
    local realmPenalty = math.max(0.1, 1.0 - (playerData.cultivationRealm * 0.05))
    baseEfficiency = baseEfficiency * realmPenalty
    
    return math.max(0.1, baseEfficiency)
end

function CultivationSystem:GetLocationBonus(location)
    if not location then
        return 1.0
    end
    
    -- Check if location is near a spiritual node
    for _, node in pairs(spiritualNodes) do
        if node.active then
            local distance = (Vector3.new(location.x, location.y, location.z) - node.position).Magnitude
            if distance <= node.radius then
                return node.bonus
            end
        end
    end
    
    return 1.0
end

function CultivationSystem:GetTimeOfDayBonus()
    local timeOfDay = game.Lighting.TimeOfDay
    local hour = tonumber(string.sub(timeOfDay, 1, 2))
    
    -- Dawn and dusk are best for cultivation
    if hour >= 5 and hour <= 7 then
        return 1.3 -- Dawn bonus
    elseif hour >= 17 and hour <= 19 then
        return 1.3 -- Dusk bonus
    elseif hour >= 23 or hour <= 2 then
        return 1.2 -- Midnight bonus
    else
        return 1.0
    end
end

function CultivationSystem:Update(deltaTime)
    -- Update active cultivation sessions
    for userId, session in pairs(activeSessions) do
        self:UpdateCultivationSession(session, deltaTime)
    end
    
    -- Update spiritual nodes
    self:UpdateSpiritualNodes(deltaTime)
    
    -- Update active tribulations
    for userId, tribulation in pairs(activeTribulations) do
        self:UpdateTribulation(tribulation, deltaTime)
    end
end

function CultivationSystem:UpdateCultivationSession(session, deltaTime)
    local player = session.player
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Calculate qi gain per second
    local baseQiPerSecond = 10 * session.efficiency
    local qiGain = baseQiPerSecond * deltaTime
    
    -- Calculate progress gain per second
    local baseProgressPerSecond = 1 * session.efficiency
    local progressGain = baseProgressPerSecond * deltaTime
    
    -- Apply diminishing returns for long sessions
    local sessionDuration = tick() - session.startTime
    local diminishingFactor = math.max(0.1, 1.0 - (sessionDuration / 3600)) -- Reduces over 1 hour
    
    qiGain = qiGain * diminishingFactor
    progressGain = progressGain * diminishingFactor
    
    -- Update session totals
    session.qiGained = session.qiGained + qiGain
    session.progressGained = session.progressGained + progressGain
    
    -- Send periodic updates to client (every 5 seconds)
    if sessionDuration % 5 < deltaTime then
        RemoteEvents.FireClient("QiUpdate", player, {
            currentQi = playerData.cultivation.currentQi + session.qiGained,
            qiGained = qiGain,
            progressGained = progressGain,
            efficiency = session.efficiency * diminishingFactor
        })
    end
end

function CultivationSystem:AttemptBreakthrough(player, useItems)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        warn("No player data found for breakthrough attempt")
        return
    end
    
    local currentRealm = playerData.cultivationRealm
    local nextRealm = currentRealm + 1
    
    -- Check if next realm exists
    if not GameConstants.CULTIVATION_REALMS[nextRealm] then
        RemoteEvents.FireClient("SystemMessage", player, "You have reached the highest cultivation realm!")
        return
    end
    
    -- Check if player has enough progress
    local requiredProgress = GameConstants.GetExperienceRequired(currentRealm)
    if playerData.cultivation.cultivationProgress < requiredProgress then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient cultivation progress for breakthrough!")
        return
    end
    
    -- Check daily breakthrough limit
    local today = math.floor(tick() / 86400)
    local lastBreakthroughDay = math.floor((playerData.cultivation.lastBreakthroughTime or 0) / 86400)
    local todayAttempts = playerData.cultivation.todayBreakthroughAttempts or 0
    
    if lastBreakthroughDay < today then
        todayAttempts = 0
    end
    
    if todayAttempts >= GameConstants.PROGRESSION.MAX_DAILY_BREAKTHROUGHS then
        RemoteEvents.FireClient("SystemMessage", player, "You have reached the daily breakthrough limit!")
        return
    end
    
    -- Calculate breakthrough chance
    local baseChance = GameConstants.GetBreakthroughChance(playerData.cultivation.breakthroughAttempts)
    local finalChance = baseChance
    
    -- Apply item bonuses
    if useItems and useItems.breakthroughPill then
        local pillInfo = GameConstants.PILLS.BreakthroughPill
        if pillInfo and pillInfo.effects.breakthroughChance then
            finalChance = finalChance + pillInfo.effects.breakthroughChance
            -- Remove pill from inventory (would need inventory system)
        end
    end
    
    -- Spirit root bonus
    local spiritRootMultiplier = GameConstants.GetSpiritRootMultiplier(playerData.spiritRoot)
    finalChance = finalChance * spiritRootMultiplier
    
    -- Clamp chance between 5% and 95%
    finalChance = math.max(0.05, math.min(0.95, finalChance))
    
    -- Attempt breakthrough
    local success = math.random() < finalChance
    
    -- Update attempt counters
    playerData.cultivation.breakthroughAttempts = playerData.cultivation.breakthroughAttempts + 1
    playerData.cultivation.todayBreakthroughAttempts = todayAttempts + 1
    playerData.cultivation.lastBreakthroughTime = tick()
    
    if success then
        -- Successful breakthrough
        playerData.cultivationRealm = nextRealm
        playerData.cultivation.cultivationProgress = 0
        playerData.cultivation.breakthroughAttempts = 0
        playerData.cultivation.maxQi = GameConstants.GetMaxQi(nextRealm)
        
        -- Update statistics
        playerData.stats.breakthroughsAchieved = playerData.stats.breakthroughsAchieved + 1
        
        -- Trigger heavenly tribulation for higher realms
        if nextRealm >= 4 then -- Core Formation and above
            self:TriggerHeavenlyTribulation(player, nextRealm)
        end
        
        print("Breakthrough successful for", player.Name, "- New realm:", nextRealm)
        
        RemoteEvents.FireClient("BreakthroughResult", player, {
            success = true,
            newRealm = nextRealm,
            realmName = GameConstants.CULTIVATION_REALMS[nextRealm].name,
            tribulation = nextRealm >= 4
        })
        
        -- Notify all players of major breakthroughs
        if nextRealm >= 7 then -- Four-Axis and above
            RemoteEvents.FireAllClients("SystemMessage", player.Name .. " has broken through to " .. GameConstants.CULTIVATION_REALMS[nextRealm].name .. "!")
        end
    else
        -- Failed breakthrough
        local penalty = 0.1 -- Lose 10% of progress
        playerData.cultivation.cultivationProgress = playerData.cultivation.cultivationProgress * (1 - penalty)
        
        print("Breakthrough failed for", player.Name, "- Attempts:", playerData.cultivation.breakthroughAttempts)
        
        RemoteEvents.FireClient("BreakthroughResult", player, {
            success = false,
            penalty = penalty,
            attemptsRemaining = GameConstants.PROGRESSION.MAX_DAILY_BREAKTHROUGHS - (todayAttempts + 1)
        })
    end
    
    gameManager:UpdatePlayerData(player, playerData)
end

function CultivationSystem:TriggerHeavenlyTribulation(player, realm)
    local userId = player.UserId
    
    -- Don't trigger if already in tribulation
    if activeTribulations[userId] then
        return
    end
    
    local tribulation = {
        player = player,
        realm = realm,
        startTime = tick(),
        duration = 300, -- 5 minutes
        waves = {},
        currentWave = 0,
        completed = false,
        failed = false
    }
    
    -- Generate tribulation waves based on realm
    local waveCount = math.min(9, realm - 1) -- Max 9 waves
    for i = 1, waveCount do
        table.insert(tribulation.waves, {
            waveNumber = i,
            power = realm * 100 * i,
            duration = 30,
            type = i % 3 == 0 and "Lightning" or (i % 2 == 0 and "Thunder" or "Wind")
        })
    end
    
    activeTribulations[userId] = tribulation
    
    print("Heavenly tribulation triggered for", player.Name, "- Realm:", realm, "Waves:", waveCount)
    
    RemoteEvents.FireClient("HeavenlyTribulation", player, {
        realm = realm,
        waves = tribulation.waves,
        duration = tribulation.duration
    })
end

function CultivationSystem:UpdateTribulation(tribulation, deltaTime)
    local currentTime = tick()
    local elapsed = currentTime - tribulation.startTime
    
    -- Check if tribulation has timed out
    if elapsed > tribulation.duration then
        self:EndTribulation(tribulation.player, false)
        return
    end
    
    -- Progress through waves
    local waveInterval = tribulation.duration / #tribulation.waves
    local expectedWave = math.floor(elapsed / waveInterval) + 1
    
    if expectedWave > tribulation.currentWave and expectedWave <= #tribulation.waves then
        tribulation.currentWave = expectedWave
        local wave = tribulation.waves[expectedWave]
        
        print("Tribulation wave", expectedWave, "for", tribulation.player.Name)
        
        RemoteEvents.FireClient("TribulationWave", tribulation.player, {
            waveNumber = expectedWave,
            wave = wave,
            timeRemaining = tribulation.duration - elapsed
        })
    end
    
    -- Check if all waves completed
    if tribulation.currentWave >= #tribulation.waves and not tribulation.completed then
        self:EndTribulation(tribulation.player, true)
    end
end

function CultivationSystem:EndTribulation(player, success)
    local userId = player.UserId
    local tribulation = activeTribulations[userId]
    
    if not tribulation then
        return
    end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if success then
        -- Successful tribulation
        playerData.cultivation.tribulationsPassed = playerData.cultivation.tribulationsPassed + 1
        
        -- Grant rewards based on realm
        local rewards = {
            qi = tribulation.realm * 1000,
            experience = tribulation.realm * 500,
            reputation = tribulation.realm * 100
        }
        
        playerData.cultivation.currentQi = math.min(
            playerData.cultivation.currentQi + rewards.qi,
            playerData.cultivation.maxQi
        )
        playerData.experience = playerData.experience + rewards.experience
        playerData.resources.reputation = playerData.resources.reputation + rewards.reputation
        
        print("Tribulation successful for", player.Name, "- Rewards:", rewards.qi, "qi,", rewards.experience, "exp")
        
        RemoteEvents.FireClient("TribulationResult", player, {
            success = true,
            rewards = rewards
        })
    else
        -- Failed tribulation
        local penalty = {
            qi = playerData.cultivation.currentQi * 0.5, -- Lose 50% qi
            cultivation = playerData.cultivation.cultivationProgress * 0.3 -- Lose 30% progress
        }
        
        playerData.cultivation.currentQi = playerData.cultivation.currentQi - penalty.qi
        playerData.cultivation.cultivationProgress = playerData.cultivation.cultivationProgress - penalty.cultivation
        
        -- Prevent realm regression
        playerData.cultivation.currentQi = math.max(0, playerData.cultivation.currentQi)
        playerData.cultivation.cultivationProgress = math.max(0, playerData.cultivation.cultivationProgress)
        
        print("Tribulation failed for", player.Name, "- Penalties applied")
        
        RemoteEvents.FireClient("TribulationResult", player, {
            success = false,
            penalties = penalty
        })
    end
    
    activeTribulations[userId] = nil
    gameManager:UpdatePlayerData(player, playerData)
end

function CultivationSystem:InitializeSpiritualNodes()
    -- Create spiritual energy nodes throughout the world
    local nodeLocations = {
        {position = Vector3.new(0, 0, 0), radius = 100, bonus = 1.5, type = "Balanced"},
        {position = Vector3.new(500, 0, 500), radius = 80, bonus = 2.0, type = "Fire"},
        {position = Vector3.new(-500, 0, 500), radius = 80, bonus = 2.0, type = "Water"},
        {position = Vector3.new(500, 0, -500), radius = 80, bonus = 2.0, type = "Earth"},
        {position = Vector3.new(-500, 0, -500), radius = 80, bonus = 2.0, type = "Metal"},
        {position = Vector3.new(0, 0, 1000), radius = 120, bonus = 3.0, type = "Wood"},
    }
    
    for i, nodeData in ipairs(nodeLocations) do
        spiritualNodes[i] = {
            id = i,
            position = nodeData.position,
            radius = nodeData.radius,
            bonus = nodeData.bonus,
            type = nodeData.type,
            active = true,
            energy = 1000,
            maxEnergy = 1000,
            regenerationRate = 10, -- per second
            lastHarvest = {}
        }
    end
    
    print("Initialized", #spiritualNodes, "spiritual energy nodes")
end

function CultivationSystem:UpdateSpiritualNodes(deltaTime)
    for _, node in pairs(spiritualNodes) do
        if node.active then
            -- Regenerate energy
            node.energy = math.min(node.maxEnergy, node.energy + node.regenerationRate * deltaTime)
            
            -- Clear old harvest records (24 hour cooldown)
            local currentTime = tick()
            for userId, lastTime in pairs(node.lastHarvest) do
                if currentTime - lastTime > 86400 then
                    node.lastHarvest[userId] = nil
                end
            end
        end
    end
end

function CultivationSystem:GatherFromNode(player, nodeId)
    local node = spiritualNodes[nodeId]
    if not node or not node.active then
        RemoteEvents.FireClient("SystemMessage", player, "Invalid spiritual node!")
        return
    end
    
    local userId = player.UserId
    local currentTime = tick()
    
    -- Check cooldown
    if node.lastHarvest[userId] and currentTime - node.lastHarvest[userId] < 86400 then
        local remaining = 86400 - (currentTime - node.lastHarvest[userId])
        RemoteEvents.FireClient("SystemMessage", player, "Node cooldown: " .. math.floor(remaining / 3600) .. " hours remaining")
        return
    end
    
    -- Check if node has energy
    if node.energy < 100 then
        RemoteEvents.FireClient("SystemMessage", player, "Spiritual node is depleted!")
        return
    end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Calculate harvest amount based on player's cultivation level
    local baseHarvest = 100
    local realmMultiplier = 1 + (playerData.cultivationRealm * 0.2)
    local spiritRootMultiplier = GameConstants.GetSpiritRootMultiplier(playerData.spiritRoot)
    
    local harvestAmount = math.floor(baseHarvest * realmMultiplier * spiritRootMultiplier)
    harvestAmount = math.min(harvestAmount, node.energy)
    
    -- Apply harvest
    node.energy = node.energy - harvestAmount
    node.lastHarvest[userId] = currentTime
    
    playerData.cultivation.currentQi = math.min(
        playerData.cultivation.currentQi + harvestAmount,
        playerData.cultivation.maxQi
    )
    playerData.resources.qi = playerData.cultivation.currentQi
    
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "harvested", harvestAmount, "qi from node", nodeId)
    
    RemoteEvents.FireClient("ResourceUpdate", player, {
        type = "qi",
        amount = harvestAmount,
        total = playerData.cultivation.currentQi
    })
end

function CultivationSystem:UseTechnique(player, techniqueId, target)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Check if player knows the technique
    local hasTechnique = false
    for _, technique in ipairs(playerData.cultivation.techniques) do
        if technique.id == techniqueId then
            hasTechnique = true
            break
        end
    end
    
    if not hasTechnique then
        RemoteEvents.FireClient("SystemMessage", player, "You don't know this technique!")
        return
    end
    
    -- Implement technique effects based on techniqueId
    -- This would be expanded with specific technique implementations
    
    print("Player", player.Name, "used cultivation technique", techniqueId)
end

return CultivationSystem

