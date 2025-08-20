# How to Integrate Your Lore and World-Building

This guide will help you bring your unique cultivation world to life using this template. The key to a memorable game is a rich and consistent world. This document provides tips on how to integrate your lore into the game's mechanics.

## 1. The Foundation: `GameConstants.lua`

Almost all the text that players will see is defined in `ReplicatedStorage/GameConstants.lua`. As you build your world, you should constantly refer back to this file to update the names and descriptions of your game's elements.

### Progression Paths and Realms

In the `PROGRESSION_PATHS` table, you have the power to define the journey your players will take.

-   **`Name`**: This is the name of the progression path itself (e.g., "The Way of the Ascendant", "Path of the Iron Body").
-   **`Realms`**: Each realm within a path has a `name` and a `description`.
    -   **Good Name:** "Qi Condensation"
    -   **Good Description:** "The first step on the path to immortality, where a cultivator learns to sense and gather the world's spiritual energy into their body."
    -   **Bad Description:** "Level 2"

Use the descriptions to tell a story about what it means to be at that level of power. What new abilities does the player have? How are they perceived by others in the world?

### Items and Resources

Give your resources and items names that fit your world's theme.

-   Instead of "Spirit Stones," maybe your world uses "Soul Crystals" or "Essence Shards."
-   Instead of "Spirit Grass," perhaps a "Sunpetal Herb" or "Moon-Kissed Root."

The descriptions for these items are a great place for lore. A simple herb's description could be:
> "A common herb that grows in areas with dense spiritual energy. It is said to be a favorite food of the Whispering Spirit Vole."

This adds flavor and makes your world feel more alive.

## 2. Writing for Your World

As you fill out `GameConstants.lua`, keep these principles in mind:

-   **Consistency**: Ensure your naming conventions and themes are consistent. If your world is based on ancient Chinese mythology, use names and concepts from that tradition. If it's a more modern take on cultivation, your language can be more contemporary.
-   **Show, Don't Just Tell**: Instead of saying a realm is "powerful," describe what a person in that realm can do. Can they shatter mountains? Can they communicate with spirits? Can they live for a thousand years?
-   **Connect to Gameplay**: Your lore should have a tangible impact on the game. If you write that a certain bloodline is descended from dragons, this should be reflected in their abilities (e.g., a bonus to fire techniques or higher innate prestige).

## 3. Creating a World Bible (Optional but Recommended)

For larger projects, it's a good idea to create your own "World Bible" – a separate document where you detail your world's history, geography, major factions, and key figures.

Your World Bible could include:

-   A map of your world.
-   The history of the major sects or kingdoms.
-   The creation myth of your universe.
-   Profiles of legendary cultivators from the past.
-   The unique laws of cultivation in your world (e.g., are there specific elements? Is cultivation a public or secret practice?).

While this information might not all go directly into the game, it will help you maintain consistency and provide a deep well of ideas for future content, quests, and events.

## 4. Where to Go From Here

Once you have customized `GameConstants.lua` and have a good sense of your world's lore, you can start thinking about:

-   **Quests**: Design quests that introduce players to your world's history and conflicts.
-   **NPCs**: Create non-player characters who have their own stories and perspectives on the world.
-   **Visuals**: Design a map, user interface, and character models that reflect your world's aesthetic.

By thoughtfully integrating your lore into the template, you can transform this set of systems into a unique and immersive gaming experience.
