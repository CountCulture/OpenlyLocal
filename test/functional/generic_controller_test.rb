require 'test_helper'

# Way of testing application controller stuff (though some of this can be 
# tested in unit test) and application layout stuff
class GenericController < ApplicationController
  before_filter :linked_data_available, :only => :show
  before_filter :show_rss_link, :only => :index
  def index
    @enable_google_maps = true
    render :text => "index text", :layout => true
  end
  
  def show
    @council = Council.find(params[:council_id]) if params[:council_id]
    @title = "Foo Title"
    @canonical_url = "/foo/bar"
    render :text => "show text", :layout => true
  end
end

class GenericControllerTest < ActionController::TestCase
  
  def setup
    ActionController::Routing::Routes.draw do |map|
      map.connect ':controller/:action/:id' # add usual route for testing purposes
    end
    @council = Factory(:council)
  end
  
  # index tests
  context "on GET to :index" do
    setup do
      get :index
    end

    should "show title" do
      assert_select "title", "Openly Local"
    end
    
    should "use default meta description if no title" do
      assert_select "meta[name='description'][content*=?]", "Opening Up Local Government"
    end
    
    should "not show rdfa headers" do
      assert_select "html[xmlns:foaf*='xmlns.com/foaf']", false
    end
    
    should "show rss auto discovery link" do
      assert_select "link[rel='alternate'][type='application/rss+xml'][href='http://test.host/generic?format=rss']"
    end
    
    should "load google maps javascript if @enable_google_maps true" do
      assert_select "script", /google\.load\(\"maps/
    end
    
    should "initialize map onload if @enable_google_maps true" do
      assert_select "body[onload='initMap()']"
    end
  end
  
  # show tests
  context "on GET to :show" do
    setup do
      get :show
    end
    
    should "show given title in title" do
      assert_select "title", "Foo Title :: Openly Local"
    end
    
    should "use title in meta description" do
      assert_select "meta[name='description'][content*=?]", /Foo Title/
    end
    
    should "show canonical_url link" do
      assert_select "link[rel='canonical'][href='/foo/bar']"
    end
    
    should "not show rss auto discovery link" do
      assert_select "link[rel='alternate'][type='application/rss+xml']", false
    end
    
    should "not load google maps javascript if @enable_google_maps not true" do
      assert_select "script", :text => /google\.load\(\"maps/, :count => 0
    end
    
    should "not initialize map onload if @enable_google_maps not true" do
      assert_select "body[onload='initMap()']", false
    end
  end
  
  context "on GET to :show with council instantiated" do
    setup do
      get :show, :council_id => @council.id
    end
    
    should "show council in title" do
      assert_select "title", "Foo Title :: #{@council.title} :: Openly Local"
    end
    
    should "use title in meta description" do
      assert_select "meta[name='description'][content*=?]", "Foo Title"
    end
    
    should "use council name in meta description" do
      assert_select "meta[name='description'][content*=?]", @council.title
    end
    
  end
  
  context "on GET to :show when passed redirect_from_resource as parameter" do
    setup do
      get :show, :council_id => @council.id, :redirect_from_resource => true, :foo => "bar"
    end

    should respond_with 303
    should_redirect_to("the given page without redirect_from_resource but with other params") {{:action => "show", :council_id => @council.id, :foo => "bar"}}
  end
  
  context "on GET to :show and no id passed in params" do
    setup do
      get :show
    end
    
    should "not show link to resource uri in head when no id in params" do
      assert_select "link[rel='foaf:primaryTopic'][href*='/id/generic']", false # uri based on controller
    end
    
    should "not show alternative resource links in head when no id in params" do
      assert_select "link[rel='alternate'][type='application/xml'][href*='.xml']", false
      assert_select "link[rel='alternate'][type='application/rdf+xml'][href*='.rdf']", false
    end    
  end
  
  context "on GET to :show with id passed in params" do
    setup do
      get :show, :id => "42"
    end
    
    should "show link to resource uri in head" do
      assert_select "link[rel*='primarytopic'][href*='/id/generic/42']" # uri based on controller
    end
    
    should "not show alternative resource links in head when no id in params" do
      assert_select "link[rel='alternate'][type='application/xml'][href*='/generic/42.xml']"
      assert_select "link[rel='alternate'][type='application/rdf+xml'][href*='/generic/42.rdf']"
    end
  end
end