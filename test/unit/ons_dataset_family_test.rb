require 'test_helper'

class OnsDatasetFamilyTest < ActiveSupport::TestCase
  subject { @ons_dataset_family }
  context "The OnsDatasetFamily class" do
    setup do
      @ons_dataset_family = Factory(:ons_dataset_family) 
    end
    should_validate_presence_of :title 
    should_validate_presence_of :source_type
    should_validate_presence_of :statistical_dataset_id
    should_have_and_belong_to_many :ons_subjects
    should_have_many :ons_datasets
    should_have_many :ons_dataset_topics
    should_have_many :ons_datapoints, :through => :ons_dataset_topics
    should_belong_to :statistical_dataset
  end 
  
  
  context "An OnsDatasetFamily instance" do
    setup do
      @ons_dataset_family = Factory(:ons_dataset_family) 
    end

    should "return statistical dataset in array as parents" do
      assert_equal [@ons_dataset_family.statistical_dataset], @ons_dataset_family.parents
    end
  end
  
end
