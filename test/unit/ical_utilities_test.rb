require File.expand_path('../../test_helper', __FILE__)

# Tests IcalUtilities::Calendar class. NB uses Mocha
class IcalUtilitiesTest < ActiveSupport::TestCase
  
  context "A Calendar instance" do
    setup do
      @events = [stub()]
      @calendar =IcalUtilities::Calendar.new(@events, :name => "Dummy Calendar", :url => "http://test.com", :attribute_aliases => {:foo => :bar})
    end

    should "set events from options" do
      assert_equal @events, @calendar.events
    end
    
    should "set name from options" do
      assert_equal "Dummy Calendar", @calendar.name
    end
    
    should "set url from options" do
      assert_equal "Dummy Calendar", @calendar.name
    end
    
    should "set attribute_aliases from options" do
      assert_equal({:foo => :bar}, @calendar.attribute_aliases)
    end
    
    should "set attribute_aliases as emty hash if not given" do
      assert_equal({}, IcalUtilities::Calendar.new.attribute_aliases)
    end
    
    should "make array of events if single event passed in to calendar" do
      event = stub()

      calendar = IcalUtilities::Calendar.new(event)
      assert_equal [event], calendar.events
    end

    should "encode calendar as_vcalendar" do
      encoded_cal = <<-EOF
BEGIN:VCALENDAR
VERSION:2.0
METHOD:PUBLISH
PRODID:-//#{IcalUtilities::PRODID}
CALSCALE:Gregorian
END:VCALENDAR
    EOF
      calendar = IcalUtilities::Calendar.new
      assert_equal encoded_cal, calendar.encoded
    end
    
    should "encode_calendar_as_vcalendar_with_name_and_url_of_calendar" do
      encoded_cal = <<-EOF
BEGIN:VCALENDAR
VERSION:2.0
METHOD:PUBLISH
PRODID:-//#{IcalUtilities::PRODID}
CALSCALE:Gregorian
X-WR-CALNAME:Test Calendar
X-ORIGINAL-URL:http://test.com/events
END:VCALENDAR
    EOF
      calendar = IcalUtilities::Calendar.new(nil, :name => "Test Calendar", :url => "http://test.com/events")
      assert_equal encoded_cal, calendar.encoded
    end
      
  end
      
  should "encode_calendar_as_vcalendar_with_event" do
    event = stub_everything(:summary => "dummy event title", :dtstart => "2009-01-17".to_date, :dtend => "2009-02-03".to_date,
                            :description => "Some dummy copy with line breaks in it and also some\nlong lines that can only be a \ncertain number of characters long",
                            :location => "Some address\nsome street\nsome town\nUnited Kingdom",
                            :url => "http://www.example.com", :uid => "some unique id", :last_modified => DateTime.civil(2009, 12, 5, 15, 32, 05).to_time, :created => DateTime.civil(2009, 12, 4, 11, 34).to_time)
    
    encoded_cal = <<-EOF
BEGIN:VCALENDAR
VERSION:2.0
METHOD:PUBLISH
PRODID:-//#{IcalUtilities::PRODID}
CALSCALE:Gregorian
BEGIN:VEVENT
SUMMARY:dummy event title
DTSTART;VALUE=DATE:20090117
DTEND;VALUE=DATE:20090203
DESCRIPTION:Some dummy copy with line breaks in it and also some\\nlong line
 s that can only be a \\ncertain number of characters long
LOCATION:Some address\\nsome street\\nsome town\\nUnited Kingdom
CREATED:20091204T113400
LAST-MODIFIED:20091205T153205
UID:some unique id
URL:http://www.example.com
END:VEVENT
END:VCALENDAR
    EOF
    calendar = IcalUtilities::Calendar.new(event)
    assert_equal encoded_cal, calendar.encoded
  end
  
  should "encode_calendar_with_event_with_empty_attribs" do
    event = stub_everything(:summary => "dummy event title", :dtstart => "2009-01-17".to_date)
      encoded_cal = <<-EOF
