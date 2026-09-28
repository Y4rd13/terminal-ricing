-- Behavioural test for the keys help in ubuntu-wsl/.config/wezterm/wezterm.lua.
--
-- The config is loaded against a stub of the `wezterm` module, so the real bindings,
-- the real help and the real click handler run; only the GUI calls are recorded instead
-- of performed. What it guards: F1 and the tab-bar button open the help, every binding in
-- config.keys is listed in it (a binding added outside KEYMAP would be missing), Enter on
-- a WezTerm entry runs that binding, and Enter on a tmux or zsh entry does nothing.
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
  nerdfonts = setmetatable({}, { __index = function(_, k) return k end }),
  on = function(event, fn) handlers[event] = fn end,
  plugin = { require = function() return { apply_to_config = function() end } end },
  time = { call_after = function() end },
}

local config = dofile(config_path)

local passed, failed = 0, 0
local function check(cond, msg)
  if cond then
    passed = passed + 1
  else
    failed = failed + 1
    io.write('FAIL: ', msg, '\n')
  end
end

local function fake_window()
  local w = { performed = {} }
  -- A nil action would be lost by table.insert and look like "nothing performed".
  function w:perform_action(a, _) table.insert(self.performed, a == nil and 'nil action' or a) end
  return w
end

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
    help = open_help(function(w) f1.action.fn(w, {}) end)
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
      help.action.fn(w, {}, id, by_id[id].label)
      check(#w.performed == 1 and w.performed[1] == k.action,
        'Enter on ' .. id .. ' did not run its own action')
    end
  end

  -- tmux and zsh are listed too, and Enter on them does nothing.
  for _, group in ipairs({ 'tmux', 'zsh' }) do
    local found
    for _, c in ipairs(help.choices) do
      if c.label:find('[' .. group .. ']', 1, true) then found = c end
    end
    check(found ~= nil, 'the help lists no [' .. group .. '] entry')
    if found then
      local w = fake_window()
      help.action.fn(w, {}, found.id, found.label)
      check(#w.performed == 0, 'Enter on a [' .. group .. '] entry performed an action')
    end
  end

  -- Esc (id and label nil) does nothing.
  local w = fake_window()
  help.action.fn(w, {}, nil, nil)
  check(#w.performed == 0, 'cancelling the help performed an action')
end

-- The tab-bar button is shown, a left click opens the help and suppresses the new tab.
check(config.show_new_tab_button_in_tab_bar == true, 'the tab-bar button is hidden')
local click = handlers['new-tab-button-click']
check(click ~= nil, 'no new-tab-button-click handler')
if click then
  local ret
  local clicked = open_help(function(w) ret = click(w, {}, 'Left', action.SpawnTab) end)
  check(clicked ~= nil, 'a left click on the tab-bar button did not open the help')
  check(ret == false, 'a left click on the tab-bar button still opens a new tab')

  local w = fake_window()
  ret = click(w, {}, 'Right', action.ShowLauncher)
  check(#w.performed == 0 and ret ~= false, 'a right click no longer runs the default action')
end

if failed == 0 then
  io.write(passed, ' passed\n')
  os.exit(0)
end
io.write(passed, ' passed, ', failed, ' failed\n')
os.exit(1)
