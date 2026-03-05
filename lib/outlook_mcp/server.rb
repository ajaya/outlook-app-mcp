# frozen_string_literal: true

module OutlookMcp
  module Server
    TOOLS = [
      # Read operations
      Tools::ListEmails,
      Tools::SearchEmails,
      Tools::ReadEmail,
      Tools::ListFolders,
      Tools::ListAttachments,
      Tools::GetAttachment,
      # Compose & send
      Tools::SendEmail,
      Tools::ReplyToEmail,
      Tools::ReplyAllToEmail,
      Tools::ForwardEmail,
      Tools::CreateDraft,
      Tools::SendDraft,
      # Manage
      Tools::MarkAsRead,
      Tools::MoveEmails,
      Tools::CopyEmail,
      Tools::DeleteEmail,
      Tools::CreateFolder
    ].freeze

    def self.start
      config = Config.new
      token_store = Auth::TokenStore.new(config)
      graph_client = Graph::Client.new(token_store)

      log "Outlook MCP Server v#{OutlookMcp::VERSION}"
      log "Ruby #{RUBY_VERSION} | MCP #{MCP::VERSION}"
      log "Transport: stdio (stdin/stdout)"
      log "PID: #{Process.pid}"
      log "Tools: #{TOOLS.size} registered"
      log "Token: #{File.exist?(config.token_path) ? "found" : "NOT FOUND — run `outlook-mcp auth`"}"
      log "OAuth callback: #{config.redirect_uri}"
      log "Graph API: #{Graph::Client::BASE_URL}#{Graph::Client::API_VERSION}"
      log "Waiting for MCP client on stdio..."

      server = MCP::Server.new(
        name: "outlook",
        version: OutlookMcp::VERSION,
        tools: TOOLS,
        server_context: {graph: graph_client}
      )

      transport = LoggingStdioTransport.new(server)
      transport.open
    end

    def self.log(msg)
      warn "[outlook-mcp] #{msg}"
    end
  end

  class LoggingStdioTransport < MCP::Server::Transports::StdioTransport
    def handle_json_request(request_json)
      warn "[outlook-mcp] >>> #{request_json}"
      super
    end

    def send_response(message)
      json = message.is_a?(String) ? message : JSON.generate(message)
      warn "[outlook-mcp] <<< #{json}"
      super
    end
  end
end
