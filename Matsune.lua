-- ╔══════════════════════════════════════════════════════╗
-- ║   BUNNI_R  ·  Matsune PVP  ·  v3.0                  ║
-- ║   Black-Purple Glass  ·  Futuristic  ·  Lightweight  ║
-- ╚══════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput      = game:GetService("VirtualInputManager")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local ESPTag = math.random(1, 999999)

-- ════════════════════════════════════════════════════════
--  CONFIG
-- ════════════════════════════════════════════════════════
local CFG = {
    -- Toggles
    AimbotGun       = false,
    AimbotSkill     = false,
    SilentAim       = false,
    CamLock         = false,
    FastAttack      = false,
    ESPPlayer       = false,
    WalkWater       = false,
    NoClip          = false,
    SpeedHack       = false,
    SafeMode        = false,
    AutoHaki        = false,
    AutoV3          = false,
    AutoV4          = false,
    HighPerf        = false,

    -- Values
    JumpPower       = 120,
    WalkSpeed       = 80,
    ESPRange        = 500,
    FastAtkDelay    = 0,
    SafeHPThresh    = 30,
    AimbotTarget    = "HRP",   -- "HRP" | "Head"
    TargetMode      = "Nearest Enemy",  -- "Nearest Enemy" | "Specific Player"
    SpecificPlayer  = nil,
}

local SelectWeaponGun = ""

-- ════════════════════════════════════════════════════════
--  GUI PARENT (CoreGui safe)
-- ════════════════════════════════════════════════════════
local function GetGuiParent()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    return ok and cg or LP:WaitForChild("PlayerGui")
end

-- ════════════════════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════════════════════
local function M(s) return math.floor(s * 0.28) end

-- Check safe-zone / force-field (from QuixHub)
local function InSafeZone()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local main = pg:FindFirstChild("Main")
        if main then
            local sz = main:FindFirstChild("SafeZone")
            if sz and sz.Visible then return true end
        end
    end
    if LP.Character and LP.Character:FindFirstChildOfClass("ForceField") then return true end
    return false
end

-- Validate player as valid target (team-check from QuixHub)
local function IsValidTarget(p)
    if not p or not p.Character then return false end
    local hum = p.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if InSafeZone() then return false end
    if p.Character:FindFirstChildOfClass("ForceField") then return false end
    -- same-team marines friendly fire protection
    if LP.Team and p.Team then
        if tostring(LP.Team) == "Marines" and tostring(p.Team) == "Marines" then
            return false
        end
    end
    return true
end

-- Get nearest valid target (QuixHub logic, with ESPRange cap)
local function GetNearest()
    if InSafeZone() then return nil end
    local myChar = LP.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    if CFG.TargetMode == "Specific Player" and CFG.SpecificPlayer then
        local p = Players:FindFirstChild(CFG.SpecificPlayer)
        if p and IsValidTarget(p) and p.Character:FindFirstChild("HumanoidRootPart") then
            return p.Character.HumanoidRootPart
        end
        return nil
    end

    local bestDist, bestHRP = math.huge, nil
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LP and IsValidTarget(v) then
            local hrp = v.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestDist and d <= CFG.ESPRange then
                    bestDist = d
                    bestHRP  = hrp
                end
            end
        end
    end
    return bestHRP
end

-- Get nearest character (for safe-mode / bring checks, from QuixHub's u83)
local function GetNearestChar(range)
    local myChar = LP.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local best, bestD = nil, range or 600
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LP and IsValidTarget(v) then
            local hrp = v.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestD then bestD = d; best = v.Character end
            end
        end
    end
    return best
end

local function GetAimPos(hrp)
    if not hrp then return nil end
    if CFG.AimbotTarget == "Head" then
        local head = hrp.Parent and hrp.Parent:FindFirstChild("Head")
        return head and head.Position or hrp.Position
    end
    return hrp.Position
end

local function GetAimPart(hrp)
    if not hrp then return nil end
    if CFG.AimbotTarget == "Head" then
        return hrp.Parent and hrp.Parent:FindFirstChild("Head") or hrp
    end
    return hrp
end

local function GetLevel(p)
    local ok, v = pcall(function() return p.Data.Level.Value end)
    return ok and tostring(v) or "?"
end

local function TeamColor(p)
    local ok, t = pcall(function() return tostring(p.Team) end)
    if not ok then return Color3.fromRGB(180, 180, 180) end
    if t:lower():find("marine") then return Color3.fromRGB(90, 180, 255) end
    if t:lower():find("pirate") then return Color3.fromRGB(255, 70,  70)  end
    return Color3.fromRGB(180, 180, 180)
end

local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 2})
    end)
end

-- ════════════════════════════════════════════════════════
--  GUN TRACKER
-- ════════════════════════════════════════════════════════
spawn(function()
    while wait(0.5) do pcall(function()
        local function scan(c)
            for _, v in pairs(c:GetChildren()) do
                if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                    SelectWeaponGun = v.Name
                end
            end
        end
        scan(LP.Backpack)
        if LP.Character then scan(LP.Character) end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  AUTO HAKI
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
--  SILENT AIM  (from QuixHub – hooks __namecall cleanly)
-- ════════════════════════════════════════════════════════
local _raw = getrawmetatable(game)
local _origNamecall = _raw.__namecall
setreadonly(_raw, false)
_raw.__namecall = newcclosure(function(self, ...)
    local args   = {...}
    local method = getnamecallmethod()
    if CFG.SilentAim and (method == "FireServer" or method == "InvokeServer") then
        local tHRP = GetNearest()
        if tHRP then
            local pos = GetAimPos(tHRP)
            for i, v in ipairs(args) do
                if typeof(v) == "Vector3" then args[i] = pos
                elseif typeof(v) == "CFrame"  then args[i] = CFrame.new(pos) end
            end
        end
    end
    return _origNamecall(self, unpack(args))
end)
setreadonly(_raw, true)

-- ════════════════════════════════════════════════════════
--  CAMLOCK
-- ════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not CFG.CamLock then return end
    local hrp = GetNearest()
    if hrp then Cam.CFrame = CFrame.new(Cam.CFrame.Position, hrp.Position) end
end)

-- ════════════════════════════════════════════════════════
--  AIMBOT GUN
-- ════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.AimbotGun then return end
    local hrp  = GetNearest(); if not hrp then return end
    local char = LP.Character; if not char then return end
    local gun  = char:FindFirstChild(SelectWeaponGun)
    if gun and gun:FindFirstChild("RemoteFunctionShoot") then
        pcall(function()
            gun.RemoteFunctionShoot:InvokeServer(GetAimPos(hrp), GetAimPart(hrp))
        end)
    end
end)

