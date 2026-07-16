# Paged Tracked Penances (Tactical Overlay) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the favourite ("tracked") penances shown on the right of the in-mission tactical overlay across as many pages as they need, cycled with the overlay's existing page-switch input.

**Architecture:** Three DMF hooks on `HudElementTacticalOverlay`. `_setup_achievements` is replaced: it builds every favourite's widget once, measures the resulting variable heights, greedily packs them into pages against the panel's height budget, keeps page 1 on the stock `achievements` key and registers the overflow as `_dynamic_pages` entries. A `hook_safe` on `_rebuild_right_panel_order` splices those page keys back into the panel order, because the stock implementation only preserves live-event dynamic pages. The pure packing arithmetic lives in its own engine-free module so it can be unit-tested offline with LuaJIT.

**Tech Stack:** Lua 5.1 / LuaJIT 2.1, Darktide Mod Framework (DMF), Stingray UI (`HudElementTacticalOverlay`, `UIWidgetGrid`).

**Spec:** `docs/superpowers/specs/2026-07-14-tactical-penance-pages-design.md`

## Global Constraints

- Lua 5.1 (LuaJIT). **No `goto` statements.**
- Cache globals to locals at file scope (`local math_max = math.max`).
- **Do not commit.** Stage changes and report "ready to commit"; the user commits.
- **Do not bump the version** or touch the `.mod` file / Date header. Not in scope.
- **No explanatory comments in source.** Rationale belongs in memory, not in the code. The only permitted comments are the canonical Wobin header block and section-divider titles.
- Localisation strings must contain **no `%` character** — DMF pushes strings through `string.format` and a bare `%` crashes the game.
- Mod folder name and id contain spaces: `Archivum Messelina`. `io_dofile` paths use backslashes in `[[...]]` literals.
- `mod:io_dofile` does **not** cache: each module must be loaded exactly once, from the entry file (`Archivum Messelina.lua`) or from `modules/hooks.lua`, never both.
- Engine gotchas already verified against `tools/output/`:
  - `table.index_of(t, x)` returns **-1** when not found, never nil. Guard with `> 0`.
  - `table.clone` is a **deep** copy.
  - `_delete_right_panel_widgets(key, ui_renderer)` (no third arg) already calls `_switch_right_grid` if the deleted page was the visible one. Do not hand-roll that fallback, and do not pass `is_update`.

All paths below are relative to `mods/Archivum Messelina/`.

---

### Task 1: Pure page-packing arithmetic

Engine-free so it can be tested offline. No `require`, no `Managers`, no widgets.

**Files:**
- Create: `scripts/mods/Archivum Messelina/modules/tactical_paging.lua`
- Create: `tests/test_tactical_paging.lua`

**Interfaces:**
- Produces:
  - `mod.page_budget(content_height: number, header_height: number, buffer: number) -> number` — usable vertical space on one page, never negative.
  - `mod.pack_pages(heights: number[], budget: number, spacing: number) -> {first: number, last: number}[]` — inclusive index ranges, one per page. Empty array when there is nothing to place.

- [ ] **Step 1: Write the failing test**

Create `tests/test_tactical_paging.lua`:

```lua
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

pages = module.pack_pages({ 100, 100, 100 }, 500, 2)

check("everything fits on one page", #pages, 1)
check("single page starts at 1", pages[1].first, 1)
check("single page ends at 3", pages[1].last, 3)

pages = module.pack_pages({ 100, 100, 100, 100, 100 }, 306, 2)

check("overflow splits into two pages", #pages, 2)
check("page 1 holds three entries", pages[1].last, 3)
check("page 2 starts at four", pages[2].first, 4)
check("page 2 ends at five", pages[2].last, 5)

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
```

- [ ] **Step 2: Run test to verify it fails**

Run from `mods/Archivum Messelina/`:

```bash
"$LOCALAPPDATA/Programs/LuaJIT/bin/luajit.exe" tests/test_tactical_paging.lua
```

