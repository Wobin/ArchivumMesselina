local mod = get_mod("Archivum Messelina")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
  options = {
		  widgets = {
            {
                setting_id = "max_favourites",
                type = "numeric",
                default_value = 5,
                range = {5, 30},
            }
      }
  }
}
