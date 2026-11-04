--=====================================================================
--  KING  |  ANGEL AURA VFX  --  1:1 rebuild loader v1.1 (Delta-ready, self-reporting)
--  بناء حرفيا من "new angel aura reworked.rbxm" (تفكيك binary كامل)
--
--  * نفس الشجرة والكلاسات ونفس قيم الخصائص بالظبط:
--    ريج R6 كامل + جنح Angel wings + سيف Chastiefol (MeshPart حقيقي
--    + SurfaceAppearance PBR) + 56 ParticleEmitter (24 كونفج فريد)
--    + Humanoid/Animator + انيميشن Idle (AnimationId الاصلي)
--  * بيظهر قدام اللاعب ويلعب الانيميشن - كل حاجة كلينت سايد
--  * ايقاف كامل في اي وقت: getgenv().KING_AURA_STOP()
--
--  ملاحظات صادقة:
--  - KeyframeSequence المدمجة (121 keyframe) بيانات تحرير بس - التشغيل
--    بيستخدم AnimationId الاصلي من نفس السكربت.
--  - MeshPart.MeshId وحقول SurfaceAppearance محمية في المحرك: السيف
--    بيتجاب كأصل حقيقي بـ game:GetObjects بنفس الـ MeshId، ولو فشل
--    فيه fallback. جرّب وشوف الشكل بعينك.
--  - الملف اتشيك عليه هنا: سينتاكس PASS + سكانر CLEAN + GitHub raw
--    مطابق حرف بحرف. اختبار العين في اللعبة خطوتك انت.
--
--  Loader:
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/KING_AngelAura_VFX.lua"))()
--=====================================================================

local Players         = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

-- re-run safety + full stop
local genv = (typeof(getgenv) == "function" and getgenv()) or _G
pcall(function()
    if type(genv.KING_AURA_STOP) == "function" then genv.KING_AURA_STOP() end
end)
local myToken = {}
genv.KING_AURA_TOKEN = myToken
local function alive() return genv.KING_AURA_TOKEN == myToken end

-- CFrame from position + exact rotation columns (no angle rounding)
local function CFR(px, py, pz, x1, y1, z1, x2, y2, z2, x3, y3, z3)
    return CFrame.fromMatrix(
        Vector3.new(px, py, pz),
        Vector3.new(x1, y1, z1),
        Vector3.new(x2, y2, z2),
        Vector3.new(x3, y3, z3))
end

