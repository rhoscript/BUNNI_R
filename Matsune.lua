--[[
    ╔══════════════════════════════════════════════╗
    ║       BUNNI_R  ·  Matsune PVP  v2.0         ║
    ║   Aimbot · ESP · CamLock · SilentAim        ║
    ║   FastAttack · HighJump · SpeedHack         ║
    ║   SafeMode · V3/V4 · Haki · FPS Cap         ║
    ╚══════════════════════════════════════════════╝
]]

-- ── Anti-duplicate ───────────────────────────────────────
if _G._BunniR_Running then
    local old = game:GetService("CoreGui"):FindFirstChild("BunniR_PVP")
    if old then old:Destroy() end
    local old2 = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if old2 then
        local g = old2:FindFirstChild("BunniR_PVP")
        if g then g:Destroy() end
    end
end
_G._BunniR_Running = true

-- ── Services ─────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput      = game:GetService("VirtualInputManager")

-- ── Core refs ────────────────────────────────────────────
local LP     = Players.LocalPlayer
local ESPTag = math.random(1, 999999)

-- ── Globals ──────────────────────────────────────────────
_G.AimbotGun          = false
_G.AimbotSkill        = false
_G.AutoTarget         = false
_G.ESPPlayer          = false
_G.WalkWater          = false
_G.SafeMode           = false
_G.FastAttack         = false
_G.CamLock            = false
_G.SilentAim          = false
_G.AutoV3             = false
_G.AutoV4             = false
_G.HighPerformance    = false
_G.SpeedHack          = false
_G.Haki               = false
_G.JumpPower          = 100
_G.SpeedValue         = 32
_G.AimbotTarget       = "HumanoidRootPart" -- "Head" / "UpperTorso" / "HumanoidRootPart"
_G.ESPRange           = 500
_G.FastAttackDelay    = 5   -- centiseconds (5 = 0.05s)
_G.SafeHealthThreshold = 5500
_G.FPSCap             = 29

local SelectWeaponGun = ""
local SilentAimPos    = nil

-- ── FPS Cap ──────────────────────────────────────────────
if setfpscap then
    setfpscap(_G.FPSCap)
end
spawn(function()
    while task.wait(1) do
        if setfpscap then setfpscap(_G.FPSCap) end
    end
end)

-- ── Helpers ──────────────────────────────────────────────
local function M(s) return math.floor(s * 0.28) end

local function GetAimPart(character)
    if not character then return nil end
    local t = _G.AimbotTarget
    if t == "Head" then
        return character:FindFirstChild("Head")
    elseif t == "UpperTorso" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
    else
        return character:FindFirstChild("HumanoidRootPart")
    end
end

local function GetNearest()
    local best, bestD = nil, math.huge
    local myChar = LP.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LP and v.Character then
            local hrp = v.Character:FindFirstChild("HumanoidRootPart")
            local hum = v.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < bestD then bestD = d; best = v end
            end
        end
    end
    return best
end

local function GetLevel(p)
    local ok, v = pcall(function() return p.Data.Level.Value end)
    return ok and tostring(v) or "?"
end

local function TeamColor(p)
    local ok, t = pcall(function() return tostring(p.Team) end)
    if not ok then return Color3.fromRGB(200, 200, 200) end
    local tl = t:lower()
    if tl:find("marine") then return Color3.fromRGB(80, 170, 255) end
    if tl:find("pirate") then return Color3.fromRGB(255, 70, 70) end
    return Color3.fromRGB(200, 200, 200)
end

-- ── Track Gun (fixed: also checks equipped tool) ─────────
spawn(function()
    while task.wait(0.5) do
        pcall(function()
            -- Check backpack
            if LP.Backpack then
                for _, v in pairs(LP.Backpack:GetChildren()) do
                    if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                        SelectWeaponGun = v.Name
                    end
                end
            end
            -- Check equipped
            if LP.Character then
                for _, v in pairs(LP.Character:GetChildren()) do
                    if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                        SelectWeaponGun = v.Name
                    end
                end
            end
        end)
    end
end)

-- ── Fast Attack (fixed: uses configurable delay) ─────────
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
                if d < 100 then
                    table.insert(list, {e, head}); base = head
                end
            end
        end
        return list, base
    end

    while task.wait(0) do
        if not _G.FastAttack then
            task.wait(0.1); continue
        end
        local char = LP.Character; if not char then continue end

        local eList, b1 = Collect(workspace:FindFirstChild("Enemies"))
        local cList, b2 = Collect(workspace:FindFirstChild("Characters"))
        for _, d in ipairs(cList) do table.insert(eList, d) end

        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("LeftClickRemote") then
            for _, d in ipairs(eList) do
                local hrp = d[1]:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dir = (hrp.Position - char:GetPivot().Position).Unit
                    pcall(function() tool.LeftClickRemote:FireServer(dir, 1) end)
                end
            end
        elseif #eList > 0 then
            pcall(function()
                RegAtk:FireServer(0)
                RegHit:FireServer(b1 or b2, eList)
            end)
        end
        task.wait((_G.FastAttackDelay or 5) / 100)
    end
