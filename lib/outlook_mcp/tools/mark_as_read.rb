# frozen_string_literal: true

module OutlookMcp
  module Tools
    class MarkAsRead < MCP::Tool
      description "Mark an email as read or unread"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: true
      )

      input_schema(
        properties: {
          id: { type: "string", description: "The email message ID" },
          is_read: { type: "boolean", description: "true to mark as read, false for unread (default: true)" }
        },
        required: ["id"]
      )

      class << self
        def call(id:, server_context:, **args)
          graph = server_context[:graph]
          is_read = args.fetch(:is_read, true)
          graph.update_message(id, { isRead: is_read })
          status = is_read ? "read" : "unread"
          MCP::Tool::Response.new([{ type: "text", text: "Email marked as #{status}." }])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{ type: "text", text: "Error updating email: #{e.message}" }], error: true)
        end
      end
    end
  end
end
