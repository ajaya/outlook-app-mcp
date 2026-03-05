# frozen_string_literal: true

module OutlookMcp
  module Graph
    module Email
      def list_messages(folder_id: nil, top: 10, skip: 0)
        path = folder_id ? "/me/mailFolders/#{folder_id}/messages" : "/me/messages"
        get(path, {
          "$top" => top,
          "$skip" => skip,
          "$select" => "id,subject,from,toRecipients,receivedDateTime,isRead,isDraft,hasAttachments,bodyPreview,importance,flag",
          "$orderby" => "receivedDateTime desc"
        })
      end

      def search_messages(query:, top: 10)
        escaped_query = query.gsub('\\', '\\\\').gsub('"', '\\"')
        get("/me/messages", {
          "$search" => "\"#{escaped_query}\"",
          "$top" => top,
          "$select" => "id,subject,from,toRecipients,receivedDateTime,isRead,isDraft,hasAttachments,bodyPreview,importance"
        })
      end

      def get_message(id)
        get("/me/messages/#{id}", {
          "$select" => "id,subject,from,toRecipients,ccRecipients,bccRecipients,replyTo,body,receivedDateTime,sentDateTime,isRead,isDraft,hasAttachments,importance,conversationId,flag,internetMessageId"
        })
      end

      def send_mail(to:, subject:, body:, cc: [], bcc: [], reply_to: nil, importance: "normal")
        payload = {
          message: {
            subject: subject,
            body: { contentType: "HTML", content: body },
            toRecipients: to.map { |addr| { emailAddress: { address: addr } } },
            ccRecipients: cc.map { |addr| { emailAddress: { address: addr } } },
            bccRecipients: bcc.map { |addr| { emailAddress: { address: addr } } },
            importance: importance
          }
        }
        payload[:message][:replyTo] = [{ emailAddress: { address: reply_to } }] if reply_to
        post("/me/sendMail", payload)
      end

      def create_draft(to: [], subject: nil, body: nil, cc: [], bcc: [], importance: "normal")
        payload = {
          subject: subject,
          body: body ? { contentType: "HTML", content: body } : nil,
          toRecipients: to.map { |addr| { emailAddress: { address: addr } } },
          ccRecipients: cc.map { |addr| { emailAddress: { address: addr } } },
          bccRecipients: bcc.map { |addr| { emailAddress: { address: addr } } },
          importance: importance
        }.compact
        post("/me/messages", payload)
      end

      def send_draft(id)
        post("/me/messages/#{id}/send")
      end

      def update_message(id, attrs)
        patch("/me/messages/#{id}", attrs)
      end

      def delete_message(id)
        delete("/me/messages/#{id}")
      end

      def move_message(id, destination_folder_id)
        post("/me/messages/#{id}/move", { destinationId: destination_folder_id })
      end

      def copy_message(id, destination_folder_id)
        post("/me/messages/#{id}/copy", { destinationId: destination_folder_id })
      end

      def reply_to_message(id, comment:)
        post("/me/messages/#{id}/reply", { comment: comment })
      end

      def reply_all_to_message(id, comment:)
        post("/me/messages/#{id}/replyAll", { comment: comment })
      end

      def forward_message(id, to:, comment: nil)
        payload = {
          toRecipients: to.map { |addr| { emailAddress: { address: addr } } }
        }
        payload[:comment] = comment if comment
        post("/me/messages/#{id}/forward", payload)
      end

      def create_reply_draft(id, comment: nil)
        payload = comment ? { comment: comment } : {}
        post("/me/messages/#{id}/createReply", payload)
      end

      def create_reply_all_draft(id, comment: nil)
        payload = comment ? { comment: comment } : {}
        post("/me/messages/#{id}/createReplyAll", payload)
      end

      def create_forward_draft(id, to: [], comment: nil)
        payload = {}
        payload[:comment] = comment if comment
        payload[:toRecipients] = to.map { |addr| { emailAddress: { address: addr } } } if to.any?
        post("/me/messages/#{id}/createForward", payload)
      end

      def list_attachments(message_id)
        get("/me/messages/#{message_id}/attachments")
      end

      def get_attachment(message_id, attachment_id)
        get("/me/messages/#{message_id}/attachments/#{attachment_id}")
      end

      def add_attachment(message_id, name:, content_bytes:, content_type: "application/octet-stream")
        post("/me/messages/#{message_id}/attachments", {
          "@odata.type" => "#microsoft.graph.fileAttachment",
          name: name,
          contentType: content_type,
          contentBytes: content_bytes
        })
      end
    end
  end
end
