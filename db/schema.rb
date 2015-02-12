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

ActiveRecord::Schema.define(version: 20150206225908) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "hstore"

  create_table "changesets", force: true do |t|
    t.text     "notes"
    t.boolean  "applied"
    t.datetime "applied_at"
    t.json     "payload"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identifiers", force: true do |t|
    t.integer  "identified_entity_id",               null: false
    t.string   "identified_entity_type",             null: false
    t.string   "identifier"
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_or_updated_in_changeset_id"
    t.integer  "destroyed_in_changeset_id"
    t.integer  "version"
    t.boolean  "current"
  end

  add_index "identifiers", ["created_or_updated_in_changeset_id"], :name => "identifiers_cu_in_changeset_id_index"
  add_index "identifiers", ["current"], :name => "index_identifiers_on_current"
  add_index "identifiers", ["destroyed_in_changeset_id"], :name => "identifiers_d_in_changeset_id_index"
  add_index "identifiers", ["identified_entity_id", "identified_entity_type"], :name => "identified_entity"
  add_index "identifiers", ["identified_entity_id"], :name => "index_identifiers_on_identified_entity_id"

  create_table "operators", force: true do |t|
    t.string   "name"
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "onestop_id"
    t.spatial  "geometry",                           limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
    t.integer  "created_or_updated_in_changeset_id"
    t.integer  "destroyed_in_changeset_id"
    t.integer  "version"
    t.boolean  "current"
  end

  add_index "operators", ["created_or_updated_in_changeset_id"], :name => "operators_cu_in_changeset_id_index"
  add_index "operators", ["current"], :name => "index_operators_on_current"
  add_index "operators", ["destroyed_in_changeset_id"], :name => "operators_d_in_changeset_id_index"
  add_index "operators", ["onestop_id"], :name => "index_operators_on_onestop_id", :unique => true

  create_table "operators_serving_stop", force: true do |t|
    t.integer  "stop_id",                            null: false
    t.integer  "operator_id",                        null: false
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_or_updated_in_changeset_id"
    t.integer  "destroyed_in_changeset_id"
    t.integer  "version"
    t.boolean  "current"
  end

  add_index "operators_serving_stop", ["created_or_updated_in_changeset_id"], :name => "operators_serving_stop_cu_in_changeset_id_index"
  add_index "operators_serving_stop", ["current"], :name => "index_operators_serving_stop_on_current"
  add_index "operators_serving_stop", ["destroyed_in_changeset_id"], :name => "operators_serving_stop_d_in_changeset_id_index"
  add_index "operators_serving_stop", ["operator_id"], :name => "index_operators_serving_stop_on_operator_id"
  add_index "operators_serving_stop", ["stop_id", "operator_id"], :name => "index_operators_serving_stop_on_stop_id_and_operator_id", :unique => true
  add_index "operators_serving_stop", ["stop_id"], :name => "index_operators_serving_stop_on_stop_id"

  create_table "stops", force: true do |t|
    t.string   "onestop_id"
    t.spatial  "geometry",                           limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "created_or_updated_in_changeset_id"
    t.integer  "destroyed_in_changeset_id"
    t.integer  "version"
    t.boolean  "current"
  end

  add_index "stops", ["created_or_updated_in_changeset_id"], :name => "stops_cu_in_changeset_id_index"
  add_index "stops", ["current"], :name => "index_stops_on_current"
  add_index "stops", ["destroyed_in_changeset_id"], :name => "stops_d_in_changeset_id_index"
  add_index "stops", ["onestop_id"], :name => "index_stops_on_onestop_id"

end
