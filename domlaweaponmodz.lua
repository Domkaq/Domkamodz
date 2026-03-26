-- [[ DOMKAMODZ X WEAPON MODS — V7 — FIXED MOVEMENT & VISIBLE UI ]]
local Config = {
    NoRecoil       = false,
    NoSpread       = false,
    InfiniteAmmo   = false,
    RapidFire      = false,
    RapidFireDelay = 0.01,
    GodMovement    = false,
    AutoBhop       = false,
    GodMovementKey = Enum.KeyCode.V,
    ToggleKey      = Enum.KeyCode.RightShift,
    Active         = true
}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local LP         = Players.LocalPlayer
local _C         = {}

local Theme = {
    accent = Color3.fromRGB(130,80,255),
    bg     = Color3.fromRGB(12,12,18),
    card   = Color3.fromRGB(22,22,32),
    text   = Color3.fromRGB(225,225,240),
    border = Color3.fromRGB(55,55,75),
    gold   = Color3.fromRGB(255,200,60),
    green  = Color3.fromRGB(80,255,140),
}

-- capture default movement values from the game
local defaultWalkSpeed = 16
local defaultJumpPower = 50
local defaultGravity   = 196
if LP.Character then
    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        defaultWalkSpeed = hum.WalkSpeed
        defaultJumpPower = hum.JumpPower
    end
end

local function glass(p)
    local f = Instance.new("Frame")
    f.BackgroundColor3       = p.Color or Theme.bg
    f.BackgroundTransparency = p.Tr or 1
    f.BorderSizePixel        = 0
    f.Size                   = p.Size or UDim2.new(0,200,0,200)
    f.Position               = p.Pos  or UDim2.new(0,0,0,0)
    Instance.new("UICorner",f).CornerRadius = p.Corner or UDim.new(0,8)
    local s = Instance.new("UIStroke",f)
    s.Color = p.BC or Theme.border; s.Thickness = 1.2
    f.Parent = p.Parent
    return f
end

local SG   = Instance.new("ScreenGui",CoreGui); SG.ResetOnSpawn = false
local Main = glass({
    Size=UDim2.new(0,280,0,640),
    Pos=UDim2.new(0.5,-140,0.5,-320),
    Parent=SG, BC=Theme.accent
})

local drag,ds,sp = false,Vector2.new(),UDim2.new()
Main.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true; ds=Vector2.new(i.Position.X,i.Position.Y); sp=Main.Position
    end
end)
table.insert(_C,UIS.InputChanged:Connect(function(i)
    if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=Vector2.new(i.Position.X,i.Position.Y)-ds
        Main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end))
table.insert(_C,UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
end))

local TitleL=Instance.new("TextLabel",Main)
TitleL.Text="DOMKAMODZ  ·  Plusmenu"
TitleL.Font=Enum.Font.GothamBold; TitleL.TextColor3=Theme.accent
TitleL.Size=UDim2.new(1,0,0,44); TitleL.BackgroundTransparency=1; TitleL.TextSize=13

local Scroll=Instance.new("ScrollingFrame",Main)
Scroll.Size=UDim2.new(1,-16,1,-50); Scroll.Position=UDim2.new(0,8,0,46)
Scroll.BackgroundTransparency=1; Scroll.BorderSizePixel=0
Scroll.ScrollBarThickness=3; Scroll.ScrollBarImageColor3=Theme.accent

local ULL=Instance.new("UIListLayout",Scroll); ULL.Padding=UDim.new(0,5)
ULL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize=UDim2.new(0,0,0,ULL.AbsoluteContentSize.Y+10)
end)
Instance.new("UIPadding",Scroll).PaddingTop=UDim.new(0,4)

-- GM params
local GM = {
    WalkSpeed  = 36,
    SprintMult = 1.6,
    JumpPower  = 95,
    AirAccel   = 200,
    AirCap     = 38,
    Gravity    = 140,
    AutoSpeed  = 40,
}

