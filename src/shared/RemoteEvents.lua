--[[
    RemoteEvents.lua
    Centralized management of RemoteEvents and RemoteFunctions for client-server communication
    Provides type safety and rate limiting for network calls
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEvents = {}

-- Rate limiting configuration
local RATE_LIMIT_WINDOW = 60 -- seconds
local MAX_CALLS_PER_WINDOW = 60
local rateLimitData = {}

-- Create RemoteEvents folder if it doesn't exist
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
end

-- Create RemoteFunctions folder if it doesn't exist
local remoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not remoteFunctionsFolder then
    remoteFunctionsFolder = Instance.new("Folder")
    remoteFunctionsFolder.Name = "RemoteFunctions"
    remoteFunctionsFolder.Parent = ReplicatedStorage
end

-- Helper function to create or get RemoteEvent
local function getOrCreateRemoteEvent(name)
    local remoteEvent = remoteEventsFolder:FindFirstChild(name)
    if not remoteEvent then
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = remoteEventsFolder
    end
    return remoteEvent
end

-- Helper function to create or get RemoteFunction
local function getOrCreateRemoteFunction(name)
    local remoteFunction = remoteFunctionsFolder:FindFirstChild(name)
    if not remoteFunction then
        remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = name
        remoteFunction.Parent = remoteFunctionsFolder
    end
    return remoteFunction
end

-- Rate limiting function
local function checkRateLimit(player, eventName)
    if not RunService:IsServer() then
        return true -- Client doesn't need rate limiting
    end
    
    local userId = player.UserId
    local currentTime = tick()
    
    if not rateLimitData[userId] then
        rateLimitData[userId] = {}
    end
    
    if not rateLimitData[userId][eventName] then
        rateLimitData[userId][eventName] = {
            calls = {},
            totalCalls = 0
        }
    end
    
    local playerData = rateLimitData[userId][eventName]
    
    -- Remove old calls outside the window
    local cutoffTime = currentTime - RATE_LIMIT_WINDOW
    for i = #playerData.calls, 1, -1 do
        if playerData.calls[i] < cutoffTime then
            table.remove(playerData.calls, i)
        end
    end
    
    -- Check if player has exceeded rate limit
    if #playerData.calls >= MAX_CALLS_PER_WINDOW then
        warn("Rate limit exceeded for player", player.Name, "on event", eventName)
        return false
    end
    
    -- Add current call
    table.insert(playerData.calls, currentTime)
    playerData.totalCalls = playerData.totalCalls + 1
    
    return true
end

-- Wrapper function for RemoteEvent:FireClient with rate limiting
local function fireClientSafe(remoteEvent, player, ...)
    if RunService:IsServer() then
        remoteEvent:FireClient(player, ...)
    end
end

-- Wrapper function for RemoteEvent:FireServer with rate limiting
local function fireServerSafe(remoteEvent, ...)
    if RunService:IsClient() then
        remoteEvent:FireServer(...)
    end
end

-- Player Data Events
RemoteEvents.PlayerDataSync = getOrCreateRemoteEvent("PlayerDataSync")
RemoteEvents.PlayerDataUpdate = getOrCreateRemoteEvent("PlayerDataUpdate")
RemoteEvents.PlayerStatsUpdate = getOrCreateRemoteEvent("PlayerStatsUpdate")

-- Cultivation Events
RemoteEvents.StartCultivation = getOrCreateRemoteEvent("StartCultivation")
RemoteEvents.StopCultivation = getOrCreateRemoteEvent("StopCultivation")
RemoteEvents.CultivationProgress = getOrCreateRemoteEvent("CultivationProgress")
RemoteEvents.AttemptBreakthrough = getOrCreateRemoteEvent("AttemptBreakthrough")
RemoteEvents.BreakthroughResult = getOrCreateRemoteEvent("BreakthroughResult")
RemoteEvents.QiUpdate = getOrCreateRemoteEvent("QiUpdate")

-- Martial Arts Events
RemoteEvents.StartMartialTraining = getOrCreateRemoteEvent("StartMartialTraining")
RemoteEvents.StopMartialTraining = getOrCreateRemoteEvent("StopMartialTraining")
RemoteEvents.MartialProgress = getOrCreateRemoteEvent("MartialProgress")
RemoteEvents.IntentVisualization = getOrCreateRemoteEvent("IntentVisualization")
RemoteEvents.EmotionStateChange = getOrCreateRemoteEvent("EmotionStateChange")
RemoteEvents.GangQiUpdate = getOrCreateRemoteEvent("GangQiUpdate")

-- Combat Events
RemoteEvents.InitiateCombat = getOrCreateRemoteEvent("InitiateCombat")
RemoteEvents.CombatAction = getOrCreateRemoteEvent("CombatAction")
RemoteEvents.CombatResult = getOrCreateRemoteEvent("CombatResult")
RemoteEvents.CombatEnd = getOrCreateRemoteEvent("CombatEnd")
RemoteEvents.DamageDealt = getOrCreateRemoteEvent("DamageDealt")
RemoteEvents.HealingReceived = getOrCreateRemoteEvent("HealingReceived")

-- Sect Events
RemoteEvents.CreateSect = getOrCreateRemoteEvent("CreateSect")
RemoteEvents.JoinSect = getOrCreateRemoteEvent("JoinSect")
RemoteEvents.LeaveSect = getOrCreateRemoteEvent("LeaveSect")
RemoteEvents.SectInvitation = getOrCreateRemoteEvent("SectInvitation")
RemoteEvents.SectUpdate = getOrCreateRemoteEvent("SectUpdate")
RemoteEvents.SectWarDeclaration = getOrCreateRemoteEvent("SectWarDeclaration")
RemoteEvents.SectContribution = getOrCreateRemoteEvent("SectContribution")

-- Resource Events
RemoteEvents.GatherResource = getOrCreateRemoteEvent("GatherResource")
RemoteEvents.ResourceUpdate = getOrCreateRemoteEvent("ResourceUpdate")
RemoteEvents.CraftItem = getOrCreateRemoteEvent("CraftItem")
RemoteEvents.UseItem = getOrCreateRemoteEvent("UseItem")
RemoteEvents.TradeRequest = getOrCreateRemoteEvent("TradeRequest")
RemoteEvents.TradeResponse = getOrCreateRemoteEvent("TradeResponse")

-- World Events
RemoteEvents.WorldEventNotification = getOrCreateRemoteEvent("WorldEventNotification")
RemoteEvents.WorldEventParticipation = getOrCreateRemoteEvent("WorldEventParticipation")
RemoteEvents.WorldEventEnded = getOrCreateRemoteEvent("WorldEventEnded")

-- UI Events
RemoteEvents.UIUpdate = getOrCreateRemoteEvent("UIUpdate")
RemoteEvents.NotificationSend = getOrCreateRemoteEvent("NotificationSend")
RemoteEvents.ChatMessage = getOrCreateRemoteEvent("ChatMessage")
RemoteEvents.SystemMessage = getOrCreateRemoteEvent("SystemMessage")

-- Admin Events
RemoteEvents.AdminCommand = getOrCreateRemoteEvent("AdminCommand")
RemoteEvents.AdminResponse = getOrCreateRemoteEvent("AdminResponse")

-- Remote Functions (for request-response patterns)
RemoteEvents.GetPlayerData = getOrCreateRemoteFunction("GetPlayerData")
RemoteEvents.GetSectInfo = getOrCreateRemoteFunction("GetSectInfo")
RemoteEvents.GetLeaderboard = getOrCreateRemoteFunction("GetLeaderboard")
RemoteEvents.GetMarketData = getOrCreateRemoteFunction("GetMarketData")
RemoteEvents.ValidateAction = getOrCreateRemoteFunction("ValidateAction")

-- Server-side event handlers with rate limiting
if RunService:IsServer() then
    -- Add rate limiting to all RemoteEvents
    for eventName, remoteEvent in pairs(RemoteEvents) do
        if typeof(remoteEvent) == "Instance" and remoteEvent:IsA("RemoteEvent") then
            remoteEvent.OnServerEvent:Connect(function(player, ...)
                if checkRateLimit(player, eventName) then
                    -- Event is allowed, let it proceed
                    -- The actual handling will be done by the specific system modules
                else
                    -- Rate limit exceeded, ignore the event
                    return
                end
            end)
        end
    end
end

-- Utility functions for safe remote calls
function RemoteEvents.FireClient(eventName, player, ...)
    local remoteEvent = RemoteEvents[eventName]
    if remoteEvent and typeof(remoteEvent) == "Instance" and remoteEvent:IsA("RemoteEvent") then
        fireClientSafe(remoteEvent, player, ...)
    else
        warn("Invalid RemoteEvent:", eventName)
    end
end

function RemoteEvents.FireAllClients(eventName, ...)
    local remoteEvent = RemoteEvents[eventName]
    if remoteEvent and typeof(remoteEvent) == "Instance" and remoteEvent:IsA("RemoteEvent") then
        if RunService:IsServer() then
            remoteEvent:FireAllClients(...)
        end
    else
        warn("Invalid RemoteEvent:", eventName)
    end
end

function RemoteEvents.FireServer(eventName, ...)
    local remoteEvent = RemoteEvents[eventName]
    if remoteEvent and typeof(remoteEvent) == "Instance" and remoteEvent:IsA("RemoteEvent") then
        fireServerSafe(remoteEvent, ...)
    else
        warn("Invalid RemoteEvent:", eventName)
    end
end

function RemoteEvents.InvokeServer(functionName, ...)
    local remoteFunction = RemoteEvents[functionName]
    if remoteFunction and typeof(remoteFunction) == "Instance" and remoteFunction:IsA("RemoteFunction") then
        if RunService:IsClient() then
            return remoteFunction:InvokeServer(...)
        end
    else
        warn("Invalid RemoteFunction:", functionName)
    end
    return nil
end

function RemoteEvents.InvokeClient(functionName, player, ...)
    local remoteFunction = RemoteEvents[functionName]
    if remoteFunction and typeof(remoteFunction) == "Instance" and remoteFunction:IsA("RemoteFunction") then
        if RunService:IsServer() then
            local success, result = pcall(function()
                return remoteFunction:InvokeClient(player, ...)
            end)
            if success then
                return result
            else
                warn("RemoteFunction invocation failed:", result)
                return nil
            end
        end
    else
        warn("Invalid RemoteFunction:", functionName)
    end
    return nil
end

-- Connect event handlers for specific events
function RemoteEvents.ConnectEvent(eventName, handler)
    local remoteEvent = RemoteEvents[eventName]
    if remoteEvent and typeof(remoteEvent) == "Instance" and remoteEvent:IsA("RemoteEvent") then
        if RunService:IsServer() then
            remoteEvent.OnServerEvent:Connect(handler)
        else
            remoteEvent.OnClientEvent:Connect(handler)
        end
    else
        warn("Invalid RemoteEvent:", eventName)
    end
end

function RemoteEvents.ConnectFunction(functionName, handler)
    local remoteFunction = RemoteEvents[functionName]
    if remoteFunction and typeof(remoteFunction) == "Instance" and remoteFunction:IsA("RemoteFunction") then
        if RunService:IsServer() then
            remoteFunction.OnServerInvoke = handler
        else
            remoteFunction.OnClientInvoke = handler
        end
    else
        warn("Invalid RemoteFunction:", functionName)
    end
end

-- Cleanup function for rate limiting data
function RemoteEvents.CleanupRateLimitData()
    local currentTime = tick()
    local cutoffTime = currentTime - RATE_LIMIT_WINDOW
    
    for userId, userData in pairs(rateLimitData) do
        for eventName, eventData in pairs(userData) do
            -- Remove old calls
            for i = #eventData.calls, 1, -1 do
                if eventData.calls[i] < cutoffTime then
                    table.remove(eventData.calls, i)
                end
            end
            
            -- Remove empty event data
            if #eventData.calls == 0 then
                userData[eventName] = nil
            end
        end
        
        -- Remove empty user data
        if next(userData) == nil then
            rateLimitData[userId] = nil
        end
    end
end

-- Start cleanup loop on server
if RunService:IsServer() then
    spawn(function()
        while true do
            wait(RATE_LIMIT_WINDOW)
            RemoteEvents.CleanupRateLimitData()
        end
    end)
end

-- Event validation functions
function RemoteEvents.ValidatePlayerDataUpdate(data)
    if type(data) ~= "table" then
        return false, "Data must be a table"
    end
    
    -- Add specific validation rules here
    return true, "Valid"
end

function RemoteEvents.ValidateCombatAction(action)
    if type(action) ~= "table" then
        return false, "Action must be a table"
    end
    
    if not action.type or type(action.type) ~= "string" then
        return false, "Action must have a valid type"
    end
    
    local validActions = {"Attack", "Block", "Dodge", "UseSkill", "Retreat"}
    local isValidAction = false
    for _, validAction in ipairs(validActions) do
        if action.type == validAction then
            isValidAction = true
            break
        end
    end
    
    if not isValidAction then
        return false, "Invalid action type"
    end
    
    return true, "Valid"
end

function RemoteEvents.ValidateResourceGather(resourceType, amount)
    if type(resourceType) ~= "string" then
        return false, "Resource type must be a string"
    end
    
    if type(amount) ~= "number" or amount <= 0 or amount > 1000 then
        return false, "Invalid amount"
    end
    
    return true, "Valid"
end

-- Debug functions
function RemoteEvents.GetRateLimitStats(player)
    if RunService:IsServer() and player then
        local userId = player.UserId
        return rateLimitData[userId] or {}
    end
    return {}
end

function RemoteEvents.PrintRemoteEvents()
    print("Available RemoteEvents:")
    for name, remoteEvent in pairs(RemoteEvents) do
        if typeof(remoteEvent) == "Instance" then
            print(" -", name, "(" .. remoteEvent.ClassName .. ")")
        end
    end
end

return RemoteEvents

