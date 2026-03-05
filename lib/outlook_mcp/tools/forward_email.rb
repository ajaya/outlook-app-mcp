# frozen_string_literal: true

module OutlookMcp
  module Tools
    class ForwardEmail < MCP::Tool
      description "Forward an email to one or more recipients"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: true
      )

      input_schema(
        properties: {
          id: {type: "string", description: "The email message ID to forward"},
          to: {type: "array", items: {type: "string"}, description: "Recipient email addresses"},
          comment: {type: "string", description: "Optional comment to include (HTML supported)"}
        },
        required: %w[id to]
      )

      class << self
        def call(id:, to:, server_context:, **args)
          graph = server_context[:graph]
          graph.forward_message(id, to: to, comment: args[:comment])
          MCP::Tool::Response.new([{type: "text", text: "Email forwarded to #{to.join(", ")}."}])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{type: "text", text: "Error forwarding: #{e.message}"}], error: true)
        end
      end
    end
  end
end
