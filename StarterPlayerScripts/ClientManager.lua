--[[
    ClientManager.lua
    Main client-side script that handles UI, input, and communication with server
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Import shared modules
local GameConstants = require(ReplicatedStorage.Shared.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

-- Client modules
local UIManager = require(script.Parent.UI.UIManager)
local CombatUI = require(script.Parent.Combat.CombatUI)
local CultivationUI = require(script.Parent.Cultivation.CultivationUI)
local ResourceUI = require(script.Parent.Resources.ResourceUI)

local ClientManager = {}

-- Player data cache
local playerData = {}
local isInitialized = false

function ClientManager:Initialize()
    if isInitialized then return end
    
    print("Initializing client manager for", player.Name)
    
    -- Set up remote event handlers
    self:SetupRemoteEvents()
    
    -- Initialize UI systems
    UIManager:Initialize()
    CombatUI:Initialize()
    CultivationUI:Initialize()
    ResourceUI:Initialize()
    
    -- Set up input handling
    self:SetupInputHandling()
    
    -- Request initial data from server
    RemoteEvents.FireServer("RequestPlayerData")
    
    isInitialized = true
end

function ClientManager:SetupRemoteEvents()
    -- Player data updates
    RemoteEvents.ConnectClient("PlayerDataUpdate", function(data)
        playerData = data
        self:UpdateAllUI()
    end)
    
    -- Cultivation progress updates
    RemoteEvents.ConnectClient("CultivationProgress", function(data)
        CultivationUI:UpdateProgress(data)
    end)
    
    -- Martial arts progress updates
    RemoteEvents.ConnectClient("MartialProgress", function(data)
        CultivationUI:UpdateMartialProgress(data)
    end)
    
    -- Combat events
    RemoteEvents.ConnectClient("CombatInvitation", function(data)
        CombatUI:ShowInvitation(data)
    end)
    
    RemoteEvents.ConnectClient("CombatStart", function(data)
        CombatUI:StartCombat(data)
    end)
    
    RemoteEvents.ConnectClient("CombatResult", function(data)
        CombatUI:ShowResult(data)
    end)
    
    RemoteEvents.ConnectClient("CombatEnd", function(data)
        CombatUI:EndCombat(data)
    end)
    
    -- Resource updates
    RemoteEvents.ConnectClient("ResourceUpdate", function(data)
        ResourceUI:UpdateResources(data)
    end)
    
    -- System messages
    RemoteEvents.ConnectClient("SystemMessage", function(message)
        UIManager:ShowSystemMessage(message)
    end)
    
    -- Sect updates
    RemoteEvents.ConnectClient("SectUpdate", function(data)
        UIManager:UpdateSectInfo(data)
    end)
    
    -- Intent visualization
    RemoteEvents.ConnectClient("IntentVisualization", function(data)
        self:ShowIntentVisualization(data)
    end)
    
    -- Emotion state changes
    RemoteEvents.ConnectClient("EmotionStateChange", function(data)
        self:UpdateEmotionEffects(data)
    end)
end

function ClientManager:SetupInputHandling()
    -- Cultivation hotkeys
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.C then
            -- Toggle cultivation UI
            CultivationUI:Toggle()
        elseif input.KeyCode == Enum.KeyCode.I then
            -- Toggle inventory
            ResourceUI:ToggleInventory()
        elseif input.KeyCode == Enum.KeyCode.M then
            -- Toggle market
            ResourceUI:ToggleMarket()
        elseif input.KeyCode == Enum.KeyCode.G then
            -- Toggle sect UI
            UIManager:ToggleSectUI()
        elseif input.KeyCode == Enum.KeyCode.P then
            -- Toggle player stats
            UIManager:ToggleStatsUI()
        end
    end)
    
    -- Mouse input for resource gathering
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = player:GetMouse()
            local target = mouse.Target
            
            if target and target:GetAttribute("ResourceNode") then
                local nodeId = target:GetAttribute("NodeId")
                local gatherType = target:GetAttribute("GatherType")
                RemoteEvents.FireServer("GatherResource", nodeId, gatherType)
            end
        end
    end)
end

function ClientManager:UpdateAllUI()
    if not playerData then return end
    
    UIManager:UpdatePlayerInfo(playerData)
    CultivationUI:UpdateData(playerData)
    ResourceUI:UpdateData(playerData)
end

function ClientManager:ShowIntentVisualization(data)
    if not data then return end
    
    -- Create visual effect for intent
    local startPos = data.startPosition
    local targetPos = data.targetPosition
    local color = data.color
    
    -- Create beam effect
    local beam = Instance.new("Beam")
    beam.Color = ColorSequence.new(color)
    beam.Transparency = NumberSequence.new(0.3)
    beam.Width0 = 2
    beam.Width1 = 2
    beam.FaceCamera = true
    
    -- Create attachment points
    local startAttachment = Instance.new("Attachment")
    local endAttachment = Instance.new("Attachment")
    
    startAttachment.Position = startPos
    endAttachment.Position = targetPos
    
    startAttachment.Parent = workspace
    endAttachment.Parent = workspace
    
    beam.Attachment0 = startAttachment
    beam.Attachment1 = endAttachment
    beam.Parent = workspace
    
    -- Animate and cleanup
    local tween = TweenService:Create(beam, TweenInfo.new(data.duration or 3), {
        Transparency = NumberSequence.new(1)
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        beam:Destroy()
        startAttachment:Destroy()
        endAttachment:Destroy()
    end)
end

function ClientManager:UpdateEmotionEffects(data)
    if not player.Character then return end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create emotion aura effect
    local aura = humanoidRootPart:FindFirstChild("EmotionAura")
    if not aura then
        aura = Instance.new("SelectionBox")
        aura.Name = "EmotionAura"
        aura.Adornee = humanoidRootPart
        aura.Transparency = 0.7
        aura.LineThickness = 0.2
        aura.Parent = humanoidRootPart
    end
    
    aura.Color3 = data.color
    
    -- Create particle effect
    local particles = humanoidRootPart:FindFirstChild("EmotionParticles")
    if not particles then
        particles = Instance.new("Attachment")
        particles.Name = "EmotionParticles"
        particles.Parent = humanoidRootPart
        
        local particleEmitter = Instance.new("ParticleEmitter")
        particleEmitter.Color = ColorSequence.new(data.color)
        particleEmitter.Size = NumberSequence.new(0.5)
        particleEmitter.Lifetime = NumberRange.new(2, 4)
        particleEmitter.Rate = 10
        particleEmitter.SpreadAngle = Vector2.new(45, 45)
        particleEmitter.Speed = NumberRange.new(2, 5)
        particleEmitter.Parent = particles
    else
        local particleEmitter = particles:FindFirstChild("ParticleEmitter")
        if particleEmitter then
            particleEmitter.Color = ColorSequence.new(data.color)
        end
    end
end

function ClientManager:GetPlayerData()
    return playerData
end

-- Initialize when script loads
ClientManager:Initialize()

return ClientManager

