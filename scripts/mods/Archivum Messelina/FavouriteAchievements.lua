local mod = get_mod("Archivum Messelina")
local AchievementUIHelper = require("scripts/managers/achievements/utility/achievement_ui_helper")

local window = 1


local setup_bookmarks = function(self, options)
 if not mod.achievements_by_category then return end
    for i = 1, #options do
      local category_id = options[i].category_id
      local listing = table.clone(mod.achievements_by_category[category_id] or {})
      local children = options[i].child_categories             
      if children then          
        for _, c in ipairs(children) do                                  
          table.append(listing, mod.achievements_by_category[c] or {})
        end          
      end
      for _,v in ipairs(listing) do
        if AchievementUIHelper.is_favorite_achievement(v) then
          self._widget_content_by_category[category_id].has_favourites = true
          break
        end
        self._widget_content_by_category[category_id].has_favourites = false
      end        
    end
end
mod.create_favourites = function()    
 mod:hook_require("scripts/settings/ui/ui_settings", function(settings)
      settings.max_favorite_achievements = mod:get("max_favourites") or 5
  end)

  mod:hook("HudElementTacticalOverlay", "_create_right_panel_widgets", function (func, self, page_key, configs, ui_renderer)
    if page_key ~= "achievements" or #configs < 6 then return func(self, page_key, configs, ui_renderer) end
    -- Get me a two cloned table to map a window to    
    local padded = table.append(table.clone(configs), table.clone(configs))
    mod.achivementCount = #configs    
    local current = table.slice( padded, window, 5)    
    return func(self, page_key, current, ui_renderer)
  end)

  mod:hook_safe("PenanceOverviewView","_setup_penance_category_buttons", function(self, options)
     setup_bookmarks(self, options)
  end)

  mod:hook_safe("PenanceOverviewView","_cb_on_penance_secondary_pressed", function (self, widget, config)      
 		setup_bookmarks(self, self._category_button_config)
  end)

  mod:hook_safe("HudElementTacticalOverlay", "update", function (self, dt, t, ui_renderer, render_settings, input_service)
    local is_input_blocked = Managers.ui:using_input(true)
    
    input_service = is_input_blocked and input_service:null_service() or Managers.input:get_input_service("Ingame")

    if not mod.overlay then mod.overlay = self end
    if not input_service:is_null_service() and input_service:get("tactical_overlay_hold") then
      local view_service = Managers.input:get_input_service("View")
      if input_service:get("wield_scroll_down") or view_service:get("navigate_up_pressed") then        
        if window == mod.achivementCount then 
          window = 1
        else
          window = window + 1
        end
      end
      if input_service:get("wield_scroll_up") or view_service:get("navigate_down_pressed") then
        if window == 1 then window = mod.achivementCount
        else
          window = window - 1
        end
      end
      mod.overlay._current_achievements = nil
    end
  end)
  mod:hook("ViewElementTabMenu", "add_entry", function(func, self, display_name, on_pressed_callback, pass_template, optional_display_icon, optional_update_function, no_localization)
      if self:parent().view_name ~= "penance_overview_view" then 
        return func( self, display_name, on_pressed_callback, pass_template, optional_display_icon, optional_update_function, no_localization) 
      end            
       pass_template[10] = {
                              value = "content/ui/materials/icons/generic/bookmark",
                              pass_type = "texture",
                              style = {
                                horizontal_alignment = "left",
                                vertical_alignment = "top",
                                color = Color.terminal_corner_selected(255, true),
                                default_color = Color.terminal_frame(180, true),
                                selected_color = Color.terminal_frame_selected(180, true),
                                disabled_color = Color.ui_grey_medium(180, true),
                                hover_color = Color.terminal_frame_hover(180, true),
                                size = {
                                  20,
                                  20
                                },
                                offset = {
                                  0,
                                  0,
                                  4
                                }
                              },
                              visibility_function = function (content, style)
                                return content.has_favourites
                              end
                            }      

      return func( self, display_name, on_pressed_callback, pass_template, optional_display_icon, optional_update_function, no_localization)
  end)

end