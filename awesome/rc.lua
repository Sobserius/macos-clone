-- Meadow — a Linux port of https://github.com/gloceandotdev/dotfiles
-- Window manager: AwesomeWM (replaces yabai + skhd + sketchybar + JankyBorders)

pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- Startup trace: goes to stderr (and therefore to ~/.cache/meadow/session.log
-- when started through bin/awesome-session). If the machine freezes while
-- starting X, the last line in that file shows where it stopped.
local function phase(msg)
    io.stderr:write("meadow: " .. msg .. "\n")
    io.stderr:flush()
end

phase("rc.lua loaded")

local widgets

-- ── Theme ─────────────────────────────────────────────────────────────────────
local meadow = require("theme")
beautiful.init(meadow.palette)

widgets = require("widgets")

phase("theme loaded (" .. meadow.mode .. ")")

local HOME = os.getenv("HOME")
local terminal = os.getenv("TERMINAL") or "ghostty"
local modkey = "Mod4"

local function run(cmd)
    awful.spawn.with_shell(cmd)
end

local function bin(name, args)
    run(HOME .. "/.local/bin/" .. name .. (args and (" " .. args) or ""))
end

-- ── Error handling ────────────────────────────────────────────────────────────
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors,
    })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err),
        })
        in_error = false
    end)
end

-- ── Layouts ───────────────────────────────────────────────────────────────────
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.max,
    awful.layout.suit.floating,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
}

-- ── Notifications ─────────────────────────────────────────────────────────────
naughty.config.defaults.ontop = true
naughty.config.defaults.timeout = 6
naughty.config.defaults.position = "top_right"
naughty.config.defaults.margin = beautiful.notification_margin or 12

-- The request::display signal / naughty.layout.box API only exists in
-- Awesome 4.4+. 4.3 (Tumbleweed, Arch, Debian) draws notifications itself
-- from the beautiful.* notification_* values set in theme/.
if naughty.connect_signal and naughty.layout and naughty.layout.box then
    naughty.connect_signal("request::display", function(n)
        naughty.layout.box({ notification = n })
    end)
end

-- ── Tags ──────────────────────────────────────────────────────────────────────
-- yabai spaces 1..10 -> tags 1..9 and 0
local tag_names = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }

-- ── Buttons ───────────────────────────────────────────────────────────────────
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", { raise = true })
        end
    end),
    awful.button({}, 3, function(c) c:kill() end),
    awful.button({}, 4, function() awful.client.focus.byidx(1) end),
    awful.button({}, 5, function() awful.client.focus.byidx(-1) end)
)

local clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- ── Wibar (Sketchybar equivalent) ─────────────────────────────────────────────
local taglist_template = {
    {
        {
            id = "text_role",
            widget = wibox.widget.textbox,
            align = "center",
            valign = "center",
        },
        left = 10,
        right = 10,
        top = 7,
        bottom = 7,
        widget = wibox.container.margin,
    },
    id = "background_role",
    widget = wibox.container.background,
}

local tasklist_template = {
    {
        {
            id = "text_role",
            widget = wibox.widget.textbox,
            align = "center",
            valign = "center",
        },
        left = 8,
        right = 8,
        top = 2,
        bottom = 2,
        widget = wibox.container.margin,
    },
    id = "background_role",
    widget = wibox.container.background,
}

awful.screen.connect_for_each_screen(function(s)
    awful.tag(tag_names, s, awful.layout.layouts[1])

    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
        spacing = 4,
        widget_template = taglist_template,
    })

    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        widget_template = tasklist_template,
        style = {
            bg_focus = beautiful.tasklist_bg_focus,
            fg_focus = beautiful.tasklist_fg_focus,
            bg_normal = beautiful.tasklist_bg_normal,
            fg_normal = beautiful.tasklist_fg_normal,
            bg_minimize = beautiful.tasklist_bg_minimize,
            fg_minimize = beautiful.tasklist_fg_minimize,
            font = beautiful.tasklist_font,
        },
        layout = {
            spacing = 6,
            layout = wibox.layout.fixed.horizontal,
        },
    })

    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        height = beautiful.bar_height,
        bg = beautiful.bar_bg,
        fg = beautiful.bar_fg,
        border_width = 0,
    })

    local taglist_margin = wibox.container.margin(s.mytaglist, 12, 0, 6, 6)

    local left = wibox.layout.fixed.horizontal()
    left.spacing = 4
    left:add(taglist_margin)

    local middle = wibox.layout.fixed.horizontal()
    middle:add(s.mytasklist)

    local right = wibox.layout.fixed.horizontal()
    right.spacing = 6
    right:add(wibox.container.margin(wibox.widget.systray(), 0, 0, 8, 8))
    right:add(widgets.weather())
    right:add(widgets.battery())
    right:add(widgets.volume())
    right:add(widgets.clock())
    right:add(wibox.container.margin(wibox.widget.textbox(""), 0, 6, 0, 0))

    local bar = wibox.layout.align.horizontal()
    bar:set_first(left)
    bar:set_second(middle)
    bar:set_third(right)
    s.mywibox:set_widget(bar)

    -- Wallpaper (same images as the macOS rice)
    if beautiful.wallpaper and os.getenv("MEADOW_NO_WALLPAPER") ~= "1" then
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    else
        gears.wallpaper.set(beautiful.bg)
    end
