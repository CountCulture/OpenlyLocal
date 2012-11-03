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

ActiveRecord::Schema.define(:version => 20121023203129) do

  create_table "account_lines", :force => true do |t|
    t.integer  "value"
    t.string   "period"
    t.string   "sub_heading"
    t.integer  "classification_id"
    t.string   "organisation_type"
    t.integer  "organisation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "addresses", :force => true do |t|
    t.text     "street_address"
    t.string   "locality"
    t.string   "postal_code"
    t.string   "country"
    t.string   "addressee_type"
    t.integer  "addressee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "region"
    t.boolean  "former",         :default => false
    t.float    "lat"
    t.float    "lng"
    t.text     "raw_address"
  end

  add_index "addresses", ["addressee_id", "addressee_type"], :name => "index_addresses_on_addressee_id_and_addressee_type"
  add_index "addresses", ["lat", "lng"], :name => "index_addresses_on_lat_and_lng"

  create_table "alert_subscribers", :force => true do |t|
    t.string   "email",             :limit => 128
    t.string   "postcode_text",     :limit => 8
    t.datetime "last_sent"
    t.boolean  "confirmed"
    t.string   "confirmation_code"
    t.float    "distance"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "postcode_id"
    t.point    "geom",              :limit => nil, :srid => 4326
    t.point    "metres",            :limit => nil, :srid => 27700
  end

  add_index "alert_subscribers", ["created_at"], :name => "index_alert_subscribers_on_created_at"
  add_index "alert_subscribers", ["email"], :name => "index_alert_subscribers_on_email"
  add_index "alert_subscribers", ["geom"], :name => "index_alert_subscribers_on_geom", :spatial => true
  add_index "alert_subscribers", ["metres"], :name => "index_alert_subscribers_on_metres", :spatial => true

  create_table "boundaries", :force => true do |t|
    t.string   "area_type"
    t.integer  "area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "hectares"
    t.polygon  "boundary_line", :limit => nil, :srid => 0
  end

  add_index "boundaries", ["area_id", "area_type"], :name => "index_boundaries_on_area_id_and_area_type"

  create_table "candidates", :force => true do |t|
    t.integer  "poll_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "party"
    t.boolean  "elected"
    t.integer  "votes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "basic_address"
    t.integer  "political_party_id"
    t.integer  "member_id"
  end

  add_index "candidates", ["member_id"], :name => "index_candidates_on_member_id"
  add_index "candidates", ["political_party_id"], :name => "index_candidates_on_political_party_id"
  add_index "candidates", ["poll_id"], :name => "index_candidates_on_poll_id"

  create_table "charities", :force => true do |t|
    t.string   "title"
    t.text     "activities"
    t.string   "charity_number"
    t.string   "website"
    t.string   "email"
    t.string   "telephone"
    t.date     "date_registered"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "vat_number"
    t.string   "contact_name"
    t.date     "accounts_date"
    t.integer  "spending"
    t.integer  "income"
    t.date     "date_removed"
    t.string   "normalised_title"
    t.integer  "employees"
    t.text     "accounts"
    t.text     "financial_breakdown"
    t.text     "trustees"
    t.text     "other_names"
    t.integer  "volunteers"
    t.datetime "last_checked"
    t.string   "facebook_account_name"
    t.string   "youtube_account_name"
    t.string   "feed_url"
    t.text     "governing_document"
    t.string   "company_number"
    t.string   "housing_association_number"
    t.string   "fax"
    t.integer  "subsidiary_number"
    t.string   "area_of_benefit"
    t.boolean  "signed_up_for_1010",         :default => false
    t.string   "corrected_company_number"
    t.datetime "manually_updated"
  end

  add_index "charities", ["charity_number"], :name => "index_charities_on_charity_number", :unique => true
  add_index "charities", ["company_number"], :name => "index_charities_on_company_number"
  add_index "charities", ["corrected_company_number"], :name => "index_charities_on_normalised_company_number"
  add_index "charities", ["date_registered"], :name => "index_charities_on_date_registered"
  add_index "charities", ["income"], :name => "index_charities_on_income"
  add_index "charities", ["normalised_title"], :name => "index_charities_on_normalised_title"
  add_index "charities", ["spending"], :name => "index_charities_on_spending"
  add_index "charities", ["title"], :name => "index_charities_on_title"

  create_table "charity_annual_reports", :force => true do |t|
    t.integer  "charity_id"
    t.string   "annual_return_code"
    t.date     "financial_year_start"
    t.date     "financial_year_end"
    t.integer  "income_from_legacies"
    t.integer  "income_from_endowments"
    t.integer  "voluntary_income"
    t.integer  "activities_generating_funds"
    t.integer  "income_from_charitable_activities"
    t.integer  "investment_income"
    t.integer  "other_income"
    t.integer  "total_income"
    t.integer  "investment_gains"
    t.integer  "gains_from_asset_revaluations"
    t.integer  "gains_on_pension_fund"
    t.integer  "voluntary_income_costs"
    t.integer  "fundraising_trading_costs"
    t.integer  "investment_management_costs"
    t.integer  "grants_to_institutions"
    t.integer  "charitable_activities_costs"
    t.integer  "governance_costs"
    t.integer  "other_expenses"
    t.integer  "total_expenses"
    t.integer  "support_costs"
    t.integer  "depreciation"
    t.integer  "reserves"
    t.integer  "fixed_assets_at_start_of_year"
    t.integer  "fixed_assets_at_end_of_year"
    t.integer  "fixed_investment_assets_at_end_of_year"
    t.integer  "fixed_investment_assets_at_start_of_year"
    t.integer  "current_investment_assets"
    t.integer  "cash"
    t.integer  "total_current_assets"
    t.integer  "creditors_within_1_year"
    t.integer  "long_term_creditors_or_provisions"
    t.integer  "pension_assets"
    t.integer  "total_assets"
    t.integer  "endowment_funds"
    t.integer  "restricted_funds"
    t.integer  "unrestricted_funds"
    t.integer  "total_funds"
    t.integer  "employees"
    t.integer  "volunteers"
    t.boolean  "consolidated_accounts"
    t.boolean  "charity_only_accounts"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "charity_annual_reports", ["charity_id"], :name => "index_charity_annual_reports_on_charity_id"

  create_table "classification_links", :force => true do |t|
    t.integer "classification_id"
    t.string  "classified_type"
    t.integer "classified_id"
  end

  add_index "classification_links", ["classification_id"], :name => "index_classification_links_on_classification_id"
  add_index "classification_links", ["classified_id", "classified_type"], :name => "index_classification_links_on_classified_id_and_classified_type"

  create_table "classifications", :force => true do |t|
    t.string   "grouping"
    t.string   "title"
    t.text     "extended_title"
    t.string   "uid"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "classifications", ["grouping"], :name => "index_classifications_on_grouping"

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
  add_index "committees", ["ward_id"], :name => "index_committees_on_ward_id"

  create_table "companies", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "company_number"
    t.integer  "supplier_id"
    t.string   "normalised_title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "incorporation_date"
    t.string   "company_type"
    t.string   "wikipedia_url"
    t.string   "status"
    t.string   "vat_number"
    t.text     "previous_names"
    t.text     "sic_codes"
    t.string   "country"
  end

  add_index "companies", ["company_number"], :name => "index_companies_on_company_number"

  create_table "contracts", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "uid"
    t.string   "source_url"
    t.string   "url"
    t.integer  "organisation_id"
    t.string   "organisation_type"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "duration"
    t.integer  "total_value"
    t.integer  "annual_value"
    t.string   "supplier_name"
    t.text     "supplier_address"
    t.string   "supplier_uid"
    t.string   "department_responsible"
    t.string   "person_responsible"
    t.string   "email"
    t.string   "telephone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contracts", ["organisation_id", "organisation_type"], :name => "index_contracts_on_organisation_id_and_organisation_type"

  create_table "council_contacts", :force => true do |t|
    t.string   "name"
    t.string   "position"
    t.string   "email"
    t.integer  "council_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "approved"
  end

  add_index "council_contacts", ["council_id"], :name => "index_council_contacts_on_council_id"

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
    t.integer  "ldg_id"
    t.string   "os_id"
    t.integer  "parent_authority_id"
    t.string   "police_force_url"
    t.integer  "police_force_id"
    t.string   "ness_id"
    t.float    "lat"
    t.float    "lng"
    t.string   "cipfa_code"
    t.string   "region"
    t.boolean  "signed_up_for_1010",            :default => false
    t.integer  "pension_fund_id"
    t.string   "gss_code"
    t.string   "annual_audit_letter"
    t.integer  "output_area_classification_id"
    t.boolean  "defunkt",                       :default => false
    t.string   "open_data_url"
    t.string   "open_data_licence"
    t.string   "normalised_title"
    t.integer  "wdtk_id"
    t.string   "vat_number"
    t.string   "planning_email"
  end

  add_index "councils", ["authority_type"], :name => "index_councils_on_authority_type"
  add_index "councils", ["cipfa_code"], :name => "index_councils_on_cipfa_code"
  add_index "councils", ["normalised_title"], :name => "index_councils_on_normalised_title"
  add_index "councils", ["os_id"], :name => "index_councils_on_os_id"
  add_index "councils", ["output_area_classification_id"], :name => "index_councils_on_output_area_classification_id"
  add_index "councils", ["parent_authority_id"], :name => "index_councils_on_parent_authority_id"
  add_index "councils", ["pension_fund_id"], :name => "index_councils_on_pension_fund_id"
  add_index "councils", ["police_force_id"], :name => "index_councils_on_police_force_id"
  add_index "councils", ["portal_system_id"], :name => "index_councils_on_portal_system_id"
  add_index "councils", ["snac_id"], :name => "index_councils_on_snac_id"
  add_index "councils", ["wdtk_name"], :name => "index_councils_on_wdtk_name"

  create_table "crime_areas", :force => true do |t|
    t.string   "uid"
    t.integer  "police_force_id"
    t.string   "name"
    t.integer  "level"
    t.integer  "parent_area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "crime_mapper_url"
    t.string   "feed_url"
    t.string   "crime_level_cf_national"
    t.text     "crime_rates"
    t.text     "total_crimes"
  end

  add_index "crime_areas", ["police_force_id"], :name => "index_crime_areas_on_police_force_id"

  create_table "crime_types", :force => true do |t|
    t.string   "uid"
    t.string   "name"
    t.string   "plural_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_periods", :force => true do |t|
    t.date "start_date"
    t.date "end_date"
  end

  create_table "data_periods_dataset_families", :id => false, :force => true do |t|
    t.integer "data_period_id"
    t.integer "dataset_family_id"
  end

  create_table "datapoints", :force => true do |t|
    t.float    "value"
    t.integer  "dataset_topic_id"
    t.integer  "area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "area_type"
    t.integer  "data_period_id"
  end

  add_index "datapoints", ["area_id", "area_type"], :name => "index_datapoints_on_area_id_and_area_type"
  add_index "datapoints", ["dataset_topic_id"], :name => "index_ons_datapoints_on_ons_dataset_topic_id"

  create_table "dataset_families", :force => true do |t|
    t.string   "title"
    t.integer  "ons_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source_type"
    t.integer  "dataset_id"
    t.string   "calculation_method"
  end

  add_index "dataset_families", ["dataset_id"], :name => "index_dataset_families_on_dataset_id"

  create_table "dataset_families_ons_subjects", :id => false, :force => true do |t|
    t.integer "ons_subject_id"
    t.integer "dataset_family_id"
  end

  add_index "dataset_families_ons_subjects", ["dataset_family_id", "ons_subject_id"], :name => "ons_subjects_families_join_index"
  add_index "dataset_families_ons_subjects", ["ons_subject_id", "dataset_family_id"], :name => "ons_families_subjects_join_index"

  create_table "dataset_topic_groupings", :force => true do |t|
    t.string   "title"
    t.string   "display_as"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sort_by"
  end

  create_table "dataset_topics", :force => true do |t|
    t.string   "title"
    t.integer  "ons_uid"
    t.integer  "dataset_family_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "muid"
    t.text     "description"
    t.date     "data_date"
    t.string   "short_title"
    t.integer  "dataset_topic_grouping_id"
  end

  add_index "dataset_topics", ["dataset_family_id"], :name => "index_ons_dataset_topics_on_ons_dataset_family_id"
  add_index "dataset_topics", ["dataset_topic_grouping_id"], :name => "index_dataset_topics_on_dataset_topic_grouping_id"
  add_index "dataset_topics", ["ons_uid"], :name => "index_dataset_topics_on_ons_uid"

  create_table "datasets", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "url"
    t.string   "originator"
    t.string   "originator_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dataset_topic_grouping_id"
    t.text     "notes"
    t.string   "licence"
  end

  add_index "datasets", ["dataset_topic_grouping_id"], :name => "index_datasets_on_dataset_topic_grouping_id"

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

  add_index "delayed_jobs", ["priority", "run_at"], :name => "index_delayed_jobs_on_priority_and_run_at"

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
    t.text     "precis"
  end

  add_index "documents", ["document_owner_id", "document_owner_type"], :name => "index_documents_on_document_owner_id_and_document_owner_type"

  create_table "entities", :force => true do |t|
    t.string   "title"
    t.string   "entity_type"
    t.string   "entity_subtype"
    t.string   "website"
    t.string   "wikipedia_url"
    t.string   "sponsoring_organisation"
    t.string   "wdtk_name"
    t.text     "previous_names"
    t.date     "setup_on"
    t.date     "disbanded_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "vat_number"
    t.string   "cpid_code"
    t.string   "normalised_title"
    t.text     "other_attributes"
    t.string   "external_resource_uri"
    t.string   "telephone"
  end

  add_index "entities", ["title"], :name => "index_entities_on_title"
  add_index "entities", ["wdtk_name"], :name => "index_entities_on_wdtk_name"

  create_table "feed_entries", :force => true do |t|
    t.string   "title"
    t.text     "summary"
    t.string   "url"
    t.datetime "published_at"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "feed_owner_type"
    t.integer  "feed_owner_id"
    t.float    "lat"
    t.float    "lng"
  end

  add_index "feed_entries", ["feed_owner_id", "feed_owner_type"], :name => "index_feed_entries_on_feed_owner_id_and_feed_owner_type"
  add_index "feed_entries", ["guid"], :name => "index_feed_entries_on_guid"
  add_index "feed_entries", ["published_at"], :name => "index_feed_entries_on_published_at"

  create_table "financial_transactions", :force => true do |t|
    t.text     "description"
    t.string   "uid"
    t.integer  "supplier_id"
    t.date     "date"
    t.string   "department_name"
    t.string   "service"
    t.string   "cost_centre"
    t.text     "source_url"
    t.float    "value"
    t.string   "transaction_type"
    t.integer  "date_fuzziness"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "invoice_number"
    t.integer  "csv_line_number"
    t.integer  "classification_id"
    t.date     "invoice_date"
  end

  add_index "financial_transactions", ["date"], :name => "index_financial_transactions_on_date"
  add_index "financial_transactions", ["supplier_id"], :name => "index_financial_transactions_on_supplier_id"
  add_index "financial_transactions", ["value"], :name => "index_financial_transactions_on_value"

  create_table "hyperlocal_groups", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hyperlocal_sites", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "email"
    t.string   "feed_url"
    t.float    "lat"
    t.float    "lng"
    t.float    "distance_covered"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hyperlocal_group_id"
    t.string   "platform"
    t.text     "description"
    t.string   "area_covered"
    t.integer  "council_id"
    t.string   "country"
    t.boolean  "approved",                           :default => false
    t.string   "party_affiliation"
    t.point    "geom",                :limit => nil,                    :srid => 4326
    t.point    "metres",              :limit => nil,                    :srid => 27700
  end

  add_index "hyperlocal_sites", ["approved"], :name => "index_hyperlocal_sites_on_approved"
  add_index "hyperlocal_sites", ["council_id"], :name => "index_hyperlocal_sites_on_council_id"
  add_index "hyperlocal_sites", ["geom"], :name => "index_hyperlocal_sites_on_geom", :spatial => true
  add_index "hyperlocal_sites", ["hyperlocal_group_id"], :name => "index_hyperlocal_sites_on_hyperlocal_group_id"
  add_index "hyperlocal_sites", ["metres"], :name => "index_hyperlocal_sites_on_metres", :spatial => true

  create_table "investigation_subject_connections", :force => true do |t|
    t.integer "investigation_id"
    t.integer "subject_id"
    t.string  "subject_type"
  end

  add_index "investigation_subject_connections", ["investigation_id"], :name => "index_investigation_subject_connections_on_investigation_id"
  add_index "investigation_subject_connections", ["subject_id", "subject_type"], :name => "index_investigation_subject_connections_on_subject"

  create_table "investigations", :force => true do |t|
    t.string   "uid"
    t.string   "url"
    t.string   "related_organisation_name"
    t.text     "raw_html"
    t.string   "standards_body"
    t.string   "title"
    t.string   "subjects"
    t.date     "date_received"
    t.date     "date_completed"
    t.text     "description"
    t.text     "result"
    t.text     "case_details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "full_report_url"
    t.string   "related_organisation_type"
    t.integer  "related_organisation_id"
  end

  add_index "investigations", ["related_organisation_id", "related_organisation_type"], :name => "index_investigations_on_related_organisation"

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

  add_index "ldg_services", ["lgsl"], :name => "index_ldg_services_on_lgsl"

  create_table "meetings", :force => true do |t|
    t.datetime "date_held"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "committee_id"
    t.string   "uid"
    t.integer  "council_id"
    t.string   "url"
    t.text     "venue"
    t.string   "status"
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
    t.string   "blog_url"
    t.string   "facebook_account_name"
    t.string   "linked_in_account_name"
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

  add_index "officers", ["council_id"], :name => "index_officers_on_council_id"

  create_table "ons_datasets", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "dataset_family_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ons_datasets", ["dataset_family_id"], :name => "index_ons_datasets_on_ons_dataset_family_id"

  create_table "ons_subjects", :force => true do |t|
    t.string   "title"
    t.integer  "ons_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "output_area_classifications", :force => true do |t|
    t.string  "title"
    t.string  "uid"
    t.string  "area_type"
    t.integer "level"
  end

  create_table "output_areas", :force => true do |t|
    t.string  "oa_code"
    t.string  "lsoa_code"
    t.string  "lsoa_name"
    t.integer "ward_id"
    t.string  "ward_snac_id"
  end

  add_index "output_areas", ["ward_id"], :name => "index_output_areas_on_ward_id"

  create_table "parish_councils", :force => true do |t|
    t.string   "title"
    t.string   "os_id"
    t.text     "website"
    t.string   "gss_code"
    t.integer  "council_id"
    t.string   "wdtk_name"
    t.string   "vat_number"
    t.string   "normalised_title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "feed_url"
    t.string   "facebook_account_name"
    t.string   "youtube_account_name"
    t.string   "council_type",          :limit => 8
  end

  add_index "parish_councils", ["council_id"], :name => "index_parish_councils_on_council_id"
  add_index "parish_councils", ["os_id"], :name => "index_parish_councils_on_os_id"

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
    t.string   "type"
    t.text     "attribute_mapping"
    t.integer  "skip_rows"
    t.string   "cookie_path"
  end

  add_index "parsers", ["id", "type"], :name => "index_parsers_on_id_and_type"
  add_index "parsers", ["portal_system_id"], :name => "index_parsers_on_portal_system_id"

  create_table "pension_funds", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "telephone"
    t.string   "email"
    t.string   "fax"
    t.text     "address"
    t.string   "wdtk_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wdtk_id"
  end

  add_index "pension_funds", ["name"], :name => "index_pension_funds_on_name"

  create_table "planning_applications", :force => true do |t|
    t.string   "uid",               :limit => 50,                  :null => false
    t.text     "address"
    t.string   "postcode"
    t.text     "description"
    t.string   "url",               :limit => 1024
    t.string   "comment_url",       :limit => 1024
    t.datetime "retrieved_at"
    t.date     "start_date"
    t.float    "lat"
    t.float    "lng"
    t.integer  "council_id"
    t.text     "applicant_name"
    t.text     "applicant_address"
    t.text     "decision"
    t.text     "other_attributes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "application_type"
    t.integer  "bitwise_flag",                      :default => 0
    t.text     "status"
    t.point    "geom",              :limit => nil,                                 :srid => 4326
    t.point    "metres",            :limit => nil,                                 :srid => 27700
  end

  add_index "planning_applications", ["council_id", "start_date"], :name => "index_planning_applications_on_council_id_and_date_received"
  add_index "planning_applications", ["council_id", "uid"], :name => "index_planning_applications_on_council_id_and_uid", :unique => true
  add_index "planning_applications", ["council_id", "updated_at"], :name => "index_planning_applications_on_council_id_and_updated_at"
  add_index "planning_applications", ["geom"], :name => "index_planning_applications_on_geom", :spatial => true
  add_index "planning_applications", ["lat", "lng"], :name => "index_planning_applications_on_lat_and_lng"
  add_index "planning_applications", ["metres"], :name => "index_planning_applications_on_metres", :spatial => true

  create_table "police_authorities", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.text     "address"
    t.string   "telephone"
    t.string   "wdtk_name"
    t.string   "wikipedia_url"
    t.integer  "police_force_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "annual_audit_letter"
    t.string   "vat_number"
    t.integer  "wdtk_id"
  end

  add_index "police_authorities", ["name"], :name => "index_police_authorities_on_name"
  add_index "police_authorities", ["police_force_id"], :name => "index_police_authorities_on_police_force_id"

  create_table "police_forces", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "wikipedia_url"
    t.string   "telephone"
    t.text     "address"
    t.string   "wdtk_name"
    t.string   "npia_id"
    t.string   "youtube_account_name"
    t.string   "facebook_account_name"
    t.string   "feed_url"
    t.string   "crime_map"
    t.integer  "wdtk_id"
  end

  add_index "police_forces", ["npia_id"], :name => "index_police_forces_on_npia_id"

  create_table "police_officers", :force => true do |t|
    t.string   "name"
    t.string   "rank"
    t.text     "biography"
    t.integer  "police_team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",         :default => true
  end

  add_index "police_officers", ["police_team_id"], :name => "index_police_officers_on_police_team_id"

  create_table "police_teams", :force => true do |t|
    t.string   "name"
    t.string   "uid"
    t.text     "description"
    t.string   "url"
    t.integer  "police_force_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "lat"
    t.float    "lng"
    t.boolean  "defunkt",         :default => false
  end

  add_index "police_teams", ["police_force_id"], :name => "index_police_teams_on_police_force_id"
  add_index "police_teams", ["uid"], :name => "index_police_teams_on_uid"

  create_table "political_parties", :force => true do |t|
    t.string   "name"
    t.string   "electoral_commission_uid"
    t.string   "url"
    t.string   "wikipedia_name"
    t.string   "colour"
    t.text     "alternative_names"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "political_parties", ["electoral_commission_uid"], :name => "index_political_parties_on_electoral_commission_uid"
  add_index "political_parties", ["wikipedia_name"], :name => "index_political_parties_on_wikipedia_name"

  create_table "polls", :force => true do |t|
    t.integer  "area_id"
    t.string   "area_type"
    t.date     "date_held"
    t.string   "position"
    t.integer  "electorate"
    t.integer  "ballots_issued"
    t.integer  "ballots_rejected"
    t.integer  "postal_votes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source"
    t.boolean  "uncontested",                             :default => false
    t.integer  "ballots_missing_official_mark"
    t.integer  "ballots_with_too_many_candidates_chosen"
    t.integer  "ballots_with_identifiable_voter"
    t.integer  "ballots_void_for_uncertainty"
  end

  add_index "polls", ["area_id", "area_type"], :name => "index_polls_on_area_id_and_area_type"
  add_index "polls", ["date_held"], :name => "index_polls_on_date_held"

  create_table "portal_systems", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "portal_systems", ["name"], :name => "index_portal_systems_on_name"

  create_table "postcodes", :force => true do |t|
    t.string  "code"
    t.integer "quality"
    t.string  "country"
    t.string  "nhs_region"
    t.string  "nhs_health_authority"
    t.integer "county_id"
    t.integer "council_id"
    t.integer "ward_id"
    t.float   "lat"
    t.float   "lng"
    t.integer "crime_area_id"
    t.point   "geom",                 :limit => nil, :srid => 4326
    t.point   "metres",               :limit => nil, :srid => 27700
  end

  add_index "postcodes", ["code"], :name => "index_postcodes_on_code"
  add_index "postcodes", ["council_id"], :name => "index_postcodes_on_council_id"
  add_index "postcodes", ["county_id"], :name => "index_postcodes_on_county_id"
  add_index "postcodes", ["geom"], :name => "index_postcodes_on_geom", :spatial => true
  add_index "postcodes", ["metres"], :name => "index_postcodes_on_metres", :spatial => true
  add_index "postcodes", ["ward_id"], :name => "index_postcodes_on_ward_id"

  create_table "quangos", :force => true do |t|
    t.string   "title"
    t.string   "quango_type"
    t.string   "quango_subtype"
    t.string   "website"
    t.string   "wikipedia_url"
    t.string   "sponsoring_organisation"
    t.string   "wdtk_name"
    t.text     "previous_names"
    t.date     "setup_on"
    t.date     "disbanded_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "related_articles", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "subject_type"
    t.integer  "subject_id"
    t.text     "extract"
    t.integer  "hyperlocal_site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "related_articles", ["hyperlocal_site_id"], :name => "index_related_articles_on_hyperlocal_site_id"
  add_index "related_articles", ["subject_id", "subject_type"], :name => "index_related_articles_on_subject_id_and_subject_type"

  create_table "scrapers", :force => true do |t|
    t.text     "url"
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
    t.boolean  "problematic",                             :default => false
    t.text     "notes"
    t.string   "referrer_url"
    t.text     "cookie_url"
    t.boolean  "use_post",                                :default => false
    t.string   "parsing_library",            :limit => 1, :default => "H"
    t.string   "base_url"
    t.datetime "next_due"
    t.integer  "frequency",                               :default => 7
    t.integer  "priority",                                :default => 4
  end

  add_index "scrapers", ["council_id"], :name => "index_scrapers_on_council_id"
  add_index "scrapers", ["id", "type"], :name => "index_scrapers_on_id_and_type"
  add_index "scrapers", ["parser_id"], :name => "index_scrapers_on_parser_id"
  add_index "scrapers", ["priority", "next_due"], :name => "index_scrapers_on_priority_and_next_due"

  create_table "scrapes", :force => true do |t|
    t.integer  "scraper_id"
    t.string   "results_summary"
    t.text     "results"
    t.text     "scraping_errors"
    t.datetime "created_at"
  end

  add_index "scrapes", ["scraper_id", "created_at"], :name => "index_scrapes_on_scraper_id_and_created_at"

  create_table "services", :force => true do |t|
    t.string   "title"
    t.text     "url"
    t.string   "category"
    t.integer  "council_id"
    t.integer  "ldg_service_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "services", ["council_id"], :name => "index_services_on_council_id"
  add_index "services", ["ldg_service_id"], :name => "index_services_on_ldg_service_id"

  create_table "spending_stats", :force => true do |t|
    t.string   "organisation_type"
    t.integer  "organisation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "total_spend"
    t.float    "average_monthly_spend"
    t.float    "average_transaction_value"
    t.text     "spend_by_month"
    t.text     "breakdown"
    t.date     "earliest_transaction"
    t.date     "latest_transaction"
    t.integer  "transaction_count",            :limit => 8
    t.integer  "total_received_from_councils"
    t.text     "payer_breakdown"
    t.integer  "total_received"
  end

  add_index "spending_stats", ["organisation_id", "organisation_type"], :name => "index_spending_stats_on_organisation"
  add_index "spending_stats", ["organisation_type", "total_spend"], :name => "index_spending_stats_on_organisation_type_and_total_spend"

  create_table "suppliers", :force => true do |t|
    t.string   "name"
    t.string   "uid"
    t.string   "organisation_type"
    t.integer  "organisation_id"
    t.boolean  "failed_payee_search", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.integer  "payee_id"
    t.string   "payee_type"
  end

  add_index "suppliers", ["name"], :name => "index_suppliers_on_name"
  add_index "suppliers", ["organisation_id", "organisation_type"], :name => "index_suppliers_on_organisation_id_and_organisation_type"
  add_index "suppliers", ["payee_id", "payee_type"], :name => "index_suppliers_on_payee_id_and_payee_type"
  add_index "suppliers", ["uid"], :name => "index_suppliers_on_uid"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "twitter_accounts", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.string   "user_type"
    t.integer  "twitter_id"
    t.integer  "follower_count"
    t.integer  "following_count"
    t.text     "last_tweet"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "twitter_accounts", ["user_id", "user_type"], :name => "index_twitter_accounts_on_user_id_and_user_type"

  create_table "user_submissions", :force => true do |t|
    t.string   "twitter_account_name"
    t.integer  "item_id"
    t.integer  "member_id"
    t.string   "member_name"
    t.string   "blog_url"
    t.string   "facebook_account_name"
    t.string   "linked_in_account_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "approved",               :default => false
    t.text     "submission_details"
    t.string   "item_type"
    t.string   "ip_address"
    t.text     "notes"
  end

  add_index "user_submissions", ["item_id", "item_type"], :name => "index_user_submissions_on_item_id_and_item_type"
  add_index "user_submissions", ["item_id"], :name => "index_user_submissions_on_council_id"
  add_index "user_submissions", ["member_id"], :name => "index_user_submissions_on_member_id"

  create_table "wards", :force => true do |t|
    t.string   "name"
    t.integer  "council_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uid"
    t.string   "snac_id"
    t.string   "url"
    t.string   "os_id"
    t.string   "police_neighbourhood_url"
    t.string   "ness_id"
    t.string   "gss_code"
    t.integer  "police_team_id"
    t.integer  "output_area_classification_id"
    t.boolean  "defunkt",                       :default => false
    t.integer  "crime_area_id"
  end

  add_index "wards", ["council_id"], :name => "index_wards_on_council_id"
  add_index "wards", ["os_id"], :name => "index_wards_on_os_id"
  add_index "wards", ["output_area_classification_id"], :name => "index_wards_on_output_area_classification_id"
  add_index "wards", ["police_team_id"], :name => "index_wards_on_police_team_id"
  add_index "wards", ["snac_id"], :name => "index_wards_on_snac_id"

  create_table "wdtk_requests", :force => true do |t|
    t.string   "title"
    t.string   "status"
    t.text     "description"
    t.integer  "organisation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "organisation_type"
    t.integer  "uid"
    t.string   "related_object_type"
    t.integer  "related_object_id"
    t.string   "request_name"
  end

  add_index "wdtk_requests", ["organisation_id"], :name => "index_wdtk_requests_on_council_id"

end
