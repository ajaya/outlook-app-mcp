# frozen_string_literal: true

module OutlookMcp
  module Tools
    class SearchEmails < MCP::Tool
      description "Search emails in the user's Outlook mailbox using a query string"

      annotations(
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: true
      )

      input_schema(
        properties: {
          query: { type: "string", description: "Search query (searches subject, body, sender, etc.)" },
          top: { type: "integer", description: "Number of results to return (default 10, max 50)" }
        },
        required: ["query"]
      )

      class << self
        def call(query:, server_context:, **args)
          graph = server_context[:graph]
          top = [args[:top] || 10, 50].min
          result = graph.search_messages(query: query, top: top)

          formatted = (result["value"] || []).map do |email|
            "From: #{email.dig("from", "emailAddress", "address")}\n" \
              "Subject: #{email["subject"]}\n" \
              "Date: #{email["receivedDateTime"]}\n" \
              "Preview: #{email["bodyPreview"]&.slice(0, 100)}\n" \
              "ID: #{email["id"]}"
          end.join("\n---\n")

          MCP::Tool::Response.new([{ type: "text", text: formatted.empty? ? "No emails found." : formatted }])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{ type: "text", text: "Error searching emails: #{e.message}" }], error: true)
        end
      end
    end
  end
end
