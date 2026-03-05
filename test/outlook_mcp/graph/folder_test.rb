# frozen_string_literal: true

require "test_helper"

class GraphFolderTest < Minitest::Test
  def setup
    @token_store = Object.new
    @token_store.define_singleton_method(:access_token) { "test-token" }
    @token_store.define_singleton_method(:refresh!) { nil }
    @client = OutlookMcp::Graph::Client.new(@token_store)
  end

  def test_list_folders
    stub_request(:get, %r{/v1\.0/me/mailFolders})
      .to_return(json_response({"value" => [
        {"id" => "f1", "displayName" => "Inbox", "totalItemCount" => 42, "unreadItemCount" => 3}
      ]}))

    result = @client.list_folders

    assert_equal 1, result["value"].size
    assert_equal "Inbox", result["value"][0]["displayName"]
  end

  def test_create_folder
    stub_graph(:post, "/me/mailFolders")
      .to_return(json_response({"id" => "new-f", "displayName" => "Archive"}))

    result = @client.create_folder(display_name: "Archive")

    assert_equal "Archive", result["displayName"]
  end

  def test_create_child_folder
    stub_graph(:post, "/me/mailFolders/parent-1/childFolders")
      .to_return(json_response({"id" => "child-f", "displayName" => "Sub"}))

    result = @client.create_folder(display_name: "Sub", parent_folder_id: "parent-1")

    assert_equal "Sub", result["displayName"]
  end

  private

  def stub_graph(method, path)
    stub_request(method, "https://graph.microsoft.com/v1.0#{path}")
  end

  def json_response(body, status: 200)
    {status: status, body: body.to_json, headers: {"Content-Type" => "application/json"}}
  end
end
