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
  font = identity,
  font_with_fallback = identity,
  format = identity,
  get_builtin_color_schemes = function() return {} end,
  home_dir = '/nonexistent',
  json_encode = function() return '' end,
  json_parse = function() return nil end,
  log_info = function() end,
  mux = { all_windows = function() return {} end, spawn_window = function() end },
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
  on = function(event, fn) handlers[event] = fn end,
  plugin = { require = function() return { apply_to_config = function() end } end },
  time = { call_after = function() end },
}

local f = assert(io.open(config_path, 'r'))
local source = f:read('*a')
f:close()

local DEFAULT_LANG = "local HELP_LANG = 'en'"

-- Loads the config with HELP_LANG set to `lang`; returns the config and its event handlers.
local function load_config(lang)
  handlers = {}
  local src = source:gsub(DEFAULT_LANG, "local HELP_LANG = '" .. lang .. "'", 1)
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

local function fake_window(overrides)
  local w = { performed = {}, overrides = overrides }
  -- A nil action would be lost by table.insert and look like "nothing performed".
  function w:perform_action(a, _) table.insert(self.performed, a == nil and 'nil action' or a) end
  function w:get_config_overrides() return self.overrides end
  function w:set_config_overrides(o) self.overrides = o end
  return w
end

local PANE_COLS = 120
local function fake_pane()
  return { get_dimensions = function() return { cols = PANE_COLS } end }
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
  for _, s in ipairs({ 'help', 'tabs', 'panes', 'tmux', 'zsh' }) do
    local h = by_id['header:' .. s]
    check(h ~= nil, 'the help has no header for section ' .. s)
    if h then
      local hw = fake_window()
      help.action.fn(hw, fake_pane(), h.id, h.label)
      check(#hw.performed == 0, 'Enter on header ' .. s .. ' performed an action')
    end
  end
  for id, s in pairs({ ['F1|'] = 'help', ['T|CTRL|SHIFT'] = 'tabs', ['Y|CTRL|SHIFT'] = 'panes',
                       ['s|LEADER'] = 'panes', ['r|CTRL|SHIFT'] = 'help' }) do
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
      if c.id:find('|', 1, true) then
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
