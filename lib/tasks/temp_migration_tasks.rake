desc "Create precis from document bodies"
task :create_document_precis => :environment do
  Document.delete_all('document_owner_id IS NULL AND document_owner_type is NULL')
  Document.find_each(:batch_size => 10) do |document|
    document.update_attribute(:precis, document.calculated_precis)
  end
end
