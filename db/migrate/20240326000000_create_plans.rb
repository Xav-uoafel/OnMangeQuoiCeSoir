class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans do |t|
      t.references :user, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.json :constraints, null: false, default: {}
      t.string :status, null: false, default: 'draft'

      t.timestamps
    end

    create_table :plan_recipes do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.date :scheduled_for, null: false
      t.string :meal_type, null: false

      t.timestamps
    end

    add_index :plan_recipes, [:plan_id, :scheduled_for, :meal_type], unique: true
  end
end 