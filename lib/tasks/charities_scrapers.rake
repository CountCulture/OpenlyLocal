require 'tempfile'
desc "Populate UK Charities"
task :populate_charities => :environment do
  local_auth_list_page = Hpricot(open('http://www.charitycommission.gov.uk/ShowCharity/registerofcharities/mapping/Search.aspx'))
  local_auth_list = local_auth_list_page.search('#ctl00_MainContent_ddlLA option')[1..-1].collect{|la| [la.inner_text, la[:value]]}
  puts "Found #{local_auth_list.size} authorities"
  local_auth_list.each do |la|
    begin
      puts "\n==================\nAbout to start getting charities in #{la.first}"
      url = "http://www.charitycommission.gov.uk/ShowCharity/registerofcharities/mapping/Map.aspx?ResultType=1&LocalAuthorityId=#{la.last}&Parameter=#{la.first.gsub(/\s/,'%20')}"
      results_page = Hpricot(open(url))
      charities = results_page.search('#charities_oDataList td.name span').collect{|e| [e.inner_text.scan(/^\d+/).to_s, e.inner_text.scan(/\d - (.+)/).to_s.squish] }
      puts "Found #{charities.size} charities:"
      charities.each { |c| create_charity(c) }
      client = HTTPClient.new
      next unless (no_of_pages = results_page.at('input#charities_hiddenPagesCount')[:value].to_i) > 1
      puts "About to fetch results from #{no_of_pages} more pages"
      no_of_pages.times do |i|
        viewstate = results_page.at('input#__VIEWSTATE')[:value]
        eventvalidation = results_page.at('input#__EVENTVALIDATION')[:value]
        results_page = Hpricot(client.post(url, "charities$hiddenPagesCount" => no_of_pages, "charities$hiddenCurrentPage" => i+1, "charities$btnGoToNext" => 'Next >', "__EVENTVALIDATION" => eventvalidation, "__VIEWSTATE" => viewstate).content)
        new_charities = results_page.search('#charities_oDataList td.name span').collect{|e| [e.inner_text.scan(/^\d+/).to_s, e.inner_text.scan(/\d - (.+)/).to_s.squish] }
        "Found #{new_charities.size} more charities:"
        new_charities.each do |c|
          create_charity(c)
        end
      end
    rescue Exception => e
      puts "**** Problem getting/parsing data: #{e.inspect}"
    end
  end
end


desc "Get Missing Charities"
task :get_missing_charities => :environment do
  %w(reg_now rem91).each do |file_name|
    File.open(File.join(RAILS_ROOT, "db/data/charities/#{file_name}.txt")).each do |file|
      file.each_line do |line|
        unless Charity.find_by_charity_number(charity_number = line.squish)
          puts "Getting details for missing charity (#{charity_number})"
          begin
            c = Charity.new(:charity_number => charity_number)
            if c.update_info
              puts "Added details for #{c.title}"
            else
              puts "Problem adding details for charity: #{c.errors.to_json}"
            end
          rescue Exception => e
            puts "**** Problem getting info for charity: #{e.inspect}"
          end
        end
      end
    end
    
  end
  base_url = "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/"
end

desc "Catch up newly created charities"
task :catch_up_with_new_charities => :environment do
  days_ago = 2
  charities, unsaved_charity_count = [],1 # give new_charity_count non-zero value so loop runs at least once
  while charities.size != unsaved_charity_count # keep going unless all the charities returned are already in db 
    start_date = (days_ago+4).days.ago.to_date
    end_date = days_ago.days.ago.to_date
    puts "About to get charities from #{start_date} to #{end_date}"
    charities = Charity.add_new_charities(:start_date => start_date, :end_date => end_date)
    unsaved_charity_count = charities.select{|c| c.new_record?}.size
    puts "Found #{charities.size} charities, #{charities.size - unsaved_charity_count} of them new"
    days_ago += 3
  end 
  
end

desc "Import Charity Classification Types"
task :import_charity_class_types => :environment do
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/charities/extract_class_ref.bcp"), :headers => false, :col_sep => "@**@") do |row|
    c=Classification.find_or_initialize_by_grouping_and_uid('CharityClassification', row[0])
    c.update_attribute(:title, row[1])
  end
  
end

