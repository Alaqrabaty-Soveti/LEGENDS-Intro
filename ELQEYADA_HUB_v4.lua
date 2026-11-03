-- ============================================================================
--  EL QEYADA HUB  --  v4.0 "GARGANTUA EDITION"
--  ملف واحد مدموج: انترو El Qeyada + واجهة Ravex الكاملة (FO AHMED)
--  + تاب البلاك هول الواقعي (قرص تماسك حجمي: أبيض ساخن -> ذهبي -> برتقالي
--    + حلقة فوتون نحيفة + أفق أسود نقي -- صفر بنفسجي -- صفر حواف قطع ظاهرة)
--  مرجع الواقعية: Gargantua (Interstellar) + EHT M87
--  Loader:
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/LEGENDS_Intro_VFX_Studio_v2.lua"))()
-- ============================================================================

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Lighting     = game:GetService("Lighting")

local LocalPlayer  = Players.LocalPlayer

-- ---------------------------------------------------------------------------
-- [0] تنظيف أي نسخ قديمة (انترو قديم / شل قديم / بلاك هول قديم)
-- ---------------------------------------------------------------------------
pcall(function()
    local genv = (typeof(getgenv) == "function" and getgenv()) or _G
    if type(genv.__RavexEmptyShellCleanup) == "function" then genv.__RavexEmptyShellCleanup() end
    if type(genv.__RavexSAE_Cleanup) == "function" then genv.__RavexSAE_Cleanup() end
    if type(genv.__ElQeyadaHubCleanup) == "function" then genv.__ElQeyadaHubCleanup() end
    if type(genv.LEGENDS_INTRO_STOP) == "function" then genv.LEGENDS_INTRO_STOP() end
end)

local playerGui = nil
pcall(function() playerGui = LocalPlayer:WaitForChild("PlayerGui") end)
local guiRoot = nil
pcall(function() guiRoot = (type(gethui) == "function" and gethui()) or playerGui end)

local OLD_GUI_NAMES = {
    IntroQeyada = true,
    Ravex_EmptyShell_Gear = true,
    Ravex_EmptyShell_Gear_v2 = true,
    FOAHMED_CinematicIntro = true,
    ["Nexus Library V1"] = true,
    ["UIContainer_" .. tostring(LocalPlayer.UserId % 8999 + 1000)] = true,
}
for _, root in ipairs({ guiRoot, playerGui }) do
    if root then
        pcall(function()
            for _, child in ipairs(root:GetChildren()) do
                if OLD_GUI_NAMES[child.Name] then child:Destroy() end
            end
        end)
    end
end
-- مسح مشاهد البلاك هول القديمة من الجو (workspace + Lighting)
for _, root in ipairs({ workspace, Lighting }) do
    pcall(function()
        for _, obj in ipairs(root:GetChildren()) do
            local n = tostring(obj.Name)
            if n:sub(1, 8) == "LEGENDS_" or n:sub(1, 4) == "BH4_" or n == "ElQeyada_SpaceScene" then
                obj:Destroy()
            end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- [1] الإنترو (نفس هوية IntroQeyada بالظبط + توهين أنعم بـ TweenService)
-- ---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "IntroQeyada"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2147483647
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local guiParentOK = pcall(function()
    gui.Parent = game:GetService("CoreGui")
end)
if not guiParentOK then
    gui.Parent = playerGui
end

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://120102995443063"
sound.Volume = 0.7
sound.Parent = workspace

task.spawn(function()
    local t0 = tick()
    while sound.Parent and not sound.IsLoaded and tick() - t0 < 6 do
        task.wait()
    end
    if sound.Parent then
        sound.TimePosition = 9
        sound:Play()
    end
end)

local bg = Instance.new("ImageLabel")
bg.Name = "BG"
bg.Size = UDim2.new(1, 0, 1, 0)
bg.Position = UDim2.new(0, 0, 0, 0)
bg.Image = "rbxassetid://104907699047769"
bg.ScaleType = Enum.ScaleType.Crop
bg.BackgroundColor3 = Color3.new(0, 0, 0)
bg.BackgroundTransparency = 0
bg.ImageColor3 = Color3.new(1, 1, 1)
bg.ImageTransparency = 0
bg.ZIndex = 1
bg.Parent = gui

local dark = Instance.new("Frame")
dark.Name = "Overlay"
dark.Size = UDim2.new(1, 0, 1, 0)
dark.BackgroundColor3 = Color3.new(0, 0, 0)
dark.BackgroundTransparency = 1
dark.BorderSizePixel = 0
dark.ZIndex = 2
dark.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0.8, 0, 0, 60)
title.Position = UDim2.new(0, 20, 0.15, 0)
title.BackgroundTransparency = 1
title.Text = "Welcome / El Qeyada"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 32
title.TextStrokeColor3 = Color3.fromRGB(192, 192, 192)
title.TextStrokeTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTransparency = 1
title.ZIndex = 3
title.Parent = gui

local titleGlow = Instance.new("TextLabel")
titleGlow.Name = "TitleGlow"
titleGlow.Size = UDim2.new(0.8, 0, 0, 60)
titleGlow.Position = UDim2.new(0, 20, 0.15, 0)
titleGlow.BackgroundTransparency = 1
titleGlow.Text = "Welcome / El Qeyada"
titleGlow.TextColor3 = Color3.fromRGB(192, 192, 192)
titleGlow.Font = Enum.Font.GothamBlack
titleGlow.TextSize = 32
titleGlow.TextStrokeColor3 = Color3.fromRGB(192, 192, 192)
titleGlow.TextStrokeTransparency = 1
titleGlow.TextTransparency = 1
titleGlow.TextXAlignment = Enum.TextXAlignment.Left
titleGlow.ZIndex = 2
titleGlow.Parent = gui

-- ===== الزر الفخم =====
local outlineFrame = Instance.new("Frame")
outlineFrame.Name = "Outline"
outlineFrame.Size = UDim2.new(0, 186, 0, 61)
outlineFrame.Position = UDim2.new(0.5, -93, 0.72, 0)
outlineFrame.BackgroundColor3 = Color3.new(1, 1, 1)
outlineFrame.BackgroundTransparency = 1
outlineFrame.BorderSizePixel = 0
outlineFrame.Active = true
outlineFrame.ZIndex = 3
outlineFrame.Parent = gui

local outlineCorner = Instance.new("UICorner")
outlineCorner.CornerRadius = UDim.new(0, 12)
outlineCorner.Parent = outlineFrame

local outlineGradient = Instance.new("UIGradient")
outlineGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
    ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
})
outlineGradient.Rotation = 90
outlineGradient.Parent = outlineFrame

local mainButton = Instance.new("TextButton")
mainButton.Name = "MainButton"
mainButton.Size = UDim2.new(1, -6, 1, -6)
mainButton.Position = UDim2.new(0, 3, 0, 3)
mainButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainButton.BorderSizePixel = 0
mainButton.ClipsDescendants = true
mainButton.Text = "READY"
mainButton.TextColor3 = Color3.new(1, 1, 1)
mainButton.Font = Enum.Font.GothamBold
mainButton.TextSize = 18
mainButton.AutoButtonColor = false
mainButton.TextTransparency = 1
mainButton.ZIndex = 3
mainButton.Parent = outlineFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 10)
buttonCorner.Parent = mainButton

