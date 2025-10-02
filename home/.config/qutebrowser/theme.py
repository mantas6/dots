clr = {
    "bg": "#1D252C", # bg, gunmetal
    "bg-alt": "#171D22", #bg-alt, eerie-black
    # "rich-black": "#001021", # rich black FOGRA 29 (extra)
    "smoky-black": "#0F110C", # smoky black (extra)
    "bg-selected": "#10151C", #bg-selected
    "bg-lightened": "#41505e", #bg-lightened
    "fg-disabled": "#56697a", #fg-disabled
    "fg": "#a0b3c5", #base05 (white-ish, cadet-blue-crayola)
    # "cbc-alt": "#9CAABB", # base08 (white-ish, cadet-blue alt)
    # "fg-alt": "#728ca0", #base06 (bright white, light-slate-gray)
    "maya-blue": "#5ec4ff", # blue
    "paradise-pink": "#d95468", # red
    # "lava-red": "#C81D25", # red (extra)
    "persian-orange": "#D98E48", # orange
    "gold-crayola": "#EBBF83", # yellow
    "celadon": "#8BD49C", # green
    "dark-cyan": "#008b94", # dark cyan
    "cornflower-blue": "#539AFC", # bright blue
    "shimmering-blush": "#e27e8d", # magenta
    "maroon-x11": "#b62d65", # violet
    "electric-blue": "#70E1E8", # cyan (extra)
    "midnight-green-eagle": "#114B5F" # unused (extra)
}

c.colors.completion.fg = clr["fg"]
c.colors.completion.odd.bg = clr["bg-alt"]
c.colors.completion.even.bg = clr["bg"]
c.colors.completion.category.fg = clr["cornflower-blue"]
c.colors.completion.category.bg = clr["bg-alt"]
c.colors.completion.category.border.top = clr["smoky-black"]
c.colors.completion.category.border.bottom = clr["smoky-black"]
c.colors.completion.item.selected.fg = clr["electric-blue"]
c.colors.completion.item.selected.bg = clr["bg-selected"]
c.colors.completion.item.selected.border.top = clr["bg-selected"]
c.colors.completion.item.selected.border.bottom = clr["bg-selected"]
c.colors.completion.item.selected.match.fg = clr["persian-orange"]
c.colors.completion.match.fg = clr["gold-crayola"]
c.colors.completion.scrollbar.fg = clr["fg"]
c.colors.completion.scrollbar.bg = clr["bg"]
c.colors.contextmenu.disabled.bg = clr["bg-alt"]
c.colors.contextmenu.disabled.fg = clr["fg-disabled"]
c.colors.contextmenu.menu.bg = clr["bg"]
c.colors.contextmenu.menu.fg =  clr["fg"]
c.colors.contextmenu.selected.bg = clr["bg-selected"]
c.colors.contextmenu.selected.fg = clr["fg"]
c.colors.downloads.bar.bg = clr["bg"]
c.colors.downloads.start.fg = clr["bg"]
c.colors.downloads.start.bg = clr["cornflower-blue"]
c.colors.downloads.stop.fg = clr["bg"]
c.colors.downloads.stop.bg = clr["dark-cyan"]
c.colors.downloads.error.fg = clr["paradise-pink"]
c.colors.hints.fg = clr["bg"]
c.colors.hints.bg = clr["gold-crayola"]
c.colors.hints.match.fg = clr["fg"]
c.colors.keyhint.fg = clr["fg"]
c.colors.keyhint.suffix.fg = clr["gold-crayola"]
c.colors.keyhint.bg = clr["bg"]
c.colors.messages.error.fg = clr["paradise-pink"]
c.colors.messages.error.bg = clr["bg"]
c.colors.messages.error.border = clr["paradise-pink"]
c.colors.messages.warning.fg = clr["persian-orange"]
c.colors.messages.warning.bg = clr["bg"]
c.colors.messages.warning.border = clr["persian-orange"]
c.colors.messages.info.fg = clr["electric-blue"]
c.colors.messages.info.bg = clr["bg"]
c.colors.messages.info.border = clr["electric-blue"]
c.colors.prompts.fg = clr["fg"]
c.colors.prompts.border = clr["bg"]
c.colors.prompts.bg = clr["bg"]
c.colors.prompts.selected.bg = clr["bg-selected"]
c.colors.prompts.selected.fg = clr["fg"]
c.colors.statusbar.normal.fg = clr["celadon"]
c.colors.statusbar.normal.bg = clr["bg"]
c.colors.statusbar.insert.fg = clr["bg"]
c.colors.statusbar.insert.bg = clr["cornflower-blue"]
c.colors.statusbar.passthrough.fg = clr["bg"]
c.colors.statusbar.passthrough.bg = clr["dark-cyan"]
c.colors.statusbar.private.fg = clr["bg"]
c.colors.statusbar.private.bg = clr["bg-alt"]
c.colors.statusbar.command.fg = clr["fg"]
c.colors.statusbar.command.bg = clr["bg"]
c.colors.statusbar.command.private.fg = clr["fg"]
c.colors.statusbar.command.private.bg = clr["bg"]
c.colors.statusbar.caret.fg = clr["bg"]
c.colors.statusbar.caret.bg = clr["maroon-x11"]
c.colors.statusbar.caret.selection.fg = clr["bg"]
c.colors.statusbar.caret.selection.bg = clr["cornflower-blue"]
c.colors.statusbar.progress.bg = clr["cornflower-blue"]
c.colors.statusbar.url.fg = clr["fg"]
c.colors.statusbar.url.error.fg = clr["paradise-pink"]
c.colors.statusbar.url.hover.fg = clr["electric-blue"] # ex. cadet blue crayola
c.colors.statusbar.url.success.http.fg = clr["fg"]
c.colors.statusbar.url.success.https.fg = clr["celadon"]
c.colors.statusbar.url.warn.fg = clr["shimmering-blush"]
c.colors.tabs.bar.bg = clr["bg"]
c.colors.tabs.indicator.start = clr["cornflower-blue"]
c.colors.tabs.indicator.stop = clr["dark-cyan"]
c.colors.tabs.indicator.error = clr["paradise-pink"]
c.colors.tabs.odd.fg = clr["fg"]
c.colors.tabs.odd.bg = clr["bg-selected"]
c.colors.tabs.even.fg = clr["fg"]
c.colors.tabs.even.bg = clr["bg-selected"]
c.colors.tabs.pinned.even.bg = clr["bg-selected"]
c.colors.tabs.pinned.even.fg = clr["fg"]
c.colors.tabs.pinned.odd.bg = clr["bg-selected"]
c.colors.tabs.pinned.odd.fg = clr["fg"]
c.colors.tabs.pinned.selected.even.bg = clr["bg-lightened"]
c.colors.tabs.pinned.selected.even.fg = clr["fg"]
c.colors.tabs.pinned.selected.odd.bg = clr["bg-lightened"]
c.colors.tabs.pinned.selected.odd.fg = clr["fg"]
c.colors.tabs.selected.odd.fg = clr["fg"]
c.colors.tabs.selected.odd.bg = clr["bg-lightened"]
c.colors.tabs.selected.even.fg = clr["fg"]
c.colors.tabs.selected.even.bg = clr["bg-lightened"]
