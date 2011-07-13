xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:owl"   => "http://www.w3.org/2002/07/owl#",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
           
  # basic info about this resource         
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@ward) do
    xml.tag! "rdfs:label", @ward.name
    xml.tag! "owl:sameAs", "rdf:resource" => "http://statistics.data.gov.uk/id/local-authority-ward/#{@ward.snac_id}" unless @ward.snac_id.blank?
    xml.tag! "owl:sameAs", "rdf:resource" => "http://data.ordnancesurvey.co.uk/id/#{@ward.os_id}" unless @ward.os_id.blank?
    xml.tag! "foaf:page", @ward.url unless @ward.url.blank?
  end
  
  # establish relationship with council
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@council) do
    xml.tag! "openlylocal:Ward", "rdf:resource" => resource_uri_for( @ward)
  end

  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => ward_url(:id => @ward.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@ward)
    xml.tag! "dct:title", "Information about #{@ward.name} ward"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @ward.created_at.xmlschema
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @ward.updated_at.xmlschema
    # show alt representations for ward
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => ward_url(:id => @ward.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => ward_url(:id => @ward.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => ward_url(:id => @ward.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@ward)
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@ward.name}"
    end
  end
  
end
