repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================
-- INFINITE JUMP VARIABLES
-- ============================================
local infJumpEnabled = false

-- ============================================
-- UNWALK VARIABLES
-- ============================================
local unwalkEnabled = false
local unwalkConn = nil
local gChar = nil

-- ============================================
-- ESP VARIABLES
-- ============================================
local espEnabled = false
local espConns = {}
local ESP_COLOR = Color3.fromRGB(220, 30, 30)

-- ============================================
-- AUTO LEFT / AUTO RIGHT VARIABLES
-- ============================================
local autoLeftEnabled = false
local autoRightEnabled = false
local autoLeftPhase = 1
local autoRightPhase = 1
local autoLeftConn = nil
local autoRightConn = nil
local NORMAL_SPEED = 60

-- Target positions
local POS = {
    L1 = Vector3.new(-476.48, -6.28, 92.73),
    L2 = Vector3.new(-483.12, -4.95, 94.80),
    R1 = Vector3.new(-476.16, -6.52, 25.62),
    R2 = Vector3.new(-483.04, -5.09, 23.14),
}

-- ============================================
-- SPEED BOOST & CARRY MODE SYSTEM
-- ============================================
local SpeedState = {
    normalSpeed = 59,
    carrySpeed = 29,
    laggerSpeed = 12.3,
    isCarryMode = false,
    isLaggerMode = false,
}

local speedCharacter = nil
local speedHumanoid = nil
local speedRootPart = nil

local function applySpeed()
    if not speedHumanoid or not speedRootPart then return end
    local moveDirection = speedHumanoid.MoveDirection
    local currentSpeed

    if SpeedState.isLaggerMode then
        currentSpeed = SpeedState.laggerSpeed
    elseif SpeedState.isCarryMode then
        currentSpeed = SpeedState.carrySpeed
    else
        currentSpeed = SpeedState.normalSpeed
    end

    if moveDirection.Magnitude > 0 then
        speedRootPart.Velocity = Vector3.new(
            moveDirection.X * currentSpeed,
            speedRootPart.Velocity.Y,
            moveDirection.Z * currentSpeed
        )
    end
end

-- Ativa o loop de velocidade continuamente no jogo
RunService.Heartbeat:Connect(function()
    local c = Player.Character
    if c then
        speedCharacter = c
        speedHumanoid = c:FindFirstChildOfClass("Humanoid")
        speedRootPart = c:FindFirstChild("HumanoidRootPart")
        applySpeed()
    end
end)

local function setNormal()
    SpeedState.isCarryMode = false
    SpeedState.isLaggerMode = false
end

local function setLagger()
    SpeedState.isCarryMode = false
    SpeedState.isLaggerMode = true
end

local function setCarry()
    SpeedState.isCarryMode = true
    SpeedState.isLaggerMode = false
end

-- ============================================
-- KEYBIND SYSTEM (Customizable)
-- ============================================
local keybinds = {
    tpDown = Enum.KeyCode.G,
    drop = Enum.KeyCode.Q,
    autoLeft = Enum.KeyCode.Z,
    autoRight = Enum.KeyCode.C,
    batAimbot = Enum.KeyCode.X,
    toggleMenu = Enum.KeyCode.U,
    antiRagdoll = Enum.KeyCode.R,
}

local keybindCallbacks = {
    tpDown = function() if doTpDown then doTpDown() end end,
    drop = function() if toggleDrop then toggleDrop() end end,
    autoLeft = function() toggleAutoLeft() end,
    autoRight = function() toggleAutoRight() end,
    batAimbot = function() if toggleBatAimbot then toggleBatAimbot() end end,
    toggleMenu = function() if toggleMainGUI then toggleMainGUI() end end,
    antiRagdoll = function() if toggleAntiRagdoll then toggleAntiRagdoll() end end,
}

-- Keybind listening
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    for action, key in pairs(keybinds) do
        if input.KeyCode == key then
            task.spawn(function()
                keybindCallbacks[action]()
            end)
            break
        end
    end
end)

local function setKeybind(action, newKeyCode)
    keybinds[action] = newKeyCode
    if updateKeybindUI then
        updateKeybindUI(action, newKeyCode)
    end
end

-- ============================================
-- AUTO LEFT FUNCTIONS
-- ============================================
local function stopAutoLeft()
    if autoLeftConn then
        autoLeftConn:Disconnect()
        autoLeftConn = nil
    end
    autoLeftPhase = 1
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:Move(Vector3.zero, false)
        end
        local root = c:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
end

local function startAutoLeft()
    if autoLeftConn then stopAutoLeft() end
    autoLeftEnabled = true
    autoLeftPhase = 1
    
    autoLeftConn = RunService.Heartbeat:Connect(function()
        if not autoLeftEnabled then return end
        local c = Player.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        
        local speed = NORMAL_SPEED
        
        if autoLeftPhase == 1 then
            local target = Vector3.new(POS.L1.X, root.Position.Y, POS.L1.Z)
            if (target - root.Position).Magnitude < 1.5 then
                autoLeftPhase = 2
                local direction = (POS.L2 - root.Position)
                local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
                hum:Move(moveVec, false)
                root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
                return
            end
            local direction = (POS.L1 - root.Position)
            local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
            hum:Move(moveVec, false)
            root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
        elseif autoLeftPhase == 2 then
            local target = Vector3.new(POS.L2.X, root.Position.Y, POS.L2.Z)
            if (target - root.Position).Magnitude < 1.5 then
                hum:Move(Vector3.zero, false)
                root.AssemblyLinearVelocity = Vector3.zero
                autoLeftEnabled = false
                if autoLeftConn then autoLeftConn:Disconnect(); autoLeftConn = nil end
                autoLeftPhase = 1
                return
            end
            local direction = (POS.L2 - root.Position)
            local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
            hum:Move(moveVec, false)
            root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
        end
    end)
end

function toggleAutoLeft()
    if autoLeftEnabled then
        autoLeftEnabled = false
        stopAutoLeft()
        if leftText then
            leftText.Text = "AUTO\nLEFT"
            if leftStroke then leftStroke.Color = Color3.fromRGB(220, 30, 30) end
            leftText.TextColor3 = Color3.fromRGB(220, 30, 30)
        end
    else
        if autoRightEnabled then toggleAutoRight() end
        startAutoLeft()
        if leftText then
            leftText.Text = "LEFT\nON"
            if leftStroke then leftStroke.Color = Color3.fromRGB(100, 255, 100) end
            leftText.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end
end

-- ============================================
-- AUTO RIGHT FUNCTIONS
-- ============================================
local function stopAutoRight()
    if autoRightConn then
        autoRightConn:Disconnect()
        autoRightConn = nil
    end
    autoRightPhase = 1
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
        local root = c:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.zero end
    end
end

local function startAutoRight()
    if autoRightConn then stopAutoRight() end
    autoRightEnabled = true
    autoRightPhase = 1
    
    autoRightConn = RunService.Heartbeat:Connect(function()
        if not autoRightEnabled then return end
        local c = Player.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        
        local speed = NORMAL_SPEED
        
        if autoRightPhase == 1 then
            local target = Vector3.new(POS.R1.X, root.Position.Y, POS.R1.Z)
            if (target - root.Position).Magnitude < 1.5 then
                autoRightPhase = 2
                local direction = (POS.R2 - root.Position)
                local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
                hum:Move(moveVec, false)
                root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
                return
            end
            local direction = (POS.R1 - root.Position)
            local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
            hum:Move(moveVec, false)
            root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
        elseif autoRightPhase == 2 then
            local target = Vector3.new(POS.R2.X, root.Position.Y, POS.R2.Z)
