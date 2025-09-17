-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Store Motor6Ds
local joints = {}
for _, motor in pairs(character:GetDescendants()) do
    if motor:IsA("Motor6D") and motor.Name ~= "HumanoidRootPartRootJoint" then
        joints[motor] = motor.C0
    end
end

local ragdolling = false
local bv, bav

-- Movement variables
local speed = 40 -- smooth speed
local velocityGoal = Vector3.new()

-- Toggle ragdoll
local function toggleRagdoll()
    ragdolling = not ragdolling

    if ragdolling then
        -- Disable joints for ragdoll
        for motor, _ in pairs(joints) do
            motor.Enabled = false
        end

        -- Physics control
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e5,0,1e5) -- no Y force, keep gravity
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = hrp

        bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(1e5,1e5,1e5)
        bav.AngularVelocity = Vector3.new(0,0,0)
        bav.Parent = hrp

        humanoid.PlatformStand = true

        -- Flopping limbs
        RunService.Heartbeat:Connect(function()
            if not ragdolling then return end
            for motor, _ in pairs(joints) do
                if motor.Part0 then
                    motor.Part0.AssemblyAngularVelocity = Vector3.new(
                        math.random(-15,15),
                        math.random(-15,15),
                        math.random(-15,15)
                    )
                end
            end

            -- Smooth velocity interpolation
            local currentVel = hrp.Velocity
            local targetVel = Vector3.new(velocityGoal.X, currentVel.Y, velocityGoal.Z)
            bv.Velocity = currentVel:Lerp(targetVel, 0.2) -- smooth lerp
        end)

        -- Update velocityGoal based on input
        UserInputService.InputChanged:Connect(function()
            local dir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + workspace.CurrentCamera.CFrame.RightVector end
            velocityGoal = dir.Unit * speed
            if dir.Magnitude == 0 then velocityGoal = Vector3.new() end
        end)

    else
        -- Restore joints
        for motor, c0 in pairs(joints) do
            motor.Enabled = true
            motor.C0 = c0
            if motor.Part0 then
                motor.Part0.AssemblyAngularVelocity = Vector3.zero
            end
        end
        humanoid.PlatformStand = false
        if bv then bv:Destroy() end
        if bav then bav:Destroy() end
    end
end

-- Keybind R
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.R then
        toggleRagdoll()
    end
end)
