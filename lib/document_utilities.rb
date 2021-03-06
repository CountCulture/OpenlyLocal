module DocumentUtilities
  extend self
  
  def sanitize(raw_text, options={})
    return if raw_text.blank?
    uncommented_body = raw_text.gsub(/<\!--.*?-->/mi, '').gsub(/<\!\[.*?\]>/mi, '') # remove comments otherwise they are escape by sanitizer and show in browser
    # sanitized_body = ActionController::Base.helpers.sanitize(uncommented_body)
    # doc = Hpricot(sanitized_body)
    doc = Nokogiri::HTML::DocumentFragment.parse(uncommented_body)
    base_url = options[:base_url]&&options[:base_url].sub(/\/[^\/]+$/,'/')
    doc.css("a[@href]").each do |link|
      (link['href'] = "#{base_url}#{link[:href]}") if base_url && !link[:href].match(/^http:|^mailto:/)
      link['class'] ='external'
    end
    doc.search('img').remove
    doc.search('script').remove # sanitizer would just remove tags, not contents
    # p doc.to_html
    ActionController::Base.helpers.sanitize(doc.to_html)
  end
  
  def precis(raw_text)
    return if raw_text.blank?
    stripped_text = ActionController::Base.helpers.strip_tags(raw_text).gsub(/[\t\r\n]+ *[\t\r\n]+/,"\n")
    ActionController::Base.helpers.truncate(stripped_text, :length => 500)
  end
  
end