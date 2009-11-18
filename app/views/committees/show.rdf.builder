xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
           
  # basic info about this resource         
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@committee) do
    xml.tag! "rdfs:label", @committee.title
    xml.tag! "rdf:type", "rdf:resource" => "openlylocal:LocalAuthorityCommittee"
    # xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@committee)
    
    @committee.members.each do |member|
      xml.tag! "foaf:member", "rdf:resource" => resource_uri_for(member)
    end
    @meetings.each do |meeting|
      xml.tag! "openlylocal:meeting", "rdf:resource" => resource_uri_for(meeting)
    end
  end
  
  # show info on related items
  @committee.members.each do |member|
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(member) do
      xml.tag! "rdfs:label", member.title
    end
  end
  
  @meetings.each do |meeting|
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(meeting) do
      xml.tag! "rdfs:label", meeting.title
    end
  end
  
  # show relationship with council
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@council) do
    xml.tag! "openlylocal:LocalAuthorityCommittee", "rdf:resource" => resource_uri_for(@committee)
  end
  
  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => committee_url(:id => @committee.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@committee)
    xml.tag! "dct:title", "Information about #{@committee.title}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @committee.created_at
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @committee.updated_at
    # show alt representations for committee
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => committee_url(:id => @committee.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => committee_url(:id => @committee.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => committee_url(:id => @committee.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@committee)
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@committee.title}"
    end
  end
end
