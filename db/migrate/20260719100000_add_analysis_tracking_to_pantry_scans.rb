class AddAnalysisTrackingToPantryScans < ActiveRecord::Migration[8.0]
  def change
    change_table :pantry_scans, bulk: true do |table|
      table.string :analysis_token
      table.datetime :analysis_started_at
      table.datetime :analysis_completed_at
      table.string :analysis_error_code
      table.integer :analysis_attempts, default: 0, null: false
    end

    add_index :pantry_scans, :analysis_token, unique: true
    add_index :pantry_scans, %i[status analysis_started_at]
  end
end
