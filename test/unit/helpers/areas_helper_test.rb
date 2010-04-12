require 'test_helper'

class AreasHelperTest < ActionView::TestCase
  context "crime_stats_graph helper method" do
    setup do
      @comparison_data = [{"date"=>"2008-12", "value"=>"42.2"}, {"date"=>"2009-01", "value"=>"51", 'force_value' => '2.5'}, {"date"=>"2009-02", "value"=>"3.14", 'force_value' => '3.7'}]
    end

    should "should return nil if no data" do
      assert_nil crime_stats_graph(nil)
      assert_nil crime_stats_graph([])
    end
    
    should "should get line graph for comparison data" do
      Gchart.expects(:line).returns("http://foo.com//graph")
      crime_stats_graph(@comparison_data)
    end
    
    should "should use numbers from party breakdown" do
      Gchart.expects(:line).with(has_entry( :data => [[42.2,51.0,3.14],[nil, 2.5, 3.7]] )).returns("http://foo.com//graph")
      crime_stats_graph(@comparison_data)
    end
    
    should "should provide info for legend" do
      Gchart.expects(:line).with(has_entry( :legend => ["This area", "Force Average"])).returns("http://foo.com//graph")
      crime_stats_graph(@comparison_data)
    end
    
    # should "should use party colours in legend replacing nil colours with spare colours" do
    #   Gchart.expects(:line).with(has_entry( :bar_colors => [Party.new("Labour").colour, Party.new("Conservative").colour, "66442233", "66442244"])).returns("http://foo.com//graph")
    #   crime_stats_graph(@comparison_data)
    # end
    
    should "return image tag using graph url as as src" do
      Gchart.stubs(:line).returns("http://foo.com//graph")
      assert_dom_equal image_tag("http://foo.com//graph", :class => "chart", :alt => "Crime Statistics Graph"), crime_stats_graph(@comparison_data)
    end
  end
  
end
