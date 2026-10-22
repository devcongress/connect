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

ActiveRecord::Schema[8.1].define(version: 2026_10_24_110000) do
  create_table "active_shrine_attachments", force: :cascade do |t|
    t.string "record_type"
    t.bigint "record_id"
    t.string "name", null: false
    t.string "type", default: "ActiveShrine::Attachment", null: false
    t.json "file_data", null: false
    t.json "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_data"], name: "index_active_shrine_attachments_on_file_data"
    t.index ["metadata"], name: "index_active_shrine_attachments_on_metadata"
    t.index ["name"], name: "index_active_shrine_attachments_on_name"
    t.index ["record_type", "record_id"], name: "index_active_shrine_attachments_on_record"
  end

  create_table "admin_active_session_keys", primary_key: ["admin_id", "session_id"], force: :cascade do |t|
    t.integer "admin_id"
    t.string "session_id"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "last_use", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["admin_id"], name: "index_admin_active_session_keys_on_admin_id"
  end

  create_table "admin_authentication_audit_logs", force: :cascade do |t|
    t.integer "admin_id", null: false
    t.datetime "at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "message", null: false
    t.json "metadata"
    t.index ["admin_id", "at"], name: "audit_admin_admin_id_at_idx"
    t.index ["admin_id"], name: "index_admin_authentication_audit_logs_on_admin_id"
    t.index ["at"], name: "audit_admin_at_idx"
  end

  create_table "admin_lockouts", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent"
  end

  create_table "admin_login_failures", force: :cascade do |t|
    t.integer "number", default: 1, null: false
  end

  create_table "admin_otp_keys", force: :cascade do |t|
    t.string "key", null: false
    t.integer "num_failures", default: 0, null: false
    t.datetime "last_use", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "admin_password_reset_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "admin_recovery_codes", primary_key: ["id", "code"], force: :cascade do |t|
    t.bigint "id"
    t.string "code"
  end

  create_table "admin_remember_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
  end

  create_table "admin_verification_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "admins", force: :cascade do |t|
    t.integer "status", default: 1, null: false
    t.string "email", null: false
    t.string "password_hash"
    t.integer "role", default: 0, null: false
    t.index ["email"], name: "index_admins_on_email", unique: true, where: "status IN (1, 2)"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "website"
    t.text "description"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "jobs_trusted_at"
    t.integer "personal_owner_id"
    t.string "tagline"
    t.string "organization_type"
    t.string "industry"
    t.integer "founded_year"
    t.string "github_url"
    t.string "linkedin_url"
    t.string "x_url"
    t.index ["name"], name: "index_companies_on_name", unique: true
    t.index ["personal_owner_id"], name: "index_companies_on_personal_owner_id", unique: true
    t.index ["slug"], name: "index_companies_on_slug", unique: true
  end

  create_table "company_user_invites", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "email", null: false
    t.text "token", null: false
    t.integer "role", default: 0, null: false
    t.integer "state", default: 0, null: false
    t.datetime "expires_at"
    t.datetime "accepted_at"
    t.string "invited_by_type", null: false
    t.integer "invited_by_id", null: false
    t.integer "user_id"
    t.string "invitable_type"
    t.integer "invitable_id"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "email"], name: "index_company_user_invites_on_entity_email_pending", unique: true, where: "state = 0"
    t.index ["company_id"], name: "index_company_user_invites_on_company_id"
    t.index ["invitable_type", "invitable_id"], name: "index_company_user_invites_on_invitable"
    t.index ["invitable_type", "invitable_id"], name: "index_company_user_invites_on_invitable_pending", unique: true, where: "state = 0 AND invitable_id IS NOT NULL"
    t.index ["invited_by_type", "invited_by_id"], name: "index_company_user_invites_on_invited_by"
    t.index ["token"], name: "index_company_user_invites_on_token", unique: true
    t.index ["user_id"], name: "index_company_user_invites_on_user_id"
  end

  create_table "company_users", force: :cascade do |t|
    t.integer "company_id", null: false
    t.integer "user_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "user_id"], name: "index_company_users_on_company_id_and_user_id", unique: true
    t.index ["company_id"], name: "index_company_users_on_company_id"
    t.index ["user_id"], name: "index_company_users_on_user_id"
  end

  create_table "developers_experience_skills", force: :cascade do |t|
    t.integer "experience_id", null: false
    t.integer "profile_skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["experience_id", "profile_skill_id"], name: "idx_on_experience_id_profile_skill_id_491a95c723", unique: true
    t.index ["profile_skill_id"], name: "index_developers_experience_skills_on_profile_skill_id"
  end

  create_table "developers_experiences", force: :cascade do |t|
    t.integer "profile_id", null: false
    t.integer "company_id"
    t.string "company_name", null: false
    t.string "title", null: false
    t.string "location"
    t.date "started_on", null: false
    t.date "ended_on"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_developers_experiences_on_company_id"
    t.index ["profile_id"], name: "index_developers_experiences_on_profile_id"
  end

  create_table "developers_profile_skills", force: :cascade do |t|
    t.integer "profile_id", null: false
    t.integer "skill_id", null: false
    t.integer "level"
    t.integer "years"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "endorsements_count", default: 0, null: false
    t.index ["profile_id"], name: "index_developers_profile_skills_on_profile_id"
    t.index ["skill_id", "profile_id"], name: "index_developers_profile_skills_on_skill_id_and_profile_id", unique: true
  end

  create_table "developers_profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "handle", null: false
    t.string "name", null: false
    t.string "headline"
    t.text "bio"
    t.string "city"
    t.string "region"
    t.string "country"
    t.string "timezone"
    t.boolean "remote_ok", default: true, null: false
    t.boolean "open_to_relocation", default: false, null: false
    t.string "contact_email"
    t.string "phone"
    t.string "website_url"
    t.string "github_url"
    t.string "linkedin_url"
    t.string "x_url"
    t.integer "availability", default: 1, null: false
    t.integer "seniority"
    t.integer "years_experience"
    t.integer "contact_visibility", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 1, null: false
    t.string "first_name", null: false
    t.string "other_names"
    t.index ["country"], name: "index_developers_profiles_on_country"
    t.index ["handle"], name: "index_developers_profiles_on_handle", unique: true
    t.index ["user_id"], name: "index_developers_profiles_on_user_id", unique: true
    t.index ["visibility", "availability"], name: "index_developers_profiles_on_visibility_and_availability"
  end

  create_table "hiring_application_notes", force: :cascade do |t|
    t.integer "job_application_id", null: false
    t.integer "author_id"
    t.integer "kind", default: 0, null: false
    t.text "body"
    t.string "from_status"
    t.string "to_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_hiring_application_notes_on_author_id"
    t.index ["job_application_id", "created_at"], name: "idx_on_job_application_id_created_at_e70a1b5944"
    t.index ["job_application_id"], name: "index_hiring_application_notes_on_job_application_id"
  end

  create_table "hiring_job_applications", force: :cascade do |t|
    t.integer "job_post_id", null: false
    t.integer "profile_id", null: false
    t.text "cover_note"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "position", precision: 16, scale: 8
    t.integer "rating"
    t.datetime "status_changed_at"
    t.index ["job_post_id", "profile_id"], name: "index_hiring_job_applications_on_job_post_id_and_profile_id", unique: true
    t.index ["job_post_id"], name: "index_hiring_job_applications_on_job_post_id"
    t.index ["profile_id"], name: "index_hiring_job_applications_on_profile_id"
    t.index ["status", "position"], name: "index_hiring_job_applications_on_status_and_position"
  end

  create_table "hiring_job_posts", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.integer "employment_type", default: 0, null: false
    t.integer "seniority"
    t.integer "salary_min"
    t.integer "salary_max"
    t.string "salary_currency", default: "USD", null: false
    t.boolean "remote_ok", default: false, null: false
    t.string "city"
    t.string "country"
    t.string "apply_url"
    t.boolean "accepts_applications", default: true, null: false
    t.datetime "published_at"
    t.datetime "expires_at"
    t.datetime "filled_at"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 2, null: false
    t.datetime "approved_at"
    t.integer "pay_period", default: 0, null: false
    t.boolean "paid", default: true, null: false
    t.string "duration"
    t.date "starts_on"
    t.string "slack_message_ts"
    t.string "slack_message_url"
    t.string "slack_posted_status"
    t.index ["company_id"], name: "index_hiring_job_posts_on_company_id"
    t.index ["published_at", "expires_at"], name: "index_hiring_job_posts_on_published_at_and_expires_at"
  end

  create_table "network_endorsements", force: :cascade do |t|
    t.integer "endorser_id", null: false
    t.integer "profile_skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endorser_id"], name: "index_network_endorsements_on_endorser_id"
    t.index ["profile_skill_id", "endorser_id"], name: "index_network_endorsements_on_profile_skill_id_and_endorser_id", unique: true
  end

  create_table "network_follows", force: :cascade do |t|
    t.integer "follower_id", null: false
    t.integer "followee_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followee_id"], name: "index_network_follows_on_followee_id"
    t.index ["follower_id", "followee_id"], name: "index_network_follows_on_follower_id_and_followee_id", unique: true
    t.check_constraint "follower_id <> followee_id", name: "network_follows_not_self"
  end

  create_table "notification_opt_outs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "channel", default: "email", null: false
    t.index ["user_id", "channel", "category"], name: "idx_on_user_id_channel_category_b4bf89541d", unique: true
  end

  create_table "showcase_project_contributors", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "profile_id", null: false
    t.string "role"
    t.integer "status", default: 0, null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_showcase_project_contributors_on_profile_id"
    t.index ["project_id", "profile_id"], name: "idx_on_project_id_profile_id_42ba9b7f27", unique: true
  end

  create_table "showcase_project_skills", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "skill_id"], name: "index_showcase_project_skills_on_project_id_and_skill_id", unique: true
    t.index ["skill_id"], name: "index_showcase_project_skills_on_skill_id"
  end

  create_table "showcase_projects", force: :cascade do |t|
    t.integer "owner_id", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.string "summary"
    t.text "body"
    t.string "repo_url"
    t.string "demo_url"
    t.date "started_on"
    t.date "ended_on"
    t.integer "visibility", default: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_showcase_projects_on_owner_id"
    t.index ["slug"], name: "index_showcase_projects_on_slug", unique: true
    t.index ["visibility", "updated_at"], name: "index_showcase_projects_on_visibility_and_updated_at"
  end

  create_table "skills", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.text "description"
    t.string "website_url"
    t.string "source_url"
    t.text "why_description"
    t.json "company_examples", default: [], null: false
    t.boolean "content_curated", default: false, null: false
    t.index ["category"], name: "index_skills_on_category"
    t.index ["content_curated"], name: "index_skills_on_content_curated"
    t.index ["name"], name: "index_skills_on_name", unique: true
    t.index ["slug"], name: "index_skills_on_slug", unique: true
  end

  create_table "user_identities", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.json "info", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_user_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_user_identities_on_user_id"
  end

  create_table "user_login_change_keys", force: :cascade do |t|
    t.string "key", null: false
    t.string "login", null: false
    t.datetime "deadline", null: false
  end

  create_table "user_password_reset_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_remember_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
  end

  create_table "user_verification_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "users", force: :cascade do |t|
    t.integer "status", default: 1, null: false
    t.string "email", null: false
    t.string "password_hash"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "status IN (1, 2)"
  end

  add_foreign_key "admin_active_session_keys", "admins"
  add_foreign_key "admin_authentication_audit_logs", "admins"
  add_foreign_key "admin_lockouts", "admins", column: "id"
  add_foreign_key "admin_login_failures", "admins", column: "id"
  add_foreign_key "admin_otp_keys", "admins", column: "id"
  add_foreign_key "admin_password_reset_keys", "admins", column: "id"
  add_foreign_key "admin_recovery_codes", "admins", column: "id"
  add_foreign_key "admin_remember_keys", "admins", column: "id"
  add_foreign_key "admin_verification_keys", "admins", column: "id"
  add_foreign_key "companies", "users", column: "personal_owner_id", on_delete: :cascade
  add_foreign_key "company_user_invites", "companies"
  add_foreign_key "company_user_invites", "users"
  add_foreign_key "company_users", "companies"
  add_foreign_key "company_users", "users"
  add_foreign_key "developers_experience_skills", "developers_experiences", column: "experience_id", on_delete: :cascade
  add_foreign_key "developers_experience_skills", "developers_profile_skills", column: "profile_skill_id", on_delete: :cascade
  add_foreign_key "developers_experiences", "companies"
  add_foreign_key "developers_experiences", "developers_profiles", column: "profile_id"
  add_foreign_key "developers_profile_skills", "developers_profiles", column: "profile_id"
  add_foreign_key "developers_profile_skills", "skills"
  add_foreign_key "developers_profiles", "users"
  add_foreign_key "hiring_application_notes", "hiring_job_applications", column: "job_application_id", on_delete: :cascade
  add_foreign_key "hiring_application_notes", "users", column: "author_id", on_delete: :nullify
  add_foreign_key "hiring_job_applications", "developers_profiles", column: "profile_id"
  add_foreign_key "hiring_job_applications", "hiring_job_posts", column: "job_post_id"
  add_foreign_key "hiring_job_posts", "companies"
  add_foreign_key "network_endorsements", "developers_profile_skills", column: "profile_skill_id", on_delete: :cascade
  add_foreign_key "network_endorsements", "developers_profiles", column: "endorser_id", on_delete: :cascade
  add_foreign_key "network_follows", "developers_profiles", column: "followee_id", on_delete: :cascade
  add_foreign_key "network_follows", "developers_profiles", column: "follower_id", on_delete: :cascade
  add_foreign_key "notification_opt_outs", "users"
  add_foreign_key "showcase_project_contributors", "developers_profiles", column: "profile_id", on_delete: :cascade
  add_foreign_key "showcase_project_contributors", "showcase_projects", column: "project_id", on_delete: :cascade
  add_foreign_key "showcase_project_skills", "showcase_projects", column: "project_id", on_delete: :cascade
  add_foreign_key "showcase_project_skills", "skills"
  add_foreign_key "showcase_projects", "developers_profiles", column: "owner_id", on_delete: :cascade
  add_foreign_key "user_identities", "users", on_delete: :cascade
  add_foreign_key "user_login_change_keys", "users", column: "id"
  add_foreign_key "user_password_reset_keys", "users", column: "id"
  add_foreign_key "user_remember_keys", "users", column: "id"
  add_foreign_key "user_verification_keys", "users", column: "id"
end
