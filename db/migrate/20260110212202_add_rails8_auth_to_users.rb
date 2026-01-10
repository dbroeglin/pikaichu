class AddRails8AuthToUsers < ActiveRecord::Migration[8.1]
  def change
    # Add new Rails 8 authentication columns
    add_column :users, :email_address, :string
    add_column :users, :password_digest, :string
    
    # Add index on email_address for performance
    add_index :users, :email_address, unique: true
    
    # Copy data from Devise columns to Rails 8 columns
    reversible do |dir|
      dir.up do
        # Normalize email addresses and copy data
        execute <<-SQL
          UPDATE users 
          SET email_address = LOWER(TRIM(email)),
              password_digest = encrypted_password;
        SQL
      end
    end
  end
end
