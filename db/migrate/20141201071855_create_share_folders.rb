class CreateShareFolders < ActiveRecord::Migration
  def change
    create_table :share_folders do |t|
      t.integer :user_id
      t.string :shared_email
      t.integer :shared_user_id
      t.integer :folder_id
      t.string :message

      t.timestamps
    end

    add_index :share_folders, :user_id 
    add_index :share_folders, :folder_id
    add_index :share_folders, :shared_user_id
  end
end
