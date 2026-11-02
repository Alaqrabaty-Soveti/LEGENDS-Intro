--=====================================================================--
--   L E G E N D S  —  " T H E   S K Y   S P L I T T E R "
--   VFX STUDIO EDITION  ·  v2  (full rebuild)
--
--   Blanch-inspired White x Silver cinematic. One LocalScript only.
--   Put it in StarterGui (or StarterPlayerScripts) and play.
--
--   v2 upgrades over v1:
--    * 13-pose character animation system (Motor6D.Transform blending)
--      + live procedural layer (breathing / tremble / sword sway)
--    * Camera Director: tweened FOV + dutch roll + noise handheld shake
--    * Per-phase color grading (ColorCorrection / Bloom pulses / Blur)
--    * Sword v2: rune ring, fuller core, crossguard blades, tip trail
--    * Arena v2: floating disc, broken neon columns, ground cracks, moon
--    * Sky Rift v2: god rays + strobing lightning arcs + shard rain
--    * Debug overlay + per-phase error catching (never breaks the intro)
--    * Full save/restore of camera, lighting, sky, clouds and controls
--
--   AR: حط السكربت ده LocalScript جوا StarterGui وخلاص، مفيش حاجات تانية
--=====================================================================--

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Debris       = game:GetService("Debris")

--=============================================================
--  SELF-DIAGNOSIS: the script TELLS you what is wrong instead
--  of failing silently (this was the v2.0 weakness)
--=============================================================

-- #1 most common mistake: pasting this into a server Script.
local function bootFail(msg)
        warn("═══════════ LEGENDS v2 ═══════════")
        warn(msg)
        warn("═════════════════════════════════")
        return
end

if RunService:IsServer() and not RunService:IsClient() then
        bootFail("السكربت ده لازم يكون LocalScript مش Script عادي!\n "
                .. "امسحه من هنا وحطه في: StarterGui > اعمل LocalScript > الصق جواه\n "
                .. "(This must be a LOCALSCRIPT inside StarterGui, not a Script)")
        return
end

local player = Players.LocalPlayer
if player == nil then
        bootFail("مش شايف LocalPlayer — اتأكد إن السكربت LocalScript جوا StarterGui\n "
                .. "(No LocalPlayer: the script must run as a LocalScript on the client)")
        return
end

local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

-- red on-screen error box: any boot error is now VISIBLE, not silent
local function showFatal(msg)
        warn("[LEGENDS v2] boot error: " .. tostring(msg))
        pcall(function()
                local g = Instance.new("ScreenGui")
                g.Name = "LEGENDS_Error"
                g.ResetOnSpawn = false
                g.DisplayOrder = 9999
                g.Parent = playerGui
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, -40, 0, 170)
                f.Position = UDim2.new(0, 20, 0.38, 0)
                f.BackgroundColor3 = Color3.fromRGB(24, 8, 8)
                f.BackgroundTransparency = 0.06
                f.BorderSizePixel = 0
                f.Parent = g
                local cr = Instance.new("UICorner")
                cr.CornerRadius = UDim.new(0, 10)
                cr.Parent = f
                local t = Instance.new("TextLabel")
                t.Size = UDim2.new(1, -24, 1, -20)
                t.Position = UDim2.new(0, 12, 0, 10)
                t.BackgroundTransparency = 1
                t.Font = Enum.Font.Code
                t.TextSize = 15
                t.TextWrapped = true
                t.TextXAlignment = Enum.TextXAlignment.Left
                t.TextYAlignment = Enum.TextYAlignment.Top
                t.TextColor3 = Color3.fromRGB(255, 130, 130)
                t.Text = "LEGENDS v2 — حصل خطأ وده نصه:\n" .. tostring(msg)
                        .. "\n\nابعتلي الصورة دي في الشات وأنا أصلحه فورًا"
                t.Parent = f
        end)
end

----------------------------------------------------------------- CONFIG
local CONFIG = {
        GAME_NAME        = "LEGENDS",
        TAGLINE          = "T H E   S K Y   S P L I T T E R",
        INTRO_DURATION   = 57,     -- seconds (57 == the authored length)
        ENABLE_SOUNDS    = true,
        ENABLE_SKIP      = true,
        MUSIC_ID         = "",     -- optional: "rbxassetid://...."
        SHOW_PHASE_NAMES = true,   -- small cinematic captions
        DEBUG_OVERLAY    = false,  -- top-left technical overlay
}

-- global time scale: all authored beats fit INTRO_DURATION
local S = CONFIG.INTRO_DURATION / 57
local function T(x) return x * S end

---------------------------------------------------------------- PALETTE
local WHITE    = Color3.fromRGB(255, 255, 255)
local SILVER   = Color3.fromRGB(214, 226, 244)
local ICE      = Color3.fromRGB(172, 202, 255)
local DEEP     = Color3.fromRGB(24, 26, 36)
local VOID     = Color3.fromRGB(10, 9, 14)
local EMBER    = Color3.fromRGB(255, 122, 34)
local EMBER2   = Color3.fromRGB(255, 61, 18)
local OBSIDIAN = Color3.fromRGB(30, 26, 34)

local SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE_TEX  = "rbxasset://textures/particles/fire_main.dds"
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"

local function silverSeq()
        return ColorSequence.new(WHITE, ICE)
end
local function emberSeq()
        return ColorSequence.new(Color3.fromRGB(255, 200, 90), EMBER2)
end

------------------------------------------------------------------ STATE
local introActive = false
local saved  = {}
local savedFX = {}
local conns  = {}
local soundsAll = {}
local music = nil
local controls = nil

local sceneFolder = Instance.new("Folder")
sceneFolder.Name = "LEGENDS_VFX_Scene"

-- character refs
local char, hrp, humanoid, animator
local isR15 = false
local handPart = nil
local animateScript = nil
local joints = {}

-- story anchors
local originPos, lookH, rightH, yawCF
local crackPos, spaceEndPos

-- runtime objects
local swordModel, swordParts, swordLight, swordEmit
local swordTip, swordTrail, runeRing
local auraEmit, trailEmit, cloudEmit, cloudPart
local dragon = nil
local starDome = nil
local crackGroup = nil
local crackLight = nil
local lightningArcs = {}
local moonPart = nil
local runeSpin = 0

-- post effects created by the intro
local introCC, introBloom, introBlur, atmosphere = nil, nil, nil, nil
local createdAtmo = false

-- UI refs
local uiGui, blackFrame, flashFrame
local letterTop, letterBottom
local titleMain, titleTag, titleScale
local titleGrad, skipButton
local phaseLabel, debugLabel

-- camera / animation state
local cam = { shake = 0 }
local camValue = Instance.new("CFrameValue")
local fovVal   = Instance.new("NumberValue")
local rollVal  = Instance.new("NumberValue")
local poseSnap = false
local trembleAmp = 0.3
local spaceMode = false
local ascendCam = false
local runConn = nil
local errCount = 0
local errText = ""

-- pose blending state (filled by setPose)
local poseCur = { shR = 6, shL = 4, neck = 2, waist = 0 }
local poseTgt = { shR = 6, shL = 4, neck = 2, waist = 0 }
local poseRate = 6

---------------------------------------------------------------- HELPERS
local function twi(d, style, dir)
        return TweenInfo.new(d, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
end

local function tween(obj, info, goal)
        local tw = TweenService:Create(obj, info, goal)
        tw:Play()
        return tw
end

local function lerp(a, b, t)
        return a + (b - a) * t
end

local function beat(delayS, fn)
        task.delay(delayS, function()
                if introActive then
                        pcall(fn)
                end
        end)
end

local function guard()
        return introActive and sceneFolder.Parent ~= nil
end

-- generic part builder
local function part(props, parent)
        local p = Instance.new(props.Class or "Part")
        p.Anchored = props.Anchored == true
        p.CanCollide = props.CanCollide == true
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = props.CastShadow == true
        p.Massless = props.Massless ~= false
        p.Material = props.Material or Enum.Material.SmoothPlastic
        p.Color = props.Color or WHITE
        p.Transparency = props.Transparency or 0
        p.Reflectance = props.Reflectance or 0
        p.Size = props.Size or Vector3.new(1, 1, 1)
        p.CFrame = props.CFrame or CFrame.new(0, -500, 0)
        p.Name = props.Name or "FXPart"
        if props.Shape then
                p.Shape = props.Shape
        end
        local ok = pcall(function()
                p.Parent = parent or sceneFolder
        end)
        if not ok then
                return nil
        end
        return p
end

local function weldTo(a, b)
        if a == nil or b == nil then
                return nil
        end
        local w = Instance.new("WeldConstraint")
        w.Part0 = a
        w.Part1 = b
        w.Parent = a
        return w
end

local function motor6d(p0, p1, pivotWorld)
        if p0 == nil or p1 == nil then
                return nil
        end
        local m = Instance.new("Motor6D")
        m.Part0 = p0
        m.Part1 = p1
        m.C0 = p0.CFrame:Inverse() * pivotWorld
        m.C1 = p1.CFrame:Inverse() * pivotWorld
        m.Parent = p0
        return m
end

local function pointLight(parent, color, brightness, range)
        if parent == nil then
                return nil
        end
        local l = Instance.new("PointLight")
        l.Color = color or WHITE
        l.Brightness = brightness or 2
        l.Range = range or 16
        l.Shadows = true
        l.Parent = parent
        return l
end

local function emitter(parent, props)
        if parent == nil then
                return nil
        end
        local e = Instance.new("ParticleEmitter")
        e.Texture = props.Texture or SPARK_TEX
        e.Rate = props.Rate or 0
        e.Speed = props.Speed or NumberRange.new(4, 8)
        e.Lifetime = props.Lifetime or NumberRange.new(0.5, 1)
        e.Size = props.Size or NumberSequence.new(1)
        e.Transparency = props.Transparency or NumberSequence.new(0)
        e.LightEmission = props.LightEmission or 0.8
        e.LightInfluence = 0
        e.Color = props.Color or silverSeq()
        if props.SpreadAngle then
                e.SpreadAngle = props.SpreadAngle
        end
        if props.EmissionDirection then
                e.EmissionDirection = props.EmissionDirection
        end
        if props.Acceleration then
                e.Acceleration = props.Acceleration
        end
        if props.Drag then
                e.Drag = props.Drag
        end
        if props.RotSpeed then
                e.RotSpeed = props.RotSpeed
        end
        e.Enabled = props.Enabled == true
        e.Parent = parent
        return e
end

------------------------------------------------------------- SOUND BANK
local SOUND_BANK = {
        unsheath = "rbxasset://sounds/unsheath.wav",
        slash    = "rbxasset://sounds/swordslash.wav",
        lunge    = "rbxasset://sounds/swordlunge.wav",
        impact   = "rbxasset://sounds/impact_water.mp3",
        ping     = "rbxasset://sounds/electronicpingshort.wav",
        swoosh   = "rbxasset://sounds/swoosh.wav",
        click    = "rbxasset://sounds/clickfast.wav",
}

local function sfx(name, pitch, vol)
        if not CONFIG.ENABLE_SOUNDS then
                return
        end
        local id = SOUND_BANK[name]
        if not id then
                return
        end
        pcall(function()
                local s = Instance.new("Sound")
                s.SoundId = id
                s.PlaybackSpeed = pitch or 1
                s.Volume = vol or 0.6
                s.Parent = SoundService
                s:Play()
                table.insert(soundsAll, s)
                Debris:AddItem(s, 5)
        end)
end

local function startMusic()
        if not CONFIG.ENABLE_SOUNDS or CONFIG.MUSIC_ID == "" then
                return
        end
        pcall(function()
                music = Instance.new("Sound")
                music.SoundId = CONFIG.MUSIC_ID
                music.Volume = 0
                music.Looped = true
                music.Parent = SoundService
                music:Play()
                tween(music, twi(2), { Volume = 0.5 })
        end)
end

--============================================================--
--  CAMERA DIRECTOR  (tweened CFrame + FOV + dutch roll + shake)
--============================================================--

local function camSet(cf)
        if not introActive then
                return
        end
        camValue.Value = cf
end

-- camTo(cf, dur, opts)  opts = { style, dir, fov, roll }
local function camTo(cf, dur, opts)
        if not introActive then
                return
        end
        opts = opts or {}
        tween(camValue, twi(dur or 1, opts.style or Enum.EasingStyle.Quad, opts.dir or Enum.EasingDirection.Out), { Value = cf })
        if opts.fov then
                tween(fovVal, twi(dur or 1, opts.style or Enum.EasingStyle.Quad, opts.dir or Enum.EasingDirection.Out), { Value = opts.fov })
        end
        if opts.roll then
                tween(rollVal, twi(dur or 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = opts.roll })
        end
end

local function camFOV(v, dur)
        if not introActive then
                return
        end
        tween(fovVal, twi(dur or 0.4), { Value = v })
end

local function addShake(a)
        cam.shake = math.max(cam.shake, a)
end

local function cameraStep(dt, t)
        -- impact shake decays fast, plus a small constant floor
        cam.shake = math.max(0, cam.shake - dt * (cam.shake * 2.2 + 0.35))

        -- chase camera during the ascension
        if ascendCam and hrp and hrp.Parent then
                camValue.Value = CFrame.lookAt(
                        hrp.Position - lookH * 12 + rightH * 7 - Vector3.new(0, 5, 0),
                        hrp.Position + Vector3.new(0, 16, 0)
                )
        end

        -- handheld: fast noise (impacts) + slow drift (breathing)
        local sx = math.noise(t * 12, 31.7, 0) * cam.shake
        local sy = math.noise(t * 12, 77.3, 0) * cam.shake
        local sz = math.noise(t * 10, 12.9, 0) * cam.shake * 0.6
        local dx = math.noise(t * 0.32, 5.1, 0) * 0.0045
        local dy = math.noise(t * 0.28, 9.4, 0) * 0.0038

        camera.CFrame = camValue.Value * CFrame.Angles(sx + dx, sy + dy, sz + math.rad(rollVal.Value))
        camera.FieldOfView = fovVal.Value + math.sin(t * 0.8) * 0.35
end

--============================================================--
--  POST FX GRADE HELPERS
--============================================================--

local function bloomPulse(intensity, dur)
        if introBloom == nil or introBloom.Parent == nil then
                return
        end
        dur = dur or 0.6
        tween(introBloom, twi(dur * 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Intensity = intensity })
        task.delay(dur * 0.45, function()
                if not introActive or introBloom == nil or introBloom.Parent == nil then
                        return
                end
                tween(introBloom, twi(dur * 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Intensity = 0.55 })
        end)
end

local function setGrade(props, dur)
        if introCC and introCC.Parent then
                tween(introCC, twi(dur or 1), props)
        end
end

local function setBlur(v, dur)
        if introBlur and introBlur.Parent then
                tween(introBlur, twi(dur or 0.4), { Size = v })
        end
end

local function setAtmo(props, dur)
        if atmosphere and atmosphere.Parent then
                tween(atmosphere, twi(dur or 1), props)
        end
end

local function flash(dur, color)
        if flashFrame == nil then
                return
        end
        flashFrame.BackgroundColor3 = color or WHITE
        flashFrame.BackgroundTransparency = 0
        tween(flashFrame, twi(dur or 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
end

local function fade(toTransparency, dur)
        if blackFrame == nil then
                return
        end
        tween(blackFrame, twi(dur), { BackgroundTransparency = toTransparency })
end

--============================================================--
--  UI  (letterbox / vignette / title / captions / skip / debug)
--============================================================--

local function letterIn()
        if letterTop == nil then
                return
        end
        tween(letterTop, twi(0.9, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 0.115, 0) })
        tween(letterBottom, twi(0.9, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 0.115, 0) })
end

local function showTitle()
        if titleMain == nil then
                return
        end
        titleScale.Scale = 1.18
        tween(titleScale, twi(1.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 })
        tween(titleMain, twi(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.05, TextStrokeTransparency = 0.6 })
        beat(0.25, function()
                tween(titleTag, twi(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.15, TextStrokeTransparency = 0.8 })
        end)
        -- slow silver shine sweeping across the logo
        task.spawn(function()
                for _ = 1, 2 do
                        if not introActive then
                                return
                        end
                        local g = tween(titleGrad, twi(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1, 0) })
                        if g.Completed then
                                g.Completed:Wait()
                        end
                        if introActive and titleGrad.Parent then
                                titleGrad.Offset = Vector2.new(-1, 0)
                        end
                end
        end)
