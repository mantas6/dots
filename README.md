# dotfiles

```
    █     █
█ ███████████ █
    █     █
█ ███ ███ ███ 
  █ █ █ █ █
█ ███ ███ █ █
```

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
mkdir "$HOME/Repos"
gh repo clone mantas6/dotfiles "$HOME/Repos/dotfiles"
cd "$HOME/Repos/dotfiles"
./stow
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
./stow

git status
# Move/clean unstaged files
```