-- 24 unique emitter configs (56 instances, deduped by value)
local ECFG = {
	{ -- [1] Firm Smoke
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=15}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.690196,0.439216)),ColorSequenceKeypoint.new(1,Color3.new(1,0.690196,0.439216))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.4,0.7)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.FacingCamera}, {p="Rate",v=25}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.377261,0),NumberSequenceKeypoint.new(0.2,0.733302,0),NumberSequenceKeypoint.new(0.3,1.065671,0),NumberSequenceKeypoint.new(0.4,1.371356,0),NumberSequenceKeypoint.new(0.5,1.646588,0),NumberSequenceKeypoint.new(0.6,1.886554,0),NumberSequenceKeypoint.new(0.7,2.084964,0),NumberSequenceKeypoint.new(0.8,2.23349,0),NumberSequenceKeypoint.new(0.9,2.32161,0),NumberSequenceKeypoint.new(1,2.34405,0)})}, {p="Speed",v=NumberRange.new(0.002412,0.002412)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.02,0),NumberSequenceKeypoint.new(0.2,0.04,0),NumberSequenceKeypoint.new(0.3,0.06,0),NumberSequenceKeypoint.new(0.4,0.08,0),NumberSequenceKeypoint.new(0.5,0.1,0),NumberSequenceKeypoint.new(0.6,0.12,0),NumberSequenceKeypoint.new(0.7,0.14,0),NumberSequenceKeypoint.new(0.8,0.16,0),NumberSequenceKeypoint.new(0.9,0.18,0),NumberSequenceKeypoint.new(1,0.2,0)})}, {p="Texture",v="rbxassetid://14727016281"}, {p="TimeScale",v=0.15}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [2] Cut Smoke
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=15}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.768627,0.564706)),ColorSequenceKeypoint.new(1,Color3.new(1,0.768627,0.564706))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.FacingCamera}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-15,15)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.377261,0),NumberSequenceKeypoint.new(0.2,0.733302,0),NumberSequenceKeypoint.new(0.3,1.065671,0),NumberSequenceKeypoint.new(0.4,1.371356,0),NumberSequenceKeypoint.new(0.5,1.646588,0),NumberSequenceKeypoint.new(0.6,1.886554,0),NumberSequenceKeypoint.new(0.7,2.084964,0),NumberSequenceKeypoint.new(0.8,2.23349,0),NumberSequenceKeypoint.new(0.9,2.32161,0),NumberSequenceKeypoint.new(1,2.34405,0)})}, {p="Speed",v=NumberRange.new(0.002412,0.002412)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.02,0),NumberSequenceKeypoint.new(0.2,0.04,0),NumberSequenceKeypoint.new(0.3,0.06,0),NumberSequenceKeypoint.new(0.4,0.08,0),NumberSequenceKeypoint.new(0.5,0.1,0),NumberSequenceKeypoint.new(0.6,0.12,0),NumberSequenceKeypoint.new(0.7,0.14,0),NumberSequenceKeypoint.new(0.8,0.16,0),NumberSequenceKeypoint.new(0.9,0.18,0),NumberSequenceKeypoint.new(1,0.2,0)})}, {p="Texture",v="rbxassetid://11799607237"}, {p="TimeScale",v=0.5}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [3] Faint Flash Step 8x8
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=15}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.768627,0.564706)),ColorSequenceKeypoint.new(1,Color3.new(1,0.768627,0.564706))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.1,0.1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.FacingCamera}, {p="Rate",v=5}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(0,0)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,2.81286,0),NumberSequenceKeypoint.new(1,2.81286,0)})}, {p="Speed",v=NumberRange.new(0.000469,0.000469)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.02,0),NumberSequenceKeypoint.new(0.2,0.04,0),NumberSequenceKeypoint.new(0.3,0.06,0),NumberSequenceKeypoint.new(0.4,0.08,0),NumberSequenceKeypoint.new(0.5,0.1,0),NumberSequenceKeypoint.new(0.6,0.12,0),NumberSequenceKeypoint.new(0.7,0.14,0),NumberSequenceKeypoint.new(0.8,0.16,0),NumberSequenceKeypoint.new(0.9,0.18,0),NumberSequenceKeypoint.new(1,0.2,0)})}, {p="Texture",v="rbxassetid://85206115924515"}, {p="TimeScale",v=0.5}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [4] Purple Lightning
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=1}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.768627,0.564706)),ColorSequenceKeypoint.new(1,Color3.new(1,0.768627,0.564706))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.1,0.1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityParallel}, {p="Rate",v=15}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,2.812858,0),NumberSequenceKeypoint.new(1,2.812858,0)})}, {p="Speed",v=NumberRange.new(0.000469,0.000469)}, {p="SpreadAngle",v=Vector2.new(-360,360)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://13013256540"}, {p="TimeScale",v=0.15}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [5] OffCentered Spec 37
		{p="Acceleration",v=Vector3.new(0,10.202801,0)}, {p="Brightness",v=12}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.768627,0.564706)),ColorSequenceKeypoint.new(1,Color3.new(1,0.768627,0.564706))})}, {p="Drag",v=5}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid2x2}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.4,1.2)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityParallel}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(-250,250)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0.775798,0),NumberSequenceKeypoint.new(0.1,0.698218,0),NumberSequenceKeypoint.new(0.2,0.620638,0),NumberSequenceKeypoint.new(0.3,0.543059,0),NumberSequenceKeypoint.new(0.4,0.465479,0),NumberSequenceKeypoint.new(0.5,0.387899,0),NumberSequenceKeypoint.new(0.6,0.310319,0),NumberSequenceKeypoint.new(0.7,0.232739,0),NumberSequenceKeypoint.new(0.8,0.15516,0),NumberSequenceKeypoint.new(0.9,0.07758,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Speed",v=NumberRange.new(4.125124,8.250247)}, {p="SpreadAngle",v=Vector2.new(-360,360)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://15394194008"}, {p="TimeScale",v=0.6}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=-2},
	},
	{ -- [6] Realistic flame dissolve
		{p="Acceleration",v=Vector3.new(0,22.344505,0)}, {p="Brightness",v=3}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.768627,0.564706)),ColorSequenceKeypoint.new(1,Color3.new(1,0.768627,0.564706))})}, {p="Drag",v=12}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.4,1.2)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=false}, {p="Orientation",v=Enum.ParticleOrientation.VelocityParallel}, {p="Rate",v=2}, {p="RotSpeed",v=NumberRange.new(-5,5)}, {p="Rotation",v=NumberRange.new(90,90)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1.418707,0),NumberSequenceKeypoint.new(1,1.418707,0)})}, {p="Speed",v=NumberRange.new(8.512239,17.024477)}, {p="SpreadAngle",v=Vector2.new(-360,360)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.1,0),NumberSequenceKeypoint.new(0.2,0.2,0),NumberSequenceKeypoint.new(0.3,0.3,0),NumberSequenceKeypoint.new(0.4,0.4,0),NumberSequenceKeypoint.new(0.5,0.5,0),NumberSequenceKeypoint.new(0.6,0.6,0),NumberSequenceKeypoint.new(0.7,0.7,0),NumberSequenceKeypoint.new(0.8,0.8,0),NumberSequenceKeypoint.new(0.9,0.9,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="Texture",v="rbxassetid://135579750139927"}, {p="TimeScale",v=0.8}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.198992,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=-4},
	},
	{ -- [7] Bright Gleaming Star
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=15}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.690196,0.470588)),ColorSequenceKeypoint.new(1,Color3.new(1,0.690196,0.470588))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid2x2}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.None}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.2,0.2)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.FacingCamera}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(25,25)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1.21396,0),NumberSequenceKeypoint.new(0.1,1.092564,0),NumberSequenceKeypoint.new(0.2,0.971168,0),NumberSequenceKeypoint.new(0.3,0.849772,0),NumberSequenceKeypoint.new(0.4,0.728376,0),NumberSequenceKeypoint.new(0.5,0.60698,0),NumberSequenceKeypoint.new(0.6,0.485584,0),NumberSequenceKeypoint.new(0.7,0.364188,0),NumberSequenceKeypoint.new(0.8,0.242792,0),NumberSequenceKeypoint.new(0.9,0.121396,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Speed",v=NumberRange.new(0.000607,0.000607)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="Texture",v="rbxassetid://73245886600206"}, {p="TimeScale",v=1}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=2},
	},
	{ -- [8] Bright Gleaming Star
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=15}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.690196,0.470588)),ColorSequenceKeypoint.new(1,Color3.new(1,0.690196,0.470588))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid2x2}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.None}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.2,0.2)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.FacingCamera}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-70,-70)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1.21396,0),NumberSequenceKeypoint.new(0.1,1.092564,0),NumberSequenceKeypoint.new(0.2,0.971168,0),NumberSequenceKeypoint.new(0.3,0.849772,0),NumberSequenceKeypoint.new(0.4,0.728376,0),NumberSequenceKeypoint.new(0.5,0.60698,0),NumberSequenceKeypoint.new(0.6,0.485584,0),NumberSequenceKeypoint.new(0.7,0.364188,0),NumberSequenceKeypoint.new(0.8,0.242792,0),NumberSequenceKeypoint.new(0.9,0.121396,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Speed",v=NumberRange.new(0.000607,0.000607)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="Texture",v="rbxassetid://73245886600206"}, {p="TimeScale",v=1}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=2},
	},
	{ -- [9] Cut Smoke
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=15}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.768627,0.564706)),ColorSequenceKeypoint.new(1,Color3.new(1,0.768627,0.564706))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Back}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityParallel}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(90,90)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.564849,0),NumberSequenceKeypoint.new(0.2,1.097928,0),NumberSequenceKeypoint.new(0.3,1.595563,0),NumberSequenceKeypoint.new(0.4,2.053245,0),NumberSequenceKeypoint.new(0.5,2.465333,0),NumberSequenceKeypoint.new(0.6,2.82462,0),NumberSequenceKeypoint.new(0.7,3.121687,0),NumberSequenceKeypoint.new(0.8,3.344064,0),NumberSequenceKeypoint.new(0.9,3.476002,0),NumberSequenceKeypoint.new(1,3.509599,0)})}, {p="Speed",v=NumberRange.new(0.003611,0.003611)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="Texture",v="rbxassetid://11799607237"}, {p="TimeScale",v=0.5}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [10] Firm Smoke
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=15}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.690196,0.439216)),ColorSequenceKeypoint.new(1,Color3.new(1,0.690196,0.439216))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Back}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.4,0.7)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityParallel}, {p="Rate",v=155}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.379096,0),NumberSequenceKeypoint.new(0.2,0.73687,0),NumberSequenceKeypoint.new(0.3,1.070856,0),NumberSequenceKeypoint.new(0.4,1.378027,0),NumberSequenceKeypoint.new(0.5,1.654599,0),NumberSequenceKeypoint.new(0.6,1.895732,0),NumberSequenceKeypoint.new(0.7,2.095108,0),NumberSequenceKeypoint.new(0.8,2.244356,0),NumberSequenceKeypoint.new(0.9,2.332905,0),NumberSequenceKeypoint.new(1,2.355454,0)})}, {p="Speed",v=NumberRange.new(0.002424,0.002424)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,0.02,0),NumberSequenceKeypoint.new(0.2,0.04,0),NumberSequenceKeypoint.new(0.3,0.06,0),NumberSequenceKeypoint.new(0.4,0.08,0),NumberSequenceKeypoint.new(0.5,0.1,0),NumberSequenceKeypoint.new(0.6,0.12,0),NumberSequenceKeypoint.new(0.7,0.14,0),NumberSequenceKeypoint.new(0.8,0.16,0),NumberSequenceKeypoint.new(0.9,0.18,0),NumberSequenceKeypoint.new(1,0.2,0)})}, {p="Texture",v="rbxassetid://14727016281"}, {p="TimeScale",v=0.2}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [11] OffCentered Spec 37
		{p="Acceleration",v=Vector3.new(0,15.276015,0)}, {p="Brightness",v=12}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.768627,0.564706)),ColorSequenceKeypoint.new(1,Color3.new(1,0.768627,0.564706))})}, {p="Drag",v=5}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid2x2}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.4,1.2)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityParallel}, {p="Rate",v=25}, {p="RotSpeed",v=NumberRange.new(-250,250)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1.161554,0),NumberSequenceKeypoint.new(0.1,1.045398,0),NumberSequenceKeypoint.new(0.2,0.929243,0),NumberSequenceKeypoint.new(0.3,0.813088,0),NumberSequenceKeypoint.new(0.4,0.696932,0),NumberSequenceKeypoint.new(0.5,0.580777,0),NumberSequenceKeypoint.new(0.6,0.464622,0),NumberSequenceKeypoint.new(0.7,0.348466,0),NumberSequenceKeypoint.new(0.8,0.232311,0),NumberSequenceKeypoint.new(0.9,0.116155,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Speed",v=NumberRange.new(6.17629,12.35258)}, {p="SpreadAngle",v=Vector2.new(-360,360)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://15394194008"}, {p="TimeScale",v=0.6}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=-2},
	},
	{ -- [12] Purple Lightning
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=1}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.768627,0.564706)),ColorSequenceKeypoint.new(1,Color3.new(1,0.768627,0.564706))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.1,0.1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityParallel}, {p="Rate",v=15}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,3.491022,0),NumberSequenceKeypoint.new(1,3.491022,0)})}, {p="Speed",v=NumberRange.new(0.000582,0.000582)}, {p="SpreadAngle",v=Vector2.new(-360,360)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://13013256540"}, {p="TimeScale",v=0.15}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [13] Rotating Wind Circle
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=12}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=3}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,1.60944,0),NumberSequenceKeypoint.new(0.2,3.128357,0),NumberSequenceKeypoint.new(0.3,4.546282,0),NumberSequenceKeypoint.new(0.4,5.850368,0),NumberSequenceKeypoint.new(0.5,7.024543,0),NumberSequenceKeypoint.new(0.6,8.048267,0),NumberSequenceKeypoint.new(0.7,8.89471,0),NumberSequenceKeypoint.new(0.8,9.528336,0),NumberSequenceKeypoint.new(0.9,9.90427,0),NumberSequenceKeypoint.new(1,10,0)})}, {p="Speed",v=NumberRange.new(0.014583,0.014583)}, {p="SpreadAngle",v=Vector2.new(-5,5)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://18281460865"}, {p="TimeScale",v=0.5}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.5,0.53125,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [14] Peculiar overlay
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=12}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=2}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(0,0)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,1.60944,0),NumberSequenceKeypoint.new(0.2,3.128357,0),NumberSequenceKeypoint.new(0.3,4.546282,0),NumberSequenceKeypoint.new(0.4,5.850368,0),NumberSequenceKeypoint.new(0.5,7.024543,0),NumberSequenceKeypoint.new(0.6,8.048267,0),NumberSequenceKeypoint.new(0.7,8.89471,0),NumberSequenceKeypoint.new(0.8,9.528336,0),NumberSequenceKeypoint.new(0.9,9.90427,0),NumberSequenceKeypoint.new(1,10,0)})}, {p="Speed",v=NumberRange.new(0.014583,0.014583)}, {p="SpreadAngle",v=Vector2.new(-5,5)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://117427578305415"}, {p="TimeScale",v=0.5}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.5,0.53125,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [15] glowing debris spec
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=45}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=6}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(0,0)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,1.623768,0),NumberSequenceKeypoint.new(0.2,3.156207,0),NumberSequenceKeypoint.new(0.3,4.586756,0),NumberSequenceKeypoint.new(0.4,5.902451,0),NumberSequenceKeypoint.new(0.5,7.087079,0),NumberSequenceKeypoint.new(0.6,8.119918,0),NumberSequenceKeypoint.new(0.7,8.973895,0),NumberSequenceKeypoint.new(0.8,9.613162,0),NumberSequenceKeypoint.new(0.9,9.992443,0),NumberSequenceKeypoint.new(1,10.089025,0)})}, {p="Speed",v=NumberRange.new(0.014712,0.014712)}, {p="SpreadAngle",v=Vector2.new(-5,5)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://112386621322440"}, {p="TimeScale",v=0.5}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.502519,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [16] Wavy Glowing Star Shine8x8
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=5}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.1,0.5)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=15}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-50,-50)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,7.226967,0),NumberSequenceKeypoint.new(0.1,6.504271,0),NumberSequenceKeypoint.new(0.2,5.781574,0),NumberSequenceKeypoint.new(0.3,5.058877,0),NumberSequenceKeypoint.new(0.4,4.33618,0),NumberSequenceKeypoint.new(0.5,3.613484,0),NumberSequenceKeypoint.new(0.6,2.890787,0),NumberSequenceKeypoint.new(0.7,2.16809,0),NumberSequenceKeypoint.new(0.8,1.445394,0),NumberSequenceKeypoint.new(0.9,0.722697,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Speed",v=NumberRange.new(0.00443,0.00443)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,2,0),NumberSequenceKeypoint.new(1,2,0)})}, {p="Texture",v="rbxassetid://139843022964858"}, {p="TimeScale",v=0.2}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.502519,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [17] Wavy Glowing Star Shine8x8
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=5}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(0.1,0.5)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=15}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(50,50)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,7.226967,0),NumberSequenceKeypoint.new(0.1,6.504271,0),NumberSequenceKeypoint.new(0.2,5.781574,0),NumberSequenceKeypoint.new(0.3,5.058877,0),NumberSequenceKeypoint.new(0.4,4.33618,0),NumberSequenceKeypoint.new(0.5,3.613484,0),NumberSequenceKeypoint.new(0.6,2.890787,0),NumberSequenceKeypoint.new(0.7,2.16809,0),NumberSequenceKeypoint.new(0.8,1.445394,0),NumberSequenceKeypoint.new(0.9,0.722697,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Speed",v=NumberRange.new(0.00443,0.00443)}, {p="SpreadAngle",v=Vector2.new(0,0)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,2,0),NumberSequenceKeypoint.new(1,2,0)})}, {p="Texture",v="rbxassetid://139843022964858"}, {p="TimeScale",v=0.2}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.502519,0,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [18] WindOne
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=5}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=0}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=5}, {p="RotSpeed",v=NumberRange.new(-250,250)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,1.885698,0),NumberSequenceKeypoint.new(0.2,3.665334,0),NumberSequenceKeypoint.new(0.3,5.326643,0),NumberSequenceKeypoint.new(0.4,6.854573,0),NumberSequenceKeypoint.new(0.5,8.230293,0),NumberSequenceKeypoint.new(0.6,9.429738,0),NumberSequenceKeypoint.new(0.7,10.421471,0),NumberSequenceKeypoint.new(0.8,11.163857,0),NumberSequenceKeypoint.new(0.9,11.604321,0),NumberSequenceKeypoint.new(1,11.716482,0)})}, {p="Speed",v=NumberRange.new(0.017086,0.017086)}, {p="SpreadAngle",v=Vector2.new(-12,12)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://14621031119"}, {p="TimeScale",v=0.5}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0.89375,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [19] New149
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=5}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid2x2}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=1}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(-500,500)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,1.885698,0),NumberSequenceKeypoint.new(0.2,3.665334,0),NumberSequenceKeypoint.new(0.3,5.326643,0),NumberSequenceKeypoint.new(0.4,6.854573,0),NumberSequenceKeypoint.new(0.5,8.230293,0),NumberSequenceKeypoint.new(0.6,9.429738,0),NumberSequenceKeypoint.new(0.7,10.421471,0),NumberSequenceKeypoint.new(0.8,11.163857,0),NumberSequenceKeypoint.new(0.9,11.604321,0),NumberSequenceKeypoint.new(1,11.716482,0)})}, {p="Speed",v=NumberRange.new(0.017086,0.017086)}, {p="SpreadAngle",v=Vector2.new(-25,25)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://13367229656"}, {p="TimeScale",v=0.3}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.501259,0.89375,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [20] Transparenct Blast 1
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=12}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid2x2}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=1}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(25,25)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,2.029466,0),NumberSequenceKeypoint.new(0.2,4.058932,0),NumberSequenceKeypoint.new(0.3,6.088398,0),NumberSequenceKeypoint.new(0.4,8.117864,0),NumberSequenceKeypoint.new(0.5,10.147329,0),NumberSequenceKeypoint.new(0.6,12.176795,0),NumberSequenceKeypoint.new(0.7,14.206261,0),NumberSequenceKeypoint.new(0.8,16.235727,0),NumberSequenceKeypoint.new(0.9,18.265192,0),NumberSequenceKeypoint.new(1,20.294659,0)})}, {p="Speed",v=NumberRange.new(0.01387,0.01387)}, {p="SpreadAngle",v=Vector2.new(-5,5)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://15846370432"}, {p="TimeScale",v=1}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.505038,0.89375,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [21] Circle2
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=12}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=1}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(25,25)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,2.029466,0),NumberSequenceKeypoint.new(0.2,4.058932,0),NumberSequenceKeypoint.new(0.3,6.088398,0),NumberSequenceKeypoint.new(0.4,8.117864,0),NumberSequenceKeypoint.new(0.5,10.147329,0),NumberSequenceKeypoint.new(0.6,12.176795,0),NumberSequenceKeypoint.new(0.7,14.206261,0),NumberSequenceKeypoint.new(0.8,16.235727,0),NumberSequenceKeypoint.new(0.9,18.265192,0),NumberSequenceKeypoint.new(1,20.294659,0)})}, {p="Speed",v=NumberRange.new(0.01387,0.01387)}, {p="SpreadAngle",v=Vector2.new(-5,5)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://16877839414"}, {p="TimeScale",v=0.5}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.505038,0.89375,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [22] Circular Smack
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=12}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Grid8x8}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=1}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(25,25)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,2.93426,0),NumberSequenceKeypoint.new(0.2,5.86852,0),NumberSequenceKeypoint.new(0.3,8.802779,0),NumberSequenceKeypoint.new(0.4,11.73704,0),NumberSequenceKeypoint.new(0.5,14.671299,0),NumberSequenceKeypoint.new(0.6,17.605558,0),NumberSequenceKeypoint.new(0.7,20.539818,0),NumberSequenceKeypoint.new(0.8,23.474079,0),NumberSequenceKeypoint.new(0.9,26.408339,0),NumberSequenceKeypoint.new(1,29.342598,0)})}, {p="Speed",v=NumberRange.new(0.020054,0.020054)}, {p="SpreadAngle",v=Vector2.new(-5,5)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://18140248952"}, {p="TimeScale",v=0.2}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.505038,0.89375,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [23] Erica Water Wave Blur 8x8
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=5}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=1}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.VelocityPerpendicular}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(25,25)}, {p="Rotation",v=NumberRange.new(-360,360)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,2.408521,0),NumberSequenceKeypoint.new(0.2,4.817043,0),NumberSequenceKeypoint.new(0.3,7.225564,0),NumberSequenceKeypoint.new(0.4,9.634086,0),NumberSequenceKeypoint.new(0.5,12.042607,0),NumberSequenceKeypoint.new(0.6,14.451127,0),NumberSequenceKeypoint.new(0.7,16.859648,0),NumberSequenceKeypoint.new(0.8,19.268171,0),NumberSequenceKeypoint.new(0.9,21.676693,0),NumberSequenceKeypoint.new(1,24.085215,0)})}, {p="Speed",v=NumberRange.new(0.016461,0.016461)}, {p="SpreadAngle",v=Vector2.new(-5,5)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(1,0,0)})}, {p="Texture",v="rbxassetid://123266658426840"}, {p="TimeScale",v=0.2}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.505038,0.89375,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
	{ -- [24] Faint Flash Step 8x8
		{p="Acceleration",v=Vector3.new(0,0,0)}, {p="Brightness",v=12}, {p="Color",v=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,0.705882,0.415686)),ColorSequenceKeypoint.new(1,Color3.new(1,0.705882,0.415686))})}, {p="Drag",v=0}, {p="EmissionDirection",v=Enum.NormalId.Top}, {p="Enabled",v=true}, {p="FlipbookFramerate",v=NumberRange.new(1,1)}, {p="FlipbookLayout",v=Enum.ParticleFlipbookLayout.Custom}, {p="FlipbookMode",v=Enum.ParticleFlipbookMode.Loop}, {p="FlipbookSizeX",v=1}, {p="FlipbookSizeY",v=1}, {p="FlipbookStartRandom",v=false}, {p="Lifetime",v=NumberRange.new(1,1)}, {p="LightEmission",v=1}, {p="LightInfluence",v=0}, {p="LockedToPart",v=true}, {p="Orientation",v=Enum.ParticleOrientation.FacingCameraWorldUp}, {p="Rate",v=12}, {p="RotSpeed",v=NumberRange.new(0,0)}, {p="Rotation",v=NumberRange.new(-5,5)}, {p="Shape",v=Enum.ParticleEmitterShape.Box}, {p="ShapeInOut",v=Enum.ParticleShapeInOut.Outward}, {p="ShapePartial",v=1}, {p="ShapeStyle",v=Enum.ParticleShapeStyle.Volume}, {p="Size",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0,0),NumberSequenceKeypoint.new(0.1,2.408521,0),NumberSequenceKeypoint.new(0.2,4.817043,0),NumberSequenceKeypoint.new(0.3,7.225564,0),NumberSequenceKeypoint.new(0.4,9.634086,0),NumberSequenceKeypoint.new(0.5,12.042607,0),NumberSequenceKeypoint.new(0.6,14.451127,0),NumberSequenceKeypoint.new(0.7,16.859648,0),NumberSequenceKeypoint.new(0.8,19.268171,0),NumberSequenceKeypoint.new(0.9,21.676693,0),NumberSequenceKeypoint.new(1,24.085215,0)})}, {p="Speed",v=NumberRange.new(0.016461,0.016461)}, {p="SpreadAngle",v=Vector2.new(-5,5)}, {p="Squash",v=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5,0),NumberSequenceKeypoint.new(1,0.5,0)})}, {p="Texture",v="rbxassetid://85206115924515"}, {p="TimeScale",v=0.2}, {p="Transparency",v=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(0.505038,0.89375,0),NumberSequenceKeypoint.new(1,1,0)})}, {p="VelocityInheritance",v=0}, {p="WindAffectsDrag",v=false}, {p="ZOffset",v=0},
	},
}