end

local PHASE_NAMES = {
        "AWAKENING", "THE BLADE", "THE GAZE", "SKY SPLITTER",
        "THE DRAGON", "THE BATTLE", "VICTORY", "ASCENSION",
}

local function setPhaseLabel(idx)
        if not CONFIG.SHOW_PHASE_NAMES or phaseLabel == nil then
                return
        end
        local name = PHASE_NAMES[idx] or ""
        phaseLabel.Text = string.format("%d  ·  %s", idx, name)
        tween(phaseLabel, twi(0.35), { TextTransparency = 0.25, BackgroundTransparency = 0.35 })
        task.delay(2.2, function()
                if introActive and phaseLabel and phaseLabel.Parent then
                        tween(phaseLabel, twi(0.7), { TextTransparency = 1, BackgroundTransparency = 1 })
                end
        end)
end

local function updateDebug(idx)
        if not CONFIG.DEBUG_OVERLAY or debugLabel == nil then
                return
        end
        debugLabel.Text = string.format("[LEGENDS v2] phase %d/8  |  errors: %d %s", idx, errCount, errText)
end

local function buildUI()
        uiGui = Instance.new("ScreenGui")
        uiGui.Name = "LEGENDS_VFX_UI"
        uiGui.ResetOnSpawn = false
        uiGui.IgnoreGuiInset = true
        uiGui.DisplayOrder = 999
        uiGui.Parent = playerGui

        -- black fade layer
        blackFrame = Instance.new("Frame")
        blackFrame.Name = "BlackFade"
        blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        blackFrame.BorderSizePixel = 0
        blackFrame.Size = UDim2.new(1, 0, 1, 0)
        blackFrame.BackgroundTransparency = 0
        blackFrame.ZIndex = 5
        blackFrame.Parent = uiGui

        -- white flash layer
        flashFrame = Instance.new("Frame")
        flashFrame.Name = "WhiteFlash"
        flashFrame.BackgroundColor3 = WHITE
        flashFrame.BorderSizePixel = 0
        flashFrame.Size = UDim2.new(1, 0, 1, 0)
        flashFrame.BackgroundTransparency = 1
        flashFrame.ZIndex = 6
        flashFrame.Parent = uiGui

        -- cinematic letterbox bars
        letterTop = Instance.new("Frame")
        letterTop.Name = "BarTop"
        letterTop.BackgroundColor3 = Color3.new(0, 0, 0)
        letterTop.BorderSizePixel = 0
        letterTop.Size = UDim2.new(1, 0, 0, 0)
        letterTop.Position = UDim2.new(0, 0, 0, 0)
        letterTop.ZIndex = 4
        letterTop.Parent = uiGui

        letterBottom = Instance.new("Frame")
        letterBottom.Name = "BarBottom"
        letterBottom.BackgroundColor3 = Color3.new(0, 0, 0)
        letterBottom.BorderSizePixel = 0
        letterBottom.Size = UDim2.new(1, 0, 0, 0)
        letterBottom.AnchorPoint = Vector2.new(0, 1)
        letterBottom.Position = UDim2.new(0, 0, 1, 0)
        letterBottom.ZIndex = 4
        letterBottom.Parent = uiGui

        -- vignette (4 gradient edges)
        local vignetteData = {
                { UDim2.new(1, 0, 0.16, 0), UDim2.new(0, 0, 0, 0), 90, 0 },
                { UDim2.new(1, 0, 0.16, 0), UDim2.new(0, 0, 0.84, 0), 90, 1 },
                { UDim2.new(0.14, 0, 1, 0), UDim2.new(0, 0, 0, 0), 0, 0 },
                { UDim2.new(0.14, 0, 1, 0), UDim2.new(0.86, 0, 0, 0), 0, 1 },
        }
        for i, v in ipairs(vignetteData) do
                local f = Instance.new("Frame")
                f.Name = "Vignette" .. i
                f.BackgroundColor3 = Color3.new(0, 0, 0)
                f.BackgroundTransparency = 0.45
                f.BorderSizePixel = 0
                f.Size = v[1]
                f.Position = v[2]
                f.ZIndex = 3
                local g = Instance.new("UIGradient")
                g.Rotation = v[3]
                if v[4] == 0 then
                        g.Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0),
                                NumberSequenceKeypoint.new(1, 1),
                        })
                else
                        g.Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(1, 0),
                        })
                end
                g.Parent = f
                f.Parent = uiGui
        end

        -- title block
        titleScale = Instance.new("UIScale")
        titleScale.Scale = 1.18

        local titleFrame = Instance.new("Frame")
        titleFrame.Name = "Title"
        titleFrame.BackgroundTransparency = 1
        titleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        titleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        titleFrame.Size = UDim2.new(1, 0, 0.4, 0)
        titleFrame.ZIndex = 7
        titleFrame.Parent = uiGui

        titleMain = Instance.new("TextLabel")
        titleMain.Name = "Main"
        titleMain.BackgroundTransparency = 1
        titleMain.AnchorPoint = Vector2.new(0.5, 0.5)
        titleMain.Position = UDim2.new(0.5, 0, 0.42, 0)
        titleMain.Size = UDim2.new(0.8, 0, 0.5, 0)
        titleMain.Font = Enum.Font.Bodoni
        titleMain.Text = CONFIG.GAME_NAME
        titleMain.TextColor3 = WHITE
        titleMain.TextTransparency = 1
        titleMain.TextStrokeTransparency = 1
        titleMain.TextStrokeColor3 = Color3.fromRGB(120, 130, 150)
        titleMain.TextScaled = true
        titleMain.ZIndex = 7
        titleGrad = Instance.new("UIGradient")
        titleGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, WHITE),
                ColorSequenceKeypoint.new(0.5, SILVER),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 172, 190)),
        })
        titleGrad.Rotation = 90
        titleGrad.Offset = Vector2.new(-1, 0)
        titleGrad.Parent = titleMain
        local tStroke = Instance.new("UIStroke")
        tStroke.Thickness = 1.5
        tStroke.Color = Color3.fromRGB(190, 200, 220)
        tStroke.Transparency = 1
        tStroke.Parent = titleMain
        titleMain.Parent = titleFrame
        titleScale.Parent = titleMain

        titleTag = Instance.new("TextLabel")
        titleTag.Name = "Tagline"
        titleTag.BackgroundTransparency = 1
        titleTag.AnchorPoint = Vector2.new(0.5, 0.5)
        titleTag.Position = UDim2.new(0.5, 0, 0.72, 0)
        titleTag.Size = UDim2.new(0.8, 0, 0.16, 0)
        titleTag.Font = Enum.Font.Gotham
        titleTag.Text = CONFIG.TAGLINE
        titleTag.TextColor3 = SILVER
        titleTag.TextTransparency = 1
        titleTag.TextStrokeTransparency = 1
        titleTag.TextStrokeColor3 = Color3.fromRGB(60, 66, 80)
        titleTag.TextScaled = true
        titleTag.ZIndex = 7
        titleTag.Parent = titleFrame

        -- phase caption (bottom-left)
        if CONFIG.SHOW_PHASE_NAMES then
                phaseLabel = Instance.new("TextLabel")
                phaseLabel.Name = "PhaseCaption"
                phaseLabel.AnchorPoint = Vector2.new(0, 1)
                phaseLabel.Position = UDim2.new(0, 26, 1, -30)
                phaseLabel.Size = UDim2.new(0, 340, 0, 30)
                phaseLabel.BackgroundTransparency = 1
                phaseLabel.BackgroundColor3 = Color3.new(0, 0, 0)
                phaseLabel.Font = Enum.Font.GothamBold
                phaseLabel.Text = ""
                phaseLabel.TextSize = 15
                phaseLabel.TextXAlignment = Enum.TextXAlignment.Left
                phaseLabel.TextColor3 = SILVER
                phaseLabel.TextTransparency = 1
                phaseLabel.ZIndex = 6
                phaseLabel.Parent = uiGui
        end

        -- debug overlay (top-left)
        if CONFIG.DEBUG_OVERLAY then
                debugLabel = Instance.new("TextLabel")
                debugLabel.Name = "DebugOverlay"
                debugLabel.Position = UDim2.new(0, 10, 0, 10)
                debugLabel.Size = UDim2.new(0, 420, 0, 22)
                debugLabel.BackgroundColor3 = Color3.new(0, 0, 0)
                debugLabel.BackgroundTransparency = 0.55
                debugLabel.BorderSizePixel = 0
                debugLabel.Font = Enum.Font.Code
                debugLabel.Text = "[LEGENDS v2] booting..."
                debugLabel.TextSize = 13
                debugLabel.TextXAlignment = Enum.TextXAlignment.Left
                debugLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
                debugLabel.ZIndex = 9
                debugLabel.Parent = uiGui
        end

        -- skip button
        if CONFIG.ENABLE_SKIP then
                skipButton = Instance.new("TextButton")
                skipButton.Name = "Skip"
                skipButton.AnchorPoint = Vector2.new(1, 0)
                skipButton.Position = UDim2.new(1, -20, 0, 16)
                skipButton.Size = UDim2.new(0, 92, 0, 34)
                skipButton.Font = Enum.Font.GothamBold
                skipButton.Text = "SKIP  X"
                skipButton.TextSize = 14
                skipButton.TextColor3 = SILVER
                skipButton.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
                skipButton.BackgroundTransparency = 0.45
                skipButton.BorderSizePixel = 0
                skipButton.TextTransparency = 0.25
                skipButton.AutoButtonColor = true
                skipButton.Visible = false
                skipButton.ZIndex = 8
                local sk = Instance.new("UICorner")
                sk.CornerRadius = UDim.new(0, 8)
                sk.Parent = skipButton
                local sstroke = Instance.new("UIStroke")
                sstroke.Color = Color3.fromRGB(120, 132, 155)
                sstroke.Transparency = 0.35
                sstroke.Parent = skipButton
                skipButton.Parent = uiGui
        end
end

--============================================================--
--  FX LIBRARY
--============================================================--

-- little light motes that fly INWARD to a point (energy gather)
local function convergeTo(pos, color, count)
        if not guard() then
                return
        end
        for _ = 1, count do
                local ang = math.random() * math.pi * 2
                local el = (math.random() - 0.5) * math.pi
                local r = 5 + math.random() * 5
                local dir = Vector3.new(math.cos(ang) * math.cos(el), math.sin(el), math.sin(ang) * math.cos(el))
                local sz = 0.22 + math.random() * 0.3
                local p = part({
                        Shape = Enum.PartType.Ball,
                        Material = Enum.Material.Neon,
                        Color = color or ICE,
                        Size = Vector3.new(sz, sz, sz),
                        CFrame = CFrame.new(pos + dir * r),
                        Anchored = true,
                })
                if p then
                        tween(p, twi(0.35 + math.random() * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(pos) })
                        Debris:AddItem(p, 0.95)
                end
        end
end

-- expanding ground shock ring
local function windDisc(pos, color, scale)
        if not guard() then
                return
        end
        scale = scale or 1
        local d = part({
                Shape = Enum.PartType.Cylinder,
                Material = Enum.Material.Neon,
                Color = color or SILVER,
                Transparency = 0.25,
                Size = Vector3.new(0.5, 8 * scale, 8 * scale),
                CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
                Anchored = true,
                CastShadow = false,
        })
        if d then
                tween(d, twi(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = Vector3.new(0.5, 40 * scale, 40 * scale),
                        Transparency = 1,
                })
                Debris:AddItem(d, 0.7)
        end
end

-- crossed neon slash arcs
local function slashArc(cf, scale, color)
        if not guard() then
                return
        end
        scale = scale or 1
        for _, a in ipairs({ 26, -26 }) do
                local blade = part({
                        Material = Enum.Material.Neon,
                        Color = color or WHITE,
                        Size = Vector3.new(0.3, 30 * scale, 3.6 * scale),
                        CFrame = cf * CFrame.Angles(math.rad(a), 0, 0),
                        Anchored = true,
                        CastShadow = false,
                })
                if blade then
                        tween(blade, twi(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                Transparency = 1,
                                Size = Vector3.new(0.3, 38 * scale, 5 * scale),
                        })
                        Debris:AddItem(blade, 0.55)
                end
        end
        local holder = part({ Transparency = 1, CFrame = cf, Anchored = true, CastShadow = false })
        if holder then
                local sp = emitter(holder, {
                        Rate = 0,
                        Speed = NumberRange.new(18 * scale, 34 * scale),
                        Lifetime = NumberRange.new(0.25, 0.55),
                        Size = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 0.9 * scale),
                                NumberSequenceKeypoint.new(1, 0),
                        }),
                        LightEmission = 1,
                        Color = silverSeq(),
                        SpreadAngle = Vector2.new(180, 180),
                        Drag = 4,
                })
                if sp then
                        sp:Emit(math.floor(40 * scale))
                end
                local l = pointLight(holder, color or WHITE, 8, 30 * scale)
                if l then
                        tween(l, twi(0.4), { Brightness = 0 })
                end
                Debris:AddItem(holder, 1.2)
        end
