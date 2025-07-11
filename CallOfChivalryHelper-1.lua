




local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")


local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local trajectoryEnabled = true
local targetingEnabled = true
local gravity = workspace.Gravity 
local arrowSpeed = 175 
local trajectoryPoints = 30 
local trajectoryLifetime = 0.1 
local lastTargetPosition = Vector3.new(0, 0, 0)
local predictedImpactPosition = Vector3.new(0, 0, 0)
local bowEquipped = false
local trajectoryParts = {}
local aimAssistActive = false


local trajectoryColor = Color3.fromRGB(255, 255, 0) 
local impactColor = Color3.fromRGB(255, 0, 0) 
local targetingColor = Color3.fromRGB(0, 255, 0) 


local function setupUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProjectileCalculatorGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 220, 0, 140)
    mainFrame.Position = UDim2.new(0.85, -110, 0.4, 0)
    mainFrame.BackgroundTransparency = 0.4
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    mainFrame.Parent = screenGui
    
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.BackgroundTransparency = 0.5
    titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleLabel.Text = "Projectile Calculator"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.Parent = mainFrame
    
    
    local trajectoryToggle = Instance.new("TextButton")
    trajectoryToggle.Name = "TrajectoryToggle"
    trajectoryToggle.Size = UDim2.new(0.9, 0, 0, 25)
    trajectoryToggle.Position = UDim2.new(0.05, 0, 0.25, 0)
    trajectoryToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    trajectoryToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    trajectoryToggle.Text = "Trajectory: ON"
    trajectoryToggle.Font = Enum.Font.Gotham
    trajectoryToggle.TextSize = 14
    trajectoryToggle.Parent = mainFrame
    
    
    local targetToggle = Instance.new("TextButton")
    targetToggle.Name = "TargetToggle"
    targetToggle.Size = UDim2.new(0.9, 0, 0, 25)
    targetToggle.Position = UDim2.new(0.05, 0, 0.45, 0)
    targetToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    targetToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetToggle.Text = "Target Assist: ON"
    targetToggle.Font = Enum.Font.Gotham
    targetToggle.TextSize = 14
    targetToggle.Parent = mainFrame
    
    
    local distanceText = Instance.new("TextLabel")
    distanceText.Name = "DistanceText"
    distanceText.Size = UDim2.new(0.9, 0, 0, 25)
    distanceText.Position = UDim2.new(0.05, 0, 0.65, 0)
    distanceText.BackgroundTransparency = 0.8
    distanceText.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    distanceText.Text = "Target Distance: N/A"
    distanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceText.Font = Enum.Font.Gotham
    distanceText.TextSize = 14
    distanceText.Parent = mainFrame
    
    
    trajectoryToggle.MouseButton1Click:Connect(function()
        trajectoryEnabled = not trajectoryEnabled
        
        if trajectoryEnabled then
            trajectoryToggle.Text = "Trajectory: ON"
            trajectoryToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        else
            trajectoryToggle.Text = "Trajectory: OFF"
            trajectoryToggle.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
            
            clearTrajectory()
        end
    end)
    
    
    targetToggle.MouseButton1Click:Connect(function()
        targetingEnabled = not targetingEnabled
        
        if targetingEnabled then
            targetToggle.Text = "Target Assist: ON"
            targetToggle.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        else
            targetToggle.Text = "Target Assist: OFF"
            targetToggle.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        end
    end)
    
    
    local targetIndicator = Instance.new("BillboardGui")
    targetIndicator.Name = "TargetIndicator"
    targetIndicator.Size = UDim2.new(5, 0, 5, 0)
    targetIndicator.AlwaysOnTop = true
    targetIndicator.Enabled = false
    targetIndicator.Parent = workspace
    
    local targetFrame = Instance.new("Frame")
    targetFrame.Name = "TargetFrame"
    targetFrame.Size = UDim2.new(1, 0, 1, 0)
    targetFrame.BackgroundTransparency = 0.5
    targetFrame.BackgroundColor3 = targetingColor
    targetFrame.BorderSizePixel = 2
    targetFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    targetFrame.Parent = targetIndicator
    
    
    local crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "EnhancedCrosshair"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.Parent = player.PlayerGui
    
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 4, 0, 4)
    crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
    crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshair.BorderSizePixel = 0
    crosshair.Parent = crosshairGui
    
    local horizontalLine = Instance.new("Frame")
    horizontalLine.Name = "HorizontalLine"
    horizontalLine.Size = UDim2.new(0, 12, 0, 2)
    horizontalLine.Position = UDim2.new(0.5, -6, 0.5, -1)
    horizontalLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    horizontalLine.BorderSizePixel = 0
    horizontalLine.Parent = crosshairGui
    
    local verticalLine = Instance.new("Frame")
    verticalLine.Name = "VerticalLine"
    verticalLine.Size = UDim2.new(0, 2, 0, 12)
    verticalLine.Position = UDim2.new(0.5, -1, 0.5, -6)
    verticalLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    verticalLine.BorderSizePixel = 0
    verticalLine.Parent = crosshairGui
    
    return {
        distanceText = distanceText,
        targetIndicator = targetIndicator,
        crosshair = crosshair,
        horizontalLine = horizontalLine,
        verticalLine = verticalLine
    }
