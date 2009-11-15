xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:rdf",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:owl"   => "http://www.w3.org/2002/07/owl#",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
  xml.tag! "rdf:Description", "rdf:about" => council_url(:id => @council.id) do
    xml.tag! "rdfs:label", @council.title
    xml.tag! "rdf:type", "rdf:resource" => "openlylocal:#{@council.authority_type.gsub(/\s+/,'')}Authority"
    xml.tag! "owl:sameas", "rdf:resource" => "http://statistics.data.gov.uk/doc/local-authority/#{@council.snac_id}" unless @council.snac_id.blank?
    xml.tag! "owl:sameas", "rdf:resource" => @council.dbpedia_url unless @council.dbpedia_url.blank?
    xml.tag! "foaf:address", @council.address unless @council.address.blank?
    xml.tag! "foaf:phone", @council.telephone unless @council.telephone.blank?
    xml.tag! "foaf:homepage", @council.url unless @council.url.blank?
    @wards.each do |ward|
      xml.tag! "openlylocal:Ward", "rdf:resource" => ward_url(:id => ward.id)
    end
  end
  @wards.each do |ward|
    xml.tag! "rdf:Description", "rdf:about" => ward_url(:id => ward.id) do
      xml.tag! "rdfs:label", ward.title
    end
  end
end
