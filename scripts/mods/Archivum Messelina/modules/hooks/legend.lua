local mod = get_mod("Archivum Messelina")

mod.register_legend_hooks = function()
	mod:hook("ViewElementInputLegend", "_handle_input", function(func, ...)
		if Managers.ui:view_active("penance_overview_view") then
			if mod.is_writing() or mod.block_next_legend_escape_check then
				mod.block_next_legend_escape_check = false

				return
			end
		end

		if func then
			func(...)
		end
	end)
end
