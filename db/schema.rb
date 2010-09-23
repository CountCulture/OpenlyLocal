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

ActiveRecord::Schema.define(:version => 20100923164320) do

  create_table "addresses", :force => true do |t|
    t.column "street_address", :text
    t.column "locality", :string
    t.column "postal_code", :string
    t.column "country", :string
    t.column "addressee_type", :string
    t.column "addressee_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "region", :string
    t.column "former", :boolean, :default => false
  end

  add_index "addresses", ["addressee_id", "addressee_type"], :name => "index_addresses_on_addressee_id_and_addressee_type"

  create_table "boundaries", :force => true do |t|
    t.column "area_type", :string
    t.column "area_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "boundary_line", :polygon
    t.column "hectares", :float
  end

  add_index "boundaries", ["area_id", "area_type"], :name => "index_boundaries_on_area_id_and_area_type"

  create_table "candidates", :force => true do |t|
    t.column "poll_id", :integer
    t.column "first_name", :string
    t.column "last_name", :string
    t.column "party", :string
    t.column "elected", :boolean
    t.column "votes", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "basic_address", :text
    t.column "political_party_id", :integer
    t.column "member_id", :integer
  end

  add_index "candidates", ["poll_id"], :name => "index_candidates_on_poll_id"
  add_index "candidates", ["political_party_id"], :name => "index_candidates_on_political_party_id"
  add_index "candidates", ["member_id"], :name => "index_candidates_on_member_id"

  create_table "charities", :force => true do |t|
    t.column "title", :string
    t.column "activities", :text
    t.column "charity_number", :string
    t.column "website", :string
    t.column "email", :string
    t.column "telephone", :string
    t.column "date_registered", :date
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "vat_number", :string
    t.column "contact_name", :string
    t.column "accounts_date", :date
    t.column "spending", :integer
    t.column "income", :integer
    t.column "date_removed", :date
    t.column "normalised_title", :string
    t.column "employees", :integer
    t.column "accounts", :text
    t.column "financial_breakdown", :text
    t.column "trustees", :text
    t.column "other_names", :string
    t.column "volunteers", :integer
    t.column "last_checked", :datetime
    t.column "facebook_account_name", :string
    t.column "youtube_account_name", :string
    t.column "feed_url", :string
    t.column "governing_document", :text
  end

  add_index "charities", ["charity_number"], :name => "index_charities_on_charity_number"
  add_index "charities", ["date_registered"], :name => "index_charities_on_date_registered"

  create_table "committees", :force => true do |t|
    t.column "title", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "url", :string
    t.column "council_id", :integer
    t.column "uid", :string
    t.column "description", :text
    t.column "ward_id", :integer
    t.column "normalised_title", :string
    t.column "organisation_type", :string
    t.column "organisation_id", :integer
  end

  add_index "committees", ["council_id"], :name => "index_committees_on_council_id"
  add_index "committees", ["ward_id"], :name => "index_committees_on_ward_id"

  create_table "companies", :force => true do |t|
    t.column "title", :string
    t.column "url", :string
    t.column "company_number", :string
    t.column "supplier_id", :integer
    t.column "normalised_title", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "incorporation_date", :date
    t.column "company_type", :string
    t.column "wikipedia_url", :string
    t.column "status", :string
    t.column "vat_number", :string
    t.column "previous_names", :text
    t.column "sic_codes", :text
    t.column "country", :string
  end

  create_table "contracts", :force => true do |t|
    t.column "title", :string
    t.column "description", :text
    t.column "uid", :string
    t.column "source_url", :string
    t.column "url", :string
    t.column "organisation_id", :integer
    t.column "organisation_type", :string
    t.column "start_date", :date
    t.column "end_date", :date
    t.column "duration", :string
    t.column "total_value", :integer
    t.column "annual_value", :integer
    t.column "supplier_name", :string
    t.column "supplier_address", :text
    t.column "supplier_uid", :string
    t.column "department_responsible", :string
    t.column "person_responsible", :string
    t.column "email", :string
    t.column "telephone", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  add_index "contracts", ["organisation_id", "organisation_type"], :name => "index_contracts_on_organisation_id_and_organisation_type"

  create_table "council_contacts", :force => true do |t|
    t.column "name", :string
    t.column "position", :string
    t.column "email", :string
    t.column "council_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "approved", :datetime
  end

  add_index "council_contacts", ["council_id"], :name => "index_council_contacts_on_council_id"

  create_table "councils", :force => true do |t|
    t.column "name", :string
    t.column "url", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "base_url", :string
    t.column "telephone", :string
    t.column "address", :text
    t.column "authority_type", :string
    t.column "portal_system_id", :integer
    t.column "notes", :text
    t.column "wikipedia_url", :string
    t.column "ons_url", :string
    t.column "egr_id", :integer
    t.column "wdtk_name", :string
    t.column "feed_url", :string
    t.column "data_source_url", :string
    t.column "data_source_name", :string
    t.column "snac_id", :string
    t.column "country", :string
    t.column "population", :integer
    t.column "ldg_id", :integer
    t.column "os_id", :string
    t.column "parent_authority_id", :integer
    t.column "police_force_url", :string
    t.column "police_force_id", :integer
    t.column "ness_id", :string
    t.column "lat", :float
    t.column "lng", :float
    t.column "cipfa_code", :string
    t.column "region", :string
    t.column "signed_up_for_1010", :boolean, :default => false
    t.column "pension_fund_id", :integer
    t.column "gss_code", :string
    t.column "annual_audit_letter", :string
    t.column "output_area_classification_id", :integer
    t.column "defunkt", :boolean, :default => false
    t.column "open_data_url", :string
    t.column "open_data_licence", :string
    t.column "normalised_title", :string
    t.column "wdtk_id", :integer
    t.column "vat_number", :string
  end

  add_index "councils", ["police_force_id"], :name => "index_councils_on_police_force_id"
  add_index "councils", ["portal_system_id"], :name => "index_councils_on_portal_system_id"
  add_index "councils", ["parent_authority_id"], :name => "index_councils_on_parent_authority_id"
  add_index "councils", ["pension_fund_id"], :name => "index_councils_on_pension_fund_id"
  add_index "councils", ["output_area_classification_id"], :name => "index_councils_on_output_area_classification_id"

  create_table "crime_areas", :force => true do |t|
    t.column "uid", :string
    t.column "police_force_id", :integer
    t.column "name", :string
    t.column "level", :integer
    t.column "parent_area_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "crime_mapper_url", :string
    t.column "feed_url", :string
    t.column "crime_level_cf_national", :string
    t.column "crime_rates", :text
    t.column "total_crimes", :text
  end

  add_index "crime_areas", ["police_force_id"], :name => "index_crime_areas_on_police_force_id"

  create_table "crime_types", :force => true do |t|
    t.column "uid", :string
    t.column "name", :string
    t.column "plural_name", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "csv_parsers", :force => true do |t|
    t.column "result_model", :string
    t.column "item_mapping", :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "datapoints", :force => true do |t|
    t.column "value", :float
    t.column "dataset_topic_id", :integer
    t.column "area_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "area_type", :string
  end

  add_index "datapoints", ["dataset_topic_id"], :name => "index_ons_datapoints_on_ons_dataset_topic_id"
  add_index "datapoints", ["area_id", "area_type"], :name => "index_datapoints_on_area_id_and_area_type"

  create_table "dataset_families", :force => true do |t|
    t.column "title", :string
    t.column "ons_uid", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "source_type", :string
    t.column "dataset_id", :integer
    t.column "calculation_method", :string
  end

  add_index "dataset_families", ["dataset_id"], :name => "index_dataset_families_on_dataset_id"

  create_table "dataset_families_ons_subjects", :id => false, :force => true do |t|
    t.column "ons_subject_id", :integer
    t.column "dataset_family_id", :integer
  end

  add_index "dataset_families_ons_subjects", ["ons_subject_id", "dataset_family_id"], :name => "ons_families_subjects_join_index"
  add_index "dataset_families_ons_subjects", ["dataset_family_id", "ons_subject_id"], :name => "ons_subjects_families_join_index"

  create_table "dataset_topic_groupings", :force => true do |t|
    t.column "title", :string
    t.column "display_as", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "sort_by", :string
  end

  create_table "dataset_topics", :force => true do |t|
    t.column "title", :string
    t.column "ons_uid", :integer
    t.column "dataset_family_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "muid", :integer
    t.column "description", :text
    t.column "data_date", :date
    t.column "short_title", :string
    t.column "dataset_topic_grouping_id", :integer
  end

  add_index "dataset_topics", ["dataset_family_id"], :name => "index_ons_dataset_topics_on_ons_dataset_family_id"
  add_index "dataset_topics", ["dataset_topic_grouping_id"], :name => "index_dataset_topics_on_dataset_topic_grouping_id"

  create_table "datasets", :force => true do |t|
    t.column "title", :string
    t.column "description", :text
    t.column "url", :string
    t.column "originator", :string
    t.column "originator_url", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "dataset_topic_grouping_id", :integer
    t.column "notes", :text
    t.column "licence", :string
  end

  add_index "datasets", ["dataset_topic_grouping_id"], :name => "index_datasets_on_dataset_topic_grouping_id"

  create_table "delayed_jobs", :force => true do |t|
    t.column "priority", :integer, :default => 0
    t.column "attempts", :integer, :default => 0
    t.column "handler", :text
    t.column "last_error", :text
    t.column "run_at", :datetime
    t.column "locked_at", :datetime
    t.column "failed_at", :datetime
    t.column "locked_by", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "documents", :force => true do |t|
    t.column "title", :string
    t.column "body", :text, :limit => 16777215
    t.column "url", :string
    t.column "document_owner_id", :integer
    t.column "document_owner_type", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "raw_body", :text, :limit => 16777215
    t.column "document_type", :string
    t.column "precis", :text
    t.column "filetype", :string
    t.column "original_file_name", :string
    t.column "original_content_type", :string
    t.column "original_file_size", :integer
    t.column "original_updated_at", :datetime
  end

  add_index "documents", ["document_owner_type", "document_owner_id"], :name => "index_documents_on_document_owner_type_and_document_owner_id"

  create_table "feed_entries", :force => true do |t|
    t.column "title", :string
    t.column "summary", :text
    t.column "url", :string
    t.column "published_at", :datetime
    t.column "guid", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "feed_owner_type", :string
    t.column "feed_owner_id", :integer
    t.column "lat", :float
    t.column "lng", :float
  end

  add_index "feed_entries", ["feed_owner_id", "feed_owner_type"], :name => "index_feed_entries_on_feed_owner_id_and_feed_owner_type"
  add_index "feed_entries", ["guid"], :name => "index_feed_entries_on_guid"

  create_table "financial_transactions", :force => true do |t|
    t.column "description", :text
    t.column "uid", :string
    t.column "supplier_id", :integer
    t.column "date", :date
    t.column "department_name", :string
    t.column "service", :string
    t.column "cost_centre", :string
    t.column "source_url", :text
    t.column "value", :float
    t.column "transaction_type", :string
    t.column "date_fuzziness", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "invoice_number", :string
    t.column "csv_line_number", :integer
  end

  add_index "financial_transactions", ["supplier_id"], :name => "index_financial_transactions_on_supplier_id"
  add_index "financial_transactions", ["value"], :name => "index_financial_transactions_on_value"
  add_index "financial_transactions", ["date"], :name => "index_financial_transactions_on_date"

  create_table "hyperlocal_groups", :force => true do |t|
    t.column "title", :string
    t.column "url", :string
    t.column "email", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "hyperlocal_sites", :force => true do |t|
    t.column "title", :string
    t.column "url", :string
    t.column "email", :string
    t.column "feed_url", :string
    t.column "lat", :float
    t.column "lng", :float
    t.column "distance_covered", :float
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "hyperlocal_group_id", :integer
    t.column "platform", :string
    t.column "description", :text
    t.column "area_covered", :string
    t.column "council_id", :integer
    t.column "country", :string
    t.column "approved", :boolean, :default => false
    t.column "party_affiliation", :string
  end

  add_index "hyperlocal_sites", ["hyperlocal_group_id"], :name => "index_hyperlocal_sites_on_hyperlocal_group_id"
  add_index "hyperlocal_sites", ["council_id"], :name => "index_hyperlocal_sites_on_council_id"

  create_table "investigation_subject_connections", :force => true do |t|
    t.column "investigation_id", :integer
    t.column "subject_id", :integer
    t.column "subject_type", :string
  end

  add_index "investigation_subject_connections", ["investigation_id"], :name => "index_investigation_subject_connections_on_investigation_id"
  add_index "investigation_subject_connections", ["subject_id", "subject_type"], :name => "index_investigation_subject_connections_on_subject"

  create_table "investigations", :force => true do |t|
    t.column "uid", :string
    t.column "url", :string
    t.column "related_organisation_name", :string
    t.column "raw_html", :text
    t.column "standards_body", :string
    t.column "title", :string
    t.column "subjects", :string
    t.column "date_received", :date
    t.column "date_completed", :date
    t.column "description", :text
    t.column "result", :text
    t.column "case_details", :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "full_report_url", :string
    t.column "related_organisation_type", :string
    t.column "related_organisation_id", :integer
  end

  add_index "investigations", ["related_organisation_id", "related_organisation_type"], :name => "index_investigations_on_related_organisation"

  create_table "ldg_services", :force => true do |t|
    t.column "category", :string
    t.column "lgsl", :integer
    t.column "lgil", :integer
    t.column "service_name", :string
    t.column "authority_level", :string
    t.column "url", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "meetings", :force => true do |t|
    t.column "date_held", :datetime
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "committee_id", :integer
    t.column "uid", :string
    t.column "council_id", :integer
    t.column "url", :string
    t.column "venue", :text
    t.column "status", :string
    t.column "organisation_type", :string
    t.column "organisation_id", :integer
  end

  add_index "meetings", ["council_id"], :name => "index_meetings_on_council_id"
  add_index "meetings", ["committee_id"], :name => "index_meetings_on_committee_id"

  create_table "members", :force => true do |t|
    t.column "first_name", :string
    t.column "last_name", :string
    t.column "party", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "url", :string
    t.column "email", :string
    t.column "telephone", :string
    t.column "date_elected", :date
    t.column "date_left", :date
    t.column "council_id", :integer
    t.column "uid", :string
    t.column "name_title", :string
    t.column "qualifications", :string
    t.column "register_of_interests", :string
    t.column "address", :text
    t.column "ward_id", :integer
    t.column "blog_url", :string
    t.column "facebook_account_name", :string
    t.column "linked_in_account_name", :string
    t.column "organisation_type", :string
    t.column "organisation_id", :integer
  end

  add_index "members", ["council_id"], :name => "index_members_on_council_id"
  add_index "members", ["ward_id"], :name => "index_members_on_ward_id"

  create_table "memberships", :force => true do |t|
    t.column "member_id", :integer
    t.column "committee_id", :integer
    t.column "date_joined", :date
    t.column "date_left", :date
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "council_id", :integer
  end

  add_index "memberships", ["committee_id", "member_id"], :name => "index_memberships_on_committee_id_and_member_id"

  create_table "officers", :force => true do |t|
    t.column "first_name", :string
    t.column "last_name", :string
    t.column "name_title", :string
    t.column "qualifications", :string
    t.column "position", :string
    t.column "council_id", :integer
    t.column "url", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "organisation_type", :string
    t.column "organisation_id", :integer
  end

  add_index "officers", ["council_id"], :name => "index_officers_on_council_id"

  create_table "old_datapoints", :force => true do |t|
    t.column "data", :text
    t.column "council_id", :integer
    t.column "old_dataset_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  add_index "old_datapoints", ["council_id"], :name => "index_datapoints_on_council_id"
  add_index "old_datapoints", ["old_dataset_id"], :name => "index_datapoints_on_dataset_id"

  create_table "old_datasets", :force => true do |t|
    t.column "title", :string
    t.column "key", :string
    t.column "source", :string
    t.column "query", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "description", :text
    t.column "originator", :string
    t.column "originator_url", :string
    t.column "summary_column", :integer
    t.column "last_checked", :datetime
  end

  create_table "ons_datasets", :force => true do |t|
    t.column "start_date", :date
    t.column "end_date", :date
    t.column "dataset_family_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  add_index "ons_datasets", ["dataset_family_id"], :name => "index_ons_datasets_on_ons_dataset_family_id"

  create_table "ons_subjects", :force => true do |t|
    t.column "title", :string
    t.column "ons_uid", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "output_area_classifications", :force => true do |t|
    t.column "title", :string
    t.column "uid", :string
    t.column "area_type", :string
    t.column "level", :integer
  end

  create_table "output_areas", :force => true do |t|
    t.column "oa_code", :string
    t.column "lsoa_code", :string
    t.column "lsoa_name", :string
    t.column "ward_id", :integer
    t.column "ward_snac_id", :string
  end

  add_index "output_areas", ["ward_id"], :name => "index_output_areas_on_ward_id"

  create_table "parsers", :force => true do |t|
    t.column "description", :string
    t.column "item_parser", :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "attribute_parser", :text
    t.column "portal_system_id", :integer
    t.column "result_model", :string
    t.column "related_model", :string
    t.column "scraper_type", :string
    t.column "path", :string
    t.column "type", :string
    t.column "attribute_mapping", :text
  end

  add_index "parsers", ["portal_system_id"], :name => "index_parsers_on_portal_system_id"
  add_index "parsers", ["id", "type"], :name => "index_parsers_on_id_and_type"

  create_table "pension_funds", :force => true do |t|
    t.column "name", :string
    t.column "url", :string
    t.column "telephone", :string
    t.column "email", :string
    t.column "fax", :string
    t.column "address", :text
    t.column "wdtk_name", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "police_authorities", :force => true do |t|
    t.column "name", :string
    t.column "url", :string
    t.column "address", :text
    t.column "telephone", :string
    t.column "wdtk_name", :string
    t.column "wikipedia_url", :string
    t.column "police_force_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "annual_audit_letter", :string
    t.column "vat_number", :string
  end

  add_index "police_authorities", ["police_force_id"], :name => "index_police_authorities_on_police_force_id"

  create_table "police_forces", :force => true do |t|
    t.column "name", :string
    t.column "url", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "wikipedia_url", :string
    t.column "telephone", :string
    t.column "address", :text
    t.column "wdtk_name", :string
    t.column "npia_id", :string
    t.column "youtube_account_name", :string
    t.column "facebook_account_name", :string
    t.column "feed_url", :string
    t.column "crime_map", :string
  end

  create_table "police_officers", :force => true do |t|
    t.column "name", :string
    t.column "rank", :string
    t.column "biography", :text
    t.column "police_team_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "active", :boolean, :default => true
  end

  add_index "police_officers", ["police_team_id"], :name => "index_police_officers_on_police_team_id"

  create_table "police_teams", :force => true do |t|
    t.column "name", :string
    t.column "uid", :string
    t.column "description", :text
    t.column "url", :string
    t.column "police_force_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "lat", :float
    t.column "lng", :float
    t.column "defunkt", :boolean, :default => false
  end

  add_index "police_teams", ["police_force_id"], :name => "index_police_teams_on_police_force_id"

  create_table "political_parties", :force => true do |t|
    t.column "name", :string
    t.column "electoral_commission_uid", :string
    t.column "url", :string
    t.column "wikipedia_name", :string
    t.column "colour", :string
    t.column "alternative_names", :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "polls", :force => true do |t|
    t.column "area_id", :integer
    t.column "area_type", :string
    t.column "date_held", :date
    t.column "position", :string
    t.column "electorate", :integer
    t.column "ballots_issued", :integer
    t.column "ballots_rejected", :integer
    t.column "postal_votes", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "source", :string
    t.column "uncontested", :boolean, :default => false
    t.column "ballots_missing_official_mark", :integer
    t.column "ballots_with_too_many_candidates_chosen", :integer
    t.column "ballots_with_identifiable_voter", :integer
    t.column "ballots_void_for_uncertainty", :integer
  end

  add_index "polls", ["area_id", "area_type"], :name => "index_polls_on_area_id_and_area_type"

  create_table "portal_systems", :force => true do |t|
    t.column "name", :string
    t.column "url", :string
    t.column "notes", :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "postcodes", :force => true do |t|
    t.column "code", :string
    t.column "quality", :integer
    t.column "country", :string
    t.column "nhs_region", :string
    t.column "nhs_health_authority", :string
    t.column "county_id", :integer
    t.column "council_id", :integer
    t.column "ward_id", :integer
    t.column "lat", :float
    t.column "lng", :float
    t.column "crime_area_id", :integer
  end

  add_index "postcodes", ["code"], :name => "index_postcodes_on_code"
  add_index "postcodes", ["ward_id"], :name => "index_postcodes_on_ward_id"
  add_index "postcodes", ["council_id"], :name => "index_postcodes_on_council_id"
  add_index "postcodes", ["county_id"], :name => "index_postcodes_on_county_id"

  create_table "quangos", :force => true do |t|
    t.column "title", :string
    t.column "quango_type", :string
    t.column "quango_subtype", :string
    t.column "website", :string
    t.column "wikipedia_url", :string
    t.column "sponsoring_organisation", :string
    t.column "wdtk_name", :string
    t.column "previous_names", :text
    t.column "setup_on", :date
    t.column "disbanded_on", :date
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "vat_number", :string
  end

  create_table "related_articles", :force => true do |t|
    t.column "title", :string
    t.column "url", :string
    t.column "subject_type", :string
    t.column "subject_id", :integer
    t.column "extract", :text
    t.column "hyperlocal_site_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  add_index "related_articles", ["hyperlocal_site_id"], :name => "index_related_articles_on_hyperlocal_site_id"
  add_index "related_articles", ["subject_id", "subject_type"], :name => "index_related_articles_on_subject_id_and_subject_type"

  create_table "scrapers", :force => true do |t|
    t.column "url", :string
    t.column "parser_id", :integer
    t.column "council_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "expected_result_class", :string
    t.column "expected_result_size", :integer
    t.column "expected_result_attributes", :text
    t.column "type", :string
    t.column "related_model", :string
    t.column "last_scraped", :datetime
    t.column "problematic", :boolean, :default => false
    t.column "notes", :text
    t.column "referrer_url", :string
    t.column "cookie_url", :string
    t.column "organisation_type", :string
    t.column "organisation_id", :integer
  end

  add_index "scrapers", ["id", "type"], :name => "index_scrapers_on_id_and_type"
  add_index "scrapers", ["parser_id"], :name => "index_scrapers_on_parser_id"
  add_index "scrapers", ["council_id"], :name => "index_scrapers_on_council_id"

  create_table "services", :force => true do |t|
    t.column "title", :string
    t.column "url", :text
    t.column "category", :string
    t.column "council_id", :integer
    t.column "ldg_service_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  add_index "services", ["council_id"], :name => "index_services_on_council_id"
  add_index "services", ["ldg_service_id"], :name => "index_services_on_ldg_service_id"

  create_table "spending_stats", :force => true do |t|
    t.column "organisation_type", :string
    t.column "organisation_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "total_spend", :float
    t.column "average_monthly_spend", :float
    t.column "average_transaction_value", :float
    t.column "spend_by_month", :text
    t.column "breakdown", :text
  end

  add_index "spending_stats", ["organisation_id", "organisation_type"], :name => "index_spending_stats_on_organisation"

  create_table "suppliers", :force => true do |t|
    t.column "name", :string
    t.column "uid", :string
    t.column "organisation_type", :string
    t.column "organisation_id", :integer
    t.column "failed_payee_search", :boolean, :default => false
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "url", :string
    t.column "payee_id", :integer
    t.column "payee_type", :string
  end

  add_index "suppliers", ["organisation_id", "organisation_type"], :name => "index_suppliers_on_organisation_id_and_organisation_type"
  add_index "suppliers", ["payee_id", "payee_type"], :name => "index_suppliers_on_payee_id_and_payee_type"

  create_table "taggings", :force => true do |t|
    t.column "tag_id", :integer
    t.column "taggable_id", :integer
    t.column "tagger_id", :integer
    t.column "tagger_type", :string
    t.column "taggable_type", :string
    t.column "context", :string
    t.column "created_at", :datetime
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.column "name", :string
  end

  create_table "twitter_accounts", :force => true do |t|
    t.column "name", :string
    t.column "user_id", :integer
    t.column "user_type", :string
    t.column "twitter_id", :integer
    t.column "follower_count", :integer
    t.column "following_count", :integer
    t.column "last_tweet", :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  add_index "twitter_accounts", ["user_id", "user_type"], :name => "index_twitter_accounts_on_user_id_and_user_type"

  create_table "user_submissions", :force => true do |t|
    t.column "twitter_account_name", :string
    t.column "item_id", :integer
    t.column "member_id", :integer
    t.column "member_name", :string
    t.column "blog_url", :string
    t.column "facebook_account_name", :string
    t.column "linked_in_account_name", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "approved", :boolean, :default => false
    t.column "submission_details", :text
    t.column "item_type", :string
    t.column "ip_address", :string
    t.column "notes", :text
  end

  add_index "user_submissions", ["member_id"], :name => "index_user_submissions_on_member_id"
  add_index "user_submissions", ["item_id"], :name => "index_user_submissions_on_council_id"
  add_index "user_submissions", ["item_id", "item_type"], :name => "index_user_submissions_on_item_id_and_item_type"

  create_table "wards", :force => true do |t|
    t.column "name", :string
    t.column "council_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "uid", :string
    t.column "snac_id", :string
    t.column "url", :string
    t.column "os_id", :string
    t.column "police_neighbourhood_url", :string
    t.column "ness_id", :string
    t.column "gss_code", :string
    t.column "police_team_id", :integer
    t.column "organisation_type", :string
    t.column "organisation_id", :integer
    t.column "output_area_classification_id", :integer
    t.column "defunkt", :boolean, :default => false
    t.column "crime_area_id", :integer
  end

  add_index "wards", ["council_id"], :name => "index_wards_on_council_id"
  add_index "wards", ["police_team_id"], :name => "index_wards_on_police_team_id"
  add_index "wards", ["output_area_classification_id"], :name => "index_wards_on_output_area_classification_id"

  create_table "wdtk_requests", :force => true do |t|
    t.column "title", :string
    t.column "url", :string
    t.column "status", :string
    t.column "description", :text
    t.column "council_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  add_index "wdtk_requests", ["council_id"], :name => "index_wdtk_requests_on_council_id"

end
