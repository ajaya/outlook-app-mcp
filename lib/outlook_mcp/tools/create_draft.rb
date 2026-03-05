# frozen_string_literal: true

module OutlookMcp
  module Tools
    class CreateDraft < MCP::Tool
      description "Create a new email draft in the Drafts folder"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: true
      )

      input_schema(
        properties: {
          to: {type: "array", items: {type: "string"}, description: "Recipient email addresses"},
          subject: {type: "string", description: "Email subject"},
          body: {type: "string", description: "Email body (HTML supported)"},
          cc: {type: "array", items: {type: "string"}, description: "CC recipients (optional)"},
          bcc: {type: "array", items: {type: "string"}, description: "BCC recipients (optional)"},
          importance: {type: "string", enum: %w[low normal high], description: "Importance level (default: normal)"}
        },
        required: ["subject"]
      )

      class << self
        def call(subject:, server_context:, **args)
          graph = server_context[:graph]
          draft = graph.create_draft(
            to: args[:to] || [],
            subject: subject,
            body: args[:body],
            cc: args[:cc] || [],
            bcc: args[:bcc] || [],
            importance: args[:importance] || "normal"
          )
          MCP::Tool::Response.new([{type: "text", text: "Draft created: #{draft["subject"]} (ID: #{draft["id"]})"}])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{type: "text", text: "Error creating draft: #{e.message}"}], error: true)
        end
      end
    end
  end
end
