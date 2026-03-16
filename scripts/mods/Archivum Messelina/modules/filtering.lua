local mod = get_mod("Archivum Messelina")

local AchievementUIHelper = require("scripts/managers/achievements/utility/achievement_ui_helper")
local MemoiseAchievements = mod:persistent_table("MemoiseAchievements", {})

local Managers = Managers

mod._filter_settings = mod._filter_settings or { filter = 0 }

local settings = mod._filter_settings

mod.cycleFilter = function()
	settings.filter = (settings.filter + 1) % 4
end

mod.isNotFiltered = function()
	return settings.filter == 0
end

mod.isFilterByEarnt = function()
	return settings.filter == 1
end

mod.isFilterByUnearnt = function()
	return settings.filter == 2
end

mod.isUnclaimed = function()
	return settings.filter == 3
end

mod.achievement_matches_filters = function(view, achievement_id)
	local player = view:_player()
	local earnt = Managers.achievements:achievement_completed(player, achievement_id)

	local passes_state_filter = (earnt and mod.isFilterByEarnt()) or
		(not earnt and mod.isFilterByUnearnt()) or
		(earnt and mod.isUnclaimed() and view:_can_claim_achievement_by_id(achievement_id)) or
		mod.isNotFiltered()

	if not passes_state_filter then
		return false
	end

	return not mod.searchFilteredSet or mod.searchFilteredSet[achievement_id] == true
end

local get_search_index_text = function(achievement_id)
	if MemoiseAchievements[achievement_id] then
		return MemoiseAchievements[achievement_id]
	end

	local achievement_definition = Managers.achievements:achievement_definition(achievement_id)

	if not achievement_definition then
		MemoiseAchievements[achievement_id] = ""

		return ""
	end

	local title = AchievementUIHelper.localized_title(achievement_definition) or ""
	local description = AchievementUIHelper.localized_description(achievement_definition, true) or ""
	local searchable = string.lower(title .. " " .. description)

	MemoiseAchievements[achievement_id] = searchable

	return searchable
end

mod.rebuild_search_filtered = function(term)
	mod.searchFiltered = nil
	mod.searchFilteredSet = nil

	if not term or term == "" or not mod.achievements_by_category then
		return
	end

	local escaped_term = string.gsub(string.lower(term), "%%", "%%%%")
	local search_items = {}
	local search_set = {}

	for _, category_achievements in pairs(mod.achievements_by_category) do
		for _, achievement_id in ipairs(category_achievements or {}) do
			if not search_set[achievement_id] then
				local searchable = get_search_index_text(achievement_id)

				if searchable ~= "" and string.match(searchable, escaped_term) then
					search_items[#search_items + 1] = achievement_id
					search_set[achievement_id] = true
				end
			end
		end
	end

	mod.searchFiltered = search_items
	mod.searchFilteredSet = search_set
end

mod.filterAchievements = function(category, achievementList, view)
	local filtered_category = {}

	for _, achievement_id in pairs(achievementList[category] or {}) do
		if mod.achievement_matches_filters(view, achievement_id) then
			filtered_category[#filtered_category + 1] = achievement_id
		end
	end

	return filtered_category
end

mod.update_category_tab_counts = function(view)
	if not view or not view._category_button_config or not view._widget_content_by_category or not mod.achievements_by_category then
		return
	end

	local player = view:_player()

	for _, option in ipairs(view._category_button_config) do
		local total_count = 0
		local completed_count = 0
		local unclaimed_count = 0
		local favorite_count = 0
		local categories = { option.category_id }

		for i = 1, #(option.child_categories or {}) do
			categories[#categories + 1] = option.child_categories[i]
		end

		for _, category_id in ipairs(categories) do
			for _, achievement_id in ipairs(mod.achievements_by_category[category_id] or {}) do
				if mod.achievement_matches_filters(view, achievement_id) then
					total_count = total_count + 1

					if Managers.achievements:achievement_completed(player, achievement_id) then
						completed_count = completed_count + 1
					end

					if view:_can_claim_achievement_by_id(achievement_id) then
						unclaimed_count = unclaimed_count + 1
					end

					if view:is_favorite_achievement(achievement_id) then
						favorite_count = favorite_count + 1
					end
				end
			end
		end

		local entry_content = view._widget_content_by_category[option.category_id]

		if entry_content then
			entry_content.text_counter = string.format("%d/%d", completed_count, total_count)
			entry_content.has_unclaimed_penances = unclaimed_count > 0
			entry_content.has_favorite_penances = favorite_count > 0
		end
	end
end

mod.refreshGrid = function()
	if mod.view and mod.view._penance_grid then
		mod.view._select_category(mod.view, mod.last_index or 1)
		mod.update_category_tab_counts(mod.view)
	end
end
