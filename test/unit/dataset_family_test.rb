require File.expand_path('../../test_helper', __FILE__)

class DatasetFamilyTest < ActiveSupport::TestCase
  subject { @dataset_family }
  context "The DatasetFamily class" do
    setup do
      @dataset_family = Factory(:dataset_family) 
    end
    should validate_presence_of :title 
    should validate_presence_of :source_type
    should validate_presence_of :dataset_id
    should have_and_belong_to_many :ons_subjects
    should have_many :ons_datasets
    should have_many :dataset_topics
    should have_many(:datapoints).through :dataset_topics
    should belong_to :dataset
    should have_db_column :calculation_method
  end 
  
  
  context "An DatasetFamily instance" do
    setup do
      @dataset_family = Factory(:dataset_family) 
    end

    should "return statistical dataset in array as parents" do
      assert_equal [@dataset_family.dataset], @dataset_family.parents
    end
    
    context "when returning calculated_datapoints_for_councils" do
      setup do
        @dataset_family.update_attribute(:calculation_method, "sum")
        @council_1 = Factory(:council)
        @council_2 = Factory(:council, :name => "Council 2")
        @council_3 = Factory(:council, :name => "Council 3")
        @council_4 = Factory(:council, :name => "Council 4")
        4.times do |i|
          @topic = Factory(:dataset_topic, :dataset_family => @dataset_family, :muid => 1)
          Factory(:datapoint, :dataset_topic => @topic, :area => @council_1, :value => i*2) # 0,2,4,6 => sum = 12
          Factory(:datapoint, :dataset_topic => @topic, :area => @council_2, :value => i*4) # 0,4,8,12 => sum = 24
          Factory(:datapoint, :dataset_topic => @topic, :area => @council_3, :value => i*3) # 0,3,6,9 => sum = 18
          Factory(:datapoint, :dataset_topic => @topic, :area => @council_4, :value => 0) # 0,0,0,0 => sum = 0
        end
      end
      
      should "return array of BareDapoints" do
        assert_kind_of Array, dps = @dataset_family.calculated_datapoints_for_councils
        assert_kind_of BareDatapoint, dps.first
      end
      
      should "assign dataset_topic muid_format and muid_type to BareDapoints" do
        dps = @dataset_family.calculated_datapoints_for_councils
        assert_equal @topic.muid_format, dps.first.muid_format
        assert_equal @topic.muid_format, dps.last.muid_format
        assert_equal @topic.muid_type, dps.first.muid_type
        assert_equal @topic.muid_type, dps.last.muid_type
      end
      
      should "assign dataset_family to BareDapoints as subject" do
        dps = @dataset_family.calculated_datapoints_for_councils
        assert_equal @dataset_family, dps.first.subject
        assert_equal @dataset_family, dps.last.subject
      end
      
      should "return sorted_by value, largest first" do
        dp = @dataset_family.calculated_datapoints_for_councils.first
        assert_equal @council_2, dp.area
        assert_equal 24.0, dp.value
      end
      
      should "not return entries with zero value" do
        dps = @dataset_family.calculated_datapoints_for_councils
        assert !dps.any?{ |dp| dp.area == @council_4 }
      end
      
      should "return nil if no matching datapoints" do
        assert_nil Factory(:dataset_family).calculated_datapoints_for_councils
      end
      
      should "return nil if calculation_method is blank" do
        @dataset_family.update_attribute(:calculation_method, "")
        assert_nil @dataset_family.calculated_datapoints_for_councils
      end
      
      should "alias title as short_title" do
        assert_equal @dataset_family.title, @dataset_family.short_title
      end
    end
  end
  
end
