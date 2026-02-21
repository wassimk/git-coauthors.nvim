local M = {}

local async_coroutines = setmetatable({}, { __mode = 'k' })

local function run_cmd(cmd)
  local co = coroutine.running()
  if not co or not async_coroutines[co] then
    local output = vim.fn.system(cmd)
    return { stdout = output, code = vim.v.shell_error }
  end

  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      coroutine.resume(co, result)
    end)
  end)
  return coroutine.yield()
end

local function async_run(fn)
  local co = coroutine.create(fn)
  async_coroutines[co] = true
  coroutine.resume(co)
end

local function is_gh_available()
  return vim.fn.executable('gh') == 1
end

local function get_repo_info()
  local result = run_cmd({ 'gh', 'repo', 'view', '--json', 'owner,name', '--jq', '.owner.login + "/" + .name' })
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout)
end

local function get_current_gh_user()
  local result = run_cmd({ 'gh', 'api', 'user', '--jq', '.login' })
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout)
end

local function parse_git_log()
  local result = run_cmd({ 'git', 'log', '--format=%aN <%aE>' })
  if result.code ~= 0 then
    return {}, {}
  end
  local output = result.stdout

  local email_to_names = {}
  local name_to_emails = {}
  local seen = {}

  for line in output:gmatch('[^\r\n]+') do
    line = vim.trim(line)
    if line ~= '' and not seen[line] then
      seen[line] = true
      local name, email = line:match('^(.+) <(.+)>$')
      if name and email then
        email_to_names[email] = name
        if not name_to_emails[name] then
          name_to_emails[name] = {}
        end
        table.insert(name_to_emails[name], email)
      end
    end
  end

  return email_to_names, name_to_emails
end

local function first_real_email(emails)
  if not emails then
    return nil
  end
  for _, email in ipairs(emails) do
    if not email:find('noreply.github.com', 1, true) then
      return email
    end
  end
  return nil
end

local function find_real_email(display_name, login, database_id, email_to_names, name_to_emails)
  -- Try name match first (covers the common case where GitHub name == git config name)
  local real = first_real_email(name_to_emails[display_name])
  if real then
    return real
  end

  -- Fall back to noreply pattern match (finds users who commit with their noreply email)
  local noreply_patterns = {
    string.format('%s+%s@users.noreply.github.com', database_id, login),
    string.format('%s@users.noreply.github.com', login),
  }

  for _, pattern in ipairs(noreply_patterns) do
    local author_name = email_to_names[pattern]
    if author_name then
      real = first_real_email(name_to_emails[author_name])
      if real then
        return real
      end
    end
  end

  return nil
end

local function discover_from_github()
  if not is_gh_available() then
    return nil
  end

  local repo_info = get_repo_info()
  if not repo_info then
    return nil
  end

  local owner, repo_name = repo_info:match('^(.+)/(.+)$')
  if not owner or not repo_name then
    return nil
  end

  local current_user = get_current_gh_user()
  local handles = {}
  local has_next_page = true
  local cursor = ''

  while has_next_page do
    local after_clause = cursor ~= '' and string.format(', after: "%s"', cursor) or ''
    local query = string.format(
      '{ repository(owner: "%s", name: "%s") { collaborators(first: 100%s) { totalCount nodes { login name databaseId } pageInfo { hasNextPage endCursor } } } }',
      owner,
      repo_name,
      after_clause
    )

    local result = run_cmd({ 'gh', 'api', 'graphql', '-f', 'query=' .. query })
    if result.code ~= 0 then
      return nil
    end

    local ok, decoded = pcall(vim.fn.json_decode, result.stdout)
    if not ok or not decoded then
      return nil
    end

    if decoded.errors then
      return nil
    end

    local collaborators = decoded.data and decoded.data.repository and decoded.data.repository.collaborators
    if not collaborators then
      return nil
    end

    for _, node in ipairs(collaborators.nodes or {}) do
      local login = node.login
      local is_self = current_user and login == current_user
      local is_bot = login:find('%[bot%]')

      if not is_self and not is_bot then
        local display_name = node.name
        if display_name == nil or display_name == vim.NIL or display_name == '' then
          display_name = login
        end
        local database_id = node.databaseId
        local handle = '@' .. login
        local email = string.format('%s+%s@users.noreply.github.com', database_id, login)
        handles[handle] = string.format('%s <%s>', display_name, email)
      end
    end

    has_next_page = collaborators.pageInfo and collaborators.pageInfo.hasNextPage or false
    cursor = collaborators.pageInfo and collaborators.pageInfo.endCursor or ''
  end

  local email_to_names, name_to_emails = parse_git_log()
  for handle, value in pairs(handles) do
    local login = handle:sub(2)
    local display_name = value:match('^(.+) <')
    local db_id = value:match('<(%d+)+')
    if display_name and db_id then
      local real_email = find_real_email(display_name, login, db_id, email_to_names, name_to_emails)
      if real_email then
        handles[handle] = string.format('%s <%s>', display_name, real_email)
      end
    end
  end

  return handles
end

local function discover_from_git_log()
  local rev_result = run_cmd({ 'git', 'rev-parse', '--show-toplevel' })
  if rev_result.code ~= 0 then
    return {}
  end

  local current_name = vim.trim(run_cmd({ 'git', 'config', 'user.name' }).stdout)
  local current_email = vim.trim(run_cmd({ 'git', 'config', 'user.email' }).stdout)

  local log_result = run_cmd({ 'git', 'log', '--format=%aN <%aE>' })
  if log_result.code ~= 0 then
    return {}
  end
  local output = log_result.stdout

  local handles = {}
  local seen = {}

  for line in output:gmatch('[^\r\n]+') do
    line = vim.trim(line)
    if line ~= '' and not seen[line] then
      seen[line] = true
      local author_name, author_email = line:match('^(.+) <(.+)>$')
      if author_name and author_email then
        if author_name ~= current_name and author_email ~= current_email then
          handles['@' .. author_name] = line
        end
      end
    end
  end

  return handles
end

function M.discover(config)
  if config.discover == false then
    return {}
  end

  local github_handles = discover_from_github()
  if github_handles then
    return github_handles
  end

  return discover_from_git_log()
end

function M.discover_async(config, callback)
  if config.discover == false then
    return callback({})
  end

  async_run(function()
    local github_handles = discover_from_github()
    if github_handles then
      return callback(github_handles)
    end
    callback(discover_from_git_log())
  end)
end

return M
