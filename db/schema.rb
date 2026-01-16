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

ActiveRecord::Schema[8.1].define(version: 2026_01_16_032318) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "actors", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.bigint "github_id", null: false
    t.string "login", null: false
    t.jsonb "raw_payload"
    t.datetime "updated_at", null: false
    t.index ["github_id"], name: "index_actors_on_github_id", unique: true
    t.index ["login"], name: "index_actors_on_login"
  end

  create_table "push_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "before", null: false
    t.datetime "created_at", null: false
    t.datetime "enriched_at"
    t.string "github_event_id", null: false
    t.string "head", null: false
    t.bigint "push_id", null: false
    t.jsonb "raw_payload", null: false
    t.string "ref", null: false
    t.bigint "repository_id"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_push_events_on_actor_id"
    t.index ["enriched_at"], name: "index_push_events_on_enriched_at"
    t.index ["github_event_id"], name: "index_push_events_on_github_event_id", unique: true
    t.index ["push_id"], name: "index_push_events_on_push_id"
    t.index ["ref"], name: "index_push_events_on_ref"
    t.index ["repository_id"], name: "index_push_events_on_repository_id"
  end

  create_table "rate_limit_states", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.integer "remaining", default: 60, null: false
    t.datetime "resets_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint"], name: "index_rate_limit_states_on_endpoint", unique: true
  end

  create_table "repositories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "full_name", null: false
    t.bigint "github_id", null: false
    t.string "name", null: false
    t.jsonb "raw_payload"
    t.datetime "updated_at", null: false
    t.index ["full_name"], name: "index_repositories_on_full_name"
    t.index ["github_id"], name: "index_repositories_on_github_id", unique: true
  end

  add_foreign_key "push_events", "actors"
  add_foreign_key "push_events", "repositories"
end
