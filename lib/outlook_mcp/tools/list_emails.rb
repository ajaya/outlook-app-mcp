# frozen_string_literal: true

module OutlookMcp
  module Tools
    class ListEmails < MCP::Tool
      description "List recent emails from the user's Outlook mailbox"

      annotations(
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: true
      )

      input_schema(
        properties: {
          folder_id: { type: "string", description: "Mail folder ID (defaults to Inbox)" },
          top: { type: "integer", description: "Number of emails to return (default 10, max 50)" },
          skip: { type: "integer", description: "Number of emails to skip for pagination" }
        }
      )

      class << self
        def call(server_context:, **args)
          graph = server_context[:graph]
          top = [args[:top] || 10, 50].min
          result = graph.list_messages(folder_id: args[:folder_id], top: top, skip: args[:skip] || 0)

          formatted = (result["value"] || []).map do |email|
            "From: #{email.dig("from", "emailAddress", "address")}\n" \
              "Subject: #{email["subject"]}\n" \
              "Date: #{email["receivedDateTime"]}\n" \
              "Read: #{email["isRead"]}\n" \
              "Preview: #{email["bodyPreview"]&.slice(0, 100)}\n" \
              "ID: #{email["id"]}"
          end.join("\n---\n")

          MCP::Tool::Response.new([{ type: "text", text: formatted.empty? ? "No emails found." : formatted }])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{ type: "text", text: "Error listing emails: #{e.message}" }], error: true)
        end
      end
    end
  end
end
