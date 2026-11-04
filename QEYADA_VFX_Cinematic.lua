--=====================================================================
--  EL QEYADA  |  CINEMATIC VFX SHOW  --  v1.0  (NO HUB, NO MENU)
--  سكربت الـ VFX الكامل: عرض سينمائي طبقات على الشخصية
--  البيئة: مكعب خلفية كبير بسماء رمادية عادية (مش فضاء)
--
--  WHAT RUNS (auto, no UI):
--    [env ] 6-wall giant gray sky cube + fog + real clouds + overcast day
--    [cam ] local cinematic camera: orbit -> close -> shake -> pull back
--    [0-3 ] fade-in dust motes
--    [3-12] GATHER : 6 orbiting energy streaks + ground pulse rings
--    [12-20] RISE  : aura + upward sparks + limb trails + starter pillar
--    [20-21.5] BURST: flash + 3 shockwave rings + debris chunks + FOV punch
--    [21.5-32] PILLAR: huge beam pillar + crown rings + orbiting orbs
--    [32-37] FADE  : emissions stop, beams shrink, full restore
--
--  PERFORMANCE (roblox-vfx skill): rates <= 40/emitter, sizes <= 6 studs,
--  LightEmission glow, mobile auto-scale 0.45, one RenderStepped loop only.
--  CLEANUP: every one-shot part on Debris:AddItem; emitters stopped +
--  :Clear() before destroy; lighting/atmosphere/clouds/camera all restored;
--  stop anytime: getgenv().QEYADA_VFX_STOP()
--
--  VERIFIED HERE : luaparser syntax PASS, static call/property scan CLEAN,
--                  GitHub raw fetch with Roblox UA (byte-identical).
--  NOT RUN HERE  : live Play test (no Roblox Studio in this box) --
--                  test the loader line in game and judge the visuals.
--
--  Loader:
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/QEYADA_VFX_Cinematic.lua"))()
--=====================================================================

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Lighting       = game:GetService("Lighting")
local Debris         = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui        = game:GetService("CoreGui")

local PREFIX   = "QEYADA_VFX_"
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local function RATE(n)
    return IS_MOBILE and math.max(1, math.floor(n * 0.45)) or n
end

--[[ engine-shipped textures: always present, zero moderation risk ]]--
local TEX = {
    spark = "rbxasset://textures/particles/sparkles_main.dds",
    smoke = "rbxasset://textures/particles/smoke_main.dds",
    fire  = "rbxasset://textures/particles/fire_main.dds",
}
pcall(function()
    ContentProvider:PreloadAsync({ TEX.spark, TEX.smoke, TEX.fire })
end)

--[[ ---------------------------------------------------------------
     TOKEN + previous-run kill (re-running the loader never stacks)
---------------------------------------------------------------- ]]--
local genv = (typeof(getgenv) == "function" and getgenv()) or _G
pcall(function()
    if type(genv.QEYADA_VFX_STOP) == "function" then
        genv.QEYADA_VFX_STOP()
    end
end)

local myToken = {}
genv.QEYADA_VFX_TOKEN = myToken
local dead = false
local function alive()
    return (not dead) and genv.QEYADA_VFX_TOKEN == myToken
end

--[[ ------------------------- CHARACTER ------------------------------ ]]--
local player = Players.LocalPlayer
if not player then
    warn("[QEYADA VFX] no LocalPlayer - aborting")
    return
end
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart", 10)
if not hrp then
    warn("[QEYADA VFX] no HumanoidRootPart - aborting (spawn first, then run)")
    return
end
local humanoid = character:FindFirstChildOfClass("Humanoid")

