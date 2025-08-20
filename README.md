# Cultivation Game Template for Roblox

## Overview

The Cultivation Game Template provides a robust and flexible foundation for creating Roblox games inspired by Chinese cultivation (Xianxia) or martial arts themes.  
This project includes modular systems that are fully customizable, allowing developers to focus on building unique stories, mechanics, and environments without starting from scratch.  

The template is data-driven. All core configuration is centralized in `GameConstants.lua`, enabling broad design changes without modifying system logic.

---

## Project Structure

This project is configured for use with [Rojo](https://rojo.space), a development tool that integrates professional workflows into Roblox Studio.

```
CultivationGameTemplate/
├── src/
│   ├── server/                     # Server-side systems
│   │   ├── ServerMain.lua            -- Main server entry point
│   │   └── ...
│   │
│   ├── client/                     # Client-side systems and UI
│   │   ├── ClientMain.lua            -- Main client entry point
│   │   └── ...
│   │
│   └── shared/                     # Shared modules
│       ├── GameConstants.lua         -- Core configuration file
│       └── RemoteEvents.lua          -- Client-server communication
│
└── default.project.json            # Rojo project configuration
```

---

## Getting Started

### Step 1: Install Tools
- Install [Aftman](https://github.com/LPGhatguy/aftman)  
- Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/)  

This project is pre-configured for Rojo 7.

### Step 2: Sync with Roblox Studio
1. Open Roblox Studio and load your place file.  
2. From the project root, run:
   ```powershell
   rojo serve
   ```
3. In Studio, open **Plugins > Rojo > Connect** to synchronize source files.

### Step 3: Enable API Services
- In Studio, go to **Game Settings > Security**.  
- Enable **Allow HTTP Requests**.  
- Enable **Enable Studio Access to API Services** (required for DataStores).

### Step 4: Test
- Click **Play** in Studio.  
- Use the Output window to verify initialization.

---

## Customization

### GameConstants.lua
The `GameConstants.lua` file defines most aspects of gameplay and progression.

- **Progression Paths**: Configure cultivation paths, martial arts routes, realms, lifespans, and resource caps.  
- **Talents and Bloodlines**: Create unique bonuses and restrictions.  
- **Resources and Items**: Define currencies, crafting materials, and consumables.  
- **System Balancing**: Adjust cultivation speed, martial training, breakthrough chances, tribulation difficulty, economy, and PVP rules.  

### Lore Integration
Refer to `Documentation/LORE_GUIDE.md` for guidance on writing realm descriptions, defining cultural context, and embedding story elements.

---

## Technical Notes

- **Server Logic**: Centralized in `ServerMain.lua`.  
- **Client Logic**: Managed by `ClientMain.lua`.  
- **Data-Driven Architecture**: Systems read directly from `GameConstants.lua`, enabling rapid iteration without refactoring core modules.  

---

## License

This template is released under the MIT License. You are free to use, modify, and distribute it in your own projects.

---

## Contributing

Contributions and suggestions are welcome. Please submit issues and pull requests via GitHub.
