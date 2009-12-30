require 'test_helper'

class StatisticalDatasetsControllerTest < ActionController::TestCase
  def setup
    @statistical_dataset = Factory(:statistical_dataset)
    @ons_dataset_family = Factory(:ons_dataset_family, :statistical_dataset => @statistical_dataset)
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
    
  end
end
