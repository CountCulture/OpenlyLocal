module RdfUtilities
  require 'cgi'
  require 'open-uri'
  require 'rubygems'
  require 'rdf'
  require 'rdf/raptor'
  
  extend self
  
  def graph_from(url=nil)
    return unless url 
    response = _http_get(url)
    if response && response.content_type =~ /xml/
      response = response.read
      rdfxml_url = true
    else
      rdfxml_url = response && rdf_representation_of(response.read)
      url = rdfxml_url || url
      return unless response = rdfxml_url ? _http_get(url).read : _http_get("http://www.w3.org/2007/08/pyRdfa/extract?uri=#{url}", :distill => true).read  rescue nil
    end
    graph = RDF::Graph.new
    # reader = rdfxml_url ? RDF::Reader.for(:rdfxml).new(response) : RDF::Reader.for(:ntriples).new(response)
    reader = RDF::Reader.for(:rdfxml).new(response)# : RDF::Reader.for(:ntriples).new(response)
    reader.each_statement { |st| graph << st }
    graph
  end
  
  # protected
  def _http_get(url, options={})
    return if RAILS_ENV == 'test'
    headers = options[:distill] ? {'Accept' => 'text/rdf+n3'} : {}
    open(url, headers)
  rescue 
    return nil
  end
  
  def rdf_representation_of(response)
    Hpricot(response).at('link[@rel=alternate][@type="application/rdf+xml"]')[:href] rescue nil
  end
  
end