require 'test_helper'

class PostcodeTest < ActiveSupport::TestCase
  subject { @postcode }
  
  def setup
    @postcode = Factory(:postcode)
  end
  
  context "The Postcode class" do
    
    should_validate_presence_of :code, :lat, :lng
    should_validate_uniqueness_of :code
    should_have_db_columns :quality, :lat, :lng, :country, :nhs_region, :nhs_health_authority, :county_id, :council_id, :ward_id
    should_belong_to :ward
    should_belong_to :council
    should_belong_to :county
  end
  
  context 'an instance of the Postcode class' do
    should 'return pretty code' do
      assert_equal 'AB1D 3DL', Postcode.new(:code => 'AB1D3DL').pretty_code
    end
  end
end
