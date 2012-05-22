require File.expand_path('../../../test_helper', __FILE__)

class WardsHelperTest < ActionView::TestCase
  include ApplicationHelper

  context "statistics_graph helper method" do
    setup do
      datapoint_1 = stub_everything(:value => 53, :short_title => '0-17')
      datapoint_2 = stub_everything(:value => 42.3, :short_title => '18-25')
      datapoint_3 = stub_everything(:value => 61, :short_title => '26-35')
      @statistics_group = {:demographics => [datapoint_1, datapoint_2, datapoint_3]}
    end

    should "should get pie chart for ons statistics data" do
      Gchart.expects(:pie).returns("http://foo.com//graph")
      statistics_graph(@statistics_group)
    end

    should "use datapoint values for graph" do
      Gchart.expects(:pie).with(has_entry( :data => [53,42.3,61])).returns("http://foo.com//graph")
      statistics_graph(@statistics_group)
    end

    should "should use titles in legend" do
      Gchart.expects(:pie).with(has_entry( :legend => ['0-17', '18-25', '26-35'])).returns("http://foo.com//graph")
      statistics_graph(@statistics_group)
    end

    should "return image tag using graph url as as src" do
      Gchart.stubs(:pie).returns("http://foo.com//graph")
      assert_dom_equal image_tag("http://foo.com//graph", :class => "chart", :alt => "Demographics graph"), statistics_graph(@statistics_group)
    end

    should "not raise exception if no data" do
      assert_nothing_raised(Exception){statistics_graph(nil)}
      assert_nothing_raised(Exception){statistics_graph({})}
    end
  end

  context "statistics_in_words helper method" do
    setup do
      # Muids = { 1 => ['Count'],
      #           2 => ['Percentage', "%.1f%"],
      #           9 => ['Pounds Sterling', "£%d"],
      #           14 => ['Years', "%.1f"]}
      @area = Factory(:council)
      @dataset_topic_1 = Factory(:dataset_topic, :short_title => '18-25')
      @dataset_topic_2 = Factory(:dataset_topic, :short_title => 'of the population', :muid => 2)
      @dataset_topic_3 = Factory(:dataset_topic, :short_title => '26-35 years olds', :muid => 14)
      @dataset_topic_4 = Factory(:dataset_topic, :short_title => 'has a mean age of', :muid => 14)
      self.stubs(:mocha_mock_path).returns('/foo') #url in stats, so just stub out all calls to object's path
      @datapoint_1 = BareDatapoint.new(:value => 534, :subject => @dataset_topic_1, :area => @area)
      @datapoint_2 = BareDatapoint.new(:value => 42.2, :subject => @dataset_topic_2, :area => @area, :muid_type => 'Percentage', :muid_format => "%.1f%")
      @datapoint_3 = BareDatapoint.new(:value => 61, :subject => @dataset_topic_3, :area => @area)
      @datapoint_4 = BareDatapoint.new(:value => 75, :subject => @dataset_topic_4, :area => @area)
      statistics_group = {:demographics => [@datapoint_1, @datapoint_2, @datapoint_3, @datapoint_4]}
      @result = statistics_in_words(statistics_group)
    end


    should "should return text with stats" do
      assert_match /534.+18\-25/, @result
    end

    should "should use muid format for number" do
      
      assert_match /42.2%.+of the population/, @result
    end

    # should "should put number after number for age" do
    #   assert_match /has a mean age of.+75/, @result
    # end
    # 
    should "should link to datapoints" do
      assert_match /href=\"\/councils\/#{@area.to_param}\/dataset_topics\/#{@dataset_topic_1.id}\"/, @result
    end

    should "not raise exception if no data" do
      assert_nothing_raised(Exception){statistics_in_words(nil)}
      assert_nothing_raised(Exception){statistics_in_words({})}
    end
  end
end