-- ════════════════════════════════════════════════════════
--  AIMBOT SKILL
-- ════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not CFG.AimbotSkill then return end
    local hrp  = GetNearest(); if not hrp then return end
    local char = LP.Character; if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and char:FindFirstChild(tool.Name) then
        local t = char[tool.Name]
        if t:FindFirstChild("MousePos") then
            pcall(function() t.RemoteEvent:FireServer(GetAimPos(hrp)) end)
        end
    end
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
                if LP:DistanceFromCharacter(head.Position) < 100 then
                    table.insert(list, {e, head}); base = head
                end
            end
        end
        return list, base
    end

    while true do
        if not CFG.FastAttack then task.wait(0.05); continue end
        if CFG.FastAtkDelay > 0 then task.wait(CFG.FastAtkDelay) end
        local char = LP.Character; if not char then task.wait(0.05); continue end
        local eList, b1 = Collect(workspace:FindFirstChild("Enemies"))
        local cList, b2 = Collect(workspace:FindFirstChild("Characters"))
        for _, d in ipairs(cList) do table.insert(eList, d) end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("LeftClickRemote") then
            for _, d in ipairs(eList) do
                local dir = (d[1].HumanoidRootPart.Position - char:GetPivot().Position).Unit
                pcall(function() tool.LeftClickRemote:FireServer(dir, 1) end)
            end
        elseif #eList > 0 then
            pcall(function() RegAtk:FireServer(0) end)
            pcall(function() RegHit:FireServer(b1 or b2, eList) end)
        end
        task.wait(0)
    end
end)

-- ════════════════════════════════════════════════════════
--  ESP PLAYER  (QuixHub-style BillboardGui into a Folder)
-- ════════════════════════════════════════════════════════
local espFolder = Instance.new("Folder")
espFolder.Name  = "BunniESP_Folder"
espFolder.Parent = GetGuiParent()

spawn(function()
    while true do
        if not CFG.ESPPlayer then
            espFolder:ClearAllChildren()
            task.wait(0.5)
            continue
        end

        local myChar = LP.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")

        if myHRP then
            for _, v in ipairs(Players:GetPlayers()) do
                if v == LP then continue end
                local char = v.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChild("Humanoid")

                if not hrp or not hum or hum.Health <= 0 then
                    local old = espFolder:FindFirstChild(v.Name)
                    if old then old:Destroy() end
                    continue
                end

                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist > CFG.ESPRange then
                    local old = espFolder:FindFirstChild(v.Name)
                    if old then old:Destroy() end
                    continue
                end

                -- Create or get billboard
                local bg = espFolder:FindFirstChild(v.Name)
                if not bg then
                    bg = Instance.new("BillboardGui", espFolder)
                    bg.Name        = v.Name
                    bg.Size        = UDim2.new(0, 200, 0, 62)
                    bg.StudsOffset = Vector3.new(0, 3.5, 0)
                    bg.AlwaysOnTop = true

                    -- Name + level label
                    local nl = Instance.new("TextLabel", bg)
                    nl.Name = "NL"; nl.Size = UDim2.new(1,0,0,22)
                    nl.BackgroundTransparency = 1
                    nl.Font = Enum.Font.GothamBold; nl.TextSize = 13
                    nl.TextStrokeTransparency = 0.2
                    nl.TextStrokeColor3 = Color3.new(0,0,0)

                    -- Info label (dist + hp%)
                    local il = Instance.new("TextLabel", bg)
                    il.Name = "IL"; il.Size = UDim2.new(1,0,0,14)
                    il.Position = UDim2.new(0,0,0,22)
                    il.BackgroundTransparency = 1
                    il.Font = Enum.Font.Gotham; il.TextSize = 11
                    il.TextColor3 = Color3.fromRGB(180,180,180)
                    il.TextStrokeTransparency = 0.3
                    il.TextStrokeColor3 = Color3.new(0,0,0)

                    -- HP bar bg
                    local bb = Instance.new("Frame", bg)
                    bb.Name = "BB"; bb.Size = UDim2.new(0.82, 0, 0, 5)
                    bb.Position = UDim2.new(0.09, 0, 0, 40)
                    bb.BackgroundColor3 = Color3.fromRGB(28,28,28)
                    bb.BorderSizePixel = 0
                    Instance.new("UICorner", bb).CornerRadius = UDim.new(1,0)

                    local bf = Instance.new("Frame", bb)
                    bf.Name = "BF"; bf.Size = UDim2.new(1,0,1,0)
                    bf.BorderSizePixel = 0
                    Instance.new("UICorner", bf).CornerRadius = UDim.new(1,0)
                end

                if bg.Adornee ~= hrp then bg.Adornee = hrp end

                local hp    = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local lvl   = GetLevel(v)
                local col   = TeamColor(v)
                local metres = M(dist)

                -- Same-team marines get green (QuixHub logic)
                if LP.Team and v.Team then
                    if tostring(LP.Team) == "Marines" and tostring(v.Team) == "Marines" then
                        col = Color3.fromRGB(60, 220, 60)
                    end
                end

                bg.NL.Text        = v.Name .. "  [Lv." .. lvl .. "]"
                bg.NL.TextColor3  = col
                bg.IL.Text        = metres .. "m  ·  " .. math.floor(hum.Health) .. " HP  (" .. math.floor(hp*100) .. "%)"
                local bf = bg.BB:FindFirstChild("BF")
                if bf then
                    bf.Size = UDim2.new(hp, 0, 1, 0)
                    bf.BackgroundColor3 = hp > 0.6
                        and Color3.fromRGB(55, 210, 55)
                        or  hp > 0.3 and Color3.fromRGB(230, 185, 0)
                        or  Color3.fromRGB(215, 45, 45)
                end
            end
        end
        task.wait(0.4)
    end
end)

