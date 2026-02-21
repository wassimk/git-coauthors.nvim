local helpers = require('helpers')
local items = require('git-coauthors.items')
local git_coauthors = require('git-coauthors')

describe('items', function()
  before_each(function()
    helpers.setup_mocks()
    git_coauthors.setup()
  end)

  after_each(function()
    helpers.teardown_mocks()
  end)

  it('returns items when line matches Co-Authored-By: @...', function()
    local result = items.build_items({
      line_text = 'Co-Authored-By: @',
      line_number = 3,
      cursor_col = 17,
    })

    assert.is_not_nil(result)
    assert.equals(2, #result)
  end)

  it('returns nil when line is plain text', function()
    local result = items.build_items({
      line_text = 'some plain text @mention',
      line_number = 0,
      cursor_col = 24,
    })

    assert.is_nil(result)
  end)

  it('returns nil when line has no @', function()
    local result = items.build_items({
      line_text = 'Co-Authored-By: ',
      line_number = 0,
      cursor_col = 16,
    })

    assert.is_nil(result)
  end)

  it('returns nil when prefix is different', function()
    local result = items.build_items({
      line_text = 'Signed-Off-By: @user',
      line_number = 0,
      cursor_col = 20,
    })

    assert.is_nil(result)
  end)

  it('has correct filterText with handle and name/email', function()
    local result = items.build_items({
      line_text = 'Co-Authored-By: @a',
      line_number = 0,
      cursor_col = 18,
    })

    assert.is_not_nil(result)
    local filter_texts = {}
    for _, item in ipairs(result) do
      filter_texts[item.filterText] = true
    end
    assert.is_true(filter_texts['@alice Alice Smith <alice@example.com>'])
    assert.is_true(filter_texts['@bob Bob Jones <bob@example.com>'])
  end)

  it('has correct textEdit range from @ to cursor', function()
    local result = items.build_items({
      line_text = 'Co-Authored-By: @ali',
      line_number = 5,
      cursor_col = 20,
    })

    assert.is_not_nil(result)
    local item = result[1]
    assert.equals(5, item.textEdit.range.start.line)
    assert.equals(16, item.textEdit.range.start.character)
    assert.equals(5, item.textEdit.range['end'].line)
    assert.equals(20, item.textEdit.range['end'].character)
  end)

  it('works with partial handle input', function()
    local result = items.build_items({
      line_text = 'Co-Authored-By: @was',
      line_number = 0,
      cursor_col = 20,
    })

    assert.is_not_nil(result)
    assert.equals(2, #result)
  end)

  it('works with leading whitespace before Co-Authored-By:', function()
    local result = items.build_items({
      line_text = '  Co-Authored-By: @was',
      line_number = 0,
      cursor_col = 22,
    })

    assert.is_not_nil(result)
    assert.equals(2, #result)
  end)

  it('returns nil when @ is inside an already-completed email address', function()
    local result = items.build_items({
      line_text = 'Co-Authored-By: Breanne Johnson <53622028+breannedurenjohnson@users.noreply.github.com>',
      line_number = 0,
      cursor_col = 87,
    })

    assert.is_nil(result)
  end)

  it('returns nil when handles are empty', function()
    helpers.file_exists = false
    require('git-coauthors.handles')._reset_cache()
    git_coauthors.setup()

    local result = items.build_items({
      line_text = 'Co-Authored-By: @test',
      line_number = 0,
      cursor_col = 21,
    })

    assert.is_nil(result)
  end)
end)
