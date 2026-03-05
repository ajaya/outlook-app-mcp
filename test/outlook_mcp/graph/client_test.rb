# frozen_string_literal: true

require "test_helper"

class GraphClientTest < Minitest::Test
  def setup
    @token_store = Object.new
    @token_store.define_singleton_method(:access_token) { "test-token" }
    @token_store.define_singleton_method(:refresh!) { nil }
    @client = OutlookMcp::Graph::Client.new(@token_store)
  end

  def test_get_sends_authorization_header
    stub_request(:get, "https://graph.microsoft.com/v1.0/me")
      .with(headers: {"Authorization" => "Bearer test-token"})
      .to_return(status: 200, body: {displayName: "Test"}.to_json, headers: {"Content-Type" => "application/json"})

    result = @client.get("/me")

    assert_equal "Test", result["displayName"]
  end

  def test_post_sends_json_body
    stub_request(:post, "https://graph.microsoft.com/v1.0/me/sendMail")
      .to_return(status: 202, body: "", headers: {"Content-Type" => "application/json"})

    @client.post("/me/sendMail", {message: {subject: "Hi"}})

    assert_requested(:post, "https://graph.microsoft.com/v1.0/me/sendMail")
  end

  def test_retries_on_401_then_succeeds
    call_count = 0
    token_store = Object.new
    token_store.define_singleton_method(:access_token) do
      call_count += 1
      call_count == 1 ? "expired-token" : "fresh-token"
    end
    token_store.define_singleton_method(:refresh!) { nil }

    client = OutlookMcp::Graph::Client.new(token_store)

    stub_request(:get, "https://graph.microsoft.com/v1.0/me")
      .with(headers: {"Authorization" => "Bearer expired-token"})
      .to_return(status: 401, body: {error: {code: "InvalidAuthenticationToken"}}.to_json, headers: {"Content-Type" => "application/json"})

    stub_request(:get, "https://graph.microsoft.com/v1.0/me")
      .with(headers: {"Authorization" => "Bearer fresh-token"})
      .to_return(status: 200, body: {displayName: "OK"}.to_json, headers: {"Content-Type" => "application/json"})

    result = client.get("/me")

    assert_equal "OK", result["displayName"]
  end

  def test_raises_on_second_401
    token_store = Object.new
    token_store.define_singleton_method(:access_token) { "bad-token" }
    token_store.define_singleton_method(:refresh!) { nil }

    client = OutlookMcp::Graph::Client.new(token_store)

    stub_request(:get, "https://graph.microsoft.com/v1.0/me")
      .to_return(status: 401, body: {error: {code: "InvalidAuthenticationToken"}}.to_json, headers: {"Content-Type" => "application/json"})

    assert_raises(Faraday::UnauthorizedError) { client.get("/me") }
  end

  def test_delete_request
    stub_request(:delete, "https://graph.microsoft.com/v1.0/me/messages/msg-1")
      .to_return(status: 204, body: "", headers: {"Content-Type" => "application/json"})

    @client.delete("/me/messages/msg-1")

    assert_requested(:delete, "https://graph.microsoft.com/v1.0/me/messages/msg-1")
  end
end
