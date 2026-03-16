--[[
Title: Archivum Messelina
Author: Wobin
Date: 17/03/2026
Repository: https://github.com/Wobin/ArchivumMesselina
Version: 2.5
--]]

local mod = get_mod("Archivum Messelina")

mod.version = "2.5"

mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\filtering]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\ui]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\input]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\FavouriteAchievements]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks]])

mod.on_all_mods_loaded = function()
	mod:info(mod.version)
	mod.register_hooks()
end