local function Lbl(txt,col)
    local f=Instance.new("TextLabel",Scroll)
    f.Text=txt; f.Font=Enum.Font.GothamBold
    f.TextColor3=col or Theme.gold
    f.Size=UDim2.new(1,-4,0,22)
    f.BackgroundTransparency=1
    f.TextXAlignment=Enum.TextXAlignment.Left
    f.TextSize=11
end

local function Div()
    local f=Instance.new("Frame",Scroll)
    f.Size=UDim2.new(1,-4,0,1)
    f.BackgroundColor3=Theme.accent
    f.BackgroundTransparency=0.6
    f.BorderSizePixel=0
end

local function Toggle(name,prop,col,onToggle)
    local b=glass({Color=Theme.card,Size=UDim2.new(1,-4,0,36),Parent=Scroll, Tr=0.85})
    local t=Instance.new("TextLabel",b)
    t.Text=name; t.Font=Enum.Font.GothamMedium
    t.TextColor3=col or Theme.text
    t.Size=UDim2.new(1,-46,1,0); t.Position=UDim2.new(0,10,0,0)
    t.TextXAlignment=Enum.TextXAlignment.Left
    t.BackgroundTransparency=1; t.TextSize=12
    local sw=glass({
        Color=Config[prop] and (col or Theme.accent) or Color3.fromRGB(50,50,62),
        Size=UDim2.new(0,26,0,13),Pos=UDim2.new(1,-36,0.5,-6.5),Parent=b,
        Tr=0
    })
    local tb=Instance.new("TextButton",b)
    tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""
    tb.MouseButton1Click:Connect(function()
        Config[prop]=not Config[prop]
        TweenSvc:Create(sw,TweenInfo.new(0.18),{
            BackgroundColor3=Config[prop] and (col or Theme.accent) or Color3.fromRGB(50,50,62)
        }):Play()
        if onToggle then onToggle(Config[prop]) end
    end)
end

local function Slider(name,mn,mx,dec,sv,cb)
    local sf=glass({Color=Theme.card,Size=UDim2.new(1,-4,0,48),Parent=Scroll, Tr=0.85})
    local tl=Instance.new("TextLabel",sf)
    tl.Text=name..": "..sv; tl.Font=Enum.Font.GothamMedium; tl.TextColor3=Theme.text
    tl.Size=UDim2.new(1,-16,0,24); tl.Position=UDim2.new(0,10,0,3)
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.BackgroundTransparency=1; tl.TextSize=11
    local bar=glass({Color=Color3.fromRGB(34,34,44),Size=UDim2.new(1,-20,0,5),Pos=UDim2.new(0,10,0,35),Parent=sf, Tr=0})
    local p0=math.clamp((sv-mn)/(mx-mn),0,1)
    local fill=glass({Color=Theme.accent,Size=UDim2.new(p0,0,1,0),Parent=bar, Tr=0})
    local knob=glass({Color=Color3.fromRGB(230,220,255),Size=UDim2.new(0,10,0,10),
        Pos=UDim2.new(p0,-5,0.5,-5),Parent=bar,BC=Theme.accent, Tr=0})
    local sd=false
    local function upd()
        local pct=math.clamp((UIS:GetMouseLocation().X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local val=math.floor((mn+(mx-mn)*pct)/dec+0.5)*dec
        fill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,-5,0.5,-5)
        tl.Text=name..": "..val; cb(val)
    end
    sf.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sd=true end end)
    table.insert(_C,UIS.InputChanged:Connect(function(i) if sd and i.UserInputType==Enum.UserInputType.MouseMovement then upd() end end))
    table.insert(_C,UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sd=false end end))
end

