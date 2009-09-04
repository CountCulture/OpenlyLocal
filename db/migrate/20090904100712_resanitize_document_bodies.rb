class ResanitizeDocumentBodies < ActiveRecord::Migration
  require 'hpricot'
  def self.up
    # just get ids first to avoid huge memory use
    Document.find(:all, :select => "id", :conditions => "raw_body LIKE '%<!%'").each do |doc|
      full_doc = Document.find(doc.id)
      full_doc.send(:sanitize_body)
      full_doc.save!
    end
  end

  def self.down
  end
end
