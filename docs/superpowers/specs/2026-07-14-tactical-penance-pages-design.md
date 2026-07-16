# Paged tracked penances in the tactical overlay

Date: 2026-07-14
Mod: Archivum Messelina
Status: approved design, not yet implemented

## Problem

Archivum Messelina raises `UISettings.max_favorite_achievements` from the stock 5 to as
many as 30 (the `max_favourites` setting).

The in-mission tactical overlay (Tab) already renders the favourite penances on the right
hand side: `HudElementTacticalOverlay._setup_achievements` reads
`Managers.save:account_data().favorite_achievements` and builds one `achievement` blueprint
entry per favourite, all on a single page keyed `achievements`.

That page has no pagination and no scrollbar. `_update_right_grid_size` sizes the panel
background to `grid:length() + buffer` with no clamp, so once the favourites exceed the
panel's height budget the list simply runs off the panel. A user who raises
`max_favourites` to 30 cannot see most of what they track.

## Goal

Split the favourites across as many pages as they need, and let the player cycle those
pages with the overlay's existing right-panel page-switch input.

Non-goals: changing the appearance of an individual entry, filtering or sorting the
favourites, touching the penance browser view, or adding a new keybind.

## Key engine facts this design relies on

All line numbers are into `tools/output/ui/hud/elements/tactical_overlay/`.

- `HudElementTacticalOverlay` is declared with `class(...)`, so DMF string-form hooks
  resolve against it.
- `_setup_achievements` (`hud_element_tactical_overlay.lua:1580`) is the single place the
  favourites are turned into widgets. It is driven from `_update_achievements` (`:1628`),
  which fires only when the favourites array actually differs from the cached
  `_current_achievements` (`table.array_equals` diff). It is therefore not a per-frame path.
- `_create_right_panel_widgets(page_key, configs, ui_renderer)` (`:1319`) creates one widget
  per config, runs the blueprint's `init`, and stores the result in
  `_right_panel_entries[page_key]`.
- `Blueprints.achievement.size` is `{ right_grid_width, 0 }`. The height is **0** in the
  blueprint; `init` computes `widget.content.size[2]` per entry from the wrapped title and
  description text plus an optional progress bar. **Entries are variable height**, so the
  number that fits on a page cannot be a constant and must be measured.
- The measured height is final after `init`. The blueprint's `update` rewrites only the
  progress text and the progress bar's *width* (`size[1]`), and `complete` only recolours;
  neither ever writes `content.size[2]` or any `offset[2]`. Measuring immediately after
  `_create_right_panel_widgets` is therefore sound.
- `init` measures with `Text.text_height(ui_renderer, ...)`, so heights are only valid for
  the renderer passed in. The measure pass must use the `ui_renderer` the hook was handed,
  never a cached one.
- Entry height is bounded: `init` truncates the description with an ellipsis until it fits
  `ElementSettings.max_penance_description_height` (64). Worst case is roughly title + 64 +
  progress bar + progress text + buffers, around 140px, against a budget near 500px. So 30
  favourites lands at roughly 4-7 pages, and no single entry can ever exceed one page.
- Extra pages are a supported engine concept. The live-event code (`:1429-1449`) registers
  one by cloning a page table into `self._dynamic_pages[page_key]`, calling
  `_rebuild_right_panel_order()`, then `_create_right_panel_widgets(...)`. `_get_page`
  (`:1116`) resolves `grid_overrides` then `dynamic_pages` then the static
  `ElementSettings.right_panel_grids`.
- `_switch_right_grid` (`:1642`) — the existing page-cycle input — walks
  `self._right_panel_order` and stops on any key that has an entry in
  `_right_panel_entries`. Our pages therefore need no input handling and no custom tab bar;
  they inherit both.
- **Trap:** `_rebuild_right_panel_order` (`:1528`) reconstructs the order from live-event
  dynamic pages plus `ElementSettings.right_panel_order` only. It silently drops any
  dynamic page that is not a live-event page. Our pages must splice themselves back in.
- The header title is `Localize(selected_page.loc_key)` (`:1267`), so a page can be titled
  with any loc key the mod registers globally.
- `_remove_live_event_page` (`:1514`) is the teardown template: nil the `_dynamic_pages`
  entry, rebuild the order, delete the widgets.

## Design

A new module `scripts/mods/Archivum Messelina/modules/hooks/tactical.lua`, exposing
`mod.register_tactical_hooks()`, called from `modules/hooks.lua` next to the existing
view/grid/legend registrations. Loc keys are added to the existing localization file.
Nothing in the penance browser view changes.

### Page keys

