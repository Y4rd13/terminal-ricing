-- WEZTERM (Windows) + WSL (Ubuntu) - Config ajustada
local wezterm = require 'wezterm'
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm") -- bar.wezterm plugin :contentReference[oaicite:1]{index=1}
local act = wezterm.action

local config = wezterm.config_builder()

-- Idioma de la ayuda de atajos (F1 y botón de la barra): 'en' o 'es'
local HELP_LANG = 'en'

-- =========================================================
-- OPTIMIZACIONES
-- =========================================================
-- 1) Scrollback más grande
config.scrollback_lines = 10000

-- 2) GPU backend explícito (performance)
config.front_end = 'OpenGL'

-- 3) Refresh para módulos dinámicos (clock/spotify)
config.status_update_interval = 1000

-- =========================================================
-- 1) WSL: abrir SIEMPRE en Ubuntu (no cmd/powershell)
-- =========================================================
config.wsl_domains = wezterm.default_wsl_domains() -- :contentReference[oaicite:1]{index=1}

-- Cambia esto si tu distro se llama distinto (ver: wsl -l -v)
local WSL_DISTRO = 'Ubuntu'
local WSL_DOMAIN = 'WSL:' .. WSL_DISTRO

config.default_domain = WSL_DOMAIN -- :contentReference[oaicite:2]{index=2}

-- Forzar: entrar en ~ y ejecutar zsh login (para cargar tu setup)
for _, dom in ipairs(config.wsl_domains) do
  if dom.name == WSL_DOMAIN then
    dom.default_prog = { 'bash', '-lc', 'cd ~; exec zsh -l' } -- :contentReference[oaicite:3]{index=3}
    -- Si prefieres auto-tmux:
    -- dom.default_prog = { 'bash', '-lc', 'cd ~; exec tmux new-session -A -s main' }
  end
end

-- =========================================================
-- 2) Apariencia
-- =========================================================
-- Color scheme base
config.color_scheme = 'Dracula'
config.bold_brightens_ansi_colors = true
config.force_reverse_video_cursor = true

-- Fondo sutil
config.window_background_gradient = {
  orientation = 'Vertical',
  colors = { '#1a1b26', '#16161e' },
  interpolation = 'Linear',
  blend = 'Rgb',
}

-- Opacidad
config.window_background_opacity = 0.82
config.text_background_opacity = 1.0
-- Blur en Windows 11 (opcional). Requiere opacity < 1.0. :contentReference[oaicite:4]{index=4}
-- config.win32_system_backdrop = 'Mica'

-- =========================================================
-- 3) Fuente
-- WezTerm trae JetBrains Mono + Nerd Font Symbols + Noto Color Emoji. :contentReference[oaicite:5]{index=5}
-- =========================================================
config.font = wezterm.font_with_fallback {
  'JetBrains Mono',
  'Symbols Nerd Font Mono',
  'Noto Color Emoji',
}
config.font_size = 13
config.line_height = 1.1

-- =========================================================
-- 4) Ventana
-- =========================================================
config.default_workspace = "main"
config.window_decorations = "RESIZE"
config.window_close_confirmation = 'NeverPrompt'
config.adjust_window_size_when_changing_font_size = false
config.use_resize_increments = false
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

local function tab_title(tab_info)
  local title = tab_info.tab_title
  if title and #title > 0 then
    return title
  end
  return tab_info.active_pane.title
end

-- Tabs
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = false
-- El botón de "nueva pestaña" pasa a ser el de la ayuda de atajos (ver sección 7)
config.show_new_tab_button_in_tab_bar = true
config.tab_max_width = 28

-- Scrollbar ON (usa el padding derecho)
config.enable_scroll_bar = true
config.window_padding = {
  left = 15,
  right = "1cell", -- comentar si el config.enable_scroll_bar = true
--  right = 15, -- descomentar si el config.enable_scroll_bar = false
  top = 15,
  bottom = 15,
}

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

config.initial_cols = 170
config.initial_rows = 30

config.window_frame = {
  font = wezterm.font { family = 'JetBrains Mono', weight = 'Bold' },
  font_size = 12.0,
}

