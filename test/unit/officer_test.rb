require 'test_helper'

class OfficerTest < ActiveSupport::TestCase
  subject { @officer }
  
  context "The Officer class" do
    setup do
      @officer = Factory(:officer)
    end
    
    should_belong_to :council 
    should_validate_presence_of :last_name
    should_validate_presence_of :position
    should_validate_presence_of :council_id
  end
  
  context "An Officer instance" do
    setup do
      NameParser.stubs(:parse).returns(:first_name => "Fred", :last_name => "Scuttle", :name_title => "Prof", :qualifications => "PhD")
      @officer = Officer.new(:full_name => "Fred Scuttle")
    end
    
    should "return full name" do
      assert_equal "Fred Scuttle", @officer.full_name
    end
    
    should "should extract first name from full name" do
      assert_equal "Fred", @officer.first_name
    end
    
    should "extract last name from full name" do
      assert_equal "Scuttle", @officer.last_name
    end
    
    should "extract name_title from full name" do
      assert_equal "Prof", @officer.name_title
    end
    
    should "extract qualifications from full name" do
      assert_equal "PhD", @officer.qualifications
    end
    
  end
  
end
