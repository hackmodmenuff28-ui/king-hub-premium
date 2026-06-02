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
    tpDown = function() doTpDown() end,
    drop = function() toggleDrop() end,
    autoLeft = function() toggleAutoLeft() end,
    autoRight = function() toggleAutoRight() end,
    batAimbot = function() toggleBatAimbot() end,
    toggleMenu = function() toggleMainGUI() end,
    antiRagdoll = function() toggleAntiRagdoll() end,
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

local function toggleAutoLeft()
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
            if (target - root.Position).Magnitude < 1.5 then
                hum:Move(Vector3.zero, false)
                root.AssemblyLinearVelocity = Vector3.zero
                autoRightEnabled = false
                if autoRightConn then autoRightConn:Disconnect(); autoRightConn = nil end
                autoRightPhase = 1
                return
            end
            local direction = (POS.R2 - root.Position)
            local moveVec = Vector3.new(direction.X, 0, direction.Z).Unit
            hum:Move(moveVec, false)
            root.AssemblyLinearVelocity = Vector3.new(moveVec.X * speed, root.AssemblyLinearVelocity.Y, moveVec.Z * speed)
        end
    end)
end

local function toggleAutoRight()
    if autoRightEnabled then
        autoRightEnabled = false
        stopAutoRight()
        if rightText then
            rightText.Text = "AUTO\nRIGHT"
            if rightStroke then rightStroke.Color = Color3.fromRGB(220, 30, 30) end
            rightText.TextColor3 = Color3.fromRGB(220, 30, 30)
        end
    else
        if autoLeftEnabled then toggleAutoLeft() end
        startAutoRight()
        if rightText then
            rightText.Text = "RIGHT\nON"
            if rightStroke then rightStroke.Color = Color3.fromRGB(100, 255, 100) end
            rightText.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end
end

-- ============================================
-- TP DOWN FUNCTION
-- ============================================
local function doTpDown()
    pcall(function()
        local c = Player.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {c}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local res = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rp)
        if res then 
            local newPos = res.Position + Vector3.new(0, root.Size.Y/2 + 0.5, 0)
            root.CFrame = CFrame.new(newPos)
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

-- ============================================
-- DROP BRAINROT FUNCTION
-- ============================================
local dropEnabled = false
local dropConnections = {}
local AUTO_OFF_DELAY = 0.15

local function stopDrop()
    dropEnabled = false
    for _, conn in ipairs(dropConnections) do
        pcall(function() conn:Disconnect() end)
    end
    dropConnections = {}
end

