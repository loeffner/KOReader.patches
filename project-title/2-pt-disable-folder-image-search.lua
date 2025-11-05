--[[
    This user patch is for use with the Project: Title plugin.
    It requires v3.5.

    This patch disables the search for folder cover images (like cover.jpg,
    folder.png, etc.) in directories, forcing Project: Title to only use
    book covers from the folder's contents to build folder thumbnails.

    By default, Project: Title first searches for dedicated folder cover
    images (cover.jpg, folder.png, etc.) before falling back to building
    a cover from book thumbnails. This patch skips the image file search
    entirely and always builds covers from the actual book covers in the
    folder.

    This can speed up the process significantly, especially on slower devices.
    Obviously, you should only use it, when you don't intend to provide your
    own folder cover images.

    Author: Andreas Lösel
    License: GNU AGPL v3
--]]

local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
  local ptutil = require("ptutil")

  -- Store the original getFolderCover function
  local orig_getFolderCover = ptutil.getFolderCover

  -- Replace getFolderCover to skip the folder image search
  ptutil.getFolderCover = function(filepath, max_img_w, max_img_h)
    -- Simply return nil, which will cause the calling code to fall back
    -- to getSubfolderCoverImages and build the cover from book thumbnails
    return nil
  end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
