--[[
    This user patch is for use with the Project: Title plugin.
    It requires v3.5.

    The Patch allows you to modify the maximum progress bar width.

    By default, Project: Title limits progress bars to 235 pixels maximum,
    which represents 705 pages (at 3 pages per pixel). For books longer
    than this the progress bar is cut off and shows a "large book" indicator '∫'.

    This patch modifies the limit to allow for longer or shorter progress bars.
    You might have to play around with it to find a value that fits your screen (width and dpi).

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



-- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

-- This value will make the progress bar "physically" longer. If there is not enough space it will squish the elements on the left.
local PROGRESS_BAR_MAX_SIZE_LIST = 250 -- Default: 235
-- This value squeezes more pages into the same space, making the bar reflect larger books without increasing the physical size.
local PAGES_PER_PIXEL = 3              -- Default: 3

-- For grid view it works a bit different. The progress bars dont get longer, but the
-- relative length to the cover width changes.
-- Uncomment to modify grid view
local PROGRESS_BAR_MAX_SIZE_GRID = 235   -- Default: 235

-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local ptutil = require("ptutil")

    -- All we have to do is overwrite the default in ptutil.
    ptutil.list_defaults.progress_bar_max_size = PROGRESS_BAR_MAX_SIZE_LIST

    ptutil.list_defaults.progress_bar_pixels_per_page = PAGES_PER_PIXEL -- for PT 3.5
    ptutil.list_defaults.progress_bar_pages_per_pixel = PAGES_PER_PIXEL -- for PT 3.6+ (it was renamed to reflect what it actually does)

    -- Uncomment to change the value for grid view.
    ptutil.grid_defaults.progress_bar_max_size = PROGRESS_BAR_MAX_SIZE_GRID
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