Expected: FAIL — `cannot open scripts/mods/Archivum Messelina/modules/tactical_paging.lua`.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/mods/Archivum Messelina/modules/tactical_paging.lua`:

```lua
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
```

An entry taller than the whole budget lands on a page by itself: the break only fires when `i > first`, so an oversized entry is always placed, and the next entry then breaks off. That is what stops an empty-chunk loop. It is unreachable today because `init` caps each description at 64px, but a future blueprint change must not be able to hang the HUD.

- [ ] **Step 4: Run test to verify it passes**

```bash
"$LOCALAPPDATA/Programs/LuaJIT/bin/luajit.exe" tests/test_tactical_paging.lua
```

Expected: every line `ok`, final line `all passing`, exit 0.

- [ ] **Step 5: Stage (do not commit)**

```bash
git add "scripts/mods/Archivum Messelina/modules/tactical_paging.lua" tests/test_tactical_paging.lua
```

Report to the user: staged, ready to commit. Do not run `git commit`.

---

### Task 2: Page titles

The overlay header renders `Localize(page.loc_key)`, so each overflow page needs a registered global loc key. 30 favourites at a ~140px worst-case entry against a ~500px budget is at most 7 pages; register 2..8 for headroom.

**Files:**
- Modify: `scripts/mods/Archivum Messelina/Archivum Messelina_localization.lua`

**Interfaces:**
- Consumes: nothing.
- Produces: global loc keys `loc_AM_penance_page_2` … `loc_AM_penance_page_8`, consumed by Task 3 as `"loc_AM_penance_page_" .. page_index`.

- [ ] **Step 1: Add the page-title keys**

In `Archivum Messelina_localization.lua`, inside the existing `mod:add_global_localize_strings({ ... })` call, after the `loc_AM_no_filter` entry, add:

```lua
	loc_AM_penance_page_2 = {
		en = "Penances (2)",
		["zh-cn"] = "苦修 (2)",
		["zh-tw"] = "苦修 (2)",
		ru = "Искупления (2)",
	},
	loc_AM_penance_page_3 = {
		en = "Penances (3)",
		["zh-cn"] = "苦修 (3)",
		["zh-tw"] = "苦修 (3)",
		ru = "Искупления (3)",
	},
	loc_AM_penance_page_4 = {
		en = "Penances (4)",
		["zh-cn"] = "苦修 (4)",
		["zh-tw"] = "苦修 (4)",
		ru = "Искупления (4)",
	},
	loc_AM_penance_page_5 = {
		en = "Penances (5)",
		["zh-cn"] = "苦修 (5)",
		["zh-tw"] = "苦修 (5)",
		ru = "Искупления (5)",
	},
	loc_AM_penance_page_6 = {
		en = "Penances (6)",
		["zh-cn"] = "苦修 (6)",
		["zh-tw"] = "苦修 (6)",
		ru = "Искупления (6)",
	},
	loc_AM_penance_page_7 = {
		en = "Penances (7)",
		["zh-cn"] = "苦修 (7)",
		["zh-tw"] = "苦修 (7)",
		ru = "Искупления (7)",
	},
	loc_AM_penance_page_8 = {
		en = "Penances (8)",
		["zh-cn"] = "苦修 (8)",
		["zh-tw"] = "苦修 (8)",
		ru = "Искупления (8)",
	},
```

Remember the trailing comma on the `loc_AM_no_filter` entry that previously ended the table.

None of these strings contain a `%`.

- [ ] **Step 2: Syntax-check**

```bash
"$LOCALAPPDATA/Programs/LuaJIT/bin/luajit.exe" -bl "scripts/mods/Archivum Messelina/Archivum Messelina_localization.lua" > /dev/null && echo OK
```

Expected: `OK`.

- [ ] **Step 3: Stage (do not commit)**

```bash
git add "scripts/mods/Archivum Messelina/Archivum Messelina_localization.lua"
```

---

### Task 3: The tactical overlay hooks

**Files:**
- Create: `scripts/mods/Archivum Messelina/modules/hooks/tactical.lua`
- Modify: `scripts/mods/Archivum Messelina/modules/hooks.lua`
- Modify: `scripts/mods/Archivum Messelina/Archivum Messelina.lua`

**Interfaces:**
- Consumes: `mod.page_budget`, `mod.pack_pages` (Task 1); loc keys `loc_AM_penance_page_N` (Task 2).
- Produces: `mod.register_tactical_hooks()`, called from `mod.register_hooks()`.

Per-element state is stored on the element itself as `self._am_overflow_pages` (an array of our active page keys, or nil). It dies with the HUD element, so no cross-mission leakage and no teardown hook needed.

- [ ] **Step 1: Create the hooks module**

Create `scripts/mods/Archivum Messelina/modules/hooks/tactical.lua`:

```lua
local mod = get_mod("Archivum Messelina")

local ElementSettings = require("scripts/ui/hud/elements/tactical_overlay/hud_element_tactical_overlay_settings")

local Managers = Managers
local table_clone = table.clone
local table_index_of = table.index_of

local BASE_PAGE_KEY = "achievements"
local OVERFLOW_PAGE_PREFIX = "am_penances_"
local FALLBACK_CONTENT_HEIGHT = 550

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
	local current = {}

	for i = 1, #favourites do
		local id = favourites[i]

		if achievements:achievement_definition(id) then
			configs[#configs + 1] = {
				blueprint = "achievement",
				id = id,
			}
			current[i] = id
		end
	end

	return configs, current, #favourites
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
	page.loc_key = "loc_AM_penance_page_" .. page_index

	self._dynamic_pages[page_key] = page
	self._am_overflow_pages[#self._am_overflow_pages + 1] = page_key

	self:_rebuild_right_panel_order()
	self:_create_right_panel_widgets(page_key, configs, ui_renderer)
end

mod.register_tactical_hooks = function()
	mod:hook("HudElementTacticalOverlay", "_setup_achievements", function(func, self, ui_renderer)
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
			return
		end

		self:_create_right_panel_widgets(BASE_PAGE_KEY, slice(configs, pages[1].first, pages[1].last), ui_renderer)

		self._am_overflow_pages = {}

		for i = 2, #pages do
			add_overflow_page(self, i, slice(configs, pages[i].first, pages[i].last), ui_renderer)
		end
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

				table.insert(order, insert_at, page_key)
			end
		end
	end)
end
```

`table_index_of` returns -1 when absent, hence the `<= 0` guards rather than `not`. The stock `_rebuild_right_panel_order` rebuilds the order from live-event pages plus the static list and drops everything else, which is exactly why this `hook_safe` has to put our keys back after it runs.

- [ ] **Step 2: Register the hooks**

In `scripts/mods/Archivum Messelina/modules/hooks.lua`, add the `io_dofile` alongside the existing ones and the call inside `mod.register_hooks`:

```lua
local mod = get_mod("Archivum Messelina")

mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\definitions]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\view]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\grid]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\legend]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks\tactical]])

