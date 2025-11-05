# KOReader Userpatches

This repository contains userpatches for customizing KOReader and its plugins.

The patches currently target:
- [Project: Title](https://github.com/joshuacant/ProjectTitle) plugin

**Note:** The weather lockscreen patch has been converted to a standalone plugin: [loeffner/WeatherLockscreen](https://github.com/loeffner/WeatherLockscreen)

## Installation

See the [KOReader documentation](https://koreader.rocks/user_guide/#L2-userpatches) for more information.

1. **Create a directory named patches under koreader directory on your device**

2. **Download and put the patch file with .lua extension in this patches directory**
   - You may want to modify the patch for your use-case.

3. **Restart KOReader:**
   - You can see the list and status of your user patches and enable/disable them in `Patch Management`.


## [Project: Title Patches](project-title)
This folder contains various patches to tweak the already awesome [Project: Title](https://github.com/joshuacant/ProjectTitle) plugin.

There are screenshots and descriptions [here](project-title/README.md).

It contains:

- [🞂 2-pt-modify-font-sizes.lua](project-title/2-pt-modify-font-sizes.lua)
- [🞂 2-pt-disable-progress-string.lua](project-title/2-pt-disable-progress-string.lua)
- [🞂 2-pt-limit-tags.lua](project-title/2-pt-limit-tags.lua)
- [🞂 2-pt-disable-folder-nbitems-overlay.lua](project-title/2-pt-disable-folder-nbitems-overlay.lua)
- [🞂 2-pt-disable-folder-image-search.lua](project-title/2-pt-disable-folder-image-search.lua)
- [🞂 2-pt-modify-item-limits.lua](project-title/2-pt-modify-item-limits.lua)
- [🞂 2-pt-modify-progressbar-max-width.lua](project-title/2-pt-modify-progressbar-max-width.lua)
- [🞂 2-pt-modify-series-format.lua](project-title/2-pt-modify-series-format.lua)


## Weather Lockscreen Plugin

**The Weather Lockscreen patch has been converted to a standalone plugin and moved to its own repository:**

### **[loeffner/WeatherLockscreen](https://github.com/loeffner/WeatherLockscreen)** 🌤️

This is now a full-featured KOReader plugin that displays beautiful weather information on your sleep screen, with multiple display formats and easy configuration - no need to edit source code!


## License
[GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.de.html)

## Author

Andreas Lösel

## Disclaimer

Using these patches may slow down your device or even break things.
Please use them at your own risk.

Feel free to contact me if you have questions or suggestions.

## Links

- [KOReader](https://github.com/koreader/koreader)
- [KOReader Userpatches Documentation](https://github.com/koreader/koreader/wiki/User-patches)
- [Project: Title](https://github.com/joshuacant/ProjectTitle)
- [WeatherLockscreen Plugin](https://github.com/loeffner/WeatherLockscreen) - Standalone weather lockscreen plugin

### More User Patches
- [joshuacant/KOReader.patches](https://github.com/joshuacant/KOReader.patches)
- [sebdelsol/KOReader.patches](https://github.com/sebdelsol/KOReader.patches)
