--=====================================================================
--  LEGENDS  |  BLACK HOLE CINEMATIC INTRO  --  V3
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
    HOLE_POS     = Vector3.new(0, 1500, 0),
    STAR_COUNT   = 170,
    DEBRIS_COUNT = 44,
    SHOCK_TIMES  = {13, 20, 27, 34, 41, 47},
    SUCK_EVERY   = 2.8,
}

local C_HOT    = Color3.fromRGB(255, 240, 214)
local C_EMBER  = Color3.fromRGB(255, 160, 82)
local C_PLASMA = Color3.fromRGB(196, 84, 130)
local C_STAR   = Color3.fromRGB(214, 226, 255)
local C_ICE    = Color3.fromRGB(170, 190, 255)

local function destroyPrevious()
    local roots = {workspace, Lighting}
    pcall(function()
        table.insert(roots, CoreGui)
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
    local glowPulse   = 0
    local shockPulse  = 0
    local saved       = {}

    local cam = workspace.CurrentCamera
    if not cam then
        cam = workspace:WaitForChild("Camera", 5)
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
    saved.skyProps = nil
    local oldSky = Lighting:FindFirstChildOfClass("Sky")
    if oldSky then
        saved.skyProps = {
            obj = oldSky,
            Bk = oldSky.SkyboxBk, Dn = oldSky.SkyboxDn, Ft = oldSky.SkyboxFt,
            Lf = oldSky.SkyboxLf, Rt = oldSky.SkyboxRt, Up = oldSky.SkyboxUp,
            SunVisible = oldSky.SunVisible, MoonVisible = oldSky.MoonVisible,
            StarCount = oldSky.StarCount,
        }
        pcall(function()
            oldSky.SkyboxBk = ""
            oldSky.SkyboxDn = ""
            oldSky.SkyboxFt = ""
            oldSky.SkyboxLf = ""
            oldSky.SkyboxRt = ""
            oldSky.SkyboxUp = ""
            oldSky.SunVisible = false
            oldSky.MoonVisible = false
            oldSky.StarCount = 0
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
        atmo.Density = 0
        atmo.Haze = 0
        atmo.Glare = 0
    end

    --[[ lighting ]]--
    Lighting.Brightness           = 0
    Lighting.Ambient              = Color3.fromRGB(8, 8, 16)
    Lighting.OutdoorAmbient       = Color3.fromRGB(14, 14, 26)
    Lighting.ClockTime            = 0
    Lighting.FogColor             = Color3.fromRGB(6, 6, 14)
    Lighting.FogStart             = 250
    Lighting.FogEnd               = 4000
    Lighting.GlobalShadows        = false
    Lighting.ExposureCompensation = 0.05

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name       = "LEGENDS_CC"
    cc.Brightness = 0
    cc.Contrast   = 0.08
    cc.Saturation = -0.05
    cc.Parent     = Lighting

    local blur = Instance.new("BlurEffect")
    blur.Name  = "LEGENDS_Blur"
    blur.Size  = 0
    blur.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name      = "LEGENDS_Bloom"
    bloom.Intensity = 1.0
    bloom.Size      = 40
    bloom.Threshold = 1.35
    bloom.Parent    = Lighting

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
    end

    --[[ space enclosure -- guaranteed void background ]]--
    part({
        Name     = "BH_Space",
        Size     = Vector3.new(4000, 4000, 4000),
        Color    = Color3.new(0, 0, 0),
        Material = Enum.Material.SmoothPlastic,
        CFrame   = CFrame.new(HOLE),
    })

    --[[ the hole ]]--
    local core = part({
        Name     = "BH_Core",
        Shape    = Enum.PartType.Ball,
        Size     = Vector3.new(26, 26, 26),
        Color    = Color3.new(0, 0, 0),
        Material = Enum.Material.SmoothPlastic,
        CFrame   = CFrame.new(HOLE),
    })

    local plight = Instance.new("PointLight")
    plight.Color      = C_HOT
    plight.Brightness = 1.5
    plight.Range      = 60
    plight.Parent     = core

    local glow = part({
        Name         = "BH_Glow",
        Shape        = Enum.PartType.Ball,
        Size         = Vector3.new(40, 40, 40),
        Color        = C_HOT,
        Transparency = 0.95,
        CFrame       = CFrame.new(HOLE),
    })

    -- photon ring
    local PHOTON_N   = 36
    local photonTilt = CFrame.Angles(math.rad(18), 0, math.rad(10))
    local photonSegs = {}
    for i = 1, PHOTON_N do
        photonSegs[i] = part({
            Name         = "BH_Photon",
            Size         = Vector3.new(0.5, 0.5, 2.4),
            Color        = C_HOT,
            Transparency = 0.12,
            CFrame       = CFrame.new(HOLE),
        })
    end

    -- lensed halo ring (vertical, Interstellar-style)
    local LENS_N   = 40
    local lensTilt = diskTilt * CFrame.Angles(math.rad(90), 0, 0)
    local lensSegs = {}
    for i = 1, LENS_N do
        lensSegs[i] = part({
            Name         = "BH_Lens",
            Size         = Vector3.new(0.4, 0.4, 2.0),
            Color        = C_HOT,
            Transparency = 0.55,
            CFrame       = CFrame.new(HOLE),
        })
    end

    -- accretion disk (inner rings spin faster - Keplerian)
    local diskTilt = CFrame.Angles(math.rad(22), 0, math.rad(-8))
    local rings = {
        {r = 24, n = 40, speed = 1.60, color = C_HOT,    sx = 1.5, sy = 0.9, sz = 3.0, base = 0.10},
        {r = 33, n = 42, speed = 0.95, color = C_EMBER,  sx = 1.3, sy = 0.8, sz = 3.8, base = 0.20},
        {r = 44, n = 46, speed = 0.60, color = C_PLASMA, sx = 1.2, sy = 0.7, sz = 4.6, base = 0.30},
    }
    local diskSegs = {}
    for ri, ring in ipairs(rings) do
        for i = 1, ring.n do
            local seg = part({
                Name         = "BH_Disk",
                Size         = Vector3.new(ring.sx, ring.sy, ring.sz),
                Color        = ring.color,
                Transparency = ring.base,
                CFrame       = CFrame.new(HOLE),
            })
            diskSegs[#diskSegs + 1] = {
                part   = seg,
                ring   = ri,
                i      = i,
                n      = ring.n,
                jitter = math.random() * math.pi * 2,
            }
        end
    end

    -- infalling debris
    local debris = {}
    for i = 1, CONFIG.DEBRIS_COUNT do
        local d = part({
            Name   = "BH_Debris",
            Size   = Vector3.new(1, 1, 1),
            Color  = C_ICE,
            CFrame = CFrame.new(HOLE),
        })
        debris[i] = {
            part = d,
            r    = 60 + math.random() * 100,
            ang  = math.random() * math.pi * 2,
            h    = (math.random() - 0.5) * 60,
            spd  = 0.4 + math.random() * 0.5,
        }
        addTrail(d, C_ICE)
    end

    -- starfield
    local stars = {}
    for i = 1, CONFIG.STAR_COUNT do
        local dist = 260 + math.random() * 560
        local pos  = HOLE + randomUnit() * dist
        local s = part({
            Name         = "BH_Star",
            Size         = Vector3.new(1, 1, 1) * (0.7 + math.random() * 1.2),
            Color        = C_STAR,
            Transparency = 0.05 + math.random() * 0.35,
            CFrame       = CFrame.new(pos),
        })
        stars[i] = {
            part = s, home = pos, size = s.Size, color = s.Color,
            sucked = false, p = 0, r0 = 0, a0 = 0, h0 = 0,
        }
    end

    -- twinkling stars subset
    local twinkle = {}
    for i = 1, 50 do
        twinkle[i] = {
            part  = stars[math.random(#stars)].part,
            phase = math.random() * math.pi * 2,
        }
    end

    -- nebula blobs
    local nebColors = {
        Color3.fromRGB(88, 58, 158),
        Color3.fromRGB(44, 74, 158),
        Color3.fromRGB(138, 42, 118),
        Color3.fromRGB(30, 96, 138),
    }
    for i = 1, 8 do
        local dir = randomUnit()
        dir = Vector3.new(dir.X, math.abs(dir.Y) * 0.6 + 0.05, dir.Z)
        if dir.Magnitude < 0.05 then
            dir = Vector3.new(1, 0.2, 0)
        end
        dir = dir.Unit
        local dist = 420 + math.random() * 380
        part({
            Name         = "BH_Nebula",
            Shape        = Enum.PartType.Ball,
            Size         = Vector3.new(1, 1, 1) * (90 + math.random() * 90),
            Color        = nebColors[(i % #nebColors) + 1],
            Transparency = 0.955,
            CFrame       = CFrame.new(HOLE + dir * dist),
        })
    end

    -- distant galaxy swirl
    local galaxyCF = CFrame.new(HOLE + Vector3.new(480, 190, -420))
        * CFrame.Angles(math.rad(60), 0, math.rad(20))
    for i = 1, 46 do
        local a  = math.random() * math.pi * 2
        local rr = 6 + math.random() * 55
        local y  = (math.random() - 0.5) * 4
        part({
            Name         = "BH_GalStar",
            Size         = Vector3.new(1, 1, 1) * (0.6 + math.random() * 0.9),
            Color        = C_ICE:Lerp(C_HOT, math.random()),
            Transparency = 0.1 + math.random() * 0.4,
            CFrame       = galaxyCF * CFrame.Angles(0, a, 0) * CFrame.new(rr, y, 0),
        })
    end

    -- shockwaves
    local shocks = {}
    local function spawnShock()
        local list = {}
        for i = 1, 32 do
            list[i] = part({
                Name         = "BH_Shock",
                Size         = Vector3.new(0.8, 0.8, 10),
                Color        = C_HOT,
                Transparency = 0.35,
                CFrame       = CFrame.new(HOLE),
            })
        end
        shocks[#shocks + 1] = {segs = list, t = 0}
    end

    --[[ per-frame updates ]]--
    local function updatePhoton(t)
        for i = 1, PHOTON_N do
            local a = (i / PHOTON_N) * math.pi * 2 + t * 0.15
            photonSegs[i].Transparency = 0.10 + 0.10 * math.sin(t * 3 + i * 0.9)
            photonSegs[i].CFrame = CFrame.new(HOLE) * photonTilt
                * CFrame.Angles(0, a, 0)
                * CFrame.new(21, 0, 0)
        end
    end

    local function updateLens(t)
        for i = 1, LENS_N do
            local a = (i / LENS_N) * math.pi * 2 - t * 0.10
            lensSegs[i].Transparency = 0.50 + 0.12 * math.sin(t * 2 + i * 1.3)
            lensSegs[i].CFrame = CFrame.new(HOLE) * lensTilt
                * CFrame.Angles(0, a, 0)
                * CFrame.new(25, 0, 0)
        end
    end

    local function updateTwinkle(t)
        for _, tk in ipairs(twinkle) do
            tk.part.Transparency = 0.12 + 0.3 * (0.5 + 0.5 * math.sin(t * 2.5 + tk.phase))
        end
    end

    local function updateDisk(t)
        for _, s in ipairs(diskSegs) do
            local ring = rings[s.ring]
            local a  = (s.i / s.n) * math.pi * 2 + t * ring.speed + s.jitter * 0.05
            local rr = ring.r + 0.8 * math.sin(t * 2 + s.jitter)
            s.part.Transparency = ring.base + 0.12 * math.sin(t * 3 + s.jitter)
            s.part.CFrame = CFrame.new(HOLE) * diskTilt
                * CFrame.Angles(0, a, 0)
                * CFrame.new(rr, 0, 0)
        end
    end

    local function updateDebris(dt)
        for _, d in ipairs(debris) do
            d.r   = d.r - dt * (5 + (130 - d.r) * 0.045)
            d.ang = d.ang + dt * d.spd * (1 + 45 / (d.r + 8))
            d.h   = d.h * (1 - dt * 1.2)
            if d.r < 18 then
                glowPulse = math.min(glowPulse + 0.25, 2)
                d.r   = 95 + math.random() * 70
                d.ang = math.random() * math.pi * 2
                d.h   = (math.random() - 0.5) * 70
            end
            local k = math.clamp(1 - (d.r - 18) / 120, 0, 1)
            d.part.Color        = C_ICE:Lerp(C_HOT, k)
            d.part.Size         = Vector3.new(1, 1, 1) * (0.6 + k * 0.9)
            d.part.Transparency = 0.15 + 0.4 * (1 - k)
            d.part.CFrame = CFrame.new(HOLE) * diskTilt
                * CFrame.Angles(0, d.ang, 0)
                * CFrame.new(d.r, d.h, 0)
        end
    end

    local suckTimer = 0

    local function pickSucked()
        local picked = 0
        for _, st in ipairs(stars) do
            if picked >= 3 then break end
            if not st.sucked then
                local off = st.home - HOLE
                st.sucked = true
                st.p  = 0
                st.r0 = off.Magnitude
                st.a0 = math.atan2(off.Z, off.X)
                st.h0 = off.Y
                picked = picked + 1
            end
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
                    local rr = st.r0 * (1 - st.p) ^ 1.25 + 8
                    local aa = st.a0 + st.p * 7
                    local hh = st.h0 * (1 - st.p)
                    st.part.Color = C_STAR:Lerp(C_HOT, st.p)
                    local off = Vector3.new(math.cos(aa) * rr, hh, math.sin(aa) * rr)
                    st.part.CFrame = CFrame.new(HOLE + off)
                end
            end
        end
    end

    local function updateShocks(dt)
        for idx = #shocks, 1, -1 do
            local sh = shocks[idx]
            sh.t = sh.t + dt
            local k = sh.t / 1.7
            if k >= 1 then
                for _, sgm in ipairs(sh.segs) do
                    sgm:Destroy()
                end
                table.remove(shocks, idx)
            else
                local R  = 16 + 104 * (1 - (1 - k) * (1 - k))
                local tr = 0.3 + 0.7 * k
                for i, sgm in ipairs(sh.segs) do
                    local a = (i / #sh.segs) * math.pi * 2
                    sgm.Transparency = tr
                    sgm.CFrame = CFrame.new(HOLE) * diskTilt
                        * CFrame.Angles(0, a, 0)
                        * CFrame.new(R, 0, 0)
                end
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
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
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
    vignette(90,  UDim2.new(0, 0, 0, 0),    UDim2.new(1, 0, 0, 150))
    vignette(-90, UDim2.new(0, 0, 1, -150), UDim2.new(1, 0, 0, 150))
    vignette(0,   UDim2.new(0, 0, 0, 0),    UDim2.new(0, 150, 1, 0))
    vignette(180, UDim2.new(1, -150, 0, 0), UDim2.new(0, 150, 1, 0))

    local blackout = newFrame(8, 1)
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
    presents.TextColor3              = Color3.fromRGB(226, 232, 244)
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
    tg.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(168, 178, 198))
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
    sub.TextColor3             = Color3.fromRGB(205, 214, 232)
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
    sub2.TextColor3             = Color3.fromRGB(168, 178, 198)
    sub2.TextTransparency       = 1
    sub2.ZIndex                 = 10
    sub2.Parent                 = gui

    -- skip button
    local skip = Instance.new("TextButton")
    skip.AnchorPoint            = Vector2.new(1, 1)
    skip.Position               = UDim2.new(1, -18, 1, -18)
    skip.Size                   = UDim2.new(0, 132, 0, 36)
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
    skStroke.Color        = Color3.fromRGB(120, 130, 160)
    skStroke.Transparency = 0.4
    skStroke.Parent       = skip

    --[[ cleanup ]]--
    cleanup = function()
        if dead then return end
        dead = true
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
            cam.CameraType  = saved.camType or Enum.CameraType.Custom
            cam.FieldOfView = saved.camFOV or 70
            if saved.camCF then
                cam.CFrame = saved.camCF
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
            if saved.skyProps then
                local s = saved.skyProps
                local o = s.obj
                if o and o.Parent then
                    o.SkyboxBk = s.Bk
                    o.SkyboxDn = s.Dn
                    o.SkyboxFt = s.Ft
                    o.SkyboxLf = s.Lf
                    o.SkyboxRt = s.Rt
                    o.SkyboxUp = s.Up
                    o.SunVisible = s.SunVisible
                    o.MoonVisible = s.MoonVisible
                    o.StarCount = s.StarCount
                end
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
            for _, n in ipairs({"LEGENDS_CC", "LEGENDS_Blur", "LEGENDS_Bloom"}) do
                local o = Lighting:FindFirstChild(n)
                if o then
                    o:Destroy()
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

    skip.MouseButton1Click:Connect(function()
        click:Play()
        task.delay(0.08, cleanup)
    end)

    pcall(function()
        local genv = (typeof(getgenv) == "function" and getgenv()) or _G
        genv.LEGENDS_INTRO_STOP = cleanup
    end)

    --[[ camera director ]]--
    cam.CameraType = Enum.CameraType.Scriptable

    local CAM = {
        {t0 = 0,  t1 = 9,  r0 = 560, r1 = 470, h0 = 30,  h1 = 60,  w0 = 0.05, fov0 = 72, fov1 = 64, rollA = 0,  shake = 0.15, a0 = -0.40, ease = 0},
        {t0 = 9,  t1 = 20, r0 = 470, r1 = 200, h0 = 60,  h1 = 85,  w0 = 0.13, fov0 = 64, fov1 = 58, rollA = 4,  shake = 0.30, a0 = 0.05,  ease = 1},
        {t0 = 20, t1 = 34, r0 = 200, r1 = 100, h0 = 85,  h1 = 45,  w0 = 0.21, fov0 = 58, fov1 = 70, rollA = 9,  shake = 0.80, a0 = 1.48,  ease = 1},
        {t0 = 34, t1 = 44, r0 = 100, r1 = 280, h0 = 45,  h1 = 120, w0 = 0.10, fov0 = 70, fov1 = 64, rollA = 3,  shake = 0.40, a0 = 4.42,  ease = 1},
        {t0 = 44, t1 = 52, r0 = 280, r1 = 16,  h0 = 120, h1 = 8,   w0 = 0.27, fov0 = 64, fov1 = 86, rollA = 14, shake = 1.70, a0 = 5.42,  ease = 2},
        {t0 = 52, t1 = 58, r0 = 16,  r1 = 14,  h0 = 8,   h1 = 6,   w0 = 0.15, fov0 = 86, fov1 = 92, rollA = 2,  shake = 0.50, a0 = 7.58,  ease = 0},
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
        tw(presents, {TextTransparency = 0.05, TextStrokeTransparency = 0.6}, 1.6)
    end)
    task.delay(5.5, function()
        tw(presents, {TextTransparency = 1, TextStrokeTransparency = 1}, 1.4)
    end)
    task.delay(44, function()
        if dead then return end
        riser:Play()
        TweenService:Create(riser, TweenInfo.new(7, Enum.EasingStyle.Linear), {Volume = 0.85}):Play()
    end)
    task.delay(49.4, function()
        if dead then return end
        tw(blackout, {BackgroundTransparency = 0}, 2.6)
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
        elapsed  = elapsed + dtStep
        local t  = elapsed

        while shockIdx <= #CONFIG.SHOCK_TIMES and t >= CONFIG.SHOCK_TIMES[shockIdx] do
            shockIdx = shockIdx + 1
            spawnShock()
            boom()
            shockPulse = 1
        end

        suckTimer = suckTimer + dt
        if suckTimer >= CONFIG.SUCK_EVERY then
            suckTimer = 0
            pickSucked()
        end

        updatePhoton(t)
        updateLens(t)
        updateDisk(t)
        updateDebris(dt)
        updateSucked(dt)
        updateShocks(dt)
        updateTwinkle(t)

        shockPulse = shockPulse * (1 - dt * 2.2)
        glowPulse  = glowPulse * (1 - dt * 3)
        local dive = math.clamp((t - 44) / 8, 0, 1)

        blur.Size      = shockPulse * 14 + dive * 22
        cc.Brightness  = shockPulse * 0.10 - dive * 0.08
        cc.Contrast    = 0.08 + dive * 0.22
        cc.Saturation  = -0.05 - dive * 0.25
        cc.TintColor   = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(150, 165, 220), dive)
        bloom.Intensity = math.min(1.15 + 0.35 * math.sin(t * 1.3) + shockPulse * 0.7 + glowPulse * 0.3, 2.2)

        glow.Size         = Vector3.new(1, 1, 1) * (40 + glowPulse * 6)
        glow.Transparency = 0.95 - glowPulse * 0.05
        plight.Brightness = 1.5 + glowPulse * 1.2

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

    loopConn = RunService.RenderStepped:Connect(function(dtStep)
        if dead then return end
        local ok, err = pcall(stepFrame, dtStep)
        if not ok then
            warn("[LEGENDS] frame error:", err)
        end
        if elapsed >= CONFIG.DURATION + 2 then
            cleanup()
        end
    end)
end

--=====================================================================
--  run with full error surface
--=====================================================================
local OK, ERR = pcall(main)
if not OK then
    warn("[LEGENDS] intro error:", ERR)
    pcall(function()
        local g = Instance.new("ScreenGui")
        g.Name          = "LEGENDS_ERR"
        g.DisplayOrder  = 10000
        g.ResetOnSpawn  = false
        local okc = pcall(function()
            g.Parent = game:GetService("CoreGui")
        end)
        if not okc then
            g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
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
