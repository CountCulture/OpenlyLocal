desc "Import May 2006 London Election Results"
task :import_london_2006_election_results => :environment do
end

desc "Scrape Electoral Commission for Political Parties"
task :scrape_electoral_commission_party_list => :environment do
  require 'hpricot'
  base_url = 'http://registers.electoralcommission.org.uk'
  party_list_page = 'http://registers.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm'
  Hpricot(open(party_list_page)).search('#id_political option')[1..-1].each do |option|
    party = PoliticalParty.find_or_initialize_by_electoral_commission_uid(:electoral_commission_uid => option[:value], :name => option.inner_text)
    begin
      party.save!
    rescue Exception => e
      puts "Problem saving ##{party.inspect}"
    end
  end
end