--=====================================================================
--  LEGENDS  |  BLACK HOLE CINEMATIC INTRO  --  V3.5 (realistic Gargantua edition)
--  Pure VFX: no character, no fight -- a living black hole.
--  Loader:
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/LEGENDS_Intro_VFX_Studio_v2.lua"))()
--=====================================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local CoreGui      = game:GetService("CoreGui")
local Debris       = game:GetService("Debris")

local CONFIG = {
    DURATION     = 58,
    HOLE_POS     = Vector3.new(0, 5000, 0), -- far above the map: beyond streaming range, nothing of the world exists near here
    STAR_COUNT   = 380,
    DEBRIS_COUNT = 44,
    SHOCK_TIMES  = {13, 20, 27, 34, 41, 47},
    SUCK_EVERY   = 2.8,
}

-- v3.5 palette: real Gargantua look -- white-hot core -> gold -> orange -> burnt outer edge
local C_CORE   = Color3.fromRGB(255, 252, 240) -- blazing white-hot (inner edge)
local C_HOT    = Color3.fromRGB(255, 236, 186) -- pale gold
local C_EMBER  = Color3.fromRGB(255, 192, 104) -- gold-orange
local C_PLASMA = Color3.fromRGB(255, 142, 56)  -- deep orange
local C_ROSE   = Color3.fromRGB(198, 84, 30)   -- burnt red-orange outer fade
local C_STAR   = Color3.fromRGB(255, 244, 224) -- warm star white
local C_ICE    = Color3.fromRGB(168, 198, 255) -- cold blue (comets / ice giant only)

local function destroyPrevious()
    local roots = {workspace, Lighting}
    pcall(function()
        table.insert(roots, CoreGui)
    end)
    pcall(function()
        local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            table.insert(roots, pg)
        end
    end)
    for _, root in ipairs(roots) do
        pcall(function()
            for _, obj in ipairs(root:GetChildren()) do
                if obj.Name:sub(1, 8) == "LEGENDS_" then
                    obj:Destroy()
                end
            end
        end)
    end
end

-- stop any previous run before starting fresh
pcall(function()
    local genv = (typeof(getgenv) == "function" and getgenv()) or _G
    if type(genv.LEGENDS_INTRO_STOP) == "function" then
        genv.LEGENDS_INTRO_STOP()
    end
end)

destroyPrevious()

