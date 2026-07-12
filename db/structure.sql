CREATE TABLE "action_text_rich_texts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "body" text, "created_at" datetime(6) NOT NULL, "name" varchar NOT NULL, "record_id" bigint NOT NULL, "record_type" varchar NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_action_text_rich_texts_uniqueness" ON "action_text_rich_texts" ("record_type", "record_id", "name") /*application='Feedbackhub'*/;
CREATE TABLE "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "content_type" varchar, "created_at" datetime(6) NOT NULL, "filename" varchar NOT NULL, "key" varchar NOT NULL, "metadata" text, "service_name" varchar NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='Feedbackhub'*/;
CREATE TABLE "feedback_templates" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "field_schema" json DEFAULT '[]' NOT NULL, "name" varchar NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_feedback_templates_on_name" ON "feedback_templates" ("name") /*application='Feedbackhub'*/;
CREATE TABLE "tags" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "name" varchar NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_tags_on_name" ON "tags" ("name") /*application='Feedbackhub'*/;
CREATE TABLE "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "email" varchar NOT NULL, "name" varchar NOT NULL, "password_digest" varchar NOT NULL, "role" varchar DEFAULT 'user' NOT NULL, "updated_at" datetime(6) NOT NULL, "last_digest_sent_at" datetime(6) /*application='Feedbackhub'*/);
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email") /*application='Feedbackhub'*/;
CREATE TABLE "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "name" varchar NOT NULL, "record_id" bigint NOT NULL, "record_type" varchar NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='Feedbackhub'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='Feedbackhub'*/;
CREATE TABLE "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='Feedbackhub'*/;
CREATE TABLE "article_tags" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "article_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "tag_id" integer NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_646e8d3122"
FOREIGN KEY ("article_id")
  REFERENCES "articles" ("id")
