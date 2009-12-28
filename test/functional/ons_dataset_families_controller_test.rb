require 'test_helper'

class OnsDatasetFamiliesControllerTest < ActionController::TestCase
  def setup
    @ons_subject = Factory(:ons_subject)
    @ons_subject_2 = Factory(:ons_subject)
    @ons_dataset = Factory(:ons_dataset)
    @ons_dataset_family = @ons_dataset.ons_dataset_family
    @ons_dataset_family.ons_subjects << [@ons_subject, @ons_subject_2]
    @ons_dataset_topic = Factory(:ons_dataset_topic, :ons_dataset_family => @ons_dataset_family)
  end

  # index test
  context "on GET to :index" do

    context "with basic request" do
      setup do
        get :index
      end

      should_assign_to :ons_subjects
      should_respond_with :success
      should_render_template :index

      should "list ons dataset subjects" do
        assert_select "#ons_subjects li", 2 do
          @ons_subject.title
        end
      end

      should "list ons dataset families grouped by subject" do
        assert_select "div#ons_subject_#{@ons_subject.id}" do
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

      should "list ons datasets for dataset family" do
        assert_select "#ons_datasets" do
          assert_select 'li', @ons_dataset.title
        end
      end

      should "list subjects for dataset family" do
        assert_select ".ons_subjects a", /#{@ons_subject.title}/
      end

      should "list ons dataset topics for dataset family" do
        assert_select "#ons_dataset_topics" do
          assert_select 'li', @ons_dataset_topic.title
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
