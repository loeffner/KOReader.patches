--[[
    This user patch is for use with the Project: Title plugin.
    It requires v3.5.

    The Patch allows you to modify the limits for the number of items on the page.

    By default, Project: Title limits listview to 3 - 10 elements,
    and gridview to 2 - 4 elements per column and row.

    This patch modifies the limit to allow for more or fewer items.
    It also lets you change the default values.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



-- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

local MAX_ITEMS_PER_PAGE = 15     -- Default: 10
local MIN_ITEMS_PER_PAGE = 3      -- Default: 3
local DEFAULT_ITEMS_PER_PAGE = 10 -- Default: 7
local GRID_MAX_COLS = 4           -- Default: 4
local GRID_MAX_ROWS = 4           -- Default: 4
local GRID_MIN_COLS = 2           -- Default: 2
local GRID_MIN_ROWS = 2           -- Default: 2
local GRID_DEFAULT_COLS = 3       -- Default: 3
local GRID_DEFAULT_ROWS = 3       -- Default: 3

-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local ptutil = require("ptutil")

    -- All we have to do is overwrite the defaults in ptutil.
    ptutil.list_defaults.max_items_per_page = MAX_ITEMS_PER_PAGE
    ptutil.list_defaults.min_items_per_page = MIN_ITEMS_PER_PAGE
    ptutil.list_defaults.default_items_per_page = DEFAULT_ITEMS_PER_PAGE
    ptutil.grid_defaults.max_cols = GRID_MAX_COLS
    ptutil.grid_defaults.max_rows = GRID_MAX_ROWS
    ptutil.grid_defaults.min_cols = GRID_MIN_COLS
    ptutil.grid_defaults.min_rows = GRID_MIN_ROWS
    ptutil.grid_defaults.default_cols = GRID_DEFAULT_COLS
    ptutil.grid_defaults.default_rows = GRID_DEFAULT_ROWS
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
