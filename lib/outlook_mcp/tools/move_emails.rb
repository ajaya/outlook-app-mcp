# frozen_string_literal: true

module OutlookMcp
  module Tools
    class MoveEmails < MCP::Tool
      description "Move one or more emails to a different mail folder"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: true
      )

      input_schema(
        properties: {
          message_ids: { type: "array", items: { type: "string" }, description: "Email message IDs to move" },
          destination_folder_id: { type: "string", description: "Destination folder ID" }
        },
        required: %w[message_ids destination_folder_id]
      )

      class << self
        def call(message_ids:, destination_folder_id:, server_context:, **)
          graph = server_context[:graph]
          moved = 0
          errors = []

          message_ids.each do |id|
            graph.move_message(id, destination_folder_id)
            moved += 1
          rescue Faraday::Error => e
            errors << "#{id}: #{e.message}"
          end

          text = "Moved #{moved}/#{message_ids.size} emails."
          text += "\nErrors:\n#{errors.join("\n")}" if errors.any?

          MCP::Tool::Response.new([{ type: "text", text: text }], error: errors.any?)
        end
      end
    end
  end
end
