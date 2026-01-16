class AddPayloadKeyToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :push_events, :payload_key, :string
    add_column :actors, :payload_key, :string
    add_column :repositories, :payload_key, :string

    add_index :push_events, :payload_key
    add_index :actors, :payload_key
    add_index :repositories, :payload_key
  end
end
