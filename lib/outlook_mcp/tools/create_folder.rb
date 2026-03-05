# frozen_string_literal: true

module OutlookMcp
  module Tools
    class CreateFolder < MCP::Tool
      description "Create a new mail folder in the user's Outlook mailbox"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: true
      )

      input_schema(
        properties: {
          display_name: { type: "string", description: "Name of the new folder" },
          parent_folder_id: { type: "string", description: "Parent folder ID for creating a subfolder (optional)" }
        },
        required: ["display_name"]
      )

      class << self
        def call(display_name:, server_context:, **args)
          graph = server_context[:graph]
          folder = graph.create_folder(display_name: display_name, parent_folder_id: args[:parent_folder_id])
          MCP::Tool::Response.new([{ type: "text", text: "Folder created: #{folder["displayName"]} (ID: #{folder["id"]})" }])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{ type: "text", text: "Error creating folder: #{e.message}" }], error: true)
        end
      end
    end
  end
end
