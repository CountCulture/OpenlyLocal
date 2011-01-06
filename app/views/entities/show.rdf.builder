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
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@entity) do
    xml.tag! "rdf:type", "rdf:resource" => "http://www.w3.org/ns/org/FormalOrganization"
    xml.tag! "rdfs:label", @entity.title
    xml.tag! "owl:sameAs", "rdf:resource" => @entity.dbpedia_resource unless @entity.dbpedia_resource.blank?
    xml.tag! "owl:sameAs", "rdf:resource" => @entity.external_resource_uri unless @entity.external_resource_uri.blank?
    xml.tag! "foaf:phone", @entity.foaf_telephone unless @entity.foaf_telephone.blank?
    xml.tag! "foaf:homepage", @entity.website if @entity.website?
    if @entity.address
      xml.tag! "vCard:ADR", "rdf:parseType" => "Resource" do
        xml.tag! "vCard:Extadd", @entity.address_in_full
      end
    end
    
  end
  
  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => entity_url(:id => @entity.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@entity)
    xml.tag! "dct:title", "Information about #{@entity.title}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @entity.created_at
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @entity.updated_at
    # show alt representations for entity
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => entity_url(:id => @entity.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => council_url(:id => @entity.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => council_url(:id => @entity.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@entity)
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@entity.title}"
    end
  end
  
end
