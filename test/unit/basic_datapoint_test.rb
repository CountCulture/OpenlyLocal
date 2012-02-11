require 'test_helper'

class BasicDatapointTest < ActiveSupport::TestCase
  context "a BasicDatapoint instance" do
    setup do
      @bd = BasicDatapoint.new(:name => "foo", :data => 123, :source => "ABC", :source_url => "foo.com/abc", :licence => "Anyhoo")
    end
    

    should "have name accessor" do
      assert_equal "foo", @bd.name
    end
    should "have data accessor" do
      assert_equal 123, @bd.data
    end
    should "have source accessor" do
      assert_equal "ABC", @bd.source
    end
    should "have source_url accessor" do
      assert_equal "foo.com/abc", @bd.source_url
    end
    should "have licence accessor" do
      assert_equal "Anyhoo", @bd.licence
    end
    
    context "when converting to xml" do
      
      should "not include declaration" do 
        assert_no_match /xml version/, @bd.to_xml
      end
      
      should "use name as root element" do 
        assert_match /^<foo/, @bd.to_xml
      end
      
      should "not have name attribute as child element" do 
        assert_no_match /<name/, @bd.to_xml
      end
      
      should "use other attribute as child elements" do 
        %w(data licence source source-url).each do |a|
          assert_match /^<foo.+<#{a}/m, @bd.to_xml
        end
      end
    end
  end
end