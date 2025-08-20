--[[
    ResourceBars.lua (ModuleScript)
    Creates and manages the resource bars UI (Health, Qi, Mana, Stamina)
]]

local TweenService = game:GetService("TweenService")

local ResourceBars = {}

-- Create the resource bars container
function ResourceBars.Create(parent)
    local container = Instance.new("Frame")
    container.Name = "ResourceBars"
    container.Size = UDim2.new(0, 400, 0, 80)
    container.Position = UDim2.new(0, 20, 1, -100)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    -- Create individual resource bars
    local resourceData = {}
    
    -- Health bar
    local healthContainer, healthBar = ResourceBars.CreateProgressBar(
        container,
        UDim2.new(1, 0, 0, 18),
        UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(244, 67, 54), -- Red
        Color3.fromRGB(66, 66, 66)   -- Gray background
    )
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 1, 0)
    healthLabel.Position = UDim2.new(0, 0, 0, 0)
    healthLabel.Text = "Health: 100/100"
    healthLabel.Font = Enum.Font.SourceSans
    healthLabel.TextSize = 12
    healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextXAlignment = Enum.TextXAlignment.Left
    healthLabel.Parent = healthContainer
    
    resourceData.health = {container = healthContainer, bar = healthBar, label = healthLabel}
    
    -- Qi bar
    local qiContainer, qiBar = ResourceBars.CreateProgressBar(
        container,
        UDim2.new(1, 0, 0, 18),
        UDim2.new(0, 0, 0, 20),
        Color3.fromRGB(26, 35, 126), -- Blue
        Color3.fromRGB(66, 66, 66)
    )
    
    local qiLabel = Instance.new("TextLabel")
    qiLabel.Size = UDim2.new(1, 0, 1, 0)
    qiLabel.Position = UDim2.new(0, 0, 0, 0)
    qiLabel.Text = "Qi: 100/100"
    qiLabel.Font = Enum.Font.SourceSans
    qiLabel.TextSize = 12
    qiLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    qiLabel.BackgroundTransparency = 1
    qiLabel.TextXAlignment = Enum.TextXAlignment.Left
    qiLabel.Parent = qiContainer
    
    resourceData.qi = {container = qiContainer, bar = qiBar, label = qiLabel}
    
    -- Mana bar
    local manaContainer, manaBar = ResourceBars.CreateProgressBar(
        container,
        UDim2.new(1, 0, 0, 18),
        UDim2.new(0, 0, 0, 40),
        Color3.fromRGB(74, 20, 140), -- Purple
        Color3.fromRGB(66, 66, 66)
    )
    
    local manaLabel = Instance.new("TextLabel")
    manaLabel.Size = UDim2.new(1, 0, 1, 0)
    manaLabel.Position = UDim2.new(0, 0, 0, 0)
    manaLabel.Text = "Mana: 100/100"
    manaLabel.Font = Enum.Font.SourceSans
    manaLabel.TextSize = 12
    manaLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    manaLabel.BackgroundTransparency = 1
    manaLabel.TextXAlignment = Enum.TextXAlignment.Left
    manaLabel.Parent = manaContainer
    
    resourceData.mana = {container = manaContainer, bar = manaBar, label = manaLabel}
    
    -- Stamina bar
    local staminaContainer, staminaBar = ResourceBars.CreateProgressBar(
        container,
        UDim2.new(1, 0, 0, 18),
        UDim2.new(0, 0, 0, 60),
        Color3.fromRGB(27, 94, 32), -- Green
        Color3.fromRGB(66, 66, 66)
    )
    
    local staminaLabel = Instance.new("TextLabel")
    staminaLabel.Size = UDim2.new(1, 0, 1, 0)
    staminaLabel.Position = UDim2.new(0, 0, 0, 0)
    staminaLabel.Text = "Stamina: 100/100"
    staminaLabel.Font = Enum.Font.SourceSans
    staminaLabel.TextSize = 12
    staminaLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    staminaLabel.BackgroundTransparency = 1
    staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
    staminaLabel.Parent = staminaContainer
    
    resourceData.stamina = {container = staminaContainer, bar = staminaBar, label = staminaLabel}
    
    return container, resourceData
end

-- Create a progress bar
function ResourceBars.CreateProgressBar(parent, size, position, barColor, backgroundColor)
    local container = Instance.new("Frame")
    container.Size = size
    container.Position = position
    container.BackgroundColor3 = backgroundColor
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container
    
    local bar = Instance.new("Frame")
    bar.Name = "ProgressBar"
    bar.Size = UDim2.new(1, 0, 1, 0) -- 100% by default
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.BackgroundColor3 = barColor
    bar.BorderSizePixel = 0
    bar.Parent = container
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = bar
    
    return container, bar
end

-- Update a resource bar with animation
function ResourceBars.UpdateResource(resourceData, current, max, resourceName)
    if not resourceData or not resourceData.bar or not resourceData.label then return end
    
    local percentage = math.clamp(current / max, 0, 1)
    local targetSize = UDim2.new(percentage, 0, 1, 0)
    
    -- Animate the bar
    local tween = TweenService:Create(
        resourceData.bar,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = targetSize}
    )
    tween:Play()
    
    -- Update the label
    resourceData.label.Text = resourceName .. ": " .. current .. "/" .. max
end

return ResourceBars

