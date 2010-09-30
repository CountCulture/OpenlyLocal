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
  FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/csv_data/ProClass_vC10.1.csv"), :headers => true) do |row|
    next if row['C10.1N'].blank?
    levels = [row["Top Level"],row["Level 2"],row["Level 3"]].compact
    Classification.create!(
    :grouping => 'Proclass10.1',
    :uid => row['C10.1N'],
    :title => levels.last,
    :extended_title => levels.join(' > '))
    print '.'
  end
end