--[[ ------------------------- SAVE STATE ----------------------------- ]]--
local saved = { lighting = {}, skies = {}, atmo = nil, clouds = nil, fx = {} }
local function saveState()
    pcall(function()
        saved.lighting = {
            Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
            FogColor = Lighting.FogColor, FogStart = Lighting.FogStart,
            FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
            ExposureCompensation = Lighting.ExposureCompensation,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        }
    end)
    pcall(function()
        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then
                sky.Parent = nil -- detach, restore re-parents
                saved.skies[#saved.skies + 1] = sky
            end
        end
    end)
    pcall(function()
        local a = Lighting:FindFirstChildOfClass("Atmosphere")
        if a then
            saved.atmo = { obj = a,
                Density = a.Density, Haze = a.Haze, Glare = a.Glare,
                Color = a.Color, Decay = a.Decay, Offset = a.Offset }
        end
    end)
    pcall(function()
        local terr = workspace:FindFirstChildOfClass("Terrain")
        local cl = terr and terr:FindFirstChildOfClass("Clouds")
        if cl then
            saved.clouds = { obj = cl,
                Cover = cl.Cover, Density = cl.Density,
                Color = cl.Color, Enabled = cl.Enabled }
        end
    end)
    pcall(function()
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") and fx.Name:sub(1, #PREFIX) ~= PREFIX then
                saved.fx[#saved.fx + 1] = { obj = fx, enabled = fx.Enabled }
                fx.Enabled = false -- our bloom/CC must read clean
            end
        end
    end)
end
saveState()

--[[ ------------------------- FX CONTAINERS -------------------------- ]]--
local cubeFolder = Instance.new("Folder")
cubeFolder.Name = PREFIX .. "ENV"
cubeFolder.Parent = workspace

local fx = Instance.new("Folder")
fx.Name = PREFIX .. "FX"
fx.Parent = workspace

local ourBloom = Instance.new("BloomEffect")
ourBloom.Name = PREFIX .. "Bloom"
ourBloom.Intensity = 0.4
ourBloom.Size = 32
ourBloom.Threshold = 1.05
ourBloom.Parent = Lighting

local ourCC = Instance.new("ColorCorrectionEffect")
ourCC.Name = PREFIX .. "CC"
ourCC.Brightness = 0
ourCC.Contrast = 0.06
ourCC.Saturation = 0.02
ourCC.TintColor = Color3.fromRGB(255, 251, 242)
ourCC.Parent = Lighting

--[[ ================================================================
     1) ENVIRONMENT -- giant cube with a NORMAL GRAY SKY (not space)
     6 thin walls (2400 studs). From inside you always see the near
     face, so the gray wraps the whole view. Fog + atmosphere blend
     the walls into one seamless overcast sky gradient.
================================================================ ]]--
local WALL = 2400
local GRAY = {
    side = Color3.fromRGB(168, 174, 184),
    top  = Color3.fromRGB(196, 200, 208),
    bottom = Color3.fromRGB(122, 126, 134),
}
local skyWalls = {}
local function buildSkyCube(center)
    local specs = {
        { off = Vector3.new(0, 0, -WALL / 2), size = Vector3.new(WALL, WALL, 4), c = GRAY.side },
        { off = Vector3.new(0, 0,  WALL / 2), size = Vector3.new(WALL, WALL, 4), c = GRAY.side },
        { off = Vector3.new(-WALL / 2, 0, 0), size = Vector3.new(4, WALL, WALL), c = GRAY.side },
        { off = Vector3.new( WALL / 2, 0, 0), size = Vector3.new(4, WALL, WALL), c = GRAY.side },
        { off = Vector3.new(0, WALL / 2, 0),  size = Vector3.new(WALL, 4, WALL), c = GRAY.top },
        { off = Vector3.new(0, -WALL / 2, 0), size = Vector3.new(WALL, 4, WALL), c = GRAY.bottom },
    }
    for i, s in ipairs(specs) do
        local w = Instance.new("Part")
        w.Name = PREFIX .. "Wall" .. i
        w.Size = s.size
        w.CFrame = CFrame.new(center + s.off)
        w.Anchored = true
        w.CanCollide = false
        w.CanQuery = false
        w.CanTouch = false
        w.CastShadow = false
        w.Material = Enum.Material.SmoothPlastic
        w.Color = s.c
        w.Parent = cubeFolder
        skyWalls[i] = w
    end
end

local ourAtmo = nil
local ourCloudsNew = nil
local function applyOvercastLighting()
    pcall(function()
        Lighting.ClockTime = 13.4
        Lighting.Brightness = 2.4
        Lighting.Ambient = Color3.fromRGB(110, 112, 118)
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 152, 158)
        Lighting.FogColor = Color3.fromRGB(196, 200, 208)
        Lighting.FogStart = 60
        Lighting.FogEnd = 950
        Lighting.GlobalShadows = true
        Lighting.ExposureCompensation = 0.05
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    end)
    pcall(function()
        local a = Lighting:FindFirstChildOfClass("Atmosphere")
        if a and not saved.atmo then
            ourAtmo = a -- ours to destroy later
        elseif a then
            a.Density, a.Haze, a.Glare = 0.34, 2.2, 0.05
            a.Color, a.Decay = Color3.fromRGB(203, 208, 216), Color3.fromRGB(128, 134, 146)
        else
            ourAtmo = Instance.new("Atmosphere")
            ourAtmo.Name = PREFIX .. "Atmo"
            ourAtmo.Density = 0.34
            ourAtmo.Haze = 2.2
            ourAtmo.Glare = 0.05
            ourAtmo.Offset = 0.6
            ourAtmo.Color = Color3.fromRGB(203, 208, 216)
            ourAtmo.Decay = Color3.fromRGB(128, 134, 146)
            ourAtmo.Parent = Lighting
        end
    end)
    pcall(function()
        local terr = workspace:FindFirstChildOfClass("Terrain")
        if terr then
            local cl = terr:FindFirstChildOfClass("Clouds")
            if not cl then
                cl = Instance.new("Clouds")
                cl.Name = PREFIX .. "Clouds"
                cl.Parent = terr
                ourCloudsNew = cl
            end
            cl.Enabled = true
            cl.Cover = 0.65
            cl.Density = 0.5
            cl.Color = Color3.fromRGB(240, 242, 246)
        end
    end)
end

