-- Minimal diagnostic config for Meadow.
--
-- Use it through the session wrapper:
--   MEADOW_MINIMAL=1 MEADOW_NO_PICOM=1 startx
-- or pick the "Awesome (Meadow)" session after setting it in the wrapper.
--
-- It deliberately avoids themes, widgets, picom and the large wallpaper so
-- that a freeze can be attributed to Xorg/GPU instead of the rice config.
-- Set MEADOW_WALLPAPER=/path/to.png to test wallpaper loading by itself.

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

io.stderr:write("minimal: start\n")
io.stderr:flush()

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
}

awful.screen.connect_for_each_screen(function(s)
    awful.tag({ "1", "2", "3", "4", "5" }, s, awful.layout.layouts[1])

    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
    })

    s.mywibox = awful.wibar({ position = "top", screen = s, height = 32 })
    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        { s.mytaglist, widget = wibox.container.margin },
        nil,
        nil,
    })

    local wp = os.getenv("MEADOW_WALLPAPER")
    if wp then
        io.stderr:write("minimal: loading wallpaper " .. wp .. "\n")
        io.stderr:flush()
        gears.wallpaper.maximized(wp, s, true)
    else
        gears.wallpaper.set("#1f1a24")
    end
end)

root.keys(gears.table.join(
    awful.key({ "Mod4" }, "Return", function() awful.spawn("xterm") end,
        { description = "terminal", group = "minimal" }),
    awful.key({ "Mod4", "Shift" }, "q", awesome.quit,
        { description = "quit awesome", group = "minimal" })
))

io.stderr:write("minimal: ready\n")
io.stderr:flush()
