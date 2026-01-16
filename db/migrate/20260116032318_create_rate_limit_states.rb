class CreateRateLimitStates < ActiveRecord::Migration[8.1]
  def change
    create_table :rate_limit_states do |t|
      t.string :endpoint, null: false
      t.integer :remaining, null: false, default: 60
      t.datetime :resets_at, null: false

      t.timestamps
    end

    add_index :rate_limit_states, :endpoint, unique: true
  end
end
