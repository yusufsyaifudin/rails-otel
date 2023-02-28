class CreateUsersTable < ActiveRecord::Migration[7.0]
  def up
    create_table :users, :id => false do |t|
      t.column :id, 'uuid', :null => false, :primary_key => true, :default => "uuid_generate_v4()"
      t.string :username, :null => false
      t.string :name, :null => false, :default => ''
      t.timestamps
    end

    add_index :users, :username, unique: true
  end

   def down
      drop_table :users
    end
end