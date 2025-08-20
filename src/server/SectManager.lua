--[[
    SectManager.lua
    Handles sect creation, management, wars, territories, and social interactions
    Manages both NPC sects and player-created sects
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

-- Import shared modules
local GameConstants = require(ReplicatedStorage.Shared.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local SectManager = {}
SectManager.__index = SectManager

-- Sect data storage
local sectDataStore = DataStoreService:GetDataStore("SectData_v1")
local activeSects = {}
local npcSects = {}
local sectWars = {}
local territories = {}

-- Sect invitation system
local pendingInvitations = {}

function SectManager.new()
    local self = setmetatable({}, SectManager)
    
    -- Set up remote event handlers
    self:SetupRemoteEvents()
    
    -- Load existing sects
    self:LoadSects()
    
    return self
end

function SectManager:InitializePlayer(player, playerData)
    print("Initializing sect system for player:", player.Name)
    
    -- Set up player's sect data if not exists
    if not playerData.sect then
        playerData.sect = {
            sectId = nil,
            rank = 0,
            contributionPoints = 0,
            joinDate = nil,
            permissions = {},
            reputation = 0,
            achievements = {}
        }
    end
    
    -- If player is in a sect, load sect info
    if playerData.sect.sectId then
        local sectInfo = self:GetSectInfo(playerData.sect.sectId)
        if sectInfo then
            RemoteEvents.FireClient("SectUpdate", player, sectInfo)
        else
            -- Sect no longer exists, remove player from it
            playerData.sect.sectId = nil
            playerData.sect.rank = 0
        end
    end
end

function SectManager:CleanupPlayer(player)
    local userId = player.UserId
    
    -- Clean up pending invitations
    pendingInvitations[userId] = nil
    
    print("Cleaned up sect system for player:", player.Name)
end

function SectManager:SetupRemoteEvents()
    -- Create sect
    RemoteEvents.ConnectEvent("CreateSect", function(player, sectName, sectType, description)
        self:CreateSect(player, sectName, sectType, description)
    end)
    
    -- Join sect
    RemoteEvents.ConnectEvent("JoinSect", function(player, sectId)
        self:JoinSect(player, sectId)
    end)
    
    -- Leave sect
    RemoteEvents.ConnectEvent("LeaveSect", function(player)
        self:LeaveSect(player)
    end)
    
    -- Invite player to sect
    RemoteEvents.ConnectEvent("InviteToSect", function(player, targetPlayerName)
        self:InvitePlayer(player, targetPlayerName)
    end)
    
    -- Respond to sect invitation
    RemoteEvents.ConnectEvent("RespondToInvitation", function(player, sectId, accept)
        self:RespondToInvitation(player, sectId, accept)
    end)
    
    -- Contribute to sect
    RemoteEvents.ConnectEvent("ContributeToSect", function(player, contributionType, amount)
        self:ContributeToSect(player, contributionType, amount)
    end)
    
    -- Declare sect war
    RemoteEvents.ConnectEvent("DeclareSectWar", function(player, targetSectId)
        self:DeclareSectWar(player, targetSectId)
    end)
    
    -- Manage sect (promote, demote, kick)
    RemoteEvents.ConnectEvent("ManageSectMember", function(player, targetUserId, action)
        self:ManageSectMember(player, targetUserId, action)
    end)
    
    -- Get sect information
    RemoteEvents.ConnectFunction("GetSectInfo", function(player, sectId)
        return self:GetSectInfo(sectId)
    end)
end

function SectManager:CreateSect(player, sectName, sectType, description)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        warn("No player data found for sect creation")
        return
    end
    
    -- Check if player is already in a sect
    if playerData.sect.sectId then
        RemoteEvents.FireClient("SystemMessage", player, "You are already in a sect!")
        return
    end
    
    -- Check minimum requirements
    if playerData.cultivationRealm < 2 and playerData.martialRealm < 2 then
        RemoteEvents.FireClient("SystemMessage", player, "Requires at least Qi Refining or Second Rate realm!")
        return
    end
    
    -- Check if sect name is available
    if self:IsSectNameTaken(sectName) then
        RemoteEvents.FireClient("SystemMessage", player, "Sect name is already taken!")
        return
    end
    
    -- Check creation cost
    local creationCost = 10000 -- Spirit stones
    if not playerData.resources.spiritStones or playerData.resources.spiritStones < creationCost then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient spirit stones! Requires " .. creationCost)
        return
    end
    
    -- Validate sect type
    local validTypes = {"Cultivation", "MartialArts", "Mixed", "Merchant", "Scholar"}
    local isValidType = false
    for _, validType in ipairs(validTypes) do
        if sectType == validType then
            isValidType = true
            break
        end
    end
    
    if not isValidType then
        warn("Invalid sect type:", sectType)
        return
    end
    
    -- Create new sect
    local sectId = "sect_" .. player.UserId .. "_" .. tick()
    local newSect = {
        id = sectId,
        name = sectName,
        type = sectType,
        description = description,
        founderId = player.UserId,
        founderName = player.Name,
        createdAt = tick(),
        level = 1,
        experience = 0,
        reputation = 0,
        treasury = {
            spiritStones = 0,
            resources = {},
            artifacts = {}
        },
        members = {
            [player.UserId] = {
                userId = player.UserId,
                username = player.Name,
                rank = 10, -- Sect Master
                contributionPoints = 0,
                joinDate = tick(),
                permissions = {"all"}
            }
        },
        ranks = {
            [10] = {name = "Sect Master", permissions = {"all"}},
            [9] = {name = "Elder", permissions = {"invite", "kick_low", "manage_treasury"}},
            [8] = {name = "Core Disciple", permissions = {"invite"}},
            [7] = {name = "Inner Disciple", permissions = {}},
            [6] = {name = "Outer Disciple", permissions = {}},
            [5] = {name = "Servant Disciple", permissions = {}}
        },
        territory = {
            center = player.Character and player.Character.HumanoidRootPart.Position or Vector3.new(0, 0, 0),
            radius = 100,
            buildings = {},
            defenses = 0
        },
        policies = {
            autoAccept = false,
            minRealm = 1,
            contributionTax = 0.1,
            warPolicy = "Defensive"
        },
        wars = {},
        alliances = {},
        achievements = {},
        isNPC = false
    }
    
    -- Deduct creation cost
    playerData.resources.spiritStones = playerData.resources.spiritStones - creationCost
    
    -- Update player sect data
    playerData.sect.sectId = sectId
    playerData.sect.rank = 10
    playerData.sect.joinDate = tick()
    playerData.sect.permissions = {"all"}
    
    -- Save sect and player data
    activeSects[sectId] = newSect
    self:SaveSect(newSect)
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Sect created:", sectName, "by", player.Name)
    
    -- Notify player
    RemoteEvents.FireClient("SectUpdate", player, newSect)
    RemoteEvents.FireClient("SystemMessage", player, "Sect '" .. sectName .. "' created successfully!")
    
    -- Announce to server
    RemoteEvents.FireAllClients("SystemMessage", player.Name .. " has founded the " .. sectName .. " sect!")
end

function SectManager:JoinSect(player, sectId)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Check if player is already in a sect
    if playerData.sect.sectId then
        RemoteEvents.FireClient("SystemMessage", player, "You are already in a sect!")
        return
    end
    
    local sect = activeSects[sectId] or npcSects[sectId]
    if not sect then
        RemoteEvents.FireClient("SystemMessage", player, "Sect not found!")
        return
    end
    
    -- Check if sect is full
    local memberCount = 0
    for _ in pairs(sect.members) do
        memberCount = memberCount + 1
    end
    
    if memberCount >= GameConstants.SECTS.MAX_MEMBERS_PER_SECT then
        RemoteEvents.FireClient("SystemMessage", player, "Sect is full!")
        return
    end
    
    -- Check minimum requirements
    local minRealm = sect.policies.minRealm or 1
    if playerData.cultivationRealm < minRealm and playerData.martialRealm < minRealm then
        RemoteEvents.FireClient("SystemMessage", player, "You don't meet the minimum realm requirement!")
        return
    end
    
    -- Check if auto-accept is enabled
    if sect.policies.autoAccept then
        self:AddPlayerToSect(player, sect, 6) -- Outer Disciple
    else
        -- Send join request to sect leaders
        self:SendJoinRequest(player, sect)
    end
end

function SectManager:AddPlayerToSect(player, sect, rank)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData then
        return
    end
    
    -- Add player to sect
    sect.members[player.UserId] = {
        userId = player.UserId,
        username = player.Name,
        rank = rank,
        contributionPoints = 0,
        joinDate = tick(),
        permissions = sect.ranks[rank].permissions or {}
    }
    
    -- Update player data
    playerData.sect.sectId = sect.id
    playerData.sect.rank = rank
    playerData.sect.joinDate = tick()
    playerData.sect.permissions = sect.ranks[rank].permissions or {}
    
    -- Save data
    if not sect.isNPC then
        self:SaveSect(sect)
    end
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "joined sect", sect.name)
    
    -- Notify player
    RemoteEvents.FireClient("SectUpdate", player, sect)
    RemoteEvents.FireClient("SystemMessage", player, "Welcome to " .. sect.name .. "!")
    
    -- Notify sect members
    for memberId, member in pairs(sect.members) do
        local memberPlayer = game.Players:GetPlayerByUserId(memberId)
        if memberPlayer and memberPlayer ~= player then
            RemoteEvents.FireClient("SystemMessage", memberPlayer, player.Name .. " has joined the sect!")
        end
    end
end

function SectManager:LeaveSect(player)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or not playerData.sect.sectId then
        RemoteEvents.FireClient("SystemMessage", player, "You are not in a sect!")
        return
    end
    
    local sect = activeSects[playerData.sect.sectId] or npcSects[playerData.sect.sectId]
    if not sect then
        return
    end
    
    -- Check if player is sect master
    if playerData.sect.rank == 10 then
        -- Transfer leadership or disband sect
        local newLeader = self:FindSuccessor(sect, player.UserId)
        if newLeader then
            -- Transfer leadership
            sect.members[newLeader].rank = 10
            sect.members[newLeader].permissions = {"all"}
            
            local newLeaderPlayer = game.Players:GetPlayerByUserId(newLeader)
            if newLeaderPlayer then
                RemoteEvents.FireClient("SystemMessage", newLeaderPlayer, "You are now the sect master!")
            end
        else
            -- Disband sect
            self:DisbandSect(sect)
            return
        end
    end
    
    -- Remove player from sect
    sect.members[player.UserId] = nil
    
    -- Reset player sect data
    playerData.sect.sectId = nil
    playerData.sect.rank = 0
    playerData.sect.permissions = {}
    
    -- Save data
    if not sect.isNPC then
        self:SaveSect(sect)
    end
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "left sect", sect.name)
    
    -- Notify player
    RemoteEvents.FireClient("SectUpdate", player, nil)
    RemoteEvents.FireClient("SystemMessage", player, "You have left " .. sect.name)
    
    -- Notify remaining sect members
    for memberId, member in pairs(sect.members) do
        local memberPlayer = game.Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            RemoteEvents.FireClient("SystemMessage", memberPlayer, player.Name .. " has left the sect")
        end
    end
end

function SectManager:InvitePlayer(player, targetPlayerName)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or not playerData.sect.sectId then
        RemoteEvents.FireClient("SystemMessage", player, "You are not in a sect!")
        return
    end
    
    -- Check permissions
    if not self:HasPermission(playerData.sect.permissions, "invite") then
        RemoteEvents.FireClient("SystemMessage", player, "You don't have permission to invite players!")
        return
    end
    
    local targetPlayer = game.Players:FindFirstChild(targetPlayerName)
    if not targetPlayer then
        RemoteEvents.FireClient("SystemMessage", player, "Player not found!")
        return
    end
    
    local targetData = gameManager:GetPlayerData(targetPlayer)
    if not targetData then
        return
    end
    
    -- Check if target is already in a sect
    if targetData.sect.sectId then
        RemoteEvents.FireClient("SystemMessage", player, "Player is already in a sect!")
        return
    end
    
    local sect = activeSects[playerData.sect.sectId] or npcSects[playerData.sect.sectId]
    if not sect then
        return
    end
    
    -- Send invitation
    local invitation = {
        sectId = sect.id,
        sectName = sect.name,
        inviterName = player.Name,
        inviteTime = tick()
    }
    
    if not pendingInvitations[targetPlayer.UserId] then
        pendingInvitations[targetPlayer.UserId] = {}
    end
    pendingInvitations[targetPlayer.UserId][sect.id] = invitation
    
    RemoteEvents.FireClient("SectInvitation", targetPlayer, invitation)
    RemoteEvents.FireClient("SystemMessage", player, "Invitation sent to " .. targetPlayerName)
    
    print("Sect invitation sent from", player.Name, "to", targetPlayerName, "for sect", sect.name)
end

function SectManager:RespondToInvitation(player, sectId, accept)
    local userId = player.UserId
    
    if not pendingInvitations[userId] or not pendingInvitations[userId][sectId] then
        RemoteEvents.FireClient("SystemMessage", player, "No pending invitation found!")
        return
    end
    
    local invitation = pendingInvitations[userId][sectId]
    pendingInvitations[userId][sectId] = nil
    
    if accept then
        local sect = activeSects[sectId] or npcSects[sectId]
        if sect then
            self:AddPlayerToSect(player, sect, 6) -- Outer Disciple
        end
    else
        RemoteEvents.FireClient("SystemMessage", player, "Invitation declined")
    end
end

function SectManager:ContributeToSect(player, contributionType, amount)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or not playerData.sect.sectId then
        RemoteEvents.FireClient("SystemMessage", player, "You are not in a sect!")
        return
    end
    
    local sect = activeSects[playerData.sect.sectId] or npcSects[playerData.sect.sectId]
    if not sect then
        return
    end
    
    -- Validate contribution
    local validContributions = {"spiritStones", "qi", "herbs", "materials"}
    local isValid = false
    for _, validType in ipairs(validContributions) do
        if contributionType == validType then
            isValid = true
            break
        end
    end
    
    if not isValid then
        warn("Invalid contribution type:", contributionType)
        return
    end
    
    -- Check if player has enough resources
    local playerResource = playerData.resources[contributionType]
    if not playerResource or playerResource < amount then
        RemoteEvents.FireClient("SystemMessage", player, "Insufficient " .. contributionType .. "!")
        return
    end
    
    -- Calculate contribution points
    local contributionPoints = amount
    if contributionType == "spiritStones" then
        contributionPoints = amount * 1
    elseif contributionType == "qi" then
        contributionPoints = amount * 0.1
    else
        contributionPoints = amount * 0.5
    end
    
    -- Apply contribution
    playerData.resources[contributionType] = playerData.resources[contributionType] - amount
    playerData.sect.contributionPoints = playerData.sect.contributionPoints + contributionPoints
    
    -- Add to sect treasury
    if not sect.treasury[contributionType] then
        sect.treasury[contributionType] = 0
    end
    sect.treasury[contributionType] = sect.treasury[contributionType] + amount
    
    -- Update sect member data
    if sect.members[player.UserId] then
        sect.members[player.UserId].contributionPoints = sect.members[player.UserId].contributionPoints + contributionPoints
    end
    
    -- Save data
    if not sect.isNPC then
        self:SaveSect(sect)
    end
    gameManager:UpdatePlayerData(player, playerData)
    
    print("Player", player.Name, "contributed", amount, contributionType, "to sect", sect.name)
    
    RemoteEvents.FireClient("SystemMessage", player, "Contributed " .. amount .. " " .. contributionType .. " to the sect!")
    RemoteEvents.FireClient("SectContribution", player, {
        type = contributionType,
        amount = amount,
        contributionPoints = contributionPoints
    })
end

function SectManager:DeclareSectWar(player, targetSectId)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or not playerData.sect.sectId then
        RemoteEvents.FireClient("SystemMessage", player, "You are not in a sect!")
        return
    end
    
    -- Check permissions (only sect master and elders can declare war)
    if playerData.sect.rank < 9 then
        RemoteEvents.FireClient("SystemMessage", player, "Only sect masters and elders can declare war!")
        return
    end
    
    local attackingSect = activeSects[playerData.sect.sectId] or npcSects[playerData.sect.sectId]
    local defendingSect = activeSects[targetSectId] or npcSects[targetSectId]
    
    if not attackingSect or not defendingSect then
        RemoteEvents.FireClient("SystemMessage", player, "Invalid sect!")
        return
    end
    
    -- Check if already at war
    for _, war in pairs(sectWars) do
        if (war.attackingSectId == attackingSect.id and war.defendingSectId == defendingSect.id) or
           (war.attackingSectId == defendingSect.id and war.defendingSectId == attackingSect.id) then
            RemoteEvents.FireClient("SystemMessage", player, "Already at war with this sect!")
            return
        end
    end
    
    -- Check war cooldown
    local lastWar = attackingSect.lastWarTime or 0
    if tick() - lastWar < GameConstants.SECTS.SECT_WAR_COOLDOWN then
        local remaining = GameConstants.SECTS.SECT_WAR_COOLDOWN - (tick() - lastWar)
        RemoteEvents.FireClient("SystemMessage", player, "War cooldown: " .. math.floor(remaining / 3600) .. " hours remaining")
        return
    end
    
    -- Create sect war
    local warId = "war_" .. attackingSect.id .. "_" .. defendingSect.id .. "_" .. tick()
    local war = {
        id = warId,
        attackingSectId = attackingSect.id,
        attackingSectName = attackingSect.name,
        defendingSectId = defendingSect.id,
        defendingSectName = defendingSect.name,
        startTime = tick(),
        duration = GameConstants.PVP.SECT_WAR_DURATION,
        attackingScore = 0,
        defendingScore = 0,
        battles = {},
        active = true
    }
    
    sectWars[warId] = war
    attackingSect.lastWarTime = tick()
    
    -- Save sect data
    if not attackingSect.isNPC then
        self:SaveSect(attackingSect)
    end
    
    print("Sect war declared:", attackingSect.name, "vs", defendingSect.name)
    
    -- Notify all players
    RemoteEvents.FireAllClients("SectWarDeclaration", war)
    
    -- Notify sect members
    for memberId, member in pairs(attackingSect.members) do
        local memberPlayer = game.Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            RemoteEvents.FireClient("SystemMessage", memberPlayer, "War declared against " .. defendingSect.name .. "!")
        end
    end
    
    for memberId, member in pairs(defendingSect.members) do
        local memberPlayer = game.Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            RemoteEvents.FireClient("SystemMessage", memberPlayer, attackingSect.name .. " has declared war on your sect!")
        end
    end
end

function SectManager:ManageSectMember(player, targetUserId, action)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or not playerData.sect.sectId then
        RemoteEvents.FireClient("SystemMessage", player, "You are not in a sect!")
        return
    end
    
    local sect = activeSects[playerData.sect.sectId] or npcSects[playerData.sect.sectId]
    if not sect then
        return
    end
    
    local targetMember = sect.members[targetUserId]
    if not targetMember then
        RemoteEvents.FireClient("SystemMessage", player, "Player is not in your sect!")
        return
    end
    
    -- Check permissions and rank hierarchy
    local playerRank = playerData.sect.rank
    local targetRank = targetMember.rank
    
    if action == "promote" then
        if playerRank <= targetRank or not self:HasPermission(playerData.sect.permissions, "promote") then
            RemoteEvents.FireClient("SystemMessage", player, "Insufficient permissions!")
            return
        end
        
        if targetRank < 10 then
            targetMember.rank = targetRank + 1
            targetMember.permissions = sect.ranks[targetRank + 1].permissions or {}
            
            local targetPlayer = game.Players:GetPlayerByUserId(targetUserId)
            if targetPlayer then
                local targetPlayerData = gameManager:GetPlayerData(targetPlayer)
                if targetPlayerData then
                    targetPlayerData.sect.rank = targetRank + 1
                    targetPlayerData.sect.permissions = targetMember.permissions
                    gameManager:UpdatePlayerData(targetPlayer, targetPlayerData)
                end
                RemoteEvents.FireClient("SystemMessage", targetPlayer, "You have been promoted to " .. sect.ranks[targetRank + 1].name .. "!")
            end
        end
        
    elseif action == "demote" then
        if playerRank <= targetRank or not self:HasPermission(playerData.sect.permissions, "demote") then
            RemoteEvents.FireClient("SystemMessage", player, "Insufficient permissions!")
            return
        end
        
        if targetRank > 5 then
            targetMember.rank = targetRank - 1
            targetMember.permissions = sect.ranks[targetRank - 1].permissions or {}
            
            local targetPlayer = game.Players:GetPlayerByUserId(targetUserId)
            if targetPlayer then
                local targetPlayerData = gameManager:GetPlayerData(targetPlayer)
                if targetPlayerData then
                    targetPlayerData.sect.rank = targetRank - 1
                    targetPlayerData.sect.permissions = targetMember.permissions
                    gameManager:UpdatePlayerData(targetPlayer, targetPlayerData)
                end
                RemoteEvents.FireClient("SystemMessage", targetPlayer, "You have been demoted to " .. sect.ranks[targetRank - 1].name)
            end
        end
        
    elseif action == "kick" then
        if playerRank <= targetRank or not self:HasPermission(playerData.sect.permissions, "kick") then
            RemoteEvents.FireClient("SystemMessage", player, "Insufficient permissions!")
            return
        end
        
        -- Remove from sect
        sect.members[targetUserId] = nil
        
        local targetPlayer = game.Players:GetPlayerByUserId(targetUserId)
        if targetPlayer then
            local targetPlayerData = gameManager:GetPlayerData(targetPlayer)
            if targetPlayerData then
                targetPlayerData.sect.sectId = nil
                targetPlayerData.sect.rank = 0
                targetPlayerData.sect.permissions = {}
                gameManager:UpdatePlayerData(targetPlayer, targetPlayerData)
            end
            RemoteEvents.FireClient("SystemMessage", targetPlayer, "You have been kicked from " .. sect.name)
            RemoteEvents.FireClient("SectUpdate", targetPlayer, nil)
        end
    end
    
    -- Save sect data
    if not sect.isNPC then
        self:SaveSect(sect)
    end
    
    print("Sect management action:", action, "by", player.Name, "on", targetMember.username)
end

function SectManager:GetSectInfo(sectId)
    return activeSects[sectId] or npcSects[sectId]
end

function SectManager:GetSectCount()
    local count = 0
    for _ in pairs(activeSects) do
        count = count + 1
    end
    for _ in pairs(npcSects) do
        count = count + 1
    end
    return count
end

function SectManager:HasPermission(permissions, requiredPermission)
    if not permissions then
        return false
    end
    
    for _, permission in ipairs(permissions) do
        if permission == "all" or permission == requiredPermission then
            return true
        end
    end
    
    return false
end

function SectManager:IsSectNameTaken(sectName)
    for _, sect in pairs(activeSects) do
        if sect.name == sectName then
            return true
        end
    end
    
    for _, sect in pairs(npcSects) do
        if sect.name == sectName then
            return true
        end
    end
    
    return false
end

function SectManager:FindSuccessor(sect, excludeUserId)
    local highestRank = 0
    local successor = nil
    
    for userId, member in pairs(sect.members) do
        if userId ~= excludeUserId and member.rank > highestRank then
            highestRank = member.rank
            successor = userId
        end
    end
    
    return successor
end

function SectManager:DisbandSect(sect)
    print("Disbanding sect:", sect.name)
    
    -- Notify all members
    for memberId, member in pairs(sect.members) do
        local memberPlayer = game.Players:GetPlayerByUserId(memberId)
        if memberPlayer then
            local gameManager = require(script.Parent.GameManager)
            local memberData = gameManager:GetPlayerData(memberPlayer)
            if memberData then
                memberData.sect.sectId = nil
                memberData.sect.rank = 0
                memberData.sect.permissions = {}
                gameManager:UpdatePlayerData(memberPlayer, memberData)
            end
            RemoteEvents.FireClient("SystemMessage", memberPlayer, sect.name .. " has been disbanded!")
            RemoteEvents.FireClient("SectUpdate", memberPlayer, nil)
        end
    end
    
    -- Remove sect
    activeSects[sect.id] = nil
    
    -- Delete from datastore
    pcall(function()
        sectDataStore:RemoveAsync(sect.id)
    end)
end

function SectManager:LoadSects()
    -- Load player sects from datastore
    -- This would be implemented with proper pagination for large numbers of sects
    print("Loading existing sects...")
    
    -- For now, we'll just initialize with empty tables
    -- In a real implementation, you'd load from DataStore
end

function SectManager:SaveSect(sect)
    if sect.isNPC then
        return -- Don't save NPC sects
    end
    
    local success, result = pcall(function()
        sectDataStore:SetAsync(sect.id, sect)
    end)
    
    if not success then
        warn("Failed to save sect data:", result)
    end
end

function SectManager:InitializeNPCSects()
    -- Create NPC sects for players to interact with
    local npcSectData = {
        {
            name = "Heavenly Sword Sect",
            type = "MartialArts",
            description = "Masters of sword techniques and martial prowess",
            level = 10,
            reputation = 5000,
            territory = {center = Vector3.new(1000, 0, 0), radius = 200}
        },
        {
            name = "Mystic Pill Pavilion",
            type = "Cultivation",
            description = "Renowned alchemists and pill refiners",
            level = 8,
            reputation = 4000,
            territory = {center = Vector3.new(-1000, 0, 0), radius = 150}
        },
        {
            name = "Demon Blood Clan",
            type = "Mixed",
            description = "Fierce warriors with demon bloodline",
            level = 12,
            reputation = 6000,
            territory = {center = Vector3.new(0, 0, 1000), radius = 250}
        },
        {
            name = "Scholarly Pavilion",
            type = "Scholar",
            description = "Keepers of ancient knowledge and techniques",
            level = 6,
            reputation = 3000,
            territory = {center = Vector3.new(0, 0, -1000), radius = 100}
        }
    }
    
    for i, sectData in ipairs(npcSectData) do
        local sectId = "npc_sect_" .. i
        npcSects[sectId] = {
            id = sectId,
            name = sectData.name,
            type = sectData.type,
            description = sectData.description,
            founderId = 0,
            founderName = "Ancient Master",
            createdAt = 0,
            level = sectData.level,
            experience = sectData.level * 10000,
            reputation = sectData.reputation,
            treasury = {
                spiritStones = sectData.level * 100000,
                resources = {},
                artifacts = {}
            },
            members = {}, -- NPC members would be generated
            territory = sectData.territory,
            policies = {
                autoAccept = false,
                minRealm = sectData.level,
                contributionTax = 0.05,
                warPolicy = "Aggressive"
            },
            wars = {},
            alliances = {},
            achievements = {},
            isNPC = true
        }
    end
    
    print("Initialized", #npcSectData, "NPC sects")
end

function SectManager:Update()
    -- Update sect wars
    self:UpdateSectWars()
    
    -- Update sect territories
    self:UpdateTerritories()
    
    -- Clean up expired invitations
    self:CleanupInvitations()
end

function SectManager:UpdateSectWars()
    local currentTime = tick()
    
    for warId, war in pairs(sectWars) do
        if war.active then
            local elapsed = currentTime - war.startTime
            
            if elapsed > war.duration then
                -- End war
                self:EndSectWar(war)
                sectWars[warId] = nil
            end
        end
    end
end

function SectManager:EndSectWar(war)
    local winner = war.attackingScore > war.defendingScore and "attacking" or "defending"
    local winnerSectId = winner == "attacking" and war.attackingSectId or war.defendingSectId
    local loserSectId = winner == "attacking" and war.defendingSectId or war.attackingSectId
    
    print("Sect war ended:", war.attackingSectName, "vs", war.defendingSectName, "Winner:", winner)
    
    -- Apply war results
    local winnerSect = activeSects[winnerSectId] or npcSects[winnerSectId]
    local loserSect = activeSects[loserSectId] or npcSects[loserSectId]
    
    if winnerSect then
        winnerSect.reputation = winnerSect.reputation + 1000
        winnerSect.experience = winnerSect.experience + 5000
    end
    
    if loserSect then
        loserSect.reputation = math.max(0, loserSect.reputation - 500)
    end
    
    -- Notify all players
    RemoteEvents.FireAllClients("SystemMessage", "Sect war ended! " .. (winner == "attacking" and war.attackingSectName or war.defendingSectName) .. " is victorious!")
end

function SectManager:UpdateTerritories()
    -- Update territory control and benefits
    -- This would involve checking player presence in territories
end

function SectManager:CleanupInvitations()
    local currentTime = tick()
    
    for userId, invitations in pairs(pendingInvitations) do
        for sectId, invitation in pairs(invitations) do
            if currentTime - invitation.inviteTime > 300 then -- 5 minute expiry
                invitations[sectId] = nil
            end
        end
        
        if next(invitations) == nil then
            pendingInvitations[userId] = nil
        end
    end
end

return SectManager

