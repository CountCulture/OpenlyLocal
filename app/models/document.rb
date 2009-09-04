class Document < ActiveRecord::Base
  validates_presence_of :body
  validates_presence_of :url
  validates_uniqueness_of :url, :scope => :document_type
  belongs_to :document_owner, :polymorphic => true
  before_validation :sanitize_body
  
  def document_type
    self[:document_type] || "Document"
  end
  
  def precis
    stripped_text = ActionController::Base.helpers.strip_tags(body).gsub(/[\t\r\n]+ *[\t\r\n]+/,"\n")
    ActionController::Base.helpers.truncate(stripped_text, :length => 500)
  end
  
  def title
    self[:title] || "#{document_type} for #{document_owner.title}"
  end
  
  def extended_title
    self[:title] || "#{document_type} for #{document_owner.extended_title}"
  end
  
  protected
  def sanitize_body
    return if raw_body.blank?
    uncommented_body = raw_body.gsub(/<\!--.*?-->/mi, '').gsub(/<\!\[.*?\]>/mi, '') # remove comments otherwise they are escape by sanitizer and show in browser
    sanitized_body = ActionController::Base.helpers.sanitize(uncommented_body)
    base_url = url&&url.sub(/\/[^\/]+$/,'/')
    doc = Hpricot(sanitized_body)
    doc.search("a[@href]").each do |link|
      link[:href].match(/^http:/) ? link : link.set_attribute(:href, "#{base_url}#{link[:href]}")
      link.set_attribute(:class, 'external')
    end
    doc.search('img').remove
    self.body = doc.to_html
  end
end