local function Keybind(lbl,key)
    local kf=glass({Color=Theme.card,Size=UDim2.new(1,-4,0,36),Parent=Scroll, Tr=0.85})
    local kl=Instance.new("TextLabel",kf)
    kl.Text=lbl..":  ["..Config[key].Name.."]"; kl.Font=Enum.Font.GothamMedium
    kl.TextColor3=Theme.gold; kl.Size=UDim2.new(1,-10,1,0); kl.Position=UDim2.new(0,10,0,0)
    kl.TextXAlignment=Enum.TextXAlignment.Left; kl.BackgroundTransparency=1; kl.TextSize=11
    local ls=false
    local kb=Instance.new("TextButton",kf)
    kb.Size=UDim2.new(1,0,1,0); kb.BackgroundTransparency=1; kb.Text=""
    kb.MouseButton1Click:Connect(function()
        ls=true; kl.Text=lbl..":  [press key...]"
        kl.TextColor3=Color3.fromRGB(255,255,80)
    end)
    table.insert(_C,UIS.InputBegan:Connect(function(i,gp)
        if ls and not gp and i.UserInputType==Enum.UserInputType.Keyboard then
            Config[key]=i.KeyCode
            kl.Text=lbl..":  ["..i.KeyCode.Name.."]"
            kl.TextColor3=Theme.gold; ls=false
        end
    end))
end

-- UI feltöltés
Lbl("⚙  WEAPON MODS", Theme.accent)
Toggle("No Recoil",      "NoRecoil")
Toggle("No Spread",      "NoSpread")
Toggle("Infinite Ammo",  "InfiniteAmmo")
Toggle("Rapid Fire",     "RapidFire")
Slider("Fire Delay",0.01,1.0,0.01,Config.RapidFireDelay,function(v) Config.RapidFireDelay=v end)
Div()
Lbl("⚡  GOD MOVEMENT", Theme.gold)

-- Movement reset and apply functions
local vf       = nil
local att0     = nil
local jumpConn = nil

local function clearVF()
    if vf then
        vf.Force = Vector3.new(0,0,0)
        vf.Parent = nil
        vf:Destroy()
        vf = nil
    end
    if att0 then
        att0:Destroy()
        att0 = nil
    end
end

local function resetMovement()
    workspace.Gravity = defaultGravity
    clearVF()
    if jumpConn then
        jumpConn:Disconnect()
        jumpConn = nil
    end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = defaultWalkSpeed
            hum.JumpPower = defaultJumpPower
        end
    end
end

local function applyMovementSettings()
    if not Config.GodMovement then
        resetMovement()
        return
    end
    -- If God Movement is on, we rely on godStep to set walk/jump each frame,
    -- but we need to ensure the bhop hook is active.
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and (not jumpConn or not jumpConn.Connected) then
            -- hookBhop will be called in godStep if needed, but we can call it here too
            -- Actually the hook is created in onCharAdded and godStep ensures it's connected.
            -- We'll let godStep handle it.
        end
    end
end

-- Create God Movement toggle with callback
Toggle("God Movement", "GodMovement", Theme.gold, function(state)
    if state then
        applyMovementSettings()
    else
        resetMovement()
    end
end)
Toggle("Auto Bhop",      "AutoBhop",    Theme.green)
Keybind("AutoMove Bind", "GodMovementKey")
Slider("Walk Speed", 20,80,1, GM.WalkSpeed, function(v) GM.WalkSpeed=v end)
Slider("Jump Power", 50,150,1,GM.JumpPower, function(v) GM.JumpPower=v end)
Slider("Air Accel",  50,500,5,GM.AirAccel,  function(v) GM.AirAccel=v  end)
Slider("Gravity",    80,220,5,GM.Gravity,   function(v) GM.Gravity=v   end)
Div()

