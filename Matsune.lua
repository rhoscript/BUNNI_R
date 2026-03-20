-- Matsune PVP Hub | Blox Fruits
-- Features: Aimbot, Auto-Target, ESP Player (Level + Team Color), Walk on Water, Safe Mode, Fast Attack

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Globals
_G.AimbotGun     = false
_G.AimbotSkill   = false
_G.AutoTarget    = false
_G.ESPPlayer     = false
_G.WalkWater     = false
_G.SafeMode      = false
_G.FastAttack    = false

local SelectWeaponGun = ""
local ESPTag = math.random(1, 1000000)

-- ─────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────

local function GetNearestPlayer()
    local nearest, minDist = nil, math.huge
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character
            and v.Character:FindFirstChild("HumanoidRootPart")
            and v.Character:FindFirstChild("Humanoid")
            and v.Character.Humanoid.Health > 0 then
            local d = (v.Character.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
            if d < minDist then minDist = d; nearest = v end
        end
    end
    return nearest
end

local function StudsToMetres(studs)
    return math.floor(studs * 0.28)
end

-- Track gun in backpack
spawn(function()
    while wait(0.5) do pcall(function()
        for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                SelectWeaponGun = v.Name
            end
        end
    end) end
end)

-- ─────────────────────────────────────────
--  FAST ATTACK (M1 Range)
-- ─────────────────────────────────────────
spawn(function()
    while task.wait() do
        if _G.FastAttack then
            pcall(function()
                local Net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
                local RegisterAttack = Net and Net:FindFirstChild("RE/RegisterAttack")
                local RegisterHit    = Net and Net:FindFirstChild("RE/RegisterHit")
                if not RegisterAttack or not RegisterHit then return end

                local OthersEnemies = {}
                local BasePart = nil
                local myChar = LocalPlayer.Character
                if not myChar then return end

                local function ProcessFolder(folder)
                    for _, enemy in pairs(folder:GetChildren()) do
                        local head = enemy:FindFirstChild("Head")
                        local hum  = enemy:FindFirstChild("Humanoid")
                        if head and hum and hum.Health > 0 and enemy ~= myChar then
                            local dist = (head.Position - myChar.HumanoidRootPart.Position).Magnitude
                            if dist < 100 then
                                table.insert(OthersEnemies, {enemy, head})
                                BasePart = head
                            end
                        end
                    end
                end

                local Enemies    = workspace:FindFirstChild("Enemies")
                local Characters = workspace:FindFirstChild("Characters")
                if Enemies    then ProcessFolder(Enemies)    end
                if Characters then ProcessFolder(Characters) end

                if BasePart and #OthersEnemies > 0 then
                    RegisterAttack:FireServer(0)
                    RegisterHit:FireServer(BasePart, OthersEnemies)
                end
            end)
        end
    end
end)

-- ─────────────────────────────────────────
--  AIMBOT GUN
-- ─────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not _G.AimbotGun then return end
    local target = GetNearestPlayer()
    if not target or not target.Character then return end
    local char = LocalPlayer.Character
    if not char then return end
    local gun = char:FindFirstChild(SelectWeaponGun)
    if gun and gun:FindFirstChild("RemoteFunctionShoot") then
        pcall(function()
            gun.RemoteFunctionShoot:InvokeServer(
                target.Character.HumanoidRootPart.Position,
                target.Character.HumanoidRootPart
            )
        end)
    end
end)

-- ─────────────────────────────────────────
--  AIMBOT SKILL
-- ─────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not _G.AimbotSkill then return end
    local target = GetNearestPlayer()
    if not target or not target.Character then return end
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and char:FindFirstChild(tool.Name) then
        local t = char[tool.Name]
        if t:FindFirstChild("MousePos") then
            pcall(function()
                t.RemoteEvent:FireServer(target.Character.HumanoidRootPart.Position)
            end)
        end
    end
end)

