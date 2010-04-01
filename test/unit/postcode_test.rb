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
  end
  
  context 'an instance of the Postcode class' do
    should 'return pretty code' do
      assert_equal 'AB1D 3DL', Postcode.new(:code => 'AB1D3DL').pretty_code
    end
  end
end
