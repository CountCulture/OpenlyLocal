require File.expand_path('../../test_helper', __FILE__)

class MembershipTest < ActiveSupport::TestCase

  context "The Membership Class" do
    setup do
      # @membership = Membership.create!(:title => "Some Committee", :url => "some.url", :uid => 44, :council_id => 1)
    end

    should_validate_presence_of :member_id, :committee_id
    should belong_to :committee
    # should belong_to :council
    should belong_to :member
    # should belong_to :uid_member
    
  end
end
