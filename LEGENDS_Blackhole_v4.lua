--=====================================================================
--  LEGENDS  |  BLACK HOLE CINEMATIC INTRO  --  V4.0 (REALISM edition)
--  * crash fix: CFrame.identity() called as a function (line 917) -> CFrame.new()
--  * disk: 64-chord rings (no polygons) + real Doppler beaming (one side burns
--    brighter, tracked to the camera every frame -- like Gargantua)
--  * planets: latitude bands are now vertical beam strips hugging the sphere
--    (zero poking disks), surface detail = dozens of tiny mottle blobs that
--    melt together -- no more visible plate shapes
--  Loader (THIS file = pure 58s cinematic, no hub UI):
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/LEGENDS_Blackhole_v4.lua"))()
--  (the main path LEGENDS_Intro_VFX_Studio_v2.lua serves the EL QEYADA HUB instead)
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
    STAR_COUNT   = 520,
    DEBRIS_COUNT = 44,
    SHOCK_TIMES  = {13, 20, 27, 34, 41, 47},
    SUCK_EVERY   = 2.8,
}

-- v4.0 palette: real Gargantua look -- white-hot core -> gold -> orange -> burnt outer edge
local C_CORE   = Color3.fromRGB(255, 252, 240) -- blazing white-hot (inner edge)
local C_HOT    = Color3.fromRGB(255, 236, 186) -- pale gold
local C_EMBER  = Color3.fromRGB(255, 192, 104) -- gold-orange
local C_PLASMA = Color3.fromRGB(255, 136, 44)  -- vivid deep orange
local C_ROSE   = Color3.fromRGB(188, 72, 24)   -- burnt red-orange outer fade
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
    pcall(function() -- REV-C: never let host-FX probing strand the restore path
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") and fx.Name:sub(1, 8) ~= "LEGENDS_" then
                saved.fxProps[#saved.fxProps + 1] = { obj = fx, enabled = fx.Enabled }
                fx.Enabled = false
            end
        end
    end)

    --[[ emergency restore -- registered BEFORE the first mutation (v3.1) ]]--
    local function emergencyRestore()
        dead = true
        pcall(function()
            if genv.LEGENDS_INTRO_TOKEN == myToken then -- a newer run owns the bind (REV-A)
                RunService:UnbindFromRenderStep("LEGENDS_Cam")
            end
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
    cc.Contrast   = 0.18
    cc.Saturation = -0.02
    cc.Parent     = Lighting

    local blur = Instance.new("BlurEffect")
    blur.Name  = "LEGENDS_Blur"
    blur.Size  = 0
    blur.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name      = "LEGENDS_Bloom"
    bloom.Intensity = 1.8
    bloom.Size      = isTouch and 24 or 40
    bloom.Threshold = 0.82
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

    --[[ beam rings (v3.7): a circle made ONLY of Beams -- N attachments on the
         circumference, N straight chords between neighbours. With
         LightEmission=1 the chords fuse into one seamless glowing torus:
         zero visible geometry, zero polygon facets, correct from any angle.
         The opaque black core depth-occludes the far side -> a REAL shadow. ]]--
    local ringFX = {} -- animated rings: {beams, base, amp, freq, ph}
    local dopRings = {} -- Doppler rings: {beams, brBase, dirs[], mids[]} (v4.0)
    local function beamRing(centerCF, radius, width, color, tr, spd, bright, nSeg, anim, dop)
        nSeg = nSeg or 64
        local anchor = part({
            Name         = "BH_BeamRing",
            Size         = Vector3.new(0.4, 0.4, 0.4),
            Transparency = 1,
            CFrame       = centerCF,
        })
        local atts = {}
        for i = 1, nSeg do
            local a  = (i / nSeg) * math.pi * 2
            local at = Instance.new("Attachment")
            at.Position = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
            at.Parent   = anchor
            atts[i]     = at
        end
        local beams = {}
        for i = 1, nSeg do
            local b = Instance.new("Beam")
            b.Attachment0    = atts[i]
            b.Attachment1    = atts[(i % nSeg) + 1]
            b.Width0         = width
            b.Width1         = width
            b.Color          = ColorSequence.new(color)
            b.Transparency   = NumberSequence.new(tr)
            b.LightEmission  = 1
            b.LightInfluence = 0
            b.Brightness     = bright
            b.Texture        = "rbxasset://textures/particles/fire_main.dds"
            b.TextureMode    = Enum.TextureMode.Wrap
            b.TextureLength  = (2 * math.pi * radius) / 8
            b.TextureSpeed   = spd
            b.FaceCamera     = true
            b.Segments       = 1
            b.Parent         = anchor
            beams[i] = b
        end
        if anim then
            ringFX[#ringFX + 1] = { beams = beams, base = tr, amp = anim[1], freq = anim[2], ph = anim[3] }
        end
        if dop then
            -- precompute each chord's world midpoint + orbital motion direction
            -- (the disk spins toward +theta; Doppler beaming brightens the side
            --  whose matter moves TOWARD the camera -- recomputed per frame)
            local dr = { beams = beams, brBase = bright, dirs = {}, mids = {} }
            for i = 1, nSeg do
                local am = ((i - 0.5) / nSeg) * math.pi * 2
                local lm = Vector3.new(math.cos(am) * radius, 0, math.sin(am) * radius)
                dr.mids[i] = (centerCF * CFrame.new(lm)).Position
                dr.dirs[i] = centerCF:VectorToWorldSpace(Vector3.new(-math.sin(am), 0, math.cos(am))).Unit
            end
            dopRings[#dopRings + 1] = dr
        end
        return anchor
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
    plight.Brightness = 2.4
    plight.Range      = 60 -- engine max (REV-A: 140 silently clamps to 60)
    plight.Parent     = core

    local glow = part({
        Name         = "BH_Glow",
        Shape        = Enum.PartType.Ball,
        Size         = Vector3.new(64, 64, 64),
        Color        = C_HOT,
        Transparency = 0.95,
        CFrame       = CFrame.new(HOLE),
    })

    -- disk tilt (v3.1 fix: declared BEFORE every structure that uses it)
    local diskTilt = CFrame.Angles(math.rad(14), 0, math.rad(-6))

    --[[ ======  THE HOLE (v3.7): pure-light build -- ZERO solid disk geometry.
         Reference (Gargantua / EHT): a pure black shadow, a razor-thin
         white-hot photon ring hugging it, a lensed halo arcing around it,
         and a thin striated disk: white-hot inner edge -> gold -> orange ->
         burnt rim. Every ring is fused beam chords (see beamRing): zero
         visible facets; the black core depth-occludes the far side.
         Photon ring + halo are re-aimed at the camera every frame, so the
         classic silhouette holds from every orbit angle (lensing artifact). ]]--
    local diskBase0 = CFrame.new(HOLE) * diskTilt

    -- face-on group: photon ring + companion bloom + lensed halo
    -- (v4.0: 64/44 chords -> geometrically perfect circles, no polygon corners)
    local camLook0 = CFrame.lookAt(HOLE, HOLE + Vector3.new(0, 0, -1))
    local photonA = beamRing(camLook0, 24.5, 1.5, C_CORE,  0.00, 0.55, 4.2, isTouch and 44 or 64, {0.05, 2.6, 0.0})
    local photonB = beamRing(camLook0, 26.5, 2.8, C_HOT,   0.45, 0.38, 2.3, isTouch and 44 or 64, {0.10, 2.6, 0.9})
    local haloA   = beamRing(camLook0, 31.0, 2.2, C_EMBER, 0.55, 0.26, 1.9, isTouch and 44 or 64, {0.12, 1.9, 1.6})
    photonA.Name = "BH_PhotonRing"
    photonB.Name = "BH_PhotonBloom"
    haloA.Name   = "BH_LensHalo"

    -- accretion disk: Keplerian striation rings in the tilted disk plane
    -- (inner = fast + white-hot, outer = slow + burnt; the inner edge hugs the
    --  photon ring like the real thing; last two rings = soft burnt envelope
    --  so the disk melts into the void instead of ending on a hard rim)
    local diskRings = {
        { r = 28.5, w = 3.2, c = C_CORE,   tr = 0.02, sp = 1.05, br = 3.2 },
        { r = 34,   w = 2.6, c = C_CORE,   tr = 0.08, sp = 0.88, br = 3.1 },
        { r = 40.5, w = 3.0, c = C_HOT,    tr = 0.13, sp = 0.70, br = 3.0 },
        { r = 48,   w = 2.6, c = C_HOT,    tr = 0.20, sp = 0.55, br = 2.8 },
        { r = 57,   w = 3.4, c = C_EMBER,  tr = 0.26, sp = 0.44, br = 2.6 },
        { r = 68,   w = 2.6, c = C_EMBER,  tr = 0.34, sp = 0.36, br = 2.4 },
        { r = 81,   w = 3.6, c = C_PLASMA, tr = 0.42, sp = 0.29, br = 2.2 },
        { r = 96,   w = 3.0, c = C_PLASMA, tr = 0.52, sp = 0.22, br = 2.0 },
        { r = 114,  w = 4.2, c = C_ROSE,   tr = 0.62, sp = 0.16, br = 1.7 },
        { r = 134,  w = 4.8, c = C_ROSE,   tr = 0.74, sp = 0.11, br = 1.4 },
        { r = 158,  w = 7.0, c = C_ROSE,   tr = 0.85, sp = 0.07, br = 1.0 },
        { r = 184,  w = 9.0, c = C_ROSE,   tr = 0.92, sp = 0.05, br = 0.8 },
    }
    for _, dr in ipairs(diskRings) do
        beamRing(diskBase0, dr.r, dr.w, dr.c, dr.tr, dr.sp, dr.br, isTouch and 40 or 64, nil, true)
    end

    -- orbiting dust: rotating invisible anchors make particles spawn along sweeping
    -- arcs (engine-side particles = silky motion, never boxy)
    local function dustEmitter(parent, rate, s0, s1, life, c0, c1, tex)
        local pe = Instance.new("ParticleEmitter")
        pe.Texture        = tex or "rbxasset://textures/particles/fire_main.dds"
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
    dustEmitter(dustIn, isTouch and 62 or 130, 0.7, 2.0, 1.7, C_CORE, C_EMBER)

    local dustOut = part({
        Name         = "BH_DustOut",
        Size         = Vector3.new(210, 2.6, 210),
        Transparency = 1,
        CFrame       = diskBase0,
    })
    dustEmitter(dustOut, isTouch and 30 or 62, 1.2, 3.2, 2.6, C_HOT, C_PLASMA)

    -- faint stardust drifting through the void (depth parallax)
    local voidDust = part({
        Name         = "BH_VoidDust",
        Size         = Vector3.new(1500, 320, 1500),
        Transparency = 1,
        CFrame       = CFrame.new(HOLE),
    })
    do
        local pe = dustEmitter(voidDust, 7, 6, 10, 14, Color3.fromRGB(210, 220, 240), C_ICE, "rbxasset://textures/particles/sparkles_main.dds")
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

    -- starfield (v3.6: denser field + bigger bright giants)
    local stars = {}
    local starN = isTouch and 300 or CONFIG.STAR_COUNT
    local starPalette = {
        Color3.fromRGB(214, 226, 255), -- blue-white
        Color3.fromRGB(255, 244, 230), -- warm white
        Color3.fromRGB(255, 228, 190), -- warm gold
        Color3.fromRGB(190, 235, 255), -- pale cyan
    }
    for i = 1, starN do
        local giant = (i <= 14)
        local dist  = 260 + math.random() * 560
        local pos   = HOLE + randomUnit() * dist
        local s = part({
            Name         = "BH_Star",
            Shape        = Enum.PartType.Ball, -- REV-B: never Blocks (the square-star bug)
            Size         = Vector3.new(1, 1, 1) * (giant and (3.2 + math.random() * 1.4) or (0.8 + math.random() * 1.4)),
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
        local farN = isTouch and 120 or 220
        for i = 1, farN do
            local dist = 640 + math.random() * 330
            part({
                Name         = "BH_FarStar",
                Shape        = Enum.PartType.Ball,
                Size         = Vector3.new(1, 1, 1) * (0.6 + math.random() * 0.8),
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
    for i = 1, math.min(isTouch and 55 or 130, #tidx) do
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

    --[[ planets: a small system scattered in the void -- v3.7 rebuild.
         Every world is lit by a REAL PointLight parked on its day side (the
         side facing the burning disk) -> true day/night terminator instead
         of flat self-lit Neon. Surface detail = latitude belts (squashed
         spheres that poke 2-3% through the globe) and surface patches
         (flattened tangent ellipsoids that hug the curve) -- never warts.
         Saturn rings = beam rings (see beamRing): silky, gap-separated. ]]--
    local moonP, moonCenter, moonTilt, moonLight
    local spinners = {} -- rotating surface details {cf0, spd, kids={{p, off}}}

    --[[ latitude band (v4.0 REALISM): a closed strip of straight beam chords
         hugging the sphere at one latitude. Each attachment stands VERTICAL
         (its Y axis = the planet's spin axis), so every chord renders as a
         vertical ribbon tangent to the surface: from any side view it reads
         as a weather belt painted ON the globe, and the far half is
         depth-occluded by the planet itself. Zero poking disks, zero plates,
         zero silhouette bumps -- the old squashed-ball belts are gone. ]]--
    local function band(planetCF, R, latDeg, width, color, tr, br, opts)
        opts = opts or {}
        local lat   = math.rad(latDeg)
        local yLat  = math.sin(lat) * R
        local rc    = math.cos(lat) * R * 1.012
        local nSeg  = opts.segs or (isTouch and 30 or 44)
        local anchor = part({
            Name         = "BH_Band",
            Size         = Vector3.new(0.4, 0.4, 0.4),
            Transparency = 1,
            CFrame       = planetCF,
        })
        local atts = {}
        for i = 1, nSeg do
            local th = (i / nSeg) * math.pi * 2
            local at = Instance.new("Attachment")
            at.CFrame = CFrame.Angles(0, th, 0) * CFrame.new(rc, yLat, 0)
            at.Parent = anchor
            atts[i] = at
        end
        for i = 1, nSeg do
            local b = Instance.new("Beam")
            b.Attachment0    = atts[i]
            b.Attachment1    = atts[(i % nSeg) + 1]
            b.Width0         = width
            b.Width1         = width
            b.Color          = ColorSequence.new(color)
            b.Transparency   = NumberSequence.new(tr)
            b.LightEmission  = opts.emit or 0.3  -- bands obey the day light ...
            b.LightInfluence = opts.inf or 0.7   -- ... so the night side goes dark
            b.Brightness     = br or 1
            b.FaceCamera     = false
            b.Segments       = 1
            if opts.tex then
                b.Texture       = opts.tex
                b.TextureMode   = Enum.TextureMode.Wrap
                b.TextureLength = (2 * math.pi * rc) / (opts.texRep or 6)
                b.TextureSpeed  = opts.spd or 0
            end
            b.Parent = anchor
        end
        return anchor
    end

    -- surface mottle (v4.0): a TINY flattened ball tangent to the globe
    -- (5-30 studs on a 116-340 stud planet) -- dozens melt into continents /
    -- maria / storms with no readable outline. Each planet owns ONE spinner
    -- carrying all its blobs (a single CFrame chain per planet per frame).
    local function patch(sp, R, theta, elev, w, h, thick, color, tr, mat)
        local p = part({
            Name         = "BH_Patch",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(w, h, thick),
            Color        = color,
            Transparency = tr,
            Material     = mat or Enum.Material.SmoothPlastic,
            Reflectance  = 0,
        })
        local off = CFrame.Angles(0, theta, 0)
            * CFrame.Angles(elev, 0, 0)
            * CFrame.new(0, 0, -(R - thick * 0.25))
        sp.kids[#sp.kids + 1] = { p = p, off = off }
        return p
    end

    -- day light: a real light source parked on the day side (facing the
    -- burning disk). PointLight Range caps at 60 (REV-A) so keep it close.
    local function dayLight(pos, R, color, bright, dist)
        local dir = (HOLE - pos).Unit
        local lp = part({
            Name         = "BH_DayLight",
            Size         = Vector3.new(0.4, 0.4, 0.4),
            Transparency = 1,
            Material     = Enum.Material.SmoothPlastic,
            CFrame       = CFrame.new(pos + dir * (R + (dist or 4))),
        })
        local pl = Instance.new("PointLight")
        pl.Color      = color
        pl.Brightness = bright
        pl.Range      = 60
        pl.Parent     = lp
        return lp
    end

    do
        --[[ ====== PLANETARY SYSTEM (v4.0 REALISM) ======
             Every world = one matte globe lit by real PointLights parked on
             its day side (true day/night terminator) + vertical beam-strip
             latitude bands hugging the sphere + dozens of tiny tangent
             mottle blobs that melt together. Nothing pokes out of any
             silhouette: no plates, no warts, no visible composite shapes. ]]--

        -- P1: giant ringed world (Jupiter warmth + Saturn rings): cream
        -- globe, banded latitudes, great rust storm, silky ring system
        local p1R    = 170
        local p1Pos  = HOLE + Vector3.new(-0.6, 0.22, 0.76).Unit * 745
        local p1Tilt = CFrame.Angles(math.rad(11), 0, math.rad(-7))
        local p1CF   = CFrame.new(p1Pos) * p1Tilt
        part({
            Name         = "BH_Planet1",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p1R * 2,
            Color        = Color3.fromRGB(206, 172, 128),
            Material     = Enum.Material.SmoothPlastic,
            Reflectance  = 0,
            CFrame       = CFrame.new(p1Pos),
        })
        local sp1 = { cf0 = p1CF, spd = 0.020, kids = {} }
        -- weather belts: vertical beam strips tangent to the globe
        band(p1CF, p1R,   0, 0.085 * p1R, Color3.fromRGB(228, 198, 152), 0.10, 1.2)
        band(p1CF, p1R,  14, 0.065 * p1R, Color3.fromRGB(176, 132,  92), 0.16, 1.1)
        band(p1CF, p1R, -12, 0.070 * p1R, Color3.fromRGB(214, 178, 132), 0.14, 1.1)
        band(p1CF, p1R,  28, 0.050 * p1R, Color3.fromRGB(196, 152, 110), 0.20, 1.0)
        band(p1CF, p1R, -26, 0.058 * p1R, Color3.fromRGB(168, 124,  88), 0.18, 1.0)
        band(p1CF, p1R,  44, 0.042 * p1R, Color3.fromRGB(222, 190, 146), 0.24, 0.9)
        band(p1CF, p1R, -42, 0.048 * p1R, Color3.fromRGB(182, 140, 100), 0.22, 0.9)
        band(p1CF, p1R,  60, 0.040 * p1R, Color3.fromRGB(206, 172, 132), 0.30, 0.8)
        band(p1CF, p1R, -58, 0.044 * p1R, Color3.fromRGB(178, 140, 104), 0.28, 0.8)
        band(p1CF, p1R,  76, 0.050 * p1R, Color3.fromRGB(160, 130, 104), 0.38, 0.7)
        -- the great rust storm + small ovals: tiny tangent blobs (melt together)
        patch(sp1, p1R, 2.10, -0.38, 30, 20, 9, Color3.fromRGB(188, 92, 58),  0.10)
        patch(sp1, p1R, 2.16, -0.38, 18, 11, 7, Color3.fromRGB(214, 120, 76), 0.18)
        patch(sp1, p1R, 4.40,  0.22, 10,  7, 5, Color3.fromRGB(236, 214, 178), 0.25)
        patch(sp1, p1R, 5.10,  0.30,  8,  6, 5, Color3.fromRGB(236, 214, 178), 0.30)
        patch(sp1, p1R, 0.90,  0.12,  9,  6, 5, Color3.fromRGB(240, 220, 186), 0.30)
        patch(sp1, p1R, 3.60, -0.10, 11,  7, 5, Color3.fromRGB(150, 110, 80),  0.30)
        patch(sp1, p1R, 1.60,  0.42, 10,  7, 5, Color3.fromRGB(150, 112, 82),  0.32)
        spinners[#spinners + 1] = sp1
        -- faint rim glow so the night limb stays readable
        part({
            Name         = "BH_Planet1Shell",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p1R * 2 * 1.012,
            Color        = Color3.fromRGB(214, 180, 136),
            Transparency = 0.93,
            CFrame       = CFrame.new(p1Pos),
        })
        -- ring system: silky beam rings with real gaps between them
        local ringCF = p1CF * CFrame.Angles(math.rad(18), 0, math.rad(6))
        beamRing(ringCF, 210, 2.2, Color3.fromRGB(226, 202, 164), 0.30, 0.060, 1.4, isTouch and 32 or 48)
        beamRing(ringCF, 226, 3.0, Color3.fromRGB(236, 212, 172), 0.18, 0.050, 1.6, isTouch and 32 or 48)
        beamRing(ringCF, 244, 1.6, Color3.fromRGB(214, 188, 148), 0.58, 0.045, 1.1, isTouch and 32 or 48) -- Cassini gap
        beamRing(ringCF, 260, 3.4, Color3.fromRGB(232, 206, 166), 0.24, 0.040, 1.5, isTouch and 32 or 48)
        beamRing(ringCF, 272, 1.8, Color3.fromRGB(206, 180, 140), 0.64, 0.030, 1.0, isTouch and 32 or 48)
        -- shimmering dust riding the main band (8 orbiting emitters)
        do
            local kids = {}
            for ai = 1, 8 do
                local a  = (ai / 8) * math.pi * 2
                local em = part({
                    Name         = "BH_RingSpark",
                    Size         = Vector3.new(2, 2, 2),
                    Transparency = 1,
                    CFrame       = ringCF * CFrame.new(math.cos(a) * 236, 0, math.sin(a) * 236),
                })
                local pe = Instance.new("ParticleEmitter")
                pe.Texture        = "rbxasset://textures/particles/sparkles_main.dds"
                pe.Rate           = isTouch and 2.5 or 5
                pe.Speed          = NumberRange.new(0, 0.2)
                pe.Lifetime       = NumberRange.new(0.9, 1.6)
                pe.LightEmission  = 1
                pe.LightInfluence = 0
                pe.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.4),
                    NumberSequenceKeypoint.new(1, 1.0),
                })
                pe.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.35),
                    NumberSequenceKeypoint.new(1, 1),
                })
                pe.Color  = ColorSequence.new(Color3.fromRGB(238, 216, 182), Color3.fromRGB(216, 186, 146))
                pe.Parent = em
                kids[#kids + 1] = { p = em, off = CFrame.new(math.cos(a) * 236, 0, math.sin(a) * 236) }
            end
            spinners[#spinners + 1] = { cf0 = ringCF, spd = 0.10, kids = kids }
        end
        -- key + fill lights on the day side (the disk side)
        dayLight(p1Pos, p1R, Color3.fromRGB(255, 214, 160), 2.2, 4)
        dayLight(p1Pos, p1R, Color3.fromRGB(255, 214, 160), 0.7, 44)

        -- P2: ice giant (cold azure, far side): subtle methane bands, a deep
        -- storm eye, thick glowing atmosphere shell, own day light
        local p2R   = 130
        local p2Pos = HOLE + Vector3.new(0.55, -0.18, 0.62).Unit * 820
        local p2Tilt = CFrame.Angles(math.rad(-8), 0, math.rad(10))
        local p2CF  = CFrame.new(p2Pos) * p2Tilt
        part({
            Name         = "BH_Planet2",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p2R * 2,
            Color        = Color3.fromRGB(66, 104, 178),
            Material     = Enum.Material.SmoothPlastic,
            Reflectance  = 0,
            CFrame       = CFrame.new(p2Pos),
        })
        band(p2CF, p2R,   0, 0.070 * p2R, Color3.fromRGB(88, 128, 198),  0.16, 1.0)
        band(p2CF, p2R,  20, 0.050 * p2R, Color3.fromRGB(104, 146, 214), 0.24, 0.9)
        band(p2CF, p2R, -20, 0.054 * p2R, Color3.fromRGB(74, 112, 186),  0.22, 0.9)
        band(p2CF, p2R,  38, 0.042 * p2R, Color3.fromRGB(96, 138, 206),  0.30, 0.8)
        band(p2CF, p2R, -38, 0.046 * p2R, Color3.fromRGB(70, 108, 182),  0.28, 0.8)
        band(p2CF, p2R,  58, 0.044 * p2R, Color3.fromRGB(86, 124, 194),  0.36, 0.7)
        local sp2 = { cf0 = p2CF, spd = 0.030, kids = {} }
        patch(sp2, p2R, 4.4, 0.28, 14,  9, 5, Color3.fromRGB(46, 82, 148),  0.14)
        patch(sp2, p2R, 1.2, -0.15, 10,  7, 5, Color3.fromRGB(58, 94, 162), 0.20)
        patch(sp2, p2R, 2.8,  0.44,  8,  6, 4, Color3.fromRGB(52, 88, 156), 0.24)
        spinners[#spinners + 1] = sp2
        part({ -- methane glow limb
            Name         = "BH_Planet2Shell",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p2R * 2 * 1.035,
            Color        = Color3.fromRGB(140, 190, 255),
            Transparency = 0.90,
            CFrame       = CFrame.new(p2Pos),
        })
        part({
            Name         = "BH_Planet2Haze",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p2R * 2 * 1.09,
            Color        = Color3.fromRGB(110, 160, 240),
            Transparency = 0.955,
            CFrame       = CFrame.new(p2Pos),
        })
        beamRing(CFrame.new(p2Pos) * p2Tilt * CFrame.Angles(math.rad(-72), 0, math.rad(22)),
            176, 1.4, Color3.fromRGB(150, 190, 250), 0.74, 0.030, 1.0, isTouch and 30 or 44)
        dayLight(p2Pos, p2R, Color3.fromRGB(200, 220, 255), 2.0, 4)
        dayLight(p2Pos, p2R, Color3.fromRGB(200, 220, 255), 0.6, 36)

        -- P3: red rock world (Mars-like): dark maria + bright highlands as
        -- dozens of tiny mottle blobs, white polar caps as tight band stacks,
        -- thin dusty glow, orbiting gray moon
        local p3R   = 92
        local p3Pos = HOLE + Vector3.new(0.2, 0.35, -0.85).Unit * 690
        local p3CF  = CFrame.new(p3Pos)
        part({
            Name         = "BH_Planet3",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p3R * 2,
            Color        = Color3.fromRGB(172, 94, 56),
            Material     = Enum.Material.SmoothPlastic,
            Reflectance  = 0,
            CFrame       = CFrame.new(p3Pos),
        })
        local sp3 = { cf0 = p3CF, spd = 0.045, kids = {} }
        -- dark maria (small tangent blobs that melt into mottling)
        patch(sp3, p3R, 0.8,  0.10, 11,  8, 5, Color3.fromRGB(118, 58, 34), 0.28)
        patch(sp3, p3R, 2.4, -0.22, 10,  7, 5, Color3.fromRGB(118, 58, 34), 0.32)
        patch(sp3, p3R, 4.0,  0.30,  9,  6, 4, Color3.fromRGB(110, 54, 32), 0.34)
        patch(sp3, p3R, 5.3, -0.05, 11,  8, 5, Color3.fromRGB(124, 62, 36), 0.30)
        patch(sp3, p3R, 1.6, -0.38,  8,  6, 4, Color3.fromRGB(118, 58, 34), 0.36)
        patch(sp3, p3R, 3.2,  0.20,  9,  6, 4, Color3.fromRGB(114, 56, 34), 0.34)
        patch(sp3, p3R, 5.9, -0.28,  8,  6, 4, Color3.fromRGB(118, 58, 34), 0.36)
        patch(sp3, p3R, 4.7, -0.44,  7,  5, 4, Color3.fromRGB(110, 54, 32), 0.38)
        patch(sp3, p3R, 2.0,  0.48,  7,  5, 4, Color3.fromRGB(118, 58, 34), 0.40)
        patch(sp3, p3R, 0.3, -0.52,  7,  5, 4, Color3.fromRGB(114, 56, 34), 0.40)
        patch(sp3, p3R, 5.6,  0.14,  8,  6, 4, Color3.fromRGB(120, 60, 36), 0.36)
        patch(sp3, p3R, 1.1,  0.30,  7,  5, 4, Color3.fromRGB(118, 58, 34), 0.38)
        -- bright highlands + a canyon slash
        patch(sp3, p3R, 3.2,  0.20,  9,  6, 4, Color3.fromRGB(218, 160, 108), 0.30)
        patch(sp3, p3R, 5.9, -0.28,  8,  6, 4, Color3.fromRGB(214, 152, 100), 0.32)
        patch(sp3, p3R, 0.6, -0.12,  9,  5, 4, Color3.fromRGB(222, 166, 116), 0.30)
        patch(sp3, p3R, 2.8,  0.40,  7,  5, 4, Color3.fromRGB(216, 158, 108), 0.34)
        patch(sp3, p3R, 4.2, -0.34,  8,  5, 4, Color3.fromRGB(220, 162, 112), 0.34)
        patch(sp3, p3R, 1.9,  0.02, 10,  4, 4, Color3.fromRGB(150, 82, 48),  0.30) -- Valles-like slash
        spinners[#spinners + 1] = sp3
        -- polar caps: tight stacks of thin white bands around each pole
        band(p3CF, p3R,  84, 0.055 * p3R, Color3.fromRGB(244, 248, 252), 0.14, 1.1)
        band(p3CF, p3R,  78, 0.062 * p3R, Color3.fromRGB(240, 244, 250), 0.22, 1.0)
        band(p3CF, p3R,  70, 0.050 * p3R, Color3.fromRGB(238, 242, 248), 0.38, 0.9)
        band(p3CF, p3R, -84, 0.055 * p3R, Color3.fromRGB(244, 248, 252), 0.14, 1.1)
        band(p3CF, p3R, -78, 0.062 * p3R, Color3.fromRGB(240, 244, 250), 0.22, 1.0)
        band(p3CF, p3R, -70, 0.050 * p3R, Color3.fromRGB(238, 242, 248), 0.38, 0.9)
        part({ -- thin dusty atmosphere
            Name         = "BH_Planet3Shell",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p3R * 2 * 1.07,
            Color        = Color3.fromRGB(255, 170, 110),
            Transparency = 0.90,
            CFrame       = CFrame.new(p3Pos),
        })
        dayLight(p3Pos, p3R, Color3.fromRGB(255, 196, 140), 1.8, 4)
        moonP = part({
            Name         = "BH_Moon",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(26, 26, 26),
            Color        = Color3.fromRGB(150, 150, 160),
            Material     = Enum.Material.SmoothPlastic,
            Reflectance  = 0,
            CFrame       = CFrame.new(p3Pos),
        })
        moonLight = part({
            Name         = "BH_MoonLight",
            Size         = Vector3.new(0.4, 0.4, 0.4),
            Transparency = 1,
            Material     = Enum.Material.SmoothPlastic,
            CFrame       = CFrame.new(p3Pos),
        })
        do
            local mpl = Instance.new("PointLight")
            mpl.Color      = Color3.fromRGB(255, 210, 160)
            mpl.Brightness = 1.1
            mpl.Range      = 60
            mpl.Parent     = moonLight
        end
        moonCenter = CFrame.new(p3Pos)
        moonTilt   = CFrame.Angles(math.rad(24), 0, math.rad(10))

        -- P4: molten world near the hole: matte charcoal crust, GLOWING lava
        -- bands (lava is self-luminous, so these strips stay emissive on the
        -- night side), white-hot volcano blobs, ember haze, strong key light
        local p4R   = 64
        local p4Pos = HOLE + Vector3.new(-0.35, 0.4, -0.55).Unit * 430
        local p4CF  = CFrame.new(p4Pos)
        part({
            Name         = "BH_Planet4",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p4R * 2,
            Color        = Color3.fromRGB(46, 24, 16),
            Material     = Enum.Material.SmoothPlastic,
            Reflectance  = 0,
            CFrame       = CFrame.new(p4Pos),
        })
        band(p4CF, p4R,  0, 0.090 * p4R, Color3.fromRGB(255, 140, 40), 0.08, 1.6, { emit = 0.85, inf = 0.15 })
        band(p4CF, p4R, 22, 0.048 * p4R, Color3.fromRGB(255, 90, 20),  0.22, 1.3, { emit = 0.85, inf = 0.15 })
        band(p4CF, p4R, -20, 0.052 * p4R, Color3.fromRGB(255, 120, 30), 0.18, 1.3, { emit = 0.85, inf = 0.15 })
        band(p4CF, p4R, 40, 0.036 * p4R, Color3.fromRGB(255, 105, 25), 0.32, 1.1, { emit = 0.85, inf = 0.15 })
        local sp4 = { cf0 = p4CF, spd = 0.030, kids = {} }
        patch(sp4, p4R, 1.1,  0.15,  8,  6, 4, Color3.fromRGB(255, 180, 70), 0.05, Enum.Material.Neon)
        patch(sp4, p4R, 3.7, -0.25,  7,  5, 4, Color3.fromRGB(255, 160, 60), 0.08, Enum.Material.Neon)
        patch(sp4, p4R, 5.2,  0.40,  6,  4, 3, Color3.fromRGB(255, 150, 50), 0.10, Enum.Material.Neon)
        patch(sp4, p4R, 0.4, -0.35,  6,  4, 3, Color3.fromRGB(255, 170, 65), 0.08, Enum.Material.Neon)
        patch(sp4, p4R, 2.5,  0.05,  7,  5, 4, Color3.fromRGB(255, 155, 55), 0.08, Enum.Material.Neon)
        patch(sp4, p4R, 4.4,  0.28,  5,  4, 3, Color3.fromRGB(255, 145, 45), 0.12, Enum.Material.Neon)
        patch(sp4, p4R, 5.8, -0.10,  6,  4, 3, Color3.fromRGB(255, 165, 60), 0.10, Enum.Material.Neon)
        spinners[#spinners + 1] = sp4
        part({ -- ember haze
            Name         = "BH_Planet4Shell",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p4R * 2 * 1.10,
            Color        = Color3.fromRGB(255, 120, 50),
            Transparency = 0.93,
            CFrame       = CFrame.new(p4Pos),
        })
        dayLight(p4Pos, p4R, Color3.fromRGB(255, 160, 90), 2.4, 4)

        -- P5: ocean paradise: deep-blue marble, green continents + sandy
        -- shores as melted mottle clusters, drifting white cloud strips,
        -- sky-blue atmosphere
        local p5R   = 104
        local p5Pos = HOLE + Vector3.new(0.88, -0.02, 0.42).Unit * 640
        local p5Tilt = CFrame.Angles(math.rad(9), 0, math.rad(-5))
        local p5CF  = CFrame.new(p5Pos) * p5Tilt
        part({
            Name         = "BH_Planet5",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p5R * 2,
            Color        = Color3.fromRGB(22, 66, 128),
            Material     = Enum.Material.SmoothPlastic,
            Reflectance  = 0,
            CFrame       = CFrame.new(p5Pos),
        })
        local sp5 = { cf0 = p5CF, spd = 0.040, kids = {} }
        -- continent clusters: 2-4 overlapping blobs each, no hard outlines
        patch(sp5, p5R, 0.6,  0.12, 15, 11, 7, Color3.fromRGB(66, 128, 80),  0.06)
        patch(sp5, p5R, 0.9,  0.16, 11,  8, 6, Color3.fromRGB(74, 138, 84),  0.08)
        patch(sp5, p5R, 0.4,  0.06,  9,  7, 5, Color3.fromRGB(60, 118, 74),  0.10)
        patch(sp5, p5R, 2.2, -0.25, 13,  9, 6, Color3.fromRGB(74, 138, 84),  0.07)
        patch(sp5, p5R, 2.5, -0.30,  9,  7, 5, Color3.fromRGB(66, 128, 80),  0.10)
        patch(sp5, p5R, 4.1,  0.34, 10,  8, 5, Color3.fromRGB(60, 118, 74),  0.10)
        patch(sp5, p5R, 4.4,  0.28,  8,  6, 5, Color3.fromRGB(70, 132, 82),  0.12)
        patch(sp5, p5R, 5.5, -0.08, 14, 10, 6, Color3.fromRGB(70, 132, 82),  0.07)
        patch(sp5, p5R, 5.8, -0.14, 10,  7, 5, Color3.fromRGB(62, 120, 76),  0.10)
        patch(sp5, p5R, 3.3,  0.45,  8,  6, 5, Color3.fromRGB(66, 124, 78),  0.12)
        patch(sp5, p5R, 3.0,  0.40,  7,  5, 4, Color3.fromRGB(74, 138, 84),  0.14)
        -- sandy shores + a small archipelago
        patch(sp5, p5R, 1.4, -0.40,  9,  7, 5, Color3.fromRGB(188, 164, 116), 0.20)
        patch(sp5, p5R, 4.8,  0.02,  8,  6, 5, Color3.fromRGB(192, 168, 120), 0.22)
        patch(sp5, p5R, 1.7, -0.44,  6,  4, 4, Color3.fromRGB(196, 172, 124), 0.24)
        patch(sp5, p5R, 2.6,  0.02,  5,  4, 4, Color3.fromRGB(190, 166, 118), 0.26)
        patch(sp5, p5R, 0.2,  0.36,  6,  4, 4, Color3.fromRGB(186, 162, 114), 0.26)
        spinners[#spinners + 1] = sp5
        -- cloud strips: soft smoke texture, drifting slowly with the spin
        band(p5CF, p5R,   0, 0.060 * p5R, Color3.fromRGB(245, 248, 252), 0.34, 0.9,
            { tex = "rbxasset://textures/particles/smoke_main.dds", texRep = 8, spd = 0.030 })
        band(p5CF, p5R,  18, 0.046 * p5R, Color3.fromRGB(240, 244, 250), 0.42, 0.8,
            { tex = "rbxasset://textures/particles/smoke_main.dds", texRep = 8, spd = 0.022 })
        band(p5CF, p5R, -20, 0.050 * p5R, Color3.fromRGB(240, 244, 250), 0.40, 0.8,
            { tex = "rbxasset://textures/particles/smoke_main.dds", texRep = 8, spd = -0.026 })
        band(p5CF, p5R,  40, 0.040 * p5R, Color3.fromRGB(238, 242, 248), 0.48, 0.7,
            { tex = "rbxasset://textures/particles/smoke_main.dds", texRep = 8, spd = 0.016 })
        band(p5CF, p5R, -42, 0.044 * p5R, Color3.fromRGB(238, 242, 248), 0.46, 0.7,
            { tex = "rbxasset://textures/particles/smoke_main.dds", texRep = 8, spd = -0.018 })
        part({ -- sky-blue atmosphere limb
            Name         = "BH_Planet5Shell",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p5R * 2 * 1.055,
            Color        = Color3.fromRGB(120, 180, 255),
            Transparency = 0.88,
            CFrame       = CFrame.new(p5Pos),
        })
        part({
            Name         = "BH_Planet5Haze",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p5R * 2 * 1.11,
            Color        = Color3.fromRGB(96, 156, 236),
            Transparency = 0.95,
            CFrame       = CFrame.new(p5Pos),
        })
        dayLight(p5Pos, p5R, Color3.fromRGB(235, 240, 255), 2.0, 4)
        dayLight(p5Pos, p5R, Color3.fromRGB(235, 240, 255), 0.6, 38)

        -- P6: pale ice dwarf: arctic globe, frost bands, cold blue glow
        local p6R   = 58
        local p6Pos = HOLE + Vector3.new(-0.75, -0.25, -0.45).Unit * 900
        local p6CF  = CFrame.new(p6Pos)
        part({
            Name         = "BH_Planet6",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p6R * 2,
            Color        = Color3.fromRGB(188, 206, 224),
            Material     = Enum.Material.SmoothPlastic,
            Reflectance  = 0,
            CFrame       = CFrame.new(p6Pos),
        })
        band(p6CF, p6R,   0, 0.075 * p6R, Color3.fromRGB(206, 222, 238), 0.12, 1.0)
        band(p6CF, p6R,  30, 0.050 * p6R, Color3.fromRGB(172, 194, 216), 0.20, 0.9)
        band(p6CF, p6R, -30, 0.054 * p6R, Color3.fromRGB(166, 190, 214), 0.18, 0.9)
        band(p6CF, p6R,  54, 0.042 * p6R, Color3.fromRGB(196, 214, 232), 0.28, 0.8)
        local sp6 = { cf0 = p6CF, spd = 0.020, kids = {} }
        patch(sp6, p6R, 1.8,  0.18,  7,  5, 4, Color3.fromRGB(158, 180, 202), 0.24)
        patch(sp6, p6R, 4.3, -0.30,  6,  4, 3, Color3.fromRGB(164, 186, 208), 0.26)
        patch(sp6, p6R, 3.0,  0.42,  5,  4, 3, Color3.fromRGB(214, 228, 242), 0.22)
        spinners[#spinners + 1] = sp6
        part({
            Name         = "BH_Planet6Shell",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * p6R * 2 * 1.08,
            Color        = C_ICE,
            Transparency = 0.92,
            CFrame       = CFrame.new(p6Pos),
        })
        dayLight(p6Pos, p6R, Color3.fromRGB(210, 230, 255), 1.4, 4)
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
        -- sweeping dust anchors + breathing glow rings
        dustIn.CFrame  = diskBase0 * CFrame.new(0, 2.0, 0) * CFrame.Angles(0,  t * 0.9, 0)
        dustOut.CFrame = diskBase0 * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, -t * 0.3, 0)
        -- photon ring + lensed halo always face the camera (lensing artifact:
        -- the ring reads as a perfect circle around the shadow from ANY angle)
        local camFx = workspace.CurrentCamera
        if camFx then
            local lookCF = CFrame.lookAt(HOLE, camFx.CFrame.Position)
            photonA.CFrame = lookCF
            photonB.CFrame = lookCF
            haloA.CFrame   = lookCF
        end
        for _, fx in ipairs(ringFX) do
            local k = fx.base + fx.amp * (0.5 + 0.5 * math.sin(t * fx.freq + fx.ph))
            local seq = NumberSequence.new(k) -- ONE alloc per ring, not per beam (REV-A/C)
            for _, b in ipairs(fx.beams) do
                b.Transparency = seq
            end
        end
        -- Doppler beaming (v4.0): the side of the disk moving TOWARD the camera
        -- burns brighter -- the signature Gargantua asymmetry, tracked live as
        -- the camera orbits (relativistic beaming, no per-frame allocations)
        if camFx and #dopRings > 0 then
            local cp = camFx.CFrame.Position
            for _, dr in ipairs(dopRings) do
                for i = 1, #dr.beams do
                    local toCam = cp - dr.mids[i]
                    if toCam.Magnitude > 1 then
                        local d = dr.dirs[i]:Dot(toCam.Unit)
                        dr.beams[i].Brightness = dr.brBase * (1 + 0.42 * d)
                    end
                end
            end
        end
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
                * CFrame.new(hs.r + w, hs.hgt + 2.8, 0)
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
                    * CFrame.new(f.r, 2.4, 0)
            else
                f.part.Transparency = 1
            end
        end
    end

    -- orbiting moon around the red rock world (+ its day light follows)
    local function updateMoon(t)
        if moonP then
            local mc = moonCenter * moonTilt
                * CFrame.Angles(0, t * 0.18, 0)
                * CFrame.new(150, 0, 0)
            moonP.CFrame = mc
            if moonLight then
                local mp  = mc.Position
                local dir = (HOLE - mp).Unit
                moonLight.CFrame = CFrame.new(mp + dir * 17)
            end
        end
    end

    -- rotating surface details (continents / clouds / ring sparkles) -- v3.6
    local function updatePlanets(t)
        for _, sp in ipairs(spinners) do
            local w = sp.cf0 * CFrame.Angles(0, t * sp.spd, 0)
            for _, k in ipairs(sp.kids) do
                k.p.CFrame = w * k.off
            end
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
                local R = 30 + 70 * (1 - (1 - k) * (1 - k)) -- capped inside the closest camera pass (REV-B)
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
            emergencyRestore() -- full teardown, not just the gui (REV-C)
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
            if genv.LEGENDS_INTRO_TOKEN == myToken then -- a newer run owns the bind (REV-A)
                RunService:UnbindFromRenderStep("LEGENDS_Cam")
            end
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
        Lighting.Brightness = 0 -- REV-C: hosts may rewrite these every frame too
        Lighting.Ambient    = Color3.new(0, 0, 0)
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
        updatePlanets(t)

        shockPulse = shockPulse * (1 - dt * 2.2)
        glowPulse  = glowPulse * (1 - dt * 3)

        blur.Size      = math.min(shockPulse * 14 + dive * 22, isTouch and 14 or 40)
        cc.Brightness  = shockPulse * 0.10 - dive * 0.08
        cc.Contrast    = 0.08 + dive * 0.22
        cc.Saturation  = -0.05 - dive * 0.25
        cc.TintColor   = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 172, 110), dive)
        local bloomCap = isTouch and 2.0 or 2.9
        if dive > 0.5 then
            bloomCap = math.min(bloomCap, 1.35) -- REV-B: keep the plunge readable, no whiteout
        end
        bloom.Intensity = math.min(1.55 + 0.35 * math.sin(t * 1.3) + shockPulse * 0.7 + glowPulse * 0.35, bloomCap)

        glow.Size         = Vector3.new(1, 1, 1) * (64 + glowPulse * 9)
        glow.Transparency = 0.95 - glowPulse * 0.04 -- v4.0: softer halo, bloom does the work
        plight.Brightness = 2.4 + glowPulse * 1.8
        core.Size         = Vector3.new(1, 1, 1) * (44 + 1.0 * math.sin(t * 2.6) + math.min(glowPulse, 0.5) * 1.2) -- capped: photon ring hugs at 24.5, never swallowed (REV-B/v4.0)

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
        if dead or genv.LEGENDS_INTRO_TOKEN ~= myToken then return end
        if not sceneFolder.Parent then -- external wipe: restore instead of idling (REV-C)
            cleanup()
            return
        end
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
