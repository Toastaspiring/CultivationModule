--[[
    ServerMain.lua
    Main server script that initializes and runs all game systems
    This script should be a regular Script (not ModuleScript) in ServerScriptService
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

-- Wait for shared modules to load
local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameConstants = require(SharedModules:WaitForChild("GameConstants"))
local RemoteEvents = require(SharedModules:WaitForChild("RemoteEvents"))

-- Require all server modules
local PlayerDataManager = require(script.Parent:WaitForChild("PlayerDataManager"))
local CultivationSystem = require(script.Parent:WaitForChild("CultivationSystem"))
local MartialArtsSystem = require(script.Parent:WaitForChild("MartialArtsSystem"))
local SectManager = require(script.Parent:WaitForChild("SectManager"))
local CombatSystem = require(script.Parent:WaitForChild("CombatSystem"))
local ResourceManager = require(script.Parent:WaitForChild("ResourceManager"))

-- Game state
local GameState = {
    IsRunning = false,
    PlayerCount = 0,
    ServerStartTime = tick(),
    ActiveCombats = {},
    ActiveSects = {},
    ResourceNodes = {}
}

-- Initialize all game systems
local function InitializeGameSystems()
    print("🎮 Initializing Cultivation Game Server...")
    
    -- Initialize RemoteEvents first
    RemoteEvents.Initialize()
    print("✅ Remote Events initialized")
    
    -- Initialize PlayerDataManager
    PlayerDataManager.Initialize()
    print("✅ Player Data Manager initialized")
    
    -- Initialize CultivationSystem
    CultivationSystem.Initialize()
    print("✅ Cultivation System initialized")
    
    -- Initialize MartialArtsSystem
    MartialArtsSystem.Initialize()
    print("✅ Martial Arts System initialized")
    
    -- Initialize SectManager
    SectManager.Initialize()
    print("✅ Sect Manager initialized")
    
    -- Initialize CombatSystem
    CombatSystem.Initialize()
    print("✅ Combat System initialized")
    
    -- Initialize ResourceManager
    ResourceManager.Initialize()
    print("✅ Resource Manager initialized")
    
    GameState.IsRunning = true
    print("🌟 Cultivation Game Server fully initialized!")
end

-- Handle player joining
local function OnPlayerAdded(player)
    print("👤 Player joined:", player.Name)
    GameState.PlayerCount = GameState.PlayerCount + 1
    
    -- Load player data
    PlayerDataManager.LoadPlayerData(player)
    
    -- Initialize player in all systems
    CultivationSystem.InitializePlayer(player)
    MartialArtsSystem.InitializePlayer(player)
    SectManager.InitializePlayer(player)
    CombatSystem.InitializePlayer(player)
    ResourceManager.InitializePlayer(player)
    
    -- Send welcome message
    local welcomeData = {
        ServerTime = tick() - GameState.ServerStartTime,
        PlayerCount = GameState.PlayerCount,
        GameVersion = GameConstants.GAME_VERSION or "1.0.0"
    }
    
    RemoteEvents.SendToClient(player, "PlayerWelcome", welcomeData)
    
    print("✅ Player", player.Name, "fully initialized")
end

-- Handle player leaving
local function OnPlayerRemoving(player)
    print("👋 Player leaving:", player.Name)
    GameState.PlayerCount = GameState.PlayerCount - 1
    
    -- Save player data
    PlayerDataManager.SavePlayerData(player)
    
    -- Clean up player from all systems
    CultivationSystem.CleanupPlayer(player)
    MartialArtsSystem.CleanupPlayer(player)
    SectManager.CleanupPlayer(player)
    CombatSystem.CleanupPlayer(player)
    ResourceManager.CleanupPlayer(player)
    
    print("✅ Player", player.Name, "cleaned up")
end

-- Main game loop
local function GameLoop()
    if not GameState.IsRunning then return end
    
    -- Update all systems
    CultivationSystem.Update()
    MartialArtsSystem.Update()
    SectManager.Update()
    CombatSystem.Update()
    ResourceManager.Update()
end

-- Server shutdown handling
local function OnServerShutdown()
    print("🛑 Server shutting down, saving all data...")
    GameState.IsRunning = false
    
    -- Save all player data
    for _, player in pairs(Players:GetPlayers()) do
        PlayerDataManager.SavePlayerData(player)
    end
    
    -- Save sect data
    SectManager.SaveAllSectData()
    
    print("✅ All data saved successfully")
end

-- Error handling
local function HandleError(err)
    warn("❌ Server Error:", err)
    warn("Stack trace:", debug.traceback())
    
    -- Log error to analytics if available
    if GameConstants.ENABLE_ANALYTICS then
        -- Send error to analytics service
    end
end

-- Initialize the server
local function StartServer()
    -- Wrap initialization in pcall for error handling
    local success, err = pcall(InitializeGameSystems)
    
    if not success then
        HandleError(err)
        return
    end
    
    -- Connect player events
    Players.PlayerAdded:Connect(OnPlayerAdded)
    Players.PlayerRemoving:Connect(OnPlayerRemoving)
    
    -- Handle players already in game (for testing)
    for _, player in pairs(Players:GetPlayers()) do
        OnPlayerAdded(player)
    end
    
    -- Start main game loop
    RunService.Heartbeat:Connect(function()
        local success, err = pcall(GameLoop)
        if not success then
            HandleError(err)
        end
    end)
    
    -- Handle server shutdown
    game:BindToClose(OnServerShutdown)
    
    print("🚀 Cultivation Game Server is now running!")
    print("📊 Server Stats:")
    print("   - Game Version:", GameConstants.GAME_VERSION or "1.0.0")
    print("   - Max Players:", GameConstants.MAX_PLAYERS or 50)
    print("   - Server Region:", GameConstants.SERVER_REGION or "Global")
end

-- Start the server
StartServer()

-- Export for debugging
_G.CultivationGameServer = {
    GameState = GameState,
    Systems = {
        PlayerDataManager = PlayerDataManager,
        CultivationSystem = CultivationSystem,
        MartialArtsSystem = MartialArtsSystem,
        SectManager = SectManager,
        CombatSystem = CombatSystem,
        ResourceManager = ResourceManager
    },
    RestartServer = StartServer,
    GetServerStats = function()
        return {
            Uptime = tick() - GameState.ServerStartTime,
            PlayerCount = GameState.PlayerCount,
            IsRunning = GameState.IsRunning,
            ActiveCombats = #GameState.ActiveCombats,
            ActiveSects = #GameState.ActiveSects
        }
    end
}

