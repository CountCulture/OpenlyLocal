require 'test_helper'

class OnsDatapointsControllerTest < ActionController::TestCase

  # show test
  context "on GET to :show" do
    setup do
      @council = Factory(:council, :authority_type => "District")
      @related_council = Factory(:council, :name => "Related council", :authority_type => "District")
      @ward = Factory(:ward, :council => @council)
      @another_ward = Factory(:ward, :name => 'Another Ward', :council => @council)
      
      @datapoint = Factory(:ons_datapoint, :area => @ward)
      @datapoint_for_another_ward = Factory(:ons_datapoint, :area => @another_ward, :ons_dataset_topic => @datapoint.ons_dataset_topic)
      @council_datapoint = Factory(:ons_datapoint, :area => @council)
      @related_council_datapoint = Factory(:ons_datapoint, :area => @related_council, :ons_dataset_topic => @council_datapoint.ons_dataset_topic)
    end

    context "with basic request" do
      setup do
        get :show, :id => @datapoint.id
      end

      should_assign_to(:datapoints) { [@datapoint_for_another_ward, @datapoint] }
      should_assign_to(:area) { @ward }
      should_respond_with :success
      should_render_template :show

      should "show details for datapoint" do
        assert_select 'h1', /#{@datapoint.ons_dataset_topic.title}/
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
        assert_select "table.datapoints caption", /comparison.+wards in.+#{@council.name}/i
      end

      should "list datapoints" do
        assert_select ".datapoints" do
          assert_select '.area', /#{@ward.name}/
          assert_select '.area', /#{@another_ward.name}/
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
        actual_position = css_select( ".selected td.area").first.to_s.scan(/background-position: ([\d\.]+)px/).to_s
        assert_in_delta(expected_position, actual_position, 0.1)
      end

      should "show source of data" do
        assert_select ".source a", @datapoint.ons_dataset_topic.title
      end
    end
    
    context "with basic request for council datapoint" do
      setup do
        get :show, :id => @council_datapoint.id
      end

      should_assign_to(:datapoints) { [@council_datapoint, @related_council_datapoint] }
      should_assign_to(:area) { @council }
      should_respond_with :success
      should_render_template :show

      should "show details for datapoint" do
        assert_select 'h1', /#{@council_datapoint.ons_dataset_topic.title}/
      end
      
      should "show show council name in title" do
        assert_select 'title', /#{@council.name}/
      end
      
      should "explain datapoint grouping in table caption" do
        assert_select "table.datapoints caption", /comparison.+district councils/i
      end

      should "identify given datapoint" do
        assert_select ".datapoints .selected", /#{@council.name}/
      end
    end
    
  end
end
