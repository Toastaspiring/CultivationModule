--[[
    MartialArtsSystem.lua
    Handles martial arts progression including intent visualization, emotion mastery,
    Gang Qi manipulation, and heart manifestation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Import shared modules
local GameConstants = require(ReplicatedStorage.Shared.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local MartialArtsSystem = {}
MartialArtsSystem.__index = MartialArtsSystem

-- Active training sessions
local activeTraining = {}

-- Intent visualization data
local intentVisualizations = {}

-- Gang Qi formations
local gangQiFormations = {}

-- Heart manifestations
local heartManifestations = {}

function MartialArtsSystem.new()
    local self = setmetatable({}, MartialArtsSystem)
    
    -- Set up remote event handlers
    self:SetupRemoteEvents()
    
    -- Initialize training grounds
    self:InitializeTrainingGrounds()
    
    return self
end

function MartialArtsSystem:InitializePlayer(player, playerData)
    print("Initializing martial arts system for player:", player.Name)
    
    -- Set up player's martial arts data if not exists
    if not playerData.martialArts then
        playerData.martialArts = {
            internalEnergy = 100,
            maxInternalEnergy = 1000,
            intentMastery = 0,
            emotionMastery = {
                Joy = 0,
                Anger = 0,
                Sorrow = 0,
                Pleasure = 0,
                Love = 0,
                Hate = 0,
                Desire = 0
            },
            gangQiLevel = 0,
            heartAffinity = playerData.heartAffinity or math.random(1, 100),
            techniques = {},
            stances = {},
            manifestations = {},
            trainingProgress = 0,
            lastTrainingTime = 0,
            sparringWins = 0,
            sparringLosses = 0,
            currentEmotion = "Joy",
            intentColor = GameConstants.EMOTIONS.Joy.color
        }
    end
    
    -- Send initial martial arts data to client
    RemoteEvents.FireClient("MartialProgress", player, playerData.martialArts)
end

function MartialArtsSystem:CleanupPlayer(player)
    local userId = player.UserId
    
    -- Stop any active training session
    if activeTraining[userId] then
        self:StopTraining(player)
    end
    
    -- Clean up intent visualizations
    if intentVisualizations[userId] then
        self:ClearIntentVisualization(player)
    end
    
    -- Clean up Gang Qi formations
    if gangQiFormations[userId] then
        self:DismissGangQi(player)
    end
    
    print("Cleaned up martial arts system for player:", player.Name)
end

function MartialArtsSystem:SetupRemoteEvents()
    -- Start martial training
    RemoteEvents.ConnectEvent("StartMartialTraining", function(player, trainingType, emotion)
        self:StartTraining(player, trainingType, emotion)
    end)
    
    -- Stop martial training
    RemoteEvents.ConnectEvent("StopMartialTraining", function(player)
        self:StopTraining(player)
    end)
    
    -- Change emotion state
    RemoteEvents.ConnectEvent("ChangeEmotionState", function(player, emotion)
        self:ChangeEmotionState(player, emotion)
    end)
    
    -- Visualize intent
    RemoteEvents.ConnectEvent("VisualizeIntent", function(player, targetPosition, intentType)
        self:VisualizeIntent(player, targetPosition, intentType)
    end)
    
    -- Form Gang Qi
    RemoteEvents.ConnectEvent("FormGangQi", function(player, formationType, targets)
        self:FormGangQi(player, formationType, targets)
    end)
    
    -- Manifest heart essence
    RemoteEvents.ConnectEvent("ManifestHeart", function(player, manifestationType)
        self:ManifestHeart(player, manifestationType)
    end)
    
    -- Challenge to sparring
    RemoteEvents.ConnectEvent("ChallengeSparring", function(player, targetPlayer)
        self:InitiateSparring(player, targetPlayer)
    end)
end

function MartialArtsSystem:StartTraining(player, trainingType, emotion)
    local userId = player.UserId
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        warn("No player data found for martial training start")
        return
    end
    
    -- Check if already training
    if activeTraining[userId] then
        RemoteEvents.FireClient("SystemMessage", player, "You are already training!")
        return
    end
    
    -- Validate training type
    local validTypes = {"BasicCombat", "IntentTraining", "EmotionMastery", "GangQiFormation", "HeartManifestation"}
    local isValidType = false
    for _, validType in ipairs(validTypes) do
        if trainingType == validType then
            isValidType = true
            break
        end
    end
    
    if not isValidType then
        warn("Invalid training type:", trainingType)
        return
    end
    
    -- Check realm requirements
    local realmRequirements = {
        BasicCombat = 1,
        IntentTraining = 4, -- Peak Master
        EmotionMastery = 5, -- Three Flowers
        GangQiFormation = 6, -- Five Energies
        HeartManifestation = 8 -- First Manifestation
    }
    
    if playerData.martialRealm < realmRequirements[trainingType] then
        local requiredRealm = GameConstants.MARTIAL_REALMS[realmRequirements[trainingType]]
        RemoteEvents.FireClient("SystemMessage", player, "Requires " .. requiredRealm.name .. " realm!")
        return
    end
    
    -- Validate emotion if provided
    if emotion and not GameConstants.EMOTIONS[emotion] then
        warn("Invalid emotion:", emotion)
        emotion = "Joy"
    end
    
    -- Calculate training efficiency
    local efficiency = self:CalculateTrainingEfficiency(player, trainingType, emotion)
    
    -- Create training session
    local session = {
        player = player,
        type = trainingType,
        emotion = emotion or playerData.martialArts.currentEmotion,
        startTime = tick(),
        efficiency = efficiency,
        progressGained = 0,
        energySpent = 0
    }
    
    activeTraining[userId] = session
    
    -- Set emotion state if training emotion mastery
    if trainingType == "EmotionMastery" and emotion then
        self:ChangeEmotionState(player, emotion)
    end
    
    print("Started martial training for", player.Name, "- Type:", trainingType, "Emotion:", emotion, "Efficiency:", efficiency)
    
    -- Notify client
    RemoteEvents.FireClient("MartialProgress", player, {
        training = true,
        type = trainingType,
        emotion = emotion,
        efficiency = efficiency,
        startTime = session.startTime
    })
end

function MartialArtsSystem:StopTraining(player)
    local userId = player.UserId
    local session = activeTraining[userId]
    
    if not session then
        return
    end
    
    -- Calculate final gains
    local duration = tick() - session.startTime
    local finalProgressGain = session.progressGained
    local finalEnergySpent = session.energySpent
    
    -- Apply gains to player data
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if playerData then
        playerData.martialArts.trainingProgress = playerData.martialArts.trainingProgress + finalProgressGain
        playerData.martialArts.internalEnergy = math.max(0, playerData.martialArts.internalEnergy - finalEnergySpent)
        
        -- Apply specific training benefits
        if session.type == "IntentTraining" then
            playerData.martialArts.intentMastery = playerData.martialArts.intentMastery + finalProgressGain * 0.1
        elseif session.type == "EmotionMastery" and session.emotion then
            local currentMastery = playerData.martialArts.emotionMastery[session.emotion] or 0
            playerData.martialArts.emotionMastery[session.emotion] = currentMastery + finalProgressGain * 0.05
        elseif session.type == "GangQiFormation" then
            playerData.martialArts.gangQiLevel = playerData.martialArts.gangQiLevel + finalProgressGain * 0.02
        end
        
        -- Update statistics
        playerData.stats.totalPlayTime = playerData.stats.totalPlayTime + duration
        
        gameManager:UpdatePlayerData(player, playerData)
    end
    
    -- Clean up session
    activeTraining[userId] = nil
    
    print("Stopped martial training for", player.Name, "- Progress gained:", finalProgressGain)
    
    -- Notify client
    RemoteEvents.FireClient("MartialProgress", player, {
        training = false,
        progressGained = finalProgressGain,
        energySpent = finalEnergySpent
    })
end

function MartialArtsSystem:CalculateTrainingEfficiency(player, trainingType, emotion)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return 1.0
    end
    
    local baseEfficiency = 1.0
    
    -- Heart affinity bonus
    local heartAffinityBonus = playerData.martialArts.heartAffinity / 100
    baseEfficiency = baseEfficiency * (1 + heartAffinityBonus)
    
    -- Bloodline bonuses
    local bloodlineInfo = GameConstants.BLOODLINES[playerData.bloodline]
    if bloodlineInfo and bloodlineInfo.bonuses then
        if bloodlineInfo.bonuses.physicalPower then
            baseEfficiency = baseEfficiency * bloodlineInfo.bonuses.physicalPower
        end
    end
    
    -- Emotion state bonuses
    if emotion and GameConstants.EMOTIONS[emotion] then
        local emotionEffects = GameConstants.EMOTIONS[emotion].effects
        if trainingType == "EmotionMastery" then
            baseEfficiency = baseEfficiency * 1.5 -- Bonus for training specific emotion
        end
        
        -- Apply emotion-specific bonuses
        for effect, multiplier in pairs(emotionEffects) do
            if effect == "technique" and trainingType == "BasicCombat" then
                baseEfficiency = baseEfficiency * multiplier
            elseif effect == "precision" and trainingType == "IntentTraining" then
                baseEfficiency = baseEfficiency * multiplier
            end
        end
    end
    
    -- Realm efficiency (higher realms train more efficiently)
    local realmBonus = 1 + (playerData.martialRealm * 0.1)
    baseEfficiency = baseEfficiency * realmBonus
    
    -- Training type modifiers
    local typeModifiers = {
        BasicCombat = 1.0,
        IntentTraining = 0.8, -- Slower but more focused
        EmotionMastery = 0.6, -- Very slow but powerful
        GangQiFormation = 0.4, -- Extremely slow
        HeartManifestation = 0.2 -- Incredibly slow but transformative
    }
    
    baseEfficiency = baseEfficiency * (typeModifiers[trainingType] or 1.0)
    
    return math.max(0.1, baseEfficiency)
end

function MartialArtsSystem:ChangeEmotionState(player, emotion)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or not GameConstants.EMOTIONS[emotion] then
        return
    end
    
    -- Check if player has mastery in this emotion
    local emotionMastery = playerData.martialArts.emotionMastery[emotion] or 0
    if emotionMastery < 10 and playerData.martialRealm < 5 then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient mastery in " .. emotion .. " emotion!")
        return
    end
    
    -- Update emotion state
    playerData.martialArts.currentEmotion = emotion
    playerData.martialArts.intentColor = GameConstants.EMOTIONS[emotion].color
    
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "changed emotion to", emotion)
    
    -- Notify client for visual effects
    RemoteEvents.FireClient("EmotionStateChange", player, {
        emotion = emotion,
        color = GameConstants.EMOTIONS[emotion].color,
        effects = GameConstants.EMOTIONS[emotion].effects
    })
    
    -- Update intent visualization if active
    if intentVisualizations[player.UserId] then
        self:UpdateIntentVisualization(player)
    end
end

function MartialArtsSystem:VisualizeIntent(player, targetPosition, intentType)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or playerData.martialRealm < 4 then
        RemoteEvents.FireClient("SystemMessage", player, "Requires Peak Master realm to visualize intent!")
        return
    end
    
    local userId = player.UserId
    local currentEmotion = playerData.martialArts.currentEmotion
    local intentColor = GameConstants.EMOTIONS[currentEmotion].color
    
    -- Create intent visualization
    local visualization = {
        player = player,
        startPosition = player.Character and player.Character.HumanoidRootPart.Position or Vector3.new(0, 0, 0),
        targetPosition = targetPosition,
        color = intentColor,
        emotion = currentEmotion,
        intentType = intentType,
        startTime = tick(),
        duration = 3.0,
        intensity = playerData.martialArts.intentMastery / 100
    }
    
    intentVisualizations[userId] = visualization
    
    print("Player", player.Name, "visualizing", intentType, "intent with", currentEmotion, "emotion")
    
    -- Notify all nearby players
    RemoteEvents.FireClient("IntentVisualization", player, visualization)
    
    -- Notify other players in range
    if player.Character and player.Character.HumanoidRootPart then
        local playerPosition = player.Character.HumanoidRootPart.Position
        for _, otherPlayer in pairs(game.Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character.HumanoidRootPart then
                local distance = (otherPlayer.Character.HumanoidRootPart.Position - playerPosition).Magnitude
                if distance <= 100 then -- 100 stud range
                    RemoteEvents.FireClient("IntentVisualization", otherPlayer, visualization)
                end
            end
        end
    end
end

function MartialArtsSystem:UpdateIntentVisualization(player)
    local userId = player.UserId
    local visualization = intentVisualizations[userId]
    
    if not visualization then
        return
    end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if playerData then
        visualization.color = GameConstants.EMOTIONS[playerData.martialArts.currentEmotion].color
        visualization.emotion = playerData.martialArts.currentEmotion
        
        -- Update visualization for all nearby players
        RemoteEvents.FireClient("IntentVisualization", player, visualization)
    end
end

function MartialArtsSystem:ClearIntentVisualization(player)
    local userId = player.UserId
    intentVisualizations[userId] = nil
    
    RemoteEvents.FireClient("IntentVisualization", player, nil)
end

function MartialArtsSystem:FormGangQi(player, formationType, targets)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or playerData.martialRealm < 6 then
        RemoteEvents.FireClient("SystemMessage", player, "Requires Five Energies realm to form Gang Qi!")
        return
    end
    
    -- Check internal energy cost
    local energyCost = {
        Sphere = 200,
        Blade = 150,
        Shield = 100,
        Projection = 300
    }
    
    local cost = energyCost[formationType] or 100
    if playerData.martialArts.internalEnergy < cost then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient internal energy!")
        return
    end
    
    local userId = player.UserId
    
    -- Dismiss existing Gang Qi
    if gangQiFormations[userId] then
        self:DismissGangQi(player)
    end
    
    -- Create Gang Qi formation
    local formation = {
        player = player,
        type = formationType,
        targets = targets or {},
        startTime = tick(),
        duration = 60, -- 1 minute base duration
        power = playerData.martialArts.gangQiLevel,
        emotion = playerData.martialArts.currentEmotion,
        color = GameConstants.EMOTIONS[playerData.martialArts.currentEmotion].color
    }
    
    -- Extend duration based on Gang Qi mastery
    formation.duration = formation.duration + (playerData.martialArts.gangQiLevel * 10)
    
    gangQiFormations[userId] = formation
    
    -- Consume internal energy
    playerData.martialArts.internalEnergy = playerData.martialArts.internalEnergy - cost
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "formed", formationType, "Gang Qi")
    
    -- Notify client
    RemoteEvents.FireClient("GangQiUpdate", player, formation)
end

function MartialArtsSystem:DismissGangQi(player)
    local userId = player.UserId
    gangQiFormations[userId] = nil
    
    RemoteEvents.FireClient("GangQiUpdate", player, nil)
end

function MartialArtsSystem:ManifestHeart(player, manifestationType)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or playerData.martialRealm < 8 then
        RemoteEvents.FireClient("SystemMessage", player, "Requires First Manifestation realm!")
        return
    end
    
    -- Check if player already has this manifestation
    local hasManifestations = false
    for _, manifestation in ipairs(playerData.martialArts.manifestations) do
        if manifestation.type == manifestationType then
            hasManifestations = true
            break
        end
    end
    
    if hasManifestations then
        RemoteEvents.FireClient("SystemMessage", player, "You already have this heart manifestation!")
        return
    end
    
    -- Heart manifestation requires deep understanding of emotions
    local totalEmotionMastery = 0
    for emotion, mastery in pairs(playerData.martialArts.emotionMastery) do
        totalEmotionMastery = totalEmotionMastery + mastery
    end
    
    if totalEmotionMastery < 500 then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient emotion mastery for heart manifestation!")
        return
    end
    
    -- Create heart manifestation
    local manifestation = {
        type = manifestationType,
        power = playerData.martialArts.heartAffinity,
        createdAt = tick(),
        emotion = playerData.martialArts.currentEmotion,
        description = self:GetManifestationDescription(manifestationType)
    }
    
    table.insert(playerData.martialArts.manifestations, manifestation)
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "manifested heart:", manifestationType)
    
    -- Notify client
    RemoteEvents.FireClient("HeartManifestation", player, manifestation)
    
    -- Notify all players of major achievement
    RemoteEvents.FireAllClients("SystemMessage", player.Name .. " has manifested their heart: " .. manifestationType .. "!")
end

function MartialArtsSystem:GetManifestationDescription(manifestationType)
    local descriptions = {
        ["Sword Heart"] = "A heart that cuts through all illusions with unwavering determination",
        ["Compassionate Heart"] = "A heart that embraces all beings with infinite love and understanding",
        ["Wrathful Heart"] = "A heart that burns with righteous fury against injustice",
        ["Tranquil Heart"] = "A heart as calm as still water, unmoved by worldly concerns",
        ["Ambitious Heart"] = "A heart that reaches for the heavens with boundless desire",
        ["Protective Heart"] = "A heart that shields others from harm with selfless devotion",
        ["Seeking Heart"] = "A heart that pursues truth and knowledge without end"
    }
    
    return descriptions[manifestationType] or "A unique manifestation of the martial heart"
end

function MartialArtsSystem:InitiateSparring(player, targetPlayer)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    local targetData = gameManager:GetPlayerData(targetPlayer)
    
    if not playerData or not targetData then
        return
    end
    
    -- Check if both players are in martial arts realm
    if playerData.martialRealm < 1 or targetData.martialRealm < 1 then
        RemoteEvents.FireClient("SystemMessage", player, "Both players must have martial arts training!")
        return
    end
    
    -- Send sparring invitation
    RemoteEvents.FireClient("SparringInvitation", targetPlayer, {
        challenger = player.Name,
        challengerRealm = playerData.martialRealm,
        challengerRealmName = GameConstants.MARTIAL_REALMS[playerData.martialRealm].name
    })
    
    print("Sparring invitation sent from", player.Name, "to", targetPlayer.Name)
end

function MartialArtsSystem:Update(deltaTime)
    -- Update active training sessions
    for userId, session in pairs(activeTraining) do
        self:UpdateTrainingSession(session, deltaTime)
    end
    
    -- Update intent visualizations
    for userId, visualization in pairs(intentVisualizations) do
        self:UpdateIntentVisualizationTimer(visualization, deltaTime)
    end
    
    -- Update Gang Qi formations
    for userId, formation in pairs(gangQiFormations) do
        self:UpdateGangQiFormation(formation, deltaTime)
    end
end

function MartialArtsSystem:UpdateTrainingSession(session, deltaTime)
    local player = session.player
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Calculate progress gain per second
    local baseProgressPerSecond = 5 * session.efficiency
    local progressGain = baseProgressPerSecond * deltaTime
    
    -- Calculate energy cost per second
    local baseEnergyPerSecond = 2
    local energyCost = baseEnergyPerSecond * deltaTime
    
    -- Check if player has enough energy
    if playerData.martialArts.internalEnergy < energyCost then
        -- Stop training due to exhaustion
        self:StopTraining(player)
        RemoteEvents.FireClient("SystemMessage", player, "Training stopped due to exhaustion!")
        return
    end
    
    -- Apply diminishing returns for long sessions
    local sessionDuration = tick() - session.startTime
    local diminishingFactor = math.max(0.1, 1.0 - (sessionDuration / 7200)) -- Reduces over 2 hours
    
    progressGain = progressGain * diminishingFactor
    
    -- Update session totals
    session.progressGained = session.progressGained + progressGain
    session.energySpent = session.energySpent + energyCost
    
    -- Send periodic updates to client (every 10 seconds)
    if sessionDuration % 10 < deltaTime then
        RemoteEvents.FireClient("MartialProgress", player, {
            progressGained = progressGain,
            energySpent = energyCost,
            efficiency = session.efficiency * diminishingFactor,
            internalEnergy = playerData.martialArts.internalEnergy - session.energySpent
        })
    end
end

function MartialArtsSystem:UpdateIntentVisualizationTimer(visualization, deltaTime)
    local elapsed = tick() - visualization.startTime
    
    if elapsed > visualization.duration then
        self:ClearIntentVisualization(visualization.player)
    end
end

function MartialArtsSystem:UpdateGangQiFormation(formation, deltaTime)
    local elapsed = tick() - formation.startTime
    
    if elapsed > formation.duration then
        self:DismissGangQi(formation.player)
    end
end

function MartialArtsSystem:InitializeTrainingGrounds()
    -- Create training areas with different bonuses
    local trainingGrounds = {
        {position = Vector3.new(200, 0, 200), radius = 50, bonus = 1.2, type = "Basic"},
        {position = Vector3.new(-200, 0, 200), radius = 50, bonus = 1.5, type = "Intent"},
        {position = Vector3.new(200, 0, -200), radius = 50, bonus = 1.3, type = "Emotion"},
        {position = Vector3.new(-200, 0, -200), radius = 50, bonus = 1.8, type = "Gang Qi"}
    }
    
    -- These would be implemented as actual areas in the game world
    print("Initialized", #trainingGrounds, "martial arts training grounds")
end

return MartialArtsSystem

