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

ActiveRecord::Schema.define(version: 20141208264720) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "hstore"

  create_table "feed_import_errors", force: true do |t|
    t.integer  "feed_import_id"
    t.string   "error_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feed_import_errors", ["feed_import_id"], :name => "index_feed_import_errors_on_feed_import_id"

  create_table "feed_imports", force: true do |t|
    t.integer  "feed_id"
    t.boolean  "successful_fetch"
    t.boolean  "successful_import"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.string   "file_fingerprint"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feed_imports", ["feed_id"], :name => "index_feed_imports_on_feed_id"

  create_table "feeds", force: true do |t|
    t.string   "url"
    t.string   "feed_format"
    t.datetime "last_fetched_at"
    t.datetime "last_imported_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identifiers", force: true do |t|
    t.integer  "identified_entity_id",   null: false
    t.string   "identified_entity_type", null: false
    t.string   "identifier"
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "identifiers", ["identified_entity_id", "identified_entity_type"], :name => "identified_entity"
  add_index "identifiers", ["identified_entity_id"], :name => "index_identifiers_on_identified_entity_id"

  create_table "operators", force: true do |t|
    t.string   "name"
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "onestop_id"
    t.spatial  "geometry",   limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
  end

  add_index "operators", ["onestop_id"], :name => "index_operators_on_onestop_id", :unique => true

  create_table "operators_in_feed", force: true do |t|
    t.integer  "feed_id"
    t.integer  "operator_id"
    t.string   "onestop_id"
    t.string   "gtfs_agency_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "operators_in_feed", ["feed_id"], :name => "index_operators_in_feed_on_feed_id"
  add_index "operators_in_feed", ["operator_id"], :name => "index_operators_in_feed_on_operator_id"

  create_table "operators_serving_stop", force: true do |t|
    t.integer  "stop_id",     null: false
    t.integer  "operator_id", null: false
    t.hstore   "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "operators_serving_stop", ["operator_id"], :name => "index_operators_serving_stop_on_operator_id"
  add_index "operators_serving_stop", ["stop_id", "operator_id"], :name => "index_operators_serving_stop_on_stop_id_and_operator_id", :unique => true
  add_index "operators_serving_stop", ["stop_id"], :name => "index_operators_serving_stop_on_stop_id"

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
