local mod = get_mod("Archivum Messelina")

mod:add_global_localize_strings({

	loc_AM_filter_unearnt = {
		en = "Filtering by incomplete penances",
		["zh-cn"] = "按未完成苦修筛选",
		ru = "Фильтрация по незавершённым Искуплениям",
	},
	loc_AM_filter_completed = {
		en = "Filtering by completed penances",
		["zh-cn"] = "按已完成苦修筛选",
		ru = "Фильтрация по завершённым Искуплениям",
	},
	loc_AM_filter_unclaimed = {
		en = "Filtering by unclaimed penances",
		["zh-cn"] = "按未领取苦修筛选",
		ru = "Фильтрация по не забранным Искуплениям",
	},
	loc_AM_no_filter = {
		en = "Showing all",
		["zh-cn"] = "显示全部",
		ru = "Показать все",
	}
	})


return {
	mod_name = {
		en = "Archivum Messelina",
		["zh-cn"] = "苦修筛选 - 梅塞利纳档案馆",
		ru = "Архивум Месселина",
	},
	mod_description = {
		en = "Archivum Messelina will allow you to filter/search your penances",
		["zh-cn"] = "梅塞利纳档案馆 - 允许你筛选/搜索苦修",
		ru = "Archivum Messelina - позволит вам фильтровать/искать ваши Искупления",
	},
  max_favourites = {
    en = "Maximum number of penance favourites",
    ["zh-cn"] = "苦修最多追踪数量",
    ru = "Максимальное количество избранных Искуплений"
    },
  search = {
    en = "Search: ",
    ["zh-cn"] = "搜索：",
    ru = "Поиск: "
    }
}
