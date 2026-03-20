-- ╔══════════════════════════════════════════╗
-- ║        BUNNI_R  ·  Matsune PVP           ║
-- ║  Aimbot · ESP · CamLock · SilentAim      ║
-- ║  FastAttack · HighJump · SafeMode · V3/V4║
-- ╚══════════════════════════════════════════╝

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualInput       = game:GetService("VirtualInputManager")
local RenderSettings     = settings().Rendering

local LP   = Players.LocalPlayer
local Cam  = workspace.CurrentCamera
local ESPTag = math.random(1,999999)

-- ── Globals ──────────────────────────────────────────────────────────────
_G.AimbotGun       = false
_G.AimbotSkill     = false
_G.AutoTarget      = false
_G.ESPPlayer       = false
_G.WalkWater       = false
_G.SafeMode        = false
_G.FastAttack      = false
_G.CamLock         = false
_G.SilentAim       = false
_G.AutoV3          = false
_G.AutoV4          = false
_G.HighPerformance = false
_G.JumpPower       = 100

local SelectWeaponGun  = ""
local SilentAimPos     = nil

-- ── Helpers ──────────────────────────────────────────────────────────────
local function M(s) return math.floor(s * 0.28) end  -- studs → metres

local function GetNearest()
    local best, bestD = nil, math.huge
    local myChar = LP.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LP and v.Character
            and v.Character:FindFirstChild("HumanoidRootPart")
            and v.Character:FindFirstChild("Humanoid")
            and v.Character.Humanoid.Health > 0 then
            local d = (v.Character.HumanoidRootPart.Position
                - myChar.HumanoidRootPart.Position).Magnitude
            if d < bestD then bestD = d; best = v end
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
    if t:lower():find("marine") then return Color3.fromRGB(80,170,255) end
    if t:lower():find("pirate") then return Color3.fromRGB(255,70,70) end
    return Color3.fromRGB(200,200,200)
end

-- ── Track gun ────────────────────────────────────────────────────────────
spawn(function()
    while wait(0.5) do pcall(function()
        for _, v in pairs(LP.Backpack:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
                SelectWeaponGun = v.Name
            end
        end
    end) end
end)

-- ── Fast Attack ──────────────────────────────────────────────────────────
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

    while task.wait(0) do
        if not _G.FastAttack then task.wait(0.05); continue end
        local char = LP.Character; if not char then continue end
        local eList, b1 = Collect(workspace:FindFirstChild("Enemies"))
        local cList, b2 = Collect(workspace:FindFirstChild("Characters"))
        for _, d in ipairs(cList) do table.insert(eList, d) end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("LeftClickRemote") then
            for _, d in ipairs(eList) do
                local dir = (d[1].HumanoidRootPart.Position - char:GetPivot().Position).Unit
                pcall(function() tool.LeftClickRemote:FireServer(dir,1) end)
            end
        elseif #eList > 0 then
            RegAtk:FireServer(0)
            RegHit:FireServer(b1 or b2, eList)
        end
    end
end)

-- ── Aimbot Gun ───────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not _G.AimbotGun then return end
    local t = GetNearest(); if not t or not t.Character then return end
    local char = LP.Character; if not char then return end
    local gun = char:FindFirstChild(SelectWeaponGun)
    if gun and gun:FindFirstChild("RemoteFunctionShoot") then
        pcall(function()
            gun.RemoteFunctionShoot:InvokeServer(
                t.Character.HumanoidRootPart.Position,
                t.Character.HumanoidRootPart)
        end)
    end
end)

-- ── Aimbot Skill ─────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not _G.AimbotSkill then return end
    local t = GetNearest(); if not t or not t.Character then return end
    local char = LP.Character; if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and char:FindFirstChild(tool.Name) then
        local tr = char[tool.Name]
        if tr:FindFirstChild("MousePos") then
            pcall(function()
                tr.RemoteEvent:FireServer(t.Character.HumanoidRootPart.Position)
            end)
        end
    end
end)

-- ── Silent Aim ───────────────────────────────────────────────────────────
spawn(function()
    local old = gg and gg.__namecall
    pcall(function()
        local raw = getrawmetatable(game)
        local orig = raw.__namecall
        setreadonly(raw, false)
        raw.__namecall = newcclosure(function(...)
            local method = getnamecallmethod()
            local args = {...}
            if _G.SilentAim and method == "FireServer" then
                local t = GetNearest()
                if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                    SilentAimPos = t.Character.HumanoidRootPart.Position
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = SilentAimPos
                        end
                    end
                end
            end
            return orig(unpack(args))
        end)
        setreadonly(raw, true)
    end)
end)