end)

-- ── Aimbot Gun (fixed: uses selectable aim part) ─────────
RunService.Heartbeat:Connect(function()
    if not _G.AimbotGun then return end
    local t = GetNearest(); if not t or not t.Character then return end
    local char = LP.Character; if not char then return end
    local gun = char:FindFirstChild(SelectWeaponGun)
    if gun and gun:FindFirstChild("RemoteFunctionShoot") then
        local aimPart = GetAimPart(t.Character)
        if aimPart then
            pcall(function()
                gun.RemoteFunctionShoot:InvokeServer(aimPart.Position, aimPart)
            end)
        end
    end
end)

-- ── Aimbot Skill (fixed: uses selectable aim part) ───────
RunService.RenderStepped:Connect(function()
    if not _G.AimbotSkill then return end
    local t = GetNearest(); if not t or not t.Character then return end
    local char = LP.Character; if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and char:FindFirstChild(tool.Name) then
        local tr = char[tool.Name]
        if tr:FindFirstChild("MousePos") then
            local aimPart = GetAimPart(t.Character)
            if aimPart then
                pcall(function()
                    tr.RemoteEvent:FireServer(aimPart.Position)
                end)
            end
        end
    end
end)

-- ── Silent Aim (fixed: removed undefined 'gg' ref) ───────
spawn(function()
    pcall(function()
        local raw  = getrawmetatable(game)
        local orig = raw.__namecall
        setreadonly(raw, false)
        raw.__namecall = newcclosure(function(...)
            local method = getnamecallmethod()
            local args   = {...}
            if _G.SilentAim and method == "FireServer" then
                local t = GetNearest()
                if t and t.Character then
                    local aimPart = GetAimPart(t.Character)
                    if aimPart then
                        SilentAimPos = aimPart.Position
                        for i, v in ipairs(args) do
                            if typeof(v) == "Vector3" then
                                args[i] = SilentAimPos
                            end
                        end
                    end
                end
            end
            return orig(unpack(args))
        end)
        setreadonly(raw, true)
    end)
end)

-- ── CamLock (fixed: uses workspace.CurrentCamera live) ───
RunService.RenderStepped:Connect(function()
    if not _G.CamLock then return end
    local t = GetNearest()
    if t and t.Character then
        local aimPart = GetAimPart(t.Character)
        if aimPart then
            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, aimPart.Position)
        end
    end
end)

