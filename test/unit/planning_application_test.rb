require 'test_helper'

class PlanningApplicationTest < ActiveSupport::TestCase
  context "the PlanningApplication class" do
    should validate_presence_of :council_id
    should validate_presence_of :uid
    should have_db_column :council_id
    should have_db_column :applicant_name
    should have_db_column :applicant_address
    should have_db_column :address
    should have_db_column :postcode
    should have_db_column :description
    should have_db_column :url
    should have_db_column :info_tinyurl
    should have_db_column :comment_url
    should have_db_column :comment_tinyurl
    should have_db_column :uid
    should have_db_column :retrieved_at
    should have_db_column :date_received
    should have_db_column :on_notice_from
    should have_db_column :on_notice_to
    should have_db_column :map_url
    should have_db_column :application_type
    should have_db_column :bitwise_flag

    should belong_to :council

    should "serialize other attributes" do
      assert_equal({:foo => 'bar'}, Factory(:planning_application, :other_attributes => {:foo => 'bar'}).reload.other_attributes)
    end
    
    should "set bitwise_flag to be zero if not set on creation" do
      assert_equal 0, Factory(:planning_application).bitwise_flag
      assert_equal 0, Factory(:planning_application, :bitwise_flag => nil).bitwise_flag
    end

    should "act as mappable" do
      assert PlanningApplication.respond_to?(:find_closest)
    end

    context "stale named scope" do
      setup do
        @no_details_application = Factory(:planning_application) #retrieved_at is nil
        @stale_application = Factory(:planning_application, :retrieved_at => 2.months.ago) 
        @too_old_to_be_stale_application = Factory(:planning_application, :retrieved_at => 4.months.ago)
        @stale_applications = PlanningApplication.stale
      end

      should "include applications where retrieved_at is nil" do
        assert @stale_applications.include?(@no_details_application)
      end
      
      should "include applications where retrieved at is more than a week ago" do
        assert @stale_applications.include?(@stale_application)
      end
      
      should "not include applications too old to be stale" do
        assert !@stale_applications.include?(@too_old_to_be_stale_application)
      end
    end
  end

  
  context "an instance of the PlanningApplication class" do
    setup do
      @planning_application = Factory(:planning_application)
    end
    
    context "when returning title" do
      should "use uid reference" do
        assert_equal "Planning Application AB123/456", PlanningApplication.new(:uid => 'AB123/456').title
      end
      
      should "use address if given" do
        assert_match /32 Acacia Avenue/, PlanningApplication.new(:address => '32 Acacia Avenue, Footown FOO1 3BA').title
      end
      
      should "use council reference and address if given" do
        application =  PlanningApplication.new(:uid => 'AB123/456', :address => '32 Acacia Avenue, Footown FOO1 3BA')
        assert_match /32 Acacia Avenue/, application.title
        assert_match /AB123\/456/, application.title
      end
    end
    
    should "alias uid attribute as council_reference" do
      pa = Factory(:planning_application)
      assert_equal pa.uid, pa.council_reference
      pa.council_reference = 'FOO1234'
      assert_equal 'FOO1234', pa.uid
    end
    
    should "return 13 for google_map_magnfication" do
      assert_equal 13, Factory(:planning_application).google_map_magnification
    end
    
    context "on save" do

      should "get inferred_lat_lng" do
        @planning_application.expects(:inferred_lat_lng)
        @planning_application.save!
      end

      should "update lat & lng with inferred_lat_lng" do
        @planning_application.stubs(:inferred_lat_lng).returns([12.1,23.2])
        @planning_application.save!
        assert_equal 12.1, @planning_application.lat
        assert_equal 23.2, @planning_application.lng
      end
      
      should "set lat, lng to nil if inferred_lat_lng is nil" do
        @planning_application.update_attributes(:lat => 22.2, :lng => 33.3)
        @planning_application.stubs(:inferred_lat_lng) # => nil
        @planning_application.save!
        assert_nil @planning_application.lat
        assert_nil @planning_application.lng
      end
      
      should "set not lat, lng to nil when inferred_lat_lng is nil if lat,lng has just changed" do
        @planning_application.lat = 22.2
        @planning_application.lng = 33.3
        @planning_application.stubs(:inferred_lat_lng) # => nil
        @planning_application.save!
        assert_equal 22.2, @planning_application.lat
        assert_equal 33.3, @planning_application.lng
      end
    end
    
    context "when assigning address" do
      setup do
        @dummy_address = '32 Acacia Avenue, Footown FO1 3BA'
      end
      
      should "not raise exception when address is blank" do
        assert_nothing_raised(Exception) { Factory.build(:planning_application, :address => nil) }
        assert_nothing_raised(Exception) { Factory.build(:planning_application, :address => '') }
      end

      should "set address attribute" do
        assert_equal @dummy_address, Factory(:planning_application, :address => @dummy_address)[:address]
      end
      
      should "remove extra spaces" do
        assert_equal @dummy_address, Factory(:planning_application, :address => "\n 32   Acacia Avenue,  Footown FO1 3BA  \n")[:address]
      end
      
      should "normalise line breaks" do
        assert_equal "32 Acacia Avenue\nFootown\nFOO1 3BA", Factory(:planning_application, :address => "32   Acacia Avenue\rFootown\rFOO1 3BA")[:address]
      end
      
      should "set postcode attribute" do
        assert_equal 'FO1 3BA', Factory(:planning_application, :address => @dummy_address)[:postcode]
      end
      
      context "and postcode already set" do
        setup do
          @planning_application = Factory(:planning_application, :address => @dummy_address)
          @new_address = '43 Cherry Road, Bartown BA2 5AB'
        end
        
        should "not set postcode if postcode has already changed" do
          @planning_application.postcode = 'AB1 3CD'
          @planning_application.address = @new_address
          assert_equal 'AB1 3CD', @planning_application.postcode
        end
        
        should "set postcode if postcode has not already changed" do
          @planning_application.address = @new_address
          assert_equal 'BA2 5AB', @planning_application.postcode
        end
      end
    end
    
    context "when setting bitwise flag" do

      should "do nothing if if nil given" do
        @planning_application[:bitwise_flag] = 0b0101
        @planning_application.bitwise_flag = nil
        assert_equal 0b0101, @planning_application.bitwise_flag
      end
      
      should "perform bitwise OR from given number" do
        @planning_application[:bitwise_flag] = 0b0101
        @planning_application.bitwise_flag = 0b0011
        assert_equal 0b0111, @planning_application.bitwise_flag
      end
      
      should "set to given number if currently nil" do
        @planning_application.bitwise_flag = 0b0010
        assert_equal 0b0010, @planning_application.bitwise_flag
      end
      
      should "set to zero if full count" do
        @planning_application[:bitwise_flag] = 0b1101
        @planning_application.bitwise_flag = 0b0010
        assert_equal 0, @planning_application.bitwise_flag
      end
    end
    
    context "when returning inferred lat long" do
      setup do
        @postcode = Factory(:postcode, :code => 'AB12CD')
      end
      
      should "return lat_long for postcode matching normalised postcode" do
        @planning_application.postcode = 'AB1 2CD'
        inferred_lat_lng = @planning_application.inferred_lat_lng
        assert_in_delta @postcode.lat, inferred_lat_lng.first, 0.01
        assert_in_delta @postcode.lng, inferred_lat_lng.last, 0.01
      end

      should "return nil if postcode is blank" do
        assert_nil @planning_application.inferred_lat_lng
      end
      
      should "return nil if no such postcode" do
        @planning_application.postcode = 'CD2 1AB'
        assert_nil @planning_application.inferred_lat_lng
      end
    end
  end
  
end