local function main()
    --[[ state ]]--
    local dead        = false
    local loopConn    = nil
    local sceneFolder = nil
    local soundFolder = nil
    local gui         = nil
    local cleanup     = nil
    local myBlackSky  = nil
    local glowPulse   = 0
    local shockPulse  = 0
    local saved       = {}

    -- generation token: a newer execution invalidates this one (race guard)
    local genv = (typeof(getgenv) == "function" and getgenv()) or _G
    local myToken = {}
    genv.LEGENDS_INTRO_TOKEN = myToken

    local isTouch = false
    pcall(function()
        isTouch = game:GetService("UserInputService").TouchEnabled
    end)

    local cam = workspace.CurrentCamera
    local camWaited = 0
    while not cam and camWaited < 8 do
        task.wait(0.1)
        camWaited = camWaited + 0.1
        cam = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
    end
    if genv.LEGENDS_INTRO_TOKEN ~= myToken then
        return -- a newer execution took over while we waited
    end
    if not cam then
        error("no camera found")
    end
    saved.camType = cam.CameraType
    saved.camCF   = cam.CFrame
    saved.camFOV  = cam.FieldOfView
    saved.lighting = {
        Ambient              = Lighting.Ambient,
        OutdoorAmbient       = Lighting.OutdoorAmbient,
        Brightness           = Lighting.Brightness,
        ClockTime            = Lighting.ClockTime,
        FogColor             = Lighting.FogColor,
        FogStart             = Lighting.FogStart,
        FogEnd               = Lighting.FogEnd,
        GlobalShadows        = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
    }

    -- blank any custom sky (gray skybox fix) + kill haze
    -- NOTE: we never touch the old sky's properties, so restoring it = re-parenting only.
    -- (property reads like SunVisible do not exist on Sky and crashed the whole intro)
    saved.skyProps = nil
    local oldSky = Lighting:FindFirstChildOfClass("Sky")
    if oldSky and oldSky.Name ~= "LEGENDS_Sky" then
        saved.skyProps = { obj = oldSky }
        pcall(function()
            oldSky.Parent = nil -- detach entirely; our own black Sky replaces it
        end)
    end

    saved.atmoProps = nil
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        saved.atmoProps = {
            Density = atmo.Density,
            Haze = atmo.Haze,
            Glare = atmo.Glare,
        }
        pcall(function()
            atmo.Density = 0
            atmo.Haze = 0
            atmo.Glare = 0
        end)
    end

    -- neutralize host-game post-processing (REV-B: a game ColorCorrection with
    -- Brightness > 0 or a wide Bloom would gray-wash the black void walls)
    saved.fxProps = {}
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("PostEffect") and fx.Name:sub(1, 8) ~= "LEGENDS_" then
            saved.fxProps[#saved.fxProps + 1] = { obj = fx, enabled = fx.Enabled }
            fx.Enabled = false
        end
    end

    --[[ emergency restore -- registered BEFORE the first mutation (v3.1) ]]--
    local function emergencyRestore()
        dead = true
        pcall(function()
            RunService:UnbindFromRenderStep("LEGENDS_Cam")
        end)
        pcall(function()
            if loopConn then
                loopConn:Disconnect()
                loopConn = nil
            end
        end)
        pcall(function()
            local c = workspace.CurrentCamera or cam
            if c then
                c.CameraType  = saved.camType or Enum.CameraType.Custom
                c.FieldOfView = saved.camFOV or 70
                if saved.camCF and c == cam then
                    c.CFrame = saved.camCF
                end
            end
        end)
        pcall(function()
            local L = saved.lighting
            if L then
                Lighting.Ambient              = L.Ambient
                Lighting.OutdoorAmbient       = L.OutdoorAmbient
                Lighting.Brightness           = L.Brightness
                Lighting.ClockTime            = L.ClockTime
                Lighting.FogColor             = L.FogColor
                Lighting.FogStart             = L.FogStart
                Lighting.FogEnd               = L.FogEnd
                Lighting.GlobalShadows        = L.GlobalShadows
                Lighting.ExposureCompensation = L.ExposureCompensation
            end
        end)
        pcall(function()
            if myBlackSky then
                myBlackSky:Destroy()
                myBlackSky = nil
            end
            if saved.skyProps and saved.skyProps.obj then
                saved.skyProps.obj.Parent = Lighting -- re-attach untouched game sky
            end
        end)
        pcall(function()
            if saved.atmoProps then
                local a = Lighting:FindFirstChildOfClass("Atmosphere")
                if a then
                    a.Density = saved.atmoProps.Density
                    a.Haze    = saved.atmoProps.Haze
                    a.Glare   = saved.atmoProps.Glare
                end
            end
        end)
        pcall(function()
            for _, f in ipairs(saved.fxProps or {}) do
                if f.obj then
                    f.obj.Enabled = f.enabled
                end
            end
        end)
        pcall(function()
            for _, n in ipairs({"LEGENDS_CC", "LEGENDS_Blur", "LEGENDS_Bloom"}) do
                local o = Lighting:FindFirstChild(n)
                if o then
                    o:Destroy()
                end
            end
        end)
        pcall(function()
            if soundFolder then -- REV-C: halt audio before the folder dies
                for _, s in ipairs(soundFolder:GetChildren()) do
                    s:Stop()
                end
            end
        end)
        pcall(function()
            if sceneFolder then
                sceneFolder:Destroy()
                sceneFolder = nil
            end
        end)
        pcall(function()
            if gui then
                gui:Destroy()
                gui = nil
            end
        end)
    end
    genv.LEGENDS_INTRO_STOP = emergencyRestore

    --[[ lighting ]]--
    Lighting.Brightness           = 0
    Lighting.Ambient              = Color3.new(0, 0, 0)
    Lighting.OutdoorAmbient       = Color3.new(0, 0, 0)
    Lighting.ClockTime            = 0
    Lighting.FogColor             = Color3.new(0, 0, 0)
    Lighting.FogStart             = 300
    Lighting.FogEnd               = 2800
    Lighting.GlobalShadows        = false
    Lighting.ExposureCompensation = 0

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name       = "LEGENDS_CC"
    cc.Brightness = 0
    cc.Contrast   = 0.16
    cc.Saturation = -0.02
    cc.Parent     = Lighting

    local blur = Instance.new("BlurEffect")
    blur.Name  = "LEGENDS_Blur"
    blur.Size  = 0
    blur.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name      = "LEGENDS_Bloom"
    bloom.Intensity = 1.55
    bloom.Size      = isTouch and 24 or 40
    bloom.Threshold = 0.88
    bloom.Parent    = Lighting

    -- pitch-black space skybox (100% independent of the game's gray sky)
    do
        local orphan = Lighting:FindFirstChild("LEGENDS_Sky")
        if orphan then
            orphan:Destroy() -- leftover from an older/failed run
        end
    end
    local blackSky = Instance.new("Sky")
    blackSky.Name                 = "LEGENDS_Sky"
    blackSky.SkyboxBk             = ""
    blackSky.SkyboxDn             = ""
    blackSky.SkyboxFt             = ""
    blackSky.SkyboxLf             = ""
    blackSky.SkyboxRt             = ""
    blackSky.SkyboxUp             = ""
    blackSky.CelestialBodiesShown = false -- hides sun + moon + stars (the only valid Sky toggle)
    blackSky.StarCount            = 0
    blackSky.Parent               = Lighting
    myBlackSky = blackSky

    --[[ helpers ]]--
    local HOLE = CONFIG.HOLE_POS

    sceneFolder = Instance.new("Folder")
    sceneFolder.Name   = "LEGENDS_BH_SCENE"
    sceneFolder.Parent = workspace

    local function part(props)
        local p = Instance.new("Part")
        p.Anchored       = true
        p.CanCollide     = false
        p.CanTouch       = false
        p.CanQuery       = false
        p.CastShadow     = false
        p.Material       = Enum.Material.Neon
        p.TopSurface     = Enum.SurfaceType.Smooth
        p.BottomSurface  = Enum.SurfaceType.Smooth
        for k, v in pairs(props) do
            p[k] = v
        end
        p.Parent = sceneFolder
        return p
    end

    local function randomUnit()
        local v = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
        if v.Magnitude < 0.05 then
            v = Vector3.new(0, 1, 0)
        end
        return v.Unit
    end

    local function tw(inst, props, dur, style, dir)
        local ti  = TweenInfo.new(dur or 0.5, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
        local twn = TweenService:Create(inst, ti, props)
        twn:Play()
        return twn
    end

    local function addTrail(p, col)
        local a1 = Instance.new("Attachment")
        a1.Position = Vector3.new(0, 0, 0.35)
        a1.Parent = p
        local a2 = Instance.new("Attachment")
        a2.Position = Vector3.new(0, 0, -0.35)
        a2.Parent = p
        local tr = Instance.new("Trail")
        tr.Attachment0   = a1
        tr.Attachment1   = a2
        tr.Lifetime      = 0.14
        tr.MinLength     = 0
        tr.FaceCamera    = true
        tr.LightEmission = 1
        tr.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
        tr.Color = ColorSequence.new(col, C_HOT)
        tr.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(1, 1),
        })
        tr.Parent = p
        return tr
    end

    --[[ space enclosure -- 6 REAL walls forming a hollow black box.
         v3.2 fix: a single solid Part is INVISIBLE from inside (Roblox backface
         culling), so the game's gray sky + map leaked through it. Each wall's
         inner face now faces the camera -> guaranteed pitch-black void. ]]--
    local WALL_T, WALL_D = 8, 1024 -- inner faces at 1020; camera max reach ~570 never touches them
    local wallDefs = {
        {size = Vector3.new(2048, WALL_T, 2048), off = Vector3.new(0,  WALL_D, 0)}, -- ceiling
        {size = Vector3.new(2048, WALL_T, 2048), off = Vector3.new(0, -WALL_D, 0)}, -- floor
        {size = Vector3.new(WALL_T, 2048, 2048), off = Vector3.new( WALL_D, 0, 0)}, -- +X
        {size = Vector3.new(WALL_T, 2048, 2048), off = Vector3.new(-WALL_D, 0, 0)}, -- -X
        {size = Vector3.new(2048, 2048, WALL_T), off = Vector3.new(0, 0,  WALL_D)}, -- +Z
        {size = Vector3.new(2048, 2048, WALL_T), off = Vector3.new(0, 0, -WALL_D)}, -- -Z
    }
    for wi, wd in ipairs(wallDefs) do
        part({
            Name        = "BH_Space_Wall" .. wi,
            Size        = wd.size,
            Color       = Color3.new(0, 0, 0),
            Material    = Enum.Material.SmoothPlastic,
            Reflectance = 0,
            CFrame      = CFrame.new(HOLE + wd.off),
        })
    end

    --[[ the hole ]]--
    local core = part({
        Name     = "BH_Core",
        Shape    = Enum.PartType.Ball,
        Size     = Vector3.new(44, 44, 44), -- v3.5: a BIGGER shadow
        Color    = Color3.new(0, 0, 0),
        Material = Enum.Material.SmoothPlastic,
        CFrame   = CFrame.new(HOLE),
    })

    local plight = Instance.new("PointLight")
    plight.Color      = C_HOT
    plight.Brightness = 2.0
    plight.Range      = 90
    plight.Parent     = core

    local glow = part({
        Name         = "BH_Glow",
        Shape        = Enum.PartType.Ball,
        Size         = Vector3.new(58, 58, 58),
        Color        = C_HOT,
        Transparency = 0.93,
        CFrame       = CFrame.new(HOLE),
    })

    -- disk tilt (v3.1 fix: declared BEFORE every structure that uses it)
    local diskTilt = CFrame.Angles(math.rad(14), 0, math.rad(-6))

    --[[ ======  REALISTIC HOLE (v3.5): smooth primitives ONLY -- zero boxes.
         Trick: solid Neon cylinders + the opaque black core. The core swallows
         every cylinder's center, so a solid disk reads as a glowing RING. ]]--
    local diskBase0 = CFrame.new(HOLE) * diskTilt

    -- photon ring: razor-thin white-hot ring hugging the shadow
    local photonC = part({
        Name         = "BH_PhotonRing",
        Shape        = Enum.PartType.Cylinder,
        Size         = Vector3.new(0.5, 52, 52), -- radius 26 around the r=22 core
        Color        = C_CORE,
        Transparency = 0.02,
        CFrame       = CFrame.new(HOLE) * CFrame.Angles(0, 0, math.rad(90)), -- axis up -> flat ring
    })

    -- lensed halo: vertical ring arcing over/under the shadow (Interstellar signature)
    local haloT = part({
        Name         = "BH_LensHalo",
        Shape        = Enum.PartType.Cylinder,
        Size         = Vector3.new(0.7, 60, 60),
        Color        = C_HOT,
        Transparency = 0.24,
        CFrame       = CFrame.new(HOLE) * diskTilt
            * CFrame.Angles(math.rad(90), 0, 0)
            * CFrame.Angles(0, 0, math.rad(90)),
    })

    -- smooth accretion disk: stacked flat cylinders, white-hot inner edge -> burnt rim
    local DISK_CYLS = {
        {r = 32,  h = 0.7, c = C_CORE,   tr = 0.05},
        {r = 40,  h = 0.9, c = C_HOT,    tr = 0.10},
        {r = 49,  h = 1.1, c = C_EMBER,  tr = 0.16},
        {r = 59,  h = 1.3, c = C_EMBER,  tr = 0.24},
        {r = 70,  h = 1.6, c = C_PLASMA, tr = 0.60}, -- outer layers kept faint so the
        {r = 83,  h = 1.9, c = C_PLASMA, tr = 0.68}, -- white-hot inner edge reads
        {r = 97,  h = 2.2, c = C_ROSE,   tr = 0.76}, -- through the stack (REV-B)
        {r = 112, h = 2.6, c = C_ROSE,   tr = 0.83},
    }
    for _, dc in ipairs(DISK_CYLS) do
        part({
            Name         = "BH_Disk",
            Shape        = Enum.PartType.Cylinder,
            Size         = Vector3.new(dc.h, dc.r * 2, dc.r * 2),
            Color        = dc.c,
            Transparency = dc.tr,
            CFrame       = diskBase0 * CFrame.Angles(0, 0, math.rad(90)),
        })
    end

    -- relativistic beaming: one side of the disk burns brighter (soft stretched glow)
    local doppler = part({
        Name         = "BH_Doppler",
        Shape        = Enum.PartType.Ball,
        Size         = Vector3.new(18, 9, 46),
        Color        = C_HOT,
        Transparency = 0.78,
        CFrame       = diskBase0 * CFrame.Angles(0, 0.9, 0) * CFrame.new(52, 0, 0),
    })

    -- orbiting dust: rotating invisible anchors make particles spawn along sweeping
    -- arcs (engine-side particles = silky motion, never boxy)
    local function dustEmitter(parent, rate, s0, s1, life, c0, c1)
        local pe = Instance.new("ParticleEmitter")
        pe.Texture        = "rbxasset://textures/particles/sparkles_main.dds"
        pe.Rate           = rate
        pe.Speed          = NumberRange.new(0, 0.4)
        pe.Lifetime       = NumberRange.new(life * 0.6, life)
        pe.RotSpeed       = NumberRange.new(-40, 40)
        pe.SpreadAngle    = Vector2.new(6, 6)
        pe.LightEmission  = 1
        pe.LightInfluence = 0
        pe.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, s0),
            NumberSequenceKeypoint.new(1, s1),
        })
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(1, 1),
        })
        pe.Color  = ColorSequence.new(c0, c1)
        pe.Parent = parent
        return pe
    end

    local dustIn = part({
        Name         = "BH_DustIn",
        Size         = Vector3.new(84, 1.4, 84),
        Transparency = 1,
        CFrame       = diskBase0,
    })
    dustEmitter(dustIn, isTouch and 50 or 100, 0.35, 1.1, 1.7, C_CORE, C_EMBER)

    local dustOut = part({
        Name         = "BH_DustOut",
        Size         = Vector3.new(210, 2.6, 210),
        Transparency = 1,
        CFrame       = diskBase0,
    })
    dustEmitter(dustOut, isTouch and 24 or 48, 0.7, 2.1, 2.6, C_HOT, C_PLASMA)

    -- faint stardust drifting through the void (depth parallax)
    local voidDust = part({
        Name         = "BH_VoidDust",
        Size         = Vector3.new(1500, 320, 1500),
        Transparency = 1,
        CFrame       = CFrame.new(HOLE),
    })
    do
        local pe = dustEmitter(voidDust, 7, 6, 10, 14, Color3.fromRGB(210, 220, 240), C_ICE)
        pe.LightEmission = 0.55
        pe.Speed = NumberRange.new(0, 0.18)
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.93),
            NumberSequenceKeypoint.new(1, 1),
        })
    end

    -- infalling debris: glowing meteors (round, with trails) raining into the disk
    local debris = {}
    local debrisTints = { C_ICE, C_HOT, C_EMBER }
    local debrisN = isTouch and 26 or CONFIG.DEBRIS_COUNT
    for i = 1, debrisN do
        local tint = debrisTints[(i % #debrisTints) + 1]
        local d = part({
            Name   = "BH_Debris",
            Shape  = Enum.PartType.Ball,
            Size   = Vector3.new(1, 1, 1) * (2 + math.random() * 2),
            Color  = tint,
            CFrame = CFrame.new(HOLE),
        })
        debris[i] = {
            part = d,
            tint = tint,
            tilt = CFrame.Angles((math.random() - 0.5) * 1.1, 0, (math.random() - 0.5) * 1.1),
            r    = 70 + math.random() * 190,
            ang  = math.random() * math.pi * 2,
            h    = (math.random() - 0.5) * 150,
            spd  = 0.4 + math.random() * 0.5,
        }
        addTrail(d, tint)
    end

    -- plasma knots: bright orbs riding the disk with trails
    local hotspots = {}
    for i = 1, 7 do
        local h = part({
            Name   = "BH_HotSpot",
            Shape  = Enum.PartType.Ball,
            Size   = Vector3.new(1, 1, 1) * (3 + math.random() * 1.5),
            Color  = C_HOT,
            CFrame = CFrame.new(HOLE),
        })
        addTrail(h, C_EMBER)
        hotspots[i] = {
            part = h,
            r    = 30 + math.random() * 40,
            ang  = math.random() * math.pi * 2,
            spd  = 0.9 + math.random() * 0.9,
            hgt  = (math.random() - 0.5) * 4,
        }
    end

    -- prominence sparks: tiny orbs flashing on the inner rim
    local flares = {}
    for i = 1, 14 do
        flares[i] = {
            part = part({
                Name         = "BH_Flare",
                Shape        = Enum.PartType.Ball,
                Size         = Vector3.new(2.4, 2.4, 2.4),
                Color        = C_HOT,
                Transparency = 1,
                CFrame       = CFrame.new(HOLE),
            }),
            next = 1 + math.random() * 4,
            life = 0,
            max  = 0.5 + math.random() * 0.4,
            ang  = 0,
            r    = 30 + math.random() * 12,
        }
    end

    -- starfield (v3.5: DOUBLE the stars)
    local stars = {}
    local starN = isTouch and 240 or CONFIG.STAR_COUNT
    local starPalette = {
        Color3.fromRGB(214, 226, 255), -- blue-white
        Color3.fromRGB(255, 244, 230), -- warm white
        Color3.fromRGB(224, 190, 255), -- pale violet
        Color3.fromRGB(190, 235, 255), -- pale cyan
    }
    for i = 1, starN do
        local giant = (i <= 10)
        local dist  = 260 + math.random() * 560
        local pos   = HOLE + randomUnit() * dist
        local s = part({
            Name         = "BH_Star",
            Size         = Vector3.new(1, 1, 1) * (giant and (2.6 + math.random() * 1.0) or (0.7 + math.random() * 1.2)),
            Color        = giant and Color3.fromRGB(255, 250, 240) or starPalette[math.random(#starPalette)],
            Transparency = giant and 0.02 or (0.05 + math.random() * 0.35),
            CFrame       = CFrame.new(pos),
        })
        stars[i] = {
            part = s, home = pos, size = s.Size, color = s.Color,
            sucked = false, p = 0, r0 = 0, a0 = 0, h0 = 0,
        }
    end

    -- far star layer: a deep curtain of tiny static stars near the walls
    do
        local farN = isTouch and 90 or 160
        for i = 1, farN do
            local dist = 640 + math.random() * 330
            part({
                Name         = "BH_FarStar",
                Size         = Vector3.new(1, 1, 1) * (0.5 + math.random() * 0.7),
                Color        = starPalette[math.random(#starPalette)],
                Transparency = 0.3 + math.random() * 0.35,
                CFrame       = CFrame.new(HOLE + randomUnit() * dist),
            })
        end
    end

    -- twinkling stars subset (unique stars, shuffled; giants 1..8 keep fixed brightness)
    local twinkle = {}
    local tidx = {}
    for i = 11, #stars do
        tidx[#tidx + 1] = i
    end
    for i = #tidx, 2, -1 do
        local j = math.random(i)
        tidx[i], tidx[j] = tidx[j], tidx[i]
    end
    for i = 1, math.min(isTouch and 45 or 110, #tidx) do
        twinkle[i] = {
            part  = stars[tidx[i]].part,
            star  = stars[tidx[i]],
            phase = math.random() * math.pi * 2,
        }
    end

    -- nebula blobs: deep-space gas clouds (realistic photo palette)
    local nebColors = {
        Color3.fromRGB(38, 60, 148),   -- deep space blue
        Color3.fromRGB(26, 108, 138),  -- teal
        Color3.fromRGB(52, 46, 128),   -- dim indigo
        Color3.fromRGB(148, 78, 40),   -- warm dust
        Color3.fromRGB(84, 108, 196),  -- pale blue
        Color3.fromRGB(138, 40, 62),   -- crimson dust
    }
    for i = 1, 12 do
        local dir = randomUnit()
        dir = Vector3.new(dir.X, math.abs(dir.Y) * 0.6 + 0.05, dir.Z)
        if dir.Magnitude < 0.05 then
            dir = Vector3.new(1, 0.2, 0)
        end
        dir = dir.Unit
        local dist = 680 + math.random() * 140
        part({
            Name         = "BH_Nebula",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * (120 + math.random() * 120),
            Color        = nebColors[(i % #nebColors) + 1],
            Transparency = 0.955,
            CFrame       = CFrame.new(HOLE + dir * dist),
        })
    end

    --[[ planets: a small system scattered in the void -- v3.5: MORE + BIGGER,
         all self-lit Neon (Lighting is pitch black out here, plastic would vanish) ]]--
    local moonP, moonCenter, moonTilt
    do
        -- P1: giant ringed world (Saturn-like, much bigger)
        local p1Pos = HOLE + Vector3.new(-0.6, 0.22, 0.76).Unit * 760
        part({
            Name         = "BH_Planet1",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(150, 150, 150),
            Color        = Color3.fromRGB(214, 176, 128),
            Transparency = 0.04,
            CFrame       = CFrame.new(p1Pos),
        })
        local ringTilt = CFrame.Angles(math.rad(74), 0, math.rad(18))
        for ri, pr in ipairs({ 210, 262 }) do
            part({
                Name         = "BH_Planet1Ring",
                Shape        = Enum.PartType.Cylinder,
                Size         = Vector3.new(ri == 1 and 1.4 or 2.4, pr * 2, pr * 2),
                Color        = Color3.fromRGB(226, 200, 160),
                Transparency = (ri == 1) and 0.55 or 0.72,
                CFrame       = CFrame.new(p1Pos) * CFrame.Angles(0, 0, math.rad(90)) * ringTilt,
            })
        end

        -- P2: ice giant (cold blue, far side)
        local p2Pos = HOLE + Vector3.new(0.55, -0.18, 0.62).Unit * 830
        part({
            Name         = "BH_Planet2",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(110, 110, 110),
            Color        = Color3.fromRGB(140, 182, 238),
            Transparency = 0.05,
            CFrame       = CFrame.new(p2Pos),
        })

        -- P3: red rock world + orbiting moon
        local p3Pos = HOLE + Vector3.new(0.2, 0.35, -0.85).Unit * 700
        part({
            Name         = "BH_Planet3",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(84, 84, 84),
            Color        = Color3.fromRGB(196, 112, 72),
            Transparency = 0.05,
            CFrame       = CFrame.new(p3Pos),
        })
        moonP = part({
            Name         = "BH_Moon",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(22, 22, 22),
            Color        = Color3.fromRGB(190, 190, 198),
            Transparency = 0.1,
            CFrame       = CFrame.new(p3Pos),
        })
        moonCenter = CFrame.new(p3Pos)
        moonTilt   = CFrame.Angles(math.rad(24), 0, math.rad(10))

        -- P4: molten world near the hole (glows with captured heat)
        local p4Pos = HOLE + Vector3.new(-0.35, 0.4, -0.55).Unit * 430
        part({
            Name         = "BH_Planet4",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(48, 48, 48),
            Color        = Color3.fromRGB(255, 138, 54),
            Transparency = 0.1,
            CFrame       = CFrame.new(p4Pos),
        })
    end

    -- distant galaxy swirl (v3.5: bigger + a soft core glow)
    local galaxyCF = CFrame.new(HOLE + Vector3.new(480, 190, -420))
        * CFrame.Angles(math.rad(60), 0, math.rad(20))
    part({
        Name         = "BH_GalCore",
        Shape        = Enum.PartType.Ball,
        Size         = Vector3.new(70, 70, 70),
        Color        = Color3.fromRGB(255, 238, 210),
        Transparency = 0.86,
        CFrame       = galaxyCF,
    })
    for i = 1, 70 do
        local a  = math.random() * math.pi * 2
        local rr = 6 + math.random() * 95
        local y  = (math.random() - 0.5) * 16
        part({
            Name         = "BH_GalStar",
            Size         = Vector3.new(1, 1, 1) * (0.6 + math.random() * 1.1),
            Color        = C_ICE:Lerp(C_HOT, math.random()),
            Transparency = 0.1 + math.random() * 0.4,
            CFrame       = galaxyCF * CFrame.Angles(0, a, 0) * CFrame.new(rr, y, 0),
        })
    end

    -- shooting comets crossing the void (chord paths stay inside the walls)
    local comets = {}
    local cometN = isTouch and 3 or 5
    for i = 1, cometN do
        local c = part({
            Name         = "BH_Comet",
            Size         = Vector3.new(0.9, 0.9, 26),
            Color        = C_ICE,
            Transparency = 1,
            CFrame       = CFrame.new(HOLE),
        })
        comets[i] = {
            part  = c,
            trail = addTrail(c, C_ICE),
            dir   = randomUnit(),
            from  = HOLE + randomUnit() * (340 + math.random() * 90),
            prog  = 0,
            spd   = 0.35 + math.random() * 0.3,
            wait  = 1 + math.random() * 7,
        }
        comets[i].trail.Enabled = false -- parked invisible: no stray streak
    end

    -- (v3.5) the fantasy props (energy pillar / cage / spikes) are gone --
    -- a real black hole needs only shadow, ring, disk and falling matter.

    -- shockwaves
    local shocks = {}
    local function spawnShock()
        shocks[#shocks + 1] = {
            ball = part({
                Name         = "BH_Shock",
                Shape        = Enum.PartType.Ball,
                Size         = Vector3.new(1, 1, 1) * 30,
                Color        = C_EMBER,
                Transparency = 0.2,
                CFrame       = CFrame.new(HOLE),
            }),
            t = 0,
        }
    end

    --[[ per-frame updates ]]--
    local function updateDiskCore(t)
        -- sweeping dust anchors + drifting beaming glow + breathing rings
        dustIn.CFrame  = diskBase0 * CFrame.Angles(0,  t * 0.9, 0)
        dustOut.CFrame = diskBase0 * CFrame.Angles(0, -t * 0.3, 0)
        doppler.CFrame = diskBase0 * CFrame.Angles(0, 0.9 + t * 0.28, 0) * CFrame.new(52, 0, 0)
        photonC.Transparency = 0.02 + 0.04 * (0.5 + 0.5 * math.sin(t * 2.6))
        haloT.Transparency   = 0.22 + 0.08 * (0.5 + 0.5 * math.sin(t * 1.9 + 1))
    end

    local function updateTwinkle(t)
        for _, tk in ipairs(twinkle) do
            if not tk.star.sucked then
                tk.part.Transparency = 0.12 + 0.3 * (0.5 + 0.5 * math.sin(t * 2.5 + tk.phase))
            end
        end
    end

    local function updateComets(dt)
        for _, c in ipairs(comets) do
            if c.wait > 0 then
                c.wait = c.wait - dt
                if c.wait <= 0 then
                    local fd = (c.from - HOLE).Unit -- radial dir relative to the hole, not world origin
                    local d  = randomUnit()
                    d = d - fd * d:Dot(fd)
                    if d.Magnitude < 0.1 then
                        d = fd:Cross(Vector3.yAxis)
                        if d.Magnitude < 0.1 then
                            d = fd:Cross(Vector3.xAxis)
                        end
                    end
                    c.dir  = d.Unit
                    c.prog = 0
                end
            else
                c.prog = c.prog + dt * c.spd
                if c.prog >= 1 then
                    c.part.Transparency = 1
                    c.trail.Enabled     = false
                    c.wait = 3 + math.random() * 6
                    c.from = HOLE + randomUnit() * (340 + math.random() * 90)
                else
                    local pos = c.from + c.dir * ((c.prog - 0.5) * 520)
                    c.trail.Enabled     = true
                    c.part.Transparency = 1 - 0.9 * math.sin(c.prog * math.pi) -- fades to invisible at both ends
                    c.part.CFrame       = CFrame.lookAt(pos, pos + c.dir)
                end
            end
        end
    end

    local function updateDebris(dt)
        for _, d in ipairs(debris) do
            d.r   = d.r - dt * (5 + (200 - d.r) * 0.045)
            d.ang = d.ang + dt * d.spd * (1 + 45 / (d.r + 8))
            d.h   = d.h * (1 - dt * 1.2)
            if d.r < 26 then
                glowPulse = math.min(glowPulse + 0.25, 2)
                d.r   = 130 + math.random() * 120
                d.ang = math.random() * math.pi * 2
                d.h   = (math.random() - 0.5) * 160
            end
            local k = math.clamp(1 - (d.r - 26) / 200, 0, 1)
            d.part.Color        = d.tint:Lerp(C_HOT, k)
            d.part.Size         = Vector3.new(1, 1, 1) * (1.3 + k * 2.0)
            d.part.Transparency = 0.15 + 0.4 * (1 - k)
            d.part.CFrame = CFrame.new(HOLE) * diskTilt * d.tilt
                * CFrame.Angles(0, d.ang, 0)
                * CFrame.new(d.r, d.h, 0)
        end
    end

    local suckTimer = 0

    local function pickSucked()
        local pool = {}
        for _, st in ipairs(stars) do
            if not st.sucked then
                pool[#pool + 1] = st
            end
        end
        for _ = 1, 3 do
            if #pool == 0 then
                break
            end
            local k  = math.random(#pool)
            local st = pool[k]
            table.remove(pool, k)
            local off = st.home - HOLE
            st.sucked = true
            st.p  = 0
            st.r0 = off.Magnitude
            st.a0 = math.atan2(off.Z, off.X)
            st.h0 = off.Y
        end
    end

    local function updateSucked(dt)
        for _, st in ipairs(stars) do
            if st.sucked then
                st.p = st.p + dt / 1.4
                if st.p >= 1 then
                    st.sucked = false
                    glowPulse = math.min(glowPulse + 0.35, 2.2)
                    st.part.CFrame = CFrame.new(st.home)
                    st.part.Color  = st.color
                    st.part.Size   = st.size
                else
                    local rr = st.r0 * (1 - st.p) ^ 1.25 + 20
                    local aa = st.a0 + st.p * 7
                    local hh = st.h0 * (1 - st.p)
                    st.part.Color = C_STAR:Lerp(C_HOT, st.p)
                    local off = Vector3.new(math.cos(aa) * rr, hh, math.sin(aa) * rr)
                    st.part.CFrame = CFrame.new(HOLE + off)
                end
            end
        end
    end

    local function updateHotspots(t, dt)
        for _, hs in ipairs(hotspots) do
            hs.ang = hs.ang + dt * hs.spd
            local w = 1.6 * math.sin(t * 2 + hs.ang * 3)
            hs.part.CFrame = CFrame.new(HOLE) * diskTilt
                * CFrame.Angles(0, hs.ang, 0)
                * CFrame.new(hs.r + w, hs.hgt, 0)
        end
    end

    local function updateFlares(dt, t)
        for _, f in ipairs(flares) do
            f.next = f.next - dt
            if f.next <= 0 and f.life <= 0 then
                f.life = f.max
                f.ang  = math.random() * math.pi * 2
                f.r    = 30 + math.random() * 12
                f.next = 1.2 + math.random() * 3.2
            end
            if f.life > 0 then
                f.life = f.life - dt
                local k = math.clamp(f.life / f.max, 0, 1)
                f.part.Transparency = 1 - k * 0.85
                f.part.Size = Vector3.new(1, 1, 1) * (2.2 + (1 - k) * 1.8)
                f.part.CFrame = CFrame.new(HOLE) * diskTilt
                    * CFrame.Angles(0, f.ang + t * 1.4, 0)
                    * CFrame.new(f.r, 0, 0)
            else
                f.part.Transparency = 1
            end
        end
    end

    -- orbiting moon around the red rock world
    local function updateMoon(t)
        if moonP then
            moonP.CFrame = moonCenter * moonTilt
                * CFrame.Angles(0, t * 0.18, 0)
                * CFrame.new(150, 0, 0)
        end
    end

    local function updateShocks(dt)
        for idx = #shocks, 1, -1 do
            local sh = shocks[idx]
            sh.t = sh.t + dt
            local k = sh.t / 1.6
            if k >= 1 then
                sh.ball:Destroy()
                table.remove(shocks, idx)
            else
                local R = 30 + 330 * (1 - (1 - k) * (1 - k))
                sh.ball.Size         = Vector3.new(1, 1, 1) * R
                sh.ball.Transparency = 0.2 + 0.78 * k
            end
        end
    end

    --[[ sounds ]]--
    soundFolder = Instance.new("Folder")
    soundFolder.Name   = "LEGENDS_BH_SOUNDS"
    soundFolder.Parent = sceneFolder

    local function makeSound(id, looped, speed, vol)
        local s = Instance.new("Sound")
        s.SoundId       = id
        s.Looped        = looped
        s.PlaybackSpeed = speed
        s.Volume        = vol
        s.Parent        = soundFolder
        return s
    end

    local drone  = makeSound("rbxasset://sounds/impact_water.mp3", true, 0.12, 0.9)
    local drone2 = makeSound("rbxasset://sounds/impact_water.mp3", true, 0.25, 0.3)
    local riser  = makeSound("rbxasset://sounds/swoosh.wav", true, 0.35, 0)
    local click  = makeSound("rbxasset://sounds/clickfast.wav", false, 1, 0.6)

    local function boom()
        local b = Instance.new("Sound")
        b.SoundId       = "rbxasset://sounds/impact_water.mp3"
        b.PlaybackSpeed = 0.55
        b.Volume        = 0.85
        b.Parent        = soundFolder
        b:Play()
        Debris:AddItem(b, 5)
    end

    --[[ UI ]]--
    gui = Instance.new("ScreenGui")
    gui.Name          = "LEGENDS_BH_GUI"
    gui.ResetOnSpawn  = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder  = 9999
    local okCore = pcall(function()
        gui.Parent = CoreGui
    end)
    if not okCore then
        local lp = Players.LocalPlayer
        local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
        if not pg and lp then
            pg = lp:WaitForChild("PlayerGui", 5)
        end
        -- a newer execution may have taken over during the yield above
        if dead or genv.LEGENDS_INTRO_TOKEN ~= myToken then
            gui:Destroy()
            return
        end
        if pg then
            gui.Parent = pg
        else
            error("no PlayerGui found")
        end
    end

    local function newFrame(z, trans, color)
        local f = Instance.new("Frame")
        f.BackgroundColor3       = color or Color3.new(0, 0, 0)
        f.BackgroundTransparency = trans
        f.BorderSizePixel        = 0
        f.ZIndex                 = z
        f.Parent                 = gui
        return f
    end

    -- vignette (full-screen cinematic frame, no bars)
    local function vignette(rot, pos, size)
        local f = newFrame(4, 0.35)
        f.Position = pos
        f.Size     = size
        local g = Instance.new("UIGradient")
        g.Rotation    = rot
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        g.Parent = f
    end
    vignette(90,  UDim2.new(0, 0, 0, 0),    UDim2.new(1, 0, 0, 96))
    vignette(-90, UDim2.new(0, 0, 1, -96),  UDim2.new(1, 0, 0, 96))
    vignette(0,   UDim2.new(0, 0, 0, 0),    UDim2.new(0, 96, 1, 0))
    vignette(180, UDim2.new(1, -96, 0, 0),  UDim2.new(0, 96, 1, 0))

    local blackout = newFrame(8, 0) -- starts fully black: no gray flash before camera takes over
    blackout.Size = UDim2.new(1, 0, 1, 0)
    local flash = newFrame(9, 1, Color3.new(1, 1, 1))
    flash.Size = UDim2.new(1, 0, 1, 0)
    local fadeOut = newFrame(20, 1)
    fadeOut.Size = UDim2.new(1, 0, 1, 0)

    -- presents
    local presents = Instance.new("TextLabel")
    presents.BackgroundTransparency  = 1
    presents.Position                = UDim2.new(0, 0, 0.26, 0)
    presents.Size                    = UDim2.new(1, 0, 0, 44)
    presents.Font                    = Enum.Font.GothamBlack
    presents.TextSize                = 30
    presents.Text                    = "L  E  G  E  N  D  S"
    presents.TextColor3              = Color3.fromRGB(255, 244, 224)
    presents.TextTransparency        = 1
    presents.TextStrokeTransparency  = 1
    presents.ZIndex                  = 10
    presents.Parent                  = gui

    -- finale title
    local title = Instance.new("TextLabel")
    title.AnchorPoint            = Vector2.new(0.5, 0.5)
    title.Position               = UDim2.new(0.5, 0, 0.44, 0)
    title.Size                   = UDim2.new(0.9, 0, 0.24, 0)
    title.BackgroundTransparency = 1
    title.Font                   = Enum.Font.GothamBlack
    title.TextScaled             = true
    title.Text                   = "LEGENDS"
    title.TextColor3             = Color3.new(1, 1, 1)
    title.TextTransparency       = 1
    title.ZIndex                 = 10
    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 208, 138))
    tg.Parent = title
    local stroke = Instance.new("UIStroke")
    stroke.Thickness    = 2
    stroke.Color        = Color3.new(0, 0, 0)
    stroke.Transparency = 1
    stroke.Parent       = title
    local tScale = Instance.new("UIScale")
    tScale.Scale = 0.55
    tScale.Parent = title
    title.Parent = gui

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint            = Vector2.new(0.5, 0)
    sub.Position               = UDim2.new(0.5, 0, 0.62, 0)
    sub.Size                   = UDim2.new(1, 0, 0, 34)
    sub.BackgroundTransparency = 1
    sub.Font                   = Enum.Font.Gotham
    sub.TextSize               = 22
    sub.Text                   = "F O R G E D   I N   T H E   V O I D"
    sub.TextColor3             = Color3.fromRGB(255, 232, 200)
    sub.TextTransparency       = 1
    sub.ZIndex                 = 10
    sub.Parent                 = gui

    local sub2 = Instance.new("TextLabel")
    sub2.AnchorPoint            = Vector2.new(0.5, 0)
    sub2.Position               = UDim2.new(0.5, 0, 0.685, 0)
    sub2.Size                   = UDim2.new(1, 0, 0, 30)
    sub2.BackgroundTransparency = 1
    sub2.Font                   = Enum.Font.GothamBold
    sub2.TextSize               = 20
    sub2.Text                   = "أسطورة بتتولد من العتمة"
    sub2.TextColor3             = Color3.fromRGB(255, 210, 164)
    sub2.TextTransparency       = 1
    sub2.ZIndex                 = 10
    sub2.Parent                 = gui

    -- skip button
    local skip = Instance.new("TextButton")
    skip.AnchorPoint            = Vector2.new(1, 1)
    skip.Position               = UDim2.new(1, -22, 1, -22)
    skip.Size                   = UDim2.new(0, 150, 0, 44)
    skip.BackgroundColor3       = Color3.new(0, 0, 0)
    skip.BackgroundTransparency = 0.55
    skip.Font                   = Enum.Font.GothamBold
    skip.TextSize               = 16
    skip.TextColor3             = Color3.fromRGB(235, 240, 250)
    skip.Text                   = "تخطي | SKIP"
    skip.ZIndex                 = 12
    skip.Parent                 = gui
    local skCorner = Instance.new("UICorner")
    skCorner.CornerRadius = UDim.new(0, 8)
    skCorner.Parent = skip
    local skStroke = Instance.new("UIStroke")
    skStroke.Color        = Color3.fromRGB(232, 182, 110)
    skStroke.Transparency = 0.4
    skStroke.Parent       = skip

    --[[ cleanup ]]--
    cleanup = function()
        if dead then return end
        dead = true
        pcall(function()
            RunService:UnbindFromRenderStep("LEGENDS_Cam")
        end)
        pcall(function()
            if loopConn then
                loopConn:Disconnect()
                loopConn = nil
            end
        end)
        pcall(function()
            if soundFolder then
                for _, s in ipairs(soundFolder:GetChildren()) do
                    s:Stop()
                end
            end
        end)
        pcall(function()
            local c = workspace.CurrentCamera or cam
            if c then
                c.CameraType  = saved.camType or Enum.CameraType.Custom
                c.FieldOfView = saved.camFOV or 70
                if saved.camCF and c == cam then
                    c.CFrame = saved.camCF
                end
            end
        end)
        pcall(function()
            local L = saved.lighting
            if L then
                Lighting.Ambient              = L.Ambient
                Lighting.OutdoorAmbient       = L.OutdoorAmbient
                Lighting.Brightness           = L.Brightness
                Lighting.ClockTime            = L.ClockTime
                Lighting.FogColor             = L.FogColor
                Lighting.FogStart             = L.FogStart
                Lighting.FogEnd               = L.FogEnd
                Lighting.GlobalShadows        = L.GlobalShadows
                Lighting.ExposureCompensation = L.ExposureCompensation
            end
        end)
        pcall(function()
            if myBlackSky then
                myBlackSky:Destroy()
                myBlackSky = nil
            end
            if saved.skyProps and saved.skyProps.obj then
                saved.skyProps.obj.Parent = Lighting -- re-attach untouched game sky
            end
        end)
        pcall(function()
            if saved.atmoProps then
                local a = Lighting:FindFirstChildOfClass("Atmosphere")
                if a then
                    a.Density = saved.atmoProps.Density
                    a.Haze = saved.atmoProps.Haze
                    a.Glare = saved.atmoProps.Glare
                end
            end
        end)
        pcall(function()
            for _, f in ipairs(saved.fxProps or {}) do
                if f.obj then
                    f.obj.Enabled = f.enabled
                end
            end
        end)
        pcall(function()
            cc:Destroy()
            blur:Destroy()
            bloom:Destroy()
        end)
        pcall(function()
            if sceneFolder then
                sceneFolder:Destroy()
                sceneFolder = nil
            end
        end)
        pcall(function()
            if gui then
                gui:Destroy()
                gui = nil
            end
        end)
    end

    skip.MouseButton1Click:Connect(function()
        click:Play()
        task.delay(0.08, cleanup)
    end)

    pcall(function()
        local genv = (typeof(getgenv) == "function" and getgenv()) or _G
        genv.LEGENDS_INTRO_STOP = cleanup
    end)

    --[[ camera director ]]--
    -- a newer execution or cleanup may have fired during init yields
    if dead or genv.LEGENDS_INTRO_TOKEN ~= myToken then
        cleanup()
        return
    end
    -- re-snapshot camera right before takeover (it may have drifted during init)
    saved.camType = cam.CameraType
    saved.camCF   = cam.CFrame
    saved.camFOV  = cam.FieldOfView
    cam.CameraType = Enum.CameraType.Scriptable

    local CAM = {
        {t0 = 0,  t1 = 9,  r0 = 560, r1 = 470, h0 = 30,  h1 = 60,  w0 = 0.05, fov0 = 72, fov1 = 64, rollA = 0,  shake = 0.15, a0 = -0.40, ease = 1},
        {t0 = 9,  t1 = 20, r0 = 470, r1 = 200, h0 = 60,  h1 = 85,  w0 = 0.13, fov0 = 64, fov1 = 58, rollA = 4,  shake = 0.30, a0 = 0.05,  ease = 1},
        {t0 = 20, t1 = 34, r0 = 200, r1 = 100, h0 = 85,  h1 = 45,  w0 = 0.21, fov0 = 58, fov1 = 70, rollA = 9,  shake = 0.80, a0 = 1.48,  ease = 1},
        {t0 = 34, t1 = 44, r0 = 100, r1 = 280, h0 = 45,  h1 = 120, w0 = 0.10, fov0 = 70, fov1 = 64, rollA = 3,  shake = 0.40, a0 = 4.42,  ease = 1},
        {t0 = 44, t1 = 52, r0 = 280, r1 = 40,  h0 = 120, h1 = 18,  w0 = 0.27, fov0 = 64, fov1 = 86, rollA = 14, shake = 1.70, a0 = 5.42,  ease = 2},
        {t0 = 52, t1 = 58, r0 = 40,  r1 = 34,  h0 = 18,  h1 = 14,  w0 = 0.15, fov0 = 86, fov1 = 92, rollA = 2,  shake = 0.50, a0 = 7.58,  ease = 0},
    }

    local function easeSm(u)
        return u * u * (3 - 2 * u)
    end

    local function pickEase(kind, u)
        if kind == 1 then
            return easeSm(u)
        elseif kind == 2 then
            return u * u
        end
        return u
    end

    local function camAt(t)
        local seg = CAM[#CAM]
        for _, s in ipairs(CAM) do
            if t < s.t1 then
                seg = s
                break
            end
        end
        local u = math.clamp((t - seg.t0) / (seg.t1 - seg.t0), 0, 1)
        local e      = pickEase(seg.ease, u)
        local radius = seg.r0 + (seg.r1 - seg.r0) * e
        local height = seg.h0 + (seg.h1 - seg.h0) * easeSm(u)
        local ang    = seg.a0 + seg.w0 * (t - seg.t0)
        local fov    = seg.fov0 + (seg.fov1 - seg.fov0) * easeSm(u)
        local roll   = seg.rollA * math.sin(u * math.pi * 2)
        local pos = Vector3.new(
            HOLE.X + math.cos(ang) * radius,
            HOLE.Y + height,
            HOLE.Z + math.sin(ang) * radius
        )
        return pos, fov, roll, seg.shake
    end

    --[[ beats ]]--
    task.delay(1.2, function()
        if dead then return end
        tw(presents, {TextTransparency = 0.05, TextStrokeTransparency = 0.6}, 1.6)
    end)
    task.delay(5.5, function()
        if dead then return end
        tw(presents, {TextTransparency = 1, TextStrokeTransparency = 1}, 1.4)
    end)
    task.delay(1.3, function()
        if dead then return end
        tw(blackout, {BackgroundTransparency = 1}, 1.4)
    end)
    task.delay(44, function()
        if dead then return end
        riser:Play()
        TweenService:Create(riser, TweenInfo.new(7, Enum.EasingStyle.Linear), {Volume = 0.85}):Play()
    end)
    task.delay(49.8, function()
        if dead then return end
        tw(blackout, {BackgroundTransparency = 0}, 1.2)
    end)
    task.delay(52.6, function()
        if dead then return end
        tw(blackout, {BackgroundTransparency = 0.78}, 1.6)
    end)
    task.delay(52, function()
        if dead then return end
        riser:Stop()
        flash.BackgroundTransparency = 0
        tw(flash, {BackgroundTransparency = 1}, 0.8)
        local hit = makeSound("rbxasset://sounds/impact_water.mp3", false, 1.0, 1.0)
        hit:Play()
        Debris:AddItem(hit, 6)
        local ping = makeSound("rbxasset://sounds/electronicpingshort.wav", false, 0.5, 0.5)
        ping:Play()
        Debris:AddItem(ping, 6)
        tw(title, {TextTransparency = 0}, 1.2)
        tw(stroke, {Transparency = 0.3}, 1.2)
        TweenService:Create(tScale, TweenInfo.new(1.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(drone, TweenInfo.new(3.5), {Volume = 0}):Play()
        TweenService:Create(drone2, TweenInfo.new(3.5), {Volume = 0}):Play()
    end)
    task.delay(53.4, function()
        if dead then return end
        tw(sub, {TextTransparency = 0.05}, 1.2)
        tw(sub2, {TextTransparency = 0.1}, 1.2)
    end)
    task.delay(56.6, function()
        if dead then return end
        tw(fadeOut, {BackgroundTransparency = 0}, 1.0)
    end)
    task.delay(57.8, function()
        cleanup()
    end)
    task.delay(65, function()
        cleanup()
    end)

    --[[ main loop ]]--
    local elapsed   = 0
    local shockIdx  = 1

    drone:Play()
    drone2:Play()

    local function stepFrame(dtStep)
        local dt = math.clamp(dtStep, 0.001, 0.1)
        elapsed  = elapsed + math.clamp(dtStep, 0, 0.25)
        local t  = elapsed

        -- keep the void hers (REV-C): host day/night scripts may rewrite fog every frame
        Lighting.FogColor = Color3.new(0, 0, 0)
        Lighting.FogStart = 300
        Lighting.FogEnd   = 2800
        pcall(function()
            local at2 = Lighting:FindFirstChildOfClass("Atmosphere")
            if at2 then
                at2.Density = 0
                at2.Haze = 0
                at2.Glare = 0
            end
        end)

        while shockIdx <= #CONFIG.SHOCK_TIMES and t >= CONFIG.SHOCK_TIMES[shockIdx] do
            shockIdx = shockIdx + 1
            spawnShock()
            boom()
            shockPulse = 1
        end

        suckTimer = suckTimer + dt
        if suckTimer >= CONFIG.SUCK_EVERY and t < 50 then -- REV-C: still starfield for the title reveal
            suckTimer = suckTimer - CONFIG.SUCK_EVERY
            pickSucked()
        end

        local dive = math.clamp((t - 44) / 8, 0, 1)

        updateDiskCore(t)
        updateDebris(dt)
        updateSucked(dt)
        updateShocks(dt)
        updateTwinkle(t)
        updateHotspots(t, dt)
        updateFlares(dt, t)
        updateComets(dt)
        updateMoon(t)

        shockPulse = shockPulse * (1 - dt * 2.2)
        glowPulse  = glowPulse * (1 - dt * 3)

        blur.Size      = math.min(shockPulse * 14 + dive * 22, isTouch and 14 or 40)
        cc.Brightness  = shockPulse * 0.10 - dive * 0.08
        cc.Contrast    = 0.08 + dive * 0.22
        cc.Saturation  = -0.05 - dive * 0.25
        cc.TintColor   = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 172, 110), dive)
        bloom.Intensity = math.min(1.4 + 0.35 * math.sin(t * 1.3) + shockPulse * 0.7 + glowPulse * 0.35, isTouch and 1.8 or 2.6)

        glow.Size         = Vector3.new(1, 1, 1) * (58 + glowPulse * 9)
        glow.Transparency = 0.93 - glowPulse * 0.05
        plight.Brightness = 2.0 + glowPulse * 1.6
        core.Size         = Vector3.new(1, 1, 1) * (44 + 1.4 * math.sin(t * 2.6) + glowPulse * 1.8)

        local camNow = workspace.CurrentCamera
        if camNow then
            if camNow.CameraType ~= Enum.CameraType.Scriptable then
                camNow.CameraType = Enum.CameraType.Scriptable
            end
            local pos, fov, roll, shakeAmt = camAt(t)
            local sx = math.noise(t * 1.7, 0) * shakeAmt
            local sy = math.noise(0, t * 1.7) * shakeAmt
            local sz = math.noise(t * 1.3, 9) * shakeAmt
            pos = pos + Vector3.new(sx, sy, sz) * 1.1
            local rShake = math.noise(t * 1.1, 4) * shakeAmt * 1.3
            camNow.CFrame = CFrame.lookAt(pos, HOLE + Vector3.new(0, 2, 0))
                * CFrame.Angles(0, 0, math.rad(roll + rShake))
            camNow.FieldOfView = fov
        end
    end

    local function camStep(dtStep)
        if dead or genv.LEGENDS_INTRO_TOKEN ~= myToken or not sceneFolder.Parent then return end
        local ok, err = pcall(stepFrame, dtStep)
        if not ok then
            warn("[LEGENDS] frame error:", err)
        end
        if elapsed >= CONFIG.DURATION + 2 then
            cleanup()
        end
    end

    -- camera-priority render bind (beats game camera controllers); fallback to RenderStepped
    pcall(function()
        RunService:UnbindFromRenderStep("LEGENDS_Cam")
    end)
    local boundOk = false
    pcall(function()
        RunService:BindToRenderStep("LEGENDS_Cam", Enum.RenderPriority.Camera.Value + 1, camStep)
        boundOk = true
    end)
    if not boundOk then
        loopConn = RunService.RenderStepped:Connect(camStep)
    end
end

--=====================================================================
--  run with full error surface
--=====================================================================
local OK, ERR = pcall(main)
if not OK then
    warn("[LEGENDS] intro error:", ERR)
    pcall(function()
        local genv = (typeof(getgenv) == "function" and getgenv()) or _G
        if type(genv.LEGENDS_INTRO_STOP) == "function" then
            genv.LEGENDS_INTRO_STOP()
        end
    end)
    pcall(function()
        local g = Instance.new("ScreenGui")
        g.Name          = "LEGENDS_ERR"
        g.DisplayOrder  = 10000
        g.ResetOnSpawn  = false
        local okc = pcall(function()
            g.Parent = game:GetService("CoreGui")
        end)
        if not okc then
            local lp = Players.LocalPlayer
            local pg = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 3))
            if not pg then
                return -- cannot surface the error visually
            end
            g.Parent = pg
        end
        local tl = Instance.new("TextLabel")
        tl.Size                   = UDim2.new(0.9, 0, 0, 60)
        tl.Position               = UDim2.new(0.05, 0, 0.04, 0)
        tl.BackgroundColor3       = Color3.new(0, 0, 0)
        tl.BackgroundTransparency = 0.4
        tl.TextColor3             = Color3.fromRGB(255, 120, 120)
        tl.Font                   = Enum.Font.Code
        tl.TextSize               = 14
        tl.TextWrapped            = true
        tl.Text                   = "LEGENDS intro error: " .. tostring(ERR):sub(1, 160)
        tl.Parent                 = g
        game:GetService("Debris"):AddItem(g, 12)
    end)
end