-- ── CamLock ──────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not _G.CamLock then return end
    local t = GetNearest()
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = t.Character.HumanoidRootPart
        Cam.CFrame = CFrame.new(Cam.CFrame.Position, hrp.Position)
    end
end)

-- ── ESP Player ───────────────────────────────────────────────────────────
spawn(function()
    while wait(0.4) do pcall(function()
        for _, v in ipairs(Players:GetPlayers()) do
            if v == LP then continue end
            if not v.Character then continue end
            local head = v.Character:FindFirstChild("Head")
            if not head then continue end

            if _G.ESPPlayer then
                if not head:FindFirstChild("BESP_"..ESPTag) then
                    local bg = Instance.new("BillboardGui", head)
                    bg.Name = "BESP_"..ESPTag
                    bg.AlwaysOnTop = true
                    bg.Size = UDim2.new(0,200,0,60)
                    bg.StudsOffset = Vector3.new(0,3,0)

                    local name_lbl = Instance.new("TextLabel", bg)
                    name_lbl.Name = "NameLbl"
                    name_lbl.Size = UDim2.new(1,0,0,20)
                    name_lbl.Position = UDim2.new(0,0,0,0)
                    name_lbl.BackgroundTransparency = 1
                    name_lbl.Font = Enum.Font.GothamBold
                    name_lbl.TextSize = 13
                    name_lbl.TextStrokeTransparency = 0.3
                    name_lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)

                    local info_lbl = Instance.new("TextLabel", bg)
                    info_lbl.Name = "InfoLbl"
                    info_lbl.Size = UDim2.new(1,0,0,14)
                    info_lbl.Position = UDim2.new(0,0,0,20)
                    info_lbl.BackgroundTransparency = 1
                    info_lbl.Font = Enum.Font.Gotham
                    info_lbl.TextSize = 11
                    info_lbl.TextColor3 = Color3.fromRGB(200,200,200)
                    info_lbl.TextStrokeTransparency = 0.4
                    info_lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)

                    -- Health bar background
                    local barBg = Instance.new("Frame", bg)
                    barBg.Name = "BarBg"
                    barBg.Size = UDim2.new(1,0,0,5)
                    barBg.Position = UDim2.new(0,0,0,36)
                    barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
                    barBg.BorderSizePixel = 0
                    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

                    -- Health bar fill
                    local barFill = Instance.new("Frame", barBg)
                    barFill.Name = "BarFill"
                    barFill.Size = UDim2.new(1,0,1,0)
                    barFill.BackgroundColor3 = Color3.fromRGB(80,220,80)
                    barFill.BorderSizePixel = 0
                    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)
                end

                local esp = head:FindFirstChild("BESP_"..ESPTag)
                if esp then
                    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local studs  = myRoot and (head.Position - myRoot.Position).Magnitude or 0
                    local metres = M(studs)
                    local hum    = v.Character:FindFirstChild("Humanoid")
                    local hp     = hum and (hum.Health / hum.MaxHealth) or 0
                    local hpPct  = math.floor(hp * 100)
                    local lvl    = GetLevel(v)
                    local col    = TeamColor(v)

                    esp.NameLbl.Text       = v.Name .. "  [Lv."..lvl.."]"
                    esp.NameLbl.TextColor3 = col
                    esp.InfoLbl.Text       = metres.."m"

                    -- Health bar
                    local fill = esp.BarBg:FindFirstChild("BarFill")
                    if fill then
                        fill.Size = UDim2.new(math.clamp(hp,0,1), 0, 1, 0)
                        -- colour shifts: green → yellow → red
                        if hp > 0.6 then
                            fill.BackgroundColor3 = Color3.fromRGB(60,210,60)
                        elseif hp > 0.3 then
                            fill.BackgroundColor3 = Color3.fromRGB(230,190,0)
                        else
                            fill.BackgroundColor3 = Color3.fromRGB(220,50,50)
                        end
                    end
                end
            else
                local esp = head:FindFirstChild("BESP_"..ESPTag)
                if esp then esp:Destroy() end
            end
        end
    end) end
end)

-- ── Walk on Water ────────────────────────────────────────────────────────
spawn(function()
    while wait(1) do pcall(function()
        local p = workspace.Map:FindFirstChild("WaterBase-Plane")
        if p then p.Size = _G.WalkWater
            and Vector3.new(1000,112,1000)
            or  Vector3.new(1000,80,1000)
        end
    end) end
end)

