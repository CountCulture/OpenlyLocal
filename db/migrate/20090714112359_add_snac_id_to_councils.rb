class AddSnacIdToCouncils < ActiveRecord::Migration
  require 'hpricot'
  def self.up
    add_column :councils, :snac_id, :string
    Council.reset_column_information
    Council.all(:conditions => "egr_id IS NOT NULL").each do |council|
      begin
        doc = Hpricot(open("http://www.brent.gov.uk/egr.nsf/laref/#{council.egr_id}"))
        snac_id = doc.at("#main td[text()*='SNAC']").next_sibling.at("font").inner_text.strip
        puts "Updating #{council.name} with SNAC ID: #{snac_id}"
        council.update_attribute(:snac_id, snac_id)
      rescue Exception => e
        puts "exeception raised (#{e.inspect}) when getting SNAC ID for #{council.name}"
      end
    end
  end

  def self.down
    remove_column :councils, :snac_id
  end
end
