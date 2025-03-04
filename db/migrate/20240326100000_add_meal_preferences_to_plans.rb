class AddMealPreferencesToPlans < ActiveRecord::Migration[7.1]
  def change
    change_table :plans do |t|
      t.boolean :weekday_lunches, default: false
      t.boolean :weekday_dinners, default: true
      t.boolean :weekend_lunches, default: true
      t.boolean :weekend_dinners, default: true
    end
  end
end 