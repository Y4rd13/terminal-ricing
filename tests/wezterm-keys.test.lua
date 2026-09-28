-- Behavioural test for the keys help in ubuntu-wsl/.config/wezterm/wezterm.lua.
--
-- The config is loaded against a stub of the `wezterm` module, so the real bindings,
-- the real help and the real click handler run; only the GUI calls are recorded instead
-- of performed. What it guards: F1 and the tab-bar button open the help, every binding in
-- config.keys is listed in it (a binding added outside KEYMAP would be missing), Enter on
-- a WezTerm entry runs that binding, and Enter on a tmux or zsh entry does nothing. The
-- help is English by default and fully translated to Spanish (HELP_LANG = 'es').
--
-- Run: lua5.4 tests/wezterm-keys.test.lua <path-to-wezterm.lua>   (or: nvim -l ...)
-- Prints one FAIL line per broken check and ends with "N passed" or "N passed, M failed".

local config_path = assert(arg[1], 'usage: wezterm-keys.test.lua <wezterm.lua>')

local handlers = {}
local plugin_loaded, before_plugin = false, {}
local live_panes = {}
local reloads = 0
-- What the links handler asked WSL to run, the URLs it opened, and how the fake WSL answers.
local child_calls, opened = {}, {}
local child_answer = function() return false, '', '' end

-- act.X is both a value (act.TogglePaneZoomState) and a constructor (act.SpawnTab '...').
local action = setmetatable({}, {
  __index = function(_, name)
    return setmetatable({ kind = name }, {
      __call = function(_, a) return { kind = name, arg = a } end,
    })
  end,
})

local function identity(x) return x end

package.loaded.wezterm = {
  action = action,
  action_callback = function(fn) return { kind = 'callback', fn = fn } end,
  config_builder = function() return {} end,
  default_wsl_domains = function() return {} end,
  -- One marker rule stands for WezTerm's own URL rules, so a test can see they were kept.
  default_hyperlink_rules = function() return { { regex = 'DEFAULT-RULE', format = '$0' } } end,
  run_child_process = function(argv) table.insert(child_calls, argv); return child_answer(argv) end,
  background_child_process = function(argv) table.insert(child_calls, argv) end,
  open_with = function(url) table.insert(opened, url) end,
  font = identity,
  font_with_fallback = identity,
  format = identity,
  get_builtin_color_schemes = function() return { ['Dracula'] = {}, ['Nord'] = {}, ['Gruvbox Dark'] = {} } end,
  home_dir = '/nonexistent',
  -- A flat table of strings, numbers and booleans is all the config stores; encode it as a
  -- Lua literal and parse it back, which is enough for a round trip. Bad input -> error.
  json_encode = function(t)
    local out = {}
    for k, v in pairs(t) do table.insert(out, string.format('[%q]=%s', k, type(v) == 'string' and string.format('%q', v) or tostring(v))) end
    return 'return {' .. table.concat(out, ',') .. '}'
  end,
  json_parse = function(text)
    local chunk = (loadstring or load)(text)
    if not chunk then error('not json') end
    return chunk()
  end,
  reload_configuration = function() reloads = reloads + 1 end,
  log_info = function() end,
  mux = {
    all_windows = function() return {} end,
    spawn_window = function() end,
    -- A pane closed while its help was open is gone from the mux.
    get_pane = function(id) if live_panes[id] then return { pane_id = function() return id end } end end,
  },
  GLOBAL = {},
  -- A Nerd Font glyph is one cell wide; the stub gives each name its own one-cell
  -- private-use character, so row widths add up and a test can look for a given glyph.
  nerdfonts = setmetatable({}, {
    __index = function(t, name)
      local n = 0
      for _ in pairs(t) do n = n + 1 end
      local glyph = string.char(0xEE, 0x80 + math.floor(n / 64), 0x80 + n % 64) -- U+E000 + n
      rawset(t, name, glyph)
      return glyph
    end,
  }),
  -- Records which handlers exist before the tab-bar plugin loads: WezTerm runs only the
  -- first format-tab-title handler, so ours must come before bar.wezterm's.
  -- As WezTerm does: handlers of one event run in order and a `false` stops the chain,
  -- except format-tab-title, where only the first one registered is ever used.
  on = function(event, fn)
    local prev = handlers[event]
    if prev and event == 'format-tab-title' then return end
    handlers[event] = prev and function(...)
      if prev(...) == false then return false end
      return fn(...)
    end or fn
    if not plugin_loaded then before_plugin[event] = true end
  end,
  plugin = { require = function()
    plugin_loaded = true
    return { apply_to_config = function() end }
  end },
  truncate_right = function(s, n) return s:sub(1, n) end,
  time = { call_after = function() end },
}

local f = assert(io.open(config_path, 'r'))
local source = f:read('*a')
f:close()

local DEFAULT_LANG = "local HELP_LANG = 'en'"

-- Loads the config with HELP_LANG set to `lang`; returns the config and its event handlers.
local function load_config(lang, extra_from, extra_to)
  handlers, plugin_loaded, before_plugin = {}, false, {}
  local src = source:gsub(DEFAULT_LANG, "local HELP_LANG = '" .. lang .. "'", 1)
  if extra_from then src = src:gsub(extra_from, extra_to, 1) end
  local chunk = assert((loadstring or load)(src, '@' .. config_path))
  return chunk(), handlers
end

-- wezterm.format is stubbed as identity, so a styled label is its list of format items.
local function plain(x)
  if type(x) ~= 'table' then return tostring(x) end
  local out = {}
  for _, item in ipairs(x) do
    if type(item) == 'table' and item.Text then table.insert(out, item.Text) end
  end
  return table.concat(out)
end

local config = load_config('en')

local passed, failed = 0, 0
local function check(cond, msg)
  if cond then
    passed = passed + 1
  else
    failed = failed + 1
    io.write('FAIL: ', msg, '\n')
  end
end

local function fake_window(overrides, id)
  local w = { performed = {}, overrides = overrides }
  function w:window_id() return id or 1 end
  -- A nil action would be lost by table.insert and look like "nothing performed".
  function w:perform_action(a, _) table.insert(self.performed, a == nil and 'nil action' or a) end
  function w:get_config_overrides() return self.overrides end
  function w:set_config_overrides(o) self.overrides = o end
  -- What every real window answers; tests that care override these.
  function w:active_pane() return { pane_id = function() return 1 end } end
  function w:is_focused() return true end
  function w:mux_window()
    return { tabs = function() return {} end,
             active_tab = function() return { active_pane = function() return { pane_id = function() return 1 end } end } end }
  end
  function w:toast_notification() end
  return w
end

local PANE_COLS = 120
local function fake_pane(id, cols)
  id = id or 1
  live_panes[id] = true
  return {
    get_dimensions = function() return { cols = cols or PANE_COLS } end,
    pane_id = function() return id end,
  }
