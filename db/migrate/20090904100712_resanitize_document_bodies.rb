class ResanitizeDocumentBodies < ActiveRecord::Migration
  require 'hpricot'
  def self.up
    # just get ids first to avoid huge memory use
    Document.find(:all, :select => "id", :conditions => "raw_body LIKE '%<!%' OR raw_body LIKE '%mailto:%'").each do |doc|
      full_doc = Document.find(doc.id)
      full_doc.send(:sanitize_body)
      p full_doc # so we can see any probs
      begin
        full_doc.save!
      rescue Exception => e
        puts "#{e.message}: destroying this record"
        full_doc.destroy # don't bother trying to fix problem, just delete record
      end
    end
  end

  def self.down
  end
end
