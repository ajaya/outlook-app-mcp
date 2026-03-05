# frozen_string_literal: true

require "dotenv"

module OutlookMcp
  class Config
    SCOPES = "offline_access User.Read Mail.Read Mail.ReadWrite Mail.Send"

    attr_reader :client_id, :client_secret, :tenant_id, :token_path, :redirect_uri, :scopes

    def initialize
      Dotenv.load
      @client_id     = ENV.fetch("OUTLOOK_CLIENT_ID")
      @client_secret = ENV.fetch("OUTLOOK_CLIENT_SECRET")
      @tenant_id     = ENV.fetch("OUTLOOK_TENANT_ID", "common")
      @token_path    = ENV.fetch("OUTLOOK_TOKEN_PATH", File.expand_path("~/.outlook-mcp-tokens.json"))
      @redirect_uri  = ENV.fetch("OUTLOOK_REDIRECT_URI", "http://localhost:3333/auth/callback")
      @scopes        = ENV.fetch("OUTLOOK_SCOPES", SCOPES)
    end

    def authorize_url
      "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/authorize"
    end

    def token_url
      "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token"
    end
  end
end