-- keep the cube centered on the player so the sky can never be escaped
task.spawn(function()
    while alive() do
        pcall(function()
            if hrp.Parent then
                local p = hrp.Position
                local center = Vector3.new(p.X, p.Y + WALL / 2 - 40, p.Z)
                for _, w in ipairs(skyWalls) do
                    if w and w.Parent then
                        -- walls keep their offsets relative to the new center
                        local rel = w:GetAttribute("Rel")
                        if rel then
                            w.CFrame = CFrame.new(center + rel)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

--[[ ================================================================
     2) HELPERS -- sequences, emitters, one-shot pieces
================================================================ ]]--
local function kps(list)
    local pts = {}
    for i, v in ipairs(list) do
        pts[i] = NumberSequenceKeypoint.new(v[1], v[2], v[3] or 0)
    end
    return NumberSequence.new(pts)
end

local function cseq(c0, c1)
    return ColorSequence.new(c0, c1)
end

local function makeHost(pos)
    local h = Instance.new("Part")
    h.Size = Vector3.new(0.4, 0.4, 0.4)
    h.Transparency = 1
    h.Anchored = true
    h.CanCollide = false
    h.CanQuery = false
    h.CanTouch = false
    h.CastShadow = false
    h.CFrame = CFrame.new(pos)
    h.Parent = fx
    return h
end

local function makeEmitter(host, cfg)
    local e = Instance.new("ParticleEmitter")
    e.Name = cfg.name or "FX"
    e.Texture = cfg.tex or TEX.spark
    e.Rate = RATE(cfg.rate or 10)
    e.Lifetime = NumberRange.new(cfg.life[1], cfg.life[2])
    e.Speed = NumberRange.new(cfg.speed[1], cfg.speed[2])
    e.Size = cfg.size
    e.Transparency = cfg.transparency
    e.Color = cfg.color or cseq(Color3.fromRGB(255, 250, 240), Color3.fromRGB(255, 220, 170))
    e.LightEmission = cfg.glow ~= nil and cfg.glow or 0.85
    e.LightInfluence = cfg.influence or 0
    e.SpreadAngle = cfg.spread or Vector2.new(10, 10)
    e.Rotation = NumberRange.new(0, 360)
    e.RotSpeed = NumberRange.new(-45, 45)
    e.Acceleration = cfg.accel or Vector3.new(0, 0, 0)
    e.Drag = cfg.drag or 0
    e.EmissionDirection = cfg.dir or Enum.NormalId.Top
    e.ZOffset = cfg.zoff or 0
    e.Parent = host
    return e
end

local function groundPoint(near)
    local origin = Vector3.new(near.X, near.Y + 2, near.Z)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = { character, fx, cubeFolder }
    local hit = workspace:Raycast(origin, Vector3.new(0, -300, 0), rp)
    if hit then
        return hit.Position
    end
    return Vector3.new(near.X, near.Y - 3, near.Z)
end

-- one-shot expanding ground ring (cylinder axis -> vertical)
local function spawnRing(pos, baseD, maxD, dur, color, thickness)
    local p = Instance.new("Part")
    p.Shape = Enum.PartType.Cylinder
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Size = Vector3.new(thickness or 0.5, baseD, baseD)
    p.CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = false
    p.Transparency = 0.12
    p.Parent = fx
    Debris:AddItem(p, dur + 0.2)
    TweenService:Create(p,
        TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = Vector3.new(thickness or 0.5, maxD, maxD), Transparency = 1 }):Play()
end

-- one-shot physics debris chunks (skill rule: Debris cleanup, no collision)
local function spawnDebrisBurst(pos)
    local n = IS_MOBILE and 6 or 14
    for i = 1, n do
        if not alive() then break end
        local p = Instance.new("Part")
        local s = 0.6 + math.random() * 0.9
        p.Size = Vector3.new(s, s * 0.7, s)
        p.Material = Enum.Material.Slate
        p.Color = Color3.fromRGB(118, 120, 126)
        p.Transparency = 0
        p.Anchored = false
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        local ang = (i / n) * math.pi * 2 + math.random() * 0.4
        local rad = 1.5 + math.random() * 3
        p.CFrame = CFrame.new(pos + Vector3.new(math.cos(ang) * rad, 0.6, math.sin(ang) * rad))
            * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)
        local power = 26 + math.random() * 26
        p.AssemblyLinearVelocity = Vector3.new(
            math.cos(ang) * power * 0.55,
            power,
            math.sin(ang) * power * 0.55)
        p.AssemblyAngularVelocity = Vector3.new(
            (math.random() - 0.5) * 14, (math.random() - 0.5) * 14, (math.random() - 0.5) * 14)
        p.Parent = fx
        Debris:AddItem(p, 2.4)
    end
end

