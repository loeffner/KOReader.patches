--[[
    This user patch is for use with the Project: Title plugin.
    It requires v3.5.

    The Patch allows you to modify the font size limits.

    By default, Project: Title attempts to find the largest
    fontsize within the limits that does not truncate text.

    This patch modifies the limits.
    As it is set up, PT uses the same (small) font size for everything,
    to avoid varying font sizes.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



-- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

-- List view
local TITLE_FONT_NOMINAL = 20    -- Default: 20 -- Nominal font size for book titles (and directory names) in list view
local TITLE_FONT_MAX = 20        -- Default: 26 -- Maximum font size for book titles (and directory names) in list view
local TITLE_FONT_MIN = 20        -- Default: 20 -- Minimum font size for book titles (and directory names) in list view
local AUTHORS_FONT_NOMINAL = 14  -- Default: 14 -- Nominal font size for authors in list view
local AUTHORS_FONT_MAX = 18      -- Default: 18 -- Maximum font size for authors in list view
local AUTHORS_FONT_MIN = 10      -- Default: 10 -- Minimum font size for authors in list view
local PROGRESS_FONT_NOMINAL = 12 -- Default: 12 -- Nominal (and minimum) font size for progress string and progressbar height in list view
local PROGRESS_FONT_MAX = 18     -- Default: 18 -- Maximum font size for progress string and progressbar height in list view
local TAGS_FONT_MIN = 10         -- Default: 10 -- Minimum font size for tags in list view
local TAGS_FONT_OFFSET = 3       -- Default:  3 -- Offset from author font size for tags in list view (e.g. tags are 3 steps smaller than authors)

-- Grid view
local DIR_FONT_NOMINAL = 18 -- Default: 22 -- Nominal (and maximum) font size for directory names in overlay in grid view
local DIR_FONT_MIN = 18     -- Default: 18 -- Minimum font size for directory names in overlay in grid view

-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local ptutil = require("ptutil")

    -- All we have to do is overwrite the defaults in ptutil.
    ptutil.list_defaults.title_font_nominal = TITLE_FONT_NOMINAL
    ptutil.list_defaults.title_font_max = TITLE_FONT_MAX
    ptutil.list_defaults.title_font_min = TITLE_FONT_MIN
    ptutil.list_defaults.authors_font_nominal = AUTHORS_FONT_NOMINAL
    ptutil.list_defaults.authors_font_max = AUTHORS_FONT_MAX
    ptutil.list_defaults.authors_font_min = AUTHORS_FONT_MIN
    ptutil.list_defaults.wright_font_nominal = PROGRESS_FONT_NOMINAL
    ptutil.list_defaults.wright_font_max = PROGRESS_FONT_MAX
    ptutil.list_defaults.tags_font_min = TAGS_FONT_MIN
    ptutil.list_defaults.tags_font_offset = TAGS_FONT_OFFSET
    ptutil.grid_defaults.dir_font_nominal = DIR_FONT_NOMINAL
    ptutil.grid_defaults.dir_font_min = DIR_FONT_MIN
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