-- ── Safe Mode ────────────────────────────────────────────────────────────
spawn(function()
    while task.wait(0.1) do pcall(function()
        if not _G.SafeMode then return end
        local c = LP.Character
        if c and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart")
            and c.Humanoid.Health < 5500 then
            c.HumanoidRootPart.CFrame = c.HumanoidRootPart.CFrame + Vector3.new(0,200,0)
        end
    end) end
end)

-- ── Auto V3 ──────────────────────────────────────────────────────────────
spawn(function()
    while wait(0.5) do pcall(function()
        if _G.AutoV3 then
            ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
        end
    end) end
end)

-- ── Auto V4 ──────────────────────────────────────────────────────────────
spawn(function()
    while wait(0.5) do pcall(function()
        if _G.AutoV4 then
            VirtualInput:SendKeyEvent(true,  "Y", false, game)
            task.wait(0.05)
            VirtualInput:SendKeyEvent(false, "Y", false, game)
        end
    end) end
end)

-- ── High Performance ─────────────────────────────────────────────────────
spawn(function()
    while wait(2) do pcall(function()
        if _G.HighPerformance then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            game:GetService("RunService"):Set3dRenderingEnabled(true)
            workspace:FindFirstChildOfClass("Terrain").WaterWaveSize = 0
            workspace:FindFirstChildOfClass("Terrain").WaterWaveSpeed = 0
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke")
                    or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
        end
    end) end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  UI
-- ═══════════════════════════════════════════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "BunniR_PVP"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if syn then syn.protect_gui(gui) end; gui.Parent = game.CoreGui end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

-- Logo asset (pixel bunny with crosshair — use the user's image as rbxassetid if uploaded,
-- otherwise we draw it inline as an SVG-style ImageLabel placeholder)
local LOGO_ID = "rbxassetid://0" -- replace with actual uploaded asset id if available

-- ── Colour palette ────────────────────────────────────────────────────────
local C = {
    bg      = Color3.fromRGB(10, 10, 10),
    bar     = Color3.fromRGB(16, 16, 16),
    row     = Color3.fromRGB(18, 18, 18),
    accent  = Color3.fromRGB(220, 30,  30),   -- red crosshair colour from logo
    accent2 = Color3.fromRGB(255, 255, 255),
    dim     = Color3.fromRGB(80,  80,  80),
    text    = Color3.fromRGB(210, 210, 210),
    on      = Color3.fromRGB(220, 40,  40),
    off     = Color3.fromRGB(38,  38,  38),
}

-- ── Drag helper ──────────────────────────────────────────────────────────
local function MakeDraggable(frame, handle)
    local drag, dInput, dStart, dPos
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; dStart = inp.Position; dPos = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then drag = false end
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

-- ── Toggle builder ───────────────────────────────────────────────────────
local orderN = 0
local function O() orderN = orderN+1; return orderN end

local function Section(parent, name)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,0,0,18); f.BackgroundTransparency = 1; f.LayoutOrder = O()
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1
    l.Text = name:upper(); l.Font = Enum.Font.GothamBold; l.TextSize = 9
    l.TextColor3 = C.accent; l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextStrokeTransparency = 0.6; l.TextStrokeColor3 = C.accent
end

local function Toggle(parent, label, flag, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,28); row.BackgroundColor3 = C.row
    row.BorderSizePixel = 0; row.LayoutOrder = O()
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,5)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-48,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = C.text; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0,32,0,16); pill.Position = UDim2.new(1,-40,0.5,-8)
    pill.BackgroundColor3 = C.off; pill.BorderSizePixel = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.new(0,11,0,11); knob.Position = UDim2.new(0,2,0.5,-5.5)
    knob.BackgroundColor3 = Color3.fromRGB(100,100,100); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        _G[flag] = state
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = state and C.on or C.off }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1,-13,0.5,-5.5) or UDim2.new(0,2,0.5,-5.5),
            BackgroundColor3 = state and C.accent2 or Color3.fromRGB(100,100,100)
        }):Play()
        if callback then callback(state) end
    end)
    return row
end

-- ── Main window ──────────────────────────────────────────────────────────
local WIN = Instance.new("Frame", gui)
WIN.Size = UDim2.new(0,220,0,0)   -- height driven by content
WIN.Position = UDim2.new(0.03,0,0.25,0)
WIN.BackgroundColor3 = C.bg
WIN.BorderSizePixel = 0
WIN.ClipsDescendants = true
WIN.AutomaticSize = Enum.AutomaticSize.Y
Instance.new("UICorner", WIN).CornerRadius = UDim.new(0,8)
local ws = Instance.new("UIStroke", WIN)
ws.Color = C.accent; ws.Thickness = 1

