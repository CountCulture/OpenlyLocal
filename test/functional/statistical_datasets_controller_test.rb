require 'test_helper'

class StatisticalDatasetsControllerTest < ActionController::TestCase
  def setup
    @statistical_dataset = Factory(:statistical_dataset)
    @ons_dataset_family = Factory(:ons_dataset_family, :statistical_dataset => @statistical_dataset, :calculation_method => "sum")
  end

  # index test
  context "on GET to :index" do
    context "with basic request" do
      setup do
        get :index
      end

      should_assign_to(:statistical_datasets) { StatisticalDataset.all}
      should_respond_with :success
      should_render_template :index
      should "list statistical datasets" do
        assert_select "li a", @statistical_dataset.title
      end
      
      should 'show title' do
        assert_select "title", /datasets/i
      end
      
    end
  end
    
  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @statistical_dataset.id
      end

      should_assign_to :statistical_dataset
      should_respond_with :success
      should_render_template :show

      should "include statistical dataset in page title" do
        assert_select "title", /#{@statistical_dataset.title}/
      end

      should "list statistical dataset attributes" do
        assert_select '.attributes dd', /#{@statistical_dataset.url}/
      end
      
      should "list associated dataset families" do
        assert_select 'li a', /#{@ons_dataset_family.title}/
      end
    end
    
    context "with family that has calculated_datapoints_for_councils" do
      setup do
        @council_1, @council_2 = Factory(:council, :name => "Council 1"), Factory(:council, :name => "Council 2")
        dummy_datapoints = [BareDatapoint.new(:area => @council_1, :value => 123), BareDatapoint.new(:area => @council_2, :value => 456)]
        StatisticalDataset.any_instance.stubs(:calculated_datapoints_for_councils).returns(dummy_datapoints)
        get :show, :id => @statistical_dataset.id
      end

      should_assign_to :statistical_dataset
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

    context "with given area" do
      context "and basic request" do
        setup do
          @council = Factory(:council)
          
          @another_dataset_family = Factory(:ons_dataset_family, :statistical_dataset => @statistical_dataset, :calculation_method => "sum")
          @ons_dataset_topic = Factory(:ons_dataset_topic, :ons_dataset_family => @ons_dataset_family)
          @another_dataset_topic = Factory(:ons_dataset_topic, :ons_dataset_family => @another_dataset_family)

          @datapoint = Factory(:ons_datapoint, :area =>@council, :ons_dataset_topic => @ons_dataset_topic)
          @datapoint_for_another_topic = Factory(:ons_datapoint, :area => @council, :ons_dataset_topic => @another_dataset_topic) # this will have value of one more than @datapoint

          get :show, :id => @statistical_dataset.id, :area_type => "Council", :area_id => @council.id
        end

        should_assign_to :statistical_dataset
        should_assign_to(:area) { @council }
        should_respond_with :success
        should_render_template :show
        
        should "assign to datapoints bare datapoints with correct values in desc order" do
           dps = assigns(:datapoints)
           assert_kind_of BareDatapoint, dps.first
           assert_equal 2, dps.size
           assert_equal @datapoint_for_another_topic.value, dps.first.value
           assert_equal @datapoint_for_another_topic.ons_dataset_family, dps.first.ons_dataset_family
        end

        should "include statistical_dataset in page title" do
          assert_select "title", /#{@statistical_dataset.title}/
        end

        should "include area in page title" do
          assert_select "title", /#{@council.name}/
        end

        should "list datapoints" do
          assert_select ".datapoints" do
            assert_select '.ons_dataset_family', /#{@ons_dataset_family.title}/
            assert_select '.ons_dataset_family', /#{@another_dataset_family.title}/
          end
        end

        should "not list associated dataset families" do
          assert_select '#relationships li', :text => /#{@ons_dataset_family.title}/, :count => 0
        end
      end
    end

  end
end
