--=====================================================================
--  LEGENDS — BLACK HOLE INTRO (v3)
--  Pure cinematic space scene. NO character, NO fighting.
--  A black hole is born, spins, devours stars, and reveals the title.
--  Duration ~38s | Loader-ready (loadstring safe, no script refs)
--  AR: انترو فضائي كامل — بلاك هول بيتحرك، نجوم بتتسحب جواه، عنوان LEGENDS
--=====================================================================

--===================== SERVICES =====================
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")
local Lighting     = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

--===================== CONFIG =====================
local DURATION        = 38
local S               = DURATION / 38
local SHOW_PHASES     = true
local ENABLE_SKIP     = true
local ENABLE_DEBUG    = false

local C_WHITE  = Color3.fromRGB(255, 255, 255)
local C_SILVER = Color3.fromRGB(196, 204, 214)
local C_BLUE   = Color3.fromRGB(120, 170, 255)
local C_ICE    = Color3.fromRGB(200, 225, 255)
local C_AMBER  = Color3.fromRGB(255, 170, 70)
local C_GOLD   = Color3.fromRGB(255, 205, 110)
local C_EMBER  = Color3.fromRGB(255, 110, 40)
local C_VIOLET = Color3.fromRGB(150, 90, 255)
local C_BLACK  = Color3.fromRGB(0, 0, 0)

--===================== BOOT GUARDS =====================
if RunService:IsServer() and not RunService:IsClient() then
        warn("[LEGENDS v3] Run this on the CLIENT (LocalScript / executor), not a server Script.")
        return
end
local player = Players.LocalPlayer
if not player then
        warn("[LEGENDS v3] No LocalPlayer found.")
        return
end
local playerGui = player:WaitForChild("PlayerGui")

--===================== STATE SAVE =====================
local cam = workspace.CurrentCamera
local savedCameraType   = cam.CameraType
local savedCameraCF     = cam.CFrame
local savedFOV          = cam.FieldOfView
local savedLighting     = {
        Brightness   = Lighting.Brightness,
        Ambient      = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime    = Lighting.ClockTime,
        FogEnd       = Lighting.FogEnd,
        FogColor     = Lighting.FogColor,
}
local savedPost = {}
for _, n in ipairs({"ColorCorrection", "BloomEffect", "DepthOfField", "Atmosphere", "Sky"}) do
        local found = Lighting:FindFirstChild(n)
        if found then savedPost[n] = found end
end

local active     = true
local clock      = 0
local shakeAmp   = 0
local errCount   = 0
local errText    = ""

