--[[
    This user patch is for use with the Project: Title plugin.
    It requires v3.5.

    The Patch allows you to set a custom maximum number of tags displayed under
    books in list view.

    By default, Project: Title shows as many tags as the available width permits.
    This patch lets you limit the number of displayed tags.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



    -- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

local TAGS_LIMIT = 4 -- Default unlimited (9999)

    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local ptutil = require("ptutil")

    -- All we have to do is overwrite the defaults in ptutil.
    ptutil.list_defaults.tags_limit = TAGS_LIMIT
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