end

-- fire / energy explosion (burst + smoke + light + shock discs)
local function explosionAt(cf, scale, colA, colB)
        if not guard() then
                return
        end
        scale = scale or 1
        local holder = part({ Transparency = 1, CFrame = cf, Anchored = true, CastShadow = false })
        if holder == nil then
                return
        end
        local e = emitter(holder, {
                Texture = FIRE_TEX,
                Rate = 0,
                Speed = NumberRange.new(14 * scale, 30 * scale),
                Lifetime = NumberRange.new(0.3, 0.8),
                Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 2.4 * scale),
                        NumberSequenceKeypoint.new(1, 0),
                }),
                LightEmission = 1,
                Color = ColorSequence.new(colB or WHITE, colA or EMBER),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 4,
        })
        e:Emit(math.floor(60 * scale) + 20)
        local smoke = emitter(holder, {
                Texture = SMOKE_TEX,
                Rate = 0,
                Speed = NumberRange.new(6 * scale, 12 * scale),
                Lifetime = NumberRange.new(0.8, 1.6),
                Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 3 * scale),
                        NumberSequenceKeypoint.new(1, 8 * scale),
                }),
                Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.7),
                        NumberSequenceKeypoint.new(1, 1),
                }),
                Color = ColorSequence.new(Color3.fromRGB(120, 118, 126), Color3.fromRGB(40, 40, 46)),
                SpreadAngle = Vector2.new(180, 180),
                Drag = 3,
        })
        smoke:Emit(16)
        local l = pointLight(holder, colB or WHITE, 9, 26 * scale)
        if l then
                tween(l, twi(0.55), { Brightness = 0 })
        end
        local discs = {
                { CFrame.Angles(0, 0, math.rad(90)) },
                { CFrame.Angles(0, math.rad(90), 0) },
        }
        for _, dd in ipairs(discs) do
                local disc = part({
                        Shape = Enum.PartType.Cylinder,
                        Material = Enum.Material.Neon,
                        Color = colB or WHITE,
                        Transparency = 0.2,
                        Size = Vector3.new(0.5, 6 * scale, 6 * scale),
                        CFrame = cf * dd[1],
                        Anchored = true,
                        CastShadow = false,
                })
                if disc then
                        tween(disc, twi(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                                Size = Vector3.new(0.5, 30 * scale, 30 * scale),
                                Transparency = 1,
                        })
                        Debris:AddItem(disc, 0.65)
                end
        end
        Debris:AddItem(holder, 2.2)
end

-- flying fireball projectile
local function spawnFireball(fromPos, toPos, size, dur)
        if not guard() then
                return
        end
        local core = part({
                Shape = Enum.PartType.Ball,
                Material = Enum.Material.Neon,
                Color = EMBER2,
                Size = Vector3.new(size, size, size),
                CFrame = CFrame.new(fromPos),
                Anchored = true,
                CastShadow = false,
        })
        if core == nil then
                return
        end
        emitter(core, {
                Texture = FIRE_TEX,
                Rate = 80,
                Enabled = true,
                Speed = NumberRange.new(3, 6),
                Lifetime = NumberRange.new(0.25, 0.5),
                Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, size * 0.7),
                        NumberSequenceKeypoint.new(1, 0),
                }),
                LightEmission = 1,
                Color = emberSeq(),
                SpreadAngle = Vector2.new(180, 180),
        })
        pointLight(core, EMBER, 6, 34)
        tween(core, twi(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = toPos })
        task.delay(dur, function()
                if core and core.Parent then
                        explosionAt(CFrame.new(toPos), size * 1.7, EMBER, WHITE)
                        core:Destroy()
                end
        end)
        return core
end

-- dark glass shards falling from the broken sky
local function debrisRain(pos, color, n)
        if not guard() then
                return
        end
        for _ = 1, n do
                local sz = Vector3.new(0.6 + math.random() * 1.6, 0.6 + math.random() * 2.4, 0.4 + math.random() * 1)
                local p = part({
                        Material = Enum.Material.Glass,
                        Color = color or Color3.fromRGB(18, 16, 22),
                        Size = sz,
                        CFrame = CFrame.new(pos + Vector3.new((math.random() - 0.5) * 24, math.random() * 6, (math.random() - 0.5) * 10)) * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3),
                        Anchored = false,
                        CastShadow = false,
                })
                if p then
                        p.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * 8, -6 - math.random() * 8, (math.random() - 0.5) * 8)
                        p.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), math.random(-6, 6), math.random(-6, 6))
                        tween(p, twi(1.8 + math.random(), Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
                        Debris:AddItem(p, 3)
                end
        end
end

--============================================================--
--  CHARACTER
--============================================================--

local function setCharLTM(v)
        if char == nil then
                return
        end
        pcall(function()
                for _, d in ipairs(char:GetDescendants()) do
                        if d:IsA("BasePart") or d:IsA("Decal") then
                                d.LocalTransparencyModifier = v
                        end
                end
        end)
end

local function revealChar()
        if not introActive then
                return
        end
        task.spawn(function()
                for i = 1, 20 do
                        if not introActive then
                                return
                        end
                        setCharLTM(1 - i / 20)
                        task.wait(0.04)
                end
                setCharLTM(0)
        end)
        flash(0.35, WHITE)
        addShake(0.0022)
        sfx("ping", 1.5, 0.45)
        convergeTo(originPos + Vector3.new(0, 2.6, 0), WHITE, 12)
        windDisc(originPos + Vector3.new(0, 0.6, 0), SILVER, 1.1)
end

--============================================================--
--  SWORD v2  (rune ring / fuller core / guard blades / tip trail)
--  Blade grows along +Y from the grip origin.
--============================================================--

local function buildSword()
        if not guard() then
                return
        end
        swordModel = Instance.new("Model")
        swordModel.Name = "LegendsSilverSwordV2"
        swordParts = {}

        local function sp(props)
                local p = part(props, swordModel)
                if p then
                        table.insert(swordParts, p)
                end
                return p
        end

        -- grip (origin)
        local grip = sp({
                Size = Vector3.new(0.42, 1.5, 0.42),
                Color = Color3.fromRGB(34, 32, 38),
                Material = Enum.Material.Fabric,
                CFrame = CFrame.new(0, 0, 0),
        })
        if grip == nil then
                return
        end
        swordModel.PrimaryPart = grip

        sp({ -- pommel
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(0.34, 0.34, 0.34),
                Color = SILVER, Material = Enum.Material.Metal, Reflectance = 0.4,
                CFrame = CFrame.new(0, -0.86, 0),
        })
        sp({ -- crossguard
                Size = Vector3.new(1.9, 0.28, 0.62),
                Color = SILVER, Material = Enum.Material.Metal, Reflectance = 0.45,
                CFrame = CFrame.new(0, 0.86, 0),
        })
        sp({ -- guard blade tip right (slanted)
                Size = Vector3.new(0.42, 0.62, 0.5),
                Color = SILVER, Material = Enum.Material.Metal, Reflectance = 0.45,
                CFrame = CFrame.new(1.02, 1.06, 0) * CFrame.Angles(0, 0, math.rad(-28)),
        })
        sp({ -- guard blade tip left (slanted)
                Size = Vector3.new(0.42, 0.62, 0.5),
                Color = SILVER, Material = Enum.Material.Metal, Reflectance = 0.45,
                CFrame = CFrame.new(-1.02, 1.06, 0) * CFrame.Angles(0, 0, math.rad(28)),
        })
        sp({ -- polished blade
                Size = Vector3.new(0.26, 4.9, 0.95),
                Color = Color3.fromRGB(228, 234, 242),
                Material = Enum.Material.Metal, Reflectance = 0.5,
                CFrame = CFrame.new(0, 3.4, 0),
        })
        sp({ -- bevel strip right
                Size = Vector3.new(0.3, 4.9, 0.18),
                Color = Color3.fromRGB(240, 244, 250),
                Material = Enum.Material.Metal, Reflectance = 0.6,
                CFrame = CFrame.new(0, 3.4, 0.4),
        })
        sp({ -- bevel strip left
                Size = Vector3.new(0.3, 4.9, 0.18),
                Color = Color3.fromRGB(240, 244, 250),
                Material = Enum.Material.Metal, Reflectance = 0.6,
                CFrame = CFrame.new(0, 3.4, -0.4),
        })
        sp({ -- glowing fuller core (down the middle)
                Size = Vector3.new(0.1, 3.6, 0.14),
                Color = ICE, Material = Enum.Material.Neon,
                CFrame = CFrame.new(0, 3.2, 0),
        })
        sp({ -- neon edge right
                Size = Vector3.new(0.06, 4.9, 0.1),
                Color = ICE, Material = Enum.Material.Neon,
                CFrame = CFrame.new(0, 3.4, 0.52),
        })
        sp({ -- neon edge left
                Size = Vector3.new(0.06, 4.9, 0.1),
                Color = ICE, Material = Enum.Material.Neon,
                CFrame = CFrame.new(0, 3.4, -0.52),
        })
        sp({ -- tip
                Size = Vector3.new(0.2, 1.1, 0.62),
                Color = Color3.fromRGB(228, 234, 242),
                Material = Enum.Material.Metal, Reflectance = 0.5,
                CFrame = CFrame.new(0, 6.1, 0) * CFrame.Angles(math.rad(-13), 0, 0),
        })

        -- invisible tip part that carries the swing trail
        swordTip = part({
                Size = Vector3.new(0.15, 0.9, 0.15),
                Transparency = 1,
                CFrame = CFrame.new(0, 6.9, 0),
        }, swordModel)
        if swordTip then
                local a0 = Instance.new("Attachment")
                a0.Position = Vector3.new(0, 0.45, 0)
                a0.Parent = swordTip
                local a1 = Instance.new("Attachment")
                a1.Position = Vector3.new(0, -0.45, 0)
                a1.Parent = swordTip
                swordTrail = Instance.new("Trail")
                swordTrail.Attachment0 = a0
                swordTrail.Attachment1 = a1
                swordTrail.Color = ColorSequence.new(WHITE, ICE)
                swordTrail.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.15),
                        NumberSequenceKeypoint.new(1, 1),
                })
                swordTrail.WidthScale = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0.1),
                })
                swordTrail.Lifetime = 0.22
                swordTrail.LightEmission = 1
                swordTrail.FaceCamera = true
                swordTrail.Enabled = false
                swordTrail.Parent = swordTip
        end

        -- rotating rune ring around the blade (not welded: spun each frame)
        runeRing = part({
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.14, 2.3, 2.3),
                Color = ICE,
                Material = Enum.Material.Neon,
                Transparency = 1,
                CFrame = CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
        }, swordModel)
        -- NOTE: rune plates are welded ONLY to the ring (never to the grip),
        -- otherwise the per-frame ring spin would fight the grip welds.
        if runeRing then
                for _, rz in ipairs({ 0, 90, 180, 270 }) do
                        local rune = part({
                                Size = Vector3.new(0.06, 0.4, 0.4),
                                Color = WHITE,
                                Material = Enum.Material.Neon,
                                Transparency = 1,
                                CFrame = runeRing.CFrame * CFrame.Angles(0, 0, math.rad(rz)) * CFrame.new(0, 1.02, 0),
                        }, swordModel)
                        if rune then
                                weldTo(runeRing, rune)
                        end
                end
        end

        swordLight = Instance.new("PointLight")
        swordLight.Color = ICE
        swordLight.Brightness = 0
        swordLight.Range = 15
        swordLight.Shadows = true
        swordLight.Parent = grip

        swordEmit = emitter(grip, {
                Rate = 10,
                Enabled = true,
                Speed = NumberRange.new(1.5, 3.5),
                Lifetime = NumberRange.new(0.4, 0.9),
                Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.32),
                        NumberSequenceKeypoint.new(1, 0),
                }),
                LightEmission = 1,
                Color = silverSeq(),
                SpreadAngle = Vector2.new(40, 40),
        })

        for _, p in ipairs(swordParts) do
                p.CanCollide = false
                p.Massless = true
                p.Transparency = 1
                if p ~= grip then
                        weldTo(grip, p)
                end
        end
        swordTip.Transparency = 1
        weldTo(grip, swordTip)

        -- weld into the hand (tested offsets, R15 and R6)
        local gripCF
        if isR15 then
                gripCF = CFrame.new(0, -0.12, 0) * CFrame.Angles(math.pi, 0, math.rad(90))
        else
                gripCF = CFrame.new(0, -1.02, 0) * CFrame.Angles(math.pi, 0, math.rad(90))
        end
        grip.CFrame = handPart.CFrame * gripCF
        weldTo(grip, handPart)
        swordModel.Parent = char
end

local function revealSword()
        if swordParts == nil then
                return
        end
        for i, p in ipairs(swordParts) do
                task.delay(i * 0.06, function()
                        if p and p.Parent then
                                tween(p, twi(0.16), { Transparency = 0 })
                        end
                end)
        end
        -- rune ring + its plates fade in slightly later
        if runeRing then
                task.delay(0.5, function()
                        if not introActive then return end
                        if runeRing and runeRing.Parent then
                                tween(runeRing, twi(0.5), { Transparency = 0.45 })
                        end
                        for _, c in ipairs(runeRing:GetChildren()) do
                                if c:IsA("BasePart") then
                                        tween(c, twi(0.5), { Transparency = 0.2 })
                                end
                        end
                end)
        end
        if swordLight then
                tween(swordLight, twi(0.5), { Brightness = 1.6 })
        end
end

local function setSwordGlow(b, dur)
        if swordLight then
                tween(swordLight, twi(dur or 0.4), { Brightness = b })
        end
end

local function enableAura()
        if auraEmit then
                auraEmit.Enabled = true
        end
end

local function enableTrail(on)
        if swordTrail and swordTrail.Parent then
                swordTrail.Enabled = on and true or false
        end
end

--============================================================--
--  WORLD  (arena / sky rift / lightning / space)
--============================================================--

