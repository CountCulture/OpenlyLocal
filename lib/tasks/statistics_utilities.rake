desc "Get Ness Subjects and datasets"
task :get_ness_subject_and_datasets => :environment do
  driver = NessUtilities::DiscoveryClient.driver
  driver.wiredump_dev = STDOUT
  st = driver.GetSubjectTree('')
  branches = st.subjectTree.branch
  branches.each do |branch|
    subj = branch.subject
    subj = OnsSubject.find_or_create_by_ons_uid_and_title(subj.subjectId, subj.name)

    puts "added/found subject: #{subj.title} (#{subj.ons_uid})"
    datasets = branch.dSFamilies.dSFamily
    puts "about to add #{datasets.size} datasets for this subject"
    datasets.each do |dataset_data|
      p dataset_data
        dsf = DatasetFamily.find_or_create_by_ons_uid(:ons_uid => dataset_data.dSFamilyId, :title => dataset_data.name)
        subj.dataset_families << dsf unless subj.dataset_families.include?(dsf)
        puts "successfully added/found dataset_family #{dsf.title} (#{dsf.ons_uid})"
        data_ranges = [dataset_data.dateRange].flatten #could be single date_range or array of them
        data_ranges.each do |date_range|
          dataset = dsf.ons_datasets.find_or_create_by_start_date(:end_date => date_range.endDate, :start_date => date_range.startDate)
          puts "successfully added/found dataset for #{dsf.title}: #{dataset.start_date}-#{dataset.end_date}"
        end
    end
  end
end

desc "Get Ness Ids for Councils"
task :get_ness_ids => :environment do
  councils = Council.all(:conditions => 'snac_id IS NOT NULL AND ness_id IS NULL')
  wards = Ward.all(:conditions => 'snac_id IS NOT NULL AND ness_id IS NULL')

  puts "About to get Ness IDs for #{councils.size} councils and #{wards.size} wards\n==========="
  (councils+wards).each do |area|
    client = NessUtilities::RawClient.new('SearchAreaByCode', [['Code', area.snac_id]])
    begin
      data = client.process
      ness_id = data.at('HierarchyId[text()="18"]').parent.at('AreaId').inner_text
      puts "#{area.title} (#{area.class}, #{area.snac_id}) Ness id: #{ness_id}"
      area.update_attribute(:ness_id, ness_id)
    rescue Exception => e
      puts "Problem getting Ness Id for #{area.title}: #{data.inspect}"
    end
  end
end

desc "Get Ness Dataset topics"
task :get_ness_dataset_topics => :environment do
  datasets = DatasetFamily.all
  datasets.each do |dataset|
    client = NessUtilities::RawClient.new('VariableFamilies', [['DSFamilyId', dataset.ons_uid]])
    begin
      data = client.process
      topics = data.search('VarFamily')
      puts "Found #{topics.size} topics for #{dataset.title}\n======="
      topics.each do |topic|
        ons_uid = topic.at('VarFamilyId').inner_text
        title = topic.at('Name').inner_text
        muid = topic.at('MUId').inner_text
        data_date = topic.at('EndDate').inner_text
        topic_record = dataset.dataset_topics.find_or_initialize_by_ons_uid(ons_uid)
        topic_record.update_attributes(:title => title, :muid => muid, :data_date => data_date)
        puts "Found/Updated #{title} (ons_uid: #{ons_uid}, muid: #{muid}, data_date: #{data_date})"
      end
    rescue Exception => e
      puts "Problem getting topics for #{dataset.title}: #{e.inspect}"
    end
  end
end

desc "Import Local Spending 2006-2007"
task :import_local_spending => :environment do
  require 'pp'
  spending_dataset = Dataset.create!(  :title => "Local Spending Report England 2006-07", 
                                                  :url => "http://www.communities.gov.uk/publications/corporate/statistics/localspendingreports200607", 
                                                  :originator => "Department of Communities and Local Government", 
                                                  :originator_url => "http://www.communities.gov.uk/")
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/spending_report_2006_07_raw_data.csv")).to_a[1..-1] # skip first row for the moment
  families = rows.shift[2..-1]
  topics = rows.shift[2..-1]
  p families, topics
  ons_families = families.collect{ |f| DatasetFamily.find_or_create_by_title_and_source_type(:title => "#{f.strip} spending", :source_type => "Spending", :dataset => spending_dataset, :calculation_method => "sum") }
  ons_topics = []
  
  topics.each_with_index{ |t,i| ons_topics << ons_families[i].dataset_topics.find_or_create_by_title(:title => "#{t.strip} spending", :muid => 9, :data_date => "2007-04-04") }

  pp ons_families, ons_topics
  
  rows.each do |row|
    if council = Council.find_by_cipfa_code(row[0])
      row[2..-1].each_with_index do |raw_dp, i|
        dp = council.datapoints.find_or_initialize_by_dataset_topic_id(:dataset_topic_id => ons_topics[i].id, :value => raw_dp.to_i*1000)
        begin
          dp.save!
        rescue Exception => e
          puts "Problem saving: #{dp.inspect}"
        end  
      end
      puts "Finished adding datapoints for #{council.name}"
    else
      puts "Could not find entry for #{row[1]} (cipfa_code #{row[0]})"
    end
  end
