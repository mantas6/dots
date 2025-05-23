# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103

config.load_autoconfig()

c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = 'lightness-cielab'
c.colors.webpage.darkmode.policy.images = 'never'

c.fonts.default_size = '16pt'

c.tabs.padding = {'top': 5, 'bottom': 5, 'left': 9, 'right': 9}
# c.tabs.indicator.width = 0 # no tab indicators
c.tabs.width = '7%'
