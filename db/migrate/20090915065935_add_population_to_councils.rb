class AddPopulationToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :population, :integer
    Council.reset_column_information
    rows = FasterCSV.read(File.join(RAILS_ROOT, "db/ons_data/LA-pop-by-Snac.csv"), :headers => true).to_a
    rows[1..-1].each do |row| # skip header row
      if council = Council.find_by_snac_id(row[2]) # try to find council
        population = (row[3].to_f*1000).to_i
        council.update_attribute(:population, population)
        puts "Updated council: #{row[0].strip} (#{row[2]}) with population #{population}"
      else
        puts "Could not find council: #{row[0].strip} (#{row[2]})"
      end
    end
  end

  def self.down
    remove_column :councils, :population
  end
end