local function runDrop()
    if dropEnabled then return end
    dropEnabled = true
    
    local colConn = RunService.Stepped:Connect(function()
        if not dropEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Player and player.Character then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
    table.insert(dropConnections, colConn)
    
    task.spawn(function()
        while dropEnabled do
            RunService.Heartbeat:Wait()
            local char = Player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            local vel = root.Velocity
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if root and root.Parent then root.Velocity = vel end
            RunService.Stepped:Wait()
            if root and root.Parent then root.Velocity = vel + Vector3.new(0, 0.1, 0) end
        end
    end)
    
    task.wait(AUTO_OFF_DELAY)
    stopDrop()
end

local function toggleDrop()
    if not dropEnabled then runDrop() end
end

-- ============================================
-- BAT AIMBOT VARIABLES
-- ============================================
local batAimbotEnabled = false
local aimbotConn = nil
local lockedTarget = nil
local BAT_ENGAGE_RANGE = 5
local AIMBOT_SPEED = 60
local MELEE_OFFSET = 3
local bodyGyro = nil

local aimbotHighlight = Instance.new("Highlight")
aimbotHighlight.Name = "BatAimbotESP"
aimbotHighlight.FillColor = Color3.fromRGB(220, 30, 30)
aimbotHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
aimbotHighlight.FillTransparency = 0.5
aimbotHighlight.OutlineTransparency = 0
pcall(function() aimbotHighlight.Parent = Player:WaitForChild("PlayerGui") end)

local function isTargetValid(targetChar)
    if not targetChar then return false end
    local hum2 = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp2 = targetChar:FindFirstChild("HumanoidRootPart")
    local ff = targetChar:FindFirstChildOfClass("ForceField")
    return hum2 and hrp2 and hum2.Health > 0 and not ff
end

local function getBestTarget(myHRP)
    if lockedTarget and isTargetValid(lockedTarget) then
        return lockedTarget:FindFirstChild("HumanoidRootPart"), lockedTarget
    end
    local shortestDist, newTargetChar, newTargetHRP = math.huge, nil, nil
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= Player and isTargetValid(targetPlayer.Character) then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local distance = (targetHRP.Position - myHRP.Position).Magnitude
            if distance < shortestDist then
                shortestDist = distance
                newTargetHRP = targetHRP
                newTargetChar = targetPlayer.Character
            end
        end
    end
    lockedTarget = newTargetChar
    return newTargetHRP, newTargetChar
end

local function findBatTool()
    local c = Player.Character
    if not c then return nil end
    local bp = Player:FindFirstChildOfClass("Backpack")
    local SlapList = {
        "Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap",
        "Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap",
        "Galaxy Slap","Glitched Slap"
    }
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _, name in ipairs(SlapList) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
end

function startBatAimbot()
    if aimbotConn then return end
    local c = Player.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    local hm = c:FindFirstChildOfClass("Humanoid")
    if not h or not hm then return end
    
    bodyGyro = h:FindFirstChild("AimbotBodyGyro")
    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "AimbotBodyGyro"
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.P = 10000
        bodyGyro.D = 500
        bodyGyro.Parent = h
    end
    
    pcall(function() hm.AutoRotate = false end)
    
    batAimbotEnabled = true
    aimbotConn = RunService.Heartbeat:Connect(function()
        if not batAimbotEnabled then return end
        local c2 = Player.Character
        if not c2 then return end
        local h2 = c2:FindFirstChild("HumanoidRootPart")
        if not h2 then return end
        local hm2 = c2:FindFirstChildOfClass("Humanoid")
        local bat = findBatTool()
        if bat and bat.Parent ~= c2 then
            pcall(function() hm2:EquipTool(bat) end)
        end
        local targetHRP, targetChar = getBestTarget(h2)
        if targetHRP and targetChar then
            aimbotHighlight.Adornee = targetChar
            local targetVel = targetHRP.AssemblyLinearVelocity
            local speed = targetVel.Magnitude
            local predictTime = math.clamp(speed / 150, 0.05, 0.2)
            local predictedPos = targetHRP.Position + (targetVel * predictTime)
            local dir = (predictedPos - h2.Position)
            local dist3D = dir.Magnitude
            local standPos = predictedPos
            if dist3D > 0 then standPos = predictedPos - (dir.Unit * MELEE_OFFSET) end
            
            local lookCFrame = CFrame.lookAt(h2.Position, predictedPos)
            bodyGyro.CFrame = lookCFrame
            
            local moveDir2 = (standPos - h2.Position)
            local distToStand = moveDir2.Magnitude
            if distToStand > 1 then
                h2.AssemblyLinearVelocity = moveDir2.Unit * AIMBOT_SPEED
            else
                h2.AssemblyLinearVelocity = targetVel
            end
            if distToStand <= BAT_ENGAGE_RANGE then
                if bat and bat.Parent == c2 then
                    pcall(function() bat:Activate() end)
                end
            end
        else
            lockedTarget = nil
            h2.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            aimbotHighlight.Adornee = nil
        end
    end)
end

function stopBatAimbot()
    batAimbotEnabled = false
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
    local c = Player.Character
    local h = c and c:FindFirstChild("HumanoidRootPart")
    local hm = c and c:FindFirstChildOfClass("Humanoid")
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    if h then h.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
    if hm then pcall(function() hm.AutoRotate = true end) end
    lockedTarget = nil
    aimbotHighlight.Adornee = nil
end

function toggleBatAimbot()
    if batAimbotEnabled then 
        stopBatAimbot()
        if lockText then
            if lockStroke then lockStroke.Color = Color3.fromRGB(220, 30, 30) end
            lockText.TextColor3 = Color3.fromRGB(220, 30, 30)
            lockText.Text = "BAT\nLOCK"
        end
    else 
        startBatAimbot()
        if lockText then
            if lockStroke then lockStroke.Color = Color3.fromRGB(100, 255, 100) end
            lockText.TextColor3 = Color3.fromRGB(100, 255, 100)
            lockText.Text = "LOCK\nON"
        end
    end
end

-- ============================================
-- INFINITE JUMP FUNCTIONALITY
-- ============================================
local function setupInfiniteJump()
    UIS.JumpRequest:Connect(function()
        if not infJumpEnabled then return end
        local c = Player.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
        end
    end)
end

-- ============================================
-- UNWALK FUNCTIONALITY
-- ============================================
local function startUnwalk()
    if not gChar then gChar = Player.Character; if not gChar then return end end
    local h2 = gChar:FindFirstChildOfClass("Humanoid")
    if not h2 then return end
    local anim = h2:FindFirstChildOfClass("Animator")
    if not anim then return end
    for _, t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not unwalkEnabled then 
            if unwalkConn then unwalkConn:Disconnect(); unwalkConn = nil end
            return 
        end
        local c = Player.Character
        if not c then return end
        local hh = c:FindFirstChildOfClass("Humanoid")
        if not hh then return end
        local an = hh:FindFirstChildOfClass("Animator")
        if not an then return end
        for _, t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end
    end)
end

local function stopUnwalk()
    if unwalkConn then unwalkConn:Disconnect(); unwalkConn = nil end
end

-- ============================================
-- ESP FUNCTIONALITY
-- ============================================
local function createESP(plr)
    if plr == Player or not plr.Character then return end
    local c = plr.Character
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if c:FindFirstChild("51S_ESP") then c:FindFirstChild("51S_ESP"):Destroy() end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "51S_ESP"
    box.Adornee = root
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = ESP_COLOR
    box.Transparency = 0.45
    box.ZIndex = 10
    box.AlwaysOnTop = true
    box.Parent = c
end

local function removeESP(plr)
    if not plr.Character then return end
    local esp = plr.Character:FindFirstChild("51S_ESP")
    if esp then esp:Destroy() end
end

local function enableESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            if plr.Character then pcall(function() createESP(plr) end) end
            local conn = plr.CharacterAdded:Connect(function()
                task.wait(0.1)
                if espEnabled then pcall(function() createESP(plr) end) end
            end)
            table.insert(espConns, conn)
        end
    end
    local playerAddedConn = Players.PlayerAdded:Connect(function(plr)
        if plr == Player then return end
        local conn = plr.CharacterAdded:Connect(function()
            task.wait(0.1)
            if espEnabled then pcall(function() createESP(plr) end) end
        end)
        table.insert(espConns, conn)
    end)
    table.insert(espConns, playerAddedConn)
end

local function disableESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        pcall(function() removeESP(plr) end)
    end
    for _, conn in ipairs(espConns) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    espConns = {}
end

-- ============================================
-- ANTI-RAGDOLL FUNCTIONS
-- ============================================
local antiRagdollMode = nil
local ragdollConnections = {}
local cachedCharData = {}
local isBoosting = false
local BOOST_SPEED = 400
local DEFAULT_SPEED = 16
local stuckCounter = 0
local antiFreezeEnabled = true

local function cacheCharacterData()
    local char = Player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cachedCharData = { character = char, humanoid = hum, root = root }
    return true
end

