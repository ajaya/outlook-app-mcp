# frozen_string_literal: true

module OutlookMcp
  module Tools
    class CopyEmail < MCP::Tool
      description "Copy an email to a different mail folder"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: true
      )

      input_schema(
        properties: {
          id: {type: "string", description: "The email message ID to copy"},
          destination_folder_id: {type: "string", description: "Destination folder ID"}
        },
        required: %w[id destination_folder_id]
      )

      class << self
        def call(id:, destination_folder_id:, server_context:, **)
          graph = server_context[:graph]
          result = graph.copy_message(id, destination_folder_id)
          MCP::Tool::Response.new([{type: "text", text: "Email copied. New ID: #{result["id"]}"}])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{type: "text", text: "Error copying email: #{e.message}"}], error: true)
        end
      end
    end
  end
end
