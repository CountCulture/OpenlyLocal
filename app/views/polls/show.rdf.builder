xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#",
         "xmlns:cal"   => "http://www.w3.org/2002/12/cal#",
         "xmlns:vCard" => "http://www.w3.org/2001/vcard-rdf/3.0#",
         "xmlns:openelection" => "http://openelectiondata.org/0.1/",
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/",
         "xmlns:dbpedia-owl" => "http://dbpedia.org/ontology/",
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
           
  # basic info about this resource         
  xml.tag! "rdf:Description", "rdf:about" => @poll.resource_uri do
    xml.tag! "rdf:type", "rdf:resource" => "openelection:Poll"
    xml.tag! "rdfs:label", "Electoral Poll for #{@poll.extended_title}"
    xml.tag! "openelection:electionArea", "rdf:resource" => @poll.area.resource_uri
    xml.tag! "cal:dtstart", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#date"}, @poll.date_held
    ( %w(electorate ballots_issued) + Poll::BallotRejectedCategories).each do |attrib|
      xml.tag! "openelection:#{attrib.camelize(:lower)}", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#integer"}, @poll.send(attrib) if @poll.send(attrib)
    end
    xml.tag! "openelection:rejectedBallots", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#integer"}, @poll.ballots_rejected if @poll.ballots_rejected
    xml.tag! "owl:sameAs", "rdf:resource" => "http://openelectiondata.org/id/polls/#{@poll.area.snac_id||('OL_' + @poll.area_id.to_s)}/#{@poll.date_held}/member"
  end

  # basic info about this page
  xml.tag! "rdf:Description", "rdf:about" => poll_url(:id => @poll.id) do
    xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
    xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
    xml.tag! "foaf:primaryTopic", "rdf:resource" => @poll.resource_uri
    xml.tag! "dct:title", "Electoral Poll for #{@poll.extended_title}"
    xml.tag! "dct:created", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @poll.created_at.xmlschema
    xml.tag! "dct:modified", {"rdf:datatype" => "http://www.w3.org/2001/XMLSchema#dateTime"}, @poll.updated_at.xmlschema
    # show alt representations for ward
    ResourceRepresentations.keys.each do |format|
      xml.tag! "dct:hasFormat", "rdf:resource" => poll_url(:id => @poll.id, :format => format)
    end
  end

  # show info for alt representations
  ResourceRepresentations.each do |format, mime_type|
    xml.tag! "rdf:Description", "rdf:about" => poll_url(:id => @poll.id, :format => format) do
      xml.tag! "dct:isFormatOf", "rdf:resource" => poll_url(:id => @poll.id)
      xml.tag! "foaf:primaryTopic", "rdf:resource" => @poll.resource_uri
      xml.tag! "rdf:type", "rdf:resource" => "http://purl.org/dc/dcmitype/Text"
      xml.tag! "rdf:type", "rdf:resource" => "http://xmlns.com/foaf/0.1/Document"
      xml.tag! "dct:format", mime_type
      xml.tag! "dct:title", "#{format == :rdf ? 'Linked ' : ''}Data in #{format.to_s.upcase} format for Electoral Poll for #{@poll.extended_title}"
    end
  end
 
end
           