local function buildArena()
        if not guard() then
                return
        end
        local floorY = originPos.Y - 2.9

        -- floating stone disc
        part({
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(2, 120, 120),
                Color = Color3.fromRGB(38, 37, 44),
                Material = Enum.Material.Slate,
                CFrame = CFrame.new(originPos.X, floorY - 1, originPos.Z),
                Anchored = true,
                CastShadow = true,
        })
        -- neon rings placed ABOVE the surface (v1 bug fixed: they were buried)
        part({
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.6, 124, 124),
                Color = SILVER,
                Material = Enum.Material.Neon,
                Transparency = 0.55,
                CFrame = CFrame.new(originPos.X, floorY + 0.05, originPos.Z),
                Anchored = true,
                CastShadow = false,
        })
        part({
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.5, 152, 152),
                Color = ICE,
                Material = Enum.Material.Neon,
                Transparency = 0.78,
                CFrame = CFrame.new(originPos.X, floorY + 0.03, originPos.Z),
                Anchored = true,
                CastShadow = false,
        })

        -- glowing ground cracks radiating from the center
        for _ = 1, 9 do
                local len = 3 + math.random() * 4.5
                local ang = math.random() * math.pi * 2
                local r = 3 + math.random() * 11
                part({
                        Size = Vector3.new(0.22, 0.06, len),
                        Color = ICE,
                        Material = Enum.Material.Neon,
                        Transparency = 0.55,
                        CFrame = CFrame.new(originPos + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r) + Vector3.new(0, floorY - originPos.Y + 0.08, 0)) * CFrame.Angles(0, ang + math.rad(90), 0),
                        Anchored = true,
                        CastShadow = false,
                })
        end

        -- six broken columns with neon caps
        for i = 1, 6 do
                local ang = (i / 6) * math.pi * 2 + 0.3
                local r = 26 + math.random() * 4
                local h = 6 + math.random() * 6
                local base = originPos + Vector3.new(math.cos(ang) * r, floorY - originPos.Y, math.sin(ang) * r)
                local col = part({
                        Size = Vector3.new(2.6, h, 2.6),
                        Color = Color3.fromRGB(44, 43, 52),
                        Material = Enum.Material.Slate,
                        CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(math.random() * 0.1 - 0.05, math.random() * 3, math.random() * 0.1 - 0.05),
                        Anchored = true,
                        CastShadow = true,
                })
                if col then
                        part({
                                Size = Vector3.new(2.8, 0.22, 2.8),
                                Color = ICE,
                                Material = Enum.Material.Neon,
                                Transparency = 0.3,
                                CFrame = col.CFrame * CFrame.new(0, h / 2 + 0.1, 0),
                                Anchored = true,
                                CastShadow = false,
                        })
                end
                -- rubble at the foot of every second column
                if i % 2 == 0 then
                        part({
                                Shape = Enum.PartType.Ball,
                                Size = Vector3.new(1.6, 1.2, 1.4),
                                Color = Color3.fromRGB(40, 39, 48),
                                Material = Enum.Material.Slate,
                                CFrame = CFrame.new(base + Vector3.new(math.random(-2, 2), 0.5, math.random(-2, 2))),
                                Anchored = true,
                        })
                end
        end

        -- floating rock shards for depth
        for i = 1, 6 do
                local ang = (i / 6) * math.pi * 2 + math.random() * 0.5
                local r = 22 + math.random() * 14
                local h = 4 + math.random() * 10
                part({
                        Size = Vector3.new(4 + math.random() * 5, 1.6 + math.random() * 2, 3 + math.random() * 3),
                        Color = Color3.fromRGB(30, 28, 36),
                        Material = Enum.Material.Slate,
                        CFrame = CFrame.new(originPos + Vector3.new(math.cos(ang) * r, h, math.sin(ang) * r)) * CFrame.Angles(math.random() * 0.6 - 0.3, math.random() * 3, math.random() * 0.5 - 0.25),
                        Anchored = true,
                })
        end

        -- ground mist
        for i = 1, 3 do
                local ang = (i / 3) * math.pi * 2
                local holder = part({
                        Transparency = 1,
                        Size = Vector3.new(1, 1, 1),
                        CFrame = CFrame.new(originPos + Vector3.new(math.cos(ang) * 13, 1, math.sin(ang) * 13)),
                        Anchored = true,
                        CastShadow = false,
                })
                if holder then
                        emitter(holder, {
                                Texture = SMOKE_TEX,
                                Rate = 7,
                                Enabled = true,
                                Speed = NumberRange.new(0.8, 1.6),
                                Lifetime = NumberRange.new(3, 5),
                                Size = NumberSequence.new({
                                        NumberSequenceKeypoint.new(0, 9),
                                        NumberSequenceKeypoint.new(1, 20),
                                }),
                                Transparency = NumberSequence.new({
                                        NumberSequenceKeypoint.new(0, 0.88),
                                        NumberSequenceKeypoint.new(0.5, 0.8),
                                        NumberSequenceKeypoint.new(1, 1),
                                }),
                                Color = ColorSequence.new(Color3.fromRGB(210, 216, 228)),
                                LightEmission = 0.12,
                        })
                end
        end

        -- silver moon watching from behind
        moonPart = part({
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(24, 24, 24),
                Color = Color3.fromRGB(225, 230, 240),
                Material = Enum.Material.SmoothPlastic,
                Reflectance = 0.08,
                CFrame = CFrame.new(originPos - lookH * 150 + rightH * 90 + Vector3.new(0, 150, 0)),
                Anchored = true,
                CastShadow = false,
        })
        if moonPart then
                local ml = Instance.new("SurfaceLight")
                ml.Face = Enum.NormalId.Front
                ml.Brightness = 0.6
                ml.Range = 300
                ml.Parent = moonPart
                moonPart.CFrame = CFrame.lookAt(moonPart.Position, originPos + Vector3.new(0, 6, 0))
        end
end

----------------------------------------------------------- SKY RIFT v2
local function buildCrack()
        if not guard() then
                return
        end
        crackGroup = Instance.new("Model")
        crackGroup.Name = "SkyRift"

        -- the "torn piece of sky": dark void slab behind the fissure
        local slab = part({
                Size = Vector3.new(110, 170, 6),
                Color = VOID,
                Material = Enum.Material.Glass,
                Transparency = 0.15,
                CFrame = CFrame.lookAt(crackPos, crackPos - lookH),
                Anchored = true,
                CastShadow = false,
                Parent = crackGroup,
        })

        -- glowing zig-zag fissure (tested: local -3.6 offset on the front face)
        local slabCF = CFrame.lookAt(crackPos, crackPos - lookH)
        for i = 1, 6 do
                local segH = 26 + math.random() * 9
                local seg = part({
                        Size = Vector3.new(3.4 + math.random() * 1.8, segH, 2),
                        Color = WHITE,
                        Material = Enum.Material.Neon,
                        CFrame = slabCF
                                * CFrame.new((i % 2 == 0) and 7 or -6 + math.random() * 4, -75 + (i - 1) * 26, -3.6)
                                * CFrame.Angles(0, 0, math.rad(math.random(-28, 28))),
                        Anchored = true,
                        CastShadow = false,
                        Parent = crackGroup,
                })
                if seg then
                        emitter(seg, {
                                Rate = 18,
                                Enabled = true,
                                Speed = NumberRange.new(3, 8),
                                Lifetime = NumberRange.new(0.6, 1.4),
                                Size = NumberSequence.new({
                                        NumberSequenceKeypoint.new(0, 0.5),
                                        NumberSequenceKeypoint.new(1, 0),
                                }),
                                LightEmission = 1,
                                Color = silverSeq(),
                                SpreadAngle = Vector2.new(180, 180),
                        })
                end
        end

        -- god rays slanting down from the rift toward the arena
        for i = 1, 4 do
                local target = originPos + Vector3.new(0, 4, 0)
                local mid = crackPos:Lerp(target, 0.5) + rightH * ((i - 2.5) * 10)
                part({
                        Size = Vector3.new(5 + i * 1.6, 5 + i * 1.6, 240),
                        Color = ICE,
                        Material = Enum.Material.Neon,
                        Transparency = 0.86,
                        CFrame = CFrame.lookAt(mid, crackPos),
                        Anchored = true,
                        CastShadow = false,
                        Parent = crackGroup,
                })
        end

        -- strobing lightning chains (invisible until lightningStrike)
        lightningArcs = {}
        for chain = 1, 3 do
                local bx = (chain - 2) * 30 + math.random(-8, 8)
                local prevTop = nil
                for s = 1, 4 do
                        local seg = part({
                                Size = Vector3.new(0.6, 9, 0.6),
                                Color = WHITE,
                                Material = Enum.Material.Neon,
                                Transparency = 1,
                                CFrame = slabCF
                                        * CFrame.new(bx + math.random(-6, 6), 40 - s * 22, -4)
                                        * CFrame.Angles(math.rad(math.random(-18, 18)), 0, math.rad(math.random(-18, 18))),
                                Anchored = true,
                                CastShadow = false,
                                Parent = crackGroup,
                        })
                        if seg then
                                table.insert(lightningArcs, seg)
                                prevTop = seg
                        end
                end
        end

        -- rift light (the render loop breathes it every frame)
        crackLight = pointLight(slab, ICE, 6, 220)

        crackGroup.Parent = sceneFolder

        -- rift FX: shock rings + falling shards
        sfx("impact", 0.5, 0.8)
        for i = 1, 3 do
                beat(0.12 * i, function()
                        windDisc(crackPos, ICE, 6 + i * 3)
                end)
        end
        beat(0.25, function()
                debrisRain(crackPos - Vector3.new(0, 20, 0), Color3.fromRGB(16, 14, 20), 9)
        end)
        beat(0.9, function()
                debrisRain(crackPos - Vector3.new(0, 30, 0), Color3.fromRGB(16, 14, 20), 6)
        end)
end

local function lightningStrike()
        if not guard() then
                return
        end
        for _, seg in ipairs(lightningArcs) do
                if seg and seg.Parent then
                        seg.Transparency = 0.05
                        tween(seg, twi(0.14), { Transparency = 1 })
                end
        end
        flash(0.18, WHITE)
        addShake(0.011)
        bloomPulse(2.4, 0.55)
        sfx("impact", 0.32, 0.75)
end

------------------------------------------------------------ SPACE BUILD
local function buildSpace()
        if not guard() then
                return
        end
        -- star dome (follows the camera in the render loop)
        starDome = Instance.new("Model")
        starDome.Name = "LegendsStarDome"
        for _ = 1, 130 do
                local ang = math.random() * math.pi * 2
                local el = (math.random() - 0.35) * math.pi * 0.9
                local r = 700 + math.random() * 260
                local dir = Vector3.new(math.cos(ang) * math.cos(el), math.sin(el), math.sin(ang) * math.cos(el))
                local sz = 0.4 + math.random() * 1.8
                part({
                        Shape = Enum.PartType.Ball,
                        Material = Enum.Material.Neon,
                        Color = WHITE,
                        Size = Vector3.new(sz, sz, sz),
                        CFrame = CFrame.new(dir * r),
                        Anchored = true,
                        CastShadow = false,
                        Parent = starDome,
                })
        end
        starDome.Parent = sceneFolder

        -- gas planet on the horizon
        local dir = (lookH + rightH * 2.2 + Vector3.new(0, 0.35, 0)).Unit
        local ppos = spaceEndPos + dir * 2000
        part({
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(320, 320, 320),
                Color = Color3.fromRGB(72, 92, 150),
                Material = Enum.Material.SmoothPlastic,
                Reflectance = 0.05,
                CFrame = CFrame.new(ppos),
                Anchored = true,
                CastShadow = false,
        })
        part({ -- atmosphere halo
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(352, 352, 352),
                Color = ICE,
                Material = Enum.Material.Neon,
                Transparency = 0.9,
                CFrame = CFrame.new(ppos),
                Anchored = true,
                CastShadow = false,
        })
        part({ -- planetary ring
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(4, 620, 620),
                Color = Color3.fromRGB(150, 168, 205),
                Material = Enum.Material.SmoothPlastic,
                Transparency = 0.55,
                CFrame = CFrame.new(ppos) * CFrame.Angles(math.rad(75), 0, math.rad(20)),
                Anchored = true,
                CastShadow = false,
        })
        -- small silver moon
        part({
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(60, 60, 60),
                Color = Color3.fromRGB(225, 230, 240),
                Material = Enum.Material.SmoothPlastic,
                CFrame = CFrame.new(spaceEndPos - dir * 1400 + rightH * 700 + Vector3.new(0, 260, 0)),
                Anchored = true,
                CastShadow = false,
        })

        -- faint colored nebulae around the space destination
        local nebulaData = {
                { Vector3.new(300, 80, -400), Color3.fromRGB(120, 90, 200) },
                { Vector3.new(-350, -40, -600), Color3.fromRGB(60, 110, 200) },
                { Vector3.new(0, 150, -800), Color3.fromRGB(90, 80, 190) },
        }
        for _, nb in ipairs(nebulaData) do
                local holder = part({
                        Transparency = 1,
                        Size = Vector3.new(1, 1, 1),
                        CFrame = CFrame.new(spaceEndPos + dir * 1200 + nb[1]),
                        Anchored = true,
                        CastShadow = false,
                })
                if holder then
                        emitter(holder, {
                                Texture = SMOKE_TEX,
                                Rate = 2,
                                Enabled = true,
                                Speed = NumberRange.new(1, 3),
                                Lifetime = NumberRange.new(8, 13),
                                Size = NumberSequence.new({
                                        NumberSequenceKeypoint.new(0, 60),
                                        NumberSequenceKeypoint.new(1, 110),
                                }),
                                Transparency = NumberSequence.new({
                                        NumberSequenceKeypoint.new(0, 1),
                                        NumberSequenceKeypoint.new(0.35, 0.88),
                                        NumberSequenceKeypoint.new(1, 1),
                                }),
                                Color = ColorSequence.new(nb[2]),
                                LightEmission = 0.55,
                                RotSpeed = NumberRange.new(-3, 3),
                        })
                end
        end
end

--============================================================--
--  DRAGON  (motorized chains / jaw / fire / shatter death)
--============================================================--

