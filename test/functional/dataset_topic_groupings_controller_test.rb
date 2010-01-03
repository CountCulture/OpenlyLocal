require 'test_helper'

class DatasetTopicGroupingsControllerTest < ActionController::TestCase
  def setup
    @dataset_topic_grouping = Factory(:dataset_topic_grouping)
  end

  # index test
  context "on GET to :index" do
    context "without auth" do
      setup do
        get :index
      end

      should_respond_with 401
    end
    
    context "with basic request" do
      setup do
        stub_authentication
        get :index
      end

      should_assign_to(:dataset_topic_groupings) { DatasetTopicGrouping.find(:all)}
      should_respond_with :success
      should_render_template :index
      should "list Topic Groupings" do
        assert_select "li a", @dataset_topic_grouping.title
      end

      should 'show title' do
        assert_select "title", /Topic Groupings/i
      end

    end
  end

  # show test
  context "on GET to :show" do

    context "without auth" do
      setup do
        get :show, :id => @dataset_topic_grouping.id
      end

      should_respond_with 401
    end

    context "with basic request" do
      setup do
        stub_authentication
        @dataset_topic = Factory(:dataset_topic, :dataset_topic_grouping => @dataset_topic_grouping)
        get :show, :id => @dataset_topic_grouping.id
      end

      should_assign_to :dataset_topic_grouping
      should_respond_with :success
      should_render_template :show

      should "include Topic Grouping in page title" do
        assert_select "title", /#{@dataset_topic_grouping.title}/
      end

      should "list associated dataset_topics" do
        assert_select 'li a', @dataset_topic.title
      end
    end
  end

  # new test
  context "on GET to :new without auth" do
    setup do
      get :new
    end

    should_respond_with 401
  end

  context "on GET to :new" do
    setup do
      stub_authentication
      get :new
    end

    should_assign_to(:dataset_topic_grouping)
    should_respond_with :success
    should_render_template :new

    should "show form" do
      assert_select "form#new_dataset_topic_grouping"
    end

    should "show possible display options in select box" do
      assert_select "select#dataset_topic_grouping_display_as"
    end
  end  

  # create test
   context "on POST to :create" do

     context "without auth" do
       setup do
         post :create, :dataset_topic_grouping => {:title => "New Topic Grouping"}
       end

       should_respond_with 401
     end

     context "with valid params" do
       setup do
         stub_authentication
         post :create, :dataset_topic_grouping => {:title => "New Topic Grouping"}
       end

       should_change "DatasetTopicGrouping.count", :by => 1
       should_assign_to :dataset_topic_grouping
       should_redirect_to( "the show page for dataset_topic_grouping") { dataset_topic_grouping_url(assigns(:dataset_topic_grouping)) }
       should_set_the_flash_to /Successfully created/

     end

     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :dataset_topic_grouping => {:title => ""}
       end

       should_not_change "DatasetTopicGrouping.count"
       should_assign_to :dataset_topic_grouping
       should_render_template :new
       should_not_set_the_flash
     end

   end  

  # edit tests
  context "on get to :edit a Topic Grouping without auth" do
    setup do
      get :edit, :id => @dataset_topic_grouping.id
    end

    should_respond_with 401
  end

  context "on get to :edit a Topic Grouping" do
    setup do
      stub_authentication
      get :edit, :id => @dataset_topic_grouping.id
    end

    should_assign_to :dataset_topic_grouping
    should_respond_with :success
    should_render_template :edit
    should_not_set_the_flash
    should "display a form" do
     assert_select "form#edit_dataset_topic_grouping_#{@dataset_topic_grouping.id}"
    end

  end

  # update tests
  context "on PUT to :update without auth" do
    setup do
      put :update, { :id => @dataset_topic_grouping.id,
                     :dataset_topic_grouping => { :title => "New title"}}
    end

    should_respond_with 401
  end

  context "on PUT to :update" do
    setup do
      stub_authentication
      put :update, { :id => @dataset_topic_grouping.id,
                     :dataset_topic_grouping => { :title => "New title"}}
    end

    should_assign_to :dataset_topic_grouping
    should_redirect_to( "the show page for dataset_topic_grouping") { dataset_topic_grouping_url(@dataset_topic_grouping.reload) }
    should_set_the_flash_to /Successfully updated/

    should "update dataset_topic_grouping" do
      assert_equal "New title", @dataset_topic_grouping.reload.title
    end
  end

  # delete tests
  context "on delete to :destroy a dataset_topic_grouping without auth" do
    setup do
      delete :destroy, :id => @dataset_topic_grouping.id
    end

    should_respond_with 401
  end

  context "on delete to :destroy a dataset_topic_grouping" do

    setup do
      stub_authentication
      delete :destroy, :id => @dataset_topic_grouping.id
    end

    should "destroy dataset_topic_grouping" do
      assert_nil DatasetTopicGrouping.find_by_id(@dataset_topic_grouping.id)
    end
    should_redirect_to ( "the dataset_topic_groupings index page") { dataset_topic_groupings_url }
    should_set_the_flash_to /Successfully destroyed/
  end
end
