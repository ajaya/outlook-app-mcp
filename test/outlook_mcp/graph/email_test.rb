# frozen_string_literal: true

require "test_helper"

class GraphEmailTest < Minitest::Test
  def setup
    @token_store = Object.new
    @token_store.define_singleton_method(:access_token) { "test-token" }
    @token_store.define_singleton_method(:refresh!) { nil }
    @client = OutlookMcp::Graph::Client.new(@token_store)
  end

  def test_list_messages
    stub_graph_get(%r{/v1\.0/me/messages})
      .to_return(json_response({"value" => [{"id" => "1", "subject" => "Hello"}]}))

    result = @client.list_messages(top: 5)

    assert_equal 1, result["value"].size
    assert_equal "Hello", result["value"][0]["subject"]
  end

  def test_list_messages_with_folder
    stub_graph_get(%r{/v1\.0/me/mailFolders/drafts/messages})
      .to_return(json_response({"value" => []}))

    result = @client.list_messages(folder_id: "drafts")

    assert_equal [], result["value"]
  end

  def test_search_messages
    stub_graph_get(%r{/v1\.0/me/messages})
      .to_return(json_response({"value" => [{"id" => "1", "subject" => "Invoice"}]}))

    result = @client.search_messages(query: "invoice")

    assert_equal "Invoice", result["value"][0]["subject"]
  end

  def test_get_message
    stub_graph_get(%r{/v1\.0/me/messages/msg-1})
      .to_return(json_response({"id" => "msg-1", "subject" => "Test", "body" => {"content" => "<p>Hi</p>"}}))

    result = @client.get_message("msg-1")

    assert_equal "msg-1", result["id"]
    assert_equal "<p>Hi</p>", result.dig("body", "content")
  end

  def test_send_mail
    stub_graph(:post, "/me/sendMail")
      .to_return(status: 202, body: "", headers: {"Content-Type" => "application/json"})

    @client.send_mail(to: ["bob@example.com"], subject: "Hi", body: "<p>Hello</p>")

    assert_requested(:post, "https://graph.microsoft.com/v1.0/me/sendMail")
  end

  def test_create_draft
    stub_graph(:post, "/me/messages")
      .to_return(json_response({"id" => "draft-1", "subject" => "Draft", "isDraft" => true}))

    result = @client.create_draft(subject: "Draft", to: ["a@b.com"])

    assert_equal "draft-1", result["id"]
    assert result["isDraft"]
  end

  def test_reply_to_message
    stub_graph(:post, "/me/messages/msg-1/reply")
      .to_return(status: 202, body: "", headers: {"Content-Type" => "application/json"})

    @client.reply_to_message("msg-1", comment: "Thanks!")

    assert_requested(:post, "https://graph.microsoft.com/v1.0/me/messages/msg-1/reply")
  end

  def test_forward_message
    stub_graph(:post, "/me/messages/msg-1/forward")
      .to_return(status: 202, body: "", headers: {"Content-Type" => "application/json"})

    @client.forward_message("msg-1", to: ["fwd@example.com"], comment: "FYI")

    assert_requested(:post, "https://graph.microsoft.com/v1.0/me/messages/msg-1/forward")
  end

  def test_move_message
    stub_graph(:post, "/me/messages/msg-1/move")
      .to_return(json_response({"id" => "msg-1-new"}))

    result = @client.move_message("msg-1", "folder-2")

    assert_equal "msg-1-new", result["id"]
  end

  def test_copy_message
    stub_graph(:post, "/me/messages/msg-1/copy")
      .to_return(json_response({"id" => "msg-1-copy"}))

    result = @client.copy_message("msg-1", "folder-2")

    assert_equal "msg-1-copy", result["id"]
  end

  def test_delete_message
    stub_graph(:delete, "/me/messages/msg-1")
      .to_return(status: 204, body: "", headers: {"Content-Type" => "application/json"})

    @client.delete_message("msg-1")

    assert_requested(:delete, "https://graph.microsoft.com/v1.0/me/messages/msg-1")
  end

  def test_search_messages_escapes_quotes
    stub_graph_get(%r{/v1\.0/me/messages})
      .to_return(json_response({"value" => []}))

    @client.search_messages(query: 'from:"alice@test.com"')

    assert_requested(:get, %r{/v1\.0/me/messages})
  end

  def test_get_message_rejects_invalid_id
    assert_raises(ArgumentError) { @client.get_message("../admin") }
  end

  def test_list_attachments
    stub_graph_get(%r{/v1\.0/me/messages/msg-1/attachments})
      .to_return(json_response({"value" => [{"id" => "att-1", "name" => "doc.pdf", "size" => 1024}]}))

    result = @client.list_attachments("msg-1")

    assert_equal "doc.pdf", result["value"][0]["name"]
  end

  private

  def stub_graph(method, path)
    stub_request(method, "https://graph.microsoft.com/v1.0#{path}")
  end

  def stub_graph_get(pattern)
    stub_request(:get, pattern)
  end

  def json_response(body, status: 200)
    {status: status, body: body.to_json, headers: {"Content-Type" => "application/json"}}
  end
end
