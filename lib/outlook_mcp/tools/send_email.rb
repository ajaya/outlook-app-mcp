# frozen_string_literal: true

module OutlookMcp
  module Tools
    class SendEmail < MCP::Tool
      description "Send an email from the user's Outlook account"

      annotations(
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: true
      )

      input_schema(
        properties: {
          to: { type: "array", items: { type: "string" }, description: "Recipient email addresses" },
          subject: { type: "string", description: "Email subject" },
          body: { type: "string", description: "Email body (HTML supported)" },
          cc: { type: "array", items: { type: "string" }, description: "CC recipients (optional)" }
        },
        required: %w[to subject body]
      )

      class << self
        def call(to:, subject:, body:, server_context:, **args)
          graph = server_context[:graph]
          graph.send_mail(to: to, subject: subject, body: body, cc: args[:cc] || [])
          MCP::Tool::Response.new([{ type: "text", text: "Email sent successfully to #{to.join(", ")}." }])
        rescue Faraday::Error => e
          MCP::Tool::Response.new([{ type: "text", text: "Error sending email: #{e.message}" }], error: true)
        end
      end
    end
  end
end
