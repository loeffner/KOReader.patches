--[[
    This user patch is for use with the Project: Title plugin.
    It is tested with v3.5, but might work with earlier versions.

    The Patch allows you remove the item count overlay for directories
    in the cover grid view.

    When enabled, Project: Title shows the folder name at the top and
    the number of folders and files at the bottom of a directory cover.
    This patch hides the item count for a cleaner look while keeping
    the folder name.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



    -- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

local HIDE_NBITEMS_OVERLAY = true

    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")

    if not MosaicMenuItem then
        return
    end

    -- Patch the update method to conditionally remove nbitems
    local orig_MosaicMenuItem_update = MosaicMenuItem.update
    MosaicMenuItem.update = function(self)
        -- Call the original update
        orig_MosaicMenuItem_update(self)

        -- If this is a directory and hiding is enabled, remove the nbitems widget
        if self.is_directory and HIDE_NBITEMS_OVERLAY then
            local widget_parts = self._underline_container[1][1]

            -- widget_parts is an OverlapGroup that contains:
            -- 1. CenterContainer with subfolder_cover_image
            -- 2. TopContainer with directory name (if show_name_grid_folders is true)
            -- 3. BottomContainer with nbitems (if show_name_grid_folders is true)

            -- We want to remove the BottomContainer (the third element)
            if widget_parts and #widget_parts >= 3 then
                -- Free the widget to avoid memory leaks
                if widget_parts[3] and widget_parts[3].free then
                    widget_parts[3]:free()
                end
                -- Remove it from the widget tree
                table.remove(widget_parts, 3)
            end
        end
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
