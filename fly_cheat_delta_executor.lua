-- ============================================
-- FLY CHEAT FOR ROBLOX DELTA EXECUTOR (MOBILE)
-- ============================================
-- Usage: Copy this entire script into Delta Executor's script editor or console
-- Toggle with 't' key or use the toggle button in UI
-- ============================================

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
local RootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")

-- Configuration
local Config = {
    FlyEnabled = false,
    FlySpeed = 15, -- Vertical speed (adjust as needed)
    FlyHeightLimit = 200, -- Max height before auto-descent
    ToggleKey = Enum.KeyCode.T, -- Key to toggle fly mode
    AutoDescent = true, -- Enable/disable automatic descent at max height
}

-- Variables
local isFlying = false
local lastTouchY = 0
local touchStartTime = 0
local touchDuration = 0.5 -- Minimum touch duration for activation

-- ============================================
-- MAIN FLY FUNCTION
-- ============================================
local function FlyLoop()
    if not Humanoid or not RootPart then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Check if fly is enabled
    if Config.FlyEnabled and isFlying then
        -- Get touch input for vertical movement
        local currentTouchY = UserInputService.TouchPosition.Y
        
        -- Calculate vertical velocity based on touch drag
        local deltaY = lastTouchY - currentTouchY
        local targetVelocity = Config.FlySpeed * (deltaY / 10)
        
        -- Apply upward force
        RootPart.Velocity = Vector3.new(0, targetVelocity, 0)
        
        -- Update last touch position
        lastTouchY = currentTouchY
        
        -- Auto-descent check
        if Config.AutoDescent and (RootPart.Position.Y > Config.FlyHeightLimit) then
            local descentSpeed = 10
            RootPart.Velocity = Vector3.new(0, -descentSpeed, 0)
        end
    else
        -- Reset velocity when fly is disabled
        if not isFlying and lastTouchY ~= 0 then
            RootPart.Velocity = Vector3.zero()
            lastTouchY = 0
        end
    end
    
    task.wait(1/60) -- Run every frame (approx 60 FPS)
end

-- ============================================
-- TOGGLE FUNCTION
-- ============================================
local function OnToggleFly()
    isFlying = not isFlying
    Config.FlyEnabled = isFlying
    
    if isFlying then
        print("[FLY] Enabled - Touch and drag up/down to fly")
        lastTouchY = UserInputService.TouchPosition.Y
    else
        print("[FLY] Disabled")
        RootPart.Velocity = Vector3.zero()
        lastTouchY = 0
    end
    
    -- Visual feedback (optional)
    if isFlying then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            rootPart.BrickColor = BrickColor.new("Bright red")
            task.wait(0.5)
            rootPart.BrickColor = BrickColor.Random() -- Restore random color
        end
    end
end

-- ============================================
-- KEYBOARD TOGGLE BINDING
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not isFlying and input.KeyCode == Config.ToggleKey then
        OnToggleFly()
    end
end)

-- ============================================
-- TOUCH CONTROL (MOBILE FRIENDLY)
-- ============================================
UserInputService.TouchEnded:Connect(function(input, position, pointerIndex, gameProcessed)
    -- Check if touch was on screen and within duration
    if input.UserPointerIndex == 1 then -- Primary finger
        local currentTime = tick()
        
        -- If touched recently, calculate velocity
        if (currentTime - touchStartTime) < touchDuration then
            local currentTouchY = UserInputService.TouchPosition.Y
            local deltaY = lastTouchY - currentTouchY
            
            -- Apply immediate upward force on release
            if Config.FlyEnabled and isFlying then
                RootPart.Velocity = Vector3.new(0, Config.FlySpeed * (deltaY / 5), 0)
            end
        end
        
        touchStartTime = currentTime
    end
    
    lastTouchY = position.Y
end)

-- ============================================
-- TOUCH START TRACKING
-- ============================================
UserInputService.TouchStarted:Connect(function(input, position, pointerIndex, gameProcessed)
    if input.UserPointerIndex == 1 then -- Primary finger
        touchStartTime = tick()
        lastTouchY = position.Y
    end
end)

-- ============================================
-- AUTO-TOGGLE ON TOUCH (OPTIONAL - UNCOMMENT TO ENABLE)
-- ============================================
--[[
UserInputService.TouchMoved:Connect(function(input, position, pointerIndex, gameProcessed)
    if input.UserPointerIndex == 1 and Config.FlyEnabled then
        local currentTouchY = UserInputService.TouchPosition.Y
        local deltaY = lastTouchY - currentTouchY
        
        -- Auto-toggle fly on touch movement
        isFlying = true
        Config.FlyEnabled = true
        
        RootPart.Velocity = Vector3.new(0, Config.FlySpeed * (deltaY / 10), 0)
        
        lastTouchY = currentTouchY
    end
end)
]]

-- ============================================
-- INITIAL SETUP
-- ============================================
print("[FLY CHEAT] Loaded successfully!")
print("[FLY CHEAT] Press '" .. Config.ToggleKey.Name .. "' to toggle fly mode")
print("[FLY CHEAT] Or touch and drag on screen for mobile control")
print("[FLY CHEAT] Current Speed: " .. Config.FlySpeed)

-- Start the main loop
task.spawn(FlyLoop)

-- ============================================
-- CONFIGURATION MODIFIER (OPTIONAL SCRIPTS)
-- ============================================
--[[
-- To change fly speed, add this to your script or use in console:
-- game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 25, 0)

-- To disable auto-descent:
-- Config.AutoDescent = false

-- To change toggle key:
-- Config.ToggleKey = Enum.KeyCode.F12
]]

return {
    FlyEnabled = Config.FlyEnabled,
    OnToggleFly = OnToggleFly,
    FlySpeed = Config.FlySpeed,
}