--[[
    GameManager.lua
    Main server-side game controller for the Cultivation Game
    Handles initialization, player connections, and core game loop
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")

-- Import core modules
local PlayerDataManager = require(script.Parent.PlayerDataManager)
local CultivationSystem = require(script.Parent.CultivationSystem)
local MartialArtsSystem = require(script.Parent.MartialArtsSystem)
local SectManager = require(script.Parent.SectManager)
local ResourceManager = require(script.Parent.ResourceManager)
local CombatSystem = require(script.Parent.CombatSystem)

-- Import shared modules
local GameConstants = require(ReplicatedStorage.Shared.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local GameManager = {}
GameManager.__index = GameManager

-- Game state
local gameState = {
    isRunning = false,
    serverStartTime = 0,
    activePlayers = {},
    worldEvents = {},
    sectWars = {},
    resourceNodes = {}
}

function GameManager.new()
    local self = setmetatable({}, GameManager)
    
    self.playerDataManager = PlayerDataManager.new()
    self.cultivationSystem = CultivationSystem.new()
    self.martialArtsSystem = MartialArtsSystem.new()
    self.sectManager = SectManager.new()
    self.resourceManager = ResourceManager.new()
    self.combatSystem = CombatSystem.new()
    
    return self
end

function GameManager:Initialize()
    print("Initializing Cultivation Game Server...")
    
    -- Set up player connections
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeaving(player)
    end)
    
    -- Initialize world systems
    self:InitializeWorldSystems()
    
    -- Start game loop
    self:StartGameLoop()
    
    gameState.isRunning = true
    gameState.serverStartTime = tick()
    
    print("Cultivation Game Server initialized successfully!")
end

function GameManager:OnPlayerJoined(player)
    print("Player joined:", player.Name)
    
    -- Load player data
    local playerData = self.playerDataManager:LoadPlayerData(player)
    if not playerData then
        -- Create new player with character creation
        playerData = self:CreateNewPlayer(player)
    end
    
    gameState.activePlayers[player.UserId] = {
        player = player,
        data = playerData,
        joinTime = tick(),
        lastActivity = tick()
    }
    
    -- Initialize player systems
    self.cultivationSystem:InitializePlayer(player, playerData)
    self.martialArtsSystem:InitializePlayer(player, playerData)
    self.sectManager:InitializePlayer(player, playerData)
    
    -- Send initial data to client
    RemoteEvents.PlayerDataSync:FireClient(player, playerData)
end

function GameManager:OnPlayerLeaving(player)
    print("Player leaving:", player.Name)
    
    local playerInfo = gameState.activePlayers[player.UserId]
    if playerInfo then
        -- Save player data
        self.playerDataManager:SavePlayerData(player, playerInfo.data)
        
        -- Clean up player from systems
        self.cultivationSystem:CleanupPlayer(player)
        self.martialArtsSystem:CleanupPlayer(player)
        self.sectManager:CleanupPlayer(player)
        
        gameState.activePlayers[player.UserId] = nil
    end
end

function GameManager:CreateNewPlayer(player)
    local newPlayerData = {
        -- Basic Info
        userId = player.UserId,
        username = player.Name,
        createdAt = tick(),
        lastLogin = tick(),
        
        -- Character Attributes
        spiritRoot = self:GenerateSpiritRoot(),
        bloodline = "Human",
        heartAffinity = math.random(1, 100),
        
        -- Progression
        cultivationRealm = 0, -- 0 = No cultivation
        martialRealm = 0, -- 0 = No martial arts
        experience = 0,
        
        -- Resources
        resources = {
            qi = 100,
            spiritStones = 0,
            contributionPoints = 0,
            reputation = 0
        },
        
        -- Inventory
        inventory = {
            herbs = {},
            pills = {},
            techniques = {},
            equipment = {},
            materials = {}
        },
        
        -- Social
        sectId = nil,
        sectRank = 0,
        friends = {},
        enemies = {},
        
        -- Statistics
        stats = {
            totalPlayTime = 0,
            breakthroughsAchieved = 0,
            combatWins = 0,
            combatLosses = 0,
            resourcesGathered = 0
        },
        
        -- Settings
        settings = {
            autoSave = true,
            combatMode = "Manual",
            uiScale = 1.0,
            soundEnabled = true
        }
    }
    
    return newPlayerData
end

function GameManager:GenerateSpiritRoot()
    local chance = math.random(1, 1000)
    
    if chance <= 1 then
        return "Legendary" -- 0.1% chance
    elseif chance <= 10 then
        return "High" -- 0.9% chance
    elseif chance <= 50 then
        return "Medium" -- 4% chance
    elseif chance <= 200 then
        return "Low" -- 15% chance
    else
        return "None" -- 80% chance
    end
end

function GameManager:InitializeWorldSystems()
    -- Initialize resource nodes
    self.resourceManager:InitializeResourceNodes()
    
    -- Initialize NPC sects
    self.sectManager:InitializeNPCSects()
    
    -- Set up world events
    self:ScheduleWorldEvents()
end

function GameManager:StartGameLoop()
    -- Main game loop running at 30 FPS
    RunService.Heartbeat:Connect(function(deltaTime)
        self:UpdateGameSystems(deltaTime)
    end)
    
    -- Slower update loop for less critical systems (1 FPS)
    spawn(function()
        while gameState.isRunning do
            self:UpdateSlowSystems()
            wait(1)
        end
    end)
end

function GameManager:UpdateGameSystems(deltaTime)
    -- Update cultivation progress for all players
    self.cultivationSystem:Update(deltaTime)
    
    -- Update martial arts training
    self.martialArtsSystem:Update(deltaTime)
    
    -- Update combat systems
    self.combatSystem:Update(deltaTime)
    
    -- Update resource regeneration
    self.resourceManager:Update(deltaTime)
end

function GameManager:UpdateSlowSystems()
    -- Update sect activities
    self.sectManager:Update()
    
    -- Process world events
    self:ProcessWorldEvents()
    
    -- Auto-save player data
    self:AutoSavePlayerData()
    
    -- Update server statistics
    self:UpdateServerStats()
end

function GameManager:ScheduleWorldEvents()
    -- Schedule various world events
    spawn(function()
        while gameState.isRunning do
            -- Ancient herb garden spawn (every 2-4 hours)
            wait(math.random(7200, 14400))
            self:SpawnAncientHerbGarden()
        end
    end)
    
    spawn(function()
        while gameState.isRunning do
            -- Meteor shower event (every 6-12 hours)
            wait(math.random(21600, 43200))
            self:TriggerMeteorShower()
        end
    end)
    
    spawn(function()
        while gameState.isRunning do
            -- Enlightenment opportunity (every 1-3 hours)
            wait(math.random(3600, 10800))
            self:CreateEnlightenmentOpportunity()
        end
    end)
end

function GameManager:SpawnAncientHerbGarden()
    print("Ancient Herb Garden has appeared!")
    
    local event = {
        type = "AncientHerbGarden",
        startTime = tick(),
        duration = 1800, -- 30 minutes
        location = self:GetRandomLocation(),
        participants = {}
    }
    
    table.insert(gameState.worldEvents, event)
    
    -- Notify all players
    for userId, playerInfo in pairs(gameState.activePlayers) do
        RemoteEvents.WorldEventNotification:FireClient(playerInfo.player, event)
    end
end

function GameManager:TriggerMeteorShower()
    print("Meteor shower is occurring!")
    
    local event = {
        type = "MeteorShower",
        startTime = tick(),
        duration = 600, -- 10 minutes
        intensity = math.random(1, 5),
        rewards = {}
    }
    
    table.insert(gameState.worldEvents, event)
    
    -- Notify all players
    for userId, playerInfo in pairs(gameState.activePlayers) do
        RemoteEvents.WorldEventNotification:FireClient(playerInfo.player, event)
    end
end

function GameManager:CreateEnlightenmentOpportunity()
    print("An enlightenment opportunity has manifested!")
    
    local event = {
        type = "EnlightenmentOpportunity",
        startTime = tick(),
        duration = 900, -- 15 minutes
        location = self:GetRandomLocation(),
        requirements = {
            minRealm = math.random(1, 5),
            pathType = math.random() > 0.5 and "Cultivation" or "MartialArts"
        }
    }
    
    table.insert(gameState.worldEvents, event)
    
    -- Notify eligible players
    for userId, playerInfo in pairs(gameState.activePlayers) do
        local meetsRequirements = false
        if event.requirements.pathType == "Cultivation" then
            meetsRequirements = playerInfo.data.cultivationRealm >= event.requirements.minRealm
        else
            meetsRequirements = playerInfo.data.martialRealm >= event.requirements.minRealm
        end
        
        if meetsRequirements then
            RemoteEvents.WorldEventNotification:FireClient(playerInfo.player, event)
        end
    end
end

function GameManager:GetRandomLocation()
    -- Return a random location in the game world
    return {
        x = math.random(-1000, 1000),
        y = 0,
        z = math.random(-1000, 1000)
    }
end

function GameManager:ProcessWorldEvents()
    local currentTime = tick()
    
    for i = #gameState.worldEvents, 1, -1 do
        local event = gameState.worldEvents[i]
        
        if currentTime - event.startTime > event.duration then
            -- Event has ended
            self:EndWorldEvent(event)
            table.remove(gameState.worldEvents, i)
        end
    end
end

function GameManager:EndWorldEvent(event)
    print("World event ended:", event.type)
    
    -- Notify all participants
    for userId, playerInfo in pairs(gameState.activePlayers) do
        RemoteEvents.WorldEventEnded:FireClient(playerInfo.player, event)
    end
end

function GameManager:AutoSavePlayerData()
    for userId, playerInfo in pairs(gameState.activePlayers) do
        if playerInfo.data.settings.autoSave then
            self.playerDataManager:SavePlayerData(playerInfo.player, playerInfo.data)
        end
    end
end

function GameManager:UpdateServerStats()
    local stats = {
        activePlayerCount = 0,
        totalSects = 0,
        activeWorldEvents = #gameState.worldEvents,
        serverUptime = tick() - gameState.serverStartTime
    }
    
    for _ in pairs(gameState.activePlayers) do
        stats.activePlayerCount = stats.activePlayerCount + 1
    end
    
    stats.totalSects = self.sectManager:GetSectCount()
    
    -- Could send to analytics service or display in admin panel
end

function GameManager:GetPlayerData(player)
    local playerInfo = gameState.activePlayers[player.UserId]
    return playerInfo and playerInfo.data or nil
end

function GameManager:UpdatePlayerData(player, newData)
    local playerInfo = gameState.activePlayers[player.UserId]
    if playerInfo then
        playerInfo.data = newData
        playerInfo.lastActivity = tick()
    end
end

function GameManager:Shutdown()
    print("Shutting down Cultivation Game Server...")
    
    gameState.isRunning = false
    
    -- Save all player data
    for userId, playerInfo in pairs(gameState.activePlayers) do
        self.playerDataManager:SavePlayerData(playerInfo.player, playerInfo.data)
    end
    
    print("Server shutdown complete.")
end

-- Initialize the game manager
local gameManager = GameManager.new()
gameManager:Initialize()

-- Handle server shutdown
game:BindToClose(function()
    gameManager:Shutdown()
end)

return GameManager

