--[[
Title: Archivum Messelina
Author: Wobin
Date: 17/03/2026
Repository: https://github.com/Wobin/ArchivumMesselina
Version: 2.5
--]]
local mt = get_mod("modding_tools")
local mod = get_mod("Archivum Messelina")
mod.version = "2.5"
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local TextInputPassTemplates = require("scripts/ui/pass_templates/text_input_pass_templates")
local MemoiseAchievements = mod:persistent_table("MemoiseAchievements", {})
local settings = {filter = 0}

local cycleFilter = function()
  settings.filter = (settings.filter + 1) % 4
end

local isNotFiltered = function()
  return settings.filter == 0
end

local isFilterByEarnt = function()
  return settings.filter == 1
end

local isFilterByUnearnt = function()
  return settings.filter == 2
end

local isUnclaimed = function()
  return settings.filter == 3
end

local onListTab =  function(parent) 
  return parent._selected_top_option_key == "browser" and 
    not parent._wintracks_focused and 
    parent._enter_animation_complete
end


local filter_unclaimed_definition = {
  input_action = "hotkey_menu_special_2",
	display_name = "loc_AM_filter_unclaimed",
	alignment = "right_alignment",
	on_pressed_callback = "cb_on_filter",
  visibility_function  = function(parent) return onListTab(parent) and isUnclaimed() end
  }

local no_filter_definition = {
	input_action = "hotkey_menu_special_2",
	display_name = "loc_AM_no_filter",
	alignment = "right_alignment",
	on_pressed_callback = "cb_on_filter",
  visibility_function  = function(parent) return onListTab(parent) and isNotFiltered() end
}
local filter_completed_definition = {
	input_action = "hotkey_menu_special_2",
	display_name = "loc_AM_filter_completed",
	alignment = "right_alignment",
	on_pressed_callback = "cb_on_filter",
  visibility_function  = function(parent) return onListTab(parent) and isFilterByEarnt() end
}

local filter_unearnt_definition = {
  input_action = "hotkey_menu_special_2",
	display_name = "loc_AM_filter_unearnt",
	alignment = "right_alignment",
	on_pressed_callback = "cb_on_filter",
  visibility_function  = function(parent) return onListTab(parent) and isFilterByUnearnt() end
}

local visibility = function()
   return mod.view and mod.view._selected_top_option_key == "browser" or false 
end

local append_to_view_defs = function(defs)
	if not defs then return end 
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
		position = {x_offset, y_offset, z_offset }
	}

	defs.scenegraph_definition.search_input = {
		vertical_alignment = "top",
		parent = "penance_grid",
		horizontal_alignment = "left",
		size = { 200, 30 },
		position = {x_offset + 100, y_offset, z_offset },    
	}

  
	defs.widget_definitions.search_label = UIWidget.create_definition({
		{
			value = mod:localize("search"),
			value_id = "text",
			pass_type = "text",
			style = table.clone(UIFontSettings.body),
      visibility_function  = visibility
		}
	}, "search_label")  
  local input = table.clone(TextInputPassTemplates.simple_input_field)

  local _, background = table.find_by_key(input, "style_id", "background")
  background.visibility_function = visibility
  
  local _, baseline = table.find_by_key(input, "style_id", "baseline")
  baseline.visibility_function = visibility 

	defs.widget_definitions.search_input = UIWidget.create_definition(input, "search_input")    
end

local is_writing = function()
	return mod.input_field and mod.input_field.content and
		mod.input_field.content.is_writing
end

local set_is_writing = function(value)
	if not mod.input_field or not mod.input_field.content then return end  
	mod.input_field.content.is_writing = value
  --if mod.view and mod.view._categories_tab_bar then mod.view._categories_tab_bar._is_handling_navigation_input = not value end
  --mt:echo(mod.view._categories_tab_bar._is_handling_navigation_input)
end

local refreshGrid = function()
  if mod.view and mod.view._penance_grid then
    mod.view._select_category(mod.view, mod.last_index or 1)
  end
