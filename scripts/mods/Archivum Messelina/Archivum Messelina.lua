--[[
Title: Archivum Messelina
Author: Wobin
Repository: https://github.com/Wobin/ArchivumMesselina
Version: 3.1
--]]

local mod = get_mod("Archivum Messelina")
mod.version = "3.1"

mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\ui]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\input]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\filtering]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\FavouriteAchievements]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks]])

mod.on_all_mods_loaded = function()
	mod:info(mod.version)
	mod.register_hooks()
end
