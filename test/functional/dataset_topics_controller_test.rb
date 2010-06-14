require 'test_helper'

class DatasetTopicsControllerTest < ActionController::TestCase

  def setup
    @council_1 = Factory(:council, :authority_type => "District")
    @council_2 = Factory(:council, :name => "Second Council")
    @council_3 = Factory(:council, :name => "Third Council")
    @dataset_topic = Factory(:dataset_topic)
    @datapoint_1 = Factory(:datapoint, :dataset_topic => @dataset_topic, :area => @council_1, :value => "9999")
    @datapoint_2 = Factory(:datapoint, :dataset_topic => @dataset_topic, :area => @council_2)
    @datapoint_3 = Factory(:datapoint, :dataset_topic => @dataset_topic, :area => @council_2, :value => "123456")
    10.times do |i|
      Factory(:datapoint, :dataset_topic => @dataset_topic, :area => Factory(:council, :name => "Council #{i}"))
    end
  end

  # routing tests
  should "route with council to show" do
    assert_routing("councils/42/dataset_topics/123", {:controller => "dataset_topics", :action => "show", :id => "123", :area_id => "42", :area_type => "Council"})
  end
  
  should "route with ward to show" do
    assert_routing("wards/42/dataset_topics/123", {:controller => "dataset_topics", :action => "show", :id => "123", :area_id => "42", :area_type => "Ward"})
  end
  
  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @dataset_topic.id
      end

      should_assign_to :dataset_topic
      should_assign_to :datapoints
      should respond_with :success
      should render_template :show

      # should "return max 10 datapoints" do
      #   assert_equal 10, assigns(:datapoints).size
      # end
      # 
      should "return all datapoints" do
        assert_equal 13, assigns(:datapoints).size
      end
      
      should "sort datapoints in descending order" do
        assert_equal @datapoint_3, assigns(:datapoints).first
      end
      
      should "include ons dataset topic in page title" do
        assert_select "title", /#{@dataset_topic.title}/
      end

      should "link to ons dataset family" do
        assert_select 'a', @dataset_topic.dataset_family.title
      end

      should "list topic attributes" do
        assert_select '.attributes dd', /#{@dataset_topic.ons_uid}/
      end
      
      should "list datapoints for councils" do
        assert_select "table.statistics" do
          assert_select ".datapoint", 13
        end
      end
      
      should "show council name for datapoints for councils" do
        assert_select "table.statistics .datapoint" do
          assert_select "a", /#{@council_1.title}/
        end
      end
    end
    
    context "with given area" do
      setup do
        @related_council = Factory(:council, :name => "Related council", :authority_type => "District")
        @ward = Factory(:ward, :council => @council_1)
        @another_ward = Factory(:ward, :name => 'Another Ward', :council => @council_1)

        @datapoint = Factory(:datapoint, :area => @ward)
        @dataset_topic = @datapoint.dataset_topic
        @datapoint_for_another_ward = Factory(:datapoint, :area => @another_ward, :dataset_topic => @dataset_topic)
        @council_datapoint = Factory(:datapoint, :area => @council_1, :dataset_topic => @dataset_topic)
        @related_council_datapoint = Factory(:datapoint, :area => @related_council, :dataset_topic => @dataset_topic)
      end
      
      context "and area is a council" do
        setup do
          get :show, :id => @dataset_topic.id, :area_type => "Council", :area_id => @council_1.id
        end

        should_assign_to :dataset_topic
        should_assign_to :datapoints
        should_assign_to(:area) {@council_1}
        should respond_with :success
        should render_template :show
      
        should "show show council name in title" do
          assert_select 'title', /#{@council_1.name}/
        end
      
        should "explain datapoint grouping in table caption" do
          assert_select "table.datapoints caption", /comparison.+district councils/i
        end

        should "identify given datapoint" do
          assert_select ".datapoints .selected", /#{@council_1.name}/
        end
      end
    
      context "with given ward" do
        setup do        
          get :show, :id => @dataset_topic.id, :area_type => "Ward", :area_id => @ward.id
        end

        should_assign_to(:datapoints) { [@datapoint_for_another_ward, @datapoint] }
        should_assign_to(:area) { @ward }
        should respond_with :success
        should render_template :show

        should "show details for datapoint" do
          assert_select 'h1', /#{@datapoint.dataset_topic.title}/
        end

        should "show link to ward name in title" do
          assert_select 'title', /#{@ward.name}/
        end

        should_eventually "show link to council for datapoint ward" do
          assert_select 'a', /#{@ward.council.name}/
        end

        should "show show council name in title" do
          assert_select 'title', /#{@ward.council.name}/
        end

        should "explain datapoint grouping in table caption" do
          assert_select "table.datapoints caption", /comparison.+wards in.+#{@council_1.name}/i
        end

        should "list datapoints" do
          assert_select ".datapoints" do
            assert_select '.description', /#{@ward.name}/
            assert_select '.description', /#{@another_ward.name}/
          end
        end

        should "list datapoints in alpha order" do
          assert_select ".datapoints", /#{@another_ward.name}.+#{@ward.name}/m
        end

        should "identify given datapoint" do
          assert_select ".datapoints .selected", /#{@ward.name}/
        end
      end
    end
  end

  # edit tests
  context "on get to :edit a topic without auth" do
    setup do
      get :edit, :id => @dataset_topic.id
    end

    should respond_with 401
  end

  context "on get to :edit a topic" do
    setup do
      stub_authentication
      get :edit, :id => @dataset_topic.id
    end

    should_assign_to :dataset_topic
    should respond_with :success
    should render_template :edit
    should_not set_the_flash
    should "display a form" do
     assert_select "form#edit_dataset_topic_#{@dataset_topic.id}"
    end

    should "show button to process dataset_topic" do
      assert_select "form.button-to[action='/dataset_topics/#{@dataset_topic.to_param}/populate']"
    end
  end

  # update tests
  context "on PUT to :update without auth" do
    setup do
      put :update, { :id => @dataset_topic.id,
                     :dataset_topic => { :short_title => "New title"}}
    end

    should respond_with 401
  end

  context "on PUT to :update" do
    setup do
      stub_authentication
      put :update, { :id => @dataset_topic.id,
                     :dataset_topic => { :short_title => "New title"}}
    end

    should_assign_to :dataset_topic
    should_redirect_to( "the show page for dataset_topic") { dataset_topic_path(@dataset_topic.reload) }
    should_set_the_flash_to "Successfully updated DatasetTopic"

    should "update dataset_topic" do
      assert_equal "New title", @dataset_topic.reload.short_title
    end
  end

  # populate tests
  context "on POST to :populate without auth" do
    setup do
      post :populate, :id => @dataset_topic.id
    end
  
    should respond_with 401
  end

  context "on POST to :populate with auth" do
    setup do
      stub_authentication
      post :populate, {:id => @dataset_topic.id}
    end
  
    should_assign_to :dataset_topic
    should_redirect_to( "the show page for dataset_topic") { dataset_topic_path(@dataset_topic) }
    should_set_the_flash_to /Successfully queued Topic/
    
    before_should "queue up topic to be populated" do
      Delayed::Job.expects(:enqueue).with(instance_of(DatasetTopic))
    end
  end


end
