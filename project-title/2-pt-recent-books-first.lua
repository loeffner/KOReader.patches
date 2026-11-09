--[[
    This user patch is for use with the Project: Title plugin.
    It requires a Project: Title version without the built-in "Library mode"
    (the current master branch), together with KOReader's
    "Show all files from subfolders" option.

    The Patch brings back the "Show opened books first" feature of the old
    Library mode: books you are currently reading are moved to the front of
    the list and marked with a black separator line (list view) or a black
    underline (cover grid).

    Project: Title replaced its Library mode with KOReader's "Show all files
    from subfolders" option (long-press the Project: Title logo to toggle it),
    but kept the code that draws the separator. This patch only reorders the
    items and tells Project: Title where the recent books end.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



    -- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

-- true:  only in the "Library" view (Show all files from subfolders), like the old Library mode
-- false: in every folder of the file browser
local ONLY_IN_LIBRARY = true

-- false: recent books keep the current sort order of the file browser (like the old Library mode)
-- true:  recent books are sorted by last read date, most recent first
local ORDER_BY_LAST_READ = false

    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local FileChooser = require("ui/widget/filechooser")
    local BookList = require("ui/widget/booklist")

    -- Plugin patches run for every new FileManager/Reader instance: wrap only once.
    if FileChooser._pt_recent_books_first then
        return
    end
    FileChooser._pt_recent_books_first = true

    -- Same criterion as the old Library mode and as Project: Title's "Reading" label:
    -- status "reading" and a stored reading position below 100%.
    -- A book can have a sidecar (.sdr) without ever being read; KOReader then reports
    -- status "reading" but no percent_finished, and Project: Title shows it as "New".
    local function isRecent(item)
        if not (item.is_file and item.path) then
            return false
        end
        local info = BookList.getBookInfo(item.path)
        local percent = info.percent_finished
        return info.been_opened == true
            and info.status == "reading"
            and type(percent) == "number"
            and percent < 1
    end

    local function sortByLastRead(recent)
        local ReadHistory = require("readhistory")
        local hist_pos = {}
        for i, entry in ipairs(ReadHistory.hist) do
            hist_pos[entry.file] = i
        end
        for i, item in ipairs(recent) do
            item._pt_order = i -- keep the original order for books not in history
        end
        table.sort(recent, function(a, b)
            local pa, pb = hist_pos[a.path] or math.huge, hist_pos[b.path] or math.huge
            if pa ~= pb then
                return pa < pb
            end
            return a._pt_order < b._pt_order
        end)
    end

    local orig_genItemTable = FileChooser.genItemTable
    FileChooser.genItemTable = function(self, dirs, files, path)
        local item_table = orig_genItemTable(self, dirs, files, path)

        -- Project: Title reads these from the file chooser; reset them so no stale
        -- separator survives a folder change.
        self.recent_boundary_index = 0
        self.meta_show_opened = nil

        if not self.is_fm or type(item_table) ~= "table" then
            return item_table
        end
        if ONLY_IN_LIBRARY and not FileChooser.show_flat_view then
            return item_table
        end
        self.meta_show_opened = true -- extra separator below the last row, as in the old Library mode

        local head, recent, others = {}, {}, {}
        for _, item in ipairs(item_table) do
            if item.is_go_up and #recent == 0 and #others == 0 then
                table.insert(head, item) -- keep "../" at the very top
            elseif isRecent(item) then
                table.insert(recent, item)
            else
                table.insert(others, item)
            end
        end
        if #recent == 0 then
            return item_table
        end
        if ORDER_BY_LAST_READ then
            sortByLastRead(recent)
        end

        local result = {}
        for _, t in ipairs({ head, recent, others }) do
            for _, item in ipairs(t) do
                table.insert(result, item)
            end
        end
        self.recent_boundary_index = #head + #recent
        return result
    end
end

userpatch.registerPatchPluginFunc("projecttitle", patchCoverBrowser)
