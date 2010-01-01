require 'test_helper'

class BareDatapointTest < Test::Unit::TestCase
  
  context "A BareDatapoint instance" do

    should "store given area as area" do
      dummy_area = stub
      assert_equal dummy_area, BareDatapoint.new(:area => dummy_area).area
    end
    
    should "store given value as value" do
      assert_equal 123, BareDatapoint.new(:value => 123).value
    end
    
    should "store given muid_type as muid_type" do
      assert_equal 4, BareDatapoint.new(:muid_type => 4).muid_type
    end
    should "store given muid_format as muid_format" do
      assert_equal "foo", BareDatapoint.new(:muid_format => "foo").muid_format
    end
  end
end