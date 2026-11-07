-- Meadow Light — https://glocean.dev/meadow
local gears = require("gears")

local theme = {}

theme.name = "meadow-light"
theme.mode = "light"

theme.font = "Inter 10"
theme.font_bold = "Inter Bold 10"
theme.mono_font = "JetBrains Mono 10"

theme.bg = "#f7e8ee"
theme.surface = "#efdee4"
theme.surface2 = "#e1ced7"
theme.surface3 = "#e0d7f4"
theme.text = "#382a3d"
theme.muted = "#857284"

theme.lavender = "#715c97"
theme.cornflower = "#4a68a0"
theme.marigold = "#b76316"
theme.dew = "#217584"
theme.sage = "#507357"
theme.poppy = "#b9454c"

theme.bg_normal = theme.bg
theme.bg_focus = theme.surface
theme.bg_urgent = theme.poppy
theme.bg_minimize = theme.surface
theme.bg_systray = theme.surface
theme.fg_normal = theme.text
theme.fg_focus = theme.text
theme.fg_urgent = theme.bg
theme.fg_minimize = theme.muted

theme.border_width = 3
theme.border_normal = theme.surface2
theme.border_focus = theme.lavender
theme.border_marked = theme.poppy

theme.useless_gap = 10
theme.snap_bg = theme.lavender
theme.snap_border_width = 2

theme.bar_bg = theme.surface
theme.bar_fg = theme.text
theme.bar_border = theme.surface2
theme.bar_height = 43
theme.widget_bg = theme.surface2
theme.widget_fg = theme.text

theme.taglist_spacing = 4
theme.taglist_bg_focus = theme.lavender
theme.taglist_fg_focus = theme.surface
theme.taglist_bg_occupied = theme.surface2
theme.taglist_fg_occupied = theme.text
theme.taglist_bg_empty = theme.surface3
theme.taglist_fg_empty = theme.muted
theme.taglist_bg_urgent = theme.poppy
theme.taglist_fg_urgent = theme.bg
theme.taglist_font = theme.font_bold
theme.taglist_shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 6) end
theme.taglist_shape_border_width = 0

theme.tasklist_bg_focus = theme.surface2
theme.tasklist_fg_focus = theme.lavender
theme.tasklist_bg_normal = theme.surface
theme.tasklist_fg_normal = theme.muted
theme.tasklist_bg_minimize = theme.surface
theme.tasklist_fg_minimize = theme.surface2
theme.tasklist_font = theme.font

theme.notification_bg = theme.surface
theme.notification_fg = theme.text
theme.notification_border_color = theme.lavender
theme.notification_border_width = 2
theme.notification_font = theme.font
theme.notification_title_font = theme.font_bold
theme.notification_shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 8) end
theme.notification_max_width = 500
theme.notification_margin = 12
theme.notification_opacity = 1

theme.icon_theme = "Papirus"
theme.wallpaper = (os.getenv("HOME") or "") .. "/.config/awesome/assets/wallpapers/meadow-light.png"

return theme
