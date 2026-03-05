# Outlook MCP Server (Ruby)

Give Claude (or any AI assistant) full access to your Outlook mailbox — read, search, send, reply, forward, organize, and manage drafts — all through the [Model Context Protocol](https://modelcontextprotocol.io/).

## Quick Start

```bash
git clone https://github.com/ajaya/outlook-mcp-ruby.git
cd outlook-mcp-ruby
bundle install
cp .env.example .env        # edit with your Azure credentials
bin/outlook-mcp auth        # one-time OAuth login
bin/outlook-mcp config claude-code   # prints config you can paste
```

## What It Does

17 mail tools exposed over MCP stdio transport:

| | Tools |
| -- | ----- |
| **Read** | `list_emails` `search_emails` `read_email` `list_folders` `list_attachments` `get_attachment` |
| **Compose** | `send_email` `reply_to_email` `reply_all_to_email` `forward_email` `create_draft` `send_draft` |
| **Manage** | `mark_as_read` `move_emails` `copy_email` `delete_email` `create_folder` |

## Prerequisites

- **Ruby 4.0+** — pinned in `.ruby-version`; works with rv, rbenv, mise, asdf, rvm, chruby
- **Azure AD app registration** with Microsoft Graph delegated permissions

## Azure App Setup

1. [Azure Portal > App registrations](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade) > **New registration**
2. Redirect URI: `http://localhost:3333/auth/callback` (Web platform)
3. **Certificates & secrets** > new client secret
4. **API permissions** > add Microsoft Graph delegated:
   `User.Read`, `Mail.Read`, `Mail.ReadWrite`, `Mail.Send`
5. Note your **Client ID**, **Client secret**, and **Tenant ID**

## Install

```bash
git clone https://github.com/ajaya/outlook-mcp-ruby.git
cd outlook-mcp-ruby
bundle install
```

Create `.env` from the example:

```bash
cp .env.example .env
```

```env
OUTLOOK_CLIENT_ID=your-client-id
OUTLOOK_CLIENT_SECRET=your-client-secret
OUTLOOK_TENANT_ID=common
```

Authenticate (one-time):

```bash
bin/outlook-mcp auth
```

This opens your browser for Azure AD consent and saves tokens to `~/.outlook-mcp-tokens.json`. Tokens auto-refresh when expired.

## Configure Claude

Generate a ready-to-paste config snippet (reads your `.env` credentials):

```bash
bin/outlook-mcp config claude-desktop
bin/outlook-mcp config claude-code
```

Or add manually:

**Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "outlook": {
      "command": "/path/to/outlook-mcp-ruby/bin/outlook-mcp",
      "args": ["server"],
      "env": {
        "OUTLOOK_CLIENT_ID": "...",
        "OUTLOOK_CLIENT_SECRET": "...",
        "OUTLOOK_TENANT_ID": "..."
      }
    }
  }
}
```

**Claude Code**: same, without `env` (reads from `.env` file directly).

## Ruby Version Manager

The `bin/outlook-mcp` wrapper auto-detects your Ruby version manager so MCP clients (which spawn with a minimal `PATH`) find the right Ruby. Supported: rv, rbenv, mise, asdf, rvm, chruby.

If auto-detection picks the wrong one, pin it in `.env`:

```env
RUBY_VERSION_MANAGER=rv
```

## Configuration Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `OUTLOOK_CLIENT_ID` | *required* | Azure app client ID |
| `OUTLOOK_CLIENT_SECRET` | *required* | Azure app client secret |
| `OUTLOOK_TENANT_ID` | `common` | Azure tenant ID |
| `OUTLOOK_TOKEN_PATH` | `~/.outlook-mcp-tokens.json` | Token storage location |
| `OUTLOOK_REDIRECT_URI` | `http://localhost:3333/auth/callback` | OAuth redirect URI |
| `OUTLOOK_SCOPES` | `offline_access User.Read Mail.Read Mail.ReadWrite Mail.Send` | OAuth scopes |
| `RUBY_VERSION_MANAGER` | `auto` | `auto`, `rv`, `rbenv`, `mise`, `asdf`, `rvm`, `chruby` |

## CLI

```bash
bin/outlook-mcp auth             # OAuth login
bin/outlook-mcp server           # Start MCP server
bin/outlook-mcp config TARGET    # Generate config (claude-desktop, claude-code)
bin/outlook-mcp version          # Print version
bin/outlook-mcp debug            # Config, token status, registered tools
bin/outlook-mcp tools            # List all MCP tools
bin/outlook-mcp tool NAME        # Tool details and input schema
bin/outlook-mcp token            # Token status

# Direct mail operations
bin/outlook-mcp me               # Authenticated user profile
bin/outlook-mcp inbox [COUNT]    # Recent emails (--folder=ID)
bin/outlook-mcp read ID          # Read email
bin/outlook-mcp search QUERY     # Search (--count=N)
bin/outlook-mcp folders          # List folders
bin/outlook-mcp attachments ID   # List attachments
```

## Architecture

```
lib/outlook_mcp/
├── config.rb                 # Env var loading
├── auth/
│   ├── token_store.rb        # JSON token persistence + auto-refresh
│   ├── oauth_client.rb       # Azure AD OAuth2 flow
│   └── callback_server.rb    # WEBrick server for OAuth callback
├── graph/
│   ├── sanitize_ids.rb       # Automatic ID validation via prepend callbacks
│   ├── client.rb             # Faraday HTTP client with Bearer auth + 401 retry
│   ├── email.rb              # Mail API methods (mixed into Client)
│   └── folder.rb             # Folder API methods (mixed into Client)
├── tools/                    # 17 MCP tool classes
├── server.rb                 # MCP::Server factory
└── cli.rb                    # Thor CLI
```

Key design decisions:

- **Dependency injection** — tools receive `server_context[:graph]` instead of globals
- **Graph mixins** — `Graph::Email` and `Graph::Folder` mixed into `Graph::Client`
- **Auto token refresh** — catches 401, refreshes, retries once
- **ID sanitization** — `SanitizeIds.wrap(mod)` auto-validates ID parameters via `prepend`
- **No OAuth2 gem** — Azure AD OAuth2 is two HTTP calls; Faraday is enough

## Development

```bash
bundle exec rake test
bundle exec ruby -Itest test/outlook_mcp/graph/email_test.rb
bundle exec rubocop
```

See [TOOLS.md](TOOLS.md) for Graph API endpoints and methods available for future tools.

## License

MIT