-- =========================================================
-- 4.1) Scrollbar thumb más visible (custom scheme)
-- =========================================================
do
  local schemes = wezterm.get_builtin_color_schemes()
  local base = schemes['Dracula']
  if base then
    -- Contraste: súbelo si quieres aún más visible
    base.scrollbar_thumb = '#6272a4'
    config.color_schemes = {
      ['Dracula (custom)'] = base,
    }
    config.color_scheme = 'Dracula (custom)'
  end
end

-- =========================================================
-- 4.2) bar.wezterm (powerline + clean)
-- =========================================================
bar.apply_to_config(config, {
  position = "top",
  max_width = 28,

  padding = {
    left = 1,
    right = 1,
    tabs = {
      left = 0,
      right = 2,
    },
  },

  -- Separadores “powerline”
  separator = {
    space = 1,
    left_icon = wezterm.nerdfonts.pl_right_hard_divider,
    right_icon = wezterm.nerdfonts.pl_left_hard_divider,
    field_icon = wezterm.nerdfonts.indent_line,
  },

  modules = {
    -- Colores por índice ANSI (0-15)
    tabs = {
      active_tab_fg = 15,
      inactive_tab_fg = 8,
      new_tab_fg = 5,
    },

    workspace = { enabled = true, icon = wezterm.nerdfonts.cod_window, color = 8 },
    leader    = { enabled = true, icon = wezterm.nerdfonts.oct_rocket, color = 2 },
    zoom      = { enabled = true, icon = wezterm.nerdfonts.md_fullscreen, color = 4 },
    pane      = { enabled = true, icon = wezterm.nerdfonts.cod_multiple_windows, color = 7 },

    username  = { enabled = true, icon = wezterm.nerdfonts.fa_user, color = 6 },
    hostname  = { enabled = true, icon = wezterm.nerdfonts.cod_server, color = 8 },

    cwd       = { enabled = true, icon = wezterm.nerdfonts.oct_file_directory, color = 7 },
    clock     = { enabled = true, icon = wezterm.nerdfonts.md_calendar_clock, format = "%H:%M:%S", color = 5 },

    -- ✅ Spotify (requiere spotify-tui / spt instalado y configurado en Windows)
    -- https://developer.spotify.com/dashboard
    -- use on powershell: command spt
    -- spotify   = { enabled = true, icon = wezterm.nerdfonts.fa_spotify, color = 2, max_width = 64, throttle = 15 },
  },
})

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

-- =========================================================
-- 4.2.1) bar.wezterm - TAB BAR TRANSPARENTE (como en el README)
-- FIX: WezTerm exige fg_color + bg_color (si no, falla con missing field `fg_color`)
-- =========================================================
config.colors = config.colors or {}
config.colors.tab_bar = config.colors.tab_bar or {}

-- Fondo general (lo dejamos “clean” y coherente con tu gradiente)
config.colors.tab_bar.background = 'transparent'

-- Activo: más contraste, se siente “premium”
config.colors.tab_bar.active_tab = config.colors.tab_bar.active_tab or {}
config.colors.tab_bar.active_tab.bg_color = '#44475a'
config.colors.tab_bar.active_tab.fg_color = '#f8f8f2'
config.colors.tab_bar.active_tab.intensity = 'Bold'

-- Inactivo: oscuro + texto suave
config.colors.tab_bar.inactive_tab = config.colors.tab_bar.inactive_tab or {}
config.colors.tab_bar.inactive_tab.bg_color = '#1e1f29'
config.colors.tab_bar.inactive_tab.fg_color = '#6272a4'

-- Hover: “lift” sutil
config.colors.tab_bar.inactive_tab_hover = config.colors.tab_bar.inactive_tab_hover or {}
config.colors.tab_bar.inactive_tab_hover.bg_color = '#2a2c37'
config.colors.tab_bar.inactive_tab_hover.fg_color = '#f8f8f2'

-- Nuevo tab: acento morado dracula
config.colors.tab_bar.new_tab = config.colors.tab_bar.new_tab or {}
config.colors.tab_bar.new_tab.bg_color = '#1e1f29'
config.colors.tab_bar.new_tab.fg_color = '#bd93f9'

config.colors.tab_bar.new_tab_hover = config.colors.tab_bar.new_tab_hover or {}
config.colors.tab_bar.new_tab_hover.bg_color = '#2a2c37'
config.colors.tab_bar.new_tab_hover.fg_color = '#f8f8f2'

