class CreateRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :repositories do |t|
      t.bigint :github_id, null: false
      t.string :name, null: false
      t.string :full_name, null: false
      t.jsonb :raw_payload

      t.timestamps
    end

    add_index :repositories, :github_id, unique: true
    add_index :repositories, :full_name
  end
end
