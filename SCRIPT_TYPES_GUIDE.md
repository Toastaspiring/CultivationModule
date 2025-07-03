# Roblox Script Types Guide

## 🎯 Understanding Script Types in Roblox

This guide explains the three types of scripts in Roblox and how they're used in the Cultivation Game project.

## 📜 Script Types Overview

### 1. Script (Server Script)
- **Runs on:** Server only
- **Purpose:** Server-side game logic
- **Location:** ServerScriptService, ServerStorage, Workspace
- **Can access:** Server-side services, all players, DataStores
- **Cannot access:** Player's GUI, local input

### 2. LocalScript
- **Runs on:** Client only (each player's device)
- **Purpose:** Client-side UI and input handling
- **Location:** StarterPlayerScripts, StarterGui, PlayerGui
- **Can access:** Player's GUI, local input, camera
- **Cannot access:** Other players' data directly, DataStores

### 3. ModuleScript
- **Runs on:** Neither (must be required by other scripts)
- **Purpose:** Shared code libraries and functions
- **Location:** Anywhere (ReplicatedStorage for shared, ServerScriptService for server-only)
- **Can access:** Depends on where it's required from
- **Cannot access:** Nothing directly (inherits from requiring script)

## 🏗️ How They Work Together

```
Server (Script) ←→ RemoteEvents ←→ Client (LocalScript)
       ↓                                    ↓
   ModuleScripts                      ModuleScripts
```

## 🎮 Cultivation Game Implementation

### Server-Side Structure:
```
ServerScriptService/
├── ServerMain.lua (Script) ← Main launcher
├── GameManager.lua (ModuleScript) ← Game logic
├── PlayerDataManager.lua (ModuleScript) ← Data handling
└── ... other systems (ModuleScripts)
```

### Client-Side Structure:
```
StarterPlayerScripts/
├── ClientMain.lua (LocalScript) ← Main launcher
├── ClientManager.lua (ModuleScript) ← Client logic
└── UI/ (ModuleScripts) ← UI components
```

### Shared Structure:
```
ReplicatedStorage/
└── Shared/
    ├── GameConstants.lua (ModuleScript) ← Shared constants
    └── RemoteEvents.lua (ModuleScript) ← Communication
```

## 🔧 Script Creation in Roblox Studio

### Creating a Script:
1. Right-click in ServerScriptService
2. Insert → Script
3. Rename to desired name
4. Paste server code

### Creating a LocalScript:
1. Right-click in StarterPlayerScripts
2. Insert → LocalScript
3. Rename to desired name
4. Paste client code

### Creating a ModuleScript:
1. Right-click in desired location
2. Insert → ModuleScript
3. Rename to desired name
4. Paste module code

## ⚠️ Common Mistakes

### ❌ Wrong Script Type:
```lua
-- DON'T: Put server logic in LocalScript
local DataStoreService = game:GetService("DataStoreService") -- Won't work!

-- DON'T: Put client UI in Script
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui") -- Won't work!
```

### ✅ Correct Usage:
```lua
-- Server Script: Handle data
local DataStoreService = game:GetService("DataStoreService") -- ✓ Works

-- LocalScript: Handle UI
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui") -- ✓ Works
```

### ❌ ModuleScript Execution:
```lua
-- DON'T: Try to run ModuleScript directly
-- ModuleScripts don't execute on their own!
```

### ✅ Correct ModuleScript Usage:
```lua
-- In Script or LocalScript:
local MyModule = require(path.to.ModuleScript) -- ✓ Correct
MyModule.Initialize() -- ✓ Call module functions
```

## 🚀 Execution Flow in Cultivation Game

### 1. Server Startup:
```
1. ServerMain.lua (Script) starts automatically
2. Requires all ModuleScript systems
3. Calls Initialize() on each system
4. Sets up player event handlers
5. Starts main game loop
```

### 2. Client Startup (per player):
```
1. ClientMain.lua (LocalScript) starts when player joins
2. Requires UI ModuleScripts
3. Creates player interface
4. Sets up input handling
5. Connects to server via RemoteEvents
```

### 3. Communication:
```
Client Input → LocalScript → RemoteEvent → Server Script → ModuleScript Logic
Server Update → ModuleScript → RemoteEvent → LocalScript → UI Update
```

## 🔍 Debugging Script Types

### Check Script Type:
```lua
-- In any script:
print("Script type:", script.ClassName)
-- Output: "Script", "LocalScript", or "ModuleScript"
```

### Check Execution Context:
```lua
-- Server-side check:
if game:GetService("RunService"):IsServer() then
    print("Running on server")
end

-- Client-side check:
if game:GetService("RunService"):IsClient() then
    print("Running on client")
end
```

## 📋 Quick Reference

| Need to... | Use... | Location |
|------------|--------|----------|
| Handle player data | Script | ServerScriptService |
| Create UI | LocalScript | StarterPlayerScripts |
| Share code | ModuleScript | ReplicatedStorage |
| Server game logic | Script + ModuleScripts | ServerScriptService |
| Client input | LocalScript + ModuleScripts | StarterPlayerScripts |
| Constants/Config | ModuleScript | ReplicatedStorage |

## 🎯 Best Practices

### 1. Separation of Concerns:
- **Scripts:** Main launchers and event handlers
- **ModuleScripts:** Actual game logic and systems
- **LocalScripts:** UI and input handling

### 2. Error Handling:
```lua
-- Always wrap in pcall for production
local success, result = pcall(function()
    return require(ModuleScript).Initialize()
end)

if not success then
    warn("Failed to initialize:", result)
end
```

### 3. Module Structure:
```lua
-- Good ModuleScript structure:
local MyModule = {}

function MyModule.Initialize()
    -- Setup code
end

function MyModule.Update()
    -- Update logic
end

function MyModule.Cleanup()
    -- Cleanup code
end

return MyModule
```

This structure ensures your Cultivation Game will run properly in Roblox Studio! 🌟

