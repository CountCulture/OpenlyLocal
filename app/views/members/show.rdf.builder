xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#",
         "xmlns:vCard" => "http://www.w3.org/2001/vcard-rdf/3.0#",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/",
         "xmlns:dbpedia-owl" => "http://dbpedia.org/ontology/",
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
           
  # basic info about this resource         
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@member) do
    xml.tag! "rdfs:label", @member.title
    xml.tag! "rdf:type", "rdf:resource" => "openlylocal:LocalAuthorityMember"
    xml.tag! "foaf:name", @member.full_name
    xml.tag! "foaf:page", @member.url
    xml.tag! "foaf:title", @member.name_title unless @member.name_title.blank?
    xml.tag! "foaf:phone", @member.foaf_telephone unless @member.foaf_telephone.blank?
    xml.tag! "foaf:mbox", "mailto:#{@member.email}" unless @member.email.blank?
    xml.tag!("dbpedia-owl:party", "rdf:resource" => @member.party.dbpedia_uri) unless @member.party.dbpedia_uri.blank?
    unless @member.address.blank?
      xml.tag! "vCard:ADR", "rdf:parseType" => "Resource" do
        xml.tag! "vCard:Extadd", @member.address
      end
    end
    unless @member.twitter_account.blank?
      xml.tag! "foaf:holdsAccount" do
        xml.tag! "foaf:OnlineAccount", "rdf:about" => "http://twitter.com/#{@member.twitter_account}" do
          xml.tag! "foaf:accountServiceHomepage", "rdf:resource" => "http://twitter.com/"
          xml.tag! "foaf:accountName", @member.twitter_account
        end
      end
    end
    
    @committees.each do |committee|
      xml.tag! "openlylocal:Committee", "rdf:resource" => resource_uri_for(committee)
    end
  end
  
  # show relationship with committees
  @committees.each do |committee|
    xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(committee) do
      xml.tag! "foaf:member", "rdf:resource" => resource_uri_for(@member)
    end
  end
  
  # show relationship with council
  xml.tag! "rdf:Description", "rdf:about" => resource_uri_for(@council) do
    xml.tag! "foaf:member", "rdf:resource" => resource_uri_for(@member)
  end
    
  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => member_url(:id => @member.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@member)
    xml.tag! "dct:title", "Information about #{@member.full_name}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @member.created_at
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @member.updated_at
    # show alt representations for member
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => member_url(:id => @member.id, :format => format)
    end
  end
  
  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => member_url(:id => @member.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => member_url(:id => @member.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => resource_uri_for(@member)
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for #{@member.full_name}"
    end
  end
end
