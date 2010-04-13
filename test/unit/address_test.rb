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
    
end
