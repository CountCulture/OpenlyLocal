require 'test_helper'

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
      
      should 'parse address' do
        original_and_parsed_address = {
          "32 Acacia Avenue, Anytown, AT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue\nAnytown\r\nAT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue\n Anytown\r\n AT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue,\n Anytown,\r\n AT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue, Little Village, Anytown, AT1 2BT" => {:street_address => '32 Acacia Avenue, Little Village', :postal_code => 'AT1 2BT', :locality => 'Anytown'},
          "32 Acacia Avenue, Anytown" => {:street_address => '32 Acacia Avenue', :postal_code => nil, :locality => 'Anytown'},
          "32, Acacia Avenue, Anytown, AT1 2BT" => {:street_address => '32 Acacia Avenue', :postal_code => 'AT1 2BT', :locality => 'Anytown'}
        }.each do |orig, parsed|
          blank_address = Address.new
          blank_address.in_full = orig
          assert parsed.all?{ |attrib,value| blank_address.send(attrib) == value }, "failed for #{orig}. Parsed address = #{blank_address.attributes.inspect}"
        end
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
      should "should queue for performing" do
        Delayed::Job.expects(:enqueue).with(@address)
        @address.save!
      end
    end
  end
end