-- ── ESP Player (fixed: respects ESPRange, cleanup) ───────
spawn(function()
    while task.wait(0.4) do
        pcall(function()
            for _, v in ipairs(Players:GetPlayers()) do
                if v == LP then continue end
                if not v.Character then continue end
                local head = v.Character:FindFirstChild("Head")
                if not head then continue end

                if _G.ESPPlayer then
                    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local dist = myRoot and (head.Position - myRoot.Position).Magnitude or math.huge
                    if dist > (_G.ESPRange or 500) then
                        local old = head:FindFirstChild("BESP_"..ESPTag)
                        if old then old:Destroy() end
                        continue
                    end

                    if not head:FindFirstChild("BESP_"..ESPTag) then
                        local bg = Instance.new("BillboardGui", head)
                        bg.Name = "BESP_"..ESPTag
                        bg.AlwaysOnTop = true
                        bg.Size = UDim2.new(0, 200, 0, 60)
                        bg.StudsOffset = Vector3.new(0, 3, 0)

                        local nl = Instance.new("TextLabel", bg)
                        nl.Name = "NameLbl"
                        nl.Size = UDim2.new(1,0,0,20)
                        nl.BackgroundTransparency = 1
                        nl.Font = Enum.Font.GothamBold; nl.TextSize = 13
                        nl.TextStrokeTransparency = 0.3
                        nl.TextStrokeColor3 = Color3.new(0,0,0)

                        local il = Instance.new("TextLabel", bg)
                        il.Name = "InfoLbl"
                        il.Size = UDim2.new(1,0,0,14)
                        il.Position = UDim2.new(0,0,0,20)
                        il.BackgroundTransparency = 1
                        il.Font = Enum.Font.Gotham; il.TextSize = 11
                        il.TextColor3 = Color3.fromRGB(200,200,200)
                        il.TextStrokeTransparency = 0.4
                        il.TextStrokeColor3 = Color3.new(0,0,0)

                        local barBg = Instance.new("Frame", bg)
                        barBg.Name = "BarBg"
                        barBg.Size = UDim2.new(1,0,0,5)
                        barBg.Position = UDim2.new(0,0,0,36)
                        barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
                        barBg.BorderSizePixel = 0
                        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

                        local bf = Instance.new("Frame", barBg)
                        bf.Name = "BarFill"
                        bf.Size = UDim2.new(1,0,1,0)
                        bf.BackgroundColor3 = Color3.fromRGB(80,220,80)
                        bf.BorderSizePixel = 0
                        Instance.new("UICorner", bf).CornerRadius = UDim.new(1,0)
                    end

                    local esp = head:FindFirstChild("BESP_"..ESPTag)
                    if esp then
                        local hum = v.Character:FindFirstChild("Humanoid")
                        local hp  = hum and (hum.Health / hum.MaxHealth) or 0
                        local col = TeamColor(v)
                        esp.NameLbl.Text = v.Name.." [Lv."..GetLevel(v).."]"
                        esp.NameLbl.TextColor3 = col
                        esp.InfoLbl.Text = M(dist).."m"
                        local fill = esp.BarBg:FindFirstChild("BarFill")
                        if fill then
                            fill.Size = UDim2.new(math.clamp(hp,0,1),0,1,0)
                            fill.BackgroundColor3 = hp > 0.6
                                and Color3.fromRGB(60,210,60)
                                or hp > 0.3
                                and Color3.fromRGB(230,190,0)
                                or Color3.fromRGB(220,50,50)
                        end
                    end
                else
                    local old = head:FindFirstChild("BESP_"..ESPTag)
                    if old then old:Destroy() end
                end
            end
        end)
    end
end)

-- ── Walk on Water ────────────────────────────────────────
spawn(function()
    while task.wait(1) do
        pcall(function()
            local p = workspace.Map:FindFirstChild("WaterBase-Plane")
            if p then
                p.Size = _G.WalkWater
                    and Vector3.new(1000,112,1000)
                    or  Vector3.new(1000,80,1000)
            end
        end)
    end
end)

-- ── Safe Mode (uses configurable threshold) ──────────────
spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not _G.SafeMode then return end
            local c = LP.Character
            if c and c:FindFirstChild("Humanoid")
                and c:FindFirstChild("HumanoidRootPart")
                and c.Humanoid.Health < (_G.SafeHealthThreshold or 5500) then
                c.HumanoidRootPart.CFrame = c.HumanoidRootPart.CFrame
                    + Vector3.new(0, 200, 0)
            end
        end)
    end
end)

-- ── Speed Hack (NEW) ─────────────────────────────────────
spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if _G.SpeedHack and LP.Character then
                local hum = LP.Character:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = _G.SpeedValue end
            end
        end)
    end
end)

-- ── Haki Toggle (NEW) ────────────────────────────────────
spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if _G.Haki then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local r = remotes:FindFirstChild("CommE")
                    if r then r:FireServer("ActivateHaki") end
                end
            end
        end)
    end
end)

-- ── Auto V3 ──────────────────────────────────────────────
spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if _G.AutoV3 then
                ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
            end
        end)
    end
end)

-- ── Auto V4 ──────────────────────────────────────────────
spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if _G.AutoV4 then
                VirtualInput:SendKeyEvent(true,  "Y", false, game)
                task.wait(0.05)
                VirtualInput:SendKeyEvent(false, "Y", false, game)
            end
        end)
    end
end)

-- ── High Performance ─────────────────────────────────────
spawn(function()
    while task.wait(2) do
        pcall(function()
            if _G.HighPerformance then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                end
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail")
                        or v:IsA("Smoke") or v:IsA("Fire")
                        or v:IsA("Sparkles") then
                        v.Enabled = false
                    end
                end
            end
        end)
    end
end)

--[[
═══════════════════════════════════════════════════════════
  UI  ─  Black · Purple · Glass · Liquid   (Futuristic)
═══════════════════════════════════════════════════════════
]]

local gui = Instance.new("ScreenGui")
gui.Name = "BunniR_PVP"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    if syn then syn.protect_gui(gui) end
    gui.Parent = game:GetService("CoreGui")
end)
if not gui.Parent then
    gui.Parent = LP:WaitForChild("PlayerGui")
end