local shine = Instance.new("Frame")
shine.Name = "Shine"
shine.Size = UDim2.new(0, 80, 2, 0)
shine.Position = UDim2.new(-1.5, 0, -0.5, 0)
shine.BackgroundColor3 = Color3.new(1, 1, 1)
shine.BorderSizePixel = 0
shine.Rotation = 30
shine.ZIndex = 3
shine.Parent = mainButton

local shineGrad = Instance.new("UIGradient")
shineGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0.5),
    NumberSequenceKeypoint.new(1, 1)
})
shineGrad.Parent = shine

local spinConn = RunService.RenderStepped:Connect(function(dt)
    outlineGradient.Rotation = (outlineGradient.Rotation + dt * 120) % 360
end)

task.spawn(function()
    while gui and gui.Parent do
        task.wait(10)
        if not shine or not shine.Parent then break end
        shine.Position = UDim2.new(-1.5, 0, -0.5, 0)
        TweenService:Create(shine, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {
            Position = UDim2.new(2.5, 0, -0.5, 0)
        }):Play()
    end
end)

-- ===== Fade In ناعم (TweenService بدل اللوب اليدوي) =====
task.delay(0.05, function()
    local ti = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(dark, ti, { BackgroundTransparency = 0.35 }):Play()
    TweenService:Create(title, ti, { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
    TweenService:Create(titleGlow, ti, { TextTransparency = 0.4 }):Play()
    TweenService:Create(outlineFrame, ti, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(mainButton, ti, { TextTransparency = 0 }):Play()
end)

-- نبض توهج العنوان (لوب لا نهائي مع ارتداد)
task.delay(0.65, function()
    if titleGlow and titleGlow.Parent then
        TweenService:Create(titleGlow,
            TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { TextTransparency = 0.8 }):Play()
    end
end)

-- ===== تعريف بناء الواجهة (بينفذ بعد الضغط) =====
local buildHub = nil

-- ===== Event الزر =====
local started = false
mainButton.MouseButton1Click:Connect(function()
    if started then return end
    started = true

    pcall(function()
        sound:Stop()
        sound:Destroy()
    end)

    local ti = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(bg, ti, { ImageTransparency = 1 }):Play()
    TweenService:Create(dark, ti, { BackgroundTransparency = 0.55 }):Play()
    TweenService:Create(title, ti, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    TweenService:Create(titleGlow, ti, { TextTransparency = 1 }):Play()
    TweenService:Create(outlineFrame, ti, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(mainButton, ti, { TextTransparency = 1 }):Play()

    task.delay(0.42, function()
        pcall(function() spinConn:Disconnect() end)
        pcall(function() gui:Destroy() end)
        if type(buildHub) == "function" then
            task.spawn(function()
                local ok, err = pcall(buildHub)
                if not ok then
                    warn("[ElQeyada Hub] build error: " .. tostring(err))
                end
            end)
        end
    end)
end)

mainButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(outlineFrame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 176, 0, 56)
        }):Play()
    end
end)

mainButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(outlineFrame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 186, 0, 61)
        }):Play()
    end
end)

