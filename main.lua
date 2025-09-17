--// Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Destroy old GUI
local existingGui = player:FindFirstChild("PlayerGui"):FindFirstChild("VortexialHubGUI")
if existingGui then existingGui:Destroy() end

local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Respawn support
player.CharacterAdded:Connect(function(char)
    character = char
    hrp = character:WaitForChild("HumanoidRootPart")
end)

--// GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VortexialHubGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 380)
frame.Position = UDim2.new(0.35,0,0.25,0)
frame.BackgroundColor3 = Color3.fromRGB(20,20,30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(25,25,40)
title.BorderSizePixel = 0
title.Text = "Vortexial Hub"
title.TextColor3 = Color3.fromRGB(200,100,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0,8)
titleCorner.Parent = title

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,0,0,20)
statusLabel.Position = UDim2.new(0,0,0,36)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🔒 Locked"
statusLabel.TextColor3 = Color3.fromRGB(255,75,75)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 16
statusLabel.Parent = frame

-- Helper function for buttons
local function createButton(text,pos)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,220,0,45)
    button.Position = pos
    button.BackgroundColor3 = Color3.fromRGB(90,0,130)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Parent = frame
    return button
end

-- Buttons
local setPointBtn = createButton("Set Point", UDim2.new(0,40,0,70))
local tweenBtn = createButton("Tween (E)", UDim2.new(0,40,0,130))
local playPathBtn = createButton("Play Path", UDim2.new(0,40,0,190))
local returnToggle = createButton("Return After Tween: OFF", UDim2.new(0,40,0,250))
local resetPathBtn = createButton("Reset Path", UDim2.new(0,40,0,310))

-- Hide all controls until key is entered
setPointBtn.Visible = false
tweenBtn.Visible = false
playPathBtn.Visible = false
returnToggle.Visible = false
resetPathBtn.Visible = false

-- Key Box
local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0,200,0,35)
keyBox.Position = UDim2.new(0.5,-100,0.5,-20)
keyBox.BackgroundColor3 = Color3.fromRGB(40,0,70)
keyBox.TextColor3 = Color3.fromRGB(255,255,255)
keyBox.PlaceholderText = ""
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 16
keyBox.Parent = frame

local keySubmit = createButton("Submit Key", UDim2.new(0.5,-100,0.5,25))

-- Galaxy styling
local function galaxyStyle(button)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120,0,180)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180,0,255))
    }
    gradient.Rotation = 45
    gradient.Parent = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(200,100,255)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button
end

galaxyStyle(setPointBtn)
galaxyStyle(tweenBtn)
galaxyStyle(playPathBtn)
galaxyStyle(returnToggle)
galaxyStyle(resetPathBtn)
galaxyStyle(keySubmit)

-- Variables
local hasKey = false
local correctKey = "VortexialHubONTOP"
local savedPoints = {} -- {name = CFrame}
local pointOrder = {} -- ordered list of point names
local currentPointName = nil
local tweenTime = 0.6
local returnAfterTween = false

-- Status helper
local function updateStatus(text,color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color
end

-- Key Submit
keySubmit.MouseButton1Click:Connect(function()
    if keyBox.Text == correctKey then
        hasKey = true
        keySubmit.Text = "Key Accepted!"
        updateStatus("✅ Verified", Color3.fromRGB(0,255,100))
        wait(1)
        keyBox.Visible = false
        keySubmit.Visible = false
        setPointBtn.Visible = true
        tweenBtn.Visible = true
        playPathBtn.Visible = true
        returnToggle.Visible = true
        resetPathBtn.Visible = true
    else
        keySubmit.Text = "Wrong Key!"
        updateStatus("🔒 Locked", Color3.fromRGB(255,75,75))
        wait(1)
        keySubmit.Text = "Submit Key"
    end
end)

-- Set Point Button
setPointBtn.MouseButton1Click:Connect(function()
    if hasKey and hrp then
        local pointName = "Point"..(#pointOrder+1)
        savedPoints[pointName] = hrp.CFrame
        table.insert(pointOrder, pointName)
        currentPointName = pointName
        setPointBtn.Text = "Saved "..pointName
        wait(1)
        setPointBtn.Text = "Set Point"
        updateStatus("Saved "..pointName, Color3.fromRGB(0,200,255))
    end
end)

-- Tween to single point
local function tweenToPoint(pointName)
    if hasKey and savedPoints[pointName] and hrp then
        local originalCFrame = hrp.CFrame
        local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = savedPoints[pointName]})
        tween:Play()
        tween.Completed:Wait()
        if returnAfterTween then
            local tweenBack = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = originalCFrame})
            tweenBack:Play()
            tweenBack.Completed:Wait()
        end
    end
end

-- Play Path: sequential tween through all saved points
local function playPath()
    if hasKey and #pointOrder > 0 and hrp then
        local originalCFrame = hrp.CFrame
        for _, pointName in ipairs(pointOrder) do
            local targetCFrame = savedPoints[pointName]
            local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
            tween:Play()
            tween.Completed:Wait()
        end
        if returnAfterTween then
            local tweenBack = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = originalCFrame})
            tweenBack:Play()
            tweenBack.Completed:Wait()
        end
    end
end

-- Reset Path Button
resetPathBtn.MouseButton1Click:Connect(function()
    savedPoints = {}
    pointOrder = {}
    currentPointName = nil
    updateStatus("Path Reset", Color3.fromRGB(255,200,0))
end)

-- Button connections
tweenBtn.MouseButton1Click:Connect(function()
    if currentPointName then tweenToPoint(currentPointName) end
end)

playPathBtn.MouseButton1Click:Connect(playPath)

-- Keybind
UserInputService.InputBegan:Connect(function(input,gp)
    if not gp and input.KeyCode==Enum.KeyCode.E then
        if currentPointName then tweenToPoint(currentPointName) end
    end
end)

-- Return toggle
returnToggle.MouseButton1Click:Connect(function()
    returnAfterTween = not returnAfterTween
    returnToggle.Text = "Return After Tween: "..(returnAfterTween and "ON" or "OFF")
end)

-- Draggable
local dragging = false
local dragStart, startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true
        dragStart=input.Position
        startPos=frame.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)
