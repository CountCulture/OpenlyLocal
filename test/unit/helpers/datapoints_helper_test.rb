require 'test_helper'

class DatapointsHelperTest < ActionView::TestCase
  context "the formatted_datapoint_value helper method" do
    should "return nil if value blank" do
      assert_nil formatted_datapoint_value(stub_everything)
      assert_nil formatted_datapoint_value(stub_everything(:value => ""))
    end

    should "format value depending on muid by default" do
      assert_equal '345', formatted_datapoint_value(stub_everything(:value => 345)).to_s #we only care about how it looks as a string
      assert_equal '£345', formatted_datapoint_value(stub_everything(:value => 345, :muid_format => "£%d"))
      assert_equal '24.6%', formatted_datapoint_value(stub_everything(:value => 24.62, :muid_format => "%.1f%"))
      assert_equal '34,567', formatted_datapoint_value(stub_everything(:value => 34567))
    end
    
    should "format with pound sign and delimiter if muid_type is Pounds Sterling" do
      assert_equal '£345', formatted_datapoint_value(stub_everything(:value => 345, :muid_type => "Pounds Sterling")).to_s #we only care about how it looks as a string
      assert_equal '£345', formatted_datapoint_value(stub_everything(:value => 345.0, :muid_type => "Pounds Sterling")).to_s #we only care about how it looks as a string
      assert_equal '£345', formatted_datapoint_value(stub_everything(:value => 345, :muid_format => "%.1f%", :muid_type => "Pounds Sterling")).to_s
      assert_equal '£0', formatted_datapoint_value(stub_everything(:value => 0, :muid_format => "%.1f%", :muid_type => "Pounds Sterling")).to_s
      assert_equal '£345,123,456', formatted_datapoint_value(stub_everything(:value => 345123456, :muid_type => "Pounds Sterling")).to_s
      assert_equal '£345,123,456', formatted_datapoint_value(stub_everything(:value => 345123456.0, :muid_type => "Pounds Sterling")).to_s
      assert_nil formatted_datapoint_value(stub_everything(:value => "", :muid_type => "Pounds Sterling"))
    end
  end
end
