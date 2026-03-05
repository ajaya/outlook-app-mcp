# frozen_string_literal: true

require "thor"
require "json"

module OutlookMcp
  class CLI < Thor
    desc "auth", "Authenticate with Microsoft Outlook via OAuth2"
    def auth
      config = Config.new
      callback = Auth::CallbackServer.new(port: 3333)
      callback.check_port_available!

      oauth = Auth::OAuthClient.new(config)
      url = oauth.authorization_url
      puts "Opening browser for authentication..."
      puts url

      system("open", url) || system("xdg-open", url)

      code = callback.wait_for_code
      puts "Exchanging code for tokens..."
      token_data = oauth.exchange_code(code)

      store = Auth::TokenStore.new(config)
      store.save(token_data)
      puts "Authentication successful! Tokens saved to #{config.token_path}"
    rescue RuntimeError => e
      puts "Error: #{e.message}"
      exit 1
    rescue Faraday::Error => e
      puts "Token exchange failed: #{e.message}"
      exit 1
    end

    desc "server", "Start the MCP stdio server"
    def server
      OutlookMcp::Server.start
    end

    desc "version", "Print the version"
    def version
      puts "outlook-mcp v#{OutlookMcp::VERSION}"
    end

    desc "tools", "List all available MCP tools"
    def tools
      puts "Available MCP Tools (#{OutlookMcp::Server::TOOLS.size}):"
      puts ""
      OutlookMcp::Server::TOOLS.each do |tool|
        ann = tool.annotations
        flags = []
        flags << "read-only" if ann&.read_only_hint
        flags << "destructive" if ann&.destructive_hint
        flag_str = flags.any? ? " [#{flags.join(", ")}]" : ""
        puts "  #{tool_name(tool)} - #{tool.description}#{flag_str}"
      end
    end

    desc "tool TOOL_NAME", "Show details for a specific MCP tool"
    def tool(name)
      tool_class = find_tool(name)
      unless tool_class
        puts "Tool '#{name}' not found. Run `outlook-mcp tools` to list available tools."
        return
      end

      puts "Tool: #{tool_name(tool_class)}"
      puts "Description: #{tool_class.description}"
      puts ""

      if (ann = tool_class.annotations)
        puts "Annotations:"
        ann.to_h.each { |k, v| puts "  #{k}: #{v}" unless v.nil? }
        puts ""
      end

      schema = tool_class.input_schema
      if schema
        puts "Input Schema:"
        puts JSON.pretty_generate(schema.to_h)
      end
    end

    desc "token", "Show token status"
    def token
      config = Config.new
      store = Auth::TokenStore.new(config)
      data = store.tokens

      unless data
        puts "No tokens found. Run `outlook-mcp auth` first."
        return
      end

      expires_at = Time.at(data[:expires_at])
      expired = store.expired?(data)

      puts "Token file: #{config.token_path}"
      puts "Expires at: #{expires_at}"
      puts "Status: #{expired ? "EXPIRED" : "VALID"}"
      puts "Has refresh token: #{data[:refresh_token] ? "yes" : "no"}"
      puts "Scopes: #{data[:scope]}"
    end

    desc "me", "Show the authenticated user's profile"
    def me
      graph = build_graph_client
      result = graph.get("/me", {"$select" => "displayName,mail,userPrincipalName"})
      puts "Name: #{result["displayName"]}"
      puts "Email: #{result["mail"]}"
      puts "UPN: #{result["userPrincipalName"]}"
    rescue => e
      puts "Error: #{e.message}"
    end

    desc "inbox [COUNT]", "List recent inbox emails (default: 10)"
    method_option :folder, type: :string, desc: "Folder ID or well-known name (default: Inbox)"
    def inbox(count = "10")
      graph = build_graph_client
      result = graph.list_messages(folder_id: options[:folder], top: count.to_i)
      emails = result["value"] || []

      if emails.empty?
        puts "No emails found."
        return
      end

      emails.each_with_index do |email, i|
        from = email.dig("from", "emailAddress", "address") || "unknown"
        read_marker = email["isRead"] ? " " : "*"
        draft_marker = email["isDraft"] ? "[DRAFT] " : ""
        puts "#{read_marker} #{i + 1}. #{draft_marker}#{email["subject"]}"
        puts "     From: #{from} | #{email["receivedDateTime"]}"
        puts "     ID: #{email["id"]}"
        puts ""
      end
    rescue => e
      puts "Error: #{e.message}"
    end

    desc "read ID", "Read a specific email"
    def read(id)
      graph = build_graph_client
      email = graph.get_message(id)

      to = (email["toRecipients"] || []).map { |r| r.dig("emailAddress", "address") }.join(", ")
      cc = (email["ccRecipients"] || []).map { |r| r.dig("emailAddress", "address") }.join(", ")

      puts "From: #{email.dig("from", "emailAddress", "address")}"
      puts "To: #{to}"
      puts "CC: #{cc}" unless cc.empty?
      puts "Subject: #{email["subject"]}"
      puts "Date: #{email["receivedDateTime"]}"
      puts "Read: #{email["isRead"]} | Draft: #{email["isDraft"]} | Attachments: #{email["hasAttachments"]}"
      puts "Conversation ID: #{email["conversationId"]}"
      puts "-" * 60
      puts email.dig("body", "content")
    rescue => e
      puts "Error: #{e.message}"
    end

    desc "folders", "List mail folders"
    def folders
      graph = build_graph_client
      result = graph.list_folders
      folders = result["value"] || []

      puts "Mail Folders:"
      folders.each do |folder|
        unread = folder["unreadItemCount"].to_i
        unread_str = unread > 0 ? " (#{unread} unread)" : ""
        puts "  #{folder["displayName"]} [#{folder["totalItemCount"]} items#{unread_str}]"
        puts "    ID: #{folder["id"]}"
      end
    rescue => e
      puts "Error: #{e.message}"
    end

    desc "search QUERY", "Search emails"
    method_option :count, type: :numeric, default: 10, desc: "Number of results"
    def search(query)
      graph = build_graph_client
      result = graph.search_messages(query: query, top: options[:count])
      emails = result["value"] || []

      if emails.empty?
        puts "No results for '#{query}'."
        return
      end

      puts "Search results for '#{query}' (#{emails.size} found):"
      puts ""
      emails.each_with_index do |email, i|
        from = email.dig("from", "emailAddress", "address") || "unknown"
        puts "  #{i + 1}. #{email["subject"]}"
        puts "     From: #{from} | #{email["receivedDateTime"]}"
        puts "     ID: #{email["id"]}"
        puts ""
      end
    rescue => e
      puts "Error: #{e.message}"
    end

    desc "attachments ID", "List attachments on an email"
    def attachments(message_id)
      graph = build_graph_client
      result = graph.list_attachments(message_id)
      atts = result["value"] || []

      if atts.empty?
        puts "No attachments."
        return
      end

      puts "Attachments (#{atts.size}):"
      atts.each_with_index do |att, i|
        size_kb = (att["size"].to_f / 1024).round(1)
        puts "  #{i + 1}. #{att["name"]} (#{size_kb} KB, #{att["contentType"]})"
        puts "     ID: #{att["id"]}"
      end
    rescue => e
      puts "Error: #{e.message}"
    end

    desc "config TARGET", "Generate MCP config snippet (claude-desktop, claude-code)"
    def config(target)
      Dotenv.load
      bin_path = File.expand_path("../../bin/outlook-mcp", __dir__)

      env_vars = {
        OUTLOOK_CLIENT_ID: ENV.fetch("OUTLOOK_CLIENT_ID", "YOUR_CLIENT_ID"),
        OUTLOOK_CLIENT_SECRET: ENV.fetch("OUTLOOK_CLIENT_SECRET", "YOUR_CLIENT_SECRET"),
        OUTLOOK_TENANT_ID: ENV.fetch("OUTLOOK_TENANT_ID", "common")
      }
      rvm = ENV["RUBY_VERSION_MANAGER"]
      env_vars[:RUBY_VERSION_MANAGER] = rvm if rvm && rvm != "auto"

      snippet = case target.downcase.tr(" ", "-")
      when "claude-desktop", "desktop"
        {
          mcpServers: {
            outlook: {
              command: bin_path,
              args: ["server"],
              env: env_vars
            }
          }
        }
      when "claude-code", "code"
        server = { command: bin_path, args: ["server"] }
        server[:env] = { RUBY_VERSION_MANAGER: rvm } if rvm && rvm != "auto"
        { mcpServers: { outlook: server } }
      else
        puts "Unknown target '#{target}'. Use: claude-desktop, claude-code"
        return
      end

      puts JSON.pretty_generate(snippet)
    end

    desc "debug", "Show debug info (config, token, tools)"
    def debug
      puts "=== Outlook MCP Debug Info ==="
      puts ""
      puts "Version: #{OutlookMcp::VERSION}"
      puts "Ruby: #{RUBY_VERSION}"
      puts "MCP gem: #{MCP::VERSION}" if defined?(MCP::VERSION)
      puts ""

      puts "Tools registered: #{OutlookMcp::Server::TOOLS.size}"
      OutlookMcp::Server::TOOLS.each { |t| puts "  - #{tool_name(t)}" }
      puts ""

      begin
        config = Config.new
        puts "Config:"
        puts "  Client ID: #{config.client_id[0..7]}..."
        puts "  Tenant: #{config.tenant_id}"
        puts "  Token path: #{config.token_path}"
        puts "  Token exists: #{File.exist?(config.token_path)}"
        puts "  Redirect URI: #{config.redirect_uri}"
        puts "  Scopes: #{config.scopes}"

        store = Auth::TokenStore.new(config)
        if store.tokens
          puts ""
          puts "Token status: #{store.expired? ? "EXPIRED" : "VALID"}"
          puts "Expires at: #{Time.at(store.tokens[:expires_at])}"
        end
      rescue KeyError => e
        puts "Config error: #{e.message} (set in .env or environment)"
      end
    end

    private

    def build_graph_client
      config = Config.new
      token_store = Auth::TokenStore.new(config)
      Graph::Client.new(token_store)
    end

    def tool_name(tool_class)
      tool_class.name.split("::").last
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end

    def find_tool(name)
      OutlookMcp::Server::TOOLS.find do |t|
        tool_name(t) == name || t.name.split("::").last.downcase == name.downcase
      end
    end
  end
end
