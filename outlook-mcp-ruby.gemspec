# frozen_string_literal: true

require_relative "lib/outlook_mcp/version"

Gem::Specification.new do |spec|
  spec.name          = "outlook-mcp-ruby"
  spec.version       = OutlookMcp::VERSION
  spec.authors       = ["Ajaya Agrawalla"]
  spec.summary       = "MCP server for Microsoft Outlook via Graph API"
  spec.description   = "A Ruby MCP server that lets AI assistants read and manage Outlook email via Microsoft Graph API."
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.files         = Dir["lib/**/*", "bin/*", "LICENSE", "README.md"]
  spec.bindir        = "bin"
  spec.executables   = ["outlook-mcp"]

  spec.add_dependency "dotenv",  "~> 3.1"
  spec.add_dependency "faraday", "~> 2.9"
  spec.add_dependency "mcp",     ">= 0.8.0"
  spec.add_dependency "rack",    "~> 3.1"
  spec.add_dependency "rackup",  "~> 2.2"
  spec.add_dependency "thor",    "~> 1.3"
  spec.add_dependency "webrick", "~> 1.9"
  spec.add_dependency "zeitwerk","~> 2.7"

  spec.add_development_dependency "minitest",           "~> 5.25"
  spec.add_development_dependency "minitest-reporters", "~> 1.7"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop",            "~> 1.62"
  spec.add_development_dependency "webmock",            "~> 3.23"
end
