--[[
    GameManager.lua (ModuleScript)
    Main game management system for the Cultivation Game
    Handles overall game state, player management, and system coordination
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameManager = {}

-- Game state
local gameState = {
    isRunning = false,
    playerCount = 0,
    serverStartTime = 0,
    activeCombats = {},
    activeSects = {},
    worldEvents = {},
    connections = {}
}

-- Initialize the game manager
function GameManager.Initialize()
    print("🎮 Initializing Game Manager...")
    
    gameState.serverStartTime = tick()
    
    -- Initialize world state
    GameManager.InitializeWorld()
    
    gameState.isRunning = true
    print("✅ Game Manager initialized successfully")
end

-- Initialize the game world
function GameManager.InitializeWorld()
    -- Create world events
    gameState.worldEvents = {
        {
            name = "Spiritual Energy Convergence",
            type = "cultivation_boost",
            duration = 3600, -- 1 hour
            effect = {cultivation_speed = 1.5},
            cooldown = 86400 -- 24 hours
        },
        {
            name = "Sect War Declaration",
            type = "pvp_event",
            duration = 7200, -- 2 hours
            effect = {sect_war_enabled = true},
            cooldown = 172800 -- 48 hours
        },
        {
            name = "Rare Resource Spawn",
            type = "resource_event",
            duration = 1800, -- 30 minutes
            effect = {rare_resource_multiplier = 3},
            cooldown = 43200 -- 12 hours
        }
    }
    
    print("🌍 World initialized with", #gameState.worldEvents, "event types")
end

-- Main update function
function GameManager.Update()
    if not gameState.isRunning then return end
    
    -- Update player counts
    gameState.playerCount = #Players:GetPlayers()
    
    -- Process any pending game state changes
    GameManager.ProcessGameStateChanges()
end

-- Process game state changes
function GameManager.ProcessGameStateChanges()
    -- Handle any queued state changes
    -- This could include sect wars, territory changes, etc.
end

-- Initialize player in game manager
function GameManager.InitializePlayer(player)
    print("🎮 Initializing player in Game Manager:", player.Name)
    
    -- Send current world state to player
    local worldState = {
        serverTime = tick() - gameState.serverStartTime,
        playerCount = gameState.playerCount,
        activeEvents = {}
    }
    
    -- Add active world events
    for _, event in ipairs(gameState.worldEvents) do
        if event.endTime and event.endTime > tick() then
            table.insert(worldState.activeEvents, {
                name = event.name,
                type = event.type,
                timeRemaining = event.endTime - tick(),
                effect = event.effect
            })
        end
    end
    
    -- Send to client via RemoteEvents (will be handled by ServerMain)
    local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
    RemoteEvents.SendToClient(player, "WorldStateUpdate", worldState)
end

-- Clean up player from game manager
function GameManager.CleanupPlayer(player)
    print("🎮 Cleaning up player from Game Manager:", player.Name)
    
    -- Clean up any player-specific data
    if gameState.activeCombats[player.UserId] then
        gameState.activeCombats[player.UserId] = nil
    end
end

-- Get game statistics
function GameManager.GetGameStats()
    return {
        uptime = tick() - gameState.serverStartTime,
        playerCount = gameState.playerCount,
        isRunning = gameState.isRunning,
        activeCombats = #gameState.activeCombats,
        activeSects = #gameState.activeSects,
        activeEvents = #gameState.worldEvents
    }
end

-- Trigger a world event
function GameManager.TriggerWorldEvent(event)
    event.lastTriggered = tick()
    event.endTime = tick() + event.duration
    
    print("🌟 World Event Triggered:", event.name)
    
    -- Notify all players
    local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
    for _, player in pairs(Players:GetPlayers()) do
        RemoteEvents.SendToClient(player, "WorldEventStarted", {
            name = event.name,
            type = event.type,
            duration = event.duration,
            effect = event.effect
        })
    end
    
    -- Schedule event end
    spawn(function()
        wait(event.duration)
        GameManager.EndWorldEvent(event)
    end)
end

-- End a world event
function GameManager.EndWorldEvent(event)
    print("🌟 World Event Ended:", event.name)
    
    -- Notify all players
    local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
    for _, player in pairs(Players:GetPlayers()) do
        RemoteEvents.SendToClient(player, "WorldEventEnded", {
            name = event.name,
            type = event.type
        })
    end
end

-- Shutdown the game manager
function GameManager.Shutdown()
    print("🛑 Shutting down Game Manager...")
    gameState.isRunning = false
    
    -- Disconnect all connections
    for _, connection in pairs(gameState.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    print("✅ Game Manager shutdown complete")
end

return GameManager

