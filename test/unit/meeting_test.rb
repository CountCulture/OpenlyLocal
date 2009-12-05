require 'test_helper'

class MeetingTest < ActiveSupport::TestCase
  subject { @meeting }
  context "The Meeting Class" do
    setup do
      @committee = Factory(:committee)
      @meeting = Factory(:meeting, :committee => @committee, :council => @committee.council)
   end

    should_belong_to :committee
    should_belong_to :council # think about meeting should belong to council through committee
    should_validate_presence_of :date_held
    should_validate_presence_of :committee_id
    should_validate_presence_of :council_id
    should_have_one :minutes # no shoulda macro for polymorphic stuff so tested below
    should_have_one :agenda # no shoulda macro for polymorphic stuff so tested below
    should_have_db_columns :venue
    should_validate_uniqueness_of :date_held, :scoped_to => [:council_id, :committee_id]
    should "validate uniqueness of uid scoped to council_id" do
      #shoulda macros can't allow for nil values
      @meeting.update_attribute(:uid, 42)
      new_meet = Meeting.new(:council_id => @meeting.council_id)
      new_meet.valid? # uid is nil
      assert_nil new_meet.errors[:uid]
      new_meet.uid = 42 #uid is same as existing meeting
      new_meet.valid?
      assert_equal "has already been taken", new_meet.errors[:uid]
      new_meet.council_id = @meeting.council_id+10 #change council so different to existing meeting
      new_meet.valid?
      assert_nil new_meet.errors[:uid]
    end
    
    # should "validate presence either of uid or url" do
    #   assert new_meeting(:uid => 42).valid?
    #   assert new_meeting(:url => "foo.com").valid?
    #   nm = new_meeting
    #   assert !nm.valid?
    #   assert_equal "either uid or url must be present", nm.errors[:base]
    # end
    # 
    should "validate uniqueness of url if uid is blank?" do
     @meeting.update_attribute(:url, "foo.com")
      nm = new_meeting(:url => "foo.com", :council_id => @meeting.council_id)
      assert !nm.valid?
      assert_equal "must be unique", nm.errors[:url]
    end
    
    should "not validate uniqueness of url if uid is not blank?" do
      nm = new_meeting(:url => "foo.com", :uid => 43, :council_id => @meeting.council_id)
      assert nm.valid?
    end

    should "include ScraperModel mixin" do
      assert Meeting.respond_to?(:find_all_existing)
    end
    
    should "have forthcoming named scope" do
      expected_options = {:conditions => ["date_held >= ?", Time.now], :order => "date_held" }
      assert_equal expected_options[:order], Meeting.forthcoming.proxy_options[:order]
      assert_equal expected_options[:conditions].first, Meeting.forthcoming.proxy_options[:conditions].first
      assert_in_delta expected_options[:conditions].last, Meeting.forthcoming.proxy_options[:conditions].last, 2
    end
  
    context "should overwrite orphan_records_callback and" do
      setup do
        @future_meeting = Factory(:meeting, :committee => @committee, :council => @committee.council, :date_held => 5.days.from_now)
      end

      should "not delete orphan_record if not saving results" do      
        Meeting.send(:orphan_records_callback, [@meeting, @future_meeting])
        assert Meeting.find_by_id(@meeting.id)
        assert Meeting.find_by_id(@future_meeting.id)
      end

      should "not fail if the are no orphan records" do
        assert_nothing_raised(Exception) { Meeting.send(:orphan_records_callback, [], :save_results => true) }
      end   

      should "delete orphan meetings in the future" do
        Meeting.send(:orphan_records_callback, [@meeting, @future_meeting], :save_results => true)
        assert_nil Meeting.find_by_id(@future_meeting.id)
      end  

      should "not delete orphan meetings in the past" do
        Meeting.send(:orphan_records_callback, [@meeting, @future_meeting], :save_results => true)
        assert Meeting.find_by_id(@meeting.id)
      end       
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
    
    should "convert datetime string to datetime" do
      assert_equal DateTime.new(2009, 12, 30, 19, 30), Meeting.new(:date_held => "30-12-2009 7:30pm").date_held
      assert_equal DateTime.new(2009, 12, 30, 19, 30), Meeting.new(:date_held => "12/30/2009 7:30pm").date_held # regression test for Ruby 1.9. Should fail for that
    end
    
    should "return date for date_held if time is midnight" do
      assert_equal Date.new(2009, 12, 30), Factory(:meeting, :committee => @committee, :council_id => @committee.council_id, :date_held => "30-12-2009").reload.date_held
    end
    
    should "return date for date_held if time is midnight in BST" do
      assert_equal Date.new(2010, 05, 11), Factory(:meeting, :committee => @committee, :council_id => @committee.council_id, :date_held => "2010-05-11T00:00:00+01:00").reload.date_held
    end
    
    should "return nil date_held if no date" do
      assert_nil Meeting.new.date_held
    end
    
    should "return committee name in title" do
      assert_equal "Audit Group meeting", @meeting.title
    end
    
    should "return committee name and date in extended title" do
      assert_equal "Audit Group meeting, #{@meeting.date_held.to_s(:event_date)}", @meeting.extended_title
    end
    
    should "return formatted date as formatted date with extra spaces removed" do
      assert_equal "Nov 6 2008, 7.30PM", @meeting.formatted_date
    end
    
    should "have polymorphic Meeting type document as minutes" do
      another_doc = Factory(:document, :title => "some other document", :document_owner => @meeting)
      minutes = Factory(:document, :title => "minutes of some meeting", :document_type => "Minutes", :document_owner => @meeting)
      assert_equal minutes, @meeting.minutes
      assert_equal @meeting.id, minutes.document_owner_id
      assert_equal "Meeting", minutes.document_owner_type
    end
    
    should "have polymorphic Agenda type document as agenda" do
      another_doc = Factory(:document, :title => "some other document", :document_owner => @meeting)
      agenda = Factory(:document, :title => "agenda of some meeting", :document_type => "Agenda", :document_owner => @meeting)
      assert_equal agenda, @meeting.agenda
      assert_equal @meeting.id, agenda.document_owner_id
      assert_equal "Meeting", agenda.document_owner_type
    end
    
    should "have polymorphic documents as documents" do
      another_doc = Factory(:document, :title => "some other document", :document_owner => @meeting)
      minutes = Factory(:document, :title => "minutes of some meeting", :document_type => "Minutes", :document_owner => @meeting)
      assert_equal 2, @meeting.documents.size
      assert @meeting.documents.include?(minutes)
      assert @meeting.documents.include?(another_doc)
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
      assert_equal "#{@meeting.created_at.strftime("%Y%m%dT%H%M%S")}-meeting-#{@meeting.id}@twfylocal", @meeting.event_uid
    end
    
    should "return status of meeting" do
      assert_equal "past", new_meeting.status
      assert_equal "future", new_meeting(:date_held => 1.hour.from_now).status
    end
    
    should "return status of meeting with no time set" do
      assert_equal "past", new_meeting(:date_held => "3 November 2007").status
      assert_equal "future", new_meeting(:date_held => "3 November 2020").status
    end
    
    context "when converting meeting to_xml" do
      should "include openlylocal_url" do
        assert_match %r(<openlylocal-url), @meeting.to_xml
      end
      
      should "include formatted_date" do
        assert_match %r(<formatted-date), @meeting.to_xml
      end
      
      should "include title" do
        assert_match %r(<title), @meeting.to_xml
      end
    end
    
    context "when matching existing member against params should override default and" do
      should "should match uid if it exists" do
        meeting_with_uid = Factory(:meeting, :council => @meeting.council, :date_held => 3.days.from_now, :committee => @meeting.committee, :url => "bar.com/meeting")
        assert !@meeting.matches_params(:uid => 42)
        @meeting.uid = 42
        assert !@meeting.matches_params(:uid => nil)
        assert !@meeting.matches_params(:uid => 41)
        assert !@meeting.matches_params
        assert @meeting.matches_params(:uid => 42)
        assert @meeting.matches_params(:uid => 42, :url => "bar.com/foo") #ignore that url is different
        assert @meeting.matches_params(:uid => 42, :date_held => 4.days.from_now) #ignore that date_held is different
      end
      
      should "should match committee_id and url if uid is blank" do
        meeting_with_url = Factory(:meeting, :council => @meeting.council, :date_held => 3.days.from_now, :committee => @meeting.committee, :url => "bar.com/meeting")
        assert meeting_with_url.matches_params(:committee_id => meeting_with_url.committee_id, :url => meeting_with_url.url)
        assert meeting_with_url.matches_params(:committee_id => meeting_with_url.committee_id, :url => meeting_with_url.url, :date_held => 4.days.from_now) #ignore that date_held is different
        assert !meeting_with_url.matches_params(:url => meeting_with_url.url)
        assert !meeting_with_url.matches_params(:committee_id => nil, :url => meeting_with_url.url)
      end
      
      should "should match committee_id and date_held if uid and url are blank" do
        date_held = 3.days.from_now
        meeting_with_date_held = Factory(:meeting, :council => @meeting.council, :date_held => date_held, :committee => @meeting.committee) #no uid
        assert meeting_with_date_held.matches_params(:committee_id => meeting_with_date_held.committee_id, :date_held => date_held)
        assert !meeting_with_date_held.matches_params(:date_held => date_held)
        assert !meeting_with_date_held.matches_params(:committee_id => nil, :date_held => date_held)
      end
      
      should "should not match when no params" do
        assert !@meeting.matches_params
        assert Meeting.new.matches_params
      end
      
    end
    
    context "when calling minutes_document_body setter" do
      setup do
        @meeting.minutes_document_body = "some document text"
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
    
    context "when calling agenda_document_body setter" do
      setup do
        @meeting.agenda_document_body = "some document text"
      end
      
      should "create new agenda document" do
        assert_kind_of Document, @meeting.agenda
      end
      
      should "save new agenda document" do
        assert !@meeting.agenda.new_record?
      end
      
      should "store passed value in document raw_body" do
        assert_equal "some document text", @meeting.agenda.raw_body
      end
      
      should "save meeting url as document url" do
        assert_equal "http//council.gov.uk/meeting/22", @meeting.agenda.url
      end
      
      should "set document type to be 'Agenda'" do
        assert_equal "Agenda", @meeting.agenda.document_type
      end
    end
    
    context "when calling minutes_document_body setter and meeting has existing minutes" do
      setup do
        @existing_minutes = Factory(:document, :document_type => "Minutes", :document_owner => @meeting)
        @meeting.minutes_document_body = "some document text"
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
        
    context "when calling agenda_document_body setter and meeting has existing agenda" do
      setup do
        @existing_agenda = Factory(:document, :document_type => "Agenda", :document_owner => @meeting)
        @meeting.agenda_document_body = "some document text"
      end

      should "not replace agenda" do
        assert_equal @existing_agenda.id, @meeting.agenda.id
      end
      
      should "update existing agenda raw_body" do
        assert_equal "some document text", @existing_agenda.reload.raw_body
      end
      
      should "set document_type to be 'Agenda'" do
        assert_equal "Agenda", @meeting.agenda.document_type
      end
    end
        
  end

  private
  def new_meeting(options={})
    Meeting.new({:date_held => 5.days.ago, :committee_id => 22, :council_id => 11}.merge(options))
  end
end
