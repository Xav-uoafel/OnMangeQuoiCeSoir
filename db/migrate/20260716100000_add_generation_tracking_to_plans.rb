class AddGenerationTrackingToPlans < ActiveRecord::Migration[8.0]
  def change
    change_table :plans, bulk: true do |table|
      table.string :generation_token
      table.datetime :generation_started_at
      table.datetime :generation_completed_at
      table.string :generation_error_code
      table.integer :generation_attempts, default: 0, null: false
    end

    add_index :plans, :generation_token, unique: true
    add_index :plans, %i[status generation_started_at]
  end
end
