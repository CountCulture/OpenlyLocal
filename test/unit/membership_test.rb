require File.expand_path('../../test_helper', __FILE__)

class MembershipTest < ActiveSupport::TestCase

  context "The Membership Class" do
    setup do
      # @membership = Membership.create!(:title => "Some Committee", :url => "some.url", :uid => 44, :council_id => 1)
    end

    [:member_id, :committee_id].each do |attribute|
      should validate_presence_of attribute
    end
    should belong_to :committee
    # should belong_to :council
    should belong_to :member
    # should belong_to :uid_member
    
  end
end
