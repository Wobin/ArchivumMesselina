local mod = get_mod("Archivum Messelina")

mod.is_writing = function()
	return mod.input_field and mod.input_field.content and mod.input_field.content.is_writing
end

mod.set_is_writing = function(value)
	if not mod.input_field or not mod.input_field.content then
		return
	end

	mod.input_field.content.is_writing = value
end

mod.set_navigation_lock = function(view, locked)
	if not view then
		return
	end

	if view._categories_tab_bar and view._categories_tab_bar.disable_input then
		view._categories_tab_bar:disable_input(locked)

		if view._categories_tab_bar.set_is_handling_navigation_input then
			view._categories_tab_bar:set_is_handling_navigation_input(not locked)
		end
	end

	if view._penance_grid and view._penance_grid.disable_input then
		view._penance_grid:disable_input(locked)
	end

	if view._top_panel and view._top_panel.disable_input then
		view._top_panel:disable_input(locked)

		if view._top_panel.set_is_handling_navigation_input and view._top_panel.set_is_handling_navigation_input then
			view._top_panel:set_is_handling_navigation_input(not locked)
		end
	end

	if view._input_legend_element and view._input_legend_element.disable_input then
		view._input_legend_element:disable_input(locked)
	end
end

mod.stop_writing_safe = function()
	if not mod.is_writing() then
		return
	end

	mod.set_is_writing(false)
	mod.set_navigation_lock(mod.view, false)
end

local is_close_search_keystroke = function(ks)
	if type(ks) == "number" then
		return Keyboard and ks == Keyboard.ESCAPE or Keyboard and ks == Keyboard.ENTER
	end

	if type(ks) ~= "string" then
		return false
	end

	local key = string.lower(ks)

	return key == "escape" or key == "esc" or key == "enter" or key == "return" or key == "\n" or key == "\r"
end

local is_focus_search_shortcut = function(ks)
	if type(ks) ~= "string" then
		return false
	end

	return string.lower(ks) == "s"
end

mod.search_results = function(view, dt, t, input_service)
	if not view or not view._categories_tab_bar then
		return
	end

	mod.view = mod.view or view
	mod.input_field = mod.input_field or view._widgets_by_name["search_input"]

	if not mod.visibility() or not mod.input_field then
		return
	end

	if mod.is_writing() and input_service and input_service:get("left_pressed") and
		not (mod.input_field.content and mod.input_field.content.hotspot and mod.input_field.content.hotspot.on_pressed) then
		mod.stop_writing_safe()

		return
	end

	if mod.set_is_writing_asap then
		mod.set_is_writing(true)
		mod.set_is_writing_asap = false
	end

	local keystrokes = Keyboard.keystrokes()

	for _, ks in ipairs(keystrokes) do
		if mod.is_writing() and is_close_search_keystroke(ks) then
			mod.set_is_writing(false)
			mod.block_next_legend_escape_check = true

			return
		elseif not mod.is_writing() and is_focus_search_shortcut(ks) then
			mod.set_is_writing_asap = true

			return
		end
	end

	local last_text = mod.input_field.last_text
	local current_text = mod.input_field.content.input_text

	if last_text == current_text then
		return
	end

	mod.input_field.last_text = current_text
	mod.rebuild_search_filtered(current_text)
	mod.refreshGrid()
end
