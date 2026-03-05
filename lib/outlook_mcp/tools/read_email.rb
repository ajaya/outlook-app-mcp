# frozen_string_literal: true

module OutlookMcp
  module Tools
    class ReadEmail < MCP::Tool
      description "Read the full content of a specific email by its ID"

      annotations(
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: true
      )

      input_schema(
        properties: {
          id: { type: "string", description: "The email message ID" }
        },
        required: ["id"]
      )

      class << self
        def call(id:, server_context:, **)
          graph = server_context[:graph]
          email = graph.get_message(id)

          to = (email["toRecipients"] || []).map { |r| r.dig("emailAddress", "address") }.join(", ")
          cc = (email["ccRecipients"] || []).map { |r| r.dig("emailAddress", "address") }.join(", ")

          text = <<~EMAIL
            From: #{email.dig("from", "emailAddress", "address")}
            To: #{to}
            CC: #{cc}
            Subject: #{email["subject"]}
            Date: #{email["receivedDateTime"]}
            Has Attachments: #{email["hasAttachments"]}

            #{email.dig("body", "content")}
          EMAIL

          MCP::Tool::Response.new([{ type: "text", text: text }])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{ type: "text", text: "Error reading email: #{e.message}" }], error: true)
        end
      end
    end
  end
end
