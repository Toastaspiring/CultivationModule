--[[
    PlayerDataManager.lua
    Handles all player data operations including loading, saving, and data validation
    Uses DataStoreService for persistence with proper error handling and retry logic
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDataManager = {}
PlayerDataManager.__index = PlayerDataManager

-- DataStore configuration
local DATASTORE_NAME = "CultivationGameData_v1"
local BACKUP_DATASTORE_NAME = "CultivationGameBackup_v1"
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes

-- Retry configuration
local MAX_RETRIES = 3
local RETRY_DELAY = 1

-- Data validation schemas
local DATA_SCHEMA = {
    userId = "number",
    username = "string",
    createdAt = "number",
    lastLogin = "number",
    spiritRoot = "string",
    bloodline = "string",
    heartAffinity = "number",
    cultivationRealm = "number",
    martialRealm = "number",
    experience = "number",
    resources = "table",
    inventory = "table",
    sectId = {"string", "nil"},
    sectRank = "number",
    friends = "table",
    enemies = "table",
    stats = "table",
    settings = "table"
}

function PlayerDataManager.new()
    local self = setmetatable({}, PlayerDataManager)
    
    -- Initialize DataStores
    self.mainDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
    self.backupDataStore = DataStoreService:GetDataStore(BACKUP_DATASTORE_NAME)
    
    -- Cache for loaded player data
    self.playerDataCache = {}
    
    -- Auto-save tracking
    self.lastAutoSave = {}
    
    -- Set up auto-save loop
    self:StartAutoSaveLoop()
    
    return self
end

function PlayerDataManager:LoadPlayerData(player)
    local userId = player.UserId
    local key = "Player_" .. userId
    
    print("Loading data for player:", player.Name)
    
    -- Check cache first
    if self.playerDataCache[userId] then
        print("Data loaded from cache for:", player.Name)
        return self.playerDataCache[userId]
    end
    
    -- Try to load from main DataStore
    local data = self:LoadFromDataStore(self.mainDataStore, key)
    
    -- If main DataStore fails, try backup
    if not data then
        print("Main DataStore failed, trying backup for:", player.Name)
        data = self:LoadFromDataStore(self.backupDataStore, key)
    end
    
    -- Validate and migrate data if necessary
    if data then
        data = self:ValidateAndMigrateData(data)
        self.playerDataCache[userId] = data
        
        -- Update last login time
        data.lastLogin = tick()
        
        print("Data loaded successfully for:", player.Name)
        return data
    else
        print("No existing data found for:", player.Name)
        return nil
    end
end

function PlayerDataManager:LoadFromDataStore(dataStore, key)
    for attempt = 1, MAX_RETRIES do
        local success, result = pcall(function()
            return dataStore:GetAsync(key)
        end)
        
        if success then
            return result
        else
            warn("DataStore load attempt", attempt, "failed:", result)
            if attempt < MAX_RETRIES then
                wait(RETRY_DELAY * attempt)
            end
        end
    end
    
    return nil
end

function PlayerDataManager:SavePlayerData(player, data)
    local userId = player.UserId
    local key = "Player_" .. userId
    
    if not data then
        warn("Attempted to save nil data for player:", player.Name)
        return false
    end
    
    -- Validate data before saving
    if not self:ValidateData(data) then
        warn("Data validation failed for player:", player.Name)
        return false
    end
    
    -- Update cache
    self.playerDataCache[userId] = data
    
    -- Save to both main and backup DataStores
    local mainSuccess = self:SaveToDataStore(self.mainDataStore, key, data)
    local backupSuccess = self:SaveToDataStore(self.backupDataStore, key, data)
    
    if mainSuccess or backupSuccess then
        self.lastAutoSave[userId] = tick()
        print("Data saved successfully for:", player.Name)
        return true
    else
        warn("Failed to save data for player:", player.Name)
        return false
    end
end

function PlayerDataManager:SaveToDataStore(dataStore, key, data)
    for attempt = 1, MAX_RETRIES do
        local success, result = pcall(function()
            dataStore:SetAsync(key, data)
        end)
        
        if success then
            return true
        else
            warn("DataStore save attempt", attempt, "failed:", result)
            if attempt < MAX_RETRIES then
                wait(RETRY_DELAY * attempt)
            end
        end
    end
    
    return false
end

function PlayerDataManager:ValidateData(data)
    if type(data) ~= "table" then
        return false
    end
    
    -- Check required fields
    for field, expectedType in pairs(DATA_SCHEMA) do
        local value = data[field]
        
        if type(expectedType) == "table" then
            -- Multiple allowed types
            local validType = false
            for _, allowedType in ipairs(expectedType) do
                if type(value) == allowedType then
                    validType = true
                    break
                end
            end
            if not validType then
                warn("Data validation failed: field", field, "has invalid type", type(value))
                return false
            end
        else
            -- Single expected type
            if type(value) ~= expectedType then
                warn("Data validation failed: field", field, "expected", expectedType, "got", type(value))
                return false
            end
        end
    end
    
    -- Additional validation rules
    if data.cultivationRealm < 0 or data.cultivationRealm > 20 then
        warn("Data validation failed: invalid cultivation realm", data.cultivationRealm)
        return false
    end
    
    if data.martialRealm < 0 or data.martialRealm > 20 then
        warn("Data validation failed: invalid martial realm", data.martialRealm)
        return false
    end
    
    if data.heartAffinity < 0 or data.heartAffinity > 100 then
        warn("Data validation failed: invalid heart affinity", data.heartAffinity)
        return false
    end
    
    return true
end

function PlayerDataManager:ValidateAndMigrateData(data)
    -- Data migration logic for version updates
    
    -- Ensure all required fields exist with default values
    if not data.stats then
        data.stats = {
            totalPlayTime = 0,
            breakthroughsAchieved = 0,
            combatWins = 0,
            combatLosses = 0,
            resourcesGathered = 0
        }
    end
    
    if not data.settings then
        data.settings = {
            autoSave = true,
            combatMode = "Manual",
            uiScale = 1.0,
            soundEnabled = true
        }
    end
    
    if not data.resources then
        data.resources = {
            qi = 100,
            spiritStones = 0,
            contributionPoints = 0,
            reputation = 0
        }
    end
    
    if not data.inventory then
        data.inventory = {
            herbs = {},
            pills = {},
            techniques = {},
            equipment = {},
            materials = {}
        }
    end
    
    -- Migrate old data formats if necessary
    if data.version and data.version < 1.0 then
        -- Migration logic for older versions
        data = self:MigrateFromVersion1(data)
    end
    
    -- Set current version
    data.version = 1.0
    
    return data
end

function PlayerDataManager:MigrateFromVersion1(data)
    -- Example migration logic
    print("Migrating data from version 1.0")
    
    -- Add any new fields or restructure data as needed
    if not data.bloodline then
        data.bloodline = "Human"
    end
    
    return data
end

function PlayerDataManager:StartAutoSaveLoop()
    spawn(function()
        while true do
            wait(AUTO_SAVE_INTERVAL)
            self:AutoSaveAllPlayers()
        end
    end)
end

function PlayerDataManager:AutoSaveAllPlayers()
    local currentTime = tick()
    
    for userId, data in pairs(self.playerDataCache) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            local lastSave = self.lastAutoSave[userId] or 0
            if currentTime - lastSave >= AUTO_SAVE_INTERVAL then
                self:SavePlayerData(player, data)
            end
        else
            -- Player has left, remove from cache
            self.playerDataCache[userId] = nil
            self.lastAutoSave[userId] = nil
        end
    end
end

function PlayerDataManager:GetCachedData(player)
    return self.playerDataCache[player.UserId]
end

function PlayerDataManager:UpdateCachedData(player, newData)
    self.playerDataCache[player.UserId] = newData
end

function PlayerDataManager:IncrementStat(player, statName, amount)
    local data = self:GetCachedData(player)
    if data and data.stats and data.stats[statName] then
        data.stats[statName] = data.stats[statName] + (amount or 1)
        return true
    end
    return false
end

function PlayerDataManager:AddResource(player, resourceType, amount)
    local data = self:GetCachedData(player)
    if data and data.resources and data.resources[resourceType] then
        data.resources[resourceType] = data.resources[resourceType] + amount
        return true
    end
    return false
end

function PlayerDataManager:RemoveResource(player, resourceType, amount)
    local data = self:GetCachedData(player)
    if data and data.resources and data.resources[resourceType] then
        if data.resources[resourceType] >= amount then
            data.resources[resourceType] = data.resources[resourceType] - amount
            return true
        end
    end
    return false
end

function PlayerDataManager:HasResource(player, resourceType, amount)
    local data = self:GetCachedData(player)
    if data and data.resources and data.resources[resourceType] then
        return data.resources[resourceType] >= amount
    end
    return false
end

function PlayerDataManager:AddToInventory(player, category, item)
    local data = self:GetCachedData(player)
    if data and data.inventory and data.inventory[category] then
        table.insert(data.inventory[category], item)
        return true
    end
    return false
end

function PlayerDataManager:RemoveFromInventory(player, category, itemId)
    local data = self:GetCachedData(player)
    if data and data.inventory and data.inventory[category] then
        for i, item in ipairs(data.inventory[category]) do
            if item.id == itemId then
                table.remove(data.inventory[category], i)
                return true
            end
        end
    end
    return false
end

function PlayerDataManager:GetInventoryCount(player, category, itemId)
    local data = self:GetCachedData(player)
    if data and data.inventory and data.inventory[category] then
        local count = 0
        for _, item in ipairs(data.inventory[category]) do
            if item.id == itemId then
                count = count + (item.quantity or 1)
            end
        end
        return count
    end
    return 0
end

function PlayerDataManager:CleanupPlayer(player)
    local userId = player.UserId
    
    -- Final save before cleanup
    local data = self.playerDataCache[userId]
    if data then
        self:SavePlayerData(player, data)
    end
    
    -- Remove from cache
    self.playerDataCache[userId] = nil
    self.lastAutoSave[userId] = nil
    
    print("Cleaned up data for player:", player.Name)
end

function PlayerDataManager:GetLeaderboardData(category, limit)
    -- This would require a separate OrderedDataStore for leaderboards
    -- Implementation depends on specific leaderboard requirements
    
    local leaderboardStore = DataStoreService:GetOrderedDataStore("Leaderboard_" .. category)
    
    local success, result = pcall(function()
        return leaderboardStore:GetSortedAsync(false, limit or 10)
    end)
    
    if success then
        local leaderboard = {}
        for rank, entry in ipairs(result:GetCurrentPage()) do
            table.insert(leaderboard, {
                rank = rank,
                userId = entry.key,
                value = entry.value
            })
        end
        return leaderboard
    else
        warn("Failed to get leaderboard data:", result)
        return {}
    end
end

function PlayerDataManager:UpdateLeaderboard(player, category, value)
    local leaderboardStore = DataStoreService:GetOrderedDataStore("Leaderboard_" .. category)
    
    local success, result = pcall(function()
        leaderboardStore:SetAsync(tostring(player.UserId), value)
    end)
    
    if not success then
        warn("Failed to update leaderboard:", result)
    end
end

return PlayerDataManager