-- ── Colour Palette ───────────────────────────────────────
local C = {
    bg          = Color3.fromRGB(6, 4, 15),
    bgGlass     = Color3.fromRGB(12, 8, 26),
    bar         = Color3.fromRGB(14, 10, 30),
    row         = Color3.fromRGB(18, 12, 36),
    accent      = Color3.fromRGB(138, 43, 226),
    accent2     = Color3.fromRGB(185, 110, 255),
    accentDim   = Color3.fromRGB(80, 30, 140),
    glassBorder = Color3.fromRGB(75, 45, 130),
    text        = Color3.fromRGB(225, 218, 240),
    textDim     = Color3.fromRGB(120, 105, 150),
    on          = Color3.fromRGB(138, 43, 226),
    off         = Color3.fromRGB(28, 20, 44),
}

-- ── Drag Helper ──────────────────────────────────────────
local function MakeDraggable(frame, handle)
    local drag, dInput, dStart, dPos
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; dStart = inp.Position; dPos = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    drag = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
            dInput = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp == dInput then
            local d = inp.Position - dStart
            frame.Position = UDim2.new(
                dPos.X.Scale, dPos.X.Offset + d.X,
                dPos.Y.Scale, dPos.Y.Offset + d.Y)
        end
    end)
end

-- ── UI Builder Helpers ───────────────────────────────────
local orderN = 0
local function O() orderN = orderN + 1; return orderN end

local function Section(parent, name)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 24)
    f.BackgroundTransparency = 1
    f.LayoutOrder = O()

    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(1, -16, 0, 1)
    line.Position = UDim2.new(0, 8, 1, -1)
    line.BackgroundColor3 = C.accent
    line.BackgroundTransparency = 0.65
    line.BorderSizePixel = 0

    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -16, 1, 0)
    l.Position = UDim2.new(0, 8, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name:upper()
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextColor3 = C.accent2
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextStrokeTransparency = 0.65
    l.TextStrokeColor3 = C.accent
end

local function Toggle(parent, label, flag, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 32)
    row.BackgroundColor3 = C.row
    row.BackgroundTransparency = 0.45
    row.BorderSizePixel = 0
    row.LayoutOrder = O()
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11; lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0, 36, 0, 18)
    pill.Position = UDim2.new(1, -46, 0.5, -9)
    pill.BackgroundColor3 = C.off; pill.BorderSizePixel = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local ps = Instance.new("UIStroke", pill)
    ps.Color = C.glassBorder; ps.Thickness = 1; ps.Transparency = 0.5

    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(110, 100, 130)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1; btn.Text = ""

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state; _G[flag] = state
        TweenService:Create(pill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = state and C.on or C.off }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Position = state
                and UDim2.new(1, -16, 0.5, -7)
                or  UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = state and C.accent2 or Color3.fromRGB(110,100,130)
        }):Play()
        TweenService:Create(ps, TweenInfo.new(0.2), {
            Color = state and C.accent or C.glassBorder }):Play()
        if callback then callback(state) end
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundTransparency=0.25}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundTransparency=0.45}):Play()
    end)
    return row
end

