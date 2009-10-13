require 'test_helper'

class CommitteeTest < ActiveSupport::TestCase
  subject { @committee }
  
  context "The Committee Class" do
    setup do
      @committee = Factory(:committee)
    end

    should_validate_presence_of :title, :url, :uid, :council_id
    should_validate_uniqueness_of :title, :scoped_to => :council_id
    should_have_many :meetings
    should_have_many :meeting_documents, :through => :meetings
    should_have_one  :next_meeting
    should_have_many :memberships
    should_have_many :members, :through => :memberships
    should_belong_to :council
    should_belong_to :ward
    should_have_named_scope :active
    
    should "include ScraperModel mixin" do
      assert Committee.respond_to?(:find_existing)
    end
    
    should "mixin PartyBreakdownSummary module" do
      assert Committee.new.respond_to?(:party_breakdown)
    end

    context "when finding committees that are active" do
      setup do
        @inactive_committee = Factory(:committee, :council => @committee.council)
        @very_old_meeting = new_meeting_for(@inactive_committee, :date_held => 13.months.ago)
        @less_old_meeting = new_meeting_for(@committee, :date_held => 10.months.ago)
      end
      
      should "return only committees with meetings in past 12 months" do
        assert_equal [@committee], Committee.active.all
      end
    end
    context "when finding committees with activity status" do
      setup do
        @inactive_committee = Factory(:committee, :council => @committee.council)
        @very_old_meeting = new_meeting_for(@inactive_committee, :date_held => 13.months.ago)
        @less_old_meeting = new_meeting_for(@committee, :date_held => 10.months.ago)
      end
      
      should "return activity status for committees" do
        assert_equal [@committee, @inactive_committee], comms = Committee.with_activity_status.all
        assert comms.first.active?
        assert !comms.last.active?
      end
    end
    
    context "when finding next_meeting" do
      setup do
        @past_meeting = new_meeting_for(@committee, :date_held => 7.days.ago)
      end
      
      should "return first meeting in the future" do
        future_meeting = new_meeting_for(@committee, :date_held=> 2.months.from_now)
        near_future_meeting = new_meeting_for(@committee, :date_held => 3.days.from_now)
        assert_equal near_future_meeting, @committee.next_meeting
      end
      
      should "return nil if no meetings in the future" do
        assert_nil @committee.next_meeting
      end
    end
  end
    
  context "A Committee instance" do
    setup do
      @council, @another_council = Factory(:council), Factory(:another_council)
      @committee = Factory(:committee, :council => @council)
      @another_committee = Factory(:committee, :council => @council)
    end
    
    context "when saving" do
      should "normalise title" do
        @committee.expects(:normalise_title)
        @committee.save!
      end

      should "save normalised title" do
        @committee.title = "foo committee"
        @committee.save!
        assert_equal "foo", @committee.reload.normalised_title
      end
      
      should "return activity status as status" do
        assert_nil @committee.status #doesn't have active? method by default
        @committee.stubs(:active?).returns(true)
        assert_equal "active", @committee.status
        @committee.stubs(:active?).returns(false)
        assert_equal "inactive", @committee.status
      end
    end
    
    context "with members" do
      # this part is really just testing inclusion of uid_association extension in members association
      setup do
        @member = Factory(:member, :council => @council)
        @old_member = Factory(:old_member, :council => @council)
        @another_council_member = Factory(:member, :council => @another_council, :uid => 999)
        @committee.members << @old_member
      end

      should "return member uids" do
        assert_equal [@old_member.uid], @committee.member_uids
      end
      
      should "replace existing members with ones with given uids" do
        @committee.member_uids = [@member.uid]
        assert_equal [@member], @committee.members
      end
      
      should "not add members that don't exist for council" do
        @committee.member_uids = [@another_council_member.uid]
        assert_equal [], @committee.members
      end
      
    end
    
    context "when getting meeting_documents" do
      setup do
        @past_meeting = Factory(:meeting, :council => @council, :committee => @committee)
        @forthcoming_meeting = Factory(:meeting, :council => @council, :committee => @committee, :date_held => 2.weeks.from_now)
        @another_committee_meeting = Factory(:meeting, :council => @council, :committee => @another_committee)
        
        @past_meeting_document = Factory(:document, :document_owner => @past_meeting)
        @forthcoming_meeting_document = Factory(:document, :document_owner => @forthcoming_meeting)
        @another_committee_meeting_document = Factory(:document, :document_owner => @another_committee_meeting)
      end
      
      should "return documents" do
        assert_equal 2, @committee.meeting_documents.size
        assert @committee.meeting_documents.include?(@forthcoming_meeting_document)
        assert @committee.meeting_documents.include?(@past_meeting_document)
      end
      
      should "return documents in order of descending date_held of meetings" do
        assert_equal @forthcoming_meeting_document, @committee.meeting_documents.first
      end
      
      should "not return document body or raw_body" do
        assert !@committee.meeting_documents.first.attributes.include?("body")
        assert !@committee.meeting_documents.first.attributes.include?("raw_body")
      end
    end
  end
  
  private
  def new_committee(options={})
    Committee.new({:title => "Some Title"}.merge(options))
  end

  def new_meeting_for(committee, options={})
    Factory(:meeting, {:committee => committee, :council => committee.council}.merge(options))
  end
end
