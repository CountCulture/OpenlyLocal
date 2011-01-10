xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:owl"   => "http://www.w3.org/2002/07/owl#",
         "xmlns:vCard" => "http://www.w3.org/2001/vcard-rdf/3.0#",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
           
  # basic info about this resource         
  xml.tag! "rdf:Description", "rdf:about" => @company.resource_uri do
    xml.tag! "rdf:type", "rdf:resource" => "http://www.w3.org/ns/org/FormalOrganization"
    xml.tag! "rdfs:label", @company.title
    xml.tag! "foaf:homepage", @company.url if @company.url?
    if @company.address
      xml.tag! "vCard:ADR", "rdf:parseType" => "Resource" do
        xml.tag! "vCard:Extadd", @company.address_in_full
      end
    end
    
  end
  
  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => company_url(:id => @company.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => @company.resource_uri
    xml.tag! "dct:title", "Information about #{@company.title}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @company.created_at
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @company.updated_at
    # show alt representations for company
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => company_url(:id => @company.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => company_url(:id => @company.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => company_url(:id => @company.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => @company.resource_uri
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@company.title}"
    end
  end
  
end