-- =========================================================
-- 5) Keybindings
-- Nota: ALT/OPT/META son equivalentes en WezTerm. :contentReference[oaicite:6]{index=6}
--
-- Todos los atajos van en KEYMAP, nunca directo en config.keys: de esta lista salen
-- config.keys y la ayuda de F1 (sección 7), así que un atajo nuevo aparece en la ayuda
-- solo. Campos: grupo, cómo se escribe el atajo, qué hace en inglés y en español
-- (HELP_LANG elige), y key/mods/action para WezTerm. Una entrada sin key solo se
-- muestra en la ayuda (tmux, zsh, rangos).
-- tests/wezterm-keys.test.lua falla si un atajo queda fuera de la ayuda o sin traducir.
-- =========================================================
local function wez(keys, desc, key, mods, action)
  return { group = 'wezterm', keys = keys, desc = desc, key = key, mods = mods, action = action }
end

local KEYMAP = {
  -- Pestañas (mismos atajos que trae WezTerm, declarados para que salgan en la ayuda)
  wez('Ctrl+Tab', { en = 'Next tab', es = 'Pestaña siguiente' },
    'Tab', 'CTRL', act.ActivateTabRelative(1)),
  wez('Ctrl+Shift+Tab', { en = 'Previous tab', es = 'Pestaña anterior' },
    'Tab', 'CTRL|SHIFT', act.ActivateTabRelative(-1)),
  wez('Ctrl+Shift+PageUp', { en = 'Move tab left', es = 'Mover pestaña a la izquierda' },
    'PageUp', 'CTRL|SHIFT', act.MoveTabRelative(-1)),
  wez('Ctrl+Shift+PageDown', { en = 'Move tab right', es = 'Mover pestaña a la derecha' },
    'PageDown', 'CTRL|SHIFT', act.MoveTabRelative(1)),
  { group = 'wezterm', keys = 'Ctrl+Shift+1..9',
    desc = { en = 'Go to tab 1-8 (9 = last)', es = 'Ir a la pestaña 1-8 (9 = última)' } },

  -- Splits
  wez('Ctrl+Shift+F', { en = 'Split pane horizontally', es = 'Dividir panel en horizontal' },
    'f', 'CTRL|SHIFT', act.SplitHorizontal { domain = 'CurrentPaneDomain' }),
  wez('Ctrl+Shift+D', { en = 'Split pane vertically', es = 'Dividir panel en vertical' },
    'd', 'CTRL|SHIFT', act.SplitVertical { domain = 'CurrentPaneDomain' }),

  -- Cambiar entre paneles
  wez('Ctrl+Left', { en = 'Go to the pane on the left', es = 'Ir al panel de la izquierda' },
    'LeftArrow', 'CTRL', act.ActivatePaneDirection 'Left'),
  wez('Ctrl+Right', { en = 'Go to the pane on the right', es = 'Ir al panel de la derecha' },
    'RightArrow', 'CTRL', act.ActivatePaneDirection 'Right'),
  wez('Ctrl+Up', { en = 'Go to the pane above', es = 'Ir al panel de arriba' },
    'UpArrow', 'CTRL', act.ActivatePaneDirection 'Up'),
  wez('Ctrl+Down', { en = 'Go to the pane below', es = 'Ir al panel de abajo' },
    'DownArrow', 'CTRL', act.ActivatePaneDirection 'Down'),

  -- Zoom del panel
  wez('Ctrl+Shift+Z', { en = 'Zoom the pane in or out', es = 'Zoom del panel (activar/quitar)' },
    'z', 'CTRL|SHIFT', act.TogglePaneZoomState),

  -- Redimensionar paneles
  wez('Alt+Left', { en = 'Move the pane border left', es = 'Mover el borde del panel a la izquierda' },
    'LeftArrow', 'OPT', act.AdjustPaneSize { 'Left', 5 }),
  wez('Alt+Right', { en = 'Move the pane border right', es = 'Mover el borde del panel a la derecha' },
    'RightArrow', 'OPT', act.AdjustPaneSize { 'Right', 5 }),
  wez('Alt+Up', { en = 'Move the pane border up', es = 'Mover el borde del panel hacia arriba' },
    'UpArrow', 'OPT', act.AdjustPaneSize { 'Up', 5 }),
  wez('Alt+Down', { en = 'Move the pane border down', es = 'Mover el borde del panel hacia abajo' },
    'DownArrow', 'OPT', act.AdjustPaneSize { 'Down', 5 }),

  -- Cerrar panel
  wez('Ctrl+Shift+W', { en = 'Close the current pane', es = 'Cerrar el panel actual' },
    'w', 'CTRL|SHIFT', act.CloseCurrentPane { confirm = true }),

  -- 4) Atajo para recargar config
  wez('Ctrl+Shift+R', { en = 'Reload the config', es = 'Recargar la config' },
    'r', 'CTRL|SHIFT', act.ReloadConfiguration),
}