end


local function createTrajectoryPart()
    local part = Instance.new("Part")
    part.Name = "TrajectoryPoint"
    part.Size = Vector3.new(0.2, 0.2, 0.2)
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Shape = Enum.PartType.Ball
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Transparency = 0.5
    part.Parent = workspace
    
    return part
end


local function clearTrajectory()
    for _, part in ipairs(trajectoryParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    trajectoryParts = {}
end


local function calculateTrajectory(startPos, initialVelocity)
    local trajectory = {}
    local timeStep = 0.1 
    
    
    local position = startPos
    local velocity = initialVelocity
    
    
    for i = 1, trajectoryPoints do
        
        position = position + velocity * timeStep
        
        
        velocity = velocity + Vector3.new(0, -gravity * timeStep, 0)
        
        
        table.insert(trajectory, position)
        
        
        local ray = Ray.new(position - velocity * timeStep, velocity * timeStep)
        local hit, hitPosition = workspace:FindPartOnRay(ray, character, false, true)
        
        if hit then
            
            table.insert(trajectory, hitPosition)
            predictedImpactPosition = hitPosition
            break
        end
    end
    
    return trajectory
end


local function visualizeTrajectory(trajectory)
    clearTrajectory()
    
    
    for i, position in ipairs(trajectory) do
        local part = createTrajectoryPart()
        
        
        if i == #trajectory then
            part.Size = Vector3.new(0.6, 0.6, 0.6)
            part.Color = impactColor
        else
            part.Color = trajectoryColor
        end
        
        part.Position = position
        table.insert(trajectoryParts, part)
        
        
        Debris:AddItem(part, trajectoryLifetime)
    end
end


local function checkForBowEquipped()
    if not character then return false end
    
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        
        
        local toolName = tool.Name:lower()
        return string.find(toolName, "bow") or 
               string.find(toolName, "arrow") or 
               string.find(toolName, "crossbow") or
               string.find(toolName, "longbow")
    end
    
    return false
end


local function findBestTarget(maxDistance)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local playerPosition = humanoidRootPart.Position
    local lookVector = camera.CFrame.LookVector
    
    local bestTarget = nil
    local bestScore = 0
    local bestPosition = nil
    
    
    local allPlayers = Players:GetPlayers()
    
    for _, otherPlayer in pairs(allPlayers) do
        
        if otherPlayer ~= player then
            
            local otherCharacter = otherPlayer.Character
            if otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart") and
               otherCharacter:FindFirstChild("Humanoid") and
               otherCharacter.Humanoid.Health > 0 then
                
                local otherHRP = otherCharacter:FindFirstChild("HumanoidRootPart")
                local targetPosition = otherHRP.Position
                local distance = (targetPosition - playerPosition).Magnitude
                
                
                if distance <= maxDistance then
                    
                    local directionToTarget = (targetPosition - playerPosition).Unit
                    local alignmentScore = lookVector:Dot(directionToTarget) 
                    
                    
                    if alignmentScore > 0.7 then
                        
                        
                        local score = alignmentScore * (1 - distance/maxDistance)
                        
                        if score > bestScore then
                            bestScore = score
                            bestTarget = otherCharacter
                            bestPosition = targetPosition
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget, bestPosition
end


local function calculateLeadPosition(targetCharacter, targetPosition, projectileSpeed)
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
        return targetPosition
    end
    
    local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    
    local estimatedVelocity = Vector3.new(0, 0, 0)
    if lastTargetPosition ~= Vector3.new(0, 0, 0) then
        estimatedVelocity = (targetPosition - lastTargetPosition) / RunService.Heartbeat:Wait()
    end
    lastTargetPosition = targetPosition
    
    
    if estimatedVelocity.Magnitude < 1 then
        return targetPosition
    end
    
    
    local characterPosition = character:FindFirstChild("HumanoidRootPart").Position
    local distanceToTarget = (targetPosition - characterPosition).Magnitude
    local timeToTarget = distanceToTarget / projectileSpeed
    
    
    local predictedPosition = targetPosition + (estimatedVelocity * timeToTarget)
    
    
    local gravityDrop = 0.5 * gravity * timeToTarget * timeToTarget
    predictedPosition = predictedPosition + Vector3.new(0, gravityDrop, 0)
    
    return predictedPosition
end


local function onCharacterAdded(newCharacter)
    character = newCharacter
    bowEquipped = false
end


local function updateProjectileTrajectory(uiElements)
    
    bowEquipped = checkForBowEquipped()
    
    
    if not bowEquipped or not trajectoryEnabled then
        clearTrajectory()
        uiElements.targetIndicator.Enabled = false
        uiElements.distanceText.Text = "Target Distance: N/A"
        uiElements.crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        uiElements.horizontalLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        uiElements.verticalLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        return
    end
    
    
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local startPosition = humanoidRootPart.Position + Vector3.new(0, 1.5, 0) 
    
    
    local fireDirection = camera.CFrame.LookVector
    
    
    local targetCharacter, targetPosition = nil, nil
    if targetingEnabled then
        targetCharacter, targetPosition = findBestTarget(150) 
        
        if targetCharacter and targetPosition then
            
            local leadPosition = calculateLeadPosition(targetCharacter, targetPosition, arrowSpeed)
            
            
            uiElements.targetIndicator.Adornee = targetCharacter.HumanoidRootPart
            uiElements.targetIndicator.Enabled = true
            
            
            local directionToTarget = (leadPosition - startPosition).Unit
            fireDirection = directionToTarget
            
            
            local distance = (targetPosition - startPosition).Magnitude
            uiElements.distanceText.Text = "Target Distance: " .. math.floor(distance) .. " studs"
            
            
            uiElements.crosshair.BackgroundColor3 = targetingColor
            uiElements.horizontalLine.BackgroundColor3 = targetingColor
            uiElements.verticalLine.BackgroundColor3 = targetingColor
            
            
            if not aimAssistActive then
                aimAssistActive = true
                
                
                local targetLook = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + directionToTarget)
                local currentLook = camera.CFrame
                
                
                local blendedCFrame = currentLook:Lerp(targetLook, 0.3)
                camera.CFrame = blendedCFrame
            end
        else
            uiElements.targetIndicator.Enabled = false
            uiElements.distanceText.Text = "Target Distance: N/A"
            uiElements.crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            uiElements.horizontalLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            uiElements.verticalLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            aimAssistActive = false
        end
    else
        uiElements.targetIndicator.Enabled = false
        aimAssistActive = false
    end
    
    
    local initialVelocity = fireDirection * arrowSpeed
    
    
    local trajectory = calculateTrajectory(startPosition, initialVelocity)
    
    
    visualizeTrajectory(trajectory)
