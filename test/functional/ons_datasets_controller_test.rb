require 'test_helper'

class OnsDatasetsControllerTest < ActionController::TestCase
  def setup
    @ons_subject = Factory(:ons_subject)
    @ons_subject_2 = Factory(:ons_subject)
    @ons_dataset = Factory(:ons_dataset)
    @ons_dataset_family = @ons_dataset.ons_dataset_family
    @ons_dataset_family.ons_subjects << [@ons_subject, @ons_subject_2]
  end
  
  # index test
  context "on GET to :index" do
        
    context "with basic request" do
      setup do
        get :index
      end
      
      should_assign_to :ons_datasets_families
      should_respond_with :success
      should_render_template :index
      
      should "list ons dataset families" do
        assert_select "div.ons_dataset_family" do
          assert_select "h3", @ons_dataset_family.title
        end
      end
      
      should "list ons dataset subjects" do
        assert_select "div.ons_dataset_family .subject", 2 do
          @ons_subject.title
        end
      end
      
      should "list ons dataset for dataset family" do
        assert_select "div.ons_dataset_family .dataset" do
          @ons_dataset.title
        end
      end
    end
  end
  
  # index test
  context "on GET to :show" do
        
    context "with basic request" do
      setup do
        get :show, :id => @ons_dataset.id
      end
      
      should_assign_to :ons_dataset
      should_respond_with :success
      should_render_template :show
      
      should "show ons dataset extended title as page title" do
        assert_select "title", /#{@ons_dataset.extended_title}/
      end
      
      # should "list ons dataset for dataset family" do
      #   assert_select "div.ons_dataset_family .dataset" do
      #     @ons_dataset.title
      #   end
      # end
    end
  end
end
