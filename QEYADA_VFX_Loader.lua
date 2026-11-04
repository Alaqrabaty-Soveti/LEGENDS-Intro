--=====================================================================
--  EL QEYADA  |  INTRO LOADER  v1.1  --  DELTA / MOBILE READY
--
--  v1.1: اللودر دلوقتي بيحمّل ملفك انت: KING_AngelAura_VFX.lua
--  (بناء حرفيا 1:1 من "new angel aura reworked.rbxm" الي انت اديهولي)
--  مش السينماتيك بتاعي. الاورا والجنح والسيف والأنميشن كلهم من ملفك.
--
--  اللودر نفسه مبيعرضش أي حاجة: لا بوكس ولا UI --
--  وظيفته الوحيدة: يجيب سكربت الـ VFX من GitHub ويشغّله
--  زي ما هو حرفياً بدون أي تعديل.
--
--  معلومة (صح انت كده): كله LOCAL على جهازك انت بس --
--  مثالي كـ INTRO شخصي، محدش في السيرفر هيشوف حاجة.
--
--  Run (Delta / mobile / PC):
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/QEYADA_VFX_Loader.lua"))()
--
--  * re-run at any time: the VFX kills its old show first (never stacks)
--  * Delta autoexec OK: the VFX waits for your character, intro plays on spawn
--  * this loader has ZERO UI: status goes to console only (print / warn)
--  * لو حصلت مشكلة، الـ VFX نفسه هيكتب الخطأ بالأحمر على الشاشة
--
--  stop the show anytime: getgenv().KING_AURA_STOP()
--=====================================================================

local VFX_URL = "https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/KING_AngelAura_VFX.lua"
local MARK    = "KING AURA"   -- must exist inside the genuine VFX source

local genv = (typeof(getgenv) == "function" and getgenv()) or _G

--[[ re-entry lock: spam-executing won't double-download ---------------- ]]--
if genv.QEYADA_LOADER_BUSY == true then
    warn("[QEYADA LOADER] busy - still fetching, wait a second")
    return
end
genv.QEYADA_LOADER_BUSY = true

--[[ fetch: HttpGet first (Delta native), generic request as fallback ---- ]]--
local function fetch(url)
    local ok, body = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(body) == "string" and #body > 0 then
        return body
    end

    local fn = (typeof(request) == "function" and request)
        or (typeof(http_request) == "function" and http_request)
        or (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request)
    if fn then
        local ok2, res = pcall(function()
            return fn({ Url = url, Method = "GET" })
        end)
        if ok2 and type(res) == "table" and type(res.Body) == "string" then
            return res.Body
        end
        if ok2 and type(res) == "string" then
            return res
        end
    end
    return nil
end

print("[QEYADA LOADER] downloading the VFX script ...")

local src = fetch(VFX_URL)
if type(src) ~= "string" or #src < 500 then
    genv.QEYADA_LOADER_BUSY = false
    warn("[QEYADA LOADER] FAIL: could not download the script (internet / http blocked)")
    return
end

if not string.find(src, MARK, 1, true) then
    genv.QEYADA_LOADER_BUSY = false
    warn("[QEYADA LOADER] FAIL: downloaded file is not the KING aura VFX")
    return
end

print("[QEYADA LOADER] source OK (" .. #src .. " chars) - starting intro ...")

local fn, cerr = (loadstring or load)(src, "=KING_AngelAura_VFX")
if type(fn) ~= "function" then
    genv.QEYADA_LOADER_BUSY = false
    warn("[QEYADA LOADER] FAIL: compile error -> " .. tostring(cerr))
    return
end

-- download phase done; the VFX token system itself guards against stacking
genv.QEYADA_LOADER_BUSY = false

local ok, rerr = pcall(fn)
if ok then
    print("[QEYADA LOADER] intro running (your screen only) | stop: getgenv().KING_AURA_STOP()")
else
    warn("[QEYADA LOADER] runtime error -> " .. tostring(rerr))
    warn("[QEYADA LOADER] re-run the loader to try again")
end
