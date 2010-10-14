require 'test_helper'

class GenericEntityMatcherTest < Test::Unit::TestCase
  
  context "The GenericEntityMatcher module" do
    
    context "when returning possible matches" do

      should "return nil if nil given" do
        assert_nil GenericEntityMatcher.possible_matches
      end

      # should "match against possible_matches for given class" do
      #   Council.expects(:possible_matches).with(:title => 'foo thing')
      #   GenericEntityMatcher.possible_matches(:title => 'foo thing', :entity_type => 'Council')
      # end

      should "return all starting with first word of title if class doesn't implement possible matches" do
        TestScrapedModel.expects(:all).with(:conditions => ['title LIKE ?',"foo%"])
        GenericEntityMatcher.possible_matches(:title => 'foo thing', :entity_type => 'TestScrapedModel')
      end

      should "return all starting with first word of name if class doesn't implement possible matches and has name rather than title attribute" do
        TestModelWithSpendingStat.expects(:all).with(:conditions => ['name LIKE ?',"foo%"])
        GenericEntityMatcher.possible_matches(:title => 'foo thing', :entity_type => 'TestModelWithSpendingStat')
      end

      # should "return empty string if empty string given" do
      #   assert_equal "", TitleNormaliser.normalise_title("")
      # end

    end

  end
  
end
