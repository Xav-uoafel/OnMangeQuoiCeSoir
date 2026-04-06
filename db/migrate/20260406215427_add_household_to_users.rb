class AddHouseholdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :household, foreign_key: true
    add_column :users, :household_role, :string, default: 'member'
  end
end
