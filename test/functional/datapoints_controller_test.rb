require 'test_helper'

class DatapointsControllerTest < ActionController::TestCase
  def setup
    @council = Factory(:council, :authority_type => "District")
    @related_council = Factory(:council, :name => "Related council", :authority_type => "District")
    @ward = Factory(:ward, :council => @council)
    @another_ward = Factory(:ward, :name => 'Another Ward', :council => @council)
    
    @datapoint = Factory(:datapoint, :area => @ward)
    @dataset_topic = @datapoint.dataset_topic
    @datapoint_for_another_ward = Factory(:datapoint, :area => @another_ward, :dataset_topic => @dataset_topic)
    @council_datapoint = Factory(:datapoint, :area => @council, :dataset_topic => @dataset_topic)
    @related_council_datapoint = Factory(:datapoint, :area => @related_council, :dataset_topic => @dataset_topic)
  end



  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @datapoint.id
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
        assert_select "table.datapoints caption", /comparison.+wards in.+#{@council.name}/i
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

      should "show use background-position to make graph" do
        expected_position = 7.7*(100.0/@datapoint_for_another_ward.value.to_f)*@datapoint.value.to_f #full length is 770px (inc 2 x 5px padding), scale so max value is 100%: (800/100)*(100.0/max_value)*datapoint.value.to_f
        actual_position = css_select( ".selected td.description").first.to_s.scan(/background-position:([\d\.]+)px/).to_s
        assert_in_delta(expected_position, actual_position, 0.1)
      end

      should "show source of data" do
        assert_select ".source a", @datapoint.dataset_topic.title
      end
    end
    
    context "with basic request for council datapoint" do
      setup do
        get :show, :id => @council_datapoint.id
      end

      should_assign_to(:datapoints) { [@council_datapoint, @related_council_datapoint] }
      should_assign_to(:area) { @council }
      should respond_with :success
      should render_template :show

      should "show details for datapoint" do
        assert_select 'h1', /#{@council_datapoint.dataset_topic.title}/
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
