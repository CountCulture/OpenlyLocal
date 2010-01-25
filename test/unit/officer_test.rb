require 'test_helper'

class OfficerTest < ActiveSupport::TestCase
  subject { @officer }
  
  context "The Officer class" do
    setup do
      @officer = Factory(:officer)
      @council = @officer.council
    end
    
    should_belong_to :council 
    should_validate_presence_of :last_name
    should_validate_presence_of :position
    should_validate_presence_of :council_id

    should "validate uniqueness of chief executive for council" do
      ceo = Factory(:officer, :council => @council, :position => "Chief Executive")
      another_ceo = Factory.build(:officer, :council => @council, :position => "Chief Executive")
      assert !another_ceo.valid?
      assert_equal "A Chief Executive already exists for this council", another_ceo.errors[:base]
    end
    
    should "not validate uniqueness of non chief executive for council" do
      non_ceo = Factory.build(:officer, :council => @council, :position => @officer.position)
      assert non_ceo.valid?
    end
    
    should "allow chief exec to be changed" do
      # this is regression test
      ce = Factory(:officer, :council => Factory(:another_council), :position => "Chief Executive")
      ce.full_name = "Fred Flintstone"
      assert ce.save
    end
  end
  
  context "An Officer instance" do
    
    context "when setting and getting full_name" do
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
end
