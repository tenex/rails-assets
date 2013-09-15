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

ActiveRecord::Schema.define(version: 20130915142527) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id", :order => {"author_type" => :asc, "author_id" => :asc}
    t.index ["namespace"], :name => "index_active_admin_comments_on_namespace", :order => {"namespace" => :asc}
    t.index ["resource_type", "resource_id"], :name => "index_active_admin_comments_on_resource_type_and_resource_id", :order => {"resource_type" => :asc, "resource_id" => :asc}
  end

  create_table "admin_users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["email"], :name => "index_admin_users_on_email", :unique => true, :order => {"email" => :asc}
    t.index ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true, :order => {"reset_password_token" => :asc}
  end

  create_table "components", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "homepage"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], :name => "index_components_on_name", :unique => true, :order => {"name" => :asc}
  end

  create_table "versions", force: true do |t|
    t.integer  "component_id"
    t.string   "string"
    t.hstore   "dependencies"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["component_id"], :name => "fk__versions_component_id", :order => {"component_id" => :asc}
    t.index ["component_id"], :name => "index_versions_on_component_id", :order => {"component_id" => :asc}
    t.index ["string"], :name => "index_versions_on_string", :order => {"string" => :asc}
    t.foreign_key ["component_id"], "components", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_versions_component_id"
  end

end