--===================== CLEANUP REGISTRY =====================
local junk  = {}
local conns = {}
local function track(inst)
        junk[#junk + 1] = inst
        return inst
end
local function conn(c)
        conns[#conns + 1] = c
        return c
end

-- per-phase camera connection : only ONE live at a time
local phaseConn = nil
local function pconn(c)
        if phaseConn then pcall(function() phaseConn:Disconnect() end) end
        phaseConn = c
        return c
end
local function endPhaseConn()
        if phaseConn then
                pcall(function() phaseConn:Disconnect() end)
                phaseConn = nil
        end
end

--===================== SOUND =====================
local function sfx(id, vol, speed)
        local ok = pcall(function()
                local s = Instance.new("Sound")
                s.SoundId = id
                s.Volume = vol or 0.5
                s.PlaybackSpeed = speed or 1
                s.Parent = SoundService
                s:Play()
                track(s)
                task.delay(8, function() s:Destroy() end)
        end)
        return ok
end

local function startAmbience()
        pcall(function()
                local s = Instance.new("Sound")
                s.Name = "LEGENDS_Ambience"
                s.SoundId = "rbxasset://sounds/impact_water.mp3"
                s.Volume = 0.25
                s.Looped = true
                s.PlaybackSpeed = 0.35
                s.Parent = SoundService
                s:Play()
                track(s)
        end)
end

--===================== BUILD HELPERS =====================
local root = track(Instance.new("Folder"))
root.Name = "LEGENDS_BlackHole"

local function part(props, parent)
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Size = Vector3.new(1, 1, 1)
        for k, v in pairs(props or {}) do
                p[k] = v
        end
        p.Parent = parent or root
        return p
end

-- ring built from a cylinder (flat disc) : axis = X
local function ring(radius, thickness, color, transparency, parent)
        return part({
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(thickness, radius * 2, radius * 2),
                Color = color,
                Transparency = transparency or 0,
                Material = Enum.Material.Neon,
        }, parent)
end

--===================== POST FX =====================
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "LEGENDS_CC"
cc.Brightness = 0
cc.Contrast = 0.1
cc.Saturation = -0.15
cc.TintColor = C_WHITE
cc.Parent = Lighting
track(cc)

local bloom = Instance.new("BloomEffect")
bloom.Name = "LEGENDS_Bloom"
bloom.Intensity = 0.9
bloom.Size = 32
bloom.Threshold = 0.85
bloom.Parent = Lighting
track(bloom)

local blur = Instance.new("BlurEffect")
blur.Name = "LEGENDS_Blur"
blur.Size = 0
blur.Parent = Lighting
track(blur)

local sky = Instance.new("Sky")
sky.Name = "LEGENDS_Sky"
sky.SkyboxBk = C_BLACK
sky.SkyboxDn = C_BLACK
sky.SkyboxFt = C_BLACK
sky.SkyboxLf = C_BLACK
sky.SkyboxRt = C_BLACK
sky.SkyboxUp = C_BLACK
sky.StarCount = 0
sky.SunAngularSize = 0
sky.MoonAngularSize = 0
sky.Parent = Lighting
track(sky)

Lighting.Brightness = 1
Lighting.Ambient = Color3.fromRGB(6, 6, 12)
Lighting.OutdoorAmbient = Color3.fromRGB(6, 6, 12)
Lighting.FogEnd = 100000
Lighting.ClockTime = 0

local function setCC(brightness, contrast, sat)
        cc.Brightness = brightness
        cc.Contrast = contrast
        cc.Saturation = sat
end
local function setBloom(i)
        bloom.Intensity = i
end
local function setBlur(s)
        blur.Size = s
end
local function flash(color, peak, dur)
        local f = Instance.new("ColorCorrectionEffect")
        f.Name = "LEGENDS_Flash"
        f.Brightness = peak or 0.4
        f.TintColor = color or C_WHITE
        f.Parent = Lighting
        track(f)
        TweenService:Create(f, TweenInfo.new(dur or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Brightness = 0,
        }):Play()
        task.delay((dur or 0.5) + 0.1, function()
                pcall(function() f:Destroy() end)
        end)
end

--===================== UI =====================
local gui = Instance.new("ScreenGui")
gui.Name = "LEGENDS_BH_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = playerGui
track(gui)

-- letterbox bars
local barTop = Instance.new("Frame")
barTop.Size = UDim2.new(1, 0, 0.115, 0)
barTop.Position = UDim2.new(0, 0, 0, 0)
barTop.BackgroundColor3 = C_BLACK
barTop.BorderSizePixel = 0
barTop.ZIndex = 5
barTop.Parent = gui
local barBot = barTop:Clone()
barBot.Position = UDim2.new(0, 0, 0.885, 0)
barBot.Parent = gui
TweenService:Create(barTop, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0.09, 0),
}):Play()
TweenService:Create(barBot, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0.09, 0),
}):Play()

-- black fade overlay
local fade = Instance.new("Frame")
fade.Size = UDim2.new(1, 0, 1, 0)
fade.BackgroundColor3 = C_BLACK
fade.BackgroundTransparency = 0
fade.BorderSizePixel = 0
fade.ZIndex = 8
fade.Parent = gui
TweenService:Create(fade, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
}):Play()

-- phase label
local phaseLabel = Instance.new("TextLabel")
phaseLabel.Size = UDim2.new(0, 400, 0, 26)
phaseLabel.Position = UDim2.new(0.5, -200, 0.095, 6)
phaseLabel.BackgroundTransparency = 1
phaseLabel.Font = Enum.Font.Gotham
phaseLabel.TextSize = 14
phaseLabel.TextColor3 = C_SILVER
phaseLabel.TextTransparency = 0.35
phaseLabel.Text = ""
phaseLabel.Visible = SHOW_PHASES
phaseLabel.ZIndex = 6
phaseLabel.Parent = gui

