require 'test_helper'

class LsoaTest < ActiveSupport::TestCase
  context "The Lsoa class" do
    setup do
      @ward = Factory(:lsoa)
    end
    
    should_validate_presence_of :oa_code, :lsoa_code, :lsoa_name#, :ward_id, :ward_snac_id
    should_validate_uniqueness_of :oa_code
    should_belong_to :ward
    
  end
end
