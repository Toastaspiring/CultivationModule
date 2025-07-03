--[[
    ResourceManager.lua
    Handles resource gathering, crafting, trading, auction house, and economy
    Manages resource nodes, herb gardens, mining, and material processing
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Import shared modules
local GameConstants = require(ReplicatedStorage.Shared.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local ResourceManager = {}
ResourceManager.__index = ResourceManager

-- Resource nodes and gathering spots
local resourceNodes = {}
local herbGardens = {}
local miningNodes = {}

-- Crafting stations
local craftingStations = {}

-- Trading and auction house
local marketDataStore = DataStoreService:GetDataStore("MarketData_v1")
local activeListings = {}
local tradeRequests = {}

-- Resource regeneration timers
local regenerationTimers = {}

function ResourceManager.new()
    local self = setmetatable({}, ResourceManager)
    
    -- Set up remote event handlers
    self:SetupRemoteEvents()
    
    -- Load market data
    self:LoadMarketData()
    
    return self
end

function ResourceManager:InitializePlayer(player, playerData)
    print("Initializing resource system for player:", player.Name)
    
    -- Set up player's resource data if not exists
    if not playerData.resources then
        playerData.resources = {
            qi = 100,
            spiritStones = GameConstants.ECONOMY.STARTING_SPIRIT_STONES,
            contributionPoints = 0,
            reputation = 0
        }
    end
    
    if not playerData.inventory then
        playerData.inventory = {
            herbs = {},
            pills = {},
            techniques = {},
            equipment = {},
            materials = {}
        }
    end
    
    if not playerData.crafting then
        playerData.crafting = {
            alchemy = 0,
            forging = 0,
            formation = 0,
            tailoring = 0,
            cooking = 0,
            experience = {
                alchemy = 0,
                forging = 0,
                formation = 0,
                tailoring = 0,
                cooking = 0
            }
        }
    end
    
    -- Send initial resource data to client
    RemoteEvents.FireClient("ResourceUpdate", player, playerData.resources)
end

function ResourceManager:CleanupPlayer(player)
    local userId = player.UserId
    
    -- Cancel any active trade requests
    for tradeId, trade in pairs(tradeRequests) do
        if trade.initiator == player or trade.target == player then
            self:CancelTrade(tradeId)
        end
    end
    
    print("Cleaned up resource system for player:", player.Name)
end

function ResourceManager:SetupRemoteEvents()
    -- Gather resources
    RemoteEvents.ConnectEvent("GatherResource", function(player, nodeId, gatherType)
        self:GatherResource(player, nodeId, gatherType)
    end)
    
    -- Craft item
    RemoteEvents.ConnectEvent("CraftItem", function(player, recipeId, quantity, stationId)
        self:CraftItem(player, recipeId, quantity, stationId)
    end)
    
    -- Use item
    RemoteEvents.ConnectEvent("UseItem", function(player, itemId, quantity)
        self:UseItem(player, itemId, quantity)
    end)
    
    -- Trade request
    RemoteEvents.ConnectEvent("TradeRequest", function(player, targetPlayer, offer, request)
        self:InitiateTrade(player, targetPlayer, offer, request)
    end)
    
    -- Trade response
    RemoteEvents.ConnectEvent("TradeResponse", function(player, tradeId, accept)
        self:RespondToTrade(player, tradeId, accept)
    end)
    
    -- Market listing
    RemoteEvents.ConnectEvent("CreateMarketListing", function(player, itemId, quantity, price, duration)
        self:CreateMarketListing(player, itemId, quantity, price, duration)
    end)
    
    -- Purchase from market
    RemoteEvents.ConnectEvent("PurchaseFromMarket", function(player, listingId)
        self:PurchaseFromMarket(player, listingId)
    end)
    
    -- Get market data
    RemoteEvents.ConnectFunction("GetMarketData", function(player, category, searchTerm)
        return self:GetMarketData(category, searchTerm)
    end)
    
    -- Plant herb
    RemoteEvents.ConnectEvent("PlantHerb", function(player, herbType, location)
        self:PlantHerb(player, herbType, location)
    end)
    
    -- Harvest herb
    RemoteEvents.ConnectEvent("HarvestHerb", function(player, gardenId)
        self:HarvestHerb(player, gardenId)
    end)
end

function ResourceManager:InitializeResourceNodes()
    -- Create various resource nodes throughout the world
    local nodeTypes = {
        {type = "SpiritGrass", position = Vector3.new(100, 0, 100), rarity = "Common", respawnTime = 300},
        {type = "BloodLotus", position = Vector3.new(200, 0, 200), rarity = "Rare", respawnTime = 1800},
        {type = "DragonScale", position = Vector3.new(300, 0, 300), rarity = "Legendary", respawnTime = 7200},
        {type = "IronOre", position = Vector3.new(-100, 0, 100), rarity = "Common", respawnTime = 600},
        {type = "SpiritCrystal", position = Vector3.new(-200, 0, 200), rarity = "Rare", respawnTime = 3600},
        {type = "StarIron", position = Vector3.new(-300, 0, 300), rarity = "Legendary", respawnTime = 14400}
    }
    
    for i, nodeData in ipairs(nodeTypes) do
        local nodeId = "node_" .. i
        resourceNodes[nodeId] = {
            id = nodeId,
            type = nodeData.type,
            position = nodeData.position,
            rarity = nodeData.rarity,
            respawnTime = nodeData.respawnTime,
            lastHarvested = {},
            available = true,
            quantity = self:GetNodeQuantity(nodeData.rarity),
            maxQuantity = self:GetNodeQuantity(nodeData.rarity)
        }
    end
    
    -- Create mining nodes
    local miningTypes = {
        {type = "SpiritStone", position = Vector3.new(500, 0, 0), rarity = "Common", respawnTime = 900},
        {type = "JadeEssence", position = Vector3.new(600, 0, 0), rarity = "Rare", respawnTime = 2700},
        {type = "CelestialCrystal", position = Vector3.new(700, 0, 0), rarity = "Legendary", respawnTime = 10800}
    }
    
    for i, miningData in ipairs(miningTypes) do
        local nodeId = "mining_" .. i
        miningNodes[nodeId] = {
            id = nodeId,
            type = miningData.type,
            position = miningData.position,
            rarity = miningData.rarity,
            respawnTime = miningData.respawnTime,
            lastMined = {},
            available = true,
            hardness = self:GetMiningHardness(miningData.rarity),
            quantity = self:GetNodeQuantity(miningData.rarity)
        }
    end
    
    -- Create crafting stations
    local stationTypes = {
        {type = "AlchemyFurnace", position = Vector3.new(0, 0, 500), level = 1},
        {type = "ForgingAnvil", position = Vector3.new(100, 0, 500), level = 1},
        {type = "FormationTable", position = Vector3.new(200, 0, 500), level = 1},
        {type = "TailoringLoom", position = Vector3.new(300, 0, 500), level = 1}
    }
    
    for i, stationData in ipairs(stationTypes) do
        local stationId = "station_" .. i
        craftingStations[stationId] = {
            id = stationId,
            type = stationData.type,
            position = stationData.position,
            level = stationData.level,
            inUse = false,
            currentUser = nil,
            queue = {}
        }
    end
    
    print("Initialized", #nodeTypes + #miningTypes, "resource nodes and", #stationTypes, "crafting stations")
end

function ResourceManager:GatherResource(player, nodeId, gatherType)
    local node = resourceNodes[nodeId] or miningNodes[nodeId]
    if not node or not node.available then
        RemoteEvents.FireClient("SystemMessage", player, "Resource node not available!")
        return
    end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    local userId = player.UserId
    local currentTime = tick()
    
    -- Check cooldown
    if node.lastHarvested[userId] and currentTime - node.lastHarvested[userId] < node.respawnTime then
        local remaining = node.respawnTime - (currentTime - node.lastHarvested[userId])
        RemoteEvents.FireClient("SystemMessage", player, "Node cooldown: " .. math.floor(remaining / 60) .. " minutes remaining")
        return
    end
    
    -- Check if node has resources
    if node.quantity <= 0 then
        RemoteEvents.FireClient("SystemMessage", player, "Resource node is depleted!")
        return
    end
    
    -- Calculate gathering success and amount
    local gatheringSkill = self:GetGatheringSkill(playerData, gatherType)
    local successChance = math.min(0.95, 0.5 + (gatheringSkill * 0.01))
    
    if math.random() > successChance then
        RemoteEvents.FireClient("SystemMessage", player, "Gathering failed!")
        return
    end
    
    -- Calculate gathered amount
    local baseAmount = 1
    local bonusAmount = math.floor(gatheringSkill / 20)
    local totalAmount = math.min(baseAmount + bonusAmount, node.quantity)
    
    -- Apply realm bonuses
    local realmBonus = 1 + (math.max(playerData.cultivationRealm, playerData.martialRealm) * 0.1)
    totalAmount = math.floor(totalAmount * realmBonus)
    
    -- Create gathered item
    local gatheredItem = {
        id = node.type,
        name = node.type,
        quantity = totalAmount,
        quality = self:DetermineQuality(node.rarity, gatheringSkill),
        gatheredAt = currentTime,
        gatheredBy = player.Name
    }
    
    -- Add to player inventory
    local category = self:GetItemCategory(node.type)
    if not playerData.inventory[category] then
        playerData.inventory[category] = {}
    end
    
    -- Check if item already exists in inventory
    local existingItem = nil
    for _, item in ipairs(playerData.inventory[category]) do
        if item.id == gatheredItem.id and item.quality == gatheredItem.quality then
            existingItem = item
            break
        end
    end
    
    if existingItem then
        existingItem.quantity = existingItem.quantity + gatheredItem.quantity
    else
        table.insert(playerData.inventory[category], gatheredItem)
    end
    
    -- Update node
    node.quantity = node.quantity - totalAmount
    node.lastHarvested[userId] = currentTime
    
    if node.quantity <= 0 then
        node.available = false
        -- Schedule respawn
        spawn(function()
            wait(node.respawnTime)
            node.quantity = node.maxQuantity
            node.available = true
            node.lastHarvested = {}
        end)
    end
    
    -- Update player statistics
    playerData.stats.resourcesGathered = playerData.stats.resourcesGathered + totalAmount
    
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "gathered", totalAmount, node.type, "quality:", gatheredItem.quality)
    
    RemoteEvents.FireClient("ResourceUpdate", player, {
        type = "gather",
        item = gatheredItem,
        nodeId = nodeId,
        remaining = node.quantity
    })
end

function ResourceManager:CraftItem(player, recipeId, quantity, stationId)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Get recipe
    local recipe = self:GetRecipe(recipeId)
    if not recipe then
        RemoteEvents.FireClient("SystemMessage", player, "Invalid recipe!")
        return
    end
    
    -- Check crafting station
    local station = craftingStations[stationId]
    if not station or station.type ~= recipe.stationType then
        RemoteEvents.FireClient("SystemMessage", player, "Invalid crafting station!")
        return
    end
    
    if station.inUse then
        RemoteEvents.FireClient("SystemMessage", player, "Crafting station is in use!")
        return
    end
    
    -- Check skill requirements
    local requiredSkill = recipe.skillType
    local playerSkill = playerData.crafting[requiredSkill] or 0
    
    if playerSkill < recipe.skillLevel then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient " .. requiredSkill .. " skill!")
        return
    end
    
    -- Check ingredients
    for _, ingredient in ipairs(recipe.ingredients) do
        local hasEnough = self:HasItem(playerData, ingredient.id, ingredient.quantity * quantity)
        if not hasEnough then
            RemoteEvents.FireClient("SystemMessage", player, "Insufficient " .. ingredient.id .. "!")
            return
        end
    end
    
    -- Reserve crafting station
    station.inUse = true
    station.currentUser = player
    
    -- Start crafting process
    local craftingTime = recipe.craftingTime * quantity
    
    RemoteEvents.FireClient("CraftingStarted", player, {
        recipeId = recipeId,
        quantity = quantity,
        duration = craftingTime,
        stationId = stationId
    })
    
    spawn(function()
        wait(craftingTime)
        
        -- Complete crafting
        self:CompleteCrafting(player, recipe, quantity, station)
    end)
end

function ResourceManager:CompleteCrafting(player, recipe, quantity, station)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        station.inUse = false
        station.currentUser = nil
        return
    end
    
    -- Calculate success chance
    local playerSkill = playerData.crafting[recipe.skillType] or 0
    local successChance = math.min(0.95, 0.3 + (playerSkill * 0.01))
    
    local successfulCrafts = 0
    local skillGained = 0
    
    for i = 1, quantity do
        if math.random() < successChance then
            successfulCrafts = successfulCrafts + 1
            
            -- Consume ingredients
            for _, ingredient in ipairs(recipe.ingredients) do
                self:RemoveItem(playerData, ingredient.id, ingredient.quantity)
            end
            
            -- Create crafted item
            local craftedItem = {
                id = recipe.resultId,
                name = recipe.resultName,
                quantity = recipe.resultQuantity,
                quality = self:DetermineCraftingQuality(playerSkill, recipe.difficulty),
                craftedAt = tick(),
                craftedBy = player.Name
            }
            
            -- Add to inventory
            local category = self:GetItemCategory(recipe.resultId)
            if not playerData.inventory[category] then
                playerData.inventory[category] = {}
            end
            
            table.insert(playerData.inventory[category], craftedItem)
            
            -- Gain skill experience
            local expGain = recipe.expGain
            playerData.crafting.experience[recipe.skillType] = playerData.crafting.experience[recipe.skillType] + expGain
            skillGained = skillGained + expGain
            
            -- Check for skill level up
            local newSkillLevel = math.floor(playerData.crafting.experience[recipe.skillType] / 1000)
            if newSkillLevel > playerData.crafting[recipe.skillType] then
                playerData.crafting[recipe.skillType] = newSkillLevel
                RemoteEvents.FireClient("SystemMessage", player, recipe.skillType .. " skill increased to " .. newSkillLevel .. "!")
            end
        end
    end
    
    -- Release crafting station
    station.inUse = false
    station.currentUser = nil
    
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "crafted", successfulCrafts, "out of", quantity, recipe.resultName)
    
    RemoteEvents.FireClient("CraftingCompleted", player, {
        recipeId = recipe.id,
        successfulCrafts = successfulCrafts,
        totalAttempts = quantity,
        skillGained = skillGained
    })
end

function ResourceManager:UseItem(player, itemId, quantity)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Find item in inventory
    local item = self:FindItem(playerData, itemId)
    if not item or item.quantity < quantity then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient " .. itemId .. "!")
        return
    end
    
    -- Get item effects
    local itemData = self:GetItemData(itemId)
    if not itemData or not itemData.effects then
        RemoteEvents.FireClient("SystemMessage", player, "Item cannot be used!")
        return
    end
    
    -- Apply item effects
    for effect, value in pairs(itemData.effects) do
        if effect == "qi" then
            playerData.cultivation.currentQi = math.min(
                playerData.cultivation.currentQi + (value * quantity),
                playerData.cultivation.maxQi
            )
        elseif effect == "health" then
            playerData.combat.currentHealth = math.min(
                playerData.combat.currentHealth + (value * quantity),
                playerData.combat.maxHealth
            )
        elseif effect == "mana" then
            playerData.combat.currentMana = math.min(
                playerData.combat.currentMana + (value * quantity),
                playerData.combat.maxMana
            )
        elseif effect == "breakthrough" then
            -- Temporary breakthrough chance bonus
            if not playerData.cultivation.tempBonuses then
                playerData.cultivation.tempBonuses = {}
            end
            playerData.cultivation.tempBonuses.breakthroughChance = (playerData.cultivation.tempBonuses.breakthroughChance or 0) + value
        end
    end
    
    -- Remove item from inventory
    self:RemoveItem(playerData, itemId, quantity)
    
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "used", quantity, itemId)
    
    RemoteEvents.FireClient("ItemUsed", player, {
        itemId = itemId,
        quantity = quantity,
        effects = itemData.effects
    })
end

function ResourceManager:InitiateTrade(player, targetPlayer, offer, request)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    local targetData = gameManager:GetPlayerData(targetPlayer)
    
    if not playerData or not targetData then
        return
    end
    
    -- Validate offer
    for _, item in ipairs(offer) do
        if not self:HasItem(playerData, item.id, item.quantity) then
            RemoteEvents.FireClient("SystemMessage", player, "You don't have enough " .. item.id .. "!")
            return
        end
    end
    
    -- Create trade request
    local tradeId = "trade_" .. player.UserId .. "_" .. targetPlayer.UserId .. "_" .. tick()
    local trade = {
        id = tradeId,
        initiator = player,
        target = targetPlayer,
        offer = offer,
        request = request,
        timestamp = tick(),
        timeout = 300, -- 5 minutes
        status = "pending"
    }
    
    tradeRequests[tradeId] = trade
    
    print("Trade request initiated:", player.Name, "to", targetPlayer.Name)
    
    -- Send trade request to target
    RemoteEvents.FireClient("TradeRequest", targetPlayer, {
        tradeId = tradeId,
        initiatorName = player.Name,
        offer = offer,
        request = request,
        timeout = trade.timeout
    })
    
    RemoteEvents.FireClient("SystemMessage", player, "Trade request sent to " .. targetPlayer.Name)
    
    -- Auto-expire trade
    spawn(function()
        wait(trade.timeout)
        if tradeRequests[tradeId] and tradeRequests[tradeId].status == "pending" then
            self:CancelTrade(tradeId)
        end
    end)
end

function ResourceManager:RespondToTrade(player, tradeId, accept)
    local trade = tradeRequests[tradeId]
    if not trade or trade.target ~= player or trade.status ~= "pending" then
        RemoteEvents.FireClient("SystemMessage", player, "Invalid trade request!")
        return
    end
    
    if accept then
        self:ExecuteTrade(trade)
    else
        self:CancelTrade(tradeId)
        RemoteEvents.FireClient("SystemMessage", trade.initiator, player.Name .. " declined the trade")
    end
end

function ResourceManager:ExecuteTrade(trade)
    local gameManager = require(script.Parent.GameManager)
    local initiatorData = gameManager:GetPlayerData(trade.initiator)
    local targetData = gameManager:GetPlayerData(trade.target)
    
    if not initiatorData or not targetData then
        self:CancelTrade(trade.id)
        return
    end
    
    -- Verify both players still have the required items
    for _, item in ipairs(trade.offer) do
        if not self:HasItem(initiatorData, item.id, item.quantity) then
            RemoteEvents.FireClient("SystemMessage", trade.initiator, "Trade failed: insufficient " .. item.id)
            RemoteEvents.FireClient("SystemMessage", trade.target, "Trade failed: " .. trade.initiator.Name .. " doesn't have enough " .. item.id)
            self:CancelTrade(trade.id)
            return
        end
    end
    
    for _, item in ipairs(trade.request) do
        if not self:HasItem(targetData, item.id, item.quantity) then
            RemoteEvents.FireClient("SystemMessage", trade.target, "Trade failed: insufficient " .. item.id)
            RemoteEvents.FireClient("SystemMessage", trade.initiator, "Trade failed: " .. trade.target.Name .. " doesn't have enough " .. item.id)
            self:CancelTrade(trade.id)
            return
        end
    end
    
    -- Execute the trade
    -- Remove items from initiator, add to target
    for _, item in ipairs(trade.offer) do
        self:RemoveItem(initiatorData, item.id, item.quantity)
        self:AddItem(targetData, item.id, item.quantity)
    end
    
    -- Remove items from target, add to initiator
    for _, item in ipairs(trade.request) do
        self:RemoveItem(targetData, item.id, item.quantity)
        self:AddItem(initiatorData, item.id, item.quantity)
    end
    
    -- Update player data
    gameManager:UpdatePlayerData(trade.initiator, initiatorData)
    gameManager:UpdatePlayerData(trade.target, targetData)
    
    -- Clean up trade
    tradeRequests[trade.id] = nil
    
    print("Trade completed:", trade.initiator.Name, "with", trade.target.Name)
    
    -- Notify both players
    RemoteEvents.FireClient("TradeCompleted", trade.initiator, {
        partner = trade.target.Name,
        given = trade.offer,
        received = trade.request
    })
    
    RemoteEvents.FireClient("TradeCompleted", trade.target, {
        partner = trade.initiator.Name,
        given = trade.request,
        received = trade.offer
    })
end

function ResourceManager:CancelTrade(tradeId)
    local trade = tradeRequests[tradeId]
    if trade then
        tradeRequests[tradeId] = nil
        
        if trade.initiator and trade.initiator.Parent then
            RemoteEvents.FireClient("SystemMessage", trade.initiator, "Trade cancelled")
        end
        
        if trade.target and trade.target.Parent then
            RemoteEvents.FireClient("SystemMessage", trade.target, "Trade cancelled")
        end
    end
end

function ResourceManager:CreateMarketListing(player, itemId, quantity, price, duration)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Check if player has the item
    if not self:HasItem(playerData, itemId, quantity) then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient " .. itemId .. "!")
        return
    end
    
    -- Check minimum price
    if price < 1 then
        RemoteEvents.FireClient("SystemMessage", player, "Price must be at least 1 spirit stone!")
        return
    end
    
    -- Calculate listing fee
    local listingFee = math.floor(price * GameConstants.ECONOMY.AUCTION_HOUSE_FEE)
    if playerData.resources.spiritStones < listingFee then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient spirit stones for listing fee!")
        return
    end
    
    -- Remove item from inventory and listing fee
    self:RemoveItem(playerData, itemId, quantity)
    playerData.resources.spiritStones = playerData.resources.spiritStones - listingFee
    
    -- Create market listing
    local listingId = "listing_" .. player.UserId .. "_" .. tick()
    local listing = {
        id = listingId,
        sellerId = player.UserId,
        sellerName = player.Name,
        itemId = itemId,
        quantity = quantity,
        price = price,
        listingFee = listingFee,
        createdAt = tick(),
        expiresAt = tick() + duration,
        status = "active"
    }
    
    activeListings[listingId] = listing
    
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Market listing created:", player.Name, "selling", quantity, itemId, "for", price, "spirit stones")
    
    RemoteEvents.FireClient("SystemMessage", player, "Item listed on market!")
    
    -- Save to datastore
    self:SaveMarketListing(listing)
    
    -- Schedule expiration
    spawn(function()
        wait(duration)
        if activeListings[listingId] and activeListings[listingId].status == "active" then
            self:ExpireMarketListing(listingId)
        end
    end)
end

function ResourceManager:PurchaseFromMarket(player, listingId)
    local listing = activeListings[listingId]
    if not listing or listing.status ~= "active" then
        RemoteEvents.FireClient("SystemMessage", player, "Listing not available!")
        return
    end
    
    local gameManager = require(script.Parent.GameManager)
    local buyerData = gameManager:GetPlayerData(player)
    
    if not buyerData then
        return
    end
    
    -- Check if buyer has enough spirit stones
    if buyerData.resources.spiritStones < listing.price then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient spirit stones!")
        return
    end
    
    -- Check if buyer is not the seller
    if player.UserId == listing.sellerId then
        RemoteEvents.FireClient("SystemMessage", player, "Cannot buy your own listing!")
        return
    end
    
    -- Execute purchase
    buyerData.resources.spiritStones = buyerData.resources.spiritStones - listing.price
    self:AddItem(buyerData, listing.itemId, listing.quantity)
    
    -- Pay seller
    local seller = game.Players:GetPlayerByUserId(listing.sellerId)
    if seller then
        local sellerData = gameManager:GetPlayerData(seller)
        if sellerData then
            sellerData.resources.spiritStones = sellerData.resources.spiritStones + listing.price
            gameManager:UpdatePlayerData(seller, sellerData)
            RemoteEvents.FireClient("SystemMessage", seller, "Your " .. listing.itemId .. " sold for " .. listing.price .. " spirit stones!")
        end
    end
    
    -- Update listing status
    listing.status = "sold"
    listing.buyerId = player.UserId
    listing.buyerName = player.Name
    listing.soldAt = tick()
    
    gameManager:UpdatePlayerData(player, buyerData)
    
    print("Market purchase:", player.Name, "bought", listing.quantity, listing.itemId, "for", listing.price, "spirit stones")
    
    RemoteEvents.FireClient("SystemMessage", player, "Purchase successful!")
    
    -- Remove from active listings
    activeListings[listingId] = nil
    
    -- Update datastore
    self:SaveMarketListing(listing)
end

function ResourceManager:GetMarketData(category, searchTerm)
    local results = {}
    
    for listingId, listing in pairs(activeListings) do
        if listing.status == "active" then
            local itemData = self:GetItemData(listing.itemId)
            if itemData then
                local matchesCategory = not category or itemData.category == category
                local matchesSearch = not searchTerm or string.find(string.lower(listing.itemId), string.lower(searchTerm))
                
                if matchesCategory and matchesSearch then
                    table.insert(results, {
                        id = listing.id,
                        itemId = listing.itemId,
                        itemName = itemData.name or listing.itemId,
                        quantity = listing.quantity,
                        price = listing.price,
                        sellerName = listing.sellerName,
                        timeRemaining = listing.expiresAt - tick()
                    })
                end
            end
        end
    end
    
    -- Sort by price (ascending)
    table.sort(results, function(a, b)
        return a.price < b.price
    end)
    
    return results
end

function ResourceManager:PlantHerb(player, herbType, location)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Check if player has herb seeds
    local seedId = herbType .. "Seed"
    if not self:HasItem(playerData, seedId, 1) then
        RemoteEvents.FireClient("SystemMessage", player, "You don't have " .. seedId .. "!")
        return
    end
    
    -- Check if location is suitable for planting
    if not self:IsValidPlantingLocation(location) then
        RemoteEvents.FireClient("SystemMessage", player, "Invalid planting location!")
        return
    end
    
    -- Remove seed from inventory
    self:RemoveItem(playerData, seedId, 1)
    
    -- Create herb garden
    local gardenId = "garden_" .. player.UserId .. "_" .. tick()
    local herbInfo = GameConstants.HERBS[herbType]
    
    herbGardens[gardenId] = {
        id = gardenId,
        ownerId = player.UserId,
        ownerName = player.Name,
        herbType = herbType,
        location = location,
        plantedAt = tick(),
        growthTime = herbInfo.growthTime,
        ready = false,
        quality = "Normal"
    }
    
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Herb planted:", player.Name, "planted", herbType, "at", location.x, location.y, location.z)
    
    RemoteEvents.FireClient("SystemMessage", player, herbType .. " planted successfully!")
    
    -- Schedule growth completion
    spawn(function()
        wait(herbInfo.growthTime)
        if herbGardens[gardenId] then
            herbGardens[gardenId].ready = true
            if game.Players:GetPlayerByUserId(herbGardens[gardenId].ownerId) then
                RemoteEvents.FireClient("SystemMessage", game.Players:GetPlayerByUserId(herbGardens[gardenId].ownerId), herbType .. " is ready for harvest!")
            end
        end
    end)
end

function ResourceManager:HarvestHerb(player, gardenId)
    local garden = herbGardens[gardenId]
    if not garden then
        RemoteEvents.FireClient("SystemMessage", player, "Garden not found!")
        return
    end
    
    if garden.ownerId ~= player.UserId then
        RemoteEvents.FireClient("SystemMessage", player, "This is not your garden!")
        return
    end
    
    if not garden.ready then
        local remaining = garden.growthTime - (tick() - garden.plantedAt)
        RemoteEvents.FireClient("SystemMessage", player, "Herb not ready! " .. math.floor(remaining / 60) .. " minutes remaining")
        return
    end
    
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Calculate harvest yield
    local herbInfo = GameConstants.HERBS[garden.herbType]
    local baseYield = 1
    local bonusYield = math.random(0, 2) -- 0-2 bonus herbs
    local totalYield = baseYield + bonusYield
    
    -- Add herbs to inventory
    self:AddItem(playerData, garden.herbType, totalYield)
    
    -- Remove garden
    herbGardens[gardenId] = nil
    
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Herb harvested:", player.Name, "harvested", totalYield, garden.herbType)
    
    RemoteEvents.FireClient("SystemMessage", player, "Harvested " .. totalYield .. " " .. garden.herbType .. "!")
end

-- Helper functions
function ResourceManager:GetNodeQuantity(rarity)
    local quantities = {
        Common = 10,
        Rare = 5,
        Legendary = 2
    }
    return quantities[rarity] or 5
end

function ResourceManager:GetMiningHardness(rarity)
    local hardness = {
        Common = 1,
        Rare = 3,
        Legendary = 5
    }
    return hardness[rarity] or 1
end

function ResourceManager:GetGatheringSkill(playerData, gatherType)
    -- For now, use cultivation/martial realm as gathering skill
    return math.max(playerData.cultivationRealm, playerData.martialRealm) * 10
end

function ResourceManager:DetermineQuality(rarity, skill)
    local baseChance = 0.1 + (skill * 0.001)
    local rand = math.random()
    
    if rarity == "Legendary" then
        if rand < baseChance * 0.1 then return "Perfect"
        elseif rand < baseChance * 0.3 then return "Excellent"
        elseif rand < baseChance * 0.6 then return "Good"
        else return "Normal" end
    elseif rarity == "Rare" then
        if rand < baseChance * 0.2 then return "Excellent"
        elseif rand < baseChance * 0.5 then return "Good"
        else return "Normal" end
    else
        if rand < baseChance * 0.3 then return "Good"
        else return "Normal" end
    end
end

function ResourceManager:DetermineCraftingQuality(skill, difficulty)
    local successMargin = skill - difficulty
    local rand = math.random()
    
    if successMargin > 50 then
        if rand < 0.1 then return "Perfect"
        elseif rand < 0.3 then return "Excellent"
        elseif rand < 0.6 then return "Good"
        else return "Normal" end
    elseif successMargin > 20 then
        if rand < 0.2 then return "Excellent"
        elseif rand < 0.5 then return "Good"
        else return "Normal" end
    else
        if rand < 0.3 then return "Good"
        else return "Normal" end
    end
end

function ResourceManager:GetItemCategory(itemId)
    local categories = {
        SpiritGrass = "herbs",
        BloodLotus = "herbs",
        DragonScale = "herbs",
        IronOre = "materials",
        SpiritCrystal = "materials",
        StarIron = "materials",
        SpiritStone = "materials",
        JadeEssence = "materials",
        CelestialCrystal = "materials"
    }
    return categories[itemId] or "materials"
end

function ResourceManager:GetRecipe(recipeId)
    local recipes = {
        QiGatheringPill = {
            id = "QiGatheringPill",
            resultId = "QiGatheringPill",
            resultName = "Qi Gathering Pill",
            resultQuantity = 1,
            stationType = "AlchemyFurnace",
            skillType = "alchemy",
            skillLevel = 1,
            difficulty = 10,
            craftingTime = 60,
            expGain = 50,
            ingredients = {
                {id = "SpiritGrass", quantity = 3}
            }
        },
        BreakthroughPill = {
            id = "BreakthroughPill",
            resultId = "BreakthroughPill",
            resultName = "Breakthrough Pill",
            resultQuantity = 1,
            stationType = "AlchemyFurnace",
            skillType = "alchemy",
            skillLevel = 5,
            difficulty = 50,
            craftingTime = 300,
            expGain = 200,
            ingredients = {
                {id = "BloodLotus", quantity = 1},
                {id = "SpiritGrass", quantity = 5}
            }
        }
    }
    return recipes[recipeId]
end

function ResourceManager:GetItemData(itemId)
    local items = {
        SpiritGrass = {name = "Spirit Grass", category = "herbs", effects = {qi = 10}},
        BloodLotus = {name = "Blood Lotus", category = "herbs", effects = {qi = 50}},
        DragonScale = {name = "Dragon Scale Herb", category = "herbs", effects = {qi = 500, breakthrough = 0.1}},
        QiGatheringPill = {name = "Qi Gathering Pill", category = "pills", effects = {qi = 100}},
        BreakthroughPill = {name = "Breakthrough Pill", category = "pills", effects = {breakthrough = 0.2}}
    }
    return items[itemId]
end

function ResourceManager:HasItem(playerData, itemId, quantity)
    for category, items in pairs(playerData.inventory) do
        for _, item in ipairs(items) do
            if item.id == itemId and item.quantity >= quantity then
                return true
            end
        end
    end
    return false
end

function ResourceManager:FindItem(playerData, itemId)
    for category, items in pairs(playerData.inventory) do
        for _, item in ipairs(items) do
            if item.id == itemId then
                return item
            end
        end
    end
    return nil
end

function ResourceManager:AddItem(playerData, itemId, quantity)
    local category = self:GetItemCategory(itemId)
    if not playerData.inventory[category] then
        playerData.inventory[category] = {}
    end
    
    -- Check if item already exists
    for _, item in ipairs(playerData.inventory[category]) do
        if item.id == itemId then
            item.quantity = item.quantity + quantity
            return
        end
    end
    
    -- Add new item
    table.insert(playerData.inventory[category], {
        id = itemId,
        name = itemId,
        quantity = quantity,
        quality = "Normal"
    })
end

function ResourceManager:RemoveItem(playerData, itemId, quantity)
    for category, items in pairs(playerData.inventory) do
        for i, item in ipairs(items) do
            if item.id == itemId then
                if item.quantity >= quantity then
                    item.quantity = item.quantity - quantity
                    if item.quantity <= 0 then
                        table.remove(items, i)
                    end
                    return true
                end
            end
        end
    end
    return false
end

function ResourceManager:IsValidPlantingLocation(location)
    -- Check if location is not too close to other gardens
    for _, garden in pairs(herbGardens) do
        local distance = (Vector3.new(location.x, location.y, location.z) - garden.location).Magnitude
        if distance < 20 then -- Minimum 20 studs apart
            return false
        end
    end
    return true
end

function ResourceManager:LoadMarketData()
    -- Load active market listings from datastore
    -- This would be implemented with proper pagination
    print("Loading market data...")
end

function ResourceManager:SaveMarketListing(listing)
    local success, result = pcall(function()
        marketDataStore:SetAsync(listing.id, listing)
    end)
    
    if not success then
        warn("Failed to save market listing:", result)
    end
end

function ResourceManager:ExpireMarketListing(listingId)
    local listing = activeListings[listingId]
    if listing then
        -- Return item to seller
        local seller = game.Players:GetPlayerByUserId(listing.sellerId)
        if seller then
            local gameManager = require(script.Parent.GameManager)
            local sellerData = gameManager:GetPlayerData(seller)
            if sellerData then
                self:AddItem(sellerData, listing.itemId, listing.quantity)
                gameManager:UpdatePlayerData(seller, sellerData)
                RemoteEvents.FireClient("SystemMessage", seller, "Market listing expired: " .. listing.itemId .. " returned to inventory")
            end
        end
        
        listing.status = "expired"
        activeListings[listingId] = nil
        
        self:SaveMarketListing(listing)
    end
end

function ResourceManager:Update(deltaTime)
    -- Update resource node regeneration
    self:UpdateResourceRegeneration(deltaTime)
    
    -- Update herb growth
    self:UpdateHerbGrowth(deltaTime)
    
    -- Clean up expired trades
    self:CleanupExpiredTrades()
    
    -- Update market listings
    self:UpdateMarketListings()
end

function ResourceManager:UpdateResourceRegeneration(deltaTime)
    -- This would handle gradual resource regeneration for nodes
end

function ResourceManager:UpdateHerbGrowth(deltaTime)
    -- This would handle herb growth progress updates
end

function ResourceManager:CleanupExpiredTrades()
    local currentTime = tick()
    
    for tradeId, trade in pairs(tradeRequests) do
        if currentTime - trade.timestamp > trade.timeout then
            self:CancelTrade(tradeId)
        end
    end
end

function ResourceManager:UpdateMarketListings()
    local currentTime = tick()
    
    for listingId, listing in pairs(activeListings) do
        if listing.status == "active" and currentTime > listing.expiresAt then
            self:ExpireMarketListing(listingId)
        end
    end
end

return ResourceManager