-- debug label
local dbg = Instance.new("TextLabel")
dbg.Size = UDim2.new(0, 320, 0, 40)
dbg.Position = UDim2.new(0, 12, 0, 40)
dbg.BackgroundTransparency = 0.55
dbg.BackgroundColor3 = C_BLACK
dbg.Font = Enum.Font.Code
dbg.TextSize = 13
dbg.TextColor3 = C_ICE
dbg.TextXAlignment = Enum.TextXAlignment.Left
dbg.Visible = ENABLE_DEBUG
dbg.ZIndex = 9
dbg.Parent = gui

-- skip button
if ENABLE_SKIP then
        local skip = Instance.new("TextButton")
        skip.Size = UDim2.new(0, 110, 0, 34)
        skip.Position = UDim2.new(1, -124, 0.885, 10)
        skip.BackgroundColor3 = C_BLACK
        skip.BackgroundTransparency = 0.45
        skip.TextColor3 = C_SILVER
        skip.Font = Enum.Font.GothamBold
        skip.TextSize = 14
        skip.Text = "SKIP  »"
        skip.ZIndex = 10
        skip.Parent = gui
        skip.MouseButton1Click:Connect(function()
                active = false
        end)
end

-- title group (hidden until phase 6)
local titleHolder = Instance.new("Frame")
titleHolder.Size = UDim2.new(1, 0, 1, 0)
titleHolder.BackgroundTransparency = 1
titleHolder.Visible = false
titleHolder.ZIndex = 6
titleHolder.Parent = gui

local function makeGlowText(txt, size, y, color, zoffset)
        local glow = Instance.new("TextLabel")
        glow.Size = UDim2.new(1, 0, 0, size * 1.6)
        glow.Position = UDim2.new(0, 0, y, 0)
        glow.BackgroundTransparency = 1
        glow.Font = Enum.Font.GothamBlack
        glow.TextSize = size
        glow.TextColor3 = color
        glow.TextTransparency = 1
        glow.Text = txt
        glow.ZIndex = 6 + (zoffset or 0)
        glow.Parent = titleHolder
        return glow
end

local titleMain = makeGlowText("L E G E N D S", math.clamp(math.floor(cam.ViewportSize.X * 0.085), 42, 96), 0.38, C_WHITE)
local titleSub = makeGlowText("—  B E Y O N D   T H E   H O R I Z O N  —", 18, 0.55, C_SILVER)

--===================== SCENE : STAR FIELD =====================
local rng = Random.new(20261102)

local starFolder = Instance.new("Folder")
starFolder.Name = "Stars"
starFolder.Parent = root

