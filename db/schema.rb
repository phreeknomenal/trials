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

ActiveRecord::Schema[8.1].define(version: 2026_01_18_073959) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "conditions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_conditions_on_name", unique: true
  end

  create_table "genders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_genders_on_name", unique: true
  end

  create_table "identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_identities_on_name", unique: true
  end

  create_table "interests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_interests_on_name", unique: true
  end

  create_table "profile_conditions", force: :cascade do |t|
    t.integer "condition_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_primary", default: false
    t.integer "profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id"], name: "index_profile_conditions_on_condition_id"
    t.index ["profile_id", "condition_id"], name: "index_profile_conditions_on_profile_id_and_condition_id", unique: true
    t.index ["profile_id"], name: "index_profile_conditions_on_profile_id"
  end

  create_table "profile_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "identity_id", null: false
    t.integer "profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["identity_id"], name: "index_profile_identities_on_identity_id"
    t.index ["profile_id", "identity_id"], name: "index_profile_identities_on_profile_id_and_identity_id", unique: true
    t.index ["profile_id"], name: "index_profile_identities_on_profile_id"
  end

  create_table "profile_interests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "interest_id", null: false
    t.integer "profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["interest_id"], name: "index_profile_interests_on_interest_id"
    t.index ["profile_id", "interest_id"], name: "index_profile_interests_on_profile_id_and_interest_id", unique: true
    t.index ["profile_id"], name: "index_profile_interests_on_profile_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "birth_year"
    t.string "city"
    t.string "contact_preference"
    t.string "country", default: "US"
    t.datetime "created_at", null: false
    t.string "current_treatment"
    t.string "diagnosis_timing"
    t.string "ethnicity", default: "prefer not to say"
    t.string "first_name"
    t.integer "gender_id"
    t.string "language_preference"
    t.string "last_name"
    t.boolean "onboarded", default: false, null: false
    t.string "phone_number"
    t.boolean "prior_treatment", default: false
    t.string "pronouns"
    t.integer "race_id"
    t.string "remote_visit_preference"
    t.string "risk_tolerance"
    t.string "sex_assigned_at_birth"
    t.string "state"
    t.boolean "transportation_reliable", default: true
    t.string "trial_type_preference"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "willing_travel_miles"
    t.string "zip_code"
    t.index ["gender_id"], name: "index_profiles_on_gender_id"
    t.index ["race_id"], name: "index_profiles_on_race_id"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "races", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_races_on_name", unique: true
  end

  create_table "saved_trials", force: :cascade do |t|
    t.date "completion_date"
    t.datetime "created_at", null: false
    t.integer "enrollment_count"
    t.decimal "match_score", precision: 5, scale: 2
    t.integer "max_age"
    t.integer "min_age"
    t.string "nct_id", null: false
    t.string "phase"
    t.string "sponsor"
    t.date "start_date"
    t.string "status", default: "interested", null: false
    t.string "study_type"
    t.text "summary"
    t.string "tags"
    t.string "trial_status"
    t.string "trial_title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_saved_trials_on_created_at"
    t.index ["status"], name: "index_saved_trials_on_status"
    t.index ["user_id", "nct_id"], name: "index_saved_trials_on_user_and_nct", unique: true
    t.index ["user_id"], name: "index_saved_trials_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "profile_conditions", "conditions"
  add_foreign_key "profile_conditions", "profiles"
  add_foreign_key "profile_identities", "identities"
  add_foreign_key "profile_identities", "profiles"
  add_foreign_key "profile_interests", "interests"
  add_foreign_key "profile_interests", "profiles"
  add_foreign_key "profiles", "genders"
  add_foreign_key "profiles", "races"
  add_foreign_key "profiles", "users"
  add_foreign_key "saved_trials", "users"
end
