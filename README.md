# LEGENDS — Sky Splitter Intro (VFX Studio v2)

انترو سينمائي متقدم لروبلوكس — ستايل Bleach Quincy (أبيض × فضي) — 62 ثانية، 8 مراحل.

## المميزات
- 🗡️ سيف ملكي كامل (blade + fuller نيون + runeRing + Trail + Aura)
- 🐉 تنين ناري إجرائي بسلاسل Motor6D (رقبة + جناحين + ذيل + فك يفتح) + shatter explosion
- 🎬 كاميرا Director: 14 قطعة كاميرا + FOV breathing + Dutch roll + shake بـ math.noise + freeze frames
- ✨ PostFX: ColorCorrection + Bloom + DepthBlur + Atmosphere (كله بأسماء LEGENDS_* ويترجع لأصله بعد الانتها)
- 🎭 13 وضعية أنيميشن إجرائية (Motor6D.Transform) + طبقة حية (تنفس + رجفة + ميلان) — يدعم R15 و R6
- ⚡ شق السماء: لوح Glass 110×170 + god rays + lightning strobe
- 🌌 الفضاء: 130 نجمة + 7 سديم + كوكب بحلقة
- 🖥️ UI: Letterbox سينمائي + Vignette + عنوان LEGENDS + زر Skip + Debug Overlay اختياري
- 🛡️ حماية: pcall على كل مرحلة + حفظ/استعادة الكاميرا والإضاءة والـ Character

## التركيب
1. افتح لعبتك في Roblox Studio
2. في Explorer: `StarterPlayer` → `StarterPlayerScripts` (أو StarterGui)
3. اعمل `LocalScript` جديد وسمّيه `LEGENDS_Intro`
4. الصق محتوى `LEGENDS_Intro_VFX_Studio_v2.lua` كله جواه
5. اضغط Play — خلاص 🎬

## التحكم السريع (أول ~40 سطر في CONFIG)
| الإعداد | الوظيفة |
|---|---|
| `INTRO_DURATION` | طول الانترو بالثواني (الافتراضي 62) |
| `SHOW_PHASE_NAMES` | إظهار اسم المرحلة على الشاشة |
| `ENABLE_DEBUG_OVERLAY` | عداد أخطاء مباشر أثناء التجربة |

## GitHub — إزاي ترفعه على حسابك
1. اعمل حساب على github.com (لو معندكش) واعمل **New repository** سمّيه `LEGENDS-Intro`
2. اضغط **uploading an existing file** وارفع ملف `LEGENDS_Intro_VFX_Studio_v2.lua` + الـ README
3. اضغط **Commit changes** — خلص

أو لو عايز الطريقة الاحترافية:
```bash
git clone https://github.com/اسمك/LEGENDS-Intro.git
cd LEGENDS-Intro
# انسخ الملف هنا
git add .
git commit -m "LEGENDS Intro VFX Studio v2"
git push
```

## الرابط الاحتياطي (Pastefy/DPaste)
https://dpaste.org/ErcNZ
