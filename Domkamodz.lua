--[[
    DomkaModz v5.1 — Wave Executor
    Game arg layouts (SimpleSpy dump):
    HIT_REGISTER.Bullet:FireServer(
      [1] HitPart  [2] HitPos(V3)  [3] Dir(V3)  [4] WeaponName(str)
      [5] Damage   [6] 0           [7] BulletSpeed
      [8] nil (GAP)
      [9] Gun(Instance)  [10] Origin(V3)  [11] DistributedTime  [12] 1
    )
    Events.CreateTrail:FireServer(
      [1] Origin(V3) [2] EndPos(V3) [3] col1 [4] col2 [5] IgnoreTable [6] col3
    )
    CC:FireServer("ClassName")   — string, NOT number
    SpawnPlayer:FireServer({"none"})
    Server: Checks Picked, TeamC, BulletSize floors, math.max(floor,dmg)
]]

------------------------------------------------------------------------
-- 1. SERVICES & UPVALUES
------------------------------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local RS                = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local mFloor  = math.floor
local mClamp  = math.clamp
local mMax    = math.max
local mAbs    = math.abs
local mRand   = math.random
local mHuge   = math.huge
local mAtan2  = math.atan2
local mSin    = math.sin
local mCos    = math.cos
local tInsert = table.insert
local V2      = Vector2.new
local V3      = Vector3.new
local CFa     = CFrame.Angles

------------------------------------------------------------------------
-- 2. CONFIG
------------------------------------------------------------------------
local Config = {
    -- Aimbot
    AimbotEnabled   = false,
    AimbotMode      = "Legit",
    AimbotBone      = "Head",
    AimbotSmooth    = 6,
    AimbotFOV       = 120,
    AimbotKey       = Enum.UserInputType.MouseButton2,
    -- Silent
    SilentForceHead = true,
    HitChance       = 0.55,
    KillCooldown    = 2.0,
    DamageSync      = false,
    -- BulletTP
    BulletTPEnabled = false,
    BulletTPMult    = 50,
    BulletTPMode    = "Speed",
    -- Triggerbot
    TriggerEnabled  = false,
    TriggerDelay    = 0.05,
    TriggerKey      = Enum.KeyCode.T,
    -- RCS
    RCSEnabled      = false,
    RCSStrength     = 0.7,
    -- Backtrack
    BacktrackOn     = false,
    BacktrackTicks  = 6,
    -- Weapon
    NoRecoil        = false,
    NoSpread        = false,
    InfiniteAmmo    = false,
    RapidFire       = false,
    RapidFireDelay  = 0.01,
    -- Hitbox & Auto-Wall
    HitboxEnabled   = false,
    HitboxSize      = 3,
    AutoWallEnabled = false,
    -- Smart Aim
    SmartAimEnabled = false,
    HeadJitter      = 0.15,
    StickyAim       = true,
    -- ESP
    ESPEnabled      = false,
    BoxESP          = true,
    SkeletonESP     = false,
    HealthBar       = true,
    DistESP         = true,
    NameESP         = true,
    WeaponESP       = false,
    AmmoESP         = false,
    GlowESP        = false,
    TeamCheck       = true,
    -- World ESP
    WorldESPOn      = false,
    DroppedWeapons  = false,
    GrenadesESP     = false,
    -- Movement
    SpeedHack       = false,
    SpeedMult       = 1.5,
    -- Camera
    ThirdPerson     = false,
    ThirdPersonDist = 8,
    ThirdPersonSmooth = 0.15,
    -- Misc
    AntiAFK         = true,
    AntiKick        = true,
    ShowWatermark   = true,
    -- Prediction
    PredictionOn    = false,
    -- Radar
    RadarEnabled    = false,
    RadarSize       = 120,
    RadarRange      = 200,
    -- Anti-Aim
    AntiAimOn       = false,
    -- Crosshair
    CrosshairOn     = false,
    CrosshairSize   = 6,
    CrosshairGap    = 3,
    -- FOV
    FOVChangerOn    = false,
    CustomFOV       = 90,
    -- Visual
    Fullbright      = false,
    -- Survival
    AutoRespawn     = false,
    -- Flight
    NoclipEnabled   = false,
    FlyEnabled      = false,
    FlySpeed        = 50,
    NoclipKey       = Enum.KeyCode.N,
    FlyKey          = Enum.KeyCode.G,
    -- Sound
    KillSound       = true,
    -- Theme
    AccR = 130, AccG = 80, AccB = 255,
    BGAlpha = 0.15,
    ToggleKey = Enum.KeyCode.RightShift,
}

------------------------------------------------------------------------
-- 2b. CONFIG SAVE/LOAD
------------------------------------------------------------------------
local CONFIG_FILE = "DomkaModz_config.json"
local function saveConfig() pcall(function()
    if not writefile then return end
    local HS = game:GetService("HttpService"); local sd = {}
    for k,v in pairs(Config) do
        if type(v) ~= "function" and type(v) ~= "userdata" then
            if typeof(v) == "EnumItem" then sd[k] = {_enum=true,type=tostring(v.EnumType),name=v.Name}
            else sd[k] = v end
        end
    end
    writefile(CONFIG_FILE, HS:JSONEncode(sd))
end) end

local function loadConfig() pcall(function()
    if not readfile or not isfile then return end
    if not isfile(CONFIG_FILE) then return end
    local HS = game:GetService("HttpService")
    local ok, d = pcall(HS.JSONDecode, HS, readfile(CONFIG_FILE))
    if not ok or type(d) ~= "table" then return end
    for k,v in pairs(d) do
        if Config[k] ~= nil then
            if type(v) == "table" and v._enum then pcall(function() Config[k] = Enum[v.type][v.name] end)
            elseif type(v) == type(Config[k]) then Config[k] = v end
        end
    end
end) end
loadConfig()

------------------------------------------------------------------------
-- 3. THEME
------------------------------------------------------------------------
local Theme = {}
local _accentCache, _accentCacheTk = nil, 0
function Theme.accent()
    local n = tick()
    if n - _accentCacheTk > 0.03 then
        _accentCache = Color3.fromRGB(Config.AccR,Config.AccG,Config.AccB)
        _accentCacheTk = n
    end
    return _accentCache
end
function Theme.accentDim() return Color3.fromRGB(mFloor(Config.AccR*.6),mFloor(Config.AccG*.6),mFloor(Config.AccB*.6)) end
function Theme.bg()        return Color3.fromRGB(12,12,18) end
function Theme.card()      return Color3.fromRGB(22,22,32) end
function Theme.glass()     return Color3.fromRGB(30,30,44) end
function Theme.text()      return Color3.fromRGB(225,225,240) end
function Theme.dim()       return Color3.fromRGB(100,100,120) end
function Theme.border()    return Color3.fromRGB(55,55,75) end
function Theme.success()   return Color3.fromRGB(80,255,120) end
function Theme.danger()    return Color3.fromRGB(255,70,70) end
function Theme.warning()   return Color3.fromRGB(255,200,60) end

------------------------------------------------------------------------
-- 4. REMOTE CACHE
------------------------------------------------------------------------
local Rem = {}
local function getNil(name,class)
    for _,v in next,getnilinstances() do
        if v.ClassName==class and v.Name==name then return v end
    end
end

local function cacheRemotes()
    pcall(function()
        local ev = RS:WaitForChild("Events",5)
        if ev then
            Rem.RemoteEvent  = ev:FindFirstChild("RemoteEvent")
            Rem.AdobeAmmo    = ev:FindFirstChild("AdobeAutoAmmo")
            Rem.CreateTrail  = ev:FindFirstChild("CreateTrail")
            Rem.CC           = ev:FindFirstChild("CC")
            Rem.Vote         = ev:FindFirstChild("Vote")
            Rem.Comms        = ev:FindFirstChild("Comms")
        end
        local hr = Workspace:FindFirstChild("HIT_REGISTER")
        if hr then
            Rem.Bullet      = hr:FindFirstChild("Bullet")
            Rem.Fire        = hr:FindFirstChild("Fire")
            Rem.CreateBlood = hr:FindFirstChild("CreateBlood")
        end
        Rem.RefillAmmo      = Workspace:FindFirstChild("RefillAmmo")
        Rem.UpdateEmpty     = Workspace:FindFirstChild("UpdateEmpty")
        Rem.UpdateBBG       = Workspace:FindFirstChild("UpdateBBG")
        Rem.DistributedTime = Workspace:FindFirstChild("DistributedTime")
        pcall(function()
            local bp = LP:FindFirstChild("Backpack")
            if bp then Rem.SpawnPlayer = bp:FindFirstChild("SpawnPlayer") end
        end)
        if not Rem.SpawnPlayer then
            Rem.SpawnPlayer = getNil("SpawnPlayer","RemoteEvent")
        end
    end)
end
cacheRemotes()

------------------------------------------------------------------------
-- 5. PLAYER CACHE & IGNORE LIST
------------------------------------------------------------------------
local _players    = {}
local _playersTk  = 0

local function getPlayers()
    local now = tick()
    if now - _playersTk > 0.1 then
        _players   = Players:GetPlayers()
        _playersTk = now
    end
    return _players
end
getPlayers()

local _ignoreList = {}
local _ignoreTk   = 0

local function buildIgnore()
    local now = tick()
    if now - _ignoreTk > 0.25 then
        local l = {}
        local c = LP.Character
        if c then tInsert(l,c) end
        pcall(function()
            local d = Workspace:FindFirstChild("Debris")
            if d then tInsert(l,d) end
            local r = Workspace:FindFirstChild("Ray_Ignore")
            if r then tInsert(l,r) end
            local ca = Workspace:FindFirstChild("Camera")
            if ca then tInsert(l,ca) end
            local m = Workspace:FindFirstChild("Map")
            if m then
                local s = m:FindFirstChild("Spawns")
                if s then tInsert(l,s) end
                local ig = m:FindFirstChild("Ignore")
                if ig then tInsert(l,ig) end
            end
        end)
        _ignoreList = l
        _ignoreTk   = now
    end
    return _ignoreList
end

------------------------------------------------------------------------
-- 5b. FORWARD: GameInt (must be before captureWeapon/restoreWeapon)
------------------------------------------------------------------------
local GameInt = {}

------------------------------------------------------------------------
-- 6. WEAPON VALUE STORAGE
------------------------------------------------------------------------
local OrigVals   = {}
local LastGun    = nil
local CachedGun  = nil
local _anyWpnFeat = false
local _hookGuard = false
local _hookGuardTk = 0

local GUN_VALS = {"Recoil","LRecoil","RRecoil","Spread","FireRate","Damage","BulletSpeed","BulletDrop","Penetration"}
local MULT_NAMES = {
    Head="HMultiplier",UpperTorso="TMultiplier",LowerTorso="TMultiplier",HumanoidRootPart="TMultiplier",
    LeftUpperArm="LAMultiplier",LeftLowerArm="LAMultiplier",LeftHand="LAMultiplier",
    RightUpperArm="RAMultiplier",RightLowerArm="RAMultiplier",RightHand="RAMultiplier",
    LeftUpperLeg="LLMultiplier",LeftLowerLeg="LLMultiplier",LeftFoot="LLMultiplier",
    RightUpperLeg="RLMultiplier",RightLowerLeg="RLMultiplier",RightFoot="RLMultiplier",
}

local function captureWeapon(gun)
    if gun == LastGun and OrigVals.ok then return end
    LastGun  = gun
    OrigVals = {ok=true}
    -- Temporarily disable hooks so we read TRUE stored values, not our overridden ones
    _hookGuard=true; _hookGuardTk=tick()
    pcall(function()
        for _,n in ipairs(GUN_VALS) do
            local v = gun:FindFirstChild(n)
            if v then
                local val = v.Value
                if typeof(val)=="string" then val = tonumber(val) end
                if typeof(val)=="number" then OrigVals[n] = val end
            end
        end
        local mf = gun:FindFirstChild("Multipliers")
        if mf then OrigVals.Multipliers = {}
            for _,mv in ipairs(mf:GetChildren()) do
                if mv:IsA("NumberValue") then OrigVals.Multipliers[mv.Name] = mv.Value end
            end
        end
        local bs = gun:FindFirstChild("BulletSize"); if bs then OrigVals.BulletSize = bs.Value end
    end)
    _hookGuard=false
    -- Snapshot GC table originals if available
    pcall(function()
        if GameInt.WeaponModule then
            local wm = GameInt.WeaponModule
            for _,n in ipairs(GUN_VALS) do
                if not OrigVals[n] and type(rawget(wm,n))=="number" then OrigVals[n]=rawget(wm,n) end
            end
        end
    end)
end

local MULT_FALLBACK = {Head=3,UpperTorso=1,LowerTorso=1,HumanoidRootPart=1,LeftUpperArm=.8,LeftLowerArm=.8,LeftHand=.8,RightUpperArm=.8,RightLowerArm=.8,RightHand=.8,LeftUpperLeg=.5,LeftLowerLeg=.5,LeftFoot=.5,RightUpperLeg=.5,RightLowerLeg=.5,RightFoot=.5}
local function getServerMultiplier(boneName)
    if OrigVals.Multipliers then
        local mn = MULT_NAMES[boneName]
        if mn and OrigVals.Multipliers[mn] then return OrigVals.Multipliers[mn] end
    end
    return MULT_FALLBACK[boneName] or 1
end

local function restoreWeapon(gun)
    if not OrigVals.ok then return end
    for _,n in ipairs(GUN_VALS) do
        local v = gun:FindFirstChild(n)
        if v and OrigVals[n] then
            pcall(function() v.Value = OrigVals[n] end)
        end
    end
