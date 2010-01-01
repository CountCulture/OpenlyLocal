require 'test_helper'

class OnsDatasetFamiliesControllerTest < ActionController::TestCase
  def setup
    @statistical_dataset = Factory(:statistical_dataset)
    @ons_dataset_family = Factory(:ons_dataset_family, :statistical_dataset => @statistical_dataset)
    @another_dataset_family = Factory(:ons_dataset_family, :statistical_dataset => @statistical_dataset)
    @ons_dataset_topic = Factory(:ons_dataset_topic, :ons_dataset_family => @ons_dataset_family)
  end

  # index test
  context "on GET to :index" do

    context "with basic request" do
      setup do
        get :index
      end

      should_assign_to :statistical_datasets
      should_respond_with :success
      should_render_template :index

      should "list ons dataset families grouped by statistical_dataset" do
        assert_select "div#statistical_dataset_#{@statistical_dataset.id}" do
          assert_select 'li', @ons_dataset_family.title
        end
      end
    end
  end

  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @ons_dataset_family.id
      end

      should_assign_to :ons_dataset_family
      should_respond_with :success
      should_render_template :show

      should "show ons dataset family title as page title" do
        assert_select "title", /#{@ons_dataset_family.title}/
      end

      should "list ons dataset topics for dataset family" do
        assert_select "#ons_dataset_topics" do
          assert_select 'li', @ons_dataset_topic.title
        end
      end
    end
    
    context "and dataset_family has ons_subjects" do
      setup do
        @ons_subject = Factory(:ons_subject)
        @ons_subject.ons_dataset_families << @ons_dataset_family
        get :show, :id => @ons_dataset_family.id
      end
      
      should "list subjects for dataset family" do
        assert_select ".ons_subjects a", /#{@ons_subject.title}/
      end
    end

    context "with family that has calculated_datapoints_for_councils" do
      setup do
        @council_1, @council_2 = Factory(:council, :name => "Council 1"), Factory(:council, :name => "Council 2")
        dummy_datapoints = [BareDatapoint.new(:area => @council_1, :value => 123), BareDatapoint.new(:area => @council_2, :value => 456)]
        OnsDatasetFamily.any_instance.expects(:calculated_datapoints_for_councils).returns(dummy_datapoints)
        get :show, :id => @ons_dataset_family.id
      end

      should_assign_to :ons_dataset_family
      should_assign_to :datapoints
      should_respond_with :success
      should_render_template :show
      
      should "show datapoints in table" do
        assert_select "table tr" do
          assert_select ".description", /#{@council_1.name}/
          assert_select ".value", /123/
        end
      end
      
    end
  end
  
  context "on GET to :show with given area" do

    context "with basic request" do
      setup do
        @council = Factory(:council)
        @another_dataset_topic = Factory(:ons_dataset_topic, :ons_dataset_family => @ons_dataset_family)
        @datapoint = Factory(:ons_datapoint, :area =>@council, :ons_dataset_topic => @ons_dataset_topic)
        @datapoint_for_another_topic = Factory(:ons_datapoint, :area => @council, :ons_dataset_topic => @another_dataset_topic)
        
        get :show, :id => @ons_dataset_family.id, :area_type => "Council", :area_id => @council.id
      end

      should_assign_to :ons_dataset_family
      should_assign_to(:area) { @council }
      should_assign_to(:datapoints) { [@datapoint, @datapoint_for_another_topic] }
      should_respond_with :success
      should_render_template :show

      should "include ons dataset family in page title" do
        assert_select "title", /#{@ons_dataset_family.title}/
      end

      should "include area in page title" do
        assert_select "title", /#{@council.name}/
      end

      should "list datapoints" do
        assert_select ".datapoints" do
          assert_select '.ons_dataset_topic', /#{@ons_dataset_topic.title}/
          assert_select '.ons_dataset_topic', /#{@another_dataset_topic.title}/
        end
      end


    end
  end

  
end