local function buildDragon(spawnCF)
        if not guard() then
                return
        end
        local model = Instance.new("Model")
        model.Name = "VoidDragon"

        dragon = {
                model = model,
                alive = true,
                frozen = false,
                flapSpeed = 5,
                flapAmp = 0.3,
                jawOpen = 0,
                jawTarget = 0,
                headYaw = 0,
                headPitch = 0,
                tail = {},
                neck = {},
                molten = {},
                eyeParts = {},
        }

        local function dp(props)
                return part(props, model)
        end

        -- ROOT (anchored core; everything hangs off it)
        local root = dp({
                Size = Vector3.new(9, 7.5, 20),
                Color = OBSIDIAN,
                Material = Enum.Material.Slate,
                CFrame = spawnCF,
                Anchored = true,
                CastShadow = true,
        })
        if root == nil then
                return
        end
        dragon.root = root
        model.PrimaryPart = root

        -- chest
        local chest = dp({
                Size = Vector3.new(8, 6.5, 9),
                Color = OBSIDIAN,
                Material = Enum.Material.Slate,
                CFrame = root.CFrame * CFrame.new(0, -0.2, -12),
        })
        weldTo(root, chest)

        -- molten cracks on the chest
        for i = 1, 4 do
                local cr = dp({
                        Size = Vector3.new(0.42, 3 + math.random() * 2, 0.42),
                        Color = EMBER,
                        Material = Enum.Material.Neon,
                        CFrame = root.CFrame * CFrame.new(-2.6 + i * 1.7, 0.5, -13.5) * CFrame.Angles(0, 0, math.rad(math.random(-22, 22))),
                })
                if cr then
                        table.insert(dragon.molten, cr)
                        weldTo(root, cr)
                end
        end

        -- back spikes
        for i = 1, 5 do
                local spk = dp({
                        Size = Vector3.new(0.7, 2.8 - i * 0.28, 0.7),
                        Color = Color3.fromRGB(210, 205, 218),
                        Material = Enum.Material.Marble,
                        CFrame = root.CFrame * CFrame.new(0, 4.4, 7 - i * 3.6) * CFrame.Angles(math.rad(-24), 0, 0),
                })
                weldTo(root, spk)
        end

        -- neck chain (4 segments, motorized)
        local neckSizes = {
                Vector3.new(6, 5.4, 6.5), Vector3.new(5.2, 4.6, 6),
                Vector3.new(4.4, 4, 5.5), Vector3.new(3.7, 3.4, 5),
        }
        local neckOffs = {
                CFrame.new(0, 1.8, -15.5) * CFrame.Angles(math.rad(-14), 0, 0),
                CFrame.new(0, 3.8, -20) * CFrame.Angles(math.rad(-10), 0, 0),
                CFrame.new(0, 5.4, -24) * CFrame.Angles(math.rad(-6), 0, 0),
                CFrame.new(0, 6.6, -27.8) * CFrame.Angles(math.rad(-2), 0, 0),
        }
        local prev = root
        for i = 1, 4 do
                local seg = dp({
                        Size = neckSizes[i],
                        Color = OBSIDIAN,
                        Material = Enum.Material.Slate,
                        CFrame = root.CFrame * neckOffs[i],
                })
                if seg then
                        local pivotW = root.CFrame * (neckOffs[i] * CFrame.new(0, 0, 2.5))
                        local m = motor6d(prev, seg, pivotW)
                        if m then
                                table.insert(dragon.neck, m)
                        end
                        prev = seg
                end
        end

        -- head
        local head = dp({
                Size = Vector3.new(4.6, 3.8, 6.4),
                Color = OBSIDIAN,
                Material = Enum.Material.Slate,
                CFrame = root.CFrame * CFrame.new(0, 7.4, -32.5) * CFrame.Angles(math.rad(4), 0, 0),
                CastShadow = true,
        })
        if head then
                dragon.head = motor6d(prev, head, root.CFrame * CFrame.new(0, 6.6, -27.8))

                -- snout
                local snout = dp({
                        Size = Vector3.new(3.2, 2, 4.6),
                        Color = OBSIDIAN,
                        Material = Enum.Material.Slate,
                        CFrame = head.CFrame * CFrame.new(0, -0.4, -4.6),
                })
                weldTo(head, snout)

                -- jaw
                local jaw = dp({
                        Size = Vector3.new(3, 0.9, 4.4),
                        Color = Color3.fromRGB(40, 34, 44),
                        Material = Enum.Material.Slate,
                        CFrame = head.CFrame * CFrame.new(0, -1.6, -4.4),
                })
                dragon.jaw = motor6d(head, jaw, head.CFrame * CFrame.new(0, -1.2, -1.6))

                -- fangs
                for i = 1, 3 do
                        local fang = dp({
                                Size = Vector3.new(0.35, 0.9, 0.35),
                                Color = Color3.fromRGB(235, 232, 240),
                                Material = Enum.Material.SmoothPlastic,
                                CFrame = head.CFrame * CFrame.new(-1 + i, -0.9, -6.2),
                        })
                        weldTo(head, fang)
                end

                -- horns with glowing tips
                for _, sx in ipairs({ -1, 1 }) do
                        local horn = dp({
                                Size = Vector3.new(0.8, 3.2, 0.8),
                                Color = Color3.fromRGB(215, 210, 222),
                                Material = Enum.Material.Marble,
                                CFrame = head.CFrame * CFrame.new(sx * 1.5, 2.4, 1) * CFrame.Angles(math.rad(-38), 0, sx * math.rad(14)),
                        })
                        weldTo(head, horn)
                        local tip = dp({
                                Shape = Enum.PartType.Ball,
                                Size = Vector3.new(0.34, 0.34, 0.34),
                                Color = ICE,
                                Material = Enum.Material.Neon,
                                CFrame = horn.CFrame * CFrame.new(0, 1.7, 0),
                        })
                        weldTo(head, tip)
                end

                -- burning eyes
                for _, sx in ipairs({ -1, 1 }) do
                        local eye = dp({
                                Shape = Enum.PartType.Ball,
                                Size = Vector3.new(1.1, 1.1, 1.1),
                                Color = EMBER,
                                Material = Enum.Material.Neon,
                                CFrame = head.CFrame * CFrame.new(sx * 1.5, 0.7, -2.9),
                        })
                        if eye then
                                table.insert(dragon.eyeParts, eye)
                                weldTo(head, eye)
                        end
                end
                pointLight(head, EMBER, 4, 40)

                -- mouth fire core + emitter
                local mouthCore = dp({
                        Shape = Enum.PartType.Ball,
                        Size = Vector3.new(1.1, 1.1, 1.1),
                        Color = EMBER2,
                        Material = Enum.Material.Neon,
                        Transparency = 0.25,
                        CFrame = head.CFrame * CFrame.new(0, -1.1, -6.4),
                })
                weldTo(head, mouthCore)
                dragon.mouthEmit = emitter(mouthCore, {
                        Texture = FIRE_TEX,
                        Rate = 0,
                        Enabled = true,
                        Speed = NumberRange.new(8, 14),
                        Lifetime = NumberRange.new(0.2, 0.45),
                        Size = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 2.2),
                                NumberSequenceKeypoint.new(1, 0),
                        }),
                        LightEmission = 1,
                        Color = emberSeq(),
                        SpreadAngle = Vector2.new(14, 14),
                        EmissionDirection = Enum.NormalId.Front,
                })
                dragon.mouthLight = pointLight(mouthCore, EMBER, 4, 32)
        end

        -- wings (motorized bone chains + membranes)
        for _, sx in ipairs({ -1, 1 }) do
                local shoulderPos = root.CFrame * CFrame.new(sx * 5.5, 2.4, -3)
                local b1 = dp({
                        Size = Vector3.new(15, 0.9, 4),
                        Color = OBSIDIAN,
                        Material = Enum.Material.Slate,
                        CFrame = shoulderPos * CFrame.new(sx * 7, 0.8, 0),
                        CastShadow = true,
                })
                if b1 then
                        local m1 = motor6d(root, b1, shoulderPos)
                        local mem1 = dp({
                                Size = Vector3.new(13, 7.5, 0.35),
                                Color = Color3.fromRGB(66, 30, 38),
                                Material = Enum.Material.SmoothPlastic,
                                Transparency = 0.25,
                                CFrame = shoulderPos * CFrame.new(sx * 7.5, -2.8, 0.6),
                        })
                        weldTo(b1, mem1)
                        local elbowPos = shoulderPos * CFrame.new(sx * 14, 1.6, 0)
                        local b2 = dp({
                                Size = Vector3.new(13, 0.8, 3.4),
                                Color = OBSIDIAN,
                                Material = Enum.Material.Slate,
                                CFrame = elbowPos * CFrame.new(sx * 6, 1.2, 2.2),
                        })
                        if b2 then
                                local m2 = motor6d(b1, b2, elbowPos)
                                local mem2 = dp({
                                        Size = Vector3.new(11.5, 6.5, 0.35),
                                        Color = Color3.fromRGB(66, 30, 38),
                                        Material = Enum.Material.SmoothPlastic,
                                        Transparency = 0.25,
                                        CFrame = elbowPos * CFrame.new(sx * 6.5, -2.2, 2.6),
                                })
                                weldTo(b2, mem2)
                                if sx < 0 then
                                        dragon.wingL1 = m1
                                        dragon.wingL2 = m2
                                else
                                        dragon.wingR1 = m1
                                        dragon.wingR2 = m2
                                end
                        end
                end
        end

        -- tail chain (4 motorized segments)
        local tailSizes = {
                Vector3.new(4.6, 4, 7), Vector3.new(3.6, 3.2, 7),
                Vector3.new(2.8, 2.5, 7), Vector3.new(1.8, 1.7, 7),
        }
        local tailOffs = {
                CFrame.new(0, 0.4, 13), CFrame.new(0, 0.9, 19),
                CFrame.new(0, 1.5, 25), CFrame.new(0, 2.2, 31),
        }
        prev = root
        local lastTail = root
        for i = 1, 4 do
                local seg = dp({
                        Size = tailSizes[i],
                        Color = OBSIDIAN,
                        Material = Enum.Material.Slate,
                        CFrame = root.CFrame * tailOffs[i],
                })
                if seg then
                        local pivotW = root.CFrame * (tailOffs[i] * CFrame.new(0, 0, -3))
                        local m = motor6d(prev, seg, pivotW)
                        if m then
                                table.insert(dragon.tail, m)
                        end
                        prev = seg
                        lastTail = seg
                end
        end
        -- tail blade
        local tblade = dp({
                Size = Vector3.new(0.4, 3.4, 1.6),
                Color = Color3.fromRGB(215, 210, 222),
                Material = Enum.Material.Marble,
                CFrame = root.CFrame * (tailOffs[4] * CFrame.new(0, 1.6, 3.8)) * CFrame.Angles(math.rad(30), 0, 0),
        })
        weldTo(lastTail, tblade)

        -- tucked legs + claws
        for _, sx in ipairs({ -1, 1 }) do
                local thigh = dp({
                        Size = Vector3.new(3.2, 3.8, 4),
                        Color = OBSIDIAN,
                        Material = Enum.Material.Slate,
                        CFrame = root.CFrame * CFrame.new(sx * 3.8, -3.6, 4) * CFrame.Angles(math.rad(35), 0, 0),
                })
                weldTo(root, thigh)
                local claw = dp({
                        Size = Vector3.new(2, 1.2, 3),
                        Color = Color3.fromRGB(215, 210, 222),
                        Material = Enum.Material.Metal,
                        CFrame = root.CFrame * CFrame.new(sx * 3.8, -5.4, 6.2) * CFrame.Angles(math.rad(20), 0, 0),
                })
                weldTo(root, claw)
        end

        -- ember dust drifting off the body
        emitter(root, {
                Texture = FIRE_TEX,
                Rate = 34,
                Enabled = true,
                Speed = NumberRange.new(2, 5),
                Lifetime = NumberRange.new(0.5, 1.2),
                Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1.2),
                        NumberSequenceKeypoint.new(1, 0),
                }),
                LightEmission = 1,
                Color = emberSeq(),
                SpreadAngle = Vector2.new(70, 70),
        })

        -- tweenable base CFrame (render loop adds hover bob)
        dragon.base = spawnCF
        local baseValue = Instance.new("CFrameValue")
        baseValue.Value = spawnCF
        baseValue.Changed:Connect(function(v)
                if dragon then
                        dragon.base = v
                end
        end)
        baseValue.Name = "DragonBase"
        baseValue.Parent = model
        dragon.baseValue = baseValue

        model.Parent = sceneFolder
end

local function setJaw(v)
        if dragon then
                dragon.jawTarget = v
        end
end

-- dragon death: freeze -> white-hot -> shatter into embers
local function shatterDragon()
        if dragon == nil then
                return
        end
        dragon.alive = false
        local model = dragon.model
        local center = dragon.root.Position

        for _, j in ipairs(model:GetDescendants()) do
                if j:IsA("Motor6D") or j:IsA("WeldConstraint") then
                        j:Destroy()
                end
        end
        for _, p in ipairs(model:GetDescendants()) do
                if p:IsA("BasePart") then
                        p.Anchored = false
                        p.CanCollide = false
                        local dir = p.Position - center
                        if dir.Magnitude < 0.5 then
                                dir = Vector3.new(0, 1, 0)
                        end
                        p.AssemblyLinearVelocity = dir.Unit * math.random(28, 55) + Vector3.new(0, math.random(14, 30), 0)
                        p.AssemblyAngularVelocity = Vector3.new(math.random(-9, 9), math.random(-9, 9), math.random(-9, 9))
                        tween(p, twi(1.4 + math.random() * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 })
                elseif p:IsA("ParticleEmitter") then
                        p.Enabled = false
                elseif p:IsA("PointLight") then
                        p.Enabled = false
                end
        end

        explosionAt(CFrame.new(center), 3.5, EMBER, WHITE)
        Debris:AddItem(model, 3.6)
        dragon = nil
end

--============================================================--
--  POSE SYSTEM v2  (13 poses, blended + procedural layer)
--============================================================--

local POSES = {
        IDLE     = { shR = 6,   shL = 4,  neck = 2,   waist = 0 },
        GRIP     = { shR = 48,  shL = 10, neck = 0,   waist = 0 },
        FORGE    = { shR = 92,  shL = 22, neck = -8,  waist = 0 },
        RAISE    = { shR = 150, shL = 16, neck = -16, waist = 0 },
        GAZE     = { shR = 168, shL = 12, neck = -26, waist = 0 },
        WINDUP   = { shR = 186, shL = 26, neck = -18, waist = 5 },
        SLASH    = { shR = 88,  shL = 6,  neck = -6,  waist = -4 },
        BATTLE   = { shR = 112, shL = 34, neck = -4,  waist = 0 },
        DODGE    = { shR = 62,  shL = 46, neck = 2,   waist = 0 },
        VICTORY  = { shR = 176, shL = 18, neck = -10, waist = 0 },
        HEROLAND = { shR = 24,  shL = 8,  neck = 4,   waist = 0 },
        ASCEND   = { shR = 172, shL = 14, neck = -12, waist = 0 },
        SOAR     = { shR = 58,  shL = 42, neck = -18, waist = 0 },
}

local function setPose(name, rate)
        local p = POSES[name]
        if p == nil then
                return
        end
        for k, v in pairs(p) do
                poseTgt[k] = v
        end
        if rate then
                poseRate = rate
        end
end

local function snapPose()
        poseSnap = true
end

local function setTremble(a)
        trembleAmp = a
end

