require 'test_helper'

class MeetingsHelperTest < ActionView::TestCase
  include ApplicationHelper
  include MeetingsHelper
  
  context "link_to_calendar helper method" do
    setup do
      @controller = TestController.new
      self.stubs(:params).returns(:controller => "meetings", :action => "index", :foo => "bar")
    end
    
    should "return link to current page" do
      assert_equal link_to("Subscribe to this calendar", { :controller => "meetings", 
                                                           :action => "index", 
                                                           :foo => "bar", 
                                                           :protocol => "webcal", 
                                                           :only_path => false, 
                                                           :format => "ics" }, :class => "calendar feed"), 
                      link_to_calendar
      
    end
  end
end
