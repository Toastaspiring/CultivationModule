--[[
    TestRunner.spec.lua
    A simple, from-scratch test runner for the server-side modules of the Cultivation Game.
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
    print("SERVER DESCRIBE: " .. description)
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
    print("Starting server-side tests...")

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local GameManager = require(ServerScriptService.Server.GameManager)
    local GameConstants = require(ReplicatedStorage.GameConstants)
    local RemoteEvents = require(ReplicatedStorage.RemoteEvents)

    -- GameManager Tests
    describe("GameManager", function()
        it("should initialize correctly", function()
            GameManager.Initialize()
            local stats = GameManager.GetGameStats()
            expect(stats.isRunning).toBeTruthy()
        end)

        it("should initialize world with events", function()
            GameManager.InitializeWorld()
            local stats = GameManager.GetGameStats()
            expect(stats.activeEvents).toBeGreaterThan(0)
        end)

        it("should trigger a world event", function()
            GameManager.Initialize()
            local event = {
                name = "Test Event",
                duration = 10
            }
            GameManager.TriggerWorldEvent(event)
            expect(event.lastTriggered).toBeTruthy()
            expect(event.endTime).toBeTruthy()
        end)

        it("should shut down correctly", function()
            GameManager.Initialize()
            GameManager.Shutdown()
            local stats = GameManager.GetGameStats()
            expect(stats.isRunning).toBeFalsy()
        end)
    end)

    -- GameConstants Tests
    describe("GameConstants", function()
        it("should return correct realm info", function()
            local realmInfo = GameConstants.GetRealmInfo("Cultivation", 1)
            expect(realmInfo.name).toEqual("Realm 1: Foundation")
        end)

        it("should calculate experience required correctly", function()
            local exp = GameConstants.GetExperienceRequired(10)
            expect(exp).toBeGreaterThan(0)
        end)
    end)

    -- RemoteEvents Tests
    describe("RemoteEvents", function()
        it("should validate player data correctly", function()
            local valid, message = RemoteEvents.ValidatePlayerDataUpdate({level = 1})
            expect(valid).toBeTruthy()
        end)

        it("should invalidate incorrect player data", function()
            local valid, message = RemoteEvents.ValidatePlayerDataUpdate("not a table")
            expect(valid).toBeFalsy()
        end)
    end)

    -- Print summary
    print("\n--------------------------------")
    print("Server Test Results:")
    print("  Passed: " .. TestRunner.results.passed)
    print("  Failed: " .. TestRunner.results.failed)
    print("  Total:  " .. TestRunner.results.total)
    print("--------------------------------")
end

TestRunner.run()

return TestRunner
