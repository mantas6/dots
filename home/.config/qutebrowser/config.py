# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103

#  pylint: disable=C0111
# from qutebrowser.config.configfiles import ConfigAPI  # noqa: F401
# from qutebrowser.config.config import ConfigContainer  # noqa: F401
# config: ConfigAPI = config  # noqa: F821 pylint: disable=E0602,C0103
# c: ConfigContainer = c  # noqa: F821 pylint: disable=E0602,C0103

c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = 'lightness-cielab'
c.colors.webpage.darkmode.policy.images = 'never'
# c.set('colors.webpage.darkmode.enabled', False, 'file://*')

c.fonts.default_family = '"Jetbrains Mono"'
c.fonts.default_size = '12pt'

c.fonts.web.size.default = 20
c.zoom.default = 110

c.tabs.padding = {'top': 5, 'bottom': 5, 'left': 9, 'right': 9}
# c.tabs.indicator.width = 0 # no tab indicators
c.tabs.width = '7%'

c.content.mute = True
c.content.cookies.accept = 'no-3rdparty'

c.downloads.location.directory = '~/Downloads'

c.tabs.show = 'multiple'

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


c.editor.command = [
    'oneshot',
    'nvim',
    '-f',
    '{file}',
    '-c',
    'normal {line}G{column0}l',
]

c.content.blocking.enabled = True
# c.content.blocking.adblock.lists = [
# ]

config.source('theme.py')
config.load_autoconfig()