local dB=glass({Color=Color3.fromRGB(160,35,35),Size=UDim2.new(1,-4,0,34),Parent=Scroll,BC=Color3.new(1,0,0), Tr=0})
local dT=Instance.new("TextLabel",dB)
dT.Text="DESTROY SCRIPT"; dT.Font=Enum.Font.GothamBold
dT.TextColor3=Color3.new(1,1,1); dT.Size=UDim2.new(1,0,1,0); dT.BackgroundTransparency=1
local dTr=Instance.new("TextButton",dB)
dTr.Size=UDim2.new(1,0,1,0); dTr.BackgroundTransparency=1; dTr.Text=""
dTr.MouseButton1Click:Connect(function()
    Config.Active=false
    resetMovement()
    for _,c in pairs(_C) do pcall(function() c:Disconnect() end) end
    SG:Destroy()
    if HudSG then HudSG:Destroy() end
end)

-- ── SPEED HUD
HudSG=Instance.new("ScreenGui",CoreGui); HudSG.ResetOnSpawn=false
local HudF=Instance.new("Frame",HudSG)
HudF.Size=UDim2.new(0,180,0,38); HudF.Position=UDim2.new(0.5,-90,0.88,0)
HudF.BackgroundColor3=Color3.fromRGB(8,8,14); HudF.BackgroundTransparency=1
HudF.BorderSizePixel=0; Instance.new("UICorner",HudF).CornerRadius=UDim.new(1.3)
Instance.new("UIStroke",HudF).Color=Theme.accent
local HudTxt=Instance.new("TextLabel",HudF)
HudTxt.Size=UDim2.new(1,0,1,0); HudTxt.BackgroundTransparency=1
HudTxt.Font=Enum.Font.GothamBold; HudTxt.TextSize=18; HudTxt.Text=""
HudF.Visible=false

-- ════════════════════════════════════════════════════════════════
--  GOD MOVEMENT ENGINE  —  V7
-- ════════════════════════════════════════════════════════════════

local function ensureVF(hrp)
    if vf and vf.Parent == hrp then return vf end
    clearVF()
    att0          = Instance.new("Attachment")
    att0.Position = Vector3.new(0,0,0)
    att0.Parent   = hrp
    vf            = Instance.new("VectorForce")
    vf.Attachment0        = att0
    vf.ApplyAtCenterOfMass= true
    vf.RelativeTo         = Enum.ActuatorRelativeTo.World
    vf.Force              = Vector3.new(0,0,0)
    vf.Parent             = hrp
    return vf
end

local function hookBhop(hum)
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = hum.StateChanged:Connect(function(old, new)
        if not Config.Active or not Config.GodMovement then return end
        if new == Enum.HumanoidStateType.Landed then
            if Config.AutoBhop or UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Config.GodMovementKey) then
                task.defer(function()
                    if hum and hum.Parent then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end
        end
    end)
end

local function onCharAdded(char)
    local hum = char:WaitForChild("Humanoid")
    if Config.GodMovement then
        hookBhop(hum)
    else
        hum.WalkSpeed = defaultWalkSpeed
        hum.JumpPower = defaultJumpPower
    end
end
table.insert(_C, LP.CharacterAdded:Connect(onCharAdded))
if LP.Character then
    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if Config.GodMovement then
            hookBhop(hum)
        else
            hum.WalkSpeed = defaultWalkSpeed
            hum.JumpPower = defaultJumpPower
        end
    end
end

