local mod = get_mod("Archivum Messelina")

mod:add_global_localize_strings({

	loc_AM_filter_unearnt = {
		en = "Filtering by incomplete penances",
		["zh-cn"] = "按未完成苦修筛选",
		ru = "Фильтрация по незавершённым Искуплениям",
		["zh-tw"] = "根據未完成苦修篩選",
	},
	loc_AM_filter_completed = {
		en = "Filtering by completed penances",
		["zh-cn"] = "按已完成苦修筛选",
		ru = "Фильтрация по завершённым Искуплениям",
		["zh-tw"] = "根據已完成苦修篩選",
	},
	loc_AM_filter_unclaimed = {
		en = "Filtering by unclaimed penances",
		["zh-cn"] = "按未领取苦修筛选",
		["zh-tw"] = "根據未領取苦修篩選",
		ru = "Фильтрация по незабранным Искуплениям",
	},
	loc_AM_no_filter = {
		en = "Showing all",
		["zh-cn"] = "显示全部",
		ru = "Показать все",
		["zh-tw"] = "顯示全部",
	}
	})


return {
	mod_name = {
		en = "Archivum Messelina",
		["zh-cn"] = "苦修筛选 - 梅塞利纳档案馆",
		ru = "Архивум Месселина",
		["zh-tw"] = "苦修篩選 - 梅塞利納檔案館",
	},
	mod_description = {
		en = "Archivum Messelina will allow you to filter/search your penances",
		["zh-cn"] = "梅塞利纳档案馆 - 允许你筛选/搜索苦修",
		ru = "Archivum Messelina - позволит вам фильтровать/искать ваши Искупления",
		["zh-tw"] = "梅塞利納檔案館 - 允許你篩選/搜尋你的苦修",
	},
	max_favourites = {
		en = "Maximum number of penance favourites",
		["zh-cn"] = "苦修最多追踪数量",
		["zh-tw"] = "最多可追蹤的苦修數量",
		ru = "Максимальное количество избранных Искуплений"
	},
	search = {
		en = "Search: ",
		["zh-cn"] = "搜索：",
		["zh-tw"] = "搜尋：",
		ru = "Поиск: "
	}
}
