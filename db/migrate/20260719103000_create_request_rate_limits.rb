class CreateRequestRateLimits < ActiveRecord::Migration[8.0]
  def change
    create_table :request_rate_limits do |table|
      table.string :key, null: false
      table.integer :count, default: 0, null: false
      table.datetime :window_started_at, null: false
      table.datetime :expires_at, null: false

      table.timestamps
    end

    add_index :request_rate_limits, :key, unique: true
    add_index :request_rate_limits, :expires_at
  end
end
