--[[
    This user patch is for use with the Weather plugin.
    This user patch adds a "Weather" option to the Sleep screen > Wallpaper menu.

    The weather is fetched from the Weather plugin's configured location.

    Navigate to: Settings > Screen > Sleep screen > Wallpaper > Weather

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]


local WEATHER_ICON_SIZE = 200  -- Size of the weather icon in pixels
local WEATHER_CACHE_MAX_AGE = 3600  -- Maximum age of cached weather data in seconds (1 hour)

local userpatch = require("userpatch")
local logger = require("logger")

local function patchWeather(weather_plugin)
    local UIManager = require("ui/uimanager")
    local DataStorage = require("datastorage")
    local ImageWidget = require("ui/widget/imagewidget")
    local TextWidget = require("ui/widget/textwidget")
    local VerticalGroup = require("ui/widget/verticalgroup")
    local CenterContainer = require("ui/widget/container/centercontainer")
    local Font = require("ui/font")
    local Blitbuffer = require("ffi/blitbuffer")
    local Device = require("device")
    local Screen = Device.screen
    local WeatherApi = require("weatherapi")
    local ScreenSaverWidget = require("ui/widget/screensaverwidget")
    local bit = require("bit")

    local function getIconPath(icon_url_from_api)
        -- WeatherAPI returns icon URLs like "//cdn.weatherapi.com/weather/64x64/day/113.png"
        -- We need to download these and cache them locally
        if not icon_url_from_api then
            return nil
        end

        local url = icon_url_from_api
        if url:sub(1, 2) == "//" then
            url = "https:" .. url
        end

        -- Extract filename from URL (e.g., "113.png" from the path)
        local filename = url:match("([^/]+)$")
        if not filename then
            return nil
        end

        -- Cache directory
        local cache_dir = DataStorage:getDataDir() .. "/cache/weather-icons/"
        local cache_path = cache_dir .. filename

        -- Check if already cached
        local f = io.open(cache_path, "r")
        if f then
            f:close()
            logger.dbg("Weather lockscreen: Using cached icon:", cache_path)
            return cache_path
        end

        -- Download the icon
        logger.dbg("Weather lockscreen: Downloading icon from:", url)
        local http = require("socket.http")
        local ltn12 = require("ltn12")
        local util = require("util")

        -- Create cache directory if needed
        util.makePath(cache_dir)

        local sink_table = {}
        local res, code = http.request{
            url = url,
            sink = ltn12.sink.table(sink_table)
        }

        if code == 200 then
            local icon_data = table.concat(sink_table)
            local out_file = io.open(cache_path, "wb")
            if out_file then
                out_file:write(icon_data)
                out_file:close()
                logger.dbg("Weather lockscreen: Downloaded and cached icon:", cache_path)
                return cache_path
            else
                logger.warn("Weather lockscreen: Failed to write icon file:", cache_path)
            end
        else
            logger.warn("Weather lockscreen: Failed to download icon, HTTP code:", code)
        end

        return nil
    end

    local function saveWeatherCache(weather_data)
        local cache_file = DataStorage:getDataDir() .. "/cache/weather-lockscreen.json"
        local util = require("util")
        local cache_dir = DataStorage:getDataDir() .. "/cache/"
        util.makePath(cache_dir)

        -- Add timestamp to cache
        local cache_data = {
            timestamp = os.time(),
            data = weather_data
        }

        local json = require("json")
        local f = io.open(cache_file, "w")
        if f then
            f:write(json.encode(cache_data))
            f:close()
            logger.dbg("Weather lockscreen: Cached weather data")
            return true
        else
            logger.warn("Weather lockscreen: Failed to write cache file")
            return false
        end
    end

    local function loadWeatherCache()
        local cache_file = DataStorage:getDataDir() .. "/cache/weather-lockscreen.json"
        local f = io.open(cache_file, "r")
        if not f then
            logger.dbg("Weather lockscreen: No cache file found")
            return nil
        end

        local content = f:read("*all")
        f:close()

        local json = require("json")
        local success, cache_data = pcall(json.decode, content)
        if not success or not cache_data then
            logger.warn("Weather lockscreen: Failed to parse cache file")
            return nil
        end

        if not cache_data.timestamp or not cache_data.data then
            logger.warn("Weather lockscreen: Invalid cache format")
            return nil
        end

        local age = os.time() - cache_data.timestamp
        logger.dbg("Weather lockscreen: Cache age:", age, "seconds")

        if age > WEATHER_CACHE_MAX_AGE then
            logger.dbg("Weather lockscreen: Cache too old, ignoring")
            return nil
        end

        logger.dbg("Weather lockscreen: Using cached weather data")
        return cache_data.data, cache_data.timestamp
    end

    local function formatHourLabel(hour, clock_style)
        if clock_style == "12" then
            if hour == 0 then
                return "12 AM"
            elseif hour < 12 then
                return hour .. " AM"
            elseif hour == 12 then
                return "12 PM"
            else
                return (hour - 12) .. " PM"
            end
        else
            return hour .. ":00"
        end
    end

    local function fetchWeatherData()
        -- Load settings from G_reader_settings (global settings object)
        local postal_code = G_reader_settings:readSetting("weather_postal_code") or "X0A0H0"
        local api_key = G_reader_settings:readSetting("weather_api_key")
        local temp_scale = G_reader_settings:readSetting("weather_temp_scale") or "C"
        local clock_style = G_reader_settings:readSetting("weather_clock_style") or "12"

        -- Initialize weather API
        local api = WeatherApi:new{ api_key = api_key }
        logger.dbg("Weather lockscreen: Fetching weather for postal code:", postal_code)
        local result = api:getForecast(2, postal_code)

        if result and result.current and not result.error then
            logger.dbg("Weather lockscreen: Weather data received successfully")

            -- Process current weather
            local condition = result.current.condition.text
            logger.dbg("Weather lockscreen: Current condition:", condition)
            local icon_path = getIconPath(result.current.condition.icon)
            logger.dbg("Weather lockscreen: Icon path:", icon_path)

            local temperature
            if temp_scale == "C" then
                temperature = math.floor(result.current.temp_c) .. "°C"
            else
                temperature = math.floor(result.current.temp_f) .. "°F"
            end

            local current_data = {
                icon_path = icon_path,
                temperature = temperature,
                condition = condition,
                location = result.location and result.location.name or nil,
                timestamp = os.date("%Y-%m-%d %H:%M"),
            }

            -- Extract hourly data for today and tomorrow
            local hourly_today = {}
            local hourly_tomorrow = {}
            local target_hours = {6, 12, 18}  -- Hours we want to display

            if result.forecast and result.forecast.forecastday then
                -- Process today's hours (day 1)
                if result.forecast.forecastday[1] and result.forecast.forecastday[1].hour then
                    for _, hour_data in ipairs(result.forecast.forecastday[1].hour) do
                        local hour = tonumber(hour_data.time:match("(%d+):00$"))
                        if hour then
                            for _, target_hour in ipairs(target_hours) do
                                if hour == target_hour then
                                    local h_icon_path = getIconPath(hour_data.condition.icon)
                                    local h_temp = temp_scale == "C" 
                                        and math.floor(hour_data.temp_c) .. "°"
                                        or math.floor(hour_data.temp_f) .. "°"

                                    table.insert(hourly_today, {
                                        hour = formatHourLabel(target_hour, clock_style),
                                        icon_path = h_icon_path,
                                        temperature = h_temp
                                    })
                                    break
                                end
                            end
                        end
                    end
                end

                -- Process tomorrow's hours (day 2)
                if result.forecast.forecastday[2] and result.forecast.forecastday[2].hour then
                    for _, hour_data in ipairs(result.forecast.forecastday[2].hour) do
                        local hour = tonumber(hour_data.time:match("(%d+):00$"))
                        if hour then
                            for _, target_hour in ipairs(target_hours) do
                                if hour == target_hour then
                                    local h_icon_path = getIconPath(hour_data.condition.icon)
                                    local h_temp = temp_scale == "C" 
                                        and math.floor(hour_data.temp_c) .. "°"
                                        or math.floor(hour_data.temp_f) .. "°"

                                    table.insert(hourly_tomorrow, {
                                        hour = formatHourLabel(target_hour, clock_style),
                                        icon_path = h_icon_path,
                                        temperature = h_temp
                                    })
                                    break
                                end
                            end
                        end
                    end
                end
            end

            logger.dbg("Weather lockscreen: Hours today:", #hourly_today, "Hours tomorrow:", #hourly_tomorrow)

            local weather_data = {
                current = current_data,
                hourly_today = hourly_today,
                hourly_tomorrow = hourly_tomorrow
            }

            -- Save to cache
            saveWeatherCache(weather_data)

            return weather_data
        else
            logger.warn("Weather lockscreen: Failed to fetch weather data or received error")
            if result and result.error then
                logger.warn("Weather lockscreen: API error:", result.error.message)
            end
        end

        -- Try to load from cache if fetch failed
        logger.dbg("Weather lockscreen: Attempting to load cached data")
        local cached_data, cache_timestamp = loadWeatherCache()
        if cached_data then
            cached_data.cache_timestamp = cache_timestamp
            return cached_data
        end

        return nil
    end

    local function createFallbackWidget()
        logger.dbg("Weather lockscreen: Creating fallback icon based on time of day")

        -- Calculate scale factor based on screen width
        local screen_width = Screen:getWidth()
        local base_width = 600
        local scale_factor = math.min(2.5, math.max(1.0, screen_width / base_width))

        local icon_size = math.floor(WEATHER_ICON_SIZE * scale_factor * 2)  -- Make it larger for fallback

        -- Determine if it's day or night (6 AM - 6 PM = day, otherwise night)
        local current_hour = tonumber(os.date("%H"))
        local is_daytime = current_hour >= 6 and current_hour < 18

        -- Get the icon path
        local icon_filename = is_daytime and "sun.svg" or "moon.svg"
        local icon_path = DataStorage:getDataDir() .. "/icons/" .. icon_filename

        logger.dbg("Weather lockscreen: Using fallback icon:", icon_path, "Hour:", current_hour)

        -- Check if the icon file exists
        local f = io.open(icon_path, "r")
        if f then
            f:close()
        else
            logger.warn("Weather lockscreen: Fallback icon not found:", icon_path)
            return nil
        end

        local icon_widget = ImageWidget:new{
            file = icon_path,
            width = icon_size,
            height = icon_size,
            alpha = true,
        }

        return CenterContainer:new{
            dimen = Screen:getSize(),
            VerticalGroup:new{
                align = "center",
                icon_widget,
            },
        }
    end

    local function createWeatherLockscreenWidget()
        logger.dbg("Weather lockscreen: Creating widget")
        local weather_data = fetchWeatherData()

        if not weather_data or not weather_data.current or not weather_data.current.icon_path then
            logger.warn("Weather lockscreen: No weather data or icon path available, trying fallback")
            local fallback = createFallbackWidget()
            if fallback then
                return fallback
            end
            logger.warn("Weather lockscreen: Fallback also failed, returning nil")
            return nil
        end

        logger.dbg("Weather lockscreen: Icon path:", weather_data.current.icon_path)
        logger.dbg("Weather lockscreen: Temperature:", weather_data.current.temperature)
        logger.dbg("Weather lockscreen: Condition:", weather_data.current.condition)

        -- Calculate scale factor based on screen width
        -- Base size is designed for ~600px width, scale proportionally for larger screens
        local screen_width = Screen:getWidth()
        local base_width = 600
        local scale_factor = math.min(2.5, math.max(1.0, screen_width / base_width))
        logger.dbg("Weather lockscreen: Screen width:", screen_width, "Scale factor:", scale_factor)

        -- Scaled sizes
        local current_icon_size = math.floor(WEATHER_ICON_SIZE * scale_factor)
        local hourly_icon_size = math.floor(WEATHER_ICON_SIZE * 0.4 * scale_factor)
        local temp_font_size = math.floor(32 * scale_factor)
        local condition_font_size = math.floor(24 * scale_factor)
        local location_font_size = math.floor(18 * scale_factor)
        local label_font_size = math.floor(20 * scale_factor)
        local hour_font_size = math.floor(16 * scale_factor)
        local timestamp_font_size = math.floor(14 * scale_factor)
        local header_font_size = math.floor(16 * scale_factor)
        local vertical_spacing = math.floor(20 * scale_factor)
        local horizontal_spacing = math.floor(15 * scale_factor)
        local header_margin = math.floor(10 * scale_factor)

        local HorizontalGroup = require("ui/widget/horizontalgroup")
        local HorizontalSpan = require("ui/widget/horizontalspan")
        local VerticalSpan = require("ui/widget/verticalspan")
        local OverlapGroup = require("ui/widget/overlapgroup")
        local LeftContainer = require("ui/widget/container/leftcontainer")
        local RightContainer = require("ui/widget/container/rightcontainer")
        local FrameContainer = require("ui/widget/container/framecontainer")

        local widgets = {}

        -- Header: Location (top left) and Timestamp (top right)
        local header_widgets = {}
        
        -- Location in top left
        if weather_data.current.location then
            table.insert(header_widgets, LeftContainer:new{
                dimen = { w = Screen:getWidth(), h = header_font_size + header_margin * 2 },
                FrameContainer:new{
                    padding = header_margin,
                    margin = 0,
                    bordersize = 0,
                    TextWidget:new{
                        text = weather_data.current.location,
                        face = Font:getFace("cfont", header_font_size),
                        fgcolor = Blitbuffer.COLOR_DARK_GRAY,
                    },
                },
            })
        end

        -- Timestamp in top right
        if weather_data.current.timestamp then
            -- Format timestamp: "2025-11-01 16:12" -> "Nov 1, 4:12 PM" or similar
            local timestamp = weather_data.current.timestamp
            local year, month, day, hour, min = timestamp:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
            local formatted_time = ""
            if year and month and day and hour and min then
                local month_names = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
                local month_name = month_names[tonumber(month)] or month
                local clock_style = G_reader_settings:readSetting("weather_clock_style") or "12"
                local hour_num = tonumber(hour)
                local time_str
                if clock_style == "12" then
                    local period = hour_num >= 12 and "PM" or "AM"
                    local display_hour = hour_num % 12
                    if display_hour == 0 then display_hour = 12 end
                    time_str = display_hour .. ":" .. min .. " " .. period
                else
                    time_str = hour .. ":" .. min
                end
                formatted_time = month_name .. " " .. tonumber(day) .. ", " .. time_str
            else
                formatted_time = timestamp
            end

            table.insert(header_widgets, RightContainer:new{
                dimen = { w = Screen:getWidth(), h = header_font_size + header_margin * 2 },
                FrameContainer:new{
                    padding = header_margin,
                    margin = 0,
                    bordersize = 0,
                    TextWidget:new{
                        text = formatted_time,
                        face = Font:getFace("cfont", header_font_size),
                        fgcolor = Blitbuffer.COLOR_DARK_GRAY,
                    },
                },
            })
        end

        local header_group = OverlapGroup:new{
            dimen = { w = Screen:getWidth(), h = header_font_size + header_margin * 2 },
            unpack(header_widgets)
        }

        -- Row 1: Current weather (large)
        local current_widgets = {}

        -- Current weather icon
        local icon_widget = ImageWidget:new{
            file = weather_data.current.icon_path,
            width = current_icon_size,
            height = current_icon_size,
            alpha = true,
        }
        table.insert(current_widgets, icon_widget)

        -- Current temperature text
        if weather_data.current.temperature then
            table.insert(current_widgets, TextWidget:new{
                text = weather_data.current.temperature,
                face = Font:getFace("cfont", temp_font_size),
                bold = true,
            })
        end

        -- Current condition text
        if weather_data.current.condition then
            table.insert(current_widgets, TextWidget:new{
                text = weather_data.current.condition,
                face = Font:getFace("cfont", condition_font_size),
            })
        end

        table.insert(widgets, VerticalGroup:new{
            align = "center",
            unpack(current_widgets)
        })

        -- Spacing
        table.insert(widgets, VerticalSpan:new{ width = vertical_spacing })

        -- Row 2: "Today" label + hourly forecast if we have hours left today
        if weather_data.hourly_today and #weather_data.hourly_today > 0 then
            table.insert(widgets, TextWidget:new{
                text = "Today",
                face = Font:getFace("cfont", label_font_size),
                bold = true,
            })

            local today_row = {}
            for i, hour_data in ipairs(weather_data.hourly_today) do
                if i > 1 then
                    table.insert(today_row, HorizontalSpan:new{ width = horizontal_spacing })
                end

                local hour_widgets = {}
                table.insert(hour_widgets, TextWidget:new{
                    text = hour_data.hour,
                    face = Font:getFace("cfont", hour_font_size),
                })

                if hour_data.icon_path then
                    table.insert(hour_widgets, ImageWidget:new{
                        file = hour_data.icon_path,
                        width = hourly_icon_size,
                        height = hourly_icon_size,
                        alpha = true,
                    })
                end

                table.insert(hour_widgets, TextWidget:new{
                    text = hour_data.temperature,
                    face = Font:getFace("cfont", hour_font_size),
                })

                table.insert(today_row, VerticalGroup:new{
                    align = "center",
                    unpack(hour_widgets)
                })
            end

            table.insert(widgets, HorizontalGroup:new{
                align = "center",
                unpack(today_row)
            })

            table.insert(widgets, VerticalSpan:new{ width = vertical_spacing })
        end

        -- Row 3: "Tomorrow" label + hourly forecast
        if weather_data.hourly_tomorrow and #weather_data.hourly_tomorrow > 0 then
            table.insert(widgets, TextWidget:new{
                text = "Tomorrow",
                face = Font:getFace("cfont", label_font_size),
                bold = true,
            })

            local tomorrow_row = {}
            for i, hour_data in ipairs(weather_data.hourly_tomorrow) do
                if i > 1 then
                    table.insert(tomorrow_row, HorizontalSpan:new{ width = horizontal_spacing })
                end

                local hour_widgets = {}
                table.insert(hour_widgets, TextWidget:new{
                    text = hour_data.hour,
                    face = Font:getFace("cfont", hour_font_size),
                })

                if hour_data.icon_path then
                    table.insert(hour_widgets, ImageWidget:new{
                        file = hour_data.icon_path,
                        width = hourly_icon_size,
                        height = hourly_icon_size,
                        alpha = true,
                    })
                end

                table.insert(hour_widgets, TextWidget:new{
                    text = hour_data.temperature,
                    face = Font:getFace("cfont", hour_font_size),
                })

                table.insert(tomorrow_row, VerticalGroup:new{
                    align = "center",
                    unpack(hour_widgets)
                })
            end

            table.insert(widgets, HorizontalGroup:new{
                align = "center",
                unpack(tomorrow_row)
            })
        end

        local weather_group = VerticalGroup:new{
            align = "center",
            unpack(widgets)
        }

        local main_content = CenterContainer:new{
            dimen = Screen:getSize(),
            weather_group,
        }

        -- Combine header and main content using OverlapGroup
        return OverlapGroup:new{
            dimen = Screen:getSize(),
            main_content,
            header_group,
        }
    end

    -- Hook into the Screensaver.show() method to handle "weather" type
    local Screensaver = require("ui/screensaver")
    local _ = require("gettext")

    -- Store original show method and override it
    local orig_show = Screensaver.show
    Screensaver.show = function(self)
        logger.dbg("Weather lockscreen: Screensaver.show() called, type:", self.screensaver_type)

        if self.screensaver_type == "weather" then
            logger.dbg("Weather lockscreen: Weather screensaver activated")

            -- Close any existing screensaver widget to ensure fresh data
            if self.screensaver_widget then
                logger.dbg("Weather lockscreen: Closing existing widget")
                UIManager:close(self.screensaver_widget)
                self.screensaver_widget = nil
            end

            -- Notify Device that we're in screen saver mode
            Device.screen_saver_mode = true

            -- Set rotation mode if needed (copied from original)
            local rotation_mode = Screen:getRotationMode()
            Device.orig_rotation_mode = rotation_mode
            if bit.band(Device.orig_rotation_mode, 1) == 1 then
                Screen:setRotationMode(Screen.DEVICE_ROTATED_UPRIGHT)
            else
                Device.orig_rotation_mode = nil
            end

            -- Get weather data and create widget (with fallback to sun icon)
            local weather_widget = createWeatherLockscreenWidget()

            if weather_widget then
                logger.dbg("Weather lockscreen: Widget created successfully, displaying...")

                -- Create and show the screensaver widget
                self.screensaver_widget = ScreenSaverWidget:new{
                    widget = weather_widget,
                    background = Blitbuffer.COLOR_WHITE,
                    covers_fullscreen = true,
                }
                self.screensaver_widget.modal = true
                self.screensaver_widget.dithered = true

                UIManager:show(self.screensaver_widget, "full")
                logger.dbg("Weather lockscreen: Widget displayed")
            else
                logger.warn("Weather lockscreen: All widget creation failed, falling back to disable")
                self.screensaver_type = "disable"
                orig_show(self)
            end
        else
            -- Call original show for other screensaver types
            orig_show(self)
        end
    end

    -- Monkey-patch dofile to add weather option to the screensaver menu
    local orig_dofile = dofile
    _G.dofile = function(filepath)
        local result = orig_dofile(filepath)

        -- Check if this is the screensaver menu being loaded
        if filepath and filepath:match("screensaver_menu%.lua$") then
            logger.dbg("Weather lockscreen: Patching screensaver menu")

            -- Result is a table with {wallpaper_menu, message_menu}
            if result and result[1] and result[1].sub_item_table then
                local wallpaper_submenu = result[1].sub_item_table

                -- Helper function (copied from screensaver_menu.lua)
                local function genMenuItem(text, setting, value, enabled_func, separator)
                    return {
                        text = text,
                        enabled_func = enabled_func,
                        checked_func = function()
                            return G_reader_settings:readSetting(setting) == value
                        end,
                        callback = function()
                            G_reader_settings:saveSetting(setting, value)
                        end,
                        radio = true,
                        separator = separator,
                    }
                end

                -- Insert weather option above "Leave screen as-is" (position 6)
                table.insert(wallpaper_submenu, 6,
                    genMenuItem(_("Show weather on sleep screen"), "screensaver_type", "weather")
                )

                logger.dbg("Weather lockscreen: Added weather option to wallpaper menu")
            end
        end

        return result
    end
end

userpatch.registerPatchPluginFunc("weather", patchWeather)
