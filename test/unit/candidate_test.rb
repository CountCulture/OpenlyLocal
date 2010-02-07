require 'test_helper'

class CandidateTest < ActiveSupport::TestCase
  subject { @candidate }

  context "The Candidate class" do
    setup do
      @election = Factory(:election)
      @candidate = Factory(:candidate, :election => @election)
    end

    should_belong_to :election
    should_have_db_columns :first_name, :last_name, :party, :elected, :votes, :address
    should_validate_presence_of :election_id
    should_validate_presence_of :last_name
    
    should "delegate ward to election" do
      assert_equal @election.ward, @candidate.ward
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
