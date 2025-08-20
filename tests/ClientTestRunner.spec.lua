--[[
    ClientTestRunner.spec.lua
    A simple, from-scratch test runner for the client-side modules of the Cultivation Game.
]]

-- A simple testing framework
local TestRunner = {}
TestRunner.results = {
    passed = 0,
    failed = 0,
    total = 0,
    tests = {}
}

local function describe(description, func)
    print("--------------------------------")
    print("CLIENT DESCRIBE: " .. description)
    func()
    print("--------------------------------")
end

local function it(description, func)
    TestRunner.results.total = TestRunner.results.total + 1
    local success, err = pcall(func)
    if success then
        TestRunner.results.passed = TestRunner.results.passed + 1
        print("  PASSED: " .. description)
        table.insert(TestRunner.results.tests, {
            name = description,
            status = "Passed"
        })
    else
        TestRunner.results.failed = TestRunner.results.failed + 1
        warn("  FAILED: " .. description)
        warn("    " .. tostring(err))
        table.insert(TestRunner.results.tests, {
            name = description,
            status = "Failed",
            error = tostring(err)
        })
    end
end

local function expect(value)
    local self = {}

    function self.toEqual(expected)
        if value ~= expected then
            error("Expected " .. tostring(value) .. " to equal " .. tostring(expected))
        end
    end

    function self.toBe(expected)
        if value ~= expected then
            error("Expected " .. tostring(value) .. " to be " .. tostring(expected))
        end
    end

    function self.toBeTruthy()
        if not value then
            error("Expected " .. tostring(value) .. " to be truthy")
        end
    end

    function self.toBeFalsy()
        if value then
            error("Expected " .. tostring(value) .. " to be falsy")
        end
    end

    function self.toBeGreaterThan(expected)
        if value <= expected then
            error("Expected " .. tostring(value) .. " to be greater than " .. tostring(expected))
        end
    end

    return self
end


-- Run tests
function TestRunner.run()
    print("Starting client-side tests...")

    local ClientManager = require(script.Parent.Parent.Client.ClientManager)

    -- ClientManager Tests
    describe("ClientManager", function()
        it("should initialize correctly", function()
            ClientManager.Initialize()
            local stats = ClientManager.GetClientStats()
            expect(stats.isInitialized).toBeTruthy()
        end)

        it("should set and get player data", function()
            local playerData = { name = "TestPlayer", level = 1 }
            ClientManager.SetPlayerData(playerData)
            expect(ClientManager.GetPlayerData()).toEqual(playerData)
        end)

        it("should register and get UI elements", function()
            local uiElement = {}
            ClientManager.RegisterUIElement("TestUI", uiElement)
            expect(ClientManager.GetUIElement("TestUI")).toEqual(uiElement)
        end)

        it("should set and check interface active state", function()
            ClientManager.SetInterfaceActive("TestInterface", true)
            expect(ClientManager.IsInterfaceActive("TestInterface")).toBeTruthy()
            ClientManager.SetInterfaceActive("TestInterface", false)
            expect(ClientManager.IsInterfaceActive("TestInterface")).toBeFalsy()
        end)
    end)

    -- Print summary
    print("\n--------------------------------")
    print("Client Test Results:")
    print("  Passed: " .. TestRunner.results.passed)
    print("  Failed: " .. TestRunner.results.failed)
    print("  Total:  " .. TestRunner.results.total)
    print("--------------------------------")
end

TestRunner.run()

return TestRunner
