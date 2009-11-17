xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@committee) do
    xml.tag! "rdfs:label", @committee.title
    xml.tag! "rdf:type", "rdf:resource" => "openlylocal:LocalAuthorityCommittee"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@committee)
    
    @committee.members.each do |member|
      xml.tag! "foaf:member", "rdf:resource" => resource_uri_for(member)
    end
    
    @meetings.each do |meeting|
      xml.tag! "openlylocal:meeting", "rdf:resource" => resource_uri_for(meeting)
    end
  end
  
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@council) do
    xml.tag! "openlylocal:LocalAuthorityCommittee", "rdf:resource" => resource_uri_for(@committee)
  end
  
end