local function Slider(parent, label, flag, min, max, default, displayCb)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 50)
    row.BackgroundColor3 = C.row; row.BackgroundTransparency = 0.45
    row.BorderSizePixel = 0; row.LayoutOrder = O()
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 2)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = C.text; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0.35, 0, 0, 20)
    valLbl.Position = UDim2.new(0.65, -8, 0, 2)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = displayCb and displayCb(default) or tostring(default)
    valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 11
    valLbl.TextColor3 = C.accent2
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local sBg = Instance.new("Frame", row)
    sBg.Size = UDim2.new(1, -24, 0, 6)
    sBg.Position = UDim2.new(0, 12, 0, 32)
    sBg.BackgroundColor3 = Color3.fromRGB(28, 22, 48)
    sBg.BorderSizePixel = 0
    Instance.new("UICorner", sBg).CornerRadius = UDim.new(1, 0)

    local rel = math.clamp((default - min) / (max - min), 0, 1)

    local sFill = Instance.new("Frame", sBg)
    sFill.Size = UDim2.new(rel, 0, 1, 0)
    sFill.BackgroundColor3 = C.accent; sFill.BorderSizePixel = 0
    Instance.new("UICorner", sFill).CornerRadius = UDim.new(1, 0)
    local fg = Instance.new("UIGradient", sFill)
    fg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(90,25,170)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(170,70,255)),
    }

    local sKnob = Instance.new("Frame", sBg)
    sKnob.Size = UDim2.new(0, 14, 0, 14)
    sKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    sKnob.Position = UDim2.new(rel, 0, 0.5, 0)
    sKnob.BackgroundColor3 = C.accent2; sKnob.BorderSizePixel = 0
    Instance.new("UICorner", sKnob).CornerRadius = UDim.new(1, 0)
    local ks = Instance.new("UIStroke", sKnob)
    ks.Color = C.accent; ks.Thickness = 1.5

    local dragging = false
    local function startDrag(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end
    local function stopDrag(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end
    sKnob.InputBegan:Connect(startDrag); sKnob.InputEnded:Connect(stopDrag)
    sBg.InputBegan:Connect(startDrag);   sBg.InputEnded:Connect(stopDrag)

    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp(
                (i.Position.X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * r)
            _G[flag] = val
            sFill.Size = UDim2.new(r, 0, 1, 0)
            sKnob.Position = UDim2.new(r, 0, 0.5, 0)
            valLbl.Text = displayCb and displayCb(val) or tostring(val)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return row
end

local function Dropdown(parent, label, options, flag)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 32)
    row.BackgroundColor3 = C.row; row.BackgroundTransparency = 0.45
    row.BorderSizePixel = 0; row.LayoutOrder = O()
    row.ClipsDescendants = false
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.48, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = C.text; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local selBtn = Instance.new("TextButton", row)
    selBtn.Size = UDim2.new(0.48, -8, 0, 24)
    selBtn.Position = UDim2.new(0.52, 0, 0.5, -12)
    selBtn.BackgroundColor3 = C.bgGlass; selBtn.BorderSizePixel = 0
    selBtn.Text = tostring(_G[flag] or options[1])
    selBtn.Font = Enum.Font.GothamBold; selBtn.TextSize = 10
    selBtn.TextColor3 = C.accent2
    Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", selBtn).Color = C.glassBorder

    local dropF = Instance.new("Frame", row)
    dropF.Size = UDim2.new(0.48, -8, 0, #options * 26)
    dropF.Position = UDim2.new(0.52, 0, 1, 4)
    dropF.BackgroundColor3 = C.bgGlass; dropF.BorderSizePixel = 0
    dropF.Visible = false; dropF.ZIndex = 50
    Instance.new("UICorner", dropF).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", dropF).Color = C.glassBorder

    local isOpen = false
    selBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen; dropF.Visible = isOpen
    end)

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton", dropF)
        ob.Size = UDim2.new(1, 0, 0, 26)
        ob.Position = UDim2.new(0, 0, 0, (i-1)*26)
        ob.BackgroundColor3 = C.row; ob.BackgroundTransparency = 0.3
        ob.BorderSizePixel = 0; ob.Text = opt
        ob.Font = Enum.Font.Gotham; ob.TextSize = 10
        ob.TextColor3 = C.text; ob.ZIndex = 51
        ob.MouseButton1Click:Connect(function()
            _G[flag] = opt; selBtn.Text = opt
            dropF.Visible = false; isOpen = false
        end)
        ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0.1 end)
        ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 0.3 end)
    end
    return row
end

-- ── Main Window ──────────────────────────────────────────
local WIN = Instance.new("Frame", gui)
WIN.Name = "MainWin"
WIN.Size = UDim2.new(0, 245, 0, 440)
WIN.Position = UDim2.new(0.03, 0, 0.15, 0)
WIN.BackgroundColor3 = C.bg
WIN.BackgroundTransparency = 0.04
WIN.BorderSizePixel = 0; WIN.ClipsDescendants = true
Instance.new("UICorner", WIN).CornerRadius = UDim.new(0, 14)

local ws = Instance.new("UIStroke", WIN)
ws.Color = C.glassBorder; ws.Thickness = 1.5; ws.Transparency = 0.25

local wg = Instance.new("UIGradient", WIN)
wg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 8, 28)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6, 4, 15)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 6, 22)),
}
wg.Rotation = 145

-- ── Header ───────────────────────────────────────────────
local HDR = Instance.new("Frame", WIN)
HDR.Size = UDim2.new(1, 0, 0, 54)
HDR.BackgroundColor3 = C.bar; HDR.BackgroundTransparency = 0.08
HDR.BorderSizePixel = 0
Instance.new("UICorner", HDR).CornerRadius = UDim.new(0, 14)
MakeDraggable(WIN, HDR)

local hg = Instance.new("UIGradient", HDR)
hg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 14, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 6, 18)),
}; hg.Rotation = 100

