require 'test_helper'

class WardsHelperTest < ActionView::TestCase

  context "ons_statistics_graph helper method" do
    setup do
      datapoint_1 = stub(:value => '53', :title => '0-17')
      datapoint_2 = stub(:value => '42.3', :title => '18-25')
      datapoint_3 = stub(:value => '61', :title => '26-35')
      @statistics_group = {:demographics => [datapoint_1, datapoint_2, datapoint_3]}
    end

    should "should get pie chart for ons statistics data" do
      Gchart.expects(:pie).returns("http://foo.com//graph")
      ons_statistics_graph(@statistics_group)
    end

    should "should convert numbers from datapoints to floats" do
      Gchart.expects(:pie).with(has_entry( :data => [53.0,42.3,61.0])).returns("http://foo.com//graph")
      ons_statistics_graph(@statistics_group)
    end

    should "should use titles in legend" do
      Gchart.expects(:pie).with(has_entry( :legend => ['0-17', '18-25', '26-35'])).returns("http://foo.com//graph")
      ons_statistics_graph(@statistics_group)
    end

    should "return image tag using graph url as as src" do
      Gchart.stubs(:pie).returns("http://foo.com//graph")
      assert_dom_equal image_tag("http://foo.com//graph", :class => "chart", :alt => "Demographics graph"), ons_statistics_graph(@statistics_group)
    end

    should "not raise exception if no data" do
      assert_nothing_raised(Exception){ons_statistics_graph(nil)}
      assert_nothing_raised(Exception){ons_statistics_graph({})}
    end
  end

end