end

------------------------------------------------------------------------
-- 7. FORWARD DECLARATIONS & STATE
------------------------------------------------------------------------
local getClosestTarget, getBone, findGun
local BacktrackHistory = {}
local _prevVelocity    = {}
local _lastRedirect    = 0
local _lastKill        = 0
local _killCD          = false
local _stickyTarget    = nil

local _killCount = 0
local _killSnd
local function onEnemyDied()
    _lastKill=tick(); _killCD=true; _killCount=_killCount+1
    if Config.KillSound then
        pcall(function()
            if not _killSnd or not _killSnd.Parent then
                _killSnd = Instance.new("Sound")
                _killSnd.SoundId = "rbxassetid://6647898215"
                _killSnd.Volume = 0.8
                _killSnd.Parent = game:GetService("SoundService")
            end
            _killSnd:Play()
        end)
    end
end
local function killCDReady()
    if not _killCD then return true end
    if tick()-_lastKill >= Config.KillCooldown then _killCD=false; return true end
    return false
end

local _silentRoll   = false
local _silentRollTk = 0
local function getSilentRoll()
    local now = tick()
    if now-_silentRollTk > 0.015 then
        _silentRollTk = now
        _silentRoll = killCDReady() and mRand()<Config.HitChance
    end
    return _silentRoll
end

------------------------------------------------------------------------
-- 8. BASE UTILITIES
------------------------------------------------------------------------
local function isWeaponEquipped()
    local c = LP.Character
    return c and c:FindFirstChild("Picked") ~= nil
end

local function isAlive(p)
    local c = p.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health<=0 then return false end
    return c:FindFirstChild("HumanoidRootPart") ~= nil
end

local function isEnemy(p)
    if p==LP then return false end
    if not Config.TeamCheck then return true end
    local mt = LP:FindFirstChild("TeamC")
    local tt = p:FindFirstChild("TeamC")
    if mt and tt then
        if mt.Value=="Spectator" then return false end
        return mt.Value ~= tt.Value and tt.Value ~= "Spectator"
    end
    return true
end

local BONE_MAP = {Head="Head",UpperTorso="UpperTorso",HumanoidRootPart="HumanoidRootPart"}

getBone = function(p)
    local c = p.Character
    if not c then return nil end
    local b = c:FindFirstChild(BONE_MAP[Config.AimbotBone] or "Head")
    if b and b:IsA("BasePart") then return b end
    local h = c:FindFirstChild("HumanoidRootPart")
    if h and h:IsA("BasePart") then return h end
    return nil
end

local function w2s(pos)
    local v,on = Camera:WorldToScreenPoint(pos)
    return V2(v.X,v.Y),on
end

-- Smart Head Offset for better head targeting
local _headOffsetTk,_headOffset = 0,V3(0,0,0)
local function getSmartHeadOffset()
    local n = tick()
    if n-_headOffsetTk > Config.HeadJitter then
        _headOffsetTk = n
        local r = mRand()
        if r<0.35 then _headOffset = V3(0,0.15,0)
        elseif r<0.55 then _headOffset = V3(0,-0.05,0)
        elseif r<0.7 then _headOffset = V3(0.12,0.05,0)
        elseif r<0.85 then _headOffset = V3(-0.12,0.05,0)
        else _headOffset = V3((mRand()-0.5)*0.18,(mRand()-0.5)*0.15,0) end
    end
    return _headOffset
end

------------------------------------------------------------------------
-- 9. TARGET INTELLIGENCE
------------------------------------------------------------------------
local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude

local _visCache = {}
local _visTk    = 0

local _visIL = {}
local function isVisible(tPos,exChar)
    local base = buildIgnore()
    local n = #base
    for i=1,n do _visIL[i]=base[i] end
    if exChar then n=n+1; _visIL[n]=exChar end
    for i=n+1,#_visIL do _visIL[i]=nil end
    visParams.FilterDescendantsInstances = _visIL
    local o = Camera.CFrame.Position
    local d = tPos - o
    local m = d.Magnitude
    if m<0.5 then return true end
    local ok,r = pcall(Workspace.Raycast,Workspace,o,d.Unit*(m-0.5),visParams)
    if not ok then return true end
    return r==nil
end

local function getCachedVis(plr,bPos)
    local now = tick()
    if now-_visTk > 0.15 then _visCache={}; _visTk=now end
    if _visCache[plr]~=nil then return _visCache[plr] end
    local v = isVisible(bPos,plr.Character)
    if not v and Config.AutoWallEnabled then
        local pen = OrigVals.Penetration or 0
        if pen > 0 then
            local il = table.clone(buildIgnore())
            if plr.Character then tInsert(il,plr.Character) end
            visParams.FilterDescendantsInstances = il
            local o = Camera.CFrame.Position
            local d = bPos - o
            local m = d.Magnitude
            if m >= 0.5 then
                local ok,r = pcall(Workspace.Raycast,Workspace,o,d.Unit*(m-0.5),visParams)
                if ok and r and (bPos-r.Position).Magnitude <= pen*2 then v = true end
            end
        end
    end
    _visCache[plr]=v
    return v
end

local function getThreat(p)
    local mc = LP.Character
    if not mc then return 0 end
    local mh = mc:FindFirstChild("HumanoidRootPart")
    if not mh then return 0 end
    local tc = p.Character
    if not tc then return 0 end
    local th = tc:FindFirstChild("HumanoidRootPart")
    if not th then return 0 end
    local toMe = (mh.Position-th.Position).Unit
    local look = th.CFrame.LookVector
    return mClamp((look:Dot(toMe)+1)/2,0,1)
end

local function isADS(p)
    local c = p.Character
    if not c then return false end
    return c:FindFirstChild("Gun")~=nil and (c:FindFirstChild("Picked")~=nil)
end

------------------------------------------------------------------------
-- 10. CLOSEST TARGET + BACKTRACK
------------------------------------------------------------------------
local _frameTarget   = nil
local _frameTargetTk = 0

getClosestTarget = function()
    local vp = Camera.ViewportSize
    local center = V2(vp.X*.5,vp.Y*.5)
    local mc = LP.Character
    local mh = mc and mc:FindFirstChild("HumanoidRootPart")
    local mp = mh and mh.Position or Camera.CFrame.Position
    local fov = Config.AimbotFOV
    local best,bestS = nil,-mHuge
    local pl = getPlayers()
    for i=1,#pl do
        local p = pl[i]
        if p~=LP and isAlive(p) and isEnemy(p) then
            local bone = getBone(p)
            if bone then
                local bp = bone.Position
                local sp,on = w2s(bp)
                if on then
                    local sd = (sp-center).Magnitude
                    local hbPx = Config.HitboxEnabled and mClamp(Config.HitboxSize * 8, 0, 40) or 0
                    if sd<=(fov + hbPx) then
                        local effectiveFov = fov + hbPx
                        local s = mMax((1-sd/effectiveFov)*30, 0)
                        s = s + (1-mClamp((bp-mp).Magnitude/500,0,1))*20
                        if getCachedVis(p,bp) then s=s+40 end
                        s = s + getThreat(p)*20
                        if isADS(p) then s=s+10 end
                        local c2 = p.Character
                        if c2 then
                            local hum = c2:FindFirstChildOfClass("Humanoid")
                            if hum then s=s+(1-mClamp(hum.Health/hum.MaxHealth,0,1))*10 end
                            if c2:FindFirstChild("Gun") then s=s+5 end
                        end
                        -- Sticky aim bonus
                        if Config.StickyAim and p == _stickyTarget then
                            s = s + 25
                        end
                        if s>bestS then bestS=s; best=p end
                    end
                end
            end
        end
    end
    return best
end

local function getFrameTarget()
    local now = tick()
    if now-_frameTargetTk > 0.016 then
        _frameTarget   = getClosestTarget()
        _frameTargetTk = now
        if _frameTarget then _stickyTarget = _frameTarget end
    end
    return _frameTarget
end

local function validateTarget(t)
    if not t then return nil end
    if not isAlive(t) then _stickyTarget = nil; return nil end
    local b = getBone(t)
    if not b then return nil end
    if not getCachedVis(t,b.Position) then return nil end
    return t
end

local function resolveBone(t)
    if not t then return nil end
    local c = t.Character
    if not c then return nil end
    if Config.SilentForceHead then
        if mRand()<0.45 then
            local h = c:FindFirstChild("Head")
            if h and h:IsA("BasePart") then return h end
        else
            local u = c:FindFirstChild("UpperTorso")
            if u and u:IsA("BasePart") then return u end
        end
    end
    return getBone(t)
end

