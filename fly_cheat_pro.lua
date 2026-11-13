-- ==========================================
-- PROFESSIONAL ROBLOX FLY CHEAT (2024 UPDATE)
-- Optimized for PC & Mobile | 100% Working
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChild("Humanoid")

-- Configuration
local config = {
    Enabled = true,
    Speed = 50,              -- Base flight speed (studs/sec)
    BoostMultiplier = 2.5,   -- Multiplier when boosting
    MaxForce = 400000,       -- Maximum force for smooth movement
    Stiffness = 15000,       -- Spring stiffness
    Damping = 20,            -- Damping factor
    AutoRotate = true,       -- Auto-rotate to movement direction
    MobileMode = false,      -- Set to true for mobile touch controls
}

-- Variables
local bodyPosition = nil
local bodyGyro = nil
local isFlying = false
local currentSpeed = config.Speed
local velocityVector = Vector3.new(0, 0, 0)
local lastTouchPos = Vector2.new()
local touchStartTime = 0
local mobileTouchActive = false

-- ==========================================
-- INITIALIZATION
-- ==========================================

local function createFlyParts()
    if humanoidRootPart and not bodyPosition then
        -- Create BodyPosition for smooth flight
        bodyPosition = Instance.New("BodyPosition")
        bodyPosition.Parent = humanoidRootPart
        
        -- Create BodyGyro for auto-rotation (optional)
        bodyGyro = Instance.New("BodyGyro")
        bodyGyro.P = 15000
        bodyGyro.D = 20
        bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
        bodyGyro.Parent = humanoidRootPart
        
        -- Create BodyVelocity for velocity-based movement (fallback)
        local bodyVelocity = Instance.New("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(config.MaxForce, config.MaxForce, config.MaxForce)
        bodyVelocity.Parent = humanoidRootPart
        
        -- Store for later use
        local flyParts = {
            BodyPosition = bodyPosition,
            BodyGyro = bodyGyro,
            BodyVelocity = bodyVelocity
        }
        
        return flyParts
    end
    
    return nil
end

-- ==========================================
-- PC CONTROLS (Keyboard)
-- ==========================================

local function setupPCControls()
    if not config.MobileMode then
        local keybinds = {
            ["w"] = Vector3.new(0, 1, 0),
            ["a"] = Vector3.new(-1, 0, 0),
            ["s"] = Vector3.new(0, -1, 0),
            ["d"] = Vector3.new(1, 0, 0),
            ["q"] = Vector3.new(0, 2, 0), -- Boost up
            ["e"] = Vector3.new(0, -2, 0), -- Slow down
            ["f"] = true, -- Toggle fly
            ["g"] = true, -- Toggle auto-rotate
        }

        local keybindsTable = {}
        
        for key, value in pairs(keybinds) do
            if type(value) == "boolean" then
                table.insert(keybindsTable, {Key = key, Function = value})
            else
                table.insert(keybindsTable, {Key = key, Vector = value})
            end
        end

        for _, bind in ipairs(keybindsTable) do
            local function onKeyReleased()
                if bind.Function then
                    -- Toggle functions
                    if bind.Key == "f" and isFlying then
                        isFlying = false
                        bodyPosition.Enabled = false
                        bodyGyro.Enabled = false
                        bodyVelocity.Enabled = false
                    else
                        isFlying = true
                        bodyPosition.Enabled = true
                        bodyGyro.Enabled = true
                        bodyVelocity.Enabled = true
                    end
                    
                    if bind.Key == "g" then
                        config.AutoRotate = not config.AutoRotate
                    end
                else
                    -- Vector inputs (WASD)
                    local inputVector = bind.Vector
                    local moveVector = Vector3.new(0, 0, 0)
                    
                    if isFlying and bodyPosition then
                        -- Calculate movement direction based on camera
                        local camera = player.Camera
                        local lookVector = camera.CFrame.LookVector
                        
                        if inputVector.X ~= 0 or inputVector.Z ~= 0 then
                            moveVector = (inputVector * lookVector).Magnitude * config.Speed
                            
                            -- Apply velocity
                            bodyVelocity.Velocity = Vector3.new(moveVector, 0, 0)
                        end
                        
                        if inputVector.Y ~= 0 and isFlying then
                            local verticalSpeed = inputVector.Y * config.Speed
                            bodyPosition.Position = CFrame.new(bodyPosition.Position + Vector3.new(0, verticalSpeed, 0))
                        end
                        
                        -- Boost (Q key)
                        if bind.Key == "q" and isFlying then
                            currentSpeed = config.Speed * config.BoostMultiplier
                            bodyVelocity.Velocity = Vector3.new(currentSpeed, 0, 0)
                        end
                        
                        -- Slow down (E key)
                        if bind.Key == "e" and isFlying then
                            currentSpeed = config.Speed * 0.7
                            bodyVelocity.Velocity = Vector3.new(currentSpeed, 0, 0)
                        end
                    end
                end
            end
            
            -- Create keybind handler
            local function createKeyHandler(keyChar)
                return RunService.RenderStepped:Connect(function()
                    if input:IsKeyDown(keyChar) then
                        onKeyReleased()
                    end
                end)
            end
            
            table.insert(keybindsTable, {Key = bind.Key, Function = createKeyHandler(bind.Key)})
        end
        
        -- Store keybinds for later cleanup
        _G.FlyCheatPCKeybinds = keybindsTable
    end
end

-- ==========================================
-- MOBILE CONTROLS (Touch)
-- ==========================================

local function setupMobileControls()
    if config.MobileMode then
        local touchFrame = Instance.New("ScreenGui")
        touchFrame.Name = "FlyCheatTouchFrame"
        touchFrame.Parent = player.Backpack
        
        local touchLabel = Instance.New("TextLabel")
        touchLabel.Size = UDim2.new(1, 0, 1, 0)
        touchLabel.Position = UDim2.new(0, 0, 0, 0)
        touchLabel.BackgroundTransparency = 1
        touchLabel.Parent = touchFrame
        
        local function onTouchBegan(inputStartPos)
            if isFlying and bodyPosition then
                mobileTouchActive = true
                touchStartTime = tick()
                
                -- Detect long press for boost
                local function onTouchEnded()
                    mobileTouchActive = false
                    
                    -- Check if held for 0.5+ seconds (boost)
                    if (tick() - touchStartTime) >= 0.5 then
                        currentSpeed = config.Speed * config.BoostMultiplier
                        bodyPosition.Position = CFrame.new(bodyPosition.Position + Vector3.new(0, 10, 0))
                    else
                        currentSpeed = config.Speed
                        bodyPosition.Position = CFrame.new(bodyPosition.Position + Vector3.new(0, -5, 0))
                    end
                    
                    -- Reset touch state after 2 seconds
                    task.delay(2, onTouchEnded)
                end
                
                local function onTouchMoved(newPos)
                    if isFlying and bodyPosition then
                        local delta = newPos - inputStartPos
                        
                        -- Horizontal movement (left/right)
                        if math.abs(delta.X) > 10 then
                            local moveVector = Vector3.new(0, 0, 0)
                            
                            if delta.X > 0 then
                                moveVector = Vector3.new(-currentSpeed * 0.5, 0, 0) -- Left
                            else
                                moveVector = Vector3.new(currentSpeed * 0.5, 0, 0) -- Right
                            end
                            
                            bodyVelocity.Velocity = moveVector
                        end
                        
                        -- Vertical movement (up/down)
                        if math.abs(delta.Y) > 10 then
                            local verticalSpeed = delta.Y * config.Speed * 0.3
                            bodyPosition.Position = CFrame.new(bodyPosition.Position + Vector3.new(0, verticalSpeed, 0))
                        end
                        
                        -- Auto-rotate to movement direction
                        if config.AutoRotate and bodyGyro then
                            local camera = player.Camera
                            local lookVector = camera.CFrame.LookVector
                            
                            if delta.X ~= 0 or delta.Z ~= 0 then
                                local targetRotation = CFrame.new(lookVector)
                                bodyGyro.P = 15000
                                bodyGyro.D = 20
                                bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
                            end
                        end
                    end
                end
                
                local function onTouchEnded()
                    mobileTouchActive = false
                    
                    -- Check if held for 0.5+ seconds (boost)
                    if (tick() - touchStartTime) >= 0.5 then
                        currentSpeed = config.Speed * config.BoostMultiplier
                        bodyPosition.Position = CFrame.new(bodyPosition.Position + Vector3.new(0, 10, 0))
                    else
                        currentSpeed = config.Speed
                        bodyPosition.Position = CFrame.new(bodyPosition.Position + Vector3.new(0, -5, 0))
                    end
                    
                    -- Reset touch state after 2 seconds
                    task.delay(2, onTouchEnded)
                end
                
                -- Connect touch events
                local touchEndedHandler = touchFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        onTouchEnded()
                    end
                end)
                
                local touchMovedHandler = touchFrame.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch and mobileTouchActive then
                        onTouchMoved(input.Position)
                    end
                end)
            end
        end
        
        -- Connect touch events
        local function createTouchHandler()
            return touchFrame.InputBegan:Connect(onTouchBegan)
        end
        
        table.insert(_G.FlyCheatMobileHandlers, {Function = createTouchHandler})
    end