local function disconnectAll()
    for _, conn in ipairs(ragdollConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ragdollConnections = {}
end

local function isRagdolled()
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    local ragdollStates = {
        [Enum.HumanoidStateType.Physics] = true,
        [Enum.HumanoidStateType.Ragdoll] = true,
        [Enum.HumanoidStateType.FallingDown] = true
    }
    if ragdollStates[state] then return true end
    local endTime = Player:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then return true end
    return false
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    pcall(function() Player:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
    for _, descendant in ipairs(cachedCharData.character:GetDescendants()) do
        if descendant:IsA("BallSocketConstraint") or (descendant:IsA("Attachment") and descendant.Name:find("RagdollAttachment")) then
            descendant:Destroy()
        end
    end
    if not isBoosting then isBoosting = true; cachedCharData.humanoid.WalkSpeed = BOOST_SPEED end
    if cachedCharData.humanoid.Health > 0 then cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running) end
    cachedCharData.root.Anchored = false
end

local function antiFreezeFix()
    if not antiFreezeEnabled then return end
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    local vel = cachedCharData.root.Velocity
    local isStuck = math.abs(vel.X) < 0.5 and math.abs(vel.Z) < 0.5
    if isRagdolled() then
        if isStuck then
            stuckCounter = stuckCounter + 1
            if stuckCounter > 30 then
                pcall(function()
                    cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.wait(0.05)
                    cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    cachedCharData.root.Velocity = Vector3.zero
                    cachedCharData.root.RotVelocity = Vector3.zero
                    cachedCharData.humanoid.AutoRotate = true
                    cachedCharData.humanoid.PlatformStand = false
                    if not isBoosting then isBoosting = true; cachedCharData.humanoid.WalkSpeed = BOOST_SPEED end
                    stuckCounter = 0
                end)
            end
        else
            stuckCounter = math.max(0, stuckCounter - 1)
        end
        if isStuck and cachedCharData.root.Position.Y < 0.5 then
            pcall(function()
                cachedCharData.humanoid.Jump = true
                task.wait(0.1)
                cachedCharData.humanoid.Jump = false
            end)
        end
    else
        stuckCounter = 0
        if isBoosting and not isRagdolled() then
            isBoosting = false
            if cachedCharData.humanoid then cachedCharData.humanoid.WalkSpeed = DEFAULT_SPEED end
        end
    end
    if cachedCharData.humanoid.PlatformStand then pcall(function() cachedCharData.humanoid.PlatformStand = false end) end
    if cachedCharData.humanoid.AutoRotate == false then pcall(function() cachedCharData.humanoid.AutoRotate = true end) end
end

local function antiRagdollHeartbeatLoop()
    while antiRagdollMode == "v1" do
        task.wait()
        local currentlyRagdolled = isRagdolled()
        if currentlyRagdolled then
            forceExitRagdoll()
            antiFreezeFix()
        elseif isBoosting and not currentlyRagdolled then
            isBoosting = false
            if cachedCharData.humanoid then cachedCharData.humanoid.WalkSpeed = DEFAULT_SPEED end
        else
            antiFreezeFix()
        end
    end
end

local function EnableAntiRagdoll()
    if antiRagdollMode == "v1" then return end
    if not cacheCharacterData() then return end
    antiRagdollMode = "v1"
    local camConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid then cam.CameraSubject = cachedCharData.humanoid end
    end)
    table.insert(ragdollConnections, camConn)
    local respawnConn = Player.CharacterAdded:Connect(function()
        isBoosting = false; stuckCounter = 0
        task.wait(0.5); cacheCharacterData()
    end)
    table.insert(ragdollConnections, respawnConn)
    task.spawn(antiRagdollHeartbeatLoop)
end

local function DisableAntiRagdoll()
    antiRagdollMode = nil
    if isBoosting and cachedCharData.humanoid then cachedCharData.humanoid.WalkSpeed = DEFAULT_SPEED end
    isBoosting = false; stuckCounter = 0; disconnectAll(); cachedCharData = {}
end

local function toggleAntiRagdoll()
    if antiRagdollMode == "v1" then
        DisableAntiRagdoll()
        antiFreezeEnabled = false
    else
        antiFreezeEnabled = true
        EnableAntiRagdoll()
    end
end

-- ============================================
-- CHARACTER SETUP FOR SPEED SYSTEM
-- ============================================
local function onCharacterAdded(newChar)
    speedCharacter = newChar
    speedHumanoid = speedCharacter:WaitForChild("Humanoid")
    speedRootPart = speedCharacter:WaitForChild("HumanoidRootPart")
end

if Player.Character then onCharacterAdded(Player.Character) end
Player.CharacterAdded:Connect(onCharacterAdded)

-- ============================================
-- CHARACTER RESPAWN HANDLER
-- ============================================
Player.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    gChar = c
    if unwalkEnabled then startUnwalk() end
    if espEnabled then disableESP(); enableESP() end
    if autoLeftEnabled then autoLeftEnabled = false; stopAutoLeft() end
    if autoRightEnabled then autoRightEnabled = false; stopAutoRight() end
    if antiRagdollMode == "v1" then cacheCharacterData() end
end)

setupInfiniteJump()

task.spawn(function()
    if Player.Character then
        task.wait(0.5); cacheCharacterData(); EnableAntiRagdoll()
    else
        Player.CharacterAdded:Connect(function()
            task.wait(0.5); cacheCharacterData()
            if antiRagdollMode ~= "v1" then EnableAntiRagdoll() end
        end)
    end
end)

-- ============================================
-- GUI CREATION - HUD BANNER (Top Center)
-- ============================================
local sg = Instance.new("ScreenGui")
sg.Name = "51S_HUB"
sg.ResetOnSpawn = false
sg.Parent = Player.PlayerGui

local hudBanner = Instance.new("Frame", sg)
hudBanner.Name = "HUDBanner"
hudBanner.Size = UDim2.new(0, 280, 0, 38)
hudBanner.Position = UDim2.new(0.5, -140, 0, 10)
hudBanner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
hudBanner.BackgroundTransparency = 0.25
hudBanner.BorderSizePixel = 0
hudBanner.Active = true
hudBanner.Draggable = true

local hudCorner = Instance.new("UICorner", hudBanner)
hudCorner.CornerRadius = UDim.new(0, 12)
local hudStroke = Instance.new("UIStroke", hudBanner)
hudStroke.Thickness = 1.5
hudStroke.Color = Color3.fromRGB(220, 30, 30)

