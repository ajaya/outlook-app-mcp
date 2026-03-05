# frozen_string_literal: true

require "test_helper"

class ServerTest < Minitest::Test
  def test_tools_constant_has_all_tools
    assert_equal 17, OutlookMcp::Server::TOOLS.size
  end

  def test_all_tools_are_mcp_tools
    OutlookMcp::Server::TOOLS.each do |tool|
      assert tool < MCP::Tool, "#{tool.name} should inherit from MCP::Tool"
    end
  end

  def test_all_tools_have_descriptions
    OutlookMcp::Server::TOOLS.each do |tool|
      refute_nil tool.description, "#{tool.name} should have a description"
      refute_empty tool.description, "#{tool.name} description should not be empty"
    end
  end

  def test_all_tools_have_annotations
    OutlookMcp::Server::TOOLS.each do |tool|
      refute_nil tool.annotations, "#{tool.name} should have annotations"
    end
  end

  def test_all_tools_have_input_schema
    OutlookMcp::Server::TOOLS.each do |tool|
      refute_nil tool.input_schema, "#{tool.name} should have an input_schema"
    end
  end

  def test_tool_names_are_unique
    names = OutlookMcp::Server::TOOLS.map(&:name)
    assert_equal names.uniq.size, names.size, "Tool names must be unique"
  end

  def test_read_only_tools
    read_only = OutlookMcp::Server::TOOLS.select { |t| t.annotations&.read_only_hint }
    read_only_names = read_only.map { |t| t.name.split("::").last }

    %w[ListEmails SearchEmails ReadEmail ListFolders ListAttachments GetAttachment].each do |name|
      assert_includes read_only_names, name, "#{name} should be read-only"
    end
  end

  def test_destructive_tools
    destructive = OutlookMcp::Server::TOOLS.select { |t| t.annotations&.destructive_hint }
    destructive_names = destructive.map { |t| t.name.split("::").last }

    assert_includes destructive_names, "DeleteEmail"
  end
end
