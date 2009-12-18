require 'test_helper'

class OnsDatapointsControllerTest < ActionController::TestCase

  # index test
  context "on GET to :show" do
  setup do
    @datapoint = Factory(:ons_datapoint)
    @ward = @datapoint.ward
    @another_ward = Factory(:ward, :name => 'Another Ward', :council => @ward.council)
    @datapoint_for_another_ward = Factory(:ons_datapoint, :ward => @another_ward, :ons_dataset_topic => @datapoint.ons_dataset_topic)
  end

    context "with basic request" do
      setup do
        get :show, :id => @datapoint.id
      end

      should_assign_to(:datapoints) { [@datapoint_for_another_ward, @datapoint] }
      should_respond_with :success
      should_render_template :show

      should "show details for datapoint" do
        assert_select 'h1', /#{@datapoint.ons_dataset_topic.title}/
      end

      should "show link to ward name in title" do
        assert_select 'title', /#{@ward.name}/
      end

      should "show link to council for datapoint ward" do
        assert_select 'a', /#{@ward.council.name}/
      end

      should "show show council name in title" do
        assert_select 'title', /#{@ward.council.name}/
      end

      should "list datapoints" do
        assert_select ".datapoints" do
          assert_select '.ward', /#{@ward.name}/
          assert_select '.ward', /#{@another_ward.name}/
        end
      end

      should "list datapoints in alpha order" do
        assert_select ".datapoints", /#{@another_ward.name}.+#{@ward.name}/m
      end

      should "identify given datapoint" do
        assert_select ".datapoints .selected", /#{@ward.name}/
      end

      should "show use background-position to make graph" do
        expected_position = 8*(100.0/@datapoint_for_another_ward.value.to_f)*@datapoint.value.to_f #full length is 800px, scale so max value is 100%: (800/100)*(100.0/max_value)*datapoint.value.to_f
        actual_position = css_select( ".selected td.ward").first.to_s.scan(/background-position: ([\d\.]+)px/).to_s
        assert_in_delta(expected_position, actual_position, 0.1)
      end

      should "show source of data" do
        assert_select ".source a", @datapoint.ons_dataset_topic.title
      end
    end
  end
end
