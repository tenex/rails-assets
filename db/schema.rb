# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160218022010) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "components", force: :cascade do |t|
    t.string   "name",        index: {name: "index_components_on_name", unique: true}
    t.text     "description"
    t.string   "homepage"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bower_name"
  end

  create_table "failed_jobs", force: :cascade do |t|
    t.string   "name",       index: {name: "index_failed_jobs_on_name"}
    t.string   "worker"
    t.text     "args"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "versions", force: :cascade do |t|
    t.integer  "component_id",  index: {name: "index_versions_on_component_id"}, foreign_key: {references: "components", name: "fk_versions_component_id", on_update: :no_action, on_delete: :no_action}
    t.string   "string",        index: {name: "index_versions_on_string"}
    t.hstore   "dependencies"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "build_status",  index: {name: "index_versions_on_build_status"}
    t.text     "build_message"
    t.text     "asset_paths",   default: [],    array: true
    t.text     "main_paths",    default: [],    array: true
    t.boolean  "rebuild",       default: false, index: {name: "index_versions_on_rebuild"}
    t.string   "bower_version", index: {name: "index_versions_on_bower_version"}
    t.string   "position",      limit: 1023, index: {name: "index_versions_on_position"}
    t.boolean  "prerelease",    default: false, index: {name: "index_versions_on_prerelease"}
  end

end