end)

phase("wibar + wallpaper ready")

-- ── Key helpers ───────────────────────────────────────────────────────────────
local function focus_screen(idx)
    local s = _G.screen[idx]
    if s then awful.screen.focus(s) end
end

local function move_to_screen(idx)
    local c = client.focus
    local s = _G.screen[idx]
    if not c or not s then return end
    c:move_to_screen(s)
    awful.screen.focus(s)
end

local function move_to_tag(idx)
    local c = client.focus
    if not c then return end
    local t = c.screen.tags[idx]
    if t then
        c:move_to_tag(t)
        awful.tag.viewonly(t)
    end
end

local function adjust_master(delta)
    local t = awful.screen.focused().selected_tag
    if t then awful.tag.incmwfact(delta, t) end
end

local function adjust_nmaster(delta)
    local t = awful.screen.focused().selected_tag
    if t then awful.tag.incnmaster(delta, t) end
end

local function balance()
    local t = awful.screen.focused().selected_tag
    if not t then return end
    awful.tag.incmwfact(0.5 - t.master_width_factor, t)
    awful.tag.incnmaster(1 - t.master_count, t)
end

local function toggle_max()
    local t = awful.screen.focused().selected_tag
    if not t then return end
    if t.layout == awful.layout.suit.max then
        awful.layout.set(awful.layout.suit.tile, t)
    else
        awful.layout.set(awful.layout.suit.max, t)
    end
end

local function toggle_float()
    local c = client.focus
    if not c then return end
    awful.client.floating.toggle(c)
    if awful.client.floating.get(c) then
        awful.placement.centered(c)
    end
end

local function get_scratchpad()
    local found
    for c in awful.client.iterate(function(c) return c.class == "scratchpad" end) do
        found = c
        break
    end
    return found
end

local function toggle_scratchpad()
    local c = get_scratchpad()
    if not c then
        awful.spawn.with_shell(terminal .. " --gtk-single-instance=false --class=scratchpad --title=scratchpad")
        return
    end
    if c.minimized then
        c.minimized = false
        c:emit_signal("request::activate", "scratchpad", { raise = true })
    else
        c.minimized = true
    end
end

local function key(mods, k, fn, desc)
    return awful.key(mods, k, fn, { description = desc, group = "meadow" })
end