local stars = {}
for i = 1, 170 do
        local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
        if dir.Magnitude < 0.05 then dir = Vector3.new(1, 0, 0) end
        dir = dir.Unit
        local r = rng:NextNumber(500, 950)
        local col = C_WHITE
        local pick = rng:NextNumber()
        if pick < 0.25 then col = C_ICE elseif pick < 0.45 then col = C_BLUE elseif pick < 0.55 then col = C_GOLD end
        local st = part({
                Size = Vector3.new(rng:NextNumber(1.2, 3.4), rng:NextNumber(1.2, 3.4), rng:NextNumber(1.2, 3.4)),
                Color = col,
                Transparency = rng:NextNumber(0.05, 0.4),
                CFrame = CFrame.new(SCENE + dir * r),
        }, starFolder)
        stars[#stars + 1] = {p = st, base = SCENE + dir * r, tw = rng:NextNumber(0.5, 2.4), ph = rng:NextNumber(0, 6.28)}
end

-- nebula clouds
local nebFolder = Instance.new("Folder")
nebFolder.Name = "Nebulae"
nebFolder.Parent = root
local nebColors = {C_BLUE, C_VIOLET, C_ICE, C_SILVER}
for i = 1, 9 do
        local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-1, 1))
        if dir.Magnitude < 0.05 then dir = Vector3.zAxis end
        dir = dir.Unit
        local nb = part({
                Size = Vector3.new(rng:NextNumber(140, 320), rng:NextNumber(90, 200), 2),
                Color = nebColors[rng:NextInteger(1, #nebColors)],
                Transparency = 0.86,
                Material = Enum.Material.Neon,
                CFrame = CFrame.lookAt(SCENE + dir * rng:NextNumber(700, 1100), SCENE)
                        * CFrame.Angles(0, rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28)),
        }, nebFolder)
        track(nb)
end

--===================== SCENE : BLACK HOLE =====================
local SCENE  = Vector3.new(0, 2000, 0)          -- high above any map
local BH_POS = SCENE + Vector3.new(0, 0, -260)  -- where the black hole lives
local bhFolder = Instance.new("Folder")
bhFolder.Name = "BlackHole"
bhFolder.Parent = root
bhFolder:PivotTo(CFrame.new(BH_POS))

-- core : pure black sphere (hidden until birth phase)
local core = part({
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(1, 1, 1),
        Color = C_BLACK,
        Material = Enum.Material.SmoothPlastic,
        Transparency = 1,
        CFrame = CFrame.new(BH_POS),
}, bhFolder)

-- photon ring : razor thin bright ring hugging the core
local photon1 = ring(1, 0.22, C_WHITE, 1, bhFolder)
local photon2 = ring(1, 0.5, C_ICE, 1, bhFolder)
photon1.CFrame = CFrame.new(BH_POS) * CFrame.Angles(0, 0, math.rad(90))
photon2.CFrame = CFrame.new(BH_POS) * CFrame.Angles(0, 0, math.rad(90))

-- accretion disk : layered rotating discs (amber -> violet)
local disk = {}
local diskSpec = {
        {r = 2.4, t = 0.16, col = C_WHITE,  tr = 0.30, spin = 1.00},
        {r = 2.9, t = 0.30, col = C_GOLD,   tr = 0.42, spin = 0.82},
        {r = 3.5, t = 0.42, col = C_AMBER,  tr = 0.52, spin = 0.66},
        {r = 4.3, t = 0.55, col = C_EMBER,  tr = 0.62, spin = 0.52},
        {r = 5.3, t = 0.75, col = C_VIOLET, tr = 0.74, spin = 0.40},
        {r = 6.5, t = 1.00, col = C_VIOLET, tr = 0.85, spin = 0.30},
}
for _, spec in ipairs(diskSpec) do
        local d = ring(spec.r, spec.t, spec.col, 1, bhFolder)
        d.CFrame = CFrame.new(BH_POS) * CFrame.Angles(0, 0, math.rad(90))
        disk[#disk + 1] = {p = d, spin = spec.spin, ang = rng:NextNumber(0, 6.28), r = spec.r, t = spec.t}
end

-- glow halo behind the hole
local halo = part({
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(1, 1, 1),
        Color = C_AMBER,
        Transparency = 1,
        Material = Enum.Material.Neon,
        CFrame = CFrame.new(BH_POS),
}, bhFolder)

--===================== SCENE : DEBRIS (spiral food) =====================
local debrisFolder = Instance.new("Folder")
debrisFolder.Name = "Debris"
debrisFolder.Parent = root

local debris = {}
for i = 1, 34 do
        local col = C_GOLD
        local pick = rng:NextNumber()
        if pick < 0.4 then col = C_AMBER elseif pick < 0.6 then col = C_ICE elseif pick < 0.75 then col = C_WHITE end
        local d = part({
                Size = Vector3.new(1, 1, 1) * rng:NextNumber(0.8, 2.4),
                Color = col,
                Transparency = rng:NextNumber(0, 0.3),
        }, debrisFolder)
        debris[#debris + 1] = {
                p = d,
                baseSize = d.Size.X,
                ang = rng:NextNumber(0, 6.28),
                rad = rng:NextNumber(40, 150),
                fall = rng:NextNumber(2.2, 6.5),
                spinY = rng:NextNumber(-0.6, 0.6),
                speed = rng:NextNumber(0.55, 1.35),
        }
end

-- doomed hero stars : long trails, get eaten
local heroFolder = Instance.new("Folder")
heroFolder.Name = "HeroStars"
heroFolder.Parent = root
local heroStars = {}
for i = 1, 6 do
        local st = part({
                Size = Vector3.new(3.2, 3.2, 3.2),
                Color = C_WHITE,
                Transparency = 0,
        }, heroFolder)
        local a0 = Instance.new("Attachment")
        a0.Parent = st
        local tr = Instance.new("Trail")
        tr.Attachment0 = a0
        tr.Attachment1 = a0
        tr.Lifetime = 1.4
        tr.MinLength = 0.05
        tr.WidthScale = NumberSequence.new(1, 0)
        tr.Color = ColorSequence.new(C_ICE, C_VIOLET)
        tr.Transparency = NumberSequence.new(0.2, 1)
        tr.LightEmission = 1
        tr.FaceCamera = true
        tr.Parent = st
        track(tr)
        -- trail needs two attachments offset; fix:
        local a1 = Instance.new("Attachment")
        a1.Position = Vector3.new(0, 1.6, 0)
        a1.Parent = st
        a0.Position = Vector3.new(0, -1.6, 0)
        tr.Attachment1 = a1
        heroStars[#heroStars + 1] = {
                p = st,
                startDir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-1, 1)).Unit,
                startR = rng:NextNumber(260, 420),
                t0 = 11 + i * 3.2,         -- spawn time (after the hole is born)
                dur = rng:NextNumber(5.5, 7.5),
                alive = true,
                nextSpawn = 0,
        }
