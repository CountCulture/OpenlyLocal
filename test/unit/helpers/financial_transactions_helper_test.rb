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
  
  private
  def fuzzy_date(fuzziness_in_days=nil)
    stub_everything(:date => @date, :date_fuzziness => fuzziness_in_days)
  end
end
