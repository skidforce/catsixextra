-- catsixextra loader (public GitHub repo)
-- 1) Paste this whole script into your executor and run it.
-- 2) Files are fetched from raw.githubusercontent.com (no auth needed).
--    Falls back to the GitHub contents API if raw fails.

local REPO = "skidforce/catsixextra"
local BRANCH = "main"

local license = ... or {}
license.Key = script_key or license.Key or '_key'

local httpService = game:GetService("HttpService")
local requestFn = request or http_request or (syn and syn.request)

local function urlenc(s)
    return (s:gsub("([^%w%.%-%~_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function encseg(s)
    return (s:gsub("([^/]+)", urlenc))
end

local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function b64dec(s)
    s = s:gsub('%s+', '')
    local out = {}
    local pad = 0
    for i = 1, #s, 4 do
        local n = 0
        for j = 0, 3 do
            local c = s:sub(i + j, i + j)
            if c == '' or c == '=' then
                pad = pad + 1
                n = n * 64
            else
                n = n * 64 + (B64:find(c, 1, true) - 1)
            end
        end
        out[#out + 1] = string.char(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
    end
    local data = table.concat(out)
    if pad > 0 then
        data = data:sub(1, #data - pad)
    end
    return data
end

local function decodeGit(res)
    if res:sub(1, 1) ~= '{' then
        return res
    end
    local ok, data = pcall(function()
        local j = httpService:JSONDecode(res)
        if type(j) == 'table' and j.encoding == 'base64' and type(j.content) == 'string' then
            return b64dec(j.content)
        end
        return res
    end)
    return ok and data or res
end

local function fetch(url)
    if requestFn then
        local ok, resp = pcall(requestFn, {
            Url = url,
            Method = "GET",
        })
        if ok and resp and resp.StatusCode == 200 and resp.Body then
            return true, resp.Body
        end
        return false, resp and tostring(resp.StatusCode) or "no response"
    end
    return pcall(function()
        return game:HttpGetAsync(url, false)
    end)
end

local RAW = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/"
local API = "https://api.github.com/repos/" .. REPO .. "/contents/"

local files = {
    "features.json",
    "init.lua",
    "main.lua",
    "packages.json",
    "libraries/cheatengine.lua",
    "libraries/drawing.lua",
    "libraries/entity.lua",
    "libraries/hash.lua",
    "libraries/prediction.lua",
    "libraries/premium.lua",
    "libraries/vm.lua",
    "guis/liquidbounce.lua",
    "guis/new.lua",
    "guis/old.lua",
    "guis/rise.lua",
    "guis/wurst.lua",
    "games/77790193039862.lua",
    "games/80041634734121.lua",
"games/6872265039.lua",
    "games/6872274481.lua",
    "games/106431012459431.lua",
    "games/16483433878.lua",
    "games/893973440.lua",
    "games/5938036553.lua",
    "games/123804558118054.lua",
    "games/131465939650733.lua",
    "games/83413351472244.lua",
    "games/135564683255158.lua",
    "games/155615604.lua",
    "games/115875349872417.lua",
    "games/126691165749976.lua",
    "games/94987506187454.lua",
    "games/13246639586.lua",
    "games/8542259458.lua",
    "games/8542275097.lua",
    "games/8592115909.lua",
    "games/8768229691.lua",
    "games/8951451142.lua",
    "games/universal.lua",
    "games/606849621.lua",
    "games/132768098780837.lua",
    "games/139566161526375.lua",

"assets/liquidbounce/Inter-Light.ttf",
    "assets/liquidbounce/Inter-Medium.ttf",
    "assets/liquidbounce/Inter-Regular.ttf",
    "assets/liquidbounce/logo.png",
    "assets/liquidbounce/textgui.png",
    "assets/new/add.png",
    "assets/new/alert.png",
    "assets/new/alertlarge.png",
    "assets/new/allowedicon.png",
    "assets/new/allowedtab.png",
    "assets/new/arrowmodule.png",
    "assets/new/back.png",
    "assets/new/bind.png",
    "assets/new/bindbkg.png",
    "assets/new/blatanticon.png",
    "assets/new/blockedicon.png",
    "assets/new/blockedtab.png",
    "assets/new/blur.png",
    "assets/new/blurnotif.png",
    "assets/new/close.png",
    "assets/new/closemini.png",
    "assets/new/colorpreview.png",
    "assets/new/combaticon.png",
    "assets/new/customsettings.png",
    "assets/new/discord.png",
    "assets/new/dislike.png",
    "assets/new/dots.png",
    "assets/new/edit.png",
    "assets/new/expandicon.png",
    "assets/new/expandright.png",
    "assets/new/expandup.png",
    "assets/new/favoritesicon.png",
    "assets/new/friendstab.png",
    "assets/new/guisettings.png",
    "assets/new/guislider.png",
    "assets/new/guisliderrain.png",
    "assets/new/guiv4.png",
    "assets/new/guivape.png",
    "assets/new/hide.png",
    "assets/new/info.png",
    "assets/new/inventoryicon.png",
    "assets/new/legit.png",
    "assets/new/legittab.png",
    "assets/new/like.png",
    "assets/new/miniicon.png",
    "assets/new/newpublicprofiles.png",
    "assets/new/notification.png",
    "assets/new/onlineicon.png",
    "assets/new/overlaysicon.png",
    "assets/new/overlaystab.png",
    "assets/new/pin.png",
    "assets/new/profilesicon.png",
    "assets/new/profileworld.png",
    "assets/new/proxima.ttf",
    "assets/new/proximabd.ttf",
    "assets/new/radaricon.png",
    "assets/new/rainbow_1.png",
    "assets/new/rainbow_2.png",
    "assets/new/rainbow_3.png",
    "assets/new/rainbow_4.png",
    "assets/new/range.png",
    "assets/new/rangearrow.png",
    "assets/new/rendericon.png",
    "assets/new/rendertab.png",
    "assets/new/search.png",
    "assets/new/show.png",
    "assets/new/star.png",
    "assets/new/targetinfoicon.png",
    "assets/new/targetnpc1.png",
    "assets/new/targetnpc2.png",
    "assets/new/targetplayers1.png",
    "assets/new/targetplayers2.png",
    "assets/new/targetstab.png",
    "assets/new/textguiicon.png",
    "assets/new/textv4.png",
    "assets/new/textvape.png",
    "assets/new/utilityicon.png",
    "assets/new/vape.png",
    "assets/new/warning.png",
    "assets/new/worldicon.png",
    "assets/old/barlogo.png",
    "assets/old/blatanticon.png",
    "assets/old/checkbox.png",
    "assets/old/combaticon.png",
    "assets/old/friendsicon.png",
    "assets/old/guiicon.png",
    "assets/old/info.png",
    "assets/old/pin.png",
    "assets/old/profilesicon.png",
    "assets/old/rendericon.png",
    "assets/old/search.png",
    "assets/old/settingsicon.png",
    "assets/old/targetinfoicon.png",
    "assets/old/textguiicon.png",
    "assets/old/textv4.png",
    "assets/old/textvape.png",
    "assets/old/utilityicon.png",
    "assets/old/worldicon.png",
    "assets/rise/Icon-1.ttf",
    "assets/rise/Icon-3.ttf",
    "assets/rise/SF-Pro-Rounded-Light.otf",
    "assets/rise/SF-Pro-Rounded-Medium.otf",
    "assets/rise/SF-Pro-Rounded-Regular.otf",
    "assets/rise/productsans.json",
    "assets/rise/slice.png",
    "assets/wurst/triangle.png",
    "assets/wurst/wurst_128.png",
}

local downloaded = 0
local failed = {}
local queue = {}
for _, f in ipairs(files) do
    queue[#queue + 1] = f
end

local function worker()
    while true do
        local f = table.remove(queue, 1)
        if not f then break end
        local dir = f:match("^(.*)/[^/]+$")
        if dir and not isfolder("catsixextra/" .. dir) then
            pcall(makefolder, "catsixextra/" .. dir)
        end
        local ok, res = fetch(RAW .. encseg(f))
        if not ok or res:match("^%d+%s*:") then
            ok, res = fetch(API .. encseg(f) .. "?ref=" .. BRANCH)
        end
        if ok and res and not res:match("^%d+%s*:") then
            writefile("catsixextra/" .. f, decodeGit(res))
            downloaded = downloaded + 1
        else
            table.insert(failed, f)
        end
    end
end

local threads = {}
for _ = 1, 8 do
    threads[#threads + 1] = task.spawn(worker)
end
for _, t in ipairs(threads) do
    while task.wait() do
        if coroutine.status(t) == "dead" then break end
    end
end

print(("[catsixextra] downloaded %d/%d files"):format(downloaded, #files))
if #failed > 0 then
    warn("[catsixextra] failed: " .. table.concat(failed, ", "))
end

if isfile("catsixextra/main.lua") then
    local src = readfile("catsixextra/main.lua")
    local f, err = loadstring(src, "main")
    if f then
        xpcall(function()
            f(license)
        end, function(e)
            warn("[catsixextra] main.lua runtime error: " .. tostring(e))
        end)
    else
        warn("[catsixextra] main.lua failed to compile: " .. tostring(err))
        print("[catsixextra] main.lua head: " .. src:sub(1, 200))
    end
else
    warn("[catsixextra] catsixextra/main.lua not found")
end