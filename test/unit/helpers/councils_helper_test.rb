require 'test_helper'

class CouncilsHelperTest < ActionView::TestCase
  context "party_breakdown_graph helper method" do
    setup do
      @breakdown = [[Party.new("Labour"), 6], [Party.new("Conservative"), 3],[Party.new("Independent"), 1],[Party.new("Not Known"), 1]]
    end

    should "should get pie chart for party breakdown array" do
      Gchart.expects(:pie).returns("http://foo.com//graph")
      party_breakdown_graph(@breakdown)
    end
    
    should "should use numbers from party breakdown" do
      Gchart.expects(:pie).with(has_entry( :data => [6,3,1,1])).returns("http://foo.com//graph")
      party_breakdown_graph(@breakdown)
    end
    
    should "should use party names in legend" do
      Gchart.expects(:pie).with(has_entry( :legend => ["Labour", "Conservative", "Independent", "Not Known"])).returns("http://foo.com//graph")
      party_breakdown_graph(@breakdown)
    end
    
    should "should use party colours in legend replacing nil colours with spare colours" do
      Gchart.expects(:pie).with(has_entry( :bar_colors => [Party.new("Labour").colour, Party.new("Conservative").colour, "664422CC", "664422AA"])).returns("http://foo.com//graph")
      party_breakdown_graph(@breakdown)
    end
    
    should "return image tag using graph url as as src" do
      Gchart.stubs(:pie).returns("http://foo.com//graph")
      assert_dom_equal image_tag("http://foo.com//graph", :class => "chart", :alt => "Party Breakdown Chart"), party_breakdown_graph(@breakdown)
    end
  end
  
end
