--[[
    This user patch is for use with the Project: Title plugin.
    It requires v3.8.

    The Patch draws every cover in the cover grid at the same size.

    By default, Project: Title scales each cover to fit its grid cell while
    keeping the cover's own aspect ratio, so covers end up with different sizes.
    This patch stretches every cover to the grid cell instead (covers are
    stretched, not cropped). It only affects the cover grid, not the list view.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



    -- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

-- Width of a cover as a fraction of the grid cell width (1 = full width).
-- Lower values (e.g. 0.8-0.9) reduce distortion for typical 2:3 covers.
local STRETCH_RATIO = 1

    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local ptutil = require("ptutil")

    -- All we have to do is overwrite the defaults in ptutil.
    ptutil.grid_defaults.stretch_covers = true
    ptutil.grid_defaults.stretch_ratio = STRETCH_RATIO
end

userpatch.registerPatchPluginFunc("projecttitle", patchCoverBrowser)
