local helpers = require('helpers')
local handles = require('git-coauthors.handles')
local git_coauthors = require('git-coauthors')

describe('handles', function()
  before_each(function()
    helpers.setup_mocks()
  end)

  after_each(function()
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
end)
