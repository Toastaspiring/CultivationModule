--[[
    PlayerDataManager.lua
    Handles all player data operations including loading, saving, and data validation.
    This version uses a more generic data schema suitable for a template.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataManager = {}
PlayerDataManager.__index = PlayerDataManager

-- DataStore configuration
local DATASTORE_NAME = "CultivationGameTemplate_v1"
local BACKUP_DATASTORE_NAME = "CultivationGameTemplateBackup_v1"
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes

-- Data validation schema with comments for customization
local DATA_SCHEMA = {
    -- Core Player Info
    userId = "number",
    username = "string",
    createdAt = "number",
    lastLogin = "number",

    -- Progression Path Levels
    realm_path1 = "number", -- Corresponds to PROGRESSION_PATHS.PATH_1 (e.g., Cultivation Realm)
    realm_path2 = "number", -- Corresponds to PROGRESSION_PATHS.PATH_2 (e.g., Martial Realm)

    -- Talents and Traits
    talent_path1 = "string", -- Corresponds to TALENTS.PATH_1 (e.g., Spirit Root)
    talent_path2 = "number", -- Corresponds to a secondary talent (e.g., Heart Affinity)
    bloodline = "string", -- Player's bloodline, from GameConstants.BLOODLINES

    -- Player Resources
    experience = "number", -- General experience points
    resources = "table", -- Currencies and energy, see GameConstants.RESOURCES
    inventory = "table", -- Holds items like herbs, pills, etc.

    -- Social
    sectId = {"string", "nil"}, -- ID of the player's sect/faction
    sectRank = "number",
    friends = "table",

    -- Stats and Settings
    stats = "table",
    settings = "table"
}

function PlayerDataManager.new()
    local self = setmetatable({}, PlayerDataManager)
    self.mainDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
    self.backupDataStore = DataStoreService:GetDataStore(BACKUP_DATASTORE_NAME)
    self.playerDataCache = {}
    self:StartAutoSaveLoop()
    return self
end

function PlayerDataManager:LoadPlayerData(player)
    local userId = player.UserId
    local key = "Player_" .. userId
    
    if self.playerDataCache[userId] then return self.playerDataCache[userId] end
    
    local data
    pcall(function() data = self.mainDataStore:GetAsync(key) end)
    if not data then
        warn("Main DataStore failed, trying backup for:", player.Name)
        pcall(function() data = self.backupDataStore:GetAsync(key) end)
    end
    
    if data then
        data = self:ValidateAndMigrateData(data)
        self.playerDataCache[userId] = data
        data.lastLogin = tick()
        print("Data loaded successfully for:", player.Name)
        return data
    else
        print("No existing data found for:", player.Name, "Creating new profile.")
        return self:CreateNewPlayerData(player)
    end
end

function PlayerDataManager:SavePlayerData(player, data)
    local userId = player.UserId
    local key = "Player_" .. userId
    if not data then return false end
    
    self.playerDataCache[userId] = data
    
    local success, err = pcall(function() self.mainDataStore:SetAsync(key, data) end)
    if not success then warn("Main DataStore save failed:", err) end
    
    pcall(function() self.backupDataStore:SetAsync(key, data) end)
    
    return success
end

function PlayerDataManager:CreateNewPlayerData(player)
    local newData = {
        userId = player.UserId,
        username = player.Name,
        createdAt = tick(),
        lastLogin = tick(),
        
        realm_path1 = 0,
        realm_path2 = 0,

        talent_path1 = "Low", -- Default starting talent
        talent_path2 = math.random(1, 100),
        bloodline = "Human",

        experience = 0,
        resources = {
            PrimaryEnergy = 100,
            Currency = 100,
            SectCurrency = 0,
            SocialCurrency = 0
        },
        inventory = { Herbs = {}, Pills = {}, Equipment = {} },

        sectId = nil,
        sectRank = 0,
        friends = {},

        stats = { totalPlayTime = 0 },
        settings = { autoSave = true }
    }
    self.playerDataCache[player.UserId] = newData
    return newData
end

function PlayerDataManager:ValidateAndMigrateData(data)
    -- This function ensures that loaded data conforms to the latest schema.
    -- If you add a new field to the schema, add a check here to give it a default value.
    if not data.stats then data.stats = { totalPlayTime = 0 } end
    if not data.settings then data.settings = { autoSave = true } end
    if not data.resources then data.resources = { PrimaryEnergy = 100, Currency = 100 } end
    
    -- Example of migrating an old field name to a new one
    if data.cultivationRealm then
        data.realm_path1 = data.cultivationRealm
        data.cultivationRealm = nil -- remove old field
    end
    if data.martialRealm then
        data.realm_path2 = data.martialRealm
        data.martialRealm = nil
    end
    
    return data
end

function PlayerDataManager:StartAutoSaveLoop()
    spawn(function()
        while true do
            wait(AUTO_SAVE_INTERVAL)
            for userId, data in pairs(self.playerDataCache) do
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    self:SavePlayerData(player, data)
                else
                    self.playerDataCache[userId] = nil -- Player left, clear cache
                end
            end
        end
    end)
end

function PlayerDataManager:GetCachedData(player)
    return self.playerDataCache[player.UserId]
end

function PlayerDataManager:CleanupPlayer(player)
    local data = self:GetCachedData(player)
    if data then
        self:SavePlayerData(player, data)
        self.playerDataCache[player.UserId] = nil
        print("Cleaned up and saved data for player:", player.Name)
    end
end

return PlayerDataManager