end

--===================== SCENE : SHOCKWAVES =====================
local waveFolder = Instance.new("Folder")
waveFolder.Name = "Waves"
waveFolder.Parent = root
local waves = {}
local function shockwave(radius, color)
        local w = ring(radius, 0.4, color or C_ICE, 0.15, waveFolder)
        w.CFrame = CFrame.new(BH_POS) * CFrame.Angles(0, 0, math.rad(90))
        waves[#waves + 1] = {p = w, r = radius, life = 0}
end

--===================== UPDATERS =====================
local diskGroup = bhFolder -- rotate children via CFrame math below

local function updateBlackHole(dt, t)
        -- gates : nothing exists before the birth phase (t >= 9)
        local born = t >= 9
        core.Transparency = born and 0 or 1
        halo.Transparency = (t >= 10) and math.clamp(0.72 - math.sin(t * 1.3) * 0.06, 0, 1) or 1
        if not born then return end

        -- grow over intro : birth (9s) -> full size (15s)
        local grow = math.clamp((t - 9) / 6, 0, 1)
        local pulse = 1 + math.sin(t * 2.1) * 0.02
        local size = (0.4 + grow * 0.96) * pulse
        core.Size = Vector3.new(1, 1, 1) * 26 * size
        halo.Size = Vector3.new(1, 1, 1) * 34 * size

        local pVis = math.clamp((t - 9.6) / 1.4, 0, 1)
        photon1.Size = Vector3.new(0.22, 26.9 * size, 26.9 * size)
        photon2.Size = Vector3.new(0.5, 28.5 * size, 28.5 * size)
        photon1.CFrame = CFrame.new(BH_POS) * CFrame.Angles(0, 0, math.rad(90))
        photon2.CFrame = CFrame.new(BH_POS) * CFrame.Angles(0, 0, math.rad(90))
        photon1.Transparency = 1 - pVis * (0.1 + math.sin(t * 3.7) * 0.08)
        photon2.Transparency = 1 - pVis * (0.4 + math.sin(t * 2.2 + 1) * 0.1)

        local dVis = math.clamp((t - 11) / 2.5, 0, 1)
        for _, d in ipairs(disk) do
                d.ang = d.ang + dt * (0.9 + d.spin * (0.6 + grow * 1.5))
                local wob = math.sin(t * 0.8 + d.r) * 0.03
                d.p.Size = Vector3.new(d.t, d.r * 2 * size, d.r * 2 * size)
                -- axis up (flat disc) + slow cinematic tilt
                d.p.CFrame = CFrame.new(BH_POS)
                        * CFrame.Angles(math.rad(10 + math.sin(t * 0.35) * 4) + wob, d.ang * 0.15, 0)
                        * CFrame.Angles(0, 0, math.rad(90))
                d.p.Transparency = 1 - dVis * (1 - d.tr)
        end
end

local function updateDebris(dt, t)
        if t < 9.5 then return end
        local grow = math.clamp((t - 9) / 6, 0, 1)
        local dVis = math.clamp((t - 9.5) / 2, 0, 1)
        for _, d in ipairs(debris) do
                -- spiral inward : radius shrinks, angle accelerates near hole
                d.rad = d.rad - dt * d.fall * (1 + grow * 0.8)
                local omega = 60 / math.max(d.rad, 6)
                d.ang = d.ang + dt * omega * d.speed
                if d.rad < 16 then
                        -- consumed : respawn far out
                        d.rad = rng:NextNumber(110, 190)
                        d.ang = rng:NextNumber(0, 6.28)
                        if rng:NextNumber() < 0.25 then
                                shockwave(8 + rng:NextNumber(0, 10), C_AMBER)
                        end
                end
                local y = math.sin(d.ang * 2 + d.spinY * 10) * d.rad * 0.10
                local pos = BH_POS + Vector3.new(math.cos(d.ang) * d.rad, y, math.sin(d.ang) * d.rad)
                local stretch = math.clamp(omega * 0.12, 1, 2.4)
                d.p.CFrame = CFrame.lookAt(pos, BH_POS) * CFrame.Angles(0, math.rad(90), 0)
                d.p.Size = Vector3.new(1, 1, 1) * d.baseSize * (0.75 + stretch * 0.3)
                d.p.Transparency = 1 - dVis * 0.85
        end
end

local function updateHeroStars(dt, t)
        for _, hs in ipairs(heroStars) do
                if not hs.alive then
                        -- respawn a new doomed star later
                        if t > hs.nextSpawn then
                                hs.alive = true
                                hs.startDir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-1, 1)).Unit
                                hs.startR = rng:NextNumber(260, 430)
                                hs.t0 = t
                                hs.dur = rng:NextNumber(5, 7.5)
                                hs.p.Transparency = 0
                        end
                else
                        local k = (t - hs.t0) / hs.dur
                        if k >= 1 then
                                hs.alive = false
                                hs.nextSpawn = t + rng:NextNumber(3, 7)
                                hs.p.Transparency = 1
                                flash(C_ICE, 0.18, 0.35)
                                shockwave(30, C_ICE)
                                shakeAmp = math.min(shakeAmp + 0.5, 1.6)
                        else
                                -- accelerate as it falls in
                                local eased = k * k * 0.4 + k * 0.6
                                local r = hs.startR * (1 - eased)
                                local swirl = eased * 3.4
                                local rot = CFrame.Angles(0, swirl, eased * 0.7)
                                local dir = (rot * hs.startDir).Unit
                                local pos = BH_POS + dir * r
                                hs.p.CFrame = CFrame.lookAt(pos, BH_POS)
                                hs.p.Size = Vector3.new(3.2, 3.2, 3.2) * (1 - eased * 0.75)
                        end
                end
        end
