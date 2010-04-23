xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title "#{@council.title}: #{@title}"
    xml.description "Committee meeting documents for #{@council.title}"
    xml.link documents_url(:format => :rss)
    
    for document in @documents
      xml.item do
        xml.title document.title
        xml.description document.precis
        xml.pubDate document.created_at.to_s(:rfc822)
        xml.link document_url(document)
        xml.guid document_url(document)
      end
    end
  end
end