local function godStep(dt)
    if not Config.Active or not Config.GodMovement then
        clearVF()
        workspace.Gravity = defaultGravity
        HudF.Visible = false
        return
    end

    local char = LP.Character
    if not char then clearVF(); return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then clearVF(); return end

    workspace.Gravity = GM.Gravity

    if not jumpConn or not jumpConn.Connected then hookBhop(hum) end

    local sprintOn = UIS:IsKeyDown(Enum.KeyCode.LeftShift)
    hum.WalkSpeed  = GM.WalkSpeed * (sprintOn and GM.SprintMult or 1)
    hum.JumpPower  = GM.JumpPower

    local cam  = workspace.CurrentCamera
    local look = cam.CFrame.LookVector
    local rght = cam.CFrame.RightVector
    local fwd2 = Vector3.new(look.X, 0, look.Z)
    local rgt2 = Vector3.new(rght.X, 0, rght.Z)
    if fwd2.Magnitude > 0 then fwd2 = fwd2.Unit end
    if rgt2.Magnitude > 0 then rgt2 = rgt2.Unit end

    local onGnd = hum.FloorMaterial ~= Enum.Material.Air

    local autoOn = UIS:IsKeyDown(Config.GodMovementKey)
    if autoOn then
        local targetVel = fwd2 * GM.AutoSpeed
        hrp.AssemblyLinearVelocity = Vector3.new(
            targetVel.X,
            hrp.AssemblyLinearVelocity.Y,
            targetVel.Z
        )
        HudF.Visible = true
        local spd = math.floor(Vector3.new(hrp.AssemblyLinearVelocity.X,0,hrp.AssemblyLinearVelocity.Z).Magnitude)
        HudTxt.Text = "AUTO  "..spd.." u/s"
        HudTxt.TextColor3 = Theme.green
        return
    end

    local wd = Vector3.new(0,0,0)
    if UIS:IsKeyDown(Enum.KeyCode.W) then wd = wd + fwd2 end
    if UIS:IsKeyDown(Enum.KeyCode.S) then wd = wd - fwd2 end
    if UIS:IsKeyDown(Enum.KeyCode.A) then wd = wd - rgt2 end
    if UIS:IsKeyDown(Enum.KeyCode.D) then wd = wd + rgt2 end
    if wd.Magnitude > 0 then wd = wd.Unit end

    local vfRef = ensureVF(hrp)

    if not onGnd and wd.Magnitude > 0 then
        local curH   = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        local proj   = curH:Dot(wd)
        local addSpd = GM.AirAccel * dt
        if proj + addSpd > GM.AirCap then
            addSpd = math.max(0, GM.AirCap - proj)
        end
        local mass = hrp.AssemblyMass
        vfRef.Force = wd * (addSpd / dt) * mass
    else
        vfRef.Force = Vector3.new(0,0,0)
    end

    HudF.Visible = true
    local spd = math.floor(Vector3.new(hrp.AssemblyLinearVelocity.X,0,hrp.AssemblyLinearVelocity.Z).Magnitude)
    HudTxt.Text = "spd "..spd.." u/s"
    HudTxt.TextColor3 = spd > 60 and Theme.green or spd > 40 and Theme.gold or Theme.text
end

-- ── METAMETHOD HOOK
local mt = getrawmetatable(game)
local oldIdx = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(self, key)
    if checkcaller() or not Config.Active then return oldIdx(self,key) end
    if key=="Value" and typeof(self)=="Instance" and self:IsA("NumberValue") then
        local n = self.Name
        if Config.NoRecoil and (n=="Recoil" or n=="LRecoil" or n=="RRecoil") then return 0 end
        if Config.NoSpread  and n=="Spread"  then return 0 end
        if Config.InfiniteAmmo and n=="Ammo" then return 999 end
        if Config.RapidFire and n=="FireRate" then return Config.RapidFireDelay end
    end
    return oldIdx(self, key)
end)
setreadonly(mt, true)

-- UI toggle
table.insert(_C, UIS.InputBegan:Connect(function(i,g)
    if not g and i.KeyCode == Config.ToggleKey then Main.Visible = not Main.Visible end
end))

-- Weapon loop
table.insert(_C, RunService.RenderStepped:Connect(function()
    if not Config.Active then return end
    pcall(function()
        local gun = LP.Character and LP.Character:FindFirstChild("Gun")
        if gun and Config.NoRecoil then
            for _,n in pairs({"Recoil","LRecoil","RRecoil"}) do
                local v = gun:FindFirstChild(n); if v then v.Value=0 end
            end
        end
    end)
end))

-- Physics loop
table.insert(_C, RunService.Heartbeat:Connect(function(dt)
    pcall(godStep, dt)
end))
