--[[
    This user patch is for use with the Project: Title plugin.
    It requires v3.5.

    The Patch allows you to modify the maximum progress bar width.

    By default, Project: Title limits progress bars to 235 pixels maximum,
    which represents about 705 pages (at 3 pixels per page). For books longer
    than this the progress bar is cut off and shows a "large book" indicator '∫'.

    This patch modifies the limit to allow for longer or shorter progress bars.
    You might have to play around with it to find a value that fits your screen (width and dpi).

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



    -- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

local PROGRESS_BAR_MAX_SIZE_LIST = 250   -- Default: 235

-- For grid view it works a bit different. The progress bars dont get longer, but the
-- relative length to the cover width changes.
-- Uncomment to modify grid view
-- local PROGRESS_BAR_MAX_SIZE_LIST_GRID = 235   -- Default: 235

    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local ptutil = require("ptutil")

    -- All we have to do is overwrite the default in ptutil.
    ptutil.list_defaults.progress_bar_max_size = PROGRESS_BAR_MAX_SIZE_LIST

    -- Uncomment to change the value for grid view.
    -- ptutil.grid_defaults.progress_bar_max_size = PROGRESS_BAR_MAX_SIZE_GRID


end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
