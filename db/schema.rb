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

ActiveRecord::Schema.define(version: 20141031233950) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "hstore"

  create_table "stop_identifiers", force: true do |t|
    t.integer  "stop_id"
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