desc "Import Data from Charity Register table"
task :import_charity_table => :environment do
  file = clean_data_file(File.join(RAILS_ROOT, "db/data/charities/extract_charity.bcp"))
  file.open
  FasterCSV.new(file, :col_sep => "@@@@", :row_sep=>"*@@*").each do |row|
    attribs = {}
    charity_number = (row[1] != '0') ? "#{row[0]}-#{row[1]}" : row[0]

    attribs[:subsidiary_number] = (row[1] != '0' ? row[1] : nil )
    attribs[:title] = replace_dummy_linebreaks_and_quotes(row[2])
    attribs[:governing_document] = replace_dummy_linebreaks_and_quotes(row[4])
    attribs[:area_of_benefit] = replace_dummy_linebreaks_and_quotes(row[5])
    attribs[:housing_association_number] = replace_dummy_linebreaks_and_quotes(row[8])
    attribs[:contact_name] = replace_dummy_linebreaks_and_quotes(row[9])
    attribs[:address_in_full] = (10..15).collect{ |i| replace_dummy_linebreaks_and_quotes(row[i])}.join(', ')
    attribs[:telephone] = replace_dummy_linebreaks_and_quotes(row[16])
    attribs[:fax] = replace_dummy_linebreaks_and_quotes(row[17])
    if charity = Charity.find_by_charity_number(charity_number)
      charity.update_attributes(attribs)
      puts "***Udated existing charity: #{charity.title} (#{charity.charity_number})"
    else
      Charity.create!(attribs.merge(:charity_number => charity_number))
      puts "Added new charity: #{attribs[:title]} (#{charity_number})"
    end
  end
  
  file.close
end

desc "Import Data from Charity details table"
task :import_charity_details=> :environment do
  file = clean_data_file(File.join(RAILS_ROOT, "db/data/charities/extract_main_charity.bcp"))
  file.open
  FasterCSV.new(file, :col_sep => "@@@@", :row_sep=>"*@@*").each do |row|
    attribs = {}
    charity_number = row[0]

    attribs[:company_number] = replace_dummy_linebreaks_and_quotes(row[1])
    # attribs[:income] = replace_dummy_linebreaks_and_quotes(row[2])
    attribs[:email] = replace_dummy_linebreaks_and_quotes(row[8])
    attribs[:website] = replace_dummy_linebreaks_and_quotes(row[9])
    if charity = Charity.find_by_charity_number(charity_number)
      charity.update_attributes(attribs)
      puts "***Udated existing charity: #{charity.title} (#{charity.charity_number})"
    else
      puts "****Alert can't find charity with number: #{charity_number}"
      break
    end
  end
  file.close
end

desc "Import Charity classification associations"
task :import_charity_classifications=> :environment do
  ClassificationLink.destroy_all(:classified_type => 'Charity') # flush existing ones
  classification_types = Classification.find_all_by_grouping('CharityClassification')
  file = clean_data_file(File.join(RAILS_ROOT, "db/data/charities/extract_class.bcp"))
  file.open
  previous_charity = Charity.first
  FasterCSV.new(file, :col_sep => "@@@@", :row_sep=>"*@@*").each do |row|
    attribs = {}
    charity = (previous_charity.charity_number == row[0]) ? previous_charity : Charity.find_by_charity_number(row[0])
    classification = classification_types.detect{|t| t.uid == row[1]}
    charity.classifications << classification
    print '.'
  end
  
  file.close
end



def create_charity(c)
  unless Charity.find_by_charity_number(c.first)
    c = Charity.create!(:charity_number => c.first, :title => c.last)
    puts "Added new charity: #{c.title} (#{c.charity_number})"
  end
end

def clean_data_file(file)
  file_name = file.scan(/extract_([\w_]+)\.bcp/).to_s
  tf=Tempfile.new("#{file_name}_fixed")
  File.open(file) do |file|
    while (line = file.gets) do
      fixed_line = line.gsub(/@\*\*@/,'@@@@').gsub(/[\r\n]+/,'**linebreak**').gsub(/"/,'**aquote**')
      tf.print(fixed_line) # don't want line breaks so print rather than puts
    end
  end
  tf.close
  tf
end

def replace_dummy_linebreaks_and_quotes(text)
  return unless text
  text.gsub('**linebreak**', "\n").gsub('**aquote**', '"')
end
