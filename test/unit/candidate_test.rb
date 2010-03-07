require 'test_helper'

class CandidateTest < ActiveSupport::TestCase
  subject { @candidate }

  context "The Candidate class" do
    setup do
      @poll = Factory(:poll)
      @candidate = Factory(:candidate, :poll => @poll)
    end

    should_belong_to :poll
    should_belong_to :political_party
    should_have_db_columns :first_name, :last_name, :party, :elected, :votes, :address
    should_validate_presence_of :poll_id
    should_validate_presence_of :last_name
    
    should "delegate area to poll" do
      assert_equal @poll.area, @candidate.area
    end

  end

  context "A Candidate instance" do
    setup do
      @candidate = Factory(:candidate)
    end
    
    should "not be elected by default" do
      assert !@candidate.elected?
    end
  end
end
