desc "Import May 2006 London Election Results"
task :import_london_2006_election_results => :environment do
  council_name, ward_name, council, ward, poll, wards = nil, nil, nil, nil, nil, nil #initialize variables
  councils = Council.find_all_by_authority_type('London Borough')
  political_parties = PoliticalParty.all
  FasterCSV.foreach(File.join(RAILS_ROOT, 'db/csv_data/London_LA_Election_Results_May_4_2006.csv'), :headers => true) do |row|
    if council_name != row["Borough"]
      council_name = row["Borough"]
      council = councils.detect{|c| Council.normalise_title(c.name) == Council.normalise_title(row["Borough"])}
      wards = council.wards
      puts "=======\nStarted importing results for #{council.name}"
    end
    if ward_name != row["WardName"]
      ward_name = row["WardName"]
      if ward = wards.detect{ |w| TitleNormaliser.normalise_title(w.title) == TitleNormaliser.normalise_title(ward_name) }
        poll = ward.polls.find_or_create_by_date_held("04-05-2006".to_date)
        puts "Now importing results for ward: #{ward.name}"
      else
        puts "****Can't match: #{ward_name}"
      end
    end
    last_name, first_name  = row["Candidate"].split(',').collect{ |n| n.strip }
    political_party = political_parties.detect{ |p| p.matches_name?(row["Party"]) }
    party = political_party ? nil : row["Party"]
    elected = !!row["Elected"]
    poll.candidacies.create!(:elected => elected, :last_name => last_name, :first_name => first_name, :votes => row["Vote"], :political_party => political_party, :party => party)
  end
end

desc "Import May 2006 London Voting Proportions"
task :import_london_2006_voting_proportions => :environment do
  council_name, council, ward, poll, wards = nil, nil, nil, nil, nil #initialize variables
  councils = Council.find_all_by_authority_type('London Borough')
  political_parties = PoliticalParty.all
  FasterCSV.foreach(File.join(RAILS_ROOT, 'db/csv_data/London_LA_Voting_Proportions_May_4_2006.csv'), :headers => true) do |row|
    if council_name != row['Borough']
      council_name = row['Borough']
      council = councils.detect{|c| Council.normalise_title(c.name) == Council.normalise_title(row['Borough'])}
      wards = council.wards
      puts "=======\nStarted importing results for #{council.name}"
    end
    next if row['WardName'].strip == "Total"
    if ward = wards.detect{ |w| TitleNormaliser.normalise_title(w.title) == TitleNormaliser.normalise_title(row['WardName']) }
      poll = ward.polls.find_or_create_by_date_held("04-05-2006".to_date)
      voting_attribs = { :position => 'Member',
                         :electorate => row['Electorate'].gsub(',',''), 
                         :postal_votes => row['PostalVotes']&&row['PostalVotes'].gsub(',',''), 
                         :ballots_rejected => row['RejectedBallots'] }
      voting_attribs[:ballots_issued] = (row['PostalVotes']&&row['PostalVotes'].gsub(',','')).to_i + row['VotesInPerson'].gsub(',','').to_i
      poll.update_attributes(voting_attribs)
      puts "Updated results for #{ward.name}: #{voting_attribs.inspect}"
    else
      puts "****Can't match: #{row['WardName']}"
    end
  end  
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

desc "Get details for Political Parties on Electoral Commission list"
task :get_details_for_electoral_commission_parties => :environment do
  require 'hpricot'
  PoliticalParty.all.each do |party|
    alternative_names = []
    data = Hpricot(open(party.electoral_commission_url)).at('table.datatable')
    alternative_names << data.at('tr[text()*="Other name"] td:last-of-type').try(:inner_text)
    alternative_names += data.search('tr[text()*="Party description"]~tr>td:not([strong|table])').collect{ |d| d.inner_text.to_s.gsub(/\302\240/, '').strip }
    alternative_names = alternative_names.delete_if { |n| n.blank? }.uniq - [party.name]
    party.update_attribute(:alternative_names, alternative_names) unless alternative_names.blank?
    puts "Added alternative_names to #{party.name}: #{alternative_names.inspect}"
  end
end

desc "Match candidacies and members"
task :match_candidacies_and_members => :environment do
  Candidacy.all(:conditions => {:member_id => nil, :elected => true}, :include => :poll).each do |candidacy|
    next unless (ward = candidacy.poll.area) && ward.is_a?(Ward) # don't want councils
    members = ward.members.select{ |m| m.last_name.downcase == candidacy.last_name.downcase }
    if members.empty?
      puts "Failed to match members against candidacy (#{candidacy.first_name} #{candidacy.last_name})"
      next
    elsif members.size == 1
      member = members.first
    elsif members.size > 1 && poss_members = members.select{|m| m.first_name.split(' ').first == candidacy.first_name.split(' ').first} #see if we can match first, first names
      if poss_members.size != 1
        puts "*** Matched more than one member to candidacy (#{candidacy.first_name} #{candidacy.last_name}): #{members.collect(&:full_name)}"
        next
      else
        member = poss_members.first
      end
    end
    member.candidacies << candidacy
    member.update_attribute(:date_elected, candidacy.poll.date_held) unless member.date_elected? && candidacy.poll.date_held < 4.years.ago.to_date
    puts "Matched candidacy (#{candidacy.first_name} #{candidacy.last_name}, #{candidacy.poll.date_held.to_s(:event_date)}) with member (#{members.first.full_name})"
  end
end

desc "Search Wikipedia For Political Parties"
task :search_wikipedia_for_parties => :environment do
  require 'hpricot'
  base_url = "http://en.wikipedia.org/w/index.php?fulltext=Search&search="
  PoliticalParty.find_all_by_wikipedia_name(nil).each do |party|
    client = HTTPClient.new
    content = client.get_content("http://en.wikipedia.org/w/index.php?fulltext=Search&search="+URI.escape(party.name), nil, "User-Agent" => "Mozilla/4.0 (OpenlyLocal.com)")
    poss_parties = Hpricot(content).search('.mw-search-results li>a')
    puts "\n========\nPossible matches for #{party.name}\n"
    poss_parties[0..4].each_with_index do |poss_party, i|
      puts "  #{i+1}. #{poss_party.inner_text}  - http://en.wikipedia.org#{poss_party[:href]}\n"
    end
    puts "Please choose correct answer -- enter number, n for next(default), q to quit:"
    response = $stdin.gets.chomp
    next if response == "n" || response.empty?
    break if response == "q"
    chosen_party = response.to_i
    wikipedia_name = poss_parties[chosen_party-1][:href].sub(/^\/wiki\//,'')
    party.update_attribute(:wikipedia_name, wikipedia_name)
    puts "Updated #{party.name} with Wikipedia name (#{wikipedia_name})"
  end
end