end


player.CharacterAdded:Connect(onCharacterAdded)


local uiElements = setupUI()


RunService.RenderStepped:Connect(function()
    updateProjectileTrajectory(uiElements)
end)


print("Projectile Trajectory Calculator initialized successfully!")





local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart
local cameraModule = workspace.CurrentCamera
local blockKey = Enum.KeyCode.F 
local blockButton = Enum.UserInputType.MouseButton2 
local blockDetectionRange = 15 
local reactionTimeWindow = 0.3 
local cooldownTime = 2 
local onCooldown = false
local attackDetected = false
local visualFeedbackEnabled = true


local function setupUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoBlockAssistGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 200, 0, 100)
    mainFrame.Position = UDim2.new(0.85, -100, 0.2, 0)
    mainFrame.BackgroundTransparency = 0.5
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
    mainFrame.Parent = screenGui
    
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.BackgroundTransparency = 0.7
    titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleLabel.Text = "Auto-Block Assistant"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.Parent = mainFrame
    
    
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Size = UDim2.new(0, 20, 0, 20)
    statusIndicator.Position = UDim2.new(0.1, 0, 0.5, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0) 
    statusIndicator.BorderSizePixel = 1
    statusIndicator.Parent = mainFrame
    
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(0.7, 0, 0, 20)
    statusText.Position = UDim2.new(0.25, 0, 0.5, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Ready"
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 14
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = mainFrame
    
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(1, 0, 0, 25)
    toggleButton.Position = UDim2.new(0, 0, 1, 5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = "Disable Visual Feedback"
    toggleButton.Font = Enum.Font.Gotham
    toggleButton.TextSize = 14
    toggleButton.Parent = mainFrame
    
    
    local alertOverlay = Instance.new("Frame")
    alertOverlay.Name = "AlertOverlay"
    alertOverlay.Size = UDim2.new(1, 0, 1, 0)
    alertOverlay.BackgroundTransparency = 0.7
    alertOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    alertOverlay.Visible = false
    alertOverlay.Parent = screenGui
    
    local alertText = Instance.new("TextLabel")
    alertText.Name = "AlertText"
    alertText.Size = UDim2.new(0.5, 0, 0.2, 0)
    alertText.Position = UDim2.new(0.25, 0, 0.4, 0)
    alertText.BackgroundTransparency = 1
    alertText.Text = "BLOCK NOW!"
    alertText.TextColor3 = Color3.fromRGB(255, 255, 255)
    alertText.Font = Enum.Font.GothamBold
    alertText.TextSize = 36
    alertText.Parent = alertOverlay
    
    
    toggleButton.MouseButton1Click:Connect(function()
        visualFeedbackEnabled = not visualFeedbackEnabled
        if visualFeedbackEnabled then
            toggleButton.Text = "Disable Visual Feedback"
            toggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
        else
            toggleButton.Text = "Enable Visual Feedback"
            toggleButton.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
        end
    end)
    
    return {
        statusIndicator = statusIndicator,
        statusText = statusText,
        alertOverlay = alertOverlay
    }
end


local function updateUI(uiElements, status)
    if status == "ready" then
        uiElements.statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0) 
        uiElements.statusText.Text = "Ready"
    elseif status == "alert" then
        uiElements.statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0) 
        uiElements.statusText.Text = "Incoming Attack!"
        if visualFeedbackEnabled then
            uiElements.alertOverlay.Visible = true
            delay(0.5, function()
                uiElements.alertOverlay.Visible = false
            end)
        end
    elseif status == "cooldown" then
        uiElements.statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 165, 0) 
        uiElements.statusText.Text = "Cooldown"
    end
