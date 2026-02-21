local helpers = require('helpers')

describe('blink source', function()
  before_each(function()
    helpers.setup_mocks()
  end)

  after_each(function()
    helpers.teardown_mocks()
  end)

  it('get_trigger_characters returns @', function()
    local blink = require('git-coauthors.blink')
    local source = blink.new({}, {})
    assert.same({ '@' }, source:get_trigger_characters())
  end)

  it('new() initializes config from opts if setup not called', function()
    local blink = require('git-coauthors.blink')
    blink.new({ handles_path = '/custom/path.json' }, {})

    local config = require('git-coauthors')._config
    assert.equals('/custom/path.json', config.handles_path)
  end)

  it('get_completions calls callback with items on match', function()
    local blink = require('git-coauthors.blink')
    local source = blink.new({}, {})

    local result
    source:get_completions({
      line = 'Co-Authored-By: @a',
      cursor = { 4, 18 },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.is_not_nil(result.items)
    assert.equals(2, #result.items)
  end)

  it('get_completions calls callback with empty items on no match', function()
    local blink = require('git-coauthors.blink')
    local source = blink.new({}, {})

    local result
    source:get_completions({
      line = 'plain text',
      cursor = { 1, 10 },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.same({}, result.items)
  end)

  it('maps blink row (1-indexed) to 0-indexed line_number', function()
    local blink = require('git-coauthors.blink')
    local source = blink.new({}, {})

    local result
    source:get_completions({
      line = 'Co-Authored-By: @',
      cursor = { 10, 17 },
    }, function(response)
      result = response
    end)

    assert.is_not_nil(result)
    assert.equals(2, #result.items)
    local item = result.items[1]
    assert.equals(9, item.textEdit.range.start.line)
  end)
end)
