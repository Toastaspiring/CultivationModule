--[[
    UIManager.lua
    Manages the main game UI, system messages, and player information display
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UIManager = {}

-- UI Elements
local mainFrame = nil
local systemMessageFrame = nil
local playerInfoFrame = nil
local sectInfoFrame = nil

-- Message queue for system messages
local messageQueue = {}
local isShowingMessage = false

function UIManager:Initialize()
    self:CreateMainUI()
    self:CreateSystemMessageUI()
    self:CreatePlayerInfoUI()
    self:CreateSectInfoUI()
    
    print("UIManager initialized")
end

function UIManager:CreateMainUI()
    -- Create main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CultivationGameUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main frame container
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui
end

function UIManager:CreateSystemMessageUI()
    -- System message frame
    systemMessageFrame = Instance.new("Frame")
    systemMessageFrame.Name = "SystemMessages"
    systemMessageFrame.Size = UDim2.new(0, 400, 0, 100)
    systemMessageFrame.Position = UDim2.new(0.5, -200, 0, 50)
    systemMessageFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    systemMessageFrame.BackgroundTransparency = 0.3
    systemMessageFrame.BorderSizePixel = 0
    systemMessageFrame.Visible = false
    systemMessageFrame.Parent = mainFrame
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = systemMessageFrame
    
    -- Message text
    local messageText = Instance.new("TextLabel")
    messageText.Name = "MessageText"
    messageText.Size = UDim2.new(1, -20, 1, -20)
    messageText.Position = UDim2.new(0, 10, 0, 10)
    messageText.BackgroundTransparency = 1
    messageText.Text = ""
    messageText.TextColor3 = Color3.new(1, 1, 1)
    messageText.TextScaled = true
    messageText.Font = Enum.Font.SourceSans
    messageText.Parent = systemMessageFrame
end

function UIManager:CreatePlayerInfoUI()
    -- Player info frame (top-left)
    playerInfoFrame = Instance.new("Frame")
    playerInfoFrame.Name = "PlayerInfo"
    playerInfoFrame.Size = UDim2.new(0, 300, 0, 150)
    playerInfoFrame.Position = UDim2.new(0, 20, 0, 20)
    playerInfoFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    playerInfoFrame.BackgroundTransparency = 0.2
    playerInfoFrame.BorderSizePixel = 0
    playerInfoFrame.Parent = mainFrame
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = playerInfoFrame
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(1, -20, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = playerInfoFrame
    
    -- Cultivation realm
    local cultivationLabel = Instance.new("TextLabel")
    cultivationLabel.Name = "CultivationRealm"
    cultivationLabel.Size = UDim2.new(1, -20, 0, 25)
    cultivationLabel.Position = UDim2.new(0, 10, 0, 45)
    cultivationLabel.BackgroundTransparency = 1
    cultivationLabel.Text = "Cultivation: Qi Refining"
    cultivationLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
    cultivationLabel.TextScaled = true
    cultivationLabel.Font = Enum.Font.SourceSans
    cultivationLabel.TextXAlignment = Enum.TextXAlignment.Left
    cultivationLabel.Parent = playerInfoFrame
    
    -- Martial realm
    local martialLabel = Instance.new("TextLabel")
    martialLabel.Name = "MartialRealm"
    martialLabel.Size = UDim2.new(1, -20, 0, 25)
    martialLabel.Position = UDim2.new(0, 10, 0, 75)
    martialLabel.BackgroundTransparency = 1
    martialLabel.Text = "Martial Arts: Third Rate"
    martialLabel.TextColor3 = Color3.new(1, 0.8, 0.8)
    martialLabel.TextScaled = true
    martialLabel.Font = Enum.Font.SourceSans
    martialLabel.TextXAlignment = Enum.TextXAlignment.Left
    martialLabel.Parent = playerInfoFrame
    
    -- Spirit stones
    local spiritStonesLabel = Instance.new("TextLabel")
    spiritStonesLabel.Name = "SpiritStones"
    spiritStonesLabel.Size = UDim2.new(1, -20, 0, 25)
    spiritStonesLabel.Position = UDim2.new(0, 10, 0, 105)
    spiritStonesLabel.BackgroundTransparency = 1
    spiritStonesLabel.Text = "Spirit Stones: 1000"
    spiritStonesLabel.TextColor3 = Color3.new(1, 1, 0.8)
    spiritStonesLabel.TextScaled = true
    spiritStonesLabel.Font = Enum.Font.SourceSans
    spiritStonesLabel.TextXAlignment = Enum.TextXAlignment.Left
    spiritStonesLabel.Parent = playerInfoFrame
end

function UIManager:CreateSectInfoUI()
    -- Sect info frame (top-right)
    sectInfoFrame = Instance.new("Frame")
    sectInfoFrame.Name = "SectInfo"
    sectInfoFrame.Size = UDim2.new(0, 250, 0, 100)
    sectInfoFrame.Position = UDim2.new(1, -270, 0, 20)
    sectInfoFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    sectInfoFrame.BackgroundTransparency = 0.2
    sectInfoFrame.BorderSizePixel = 0
    sectInfoFrame.Visible = false
    sectInfoFrame.Parent = mainFrame
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = sectInfoFrame
    
    -- Sect name
    local sectNameLabel = Instance.new("TextLabel")
    sectNameLabel.Name = "SectName"
    sectNameLabel.Size = UDim2.new(1, -20, 0, 30)
    sectNameLabel.Position = UDim2.new(0, 10, 0, 10)
    sectNameLabel.BackgroundTransparency = 1
    sectNameLabel.Text = "No Sect"
    sectNameLabel.TextColor3 = Color3.new(1, 1, 1)
    sectNameLabel.TextScaled = true
    sectNameLabel.Font = Enum.Font.SourceSansBold
    sectNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    sectNameLabel.Parent = sectInfoFrame
    
    -- Sect rank
    local sectRankLabel = Instance.new("TextLabel")
    sectRankLabel.Name = "SectRank"
    sectRankLabel.Size = UDim2.new(1, -20, 0, 25)
    sectRankLabel.Position = UDim2.new(0, 10, 0, 45)
    sectRankLabel.BackgroundTransparency = 1
    sectRankLabel.Text = "Rank: None"
    sectRankLabel.TextColor3 = Color3.new(0.8, 1, 0.8)
    sectRankLabel.TextScaled = true
    sectRankLabel.Font = Enum.Font.SourceSans
    sectRankLabel.TextXAlignment = Enum.TextXAlignment.Left
    sectRankLabel.Parent = sectInfoFrame
    
    -- Contribution points
    local contributionLabel = Instance.new("TextLabel")
    contributionLabel.Name = "ContributionPoints"
    contributionLabel.Size = UDim2.new(1, -20, 0, 25)
    contributionLabel.Position = UDim2.new(0, 10, 0, 75)
    contributionLabel.BackgroundTransparency = 1
    contributionLabel.Text = "Contribution: 0"
    contributionLabel.TextColor3 = Color3.new(1, 0.8, 1)
    contributionLabel.TextScaled = true
    contributionLabel.Font = Enum.Font.SourceSans
    contributionLabel.TextXAlignment = Enum.TextXAlignment.Left
    contributionLabel.Parent = sectInfoFrame
end

function UIManager:ShowSystemMessage(message)
    table.insert(messageQueue, message)
    
    if not isShowingMessage then
        self:ProcessMessageQueue()
    end
end

function UIManager:ProcessMessageQueue()
    if #messageQueue == 0 then
        isShowingMessage = false
        return
    end
    
    isShowingMessage = true
    local message = table.remove(messageQueue, 1)
    
    local messageText = systemMessageFrame:FindFirstChild("MessageText")
    if messageText then
        messageText.Text = message
    end
    
    -- Show message
    systemMessageFrame.Visible = true
    systemMessageFrame.Position = UDim2.new(0.5, -200, 0, -100)
    
    -- Animate in
    local tweenIn = TweenService:Create(systemMessageFrame, 
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -200, 0, 50)}
    )
    
    tweenIn:Play()
    tweenIn.Completed:Connect(function()
        -- Wait then animate out
        wait(3)
        
        local tweenOut = TweenService:Create(systemMessageFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -200, 0, -100)}
        )
        
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            systemMessageFrame.Visible = false
            self:ProcessMessageQueue()
        end)
    end)
