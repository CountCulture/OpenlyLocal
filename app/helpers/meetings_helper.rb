module MeetingsHelper
  def link_to_calendar
    link_to "Subscribe to this calendar", url_for(params.merge(:protocol => "webcal", :only_path => false, :format => "ics")), :class => "calendar feed"
  end
end
