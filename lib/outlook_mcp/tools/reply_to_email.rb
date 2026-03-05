# frozen_string_literal: true

module OutlookMcp
  module Tools
    class ReplyToEmail < MCP::Tool
      description "Reply to the sender of an email"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: true
      )

      input_schema(
        properties: {
          id: {type: "string", description: "The email message ID to reply to"},
          comment: {type: "string", description: "Reply message body (HTML supported)"}
        },
        required: %w[id comment]
      )

      class << self
        def call(id:, comment:, server_context:, **)
          graph = server_context[:graph]
          graph.reply_to_message(id, comment: comment)
          MCP::Tool::Response.new([{type: "text", text: "Reply sent."}])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{type: "text", text: "Error replying: #{e.message}"}], error: true)
        end
      end
    end
  end
end