end

-- Display width of a plain label: one cell per UTF-8 character (icons and arrows included).
local function width(s) return select(2, s:gsub('[^\128-\191]', '')) end

local function has_background(label)
  if type(label) ~= 'table' then return false end
  for _, item in ipairs(label) do
    if type(item) == 'table' and item.Background then return true end
  end
  return false
end

local function is_header(c) return c.id:sub(1, 7) == 'header:' end

local function binding_id(k) return k.key .. '|' .. (k.mods or '') end

-- Opens the help through `run(window)` and returns the InputSelector it performed, if any.
local function open_help(run)
  local w = fake_window()
  run(w)
  local a = w.performed[1]
  if #w.performed == 1 and a.kind == 'InputSelector' then return a.arg end
  return nil
end

-- F1 opens the help.
local f1
for _, k in ipairs(config.keys or {}) do
  if k.key == 'F1' then f1 = k end
end
check(f1 ~= nil, 'no binding for F1 in config.keys')

local help
if f1 then
  check(f1.action.kind == 'callback', 'F1 is not bound to a callback that opens the help')
  if f1.action.kind == 'callback' then
    help = open_help(function(w) f1.action.fn(w, fake_pane()) end)
  end
  check(help ~= nil, 'F1 did not open an InputSelector')
end

if help then
  check(help.fuzzy == true, 'the help does not start in fuzzy search mode')

  local by_id = {}
  for _, c in ipairs(help.choices) do by_id[c.id] = c end

  -- Every binding is listed, and Enter on it runs exactly that binding.
  for _, k in ipairs(config.keys) do
    local id = binding_id(k)
    check(by_id[id] ~= nil, 'binding ' .. id .. ' is in config.keys but not in the help')
    if by_id[id] then
      local w = fake_window()
      help.action.fn(w, fake_pane(), id, by_id[id].label)
      check(#w.performed == 1 and w.performed[1] == k.action,
        'Enter on ' .. id .. ' did not run its own action')
    end
  end

  -- tmux and zsh are listed too, and Enter on them does nothing.
  for _, group in ipairs({ 'tmux', 'zsh' }) do
    local found
    for _, c in ipairs(help.choices) do
      if c.id:sub(1, #group + 1) == group .. ':' then found = c end
    end
    check(found ~= nil, 'the help lists no [' .. group .. '] entry')
    if found then
      local w = fake_window()
      help.action.fn(w, fake_pane(), found.id, found.label)
      check(#w.performed == 0, 'Enter on a [' .. group .. '] entry performed an action')
    end
  end

  -- Esc (id and label nil) does nothing.
  local w = fake_window()
  help.action.fn(w, fake_pane(), nil, nil)
  check(#w.performed == 0, 'cancelling the help performed an action')

  -- Rows paint no background of their own (the window turns opaque instead, see below;
  -- a per-row background flickers as the selection moves), and share one compact width
  -- so the Enter mark sits near its text, not at the far edge of a wide pane.
  local row_width
  for _, c in ipairs(help.choices) do
    check(not has_background(c.label), 'row ' .. c.id .. ' paints its own background')
    local cw = width(plain(c.label))
    row_width = row_width or cw
    check(cw == row_width, 'row ' .. c.id .. ' is ' .. cw .. ' cells wide, the first row is ' .. row_width)
  end
  check(row_width and row_width >= 60 and row_width <= 90,
    'rows are ' .. tostring(row_width) .. ' cells wide in a ' .. PANE_COLS .. '-column pane, expected 60-90')

  -- Sections: each entry sits under its own header, and Enter on a header does nothing.
  local section_of, current = {}, nil
  for _, c in ipairs(help.choices) do
    if is_header(c) then current = c.id:sub(8) else section_of[c.id] = current end
  end
  for _, s in ipairs({ 'help', 'tabs', 'panes', 'links', 'tmux', 'zsh' }) do
    local h = by_id['header:' .. s]
    check(h ~= nil, 'the help has no header for section ' .. s)
    if h then
      local hw = fake_window()
      help.action.fn(hw, fake_pane(), h.id, h.label)
      check(#hw.performed == 0, 'Enter on header ' .. s .. ' performed an action')
    end
  end
  for id, s in pairs({ ['F1|'] = 'help', ['T|CTRL|SHIFT'] = 'tabs', ['Y|CTRL|SHIFT'] = 'panes',
                       ['s|LEADER'] = 'panes', ['r|CTRL|SHIFT'] = 'help', ['Space|CTRL|SHIFT'] = 'links' }) do
    check(section_of[id] == s, id .. ' is under section ' .. tostring(section_of[id]) .. ', expected ' .. s)
  end

  -- Runnable rows end in the Nerd Font Enter glyph; the others carry no mark and no
  -- "(reference)" text: the tmux and zsh headers already say it.
  local RET = package.loaded.wezterm.nerdfonts.md_keyboard_return
  local entries = 0
  for _, c in ipairs(help.choices) do
    if not is_header(c) then
      entries = entries + 1
      local text = plain(c.label)
      if c.id:find('|', 1, true) or c.id:sub(1, 7) == 'action:' then
        check(text:find(RET, 1, true) ~= nil, 'runnable row ' .. c.id .. ' has no Enter mark')
      else
        check(not text:find(RET, 1, true) and not text:find('(reference)', 1, true),
          'row ' .. c.id .. ' cannot run from the list but carries a mark: ' .. text)
      end
    end
  end
  check(plain(help.fuzzy_description):find(tostring(entries), 1, true) ~= nil,
    'the search line does not give the number of shortcuts (' .. entries .. ')')
  check(plain(help.fuzzy_description):find(RET, 1, true) ~= nil,
    'the search line does not show the Enter mark it explains')

  -- WezTerm shows the selected row by swapping each stretch's colours, so everything after
  -- the icon (shortcut, description, mark) uses one colour and the selection reads as one block.
  for _, c in ipairs(help.choices) do
    if not is_header(c) and type(c.label) == 'table' then
      local colours, seen_text = {}, false
      local fg
      for _, item in ipairs(c.label) do
        if type(item) == 'table' and item.Foreground then fg = item.Foreground.Color end
        if type(item) == 'table' and item.Text then
          if seen_text then colours[fg or 'default'] = true end
          seen_text = true
        end
      end
      local n = 0
      for _ in pairs(colours) do n = n + 1 end
      check(n == 1, 'row ' .. c.id .. ' uses ' .. n .. ' colours after the icon, so its selection is striped')
    end
  end

  -- The window turns fully opaque while the help is open, and closing it by any path
  -- (Enter on a row, Enter on a header, Esc) puts back exactly the overrides it had.
  for _, close in ipairs({ { 'T|CTRL|SHIFT', 'Enter on a row' }, { 'header:tabs', 'Enter on a header' },
                           { nil, 'Esc' } }) do
    for _, before in ipairs({ { nil, 'no override' }, { 0.5, 'an opacity override of 0.5' } }) do
      local w = fake_window(before[1] and { window_background_opacity = before[1] } or nil)
      f1.action.fn(w, fake_pane())
      local opened = w.performed[1]
      check((w.overrides or {}).window_background_opacity == 1.0,
        'opening the help with ' .. before[2] .. ' does not make the window opaque')
      if opened and opened.kind == 'InputSelector' then
        opened.arg.action.fn(w, fake_pane(), close[1], close[1] and '' or nil)
        check((w.overrides or {}).window_background_opacity == before[1],
          close[2] .. ' with ' .. before[2] .. ' left the opacity at '
            .. tostring((w.overrides or {}).window_background_opacity))
      end
    end
  end

  -- The overlay's tab title is not the button's text, so "Keys" is not shown twice.
  check(not plain(help.title):find('Keys', 1, true), 'the help tab is titled like the Keys button')
end

-- Ctrl+Alt+Up / Down change the window opacity by 5% within 30-100%, and Ctrl+Alt+0 drops
-- the override so the config's own value (window_background_opacity) applies again.
local function binding(cfg, key, mods)
  for _, k in ipairs(cfg.keys or {}) do
    if k.key == key and k.mods == mods then return k end
  end
end

local function press(k, overrides)
  local w = fake_window(overrides)
  k.action.fn(w, fake_pane())
  return (w.overrides or {}).window_background_opacity
end

local function near(a, b) return a ~= nil and b ~= nil and math.abs(a - b) < 1e-9 end

local up, down, reset = binding(config, 'UpArrow', 'CTRL|ALT'), binding(config, 'DownArrow', 'CTRL|ALT'),
  binding(config, '0', 'CTRL|ALT')
check(up and down and reset, 'Ctrl+Alt+Up, Ctrl+Alt+Down or Ctrl+Alt+0 is not bound')
if up and down and reset then
  local base = config.window_background_opacity
  check(near(press(up, nil), base + 0.05), 'Ctrl+Alt+Up from the config value does not add 5%')
  check(near(press(down, nil), base - 0.05), 'Ctrl+Alt+Down from the config value does not take 5%')
  check(near(press(up, { window_background_opacity = 0.5 }), 0.55), 'Ctrl+Alt+Up does not start from the current opacity')
  check(near(press(up, { window_background_opacity = 0.98 }), 1.0), 'Ctrl+Alt+Up goes past 100%')
  check(near(press(down, { window_background_opacity = 0.32 }), 0.3), 'Ctrl+Alt+Down goes below 30%')
  check(press(reset, { window_background_opacity = 0.5 }) == nil, 'Ctrl+Alt+0 does not return to the config value')
end
if help then
  for _, c in ipairs(help.choices) do
    if c.id:find('|CTRL|ALT', 1, true) and not is_header(c) then
      local section
      for _, h in ipairs(help.choices) do
        if is_header(h) then section = h.id end
        if h == c then break end
      end
      check(section == 'header:help', c.id .. ' is not under Help & config')
    end
  end
end

-- The opacity survives two helps open at once and a pane closed with its help still open:
-- the value from before the first help comes back once the last one is gone.
if f1 then
  local w = fake_window({ window_background_opacity = 0.6 }, 7)
  local p1, p2 = fake_pane(11), fake_pane(12)
  f1.action.fn(w, p1)
  f1.action.fn(w, p2)
  local first, second = w.performed[1], w.performed[2]
  second.arg.action.fn(w, p2, nil, nil)
  check(near(w.overrides.window_background_opacity, 1.0), 'closing one of two open helps made the window translucent')
  first.arg.action.fn(w, p1, nil, nil)
  check(near(w.overrides.window_background_opacity, 0.6), 'closing both helps did not restore 0.6, got '
    .. tostring(w.overrides.window_background_opacity))

  local p3 = fake_pane(13)
  f1.action.fn(w, p3)
  live_panes[13] = nil
  local status = handlers['update-status']
  check(status ~= nil, 'no update-status handler to notice a pane closed with its help open')
  if status then status(w, fake_pane(14)) end
  check(near(w.overrides.window_background_opacity, 0.6),
    'closing a pane with its help open left the window at ' .. tostring(w.overrides.window_background_opacity))
end

-- A narrow pane still gets rows of one width that fit it, each runnable one with its mark.
if f1 then
  local w = fake_window()
  f1.action.fn(w, fake_pane(21, 50))
  local narrow = w.performed[1] and w.performed[1].arg
  local RET = package.loaded.wezterm.nerdfonts.md_keyboard_return
  local first_width
  for _, c in ipairs(narrow and narrow.choices or {}) do
    local text = plain(c.label)
    local cw = width(text)
    first_width = first_width or cw
    check(cw == first_width and cw <= 50, 'in a 50-column pane row ' .. c.id .. ' is ' .. cw .. ' cells wide')
    if c.id:find('|', 1, true) then
      check(text:find(RET, 1, true) ~= nil, 'in a 50-column pane row ' .. c.id .. ' lost its Enter mark')
    end
  end
end

-- Ctrl+Shift+E renames the current tab; an empty name goes back to the automatic title.
do
  local rename = binding(config, 'E', 'CTRL|SHIFT')
  check(rename and rename.action.kind == 'PromptInputLine', 'Ctrl+Shift+E does not ask for a tab name')
  if rename and rename.action.kind == 'PromptInputLine' then
    local titled
    local w = fake_window()
    function w:active_tab() return { set_title = function(_, t) titled = t end } end
    rename.action.arg.action.fn(w, fake_pane(), 'API plenor')
    check(titled == 'API plenor', 'renaming did not set the tab title')
    titled = 'untouched'
    rename.action.arg.action.fn(w, fake_pane(), nil)
    check(titled == 'untouched', 'Esc on the rename prompt changed the title')
    rename.action.arg.action.fn(w, fake_pane(), '')
    check(titled == '', 'an empty name does not return to the automatic title')
  end
end

-- A Windows toast when a Claude Code session you are not looking at finishes (working ->
-- idle) or starts needing you (claude_state = waiting). Never on the first look at a pane,
-- never twice for one change, never for the pane you are looking at, never for a plain shell.
do
  local status = handlers['update-status']
  local panes, tab_names = {}, {}
  local function pane(id, title, vars)
    panes[id] = { title = title, vars = vars or {} }
  end
  -- active_id: the tab's active pane (mux); gui_active: what window:active_pane() returns,
  -- which is an overlay's own pane while F1, copy mode or a prompt is open on it.
  local function fake(active_id, focused, gui_active)
    local w = fake_window(nil, 42)
    w.toasts = {}
    function w:toast_notification(title, msg) table.insert(self.toasts, title .. ': ' .. msg) end
    function w:is_focused() return focused end
    function w:active_pane() return { pane_id = function() return gui_active or active_id end } end
    function w:mux_window()
      local tabs = {}
      for id, p in pairs(panes) do
        local pn = { pane_id = function() return id end, get_title = function() return p.title end,
                     get_user_vars = function() return p.vars end }
        table.insert(tabs, { panes = function() return { pn } end, get_title = function() return tab_names[id] or '' end })
      end
      return {
        tabs = function() return tabs end,
        active_tab = function() return { active_pane = function() return { pane_id = function() return active_id end } end } end,
      }
    end
    return w
  end
  local function tick(active_id, focused, gui_active)
    local w = fake(active_id, focused, gui_active)
    status(w, fake_pane(active_id))
    return w.toasts
  end

  pane(1, '◐ Planforge local'); pane(2, '◐ rtk-hook'); pane(3, 'zsh'); pane(4, '✳ NeuralGT')
  check(#tick(9, true) == 0, 'the first look at the panes raised a toast')
  pane(1, '✳ Planforge local')
  local t = tick(9, true)
  check(#t == 1 and t[1]:find('Planforge local', 1, true) and not t[1]:find('✳', 1, true),
    'a background session that finished raised no toast naming it: ' .. table.concat(t, ' | '))
  check(#tick(9, true) == 0, 'the same finish raised a second toast')
  pane(2, '✳ rtk-hook')
  check(#tick(2, true) == 0, 'the session you are looking at raised a toast when it finished')
  pane(2, '◐ rtk-hook'); tick(2, true); pane(2, '✳ rtk-hook')
  check(#tick(2, false) == 1, 'the active session finished while WezTerm was not focused, and no toast came')
  pane(2, '◐ rtk-hook'); tick(2, true); pane(2, '✳ rtk-hook')
  check(#tick(2, true, 999) == 0, 'the session you are looking at, with F1 or copy mode open on it, raised a toast')
  pane(4, '◐ NeuralGT', { claude_state = 'waiting' })
  t = tick(9, true)
  check(#t == 1 and t[1]:find('NeuralGT', 1, true), 'a background session that needs you raised no toast: '
    .. table.concat(t, ' | '))
  check(#tick(9, true) == 0, 'a session still waiting raised a second toast')
  pane(3, 'zsh'); tick(9, true); pane(3, 'bash')
  check(#tick(9, true) == 0, 'a plain shell tab raised a toast')
  pane(5, '◐ build'); tick(9, true); pane(5, '❯ ~/proj')
  check(#tick(9, true) == 0, 'a Claude session that exited to a shell prompt with a glyph raised a toast')
  pane(5, '✳ build'); tick(9, true)
  check(#tick(9, true) == 0, 'a shell prompt glyph was read as a Claude state')
  tab_names[6] = 'API plenor'; pane(6, '◐ Claude Code'); tick(9, true); pane(6, '✳ Claude Code')
  t = tick(9, true)
  check(#t == 1 and t[1]:find('API plenor', 1, true), 'the toast ignores the tab name set with Ctrl+Shift+E: '
    .. table.concat(t, ' | '))
end

-- CLAUDE_TOASTS at the top of the file turns the toasts off; true by default.
do
  local _, n = source:gsub("local CLAUDE_TOASTS = true", '')
  check(n == 1, 'wezterm.lua does not set local CLAUDE_TOASTS = true exactly once')
  local cfg_handlers
  load_config('en', "local CLAUDE_TOASTS = true", "local CLAUDE_TOASTS = false")
  cfg_handlers = handlers
  local title = '◐ quiet'
  local w = fake_window(nil, 43)
  w.toasts = {}
  function w:toast_notification(t, m) table.insert(self.toasts, t .. ': ' .. m) end
  function w:mux_window()
    local pn = { pane_id = function() return 77 end, get_title = function() return title end,
                 get_user_vars = function() return {} end }
    return { tabs = function() return { { panes = function() return { pn } end, get_title = function() return '' end } } end,
             active_tab = function() return { active_pane = function() return { pane_id = function() return 1 end } end } end }
  end
  cfg_handlers['update-status'](w, fake_pane(1))
  title = '✳ quiet'
  cfg_handlers['update-status'](w, fake_pane(1))
  check(#w.toasts == 0, 'with CLAUDE_TOASTS = false a finished background session still raised a toast')
  load_config('en') -- back to the default config for the checks below
end

-- ⚙ Settings: reached from a row of the F1 help (section Help & config). Each setting shows
-- its value; Enter opens a list of values, and choosing one saves it to
-- <home>/.wezterm-settings.json (outside the repo) and reloads the config, where the saved
-- values override the file's defaults. A missing or broken file means the defaults.
do
  local W = package.loaded.wezterm
  local dir = os.tmpname(); os.remove(dir); os.execute('mkdir -p "' .. dir .. '"')
  local file = dir .. '/.wezterm-settings.json'
  local saved_home = W.home_dir
  W.home_dir = dir
  local function write(t) local f = io.open(file, 'w'); f:write(W.json_encode(t)); f:close() end
  local function read()
    local f = io.open(file, 'r'); if not f then return {} end
    local text = f:read('*a'); f:close()
    local ok, t = pcall(W.json_parse, text)
    return ok and t or {}
  end
  local function help_of(cfg)
    local k = binding(cfg, 'F1', nil)
    return k and open_help(function(w) k.action.fn(w, fake_pane()) end)
  end
  local function find(choices, id) for _, c in ipairs(choices or {}) do if c.id == id then return c end end end

  os.remove(file)
  local cfg = load_config('en')
  check(near(cfg.window_background_opacity, 0.82) and cfg.font_size == 13, 'with no settings file the defaults changed')

  write({ lang = 'es', toasts = false, opacity = 0.7, font_size = 15, color_scheme = 'Nord' })
  cfg = load_config('en')
  check(near(cfg.window_background_opacity, 0.7), 'the saved opacity is not applied')
  check(cfg.font_size == 15, 'the saved font size is not applied')
  check(cfg.color_scheme == 'Nord', 'the saved color scheme is not applied: ' .. tostring(cfg.color_scheme))
  local h = help_of(cfg)
  check(h and plain(h.title):find('Ayuda', 1, true), 'the saved language (es) is not applied to the help')

  local f = io.open(file, 'w'); f:write('{ not json'); f:close()
  local ok_load, cfg_bad = pcall(load_config, 'en')
  check(ok_load and near(cfg_bad.window_background_opacity, 0.82), 'a broken settings file breaks the config or its defaults')

  os.remove(file)
  cfg = load_config('en')
  h = help_of(cfg)
  local row = h and find(h.choices, 'action:settings')
  check(row ~= nil, 'the F1 help has no Settings row')
  local section
  for _, c in ipairs(h and h.choices or {}) do
    if is_header(c) then section = c.id end
    if c.id == 'action:settings' then break end
  end
  check(section == 'header:help', 'the Settings row is not under Help & config')

  local function run_action(a, w)
    if a and a.kind == 'callback' then a.fn(w, fake_pane()) end
  end
  local page
  if row then
    local w = fake_window()
    h.action.fn(w, fake_pane(), row.id, row.label)
    local w2 = fake_window()
    run_action(w.performed[1], w2)
    page = w2.performed[1] and w2.performed[1].kind == 'InputSelector' and w2.performed[1].arg
  end
  check(page ~= nil, 'Enter on the Settings row does not open the settings page')
  if page then
    local want = { ['setting:lang'] = 'English', ['setting:toasts'] = 'on', ['setting:opacity'] = '82%',
                   ['setting:font_size'] = '13', ['setting:color_scheme'] = 'Dracula (custom)' }
    for id, value in pairs(want) do
      local c = find(page.choices, id)
      check(c and plain(c.label):find(value, 1, true), id .. ' does not show its current value ' .. value
        .. ': ' .. tostring(c and plain(c.label)))
    end

    local function pick(setting_id, value_id, w)
      w = w or fake_window()
      page.action.fn(w, fake_pane(), setting_id, '')
      local picker = w.performed[#w.performed]
      picker = picker and picker.kind == 'InputSelector' and picker.arg
      check(picker and find(picker.choices, value_id), setting_id .. ' offers no value ' .. value_id)
      if picker then picker.action.fn(w, fake_pane(), value_id, '') end
      return w
    end

    local before = reloads
    pick('setting:lang', 'es')
    check(read().lang == 'es' and reloads == before + 1, 'choosing Español was not saved and reloaded')
    pick('setting:toasts', 'false')
    check(read().toasts == false and read().lang == 'es', 'turning notifications off lost it or the language')
    local w = pick('setting:opacity', '0.9', fake_window({ window_background_opacity = 0.5 }))
    check(near(read().opacity, 0.9), 'the chosen opacity was not saved')
    check((w.overrides or {}).window_background_opacity == nil, 'a session opacity override hides the new default')
    pick('setting:font_size', '15')
    check(read().font_size == 15, 'the chosen font size was not saved as a number')
    w = pick('setting:color_scheme', 'Nord')
    check(read().color_scheme == 'Nord', 'the chosen color scheme was not saved')
    local last = w.performed[#w.performed]
    check(last and last.kind == 'InputSelector', 'the scheme list does not reopen to try another one')
    local reopened = last and last.kind == 'InputSelector' and last.arg
    local nord = reopened and find(reopened.choices, 'Nord')
    check(nord and plain(nord.label):find('●', 1, true), 'the reopened list does not mark the scheme just picked')
    -- The page shows what the window shows, not the scheme the config started with.
    local wp = fake_window(w.overrides)
    local k = binding(cfg, 'F1', nil)
    local hh = open_help(function(x) k.action.fn(x, fake_pane()) end)
    local srow = find(hh.choices, 'action:settings')
    hh.action.fn(wp, fake_pane(), srow.id, '')
    local w3 = fake_window(w.overrides)
    run_action(wp.performed[1], w3)
    local page2 = w3.performed[#w3.performed] and w3.performed[#w3.performed].arg
    local crow = page2 and find(page2.choices, 'setting:color_scheme')
    check(crow and plain(crow.label):find('Nord', 1, true), 'the Settings page still shows the old scheme: '
      .. tostring(crow and plain(crow.label)))
    -- Esc on the scheme list drops the window override and reloads, so every window takes
    -- the saved scheme and deleting the file really goes back to the default.
    local before_esc = reloads
    if reopened then reopened.action.fn(w, fake_pane(), nil, nil) end
    check((w.overrides or {}).color_scheme == nil, 'closing the scheme list left a color_scheme override on the window')
    check(reloads == before_esc + 1, 'closing the scheme list did not reload the config')
  end

  os.remove(file); os.execute('rmdir "' .. dir .. '"')
  W.home_dir = saved_home
  load_config('en')
end

-- Clickable links: #N opens the PR or issue of the pane folder's GitHub repo, a Jira key
-- opens the issue when ~/.wezterm-settings.json names the site and the prefixes, and
-- file:line opens the editor chosen by setup.sh. Quick Select gets the same patterns.
-- WezTerm's regexes are Rust ones; Python's re agrees with Rust regex on the subset used
-- here (no lookaround, no backreferences), so samples are checked through python3.
local links_dir = os.tmpname(); os.remove(links_dir); os.execute('mkdir -p "' .. links_dir .. '"')
local links_file = links_dir .. '/.wezterm-settings.json'

-- Loads the config with a settings file holding `literal` (the stub's json_parse runs Lua,
-- so the file is a Lua table literal), or with no file when `literal` is nil.
local function links_settings(literal)
  local W = package.loaded.wezterm
  W.home_dir = links_dir
  if literal then
    local f = io.open(links_file, 'w'); f:write('return ' .. literal); f:close()
  else
    os.remove(links_file)
  end
  return load_config('en')
end

-- For each sample, the sorted, space-separated links that `pairs_list` ({regex, format})
-- make of it. nil when python3 is not installed.
local function python_links(pairs_list, samples)
  local status = os.execute('command -v python3 >/dev/null 2>&1')
  if status ~= true and status ~= 0 then return nil end
  local out = { 'import re', 'rules = [' }
  for _, r in ipairs(pairs_list) do table.insert(out, string.format('(%q, %q),', r[1], r[2])) end
  table.insert(out, ']')
  table.insert(out, 'samples = [')
  for _, s in ipairs(samples) do table.insert(out, string.format('%q,', s)) end
  table.insert(out, ']')
  for _, line in ipairs({
    'for s in samples:',
    '    found = set()',
    '    for rx, fmt in rules:',
    '        for m in re.finditer(rx, s):',
    "            found.add(re.sub(r'\\$(\\d)', lambda d: m.group(int(d.group(1))) or '', fmt))",
    "    print(' '.join(sorted(found)))",
  }) do table.insert(out, line) end
  local script = os.tmpname()
  local f = io.open(script, 'w'); f:write(table.concat(out, '\n'), '\n'); f:close()
  local p = io.popen('python3 ' .. script)
  local results = {}
  for line in p:lines() do table.insert(results, line) end
  p:close(); os.remove(script)
  return results
end

local function jira_rules(cfg)
  local n = 0
  for _, r in ipairs(cfg.hyperlink_rules or {}) do
    if r.format:find('/browse/', 1, true) then n = n + 1 end
  end
  return n
end

do
  local cfg = links_settings(nil)
  local rules = cfg.hyperlink_rules or {}
  check(rules[1] and rules[1].regex == 'DEFAULT-RULE', "WezTerm's own hyperlink rules were dropped")
  local has = {}
  for _, r in ipairs(rules) do has[r.format:match('^(%a+):') or ''] = true end
  check(has.ghref and has.edit, 'no hyperlink rule for #N or file:line')
  check(jira_rules(cfg) == 0, 'a Jira rule exists with no settings file')

  for _, bad in ipairs({
    "{ jira_url = 'https://x.atlassian.net' }",
    "{ jira_projects = { 'FTK' } }",
    "{ jira_url = '', jira_projects = { 'FTK' } }",
    "{ jira_url = 'http://x.atlassian.net', jira_projects = { 'FTK' } }",
    "{ jira_url = 'javascript:alert(1)', jira_projects = { 'FTK' } }",
    "{ jira_url = 'https://x.atlassian.net', jira_projects = {} }",
    "{ jira_url = 'https://x.atlassian.net', jira_projects = { 'ftk' } }",
    "{ jira_url = 'https://x.atlassian.net', jira_projects = { 'FTK|.*' } }",
    "{ jira_url = 'https://x.atlassian.net', jira_projects = { 'FTK', 5 } }",
    "{ jira_url = 'https://x.atlassian.net', jira_projects = 'FTK' }",
  }) do
    check(jira_rules(links_settings(bad)) == 0, 'incomplete or invalid Jira settings still made a rule: ' .. bad)
  end

  local jcfg = links_settings("{ jira_url = 'https://x.atlassian.net/', jira_projects = { 'FTK', 'OPS' } }")
  check(jira_rules(jcfg) == 1, 'valid Jira settings made no Jira rule')
  check(#(cfg.quick_select_patterns or {}) == 2 and #(jcfg.quick_select_patterns or {}) == 3,
    'Quick Select does not get #N and file:line, plus the Jira keys when they are set')

  for _, p in ipairs(jcfg.quick_select_patterns or {}) do
    check(not (p:gsub('%(%?:', '')):find('(', 1, true), 'Quick Select pattern has a capture group: ' .. p)
  end
  for _, r in ipairs(jcfg.hyperlink_rules or {}) do
    for _, look in ipairs({ '(?=', '(?!', '(?<=', '(?<!' }) do
      check(not r.regex:find(look, 1, true), 'hyperlink rule uses lookaround, which Rust regex rejects: ' .. r.regex)
    end
  end

  local function own(c)
    local out = {}
    for _, r in ipairs(c.hyperlink_rules or {}) do
      if r.regex ~= 'DEFAULT-RULE' then table.insert(out, { r.regex, r.format }) end
    end
    return out
  end
  local cases = {
    { 'see #21 now', 'ghref:21' },
    { '(#7)', 'ghref:7' },
    { 'color #ff5555', '' },
    { 'a#12', '' },
    { '#1234567', '' },
    { 'src/app.ts:42', 'edit:src/app.ts:42' },
    { 'error at ./a/b.py:7:3: boom', 'edit:./a/b.py:7:3' },
    { "'/home/me/x.lua:10'", 'edit:/home/me/x.lua:10' },
    { 'http://localhost.dev:8080/x', '' },
    { 'listen 127.0.0.1:8080', '' },
    { 'at 10:30', '' },
    { 'Makefile:3', '' },
    { 'connect to api.github.com:443', '' },
    { 'db.internal:5432 is down', '' },
    { 'see setup.sh:691', 'edit:setup.sh:691' },
    { 'in config.json:12:4', 'edit:config.json:12:4' },
    { 'fix FTK-12 and OPS-3', 'https://x.atlassian.net/browse/FTK-12 https://x.atlassian.net/browse/OPS-3' },
    { 'UTF-8 and XFTK-12', '' },
  }
  local samples = {}
  for _, c in ipairs(cases) do table.insert(samples, c[1]) end
  local got = python_links(own(jcfg), samples)
  if got then
    for i, c in ipairs(cases) do
      check(got[i] == c[2], 'links in "' .. c[1] .. '": expected "' .. c[2] .. '", got "' .. tostring(got[i]) .. '"')
    end
    local plain_got = python_links(own(cfg), { 'fix FTK-12' })
    check(plain_got[1] == '', 'with no Jira settings FTK-12 is still a link: ' .. tostring(plain_got[1]))
    local qs = {}
    for _, p in ipairs(jcfg.quick_select_patterns or {}) do table.insert(qs, { p, 'qs:$0' }) end
    local qs_got = python_links(qs, { 'see #21 in src/a.ts:3 for FTK-9' })
    check(qs_got[1] == 'qs:#21 qs:FTK-9 qs:src/a.ts:3', 'Quick Select marks ' .. tostring(qs_got[1]))
  else
    io.write('SKIP: python3 not installed, link regexes not checked against samples\n')
  end

  -- The fake WSL: `git remote get-url origin` answers `remote` (nil = not a repo), and
  -- `test -f <path>` succeeds for the paths in `existing`.
  local function answer(remote, existing)
    child_calls, opened = {}, {}
    child_answer = function(argv)
      local i = 1
      -- --exec, never --: after -- wsl.exe hands the line to the Linux shell, which expands it.
      while argv[i] and argv[i] ~= '--exec' do i = i + 1 end
      if argv[i + 1] == 'git' then
        if remote then return true, remote .. '\n', '' end
        return false, '', 'fatal: not a git repository'
      end
      if argv[i + 1] == 'test' then return (existing or {})[argv[i + 3]] == true, '', '' end
      return false, '', ''
    end
  end
  local function link_pane(cwd)
    local p = { splits = {} }
    function p:get_current_working_dir() return cwd and { file_path = '/wsl.localhost/Ubuntu' .. cwd } or nil end
    function p:split(args) table.insert(self.splits, args); return {} end
    function p:pane_id() return 1 end
    return p
  end
  local function toast_window()
    local w = fake_window(); w.toasts = {}
    function w:toast_notification(_, msg) table.insert(self.toasts, msg) end
    return w
  end

  links_settings(nil)
  check(handlers['open-uri'] ~= nil, 'no open-uri handler')
  if handlers['open-uri'] then
    for _, remote in ipairs({ 'https://github.com/Y4rd13/terminal-ricing.git', 'git@github.com:Y4rd13/terminal-ricing.git',
                              'https://github.com/Y4rd13/terminal-ricing', 'ssh://git@github.com/Y4rd13/terminal-ricing.git' }) do
      answer(remote)
      local ret = handlers['open-uri'](toast_window(), link_pane('/home/me/proj'), 'ghref:21')
      check(ret == false and opened[1] == 'https://github.com/Y4rd13/terminal-ricing/issues/21',
        'ghref:21 with remote ' .. remote .. ' opened ' .. tostring(opened[1]))
    end
    answer('https://github.com/o/r.git')
    handlers['open-uri'](toast_window(), link_pane('/home/me/my proj'), 'ghref:3')
    check(child_calls[1] and child_calls[1][4] == '--cd' and child_calls[1][5] == '/home/me/my proj',
      'git did not run in the pane folder')

    for _, case in ipairs({
      { 'https://gitlab.com/o/r.git', '/home/me/proj', 'a GitLab remote' },
      { nil, '/home/me/proj', 'a folder that is not a repo' },
      { 'https://github.com/o/r.git', nil, 'a pane with no known folder' },
      { 'https://github.com.evil.io/o/r.git', '/home/me/proj', 'a look-alike host' },
    }) do
      answer(case[1])
      local w = toast_window()
      local ret = handlers['open-uri'](w, link_pane(case[2]), 'ghref:5')
      check(ret == false and #opened == 0 and #w.toasts == 1, case[3] .. ' opened something or gave no toast')
    end

    local function edit(literal, uri, cwd, existing)
      links_settings(literal)
      answer(nil, existing)
      local w, p = toast_window(), link_pane(cwd)
      return handlers['open-uri'](w, p, uri), w, p
    end
    local ret, w, p = edit("{ editor = 'nvim' }", 'edit:src/app.ts:42', '/home/me/proj', { ['/home/me/proj/src/app.ts'] = true })
    local s = p.splits[1]
    check(ret == false and #p.splits == 1 and s.direction == 'Right', 'nvim: file:line did not split to the right')
    check(s and s.domain and s.domain.DomainName == 'WSL:Ubuntu', 'the editor split is not in the WSL domain')
    check(s and s.args[1] == 'bash' and s.args[2] == '-lc' and s.args[3] == "exec nvim +42 '/home/me/proj/src/app.ts'",
      'nvim: wrong command ' .. tostring(s and s.args[3]))
    ret, w, p = edit("{ editor = 'micro' }", 'edit:./a/b.py:7:3', '/home/me/proj', { ['/home/me/proj/a/b.py'] = true })
    check(p.splits[1] and p.splits[1].args[3] == "exec micro +7 '/home/me/proj/a/b.py'",
      'micro: wrong command ' .. tostring(p.splits[1] and p.splits[1].args[3]))
    ret, w, p = edit("{ editor = 'code' }", 'edit:/etc/x.conf:9', nil, { ['/etc/x.conf'] = true })
    local last = child_calls[#child_calls]
    -- code is only on the PATH the shell builds, so it runs through sh -c with the path as
    -- a positional argument, which sh never parses.
    check(ret == false and #p.splits == 0 and last and last[4] == '--exec' and last[5] == 'sh'
      and last[7] == 'exec code -g "$1"' and last[9] == '/etc/x.conf:9',
      'code: file:line did not run code -g /etc/x.conf:9 through sh -c')
    for _, literal in ipairs({ '{}', "{ editor = 'vim' }", "{ editor = { 'code' } }" }) do
      ret, w, p = edit(literal, 'edit:a.lua:1', '/p', { ['/p/a.lua'] = true })
      check(p.splits[1] and p.splits[1].args[3]:find('^exec nvim ') ~= nil,
        'editor setting ' .. literal .. ' did not fall back to nvim')
    end
    ret, w, p = edit("{ editor = 'nvim' }", 'edit:gone.lua:3', '/p', {})
    check(ret == false and #p.splits == 0 and #w.toasts == 1 and w.toasts[1]:find('gone.lua', 1, true) ~= nil,
      'a missing file opened or gave no toast naming it')
    ret, w, p = edit("{ editor = 'nvim' }", 'edit:a.lua:3', nil, { ['/p/a.lua'] = true })
    check(#p.splits == 0 and #w.toasts == 1, 'a relative path with no known folder opened something')
    -- An OSC 8 hyperlink can point anywhere: a path with shell syntax reaches neither WSL nor
    -- the editor, only a toast.
    for _, hostile in ipairs({ 'edit:/tmp/x$(touch pwned).lua:1', 'edit:a`id`.lua:2', "edit:/p/a;rm -rf ~.lua:3", "edit:it's.lua:1" }) do
      ret, w, p = edit("{ editor = 'code' }", hostile, '/p', {})
      check(ret == false and #child_calls == 0 and #p.splits == 0 and #w.toasts == 1,
        'the hostile link ' .. hostile .. ' reached WSL or gave no toast')
    end
    answer(nil)
    check(handlers['open-uri'](toast_window(), link_pane('/p'), 'https://example.com') == nil,
      'a normal URL no longer reaches the default browser action')
  end

  local mcfg = links_settings("{ editor = 'micro' }")
  local mf1 = binding(mcfg, 'F1', nil)
  local mhelp = mf1 and open_help(function(w) mf1.action.fn(w, fake_pane()) end)
  local names_editor = false
  for _, c in ipairs(mhelp and mhelp.choices or {}) do
    if plain(c.label):find('micro', 1, true) then names_editor = true end
  end
  check(names_editor, 'the file:line row of the help does not name the chosen editor (micro)')

  -- (Tasks 2 and 3 add their checks above this line.)
  -- Back to no settings file and the default config: the checks below read `handlers`.
  os.remove(links_file); os.execute('rmdir "' .. links_dir .. '"')
  package.loaded.wezterm.home_dir = '/nonexistent'
  load_config('en')
end

-- Tab titles change colour under the mouse. bar.wezterm ignores the hover flag, and WezTerm
-- runs only the first format-tab-title handler, so the config registers its own before the
-- plugin loads, keeping the plugin's "N <icon> title" layout.
check(before_plugin['format-tab-title'] == true, 'format-tab-title is not registered before bar.wezterm loads')
local fmt = handlers['format-tab-title']
if fmt then
  local conf = {
    tab_max_width = 28,
    resolved_palette = { tab_bar = {
      active_tab = { bg_color = 'active-bg', fg_color = 'active-fg' },
      inactive_tab = { bg_color = 'idle-bg', fg_color = 'idle-fg' },
      inactive_tab_hover = { bg_color = 'hover-bg', fg_color = 'hover-fg' },
    } },
  }
  local function tab(index, active, pane_title, tab_title, user_vars, unseen)
    return { tab_index = index, is_active = active, tab_title = tab_title or '',
             active_pane = { title = pane_title, user_vars = user_vars or {}, has_unseen_output = unseen or false } }
  end
  local function colours(items) return items[1].Background.Color, items[2].Foreground.Color end
  local function text(items)
    local out = {}
    for _, it in ipairs(items) do if it.Text then table.insert(out, it.Text) end end
    return table.concat(out)
  end
  local icon = package.loaded.wezterm.nerdfonts.pl_right_hard_divider

  local bg, fg = colours(fmt(tab(1, false, 'zsh'), {}, {}, conf, true, 28))
  check(bg == 'hover-bg' and fg == 'hover-fg', 'a hovered inactive tab does not use inactive_tab_hover')
  bg, fg = colours(fmt(tab(1, false, 'zsh'), {}, {}, conf, false, 28))
  check(bg == 'idle-bg' and fg == 'idle-fg', 'an inactive tab does not use inactive_tab')
  bg, fg = colours(fmt(tab(1, true, 'zsh'), {}, {}, conf, true, 28))
  check(bg == 'active-bg' and fg == 'active-fg', 'the active tab changes colour under the mouse')

  local t = text(fmt(tab(2, false, '/home/me/notes.md'), {}, {}, conf, false, 28))
  check(t == '3 ' .. icon .. ' notes  ', 'tab title is not "N <icon> basename": ' .. t)
  t = text(fmt(tab(0, false, 'x', 'My tab'), {}, {}, conf, false, 28))
  check(t == '1 ' .. icon .. ' My tab  ', 'an explicit tab title is not used: ' .. t)
  t = text(fmt(tab(0, false, string.rep('a', 60)), {}, {}, conf, false, 28))
  check(t:find('…', 1, true) ~= nil and #t < 60, 'a long tab title is not truncated: ' .. t)

  -- Claude Code sessions, minimal: only the state glyph and the tab's separator take the
  -- state colour; the background and the name keep the tab's own colours. The title glyph
  -- says working (◐ ◑ ◒ ◓ or a braille spinner) or idle (✳); the claude_state user var, set
  -- by a Claude Code hook, says it needs you.
  local nf = package.loaded.wezterm.nerdfonts
  local function render(...) return fmt(tab(...), {}, {}, conf, false, 28) end
  local function all_text(items)
    local out = {}
    for _, it in ipairs(items) do if it.Text then table.insert(out, it.Text) end end
    return table.concat(out)
  end
  -- Colour in force where a Text item contains `needle`.
  local function colour_of(items, needle)
    local fg
    for _, it in ipairs(items) do
      if it.Foreground then fg = it.Foreground.Color end
      if it.Text and it.Text:find(needle, 1, true) then return fg end
    end
  end
  local function state_ok(items, mark, colour, label)
    check(items[1].Background.Color == 'idle-bg', label .. ': the background changed')
    check(colour_of(items, mark) == colour, label .. ': the mark is not ' .. colour .. ', got ' .. tostring((colour_of(items, mark))))
    check(colour_of(items, icon) == colour, label .. ': the separator is not ' .. colour)
    check(colour_of(items, 'Planforge') == 'idle-fg', label .. ': the name changed colour')
  end

  state_ok(render(1, false, '◐ Planforge local'), '◐', '#f1fa8c', 'working ◐')
  state_ok(render(1, false, '◑ Planforge local'), '◑', '#f1fa8c', 'working ◑ (same colour in every spinner phase)')
  state_ok(render(1, false, '⠋ Planforge local'), '⠋', '#f1fa8c', 'working with a braille spinner')

  local items = render(1, false, '◐ Planforge local', nil, { claude_state = 'waiting' })
  state_ok(items, nf.md_bell_ring, '#ff5555', 'waiting for you')
  check(not all_text(items):find('◐', 1, true), 'a waiting tab still shows the stale spinner: ' .. all_text(items))

  items = render(1, false, '✳ Planforge local', nil, nil, true)
  state_ok(items, '•', '#50fa7b', 'finished while you were away')
  check(not all_text(items):find('✳', 1, true), 'a finished tab still shows ✳')

  items = render(1, false, '✳ Planforge local')
  check(colour_of(items, '✳') == '#6272a4' and colour_of(items, icon) == 'idle-fg',
    'an idle Claude tab does not show a dim ✳ with a plain separator')
  items = fmt(tab(1, true, '✳ Planforge local', nil, nil, true), {}, {}, conf, false, 28)
  check(colour_of(items, '✳') == '#6272a4', 'the active idle tab is marked as finished-while-away')
  items = render(1, false, 'zsh', nil, nil, true)
  check(colour_of(items, icon) == 'idle-fg' and colour_of(items, 'zsh') == 'idle-fg',
    'a plain shell tab with new output is coloured like a Claude one')
  check(all_text(render(2, false, '/home/me/notes.md')) == '3 ' .. icon .. ' notes  ',
    'a plain tab title changed: ' .. all_text(render(2, false, '/home/me/notes.md')))
end

-- The tab-bar button is shown, a left click opens the help and suppresses the new tab.
check(config.show_new_tab_button_in_tab_bar == true, 'the tab-bar button is hidden')
local click = handlers['new-tab-button-click']
check(click ~= nil, 'no new-tab-button-click handler')
if click then
  local ret
  local clicked = open_help(function(w) ret = click(w, fake_pane(), 'Left', action.SpawnTab) end)
  check(clicked ~= nil, 'a left click on the tab-bar button did not open the help')
  check(ret == false, 'a left click on the tab-bar button still opens a new tab')

  local w = fake_window()
  ret = click(w, fake_pane(), 'Right', action.ShowLauncher)
  check(#w.performed == 0 and ret ~= false, 'a right click no longer runs the default action')
end

-- English is the default, and every text in the help has its own Spanish version.
local _, default_count = source:gsub(DEFAULT_LANG, '')
check(default_count == 1, 'wezterm.lua does not set ' .. DEFAULT_LANG .. ' exactly once')

local es = load_config('es')
local es_f1
for _, k in ipairs(es.keys or {}) do
  if k.key == 'F1' then es_f1 = k end
end
local es_help = es_f1 and open_help(function(w) es_f1.action.fn(w, fake_pane()) end)
check(es_help ~= nil, "F1 does not open the help with HELP_LANG = 'es'")

if help and es_help then
  check(plain(help.title) ~= plain(es_help.title), 'the help title is not translated')
  check(#help.choices == #es_help.choices, 'the English and Spanish helps list different entries')
  for i, c in ipairs(help.choices) do
    local e = es_help.choices[i]
    check(e and plain(c.label) ~= plain(e.label),
      'entry ' .. c.id .. ' reads the same in both languages: ' .. plain(c.label))
  end
  check(plain(help.fuzzy_description) ~= plain(es_help.fuzzy_description), 'the search line is not translated')
  local es_tabs
  for _, c in ipairs(es_help.choices) do if c.id == 'header:tabs' then es_tabs = plain(c.label) end end
  check(es_tabs and es_tabs:find('PESTAÑAS', 1, true), 'the Spanish Tabs header does not read PESTAÑAS: ' .. tostring(es_tabs))
end

local function button_text(cfg) return plain((cfg.tab_bar_style or {}).new_tab) end
check(button_text(config):find('Keys', 1, true) ~= nil, 'the English tab-bar button does not say Keys')
check(button_text(es):find('Atajos', 1, true) ~= nil, 'the Spanish tab-bar button does not say Atajos')

if failed == 0 then
  io.write(passed, ' passed\n')
  os.exit(0)
end
io.write(passed, ' passed, ', failed, ' failed\n')
os.exit(1)
