require 'test_helper'

class HyperlocalSitesControllerTest < ActionController::TestCase
  def setup
    @hyperlocal_site = Factory(:approved_hyperlocal_site, :email => 'info@hyperlocal.com')
    @another_hyperlocal_site = Factory(:approved_hyperlocal_site, :country => 'Scotland', :title => "Second Hyperlocal Site", :hyperlocal_group => Factory(:hyperlocal_group))
    @unapproved_hyperlocal_site = Factory(:hyperlocal_site)
  end
  
  context "when routing to hyperlocal_sites" do
    should "have routing for custom search" do
      assert_routing("hyperlocal_sites/custom_search.xml", {:controller => "hyperlocal_sites", :action => "index", :custom_search => true, :format => "xml"})
    end
    
    should "have routing for destroying_multiple sites" do
      assert_routing({ :method => 'delete', :path => '/hyperlocal_sites/destroy_multiple' }, {:controller => "hyperlocal_sites", :action => "destroy_multiple"})
    end
    
  end

  # index test
  context "on GET to :index" do
    context "with basic request" do
      setup do
        get :index
      end

      should assign_to(:hyperlocal_sites) { [@hyperlocal_site, @another_hyperlocal_site]}
      should respond_with :success
      should render_template :index
      should "list only approved hyperlocal sites" do
        assert_select "li a", @hyperlocal_site.title
        assert_select "li a", :text => @unapproved_hyperlocal_site.title, :count => 0
      end

      should "show share block" do
        assert_select "#share_block"
      end

      should "show api block" do
        assert_select "#api_info"
      end
      
      should 'show title' do
        assert_select "title", /Hyperlocal Sites/i
      end
      
      should 'group by country' do
        assert_select "li.country", /Scotland/ do
          assert_select "ul li a", @another_hyperlocal_site.title
        end
      end
      
      should 'show link to restrict to independent sites' do
        assert_select "a", /independent sites/i
      end
      
      should "enable google maps" do
        assert assigns(:enable_google_maps)
      end
      
      should "show rss feed link" do
        assert_select "link[rel='alternate'][type='application/rss+xml'][href='http://test.host/hyperlocal_sites.rss']"
      end
      
    end
    
    context "with independent only requested" do
      setup do
        get :index, :independent => true
      end

      should assign_to(:hyperlocal_sites) {[@hyperlocal_site]}
      should respond_with :success
      should render_template :index
      
      should 'show restriction in title' do
        assert_select "title", /independent hyperlocal sites in UK/i
      end
      
      should 'show link to restrict to independent sites' do
        assert_select "a", /show all sites/i
      end
      
    end
    
    context 'when restricted to country' do
      setup do
        get :index, :country => 'Scotland'
      end

      should assign_to(:hyperlocal_sites) {[@another_hyperlocal_site]}
      should respond_with :success
      should render_template :index
      
      should 'show restriction in title' do
        assert_select "title", /hyperlocal sites in Scotland/i
      end
      
      should 'show link to restrict to all sites' do
        assert_select 'a', /show all sites/i
      end
    end
    
    context 'when restricted to region' do
      setup do
        council = Factory(:council, :region => 'West Midlands')
        @west_midlands_site = Factory(:approved_hyperlocal_site, :council => council)
        get :index, :region => 'West Midlands'
      end
      
      should assign_to(:hyperlocal_sites) {[@west_midlands_site]}
      should respond_with :success
      should render_template :index
      
      should 'show restriction in title' do
        assert_select 'title', /hyperlocal sites in West Midlands/i
      end
      
      should 'show link to restrict to all sites' do
        assert_select 'a', /show all sites/i
      end
    end
    
    context "with request with location" do
      setup do
        @hyperlocal_site.stubs(:distance).returns(5)
        @another_hyperlocal_site.stubs(:distance).returns(9.2)
        @sites = [@hyperlocal_site, @another_hyperlocal_site]
        Geokit::LatLng.stubs(:normalize).returns(Geokit::LatLng.new)
        HyperlocalSite.stubs(:find).returns(@sites)
        
        get :index, :location => '100 Spear st, San Francisco, CA'
      end

      should assign_to(:hyperlocal_sites) { }
      should respond_with :success
      should render_template :index

      should 'show location in title' do
        assert_select "title", /100 Spear st, San Francisco, CA/i
      end
      
      should 'show distance from location' do
        assert_select "ul li", /#{@another_hyperlocal_site.title}/ do
          assert_select "li", /9.2 miles/
        end
      end
      
      should "enable google maps" do
        assert assigns(:enable_google_maps)
      end
    end
    
    context "with request for location that can't be geocoded" do
      setup do
        
        @sites = [@hyperlocal_site, @another_hyperlocal_site]
        Geokit::LatLng.stubs(:normalize).raises(Geokit::Geocoders::GeocodeError)
        
        get :index, :location => 'foo'
      end
      
      should assign_to(:hyperlocal_sites) { [@hyperlocal_site, @another_hyperlocal_site] }
      should respond_with :success
      should render_template :index

      should 'show location in title' do
        assert_select "title", /foo/i
      end
      
      should 'show message' do
        assert_select ".warning", /couldn't find location/i
      end

    end

    context "with xml request" do
      setup do
        get :index, :format => "xml"
      end

      should assign_to(:hyperlocal_sites) { [@hyperlocal_site, @another_hyperlocal_site] }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/xml'
      should "not include email address" do
        assert_select "email", false
      end
    end
    
    context "with json requested" do
      setup do
        get :index, :format => "json"
      end
  
      should assign_to(:hyperlocal_sites) {  [@hyperlocal_site, @another_hyperlocal_site] }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/json'
      should "not include email address" do
        assert_no_match /email\:/, @response.body
      end
    end
    
    context "with rss requested" do
      setup do
        HyperlocalSite.record_timestamps = false # update timestamp without triggering callbacks
        @hyperlocal_site.update_attributes(:distance_covered => 10.0, :created_at => 2.hours.ago)
        HyperlocalSite.record_timestamps = true # update timestamp without triggering callbacks
        get :index, :format => "rss"
      end
      
      should assign_to(:hyperlocal_sites) {  [@hyperlocal_site, @another_hyperlocal_site] }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/rss+xml'
      should "have title " do
        assert_select "title", "Latest Hyperlocal Sites in UK &amp; Ireland"
      end
      should "list hyperlocal sites" do
        assert_select "item", 2 do
          assert_select "title", @hyperlocal_site.title
          assert_select "link", "http://test.host/hyperlocal_sites/#{@hyperlocal_site.to_param}"
          assert_match /georss:point>#{@hyperlocal_site.lat} #{@hyperlocal_site.lng}/, @response.body
          assert_match /georss:radius>#{@hyperlocal_site.distance_covered*1604.34}/, @response.body
        end
      end
      should "list newest hyperlocal site first" do
        assert_match /#{@another_hyperlocal_site.title}.+#{@hyperlocal_site.title}/m, @response.body
      end
    end
  end
    
  # custom_search tests for index action
  context "on GET to :custom search" do
    
    context "in general should" do
      setup do
        get :index, :custom_search => true, :format => "xml"
      end
      
      should assign_to(:hyperlocal_sites) { [@hyperlocal_site, @another_hyperlocal_site] }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/xml'
      
      should "generate custom search title" do
        assert_xml_select 'CustomSearchEngine>Title' do
          assert_select "Title", /OpenlyLocal Hyperlocal Sites in UK/
        end
      end
      
      should "generate custom search info" do
        assert_xml_select "Annotations>Annotation", 2 do
          assert_select "Annotation[about='#{@hyperlocal_site.url}/*']"
          assert_select "Label[name='openlylocal_cse_hyperlocal_']"
        end
      end
    end
    
    context "with request with location" do
      setup do
        @hyperlocal_site.stubs(:distance).returns(5)
        @another_hyperlocal_site.stubs(:distance).returns(9.2)
        @sites = [@hyperlocal_site, @another_hyperlocal_site]
        Geokit::LatLng.stubs(:normalize).returns(Geokit::LatLng.new)
        HyperlocalSite.stubs(:find).returns(@sites)

        get :index, :custom_search => true, :format => "xml", :location => '100 Spear st, San Francisco, CA'
      end
      
      should assign_to(:hyperlocal_sites) { [@hyperlocal_site, @another_hyperlocal_site] }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/xml'
      
      should "generate custom search title" do
        assert_xml_select 'CustomSearchEngine>Title' do
          assert_select "Title", /100 Spear st, San Francisco, CA/
        end
      end
      
      should "generate custom search info" do
        assert_xml_select "Annotations>Annotation", 2 do
          assert_select "Annotation[about='#{@hyperlocal_site.url}/*']"
          assert_select "Label[name='openlylocal_cse_hyperlocal_100spearstsanfranciscoca']"
        end
      end
    end
    
    # custom_search_results tests
    context "on GET to :custom_search_results" do
      should "generate routing for custom_search_results" do
        assert_routing("hyperlocal_sites/custom_search_results", {:controller => "hyperlocal_sites", :action => "custom_search_results"})
      end

      context "in general should" do
        setup do
          get :custom_search_results
        end
        
        should respond_with :success
        should_render_with_layout
        should "have title " do
          assert_select "title", /Hyperlocal Sites Search Results/i
        end
        should "show div for results" do
          assert_select "div#cse-search-results"
        end  
      end  
    end
  end  
  
  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @hyperlocal_site.id
      end

      should assign_to :hyperlocal_site
      should respond_with :success
      should render_template :show

      should "include hyperlocal site in page title" do
        assert_select "title", /#{@hyperlocal_site.title}/
      end

      should "include phrase 'hyperlocal sites' in page title" do
        assert_select "title", /hyperlocal sites/i
      end

      should "list hyperlocal site attributes" do
        assert_select '.attributes dd', /#{@hyperlocal_site.url}/
      end
      
      should "not list email address" do
        assert_select ".attributes", :text => /#{@hyperlocal_site.email}/, :count => 0
      end
      
      should "enable google maps" do
        assert assigns(:enable_google_maps)
      end
      
      should "not nofollow link to website" do
        assert_select "a[rel=nofollow]", :text => @hyperlocal_site.url, :count => 0
      end
    end
    
    context "with basic request and assoc local authority" do
      setup do
        @council = Factory(:council, :region => "West Midlands", :country => "Scotland")
        @hyperlocal_site.update_attribute(:council, @council)
        get :show, :id => @hyperlocal_site.id
      end

      should assign_to :hyperlocal_site
      should respond_with :success
      should render_template :show

      should "show link to hyperlocal_sites in council region" do
        assert_select "a.region[href*='region=West+Midlands']", /West Midlands/
      end

      should "show link to hyperlocal_sites in country" do
        assert_select "a.country[href*='country=England']", /England/
      end

    end
    
    context "with unapproved site" do
      setup do
        get :show, :id => @unapproved_hyperlocal_site.id
      end
      
      should "nofollow link to website" do
        assert_select "a[rel=nofollow]", @unapproved_hyperlocal_site.url
      end
    end
    
    context "when hyperlocal_site belongs to hyperlocal_group" do
      setup do
        @hyperlocal_group = Factory(:hyperlocal_group)
        @hyperlocal_group.hyperlocal_sites << @hyperlocal_site
        get :show, :id => @hyperlocal_site.id
      end
      
      should "list hyperlocal group" do
        assert_select '.attributes dd a', @hyperlocal_group.title
      end
      
    end
    
    context "when hyperlocal_site has feed_entries" do
      setup do
        @feed_entry = Factory(:feed_entry, :feed_owner => @hyperlocal_site)
        get :show, :id => @hyperlocal_site.id
      end
      
      should "list latest feed items" do
        assert_select '#feed_entries' do
          assert_select "#feed_entry_#{@feed_entry.id}"
        end
      end
      
    end
    
    context "when hyperlocal_site has twitter_account" do
      setup do
        @hyperlocal_site.twitter_account_name = "foo"
        get :show, :id => @hyperlocal_site.id
      end
      
      should "link to twitter feed" do
        assert_select 'a.twitter[href*="twitter.com/foo"]'
      end
      
    end
  end

  # new test
  context "on GET to :new" do
    setup do
      get :new
    end
  
    should assign_to(:hyperlocal_site)
    should respond_with :success
    should render_template :new
  
    should "show title" do
      assert_select "title", /new hyperlocal site/i
    end
    
    should "show form" do
      assert_select "form#new_hyperlocal_site"
    end
    
    should "show possible hyperlocal groups in select box" do
      assert_select "select#hyperlocal_site_hyperlocal_group_id"
    end
    
    should "show possible platforms in select box" do
      assert_select "select#hyperlocal_site_platform"
    end
    
    should "not show approved tickbox" do
      assert_select "#hyperlocal_site_approved", false
    end
    
    should "enable google maps" do
      assert assigns(:enable_google_maps)
    end
  end  
  
  # create test
   context "on POST to :create" do
     setup do
       @attributes = Factory.attributes_for(:hyperlocal_site)
     end
    
    context "with valid params" do
       setup do
         post :create, :hyperlocal_site => @attributes
       end
     
       should_change("The number of Hyperlocal Sites", :by => 1) {HyperlocalSite.count}
       should assign_to :hyperlocal_site
       should_redirect_to( "the hyperlocal_sites index page") { hyperlocal_sites_url }
       should set_the_flash.to(/Successfully submitted/i)
        
       should "set approved flag to false by default" do
         assert !HyperlocalSite.find_by_title(@attributes[:title]).approved?
       end
     end
     
     context "with invalid params" do
       setup do
         post :create, :hyperlocal_site => {:title => "New Hyperlocal Site"}
       end
     
       should_not_change("The number of Hyperlocal Sites") { HyperlocalSite.count }
       should assign_to :hyperlocal_site
       should render_template :new
       should_not set_the_flash
     end
  
     context "with approved_flag set to true" do
       setup do
         post :create, :hyperlocal_site => @attributes.merge(:approved => "1")
       end
     
       should "not set approved flag to true" do
         assert !HyperlocalSite.find_by_title(@attributes[:title]).approved?
       end
     end
  
   end  
  
  # edit tests
  context "on get to :edit a hyperlocal site without auth" do
    setup do
      get :edit, :id => @hyperlocal_site.id
    end

    should respond_with 401
  end

  context "on get to :edit a hyperlocal site" do
    setup do
      stub_authentication
      get :edit, :id => @hyperlocal_site.id
    end

    should assign_to :hyperlocal_site
    should respond_with :success
    should render_template :edit
    should_not set_the_flash
    should "display a form" do
     assert_select "form#edit_hyperlocal_site_#{@hyperlocal_site.id}"
    end

    should "show approved checkbox" do
      assert_select "#hyperlocal_site_approved"
    end
    
    should "show button to delete" do
      assert_select "form.button-to[action='/hyperlocal_sites/#{@hyperlocal_site.to_param}']"
    end
    
    should "enable google maps" do
      assert assigns(:enable_google_maps)
    end
  end

  # update tests
  context "on PUT to :update without auth" do
    setup do
      put :update, { :id => @hyperlocal_site.id,
                     :hyperlocal_site => { :title => "New title"}}
    end

    should respond_with 401
  end

  context "on PUT to :update" do
    context "in general" do
      setup do
        stub_authentication
        put :update, { :id => @hyperlocal_site.id,
                       :hyperlocal_site => { :title => "New title"}}
      end

      should assign_to :hyperlocal_site
      should_redirect_to( "the show page for hyperlocal_site") { hyperlocal_site_url(@hyperlocal_site.reload) }
      should set_the_flash.to( /Successfully updated/)

      should "update hyperlocal_site" do
        assert_equal "New title", @hyperlocal_site.reload.title
      end
    end
    
    context "when approved is set to true" do
      setup do
        stub_authentication
        put :update, { :id => @hyperlocal_site.id,
                       :hyperlocal_site => { :approved => "1"}}
      end

      should "approve hyperlocal_site" do
        assert @hyperlocal_site.reload.approved?
      end
    end
    
    context "when approved is set to true" do
      setup do
        @hyperlocal_site.update_attribute(:approved, true)
        stub_authentication
        put :update, { :id => @hyperlocal_site.id,
                       :hyperlocal_site => { :approved => "0"}}
      end

      should "disapprove hyperlocal_site" do
        assert !@hyperlocal_site.reload.approved?
      end
    end
  end
  
  # delete tests
  context "on delete to :destroy a hyperlocal_site without auth" do
    setup do
      delete :destroy, :id => @hyperlocal_site.id
    end

    should respond_with 401
  end

  context "on delete to :destroy a hyperlocal_site" do

    setup do
      stub_authentication
      delete :destroy, :id => @hyperlocal_site.id
    end

    should "destroy hyperlocal_site" do
      assert_nil HyperlocalSite.find_by_id(@hyperlocal_site.id)
    end
    should_redirect_to ( "the admin page") { admin_url }
    should set_the_flash.to( /Successfully destroyed/)
  end
    
  context "on delete to :destroy multiple hyperlocal_sites" do

    setup do
      stub_authentication
      delete :destroy_multiple, :ids => [@hyperlocal_site.id, @another_hyperlocal_site.id]
    end

    should "destroy given hyperlocal_sites" do
      assert_nil HyperlocalSite.find_by_id(@hyperlocal_site.id)
      assert_nil HyperlocalSite.find_by_id(@another_hyperlocal_site.id)
    end
    
    should_redirect_to ( "the admin page") { admin_url }
    should set_the_flash.to( /successfully destroyed 2 hyperlocal sites/i)
  end
    
end
