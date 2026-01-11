class RemoveDeviseColumnsFromUsers < ActiveRecord::Migration[8.1]
  def change
    # Remove old Devise columns that have been replaced by Rails 8 authentication
    remove_column :users, :email, :string
    remove_column :users, :encrypted_password, :string
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime

    # Remove lockable columns (not needed)
    remove_column :users, :failed_attempts, :integer
    remove_column :users, :unlock_token, :string
    remove_column :users, :locked_at, :datetime

    # Remove corresponding indexes
    remove_index :users, name: "index_users_on_email" if index_exists?(:users, :email, name: "index_users_on_email")
    remove_index :users, name: "index_users_on_reset_password_token" if index_exists?(:users, :reset_password_token, name: "index_users_on_reset_password_token")
    remove_index :users, name: "index_users_on_unlock_token" if index_exists?(:users, :unlock_token, name: "index_users_on_unlock_token")
  end
end