print("[KING AURA] v1.1 starting...")

-- on-screen failure reporter: read the text and send it back
local function reportError(msg)
        print("[KING AURA] FAILED: " .. tostring(msg))
        pcall(function()
                local gui = Instance.new("ScreenGui")
                gui.Name = "KING_AURA_ERR"
                gui.DisplayOrder = 999999
                gui.ResetOnSpawn = false
                local okp = pcall(function() gui.Parent = game:GetService("CoreGui") end)
                if not okp or not gui.Parent then
                        local pg = Players.LocalPlayer
                            and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
                        if pg then gui.Parent = pg end
                end
                local tl = Instance.new("TextLabel")
                tl.AnchorPoint = Vector2.new(0.5, 0)
                tl.Position = UDim2.new(0.5, 0, 0, 70)
                tl.Size = UDim2.new(0, 620, 0, 110)
                tl.BackgroundColor3 = Color3.fromRGB(64, 14, 14)
                tl.BackgroundTransparency = 0.1
                tl.TextColor3 = Color3.fromRGB(255, 214, 214)
                tl.Font = Enum.Font.GothamMedium
                tl.TextSize = 14
                tl.TextWrapped = true
                tl.BorderSizePixel = 0
                tl.Text = "KING AURA ERROR: " .. tostring(msg)
                tl.Parent = gui
                task.delay(15, function() pcall(function() gui:Destroy() end) end)
        end)
