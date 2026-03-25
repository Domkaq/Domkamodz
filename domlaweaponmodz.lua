-- [[ DOMKAMODZ X WEAPON MODS — FINAL V3 ]]
local Config = {
    NoRecoil = false,
    NoSpread = false,
    InfiniteAmmo = false,
    RapidFire = false,
    RapidFireDelay = 0.01,
    ToggleKey = Enum.KeyCode.RightShift,
    Active = true
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local _Connections = {}

-- [[ TÉMA (DOMKA STYLE) ]]
local Theme = {
    accent = Color3.fromRGB(130, 80, 255),
    bg = Color3.fromRGB(12, 12, 18),
    card = Color3.fromRGB(22, 22, 32),
    text = Color3.fromRGB(225, 225, 240),
    border = Color3.fromRGB(55, 55, 75)
}

local function glass(props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.Color or Theme.bg
    f.BackgroundTransparency = props.Tr or 0.15
    f.BorderSizePixel = 0
    f.Size = props.Size or UDim2.new(0, 200, 0, 200)
    f.Position = props.Pos or UDim2.new(0, 0, 0, 0)
    Instance.new("UICorner", f).CornerRadius = props.Corner or UDim.new(0, 8)
    local s = Instance.new("UIStroke", f)
    s.Color = props.BC or Theme.border
    s.Thickness = 1.2
    f.Parent = props.Parent
    return f
end

-- [[ UI LÉTREHOZÁSA ]]
local ScreenGui = Instance.new("ScreenGui", CoreGui)
local Main = glass({Size = UDim2.new(0, 260, 0, 440), Pos = UDim2.new(0.5, -130, 0.5, -220), Parent = ScreenGui, BC = Theme.accent})

-- [[ JAVÍTOTT HÚZHATÓSÁG (DRAGGABLE) ]]
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
table.insert(_Connections, UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))
table.insert(_Connections, UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end))

local Title = Instance.new("TextLabel", Main)
Title.Text = "DOMKAMODZ — WEAPON"; Title.Font = Enum.Font.GothamBold; Title.TextColor3 = Theme.accent
Title.Size = UDim2.new(1, 0, 0, 45); Title.BackgroundTransparency = 1; Title.TextSize = 13

local Container = Instance.new("ScrollingFrame", Main)
Container.Size = UDim2.new(1, -20, 1, -70); Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1; Container.BorderSizePixel = 0; Container.ScrollBarThickness = 2
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 6)

-- [[ KOMPONENS GYÁRTÓK ]]
local function CreateToggle(name, prop)
    local btn = glass({Color = Theme.card, Size = UDim2.new(1, -5, 0, 38), Parent = Container})
    local t = Instance.new("TextLabel", btn); t.Text = name; t.Font = Enum.Font.GothamMedium; t.TextColor3 = Theme.text; t.Size = UDim2.new(1,-50,1,0); t.Position = UDim2.new(0,10,0,0); t.TextXAlignment = 0; t.BackgroundTransparency = 1
    local status = glass({Color = Config[prop] and Theme.accent or Color3.fromRGB(60,60,70), Size = UDim2.new(0, 24, 0, 12), Pos = UDim2.new(1,-34,0.5,-6), Parent = btn})
    local trigger = Instance.new("TextButton", btn); trigger.Size = UDim2.new(1,0,1,0); trigger.BackgroundTransparency = 1; trigger.Text = ""
    trigger.MouseButton1Click:Connect(function()
        Config[prop] = not Config[prop]
        TweenService:Create(status, TweenInfo.new(0.25), {BackgroundColor3 = Config[prop] and Theme.accent or Color3.fromRGB(60,60,70)}):Play()
    end)
end

