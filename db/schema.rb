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

ActiveRecord::Schema.define(version: 20141202182820) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "hstore"

  create_table "operator_serving_stops", force: true do |t|
    t.integer  "stop_id",     null: false
    t.integer  "operator_id", null: false
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "operator_serving_stops", ["operator_id"], :name => "index_operator_serving_stops_on_operator_id"
  add_index "operator_serving_stops", ["stop_id", "operator_id"], :name => "index_operator_serving_stops_on_stop_id_and_operator_id", :unique => true
  add_index "operator_serving_stops", ["stop_id"], :name => "index_operator_serving_stops_on_stop_id"

  create_table "operators", force: true do |t|
    t.string   "name"
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "onestop_id"
    t.spatial  "geometry",   limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
  end

  add_index "operators", ["onestop_id"], :name => "index_operators_on_onestop_id", :unique => true

  create_table "stop_identifiers", force: true do |t|
    t.integer  "stop_id",    null: false
    t.string   "identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "tags"
  end

  add_index "stop_identifiers", ["stop_id"], :name => "index_stop_identifiers_on_stop_id"

  create_table "stops", force: true do |t|
    t.string   "onestop_id"
    t.spatial  "geometry",   limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "stops", ["onestop_id"], :name => "index_stops_on_onestop_id"

end