local hudClickBtn = Instance.new("TextButton", hudBanner)
hudClickBtn.Size = UDim2.new(1, 0, 1, 0)
hudClickBtn.BackgroundTransparency = 1
hudClickBtn.Text = ""

local fpsText = Instance.new("TextLabel", hudBanner)
fpsText.Size = UDim2.new(0, 50, 1, 0)
fpsText.Position = UDim2.new(0, 12, 0, 0)
fpsText.BackgroundTransparency = 1
fpsText.Text = "FPS"
fpsText.TextColor3 = Color3.fromRGB(220, 30, 30)
fpsText.Font = Enum.Font.GothamBold
fpsText.TextSize = 14
fpsText.TextXAlignment = Enum.TextXAlignment.Left
fpsText.TextYAlignment = Enum.TextYAlignment.Center

local fpsValue = Instance.new("TextLabel", hudBanner)
fpsValue.Name = "FPSValue"
fpsValue.Size = UDim2.new(0, 45, 1, 0)
fpsValue.Position = UDim2.new(0, 48, 0, 0)
fpsValue.BackgroundTransparency = 1
fpsValue.Text = "61"
fpsValue.TextColor3 = Color3.fromRGB(224, 224, 224)
fpsValue.Font = Enum.Font.GothamBold
fpsValue.TextSize = 14
fpsValue.TextXAlignment = Enum.TextXAlignment.Left
fpsValue.TextYAlignment = Enum.TextYAlignment.Center

local titleLabel = Instance.new("TextLabel", hudBanner)
titleLabel.Size = UDim2.new(0, 130, 1, 0)
titleLabel.Position = UDim2.new(0.5, -65, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "51S DUELS"
titleLabel.TextColor3 = Color3.fromRGB(220, 30, 30)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.TextYAlignment = Enum.TextYAlignment.Center

local msValue = Instance.new("TextLabel", hudBanner)
msValue.Name = "MSValue"
msValue.Size = UDim2.new(0, 65, 1, 0)
msValue.Position = UDim2.new(1, -77, 0, 0)
msValue.BackgroundTransparency = 1
msValue.Text = "43 MS"
msValue.TextColor3 = Color3.fromRGB(224, 224, 224)
msValue.Font = Enum.Font.GothamBold
msValue.TextSize = 14
msValue.TextXAlignment = Enum.TextXAlignment.Right
msValue.TextYAlignment = Enum.TextYAlignment.Center

-- ============================================
-- MAIN GUI CONTAINER
-- ============================================
local mainContainer = Instance.new("Frame", sg)
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 280, 0, 400)
mainContainer.Position = isMobile and UDim2.new(0.5, -140, 0.5, -200) or UDim2.new(1, -290, 0, 70)
mainContainer.BackgroundTransparency = 1
mainContainer.BorderSizePixel = 0
mainContainer.Active = true
mainContainer.Draggable = true

local mainGuiContainer = Instance.new("Frame", mainContainer)
mainGuiContainer.Name = "MainGUI"
mainGuiContainer.Size = UDim2.new(1, 0, 1, 0)
mainGuiContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainGuiContainer.BorderSizePixel = 0
mainGuiContainer.Visible = true

local guiCorner = Instance.new("UICorner", mainGuiContainer)
guiCorner.CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", mainGuiContainer)
mainStroke.Thickness = 2
mainStroke.Color = Color3.fromRGB(220, 30, 30)

local titleLabelGui = Instance.new("TextLabel", mainGuiContainer)
titleLabelGui.Size = UDim2.new(1, 0, 0, 32)
titleLabelGui.Position = UDim2.new(0, 0, 0, 0)
titleLabelGui.BackgroundTransparency = 1
titleLabelGui.Text = "51S HUB"
titleLabelGui.TextColor3 = Color3.fromRGB(220, 30, 30)
titleLabelGui.Font = Enum.Font.GothamBold
titleLabelGui.TextSize = 16
titleLabelGui.TextXAlignment = Enum.TextXAlignment.Center

local closeMainBtn = Instance.new("TextButton", mainGuiContainer)
closeMainBtn.Size = UDim2.new(0, 24, 0, 24)
closeMainBtn.Position = UDim2.new(1, -30, 0, 4)
closeMainBtn.BackgroundTransparency = 1
closeMainBtn.Text = "Ã—"
closeMainBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
closeMainBtn.Font = Enum.Font.GothamBold
closeMainBtn.TextSize = 20
closeMainBtn.MouseButton1Click:Connect(function() mainGuiContainer.Visible = false; guiVisible = false end)

local divider = Instance.new("Frame", mainGuiContainer)
divider.Size = UDim2.new(1, -16, 0, 1)
divider.Position = UDim2.new(0, 8, 0, 32)
divider.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
divider.BackgroundTransparency = 0.6

-- TAB BAR
local tabBar = Instance.new("Frame", mainGuiContainer)
tabBar.Size = UDim2.new(1, -16, 0, 28)
tabBar.Position = UDim2.new(0, 8, 0, 38)
tabBar.BackgroundTransparency = 1

local tabNames = {"FEATURES", "SETTINGS", "KEYBINDS"}
local tabButtons = {}

local featuresFrame = Instance.new("ScrollingFrame", mainGuiContainer)
featuresFrame.Size = UDim2.new(1, -16, 0, 270)
featuresFrame.Position = UDim2.new(0, 8, 0, 70)
featuresFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
featuresFrame.BorderSizePixel = 0
featuresFrame.BackgroundTransparency = 0.3
featuresFrame.CanvasSize = UDim2.new(0, 0, 0, 260)
featuresFrame.ScrollBarThickness = 4
featuresFrame.ScrollBarImageColor3 = Color3.fromRGB(220, 30, 30)

