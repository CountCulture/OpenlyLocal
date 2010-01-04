require 'test_helper'

class DatasetFamiliesControllerTest < ActionController::TestCase
  def setup
    @dataset = Factory(:dataset)
    @dataset_family = Factory(:dataset_family, :dataset => @dataset)
    @another_dataset_family = Factory(:dataset_family, :dataset => @dataset)
    @dataset_topic = Factory(:dataset_topic, :dataset_family => @dataset_family, :muid => 1)
  end

  # routing tests
  should "route with council to show" do
    @council = Factory(:council)
    assert_routing("councils/42/dataset_families/123", {:controller => "dataset_families", :action => "show", :id => "123", :area_id => "42", :area_type => "Council"})
  end
  
  # index test
  context "on GET to :index" do

    context "with basic request" do
      setup do
        get :index
      end

      should_assign_to :datasets
      should_respond_with :success
      should_render_template :index

      should "list ons dataset families grouped by dataset" do
        assert_select "div#dataset_#{@dataset.id}" do
          assert_select 'li', @dataset_family.title
        end
      end
    end
  end

  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @dataset_family.id
      end

      should_assign_to :dataset_family
      should_respond_with :success
      should_render_template :show

      should "show ons dataset family title as page title" do
        assert_select "title", /#{@dataset_family.title}/
      end

      should "list ons dataset topics with extended title for dataset family" do
        assert_select "#dataset_topics" do
          assert_select 'li', @dataset_topic.extended_title
        end
      end
    end
    
    context "and dataset_family has ons_subjects" do
      setup do
        @ons_subject = Factory(:ons_subject)
        @ons_subject.dataset_families << @dataset_family
        get :show, :id => @dataset_family.id
      end
      
      should "list subjects for dataset family" do
        assert_select ".ons_subjects a", /#{@ons_subject.title}/
      end
    end

    context "with family that has calculated_datapoints_for_councils" do
      setup do
        @council_1, @council_2 = Factory(:council, :name => "Council 1"), Factory(:council, :name => "Council 2")
        dummy_datapoints = [BareDatapoint.new(:area => @council_1, :value => 123, :subject => @dataset_family), BareDatapoint.new(:area => @council_2, :value => 456, :subject => @dataset_family)]
        DatasetFamily.any_instance.expects(:calculated_datapoints_for_councils).returns(dummy_datapoints)
        get :show, :id => @dataset_family.id
      end

      should_assign_to :dataset_family
      should_assign_to :datapoints
      should_respond_with :success
      should_render_template :show
      
      should "show datapoints in table" do
        assert_select "table tr" do
          assert_select ".description", /#{@council_1.name}/
          assert_select ".value", /123/
        end
      end
      
      should "list ons dataset topics with extended title for dataset family" do
        assert_select "#dataset_topics" do
          assert_select 'li', @dataset_topic.extended_title
        end
      end
    end
  end
  
  context "on GET to :show with given area" do

    context "with basic request" do
      setup do
        @council = Factory(:council)
        @another_dataset_topic = Factory(:dataset_topic, :dataset_family => @dataset_family)
        @datapoint = Factory(:datapoint, :area =>@council, :dataset_topic => @dataset_topic)
        @datapoint_for_another_topic = Factory(:datapoint, :area => @council, :dataset_topic => @another_dataset_topic)
        
        get :show, :id => @dataset_family.id, :area_type => "Council", :area_id => @council.id
      end

      should_assign_to :dataset_family
      should_assign_to(:area) { @council }
      should_assign_to(:datapoints) { [@datapoint, @datapoint_for_another_topic] }
      should_respond_with :success
      should_render_template :show

      should "include ons dataset family in page title" do
        assert_select "title", /#{@dataset_family.title}/
      end

      should "include area in page title" do
        assert_select "title", /#{@council.name}/
      end

      should "list datapoints" do
        assert_select ".datapoints" do
          assert_select '.description', /#{@dataset_topic.title}/
          assert_select '.description', /#{@another_dataset_topic.title}/
        end
      end

      should "not list ons dataset topics with dataset family" do
        assert_select "#dataset_topics", false
      end

    end
  end

  
end
