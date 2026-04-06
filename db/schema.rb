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

ActiveRecord::Schema[7.1].define(version: 2026_04_06_215427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cooked_recipes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "recipe_id", null: false
    t.date "cooked_on", default: -> { "CURRENT_DATE" }, null: false
    t.boolean "liked"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_cooked_recipes_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "index_cooked_recipes_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_cooked_recipes_on_user_id"
  end

  create_table "households", force: :cascade do |t|
    t.string "name"
    t.string "invite_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_code"], name: "index_households_on_invite_code", unique: true
  end

  create_table "pantry_items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "category"
    t.string "quantity_text"
    t.date "detected_on"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pantry_items_on_user_id"
  end

  create_table "pantry_scans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "label"
    t.integer "items_detected", default: 0
    t.string "status", default: "processing"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pantry_scans_on_user_id"
  end

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
    t.jsonb "ingredients_from_pantry", default: []
    t.jsonb "ingredients_to_buy", default: []
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

  create_table "shopping_list_items", force: :cascade do |t|
    t.bigint "shopping_list_id", null: false
    t.string "name", null: false
    t.string "quantity_text"
    t.string "category"
    t.boolean "checked", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shopping_list_id"], name: "index_shopping_list_items_on_shopping_list_id"
  end

  create_table "shopping_lists", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "user_id", null: false
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_shopping_lists_on_plan_id"
    t.index ["user_id"], name: "index_shopping_lists_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "household_size", default: 2
    t.jsonb "dietary_restrictions", default: []
    t.jsonb "excluded_ingredients", default: []
    t.integer "preferred_max_prep_time"
    t.boolean "onboarding_completed", default: false
    t.bigint "household_id"
    t.string "household_role", default: "member"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["household_id"], name: "index_users_on_household_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cooked_recipes", "recipes"
  add_foreign_key "cooked_recipes", "users"
  add_foreign_key "pantry_items", "users"
  add_foreign_key "pantry_scans", "users"
  add_foreign_key "plan_recipes", "plans"
  add_foreign_key "plan_recipes", "recipes"
  add_foreign_key "plans", "users"
  add_foreign_key "recipes", "users"
  add_foreign_key "reviews", "recipes"
  add_foreign_key "reviews", "users"
  add_foreign_key "shopping_list_items", "shopping_lists"
  add_foreign_key "shopping_lists", "plans"
  add_foreign_key "shopping_lists", "users"
  add_foreign_key "users", "households"
end