local function recordBacktrack()
    if not Config.BacktrackOn then return end
    local mx = Config.BacktrackTicks
    local pl = getPlayers()
    for i=1,#pl do
        local p = pl[i]
        if p~=LP and isAlive(p) and isEnemy(p) then
            local bone = getBone(p)
            if bone then
                local h = BacktrackHistory[p]
                if not h then h={}; BacktrackHistory[p]=h end
                tInsert(h,{pos=bone.Position,t=tick()})
                local ex = #h - mx
                if ex>0 then
                    table.move(h,ex+1,#h,1)
                    for j=#h,#h-ex+1,-1 do h[j]=nil end
                end
            end
        end
    end
end

local function getTargetAcceleration(tp)
    local tc = tp and tp.Character; if not tc then return V3(0,0,0) end
    local thrp = tc:FindFirstChild("HumanoidRootPart"); if not thrp then return V3(0,0,0) end
    local ok,vel = pcall(function() return thrp.AssemblyLinearVelocity end)
    if not ok or typeof(vel)~="Vector3" then return V3(0,0,0) end
    local prev = _prevVelocity[tp]; _prevVelocity[tp] = {vel=vel,t=tick()}
    if prev then local dt = tick()-prev.t; if dt>0.001 and dt<0.5 then return (vel-prev.vel)*(1/dt) end end
    return V3(0,0,0)
end

local function predictPos(bone, targetPlr)
    if not Config.PredictionOn or not bone then return bone and bone.Position end
    local tc = targetPlr and targetPlr.Character
    if not tc then return bone.Position end
    local thrp = tc:FindFirstChild("HumanoidRootPart")
    if not thrp then return bone.Position end
    local ok, vel = pcall(function() return thrp.AssemblyLinearVelocity end)
    if not ok or typeof(vel)~="Vector3" or vel.Magnitude<0.5 then return bone.Position end
    local mc = LP.Character
    local mh = mc and mc:FindFirstChild("HumanoidRootPart")
    local origin = mh and mh.Position or Camera.CFrame.Position
    local dist = (bone.Position - origin).Magnitude
    local bs = OrigVals.BulletSpeed or 2000
    local tt = mClamp(dist / mMax(bs, 1), 0, 0.5)
    local accel = getTargetAcceleration(targetPlr)
    return bone.Position + vel * tt + accel * 0.5 * tt * tt
end

local function getAimPos(p)
    local bone = getBone(p)
    if not bone then return nil end
    local best = predictPos(bone, p)
    if Config.SmartAimEnabled and bone.Name=="Head" then
        best = best + getSmartHeadOffset()
    end
    if Config.BacktrackOn and BacktrackHistory[p] then
        local c = V2(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        local bd = mHuge
        local sp2,v2 = w2s(best)
        if v2 then bd=(sp2-c).Magnitude end
        for _,r in ipairs(BacktrackHistory[p]) do
            local rs,rv = w2s(r.pos)
            if rv then
                local d2 = (rs-c).Magnitude
                if d2<bd then bd=d2; best=r.pos end
            end
        end
    end
    return best
end

------------------------------------------------------------------------
-- 10b. RAW METATABLE CAPTURE (MUST happen before any hookmetamethod)
-- hookmetamethod internally modifies the metatable — if we capture
-- AFTER it runs, getrawmetatable may return a corrupted reference.
-- The standalone script works because it never calls hookmetamethod.
------------------------------------------------------------------------
local _hookMT = getrawmetatable(game)
local oldIndex = _hookMT.__index
local oldNewIndex = _hookMT.__newindex

------------------------------------------------------------------------
-- 11. NAMECALL HOOK
------------------------------------------------------------------------
local SANITIZE_IDX = {5,6,7,11,12}
local oldNamecall
oldNamecall = hookmetamethod(game,"__namecall",newcclosure(function(self,...)
    local method = getnamecallmethod()

    if Config.AntiKick and method=="Kick" then return end
    if checkcaller() then return oldNamecall(self,...) end

    local silentOn = Config.AimbotEnabled and Config.AimbotMode=="Silent"
    local btpOn    = Config.BulletTPEnabled

    if method=="FireServer" then
        -- LAYER 1: HIT_REGISTER.Bullet — all logic in pcall for crash safety
        if self==Rem.Bullet and (silentOn or btpOn or Config.NoSpread or Config.NoRecoil or Config.InfiniteAmmo or Config.DamageSync) then
            local args = {...}
            local n    = select("#",...)
            pcall(function()
                -- Pre-sanitize ALL numeric args FIRST (before any early return)
                for _,si in ipairs(SANITIZE_IDX) do
                    if typeof(args[si])=="string" then
                        local nn = tonumber(args[si])
                        if nn then args[si]=nn end
                    end
                end
                if not isWeaponEquipped() then return end
                local target = nil
                local didRedirect = false
                if btpOn then
                    target = validateTarget(getFrameTarget())
                elseif silentOn and getSilentRoll()
                   and (tick()-_lastRedirect)>=0.08 then
                    target = validateTarget(getFrameTarget())
                end
                if target then
                    local bone = resolveBone(target)
                    if bone and bone:IsA("BasePart")
                       and typeof(args[2])=="Vector3"
                       and typeof(args[3])=="Vector3" then
                        local origin = typeof(args[10])=="Vector3" and args[10] or Camera.CFrame.Position
                        local mc = LP.Character
                        if mc then
                            local hrp = mc:FindFirstChild("HumanoidRootPart")
                            if hrp then origin=hrp.Position end
                        end
                        local hitPos = predictPos(bone, target)
                        if Config.SmartAimEnabled and bone.Name=="Head" then
                            hitPos = hitPos + getSmartHeadOffset()
                        end
                        if Config.BacktrackOn and BacktrackHistory[target] then
                            local hist = BacktrackHistory[target]
                            local bp2,bd2 = hitPos,(hitPos-origin).Magnitude
                            for k=1,#hist do
                                local dd=(hist[k].pos-origin).Magnitude
                                if dd<bd2 then bd2=dd; bp2=hist[k].pos end
                            end
                            hitPos=bp2
                        end
                        local delta = hitPos-origin
                        if delta.Magnitude>0.001 then
                            -- Anti-detection: check redirect angle vs original aim
                            local origDir = typeof(args[3])=="Vector3" and args[3].Unit or Camera.CFrame.LookVector
                            local newDir = delta.Unit
                            local dotAngle = origDir:Dot(newDir)
                            -- Redirect: silent/BTP always redirect, legit checks angle
                            if silentOn or btpOn or dotAngle > 0.5 then
                                args[1]  = bone
                                args[2]  = hitPos
                                args[3]  = newDir
                                args[10] = origin
                                if Rem.DistributedTime then
                                    local dtv = Rem.DistributedTime.Value
                                    if typeof(dtv)=="string" then dtv = tonumber(dtv) end
                                    if dtv then args[11] = dtv end
                                end
                                if Config.DamageSync and typeof(args[5])=="number" and OrigVals.Damage then
                                    args[5] = OrigVals.Damage * getServerMultiplier(bone.Name)
                                end
                                -- Server bypass: floor numeric args to match server validation
                                if typeof(args[5])=="number" then args[5] = mFloor(args[5]) end
                                if typeof(args[7])=="number" then args[7] = mFloor(args[7] + 0.5) end
                                _lastRedirect = tick()
                                didRedirect = true
                            end
                        end
                    end
                end
                if Config.NoSpread and typeof(args[3])=="Vector3" and not didRedirect then
                    args[3] = Camera.CFrame.LookVector
                end
                if btpOn and typeof(args[7])=="number" and OrigVals.BulletSpeed then
                    if Config.BulletTPMode=="Speed" then
                        args[7] = OrigVals.BulletSpeed * Config.BulletTPMult
                    else
                        args[7] = OrigVals.BulletSpeed
                    end
                end
            end)
            -- Safety: ensure numeric args are numbers even if pcall exited early
            for _,idx in ipairs(SANITIZE_IDX) do
                if typeof(args[idx])=="string" then
                    local num = tonumber(args[idx])
                    if num then args[idx]=num end
                end
            end
            return oldNamecall(self,unpack(args,1,n))
        end

        -- LAYER 2: CreateTrail visual redirect
        if self==Rem.CreateTrail and (silentOn or btpOn) then
            local args = {...}
            local n    = select("#",...)
            pcall(function()
                local t = validateTarget(getFrameTarget())
                if t and t.Character then
                    local bone = resolveBone(t)
                    if bone and bone:IsA("BasePart")
                       and typeof(args[1])=="Vector3"
                       and typeof(args[2])=="Vector3" then
                        args[2] = bone.Position
                    end
                end
            end)
            return oldNamecall(self,unpack(args,1,n))
        end
    end

    return oldNamecall(self,...)
end))

------------------------------------------------------------------------
-- 12-13. METAMETHOD HOOKS (rawmetatable — Wave-compatible)
-- _hookMT, oldIndex, oldNewIndex captured in 10b BEFORE hookmetamethod.
-- Re-install on the pre-captured reference so hookmetamethod can't corrupt.
------------------------------------------------------------------------
setreadonly(_hookMT, false)

-- 12a. __index — spoof weapon value reads (NumberValue ONLY, like standalone)
_hookMT.__index = newcclosure(function(self, key)
    if _hookGuard then
        if tick()-_hookGuardTk>0.05 then _hookGuard=false else return oldIndex(self,key) end
    end
    if not checkcaller() and key=="Value" and typeof(self)=="Instance" and self:IsA("NumberValue") then
        local name = self.Name
        if Config.NoRecoil and (name=="Recoil" or name=="LRecoil" or name=="RRecoil") then
            return 0
        end
        if Config.NoSpread and name=="Spread" then
            return 0
        end
        if Config.InfiniteAmmo and name=="Ammo" then
            return 999
        end
        if Config.RapidFire and name=="FireRate" then
            return Config.RapidFireDelay
        end
        if Config.BulletTPEnabled then
            if name=="BulletSpeed" and OrigVals.BulletSpeed then
                return Config.BulletTPMode=="Speed"
                    and OrigVals.BulletSpeed * Config.BulletTPMult
                    or  OrigVals.BulletSpeed
            end
            if name=="BulletDrop" then return 0 end
        end
    end
    return oldIndex(self,key)
end)

-- 12b. __newindex — pass-through (standalone has NO __newindex hook;
-- the old catch-all string→number conversion was causing
-- 'Unable to cast Vector3 to bool' in the game's firebullet)
_hookMT.__newindex = newcclosure(function(self, key, value)
    return oldNewIndex(self, key, value)
end)

setreadonly(_hookMT, true)

------------------------------------------------------------------------
-- 14. ANTI-KICK
------------------------------------------------------------------------
pcall(function()
    if not hookfunction or not newcclosure then return end
    local old; old = hookfunction(LP.Kick,newcclosure(function(s,r)
        if Config.AntiKick then return end
        if old then return old(s,r) end
    end))
end)

pcall(function()
    if not getconnections then return end
    local ok,c = pcall(getconnections,LP.OnTeleport)
    if ok and c then for _,cn in ipairs(c) do pcall(function() cn:Disable() end) end end
end)

pcall(function()
    CoreGui.DescendantAdded:Connect(function(d)
        if not Config.AntiKick then return end
        task.defer(function()
            pcall(function()
                if d.Name=="ErrorPrompt" or d.Name=="ErrorMessage" then
                    local p = d:FindFirstAncestorOfClass("ScreenGui")
                    if p and p.Name~="DomkaModzUI" then d.Visible=false end
                end
            end)
        end)
    end)
end)

------------------------------------------------------------------------
-- 15. GC SCANNER
------------------------------------------------------------------------
local function scanGC()
    pcall(function()
        for _,v in ipairs(getgc(true)) do
            if typeof(v)=="table" then
                if rawget(v,"Damage") and rawget(v,"Spread") and (rawget(v,"FireRate") or rawget(v,"Recoil")) then
                    GameInt.WeaponModule = v
                end
                if rawget(v,"visualizePoint") or rawget(v,"visualizeRay") then
                    GameInt.VisModule = v
                end
                if rawget(v,"takedamage") then GameInt.TakeDmg = v end
            end
        end
    end)
end
scanGC()

------------------------------------------------------------------------
-- 16. COMBAT: Aimbot, RCS, Triggerbot
------------------------------------------------------------------------
local AimbotActive  = false
local CurrentTarget = nil

local function smoothAim(tPos,smooth)
    local cf = Camera.CFrame
    local dir = (tPos-cf.Position).Unit
    local goal = CFrame.lookAt(cf.Position,cf.Position+dir)
    return cf:Lerp(goal,1/mMax(smooth,1))
end

local lastCamCF = Camera.CFrame

local _m1Down = false
UIS.InputBegan:Connect(function(i,g) if g then return end; if i.UserInputType==Enum.UserInputType.MouseButton1 then _m1Down=true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _m1Down=false end end)

local function applyRCS()
    if not isWeaponEquipped() then lastCamCF=Camera.CFrame; return end
    local cur = Camera.CFrame
    local ly,lp,_ = lastCamCF:ToEulerAnglesYXZ()
    local cy,cp,_ = cur:ToEulerAnglesYXZ()
    local dP = cp-lp
    local dY = cy-ly
    if Config.NoRecoil and _m1Down and not (Config.AimbotEnabled and AimbotActive) and not Config.ThirdPerson then
        local cP,cY = 0,0
        if dP<-0.0005 then cP = mAbs(dP) end
        if mAbs(dY)>0.0005 then cY = -dY*0.9 end
        if cP>0 or cY~=0 then
            Camera.CFrame = cur*CFa(cP,cY,0)
            lastCamCF = Camera.CFrame
            return
        end
    end
    if Config.RCSEnabled and not Config.NoRecoil and dP<-0.002 then
        local comp = mAbs(dP)*Config.RCSStrength
        Camera.CFrame = cur*CFa(comp,0,0)
    end
    lastCamCF = Camera.CFrame
end

local lastTrig    = 0
local _trigFiring = false
local trigParams  = RaycastParams.new()
trigParams.FilterType = Enum.RaycastFilterType.Exclude

local function findPlrFromPart(part)
    local inst = part
    for _=1,8 do
        if not inst then return nil end
        local p = Players:GetPlayerFromCharacter(inst)
        if p then return p end
        inst = inst.Parent
    end
    return nil
end

local function runTrigger()
    if not Config.TriggerEnabled or _trigFiring then return end
    if tick()-lastTrig<Config.TriggerDelay then return end
    local fire = false
    local sil = (Config.AimbotEnabled and Config.AimbotMode=="Silent") or Config.BulletTPEnabled
    if sil then
        if validateTarget(getFrameTarget()) then fire=true end
    else
        trigParams.FilterDescendantsInstances = buildIgnore()
        local ok,r = pcall(Workspace.Raycast,Workspace,Camera.CFrame.Position,Camera.CFrame.LookVector*2000,trigParams)
        if ok and r and r.Instance then
            local p = findPlrFromPart(r.Instance)
            if p and isEnemy(p) and isAlive(p) then fire=true end
        end
    end
    if fire then
        lastTrig=tick(); _trigFiring=true
        task.spawn(function()
            pcall(function()
                mouse1press()
                task.wait(0.04+mRand()*0.02)
                mouse1release()
            end)
            _trigFiring=false
        end)
    end
end

------------------------------------------------------------------------
-- 17. WEAPON MODS + SPEED HACK
------------------------------------------------------------------------
local _gunCache   = nil
local _gunCacheTk = 0

findGun = function()
    local now = tick()
    if now-_gunCacheTk<0.05 and _gunCache and _gunCache.Parent then return _gunCache end
    local result = nil
    local c = LP.Character
    if c then
        local g = c:FindFirstChild("Gun")
        if g then result=g end
    end
    if not result then
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            local g = bp:FindFirstChild("Gun")
            if g then result=g end
        end
    end
    _gunCache=result; _gunCacheTk=now
    return result
end

local function setVal(obj,val)
    if not obj or typeof(val)~="number" then return end
    if obj:IsA("NumberValue") then
        if obj.Value~=val then pcall(function() obj.Value=val end) end
    elseif obj:IsA("IntValue") then
        local r = mFloor(val+0.5)
        if obj.Value~=r then pcall(function() obj.Value=r end) end
    elseif obj:IsA("StringValue") then
        local s = tostring(val)
        if obj.Value~=s then pcall(function() obj.Value=s end) end
    else
        pcall(function() obj.Value=val end)
    end
end

local RECOIL_KEYS = {"Recoil","LRecoil","RRecoil"}

local function modWeapon()
    local gun = findGun()
    if not gun then LastGun=nil; return end
    local isNewGun = (gun ~= LastGun)
    captureWeapon(gun)
    if isNewGun and not GameInt.WeaponModule then pcall(scanGC) end
    -- Direct writes like the standalone script — no setVal, no comparisons
    for _,n in ipairs(RECOIL_KEYS) do
        local v = gun:FindFirstChild(n)
        if v then
            if Config.NoRecoil then
                pcall(function() v.Value = 0 end)
            elseif OrigVals[n] then
                pcall(function() v.Value = OrigVals[n] end)
            end
        end
    end
    local sp = gun:FindFirstChild("Spread")
    if sp then
        if Config.NoSpread then
            pcall(function() sp.Value = 0 end)
        elseif OrigVals.Spread then
            pcall(function() sp.Value = OrigVals.Spread end)
        end
    end
    if Config.InfiniteAmmo then
        local a = gun:FindFirstChild("Ammo")
        local bi = gun:FindFirstChild("BI")
        local biVal = bi and (typeof(bi.Value)=="number" and bi.Value or tonumber(bi.Value)) or 999
        if a then pcall(function() a.Value = biVal end) end
    end
    if Config.RapidFire then
        local fr = gun:FindFirstChild("FireRate")
        if fr then pcall(function() fr.Value = Config.RapidFireDelay end) end
    end
end

local _lastSpeed = 16
local function applySpeed()
    local c = LP.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local target = Config.SpeedHack and (16*Config.SpeedMult) or 16
    if h.WalkSpeed ~= target then h.WalkSpeed = target end
    _lastSpeed = target
end

------------------------------------------------------------------------
-- 17b. ANTI-AIM DESYNC (rotates Neck + Waist for full body desync)
------------------------------------------------------------------------
local _aaFlip = false
local _aaNeckObj, _aaNeckBase = nil, nil
local _aaWaistObj, _aaWaistBase = nil, nil
local function restoreNeck()
    pcall(function()
        if _aaNeckObj and _aaNeckBase and _aaNeckObj.Parent then
            _aaNeckObj.C0 = _aaNeckBase
        end
        if _aaWaistObj and _aaWaistBase and _aaWaistObj.Parent then
            _aaWaistObj.C0 = _aaWaistBase
        end
    end)
end
local function applyAntiAim()
    local c = LP.Character
    if not c then _aaNeckObj=nil; _aaNeckBase=nil; _aaWaistObj=nil; _aaWaistBase=nil; return end
    -- Find Neck (Head rotation)
    local head = c:FindFirstChild("Head")
    if head then
        local neck = head:FindFirstChild("Neck") or c:FindFirstChild("Neck")
        if neck and neck:IsA("Motor6D") then
            if neck ~= _aaNeckObj then _aaNeckObj=neck; _aaNeckBase=neck.C0 end
        end
    end
    -- Find Waist/Root (Body rotation)
    local ut = c:FindFirstChild("UpperTorso")
    if ut then
        local waist = ut:FindFirstChild("Waist")
        if waist and waist:IsA("Motor6D") then
            if waist ~= _aaWaistObj then _aaWaistObj=waist; _aaWaistBase=waist.C0 end
        end
    end
    if not _aaWaistObj then
        local lt = c:FindFirstChild("LowerTorso")
        if lt then
            local root = lt:FindFirstChild("Root")
            if root and root:IsA("Motor6D") then
                if root ~= _aaWaistObj then _aaWaistObj=root; _aaWaistBase=root.C0 end
            end
        end
    end
    if not Config.AntiAimOn then restoreNeck(); return end
    _aaFlip = not _aaFlip
    local headJitter = _aaFlip and 3.14 or (mRand()-0.5)*2.5
    local bodyJitter = _aaFlip and -2.8 or (mRand()-0.5)*2.0
    if _aaNeckObj and _aaNeckBase then
        pcall(function() _aaNeckObj.C0 = _aaNeckBase * CFa(0, headJitter, 0) end)
    end
    if _aaWaistObj and _aaWaistBase then
        pcall(function() _aaWaistObj.C0 = _aaWaistBase * CFa(0, bodyJitter, 0) end)
    end
end

------------------------------------------------------------------------
-- 17c. HITBOX EXPANSION (virtual — no Part.Size modification)
------------------------------------------------------------------------
-- Hitbox expansion is applied as FOV tolerance in getClosestTarget.
-- No Instance properties are modified, so the server cannot detect it.
local function updateHitboxes() end

------------------------------------------------------------------------
-- 18. 3RD PERSON CAMERA (connection-based transparency)
------------------------------------------------------------------------
local _3pDist = 0
local _3pConns = {}
local _3pChar = nil

local function clear3PConns()
    for _,cn in ipairs(_3pConns) do pcall(function() cn:Disconnect() end) end
    _3pConns = {}
end

local function setup3PChar(char)
    clear3PConns()
    _3pChar = char
    if not char then return end
    local function hookPart(v)
        if not v:IsA("BasePart") then return end
        if not v.Parent then return end
        pcall(function() v.LocalTransparencyModifier = 0 end)
        local cn; cn = v:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
            if Config.ThirdPerson and v.Parent then
                pcall(function() v.LocalTransparencyModifier = 0 end)
            end
        end)
        tInsert(_3pConns, cn)
    end
    for _,v in ipairs(char:GetDescendants()) do pcall(hookPart,v) end
    tInsert(_3pConns, char.DescendantAdded:Connect(function(v)
        task.defer(function()
            if v.Parent then pcall(hookPart,v) end
        end)
    end))
end

RunService:BindToRenderStep("DomkaModz_3P",Enum.RenderPriority.Camera.Value+10,function()
    pcall(function()
        if not Config.ThirdPerson then
            _3pDist = 0
            if _3pChar then setup3PChar(nil) end
            return
        end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local c = LP.Character
        if not c then _3pDist = 0; if _3pChar then setup3PChar(nil) end; return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then _3pDist = 0; if _3pChar then setup3PChar(nil) end; return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if c ~= _3pChar then setup3PChar(c) end
        _3pDist = _3pDist + (Config.ThirdPersonDist - _3pDist) * mClamp(Config.ThirdPersonSmooth, 0.01, 1)
        local cf = cam.CFrame
        cam.CFrame = cf - cf.LookVector * _3pDist
    end)
end)

------------------------------------------------------------------------
-- 19. ANTI-AFK
------------------------------------------------------------------------
do
    local VU = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        if not Config.AntiAFK then return end
        VU:CaptureController()
        VU:ClickButton2(V2(0,0))
    end)
end

------------------------------------------------------------------------
-- 19b. NOCLIP + FLY
------------------------------------------------------------------------
local _noclipConn = nil
local _ncParts, _ncChar = {}, nil
pcall(function()
    _noclipConn = RunService.Stepped:Connect(function()
        if not Config.NoclipEnabled then return end
        local c = LP.Character
        if not c then _ncChar=nil; return end
        if c ~= _ncChar then
            _ncChar = c; _ncParts = {}
            for _,v in ipairs(c:GetDescendants()) do
                if v:IsA("BasePart") then tInsert(_ncParts, v) end
            end
            c.DescendantAdded:Connect(function(v)
                if v:IsA("BasePart") then tInsert(_ncParts, v) end
            end)
        end
        for i = #_ncParts, 1, -1 do
            local v = _ncParts[i]
            if v.Parent then v.CanCollide = false
            else table.remove(_ncParts, i) end
        end
    end)
end)

local _flyBV, _flyBG = nil, nil
local function updateFly()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if Config.FlyEnabled then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        if not _flyBV or not _flyBV.Parent then
            _flyBV = Instance.new("BodyVelocity")
            _flyBV.MaxForce = V3(mHuge,mHuge,mHuge)
            _flyBV.Velocity = V3(0,0,0)
            _flyBV.Parent = hrp
        end
        if not _flyBG or not _flyBG.Parent then
            _flyBG = Instance.new("BodyGyro")
            _flyBG.MaxTorque = V3(mHuge,mHuge,mHuge)
            _flyBG.P = 9e4
            _flyBG.Parent = hrp
        end
        local spd = Config.FlySpeed
        local cf = Camera.CFrame
        local dir = V3(0,0,0)
        local typing = UIS:GetFocusedTextBox() ~= nil
        if not typing then
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + V3(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - V3(0,1,0) end
        end
        _flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * spd or V3(0,0,0)
        _flyBG.CFrame = cf
    else
        if _flyBV and _flyBV.Parent then _flyBV:Destroy() end
        if _flyBG and _flyBG.Parent then _flyBG:Destroy() end
        _flyBV, _flyBG = nil, nil
    end
end

------------------------------------------------------------------------
-- 19c. FULLBRIGHT
------------------------------------------------------------------------
local _fbOriginal = {}
local _fbApplied = false
local function applyFullbright()
    local L = game:GetService("Lighting")
    if Config.Fullbright and not _fbApplied then
        _fbOriginal.Brightness = L.Brightness
        _fbOriginal.ClockTime = L.ClockTime
        _fbOriginal.FogEnd = L.FogEnd
        _fbOriginal.GlobalShadows = L.GlobalShadows
        L.Brightness = 2; L.ClockTime = 14; L.FogEnd = 1e6; L.GlobalShadows = false
        for _,v in ipairs(L:GetChildren()) do
            if v:IsA("Atmosphere") then
                v:SetAttribute("_fbDens", v.Density); v.Density = 0
            elseif v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") then
                v:SetAttribute("_fbOn", v.Enabled); v.Enabled = false
            end
        end
        _fbApplied = true
    elseif not Config.Fullbright and _fbApplied then
        if _fbOriginal.Brightness then L.Brightness = _fbOriginal.Brightness end
        if _fbOriginal.ClockTime then L.ClockTime = _fbOriginal.ClockTime end
        if _fbOriginal.FogEnd then L.FogEnd = _fbOriginal.FogEnd end
        if _fbOriginal.GlobalShadows ~= nil then L.GlobalShadows = _fbOriginal.GlobalShadows end
        for _,v in ipairs(L:GetChildren()) do
            local d = v:GetAttribute("_fbDens")
            local e = v:GetAttribute("_fbOn")
            if d then v.Density = d; v:SetAttribute("_fbDens", nil) end
            if e ~= nil then v.Enabled = e; v:SetAttribute("_fbOn", nil) end
        end
        _fbApplied = false
    end
end

------------------------------------------------------------------------
-- 20. DRAWING HELPER + ESP
------------------------------------------------------------------------
local function newDraw(cls,props)
    local d = Drawing.new(cls)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local ESP = {}
local BONE_PAIRS = {
    {"Head","UpperTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LeftHand","LeftLowerArm"},{"RightHand","RightLowerArm"},
    {"LeftFoot","LeftLowerLeg"},{"RightFoot","RightLowerLeg"},
}

local function createESP(p)
    if ESP[p] then return end
    pcall(function()
        local c = p.Character
        if c then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then hum.Died:Connect(function()
                if isEnemy(p) then onEnemyDied() end
            end) end
        end
    end)
    local ac = Theme.accent()
    ESP[p] = {
        box     = newDraw("Square",{Thickness=1.2,Filled=false,Color=ac,Visible=false,Transparency=1}),
        boxFill = newDraw("Square",{Thickness=1,Filled=true,Color=Theme.bg(),Visible=false,Transparency=0.82}),
        name    = newDraw("Text",{Size=13,Center=true,Outline=true,Color=Theme.text(),Visible=false,Font=2}),
        health  = newDraw("Square",{Thickness=1,Filled=true,Color=Theme.success(),Visible=false}),
        hpBG    = newDraw("Square",{Thickness=1,Filled=true,Color=Color3.fromRGB(35,35,35),Visible=false}),
        dist    = newDraw("Text",{Size=11,Center=true,Outline=true,Color=Theme.dim(),Visible=false,Font=2}),
        weapon  = newDraw("Text",{Size=11,Center=true,Outline=true,Color=Theme.dim(),Visible=false,Font=2}),
        skel    = {},
    }
    for i=1,#BONE_PAIRS do
        ESP[p].skel[i] = newDraw("Line",{Thickness=1,Color=ac,Visible=false,Transparency=1})
    end
end

local function removeESP(p)
    local d = ESP[p]
    if not d then return end
    for _,v in pairs(d) do
        if typeof(v)=="table" then
            for _,dr in pairs(v) do pcall(function() dr:Remove() end) end
        else pcall(function() v:Remove() end) end
    end
    ESP[p]=nil
end

local function hideESP(d)
    for _,v in pairs(d) do
        if typeof(v)=="table" then
            for _,dr in pairs(v) do pcall(function() dr.Visible=false end) end
        else pcall(function() v.Visible=false end) end
    end
end

local function getWeaponStr(char)
    if not char then return "---" end
    local gun = char:FindFirstChild("Gun")
    if not gun then return "---" end
    local str = gun.Name
    if Config.AmmoESP then
        local a = gun:FindFirstChild("Ammo")
        local bi = gun:FindFirstChild("BI")
        if a and bi then
            local av,bv = tonumber(a.Value),tonumber(bi.Value)
            if av and bv then str = str.." ["..mFloor(av).."/"..mFloor(bv).."]"
            end
        end
    end
    return str
end

local function updateESP(p)
    local d = ESP[p]
    if not d then return end
    local char = p.Character
    if not (Config.ESPEnabled and char and isEnemy(p) and isAlive(p)) then
        hideESP(d); return
    end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and head and hum) then hideESP(d); return end
    local pos,onS = Camera:WorldToViewportPoint(hrp.Position)
    if not onS then hideESP(d); return end
    local tp = Camera:WorldToViewportPoint(head.Position+V3(0,1.5,0))
    local bp = Camera:WorldToViewportPoint(hrp.Position-V3(0,3,0))
    local h = mAbs(bp.Y-tp.Y)
    local w = h*0.45
    local bx = pos.X-w*0.5
    local by = tp.Y
    local ac = Theme.accent()

    if Config.BoxESP then
        local p2,s2 = V2(bx,by),V2(w,h)
        d.boxFill.Position=p2; d.boxFill.Size=s2; d.boxFill.Visible=true
        d.box.Position=p2; d.box.Size=s2; d.box.Color=ac; d.box.Visible=true
    else d.box.Visible=false; d.boxFill.Visible=false end

    if Config.NameESP then
        local spot = char:FindFirstChild("Spotted")
        d.name.Text = (spot and "[!] " or "")..p.Name
        d.name.Position = V2(pos.X,by-15)
        d.name.Color = spot and Theme.danger() or Theme.text()
        d.name.Visible=true
    else d.name.Visible=false end

    if Config.HealthBar then
        local f = mClamp(hum.Health/hum.MaxHealth,0,1)
        d.hpBG.Position=V2(bx-5,by); d.hpBG.Size=V2(2,h); d.hpBG.Visible=true
        d.health.Position=V2(bx-5,by+h*(1-f)); d.health.Size=V2(2,h*f)
        d.health.Color=Color3.fromRGB(255*(1-f),255*f,40); d.health.Visible=true
    else d.health.Visible=false; d.hpBG.Visible=false end

    local yOff = by+h+2
    if Config.DistESP then
        local mc = LP.Character
        local dst = mc and mc:FindFirstChild("HumanoidRootPart")
            and mFloor((mc.HumanoidRootPart.Position-hrp.Position).Magnitude) or 0
        d.dist.Text=dst.."m"; d.dist.Position=V2(pos.X,yOff); d.dist.Visible=true
        yOff=yOff+12
    else d.dist.Visible=false end

    if Config.WeaponESP then
        d.weapon.Text=getWeaponStr(char); d.weapon.Position=V2(pos.X,yOff); d.weapon.Visible=true
    else d.weapon.Visible=false end

    if Config.SkeletonESP then
        for i=1,#BONE_PAIRS do
            local ln = d.skel[i]
            if ln then
                local pr = BONE_PAIRS[i]
                local b1 = char:FindFirstChild(pr[1])
                local b2 = char:FindFirstChild(pr[2])
                if b1 and b2 and b1:IsA("BasePart") and b2:IsA("BasePart") then
                    local p1 = Camera:WorldToViewportPoint(b1.Position)
                    local p2 = Camera:WorldToViewportPoint(b2.Position)
                    ln.From=V2(p1.X,p1.Y); ln.To=V2(p2.X,p2.Y); ln.Color=ac; ln.Visible=true
                else ln.Visible=false end
            end
        end
    else
        for _,l in pairs(d.skel) do pcall(function() l.Visible=false end) end
    end
end

-- World ESP
local WDraw = {}
local function clearWESP() for _,d in pairs(WDraw) do pcall(function() d:Remove() end) end; WDraw={} end

local function updateWESP()
    clearWESP()
    if not Config.WorldESPOn then return end
    local deb = Workspace:FindFirstChild("Debris")
    if not deb then return end
    for _,item in ipairs(deb:GetChildren()) do
        if Config.DroppedWeapons and (item:FindFirstChild("Ammo") or item:FindFirstChild("Bullets")) and not item:FindFirstChild("ExplodeSC") then
            local ok,p,v = pcall(function() return Camera:WorldToViewportPoint(item.Position) end)
            if ok and v then
                tInsert(WDraw,newDraw("Text",{Text="[W] "..item.Name,Size=12,Center=true,Outline=true,
                    Color=Theme.warning(),Position=V2(p.X,p.Y),Visible=true,Font=2}))
            end
        end
        if Config.DroppedWeapons and (item.Name=="Ammobag" or item.Name=="Medkit") then
            local ok,p,v = pcall(function() return Camera:WorldToViewportPoint(item.Position) end)
            if ok and v then
                local ic = item.Name=="Medkit" and "[+] " or "[A] "
                tInsert(WDraw,newDraw("Text",{Text=ic..item.Name,Size=12,Center=true,Outline=true,
                    Color=Theme.success(),Position=V2(p.X,p.Y),Visible=true,Font=2}))
            end
        end
        if Config.GrenadesESP and (item.Name:find("Grenade") or item.Name:find("grenade") or item:FindFirstChild("ExplodeSC")) then
            local ok,p,v = pcall(function() return Camera:WorldToViewportPoint(item.Position) end)
            if ok and v then
                tInsert(WDraw,newDraw("Text",{Text="[!] "..item.Name,Size=13,Center=true,Outline=true,
                    Color=Theme.danger(),Position=V2(p.X,p.Y),Visible=true,Font=2}))
            end
        end
    end
end

-- Glow ESP
local Glows = {}
local function updateGlow(p)
    local c = p.Character
    if Config.GlowESP and Config.ESPEnabled and c and isEnemy(p) and isAlive(p) then
        if not Glows[p] then
            local h = Instance.new("Highlight")
            h.FillColor=Theme.accent(); h.OutlineColor=Color3.new(1,1,1)
            h.FillTransparency=0.65; h.OutlineTransparency=0.3
            h.Adornee=c; h.Parent=CoreGui
            Glows[p]=h
        else Glows[p].FillColor=Theme.accent() end
    else
        if Glows[p] then Glows[p]:Destroy(); Glows[p]=nil end
    end
end

-- FOV Circle
local FOVCircle = newDraw("Circle",{Thickness=1.2,Color=Theme.accent(),Filled=false,Visible=false,Transparency=0.5,NumSides=72})
local SnapLine = newDraw("Line",{Thickness=1.5,Color=Theme.accent(),Visible=false,Transparency=0.4})

-- Crosshair
local Crosshair = {
    newDraw("Line",{Thickness=1.5,Color=Color3.new(1,1,1),Visible=false,Transparency=1}),
    newDraw("Line",{Thickness=1.5,Color=Color3.new(1,1,1),Visible=false,Transparency=1}),
    newDraw("Line",{Thickness=1.5,Color=Color3.new(1,1,1),Visible=false,Transparency=1}),
    newDraw("Line",{Thickness=1.5,Color=Color3.new(1,1,1),Visible=false,Transparency=1}),
}

-- Hit Marker (X flash on redirect)
local HitMarker = {
    newDraw("Line",{Thickness=2,Color=Color3.new(1,1,1),Visible=false}),
    newDraw("Line",{Thickness=2,Color=Color3.new(1,1,1),Visible=false}),
    newDraw("Line",{Thickness=2,Color=Color3.new(1,1,1),Visible=false}),
    newDraw("Line",{Thickness=2,Color=Color3.new(1,1,1),Visible=false}),
}

-- Active Features HUD
local FeatHUD = newDraw("Text",{Size=12,Center=false,Outline=true,Color=Color3.fromRGB(200,200,220),Visible=false,Font=2,Position=V2(10,42)})

-- Radar Minimap
local RADAR_MAX_DOTS = 32
local RadarDraw = {
    bg     = newDraw("Square",{Size=V2(120,120),Position=V2(10,60),Color=Theme.bg(),Filled=true,Visible=false,Transparency=0.15}),
    border = newDraw("Square",{Size=V2(120,120),Position=V2(10,60),Color=Theme.accent(),Filled=false,Visible=false,Thickness=1.2}),
    cross1 = newDraw("Line",{Thickness=0.5,Color=Theme.dim(),Visible=false,Transparency=0.6}),
    cross2 = newDraw("Line",{Thickness=0.5,Color=Theme.dim(),Visible=false,Transparency=0.6}),
    center = newDraw("Triangle",{Filled=true,Color=Color3.new(1,1,1),Visible=false,Thickness=0}),
    dots   = {},
}
for _i=1,RADAR_MAX_DOTS do
    RadarDraw.dots[_i] = newDraw("Circle",{Radius=3,Position=V2(0,0),Color=Theme.danger(),Filled=true,Visible=false,NumSides=8,Transparency=1})
end

local function updateRadar()
    local sz = Config.RadarSize
    local rng = Config.RadarRange
    local vis = Config.RadarEnabled
    RadarDraw.bg.Size=V2(sz,sz); RadarDraw.bg.Position=V2(10,60); RadarDraw.bg.Visible=vis
    RadarDraw.border.Size=V2(sz,sz); RadarDraw.border.Position=V2(10,60); RadarDraw.border.Visible=vis
    local cx,cy = 10+sz/2, 60+sz/2
    RadarDraw.cross1.From=V2(cx,60); RadarDraw.cross1.To=V2(cx,60+sz); RadarDraw.cross1.Visible=vis
    RadarDraw.cross2.From=V2(10,cy); RadarDraw.cross2.To=V2(10+sz,cy); RadarDraw.cross2.Visible=vis
    RadarDraw.center.PointA=V2(cx,cy-4); RadarDraw.center.PointB=V2(cx-3,cy+3); RadarDraw.center.PointC=V2(cx+3,cy+3); RadarDraw.center.Visible=vis
    local dotIdx = 0
    if vis then
        local mc = LP.Character
        local mh = mc and mc:FindFirstChild("HumanoidRootPart")
        if mh then
            local myPos = mh.Position
            local myLook = Camera.CFrame.LookVector
            local myRight = Camera.CFrame.RightVector
            local pl = getPlayers()
            for i=1,#pl do
                local p = pl[i]
                if p~=LP and isAlive(p) and isEnemy(p) then
                    local tc = p.Character
                    if tc then
                        local thrp = tc:FindFirstChild("HumanoidRootPart")
                        if thrp then
                            local rel = thrp.Position - myPos
                            local dist2d = V2(rel.X, rel.Z).Magnitude
                            if dist2d <= rng and dotIdx < RADAR_MAX_DOTS then
                                dotIdx = dotIdx + 1
                                local fwd = myLook.X*rel.X + myLook.Z*rel.Z
                                local rgt = myRight.X*rel.X + myRight.Z*rel.Z
                                local angle = mAtan2(rgt, fwd)
                                local f = dist2d / rng
                                local dot = RadarDraw.dots[dotIdx]
                                dot.Position = V2(cx + mSin(angle) * f * (sz/2-4), cy - mCos(angle) * f * (sz/2-4))
                                dot.Color = Theme.danger()
                                dot.Visible = true
                            end
                        end
                    end
                end
            end
        end
    end
    for i=dotIdx+1,RADAR_MAX_DOTS do RadarDraw.dots[i].Visible = false end
end

------------------------------------------------------------------------
-- 21. UI FRAMEWORK
------------------------------------------------------------------------
if CoreGui:FindFirstChild("DomkaModzUI") then CoreGui:FindFirstChild("DomkaModzUI"):Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name="DomkaModzUI"; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.ResetOnSpawn=false; SG.Parent=CoreGui

local function tw(o,p,d,s,dir)
    local t=TweenService:Create(o,TweenInfo.new(d or .25,s or Enum.EasingStyle.Quint,dir or Enum.EasingDirection.Out),p); t:Play(); return t
end

local function ripple(btn)
    local r=Instance.new("Frame"); r.BackgroundColor3=Color3.new(1,1,1); r.BackgroundTransparency=.75
    r.BorderSizePixel=0; r.AnchorPoint=V2(.5,.5); r.Position=UDim2.new(.5,0,.5,0); r.Size=UDim2.new(0,0,0,0)
    r.ZIndex=btn.ZIndex+1; r.Parent=btn; Instance.new("UICorner",r).CornerRadius=UDim.new(1,0)
    local t=tw(r,{Size=UDim2.new(2.5,0,2.5,0),BackgroundTransparency=1},.5); t.Completed:Connect(function() r:Destroy() end)
end

local function glass(pr)
    local f=Instance.new("Frame"); f.BackgroundColor3=pr.Color or Theme.glass(); f.BackgroundTransparency=pr.Tr or .35
    f.BorderSizePixel=0; f.Size=pr.Size or UDim2.new(1,0,1,0); f.Position=pr.Pos or UDim2.new(0,0,0,0)
    f.ClipsDescendants=pr.Clip~=false; if pr.Parent then f.Parent=pr.Parent end
    Instance.new("UICorner",f).CornerRadius=pr.Corner or UDim.new(0,10)
    local st=Instance.new("UIStroke",f); st.Color=pr.BC or Color3.fromRGB(70,70,90); st.Thickness=pr.BT or 1; st.Transparency=pr.BTr or .5
    local gr=Instance.new("UIGradient",f)
    gr.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(180,180,200))}
    gr.Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,.92),NumberSequenceKeypoint.new(.5,.96),NumberSequenceKeypoint.new(1,.99)}
    gr.Rotation=pr.GA or 135; return f
