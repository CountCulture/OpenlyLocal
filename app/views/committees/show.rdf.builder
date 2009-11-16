xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
  xml.tag! "rdf:Description", "rdf:about" => committee_url(:id => @committee.id) do
    xml.tag! "rdfs:label", @committee.title
    xml.tag! "rdf:type", "rdf:resource" => "openlylocal:LocalAuthorityCommittee"
    
    @committee.members.each do |member|
      xml.tag! "foaf:member", "rdf:resource" => member_url(:id => member.id)
    end
    
    @meetings.each do |meeting|
      xml.tag! "openlylocal:meeting", "rdf:resource" => meeting_url(:id => meeting.id)
    end
  end
  
  xml.tag! "rdf:Description", "rdf:about" => council_url(:id => @council.id) do
    xml.tag! "openlylocal:LocalAuthorityCommittee", "rdf:resource" => committee_url(:id => @committee.id)
  end
  
end
