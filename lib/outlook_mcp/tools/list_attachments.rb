# frozen_string_literal: true

module OutlookMcp
  module Tools
    class ListAttachments < MCP::Tool
      description "List attachments on an email message"

      annotations(
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: true
      )

      input_schema(
        properties: {
          message_id: {type: "string", description: "The email message ID"}
        },
        required: ["message_id"]
      )

      class << self
        def call(message_id:, server_context:, **)
          graph = server_context[:graph]
          result = graph.list_attachments(message_id)

          formatted = (result["value"] || []).map do |att|
            "Name: #{att["name"]}\n" \
              "Size: #{att["size"]} bytes\n" \
              "Content Type: #{att["contentType"]}\n" \
              "Is Inline: #{att["isInline"]}\n" \
              "ID: #{att["id"]}"
          end.join("\n---\n")

          MCP::Tool::Response.new([{type: "text", text: formatted.empty? ? "No attachments." : formatted}])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{type: "text", text: "Error listing attachments: #{e.message}"}], error: true)
        end
      end
    end
  end
end
