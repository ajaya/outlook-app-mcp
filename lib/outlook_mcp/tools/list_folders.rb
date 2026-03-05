# frozen_string_literal: true

module OutlookMcp
  module Tools
    class ListFolders < MCP::Tool
      description "List mail folders in the user's Outlook mailbox"

      annotations(
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: true
      )

      input_schema(
        properties: {
          top: { type: "integer", description: "Number of folders to return (default 25)" }
        }
      )

      class << self
        def call(server_context:, **args)
          graph = server_context[:graph]
          result = graph.list_folders(top: args[:top] || 25)

          formatted = (result["value"] || []).map do |folder|
            "Name: #{folder["displayName"]}\n" \
              "Total: #{folder["totalItemCount"]}\n" \
              "Unread: #{folder["unreadItemCount"]}\n" \
              "ID: #{folder["id"]}"
          end.join("\n---\n")

          MCP::Tool::Response.new([{ type: "text", text: formatted.empty? ? "No folders found." : formatted }])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{ type: "text", text: "Error listing folders: #{e.message}" }], error: true)
        end
      end
    end
  end
end