-- ── Header ───────────────────────────────────────────────────────────────
local HDR = Instance.new("Frame", WIN)
HDR.Size = UDim2.new(1,0,0,44); HDR.BackgroundColor3 = C.bar; HDR.BorderSizePixel = 0
Instance.new("UICorner", HDR).CornerRadius = UDim.new(0,8)
MakeDraggable(WIN, HDR)

-- Logo image (pixel bunny)
local logoImg = Instance.new("ImageLabel", HDR)
logoImg.Size = UDim2.new(0,32,0,32)
logoImg.Position = UDim2.new(0,6,0.5,-16)
logoImg.BackgroundTransparency = 1
logoImg.Image = LOGO_ID          -- shows blank until user uploads; that's fine
logoImg.ImageColor3 = Color3.fromRGB(255,255,255)
-- Fallback text icon if image is blank
local fallbackIcon = Instance.new("TextLabel", logoImg)
fallbackIcon.Size = UDim2.new(1,0,1,0)
fallbackIcon.BackgroundTransparency = 1
fallbackIcon.Text = "🐰"
fallbackIcon.Font = Enum.Font.GothamBold
fallbackIcon.TextSize = 22
fallbackIcon.TextColor3 = C.accent2

local titleLbl = Instance.new("TextLabel", HDR)
titleLbl.Size = UDim2.new(1,-90,1,0)
titleLbl.Position = UDim2.new(0,44,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BUNNI_R"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextColor3 = C.accent2
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local subLbl = Instance.new("TextLabel", HDR)
subLbl.Size = UDim2.new(1,-90,0,12)
subLbl.Position = UDim2.new(0,44,1,-14)
subLbl.BackgroundTransparency = 1
subLbl.Text = "PVP SUITE  v1.2"
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 9
subLbl.TextColor3 = C.dim
subLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Minimise button
local MINBTN = Instance.new("TextButton", HDR)
MINBTN.Size = UDim2.new(0,24,0,24); MINBTN.Position = UDim2.new(1,-28,0.5,-12)
MINBTN.BackgroundColor3 = Color3.fromRGB(30,30,30); MINBTN.Text = "−"
MINBTN.Font = Enum.Font.GothamBold; MINBTN.TextSize = 14
MINBTN.TextColor3 = C.dim; MINBTN.BorderSizePixel = 0
Instance.new("UICorner", MINBTN).CornerRadius = UDim.new(0,4)

-- ── Target bar ───────────────────────────────────────────────────────────
local TGTROW = Instance.new("Frame", WIN)
TGTROW.Size = UDim2.new(1,-16,0,24); TGTROW.Position = UDim2.new(0,8,0,50)
TGTROW.BackgroundColor3 = Color3.fromRGB(20,20,20); TGTROW.BorderSizePixel = 0
Instance.new("UICorner", TGTROW).CornerRadius = UDim.new(0,5)
local tgtLbl = Instance.new("TextLabel", TGTROW)
tgtLbl.Size = UDim2.new(1,-8,1,0); tgtLbl.Position = UDim2.new(0,8,0,0)
tgtLbl.BackgroundTransparency = 1; tgtLbl.Text = "🎯  No target"
tgtLbl.Font = Enum.Font.GothamSemibold; tgtLbl.TextSize = 10
tgtLbl.TextColor3 = C.dim; tgtLbl.TextXAlignment = Enum.TextXAlignment.Left

spawn(function()
    while wait(0.25) do pcall(function()
        local t = GetNearest()
        if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            local myR = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local d = myR and M((t.Character.HumanoidRootPart.Position-myR.Position).Magnitude) or 0
            tgtLbl.Text = "🎯  "..t.Name.."  [Lv."..GetLevel(t).."]  ·  "..d.."m"
            tgtLbl.TextColor3 = TeamColor(t)
        else
            tgtLbl.Text = "🎯  No target in range"
            tgtLbl.TextColor3 = C.dim
        end
    end) end
end)

-- ── Scrollable content ───────────────────────────────────────────────────
local SCROLL = Instance.new("ScrollingFrame", WIN)
SCROLL.Size = UDim2.new(1,0,0,290)
SCROLL.Position = UDim2.new(0,0,0,80)
SCROLL.BackgroundTransparency = 1; SCROLL.BorderSizePixel = 0
SCROLL.ScrollBarThickness = 2
SCROLL.ScrollBarImageColor3 = C.accent
SCROLL.CanvasSize = UDim2.new(0,0,0,0)

local SL = Instance.new("UIListLayout", SCROLL)
SL.Padding = UDim.new(0,3); SL.SortOrder = Enum.SortOrder.LayoutOrder
local SP = Instance.new("UIPadding", SCROLL)
SP.PaddingLeft=UDim.new(0,8); SP.PaddingRight=UDim.new(0,8)
SP.PaddingTop=UDim.new(0,6); SP.PaddingBottom=UDim.new(0,6)

SL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SCROLL.CanvasSize = UDim2.new(0,0,0, SL.AbsoluteContentSize.Y+12)
end)