-- one-shot flash ball + light
local function spawnFlash(pos)
    local b = Instance.new("Part")
    b.Shape = Enum.PartType.Ball
    b.Material = Enum.Material.Neon
    b.Color = Color3.fromRGB(255, 252, 244)
    b.Size = Vector3.new(12, 12, 12)
    b.CFrame = CFrame.new(pos)
    b.Anchored = true
    b.CanCollide = false
    b.CanQuery = false
    b.CanTouch = false
    b.CastShadow = false
    b.Transparency = 0.05
    b.Parent = fx
    local l = Instance.new("PointLight")
    l.Brightness = 9
    l.Range = 70
    l.Color = Color3.fromRGB(255, 246, 224)
    l.Parent = b
    Debris:AddItem(b, 0.95)
    TweenService:Create(b,
        TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(90, 90, 90), Transparency = 1 }):Play()
    TweenService:Create(l, TweenInfo.new(0.8), { Brightness = 0, Range = 20 }):Play()
end

--[[ ================================================================
     3) CAMERA -- local cinematic only (prompt rule #19)
================================================================ ]]--
local cam = workspace.CurrentCamera
local savedCam = {
    Type = cam.CameraType, Subject = cam.CameraSubject,
    FOV = cam.FieldOfView, CFrame = cam.CFrame,
}
cam.CameraType = Enum.CameraType.Scriptable

local shakeAmp = 0
local function smooth(a, b, u)
    return a + (b - a) * (1 - (1 - u) * (1 - u))
end
local function remap(t, a, b)
    return math.clamp((t - a) / (b - a), 0, 1)
end

-- piecewise cinematic pose from show-time t
local function camPose(t, center)
    local ang, rad, h, lookH, fov
    if t < 3 then
        local u = remap(t, 0, 3)
        ang = -0.6 + t * 0.15
        rad = smooth(26, 18, u)
        h = smooth(9, 7, u)
        lookH, fov = 2.0, smooth(64, 70, u)
    elseif t < 12 then
        local u = remap(t, 3, 12)
        ang = -0.15 + (t - 3) * 0.28
        rad = smooth(18, 11.5, u)
        h = smooth(7, 6.2, u)
        lookH, fov = 2.2, smooth(70, 73, u)
    elseif t < 20 then
        ang = 2.37 + (t - 12) * 0.4
        rad = 9.5
        h = 4.8
        lookH, fov = 2.6, 70 -- steady close orbit
    elseif t < 21.5 then
        ang = 5.57 + (t - 20) * 0.5
        rad = 7.6
        h = 4.0
        lookH, fov = 3.0, 62 -- burst tight punch
    elseif t < 32 then
        local u = remap(t, 21.5, 32)
        ang = 6.32 + (t - 21.5) * 0.22
        rad = smooth(7.6, 24, u)
        h = smooth(4.0, 11, u)
        lookH = smooth(3.0, 20, u)
        fov = smooth(62, 80, u)
    else
        local u = remap(t, 32, 37)
        ang = 8.52 + (t - 32) * 0.1
        rad = smooth(24, 30, u)
        h = smooth(11, 12, u)
        lookH = smooth(20, 3, u)
        fov = smooth(80, 70, u)
    end
    local look = center + Vector3.new(0, lookH, 0)
    local eye = look + Vector3.new(math.cos(ang) * rad, h, math.sin(ang) * rad)
    local cf = CFrame.lookAt(eye, look)
    if shakeAmp > 0.002 then
        local o = Vector3.new(
            (math.random() - 0.5), (math.random() - 0.5), (math.random() - 0.5)) * shakeAmp
        cf = cf + o
    end
    return cf, fov
end

--[[ ================================================================
     4) THE SHOW
================================================================ ]]--
local t0 = os.clock()
local heartbeat = nil
local orbits = {}
local crownParts = {}
local crownOrbs = {}
local emitters = {}   -- everything continuous, stopped + cleared at cleanup
local beams = {}      -- width-tweened at fade
local pillarHost, pillarAtt0, pillarAtt1
local crownHost
local centerAtt

