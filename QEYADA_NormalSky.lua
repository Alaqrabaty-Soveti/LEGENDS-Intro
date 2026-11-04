--=====================================================================
--  EL QEYADA  |  NORMAL SKY ENVIRONMENT  --  v1.1
--  بيئة سماء عادية تغطي السماء الرمادية -- مش فضاء: سماء روبلوكس
--  الافتراضية الزرقاء + سحاب Clouds حقيقي مدمج + إضاءة نهار نظيفة
--  * 4 أزرار: نهار / غروب / ليل / استرجاع السماء الأصلية
--  * كل حاجة كلينت سايد (Executor LocalScript) -- صفر تعديل سيرفر
--  * انتقالات ناعمة TweenService بين الأوقات (مش قطع حاد)
--  * استرجاع كامل لكل حاجة: getgenv().QEYADA_SKY_STOP()
--  Loader:
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/QEYADA_NormalSky.lua"))()
--=====================================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local CoreGui          = game:GetService("CoreGui")

local PREFIX = "QEYADA_SKY_"

--[[ ----------------------------------------------------------------
     presets: each one is a full time-of-day look. Tweens make the
     transitions smooth instead of a hard snap (VFX rule: timing).
------------------------------------------------------------------ ]]
local PRESETS = {
    day = {
        clock = 14.2, brightness = 2.8, exposure = 0.05, shadows = true,
        ambient = Color3.fromRGB(95, 100, 110),
        outdoor = Color3.fromRGB(140, 145, 152),
        fogColor = Color3.fromRGB(198, 214, 235),
        ccTint = Color3.fromRGB(255, 252, 246), ccSat = 0.04, ccCon = 0.04,
        sunRays = 0.12,
        atmoDensity = 0.30, atmoHaze = 1.6, atmoGlare = 0.10,
        atmoColor = Color3.fromRGB(199, 215, 235),
        atmoDecay = Color3.fromRGB(110, 125, 150),
        clouds = { cover = 0.55, density = 0.60, color = Color3.fromRGB(255, 255, 255) },
        night = false,
    },
    sunset = {
        clock = 17.9, brightness = 2.2, exposure = 0.10, shadows = true,
        ambient = Color3.fromRGB(122, 96, 88),
        outdoor = Color3.fromRGB(170, 122, 96),
        fogColor = Color3.fromRGB(255, 183, 128),
        ccTint = Color3.fromRGB(255, 228, 205), ccSat = 0.08, ccCon = 0.06,
        sunRays = 0.32,
        atmoDensity = 0.36, atmoHaze = 2.6, atmoGlare = 0.25,
        atmoColor = Color3.fromRGB(225, 170, 130),
        atmoDecay = Color3.fromRGB(150, 100, 80),
        clouds = { cover = 0.45, density = 0.50, color = Color3.fromRGB(255, 235, 215) },
        night = false,
    },
    night = {
        clock = 0.4, brightness = 1.4, exposure = 0.35, shadows = true,
        ambient = Color3.fromRGB(38, 45, 62),
        outdoor = Color3.fromRGB(55, 65, 88),
        fogColor = Color3.fromRGB(15, 20, 35),
        ccTint = Color3.fromRGB(210, 220, 255), ccSat = -0.05, ccCon = 0.10,
        sunRays = 0.0,
        atmoDensity = 0.32, atmoHaze = 1.2, atmoGlare = 0.0,
        atmoColor = Color3.fromRGB(60, 75, 110),
        atmoDecay = Color3.fromRGB(30, 40, 65),
        clouds = { cover = 0.35, density = 0.45, color = Color3.fromRGB(140, 150, 180) },
        night = true,
    },
}

--[[ stop any previous run + undo its changes before saving fresh ]]--
pcall(function()
    local genv = (typeof(getgenv) == "function" and getgenv()) or _G
    if type(genv.QEYADA_SKY_STOP) == "function" then
        genv.QEYADA_SKY_STOP()
    end
end)

local function destroyLeftovers()
    local roots = { Lighting }
    pcall(function()
        if workspace.Terrain then
            table.insert(roots, workspace.Terrain)
        end
    end)
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
                if obj.Name:sub(1, #PREFIX) == PREFIX then
                    obj:Destroy()
                end
            end
        end)
    end
end

