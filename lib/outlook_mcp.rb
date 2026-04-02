# frozen_string_literal: true

require "dotenv"
require "faraday"
require "json"
require "mcp"
require "rack"
require "thor"
require "uri"
require "webrick"
require "zeitwerk"

module OutlookMcp
  class << self
    def loader
      @loader ||= begin
        loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
        loader.inflector.inflect("oauth_client" => "OAuthClient", "cli" => "CLI")
        loader.setup
        loader
      end
    end

    def eager_load!
      loader.eager_load
    end
  end
end

OutlookMcp.loader