local featuresCorner = Instance.new("UICorner", featuresFrame)
featuresCorner.CornerRadius = UDim.new(0, 6)
local featuresStroke = Instance.new("UIStroke", featuresFrame)
featuresStroke.Thickness = 1
featuresStroke.Color = Color3.fromRGB(220, 30, 30)
featuresStroke.Transparency = 0.5

local featureListLayout = Instance.new("UIListLayout", featuresFrame)
featureListLayout.Padding = UDim.new(0, 6)
featureListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local featurePadding = Instance.new("UIPadding", featuresFrame)
featurePadding.PaddingTop = UDim.new(0, 6)
featurePadding.PaddingBottom = UDim.new(0, 6)
featurePadding.PaddingLeft = UDim.new(0, 6)
featurePadding.PaddingRight = UDim.new(0, 6)

-- TAB CONTENT
local tabContent = Instance.new("Frame", mainGuiContainer)
tabContent.Size = UDim2.new(1, -16, 0, 270)
tabContent.Position = UDim2.new(0, 8, 0, 70)
tabContent.BackgroundTransparency = 1
tabContent.ClipsDescendants = true

local function createFeatureToggle(parent, labelText, getStateFunc, setStateFunc)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Thickness = 1
    rowStroke.Color = Color3.fromRGB(220, 30, 30)
    rowStroke.Transparency = 0.7

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0, 140, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 30, 30)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("Frame", row)
    toggleButton.Size = UDim2.new(0, 44, 0, 22)
    toggleButton.Position = UDim2.new(1, -54, 0.5, -11)
    toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggleButton.BorderSizePixel = 0
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0)

    local toggleCircle = Instance.new("Frame", toggleButton)
    toggleCircle.Size = UDim2.new(0, 18, 0, 18)
    toggleCircle.Position = UDim2.new(0, 3, 0.5, -9)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    toggleCircle.BorderSizePixel = 0
    Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)

    local toggleClick = Instance.new("TextButton", toggleButton)
    toggleClick.Size = UDim2.new(1, 0, 1, 0)
    toggleClick.BackgroundTransparency = 1
    toggleClick.Text = ""

    local function updateUI()
        local enabled = getStateFunc()
        if enabled then
            toggleButton.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
            toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleCircle.Position = UDim2.new(1, -21, 0.5, -9)
            rowStroke.Transparency = 0
            row.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
        else
            toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            toggleCircle.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
            toggleCircle.Position = UDim2.new(0, 3, 0.5, -9)
            rowStroke.Transparency = 0.7
            row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        end
    end

    toggleClick.MouseButton1Click:Connect(function()
        setStateFunc(not getStateFunc())
        updateUI()
    end)
    updateUI()
    return row
end

createFeatureToggle(featuresFrame, "BAT AIMBOT", function() return batAimbotEnabled end, function(v) if v then startBatAimbot() else stopBatAimbot() end end)
createFeatureToggle(featuresFrame, "PLAYER ESP", function() return espEnabled end, function(v) espEnabled = v; if v then enableESP() else disableESP() end end)
createFeatureToggle(featuresFrame, "INFINITE JUMP", function() return infJumpEnabled end, function(v) infJumpEnabled = v end)
createFeatureToggle(featuresFrame, "UNWALK", function() return unwalkEnabled end, function(v) unwalkEnabled = v; if v then gChar = Player.Character; startUnwalk() else stopUnwalk() end end)
createFeatureToggle(featuresFrame, "ANTI-RAGDOLL", function() return antiRagdollMode == "v1" end, function(v) if v then antiFreezeEnabled = true; EnableAntiRagdoll() else DisableAntiRagdoll(); antiFreezeEnabled = false end end)

-- SETTINGS PAGE (Aimbot settings only)
local settingsPage = Instance.new("ScrollingFrame", tabContent)
settingsPage.Size = UDim2.new(1, 0, 1, 0)
settingsPage.BackgroundTransparency = 1
settingsPage.Visible = false
settingsPage.CanvasSize = UDim2.new(0, 0, 0, 150)
settingsPage.ScrollBarThickness = 3

local settingsListLayout = Instance.new("UIListLayout", settingsPage)
settingsListLayout.Padding = UDim.new(0, 12)
settingsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local settingsPadding = Instance.new("UIPadding", settingsPage)
settingsPadding.PaddingTop = UDim.new(0, 8)
settingsPadding.PaddingBottom = UDim.new(0, 8)
settingsPadding.PaddingLeft = UDim.new(0, 8)
settingsPadding.PaddingRight = UDim.new(0, 8)

local function createInputRow(parent, labelText, initialValue, onValueChanged)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0, 120, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 30, 30)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local inputBox = Instance.new("TextBox", row)
    inputBox.Size = UDim2.new(0, 80, 0, 30)
    inputBox.Position = UDim2.new(1, -92, 0.5, -15)
    inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    inputBox.BorderSizePixel = 0
    inputBox.Text = tostring(initialValue)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextSize = 12
    Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 5)
    local inputStroke = Instance.new("UIStroke", inputBox)
    inputStroke.Thickness = 1
    inputStroke.Color = Color3.fromRGB(220, 30, 30)
    inputStroke.Transparency = 0.5
    
    inputBox.FocusLost:Connect(function()
        local num = tonumber(inputBox.Text)
        if num then
            onValueChanged(num)
            inputBox.Text = tostring(num)
        else
            inputBox.Text = tostring(initialValue)
        end
    end)
    return row
end

local aimbotHeader = Instance.new("TextLabel", settingsPage)
aimbotHeader.Size = UDim2.new(1, 0, 0, 24)
aimbotHeader.BackgroundTransparency = 1
aimbotHeader.Text = "AIMBOT SETTINGS"
aimbotHeader.TextColor3 = Color3.fromRGB(220, 30, 30)
aimbotHeader.Font = Enum.Font.GothamBold
aimbotHeader.TextSize = 12
aimbotHeader.TextXAlignment = Enum.TextXAlignment.Left

