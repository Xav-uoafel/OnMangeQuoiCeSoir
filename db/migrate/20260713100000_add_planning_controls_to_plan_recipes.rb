class AddPlanningControlsToPlanRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :plan_recipes, :locked, :boolean, default: false, null: false
    add_column :plan_recipes, :replacement_status, :string, default: "ready", null: false
    add_index :plan_recipes, :replacement_status
  end
end