-- ════════════════════════════════════════════════════════
--  WALK ON WATER  (QuixHub smart raycast platform)
-- ════════════════════════════════════════════════════════
local waterPart = Instance.new("Part")
waterPart.Name        = "BunniWaterPlatform"
waterPart.Size        = Vector3.new(30, 1, 30)
waterPart.Anchored    = true
waterPart.Transparency = 1
waterPart.CanCollide  = false
waterPart.Parent      = workspace

spawn(function()
    while task.wait(0.1) do pcall(function()
        if CFG.WalkWater and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local ray = workspace:Raycast(hrp.Position, Vector3.new(0,-100,0), RaycastParams.new())
                if ray and ray.Material == Enum.Material.Water then
                    waterPart.CanCollide = true
                    waterPart.CFrame     = CFrame.new(hrp.Position.X, ray.Position.Y + 0.5, hrp.Position.Z)
                else
                    waterPart.CanCollide = false
                end
            end
        else
            waterPart.CanCollide = false
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  NOCLIP
-- ════════════════════════════════════════════════════════
spawn(function()
    while task.wait() do pcall(function()
        if CFG.NoClip and LP.Character then
            for _, v in ipairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end) end
end)

-- ════════════════════════════════════════════════════════
--  SPEED HACK  (QuixHub Heartbeat delta method)
-- ════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.SpeedHack then return end
    local char = LP.Character; if not char then return end
    local hum  = char:FindFirstChild("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp and hum.MoveDirection.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + hum.MoveDirection * (CFG.WalkSpeed - 16) * 0.02
    end
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
            local thresh = (CFG.SafeHPThresh / 100) * hum.MaxHealth
            if hum.Health <= thresh then
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
--  HIGH PERFORMANCE  (original Matsune + QuixHub FPS boost)
-- ════════════════════════════════════════════════════════
local function ApplyHighPerf()
    settings().Rendering.QualityLevel = "Level01"
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    -- Kill post-effects
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("PostEffect") then e:Destroy() end
    end
    -- Strip particles, decals, shadows
    for _, v in ipairs(game:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke")
                or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("BasePart") then
                v.Material    = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow  = false
            end
        end)
    end
    Notify("High Performance", "FPS Boost Applied!", 2)
end

-- ════════════════════════════════════════════════════════
--  ICE TP & KILL  (ported from QuixHub u98)
-- ════════════════════════════════════════════════════════
local function IceTPKill()
    local nearChar = GetNearestChar(600)
    if nearChar and nearChar:FindFirstChild("HumanoidRootPart") then
        local myChar = LP.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            myChar.HumanoidRootPart.CFrame = nearChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            local bp  = LP.Backpack
            local hum = myChar:FindFirstChild("Humanoid")
            -- Try ice fruit first
            local ice = bp:FindFirstChild("Ice-Ice") or bp:FindFirstChild("Ice")
                or myChar:FindFirstChild("Ice-Ice") or myChar:FindFirstChild("Ice")
            if ice then
                hum:EquipTool(ice); task.wait(0.1)
                VirtualInput:SendKeyEvent(true,  Enum.KeyCode.V, false, game)
                task.wait(0.05)
                VirtualInput:SendKeyEvent(false, Enum.KeyCode.V, false, game)
            else
                -- Fallback: equip any non-special tool
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and t.Name ~= "❄️ Ice TP & Kill"
                        and t.Name ~= "Combat" and t.Name ~= "Godhuman" then
                        hum:EquipTool(t); break
                    end
                end
            end
        end
    else
        Notify("Ice TP", "No enemy within 600m!", 2)
    end
end

-- ════════════════════════════════════════════════════════
--  CLICK-TO-TP TOOL  (from QuixHub)
-- ════════════════════════════════════════════════════════
local function GiveTPTool()
    local tool = Instance.new("Tool", LP.Backpack)
    tool.Name = "Bunni TP"; tool.RequiresHandle = false
    tool.Activated:Connect(function()
        local m = LP:GetMouse()
        if m.Hit and LP.Character then
            LP.Character.HumanoidRootPart.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0,5,0))
        end
    end)
    Notify("Tool Added", "Bunni TP in backpack!", 2)
end

-- ════════════════════════════════════════════════════════════════════════
--  ██╗   ██╗██╗
--  ██║   ██║██║     BLACK·PURPLE GLASS LIQUID
--  ██║   ██║██║     FUTURISTIC · MINIMAL · FAST
--  ╚██████╔╝██║
--   ╚═════╝ ╚═╝
-- ════════════════════════════════════════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "BunniR_v3"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    if syn then syn.protect_gui(gui) end
    gui.Parent = GetGuiParent()
end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

-- ── Palette ──────────────────────────────────────────────────────────────
local P = {
    bg          = Color3.fromRGB(6,   4,  14),
    glass       = Color3.fromRGB(13,  9,  26),
    glassEdge   = Color3.fromRGB(26,  16,  52),
    sidebar     = Color3.fromRGB(9,   6,  20),
    item        = Color3.fromRGB(17,  12,  34),
    itemHover   = Color3.fromRGB(24,  17,  46),
    accent      = Color3.fromRGB(180,  50, 255),
    accentDim   = Color3.fromRGB(90,   25, 130),
    accentGlow  = Color3.fromRGB(210,  90, 255),
    red         = Color3.fromRGB(220,  40,  60),
    green       = Color3.fromRGB(55,  210,  80),
    white       = Color3.fromRGB(230, 220, 255),
    muted       = Color3.fromRGB(100,  85, 140),
    scrollBar   = Color3.fromRGB(120,  40, 200),
    onPill      = Color3.fromRGB(150,  40, 240),
    offPill     = Color3.fromRGB(30,   22,  55),
    knobOn      = Color3.fromRGB(220, 180, 255),
    knobOff     = Color3.fromRGB(80,   65, 110),
}

-- ── Utilities ─────────────────────────────────────────────────────────────
local function Corner(f, r) Instance.new("UICorner",f).CornerRadius = UDim.new(0, r or 6) end
local function Stroke(f, c, t)
    local s = Instance.new("UIStroke",f)
    s.Color = c or P.accentDim; s.Thickness = t or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end
local function Pad(f, l, r, t, b)
    local p = Instance.new("UIPadding",f)
    p.PaddingLeft   = UDim.new(0, l or 0); p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingTop    = UDim.new(0, t or 0); p.PaddingBottom = UDim.new(0, b or 0)
end
local function List(f, dir, pad, sort)
    local l = Instance.new("UIListLayout",f)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder     = sort or Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, pad or 4)
    return l
