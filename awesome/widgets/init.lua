-- Bar widgets for the Meadow wibar.
-- Icons are Nerd Font glyphs, encoded from codepoints so the source stays ASCII.
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local M = {}

-- UTF-8 encode a codepoint (LuaJIT has no \u escape).
local function u(cp)
    if cp < 0x80 then
        return string.char(cp)
    elseif cp < 0x800 then
        return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
    elseif cp < 0x10000 then
        return string.char(
            0xE0 + math.floor(cp / 0x1000),
            0x80 + math.floor(cp / 0x40) % 0x40,
            0x80 + cp % 0x40
        )
    end
    return string.char(
        0xF0 + math.floor(cp / 0x40000),
        0x80 + math.floor(cp / 0x1000) % 0x40,
        0x80 + math.floor(cp / 0x40) % 0x40,
        0x80 + cp % 0x40
    )
end

-- Font Awesome glyphs (present in Symbols Nerd Font).
local ICON = {
    cpu = u(0xF2DB),
    mem = u(0xF538),
    vol_high = u(0xF028),
    vol_low = u(0xF027),
    vol_off = u(0xF026),
    bat_full = u(0xF240),
    bat_half = u(0xF242),
    bat_low = u(0xF243),
    bat_empty = u(0xF244),
    bolt = u(0xF0E7),
    clock = u(0xF017),
    cloud = u(0xF0C2),
    thermometer = u(0xF2C9),
}

local function rounded(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, 6)
end

local function textbox()
    local w = wibox.widget.textbox()
    w.font = beautiful.mono_font
    w.align = "center"
    w.valign = "center"
    return w
end

local function pill(child, fg)
    local margin = wibox.container.margin()
    margin:set_widget(child)
    margin:set_left(10)
    margin:set_right(10)
    margin:set_top(4)
    margin:set_bottom(4)

    local bg = wibox.container.background()
    bg:set_widget(margin)
    bg:set_bg(beautiful.widget_bg)
    bg:set_fg(fg or beautiful.widget_fg)
    bg:set_shape(rounded)
    return bg
end

local function colored(color, text)
    return '<span foreground="' .. color .. '">' .. text .. "</span>"
end

-- ── CPU ───────────────────────────────────────────────────────────────────────
local function read_cpu()
    local f = io.open("/proc/stat", "r")
    if not f then return 0, 0 end
    local line = f:read("*l") or ""
    f:close()
    local vals = {}
    for v in line:gmatch("%d+") do vals[#vals + 1] = tonumber(v) end
    local idle = (vals[4] or 0) + (vals[5] or 0)
    local total = 0
    for _, v in ipairs(vals) do total = total + v end
    return total, idle
end

function M.cpu()
    local w = textbox()
    local prev_total, prev_idle
    local function update()
        local total, idle = read_cpu()
        if prev_total then
            local dtotal = total - prev_total
            local didle = idle - prev_idle
            local usage = 0
            if dtotal > 0 then
                usage = math.floor((1 - didle / dtotal) * 100 + 0.5)
            end
            w:set_markup(colored(beautiful.cornflower, ICON.cpu) .. "  " .. usage .. "%")
        end
        prev_total, prev_idle = total, idle
    end
    update()
    gears.timer({ timeout = 2, autostart = true, callback = update })
    w:buttons(gears.table.join(
        awful.button({}, 1, function() awful.spawn.with_shell("ghostty -e btop") end)
    ))
    return pill(w)
end

-- ── Memory ────────────────────────────────────────────────────────────────────
function M.memory()
    local w = textbox()
    local function update()
        local f = io.open("/proc/meminfo", "r")
        if not f then return end
        local info = {}
        for line in f:lines() do
            local k, v = line:match("^(%w+):%s+(%d+)")
            if k then info[k] = tonumber(v) end
        end
        f:close()
        local total = info.MemTotal or 0
        local avail = info.MemAvailable or 0
        local pct = 0
        if total > 0 then pct = math.floor((total - avail) / total * 100 + 0.5) end
        w:set_markup(colored(beautiful.sage, ICON.mem) .. "  " .. pct .. "%")
    end
    update()
    gears.timer({ timeout = 3, autostart = true, callback = update })
    return pill(w)
end

-- ── Volume ────────────────────────────────────────────────────────────────────
function M.volume()
    local w = textbox()
    local function set(out)
        out = out or ""
        local muted = out:find("Mute: yes", 1, true) ~= nil
        local vol = tonumber(out:match("(%d+)%%") or "") or 0
        local icon
        if muted or vol == 0 then
            icon = ICON.vol_off
        elseif vol <= 50 then
            icon = ICON.vol_low
        else
            icon = ICON.vol_high
        end
        local label = muted and "muted" or (vol .. "%")
        w:set_markup(colored(beautiful.marigold, icon) .. "  " .. label)
    end
    local function refresh()
        awful.spawn.easy_async_with_shell(
            "pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null; pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | head -n1",
            function(out) set(out) end
        )
    end
    refresh()
    gears.timer({ timeout = 2, autostart = true, callback = refresh })
    w:buttons(gears.table.join(
        awful.button({}, 1, function() awful.spawn.with_shell("pavucontrol >/dev/null 2>&1") end)
    ))
    return pill(w)
end

-- ── Battery ───────────────────────────────────────────────────────────────────
function M.battery()
    local dir
    for i = 0, 3 do
        local p = "/sys/class/power_supply/BAT" .. i
        local f = io.open(p .. "/capacity", "r")
        if f then
            f:close()
            dir = p
            break
        end
    end
    if not dir then
        return wibox.widget.textbox("")
    end

    local function read(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local v = f:read("*l")
        f:close()
        return v
    end

    local w = textbox()
    local function update()
        local cap = tonumber(read(dir .. "/capacity") or "0") or 0
        local status = read(dir .. "/status") or ""
        local charging = status:find("Charging", 1, true) ~= nil
        local icon
        if charging then
            icon = ICON.bolt
        elseif cap >= 90 then
            icon = ICON.bat_full
        elseif cap >= 50 then
            icon = ICON.bat_half
        elseif cap >= 15 then
            icon = ICON.bat_low
        else
            icon = ICON.bat_empty
        end
        w:set_markup(colored(beautiful.sage, icon) .. "  " .. cap .. "%")
    end
    update()
    gears.timer({ timeout = 15, autostart = true, callback = update })
    return pill(w)
end

-- ── Weather ───────────────────────────────────────────────────────────────────
function M.weather()
    local w = textbox()
    local home = os.getenv("HOME") or ""
    local script = home .. "/.config/awesome/scripts/weather.sh"

    local function display(out)
        local s = (out or ""):gsub("%s+$", "")
        if s == "" then s = ICON.cloud .. "  --" end
        w:set_markup(colored(beautiful.dew, s))
    end

    local function refresh()
        awful.spawn.easy_async_with_shell(script, function(out) display(out) end)
    end
    refresh()
    gears.timer({ timeout = 600, autostart = true, callback = refresh })
    w:buttons(gears.table.join(
        awful.button({}, 1, function() awful.spawn.with_shell("xdg-open 'https://openweathermap.org/' >/dev/null 2>&1") end)
    ))
    return pill(w)
end

-- ── Clock ─────────────────────────────────────────────────────────────────────
function M.clock()
    local w = textbox()
    local function tick()
        w:set_markup(colored(beautiful.poppy, ICON.clock) .. "  " .. os.date("%a %d %b  -  %I:%M %p"))
    end
    tick()
    gears.timer({ timeout = 1, autostart = true, callback = tick })
    return pill(w)
end

return M
