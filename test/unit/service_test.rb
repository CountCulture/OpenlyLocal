require File.expand_path('../../test_helper', __FILE__)

class ServiceTest < ActiveSupport::TestCase
  subject { @service }
  context "The Service class" do
    setup do
      @council = Factory(:council, :ldg_id => 42, :authority_type => "District")
      @ldg_service = Factory(:ldg_service) # this service is provided by district and unitary councils only
      @service = Factory(:service, :council => @council) # category 'Foo 1'
      Service.record_timestamps = false
      Service.record_timestamps = true
      
      @another_service = Factory(:service, :title => "Bar Service", :council => @council) # category 'Foo 1'
    end
    
    should belong_to :council
    should belong_to :ldg_service
    should validate_presence_of :council_id 
    should validate_presence_of :title 
    should validate_presence_of :url
    should validate_presence_of :category
    should validate_presence_of :ldg_service_id
    should validate_uniqueness_of(:ldg_service_id).scoped_to :council_id
    
    should "return order by title by default" do
      assert_equal [@another_service, @service], Service.all
    end
    
    should "have matching_term named_scope" do
      assert Service.respond_to?(:matching_term)
      assert_equal [@service], Service.matching_term("foo")
      assert_equal [@another_service, @service], Service.matching_term("service") # should be case-independent 
      assert_equal [@another_service, @service], Service.matching_term(nil) #should return all if no term
      assert_equal [@another_service, @service], Service.matching_term("") #should return all if no term
    end
    
    should "have stale named_scope" do
      stale_service = dummy_stale_service
      assert_equal [stale_service], Service.stale
    end
    
    context "when refreshing all urls" do
      setup do
        Council.stubs(:with_stale_services).returns([@council])
        Council.any_instance.stubs(:potential_services).returns([@ldg_service])
        @ldg_service.stubs(:destination_url).returns({:url => "http://foobar.com", :title => "Foobar Page"})
      end
      
      should "get get all councils with stale services" do
        Council.expects(:with_stale_services).returns([@council])
        Service.refresh_all_urls
      end
      
      should "get refresh urls for each council with stale services" do
        council1, council2 = stub, stub
        Council.stubs(:with_stale_services).returns([council1, council2])
        Service.expects(:refresh_urls_for).with(council1)
        Service.expects(:refresh_urls_for).with(council2)
        Service.refresh_all_urls
      end
    end
    
    context "when refreshing urls for council" do
      setup do
        Council.any_instance.stubs(:potential_services).returns([@ldg_service])
        @ldg_service.stubs(:destination_url).returns({:url => "http://foobar.com", :title => "Foobar Page"})
      end
      
      should "get potential services for councils" do
        Council.any_instance.expects(:potential_services).returns([@ldg_service])
        Service.refresh_urls_for(@council)
      end
      
      should "get destination_url for each potential service" do
        @ldg_service.expects(:destination_url).returns({:url => "http://foobar.com", :title => "Foobar Page"})
        Service.refresh_urls_for(@council)
      end
      
      should "save service if not previously in db" do
        assert_difference "Service.count", 1 do
          Service.refresh_urls_for(@council)
        end
      end
      
      should "save service details" do
        Service.refresh_urls_for(@council)
        s = Service.find_by_url_and_council_id("http://foobar.com", @council.id)
        assert_equal @ldg_service.category, s.category
        assert_equal @ldg_service.id, s.ldg_service_id
        assert_equal @ldg_service.title, s.title
      end
      
      should "not save results if previously in db" do
        assert_difference "Service.count", 1 do
          Service.refresh_urls_for(@council)
        end
      end
      
      should "not save results if no destination_url" do
        @ldg_service.expects(:destination_url) # returns nil
        assert_no_difference "Service.count" do
          Service.refresh_urls_for(@council)
        end
      end
      
      context "when pages returned include duplicates with contact in url" do
        setup do
          @second_ldg_service = Factory(:ldg_service)
          @third_ldg_service = Factory(:ldg_service)
          Council.any_instance.expects(:potential_services).returns([@ldg_service, @second_ldg_service, @third_ldg_service])
          
          @ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/contact_us", :title => "Foobar Page 1"})
          @second_ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/baz", :title => "Foobar Page 2"})
          @third_ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/contact_us", :title => "Foobar Page 3"})
        end
        
        should "not save them" do
          Service.refresh_urls_for(@council)
          assert_nil Service.find_by_url("http://foobar.com/contact_us")
        end
        
        should "still save other pages" do
          Service.refresh_urls_for(@council)
          assert Service.find_by_url("http://foobar.com/baz")
        end
      end
      
      context "when pages returned include single page with contact in url" do
        setup do
          @second_ldg_service = Factory(:ldg_service)
          Council.any_instance.expects(:potential_services).returns([@ldg_service, @second_ldg_service])
          
          @ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/contact_us", :title => "Foobar Page 1"})
          @second_ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/baz", :title => "Foobar Page 2"})
        end
        
        should "save it" do
          Service.refresh_urls_for(@council)
          assert Service.find_by_url("http://foobar.com/contact_us")
        end
        
        should "save other pages" do
          Service.refresh_urls_for(@council)
          assert Service.find_by_url("http://foobar.com/baz")
        end
      end
      
      context "when pages returned include duplicates with contact in title" do
        # NB duplicates mean they have same url
        setup do
          @second_ldg_service = Factory(:ldg_service)
          @third_ldg_service = Factory(:ldg_service)
          Council.any_instance.expects(:potential_services).returns([@ldg_service, @second_ldg_service, @third_ldg_service])
          
          @ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/some_page/1", :title => "Contact Us Now"})
          @second_ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/some_page/2", :title => "Foobar Page 2"})
          @third_ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/some_page/1", :title => "Contact Us Now"})
        end
        
        should "not save them" do
          Service.refresh_urls_for(@council)
          assert_nil Service.find_by_url("http://foobar.com/some_page/1")
        end
        
        should "still save other pages" do
          Service.refresh_urls_for(@council)
          assert Service.find_by_url("http://foobar.com/some_page/2")
        end
      end
      
      context "when pages returned include single page with contact in title" do
        setup do
          @second_ldg_service = Factory(:ldg_service)
          Council.any_instance.expects(:potential_services).returns([@ldg_service, @second_ldg_service])
          
          @ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/some_page/1", :title => "Contact Us Now"})
          @second_ldg_service.expects(:destination_url).returns({:url => "http://foobar.com/some_page/2", :title => "Foobar Page 2"})
        end
        
        should "save it" do
          Service.refresh_urls_for(@council)
          assert Service.find_by_url("http://foobar.com/some_page/1")
        end
        
        should "save other pages" do
          Service.refresh_urls_for(@council)
          assert Service.find_by_url("http://foobar.com/some_page/2")
        end
      end
      
      context "and service is already in db" do
        setup do
          @service.ldg_service = @ldg_service
          @service.save!
        end
        
        should "not create new entry" do
          assert_no_difference "Service.count" do
            Service.refresh_urls_for(@council)
          end
        end
        
        should "update existing entry" do
          Service.refresh_urls_for(@council)
          assert_equal "http://foobar.com", @service.reload.url
          assert_equal @ldg_service.title, @service.title
        end
      end
      
      should "delete stale existing results after processing" do
        stale_service = dummy_stale_service
        Service.refresh_urls_for(@council)
        assert_nil Service.find_by_id(stale_service.id)
      end
    end

    context "when returning service for lgsl id" do
      setup do
        @some_service_type = Factory(:ldg_service, :lgsl => 42)
        @another_service_type = Factory(:ldg_service, :lgsl => 44)
        @service_for_some_service_type = Factory(:service, :ldg_service => @some_service_type)
        @service_2_for_some_service_type = Factory(:service, :ldg_service => @some_service_type)
        @service_for_another_service_type = Factory(:service, :ldg_service => @another_service_type)
        @service_for_third_service_type = Factory(:service)
      end

      should "return all services belong to LdgService with given lgsl id" do
        sfl = Service.for_lgsl_id(42)
        assert_equal 2, sfl.size
        assert sfl.include?(@service_for_some_service_type)
        assert sfl.include?(@service_2_for_some_service_type)
      end

      should "return all services belong to LdgService with given lgsl ids" do
        sfl = Service.for_lgsl_id([42, 44])
        assert_equal 3, sfl.size
        assert sfl.include?(@service_for_some_service_type)
        assert sfl.include?(@service_2_for_some_service_type)
        assert sfl.include?(@service_for_another_service_type)
      end
    end
    
    context "when returning spending data services for councils publishing spending data" do
      setup do
        @council_1 = Factory(:generic_council)
        @council_2 = Factory(:generic_council, :name => "Aaa Council")
        @spend_data_service = Factory(:ldg_service, :lgsl => LdgService::SPEND_OVER_500_LGSL)
        @council_spending_service = Factory(:service, :ldg_service => @spend_data_service, :council => @council)
        @council_2_spending_service = Factory(:service, :ldg_service => @spend_data_service, :council => @council_2)
        @council_another_service = Factory(:service, :council => @council)
      end

      should "return list of service for those councils with service id" do
        cpsd = Service.spending_data_services_for_councils
        assert_equal 2, cpsd.size
        assert cpsd.include?(@council_spending_service)
        assert cpsd.include?(@council_2_spending_service)
      end

      should "return in alpha order of council name" do
        assert_equal @council_2_spending_service, Service.spending_data_services_for_councils.first
      end

      should "not include councils already tracked for spending data" do
        supplier = Factory(:supplier, :organisation => @council)
        assert_equal [@council_2_spending_service], Service.spending_data_services_for_councils
      end
    end
    
  end
  
  private
  def dummy_stale_service
    Service.record_timestamps = false
    ss = Factory(:service, :council => @council, :title => "Stale service", :created_at => 8.days.ago, :updated_at => 8.days.ago)
    Service.record_timestamps = true
    ss
  end
end
