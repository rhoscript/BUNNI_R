-- ╔══════════════════════════════════════════════╗
-- ║   BUNNI_R  ·  Matsune PVP  ·  v2.0          ║
-- ║   Black-Purple Glass · Futuristic UI         ║
-- ╚══════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput      = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local ESPTag = math.random(1, 999999)

-- ════════════════════════════════════════════════════════
--  SETTINGS  (all configurable from UI)
-- ════════════════════════════════════════════════════════
local CFG = {
    -- toggles
    AimbotGun       = false,
    AimbotSkill     = false,
    AutoTarget      = false,
    ESPPlayer       = false,
    WalkWater       = false,
    SafeMode        = false,
    FastAttack      = false,
    CamLock         = false,
    SilentAim       = false,
    AutoV3          = false,
    AutoV4          = false,
    HighPerf        = false,
    SpeedHack       = false,
    AutoHaki        = false,

    -- values
    JumpPower       = 120,
    WalkSpeed       = 60,
    ESPRange        = 500,
    FastAtkDelay    = 0,
    SafeHPThresh    = 30,   -- % health
    AimbotTarget    = "HRP",  -- "HRP" or "Head"
}

local SelectWeaponGun = ""
local OrigWalkSpeed   = 16

-- ════════════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════════════
local function M(s) return math.floor(s * 0.28) end

local function GetTarget()
    local best, bestD = nil, math.huge
    local myChar = LP.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LP and v.Character then
            local hrp = v.Character:FindFirstChild("HumanoidRootPart")
            local hum = v.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myPos).Magnitude
                if d < bestD and d <= CFG.ESPRange then
                    bestD = d; best = v
                end
            end
        end
    end
    return best
end

local function GetAimPos(v)
    if not v or not v.Character then return nil end
    if CFG.AimbotTarget == "Head" then
        local h = v.Character:FindFirstChild("Head")
        return h and h.Position or nil
    else
        local hrp = v.Character:FindFirstChild("HumanoidRootPart")
        return hrp and hrp.Position or nil
    end
end

local function GetAimPart(v)
    if not v or not v.Character then return nil end
    if CFG.AimbotTarget == "Head" then
        return v.Character:FindFirstChild("Head")
    else
        return v.Character:FindFirstChild("HumanoidRootPart")
    end
end

local function GetLevel(p)
    local ok, v = pcall(function() return p.Data.Level.Value end)
    return ok and tostring(v) or "?"
end

local function TeamColor(p)
    local ok, t = pcall(function() return tostring(p.Team) end)
    if not ok then return Color3.fromRGB(200,200,200) end
    if t:lower():find("marine") then return Color3.fromRGB(90,180,255) end
    if t:lower():find("pirate") then return Color3.fromRGB(255,70,70) end
    return Color3.fromRGB(180,180,180)
end

