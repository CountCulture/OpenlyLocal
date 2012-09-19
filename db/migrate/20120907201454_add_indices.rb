class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :charities, :normalised_title
    add_index :classifications, :grouping
    add_index :companies, :company_number
    add_index :councils, :authority_type
    add_index :councils, :cipfa_code
    add_index :councils, :normalised_title
    add_index :councils, :os_id
    add_index :councils, :snac_id
    add_index :councils, :wdtk_name
    add_index :dataset_topics, :ons_uid
    add_index :entities, :title
    add_index :entities, :wdtk_name
    add_index :hyperlocal_sites, :approved
    add_index :ldg_services, :lgsl
    add_index :parish_councils, :os_id
    add_index :pension_funds, :name
    add_index :police_authorities, :name
    add_index :police_forces, :npia_id
    add_index :police_teams, :uid
    add_index :political_parties, :electoral_commission_uid
    add_index :political_parties, :wikipedia_name
    add_index :polls, :date_held
    add_index :portal_systems, :name
    add_index :suppliers, :name
    add_index :suppliers, :uid
    add_index :wards, :os_id
    add_index :wards, :snac_id
  end

  def self.down
    remove_index :charities, :normalised_title
    remove_index :classifications, :grouping
    remove_index :companies, :company_number
    remove_index :councils, :authority_type
    remove_index :councils, :cipfa_code
    remove_index :councils, :normalised_title
    remove_index :councils, :os_id
    remove_index :councils, :snac_id
    remove_index :councils, :wdtk_name
    remove_index :dataset_topics, :ons_uid
    remove_index :entities, :title
    remove_index :entities, :wdtk_name
    remove_index :hyperlocal_sites, :approved
    remove_index :ldg_services, :lgsl
    remove_index :parish_councils, :os_id
    remove_index :pension_funds, :name
    remove_index :police_authorities, :name
    remove_index :police_forces, :npia_id
    remove_index :police_teams, :uid
    remove_index :political_parties, :electoral_commission_uid
    remove_index :political_parties, :wikipedia_name
    remove_index :polls, :date_held
    remove_index :portal_systems, :name
    remove_index :suppliers, :name
    remove_index :suppliers, :uid
    remove_index :wards, :os_id
    remove_index :wards, :snac_id
  end
end