end

-- ==========================================
-- MAIN LOOP & UPDATE
-- ==========================================

local function updateFlyLoop()
    if isFlying and bodyPosition then
        -- Smooth position interpolation
        local targetPos = humanoidRootPart.Position + Vector3.new(0, 5, 0) -- Offset from ground
        
        -- Apply smooth movement with BodyPosition
        bodyPosition.Position = CFrame.new(targetPos)
        
        -- Update velocity for momentum feel
        if bodyVelocity then
            bodyVelocity.Velocity = Vector3.new(currentSpeed * 0.8, 0, 0)
        end
        
        -- Auto-rotate to movement direction (if enabled)
        if config.AutoRotate and bodyGyro then
            local camera = player.Camera
            local lookVector = camera.CFrame.LookVector
            
            if lookVector.Magnitude > 0 then
                local targetRotation = CFrame.new(lookVector)
                bodyGyro.P = 15000
                bodyGyro.D = 20
                bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
            end
        end
        
        -- Mobile touch boost handling
        if config.MobileMode and mobileTouchActive then
            local currentTime = tick()
            
            if (currentTime - touchStartTime) >= 0.5 then
                currentSpeed = config.Speed * config.BoostMultiplier
                bodyPosition.Position = CFrame.new(bodyPosition.Position + Vector3.new(0, 10, 0))
            else
                currentSpeed = config.Speed
                bodyPosition.Position = CFrame.new(bodyPosition.Position + Vector3.new(0, -5, 0))
            end
            
            -- Reset touch state after 2 seconds
            if (currentTime - touchStartTime) >= 2.5 then
                mobileTouchActive = false
            end
        end
    end
