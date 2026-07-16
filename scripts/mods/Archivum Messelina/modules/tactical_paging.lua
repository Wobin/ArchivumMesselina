local mod = get_mod("Archivum Messelina")

local math_max = math.max

mod.page_budget = function(content_height, header_height, buffer)
	return math_max(0, content_height - header_height - buffer)
end

mod.pack_pages = function(heights, budget, spacing)
	local pages = {}
	local count = #heights

	if count == 0 or budget <= 0 then
		return pages
	end

	local first = 1
	local used = 0

	for i = 1, count do
		local height = heights[i]
		local gap = i > first and spacing or 0

		if i > first and used + gap + height > budget then
			pages[#pages + 1] = { first = first, last = i - 1 }
			first = i
			used = height
		else
			used = used + gap + height
		end
	end

	pages[#pages + 1] = { first = first, last = count }

	return pages
end