end

local function updateWaves(dt)
        for i = #waves, 1, -1 do
                local w = waves[i]
                w.life = w.life + dt
                local k = w.life / 1.6
                if k >= 1 then
                        w.p:Destroy()
                        table.remove(waves, i)
                else
                        local r = w.r + k * 90
                        w.p.Size = Vector3.new(0.4, r * 2, r * 2)
                        w.p.Transparency = 0.15 + k * 0.8
                end
        end
end

local function updateStars(dt, t)
        for _, s in ipairs(stars) do
                local tw = 0.5 + math.sin(t * s.tw + s.ph) * 0.5
                s.p.Transparency = 0.15 + tw * 0.35
        end
end

--===================== CAMERA DIRECTOR =====================
cam.CameraType = Enum.CameraType.Scriptable

cam.CFrame = CFrame.new(SCENE + Vector3.new(0, 40, 210))
local camCF = cam.CFrame
local camTargetCF = camCF
local fovVal = 70
local fovTarget = 70

local function camGo(cf, fov)
        camTargetCF = cf
        fovTarget = fov or fovTarget
end

local function orbitCF(dist, height, angle, lookAt)
        local pos = (lookAt or BH_POS) + Vector3.new(math.sin(angle) * dist, height, math.cos(angle) * dist)
        return CFrame.lookAt(pos, lookAt or BH_POS)
end

local function updateCamera(dt, t)
        -- ease toward target
        local alpha = math.clamp(dt * 2.2, 0, 1)
        camCF = camCF:Lerp(camTargetCF, alpha)
        fovVal = fovVal + (fovTarget - fovVal) * math.clamp(dt * 2.5, 0, 1)

        -- shake
        shakeAmp = math.max(0, shakeAmp - dt * (shakeAmp * 2.2 + 0.18))
        local shx = math.noise(t * 9.1, 0.3) * shakeAmp
        local shy = math.noise(0.7, t * 8.3) * shakeAmp
        local shz = math.noise(t * 7.2, 4.1) * shakeAmp * 0.5

        local roll = math.noise(t * 0.6, 9.7) * 0.8 * (1 + shakeAmp)
        cam.CFrame = camCF * CFrame.Angles(math.rad(shx * 2.2), math.rad(shy * 2.2), math.rad(roll))
                * CFrame.Angles(0, 0, math.rad(shz * 1.4))
        cam.FieldOfView = fovVal + math.sin(t * 1.1) * 0.7 + shakeAmp * 2.2
