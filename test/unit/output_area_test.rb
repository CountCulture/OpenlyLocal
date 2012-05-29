require File.expand_path('../../test_helper', __FILE__)

class OutputAreaTest < ActiveSupport::TestCase
  subject { @output_area }
  context "The OutputArea class" do
    setup do
      @output_area = Factory(:output_area)
    end
    
    [:oa_code, :lsoa_code, :lsoa_name].each do |attribute|
      should validate_presence_of attribute
    end
    should validate_uniqueness_of :oa_code
    should belong_to :ward
    
  end
end
