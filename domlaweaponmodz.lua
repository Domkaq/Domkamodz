-- [[ DOMKAMODZ X WEAPON MODS — TOTAL CLEANUP VERSION ]]
local Config = {
    NoRecoil = false,
    NoSpread = false,
    InfiniteAmmo = false,
    RapidFire = false,
    RapidFireDelay = 0.01,
    -- UI & System
    ToggleKey = Enum.KeyCode.RightShift,
    Active = true -- Ez az extra kapcsoló a teljes leállításhoz
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local _Connections = {} -- Ide gyűjtünk minden futó kapcsolatot

-- [[ DOMKA UI TÉMA & GLASS ]]
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
    s.Transparency = 0.4
    f.Parent = props.Parent
    return f
end

-- [[ UI LÉTREHOZÁSA ]]
local ScreenGui = Instance.new("ScreenGui", CoreGui)
local Main = glass({Size = UDim2.new(0, 260, 0, 400), Pos = UDim2.new(0.5, -130, 0.5, -200), Parent = ScreenGui, BC = Theme.accent})

local Container = Instance.new("ScrollingFrame", Main)
Container.Size = UDim2.new(1, -20, 1, -60); Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1; Container.BorderSizePixel = 0; Container.ScrollBarThickness = 2
Instance.new("UIListLayout", Container).Padding = UDim.new(0, 6)

-- [[ KOMPONENS GYÁRTÓK ]]
local function CreateToggle(name, prop)
    local btn = glass({Color = Theme.card, Size = UDim2.new(1, -5, 0, 38), Parent = Container})
    local t = Instance.new("TextLabel", btn)
    t.Text = name; t.Font = Enum.Font.GothamMedium; t.TextColor3 = Theme.text; t.Size = UDim2.new(1,-50,1,0); t.Position = UDim2.new(0,10,0,0); t.TextXAlignment = 0; t.BackgroundTransparency = 1
    local status = glass({Color = Config[prop] and Theme.accent or Color3.fromRGB(60,60,70), Size = UDim2.new(0, 24, 0, 12), Pos = UDim2.new(1,-34,0.5,-6), Parent = btn})
    local trigger = Instance.new("TextButton", btn); trigger.Size = UDim2.new(1,0,1,0); trigger.BackgroundTransparency = 1; trigger.Text = ""
    trigger.MouseButton1Click:Connect(function()
        Config[prop] = not Config[prop]
        TweenService:Create(status, TweenInfo.new(0.25), {BackgroundColor3 = Config[prop] and Theme.accent or Color3.fromRGB(60,60,70)}):Play()
    end)
end

local function CreateSlider(name, min, max, dec, callback)
    local sFrame = glass({Color = Theme.card, Size = UDim2.new(1, -5, 0, 50), Parent = Container})
    local txt = Instance.new("TextLabel", sFrame); txt.Text = name .. ": " .. Config.RapidFireDelay
    txt.Font = Enum.Font.GothamMedium; txt.TextColor3 = Theme.text; txt.Size = UDim2.new(1,-20,0,25); txt.Position = UDim2.new(0,10,0,5); txt.TextXAlignment = 0; txt.BackgroundTransparency = 1
    local bar = glass({Color = Color3.fromRGB(40,40,50), Size = UDim2.new(1,-20,0,4), Pos = UDim2.new(0,10,0,36), Parent = sFrame})
    local fill = glass({Color = Theme.accent, Size = UDim2.new((Config.RapidFireDelay-min)/(max-min), 0, 1, 0), Parent = bar})
    local dragging = false
    sFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    table.insert(_Connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))
    table.insert(_Connections, UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local pct = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor((min + (max-min) * pct) / dec + 0.5) * dec
            fill.Size = UDim2.new(pct, 0, 1, 0); txt.Text = name .. ": " .. string.format("%.2f", val)
            callback(val)
        end
    end))
end

-- Feltöltés
CreateToggle("No Recoil", "NoRecoil")
CreateToggle("No Spread", "NoSpread")
CreateToggle("Infinite Ammo", "InfiniteAmmo")
CreateToggle("Rapid Fire", "RapidFire")
CreateSlider("Fire Delay", 0.01, 1, 0.01, function(v) Config.RapidFireDelay = v end)

-- [[ A TÖKÉLETES TÖRLÉS (CLEANUP) ]]
local function Cleanup()
    Config.Active = false -- Leállítja a Metamethod logikát
    Config.NoRecoil = false; Config.NoSpread = false; Config.InfiniteAmmo = false; Config.RapidFire = false -- Visszaállítja az értékeket
    
    for _, conn in pairs(_Connections) do
        if conn then conn:Disconnect() end -- Minden loop és event leállítása
    end
    
    ScreenGui:Destroy() -- UI törlése
    print("DomkaModz: Script Successfully Destroyed & Cleaned Up")
end

local dBtn = glass({Color = Color3.fromRGB(150, 50, 50), Size = UDim2.new(1, -5, 0, 35), Parent = Container, BC = Color3.new(1,0,0)})
local dTxt = Instance.new("TextLabel", dBtn); dTxt.Text = "DESTROY SCRIPT"; dTxt.Font = Enum.Font.GothamBold; dTxt.TextColor3 = Color3.new(1,1,1); dTxt.Size = UDim2.new(1,0,1,0); dTxt.BackgroundTransparency = 1
local dTrig = Instance.new("TextButton", dBtn); dTrig.Size = UDim2.new(1,0,1,0); dTrig.BackgroundTransparency = 1; dTrig.Text = ""
dTrig.MouseButton1Click:Connect(Cleanup)

-- [[ HOOKS ]]
local mt = getrawmetatable(game)
local oldIdx = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(self, key)
    -- Ha a script leállt (Active = false), az eredeti értéket adja vissza azonnal
    if not checkcaller() and Config.Active and key == "Value" and typeof(self) == "Instance" and self:IsA("NumberValue") then
        if Config.NoRecoil and (self.Name == "Recoil" or self.Name == "LRecoil" or self.Name == "RRecoil") then return 0 end
        if Config.NoSpread and self.Name == "Spread" then return 0 end
        if Config.InfiniteAmmo and self.Name == "Ammo" then return 999 end
        if Config.RapidFire and self.Name == "FireRate" then return Config.RapidFireDelay end
    end
    return oldIdx(self, key)
end)
setreadonly(mt, true)

-- Bind & Loops mentése a listába a törléshez
table.insert(_Connections, UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Config.ToggleKey then Main.Visible = not Main.Visible end
end))

table.insert(_Connections, RunService.RenderStepped:Connect(function()
    if not Config.Active then return end
    pcall(function()
        local gun = LP.Character and LP.Character:FindFirstChild("Gun")
        if gun then
            if Config.NoRecoil then gun.Recoil.Value = 0 end
            if Config.InfiniteAmmo then gun.Ammo.Value = 999 end
        end
    end)
end))
