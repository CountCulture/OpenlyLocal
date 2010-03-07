require 'test_helper'

class PollTest < ActiveSupport::TestCase
  subject { @poll }
  
  context "The Poll class" do
    setup do
      @council = Factory(:council)
      @poll = Factory(:poll, :area => @council)
      
    end
    
    should_validate_presence_of :date_held
    should_validate_presence_of :area_id, :area_type
    should_have_db_columns :electorate, :position, :ballots_issued, :ballots_rejected, :postal_votes
    should_have_many :candidates
    
    should "have associated polymorphic area" do
      assert_equal @council.id, @poll.area_id
      assert_equal "Council", @poll.area_type
    end  
  end
  
  context "A Poll instance" do
    setup do
      @poll = Factory(:poll)
    end
    
    should "alias name as title" do
      # assert_equal @poll.name, @poll.title
    end

  end
end