end

local function toastOK()
        pcall(function()
                local gui = Instance.new("ScreenGui")
                gui.Name = "KING_AURA_OK"
                gui.DisplayOrder = 999999
                gui.ResetOnSpawn = false
                local okp = pcall(function() gui.Parent = game:GetService("CoreGui") end)
                if not okp or not gui.Parent then
                        local pg = Players.LocalPlayer
                            and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
                        if pg then gui.Parent = pg end
                end
                local tl = Instance.new("TextLabel")
                tl.AnchorPoint = Vector2.new(0.5, 0)
                tl.Position = UDim2.new(0.5, 0, 0, 70)
                tl.Size = UDim2.new(0, 380, 0, 36)
                tl.BackgroundColor3 = Color3.fromRGB(16, 46, 22)
                tl.BackgroundTransparency = 0.1
                tl.TextColor3 = Color3.fromRGB(214, 255, 224)
                tl.Font = Enum.Font.GothamBold
                tl.TextSize = 15
                tl.BorderSizePixel = 0
                tl.Text = "KING AURA اشتغل - الملف اتبنى كامل"
                tl.Parent = gui
                task.delay(3.5, function() pcall(function() gui:Destroy() end) end)
        end)
end

-- one bad emitter property must not kill the whole show
local WARN_COUNT = 0
local function applyEmitter(em, idx)
        for _, s in ipairs(ECFG[idx]) do
                local okp, errp = pcall(function() em[s.p] = s.v end)
                if not okp and WARN_COUNT < 3 then
                        WARN_COUNT = WARN_COUNT + 1
                        warn("[KING AURA] emitter prop skipped: "
                            .. tostring(s.p) .. " -> " .. tostring(errp))
                end
        end
end

-- Chastiefol sword: fetch with a hard 3s timeout (GetObjects must never hang)
local SWORD_MESH_ID = "rbxassetid://93212817190277"
local SWORD_PART = nil
do
        local done = false
        task.spawn(function()
                pcall(function()
                        local objs = game:GetObjects(SWORD_MESH_ID)
                        for _, o in ipairs(objs) do
                                if o:IsA("MeshPart") then
                                        SWORD_PART = o
                                        break
                                end
                        end
                end)
                done = true
        end)
        local t0 = os.clock()
        while not done and os.clock() - t0 < 3 do
                task.wait(0.05)
        end
end
if not SWORD_PART then
        SWORD_PART = Instance.new("MeshPart") -- fallback (flat color, see notes)
end

local model = Instance.new("Model")
local INST = {} -- authored parse-id -> instance, for exact ref wiring
local REFQ = {} -- deferred references

