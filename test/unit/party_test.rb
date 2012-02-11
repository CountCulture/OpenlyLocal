require 'test_helper'

class PartyTest < ActiveSupport::TestCase
  DUMMY_RAW_DATA = [
    [ ["Conservative", "Con", "Cons" ], "#0281AA" ],
    [ ["Labour", "Lab"], "#AA0000", "Labour_Party_(UK)" ],
    [ ["Liberal Democrat","LDem", "LibDem" ], nil, "Liberal_Democrats" ],
    [ [ "Scottish National", "SNP" ] ],
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
        
    should "have name, colour, dbpedia_link accessors" do
      assert Party.new("foo").respond_to?(:name)
      assert Party.new("foo").respond_to?(:colour)
      assert Party.new("foo").respond_to?(:dbpedia_uri)
    end
    
    should "be equal to another party instance with the same name" do
      assert Party.new("foo") == Party.new("foo")
    end
    
    should "be equal to itself" do
      p = Party.new("foo")
      assert p == p
    end
    
    context "when initializing from given string" do

      should "discard 'Party' from given party name" do
        assert_equal "Conservative", Party.new("Conservative Party").name
        assert_equal "Conservative", Party.new("Conservative party").name
      end

      should "strip extraneous spaces from given party name" do
        assert_equal "Conservative", Party.new("  Conservative ").name
      end

      should "strip extraneous spaces and 'Party' from given party name" do
        assert_equal "Liberal Democrat", Party.new("  Liberal Democrat Party ").name
      end
      
      should "strip UTF spaces from given party name" do
        assert_equal "Labour", Party.new("Labour\302\240").name
      end
      
      should "strip leading 'the' from given party name" do
        assert_equal "Conservative", Party.new("the Conservative Party").name
        assert_equal "Conservative", Party.new("The Conservative party").name
      end

      context "and string is party name" do
        should "use string as name" do
          assert_equal "Labour", Party.new("Labour").name
        end
        
        should "assign appropriate colour to colour" do
          assert_equal "#AA0000", Party.new("Labour").colour
        end
        
        should "assign appropriate uri to dbpedia_uri" do
          assert_equal "http://dbpedia.org/resource/Labour_Party_(UK)", Party.new("Lab").dbpedia_uri
        end
      end
      
      context "and string is alias of party" do
        should "assign appropriate party name as name" do
          assert_equal "Labour", Party.new("Lab").name
        end
        
        should "assign appropriate colour to colour" do
          assert_equal "#AA0000", Party.new("Lab").colour
        end
        
        should "assign appropriate uri to dbpedia_uri" do
          assert_equal "http://dbpedia.org/resource/Labour_Party_(UK)", Party.new("Lab").dbpedia_uri
        end
      end
      
      context "and string is not a party name" do
        should "assign given string to name" do
          assert_equal "Foo", Party.new("Foo").name
        end
        
        should "return nil as colour" do
          assert_nil Party.new("Foo").colour
        end
        
        should "return nil as dbpedia_uri" do
          assert_nil Party.new("Foo").dbpedia_uri
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
    
    context "when returning colour" do
      should "return nil if no colour" do
        assert_nil Party.new("Scottish National").colour
      end
      
      should "return nil if colour nil" do
        assert_nil Party.new("Liberal Democrat").colour
      end
      
      should "return colour if colour set" do
        assert_equal "#0281AA", Party.new("Conservative").colour
      end
    end
    
    context "when returning empty?" do
      should "return true if no party" do
        assert Party.new("").empty?
        assert Party.new(nil).empty?
      end
      
      should "return false if party" do
        assert !Party.new("foo").empty?
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