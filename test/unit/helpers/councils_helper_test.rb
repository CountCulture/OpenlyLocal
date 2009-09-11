require 'test_helper'

class CouncilsHelperTest < ActionView::TestCase
  context "party_breakdown_graph helper method" do
    setup do
      @breakdown = [["Labour", 6], ["Conservative", 3],["Independent", 1]]
    end

    should "should get graph for party breakdown array" do
      Gchart.expects(:pie).with(has_entries(:data => [6,3,1], :legend => ["Labour", "Conservative", "Independent"])).returns("http://foo.com//graph")
      party_breakdown_graph(@breakdown)
    end
    
    should "return image tag using graph url as as src" do
      Gchart.stubs(:pie).returns("http://foo.com//graph")
      assert_dom_equal image_tag("http://foo.com//graph", :class => "chart", :alt => "Party Breakdown Chart"), party_breakdown_graph(@breakdown)
    end
  end
  
end
