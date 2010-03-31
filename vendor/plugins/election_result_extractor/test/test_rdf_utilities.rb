require 'test_helper'
require 'rdf_utilities'

class RdfUtilitiesTest < Test::Unit::TestCase

  context 'when getting graph from url' do
    setup do
      @url = 'http://foo.com/something?bar=nothing&baz=nothing2'
      @dummy_response = dummy_response(:n3_poll)
      RdfUtilities.stubs(:_http_get).returns(@dummy_response)
      @dummy_reader = RDF::NTriples::Reader.new
    end
    
    context 'in general' do
      setup do
        @graph = RdfUtilities.graph_from(@url)
      end
      
      before_should 'get data from n3 distilled version of url' do
        RdfUtilities.expects(:_http_get).with("http://www.w3.org/2007/08/pyRdfa/extract?format=nt&uri=#{@url}").returns(@dummy_response)
      end

      before_should 'pass data to RDF Reader' do
        RDF::NTriples::Reader.expects(:new).with(@dummy_response).returns(@dummy_reader)
      end
      
      before_should 'construct graph from rdf statements' do
        RDF::Graph.any_instance.expects(:<<).with(kind_of(RDF::Statement)).at_least(2)
      end
      
      should 'return an RDF:Graph' do
        assert_kind_of RDF::Graph, @graph
      end
      
    end
    
  end

  context 'when problem getting graph from url' do
    setup do
      RdfUtilities.expects(:open).raises
    end
    
    should 'return nil' do
      assert_nil RdfUtilities.graph_from('http://foo.com/')
    end
  end
  
  context 'when problem parsing n3' do
    setup do
      @url = 'http://foo.com/something?bar=nothing&baz=nothing2'
      @dummy_response = dummy_response(:n3_problem)
      RdfUtilities.stubs(:_http_get).returns(@dummy_response)
      @dummy_reader = RDF::NTriples::Reader.new
    end
    
    should 'raise exception' do
      assert_raise(RDF::ReaderError) { RdfUtilities.graph_from('http://foo.com/') }
    end
  end
  
end