end

local set_navigation_lock = function(view, locked)
  if not view then return end

  if view._categories_tab_bar then
    view._categories_tab_bar:disable_input(locked)
    if view._categories_tab_bar.set_is_handling_navigation_input then
      view._categories_tab_bar:set_is_handling_navigation_input(not locked)
    end
  end

  if view._penance_grid then
    view._penance_grid:disable_input(locked)
  end

  if view._top_panel then
    view._top_panel:disable_input(locked)
    if view._top_panel.set_is_handling_navigation_input then
      view._top_panel:set_is_handling_navigation_input(not locked)
    end
  end
end

local stop_writing_safe = function()
  if not is_writing() then return end
  set_is_writing(false)
  set_navigation_lock(mod.view, false)
end

local is_close_search_keystroke = function(ks)
  if type(ks) == "number" then
    return (Keyboard and ks == Keyboard.ESCAPE) or (Keyboard and ks == Keyboard.ENTER)
  end

  if type(ks) ~= "string" then return false end

  local key = string.lower(ks)
  return key == "escape" or key == "esc" or key == "enter" or key == "return" or key == "\n" or key == "\r"
end

local is_focus_search_shortcut = function(ks)
  if type(ks) ~= "string" then return false end
  return string.lower(ks) == "s"
end

local search_results = function(view, dt, t, input_service)
	if not view then return end
  if not mod.view then mod.view = view end
  if not view._categories_tab_bar then return end
	if not mod.input_field then mod.input_field = view._widgets_by_name["search_input"] end

  if not visibility() then return end
  if not mod.input_field then return end

  -- Defocus when user clicks anywhere outside the input field.
  if is_writing() and input_service and input_service:get("left_pressed") then
    local hotspot = mod.input_field.content and mod.input_field.content.hotspot
    if not (hotspot and hotspot.on_pressed) then
      stop_writing_safe()
      return
    end
  end

	-- Used to focus the input field for next update.
	if mod.set_is_writing_asap then
		set_is_writing(true)
		mod.set_is_writing_asap = false
	end

	-- Make sure we can escape input focus with the Escape key.
	local keystrokes = Keyboard.keystrokes()

	for _, ks in ipairs(keystrokes) do
    if is_writing() and is_close_search_keystroke(ks) then
			set_is_writing(false)
			mod.block_next_legend_escape_check = true      
			return
    elseif not is_writing() and is_focus_search_shortcut(ks) then
			-- Lets us process the 's' keystroke without inputting it into field.
			mod.set_is_writing_asap = true
			return
		end
	end

	-- Only actually update if the text in the field has changed.
	local last_text = mod.input_field.last_text
	local current_text = mod.input_field.content.input_text
	if last_text == current_text then return end
	mod.input_field.last_text = current_text
  
  mod.searchFiltered = nil
  refreshGrid()
  
  if not current_text or current_text == "" then return end
  
  local widgets = view._penance_grid:widgets()
  local term = string.gsub(string.lower(current_text), "%%", "%%%%")
  local searchItems = {}
  for i,v in ipairs(widgets) do    
    local id = v.content.entry.achievement_id
    if id then      
      if not MemoiseAchievements[id] then
        MemoiseAchievements[id] = string.lower(v.content.entry.title .. " " .. v.content.entry.description)
      end
      if string.match(MemoiseAchievements[id], term) then
        searchItems[#searchItems+1] = id
      end
    end
  end    
  mod.searchFiltered = searchItems  
  refreshGrid()
end

local filterAchievements = function(category, achievementList, view)
  local filtered_category = {}
  local player = view:_player()
  for _, v in pairs(achievementList[category] or {}) do
    local earnt = Managers.achievements:achievement_completed(player, v)
    if (earnt and isFilterByEarnt()) or
    (not earnt and isFilterByUnearnt()) or
    (earnt and isUnclaimed() and view:_can_claim_achievement_by_id(v)) or
    isNotFiltered() then
      if not mod.searchFiltered or table.contains(mod.searchFiltered, v) then
        filtered_category[#filtered_category + 1] = v
      end
    end
  end
  return filtered_category
end

mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\FavouriteAchievements]])

