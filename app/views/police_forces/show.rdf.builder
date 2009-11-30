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
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@police_force) do
    xml.tag! "rdfs:label", @police_force.name
    xml.tag! "owl:sameAs", "rdf:resource" => @police_force.dbpedia_resource unless @police_force.dbpedia_resource.blank?
    xml.tag! "foaf:homepage", @police_force.url unless @police_force.url.blank?
    xml.tag! "foaf:phone", @police_force.foaf_telephone unless @police_force.foaf_telephone.blank?
    unless @police_force.address.blank?
      xml.tag! "vCard:ADR", "rdf:parseType" => "Resource" do
        xml.tag! "vCard:Extadd", @police_force.address
      end
    end
    
    # show related councils
    @police_force.councils.each do |council|    
      xml.tag! "openlylocal:isPoliceForceFor", "rdf:resource" => resource_uri_for(council)
    end

  end
  
  # show info on related councils
  @police_force.councils.each do |council|
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(council) do
      xml.tag! "rdfs:label", council.title
    end
  end
  
  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => police_force_url(:id => @police_force.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@police_force)
    xml.tag! "dct:title", "Information about #{@police_force.name}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @police_force.created_at
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @police_force.updated_at
    # show alt representations for police_force
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => police_force_url(:id => @police_force.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => council_url(:id => @police_force.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => council_url(:id => @police_force.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@police_force)
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@police_force.name}"
    end
  end
  
end
