require "test_helper"

class TestAreaModel <ActiveRecord::Base
  set_table_name "councils"
  include AreaMethods
end

class AreaMethodsTest < ActiveSupport::TestCase
  
  context "A class that includes AreaMethods mixin" do
    subject { @test_area }
    
    setup do
      @test_area = TestAreaModel.create!
    end
    
    should belong_to :output_area_classification
    should_have_one :boundary
     
    context 'and boundary association' do
      setup do
        @boundary = Factory(:boundary, :area => @test_area)
      end
      
      should 'be polymorphic as area' do
        assert_equal @test_area, @boundary.area
      end
    end
    
    should_have_many :datapoints
    context 'and datapoints association' do
      setup do
        @datapoint = Factory(:datapoint, :area => @test_area)
      end
      
      should 'be polymorphic as area' do
        assert_equal @test_area, @datapoint.area
      end
    end
    
    context 'when delegating hectares to boundary' do
      should 'return boundary hectares from associated boundary' do
        Factory(:boundary, :area => @test_area, :hectares => 42.5)
        assert_equal 42.5, @test_area.hectares
      end

      should 'return nil when no associated boundary' do
        assert_nil @test_area.hectares
      end
    end
    
    context "should have restrict_to_oac named_scope which" do
      setup do
        @oac = Factory(:output_area_classification)
        @another_test_area = TestAreaModel.create!(:output_area_classification => @oac)
      end
      
      should "restrict to areas with given output_area_classification id" do
        assert_equal [@another_test_area], TestAreaModel.restrict_to_oac({:output_area_classification_id => @oac.id})
      end

      should "return all areas if output_area_classification id is nil" do
        areas = TestAreaModel.restrict_to_oac({:output_area_classification_id => nil})
        assert areas.include?(@test_area)
        assert areas.include?(@another_test_area)
      end
      
      should "return no areas if output_area_classification id is non-existent" do
        assert_equal [], TestAreaModel.restrict_to_oac({:output_area_classification_id => -999})
      end
    end

    
  end
 
  context "An instance of a class that includes AreaMethods mixin" do
    setup do
      @test_area = TestAreaModel.create!
    end
    
    context "when getting grouped datapoints" do
      setup do
        @another_test_area = TestAreaModel.create!
        # @ward = Factory(:ward, :council => @another_test_area_model)
        
        @data_grouping_in_words = Factory(:dataset_topic_grouping, :title => "misc", :display_as => "in_words")
        @data_grouping_as_graph = Factory(:dataset_topic_grouping, :title => "demographics", :display_as => "graph")
        @basic_data_grouping = Factory(:dataset_topic_grouping, :title => "spending")
        @unused_data_grouping = Factory(:dataset_topic_grouping, :title => "foo")
        
        @selected_topic_1 = Factory(:dataset_topic, :dataset_topic_grouping => @basic_data_grouping, :title => "b title")
        @selected_topic_2 = Factory(:dataset_topic, :dataset_topic_grouping => @basic_data_grouping, :title => "a title")
        @selected_topic_3 = Factory(:dataset_topic, :dataset_topic_grouping => @basic_data_grouping, :title => "c title")
        @selected_topic_4 = Factory(:dataset_topic, :dataset_topic_grouping => @data_grouping_in_words)
        @selected_topic_5 = Factory(:dataset_topic, :dataset_topic_grouping => @data_grouping_as_graph)
        @unselected_topic = Factory(:dataset_topic)

        @selected_dp_1 = Factory(:datapoint, :area => @test_area, :dataset_topic => @selected_topic_1, :value => "3.99")
        @selected_dp_2 = Factory(:datapoint, :area => @test_area, :dataset_topic => @selected_topic_2, :value => "4.99")
        @selected_dp_3 = Factory(:datapoint, :area => @test_area, :dataset_topic => @selected_topic_3, :value => "2.99")
        @selected_dp_4 = Factory(:datapoint, :area => @test_area, :dataset_topic => @selected_topic_4)
        @selected_dp_5 = Factory(:datapoint, :area => @test_area, :dataset_topic => @selected_topic_5)
        @unselected_dp = Factory(:datapoint, :area => @test_area, :dataset_topic => @unselected_topic)
        @wrong_council_dp = Factory(:datapoint, :area => @another_test_area, :dataset_topic => @selected_topic_1)

        @dataset_data_grouping = Factory(:dataset_topic_grouping, :title => "datasets")        
        @grouped_dataset = Factory(:dataset, :dataset_topic_grouping => @dataset_data_grouping)
        @dataset_family_1 = Factory(:dataset_family, :dataset => @grouped_dataset, :calculation_method => "sum")
        @dataset_family_2 = Factory(:dataset_family, :dataset => @grouped_dataset, :calculation_method => "sum")
        @dataset_topic_1 = Factory(:dataset_topic, :dataset_family => @dataset_family_1)
        @dataset_topic_2 = Factory(:dataset_topic, :dataset_family => @dataset_family_2)
        4.times do |i|
          Factory(:datapoint, :area => @test_area, :dataset_topic => @dataset_topic_1, :value => 3.0*i) # 0,3,6,9 => 18
          Factory(:datapoint, :area => @test_area, :dataset_topic => @dataset_topic_2, :value => 4.0*i) # 0,4,8,12 => 24
        end
        
        @grouped_datapoints = @test_area.grouped_datapoints
      end

      should "return hash of arrays" do
        assert_kind_of ActiveSupport::OrderedHash, @grouped_datapoints
        assert_kind_of Array, @grouped_datapoints.values.first
      end
      
      should "use data groupings as keys of result hash" do
        assert @grouped_datapoints.keys.include?(@basic_data_grouping)
      end

      should "normally return Datapoints as Array elements" do
        assert_kind_of Datapoint, @grouped_datapoints.values.first.first
      end

      should "return datapoints for topics in groupings" do
        assert @grouped_datapoints.values.flatten.include?(@selected_dp_1)
      end

      should "not return datapoints with topics not in groupings" do
        assert !@grouped_datapoints.values.flatten.include?(@unselected_dp)
      end
      
      should "return in_words groupings first" do
        assert_equal @data_grouping_in_words, @grouped_datapoints.keys.first
      end
      
      should "return graph groupings next" do
        assert_equal @data_grouping_as_graph, @grouped_datapoints.keys[1]
      end
      
      should "return other groupings last" do
        assert_nil @grouped_datapoints.keys.last.display_as
      end
      
      should "not return groupings with no data" do
        assert_nil @grouped_datapoints[@unused_data_grouping]
      end
      
      should "not return datapoints for different areas" do
        assert !@grouped_datapoints.values.flatten.include?(@wrong_council_dp)
      end
      
      should "sort by associated topic order by default" do
        assert_equal @selected_dp_2, @grouped_datapoints[@basic_data_grouping].first
      end
      
      should "sort by associated topic order by default if sort_by is blank" do
        @basic_data_grouping.update_attribute(:sort_by, "")
        assert_equal @selected_dp_2, @grouped_datapoints[@basic_data_grouping].first
      end
      
      should "return sorted if data_grouping has sort_by set" do
        @basic_data_grouping.update_attribute(:sort_by, "value")
        assert_equal @selected_dp_3, @test_area.grouped_datapoints[@basic_data_grouping].first
      end
      
      context "and returning grouped dataset" do
        should "return array of BareDatapoints" do
          assert_kind_of BareDatapoint, @grouped_datapoints[@dataset_data_grouping].first
        end
        
        should "assign calculated datapoint to value of BareDatapoint" do
          assert_equal 18.0, @grouped_datapoints[@dataset_data_grouping].first.value
          assert_equal 24.0, @grouped_datapoints[@dataset_data_grouping].last.value
        end
      end
      
      should "not raise exception if no datapoints for grouped dataset" do
        # should arguably test this in Ward test, but for the moment keeping toge
        assert_nothing_raised(Exception) { @another_test_area.grouped_datapoints }
      end
      
    end
  end  
  
end