end

local function makeDrag(frame,handle)
    local dragging,dInput,dStart,sPos; handle=handle or frame
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dStart=i.Position; sPos=frame.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then dInput=i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i==dInput and dragging then
            local d=i.Position-dStart
            frame.Position=UDim2.new(sPos.X.Scale,sPos.X.Offset+d.X,sPos.Y.Scale,sPos.Y.Offset+d.Y)
        end
    end)
end

-- Main Window
local MF = glass({Color=Theme.bg(),Tr=.05,Size=UDim2.new(0,640,0,470),Pos=UDim2.new(.5,0,.5,0),
    Corner=UDim.new(0,12),BC=Color3.fromRGB(80,80,110),BT=1.2,BTr=.3,Parent=SG,GA=145})
MF.Name="Main"; MF.AnchorPoint=V2(.5,.5)

local shadow=Instance.new("ImageLabel"); shadow.Name="Shadow"; shadow.AnchorPoint=V2(.5,.5)
shadow.Position=UDim2.new(.5,0,.5,6); shadow.Size=UDim2.new(1,50,1,50); shadow.BackgroundTransparency=1
shadow.Image="rbxassetid://5554236805"; shadow.ImageColor3=Color3.new(0,0,0); shadow.ImageTransparency=.4
shadow.ScaleType=Enum.ScaleType.Slice; shadow.SliceCenter=Rect.new(23,23,277,277); shadow.ZIndex=-1; shadow.Parent=MF