Page 1 stays on the stock `achievements` key, so a user whose favourites fit sees exactly
today's behaviour and today's page ordering. Overflow pages are keyed `am_penances_2`,
`am_penances_3`, and so on.

### Hook 1: `_setup_achievements` (full hook, body replaced)

1. Read `account_data().favorite_achievements`, skipping ids with no
   `Managers.achievements:achievement_definition(id)` — same filter as stock.
2. If the list is empty, delete the `achievements` page widgets and all of our overflow
   pages, then return. (Stock's empty path, plus our cleanup.)
3. Build every entry once by calling `_create_right_panel_widgets("achievements", configs,
   ui_renderer)` with the full config list. This runs each blueprint `init`, which is what
   populates `widget.content.size[2]`.
4. Read the heights back out of `_right_panel_entries["achievements"]` and pack the configs
   greedily into chunks: accumulate `height + spacing` until adding the next entry would
   exceed the budget, then start a new chunk. An entry taller than a whole page gets its own
   page rather than being dropped — unreachable today given the 64px description cap, but it
   keeps a future blueprint change from spinning into an empty-chunk loop.
5. If there is exactly one chunk, we are done — the page built in step 3 is already correct.
   Tear down any overflow pages left from a previous, longer favourites list and return.
6. Otherwise re-create the `achievements` page with chunk 1, and for each remaining chunk
   register a dynamic page (clone of `ElementSettings.right_panel_grids.achievements`, with
   `index = nil` and our numbered `loc_key`), call `_rebuild_right_panel_order()`, and build
   its widgets with `_create_right_panel_widgets`.
7. Set `_current_achievements` and `_tracked_achievements` exactly as stock does, so the
   change-diff in `_update_achievements` and the telemetry reporter stay correct.

### Hook 2: `_rebuild_right_panel_order` (hook_safe)

Post-process `self._right_panel_order`: find the index of `achievements` and insert our
active overflow page keys, in numeric order, directly after it. Without this the stock
implementation drops them and the page-cycle input never reaches them.

### Teardown

Not a third hook. `_setup_achievements` removes our pages at the top of every run, mirroring
`_remove_live_event_page` (`:1514`): nil the `_dynamic_pages` entry,
`_rebuild_right_panel_order()`, `_delete_right_panel_widgets`.

We do **not** need to hand-roll a fallback for the case where the panel is currently showing
a page we just deleted: `_delete_right_panel_widgets(key, ui_renderer)` (`:1297`), called
without the `is_update` third argument, already calls `_switch_right_grid` itself when the
deleted key is the visible one.

We also do not need a `destroy` hook. Our bookkeeping lives on the element as
`self._am_overflow_pages`, so it is collected with the element and cannot leak into the next
mission's HUD.

### The height budget

Read at runtime, not hardcoded:

- budget = `self._ui_scenegraph.right_panel_content.size[2]`
  minus `ElementSettings.right_header_height`
  minus `ElementSettings.buffer`
- inter-entry spacing = `ElementSettings.right_grid_spacing[2]`

Reading the scenegraph rather than the literal 550 in the definitions file keeps this
correct if Fatshark resizes the panel in a patch. Because the scenegraph is expressed in the
1080-tall virtual workspace, the result is independent of screen resolution and HUD scale.

### Titles

`PENANCES (2)`, `PENANCES (3)`, … Registered as global loc keys
(`loc_AM_penance_page_2` upward) via the mod's existing `add_global_localize_strings` call,
in en / ru / zh-cn / zh-tw, covering enough pages for the 30-favourite maximum. Registered
strings contain no `%`, which would crash `string.format` inside the localisation path.

## Trade-off taken

Widgets are built twice whenever the favourites change: once to measure their heights, then
once more per page. The alternative — slicing the already-built widget array into pages —
means re-implementing the engine's widget naming (`"%s_%d"` keyed on page key) and its
deletion bookkeeping, which is more code and more surface to break on a patch. Since
`_setup_achievements` only runs when the favourites list changes, and never per frame, the
double build is not worth optimising away.

## Testing

Offline syntax check with LuaJIT on every changed file.

In-game, in a mission, holding Tab:

- 5 favourites (the stock cap): a single `PENANCES` page, no extra tabs, identical to today.
- 30 favourites: multiple pages; the page-cycle input walks `PENANCES`, `PENANCES (2)`, …
  and back around through the other panels; no entry runs off the panel on any page.
- Un-favourite penances down from 30 to 5 mid-mission: the overflow pages disappear and the
  panel does not end up stranded on a page that no longer exists.
- 0 favourites: no penance page at all, as today.
- Verify at a non-16:9 resolution and at a non-default HUD scale that nothing overflows.