destroyLeftovers()

--[[ generation token: a newer execution invalidates this one ]]--
local genv = (typeof(getgenv) == "function" and getgenv()) or _G
local myToken = {}
genv.QEYADA_SKY_TOKEN = myToken

local dead = false
local saved = nil
local nightSky = nil
local ourAtmo = nil
local ourClouds = nil
local ourCC, ourBloom, ourRays = nil, nil, nil
local disabledFX = {}
local activeTweens = {}
local gui = nil

local function alive()
    return (not dead) and genv.QEYADA_SKY_TOKEN == myToken
end

--[[ smooth tween helper: cancels the previous tween on the same object ]]--
local function twTo(obj, props, dur)
    if not obj then
        return nil
    end
    local old = activeTweens[obj]
    if old then
        pcall(function() old:Cancel() end)
    end
    local t = TweenService:Create(obj,
        TweenInfo.new(dur or 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), props)
    activeTweens[obj] = t
    t:Play()
    return t
end

local function cancelTweens()
    for obj, t in pairs(activeTweens) do
        pcall(function() t:Cancel() end)
        activeTweens[obj] = nil
    end
end

--[[ park the game's own post-effects that gray-wash the sky.
      dedup: each object is saved only once across the whole session. ]]--
local function parkGameFX()
    pcall(function()
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") and fx.Name:sub(1, #PREFIX) ~= PREFIX and fx.Enabled then
                local known = false
                for _, f in ipairs(disabledFX) do
                    if f.obj == fx then
                        known = true
                        break
                    end
                end
                if not known then
                    disabledFX[#disabledFX + 1] = { obj = fx, enabled = true }
                end
                fx.Enabled = false
            end
        end
    end)
end

--[[ ---------------- SAVE ORIGINALS (reversible rule #25) --------------- ]]--
local function saveOriginals()
    saved = {
        lighting = {
            Ambient              = Lighting.Ambient,
            OutdoorAmbient       = Lighting.OutdoorAmbient,
            Brightness           = Lighting.Brightness,
            ClockTime            = Lighting.ClockTime,
            FogColor             = Lighting.FogColor,
            FogStart             = Lighting.FogStart,
            FogEnd               = Lighting.FogEnd,
            GlobalShadows        = Lighting.GlobalShadows,
            ExposureCompensation = Lighting.ExposureCompensation,
        },
        skies = {},
        atmo = nil,
        clouds = nil,
    }
    pcall(function()
        saved.envDiffuse = Lighting.EnvironmentDiffuseScale
        saved.envSpecular = Lighting.EnvironmentSpecularScale
    end)

    -- detach the game's gray sky (do NOT destroy: restore = re-parent)
    pcall(function()
        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then
                sky.Parent = nil
                table.insert(saved.skies, sky)
            end
        end
    end)

    -- atmosphere: remember values, we tune them live
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        saved.atmo = {
            obj = atmo,
            Density = atmo.Density, Haze = atmo.Haze, Glare = atmo.Glare,
            Color = atmo.Color, Decay = atmo.Decay, Offset = atmo.Offset,
        }
    end

    -- terrain clouds: remember values if the game already has some
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            local cl = terrain:FindFirstChildOfClass("Clouds")
            if cl then
                saved.clouds = {
                    obj = cl,
                    Cover = cl.Cover, Density = cl.Density,
                    Color = cl.Color, Enabled = cl.Enabled,
                }
            end
        end
    end)

    parkGameFX()
end

--[[ ------------------- FULL VISUAL RESTORE ----------------------------- ]]--
-- puts EVERYTHING back the way the game had it, destroys our instances.
-- does NOT kill the panel (the buttons can rebuild and re-apply later).
local function restoreVisuals()
    cancelTweens()
    if saved then
        pcall(function()
            for k, v in pairs(saved.lighting) do
                Lighting[k] = v
            end
        end)
        pcall(function()
            Lighting.EnvironmentDiffuseScale = saved.envDiffuse or 1
            Lighting.EnvironmentSpecularScale = saved.envSpecular or 1
        end)
        pcall(function()
            for _, sky in ipairs(saved.skies) do
                if sky and sky.Parent == nil then
                    sky.Parent = Lighting -- untouched game sky goes back
                end
            end
        end)
        pcall(function()
            if saved.atmo and saved.atmo.obj then
                local a = saved.atmo.obj
                a.Density, a.Haze, a.Glare = saved.atmo.Density, saved.atmo.Haze, saved.atmo.Glare
                a.Color, a.Decay, a.Offset = saved.atmo.Color, saved.atmo.Decay, saved.atmo.Offset
            end
        end)
        pcall(function()
            if saved.clouds and saved.clouds.obj then
                local cl = saved.clouds.obj
                cl.Cover, cl.Density, cl.Color, cl.Enabled =
                    saved.clouds.Cover, saved.clouds.Density, saved.clouds.Color, saved.clouds.Enabled
            end
        end)
        pcall(function()
            for _, f in ipairs(disabledFX) do
                if f.obj then
                    f.obj.Enabled = f.enabled
                end
            end
        end)
    end
    pcall(function() if nightSky then nightSky:Destroy() nightSky = nil end end)
    pcall(function() if ourAtmo then ourAtmo:Destroy() ourAtmo = nil end end)
    pcall(function() if ourClouds then ourClouds:Destroy() ourClouds = nil end end)
    pcall(function() if ourCC then ourCC:Destroy() ourCC = nil end end)
    pcall(function() if ourBloom then ourBloom:Destroy() ourBloom = nil end end)
    pcall(function() if ourRays then ourRays:Destroy() ourRays = nil end end)
end

--[[ emergency full stop: visual restore + kill the GUI ]]--
genv.QEYADA_SKY_STOP = function()
    dead = true
    restoreVisuals()
    pcall(function() if gui then gui:Destroy() gui = nil end end)
end

--[[ ------------------- INSTANCE MANAGEMENT ----------------------------- ]]--
saveOriginals()

-- (re)create our own named effects; safe to call after a visual restore
local function ensureInstances()
    if not ourCC or not ourCC.Parent then
        ourCC = Instance.new("ColorCorrectionEffect")
        ourCC.Name = PREFIX .. "CC"
        ourCC.Parent = Lighting
    end
    if not ourBloom or not ourBloom.Parent then
        ourBloom = Instance.new("BloomEffect")
        ourBloom.Name = PREFIX .. "Bloom"
        ourBloom.Intensity = 0.35
        ourBloom.Size = 32
        ourBloom.Threshold = 1.1
        ourBloom.Parent = Lighting
    end
    if not ourRays or not ourRays.Parent then
        ourRays = Instance.new("SunRaysEffect")
        ourRays.Name = PREFIX .. "SunRays"
        ourRays.Spread = 1.0
        ourRays.Parent = Lighting
    end
    -- atmosphere: create only if the game has none
    pcall(function()
        if not Lighting:FindFirstChildOfClass("Atmosphere") then
            if not (ourAtmo and ourAtmo.Parent) then
                ourAtmo = Instance.new("Atmosphere")
                ourAtmo.Name = PREFIX .. "Atmo"
                ourAtmo.Offset = 0.6
                ourAtmo.Parent = Lighting
            end
        end
    end)
    -- clouds on terrain: create only if the game has none
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain and not terrain:FindFirstChildOfClass("Clouds") then
            if not (ourClouds and ourClouds.Parent) then
                ourClouds = Instance.new("Clouds")
                ourClouds.Name = PREFIX .. "Clouds"
                ourClouds.Parent = terrain
            end
        end
    end)
    parkGameFX()
end

local function atmoTarget()
    local a = ourAtmo
    if not (a and a.Parent) then
        a = Lighting:FindFirstChildOfClass("Atmosphere")
    end
    return a
end

local function cloudsTarget()
    if ourClouds and ourClouds.Parent then
        return ourClouds
    end
    local cl = nil
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            cl = terrain:FindFirstChildOfClass("Clouds")
        end
    end)
    return cl
end

--[[ night sky: empty skyboxes = clean black backdrop + engine star field.
      (same "" trick our black-hole script used -- verified behavior) ]]--
local function setNightSky(on)
    if on then
        if not (nightSky and nightSky.Parent) then
            pcall(function() if nightSky then nightSky:Destroy() end end)
            nightSky = Instance.new("Sky")
            nightSky.Name = PREFIX .. "Night"
            nightSky.SkyboxBk, nightSky.SkyboxDn, nightSky.SkyboxFt = "", "", ""
            nightSky.SkyboxLf, nightSky.SkyboxRt, nightSky.SkyboxUp = "", "", ""
            nightSky.CelestialBodiesShown = true -- keep the moon
            nightSky.StarCount = 2200
            nightSky.Parent = Lighting
        end
    else
        pcall(function() if nightSky then nightSky:Destroy() end end)
        nightSky = nil -- no Sky object -> Roblox default blue sky returns
    end
end

--[[ ------------------------ PRESET APPLY ------------------------------- ]]--
local activePreset = nil
local presetButtons = {}

local function applyPreset(name, instant)
    if not alive() then
        return
    end
    local p = PRESETS[name]
    if not p then
        return
    end
    ensureInstances()
    activePreset = name
    local dur = instant and 0.01 or 1.2

    twTo(Lighting, {
        ClockTime            = p.clock,
        Brightness           = p.brightness,
        Ambient              = p.ambient,
        OutdoorAmbient       = p.outdoor,
        FogColor             = p.fogColor,
        FogStart             = 0,
        FogEnd               = 125000,
        GlobalShadows        = p.shadows,
        ExposureCompensation = p.exposure,
    }, dur)
    pcall(function()
        twTo(Lighting, {
            EnvironmentDiffuseScale  = 1,
            EnvironmentSpecularScale = 1,
        }, dur)
    end)

    twTo(ourCC, {
        TintColor  = p.ccTint,
        Saturation = p.ccSat,
        Contrast   = p.ccCon,
    }, dur)
    twTo(ourRays, { Intensity = p.sunRays }, dur)

    local atmo = atmoTarget()
    if atmo then
        twTo(atmo, {
            Density = p.atmoDensity, Haze = p.atmoHaze, Glare = p.atmoGlare,
            Color = p.atmoColor, Decay = p.atmoDecay,
        }, dur)
    end

    local cl = cloudsTarget()
    if cl then
        twTo(cl, {
            Cover   = p.clouds.cover,
            Density = p.clouds.density,
            Color   = p.clouds.color,
        }, dur)
        pcall(function() cl.Enabled = true end)
    end

    -- night swaps the sky; day/sunset rely on the engine default sky
    if instant then
        setNightSky(p.night)
    else
        task.delay(0.5, function()
            if alive() and activePreset == name then
                setNightSky(p.night)
            end
        end)
    end

    for btnName, b in pairs(presetButtons) do
        local on = (btnName == name)
        pcall(function()
            b.btn.BackgroundColor3 = on and Color3.fromRGB(64, 120, 255) or Color3.fromRGB(38, 38, 46)
            b.label.TextColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 190, 200)
        end)
    end
