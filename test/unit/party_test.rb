require 'test_helper'

class PartyTest < Test::Unit::TestCase
  DUMMY_RAW_DATA = [
    [ ["Conservative", "Con", "Cons" ], "#0281AA" ],
    [ ["Labour", "Lab"], "#AA0000" ],
    [ ["Liberal Democrat","LDem", "LibDem" ], "#F3A63C" ],
    [ ["Green"], "#73A533" ]
    ] 
  
  
  context "the Party class" do
    should "make Parties constant available as raw_data" do
      assert_equal PARTIES, Party.raw_data
    end
    
    should "initialize new instance from given string" do
      assert_kind_of Party, party = Party.new("Green")
    end
    
  end
  
  context "a Party instance" do
    setup do
      Party.stubs(:raw_data).returns(DUMMY_RAW_DATA)
    end
        
    should "have name and colour accessors" do
      assert Party.new("foo").respond_to?(:name)
      assert Party.new("foo").respond_to?(:colour)
      # assert @party.respond_to?(:dbpedia_link)
    end
    
    context "when initializing from given string" do

      context "and string is party name" do
        should "use string as name" do
          assert_equal "Labour", Party.new("Labour").name
        end
        
        should "assign appropriate colour to colour" do
          assert_equal "#AA0000", Party.new("Labour").colour
        end
      end
      
      context "and string is alias of party" do
        should "assign appropriate party name as name" do
          assert_equal "Labour", Party.new("Lab").name
        end
        
        should "assign appropriate colour to colour" do
          assert_equal "#AA0000", Party.new("Lab").colour
        end
      end
      
      context "and string is not a party name" do
        should "assign given string to name" do
          assert_equal "Foo", Party.new("Foo").name
        end
        
        should "return nil as colour" do
          assert_nil Party.new("Foo").colour
        end
      end
      
      context "and string is nil" do
        should "return nil for name" do
          assert_nil Party.new(nil).name
        end
      end
      
      context "and string is empty" do
        should "return nil for name" do
          assert_nil Party.new("").name
        end
      end
    end
    
    should "output party name when to_s called" do
      assert_equal "Labour", Party.new("Lab").to_s
    end
    
    should "output empty string when to_s called and no name" do
      assert_equal "", Party.new(nil).to_s
    end
  end
end