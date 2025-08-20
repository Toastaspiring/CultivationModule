--[[
    CombatSystem.lua
    Handles PvP combat, intent prediction, emotion-based combat mechanics,
    Gang Qi interactions, and cultivation vs martial arts combat
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Import shared modules
local GameConstants = require(ReplicatedStorage.Shared.GameConstants)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

local CombatSystem = {}
CombatSystem.__index CombatSystem

-- Active combat sessions
local activeCombats = {}

-- Combat invitations
local combatInvitations = {}

-- Intent prediction data
local intentPredictions = {}

-- Damage over time effects
local dotEffects = {}

function CombatSystem.new()
    local self = setmetatable({}, CombatSystem)
    
    -- Set up remote event handlers
    self:SetupRemoteEvents()
    
    return self
end

function CombatSystem:InitializePlayer(player, playerData)
    print("Initializing combat system for player:", player.Name)
    
    -- Set up player's combat data if not exists
    if not playerData.combat then
        playerData.combat = {
            health = 1000,
            maxHealth = 1000,
            mana = 500,
            maxMana = 500,
            stamina = 100,
            maxStamina = 100,
            combatRating = 100,
            wins = 0,
            losses = 0,
            killStreak = 0,
            lastCombatTime = 0,
            combatStyle = "Balanced",
            techniques = {},
            buffs = {},
            debuffs = {},
            immunities = {}
        }
    end
    
    -- Calculate combat stats based on realm and path
    self:UpdateCombatStats(player, playerData)
end

function CombatSystem:CleanupPlayer(player)
    local userId = player.UserId
    
    -- End any active combat
    if activeCombats[userId] then
        self:EndCombat(activeCombats[userId], "disconnect")
    end
    
    -- Clean up invitations
    combatInvitations[userId] = nil
    
    -- Clean up intent predictions
    intentPredictions[userId] = nil
    
    -- Clean up DoT effects
    dotEffects[userId] = nil
    
    print("Cleaned up combat system for player:", player.Name)
end

function CombatSystem:SetupRemoteEvents()
    -- Initiate combat
    RemoteEvents.ConnectEvent("InitiateCombat", function(player, targetPlayer, combatType)
        self:InitiateCombat(player, targetPlayer, combatType)
    end)
    
    -- Accept/decline combat
    RemoteEvents.ConnectEvent("RespondToCombat", function(player, combatId, accept)
        self:RespondToCombat(player, combatId, accept)
    end)
    
    -- Combat action
    RemoteEvents.ConnectEvent("CombatAction", function(player, action)
        self:ProcessCombatAction(player, action)
    end)
    
    -- Predict intent
    RemoteEvents.ConnectEvent("PredictIntent", function(player, targetPlayer, predictedAction)
        self:PredictIntent(player, targetPlayer, predictedAction)
    end)
    
    -- Use technique
    RemoteEvents.ConnectEvent("UseTechnique", function(player, techniqueId, target)
        self:UseTechnique(player, techniqueId, target)
    end)
    
    -- Surrender
    RemoteEvents.ConnectEvent("Surrender", function(player)
        self:Surrender(player)
    end)
end

function CombatSystem:InitiateCombat(player, targetPlayer, combatType)
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    local targetData = gameManager:GetPlayerData(targetPlayer)
    
    if not playerData or not targetData then
        return
    end
    
    -- Check if players are in safe zone
    if self:IsInSafeZone(player) or self:IsInSafeZone(targetPlayer) then
        RemoteEvents.FireClient("SystemMessage", player, "Cannot initiate combat in safe zone!")
        return
    end
    
    -- Check combat cooldown
    local currentTime = tick()
    if currentTime - playerData.combat.lastCombatTime < GameConstants.PVP.PVP_COOLDOWN then
        local remaining = GameConstants.PVP.PVP_COOLDOWN - (currentTime - playerData.combat.lastCombatTime)
        RemoteEvents.FireClient("SystemMessage", player, "Combat cooldown: " .. math.floor(remaining) .. " seconds")
        return
    end
    
    -- Check if target is already in combat
    if activeCombats[targetPlayer.UserId] then
        RemoteEvents.FireClient("SystemMessage", player, "Target is already in combat!")
        return
    end
    
    -- Validate combat type
    local validTypes = {"Duel", "Sparring", "SectWar", "Tournament"}
    local isValidType = false
    for _, validType in ipairs(validTypes) do
        if combatType == validType then
            isValidType = true
            break
        end
    end
    
    if not isValidType then
        warn("Invalid combat type:", combatType)
        return
    end
    
    -- Create combat invitation
    local combatId = "combat_" .. player.UserId .. "_" .. targetPlayer.UserId .. "_" .. tick()
    local invitation = {
        id = combatId,
        challenger = player,
        target = targetPlayer,
        type = combatType,
        timestamp = currentTime,
        timeout = 30 -- 30 seconds to respond
    }
    
    combatInvitations[combatId] = invitation
    
    print("Combat invitation sent from", player.Name, "to", targetPlayer.Name, "Type:", combatType)
    
    -- Send invitation to target
    RemoteEvents.FireClient("CombatInvitation", targetPlayer, {
        challengerId = player.UserId,
        challengerName = player.Name,
        challengerRealm = self:GetDisplayRealm(playerData),
        combatType = combatType,
        combatId = combatId,
        timeout = invitation.timeout
    })
    
    RemoteEvents.FireClient("SystemMessage", player, "Combat invitation sent to " .. targetPlayer.Name)
    
    -- Auto-expire invitation
    spawn(function()
        wait(invitation.timeout)
        if combatInvitations[combatId] then
            combatInvitations[combatId] = nil
            RemoteEvents.FireClient("SystemMessage", player, "Combat invitation expired")
            RemoteEvents.FireClient("SystemMessage", targetPlayer, "Combat invitation expired")
        end
    end)
end

function CombatSystem:RespondToCombat(player, combatId, accept)
    local invitation = combatInvitations[combatId]
    if not invitation or invitation.target ~= player then
        RemoteEvents.FireClient("SystemMessage", player, "Invalid combat invitation!")
        return
    end
    
    combatInvitations[combatId] = nil
    
    if accept then
        self:StartCombat(invitation.challenger, invitation.target, invitation.type)
    else
        RemoteEvents.FireClient("SystemMessage", invitation.challenger, player.Name .. " declined the combat invitation")
        RemoteEvents.FireClient("SystemMessage", player, "Combat invitation declined")
    end
end

function CombatSystem:StartCombat(player1, player2, combatType)
    local gameManager = require(script.Parent.GameManager)
    local player1Data = gameManager:GetPlayerData(player1)
    local player2Data = gameManager:GetPlayerData(player2)
    
    if not player1Data or not player2Data then
        return
    end
    
    -- Create combat session
    local combatId = "combat_" .. player1.UserId .. "_" .. player2.UserId .. "_" .. tick()
    local combat = {
        id = combatId,
        type = combatType,
        players = {player1, player2},
        playerData = {player1Data, player2Data},
        startTime = tick(),
        turn = 1,
        currentPlayer = 1,
        turnTimeLimit = 30, -- 30 seconds per turn
        turnStartTime = tick(),
        actions = {},
        effects = {},
        winner = nil,
        ended = false,
        arena = self:CreateArena(player1, player2)
    }
    
    -- Set up combat stats
    for i, playerData in ipairs(combat.playerData) do
        playerData.combat.currentHealth = playerData.combat.maxHealth
        playerData.combat.currentMana = playerData.combat.maxMana
        playerData.combat.currentStamina = playerData.combat.maxStamina
        playerData.combat.buffs = {}
        playerData.combat.debuffs = {}
    end
    
    activeCombats[player1.UserId] = combat
    activeCombats[player2.UserId] = combat
    
    print("Combat started:", player1.Name, "vs", player2.Name, "Type:", combatType)
    
    -- Notify players
    for i, player in ipairs(combat.players) do
        RemoteEvents.FireClient("CombatStart", player, {
            combatId = combatId,
            opponent = combat.players[3-i].Name,
            opponentData = self:GetPublicCombatData(combat.playerData[3-i]),
            combatType = combatType,
            turnTimeLimit = combat.turnTimeLimit,
            arena = combat.arena
        })
    end
    
    -- Start first turn
    self:StartTurn(combat)
end

function CombatSystem:ProcessCombatAction(player, action)
    local userId = player.UserId
    local combat = activeCombats[userId]
    
    if not combat or combat.ended then
        return
    end
    
    -- Check if it's player's turn
    local playerIndex = combat.players[1] == player and 1 or 2
    if combat.currentPlayer ~= playerIndex then
        RemoteEvents.FireClient("SystemMessage", player, "It's not your turn!")
        return
    end
    
    -- Validate action
    local isValid, errorMsg = RemoteEvents.ValidateCombatAction(action)
    if not isValid then
        RemoteEvents.FireClient("SystemMessage", player, errorMsg)
        return
    end
    
    -- Process the action
    local result = self:ExecuteAction(combat, playerIndex, action)
    
    -- Record action
    table.insert(combat.actions, {
        turn = combat.turn,
        player = playerIndex,
        action = action,
        result = result,
        timestamp = tick()
    })
    
    -- Check for combat end conditions
    if self:CheckCombatEnd(combat) then
        return
    end
    
    -- Switch turns
    self:NextTurn(combat)
end

function CombatSystem:ExecuteAction(combat, playerIndex, action)
    local attacker = combat.players[playerIndex]
    local defender = combat.players[3 - playerIndex]
    local attackerData = combat.playerData[playerIndex]
    local defenderData = combat.playerData[3 - playerIndex]
    
    local result = {
        type = action.type,
        success = false,
        damage = 0,
        healing = 0,
        effects = {},
        blocked = false,
        dodged = false,
        critical = false,
        intentPredicted = false
    }
    
    -- Check intent prediction
    if intentPredictions[defender.UserId] and intentPredictions[defender.UserId].predictedAction == action.type then
        result.intentPredicted = true
        -- Defender gets bonus for correct prediction
        defenderData.combat.currentMana = math.min(defenderData.combat.maxMana, defenderData.combat.currentMana + 50)
    end
    
    -- Process action based on type
    if action.type == "Attack" then
        result = self:ProcessAttack(combat, playerIndex, action, result)
    elseif action.type == "Block" then
        result = self:ProcessBlock(combat, playerIndex, action, result)
    elseif action.type == "Dodge" then
        result = self:ProcessDodge(combat, playerIndex, action, result)
    elseif action.type == "UseSkill" then
        result = self:ProcessSkill(combat, playerIndex, action, result)
    elseif action.type == "Cultivate" then
        result = self:ProcessCultivate(combat, playerIndex, action, result)
    elseif action.type == "EmotionShift" then
        result = self:ProcessEmotionShift(combat, playerIndex, action, result)
    elseif action.type == "GangQiAttack" then
        result = self:ProcessGangQiAttack(combat, playerIndex, action, result)
    end
    
    -- Apply emotion-based modifiers
    self:ApplyEmotionEffects(combat, playerIndex, result)
    
    -- Send result to both players
    for i, player in ipairs(combat.players) do
        RemoteEvents.FireClient("CombatResult", player, {
            turn = combat.turn,
            attacker = playerIndex,
            action = action,
            result = result,
            attackerHealth = attackerData.combat.currentHealth,
            defenderHealth = defenderData.combat.currentHealth
        })
    end
    
    return result
end

function CombatSystem:ProcessAttack(combat, playerIndex, action, result)
    local attackerData = combat.playerData[playerIndex]
    local defenderData = combat.playerData[3 - playerIndex]
    
    -- Calculate base damage
    local baseDamage = GameConstants.COMBAT.BASE_DAMAGE
    
    -- Apply realm modifiers
    local attackerRealm = math.max(attackerData.cultivationRealm, attackerData.martialRealm)
    local defenderRealm = math.max(defenderData.cultivationRealm, defenderData.martialRealm)
    
    baseDamage = baseDamage * (1 + attackerRealm * 0.2)
    
    -- Apply path-specific bonuses
    if attackerData.martialRealm > attackerData.cultivationRealm then
        -- Martial artist - more direct damage
        baseDamage = baseDamage * 1.3
    else
        -- Cultivator - more technique-based
        baseDamage = baseDamage * 1.1
    end
    
    -- Check for critical hit
    local criticalChance = 0.1 + (attackerData.martialArts and attackerData.martialArts.intentMastery or 0) * 0.001
    if math.random() < criticalChance then
        result.critical = true
        baseDamage = baseDamage * GameConstants.COMBAT.CRITICAL_MULTIPLIER
    end
    
    -- Check for dodge
    local dodgeChance = GameConstants.COMBAT.DODGE_CHANCE_BASE + (defenderRealm * 0.01)
    if math.random() < dodgeChance then
        result.dodged = true
        baseDamage = 0
    end
    
    -- Check for block
    if not result.dodged then
        local blockChance = GameConstants.COMBAT.BLOCK_CHANCE_BASE + (defenderRealm * 0.015)
        if math.random() < blockChance then
            result.blocked = true
            baseDamage = baseDamage * 0.3 -- 70% damage reduction
        end
    end
    
    -- Apply damage
    if baseDamage > 0 then
        defenderData.combat.currentHealth = math.max(0, defenderData.combat.currentHealth - baseDamage)
        result.damage = baseDamage
        result.success = true
    end
    
    return result
end

function CombatSystem:ProcessBlock(combat, playerIndex, action, result)
    local playerData = combat.playerData[playerIndex]
    
    -- Blocking restores some stamina and provides defense bonus for next turn
    playerData.combat.currentStamina = math.min(playerData.combat.maxStamina, playerData.combat.currentStamina + 20)
    
    -- Add defense buff
    if not playerData.combat.buffs then
        playerData.combat.buffs = {}
    end
    
    table.insert(playerData.combat.buffs, {
        type = "Defense",
        value = 0.5, -- 50% damage reduction
        duration = 1, -- 1 turn
        source = "Block"
    })
    
    result.success = true
    result.effects = {"Defense buff applied"}
    
    return result
end

function CombatSystem:ProcessDodge(combat, playerIndex, action, result)
    local playerData = combat.playerData[playerIndex]
    
    -- Dodging increases agility for next turn
    if not playerData.combat.buffs then
        playerData.combat.buffs = {}
    end
    
    table.insert(playerData.combat.buffs, {
        type = "Agility",
        value = 0.3, -- 30% dodge chance increase
        duration = 1,
        source = "Dodge"
    })
    
    result.success = true
    result.effects = {"Agility buff applied"}
    
    return result
end

function CombatSystem:ProcessSkill(combat, playerIndex, action, result)
    local playerData = combat.playerData[playerIndex]
    local skillId = action.skillId
    
    -- Check mana cost
    local manaCost = 100 -- Base cost, would vary by skill
    if playerData.combat.currentMana < manaCost then
        result.success = false
        result.effects = {"Insufficient mana"}
        return result
    end
    
    -- Consume mana
    playerData.combat.currentMana = playerData.combat.currentMana - manaCost
    
    -- Apply skill effects based on skillId
    if skillId == "HealingLight" then
        local healAmount = 200
        playerData.combat.currentHealth = math.min(playerData.combat.maxHealth, playerData.combat.currentHealth + healAmount)
        result.healing = healAmount
        result.success = true
    elseif skillId == "QiBlast" then
        local damage = 300
        local defenderData = combat.playerData[3 - playerIndex]
        defenderData.combat.currentHealth = math.max(0, defenderData.combat.currentHealth - damage)
        result.damage = damage
        result.success = true
    end
    
    return result
end

function CombatSystem:ProcessCultivate(combat, playerIndex, action, result)
    local playerData = combat.playerData[playerIndex]
    
    -- Cultivation during combat restores mana and provides qi shield
    local manaRestore = 150
    playerData.combat.currentMana = math.min(playerData.combat.maxMana, playerData.combat.currentMana + manaRestore)
    
    -- Add qi shield
    if not playerData.combat.buffs then
        playerData.combat.buffs = {}
    end
    
    table.insert(playerData.combat.buffs, {
        type = "QiShield",
        value = 200, -- Absorbs 200 damage
        duration = 3,
        source = "Cultivation"
    })
    
    result.success = true
    result.healing = manaRestore
    result.effects = {"Qi shield applied"}
    
    return result
end

function CombatSystem:ProcessEmotionShift(combat, playerIndex, action, result)
    local playerData = combat.playerData[playerIndex]
    local newEmotion = action.emotion
    
    -- Check if player has martial arts training
    if not playerData.martialArts or playerData.martialRealm < 5 then
        result.success = false
        result.effects = {"Requires Three Flowers realm"}
        return result
    end
    
    -- Check emotion mastery
    local emotionMastery = playerData.martialArts.emotionMastery[newEmotion] or 0
    if emotionMastery < 10 then
        result.success = false
        result.effects = {"Insufficient " .. newEmotion .. " mastery"}
        return result
    end
    
    -- Change emotion
    playerData.martialArts.currentEmotion = newEmotion
    
    -- Apply emotion effects
    local emotionEffects = GameConstants.GetEmotionEffects(newEmotion)
    for effect, value in pairs(emotionEffects) do
        if not playerData.combat.buffs then
            playerData.combat.buffs = {}
        end
        
        table.insert(playerData.combat.buffs, {
            type = effect,
            value = value,
            duration = 5, -- 5 turns
            source = "Emotion: " .. newEmotion
        })
    end
    
    result.success = true
    result.effects = {"Emotion changed to " .. newEmotion}
    
    return result
end

function CombatSystem:ProcessGangQiAttack(combat, playerIndex, action, result)
    local playerData = combat.playerData[playerIndex]
    local defenderData = combat.playerData[3 - playerIndex]
    
    -- Check if player can use Gang Qi
    if not playerData.martialArts or playerData.martialRealm < 6 then
        result.success = false
        result.effects = {"Requires Five Energies realm"}
        return result
    end
    
    -- Check internal energy cost
    local energyCost = 200
    if playerData.martialArts.internalEnergy < energyCost then
        result.success = false
        result.effects = {"Insufficient internal energy"}
        return result
    end
    
    -- Consume internal energy
    playerData.martialArts.internalEnergy = playerData.martialArts.internalEnergy - energyCost
    
    -- Calculate Gang Qi damage
    local baseDamage = 400 + (playerData.martialArts.gangQiLevel * 50)
    
    -- Apply emotion modifier
    local currentEmotion = playerData.martialArts.currentEmotion
    local emotionEffects = GameConstants.GetEmotionEffects(currentEmotion)
    if emotionEffects.damage then
        baseDamage = baseDamage * emotionEffects.damage
    end
    
    -- Gang Qi attacks are harder to dodge but can be blocked
    local dodgeChance = GameConstants.COMBAT.DODGE_CHANCE_BASE * 0.5 -- Reduced dodge chance
    if math.random() < dodgeChance then
        result.dodged = true
        baseDamage = 0
    else
        local blockChance = GameConstants.COMBAT.BLOCK_CHANCE_BASE * 1.5 -- Increased block chance
        if math.random() < blockChance then
            result.blocked = true
            baseDamage = baseDamage * 0.4 -- 60% damage reduction
        end
    end
    
    -- Apply damage
    if baseDamage > 0 then
        defenderData.combat.currentHealth = math.max(0, defenderData.combat.currentHealth - baseDamage)
        result.damage = baseDamage
        result.success = true
    end
    
    return result
end

function CombatSystem:ApplyEmotionEffects(combat, playerIndex, result)
    local playerData = combat.playerData[playerIndex]
    
    if not playerData.martialArts or not playerData.martialArts.currentEmotion then
        return
    end
    
    local emotion = playerData.martialArts.currentEmotion
    local emotionEffects = GameConstants.GetEmotionEffects(emotion)
    
    -- Apply emotion-specific modifications to the result
    if emotionEffects.damage and result.damage > 0 then
        result.damage = result.damage * emotionEffects.damage
    end
    
    if emotionEffects.healing and result.healing > 0 then
        result.healing = result.healing * emotionEffects.healing
    end
    
    if emotionEffects.critical and result.critical then
        result.damage = result.damage * emotionEffects.critical
    end
end

function CombatSystem:PredictIntent(player, targetPlayer, predictedAction)
    local userId = player.UserId
    local targetUserId = targetPlayer.UserId
    
    -- Check if both players are in combat together
    local combat = activeCombats[userId]
    if not combat or not activeCombats[targetUserId] or combat ~= activeCombats[targetUserId] then
        return
    end
    
    -- Check if player has intent reading ability
    local gameManager = require(script.Parent.GameManager)
    local playerData = gameManager:GetPlayerData(player)
    
    if not playerData or not playerData.martialArts or playerData.martialRealm < 4 then
        RemoteEvents.FireClient("SystemMessage", player, "Requires Peak Master realm to read intent!")
        return
    end
    
    -- Store intent prediction
    intentPredictions[userId] = {
        target = targetUserId,
        predictedAction = predictedAction,
        timestamp = tick(),
        accuracy = playerData.martialArts.intentMastery / 100
    }
    
    print("Intent prediction:", player.Name, "predicts", targetPlayer.Name, "will use", predictedAction)
    
    RemoteEvents.FireClient("SystemMessage", player, "Intent prediction: " .. predictedAction)
end

function CombatSystem:StartTurn(combat)
    combat.turnStartTime = tick()
    
    local currentPlayer = combat.players[combat.currentPlayer]
    
    -- Notify current player it's their turn
    RemoteEvents.FireClient("CombatTurn", currentPlayer, {
        turn = combat.turn,
        timeLimit = combat.turnTimeLimit,
        availableActions = self:GetAvailableActions(combat, combat.currentPlayer)
    })
    
    -- Notify other player to wait
    local otherPlayer = combat.players[3 - combat.currentPlayer]
    RemoteEvents.FireClient("CombatWait", otherPlayer, {
        turn = combat.turn,
        currentPlayer = currentPlayer.Name
    })
    
    -- Set turn timeout
    spawn(function()
        wait(combat.turnTimeLimit)
        if activeCombats[currentPlayer.UserId] == combat and not combat.ended then
            -- Auto-action for timeout
            self:ProcessCombatAction(currentPlayer, {type = "Block"})
        end
    end)
end

function CombatSystem:NextTurn(combat)
    -- Switch to other player
    combat.currentPlayer = 3 - combat.currentPlayer
    combat.turn = combat.turn + 1
    
    -- Update buffs and debuffs
    self:UpdateEffects(combat)
    
    -- Start next turn
    self:StartTurn(combat)
end

function CombatSystem:UpdateEffects(combat)
    for i, playerData in ipairs(combat.playerData) do
        -- Update buffs
        if playerData.combat.buffs then
            for j = #playerData.combat.buffs, 1, -1 do
                local buff = playerData.combat.buffs[j]
                buff.duration = buff.duration - 1
                if buff.duration <= 0 then
                    table.remove(playerData.combat.buffs, j)
                end
            end
        end
        
        -- Update debuffs
        if playerData.combat.debuffs then
            for j = #playerData.combat.debuffs, 1, -1 do
                local debuff = playerData.combat.debuffs[j]
                debuff.duration = debuff.duration - 1
                if debuff.duration <= 0 then
                    table.remove(playerData.combat.debuffs, j)
                end
            end
        end
    end
end

function CombatSystem:CheckCombatEnd(combat)
    -- Check for player death
    for i, playerData in ipairs(combat.playerData) do
        if playerData.combat.currentHealth <= 0 then
            self:EndCombat(combat, "death", 3 - i) -- Other player wins
            return true
        end
    end
    
    -- Check for turn limit (prevent infinite combat)
    if combat.turn > 100 then
        self:EndCombat(combat, "timeout")
        return true
    end
    
    return false
end

function CombatSystem:EndCombat(combat, reason, winner)
    if combat.ended then
        return
    end
    
    combat.ended = true
    combat.endTime = tick()
    combat.duration = combat.endTime - combat.startTime
    
    local gameManager = require(script.Parent.GameManager)
    
    -- Determine winner and loser
    local winnerPlayer, loserPlayer
    if winner then
        winnerPlayer = combat.players[winner]
        loserPlayer = combat.players[3 - winner]
    end
    
    -- Update player statistics
    for i, player in ipairs(combat.players) do
        local playerData = combat.playerData[i]
        
        if player == winnerPlayer then
            playerData.combat.wins = playerData.combat.wins + 1
            playerData.combat.killStreak = playerData.combat.killStreak + 1
            playerData.resources.reputation = playerData.resources.reputation + 100
        elseif player == loserPlayer then
            playerData.combat.losses = playerData.combat.losses + 1
            playerData.combat.killStreak = 0
            playerData.resources.reputation = math.max(0, playerData.resources.reputation - GameConstants.PVP.REPUTATION_LOSS_ON_DEATH)
        end
        
        playerData.combat.lastCombatTime = tick()
        gameManager:UpdatePlayerData(player, playerData)
    end
    
    -- Clean up combat data
    for _, player in ipairs(combat.players) do
        activeCombats[player.UserId] = nil
    end
    
    print("Combat ended:", combat.players[1].Name, "vs", combat.players[2].Name, "Reason:", reason, "Winner:", winnerPlayer and winnerPlayer.Name or "None")
    
    -- Notify players
    for i, player in ipairs(combat.players) do
        RemoteEvents.FireClient("CombatEnd", player, {
            reason = reason,
            winner = winnerPlayer and winnerPlayer.Name or nil,
            duration = combat.duration,
            turns = combat.turn,
            isWinner = player == winnerPlayer
        })
    end
end

function CombatSystem:Surrender(player)
    local combat = activeCombats[player.UserId]
    if not combat or combat.ended then
        return
    end
    
    local playerIndex = combat.players[1] == player and 1 or 2
    local winner = 3 - playerIndex
    
    self:EndCombat(combat, "surrender", winner)
end

function CombatSystem:GetAvailableActions(combat, playerIndex)
    local playerData = combat.playerData[playerIndex]
    local actions = {"Attack", "Block", "Dodge"}
    
    -- Add cultivation-specific actions
    if playerData.cultivationRealm > 0 then
        table.insert(actions, "Cultivate")
        if playerData.combat.currentMana >= 100 then
            table.insert(actions, "UseSkill")
        end
    end
    
    -- Add martial arts-specific actions
    if playerData.martialRealm > 0 then
        if playerData.martialRealm >= 5 then
            table.insert(actions, "EmotionShift")
        end
        if playerData.martialRealm >= 6 and playerData.martialArts.internalEnergy >= 200 then
            table.insert(actions, "GangQiAttack")
        end
    end
    
    return actions
end

function CombatSystem:GetPublicCombatData(playerData)
    return {
        health = playerData.combat.currentHealth,
        maxHealth = playerData.combat.maxHealth,
        mana = playerData.combat.currentMana,
        maxMana = playerData.combat.maxMana,
        cultivationRealm = playerData.cultivationRealm,
        martialRealm = playerData.martialRealm,
        combatRating = playerData.combat.combatRating,
        currentEmotion = playerData.martialArts and playerData.martialArts.currentEmotion or "Joy"
    }
end

function CombatSystem:GetDisplayRealm(playerData)
    if playerData.cultivationRealm > playerData.martialRealm then
        return GameConstants.CULTIVATION_REALMS[playerData.cultivationRealm].name
    else
        return GameConstants.MARTIAL_REALMS[playerData.martialRealm].name
    end
end

function CombatSystem:IsInSafeZone(player)
    if not player.Character or not player.Character.HumanoidRootPart then
        return true
    end
    
    local position = player.Character.HumanoidRootPart.Position
    
    -- Check distance from spawn points (safe zones)
    local spawnPoints = {
        Vector3.new(0, 0, 0), -- Main spawn
        Vector3.new(1000, 0, 1000), -- Sect areas
        Vector3.new(-1000, 0, 1000),
        Vector3.new(1000, 0, -1000),
        Vector3.new(-1000, 0, -1000)
    }
    
    for _, spawnPoint in ipairs(spawnPoints) do
        local distance = (position - spawnPoint).Magnitude
        if distance <= GameConstants.PVP.SAFE_ZONE_RADIUS then
            return true
        end
    end
    
    return false
end

function CombatSystem:CreateArena(player1, player2)
    -- Create a temporary combat arena
    local arena = {
        center = Vector3.new(0, 100, 0), -- Elevated arena
        radius = 50,
        barriers = true,
        effects = {}
    }
    
    return arena
end

function CombatSystem:UpdateCombatStats(player, playerData)
    -- Calculate combat stats based on realm and path
    local baseHealth = 1000
    local baseMana = 500
    
    -- Cultivation bonuses
    if playerData.cultivationRealm > 0 then
        local realmInfo = GameConstants.CULTIVATION_REALMS[playerData.cultivationRealm]
        if realmInfo then
            baseMana = baseMana + (realmInfo.maxQi * 0.5)
            baseHealth = baseHealth + (playerData.cultivationRealm * 200)
        end
    end
    
    -- Martial arts bonuses
    if playerData.martialRealm > 0 then
        baseHealth = baseHealth + (playerData.martialRealm * 300)
        -- Martial artists have less mana but more health
        baseMana = baseMana + (playerData.martialRealm * 50)
    end
    
    -- Update combat stats
    playerData.combat.maxHealth = baseHealth
    playerData.combat.maxMana = baseMana
    
    -- Ensure current values don't exceed max
    playerData.combat.health = math.min(playerData.combat.health or baseHealth, baseHealth)
    playerData.combat.mana = math.min(playerData.combat.mana or baseMana, baseMana)
end

function CombatSystem:Update(deltaTime)
    -- Update DoT effects
    self:UpdateDotEffects(deltaTime)
    
    -- Clean up expired invitations
    self:CleanupInvitations()
    
    -- Update active combats (for any real-time effects)
    for userId, combat in pairs(activeCombats) do
        if not combat.ended then
            -- Check for disconnected players
            local allConnected = true
            for _, player in ipairs(combat.players) do
                if not player.Parent then
                    allConnected = false
                    break
                end
            end
            
            if not allConnected then
                self:EndCombat(combat, "disconnect")
            end
        end
    end
end

function CombatSystem:UpdateDotEffects(deltaTime)
    for userId, effects in pairs(dotEffects) do
        local player = game.Players:GetPlayerByUserId(userId)
        if player then
            local gameManager = require(script.Parent.GameManager)
            local playerData = gameManager:GetPlayerData(player)
            
            if playerData then
                for i = #effects, 1, -1 do
                    local effect = effects[i]
                    effect.nextTick = effect.nextTick - deltaTime
                    
                    if effect.nextTick <= 0 then
                        -- Apply effect
                        if effect.type == "poison" then
                            playerData.combat.currentHealth = math.max(0, playerData.combat.currentHealth - effect.damage)
                        elseif effect.type == "regeneration" then
                            playerData.combat.currentHealth = math.min(playerData.combat.maxHealth, playerData.combat.currentHealth + effect.healing)
                        end
                        
                        effect.duration = effect.duration - 1
                        effect.nextTick = 1.0 -- Reset tick timer
                        
                        if effect.duration <= 0 then
                            table.remove(effects, i)
                        end
                    end
                end
                
                if #effects == 0 then
                    dotEffects[userId] = nil
                end
            end
        else
            dotEffects[userId] = nil
        end
    end
end

function CombatSystem:CleanupInvitations()
    local currentTime = tick()
    
    for combatId, invitation in pairs(combatInvitations) do
        if currentTime - invitation.timestamp > invitation.timeout then
            combatInvitations[combatId] = nil
        end
    end
end

return CombatSystem

