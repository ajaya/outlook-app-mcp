# frozen_string_literal: true

module OutlookMcp
  module Tools
    class GetAttachment < MCP::Tool
      description "Get details and content of a specific email attachment"

      annotations(
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: true
      )

      input_schema(
        properties: {
          message_id: {type: "string", description: "The email message ID"},
          attachment_id: {type: "string", description: "The attachment ID"}
        },
        required: %w[message_id attachment_id]
      )

      class << self
        def call(message_id:, attachment_id:, server_context:, **)
          graph = server_context[:graph]
          att = graph.get_attachment(message_id, attachment_id)

          text = "Name: #{att["name"]}\n" \
            "Size: #{att["size"]} bytes\n" \
            "Content Type: #{att["contentType"]}\n" \
            "Is Inline: #{att["isInline"]}\n" \
            "ID: #{att["id"]}"

          text += "\nContent (base64): #{att["contentBytes"]&.slice(0, 500)}..." if att["contentBytes"]

          MCP::Tool::Response.new([{type: "text", text: text}])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{type: "text", text: "Error getting attachment: #{e.message}"}], error: true)
        end
      end
    end
  end
end
