--[[
    This user patch is for use with the Project: Title plugin.
    It requires v3.5.

    The Patch allows you to modify the format of series display.

    By default, Project: Title formats series as "#<index> - <series name>".
    This patch lets you customize the format string.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



-- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

-- Choose one of the following format strings, or create your own.
-- Available placeholders:
--   {index}  = series index number
--   {series} = series name
--
-- Format string suggestions:
local FORMAT_DEFAULT     = "#{index} - {series}"      -- #3 - The Lord of the Rings
local FORMAT_COLON       = "#{index}: {series}"       -- #3: The Lord of the Rings
local FORMAT_REVERSE     = "{series} #{index}"        -- The Lord of the Rings #3
local FORMAT_BRACKET     = "{series} [{index}]"       -- The Lord of the Rings [3]
local FORMAT_BOOK        = "Book {index} of {series}" -- Book 3 of The Lord of the Rings
local FORMAT_VOL         = "Vol. {index} - {series}"  -- Vol. 3 - The Lord of the Rings
local FORMAT_SERIES_ONLY = "{series}"                 -- The Lord of the Rings

-- Select which format to use:
local SERIES_FORMAT      = FORMAT_REVERSE

-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
  local ptutil = require("ptutil")
  local BD = require("ui/bidi")

  -- Override the formatSeries function
  function ptutil.formatSeries(series, series_index)
    local formatted_series = ""

    if series_index then
      -- Apply the custom format string
      formatted_series = SERIES_FORMAT
      formatted_series = formatted_series:gsub("{index}", tostring(series_index))
      formatted_series = formatted_series:gsub("{series}", BD.auto(series))
    else
      formatted_series = BD.auto(series)
    end

    return formatted_series
  end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