local glow=Instance.new("ImageLabel"); glow.Size=UDim2.new(1,20,0,60); glow.Position=UDim2.new(0,135,0,-20)
glow.BackgroundTransparency=1; glow.Image="rbxassetid://5554236805"; glow.ImageColor3=Theme.accent()
glow.ImageTransparency=.85; glow.ScaleType=Enum.ScaleType.Slice; glow.SliceCenter=Rect.new(23,23,277,277); glow.ZIndex=0; glow.Parent=MF

-- Title Bar
local TB = glass({Color=Theme.card(),Tr=.2,Size=UDim2.new(1,0,0,38),Pos=UDim2.new(0,0,0,0),
    Corner=UDim.new(0,12),BC=Theme.border(),BTr=.6,Parent=MF,GA=90})
TB.Name="TB"; TB.ZIndex=2
local tbF=Instance.new("Frame"); tbF.Size=UDim2.new(1,0,0,14); tbF.Position=UDim2.new(0,0,1,-14)
tbF.BackgroundColor3=Theme.card(); tbF.BackgroundTransparency=.2; tbF.BorderSizePixel=0; tbF.ZIndex=2; tbF.Parent=TB
local aLine=Instance.new("Frame"); aLine.Size=UDim2.new(1,-24,0,2); aLine.Position=UDim2.new(0,12,1,-1)
aLine.BackgroundColor3=Theme.accent(); aLine.BackgroundTransparency=.5; aLine.BorderSizePixel=0; aLine.ZIndex=3; aLine.Parent=TB
Instance.new("UICorner",aLine).CornerRadius=UDim.new(1,0)
local TL=Instance.new("TextLabel"); TL.Text="DomkaModz"; TL.Font=Enum.Font.GothamBold; TL.TextSize=16
TL.TextColor3=Theme.text(); TL.BackgroundTransparency=1; TL.Size=UDim2.new(0,140,1,0); TL.Position=UDim2.new(0,16,0,0)
TL.TextXAlignment=Enum.TextXAlignment.Left; TL.ZIndex=3; TL.Parent=TB
local VL=Instance.new("TextLabel"); VL.Text="v5.0"; VL.Font=Enum.Font.Gotham; VL.TextSize=10; VL.TextColor3=Theme.accent()
VL.BackgroundTransparency=1; VL.Size=UDim2.new(0,30,1,0); VL.Position=UDim2.new(0,128,0,0)
VL.TextXAlignment=Enum.TextXAlignment.Left; VL.ZIndex=3; VL.Parent=TB
local FL=Instance.new("TextLabel"); FL.Text="FPS: --"; FL.Font=Enum.Font.GothamMedium; FL.TextSize=10; FL.TextColor3=Theme.dim()
FL.BackgroundTransparency=1; FL.Size=UDim2.new(0,70,1,0); FL.Position=UDim2.new(1,-80,0,0)
FL.TextXAlignment=Enum.TextXAlignment.Right; FL.ZIndex=3; FL.Parent=TB
makeDrag(MF,TB)

