# Generic Cultivation Game Template for Roblox

## 🌟 Overview

Welcome to the Generic Cultivation Game Template! This Roblox Studio project provides a flexible and powerful foundation for creating your own Chinese cultivation (Xianxia) or martial arts game. The systems are designed to be highly customizable, allowing you to focus on your game's unique story, world, and mechanics without starting from scratch.

The core of this template is the `GameConstants.lua` file, which acts as a central configuration hub for almost every aspect of the game.

## 📁 Project Structure

The project follows standard Roblox conventions:

```
CultivationGameTemplate/
├── ServerScriptService/           # Core server-side systems
│   ├── ServerMain.lua             -- Main server launcher (Script)
│   ├── GameManager.lua            -- Handles game state and systems
│   ├── PlayerDataManager.lua      -- Manages player data and persistence
│   ├── CultivationSystem.lua      -- Manages the primary progression path
│   └── MartialArtsSystem.lua      -- Manages the secondary progression path
│
├── ReplicatedStorage/
│   └── Shared/
│       ├── GameConstants.lua      -- ⭐ YOUR PRIMARY CONFIGURATION FILE ⭐
│       └── RemoteEvents.lua       -- Handles client-server communication
│
├── StarterPlayerScripts/          # Client-side logic and UI
│   ├── ClientMain.lua             -- Main client launcher (LocalScript)
│   └── ClientManager.lua          -- Manages client-side systems and UI
│
└── Documentation/
    └── LORE_GUIDE.md              -- A guide to help you integrate your own lore
```

## 🚀 Getting Started: Customizing Your Game

The most important file for you to edit is `ReplicatedStorage/Shared/GameConstants.lua`. This file contains all the core data and balance settings for your game.

### Step 1: Define Progression Paths

Open `GameConstants.lua` and find the `PROGRESSION_PATHS` table. Here you can:
- Define the names of your cultivation or martial arts paths (e.g., "Immortal Path", "Way of the Sword").
- Add, remove, or rename the realms/levels for each path.
- Set the `lifespan` and `maxResource` for each realm.

### Step 2: Configure Talents and Traits

In the `TALENTS` and `BLOODLINES` tables, you can:
- Define different tiers of talent for your progression paths.
- Create unique bloodlines with custom bonuses and restrictions.

### Step 3: Customize Items and Resources

In the `RESOURCES` and `ITEMS` tables, you can:
- Rename primary resources like "Qi" and "Spirit Stones".
- Create your own herbs, pills, and other items with custom effects and crafting recipes.

### Step 4: Balance Game Systems

The `GAME SYSTEMS CONFIGURATION` section allows you to fine-tune the mechanics:
- **`CULTIVATION`**: Adjust the speed and efficiency of training, set time-of-day bonuses.
- **`MARTIAL_ARTS`**: Configure the secondary progression path's training mechanics.
- **`PROGRESSION`**: Change experience requirements and breakthrough chances.
- **`TRIBULATIONS`**: Customize the difficulty and rewards of breakthrough challenges.
- **`WORLD_NODES`**: Define the locations and bonuses of resource hotspots in your world.
- **`SECTS`**, **`WORLD_EVENTS`**, **`ECONOMY`**, **`PVP`**: Configure all other aspects of your game.

### Step 5: Integrate Your Lore

Read the `Documentation/LORE_GUIDE.md` for tips on how to bring your world to life. This includes writing descriptions for your realms, items, and creating a unique history for your game world.

## 🔧 Setup in Roblox Studio

1.  **Import the Files**: Copy the folders (`ServerScriptService`, `ReplicatedStorage`, etc.) into your Roblox Studio project.
2.  **Enable API Services**:
    -   Go to `Game Settings > Security`.
    -   Enable `Allow HTTP Requests`.
    -   Enable `Enable Studio Access to API Services`. This is required for DataStores to work.
3.  **Test**: Click "Play" in Studio to test the template. Use the Output window to check for any initialization errors.

## 🎮 How It Works

-   **Server-Side Logic**: All major game systems run on the server for security and scalability. `ServerMain.lua` initializes all the system modules.
-   **Client-Side Logic**: `ClientMain.lua` initializes the client-side managers, which handle UI and communication with the server.
-   **Data-Driven Design**: The game systems are designed to pull their configuration from `GameConstants.lua`. This means you can make significant changes to your game without needing to edit the core system scripts.

Happy developing!
