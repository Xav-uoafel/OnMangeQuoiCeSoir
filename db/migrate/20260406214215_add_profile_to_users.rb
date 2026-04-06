class AddProfileToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :household_size, :integer, default: 2
    add_column :users, :dietary_restrictions, :jsonb, default: []
    add_column :users, :excluded_ingredients, :jsonb, default: []
    add_column :users, :preferred_max_prep_time, :integer
    add_column :users, :onboarding_completed, :boolean, default: false
  end
end