mod.register_hooks = function()
	mod.register_definition_hooks()
	mod.register_view_hooks()
	mod.register_grid_hooks()
	mod.register_legend_hooks()
	mod.register_tactical_hooks()

	mod.create_favourites()
end
```

- [ ] **Step 3: Load the paging module from the entry file**

In `scripts/mods/Archivum Messelina/Archivum Messelina.lua`, add the `tactical_paging` load **before** the `hooks` load, since `hooks/tactical.lua` calls `mod.pack_pages`. Load it exactly once — `io_dofile` does not cache, and a second load would create a second copy.

```lua
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\ui]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\input]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\filtering]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\tactical_paging]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\FavouriteAchievements]])
mod:io_dofile([[Archivum Messelina\scripts\mods\Archivum Messelina\modules\hooks]])
```

- [ ] **Step 4: Syntax-check every touched file**

```bash
LJ="$LOCALAPPDATA/Programs/LuaJIT/bin/luajit.exe"
for f in "scripts/mods/Archivum Messelina/Archivum Messelina.lua" \
         "scripts/mods/Archivum Messelina/modules/hooks.lua" \
         "scripts/mods/Archivum Messelina/modules/hooks/tactical.lua" \
         "scripts/mods/Archivum Messelina/modules/tactical_paging.lua"; do
  "$LJ" -bl "$f" > /dev/null && echo "OK   $f" || echo "FAIL $f"
done
```

Expected: `OK` for all four.

- [ ] **Step 5: Re-run the unit tests**

```bash
"$LOCALAPPDATA/Programs/LuaJIT/bin/luajit.exe" tests/test_tactical_paging.lua
```

Expected: `all passing`.

- [ ] **Step 6: Stage (do not commit)**

```bash
git add "scripts/mods/Archivum Messelina/modules/hooks/tactical.lua" \
        "scripts/mods/Archivum Messelina/modules/hooks.lua" \
        "scripts/mods/Archivum Messelina/Archivum Messelina.lua"
```

---

### Task 4: In-game verification

Nothing above proves the feature works — the packing is tested, the hooks are not. This task is the actual evidence. Do not report the feature as working until these pass.

**Files:** none changed.

- [ ] **Step 1: Confirm the mod loads clean**

Launch the game with the mod enabled. Check the console / `console_logs` for `Archivum Messelina` errors and confirm the `mod:info(mod.version)` line appears.

Expected: version logged, no hook errors. A failure here most likely means the `HudElementTacticalOverlay` string hook never resolved.

- [ ] **Step 2: Baseline — 5 favourites**

With the default `max_favourites` (5), favourite 5 penances, start a mission, hold Tab.

Expected: one `PENANCES` page, no extra tabs, identical to unmodded. This is the regression guard: users who never raise the setting must see no change.

- [ ] **Step 3: Overflow — 30 favourites**

Set `max_favourites` to 30 in Mod Options, favourite 30 penances, start a mission, hold Tab, cycle the right panel.

Expected: `PENANCES`, then `PENANCES (2)` … up to roughly `(7)`, then on through the other panels and back around. On every page, no entry is clipped by or hangs off the panel edge.

- [ ] **Step 4: Shrink mid-mission**

While in the mission with 30 favourites paged, un-favourite penances down to 5 (or clear them entirely).

Expected: the overflow pages disappear and the panel is never left showing a page that no longer exists. If the panel was on `PENANCES (4)` when it vanished, the engine's `_switch_right_grid` should move it somewhere valid.

- [ ] **Step 5: Zero favourites**

Un-favourite everything, hold Tab.

Expected: no penance page at all, and the other panels (contracts, events) still cycle normally.

- [ ] **Step 6: Scale and resolution**

Repeat step 3 at a non-default HUD scale and a non-16:9 resolution.

Expected: still no overflow. The budget is read from the scenegraph in virtual workspace units, so this should hold; if it does not, the budget source is wrong.

- [ ] **Step 7: Report**

Report results to the user with what was actually observed. If everything passes, state that the work is staged and ready to commit. Do not commit.

---

## Notes for the implementer

- `_setup_achievements` runs only when the favourites array changes (`_update_achievements` diffs it), never per frame, which is why building the widgets twice — once to measure, once per page — is acceptable.
- Heights are only valid for the `ui_renderer` handed to the hook. Do not cache a renderer.
- The mod's existing bugfixes to the penance browser view are unrelated to this work but may be sitting uncommitted in the same tree. Do not fold them into this feature's staging.