local function setupJoints()
        joints = {}
        if char == nil then
                return false
        end
        if isR15 then
                local rua = char:FindFirstChild("RightUpperArm")
                local lua = char:FindFirstChild("LeftUpperArm")
                local head = char:FindFirstChild("Head")
                local ut = char:FindFirstChild("UpperTorso")
                if rua then
                        joints.rShoulder = rua:FindFirstChild("RightShoulder")
                end
                if lua then
                        joints.lShoulder = lua:FindFirstChild("LeftShoulder")
                end
                if head then
                        joints.neck = head:FindFirstChild("Neck")
                end
                if ut then
                        joints.waist = ut:FindFirstChild("Waist")
                end
        else
                local torso = char:FindFirstChild("Torso")
                if torso then
                        joints.rShoulder = torso:FindFirstChild("Right Shoulder")
                        joints.lShoulder = torso:FindFirstChild("Left Shoulder")
                        joints.neck = torso:FindFirstChild("Neck")
                end
        end
        return joints.rShoulder ~= nil
end

-- runs every frame: numeric blending toward the target pose + a live
-- procedural layer (breathing / tremble / sword sway) on top
local function animationStep(dt, t)
        local k = math.clamp(dt * poseRate, 0, 1)
        for key, v in pairs(poseTgt) do
                poseCur[key] = poseCur[key] + (v - poseCur[key]) * k
        end
        if poseSnap then
                for key, v in pairs(poseTgt) do
                        poseCur[key] = v
                end
                poseSnap = false
        end

        -- procedural layer
        local breath = math.sin(t * 1.7) * 1.3
        local trem = math.noise(t * 8.5, 7.7, 0) * trembleAmp
        local sway = math.sin(t * 2.3) * 1.1 + math.noise(t * 3.3, 1.2, 0) * 1.4

        local shR = poseCur.shR + breath * 0.35 + trem
        local shL = poseCur.shL - breath * 0.25
        local neck = poseCur.neck + math.sin(t * 0.9) * 0.8
        local lean = sway * 0.18

        if joints.rShoulder and joints.rShoulder.Parent then
                if isR15 then
                        joints.rShoulder.Transform = CFrame.Angles(math.rad(shR), 0, math.rad(6 + lean))
                else
                        joints.rShoulder.Transform = CFrame.Angles(0, math.rad(lean * 0.5), math.rad(shR))
                end
        end
        if joints.lShoulder and joints.lShoulder.Parent then
                if isR15 then
                        joints.lShoulder.Transform = CFrame.Angles(math.rad(-shL), 0, math.rad(-6 - lean * 0.6))
                else
                        joints.lShoulder.Transform = CFrame.Angles(0, 0, math.rad(-shL))
                end
        end
        if joints.neck and joints.neck.Parent then
                joints.neck.Transform = CFrame.Angles(math.rad(neck), 0, 0)
        end
        if joints.waist and joints.waist.Parent then
                joints.waist.Transform = CFrame.Angles(math.rad(poseCur.waist), 0, math.rad(lean * 0.5))
        end
end

--============================================================--
--  DRAGON LIFE (runs every frame)
--============================================================--

local function dragonUpdate(dt, t)
        if dragon == nil or dragon.alive == false or dragon.frozen then
                return
        end
        local bob = math.sin(t * 1.15) * 2.2
        local roll = math.sin(t * 0.7) * 0.03
        if dragon.root and dragon.root.Parent then
                dragon.root.CFrame = dragon.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, roll)
        end

        local f1 = math.sin(t * dragon.flapSpeed) * dragon.flapAmp
        local f2 = math.sin(t * dragon.flapSpeed - 0.8) * dragon.flapAmp * 0.55
        if dragon.wingL1 then
                dragon.wingL1.Transform = CFrame.Angles(0, 0, -f1)
        end
        if dragon.wingR1 then
                dragon.wingR1.Transform = CFrame.Angles(0, 0, f1)
        end
        if dragon.wingL2 then
                dragon.wingL2.Transform = CFrame.Angles(0, 0, -f2)
        end
        if dragon.wingR2 then
                dragon.wingR2.Transform = CFrame.Angles(0, 0, f2)
        end

        for i, m in ipairs(dragon.tail) do
                m.Transform = CFrame.Angles(math.sin(t * 1.3 + i * 0.7) * 0.10, math.sin(t * 0.9 + i * 0.55) * 0.16, 0)
        end
        for i, m in ipairs(dragon.neck) do
                m.Transform = CFrame.Angles(math.sin(t * 0.8 + i * 0.5) * 0.045, 0, 0)
        end
        if dragon.head then
                dragon.head.Transform = CFrame.Angles(dragon.headPitch + math.sin(t * 0.6) * 0.03, dragon.headYaw, 0)
        end
        dragon.jawOpen = dragon.jawOpen + ((dragon.jawTarget or 0) - dragon.jawOpen) * math.clamp(dt * 9, 0, 1)
        if dragon.jaw then
                dragon.jaw.Transform = CFrame.Angles(-math.rad(26 * dragon.jawOpen), 0, 0)
        end
end

--======================================================================--
--                      THE 8 CINEMATIC PHASES (1-4)
--======================================================================--

-- PHASE 1: ground scene, the player fades in from motes of light
local function phaseGround(d)
        local t0 = os.clock()
        setCharLTM(1)
        fade(1, 1.4)
        letterIn()
        setPose("IDLE")

        local p0 = originPos + lookH * 8.5 + rightH * 4.5 + Vector3.new(0, 1.1, 0)
        camSet(CFrame.lookAt(p0, originPos + Vector3.new(0, 2.6, 0)))
        fovVal.Value = 50
        task.wait(0.4)
        if not introActive then return end

        camTo(CFrame.lookAt(originPos + lookH * 7 + rightH * 2 + Vector3.new(0, 1.7, 0), originPos + Vector3.new(0, 2.4, 0)), 2.6, {
                style = Enum.EasingStyle.Sine, dir = Enum.EasingDirection.InOut, fov = 52,
        })
        beat(1.4, function() convergeTo(originPos + Vector3.new(0, 2.6, 0), ICE, 10) end)
        beat(2.2, function()
                convergeTo(originPos + Vector3.new(0, 2.6, 0), WHITE, 14)
                sfx("ping", 1.3, 0.3)
        end)
        task.wait(2.8)
        if not introActive then return end

        revealChar()
        task.wait(1.6)
        if not introActive then return end

        camTo(CFrame.lookAt(originPos + lookH * 6.4 - rightH * 1.2 + Vector3.new(0, 0.4, 0), originPos + Vector3.new(0, 2.9, 0)), 1.8, {
                style = Enum.EasingStyle.Quint, dir = Enum.EasingDirection.InOut, fov = 50, roll = 1.5,
        })
        task.wait(math.max(0.05, d - (os.clock() - t0)))
end

-- PHASE 2: the legendary silver sword materializes in his hand
local function phaseSword(d)
        local t0 = os.clock()
        setPose("GRIP")
        buildSword()

        local hp = handPart and handPart.Position or originPos
        camTo(CFrame.lookAt(
                originPos + lookH * 4.6 + rightH * 3.6 + Vector3.new(0, 2.2, 0),
                originPos + lookH * 1.2 + rightH * 1.1 + Vector3.new(0, 2.4, 0)
        ), 0.9, { style = Enum.EasingStyle.Quart, fov = 44 })
        task.wait(0.9)
        if not introActive then return end

        convergeTo(hp, ICE, 16)
        convergeTo(hp, WHITE, 10)
        task.wait(0.8)
        if not introActive then return end

        sfx("unsheath", 1, 0.7)
        flash(0.35, WHITE)
        addShake(0.0025)
        revealSword()
        task.wait(0.9)
        if not introActive then return end

        setPose("FORGE", 8)
        setSwordGlow(2.2, 0.5)
        enableAura()
        bloomPulse(1.6, 0.8)
        beat(0.3, function() windDisc(originPos + Vector3.new(0, 1, 0), SILVER, 1) end)
        camTo(CFrame.lookAt(
                originPos + lookH * 7.5 - rightH * 2.6 + Vector3.new(0, 0.2, 0),
                originPos + Vector3.new(0, 3.2, 0)
        ), 1.4, { style = Enum.EasingStyle.Quint, dir = Enum.EasingDirection.InOut, fov = 50, roll = -2 })
        task.wait(math.max(0.05, d - (os.clock() - t0)))
end

-- PHASE 3: he slowly raises the sword and gazes at the sky
local function phaseGaze(d)
        local t0 = os.clock()
        setPose("RAISE", 5)

        tween(Lighting, twi(2.5), { ExposureCompensation = -0.25 })
        setAtmo({ Haze = 1.4, Color = Color3.fromRGB(188, 196, 212) }, 2.5)
        setGrade({ Contrast = 0.12, Saturation = -0.08 }, 2)
        sfx("impact", 0.45, 0.5)

        local eye = originPos + Vector3.new(0, 3, 0)
        camTo(CFrame.lookAt(eye - lookH * 7.5 + rightH * 3.2, crackPos), 1.6, {
                style = Enum.EasingStyle.Sine, dir = Enum.EasingDirection.InOut, fov = 58, roll = 4,
        })
        task.wait(1.7)
        if not introActive then return end

        setPose("GAZE")
        sfx("impact", 0.4, 0.55)
        bloomPulse(1.3, 1.2)
        camTo(CFrame.lookAt(eye - lookH * 5.5 + rightH * 2.4, crackPos + Vector3.new(0, 10, 0)), 1.6, {
                style = Enum.EasingStyle.Sine, dir = Enum.EasingDirection.In, fov = 60,
        })
        task.wait(math.max(0.05, d - (os.clock() - t0)))
end

-- PHASE 4: THE SKY-SPLITTING SLASH
local function phaseSlash(d)
        local t0 = os.clock()
        setPose("WINDUP", 10)
        setTremble(1.4)
        camTo(CFrame.lookAt(
                originPos - lookH * 10 + rightH * 4 + Vector3.new(0, 3.5, 0),
                originPos + Vector3.new(0, 12, 0) + lookH * 4
        ), 0.7, { fov = 64, roll = -6 })
        beat(0.15, function() convergeTo(originPos + Vector3.new(0, 9, 0) + lookH * 2, SILVER, 18) end)
        beat(0.45, function()
                if auraEmit then
                        auraEmit:Emit(40)
                end
        end)
        task.wait(0.75)
        if not introActive then return end

        -- the strike!
        setPose("SLASH", 60)
        snapPose()
        setTremble(0.3)
        enableTrail(true)
        local slashPos = originPos + Vector3.new(0, 16, 0) + lookH * 9
        slashArc(CFrame.lookAt(slashPos, slashPos + lookH), 1.6, WHITE)
        sfx("slash", 1, 0.9)
        sfx("lunge", 0.85, 0.8)
        flash(0.5, WHITE)
        addShake(0.022)
        bloomPulse(3.2, 0.9)
        camFOV(72, 0.12)

        buildCrack()
        beat(0.2, function() lightningStrike() end)
        beat(0.55, function() lightningStrike() end)
        beat(0.35, function() enableTrail(false) end)
        task.wait(0.15)
        if not introActive then return end
        camFOV(52, 1.2)
        beat(0.9, function()
                windDisc(originPos + Vector3.new(0, 2, 0), WHITE, 2.2)
                addShake(0.006)
        end)
        task.wait(math.max(0.05, d - (os.clock() - t0)))
end

--======================================================================--
--                      THE 8 CINEMATIC PHASES (5-8)
--======================================================================--

-- PHASE 5: the dragon EMERGES from the rift
local function phaseEmerge(d)
        local t0 = os.clock()
        local spawnCF = CFrame.lookAt(crackPos + Vector3.new(0, 30, 0), originPos + Vector3.new(0, 10, 0))
        buildDragon(spawnCF)
        if dragon == nil then
                return
        end
        setAtmo({ Haze = 0.9 }, 1.5)

        local hoverPos = originPos + lookH * 40 + Vector3.new(0, 20, 0)
        dragon.flapSpeed = 7
        dragon.flapAmp = 0.55
        tween(dragon.baseValue, twi(T(3.2), Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
                Value = CFrame.lookAt(hoverPos, originPos + Vector3.new(0, 6, 0)),
        })
        sfx("impact", 0.5, 0.6)
        lightningStrike()

        camTo(CFrame.lookAt(
                originPos + lookH * 26 + rightH * 24 + Vector3.new(0, 6, 0),
                originPos + lookH * 18 + Vector3.new(0, 14, 0)
        ), 1.2, { fov = 60 })
        task.wait(1.3)
        if not introActive then return end

        -- roar beat
        setJaw(1)
        if dragon.mouthEmit then
                dragon.mouthEmit:Emit(90)
        end
        if dragon.mouthLight then
                dragon.mouthLight.Brightness = 10
        end
        addShake(0.009)
        bloomPulse(2, 0.7)
        sfx("impact", 0.32, 0.9)
        beat(0.55, function() setJaw(0.15) end)
        task.wait(1.4)
        if not introActive then return end

        -- hero shot from behind the player
        camTo(CFrame.lookAt(
                originPos - lookH * 6.5 + rightH * 4 + Vector3.new(0, 2.2, 0),
                originPos + lookH * 30 + Vector3.new(0, 16, 0)
        ), 1.0, { fov = 56, roll = -3 })
        setPose("BATTLE", 9)
        task.wait(math.max(0.05, d - (os.clock() - t0)))
        dragon.flapAmp = 0.4
end

