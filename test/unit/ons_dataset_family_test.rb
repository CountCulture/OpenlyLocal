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
    should_have_db_column :calculation_method
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
        @ons_dataset_family.update_attribute(:calculation_method, "sum")
        @council_1 = Factory(:council)
        @council_2 = Factory(:council, :name => "Council 2")
        @council_3 = Factory(:council, :name => "Council 3")
        @council_4 = Factory(:council, :name => "Council 4")
        4.times do |i|
          @topic = Factory(:ons_dataset_topic, :ons_dataset_family => @ons_dataset_family, :muid => 1)
          Factory(:ons_datapoint, :ons_dataset_topic => @topic, :area => @council_1, :value => i*2) # 0,2,4,6 => sum = 12
          Factory(:ons_datapoint, :ons_dataset_topic => @topic, :area => @council_2, :value => i*4) # 0,4,8,12 => sum = 24
          Factory(:ons_datapoint, :ons_dataset_topic => @topic, :area => @council_3, :value => i*3) # 0,3,6,9 => sum = 18
          Factory(:ons_datapoint, :ons_dataset_topic => @topic, :area => @council_4, :value => 0) # 0,0,0,0 => sum = 0
        end
      end
      
      should "return array of BareDapoints" do
        assert_kind_of Array, dps = @ons_dataset_family.calculated_datapoints_for_councils
        assert_kind_of BareDatapoint, dps.first
      end
      
      should "assign ons_dataset_topic muid_format and muid_type to BareDapoints" do
        dps = @ons_dataset_family.calculated_datapoints_for_councils
        assert_equal @topic.muid_format, dps.first.muid_format
        assert_equal @topic.muid_format, dps.last.muid_format
        assert_equal @topic.muid_type, dps.first.muid_type
        assert_equal @topic.muid_type, dps.last.muid_type
      end
      
      should "return sorted_by value, largest first" do
        dp = @ons_dataset_family.calculated_datapoints_for_councils.first
        assert_equal @council_2, dp.area
        assert_equal 24.0, dp.value
      end
      
      should "not return entries with zero value" do
        dps = @ons_dataset_family.calculated_datapoints_for_councils
        assert !dps.any?{ |dp| dp.area == @council_4 }
      end
      
      should "return nil if no matching datapoints" do
        assert_nil Factory(:ons_dataset_family).calculated_datapoints_for_councils
      end
      
      should "return nil if calculation_method is blank" do
        @ons_dataset_family.update_attribute(:calculation_method, "")
        assert_nil @ons_dataset_family.calculated_datapoints_for_councils
      end
    end
  end
  
end