config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.8,
}

-- Split con tmux en el pane actual (Ctrl+Shift+Y; la T quedó para nueva pestaña)
table.insert(KEYMAP, wez('Ctrl+Shift+Y',
  { en = 'Split horizontally running tmux (session main)', es = 'Dividir en horizontal con tmux (sesión main)' },
  'Y', 'CTRL|SHIFT', act.SplitHorizontal {
    domain = 'CurrentPaneDomain',
    args = { 'tmux', 'new-session', '-A', '-s', 'main' },
  }))

-- =========================================================
-- 6) Persistencia de layout: guarda qué ventanas/splits hay y la carpeta
--    de cada uno. Autoguardado y restauración al abrir: apagados (ver gui-startup).
--    Ctrl+Space s -> guardar ahora   |   Ctrl+Space r -> restaurar ahora
-- Requiere el OSC 7 del .zshrc (sin él no se conocen las carpetas).
-- =========================================================
local mux = wezterm.mux
local WSL = { DomainName = WSL_DOMAIN }
local STATE = wezterm.home_dir .. '/.wezterm-layout.json' -- C:\Users\<usuario>\...

-- La GUI corre en Windows, así que el cwd de un panel WSL llega como
-- /wsl.localhost/Ubuntu/home/... -> lo pasamos a ruta Linux (/home/...)
local function linux_cwd(pane)
  local url = pane:get_current_working_dir()
  if not url or not url.file_path then return nil end
  local distro = WSL_DISTRO:gsub('%p', '%%%0') -- 'Ubuntu-24.04': '-' y '.' son mágicos en patrones
  local p = url.file_path:gsub('^/wsl%.localhost/' .. distro, '')
                         :gsub('^/wsl%$/' .. distro, '')
  -- solo rutas Linux; lo demás se descarta. Una ruta de Windows llega como /C:/Users/...
  -- y también empieza con '/', por eso se excluye aparte.
  if p:find('^/') and not p:find('^/%a:') then return p end
  return nil
end

local function prog_in(dir)
  if dir then -- comillas simples: bash no interpreta el nombre de la carpeta
    local quoted = "'" .. dir:gsub("'", "'\\''") .. "'"
    return { 'bash', '-lc', 'cd ' .. quoted .. ' && exec zsh -l' }
  end
  return nil -- sin carpeta conocida: default_prog (zsh en ~)
end

local function save_layout()
  local windows = {}
  for _, win in ipairs(mux.all_windows()) do
    local tabs = {}
    for _, tab in ipairs(win:tabs()) do
      local panes = {}
      for _, p in ipairs(tab:panes_with_info()) do
        table.insert(panes, { left = p.left, top = p.top,
                              width = p.width, height = p.height,
                              cwd = linux_cwd(p.pane) })
      end
      table.sort(panes, function(a, b)
        if a.top == b.top then return a.left < b.left end
        return a.top < b.top
      end)
      if #panes > 0 then table.insert(tabs, panes) end
    end
    if #tabs > 0 then table.insert(windows, tabs) end
  end
  if #windows == 0 then return end -- nunca guardar un estado vacío
  local f = io.open(STATE, 'w')
  if f then f:write(wezterm.json_encode(windows)); f:close() end
end

