# dots

## Setup

### Install core dependencies

Debian

```sh
sudo apt install git stow zsh
```

Arch Linux

```sh
sudo pacman -S git stow zsh
```

### Change the shell

```sh
chsh -s /usr/bin/zsh
```

### Clone the repo and link

```sh
git clone https://github.com/mantas6/dots.git "$HOME/.dots"
cd "$HOME/.dots"
./bin/dot/stw
```
If stow fails, remove conflicting files (preferably to trash) and run again. Pay close attention to the output to make sure that the links that it creates make sense.

### Migrating to a new git repo name

```sh
cd ~/Repos/dotfiles
./stow -D

git remote set-url origin https://github.com/mantas6/dots.git
git pull

mv ~/Repos/dotfiles ~/.dots
cd ~/.dots
./bin/dot/stw

git status
# Move/clean unstaged files
```

## Services

Located in `srv` directory.

- Docker compose (must container `docker-compose.yml`)
- Generic user systemd units (must contain `run` executable)
- Packages (must contain `build` executable)

Use `enservice*` to enable