, CONSTRAINT "fk_rails_b651172c61"
FOREIGN KEY ("tag_id")
  REFERENCES "tags" ("id")
);
CREATE UNIQUE INDEX "index_article_tags_on_article_id_and_tag_id" ON "article_tags" ("article_id", "tag_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_article_tags_on_article_id" ON "article_tags" ("article_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_article_tags_on_tag_id" ON "article_tags" ("tag_id") /*application='Feedbackhub'*/;
CREATE TABLE "articles" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "title" varchar NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_e74ce85cbc"
FOREIGN KEY ("author_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_articles_on_author_id" ON "articles" ("author_id") /*application='Feedbackhub'*/;
CREATE TABLE "updates" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "date" date NOT NULL, "pinned" boolean DEFAULT FALSE NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_59fd684636"
FOREIGN KEY ("author_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_updates_on_author_id" ON "updates" ("author_id") /*application='Feedbackhub'*/;
CREATE TABLE "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE "team_memberships" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "manager_id" integer NOT NULL, "csr_name" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_bfc8913139"
FOREIGN KEY ("manager_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_team_memberships_on_manager_id" ON "team_memberships" ("manager_id") /*application='Feedbackhub'*/;
CREATE UNIQUE INDEX "index_team_memberships_on_manager_id_and_csr_name" ON "team_memberships" ("manager_id", "csr_name") /*application='Feedbackhub'*/;
CREATE TABLE "feedback_submissions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "csr_name" varchar, "data" json DEFAULT '{}' NOT NULL, "feedback_template_id" integer NOT NULL, "feedback_type" varchar, "priority" varchar, "submitted_by" varchar, "ticket_number" varchar, "updated_at" datetime(6) NOT NULL, "submitter_id" integer, "status" varchar DEFAULT 'open' NOT NULL /*application='Feedbackhub'*/, CONSTRAINT "fk_rails_7bad586916"
FOREIGN KEY ("feedback_template_id")
  REFERENCES "feedback_templates" ("id")
, CONSTRAINT "fk_rails_4efd9a4cf6"
FOREIGN KEY ("submitter_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_feedback_submissions_on_csr_name" ON "feedback_submissions" ("csr_name") /*application='Feedbackhub'*/;
CREATE INDEX "index_feedback_submissions_on_feedback_template_id" ON "feedback_submissions" ("feedback_template_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_feedback_submissions_on_feedback_type" ON "feedback_submissions" ("feedback_type") /*application='Feedbackhub'*/;
CREATE INDEX "index_feedback_submissions_on_priority" ON "feedback_submissions" ("priority") /*application='Feedbackhub'*/;
CREATE INDEX "index_feedback_submissions_on_submitted_by" ON "feedback_submissions" ("submitted_by") /*application='Feedbackhub'*/;
CREATE INDEX "index_feedback_submissions_on_ticket_number" ON "feedback_submissions" ("ticket_number") /*application='Feedbackhub'*/;
CREATE INDEX "index_feedback_submissions_on_submitter_id" ON "feedback_submissions" ("submitter_id") /*application='Feedbackhub'*/;
CREATE TABLE "comments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "feedback_submission_id" integer NOT NULL, "author_id" integer NOT NULL, "body" text NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_f20ddd9b1e"
FOREIGN KEY ("feedback_submission_id")
  REFERENCES "feedback_submissions" ("id")
, CONSTRAINT "fk_rails_f44b1e3c8a"
FOREIGN KEY ("author_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_comments_on_feedback_submission_id" ON "comments" ("feedback_submission_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_comments_on_author_id" ON "comments" ("author_id") /*application='Feedbackhub'*/;
CREATE TABLE "feedback_subscriptions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "feedback_submission_id" integer NOT NULL, "user_id" integer NOT NULL, "subscribed" boolean DEFAULT TRUE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_7c9d3b7262"
FOREIGN KEY ("feedback_submission_id")
  REFERENCES "feedback_submissions" ("id")
, CONSTRAINT "fk_rails_9276146b5b"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_feedback_subscriptions_on_feedback_submission_id" ON "feedback_subscriptions" ("feedback_submission_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_feedback_subscriptions_on_user_id" ON "feedback_subscriptions" ("user_id") /*application='Feedbackhub'*/;
CREATE UNIQUE INDEX "idx_on_feedback_submission_id_user_id_68c80a419d" ON "feedback_subscriptions" ("feedback_submission_id", "user_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_feedback_submissions_on_status" ON "feedback_submissions" ("status") /*application='Feedbackhub'*/;
CREATE TABLE "status_changes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "feedback_submission_id" integer NOT NULL, "actor_id" integer NOT NULL, "from_status" varchar NOT NULL, "to_status" varchar NOT NULL, "note" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_6de89eef59"
FOREIGN KEY ("feedback_submission_id")
  REFERENCES "feedback_submissions" ("id")
, CONSTRAINT "fk_rails_3116f85121"
FOREIGN KEY ("actor_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_status_changes_on_feedback_submission_id" ON "status_changes" ("feedback_submission_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_status_changes_on_actor_id" ON "status_changes" ("actor_id") /*application='Feedbackhub'*/;
CREATE TABLE "notifications" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "read_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "event_type" varchar NOT NULL, "event_id" integer NOT NULL, CONSTRAINT "fk_rails_b080fb4855"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_notifications_on_user_id" ON "notifications" ("user_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_notifications_on_user_id_and_read_at" ON "notifications" ("user_id", "read_at") /*application='Feedbackhub'*/;
CREATE UNIQUE INDEX "index_notifications_on_user_id_and_event_type_and_event_id" ON "notifications" ("user_id", "event_type", "event_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_notifications_on_event_type_and_event_id" ON "notifications" ("event_type", "event_id") /*application='Feedbackhub'*/;
CREATE TABLE "csrs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "active" boolean DEFAULT TRUE NOT NULL, "user_id" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_381751820d"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_csrs_on_user_id" ON "csrs" ("user_id") /*application='Feedbackhub'*/;
CREATE UNIQUE INDEX "index_csrs_on_name" ON "csrs" ("name") /*application='Feedbackhub'*/;
CREATE TABLE "search_entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "parent_type" varchar NOT NULL, "parent_id" integer NOT NULL, "unit_type" varchar NOT NULL, "unit_id" integer NOT NULL, "content" text NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_search_entries_on_unit_type_and_unit_id" ON "search_entries" ("unit_type", "unit_id") /*application='Feedbackhub'*/;
CREATE INDEX "index_search_entries_on_parent_type_and_parent_id" ON "search_entries" ("parent_type", "parent_id") /*application='Feedbackhub'*/;
CREATE VIRTUAL TABLE search_entries_fts USING fts5(
  content,
  content='search_entries',
  content_rowid='id',
  tokenize='porter unicode61'
)
/* search_entries_fts(content) */;
CREATE TABLE 'search_entries_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE 'search_entries_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE 'search_entries_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE 'search_entries_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE TRIGGER search_entries_ai AFTER INSERT ON search_entries BEGIN
  INSERT INTO search_entries_fts(rowid, content) VALUES (new.id, new.content);
END;
CREATE TRIGGER search_entries_ad AFTER DELETE ON search_entries BEGIN
  INSERT INTO search_entries_fts(search_entries_fts, rowid, content) VALUES ('delete', old.id, old.content);
END;
CREATE TRIGGER search_entries_au AFTER UPDATE ON search_entries BEGIN
  INSERT INTO search_entries_fts(search_entries_fts, rowid, content) VALUES ('delete', old.id, old.content);
  INSERT INTO search_entries_fts(rowid, content) VALUES (new.id, new.content);
END;
INSERT INTO "schema_migrations" (version) VALUES
('20260710190618'),
('20260710145708'),
('20260708130002'),
('20260708130001'),
('20260708130000'),
('20260707120002'),
('20260707120001'),
('20260707120000'),
('20260706114503'),
('20260706114502'),
('20260706114501'),
('20260706114500'),
('20260629120001'),
('20260629120000'),
('20260327021933'),
('20260327021517'),
('20260327021515'),
('20260327021514'),
('20260327021120'),
('20260327020739'),
('20260326002420'),
('20260326002419'),
('20260326002013'),
('20260326002011');

