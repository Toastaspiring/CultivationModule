--[[
    MartialArtsSystem.lua
    Handles martial arts progression. This system is now driven by GameConstants.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import Global modules
local GameConstants = require(ReplicatedStorage.GameConstants)
local RemoteEvents = require(ReplicatedStorage.RemoteEvents)

local MartialArtsSystem = {}
MartialArtsSystem.__index = MartialArtsSystem

-- Active state tables
local activeTraining = {}

function MartialArtsSystem.new()
    local self = setmetatable({}, MartialArtsSystem)
    self:SetupRemoteEvents()
    return self
end

function MartialArtsSystem:InitializePlayer(player, playerData)
    print("Initializing martial arts system for player:", player.Name)
    
    if not playerData.martialArts then
        local emotionMastery = {}
        for emotionName, _ in pairs(GameConstants.SPECIAL_ABILITIES.PATH_2_ABILITIES) do
            emotionMastery[emotionName] = 0
        end

        playerData.martialArts = {
            internalEnergy = 100,
            maxInternalEnergy = 1000,
            emotionMastery = emotionMastery,
            trainingProgress = 0,
            currentEmotion = "Joy" -- Default emotion
        }
    end
    
    RemoteEvents.FireClient("MartialProgress", player, playerData.martialArts)
end

function MartialArtsSystem:CleanupPlayer(player)
    if activeTraining[player.UserId] then
        self:StopTraining(player)
    end
    print("Cleaned up martial arts system for player:", player.Name)
end

function MartialArtsSystem:SetupRemoteEvents()
    RemoteEvents.ConnectEvent("StartMartialTraining", function(player, trainingType, emotion)
        self:StartTraining(player, trainingType, emotion)
    end)
    RemoteEvents.ConnectEvent("StopMartialTraining", function(player)
        self:StopTraining(player)
    end)
    RemoteEvents.ConnectEvent("ChangeEmotionState", function(player, emotion)
        self:ChangeEmotionState(player, emotion)
    end)
end

function MartialArtsSystem:StartTraining(player, trainingType, emotion)
    local userId = player.UserId
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    if not playerData then return end
    
    if activeTraining[userId] then
        RemoteEvents.FireClient("SystemMessage", player, "You are already training!")
        return
    end
    
    local trainingInfo = GameConstants.MARTIAL_ARTS.TRAINING_TYPES[trainingType]
    if not trainingInfo then
        warn("Invalid training type:", trainingType)
        return
    end
    
    if playerData.realm_path2 < trainingInfo.requiredRealm then
        local requiredRealmName = GameConstants.PROGRESSION_PATHS.PATH_2.Realms[trainingInfo.requiredRealm].name
        RemoteEvents.FireClient("SystemMessage", player, "Requires " .. requiredRealmName .. " realm!")
        return
    end
    
    local efficiency = self:CalculateTrainingEfficiency(player, trainingType, emotion)
    
    activeTraining[userId] = {
        player = player,
        type = trainingType,
        emotion = emotion or playerData.martialArts.currentEmotion,
        startTime = tick(),
        efficiency = efficiency,
        progressGained = 0
    }
    
    RemoteEvents.FireClient("MartialProgress", player, { training = true, type = trainingType })
end

function MartialArtsSystem:StopTraining(player)
    local userId = player.UserId
    local session = activeTraining[userId]
    if not session then return end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if playerData then
        playerData.martialArts.trainingProgress = playerData.martialArts.trainingProgress + session.progressGained
        gameManager:UpdatePlayerData(player, playerData)
    end
    
    activeTraining[userId] = nil
    RemoteEvents.FireClient("MartialProgress", player, { training = false, progressGained = session.progressGained })
end

function MartialArtsSystem:CalculateTrainingEfficiency(player, trainingType, emotion)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    if not playerData then return 1.0 end
    
    local baseEfficiency = 1.0
    
    -- Heart affinity bonus
    baseEfficiency = baseEfficiency * (1 + (playerData.talent_path2 / 100))
    
    -- Training type modifier
    local trainingInfo = GameConstants.MARTIAL_ARTS.TRAINING_TYPES[trainingType]
    baseEfficiency = baseEfficiency * (trainingInfo.efficiency or 1.0)
    
    -- Realm bonus
    baseEfficiency = baseEfficiency * (1 + (playerData.realm_path2 * GameConstants.MARTIAL_ARTS.REALM_EFFICIENCY_BONUS))
    
    return math.max(0.1, baseEfficiency)
end

function MartialArtsSystem:ChangeEmotionState(player, emotion)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    if not playerData or not GameConstants.SPECIAL_ABILITIES.PATH_2_ABILITIES[emotion] then
        return
    end
    
    local masteryRequirement = GameConstants.MARTIAL_ARTS.EMOTION_MASTERY_REQUIREMENT
    if (playerData.martialArts.emotionMastery[emotion] or 0) < masteryRequirement.mastery and playerData.realm_path2 < masteryRequirement.realm then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient mastery in " .. emotion .. " emotion!")
        return
    end
    
    playerData.martialArts.currentEmotion = emotion
    gameManager:UpdatePlayerData(player, playerData)
    
    RemoteEvents.FireClient("EmotionStateChange", player, { emotion = emotion })
end

function MartialArtsSystem:Update(deltaTime)
    for userId, session in pairs(activeTraining) do
        self:UpdateTrainingSession(session, deltaTime)
    end
end

function MartialArtsSystem:UpdateTrainingSession(session, deltaTime)
    local progressGain = GameConstants.MARTIAL_ARTS.BASE_PROGRESS_GAIN * session.efficiency * deltaTime
    
    local diminishConfig = GameConstants.MARTIAL_ARTS.DIMINISHING_RETURNS
    local diminishingFactor = math.max(diminishConfig.MIN_FACTOR, 1.0 - ((tick() - session.startTime) / diminishConfig.DURATION))
    
    session.progressGained = session.progressGained + (progressGain * diminishingFactor)
end

-- This function would be expanded in a full implementation
function MartialArtsSystem:InitiateSparring(player, targetPlayer)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    local targetData = gameManager:GetPlayerData(targetPlayer)
    
    if not playerData or not targetData or playerData.realm_path2 < 1 or targetData.realm_path2 < 1 then
        return
    end
    
    local realmName = GameConstants.PROGRESSION_PATHS.PATH_2.Realms[playerData.realm_path2].name
    RemoteEvents.FireClient("SparringInvitation", targetPlayer, {
        challengerName = player.Name,
        challengerRealmName = realmName
    })
end

return MartialArtsSystem
