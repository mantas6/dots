#!/usr/bin/env zsh

[ -x "$(command -v systemctl)" ] \
    && systemctl --user import-environment PATH
