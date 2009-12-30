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
        dsf = OnsDatasetFamily.find_or_create_by_ons_uid(:ons_uid => dataset_data.dSFamilyId, :title => dataset_data.name)
        subj.ons_dataset_families << dsf unless subj.ons_dataset_families.include?(dsf)
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
  datasets = OnsDatasetFamily.all
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
        topic_record = dataset.ons_dataset_topics.find_or_initialize_by_ons_uid(ons_uid)
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
  spending_dataset = StatisticalDataset.create!(  :title => "Local Spending Report England 2006-07", 
                                                  :url => "http://www.communities.gov.uk/publications/corporate/statistics/localspendingreports200607", 
                                                  :originator => "Department of Communities and Local Government", 
                                                  :originator_url => "http://www.communities.gov.uk/")
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/spending_report_2006_07_raw_data.csv")).to_a[1..-1] # skip first row for the moment
  families = rows.shift[2..-1]
  topics = rows.shift[2..-1]
  p families, topics
  ons_families = families.collect{ |f| OnsDatasetFamily.find_or_create_by_title_and_source_type(f.strip, "Spending", :statistical_dataset => spending_dataset) }
  ons_topics = []
  
  topics.each_with_index{ |t,i| ons_topics << ons_families[i].ons_dataset_topics.find_or_create_by_title(:title => t.strip, :muid => 9, :data_date => "2007-04-04") }

  pp ons_families, ons_topics
  
  rows.each do |row|
    if council = Council.find_by_cipfa_code(row[0])
      row[2..-1].each_with_index do |raw_dp, i|
        dp = council.ons_datapoints.find_or_initialize_by_ons_dataset_topic_id(:ons_dataset_topic_id => ons_topics[i].id, :value => raw_dp.to_i*1000)
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
  ness_dataset = StatisticalDataset.create!(  :title => "ONS Neighbourhood Statistics", 
                                              :url => "http://www.neighbourhood.statistics.gov.uk/", 
                                              :originator => "Office for National Statistics", 
                                              :originator_url => "http://www.statistics.gov.uk/")
  OnsDatasetFamily.update_all("statistical_dataset_id = #{ness_dataset.id}", "source_type = 'Ness'")
end

desc "Convert NessSelectedTopics top topic_groupings"
task :convert_ness_selected_topics_to_groupings => :environment do
  NessSelectedTopics.each do |key, value|
    grouping = DatasetTopicGrouping.find_or_create_by_title(key.to_s, :display_as => DisplayOnsDatapoints[key])
    grouping.ons_dataset_topics << OnsDatasetTopic.find_all_by_ons_uid(value)
    p grouping.ons_dataset_topics
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
      dp = OnsDatasetTopic.find_by_ons_uid(rdp[:ness_topic_id]).ons_datapoints.find_or_initialize_by_area_type_and_area_id('Council', council.id)
      dp.update_attributes(:value => rdp[:value])
      p dp
    end
  end
end
