-- CONFIGURACIÓN COMPLETA DE RICING PARA WEZTERM
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 🎨 COLORES Y TEMA
config.color_scheme = 'Tokyo Night'

-- Esquema de colores personalizado (alternativa)
config.colors = {
  foreground = '#c0caf5',
  background = '#1a1b26',
  cursor_bg = '#c0caf5',
  cursor_fg = '#1a1b26',
  cursor_border = '#c0caf5',
  selection_fg = '#c0caf5',
  selection_bg = '#33467c',
  split = '#7aa2f7',  -- Color azul Tokyo Night para bordes
  
  ansi = {
    '#15161e', '#f7768e', '#9ece6a', '#e0af68',
    '#7aa2f7', '#bb9af7', '#7dcfff', '#a9b1d6',
  },
  brights = {
    '#414868', '#f7768e', '#9ece6a', '#e0af68',
    '#7aa2f7', '#bb9af7', '#7dcfff', '#c0caf5',
  },
}

-- 🔤 FUENTES
config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'Fira Code',
  'monospace',
}
config.font_size = 13
config.line_height = 1.1

-- ✨ EFECTOS VISUALES
config.window_background_opacity = 0.85
config.text_background_opacity = 0.8

-- Imagen de fondo (opcional)
-- config.window_background_image = '/path/to/your/wallpaper.jpg'
-- config.window_background_image_hsb = {
--   brightness = 0.3,
--   hue = 1.0,
--   saturation = 1.0,
-- }

-- 🪟 VENTANA
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false

-- Eliminar barra de tabs
config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Padding
config.window_padding = {
  left = 15,
  right = 15,
  top = 15,
  bottom = 15,
}

-- 🖱️ CURSOR
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- ⌨️ KEYBINDINGS PERSONALIZADOS
config.keys = {
  -- Split horizontal
  {
    key = 'f',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  
  -- Split vertical
  {
    key = 'd',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  
  -- Cambiar entre paneles
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  
  -- Zoom del panel
  {
    key = 'z',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.TogglePaneZoomState,
  },

  -- ═══════════════════════════════════════════════════════════════
  -- 📏 REDIMENSIONAR PANELES
  -- ═══════════════════════════════════════════════════════════════
  
  {
    key = 'LeftArrow',
    mods = 'OPT',
    action = wezterm.action.AdjustPaneSize { 'Left', 5 },
  },
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = wezterm.action.AdjustPaneSize { 'Right', 5 },
  },
  {
    key = 'UpArrow',
    mods = 'OPT',
    action = wezterm.action.AdjustPaneSize { 'Up', 5 },
  },
  {
    key = 'DownArrow',
    mods = 'OPT',
    action = wezterm.action.AdjustPaneSize { 'Down', 5 },
  },
  
  -- ═══════════════════════════════════════════════════════════════
  -- ❌ CERRAR PANELES
  -- ═══════════════════════════════════════════════════════════════
  
  {
    key = 'w',
    mods = 'CMD|SHIFT',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
}


-- 🎯 PANELES (para multiplexing)
config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.7,
}

-- ═══════════════════════════════════════════════════════════════
-- 📐 TAMAÑO Y POSICIÓN DE VENTANA
-- ═══════════════════════════════════════════════════════════════

-- Tamaño inicial (en columnas y filas)
config.initial_cols = 120  -- Ancho en columnas (caracteres)
config.initial_rows = 35   -- Alto en filas (líneas)

-- O alternativamente, abrir maximizada
-- config.window_decorations = "NONE"
-- config.native_macos_fullscreen_mode = false

-- Para centrar la ventana al abrir
config.window_frame = {
  font = wezterm.font { family = 'JetBrainsMono Nerd Font', weight = 'Bold' },
  font_size = 12.0,
}

-- Comportamiento responsive al redimensionar
config.adjust_window_size_when_changing_font_size = false
config.use_resize_increments = false

return config
