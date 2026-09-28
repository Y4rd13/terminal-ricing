-- WEZTERM (Windows) + WSL (Ubuntu) - Config ajustada
local wezterm = require 'wezterm'

-- Títulos de pestaña con color al pasar el mouse. WezTerm usa solo el primer handler de
-- format-tab-title, y bar.wezterm (cargado abajo) ignora el hover, así que este va antes
-- del plugin. Copia su formato "N <separador> título" (bar.wezterm 89ef9bb): si el plugin
-- cambia cómo dibuja las pestañas, hay que actualizar esto.
wezterm.on('format-tab-title', function(tab, _, _, conf, hover)
  local palette = conf.resolved_palette.tab_bar
  local index = tostring(tab.tab_index + 1)
  local icon = wezterm.nerdfonts.pl_right_hard_divider
  local name = tab.tab_title
  if not name or #name == 0 then
    name = (tab.active_pane.title:match('[^/\\]*$') or ''):gsub('%.%w+$', '')
  end
  local title = index .. ' ' .. icon .. ' ' .. name
  if #title > conf.tab_max_width then
    title = wezterm.truncate_right(title, conf.tab_max_width - (#index + #icon + 4)) .. '…'
  end
  local colors = palette.inactive_tab
  if tab.is_active then
    colors = palette.active_tab
  elseif hover then
    colors = palette.inactive_tab_hover
  end
  return {
    { Background = { Color = colors.bg_color } },
    { Foreground = { Color = colors.fg_color } },
    { Text = title .. '  ' },
  }
end)

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
-- Hover: fondo entre inactiva y activa, texto en el morado de acento (botón Keys, marcas de Enter)
config.colors.tab_bar.inactive_tab_hover.bg_color = '#343746'
config.colors.tab_bar.inactive_tab_hover.fg_color = '#bd93f9'

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
local function wez(section, keys, desc, key, mods, action)
  return { group = 'wezterm', section = section, keys = keys, desc = desc, key = key, mods = mods, action = action }
end

local KEYMAP = {
  -- Pestañas (mismos atajos que trae WezTerm, declarados para que salgan en la ayuda)
  wez('tabs', 'Ctrl+Tab', { en = 'Next tab', es = 'Pestaña siguiente' },
    'Tab', 'CTRL', act.ActivateTabRelative(1)),
  wez('tabs', 'Ctrl+Shift+Tab', { en = 'Previous tab', es = 'Pestaña anterior' },
    'Tab', 'CTRL|SHIFT', act.ActivateTabRelative(-1)),
  wez('tabs', 'Ctrl+Shift+PageUp', { en = 'Move tab left', es = 'Mover pestaña a la izquierda' },
    'PageUp', 'CTRL|SHIFT', act.MoveTabRelative(-1)),
  wez('tabs', 'Ctrl+Shift+PageDown', { en = 'Move tab right', es = 'Mover pestaña a la derecha' },
    'PageDown', 'CTRL|SHIFT', act.MoveTabRelative(1)),
  { group = 'wezterm', section = 'tabs', keys = 'Ctrl+Shift+1..9',
    desc = { en = 'Go to tab 1-8 (9 = last)', es = 'Ir a la pestaña 1-8 (9 = última)' } },

  -- Splits
  wez('panes', 'Ctrl+Shift+F', { en = 'Split pane horizontally', es = 'Dividir panel en horizontal' },
    'f', 'CTRL|SHIFT', act.SplitHorizontal { domain = 'CurrentPaneDomain' }),
  wez('panes', 'Ctrl+Shift+D', { en = 'Split pane vertically', es = 'Dividir panel en vertical' },
    'd', 'CTRL|SHIFT', act.SplitVertical { domain = 'CurrentPaneDomain' }),

  -- Cambiar entre paneles
  wez('panes', 'Ctrl+Left', { en = 'Go to the pane on the left', es = 'Ir al panel de la izquierda' },
    'LeftArrow', 'CTRL', act.ActivatePaneDirection 'Left'),
  wez('panes', 'Ctrl+Right', { en = 'Go to the pane on the right', es = 'Ir al panel de la derecha' },
    'RightArrow', 'CTRL', act.ActivatePaneDirection 'Right'),
  wez('panes', 'Ctrl+Up', { en = 'Go to the pane above', es = 'Ir al panel de arriba' },
    'UpArrow', 'CTRL', act.ActivatePaneDirection 'Up'),
  wez('panes', 'Ctrl+Down', { en = 'Go to the pane below', es = 'Ir al panel de abajo' },
    'DownArrow', 'CTRL', act.ActivatePaneDirection 'Down'),

  -- Zoom del panel
  wez('panes', 'Ctrl+Shift+Z', { en = 'Zoom the pane in or out', es = 'Zoom del panel (activar/quitar)' },
    'z', 'CTRL|SHIFT', act.TogglePaneZoomState),

  -- Redimensionar paneles
  wez('panes', 'Alt+Left', { en = 'Move the pane border left', es = 'Mover el borde del panel a la izquierda' },
    'LeftArrow', 'OPT', act.AdjustPaneSize { 'Left', 5 }),
  wez('panes', 'Alt+Right', { en = 'Move the pane border right', es = 'Mover el borde del panel a la derecha' },
    'RightArrow', 'OPT', act.AdjustPaneSize { 'Right', 5 }),
  wez('panes', 'Alt+Up', { en = 'Move the pane border up', es = 'Mover el borde del panel hacia arriba' },
    'UpArrow', 'OPT', act.AdjustPaneSize { 'Up', 5 }),
  wez('panes', 'Alt+Down', { en = 'Move the pane border down', es = 'Mover el borde del panel hacia abajo' },
    'DownArrow', 'OPT', act.AdjustPaneSize { 'Down', 5 }),

  -- Cerrar panel
  wez('panes', 'Ctrl+Shift+W', { en = 'Close the current pane', es = 'Cerrar el panel actual' },
    'w', 'CTRL|SHIFT', act.CloseCurrentPane { confirm = true }),

  -- 4) Atajo para recargar config
  wez('help', 'Ctrl+Shift+R', { en = 'Reload the config', es = 'Recargar la config' },
    'r', 'CTRL|SHIFT', act.ReloadConfiguration),
}

config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.8,
}