mod.on_all_mods_loaded = function()    
  mod:info(mod.version)
  mod:hook_require("scripts/ui/views/penance_overview_view/penance_overview_view_definitions", function(definitions)
      table.array_remove_if(definitions.legend_inputs, function(v) return v.display_name:match("loc_AM_") end)
      table.insert(definitions.legend_inputs, no_filter_definition)
      table.insert(definitions.legend_inputs, filter_completed_definition)
      table.insert(definitions.legend_inputs, filter_unearnt_definition)
      table.insert(definitions.legend_inputs, filter_unclaimed_definition)
      append_to_view_defs(definitions)
  end)

  mod:hook_safe("PenanceOverviewView", "init", function(self, settings, context)
      CLASSES.PenanceOverviewView.cb_on_filter = function(self)            
        cycleFilter()    
        refreshGrid()
      end
  end)
  
  mod:hook_safe("PenanceOverviewView", "_build_achievements_cache", function(self)
      mod.achievements_by_category = table.clone(self._achievements_by_category)      
      mod.player = self:_player()
  end)

  mod:hook_safe("PenanceOverviewView", "on_category_button_pressed", function (self, index)
    -- User explicitly switched tabs: defocus the search field and clear text.
    stop_writing_safe()
    if mod.input_field and mod.input_field.content then
      mod.input_field.content.input_text = ""
      mod.input_field.last_text = nil
      mod.searchFiltered = nil
    end
    mod.last_index = index
    mod.view = self
  end)

  mod:hook("PenanceOverviewView", "_add_category_to_penance_grid_layout", function(func, self, layout, show_header, category_id, comparator)
    if not mod.player or not mod.input_field then return func(self, layout, show_header, category_id, comparator) end
    self._achievements_by_category[category_id] = filterAchievements(category_id, mod.achievements_by_category, self)
    return func(self, layout, show_header, category_id, comparator)
  end)
  
  mod:hook_safe("PenanceOverviewView", "update", search_results)

  -- Re-apply navigation lock after _set_handle_navigation re-enables
  -- elements every frame. This runs while _set_handle_navigation is still on
  -- the call stack so the lock is set before super.update processes elements.
  mod:hook_safe("PenanceOverviewView", "_set_handle_navigation", function(self)
    if is_writing() then
      set_navigation_lock(self, true)
    end
  end)

  mod:hook("PenanceOverviewView", "_is_result_presentation_active", function(func, self)
      return self._result_overlay
  end)

  mod:hook_safe("ViewElementGrid", "set_alpha_multiplier", function(self, multiplier)
      if not mod.view or self ~= mod.view._penance_grid then return end
      local wbn = mod.view._widgets_by_name
      local search_input = wbn["search_input"]
      local visible = multiplier >= 0.8
      search_input.visible = visible
      wbn["search_label"].visible = visible
      search_input.content.hide_background = not visible
      search_input.content.hide_baseline = not visible
  end)

  mod:hook("ViewElementGrid", "cb_on_grid_entry_left_pressed", function(func, self, ...)
    if mod.view and self == mod.view._penance_grid then
      stop_writing_safe()
    end
    if func then return func(self, ...) end
  end)

  mod:hook("ViewElementGrid", "cb_on_grid_entry_double_click_pressed", function(func, self, ...)
    if mod.view and self == mod.view._penance_grid then
      stop_writing_safe()
    end
    if func then return func(self, ...) end
  end)

  -- Prevents Legend hotkeys from triggering while search field is focused.
  mod:hook("ViewElementInputLegend", "_handle_input", function(func, ...)
    if Managers.ui:view_active("penance_overview_view") then 
      if (is_writing() or mod.block_next_legend_escape_check) then
        mod.block_next_legend_escape_check = false
        return
      end    
    end
    if func then func(...) end
  end)

  mod.create_favourites()  
end

