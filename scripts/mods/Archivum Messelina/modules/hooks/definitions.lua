local mod = get_mod("Archivum Messelina")

mod.register_definition_hooks = function()
	mod:hook_require("scripts/ui/views/penance_overview_view/penance_overview_view_definitions", function(definitions)
		table.array_remove_if(definitions.legend_inputs, function(v)
			return v.display_name:match("loc_AM_")
		end)
		table.insert(definitions.legend_inputs, mod.no_filter_definition)
		table.insert(definitions.legend_inputs, mod.filter_completed_definition)
		table.insert(definitions.legend_inputs, mod.filter_unearnt_definition)
		table.insert(definitions.legend_inputs, mod.filter_unclaimed_definition)
		mod.append_to_view_defs(definitions)
	end)
end
