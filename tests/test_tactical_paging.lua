local module = {}

_G.get_mod = function()
	return module
end

dofile("scripts/mods/Archivum Messelina/modules/tactical_paging.lua")

local failures = 0

local check = function(name, actual, expected)
	if actual ~= expected then
		failures = failures + 1
		print(string.format("FAIL %s: expected %s, got %s", name, tostring(expected), tostring(actual)))
	else
		print(string.format("ok   %s", name))
	end
end

check("budget subtracts header and buffer", module.page_budget(550, 40, 8), 502)
check("budget never negative", module.page_budget(10, 40, 8), 0)

local pages = module.pack_pages({}, 500, 2)

check("empty list yields no pages", #pages, 0)
check("non-positive budget yields no pages", #module.pack_pages({ 50, 50 }, 0, 2), 0)

pages = module.pack_pages({ 100, 100, 100 }, 500, 2)

check("everything fits on one page", #pages, 1)
check("single page starts at 1", pages[1].first, 1)
check("single page ends at 3", pages[1].last, 3)

pages = module.pack_pages({ 100, 100, 100, 100, 100 }, 306, 2)

check("overflow splits into two pages", #pages, 2)
check("page 1 starts at one", pages[1].first, 1)
check("page 1 holds three entries", pages[1].last, 3)
check("page 2 starts at four", pages[2].first, 4)
check("page 2 ends at five", pages[2].last, 5)

pages = module.pack_pages({ 300, 250, 250 }, 502, 2)

check("page 2 packs without a leading gap", #pages, 2)
check("page 2 spans two to three", pages[2].last, 3)

pages = module.pack_pages({ 250, 250 }, 502, 2)

check("exact fit stays on one page", #pages, 1)

pages = module.pack_pages({ 100, 900, 100 }, 500, 2)

check("oversized entry gets its own page", #pages, 3)
check("oversized entry is alone", pages[2].first, 2)
check("oversized entry ends its page", pages[2].last, 2)

if failures > 0 then
	print(string.format("%d failing", failures))
	os.exit(1)
end

print("all passing")
