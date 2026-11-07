-- Pick the Meadow palette from ~/.config/meadow/state.
-- switch-theme.sh rewrites that file and restarts awesome.
local M = {}

local home = os.getenv("HOME") or "/tmp"
local mode = "dark"

local f = io.open(home .. "/.config/meadow/state", "r")
if f then
    local value = f:read("*l")
    f:close()
    if value and value:gsub("%s+", "") == "light" then
        mode = "light"
    end
end

M.mode = mode
M.palette = require("theme.meadow-" .. mode)

return M
