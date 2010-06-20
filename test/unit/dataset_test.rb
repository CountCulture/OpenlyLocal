require 'test_helper'

class DatasetTest < ActiveSupport::TestCase
  
  subject { @dataset }
  context "The Dataset class" do
    setup do
      @dataset = Factory(:dataset)
    end

    should_have_db_columns :title, :description, :url, :originator, :originator_url, :notes, :licence
    should_validate_presence_of :title, :originator
    should_validate_uniqueness_of :title
    should have_many :dataset_families
    should have_many :dataset_topics#, :through => :dataset_families
    should belong_to :dataset_topic_grouping
    
    should "return datasets belonging to a dataset_topic_grouping in_topic_grouping named scope" do
      @dataset_in_group = Factory(:dataset, :dataset_topic_grouping => Factory(:dataset_topic_grouping))
      
      assert_equal [@dataset_in_group], Dataset.in_topic_grouping
    end
  end

  context "A Dataset instance" do
    setup do
      @dataset = Factory(:dataset) 
    end
    
    context "when returning calculated_datapoints_for_councils" do
      setup do
        @dataset_family_1 = Factory(:dataset_family, :dataset => @dataset)
        @dataset_family_1.update_attribute(:calculation_method, "sum")
        @dataset_family_2 = Factory(:dataset_family, :dataset => @dataset)
        @dataset_family_2.update_attribute(:calculation_method, "sum")

        @council_1 = Factory(:council)
        @council_2 = Factory(:council, :name => "Council 2")
        @council_3 = Factory(:council, :name => "Council 3")
        4.times do |i|
          @topic_1 = Factory(:dataset_topic, :dataset_family => @dataset_family_1, :muid => 1)
          @topic_2 = Factory(:dataset_topic, :dataset_family => @dataset_family_2, :muid => 1)
          Factory(:datapoint, :dataset_topic => @topic_1, :area => @council_1, :value => i*2) # 0,2,4,6 => sum = 12
          Factory(:datapoint, :dataset_topic => @topic_2, :area => @council_2, :value => i*4) # 0,4,8,12 => sum = 24
          Factory(:datapoint, :dataset_topic => @topic_2, :area => @council_2, :value => i*3) # 0,3,6,9 => sum = 18
          Factory(:datapoint, :dataset_topic => @topic_2, :area => @council_3, :value => 0) # 0,0,0,0 => sum = 0
        end
      end
      
      should "return array of BareDapoints" do
        assert_kind_of Array, dps = @dataset.calculated_datapoints_for_councils
        assert_kind_of BareDatapoint, dps.first
      end
      
      should "assign councils to BareDapoints as areas" do
        dps = @dataset.calculated_datapoints_for_councils
        assert_equal @council_2, dps.first.area
        assert_equal @council_1, dps.last.area
      end
      
      should "assign dataset to BareDapoints as subject" do
        dps = @dataset.calculated_datapoints_for_councils
        assert_equal @dataset, dps.first.subject
        assert_equal @dataset, dps.last.subject
      end
      
      should "assign dataset_topic muid_format and muid_type to BareDapoints" do
        dps = @dataset.calculated_datapoints_for_councils
        assert_equal @topic_1.muid_format, dps.first.muid_format
        assert_equal @topic_1.muid_format, dps.last.muid_format
        assert_equal @topic_1.muid_type, dps.first.muid_type
        assert_equal @topic_1.muid_type, dps.last.muid_type
      end
      
      should "return sorted_by value, largest first" do
        dp = @dataset.calculated_datapoints_for_councils.first
        assert_equal @council_2, dp.area
        assert_equal 42.0, dp.value #sum of all datapoints for council_2
      end
      
      should "not return entries with zero value" do
        dps = @dataset.calculated_datapoints_for_councils
        assert !dps.any?{ |dp| dp.area == @council_3 }
      end
      
      should "return nil if no matching datapoints" do
        assert_nil Factory(:dataset).calculated_datapoints_for_councils
      end
      
      should "return nil if calculation_method is blank on any family" do
        @dataset_family_2.update_attribute(:calculation_method, "")
        assert_nil @dataset.calculated_datapoints_for_councils
      end
    end
    
    context "when returning calculated_datapoints_for a council" do
      setup do
        @dataset_family_1 = Factory(:dataset_family, :dataset => @dataset)
        @dataset_family_1.update_attribute(:calculation_method, "sum")
        @dataset_family_2 = Factory(:dataset_family, :dataset => @dataset)
        @dataset_family_2.update_attribute(:calculation_method, "sum")

        @council_1 = Factory(:council)
        @council_2 = Factory(:council, :name => "Council 2")
        @council_3 = Factory(:council, :name => "Council 3")
        4.times do |i|
          @topic_1 = Factory(:dataset_topic, :dataset_family => @dataset_family_1, :muid => 1)
          @topic_2 = Factory(:dataset_topic, :dataset_family => @dataset_family_2, :muid => 1)
          Factory(:datapoint, :dataset_topic => @topic_1, :area => @council_1, :value => i*2) # 0,2,4,6 => sum = 12
          Factory(:datapoint, :dataset_topic => @topic_1, :area => @council_2, :value => i*3) # 0,3,6,9 => sum = 18
          Factory(:datapoint, :dataset_topic => @topic_2, :area => @council_2, :value => i*4) # 0,4,8,12 => sum = 24
          Factory(:datapoint, :dataset_topic => @topic_2, :area => @council_3, :value => 0) # 0,0,0,0 => sum = 0
        end
      end
      
      should "return array of BareDapoints" do
        assert_kind_of Array, dps = @dataset.calculated_datapoints_for(@council_2)
        assert_kind_of BareDatapoint, dps.first
      end
      
      should "assign dataset_topic muid_format and muid_type to BareDapoints" do
        dps = @dataset.calculated_datapoints_for(@council_2)
        assert_equal @topic_1.muid_format, dps.first.muid_format
        assert_equal @topic_1.muid_format, dps.last.muid_format
        assert_equal @topic_1.muid_type, dps.first.muid_type
        assert_equal @topic_1.muid_type, dps.last.muid_type
      end
      
      should "assign council to BareDapoints as area" do
        dps = @dataset.calculated_datapoints_for(@council_2)
        assert_equal @council_2, dps.first.area
        assert_equal @council_2, dps.last.area
      end
      
      should "assign dataset_families to BareDapoints as subject" do
        dps = @dataset.calculated_datapoints_for(@council_2)
        assert_equal @dataset_family_2, dps.first.subject
        assert_equal @dataset_family_1, dps.last.subject
      end
      
      should "return sorted_by value, largest first" do
        dp = @dataset.calculated_datapoints_for(@council_2).first
        assert_equal @dataset_family_2, dp.subject
        assert_equal 24.0, dp.value # sum of all datapoints for council_2 for dataset_family_2
      end
      
      should_eventually "not return entries with zero value" do
        #think about this. Might be good to show zero values
      end
      
      should "return nil if no matching datapoints" do
        assert_nil Factory(:dataset).calculated_datapoints_for(@council_2)
      end
      
      should "return nil if calculation_method is blank on any family" do
        @dataset_family_2.update_attribute(:calculation_method, "")
        assert_nil @dataset.calculated_datapoints_for(@council_2)
      end
    end
  end


end
