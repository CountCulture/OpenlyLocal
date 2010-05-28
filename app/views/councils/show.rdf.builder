xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:vCard" => "http://www.w3.org/2001/vcard-rdf/3.0#",
         "xmlns:owl"   => "http://www.w3.org/2002/07/owl#",
         "xmlns:geonames" => "http://www.geonames.org/ontology#",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
           
  # basic info about this resource         
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@council) do
    xml.tag! "rdfs:label", @council.title
    xml.tag! "rdf:type", "rdf:resource" => "openlylocal:#{@council.authority_type.gsub(/\s+/,'')}Authority"
    xml.tag! "owl:sameAs", "rdf:resource" => "http://statistics.data.gov.uk/id/local-authority/#{@council.snac_id}" unless @council.snac_id.blank?
    xml.tag! "administrative-geography:coverage", "rdf:resource" => "http://data.ordnancesurvey.co.uk/id/#{@council.os_id}" unless @council.os_id.blank?
    xml.tag! "owl:sameAs", "rdf:resource" => @council.dbpedia_resource unless @council.dbpedia_resource.blank?
    xml.tag! "foaf:phone", @council.foaf_telephone unless @council.foaf_telephone.blank?
    xml.tag! "foaf:homepage", @council.url unless @council.url.blank?
    
    unless @council.address.blank?
      xml.tag! "vCard:ADR", "rdf:parseType" => "Resource" do
        xml.tag! "vCard:Extadd", @council.address
        xml.tag! "vCard:Country", @council.country 
      end
    end
    unless @council.twitter_account_name.blank?
      xml.tag! "foaf:holdsAccount" do
        xml.tag! "foaf:OnlineAccount", "rdf:about" => "http://twitter.com/#{@council.twitter_account_name}" do
          xml.tag! "foaf:accountServiceHomepage", "rdf:resource" => "http://twitter.com/"
          xml.tag! "foaf:accountName", @council.twitter_account_name
        end
      end
    end
    
    # xml.tag! "geonames:population", @council.population unless @council.population.blank?
    
    @council.wards.each do |ward|
      xml.tag! "openlylocal:Ward", "rdf:resource" => resource_uri_for(ward)
    end
    @committees.each do |committee|
      xml.tag! "openlylocal:LocalAuthorityCommittee", "rdf:resource" => resource_uri_for(committee)
    end
    @members.each do |member|
      xml.tag! "openlylocal:LocalAuthorityMember", "rdf:resource" => resource_uri_for(member)
    end
    # show child authorities if they exist
    @council.child_authorities.each do |ca|
      xml.tag! "openlylocal:isParentAuthorityOf", "rdf:resource" => resource_uri_for(ca)
    end
  end
  
  # show info on related items
  @council.wards.each do |ward|
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(ward) do
      xml.tag! "rdfs:label", ward.title
    end
  end
  @committees.each do |committee|
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(committee) do
      xml.tag! "rdfs:label", committee.title
    end
  end
  @members.each do |member|
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(member) do
      xml.tag! "rdfs:label", member.title
    end
  end
  
  # establish relationship with parent authority
  if @council.parent_authority
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@council.parent_authority) do
      xml.tag! "rdfs:label", @council.parent_authority.title
      xml.tag! "openlylocal:isParentAuthorityOf", "rdf:resource" => resource_uri_for( @council)
    end
  end
  
  # establish relationship with police_force
  if @council.police_force
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@council.police_force) do
      xml.tag! "rdfs:label", @council.police_force.title
      xml.tag! "openlylocal:isPoliceForceFor", "rdf:resource" => resource_uri_for( @council)
    end
  end
  
  # show info on child authorities
    @council.child_authorities.each do |ca|
      xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(ca) do
        xml.tag! "rdfs:label", ca.title
      end
    end
  
  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => council_url(:id => @council.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@council)
    xml.tag! "dct:title", "Information about #{@council.name}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @council.created_at
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @council.updated_at
    # show alt representations for council
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => council_url(:id => @council.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => council_url(:id => @council.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => council_url(:id => @council.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@council)
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@council.name}"
    end
  end
  
end