local function trackEmitter(e) emitters[#emitters + 1] = e return e end
local function trackBeam(b) beams[#beams + 1] = b return b end

local function buildDust()
    local g = groundPoint(hrp.Position)
    local host = makeHost(g + Vector3.new(0, 1.2, 0))
    local e = makeEmitter(host, {
        name = "Dust", tex = TEX.smoke, rate = 10,
        life = { 4.5, 7 }, speed = { 0.8, 1.8 },
        size = kps({ { 0, 2.0 }, { 1, 4.2 } }),
        transparency = kps({ { 0, 1 }, { 0.25, 0.62 }, { 1, 1 } }),
        color = cseq(Color3.fromRGB(210, 212, 218), Color3.fromRGB(190, 192, 200)),
        glow = 0, influence = 0.55, spread = Vector2.new(18, 18), zoff = 2,
    })
    trackEmitter(e)
end

local function buildOrbits()
    centerAtt = Instance.new("Attachment")
    centerAtt.Name = PREFIX .. "Center"
    centerAtt.Parent = hrp
    local n = 6
    for i = 1, n do
        local host = makeHost(hrp.Position + Vector3.new(0, 1.5 + i * 0.35, 0))
        local att = Instance.new("Attachment")
        att.Parent = host
        local col = Color3.fromRGB(255, 244, 214)
        if i % 2 == 0 then
            col = Color3.fromRGB(255, 214, 150)
        end
        local e = makeEmitter(host, {
            name = "OrbitSpark", tex = TEX.spark, rate = 18,
            life = { 0.5, 1.0 }, speed = { 0.5, 1.6 },
            size = kps({ { 0, 0.5 }, { 0.5, 1.1 }, { 1, 0.2 } }),
            transparency = kps({ { 0, 0.15 }, { 1, 1 } }),
            color = cseq(col, col), glow = 1, spread = Vector2.new(180, 20),
        })
        trackEmitter(e)
        local beam = Instance.new("Beam")
        beam.Name = PREFIX .. "Streak"
        beam.Attachment0 = att
        beam.Attachment1 = centerAtt
        beam.Texture = TEX.spark
        beam.TextureMode = Enum.TextureMode.Stretch
        beam.TextureLength = 4
        beam.TextureSpeed = 5
        beam.Color = cseq(col, Color3.fromRGB(255, 255, 255))
        beam.Transparency = kps({ { 0, 0.35 }, { 1, 0.9 } })
        beam.Width0 = 0.22
        beam.Width1 = 0.05
        beam.LightEmission = 1
        beam.LightInfluence = 0
        beam.FaceCamera = true
        beam.Segments = 6
        beam.Parent = host
        trackBeam(beam)
        orbits[i] = { host = host, att = att, off = 1.5 + i * 0.35,
            speed = 1.6 + i * 0.12, ph = (i / n) * math.pi * 2, rad = 7 }
    end
end

local function buildRise(g)
    -- aura on the character
    local auraAtt = Instance.new("Attachment")
    auraAtt.Name = PREFIX .. "Aura"
    auraAtt.Parent = hrp
    local aura = makeEmitter(auraAtt, {
        name = "Aura", tex = TEX.fire, rate = 26,
        life = { 0.8, 1.5 }, speed = { 2.5, 5 },
        size = kps({ { 0, 1.0 }, { 0.4, 2.2 }, { 1, 0.3 } }),
        transparency = kps({ { 0, 0.35 }, { 1, 1 } }),
        color = cseq(Color3.fromRGB(255, 248, 228), Color3.fromRGB(255, 196, 120)),
        glow = 1, spread = Vector2.new(26, 26), accel = Vector3.new(0, 4, 0),
    })
    trackEmitter(aura)
    -- upward sparks from the ground
    local host = makeHost(g + Vector3.new(0, 0.6, 0))
    local sparks = makeEmitter(host, {
        name = "Sparks", tex = TEX.spark, rate = 14,
        life = { 0.9, 1.6 }, speed = { 8, 14 },
        size = kps({ { 0, 0.45 }, { 0.3, 0.9 }, { 1, 0.1 } }),
        transparency = kps({ { 0, 0.1 }, { 1, 1 } }),
        color = cseq(Color3.fromRGB(255, 240, 200), Color3.fromRGB(255, 180, 100)),
        glow = 1, spread = Vector2.new(14, 14), accel = Vector3.new(0, -16, 0), drag = 1.2,
    })
    trackEmitter(sparks)
    -- limb trails (R15 hands/feet, R6 arms/legs)
    local wanted = { "LeftHand", "RightHand", "LeftFoot", "RightFoot",
        "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
    local used = 0
    for _, name in ipairs(wanted) do
        if used >= 4 then break end
        local limb = character:FindFirstChild(name)
        if limb and limb:IsA("BasePart") then
            local a0 = Instance.new("Attachment")
            a0.Position = Vector3.new(0, 0.35, 0)
            a0.Parent = limb
            local a1 = Instance.new("Attachment")
            a1.Position = Vector3.new(0, -0.35, 0)
            a1.Parent = limb
            local tr = Instance.new("Trail")
            tr.Name = PREFIX .. "Trail"
            tr.Attachment0 = a0
            tr.Attachment1 = a1
            tr.Color = cseq(Color3.fromRGB(255, 250, 235), Color3.fromRGB(255, 205, 130))
            tr.Transparency = kps({ { 0, 0.25 }, { 1, 1 } })
            tr.WidthScale = kps({ { 0, 1 }, { 1, 0.1 } })
            tr.Lifetime = 0.35
            tr.LightEmission = 0.8
            tr.FaceCamera = true
            tr.MinLength = 0.05
            tr.Parent = limb
            used = used + 1
        end
    end
    -- starter pillar (thin)
    pillarHost = makeHost(g)
    pillarAtt0 = Instance.new("Attachment")
    pillarAtt0.Parent = pillarHost
    pillarAtt1 = Instance.new("Attachment")
    pillarAtt1.Position = Vector3.new(0, 60, 0)
    pillarAtt1.Parent = pillarHost
    local sp = Instance.new("Beam")
    sp.Name = PREFIX .. "PillarSeed"
    sp.Attachment0 = pillarAtt0
    sp.Attachment1 = pillarAtt1
    sp.Texture = TEX.fire
    sp.TextureMode = Enum.TextureMode.Stretch
    sp.TextureLength = 8
    sp.TextureSpeed = 3
    sp.Color = cseq(Color3.fromRGB(255, 250, 235), Color3.fromRGB(255, 210, 150))
    sp.Transparency = kps({ { 0, 0.2 }, { 1, 0.75 } })
    sp.Width0 = 1.2
    sp.Width1 = 2.5
    sp.LightEmission = 1
    sp.FaceCamera = true
    sp.Parent = pillarHost
    trackBeam(sp)
end

local function growPillar()
    if not (pillarAtt1 and pillarAtt1.Parent) then return end
    TweenService:Create(pillarAtt1, TweenInfo.new(1.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Position = Vector3.new(0, 140, 0) }):Play()
    -- core + glow re-width handled by swapping properties on the seed beam
    local core = beams[#beams]
    if core then
        core.Width0 = 5.5
        core.Width1 = 3.0
        core.Transparency = kps({ { 0, 0.1 }, { 0.5, 0.28 }, { 1, 0.85 } })
        core.TextureSpeed = 4.5
    end
    local glow = Instance.new("Beam")
    glow.Name = PREFIX .. "PillarGlow"
    glow.Attachment0 = pillarAtt0
    glow.Attachment1 = pillarAtt1
    glow.Texture = TEX.smoke
    glow.TextureMode = Enum.TextureMode.Stretch
    glow.TextureLength = 12
    glow.TextureSpeed = 2
    glow.Color = cseq(Color3.fromRGB(255, 226, 170), Color3.fromRGB(255, 190, 120))
    glow.Transparency = kps({ { 0, 0.55 }, { 1, 1 } })
    glow.Width0 = 11
    glow.Width1 = 6
    glow.LightEmission = 1
    glow.FaceCamera = true
    glow.ZOffset = 1
    glow.Parent = pillarHost
    trackBeam(glow)
end

local function buildCrown()
    crownHost = makeHost(hrp.Position + Vector3.new(0, 24, 0))
    local defs = {
        { d = 10,   tilt = 8,  col = Color3.fromRGB(255, 232, 180) },
        { d = 13.5, tilt = -6, col = Color3.fromRGB(255, 210, 140) },
    }
    for i, def in ipairs(defs) do
        local r = Instance.new("Part")
        r.Shape = Enum.PartType.Cylinder
        r.Material = Enum.Material.Neon
        r.Color = def.col
        r.Size = Vector3.new(0.35, def.d, def.d)
        r.Anchored = true
        r.CanCollide = false
        r.CanQuery = false
        r.CanTouch = false
        r.CastShadow = false
        r.Transparency = 0.25
        r.Parent = fx
        crownParts[i] = { part = r, tilt = def.tilt, h = 24 + (i - 1) * 2.5, ph = i * 1.7 }
        local att = Instance.new("Attachment")
        att.Parent = r
        local e = makeEmitter(att, {
            name = "CrownSheen", tex = TEX.spark, rate = 8,
            life = { 0.4, 0.9 }, speed = { 0.3, 1.0 },
            size = kps({ { 0, 0.4 }, { 1, 0.1 } }),
            transparency = kps({ { 0, 0.2 }, { 1, 1 } }),
            color = cseq(def.col, def.col), glow = 1, spread = Vector2.new(180, 180),
        })
        trackEmitter(e)
    end
    for i = 1, 3 do
        local orb = Instance.new("Part")
        orb.Shape = Enum.PartType.Ball
        orb.Material = Enum.Material.Neon
        orb.Color = Color3.fromRGB(255, 224, 160)
        orb.Size = Vector3.new(0.9, 0.9, 0.9)
        orb.Anchored = true
        orb.CanCollide = false
        orb.CanQuery = false
        orb.CanTouch = false
        orb.CastShadow = false
        orb.Parent = fx
        local att = Instance.new("Attachment")
        att.Parent = orb
        local e = makeEmitter(att, {
            name = "OrbTrail", tex = TEX.spark, rate = 6,
            life = { 0.3, 0.7 }, speed = { 0.2, 0.8 },
            size = kps({ { 0, 0.35 }, { 1, 0.05 } }),
            transparency = kps({ { 0, 0.2 }, { 1, 1 } }),
            color = cseq(Color3.fromRGB(255, 220, 150), Color3.fromRGB(255, 180, 90)),
            glow = 1, spread = Vector2.new(180, 180),
        })
        trackEmitter(e)
        crownOrbs[i] = { part = orb, speed = 1.1 + i * 0.35,
            ph = (i / 3) * math.pi * 2, rad = 6 + i * 0.8, h = 24 + i * 1.2 }
    end
end

local function fireBurst(g)
    spawnFlash(g + Vector3.new(0, 3, 0))
    spawnRing(g, 8, 90, 0.9, Color3.fromRGB(255, 250, 238), 0.8)
    spawnRing(g, 8, 124, 1.15, Color3.fromRGB(255, 216, 150), 0.6)
    spawnRing(g, 8, 156, 1.4, Color3.fromRGB(210, 212, 218), 0.45)
    spawnDebrisBurst(g)
    pcall(function()
        TweenService:Create(ourBloom, TweenInfo.new(0.08), { Intensity = 2.4 }):Play()
        task.delay(0.12, function()
            if alive() then
                TweenService:Create(ourBloom, TweenInfo.new(1.6), { Intensity = 1.0 }):Play()
            end
        end)
        ourCC.Brightness = 0.15
        TweenService:Create(ourCC, TweenInfo.new(0.8), { Brightness = 0 }):Play()
    end)
    shakeAmp = 1.5
end

local function groundPulses()
    task.spawn(function()
        for i = 1, 9 do
            if not alive() then break end
            local g = groundPoint(hrp.Position)
            local col = (i % 2 == 0)
                and Color3.fromRGB(255, 232, 185)
                or Color3.fromRGB(235, 237, 242)
            spawnRing(g, 6, 26, 1.2, col, 0.4)
            task.wait(1.05)
        end
    end)
end

--[[ --------------------- RUN loop (single thread) -------------------- ]]--
local function startHeartbeat()
    heartbeat = RunService.RenderStepped:Connect(function(dt)
        if not alive() or not hrp.Parent then return end
        local t = os.clock() - t0
        local center = hrp.Position + Vector3.new(0, 2.5, 0)
        -- orbit anchors
        for _, o in ipairs(orbits) do
            local a = t * o.speed + o.ph
            o.host.CFrame = CFrame.new(center
                + Vector3.new(math.cos(a) * o.rad, o.off - 2.5, math.sin(a) * o.rad))
        end
        -- crown precession + orbs
        for _, c in ipairs(crownParts) do
            if c.part and c.part.Parent then
                local a = t * 0.7 + c.ph
                local wob = math.rad(c.tilt) + math.sin(t * 0.9 + c.ph) * 0.12
                c.part.CFrame = CFrame.new(center + Vector3.new(0, c.h, 0))
                    * CFrame.Angles(0, 0, math.rad(90))
                    * CFrame.Angles(wob, a, 0)
            end
        end
        for _, o in ipairs(crownOrbs) do
            if o.part and o.part.Parent then
                local a = t * o.speed + o.ph
                o.part.CFrame = CFrame.new(center
                    + Vector3.new(math.cos(a) * o.rad, o.h - 2.5, math.sin(a) * o.rad))
            end
        end
        -- pillar follows the player
        if pillarHost and pillarHost.Parent then
            local g = groundPoint(hrp.Position)
            pillarHost.CFrame = CFrame.new(g)
        end
        -- bloom heartbeat during pillar phase
        if t > 21.5 and t < 32 then
            ourBloom.Intensity = 0.95 + math.sin(t * 4) * 0.22
        end
        -- shake decay
        if shakeAmp > 0.002 then
            shakeAmp = shakeAmp * math.pow(0.05, dt)
        end
        -- camera pose
        local cf, fov = camPose(t, center)
        cam.CFrame = cf
        cam.FieldOfView = fov
    end)
end

local function timeline()
    task.spawn(function()
        local g = groundPoint(hrp.Position)
        buildDust()
        task.wait(3)
        if not alive() then return end
        buildOrbits()
        groundPulses()
        task.wait(9) -- t=12
        if not alive() then return end
        buildRise(groundPoint(hrp.Position))
        task.wait(8) -- t=20
        if not alive() then return end
        fireBurst(groundPoint(hrp.Position))
        task.wait(1.5) -- t=21.5
        if not alive() then return end
        growPillar()
        buildCrown()
        task.wait(10.5) -- t=32
        if not alive() then return end
        -- FADE: stop emission, shrink beams, restore look
        for _, e in ipairs(emitters) do
            pcall(function()
                e.Rate = 0 -- no new particles; live ones finish naturally
            end)
        end
        for _, b in ipairs(beams) do
            pcall(function()
                -- NumberSequence is NOT tweenable: set it directly, tween widths only
                b.Transparency = kps({ { 0, 0.2 }, { 1, 1 } })
                TweenService:Create(b, TweenInfo.new(2.5),
                    { Width0 = 0.01, Width1 = 0.01 }):Play()
            end)
        end
        for _, c in ipairs(crownParts) do
            pcall(function()
                TweenService:Create(c.part, TweenInfo.new(2.2), { Transparency = 1 }):Play()
            end)
        end
        for _, o in ipairs(crownOrbs) do
            pcall(function()
                TweenService:Create(o.part, TweenInfo.new(2.0), { Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1 }):Play()
            end)
        end
        pcall(function()
            TweenService:Create(ourBloom, TweenInfo.new(2.5), { Intensity = 0 }):Play()
        end)
        task.wait(4) -- t=36
        if not alive() then return end
        shutdown()
    end)
end

--[[ ------------------------- CLEANUP / STOP -------------------------- ]]--
function shutdown()
    if dead then return end
    dead = true
    -- stop + clear emitters first (skill: no orphaned particles)
    for _, e in ipairs(emitters) do
        pcall(function()
            e.Enabled = false
            e:Clear()
        end)
    end
    if heartbeat then
        pcall(function() heartbeat:Disconnect() end)
        heartbeat = nil
    end
    pcall(function() fx:Destroy() end)
    pcall(function() cubeFolder:Destroy() end)
    -- restore post effects + lighting + sky + atmosphere + clouds
    pcall(function()
        for _, f in ipairs(saved.fx) do
            if f.obj then f.obj.Enabled = f.enabled end
        end
    end)
    pcall(function()
        for k, v in pairs(saved.lighting) do
            Lighting[k] = v
        end
    end)
    pcall(function()
        for _, sky in ipairs(saved.skies) do
            if sky and sky.Parent == nil then sky.Parent = Lighting end
        end
    end)
    pcall(function()
        if saved.atmo and saved.atmo.obj then
            local a = saved.atmo.obj
            a.Density, a.Haze, a.Glare = saved.atmo.Density, saved.atmo.Haze, saved.atmo.Glare
            a.Color, a.Decay = saved.atmo.Color, saved.atmo.Decay
        end
    end)
    pcall(function()
        if ourAtmo and ourAtmo.Parent then ourAtmo:Destroy() end
        if ourCloudsNew and ourCloudsNew.Parent then ourCloudsNew:Destroy() end
    end)
    pcall(function()
        if saved.clouds and saved.clouds.obj then
            local cl = saved.clouds.obj
            cl.Cover, cl.Density, cl.Color, cl.Enabled =
                saved.clouds.Cover, saved.clouds.Density, saved.clouds.Color, saved.clouds.Enabled
        end
    end)
    pcall(function()
        ourBloom:Destroy()
        ourCC:Destroy()
    end)
    -- camera back
    pcall(function()
        cam.CFrame = savedCam.CFrame
        cam.FieldOfView = savedCam.FOV
        cam.CameraSubject = savedCam.Subject
        cam.CameraType = savedCam.Type
    end)
    pcall(function()
        local t = CoreGui:FindFirstChild(PREFIX .. "Toast")
        if t then t:Destroy() end
    end)
    genv.QEYADA_VFX_TOKEN = nil
    genv.QEYADA_VFX_STOP = nil
    print("[QEYADA VFX] show finished / stopped - environment restored, 0 leftovers")
end
genv.QEYADA_VFX_STOP = shutdown

-- death / respawn guard: never leave a broken scene behind
if humanoid then
    humanoid.Died:Connect(function()
        task.delay(1.0, function()
            if alive() then shutdown() end
        end)
    end)
end
character.AncestryChanged:Connect(function()
    if not character:IsDescendantOf(workspace) and alive() then
        shutdown()
    end
end)

--[[ ---------------------------- TOAST -------------------------------- ]]--
local function toast()
    local gui = Instance.new("ScreenGui")
    gui.Name = PREFIX .. "Toast"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok or not gui.Parent then
        local pg = player:FindFirstChildOfClass("PlayerGui")
        if pg then gui.Parent = pg end
    end
    local tl = Instance.new("TextLabel")
    tl.AnchorPoint = Vector2.new(0.5, 0)
    tl.Position = UDim2.new(0.5, 0, 0, 22)
    tl.Size = UDim2.new(0, 380, 0, 34)
    tl.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    tl.BackgroundTransparency = 0.2
    tl.Text = "EL QEYADA | VFX السينمائي اشتغل -- السماء الرمادية جاهزة"
    tl.TextColor3 = Color3.fromRGB(235, 235, 240)
    tl.Font = Enum.Font.GothamMedium
    tl.TextSize = 15
    tl.BorderSizePixel = 0
    tl.Parent = gui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = tl
    task.delay(4.0, function()
        pcall(function()
            local tw = TweenService:Create(tl,
                TweenInfo.new(0.6), { BackgroundTransparency = 1, TextTransparency = 1 })
            tw:Play()
            task.delay(0.7, function() gui:Destroy() end)
        end)
    end)
end

--[[ ----------------------------- START ------------------------------- ]]--
local center0 = hrp.Position
buildSkyCube(center0 + Vector3.new(0, WALL / 2 - 40, 0))
-- store each wall's offset so the follow loop can re-position them
pcall(function()
    local cx = center0.X
    local cy = center0.Y + WALL / 2 - 40
    local cz = center0.Z
    for _, w in ipairs(skyWalls) do
        if w and w.Parent then
            w:SetAttribute("Rel", w.Position - Vector3.new(cx, cy, cz))
        end
    end
end)
applyOvercastLighting()
toast()
startHeartbeat()
timeline()
print("[QEYADA VFX] started | mobile=" .. tostring(IS_MOBILE)
    .. " | stop: getgenv().QEYADA_VFX_STOP()")