-- Purple glow line at top
local glow = Instance.new("Frame", HDR)
glow.Size = UDim2.new(0.7, 0, 0, 2)
glow.Position = UDim2.new(0.15, 0, 0, 0)
glow.BackgroundColor3 = C.accent; glow.BorderSizePixel = 0
Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
local glowG = Instance.new("UIGradient", glow)
glowG.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60,15,130)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190,90,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60,15,130)),
}
-- Animate glow
spawn(function()
    local offset = 0
    while task.wait(0.03) do
        offset = (offset + 0.005) % 1
        glowG.Offset = Vector2.new(offset, 0)
    end
end)

local icon = Instance.new("TextLabel", HDR)
icon.Size = UDim2.new(0,30,0,30); icon.Position = UDim2.new(0,12,0,12)
icon.BackgroundTransparency = 1; icon.Text = "⚡"
icon.Font = Enum.Font.GothamBold; icon.TextSize = 18
icon.TextColor3 = C.accent2

local title = Instance.new("TextLabel", HDR)
title.Size = UDim2.new(1,-100,0,20); title.Position = UDim2.new(0,46,0,8)
title.BackgroundTransparency = 1; title.Text = "BUNNI_R"
title.Font = Enum.Font.GothamBold; title.TextSize = 16
title.TextColor3 = C.accent2; title.TextXAlignment = Enum.TextXAlignment.Left

local sub = Instance.new("TextLabel", HDR)
sub.Size = UDim2.new(1,-100,0,14); sub.Position = UDim2.new(0,46,0,29)
sub.BackgroundTransparency = 1; sub.Text = "PVP SUITE  v2.0"
sub.Font = Enum.Font.Gotham; sub.TextSize = 9
sub.TextColor3 = C.textDim; sub.TextXAlignment = Enum.TextXAlignment.Left

local MINBTN = Instance.new("TextButton", HDR)
MINBTN.Size = UDim2.new(0,28,0,28); MINBTN.Position = UDim2.new(1,-38,0.5,-14)
MINBTN.BackgroundColor3 = C.bgGlass; MINBTN.BackgroundTransparency = 0.2
MINBTN.Text = "−"; MINBTN.Font = Enum.Font.GothamBold
MINBTN.TextSize = 16; MINBTN.TextColor3 = C.textDim
MINBTN.BorderSizePixel = 0
Instance.new("UICorner", MINBTN).CornerRadius = UDim.new(0, 7)
Instance.new("UIStroke", MINBTN).Color = C.glassBorder

-- ── Target Bar ───────────────────────────────────────────
local TGT = Instance.new("Frame", WIN)
TGT.Size = UDim2.new(1,-16,0,26); TGT.Position = UDim2.new(0,8,0,60)
TGT.BackgroundColor3 = C.bgGlass; TGT.BackgroundTransparency = 0.3
TGT.BorderSizePixel = 0
Instance.new("UICorner", TGT).CornerRadius = UDim.new(0, 6)

local tgtLbl = Instance.new("TextLabel", TGT)
tgtLbl.Size = UDim2.new(1,-12,1,0); tgtLbl.Position = UDim2.new(0,8,0,0)
tgtLbl.BackgroundTransparency = 1; tgtLbl.Text = "🎯  No target"
tgtLbl.Font = Enum.Font.GothamSemibold; tgtLbl.TextSize = 10
tgtLbl.TextColor3 = C.textDim; tgtLbl.TextXAlignment = Enum.TextXAlignment.Left

spawn(function()
    while task.wait(0.25) do
        pcall(function()
            local t = GetNearest()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                local myR = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                local d = myR and M((t.Character.HumanoidRootPart.Position - myR.Position).Magnitude) or 0
                tgtLbl.Text = "🎯  "..t.Name.."  [Lv."..GetLevel(t).."]  ·  "..d.."m"
                tgtLbl.TextColor3 = TeamColor(t)
            else
                tgtLbl.Text = "🎯  No target in range"
                tgtLbl.TextColor3 = C.textDim
            end
        end)
    end
end)

-- ── Scroll Area ──────────────────────────────────────────
local SCROLL = Instance.new("ScrollingFrame", WIN)
SCROLL.Size = UDim2.new(1,0,0,340); SCROLL.Position = UDim2.new(0,0,0,92)
SCROLL.BackgroundTransparency = 1; SCROLL.BorderSizePixel = 0
SCROLL.ScrollBarThickness = 3
SCROLL.ScrollBarImageColor3 = C.accent
SCROLL.ScrollBarImageTransparency = 0.3
SCROLL.CanvasSize = UDim2.new(0,0,0,0)
SCROLL.AutomaticCanvasSize = Enum.AutomaticSize.Y

local SL = Instance.new("UIListLayout", SCROLL)
SL.Padding = UDim.new(0, 4); SL.SortOrder = Enum.SortOrder.LayoutOrder
local SP = Instance.new("UIPadding", SCROLL)
SP.PaddingLeft  = UDim.new(0,6); SP.PaddingRight  = UDim.new(0,6)
SP.PaddingTop   = UDim.new(0,4); SP.PaddingBottom = UDim.new(0,8)

