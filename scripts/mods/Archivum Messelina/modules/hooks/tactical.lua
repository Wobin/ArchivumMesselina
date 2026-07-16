local mod = get_mod("Archivum Messelina")

local ElementSettings = require("scripts/ui/hud/elements/tactical_overlay/hud_element_tactical_overlay_settings")

local Managers = Managers
local table_clone = table.clone
local table_index_of = table.index_of
local table_insert = table.insert

local BASE_PAGE_KEY = "achievements"
local OVERFLOW_PAGE_PREFIX = "am_penances_"
local FALLBACK_CONTENT_HEIGHT = 550
local MAX_TITLED_PAGE = 15

local overflow_page_key = function(page_index)
	return OVERFLOW_PAGE_PREFIX .. page_index
end

local budget_for = function(self)
	local scenegraph = self._ui_scenegraph
	local content = scenegraph and scenegraph.right_panel_content
	local content_height = content and content.size and content.size[2] or FALLBACK_CONTENT_HEIGHT

	return mod.page_budget(content_height, ElementSettings.right_header_height, ElementSettings.buffer)
end

local collect_favourites = function()
	local save_data = Managers.save:account_data()
	local favourites = save_data.favorite_achievements
	local achievements = Managers.achievements
	local configs = {}

	for i = 1, #favourites do
		local id = favourites[i]

		if achievements:achievement_definition(id) then
			configs[#configs + 1] = {
				blueprint = "achievement",
				id = id,
			}
		end
	end

	return configs, table_clone(favourites), #favourites
end

local restore_page = function(self, page_key, ui_renderer)
	if not page_key or page_key == self._right_panel_key then
		return
	end

	if self._right_panel_entries[page_key] then
		self:_swap_right_grid(page_key, ui_renderer)
	end
end

local measure_heights = function(widgets)
	local heights = {}

	for i = 1, #widgets do
		local content = widgets[i].content

		heights[i] = content and content.size and content.size[2] or 0
	end

	return heights
end

local slice = function(configs, first, last)
	local chunk = {}

	for i = first, last do
		chunk[#chunk + 1] = configs[i]
	end

	return chunk
end

local remove_overflow_pages = function(self, ui_renderer)
	local page_keys = self._am_overflow_pages

	if not page_keys then
		return
	end

	for i = 1, #page_keys do
		local page_key = page_keys[i]

		if self._dynamic_pages[page_key] then
			self._dynamic_pages[page_key] = nil

			self:_rebuild_right_panel_order()
			self:_delete_right_panel_widgets(page_key, ui_renderer)
		end
	end

	self._am_overflow_pages = nil
end

local add_overflow_page = function(self, page_index, configs, ui_renderer)
	local page_key = overflow_page_key(page_index)
	local page = table_clone(ElementSettings.right_panel_grids[BASE_PAGE_KEY])

	page.index = nil

	if page_index <= MAX_TITLED_PAGE then
		page.loc_key = "loc_AM_penance_page_" .. page_index
	end

	self._dynamic_pages[page_key] = page
	self._am_overflow_pages[#self._am_overflow_pages + 1] = page_key

	self:_rebuild_right_panel_order()
	self:_create_right_panel_widgets(page_key, configs, ui_renderer)
end

mod.register_tactical_hooks = function()
	mod:hook("HudElementTacticalOverlay", "_setup_achievements", function(func, self, ui_renderer)
		local viewed_key = self._right_panel_key
		local configs, current, tracked = collect_favourites()

		self._current_achievements = current
		self._tracked_achievements = tracked

		remove_overflow_pages(self, ui_renderer)

		if #configs == 0 then
			self:_delete_right_panel_widgets(BASE_PAGE_KEY, ui_renderer)

			return
		end

		local widgets = self:_create_right_panel_widgets(BASE_PAGE_KEY, configs, ui_renderer)
		local heights = measure_heights(widgets)
		local pages = mod.pack_pages(heights, budget_for(self), ElementSettings.right_grid_spacing[2])

		if #pages < 2 then
			restore_page(self, viewed_key, ui_renderer)

			return
		end

		self:_create_right_panel_widgets(BASE_PAGE_KEY, slice(configs, pages[1].first, pages[1].last), ui_renderer)

		self._am_overflow_pages = {}

		for i = 2, #pages do
			add_overflow_page(self, i, slice(configs, pages[i].first, pages[i].last), ui_renderer)
		end

		restore_page(self, viewed_key, ui_renderer)
	end)

	mod:hook_safe("HudElementTacticalOverlay", "_rebuild_right_panel_order", function(self)
		local page_keys = self._am_overflow_pages

		if not page_keys then
			return
		end

		local order = self._right_panel_order
		local base_index = table_index_of(order, BASE_PAGE_KEY)

		if base_index <= 0 then
			return
		end

		local insert_at = base_index

		for i = 1, #page_keys do
			local page_key = page_keys[i]

			if self._dynamic_pages[page_key] and table_index_of(order, page_key) <= 0 then
				insert_at = insert_at + 1

				table_insert(order, insert_at, page_key)
			end
		end
	end)
end
