--[[
    PlayerInfoPanel.lua (ModuleScript)
    Creates and manages the player information panel UI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerInfoPanel = {}

-- Create the player info panel
function PlayerInfoPanel.Create(parent)
    local panel = Instance.new("Frame")
    panel.Name = "PlayerInfoPanel"
    panel.Size = UDim2.new(0, 300, 0, 150)
    panel.Position = UDim2.new(0, 20, 0, 20)
    panel.BackgroundColor3 = Color3.fromRGB(26, 35, 126)
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
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
    
    -- Player name and level
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -20, 0, 25)
    nameLabel.Position = UDim2.new(0, 10, 0, 10)
    nameLabel.Text = "◉ " .. Players.LocalPlayer.Name .. "                          Lv. 1"
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = panel
    
    -- Separator line
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -20, 0, 2)
    separator.Position = UDim2.new(0, 10, 0, 40)
    separator.BackgroundColor3 = Color3.fromRGB(255, 143, 0)
    separator.BorderSizePixel = 0
    separator.Parent = panel
    
    -- Cultivation realm
    local cultivationLabel = Instance.new("TextLabel")
    cultivationLabel.Name = "CultivationLabel"
    cultivationLabel.Size = UDim2.new(1, -20, 0, 20)
    cultivationLabel.Position = UDim2.new(0, 10, 0, 50)
    cultivationLabel.Text = "🏔️ Cultivation: Qi Refining (Stage 1)"
    cultivationLabel.Font = Enum.Font.SourceSans
    cultivationLabel.TextSize = 14
    cultivationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cultivationLabel.BackgroundTransparency = 1
    cultivationLabel.TextXAlignment = Enum.TextXAlignment.Left
    cultivationLabel.Parent = panel
    
    -- Martial arts realm
    local martialLabel = Instance.new("TextLabel")
    martialLabel.Name = "MartialLabel"
    martialLabel.Size = UDim2.new(1, -20, 0, 20)
    martialLabel.Position = UDim2.new(0, 10, 0, 70)
    martialLabel.Text = "👊 Martial Arts: Third Rate (Stage 1)"
    martialLabel.Font = Enum.Font.SourceSans
    martialLabel.TextSize = 14
    martialLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    martialLabel.BackgroundTransparency = 1
    martialLabel.TextXAlignment = Enum.TextXAlignment.Left
    martialLabel.Parent = panel
    
    -- Spirit stones
    local stonesLabel = Instance.new("TextLabel")
    stonesLabel.Name = "StonesLabel"
    stonesLabel.Size = UDim2.new(1, -20, 0, 20)
    stonesLabel.Position = UDim2.new(0, 10, 0, 90)
    stonesLabel.Text = "💎 Spirit Stones: 100"
    stonesLabel.Font = Enum.Font.SourceSans
    stonesLabel.TextSize = 14
    stonesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    stonesLabel.BackgroundTransparency = 1
    stonesLabel.TextXAlignment = Enum.TextXAlignment.Left
    stonesLabel.Parent = panel
    
    -- Reputation
    local repLabel = Instance.new("TextLabel")
    repLabel.Name = "RepLabel"
    repLabel.Size = UDim2.new(1, -20, 0, 20)
    repLabel.Position = UDim2.new(0, 10, 0, 110)
    repLabel.Text = "⭐ Reputation: 0"
    repLabel.Font = Enum.Font.SourceSans
    repLabel.TextSize = 14
    repLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    repLabel.BackgroundTransparency = 1
    repLabel.TextXAlignment = Enum.TextXAlignment.Left
    repLabel.Parent = panel
    
    -- Bloodline
    local bloodlineLabel = Instance.new("TextLabel")
    bloodlineLabel.Name = "BloodlineLabel"
    bloodlineLabel.Size = UDim2.new(1, -20, 0, 20)
    bloodlineLabel.Position = UDim2.new(0, 10, 0, 130)
    bloodlineLabel.Text = "🩸 Bloodline: None"
    bloodlineLabel.Font = Enum.Font.SourceSans
    bloodlineLabel.TextSize = 14
    bloodlineLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    bloodlineLabel.BackgroundTransparency = 1
    bloodlineLabel.TextXAlignment = Enum.TextXAlignment.Left
    bloodlineLabel.Parent = panel
    
    return panel
end

-- Update player data in the panel
function PlayerInfoPanel.UpdateData(panel, playerData)
    if not panel or not playerData then return end
    
    -- Update name and level
    local nameLabel = panel:FindFirstChild("NameLabel")
    if nameLabel and playerData.name and playerData.level then
        nameLabel.Text = "◉ " .. playerData.name .. "                          Lv. " .. playerData.level
    end
    
    -- Update cultivation realm
    local cultivationLabel = panel:FindFirstChild("CultivationLabel")
    if cultivationLabel and playerData.cultivation then
        cultivationLabel.Text = "🏔️ Cultivation: " .. playerData.cultivation.realm .. " (Stage " .. playerData.cultivation.stage .. ")"
    end
    
    -- Update martial arts realm
    local martialLabel = panel:FindFirstChild("MartialLabel")
    if martialLabel and playerData.martialArts then
        martialLabel.Text = "👊 Martial Arts: " .. playerData.martialArts.realm .. " (Stage " .. playerData.martialArts.stage .. ")"
    end
    
    -- Update spirit stones
    local stonesLabel = panel:FindFirstChild("StonesLabel")
    if stonesLabel and playerData.spiritStones then
        stonesLabel.Text = "💎 Spirit Stones: " .. playerData.spiritStones
    end
    
    -- Update reputation
    local repLabel = panel:FindFirstChild("RepLabel")
    if repLabel and playerData.reputation then
        repLabel.Text = "⭐ Reputation: " .. playerData.reputation
    end
    
    -- Update bloodline
    local bloodlineLabel = panel:FindFirstChild("BloodlineLabel")
    if bloodlineLabel and playerData.bloodline then
        bloodlineLabel.Text = "🩸 Bloodline: " .. (playerData.bloodline.name or "None")
    end
end

return PlayerInfoPanel

