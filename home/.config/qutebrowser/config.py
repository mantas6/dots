# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103

#  pylint: disable=C0111
# from qutebrowser.config.configfiles import ConfigAPI  # noqa: F401
# from qutebrowser.config.config import ConfigContainer  # noqa: F401
# config: ConfigAPI = config  # noqa: F821 pylint: disable=E0602,C0103
# c: ConfigContainer = c  # noqa: F821 pylint: disable=E0602,C0103

c.auto_save.session = False
c.confirm_quit = ['always']
c.completion.cmd_history_max_items = 5000
c.new_instance_open_target = 'window'
c.window.hide_decoration = True

c.input.mouse.back_forward_buttons = False

c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = 'lightness-cielab'
c.colors.webpage.darkmode.policy.images = 'never'
# c.set('colors.webpage.darkmode.enabled', False, 'file://*')

c.fonts.default_family = '"Jetbrains Mono"'
# c.fonts.default_size = '12pt'
c.fonts.default_size = '16pt'

c.fonts.web.size.default = 20
c.zoom.default = 110

c.tabs.show = 'multiple'
c.tabs.title.format = '{audio}{index} {current_title}'
c.tabs.padding = {'top': 5, 'bottom': 5, 'left': 9, 'right': 9}
# c.tabs.indicator.width = 0 # no tab indicators
# c.tabs.width = '7%'
c.tabs.mousewheel_switching = False

c.window.title_format = '{current_title}';
# c.statusbar.show = 'in-mode'

c.content.mute = True
c.content.cookies.accept = 'no-3rdparty'
c.content.notifications.enabled = False
c.content.autoplay = False
c.content.geolocation = False
c.content.headers.custom = {}
# c.content.javascript.alert = False
# c.content.netrc_file = ''
c.content.print_element_backgrounds = False
c.content.blocking.enabled = True

c.downloads.location.directory = '~/Downloads'
c.downloads.location.prompt = False
# c.downloads.position = 'bottom'

# Keybinds
# config.bind('<Ctrl-v>', 'spawn mpv {url}')
# config.unbind('<Ctrl-v>', mode='normal')

config.bind('so', 'config-source')

i = 1
while i <= 9:
    config.bind(f"<Ctrl-{i}>", f"tab-focus {i}")
    i += 1

c.url.default_page = 'https://google.com'
c.url.start_pages = 'https://google.com'

c.url.searchengines = {
    'DEFAULT': 'https://google.com/search?q={}',
    'duck': 'https://duckduckgo.com/?q={}',
    'am': 'https://amazon.com/s?k={}',
    'aw': 'https://wiki.archlinux.org/?search={}',
    're': 'https://reddit.com/r/{}',
    'ub': 'https://urbandictionary.com/define.php?term={}',
    'wiki': 'https://en.wikipedia.org/wiki/{}',
    'yt': 'https://youtube.com/results?search_query={}',
}

c.completion.open_categories = ['searchengines', 'quickmarks', 'bookmarks', 'history', 'filesystem']

c.editor.command = [
    'oneshot',
    'nvim',
    '-f',
    '{file}',
    '-c',
    'normal {line}G{column0}l',
]

# Site configuration
#
# config.set('content.images', False, '*://example.com/')
# with config.pattern('*://example.com/') as p:
#     p.content.images = False

# c.content.blocking.adblock.lists = [
# ]

config.source('theme.py')
config.load_autoconfig()

