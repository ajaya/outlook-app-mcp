# frozen_string_literal: true

require "test_helper"

class OAuthClientTest < Minitest::Test
  def setup
    @config = OutlookMcp::Config.new
    @oauth = OutlookMcp::Auth::OAuthClient.new(@config)
  end

  def test_authorization_url_contains_required_params
    url = @oauth.authorization_url

    assert_includes url, "https://login.microsoftonline.com/test-tenant/oauth2/v2.0/authorize"
    assert_includes url, "client_id=test-client-id"
    assert_includes url, "response_type=code"
    assert_includes url, "redirect_uri="
    assert_includes url, "response_mode=query"
  end

  def test_exchange_code_posts_to_token_endpoint
    stub_request(:post, "https://login.microsoftonline.com/test-tenant/oauth2/v2.0/token")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {access_token: "at-123", refresh_token: "rt-456", expires_in: 3600}.to_json
      )

    result = @oauth.exchange_code("auth-code-123")

    assert_equal "at-123", result[:access_token]
    assert_equal "rt-456", result[:refresh_token]
    assert_equal 3600, result[:expires_in]
  end

  def test_exchange_code_raises_on_error
    stub_request(:post, "https://login.microsoftonline.com/test-tenant/oauth2/v2.0/token")
      .to_return(
        status: 400,
        headers: {"Content-Type" => "application/json"},
        body: {error: "invalid_grant", error_description: "Code expired"}.to_json
      )

    assert_raises(RuntimeError, /Code expired/) { @oauth.exchange_code("bad-code") }
  end

  def test_refresh_token_posts_to_token_endpoint
    stub_request(:post, "https://login.microsoftonline.com/test-tenant/oauth2/v2.0/token")
      .to_return(
        status: 200,
        headers: {"Content-Type" => "application/json"},
        body: {access_token: "new-at", refresh_token: "new-rt", expires_in: 3600}.to_json
      )

    result = @oauth.refresh_token("old-refresh-token")

    assert_equal "new-at", result[:access_token]
  end
end