-- Reconstruye un tab: cada panel guardado busca a su vecino ya creado
-- (mismo borde izquierdo -> split hacia abajo; mismo borde superior -> a la derecha)
local function restore_tab(saved, first_pane)
  local placed = { { s = saved[1], pane = first_pane } }
  for i = 2, #saved do
    local p, done = saved[i], false
    for _, q in ipairs(placed) do
      local args = { domain = WSL, args = prog_in(p.cwd) }
      if p.left == q.s.left and math.abs(q.s.top + q.s.height + 1 - p.top) <= 1 then
        args.direction = 'Bottom'
        args.size = p.height / (q.s.height + p.height)
        table.insert(placed, { s = p, pane = q.pane:split(args) })
        done = true; break
      elseif p.top == q.s.top and math.abs(q.s.left + q.s.width + 1 - p.left) <= 1 then
        args.direction = 'Right'
        args.size = p.width / (q.s.width + p.width)
        table.insert(placed, { s = p, pane = q.pane:split(args) })
        done = true; break
      end
    end
    if not done then -- sin vecino claro: split a la derecha del último
      local last = placed[#placed]
      table.insert(placed, { s = p, pane = last.pane:split {
        domain = WSL, args = prog_in(p.cwd), direction = 'Right' } })
    end
  end
end

local function restore_layout()
  local f = io.open(STATE, 'r')
  if not f then return end
  local ok, data = pcall(wezterm.json_parse, f:read('*a'))
  f:close()
  if not ok or not data then return end
  for _, tabs in ipairs(data) do
    local _, pane, win = mux.spawn_window { domain = WSL, args = prog_in(tabs[1][1].cwd) }
    restore_tab(tabs[1], pane)
    for i = 2, #tabs do
      local _, tp = win:spawn_tab { domain = WSL, args = prog_in(tabs[i][1].cwd) }
      restore_tab(tabs[i], tp)
    end
  end
end

wezterm.on('gui-startup', function(cmd)
  if cmd then -- respetar `wezterm start -- algo`
    mux.spawn_window(cmd)
    return
  end
  -- 2026-09-16: restore_layout() ya no se llama al arrancar. Medido: el archivo de estado
  -- llevaba seis semanas sin actualizarse y 6 de 8 paneles guardaban el home de Windows,
  -- asi que al abrir salian paneles vacios. Reabrir sesiones de Claude Code lo hace `sr`
  -- (session-recall, en claude-config), que abre solo las que uno elige, cada una en su
  -- directorio y ya reanudada. Ctrl+Space s / Ctrl+Space r siguen disponibles a mano.
end)

-- autoguardado cada 60s; wezterm.GLOBAL evita duplicarlo en cada reload de config
if false and not wezterm.GLOBAL.layout_autosave then -- 2026-09-16: apagado, ver nota en gui-startup
  wezterm.GLOBAL.layout_autosave = true
  local function tick()
    pcall(save_layout)
    wezterm.time.call_after(60, tick)
  end
  wezterm.time.call_after(60, tick)
end

table.insert(KEYMAP, wez('Ctrl+Space s', { en = 'Save the pane layout', es = 'Guardar el layout de paneles' },
  's', 'LEADER', wezterm.action_callback(function() save_layout() end)))
table.insert(KEYMAP, wez('Ctrl+Space r', { en = 'Restore the saved layout', es = 'Restaurar el layout guardado' },
  'r', 'LEADER', wezterm.action_callback(function() restore_layout() end)))

-- Nueva pestaña: Ctrl+Shift+T
table.insert(KEYMAP, wez('Ctrl+Shift+T', { en = 'New tab', es = 'Nueva pestaña' },
  'T', 'CTRL|SHIFT', act.SpawnTab 'CurrentPaneDomain'))

-- =========================================================
-- 7) Ayuda de atajos: F1, o click en el botón "Keys"/"Atajos" de la barra de pestañas
--    Lista KEYMAP con búsqueda fuzzy. Enter sobre un atajo de WezTerm lo ejecuta;
--    sobre uno de tmux o zsh solo cierra, porque WezTerm no puede dispararlos.
-- =========================================================
local function tr(t) return t[HELP_LANG] or t.en end

local function info(group, keys, desc) return { group = group, keys = keys, desc = desc } end

