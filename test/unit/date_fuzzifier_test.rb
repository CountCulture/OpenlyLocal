require 'test_helper'

class DateFuzzifierTest < Test::Unit::TestCase
  
  context "The DateFuzzifier module" do
    context "when returning date_with_fuzziness" do
      setup do
        @date = 3.months.ago.to_date
      end

      should "return formatted_date by default" do
        assert_equal @date.to_s(:custom_short), DateFuzzifier.date_with_fuzziness(@date)
      end
  
      should "return fuzzy formatted_date prefix dependent on fuzziness" do
        assert_equal "about #{@date.to_s(:custom_short)}", DateFuzzifier.date_with_fuzziness(@date, 2)
        assert_equal @date.strftime("%b %Y"), DateFuzzifier.date_with_fuzziness(@date, 15)
        assert_equal "2nd quarter 2008", DateFuzzifier.date_with_fuzziness("2008-04-26".to_date, 45)
      end
  
      should "return range of months if 30 days of fuzziness" do
        assert_equal "Mar-Apr 2008", DateFuzzifier.date_with_fuzziness("2008-04-1".to_date, 30)
      end
    end
  end
end