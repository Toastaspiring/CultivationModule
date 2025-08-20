--[[
    MobileAdapter.lua (ModuleScript)
    Handles mobile device detection and UI adaptation
]]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local MobileAdapter = {}

-- Check if device is mobile
function MobileAdapter.IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Get screen size
function MobileAdapter.GetScreenSize()
    local viewport = workspace.CurrentCamera.ViewportSize
    return viewport
end

-- Create mobile-optimized HUD
function MobileAdapter.CreateMobileHUD(parent)
    local mobileHUD = Instance.new("Frame")
    mobileHUD.Name = "MobileHUD"
    mobileHUD.Size = UDim2.new(1, 0, 1, 0)
    mobileHUD.BackgroundTransparency = 1
    mobileHUD.Parent = parent
    
    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    topBar.BackgroundTransparency = 0.3
    topBar.BorderSizePixel = 0
    topBar.Parent = mobileHUD
    
    -- Player name
    local playerName = Instance.new("TextLabel")
    playerName.Name = "PlayerName"
    playerName.Size = UDim2.new(0.6, 0, 1, 0)
    playerName.Position = UDim2.new(0, 10, 0, 0)
    playerName.Text = "Player - Lv. 1"
    playerName.Font = Enum.Font.SourceSansBold
    playerName.TextSize = 18
    playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerName.BackgroundTransparency = 1
    playerName.TextXAlignment = Enum.TextXAlignment.Left
    playerName.Parent = topBar
    
    -- Settings button
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Name = "SettingsButton"
    settingsBtn.Size = UDim2.new(0, 50, 0, 50)
    settingsBtn.Position = UDim2.new(1, -60, 0, 5)
    settingsBtn.Text = "⚙️"
    settingsBtn.Font = Enum.Font.SourceSans
    settingsBtn.TextSize = 24
    settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingsBtn.BackgroundTransparency = 1
    settingsBtn.Parent = topBar
    
    -- Resource bars container
    local resourceContainer = Instance.new("Frame")
    resourceContainer.Name = "ResourceContainer"
    resourceContainer.Size = UDim2.new(1, -20, 0, 60)
    resourceContainer.Position = UDim2.new(0, 10, 1, -140)
    resourceContainer.BackgroundTransparency = 1
    resourceContainer.Parent = mobileHUD
    
    -- Health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 0, 25)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = resourceContainer
    
    local healthCorner = Instance.new("UICorner")
    healthCorner.CornerRadius = UDim.new(0, 6)
    healthCorner.Parent = healthBar
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 1, 0)
    healthLabel.Position = UDim2.new(0, 0, 0, 0)
    healthLabel.Text = "Health: 100/100"
    healthLabel.Font = Enum.Font.SourceSansBold
    healthLabel.TextSize = 14
    healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Parent = healthBar
    
    -- Qi bar
    local qiBar = Instance.new("Frame")
    qiBar.Name = "QiBar"
    qiBar.Size = UDim2.new(1, 0, 0, 25)
    qiBar.Position = UDim2.new(0, 0, 0, 35)
    qiBar.BackgroundColor3 = Color3.fromRGB(26, 35, 126)
    qiBar.BorderSizePixel = 0
    qiBar.Parent = resourceContainer
    
    local qiCorner = Instance.new("UICorner")
    qiCorner.CornerRadius = UDim.new(0, 6)
    qiCorner.Parent = qiBar
    
    local qiLabel = Instance.new("TextLabel")
    qiLabel.Name = "QiLabel"
    qiLabel.Size = UDim2.new(1, 0, 1, 0)
    qiLabel.Position = UDim2.new(0, 0, 0, 0)
    qiLabel.Text = "Qi: 100/100"
    qiLabel.Font = Enum.Font.SourceSansBold
    qiLabel.TextSize = 14
    qiLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    qiLabel.BackgroundTransparency = 1
    qiLabel.Parent = qiBar
    
    -- Bottom button grid
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -20, 0, 120)
    buttonContainer.Position = UDim2.new(0, 10, 1, -130)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mobileHUD
    
    local buttonLayout = Instance.new("UIGridLayout")
    buttonLayout.CellSize = UDim2.new(0, 110, 0, 50)
    buttonLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
    buttonLayout.Parent = buttonContainer
    
    -- Create mobile buttons
    local buttons = {
        {text = "Cultivate", color = Color3.fromRGB(26, 35, 126), order = 1},
        {text = "Martial Arts", color = Color3.fromRGB(183, 28, 28), order = 2},
        {text = "Inventory", color = Color3.fromRGB(66, 66, 66), order = 3},
        {text = "Market", color = Color3.fromRGB(255, 143, 0), order = 4},
        {text = "Sect", color = Color3.fromRGB(27, 94, 32), order = 5},
        {text = "Combat", color = Color3.fromRGB(230, 81, 0), order = 6}
    }
    
    local buttonElements = {}
    for _, buttonData in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.text .. "Button"
        button.Size = UDim2.new(0, 110, 0, 50)
        button.Text = buttonData.text
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 14
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundColor3 = buttonData.color
        button.BorderSizePixel = 0
        button.LayoutOrder = buttonData.order
        button.Parent = buttonContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        
        buttonElements[buttonData.text] = button
    end
    
    return mobileHUD, buttonElements
