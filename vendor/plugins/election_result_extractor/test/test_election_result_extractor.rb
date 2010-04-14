require 'test_helper'
require 'election_result_extractor'

class ElectionResultExtractorTest < Test::Unit::TestCase
  
  context 'when calculating landing_page for council' do
    setup do
      @council = stub(:ldg_id => 123) # stub Council behaviour
    end
    
    should 'try to follow LocalDirectGov redirect for election results' do
      ElectionResultExtractor.expects(:open).with("http://local.direct.gov.uk/LDGRedirect/index.jsp?LGSL=721&LGIL=8&AgencyId=123&Type=Single").returns(stub_everything)
      ElectionResultExtractor.landing_page_for(@council)
    end
    
    should 'return eventual uri from redirection' do
      ElectionResultExtractor.stubs(:open).with("http://local.direct.gov.uk/LDGRedirect/index.jsp?LGSL=721&LGIL=8&AgencyId=123&Type=Single").returns(stub(:base_uri => URI.parse('http://foo.com/bar')))
      assert_equal 'http://foo.com/bar', ElectionResultExtractor.landing_page_for(@council)
    end
    
    context 'and error following redirection' do
      should 'raise ExtractorError' do
        ElectionResultExtractor.stubs(:open).raises(Exception)
        assert_raise(ElectionResultExtractor::ExtractorError) { ElectionResultExtractor.landing_page_for(@council) }
      end
    end
  end
  
  context 'when getting elections from landing page' do
    setup do
      @dummy_response = dummy_response(:n3_landing_page)
      @dummy_graph = RDF::Graph.new
      RdfUtilities.stubs(:_http_get).returns(@dummy_response)
    end
    
    context 'in general' do
      setup do
        @results = ElectionResultExtractor.election_pages_from('http://foo.com/landing')
      end
      
      before_should 'build graph from given page' do
        RdfUtilities.expects(:graph_from).with('http://foo.com/landing').returns(@dummy_graph)
      end
      
      should 'return results' do
        assert_kind_of Array, @results
      end
      
      should 'return election_pages in results' do
        assert_equal 'http://www.lichfielddc.gov.uk/site/custom_scripts/electionresults.php?electionid=2', @results.first
      end
      
    end
  end
  
  context 'when getting polls from election page' do
    setup do
      @dummy_response = dummy_response(:n3_election_page)
      @dummy_graph = RDF::Graph.new
      RdfUtilities.stubs(:_http_get).returns(@dummy_response)
    end
    
    context 'in general' do
      setup do
        @results = ElectionResultExtractor.poll_pages_from('http://foo.com/election')
      end
      
      before_should 'build graph from given page' do
        RdfUtilities.expects(:graph_from).with('http://foo.com/election').returns(@dummy_graph)
      end
      
      should 'return results' do
        assert_kind_of Array, @results
        assert_equal 25, @results.size
      end
      
      should 'return election_pages in results' do
        assert @results.include?('http://www.lichfielddc.gov.uk/site/custom_scripts/viewelection.php?pollid=21'), @results.first
      end
      
    end
  end
  
  context 'when getting poll results from a poll_page' do
    setup do
      @dummy_response = dummy_response(:n3_poll)
      @dummy_graph = RDF::Graph.new
      RdfUtilities.stubs(:_http_get).returns(@dummy_response)
    end
    
    context 'in general' do
      setup do
        @results = ElectionResultExtractor.poll_results_from('http://foo.com/polls')
      end
      
      before_should 'build graph from given page' do
        RdfUtilities.expects(:graph_from).with('http://foo.com/polls').returns(@dummy_graph)
      end
      
      should 'return results' do
        assert_kind_of Array, @results
      end
      
      should 'return poll details in hash' do
        assert_equal 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03', @results.first[:uri]
      end
      
      should 'return poll area in hash' do
        assert_equal 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGE', @results.first[:area]
      end
      
      should 'return poll date in hash' do
        assert_equal '2007-05-03', @results.first[:date]
      end
      
      should 'return electorate in hash' do
        assert_equal '4409', @results.first[:electorate]
      end
      
      should 'return ballots_issued in hash' do
        assert_equal '1642', @results.first[:ballots_issued]
      end
      
      should 'return poll_page uri as source in hash' do
        assert_equal 'http://foo.com/polls', @results.first[:source]
      end
      
      should 'return array of candidacies in hash' do
        assert_kind_of Array, candidacies = @results.first[:candidacies]
        assert_equal 7, candidacies.size
      end
      
      should 'include candidate details for candidacies' do
        candidacies = @results.first[:candidacies]
        candidacy = @results.first[:candidacies].detect { |c| c[:name] == 'Michael John Wilcox' }
        assert_equal '790', candidacy[:votes]
        assert_equal 'false', candidacy[:elected]
        assert_equal 'http://openelectiondata.org/id/parties/25', candidacy[:party]
        assert !candidacy[:independent]
      end
      
      should 'mark independent councillors as such' do
        independent = @results.first[:candidacies].detect { |c| c[:name] == 'John Linnaeus Middleton' }
        assert_nil independent[:party]
        assert_equal 'true', independent[:independent]
      end
      
      should 'get given and family names when supplied' do
        rich_candidacy = @results.first[:candidacies].detect { |c| c[:given_name] == 'Patrick Wardle' }
        assert_equal 'Curran', rich_candidacy[:family_name]
        assert_equal '473', rich_candidacy[:votes]
      end
      
      should 'get address when supplied' do
        rich_candidacy_address = @results.first[:candidacies].detect { |c| c[:given_name] == 'Patrick Wardle' }[:address]
        assert_equal 'IG2 6RR ', rich_candidacy_address[:postal_code]
        assert_equal '7 Pershore Close', rich_candidacy_address[:street_address]
        assert_equal 'Gants Hill', rich_candidacy_address[:locality]
        assert_equal 'Essex', rich_candidacy_address[:region]
      end
    end

    context 'and error raised querying results' do
      should 'raise exception with message' do
        RDF::Graph.any_instance.expects(:query).raises
        assert_raise(ElectionResultExtractor::ExtractorError) { ElectionResultExtractor.poll_results_from('http://foo.com/polls') }
      end
    end
    
  end
  
  context 'when getting poll results from a poll_page with uncontested poll' do
    setup do
      @dummy_response = dummy_response(:n3_uncontested_poll)
      @dummy_graph = RDF::Graph.new
      RdfUtilities.stubs(:_http_get).returns(@dummy_response)
    end
    
    context 'in general' do
      setup do
        @results = ElectionResultExtractor.poll_results_from('http://foo.com/polls')
      end

      should 'return poll details in hash' do
        assert_equal 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03', @results.first[:uri]
      end
      
      should 'mark poll as uncontested' do
        assert_equal 'true', @results.first[:uncontested]
      end
      
      should 'return poll area in hash' do
        assert_equal 'http://statistics.data.gov.uk/id/local-authority-ward/41UDGW', @results.first[:area]
      end
      
      should 'return poll date in hash' do
        assert_equal '2007-05-03', @results.first[:date]
      end
      
      should 'return array of candidacies in hash' do
        assert_kind_of Array, candidacies = @results.first[:candidacies]
        assert_equal 1, candidacies.size
      end
      
      should 'include candidate details for candidacies' do
        candidacies = @results.first[:candidacies]
        candidacy = @results.first[:candidacies].first # only one of them in this case
        assert_equal 'Ian Maxwell Pardoe Pritchard', candidacy[:name]
        assert_equal 'true', candidacy[:elected]
        assert_equal 'http://openelectiondata.org/id/parties/25', candidacy[:party]
        assert_equal '0', candidacy[:votes]
        assert !candidacy[:independent]
      end
      
    end
  end
  
  context 'when getting poll results from an election page' do
    setup do
      @dummy_response = dummy_response(:n3_election_polls_page)
      @dummy_graph = RDF::Graph.new
      RdfUtilities.stubs(:_http_get).returns(@dummy_response)
    end
    
    context 'in general' do
      setup do
        @results = ElectionResultExtractor.poll_results_from('http://foo.com/election')
      end
      
      before_should 'build graph from given page' do
        RdfUtilities.expects(:graph_from).with('http://foo.com/election').returns(@dummy_graph)
      end
      
      should 'return array of polls as result' do
        assert_kind_of Array, @results
        assert_equal 21, @results.size
      end
      
      context 'and when returning polls' do
        setup do
          @poll = @results.detect{ |p| p[:uri] == 'http://openelectiondata.org/id/polls/00BUFY/2008-05-01/member' }
        end
        
        should 'return poll details in hash' do
          assert_equal '8038', @poll[:electorate]
        end

        should "extract date from poll uri if it isn't explicitly stated" do
          assert_equal '2008-05-01', @poll[:date]
        end

        should "return candidacies" do
          assert_equal 5, @poll[:candidacies].size
          
          candidacy = @poll[:candidacies].detect { |c| c[:given_name] == 'Majella Teresa' }
          assert_equal '620', candidacy[:votes]
          assert_equal 'Kennedy', candidacy[:family_name]
          assert_equal 'false', candidacy[:elected]
          assert_equal 'http://openelectiondata.org/id/parties/6', candidacy[:party]
          assert !candidacy[:independent]
        end

        # before_should 'build graph from given page' do
        #   RdfUtilities.expects(:graph_from).with('http://foo.com/election').returns(@dummy_graph)
        # end
        # 
      end
      
    end
  end

  context 'when getting poll results for council' do
    setup do
      @council = stub(:ldg_id => 123) #stub Council behaviour
      @dummy_response = dummy_response(:n3_poll)
    end
    
    context 'in general' do
      setup do
        ElectionResultExtractor.stubs(:landing_page_for).returns('http://foo.com/landing')
        ElectionResultExtractor.stubs(:election_pages_from).returns(['http://foo.com/election'])
        ElectionResultExtractor.stubs(:poll_pages_from).returns(['http://foo.com/poll'])
        RdfUtilities.stubs(:_http_get).returns(@dummy_response)
      end
      
      should 'get landing page for council' do
        ElectionResultExtractor.expects(:landing_page_for).with(@council).returns('http://foo.com/landing')
        ElectionResultExtractor.poll_results_for(@council)
      end

      should 'get election pages from landing page' do
        ElectionResultExtractor.expects(:election_pages_from).with('http://foo.com/landing').returns(['http://foo.com/election'])
        ElectionResultExtractor.poll_results_for(@council)
      end
      
      should 'get poll pages from election page' do
        ElectionResultExtractor.expects(:poll_pages_from).with('http://foo.com/election').returns([])
        ElectionResultExtractor.poll_results_for(@council)
      end
      
      should 'get polls from poll pages' do
        ElectionResultExtractor.expects(:poll_results_from).with('http://foo.com/poll')
        ElectionResultExtractor.poll_results_for(@council)
      end
      
      should 'return status of process' do
        @dummy_response = dummy_response(:n3_poll)
        @dummy_graph = RDF::Graph.new
        assert_kind_of Array, status = ElectionResultExtractor.poll_results_for(@council)[:status]
        assert status.any?{ |s| s =~ /1 polls found/ }
      end
      
      context 'when returning results' do 
        setup do
          @dummy_response = dummy_response(:n3_poll)
          @dummy_graph = RDF::Graph.new
          RdfUtilities.expects(:_http_get).returns(@dummy_response)
          @results = ElectionResultExtractor.poll_results_for(@council)[:results]
        end
        
        should 'return as hash keyed to election page' do
          assert_kind_of Hash, @results
          assert_equal 'http://foo.com/election', @results.keys.first
        end

        should 'return polls array associated with elections' do
          assert_kind_of Array, polls = @results.values.first
          assert_kind_of Hash, polls.first
          assert_equal 'http://openelectiondata.org/id/polls/41UDGE/2007-05-03', polls.first[:uri]
        end
      end

      context 'when ExtractorError raised getting landing page' do
        should 'add message to errors' do
          ElectionResultExtractor.expects(:landing_page_for).raises(ElectionResultExtractor::ExtractorError, 'Error retrieving election landing page')
          assert_match /Error retrieving election landing page/, ElectionResultExtractor.poll_results_for(@council)[:errors]
        end
      end
      
      context 'when ExtractorError raised getting elections' do
        setup do
          ElectionResultExtractor.expects(:election_pages_from).raises(ElectionResultExtractor::ExtractorError, 'Error retreving election pages')
        end
        
        should 'add message to errors' do
          assert_match /Error retreving election pages/, ElectionResultExtractor.poll_results_for(@council)[:errors]
        end
        
        should 'show success getting landing page in status' do
          assert_match /Landing page found/i, ElectionResultExtractor.poll_results_for(@council)[:status].to_s # it's an array
        end
      end
    end

  end
end