for _, k in ipairs({
  info('tmux', 'Ctrl+a |', { en = 'Split horizontally', es = 'Dividir en horizontal' }),
  info('tmux', 'Ctrl+a -', { en = 'Split vertically', es = 'Dividir en vertical' }),
  info('tmux', 'Ctrl+a I', { en = 'Install plugins (TPM)', es = 'Instalar plugins (TPM)' }),
  info('zsh',  'Ctrl+F',   { en = 'Accept the suggestion', es = 'Aceptar la sugerencia' }),
  info('zsh',  'Ctrl+R',   { en = 'Search history (fzf)', es = 'Buscar en el historial (fzf)' }),
  info('zsh',  'Ctrl+T',   { en = 'Find a file (fzf)', es = 'Buscar archivo (fzf)' }),
  info('zsh',  'Alt+C',    { en = 'Jump into a directory (fzf)', es = 'Entrar a un directorio (fzf)' }),
}) do
  table.insert(KEYMAP, k)
end

-- Colores Dracula: un ícono y un color por grupo; el atajo en rosa, la descripción en gris.
local HELP_GROUPS = {
  wezterm = { icon = wezterm.nerdfonts.dev_terminal,      color = '#bd93f9' },
  tmux    = { icon = wezterm.nerdfonts.cod_terminal_tmux, color = '#50fa7b' },
  zsh     = { icon = wezterm.nerdfonts.cod_terminal,      color = '#8be9fd' },
}

local function show_help(window, pane)
  local choices, run = {}, {}
  for i, k in ipairs(KEYMAP) do
    local id = k.key and (k.key .. '|' .. (k.mods or '')) or (k.group .. ':' .. i)
    local g = HELP_GROUPS[k.group]
    run[id] = k.action
    table.insert(choices, {
      id = id,
      label = wezterm.format {
        { Foreground = { Color = g.color } }, { Text = ' ' .. g.icon .. '  ' },
        { Foreground = { Color = '#ff79c6' } }, { Attribute = { Intensity = 'Bold' } },
        { Text = string.format('%-22s', k.keys) },
        'ResetAttributes',
        { Foreground = { Color = '#c0c4d6' } }, { Text = tr(k.desc) },
      },
    })
  end
  window:perform_action(act.InputSelector {
    title = tr { en = 'Keys', es = 'Atajos' },
    choices = choices,
    fuzzy = true,
    fuzzy_description = wezterm.nerdfonts.md_keyboard .. '  ' .. tr {
      en = 'Search keys (Enter runs WezTerm ones, Esc closes): ',
      es = 'Buscar atajo (Enter ejecuta los de WezTerm, Esc cierra): ',
    },
    action = wezterm.action_callback(function(win, p, id)
      if id and run[id] then win:perform_action(run[id], p) end
    end),
  }, pane)
end

table.insert(KEYMAP, 1, wez('F1', { en = 'Show this help', es = 'Mostrar esta ayuda' },
  'F1', nil, wezterm.action_callback(show_help)))

-- El botón: cápsula morada con ícono de teclado, rosa al pasar el mouse. El fondo de los
-- bordes redondeados es el de las pestañas inactivas, para que calce con la barra.
local function help_button(bg)
  local bar_bg = '#1e1f29'
  return wezterm.format {
    { Background = { Color = bar_bg } }, { Text = ' ' },
    { Foreground = { Color = bg } }, { Text = wezterm.nerdfonts.ple_left_half_circle_thick },
    { Background = { Color = bg } }, { Foreground = { Color = '#282a36' } },
    { Attribute = { Intensity = 'Bold' } },
    { Text = wezterm.nerdfonts.md_keyboard .. ' ' .. tr { en = 'Keys', es = 'Atajos' } },
    'ResetAttributes',
    { Background = { Color = bar_bg } }, { Foreground = { Color = bg } },
    { Text = wezterm.nerdfonts.ple_right_half_circle_thick },
  }
end
config.tab_bar_style = { new_tab = help_button('#bd93f9'), new_tab_hover = help_button('#ff79c6') }

-- Click izquierdo en el botón: la ayuda en vez de una pestaña nueva (esa sigue en
-- Ctrl+Shift+T). El click derecho conserva lo que hace WezTerm por defecto.
wezterm.on('new-tab-button-click', function(window, pane, button)
  if button ~= 'Left' then return end
  show_help(window, pane)
  return false
end)

config.keys = {}
for _, k in ipairs(KEYMAP) do
  if k.key then
    table.insert(config.keys, { key = k.key, mods = k.mods, action = k.action })
  end
end

return config