-- ── Build toggles ────────────────────────────────────────────────────────
Section(SCROLL, "⚡  aimbot")
Toggle(SCROLL, "Auto Target Nearest", "AutoTarget")
Toggle(SCROLL, "Aimbot Gun",          "AimbotGun")
Toggle(SCROLL, "Aimbot Skill",        "AimbotSkill")
Toggle(SCROLL, "Silent Aim",          "SilentAim")
Toggle(SCROLL, "CamLock",             "CamLock")
Toggle(SCROLL, "Fast Attack  (M1)",   "FastAttack")

Section(SCROLL, "👁  esp")
Toggle(SCROLL, "Player ESP", "ESPPlayer")

Section(SCROLL, "🛡  utility")
Toggle(SCROLL, "Walk on Water",     "WalkWater")
Toggle(SCROLL, "Safe Mode",         "SafeMode")
Toggle(SCROLL, "Auto V3",           "AutoV3")
Toggle(SCROLL, "Auto V4",           "AutoV4")
Toggle(SCROLL, "High Performance",  "HighPerformance", function(on)
    if on then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end
end)

-- Spacer
local foot = Instance.new("TextLabel", SCROLL)
foot.Size = UDim2.new(1,0,0,14); foot.BackgroundTransparency = 1
foot.Text = "github.com/rhoscript/BUNNI_R"
foot.Font = Enum.Font.Gotham; foot.TextSize = 8
foot.TextColor3 = Color3.fromRGB(40,40,40)
foot.TextXAlignment = Enum.TextXAlignment.Center
foot.LayoutOrder = O()

-- ── Minimise logic ───────────────────────────────────────────────────────
local mini = false
MINBTN.MouseButton1Click:Connect(function()
    mini = not mini
    SCROLL.Visible = not mini; TGTROW.Visible = not mini
    TweenService:Create(WIN, TweenInfo.new(0.18,Enum.EasingStyle.Quad), {
        Size = mini
            and UDim2.new(0,220,0,44)
            or  UDim2.new(0,220,0,380)
    }):Play()
    MINBTN.Text = mini and "+" or "−"
end)

-- ════════════════════════════════════════════════════════════════════════════
--  FLOATING HIGH-JUMP BUTTON  (top-right)
-- ════════════════════════════════════════════════════════════════════════════
local JUMP_BTN = Instance.new("Frame", gui)
JUMP_BTN.Size = UDim2.new(0,54,0,54)
JUMP_BTN.Position = UDim2.new(1,-68,0,14)
JUMP_BTN.BackgroundColor3 = Color3.fromRGB(15,15,15)
JUMP_BTN.BorderSizePixel = 0
Instance.new("UICorner", JUMP_BTN).CornerRadius = UDim.new(1,0)
local jStroke = Instance.new("UIStroke", JUMP_BTN)
jStroke.Color = C.accent; jStroke.Thickness = 1.2
MakeDraggable(JUMP_BTN, JUMP_BTN)

local jIcon = Instance.new("TextLabel", JUMP_BTN)
jIcon.Size = UDim2.new(1,0,0.55,0); jIcon.Position = UDim2.new(0,0,0,4)
jIcon.BackgroundTransparency = 1; jIcon.Text = "↑"
jIcon.Font = Enum.Font.GothamBold; jIcon.TextSize = 22
jIcon.TextColor3 = C.accent2

local jLabel = Instance.new("TextLabel", JUMP_BTN)
jLabel.Size = UDim2.new(1,0,0,13); jLabel.Position = UDim2.new(0,0,1,-14)
jLabel.BackgroundTransparency = 1; jLabel.Text = "JUMP"
jLabel.Font = Enum.Font.GothamBold; jLabel.TextSize = 8
jLabel.TextColor3 = C.dim

