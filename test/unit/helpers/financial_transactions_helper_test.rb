require 'test_helper'

class FinancialTransactionsHelperTest < ActionView::TestCase
  context "date_with_fuzziness_for helper method" do
    setup do
      @date = 3.months.ago.to_date
    end

    should "return formatted_date by default" do
      assert_equal @date.to_s(:custom_short), date_with_fuzziness_for(fuzzy_date)
    end
    
    should "return fuzzy formatted_date prefix dependent on fuzziness" do
      assert_equal "about #{@date.to_s(:custom_short)}", date_with_fuzziness_for(fuzzy_date(2))
      assert_equal @date.strftime("%b %Y"), date_with_fuzziness_for(fuzzy_date(15))
      assert_equal "2nd quarter 2008", date_with_fuzziness_for(stub_everything(:date => "2008-04-26".to_date, :date_fuzziness => 45))
    end
    
    should "return range of months if 30 days of fuzziness" do
      assert_equal "Mar-Apr 2008", date_with_fuzziness_for(stub_everything(:date => "2008-04-1".to_date, :date_fuzziness => 30))
    end
  end
  
  context "spend_by_month_graph helper_method" do
    setup do
      @spend_by_month_data = [['01-02-2009'.to_date, 123.4],['01-03-2009'.to_date, nil],['01-04-2009'.to_date, 42.3]]
    end

    should "should get bar chart for party breakdown array" do
      Gchart.expects(:bar).returns("http://foo.com//graph")
      spend_by_month_graph(@spend_by_month_data)
    end
    
    should "should use numbers from party breakdown" do
      Gchart.expects(:bar).with(has_entry( :data => [123.4,0,42.3])).returns("http://foo.com//graph")
      spend_by_month_graph(@spend_by_month_data)
    end
    
    should "should use Months and Years for legends" do
      Gchart.expects(:bar).with(has_entry( :legend => ["Feb 09", "Mar 09", "Apr 09"])).returns("http://foo.com//graph")
      spend_by_month_graph(@spend_by_month_data)
    end
    
    # should "should use party colours in legend replacing nil colours with spare colours" do
    #   Gchart.expects(:pie).with(has_entry( :bar_colors => [Party.new("Labour").colour, Party.new("Conservative").colour, "66442233", "66442244"])).returns("http://foo.com//graph")
    #   party_breakdown_graph(@breakdown)
    # end
    
    should "return image tag using graph url as as src" do
      Gchart.stubs(:bar).returns("http://foo.com//graph")
      assert_dom_equal image_tag("http://foo.com//graph", :class => "chart", :alt => "Spend By Month Chart"), spend_by_month_graph(@spend_by_month_data)
    end
  end
  
  private
  def fuzzy_date(fuzziness_in_days=nil)
    stub_everything(:date => @date, :date_fuzziness => fuzziness_in_days)
  end
end
