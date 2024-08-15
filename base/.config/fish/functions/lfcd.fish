function lf
    cd "$(command lf -print-last-dir "$argv")" || return
end