-- ── Build All Toggles / Sliders / Dropdowns ──────────────

Section(SCROLL, "⚡ Combat")
Toggle(SCROLL,  "Auto Target Nearest", "AutoTarget")
Toggle(SCROLL,  "Aimbot Gun",          "AimbotGun")
Toggle(SCROLL,  "Aimbot Skill",        "AimbotSkill")
Toggle(SCROLL,  "Silent Aim",          "SilentAim")
Toggle(SCROLL,  "CamLock",             "CamLock")
Toggle(SCROLL,  "Fast Attack  (M1)",   "FastAttack")
Dropdown(SCROLL, "Aim Target", {"HumanoidRootPart","Head","UpperTorso"}, "AimbotTarget")
Slider(SCROLL,  "Atk Delay (cs)",      "FastAttackDelay", 1, 50, 5,
    function(v) return v.." cs ("..string.format("%.2f", v/100).."s)" end)

Section(SCROLL, "👁 Vision")
Toggle(SCROLL,  "Player ESP",          "ESPPlayer")
Slider(SCROLL,  "ESP Range",           "ESPRange", 50, 2000, 500,
    function(v) return M(v).."m" end)

Section(SCROLL, "🏃 Movement")
Toggle(SCROLL,  "Speed Hack",          "SpeedHack")
Slider(SCROLL,  "Walk Speed",          "SpeedValue", 16, 250, 32)
Toggle(SCROLL,  "Walk on Water",       "WalkWater")

Section(SCROLL, "🛡 Defense")
Toggle(SCROLL,  "Safe Mode",           "SafeMode")
Slider(SCROLL,  "Safe HP Threshold",   "SafeHealthThreshold", 500, 10000, 5500)
Toggle(SCROLL,  "Haki",                "Haki")

Section(SCROLL, "⚙ Abilities")
Toggle(SCROLL,  "Auto V3",             "AutoV3")
Toggle(SCROLL,  "Auto V4",             "AutoV4")

Section(SCROLL, "🔧 System")
Toggle(SCROLL,  "High Performance",    "HighPerformance", function(on)
    if on then pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end) end
end)
Slider(SCROLL,  "FPS Cap",             "FPSCap", 10, 60, 29,
    function(v) return v.." fps" end)

-- Footer
local foot = Instance.new("TextLabel", SCROLL)
foot.Size = UDim2.new(1,0,0,18); foot.BackgroundTransparency = 1
foot.Text = "github.com/rhoscript/BUNNI_R"; foot.Font = Enum.Font.Gotham
foot.TextSize = 8; foot.TextColor3 = Color3.fromRGB(45,35,65)
foot.TextXAlignment = Enum.TextXAlignment.Center; foot.LayoutOrder = O()

-- ── Minimise ─────────────────────────────────────────────
local mini = false
MINBTN.MouseButton1Click:Connect(function()
    mini = not mini
    SCROLL.Visible = not mini; TGT.Visible = not mini
    TweenService:Create(WIN, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Size = mini and UDim2.new(0,245,0,54) or UDim2.new(0,245,0,440)
    }):Play()
    MINBTN.Text = mini and "+" or "−"
end)

-- ══════════════════════════════════════════════════════════
-- FLOATING JUMP BUTTON  (top-right, draggable)
-- ══════════════════════════════════════════════════════════

local JB = Instance.new("Frame", gui)
JB.Size = UDim2.new(0,56,0,56); JB.Position = UDim2.new(1,-70,0,14)
JB.BackgroundColor3 = C.bgGlass; JB.BackgroundTransparency = 0.08
JB.BorderSizePixel = 0
Instance.new("UICorner", JB).CornerRadius = UDim.new(0, 14)
local js = Instance.new("UIStroke", JB)
js.Color = C.accent; js.Thickness = 1.5; js.Transparency = 0.3
MakeDraggable(JB, JB)

Instance.new("UIGradient", JB).Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22,12,44)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,6,18)),
}

local ji = Instance.new("TextLabel", JB)
ji.Size = UDim2.new(1,0,0.6,0); ji.Position = UDim2.new(0,0,0,2)
ji.BackgroundTransparency = 1; ji.Text = "↑"
ji.Font = Enum.Font.GothamBold; ji.TextSize = 22; ji.TextColor3 = C.accent2

