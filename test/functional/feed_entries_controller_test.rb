require 'test_helper'

class FeedEntriesControllerTest < ActionController::TestCase
  # index test
  context "on GET to :index" do
    setup do
      @feed_entry = Factory(:feed_entry)
      @hyperlocal_site = Factory(:hyperlocal_site)
      @council = Factory(:council)
      @hyperlocal_feed_entry = Factory(:feed_entry, :feed_owner => @hyperlocal_site)
      @council_feed_entry = Factory(:feed_entry, :feed_owner => @council)
    end
    
    context "with basic request" do
      setup do
        get :index, :restrict_to => 'hyperlocal_sites'
      end

      should respond_with :success
      should render_template :index
      
      should 'restrict to given type' do
        assert assigns(:feed_entries).include?(@hyperlocal_feed_entry)
        assert !assigns(:feed_entries).include?(@feed_entry)
        assert !assigns(:feed_entries).include?(@council_feed_entry)
      end
      
      should "list feed entries" do
        assert_select "#feed_entries .feed_entry", /#{@hyperlocal_feed_entry.title}/
      end

      should "link to associated hyperlocal site" do
        assert_select "#feed_entries .feed_entry a", /#{@hyperlocal_site.title}/
      end

      should "show share block" do
        assert_select "#share_block"
      end

      should "show api block" do
        assert_select "#api_info"
      end
      
      should 'show appropriate title' do
        assert_select "title", /news stories/i
        assert_select "title", /hyperlocal sites/i
      end
    end
        
    context "with xml request" do
      setup do
        get :index, :format => "xml", :restrict_to => 'hyperlocal_sites'
      end

      should_assign_to(:feed_entries)
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/xml'
      
      should "include feed_entries" do
        assert_select "feed-entries>feed-entry>id"
      end

    end
    
    context "with json requested" do
      setup do
        get :index, :format => "json", :restrict_to => 'hyperlocal_sites'
      end
  
      should_assign_to(:feed_entries)
      should respond_with :success
      should_render_without_layout
      should respond_with_content_type 'application/json'
    end
    
    context 'when enough results' do
      setup do
        30.times { Factory(:feed_entry, :feed_owner => @hyperlocal_site) }
      end

      context 'in general' do
        setup do
          get :index, :restrict_to => 'hyperlocal_sites'
        end

        should 'show pagination links' do
          assert_select "div.pagination"
        end

        should 'show page number in title' do
          assert_select "title", /page 1/i
        end
      end

      context "with xml requested" do
        setup do
          get :index, :format => "xml", :restrict_to => 'hyperlocal_sites'
        end

        should assign_to(:feed_entries)
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/xml'

        should 'include pagination info' do
          assert_select "feed-entries>total-entries"
        end
      end

      context "with json requested" do
        setup do
          get :index, :format => "json", :restrict_to => 'hyperlocal_sites'
        end

        should assign_to(:feed_entries)
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/json'

        should 'include pagination info' do
          assert_match %r(total_entries.+33), @response.body
          assert_match %r(per_page), @response.body
          assert_match %r(page.+1), @response.body
        end
      end

    end

  end  
  
end
