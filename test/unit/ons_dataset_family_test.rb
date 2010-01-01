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
    
    context "when returning calculated_datapoints_for_councils" do
      setup do
        @council_1 = Factory(:council)
        @council_2 = Factory(:council, :name => "Council 2")
        @council_3 = Factory(:council, :name => "Council 3")
        4.times do |i|
          topic = Factory(:ons_dataset_topic, :ons_dataset_family => @ons_dataset_family)
          Factory(:ons_datapoint, :ons_dataset_topic => topic, :area => @council_1, :value => i*2) # 0,2,4,6 => sum = 12
          Factory(:ons_datapoint, :ons_dataset_topic => topic, :area => @council_2, :value => i*4) # 0,4,6,8 => sum = 24
          Factory(:ons_datapoint, :ons_dataset_topic => topic, :area => @council_3, :value => i*3) # 0,3,6,9 => sum = 16
        end
      end
      
      should "return array of arrays" do
        assert_kind_of ActiveSupport::OrderedHash, dps = @ons_dataset_family.calculated_datapoints_for_councils
        assert_kind_of Array, dps.first
      end
      
      should "return council and sums as element of arrays" do
        dp = @ons_dataset_family.calculated_datapoints_for_councils.first
        assert_kind_of Council, dp.first
        assert_kind_of Float, dp.last
      end
      
      should "return sorted_by value, largest first" do
        dp = @ons_dataset_family.calculated_datapoints_for_councils.first
        assert_equal @council_2, dp.first
        assert_equal 24.0, dp.last
      end
    end
  end
  
end