-- Sidebar
local SB = glass({Color=Theme.card(),Tr=.25,Size=UDim2.new(0,135,1,-38),Pos=UDim2.new(0,0,0,38),
    Corner=UDim.new(0,0),BC=Theme.border(),BTr=.7,Parent=MF,Clip=true,GA=180})
local sbLayout=Instance.new("UIListLayout",SB); sbLayout.SortOrder=Enum.SortOrder.LayoutOrder; sbLayout.Padding=UDim.new(0,3)
local sbP=Instance.new("UIPadding",SB); sbP.PaddingTop=UDim.new(0,10); sbP.PaddingLeft=UDim.new(0,8); sbP.PaddingRight=UDim.new(0,8)

-- Content
local CA=Instance.new("Frame"); CA.Name="Content"; CA.Size=UDim2.new(1,-135,1,-38); CA.Position=UDim2.new(0,135,0,38)
CA.BackgroundTransparency=1; CA.BorderSizePixel=0; CA.ClipsDescendants=true; CA.Parent=MF

------------------------------------------------------------------------
-- TAB SYSTEM
------------------------------------------------------------------------
local Tabs,ActiveTab = {},nil
local function switchTab(tab)
    if ActiveTab==tab then return end
    if ActiveTab then ActiveTab.page.Visible=false; ActiveTab.ind.Visible=false
        tw(ActiveTab.btn,{BackgroundTransparency=1,TextColor3=Theme.dim()},.2) end
    ActiveTab=tab; tab.page.Visible=true; tab.ind.Visible=true
    tw(tab.btn,{BackgroundTransparency=.82,TextColor3=Theme.text()},.2)
end

local function createTab(name,icon,order)
    local b=Instance.new("TextButton"); b.Name=name; b.Text=(icon or "").."  "..name
    b.Font=Enum.Font.GothamMedium; b.TextSize=12; b.TextColor3=Theme.dim(); b.BackgroundColor3=Theme.glass()
    b.BackgroundTransparency=1; b.Size=UDim2.new(1,0,0,32); b.BorderSizePixel=0; b.LayoutOrder=order or 0
    b.TextXAlignment=Enum.TextXAlignment.Left; b.AutoButtonColor=false; b.ClipsDescendants=true; b.Parent=SB
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    local ind=Instance.new("Frame"); ind.Size=UDim2.new(0,3,.55,0); ind.AnchorPoint=V2(0,.5)
    ind.Position=UDim2.new(0,-7,.5,0); ind.BackgroundColor3=Theme.accent(); ind.BorderSizePixel=0; ind.Visible=false; ind.Parent=b
    Instance.new("UICorner",ind).CornerRadius=UDim.new(1,0)
    local pg=Instance.new("ScrollingFrame"); pg.Name=name.."Page"; pg.Size=UDim2.new(1,-14,1,-14); pg.Position=UDim2.new(0,7,0,7)
    pg.BackgroundTransparency=1; pg.BorderSizePixel=0; pg.ScrollBarThickness=3; pg.ScrollBarImageColor3=Theme.accent()
    pg.CanvasSize=UDim2.new(0,0,0,0); pg.AutomaticCanvasSize=Enum.AutomaticSize.Y; pg.Visible=false; pg.Parent=CA
    local pl=Instance.new("UIListLayout",pg); pl.Padding=UDim.new(0,5); pl.SortOrder=Enum.SortOrder.LayoutOrder
    local pp=Instance.new("UIPadding",pg); pp.PaddingTop=UDim.new(0,4); pp.PaddingBottom=UDim.new(0,4)
    local tab={name=name,btn=b,page=pg,ind=ind}; tInsert(Tabs,tab)
    b.MouseButton1Click:Connect(function() ripple(b); switchTab(tab) end)
    b.MouseEnter:Connect(function() if ActiveTab~=tab then tw(b,{BackgroundTransparency=.88},.12) end end)
    b.MouseLeave:Connect(function() if ActiveTab~=tab then tw(b,{BackgroundTransparency=1},.12) end end)
    return tab
end

------------------------------------------------------------------------
-- ELEMENT BUILDERS
------------------------------------------------------------------------
local EO=0
local function nO() EO=EO+1; return EO end

local function addSec(pg,txt)
    local l=Instance.new("TextLabel"); l.Text=txt; l.Font=Enum.Font.GothamBold; l.TextSize=12; l.TextColor3=Theme.accent()
    l.BackgroundTransparency=1; l.Size=UDim2.new(1,0,0,22); l.TextXAlignment=Enum.TextXAlignment.Left; l.LayoutOrder=nO(); l.Parent=pg
    Instance.new("UIPadding",l).PaddingLeft=UDim.new(0,4)
end

local function addTgl(pg,label,key)
    local fr=glass({Color=Theme.card(),Tr=.3,Size=UDim2.new(1,0,0,30),Corner=UDim.new(0,7),BC=Theme.border(),BTr=.7,Parent=pg,GA=100})
    fr.LayoutOrder=nO()
    local lb=Instance.new("TextLabel"); lb.Text=label; lb.Font=Enum.Font.Gotham; lb.TextSize=12; lb.TextColor3=Theme.text()
    lb.BackgroundTransparency=1; lb.Size=UDim2.new(.7,0,1,0); lb.Position=UDim2.new(0,10,0,0); lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=fr
    local bg=Instance.new("Frame"); bg.Size=UDim2.new(0,38,0,20); bg.AnchorPoint=V2(1,.5); bg.Position=UDim2.new(1,-10,.5,0)
    bg.BackgroundColor3=Theme.border(); bg.BorderSizePixel=0; bg.Parent=fr; Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("Frame"); kn.Size=UDim2.new(0,16,0,16); kn.AnchorPoint=V2(0,.5); kn.Position=UDim2.new(0,2,.5,0)
    kn.BackgroundColor3=Theme.text(); kn.BorderSizePixel=0; kn.Parent=bg; Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    local dt=Instance.new("Frame"); dt.Size=UDim2.new(0,6,0,6); dt.AnchorPoint=V2(.5,.5); dt.Position=UDim2.new(.5,0,.5,0)
    dt.BackgroundColor3=Theme.card(); dt.BorderSizePixel=0; dt.Parent=kn; Instance.new("UICorner",dt).CornerRadius=UDim.new(1,0)
    local function upd()
        if Config[key] then tw(bg,{BackgroundColor3=Theme.accent()},.2); tw(kn,{Position=UDim2.new(1,-18,.5,0),BackgroundColor3=Color3.new(1,1,1)},.2)
            tw(dt,{BackgroundColor3=Theme.accent()},.2)
        else tw(bg,{BackgroundColor3=Theme.border()},.2); tw(kn,{Position=UDim2.new(0,2,.5,0),BackgroundColor3=Theme.text()},.2)
            tw(dt,{BackgroundColor3=Theme.card()},.2) end end; upd()
    local btn=Instance.new("TextButton"); btn.Text=""; btn.BackgroundTransparency=1; btn.Size=UDim2.new(1,0,1,0); btn.Parent=fr
    btn.MouseButton1Click:Connect(function() Config[key]=not Config[key]; upd() end)
end

local function addSld(pg,label,key,mn,mx,step,suf)
    suf=suf or ""; step=step or 1
    local fr=glass({Color=Theme.card(),Tr=.3,Size=UDim2.new(1,0,0,46),Corner=UDim.new(0,7),BC=Theme.border(),BTr=.7,Parent=pg,GA=100})
    fr.LayoutOrder=nO()
    local lb=Instance.new("TextLabel"); lb.Text=label; lb.Font=Enum.Font.Gotham; lb.TextSize=12; lb.TextColor3=Theme.text()
    lb.BackgroundTransparency=1; lb.Size=UDim2.new(.6,0,0,20); lb.Position=UDim2.new(0,10,0,2); lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=fr
    local vl=Instance.new("TextLabel"); vl.Font=Enum.Font.GothamMedium; vl.TextSize=12; vl.TextColor3=Theme.accent()
    vl.BackgroundTransparency=1; vl.Size=UDim2.new(.35,0,0,20); vl.Position=UDim2.new(.65,-10,0,2); vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=fr
    local sbg=Instance.new("Frame"); sbg.Size=UDim2.new(1,-20,0,6); sbg.Position=UDim2.new(0,10,0,32); sbg.BackgroundColor3=Theme.border()
    sbg.BorderSizePixel=0; sbg.Parent=fr; Instance.new("UICorner",sbg).CornerRadius=UDim.new(1,0)
    local sf=Instance.new("Frame"); sf.Size=UDim2.new(0,0,1,0); sf.BackgroundColor3=Theme.accent(); sf.BorderSizePixel=0; sf.Parent=sbg
    Instance.new("UICorner",sf).CornerRadius=UDim.new(1,0)
    local sk=Instance.new("Frame"); sk.Size=UDim2.new(0,14,0,14); sk.AnchorPoint=V2(.5,.5); sk.Position=UDim2.new(0,0,.5,0)
    sk.BackgroundColor3=Color3.new(1,1,1); sk.BorderSizePixel=0; sk.ZIndex=2; sk.Parent=sbg
    Instance.new("UICorner",sk).CornerRadius=UDim.new(1,0)
    local ks=Instance.new("UIStroke",sk); ks.Color=Theme.accent(); ks.Thickness=2; ks.Transparency=.6
    local function upS(v) v=mClamp(v,mn,mx); v=mFloor(v/step+.5)*step; Config[key]=v; local f=(v-mn)/(mx-mn)
        sf.Size=UDim2.new(f,0,1,0); sk.Position=UDim2.new(f,0,.5,0); vl.Text=tostring(mFloor(v*100)/100)..suf end
    upS(Config[key])
    local sliding=false
    local sb2=Instance.new("TextButton"); sb2.Text=""; sb2.BackgroundTransparency=1; sb2.Size=UDim2.new(1,0,1,12); sb2.Position=UDim2.new(0,0,0,-6); sb2.Parent=sbg
    sb2.MouseButton1Down:Connect(function() sliding=true end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
    UIS.InputChanged:Connect(function(i) if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then
        local f=mClamp((i.Position.X-sbg.AbsolutePosition.X)/sbg.AbsoluteSize.X,0,1); upS(mn+f*(mx-mn)) end end)
end

local function addDrop(pg,label,key,opts)
    local fr=glass({Color=Theme.card(),Tr=.3,Size=UDim2.new(1,0,0,30),Corner=UDim.new(0,7),BC=Theme.border(),BTr=.7,Parent=pg,Clip=false,GA=100})
    fr.LayoutOrder=nO()
    local lb=Instance.new("TextLabel"); lb.Text=label; lb.Font=Enum.Font.Gotham; lb.TextSize=12; lb.TextColor3=Theme.text()
    lb.BackgroundTransparency=1; lb.Size=UDim2.new(.5,0,0,20); lb.Position=UDim2.new(0,10,0,2); lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=fr
    local db=Instance.new("TextButton"); db.Text=tostring(Config[key]).."  v"; db.Font=Enum.Font.GothamMedium; db.TextSize=11
    db.TextColor3=Theme.accent(); db.BackgroundColor3=Theme.bg(); db.BackgroundTransparency=.3
    db.Size=UDim2.new(.4,0,0,24); db.AnchorPoint=V2(1,.5); db.Position=UDim2.new(1,-8,.5,0); db.BorderSizePixel=0
    db.AutoButtonColor=false; db.Parent=fr; Instance.new("UICorner",db).CornerRadius=UDim.new(0,5)
    local dl=glass({Color=Theme.bg(),Tr=.1,Size=UDim2.new(.4,0,0,#opts*26),Pos=UDim2.new(1,-8,1,4),
        Corner=UDim.new(0,6),BC=Theme.accent(),BTr=.6,Parent=fr,GA=180})
    dl.AnchorPoint=V2(1,0); dl.Visible=false; dl.ZIndex=10
    Instance.new("UIListLayout",dl).SortOrder=Enum.SortOrder.LayoutOrder
    for i,opt in ipairs(opts) do
        local ob=Instance.new("TextButton"); ob.Text=opt; ob.Font=Enum.Font.Gotham; ob.TextSize=11; ob.TextColor3=Theme.text()
        ob.BackgroundTransparency=1; ob.Size=UDim2.new(1,0,0,26); ob.LayoutOrder=i; ob.ZIndex=11; ob.Parent=dl
        ob.MouseButton1Click:Connect(function() Config[key]=opt; db.Text=opt.."  v"; dl.Visible=false end)
        ob.MouseEnter:Connect(function() tw(ob,{BackgroundTransparency=.8,TextColor3=Theme.accent()},.1) end)
        ob.MouseLeave:Connect(function() tw(ob,{BackgroundTransparency=1,TextColor3=Theme.text()},.1) end)
    end
    db.MouseButton1Click:Connect(function() dl.Visible=not dl.Visible end)
end

local function addBtn(pg,label,cb)
    local b=Instance.new("TextButton"); b.Text=label; b.Font=Enum.Font.GothamMedium; b.TextSize=12
    b.TextColor3=Color3.new(1,1,1); b.BackgroundColor3=Theme.accent(); b.BackgroundTransparency=.15
    b.Size=UDim2.new(1,0,0,30); b.BorderSizePixel=0; b.LayoutOrder=nO(); b.AutoButtonColor=false; b.ClipsDescendants=true; b.Parent=pg
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    b.MouseButton1Click:Connect(function() ripple(b); if cb then cb() end end)
    b.MouseEnter:Connect(function() tw(b,{BackgroundTransparency=.05},.12) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundTransparency=.15},.12) end)
