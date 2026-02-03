--[[
    This user patch is for use with the Project: Title plugin.
    It is tested with v3.5, but might work with earlier versions.

    The Patch allows you remove the progress status text (New/Reading/Finished/On hold)
    from the list view.

    By default, Project: Title shows text indicating the reading status
    of books above the progressbar in list view.
    This patch removes that text display for a cleaner look, while keeping the progress bar.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



-- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

local HIDE_PROGRESS_STRING = true

-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local listmenu = require("listmenu")
    local _ = require("l10n.gettext")
    local N_ = _.ngettext
    local T = require("ffi/util").template

    local PROGRESS_STRINGS = {
        _("Finished"), _("On hold"), _("Reading"), _("New")
    }

    local ListMenuItem = userpatch.getUpValue(listmenu._updateItemsBuildUI, "ListMenuItem")

    if not ListMenuItem then
        return
    end

    -- Patch the update method to set progress_str to empty string
    local orig_ListMenuItem_update = ListMenuItem.update
    ListMenuItem.update = function(self)
        -- Only apply the patch if hiding is enabled
        if not HIDE_PROGRESS_STRING then
            orig_ListMenuItem_update(self)
            return
        end

        -- Store reference to TextWidget constructor
        local TextWidget = require("ui/widget/textwidget")
        local orig_TextWidget_new = TextWidget.new


        -- Temporarily replace TextWidget.new to filter out progress strings
        TextWidget.new = function(class, o)
            if o and o.text then
                for _, str in ipairs(PROGRESS_STRINGS) do
                    if o.text == str then
                        -- Return a dummy zero-width widget instead
                        o.text = ""
                    end
                end
            end
            return orig_TextWidget_new(class, o)
        end

        -- Call the original update
        orig_ListMenuItem_update(self)

        -- Restore original TextWidget.new
        TextWidget.new = orig_TextWidget_new
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
