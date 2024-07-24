# dotfiles

## Software

- `archlinux`
- `bash`
- `tmux`
- `alacritty`
- `lf` or `yazi` - not decided yet
- `neovim`
- `awesome`
- `rofi` - app launcher, pass menu (`rofi-pass`), emoji picker (`rofi-emoji`)
- `pass`
- `stow` - dot files management

## Setup

### Home configuration

Run `./stow`

If stow fails, remove conflicting files (preferably to trash) and run again. Pay close attention to the output to make sure that the links that it creates make sense.

### Dependencies

`bluez bluez-utilsj udisks2`
`lxpolkit xss-lock i3lock`
`unclutter numlockx redshift autorandr`
`ttf-anonymous-pro ttf-anonymouspro-nerd lxappearance gnome-themes-extra`
`btop htop fastfetch`
`starship zoxide`
`pass rofi rofi-pass rofi-emoji rofi-calc`
`base-devel pacman-contrib`
`git node npm php luarocks wget tldr`
`dashbinsh paru-bin`