end

--[[ ---------------------------- GUI ------------------------------------ ]]--
local function buildGUI()
    gui = Instance.new("ScreenGui")
    gui.Name = PREFIX .. "UI"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.IgnoreGuiInset = true

    local ok = pcall(function()
        gui.Parent = CoreGui
    end)
    if not ok or not gui.Parent then
        local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            gui.Parent = pg
        end
    end

    -- toast: quick confirmation that fades out (no clutter)
    local toast = Instance.new("TextLabel")
    toast.Name = "Toast"
    toast.AnchorPoint = Vector2.new(0.5, 0)
    toast.Position = UDim2.new(0.5, 0, 0, 24)
    toast.Size = UDim2.new(0, 340, 0, 34)
    toast.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    toast.BackgroundTransparency = 0.18
    toast.Text = "السماء الطبيعية اشتغلت -- جرّب الأزرار"
    toast.TextColor3 = Color3.fromRGB(235, 235, 240)
    toast.Font = Enum.Font.GothamMedium
    toast.TextSize = 15
    toast.BorderSizePixel = 0
    toast.Parent = gui
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 10)
    tCorner.Parent = toast
    task.delay(4.5, function()
        if gui and toast.Parent then
            local t = TweenService:Create(toast,
                TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { BackgroundTransparency = 1, TextTransparency = 1 })
            t:Play()
            task.delay(0.7, function()
                pcall(function() toast:Destroy() end)
            end)
        end
    end)

    -- main panel (bottom right, draggable, mobile friendly)
    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.Position = UDim2.new(1, -16, 1, -16)
    frame.Size = UDim2.new(0, 268, 0, 158)
    frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 14)
    fCorner.Parent = frame
    local fStroke = Instance.new("UIStroke")
    fStroke.Color = Color3.fromRGB(64, 120, 255)
    fStroke.Transparency = 0.55
    fStroke.Thickness = 1
    fStroke.Parent = frame

    -- title bar (drag handle)
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.new(0, 12, 0, 6)
    title.Size = UDim2.new(1, -48, 0, 26)
    title.BackgroundTransparency = 1
    title.Text = "QEYADA | السماء الطبيعية"
    title.TextColor3 = Color3.fromRGB(120, 170, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, -8, 0, 7)
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(220, 220, 228)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = closeBtn

    -- 2x2 preset grid
    local defs = {
        { id = "day",     label = "نهار",    pos = UDim2.new(0, 12, 0, 40) },
        { id = "sunset",  label = "غروب",   pos = UDim2.new(0.5, -6, 0, 40) },
        { id = "night",   label = "ليل",    pos = UDim2.new(0, 12, 0, 96) },
        { id = "restore", label = "الأصلية", pos = UDim2.new(0.5, -6, 0, 96) },
    }
    for _, d in ipairs(defs) do
        local btn = Instance.new("TextButton")
        btn.Name = d.id
        btn.Position = d.pos
        btn.Size = UDim2.new(0.5, -18, 0, 48)
        btn.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = frame
        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 10)
        bCorner.Parent = btn

        local label = Instance.new("TextLabel")
        label.Name = "L"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = d.label
        label.TextColor3 = Color3.fromRGB(190, 190, 200)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 17
        label.Parent = btn

        -- press feedback (shrink + back, like the intro button)
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn,
                TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Size = UDim2.new(0.5, -24, 0, 44) }):Play()
        end)
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn,
                TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = UDim2.new(0.5, -18, 0, 48) }):Play()
        end)
        btn.MouseEnter:Connect(function()
            if activePreset ~= d.id then
                btn.BackgroundColor3 = Color3.fromRGB(52, 52, 62)
            end
        end)
        btn.MouseLeave:Connect(function()
            if activePreset ~= d.id then
                btn.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
            end
        end)
        btn.MouseButton1Click:Connect(function()
            if d.id == "restore" then
                restoreVisuals() -- undo everything, panel stays alive
                activePreset = nil
                for _, b in pairs(presetButtons) do
                    pcall(function()
                        b.btn.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
                        b.label.TextColor3 = Color3.fromRGB(190, 190, 200)
                    end)
                end
            else
                applyPreset(d.id, false)
            end
        end)

        presetButtons[d.id] = { btn = btn, label = label }
    end

    -- X hides the panel; a small round handle stays to reopen it
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(frame,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }):Play()
        task.delay(0.3, function()
            if gui and frame.Parent then
                frame.Visible = false
                frame.Size = UDim2.new(0, 268, 0, 158)
                frame.BackgroundTransparency = 0.12
            end
        end)
        if not gui:FindFirstChild("Reopen") then
            local reopen = Instance.new("TextButton")
            reopen.Name = "Reopen"
            reopen.AnchorPoint = Vector2.new(1, 1)
            reopen.Position = UDim2.new(1, -16, 1, -16)
            reopen.Size = UDim2.new(0, 42, 0, 42)
            reopen.BackgroundColor3 = Color3.fromRGB(64, 120, 255)
            reopen.Text = "Q"
            reopen.TextColor3 = Color3.fromRGB(255, 255, 255)
            reopen.Font = Enum.Font.GothamBlack
            reopen.TextSize = 20
            reopen.BorderSizePixel = 0
            reopen.Parent = gui
            local rCorner = Instance.new("UICorner")
            rCorner.CornerRadius = UDim.new(1, 0)
            rCorner.Parent = reopen
            reopen.MouseButton1Click:Connect(function()
                reopen:Destroy()
                frame.Visible = true
            end)
        end
    end)

    -- classic drag (mouse + touch), no leaked per-drag connections
    local dragging, dragStart, startPos = false, nil, nil
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and not dead
            and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--[[ --------------------------- START ------------------------------------ ]]--
buildGUI()
applyPreset("day", true) -- start as a clean normal day, instantly