end

--===================== PHASES =====================
local function phaseDeepSpace(dur)
        -- drifting through stars, hole not born yet
        camGo(CFrame.lookAt(SCENE + Vector3.new(0, 30, 210), BH_POS), 70)
        setCC(0, 0.05, -0.1)
        setBloom(0.6)
        task.delay(dur * 0.4, function()
                if not active then return end
                camGo(CFrame.lookAt(SCENE + Vector3.new(-30, 45, 190), BH_POS), 66)
        end)
        task.wait(dur * S)
end

local function phaseBirth(dur)
        -- the hole ignites far away
        shockwave(6, C_WHITE)
        sfx("rbxasset://sounds/impact_generic.mp3", 0.5, 0.7)
        flash(C_WHITE, 0.35, 0.8)
        shakeAmp = 0.8
        setCC(0.02, 0.15, -0.25)
        setBloom(1.0)
        camGo(CFrame.lookAt(BH_POS + Vector3.new(70, 26, 150), BH_POS), 62)
        task.delay(dur * 0.45, function()
                if not active then return end
                shockwave(20, C_GOLD)
                sfx("rbxasset://sounds/impact_generic.mp3", 0.4, 0.55)
                camGo(CFrame.lookAt(BH_POS + Vector3.new(-55, 18, 120), BH_POS), 58)
        end)
        task.wait(dur * S)
end

local function phaseAccretion(dur)
        -- disk spins up, camera orbits
        setBloom(1.25)
        setCC(0.03, 0.22, -0.3)
        local t0 = clock
        pconn(RunService.RenderStepped:Connect(function()
                if not active then return end
                local k = math.clamp((clock - t0) / (dur * S), 0, 1)
                local ang = k * math.rad(115)
                camGo(orbitCF(150 - k * 45, 26 - k * 12, ang), 60 - k * 4)
        end))
        task.delay(dur * 0.5, function()
                if active then shockwave(45, C_VIOLET) end
        end)
        task.wait(dur * S)
        endPhaseConn()
end

local function phaseGravityWell(dur)
        -- stars stream in, heavy orbit, bursts
        setBloom(1.5)
        shakeAmp = 0.5
        local t0 = clock
        pconn(RunService.RenderStepped:Connect(function()
                if not active then return end
                local k = math.clamp((clock - t0) / (dur * S), 0, 1)
                local ang = math.rad(115) + k * math.rad(150)
                camGo(orbitCF(105 - k * 25, 14 - k * 8, ang), 56 - k * 5)
        end))
        for i = 1, 3 do
                task.delay(dur * S * (0.25 + i * 0.24), function()
                        if not active then return end
                        shockwave(20 + i * 22, i % 2 == 0 and C_ICE or C_GOLD)
                        sfx("rbxasset://sounds/impact_generic.mp3", 0.45, 0.6 - i * 0.08)
                        shakeAmp = math.min(shakeAmp + 0.35, 1.4)
                end)
        end
        task.wait(dur * S)
        endPhaseConn()
end

local function phaseEventHorizon(dur)
        -- dive toward the ring : tension + white-out
        setBloom(1.8)
        setBlur(6)
        shakeAmp = 0.7
        local t0 = clock
        pconn(RunService.RenderStepped:Connect(function()
                if not active then return end
                local k = math.clamp((clock - t0) / (dur * S), 0, 1)
                local dist = 88 - k * 62
                local height = 10 - k * 7
                local ang = math.rad(265) + k * math.rad(60)
                camGo(orbitCF(dist, height, ang), 50 - k * 8)
                setBlur(k * 10)
                setCC(k * 0.08, 0.3 + k * 0.2, -0.35 - k * 0.2)
        end))
        task.delay(dur * S * 0.82, function()
                if not active then return end
                flash(C_WHITE, 0.9, 1.1)
                sfx("rbxasset://sounds/impact_generic.mp3", 0.6, 0.5)
                shockwave(60, C_WHITE)
                shakeAmp = 1.8
        end)
        task.wait(dur * S)
        endPhaseConn()
