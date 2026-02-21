local helpers = require('helpers')

describe('cmp source', function()
  before_each(function()
    helpers.setup_mocks()
    require('git-coauthors').setup()
  end)

  after_each(function()
    helpers.teardown_mocks()
  end)

  it('get_trigger_characters returns @', function()
    local cmp_source = require('git-coauthors.cmp')
    local source = cmp_source.new()
    assert.same({ '@' }, source:get_trigger_characters())
  end)

  it('complete calls callback with items on match', function()
    local cmp_source = require('git-coauthors.cmp')
    local source = cmp_source.new()

    local result
    source:complete({
      context = {
        cursor_before_line = 'Co-Authored-By: @a',
        cursor_after_line = '',
        cursor = { row = 4, col = 19 },
      },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.is_not_nil(result.items)
    assert.equals(2, #result.items)
    assert.is_true(result.isIncomplete)
  end)

  it('complete calls callback with isIncomplete on no match', function()
    local cmp_source = require('git-coauthors.cmp')
    local source = cmp_source.new()

    local result
    source:complete({
      context = {
        cursor_before_line = 'plain text',
        cursor_after_line = '',
        cursor = { row = 1, col = 11 },
      },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.is_nil(result.items)
    assert.is_true(result.isIncomplete)
  end)

  it('maps cmp row/col (both 1-indexed) to 0-indexed', function()
    local cmp_source = require('git-coauthors.cmp')
    local source = cmp_source.new()

    local result
    source:complete({
      context = {
        cursor_before_line = 'Co-Authored-By: @',
        cursor_after_line = '',
        cursor = { row = 10, col = 18 },
      },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.equals(2, #result.items)
    local item = result.items[1]
    assert.equals(9, item.textEdit.range.start.line)
  end)
end)
