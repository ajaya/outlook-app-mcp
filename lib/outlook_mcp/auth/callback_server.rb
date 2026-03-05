# frozen_string_literal: true

require "socket"
require "webrick"

module OutlookMcp
  module Auth
    class CallbackServer
      attr_reader :port

      def initialize(port: 3333)
        @port = port
        @code = nil
      end

      def check_port_available!
        sock = TCPSocket.new("127.0.0.1", port)
        sock.close
        raise "Port #{port} is already in use. Kill the process using it:\n  lsof -i :#{port}\n  kill <PID>"
      rescue Errno::ECONNREFUSED
        # Nothing listening — port is available
      end

      def wait_for_code
        server = WEBrick::HTTPServer.new(
          Port: port,
          BindAddress: "127.0.0.1",
          Logger: WEBrick::Log.new($stderr, WEBrick::Log::INFO),
          AccessLog: []
        )

        server.mount_proc "/auth/callback" do |req, res|
          if req.query["error"]
            warn "[outlook-mcp] OAuth error: #{req.query["error"]} — #{req.query["error_description"]}"
            res.status = 400
            res.body = "<html><body><h1>Authentication failed</h1><p>#{req.query["error_description"]}</p></body></html>"
          else
            warn "[outlook-mcp] OAuth callback received"
            @code = req.query["code"]
            res.body = "<html><body><h1>Authentication successful!</h1><p>You can close this window.</p></body></html>"
          end
          Thread.new { server.shutdown }
        end

        trap("INT") { server.shutdown }

        warn "[outlook-mcp] OAuth callback server listening on http://127.0.0.1:#{port}/auth/callback"
        warn "[outlook-mcp] Complete the Microsoft login in your browser..."
        server.start

        raise "Authentication failed — no code received" unless @code

        @code
      end

      private
    end
  end
end