end

local function phaseTitle(dur)
        -- pull back : the hole shrinks behind the LEGENDS title
        setBlur(0)
        setBloom(1.2)
        setCC(0.02, 0.2, -0.2)
        local t0 = clock
        pconn(RunService.RenderStepped:Connect(function()
                if not active then return end
                local k = math.clamp((clock - t0) / (dur * S), 0, 1)
                local ang = math.rad(325) + k * math.rad(30)
                camGo(orbitCF(120 + k * 60, 24 + k * 14, ang), 62 + k * 6)
        end))
        titleHolder.Visible = true
        local ti = TweenInfo.new(1.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        TweenService:Create(titleMain, ti, {TextTransparency = 0}):Play()
        task.delay(0.55, function()
                if active then
                        TweenService:Create(titleSub, TweenInfo.new(0.9), {TextTransparency = 0.25}):Play()
                end
        end)
        task.delay(dur * S * 0.72, function()
                if active then
                        TweenService:Create(fade, TweenInfo.new(1.6), {BackgroundTransparency = 0}):Play()
                end
        end)
        task.wait(dur * S)
        endPhaseConn()
end

--===================== CLEANUP =====================
local runConn = nil

local function cleanup()
        if runConn then
                runConn:Disconnect()
                runConn = nil
        end
        for _, c in ipairs(conns) do
                pcall(function() c:Disconnect() end)
        end
        for _, o in ipairs(junk) do
                pcall(function() o:Destroy() end)
        end
        -- restore world
        pcall(function()
                for _, f in ipairs({"LEGENDS_CC", "LEGENDS_Bloom", "LEGENDS_Blur", "LEGENDS_Sky"}) do
                        local x = Lighting:FindFirstChild(f)
                        if x then x:Destroy() end
                end
                Lighting.Brightness = savedLighting.Brightness
                Lighting.Ambient = savedLighting.Ambient
                Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
                Lighting.ClockTime = savedLighting.ClockTime
                Lighting.FogEnd = savedLighting.FogEnd
                Lighting.FogColor = savedLighting.FogColor
        end)
        pcall(function()
                cam.CameraType = savedCameraType
                cam.CFrame = savedCameraCF
                cam.FieldOfView = savedFOV
        end)
        print("[LEGENDS v3] Black Hole intro finished. errors: " .. errCount)
end

--===================== MAIN LOOP =====================
runConn = RunService.RenderStepped:Connect(function(dt)
        if not active then return end
        clock = clock + dt
        local t = clock
        pcall(function()
                updateBlackHole(dt, t)
                updateDebris(dt, t)
                updateHeroStars(dt, t)
                updateWaves(dt)
                updateStars(dt, t)
                updateCamera(dt, t)
        end)
        dbg.Text = ("t=%.1f  shake=%.2f  errors=%d  %s"):format(t, shakeAmp, errCount, errText)
end)

local function setPhase(n, name)
        if SHOW_PHASES then
                phaseLabel.Text = ("PHASE %d/6 — %s"):format(n, name)
        end
        if ENABLE_DEBUG then
                print("[LEGENDS v3] phase:", name)
        end
end

--===================== RUN =====================
startAmbience()

task.spawn(function()
        local phases = {
                {9.0,  function(d) setPhase(1, "DEEP SPACE")     return phaseDeepSpace(d) end},
                {6.0,  function(d) setPhase(2, "SINGULARITY")    return phaseBirth(d) end},
                {7.5,  function(d) setPhase(3, "ACCRETION DISK") return phaseAccretion(d) end},
                {6.5,  function(d) setPhase(4, "GRAVITY WELL")   return phaseGravityWell(d) end},
                {5.0,  function(d) setPhase(5, "EVENT HORIZON")  return phaseEventHorizon(d) end},
                {4.0,  function(d) setPhase(6, "LEGENDS")        return phaseTitle(d) end},
        }
        for idx, ph in ipairs(phases) do
                if not active then break end
                local ok, err = pcall(ph[2], ph[1])
                if not ok then
                        errCount = errCount + 1
                        errText = "last: " .. tostring(err):sub(1, 50)
                        warn("[LEGENDS v3] phase error:", err)
                end
        end
        if active then
                -- graceful end
                active = false
        end
        cleanup()
end)
