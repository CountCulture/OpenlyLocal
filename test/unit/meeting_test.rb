require File.expand_path('../../test_helper', __FILE__)

class MeetingTest < ActiveSupport::TestCase
  subject { @meeting }
  context "The Meeting Class" do
    setup do
      @committee = Factory(:committee)
      @council = @committee.council
      @meeting = Factory(:meeting, :committee => @committee, :council => @council)
   end

    should belong_to :committee
    should belong_to :council # think about meeting should belong to council through committee
    should validate_presence_of :date_held
    should validate_presence_of :committee_id
    should validate_presence_of :council_id
    should have_one :minutes # no shoulda macro for polymorphic stuff so tested below
    should have_one :agenda # no shoulda macro for polymorphic stuff so tested below
    should have_many :related_articles
    should have_db_column :venue
    should have_db_column :status
    should validate_uniqueness_of(:date_held).scoped_to [:council_id, :committee_id]
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
    
    context "with forthcoming named scope" do
      setup do
        @future_meeting = Factory(:meeting, :committee => @committee, :council => @council, :date_held => 5.days.from_now)
        @future_cancelled_meeting = Factory(:meeting, :committee => @committee, :council => @council, :date_held => 6.days.from_now, :status => "cancelled")
      end
      
      should "fetch only meetings in the future" do
        expected_options = {:conditions => ["date_held >= ? AND (status IS NULL OR status NOT LIKE 'cancelled')", Time.now], :order => "date_held" }
        assert_equal expected_options[:order], Meeting.forthcoming.proxy_options[:order]
        assert_equal expected_options[:conditions].first, Meeting.forthcoming.proxy_options[:conditions].first
        assert_in_delta expected_options[:conditions].last, Meeting.forthcoming.proxy_options[:conditions].last, 2
      end
      
      should "not return meetings in the past" do
        assert !Meeting.forthcoming.include?(@meeting)
      end
      
      should "return meetings in the future" do
        assert Meeting.forthcoming.include?(@future_meeting)
      end
      
      should "not include cancelled meetings" do
        assert !Meeting.forthcoming.include?(@future_cancelled_meeting)
      end
    end
    
    context "should overwrite find_all_existing and" do
      setup do
        another_committee = Factory(:committee, :council => @council)
        another_committee_meeting = Factory(:meeting, :committee => another_committee, :council => @council)
        another_council = Factory(:another_council)
        another_council_committee = Factory(:committee, :council => another_council, :uid => @committee.uid) # same uid, diff council
        another_council_meeting = Factory(:meeting, :committee => another_council_committee, :council => another_council)
      end
      
      should "find only those meetings that are for the same committee and council" do
        assert_equal [@meeting], Meeting.find_all_existing(:organisation => @council, :committee_id => @committee.id)
      end
      
      should "raise exception if no council_id in params" do
        assert_raise(ArgumentError) { Meeting.find_all_existing({:organisation => @council}) }
      end
      
      should "raise exception if no committee_id in params" do
        assert_raise(ArgumentError) { Meeting.find_all_existing({:committee_id => @committee.id}) }
      end
    end
  
    context "should overwrite orphan_records_callback and" do
      setup do
        @future_meeting = Factory(:meeting, :committee => @committee, :council => @committee.council, :date_held => 5.days.from_now)
        @meeting_with_no_time = Factory(:meeting, :committee => @committee, :council => @committee.council, :date_held => 5.days.from_now.to_date)
      end

      should "not delete orphan_record if not saving results" do      
        Meeting.send(:orphan_records_callback, [@meeting, @future_meeting])
        assert Meeting.find_by_id(@meeting.id)
        assert Meeting.find_by_id(@future_meeting.id)
      end

      should "not fail if there are no orphan records" do
        assert_nothing_raised(Exception) { Meeting.send(:orphan_records_callback, [], :save_results => true) }
      end   

      should "delete orphan meetings in the future" do
        Meeting.send(:orphan_records_callback, [@meeting, @future_meeting], :save_results => true)
        assert_nil Meeting.find_by_id(@future_meeting.id)
      end  

      should "delete orphan meetings in the future when time is not known" do
        Meeting.send(:orphan_records_callback, [@meeting, @meeting_with_no_time], :save_results => true)
        assert_nil Meeting.find_by_id(@meeting_with_no_time.id)
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
    
    # should "allow access to committee via uid" do
    #   meeting = Meeting.create!(:date_held => "6 November 2008 7:30pm", :committee_uid => @committee.uid, :council_id => @committee.council_id, :url => "http//council.gov.uk/meeting/22")
    #   assert_equal @committee, meeting.committee
    # end
    # 
    context 'when returning date_held' do
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
    end
    
    context 'when assigning date_held_date' do
      context 'and date_held is nil' do
        should 'assign date' do
          # can't use factory as it sets date_held
          assert_equal Date.new(2010, 05, 11), Meeting.create!(:date_held_date => "11 May 2010", :committee => @committee, :uid => 23, :council_id => @committee.council_id).reload.date_held
        end
        
        should 'assign datetime' do
          assert_equal Time.zone.local(2010, 05, 11, 19, 30), Meeting.create!(:date_held_date => "11 May 2010, 7:30pm", :committee => @committee, :uid => 23, :council_id => @committee.council_id).reload.date_held
        end
        
      end
      
      context 'and date_held returns date' do
        setup do
          @dh_meeting = Factory(:meeting, :committee => @committee, :council_id => @committee.council_id, :date_held => "11 May 2010")
        end
        
        should 'override existing date date_held_date new date' do
          @dh_meeting.update_attribute(:date_held_date, "13 May 2010")
          assert_equal Date.new(2010, 05, 13), @dh_meeting.reload.date_held
        end
        
        should 'override existing date with new datetime' do
          @dh_meeting.update_attribute(:date_held_date, "13 May 2010, 7:30pm")
          assert_equal Time.zone.local(2010, 05, 13, 19, 30), @dh_meeting.reload.date_held
        end
      end
      
      context 'and date_held returns datetime' do
        setup do
          @dh_meeting = Factory(:meeting, :committee => @committee, :council_id => @committee.council_id, :date_held => "11 May 2010 7:30pm")
        end
        
        should 'not override existing datetime with new date' do
          assert_equal Time.zone.local(2010, 05, 11, 19, 30), @dh_meeting.reload.date_held
          @dh_meeting.update_attribute(:date_held_date, "13 May 2010")
          assert_equal Time.zone.local(2010, 05, 11, 19, 30), @dh_meeting.reload.date_held
        end
      end
    end
    
    
    should "return committee name in title" do
      assert_equal "Audit Group meeting", @meeting.title
    end
    
    should "return meeting as title if no associated committee" do
      assert_equal "meeting", Meeting.new.title
    end
    
    should "return committee name and date in extended title" do
      assert_equal "Audit Group meeting, #{@meeting.date_held.to_s(:event_date)}", @meeting.extended_title
    end
    
    should "return formatted date as formatted date with extra spaces removed" do
      assert_equal "Nov 6 2008, 7.30PM", @meeting.formatted_date
    end
    
    should "mark as cancelled if status is cancelled" do
      assert !new_meeting.cancelled?
      assert !new_meeting(:status => "foo").cancelled?
      assert new_meeting(:status => "cancelled").cancelled?
      assert new_meeting(:status => "Cancelled").cancelled?
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
    
  context "when returning status" do
    
    should "return lower case version of status attribute" do
      assert_equal "cancelled", new_meeting(:status => "Cancelled", :date_held => nil).status
    end
    
    should "return nil if no status attribute or date_held time" do
      assert_nil new_meeting(:date_held => nil).status
    end
    
    should "return status of meeting if date_held" do
      assert_equal "past", new_meeting.status
      assert_equal "future", new_meeting(:date_held => 1.hour.from_now).status
    end
    
    should "add status of meeting with no time set" do
      assert_equal "past", new_meeting(:date_held => "3 November 2007").status
      assert_equal "future", new_meeting(:date_held => "3 November 2020").status
    end
    
    should "return lower case version of status attribute and time status of meeting with date_held" do
      assert_equal "cancelled past", new_meeting(:status => "Cancelled").status
      assert_equal "cancelled future", new_meeting(:date_held => "3 November 2020", :status => "Cancelled").status
    end
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