-- ===========================================================================
-- [2] بناء الواجهة الكاملة (مكتبة Ravex + التابات)
-- ===========================================================================
buildHub = function()

    local rawSrc = game:HttpGet("https://pastefy.app/1U7yV0yp/raw")
    assert(type(rawSrc) == "string" and #rawSrc > 100, "Ravex UI library could not be loaded")

    -- نفس باتشات الحماية المعتمدة: GUI جوه gethui/PlayerGui + اسم نظيف + أيقونة الترس
    rawSrc = rawSrc:gsub(
        'local CoreGui = game:GetService%("CoreGui"%)',
        'local CoreGui = (type(gethui) == "function" and gethui()) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")'
    )
    rawSrc = rawSrc:gsub('"Nexus Library V1"', '"Ravex_EmptyShell_Gear"')
    rawSrc = rawSrc:gsub("rbxassetid://135028606914792", "")
    rawSrc = rawSrc:gsub("rbxassetid://78796432043649", "rbxassetid://108953497423608")
    rawSrc = rawSrc:gsub("rbxassetid://92104411067431", "")
    rawSrc = rawSrc:gsub("ClickSound:Play%(%)", "do end")

    local loader, compileErr = loadstring(rawSrc)
    assert(type(loader) == "function", "Ravex UI library compile error: " .. tostring(compileErr))
    local redzlib = loader()
    assert(redzlib and type(redzlib.MakeWindow) == "function", "Ravex UI library did not initialize")

    local Window = redzlib:MakeWindow({
        Title = "FO AHMED",
        SubTitle = "El Qeyada Hub v4",
        SaveFolder = "FOAHMED_EmptyShell",
    })

    Window:AddMinimizeButton({
        Button = { Image = "rbxassetid://71104525444805", BackgroundTransparency = 0 },
        Corner = { CornerRadius = UDim.new(35, 1) },
    })

    local ALL_AREAS = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom", "Titan Temple", "Light Dark", "Enchanted Forest" }
    local ALL_RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }
    local Config = {}

    -- [Tab 01] الرئيسية
    -- ===========================================================================
    do
        local tabInfo = Window:MakeTab({ "الرئيسية", "" })
        pcall(function()
            tabInfo:AddInfoBruton()
        end)
        tabInfo:AddSection({ "الحالة المباشرة للسكربت || Live Status (v4)" })

        local LiveStatusParagraph = tabInfo:AddParagraph({
            Title = "📊 إحصائيات الجلسة المباشرة",
            Text = "واجهة تجريبية — الأزرار ظاهرة لكن وظائف اللعب معطّلة.",
        })

        local function notifyInWindow(msg)
            pcall(function()
                if LiveStatusParagraph then
                    LiveStatusParagraph:SetTitle("🔔 " .. tostring(msg))
                end
            end)
        end
        _G.__ElQeyadaNotify = notifyInWindow

        tabInfo:AddButton({
            Name = "🔍 فحص وتشخيص الماب والقاعدة (v4 Diagnostics)",
            Desc = "يتأكد من التعرف على قاعدتك وبيض الماب والموديولات",
            Callback = function() end,
        })

        tabInfo:AddSection({ "الحقوق (جاهزة لإضافة اسمك وانترو الفيديو بعد التجربة)" })
        tabInfo:AddParagraph({
            Title = "👑 النسخة المحدثة v4 (انترو El Qeyada + بلاك هول واقعي)",
            Text = "تم دمج انترو El Qeyada مع الواجهة الكاملة + تاب البلاك هول الواقعي (Gargantua Edition): قرص حجمي متدرج + حلقة فوتون + كواكب واقعية.",
        })
    end

    -- [Tab 02] قسم 2
    -- ===========================================================================
    do
        local tabSteal = Window:MakeTab({ Title = "قسم 2", Icon = "rbxassetid://" })
        tabSteal:AddSection("محرك السرقة الحقيقي لنسخة v668 بدون طرد")

        tabSteal:AddToggle({
            Title = "تفعيل السرقة التلقائية للبيض (Auto Steal v668)",
            Desc = "يسحب البيض بـ CarryFieldEgg الحقيقي مع مزامنة السيرفر ويسلمه للقاعدة",
            Default = false,
            Callback = function() end,
        })

        tabSteal:AddToggle({
            Title = "حماية مضاد الغش (v668 AC Integrity Shield)",
            Desc = "يصفر عدادات الطرد (Speed / Teleport Evidence) بدون أي Hook",
            Default = false,
            Callback = function() end,
        })

        tabSteal:AddToggle({
            Title = "زيادة السرعة المحمية (Protected Speed)",
            Desc = "يرفع سرعة المشي بأمان بشرط دعم المشغل لـ filtergc",
            Default = false,
            Callback = function() end,
        })

        tabSteal:AddToggle({
            Title = "استهداف أندر وأغلى بيضة أولاً ($/s + Rarity)",
            Default = true,
            Callback = function() end,
        })

        tabSteal:AddToggle({
            Title = "سحب البيض اليدوي الفوري بدون ضغط مطول (Instant Grab)",
            Default = false,
            Callback = function() end,
        })

        tabSteal:AddSection("فلاتر المناطق والندرة والطفرات")

        tabSteal:AddDropdown({
            Title = "تحديد المناطق (اتركها فارغة = كل المناطق)",
            Options = ALL_AREAS,
            Default = {},
            MultiSelect = true,
            Callback = function() end,
        })

        tabSteal:AddDropdown({
            Title = "تحديد الندرة المطلوبة (اتركها فارغة = الكل)",
            Options = ALL_RARITIES,
            Default = {},
            MultiSelect = true,
            Callback = function() end,
        })

        tabSteal:AddToggle({
            Title = "سرقة البيض المطفر فقط (Golden / Rainbow / Silver...)",
            Default = false,
            Callback = function() end,
        })

        tabSteal:AddSlider({
            Title = "عدد البيض في الجولة الواحدة",
            Min = 1,
            Max = 6,
            Increase = 1,
            Default = 1,
            Callback = function() end,
        })

        tabSteal:AddSlider({
            Title = "أقل نسبة ربح للبيضة (% من أقوى حيوان عندك)",
            Min = 0,
            Max = 25,
            Increase = 1,
            Default = 0,
            Callback = function() end,
        })

        tabSteal:AddSection("تحكم سريع بالشخصية")

        tabSteal:AddButton({
            Name = "🏠 الرجوع للقاعدة فوراً (Go Home)",
            Callback = function() end,
        })

        tabSteal:AddButton({
            Name = "🔓 فك تعليق الشخصية وإرجاع التحكم (Unstick)",
            Callback = function() end,
        })
    end

    -- [Tab 03] القاعدة والفقس والبيع والدمج
    -- ===========================================================================
    do
        local tabBase = Window:MakeTab({ Title = "قسم 3", Icon = "rbxassetid://" })
        tabBase:AddSection("إدارة البيض والحيوانات في القاعدة (v668)")

        tabBase:AddToggle({
            Title = "وضع البيض تلقائياً في القاعدة (Auto Place Eggs)",
            Desc = "يمسك البيضة بـ WearEggTool ويزرعها بـ PlantEgg في المساحة الفاضية",
            Default = false,
            Callback = function() end,
        })

        tabBase:AddToggle({
            Title = "فقس البيض الجاهز تلقائياً (Auto Hatch Ready Eggs)",
            Desc = "يفقس أي بيضة اكتمل نموها عبر PlacedEggRenderer.ActivateLocalEgg",
            Default = false,
            Callback = function() end,
        })

        tabBase:AddToggle({
            Title = "تجهيز أقوى الحيوانات تلقائياً (Auto Equip Best)",
            Default = false,
            Callback = function() end,
        })

        tabBase:AddToggle({
            Title = "دمج الحيوانات المتكررة تلقائياً (Auto Fuse 3+)",
            Desc = "يدمج كل 3 حيوانات متشابهة غير مجهزة في ماكينة الدمج",
            Default = false,
            Callback = function() end,
        })

        tabBase:AddToggle({
            Title = "إطعام البيض المصاب لوحش الحدث (Auto Feed Parasite)",
            Default = false,
            Callback = function() end,
        })

        tabBase:AddSection("البيع التلقائي للبيض وتجميع الأرباح")

        tabBase:AddToggle({
            Title = "بيع البيض الضعيف غير الموضوع تلقائياً (Auto Sell Eggs)",
            Default = false,
            Callback = function() end,
        })

        tabBase:AddDropdown({
            Title = "ندرة البيض المراد بيعه تلقائياً",
            Options = ALL_RARITIES,
            Default = { "Common", "Uncommon", "Rare" },
            MultiSelect = true,
            Callback = function() end,
        })

        tabBase:AddToggle({
            Title = "استلام أرباح الأوفلاين تلقائياً (عند التواجد بالقاعدة)",
            Default = false,
            Callback = function() end,
        })

        tabBase:AddToggle({
            Title = "استلام جوائز الأندكس تلقائياً (Auto Redeem Codex)",
            Default = false,
            Callback = function() end,
        })
    end

    -- [Tab 04] التدريب والتطوير
    -- ===========================================================================
    do
        local tabTrain = Window:MakeTab({ Title = "قسم 4", Icon = "rbxassetid://" })
        tabTrain:AddSection("تدريب السرعة على المشاية (Treadmill)")

        tabTrain:AddToggle({
            Title = "تدريب تلقائي عندما تكون سرعتك أقل من الحراس",
            Default = false,
            Callback = function() end,
        })

        tabTrain:AddToggle({
            Title = "تدريب مستمر على المشاية فقط (AFK Speed Farm)",
            Default = false,
            Callback = function() end,
        })

        tabTrain:AddSlider({
            Title = "مدة جولة التدريب الواحدة (ثانية)",
            Min = 5,
            Max = 60,
            Increase = 5,
            Default = 20,
            Callback = function() end,
        })

        tabTrain:AddSection("الشراء والتطوير التلقائي (v668)")

        tabTrain:AddToggle({
            Title = "تطوير مستوى القاعدة تلقائياً (BaseUpgrade.PurchaseNextTier)",
            Default = false,
            Callback = function() end,
        })

        tabTrain:AddToggle({
            Title = "تطوير المشاية تلقائياً (Auto Upgrade Treadmill)",
            Default = false,
            Callback = function() end,
        })

        tabTrain:AddSlider({
            Title = "الحد الأقصى لسعر تطوير المشاية (0 = بلا حد، 6 = مليون، 9 = مليار)",
            Min = 0,
            Max = 15,
            Increase = 1,
            Default = 0,
            Callback = function() end,
        })

        tabTrain:AddToggle({
            Title = "شراء المسارات تلقائياً (Auto Buy Trails)",
            Default = false,
            Callback = function() end,
        })
    end

    -- [Tab 05] الفخاخ والحراس
    -- ===========================================================================
    do
        local tabCombat = Window:MakeTab({ Title = "قسم 5", Icon = "rbxassetid://" })
        tabCombat:AddSection("المضرب والقتال (Bat Kill Aura)")

        tabCombat:AddToggle({
            Title = "ضرب تلقائي بالمضرب لأي لاعب قريب (Bat Hit Aura)",
            Desc = "امسك المضرب في يدك وسيضرب أي لاعب يقترب منك تلقائياً",
            Default = false,
            Callback = function() end,
        })

        tabCombat:AddSlider({
            Title = "مدى الضرب التلقائي (Studs)",
            Min = 8,
            Max = 20,
            Increase = 1,
            Default = 16,
            Callback = function() end,
        })

        tabCombat:AddToggle({
            Title = "تجاهل الأصدقاء في الضرب (Skip Friends)",
            Default = true,
            Callback = function() end,
        })

        tabCombat:AddSection("الحماية من الفخاخ والوقوع والحراس")

        tabCombat:AddToggle({
            Title = "تعطيل فخاخ اللاعبين المعادية بالكامل (Anti-Trap v668)",
            Desc = "يلغي لمس فخاخ الأعداء (PlacedTrap) مع ترك فخاخك أنت شغالة!",
            Default = false,
            Callback = function() end,
        })

        tabCombat:AddToggle({
            Title = "منع الطيران والوقوع (No Knockback & Anti-Ragdoll)",
            Default = false,
            Callback = function() end,
        })

        tabCombat:AddToggle({
            Title = "حماية سرعة الحراس (تجنب المناطق الأخطر من سرعتك)",
            Default = true,
            Callback = function() end,
        })
    end

    -- [Tab 06] الكشف البصري والأداء
    -- ===========================================================================
    do
        local tabVisual = Window:MakeTab({ Title = "قسم 6", Icon = "rbxassetid://" })
        tabVisual:AddSection("الكشف البصري الحقيقي للبيض والفخاخ (v668 ESP)")

        tabVisual:AddToggle({
            Title = "كشف البيض بالندرة والسعر والطفرة (Egg ESP v668)",
            Default = false,
            Callback = function() end,
        })

        tabVisual:AddToggle({
            Title = "تنبيه عند ظهور بيضة أسطورية (Cosmic / Secret / Divine)",
            Default = true,
            Callback = function() end,
        })

        tabVisual:AddSlider({
            Title = "مسافة كشف الـ ESP",
            Min = 100,
            Max = 1500,
            Increase = 50,
            Default = 600,
            Callback = function() end,
        })

        tabVisual:AddToggle({
            Title = "كشف أماكن فخاخ اللاعبين (PlacedTrap ESP)",
            Default = false,
            Callback = function() end,
        })

        tabVisual:AddSection("تخفيف اللاج وتبديل السيرفرات")

        tabVisual:AddToggle({
            Title = "رفع الفريمات وإزالة اللاج (Extreme FPS Boost)",
            Default = false,
            Callback = function() end,
        })

        tabVisual:AddToggle({
            Title = "إخفاء حيوانات قواعد اللاعبين الآخرين لتخفيف التهنيج",
            Default = false,
            Callback = function() end,
        })

        tabVisual:AddToggle({
            Title = "منع الطرد بسبب الخمول (Silent Anti-AFK)",
            Default = false,
            Callback = function() end,
        })

        tabVisual:AddButton({
            Name = "🌐 الانتقال لسيرفر هادئ قليل اللاعبين (Low Server Hop)",
            Callback = function() end,
        })

        tabVisual:AddButton({
            Name = "🔀 تبديل السيرفر عشوائي (Server Hop)",
            Callback = function() end,
        })
    end

    -- ===========================================================================
    -- [7] تاب البلاك هول الواقعي — GARGANTUA EDITION
    -- قرص تماسك حجمي (أبيض ساخن -> ذهبي -> برتقالي محروق) + حلقة فوتون نحيفة
    -- تواجه الكاميرا كل فريم (ظاهرة العدسة) + أفق أسود نقي + Doppler beaming
    -- + صندوق فضاء أسود بحوائط حقيقية + نجوم كروية + كواكب واقعية بمواد حقيقية
    -- ===========================================================================
    do
        local UIS = game:GetService("UserInputService")
        local isTouch = false
        pcall(function() isTouch = UIS.TouchEnabled and not UIS.KeyboardEnabled end)

        -- لوحة ألوان Gargantua المعتمدة (صفر بنفسجي)
        local C_CORE   = Color3.fromRGB(255, 252, 240) -- أبيض ساخن (الحافة الداخلية)
        local C_HOT    = Color3.fromRGB(255, 236, 186) -- ذهبي فاتح
        local C_EMBER  = Color3.fromRGB(255, 192, 104) -- ذهبي برتقالي
        local C_PLASMA = Color3.fromRGB(255, 136, 44)  -- برتقالي عميق
        local C_ROSE   = Color3.fromRGB(188, 72, 24)   -- برتقالي محروق (الطرف)

        local HOLE = Vector3.new(0, 5000, 0)
        local SCENE_NAME = "ElQeyada_SpaceScene"

        local BH = {
            built = false, scale = 1, spin = 0.24,
            planetsOn = true, glow = true,
            conns = {}, scene = nil, planetsModel = nil,
            camRings = {}, dopRings = {}, ringFX = {}, dustAnchors = {},
            planets = {}, twinkle = {},
            savedSky = nil, platform = nil,
        }

        local function mkPart(props)
            local p = Instance.new("Part")
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = Enum.Material.Neon
            p.TopSurface = Enum.SurfaceType.Smooth
            p.BottomSurface = Enum.SurfaceType.Smooth
            for k, v in pairs(props) do
                p[k] = v
            end
            p.Parent = BH.scene
            return p
        end

        -- حلقة Beam من 64 وتر = دايرة هندسية كاملة بدون أي أضلاع ظاهرة
        local function beamRing(centerCF, radius, width, color, tr, spd, bright, nSeg, anim, dop)
            nSeg = nSeg or 64
            local anchor = mkPart({
                Name = "BH4_Ring",
                Size = Vector3.new(0.4, 0.4, 0.4),
                Transparency = 1,
                CFrame = centerCF,
            })
            local atts = {}
            for i = 1, nSeg do
                local a = (i / nSeg) * math.pi * 2
                local at = Instance.new("Attachment")
                at.Position = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
                at.Parent = anchor
                atts[i] = at
            end
            local beams = {}
            for i = 1, nSeg do
                local b = Instance.new("Beam")
                b.Attachment0 = atts[i]
                b.Attachment1 = atts[(i % nSeg) + 1]
                b.Width0 = width
                b.Width1 = width
                b.Color = ColorSequence.new(color)
                b.Transparency = NumberSequence.new(tr)
                b.LightEmission = 1
                b.LightInfluence = 0
                b.Brightness = bright
                b.Texture = "rbxasset://textures/particles/fire_main.dds"
                b.TextureMode = Enum.TextureMode.Wrap
                b.TextureLength = (2 * math.pi * radius) / 8
                b.TextureSpeed = spd
                b.FaceCamera = true
                b.Segments = 1
                b.Parent = anchor
                beams[i] = b
            end
            if anim then
                BH.ringFX[#BH.ringFX + 1] = { beams = beams, base = tr, amp = anim[1], freq = anim[2], ph = anim[3] }
            end
            if dop then
                -- Doppler: الجهة اللي مادتها بتتحرك ناحية الكاميرا بتولع أكتر (زي Gargantua)
                local dr = { beams = beams, brBase = bright, dirs = {}, mids = {} }
                for i = 1, nSeg do
                    local am = ((i - 0.5) / nSeg) * math.pi * 2
                    local lm = Vector3.new(math.cos(am) * radius, 0, math.sin(am) * radius)
                    dr.mids[i] = (centerCF * CFrame.new(lm)).Position
                    dr.dirs[i] = centerCF:VectorToWorldSpace(Vector3.new(-math.sin(am), 0, math.cos(am))).Unit
                end
                BH.dopRings[#BH.dopRings + 1] = dr
            end
            return anchor
        end

        local function dustEmitter(parent, rate, s0, s1, life, c0, c1)
            local pe = Instance.new("ParticleEmitter")
            pe.Texture = "rbxasset://textures/particles/fire_main.dds"
            pe.Rate = rate
            pe.Lifetime = NumberRange.new(life * 0.6, life)
            pe.Speed = NumberRange.new(0.4, 1.4)
            pe.SpreadAngle = Vector2.new(8, 8)
            pe.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, s0),
                NumberSequenceKeypoint.new(0.5, (s0 + s1) * 0.5),
                NumberSequenceKeypoint.new(1, s1),
            })
            pe.Color = ColorSequence.new(c0, c1)
            pe.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.25),
                NumberSequenceKeypoint.new(0.6, 0.45),
                NumberSequenceKeypoint.new(1, 1),
            })
            pe.LightEmission = 1
            pe.LightInfluence = 0
            pe.RotSpeed = NumberRange.new(-25, 25)
            pe.Parent = parent
            return pe
        end

        local function applyFX()
            pcall(function()
                if not BH.glow then return end
                if not Lighting:FindFirstChild("BH4_Bloom") then
                    local bl = Instance.new("BloomEffect")
                    bl.Name = "BH4_Bloom"
                    bl.Intensity = 0.9
                    bl.Size = 24
                    bl.Threshold = 1.55
                    bl.Parent = Lighting
                end
                if not Lighting:FindFirstChild("BH4_ColorCorrection") then
                    local cc = Instance.new("ColorCorrectionEffect")
                    cc.Name = "BH4_ColorCorrection"
                    cc.Contrast = 0.05
                    cc.Saturation = 0.02
                    cc.Parent = Lighting
                end
            end)
        end

        local function removeFX()
            pcall(function()
                local bl = Lighting:FindFirstChild("BH4_Bloom")
                if bl then bl:Destroy() end
                local cc = Lighting:FindFirstChild("BH4_ColorCorrection")
                if cc then cc:Destroy() end
            end)
        end

        -- ===== الكواكب الواقعية: كرة واحدة ناعمة + مادة حقيقية + غلاف جوي شفاف =====
        -- (بدون شرائح Beam وبدون أقراص بارزة -- صفر حواف ظاهرة)
        local PLANET_DEFS = {
            { name = "Lavaheart",  size = 26, mat = Enum.Material.CrackedLava, color = Color3.fromRGB(72, 24, 14),
              orbit = 210, speed = 0.100, y = 55,  light = Color3.fromRGB(255, 110, 30),  lightB = 0.55 },
            { name = "DustRock",   size = 18, mat = Enum.Material.Slate,       color = Color3.fromRGB(128, 96, 72),
              orbit = 268, speed = 0.075, y = -40 },
            { name = "GasGiant",   size = 44, mat = Enum.Material.Sand,        color = Color3.fromRGB(208, 158, 104),
              orbit = 345, speed = 0.050, y = 30,  atmo = Color3.fromRGB(255, 196, 130), rings = true },
            { name = "IceVeil",    size = 30, mat = Enum.Material.Glacier,     color = Color3.fromRGB(188, 214, 236),
              orbit = 432, speed = 0.038, y = -65, atmo = Color3.fromRGB(150, 200, 255),
              light = Color3.fromRGB(150, 200, 255), lightB = 0.35 },
            { name = "AbyssBlue",  size = 22, mat = Enum.Material.Glass,       color = Color3.fromRGB(36, 70, 130),
              orbit = 505, speed = 0.030, y = 80,  atmo = Color3.fromRGB(110, 160, 255), reflect = 0.15 },
        }

        local function buildPlanets()
            if BH.planetsModel or not BH.scene then return end
            local m = Instance.new("Model")
            m.Name = "BH4_Planets"
            m.Parent = BH.scene
            BH.planetsModel = m
            BH.planets = {}
            for idx, def in ipairs(PLANET_DEFS) do
                local holder = Instance.new("Model")
                holder.Name = def.name
                holder.Parent = m

                local s = def.size
                local ball = Instance.new("Part")
                ball.Name = def.name .. "_Core"
                ball.Shape = Enum.PartType.Ball
                ball.Material = def.mat
                ball.Color = def.color
                ball.Reflectance = def.reflect or 0
                ball.Anchored = true
                ball.CanCollide = false
                ball.CanTouch = false
                ball.CanQuery = false
                ball.CastShadow = false
                ball.TopSurface = Enum.SurfaceType.Smooth
                ball.BottomSurface = Enum.SurfaceType.Smooth
                ball.Size = Vector3.new(s, s, s)
                ball.Parent = holder

                if def.atmo then
                    local at = Instance.new("Part")
                    at.Name = def.name .. "_Atmo"
                    at.Shape = Enum.PartType.Ball
                    at.Material = Enum.Material.SmoothPlastic
                    at.Color = def.atmo
                    at.Transparency = 0.78
                    at.Anchored = true
                    at.CanCollide = false
                    at.CanTouch = false
                    at.CanQuery = false
                    at.CastShadow = false
                    at.Size = Vector3.new(s * 1.07, s * 1.07, s * 1.07)
                    at.Parent = holder
                    def._atmoPart = at
                else
                    def._atmoPart = nil
                end

                if def.light then
                    local pl = Instance.new("PointLight")
                    pl.Color = def.light
                    pl.Brightness = def.lightB or 0.4
                    pl.Range = 42
                    pl.Parent = ball
                end

                local entry = {
                    def = def, ball = ball, holder = holder,
                    ang = (idx / #PLANET_DEFS) * math.pi * 2 + 0.7,
                    ringAnchors = {},
                }

                -- حلقات زحل ناعمة للعملاق الغازي (Beam = حرير بدون أضلاع)
                if def.rings then
                    local tan1 = Color3.fromRGB(226, 202, 164)
                    local tan2 = Color3.fromRGB(236, 212, 172)
                    local mkPlanetRing = function(r, w, c, tr)
                        local anchor = Instance.new("Part")
                        anchor.Name = def.name .. "_Ring"
                        anchor.Size = Vector3.new(0.3, 0.3, 0.3)
                        anchor.Transparency = 1
                        anchor.Anchored = true
                        anchor.CanCollide = false
                        anchor.CanQuery = false
                        anchor.CanTouch = false
                        anchor.CastShadow = false
                        anchor.Parent = holder
                        local atts = {}
                        local nSeg = isTouch and 32 or 48
                        for i = 1, nSeg do
                            local a = (i / nSeg) * math.pi * 2
                            local at = Instance.new("Attachment")
                            at.Position = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
                            at.Parent = anchor
                            atts[i] = at
                        end
                        for i = 1, nSeg do
                            local b = Instance.new("Beam")
                            b.Attachment0 = atts[i]
                            b.Attachment1 = atts[(i % nSeg) + 1]
                            b.Width0 = w
                            b.Width1 = w
                            b.Color = ColorSequence.new(c)
                            b.Transparency = NumberSequence.new(tr)
                            b.LightEmission = 1
                            b.LightInfluence = 0
                            b.Brightness = 1.5
                            b.FaceCamera = false
                            b.Segments = 1
                            b.Parent = anchor
                        end
                        return anchor
                    end
                    entry.ringAnchors[1] = mkPlanetRing(s * 1.55, 1.6, tan1, 0.35)
                    entry.ringAnchors[2] = mkPlanetRing(s * 1.75, 2.2, tan2, 0.25)
                end

                BH.planets[#BH.planets + 1] = entry
            end
        end

        local function destroyPlanets()
            pcall(function()
                if BH.planetsModel then BH.planetsModel:Destroy() end
            end)
            BH.planetsModel = nil
            BH.planets = {}
        end

        -- ===== بناء المشهد الكامل =====
        local function startBH()
            if BH.built then return end
            BH.built = true

            -- سما سوداء نقية (إصلاح السما الرمادية المعتمد) مع حفظ السما الأصلية
            pcall(function()
                local existing = Lighting:FindFirstChildOfClass("Sky")
                if existing and existing.Name ~= "BH4_BlackSky" then
                    BH.savedSky = existing
                    existing.Parent = nil
                end
                local sky = Instance.new("Sky")
                sky.Name = "BH4_BlackSky"
                sky.SkyboxBk = ""
                sky.SkyboxDn = ""
                sky.SkyboxFt = ""
                sky.SkyboxLf = ""
                sky.SkyboxRt = ""
                sky.SkyboxUp = ""
                sky.CelestialBodiesShown = false
                sky.Parent = Lighting
            end)

            local scene = Instance.new("Model")
            scene.Name = SCENE_NAME
            scene.Parent = workspace
            BH.scene = scene

            local s = BH.scale

            -- صندوق الفضاء: 6 حوائط حقيقية (الباك فيس كولينج بيخلي الحائط الواحد مخفي من جوه)
            local WALL_T, WALL_D = 8, 1024
            local wallDefs = {
                { size = Vector3.new(2048, WALL_T, 2048), off = Vector3.new(0,  WALL_D, 0) },
                { size = Vector3.new(2048, WALL_T, 2048), off = Vector3.new(0, -WALL_D, 0) },
                { size = Vector3.new(WALL_T, 2048, 2048), off = Vector3.new( WALL_D, 0, 0) },
                { size = Vector3.new(WALL_T, 2048, 2048), off = Vector3.new(-WALL_D, 0, 0) },
                { size = Vector3.new(2048, 2048, WALL_T), off = Vector3.new(0, 0,  WALL_D) },
                { size = Vector3.new(2048, 2048, WALL_T), off = Vector3.new(0, 0, -WALL_D) },
            }
            for wi, wd in ipairs(wallDefs) do
                mkPart({
                    Name = "BH4_Wall" .. wi,
                    Size = wd.size,
                    Color = Color3.new(0, 0, 0),
                    Material = Enum.Material.SmoothPlastic,
                    Reflectance = 0,
                    CFrame = CFrame.new(HOLE + wd.off),
                })
            end

            -- منصة المشاهدة (فوقها واقف بتشوف البلاك هول)
            local platform = mkPart({
                Name = "BH4_Platform",
                Size = Vector3.new(160, 8, 160),
                Color = Color3.fromRGB(20, 20, 26),
                Material = Enum.Material.Slate,
                CFrame = CFrame.new(620, 4450, 0),
            })
            platform.CanCollide = true
            BH.platform = platform
            local plight = Instance.new("PointLight")
            plight.Color = C_EMBER
            plight.Brightness = 0.5
            plight.Range = 40
            plight.Parent = platform

            -- الأفق: كرة سوداء نقية (زيرو لمعان)
            local core = mkPart({
                Name = "BH4_Core",
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(44 * s, 44 * s, 44 * s),
                Color = Color3.new(0, 0, 0),
                Material = Enum.Material.SmoothPlastic,
                Reflectance = 0,
                CFrame = CFrame.new(HOLE),
            })
            local glow = mkPart({
                Name = "BH4_Glow",
                Shape = Enum.PartType.Ball,
                Size = Vector3.new(64 * s, 64 * s, 64 * s),
                Color = C_HOT,
                Transparency = 0.95,
                Material = Enum.Material.Neon,
                CFrame = CFrame.new(HOLE),
            })

            -- ميل القرص (نفس الميل المعتمد)
            local diskTilt = CFrame.Angles(math.rad(14), 0, math.rad(-6))
            local diskBase0 = CFrame.new(HOLE) * diskTilt

            -- حلقة الفوتون + الهالة: بتواجه الكاميرا كل فريم (ظاهرة عدسة حقيقية)
            local camLook0 = CFrame.lookAt(HOLE, HOLE + Vector3.new(0, 0, -1))
            local photonA = beamRing(camLook0, 24.5 * s, 1.5 * s, C_CORE,  0.00, 0.55, 4.2, isTouch and 44 or 64, { 0.05, 2.6, 0.0 })
            local photonB = beamRing(camLook0, 26.5 * s, 2.8 * s, C_HOT,   0.45, 0.38, 2.3, isTouch and 44 or 64, { 0.10, 2.6, 0.9 })
            local haloA   = beamRing(camLook0, 31.0 * s, 2.2 * s, C_EMBER, 0.55, 0.26, 1.9, isTouch and 44 or 64, { 0.12, 1.9, 1.6 })
            photonA.Name = "BH4_PhotonRing"
            photonB.Name = "BH4_PhotonBloom"
            haloA.Name = "BH4_LensHalo"
            BH.camRings = { photonA, photonB, haloA }

            -- قرص التماسك: 12 حلقة تخطيطية (كبلرية) -- الداخل سريع وساخن، الخارج بطيء ومحروق
            local diskRings = {
                { r = 28.5,  w = 3.2, c = C_CORE,   tr = 0.02, sp = 1.05, br = 3.2 },
                { r = 34,    w = 2.6, c = C_CORE,   tr = 0.08, sp = 0.88, br = 3.1 },
                { r = 40.5,  w = 3.0, c = C_HOT,    tr = 0.13, sp = 0.70, br = 3.0 },
                { r = 48,    w = 2.6, c = C_HOT,    tr = 0.20, sp = 0.55, br = 2.8 },
                { r = 57,    w = 3.4, c = C_EMBER,  tr = 0.26, sp = 0.44, br = 2.6 },
                { r = 68,    w = 2.6, c = C_EMBER,  tr = 0.34, sp = 0.36, br = 2.4 },
                { r = 81,    w = 3.6, c = C_PLASMA, tr = 0.42, sp = 0.29, br = 2.2 },
                { r = 96,    w = 3.0, c = C_PLASMA, tr = 0.52, sp = 0.22, br = 2.0 },
                { r = 114,   w = 4.2, c = C_ROSE,   tr = 0.62, sp = 0.16, br = 1.7 },
                { r = 134,   w = 4.8, c = C_ROSE,   tr = 0.74, sp = 0.11, br = 1.4 },
                { r = 158,   w = 7.0, c = C_ROSE,   tr = 0.85, sp = 0.07, br = 1.0 },
                { r = 184,   w = 9.0, c = C_ROSE,   tr = 0.92, sp = 0.05, br = 0.8 },
            }
            for ri, dr in ipairs(diskRings) do
                -- الدوبلر على الحلقات الداخلية المضيئة بس (توفير أداء على الموبايل)
                local useDop = (not isTouch) and ri <= 8
                beamRing(diskBase0, dr.r * s, dr.w * s, dr.c, dr.tr, dr.sp, dr.br, isTouch and 40 or 64, nil, useDop)
            end

            -- غبار مداري: أنكورات بتلف -- الجزيئات بتتولد على أقواس متحركة (حركة حريرية)
            BH.dustAnchors = {}
            local dustDefs = {
                { r = 45 * s,  rate = 26, spd = 0.55, s0 = 0.6, s1 = 1.8, life = 2.2, c0 = C_CORE,   c1 = C_EMBER },
                { r = 80 * s,  rate = 20, spd = 0.34, s0 = 1.0, s1 = 2.6, life = 2.8, c0 = C_HOT,    c1 = C_PLASMA },
                { r = 122 * s, rate = 14, spd = 0.20, s0 = 1.4, s1 = 3.4, life = 3.4, c0 = C_EMBER,  c1 = C_ROSE },
            }
            for di, dd in ipairs(dustDefs) do
                local anchor = mkPart({
                    Name = "BH4_Dust" .. di,
                    Size = Vector3.new(0.3, 0.3, 0.3),
                    Transparency = 1,
                    CFrame = diskBase0 * CFrame.Angles(0, di * 2.1, 0),
                })
                dustEmitter(anchor, dd.rate, dd.s0, dd.s1, dd.life, dd.c0, dd.c1)
                BH.dustAnchors[di] = { part = anchor, base = diskBase0, spd = dd.spd }
            end

            -- حقل النجوم: كرات صغيرة (أبد بلوكات مربعة) + ستارة بعيدة + سدم
            local STAR_COLORS = {
                Color3.fromRGB(255, 250, 240),
                Color3.fromRGB(210, 222, 255),
                Color3.fromRGB(255, 240, 214),
                Color3.fromRGB(178, 198, 255),
            }
            local starN = isTouch and 170 or 300
            for i = 1, starN do
                local giant = i <= 10
                local rr = 320 + math.random() * 620
                local aa = math.random() * math.pi * 2
                local yy = (math.random() - 0.5) * 1500
                local sz = giant and (1.8 + math.random() * 1.2) or (0.7 + math.random() * 0.6)
                local st = mkPart({
                    Name = "BH4_Star",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(sz, sz, sz),
                    Color = giant and Color3.fromRGB(255, 250, 240) or STAR_COLORS[math.random(1, #STAR_COLORS)],
                    Material = Enum.Material.Neon,
                    CFrame = CFrame.new(HOLE + Vector3.new(math.cos(aa) * rr, yy, math.sin(aa) * rr)),
                })
                if i <= 60 then
                    BH.twinkle[#BH.twinkle + 1] = {
                        part = st, base = 0, amp = 0.45,
                        spd = 0.8 + math.random() * 2.2, ph = math.random() * math.pi * 2,
                    }
                end
            end
            local curtainN = isTouch and 120 or 220
            for i = 1, curtainN do
                local rr = 880 + math.random() * 110
                local aa = math.random() * math.pi * 2
                local yy = (math.random() - 0.5) * 1800
                local sz = 0.35 + math.random() * 0.35
                mkPart({
                    Name = "BH4_StarFar",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(sz, sz, sz),
                    Color = STAR_COLORS[math.random(1, #STAR_COLORS)],
                    Material = Enum.Material.SmoothPlastic,
                    CFrame = CFrame.new(HOLE + Vector3.new(math.cos(aa) * rr, yy, math.sin(aa) * rr)),
                })
            end
            -- سدم غازية (ألوان فضاء واقعية -- بدون أي بنفسجي)
            local NEBULA = {
                Color3.fromRGB(38, 60, 148), Color3.fromRGB(22, 84, 104),
                Color3.fromRGB(128, 62, 30), Color3.fromRGB(54, 80, 140),
            }
            for i = 1, 7 do
                local rr = 640 + math.random() * 300
                local aa = math.random() * math.pi * 2
                local yy = (math.random() - 0.5) * 1100
                local sz = 180 + math.random() * 240
                mkPart({
                    Name = "BH4_Nebula",
                    Shape = Enum.PartType.Ball,
                    Size = Vector3.new(sz, sz * (0.55 + math.random() * 0.4), sz),
                    Color = NEBULA[math.random(1, #NEBULA)],
                    Material = Enum.Material.SmoothPlastic,
                    Transparency = 0.93 + math.random() * 0.04,
                    CFrame = CFrame.new(HOLE + Vector3.new(math.cos(aa) * rr, yy, math.sin(aa) * rr))
                        * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3),
                })
            end

            if BH.planetsOn then
                buildPlanets()
            end
            applyFX()

            -- حلقة التحديث: حلقة الفوتون تواجه الكاميرا + الدوبلر + وميض النجوم + مدارات الكواكب
            local clock = 0
            table.insert(BH.conns, RunService.Heartbeat:Connect(function(dt)
                clock = clock + dt
                local cam = workspace.CurrentCamera

                if cam and cam.CFrame and (cam.Position - HOLE).Magnitude > 5 then
                    local camPos = cam.Position
                    -- حلقة الفوتون + الهالة تحيط بالكاميرا (السيلويت يفضل ثابت من أي زاوية)
                    for _, ringAnchor in ipairs(BH.camRings) do
                        pcall(function()
                            ringAnchor.CFrame = CFrame.lookAt(HOLE, camPos)
                        end)
                    end
                    -- Doppler beaming
                    if not isTouch then
                        for _, dr in ipairs(BH.dopRings) do
                            for i = 1, #dr.beams do
                                local delta = camPos - dr.mids[i]
                                if delta.Magnitude > 0.5 then
                                    local toCam = delta.Unit
                                    local d = dr.dirs[i]:Dot(toCam)
                                    local b = dr.brBase * (1.15 + 0.85 * d)
                                    if b < 0.4 then b = 0.4 end
                                    dr.beams[i].Brightness = b
                                end
                            end
                        end
                    end
                end

                -- تنفس الحلقات (شفافية متذبذبة)
                for _, fx in ipairs(BH.ringFX) do
                    local tr = fx.base + fx.amp * math.sin(clock * fx.freq + fx.ph)
                    for _, b in ipairs(fx.beams) do
                        b.Transparency = NumberSequence.new(tr)
                    end
                end

                -- دوران الغبار المداري
                for _, da in ipairs(BH.dustAnchors) do
                    da.part.CFrame = da.base * CFrame.Angles(0, clock * da.spd * (BH.spin / 0.24), 0)
                end

                -- وميض النجوم
                for _, tw in ipairs(BH.twinkle) do
                    local tr = tw.base + tw.amp * (0.5 + 0.5 * math.sin(clock * tw.spd + tw.ph))
                    tw.part.Transparency = tr
                end

                -- مدارات الكواكب
                if BH.planetsModel then
                    for _, pe in ipairs(BH.planets) do
                        local def = pe.def
                        pe.ang = pe.ang + dt * def.speed
                        local pos = HOLE + Vector3.new(math.cos(pe.ang) * def.orbit, def.y, math.sin(pe.ang) * def.orbit)
                        local cf = CFrame.new(pos) * CFrame.Angles(math.rad(10), 0, math.rad(6))
                        pe.ball.CFrame = cf
                        if def._atmoPart then
                            def._atmoPart.CFrame = cf
                        end
                        for _, ra in ipairs(pe.ringAnchors) do
                            ra.CFrame = cf
                        end
                    end
                end
            end))
        end

        -- ===== إيقاف ومسح المشهد =====
        local function stopBH()
            for _, c in ipairs(BH.conns) do
                pcall(function() c:Disconnect() end)
            end
            BH.conns = {}
            pcall(function()
                if BH.scene then BH.scene:Destroy() end
            end)
            BH.scene = nil
            BH.planetsModel = nil
            BH.planets = {}
            BH.camRings = {}
            BH.dopRings = {}
            BH.ringFX = {}
            BH.dustAnchors = {}
            BH.twinkle = {}
            BH.platform = nil
            pcall(function()
                local sky = Lighting:FindFirstChild("BH4_BlackSky")
                if sky then sky:Destroy() end
                if BH.savedSky then
                    BH.savedSky.Parent = Lighting
                    BH.savedSky = nil
                end
            end)
            removeFX()
            BH.built = false
        end

        local rebuildToken = 0
        local function rebuildBH()
            if not BH.built then return end
            stopBH()
            startBH()
        end
        local function scheduleRebuild()
            rebuildToken = rebuildToken + 1
            local my = rebuildToken
            task.delay(0.45, function()
                if rebuildToken == my and BH.built then
                    rebuildBH()
                end
            end)
        end

        local function gotoSpace()
            if not BH.built then
                startBH()
            end
            task.delay(0.3, function()
                pcall(function()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char:PivotTo(CFrame.new(620, 4470, 0))
                    end
                end)
            end)
        end

        -- ===== واجهة التاب =====
        local tabBH = Window:MakeTab({ Title = "البلاك هول", Icon = "rbxassetid://108953497423608" })
        tabBH:AddSection("البلاك هول الواقعي — Gargantua Edition (v4)")

        tabBH:AddParagraph({
            Title = "🌌 تصميم واقعي 100%",
            Text = "قرص تماسك حجمي متدرج: أبيض ساخن ← ذهبي ← برتقالي محروق + حلقة فوتون نحيفة بتواجه الكاميرا (ظاهرة العدسة) + أفق أسود نقي + Doppler beaming. صفر بنفسجي وصفر حواف قطع ظاهرة.",
        })

        tabBH:AddToggle({
            Title = "تشغيل البلاك هول والفضاء 🕳️",
            Desc = "يبني المشهد الكامل: سما سوداء + صندوق نجوم + البلاك هول الواقعي + الكواكب",
            Default = false,
            Callback = function(v)
                if v then
                    startBH()
                else
                    stopBH()
                end
            end,
        })

        tabBH:AddToggle({
            Title = "الكواكب الواقعية 🪐",
            Desc = "5 كواكب بكرة واحدة ناعمة ومواد حقيقية (حمم / صخر / جليد / غازي / محيط) بتلف حول البلاك هول",
            Default = true,
            Callback = function(v)
                BH.planetsOn = v
                if BH.built then
                    if v then
                        buildPlanets()
                    else
                        destroyPlanets()
                    end
                end
            end,
        })

        tabBH:AddSlider({
            Title = "حجم البلاك هول (x0.5 → x3)",
            Min = 5,
            Max = 30,
            Increase = 5,
            Default = 10,
            Callback = function(v)
                local ns = v / 10
                if ns ~= BH.scale then
                    BH.scale = ns
                    scheduleRebuild()
                end
            end,
        })

        tabBH:AddSlider({
            Title = "سرعة دوران القرص (0 = ساكن)",
            Min = 0,
            Max = 5,
            Increase = 1,
            Default = 2,
            Callback = function(v)
                BH.spin = v * 0.12
            end,
        })

        tabBH:AddToggle({
            Title = "التوهج السينمائي (Bloom)",
            Desc = "Bloom خفيف + ColorCorrection لإحساس سينمائي — يقفل لو اللعبة اتعنت",
            Default = true,
            Callback = function(v)
                BH.glow = v
                if BH.built then
                    if v then
                        applyFX()
                    else
                        removeFX()
                    end
                end
            end,
        })

        tabBH:AddButton({
            Name = "🚀 انتقل لمشاهدة البلاك هول مباشرة",
            Desc = "بيشغل المشهد لو مقفول وينقلك لمنصة المشاهدة",
            Callback = function()
                gotoSpace()
            end,
        })

        tabBH:AddButton({
            Name = "🔁 إعادة بناء المشهد",
            Callback = function()
                if BH.built then
                    rebuildBH()
                else
                    startBH()
                end
            end,
        })

        tabBH:AddButton({
            Name = "🧹 إيقاف ومسح كل حاجة",
            Callback = function()
                stopBH()
            end,
        })
    end
end

-- ===========================================================================
-- [9] تنظيف عام عند إعادة التنفيذ
-- ===========================================================================
if type(getgenv) == "function" then
    pcall(function()
        getgenv().__ElQeyadaHubCleanup = function()
            pcall(function()
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj.Name == "ElQeyada_SpaceScene" then obj:Destroy() end
                end
            end)
            pcall(function()
                for _, n in ipairs({ "BH4_Bloom", "BH4_ColorCorrection" }) do
                    local f = Lighting:FindFirstChild(n)
                    if f then f:Destroy() end
                end
            end)
        end
    end)
end
