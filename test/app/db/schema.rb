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

ActiveRecord::Schema.define(version: 2025_05_02_115736) do

  create_table "blogs", force: :cascade do |t|
    t.string "title", null: false
    t.string "description", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_blogs_on_user_id"
  end

  create_table "blogs_users", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "blog_id", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.integer "age", null: false
    t.integer "status", null: false
    t.string "phone_numbers"
    t.string "contact_info"
    t.string "family_tree"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
