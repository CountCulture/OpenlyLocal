xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#",
         "xmlns:vCard" => "http://www.w3.org/2001/vcard-rdf/3.0#",
         "xmlns:vcal"  => "http://www.w3.org/2002/12/cal/icaltzd#",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
           
  # basic info about this resource         
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@meeting) do
    xml.tag! "rdfs:label", @meeting.title
    xml.tag! "rdf:type", "rdf:resource" => "openlylocal:meeting"
    xml.tag! "rdf:type", "rdf:resource" => "vcal:Vevent"
    xml.tag! "vcal:summary", @meeting.extended_title
    xml.tag! "vcal:dtstart", @meeting.date_held.to_s(:vevent)
    xml.tag! "vcal:location", @meeting.venue
  end
  
  # show relationship with committee
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@committee) do
    xml.tag! "openlylocal:meeting", "rdf:resource" => resource_uri_for(@meeting)
  end
    
  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => meeting_url(:id => @meeting.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@meeting)
    xml.tag! "dct:title", "Information about #{@meeting.extended_title}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @meeting.created_at
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @meeting.updated_at
    # show alt representations for meeting
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => meeting_url(:id => @meeting.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => meeting_url(:id => @meeting.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => meeting_url(:id => @meeting.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@meeting)
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@meeting.extended_title}"
    end
  end
end