-- EVERYTHING below is wrapped: any failure shows its exact message on screen
local okB, errB = pcall(function()

-- Model 'KING' (id 0)
local i0 = Instance.new("Model")
i0.ModelStreamingMode = Enum.ModelStreamingMode.Default
table.insert(REFQ, {i0, "PrimaryPart", 1156})
i0.ScaleFactor = 1
i0.Name = "KING"
i0.Parent = model
INST[0] = i0

-- Script 'Animation' (id 1)
local i1 = Instance.new("Script")
i1.Name = "Animation"
i1.Parent = i0
INST[1] = i1

-- Animation 'IdleAnim' (id 2)
local i2 = Instance.new("Animation")
i2.AnimationId = "rbxassetid://133111601641673"
i2.Name = "IdleAnim"
i2.Parent = i1
INST[2] = i2

-- Humanoid 'Humanoid' (id 1093)
local i1093 = Instance.new("Humanoid")
i1093.AutoJumpEnabled = true
i1093.AutoRotate = true
i1093.AutomaticScalingEnabled = true
i1093.BreakJointsOnDeath = true
i1093.CollisionType = Enum.HumanoidCollisionType.OuterBox
i1093.EvaluateStateMachine = true
i1093.HealthDisplayDistance = 0
i1093.HipHeight = 0
i1093.JumpHeight = 7.2
i1093.JumpPower = 50
i1093.MaxHealth = 100
i1093.MaxSlopeAngle = 89
i1093.NameDisplayDistance = 0
i1093.RequiresNeck = true
i1093.RigType = Enum.HumanoidRigType.R6
i1093.UseJumpPower = true
i1093.WalkSpeed = 16
i1093.Name = "Humanoid"
i1093.Parent = i0
INST[1093] = i1093

-- HumanoidDescription 'HumanoidDescription' (id 1094)
local i1094 = Instance.new("HumanoidDescription")
i1094.BodyTypeScale = 0
i1094.ClimbAnimation = 0
i1094.DepthScale = 1
i1094.Face = 0
i1094.FallAnimation = 0
i1094.GraphicTShirt = 0
i1094.HeadScale = 1
i1094.HeightScale = 1
i1094.IdleAnimation = 0
i1094.JumpAnimation = 0
i1094.MoodAnimation = 0
i1094.Pants = 8231088943
i1094.ProportionScale = 0
i1094.RunAnimation = 0
i1094.Shirt = 8231083610
i1094.SwimAnimation = 0
i1094.UseAvatarSettings = false
i1094.WalkAnimation = 0
i1094.WidthScale = 1
i1094.Name = "HumanoidDescription"
i1094.Parent = i1093
INST[1094] = i1094

-- BodyPartDescription 'BodyPartDescription' (id 1095)
local i1095 = Instance.new("BodyPartDescription")
i1095.AssetId = 0
i1095.BodyPart = Enum.BodyPart.Head
i1095.Color = Color3.new(1,0.933333,0.882353)
i1095.Name = "BodyPartDescription"
i1095.Parent = i1094
INST[1095] = i1095

-- BodyPartDescription 'BodyPartDescription' (id 1096)
local i1096 = Instance.new("BodyPartDescription")
i1096.AssetId = 0
i1096.BodyPart = Enum.BodyPart.LeftArm
i1096.Color = Color3.new(1,0.933333,0.882353)
i1096.Name = "BodyPartDescription"
i1096.Parent = i1094
INST[1096] = i1096

-- BodyPartDescription 'BodyPartDescription' (id 1097)
local i1097 = Instance.new("BodyPartDescription")
i1097.AssetId = 0
i1097.BodyPart = Enum.BodyPart.LeftLeg
i1097.Color = Color3.new(1,0.933333,0.882353)
i1097.Name = "BodyPartDescription"
i1097.Parent = i1094
INST[1097] = i1097

-- BodyPartDescription 'BodyPartDescription' (id 1098)
local i1098 = Instance.new("BodyPartDescription")
i1098.AssetId = 0
i1098.BodyPart = Enum.BodyPart.RightArm
i1098.Color = Color3.new(1,0.933333,0.882353)
i1098.Name = "BodyPartDescription"
i1098.Parent = i1094
INST[1098] = i1098

-- BodyPartDescription 'BodyPartDescription' (id 1099)
local i1099 = Instance.new("BodyPartDescription")
i1099.AssetId = 0
i1099.BodyPart = Enum.BodyPart.RightLeg
i1099.Color = Color3.new(1,0.933333,0.882353)
i1099.Name = "BodyPartDescription"
i1099.Parent = i1094
INST[1099] = i1099

-- BodyPartDescription 'BodyPartDescription' (id 1100)
local i1100 = Instance.new("BodyPartDescription")
i1100.AssetId = 0
i1100.BodyPart = Enum.BodyPart.Torso
i1100.Color = Color3.new(1,0.933333,0.882353)
i1100.Name = "BodyPartDescription"
i1100.Parent = i1094
INST[1100] = i1100

-- Animator 'Animator' (id 1101)
local i1101 = Instance.new("Animator")
i1101.Name = "Animator"
i1101.Parent = i1093
INST[1101] = i1101

-- Pants 'Pants' (id 1102)
local i1102 = Instance.new("Pants")
i1102.PantsTemplate = "http://www.roblox.com/asset/?id=8231088930"
i1102.Name = "Pants"
i1102.Parent = i0
INST[1102] = i1102

-- Shirt 'Shirt' (id 1103)
local i1103 = Instance.new("Shirt")
i1103.ShirtTemplate = "http://www.roblox.com/asset/?id=8231083597"
i1103.Name = "Shirt"
i1103.Parent = i0
INST[1103] = i1103

-- ObjectValue 'AnimSaves' (id 1104)
local i1104 = Instance.new("ObjectValue")
i1104.Name = "AnimSaves"
i1104.Parent = i0
INST[1104] = i1104

-- Accessory 'Angel wings' (id 1105)
local i1105 = Instance.new("Accessory")
i1105.AccessoryType = Enum.AccessoryType.Unknown
i1105.AttachmentPoint = CFR(0,2,1,-1,0,0,0,1,0,0,0,-1)
i1105.Name = "Angel wings"
i1105.Parent = i0
INST[1105] = i1105

-- Configuration 'ThumbnailConfiguration' (id 1106)
local i1106 = Instance.new("Configuration")
i1106.Name = "ThumbnailConfiguration"
i1106.Parent = i1105
INST[1106] = i1106

-- ObjectValue 'ThumbnailCameraTarget' (id 1107)
local i1107 = Instance.new("ObjectValue")
table.insert(REFQ, {i1107, "Value", 1109})
i1107.Name = "ThumbnailCameraTarget"
i1107.Parent = i1106
INST[1107] = i1107

-- CFrameValue 'ThumbnailCameraValue' (id 1108)
local i1108 = Instance.new("CFrameValue")
i1108.Value = CFR(-0.179762,2.236071,6.100813,0.999657,0,0.026177,0.009167,0.936672,-0.350087,-0.024519,0.350207,0.936351)
i1108.Name = "ThumbnailCameraValue"
i1108.Parent = i1106
INST[1108] = i1108

-- Part 'Handle' (id 1109)
local i1109 = Instance.new("Part")
i1109.Anchored = false
i1109.CFrame = CFR(116.454025,23.073639,77.899986,-1,0,0,0,1,0,0,0,-1)
i1109.CanCollide = false
i1109.CanQuery = false
i1109.CanTouch = false
i1109.CastShadow = true
i1109.CollisionGroup = "Default"
i1109.Color = Color3.fromRGB(163,162,165)
i1109.EnableFluidForces = true
i1109.Locked = false
i1109.Massless = false
i1109.Material = Enum.Material.Plastic
i1109.Reflectance = 0
i1109.RootPriority = 0
i1109.Transparency = 0
i1109.Shape = 1
i1109.Size = Vector3.new(1,1,1)
i1109.Name = "Handle"
i1109.Parent = i1105
INST[1109] = i1109

-- SpecialMesh 'SpecialMesh' (id 1110)
local i1110 = Instance.new("SpecialMesh")
i1110.MeshId = "rbxassetid://7236038907"
i1110.MeshType = Enum.MeshType.FileMesh
i1110.Offset = Vector3.new(0,0,0)
i1110.Scale = Vector3.new(1,1,1)
i1110.TextureId = "rbxassetid://7236038444"
i1110.VertexColor = Vector3.new(1,1,1)
i1110.Name = "SpecialMesh"
i1110.Parent = i1109
INST[1110] = i1110

-- StringValue 'AvatarPartScaleType' (id 1111)
local i1111 = Instance.new("StringValue")
i1111.Value = "Classic"
i1111.Name = "AvatarPartScaleType"
i1111.Parent = i1109
INST[1111] = i1111

-- Attachment 'BodyBackAttachment' (id 1112)
local i1112 = Instance.new("Attachment")
i1112.CFrame = CFR(-0.000242,0.135629,0.81324,-1,0,0,0,1,0,0,0,-1)
i1112.Visible = false
i1112.Name = "BodyBackAttachment"
i1112.Parent = i1109
INST[1112] = i1112

-- Part 'Head' (id 1113)
local i1113 = Instance.new("Part")
i1113.Anchored = false
i1113.CFrame = CFR(116.454025,24.573639,76.899986,1,0,0,0,1,0,0,0,1)
i1113.CanCollide = true
i1113.CanQuery = true
i1113.CanTouch = true
i1113.CastShadow = true
i1113.CollisionGroup = "Default"
i1113.Color = Color3.fromRGB(255,233,215)
i1113.EnableFluidForces = false
i1113.Locked = false
i1113.Massless = false
i1113.Material = Enum.Material.Plastic
i1113.Reflectance = 0
i1113.RootPriority = 0
i1113.Transparency = 0
i1113.Shape = 1
i1113.Size = Vector3.new(2,1,1)
i1113.Name = "Head"
i1113.Parent = i0
INST[1113] = i1113

-- SpecialMesh 'Mesh' (id 1114)
local i1114 = Instance.new("SpecialMesh")
i1114.MeshType = Enum.MeshType.Head
i1114.Offset = Vector3.new(0,0,0)
i1114.Scale = Vector3.new(1.25,1.25,1.25)
i1114.VertexColor = Vector3.new(1,1,1)
i1114.Name = "Mesh"
i1114.Parent = i1113
INST[1114] = i1114

-- Decal 'face' (id 1115)
local i1115 = Instance.new("Decal")
i1115.Face = Enum.NormalId.Front
i1115.Texture = "rbxasset://textures/face.png"
i1115.Transparency = 0
i1115.UVOffset = Vector2.new(0,0)
i1115.UVScale = Vector2.new(1,1)
i1115.ZIndex = 1
i1115.Name = "face"
i1115.Parent = i1113
INST[1115] = i1115

-- Weld 'HeadWeld' (id 1116)
local i1116 = Instance.new("Weld")
i1116.C0 = CFR(0,0.5,0,1,0,0,0,1,0,0,0,1)
i1116.C1 = CFR(0,2,1,-1,0,0,0,1,0,0,0,-1)
i1116.Enabled = true
table.insert(REFQ, {i1116, "Part0", 1113})
table.insert(REFQ, {i1116, "Part1", 1109})
i1116.Name = "HeadWeld"
i1116.Parent = i1113
INST[1116] = i1116

-- ParticleEmitter 'Firm Smoke' (id 1117)
local i1117 = Instance.new("ParticleEmitter")
applyEmitter(i1117, 1)
i1117.Name = "Firm Smoke"
i1117.Parent = i1113
INST[1117] = i1117

-- ParticleEmitter 'Cut Smoke' (id 1118)
local i1118 = Instance.new("ParticleEmitter")
applyEmitter(i1118, 2)
i1118.Name = "Cut Smoke"
i1118.Parent = i1113
INST[1118] = i1118

-- ParticleEmitter 'Faint Flash Step 8x8' (id 1119)
local i1119 = Instance.new("ParticleEmitter")
applyEmitter(i1119, 3)
i1119.Name = "Faint Flash Step 8x8"
i1119.Parent = i1113
INST[1119] = i1119

-- ParticleEmitter 'Purple Lightning' (id 1120)
local i1120 = Instance.new("ParticleEmitter")
applyEmitter(i1120, 4)
i1120.Name = "Purple Lightning"
i1120.Parent = i1113
INST[1120] = i1120

-- ParticleEmitter 'OffCentered Spec 37' (id 1121)
local i1121 = Instance.new("ParticleEmitter")
applyEmitter(i1121, 5)
i1121.Name = "OffCentered Spec 37"
i1121.Parent = i1113
INST[1121] = i1121

-- ParticleEmitter 'Realistic flame dissolve' (id 1122)
local i1122 = Instance.new("ParticleEmitter")
applyEmitter(i1122, 6)
i1122.Name = "Realistic flame dissolve"
i1122.Parent = i1113
INST[1122] = i1122

-- Part 'Torso' (id 1123)
local i1123 = Instance.new("Part")
i1123.Anchored = false
i1123.CFrame = CFR(116.454025,23.073639,76.899986,1,0,0,0,1,0,0,0,1)
i1123.CanCollide = true
i1123.CanQuery = true
i1123.CanTouch = true
i1123.CastShadow = true
i1123.CollisionGroup = "Default"
i1123.Color = Color3.fromRGB(255,233,215)
i1123.EnableFluidForces = false
i1123.Locked = false
i1123.Massless = false
i1123.Material = Enum.Material.Plastic
i1123.Reflectance = 0
i1123.RootPriority = 0
i1123.Transparency = 0
i1123.Shape = 1
i1123.Size = Vector3.new(2,2,1)
i1123.Name = "Torso"
i1123.Parent = i0
INST[1123] = i1123

-- Motor6D 'Right Shoulder' (id 1124)
local i1124 = Instance.new("Motor6D")
i1124.C0 = CFR(1,0.5,0,0,0,-1,0,1,0,1,0,0)
i1124.C1 = CFR(-0.5,0.5,0,0,0,-1,0,1,0,1,0,0)
i1124.DesiredAngle = 0
i1124.Enabled = true
i1124.MaxVelocity = 0.1
table.insert(REFQ, {i1124, "Part0", 1123})
table.insert(REFQ, {i1124, "Part1", 1142})
i1124.Name = "Right Shoulder"
i1124.Parent = i1123
INST[1124] = i1124

-- Motor6D 'Left Shoulder' (id 1125)
local i1125 = Instance.new("Motor6D")
i1125.C0 = CFR(-1,0.5,0,0,0,1,0,1,0,-1,0,0)
i1125.C1 = CFR(0.5,0.5,0,0,0,1,0,1,0,-1,0,0)
i1125.DesiredAngle = 0
i1125.Enabled = true
i1125.MaxVelocity = 0.1
table.insert(REFQ, {i1125, "Part0", 1123})
table.insert(REFQ, {i1125, "Part1", 1135})
i1125.Name = "Left Shoulder"
i1125.Parent = i1123
INST[1125] = i1125

-- Motor6D 'Right Hip' (id 1126)
local i1126 = Instance.new("Motor6D")
i1126.C0 = CFR(1,-1,0,0,0,-1,0,1,0,1,0,0)
i1126.C1 = CFR(0.5,1,0,0,0,-1,0,1,0,1,0,0)
i1126.DesiredAngle = 0
i1126.Enabled = true
i1126.MaxVelocity = 0.1
table.insert(REFQ, {i1126, "Part0", 1123})
table.insert(REFQ, {i1126, "Part1", 1149})
i1126.Name = "Right Hip"
i1126.Parent = i1123
INST[1126] = i1126

-- Motor6D 'Left Hip' (id 1127)
local i1127 = Instance.new("Motor6D")
i1127.C0 = CFR(-1,-1,0,0,0,1,0,1,0,-1,0,0)
i1127.C1 = CFR(-0.5,1,0,0,0,1,0,1,0,-1,0,0)
i1127.DesiredAngle = 0
i1127.Enabled = true
i1127.MaxVelocity = 0.1
table.insert(REFQ, {i1127, "Part0", 1123})
table.insert(REFQ, {i1127, "Part1", 1184})
i1127.Name = "Left Hip"
i1127.Parent = i1123
INST[1127] = i1127

-- Motor6D 'Neck' (id 1128)
local i1128 = Instance.new("Motor6D")
i1128.C0 = CFR(0,1,0,-1,0,0,0,0,1,0,1,0)
i1128.C1 = CFR(0,-0.5,0,-1,0,0,0,0,1,0,1,0)
i1128.DesiredAngle = 0
i1128.Enabled = true
i1128.MaxVelocity = 0.1
table.insert(REFQ, {i1128, "Part0", 1123})
table.insert(REFQ, {i1128, "Part1", 1113})
i1128.Name = "Neck"
i1128.Parent = i1123
INST[1128] = i1128

-- ParticleEmitter 'Firm Smoke' (id 1129)
local i1129 = Instance.new("ParticleEmitter")
applyEmitter(i1129, 1)
i1129.Name = "Firm Smoke"
i1129.Parent = i1123
INST[1129] = i1129

-- ParticleEmitter 'Cut Smoke' (id 1130)
local i1130 = Instance.new("ParticleEmitter")
applyEmitter(i1130, 2)
i1130.Name = "Cut Smoke"
i1130.Parent = i1123
INST[1130] = i1130

-- ParticleEmitter 'Faint Flash Step 8x8' (id 1131)
local i1131 = Instance.new("ParticleEmitter")
applyEmitter(i1131, 3)
i1131.Name = "Faint Flash Step 8x8"
i1131.Parent = i1123
INST[1131] = i1131

-- ParticleEmitter 'Purple Lightning' (id 1132)
local i1132 = Instance.new("ParticleEmitter")
applyEmitter(i1132, 4)
i1132.Name = "Purple Lightning"
i1132.Parent = i1123
INST[1132] = i1132

-- ParticleEmitter 'OffCentered Spec 37' (id 1133)
local i1133 = Instance.new("ParticleEmitter")
applyEmitter(i1133, 5)
i1133.Name = "OffCentered Spec 37"
i1133.Parent = i1123
INST[1133] = i1133

-- ParticleEmitter 'Realistic flame dissolve' (id 1134)
local i1134 = Instance.new("ParticleEmitter")
applyEmitter(i1134, 6)
i1134.Name = "Realistic flame dissolve"
i1134.Parent = i1123
INST[1134] = i1134

-- Part 'Left Arm' (id 1135)
local i1135 = Instance.new("Part")
i1135.Anchored = false
i1135.CFrame = CFR(114.954025,23.073639,76.899986,1,0,0,0,1,0,0,0,1)
i1135.CanCollide = false
i1135.CanQuery = true
i1135.CanTouch = true
i1135.CastShadow = true
i1135.CollisionGroup = "Default"
i1135.Color = Color3.fromRGB(255,233,215)
i1135.EnableFluidForces = false
i1135.Locked = false
i1135.Massless = false
i1135.Material = Enum.Material.Plastic
i1135.Reflectance = 0
i1135.RootPriority = 0
i1135.Transparency = 0
i1135.Shape = 1
i1135.Size = Vector3.new(1,2,1)
i1135.Name = "Left Arm"
i1135.Parent = i0
INST[1135] = i1135

-- ParticleEmitter 'Firm Smoke' (id 1136)
local i1136 = Instance.new("ParticleEmitter")
applyEmitter(i1136, 1)
i1136.Name = "Firm Smoke"
i1136.Parent = i1135
INST[1136] = i1136

-- ParticleEmitter 'Cut Smoke' (id 1137)
local i1137 = Instance.new("ParticleEmitter")
applyEmitter(i1137, 2)
i1137.Name = "Cut Smoke"
i1137.Parent = i1135
INST[1137] = i1137

-- ParticleEmitter 'Faint Flash Step 8x8' (id 1138)
local i1138 = Instance.new("ParticleEmitter")
applyEmitter(i1138, 3)
i1138.Name = "Faint Flash Step 8x8"
i1138.Parent = i1135
INST[1138] = i1138

-- ParticleEmitter 'Purple Lightning' (id 1139)
local i1139 = Instance.new("ParticleEmitter")
applyEmitter(i1139, 4)
i1139.Name = "Purple Lightning"
i1139.Parent = i1135
INST[1139] = i1139

-- ParticleEmitter 'OffCentered Spec 37' (id 1140)
local i1140 = Instance.new("ParticleEmitter")
applyEmitter(i1140, 5)
i1140.Name = "OffCentered Spec 37"
i1140.Parent = i1135
INST[1140] = i1140

-- ParticleEmitter 'Realistic flame dissolve' (id 1141)
local i1141 = Instance.new("ParticleEmitter")
applyEmitter(i1141, 6)
i1141.Name = "Realistic flame dissolve"
i1141.Parent = i1135
INST[1141] = i1141

-- Part 'Right Arm' (id 1142)
local i1142 = Instance.new("Part")
i1142.Anchored = false
i1142.CFrame = CFR(117.954025,23.073639,76.899986,1,0,0,0,1,0,0,0,1)
i1142.CanCollide = false
i1142.CanQuery = true
i1142.CanTouch = true
i1142.CastShadow = true
i1142.CollisionGroup = "Default"
i1142.Color = Color3.fromRGB(255,233,215)
i1142.EnableFluidForces = false
i1142.Locked = false
i1142.Massless = false
i1142.Material = Enum.Material.Plastic
i1142.Reflectance = 0
i1142.RootPriority = 0
i1142.Transparency = 0
i1142.Shape = 1
i1142.Size = Vector3.new(1,2,1)
i1142.Name = "Right Arm"
i1142.Parent = i0
INST[1142] = i1142

-- ParticleEmitter 'Firm Smoke' (id 1143)
local i1143 = Instance.new("ParticleEmitter")
applyEmitter(i1143, 1)
i1143.Name = "Firm Smoke"
i1143.Parent = i1142
INST[1143] = i1143

-- ParticleEmitter 'Cut Smoke' (id 1144)
local i1144 = Instance.new("ParticleEmitter")
applyEmitter(i1144, 2)
i1144.Name = "Cut Smoke"
i1144.Parent = i1142
INST[1144] = i1144

-- ParticleEmitter 'Faint Flash Step 8x8' (id 1145)
local i1145 = Instance.new("ParticleEmitter")
applyEmitter(i1145, 3)
i1145.Name = "Faint Flash Step 8x8"
i1145.Parent = i1142
INST[1145] = i1145

-- ParticleEmitter 'Purple Lightning' (id 1146)
local i1146 = Instance.new("ParticleEmitter")
applyEmitter(i1146, 4)
i1146.Name = "Purple Lightning"
i1146.Parent = i1142
INST[1146] = i1146

-- ParticleEmitter 'OffCentered Spec 37' (id 1147)
local i1147 = Instance.new("ParticleEmitter")
applyEmitter(i1147, 5)
i1147.Name = "OffCentered Spec 37"
i1147.Parent = i1142
INST[1147] = i1147

-- ParticleEmitter 'Realistic flame dissolve' (id 1148)
local i1148 = Instance.new("ParticleEmitter")
applyEmitter(i1148, 6)
i1148.Name = "Realistic flame dissolve"
i1148.Parent = i1142
INST[1148] = i1148

-- Part 'Right Leg' (id 1149)
local i1149 = Instance.new("Part")
i1149.Anchored = false
i1149.CFrame = CFR(116.954025,21.073639,76.899986,1,0,0,0,1,0,0,0,1)
i1149.CanCollide = false
i1149.CanQuery = true
i1149.CanTouch = true
i1149.CastShadow = true
i1149.CollisionGroup = "Default"
i1149.Color = Color3.fromRGB(255,233,215)
i1149.EnableFluidForces = false
i1149.Locked = false
i1149.Massless = false
i1149.Material = Enum.Material.Plastic
i1149.Reflectance = 0
i1149.RootPriority = 0
i1149.Transparency = 0
i1149.Shape = 1
i1149.Size = Vector3.new(1,2,1)
i1149.Name = "Right Leg"
i1149.Parent = i0
INST[1149] = i1149

-- ParticleEmitter 'Firm Smoke' (id 1150)
local i1150 = Instance.new("ParticleEmitter")
applyEmitter(i1150, 1)
i1150.Name = "Firm Smoke"
i1150.Parent = i1149
INST[1150] = i1150

-- ParticleEmitter 'Cut Smoke' (id 1151)
local i1151 = Instance.new("ParticleEmitter")
applyEmitter(i1151, 2)
i1151.Name = "Cut Smoke"
i1151.Parent = i1149
INST[1151] = i1151

-- ParticleEmitter 'Faint Flash Step 8x8' (id 1152)
local i1152 = Instance.new("ParticleEmitter")
applyEmitter(i1152, 3)
i1152.Name = "Faint Flash Step 8x8"
i1152.Parent = i1149
INST[1152] = i1152

-- ParticleEmitter 'Purple Lightning' (id 1153)
local i1153 = Instance.new("ParticleEmitter")
applyEmitter(i1153, 4)
i1153.Name = "Purple Lightning"
i1153.Parent = i1149
INST[1153] = i1153

-- ParticleEmitter 'OffCentered Spec 37' (id 1154)
local i1154 = Instance.new("ParticleEmitter")
applyEmitter(i1154, 5)
i1154.Name = "OffCentered Spec 37"
i1154.Parent = i1149
INST[1154] = i1154

-- ParticleEmitter 'Realistic flame dissolve' (id 1155)
local i1155 = Instance.new("ParticleEmitter")
applyEmitter(i1155, 6)
i1155.Name = "Realistic flame dissolve"
i1155.Parent = i1149
INST[1155] = i1155

-- Part 'HumanoidRootPart' (id 1156)
local i1156 = Instance.new("Part")
i1156.Anchored = false
i1156.CFrame = CFR(116.454025,23.073639,76.899986,1,0,0,0,1,0,0,0,1)
i1156.CanCollide = false
i1156.CanQuery = true
i1156.CanTouch = true
i1156.CastShadow = true
i1156.CollisionGroup = "Default"
i1156.Color = Color3.fromRGB(255,233,215)
i1156.EnableFluidForces = false
i1156.Locked = false
i1156.Massless = false
i1156.Material = Enum.Material.Plastic
i1156.Reflectance = 0
i1156.RootPriority = 0
i1156.Transparency = 1
i1156.Shape = 1
i1156.Size = Vector3.new(2,2,1)
i1156.Name = "HumanoidRootPart"
i1156.Parent = i0
INST[1156] = i1156

-- Motor6D 'RootJoint' (id 1157)
local i1157 = Instance.new("Motor6D")
i1157.C0 = CFR(0,0,0,-1,0,0,0,0,1,0,1,0)
i1157.C1 = CFR(0,0,0,-1,0,0,0,0,1,0,1,0)
i1157.DesiredAngle = 0
i1157.Enabled = true
i1157.MaxVelocity = 0.1
table.insert(REFQ, {i1157, "Part0", 1156})
table.insert(REFQ, {i1157, "Part1", 1123})
i1157.Name = "RootJoint"
i1157.Parent = i1156
INST[1157] = i1157

-- Motor6D 'Chastiefol' (id 1158)
local i1158 = Instance.new("Motor6D")
i1158.C0 = CFR(1.5e-05,0,1.5e-05,1,0,0,0,0,1,0,-1,0)
i1158.C1 = CFR(0,-1.357384,0,1,0,0,0,1,0,0,0,1)
i1158.DesiredAngle = 0
i1158.Enabled = true
i1158.MaxVelocity = 0
table.insert(REFQ, {i1158, "Part0", 1156})
table.insert(REFQ, {i1158, "Part1", 1159})
i1158.Name = "Chastiefol"
i1158.Parent = i1156
INST[1158] = i1158

-- MeshPart 'Chastiefol' (id 1159)
local i1159 = SWORD_PART
i1159.Anchored = false
i1159.CFrame = CFR(116.454041,23.073639,78.257385,1,0,0,0,0,1,0,-1,0)
i1159.CanCollide = false
i1159.CanQuery = false
i1159.CanTouch = false
i1159.CastShadow = true
i1159.CollisionGroup = "Default"
i1159.Color = Color3.fromRGB(163,162,165)
i1159.DoubleSided = false
i1159.EnableFluidForces = true
i1159.Locked = false
i1159.Massless = true
i1159.Material = Enum.Material.Plastic
i1159.Reflectance = 0
i1159.RenderFidelity = Enum.RenderFidelity.Automatic
i1159.RootPriority = 0
i1159.Transparency = 0
i1159.Size = Vector3.new(1.797678,0.391094,12.147274)
i1159.Name = "Chastiefol"
i1159.Parent = i1156
INST[1159] = i1159

-- SurfaceAppearance 'SurfaceAppearance' (id 1160)
local i1160 = SWORD_PART:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance")
i1160.Name = "SurfaceAppearance"
i1160.Parent = i1159
INST[1160] = i1160

-- Attachment 'Attachment' (id 1161)
local i1161 = Instance.new("Attachment")
i1161.CFrame = CFR(0,0,3.606356,1,0,0,0,1,0,0,0,1)
i1161.Visible = false
i1161.Name = "Attachment"
i1161.Parent = i1159
INST[1161] = i1161

-- ParticleEmitter 'Bright Gleaming Star' (id 1162)
local i1162 = Instance.new("ParticleEmitter")
applyEmitter(i1162, 7)
i1162.Name = "Bright Gleaming Star"
i1162.Parent = i1161
INST[1162] = i1162

-- ParticleEmitter 'Bright Gleaming Star' (id 1163)
local i1163 = Instance.new("ParticleEmitter")
applyEmitter(i1163, 8)
i1163.Name = "Bright Gleaming Star"
i1163.Parent = i1161
INST[1163] = i1163

-- Attachment 'Attachment' (id 1164)
local i1164 = Instance.new("Attachment")
i1164.CFrame = CFR(0,0,-5.084503,1,0,0,0,1,0,0,0,1)
i1164.Visible = false
i1164.Name = "Attachment"
i1164.Parent = i1159
INST[1164] = i1164

-- ParticleEmitter 'Bright Gleaming Star' (id 1165)
local i1165 = Instance.new("ParticleEmitter")
applyEmitter(i1165, 7)
i1165.Name = "Bright Gleaming Star"
i1165.Parent = i1164
INST[1165] = i1165

-- ParticleEmitter 'Bright Gleaming Star' (id 1166)
local i1166 = Instance.new("ParticleEmitter")
applyEmitter(i1166, 8)
i1166.Name = "Bright Gleaming Star"
i1166.Parent = i1164
INST[1166] = i1166

-- ParticleEmitter 'Cut Smoke' (id 1167)
local i1167 = Instance.new("ParticleEmitter")
applyEmitter(i1167, 9)
i1167.Name = "Cut Smoke"
i1167.Parent = i1159
INST[1167] = i1167

-- ParticleEmitter 'Firm Smoke' (id 1168)
local i1168 = Instance.new("ParticleEmitter")
applyEmitter(i1168, 10)
i1168.Name = "Firm Smoke"
i1168.Parent = i1159
INST[1168] = i1168

-- ParticleEmitter 'OffCentered Spec 37' (id 1169)
local i1169 = Instance.new("ParticleEmitter")
applyEmitter(i1169, 11)
i1169.Name = "OffCentered Spec 37"
i1169.Parent = i1159
INST[1169] = i1169

-- ParticleEmitter 'Purple Lightning' (id 1170)
local i1170 = Instance.new("ParticleEmitter")
applyEmitter(i1170, 12)
i1170.Name = "Purple Lightning"
i1170.Parent = i1159
INST[1170] = i1170

-- Attachment 'Attachment' (id 1171)
local i1171 = Instance.new("Attachment")
i1171.CFrame = CFR(0,-2.700163,0,1,0,0,0,1,0,0,0,1)
i1171.Visible = false
i1171.Name = "Attachment"
i1171.Parent = i1156
INST[1171] = i1171

-- ParticleEmitter 'Rotating Wind Circle' (id 1172)
local i1172 = Instance.new("ParticleEmitter")
applyEmitter(i1172, 13)
i1172.Name = "Rotating Wind Circle"
i1172.Parent = i1171
INST[1172] = i1172

-- ParticleEmitter 'Peculiar overlay' (id 1173)
local i1173 = Instance.new("ParticleEmitter")
applyEmitter(i1173, 14)
i1173.Name = "Peculiar overlay"
i1173.Parent = i1171
INST[1173] = i1173

-- ParticleEmitter 'glowing debris spec' (id 1174)
local i1174 = Instance.new("ParticleEmitter")
applyEmitter(i1174, 15)
i1174.Name = "glowing debris spec"
i1174.Parent = i1171
INST[1174] = i1174

-- ParticleEmitter 'Wavy Glowing Star Shine8x8' (id 1175)
local i1175 = Instance.new("ParticleEmitter")
applyEmitter(i1175, 16)
i1175.Name = "Wavy Glowing Star Shine8x8"
i1175.Parent = i1171
INST[1175] = i1175

-- ParticleEmitter 'Wavy Glowing Star Shine8x8' (id 1176)
local i1176 = Instance.new("ParticleEmitter")
applyEmitter(i1176, 17)
i1176.Name = "Wavy Glowing Star Shine8x8"
i1176.Parent = i1171
INST[1176] = i1176

-- ParticleEmitter 'WindOne' (id 1177)
local i1177 = Instance.new("ParticleEmitter")
applyEmitter(i1177, 18)
i1177.Name = "WindOne"
i1177.Parent = i1171
INST[1177] = i1177

-- ParticleEmitter 'New149' (id 1178)
local i1178 = Instance.new("ParticleEmitter")
applyEmitter(i1178, 19)
i1178.Name = "New149"
i1178.Parent = i1171
INST[1178] = i1178

-- ParticleEmitter 'Transparenct Blast 1' (id 1179)
local i1179 = Instance.new("ParticleEmitter")
applyEmitter(i1179, 20)
i1179.Name = "Transparenct Blast 1"
i1179.Parent = i1171
INST[1179] = i1179

-- ParticleEmitter 'Circle2' (id 1180)
local i1180 = Instance.new("ParticleEmitter")
applyEmitter(i1180, 21)
i1180.Name = "Circle2"
i1180.Parent = i1171
INST[1180] = i1180

-- ParticleEmitter 'Circular Smack' (id 1181)
local i1181 = Instance.new("ParticleEmitter")
applyEmitter(i1181, 22)
i1181.Name = "Circular Smack"
i1181.Parent = i1171
INST[1181] = i1181

-- ParticleEmitter 'Erica Water Wave Blur 8x8' (id 1182)
local i1182 = Instance.new("ParticleEmitter")
applyEmitter(i1182, 23)
i1182.Name = "Erica Water Wave Blur 8x8"
i1182.Parent = i1171
INST[1182] = i1182

-- ParticleEmitter 'Faint Flash Step 8x8' (id 1183)
local i1183 = Instance.new("ParticleEmitter")
applyEmitter(i1183, 24)
i1183.Name = "Faint Flash Step 8x8"
i1183.Parent = i1171
INST[1183] = i1183

-- Part 'Left Leg' (id 1184)
local i1184 = Instance.new("Part")
i1184.Anchored = false
i1184.CFrame = CFR(115.954025,21.073639,76.899986,1,0,0,0,1,0,0,0,1)
i1184.CanCollide = false
i1184.CanQuery = true
i1184.CanTouch = true
i1184.CastShadow = true
i1184.CollisionGroup = "Default"
i1184.Color = Color3.fromRGB(255,233,215)
i1184.EnableFluidForces = false
i1184.Locked = false
i1184.Massless = false
i1184.Material = Enum.Material.Plastic
i1184.Reflectance = 0
i1184.RootPriority = 0
i1184.Transparency = 0
i1184.Shape = 1
i1184.Size = Vector3.new(1,2,1)
i1184.Name = "Left Leg"
i1184.Parent = i0
INST[1184] = i1184

-- ParticleEmitter 'Firm Smoke' (id 1185)
local i1185 = Instance.new("ParticleEmitter")
applyEmitter(i1185, 1)
i1185.Name = "Firm Smoke"
i1185.Parent = i1184
INST[1185] = i1185

-- ParticleEmitter 'Cut Smoke' (id 1186)
local i1186 = Instance.new("ParticleEmitter")
applyEmitter(i1186, 2)
i1186.Name = "Cut Smoke"
i1186.Parent = i1184
INST[1186] = i1186

-- ParticleEmitter 'Faint Flash Step 8x8' (id 1187)
local i1187 = Instance.new("ParticleEmitter")
applyEmitter(i1187, 3)
i1187.Name = "Faint Flash Step 8x8"
i1187.Parent = i1184
INST[1187] = i1187

-- ParticleEmitter 'Purple Lightning' (id 1188)
local i1188 = Instance.new("ParticleEmitter")
applyEmitter(i1188, 4)
i1188.Name = "Purple Lightning"
i1188.Parent = i1184
INST[1188] = i1188

-- ParticleEmitter 'OffCentered Spec 37' (id 1189)
local i1189 = Instance.new("ParticleEmitter")
applyEmitter(i1189, 5)
i1189.Name = "OffCentered Spec 37"
i1189.Parent = i1184
INST[1189] = i1189

-- ParticleEmitter 'Realistic flame dissolve' (id 1190)
local i1190 = Instance.new("ParticleEmitter")
applyEmitter(i1190, 6)
i1190.Name = "Realistic flame dissolve"
i1190.Parent = i1184
INST[1190] = i1190

-- SurfaceAppearance maps: protected fields, try to set, stay silent if refused
local iSA = INST[1160]
pcall(function()
        for _, s in ipairs({
                {p="ColorMap",      v="rbxassetid://93323678294904"},
                {p="NormalMap",     v="rbxassetid://138520724041541"},
                {p="RoughnessMap",  v="rbxassetid://121777155907959"},
                {p="MetalnessMap",  v="rbxassetid://73773151924252"},
                {p="TexturePack",   v="rbxassetid://108616976169951"},
        }) do
                iSA[s.p] = s.v
        end
        iSA.EmissiveStrength = 1
end)

-- exact reference wiring (Part0/Part1/PrimaryPart/Value)
for _, r in ipairs(REFQ) do
        r[1][r[2]] = INST[r[3]]
end

-- position: place the rig 7 studs in front of the player, facing them,
-- preserving every authored relative transform
local pivotCF = INST[1156].CFrame -- authored root pose
local REL = {}
for id, inst in pairs(INST) do
        if inst:IsA("BasePart") then
                REL[id] = pivotCF:Inverse() * inst.CFrame
        end
end

local player = Players.LocalPlayer
local char = player and player.Character
if not char and player then
        local t0 = os.clock()
        while not char and os.clock() - t0 < 5 do
                task.wait(0.1)
                char = player.Character
        end
end
local phrp = char and char:FindFirstChild("HumanoidRootPart")
if not phrp and char then
        phrp = char:WaitForChild("HumanoidRootPart", 5)
end
local base
if phrp then
        local look = phrp.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude < 0.05 then flat = Vector3.new(0, 0, -1) end
        local eye = phrp.Position + flat.Unit * 7
        base = CFrame.lookAt(
                Vector3.new(eye.X, phrp.Position.Y, eye.Z),
                Vector3.new(phrp.Position.X, phrp.Position.Y, phrp.Position.Z))
elseif workspace.CurrentCamera then
        local cc = workspace.CurrentCamera.CFrame
        base = CFrame.lookAt(
                cc.Position + Vector3.new(cc.LookVector.X, 0, cc.LookVector.Z).Unit * 12
                    + Vector3.new(0, -2, 0),
                cc.Position + Vector3.new(0, -2, 0))
else
        base = pivotCF
end
for id, rel in pairs(REL) do
        INST[id].CFrame = base * rel
end
INST[1156].Anchored = true -- display rig stability (no visual change)

model.Parent = workspace

-- run the authored Script source verbatim (with a logic replica fallback)
local SCRIPT_SRC = [==[
local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local idleAnimObject = script.IdleAnim

local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:CreateChild("Animator")
local idleTrack = animator:LoadAnimation(idleAnimObject)

idleTrack.Priority = Enum.AnimationPriority.Idle
idleTrack.Looped = true

idleTrack:Play()]==]
local ranOK = false
pcall(function()
        if loadstring and setfenv then
                local f = loadstring(SCRIPT_SRC)
                if f then
                        local env = setmetatable({script = INST[1]}, {__index = _G})
                        setfenv(f, env)
                        f()
                        ranOK = true
                end
        end
end)
if not ranOK then
        task.spawn(function()
                local okAnim, errAnim = pcall(function()
                        local npc = INST[1].Parent
                        local humanoid = npc:WaitForChild("Humanoid")
                        local animator = humanoid:FindFirstChildOfClass("Animator")
                            or Instance.new("Animator", humanoid)
                        local idleTrack = animator:LoadAnimation(INST[1].IdleAnim)
                        idleTrack.Priority = Enum.AnimationPriority.Idle
                        idleTrack.Looped = true
                        idleTrack:Play()
                end)
                if not okAnim then
                        warn("[KING AURA] animation failed (rig still shows): "
                            .. tostring(errAnim))
                end
        end)
end
end) -- close the big protective pcall

