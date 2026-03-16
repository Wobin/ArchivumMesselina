local mod = get_mod("Archivum Messelina")

mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\definitions]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\view]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\grid]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\legend]])

mod.register_hooks = function()
	mod.register_definition_hooks()
	mod.register_view_hooks()
	mod.register_grid_hooks()
	mod.register_legend_hooks()

	mod.create_favourites()
end
