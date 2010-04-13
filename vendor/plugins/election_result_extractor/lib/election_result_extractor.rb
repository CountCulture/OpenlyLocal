module ElectionResultExtractor
  require 'rdf_utilities'
  
  extend self
  ca_mapping = {RDF::FOAF.given_name => :given_name }
  
  class ExtractorError < StandardError; end
  
  def landing_page_for(council)
    resp = open("http://local.direct.gov.uk/LDGRedirect/index.jsp?LGSL=721&LGIL=8&AgencyId=#{council.ldg_id}&Type=Single")
    resp.base_uri.to_s
  rescue Exception => e
    raise ExtractorError, "Error retreving election landing page(#{e.message}).\nIs is registered with LocalDirectGov?"
  end
      
  def election_pages_from(landing_page)
    graph = RdfUtilities.graph_from(landing_page)
    graph.query(:object => openelection.Election).collect do |election|
      graph.query(:subject => election.subject, :predicate => RDF::FOAF.isPrimaryTopicOf).first.object.to_s
    end
  end 
      
  def poll_pages_from(election_page)
    graph = RdfUtilities.graph_from(election_page)
    graph.query(:object => openelection.Poll).collect do |poll|
      graph.query(:subject => poll.subject, :predicate => RDF::FOAF.isPrimaryTopicOf).first.object.to_s
    end
  end 
      
  def poll_results_from(poll_page)
    graph = RdfUtilities.graph_from(poll_page)
    poll_list = graph.query([nil, nil, openelection.Poll])
    polls = poll_list.collect do |poll|
      uri = poll.subject.to_s
      area = graph.query([poll.subject, openelection.electionArea, nil]).first.object.to_s
      date = graph.query([poll.subject, RDF::URI.new('http://www.w3.org/2002/12/cal#dtstart'), nil]).first.object.value
      ballots_issued = graph.query([poll.subject, openelection.ballotsIssued, nil]).first.object.value rescue nil
      electorate = graph.query([poll.subject, openelection.electorate, nil]).first.object.value rescue nil
      uncontested = graph.query([poll.subject, openelection.uncontested, nil]).first.object.value rescue nil
      candidacies = graph.query([poll.subject, openelection.candidacy, nil]).collect do |candidacy|
        party = graph.query([candidacy.object, openelection.party, nil]).first.object.to_s rescue nil
        votes = graph.query([candidacy.object, openelection.candidateVoteCount, nil]).first.object.value rescue nil
        elected = graph.query([candidacy.object, openelection.elected, nil]).first.object.value rescue nil
        independent = graph.query([candidacy.object, openelection.independentCandidate, nil]).first.object.value rescue nil
        candidate = graph.query([candidacy.object, openelection.candidate, nil]).first.object rescue nil        
        name = graph.query([candidate, RDF::FOAF.name, nil]).first.object.value rescue nil
        given_name = graph.query([candidate, RDF::FOAF.givenName, nil]).first.object.value rescue nil
        family_name = graph.query([candidate, RDF::FOAF.familyName, nil]).first.object.value rescue nil

        address = graph.query([candidate, openelection.address, nil]).first.object rescue nil
        if address
          address = %w(street_address locality region postal_code).inject({}) do |h,a|
            h[a.to_sym] = graph.query([address, vcard[a.gsub('_','-')], nil]).first.object.value rescue nil
            h
          end
        end
        {:party  => party, :name => name, :given_name => given_name, :family_name => family_name, :votes => votes, :elected => elected, :independent => independent, :address => address }
      end
    { :uri => uri, :area => area, :date => date, :electorate => electorate, :ballots_issued => ballots_issued, :uncontested => uncontested, :source => poll_page, :candidacies => candidacies }
    end
  rescue Exception => e
    raise ExtractorError, "Error getting/parsing election results (#{e.message}) "
  end
  
  def poll_results_for(council)
    status, poll_count, elections = [], 0, []
    landing_page = landing_page_for(council)
    status << "Landing page found"
    election_pages = election_pages_from(landing_page)
    status << "#{election_pages.size} election(s) found"
    results = {}
    elections = election_pages.each do |election_page|
      poll_pages = poll_pages_from(election_page)
      poll_count += poll_pages.size
      polls = poll_pages.collect do |poll_page|
         poll_results_from(poll_page)
      end.flatten
      results[election_page] = polls
    end
    status << "#{poll_count} polls found"
    { :results => results, :status => status }
  rescue ExtractorError => e
    {:errors => e.message, :status => status }
  end
  
  private
  def openelection
    RDF::Vocabulary.new('http://openelectiondata.org/0.1/')
  end
  
  def vcard
    RDF::Vocabulary.new('http://www.w3.org/2006/vcard/ns#')
  end
end