end

-- Set up touch handling for mobile
function MobileAdapter.SetupTouchHandling(mobileHUD)
    if not mobileHUD then return end
    
    local buttonContainer = mobileHUD:FindFirstChild("ButtonContainer")
    if not buttonContainer then return end
    
    -- Add touch feedback to all buttons
    for _, button in pairs(buttonContainer:GetChildren()) do
        if button:IsA("TextButton") then
            button.MouseButton1Down:Connect(function()
                button.BackgroundTransparency = 0.3
            end)
            
            button.MouseButton1Up:Connect(function()
                button.BackgroundTransparency = 0
            end)
            
            button.TouchLongPress:Connect(function()
                -- Handle long press for additional options
                print("Long press detected on", button.Name)
            end)
        end
    end
end

-- Update mobile HUD with player data
function MobileAdapter.UpdateMobileHUD(mobileHUD, playerData)
    if not mobileHUD or not playerData then return end
    
    -- Update player name
    local topBar = mobileHUD:FindFirstChild("TopBar")
    if topBar then
        local playerName = topBar:FindFirstChild("PlayerName")
        if playerName and playerData.name and playerData.level then
            playerName.Text = playerData.name .. " - Lv. " .. playerData.level
        end
    end
    
    -- Update resource bars
    local resourceContainer = mobileHUD:FindFirstChild("ResourceContainer")
    if resourceContainer then
        local healthBar = resourceContainer:FindFirstChild("HealthBar")
        local qiBar = resourceContainer:FindFirstChild("QiBar")
        
        if healthBar and playerData.health then
            local healthLabel = healthBar:FindFirstChild("HealthLabel")
            if healthLabel then
                healthLabel.Text = "Health: " .. playerData.health.current .. "/" .. playerData.health.max
            end
            
            -- Update bar width
            local percentage = playerData.health.current / playerData.health.max
            healthBar.Size = UDim2.new(percentage, 0, 0, 25)
        end
        
        if qiBar and playerData.qi then
            local qiLabel = qiBar:FindFirstChild("QiLabel")
            if qiLabel then
                qiLabel.Text = "Qi: " .. playerData.qi.current .. "/" .. playerData.qi.max
            end
            
            -- Update bar width
            local percentage = playerData.qi.current / playerData.qi.max
            qiBar.Size = UDim2.new(percentage, 0, 0, 25)
        end
    end
end

-- Adapt UI for mobile constraints
function MobileAdapter.AdaptUIForMobile(ui)
    if not MobileAdapter.IsMobile() then return end
    
    local screenSize = MobileAdapter.GetScreenSize()
    local isSmallScreen = screenSize.X < 768 or screenSize.Y < 1024
    
    -- Adjust UI scale
    local scale = isSmallScreen and 1.2 or 1.0
    
    -- Find and modify UI elements
    for _, element in pairs(ui:GetDescendants()) do
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            -- Increase text size for mobile
            element.TextSize = element.TextSize * scale
        elseif element:IsA("Frame") and element.Name:find("Button") then
            -- Make buttons larger for touch
            element.Size = UDim2.new(
                element.Size.X.Scale,
                element.Size.X.Offset,
                element.Size.Y.Scale,
                math.max(element.Size.Y.Offset, 44) -- Minimum 44px height
            )
        end
    end
end

return MobileAdapter

