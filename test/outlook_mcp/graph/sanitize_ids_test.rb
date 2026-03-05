# frozen_string_literal: true

require "test_helper"

class SanitizeIdsTest < Minitest::Test
  def test_sanitize_allows_valid_ids
    assert_equal "AAMkAGI2TG93AAA=", OutlookMcp::Graph::SanitizeIds.sanitize!("AAMkAGI2TG93AAA=")
    assert_equal "msg-1", OutlookMcp::Graph::SanitizeIds.sanitize!("msg-1")
    assert_equal "abc_def.123", OutlookMcp::Graph::SanitizeIds.sanitize!("abc_def.123")
  end

  def test_sanitize_rejects_path_traversal
    assert_raises(ArgumentError) { OutlookMcp::Graph::SanitizeIds.sanitize!("../etc/passwd") }
    assert_raises(ArgumentError) { OutlookMcp::Graph::SanitizeIds.sanitize!("msg-1/../../admin") }
    assert_raises(ArgumentError) { OutlookMcp::Graph::SanitizeIds.sanitize!("id with spaces") }
    assert_raises(ArgumentError) { OutlookMcp::Graph::SanitizeIds.sanitize!("") }
    assert_raises(ArgumentError) { OutlookMcp::Graph::SanitizeIds.sanitize!(nil) }
  end

  def test_wrap_generates_sanitizing_wrappers
    token_store = Object.new
    token_store.define_singleton_method(:access_token) { "test-token" }
    token_store.define_singleton_method(:refresh!) { nil }

    client = OutlookMcp::Graph::Client.new(token_store)

    assert_raises(ArgumentError) { client.get_message("../admin") }
    assert_raises(ArgumentError) { client.delete_message("foo/bar") }
    assert_raises(ArgumentError) { client.move_message("ok", "../bad") }
  end

  def test_wrap_skips_methods_without_id_params
    # search_messages has no ID params, should not raise on any query string
    token_store = Object.new
    token_store.define_singleton_method(:access_token) { "test-token" }
    token_store.define_singleton_method(:refresh!) { nil }

    client = OutlookMcp::Graph::Client.new(token_store)

    stub_request(:get, %r{graph\.microsoft\.com/v1\.0/me/messages})
      .to_return(status: 200, body: {"value" => []}.to_json, headers: {"Content-Type" => "application/json"})

    # Should not raise even with slashes in the query
    client.search_messages(query: "from:../admin")
  end

  def test_wrap_sanitizes_keyword_id_params
    token_store = Object.new
    token_store.define_singleton_method(:access_token) { "test-token" }
    token_store.define_singleton_method(:refresh!) { nil }

    client = OutlookMcp::Graph::Client.new(token_store)

    assert_raises(ArgumentError) { client.list_messages(folder_id: "../bad") }
    assert_raises(ArgumentError) { client.create_folder(display_name: "X", parent_folder_id: "a/b") }
  end
end
