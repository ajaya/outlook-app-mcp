# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def test_loads_from_env
    config = OutlookMcp::Config.new

    assert_equal "test-client-id", config.client_id
    assert_equal "test-client-secret", config.client_secret
    assert_equal "test-tenant", config.tenant_id
  end

  def test_defaults
    config = OutlookMcp::Config.new

    assert_equal "http://localhost:3333/auth/callback", config.redirect_uri
    assert_includes config.scopes, "Mail.Read"
    assert_includes config.scopes, "offline_access"
  end

  def test_authorize_url
    config = OutlookMcp::Config.new

    assert_equal "https://login.microsoftonline.com/test-tenant/oauth2/v2.0/authorize", config.authorize_url
  end

  def test_token_url
    config = OutlookMcp::Config.new

    assert_equal "https://login.microsoftonline.com/test-tenant/oauth2/v2.0/token", config.token_url
  end
end
