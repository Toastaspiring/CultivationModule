# How to Run the Tests

This document explains how to run the tests for the Cultivation Game in Roblox Studio.

## Prerequisites

*   You have [Roblox Studio](https://www.roblox.com/create) installed.
*   You have [Rojo](https://rojo.space/) installed and configured for your project.

## Steps

1.  **Sync with Roblox Studio:**
    *   Open your project in your code editor.
    *   Run the Rojo CLI to serve the project:
        ```bash
        rojo serve
        ```
    *   Open your place in Roblox Studio.
    *   In the **Plugins** tab, click on **Rojo** and then **Connect**. This will sync your project files into the game.

2.  **Find the Test Scripts:**
    *   **Server-side tests:** In the Roblox Studio **Explorer** window, navigate to `ServerScriptService`. You will find a script named `TestRunner.spec`.
    *   **Client-side tests:** In the Roblox Studio **Explorer** window, navigate to `StarterPlayer > StarterPlayerScripts`. You will find a `LocalScript` named `ClientTestRunner.spec`.

3.  **Run the Tests:**
    *   The test scripts are set to run automatically when the game starts.
    *   To run the tests, simply start a new server or play the game in Studio by clicking the **Play** button.
    *   The test results will be printed to the **Output** window.

## Viewing the Output

To view the test results, you need to have the **Output** window open in Roblox Studio.

*   Go to the **View** tab.
*   Click on **Output** to open the Output window.

You will see two sets of test results:
*   **Server test results:** These will be printed from the `TestRunner.spec` script and will be visible in the server's output view.
*   **Client test results:** These will be printed from the `ClientTestRunner.spec` script and will be visible in the client's output view. You may need to switch the output view from "Server" to "Client" to see them.
