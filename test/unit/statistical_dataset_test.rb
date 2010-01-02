require 'test_helper'

class StatisticalDatasetTest < ActiveSupport::TestCase
  
  subject { @statistical_dataset }
  context "The StatisticalDataset class" do
    setup do
      @statistical_dataset = Factory(:statistical_dataset)
    end

    should_have_db_columns :title, :description, :url, :originator, :originator_url
    should_validate_presence_of :title, :originator
    should_validate_uniqueness_of :title
    should_have_many :ons_dataset_families
    should_have_many :ons_dataset_topics, :through => :ons_dataset_families

  end

  context "A StatisticalDataset instance" do
    setup do
      @statistical_dataset = Factory(:statistical_dataset) 
    end
    
    context "when returning calculated_datapoints_for_councils" do
      setup do
        @ons_dataset_family_1 = Factory(:ons_dataset_family, :statistical_dataset => @statistical_dataset)
        @ons_dataset_family_1.update_attribute(:calculation_method, "sum")
        @ons_dataset_family_2 = Factory(:ons_dataset_family, :statistical_dataset => @statistical_dataset)
        @ons_dataset_family_2.update_attribute(:calculation_method, "sum")

        @council_1 = Factory(:council)
        @council_2 = Factory(:council, :name => "Council 2")
        @council_3 = Factory(:council, :name => "Council 3")
        4.times do |i|
          @topic_1 = Factory(:ons_dataset_topic, :ons_dataset_family => @ons_dataset_family_1, :muid => 1)
          @topic_2 = Factory(:ons_dataset_topic, :ons_dataset_family => @ons_dataset_family_2, :muid => 1)
          Factory(:ons_datapoint, :ons_dataset_topic => @topic_1, :area => @council_1, :value => i*2) # 0,2,4,6 => sum = 12
          Factory(:ons_datapoint, :ons_dataset_topic => @topic_2, :area => @council_2, :value => i*4) # 0,4,8,12 => sum = 24
          Factory(:ons_datapoint, :ons_dataset_topic => @topic_2, :area => @council_2, :value => i*3) # 0,3,6,9 => sum = 18
          Factory(:ons_datapoint, :ons_dataset_topic => @topic_2, :area => @council_3, :value => 0) # 0,0,0,0 => sum = 0
        end
      end
      
      should "return array of BareDapoints" do
        assert_kind_of Array, dps = @statistical_dataset.calculated_datapoints_for_councils
        assert_kind_of BareDatapoint, dps.first
      end
      
      should "assign ons_dataset_topic muid_format and muid_type to BareDapoints" do
        dps = @statistical_dataset.calculated_datapoints_for_councils
        assert_equal @topic_1.muid_format, dps.first.muid_format
        assert_equal @topic_1.muid_format, dps.last.muid_format
        assert_equal @topic_1.muid_type, dps.first.muid_type
        assert_equal @topic_1.muid_type, dps.last.muid_type
      end
      
      should "return sorted_by value, largest first" do
        dp = @statistical_dataset.calculated_datapoints_for_councils.first
        assert_equal @council_2, dp.area
        assert_equal 42.0, dp.value #sum of all datapoints for council_2
      end
      
      should "not return entries with zero value" do
        dps = @statistical_dataset.calculated_datapoints_for_councils
        assert !dps.any?{ |dp| dp.area == @council_3 }
      end
      
      should "return nil if no matching datapoints" do
        assert_nil Factory(:statistical_dataset).calculated_datapoints_for_councils
      end
      
      should "return nil if calculation_method is blank on any family" do
        @ons_dataset_family_2.update_attribute(:calculation_method, "")
        assert_nil @statistical_dataset.calculated_datapoints_for_councils
      end
    end
    
  end


end
