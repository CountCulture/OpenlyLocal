xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:vCard" => "http://www.w3.org/2001/vcard-rdf/3.0#",
         "xmlns:owl"   => "http://www.w3.org/2002/07/owl#",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
  Council.all.each do |council|
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(council) do
      xml.tag! "rdfs:label", council.title
    end
  end
  
end