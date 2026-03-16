local mod = get_mod("Archivum Messelina")

local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local TextInputPassTemplates = require("scripts/ui/pass_templates/text_input_pass_templates")

local onListTab = function(parent)
	return parent._selected_top_option_key == "browser" and
		not parent._wintracks_focused and
		parent._enter_animation_complete
end

mod.visibility = function()
	return mod.view and mod.view._selected_top_option_key == "browser" or false
end

mod.filter_unclaimed_definition = {
	input_action = "hotkey_menu_special_2",
	display_name = "loc_AM_filter_unclaimed",
	alignment = "right_alignment",
	on_pressed_callback = "cb_on_filter",
	visibility_function = function(parent)
		return onListTab(parent) and mod.isUnclaimed()
	end,
}

mod.no_filter_definition = {
	input_action = "hotkey_menu_special_2",
	display_name = "loc_AM_no_filter",
	alignment = "right_alignment",
	on_pressed_callback = "cb_on_filter",
	visibility_function = function(parent)
		return onListTab(parent) and mod.isNotFiltered()
	end,
}

mod.filter_completed_definition = {
	input_action = "hotkey_menu_special_2",
	display_name = "loc_AM_filter_completed",
	alignment = "right_alignment",
	on_pressed_callback = "cb_on_filter",
	visibility_function = function(parent)
		return onListTab(parent) and mod.isFilterByEarnt()
	end,
}

mod.filter_unearnt_definition = {
	input_action = "hotkey_menu_special_2",
	display_name = "loc_AM_filter_unearnt",
	alignment = "right_alignment",
	on_pressed_callback = "cb_on_filter",
	visibility_function = function(parent)
		return onListTab(parent) and mod.isFilterByUnearnt()
	end,
}

mod.append_to_view_defs = function(defs)
	if not defs then
		return
	end

	defs.scenegraph_definition = defs.scenegraph_definition or {}
	defs.widget_definitions = defs.widget_definitions or {}

	local x_offset = 10
	local y_offset = 53
	local z_offset = 25

	defs.scenegraph_definition.search_label = {
		vertical_alignment = "top",
		parent = "penance_grid",
		horizontal_alignment = "left",
		size = { 100, 30 },
		position = { x_offset, y_offset, z_offset },
	}

	defs.scenegraph_definition.search_input = {
		vertical_alignment = "top",
		parent = "penance_grid",
		horizontal_alignment = "left",
		size = { 200, 30 },
		position = { x_offset + 100, y_offset, z_offset },
	}

	defs.widget_definitions.search_label = UIWidget.create_definition({
		{
			value = mod:localize("search"),
			value_id = "text",
			pass_type = "text",
			style = table.clone(UIFontSettings.body),
			visibility_function = mod.visibility,
		},
	}, "search_label")

	local input = table.clone(TextInputPassTemplates.simple_input_field)
	local _, background = table.find_by_key(input, "style_id", "background")

	background.visibility_function = mod.visibility

	local _, baseline = table.find_by_key(input, "style_id", "baseline")

	baseline.visibility_function = mod.visibility
	defs.widget_definitions.search_input = UIWidget.create_definition(input, "search_input")
end