end

local function Draggable(frame, handle)
    local drag, dIn, dSt, dPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; dSt=i.Position; dPos=frame.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then dIn=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i==dIn then
            local d=i.Position-dSt
            frame.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,dPos.Y.Scale,dPos.Y.Offset+d.Y)
        end
    end)
end

-- ── Main window ───────────────────────────────────────────────────────────
local WIN = Instance.new("Frame", gui)
WIN.Size     = UDim2.new(0, 560, 0, 340)
WIN.Position = UDim2.new(0.5,-280, 0.5,-170)
WIN.BackgroundColor3 = P.bg
WIN.BorderSizePixel  = 0
WIN.ClipsDescendants = true
Corner(WIN, 12)
Stroke(WIN, P.accentDim, 1.2)

-- ── Header ────────────────────────────────────────────────────────────────
local HDR = Instance.new("Frame", WIN)
HDR.Size             = UDim2.new(1,0,0,38)
HDR.BackgroundColor3 = P.glass
HDR.BorderSizePixel  = 0
Corner(HDR, 12)
Draggable(WIN, HDR)

-- Thin accent underline
local hLine = Instance.new("Frame", HDR)
hLine.Size     = UDim2.new(1,-24,0,1)
hLine.Position = UDim2.new(0,12,1,-1)
hLine.BackgroundColor3 = P.accent
hLine.BackgroundTransparency = 0.55
hLine.BorderSizePixel = 0

local logoLbl = Instance.new("TextLabel", HDR)
logoLbl.Size=UDim2.new(0,30,0,30); logoLbl.Position=UDim2.new(0,8,0.5,-15)
logoLbl.BackgroundTransparency=1; logoLbl.Text="🐰"
logoLbl.TextSize=22; logoLbl.Font=Enum.Font.GothamBold

local titleLbl = Instance.new("TextLabel", HDR)
titleLbl.Size=UDim2.new(0,120,0,20); titleLbl.Position=UDim2.new(0,44,0,4)
titleLbl.BackgroundTransparency=1; titleLbl.Text="BUNNI_R"
titleLbl.Font=Enum.Font.GothamBold; titleLbl.TextSize=15
titleLbl.TextColor3=P.white; titleLbl.TextXAlignment=Enum.TextXAlignment.Left

local subLbl = Instance.new("TextLabel", HDR)
subLbl.Size=UDim2.new(0,160,0,13); subLbl.Position=UDim2.new(0,44,0,22)
subLbl.BackgroundTransparency=1; subLbl.Text="PVP SUITE  ·  v3.0"
subLbl.Font=Enum.Font.Gotham; subLbl.TextSize=9
subLbl.TextColor3=P.muted; subLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Target pill in header
local tgtPill = Instance.new("Frame", HDR)
tgtPill.Size=UDim2.new(0,220,0,24); tgtPill.Position=UDim2.new(0.5,-80,0.5,-12)
tgtPill.BackgroundColor3=P.item; tgtPill.BorderSizePixel=0
Corner(tgtPill,12); Stroke(tgtPill,P.accentDim,1)

local tgtDot = Instance.new("Frame", tgtPill)
tgtDot.Size=UDim2.new(0,7,0,7); tgtDot.Position=UDim2.new(0,10,0.5,-3.5)
tgtDot.BackgroundColor3=P.red; tgtDot.BorderSizePixel=0; Corner(tgtDot,4)

local tgtLbl = Instance.new("TextLabel", tgtPill)
tgtLbl.Size=UDim2.new(1,-26,1,0); tgtLbl.Position=UDim2.new(0,24,0,0)
tgtLbl.BackgroundTransparency=1; tgtLbl.Text="No target"
tgtLbl.Font=Enum.Font.GothamSemibold; tgtLbl.TextSize=10
tgtLbl.TextColor3=P.muted; tgtLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Minimise btn
local MINBTN = Instance.new("TextButton", HDR)
MINBTN.Size=UDim2.new(0,26,0,26); MINBTN.Position=UDim2.new(1,-32,0.5,-13)
MINBTN.BackgroundColor3=P.item; MINBTN.Text="−"
MINBTN.Font=Enum.Font.GothamBold; MINBTN.TextSize=16
MINBTN.TextColor3=P.muted; MINBTN.BorderSizePixel=0
Corner(MINBTN,5); Stroke(MINBTN,P.accentDim,1)

-- ── Target updater ────────────────────────────────────────────────────────
local dotPulse = false
local function PulseDot(on)
    if on == dotPulse then return end
    dotPulse = on
    if on then
        spawn(function()
            while dotPulse do
                TweenService:Create(tgtDot,TweenInfo.new(0.45),{BackgroundTransparency=0.75}):Play()
                wait(0.45)
                if not dotPulse then break end
                TweenService:Create(tgtDot,TweenInfo.new(0.45),{BackgroundTransparency=0}):Play()
                wait(0.45)
            end
        end)
    end
