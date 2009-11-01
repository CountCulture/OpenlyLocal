require 'test_helper'

class OnsDatasetFamilyTest < ActiveSupport::TestCase
  subject { @ons_dataset_family }
  context "The OnsDatasetFamily class" do
    setup do
      @ons_dataset_family = Factory(:ons_dataset_family) 
    end
    should_validate_presence_of :title 
    should_validate_presence_of :ons_uid
    should_have_and_belong_to_many :ons_subjects
    should_have_many :ons_datasets
  end 
end
