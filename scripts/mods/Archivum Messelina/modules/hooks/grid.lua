local mod = get_mod("Archivum Messelina")

mod.register_grid_hooks = function()
	mod:hook_safe("ViewElementGrid", "set_alpha_multiplier", function(self, multiplier)
		if not mod.view or self ~= mod.view._penance_grid then
			return
		end

		local widgets_by_name = mod.view._widgets_by_name
		local search_input = widgets_by_name["search_input"]
		local visible = multiplier >= 0.8

		search_input.visible = visible
		widgets_by_name["search_label"].visible = visible
		search_input.content.hide_background = not visible
		search_input.content.hide_baseline = not visible
	end)

	mod:hook_safe("ViewElementGrid", "cb_on_grid_entry_left_pressed", function(self)
		if mod.view and self == mod.view._penance_grid then
			mod.stop_writing_safe()
		end
	end)

	mod:hook_safe("ViewElementGrid", "cb_on_grid_entry_double_click_pressed", function(self)
		if mod.view and self == mod.view._penance_grid then
			mod.stop_writing_safe()
		end
	end)
end
