# frozen_string_literal: true

module OutlookMcp
  module Server
    DEFAULT_HTTP_PORT = 9249

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

    def self.start(http: false, port: DEFAULT_HTTP_PORT)
      server = build_server
      log_banner(server, http:, port:)

      if http
        start_http(server, port)
      else
        start_stdio(server)
      end
    end

    def self.build_server
      config = Config.new
      token_store = Auth::TokenStore.new(config)
      graph_client = Graph::Client.new(token_store)

      MCP::Server.new(
        name: "outlook",
        version: OutlookMcp::VERSION,
        tools: TOOLS,
        server_context: {graph: graph_client}
      )
    end

    def self.start_stdio(server)
      transport = LoggingStdioTransport.new(server)
      transport.open
    end

    def self.start_http(server, port)
      transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
      server.transport = transport

      app = ->(env) { transport.handle_request(Rack::Request.new(env)) }

      log "HTTP server listening on http://127.0.0.1:#{port}/mcp"

      require "rackup/handler/webrick"
      Rackup::Handler::WEBrick.run(
        Rack::Builder.new { map("/mcp") { run app } },
        Host: "127.0.0.1",
        Port: port,
        Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN),
        AccessLog: []
      )
    end

    def self.log_banner(server, http:, port:)
      config = Config.new
      transport_info = http ? "http (port #{port})" : "stdio (stdin/stdout)"

      log "Outlook MCP Server v#{OutlookMcp::VERSION}"
      log "Ruby #{RUBY_VERSION} | MCP #{MCP::VERSION}"
      log "Transport: #{transport_info}"
      log "PID: #{Process.pid}"
      log "Tools: #{TOOLS.size} registered"
      log "Token: #{File.exist?(config.token_path) ? "found" : "NOT FOUND — run `outlook-mcp auth`"}"
      log "OAuth callback: #{config.redirect_uri}"
      log "Graph API: #{Graph::Client::BASE_URL}#{Graph::Client::API_VERSION}"
      log "Waiting for MCP client..." unless http
    end

    def self.log(msg)
      warn "[outlook-mcp] #{msg}"
    end

    private_class_method :build_server, :start_stdio, :start_http, :log_banner
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
