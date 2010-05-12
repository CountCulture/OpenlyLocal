require 'test_helper'

class AddressTest < ActiveSupport::TestCase
  subject { @address }
  
  context "The Address class" do
    setup do
      @address = Factory(:address)
    end
    
    should_have_db_columns :street_address, :locality, :postal_code, :country
    should_validate_presence_of :addressee_id, :addressee_type
    
    should 'belong to addressee polymorphically' do
      @address.addressee = (member = Factory(:member))
      assert_equal 'Member', @address.addressee_type
      assert_equal member.id, @address.addressee_id
    end
  end
    
  context 'an instance of the Address class' do
    
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
  end
end
