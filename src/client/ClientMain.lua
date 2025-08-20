--[[
    ClientMain.lua
    Main client script that initializes and runs all client-side systems
    This script should be a LocalScript in StarterPlayerScripts
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-- Get local player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for Global modules to load
local GameConstants = require(ReplicatedStorage:WaitForChild("GameConstants"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

-- Require client modules
local UIManager = require(script.Parent.UI:WaitForChild("UIManager"))
local PlayerInfoPanel = require(script.Parent.UI:WaitForChild("PlayerInfoPanel"))
local ResourceBars = require(script.Parent.UI:WaitForChild("ResourceBars"))
local CultivationInterface = require(script.Parent.UI:WaitForChild("CultivationInterface"))
local MobileAdapter = require(script.Parent.UI:WaitForChild("MobileAdapter"))

-- Client state
local ClientState = {
    IsInitialized = false,
    IsMobile = false,
    PlayerData = {},
    UIElements = {},
    ActiveInterfaces = {},
    InputConnections = {}
}

-- Initialize all client systems
local function InitializeClientSystems()
    print("📱 Initializing Cultivation Game Client...")
    
    -- Detect mobile device
    ClientState.IsMobile = MobileAdapter.IsMobile()
    print("📱 Device type:", ClientState.IsMobile and "Mobile" or "Desktop")
    
    -- Initialize RemoteEvents client-side
    RemoteEvents.InitializeClient()
    print("✅ Remote Events client initialized")
    
    -- Create main UI container
    local mainUI = Instance.new("ScreenGui")
    mainUI.Name = "CultivationGameUI"
    mainUI.ResetOnSpawn = false
    mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainUI.Parent = playerGui
    
    -- Initialize UI systems
    UIManager.Initialize(mainUI)
    print("✅ UI Manager initialized")
    
    -- Create main HUD elements
    if ClientState.IsMobile then
        ClientState.UIElements.MobileHUD = MobileAdapter.CreateMobileHUD(mainUI)
        print("✅ Mobile HUD created")
    else
        -- Desktop HUD
        ClientState.UIElements.PlayerInfo = PlayerInfoPanel.Create(mainUI)
        ClientState.UIElements.ResourceBars = ResourceBars.Create(mainUI)
        print("✅ Desktop HUD created")
    end
    
    -- Create main interfaces (hidden by default)
    ClientState.UIElements.CultivationInterface = CultivationInterface.Create(mainUI)
    print("✅ Cultivation Interface created")
    
    -- Set up input handling
    InitializeInputHandling()
    print("✅ Input handling initialized")
    
    -- Set up remote event handlers
    SetupRemoteEventHandlers()
    print("✅ Remote event handlers set up")
    
    ClientState.IsInitialized = true
    print("🌟 Cultivation Game Client fully initialized!")
    
    -- Request initial data from server
    RemoteEvents.SendToServer("RequestPlayerData", {})
end

-- Initialize input handling
local function InitializeInputHandling()
    -- Keyboard shortcuts for desktop
    if not ClientState.IsMobile then
        local keyboardConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.C then
                -- Toggle Cultivation Interface
                ToggleCultivationInterface()
            elseif input.KeyCode == Enum.KeyCode.M then
                -- Toggle Martial Arts Interface
                ToggleMartialArtsInterface()
            elseif input.KeyCode == Enum.KeyCode.I then
                -- Toggle Inventory
                ToggleInventory()
            elseif input.KeyCode == Enum.KeyCode.S then
                -- Toggle Sect Interface
                ToggleSectInterface()
            elseif input.KeyCode == Enum.KeyCode.Escape then
                -- Close all interfaces
                CloseAllInterfaces()
            end
        end)
        
        table.insert(ClientState.InputConnections, keyboardConnection)
    end
    
    -- Touch handling for mobile
    if ClientState.IsMobile then
        -- Mobile touch handling will be set up in MobileAdapter
        MobileAdapter.SetupTouchHandling(ClientState.UIElements.MobileHUD)
    end
end

-- Set up remote event handlers
local function SetupRemoteEventHandlers()
    -- Player welcome message
    RemoteEvents.OnClientEvent("PlayerWelcome", function(data)
        print("🎉 Welcome to Cultivation Game!")
        print("Server uptime:", math.floor(data.ServerTime), "seconds")
        print("Players online:", data.PlayerCount)
        
        -- Show welcome notification
        UIManager.ShowNotification("Welcome to the Cultivation World!", "success", 5)
    end)
    
    -- Player data update
    RemoteEvents.OnClientEvent("PlayerDataUpdate", function(data)
        ClientState.PlayerData = data
        UpdatePlayerUI(data)
    end)
    
    -- World state update
    RemoteEvents.OnClientEvent("WorldStateUpdate", function(data)
        print("🌍 World state updated")
        UpdateWorldUI(data)
    end)
    
    -- World event notifications
    RemoteEvents.OnClientEvent("WorldEventStarted", function(data)
        UIManager.ShowNotification("World Event: " .. data.name .. " has begun!", "info", 8)
    end)
    
    RemoteEvents.OnClientEvent("WorldEventEnded", function(data)
        UIManager.ShowNotification("World Event: " .. data.name .. " has ended.", "info", 5)
    end)
    
    -- Combat notifications
    RemoteEvents.OnClientEvent("CombatStarted", function(data)
        UIManager.ShowNotification("Combat started with " .. data.opponent, "warning", 3)
    end)
    
    -- Cultivation progress
    RemoteEvents.OnClientEvent("CultivationProgress", function(data)
        if ClientState.UIElements.CultivationInterface then
            CultivationInterface.UpdateProgress(
                ClientState.UIElements.CultivationInterface,
                data.progress,
                data.currentRealm,
                data.nextRealm
            )
        end
    end)
end

-- Update player UI with new data
local function UpdatePlayerUI(data)
    if not ClientState.IsInitialized then return end
    
    -- Update desktop HUD
    if not ClientState.IsMobile and ClientState.UIElements.PlayerInfo then
        PlayerInfoPanel.UpdateData(ClientState.UIElements.PlayerInfo, data)
    end
    
    -- Update resource bars
    if ClientState.UIElements.ResourceBars then
        ResourceBars.UpdateResource(ClientState.UIElements.ResourceBars.health, data.health.current, data.health.max, "Health")
        ResourceBars.UpdateResource(ClientState.UIElements.ResourceBars.qi, data.qi.current, data.qi.max, "Qi")
        ResourceBars.UpdateResource(ClientState.UIElements.ResourceBars.mana, data.mana.current, data.mana.max, "Mana")
        ResourceBars.UpdateResource(ClientState.UIElements.ResourceBars.stamina, data.stamina.current, data.stamina.max, "Stamina")
    end
    
    -- Update mobile HUD
    if ClientState.IsMobile and ClientState.UIElements.MobileHUD then
        MobileAdapter.UpdateMobileHUD(ClientState.UIElements.MobileHUD, data)
    end
end

-- Update world UI
local function UpdateWorldUI(data)
    -- Update any world-related UI elements
    print("🌍 Updating world UI with", #data.activeEvents, "active events")
end

-- Interface toggle functions
function ToggleCultivationInterface()
    if ClientState.UIElements.CultivationInterface then
        if ClientState.UIElements.CultivationInterface.Visible then
            CultivationInterface.Hide(ClientState.UIElements.CultivationInterface)
        else
            CloseAllInterfaces()
            CultivationInterface.Show(ClientState.UIElements.CultivationInterface)
            ClientState.ActiveInterfaces.Cultivation = true
        end
    end
end

function ToggleMartialArtsInterface()
    -- TODO: Implement martial arts interface
    UIManager.ShowNotification("Martial Arts interface coming soon!", "info", 3)
end

function ToggleInventory()
    -- TODO: Implement inventory interface
    UIManager.ShowNotification("Inventory interface coming soon!", "info", 3)
end

function ToggleSectInterface()
    -- TODO: Implement sect interface
    UIManager.ShowNotification("Sect interface coming soon!", "info", 3)
end

function CloseAllInterfaces()
    -- Close all open interfaces
    if ClientState.UIElements.CultivationInterface then
        CultivationInterface.Hide(ClientState.UIElements.CultivationInterface)
    end
    
    ClientState.ActiveInterfaces = {}
end

-- Handle client shutdown
local function OnClientShutdown()
    print("🛑 Client shutting down...")
    
    -- Disconnect all input connections
    for _, connection in pairs(ClientState.InputConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    print("✅ Client shutdown complete")
end

-- Error handling
local function HandleClientError(err)
    warn("❌ Client Error:", err)
    warn("Stack trace:", debug.traceback())
    
    -- Show error to user
    if ClientState.IsInitialized then
        UIManager.ShowNotification("An error occurred. Please report this bug.", "error", 10)
    end
end

-- Initialize the client
local function StartClient()
    -- Wrap initialization in pcall for error handling
    local success, err = pcall(InitializeClientSystems)
    
    if not success then
        HandleClientError(err)
        return
    end
    
    -- Handle client shutdown
    game:BindToClose(OnClientShutdown)
    
    print("🚀 Cultivation Game Client is now running!")
end

-- Start the client
StartClient()

-- Export for debugging
_G.CultivationGameClient = {
    ClientState = ClientState,
    ToggleCultivationInterface = ToggleCultivationInterface,
    ToggleMartialArtsInterface = ToggleMartialArtsInterface,
    ToggleInventory = ToggleInventory,
    ToggleSectInterface = ToggleSectInterface,
    CloseAllInterfaces = CloseAllInterfaces,
    GetClientStats = function()
        return {
            IsInitialized = ClientState.IsInitialized,
            IsMobile = ClientState.IsMobile,
            ActiveInterfaces = ClientState.ActiveInterfaces,
            UIElementCount = 0 -- Count UI elements
        }
    end
}

