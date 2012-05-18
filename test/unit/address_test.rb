require File.expand_path('../../test_helper', __FILE__)

class AddressTest < ActiveSupport::TestCase
  subject { @address }
  
  context "The Address class" do
    setup do
      @address = Factory(:address)
    end
    
    should have_db_column :street_address    
    should have_db_column :locality    
    should have_db_column :postal_code    
    should have_db_column :country    
    should have_db_column :region    
    should have_db_column :former
    should have_db_column :lat
    should have_db_column :lng
    should have_db_column :raw_address    
    should validate_presence_of :addressee_id
    should validate_presence_of :addressee_type
    
    should 'belong to addressee polymorphically' do
      @address.addressee = (member = Factory(:member))
      assert_equal 'Member', @address.addressee_type
      assert_equal member.id, @address.addressee_id
    end
  end
    
  context 'an instance of the Address class' do
    setup do
      @address = Factory(:address)
    end
    
    context 'when returning in full' do
      should 'build from address attributes' do
        assert_equal '32 Acacia Avenue, Anytown, AT1 2BT', Factory.build(:address, :street_address => '32 Acacia Avenue', :locality => 'Anytown', :postal_code => 'AT1 2BT').in_full
      end
      
      should 'skip missing fields' do
        assert_equal '32 Acacia Avenue, Anytown', Factory.build(:address, :street_address => '32 Acacia Avenue', :locality => 'Anytown').in_full
        assert_equal '32 Acacia Avenue, Anytown', Factory.build(:address, :street_address => '32 Acacia Avenue', :locality => 'Anytown', :postal_code => '').in_full
        assert_equal '32 Acacia Avenue, AT1 2BT', Factory.build(:address, :street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT').in_full
        assert_equal '32 Acacia Avenue, AT1 2BT', Factory.build(:address, :street_address => '32 Acacia Avenue', :locality => '', :postal_code => 'AT1 2BT').in_full
      end
    end
    
    context 'when setting address from in full' do
      setup do
        @address_text = "32 Acacia Avenue, Anytown, AT1 2BT, United Kingdom"
      end
      
      should 'parse address' do
        AddressUtilities::Parser.expects(:parse).with(@address_text)
        @address.in_full = @address_text
      end
      
      should "set attributes to parsed address results" do
        
        address_result = {:street_address => '32 Acacia Avenue', 
                          :postal_code => 'AT1 2BT', 
                          :locality => 'Anytown', 
                          :country => 'United Kingdom'}
        Parser.stubs(:parse).returns(address_result)
        @address.in_full = @address_text
        assert_equal '32 Acacia Avenue', @address.street_address
        assert_equal 'Anytown', @address.locality
        assert_equal 'AT1 2BT', @address.postal_code
        assert_equal 'United Kingdom', @address.country
        
      end
    end

    context "when performing" do

      should "geocode address" do
        Geokit::LatLng.expects(:normalize).with(@address.in_full).returns(stub(:lat => 12.3, :lng => 34.5))
        @address.perform
      end

      should "update address with lat lng from geocoding" do
        Geokit::LatLng.stubs(:normalize).returns(stub(:lat => 12.3, :lng => 34.5))
        @address.perform
        assert_equal 12.3, @address.lat
        assert_equal 34.5, @address.lng
      end

      should "not update address if error geocoding" do
        Geokit::LatLng.stubs(:normalize).raises(Geokit::Geocoders::GeocodeError)
        @address.perform
        assert_nil @address.lat
        assert_nil @address.lng
      end
    end
    
    context "after saving" do
      context "and latitude nil" do

        should "should queue for performing" do
          @address.expects(:delay => stub(:perform => nil))
          @address.save!
        end
      end
      
      context "and lat not nil" do
        setup do
          @address.update_attribute(:lat, 23.4)
        end

        should "should not queue for performing" do
          @address.expects(:delay).never
          @address.save!
        end
      end
    end
  end
end