-- ─────────────────────────────────────────
--  ESP PLAYER (Level + Team Color)
-- ─────────────────────────────────────────
spawn(function()
    while wait(0.4) do pcall(function()
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                local head = v.Character:FindFirstChild("Head")
                if not head then continue end

                if _G.ESPPlayer then
                    if not head:FindFirstChild("MESP_"..ESPTag) then
                        local bg = Instance.new("BillboardGui", head)
                        bg.Name = "MESP_"..ESPTag
                        bg.AlwaysOnTop = true
                        bg.Size = UDim2.new(0, 200, 0, 50)
                        bg.StudsOffset = Vector3.new(0, 3, 0)
                        local lbl = Instance.new("TextLabel", bg)
                        lbl.Name = "lbl"
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextSize = 13
                        lbl.TextStrokeTransparency = 0.3
                        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    end

                    local esp = head:FindFirstChild("MESP_"..ESPTag)
                    if esp then
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local studs  = myRoot and (head.Position - myRoot.Position).Magnitude or 0
                        local metres = StudsToMetres(studs)
                        local hum    = v.Character:FindFirstChild("Humanoid")
                        local hp     = hum and math.floor(hum.Health / hum.MaxHealth * 100) or 0

                        -- Get level safely
                        local lvl = "?"
                        pcall(function() lvl = tostring(v.Data.Level.Value) end)

                        -- Team color: Marine = blue, Pirate = red, unknown = white
                        local teamName = ""
                        pcall(function() teamName = tostring(v.Team.Name) end)
                        local col
                        if string.find(teamName:lower(), "marine") then
                            col = Color3.fromRGB(60, 140, 255)   -- blue
                        elseif string.find(teamName:lower(), "pirate") then
                            col = Color3.fromRGB(255, 60, 60)    -- red
                        else
                            col = Color3.fromRGB(220, 220, 220)  -- white fallback
                        end

                        esp.lbl.Text = v.Name.." [Lv."..lvl.."]\n"..metres.."m  HP:"..hp.."%"
                        esp.lbl.TextColor3 = col
                    end
                else
                    local esp = head:FindFirstChild("MESP_"..ESPTag)
                    if esp then esp:Destroy() end
                end
            end
        end
    end) end
end)

-- ─────────────────────────────────────────
--  WALK ON WATER
-- ─────────────────────────────────────────
spawn(function()
    while wait(1) do pcall(function()
        local plane = workspace.Map:FindFirstChild("WaterBase-Plane")
        if plane then
            plane.Size = _G.WalkWater
                and Vector3.new(1000, 112, 1000)
                or  Vector3.new(1000, 80,  1000)
        end
    end) end
end)

-- ─────────────────────────────────────────
--  SAFE MODE
-- ─────────────────────────────────────────
spawn(function()
    while task.wait(0.1) do pcall(function()
        if not _G.SafeMode then return end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            if char.Humanoid.Health < 5500 then
                char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(0, 200, 0)
            end
        end
    end) end
end)

-- ═════════════════════════════════════════
--  UI
-- ═════════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "MatsuneAimbot"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if syn then syn.protect_gui(gui) end; gui.Parent = game.CoreGui end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Window
local WIN = Instance.new("Frame", gui)
WIN.Size = UDim2.new(0, 230, 0, 358)
WIN.Position = UDim2.new(0.04, 0, 0.3, 0)
WIN.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
WIN.BorderSizePixel = 0
WIN.ClipsDescendants = true
Instance.new("UICorner", WIN).CornerRadius = UDim.new(0, 8)
local winStroke = Instance.new("UIStroke", WIN)
winStroke.Color = Color3.fromRGB(150, 0, 255)
winStroke.Thickness = 1.2

-- Title bar
local BAR = Instance.new("Frame", WIN)
BAR.Size = UDim2.new(1, 0, 0, 34)
BAR.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
BAR.BorderSizePixel = 0
Instance.new("UICorner", BAR).CornerRadius = UDim.new(0, 8)

local TITLE = Instance.new("TextLabel", BAR)
TITLE.Size = UDim2.new(1, -40, 1, 0)
TITLE.Position = UDim2.new(0, 10, 0, 0)
TITLE.BackgroundTransparency = 1
TITLE.Text = "🎯  Matsune PVP"
TITLE.Font = Enum.Font.GothamBold
TITLE.TextSize = 13
TITLE.TextColor3 = Color3.fromRGB(190, 100, 255)
TITLE.TextXAlignment = Enum.TextXAlignment.Left

local MINBTN = Instance.new("TextButton", BAR)
MINBTN.Size = UDim2.new(0, 26, 0, 26)
MINBTN.Position = UDim2.new(1, -30, 0.5, -13)
MINBTN.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MINBTN.Text = "−"
MINBTN.Font = Enum.Font.GothamBold
MINBTN.TextSize = 15
MINBTN.TextColor3 = Color3.fromRGB(200, 200, 200)
MINBTN.BorderSizePixel = 0
Instance.new("UICorner", MINBTN).CornerRadius = UDim.new(0, 5)

-- Body
local BODY = Instance.new("ScrollingFrame", WIN)
BODY.Size = UDim2.new(1, 0, 1, -34)
BODY.Position = UDim2.new(0, 0, 0, 34)
BODY.BackgroundTransparency = 1
BODY.BorderSizePixel = 0
BODY.ScrollBarThickness = 2
BODY.ScrollBarImageColor3 = Color3.fromRGB(130, 0, 220)
BODY.CanvasSize = UDim2.new(0, 0, 0, 0)

local BLIST = Instance.new("UIListLayout", BODY)
BLIST.Padding = UDim.new(0, 4)
BLIST.SortOrder = Enum.SortOrder.LayoutOrder
local BPAD = Instance.new("UIPadding", BODY)
BPAD.PaddingLeft   = UDim.new(0, 10)
BPAD.PaddingRight  = UDim.new(0, 10)
BPAD.PaddingTop    = UDim.new(0, 8)
BPAD.PaddingBottom = UDim.new(0, 8)

