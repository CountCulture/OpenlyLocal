require File.expand_path('../../../test_helper', __FILE__)

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
      Gchart.expects(:pie).with(has_entry( :bar_colors => [Party.new("Labour").colour, Party.new("Conservative").colour, "66442233", "66442244"])).returns("http://foo.com//graph")
      party_breakdown_graph(@breakdown)
    end
    
    should "return image tag using graph url as as src" do
      Gchart.stubs(:pie).returns("http://foo.com//graph")
      assert_dom_equal image_tag("http://foo.com//graph", :class => "chart", :alt => "Party Breakdown Chart"), party_breakdown_graph(@breakdown)
    end
  end
  
  context "open_data_link_for helper method" do
    setup do
      @council = Factory(:council)
    end
    
    should 'return nil if no open_data_url' do
      assert_nil open_data_link_for(@council)
    end

    should "link to open_data_url with open_data status if open_data_url" do
      @council.open_data_url = 'http://foo.gov.uk/open'
      @council.stubs(:open_data_status).returns('foo_open')
      @council.stubs(:open_data_licence_name).returns('Creative Commons Attribution-Noncommercial 3.0')
      expected_link = link_to("Open Data page", 'http://foo.gov.uk/open', :class => "foo_open open_data_link", :title => 'Creative Commons Attribution-Noncommercial 3.0')
      assert_dom_equal expected_link, open_data_link_for(@council)
    end
    
    should "link to open_data_url with semi-open status if open_data_url but no licence" do
      @council.open_data_url = 'http://foo.gov.uk/open'
      expected_link = link_to("Open Data page", 'http://foo.gov.uk/open', :class => "semi_open_data open_data_link", :title => 'Not explicitly licensed')
      assert_dom_equal expected_link, open_data_link_for(@council)
    end
    
  end
  
end
