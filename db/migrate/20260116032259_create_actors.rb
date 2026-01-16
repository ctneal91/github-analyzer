class CreateActors < ActiveRecord::Migration[8.1]
  def change
    create_table :actors do |t|
      t.bigint :github_id, null: false
      t.string :login, null: false
      t.string :avatar_url
      t.jsonb :raw_payload

      t.timestamps
    end

    add_index :actors, :github_id, unique: true
    add_index :actors, :login
  end
end