end


local function detectIncomingAttacks(uiElements)
    
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    
    local allPlayers = Players:GetPlayers()
    
    for _, otherPlayer in pairs(allPlayers) do
        
        if otherPlayer ~= player then
            
            local otherCharacter = otherPlayer.Character
            if otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart") then
                local otherHRP = otherCharacter:FindFirstChild("HumanoidRootPart")
                local distance = (otherHRP.Position - humanoidRootPart.Position).Magnitude
                
                
                if distance <= blockDetectionRange then
                    
                    
                    
                    local otherHumanoid = otherCharacter:FindFirstChild("Humanoid")
                    
                    if otherHumanoid then
                        local currentAnim = otherHumanoid:GetPlayingAnimationTracks()
                        
                        for _, anim in pairs(currentAnim) do
                            
                            
                            if string.find(anim.Name:lower(), "attack") or 
                               string.find(anim.Name:lower(), "swing") or 
                               string.find(anim.Name:lower(), "slash") or
                               string.find(anim.Name:lower(), "stab") then
                                
                                
                                if anim.TimePosition < 0.3 and not attackDetected and not onCooldown then
                                    attackDetected = true
                                    updateUI(uiElements, "alert")
                                    
                                    
                                    delay(math.random(0.05, reactionTimeWindow), function()
                                        
                                        local blockInput = {
                                            KeyCode = blockKey,
                                            UserInputType = Enum.UserInputType.Keyboard,
                                            UserInputState = Enum.UserInputState.Begin
                                        }
                                        UserInputService:SendKeyEvent(true, blockKey, false, game)
                                        
                                        
                                        delay(0.3, function()
                                            UserInputService:SendKeyEvent(false, blockKey, false, game)
                                        end)
                                        
                                        
                                        onCooldown = true
                                        updateUI(uiElements, "cooldown")
                                        
                                        
                                        delay(cooldownTime, function()
                                            onCooldown = false
                                            attackDetected = false
                                            updateUI(uiElements, "ready")
                                        end)
                                    end)
                                    
                                    break
                                end
                            end
                        end
                        
                        
                        local tool = otherCharacter:FindFirstChildOfClass("Tool")
                        if tool and not attackDetected and not onCooldown then
                            local lookVector = otherHRP.CFrame.LookVector
                            local directionToPlayer = (humanoidRootPart.Position - otherHRP.Position).Unit
                            local dotProduct = lookVector:Dot(directionToPlayer)
                            
                            
                            if dotProduct > 0.7 and distance < 8 then
                                attackDetected = true
                                updateUI(uiElements, "alert")
                                
                                
                                delay(math.random(0.05, reactionTimeWindow), function()
                                    UserInputService:SendKeyEvent(true, blockKey, false, game)
                                    
                                    delay(0.3, function()
                                        UserInputService:SendKeyEvent(false, blockKey, false, game)
                                    end)
                                    
                                    onCooldown = true
                                    updateUI(uiElements, "cooldown")
                                    
                                    delay(cooldownTime, function()
                                        onCooldown = false
                                        attackDetected = false
                                        updateUI(uiElements, "ready")
                                    end)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end


local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    attackDetected = false
    onCooldown = false
end


player.CharacterAdded:Connect(onCharacterAdded)


local uiElements = setupUI()
updateUI(uiElements, "ready")


RunService.Heartbeat:Connect(function()
    if not onCooldown and not attackDetected then
        detectIncomingAttacks(uiElements)
    end
end)


print("Auto-Block Assistant initialized successfully!")

