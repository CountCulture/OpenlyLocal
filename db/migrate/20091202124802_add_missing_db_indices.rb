class AddMissingDbIndices < ActiveRecord::Migration
  def self.up

    # These indexes were found by searching for AR::Base finds on your application
    # It is strongly recommanded that you will consult a professional DBA about your infrastucture and implemntation before
    # changing your database in that matter.
    # There is a possibility that some of the indexes offered below is not required and can be removed and not added, if you require
    # further assistance with your rails application, database infrastructure or any other problem, visit:
    #
    # http://www.railsmentors.org
    # http://www.railstutor.org
    # http://guides.rubyonrails.org


    add_index :officers, :council_id
    add_index :parsers, :portal_system_id
    add_index :wdtk_requests, :council_id
    add_index :committees, :ward_id
    add_index :services, :ldg_service_id
    add_index :councils, :police_force_id
    add_index :councils, :portal_system_id
    add_index :councils, :parent_authority_id
    add_index :scrapers, [:id, :type]
    add_index :scrapers, :parser_id
    add_index :scrapers, :council_id
  end

  def self.down
    remove_index :officers, :council_id
    remove_index :parsers, :portal_system_id
    remove_index :wdtk_requests, :council_id
    remove_index :committees, :ward_id
    remove_index :services, :ldg_service_id
    remove_index :councils, :police_force_id
    remove_index :councils, :portal_system_id
    remove_index :councils, :parent_authority_id
    remove_index :scrapers, :column => [:id, :type]
    remove_index :scrapers, :parser_id
    remove_index :scrapers, :council_id
  end
end
