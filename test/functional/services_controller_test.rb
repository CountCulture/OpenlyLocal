require 'test_helper'

class ServicesControllerTest < ActionController::TestCase
  def setup
    @council = Factory(:council, :authority_type => "district", :ldg_id => 42)
    @service = Factory(:service, :council => @council)
    @ldg_service = @service.ldg_service
    @another_service = Factory(:service, :category => "Bar category", :title => "Bar service", :council => @council)
  end

  # index test
  context "on GET to :index" do
    
    context "with basic request and council" do
      setup do
        get :index, :council_id => @council.id
      end
      
      should_assign_to :services
      should_assign_to :council
      should respond_with :success
      should render_template :index
     
      should "show services in title" do
        assert_select "title", /links to services/i
      end
      
      should "show council in title" do
        assert_select "title", /#{@council.title}/
      end
      
      should "list links to services" do
        assert_select "div#services li a", @service.title do
          assert_select "a[href='#{ERB::Util::h @service.url}']" #uris are escaped by default
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
    
    context "with basic request and ldg_service" do
      setup do
        @another_council = Factory(:another_council, :name => 'Zcouncil') #make sure comes after @council name
        @another_council_service = Factory(:service, :category => @service.category, :title => "Bar service", :ldg_service => @ldg_service, :council => @another_council)
        
        get :index, :ldg_service_id => @service.ldg_service_id
      end
      
      should_assign_to :ldg_service
      should_assign_to :services
      should respond_with :success
      should render_template :index
      
      should "show ldg_service in title" do
        assert_select "title", /#{@ldg_service.title}/
      end
      
      should "list councils in links" do
        assert_select "div#services li a", @council.title
      end
      
      should 'list service on order of council name' do
        assert_equal @council, assigns(:services).first.last.first.council
      end
      
      should "list links to services" do
        assert_select "div#services li a", @council.title do
          assert_select "a[href='#{ERB::Util::h @service.url}']" #uris are escaped by default
        end
      end
    
    end
    
    context "with basic request and xml requested" do
      setup do
        get :index, :council_id => @council.id, :format => "xml"
      end
      
      should_assign_to :services
      should_assign_to :council
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/xml'
      
      should "show services for council" do
        assert_select "services>service>title", @service.title
        assert_select "services>service>url", @service.url
      end
  
    end
    
    context "with basic request and json requested" do
      setup do
        get :index, :council_id => @council.id, :format => "json"
      end
      
      should_assign_to :services
      should_assign_to :council
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/json'
      
      should "show services for council" do
        assert_match /service.+title.+#{@service.title}/, @response.body
        assert_match /service.+url.+#{@service.url}/, @response.body
      end
    end
    
    context "with basic request and search term" do
      setup do
        get :index, :council_id => @council.id, :term => "foo"
      end
      
      should_assign_to(:services)
      should_assign_to :council
      should respond_with :success
      should render_template :index
     
      should "show term in title" do
        assert_select "title", /foo/i
      end
      
      should "show only titles with foo in title" do
        assert_select "div#services li a", @service.title
        assert_select "div#services li a", :text => @another_service.title, :count => 0
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
      should respond_with :success
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
