class AddMissingIndices < ActiveRecord::Migration
  def self.up
    add_index :financial_transactions, :supplier_id
    add_index :addresses, [:addressee_id, :addressee_type]
    add_index :contracts, [:organisation_id, :organisation_type]
    add_index :crime_areas, :police_force_id
    add_index :wards, :output_area_classification_id
    add_index :related_articles, :hyperlocal_site_id
    add_index :related_articles, [:subject_id, :subject_type]
    add_index :datasets, :dataset_topic_grouping_id
    add_index :councils, :pension_fund_id
    add_index :councils, :output_area_classification_id
    add_index :suppliers, [:organisation_id, :organisation_type]
    add_index :boundaries, [:area_id, :area_type]
  end
  
  def self.down
    remove_index :financial_transactions, :supplier_id
    remove_index :addresses, :column => [:addressee_id, :addressee_type]
    remove_index :contracts, :column => [:organisation_id, :organisation_type]
    remove_index :crime_areas, :police_force_id
    remove_index :wards, :output_area_classification_id
    remove_index :related_articles, :hyperlocal_site_id
    remove_index :related_articles, :column => [:subject_id, :subject_type]
    remove_index :datasets, :dataset_topic_grouping_id
    remove_index :councils, :pension_fund_id
    remove_index :councils, :output_area_classification_id
    remove_index :suppliers, :column => [:organisation_id, :organisation_type]
    remove_index :boundaries, :column => [:area_id, :area_type]
  end
end
