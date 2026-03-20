--[[
╔══════════════════════════════════════════════════╗
║          BUNNI_R  ·  Matsune PVP  v2.0          ║
║   Aimbot · ESP · CamLock · SilentAim            ║
║   FastAttack · HighJump · SafeMode · V3/V4      ║
║   SpeedHack · Haki · FPS Cap                    ║
║          ─── Nova Glass UI ───                   ║
╚══════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════
-- CLEANUP PREVIOUS INSTANCE
-- ═══════════════════════════════════════════════════
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("BunniR_Nova") then
        game:GetService("CoreGui").BunniR_Nova:Destroy()
    end
end)
pcall(function()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("BunniR_Nova") then pg.BunniR_Nova:Destroy() end
end)

-- ═══════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput      = game:GetService("VirtualInputManager")

local LP     = Players.LocalPlayer
local ESPTag = math.random(1, 999999)

-- ═══════════════════════════════════════════════════
-- GLOBAL CONFIGURATION  (getgenv for executor compat)
-- ═══════════════════════════════════════════════════
local G = (getgenv and getgenv()) or _G

-- Feature toggles
G.AimbotGun       = false
G.AimbotSkill     = false
G.AutoTarget      = false
G.ESPPlayer       = false
G.WalkWater       = false
G.SafeMode        = false
G.FastAttack      = false
G.CamLock         = false
G.SilentAim       = false
G.AutoV3          = false
G.AutoV4          = false
G.HighPerformance = false
G.SpeedHack       = false
G.Haki            = false

-- Configurable settings
G.JumpPower           = 100
G.AimbotTarget        = "HumanoidRootPart" -- Head / UpperTorso / HumanoidRootPart
G.ESPRange            = 500
G.FastAttackDelay     = 5   -- stored as 1-50, used as val/100 seconds
G.SafeHealthThreshold = 5500
G.SpeedValue          = 50
G.FPSCap              = 29

local SelectWeaponGun = ""
local SilentAimPos    = nil

-- ═══════════════════════════════════════════════════
-- FPS CAP  (29 default)
-- ═══════════════════════════════════════════════════
if setfpscap then setfpscap(G.FPSCap) end

-- ═══════════════════════════════════════════════════
-- HELPER FUNCTIONS  (all nil-safe)
-- ═══════════════════════════════════════════════════
local function M(s) return math.floor(s * 0.28) end

local function GetCam()   return workspace.CurrentCamera end
local function Char(p)    return p and p.Character end
local function Hum(c)     return c and c:FindFirstChild("Humanoid") end
local function Root(c)    return c and c:FindFirstChild("HumanoidRootPart") end
local function Head(c)    return c and c:FindFirstChild("Head") end

local function Alive(c)
    local h = Hum(c)
    return h and h.Health > 0
end

local function TargetPart(char)
    if not char then return nil end
    local t = G.AimbotTarget or "HumanoidRootPart"
    if t == "UpperTorso" or t == "Torso" then
        return char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("Torso")
            or Root(char)
    elseif t == "Head" then
        return Head(char) or Root(char)
    end
    return Root(char)
end

local function GetNearest()
    local best, bestD = nil, math.huge
    local myR = Root(Char(LP))
    if not myR then return nil end
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LP then
            local c = Char(v)
            local r = Root(c)
            local h = Hum(c)
            if r and h and h.Health > 0 then
                local d = (r.Position - myR.Position).Magnitude
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
    if not ok then return Color3.fromRGB(200,200,200) end
    local tl = t:lower()
    if tl:find("marine") then return Color3.fromRGB(80,170,255) end
    if tl:find("pirate") then return Color3.fromRGB(255,70,70) end
    return Color3.fromRGB(200,200,200)
end

-- ═══════════════════════════════════════════════════
-- FEATURE: TRACK EQUIPPED GUN
-- ═══════════════════════════════════════════════════
spawn(function()
    while true do
        pcall(function()
            local bp = LP:FindFirstChild("Backpack")
            if bp then
                for _, v in pairs(bp:GetChildren()) do
                    if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                        SelectWeaponGun = v.Name
                    end
                end
            end
        end)
        wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: FAST ATTACK
-- ═══════════════════════════════════════════════════
spawn(function()
    local Net, RegAtk, RegHit
    pcall(function()
        Net    = ReplicatedStorage:WaitForChild("Modules",5):WaitForChild("Net",5)
        RegAtk = Net:WaitForChild("RE/RegisterAttack",5)
        RegHit = Net:WaitForChild("RE/RegisterHit",5)
    end)

    local function Collect(folder)
        local list, base = {}, nil
        if not folder then return list, base end
        for _, e in ipairs(folder:GetChildren()) do
            local head = e:FindFirstChild("Head")
            if head and Alive(e) and e ~= Char(LP) then
                local ok, d = pcall(function()
                    return LP:DistanceFromCharacter(head.Position)
                end)
                if ok and d and d < 100 then
                    table.insert(list, {e, head}); base = head
                end
            end
        end
        return list, base
    end

    while task.wait(0) do
        if not G.FastAttack then
            task.wait((G.FastAttackDelay or 5) / 100)
            continue
        end
        local char = Char(LP)
        if not char then continue end
        pcall(function()
            local eList, b1 = Collect(workspace:FindFirstChild("Enemies"))
            local cList, b2 = Collect(workspace:FindFirstChild("Characters"))
            for _, d in ipairs(cList) do table.insert(eList, d) end
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("LeftClickRemote") then
                for _, d in ipairs(eList) do
                    local rp = d[1]:FindFirstChild("HumanoidRootPart")
                    if rp then
                        local dir = (rp.Position - char:GetPivot().Position).Unit
                        pcall(function() tool.LeftClickRemote:FireServer(dir, 1) end)
                    end
                end
            elseif #eList > 0 and RegAtk and RegHit then
                RegAtk:FireServer(0)
                RegHit:FireServer(b1 or b2, eList)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: AIMBOT GUN
-- ═══════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not G.AimbotGun then return end
    local t = GetNearest()
    if not t then return end
    local tc = Char(t);  if not tc then return end
    local ch = Char(LP); if not ch then return end
    local tp = TargetPart(tc); if not tp then return end
    local gun = ch:FindFirstChild(SelectWeaponGun)
    if gun and gun:FindFirstChild("RemoteFunctionShoot") then
        pcall(function() gun.RemoteFunctionShoot:InvokeServer(tp.Position, tp) end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: AIMBOT SKILL
-- ═══════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not G.AimbotSkill then return end
    local t = GetNearest(); if not t then return end
    local tc = Char(t);     if not tc then return end
    local ch = Char(LP);    if not ch then return end
    local tp = TargetPart(tc); if not tp then return end
    local tool = ch:FindFirstChildOfClass("Tool")
    if tool and ch:FindFirstChild(tool.Name) then
        local tr = ch[tool.Name]
        if tr:FindFirstChild("MousePos") then
            pcall(function() tr.RemoteEvent:FireServer(tp.Position) end)
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: SILENT AIM  (fixed nil gg bug)
-- ═══════════════════════════════════════════════════
spawn(function()
    pcall(function()
        local raw  = getrawmetatable(game)
        local orig = raw.__namecall
        setreadonly(raw, false)
        raw.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}
            if G.SilentAim and method == "FireServer" then
                local t = GetNearest()
                if t then
                    local tp = TargetPart(Char(t))
                    if tp then
                        SilentAimPos = tp.Position
                        for i, v in ipairs(args) do
                            if typeof(v) == "Vector3" then args[i] = SilentAimPos end
                        end
                    end
                end
            end
            return orig(self, unpack(args))
        end)
        setreadonly(raw, true)
    end)
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: CAM LOCK
-- ═══════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not G.CamLock then return end
    local t = GetNearest(); if not t then return end
    local tp = TargetPart(Char(t))
    if tp then
        local cam = GetCam()
        cam.CFrame = CFrame.new(cam.CFrame.Position, tp.Position)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: ESP PLAYER  (with range check)
-- ═══════════════════════════════════════════════════
spawn(function()
    while wait(0.4) do
        pcall(function()
            for _, v in ipairs(Players:GetPlayers()) do
                if v == LP then continue end
                local c = Char(v); if not c then continue end
                local head = Head(c); if not head then continue end
                local myR = Root(Char(LP))
                local dist = myR and (head.Position - myR.Position).Magnitude or math.huge

                if G.ESPPlayer and dist <= (G.ESPRange or 500) then
                    if not head:FindFirstChild("BESP_"..ESPTag) then
                        local bg = Instance.new("BillboardGui", head)
                        bg.Name = "BESP_"..ESPTag; bg.AlwaysOnTop = true
                        bg.Size = UDim2.new(0,200,0,60)
                        bg.StudsOffset = Vector3.new(0,3,0)

                        local nl = Instance.new("TextLabel", bg)
                        nl.Name="NameLbl"; nl.Size=UDim2.new(1,0,0,20)
                        nl.BackgroundTransparency=1; nl.Font=Enum.Font.GothamBold
                        nl.TextSize=13; nl.TextStrokeTransparency=0.3
                        nl.TextStrokeColor3=Color3.new()

                        local il = Instance.new("TextLabel", bg)
                        il.Name="InfoLbl"; il.Size=UDim2.new(1,0,0,14)
                        il.Position=UDim2.new(0,0,0,20); il.BackgroundTransparency=1
                        il.Font=Enum.Font.Gotham; il.TextSize=11
                        il.TextColor3=Color3.fromRGB(200,200,200)
                        il.TextStrokeTransparency=0.4
                        il.TextStrokeColor3=Color3.new()

                        local bbg = Instance.new("Frame", bg)
                        bbg.Name="BarBg"; bbg.Size=UDim2.new(1,0,0,4)
                        bbg.Position=UDim2.new(0,0,0,36)
                        bbg.BackgroundColor3=Color3.fromRGB(40,40,40)
                        bbg.BorderSizePixel=0
                        Instance.new("UICorner",bbg).CornerRadius=UDim.new(1,0)

                        local bf = Instance.new("Frame", bbg)
                        bf.Name="BarFill"; bf.Size=UDim2.new(1,0,1,0)
                        bf.BackgroundColor3=Color3.fromRGB(140,60,220)
                        bf.BorderSizePixel=0
                        Instance.new("UICorner",bf).CornerRadius=UDim.new(1,0)
                    end
                    local esp = head:FindFirstChild("BESP_"..ESPTag)
                    if esp then
                        local studs = myR and (head.Position-myR.Position).Magnitude or 0
                        local hm = Hum(c)
                        local hp = hm and (hm.Health/hm.MaxHealth) or 0
                        esp.NameLbl.Text = v.Name.." [Lv."..GetLevel(v).."]"
                        esp.NameLbl.TextColor3 = TeamColor(v)
                        esp.InfoLbl.Text = M(studs).."m"
                        local fill = esp.BarBg:FindFirstChild("BarFill")
                        if fill then
                            fill.Size = UDim2.new(math.clamp(hp,0,1),0,1,0)
                            fill.BackgroundColor3 = hp>0.6
                                and Color3.fromRGB(100,220,120)
                                or hp>0.3
                                and Color3.fromRGB(230,190,0)
                                or Color3.fromRGB(220,50,50)
                        end
                    end
                else
                    local esp = head:FindFirstChild("BESP_"..ESPTag)
                    if esp then esp:Destroy() end
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: WALK ON WATER
-- ═══════════════════════════════════════════════════
spawn(function()
    while wait(1) do
        pcall(function()
            local m = workspace:FindFirstChild("Map")
            local p = m and m:FindFirstChild("WaterBase-Plane")
            if p then
                p.Size = G.WalkWater
                    and Vector3.new(1000,112,1000)
                    or  Vector3.new(1000,80,1000)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: SAFE MODE  (configurable threshold)
-- ═══════════════════════════════════════════════════
spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not G.SafeMode then return end
            local c = Char(LP)
            local h = Hum(c); local r = Root(c)
            if h and r and h.Health < (G.SafeHealthThreshold or 5500) then
                r.CFrame = r.CFrame + Vector3.new(0,200,0)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: SPEED HACK  (resets when toggled off)
-- ═══════════════════════════════════════════════════
spawn(function()
    local wasOn = false
    while task.wait(0.1) do
        pcall(function()
            local h = Hum(Char(LP))
            if not h then return end
            if G.SpeedHack then
                h.WalkSpeed = G.SpeedValue or 50
                wasOn = true
            elseif wasOn then
                h.WalkSpeed = 16
                wasOn = false
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: HAKI
-- ═══════════════════════════════════════════════════
spawn(function()
    while wait(0.5) do
        pcall(function()
            if G.Haki then
                local r = ReplicatedStorage:FindFirstChild("Remotes")
                local ce = r and r:FindFirstChild("CommE")
                if ce then ce:FireServer("ActivateHaki") end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: AUTO V3
-- ═══════════════════════════════════════════════════
spawn(function()
    while wait(0.5) do
        pcall(function()
            if G.AutoV3 then
                ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: AUTO V4
-- ═══════════════════════════════════════════════════
spawn(function()
    while wait(0.5) do
        pcall(function()
            if G.AutoV4 then
                VirtualInput:SendKeyEvent(true,"Y",false,game)
                task.wait(0.05)
                VirtualInput:SendKeyEvent(false,"Y",false,game)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- FEATURE: HIGH PERFORMANCE
-- ═══════════════════════════════════════════════════
spawn(function()
    while wait(2) do
        pcall(function()
            if G.HighPerformance then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                RunService:Set3dRenderingEnabled(true)
                local ter = workspace:FindFirstChildOfClass("Terrain")
                if ter then ter.WaterWaveSize=0; ter.WaterWaveSpeed=0 end
                for _,v in ipairs(workspace:GetDescendants()) do
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

-- ═══════════════════════════════════════════════════════════════
--    ██╗   ██╗ ██╗        NOVA GLASS UI
--    ██║   ██║ ██║        Black × Purple · Glass · Liquid
--    ██║   ██║ ██║
--    ╚██████╔╝ ██║
--     ╚═════╝  ╚═╝
-- ═══════════════════════════════════════════════════════════════

-- ── Colour Palette ──────────────────────────────
local C = {
    bg      = Color3.fromRGB(10, 7, 18),
    panel   = Color3.fromRGB(16, 12, 28),
    card    = Color3.fromRGB(22, 17, 38),
    glass   = Color3.fromRGB(28, 22, 48),
    accent  = Color3.fromRGB(138, 58, 218),
    accent2 = Color3.fromRGB(175, 100, 255),
    glow    = Color3.fromRGB(160, 80, 255),
    text    = Color3.fromRGB(232, 228, 242),
    sub     = Color3.fromRGB(130, 120, 155),
    dim     = Color3.fromRGB(80, 70, 100),
    on      = Color3.fromRGB(138, 58, 218),
    off     = Color3.fromRGB(38, 32, 52),
    divider = Color3.fromRGB(50, 40, 68),
}

local TF = TweenInfo.new(0.18, Enum.EasingStyle.Quint)
local TS = TweenInfo.new(0.35, Enum.EasingStyle.Quint)

-- ── ScreenGui ───────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "BunniR_Nova"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
pcall(function() if syn then syn.protect_gui(gui) end; gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

-- ── Drag Helper ─────────────────────────────────
local function MakeDraggable(frame, handle)
    local drag, dI, dS, dP
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; dS=i.Position; dP=frame.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement
            or i.UserInputType==Enum.UserInputType.Touch then dI=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i==dI then
            local d=i.Position-dS
            frame.Position=UDim2.new(dP.X.Scale,dP.X.Offset+d.X,dP.Y.Scale,dP.Y.Offset+d.Y)
        end
    end)
end

-- ── Notification System ─────────────────────────
local nC = Instance.new("Frame", gui)
nC.Size=UDim2.new(0,240,1,0); nC.Position=UDim2.new(1,-250,0,0)
nC.BackgroundTransparency=1; nC.ClipsDescendants=false
local nL = Instance.new("UIListLayout", nC)
nL.Padding=UDim.new(0,5); nL.VerticalAlignment=Enum.VerticalAlignment.Bottom
nL.SortOrder=Enum.SortOrder.LayoutOrder

local function Notify(txt, dur)
    dur = dur or 2.5
    local f = Instance.new("Frame", nC)
    f.Size=UDim2.new(1,0,0,30); f.BackgroundColor3=C.panel
    f.BackgroundTransparency=0.12; f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,6)
    local s=Instance.new("UIStroke",f); s.Color=C.accent; s.Thickness=1; s.Transparency=0.5
    -- gradient glass
    local gg=Instance.new("UIGradient",f)
    gg.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.1),
        NumberSequenceKeypoint.new(0.5,0.25),
        NumberSequenceKeypoint.new(1,0.1)})
    gg.Rotation=25
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-14,1,0); l.Position=UDim2.new(0,7,0,0)
    l.BackgroundTransparency=1; l.Font=Enum.Font.GothamSemibold
    l.TextSize=10; l.TextColor3=C.text; l.TextXAlignment=Enum.TextXAlignment.Left
    l.Text=txt
    f.Position=UDim2.new(1,0,0,0)
    TweenService:Create(f,TS,{Position=UDim2.new(0,0,0,0)}):Play()
    task.delay(dur, function()
        TweenService:Create(f,TS,{Position=UDim2.new(1,0,0,0),BackgroundTransparency=1}):Play()
        task.wait(0.4); pcall(function() f:Destroy() end)
    end)
end

-- ── UI Builder Helpers ──────────────────────────
local orderN = 0
local function O() orderN=orderN+1; return orderN end

-- Glass gradient applied to a frame
local function ApplyGlass(frame)
    local g = Instance.new("UIGradient", frame)
    g.Color = ColorSequence.new(Color3.new(1,1,1))
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.5, 0.72),
        NumberSequenceKeypoint.new(1, 0.55)})
    g.Rotation = 35
    return g
end

-- Section header
local function Section(parent, name)
    local f = Instance.new("Frame", parent)
    f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1; f.LayoutOrder=O()
    local line = Instance.new("Frame", f)
    line.Size=UDim2.new(1,-16,0,1); line.Position=UDim2.new(0,8,1,-1)
    line.BackgroundColor3=C.divider; line.BackgroundTransparency=0.5; line.BorderSizePixel=0
    local l = Instance.new("TextLabel", f)
    l.Size=UDim2.new(1,-16,1,0); l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Font=Enum.Font.GothamBold; l.TextSize=9
    l.Text=name:upper(); l.TextColor3=C.accent; l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextTransparency=0.15
end

-- 
