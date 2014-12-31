class ChangeSharedFolderIdInShareFolders < ActiveRecord::Migration
  def change
  	change_column :share_folders, :folder_id, :string
  end
end
