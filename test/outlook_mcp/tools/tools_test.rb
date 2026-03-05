# frozen_string_literal: true

require "test_helper"

class ToolsTest < Minitest::Test
  def setup
    @graph = Minitest::Mock.new
    @ctx = {graph: @graph}
  end

  # --- ListEmails ---

  def test_list_emails_formats_results
    @graph.expect(:list_messages, {
      "value" => [
        {"id" => "1", "subject" => "Hello", "from" => {"emailAddress" => {"address" => "a@b.com"}},
         "receivedDateTime" => "2025-01-01T00:00:00Z", "isRead" => false, "bodyPreview" => "Preview text"}
      ]
    }, folder_id: nil, top: 10, skip: 0)

    response = OutlookMcp::Tools::ListEmails.call(server_context: @ctx)

    assert_includes response_text(response), "Hello"
    assert_includes response_text(response), "a@b.com"
    refute response.error?
  end

  def test_list_emails_empty
    @graph.expect(:list_messages, {"value" => []}, folder_id: nil, top: 10, skip: 0)

    response = OutlookMcp::Tools::ListEmails.call(server_context: @ctx)

    assert_equal "No emails found.", response_text(response)
  end

  def test_list_emails_caps_top_at_50
    @graph.expect(:list_messages, {"value" => []}, folder_id: nil, top: 50, skip: 0)

    OutlookMcp::Tools::ListEmails.call(server_context: @ctx, top: 100)

    @graph.verify
  end

  # --- SearchEmails ---

  def test_search_emails
    @graph.expect(:search_messages, {
      "value" => [{"id" => "1", "subject" => "Invoice", "from" => {"emailAddress" => {"address" => "x@y.com"}},
                   "receivedDateTime" => "2025-01-01", "bodyPreview" => "Amount due"}]
    }, query: "invoice", top: 10)

    response = OutlookMcp::Tools::SearchEmails.call(query: "invoice", server_context: @ctx)

    assert_includes response_text(response), "Invoice"
  end

  # --- ReadEmail ---

  def test_read_email
    @graph.expect(:get_message, {
      "id" => "msg-1", "subject" => "Test",
      "from" => {"emailAddress" => {"address" => "sender@test.com"}},
      "toRecipients" => [{"emailAddress" => {"address" => "me@test.com"}}],
      "ccRecipients" => [],
      "body" => {"content" => "<p>Body content</p>"},
      "receivedDateTime" => "2025-01-01", "hasAttachments" => false
    }, ["msg-1"])

    response = OutlookMcp::Tools::ReadEmail.call(id: "msg-1", server_context: @ctx)

    assert_includes response_text(response), "sender@test.com"
    assert_includes response_text(response), "Body content"
  end

  # --- SendEmail ---

  def test_send_email
    @graph.expect(:send_mail, nil, to: ["bob@test.com"], subject: "Hi", body: "<p>Hey</p>", cc: [])

    response = OutlookMcp::Tools::SendEmail.call(
      to: ["bob@test.com"], subject: "Hi", body: "<p>Hey</p>", server_context: @ctx
    )

    assert_includes response_text(response), "Email sent successfully"
    assert_includes response_text(response), "bob@test.com"
  end

  # --- ReplyToEmail ---

  def test_reply_to_email
    @graph.expect(:reply_to_message, nil, ["msg-1"], comment: "Thanks!")

    response = OutlookMcp::Tools::ReplyToEmail.call(id: "msg-1", comment: "Thanks!", server_context: @ctx)

    assert_includes response_text(response), "Reply sent"
  end

  # --- ReplyAllToEmail ---

  def test_reply_all_to_email
    @graph.expect(:reply_all_to_message, nil, ["msg-1"], comment: "Noted")

    response = OutlookMcp::Tools::ReplyAllToEmail.call(id: "msg-1", comment: "Noted", server_context: @ctx)

    assert_includes response_text(response), "Reply-all sent"
  end

  # --- ForwardEmail ---

  def test_forward_email
    @graph.expect(:forward_message, nil, ["msg-1"], to: ["fwd@test.com"], comment: nil)

    response = OutlookMcp::Tools::ForwardEmail.call(id: "msg-1", to: ["fwd@test.com"], server_context: @ctx)

    assert_includes response_text(response), "forwarded"
    assert_includes response_text(response), "fwd@test.com"
  end

  # --- CreateDraft ---

  def test_create_draft
    @graph.expect(:create_draft, {"id" => "draft-1", "subject" => "My Draft"},
      to: ["a@b.com"], subject: "My Draft", body: nil, cc: [], bcc: [], importance: "normal")

    response = OutlookMcp::Tools::CreateDraft.call(subject: "My Draft", to: ["a@b.com"], server_context: @ctx)

    assert_includes response_text(response), "Draft created"
    assert_includes response_text(response), "draft-1"
  end

  # --- SendDraft ---

  def test_send_draft
    @graph.expect(:send_draft, nil, ["draft-1"])

    response = OutlookMcp::Tools::SendDraft.call(id: "draft-1", server_context: @ctx)

    assert_includes response_text(response), "Draft sent"
  end

  # --- MarkAsRead ---

  def test_mark_as_read
    @graph.expect(:update_message, nil, ["msg-1", {isRead: true}])

    response = OutlookMcp::Tools::MarkAsRead.call(id: "msg-1", server_context: @ctx)

    assert_includes response_text(response), "marked as read"
  end

  def test_mark_as_unread
    @graph.expect(:update_message, nil, ["msg-1", {isRead: false}])

    response = OutlookMcp::Tools::MarkAsRead.call(id: "msg-1", is_read: false, server_context: @ctx)

    assert_includes response_text(response), "marked as unread"
  end

  # --- MoveEmails ---

  def test_move_emails
    @graph.expect(:move_message, nil, ["msg-1", "folder-2"])
    @graph.expect(:move_message, nil, ["msg-2", "folder-2"])

    response = OutlookMcp::Tools::MoveEmails.call(
      message_ids: ["msg-1", "msg-2"], destination_folder_id: "folder-2", server_context: @ctx
    )

    assert_includes response_text(response), "Moved 2/2"
  end

  # --- CopyEmail ---

  def test_copy_email
    @graph.expect(:copy_message, {"id" => "msg-copy"}, ["msg-1", "folder-2"])

    response = OutlookMcp::Tools::CopyEmail.call(id: "msg-1", destination_folder_id: "folder-2", server_context: @ctx)

    assert_includes response_text(response), "copied"
  end

  # --- DeleteEmail ---

  def test_delete_email
    @graph.expect(:delete_message, nil, ["msg-1"])

    response = OutlookMcp::Tools::DeleteEmail.call(id: "msg-1", server_context: @ctx)

    assert_includes response_text(response), "deleted"
  end

  # --- ListFolders ---

  def test_list_folders
    @graph.expect(:list_folders, {
      "value" => [{"id" => "f1", "displayName" => "Inbox", "totalItemCount" => 10, "unreadItemCount" => 2}]
    }, top: 25)

    response = OutlookMcp::Tools::ListFolders.call(server_context: @ctx)

    assert_includes response_text(response), "Inbox"
  end

  # --- CreateFolder ---

  def test_create_folder
    @graph.expect(:create_folder, {"id" => "f-new", "displayName" => "Archive"},
      display_name: "Archive", parent_folder_id: nil)

    response = OutlookMcp::Tools::CreateFolder.call(display_name: "Archive", server_context: @ctx)

    assert_includes response_text(response), "Folder created"
    assert_includes response_text(response), "Archive"
  end

  # --- ListAttachments ---

  def test_list_attachments
    @graph.expect(:list_attachments, {
      "value" => [{"id" => "att-1", "name" => "report.pdf", "size" => 2048, "contentType" => "application/pdf", "isInline" => false}]
    }, ["msg-1"])

    response = OutlookMcp::Tools::ListAttachments.call(message_id: "msg-1", server_context: @ctx)

    assert_includes response_text(response), "report.pdf"
    assert_includes response_text(response), "2048 bytes"
  end

  def test_list_attachments_empty
    @graph.expect(:list_attachments, {"value" => []}, ["msg-1"])

    response = OutlookMcp::Tools::ListAttachments.call(message_id: "msg-1", server_context: @ctx)

    assert_equal "No attachments.", response_text(response)
  end

  # --- GetAttachment ---

  def test_get_attachment
    @graph.expect(:get_attachment, {
      "id" => "att-1", "name" => "doc.pdf", "size" => 1024,
      "contentType" => "application/pdf", "isInline" => false, "contentBytes" => "AQID"
    }, ["msg-1", "att-1"])

    response = OutlookMcp::Tools::GetAttachment.call(
      message_id: "msg-1", attachment_id: "att-1", server_context: @ctx
    )

    assert_includes response_text(response), "doc.pdf"
    assert_includes response_text(response), "AQID"
  end

  private

  def response_text(response)
    response.content.first[:text]
  end
end
