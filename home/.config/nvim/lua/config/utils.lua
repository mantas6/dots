function ClosestGitignoreDir(start_dir, cwd)
  cwd = vim.fn.fnamemodify(cwd or vim.fn.getcwd(), ':p'):gsub('/$', '')
  local dir = vim.fn.fnamemodify(start_dir or vim.fn.expand('%:p:h'), ':p'):gsub('/$', '')

  if dir ~= cwd and not dir:find('^' .. vim.pesc(cwd .. '/')) then
    return cwd
  end

  while true do
    if vim.fn.filereadable(dir .. '/.gitignore') == 1 then
      return dir
    end

    if dir == cwd then
      return cwd
    end

    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then
      return cwd
    end

    dir = parent
  end
end

function GetScopePaths()
  local file_paths = {}
  local scope_path = vim.fn.getcwd() .. '/.scope'
  if vim.fn.filereadable(scope_path) == 1 then
    for _, line in ipairs(vim.fn.readfile(scope_path)) do
      if line ~= '' then
        table.insert(file_paths, line)
      end
    end
  end

  return file_paths
end

return {
  closest_gitignore_dir = ClosestGitignoreDir,
  get_scope_paths = GetScopePaths,
}
