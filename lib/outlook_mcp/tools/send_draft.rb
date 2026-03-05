# frozen_string_literal: true

module OutlookMcp
  module Tools
    class SendDraft < MCP::Tool
      description "Send a previously created draft email"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: true
      )

      input_schema(
        properties: {
          id: {type: "string", description: "The draft message ID to send"}
        },
        required: ["id"]
      )

      class << self
        def call(id:, server_context:, **)
          graph = server_context[:graph]
          graph.send_draft(id)
          MCP::Tool::Response.new([{type: "text", text: "Draft sent."}])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{type: "text", text: "Error sending draft: #{e.message}"}], error: true)
        end
      end
    end
  end
end