-- Split con tmux en el pane actual (Ctrl+Shift+Y; la T quedó para nueva pestaña)
table.insert(KEYMAP, wez('panes', 'Ctrl+Shift+Y',
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

table.insert(KEYMAP, wez('panes', 'Ctrl+Space s', { en = 'Save the pane layout', es = 'Guardar el layout de paneles' },
  's', 'LEADER', wezterm.action_callback(function() save_layout() end)))
table.insert(KEYMAP, wez('panes', 'Ctrl+Space r', { en = 'Restore the saved layout', es = 'Restaurar el layout guardado' },
  'r', 'LEADER', wezterm.action_callback(function() restore_layout() end)))

-- Nueva pestaña: Ctrl+Shift+T
table.insert(KEYMAP, wez('tabs', 'Ctrl+Shift+T', { en = 'New tab', es = 'Nueva pestaña' },
  'T', 'CTRL|SHIFT', act.SpawnTab 'CurrentPaneDomain'))

-- =========================================================
-- 7) Ayuda de atajos: F1, o click en el botón "Keys"/"Atajos" de la barra de pestañas
--    Lista KEYMAP con búsqueda fuzzy. Enter sobre un atajo de WezTerm lo ejecuta;
--    sobre uno de tmux o zsh solo cierra, porque WezTerm no puede dispararlos.
-- =========================================================
local function tr(t) return t[HELP_LANG] or t.en end

local function info(group, keys, desc) return { group = group, section = group, keys = keys, desc = desc } end

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

-- Colores Dracula: un ícono y un color por grupo; el texto de la fila, en gris.
local HELP_GROUPS = {
  wezterm = { icon = wezterm.nerdfonts.dev_terminal,      color = '#bd93f9' },
  tmux    = { icon = wezterm.nerdfonts.cod_terminal_tmux, color = '#50fa7b' },
  zsh     = { icon = wezterm.nerdfonts.cod_terminal,      color = '#8be9fd' },
}

-- Secciones de la ayuda, en este orden; cada entrada de KEYMAP dice a cuál va. Los títulos
-- van ya en mayúsculas: upper() de Lua trabaja por bytes y dejaría "PESTAñAS".
local HELP_SECTIONS = {
  { id = 'help',  title = { en = 'HELP & CONFIG',    es = 'AYUDA Y CONFIG' } },
  { id = 'tabs',  title = { en = 'TABS',             es = 'PESTAÑAS' } },
  { id = 'panes', title = { en = 'PANES & LAYOUT',   es = 'PANELES Y LAYOUT' } },
  { id = 'tmux',  title = { en = 'TMUX · REFERENCE', es = 'TMUX · REFERENCIA' } },
  { id = 'zsh',   title = { en = 'ZSH · REFERENCE',  es = 'ZSH · REFERENCIA' } },
}

-- Filas compactas (hasta 80 columnas) para que la marca de Enter quede cerca del texto.
local KEYS_COLS, MARK_COLS = 22, 2
local RET = wezterm.nerdfonts.md_keyboard_return

-- Ancho en celdas: un carácter UTF-8 por celda (íconos Nerd Font incluidos).
local function cells(s) return select(2, s:gsub('[^\128-\191]', '')) end
local function pad(s, n) return s .. string.rep(' ', n - cells(s)) end

-- Recorta a n celdas con "…" (en paneles angostos), sin partir un carácter UTF-8.
local function fit(s, n)
  if cells(s) <= n then return s end
  local out, used = {}, 0
  for ch in s:gmatch('[\1-\127\194-\244][\128-\191]*') do
    if used == n - 1 then break end
    table.insert(out, ch)
    used = used + 1
  end
  return table.concat(out) .. '…'
end

-- Las filas de WezTerm terminan en la marca de Enter; las de tmux y zsh van tenues y sin
-- marca (su título ya dice que son de referencia), igual que un rango como Ctrl+Shift+1..9.
-- Después del ícono, todo va en un solo color: WezTerm marca la fila seleccionada
-- invirtiendo los colores de cada tramo, y con uno solo se ve como un bloque parejo.
local function help_row(k, row_cols)
  local g = HELP_GROUPS[k.group]
  local runnable = k.action ~= nil
  local desc_cols = row_cols - 4 - KEYS_COLS - MARK_COLS - 1
  return wezterm.format {
    { Foreground = { Color = g.color } }, { Text = ' ' .. g.icon .. '  ' },
    { Foreground = { Color = k.group == 'wezterm' and '#c0c4d6' or '#6272a4' } },
    { Attribute = { Intensity = 'Bold' } }, { Text = pad(fit(k.keys, KEYS_COLS), KEYS_COLS) },
    { Attribute = { Intensity = 'Normal' } },
    { Text = pad(fit(tr(k.desc), desc_cols), desc_cols) .. ' ' .. (runnable and RET or ' ') .. ' ' },
  }
end

local function help_header(section, row_cols)
  local text = ' ── ' .. tr(section.title) .. ' '
  return wezterm.format {
    { Foreground = { Color = '#6272a4' } }, { Attribute = { Intensity = 'Bold' } },
    { Text = text .. string.rep('─', row_cols - cells(text) - 1) .. ' ' },
  }
end

-- La ventana es semitransparente: mientras la ayuda está abierta se vuelve opaca, para que
-- la lista no se mezcle con lo que hay detrás, y al cerrarla (Enter o Esc) recupera lo que
-- tenía. Pintar un fondo por fila no sirve: parpadea al mover la selección.
local function set_opacity(window, value)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = value
  window:set_config_overrides(overrides)
end

-- Por ventana: la opacidad de antes de la primera ayuda y los paneles con una ayuda
-- abierta. Se restaura cuando se cierra la última, aunque haya dos abiertas a la vez.
local help_open = {}

local function help_opened(window, pane)
  local state = help_open[window:window_id()]
  if not state then
    state = { before = (window:get_config_overrides() or {}).window_background_opacity, panes = {} }
    help_open[window:window_id()] = state
    set_opacity(window, 1.0)
  end
  state.panes[pane:pane_id()] = true
end

local function help_closed(window, pane_id)
  local state = help_open[window:window_id()]
  if not state then return end
  state.panes[pane_id] = nil
  if next(state.panes) == nil then
    help_open[window:window_id()] = nil
    set_opacity(window, state.before)
  end
end

-- Un panel cerrado con la ayuda abierta nunca llama al callback: update-status (cada
-- segundo) lo nota porque el panel ya no existe, y lo da por cerrado.
wezterm.on('update-status', function(window)
  local state = help_open[window:window_id()]
  if not state then return end
  for id in pairs(state.panes) do
    if not wezterm.mux.get_pane(id) then help_closed(window, id) end
  end
end)

local function show_help(window, pane)
  local row_cols = math.max(40, math.min(80, pane:get_dimensions().cols - 8))
  local choices, run, entries = {}, {}, 0
  for _, section in ipairs(HELP_SECTIONS) do
    table.insert(choices, { id = 'header:' .. section.id, label = help_header(section, row_cols) })
    for i, k in ipairs(KEYMAP) do
      if k.section == section.id then
        local id = k.key and (k.key .. '|' .. (k.mods or '')) or (k.group .. ':' .. i)
        run[id] = k.action
        entries = entries + 1
        table.insert(choices, { id = id, label = help_row(k, row_cols) })
      end
    end
  end
  help_opened(window, pane)
  window:perform_action(act.InputSelector {
    -- Título de la pestaña temporal: distinto del botón "Keys" para no verlo dos veces.
    title = wezterm.nerdfonts.md_keyboard .. ' ' .. tr { en = 'Help', es = 'Ayuda' },
    choices = choices,
    fuzzy = true,
    fuzzy_description = wezterm.nerdfonts.md_keyboard .. '  ' .. string.format(tr {
      en = 'Search %d keys  ·  %s runs WezTerm ones  ·  Esc closes: ',
      es = 'Buscar entre %d atajos  ·  %s ejecuta los de WezTerm  ·  Esc cierra: ',
    }, entries, RET),
    action = wezterm.action_callback(function(win, p, id)
      help_closed(win, pane:pane_id())
      if id and run[id] then win:perform_action(run[id], p) end
    end),
  }, pane)
end

table.insert(KEYMAP, 1, wez('help', 'F1', { en = 'Show this help', es = 'Mostrar esta ayuda' },
  'F1', nil, wezterm.action_callback(show_help)))

-- Transparencia: Ctrl+Alt+Up/Down de a 5% entre 30% y 100%, y Ctrl+Alt+0 vuelve al valor
-- de config.window_background_opacity. Se guarda como override de la ventana, así que la
-- ayuda (que la vuelve opaca mientras está abierta) la recupera al cerrarse.
local OPACITY_STEP, OPACITY_MIN = 0.05, 0.3

local function change_opacity(delta)
  return wezterm.action_callback(function(window)
    local current = (window:get_config_overrides() or {}).window_background_opacity
      or config.window_background_opacity
    local value = math.min(1.0, math.max(OPACITY_MIN, current + delta))
    set_opacity(window, math.floor(value * 100 + 0.5) / 100)
  end)
end

table.insert(KEYMAP, wez('help', 'Ctrl+Alt+Up', { en = 'Make the window more opaque', es = 'Ventana menos transparente' },
  'UpArrow', 'CTRL|ALT', change_opacity(OPACITY_STEP)))
table.insert(KEYMAP, wez('help', 'Ctrl+Alt+Down', { en = 'Make the window more transparent', es = 'Ventana más transparente' },
  'DownArrow', 'CTRL|ALT', change_opacity(-OPACITY_STEP)))
table.insert(KEYMAP, wez('help', 'Ctrl+Alt+0', { en = 'Reset the window opacity', es = 'Volver a la transparencia de la config' },
  '0', 'CTRL|ALT', wezterm.action_callback(function(window) set_opacity(window, nil) end)))

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