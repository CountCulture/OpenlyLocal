# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090701090043) do

  create_table "committees", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.integer  "council_id"
    t.integer  "uid"
    t.text     "description"
  end

  create_table "councils", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "base_url"
    t.string   "telephone"
    t.text     "address"
    t.string   "authority_type"
    t.integer  "portal_system_id"
    t.text     "notes"
    t.string   "wikipedia_url"
    t.string   "ons_url"
    t.integer  "egr_id"
    t.string   "wdtk_name"
    t.string   "feed_url"
  end

  create_table "datapoints", :force => true do |t|
    t.text     "data"
    t.integer  "council_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datasets", :force => true do |t|
    t.string   "title"
    t.string   "key"
    t.string   "source"
    t.string   "query"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "originator"
    t.string   "originator_url"
    t.integer  "summary_column"
    t.datetime "last_checked"
  end

  create_table "documents", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.string   "url"
    t.integer  "document_owner_id"
    t.string   "document_owner_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "raw_body"
    t.string   "document_type"
  end

  create_table "meetings", :force => true do |t|
    t.datetime "date_held"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "committee_id"
    t.integer  "uid"
    t.integer  "council_id"
    t.string   "url"
    t.text     "venue"
  end

  create_table "members", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "party"
    t.string   "constituency"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.string   "email"
    t.string   "telephone"
    t.date     "date_elected"
    t.date     "date_left"
    t.integer  "council_id"
    t.integer  "uid"
    t.string   "name_title"
    t.string   "qualifications"
    t.string   "declaration_of_interests"
    t.text     "address"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "member_id"
    t.integer  "committee_id"
    t.date     "date_joined"
    t.date     "date_left"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "council_id"
  end

  create_table "parsers", :force => true do |t|
    t.string   "description"
    t.text     "item_parser"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "attribute_parser"
    t.integer  "portal_system_id"
    t.string   "result_model"
    t.string   "related_model"
    t.string   "scraper_type"
    t.string   "path"
  end

  create_table "portal_systems", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scrapers", :force => true do |t|
    t.string   "url"
    t.integer  "parser_id"
    t.integer  "council_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "expected_result_class"
    t.integer  "expected_result_size"
    t.text     "expected_result_attributes"
    t.string   "type"
    t.string   "related_model"
    t.datetime "last_scraped"
    t.boolean  "problematic",                :default => false
    t.text     "notes"
  end

end