end

spawn(function()
    while wait(0.25) do pcall(function()
        local hrp = GetNearest()
        if hrp and hrp.Parent then
            local myR = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local d   = myR and M((hrp.Position-myR.Position).Magnitude) or 0
            local p   = Players:GetPlayerFromCharacter(hrp.Parent)
            tgtLbl.Text      = (p and p.Name or "?").."  [Lv."..(p and GetLevel(p) or "?").."]  "..d.."m"
            tgtLbl.TextColor3 = p and TeamColor(p) or P.white
            PulseDot(true)
        else
            tgtLbl.Text = "No target in range"
            tgtLbl.TextColor3 = P.muted
            PulseDot(false)
        end
    end) end
end)

-- ── Sidebar ───────────────────────────────────────────────────────────────
local SIDEBAR = Instance.new("ScrollingFrame", WIN)
SIDEBAR.Size     = UDim2.new(0,130,1,-38)
SIDEBAR.Position = UDim2.new(0,0,0,38)
SIDEBAR.BackgroundColor3 = P.sidebar
SIDEBAR.BorderSizePixel  = 0
SIDEBAR.ScrollBarThickness = 0
SIDEBAR.AutomaticCanvasSize = Enum.AutomaticSize.Y
SIDEBAR.CanvasSize = UDim2.new(0,0,0,0)
List(SIDEBAR, nil, 3)
Pad(SIDEBAR, 8, 8, 10, 8)

-- ── Content area ──────────────────────────────────────────────────────────
local CONTENT = Instance.new("ScrollingFrame", WIN)
CONTENT.Size     = UDim2.new(1,-138,1,-38)
CONTENT.Position = UDim2.new(0,134,0,42)
CONTENT.BackgroundTransparency = 1
CONTENT.BorderSizePixel  = 0
CONTENT.ScrollBarThickness = 2
CONTENT.ScrollBarImageColor3 = P.scrollBar
CONTENT.AutomaticCanvasSize = Enum.AutomaticSize.Y
CONTENT.CanvasSize = UDim2.new(0,0,0,0)
List(CONTENT, nil, 6)
Pad(CONTENT, 4, 8, 6, 10)

-- Vertical divider
local divider = Instance.new("Frame", WIN)
divider.Size=UDim2.new(0,1,1,-38); divider.Position=UDim2.new(0,130,0,38)
divider.BackgroundColor3=P.accentDim; divider.BackgroundTransparency=0.6
divider.BorderSizePixel=0

-- ── Tab system ────────────────────────────────────────────────────────────
local tabs       = {}   -- {name, btn, items=[]}
local curTab     = nil

local function ShowTab(name)
    curTab = name
    -- hide/show content items
    for tName, tData in pairs(tabs) do
        local active = tName == name
        for _, item in ipairs(tData.items) do
            item.Visible = active
        end
        -- highlight sidebar btn
        TweenService:Create(tData.btn, TweenInfo.new(0.12), {
            BackgroundColor3 = active and P.accentDim or Color3.fromRGB(0,0,0),
            BackgroundTransparency = active and 0 or 1,
        }):Play()
        tData.btn.TextColor3 = active and P.white or P.muted
    end
end

local function AddTab(name, icon)
    local btn = Instance.new("TextButton", SIDEBAR)
    btn.Size             = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = Color3.fromRGB(0,0,0)
    btn.BackgroundTransparency = 1
    btn.Text             = icon .. "  " .. name
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 11
    btn.TextColor3       = P.muted
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.AutoButtonColor  = false
    btn.BorderSizePixel  = 0
    Corner(btn, 5)
    Pad(btn, 8, 0, 0, 0)

    tabs[name] = {btn=btn, items={}}
    btn.MouseButton1Click:Connect(function() ShowTab(name) end)
    return name
end

-- Register item into active tab
local function Reg(tabName, item)
    item.Visible = false
    table.insert(tabs[tabName].items, item)
end

-- ── Component builders ────────────────────────────────────────────────────
local orderN = 0
local function O() orderN=orderN+1; return orderN end

local function Section(tabName, label)
    local f = Instance.new("Frame", CONTENT)
    f.Size=UDim2.new(1,0,0,20); f.BackgroundTransparency=1; f.LayoutOrder=O()
    local l = Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=label:upper(); l.Font=Enum.Font.GothamBold; l.TextSize=9
    l.TextColor3=P.accent; l.TextXAlignment=Enum.TextXAlignment.Left
    Reg(tabName, f)
end

local function Toggle(tabName, label, cfgKey, cb)
    local row = Instance.new("Frame", CONTENT)
    row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=P.item
    row.BorderSizePixel=0; row.LayoutOrder=O()
    Corner(row, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1,-52,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
    lbl.TextColor3=P.muted; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local pill = Instance.new("Frame", row)
    pill.Size=UDim2.new(0,36,0,18); pill.Position=UDim2.new(1,-44,0.5,-9)
    pill.BackgroundColor3=P.offPill; pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local knob = Instance.new("Frame", pill)
    knob.Size=UDim2.new(0,13,0,13); knob.Position=UDim2.new(0,2,0.5,-6.5)
    knob.BackgroundColor3=P.knobOff; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local hit = Instance.new("TextButton", row)
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""

    local on = false
    hit.MouseButton1Click:Connect(function()
        on = not on
        CFG[cfgKey] = on
        TweenService:Create(pill,TweenInfo.new(0.13),{
            BackgroundColor3=on and P.onPill or P.offPill}):Play()
        TweenService:Create(knob,TweenInfo.new(0.13),{
            Position=on and UDim2.new(1,-15,0.5,-6.5) or UDim2.new(0,2,0.5,-6.5),
            BackgroundColor3=on and P.knobOn or P.knobOff}):Play()
        TweenService:Create(lbl,TweenInfo.new(0.13),{
            TextColor3=on and P.white or P.muted}):Play()
        if cb then cb(on) end
    end)
    Reg(tabName, row)
end

local function Button(tabName, label, cb)
    local row = Instance.new("TextButton", CONTENT)
    row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=P.item
    row.Text=label; row.Font=Enum.Font.GothamBold; row.TextSize=11
    row.TextColor3=P.accent; row.AutoButtonColor=false
    row.BorderSizePixel=0; row.LayoutOrder=O()
    Corner(row,6); Stroke(row,P.accentDim,1)

    row.MouseButton1Click:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.07),{BackgroundColor3=P.accentDim}):Play()
        task.wait(0.1)
        TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=P.item}):Play()
        cb()
    end)
    row.MouseEnter:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=P.itemHover}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=P.item}):Play()
    end)
    Reg(tabName, row)
