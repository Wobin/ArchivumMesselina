local mod = get_mod("Archivum Messelina")

mod:add_global_localize_strings({
    loc_AM_filter_unearnt = {
        en = "Filtering by incomplete penances"
      },
    loc_AM_filter_completed = {
      en = "Filtering by completed penances"
    },
    loc_AM_filter_unclaimed = {
      en = "Filtering by unclaimed penances"
    },
    loc_AM_no_filter = {
      en = "Showing all"
      }
    })
  

return {
	mod_description = {
		en = "Archivum Messelina will allow you to filter/search your penances",
	},
}
