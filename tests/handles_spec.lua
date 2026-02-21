local helpers = require('helpers')
local handles = require('git-coauthors.handles')
local discover = require('git-coauthors.discover')
local git_coauthors = require('git-coauthors')

describe('handles', function()
  local _original_discover_async

  before_each(function()
    helpers.setup_mocks()
    _original_discover_async = discover.discover_async
    -- Mock discover_async to call callback synchronously via sync discover()
    discover.discover_async = function(config, callback)
      callback(discover.discover(config))
    end
  end)

  after_each(function()
    discover.discover_async = _original_discover_async
    helpers.teardown_mocks()
  end)

  it('loads handles from JSON file when file exists', function()
    git_coauthors.setup()
    local result = handles.get()

    assert.is_not_nil(result)
    assert.equals('Alice Smith <alice@example.com>', result['@alice'])
    assert.equals('Bob Jones <bob@example.com>', result['@bob'])
  end)

  it('returns empty table when file does not exist and no inline handles', function()
    helpers.file_exists = false
    git_coauthors.setup()
    local result = handles.get()

    assert.is_not_nil(result)
    assert.same({}, result)
  end)

  it('merges inline handles over file handles', function()
    git_coauthors.setup({
      handles = {
        ['@alice'] = 'Alice Override <alice-new@example.com>',
        ['@carol'] = 'Carol Davis <carol@example.com>',
      },
    })
    local result = handles.get()

    assert.equals('Alice Override <alice-new@example.com>', result['@alice'])
    assert.equals('Bob Jones <bob@example.com>', result['@bob'])
    assert.equals('Carol Davis <carol@example.com>', result['@carol'])
  end)

  it('uses inline handles only when no file exists', function()
    helpers.file_exists = false
    git_coauthors.setup({
      handles = {
        ['@carol'] = 'Carol Davis <carol@example.com>',
      },
    })
    local result = handles.get()

    assert.equals('Carol Davis <carol@example.com>', result['@carol'])
    assert.is_nil(result['@alice'])
  end)

  it('handles malformed JSON gracefully', function()
    helpers.file_content = 'not valid json{{'
    git_coauthors.setup()
    local result = handles.get()

    assert.is_not_nil(result)
    assert.same({}, result)
  end)

  it('caches result after first load', function()
    git_coauthors.setup()
    local result1 = handles.get()
    helpers.file_content = '{}'
    local result2 = handles.get()

    assert.equals(result1, result2)
  end)

  describe('with discovery', function()
    it('file handles override discovered handles on key collision', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 2,
              nodes = {
                { login = 'alice', name = 'Alice GH', databaseId = 12345 },
                { login = 'carol', name = 'Carol Davis', databaseId = 33333 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })

      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'nobody\n', exit_code = 0 },
        { 'gh api graphql', response .. '\n', exit_code = 0 },
      }

      git_coauthors.setup()
      local result = handles.get()

      assert.equals('Alice Smith <alice@example.com>', result['@alice'])
      assert.equals('Bob Jones <bob@example.com>', result['@bob'])
      assert.equals('Carol Davis <33333+carol@users.noreply.github.com>', result['@carol'])
    end)

    it('inline handles override discovered handles on key collision', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 1,
              nodes = {
                { login = 'carol', name = 'Carol Davis', databaseId = 33333 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })

      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'nobody\n', exit_code = 0 },
        { 'gh api graphql', response .. '\n', exit_code = 0 },
      }

      git_coauthors.setup({
        handles = {
          ['@carol'] = 'Carol Override <carol-new@example.com>',
        },
      })
      local result = handles.get()

      assert.equals('Carol Override <carol-new@example.com>', result['@carol'])
    end)

    it('does not discover when disabled', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 1,
              nodes = {
                { login = 'carol', name = 'Carol Davis', databaseId = 33333 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })

      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'nobody\n', exit_code = 0 },
        { 'gh api graphql', response .. '\n', exit_code = 0 },
      }

      git_coauthors.setup({ discover = false })
      local result = handles.get()

      assert.equals('Alice Smith <alice@example.com>', result['@alice'])
      assert.equals('Bob Jones <bob@example.com>', result['@bob'])
      assert.is_nil(result['@carol'])
    end)
  end)
end)