local jl = Instance.new("TextLabel", JB)
jl.Size = UDim2.new(1,0,0,14); jl.Position = UDim2.new(0,0,1,-16)
jl.BackgroundTransparency = 1; jl.Text = "JUMP"
jl.Font = Enum.Font.GothamBold; jl.TextSize = 8; jl.TextColor3 = C.textDim

local jBtn = Instance.new("TextButton", JB)
jBtn.Size = UDim2.new(1,0,1,0); jBtn.BackgroundTransparency = 1; jBtn.Text = ""

jBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
        if hum then
            local orig = hum.JumpPower
            hum.JumpPower = _G.JumpPower
            hum.Jump = true
            task.wait(0.1)
            hum.JumpPower = orig
        end
    end)
    TweenService:Create(js, TweenInfo.new(0.1), {
        Thickness=3, Color=Color3.fromRGB(200,100,255)}):Play()
    task.wait(0.15)
    TweenService:Create(js, TweenInfo.new(0.2), {
        Thickness=1.5, Color=C.accent}):Play()
end)

-- Jump Power mini-panel (hover)
local JP = Instance.new("Frame", gui)
JP.Size = UDim2.new(0,150,0,60); JP.Position = UDim2.new(1,-228,0,14)
JP.BackgroundColor3 = C.bgGlass; JP.BackgroundTransparency = 0.04
JP.BorderSizePixel = 0; JP.Visible = false
Instance.new("UICorner", JP).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", JP).Color = C.glassBorder

local jpT = Instance.new("TextLabel", JP)
jpT.Size = UDim2.new(0.6,0,0,18); jpT.Position = UDim2.new(0,8,0,4)
jpT.BackgroundTransparency = 1; jpT.Text = "Jump Power"
jpT.Font = Enum.Font.GothamBold; jpT.TextSize = 10
jpT.TextColor3 = C.accent2; jpT.TextXAlignment = Enum.TextXAlignment.Left

local jpV = Instance.new("TextLabel", JP)
jpV.Size = UDim2.new(0.35,0,0,18); jpV.Position = UDim2.new(0.65,-8,0,4)
jpV.BackgroundTransparency = 1; jpV.Text = tostring(_G.JumpPower)
jpV.Font = Enum.Font.GothamBold; jpV.TextSize = 10
jpV.TextColor3 = C.accent2; jpV.TextXAlignment = Enum.TextXAlignment.Right

local jpBg = Instance.new("Frame", JP)
jpBg.Size = UDim2.new(1,-20,0,6); jpBg.Position = UDim2.new(0,10,0,32)
jpBg.BackgroundColor3 = Color3.fromRGB(28,22,48); jpBg.BorderSizePixel = 0
Instance.new("UICorner", jpBg).CornerRadius = UDim.new(1,0)

local jpFill = Instance.new("Frame", jpBg)
jpFill.Size = UDim2.new(_G.JumpPower/500,0,1,0)
jpFill.BackgroundColor3 = C.accent; jpFill.BorderSizePixel = 0
Instance.new("UICorner", jpFill).CornerRadius = UDim.new(1,0)

local jpKnob = Instance.new("Frame", jpBg)
jpKnob.Size = UDim2.new(0,14,0,14); jpKnob.AnchorPoint = Vector2.new(0.5,0.5)
jpKnob.Position = UDim2.new(_G.JumpPower/500,0,0.5,0)
jpKnob.BackgroundColor3 = C.accent2; jpKnob.BorderSizePixel = 0
Instance.new("UICorner", jpKnob).CornerRadius = UDim.new(1,0)

local jpDrag = false
jpKnob.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then jpDrag = true end end)
jpKnob.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then jpDrag = false end end)
jpBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then jpDrag = true end end)
UserInputService.InputChanged:Connect(function(i)
    if jpDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local r = math.clamp((i.Position.X - jpBg.AbsolutePosition.X) / jpBg.AbsoluteSize.X, 0,1)
        _G.JumpPower = math.max(10, math.floor(r * 500))
        jpFill.Size = UDim2.new(r,0,1,0)
        jpKnob.Position = UDim2.new(r,0,0.5,0)
        jpV.Text = tostring(_G.JumpPower)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then jpDrag = false end end)

JB.MouseEnter:Connect(function() JP.Visible = true end)
JB.MouseLeave:Connect(function() task.wait(0.3)
    if not jpDrag then JP.Visible = false end end)
JP.MouseEnter:Connect(function() JP.Visible = true end)
JP.MouseLeave:Connect(function()
    if not jpDrag then JP.Visible = false end end)

-- ── Keybind: RightShift to toggle UI ─────────────────────
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

print("[BUNNI_R v2.0] Loaded ✓  |  Press RightShift to toggle UI")