local function CreateSlider(name, min, max, dec, callback)
    local sFrame = glass({Color = Theme.card, Size = UDim2.new(1, -5, 0, 50), Parent = Container})
    local txt = Instance.new("TextLabel", sFrame); txt.Text = name .. ": " .. string.format("%.2f", Config.RapidFireDelay)
    txt.Font = Enum.Font.GothamMedium; txt.TextColor3 = Theme.text; txt.Size = UDim2.new(1,-20,0,25); txt.Position = UDim2.new(0,10,0,5); txt.TextXAlignment = 0; txt.BackgroundTransparency = 1
    local bar = glass({Color = Color3.fromRGB(40,40,50), Size = UDim2.new(1,-20,0,4), Pos = UDim2.new(0,10,0,36), Parent = sFrame})
    local fill = glass({Color = Theme.accent, Size = UDim2.new((Config.RapidFireDelay-min)/(max-min), 0, 1, 0), Parent = bar})
    
    local sDragging = false
    local function update()
        local pct = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor((min + (max-min) * pct) / dec + 0.5) * dec
        fill.Size = UDim2.new(pct, 0, 1, 0); txt.Text = name .. ": " .. string.format("%.2f", val)
        callback(val)
    end
    sFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sDragging = true end end)
    table.insert(_Connections, UIS.InputChanged:Connect(function(i) if sDragging and i.UserInputType == Enum.UserInputType.MouseMovement then update() end end))
    table.insert(_Connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sDragging = false end end))
end

-- UI Feltöltése
CreateToggle("No Recoil", "NoRecoil")
CreateToggle("No Spread", "NoSpread")
CreateToggle("Infinite Ammo", "InfiniteAmmo")
CreateToggle("Rapid Fire", "RapidFire")
CreateSlider("Fire Delay", 0.01, 1.0, 0.01, function(v) Config.RapidFireDelay = v end)

-- [[ DESTROY LOGIKA ]]
local dBtn = glass({Color = Color3.fromRGB(180, 50, 50), Size = UDim2.new(1, -5, 0, 35), Parent = Container, BC = Color3.new(1,0,0)})
local dTxt = Instance.new("TextLabel", dBtn); dTxt.Text = "DESTROY SCRIPT"; dTxt.Font = Enum.Font.GothamBold; dTxt.TextColor3 = Color3.new(1,1,1); dTxt.Size = UDim2.new(1,0,1,0); dTxt.BackgroundTransparency = 1
local dTrig = Instance.new("TextButton", dBtn); dTrig.Size = UDim2.new(1,0,1,0); dTrig.BackgroundTransparency = 1; dTrig.Text = ""

dTrig.MouseButton1Click:Connect(function()
    Config.Active = false
    Config.NoRecoil = false
    Config.NoSpread = false
    Config.InfiniteAmmo = false
    Config.RapidFire = false
    for _, c in pairs(_Connections) do c:Disconnect() end
    ScreenGui:Destroy()
end)

-- [[ METAMETHOD HOOK (BIZTONSÁGOS) ]]
local mt = getrawmetatable(game)
local oldIdx = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(self, key)
    if checkcaller() or not Config.Active then return oldIdx(self, key) end
    if key == "Value" and typeof(self) == "Instance" and self:IsA("NumberValue") then
        local n = self.Name
        if Config.NoRecoil and (n == "Recoil" or n == "LRecoil" or n == "RRecoil") then return 0 end
        if Config.NoSpread and n == "Spread" then return 0 end
        if Config.InfiniteAmmo and n == "Ammo" then return 999 end
        if Config.RapidFire and n == "FireRate" then return Config.RapidFireDelay end
    end
    return oldIdx(self, key)
end)
setreadonly(mt, true)

-- Keybind
table.insert(_Connections, UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Config.ToggleKey then Main.Visible = not Main.Visible end
end))

-- Render Loop (Backup)
table.insert(_Connections, RunService.RenderStepped:Connect(function()
    if not Config.Active then return end
    pcall(function()
        local gun = LP.Character and LP.Character:FindFirstChild("Gun")
        if gun then
            if Config.NoRecoil then
                if gun:FindFirstChild("Recoil") then gun.Recoil.Value = 0 end
            end
        end
    end)
end))
