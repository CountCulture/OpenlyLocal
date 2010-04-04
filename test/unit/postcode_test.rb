require 'test_helper'

class PostcodeTest < ActiveSupport::TestCase
  subject { @postcode }
  
  def setup
    @postcode = Factory(:postcode, :code => 'AB13DR')
  end
  
  context "The Postcode class" do
    
    should_validate_presence_of :code, :lat, :lng
    should_validate_uniqueness_of :code
    should_have_db_columns :quality, :lat, :lng, :country, :nhs_region, :nhs_health_authority, :county_id, :council_id, :ward_id
    should_belong_to :ward
    should_belong_to :council
    should_belong_to :county
    
    should 'find from raw postcode' do
      assert_equal @postcode, Postcode.find_from_messy_code(' ab 1 3Dr ')
    end
    
    should 'have many councillors through ward' do
      ward = Factory(:ward)
      @postcode.update_attribute(:ward_id, ward.id)
      another_ward = Factory(:ward, :name => 'another ward', :council => ward.council)
      member = Factory(:member, :ward => ward, :council => ward.council)
      another_member = Factory(:member, :ward => another_ward, :council => ward.council)
      assert_equal [member], @postcode.councillors
    end
    
  end
  
  context 'an instance of the Postcode class' do
    should 'return pretty code' do
      assert_equal 'AB1D 3DL', Postcode.new(:code => 'AB1D3DL').pretty_code
    end
  end
end
