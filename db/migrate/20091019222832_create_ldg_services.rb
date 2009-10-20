class CreateLdgServices < ActiveRecord::Migration
  def self.up
    create_table :services do |t|
      t.string  :category
      t.integer :lgsl
      t.integer :lgil
      t.string  :service_name
      t.string  :authority_level
      t.string  :url

      t.timestamps
    end
    Service.reset_column_information
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/csv_data/ldg_services/ldg_services.csv"), :headers => true) do |row|
      Service.create!( :category => row[0],
                       :lgsl => row[1],
                       :lgil => row[2],
                       :service_name => row[3],
                       :authority_level => row[4],
                       :url => row[5] )
    end
    
  end

  def self.down
    drop_table :services
  end
end
