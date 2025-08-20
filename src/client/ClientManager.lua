--[[
    ClientManager.lua (ModuleScript)
    Client-side game management system
    Handles client state, UI coordination, and server communication
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ClientManager = {}

-- Client state
local clientState = {
    isInitialized = false,
    isMobile = false,
    playerData = {},
    uiElements = {},
    activeInterfaces = {},
    lastUpdate = 0
}

-- Initialize the client manager
function ClientManager.Initialize()
    print("📱 Initializing Client Manager...")
    
    -- Detect device type
    clientState.isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    
    -- Set up update loop
    ClientManager.StartUpdateLoop()
    
    clientState.isInitialized = true
    print("✅ Client Manager initialized successfully")
end

-- Start the main client update loop
function ClientManager.StartUpdateLoop()
    RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - clientState.lastUpdate >= 1/30 then -- 30 FPS update rate
            ClientManager.Update()
            clientState.lastUpdate = now
        end
    end)
end

-- Main client update function
function ClientManager.Update()
    if not clientState.isInitialized then return end
    
    -- Update any client-side systems that need regular updates
    ClientManager.UpdateUI()
    ClientManager.UpdateInput()
end

-- Update UI elements
function ClientManager.UpdateUI()
    -- Update any animated UI elements
    -- This could include progress bars, animations, etc.
end

-- Update input handling
function ClientManager.UpdateInput()
    -- Handle any continuous input (like held keys)
end

-- Set player data
function ClientManager.SetPlayerData(data)
    clientState.playerData = data
    print("📊 Player data updated")
end

-- Get player data
function ClientManager.GetPlayerData()
    return clientState.playerData
end

-- Register UI element
function ClientManager.RegisterUIElement(name, element)
    clientState.uiElements[name] = element
    print("🎨 UI element registered:", name)
end

-- Get UI element
function ClientManager.GetUIElement(name)
    return clientState.uiElements[name]
end

-- Set interface active state
function ClientManager.SetInterfaceActive(name, active)
    clientState.activeInterfaces[name] = active
    print("🖥️ Interface", name, active and "opened" or "closed")
end

-- Check if interface is active
function ClientManager.IsInterfaceActive(name)
    return clientState.activeInterfaces[name] or false
end

-- Get client statistics
function ClientManager.GetClientStats()
    return {
        isInitialized = clientState.isInitialized,
        isMobile = clientState.isMobile,
        uiElementCount = 0, -- Count UI elements
        activeInterfaceCount = 0, -- Count active interfaces
        playerDataLoaded = clientState.playerData ~= nil
    }
end

-- Check if mobile device
function ClientManager.IsMobile()
    return clientState.isMobile
end

-- Shutdown the client manager
function ClientManager.Shutdown()
    print("🛑 Shutting down Client Manager...")
    clientState.isInitialized = false
    print("✅ Client Manager shutdown complete")
end

return ClientManager

