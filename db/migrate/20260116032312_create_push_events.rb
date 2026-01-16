class CreatePushEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :push_events do |t|
      t.string :github_event_id, null: false
      t.references :repository, null: true, foreign_key: true
      t.references :actor, null: true, foreign_key: true
      t.bigint :push_id, null: false
      t.string :ref, null: false
      t.string :head, null: false
      t.string :before, null: false
      t.jsonb :raw_payload, null: false
      t.datetime :enriched_at

      t.timestamps
    end

    add_index :push_events, :github_event_id, unique: true
    add_index :push_events, :push_id
    add_index :push_events, :ref
    add_index :push_events, :enriched_at
  end
end
