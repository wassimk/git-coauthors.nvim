local helpers = require('helpers')
local discover = require('git-coauthors.discover')

describe('discover', function()
  before_each(function()
    helpers.setup_mocks()
  end)

  after_each(function()
    helpers.teardown_mocks()
  end)

  describe('from github', function()
    local function setup_github_mocks(graphql_response)
      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'myuser\n', exit_code = 0 },
        { 'gh api graphql', graphql_response .. '\n', exit_code = 0 },
      }
    end

    it('returns handles from GraphQL response', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 2,
              nodes = {
                { login = 'alice', name = 'Alice Smith', databaseId = 12345 },
                { login = 'bob', name = 'Bob Jones', databaseId = 67890 },
              },
              pageInfo = { hasNextPage = false, endCursor = 'abc123' },
            },
          },
        },
      })
      setup_github_mocks(response)

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <12345+alice@users.noreply.github.com>', result['@alice'])
      assert.equals('Bob Jones <67890+bob@users.noreply.github.com>', result['@bob'])
    end)

    it('excludes the current user', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 2,
              nodes = {
                { login = 'alice', name = 'Alice Smith', databaseId = 12345 },
                { login = 'myuser', name = 'My User', databaseId = 11111 },
              },
              pageInfo = { hasNextPage = false, endCursor = 'abc123' },
            },
          },
        },
      })
      setup_github_mocks(response)

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <12345+alice@users.noreply.github.com>', result['@alice'])
      assert.is_nil(result['@myuser'])
    end)

    it('excludes bot accounts', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 2,
              nodes = {
                { login = 'alice', name = 'Alice Smith', databaseId = 12345 },
                { login = 'dependabot[bot]', databaseId = 99999 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })
      setup_github_mocks(response)

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <12345+alice@users.noreply.github.com>', result['@alice'])
      assert.is_nil(result['@dependabot[bot]'])
    end)

    it('uses login as name when name is null', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 1,
              nodes = {
                { login = 'alice', databaseId = 12345 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })
      setup_github_mocks(response)

      local result = discover.discover({ discover = true })

      assert.equals('alice <12345+alice@users.noreply.github.com>', result['@alice'])
    end)

    it('handles pagination', function()
      helpers.executables = { gh = true }

      local page1 = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 2,
              nodes = {
                { login = 'alice', name = 'Alice Smith', databaseId = 12345 },
              },
              pageInfo = { hasNextPage = true, endCursor = 'cursor1' },
            },
          },
        },
      })

      local page2 = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 2,
              nodes = {
                { login = 'bob', name = 'Bob Jones', databaseId = 67890 },
              },
              pageInfo = { hasNextPage = false, endCursor = 'cursor2' },
            },
          },
        },
      })

      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'myuser\n', exit_code = 0 },
        { 'after:', page2 .. '\n', exit_code = 0 },
        { 'gh api graphql', page1 .. '\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <12345+alice@users.noreply.github.com>', result['@alice'])
      assert.equals('Bob Jones <67890+bob@users.noreply.github.com>', result['@bob'])
    end)

    it('uses real email from git log when name matches', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 2,
              nodes = {
                { login = 'alice', name = 'Alice Smith', databaseId = 12345 },
                { login = 'bob', name = 'Bob Jones', databaseId = 67890 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })

      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'myuser\n', exit_code = 0 },
        { 'gh api graphql', response .. '\n', exit_code = 0 },
        { 'git log', 'Alice Smith <alice@company.com>\nBob Jones <bob@company.com>\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <alice@company.com>', result['@alice'])
      assert.equals('Bob Jones <bob@company.com>', result['@bob'])
    end)

    it('falls back to noreply pattern when name does not match', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 1,
              nodes = {
                { login = 'alice', name = 'Alice Smith', databaseId = 12345 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })

      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'myuser\n', exit_code = 0 },
        { 'gh api graphql', response .. '\n', exit_code = 0 },
        {
          'git log',
          'A. Smith <12345+alice@users.noreply.github.com>\nA. Smith <alice@company.com>\n',
          exit_code = 0,
        },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <alice@company.com>', result['@alice'])
    end)

    it('keeps noreply when no name or noreply pattern matches in git log', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 1,
              nodes = {
                { login = 'alice', name = 'Alice Smith', databaseId = 12345 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })

      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'myuser\n', exit_code = 0 },
        { 'gh api graphql', response .. '\n', exit_code = 0 },
        { 'git log', 'Someone Else <other@company.com>\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <12345+alice@users.noreply.github.com>', result['@alice'])
    end)

    it('keeps noreply when git log only has noreply emails for that user', function()
      local response = vim.fn.json_encode({
        data = {
          repository = {
            collaborators = {
              totalCount = 1,
              nodes = {
                { login = 'alice', name = 'Alice Smith', databaseId = 12345 },
              },
              pageInfo = { hasNextPage = false },
            },
          },
        },
      })

      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'myuser\n', exit_code = 0 },
        { 'gh api graphql', response .. '\n', exit_code = 0 },
        { 'git log', 'Alice Smith <12345+alice@users.noreply.github.com>\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <12345+alice@users.noreply.github.com>', result['@alice'])
    end)

    it('returns empty when gh is not installed', function()
      local result = discover.discover({ discover = true })

      assert.same({}, result)
    end)

    it('falls back to git log when GraphQL returns FORBIDDEN', function()
      local response = vim.fn.json_encode({
        errors = { { type = 'FORBIDDEN', message = 'Resource not accessible' } },
      })

      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'myuser\n', exit_code = 0 },
        { 'gh api graphql', response .. '\n', exit_code = 0 },
        { 'git rev-parse', '/path/to/repo\n', exit_code = 0 },
        { 'git config user.name', 'My User\n', exit_code = 0 },
        { 'git config user.email', 'myuser@example.com\n', exit_code = 0 },
        { 'git log', 'Alice Smith <alice@example.com>\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <alice@example.com>', result['@Alice Smith'])
    end)

    it('falls back to git log on malformed JSON', function()
      helpers.executables = { gh = true }
      helpers.system_responses = {
        { 'gh repo view', 'owner/repo\n', exit_code = 0 },
        { 'gh api user', 'myuser\n', exit_code = 0 },
        { 'gh api graphql', 'not valid json{{', exit_code = 0 },
        { 'git rev-parse', '/path/to/repo\n', exit_code = 0 },
        { 'git config user.name', 'My User\n', exit_code = 0 },
        { 'git config user.email', 'myuser@example.com\n', exit_code = 0 },
        { 'git log', 'Alice Smith <alice@example.com>\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <alice@example.com>', result['@Alice Smith'])
    end)
  end)

  describe('from git log', function()
    it('returns handles from git log output', function()
      helpers.system_responses = {
        { 'git rev-parse', '/path/to/repo\n', exit_code = 0 },
        { 'git config user.name', 'My User\n', exit_code = 0 },
        { 'git config user.email', 'myuser@example.com\n', exit_code = 0 },
        { 'git log', 'Alice Smith <alice@example.com>\nBob Jones <bob@example.com>\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <alice@example.com>', result['@Alice Smith'])
      assert.equals('Bob Jones <bob@example.com>', result['@Bob Jones'])
    end)

    it('excludes the current user by name', function()
      helpers.system_responses = {
        { 'git rev-parse', '/path/to/repo\n', exit_code = 0 },
        { 'git config user.name', 'My User\n', exit_code = 0 },
        { 'git config user.email', 'myuser@example.com\n', exit_code = 0 },
        { 'git log', 'Alice Smith <alice@example.com>\nMy User <other@example.com>\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <alice@example.com>', result['@Alice Smith'])
      assert.is_nil(result['@My User'])
    end)

    it('excludes the current user by email', function()
      helpers.system_responses = {
        { 'git rev-parse', '/path/to/repo\n', exit_code = 0 },
        { 'git config user.name', 'My User\n', exit_code = 0 },
        { 'git config user.email', 'myuser@example.com\n', exit_code = 0 },
        { 'git log', 'Alice Smith <alice@example.com>\nDifferent Name <myuser@example.com>\n', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <alice@example.com>', result['@Alice Smith'])
      assert.is_nil(result['@Different Name'])
    end)

    it('deduplicates entries from git log', function()
      helpers.system_responses = {
        { 'git rev-parse', '/path/to/repo\n', exit_code = 0 },
        { 'git config user.name', 'My User\n', exit_code = 0 },
        { 'git config user.email', 'myuser@example.com\n', exit_code = 0 },
        {
          'git log',
          'Alice Smith <alice@example.com>\nAlice Smith <alice@example.com>\nBob Jones <bob@example.com>\n',
          exit_code = 0,
        },
      }

      local result = discover.discover({ discover = true })

      assert.equals('Alice Smith <alice@example.com>', result['@Alice Smith'])
      assert.equals('Bob Jones <bob@example.com>', result['@Bob Jones'])
    end)

    it('keeps both entries when same name has different emails', function()
      helpers.system_responses = {
        { 'git rev-parse', '/path/to/repo\n', exit_code = 0 },
        { 'git config user.name', 'My User\n', exit_code = 0 },
        { 'git config user.email', 'myuser@example.com\n', exit_code = 0 },
        {
          'git log',
          'Alice Smith <alice@example.com>\nAlice Smith <alice@work.com>\n',
          exit_code = 0,
        },
      }

      local result = discover.discover({ discover = true })

      -- Same key @Alice Smith, last one wins
      assert.is_not_nil(result['@Alice Smith'])
    end)

    it('returns empty when not in a git repo', function()
      local result = discover.discover({ discover = true })

      assert.same({}, result)
    end)

    it('returns empty on empty git log', function()
      helpers.system_responses = {
        { 'git rev-parse', '/path/to/repo\n', exit_code = 0 },
        { 'git config user.name', 'My User\n', exit_code = 0 },
        { 'git config user.email', 'myuser@example.com\n', exit_code = 0 },
        { 'git log', '', exit_code = 0 },
      }

      local result = discover.discover({ discover = true })

      assert.same({}, result)
    end)
  end)

  it('returns empty when discover is disabled', function()
    helpers.executables = { gh = true }
    helpers.system_responses = {
      { 'gh repo view', 'owner/repo\n', exit_code = 0 },
      { 'gh api user', 'myuser\n', exit_code = 0 },
      {
        'gh api graphql',
        vim.fn.json_encode({
          data = {
            repository = {
              collaborators = {
                totalCount = 1,
                nodes = { { login = 'alice', name = 'Alice Smith', databaseId = 12345 } },
                pageInfo = { hasNextPage = false },
              },
            },
          },
        }) .. '\n',
        exit_code = 0,
      },
    }

    local result = discover.discover({ discover = false })

    assert.same({}, result)
  end)
end)
