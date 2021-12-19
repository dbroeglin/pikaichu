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

ActiveRecord::Schema.define(version: 2021_12_18_162658) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_enum :result_status, [
    "hit",
    "miss",
  ], force: :cascade

  create_table "dojos", force: :cascade do |t|
    t.string "shortname"
    t.string "name"
    t.string "country_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "participants", force: :cascade do |t|
    t.string "firstname"
    t.string "lastname"
    t.string "title"
    t.string "level"
    t.bigint "participating_dojo_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["participating_dojo_id"], name: "index_participants_on_participating_dojo_id"
  end

  create_table "participating_dojos", force: :cascade do |t|
    t.string "display_name"
    t.bigint "taikai_id", null: false
    t.bigint "dojo_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dojo_id"], name: "index_participating_dojos_on_dojo_id"
    t.index ["taikai_id", "dojo_id"], name: "by_taikai_dojo", unique: true
    t.index ["taikai_id"], name: "index_participating_dojos_on_taikai_id"
  end

  create_table "results", force: :cascade do |t|
    t.bigint "participant_id", null: false
    t.integer "round"
    t.integer "index"
    t.enum "status", enum_name: "result_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["participant_id", "round", "index"], name: "by_participant_round_index", unique: true
    t.index ["participant_id"], name: "index_results_on_participant_id"
  end

  create_table "taikais", force: :cascade do |t|
    t.string "shortname"
    t.string "name"
    t.text "description"
    t.date "start_date"
    t.date "end_date"
    t.boolean "distributed"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "participants", "participating_dojos"
  add_foreign_key "participating_dojos", "dojos"
  add_foreign_key "participating_dojos", "taikais"
  add_foreign_key "results", "participants"
end