end

desc "Add Dataset relationships"
task :add_dataset_relationships => :environment do
  ness_dataset = Dataset.create!(  :title => "ONS Neighbourhood Statistics", 
                                              :url => "http://www.neighbourhood.statistics.gov.uk/", 
                                              :originator => "Office for National Statistics", 
                                              :originator_url => "http://www.statistics.gov.uk/")
  DatasetFamily.update_all({:dataset_id => ness_dataset.id}, :source_type => 'Ness')
end

desc "Convert NessSelectedTopics top topic_groupings"
task :convert_ness_selected_topics_to_groupings => :environment do
  NessSelectedTopics.each do |key, value|
    grouping = DatasetTopicGrouping.find_or_create_by_title(key.to_s, :display_as => DisplayDatapoints[key])
    grouping.dataset_topics << DatasetTopic.find_all_by_ons_uid(value)
    p grouping.dataset_topics
  end
end

desc "get NessSelectedTopic info for councils"
task :get_ness_selected_topic_info_for_councils => :environment do
  topic_ids = NessSelectedTopics.values.flatten
  
  Council.find_in_batches(:conditions => "ness_id IS NOT NULL", :batch_size => 10) do |councils|
    puts "About to query Ness server for info on #{councils.size} councils and the following topics: #{topic_ids.inspect}"
    raw_datapoints = NessUtilities::RawClient.new('Tables', [['Areas', councils.collect(&:ness_id)], ['Variables', topic_ids]]).process_and_extract_datapoints
    puts "Found #{raw_datapoints.size} raw datapoints for councils"
    raw_datapoints.each do |rdp|
      next unless council = councils.detect{|c| c.ness_id == rdp[:ness_area_id]}
      dp = DatasetTopic.find_by_ons_uid(rdp[:ness_topic_id]).datapoints.find_or_initialize_by_area_type_and_area_id('Council', council.id)
      dp.update_attributes(:value => rdp[:value])
      p dp
    end
  end
end

desc "get Bounding Boxes for councils"
task :get_bounding_boxes_for_councils => :environment do
  
  Council.all(:conditions => "ness_id IS NOT NULL").each do |council|
    begin
      raw_data = NessUtilities::RawClient.new('AreaDetail', [['AreaId', council.ness_id]]).process
      sw_e, sw_n, ne_e, ne_n = raw_data.at('Envelope').inner_text.split(":")
    
      sw, ne = OsCoordsUtilities.convert_os_to_wgs84(sw_e, sw_n), OsCoordsUtilities.convert_os_to_wgs84(ne_e, ne_n)
      bounding_box = Polygon.from_coordinates([[[sw[1], sw[0]], [sw[1], ne[0]], [ne[1], ne[0]], [ne[1], sw[0]], [sw[1], sw[0]]]])
      Boundary.create!(:area => council, :bounding_box=>bounding_box)
      puts "created boundary for #{council.name}"
    rescue Exception => e
      puts "problem creating boundary for #{council.name}: #{e.inspect}"
    end
    
  end
end

desc "get descriptions for Ness topics"
task :get_descriptions_for_ness_topics => :environment do
  
  DatasetTopic.all(:conditions => "ons_uid IS NOT NULL AND description IS NOT NULL").each do |topic|
    begin
      client = NessUtilities::RestClient.new(:getVariableDetail, :var_family_id => topic.ons_uid)
      info = client.response
    rescue Exception => e
      puts "Problem getting/processing data from #{client.request_url}: #{e.inspect}"
    end
    if description = info["VariableDetail"]["OptionalMetaData"]
      topic.update_attribute(:description, description)
    end
  end
