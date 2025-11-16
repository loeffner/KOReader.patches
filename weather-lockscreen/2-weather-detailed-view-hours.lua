--[[
    This user patch is for use with the Weather Lockscreen plugin.
    It requires WeatherLockscreen v0.9.2-beta.2

    The Patch allows you to modify the hours that are shown in the detailed display.

    By default, WeatherLockscreen shows 6 am, 12 pm, 6 pm

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]



-- vvvvvvvvvvvvvvvvvvvvvvvvvvv-Modify here-vvvvvvvvvvvvvvvvvvvvvvvvvvvvv -

local TARGET_HOURS = {7, 12, 20}          -- Default: {6, 12, 18}
-- local TARGET_HOURS = {4, 8, 12, 16, 20}



-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^-Modify here-^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -


local userpatch = require("userpatch")

local function patchWeatherLockscreen(plugin)
    local WeatherUtils = require("weather_utils")

    -- All we have to do is overwrite the defaults weather_utils.
    WeatherUtils.target_hours = TARGET_HOURS
end

userpatch.registerPatchPluginFunc("weatherlockscreen", patchWeatherLockscreen)