createInputRow(settingsPage, "AIMBOT SPEED", AIMBOT_SPEED, function(val) AIMBOT_SPEED = math.clamp(val, 20, 200) end)
createInputRow(settingsPage, "ENGAGE RANGE", BAT_ENGAGE_RANGE, function(val) BAT_ENGAGE_RANGE = math.clamp(val, 2, 30) end)

-- ESP Color
local espHeader = Instance.new("TextLabel", settingsPage)
espHeader.Size = UDim2.new(1, 0, 0, 24)
espHeader.BackgroundTransparency = 1
espHeader.Text = "ESP COLOR"
espHeader.TextColor3 = Color3.fromRGB(220, 30, 30)
espHeader.Font = Enum.Font.GothamBold
espHeader.TextSize = 12
espHeader.TextXAlignment = Enum.TextXAlignment.Left

local colorRow = Instance.new("Frame", settingsPage)
colorRow.Size = UDim2.new(1, 0, 0, 32)
colorRow.BackgroundTransparency = 1

local colorOptions = {
    {name="RED", color=Color3.fromRGB(220,30,30)},
    {name="WHITE", color=Color3.fromRGB(240,240,240)},
    {name="GREEN", color=Color3.fromRGB(30,200,80)},
    {name="BLUE", color=Color3.fromRGB(30,120,220)},
}

local colorBtns = {}
for i, opt in ipairs(colorOptions) do
    local cb = Instance.new("TextButton", colorRow)
    cb.Size = UDim2.new(0, 55, 0, 26)
    cb.Position = UDim2.new(0, (i-1)*60, 0, 3)
    cb.BackgroundColor3 = opt.color
    cb.BorderSizePixel = 0
    cb.Text = opt.name
    cb.TextColor3 = opt.name == "WHITE" and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,255,255)
    cb.Font = Enum.Font.GothamBold
    cb.TextSize = 10
    Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 4)
    local cbStroke = Instance.new("UIStroke", cb)
    cbStroke.Thickness = 2
    cbStroke.Color = Color3.fromRGB(255,255,255)
    cbStroke.Transparency = 1
    cb.MouseButton1Click:Connect(function()
        ESP_COLOR = opt.color
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                local box = plr.Character:FindFirstChild("51S_ESP")
                if box then box.Color3 = ESP_COLOR end
            end
        end
        for _, b in ipairs(colorBtns) do b.stroke.Transparency = 1 end
        cbStroke.Transparency = 0
    end)
    table.insert(colorBtns, {btn=cb, stroke=cbStroke})
end
if colorBtns[1] then colorBtns[1].stroke.Transparency = 0 end

-- KEYBINDS PAGE
local keybindsPage = Instance.new("ScrollingFrame", tabContent)
keybindsPage.Size = UDim2.new(1, 0, 1, 0)
keybindsPage.BackgroundTransparency = 1
keybindsPage.Visible = false
keybindsPage.CanvasSize = UDim2.new(0, 0, 0, 320)
keybindsPage.ScrollBarThickness = 3

local keybindsListLayout2 = Instance.new("UIListLayout", keybindsPage)
keybindsListLayout2.Padding = UDim.new(0, 6)
keybindsListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
local keybindsPadding2 = Instance.new("UIPadding", keybindsPage)
keybindsPadding2.PaddingTop = UDim.new(0, 8)
keybindsPadding2.PaddingBottom = UDim.new(0, 8)
keybindsPadding2.PaddingLeft = UDim.new(0, 8)
keybindsPadding2.PaddingRight = UDim.new(0, 8)

local keybindsHeader2 = Instance.new("TextLabel", keybindsPage)
keybindsHeader2.Size = UDim2.new(1, 0, 0, 22)
keybindsHeader2.BackgroundTransparency = 1
keybindsHeader2.Text = "CLICK ANY KEY TO REBIND"
keybindsHeader2.TextColor3 = Color3.fromRGB(220, 30, 30)
keybindsHeader2.Font = Enum.Font.GothamBold
keybindsHeader2.TextSize = 10

local keyRowElements = {}

local function createKeybindRow(parent, labelText, actionName)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0, 130, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 30, 30)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local keyButton = Instance.new("TextButton", row)
    keyButton.Size = UDim2.new(0, 80, 0, 28)
    keyButton.Position = UDim2.new(1, -92, 0.5, -14)
    keyButton.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    keyButton.BorderSizePixel = 0
    keyButton.Text = keybinds[actionName].Name
    keyButton.TextColor3 = Color3.fromRGB(220, 30, 30)
    keyButton.Font = Enum.Font.GothamBold
    keyButton.TextSize = 11
    Instance.new("UICorner", keyButton).CornerRadius = UDim.new(0, 5)
    local keyStroke = Instance.new("UIStroke", keyButton)
    keyStroke.Thickness = 1
    keyStroke.Color = Color3.fromRGB(220, 30, 30)
    keyStroke.Transparency = 0.5

    local waitingForInput = false
    keyButton.MouseButton1Click:Connect(function()
        if waitingForInput then return end
        waitingForInput = true
        local originalText = keyButton.Text
        keyButton.Text = "..."
        keyButton.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local keyCode = input.KeyCode
                if keyCode ~= Enum.KeyCode.Unknown then
                    setKeybind(actionName, keyCode)
                    keyButton.Text = keyCode.Name
                    waitingForInput = false
                    keyButton.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                    conn:Disconnect()
                end
            end
        end)
        task.delay(5, function()
            if waitingForInput then
                waitingForInput = false
                keyButton.Text = originalText
                keyButton.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                if conn then conn:Disconnect() end
            end
        end)
    end)
    keyRowElements[actionName] = keyButton
    return row
end

local keybindsListData = {
    {text = "Toggle Menu", action = "toggleMenu"},
    {text = "TP Down", action = "tpDown"},
    {text = "Drop Brainrot", action = "drop"},
    {text = "Bat Aimbot", action = "batAimbot"},
    {text = "Auto Left", action = "autoLeft"},
    {text = "Auto Right", action = "autoRight"},
    {text = "Anti-Ragdoll", action = "antiRagdoll"},
}