end

desc "Import SOCITM Better Connected Report 2010"
task :import_socitm_bc10 => :environment do
  require 'pp'
  dataset = Dataset.find_or_initialize_by_title(  :title => "SOCITM Better Connected 2010 website assessment", 
                              :url => "http://www.socitm.net/betterconnected", 
                              :originator => "SOCITM Insight", 
                              :originator_url => "http://www.socitm.net/")
  dataset.save!
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/socitm_bc10_tidied_up.csv")).to_a[1..-1] # skip first row
  families = rows.shift[5..-1]
  raw_topics = rows.shift[5..-1]
  muids = rows.shift[5..-1]
  families = families.collect{ |f| DatasetFamily.find_or_create_by_title_and_dataset_id(:title => f.strip, :source_type => "Misc", :dataset_id => dataset.id) }
  topics = []
  
  raw_topics.each_with_index{ |t,i| topics << families[i].dataset_topics.find_or_create_by_title(:title => t.strip, :data_date => "2010-03-01", :muid => muids[i]) }
  
  pp families, topics
  all_councils = Council.all
  value_match = {"y" => 1, "n" => 0, "n/a" => nil}
  rows.each do |row|
    if council = all_councils.detect{ |c| Council.normalise_title(c.name) == Council.normalise_title(row[1].gsub(/[A-Z]{2,}/, '')) }
      puts "Matched #{row[1]} with #{council.name}"
      row[5..-1].each_with_index do |raw_dp, i|
        value = topics[i].muid == 100 ? value_match[raw_dp.downcase] : raw_dp.to_i
        next unless value && dp = council.datapoints.find_or_initialize_by_dataset_topic_id(:dataset_topic_id => topics[i].id, :value => value)
        begin
          dp.save!
        rescue Exception => e
          puts "Problem saving: #{dp.inspect}"
        end  
      end
      puts "Finished adding datapoints for #{council.name}"
    else
      puts "*** Could not find entry for #{row[1]}"
    end
  end
end

desc "Import Output Area Classification List"
task :import_oac_list => :environment do
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/ons_data/output_area_classification_list.csv")).to_a[1..-1] # skip first row
  rows.each do |row|
    title, area_type, uid = row
    level = uid.split('.').size
    oac = OutputAreaClassification.find_or_create_by_area_type_and_uid(:area_type => area_type, :uid => uid, :title => title, :level => level)
    puts "Successfully added/updated Output Area Classification: #{oac.inspect}"
  end
end

desc "Import Council Output Area Classifications"
task :import_council_oacs => :environment do
  oacs = OutputAreaClassification.all
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/ons_data/oacs_for_councils.csv"), :headers => true).each do |row|
    if council = Council.find_by_snac_id(row['Code'])
      oac = oacs.detect{ |oac| oac.uid == row['Subgroups'] && oac.area_type == 'Council' }
      council.update_attribute(:output_area_classification, oac)
      puts "Updated #{council.name} with output_area_classification: #{oac.inspect}"
    else
      puts "**Could not find council with snac id #{row['Code']}"
    end
  end
end

desc "Import Ward Output Area Classifications"
task :import_ward_oacs => :environment do
  oacs = OutputAreaClassification.all(:conditions => {:area_type => 'Ward'})
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/ons_data/oacs_for_wards.csv"), :headers => true).each do |row|
    oac = oacs.detect{ |oac| oac.uid == row['Subgroup'] }
    if ward = Ward.find_by_snac_id(row['Wardcode'])
      ward.update_attribute(:output_area_classification, oac)
      puts "Updated #{ward.name} with output_area_classification: #{oac.inspect}"
    elsif (council = Council.find_by_snac_id(row['Wardcode'][0..3])) && council.wards.count > 0
      begin
        Ward.create!(:defunkt => true, :council => council, :snac_id => row['Wardcode'], :name => row['Wardname'], :output_area_classification => oac) # can't use council.wards as this restricts to current wards
        puts "+++++Added #{row['Wardname']} as new defunkt ward (SNAC id = #{row['Wardcode']})"
      rescue Exception => e
        puts "*******ERROR adding #{row['Wardname']} as new defunkt ward (SNAC id = #{row['Wardcode']}): #{e.inspect}"
      end
    else
      puts "**Could not find ward (#{row['Wardname']}) with snac id #{row['Wardcode']} and could not find matching council either"
    end
  end
end