-- PHASE 6: THE BATTLE (fire volley / charge slash / swoop / counter)
local function phaseBattle(d)
        local t0 = os.clock()
        local hoverPos = originPos + lookH * 40 + Vector3.new(0, 20, 0)

        -- BEAT A: three fireballs, the player dodges each one
        camTo(CFrame.lookAt(originPos + rightH * 13 + Vector3.new(0, 4, 0), originPos + Vector3.new(0, 6, 0)), 0.6, { fov = 66 })
        setJaw(1)

        local function volley(i, side)
                local mouthPos = (dragon and dragon.root) and ((dragon.root.CFrame * CFrame.new(0, -1.5, -38)).Position) or originPos
                spawnFireball(mouthPos, originPos + Vector3.new(0, 2.5, 0), 2.2, 0.85)
                task.delay(0.28, function()
                        if not introActive then return end
                        local dodgePos = originPos + rightH * (11 * side) + Vector3.new(0, 2.5, 0) + lookH * (i * 1.2)
                        tween(hrp, twi(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                                CFrame = CFrame.new(dodgePos) * yawCF * CFrame.Angles(0, 0, math.rad(-12 * side)),
                        })
                        setPose("DODGE", 30)
                        sfx("swoosh", 1.2, 0.5)
                        beat(0.55, function()
                                tween(hrp, twi(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                        CFrame = CFrame.new(originPos + Vector3.new(0, 2.5, 0) + rightH * 2 * side) * yawCF,
                                })
                                setPose("BATTLE", 12)
                        end)
                end)
        end

        volley(1, 1)
        beat(1.15, function() volley(2, -1) end)
        beat(2.3, function() volley(3, 1) end)
        beat(3.1, function() setJaw(0.1) end)
        task.wait(3.4)
        if not introActive then return end

        -- BEAT B: the player charges forward and slashes the chest
        local underDragon = originPos + lookH * 34 + Vector3.new(0, 4, 0)
        tween(hrp, twi(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { CFrame = CFrame.new(underDragon) * yawCF })
        sfx("swoosh", 0.9, 0.6)
        enableTrail(true)
        beat(0.45, function()
                if not introActive or not dragon then return end
                tween(hrp, twi(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        CFrame = CFrame.new(underDragon + Vector3.new(0, 7, 0)) * yawCF,
                })
                setPose("SLASH", 40)
                snapPose()
                local hitPos = underDragon + Vector3.new(0, 15, 0) + lookH * 4
                slashArc(CFrame.lookAt(hitPos, hitPos + lookH), 1.2, SILVER)
                sfx("slash", 1.1, 0.8)
                addShake(0.008)
                bloomPulse(2.2, 0.6)
                explosionAt(CFrame.new(hitPos), 1.2, EMBER, WHITE)
                tween(dragon.baseValue, twi(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Value = CFrame.lookAt(hoverPos + Vector3.new(0, 5, 0) - lookH * 6, originPos + Vector3.new(0, 6, 0)),
                })
                beat(0.5, function()
                        if dragon then
                                tween(dragon.baseValue, twi(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                                        Value = CFrame.lookAt(hoverPos, originPos + Vector3.new(0, 6, 0)),
                                })
                        end
                end)
        end)
        beat(1.1, function() enableTrail(false) end)
        camTo(CFrame.lookAt(
                underDragon - lookH * 9 + rightH * 5 + Vector3.new(0, 5, 0),
                underDragon + Vector3.new(0, 14, 0) + lookH * 6
        ), 0.5)
        task.wait(1.8)
        if not introActive then return end

        -- BEAT C: the dragon swoops past, the wing blast knocks the player back
        local sidePos = originPos + rightH * 26 + Vector3.new(0, 14, 0) - lookH * 6
        if dragon then
                dragon.flapSpeed = 9
                tween(dragon.baseValue, twi(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                        Value = CFrame.lookAt(sidePos, originPos + Vector3.new(0, 3, 0)),
                })
        end
        beat(0.75, function()
                if not introActive or not dragon then return end
                tween(dragon.baseValue, twi(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Value = CFrame.lookAt(originPos - lookH * 14 + Vector3.new(0, 4, 0) - rightH * 8, originPos + Vector3.new(0, 3, 0)),
                })
                sfx("swoosh", 0.55, 0.85)
                addShake(0.011)
                beat(0.3, function()
                        if not introActive then return end
                        local kb = originPos - lookH * 9 + rightH * 3 + Vector3.new(0, 2.5, 0)
                        tween(hrp, twi(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                                CFrame = CFrame.new(kb) * yawCF * CFrame.Angles(0, 0, math.rad(18)),
                        })
                        explosionAt(CFrame.new(originPos + Vector3.new(0, 4, 0)), 1.4, SILVER, WHITE)
                        setPose("DODGE", 30)
                end)
                beat(0.95, function()
                        if dragon then
                                tween(dragon.baseValue, twi(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                                        Value = CFrame.lookAt(hoverPos, originPos + Vector3.new(0, 6, 0)),
                                })
                        end
                end)
        end)
        camSet(CFrame.lookAt(originPos + lookH * 14 + Vector3.new(0, 1.2, 0), originPos + Vector3.new(0, 8, 0)))
        camFOV(66, 0.3)
        task.wait(2.0)
        if not introActive then return end

        -- BEAT D: huge charged fireball -> the player COUNTER-SLASHES it
        tween(hrp, twi(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame = CFrame.new(originPos + Vector3.new(0, 2.5, 0)) * yawCF,
        })
        setPose("WINDUP", 12)
        setTremble(1.2)
        camTo(CFrame.lookAt(
                originPos - lookH * 9 + rightH * 2 + Vector3.new(0, 3, 0),
                originPos + lookH * 20 + Vector3.new(0, 18, 0)
        ), 0.7, { fov = 52 })
        setSwordGlow(3.5, 0.8)

        local bigFB = nil
        if dragon and dragon.root then
                setJaw(1)
                local mouthPos = (dragon.root.CFrame * CFrame.new(0, -1.5, -40)).Position
                bigFB = part({
                        Shape = Enum.PartType.Ball,
                        Material = Enum.Material.Neon,
                        Color = EMBER2,
                        Size = Vector3.new(1.5, 1.5, 1.5),
                        CFrame = CFrame.new(mouthPos),
                        Anchored = true,
                        CastShadow = false,
                })
                if bigFB then
                        emitter(bigFB, {
                                Texture = FIRE_TEX,
                                Rate = 70,
                                Enabled = true,
                                Speed = NumberRange.new(4, 9),
                                Lifetime = NumberRange.new(0.3, 0.6),
                                Size = NumberSequence.new({
                                        NumberSequenceKeypoint.new(0, 3),
                                        NumberSequenceKeypoint.new(1, 0),
                                }),
                                LightEmission = 1,
                                Color = emberSeq(),
                                SpreadAngle = Vector2.new(180, 180),
                        })
                        local bl = pointLight(bigFB, EMBER, 4, 40)
                        tween(bigFB, twi(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(9, 9, 9) })
                        if bl then
                                tween(bl, twi(1.1), { Brightness = 12, Range = 60 })
                        end
                        convergeTo(mouthPos, EMBER, 14)
                end
        end
        sfx("ping", 0.6, 0.5)
        task.wait(1.35)
        if not introActive then return end

        if bigFB then
                tween(bigFB, twi(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        Position = originPos + Vector3.new(0, 4, 0) + lookH * 2,
                })
        end
        task.delay(0.42, function()
                if not introActive then return end
                setPose("SLASH", 50)
                snapPose()
                setTremble(0.3)
                setSwordGlow(1.8, 0.5)
                enableTrail(true)
                local cp = originPos + Vector3.new(0, 6, 0) + lookH * 7
                slashArc(CFrame.lookAt(cp, cp + lookH), 2.0, WHITE)
                sfx("lunge", 1.05, 0.9)
                flash(0.4, WHITE)
                addShake(0.014)
                bloomPulse(3, 0.8)
                explosionAt(CFrame.new(cp + lookH * 4), 2.4, EMBER, WHITE)
                windDisc(originPos + Vector3.new(0, 4, 0), WHITE, 2.6)
                if bigFB and bigFB.Parent then
                        bigFB:Destroy()
                end
        end)
        beat(1.3, function() enableTrail(false) end)
        task.wait(math.max(0.05, d - (os.clock() - t0)))
        setJaw(0.2)
end

-- PHASE 7: VICTORY - freeze frame, the dragon shatters
local function phaseVictory(d)
        local t0 = os.clock()
        setPose("VICTORY", 14)
        setTremble(0.8)
        if auraEmit then
                auraEmit.Rate = 40
        end
        setSwordGlow(4, 0.6)
        convergeTo(originPos + Vector3.new(0, 8, 0), WHITE, 22)
        camTo(CFrame.lookAt(
                originPos + lookH * 8 - rightH * 6 + Vector3.new(0, 2.5, 0),
                originPos + Vector3.new(0, 7, 0)
        ), 1.0, { style = Enum.EasingStyle.Sine, dir = Enum.EasingDirection.InOut, fov = 48 })
        sfx("ping", 0.8, 0.5)
        task.wait(1.0)
        if not introActive then return end

        -- FINAL DASH + X-SLASH
        local strikePos = originPos + lookH * 36 + Vector3.new(0, 16, 0)
        tween(hrp, twi(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                CFrame = CFrame.new(strikePos) * yawCF * CFrame.Angles(0, 0, math.rad(-14)),
        })
        sfx("swoosh", 1.15, 0.7)
        enableTrail(true)
        beat(0.5, function()
                if not introActive then return end
                setPose("SLASH", 60)
                snapPose()
                setTremble(0.3)
                local hp = strikePos + lookH * 4
                slashArc(CFrame.lookAt(hp, hp + lookH) * CFrame.Angles(0, 0, math.rad(20)), 2.2, WHITE)
                slashArc(CFrame.lookAt(hp, hp + lookH) * CFrame.Angles(0, 0, math.rad(-20)), 2.2, SILVER)
                sfx("slash", 0.95, 1)
                sfx("lunge", 0.8, 0.9)
                flash(0.5, WHITE)
                addShake(0.024)
                bloomPulse(3.4, 1)
                camFOV(72, 0.12)
                beat(0.12, function() camFOV(50, 1.0) end)
        end)
        beat(0.9, function() enableTrail(false) end)
        task.wait(1.05)
        if not introActive then return end

        -- FREEZE FRAME: time stops, the dragon turns white-hot
        setBlur(14, 0.3)
        setTremble(0)
        if dragon then
                dragon.frozen = true
                for _, p in ipairs(dragon.molten) do
                        tween(p, twi(0.5), { Color = WHITE })
                end
                for _, e in ipairs(dragon.eyeParts) do
                        tween(e, twi(0.5), { Color = WHITE })
                end
        end
        task.wait(0.85)
        if not introActive then return end

        -- SHATTER!
        setBlur(0, 0.6)
        shatterDragon()
        flash(0.7, WHITE)
        addShake(0.026)
        bloomPulse(3.6, 1.2)
        sfx("impact", 0.42, 1)
        sfx("ping", 1.6, 0.6)
        beat(0.2, function() windDisc(originPos + Vector3.new(0, 14, 0), WHITE, 4) end)
        beat(0.45, function() windDisc(originPos + Vector3.new(0, 14, 0), SILVER, 6) end)

        -- land back in a heroic stance
        beat(0.5, function()
                if not introActive then return end
                tween(hrp, twi(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        CFrame = CFrame.new(originPos + Vector3.new(0, 2.5, 0)) * yawCF,
                })
                setPose("HEROLAND", 8)
                if auraEmit then
                        auraEmit.Rate = 12
                end
                setSwordGlow(1.6, 1)
        end)
        camTo(CFrame.lookAt(
                originPos + lookH * 13 + rightH * 8 + Vector3.new(0, 3, 0),
                originPos + Vector3.new(0, 6, 0)
        ), 1.6, { style = Enum.EasingStyle.Sine, dir = Enum.EasingDirection.InOut, roll = 0 })
        task.wait(math.max(0.05, d - (os.clock() - t0)))
end

-- PHASE 8: ASCENSION - up through the clouds, into SPACE
local function phaseAscend(d)
        local t0 = os.clock()
        spaceEndPos = originPos + Vector3.new(0, 430, 0)

        -- gather crouch
        tween(hrp, twi(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame = CFrame.new(originPos - Vector3.new(0, 0.8, 0)) * yawCF,
        })
        setPose("HEROLAND", 10)
        camTo(CFrame.lookAt(originPos + lookH * 9 + rightH * 5 + Vector3.new(0, 2, 0), originPos + Vector3.new(0, 4, 0)), 0.5)
        if auraEmit then
                auraEmit:Emit(60)
        end
        task.wait(0.55)
        if not introActive then return end

        -- LAUNCH
        setPose("ASCEND", 20)
        if trailEmit then
                trailEmit.Enabled = true
        end
        sfx("swoosh", 0.8, 0.8)
        addShake(0.008)
        tween(hrp, twi(T(2.9), Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                CFrame = CFrame.new(spaceEndPos) * yawCF * CFrame.Angles(0, 0, math.rad(5)),
        })
        ascendCam = true
        camFOV(68, 1.2)

        -- speed rings along the path
        for i = 1, 7 do
                local h = i * 48
                beat(0.2 + i * 0.28, function()
                        if not introActive then return end
                        local ring = part({
                                Shape = Enum.PartType.Cylinder,
                                Material = Enum.Material.Neon,
                                Color = ICE,
                                Transparency = 0.5,
                                Size = Vector3.new(0.4, 26, 26),
                                CFrame = CFrame.new(originPos.X, originPos.Y + h, originPos.Z) * CFrame.Angles(0, 0, math.rad(90)),
                                Anchored = true,
                                CastShadow = false,
                        })
                        if ring then
                                tween(ring, twi(0.6), { Transparency = 1 })
                                Debris:AddItem(ring, 0.8)
                        end
                end)
        end

        -- the world turns to space
        beat(0.8, function()
                if not introActive then return end
                tween(Lighting, twi(T(2.4)), {
                        ClockTime = 0,
                        Brightness = 0.4,
                        Ambient = Color3.fromRGB(9, 11, 18),
                        OutdoorAmbient = Color3.fromRGB(12, 14, 24),
                        ExposureCompensation = -0.1,
                })
                setAtmo({ Density = 0.28, Haze = 1.4, Color = Color3.fromRGB(14, 16, 26) }, T(2.4))
                setGrade({ Saturation = -0.18, Contrast = 0.16, TintColor = Color3.fromRGB(196, 210, 255) }, T(2.4))
        end)
        beat(1.9, function()
                if cloudEmit then
                        cloudEmit.Enabled = true
                end
        end)
        beat(2.3, function()
                if not introActive then return end
                if cloudEmit then
                        cloudEmit.Enabled = false
                end
                flash(0.4, WHITE)
                if hrp and hrp.Parent then
                        windDisc(hrp.Position - Vector3.new(0, 6, 0), WHITE, 3)
                end
                addShake(0.004)
        end)
        beat(3.0, function()
                if not introActive then return end
                if trailEmit then
                        trailEmit.Enabled = false
                end
                ascendCam = false
                spaceMode = true
                setPose("SOAR", 8)
                camFOV(54, 2.0)
                setAtmo({ Density = 0.1, Haze = 0.4 }, 2.0)
                local dir = (lookH + rightH * 2.2 + Vector3.new(0, 0.35, 0)).Unit
                camTo(CFrame.lookAt(spaceEndPos - dir * 13 + Vector3.new(0, 1, 0), spaceEndPos + dir * 80), 2.4, {
                        style = Enum.EasingStyle.Sine, dir = Enum.EasingDirection.InOut, roll = 3,
                })
        end)
        beat(4.2, function()
                showTitle()
                sfx("ping", 1.1, 0.5)
                bloomPulse(2, 1.4)
        end)
        beat(6.1, function()
                fade(0, 0.9)
        end)
        task.wait(math.max(0.05, d - (os.clock() - t0)))
end

--======================================================================--
--                    SAVE / RESTORE / CLEANUP / START
--======================================================================--

local UserInputService = game:GetService("UserInputService")

local function saveState()
        saved.camType = camera.CameraType
        saved.camCF = camera.CFrame
        saved.fov = camera.FieldOfView
        saved.li = {
                Brightness = Lighting.Brightness,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart,
                FogColor = Lighting.FogColor,
                GlobalShadows = Lighting.GlobalShadows,
                ExposureCompensation = Lighting.ExposureCompensation,
                EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
                EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        }
        saved.charCF = nil

        -- remember existing post-processing effects and disable them
        for _, inst in ipairs(Lighting:GetChildren()) do
                if inst:IsA("PostEffect") or inst:IsA("Atmosphere") or inst:IsA("Sky") then
                        if inst:IsA("Atmosphere") then
                                atmosphere = inst
                                saved.atmo = {
                                        Density = inst.Density, Offset = inst.Offset,
                                        Color = inst.Color, Decay = inst.Decay,
                                        Glare = inst.Glare, Haze = inst.Haze, Brightness = inst.Brightness,
                                }
                        elseif inst:IsA("Sky") then
                                saved.sky = inst
                                saved.skyParent = inst.Parent
                                inst.Parent = nil
                        else
                                table.insert(savedFX, { inst = inst, was = inst.Enabled })
                                inst.Enabled = false
                        end
                end
        end
        -- hide terrain clouds so the night/space sky stays clean
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        local clouds = terrain and terrain:FindFirstChildOfClass("Clouds")
        if clouds then
                saved.clouds = clouds
                saved.cloudsWas = clouds.Enabled
                clouds.Enabled = false
        end

        if atmosphere == nil then
                atmosphere = Instance.new("Atmosphere")
                atmosphere.Density = 0.35
                atmosphere.Offset = 0.4
                atmosphere.Glare = 0.2
                atmosphere.Parent = Lighting
                createdAtmo = true
        end

        -- intro color grade
        introCC = Instance.new("ColorCorrectionEffect")
        introCC.Name = "LEGENDS_V2_CC"
        introCC.Contrast = 0.08
        introCC.Saturation = -0.05
        introCC.TintColor = Color3.fromRGB(238, 242, 252)
        introCC.Parent = Lighting

        introBloom = Instance.new("BloomEffect")
        introBloom.Name = "LEGENDS_V2_Bloom"
        introBloom.Intensity = 0.55
        introBloom.Size = 34
        introBloom.Threshold = 1.1
        introBloom.Parent = Lighting

        introBlur = Instance.new("BlurEffect")
        introBlur.Name = "LEGENDS_V2_Blur"
        introBlur.Size = 0
        introBlur.Parent = Lighting
end

local function setupCharacter()
        char = player.Character or player.CharacterAdded:Wait()
        hrp = char:WaitForChild("HumanoidRootPart", 10)
        humanoid = char:WaitForChild("Humanoid", 10)
        if hrp == nil or humanoid == nil then
                return false
        end
        animator = humanoid:FindFirstChildOfClass("Animator")
        isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

        if isR15 then
                handPart = char:WaitForChild("RightHand", 5)
        else
                handPart = char:WaitForChild("Right Arm", 5)
        end
        if handPart == nil then
                return false
        end

        animateScript = char:FindFirstChild("Animate")
        if animateScript then
                animateScript.Disabled = true
        end
        if animator then
                for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
                        tr:Stop(0.1)
                end
        end

        originPos = hrp.Position
        local lv = hrp.CFrame.LookVector
        if lv.Magnitude < 0.05 then
                lv = Vector3.new(0, 0, -1)
        end
        lookH = Vector3.new(lv.X, 0, lv.Z)
        if lookH.Magnitude < 0.05 then
                lookH = Vector3.new(0, 0, -1)
        end
        lookH = lookH.Unit
        rightH = Vector3.new(-lookH.Z, 0, lookH.X)
        local yaw = math.atan2(-lookH.X, -lookH.Z)
        yawCF = CFrame.Angles(0, yaw, 0)

        saved.charCF = hrp.CFrame

        hrp.Anchored = true
        humanoid.AutoRotate = false

        -- SKY STAGE: lift the whole cinematic above the map so it plays
        -- against a clean 360-degree sky on ANY game
        originPos = originPos + Vector3.new(0, 260, 0)
        hrp.CFrame = CFrame.new(originPos) * yawCF

        crackPos = originPos + Vector3.new(0, 210, 0) + lookH * 60
        spaceEndPos = originPos + Vector3.new(0, 430, 0)

        if not setupJoints() then
                return false
        end

        -- safety: if the player dies / respawns during the intro, restore all
        table.insert(conns, humanoid.Died:Connect(function()
                task.delay(0.2, function() cleanup() end)
        end))
        table.insert(conns, player.CharacterAdded:Connect(function()
                task.delay(0.2, function() cleanup() end)
        end))
        return true
end

function cleanup()
        if not introActive then
                return
        end
        introActive = false

        if runConn then
                runConn:Disconnect()
                runConn = nil
        end
        for _, c in ipairs(conns) do
                pcall(function() c:Disconnect() end)
        end
        conns = {}
        pcall(function()
                if blackFrame then
                        blackFrame.BackgroundTransparency = 0
                end
        end)
        task.wait(0.35)

        -- camera
        pcall(function()
                camera.CameraType = saved.camType or Enum.CameraType.Custom
                camera.FieldOfView = saved.fov or 70
                camera.CFrame = saved.camCF or CFrame.new()
        end)
        rollVal.Value = 0
        fovVal.Value = saved.fov or 70

        -- lighting
        pcall(function()
                if saved.li then
                        Lighting.Brightness = saved.li.Brightness
                        Lighting.Ambient = saved.li.Ambient
                        Lighting.OutdoorAmbient = saved.li.OutdoorAmbient
                        Lighting.ClockTime = saved.li.ClockTime
                        Lighting.FogEnd = saved.li.FogEnd
                        Lighting.FogStart = saved.li.FogStart
                        Lighting.FogColor = saved.li.FogColor
                        Lighting.GlobalShadows = saved.li.GlobalShadows
                        Lighting.ExposureCompensation = saved.li.ExposureCompensation
                        Lighting.EnvironmentDiffuseScale = saved.li.EnvironmentDiffuseScale
                        Lighting.EnvironmentSpecularScale = saved.li.EnvironmentSpecularScale
                end
                if atmosphere then
                        if createdAtmo then
                                atmosphere:Destroy()
                                createdAtmo = false
                        elseif saved.atmo then
                                atmosphere.Density = saved.atmo.Density
                                atmosphere.Offset = saved.atmo.Offset
                                atmosphere.Color = saved.atmo.Color
                                atmosphere.Decay = saved.atmo.Decay
                                atmosphere.Glare = saved.atmo.Glare
                                atmosphere.Haze = saved.atmo.Haze
                                atmosphere.Brightness = saved.atmo.Brightness
                        end
                end
                for _, e in ipairs(savedFX) do
                        if e.inst and e.inst.Parent then
                                e.inst.Enabled = e.was
                        end
                end
                if saved.sky and saved.skyParent then
                        saved.sky.Parent = saved.skyParent
                end
                if saved.clouds then
                        saved.clouds.Enabled = saved.cloudsWas
                end
                if introCC then introCC:Destroy() introCC = nil end
                if introBloom then introBloom:Destroy() introBloom = nil end
                if introBlur then introBlur:Destroy() introBlur = nil end
        end)

        -- audio
        pcall(function()
                if music then
                        music:Destroy()
                        music = nil
                end
                for _, s in ipairs(soundsAll) do
                        if s and s.Parent then
                                s:Destroy()
                        end
                end
                soundsAll = {}
        end)

        -- controls
        pcall(function()
                if controls then
                        controls:Enable()
                end
        end)

        -- character
        pcall(function()
                if auraEmit then auraEmit:Destroy() auraEmit = nil end
                if trailEmit then trailEmit:Destroy() trailEmit = nil end
                for _, j in pairs(joints) do
                        if j and j.Parent then
                                j.Transform = CFrame.new()
                        end
                end
                joints = {}
                setCharLTM(0)
                if hrp and hrp.Parent then
                        hrp.Anchored = false
                        if saved.charCF then
                                hrp.CFrame = saved.charCF
                        end
                end
                if humanoid and humanoid.Parent then
                        humanoid.AutoRotate = true
                end
                if animateScript and animateScript.Parent then
                        animateScript.Disabled = false
                end
        end)

        -- scene
        pcall(function()
                if swordModel then
                        swordModel:Destroy()
                        swordModel = nil
                end
                if sceneFolder then
                        sceneFolder:Destroy()
                end
        end)
        dragon = nil
        crackLight = nil
        lightningArcs = {}
        starDome = nil
        runeRing = nil
        swordTrail = nil

        -- reveal the game again
        pcall(function()
                if blackFrame then
                        tween(blackFrame, twi(0.5), { BackgroundTransparency = 1 })
                end
        end)
        task.delay(0.7, function()
                pcall(function()
                        if uiGui then
                                uiGui:Destroy()
                                uiGui = nil
                        end
                end)
        end)
end

--============================================================--
--  MASTER RENDER LOOP
--============================================================--

local function connectRenderLoop()
        runConn = RunService.RenderStepped:Connect(function(dt)
                if not introActive then
                        return
                end
                local t = os.clock()

                cameraStep(dt, t)
                animationStep(dt, t)
                dragonUpdate(dt, t)

                -- rune ring spins around the blade
                if runeRing and runeRing.Parent and swordModel and swordModel.PrimaryPart then
                        runeSpin = runeSpin + dt * 2.4
                        runeRing.CFrame = swordModel.PrimaryPart.CFrame
                                * CFrame.new(0, 2.3, 0)
                                * CFrame.Angles(0, 0, math.rad(90))
                                * CFrame.Angles(runeSpin, 0, 0)
                end

                -- rift light breathes
                if crackLight and crackLight.Parent then
                        crackLight.Brightness = 6 + math.sin(t * 2.1) * 1.5
                end

                -- star dome follows the camera
                if starDome and starDome.Parent then
                        starDome:PivotTo(camera.CFrame)
                end

                -- slow float spin in space
                if spaceMode and hrp and hrp.Parent then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, dt * 0.1, 0)
                end

                -- cloud puffs follow the rising player
                if cloudPart and cloudPart.Parent and cloudEmit and cloudEmit.Enabled and hrp and hrp.Parent then
                        cloudPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 20, 0))
                end
        end)
