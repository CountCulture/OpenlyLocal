require 'test_helper'

class MeetingTest < ActiveSupport::TestCase
  context "The Meeting Class" do
    setup do
      @committee = Committee.create!(:title => "Audit Group", :url => "some.url", :uid => 33, :council_id => 1)
      @meeting = Meeting.create!(:date_held => "6 November 2008 7:30pm", :committee => @committee, :uid => 22, :council_id => @committee.council_id)
    end

    should_belong_to :committee
    should_belong_to :council # think about meeting should belong to council through committee
    should_validate_presence_of :date_held
    should_validate_presence_of :committee_id
    should_validate_presence_of :uid
    should_validate_uniqueness_of :uid, :scoped_to => :council_id
    should_have_one :minutes # no shoulda macro for polymorphic stuff so tested below
    should_have_db_columns :venue

    should "include ScraperModel mixin" do
      assert Meeting.respond_to?(:find_existing)
    end
    
    should "have forthcoming named scope" do
      expected_options = {:conditions => ["date_held >= ?", Time.now], :order => "date_held" }
      assert_equal expected_options[:order], Meeting.forthcoming.proxy_options[:order]
      assert_equal expected_options[:conditions].first, Meeting.forthcoming.proxy_options[:conditions].first
      assert_in_delta expected_options[:conditions].last, Meeting.forthcoming.proxy_options[:conditions].last, 2
    end

  end
  

  context "A Meeting instance" do
    setup do
      @committee = Committee.create!(:title => "Audit Group", :url => "some.url", :uid => 33, :council => Factory(:council))
      @meeting = Meeting.create!(:date_held => "6 November 2008 7:30pm", :committee => @committee, :uid => 22, :council_id => @committee.council_id, :url => "http//council.gov.uk/meeting/22")
    end

    should "convert date string to date" do
      assert_equal DateTime.new(2008, 11, 6, 19, 30), @meeting.date_held
    end
    
    should "return committee name and date as title" do
      assert_equal "Audit Group meeting, November 6 2008, 7.30PM", @meeting.title
    end
    
    should "have polymorphic document as minutes" do
      doc = Factory(:document, :title => "minutes of some meeting")
      @meeting.minutes = doc
      assert_equal @meeting.id, doc.document_owner_id
      assert_equal "Meeting", doc.document_owner_type
    end
    
    should "alias attributes for Ical::Utilities" do
      assert_equal @meeting.title, @meeting.summary
      assert_equal @meeting.date_held, @meeting.dtstart
      assert_equal @meeting.venue, @meeting.location
      assert_equal @meeting.created_at, @meeting.created
      assert_equal @meeting.updated_at, @meeting.last_modified
    end
    
    should "alias committee details as organizer" do
      expected_result = {:cn => "Audit Group", :uri => "some.url"}
      assert_equal expected_result, @meeting.organizer
    end
    
    should "constuct event_uid from meeting id and created_at" do
      assert_equal "#{@meeting.created_at}-meeting-#{@meeting.id}@twfylocal", @meeting.event_uid
    end
    
    context "when calling minutes_body setter" do
      setup do
        @meeting.minutes_body = "some document text"
      end
      should "create new minutes document" do
        assert_kind_of Document, @meeting.minutes
      end
      
      should "save new minutes document" do
        assert !@meeting.minutes.new_record?
      end
      
      should "store passed value in document raw_body" do
        assert_equal "some document text", @meeting.minutes.raw_body
      end
      
      should "save meeting url as document url" do
        assert_equal "http//council.gov.uk/meeting/22", @meeting.minutes.url
      end
      
      should "set document type to be 'Minutes'" do
        assert_equal "Minutes", @meeting.minutes.document_type
      end
    end
    
    context "when calling minutes_body setter and meeting has existing minutes" do
      setup do
        @existing_minutes = Factory(:document)
        @meeting.minutes = @existing_minutes
        @existing_minutes.save!
        @meeting.minutes_body = "some document text"
      end

      should "not replace minutes" do
        assert_equal @existing_minutes.id, @meeting.minutes.id
      end
      
      should "update existing minutes raw_body" do
        assert_equal "some document text", @existing_minutes.reload.raw_body
      end
      
      should "set document_type to be 'Minutes'" do
        assert_equal "Minutes", @meeting.minutes.document_type
      end
    end
        
  end

  private
  def new_meeting(options={})
    Meeting.new({:date_held => 5.days.ago}.merge(options))
  end
end
