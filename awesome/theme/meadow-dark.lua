-- Meadow (dark) — https://glocean.dev/meadow
-- Palette shared with Ghostty/Fish/Starship/btop/rofi in this repo.
local gears = require("gears")

local theme = {}

theme.name = "meadow-dark"
theme.mode = "dark"

-- Typography (SF Pro -> Inter, JetBrains Mono + Nerd Font symbols)
theme.font = "Inter 10"
theme.font_bold = "Inter Bold 10"
theme.mono_font = "JetBrains Mono 10"

-- Core
theme.bg = "#1f1a24"
theme.surface = "#2a2431"
theme.surface2 = "#3a3245"
theme.surface3 = "#4c4161"
theme.text = "#ebe7f0"
theme.muted = "#958aa3"

theme.lavender = "#c1b0e7"
theme.cornflower = "#9cb8eb"
theme.marigold = "#e9b17c"
theme.dew = "#84c7d5"
theme.sage = "#a4bba9"
theme.poppy = "#d68583"

theme.bg_normal = theme.bg
theme.bg_focus = theme.surface
theme.bg_urgent = theme.poppy
theme.bg_minimize = theme.surface
theme.bg_systray = theme.surface
theme.fg_normal = theme.text
theme.fg_focus = theme.text
theme.fg_urgent = theme.bg
theme.fg_minimize = theme.muted

-- Borders (yabai / JankyBorders: width 5 hidpi -> 3px on 1x)
theme.border_width = 3
theme.border_normal = theme.surface
theme.border_focus = theme.lavender
theme.border_marked = theme.poppy

-- Gaps (yabairc: window_gap 10, padding 10)
theme.useless_gap = 10
theme.snap_bg = theme.lavender
theme.snap_border_width = 2

-- Bar (sketchybarrc: height 43)
theme.bar_bg = theme.bg
theme.bar_fg = theme.text
theme.bar_border = theme.surface
theme.bar_height = 43
theme.widget_bg = theme.surface
theme.widget_fg = theme.text

theme.taglist_spacing = 4
theme.taglist_bg_focus = theme.lavender
theme.taglist_fg_focus = theme.bg
theme.taglist_bg_occupied = theme.surface
theme.taglist_fg_occupied = theme.text
theme.taglist_bg_empty = theme.surface3
theme.taglist_fg_empty = theme.muted
theme.taglist_bg_urgent = theme.poppy
theme.taglist_fg_urgent = theme.bg
theme.taglist_font = theme.font_bold
theme.taglist_shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 6) end
theme.taglist_shape_border_width = 0

theme.tasklist_bg_focus = theme.surface
theme.tasklist_fg_focus = theme.lavender
theme.tasklist_bg_normal = theme.bg
theme.tasklist_fg_normal = theme.muted
theme.tasklist_bg_minimize = theme.bg
theme.tasklist_fg_minimize = theme.surface3
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

theme.icon_theme = "Papirus-Dark"
theme.wallpaper = (os.getenv("HOME") or "") .. "/.config/awesome/assets/wallpapers/meadow-dark.png"

return theme
