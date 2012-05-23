require File.expand_path('../../test_helper', __FILE__)

class OutputAreaClassificationTest < ActiveSupport::TestCase
  subject { @output_area_classification }
  context "The OutputAreaClassification class" do
    setup do
      @output_area_classification = Factory(:output_area_classification)
    end

    [:title, :uid, :level, :area_type].each do |attribute|
      should validate_presence_of attribute
    end
    should validate_uniqueness_of(:uid).scoped_to :area_type
  end

  context "A OutputAreaClassification instance" do
    setup do
      @output_area_classification = Factory(:output_area_classification)
    end
    
  end
end
