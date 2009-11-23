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

ActiveRecord::Schema.define(:version => 20091123130053) do

  create_table "cached_postcodes", :force => true do |t|
    t.string   "code"
    t.integer  "output_area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "committees", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.integer  "council_id"
    t.string   "uid"
    t.text     "description"
    t.integer  "ward_id"
    t.string   "normalised_title"
  end

  add_index "committees", ["council_id"], :name => "index_committees_on_council_id"

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
    t.string   "data_source_url"
    t.string   "data_source_name"
    t.string   "snac_id"
    t.string   "country"
    t.integer  "population"
    t.string   "twitter_account"
    t.integer  "ldg_id"
    t.string   "os_id"
    t.integer  "parent_authority_id"
  end

  create_table "councils_copy", :force => true do |t|
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
    t.string   "data_source_url"
    t.string   "data_source_name"
    t.string   "snac_id"
  end

  create_table "datapoints", :force => true do |t|
    t.text     "data"
    t.integer  "council_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "datapoints", ["council_id"], :name => "index_datapoints_on_council_id"
  add_index "datapoints", ["dataset_id"], :name => "index_datapoints_on_dataset_id"

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

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documents", :force => true do |t|
    t.string   "title"
    t.text     "body",                :limit => 16777215
    t.string   "url"
    t.integer  "document_owner_id"
    t.string   "document_owner_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "raw_body",            :limit => 16777215
    t.string   "document_type"
  end

  add_index "documents", ["document_owner_type", "document_owner_id"], :name => "index_documents_on_document_owner_type_and_document_owner_id"

  create_table "feed_entries", :force => true do |t|
    t.string   "title"
    t.text     "summary"
    t.string   "url"
    t.datetime "published_at"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ldg_services", :force => true do |t|
    t.string   "category"
    t.integer  "lgsl"
    t.integer  "lgil"
    t.string   "service_name"
    t.string   "authority_level"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "meetings", :force => true do |t|
    t.datetime "date_held"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "committee_id"
    t.string   "uid"
    t.integer  "council_id"
    t.string   "url"
    t.text     "venue"
  end

  add_index "meetings", ["committee_id"], :name => "index_meetings_on_committee_id"
  add_index "meetings", ["council_id"], :name => "index_meetings_on_council_id"

  create_table "members", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "party"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.string   "email"
    t.string   "telephone"
    t.date     "date_elected"
    t.date     "date_left"
    t.integer  "council_id"
    t.string   "uid"
    t.string   "name_title"
    t.string   "qualifications"
    t.string   "register_of_interests"
    t.text     "address"
    t.integer  "ward_id"
  end

  add_index "members", ["council_id"], :name => "index_members_on_council_id"
  add_index "members", ["ward_id"], :name => "index_members_on_ward_id"

  create_table "memberships", :force => true do |t|
    t.integer  "member_id"
    t.integer  "committee_id"
    t.date     "date_joined"
    t.date     "date_left"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "council_id"
  end

  add_index "memberships", ["committee_id", "member_id"], :name => "index_memberships_on_committee_id_and_member_id"

  create_table "officers", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "name_title"
    t.string   "qualifications"
    t.string   "position"
    t.integer  "council_id"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ons_dataset_families", :force => true do |t|
    t.string   "title"
    t.integer  "ons_subject_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ons_uid"
  end

  create_table "ons_dataset_families_ons_subjects", :id => false, :force => true do |t|
    t.integer "ons_subject_id"
    t.integer "ons_dataset_family_id"
  end

  create_table "ons_datasets", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "ons_dataset_family_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ons_subjects", :force => true do |t|
    t.string   "title"
    t.integer  "ons_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "output_areas", :force => true do |t|
    t.string  "oa_code"
    t.string  "lsoa_code"
    t.string  "lsoa_name"
    t.integer "ward_id"
    t.string  "ward_snac_id"
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
    t.string   "referrer_url"
    t.string   "cookie_url"
  end

  create_table "services", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "category"
    t.integer  "council_id"
    t.integer  "ldg_service_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "services", ["council_id"], :name => "index_services_on_council_id"

  create_table "wards", :force => true do |t|
    t.string   "name"
    t.integer  "council_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "uid"
    t.string   "snac_id"
    t.string   "url"
    t.string   "os_id"
  end

  add_index "wards", ["council_id"], :name => "index_wards_on_council_id"

  create_table "wdtk_requests", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "status"
    t.text     "description"
    t.integer  "council_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
