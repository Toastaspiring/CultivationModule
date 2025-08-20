--[[
    CultivationInterface.lua (ModuleScript)
    Creates and manages the cultivation interface UI
]]

local TweenService = game:GetService("TweenService")

local CultivationInterface = {}

-- Create the cultivation interface
function CultivationInterface.Create(parent)
    local panel = Instance.new("Frame")
    panel.Name = "CultivationInterface"
    panel.Size = UDim2.new(0, 800, 0, 600)
    panel.Position = UDim2.new(0.5, -400, 0.5, -300)
    panel.BackgroundColor3 = Color3.fromRGB(26, 35, 126)
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel
    
    -- Add border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 143, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = panel
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "🏔️ CULTIVATION INTERFACE 🏔️"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.TextColor3 = Color3.fromRGB(255, 143, 0)
    title.BackgroundTransparency = 1
    title.Parent = panel
    
    -- Separator
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -40, 0, 3)
    separator.Position = UDim2.new(0, 20, 0, 55)
    separator.BackgroundColor3 = Color3.fromRGB(255, 143, 0)
    separator.BorderSizePixel = 0
    separator.Parent = panel
    
    -- Current realm display
    local realmLabel = Instance.new("TextLabel")
    realmLabel.Name = "RealmLabel"
    realmLabel.Size = UDim2.new(1, -40, 0, 30)
    realmLabel.Position = UDim2.new(0, 20, 0, 70)
    realmLabel.Text = "Current Realm: Qi Refining (Stage 1/9)"
    realmLabel.Font = Enum.Font.SourceSansBold
    realmLabel.TextSize = 18
    realmLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    realmLabel.BackgroundTransparency = 1
    realmLabel.TextXAlignment = Enum.TextXAlignment.Left
    realmLabel.Parent = panel
    
    -- Progress container
    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, -40, 0, 60)
    progressContainer.Position = UDim2.new(0, 20, 0, 105)
    progressContainer.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    progressContainer.BackgroundTransparency = 0.3
    progressContainer.BorderSizePixel = 0
    progressContainer.Parent = panel
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 8)
    progressCorner.Parent = progressContainer
    
    -- Progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0.1, 0, 0.6, 0) -- Start at 10%
    progressBar.Position = UDim2.new(0, 10, 0.2, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(0, 96, 100)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressContainer
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = progressBar
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, -20, 1, 0)
    progressText.Position = UDim2.new(0, 10, 0, 0)
    progressText.Text = "Progress: 10%"
    progressText.Font = Enum.Font.SourceSans
    progressText.TextSize = 14
    progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    progressText.BackgroundTransparency = 1
    progressText.TextXAlignment = Enum.TextXAlignment.Left
    progressText.Parent = progressContainer
    
    -- Action buttons
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -40, 0, 300)
    buttonContainer.Position = UDim2.new(0, 20, 0, 180)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = panel
    
    -- Create action buttons
    local buttons = {
        {name = "Cultivate", desc = "Begin cultivation session", pos = UDim2.new(0, 0, 0, 0)},
        {name = "Breakthrough", desc = "Attempt realm breakthrough", pos = UDim2.new(0, 200, 0, 0)},
        {name = "Techniques", desc = "View cultivation techniques", pos = UDim2.new(0, 400, 0, 0)},
        {name = "Alchemy", desc = "Open alchemy furnace", pos = UDim2.new(0, 0, 0, 80)},
        {name = "Formations", desc = "Set up formations", pos = UDim2.new(0, 200, 0, 80)},
        {name = "Meditation", desc = "Enter meditation", pos = UDim2.new(0, 400, 0, 80)}
    }
    
    local actionButtons = {}
    for _, buttonData in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.name .. "Button"
        button.Size = UDim2.new(0, 180, 0, 60)
        button.Position = buttonData.pos
        button.Text = buttonData.name
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 16
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = Color3.fromRGB(26, 35, 126)
        button.BackgroundTransparency = 0.1
        button.BorderSizePixel = 0
        button.Parent = buttonContainer
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Description label
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, 0, 0, 20)
        descLabel.Position = UDim2.new(0, 0, 1, 5)
        descLabel.Text = buttonData.desc
        descLabel.Font = Enum.Font.SourceSans
        descLabel.TextSize = 12
        descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descLabel.BackgroundTransparency = 1
        descLabel.Parent = button
        
        actionButtons[buttonData.name] = button
    end
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 100, 0, 35)
    closeButton.Position = UDim2.new(0, 20, 1, -50)
    closeButton.Text = "Close"
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 16
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    closeButton.BorderSizePixel = 0
    closeButton.Parent = panel
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        CultivationInterface.Hide(panel)
    end)
    
    return panel, actionButtons
end

-- Show the cultivation interface
function CultivationInterface.Show(panel)
    if not panel then return end
    
    panel.Position = UDim2.new(0.5, -panel.Size.X.Offset/2, 1.5, 0)
    panel.Visible = true
    
    local tween = TweenService:Create(
        panel,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -panel.Size.X.Offset/2, 0.5, -panel.Size.Y.Offset/2)}
    )
    tween:Play()
end

-- Hide the cultivation interface
function CultivationInterface.Hide(panel)
    if not panel then return end
    
    local tween = TweenService:Create(
        panel,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -panel.Size.X.Offset/2, 1.5, 0)}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        panel.Visible = false
    end)
end

-- Update cultivation progress
function CultivationInterface.UpdateProgress(panel, percentage, currentRealm, nextRealm)
    if not panel then return end
    
    local progressContainer = panel:FindFirstChild("ProgressContainer")
    if not progressContainer then return end
    
    local progressBar = progressContainer:FindFirstChild("ProgressBar")
    local progressText = progressContainer:FindFirstChild("ProgressText")
    local realmLabel = panel:FindFirstChild("RealmLabel")
    
    if progressBar then
        local targetSize = UDim2.new(math.clamp(percentage / 100, 0, 1), 0, 0.6, 0)
        local tween = TweenService:Create(
            progressBar,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = targetSize}
        )
        tween:Play()
    end
    
    if progressText then
        progressText.Text = "Progress: " .. math.floor(percentage) .. "%"
    end
    
    if realmLabel and currentRealm then
        realmLabel.Text = "Current Realm: " .. currentRealm
    end
end

return CultivationInterface

