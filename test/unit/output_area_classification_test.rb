require File.expand_path('../../test_helper', __FILE__)

class OutputAreaClassificationTest < ActiveSupport::TestCase
  subject { @output_area_classification }
  context "The OutputAreaClassification class" do
    setup do
      @output_area_classification = Factory(:output_area_classification)
    end

    should_validate_presence_of :title, :uid, :level, :area_type
    should_validate_uniqueness_of :uid, :scoped_to => :area_type
  end

  context "A OutputAreaClassification instance" do
    setup do
      @output_area_classification = Factory(:output_area_classification)
    end
    
  end
end