end

local function Slider(tabName, label, cfgKey, minV, maxV, fmt, cb)
    local f = Instance.new("Frame", CONTENT)
    f.Size=UDim2.new(1,0,0,48); f.BackgroundColor3=P.item
    f.BorderSizePixel=0; f.LayoutOrder=O()
    Corner(f,6)

    local nl = Instance.new("TextLabel",f)
    nl.Size=UDim2.new(1,-54,0,22); nl.Position=UDim2.new(0,10,0,2)
    nl.BackgroundTransparency=1; nl.Text=label
    nl.Font=Enum.Font.Gotham; nl.TextSize=10; nl.TextColor3=P.white
    nl.TextXAlignment=Enum.TextXAlignment.Left

    local vl = Instance.new("TextLabel",f)
    vl.Size=UDim2.new(0,48,0,22); vl.Position=UDim2.new(1,-52,0,2)
    vl.BackgroundTransparency=1
    local function fv(v) return fmt and string.format(fmt,v) or tostring(v) end
    vl.Text=fv(CFG[cfgKey]); vl.Font=Enum.Font.GothamBold; vl.TextSize=10
    vl.TextColor3=P.accentGlow; vl.TextXAlignment=Enum.TextXAlignment.Right

    local track = Instance.new("Frame",f)
    track.Size=UDim2.new(1,-20,0,5); track.Position=UDim2.new(0,10,0,34)
    track.BackgroundColor3=Color3.fromRGB(25,18,48); track.BorderSizePixel=0
    Corner(track,3)

    local fill = Instance.new("Frame",track)
    fill.Size=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=P.accent; fill.BorderSizePixel=0; Corner(fill,3)

    local knob = Instance.new("Frame",track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=P.accentGlow; knob.BorderSizePixel=0
    Corner(knob,7); Stroke(knob,P.accentDim,1)

    local dragging=false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    knob.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    -- Also allow dragging on the track itself
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            local rel=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local val=math.floor(minV+rel*(maxV-minV))
            CFG[cfgKey]=val; fill.Size=UDim2.new(rel,0,1,0)
            knob.Position=UDim2.new(rel,0,0.5,0); vl.Text=fv(val)
            if cb then cb(val) end
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local rel=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local val=math.floor(minV+rel*(maxV-minV))
            CFG[cfgKey]=val; fill.Size=UDim2.new(rel,0,1,0)
            knob.Position=UDim2.new(rel,0,0.5,0); vl.Text=fv(val)
            if cb then cb(val) end
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    Reg(tabName, f)
end

local function Dropdown(tabName, label, cfgKey, options, cb)
    local f = Instance.new("Frame", CONTENT)
    f.Size=UDim2.new(1,0,0,32); f.BackgroundColor3=P.item
    f.BorderSizePixel=0; f.LayoutOrder=O(); f.ClipsDescendants=true
    Corner(f,6)

    local lbl = Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(0.45,0,0,32); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=10
    lbl.TextColor3=P.white; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local selBtn = Instance.new("TextButton",f)
    selBtn.Size=UDim2.new(0,110,0,24); selBtn.Position=UDim2.new(1,-118,0.5,-12)
    selBtn.BackgroundColor3=P.accentDim; selBtn.Text=CFG[cfgKey] or options[1]
    selBtn.Font=Enum.Font.GothamBold; selBtn.TextSize=9
    selBtn.TextColor3=P.white; selBtn.BorderSizePixel=0
    Corner(selBtn,4); Stroke(selBtn,P.accent,1)

    -- Dropdown list
    local dropList = Instance.new("Frame",f)
    dropList.Size=UDim2.new(1,-16,0, #options*28+4)
    dropList.Position=UDim2.new(0,8,0,34)
    dropList.BackgroundColor3=P.glass; dropList.BorderSizePixel=0; dropList.Visible=false
    Corner(dropList,5); Stroke(dropList,P.accentDim,1)
    List(dropList,nil,2); Pad(dropList,4,4,3,3)

    local open=false
    selBtn.MouseButton1Click:Connect(function()
        open=not open
        dropList.Visible=open
        TweenService:Create(f,TweenInfo.new(0.15),{
            Size=open and UDim2.new(1,0,0,34+#options*28+10) or UDim2.new(1,0,0,32)}):Play()
    end)

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton",dropList)
        ob.Size=UDim2.new(1,0,0,26); ob.BackgroundColor3=P.item
        ob.Text=opt; ob.Font=Enum.Font.Gotham; ob.TextSize=10
        ob.TextColor3=P.muted; ob.BorderSizePixel=0
        Corner(ob,4)
        ob.MouseButton1Click:Connect(function()
            CFG[cfgKey]=opt; selBtn.Text=opt
            open=false; dropList.Visible=false
            TweenService:Create(f,TweenInfo.new(0.15),{Size=UDim2.new(1,0,0,32)}):Play()
            if cb then cb(opt) end
        end)
        ob.MouseEnter:Connect(function()
            TweenService:Create(ob,TweenInfo.new(0.08),{BackgroundColor3=P.itemHover}):Play()
            ob.TextColor3=P.white
        end)
        ob.MouseLeave:Connect(function()
            TweenService:Create(ob,TweenInfo.new(0.08),{BackgroundColor3=P.item}):Play()
            ob.TextColor3=P.muted
        end)
    end
    Reg(tabName, f)
end

-- ── Player list dropdown (QuixHub refresh logic) ──────────────────────────
local playerListDropdown = nil
local function BuildPlayerList(tabName)
    local f = Instance.new("Frame", CONTENT)
    f.Size=UDim2.new(1,0,0,32); f.BackgroundColor3=P.item
    f.BorderSizePixel=0; f.LayoutOrder=O(); f.ClipsDescendants=true
    Corner(f,6)

    local lbl = Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(0.45,0,0,32); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text="Select Player"
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=10
    lbl.TextColor3=P.white; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local selBtn = Instance.new("TextButton",f)
    selBtn.Size=UDim2.new(0,110,0,24); selBtn.Position=UDim2.new(1,-118,0.5,-12)
    selBtn.BackgroundColor3=P.accentDim; selBtn.Text="-- Pick --"
    selBtn.Font=Enum.Font.GothamBold; selBtn.TextSize=9
    selBtn.TextColor3=P.white; selBtn.BorderSizePixel=0
    Corner(selBtn,4); Stroke(selBtn,P.accent,1)

    local scroll = Instance.new("ScrollingFrame",f)
    scroll.Size=UDim2.new(1,-16,0,120); scroll.Position=UDim2.new(0,8,0,34)
    scroll.BackgroundColor3=P.glass; scroll.BorderSizePixel=0; scroll.Visible=false
    scroll.ScrollBarThickness=2; scroll.ScrollBarImageColor3=P.scrollBar
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(0,0,0,0)
    Corner(scroll,5); Stroke(scroll,P.accentDim,1)
    List(scroll,nil,2); Pad(scroll,4,4,3,3)

    local open=false
    selBtn.MouseButton1Click:Connect(function()
        open=not open; scroll.Visible=open
        TweenService:Create(f,TweenInfo.new(0.15),{
            Size=open and UDim2.new(1,0,0,160) or UDim2.new(1,0,0,32)}):Play()
    end)

    -- Refresh function
    local function Refresh()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local found = false
        for _, v in ipairs(Players:GetPlayers()) do
            if v ~= LP then
                found = true
                local ob = Instance.new("TextButton",scroll)
                ob.Size=UDim2.new(1,0,0,26); ob.BackgroundColor3=P.item
                ob.Text=v.Name; ob.Font=Enum.Font.Gotham; ob.TextSize=10
                ob.TextColor3=P.muted; ob.BorderSizePixel=0
                Corner(ob,4)
                ob.MouseButton1Click:Connect(function()
                    CFG.SpecificPlayer=v.Name; selBtn.Text=v.Name
                    open=false; scroll.Visible=false
                    TweenService:Create(f,TweenInfo.new(0.15),{Size=UDim2.new(1,0,0,32)}):Play()
                end)
            end
        end
        if not found then
            local ob=Instance.new("TextButton",scroll)
            ob.Size=UDim2.new(1,0,0,26); ob.BackgroundColor3=P.item
            ob.Text="No Players"; ob.Font=Enum.Font.Gotham; ob.TextSize=10
            ob.TextColor3=P.muted; ob.BorderSizePixel=0; Corner(ob,4)
        end
    end

    playerListDropdown = Refresh
    Refresh()
    Reg(tabName, f)
    return Refresh
end

-- ════════════════════════════════════════════════════════
--  BUILD TABS
-- ════════════════════════════════════════════════════════
AddTab("Combat",   "⚡")
AddTab("Movement", "🏃")
AddTab("Visuals",  "👁")
AddTab("Misc",     "⚙")

-- ── COMBAT ────────────────────────────────────────────────────────────────
Section("Combat", "Aimbot")
Toggle("Combat",   "Aimbot Gun",          "AimbotGun")
Toggle("Combat",   "Aimbot Skill",        "AimbotSkill")
Toggle("Combat",   "Silent Aim",          "SilentAim")
Toggle("Combat",   "CamLock",             "CamLock")

Section("Combat", "Attack")
Toggle("Combat",   "Fast Attack  (M1)",   "FastAttack")
Toggle("Combat",   "Auto Haki (Buso)",    "AutoHaki")
Toggle("Combat",   "Auto V3",             "AutoV3")
Toggle("Combat",   "Auto V4",             "AutoV4")

Section("Combat", "Target")
Dropdown("Combat", "Target Mode",   "TargetMode",   {"Nearest Enemy","Specific Player"}, function(v)
    if v == "Specific Player" and playerListDropdown then playerListDropdown() end
end)
Dropdown("Combat", "Aim At",        "AimbotTarget", {"HRP","Head"})
BuildPlayerList("Combat")
Button("Combat", "↻  Refresh Player List", function()
    if playerListDropdown then playerListDropdown() end
    Notify("Players", "List refreshed!", 1)
end)

Section("Combat", "Special")
Button("Combat", "❄  Ice TP & Kill (600m)", IceTPKill)

-- ── MOVEMENT ──────────────────────────────────────────────────────────────
Section("Movement", "Stats")
Toggle("Movement", "Speed Hack",      "SpeedHack")
Toggle("Movement", "Walk on Water",   "WalkWater")
Toggle("Movement", "NoClip (Walls)",  "NoClip")
Toggle("Movement", "Safe Mode",       "SafeMode")

Slider("Movement", "Walk Speed",      "WalkSpeed",     16, 350, "%d")
Slider("Movement", "Jump Power",      "JumpPower",     50, 500, "%d")
Slider("Movement", "Safe HP Thresh",  "SafeHPThresh",  5,  80,  "%d%%")

Button("Movement", "🖱  Get Click-TP Tool", GiveTPTool)

-- ── VISUALS ───────────────────────────────────────────────────────────────
Section("Visuals", "ESP")
Toggle("Visuals",  "Player ESP",      "ESPPlayer")
Slider("Visuals",  "ESP Range",       "ESPRange",      50, 1500, "%dm")

Section("Visuals", "Performance")
Toggle("Visuals",  "High Performance","HighPerf", function(on)
    if on then spawn(function() pcall(ApplyHighPerf) end) end
end)
Button("Visuals", "⚡  Apply FPS Boost Now", function()
    spawn(function() pcall(ApplyHighPerf) end)
end)

-- ── MISC ──────────────────────────────────────────────────────────────────
Section("Misc", "Advanced")
Slider("Misc", "Fast Atk Delay",  "FastAtkDelay", 0, 1,   "%.2fs")
Toggle("Misc", "Auto V3",         "AutoV3")
Toggle("Misc", "Auto V4",         "AutoV4")

Section("Misc", "Info")
local infoLbl = Instance.new("TextLabel", CONTENT)
infoLbl.Size=UDim2.new(1,0,0,28); infoLbl.BackgroundColor3=P.item
infoLbl.Font=Enum.Font.Gotham; infoLbl.TextSize=9
infoLbl.TextColor3=P.muted; infoLbl.TextXAlignment=Enum.TextXAlignment.Center
infoLbl.Text="github.com/rhoscript/BUNNI_R  ·  v3.0"
infoLbl.BorderSizePixel=0; infoLbl.LayoutOrder=O()
Corner(infoLbl,6)
Reg("Misc", infoLbl)

-- Show Combat tab by default
ShowTab("Combat")

-- ── Minimise ──────────────────────────────────────────────────────────────
local mini = false
MINBTN.MouseButton1Click:Connect(function()
    mini = not mini
    TweenService:Create(WIN, TweenInfo.new(0.18,Enum.EasingStyle.Quart), {
        Size = mini and UDim2.new(0,560,0,38) or UDim2.new(0,560,0,340)
    }):Play()
    MINBTN.Text = mini and "+" or "−"
end)

-- ════════════════════════════════════════════════════════════════════════
--  FLOATING BUTTON  (open/close toggle, top-left)
-- ════════════════════════════════════════════════════════════════════════
local FLOATBTN = Instance.new("ImageButton", gui)
FLOATBTN.Size     = UDim2.new(0,54,0,54)
FLOATBTN.Position = UDim2.new(0.06, 0, 0.18, 0)
FLOATBTN.BackgroundColor3 = Color3.fromRGB(0,0,0)
FLOATBTN.Image    = ""   -- replace with rbxassetid if you have the bunny asset
FLOATBTN.Active   = true
Corner(FLOATBTN, 27)
Stroke(FLOATBTN, P.accent, 2)
Draggable(FLOATBTN, FLOATBTN)

-- Bunny emoji fallback
local fbLbl = Instance.new("TextLabel", FLOATBTN)
fbLbl.Size=UDim2.new(1,0,1,0); fbLbl.BackgroundTransparency=1
fbLbl.Text="🐰"; fbLbl.TextSize=26; fbLbl.Font=Enum.Font.GothamBold

local guiVisible = true
FLOATBTN.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    WIN.Visible = guiVisible
    TweenService:Create(FLOATBTN,TweenInfo.new(0.12),{
        BackgroundColor3=guiVisible and Color3.fromRGB(0,0,0) or P.accentDim}):Play()
end)

-- ════════════════════════════════════════════════════════════════════════
--  JUMP CIRCLE BUTTON  (top-right, draggable)
-- ════════════════════════════════════════════════════════════════════════
local JWIN = Instance.new("Frame", gui)
JWIN.Size     = UDim2.new(0,58,0,58)
JWIN.Position = UDim2.new(1,-72,0,10)
JWIN.BackgroundColor3 = P.glass
JWIN.BorderSizePixel  = 0
Corner(JWIN, 29)
Stroke(JWIN, P.accent, 1.5)
Draggable(JWIN, JWIN)

local jIcon = Instance.new("TextLabel", JWIN)
jIcon.Size=UDim2.new(1,0,0.6,0); jIcon.Position=UDim2.new(0,0,0.05,0)
jIcon.BackgroundTransparency=1; jIcon.Text="↑"
jIcon.Font=Enum.Font.GothamBold; jIcon.TextSize=26; jIcon.TextColor3=P.accentGlow

local jTxt = Instance.new("TextLabel", JWIN)
jTxt.Size=UDim2.new(1,0,0,13); jTxt.Position=UDim2.new(0,0,1,-14)
jTxt.BackgroundTransparency=1; jTxt.Text="JUMP"
jTxt.Font=Enum.Font.GothamBold; jTxt.TextSize=8; jTxt.TextColor3=P.muted

local jBtn = Instance.new("TextButton", JWIN)
jBtn.Size=UDim2.new(1,0,1,0); jBtn.BackgroundTransparency=1; jBtn.Text=""

jBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local char = LP.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if hum then
            local orig = hum.JumpPower
            hum.JumpPower = CFG.JumpPower
            hum.Jump = true
            task.wait(0.2)
            hum.JumpPower = orig
        end
    end)
    TweenService:Create(JWIN,TweenInfo.new(0.08),{BackgroundColor3=P.accentDim}):Play()
    task.wait(0.14)
    TweenService:Create(JWIN,TweenInfo.new(0.2),{BackgroundColor3=P.glass}):Play()
end)

JWIN.MouseEnter:Connect(function()
    TweenService:Create(JWIN,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(20,13,42)}):Play()
end)
JWIN.MouseLeave:Connect(function()
    TweenService:Create(JWIN,TweenInfo.new(0.12),{BackgroundColor3=P.glass}):Play()
end)

Notify("BUNNI_R", "Matsune PVP v3.0 Loaded!", 3)
