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
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@police_authority) do
    xml.tag! "rdfs:label", @police_authority.name
    xml.tag! "owl:sameAs", "rdf:resource" => @police_authority.dbpedia_resource unless @police_authority.dbpedia_resource.blank?
    xml.tag! "foaf:homepage", @police_authority.url unless @police_authority.url.blank?
    xml.tag! "foaf:phone", @police_authority.foaf_telephone unless @police_authority.foaf_telephone.blank?
    unless @police_authority.address.blank?
      xml.tag! "vCard:ADR", "rdf:parseType" => "Resource" do
        xml.tag! "vCard:Extadd", @police_authority.address
      end
    end
    
    # show related police_force
    xml.tag! "openlylocal:isPoliceAuthorityFor", "rdf:resource" => resource_uri_for(@police_authority.police_force)
  end
  
  # show info on related police_force
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@police_authority.police_force) do
    xml.tag! "rdfs:label", @police_authority.police_force.name
  end
  
  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => police_authority_url(:id => @police_authority.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@police_authority)
    xml.tag! "dct:title", "Information about #{@police_authority.name}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @police_authority.created_at
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @police_authority.updated_at
    # show alt representations for police_authority
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => police_authority_url(:id => @police_authority.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => council_url(:id => @police_authority.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => council_url(:id => @police_authority.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@police_authority)
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@police_authority.name}"
    end
  end
  
end