for _, kb in ipairs(keybindsListData) do
    createKeybindRow(keybindsPage, kb.text, kb.action)
end

function updateKeybindUI(action, keyCode)
    if keyRowElements[action] then keyRowElements[action].Text = keyCode.Name end
end

local pages = {featuresFrame, settingsPage, keybindsPage}
local guiVisible = true

local function switchTab(index)
    for i, page in ipairs(pages) do
        if page then page.Visible = (i == index) end
    end
    for i, data in ipairs(tabButtons) do
        if i == index then
            data.btn.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
            data.lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            data.btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            data.lbl.TextColor3 = Color3.fromRGB(180, 60, 60)
        end
    end
end

local tabW = 1 / #tabNames
for i, name in ipairs(tabNames) do
    local tabFrame = Instance.new("Frame", tabBar)
    tabFrame.Size = UDim2.new(tabW, i < #tabNames and -2 or 0, 1, 0)
    tabFrame.Position = UDim2.new((i-1)*tabW, 0, 0, 0)
    tabFrame.BackgroundColor3 = i == 1 and Color3.fromRGB(220, 30, 30) or Color3.fromRGB(18, 18, 18)
    tabFrame.BorderSizePixel = 0
    Instance.new("UICorner", tabFrame).CornerRadius = UDim.new(0, 5)

    local tabLbl = Instance.new("TextLabel", tabFrame)
    tabLbl.Size = UDim2.new(1, 0, 1, 0)
    tabLbl.BackgroundTransparency = 1
    tabLbl.Text = name
    tabLbl.TextColor3 = i == 1 and Color3.fromRGB(255,255,255) or Color3.fromRGB(180, 60, 60)
    tabLbl.Font = Enum.Font.GothamBold
    tabLbl.TextSize = 10

    local tabClick = Instance.new("TextButton", tabFrame)
    tabClick.Size = UDim2.new(1, 0, 1, 0)
    tabClick.BackgroundTransparency = 1
    tabClick.Text = ""
    local idx = i
    tabClick.MouseButton1Click:Connect(function() switchTab(idx) end)
    table.insert(tabButtons, {btn=tabFrame, lbl=tabLbl})
end
switchTab(1)

local function toggleMainGUI()
    guiVisible = not guiVisible
    mainGuiContainer.Visible = guiVisible
end
hudClickBtn.MouseButton1Click:Connect(toggleMainGUI)

-- HUD UPDATER
local fpsCounter = 0
local fpsTimer = 0
RunService.Heartbeat:Connect(function(dt)
    fpsCounter = fpsCounter + 1
    fpsTimer = fpsTimer + dt
    if fpsTimer >= 0.5 then
        fpsValue.Text = tostring(math.round(fpsCounter / fpsTimer))
        fpsCounter = 0
        fpsTimer = 0
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        local ping = 0
        pcall(function() ping = math.round(Player:GetNetworkPing() * 1000) end)
        msValue.Text = tostring(ping) .. " MS"
    end
end)

-- Speed system heartbeat
RunService.RenderStepped:Connect(function()
    applySpeed()
end)

-- ============================================
-- FLOATING SPEED PANEL (Separate, draggable)
-- ============================================
local speedPanel = Instance.new("Frame", sg)
speedPanel.Name = "SpeedPanel"
speedPanel.Size = UDim2.new(0, 200, 0, 210)
speedPanel.Position = UDim2.new(0, 8, 0, 350)
speedPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
speedPanel.BackgroundTransparency = 0.15
speedPanel.BorderSizePixel = 0
speedPanel.Active = true
speedPanel.Draggable = true

local panelCorner = Instance.new("UICorner", speedPanel)
panelCorner.CornerRadius = UDim.new(0, 10)
local panelStroke = Instance.new("UIStroke", speedPanel)
panelStroke.Thickness = 2
panelStroke.Color = Color3.fromRGB(220, 30, 30)

local panelTitle = Instance.new("TextLabel", speedPanel)
panelTitle.Size = UDim2.new(1, 0, 0, 28)
panelTitle.Position = UDim2.new(0, 0, 0, 0)
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "SPEED CONTROL"
panelTitle.TextColor3 = Color3.fromRGB(220, 30, 30)
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 12
panelTitle.TextXAlignment = Enum.TextXAlignment.Center

local speedDisplay = Instance.new("TextLabel", speedPanel)
speedDisplay.Size = UDim2.new(1, -16, 0, 24)
speedDisplay.Position = UDim2.new(0, 8, 0, 32)
speedDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
speedDisplay.BackgroundTransparency = 0.5
speedDisplay.Text = "Speed: 0.0"
speedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDisplay.Font = Enum.Font.GothamBold
speedDisplay.TextSize = 12
Instance.new("UICorner", speedDisplay).CornerRadius = UDim.new(0, 5)

-- Mode buttons
local modeNormal = Instance.new("TextButton", speedPanel)
modeNormal.Size = UDim2.new(0, 58, 0, 28)
modeNormal.Position = UDim2.new(0, 8, 0, 62)
modeNormal.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
modeNormal.BorderSizePixel = 0
modeNormal.Text = "NORM"
modeNormal.TextColor3 = Color3.fromRGB(255, 255, 255)
modeNormal.Font = Enum.Font.GothamBold
modeNormal.TextSize = 11
Instance.new("UICorner", modeNormal).CornerRadius = UDim.new(0, 5)

local modeLagger = Instance.new("TextButton", speedPanel)
modeLagger.Size = UDim2.new(0, 58, 0, 28)
modeLagger.Position = UDim2.new(0, 71, 0, 62)
modeLagger.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
modeLagger.BorderSizePixel = 0
modeLagger.Text = "LAG"
modeLagger.TextColor3 = Color3.fromRGB(200, 200, 200)
modeLagger.Font = Enum.Font.GothamBold
modeLagger.TextSize = 11
Instance.new("UICorner", modeLagger).CornerRadius = UDim.new(0, 5)

local modeCarry = Instance.new("TextButton", speedPanel)
modeCarry.Size = UDim2.new(0, 58, 0, 28)
modeCarry.Position = UDim2.new(1, -66, 0, 62)
modeCarry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
modeCarry.BorderSizePixel = 0
modeCarry.Text = "CARRY"
modeCarry.TextColor3 = Color3.fromRGB(200, 200, 200)
modeCarry.Font = Enum.Font.GothamBold
modeCarry.TextSize = 11
Instance.new("UICorner", modeCarry).CornerRadius = UDim.new(0, 5)

modeNormal.MouseButton1Click:Connect(function()
    setNormal()
    modeNormal.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    modeNormal.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeLagger.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    modeLagger.TextColor3 = Color3.fromRGB(200, 200, 200)
    modeCarry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    modeCarry.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

modeLagger.MouseButton1Click:Connect(function()
    setLagger()
    modeLagger.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    modeLagger.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeNormal.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    modeNormal.TextColor3 = Color3.fromRGB(200, 200, 200)
    modeCarry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    modeCarry.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

modeCarry.MouseButton1Click:Connect(function()
    setCarry()
    modeCarry.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    modeCarry.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeNormal.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    modeNormal.TextColor3 = Color3.fromRGB(200, 200, 200)
    modeLagger.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    modeLagger.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

-- Speed value inputs
local function createSpeedInputRow(parent, yOffset, labelText, initialValue, onValueChanged)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -16, 0, 32)
    row.Position = UDim2.new(0, 8, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0, 80, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 30, 30)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local inputBox = Instance.new("TextBox", row)
    inputBox.Size = UDim2.new(0, 60, 0, 24)
    inputBox.Position = UDim2.new(1, -68, 0.5, -12)
    inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    inputBox.BorderSizePixel = 0
    inputBox.Text = tostring(initialValue)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextSize = 11
    Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 4)
    local inputStroke = Instance.new("UIStroke", inputBox)
    inputStroke.Thickness = 1
    inputStroke.Color = Color3.fromRGB(220, 30, 30)
    inputStroke.Transparency = 0.5
    
    inputBox.FocusLost:Connect(function()
        local num = tonumber(inputBox.Text)
        if num then
            onValueChanged(num)
            inputBox.Text = tostring(num)
        else
            inputBox.Text = tostring(initialValue)
        end
    end)
end

createSpeedInputRow(speedPanel, 100, "Normal", SpeedState.normalSpeed, function(val) SpeedState.normalSpeed = val end)
createSpeedInputRow(speedPanel, 138, "Lagger", SpeedState.laggerSpeed, function(val) SpeedState.laggerSpeed = val end)
createSpeedInputRow(speedPanel, 176, "Carry", SpeedState.carrySpeed, function(val) SpeedState.carrySpeed = val end)

-- Update speed display
RunService.RenderStepped:Connect(function()
    if speedRootPart then
        local hSpeed = Vector3.new(speedRootPart.Velocity.X, 0, speedRootPart.Velocity.Z).Magnitude
        speedDisplay.Text = "Speed: " .. string.format("%.1f", hSpeed)
    end
end)

-- ============================================
-- FLOATING BUTTONS
-- ============================================
local function createFloatButton(name, text, pos, callback)
    local btn = Instance.new("Frame", sg)
    btn.Name = name
    btn.Size = UDim2.new(0, 70, 0, 70)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BorderSizePixel = 0
    btn.Active = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0.3, 0)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(220, 30, 30)

    local txt = Instance.new("TextLabel", btn)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(220, 30, 30)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 9
    txt.TextWrapped = true
    txt.LineHeight = 1.1

    local click = Instance.new("TextButton", btn)
    click.Size = UDim2.new(1, 0, 1, 0)
    click.BackgroundTransparency = 1
    click.Text = ""

    click.MouseButton1Click:Connect(function()
        local original = txt.TextColor3
        txt.TextColor3 = Color3.fromRGB(255, 100, 100)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        task.wait(0.08)
        txt.TextColor3 = original
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        callback()
    end)

    click.MouseEnter:Connect(function()
        stroke.Color = Color3.fromRGB(255, 80, 80)
        txt.TextColor3 = Color3.fromRGB(255, 80, 80)
    end)
    click.MouseLeave:Connect(function()
        stroke.Color = Color3.fromRGB(220, 30, 30)
        txt.TextColor3 = Color3.fromRGB(220, 30, 30)
    end)
    
    local holding = false
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local holdThread = nil
    
    click.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = true
            holdThread = task.delay(0.3, function()
                if holding then
                    dragging = true
                    dragStart = input.Position
                    startPos = btn.Position
                    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                end
            end)
        end
    end)
    
    click.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = false
            dragging = false
            if holdThread then task.cancel(holdThread) end
            btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        end
    end)
    
    click.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    return btn, txt, stroke
end

local startY = 80
local spacing = 56

createFloatButton("TPDownButton", "TP\nDOWN", UDim2.new(0, 8, 0, startY), doTpDown)
createFloatButton("DropButton", "DROP\nBRAIN", UDim2.new(0, 8, 0, startY + spacing), toggleDrop)
local lockBtn, lockText, lockStroke = createFloatButton("LockButton", "BAT\nLOCK", UDim2.new(0, 8, 0, startY + spacing * 2), toggleBatAimbot)
local leftBtn, leftText, leftStroke = createFloatButton("AutoLeftButton", "AUTO\nLEFT", UDim2.new(0, 8, 0, startY + spacing * 3), toggleAutoLeft)
local rightBtn, rightText, rightStroke = createFloatButton("AutoRightButton", "AUTO\nRIGHT", UDim2.new(0, 8, 0, startY + spacing * 4), toggleAutoRight)

print("51S HUB Loaded - Speed panel is separate and draggable! Keybinds: G=TP Down, Q=Drop, Z=Auto Left, C=Auto Right, X=Bat Aimbot, U=Menu, R=Anti-Ragdoll")
