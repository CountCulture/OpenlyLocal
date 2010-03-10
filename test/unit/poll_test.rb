require 'test_helper'

class PollTest < ActiveSupport::TestCase
  subject { @poll }
  def setup
    @council = Factory(:council)
    @poll = Factory(:poll, :area => @council)
  end
  
  context "The Poll class" do
    
    should_validate_presence_of :date_held
    should_validate_presence_of :area_id, :area_type
    should_validate_presence_of :position
    should_have_db_columns :electorate, :ballots_issued, :ballots_rejected, :postal_votes
    should_have_many :candidacies
    
    should "have associated polymorphic area" do
      assert_equal @council.id, @poll.area_id
      assert_equal "Council", @poll.area_type
    end  
  end
  
  context "A Poll instance" do
    
    should "date_held as string as title" do
      assert_equal @poll.date_held.to_s(:event_date), @poll.title
    end
    
    context "when calculating turnout" do
      setup do
        @t_poll= Factory(:poll, :area => @council, :electorate => 200, :ballots_issued => 90)
      end
      
      should "return nil if electorate is nil" do
        @t_poll.electorate = nil
        assert_nil @t_poll.turnout
      end

      should "return nil if ballots issued is nil" do
        @t_poll.ballots_issued = nil
        assert_nil @t_poll.turnout
      end
      
      should "return valid ballots divided by electorate as turnout" do
        expected_result = @t_poll.ballots_issued.to_f/@t_poll.electorate.to_f
        assert_in_delta expected_result, @t_poll.turnout, 0.00000001
      end
    end

  end
end