-- Clickable layer
local jBtn = Instance.new("TextButton", JUMP_BTN)
jBtn.Size = UDim2.new(1,0,1,0); jBtn.BackgroundTransparency = 1; jBtn.Text = ""

jBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local char = LP.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            local orig = hum.JumpPower
            hum.JumpPower = _G.JumpPower
            hum.Jump = true
            task.wait(0.1)
            hum.JumpPower = orig
        end
    end)
    -- pulse animation
    TweenService:Create(jStroke, TweenInfo.new(0.08), {Thickness=2.5, Color=Color3.fromRGB(255,80,80)}):Play()
    task.wait(0.15)
    TweenService:Create(jStroke, TweenInfo.new(0.2), {Thickness=1.2, Color=C.accent}):Play()
end)

-- ── Jump power panel (shown on right-click / hover on JUMP button) ───────
local JP_PANEL = Instance.new("Frame", gui)
JP_PANEL.Size = UDim2.new(0,140,0,60)
JP_PANEL.Position = UDim2.new(1,-216,0,14)
JP_PANEL.BackgroundColor3 = Color3.fromRGB(14,14,14)
JP_PANEL.BorderSizePixel = 0; JP_PANEL.Visible = false
Instance.new("UICorner", JP_PANEL).CornerRadius = UDim.new(0,7)
local jpStroke = Instance.new("UIStroke", JP_PANEL)
jpStroke.Color = C.accent; jpStroke.Thickness = 1

local jpTitle = Instance.new("TextLabel", JP_PANEL)
jpTitle.Size = UDim2.new(1,0,0,18); jpTitle.Position = UDim2.new(0,8,0,4)
jpTitle.BackgroundTransparency = 1; jpTitle.Text = "Jump Power"
jpTitle.Font = Enum.Font.GothamBold; jpTitle.TextSize = 10
jpTitle.TextColor3 = C.accent; jpTitle.TextXAlignment = Enum.TextXAlignment.Left

local jpValLbl = Instance.new("TextLabel", JP_PANEL)
jpValLbl.Size = UDim2.new(0,36,0,18); jpValLbl.Position = UDim2.new(1,-44,0,4)
jpValLbl.BackgroundTransparency = 1; jpValLbl.Text = tostring(_G.JumpPower)
jpValLbl.Font = Enum.Font.GothamBold; jpValLbl.TextSize = 10
jpValLbl.TextColor3 = C.accent2; jpValLbl.TextXAlignment = Enum.TextXAlignment.Right

-- Slider track
local sliderBg = Instance.new("Frame", JP_PANEL)
sliderBg.Size = UDim2.new(1,-16,0,6); sliderBg.Position = UDim2.new(0,8,0,30)
sliderBg.BackgroundColor3 = Color3.fromRGB(40,40,40); sliderBg.BorderSizePixel = 0
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1,0)

local sliderFill = Instance.new("Frame", sliderBg)
sliderFill.Size = UDim2.new((_G.JumpPower/500),0,1,0)
sliderFill.BackgroundColor3 = C.accent; sliderFill.BorderSizePixel = 0
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1,0)

local sliderKnob = Instance.new("Frame", sliderBg)
sliderKnob.Size = UDim2.new(0,14,0,14); sliderKnob.AnchorPoint = Vector2.new(0.5,0.5)
sliderKnob.Position = UDim2.new((_G.JumpPower/500),0,0.5,0)
sliderKnob.BackgroundColor3 = C.accent2; sliderKnob.BorderSizePixel = 0
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1,0)

-- Slider drag
local slDragging = false
sliderKnob.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then slDragging = true end
end)
sliderKnob.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then slDragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if slDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = (i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        rel = math.clamp(rel,0,1)
        _G.JumpPower = math.floor(rel * 500)
        if _G.JumpPower < 10 then _G.JumpPower = 10 end
        sliderFill.Size = UDim2.new(rel,0,1,0)
        sliderKnob.Position = UDim2.new(rel,0,0.5,0)
        jpValLbl.Text = tostring(_G.JumpPower)
    end
end)

-- Show/hide panel on hover
JUMP_BTN.MouseEnter:Connect(function()  JP_PANEL.Visible = true  end)
JUMP_BTN.MouseLeave:Connect(function()
    task.wait(0.4)
    if not slDragging then JP_PANEL.Visible = false end
end)
JP_PANEL.MouseLeave:Connect(function()
    if not slDragging then JP_PANEL.Visible = false end
end)
