class CreateLsoas < ActiveRecord::Migration
  def self.up
    create_table :lsoas do |t|
      t.string  :oa_code
      t.string  :lsoa_code
      t.string  :lsoa_name
      t.integer :ward_id
      t.string :ward_snac_id
    end
    Lsoa.reset_column_information
    csv_file = "OA_LSOA_STward_LA_Apr05_part"
    (1..3).each do |i|
      FasterCSV.foreach(File.join(RAILS_ROOT, "db/ons_data/#{csv_file}#{i}.csv"), :headers => true) do |row|
        # columns are: OA_code,LSOA_code,LSOA_name,STwardcode,STwardname,LA_code,LA_name
        Lsoa.create!(:oa_code => row[0], :lsoa_code => row[1], :lsoa_name => row[2], :ward_snac_id => row[3], :ward => Ward.find_by_snac_id(row[3]))
      end
      puts "Finished processing #{csv_file}#{i}.csv"
    end
  end

  def self.down
    drop_table :lsoas
  end
end
