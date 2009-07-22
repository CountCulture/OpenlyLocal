require 'test_helper'

# Way of testing application controller stuff (though some of this can be 
# tested in unit test) and application layout stuff
class GenericController < ApplicationController
  before_filter :add_rdfa_headers, :only => :show
  def index
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
  end
  
  # index tests
  context "on GET to :index" do
    setup do
      get :index
    end

    should "show title" do
      assert_select "title", "Openly Local"
    end
    
    should "not show rdfa headers" do
      assert_select "html[xmlns:foaf*='xmlns.com/foaf']", false
    end
  end
  
  # get tests
  context "on GET to :show" do
    setup do
      @council = Factory(:council)
      get :show
    end
    
    should "show given title in title" do
      assert_select "title", "Foo Title :: Openly Local"
    end
    
    should "show rdfa headers" do
      assert_select "html[xmlns:foaf*='xmlns.com/foaf']"
    end
    
    should "add link in head" do
      assert_select "link[rel='foaf:primaryTopic'][href='#this']"
    end
    
    should "show canonical_url link" do
      assert_select "link[rel='canonical'][href='/foo/bar']"
    end
  end
  
  context "on GET to :show with council instantiated" do
    setup do
      @council = Factory(:council)
      get :show, :council_id => @council.id
    end
    
    should "show council in title" do
      assert_select "title", "Foo Title :: #{@council.title} :: Openly Local"
    end
  end
end