-- ════════════════════════════════════════════════════════
--  GUN TRACKER
-- ════════════════════════════════════════════════════════
spawn(function()
    while wait(0.5) do pcall(function()
        for _, v in pairs(LP.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                SelectWeaponGun = v.Name
            end
        end
        local char = LP.Character
        if char then
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                    SelectWeaponGun = v.Name
                end
            end
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  AUTO HAKI (Buso)
-- ════════════════════════════════════════════════════════
spawn(function()
    while task.wait(0.1) do pcall(function()
        if not CFG.AutoHaki then return end
        local char = LP.Character
        if char and not char:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  FAST ATTACK
-- ════════════════════════════════════════════════════════
spawn(function()
    local Net    = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
    local RegAtk = Net:WaitForChild("RE/RegisterAttack")
    local RegHit = Net:WaitForChild("RE/RegisterHit")

    local function IsAlive(c)
        return c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
    end
    local function Collect(folder)
        local list, base = {}, nil
        if not folder then return list, base end
        for _, e in ipairs(folder:GetChildren()) do
            local head = e:FindFirstChild("Head")
            if head and IsAlive(e) and e ~= LP.Character then
                local d = LP:DistanceFromCharacter(head.Position)
                if d < 100 then table.insert(list,{e,head}); base = head end
            end
        end
        return list, base
    end

    while true do
        if not CFG.FastAttack then task.wait(0.05); continue end
        task.wait(CFG.FastAtkDelay)
        local char = LP.Character; if not char then continue end
        local eList, b1 = Collect(workspace:FindFirstChild("Enemies"))
        local cList, b2 = Collect(workspace:FindFirstChild("Characters"))
        for _, d in ipairs(cList) do table.insert(eList,d) end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("LeftClickRemote") then
            for _, d in ipairs(eList) do
                local dir = (d[1].HumanoidRootPart.Position - char:GetPivot().Position).Unit
                pcall(function() tool.LeftClickRemote:FireServer(dir,1) end)
            end
        elseif #eList > 0 then
            pcall(function() RegAtk:FireServer(0) end)
            pcall(function() RegHit:FireServer(b1 or b2, eList) end)
        end
    end
end)

-- ════════════════════════════════════════════════════════
--  AIMBOT GUN
-- ════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.AimbotGun then return end
    local t = GetTarget(); if not t then return end
    local pos = GetAimPos(t); if not pos then return end
    local part = GetAimPart(t); if not part then return end
    local char = LP.Character; if not char then return end
    local gun = char:FindFirstChild(SelectWeaponGun)
    if gun and gun:FindFirstChild("RemoteFunctionShoot") then
        pcall(function() gun.RemoteFunctionShoot:InvokeServer(pos, part) end)
    end
end)

-- ════════════════════════════════════════════════════════
--  AIMBOT SKILL
-- ════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not CFG.AimbotSkill then return end
    local t = GetTarget(); if not t then return end
    local pos = GetAimPos(t); if not pos then return end
    local char = LP.Character; if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and char:FindFirstChild(tool.Name) then
        local tr = char[tool.Name]
        if tr:FindFirstChild("MousePos") then
            pcall(function() tr.RemoteEvent:FireServer(pos) end)
        end
    end
end)

-- ════════════════════════════════════════════════════════
--  SILENT AIM
-- ════════════════════════════════════════════════════════
pcall(function()
    local raw = getrawmetatable(game)
    local orig = raw.__namecall
    setreadonly(raw, false)
    raw.__namecall = newcclosure(function(...)
        local method = getnamecallmethod()
        local args = {...}
        if CFG.SilentAim and method == "FireServer" then
            local t = GetTarget()
            if t then
                local pos = GetAimPos(t)
                if pos then
                    for i,v in ipairs(args) do
                        if typeof(v) == "Vector3" then args[i] = pos end
                    end
                end
            end
        end
        return orig(unpack(args))
    end)
    setreadonly(raw, true)
end)

-- ════════════════════════════════════════════════════════
--  CAMLOCK
-- ════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not CFG.CamLock then return end
    local t = GetTarget()
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        Cam.CFrame = CFrame.new(Cam.CFrame.Position, t.Character.HumanoidRootPart.Position)
    end
end)

-- ════════════════════════════════════════════════════════
--  ESP PLAYER
-- ════════════════════════════════════════════════════════
spawn(function()
    while wait(0.35) do pcall(function()
        for _, v in ipairs(Players:GetPlayers()) do
            if v == LP then continue end
            if not v.Character then continue end
            local head = v.Character:FindFirstChild("Head")
            if not head then continue end

            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local dist = myRoot and (head.Position - myRoot.Position).Magnitude or math.huge

            if CFG.ESPPlayer and dist <= CFG.ESPRange then
                if not head:FindFirstChild("BESP_"..ESPTag) then
                    local bg = Instance.new("BillboardGui", head)
                    bg.Name = "BESP_"..ESPTag
                    bg.AlwaysOnTop = true
                    bg.Size = UDim2.new(0,200,0,58)
                    bg.StudsOffset = Vector3.new(0,3.2,0)

                    local nl = Instance.new("TextLabel", bg)
                    nl.Name = "NL"; nl.Size = UDim2.new(1,0,0,20)
                    nl.BackgroundTransparency = 1; nl.Font = Enum.Font.GothamBold
                    nl.TextSize = 13; nl.TextStrokeTransparency = 0.2
                    nl.TextStrokeColor3 = Color3.new(0,0,0)

                    local il = Instance.new("TextLabel", bg)
                    il.Name = "IL"; il.Size = UDim2.new(1,0,0,14)
                    il.Position = UDim2.new(0,0,0,20)
                    il.BackgroundTransparency = 1; il.Font = Enum.Font.Gotham
                    il.TextSize = 11; il.TextColor3 = Color3.fromRGB(180,180,180)
                    il.TextStrokeTransparency = 0.3
                    il.TextStrokeColor3 = Color3.new(0,0,0)

                    local barBg = Instance.new("Frame", bg)
                    barBg.Name = "BB"; barBg.Size = UDim2.new(0.8,0,0,5)
                    barBg.Position = UDim2.new(0.1,0,0,38)
                    barBg.BackgroundColor3 = Color3.fromRGB(30,30,30); barBg.BorderSizePixel = 0
                    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

                    local barFill = Instance.new("Frame", barBg)
                    barFill.Name = "BF"; barFill.Size = UDim2.new(1,0,1,0)
                    barFill.BorderSizePixel = 0; barFill.BackgroundColor3 = Color3.fromRGB(60,220,60)
                    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)
                end

                local esp = head:FindFirstChild("BESP_"..ESPTag)
                if esp then
                    local hum = v.Character:FindFirstChild("Humanoid")
                    local hp  = hum and math.clamp(hum.Health/hum.MaxHealth,0,1) or 0
                    local col = TeamColor(v)
                    esp.NL.Text       = v.Name.."  [Lv."..GetLevel(v).."]"
                    esp.NL.TextColor3 = col
                    esp.IL.Text       = M(dist).."m  ·  "..math.floor(hp*100).."%"
                    local bf = esp.BB:FindFirstChild("BF")
                    if bf then
                        bf.Size = UDim2.new(hp,0,1,0)
                        bf.BackgroundColor3 = hp > 0.6
                            and Color3.fromRGB(55,210,55)
                            or  hp > 0.3 and Color3.fromRGB(230,185,0)
                            or  Color3.fromRGB(215,45,45)
                    end
                end
            else
                local esp = head:FindFirstChild("BESP_"..ESPTag)
                if esp then esp:Destroy() end
            end
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  WALK ON WATER
-- ════════════════════════════════════════════════════════
spawn(function()
    while wait(1) do pcall(function()
        local p = workspace.Map:FindFirstChild("WaterBase-Plane")
        if p then
            p.Size = CFG.WalkWater and Vector3.new(1000,112,1000) or Vector3.new(1000,80,1000)
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  SPEED HACK
-- ════════════════════════════════════════════════════════
spawn(function()
    while task.wait(0.1) do pcall(function()
        local char = LP.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if not hum then return end
        if CFG.SpeedHack then
            hum.WalkSpeed = CFG.WalkSpeed
        else
            if hum.WalkSpeed == CFG.WalkSpeed then
                hum.WalkSpeed = 16
            end
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  SAFE MODE
-- ════════════════════════════════════════════════════════
spawn(function()
    while task.wait(0.1) do pcall(function()
        if not CFG.SafeMode then return end
        local char = LP.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local threshold = (CFG.SafeHPThresh / 100) * hum.MaxHealth
            if hum.Health <= threshold then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 200, 0)
            end
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  AUTO V3 / V4
-- ════════════════════════════════════════════════════════
spawn(function()
    while wait(0.5) do pcall(function()
        if CFG.AutoV3 then
            ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
        end
        if CFG.AutoV4 then
            VirtualInput:SendKeyEvent(true,  "Y", false, game)
            task.wait(0.05)
            VirtualInput:SendKeyEvent(false, "Y", false, game)
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  HIGH PERFORMANCE (logic from original Matsune script)
-- ════════════════════════════════════════════════════════
local function ApplyHighPerf()
    settings().Rendering.QualityLevel = "Level01"
    for _, v in ipairs(game:GetDescendants()) do
        pcall(function()
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1; v.BlastRadius = 1
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end)
    end
    Lighting.FogEnd = 9e9
    pcall(function() Lighting:FindFirstChildOfClass("Atmosphere"):Destroy() end)
    pcall(function() Lighting:FindFirstChildOfClass("BloomEffect"):Destroy() end)
    pcall(function() Lighting:FindFirstChildOfClass("BlurEffect"):Destroy() end)
    pcall(function() Lighting:FindFirstChildOfClass("DepthOfFieldEffect"):Destroy() end)
    pcall(function() Lighting:FindFirstChildOfClass("SunRaysEffect"):Destroy() end)
end

spawn(function()
    while wait(5) do
        if CFG.HighPerf then pcall(ApplyHighPerf) end
    end
end)

-- ════════════════════════════════════════════════════════════════════════
--  ██╗   ██╗██╗
--  ██║   ██║██║
--  ██║   ██║██║
--  ██║   ██║██║
--  ╚██████╔╝██║
--   ╚═════╝ ╚═╝
--  BLACK-PURPLE GLASS LIQUID  ·  FUTURISTIC
-- ════════════════════════════════════════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "BunniR_v2"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if syn then syn.protect_gui(gui) end; gui.Parent = game.CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

-- ── Palette ───────────────────────────────────────────────────────────────
local P = {
    void        = Color3.fromRGB(4,   4,   8),     -- near-black bg
    glass       = Color3.fromRGB(14,  10,  24),    -- dark glass panel
    glassEdge   = Color3.fromRGB(28,  16,  52),    -- panel border
    purpleDeep  = Color3.fromRGB(88,  30, 180),    -- primary purple
    purpleMid   = Color3.fromRGB(130,  50, 230),   -- mid purple glow
    purpleGlow  = Color3.fromRGB(175,  80, 255),   -- bright purple
    crimson     = Color3.fromRGB(200,  30,  60),   -- accent red (logo crosshair)
    white       = Color3.fromRGB(235, 230, 255),   -- near-white with purple tint
    muted       = Color3.fromRGB(110, 100, 140),   -- muted text
    rowBg       = Color3.fromRGB(10,   8,  20),    -- toggle row bg
    onColor     = Color3.fromRGB(160,  50, 255),   -- toggle ON
    offColor    = Color3.fromRGB(30,   25,  50),   -- toggle OFF
}

-- ── Drag helper ───────────────────────────────────────────────────────────
local function Draggable(frame, handle)
    local drag, dIn, dSt, dPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; dSt = i.Position; dPos = frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then dIn = i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i == dIn then
            local d = i.Position - dSt
            frame.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X, dPos.Y.Scale, dPos.Y.Offset+d.Y)
        end
    end)
end

-- ── Glow helper ───────────────────────────────────────────────────────────
local function AddStroke(parent, color, thick)
    local s = Instance.new("UIStroke", parent)
    s.Color = color; s.Thickness = thick or 1; s.Transparency = 0.1
    return s
end

local function GlowCorner(parent, r)
    Instance.new("UICorner", parent).CornerRadius = UDim.new(0, r or 8)
end

-- ── Main window ───────────────────────────────────────────────────────────
local WIN = Instance.new("Frame", gui)
WIN.Name = "Win"
WIN.Size = UDim2.new(0, 250, 0, 420)
WIN.Position = UDim2.new(0.03, 0, 0.2, 0)
WIN.BackgroundColor3 = P.glass
WIN.BorderSizePixel = 0
WIN.ClipsDescendants = false
GlowCorner(WIN, 12)
AddStroke(WIN, P.purpleDeep, 1.5)

-- Outer glow frame (purely decorative, slightly larger, very transparent)
local outerGlow = Instance.new("Frame", gui)
outerGlow.Size = UDim2.new(0, 262, 0, 432)
outerGlow.Position = UDim2.new(0, 0, 0, 0)   -- repositioned below
outerGlow.BackgroundColor3 = P.purpleMid
outerGlow.BackgroundTransparency = 0.88
outerGlow.BorderSizePixel = 0
outerGlow.ZIndex = 0
GlowCorner(outerGlow, 14)
-- Keep glow aligned with WIN
WIN:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    outerGlow.Position = UDim2.new(0,
        WIN.AbsolutePosition.X - 6,
        0,
        WIN.AbsolutePosition.Y - 6)
end)

-- ── Header bar ────────────────────────────────────────────────────────────
local HDR = Instance.new("Frame", WIN)
HDR.Name = "HDR"
HDR.Size = UDim2.new(1, 0, 0, 46)
HDR.BackgroundColor3 = P.glassEdge
HDR.BorderSizePixel = 0
GlowCorner(HDR, 12)
Draggable(WIN, HDR)

-- Thin purple line under header
local hdrLine = Instance.new("Frame", HDR)
hdrLine.Size = UDim2.new(1, -24, 0, 1)
hdrLine.Position = UDim2.new(0, 12, 1, 0)
hdrLine.BackgroundColor3 = P.purpleMid
hdrLine.BackgroundTransparency = 0.4
hdrLine.BorderSizePixel = 0

-- Bunny logo icon
local logoLbl = Instance.new("TextLabel", HDR)
logoLbl.Size = UDim2.new(0, 34, 0, 34)
logoLbl.Position = UDim2.new(0, 8, 0.5, -17)
logoLbl.BackgroundTransparency = 1
logoLbl.Text = "🐰"
logoLbl.TextSize = 24
logoLbl.Font = Enum.Font.GothamBold
logoLbl.TextColor3 = P.white

local titleLbl = Instance.new("TextLabel", HDR)
titleLbl.Size = UDim2.new(1, -80, 0, 18)
titleLbl.Position = UDim2.new(0, 46, 0, 6)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BUNNI_R"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 15
titleLbl.TextColor3 = P.white
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local subLbl = Instance.new("TextLabel", HDR)
subLbl.Size = UDim2.new(1, -80, 0, 13)
subLbl.Position = UDim2.new(0, 46, 0, 26)
subLbl.BackgroundTransparency = 1
subLbl.Text = "PVP SUITE  ·  v2.0"
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 9
subLbl.TextColor3 = P.muted
subLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Minimise
local MINBTN = Instance.new("TextButton", HDR)
MINBTN.Size = UDim2.new(0, 26, 0, 26)
MINBTN.Position = UDim2.new(1, -32, 0.5, -13)
MINBTN.BackgroundColor3 = Color3.fromRGB(22, 16, 40)
MINBTN.Text = "−"; MINBTN.Font = Enum.Font.GothamBold
MINBTN.TextSize = 16; MINBTN.TextColor3 = P.muted
MINBTN.BorderSizePixel = 0
GlowCorner(MINBTN, 5)
AddStroke(MINBTN, P.purpleDeep, 1)

-- ── Target pill ───────────────────────────────────────────────────────────
local TGT = Instance.new("Frame", WIN)
TGT.Size = UDim2.new(1, -16, 0, 26)
TGT.Position = UDim2.new(0, 8, 0, 52)
TGT.BackgroundColor3 = P.rowBg
TGT.BorderSizePixel = 0
GlowCorner(TGT, 6)
AddStroke(TGT, P.purpleDeep, 1)

local tgtDot = Instance.new("Frame", TGT)
tgtDot.Size = UDim2.new(0, 7, 0, 7)
tgtDot.Position = UDim2.new(0, 10, 0.5, -3.5)
tgtDot.BackgroundColor3 = P.crimson
tgtDot.BorderSizePixel = 0
GlowCorner(tgtDot, 4)

local tgtLbl = Instance.new("TextLabel", TGT)
tgtLbl.Size = UDim2.new(1, -30, 1, 0)
tgtLbl.Position = UDim2.new(0, 24, 0, 0)
tgtLbl.BackgroundTransparency = 1
tgtLbl.Text = "No target in range"
tgtLbl.Font = Enum.Font.GothamSemibold
tgtLbl.TextSize = 10
tgtLbl.TextColor3 = P.muted
tgtLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Pulse the dot when target found
local dotPulsing = false
local function PulseDot(on)
    if on and not dotPulsing then
        dotPulsing = true
        spawn(function()
            while dotPulsing do
                TweenService:Create(tgtDot,TweenInfo.new(0.5),{BackgroundTransparency=0.7}):Play()
                wait(0.5)
                TweenService:Create(tgtDot,TweenInfo.new(0.5),{BackgroundTransparency=0}):Play()
                wait(0.5)
            end
            tgtDot.BackgroundTransparency = 0
        end)
    elseif not on then
        dotPulsing = false
    end
end

spawn(function()
    while wait(0.25) do pcall(function()
        local t = GetTarget()
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local myR = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local d = myR and M((t.Character.HumanoidRootPart.Position-myR.Position).Magnitude) or 0
            tgtLbl.Text = t.Name.."  [Lv."..GetLevel(t).."]  "..d.."m"
            tgtLbl.TextColor3 = TeamColor(t)
            PulseDot(true)
        else
            tgtLbl.Text = "No target in range"
            tgtLbl.TextColor3 = P.muted
            PulseDot(false)
        end
    end) end
end)

-- ── Tab bar ───────────────────────────────────────────────────────────────
local TAB_BAR = Instance.new("Frame", WIN)
TAB_BAR.Size = UDim2.new(1, -16, 0, 28)
TAB_BAR.Position = UDim2.new(0, 8, 0, 84)
TAB_BAR.BackgroundColor3 = P.rowBg
TAB_BAR.BorderSizePixel = 0
GlowCorner(TAB_BAR, 7)
AddStroke(TAB_BAR, P.glassEdge, 1)

local tabList = Instance.new("UIListLayout", TAB_BAR)
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 2)
Instance.new("UIPadding", TAB_BAR).PaddingLeft = UDim.new(0, 3)

-- ── Content pages ─────────────────────────────────────────────────────────
local PAGES = Instance.new("Frame", WIN)
PAGES.Size = UDim2.new(1, 0, 1, -120)
PAGES.Position = UDim2.new(0, 0, 0, 118)
PAGES.BackgroundTransparency = 1
PAGES.ClipsDescendants = true

local function MakePage()
    local scroll = Instance.new("ScrollingFrame", PAGES)
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = P.purpleMid
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Visible = false
    local sl = Instance.new("UIListLayout", scroll)
    sl.Padding = UDim.new(0, 3)
    sl.SortOrder = Enum.SortOrder.LayoutOrder
    local sp = Instance.new("UIPadding", scroll)
    sp.PaddingLeft = UDim.new(0,8); sp.PaddingRight = UDim.new(0,8)
    sp.PaddingTop = UDim.new(0,6); sp.PaddingBottom = UDim.new(0,8)
    sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0, sl.AbsoluteContentSize.Y+14)
    end)
    return scroll
end

local tabPages = {}
local tabBtns  = {}
local tabNames = {"COMBAT","UTIL","SETTINGS"}
local curTab   = 1

for i, name in ipairs(tabNames) do
    tabPages[i] = MakePage()

    local tb = Instance.new("TextButton", TAB_BAR)
    tb.Size = UDim2.new(0, 70, 1, -4)
    tb.Position = UDim2.new(0, 0, 0, 2)
    tb.BackgroundColor3 = i==1 and P.purpleDeep or Color3.fromRGB(0,0,0)
    tb.BackgroundTransparency = i==1 and 0 or 1
    tb.Text = name
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 9
    tb.TextColor3 = i==1 and P.white or P.muted
    tb.BorderSizePixel = 0
    tb.LayoutOrder = i
    GlowCorner(tb, 5)
    tabBtns[i] = tb

    tb.MouseButton1Click:Connect(function()
        curTab = i
        for j, p in ipairs(tabPages) do
            p.Visible = j == i
            tabBtns[j].BackgroundColor3 = j==i and P.purpleDeep or Color3.fromRGB(0,0,0)
            tabBtns[j].BackgroundTransparency = j==i and 0 or 1
            tabBtns[j].TextColor3 = j==i and P.white or P.muted
        end
    end)
end
tabPages[1].Visible = true

-- ── Component builders ────────────────────────────────────────────────────
local orderN = 0
local function O() orderN=orderN+1; return orderN end

local function Section(page, label)
    local f = Instance.new("Frame", page)
    f.Size = UDim2.new(1,0,0,18); f.BackgroundTransparency=1; f.LayoutOrder=O()
    local l = Instance.new("TextLabel",f)
    l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text = label:upper()
    l.Font = Enum.Font.GothamBold; l.TextSize=9
    l.TextColor3 = P.purpleGlow
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function Toggle(page, label, cfgKey, cb)
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1,0,0,30)
    row.BackgroundColor3 = P.rowBg
    row.BorderSizePixel=0; row.LayoutOrder=O()
    GlowCorner(row,6)

    local lbl = Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
    lbl.TextColor3=P.white; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local pill = Instance.new("Frame",row)
    pill.Size=UDim2.new(0,34,0,17); pill.Position=UDim2.new(1,-42,0.5,-8.5)
    pill.BackgroundColor3=P.offColor; pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local knob = Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,12,0,12); knob.Position=UDim2.new(0,2,0.5,-6)
    knob.BackgroundColor3=P.muted; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local hit = Instance.new("TextButton",row)
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""

    local on = false
    hit.MouseButton1Click:Connect(function()
        on = not on; CFG[cfgKey] = on
        TweenService:Create(pill,TweenInfo.new(0.14),{
            BackgroundColor3 = on and P.onColor or P.offColor}):Play()
        TweenService:Create(knob,TweenInfo.new(0.14),{
            Position = on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6),
            BackgroundColor3 = on and P.purpleGlow or P.muted}):Play()
        if cb then cb(on) end
    end)
end

-- Slider builder
local function Slider(page, label, cfgKey, minV, maxV, fmt, cb)
    local f = Instance.new("Frame", page)
    f.Size=UDim2.new(1,0,0,44); f.BackgroundColor3=P.rowBg
    f.BorderSizePixel=0; f.LayoutOrder=O()
    GlowCorner(f,6)

    local top = Instance.new("Frame",f)
    top.Size=UDim2.new(1,0,0,20); top.BackgroundTransparency=1

    local namL = Instance.new("TextLabel",top)
    namL.Size=UDim2.new(1,-50,1,0); namL.Position=UDim2.new(0,10,0,0)
    namL.BackgroundTransparency=1; namL.Text=label
    namL.Font=Enum.Font.Gotham; namL.TextSize=10
    namL.TextColor3=P.white; namL.TextXAlignment=Enum.TextXAlignment.Left

    local valL = Instance.new("TextLabel",top)
    valL.Size=UDim2.new(0,46,1,0); valL.Position=UDim2.new(1,-50,0,0)
    valL.BackgroundTransparency=1
    local function fmtVal(v)
        return fmt and string.format(fmt,v) or tostring(v)
    end
    valL.Text=fmtVal(CFG[cfgKey])
    valL.Font=Enum.Font.GothamBold; valL.TextSize=10
    valL.TextColor3=P.purpleGlow; valL.TextXAlignment=Enum.TextXAlignment.Right

    local track = Instance.new("Frame",f)
    track.Size=UDim2.new(1,-20,0,5); track.Position=UDim2.new(0,10,0,28)
    track.BackgroundColor3=Color3.fromRGB(30,22,52); track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local fill = Instance.new("Frame",track)
    fill.Size=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=P.purpleMid; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local knob = Instance.new("Frame",track)
    knob.Size=UDim2.new(0,13,0,13); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=P.purpleGlow; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    AddStroke(knob,P.purpleDeep,1)

    local dragging=false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    knob.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local rel=math.clamp(
                (i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local val=math.floor(minV+rel*(maxV-minV))
            CFG[cfgKey]=val
            fill.Size=UDim2.new(rel,0,1,0)
            knob.Position=UDim2.new(rel,0,0.5,0)
            valL.Text=fmtVal(val)
            if cb then cb(val) end
        end
    end)
end

-- Dropdown (two-option picker)
local function Dropdown(page, label, cfgKey, opts, cb)
    local f = Instance.new("Frame",page)
    f.Size=UDim2.new(1,0,0,30); f.BackgroundColor3=P.rowBg
    f.BorderSizePixel=0; f.LayoutOrder=O()
    GlowCorner(f,6)

    local lbl = Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(0.5,-4,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=10
    lbl.TextColor3=P.white; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local selIdx = 1
    for i,o in ipairs(opts) do if o==CFG[cfgKey] then selIdx=i end end

    local optBtns = {}
    local totalW = (1/(#opts))
    for i, opt in ipairs(opts) do
        local btn = Instance.new("TextButton",f)
        btn.Size=UDim2.new(0, 62, 0, 20)
        btn.Position=UDim2.new(1, -10 - (62*(#opts-i+1)) + (4*(#opts-i)), 0.5, -10)
        btn.BackgroundColor3= i==selIdx and P.purpleDeep or Color3.fromRGB(18,12,35)
        btn.BackgroundTransparency= i==selIdx and 0 or 0
        btn.Text=opt; btn.Font=Enum.Font.GothamBold; btn.TextSize=9
        btn.TextColor3= i==selIdx and P.white or P.muted
        btn.BorderSizePixel=0
        GlowCorner(btn,4)
        optBtns[i]=btn
        btn.MouseButton1Click:Connect(function()
            selIdx=i; CFG[cfgKey]=opt
            for j,b in ipairs(optBtns) do
                TweenService:Create(b,TweenInfo.new(0.1),{
                    BackgroundColor3=j==i and P.purpleDeep or Color3.fromRGB(18,12,35),
                    BackgroundTransparency=0}):Play()
                b.TextColor3=j==i and P.white or P.muted
            end
            if cb then cb(opt) end
        end)
    end
end

-- ── COMBAT tab ─────────────────────────────────────────────────────────
local CP = tabPages[1]
Section(CP, "⚡  Aimbot")
Toggle(CP,  "Auto Target Nearest",  "AutoTarget")
Toggle(CP,  "Aimbot Gun",           "AimbotGun")
Toggle(CP,  "Aimbot Skill",         "AimbotSkill")
Toggle(CP,  "Silent Aim",           "SilentAim")
Toggle(CP,  "CamLock",              "CamLock")
Toggle(CP,  "Fast Attack  (M1)",    "FastAttack")

Section(CP, "👁  ESP")
Toggle(CP,  "Player ESP",           "ESPPlayer")

Section(CP, "🥋  Combat")
Toggle(CP,  "Auto Haki (Buso)",     "AutoHaki")
Toggle(CP,  "Auto V3",              "AutoV3")
Toggle(CP,  "Auto V4",              "AutoV4")

-- ── UTIL tab ──────────────────────────────────────────────────────────
local UP = tabPages[2]
Section(UP, "🛡  Movement")
Toggle(UP,  "Walk on Water",        "WalkWater")
Toggle(UP,  "Speed Hack",           "SpeedHack")

Section(UP, "🛡  Safety")
Toggle(UP,  "Safe Mode",            "SafeMode")
Toggle(UP,  "High Performance",     "HighPerf", function(on)
    if on then spawn(function() pcall(ApplyHighPerf) end) end
end)

-- ── SETTINGS tab ──────────────────────────────────────────────────────
local SP2 = tabPages[3]
Section(SP2, "🎯  Aimbot")
Dropdown(SP2, "Target Part",  "AimbotTarget", {"HRP","Head"})
Slider(SP2,   "ESP Range",    "ESPRange",     50, 1000, "%dm")
Slider(SP2,   "Atk Delay",    "FastAtkDelay", 0,  1,   "%.2fs")

Section(SP2, "🏃  Movement")
Slider(SP2,   "Walk Speed",   "WalkSpeed",    16, 250, "%d")
Slider(SP2,   "Jump Power",   "JumpPower",    50, 500, "%d")

Section(SP2, "🛡  Thresholds")
Slider(SP2,   "Safe HP %",    "SafeHPThresh", 5,  80,  "%d%%")

-- ── Minimise ──────────────────────────────────────────────────────────
local mini = false
MINBTN.MouseButton1Click:Connect(function()
    mini = not mini
    local newSize = mini and UDim2.new(0,250,0,46) or UDim2.new(0,250,0,420)
    TweenService:Create(WIN,TweenInfo.new(0.2,Enum.EasingStyle.Quart),{Size=newSize}):Play()
    MINBTN.Text = mini and "+" or "−"
end)

-- ════════════════════════════════════════════════════════════════════════
--  FLOATING JUMP BUTTON  (top-right, draggable circle)
-- ════════════════════════════════════════════════════════════════════════
local JWIN = Instance.new("Frame", gui)
JWIN.Size = UDim2.new(0, 58, 0, 58)
JWIN.Position = UDim2.new(1, -70, 0, 10)
JWIN.BackgroundColor3 = P.glass
JWIN.BorderSizePixel = 0
GlowCorner(JWIN, 29)  -- full circle
AddStroke(JWIN, P.purpleMid, 1.5)
Draggable(JWIN, JWIN)

-- Inner glow ring
local innerRing = Instance.new("Frame", JWIN)
innerRing.Size = UDim2.new(0, 44, 0, 44)
innerRing.Position = UDim2.new(0.5, -22, 0.5, -22)
innerRing.BackgroundTransparency = 1
innerRing.BorderSizePixel = 0
GlowCorner(innerRing, 22)
AddStroke(innerRing, P.purpleDeep, 1)

local jIcon = Instance.new("TextLabel", JWIN)
jIcon.Size = UDim2.new(1, 0, 0.6, 0)
jIcon.Position = UDim2.new(0, 0, 0.05, 0)
jIcon.BackgroundTransparency = 1
jIcon.Text = "↑"
jIcon.Font = Enum.Font.GothamBold
jIcon.TextSize = 24
jIcon.TextColor3 = P.purpleGlow

local jTxt = Instance.new("TextLabel", JWIN)
jTxt.Size = UDim2.new(1, 0, 0, 14)
jTxt.Position = UDim2.new(0, 0, 1, -15)
jTxt.BackgroundTransparency = 1
jTxt.Text = "JUMP"
jTxt.Font = Enum.Font.GothamBold
jTxt.TextSize = 8
jTxt.TextColor3 = P.muted

local jBtn = Instance.new("TextButton", JWIN)
jBtn.Size = UDim2.new(1,0,1,0); jBtn.BackgroundTransparency=1; jBtn.Text=""

jBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local char = LP.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local orig = hum.JumpPower
            hum.JumpPower = CFG.JumpPower
            hum.Jump = true
            task.wait(0.15)
            hum.JumpPower = orig
        end
    end)
    -- Pulse animation on click
    TweenService:Create(JWIN, TweenInfo.new(0.08),
        {BackgroundColor3=P.purpleDeep}):Play()
    task.wait(0.12)
    TweenService:Create(JWIN, TweenInfo.new(0.25),
        {BackgroundColor3=P.glass}):Play()
end)

-- Hover glow effect
JWIN.MouseEnter:Connect(function()
    TweenService:Create(JWIN,TweenInfo.new(0.15),
        {BackgroundColor3=Color3.fromRGB(22,14,44)}):Play()
end)
JWIN.MouseLeave:Connect(function()
    TweenService:Create(JWIN,TweenInfo.new(0.15),
        {BackgroundColor3=P.glass}):Play()
end)

-- Footer label inside WIN (very bottom)
local footer = Instance.new("TextLabel", WIN)
footer.Size = UDim2.new(1,0,0,14)
footer.Position = UDim2.new(0,0,1,-14)
footer.BackgroundTransparency = 1
footer.Text = "github.com/rhoscript/BUNNI_R"
footer.Font = Enum.Font.Gotham; footer.TextSize = 8
footer.TextColor3 = Color3.fromRGB(35,28,55)
footer.TextXAlignment = Enum.TextXAlignment.Center
