require 'test_helper'

class OutputAreaClassificationTest < ActiveSupport::TestCase
  context "The OutputAreaClassification class" do
    setup do
      @output_area_classification = Factory(:output_area_classification)
    end

    should_validate_presence_of :title, :uid, :level, :area_type
    should_validate_uniqueness_of :uid
  end

  context "A OutputAreaClassification instance" do
    setup do
      @output_area_classification = Factory(:output_area_classification)
    end
    
    # should "not be elected by default" do
    #   assert !@candidacy.elected?
    # end
  end
end
