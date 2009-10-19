class AddLdgIdToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :ldg_id, :integer
    Council.reset_column_information
    # try to fill LdgId from csv file
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/csv_data/ldg_services/ldg_LA_ids.csv"), :headers => true) do |row|
      councils = [Council.first(:conditions => ["name = ?", row[0]]) || Council.all(:conditions => ["name LIKE ?", "%#{row[0].gsub(/Borough|City|Royal|London Borough|of|Council|\(Unitary\)/, '').strip}%"])].flatten
      if councils.empty?
        puts "Couldn't find entry for #{row[0]}"
      elsif councils.size > 1
        puts "More than one matching entry for #{row[0]} (#{councils.collect(&:name).join(', ')})"
      else
        councils.first.update_attribute(:ldg_id, row[1])
        puts "successfully updated #{councils.first.name} with LDG id (#{row[1]})"
      end
    end
    
  end

  def self.down
    remove_column :councils, :ldg_id
  end
end