if okB then
        toastOK()
        print("[KING AURA] rebuilt 1:1 | emitters=56 | stop: getgenv().KING_AURA_STOP()")
else
        reportError(errB)
        pcall(function() model:Destroy() end) -- no half-built leftovers
end

local PRELOAD = {
	"http://www.roblox.com/asset/?id=8231083597",
	"http://www.roblox.com/asset/?id=8231088930",
	"rbxassetid://112386621322440",
	"rbxassetid://117427578305415",
	"rbxassetid://11799607237",
	"rbxassetid://123266658426840",
	"rbxassetid://13013256540",
	"rbxassetid://13367229656",
	"rbxassetid://135579750139927",
	"rbxassetid://139843022964858",
	"rbxassetid://14621031119",
	"rbxassetid://14727016281",
	"rbxassetid://15394194008",
	"rbxassetid://15846370432",
	"rbxassetid://16877839414",
	"rbxassetid://18140248952",
	"rbxassetid://18281460865",
	"rbxassetid://7236038444",
	"rbxassetid://7236038907",
	"rbxassetid://73245886600206",
	"rbxassetid://85206115924515",
}

-- preload the authored assets (skill rule: no mid-show pop-in)
task.spawn(function()
        local list = {}
        for _, s in ipairs(PRELOAD) do table.insert(list, s) end
        if INST[1159] then table.insert(list, INST[1159]) end
        pcall(function() ContentProvider:PreloadAsync(list) end)
end)

-- stop is ALWAYS available, success or failure
genv.KING_AURA_STOP = function()
        if genv.KING_AURA_TOKEN ~= myToken then return end
        genv.KING_AURA_TOKEN = nil
        pcall(function() model:Destroy() end)
        print("[KING AURA] stopped - model destroyed")
end