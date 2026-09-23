# Notes

## Linux

Filtered information about running processes:

```sh
ps -fp $(pgrep php)
```

## Dictionaries

- API: <https://github.com/meetDeveloper/freeDictionaryAPI>
- StarDict guide: <https://owenh.net/stardict>
- Dictd: <https://wiki.archlinux.org/title/Dictd>

## SSH

### Multiplexing

Speed up connection initiation times.

```ssh-config
Host *
    ControlMaster auto
    ControlPath ~/.ssh/ssh_mux_%h_%p_%r
    ControlPersist 60m
```

## FTP

```sh
#!/usr/bin/env bash
# nnoremap <leader>w :silent !./upload %<CR>
# mkdir
# cmds=$(find . -type d -not -path './.git/*' | sed 's|^|mkdir -p |')

# git files bash array
# IFS=$'\n'
# cmds=$(echo "${files[*]}" | sed 's|\(.*\)|put \1 -o \1|')

cmds=$(echo "$1" | sed 's|\(.*\)|put \1 -o \1|')

lftp -u $user,$pass $host <<EOF
    set ssl:verify-certificate no
    cd $root_dir
    $cmds
EOF
```