end

local function addKeybind(pg,label,key)
    local fr=glass({Color=Theme.card(),Tr=.3,Size=UDim2.new(1,0,0,30),Corner=UDim.new(0,7),BC=Theme.border(),BTr=.7,Parent=pg,GA=100})
    fr.LayoutOrder=nO()
    local lb=Instance.new("TextLabel"); lb.Text=label; lb.Font=Enum.Font.Gotham; lb.TextSize=12; lb.TextColor3=Theme.text()
    lb.BackgroundTransparency=1; lb.Size=UDim2.new(.6,0,1,0); lb.Position=UDim2.new(0,10,0,0); lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=fr
    local kb=Instance.new("TextButton"); kb.Font=Enum.Font.GothamMedium; kb.TextSize=11
    kb.TextColor3=Theme.accent(); kb.BackgroundColor3=Theme.bg(); kb.BackgroundTransparency=.3
    kb.Size=UDim2.new(.35,0,0,22); kb.AnchorPoint=V2(1,.5); kb.Position=UDim2.new(1,-8,.5,0); kb.BorderSizePixel=0
    kb.AutoButtonColor=false; kb.Parent=fr; Instance.new("UICorner",kb).CornerRadius=UDim.new(0,5)
    local listening=false
    local function updateText()
        local val=Config[key]
        if typeof(val)=="EnumItem" then kb.Text="["..val.Name.."]" else kb.Text="[???]" end
    end; updateText()
    kb.MouseButton1Click:Connect(function() listening=true; kb.Text="[...]"; kb.TextColor3=Theme.warning() end)
    UIS.InputEnded:Connect(function(i,gpe) if not listening then return end; if gpe then return end
        listening=false
        if i.UserInputType==Enum.UserInputType.Keyboard then Config[key]=i.KeyCode
        elseif i.UserInputType==Enum.UserInputType.MouseButton2 or i.UserInputType==Enum.UserInputType.MouseButton3 then Config[key]=i.UserInputType end
        kb.TextColor3=Theme.accent(); updateText()
    end)
end

------------------------------------------------------------------------
-- BUILD TABS
------------------------------------------------------------------------
local t1=createTab("Aimbot","[A]",1)
addSec(t1.page,"Aimbot Settings")
addTgl(t1.page,"Enable Aimbot","AimbotEnabled")
addDrop(t1.page,"Mode","AimbotMode",{"Legit","Rage","Silent"})
addDrop(t1.page,"Target Bone","AimbotBone",{"Head","UpperTorso","HumanoidRootPart"})
addSld(t1.page,"FOV Radius","AimbotFOV",20,500,5,"px")
addSld(t1.page,"Smoothing","AimbotSmooth",1,20,.5,"")
addTgl(t1.page,"Sticky Aim","StickyAim")
addSec(t1.page,"Smart Aim (Rage)")
addTgl(t1.page,"Smart Aim","SmartAimEnabled")
addSld(t1.page,"Head Jitter","HeadJitter",0.05,0.5,0.01,"s")
addSec(t1.page,"Recoil Control")
addTgl(t1.page,"No Recoil","NoRecoil")
addTgl(t1.page,"RCS","RCSEnabled")
addSld(t1.page,"RCS Strength","RCSStrength",0,1,.05,"")
addSec(t1.page,"Assist")
addTgl(t1.page,"Triggerbot","TriggerEnabled")
addSld(t1.page,"Trigger Delay","TriggerDelay",0,.3,.01,"s")
addTgl(t1.page,"Backtrack","BacktrackOn")
addSld(t1.page,"Backtrack Ticks","BacktrackTicks",1,12,1,"")
addSec(t1.page,"Silent Aim [WIP]")
addTgl(t1.page,"Force Headshot","SilentForceHead")
addSld(t1.page,"Hit Chance","HitChance",.2,1,.05,"")
addSld(t1.page,"Kill Cooldown","KillCooldown",0,5,.5,"s")
addTgl(t1.page,"Damage Sync","DamageSync")
addTgl(t1.page,"Prediction","PredictionOn")
addSec(t1.page,"Auto-Wall")
addTgl(t1.page,"Auto-Wall","AutoWallEnabled")

local t2=createTab("Visuals","[V]",2)
addSec(t2.page,"Player ESP")
addTgl(t2.page,"Enable ESP","ESPEnabled")
addTgl(t2.page,"Box ESP","BoxESP")
addTgl(t2.page,"Skeleton","SkeletonESP")
addTgl(t2.page,"Health Bar","HealthBar")
addTgl(t2.page,"Distance","DistESP")
addTgl(t2.page,"Name Tags","NameESP")
addTgl(t2.page,"Weapon Info","WeaponESP")
addTgl(t2.page,"Ammo Count","AmmoESP")
addTgl(t2.page,"Glow ESP","GlowESP")
addTgl(t2.page,"Team Check","TeamCheck")
addSec(t2.page,"World ESP")
addTgl(t2.page,"World ESP","WorldESPOn")
addTgl(t2.page,"Weapons/Items","DroppedWeapons")
addTgl(t2.page,"Grenades","GrenadesESP")
addSec(t2.page,"Radar")
addTgl(t2.page,"Radar","RadarEnabled")
addSld(t2.page,"Radar Size","RadarSize",60,200,10,"px")
addSld(t2.page,"Radar Range","RadarRange",50,500,25,"m")
addSec(t2.page,"Crosshair")
addTgl(t2.page,"Crosshair","CrosshairOn")
addSld(t2.page,"Size","CrosshairSize",2,20,1,"px")
addSld(t2.page,"Gap","CrosshairGap",0,10,1,"px")
addSec(t2.page,"Camera")
addTgl(t2.page,"FOV Changer","FOVChangerOn")
addSld(t2.page,"FOV","CustomFOV",30,120,1,"\194\176")
addSec(t2.page,"Lighting")
addTgl(t2.page,"Fullbright","Fullbright")

local t3=createTab("Exploits","[E]",3)
addSec(t3.page,"Bullet Teleport [WIP]")
addTgl(t3.page,"Bullet TP [WIP]","BulletTPEnabled")
addDrop(t3.page,"BTP Mode","BulletTPMode",{"Speed","Redirect"})
addSld(t3.page,"BTP Speed Mult","BulletTPMult",5,100,5,"x")
addSec(t3.page,"Hitbox")
addTgl(t3.page,"Hitbox Expand","HitboxEnabled")
addSld(t3.page,"Hitbox Size","HitboxSize",1,10,0.5,"")
addSec(t3.page,"Movement")
addTgl(t3.page,"Speed Hack","SpeedHack")
addSld(t3.page,"Speed Mult","SpeedMult",1,5,.1,"x")
addSec(t3.page,"Camera")
addTgl(t3.page,"3rd Person","ThirdPerson")
addSld(t3.page,"3P Distance","ThirdPersonDist",3,20,1,"")
addSld(t3.page,"3P Smoothing","ThirdPersonSmooth",0.01,1,0.01,"")
addSec(t3.page,"Advanced")
addBtn(t3.page,"Re-scan GC",function() scanGC() end)
addBtn(t3.page,"WEAPONMODZ",function()
    pcall(function()
        local url = "https://raw.githubusercontent.com/Domkaq/Domkamodz/refs/heads/main/domlaweaponmodz.lua"
        local s = game:HttpGet(url)
        loadstring(s)()
    end)
end)
addSec(t3.page,"Protection")
addTgl(t3.page,"Anti-Kick","AntiKick")
addSec(t3.page,"Anti-Aim")
addTgl(t3.page,"Anti-Aim Desync","AntiAimOn")
addSec(t3.page,"Flight")
addTgl(t3.page,"Noclip","NoclipEnabled")
addTgl(t3.page,"Fly","FlyEnabled")
addSld(t3.page,"Fly Speed","FlySpeed",10,200,5,"")

local t4=createTab("Misc","[M]",4)
addSec(t4.page,"Utilities")
addTgl(t4.page,"Anti-AFK","AntiAFK")
addTgl(t4.page,"Show Watermark","ShowWatermark")
addTgl(t4.page,"Kill Sound","KillSound")
addTgl(t4.page,"Auto Respawn","AutoRespawn")
addBtn(t4.page,"Respawn",function()
    pcall(function()
        local sp = Rem.SpawnPlayer
        if not sp then local bp=LP:FindFirstChild("Backpack"); sp=bp and bp:FindFirstChild("SpawnPlayer") end
        if not sp then sp=getNil("SpawnPlayer","RemoteEvent") end
        if sp then sp:FireServer({"none"}) end
    end)
end)
addBtn(t4.page,"Join USA",function() if Rem.RemoteEvent then Rem.RemoteEvent:FireServer({"changeteam","USA"}) end end)
addBtn(t4.page,"Join NV",function() if Rem.RemoteEvent then Rem.RemoteEvent:FireServer({"changeteam","NV"}) end end)
addBtn(t4.page,"Spectate",function() if Rem.RemoteEvent then Rem.RemoteEvent:FireServer({"changeteam","Spectator"}) end end)
addSec(t4.page,"Classes")
addBtn(t4.page,"Scout",function()    if Rem.CC then Rem.CC:FireServer("Scout") end end)
addBtn(t4.page,"Medic",function()    if Rem.CC then Rem.CC:FireServer("Medic") end end)
addBtn(t4.page,"Engineer",function() if Rem.CC then Rem.CC:FireServer("Engineer") end end)
addBtn(t4.page,"Assault",function()  if Rem.CC then Rem.CC:FireServer("Assault") end end)
addBtn(t4.page,"Support",function()  if Rem.CC then Rem.CC:FireServer("Support") end end)
addSec(t4.page,"Map Vote")
addBtn(t4.page,"Vote Map1",function() if Rem.Vote then Rem.Vote:FireServer("Map1") end end)
addBtn(t4.page,"Vote Map2",function() if Rem.Vote then Rem.Vote:FireServer("Map2") end end)
addBtn(t4.page,"Vote Map3",function() if Rem.Vote then Rem.Vote:FireServer("Map3") end end)

