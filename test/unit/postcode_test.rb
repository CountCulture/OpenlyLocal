require 'test_helper'

class PostcodeTest < ActiveSupport::TestCase
  subject { @postcode }
  def setup
    @postcode = Factory(:postcode)
  end
  
  context "The Postcode class" do
    
    should_validate_presence_of :code, :lat, :lng
    should_validate_uniqueness_of :code
    should_have_db_columns :quality, :lat, :lng, :country, :nhs_region, :nhs_health_authority, :county_id, :district_id, :ward_id
  end
end
