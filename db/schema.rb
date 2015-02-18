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

ActiveRecord::Schema.define(version: 20150218105340) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "components", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "homepage"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bower_name"
    t.index ["name"], :name => "index_components_on_name", :unique => true, :order => {"name" => :asc}
  end

  create_table "failed_jobs", force: true do |t|
    t.string   "name"
    t.string   "worker"
    t.text     "args"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], :name => "index_failed_jobs_on_name", :order => {"name" => :asc}
  end

  create_table "versions", force: true do |t|
    t.integer  "component_id"
    t.string   "string"
    t.hstore   "dependencies"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "build_status"
    t.text     "build_message"
    t.text     "asset_paths",                default: [],    array: true
    t.text     "main_paths",                 default: [],    array: true
    t.boolean  "rebuild",                    default: false
    t.string   "bower_version"
    t.string   "position",      limit: 1023
    t.boolean  "prerelease",                 default: false
    t.index ["component_id"], :name => "fk__versions_component_id", :order => {"component_id" => :asc}
    t.index ["bower_version"], :name => "index_versions_on_bower_version", :order => {"bower_version" => :asc}
    t.index ["build_status"], :name => "index_versions_on_build_status", :order => {"build_status" => :asc}
    t.index ["component_id"], :name => "index_versions_on_component_id", :order => {"component_id" => :asc}
    t.index ["position"], :name => "index_versions_on_position", :order => {"position" => :asc}
    t.index ["prerelease"], :name => "index_versions_on_prerelease", :order => {"prerelease" => :asc}
    t.index ["rebuild"], :name => "index_versions_on_rebuild", :order => {"rebuild" => :asc}
    t.index ["string"], :name => "index_versions_on_string", :order => {"string" => :asc}
    t.foreign_key ["component_id"], "components", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_versions_component_id"
  end

end
