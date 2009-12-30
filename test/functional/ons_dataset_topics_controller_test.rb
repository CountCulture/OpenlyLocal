require 'test_helper'

class OnsDatasetTopicsControllerTest < ActionController::TestCase

  def setup
    @council_1 = Factory(:council)
    @council_2 = Factory(:council, :name => "Second Council")
    @council_3 = Factory(:council, :name => "Third Council")
    @ons_dataset_topic = Factory(:ons_dataset_topic)
    @datapoint_1 = Factory(:ons_datapoint, :ons_dataset_topic => @ons_dataset_topic, :area => @council_1, :value => "9999")
    @datapoint_2 = Factory(:ons_datapoint, :ons_dataset_topic => @ons_dataset_topic, :area => @council_2)
    @datapoint_3 = Factory(:ons_datapoint, :ons_dataset_topic => @ons_dataset_topic, :area => @council_2, :value => "123456")
    10.times do |i|
      Factory(:ons_datapoint, :ons_dataset_topic => @ons_dataset_topic, :area => Factory(:council, :name => "Council #{i}"))
    end
  end

  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @ons_dataset_topic.id
      end

      should_assign_to :ons_dataset_topic
      should_assign_to :datapoints
      should_respond_with :success
      should_render_template :show

      should "return max 10 datapoints" do
        assert_equal 10, assigns(:datapoints).size
      end
      
      should "sort datapoints in descending order" do
        assert_equal @datapoint_3, assigns(:datapoints).first
      end
      
      should "include ons dataset topic in page title" do
        assert_select "title", /#{@ons_dataset_topic.title}/
      end

      should "link to ons dataset family" do
        assert_select 'a', @ons_dataset_topic.ons_dataset_family.title
      end

      should "list topic attributes" do
        assert_select '.attributes dd', /#{@ons_dataset_topic.ons_uid}/
      end
      
      should "list datapoints for councils" do
        assert_select "table.statistics" do
          assert_select ".datapoint", 10
        end
      end
      
      should "show council name for datapoints for councils" do
        assert_select "table.statistics .datapoint" do
          assert_select "a", /#{@council_1.title}/
        end
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

    should "show button to process ons_dataset_topic" do
      assert_select "form.button-to[action='/ons_dataset_topics/#{@ons_dataset_topic.to_param}/populate']"
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
    should_set_the_flash_to "Successfully updated OnsDatasetTopic"

    should "update ons_dataset_topic" do
      assert_equal "New title", @ons_dataset_topic.reload.short_title
    end
  end

  # populate tests
  context "on POST to :populate without auth" do
    setup do
      post :populate, :id => @ons_dataset_topic.id
    end
  
    should_respond_with 401
  end

  context "on POST to :populate with auth" do
    setup do
      stub_authentication
      post :populate, {:id => @ons_dataset_topic.id}
    end
  
    should_assign_to :ons_dataset_topic
    should_redirect_to( "the show page for ons_dataset_topic") { ons_dataset_topic_path(@ons_dataset_topic) }
    should_set_the_flash_to /Successfully queued Topic/
    
    before_should "queue up topic to be populated" do
      Delayed::Job.expects(:enqueue).with(instance_of(OnsDatasetTopic))
    end
  end


end