BEGIN:VCALENDAR
VERSION:2.0
METHOD:PUBLISH
PRODID:-//#{IcalUtilities::PRODID}
CALSCALE:Gregorian
BEGIN:VEVENT
SUMMARY:dummy event title
DTSTART;VALUE=DATE:20090117
END:VEVENT
END:VCALENDAR
    EOF
    calendar = IcalUtilities::Calendar.new(event)
    assert_equal encoded_cal, calendar.encoded
  end
  
  should "use attribute aliases when given" do
    event = stub_everything(:summary => "dummy event title", :dtstart => "2009-01-17".to_date, :uid_alias => "foo123")
    calendar = IcalUtilities::Calendar.new(event, :attribute_aliases => {:uid_alias => :uid})
    assert_match "UID:foo123", calendar.encoded
  end

  should "use attribute aliases in preferences to attributes when given" do
    event = stub_everything(:summary => "dummy event title", :dtstart => "2009-01-17".to_date, :uid => "bar456", :uid_alias => "foo123")
    calendar = IcalUtilities::Calendar.new(event, :attribute_aliases => {:uid_alias => :uid})
    assert_match /UID:foo123/, calendar.encoded
    assert_no_match /UID:bar456/, calendar.encoded
  end

  should "encode_calendar_with_event_with_organizer" do
    event = stub_everything(:summary => "dummy event title", :dtstart => "2009-01-17".to_date, :organizer => {:cn => "Example Organizer", :uri => "mailto:organizer@example.com"})
      encoded_cal = <<-EOF
BEGIN:VCALENDAR
VERSION:2.0
METHOD:PUBLISH
PRODID:-//#{IcalUtilities::PRODID}
CALSCALE:Gregorian
BEGIN:VEVENT
SUMMARY:dummy event title
DTSTART;VALUE=DATE:20090117
ORGANIZER;CN="Example Organizer":mailto:organizer@example.com
END:VEVENT
END:VCALENDAR
    EOF
    calendar = IcalUtilities::Calendar.new(event)
    assert_equal encoded_cal, calendar.encoded
  end

  should "encode_string_as_per_rfc2445" do
    assert_equal "", rfc2445_wrap_string("")
    assert_equal "small string", rfc2445_wrap_string("small string")
    assert_equal "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod te\n mpor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, \n quis nostrud.", 
                  rfc2445_wrap_string("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud.")
  end
  
  should "escape_string_as_per_rfc2445" do
    assert_equal "Lorem ipsum dolor\\n sit amet, consectetur adipisicing elit", rfc2445_escape_string("Lorem ipsum dolor\n sit amet, consectetur adipisicing elit")
    assert_equal "Lorem ipsum dolor\\n sit amet, consectetur adipisicing elit", rfc2445_escape_string("Lorem ipsum dolor\r\n sit amet, consectetur adipisicing elit")
    assert_equal 'Lorem ipsum "dolor - sit amet, consectetur adipisicing elit', rfc2445_escape_string('Lorem ipsum "dolor - sit amet, consectetur adipisicing elit')
  end
  
  
  context "when extending an object with Ical::EventsMethods" do
    setup do
      event_1, event_2 = stub_everything, stub_everything
      @events = [event_1, event_2]
      @events.extend(IcalUtilities::ArrayExtensions)
    end

    should "respond_to to_ical method" do
      assert @events.respond_to?(:to_ical)
    end
    
    should "generate new calendar from array of events" do
      IcalUtilities::Calendar.expects(:new).with(@events, anything).returns(stub_everything)
      @events.to_ical
    end
    
    should "pass given options when generating calendar" do
      IcalUtilities::Calendar.expects(:new).with(anything, {:foo => "bar"}).returns(stub_everything)
      @events.to_ical(:foo => "bar")
    end
    
    should "encode calendar after generating" do
      mock_calendar = mock(:encoded => "foo")
      IcalUtilities::Calendar.stubs(:new).returns(mock_calendar)
      assert_equal "foo", @events.to_ical
    end
  end
  
  
  private
  def rfc2445_wrap_string(some_string)
    IcalUtilities::Calendar.new.send("rfc2445_wrap_string", some_string)
  end
  def rfc2445_escape_string(some_string)
    IcalUtilities::Calendar.new.send("rfc2445_escape_string", some_string)
  end
end