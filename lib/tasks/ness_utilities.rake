desc "Finds stale scrapers and runs them" 
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