-- ── Global keys ───────────────────────────────────────────────────────────────
local globalkeys = gears.table.join(
    -- Applications
    key({ modkey }, "Return", function() awful.spawn(terminal) end, "Terminal (ghostty)"),
    key({ modkey }, "d", function() bin("rofi-launcher", "drun") end, "Application launcher"),
    key({ modkey, "Shift" }, "d", function() bin("rofi-launcher", "run") end, "Run command"),
    key({ modkey }, "Tab", function() bin("rofi-launcher", "window") end, "Window switcher"),
    key({ modkey }, "grave", toggle_scratchpad, "Toggle scratchpad terminal"),

    -- Navigation (yabai: window --focus west/south/north/east)
    key({ modkey }, "h", function() awful.client.focus.bydirection("left") end, "Focus left"),
    key({ modkey }, "j", function() awful.client.focus.bydirection("down") end, "Focus down"),
    key({ modkey }, "k", function() awful.client.focus.bydirection("up") end, "Focus up"),
    key({ modkey }, "l", function() awful.client.focus.bydirection("right") end, "Focus right"),

    -- Moving windows (yabai: window --warp)
    key({ modkey, "Shift" }, "h", function() awful.client.swap.bydirection("left") end, "Move window left"),
    key({ modkey, "Shift" }, "j", function() awful.client.swap.bydirection("down") end, "Move window down"),
    key({ modkey, "Shift" }, "k", function() awful.client.swap.bydirection("up") end, "Move window up"),
    key({ modkey, "Shift" }, "l", function() awful.client.swap.bydirection("right") end, "Move window right"),

    -- Resize (yabai: window --resize)
    key({ modkey }, "u", function() adjust_master(-0.03) end, "Resize left"),
    key({ modkey }, "i", function() adjust_nmaster(1) end, "Resize down"),
    key({ modkey }, "o", function() adjust_nmaster(-1) end, "Resize up"),
    key({ modkey }, "p", function() adjust_master(0.03) end, "Resize right"),

    -- Equalize / rotate / mirror
    key({ modkey }, "e", balance, "Equalize window sizes"),
    key({ modkey }, "r", function() awful.layout.inc(1) end, "Rotate layout"),
    key({ modkey, "Shift" }, "r", function() awful.layout.inc(-1) end, "Rotate layout backwards"),
    key({ modkey }, "x", function() awful.client.swap.byidx(1) end, "Swap with next window"),
    key({ modkey, "Shift" }, "x", function() awful.client.swap.byidx(-1) end, "Swap with previous window"),

    -- Tags (yabai spaces)
    key({ modkey }, "1", function() awful.tag.viewonly(awful.screen.focused().tags[1]) end, "Tag 1"),
    key({ modkey }, "2", function() awful.tag.viewonly(awful.screen.focused().tags[2]) end, "Tag 2"),
    key({ modkey }, "3", function() awful.tag.viewonly(awful.screen.focused().tags[3]) end, "Tag 3"),
    key({ modkey }, "4", function() awful.tag.viewonly(awful.screen.focused().tags[4]) end, "Tag 4"),
    key({ modkey }, "5", function() awful.tag.viewonly(awful.screen.focused().tags[5]) end, "Tag 5"),
    key({ modkey }, "6", function() awful.tag.viewonly(awful.screen.focused().tags[6]) end, "Tag 6"),
    key({ modkey }, "7", function() awful.tag.viewonly(awful.screen.focused().tags[7]) end, "Tag 7"),
    key({ modkey }, "8", function() awful.tag.viewonly(awful.screen.focused().tags[8]) end, "Tag 8"),
    key({ modkey }, "9", function() awful.tag.viewonly(awful.screen.focused().tags[9]) end, "Tag 9"),
    key({ modkey }, "0", function() awful.tag.viewonly(awful.screen.focused().tags[10]) end, "Tag 10"),

    -- Send window to tag and follow
    key({ modkey, "Shift" }, "1", function() move_to_tag(1) end, "Send to tag 1"),
    key({ modkey, "Shift" }, "2", function() move_to_tag(2) end, "Send to tag 2"),
    key({ modkey, "Shift" }, "3", function() move_to_tag(3) end, "Send to tag 3"),
    key({ modkey, "Shift" }, "4", function() move_to_tag(4) end, "Send to tag 4"),
    key({ modkey, "Shift" }, "5", function() move_to_tag(5) end, "Send to tag 5"),
    key({ modkey, "Shift" }, "6", function() move_to_tag(6) end, "Send to tag 6"),
    key({ modkey, "Shift" }, "7", function() move_to_tag(7) end, "Send to tag 7"),
    key({ modkey, "Shift" }, "8", function() move_to_tag(8) end, "Send to tag 8"),
    key({ modkey, "Shift" }, "9", function() move_to_tag(9) end, "Send to tag 9"),
    key({ modkey, "Shift" }, "0", function() move_to_tag(10) end, "Send to tag 10"),

    -- Monitors (yabai display)
    key({ modkey }, "q", function() focus_screen(1) end, "Focus monitor 1"),
    key({ modkey }, "w", function() focus_screen(2) end, "Focus monitor 2"),
    key({ modkey, "Shift" }, "q", function() move_to_screen(1) end, "Move to monitor 1"),
    key({ modkey, "Shift" }, "w", function() move_to_screen(2) end, "Move to monitor 2"),

    -- Window management
    key({ modkey }, "space", toggle_float, "Toggle floating"),
    key({ modkey, "Shift" }, "space", toggle_max, "Toggle maximize"),
    key({ modkey }, "f", function()
        local c = client.focus
        if c then c.fullscreen = not c.fullscreen end
    end, "Toggle fullscreen"),
    key({ modkey, "Shift" }, "f", function()
        local c = client.focus
        if c then c.fullscreen = not c.fullscreen end
    end, "Toggle native fullscreen"),
    key({ modkey, "Shift" }, "c", function()
        local c = client.focus
        if c then c:kill() end
    end, "Close window"),
    key({ modkey, "Control" }, "space", function()
        local c = client.focus
        if c then awful.client.floating.set(c, true); awful.placement.centered(c) end
    end, "Float and center"),

    -- Session / theme
    key({ modkey, "Shift" }, "e", function() bin("power-menu") end, "Power menu"),
    key({ modkey }, "Escape", function() bin("power-menu") end, "Power menu"),
    key({ modkey, "Shift" }, "t", function() bin("switch-theme", "toggle") end, "Toggle light/dark theme"),
    key({ modkey, "Control" }, "r", awesome.restart, "Restart awesome"),
    key({ modkey, "Shift" }, "slash", function()
        hotkeys_popup.show_help(nil, awful.screen.focused())
    end, "Show help"),

    -- Screenshots
    key({ modkey, "Shift" }, "s", function() bin("screenshot", "full") end, "Screenshot (full)"),
    key({ modkey, "Control" }, "s", function() bin("screenshot", "region") end, "Screenshot (region)"),

    -- Media keys
    key({}, "XF86AudioRaiseVolume", function() run("pactl set-sink-volume @DEFAULT_SINK@ +5%") end, "Volume up"),
    key({}, "XF86AudioLowerVolume", function() run("pactl set-sink-volume @DEFAULT_SINK@ -5%") end, "Volume down"),
    key({}, "XF86AudioMute", function() run("pactl set-sink-mute @DEFAULT_SINK@ toggle") end, "Mute"),
    key({}, "XF86AudioPlay", function() run("playerctl play-pause") end, "Play/pause"),
    key({}, "XF86AudioNext", function() run("playerctl next") end, "Next track"),
    key({}, "XF86AudioPrev", function() run("playerctl previous") end, "Previous track"),
    key({}, "XF86MonBrightnessUp", function() run("brightnessctl set +5%") end, "Brightness up"),
    key({}, "XF86MonBrightnessDown", function() run("brightnessctl set 5%-") end, "Brightness down")
)

