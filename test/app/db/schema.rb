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

ActiveRecord::Schema[7.0].define(version: 2025_09_02_022119) do
  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "blogs", force: :cascade do |t|
    t.string "title", null: false
    t.string "description", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_blogs_on_user_id"
  end

  create_table "blogs_users", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "blog_id", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "thumbnails", force: :cascade do |t|
    t.integer "blog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id"], name: "index_thumbnails_on_blog_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.integer "group_id", null: false
    t.integer "age", null: false
    t.integer "status", null: false
    t.string "phone_numbers"
    t.string "contact_info"
    t.string "family_tree"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", null: false
    t.index ["group_id"], name: "index_users_on_group_id"
  end

  add_foreign_key "thumbnails", "blogs"
  add_foreign_key "users", "groups"
end
