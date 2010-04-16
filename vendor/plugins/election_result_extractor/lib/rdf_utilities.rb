module RdfUtilities
  require 'cgi'
  require 'open-uri'
  require 'rubygems'
  require 'rdf'
  
  extend self
  
  def graph_from(url=nil)
    return unless url && response = _http_get("http://www.w3.org/2007/08/pyRdfa/extract?format=nt&uri=#{url}")
    graph = RDF::Graph.new
    reader = RDF::NTriples::Reader.new(response)
    reader.each_statement { |st| graph << st }
    graph
  end
  
  protected
  def _http_get(url)
    return if RAILS_ENV == 'test'
    open(url, 'Accept' => 'text/rdf+n3').read
  rescue 
    return nil
  end
  
end