local mod = get_mod("Archivum Messelina")

mod:add_global_localize_strings({
    
    loc_AM_filter_unearnt = {
        en = "Filtering by incomplete penances",
        ["zh-cn"] = "按未完成苦修筛选",
      },
    loc_AM_filter_completed = {
      en = "Filtering by completed penances",
      ["zh-cn"] = "按已完成苦修筛选",
    },
    loc_AM_filter_unclaimed = {
      en = "Filtering by unclaimed penances",
      ["zh-cn"] = "按未领取苦修筛选",
    },
    loc_AM_no_filter = {
      en = "Showing all",
      ["zh-cn"] = "显示全部",
      }
    })
  

return {
  mod_name = {
    en = "Archivum Messelina"
    },
	mod_description = {
		en = "Archivum Messelina will allow you to filter/search your penances",
		["zh-cn"] = "梅塞利纳档案馆 - 允许你筛选/搜索苦修",
	},
}