BLIST:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    BODY.CanvasSize = UDim2.new(0, 0, 0, BLIST.AbsoluteContentSize.Y + 16)
end)

-- ── Minimise ─────────────────────────────
local minimised = false
MINBTN.MouseButton1Click:Connect(function()
    minimised = not minimised
    BODY.Visible = not minimised
    WIN:TweenSize(
        minimised and UDim2.new(0, 230, 0, 34) or UDim2.new(0, 230, 0, 358),
        Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true
    )
    MINBTN.Text = minimised and "+" or "−"
end)

-- ── Drag (any part of the window) ────────
local dDragging, dInput, dStart, dStartPos = false, nil, nil, nil

local function startDrag(inp)
    dDragging = true
    dStart    = inp.Position
    dStartPos = WIN.Position
    inp.Changed:Connect(function()
        if inp.UserInputState == Enum.UserInputState.End then dDragging = false end
    end)
end

BAR.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then startDrag(inp) end
end)
BAR.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement then dInput = inp end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dDragging and inp == dInput then
        local d = inp.Position - dStart
        WIN.Position = UDim2.new(
            dStartPos.X.Scale, dStartPos.X.Offset + d.X,
            dStartPos.Y.Scale, dStartPos.Y.Offset + d.Y
        )
    end
end)

-- ── Component builders ────────────────────
local orderIdx = 0
local function nextOrder() orderIdx = orderIdx + 1; return orderIdx end

local function Section(name)
    local f = Instance.new("Frame", BODY)
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.LayoutOrder = nextOrder()
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = "── "..name.." ──"
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 10
    l.TextColor3 = Color3.fromRGB(140, 60, 220)
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function Toggle(label, flag)
    local row = Instance.new("Frame", BODY)
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    row.BorderSizePixel = 0
    row.LayoutOrder = nextOrder()
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -46, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0, 34, 0, 18)
    bg.Position = UDim2.new(1, -42, 0.5, -9)
    bg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 3, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        _G[flag] = on
        TweenService:Create(bg, TweenInfo.new(0.15), {
            BackgroundColor3 = on and Color3.fromRGB(140, 40, 255) or Color3.fromRGB(45, 45, 45)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
        }):Play()
    end)
end

-- ── Target display ────────────────────────
local tgtFrame = Instance.new("Frame", BODY)
tgtFrame.Size = UDim2.new(1, 0, 0, 26)
tgtFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tgtFrame.BorderSizePixel = 0
tgtFrame.LayoutOrder = nextOrder()
Instance.new("UICorner", tgtFrame).CornerRadius = UDim.new(0, 6)

local tgtLbl = Instance.new("TextLabel", tgtFrame)
tgtLbl.Size = UDim2.new(1, -10, 1, 0)
tgtLbl.Position = UDim2.new(0, 8, 0, 0)
tgtLbl.BackgroundTransparency = 1
tgtLbl.Text = "🎯 Target: None"
tgtLbl.Font = Enum.Font.GothamSemibold
tgtLbl.TextSize = 11
tgtLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
tgtLbl.TextXAlignment = Enum.TextXAlignment.Left

spawn(function()
    while wait(0.3) do pcall(function()
        local t = GetNearestPlayer()
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local studs  = myRoot and (t.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude or 0
            local metres = StudsToMetres(studs)
            local lvl = "?"
            pcall(function() lvl = tostring(t.Data.Level.Value) end)
            tgtLbl.Text = "🎯 "..t.Name.." [Lv."..lvl.."] · "..metres.."m"
            tgtLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        else
            tgtLbl.Text = "🎯 Target: None"
            tgtLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
        end
    end) end
end)

-- ── Build sections ────────────────────────
Section("AIMBOT")
Toggle("Auto Target Nearest", "AutoTarget")
Toggle("Aimbot Gun",          "AimbotGun")
Toggle("Aimbot Skill",        "AimbotSkill")
Toggle("Fast Attack (M1)",    "FastAttack")

Section("ESP")
Toggle("Player ESP",          "ESPPlayer")

Section("UTILITY")
Toggle("Walk on Water",       "WalkWater")
Toggle("Safe Mode",           "SafeMode")

-- Footer
local foot = Instance.new("TextLabel", BODY)
foot.Size = UDim2.new(1, 0, 0, 16)
foot.BackgroundTransparency = 1
foot.Text = "Matsune PVP v1.1"
foot.Font = Enum.Font.Gotham
foot.TextSize = 9
foot.TextColor3 = Color3.fromRGB(55, 55, 55)
foot.TextXAlignment = Enum.TextXAlignment.Center
foot.LayoutOrder = nextOrder()