end

--============================================================--
--                              START
--============================================================--

local function startIntro()
        introActive = true

        -- lock the controls (in the background, never blocks the intro)
        task.spawn(function()
                pcall(function()
                        local pm = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
                        controls = pm:GetControls()
                        if controls then
                                controls:Disable()
                        end
                end)
        end)

        saveState()
        buildUI()
        sceneFolder.Parent = workspace

        local okChar = setupCharacter()
        if not okChar then
                introActive = false
                if uiGui then uiGui:Destroy() uiGui = nil end
                camera.CameraType = saved.camType or Enum.CameraType.Custom
                showFatal("مش لاقي الشخصية أو الأيد (RightHand / Right Arm) جوا اللعبة دي.\n"
                        .. "جرب لعبة عادية (Baseplate) واضغط Play، أو افتح F9 وبعتلي الغلطة.")
                return
        end

        buildArena()
        buildSpace()

        camera.CameraType = Enum.CameraType.Scriptable
        camValue.Value = saved.camCF or CFrame.new()
        fovVal.Value = saved.fov or 70
        rollVal.Value = 0

        -- kill map fog so the sky stage stays clean
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0

        -- aura / trail / cloud emitters on the player
        auraEmit = emitter(hrp, {
                Rate = 12,
                Enabled = false,
                Speed = NumberRange.new(2, 5),
                Lifetime = NumberRange.new(0.6, 1.1),
                Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.5),
                        NumberSequenceKeypoint.new(1, 0),
                }),
                LightEmission = 1,
                Color = silverSeq(),
                SpreadAngle = Vector2.new(60, 60),
        })
        trailEmit = emitter(hrp, {
                Rate = 130,
                Enabled = false,
                Speed = NumberRange.new(20, 30),
                Lifetime = NumberRange.new(0.35, 0.6),
                Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1.6),
                        NumberSequenceKeypoint.new(1, 0),
                }),
                LightEmission = 1,
                Color = silverSeq(),
                SpreadAngle = Vector2.new(12, 12),
                EmissionDirection = Enum.NormalId.Bottom,
        })
        cloudPart = part({ Transparency = 1, Size = Vector3.new(1, 1, 1), Anchored = true, CastShadow = false })
        cloudEmit = emitter(cloudPart, {
                Texture = SMOKE_TEX,
                Rate = 55,
                Enabled = false,
                Speed = NumberRange.new(14, 22),
                Lifetime = NumberRange.new(0.5, 0.9),
                Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 8),
                        NumberSequenceKeypoint.new(1, 18),
                }),
                Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.7),
                        NumberSequenceKeypoint.new(1, 1),
                }),
                Color = ColorSequence.new(Color3.fromRGB(228, 232, 240)),
                LightEmission = 0.2,
                EmissionDirection = Enum.NormalId.Bottom,
        })

        -- skip: button + X key
        if skipButton then
                skipButton.MouseButton1Click:Connect(function()
                        cleanup()
                end)
                task.delay(1.5, function()
                        if skipButton and skipButton.Parent then
                                skipButton.Visible = true
                        end
                end)
        end
        table.insert(conns, UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode == Enum.KeyCode.X then
                        cleanup()
                end
        end))

        startMusic()
        connectRenderLoop()

        -- run all phases in order (each one error-guarded)
        local PHASES = {
                { 9.0,  phaseGround },
                { 6.0,  phaseSword },
                { 4.5,  phaseGaze },
                { 5.0,  phaseSlash },
                { 6.5,  phaseEmerge },
                { 11.5, phaseBattle },
                { 6.5,  phaseVictory },
                { 8.0,  phaseAscend },
        }
        task.spawn(function()
                for idx, ph in ipairs(PHASES) do
                        if not introActive then
                                break
                        end
                        setPhaseLabel(idx)
                        updateDebug(idx)
                        local ok, err = pcall(ph[2], ph[1] * S)
                        if not ok then
                                errCount = errCount + 1
                                errText = "| last: " .. tostring(err):sub(1, 60)
                                warn("[LEGENDS v2] phase error: " .. tostring(err))
                                updateDebug(idx)
                        end
                end
                if introActive then
                        cleanup()
                end
        end)
end

-- boot with a full safety net: any error now shows ON SCREEN (in red)
-- instead of dying silently in the Output console (F9).
local okBoot, bootErr = xpcall(startIntro, function(e)
        return tostring(e) .. "  @  " .. debug.traceback("", 2)
end)
if not okBoot then
        showFatal(bootErr)
end
