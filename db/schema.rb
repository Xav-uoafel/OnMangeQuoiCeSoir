# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_02_26_000000) do
  create_table "plan_recipes", force: :cascade do |t|
    t.integer "plan_id", null: false
    t.integer "recipe_id", null: false
    t.date "scheduled_for", null: false
    t.string "meal_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id", "scheduled_for", "meal_type"], name: "index_plan_recipes_on_plan_id_and_scheduled_for_and_meal_type", unique: true
    t.index ["plan_id"], name: "index_plan_recipes_on_plan_id"
    t.index ["recipe_id"], name: "index_plan_recipes_on_recipe_id"
  end

  create_table "plans", force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.json "constraints", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "weekday_lunches", default: false
    t.boolean "weekday_dinners", default: true
    t.boolean "weekend_lunches", default: true
    t.boolean "weekend_dinners", default: true
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "ingredients"
    t.text "instructions"
    t.integer "servings"
    t.integer "preparation_time"
    t.integer "cooking_time"
    t.string "difficulty"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "rating", default: 0
    t.json "seasonal_ingredients_used", default: []
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "rating"
    t.text "comment"
    t.integer "recipe_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_reviews_on_recipe_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "plan_recipes", "plans"
  add_foreign_key "plan_recipes", "recipes"
  add_foreign_key "plans", "users"
  add_foreign_key "recipes", "users"
  add_foreign_key "reviews", "recipes"
  add_foreign_key "reviews", "users"
end
