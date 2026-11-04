--=====================================================================
--  EL QEYADA  |  INTRO LOADER  v1.0  --  DELTA / MOBILE READY
--
--  اللودر نفسه مبيعرضش أي حاجة: لا بوكس ولا أنميشن ولا UI --
--  وظيفته الوحيدة: يجيب سكربت الـ VFX الأصلي من GitHub ويشغّله
--  زي ما هو حرفياً بدون أي تعديل. البوكس والإضاءة والأنميشن
--  كلها جاية من سكربت الـ VFX الأصلي نفسه مش من اللودر.
--
--  معلومة (صح انت كده): كله LOCAL على جهازك انت بس --
--  سكربتات الإكزكيوتور بتشتغل على كلاينتك انت بس، فمحدش
--  في السيرفر هيشوف البوكس ولا الأنميشن. مثالي كـ INTRO شخصي.
--
--  Run (Delta / mobile / PC):
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/QEYADA_VFX_Loader.lua"))()
--
--  * re-run at any time: the VFX kills its old show first (never stacks)
--  * Delta autoexec OK: the VFX waits for your character, intro plays on spawn
--  * this loader has ZERO UI: status goes to console only (print / warn)
--
--  stop the show anytime: getgenv().QEYADA_VFX_STOP()
--=====================================================================

local VFX_URL = "https://raw.githubusercontent.com/Alaqrabaty-Soveti/LEGENDS-Intro/main/QEYADA_VFX_Cinematic.lua"
local MARK    = "EL QEYADA"   -- must exist inside the genuine VFX source

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
    warn("[QEYADA LOADER] FAIL: downloaded file is not the EL QEYADA VFX")
    return
end

print("[QEYADA LOADER] source OK (" .. #src .. " chars) - starting intro ...")

local fn, cerr = (loadstring or load)(src, "=QEYADA_VFX_Cinematic")
if type(fn) ~= "function" then
    genv.QEYADA_LOADER_BUSY = false
    warn("[QEYADA LOADER] FAIL: compile error -> " .. tostring(cerr))
    return
end

-- download phase done; the VFX token system itself guards against stacking
genv.QEYADA_LOADER_BUSY = false

local ok, rerr = pcall(fn)
if ok then
    print("[QEYADA LOADER] intro running (your screen only) | stop: getgenv().QEYADA_VFX_STOP()")
else
    warn("[QEYADA LOADER] runtime error -> " .. tostring(rerr))
    warn("[QEYADA LOADER] re-run the loader to try again")
end
