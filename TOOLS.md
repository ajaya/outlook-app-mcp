# Outlook MCP Tools — Mail API

## Implemented Tools (17)

### Read Operations

| Tool | Description | Graph Endpoint |
|------|-------------|----------------|
| `list_emails` | List recent emails with pagination | `GET /me/messages` |
| `search_emails` | Full-text search across emails | `GET /me/messages?$search=` |
| `read_email` | Read full email content by ID | `GET /me/messages/{id}` |
| `list_folders` | List mail folders with counts | `GET /me/mailFolders` |
| `list_attachments` | List attachments on an email | `GET /me/messages/{id}/attachments` |
| `get_attachment` | Get attachment details & content | `GET /me/messages/{id}/attachments/{aid}` |

### Compose & Send

| Tool | Description | Graph Endpoint |
|------|-------------|----------------|
| `send_email` | Send a new email (to, cc, bcc, importance) | `POST /me/sendMail` |
| `reply_to_email` | Reply to sender | `POST /me/messages/{id}/reply` |
| `reply_all_to_email` | Reply to all recipients | `POST /me/messages/{id}/replyAll` |
| `forward_email` | Forward email to recipients | `POST /me/messages/{id}/forward` |
| `create_draft` | Create draft in Drafts folder | `POST /me/messages` |
| `send_draft` | Send existing draft | `POST /me/messages/{id}/send` |

### Manage

| Tool | Description | Graph Endpoint |
|------|-------------|----------------|
| `mark_as_read` | Mark email read/unread | `PATCH /me/messages/{id}` |
| `move_emails` | Move emails to a folder | `POST /me/messages/{id}/move` |
| `copy_email` | Copy email to a folder | `POST /me/messages/{id}/copy` |
| `delete_email` | Delete email (to Deleted Items) | `DELETE /me/messages/{id}` |
| `create_folder` | Create a new mail folder | `POST /me/mailFolders` |

## Graph API Methods Available (Not Yet Exposed as Tools)

These methods are available in the Graph API and could be added as future tools:

### Message Operations
| Method | Graph Endpoint | Notes |
|--------|----------------|-------|
| Create reply draft | `POST /me/messages/{id}/createReply` | Available in `Graph::Email` module, not exposed as tool |
| Create reply-all draft | `POST /me/messages/{id}/createReplyAll` | Available in `Graph::Email` module, not exposed as tool |
| Create forward draft | `POST /me/messages/{id}/createForward` | Available in `Graph::Email` module, not exposed as tool |
| Update draft | `PATCH /me/messages/{id}` | Update subject, body, recipients on a draft before sending |
| Permanently delete | `POST /me/messages/{id}/permanentDelete` | Purges from recoverable items — cannot be undone |
| Get MIME content | `GET /me/messages/{id}/$value` | Raw RFC822 format |
| Send MIME message | `POST /me/sendMail` (with MIME) | Send raw MIME content |
| Add attachment to draft | `POST /me/messages/{id}/attachments` | Available in `Graph::Email` module |
| Large file upload | `POST /me/messages/{id}/attachments/createUploadSession` | For files 3-150 MB |
| Delete attachment | `DELETE /me/messages/{id}/attachments/{aid}` | Remove from draft |
| Get message delta | `GET /me/mailFolders/{id}/messages/delta` | Incremental sync |

### Folder Operations
| Method | Graph Endpoint | Notes |
|--------|----------------|-------|
| Get folder | `GET /me/mailFolders/{id}` | Get specific folder details |
| Update folder | `PATCH /me/mailFolders/{id}` | Rename folder |
| Delete folder | `DELETE /me/mailFolders/{id}` | Delete a mail folder |
| Move folder | `POST /me/mailFolders/{id}/move` | Move to different parent |
| Copy folder | `POST /me/mailFolders/{id}/copy` | Copy with contents |
| List child folders | `GET /me/mailFolders/{id}/childFolders` | Nested folder structure |
| Create child folder | `POST /me/mailFolders/{id}/childFolders` | Subfolder creation |
| List messages in folder | `GET /me/mailFolders/{id}/messages` | Already supported via `list_emails` folder_id param |

### Inbox Rules (Future)
| Method | Graph Endpoint | Notes |
|--------|----------------|-------|
| List rules | `GET /me/mailFolders/Inbox/messageRules` | Inbox automation rules |
| Create rule | `POST /me/mailFolders/Inbox/messageRules` | Auto-sort, forward, flag |
| Update rule | `PATCH /me/mailFolders/Inbox/messageRules/{id}` | Modify conditions/actions |
| Delete rule | `DELETE /me/mailFolders/Inbox/messageRules/{id}` | Remove automation |

### User & Mailbox Settings (Future)
| Method | Graph Endpoint | Notes |
|--------|----------------|-------|
| Get mailbox settings | `GET /me/mailboxSettings` | Auto-replies, timezone, working hours |
| Update mailbox settings | `PATCH /me/mailboxSettings` | Set auto-reply, locale |
| Get mail tips | `POST /me/getMailTips` | OOF status, mailbox full, etc. |
| Get categories | `GET /me/outlook/masterCategories` | Color categories |
| Get focused inbox overrides | `GET /me/inferenceClassification/overrides` | Focused/Other classification |

### Well-Known Folder Names
Use these as `folder_id` in `list_emails`:
- `inbox`, `drafts`, `sentitems`, `deleteditems`, `junkemail`, `archive`, `outbox`
