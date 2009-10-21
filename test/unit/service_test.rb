require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  subject { @service }
  context "The Service class" do
    setup do
      @council = Factory(:council, :ldg_id => 42, :authority_type => "District")
      @ldg_service = Factory(:ldg_service) # this service is provided by district and unitary councils only
      @service = Factory(:service, :council => @council) # category 'Foo 1'
      
      @another_service = Factory(:service, :title => "bar Service", :council => @council) # category 'Foo 1'
    end
    
    should_belong_to :council
    should_belong_to :ldg_service
    should_validate_presence_of :council_id 
    should_validate_presence_of :title 
    should_validate_presence_of :url
    should_validate_presence_of :category
    should_validate_presence_of :ldg_service_id
    
    should "have named_scope matching_term" do
      
      assert Service.respond_to?(:matching_term)
      assert_equal [@service], Service.matching_term("foo")
      assert_equal [@service, @another_service], Service.matching_term("service") # should be case-independent 
      assert_equal [@service, @another_service], Service.matching_term(nil) #should return all if no term
      assert_equal [@service, @another_service], Service.matching_term("") #should return all if no term
    end
    
    context "when refreshing urls" do
      setup do
        Council.any_instance.stubs(:potential_services).returns([@ldg_service])
        @ldg_service.stubs(:destination_url).returns("http://foobar.com")
      end
      
      should "get get all councils" do
        Council.expects(:all).returns([@council])
        Service.refresh_urls
      end
      
      should "get potential services for councils" do
        Council.any_instance.expects(:potential_services).returns([@ldg_service])
        Service.refresh_urls
      end
      
      should "get destination_url for each potential service" do
        @ldg_service.expects(:destination_url).returns("http://foobar.com")
        Service.refresh_urls
      end
      
      should "save service if not previously in db" do
        assert_difference "Service.count", 1 do
          Service.refresh_urls
        end
      end
      
      should "save service details" do
        Service.refresh_urls
        s = Service.find_by_url_and_council_id("http://foobar.com", @council.id)
        assert_equal @ldg_service.category, s.category
        assert_equal @ldg_service.id, s.ldg_service_id
        assert_equal @ldg_service.title, s.title
      end
      
      should "not save results if not previously in db" do
        assert_difference "Service.count", 1 do
          Service.refresh_urls
        end
      end
      
      should "not save results if no destination_url" do
        @ldg_service.expects(:destination_url) # returns nil
        assert_no_difference "Service.count" do
          Service.refresh_urls
        end
      end
      
      context "and service is already in db" do
        setup do
          @service.ldg_service = @ldg_service
          @service.save!
        end
        
        should "not create new entry" do
          assert_no_difference "Service.count" do
            Service.refresh_urls
          end
        end
        
        should "update existing entry" do
          Service.refresh_urls
          assert_equal "http://foobar.com", @service.reload.url
          assert_equal @ldg_service.title, @service.title
        end
      end
      
      should "delete stale existing results after processing" do
        Service.record_timestamps = false
        @service.update_attribute(:updated_at, 2.days.ago)
        Service.record_timestamps = true
        
        Service.refresh_urls
        assert_nil Service.find_by_id(@service.id)
      end
    end
  end
end
