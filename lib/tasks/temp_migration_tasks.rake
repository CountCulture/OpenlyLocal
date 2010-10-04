desc "Create precis from document bodies"
task :create_document_precis => :environment do
  Document.delete_all('document_owner_id IS NULL AND document_owner_type is NULL')
  Document.find_each(:conditions => {:precis => nil}, :batch_size => 10) do |document|
    if document.document_owner
    document.update_attribute(:precis, document.calculated_precis)
    else
      puts 'No document owner. Deleting document'
    end
  end
end

desc "Import Proclass classification"
task :import_proclass => :environment do
  %w(10.1 8.3).each do |version|
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/csv_data/ProClass_vC#{version}.csv"), :headers => true) do |row|
      next if row["C#{version}N"].blank?
      levels = [row["Top Level"],row["Level 2"],row["Level 3"]].compact
      Classification.create!(
      :grouping => "Proclass#{version}",
      :uid => row["C#{version}N"],
      :title => levels.last,
      :extended_title => levels.join(' > '))
      print '.'
    end
  end
end

desc "Import CPID entities"
task :import_cpid_entities => :environment do
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/csv_data/cpid_codes.csv"), :headers => true) do |row|
    next unless entity = Entity.find_by_normalised_title(Entity.normalise_title(row["Name"]))
    entity.update_attribute(:cpid_code, row["Code"])
    print '.'
  end
end

