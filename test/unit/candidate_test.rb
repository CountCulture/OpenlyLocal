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
    should_belong_to :member
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
    
    context "when returning party_name" do
      
      should "return nil by default" do
        assert_nil @candidate.party_name
      end
      
      should "return name of political party if set" do
        political_party = Factory(:political_party)
        @candidate.political_party = political_party
        assert_equal political_party.name, @candidate.party_name
      end
      
      should "return party if political party if not set" do
        @candidate.party = "foo"
        assert_equal "foo", @candidate.party_name
      end
      
      should "return name of political party if political_party and party set" do
        political_party = Factory(:political_party)
        @candidate.political_party = political_party
        @candidate.party = "foo"
        assert_equal political_party.name, @candidate.party_name
      end
      
    end
    
    context "when returning full_name" do
      should "concatenate first and last names" do
        assert_equal 'Fred M Flintstone', Candidate.new(:first_name => 'Fred M', :last_name => 'Flintstone').full_name
      end
      
      should "concatenate return last name if no first_name" do
        assert_equal 'Flintstone', Candidate.new(:last_name => 'Flintstone').full_name
      end
    end
    
    context "when returning status" do
      should "return nil by default" do
        assert_nil @candidate.status
      end
      
      should "return 'elected' if elected" do
        @candidate.elected = true
        assert 'elected', @candidate.status
      end
    end
  end
end
