# ftp

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
