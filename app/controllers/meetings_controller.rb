class MeetingsController < ApplicationController
  
  def index
    @council = Council.find(params[:council_id])
    @title = "Committee meetings"
    @meetings = @council.meetings.find(:all, :order => "date_held DESC")
    respond_to do |format|
      format.html
      format.xml { render :xml => @meetings.to_xml }
      format.json { render :xml => @meetings.to_json }
      format.ics do
        @meetings.extend(IcalUtilities::ArrayExtensions)
        render :text => @meetings.to_ical(:name => "TheyWorkForYou Local :: #{@title}", :url => "http://theyworkforyoulocal.com/meetings", :attribute_aliases => {:event_uid => :uid})
      end 
    end
  end
  
  def show
    @meeting = Meeting.find(params[:id])
    @council = @meeting.council
    @committee = @meeting.committee
    @other_meetings = @committee.meetings - [@meeting]
    @title = "#{@meeting.title}"
    respond_to do |format|
      format.html
      format.xml { render :xml => @meeting.to_xml }
      format.json { render :json => @meeting.to_json }
    end
  end
end