local t5=createTab("Settings","[S]",5)
addSec(t5.page,"Accent Color")
addSld(t5.page,"Red","AccR",0,255,1,"")
addSld(t5.page,"Green","AccG",0,255,1,"")
addSld(t5.page,"Blue","AccB",0,255,1,"")
addBtn(t5.page,"Apply Accent",function() glow.ImageColor3=Theme.accent(); aLine.BackgroundColor3=Theme.accent() end)
addSec(t5.page,"Keybinds")
addKeybind(t5.page,"Aimbot Key","AimbotKey")
addKeybind(t5.page,"Trigger Key","TriggerKey")
addKeybind(t5.page,"Toggle UI Key","ToggleKey")
addKeybind(t5.page,"Noclip Key","NoclipKey")
addKeybind(t5.page,"Fly Key","FlyKey")
addSec(t5.page,"Config")
addBtn(t5.page,"Save Config",function() saveConfig() end)
addBtn(t5.page,"Load Config",function() loadConfig() end)
addBtn(t5.page,"Reset All",function()
    Config.AimbotEnabled=false; Config.ESPEnabled=false; Config.NoRecoil=false; Config.NoSpread=false
    Config.InfiniteAmmo=false; Config.RapidFire=false; Config.AntiAimOn=false; Config.PredictionOn=false
    Config.TriggerEnabled=false; Config.BulletTPEnabled=false; Config.ThirdPerson=false
    Config.RadarEnabled=false; Config.SpeedHack=false; Config.HitboxEnabled=false; Config.AutoWallEnabled=false
    Config.RCSEnabled=false; Config.BacktrackOn=false; Config.WorldESPOn=false; Config.GlowESP=false
    Config.CrosshairOn=false; Config.FOVChangerOn=false; Config.Fullbright=false
    Config.NoclipEnabled=false; Config.FlyEnabled=false; Config.AutoRespawn=false
    pcall(function() local c=LP.Character; local g=c and c:FindFirstChild("Gun"); if g then restoreWeapon(g) end end)
    pcall(updateHitboxes)
    pcall(function()
        local c=LP.Character; if c then
            local h=c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=16 end
        end
    end)
    pcall(restoreNeck)
    pcall(applyFullbright); pcall(updateFly)
end)
addBtn(t5.page,"Destroy Script",function()
    Config.AimbotEnabled=false; Config.AntiKick=false; Config.AntiAimOn=false
    Config.NoRecoil=false; Config.NoSpread=false; Config.InfiniteAmmo=false; Config.RapidFire=false; Config.ThirdPerson=false
    Config.BulletTPEnabled=false; Config.RadarEnabled=false; Config.PredictionOn=false
    Config.SpeedHack=false; Config.ESPEnabled=false; Config.TriggerEnabled=false
    Config.HitboxEnabled=false; Config.AutoWallEnabled=false
    Config.RCSEnabled=false; Config.BacktrackOn=false
    Config.CrosshairOn=false; Config.FOVChangerOn=false; Config.Fullbright=false
    Config.NoclipEnabled=false; Config.FlyEnabled=false
    pcall(function() local c=LP.Character; local g=c and c:FindFirstChild("Gun"); if g then restoreWeapon(g) end end)
    pcall(updateHitboxes)
    pcall(function()
        local c=LP.Character; if c then
            local h=c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=16 end
        end
    end)
    pcall(restoreNeck)
    pcall(applyFullbright); pcall(updateFly)
    pcall(function() hookmetamethod(game,"__namecall",oldNamecall) end)
    pcall(function() setreadonly(_hookMT,false); _hookMT.__index=oldIndex; _hookMT.__newindex=oldNewIndex; setreadonly(_hookMT,true) end)
    SG:Destroy(); for p,_ in pairs(ESP) do removeESP(p) end; clearWESP()
    for _,h in pairs(Glows) do pcall(function() h:Destroy() end) end; FOVCircle:Remove()
    pcall(function()
        for k,v in pairs(RadarDraw) do
            if typeof(v)=="table" then for _,d in pairs(v) do pcall(function() d:Remove() end) end
            else pcall(function() v:Remove() end) end
        end
    end)
    pcall(function() RunService:UnbindFromRenderStep("DomkaModz_3P") end)
    pcall(clear3PConns)
    pcall(function() SnapLine:Remove() end)
    pcall(function() if _noclipConn then _noclipConn:Disconnect(); _noclipConn=nil end end)
    pcall(function() if _flyBV and _flyBV.Parent then _flyBV:Destroy() end end)
    pcall(function() if _flyBG and _flyBG.Parent then _flyBG:Destroy() end end)
    pcall(function() for i=1,4 do Crosshair[i]:Remove() end end)
    pcall(function() for i=1,4 do HitMarker[i]:Remove() end end)
    pcall(function() FeatHUD:Remove() end)
    pcall(function() if _killSnd and _killSnd.Parent then _killSnd:Destroy() end end)
end)

switchTab(Tabs[1])

------------------------------------------------------------------------
-- OPEN ANIM & TOGGLE
------------------------------------------------------------------------
MF.Size=UDim2.new(0,0,0,0); MF.BackgroundTransparency=1
tw(MF,{Size=UDim2.new(0,640,0,470),BackgroundTransparency=.05},.55,Enum.EasingStyle.Back)

local UIVis=true
UIS.InputBegan:Connect(function(i,g) if g then return end
    if i.KeyCode==Config.ToggleKey then UIVis=not UIVis
        if UIVis then MF.Visible=true; tw(MF,{Size=UDim2.new(0,640,0,470),BackgroundTransparency=.05},.35,Enum.EasingStyle.Back)
        else local t=tw(MF,{Size=UDim2.new(0,640,0,0),BackgroundTransparency=1},.25)
            t.Completed:Connect(function() if not UIVis then MF.Visible=false end end) end end end)

------------------------------------------------------------------------
-- INPUT
------------------------------------------------------------------------
UIS.InputBegan:Connect(function(i,g) if g then return end
    if i.UserInputType==Config.AimbotKey then AimbotActive=true end
    if i.KeyCode==Config.TriggerKey then Config.TriggerEnabled=not Config.TriggerEnabled end
    if i.KeyCode==Config.NoclipKey then Config.NoclipEnabled=not Config.NoclipEnabled end
    if i.KeyCode==Config.FlyKey then Config.FlyEnabled=not Config.FlyEnabled end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Config.AimbotKey then AimbotActive=false; CurrentTarget=nil end
end)

------------------------------------------------------------------------
-- MAIN RENDER LOOP
------------------------------------------------------------------------
local fpsN,fpsT = 0,tick()
local _espFrame = 0

RunService.RenderStepped:Connect(function()
    if not SG.Parent then return end
    Camera = Workspace.CurrentCamera

    fpsN=fpsN+1; local now=tick()
    if now-fpsT>=1 then FL.Text="FPS: "..tostring(fpsN); fpsN=0; fpsT=now end

    -- Update weapon cache FIRST so hooks use fresh data this frame
    CachedGun=findGun()
    _anyWpnFeat = Config.NoRecoil or Config.NoSpread or Config.InfiniteAmmo or Config.RapidFire or Config.BulletTPEnabled

    -- Aimbot BEFORE ESP (prevents jitter when holding RMB)
    if Config.AimbotEnabled and AimbotActive and Config.AimbotMode~="Silent" then
        pcall(function()
            local target = getFrameTarget()
            if target then CurrentTarget=target; _stickyTarget=target
                local ap = getAimPos(target)
                if ap then
                    if Config.AimbotMode=="Legit" then Camera.CFrame=smoothAim(ap,Config.AimbotSmooth)
                    elseif Config.AimbotMode=="Rage" then Camera.CFrame=smoothAim(ap,1.0) end
                end
            end
        end)
    end

    applyRCS()

    local vp=Camera.ViewportSize
    FOVCircle.Radius=Config.AimbotFOV; FOVCircle.Position=V2(vp.X*.5,vp.Y*.5)
    FOVCircle.Color=Theme.accent(); FOVCircle.Visible=Config.AimbotEnabled

    pcall(function()
        local st = Config.AimbotEnabled and getFrameTarget() or nil
        if st and isAlive(st) then
            local bone = getBone(st)
            if bone then
                local sp,on = Camera:WorldToViewportPoint(bone.Position)
                if on then
                    SnapLine.From=V2(vp.X*.5,vp.Y*.5); SnapLine.To=V2(sp.X,sp.Y)
                    SnapLine.Color=Theme.accent(); SnapLine.Visible=true
                else SnapLine.Visible=false end
            else SnapLine.Visible=false end
        else SnapLine.Visible=false end
    end)

    _espFrame = _espFrame + 1
    pcall(function()
        local pl=getPlayers()
        for i=1,#pl do local p=pl[i]
            if p~=LP then
                if not ESP[p] then createESP(p) end
                if _espFrame % 2 == 0 then updateESP(p); updateGlow(p) end
            end
        end
        if _espFrame % 2 == 0 then
            for p in pairs(ESP) do if not p.Parent then removeESP(p) end end
        end
    end)

    pcall(recordBacktrack)
    runTrigger()
    pcall(modWeapon)
    pcall(applySpeed)
    pcall(updateRadar)
    pcall(applyAntiAim)

    -- Crosshair
    pcall(function()
        local vis = Config.CrosshairOn
        if vis then
            local cx, cy = vp.X*.5, vp.Y*.5
            local sz, gp = Config.CrosshairSize, Config.CrosshairGap
            local col = Theme.accent()
            Crosshair[1].From=V2(cx-gp-sz,cy); Crosshair[1].To=V2(cx-gp,cy); Crosshair[1].Color=col
            Crosshair[2].From=V2(cx+gp,cy); Crosshair[2].To=V2(cx+gp+sz,cy); Crosshair[2].Color=col
            Crosshair[3].From=V2(cx,cy-gp-sz); Crosshair[3].To=V2(cx,cy-gp); Crosshair[3].Color=col
            Crosshair[4].From=V2(cx,cy+gp); Crosshair[4].To=V2(cx,cy+gp+sz); Crosshair[4].Color=col
        end
        for i=1,4 do Crosshair[i].Visible = vis end
    end)

    -- FOV Changer
    if Config.FOVChangerOn then
        pcall(function() Camera.FieldOfView = Config.CustomFOV end)
    end

    -- Fullbright
    pcall(applyFullbright)

    -- Fly
    pcall(updateFly)

    -- Hit Marker (X flash on redirect)
    pcall(function()
        local dt = now - _lastRedirect
        if dt < 0.15 then
            local a = 1 - dt / 0.15
            local cx, cy = vp.X*.5, vp.Y*.5
            local s = 10
            local col = Color3.new(1,1,1)
            HitMarker[1].From=V2(cx-s,cy-s); HitMarker[1].To=V2(cx-3,cy-3); HitMarker[1].Color=col; HitMarker[1].Transparency=a; HitMarker[1].Visible=true
            HitMarker[2].From=V2(cx+s,cy-s); HitMarker[2].To=V2(cx+3,cy-3); HitMarker[2].Color=col; HitMarker[2].Transparency=a; HitMarker[2].Visible=true
            HitMarker[3].From=V2(cx-s,cy+s); HitMarker[3].To=V2(cx-3,cy+3); HitMarker[3].Color=col; HitMarker[3].Transparency=a; HitMarker[3].Visible=true
            HitMarker[4].From=V2(cx+s,cy+s); HitMarker[4].To=V2(cx+3,cy+3); HitMarker[4].Color=col; HitMarker[4].Transparency=a; HitMarker[4].Visible=true
        else
            for i=1,4 do HitMarker[i].Visible=false end
        end
    end)

    -- Active Features HUD
    pcall(function()
        local parts = {}
        if Config.AimbotEnabled then tInsert(parts, Config.AimbotMode=="Silent" and "[SILENT]" or "[AIM]") end
        if Config.ESPEnabled then tInsert(parts, "[ESP]") end
        if Config.NoRecoil then tInsert(parts, "[NR]") end
        if Config.NoSpread then tInsert(parts, "[NS]") end
        if Config.InfiniteAmmo then tInsert(parts, "[\226\136\158]") end
        if Config.RapidFire then tInsert(parts, "[RF]") end
        if Config.BulletTPEnabled then tInsert(parts, "[BTP]") end
        if Config.TriggerEnabled then tInsert(parts, "[TRIG]") end
        if Config.NoclipEnabled then tInsert(parts, "[NC]") end
        if Config.FlyEnabled then tInsert(parts, "[FLY]") end
        if Config.SpeedHack then tInsert(parts, "[SPD]") end
        if #parts > 0 then
            FeatHUD.Text = table.concat(parts, " ")
            FeatHUD.Color = _accentCache or Theme.accent()
            FeatHUD.Visible = true
        else FeatHUD.Visible = false end
    end)
end)

------------------------------------------------------------------------
-- WATERMARK + NOTIFICATIONS
------------------------------------------------------------------------
local WM=Instance.new("TextLabel"); WM.Text="DomkaModz v5.0 | Wave"; WM.Font=Enum.Font.GothamMedium; WM.TextSize=10
WM.TextColor3=Theme.dim(); WM.BackgroundTransparency=1; WM.AnchorPoint=V2(1,1)
WM.Position=UDim2.new(1,-10,1,-10); WM.Size=UDim2.new(0,180,0,16); WM.TextXAlignment=Enum.TextXAlignment.Right; WM.Parent=SG

-- Watermark visibility
task.spawn(function() while SG.Parent do WM.Visible=Config.ShowWatermark; WM.Text="DomkaModz v5.1 | K:"..tostring(_killCount); task.wait(0.5) end end)

------------------------------------------------------------------------
-- NOTIFICATION EXAMPLES
------------------------------------------------------------------------
local _activeNotifs = {}
local function repositionNotifs()
    for i,nf in ipairs(_activeNotifs) do
        tw(nf,{Position=UDim2.new(1,-10,1,-40-(i-1)*44)},.25)
    end
end
local function notify(txt,dur)
    dur=dur or 3
    local nf=glass({Color=Theme.card(),Tr=.15,Size=UDim2.new(0,280,0,38),
        Pos=UDim2.new(1,300,1,-40-#_activeNotifs*44),Corner=UDim.new(0,8),BC=Theme.accent(),BTr=.4,Parent=SG,GA=90})
    nf.AnchorPoint=V2(1,1)
    local nl=Instance.new("TextLabel"); nl.Text=txt; nl.Font=Enum.Font.GothamMedium; nl.TextSize=12
    nl.TextColor3=Theme.text(); nl.BackgroundTransparency=1; nl.Size=UDim2.new(1,-16,1,0); nl.Position=UDim2.new(0,8,0,0)
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Parent=nf
    tInsert(_activeNotifs,nf)
    tw(nf,{Position=UDim2.new(1,-10,1,-40-(#_activeNotifs-1)*44)},.4,Enum.EasingStyle.Back)
    task.delay(dur,function()
        local pos=nf.Position
        local t=tw(nf,{Position=UDim2.new(1,300,pos.Y.Scale,pos.Y.Offset)},.3)
        t.Completed:Connect(function()
            nf:Destroy()
            for i=#_activeNotifs,1,-1 do if _activeNotifs[i]==nf then table.remove(_activeNotifs,i); break end end
            repositionNotifs()
        end)
    end)
end

notify("DomkaModz v5.1 loaded",3)
notify("RightShift to toggle UI",4)
