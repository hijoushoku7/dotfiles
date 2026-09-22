local wezterm = require("wezterm")
local config = wezterm.config_builder()
local mux = wezterm.mux

config.automatically_reload_config = true
config.font_size = 12.0
config.use_ime = true
config.window_background_opacity = 1
config.macos_window_background_blur = 20

--　ssh設定
-- WezTerm 内蔵 ssh_domain は使わず、ローカルタブで OpenSSH の ssh.exe を起動して
-- ~/.ssh/config のエイリアス (dev/web/mc) にそのまま任せる。
config.default_domain = 'local'

config.wsl_domains = {
  {
    name = 'WSL:Ubuntu',
    distribution = 'Ubuntu',    -- `wsl -l` で出る実際の名前に
  },
}


wezterm.on("gui-startup", function(cmd)
  -- 1つ目のタブ兼ウィンドウを dev で生成 (ssh.exe を直接起動)
  local tab, pane, window = mux.spawn_window({
    args = { "ssh", "dev" },
    domain = { DomainName = "local" },
  })
  tab:set_title("dev")

  -- 2つ目のタブ: web
  local web_tab = window:spawn_tab({
    args = { "ssh", "web" },
    domain = { DomainName = "local" },
  })
  web_tab:set_title("web")

  -- 3つ目のタブ: mc
  local mc_tab = window:spawn_tab({
    args = { "ssh", "mc" },
    domain = { DomainName = "local" },
  })
  mc_tab:set_title("mc")

  -- 3つ目のタブ: WSL
  window:spawn_tab({
    args = {"powershell.exe"},
    domain = { DomainName = "local" },
  })

  -- 最初(dev)のタブをアクティブにしておく
  tab:activate()
end)

----------------------------------------------------
-- Tab
----------------------------------------------------
-- タイトルバーを非表示
config.window_decorations = "RESIZE"
-- タブバーの表示
config.show_tabs_in_tab_bar = true
-- タブが一つの時は非表示
config.hide_tab_bar_if_only_one_tab = true
-- falseにするとタブバーの透過が効かなくなる
-- config.use_fancy_tab_bar = false

-- タブバーの透過
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

-- タブバーを背景色に合わせる
config.window_background_gradient = {
  colors = { "#131d27" },
}

-- タブの追加ボタンを非表示
config.show_new_tab_button_in_tab_bar = false
-- nightlyのみ使用可能
-- タブの閉じるボタンを非表示
-- config.show_close_tab_button_in_tabs = false

-- タブ同士の境界線を非表示
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
}

-- タブの形をカスタマイズ
-- タブの左側の装飾
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
-- タブの右側の装飾
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#798438"
  local foreground = "#FFFFFF"
  local edge_background = "none"
  if tab.is_active then
    background = "#be5ba2"
    foreground = "#FFFFFF"
  end
  local edge_foreground = background
  -- 明示的に付けたタブ名 > ペインのタイトル
  local name = (tab.tab_title and #tab.tab_title > 0 and tab.tab_title)
    or tab.active_pane.title
  local title = "   " .. wezterm.truncate_right(name, max_width - 1) .. "   "
  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

----------------------------------------------------
-- keybinds
----------------------------------------------------
config.disable_default_key_bindings = true
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }

return config
