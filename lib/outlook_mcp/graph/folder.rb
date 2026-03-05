# frozen_string_literal: true

module OutlookMcp
  module Graph
    module Folder
      def list_folders(top: 25)
        get("/me/mailFolders", {
          "$top" => top,
          "$select" => "id,displayName,totalItemCount,unreadItemCount"
        })
      end

      def create_folder(display_name:, parent_folder_id: nil)
        path = parent_folder_id ? "/me/mailFolders/#{parent_folder_id}/childFolders" : "/me/mailFolders"
        post(path, { displayName: display_name })
      end
    end
  end
end
