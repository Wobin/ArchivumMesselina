local mod = get_mod("Archivum Messelina")
local CLASSES = CLASSES 

mod.register_view_hooks = function()
	mod:hook_safe("PenanceOverviewView", "init", function(self, settings, context)
		CLASSES.PenanceOverviewView.cb_on_filter = function(self)
			if mod.is_writing() then
				return
			end

			mod.cycleFilter()
			mod.refreshGrid()
		end
	end)

	mod:hook("PenanceOverviewView", "cb_on_filter_changed", function(func, self, ...)
		if mod.is_writing() then
			return
		end

		return func(self, ...)
	end)

	mod:hook("PenanceOverviewView", "cb_on_toggle_penance_appearance", function(func, self, ...)
		if mod.is_writing() then
			return
		end

		return func(self, ...)
	end)

	mod:hook_safe("PenanceOverviewView", "_build_achievements_cache", function(self)
		mod.achievements_by_category = table.clone(self._achievements_by_category)
		mod.player = self:_player()

		if mod.input_field and mod.input_field.content then
			mod.rebuild_search_filtered(mod.input_field.content.input_text)
		end
	end)

	mod:hook_safe("PenanceOverviewView", "on_category_button_pressed", function(self, index)
		mod.stop_writing_safe()
		mod.last_index = index
		mod.view = self
	end)

	mod:hook("PenanceOverviewView", "_add_category_to_penance_grid_layout", function(func, self, layout, show_header, category_id, comparator)
		if not mod.player or not mod.input_field then
			return func(self, layout, show_header, category_id, comparator)
		end

		self._achievements_by_category[category_id] = mod.filterAchievements(category_id, mod.achievements_by_category, self)

		return func(self, layout, show_header, category_id, comparator)
	end)

	mod:hook_safe("PenanceOverviewView", "update", mod.search_results)

	mod:hook_safe("PenanceOverviewView", "_set_handle_navigation", function(self)
		if mod.is_writing() then
			mod.set_navigation_lock(self, true)
		end
	end)

	mod:hook("PenanceOverviewView", "_is_result_presentation_active", function(func, self)
		return self._result_overlay
	end)
end
