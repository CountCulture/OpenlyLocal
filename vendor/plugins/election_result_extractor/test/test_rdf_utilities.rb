require 'test_helper'
require 'rdf_utilities'

class RdfUtilitiesTest < ActiveSupport::TestCase

  context 'when getting graph from url' do
    setup do
      @url = 'http://foo.com/something?bar=nothing&baz=nothing2'
      @base_response = "<html>Hello World</html>"
      @dummy_response = stub_everything(:read => @base_response)
      @rdfxml_data = dummy_response(:rdfxml_landing_page)
      @dummy_rdfxml_response = stub_everything(:read => @rdfxml_data, :content_type => 'text/xml')
      RdfUtilities.stubs(:_http_get).returns(@dummy_response).then.returns(@dummy_rdfxml_response)
      RdfUtilities.stubs(:rdf_representation_of).with(@base_response) # => nil
      @dummy_reader = RDF::Reader.for(:rdfxml).new
    end
    
    context 'in general' do
      setup do
        @graph = RdfUtilities.graph_from(@url)
      end
      
      before_should "check if given page is rdfxml" do
        RdfUtilities.expects(:_http_get).with(@url) # => nil
      end
      
      before_should "check if there's an rdfxml representation of page" do
        RdfUtilities.expects(:rdf_representation_of).with(@base_response) # => nil
      end
      
      should 'get data from RDFXML distilled version of url' do
        RdfUtilities.expects(:_http_get).with(@url).returns(@dummy_response)
        RdfUtilities.expects(:_http_get).with("http://www.w3.org/2007/08/pyRdfa/extract?uri=#{CGI.escape(@url)}").returns(@dummy_rdfxml_response)
        RdfUtilities.graph_from(@url)
      end

      before_should 'pass data to RDFXML Reader' do
        RDF::Raptor::RDFXML::Reader.expects(:new).with(@rdfxml_data).returns(@dummy_reader)
      end
      
      before_should 'construct graph from rdf statements' do
        RDF::Graph.any_instance.expects(:<<).with(kind_of(RDF::Statement)).at_least(2)
      end
      
      should 'return an RDF:Graph' do
        assert_kind_of RDF::Graph, @graph
      end
      
    end
    
    context 'and page is already rdf+xml' do
      setup do
        RdfUtilities.expects(:_http_get).returns(@dummy_rdfxml_response)
        @graph = RdfUtilities.graph_from(@url)
      end
      
      before_should 'pass data to RDFXML Reader' do
        RDF::Raptor::RDFXML::Reader.expects(:new).with(@rdfxml_data).returns(@dummy_reader)
      end
      
      before_should 'construct graph from rdf statements' do
        RDF::Graph.any_instance.expects(:<<).with(kind_of(RDF::Statement)).at_least(2)
      end
      
      should 'return an RDF:Graph' do
        assert_kind_of RDF::Graph, @graph
      end
      
    end
    
    context 'and there is rdfxml representation of page' do
      setup do
        RdfUtilities.expects(:rdf_representation_of).returns('http://foo.com/elections.rdf')
        RdfUtilities.stubs(:_http_get).returns(@dummy_response).then.returns(@dummy_rdfxml_response) # override general case, return non-rdfxml to begin with, then real stuff
      end
      
      should 'pass data to RDFXML Reader' do
        RDF::Raptor::RDFXML::Reader.expects(:new).with(@rdfxml_data).returns(@dummy_reader)
        RdfUtilities.graph_from(@url)
      end
      
      should 'construct graph from rdf statements' do
        RDF::Graph.any_instance.expects(:<<).with(kind_of(RDF::Statement)).at_least(2)
        RdfUtilities.graph_from(@url)
      end
      
      should 'return an RDF:Graph' do
        assert_kind_of RDF::Graph, RdfUtilities.graph_from(@url)
      end
      
      context 'it' do
        should 'get data from data from rdfxml url' do
          RdfUtilities.expects(:_http_get).returns(@dummy_response)
          RdfUtilities.expects(:_http_get).with("http://foo.com/elections.rdf", anything).returns(@dummy_rdfxml_response)
          RdfUtilities.graph_from(@url)
        end
      end
      
    end
  end

  context 'when problem getting graph from url' do
    setup do
      RdfUtilities.expects(:_http_get).at_least_once
    end
    
    should 'return nil' do
      assert_nil RdfUtilities.graph_from('http://foo.com/')
    end
  end
  
  # context 'when problem parsing' do
  #   setup do
  #     @url = 'http://foo.com/something?bar=nothing&baz=nothing2'
  #     @dummy_response = stub_everything(:read => dummy_response(:n3_problem))
  #     RdfUtilities.stubs(:_http_get).returns(@dummy_response)
  #     @dummy_reader = RDF::NTriples::Reader.new
  #   end
  #   
  #   should 'raise exception' do
  #     assert_raise(RDF::ReaderError) { RdfUtilities.graph_from('http://foo.com/') }
  #   end
  # end
  
end
