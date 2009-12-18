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

      should "list topic attributes" do
        assert_select '.attributes dd', /#{@ons_dataset_topic.ons_uid}/
      end

    end
  end

  # edit tests
  context "on get to :edit a topic without auth" do
    setup do
      get :edit, :id => @ons_dataset_topic.id
    end

    should_respond_with 401
  end

  context "on get to :edit a topic" do
    setup do
      stub_authentication
      get :edit, :id => @ons_dataset_topic.id
    end

    should_assign_to :ons_dataset_topic
    should_respond_with :success
    should_render_template :edit
    should_not_set_the_flash
    should "display a form" do
     assert_select "form#edit_ons_dataset_topic_#{@ons_dataset_topic.id}"
    end

    should_eventually "show button to process ons_dataset_topic" do
      assert_select "form.button-to[action='/ons_dataset_topic/#{@ons_dataset_topic.to_param}']"
    end
  end

  # update tests
  context "on PUT to :update without auth" do
    setup do
      put :update, { :id => @ons_dataset_topic.id,
                     :ons_dataset_topic => { :short_title => "New title"}}
    end

    should_respond_with 401
  end

  context "on PUT to :update" do
    setup do
      stub_authentication
      put :update, { :id => @ons_dataset_topic.id,
                     :ons_dataset_topic => { :short_title => "New title"}}
    end

    should_assign_to :ons_dataset_topic
    should_redirect_to( "the show page for ons_dataset_topic") { ons_dataset_topic_path(@ons_dataset_topic.reload) }
    should_set_the_flash_to "Successfully updated ons_dataset_topic"

    should "update ons_dataset_topic" do
      assert_equal "New title", @ons_dataset_topic.reload.short_title
    end
  end


end