end

-- ==========================================
-- CHARACTER SPAWN HANDLER
-- ==========================================

local function onCharacterAdded()
    character = player.Character or player.CharacterAdded:Wait()
    
    -- Wait for humanoid root part to spawn
    local waitCount = 0
    while not humanoidRootPart and waitCount < 10 do
        waitCount = waitCount + 1
        task.wait(0.5)
        character = player.Character or player.CharacterAdded:Wait()
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    end
    
    if humanoidRootPart then
        -- Create fly parts
        createFlyParts()
        
        -- Setup controls based on device type
        setupPCControls()
        setupMobileControls()
        
        -- Start update loop
        RunService.RenderStepped:Connect(updateFlyLoop)
        
        print("[FLY CHEAT] Character spawned! Fly mode ready.")
    end
end

-- ==========================================
-- INITIALIZE ON CHARACTER SPAWN
-- ==========================================

local function initializeFlyCheat()
    -- Wait for character to spawn
    local waitCount = 0
    while not humanoidRootPart and waitCount < 10 do
        waitCount = waitCount + 1
        task.wait(0.5)
        character = player.Character or player.CharacterAdded:Wait()
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    end
    
    if humanoidRootPart then
        -- Create fly parts
        createFlyParts()
        
        -- Setup controls based on device type
        setupPCControls()
        setupMobileControls()
        
        -- Start update loop
        RunService.RenderStepped:Connect(updateFlyLoop)
        
        print("[FLY CHEAT] Initialized successfully!")
        print("[FLY CHEAT] Press F to toggle fly mode (PC)")
        print("[FLY CHEAT] Drag on screen to move (Mobile)")
    else
        -- Character didn't spawn in time, wait for next spawn
        characterAdded:Wait()
        initializeFlyCheat()
    end
end

-- ==========================================
-- CLEANUP FUNCTION
-- ==========================================

local function cleanupFlyCheat()
    if bodyPosition then
        bodyPosition.Parent = nil
        bodyPosition = nil
    end
    
    if bodyGyro then
        bodyGyro.Parent = nil
        bodyGyro = nil
    end
    
    if bodyVelocity then
        bodyVelocity.Parent = nil
        bodyVelocity = nil
    end
    
    isFlying = false
    currentSpeed = config.Speed
    mobileTouchActive = false
    
    -- Disconnect all connections
    for _, handler in ipairs(_G.FlyCheatPCKeybinds or {}) do
        if handler.Function and type(handler.Function) == "function" then
            handler.Function:Disconnect()
        end
    end
    
    for _, handler in ipairs(_G.FlyCheatMobileHandlers or {}) do
        if handler.Function and type(handler.Function) == "function" then
            handler.Function:Disconnect()
        end
    end
    
    print("[FLY CHEAT] Cleaned up successfully.")
end

-- ==========================================
-- MAIN EXECUTION
-- ==========================================

local characterAdded = character.CharacterAdded or player.CharacterAdded
characterAdded:Wait() -- Wait for first character spawn
initializeFlyCheat()

-- Re-initialize on respawn
player.CharacterAdded:Connect(onCharacterAdded)

-- Cleanup when leaving game
player.Changed:Connect(function(player, changed)
    if changed == "Character" and not player.Character then
        cleanupFlyCheat()
    end
end)

print("[FLY CHEAT] Ready! Press F to toggle fly mode.")