require 'test_helper'

class OnsDatasetTopicsControllerTest < ActionController::TestCase

  def setup
    @ons_dataset_topic = Factory(:ons_dataset_topic)
  end

  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @ons_dataset_topic.id
      end

      should_assign_to :ons_dataset_topic
      should_respond_with :success
      should_render_template :show

      should "include ons dataset topic in page title" do
        assert_select "title", /#{@ons_dataset_topic.title}/
      end

      should "link to ons dataset family" do
        assert_select 'a', @ons_dataset_topic.ons_dataset_family.title
      end

      should "list subjects for dataset family" do
        assert_select ".ons_subjects a", /#{@ons_dataset_topic.ons_subjects.first.title}/
      end

      should "list topic attributes" do
        assert_select '.attribute .data', @ons_dataset_topic.ons_uid
      end

#      should "list ons dataset topics for dataset family" do
#        assert_select "#ons_dataset_topics" do
#          assert_select 'li', @ons_dataset_topic.title
#        end
#      end
    end
  end
end
