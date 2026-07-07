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

ActiveRecord::Schema[8.1].define(version: 2026_07_07_120002) do
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

  create_table "article_tags", force: :cascade do |t|
    t.integer "article_id", null: false
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "tag_id"], name: "index_article_tags_on_article_id_and_tag_id", unique: true
    t.index ["article_id"], name: "index_article_tags_on_article_id"
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_articles_on_author_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "feedback_submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["feedback_submission_id"], name: "index_comments_on_feedback_submission_id"
  end

  create_table "feedback_submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "csr_name"
    t.json "data", default: {}, null: false
    t.integer "feedback_template_id", null: false
    t.string "feedback_type"
    t.string "priority"
    t.string "status", default: "open", null: false
    t.string "submitted_by"
    t.integer "submitter_id"
    t.string "ticket_number"
    t.datetime "updated_at", null: false
    t.index ["csr_name"], name: "index_feedback_submissions_on_csr_name"
    t.index ["feedback_template_id"], name: "index_feedback_submissions_on_feedback_template_id"
    t.index ["feedback_type"], name: "index_feedback_submissions_on_feedback_type"
    t.index ["priority"], name: "index_feedback_submissions_on_priority"
    t.index ["status"], name: "index_feedback_submissions_on_status"
    t.index ["submitted_by"], name: "index_feedback_submissions_on_submitted_by"
    t.index ["submitter_id"], name: "index_feedback_submissions_on_submitter_id"
    t.index ["ticket_number"], name: "index_feedback_submissions_on_ticket_number"
  end

  create_table "feedback_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "feedback_submission_id", null: false
    t.boolean "subscribed", default: true, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["feedback_submission_id", "user_id"], name: "idx_on_feedback_submission_id_user_id_68c80a419d", unique: true
    t.index ["feedback_submission_id"], name: "index_feedback_subscriptions_on_feedback_submission_id"
    t.index ["user_id"], name: "index_feedback_subscriptions_on_user_id"
  end

  create_table "feedback_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "field_schema", default: [], null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_feedback_templates_on_name", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.string "event_type", null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_type", "event_id"], name: "index_notifications_on_event_type_and_event_id"
    t.index ["user_id", "event_type", "event_id"], name: "index_notifications_on_user_id_and_event_type_and_event_id", unique: true
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "status_changes", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.integer "feedback_submission_id", null: false
    t.string "from_status", null: false
    t.text "note"
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_status_changes_on_actor_id"
    t.index ["feedback_submission_id"], name: "index_status_changes_on_feedback_submission_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "team_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "csr_name", null: false
    t.integer "manager_id", null: false
    t.datetime "updated_at", null: false
    t.index ["manager_id", "csr_name"], name: "index_team_memberships_on_manager_id_and_csr_name", unique: true
    t.index ["manager_id"], name: "index_team_memberships_on_manager_id"
  end

  create_table "updates", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_updates_on_author_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "last_digest_sent_at"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "articles", "users", column: "author_id"
  add_foreign_key "comments", "feedback_submissions"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "feedback_submissions", "feedback_templates"
  add_foreign_key "feedback_submissions", "users", column: "submitter_id"
  add_foreign_key "feedback_subscriptions", "feedback_submissions"
  add_foreign_key "feedback_subscriptions", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "status_changes", "feedback_submissions"
  add_foreign_key "status_changes", "users", column: "actor_id"
  add_foreign_key "team_memberships", "users", column: "manager_id"
  add_foreign_key "updates", "users", column: "author_id"
end
