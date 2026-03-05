# frozen_string_literal: true

module OutlookMcp
  module Tools
    class DeleteEmail < MCP::Tool
      description "Delete an email (moves to Deleted Items)"

      annotations(
        read_only_hint: false,
        destructive_hint: true,
        idempotent_hint: true,
        open_world_hint: true
      )

      input_schema(
        properties: {
          id: {type: "string", description: "The email message ID to delete"}
        },
        required: ["id"]
      )

      class << self
        def call(id:, server_context:, **)
          graph = server_context[:graph]
          graph.delete_message(id)
          MCP::Tool::Response.new([{type: "text", text: "Email deleted."}])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{type: "text", text: "Error deleting email: #{e.message}"}], error: true)
        end
      end
    end
  end
end
