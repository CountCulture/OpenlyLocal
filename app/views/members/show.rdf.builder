xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#",
         "xmlns:vCard" => "http://www.w3.org/2001/vcard-rdf/3.0#",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
  xml.tag! "rdf:Description", "rdf:about" => member_url(:id => @member.id) do
    xml.tag! "rdfs:label", @member.title
    xml.tag! "rdf:type", "rdf:resource" => "openlylocal:LocalAuthorityMember"
    xml.tag! "foaf:name", @member.full_name
    xml.tag! "foaf:page", @member.url
    xml.tag! "foaf:title", @member.name_title unless @member.name_title.blank?
    xml.tag! "foaf:phone", @member.foaf_telephone unless @member.foaf_telephone.blank?
    xml.tag! "foaf:mbox", "mailto:#{@member.email}" unless @member.email.blank?
    unless @member.address.blank?
      xml.tag! "vCard:ADR", "rdf:parseType" => "Resource" do
        xml.tag! "vCard:Extadd", @member.address
      end
    end
    
    @committees.each do |committee|
      xml.tag! "openlylocal:Committee", "rdf:resource" => committee_url(:id => committee.id)
    end
  end
  
  @committees.each do |committee|
    xml.tag! "rdf:Description", "rdf:about" => committee_url(:id => committee.id) do
      xml.tag! "foaf:member", "rdf:resource" => member_url(:id => @member.id)
    end
  end
  
  xml.tag! "rdf:Description", "rdf:about" => council_url(:id => @council.id) do
    xml.tag! "foaf:member", "rdf:resource" => member_url(:id => @member.id)
  end
  
end