-- ── Client keys ───────────────────────────────────────────────────────────────
-- Only combos not already bound globally (global grabs fire too, so duplicating
-- them here would run the same action twice).
local clientkeys = gears.table.join(
    key({ modkey }, "m", function(c)
        c.maximized = not c.maximized
        c:raise()
    end, "Maximize")
)

-- Register the global key bindings
root.keys(globalkeys)

-- Desktop: scroll to switch tags
root.buttons(gears.table.join(
    awful.button({}, 4, function() awful.tag.viewnext(awful.screen.focused()) end),
    awful.button({}, 5, function() awful.tag.viewprev(awful.screen.focused()) end)
))

phase("keybindings registered")

-- ── Rules ────────────────────────────────────────────────────────────────────
awful.rules.rules = {
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
        },
    },
    {
        rule_any = {
            instance = { "DTA", "copyq", "pinentry", "scratchpad" },
            class = { "DTA", "copyq", "pinentry", "scratchpad" },
            role = { "AlarmWindow", "ConfigManager", "pop-up" },
            type = { "dialog" },
        },
        properties = { floating = true },
    },
    {
        rule = { class = "scratchpad" },
        properties = { floating = true, sticky = true, ontop = true, border_width = 0 },
        callback = function(c)
            local g = c.screen.geometry
            c:geometry({
                x = g.x + math.floor(g.width * 0.15),
                y = g.y + math.floor(g.height * 0.10),
                width = math.floor(g.width * 0.70),
                height = math.floor(g.height * 0.80),
            })
        end,
    },
    { rule = { class = "Gimp" }, properties = { floating = true } },
    { rule = { class = "mpv" }, properties = { floating = true } },
    { rule = { class = "Pavucontrol" }, properties = { floating = true } },
    { rule = { class = "Nm-connection-editor" }, properties = { floating = true } },
    { rule = { class = "Lxappearance" }, properties = { floating = true } },
    { rule = { class = "Xfce4-power-manager-settings" }, properties = { floating = true } },
    { rule = { class = "Rofi" }, properties = { floating = true, border_width = 0 } },
    { rule = { class = "feh" }, properties = { floating = true } },
}

-- ── Signals ───────────────────────────────────────────────────────────────────
client.connect_signal("manage", function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- yabai: focus_follows_mouse autoraise
client.connect_signal("mouse::enter", function(c)
    if awful.client.focus.filter(c) then
        c:emit_signal("request::activate", "mouse_enter", { raise = true })
    end
end)

-- ── Autostart ────────────────────────────────────────────────────────────────
-- picom (rounded corners, shadows off, ghostty blur). Set MEADOW_NO_PICOM=1
-- to start without a compositor while debugging a GPU/Xorg hang.
if os.getenv("MEADOW_NO_PICOM") ~= "1" then
    run("pgrep -x picom >/dev/null || picom --config " .. HOME .. "/.config/picom/picom.conf >/dev/null 2>&1")
else
    phase("picom disabled (MEADOW_NO_PICOM=1)")
end
-- Keep the mouse cursor theme consistent with the GTK theme
run("command -v xsetroot >/dev/null && xsetroot -cursor_name left_ptr")

phase("startup complete")
