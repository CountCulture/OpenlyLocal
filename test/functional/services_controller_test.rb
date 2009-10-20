require 'test_helper'

class ServicesControllerTest < ActionController::TestCase
  def setup
    @service = Factory(:service)
    @another_service = Factory(:service, :category => "Bar category", :service_name => "Bar service")
    @council = Factory(:council, :authority_type => "district", :ldg_id => 42)
  end

  # index test
   context "on GET to :index" do
     
     context "with basic request and council" do
       setup do
         get :index, :council_id => @council.id
       end
       
       should_assign_to :services
       should_assign_to :council
       should_respond_with :success
       should_render_template :index
      
       should "show services in title" do
         assert_select "title", /links to services/i
       end
       
       should "show council in title" do
         assert_select "title", /#{@council.title}/
       end
       
       should "list links to services" do
         assert_select "div#services li a", @service.service_name do
           assert_select "a[href='#{ERB::Util::h @service.url_for(@council)}']" #uris are escaped by default
         end
       end
     
       should "show list of categories" do
         assert_select "div#categories ul li", 2  do # two different categories
           assert_select "a", "Bar category"
         end
       end
       
       should "group links by category" do
         assert_select "div#services h3", 2  do # two different categories
           assert_select "h3", "Bar category"
         end
       end
       
       should "put include search form" do
         assert_select "form#services_search"
       end
       
       should "include hidden field for council id in search form" do
         assert_select "form#services_search input#council_id[type='hidden'][value='#{@council.id}']"
       end
     end
     
     context "with basic request and search term" do
       setup do
         get :index, :council_id => @council.id, :term => "foo"
       end
       
       should_assign_to(:services)
       should_assign_to :council
       should_respond_with :success
       should_render_template :index
      
       should "show term in title" do
         assert_select "title", /foo/i
       end
       
       should "show only titles with foo in title" do
         assert_select "div#services li a", @service.service_name
         assert_select "div#services li a", :text => @another_service.service_name, :count => 0
       end
       
       should "put term in form input box" do
         assert_select "form#services_search" do
           assert_select "input[value='foo']"
         end
       end
       
     end
     
     context "when no services" do
       setup do
         Service.delete_all
         get :index, :council_id => @council.id
       end
       should_assign_to :council
       should_respond_with :success
       should "show message" do
         assert_select "p", /no services found/i
       end
       should "not show services block" do
         assert_select "div#services", false
       end
     end
     
     context "on GET to :index without council_id" do

       should "raise an exception" do
         assert_raise(ActiveRecord::RecordNotFound) { get :index }
       end
     end
   end
end
