require 'test_helper'

class OnsDatapointsControllerTest < ActionController::TestCase

  # index test
  context "on GET to :show" do
  setup do
    @datapoint = Factory(:ons_datapoint)
    @ward = @datapoint.ward
    @another_ward = Factory(:ward, :name => 'another ward', :council => @ward.council)
    @datapoint_for_another_ward = Factory(:ons_datapoint, :ward => @another_ward, :ons_dataset_topic => @datapoint.ons_dataset_topic)
  end

    context "with basic request" do
      setup do
        get :show, :id => @datapoint.id
      end

      should_assign_to(:ons_datapoint) {@ons_datapoint}
      should_assign_to(:related_datapoints) { [@datapoint_for_another_ward] }
      should_respond_with :success
      should_render_template :show

      should "show details for datapoint" do
        assert_select 'h1', /#{@datapoint.ons_dataset_topic.title}/
      end

      should "list datapoints" do
        assert_select "dl.datapoints" do
          assert_select '.ward', /#{@datapoint.ward.name}/
          assert_select '.ward', /#{@datapoint_for_another_ward.ward.name}/
        end
      end

      should "indentify ward for given datapoint" do
        assert_select "dl.datapoints .selected", /#{@datapoint.ward.name}/
      end
    end
  end
end
