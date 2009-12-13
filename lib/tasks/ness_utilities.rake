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
      # begin
        dsf = OnsDatasetFamily.find_or_create_by_ons_uid(:ons_uid => dataset_data.dSFamilyId, :title => dataset_data.name)
        subj.ons_dataset_families << dsf unless subj.ons_dataset_families.include?(dsf)
        puts "successfully added/found dataset_family #{dsf.title} (#{dsf.ons_uid})"
        data_ranges = [dataset_data.dateRange].flatten #could be single date_range or array of them
        data_ranges.each do |date_range|
          dataset = dsf.ons_datasets.find_or_create_by_start_date(:end_date => date_range.endDate, :start_date => date_range.startDate)
          puts "successfully added/found dataset for #{dsf.title}: #{dataset.start_date}-#{dataset.end_date}"
        end
        # ds = subj.ons_datasets.create!( :title => dataset_data.name,
        #                               :ons_uid => dataset_data.dSFamilyId,
        #                               :start_date => dataset_data.dateRange.startDate,
        #                               :end_date => dataset_data.dateRange.endDate)
      # rescue Exception => e
        # "problem creating dataset #{e.inspect}"
      # end
    end
  end
end

desc "Get Ness Ids for Councils"
task :get_ness_ids => :environment do
  councils = Council.all(:conditions => 'snac_id IS NOT cdNULL')
  wards = Ward.all(:conditions => 'snac_id IS NOT NULL')

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
