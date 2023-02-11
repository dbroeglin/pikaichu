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

ActiveRecord::Schema[7.0].define(version: 2023_02_11_110818) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_enum :result_status, [
    "hit",
    "miss",
    "unknown",
  ], force: :cascade

  create_enum :taikai_form, [
    "individual",
    "team",
    "2in1",
    "matches",
  ], force: :cascade

  create_enum :taikai_scoring, [
    "kinteki",
    "enteki",
  ], force: :cascade

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
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

  create_table "dojos", force: :cascade do |t|
    t.string "shortname"
    t.string "name"
    t.string "city"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shortname"], name: "by_shortname", unique: true
  end

  create_table "kyudojins", force: :cascade do |t|
    t.string "lastname"
    t.string "firstname"
    t.string "federation_id"
    t.string "federation_country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "federation_club"
    t.index ["federation_id"], name: "by_federation_id", unique: true
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "taikai_id", null: false
    t.bigint "team1_id"
    t.bigint "team2_id"
    t.integer "level", limit: 2, null: false
    t.integer "index", limit: 2, null: false
    t.integer "winner", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["taikai_id"], name: "index_matches_on_taikai_id"
    t.index ["team1_id"], name: "index_matches_on_team1_id"
    t.index ["team2_id"], name: "index_matches_on_team2_id"
  end

  create_table "participants", force: :cascade do |t|
    t.integer "index"
    t.string "firstname"
    t.string "lastname"
    t.bigint "participating_dojo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id"
    t.integer "index_in_team"
    t.bigint "kyudojin_id"
    t.string "club", default: "", null: false
    t.integer "rank"
    t.integer "intermediate_rank"
    t.index ["kyudojin_id"], name: "index_participants_on_kyudojin_id"
    t.index ["participating_dojo_id", "index"], name: "participants_by_participating_dojo_index", unique: true
    t.index ["participating_dojo_id", "kyudojin_id"], name: "by_participants_participating_dojo_kyudojin", unique: true
    t.index ["participating_dojo_id"], name: "index_participants_on_participating_dojo_id"
    t.index ["team_id", "index_in_team"], name: "teams_by_team_index_in_team", unique: true
    t.index ["team_id"], name: "index_participants_on_team_id"
  end

  create_table "participating_dojos", force: :cascade do |t|
    t.string "display_name"
    t.bigint "taikai_id", null: false
    t.bigint "dojo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dojo_id"], name: "index_participating_dojos_on_dojo_id"
    t.index ["taikai_id", "dojo_id"], name: "by_taikai_dojo", unique: true
    t.index ["taikai_id"], name: "index_participating_dojos_on_taikai_id"
  end

  create_table "results", force: :cascade do |t|
    t.integer "round"
    t.integer "index"
    t.enum "status", enum_type: "result_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "final", default: false, null: false
    t.bigint "match_id"
    t.integer "value"
    t.bigint "score_id", null: false
    t.index ["match_id"], name: "index_results_on_match_id"
    t.index ["score_id"], name: "index_results_on_score_id"
  end

  create_table "scores", force: :cascade do |t|
    t.bigint "participant_id"
    t.bigint "team_id"
    t.bigint "match_id"
    t.integer "hits", default: 0
    t.integer "value", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_scores_on_match_id"
    t.index ["participant_id", "match_id"], name: "by_participant_id", unique: true
    t.index ["participant_id"], name: "index_scores_on_participant_id"
    t.index ["team_id", "match_id"], name: "by_team_id_match_id", unique: true
    t.index ["team_id"], name: "index_scores_on_team_id"
  end

  create_table "staff_roles", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "label", default: {}, null: false
    t.json "description", default: {}, null: false
    t.index ["code"], name: "by_staff_roles_code", unique: true
  end

  create_table "staffs", force: :cascade do |t|
    t.string "firstname"
    t.string "lastname"
    t.bigint "taikai_id", null: false
    t.bigint "role_id", null: false
    t.bigint "user_id"
    t.bigint "participating_dojo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participating_dojo_id"], name: "index_staffs_on_participating_dojo_id"
    t.index ["role_id"], name: "index_staffs_on_role_id"
    t.index ["taikai_id"], name: "index_staffs_on_taikai_id"
    t.index ["user_id"], name: "index_staffs_on_user_id"
  end

  create_table "taikai_transitions", force: :cascade do |t|
    t.string "to_state", null: false
    t.json "metadata", default: {}
    t.integer "sort_key", null: false
    t.integer "taikai_id", null: false
    t.boolean "most_recent", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["taikai_id", "most_recent"], name: "index_taikai_transitions_parent_most_recent", unique: true, where: "most_recent"
    t.index ["taikai_id", "sort_key"], name: "index_taikai_transitions_parent_sort", unique: true
  end

  create_table "taikais", force: :cascade do |t|
    t.string "shortname"
    t.string "name"
    t.text "description"
    t.date "start_date"
    t.date "end_date"
    t.boolean "distributed", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "num_targets", limit: 2, default: 6, null: false
    t.integer "total_num_arrows", limit: 2, default: 12, null: false
    t.integer "tachi_size", limit: 2, default: 3, null: false
    t.enum "form", enum_type: "taikai_form"
    t.enum "scoring", default: "kinteki", enum_type: "taikai_scoring"
    t.index ["form"], name: "taikais_by_form"
    t.index ["scoring"], name: "taikais_by_scoring"
    t.index ["shortname"], name: "by_taikais_shortname", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.integer "index"
    t.string "shortname", null: false
    t.bigint "participating_dojo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "mixed", default: false, null: false
    t.integer "rank"
    t.integer "intermediate_rank"
    t.index ["participating_dojo_id", "index"], name: "teams_by_participating_dojo_index", unique: true
    t.index ["participating_dojo_id", "shortname"], name: "by_teams_shortname", unique: true
    t.index ["participating_dojo_id"], name: "index_teams_on_participating_dojo_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "firstname"
    t.string "lastname"
    t.boolean "admin", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "matches", "taikais"
  add_foreign_key "matches", "teams", column: "team1_id"
  add_foreign_key "matches", "teams", column: "team2_id"
  add_foreign_key "participants", "kyudojins"
  add_foreign_key "participants", "participating_dojos"
  add_foreign_key "participants", "teams"
  add_foreign_key "participating_dojos", "dojos"
  add_foreign_key "participating_dojos", "taikais"
  add_foreign_key "results", "matches"
  add_foreign_key "results", "scores"
  add_foreign_key "scores", "matches"
  add_foreign_key "scores", "participants"
  add_foreign_key "scores", "teams"
  add_foreign_key "staffs", "participating_dojos"
  add_foreign_key "staffs", "staff_roles", column: "role_id"
  add_foreign_key "staffs", "taikais"
  add_foreign_key "staffs", "users"
  add_foreign_key "taikai_transitions", "taikais"
  add_foreign_key "teams", "participating_dojos"
end
