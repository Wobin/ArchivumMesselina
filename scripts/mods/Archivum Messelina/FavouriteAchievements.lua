local mod = get_mod("Archivum Messelina")
local AchievementUIHelper = require("scripts/managers/achievements/utility/achievement_ui_helper")

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
  local window = 1
 mod:hook_require("scripts/settings/ui/ui_settings", function(settings)
      settings.max_favorite_achievements = mod:get("max_favourites") or 5
  end)
  mod:hook_safe("PenanceOverviewView","_setup_penance_category_buttons", function(self, options)
     mod.categories_tab_bar = self._categories_tab_bar
     setup_bookmarks(self, options)
  end)

  mod:hook_safe("PenanceOverviewView","_cb_on_penance_secondary_pressed", function (self, widget, config)      
 		setup_bookmarks(self, self._category_button_config)
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