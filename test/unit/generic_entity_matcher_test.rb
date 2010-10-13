require 'test_helper'

class GenericEntityMatcherTest < Test::Unit::TestCase
  
  context "The GenericEntityMatcher module" do
    
    context "when returning possible matches" do

      should "return nil if nil given" do
        assert_nil GenericEntityMatcher.possible_matches()
      end

      should "match against possible_matches for given class" do
        Council.expects(:possible_matches).with(:title => 'foo')
        assert_nil GenericEntityMatcher.possible_matches(:title => 'foo', :entity_type => 'Council')
      end

      # should "return empty string if empty string given" do
      #   assert_equal "", TitleNormaliser.normalise_title("")
      # end

    end

  end
  
end