end

function UIManager:UpdatePlayerInfo(playerData)
    if not playerData then return end
    
    -- Update cultivation realm
    local cultivationLabel = playerInfoFrame:FindFirstChild("CultivationRealm")
    if cultivationLabel then
        local realmName = "Qi Refining" -- Default, would get from GameConstants
        cultivationLabel.Text = "Cultivation: " .. realmName
    end
    
    -- Update martial realm
    local martialLabel = playerInfoFrame:FindFirstChild("MartialRealm")
    if martialLabel then
        local realmName = "Third Rate" -- Default, would get from GameConstants
        martialLabel.Text = "Martial Arts: " .. realmName
    end
    
    -- Update spirit stones
    local spiritStonesLabel = playerInfoFrame:FindFirstChild("SpiritStones")
    if spiritStonesLabel and playerData.resources then
        spiritStonesLabel.Text = "Spirit Stones: " .. (playerData.resources.spiritStones or 0)
    end
end

function UIManager:UpdateSectInfo(sectData)
    if not sectData then
        sectInfoFrame.Visible = false
        return
    end
    
    sectInfoFrame.Visible = true
    
    -- Update sect name
    local sectNameLabel = sectInfoFrame:FindFirstChild("SectName")
    if sectNameLabel then
        sectNameLabel.Text = sectData.name or "Unknown Sect"
    end
    
    -- Update rank (would need to get rank name from sect data)
    local sectRankLabel = sectInfoFrame:FindFirstChild("SectRank")
    if sectRankLabel then
        sectRankLabel.Text = "Rank: " .. (sectData.rankName or "Member")
    end
    
    -- Update contribution points
    local contributionLabel = sectInfoFrame:FindFirstChild("ContributionPoints")
    if contributionLabel then
        contributionLabel.Text = "Contribution: " .. (sectData.contributionPoints or 0)
    end
end

function UIManager:ToggleSectUI()
    -- This would open a detailed sect management UI
    self:ShowSystemMessage("Sect UI not yet implemented")
end

function UIManager:ToggleStatsUI()
    -- This would open a detailed player statistics UI
    self:ShowSystemMessage("Stats UI not yet implemented")
end

function UIManager:CreateButton(parent, name, text, position, size, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.SourceSans
    button.TextScaled = true
    button.BorderSizePixel = 0
    button.Parent = parent
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)}):Play()
    end)
    
    -- Click callback
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

function UIManager:CreateProgressBar(parent, name, position, size, color)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    -- Progress fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = color or Color3.new(0, 0.8, 0)
    fill.BorderSizePixel = 0
    fill.Parent = frame
    
    -- Fill corner rounding
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill
    
    return frame
end

function UIManager:UpdateProgressBar(progressBar, percentage)
    local fill = progressBar:FindFirstChild("Fill")
    if fill then
        local targetSize = UDim2.new(math.clamp(percentage, 0, 1), 0, 1, 0)
        TweenService:Create(fill, TweenInfo.new(0.3), {Size = targetSize}):Play()
    end
end

return UIManager

