return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Archivum Messelina` encountered an error loading the Darktide Mod Framework.")

		new_mod("Archivum Messelina", {
			mod_script       = "Archivum Messelina/scripts/mods/Archivum Messelina/Archivum Messelina",
			mod_data         = "Archivum Messelina/scripts/mods/Archivum Messelina/Archivum Messelina_data",
			mod_localization = "Archivum Messelina/scripts/mods/Archivum Messelina/Archivum Messelina_localization",
		})
	end,
	packages = {},
}
